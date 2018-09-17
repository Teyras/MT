#!/usr/bin/Rscript

source("helpers.r")

library("boot")
library("knitr")

values <- load.stability.results(filename.from.args())
values <- values[values$metric == "cpu" & values$taskset == FALSE, ]
values$wl <- paste(values$workload, values$input_size, sep=" ")

my.mean <- function (x, d) mean(x[d])

compare.mean.ci <- function (wl, setup, isolation1, isolation2) {
	data1 <- values[values$wl == wl & values$setup == setup & values$isolation == isolation1, ]$value
	data2 <- values[values$wl == wl & values$setup == setup & values$isolation == isolation2, ]$value

	if (length(data1) == 0 | length(data2) == 0) {
		return(NA)
	}


	boot1 <- boot(data1, my.mean, R=1000)
	boot2 <- boot(data2, my.mean, R=1000)

	return(ci.compare(boot1, boot2))
}

results <- unique(values[values$workload %in% c("bsearch/bsearch", "sort/qsort"), c("setup", "wl")])

results$bare.vs.docker <- apply(results, 1, function (row) compare.mean.ci(row["wl"], row["setup"], "bare", "docker-bare"))
results$bare.vs.vbox <- apply(results, 1, function (row) compare.mean.ci(row["wl"], row["setup"], "bare", "vbox-bare"))
results$docker.vs.vbox <- apply(results, 1, function (row) compare.mean.ci(row["wl"], row["setup"], "docker-bare", "vbox-bare"))

kable(results, row.names=F)
