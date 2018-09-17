#!/usr/bin/Rscript
library("tidyr")
library("knitr")

source("helpers.r")

options(width = 200)

values <- load.stability.results(filename.from.args())
isolations <- unique(values[values$metric == "iso-cpu", ]$isolation) # Pick isolation techniques that use isolate
values <- values[values$isolation %in% isolations & values$taskset == F, ] # Pick measurements in isolate

data <- spread(values, key=metric, value=value)
names(data)[names(data) == 'iso-cpu'] <- 'iso_cpu'
names(data)[names(data) == 'iso-wall'] <- 'iso_wall'

data$cpu_err <- abs(data$iso_cpu - data$cpu)
data$wall_err <- abs(data$iso_wall - data$wall)

err_means <- aggregate(cpu_err ~ setup + isolation + workload + input_size, data, mean)
err_means$wl <- paste(err_means$workload, err_means$input_size, sep=" ")
err_means$wall_mean <- aggregate(wall ~ setup + isolation + workload + input_size, data, mean)$wall
err_means$cpu_mean <- aggregate(cpu ~ setup + isolation + workload + input_size, data, mean)$cpu
err_means$wall_err <- aggregate(wall_err ~ setup + isolation + workload + input_size, data, mean)$wall_err
err_means$cpu_err_mean <- aggregate(cpu_err ~ setup + isolation + workload + input_size, data, mean)$cpu_err
err_means$wall_err_mean <- aggregate(wall_err ~ setup + isolation + workload + input_size, data, mean)$wall_err
err_means$cpu_err_sd <- aggregate(cpu_err ~ setup + isolation + workload + input_size, data, sd)$cpu_err
err_means$wall_err_sd <- aggregate(wall_err ~ setup + isolation + workload + input_size, data, sd)$wall_err
err_means$cpu_err_cv <- 100 * err_means$cpu_err_sd / err_means$cpu_mean
err_means$wall_err_cv <- 100 * err_means$wall_err_sd / err_means$wall_mean

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

cat(kable(err_means[order(-err_means$wall_err_cv), c("setup", "isolation", "wl", "wall_err_mean", "wall_err_sd", "wall_err_cv")], row.names=F), file="iso_wall_errs.md", sep="\n")

cat(kable(err_means[order(-err_means$cpu_err_cv), c("setup", "isolation", "wl", "cpu_err_mean", "cpu_err_sd", "cpu_err_cv")], row.names=F), file="iso_cpu_errs.md", sep="\n")
