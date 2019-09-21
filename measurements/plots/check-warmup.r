#!/usr/bin/Rscript

library("zoo")
library("ggplot2")
library("ggpubr")
library("tikzDevice")

source("helpers.r")

values <- load.stability.results(filename.from.args())
values <- values[
		 values$isolation == "bare" & 
		 values$setup_type == "single" &
		 (values$metric == "cpu" | values$metric == "wall")
	 , ]

workloads <- unique(values[, c("workload", "input_size")])

print.summaries <- function() {
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
}

plot.rolling.sd <- function(data, title) {
	data$rolling <- rollapply(data$value, 10, sd, align="center", fill=c(NA, NA, NA))
	result <- ggplot(data, aes(x=iteration)) +
		geom_path(aes(y=rolling)) +
		geom_hline(aes(yintercept=sd(data$value)), colour="blue") +
		labs(title=title, x="iteration", y="time[s]")

	return(result)
}

plot.points <- function(data, title) {
	plot <- ggplot(data, aes(x=iteration)) +
		geom_point(aes(y=data$value)) +
		labs(title=title, x="iteration", y="time[s]")
	return(plot)
}


plot.summaries <- function() {
	plots <- list()

	for (row_workloads in 1:nrow(workloads)) {
		for (metric in c("cpu", "wall")) {
			workload <- workloads[row_workloads, "workload"]
			input_size <- workloads[row_workloads, "input_size"]

			plot <- plot.points(values[
				values$metric == metric & 
				values$workload == workload &
				values$input_size == input_size
			, ], title=paste(workload, input_size, metric, sep=", "))

			plots[[length(plots) + 1]] <- plot
		}
	}

	ggarrange(plotlist=plots, ncol=2, nrow=length(plots) / 2)
	ggsave(gsub("/", "-", paste("warmup", ".png", sep="")), width=5.5, height=9, units="in")
}

plot.bsearch <- function() {
	plot.points(values[
		values$metric == "cpu" & 
		values$workload == "bsearch/bsearch" &
		values$input_size == "65536_1048576"
	, ], title="")

	ggsave(gsub("/", "-", paste("warmup-bsearch", ".png", sep="")), width=5.5, height=4, units="in")
}

plot.selection <- function() {
	tikz(file="warmup.tex", width=5.5, height=4)

	ggarrange(
		plot.points(values[
			values$metric == "cpu" & 
			values$workload == "exp/exp_float"
		, ], title="exp\\textunderscore float"),
		plot.points(values[
			values$metric == "cpu" & 
			values$workload == "bsearch/bsearch"
		, ], title="bsearch"),
		plot.points(values[
			values$metric == "cpu" & 
			values$workload == "gray/gray2bin"
		, ], title="gray2bin"),
		plot.points(values[
			values$metric == "cpu" & 
			values$workload == "sort/qsort"
		, ], title="qsort"),
		common.legend=T,
		ncol=2,
		nrow=2
	)

	#dev.off()
}

plot.selection()
