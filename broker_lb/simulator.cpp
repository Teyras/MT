#include <iostream>
#include <vector>
#include <set>

#include <boost/asio.hpp>

#include "broker/src/broker_connect.h"
#include "broker/src/handlers/broker_handler.h"
#include "broker/src/queuing/multi_queue_manager.h"


void populate_registry(std::shared_ptr<worker_registry> registry)
{

}

std::shared_ptr<queue_manager_interface> create_queue_manager(const std::string &type)
{
    if (type == "multi") {
        return std::make_shared<multi_queue_manager>();
    }

    throw std::runtime_error("Unknown queue manager type");
}

struct simulation_job {
    std::string job_id;
    std::vector<std::string> data;
    boost::posix_time::milliseconds processing_time; // How long the job takes
    boost::posix_time::milliseconds arrival_time;
    boost::posix_time::milliseconds enqueueing_time;
    boost::posix_time::milliseconds processing_started_time;
};

using worker_status_map = std::map<std::string, bool>;

struct job_compare {
    bool operator() (const simulation_job &first, const simulation_job &second)
    {
        return first.arrival_time < second.arrival_time;
    }
};

class responder {
private:
    worker_status_map &worker_status_;
    broker_handler &handler_;
    bool is_terminating_ = false;
    boost::asio::io_service &io_;
    std::vector<std::shared_ptr<boost::asio::deadline_timer>> timers_;

    boost::asio::deadline_timer job_timer_;
    boost::asio::deadline_timer ping_timer_;
    boost::asio::deadline_timer reactor_periodic_timer_;

    std::set<simulation_job, job_compare> incoming_jobs_; // Used as a queue for incoming jobs
    std::map<std::string, simulation_job> job_data_;

    boost::posix_time::ptime start_time_;

    boost::posix_time::milliseconds time_since_start() const
    {
        return boost::posix_time::milliseconds(
            (boost::posix_time::microsec_clock::universal_time() - start_time_).total_milliseconds());
    }

public:
    responder(worker_status_map &worker_status, broker_handler &handler, boost::asio::io_service &io):
        worker_status_(worker_status),
        handler_(handler),
        io_(io),
        job_timer_(io_),
        ping_timer_(io_),
        reactor_periodic_timer_(io_)
    {
    }

    void start()
    {
        start_time_ = boost::posix_time::microsec_clock::universal_time() + boost::posix_time::milliseconds(100);

        job_timer_.expires_at(start_time_);
        job_timer_.async_wait([this] (const boost::system::error_code&) {
            send_jobs();
        });

        ping_timer_.expires_at(start_time_);
        ping_timer_.async_wait([this] (const boost::system::error_code&) {
            send_pings(boost::posix_time::milliseconds(500));
        });

        reactor_periodic_timer_.expires_at(start_time_);
        reactor_periodic_timer_.async_wait([this] (const boost::system::error_code&) {
            invoke_timer(boost::posix_time::milliseconds(100));
        });
    }

    void respond(const message_container &message)
    {
        if (message.key == broker_connect::KEY_WORKERS) {
            if (message.data.at(0) == "eval") {
                const std::string &job_id = message.data.at(1);
                simulation_job &job = job_data_.at(job_id);
                job.processing_started_time = time_since_start();
                auto timer = std::make_shared<boost::asio::deadline_timer>(io_, job.processing_time);
                timer->async_wait([this, job_id, message] (const boost::system::error_code&) {
                    send_job_done(job_id, message.identity);
                });
                timers_.push_back(timer);
            }
        }

        if (message.key == broker_connect::KEY_CLIENTS) {
            if (message.data.at(0) == "reject") {
                // TODO job was rejected - not good
            }
        }
    }

    void send_job_done(const std::string &job_id, const std::string &worker_identity)
    {
        handler_.on_request(message_container(broker_connect::KEY_WORKERS, worker_identity, {"done"}), [this] (const auto &message) {
            respond(message);
        });
    }

    void send_jobs()
    {
        if (incoming_jobs_.size() == 0) {
            is_terminating_ = true;
            return;
        }

        auto job = std::begin(incoming_jobs_);
        handler_.on_request(message_container(broker_connect::KEY_CLIENTS, "", job->data), [this] (const auto &message) {
            respond(message);
        });

        job = std::begin(incoming_jobs_);

        boost::posix_time::milliseconds delay(0);

        if (incoming_jobs_.size() == 1) {
            delay = job->processing_time; // We are processing the last job -> stop the periodic events after it is finished
        } else {
            delay = boost::posix_time::milliseconds((std::next(job)->arrival_time - time_since_start()).total_milliseconds());
        }

        incoming_jobs_.erase(job);

        job_timer_.expires_at(job_timer_.expires_at() + delay);
        job_timer_.async_wait([this] (const boost::system::error_code&) {
            send_jobs();
        });
    }

    void send_pings(boost::posix_time::milliseconds interval)
    {
        for (auto &it: worker_status_) {
            if (!it.second) {
                continue; // The worker is down
            }

            handler_.on_request(
                message_container(
                        broker_connect::KEY_WORKERS,
                        it.first,
                        {"ping"}
                ),
                [this] (const auto &message) {
                    respond(message);
                }
            );
        }

        if (!is_terminating_) {
            ping_timer_.expires_at(ping_timer_.expires_at() + interval);
            ping_timer_.async_wait([this, interval] (const boost::system::error_code&) {
                send_pings(interval);
            });
        }
    }

    void invoke_timer(boost::posix_time::milliseconds interval)
    {
        handler_.on_request(
                message_container(
                        broker_connect::KEY_TIMER,
                        "",
                        {std::to_string(interval.ticks())}
                ),
                [this] (const auto &msg) {
                    respond(msg);
                }
        );

        if (!is_terminating_) {
            reactor_periodic_timer_.expires_at(reactor_periodic_timer_.expires_at() + interval);
            reactor_periodic_timer_.async_wait([this, interval] (const boost::system::error_code&) {
                invoke_timer(interval);
            });
        }
    }
};

int main(int argc, char **argv)
{
    // The configuration is used only for maximum liveness, ping interval and maximum failure count.
    // Failure count is not used (we will not test job failures).
    // For maximum liveness and ping interval, we will use the default values.
    auto config = std::make_shared<const broker_config>();

    // Fill the registry according to specification from the command line
    auto registry = std::make_shared<worker_registry>();
    populate_registry(registry);

    // Create one of the predefined queue managers
    auto queue = create_queue_manager("multi");

    broker_handler handler(config, registry, queue, std::shared_ptr<spdlog::logger>());

    boost::asio::io_service io;

    worker_status_map worker_status;

    responder res{worker_status, handler, io};
    res.start();
    
    io.run();
    return 0;
}