#!/bin/sh

affinity=$(taskset -c -p $$ | cut -d : -f 2 | tr -d " ")
if echo $affinity | grep -v '-' > /dev/null 2> /dev/null; then
	args="--cpuset-cpus $affinity"
fi

echo docker run recodex-measurements:latest $args --rm --privileged -- "$@" | sed 's/$//'
