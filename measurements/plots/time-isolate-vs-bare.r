#!/usr/bin/Rscript
library("tidyr")
library("knitr")

source("helpers.r")

options(width = 200)

values <- load.stability.results(filename.from.args())
isolations <- unique(values[values$metric == "iso-cpu", ]$isolation) # Pick isolation techniques that use isolate
values <- values[values$isolation %in% isolations & values$taskset == F & values$numa == F, ] # Pick measurements in isolate

data <- spread(values, key=metric, value=value)
names(data)[names(data) == 'iso-cpu'] <- 'iso_cpu'
names(data)[names(data) == 'iso-wall'] <- 'iso_wall'

data$cpu_err <- abs(data$iso_cpu - data$cpu)
data$wall_err <- abs(data$iso_wall - data$wall)

err_means <- aggregate(cpu_err ~ setup + isolation.short + wl.short + input_size, data, mean)
err_means$wall_mean <- aggregate(wall ~ setup + isolation.short + wl.short + input_size, data, mean)$wall
err_means$cpu_mean <- aggregate(cpu ~ setup + isolation.short + wl.short + input_size, data, mean)$cpu
err_means$wall_err <- aggregate(wall_err ~ setup + isolation.short + wl.short + input_size, data, mean)$wall_err
err_means$cpu_err_mean <- aggregate(cpu_err ~ setup + isolation.short + wl.short + input_size, data, mean)$cpu_err
err_means$wall_err_mean <- aggregate(wall_err ~ setup + isolation.short + wl.short + input_size, data, mean)$wall_err
err_means$cpu_err_sd <- aggregate(cpu_err ~ setup + isolation.short + wl.short + input_size, data, sd)$cpu_err
err_means$wall_err_sd <- aggregate(wall_err ~ setup + isolation.short + wl.short + input_size, data, sd)$wall_err
err_means$cpu_err_cv <- 100 * err_means$cpu_err_sd / err_means$cpu_mean
err_means$wall_err_cv <- 100 * err_means$wall_err_sd / err_means$wall_mean

wall_threshold <- aggregate(wall_err_cv ~ setup + isolation.short, err_means, length)
names(wall_threshold)[names(wall_threshold) == 'wall_err_cv'] <- 'total'
wall_threshold$over_20 <- aggregate(wall_err_cv ~ setup + isolation.short, err_means, function (data) {
	return (length(data[data > 20]));
})$wall_err_cv

wall_threshold$over_10 <- aggregate(wall_err_cv ~ setup + isolation.short, err_means, function (data) {
	return (length(data[data > 10]));
})$wall_err_cv

wall_threshold$over_5 <- aggregate(wall_err_cv ~ setup + isolation.short, err_means, function (data) {
	return (length(data[data > 5]));
})$wall_err_cv

col.names <- c("Setup", "Isolation", "Workload", "Mean [s]", "SD", "CV [%]")

cat("
Table: Mean and standard deviation of the error of isolate wall-clock time measurements (truncated) \\label{iso-wall-err}
", file="iso-wall-err.md", sep="\n")
cat(my.kable(err_means[order(-err_means$wall_err_cv), c("setup", "isolation.short", "wl.short", "wall_err_mean", "wall_err_sd", "wall_err_cv")][err_means$wall_err_cv > 15, ], col.names=col.names), file="iso-wall-err.md", sep="\n", append=TRUE)

cat("
Table: Mean and standard deviation of the error of isolate CPU time measurements, sorted by relative error (truncated) \\label{iso-cpu-err}
", file="iso-cpu-err.md", sep="\n")
cat(my.kable(err_means[order(-err_means$cpu_err_cv), c("setup", "isolation.short", "wl.short", "cpu_err_mean", "cpu_err_sd", "cpu_err_cv")][err_means$cpu_err_cv > 5, ], col.names=col.names), file="iso-cpu-err.md", sep="\n", append=TRUE)
