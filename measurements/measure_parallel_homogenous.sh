#!/bin/sh

workers=$1
shift

label=$1
shift

seq 1 $workers | parallel -j$workers "./measure_workload.sh \"$label,worker-{}/$workers\" $@"
