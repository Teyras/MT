source("../../plot_helpers/helpers.r")

library("ggplot2")
library("tikzDevice")
library("scales")

values <- read.csv(filename.from.args())
names(values) <- c("image", "implementation", "time")
values$time <- values$time / (10 * 1000)

make.plot <- function() {
	tikz("mount-vs-unpack.tex", width=5.5, height=4)
	plot <- ggplot(values, aes(x=image, y=time, color=implementation)) +
		geom_boxplot(position="dodge") +
		labs(x="Image", y="Time per operation [s]", color="Method")

	print(plot)
	ggsave("mount-vs-unpack.png")
}

make.plot()
