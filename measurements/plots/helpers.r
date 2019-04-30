cv <- function(data) {
	return((sd(data) * 100) / mean(data))
}

span <- function(data) {
	return(max(data) / min(data))
}

range <- function(data) {
	return(max(data) - min(data))
}

filename.from.args <- function () {
	args <- commandArgs(trailingOnly=TRUE)

	if (length(args) == 0) {
		stop("Please, supply a result file as a CLI argument")
	}

	return(args[1])
}

load.stability.results <- function(file) {
	values <- read.csv(file, header=FALSE, stringsAsFactors=FALSE)
	names(values) = c("isolation", "setup_type", "setup_size", "worker", "workload", "input_size", "iteration", "metric", "value")
	values$value <- as.numeric(values$value)
	values$setup <- paste(values$setup_type, values$setup_size, sep=",")
	values$taskset <- grepl("taskset", values$setup)
	return(values)
}

mkdir <- function(dir) {
	dir.create(file.path(".", dir), showWarnings=FALSE)
}

ci.compare <- function (boot1, boot2) {
	ci1 <- boot.ci(boot1, type="basic")
	lower1 <- ci1$basic[1, 4]
	upper1 <- ci1$basic[1, 5]

	ci2 <- boot.ci(boot2, type="basic")
	lower2 <- ci2$basic[1, 4]
	upper2 <- ci2$basic[1, 5]

	if (lower1 > upper2) {
		return("higher")
	}

	if (lower2 > upper1) {
		return("lesser")
	}

	if ((lower1 > lower2 & upper1 < upper2) | (lower2 > lower1 & upper2 < upper1)) {
		return("same")
	}

	return ("overlap")
}
