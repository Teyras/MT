#!/usr/bin/Rscript
library("ggplot2")
library("ggpubr")
library("tidyr")
library("tikzDevice")

source("helpers.r")

options(width = 150)
theme_set(theme_grey(base_size=7))
file <- filename.from.args()

# Read the data
values <-  read.csv(file)
names(values) = c("iteration", "workload", "input_size", "ignored", "metric", "value")
values$value <- as.numeric(values$value)
values$wl.short <- tex.safe(gsub("^[^/]*/", "", values$workload))
workloads <- unique(values[, "wl.short"])

means <- aggregate(value ~ wl.short + metric + iteration, values, mean)
sds <- aggregate(value ~ wl.short + metric + iteration, values, sd)
means$mean <- means$value
means$sd <- aggregate(value ~ wl.short + metric + iteration, values, sd)$value

summary <- gather(means, key="stat", value="statvalue", mean, sd)

characteristics <- aggregate(value ~ wl.short + metric, means, mean)
characteristics$sd_range <- aggregate(value ~ wl.short + metric, sds, range)$value
characteristics$sd_avg <- aggregate(value ~ wl.short + metric, sds, mean)$value
characteristics$sd <- aggregate(value ~ wl.short + metric, means, sd)$value
characteristics$cv <- aggregate(value ~ wl.short + metric, means, cv)$value
characteristics$mean_range <- aggregate(value ~ wl.short + metric, means, range)$value
characteristics$min <- aggregate(value ~ wl.short + metric, means, min)$value
characteristics$max <- aggregate(value ~ wl.short + metric, means, max)$value
names(characteristics)[3] = "mean"

print(characteristics[order(-characteristics$sd_range),])

tikz(file="dependence-on-input.tex", width=5.5, height=3)
plot <- ggplot(summary[summary$metric == "cpu", ], aes(x="", y=statvalue)) +
	geom_boxplot() +
	facet_grid(cols=vars(wl.short), rows=vars(stat), scales="free_y", labeller=labeller(stat=as_labeller(c(
		"mean"="Mean",
		"sd"="Standard deviation"
	)))) +
	labs(x="", y="CPU time [s]")
print(plot)
dev.off()

