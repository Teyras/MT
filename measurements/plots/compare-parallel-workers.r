#!/usr/bin/Rscript

source("helpers.r")

calculate.p.values <- function(values) {
	setups <- unique(values$setup)
	workloads <- unique(values[, c("workload", "input_size")])
	isolations <- unique(values$isolation)
	metrics <- unique(values$metric)

	size <- length(setups) * length(workloads) * length(isolations) * length(metrics) * max(values$setup_size)

	raw.data <- as.environment(list(
		setup=rep(NA, size), 
		workload=rep(NA, size), 
		input_size=rep(NA, size), 
		isolation=rep(NA, size), 
		metric=rep(NA, size), 
		worker_1=rep(NA, size), 
		worker_2=rep(NA, size), 
		ks_value=rep(NA, size), 
		ks_approx=rep(NA, size),
		median_diff=rep(NA, size)
	))

	i <- 0

	for (setup in setups) {
		for (row_workloads in 1:nrow(workloads)) {
			for (isolation in isolations) {
				for (metric in metrics) {
					subset <- values[ 
						values$setup == setup &
						values$workload == workloads[row_workloads, "workload"] &
						values$input_size == workloads[row_workloads, "input_size"] &
						values$isolation == isolation &
						values$metric == metric
					,]

					if (nrow(subset) <= 0) {
						next
					}

					workers <- unique(subset$worker)

					if (length(workers) <= 1) {
						next
					}

					for (row_workers_1 in 2:length(workers)) {
						for (row_workers_2 in 1:(row_workers_1 - 1)) {
							if  (row_workers_1 <= row_workers_2) {
								next
							}

							samples_1 <- subset[subset$worker == workers[row_workers_1], ]
							samples_2 <- subset[subset$worker == workers[row_workers_2], ]

							ks_result <- ks.test(samples_1$value, samples_2$value)

							i <- i + 1
							raw.data$setup[i] <- setup
							raw.data$workload[i] <- workloads[row_workloads, "workload"]
							raw.data$input_size[i] <- workloads[row_workloads, "input_size"]
							raw.data$isolation[i] <- isolation
							raw.data$metric[i] <- metric
							raw.data$worker_1[i] <- workers[row_workers_1]
							raw.data$worker_2[i] <- workers[row_workers_2]
							raw.data$ks_value[i] <- ks_result$p.value
							raw.data$ks_approx[i] <- length(warnings()) > 0
							raw.data$median_diff[i] <- median(samples_1$value) - median(samples_2$value)

							assign("last.warning", NULL, envir=baseenv())
						}
					}
				}
			}
		}
	}

	return(data.frame(
		setup=raw.data$setup,
		workload=raw.data$workload,
		input_size=raw.data$input_size,
		isolation=raw.data$isolation,
		metric=raw.data$metric,
		worker_1=raw.data$worker_1,
		worker_2=raw.data$worker_2,
		ks_value=raw.data$ks_value,
		ks_approx=raw.data$ks_approx,
		median_diff=raw.data$median_diff,
		stringsAsFactors=FALSE
	)[1:i, ])
}

#data <- load.stability.results(filename.from.args())

