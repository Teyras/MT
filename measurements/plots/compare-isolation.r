#!/usr/bin/Rscript

source("helpers.r")

options(width=200)

values <- load.stability.results(filename.from.args())

isolations <- unique(values$isolation)
setups <- unique(values$setup)
workloads <- unique(values[, c("workload", "input_size")])

process_workload_data <- function(workload, input_size, label, aggregation_func) {
	for (metric in c("cpu", "wall")) {
		frame = data.frame(matrix(NA, nrow=0, ncol=length(isolations) + 1))
		names(frame) <- c("setup", isolations)

		for (row_setups in 1:length(setups)) {
			setup <- setups[row_setups]
			subset <- values[
				values$workload == workload & 
				values$input_size == input_size & 
				values$metric == metric &
				values$setup == setup
			, c("isolation", "value")]

			data <- aggregate(value ~ isolation, subset, aggregation_func(metric))$value
			frame[nrow(frame) + 1, ] <- c(setup, data)
		}

		print(paste(workload, input_size, metric, label, sep=" "))
		print(frame)
	}
}

for (row_workloads in 1:nrow(workloads)) {
	workload <- workloads[row_workloads, "workload"]
	input_size <- workloads[row_workloads, "input_size"]

	process_workload_data(workload, input_size, "span", function(metric) {
		return(span)
	})

	ref_subset <- values[
		values$workload == workload & 
		values$input_size == input_size & 
		values$isolation == "bare" &
		values$setup == "single"
	, c("metric", "value")]

	ref_span <- aggregate(value ~ metric, ref_subset, span)

	process_workload_data(workload, input_size, "span_relative", function(metric) {
		return(function (data) {
			return(span(data) / ref_span[ref_span$metric == metric, ]$value[1])
		})
	})
}

warnings()
