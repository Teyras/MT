#!/usr/bin/Rscript
library("ggplot2")
library("ggpubr")

source("helpers.r")

options(width = 150)
theme_set(theme_grey(base_size=7))
file <- filename.from.args()

# Read the data
values <-  read.csv(file)
names(values) = c("blank", "workload", "input_size", "iteration", "metric", "value")
values$value <- as.numeric(values$value)
values$wl <- paste(values$workload, values$input_size, sep="\n")
workloads <- unique(values[, "wl"])

means <- aggregate(value ~ wl + metric + iteration, values, mean)
sds <- aggregate(value ~ wl + metric + iteration, values, sd)

ggplot(sds[sds$metric == "cpu", ], aes(x=value)) +
	labs(x="[s]") +
	geom_histogram()

ggsave(gsub("/", "-", paste("dependence-on-input-sds-histogram", ".png", sep="")), width=4, height=3)

characteristics <- aggregate(value ~ wl + metric, means, mean)
characteristics$sd_range <- aggregate(value ~ wl + metric, sds, range)$value
characteristics$sd_avg <- aggregate(value ~ wl + metric, sds, mean)$value
characteristics$sd <- aggregate(value ~ wl + metric, means, sd)$value
characteristics$cv <- aggregate(value ~ wl + metric, means, cv)$value
characteristics$mean_range <- aggregate(value ~ wl + metric, means, range)$value
characteristics$min <- aggregate(value ~ wl + metric, means, min)$value
characteristics$max <- aggregate(value ~ wl + metric, means, max)$value
names(characteristics)[3] = "mean"

print(characteristics[order(-characteristics$sd_range),])

ggplot(characteristics[characteristics$metric == "cpu", ], aes(x="", y=mean_range)) +
	geom_boxplot() +
	facet_grid(. ~ wl) +
	labs(x="", y="[s]")

ggsave(gsub("/", "-", paste("dependence-on-input-means", ".png", sep="")), width=4, height=3)

ggplot(characteristics[characteristics$metric == "cpu", ], aes(x="", y=sd_range)) +
	geom_boxplot() +
	facet_grid(. ~ wl) +
	labs(x="", y="[s]")

ggsave(gsub("/", "-", paste("dependence-on-input-sds", ".png", sep="")), width=4, height=3)

for (metric in c("cpu", "wall")) {
	plots <- list()
	for (workload in workloads) {
		plots[[length(plots) + 1]] <- ggplot(characteristics[
						     characteristics$wl == workload & 
						     characteristics$metric == metric
					     , ], aes(x=wl, y=mean_range)) + 
						geom_boxplot() +
						labs(x="", y="range [s]")
						
	}

	ggarrange(plotlist=plots, nrow=1, ncol=length(plots))
	ggsave(gsub("/", "-", paste("dependence-on-input-bars-", metric, ".png", sep="")), width=7, height=4)
}
