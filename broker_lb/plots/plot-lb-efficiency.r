library("tikzDevice")
library("ggplot2")
library("tidyr")
library("dplyr")

source("../../measurements/plots/helpers.r")

values <- load.lb.results(filename.from.args())
values$wait.time <- values$processing.start - values$arrival
values$relative.wait.time <- values$wait.time / values$processing.time
values$queue.manager <- tex.safe(values$queue.manager)
values$workload <- tex.safe(values$workload)
values$setup <- tex.safe(values$setup)
values$processing.end <- values$processing.start + values$processing.time
values$lateness.class <- cut(values$relative.wait.time, breaks=c(0, 0.1, 1, 3, Inf), labels=c("on.time", "delayed", "late", "extremely.late"), right=F)

plot.efficiency <- function() {
	mkdir("lb-efficiency")
	narrow.values <- gather(values, key="metric", value="value", wait.time, relative.wait.time)

	for (setup in unique(narrow.values$setup)) {
		file <- paste("lb-efficiency/", tex.unsafe(setup), sep="")
		tikz(file=paste(file, ".tex", sep=""))

		plot <- ggplot(narrow.values[narrow.values$setup == setup, ], aes(x=queue.manager, y=value)) +
			geom_violin() +
			scale_y_log10() +
			facet_grid(rows=vars(metric), cols=vars(workload), scales="free") +
			theme(axis.text.x = element_text(angle = 90, hjust = 1))

		print(plot)
		ggsave(file=paste(file, ".png", sep=""), plot)
		dev.off()
	}
}

plot.makespan <- function() {
	makespans <- aggregate(values$processing.end, list(queue.manager=values$queue.manager, setup=values$setup, workload=values$workload), max)

	tikz(file="makespans.tex", width=15, height=20)
	plot <- ggplot(makespans, aes(x=queue.manager, y=x)) +
		geom_col() +
		facet_wrap(~ setup + workload, scales="free", ncol=2) +
		theme(axis.text.x = element_text(angle = 90, hjust = 1))

	print(plot)
	dev.off()

	tikz(file="makespans-selection.tex", width=5, height=6)
	plot <- ggplot(makespans[makespans$workload %in% c("long+short\\_small", "medium+short\\_small"),], aes(x=queue.manager, y=x)) +
		geom_col() +
		facet_wrap(~ setup + workload, scales="free_y", ncol=1) +
		theme(axis.text.x = element_text(angle = 90, hjust = 1))

	print(plot)
	dev.off()
}

plot.wait.time.trends <- function() {
	dir <- "wait-time-trends"
	mkdir(dir)

	res <- group_walk(group_by(values, setup, workload), function(data, group) {
		# Lateness graph
		file <- tex.unsafe(paste(dir, "/lateness,", group$setup, ",", group$workload, sep=""))
		tikz(file=paste(file, ".tex", sep=""))

		arrival.breaks <- c(seq(0, max(data$arrival), max(data$arrival) / 20), Inf)
		arrival.breaks <- quantile(data$arrival, seq(0, 1, .05))
		data$arrival.discrete = cut(data$arrival, breaks=arrival.breaks, labels=1:20, include.lowest=T)

		plot <- ggplot(data, aes(arrival.discrete)) +
			geom_bar(aes(fill=lateness.class), position=position_fill(reverse=T)) +
			scale_fill_manual(values=c("on.time"="darkgreen", "delayed"="green", "late"="pink", "extremely.late"="red")) +
			facet_wrap(vars(data$queue.manager), ncol=2)
		print(plot)
		ggsave(file=paste(file, ".png", sep=""), plot)
		dev.off()

		# Relative wait time histogram
		file <- tex.unsafe(paste(dir, "/rel_wait_time,", group$setup, ",", group$workload, sep=""))
		tikz(file=paste(file, ".tex", sep=""))

		plot <- ggplot(data, aes(relative.wait.time)) +
			geom_histogram() +
			scale_y_log10() +
			facet_wrap(vars(data$queue.manager), ncol=2)
		print(plot)
		ggsave(file=paste(file, ".png", sep=""), plot)
		dev.off()
	})
}


#plot.efficiency()
plot.makespan()
#plot.wait.time.trends()
