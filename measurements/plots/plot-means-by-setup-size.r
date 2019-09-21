#!/usr/bin/Rscript
library("ggplot2")
library("ggpubr")
library("tikzDevice")
library("boot")

source("helpers.r")

values <- load.stability.results(filename.from.args())
workloads <- c("exp/exp_float", "bsearch/bsearch", "gray/gray2bin", "sort/qsort", "sort/qsort_java.sh", "sort/qsort.py")
isolations <- unique(values$isolation)
metrics <- c("cpu", "iso-wall")

values <- values[
		 values$setup_type %in% c("single", "parallel-homogenous") & 
		 values$workload %in% workloads &
		 values$taskset == F & 
		 values$multi == F & 
		 values$numa == F & 
		 values$noht == F &
		 values$worker == "cpu-0" &
		 values$metric %in% metrics,
	 ]

wl.labels <- function(labels) {
	return(lapply(labels, function(wl) {
		if (wl == "exp_float") {
			return("exp\\_float")
		}

		if (wl == "qsort_java.sh") {
			return("qsort.java")
		}

		return(wl)
	}))
}

plot.means <- function() {
	means <- do.call(data.frame, aggregate(value ~ wl.short + isolation + setup_size, values, function(x) {
		return(c(mean=mean(x), sd=sd(x)))
	}))

	means$ref.mean <- apply(means[, c("wl.short", "isolation") ], 1, function(row) {
		return(means[means$wl.short == row[1] & means$isolation == row[2] & means$setup_size == 1, ]$value.mean[1])
	})
	means$ref.sd <- apply(means[, c("wl.short", "isolation") ], 1, function(row) {
		return(means[means$wl.short == row[1] & means$isolation == row[2] & means$setup_size == 1, ]$value.sd[1])
	})
	means$bare.mean <- apply(means[, c("wl.short", "isolation") ], 1, function(row) {
		return(means[means$wl.short == row[1] & means$isolation == "bare" & means$setup_size == 1, ]$value.mean[1])
	})

	dir <- "means_by_setup_size/"
	mkdir(dir)

	min.mean <- min(means$value.mean)
	max.mean <- max(means$value.mean)

	for (isolation in isolations) {
		subset <- means[means$isolation == isolation,]
		tikz(file=paste(dir, isolation, ".tex", sep=""), width=5.5, height=9)
		plot <- ggplot(subset, aes(x=setup_size, y=value.mean, group=1)) + 
			geom_line() + 
			geom_point() +
			geom_line(aes(y=1.1 * ref.mean), alpha=0.3, colour="red") +
			geom_line(aes(y=bare.mean), alpha=0.3) +
			labs(x="Number of workers", y="Mean CPU time") +
			ylim(min.mean, max.mean) +
			facet_wrap(vars(wl.short), ncol=2, labeller=labeller(wl.short=wl.labels))
		print(plot)
		dev.off()
	}
}

plot.boxes <- function() {
	values <- data.frame(values)
	values$setup_size <- factor(values$setup_size)
	dir <- "means_by_setup_size/"
	mkdir(dir)

	for (metric in metrics) {
		for (isolation in isolations) {
			subset <- values[values$isolation == isolation & values$metric == metric,]
			if (nrow(subset) == 0) {
				next
			}
			tikz(file=paste(dir, metric, "-", isolation, ".tex", sep=""), width=5.5, height=9)
			plot <- ggplot(subset, aes(y=value, x=setup_size)) + 
				geom_boxplot() +
				labs(x="Number of workers", y="CPU time") +
				facet_wrap(vars(wl.short), ncol=2, labeller=labeller(wl.short=wl.labels))
			print(plot)
			dev.off()
		}
	}
}

plot.bsearch <- function() {
	values <- data.frame(values)
	values$setup_size <- factor(values$setup_size)
	dir <- "means_by_setup_size/"
	mkdir(dir)

	subset <- values[values$metric == "cpu" & values$wl.short == "bsearch",]
	tikz(file=paste(dir, "bsearch-over-isolations.tex", sep=""), width=5.5, height=9)
	plot <- ggplot(subset, aes(y=value, x=setup_size)) + 
		geom_boxplot() +
		labs(x="Number of workers", y="CPU time") +
		facet_wrap(vars(isolation), ncol=2, labeller=labeller(wl.short=wl.labels))
	print(plot)
	dev.off()
}

#plot.boxes()
plot.bsearch()
