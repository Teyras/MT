#!/usr/bin/Rscript
library("ggplot2")
library("ggpubr")

args <- commandArgs(trailingOnly=TRUE)

if (length(args) == 0) {
	stop("Please, supply a result file as a CLI argument")
}

# Read the data
lines = readLines(args[1])
values = as.data.frame(do.call(rbind, strsplit(lines, split="[ :]+")), stringsAsFactors=FALSE)
names(values) = c("iteration", "workload", "input_size", "metric", "value")
values$value <- as.numeric(values$value)

means <- aggregate(value ~ workload + input_size + metric + iteration, values, mean)

characteristics <- aggregate(value ~ workload + input_size + metric, means, mean)
characteristics$sd <- aggregate(value ~ workload + input_size + metric, means, sd)$value
characteristics$cv <- (characteristics$sd * 100) / characteristics$value
names(characteristics)[4] = "mean"

print(characteristics[order(characteristics$cv),])

ggplot(means, aes(x="", y=value)) +
	geom_boxplot() +
	facet_grid(workload + input_size ~ metric)

ggsave(gsub("/", "-", paste("dependence-on-input", ".png", sep="")))
