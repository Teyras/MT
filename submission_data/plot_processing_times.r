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
		facet_wrap(~ runtime_environment_id,scales="free") +
		theme(axis.text.x = element_text(angle=90, hjust=1, size=6))

	tikz("processing_times_hist.tex")
	print(plot)
	ggsave("processing_times_hist.png")
}

make.plot()
