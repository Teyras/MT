#!/bin/sh

root=$(dirname $(realpath $0))

if [ $# -lt 1 ]; then
	workloads=$root/workloads.txt
else
	workloads="$1"
fi

# Compile everything and generate test data
pushd workloads
make
popd

# Prepare docker image
./build_docker.sh

# Make a new file to contain the results
results_file=$root/results.$(date '+%Y-%m-%d_%H:%M:%S').txt

# Measure on a single core
cat $workloads | while read workload size iters; do
	$root/measure_workload.sh "bare single" \
		runners/run_baremetal.sh $workload $size $iters > $results_file
	$root/measure_workload.sh "isolate single" \
		runners/run_isolate.sh $workload $size $iters > $results_file
	$root/run_docker.sh ./measure_workload.sh "docker-bare single" \
		runners/run_baremetal.sh $workload $size $iters > $results_file
	$root/run_docker.sh ./measure_workload.sh "docker-isolate single" \
		runners/run_isolate.sh $workload $size $iters > $results_file
done

# Measure the same workload on multiple cores at once
for workers in 2 10 20 40; do
	cat $workloads | while read workload size iters; do
		$root/measure_parallel_homogenous.sh $workers ./measure_workload.sh "bare parallel-homogenous" \
			runners/run_baremetal.sh $workload $size $iters > $results_file
		$root/measure_parallel_homogenous.sh $workers ./measure_workload.sh "isolate parallel-homogenous" \
			runners/run_isolate.sh $workload $size $iters > $results_file
		$root/measure_parallel_homogenous.sh $workers ./run_docker.sh ./measure_workload.sh "docker-bare parallel-homogenous" \
			runners/run_baremetal.sh $workload $size $iters > $results_file
		$root/measure_parallel_homogenous.sh $workers ./run_docker.sh ./measure_workload.sh "docker-isolate parallel-homogenous" \
			runners/run_isolate.sh $workload $size $iters > $results_file

		$root/measure_parallel_homogenous.sh --taskset $workers ./measure_workload.sh "bare parallel-homogenous-taskset" \
			runners/run_baremetal.sh $workload $size $iters > $results_file
		$root/measure_parallel_homogenous.sh --taskset $workers ./measure_workload.sh "isolate parallel-homogenous-taskset" \
			runners/run_isolate.sh $workload $size $iters > $results_file
		$root/measure_parallel_homogenous.sh --taskset $workers ./run_docker.sh ./measure_workload.sh "docker-bare parallel-homogenous" \
			runners/run_baremetal.sh $workload $size $iters > $results_file
		$root/measure_parallel_homogenous.sh --taskset $workers ./run_docker.sh ./measure_workload.sh "docker-isolate parallel-homogenous" \
			runners/run_isolate.sh $workload $size $iters > $results_file
	done
done
