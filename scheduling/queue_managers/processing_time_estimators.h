#ifndef RECODEX_BROKER_PROCESSING_TIME_ESTIMATORS_H
#define RECODEX_BROKER_PROCESSING_TIME_ESTIMATORS_H

#include "../common.h"

struct equal_length_processing_time_estimator {
    std::chrono::milliseconds estimate(const request_ptr &request, const worker_ptr &worker) const
    {
        return std::chrono::milliseconds(1000);
    }
};

struct oracle_processing_time_estimator {
    std::shared_ptr<job_data> jobs_;

    explicit oracle_processing_time_estimator(std::shared_ptr<job_data> jobs): jobs_(jobs)
    {
    }

    std::chrono::milliseconds estimate(const request_ptr &request, const worker_ptr &worker) const
    {
        return jobs_->at(request->data.get_job_id()).processing_time;
    }
};

const std::map<size_t, double> positive_error_percentiles{
    {5, 0.00'2},
    {10, 0.00'477},
    {20, 0.01'118},
    {40, 0.03'186},
    {60, 0.11'362},
    {80, 0.68'677},
    {95, 9.63243},
    {100, 635.2901}
};

const std::map<size_t, double> negative_error_percentiles{
    {5, 0.00'305},
    {10, 0.00'635},
    {20, 0.01'443},
    {40, 0.04'072},
    {60, 0.12'009},
    {80, 0.37'141},
    {95, 0.83'869},
    {100, 1}
};

const size_t positive_error_observation_count = 61260;
const size_t negative_error_observation_count = 74898;

struct imprecise_processing_time_estimator {
    std::shared_ptr<job_data> jobs_;
    std::unordered_map<request_ptr, std::chrono::milliseconds> time_estimates_;

    explicit imprecise_processing_time_estimator(std::shared_ptr<job_data> jobs): jobs_(jobs)
    {
    }

    std::chrono::milliseconds estimate(const request_ptr &request, const worker_ptr &worker)
    {
        auto previous_estimate = time_estimates_.find(request);

        if (previous_estimate != time_estimates_.end()) {
            return previous_estimate->second;
        }

        auto precise = jobs_->at(request->data.get_job_id()).processing_time;

        auto rng = std::mt19937{std::random_device{}()};
        auto percentile_distribution = std::uniform_int_distribution<size_t>(0, 99);
        auto orientation_distribution = std::uniform_int_distribution<size_t >(1, positive_error_observation_count + negative_error_observation_count);

        auto percentile = percentile_distribution(rng);
        double offset = 0;

        if (orientation_distribution(rng) >= positive_error_observation_count) {
            // Positive error
            auto it = positive_error_percentiles.upper_bound(percentile);
            auto error_upper = it->second;
            size_t error_lower = std::prev(it)->second;

            offset = std::uniform_real_distribution<double>(error_lower, error_upper)(rng);
        } else {
            // Negative error
            auto it = negative_error_percentiles.upper_bound(percentile);
            auto error_upper = it->second;
            size_t error_lower = std::prev(it)->second;

            offset = -std::uniform_real_distribution<double>(error_lower, error_upper)(rng);
        }

        auto result = precise + std::chrono::milliseconds(std::size_t(std::round(offset * precise.count())));

        time_estimates_.emplace(request, result);

        return result;
    }
};

#endif
