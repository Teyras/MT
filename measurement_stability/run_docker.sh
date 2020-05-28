#!/bin/sh

args=""

cpus=$(numactl --show | grep physcpubind: | cut -f 2 -d :)
cpucount=$(lscpu -p=cpu | grep -v '^#' | sort | uniq | wc -l)
if [ $(echo $cpus | wc -w) -lt $cpucount ]; then
	args="$args --cpuset-cpus $(echo $cpus | xargs -n 1 | paste -sd ",")"
fi

mems=$(numactl --show | grep membind: | cut -f 2 -d :)
memcount=$(lscpu -p=socket | grep -v '^#' | sort | uniq | wc -l)
if [ $(echo $mems | wc -w) -lt $(echo $memcount | wc -w) ]; then
	args="$args --cpuset-mems $(echo $mems | xargs -n 1 | paste -sd ",")"
fi

if [ -n "$PERF_OPTS" ]; then
	args="$args -e PERF_OPTS=$PERF_OPTS"
fi

docker run -e LABEL="$LABEL" $args --rm --privileged recodex-measurements:latest "$@" | sed 's/$//'

