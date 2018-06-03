#!/usr/bin/Rscript

source("helpers.r")

values <- load.stability.results(filename.from.args())
values <- values[
		 values$isolation == "bare" & 
		 values$setup == "single" &
		 (values$metric == "cpu" | values$metric == "wall")
	 , ]

workloads <- unique(values[, c("workload", "input_size")])

for (row_workloads in 1:nrow(workloads)) {
	for (metric in c("cpu", "wall")) {
		workload <- workloads[row_workloads, "workload"]
		input_size <- workloads[row_workloads, "input_size"]
		print(sprintf("%s %s: %s", workload, input_size, metric))

		data <- values[values$workload == workload & values$input_size == input_size & values$metric == metric, ]$value

		for (split in c(5, 10, 20, 40, 60, 80)) {
			first <- data[1 : split]
			second <- na.omit(data[split + 1 : length(data)])

			print(sprintf("%d: %f %f %f%%; %f %f %f%%", split, 
				      mean(first), sd(first), cv(first), 
				      mean(second), sd(second), cv(second)
		        ))
		}
	}
}
