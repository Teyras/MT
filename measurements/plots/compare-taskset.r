#!/usr/bin/Rscript
library("ggplot2")
library("ggpubr")
library("ggrepel")

source("helpers.r")

values <- load.stability.results(filename.from.args())
values$setup_label <- paste(gsub("-taskset$", "", values$setup_type), values$setup_size, sep=",")

setup_types <- unique(values[values$taskset == TRUE, ]$setup_label)
isolations <- unique(values[values$taskset == TRUE, ]$isolation)
workloads <- unique(values[values$taskset == TRUE, c("workload", "input_size")])
metrics <- unique(values[values$taskset == TRUE, ]$metric)

values <- values[values$setup_label %in% setup_types & values$isolation %in% isolations, ]

make.plot <- function(workload, input_size, metric, small) {
	subset <- values[
		values$workload == workload & 
		values$input_size == input_size &
		values$metric == metric 
	, ]

	if (small) {
		subset <- subset[subset$setup_size < 10, ]
	} else {
		subset <- subset[subset$setup_size >= 10, ]
	}

	setup_cats <- unique(subset[subset$setup_label %in% setup_types, c("setup_size", "setup_label")])
	setup_cats <- setup_cats[order(setup_cats$setup_size, setup_cats$setup_label),]$setup_label
	subset$setup_cat <- factor(subset$setup_label, level=setup_cats)

	plot <- ggplot(subset, aes(setup_cat, value)) +
		labs(title=workload, y=metric, x="setup") +
		theme(text=element_text(size=6)) +
		geom_violin(aes(fill=taskset)) +
		facet_grid(rows=vars(subset$isolation))

	return(plot)
}

mkdir("taskset")

for (metric in metrics) {
	plots <- list()

	for (row_workloads in 1:nrow(workloads)) {
		workload <- workloads[row_workloads, ]
		plots[[length(plots) + 1]] <- make.plot(workload$workload, workload$input_size, metric, TRUE)
		plots[[length(plots) + 1]] <- make.plot(workload$workload, workload$input_size, metric, FALSE)
	}

	ggarrange(plotlist=plots, ncol=2, nrow=length(plots) / 2)
	ggsave(paste("taskset/", metric, ".png", sep=""), width=10, height=20, units="in")
}
