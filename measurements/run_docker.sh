#!/bin/sh

args=""

affinity=$(taskset -c -p $$ | cut -d : -f 2 | tr -d " ")
if echo $affinity | grep -v '-' > /dev/null 2> /dev/null; then
	args="$args --cpuset-cpus $affinity"
fi

if [ -n "$PERF_OPTS" ]; then
	args="$args -e PERF_OPTS=$PERF_OPTS"
fi

docker run -e LABEL="$LABEL" $args --rm --privileged recodex-measurements:latest "$@" | sed 's/$//'

