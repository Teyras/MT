#ifndef RECODEX_BROKER_SINGLE_QUEUE_MANAGER_HPP
#define RECODEX_BROKER_SINGLE_QUEUE_MANAGER_HPP

#include <chrono>

#include "../broker/src/queuing/queue_manager_interface.h"

struct request_entry {
    request_ptr request;
    std::chrono::milliseconds arrived_at;
};

struct fcfs_job_comparator {
    bool compare(const request_entry &a, const request_entry &b, worker_ptr worker) const
    {
        return a.arrived_at < b.arrived_at;
    }
};

struct least_flexibility_job_comparator {
    const worker_registry &registry;

    explicit least_flexibility_job_comparator(const worker_registry &registry):
        registry(registry)
    {}

    bool compare(const request_entry &a, const request_entry &b, worker_ptr worker) const
    {
        size_t flexibility_a = 0;
        size_t flexibility_b = 0;

        for (auto &worker: registry.get_workers()) {
            if (worker->check_headers(a.request->headers)) {
                flexibility_a += 1;
            }

            if (worker->check_headers(b.request->headers)) {
                flexibility_b += 1;
            }
        }

        if (flexibility_a == flexibility_b) {
            return a.arrived_at < b.arrived_at;
        }

        return flexibility_a < flexibility_b;
    }
};

template <typename ProcessingTimeEstimator>
struct shortest_processing_time_job_comparator {
    std::shared_ptr<ProcessingTimeEstimator> estimator_;

    explicit shortest_processing_time_job_comparator(std::shared_ptr<ProcessingTimeEstimator> estimator): estimator_((estimator))
    {
    }

    bool compare(const request_entry &a, const request_entry &b, worker_ptr worker) const
    {
        return estimator_->estimate(a.request, nullptr) < estimator_->estimate(b.request, nullptr);
    }
};

template <typename ProcessingTimeEstimator>
struct earliest_deadline_job_comparator {
    std::shared_ptr<ProcessingTimeEstimator> estimator_;

    explicit earliest_deadline_job_comparator(std::shared_ptr<ProcessingTimeEstimator> estimator): estimator_(estimator)
    {
    }

    std::chrono::milliseconds determine_deadline(const request_entry &request) const
    {
        std::chrono::milliseconds processing_time = estimator_->estimate(request.request, nullptr);

        if (processing_time < std::chrono::seconds(15)) {
            return request.arrived_at + processing_time;
        }

        if (processing_time < std::chrono::seconds(45)) {
            return request.arrived_at + processing_time + std::chrono::seconds(15);
        }

        return request.arrived_at + 2 * processing_time;
    }

    bool compare(const request_entry &a, const request_entry &b, worker_ptr worker) const
    {
        return determine_deadline(a) < determine_deadline(b);
    }
};

template <typename ProcessingTimeEstimator>
struct oagm_job_comparator {
    std::shared_ptr<ProcessingTimeEstimator> estimator_;
    const worker_registry &registry_;

    explicit oagm_job_comparator(std::shared_ptr<ProcessingTimeEstimator> estimator, const worker_registry &registry): estimator_(estimator), registry_(registry)
    {
    }

    size_t calculate_label(const request_entry &request, worker_ptr worker) const
    {
        if (worker == nullptr) {
            return 0;
        }

        std::vector<worker_ptr> workers = registry_.get_workers();
        std::sort(workers.begin(), workers.end(), [this, request, worker] (const worker_ptr &a, const worker_ptr &b) {
            bool a_eligible = a->check_headers(request.request->headers);
            bool b_eligible = b->check_headers(request.request->headers);

            if (!a_eligible || !b_eligible) {
                return a_eligible;
            }

            return estimator_->estimate(request.request, a) < estimator_->estimate(request.request, b);
        });

        auto lower_bound = std::lower_bound(workers.cbegin(), workers.cend(), worker);
        return lower_bound - workers.cbegin();
    }

    size_t calculate_flexibility(const request_entry &request) const
    {
        size_t flexibility = 0;

        for (auto worker: registry_.get_workers()) {
            if (worker->check_headers(request.request->headers)) {
                flexibility += 1;
            }
        }

        return flexibility;
    }

    bool compare(const request_entry &a, const request_entry &b, worker_ptr worker) const
    {
        auto label_a = calculate_label(a, worker);
        auto label_b = calculate_label(a, worker);

        if (label_a != label_b) {
            return label_a < label_b;
        }

        auto flex_a = calculate_flexibility(a);
        auto flex_b = calculate_flexibility(b);

        if (flex_a != flex_b) {
            return flex_a < flex_b;
        }

        return estimator_->estimate(a.request, worker) < estimator_->estimate(b.request, worker);
    }
};

struct first_idle_worker_selector {
    worker_ptr select(const std::map<worker_ptr, request_ptr> &worker_jobs, const std::vector<request_entry> &queued_jobs, request_ptr request) const
    {
        for (auto &pair: worker_jobs) {
            if (pair.second == nullptr && pair.first->check_headers(request->headers)) {
                return pair.first;
            }
        }

        return nullptr;
    }
};

template <typename ProcessingTimeEstimator>
struct least_loaded_idle_worker_selector {
    std::shared_ptr<ProcessingTimeEstimator> estimator_;

    explicit least_loaded_idle_worker_selector(std::shared_ptr<ProcessingTimeEstimator> estimator): estimator_(estimator)
    {
    }
    
    std::chrono::milliseconds estimate_potential_worker_load(worker_ptr worker, const std::vector<request_entry> &queued_jobs) const
    {
        std::chrono::milliseconds result(0);

        for (auto &job: queued_jobs) {
            result += estimator_->estimate(job.request, worker);
        }

        return result;
    }

    worker_ptr select(const std::map<worker_ptr, request_ptr> &worker_jobs, const std::vector<request_entry> &queued_jobs, request_ptr request) const
    {
        worker_ptr result = nullptr;
        std::chrono::milliseconds potential_load(0);

        for (auto &pair: worker_jobs) {
            if (pair.second != nullptr || !pair.first->check_headers(request->headers)) {
                continue;
            }

            auto estimate = estimate_potential_worker_load(pair.first, queued_jobs);

            if (result == nullptr || estimate < potential_load) {
                result = pair.first;
                potential_load = estimate;
            }
        }

        return result;
    }
};

template <typename JobComparator, typename IdleWorkerSelector=first_idle_worker_selector>
class single_queue_manager : public queue_manager_interface
{
private:
    std::unique_ptr<JobComparator> comparator_;
    std::unique_ptr<IdleWorkerSelector> selector_;
    std::vector<request_entry> jobs_;
    std::map<worker_ptr, request_ptr> worker_jobs_;
    std::shared_ptr<const simulation_clock> clock_;

public:
    explicit single_queue_manager(std::unique_ptr<JobComparator> comparator, std::shared_ptr<const simulation_clock> clock):
        comparator_(std::move(comparator)), selector_(std::make_unique<first_idle_worker_selector>()), clock_(clock)
    {
    }

    single_queue_manager(std::unique_ptr<JobComparator> comparator, std::unique_ptr<IdleWorkerSelector> selector, std::shared_ptr<const simulation_clock> clock):
        comparator_(std::move(comparator)), selector_(std::move(selector)), clock_(clock)
    {}

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
        std::sort(jobs_.begin(), jobs_.end(), [this, worker] (const request_entry &a, const request_entry &b) {
            return comparator_->compare(a, b, worker);
        });

        for (auto it = jobs_.cbegin(); it != jobs_.cend(); ++it) {
            if (!worker->check_headers(it->request->headers)) {
                continue;
            }

            worker_jobs_[worker] = it->request;
            jobs_.erase(it);

            return worker_jobs_[worker];
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
        // Try to find an idle worker and assign the job
        auto idle_worker = selector_->select(worker_jobs_, jobs_, request);
        if (idle_worker) {
            worker_jobs_[idle_worker] = request;

            return enqueue_result{
                .assigned_to = idle_worker,
                .enqueued = true,
            };
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
        jobs_.push_back(request_entry{
            .request = request,
            .arrived_at = clock_->now()
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
