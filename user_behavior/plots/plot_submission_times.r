source("../../plot_helpers/helpers.r")

library("ggplot2")
library("tikzDevice")
library("lubridate")
library("patchwork")

file <- filename.from.args()
values <- read.csv(file, sep="\t")
values$submitted_at <- ymd_hms(values$submitted_at)
values$submission.hour <- hour(values$submitted_at)
values$submission.day <- wday(values$submitted_at, label=T, locale="en_US.UTF-8")

make.plot <- function() {
	tikz("submission-time-histograms.tex", width=5.5, height=2.5)
	by.hour <- ggplot(values, aes(x=submission.hour)) +
		labs(x="Hour of day", y="Number of submissions") +
		geom_histogram(bins=24)
	by.day <- ggplot(values, aes(x=submission.day)) +
		labs(x="Day of week", y="Number of submissions") +
		theme(axis.title.y=element_blank()) +
		geom_histogram(stat="count")

	print(by.hour + by.day)
}

make.plot()
