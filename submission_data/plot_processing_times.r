source("../measurements/plots/helpers.r")

library("ggplot2")
library("tikzDevice")

file <- filename.from.args()
values <- read.csv(file, sep="\t")

print(quantile(values$processing_time, c(.95)))

make.plot <- function() {
	#subset <- values[values$processing_time <= 50000,]
	subset <- values
	plot <- ggplot(subset, aes(x=processing_time)) +
		geom_histogram(bins=16) +
		labs(x="Processing time", y="Evaluation count") +
		scale_x_continuous(trans="log2") +
		facet_wrap(~ runtime_environment_id,scales="free", ncol=3) +
		theme(axis.text.x = element_text(angle=90, hjust=1, size=6))

	tikz("processing-times-histograms.tex", width=5.5, height=6)
	print(plot)
	ggsave("processing-times-histograms.png")
}

make.plot()
