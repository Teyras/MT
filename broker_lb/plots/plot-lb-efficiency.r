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

lateness.labels <- c("On time", "Delayed", "Late", "Extremely late")
values$lateness.class <- factor(ifelse(values$processing.time > 5000,
				as.character(cut(values$relative.wait.time, breaks=c(0, .4, 3, 9, Inf), labels=lateness.labels, right=F)),
				as.character(cut(values$wait.time, breaks=c(0, 2000, 15000, 45000, Inf), labels=lateness.labels, right=F))))

values$lateness.class <- values$lateness.class %>%
	relevel(lateness.labels[1]) %>%
	relevel(lateness.labels[2]) %>%
	relevel(lateness.labels[3]) %>%
	relevel(lateness.labels[4])

plot.efficiency <- function() {
	mkdir("lb-efficiency")
	narrow.values <- gather(values, key="metric", value="value", wait.time, relative.wait.time)

	for (setup in unique(narrow.values$setup)) {
		file <- paste("lb-efficiency/", tex.unsafe(setup), sep="")
		tikz(file=paste(file, ".tex", sep=""), width=5.5, height=7)

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
	makespans <- aggregate(values$processing.end / 1000, list(queue.manager=values$queue.manager, setup=values$setup, workload=values$workload), max)

	tikz(file="makespans.tex", width=15, height=20)
	plot <- ggplot(makespans, aes(x=queue.manager, y=x)) +
		geom_col() +
		facet_wrap(~ setup + workload, scales="free", ncol=3) +
		theme(axis.text.x = element_text(angle = 90, hjust = 1))

	print(plot)
	dev.off()

	tikz(file="makespans-selection.tex", width=5.5, height=3.5)
	plot <- ggplot(makespans[makespans$workload %in% c("long+short", tex.safe("two_phase_large")),], aes(x=x, y=queue.manager)) +
		geom_col(orientation="y") +
		facet_wrap(~ workload, scales="free_x", ncol=2) +
		xlab("Makespan [s]") +
		ylab("Queue manager")

	print(plot)
	dev.off()
}

plot.queue.sizes <- function() {
	dir <- "queue-sizes"
	mkdir(dir)

	res <- group_walk(group_by(values, setup, workload), function(data, group) {
		# Queue size graph
		arrivals <- data[, c("queue.manager")]
		arrivals$time <- data$arrival
		arrivals$value <- 1
		finishes <- data[, c("queue.manager")]
		finishes$time <- data$processing.end
		finishes$value <- -1
		
		queue.events <- rbind(arrivals, finishes)
		queue.events <- queue.events[order(queue.events$queue.manager, queue.events$time),]
		queue.events$queue.size <- ave(queue.events$value, queue.events$queue.manager, FUN=cumsum)
		queue.events <- aggregate(queue.size ~ queue.manager + time, data=queue.events, min)

		file <- tex.unsafe(paste(dir, "/", group$setup, ",", group$workload, sep=""))
		tikz(file=paste(file, ".tex", sep=""), width=5.5, height=6)
		plot <- ggplot(queue.events, aes(x=time, y=queue.size)) +
			geom_line() +
			facet_wrap(vars(queue.events$queue.manager), ncol=3)

		print(plot)
		ggsave(file=paste(file, ".png", sep=""), plot)
		dev.off()
	})
}

plot.wait.time.trends <- function() {
	dir <- "wait-time-trends"
	mkdir(dir)

	res <- group_walk(group_by(values, setup, workload), function(data, group) {
		arrival.breaks <- c(seq(0, max(data$arrival), max(data$arrival) / 20), Inf)
		arrival.breaks <- quantile(data$arrival, seq(0, 1, .05))
		data$arrival.discrete = cut(data$arrival, breaks=arrival.breaks, labels=1:20, include.lowest=T)

		# Lateness graph
		file <- tex.unsafe(paste(dir, "/lateness,", group$setup, ",", group$workload, sep=""))
		tikz(file=paste(file, ".tex", sep=""), width=5.5, height=7)

		plot <- ggplot(data, aes(arrival.discrete)) +
			geom_bar(aes(fill=lateness.class), position=position_fill()) +
			scale_fill_manual(values=c("On time"="darkgreen", "Delayed"="green", "Late"="pink", "Extremely late"="red"), name="Lateness classification") +
			theme(
			      axis.ticks.y=element_blank(), axis.text.y=element_blank(),
			      legend.position="bottom", legend.direction="vertical"
		        ) + 
			ggtitle(paste("Workload: ", group$workload, sep="")) +
			scale_x_discrete(breaks=c(0, 5, 10, 15, 20)) +
			facet_wrap(vars(data$queue.manager), ncol=3) + 
			labs(x="Discretized time of arrival", y="Number of jobs")
		print(plot)
		ggsave(file=paste(file, ".png", sep=""), plot)
		dev.off()

		# Relative wait time histogram
		file <- tex.unsafe(paste(dir, "/rel_wait_time,", group$setup, ",", group$workload, sep=""))
		tikz(file=paste(file, ".tex", sep=""), width=5.5, height=6)

		plot <- ggplot(data, aes(relative.wait.time)) +
			geom_histogram() +
			scale_y_log10() +
			facet_wrap(vars(data$queue.manager), ncol=3) +
			labs(x="Relative wait time", y="Number of jobs")
		print(plot)
		ggsave(file=paste(file, ".png", sep=""), plot)
		dev.off()
	})
}

plot.relative.wait.time.all <- function() {
	file <- tex.unsafe("rel_wait_time")
	tikz(file=paste(file, ".tex", sep=""), width=5.5, height=6)

	plot <- ggplot(values, aes(relative.wait.time)) +
		geom_histogram() +
		scale_y_log10() +
		labs(x="Relative wait time", y="Number of jobs (log-scale)") +
		facet_wrap(vars(values$queue.manager), ncol=3)
	print(plot)
	ggsave(file=paste(file, ".png", sep=""), plot)
	dev.off()
}


#plot.efficiency()
plot.queue.sizes()
plot.makespan()
plot.wait.time.trends()
plot.relative.wait.time.all()
