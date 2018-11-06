#!/bin/sh

workers=$1
cpu_count=$2
core_per_cpu=$3
is_ht=$4

if [ -z "$is_ht" ]; then
	is_ht=$(cat /proc/cpuinfo | grep '^flags\s*:.*ht' | wc -l)
fi

if [ -z "$cpu_count" -o -z "$core_per_cpu" ]; then
	cpu_count=$(cat /proc/cpuinfo | grep 'physical id' | sort | uniq | wc -l)
	core_per_cpu=$(cat /proc/cpuinfo | grep 'core id' | sort | uniq | wc -l)
fi

total=$(($cpu_count * $core_per_cpu))

# If HT is available and necessary, use it
if [ "$is_ht" -gt 0 -a $workers -gt $(($cpu_count * $core_per_cpu)) ]; then
	total=$(($total * 2))
fi

if [ $workers -eq 1 ]; then
	echo 0
	exit
fi

workers_per_cpu=$(($workers / $cpu_count))
step=$(echo "scale=2; $total / $workers_per_cpu" | bc)

for i in $(seq 0 $(($cpu_count - 1))); do
	assigned=0

	for j in $(seq 0 $(($workers_per_cpu - 1))); do
		echo "scale=0; ($assigned + $i) / 1" | bc
		assigned=$(echo "scale=2; $assigned + $step" | bc)
	done
done

