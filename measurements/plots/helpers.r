cv <- function(data) {
	return((sd(data) * 100) / mean(data))
}

span <- function(data) {
	return(max(data) / min(data))
}

filename.from.args <- function () {
	args <- commandArgs(trailingOnly=TRUE)

	if (length(args) == 0) {
		stop("Please, supply a result file as a CLI argument")
	}

	return(args[1])
}

load.stability.results <- function(file) {
	lines = readLines(file)
	values = as.data.frame(do.call(rbind, strsplit(lines, split="[ :]+")), stringsAsFactors=FALSE)
	names(values) = c("isolation", "setup", "workload", "input_size", "metric", "value")
	values$value <- as.numeric(values$value)
	values$setup <- gsub(",cpu-\\d+", "", values$setup)
	values$taskset <- grepl("taskset", values$setup)
	return(values)
}
