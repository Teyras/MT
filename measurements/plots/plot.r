#!/usr/bin/Rscript
library("ggplot2")
library("ggpubr")
library("ggrepel")

source("helpers.r")

theme_set(theme_grey(base_size=8))

# Read the data
values <- load.stability.results(filename.from.args())
workloads <- unique(values$workload)
isolations <- unique(values$isolation)
setups <- unique(values$setup)

plot_hist <- function(subset, subset_single, title, metric, limit, limit_min=0, rainbow=FALSE) {
	plot <- ggplot(subset_single, aes(subset_single$value)) +
		labs(title=title, y=paste(metric, " [s]", sep=""), x="") +
		theme(text=element_text(size=6)) +
		geom_histogram(breaks=seq(0, limit, by=limit/30)) +
		facet_grid(cols=vars(subset_single$category))

	return(plot)
}

plot_boxplot <- function(subset, subset_single, title, metric, limit, limit_min=0, rainbow=FALSE) {
	plot <- ggplot(subset_single, aes(x="", y=value)) +
		labs(title=title, y=paste(metric, " [s]", sep=""), x="") +
		theme(text=element_text(size=6)) +
		geom_boxplot(lwd=0.15, outlier.size=0.15) +
		ylim(limit_min, limit) +
		facet_grid(cols=vars(subset_single$category))

	return(plot)
}

plot_points <- function(subset, subset_single, title, metric, limit, limit_min=0, rainbow=FALSE) {
	iters <- max(subset$iteration)

	plot <- ggplot(subset, aes(x=iteration, y=value)) +
		labs(title=title, y=paste(metric, " [s]", sep=""), x="iteration") +
		scale_x_continuous(breaks=c(0, iters/2, iters)) +
		ylim(limit_min, limit) +
		facet_grid(cols=vars(category))

	if (rainbow) {
		plot <- plot + 
			geom_point(shape=19, aes(color=subset$worker), size=0.1) +
			theme(legend.position="none")
	} else {
		plot <- plot +
			geom_point(shape=19, color="grey", size=0.1) +
			geom_point(data=subset_single, shape=20, color="red", size=0.1)
	}

	return(plot)
}

plot_mad_over_setup <- function(subset, subset_single, title, metric, limit, limit_min=0, rainbow=FALSE) {
	data <- aggregate(value ~ category, subset, mad)
	data_single <- aggregate(value ~ category, subset_single, mad)
	plot <- ggplot(data, aes(x=category, y=value, group=1)) +
		labs(title=title, y=paste("mad(", metric, ") [s]", sep=""), x="") +
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

make_na_plot <- function(title, metric, limit) {
	return(ggplot(data.frame()) + 
		labs(title=title, y=paste(metric, " [s]", sep=""), x="") +
		theme(text=element_text(size=6)) +
		annotate("text", label="N/A", size=25, x=limit/2, y=.5) + 
		geom_point() + 
		xlim(0, limit) + 
		ylim(0, 1));
}

# Plots a subset of the data (see the arguments)
make_plot_by_setup <- function (plot.function, metric, workload, isolation, limit, taskset=FALSE) {
	subset <- values[values$metric == metric & values$workload == workload & values$isolation == isolation & values$taskset == taskset,]

	title <- isolation
	if (taskset) {
		title <- paste(title, "taskset", sep="+")
	}

	if (length(subset$value) == 0) {
		return(make_na_plot(title, metric, limit))
	}

	setups <- unique(subset[,c("setup_type", "setup_size", "setup")])
	setups <- setups[order(setups$setup_size, setups$setup_type),]$setup
	subset$category <- factor(subset$setup, levels=setups)
	subset_single <- subset[subset$worker == subset$worker[1],]

	return(plot.function(subset, subset_single, title, metric, limit))
}

make_plot_by_isolation <- function (plot.function, metric, workload, setup, title=NULL, rainbow=FALSE) {
	subset <- values[values$metric == metric & values$workload == workload & values$setup == setup, ]

	if (is.null(title)) {
		title <- workload
	}

	limit_max <- max(subset$value) + 0.1
	limit_min <- max(min(subset$value) - 0.1, 0)

	if (length(subset$value) == 0) {
		return(make_na_plot(title, metric, limit_max))
	}

	subset$category <- factor(subset$isolation, levels=unique(subset$isolation))
	subset_single <- subset[subset$worker == subset$worker[1],]

	return(plot.function(subset, subset_single, title, metric, limit_max, limit_min, rainbow))
}

# Plots a metric for a workload into a file
plot_workload_by_setup <- function (dir, plot.function, metric, workload) {
	subset <- values[values$workload == workload & values$metric == metric,]
	limit <- max(subset$value)
	plots <- list()

	for (isolation in isolations) {
		plots[[length(plots) + 1]] <- make_plot_by_setup(plot.function, metric, workload, isolation, limit)
		plots[[length(plots) + 1]] <- make_plot_by_setup(plot.function, metric, workload, isolation, limit, TRUE)
	}

	plot <- ggarrange(plotlist=plots, ncol=2, nrow=length(plots) / 2)
	annotate_figure(plot, top=paste(workload, metric, sep=", "))
	plot

	file.name <- paste(workload, "-", metric, ".png", sep="")
	save.path <- paste(dir, gsub("/", "-", file.name), sep="/")

	mkdir(dir)
	ggsave(save.path, width=10, height=10, units="in")
}

plot_all_workloads_by_isolation <- function(dir, plot.function, metric, setup) {
	subset <- values[values$setup == setup & values$metric == metric,]
	limit <- max(subset$value)
	plots <- list()

	for (workload in workloads) {
		plots[[length(plots) + 1]] <- make_plot_by_isolation(plot.function, metric, workload, setup)
	}

	plot <- ggarrange(plotlist=plots, ncol=2, nrow=length(plots) / 2)
	annotate_figure(plot, top=paste(setup, metric, sep=", "))
	plot

	file.name <- paste(setup, "-", metric, ".png", sep="")
	save.path <- paste(dir, gsub("/", "-", file.name), sep="/")

	mkdir(dir)
	ggsave(save.path, width=10, height=10, units="in")
}

plot.functions <- c("plot_hist", "plot_boxplot", "plot_mad_over_setup", "plot_points")

# Plot everything!
for (workload in workloads) {
	for (func.name in plot.functions) {
		func <- get(func.name)
		plot_workload_by_setup(func.name, func, "cpu", workload)
		#plot_workload_by_setup(func.name, func, "iso-cpu", workload)
		plot_workload_by_setup(func.name, func, "wall", workload)
		#plot_workload_by_setup(func.name, func, "iso-wall", workload)
	}
}

for (setup in setups) {
	for (func.name in plot.functions) {
		func <- get(func.name)
		plot_all_workloads_by_isolation(paste("alt_", func.name, sep=""), func, "cpu", setup)
		plot_all_workloads_by_isolation(paste("alt_", func.name, sep=""), func, "wall", setup)
	}
}

ggarrange(
	  make_plot_by_isolation(plot_points, "cpu", "exp/exp_float", "single,1", "exp_float, 1 worker"),
	  make_plot_by_isolation(plot_points, "cpu", "bsearch/bsearch", "single,1", "bsearch, 1 worker"),

	  make_plot_by_isolation(plot_points, "cpu", "exp/exp_float", "parallel-homogenous,2", "exp_float, 2 workers"),
	  make_plot_by_isolation(plot_points, "cpu", "bsearch/bsearch", "parallel-homogenous,2", "bsearch, 2 workers"),

	  make_plot_by_isolation(plot_points, "cpu", "exp/exp_float", "parallel-homogenous,4", "exp_float, 4 workers"),
	  make_plot_by_isolation(plot_points, "cpu", "bsearch/bsearch", "parallel-homogenous,4", "bsearch, 4 workers"),

	  make_plot_by_isolation(plot_points, "cpu", "exp/exp_float", "parallel-homogenous,10", "exp_float, 10 workers"),
	  make_plot_by_isolation(plot_points, "cpu", "bsearch/bsearch", "parallel-homogenous,10", "bsearch, 10 workers"),
	  nrow=4, ncol=2
)

ggsave("isolation-comparison.png", width=8, height=11, units="in")

ggarrange(
	  make_plot_by_isolation(plot_points, "cpu", "exp/exp_float", "single,1", "exp_float, 1 worker", rainbow=TRUE),
	  make_plot_by_isolation(plot_points, "cpu", "bsearch/bsearch", "single,1", "bsearch, 1 worker", rainbow=TRUE),

	  make_plot_by_isolation(plot_points, "cpu", "exp/exp_float", "parallel-homogenous-taskset,2", "exp_float, 2 workers", rainbow=TRUE),
	  make_plot_by_isolation(plot_points, "cpu", "bsearch/bsearch", "parallel-homogenous-taskset,2", "bsearch, 2 workers", rainbow=TRUE),

	  make_plot_by_isolation(plot_points, "cpu", "exp/exp_float", "parallel-homogenous-taskset,4", "exp_float, 4 workers", rainbow=TRUE),
	  make_plot_by_isolation(plot_points, "cpu", "bsearch/bsearch", "parallel-homogenous-taskset,4", "bsearch, 4 workers", rainbow=TRUE),

	  make_plot_by_isolation(plot_points, "cpu", "exp/exp_float", "parallel-homogenous-taskset,10", "exp_float, 10 workers", rainbow=TRUE),
	  make_plot_by_isolation(plot_points, "cpu", "bsearch/bsearch", "parallel-homogenous-taskset,10", "bsearch, 10 workers", rainbow=TRUE),
	  nrow=4, ncol=2
)

ggsave("isolation-comparison-taskset.png", width=8, height=11, units="in")
