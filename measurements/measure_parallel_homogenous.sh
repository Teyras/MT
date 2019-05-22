#!/bin/sh

if [ "$1" = "--taskset" ]; then
	taskset=1
	shift
fi

if [ "$1" = "--taskset-multi" ]; then
	taskset=1
	multi=1
	shift
fi

if [ "$1" = "--numa" ]; then
	numa=1
	shift
fi

workers=$1
shift

cmd="$@"

if [ -n "$taskset" ]; then
	cmd="taskset -c {} $cmd"
fi

if [ -n "$numa" ]; then
	nodecount=$(lscpu -p=socket | grep -v '^#' | sort | uniq | wc -l)
	cmd="numactl -m \$(({} % $nodecount)) $cmd"
fi

cmd="WORKER={} LABEL=$LABEL,$workers,cpu-\$(echo {} | tr ',' '+') $cmd"

if [ -n "$multi" ]; then
	$(dirname $0)/distribute_workers.sh --multi $workers | parallel -j$workers "$cmd"
else
	$(dirname $0)/distribute_workers.sh $workers | parallel -j$workers "$cmd"
fi
