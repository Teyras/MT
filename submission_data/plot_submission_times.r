source("../measurements/plots/helpers.r")

library("ggplot2")
library("tikzDevice")
library("lubridate")

file <- filename.from.args()
values <- read.csv(file, sep="\t")
values$submitted_at <- ymd_hms(values$submitted_at)
values$submission.hour <- hour(values$submitted_at)
values$submission.day <- wday(values$submitted_at, label=T, locale="en_US.UTF-8")

make.plot.by.hour <- function() {
	plot <- ggplot(values, aes(x=values$submission.hour)) +
		labs(x="Hour of day", y="Number of submissions") +
		geom_histogram(bins=24)

	tikz("submission-hour-histogram.tex", width=5.5, height=4)
	print(plot)
}

make.plot.by.weekday <- function() {
	plot <- ggplot(values, aes(x=values$submission.day)) +
		labs(x="Day of week", y="Number of submissions") +
		geom_histogram(stat="count")

	tikz("submission-day-histogram.tex", width=5.5, height=4)
	print(plot)
}

make.plot.by.hour()
make.plot.by.weekday()
