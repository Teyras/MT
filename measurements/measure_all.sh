#!/bin/sh

trap "exit" INT

root=$(dirname $(realpath $0))
export MEASUREMENTS_ROOT=$root

if [ $# -lt 1 ]; then
	workloads=$root/workloads.txt
else
	workloads="$1"
fi

# Clean old isolate boxes
for i in $(ls /var/local/lib/isolate); do
	isolate -b $i --cg --cleanup
done

# Compile everything and generate test data
pushd workloads
make
popd

# Prepare docker image
./build_docker.sh

# Prepare vbox VMs
#./build_vbox.sh

# Make a new file to contain the results
results_file=$root/results.$(date '+%Y-%m-%d_%H:%M:%S').csv

function measure_each_isolation() {
	setup=$1
	worker_count=$2
	wrapper_cmd=$3
	taskset=$4

	cat $workloads | while read workload size iters; do
		echo ">>> $workload $size $iters ($worker_count workers, $setup)"

		LABEL="bare,$setup" $wrapper_cmd $workers ./measure_workload.sh \
			runners/run_baremetal.sh $workload $size $iters >> $results_file
		LABEL="isolate,$setup" $wrapper_cmd $workers ./measure_workload.sh \
			runners/run_isolate.sh $workload $size $iters >> $results_file
		LABEL="docker-bare,$setup" $wrapper_cmd $workers ./run_docker.sh ./measure_workload.sh \
			runners/run_baremetal.sh $workload $size $iters >> $results_file
		LABEL="docker-isolate,$setup" $wrapper_cmd $workers ./run_docker.sh ./measure_workload.sh \
			runners/run_isolate.sh $workload $size $iters >> $results_file

		if [ "$workers" -le 20 ]; then
			./start_vbox.sh $workers
			LABEL="vbox-bare,$setup" $wrapper_cmd $workers $root/run_vbox.sh ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file < /dev/null
			LABEL="vbox-isolate,$setup" $wrapper_cmd $workers $root/run_vbox.sh ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file < /dev/null
			./stop_vbox.sh
		fi

		if [ -z "$taskset" ]; then
			continue
		fi

		LABEL="bare,$setup-taskset" $wrapper_cmd --taskset $workers ./measure_workload.sh \
			runners/run_baremetal.sh $workload $size $iters >> $results_file
		LABEL="isolate,$setup-taskset" $wrapper_cmd --taskset $workers ./measure_workload.sh \
			runners/run_isolate.sh $workload $size $iters >> $results_file
		LABEL="docker-bare,$setup-taskset" $wrapper_cmd --taskset $workers ./run_docker.sh ./measure_workload.sh \
			runners/run_baremetal.sh $workload $size $iters >> $results_file
		LABEL="docker-isolate,$setup-taskset" $wrapper_cmd --taskset $workers ./run_docker.sh ./measure_workload.sh \
			runners/run_isolate.sh $workload $size $iters >> $results_file
	done
}

# Measure on a single core
measure_each_isolation "single" 1 "LABEL=$LABEL,1,cpu-0"

# Measure a workload under multiple levels of CPU stress
for workers in 2 4 6 8 10 20 40; do
	measure_each_isolation "parallel-synth-cpu" $workers "$root/measure_parallel_synth_stress.sh '--cpu 1'" --taskset
done

# Measure a workload under multiple levels of memory contention stress
for workers in 2 4 6 8 10 20 40; do
	measure_each_isolation "parallel-synth-memcontend" $workers "$root/measure_parallel_synth_stress.sh '--mcontend 1'" --taskset
done

# Measure a workload under multiple levels of memory copying stress
for workers in 2 4 6 8 10 20 40; do
	measure_each_isolation "parallel-synth-memcpy" $workers "$root/measure_parallel_synth_stress.sh '--memcpy 1'" --taskset
done

# Measure the same workload on multiple cores at once
for workers in 2 4 6 8 10 20 40; do
	measure_each_isolation "parallel-homogenous" $workers $root/measure_parallel_homogenous.sh --taskset
done
