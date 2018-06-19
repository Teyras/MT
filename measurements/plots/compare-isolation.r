#!/usr/bin/Rscript

# TODO make coloring document-wide
# TODO separate taskset measurements

library("formattable")

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

		filename <- sprintf("isolation-comparison-%s.html", label)

		table <- format_table(frame, list(
			area(col = 1:length(isolations)+1) ~ color_tile("white", "red")
		))

		cat(sprintf("<h3>%s</h3>", paste(workload, input_size, metric, label, sep=" ")), file=filename, append=TRUE)
		cat(table, file=filename, append=TRUE)
	}
}

for (row_workloads in 1:nrow(workloads)) {
	workload <- workloads[row_workloads, "workload"]
	input_size <- workloads[row_workloads, "input_size"]

	process_workload_data(workload, input_size, "sd", function(metric) {
		return(sd)
	})

	process_workload_data(workload, input_size, "cv", function(metric) {
		return(cv)
	})

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
