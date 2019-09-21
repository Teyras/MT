#!/usr/bin/Rscript

source("helpers.r")

library("boot")
library("tikzDevice")
library("ggplot2")
library("tidyr")

values <- load.stability.results(filename.from.args())
values <- values[values$metric == "cpu" & values$taskset == FALSE & values$numa == FALSE, ]
values$wl <- paste(values$workload, values$input_size, sep=" ")

my.sd <- function (x, d) sd(x[d])
my.mean <- function (x, d) mean(x[d])

compare.fn.ci <- function (fnc, wl, setup, isolation1, isolation2) {
	data1 <- values[values$wl.short == wl & values$setup == setup & values$isolation == isolation1, ]$value
	data2 <- values[values$wl.short == wl & values$setup == setup & values$isolation == isolation2, ]$value

	return(compare.fnc.boot(data1, data2))
}

workloads <- c("sort/qsort", "exp/exp_float", "bsearch/bsearch", "gray/gray2bin")
results <- unique(values[values$workload %in% workloads, c("setup", "wl.short")])

cmp <- data.frame(results)
cmp$sd.bare <- apply(results, 1, function (row) compare.fn.ci(my.sd, row["wl.short"], row["setup"], "isolate", "bare"))
cmp$sd.docker <- apply(results, 1, function (row) compare.fn.ci(my.sd, row["wl.short"], row["setup"], "docker-isolate", "docker-bare"))
cmp$sd.vbox <- apply(results, 1, function (row) compare.fn.ci(my.sd, row["wl.short"], row["setup"], "vbox-isolate", "vbox-bare"))

cmp$mean.bare <- apply(results, 1, function (row) compare.fn.ci(my.mean, row["wl.short"], row["setup"], "isolate", "bare"))
cmp$mean.docker <- apply(results, 1, function (row) compare.fn.ci(my.mean, row["wl.short"], row["setup"], "docker-isolate", "docker-bare"))
cmp$mean.vbox <- apply(results, 1, function (row) compare.fn.ci(my.mean, row["wl.short"], row["setup"], "vbox-isolate", "vbox-bare"))

tikz(file="isolate-ci-comparison.tex", width=5.5, height=5)
cmp <- gather(cmp, sd.bare, sd.docker, sd.vbox, mean.bare, mean.docker, mean.vbox, key="key", value="result")
cmp$type <- ifelse(grepl("^mean", cmp$key), "Mean", "Standard deviation")
cmp <- drop_na(cmp, result)
cmp$result[which(cmp$result == "overlap")] <- "same"

ggplot(data=cmp, aes(x=key, fill=result)) +
	geom_bar(stat="count") +
	coord_flip() +
	labs(x="", y="") +
	scale_x_discrete(labels=c(
				  "mean.bare" = "I \\textless B", 
				  "mean.docker" = "D + I \\textless D",
				  "mean.vbox" = "V + I \\textless V",
				  "sd.bare" = "I \\textless B", 
				  "sd.docker" = "D + I \\textless D",
				  "sd.vbox" = "V + I \\textless V"
				  )) +
	scale_fill_discrete(name="Comparison result", labels=c(
				  "False",
				  "True",
				  "Equal"
				  )) +
	facet_wrap(. ~ type, ncol=1, scales="free")

