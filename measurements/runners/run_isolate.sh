#!/bin/sh

cmd=$1
data=$2
iterations=$3

if [ -z "$WORKER" ]; then
	WORKER=0
fi

META=meta-$WORKER.inf

for i in $(seq $iterations); do
	isolate -b $WORKER --cg --init > /dev/null
	isolate -b $WORKER -M $META \
		--cg --cg-timing \
		--stdout=/dev/null \
		--stderr=/box/isolate.err \
		--dir=/data=$(realpath $(dirname $cmd)) \
		--run /data/$(basename $cmd) < $data > /dev/null 2> /dev/null

	echo "${LABEL} iso-wall: $(cat $META | grep "^time-wall:" | cut -d: -f2)"
	echo "${LABEL} iso-cpu:  $(cat $META | grep "^time:" | cut -d: -f2)"

	# TODO
	if ! grep "^time" $META; then
		cat $META | sed "s@^@$LABEL@"
	fi

	isolate -b $WORKER --run /usr/bin/cat /box/isolate.err 2> /dev/null | sed "s@^@$LABEL @"
	until isolate -b $WORKER --cg --cleanup; do
		sleep 0.5
	done
done
