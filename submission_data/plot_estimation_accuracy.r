source("../measurements/plots/helpers.r")

library("ggplot2")
library("ggrepel")
library("tikzDevice")
library("dplyr")

file <- filename.from.args()
values <- read.csv(file, sep="\t")
values$error <- 100 * (values$prediction - values$processing_time) / (values$processing_time)
values$error.corrected <- ifelse(values$error > 100, 105, values$error)
print(c(
      nrow(values[abs(values$error) < 10,]) / nrow(values),
      nrow(values[abs(values$error) < 20,]) / nrow(values),
      nrow(values[abs(values$error) < 50,]) / nrow(values),
      nrow(values[abs(values$error) > 100,]) / nrow(values),
      nrow(values[abs(values$error) > 1000,]) / nrow(values)
))

percentiles <- c(.05, .1, .2, .4, .6, .8, .95, 1)
print(quantile(abs(values[values$error >= 0, ]$error), percentiles))
print(quantile(abs(values[values$error < 0, ]$error), percentiles))
print(nrow(values[values$error >= 0,]))
print(nrow(values[values$error < 0,]))

breaks <- c(0, .1, .25, .5, 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, Inf)
values$processing_time_category <- cut(values$processing_time, breaks, right=F)

error_breaks <- c(2, 5, 10, 20, 50, 75, 100, 200, 300, 400, 800, 1600, 3200, 6400, Inf)
error_breaks <- c(10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110)
error_breaks <- c(-rev(error_breaks), 0, error_breaks)
values$error_category <- cut(values$error, error_breaks, right=F)

#print(values %>% count(processing_time_category, error_category), n=100)

make.plot <- function(max.processing.time) {
	subset <- values[values$processing_time > 0 & values$processing_time <= max.processing.time, ]
	plot <- ggplot(subset, aes(x=processing_time, y=prediction)) +
		#geom_point(shape=19) +
		geom_bin2d(bins=100) +
		scale_fill_continuous(type = "viridis") +
		geom_abline(color="red", slope=1, intercept=0) +
		ylim(0, min(2 * max.processing.time, max(subset$prediction)))

	ggsave(paste("accuracy-", max.processing.time, ".png", sep=""), plot)
}

make.error.histogram <- function() {
	plot <- ggplot(values, aes(x=processing_time_category, y=error_category)) +
		geom_bin2d() +
		stat_bin2d(geom = "text", aes(label = ..count..), size=2) +
		scale_fill_continuous(type = "viridis") +
		theme(axis.text.x = element_text(angle=90, hjust=1))

	ggsave("error-hist.png", plot)
}

make.error.density.plots <- function() {
	counts <- values %>% count(processing_time_category)
	tikz("estimation-error-histograms.tex", width=5.5, height=8)
	plot <- ggplot(values, aes(error.corrected)) +
		geom_histogram(breaks=error_breaks) +
		geom_text_repel(data=counts, aes(x=-100, y=Inf, label=paste("n=", n, sep=""), hjust="left", vjust="top"), inherit.aes=F, parse=F, size=3) +
		facet_wrap(~processing_time_category, scales="free", ncol=3) +
		theme(axis.title.y = element_blank()) +
		labs(x="Relative error [\\%]", y="Observation count")

	print(plot)
	ggsave("estimation-error-histograms.png", plot)
}

#make.plot(1)
#make.plot(10)
#make.plot(20)
#make.plot(50)
#make.plot(200)
#make.plot(2000)

make.error.histogram()
make.error.density.plots()
