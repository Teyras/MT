#!/bin/sh

if [ "$1" == "--taskset" ]; then
	taskset=1
	shift
fi

workers=$1
shift

cmd="$@"

if [ -n "$taskset" ]; then
	cmd="taskset -c {} $cmd"
fi

cmd="WORKER={} LABEL=\"$LABEL;$workers;cpu-{}\" $cmd"

top_worker=$(($(nproc --all) - 1))
step=$((2 * $(nproc --all) / $workers))

(seq 0 $step $top_worker && seq 1 $step $top_worker) | parallel -j$workers "$cmd"
