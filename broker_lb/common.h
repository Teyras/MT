#ifndef RECODEX_BROKER_COMMON_H
#define RECODEX_BROKER_COMMON_H

struct simulation_job {
    std::string job_id;
    std::vector<std::string> data;
    boost::posix_time::milliseconds arrival_time;
    boost::posix_time::milliseconds processing_time; // How long the job takes
    boost::posix_time::milliseconds processing_started_time;
};

using job_data = std::map<std::string, simulation_job>;

#endif
