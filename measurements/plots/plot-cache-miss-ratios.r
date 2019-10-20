library("ggplot2")
library("tidyr")
library("tikzDevice")

source("helpers.r")

results <- load.stability.results(filename.from.args())
values <- spread(results, key=metric, value=value)

workloads <- c("exp/exp_float", "bsearch/bsearch", "gray/gray2bin", "sort/qsort")
#workloads <- c("bsearch/bsearch", "sort/qsort")
isolations <- c("bare", "isolate")

values <- values[
		 values$setup_type %in% c("single", "parallel-homogenous") & 
		 values$workload %in% workloads &
		 values$isolation %in% isolations &
		 values$taskset == F & 
		 values$multi == F & 
		 values$numa == F & 
		 values$noht == F &
		 values$worker == "cpu-0",
	 ]

values$l1_dcache_load_ratio <- values[,"L1-dcache-misses"] / values[,"L1-dcache-loads"]
values$llc_load_ratio <- values[,"LLC-load-misses"] / values[,"LLC-loads"]
values$llc_store_ratio <- values[,"LLC-store-misses"] / values[,"LLC-stores"]

names(values)[names(values) == "L1-dcache-misses"] <- "L1_dcache_misses"
names(values)[names(values) == "L1-dcache-loads"] <- "L1_dcache_loads"
names(values)[names(values) == "LLC-load-misses"] <- "LLC_load_misses"
names(values)[names(values) == "LLC-loads"] <- "LLC_loads"
names(values)[names(values) == "LLC-store-misses"] <- "LLC_store_misses"
names(values)[names(values) == "LLC-stores"] <- "LLC_stores"

dir <- "cache_miss_ratios/"
mkdir(dir)

plot.ratios <- function(column) {
	values <- data.frame(values)
	values$setup_size <- factor(values$setup_size)
	print(cor(values[[column]], values$cpu, method="spearman"))

	tikz(file=paste(dir, "misses-over-isolations-", column, ".tex", sep=""), width=5.5, height=9)
	plot <- ggplot(values, aes_string(y=column, x="setup_size")) + 
		geom_boxplot() +
		labs(x="Number of workers", y="Miss ratio") +
		facet_grid(cols=vars(isolation), rows=vars(wl.short), labeller=labeller(wl.short=wl.labels), scales="free")
	print(plot)
	dev.off()
}

plot.correlation <- function(column) {
	tikz(file=paste(dir, "correlation-", column, ".tex", sep=""), width=5.5, height=9)
	print(cor(values[[column]], values$cpu, method="spearman"))

	plot <- ggplot(values[sample(nrow(values), 1000, prob=1/values$setup_size),], aes_string(x=column, y="cpu")) +
		scale_x_continuous(labels=scales::scientific) +
		geom_point(shape=19) +
		geom_smooth(method=lm) +
		facet_wrap(.~wl.short+isolation, labeller=labeller(wl.short=wl.labels), scales="free", ncol=2) +
		labs(y="CPU time", x="Cache misses")
	print(plot)
	dev.off()
}

make.correlation.table <- function() {
	# table <- data.frame(metric = c("L1_dcache_misses", "LLC_load_misses", "LLC_store_misses"), stringsAsFactors=F)
	# table$cor <- lapply(table$metric, function (metric) round(cor(values[[metric]], values$cpu, method="pearson"), digits=3))
	# table$spearman <- lapply(table$metric, function (metric) round(cor(values[[metric]], values$cpu, method="spearman"), digits=3))

	table <- unique(results[results$metric %in% c("L1-dcache-misses", "LLC-load-misses", "LLC-store-misses"), c("metric", "wl.short")])
	table$metric <- gsub("-", "_", table$metric)
	table$cor <- apply(table, 1, function (row) cor(values[values$wl.short == row[2], ][[row[1]]], values[values$wl.short == row[2], ]$cpu))
	table$spearman <- apply(table, 1, function (row) cor(values[values$wl.short == row[2], ][[row[1]]], values[values$wl.short == row[2], ]$cpu, method="spearman"))
	table <- na.omit(table)

	cat("
Table: Correlation of CPU time and selected performance metrics \\label{perf-correlations}
        ", file="perf-correlations.md", sep="\n")
	cat(my.kable(table, c("Metric", "Workload", "Pearson correlation", "Spearman correlation")), file="perf-correlations.md", sep="\n", append=T)
}

# plot.ratios("l1_dcache_load_ratio")
# plot.ratios("llc_load_ratio")
# plot.ratios("llc_store_ratio")

# plot.correlation("L1_dcache_misses")
# plot.correlation("LLC_load_misses")
# plot.correlation("LLC_store_misses")

make.correlation.table()
