source("../../plot_helpers/helpers.r")

library("ggplot2")
library("tikzDevice")

file <- filename.from.args()
values <- read.csv(file, sep="\t")

print(quantile(values$processing_time, c(.95)))

make.plot <- function() {
	subset <- values
	plot <- ggplot(subset, aes(x=processing_time / 1000)) +
		geom_histogram(bins=16) +
		labs(x="Processing time [s] (log2-scale)", y="Evaluation count") +
		scale_x_continuous(trans="log2", labels=function (x) paste(signif(x, 2))) +
		facet_wrap(~ runtime_environment_id, scales="free", ncol=3) +
		theme(axis.text.x = element_text(size=6))

	tikz("processing-times-histograms.tex", width=5.5, height=5)
	print(plot)
	ggsave("processing-times-histograms.png")
}

make.plot()
