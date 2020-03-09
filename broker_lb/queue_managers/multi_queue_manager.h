#ifndef RECODEX_BROKER_MULTI_QUEUE_MANAGER_H
#define RECODEX_BROKER_MULTI_QUEUE_MANAGER_H

#include <algorithm>
#include <random>

#include "../broker/src/queuing/queue_manager_interface.h"
#include "../common.h"


template <typename ProcessingTimeEstimator>
size_t estimate_queue_length(const worker_ptr &worker, const std::vector<request_ptr> &queue, const ProcessingTimeEstimator &estimator)
{
    size_t result = 0;

    for (auto &request: queue) {
        result += estimator->estimate(request, worker).count();
    }

    return result;
}

template <typename ProcessingTimeEstimator>
struct least_loaded_worker_selector {
    std::unique_ptr<ProcessingTimeEstimator> processing_time_estimator;

    explicit least_loaded_worker_selector(std::unique_ptr<ProcessingTimeEstimator> processing_time_estimator):
            processing_time_estimator(std::move(processing_time_estimator))
    {}

    worker_ptr select(const std::map<worker_ptr, std::vector<request_ptr>> &queues, request_ptr request) const
    {
        std::vector<worker_ptr> eligible_workers;

        for (auto &pair: queues) {
            if (pair.first->check_headers(request->headers)) {
                eligible_workers.push_back(pair.first);
            }
        }

        if (eligible_workers.empty()) {
            return nullptr;
        }

        return *std::min_element(
            eligible_workers.begin(),
            eligible_workers.end(),
            [this, &queues] (const worker_ptr &a, const worker_ptr &b) {
                return estimate_queue_length(a, queues.at(a), processing_time_estimator) < estimate_queue_length(b, queues.at(b), processing_time_estimator);
            }
        );
    }
};

template <typename ProcessingTimeEstimator>
struct two_random_choices_selector {
    std::unique_ptr<ProcessingTimeEstimator> processing_time_estimator;

    explicit two_random_choices_selector(std::unique_ptr<ProcessingTimeEstimator> processing_time_estimator) :
            processing_time_estimator(std::move(processing_time_estimator))
            {}

    worker_ptr select(const std::map<worker_ptr, std::vector<request_ptr>> &queues, request_ptr request) const {
        std::vector<worker_ptr> eligible_workers;

        for (auto &pair: queues) {
            if (pair.first->check_headers(request->headers)) {
                eligible_workers.push_back(pair.first);
            }
        }

        if (eligible_workers.empty()) {
            return nullptr;
        }

        if (eligible_workers.size() == 1) {
            return eligible_workers[0];
        }

        std::array<worker_ptr, 2> selected_workers;
        std::sample(
            eligible_workers.cbegin(),
            eligible_workers.cend(),
            selected_workers.begin(),
            selected_workers.size(),
            std::mt19937{std::random_device{}()}
        );

        if (estimate_queue_length(selected_workers[0], queues.at(selected_workers[0]), processing_time_estimator) < estimate_queue_length(selected_workers[1], queues.at(selected_workers[1]), processing_time_estimator)) {
            return selected_workers[0];
        } else {
            return selected_workers[1];
        }
    }
};

template <typename WorkerSelector>
class advanced_multi_queue_manager : public queue_manager_interface {
private:
    std::map<worker_ptr, std::vector<request_ptr>> queues_;
    std::map<worker_ptr, request_ptr> current_requests_;
    std::unique_ptr<WorkerSelector> worker_selector_;
public:
    explicit advanced_multi_queue_manager(std::unique_ptr<WorkerSelector> worker_selector):
        worker_selector_(std::move(worker_selector))
    {}

    request_ptr add_worker(worker_ptr worker, request_ptr current_request) override
    {
        queues_.emplace(worker, std::vector<request_ptr>());
        current_requests_.emplace(worker, current_request);
        return nullptr;
    }

    std::shared_ptr<std::vector<request_ptr>> worker_terminated(worker_ptr worker) override
    {
        auto result = std::make_shared<std::vector<request_ptr>>();

        if (current_requests_[worker] != nullptr) {
            result->push_back(current_requests_[worker]);
        }

        while (!queues_[worker].empty()) {
            result->push_back(queues_[worker].front());
            queues_[worker].erase(queues_[worker].cbegin());
        }

        queues_.erase(worker);
        current_requests_.erase(worker);

        return result;
    }

    enqueue_result enqueue_request(request_ptr request) override
    {
        enqueue_result result;
        result.enqueued = false;

        // Look for a suitable worker
        worker_ptr worker = nullptr;

        worker_selector_->select(queues_, request);

        // If a worker was found, enqueue the request
        if (worker) {
            result.enqueued = true;

            if (current_requests_[worker] == nullptr) {
                // The worker is free -> assign the request right away
                current_requests_[worker] = request;
                result.assigned_to = worker;
            } else {
                // The worker is occupied -> put the request in its queue
                queues_[worker].push_back(request);
            }
        }

        return result;
    }

    request_ptr worker_finished(worker_ptr worker) override
    {
        current_requests_[worker] = nullptr;

        if (queues_[worker].empty()) {
            return nullptr;
        }

        request_ptr new_request = queues_[worker].front();
        queues_[worker].erase(queues_[worker].cbegin());
        current_requests_[worker] = new_request;

        return new_request;
    }

    request_ptr get_current_request(worker_ptr worker) override
    {
        return current_requests_[worker];
    }

    request_ptr assign_request(worker_ptr worker) override
    {
        if (queues_[worker].empty()) {
            return nullptr;
        }

        request_ptr new_request = queues_[worker].front();
        queues_[worker].erase(queues_[worker].cbegin());
        current_requests_[worker] = new_request;

        return new_request;
    }

    request_ptr worker_cancelled(worker_ptr worker) override
    {
        auto request = current_requests_[worker];
        current_requests_[worker] = nullptr;
        return request;
    }

    std::size_t get_queued_request_count() override
    {
        std::size_t result = 0;

        for (auto &pair : queues_) {
            result += pair.second.size();
        }

        return result;
    }
};

#endif
