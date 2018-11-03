#!/bin/sh

workers=$1

if [ $workers -eq 1 ]; then
	echo 0
	exit
fi

top_worker=$(($(nproc --all) - 1))
step=$(((2 * $(nproc --all) + $workers - 1) / $workers))

seq 0 $step $top_worker
seq 1 $step $top_worker
