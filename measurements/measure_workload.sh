#!/bin/sh
# Forwards arguments to a runner with an updated label and captures only the relevant output

label=$1
runner=$2
workload=$3
data_size=$4
iters=$5

line_marker=">"

$runner workloads/$workload "workloads/$(dirname $workload)/data.$data_size.in" $iters "$line_marker$label $workload $data_size" |
	grep "^$line_marker" |
	sed "s/^$line_marker//"

