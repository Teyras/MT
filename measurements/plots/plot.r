#!/usr/bin/Rscript
library("ggplot2")
library("ggpubr")

# Read the data
values <- load.stability.results(filename.from.args())

# Plots a subset of the data (see the arguments)
make_plot <- function (metric, workload, isolation, limit, taskset=FALSE) {
	subset <- values[values$metric == metric & values$workload == workload & values$isolation == isolation & values$taskset == taskset,]

	if (length(subset$value) == 0) {
		plot <- ggplot(data.frame()) + 
			labs(title=isolation, y=metric, x="") +
			theme(text=element_text(size=6)) +
			annotate("text", label="N/A", size=25, x=.5, y=.5) + 
			geom_point() + 
			xlim(0, limit) + 
			ylim(0, 1)
		return(plot)
	}

	title <- isolation
	if (taskset) {
		title <- paste(title, "taskset", sep="+")
	}

	plot <- ggplot(subset, aes(x="", y=value)) +
		labs(title=title, y=metric, x="") +
		theme(text=element_text(size=6)) +
		geom_boxplot(lwd=0.15, outlier.size=0.15) +
		ylim(0, limit) +
		facet_grid(. ~ setup)

	return(plot)
}

# Plots a metric for a workload into a file
plot_workload_by_setup <- function (metric, workload, limit) {
	#png(filename=gsub("/", "-", paste(metric, "-", workload, ".png", sep="")), width=1920, height=1200)
	subset <- values[values$workload == workload & values$metric == metric,]
	limit <- max(subset$value)

	plot <- ggarrange(
		  make_plot(metric, workload, "bare", limit), make_plot(metric, workload, "bare", limit, TRUE),
		  make_plot(metric, workload, "isolate", limit), make_plot(metric, workload, "isolate", limit, TRUE),
		  make_plot(metric, workload, "docker-bare", limit), make_plot(metric, workload, "docker-bare", limit, TRUE),
		  make_plot(metric, workload, "docker-isolate", limit), make_plot(metric, workload, "docker-isolate", limit, TRUE),
		  ncol=2, nrow=4)
	annotate_figure(plot, top=paste(workload, metric, sep=", "))
	plot
	ggsave(gsub("/", "-", paste(workload, "-", metric, ".png", sep="")))

	#dev.off()
}

plot_all_metrics_for_workload_by_setup <- function (workload, limit) {
	plot_workload_by_setup("cpu", workload, limit)
	plot_workload_by_setup("iso-cpu", workload, limit)
	plot_workload_by_setup("wall", workload, limit)
	plot_workload_by_setup("iso-wall", workload, limit)
}

# Plot everything!
plot_all_metrics_for_workload_by_setup("bsearch/bsearch", 0.005)
plot_all_metrics_for_workload_by_setup("sort/qsort", 0.08)
plot_all_metrics_for_workload_by_setup("sort/insertion_sort", 1)

plot_all_metrics_for_workload_by_setup("exp/exp_float", 0.1)
plot_all_metrics_for_workload_by_setup("exp/exp_double", 0.1)
plot_all_metrics_for_workload_by_setup("gray/gray2bin", 0.3)

