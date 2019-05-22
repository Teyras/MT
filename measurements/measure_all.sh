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

function measure_each_isolation() {
	setup=$1
	worker_count=$2
	wrapper_cmd="$3"
	mode="$4"

	cat $workloads | while read workload size iters; do
		echo ">>> $workload $size $iters ($worker_count workers, $setup $mode)"

		if [ "$mode" = "--taskset" ]; then
			LABEL=bare,$setup-taskset eval $wrapper_cmd --taskset $worker_count ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=isolate,$setup-taskset eval $wrapper_cmd --taskset $worker_count ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file
			LABEL=docker-bare,$setup-taskset eval $wrapper_cmd --taskset $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=docker-isolate,$setup-taskset eval $wrapper_cmd --taskset $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file
		elif [ "$mode" = "--taskset-multi" ]; then
			LABEL=bare,$setup-taskset-multi eval $wrapper_cmd --taskset-multi $worker_count ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=isolate,$setup-taskset-multi eval $wrapper_cmd --taskset-multi $worker_count ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file
			LABEL=docker-bare,$setup-taskset-multi eval $wrapper_cmd --taskset-multi $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=docker-isolate,$setup-taskset-multi eval $wrapper_cmd --taskset-multi $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file
		elif [ "$mode" = "--numa" ]; then
			LABEL=bare,$setup-numa eval $wrapper_cmd --numa $worker_count ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=isolate,$setup-numa eval $wrapper_cmd --numa $worker_count ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file
			LABEL=docker-bare,$setup-numa eval $wrapper_cmd --numa $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=docker-isolate,$setup-numa eval $wrapper_cmd --numa $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file
		else
			LABEL=bare,$setup eval $wrapper_cmd $worker_count ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=isolate,$setup eval $wrapper_cmd $worker_count ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file
			LABEL=docker-bare,$setup eval $wrapper_cmd $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=docker-isolate,$setup eval $wrapper_cmd $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file

			if [ "$worker_count" -le 20 ]; then
				./start_vbox.sh $worker_count > /dev/null 2>&1
				LABEL=vbox-bare,$setup eval $wrapper_cmd $worker_count $root/run_vbox.sh ./measure_workload.sh \
					runners/run_baremetal.sh $workload $size $iters >> $results_file < /dev/null
				LABEL=vbox-isolate,$setup eval $wrapper_cmd $worker_count $root/run_vbox.sh ./measure_workload.sh \
					runners/run_isolate.sh $workload $size $iters >> $results_file < /dev/null
				./stop_vbox.sh > /dev/null 2>&1
			fi
		fi
	done
}

function measure_everything() {
	# Measure on a single core
	measure_each_isolation "single" 1 $root/measure_single.sh

	 Measure a workload under multiple levels of CPU stress
	for workers in 2 4 6 8 10 20 40; do
		measure_each_isolation "parallel-synth-cpu" $workers "$root/measure_parallel_synth_stress.sh \"--cpu 1\""
		measure_each_isolation "parallel-synth-cpu" $workers "$root/measure_parallel_synth_stress.sh \"--cpu 1\"" --taskset
		measure_each_isolation "parallel-synth-cpu" $workers "$root/measure_parallel_synth_stress.sh \"--cpu 1\"" --numa
	done

	for workers in 2 4 8 10 20; do
		measure_each_isolation "parallel-synth-cpu" $workers "$root/measure_parallel_synth_stress.sh \"--cpu 1\"" --taskset-multi
	done

	# Measure a workload under multiple levels of memory copying stress
	for workers in 2 4 6 8 10 20 40; do
		measure_each_isolation "parallel-synth-memcpy" $workers "$root/measure_parallel_synth_stress.sh \"--memcpy 1\""
		measure_each_isolation "parallel-synth-memcpy" $workers "$root/measure_parallel_synth_stress.sh \"--memcpy 1\"" --taskset
		measure_each_isolation "parallel-synth-memcpy" $workers "$root/measure_parallel_synth_stress.sh \"--memcpy 1\"" --numa
	done

	for workers in 2 4 8 10 20; do
		measure_each_isolation "parallel-synth-memcpy" $workers "$root/measure_parallel_synth_stress.sh \"--memcpy 1\"" --taskset-multi
	done

	# Measure the same workload on multiple cores at once
	for workers in 2 4 6 8 10 20 40; do
		measure_each_isolation "parallel-homogenous" $workers $root/measure_parallel_homogenous.sh
		measure_each_isolation "parallel-homogenous" $workers $root/measure_parallel_homogenous.sh --taskset
		measure_each_isolation "parallel-homogenous" $workers $root/measure_parallel_homogenous.sh --numa
	done

	for workers in 2 4 8 10 20; do
		measure_each_isolation "parallel-homogenous" $workers $root/measure_parallel_homogenous.sh --taskset-multi
	done
}

# Make a new file to contain the results
results_file=$root/results.$(date '+%Y-%m-%d_%H:%M:%S').csv

# Run with perf disabled
measure_everything

# Make another file to contain the results with perf enabled
results_file=$root/results-perf.$(date '+%Y-%m-%d_%H:%M:%S').csv

export PERF_OPTS="L1-dcache-loads,L1-dcache-misses,LLC-stores,LLC-store-misses,LLC-loads,LLC-load-misses,page-faults"
measure_everything
