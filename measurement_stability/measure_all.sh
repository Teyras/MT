#!/bin/sh

trap "exit" INT

root=$(dirname $(realpath $0))
export MEASUREMENTS_ROOT=$root

if [ "$1" = "--noht" ]; then
	ht_setup="-noht"
	ht_flag="--noht"
	shift
fi

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
			LABEL=bare,$setup-taskset$ht_setup eval $wrapper_cmd --taskset $worker_count ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=isolate,$setup-taskset$ht_setup eval $wrapper_cmd --taskset $worker_count ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file
			LABEL=docker-bare,$setup-taskset$ht_setup eval $wrapper_cmd --taskset $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=docker-isolate,$setup-taskset$ht_setup eval $wrapper_cmd --taskset $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file
		elif [ "$mode" = "--taskset-multi" ]; then
			LABEL=bare,$setup-taskset-multi$ht_setup eval $wrapper_cmd --taskset-multi $worker_count ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=isolate,$setup-taskset-multi$ht_setup eval $wrapper_cmd --taskset-multi $worker_count ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file
			LABEL=docker-bare,$setup-taskset-multi$ht_setup eval $wrapper_cmd --taskset-multi $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=docker-isolate,$setup-taskset-multi$ht_setup eval $wrapper_cmd --taskset-multi $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file
		elif [ "$mode" = "--numa" ]; then
			LABEL=bare,$setup-numa$ht_setup eval $wrapper_cmd --numa $worker_count ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=isolate,$setup-numa$ht_setup eval $wrapper_cmd --numa $worker_count ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file
			LABEL=docker-bare,$setup-numa$ht_setup eval $wrapper_cmd --numa $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=docker-isolate,$setup-numa$ht_setup eval $wrapper_cmd --numa $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file
		else
			LABEL=bare,$setup$ht_setup eval $wrapper_cmd $worker_count ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=isolate,$setup$ht_setup eval $wrapper_cmd $worker_count ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file
			LABEL=docker-bare,$setup$ht_setup eval $wrapper_cmd $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file
			LABEL=docker-isolate,$setup$ht_setup eval $wrapper_cmd $worker_count ./run_docker.sh ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file

			if [ "$worker_count" -le 20 ]; then
				./start_vbox.sh $worker_count > /dev/null 2>&1
				LABEL=vbox-bare,$setup$ht_setup eval $wrapper_cmd $worker_count $root/run_vbox.sh ./measure_workload.sh \
					runners/run_baremetal.sh $workload $size $iters >> $results_file < /dev/null
				LABEL=vbox-isolate,$setup$ht_setup eval $wrapper_cmd $worker_count $root/run_vbox.sh ./measure_workload.sh \
					runners/run_isolate.sh $workload $size $iters >> $results_file < /dev/null
				./stop_vbox.sh > /dev/null 2>&1
			fi
		fi
	done
}

function measure_everything() {
	# Measure on a single core
	measure_each_isolation "single" 1 $root/measure_single.sh

	if [ "$ht_setup" = "-noht" ]; then
		worker_config="2 4 6 8 10 20"
		worker_config_short="2 4 6 8 10"
	else
		workers_config="2 4 6 8 10 20 40"
		workers_config_short="2 4 6 8 10 20"
	fi

	# Measure a workload under multiple levels of CPU stress
	for workers in $worker_config; do
		measure_each_isolation "parallel-synth-cpu" $workers "$root/measure_parallel_synth_stress.sh \"--cpu 1\"" $ht_flag
		measure_each_isolation "parallel-synth-cpu" $workers "$root/measure_parallel_synth_stress.sh \"--cpu 1\"" --taskset $ht_flag
		measure_each_isolation "parallel-synth-cpu" $workers "$root/measure_parallel_synth_stress.sh \"--cpu 1\"" --numa $ht_flag
	done

	for workers in $worker_config_short; do
		measure_each_isolation "parallel-synth-cpu" $workers "$root/measure_parallel_synth_stress.sh \"--cpu 1\"" --taskset-multi $ht_flag
	done

	# Measure a workload under multiple levels of memory copying stress
	for workers in $worker_config; do
		measure_each_isolation "parallel-synth-memcpy" $workers "$root/measure_parallel_synth_stress.sh \"--memcpy 1\"" $ht_flag
		measure_each_isolation "parallel-synth-memcpy" $workers "$root/measure_parallel_synth_stress.sh \"--memcpy 1\"" --taskset $ht_flag
		measure_each_isolation "parallel-synth-memcpy" $workers "$root/measure_parallel_synth_stress.sh \"--memcpy 1\"" --numa $ht_flag
	done

	for workers in $worker_config_short; do
		measure_each_isolation "parallel-synth-memcpy" $workers "$root/measure_parallel_synth_stress.sh \"--memcpy 1\"" --taskset-multi $ht_flag
	done

	# Measure the same workload on multiple cores at once
	for workers in $worker_config; do
		measure_each_isolation "parallel-homogenous" $workers $root/measure_parallel_homogenous.sh $ht_flag
		measure_each_isolation "parallel-homogenous" $workers $root/measure_parallel_homogenous.sh --taskset $ht_flag
		measure_each_isolation "parallel-homogenous" $workers $root/measure_parallel_homogenous.sh --numa $ht_flag
	done

	for workers in $worker_config_short; do
		measure_each_isolation "parallel-homogenous" $workers $root/measure_parallel_homogenous.sh --taskset-multi $ht_flag
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
