#!/usr/bin/Rscript

source("helpers.r")

library("boot")

values <- load.stability.results(filename.from.args())
values <- values[values$metric == "cpu" & values$taskset == FALSE & values$numa == FALSE, ]

my.mean <- function (x, d) mean(x[d])

compare.mean.ci <- function (wl, setup, isolation1, isolation2) {
	data1 <- values[values$wl.short == wl & values$setup == setup & values$isolation == isolation1, ]$value
	data2 <- values[values$wl.short == wl & values$setup == setup & values$isolation == isolation2, ]$value

	if (length(data1) == 0 | length(data2) == 0) {
		return(NA)
	}


	boot1 <- boot(data1, my.mean, R=1000)
	boot2 <- boot(data2, my.mean, R=1000)

	return(ci.compare(boot1, boot2))
}

workloads <- c("bsearch/bsearch", "exp/exp_float")
results <- unique(values[values$workload %in% workloads, c("setup", "wl.short")])

results$bare.vs.docker <- apply(results, 1, function (row) compare.mean.ci(row["wl.short"], row["setup"], "bare", "docker-bare"))
results$bare.vs.vbox <- apply(results, 1, function (row) compare.mean.ci(row["wl.short"], row["setup"], "bare", "vbox-bare"))
results$docker.vs.vbox <- apply(results, 1, function (row) compare.mean.ci(row["wl.short"], row["setup"], "docker-bare", "vbox-bare"))

cat("
Table: Results of comparison of 0.95 confidence intervals of the mean of CPU 
time for selected workloads \\label{mean-ci-comparison} on the bare metal (B), 
in docker (D) and in VirtualBox (V)
")

my.kable(results[order(results$wl.short),], col.names=c("Setup", "Workload", "B vs. D", "B vs. V", "D vs. V"))
