source("../../measurements/plots/helpers.r")

values <- load.lb.results(filename.from.args())
values$wait.time <- values$processing.start - values$arrival
values$relative.wait.time <- values$wait.time / values$processing.time

head(values[order(-values$relative.wait.time),])
