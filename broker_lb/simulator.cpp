#include <iostream>
#include <set>
#include <vector>

#include <boost/algorithm/string.hpp>

#include <yaml-cpp/yaml.h>

#include "broker/src/broker_connect.h"
#include "broker/src/handlers/broker_handler.h"
#include "broker/src/queuing/multi_queue_manager.h"

#include "common.h"
#include "queue_managers/multi_queue_manager.h"
#include "queue_managers/processing_time_estimators.h"
#include "queue_managers/single_queue_manager.h"


void load_workers(broker_handler &handler, std::istream &input)
{
	auto config = YAML::Load(input);
	auto workers = config["workers"];

	for (auto it = std::begin(workers); it != std::end(workers); ++it) {
		std::vector<std::string> init_data = {"init", it->second["hwgroup"].as<std::string>()};
		for (auto it_headers = std::begin(it->second["headers"]); it_headers != std::end(it->second["headers"]);
			 ++it_headers) {
			init_data.push_back(it_headers->as<std::string>());
		}
		init_data.emplace_back("");
		init_data.emplace_back("description=" + it->first.as<std::string>());

		handler.on_request(message_container(broker_connect::KEY_WORKERS, it->first.as<std::string>(), init_data),
			[](const message_container &) {});
	}
}

using worker_status_map = std::map<std::string, bool>;

std::shared_ptr<queue_manager_interface> create_queue_manager(
	const std::string &type, std::shared_ptr<worker_registry> registry, std::shared_ptr<job_data> jobs, std::shared_ptr<const simulation_clock> clock)
{
	if (type == "multi_rr") {
		return std::make_shared<multi_queue_manager>();
	}

	if (type == "single_fcfs") {
		auto comparator = std::make_unique<fcfs_job_comparator>();
		return std::make_shared<single_queue_manager<fcfs_job_comparator>>(std::move(comparator), clock);
	}

	if (type == "single_lf") {
		auto comparator = std::make_unique<least_flexibility_job_comparator>(*registry);
		return std::make_shared<single_queue_manager<least_flexibility_job_comparator>>(std::move(comparator), clock);
	}

	if (type == "single_spt_oracle") {
		auto comparator = std::make_unique<shortest_processing_time_job_comparator<oracle_processing_time_estimator>>(
			std::make_shared<oracle_processing_time_estimator>(jobs));
		return std::make_shared<
			single_queue_manager<shortest_processing_time_job_comparator<oracle_processing_time_estimator>>>(
			std::move(comparator), clock);
	}

    if (type == "single_spt_imprecise") {
        auto comparator = std::make_unique<shortest_processing_time_job_comparator<imprecise_processing_time_estimator>>(
                std::make_shared<imprecise_processing_time_estimator>(jobs));
        return std::make_shared<
                single_queue_manager<shortest_processing_time_job_comparator<imprecise_processing_time_estimator>>>(
                std::move(comparator), clock);
    }

    if (type == "single_edf_oracle") {
        auto comparator = std::make_unique<earliest_deadline_job_comparator<oracle_processing_time_estimator>>(
                std::make_shared<oracle_processing_time_estimator>(jobs));
        return std::make_shared<
                single_queue_manager<earliest_deadline_job_comparator<oracle_processing_time_estimator>>>(
                std::move(comparator), clock);
    }

	if (type == "single_edf_imprecise") {
		auto comparator = std::make_unique<earliest_deadline_job_comparator<imprecise_processing_time_estimator>>(
			std::make_shared<imprecise_processing_time_estimator>(jobs));
		return std::make_shared<
			single_queue_manager<earliest_deadline_job_comparator<imprecise_processing_time_estimator>>>(
			std::move(comparator), clock);
	}

	if (type == "oagm_oracle") {
		auto estimator = std::make_shared<oracle_processing_time_estimator>(jobs);
		auto comparator = std::make_unique<oagm_job_comparator<oracle_processing_time_estimator>>(estimator, *registry);
		auto selector =
			std::make_unique<least_loaded_idle_worker_selector<oracle_processing_time_estimator>>(estimator);
		return std::make_shared<single_queue_manager<oagm_job_comparator<oracle_processing_time_estimator>,
			least_loaded_idle_worker_selector<oracle_processing_time_estimator>>>(
			std::move(comparator), std::move(selector), clock);
	}

    if (type == "oagm_imprecise") {
        auto estimator = std::make_shared<imprecise_processing_time_estimator>(jobs);
        auto comparator = std::make_unique<oagm_job_comparator<imprecise_processing_time_estimator>>(estimator, *registry);
        auto selector =
                std::make_unique<least_loaded_idle_worker_selector<imprecise_processing_time_estimator>>(estimator);
        return std::make_shared<single_queue_manager<oagm_job_comparator<imprecise_processing_time_estimator>,
                least_loaded_idle_worker_selector<imprecise_processing_time_estimator>>>(
                std::move(comparator), std::move(selector), clock);
    }

	if (type == "multi_ll_queue_size") {
		auto selector = std::make_unique<least_loaded_worker_selector<equal_length_processing_time_estimator>>(
			std::make_unique<equal_length_processing_time_estimator>());
		return std::make_shared<
			advanced_multi_queue_manager<least_loaded_worker_selector<equal_length_processing_time_estimator>>>(
			std::move(selector));
	}

	if (type == "multi_ll_oracle") {
		auto selector = std::make_unique<least_loaded_worker_selector<oracle_processing_time_estimator>>(
			std::make_unique<oracle_processing_time_estimator>(jobs));
		return std::make_shared<
			advanced_multi_queue_manager<least_loaded_worker_selector<oracle_processing_time_estimator>>>(
			std::move(selector));
	}

    if (type == "multi_ll_imprecise") {
        auto selector = std::make_unique<least_loaded_worker_selector<imprecise_processing_time_estimator>>(
                std::make_unique<imprecise_processing_time_estimator>(jobs));
        return std::make_shared<
                advanced_multi_queue_manager<least_loaded_worker_selector<imprecise_processing_time_estimator>>>(
                std::move(selector));
    }

	if (type == "multi_rand2_queue_size") {
		auto selector = std::make_unique<two_random_choices_selector<equal_length_processing_time_estimator>>(
			std::make_unique<equal_length_processing_time_estimator>());
		return std::make_shared<
			advanced_multi_queue_manager<two_random_choices_selector<equal_length_processing_time_estimator>>>(
			std::move(selector));
	}

	if (type == "multi_rand2_oracle") {
		auto selector = std::make_unique<two_random_choices_selector<oracle_processing_time_estimator>>(
			std::make_unique<oracle_processing_time_estimator>(jobs));
		return std::make_shared<
			advanced_multi_queue_manager<two_random_choices_selector<oracle_processing_time_estimator>>>(
			std::move(selector));
	}

    if (type == "multi_rand2_imprecise") {
        auto selector = std::make_unique<two_random_choices_selector<imprecise_processing_time_estimator>>(
                std::make_unique<imprecise_processing_time_estimator>(jobs));
        return std::make_shared<
                advanced_multi_queue_manager<two_random_choices_selector<imprecise_processing_time_estimator>>>(
                std::move(selector));
    }

	throw std::runtime_error("Unknown queue manager type");
}

/**
 * Load jobs from a CSV file where a row contains the arrival time, processing time, and a varying number of columns for
 * headers.
 */
void load_jobs(std::shared_ptr<job_data> jobs, std::istream &input)
{
	size_t i = 1;
	const auto ws = "\t\n\v\f\r ";

	for (std::string line; std::getline(input, line);) {
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

		jobs->emplace(job_id,
			simulation_job{.job_id = job_id,
				.data = job_data,
				.arrival_time = std::chrono::milliseconds(std::stoll(entry[0])),
				.processing_time = std::chrono::milliseconds(std::stoll(entry[1])),
				.processing_started_time = std::chrono::milliseconds(0)});
	}
}

using event_queue = std::multimap<std::chrono::milliseconds, std::function<void()>>;

struct periodic_event {
	std::function<void()> execute;
	std::chrono::milliseconds period;
	std::chrono::milliseconds next_execution_at;
};

class simulation
{
private:
	worker_status_map worker_status_;
	broker_handler &handler_;

	event_queue events_;
	std::vector<periodic_event> periodic_events_;
	std::shared_ptr<job_data> job_data_;
    std::shared_ptr<simulation_clock> clock_;

	void respond_(const message_container &message)
	{
		if (message.key == broker_connect::KEY_WORKERS) {
			if (message.data.at(0) == "eval") {
				const std::string job_id = message.data.at(1);
				const std::string identity = message.identity;
				simulation_job &job = job_data_->at(job_id);
				job.processing_started_time = clock_->now();

				auto completion_time = job.processing_started_time + job.processing_time;
				events_.emplace(completion_time, [this, identity, job_id]() {
					handler_.on_request(
						message_container(broker_connect::KEY_WORKERS, identity, {"done", job_id, "OK"}),
						[this](const auto &message) { respond_(message); });
				});
			}
		}

		if (message.key == broker_connect::KEY_CLIENTS) {
			if (message.data.at(0) == "reject") {
                throw std::runtime_error("A job was rejected");
			}
		}
	}

public:
	simulation(broker_handler &handler, std::shared_ptr<job_data> jobs, std::shared_ptr<worker_registry> registry, std::shared_ptr<simulation_clock> clock)
		: handler_(handler), job_data_(jobs), clock_(clock)
	{
		// Initialize worker status
		for (auto &worker : registry->get_workers()) {
			worker_status_[worker->identity] = true;
		}

		// Schedule job arrivals
		for (auto &it : *jobs) {
			events_.emplace(it.second.arrival_time, [this, it]() {
				handler_.on_request(message_container(broker_connect::KEY_CLIENTS, "", it.second.data),
					[this](const auto &message) { respond_(message); });
			});
		}

		// Schedule periodic invocation of reactor timer (used for time tracking by the broker)
		std::chrono::milliseconds timer_period(100);
		periodic_events_.push_back(periodic_event{
			.execute =
				[this, timer_period]() {
					handler_.on_request(
						message_container(broker_connect::KEY_TIMER, "", {std::to_string(timer_period.count())}),
						[this](const auto &msg) { respond_(msg); });
				},
			.period = timer_period,
			.next_execution_at = std::chrono::milliseconds(0)});

		// Schedule periodic pings from active workers
		std::chrono::milliseconds ping_period(500);
		periodic_events_.push_back(periodic_event{
			.execute =
				[this]() {
					for (auto &it : worker_status_) {
						if (!it.second) {
							continue; // The worker is down
						}

						handler_.on_request(message_container(broker_connect::KEY_WORKERS, it.first, {"ping"}),
							[this](const auto &message) { respond_(message); });
					}
				},
			.period = ping_period,
			.next_execution_at = std::chrono::milliseconds(0)});
	}

	void run()
	{
		clock_->set(std::chrono::milliseconds(0));

		while (!events_.empty()) {
			// Pick first event in the queue
			auto next_event = std::begin(events_);

            if (next_event->first < clock_->now()) {
                throw std::runtime_error("Error in event ordering");
            }

			// Execute periodic events that precede the selected event
			while (std::any_of(periodic_events_.cbegin(),
				periodic_events_.cend(),
				[next_event](const periodic_event &event) { return event.next_execution_at <= next_event->first; })) {
				// Select the first periodic event to happen
				auto event = std::min_element(periodic_events_.begin(),
					periodic_events_.end(),
					[](const periodic_event &a, const periodic_event &b) {
						return a.next_execution_at < b.next_execution_at;
					});

				clock_->set(event->next_execution_at);
				event->execute();
				event->next_execution_at += event->period;
			}

			// Execute the event and remove it from the queue
			clock_->set(next_event->first);
			next_event->second();
			events_.erase(next_event);
		}
	}
};

int main(int argc, char **argv)
{
	// The configuration is used only for maximum liveness, ping interval and maximum failure count.
	// Failure count is not used (we will not test job failures).
	// For maximum liveness and ping interval, we will use the default values.
	auto config = std::make_shared<const broker_config>();

	// Prepare a worker registry
	auto registry = std::make_shared<worker_registry>();

	// Load jobs to be simulated
	auto jobs = std::make_shared<job_data>();

	std::ifstream jobs_file(argv[3]);
	load_jobs(jobs, jobs_file);

    // Create a simulation clock
    auto clock = std::make_shared<simulation_clock>();

	// Create one of the predefined queue managers
	auto queue = create_queue_manager(argv[1], registry, jobs, clock);

	// Create a logger that outputs to stderr
	auto sink = std::make_shared<spdlog::sinks::stderr_sink_mt>();
	auto logger = spdlog::create("broker", sink);
	logger->set_level(spdlog::level::debug);

	broker_handler handler(config, registry, queue, logger);

	// Fill the registry and queue according to specification from the command line
	std::ifstream workers_file(argv[2]);
	load_workers(handler, workers_file);

	// Run the simulation
	simulation sim{handler, jobs, registry, clock};
	sim.run();

	// Print results
	size_t unprocessed_job_count = queue->get_queued_request_count();
	if (unprocessed_job_count) {
        logger->error("There are {} jobs left in the queue", unprocessed_job_count);
		return 1;
	}

	logger->info("Simulation finished in {} ms", std::to_string(clock->now().count()));

	for (auto &it : *jobs) {
		std::cout << it.second.job_id << "," << it.second.arrival_time.count() << ","
				  << it.second.processing_time.count() << "," << it.second.processing_started_time.count() << std::endl;
	}

	return 0;
}