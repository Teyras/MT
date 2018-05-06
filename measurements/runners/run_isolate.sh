#!/bin/sh

cmd=$1
data=$2
iterations=$3
label=$4

META=meta.inf

for i in $(seq $iterations); do
	isolate --cg --init > /dev/null
	isolate -M $META \
		--cg --cg-timing \
		--stdout=/dev/null \
		--stderr=/box/isolate.err \
		--dir=/data=$(realpath $(dirname $cmd)) \
		--run /data/$(basename $cmd) < $data > /dev/null 2> /dev/null

	echo -n "${label} iso-wall: "
	cat $META | grep "^time-wall:" | cut -d: -f2

	echo -n "${label} iso-cpu:  "
	cat $META | grep "^time:" | cut -d: -f2

	isolate --run /usr/bin/cat /box/isolate.err 2> /dev/null | sed "s@^@$label @"
	isolate --cg --cleanup
done
