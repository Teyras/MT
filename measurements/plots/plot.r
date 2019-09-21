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
setup_types <- unique(values$setup_type)
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

plot_violin_by_setup_size <- function(subset, subset_single, title, metric, limit, limit_min=0, rainbow=FALSE) {
	plot <- ggplot(subset, aes(x="", y=value)) +
		labs(title=title, y=paste(metric, " [s]", sep=""), x="") +
		theme(text=element_text(size=6)) +
		geom_violin(draw_quantiles=c(0.5)) +
		ylim(limit_min, limit) +
		facet_grid(cols=vars(subset$category), rows=vars(subset$setup_size))

	return(plot)
}

plot_hist_by_setup_size <- function(subset, subset_single, title, metric, limit, limit_min=0, rainbow=FALSE) {
	plot <- ggplot(subset, aes(subset$value)) +
		labs(title=title, y=paste(metric, " [s]", sep=""), x="") +
		theme(text=element_text(size=6)) +
		geom_histogram(breaks=seq(0, limit, by=limit/30)) +
		facet_grid(cols=vars(subset$category), rows=vars(subset$setup_size))

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

plot_median_over_setup <- function(subset, subset_single, title, metric, limit, limit_min=0, rainbow=FALSE) {
	data <- aggregate(value ~ category, subset, median)
	data_single <- aggregate(value ~ category, subset_single, median)
	plot <- ggplot(data, aes(x=category, y=value, group=1)) +
		labs(title=title, y=paste("mad(", metric, ") [s]", sep=""), x="") +
		theme(text=element_text(size=6)) +
		geom_path() + 
		geom_point() +
		geom_text_repel(aes(label=sprintf("%0.3f", value)), size=2) +
		geom_path(data=data_single, color="blue") + 
		geom_point(data=data_single) +
		geom_text_repel(data=data_single, aes(label=sprintf("%0.3f", value)), size=2)

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
make_plot_by_setup <- function (plot.function, setup_type, metric, workload, isolation, limit, taskset=FALSE) {
	subset <- values[
			 values$metric == metric & 
			 values$workload == workload & 
			 values$isolation == isolation & 
			 (
			  (taskset == FALSE & values$setup_type == setup_type) | 
			  (taskset == TRUE & values$setup_type == paste(setup_type, "taskset", sep="-")) | 
			  values$setup_type == "single"
			 )
		 ,]

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

make_plot_by_isolation <- function (plot.function, metric, workload, setup, title=NULL, rainbow=FALSE, subset=NULL) {
	if (is.null(subset)) {
		subset <- values[values$metric == metric & values$workload == workload & values$setup == setup, ]
	}

	if (is.null(title)) {
		title <- workload
	}

	limit_max <- max(subset$value) + 0.1
	limit_min <- max(min(subset$value) - 0.1, 0)

	if (length(subset$value) == 0) {
		return(make_na_plot(title, metric, limit_max))
	}

	subset$category <- factor(subset$isolation.short, levels=unique(subset$isolation.short))
	subset_single <- subset[subset$worker == subset$worker[1],]

	return(plot.function(subset, subset_single, title, metric, limit_max, limit_min, rainbow))
}

# Plots a metric for a workload into a file
plot_workload_by_setup <- function (dir, plot.function, metric, workload) {
	for (setup_type in setup_types) {
		if (grepl("taskset", setup_type)) {
			next
		}

		subset <- values[
			 values$workload == workload & 
			 values$metric == metric & 
			 (values$setup_type == setup_type | values$setup_type == paste(setup_type, "taskset", sep="-") | values$setup_type == "single")
		 ,]
		limit <- max(subset$value)
		plots <- list()

		for (isolation in isolations) {
			plots[[length(plots) + 1]] <- make_plot_by_setup(plot.function, setup_type, metric, workload, isolation, limit)
			plots[[length(plots) + 1]] <- make_plot_by_setup(plot.function, setup_type, metric, workload, isolation, limit, TRUE)
		}

		plot <- ggarrange(plotlist=plots, ncol=2, nrow=length(plots) / 2)
		annotate_figure(plot, top=paste(workload, metric, sep=", "))
		plot

		file.name <- paste(setup_type, "-", workload, "-", metric, ".png", sep="")
		save.path <- paste(dir, gsub("/", "-", file.name), sep="/")

		mkdir(dir)
		ggsave(save.path, width=10, height=10, units="in")
	}
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

# Plotting functions
plot_various_stats <- function() {
	plot.functions <- c("hist", "boxplot", "mad_over_setup", "points")
	#plot.functions <- c("median_over_setup")

# Plots for gauging the effect of setup size for a particular setup type, workload and isolation technique
# TODO the other way of plotting is probably more useful
	for (workload in workloads) {
		for (func.name in plot.functions) {
			func <- get(paste("plot_", func.name, sep=""))
			plot_workload_by_setup(paste("iso_by_setup_", func.name, sep=""), func, "cpu", workload)
			#plot_workload_by_setup(func.name, func, "iso-cpu", workload)
			plot_workload_by_setup(paste("iso_by_setup_", func.name, sep=""), func, "wall", workload)
			#plot_workload_by_setup(func.name, func, "iso-wall", workload)
		}
	}

# Plots useful for gauging the effect of isolation techniques for a particular workload and setup
	for (setup in setups) {
		for (func.name in plot.functions) {
			func <- get(paste("plot_", func.name, sep=""))
			plot_all_workloads_by_isolation(paste("wl_by_iso_", func.name, sep=""), func, "cpu", setup)
			plot_all_workloads_by_isolation(paste("wl_by_iso_", func.name, sep=""), func, "wall", setup)
		}
	}
}

plot_by_setup_type_and_size <- function(metric, dir, plot.function) {
	for (setup_type in setup_types) {
		subset <- values[values$setup_type == setup_type & values$metric == metric,]
		limit <- max(subset$value)
		plots <- list()

		for (workload in workloads) {
			subset_by_workload <- subset[subset$workload == workload, ]
			plots[[length(plots) + 1]] <- make_plot_by_isolation(plot.function, metric, workload, setup_type, subset=subset_by_workload)
		}

		plot <- ggarrange(plotlist=plots, ncol=2, nrow=length(plots) / 2)
		annotate_figure(plot, top=paste(setup_type, metric, sep=", "))
		plot

		file.name <- paste(setup_type, "-", metric, ".png", sep="")
		save.path <- paste(dir, gsub("/", "-", file.name), sep="/")

		mkdir(dir)
		ggsave(save.path, width=10, height=10, units="in")
	}
}

plot_perf_metrics <- function() {
# Plots that show a comparison of various perf metrics for each isolation and setup
	perf.metrics <- c("L1-dcache-loads", "L1-dcache-misses", "LLC-stores", "LLC-store-misses", "LLC-loads", "LLC-load-misses", "page-faults")

	for (metric in perf.metrics) {
		plot_by_setup_type_and_size(metric, "plot_perf", plot_violin_by_setup_size)
	}
}

plot_times_by_setup_size <- function() {
# Plots for gauging the effect of setup size for a particular setup type, workload and isolation technique
	for (metric in c("cpu", "wall", "iso-cpu", "iso-wall")) {
		plot_by_setup_type_and_size(metric, "plot_times_by_setup", plot_hist_by_setup_size)
	}
}

plot_paralelization <- function() {
# A selection of plots that show the effect of homogenous parallelization on chosen workloads for each isolation technique
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

	ggsave("isolation-comparison.png", width=5.5, height=9, units="in")

# The same as above, but with taskset
	ggarrange(
		  make_plot_by_isolation(plot_points, "cpu", "exp/exp_float", "single,1", "exp_float, 1 worker", rainbow=TRUE),
		  make_plot_by_isolation(plot_points, "cpu", "bsearch/bsearch", "single,1", "bsearch, 1 worker", rainbow=TRUE),

		  make_plot_by_isolation(plot_points, "cpu", "exp/exp_float", "parallel-homogenous-taskset-multi,2", "exp_float, 2 workers", rainbow=TRUE),
		  make_plot_by_isolation(plot_points, "cpu", "bsearch/bsearch", "parallel-homogenous-taskset-multi,2", "bsearch, 2 workers", rainbow=TRUE),

		  make_plot_by_isolation(plot_points, "cpu", "exp/exp_float", "parallel-homogenous-taskset-multi,4", "exp_float, 4 workers", rainbow=TRUE),
		  make_plot_by_isolation(plot_points, "cpu", "bsearch/bsearch", "parallel-homogenous-taskset-multi,4", "bsearch, 4 workers", rainbow=TRUE),

		  make_plot_by_isolation(plot_points, "cpu", "exp/exp_float", "parallel-homogenous-taskset-multi,10", "exp_float, 10 workers", rainbow=TRUE),
		  make_plot_by_isolation(plot_points, "cpu", "bsearch/bsearch", "parallel-homogenous-taskset-multi,10", "bsearch, 10 workers", rainbow=TRUE),
		  nrow=4, ncol=2
	)

	ggsave("isolation-comparison-taskset.png", width=5.5, height=9, units="in")
}

if (sys.nframe() == 0) {
	# Plot everything!
	plot_various_stats()
	plot_times_by_setup_size()
	plot_paralelization()
}
