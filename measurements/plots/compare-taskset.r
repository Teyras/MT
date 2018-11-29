#!/usr/bin/Rscript
library("ggplot2")
library("ggpubr")
library("ggrepel")
library("knitr")
library("boot")
library("tidyr")

source("helpers.r")

values <- load.stability.results(filename.from.args())
values$setup_type_raw <- gsub("-taskset$", "", values$setup_type)
values$setup_label <- paste(values$setup_type_raw, values$setup_size, sep=",")

setup_types <- unique(values[values$taskset == TRUE, ]$setup_type_raw)
setup_labels <- unique(values[values$taskset == TRUE, ]$setup_label)
isolations <- unique(values[values$taskset == TRUE, ]$isolation)
workloads <- unique(values[values$taskset == TRUE, c("workload", "input_size")])
metrics <- unique(values[values$taskset == TRUE, ]$metric)

values <- values[values$setup_label %in% setup_labels & values$isolation %in% isolations, ]

make_na_plot <- function(title, metric, limit) {
	return(ggplot(data.frame()) + 
		labs(title=title, y=paste(metric, " [s]", sep=""), x="") +
		theme(text=element_text(size=6)) +
		annotate("text", label="N/A", size=25, x=limit/2, y=.5) + 
		geom_point() + 
		xlim(0, limit) + 
		ylim(0, 1));
}

make.plot <- function(setup_type, workload, input_size, metric, small) {
	subset <- values[
		values$workload == workload & 
		values$input_size == input_size &
		values$metric == metric &
		values$setup_type_raw == setup_type
	, ]

	if (nrow(subset) == 0) {
		return(make_na_plot("adf", "adsf", 3))
	}

	if (small) {
		subset <- subset[subset$setup_size < 10, ]
	} else {
		subset <- subset[subset$setup_size >= 10, ]
	}

	setup_cats <- unique(subset[subset$setup_label %in% setup_labels, c("setup_size", "setup_label")])
	setup_cats <- setup_cats[order(setup_cats$setup_size, setup_cats$setup_label),]$setup_label
	subset$setup_cat <- factor(subset$setup_label, level=setup_cats)

	plot <- ggplot(subset, aes(setup_cat, value)) +
		labs(title=workload, y=metric, x="setup") +
		theme(text=element_text(size=6)) +
		geom_violin(aes(fill=taskset)) +
		facet_grid(rows=vars(subset$isolation))

	return(plot)
}

# Make plots
mkdir("taskset")

for (setup_type in setup_types) {
	next
	mkdir(paste("taskset/", setup_type, sep=""))

	for (metric in metrics) {
		plots <- list()

		for (row_workloads in 1:nrow(workloads)) {
			workload <- workloads[row_workloads, ]
			plots[[length(plots) + 1]] <- make.plot(setup_type, workload$workload, workload$input_size, metric, TRUE)
			plots[[length(plots) + 1]] <- make.plot(setup_type, workload$workload, workload$input_size, metric, FALSE)
		}

		ggarrange(plotlist=plots, ncol=2, nrow=length(plots) / 2)
		ggsave(paste("taskset/", setup_type, "/", metric, ".png", sep=""), width=10, height=20, units="in")
	}
}

# Make table
my.mean <- function (x, d) mean(x[d])
my.sd <- function (x, d) sd(x[d])

compare.boot <- function (fnc, row) {
	data1 <- values[
			values$workload == row["workload"] & 
			values$input_size == row["input_size"] & 
			values$setup_type_raw == row["setup_type_raw"] & 
			values$isolation == row["isolation"] &
			values$metric == row["metric"] &
			values$taskset == TRUE
		, ]$value

	data2 <- values[
			values$workload == row["workload"] & 
			values$input_size == row["input_size"] & 
			values$setup_type_raw == row["setup_type_raw"] & 
			values$isolation == row["isolation"] &
			values$metric == row["metric"] &
			values$taskset == FALSE
		, ]$value

	if (length(data1) == 0 | length(data2) == 0) {
		return(NA)
	}

	boot1 <- boot(data1, fnc, R=1000)
	boot2 <- boot(data2, fnc, R=1000)

	return(ci.compare(boot1, boot2))
}

comparisons <- unique(values[
		      values$setup_type_raw %in% setup_types & values$metric %in% c("cpu", "wall"), 
		      c("setup_type_raw", "workload", "input_size", "isolation", "metric")
	      ])
comparisons$mean.comparison <- apply(comparisons, 1, function (row) compare.boot(my.mean, row))
comparisons$sd.comparison <- apply(comparisons, 1, function (row) compare.boot(my.sd, row))

kable(comparisons, row.names=F)

plot.data <- gather(comparisons, key, value, mean.comparison, sd.comparison)
ggplot(plot.data, aes(x="", fill=value)) + 
	geom_bar(width=1, stat="count") +
	facet_grid(cols=vars(plot.data$key))

ggsave("taskset/taskset-comparison.png")

