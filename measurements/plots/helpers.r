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
	values <- read.csv(file, header=FALSE)
	names(values) = c("isolation", "setup_type", "setup_size", "worker", "workload", "input_size", "iteration", "metric", "value")
	values$value <- as.numeric(values$value)
	values$setup <- paste(values$setup_type, values$setup_size, sep=",")
	values$taskset <- grepl("taskset", values$setup)
	return(values)
}

mkdir <- function(dir) {
	dir.create(file.path(".", dir), showWarnings=FALSE)
}
