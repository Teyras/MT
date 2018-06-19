#!/bin/sh

root=$(dirname $(realpath $0))
results_file=$root/results-dependence-on-input.$(date '+%Y-%m-%d_%H:%M:%S').csv
iter_count=100

if [ $# -lt 1 ]; then
	workloads=$root/workloads.txt
else
	workloads="$1"
fi

for i in $(seq $iter_count); do
	./generate_data.sh $workloads

	cat $workloads | while read workload size iters; do
		echo ">>> $workload $size $iters"
		LABEL="" $root/measure_workload.sh \
			runners/run_baremetal.sh $workload $size $iters >> $results_file
	done
done

