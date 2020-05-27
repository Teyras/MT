#!/usr/bin/Rscript

source("helpers.r")

library("boot")
library("tidyr")
library("tikzDevice")
library("ggplot2")

values <- load.stability.results(filename.from.args())
values <- values[values$metric == "cpu" & values$taskset == FALSE & values$numa == FALSE, ]

my.mean <- function (x, d) mean(x[d])
my.sd <- function (x, d) sd(x[d])

compare.fnc.ci <- function (fnc, wl, setup, isolation1, isolation2) {
	data1 <- values[values$wl.short == wl & values$setup == setup & values$isolation == isolation1, ]$value
	data2 <- values[values$wl.short == wl & values$setup == setup & values$isolation == isolation2, ]$value

	return(compare.fnc.boot(fnc, data1, data2))
}

workloads <- c("bsearch/bsearch", "exp/exp_float")
results <- unique(values[values$workload %in% workloads, c("setup", "wl.short")])

cmp <- data.frame(results)
cmp$mean.bare.vs.docker <- apply(results, 1, function (row) compare.fnc.ci(my.mean, row["wl.short"], row["setup"], "bare", "docker-bare"))
cmp$mean.bare.vs.vbox <- apply(results, 1, function (row) compare.fnc.ci(my.mean, row["wl.short"], row["setup"], "bare", "vbox-bare"))
cmp$mean.docker.vs.vbox <- apply(results, 1, function (row) compare.fnc.ci(my.mean, row["wl.short"], row["setup"], "docker-bare", "vbox-bare"))
cmp$sd.bare.vs.docker <- apply(results, 1, function (row) compare.fnc.ci(my.sd, row["wl.short"], row["setup"], "bare", "docker-bare"))
cmp$sd.bare.vs.vbox <- apply(results, 1, function (row) compare.fnc.ci(my.sd, row["wl.short"], row["setup"], "bare", "vbox-bare"))
cmp$sd.docker.vs.vbox <- apply(results, 1, function (row) compare.fnc.ci(my.sd, row["wl.short"], row["setup"], "docker-bare", "vbox-bare"))

tikz(file="virt-ci-comparison.tex", width=5.5, height=3)
cmp <- gather(cmp, mean.bare.vs.docker, mean.bare.vs.vbox, mean.docker.vs.vbox, sd.bare.vs.docker, sd.bare.vs.vbox, sd.docker.vs.vbox, key="key", value="result")
cmp$type <- ifelse(grepl("^mean", cmp$key), "Mean", "Standard deviation")
cmp <- drop_na(cmp, result)
cmp$result[which(cmp$result == "overlap")] <- "same"

ggplot(data=cmp, aes(x=key, fill=result)) +
	geom_bar(stat="count") +
	coord_flip() +
	labs(x="", y="") +
	scale_x_discrete(labels=c(
				  "mean.bare.vs.docker" = "B \\textless D", 
				  "mean.bare.vs.vbox" = "B \\textless V",
				  "mean.docker.vs.vbox" = "D \\textless V",
				  "sd.bare.vs.docker" = "B \\textless D", 
				  "sd.bare.vs.vbox" = "B \\textless V",
				  "sd.docker.vs.vbox" = "D \\textless V"
				  )) +
	scale_fill_discrete(name="Comparison\nresult", labels=c(
				  "False",
				  "True",
				  "Equal"
				  )) +
	facet_wrap(. ~ type, ncol=1, scales="free")

