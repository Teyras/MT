#include <iostream>
#include <vector>
#include <set>

#include <boost/asio.hpp>
#include <boost/algorithm/string.hpp>

#include <yaml-cpp/yaml.h>

#include "broker/src/broker_connect.h"
#include "broker/src/handlers/broker_handler.h"
#include "broker/src/queuing/multi_queue_manager.h"


void load_workers(broker_handler &handler, std::istream &input)
{
    auto config = YAML::Load(input);
    auto workers = config["workers"];

    for (auto it = std::begin(workers); it != std::end(workers); ++it) {
        std::vector<std::string> init_data = {"init", it->second["hwgroup"].as<std::string>()};
        for (auto it_headers = std::begin(it->second["headers"]); it_headers != std::end(it->second["headers"]); ++it_headers) {
            init_data.push_back(it_headers->as<std::string>());
        }
        init_data.emplace_back("");

        handler.on_request(
            message_container(
                broker_connect::KEY_WORKERS,
                it->first.as<std::string>(),
                init_data
            ),
            [] (const message_container &) {}
        );
    }
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
    boost::posix_time::milliseconds arrival_time;
    boost::posix_time::milliseconds processing_time; // How long the job takes
    boost::posix_time::milliseconds processing_started_time;
};

using worker_status_map = std::map<std::string, bool>;

struct job_compare {
    bool operator() (const simulation_job &first, const simulation_job &second)
    {
        return first.arrival_time < second.arrival_time;
    }
};

using job_queue = std::multiset<simulation_job, job_compare>;
using job_data = std::map<std::string, simulation_job>;

/**
 * Load jobs from a CSV file where a row contains the arrival time, processing time, and a varying number of columns for headers.
 */
void load_jobs(job_data &jobs, std::istream &input)
{
    size_t i = 1;
    const auto ws = "\t\n\v\f\r ";

    for (std::string line; std::getline(input, line); ) {
        std::string job_id = "job_" + std::to_string(i);
        i += 1;

        // Trim whitespace
        line.erase(0, line.find_first_not_of(ws));
        line.erase(line.find_last_not_of(ws) + 1);

        std::vector<std::string> entry;
        boost::split(entry, line, boost::is_any_of(","));

        std::vector<std::string> job_data = {"eval", job_id};
        job_data.insert(std::end(job_data), std::begin(entry) + 2, std::end(entry));
        job_data.emplace_back("");

        jobs.emplace(job_id, simulation_job{
            .job_id=job_id,
            .data=job_data,
            .arrival_time=boost::posix_time::milliseconds(std::stoll(entry[0])),
            .processing_time=boost::posix_time::milliseconds(std::stoll(entry[1])),
            .processing_started_time=boost::posix_time::milliseconds(0)
        });
    }
}

class responder {
private:
    worker_status_map worker_status_;
    broker_handler &handler_;
    bool is_terminating_ = false;
    boost::asio::io_service &io_;
    std::vector<std::shared_ptr<boost::asio::deadline_timer>> timers_;

    boost::asio::deadline_timer job_timer_;
    boost::asio::deadline_timer ping_timer_;
    boost::asio::deadline_timer reactor_periodic_timer_;

    job_queue incoming_jobs_;
    job_data &job_data_;

    boost::posix_time::ptime start_time_;

public:
    responder(broker_handler &handler, boost::asio::io_service &io, job_data &jobs, std::shared_ptr<worker_registry> registry):
        handler_(handler),
        io_(io),
        job_timer_(io_),
        ping_timer_(io_),
        reactor_periodic_timer_(io_),
        job_data_(jobs)
    {
        for (auto &it: jobs) {
            incoming_jobs_.insert(it.second);
        }

        for (auto &worker: registry->get_workers()) {
            worker_status_[worker->identity] = true;
        }
    }

    boost::posix_time::milliseconds time_since_start() const
    {
        return boost::posix_time::milliseconds(
                (boost::posix_time::microsec_clock::universal_time() - start_time_).total_milliseconds());
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
        handler_.on_request(message_container(
                broker_connect::KEY_WORKERS,
                worker_identity,
                {"done", job_id, "OK"}
            ), [this] (const auto &message) {
                respond(message);
            }
        );
    }

    void send_jobs()
    {
        if (incoming_jobs_.empty()) {
            is_terminating_ = true;
            return;
        }

        auto next_job = std::begin(incoming_jobs_);

        while (next_job != std::end(incoming_jobs_) && next_job->arrival_time <= time_since_start()) {
            handler_.on_request(message_container(broker_connect::KEY_CLIENTS, "", next_job->data),
                                [this](const auto &message) {
                                    respond(message);
                                });
            next_job = std::next(next_job);
        }

        boost::posix_time::milliseconds delay(0);

        if (next_job == std::end(incoming_jobs_)) {
            // We have processed the queue -> terminate
            is_terminating_ = true;
            return;
        } else {
            // Wait until it is time for another job to arrive
            delay = boost::posix_time::milliseconds((next_job->arrival_time - time_since_start()).total_milliseconds());
        }

        incoming_jobs_.erase(std::begin(incoming_jobs_), next_job); // Erase all jobs that precede the one we are waiting for

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
                        {std::to_string(interval.total_milliseconds())}
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

    // Create one of the predefined queue managers
    auto queue = create_queue_manager(argv[1]);

    // Prepare a worker registry
    auto registry = std::make_shared<worker_registry>();

    // Create a logger that outputs to stderr
    auto sink = std::make_shared<spdlog::sinks::stderr_sink_mt>();
    auto logger = spdlog::create("broker", sink);
    logger->set_level(spdlog::level::debug);

    broker_handler handler(config, registry, queue, logger);

    // Fill the registry and queue according to specification from the command line
    std::ifstream workers_file(argv[2]);
    load_workers(handler, workers_file);

    // Load jobs to be simulated
    job_data jobs;

    std::ifstream jobs_file(argv[3]);
    load_jobs(jobs, jobs_file);

    boost::asio::io_service io;

    responder res{handler, io, jobs, registry};
    res.start();
    
    io.run();

    std::cerr << "Done in " << std::to_string(res.time_since_start().total_milliseconds()) << "ms" << std::endl;

    for (auto &it: jobs) {
        std::cout
            << it.second.job_id << ","
            << it.second.arrival_time.total_milliseconds() << ","
            << it.second.processing_time.total_milliseconds() << ","
            << it.second.processing_started_time.total_milliseconds() << std::endl;
    }

    return 0;
}