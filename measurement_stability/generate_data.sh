#!/bin/sh

workloads=$1

cat $workloads | tr "/" " " | cut -d " " -f 1,3  | sort | uniq | while read dir size; do
	pushd $(dirname $0)/workloads/$dir
	./gendata.sh $size
	popd > /dev/null
done
