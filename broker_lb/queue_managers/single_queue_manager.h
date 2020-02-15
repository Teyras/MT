#ifndef RECODEX_BROKER_SINGLE_QUEUE_MANAGER_HPP
#define RECODEX_BROKER_SINGLE_QUEUE_MANAGER_HPP

#include <chrono>

#include "../broker/src/queuing/queue_manager_interface.h"

struct request_entry {
    request_ptr request;
    std::chrono::time_point<std::chrono::system_clock, std::chrono::milliseconds> arrived_at;
};

struct fcfs_job_comparator {
    bool operator()(const request_entry &a, const request_entry &b) const
    {
        return a.arrived_at < b.arrived_at;
    }
};

template <typename JobComparator>
class single_queue_manager : public queue_manager_interface
{
private:
    std::unique_ptr<JobComparator> comparator_;
    std::multiset<request_entry, JobComparator> jobs_;
    std::map<worker_ptr, request_ptr> worker_jobs_;

public:
    explicit single_queue_manager(std::unique_ptr<JobComparator> comparator):
        comparator_(std::move(comparator)),
        jobs_(*comparator_)
    {
    }

    ~single_queue_manager() override = default;

    request_ptr add_worker(worker_ptr worker, request_ptr current_request = nullptr) override
    {
        worker_jobs_[worker] = current_request;

        if (current_request != nullptr) {
            return current_request;
        }

        return assign_request(worker);
    }

    request_ptr assign_request(worker_ptr worker) override
    {
        for (auto it = jobs_.cbegin(); it != jobs_.cend(); ++it) {
            if (!worker->check_headers(it->request->headers)) {
                continue;
            }

            worker_jobs_[worker] = it->request;
            jobs_.erase(it);

            return it->request;
        }

        return nullptr;
    }

    std::shared_ptr<std::vector<request_ptr>> worker_terminated(worker_ptr worker) override
    {
        auto result = std::make_shared<std::vector<request_ptr>>();
        result->push_back(worker_jobs_[worker]);
        worker_jobs_.erase(worker);
        return result;
    }

    enqueue_result enqueue_request(request_ptr request) override
    {
        // Try to find a free worker and assign the job
        for (auto &pair: worker_jobs_) {
            if (pair.second == nullptr && pair.first->check_headers(request->headers)) {
                worker_jobs_[pair.first] = request;

                return enqueue_result{
                    .assigned_to = pair.first,
                    .enqueued = true,
                };
            }
        }

        // If no worker able to process the job exists, reject it
        for (auto it = std::begin(worker_jobs_); it != std::end(worker_jobs_); ++it) {
            if (it->first->check_headers(request->headers)) {
                break;
            }

            if (std::next(it) == std::end(worker_jobs_)) {
                return enqueue_result{
                    .assigned_to = nullptr,
                    .enqueued = false,
                };
            }
        }

        // Enqueue the job
        jobs_.insert(request_entry{
            .request = request,
            .arrived_at = std::chrono::time_point_cast<std::chrono::milliseconds>(std::chrono::system_clock::now())
        });

        return enqueue_result{
            .assigned_to = nullptr,
            .enqueued = true,
        };
    }

    std::size_t get_queued_request_count() override
    {
        return jobs_.size();
    }

    request_ptr get_current_request(worker_ptr worker) override
    {
        return worker_jobs_[worker];
    }

    request_ptr worker_finished(worker_ptr worker) override
    {
        return assign_request(worker);
    }

    request_ptr worker_cancelled(worker_ptr worker) override
    {
        auto current_request = worker_jobs_[worker];
        worker_jobs_[worker] = nullptr;
        return current_request;
    }
};

#endif
