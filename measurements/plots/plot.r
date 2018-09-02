#!/usr/bin/Rscript
library("ggplot2")
library("ggpubr")
library("ggrepel")

source("helpers.r")

# Read the data
values <- load.stability.results(filename.from.args())

plot_hist <- function(subset, subset_single, title, metric, limit) {
	plot <- ggplot(subset_single, aes(subset_single$value)) +
		labs(title=title, y=metric, x="") +
		theme(text=element_text(size=6)) +
		geom_histogram(breaks=seq(0, limit, by=limit/30)) +
		facet_grid(cols=vars(subset_single$setup_cat))

	return(plot)
}

plot_boxplot <- function(subset, subset_single, title, metric, limit) {
	plot <- ggplot(subset_single, aes(x="", y=value)) +
		labs(title=title, y=metric, x="") +
		theme(text=element_text(size=6)) +
		geom_boxplot(lwd=0.15, outlier.size=0.15) +
		ylim(0, limit) +
		facet_grid(cols=vars(subset_single$setup_cat))

	return(plot)
}

plot_points <- function(subset, subset_single, title, metric, limit) {
	plot <- ggplot(subset_single, aes(x=iteration, y=value)) +
		labs(title=title, y=metric, x="iteration") +
		geom_point(size=0.15) +
		ylim(0, limit) +
		facet_grid(cols=vars(subset_single$setup_cat))

	return(plot)
}

plot_mad_over_setup <- function(subset, subset_single, title, metric, limit) {
	data <- aggregate(value ~ setup_cat, subset, mad)
	data_single <- aggregate(value ~ setup_cat, subset_single, mad)
	plot <- ggplot(data, aes(x=setup_cat, y=value, group=1)) +
		labs(title=title, y=paste("mad(", metric, ")", sep=""), x="") +
		theme(text=element_text(size=6)) +
		geom_path() + 
		geom_point() +
		geom_text_repel(aes(label=sprintf("%0.3f", value)), size=2) +
		geom_path(data=data_single, color="blue") + 
		geom_point(data=data_single) +
		geom_text_repel(data=data_single, aes(label=sprintf("%0.3f", value)), size=2) +
		geom_hline(yintercept=0.05, color="red", linetype="dashed")

	return(plot)
}

# Plots a subset of the data (see the arguments)
make_plot <- function (plot.function, metric, workload, isolation, limit, taskset=FALSE) {
	subset <- values[values$metric == metric & values$workload == workload & values$isolation == isolation & values$taskset == taskset,]

	title <- isolation
	if (taskset) {
		title <- paste(title, "taskset", sep="+")
	}

	if (length(subset$value) == 0) {
		plot <- ggplot(data.frame()) + 
			labs(title=title, y=metric, x="") +
			theme(text=element_text(size=6)) +
			annotate("text", label="N/A", size=25, x=limit/2, y=.5) + 
			geom_point() + 
			xlim(0, limit) + 
			ylim(0, 1)
		return(plot)
	}

	setups <- unique(subset[,c("setup_type", "setup_size", "setup")])
	setups <- setups[order(setups$setup_size, setups$setup_type),]$setup
	subset$setup_cat <- factor(subset$setup, levels=setups)
	subset_single <- subset[subset$worker == subset$worker[1],]

	return(plot.function(subset, subset_single, title, metric, limit))
}

# Plots a metric for a workload into a file
plot_workload_by_setup <- function (dir, plot.function, metric, workload, limit) {
	#png(filename=gsub("/", "-", paste(metric, "-", workload, ".png", sep="")), width=1920, height=1200)
	subset <- values[values$workload == workload & values$metric == metric,]
	limit <- max(subset$value)

	plot <- ggarrange(
		  make_plot(plot.function, metric, workload, "bare", limit), 
		  make_plot(plot.function, metric, workload, "bare", limit, TRUE),

		  make_plot(plot.function, metric, workload, "isolate", limit), 
		  make_plot(plot.function, metric, workload, "isolate", limit, TRUE),

		  make_plot(plot.function, metric, workload, "docker-bare", limit), 
		  make_plot(plot.function, metric, workload, "docker-bare", limit, TRUE),

		  make_plot(plot.function, metric, workload, "docker-isolate", limit), 
		  make_plot(plot.function, metric, workload, "docker-isolate", limit, TRUE),

		  make_plot(plot.function, metric, workload, "vbox-bare", limit), 
		  make_plot(plot.function, metric, workload, "vbox-bare", limit, TRUE),

		  make_plot(plot.function, metric, workload, "vbox-isolate", limit), 
		  make_plot(plot.function, metric, workload, "vbox-isolate", limit, TRUE),
		  ncol=2, nrow=6)
	annotate_figure(plot, top=paste(workload, metric, sep=", "))
	plot

	file.name <- paste(workload, "-", metric, ".png", sep="")
	save.path <- paste(dir, gsub("/", "-", file.name), sep="/")

	mkdir(dir)
	ggsave(save.path, width=10, height=10, units="in")

	#dev.off()
}

plot_all_metrics_for_workload_by_setup <- function (workload) {
	for (func.name in c("plot_hist", "plot_boxplot", "plot_mad_over_setup", "plot_points")) {
		func <- get(func.name)
		plot_workload_by_setup(func.name, func, "cpu", workload)
		plot_workload_by_setup(func.name, func, "iso-cpu", workload)
		plot_workload_by_setup(func.name, func, "wall", workload)
		plot_workload_by_setup(func.name, func, "iso-wall", workload)
	}
}

# Plot everything!
plot_all_metrics_for_workload_by_setup("bsearch/bsearch")
plot_all_metrics_for_workload_by_setup("sort/qsort")
plot_all_metrics_for_workload_by_setup("sort/insertion_sort")

plot_all_metrics_for_workload_by_setup("exp/exp_float")
plot_all_metrics_for_workload_by_setup("exp/exp_double")
plot_all_metrics_for_workload_by_setup("gray/gray2bin")

