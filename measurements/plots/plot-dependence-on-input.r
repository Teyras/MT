#!/usr/bin/Rscript
library("ggplot2")
library("ggpubr")

source("helpers.r")

options(width = 150)
theme_set(theme_grey(base_size=7))
file <- filename.from.args()

# Read the data
values <-  read.csv(file)
names(values) = c("iteration", "workload", "input_size", "ignored", "metric", "value")
values$value <- as.numeric(values$value)
values$wl.short <- gsub("^[^/]*/", "", values$workload)
workloads <- unique(values[, "wl.short"])

means <- aggregate(value ~ wl.short + metric + iteration, values, mean)
sds <- aggregate(value ~ wl.short + metric + iteration, values, sd)

ggplot(sds[sds$metric == "cpu", ], aes(x=value)) +
	labs(x="[s]") +
	geom_histogram() +
	facet_grid(. ~ wl.short)

ggsave(gsub("/", "-", paste("dependence-on-input-sds-histogram", ".png", sep="")), width=5.5, height=3)

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

ggplot(means[means$metric == "cpu", ], aes(x="", y=value)) +
	geom_boxplot() +
	facet_grid(. ~ wl.short) +
	labs(x="", y="[s]")

ggsave(gsub("/", "-", paste("dependence-on-input-means", ".png", sep="")), width=5.5, height=3)

ggplot(sds[sds$metric == "cpu", ], aes(x="", y=value)) +
	geom_boxplot() +
	facet_grid(. ~ wl.short) +
	labs(x="", y="[s]")

ggsave(gsub("/", "-", paste("dependence-on-input-sds", ".png", sep="")), width=5.5, height=3)

for (metric in c("cpu", "wall")) {
	plots <- list()
	for (workload in workloads) {
		plots[[length(plots) + 1]] <- ggplot(characteristics[
						     characteristics$wl.short == workload & 
						     characteristics$metric == metric
					     , ], aes(x=wl.short, y=mean_range)) + 
						geom_boxplot() +
						labs(x="", y="range [s]")
						
	}

	ggarrange(plotlist=plots, nrow=1, ncol=length(plots))
	ggsave(gsub("/", "-", paste("dependence-on-input-bars-", metric, ".png", sep="")), width=7, height=4)
}
