library("ggplot2")
library("tikzDevice")

source("../../plot_helpers/helpers.r")

ratios <- read.csv(filename.from.args())

tikz("parallel-run-ratios.tex", width=5.5, height=4)

ggplot(ratios, aes(x=parallel_ratio)) +
	labs(x="Ratio of time spent with all processes running and the total time", y="Number of groups") +
	scale_x_reverse() +
	geom_histogram(bins=20)
