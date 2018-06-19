#!/bin/sh

affinity=$(taskset -c -p $$ | cut -d : -f 2 | tr -d " ")
if echo $affinity | grep -v '-' > /dev/null 2> /dev/null; then
	args="--cpuset-cpus $affinity"
fi

docker run -e LABEL="$LABEL" $args --rm --privileged recodex-measurements:latest "$@" | sed 's/$//'

