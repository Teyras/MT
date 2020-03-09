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
        return std::chrono::milliseconds(jobs_->at(request->data.get_job_id()).processing_time.ticks());
    }
};

#endif
