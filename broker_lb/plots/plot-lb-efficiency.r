library("tikzDevice")
library("ggplot2")
library("tidyr")

source("../../measurements/plots/helpers.r")

values <- load.lb.results(filename.from.args())
values$wait.time <- values$processing.start - values$arrival
values$relative.wait.time <- values$wait.time / values$processing.time

values <- gather(values, key="metric", value="value", wait.time, relative.wait.time)

for (setup in unique(values$setup)) {
	tikz(file=paste("lb-efficiency-", setup, ".tex", sep=""))

	plot <- ggplot(values[values$setup == setup, ], aes(x=queue.manager, y=value)) +
		geom_boxplot() +
		facet_grid(rows=vars(metric), cols=vars(workload), scales="free")

	print(plot)
	dev.off()
}
