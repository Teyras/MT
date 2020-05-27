#!/usr/bin/Rscript
library("ggplot2")
library("ggpubr")
library("ggrepel")
library("boot")
library("tidyr")
library("tikzDevice")

source("helpers.r")

data <- load.stability.results(filename.from.args())
data$setup_type_raw <- data$setup_type %>% 
	{gsub("-taskset$", "", .)} %>%
	{gsub("-taskset-multi$", "", .)} %>%
	{gsub("-numa$", "", .)} %>%
	{gsub("-taskset-noht$", "", .)} %>%
	{gsub("-taskset-multi-noht$", "", .)} %>%
	{gsub("-numa-noht$", "", .)} %>%
	{gsub("-noht$", "", .)}
data$setup_label <- paste(data$setup_type_raw, data$setup_size, sep=",")

setup_types <- unique(data[data$taskset == TRUE, ]$setup_type_raw)
setup_labels <- unique(data[data$taskset == TRUE, ]$setup_label)
isolations <- unique(data[data$taskset == TRUE, ]$isolation)
workloads <- unique(data[data$taskset == TRUE, c("workload", "input_size")])
metrics <- unique(data[data$taskset == TRUE, ]$metric)

values <- data[data$setup_label %in% setup_labels & data$isolation %in% isolations, ]

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

taskset.plots <- function() {
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
}

# Make table
my.mean <- function (x, d) mean(x[d])
my.sd <- function (x, d) sd(x[d])

compare.boot <- function (fnc, row, multi, data) {
	reference <- values[
			values$workload == row["workload"] & 
			values$input_size == row["input_size"] & 
			values$setup_type_raw == row["setup_type_raw"] & 
			values$isolation == row["isolation"] &
			values$metric == row["metric"] &
			values$taskset == multi &
			values$multi == multi &
			values$numa == F &
			values$noht == F
		, ]$value

	return(compare.fnc.boot(fnc, data, reference))
}

extract.taskset <- function (row) {
	return(values[
		values$workload == row["workload"] & 
		values$input_size == row["input_size"] & 
		values$setup_type_raw == row["setup_type_raw"] & 
		values$isolation == row["isolation"] &
		values$metric == row["metric"] &
		values$taskset == T &
		values$multi == F &
		values$noht == F
	, ]$value)
}

extract.taskset.multi <- function (row) {
	return(values[
		values$workload == row["workload"] & 
		values$input_size == row["input_size"] & 
		values$setup_type_raw == row["setup_type_raw"] & 
		values$isolation == row["isolation"] &
		values$metric == row["metric"] &
		values$taskset == T &
		values$multi == T &
		values$noht == F
	, ]$value)
}

extract.numa <- function (row) {
	return(values[
		values$workload == row["workload"] & 
		values$input_size == row["input_size"] & 
		values$setup_type_raw == row["setup_type_raw"] & 
		values$isolation == row["isolation"] &
		values$metric == row["metric"] &
		values$numa == T &
		values$noht == F
	, ]$value)
}

extract.noht <- function (row) {
	return(values[
		values$workload == row["workload"] & 
		values$input_size == row["input_size"] & 
		values$setup_type_raw == row["setup_type_raw"] & 
		values$isolation == row["isolation"] &
		values$metric == row["metric"] &
		values$numa == F &
		values$taskset == F &
		values$multi == F &
		values$noht == T
	, ]$value)
}

extract.noht.multi <- function (row) {
	return(values[
		values$workload == row["workload"] & 
		values$input_size == row["input_size"] & 
		values$setup_type_raw == row["setup_type_raw"] & 
		values$isolation == row["isolation"] &
		values$metric == row["metric"] &
		values$numa == F &
		values$multi == T &
		values$noht == T
	, ]$value)
}

make.comparison.plot <- function() {
	comparisons <- unique(values[
			      values$setup_type_raw %in% setup_types & values$metric == "cpu", 
			      c("setup_type_raw", "workload", "input_size", "isolation", "metric")
		      ])
	comparisons$mean.taskset <- apply(comparisons, 1, function (row) compare.boot(my.mean, row, F, extract.taskset(row)))
	comparisons$sd.taskset <- apply(comparisons, 1, function (row) compare.boot(my.sd, row, F, extract.taskset(row)))
	comparisons$mean.taskset.multi <- apply(comparisons, 1, function (row) compare.boot(my.mean, row, F, extract.taskset.multi(row)))
	comparisons$sd.taskset.multi <- apply(comparisons, 1, function (row) compare.boot(my.sd, row, F, extract.taskset.multi(row)))
	comparisons$mean.numa <- apply(comparisons, 1, function (row) compare.boot(my.mean, row, F, extract.numa(row)))
	comparisons$sd.numa <- apply(comparisons, 1, function (row) compare.boot(my.sd, row, F, extract.numa(row)))
	comparisons$mean.noht <- apply(comparisons, 1, function (row) compare.boot(my.mean, row, F, extract.noht(row)))
	comparisons$sd.noht <- apply(comparisons, 1, function (row) compare.boot(my.sd, row, F, extract.noht(row)))
	comparisons$mean.noht.multi <- apply(comparisons, 1, function (row) compare.boot(my.mean, row, T, extract.noht.multi(row)))
	comparisons$sd.noht.multi <- apply(comparisons, 1, function (row) compare.boot(my.sd, row, T, extract.noht.multi(row)))

	labels.metric <- c(
		"mean.taskset" = "Mean",
		"sd.taskset" = "Std. dev.",
		"mean.taskset.multi" = "Mean",
		"sd.taskset.multi" = "Std. dev.",
		"mean.numa" = "Mean",
		"sd.numa" = "Std. dev.",
		"mean.noht" = "Mean",
		"sd.noht" = "Std. dev.",
		"mean.noht.multi" = "Mean",
		"sd.noht.multi" = "Std. dev."
	)

	tikz("taskset/taskset-comparison.tex", width=5.5, height=4)

	plot.data <- gather(comparisons, key, value, mean.taskset, sd.taskset, mean.taskset.multi, sd.taskset.multi, mean.numa, sd.numa)
	plot.data <- drop_na(plot.data, value)
	plot.data$value[which(plot.data$value == "overlap")] <- "same"
	plot.data$label <- ifelse(grepl("taskset$", plot.data$key), "taskset", ifelse(grepl("numa$", plot.data$key), "numactl", "Multicore taskset"))

	plot <- ggplot(plot.data, aes(x=key, fill=value)) +
		geom_bar(stat="count") +
		coord_flip() +
		labs(x="", y="") +
		scale_x_discrete(labels=labels.metric) +
		scale_fill_discrete(name="Comparison\nresult", labels=c(
					"Higher",
					"Lesser",
					"Equal"
				       )) +
		facet_wrap(. ~ label, ncol=1, scales="free")
	print(plot)
	dev.off()

	tikz("taskset/taskset-comparison-noht.tex", width=5.5, height=3)

	plot.data <- gather(comparisons, key, value, mean.noht, sd.noht, mean.noht.multi, sd.noht.multi)
	#plot.data <- drop_na(plot.data, value)
	plot.data$value[which(plot.data$value == "overlap")] <- "same"
	plot.data$label <- ifelse(grepl("multi", plot.data$key), "Multicore taskset", "No affinity settings")

	plot <- ggplot(plot.data, aes(x=key, fill=value)) +
		geom_bar(stat="count") +
		coord_flip() +
		labs(x="", y="") +
		scale_x_discrete(labels=labels.metric) +
		scale_fill_discrete(name="Comparison\nresult", labels=c(
					"Higher",
					"Lesser",
					"Equal"
				       )) +
		facet_wrap(. ~ label, ncol=1, scales="free")
	print(plot)
	dev.off()
}

wl.labels <- function(labels) lapply(labels, function(wl) {
	if (wl == "exp_float") {
	     return("exp\\_float")
	}

	return(wl)
})

noht.labels <- function(labels) lapply(labels, function(noht) {
       if (noht == F) {
	       return("Logical Cores")
       } else {
	       return("No Logical Cores")
       }
})

make.default.vs.multi.plot <- function(isolation) {
	tikz(paste("taskset/taskset-default-vs-taskset-multi-", isolation, ".tex", sep=""), width=5.5, height=8)

	subset <- data[
			 data$setup_type_raw %in% c("single", "parallel-homogenous") & 
			 data$setup_size %in% c(1, 2, 4, 8, 10, 20) &
			 data$wl.short %in% c("exp_float", "bsearch") &
			 data$isolation == isolation &
		 	 data$metric == "cpu" &
			 grepl("cpu-0", data$worker) &
			 (data$taskset == F | data$multi == T) & 
			 data$numa == F, 
		 ]

	plot <- ggplot(subset, aes(x=iteration, y=value)) +
		geom_point(aes(color=multi), shape=19, size=0.1) +
		scale_color_manual(name="", values=c("#444444", "#ff0000"), labels=c("No affinity settings", "Multi-core taskset")) +
		labs(x="Iteration", y="CPU time") +
		facet_grid(setup_size ~ wl.short + noht, labeller=labeller(wl.short=wl.labels, noht=noht.labels)) +
		theme(legend.position="bottom", legend.direction="vertical")
	print(plot)
	dev.off()
}

if (sys.nframe() == 0) {
	make.comparison.plot()
	make.default.vs.multi.plot("bare")
	make.default.vs.multi.plot("isolate")
	#make.default.vs.multi.plot("docker-bare")
	#make.default.vs.multi.plot("docker-isolate")
}

