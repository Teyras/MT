#!/usr/bin/Rscript

source("helpers.r")

options(width = 200)

values <- load.stability.results(filename.from.args())
isolations <- unique(values[values$metric == "iso-cpu", ]$isolation)
values <- values[values$isolation %in% isolations, ]

#data <- data.frame(matrix(NA, nrow=0, ncol=))
#names(data) <- c("isolation", "setup", "workload", "input_size", "cpu", "iso_cpu", "wall", "iso_wall")

print(aggregate(value ~ setup + isolation + workload, values[values$metric == "cpu", ], length))
print(aggregate(value ~ setup + isolation + workload, values[values$metric == "iso-cpu", ], length))

data <- values[values$metric == "cpu", c("setup", "isolation", "workload", "input_size", "value")]
names(data)[names(data) == "value"] <- "cpu"

data$iso_cpu <- values[values$metric == "iso-cpu", ]$value
data$wall <- values[values$metric == "wall", ]$value
data$iso_wall <- values[values$metric == "iso-wall", ]$value

data$cpu_err <- data$iso_cpu - data$cpu
data$wall_err <- data$iso_wall - data$wall

err_means <- aggregate(cpu_err ~ setup + isolation + workload + input_size, data, mean)
err_means$wall_mean <- aggregate(wall ~ setup + isolation + workload + input_size, data, mean)$wall
err_means$cpu_mean <- aggregate(cpu ~ setup + isolation + workload + input_size, data, mean)$cpu
err_means$wall_err <- aggregate(wall_err ~ setup + isolation + workload + input_size, data, mean)$wall_err
err_means$cpu_err_sd <- aggregate(cpu_err ~ setup + isolation + workload + input_size, data, sd)$cpu_err
err_means$wall_err_sd <- aggregate(wall_err ~ setup + isolation + workload + input_size, data, sd)$wall_err
err_means$cpu_err_cv <- 100 * err_means$cpu_err_sd / err_means$cpu_mean
err_means$wall_err_cv <- 100 * err_means$wall_err_sd / err_means$wall_mean

print(err_means)
