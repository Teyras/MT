#!/bin/sh

if [ "$1" == "--taskset" ]; then
	taskset=1
	shift
fi

workers=$1
shift

measure_cmd=$1
shift

label=$1
shift

cmd="$measure_cmd \"$label,$workers,cpu-{}\" $@"

if [ -n "$taskset" ]; then
	cmd="taskset -c {} $cmd"
fi

top_worker=$(($(nproc --all) - 1))
step=$((2 * $(nproc --all) / $workers))

(seq 0 $step $top_worker && seq 1 $step $top_worker) | parallel -j$workers "$cmd"
