#!/bin/sh

workers=$1

top_worker=$(($(nproc --all) - 1))
step=$((2 * $(nproc --all) / $workers))

seq 0 $step $top_worker
seq 1 $step $top_worker
