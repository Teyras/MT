#!/bin/sh

cat workloads.txt | while read workload size iters; do
	./measure_workload.sh "bare single" runners/run_baremetal.sh $workload $size $iters
	./measure_workload.sh "isolate single" runners/run_isolate.sh $workload $size $iters
done

for workers in 2 10 20 40; do
	cat workloads.txt | while read workload size iters; do
		./measure_parallel_homogenous.sh $workers "bare parallel-homogenous" runners/run_baremetal.sh $workload $size $iters
		./measure_parallel_homogenous.sh $workers "isolate parallel-homogenous" runners/run_baremetal.sh $workload $size $iters

		./measure_parallel_homogenous.sh --taskset $workers "bare parallel-homogenous" runners/run_baremetal.sh $workload $size $iters
		./measure_parallel_homogenous.sh --taskset $workers "isolate parallel-homogenous" runners/run_baremetal.sh $workload $size $iters
	done
done
