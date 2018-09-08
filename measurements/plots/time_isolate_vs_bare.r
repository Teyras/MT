#!/usr/bin/Rscript
library("tidyr")

source("helpers.r")

options(width = 200)

values <- load.stability.results(filename.from.args())
isolations <- unique(values[values$metric == "iso-cpu", ]$isolation) # Pick isolation techniques that use isolate
values <- values[values$isolation %in% isolations, ] # Pick measurements in isolate

data <- spread(values, key=metric, value=value)
names(data)[names(data) == 'iso-cpu'] <- 'iso_cpu'
names(data)[names(data) == 'iso-wall'] <- 'iso_wall'

data$cpu_err <- abs(data$iso_cpu - data$cpu)
data$wall_err <- abs(data$iso_wall - data$wall)

err_means <- aggregate(cpu_err ~ setup + isolation + workload + input_size, data, mean)
err_means$wall_mean <- aggregate(wall ~ setup + isolation + workload + input_size, data, mean)$wall
err_means$cpu_mean <- aggregate(cpu ~ setup + isolation + workload + input_size, data, mean)$cpu
err_means$wall_err <- aggregate(wall_err ~ setup + isolation + workload + input_size, data, mean)$wall_err
err_means$cpu_err_mean <- aggregate(cpu_err ~ setup + isolation + workload + input_size, data, mean)$cpu_err
err_means$wall_err_mean <- aggregate(wall_err ~ setup + isolation + workload + input_size, data, mean)$wall_err
err_means$cpu_err_sd <- aggregate(cpu_err ~ setup + isolation + workload + input_size, data, sd)$cpu_err
err_means$wall_err_sd <- aggregate(wall_err ~ setup + isolation + workload + input_size, data, sd)$wall_err
err_means$cpu_err_cv <- 100 * err_means$cpu_err_sd / err_means$cpu_mean
err_means$wall_err_cv <- 100 * err_means$wall_err_sd / err_means$wall_mean

print("cpu")
print(err_means[order(-err_means$cpu_err_mean), ][1:20, c("setup", "isolation", "workload", "input_size", "cpu_err_mean")])
print(err_means[order(-err_means$cpu_err_cv), ][1:20, c("setup", "isolation", "workload", "input_size", "cpu_err_cv")])

print("wall")
print(err_means[order(-err_means$wall_err_mean), ][1:20, c("setup", "isolation", "workload", "input_size", "wall_err_mean")])
print(err_means[order(-err_means$wall_err_cv), ][1:20, c("setup", "isolation", "workload", "input_size", "wall_err_cv")])

wall_threshold <- aggregate(wall_err_cv ~ setup + isolation, err_means, length)
names(wall_threshold)[names(wall_threshold) == 'wall_err_cv'] <- 'total'
wall_threshold$over_20 <- aggregate(wall_err_cv ~ setup + isolation, err_means, function (data) {
	return (length(data[data > 20]));
})$wall_err_cv

wall_threshold$over_10 <- aggregate(wall_err_cv ~ setup + isolation, err_means, function (data) {
	return (length(data[data > 10]));
})$wall_err_cv

wall_threshold$over_5 <- aggregate(wall_err_cv ~ setup + isolation, err_means, function (data) {
	return (length(data[data > 5]));
})$wall_err_cv

print(wall_threshold[order(-wall_threshold$over_20),])
