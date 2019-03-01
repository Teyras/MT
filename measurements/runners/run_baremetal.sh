#!/bin/sh
source $(dirname $0)/perf_wrapper.sh

cmd=$1
data=$2
iterations=$3

err=$(mktemp)
perf=$(mktemp)

for i in $(seq $iterations); do
	perf_wrapper $perf $cmd > /dev/null < $data 2> $err

	cat $err | sed "s@^@$LABEL,${i},@"
	perf_print $perf | sed "s@^@$LABEL,${i},@"
done 2>&1

rm $err
rm $perf
