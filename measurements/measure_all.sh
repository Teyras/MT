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

# Measure on a single core
cat $workloads | while read workload size iters; do
	echo ">>> $workload $size $iters (single)"

	LABEL="bare,single,1,cpu-0" $root/measure_workload.sh \
		runners/run_baremetal.sh $workload $size $iters >> $results_file

	LABEL="isolate,single,1,cpu-0" $root/measure_workload.sh \
		runners/run_isolate.sh $workload $size $iters >> $results_file

	LABEL="docker-bare,single,1,cpu-0" $root/run_docker.sh ./measure_workload.sh \
		runners/run_baremetal.sh $workload $size $iters >> $results_file

	LABEL="docker-isolate,single,1,cpu-0" $root/run_docker.sh ./measure_workload.sh \
		runners/run_isolate.sh $workload $size $iters >> $results_file
	
	./start_vbox.sh 1
	LABEL="vbox-bare,single,1,cpu-0" $root/run_vbox.sh ./measure_workload.sh \
		runners/run_baremetal.sh $workload $size $iters >> $results_file < /dev/null

	LABEL="vbox-isolate,single,1,cpu-0" $root/run_vbox.sh ./measure_workload.sh \
		runners/run_isolate.sh $workload $size $iters >> $results_file < /dev/null
	./stop_vbox.sh
done

# Measure the same workload on multiple cores at once
for workers in 2 4 6 8 10 20 40; do
#for workers in 2; do
	cat $workloads | while read workload size iters; do
		echo ">>> $workload $size $iters ($workers workers, parallel-homogenous)"

		LABEL="bare,parallel-homogenous" $root/measure_parallel_homogenous.sh $workers ./measure_workload.sh \
			runners/run_baremetal.sh $workload $size $iters >> $results_file
		LABEL="isolate,parallel-homogenous" $root/measure_parallel_homogenous.sh $workers ./measure_workload.sh \
			runners/run_isolate.sh $workload $size $iters >> $results_file
		LABEL="docker-bare,parallel-homogenous" $root/measure_parallel_homogenous.sh $workers ./run_docker.sh ./measure_workload.sh \
			runners/run_baremetal.sh $workload $size $iters >> $results_file
		LABEL="docker-isolate,parallel-homogenous" $root/measure_parallel_homogenous.sh $workers ./run_docker.sh ./measure_workload.sh \
			runners/run_isolate.sh $workload $size $iters >> $results_file

		if [ "$workers" -le 20 ]; then
			./start_vbox.sh $workers
			LABEL="vbox-bare,parallel-homogenous" $root/measure_parallel_homogenous.sh $workers $root/run_vbox.sh ./measure_workload.sh \
				runners/run_baremetal.sh $workload $size $iters >> $results_file < /dev/null
			LABEL="vbox-isolate,parallel-homogenous" $root/measure_parallel_homogenous.sh $workers $root/run_vbox.sh ./measure_workload.sh \
				runners/run_isolate.sh $workload $size $iters >> $results_file < /dev/null
			./stop_vbox.sh
		fi

		LABEL="bare,parallel-homogenous-taskset" $root/measure_parallel_homogenous.sh --taskset $workers ./measure_workload.sh \
			runners/run_baremetal.sh $workload $size $iters >> $results_file
		LABEL="isolate,parallel-homogenous-taskset" $root/measure_parallel_homogenous.sh --taskset $workers ./measure_workload.sh \
			runners/run_isolate.sh $workload $size $iters >> $results_file
		LABEL="docker-bare,parallel-homogenous-taskset" $root/measure_parallel_homogenous.sh --taskset $workers ./run_docker.sh ./measure_workload.sh \
			runners/run_baremetal.sh $workload $size $iters >> $results_file
		LABEL="docker-isolate,parallel-homogenous-taskset" $root/measure_parallel_homogenous.sh --taskset $workers ./run_docker.sh ./measure_workload.sh \
			runners/run_isolate.sh $workload $size $iters >> $results_file
	done
done
