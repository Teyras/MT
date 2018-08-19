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

cmd="WORKER={} LABEL=\"$LABEL,$workers,cpu-{}\" $cmd"


$(dirname $0)/distribute_workers.sh $workers | parallel -j$workers "$cmd"
