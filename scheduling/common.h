#ifndef RECODEX_BROKER_COMMON_H
#define RECODEX_BROKER_COMMON_H

struct simulation_job {
    std::string job_id;
    std::vector<std::string> data;
    std::chrono::milliseconds arrival_time;
    std::chrono::milliseconds processing_time; // How long the job takes
    std::chrono::milliseconds processing_started_time;
};

using job_data = std::map<std::string, simulation_job>;

class simulation_clock {
private:
    std::chrono::milliseconds now_ = std::chrono::milliseconds(0);
public:
    std::chrono::milliseconds now() const
    {
        return now_;
    }

    void set(std::chrono::milliseconds value)
    {
        now_ = value;
    }
};

#endif
