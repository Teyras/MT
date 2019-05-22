#!/bin/sh

if [ "$1" = "--multi" ]; then
	multi=1
	shift
fi

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
	if [ -n "$multi" ]; then
		if [ "$is_ht" -gt 0 ]; then
			echo 0-$(($cpu_count * $core_per_cpu * 2))
		else
			echo 0-$(($cpu_count * $core_per_cpu))
		fi
	else
		echo 0
	fi

	exit
fi

workers_per_cpu=$(($workers / $cpu_count))
step=$(echo "scale=2; $total / $workers_per_cpu" | bc)

if [ -n "$multi" ]; then
	cpus_per_worker=$(($total / $workers))
	for cpu_index in $(seq 0 $(($cpu_count - 1))); do
		assigned=0

		for j in $(seq 0 $(($workers_per_cpu - 1))); do
			for k in $(seq 0 $(($cpus_per_worker - 1))); do
				if [ "$k" -gt 0 ]; then
					echo -n ,
				fi
				echo -n "$(echo "scale=0; ($assigned + $cpu_index + 2 * $k) / 1" | bc)"
				echo -n ",$(echo "scale=0; ($assigned + $cpu_index + 2 * $k + $cpu_count * $core_per_cpu) / 1" | bc)"
			done
			echo

			assigned=$(echo "scale=2; $assigned + $step" | bc)
		done
	done
else
	for cpu_index in $(seq 0 $(($cpu_count - 1))); do
		assigned=0

		for j in $(seq 0 $(($workers_per_cpu - 1))); do
			echo "scale=0; ($assigned + $cpu_index) / 1" | bc
			assigned=$(echo "scale=2; $assigned + $step" | bc)
		done
	done
fi

