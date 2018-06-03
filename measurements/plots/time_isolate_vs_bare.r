#!/usr/bin/Rscript

source("helpers.r")

values <- load.stability.results(filename.from.args())

isolations <- unique(values[values$metric == "iso-cpu", ]$isolation)

for (row_isolations in 1:length(isolations)) {
	isolation <- isolations[row_isolations]
	workloads <- unique(values[values$isolation == isolation, c("workload", "input_size")])
}
