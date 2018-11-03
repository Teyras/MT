#!/bin/sh

stress_opts=$1
shift

if [ "$1" == "--taskset" ]; then
	taskset=1
	shift
fi

worker_count=$1
shift

cmd="$@"
stress_cmd="stress-ng $stress_opts"

worker_cpus=$($(dirname $0)/distribute_workers.sh $worker_count)
cmd_worker=$(echo "$worker_cpus" | head -n 1)
stress_workers=$(echo "$worker_cpus" | tail -n+2)

if [ -n "$taskset" ]; then
	cmd="taskset -c $cmd_worker $cmd"
	stress_cmd="taskset -c {} $stress_cmd"
fi

echo "$stress_workers" | parallel -j$(($worker_count - 1)) $stress_cmd > /dev/null 2>&1 &
sleep 1

WORKER=$cmd_worker LABEL="$LABEL,$worker_count,cpu-$cmd_worker" $cmd

killall stress-ng

