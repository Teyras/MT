#!/usr/bin/Rscript

library("zoo")
library("ggplot2")
library("ggpubr")

source("helpers.r")

values <- load.stability.results(filename.from.args())
values <- values[
		 values$isolation == "bare" & 
		 values$setup_type == "single" &
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

plot.rolling.sd <- function(data, title) {
	data$rolling <- rollapply(data$value, 10, sd, align="center", fill=c(NA, NA, NA))
	result <- ggplot(data, aes(x=iteration)) +
		geom_path(aes(y=rolling)) +
		geom_hline(yintercept=sd(data$value)) +
		labs(title=title, x="t")

	return(result)
}


plots <- list()

for (row_workloads in 1:nrow(workloads)) {
	for (metric in c("cpu", "wall")) {
		workload <- workloads[row_workloads, "workload"]
		input_size <- workloads[row_workloads, "input_size"]

		plot <- plot.rolling.sd(values[
			values$metric == metric & 
			values$workload == workload &
			values$input_size == input_size
		, ], title=paste(workload, input_size, metric, sep=", "))

		plots[[length(plots) + 1]] <- plot
	}
}

plot <- ggarrange(plotlist=plots, ncol=2, nrow=length(plots) / 2)

plot

ggsave(gsub("/", "-", paste("warmup", ".png", sep="")), width=10, height=10, units="in")
