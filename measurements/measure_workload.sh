#!/bin/sh
# Forwards arguments to a runner with an updated label and captures only the relevant output

runner=$1
workload=$2
data_size=$3
iters=$4

line_marker=">"

LABEL="$line_marker$LABEL,$workload,$data_size" $runner workloads/$workload "workloads/$(dirname $workload)/data.$data_size.in" $iters |
	grep "^$line_marker" |
	sed "s/^$line_marker//"

