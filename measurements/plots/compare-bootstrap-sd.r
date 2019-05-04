#!/usr/bin/Rscript

source("helpers.r")

library("boot")

values <- load.stability.results(filename.from.args())
values <- values[values$metric == "cpu" & values$taskset == FALSE & values$numa == FALSE, ]
values$wl <- paste(values$workload, values$input_size, sep=" ")

my.sd <- function (x, d) sd(x[d])

compare.sd.ci <- function (wl, setup, isolation1, isolation2) {
	data1 <- values[values$wl.short == wl & values$setup == setup & values$isolation == isolation1, ]$value
	data2 <- values[values$wl.short == wl & values$setup == setup & values$isolation == isolation2, ]$value

	if (length(data1) == 0 | length(data2) == 0) {
		return(NA)
	}


	boot1 <- boot(data1, my.sd, R=1000)
	boot2 <- boot(data2, my.sd, R=1000)

	return(ci.compare(boot1, boot2))
}

workloads <- c("sort/insertion_sort", "exp/exp_float", "bsearch/bsearch")
results <- unique(values[values$workload %in% workloads, c("setup", "wl.short")])

results$bare <- apply(results, 1, function (row) compare.sd.ci(row["wl.short"], row["setup"], "isolate", "bare"))
results$docker <- apply(results, 1, function (row) compare.sd.ci(row["wl.short"], row["setup"], "docker-isolate", "docker-bare"))
results$vbox <- apply(results, 1, function (row) compare.sd.ci(row["wl.short"], row["setup"], "vbox-isolate", "vbox-bare"))

cat("
Table: Results of comparison of 0.95 confidence intervals of the standard 
deviation of CPU time, with isolate vs. without isolate
\\label{sd-ci-comparison}
")

my.kable(results[order(results$wl.short), ], col.names=c("Setup", "Workload", "Bare", "Docker", "VBox"))
