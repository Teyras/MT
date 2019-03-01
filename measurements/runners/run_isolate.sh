#!/bin/sh
source $(dirname $0)/perf_wrapper.sh

cmd=$1
data=$2
iterations=$3

if [ -z "$WORKER" ]; then
	WORKER=0
fi

META=meta-$WORKER.inf

perf=$(mktemp)

for i in $(seq $iterations); do
	isolate -b $WORKER --cg --init > /dev/null
	
	# The --processes option is to prevent "resource temporarily unavailable" errors from execve
	perf_wrapper $perf isolate -b $WORKER -M $META \
		--cg --cg-timing \
		--processes=999999 \
		--stdout=/dev/null \
		--stderr=/box/isolate.err \
		--dir=/data=$(realpath $(dirname $cmd)) \
		--run /data/$(basename $cmd) < $data > /dev/null 2>&1

	echo "${LABEL},${i},iso-wall,$(cat $META | grep "^time-wall:" | cut -d: -f2)"
	echo "${LABEL},${i},iso-cpu,$(cat $META | grep "^time:" | cut -d: -f2)"
	echo "${LABEL},${i},iso-mem,$(cat $META | grep "^cg-mem:" | cut -d: -f2)"

	isolate -b $WORKER --processes=999999 --run /usr/bin/cat /box/isolate.err 2> /dev/null | sed "s@^@$LABEL,${i},@"

	perf_print $perf | sed "s@^@$LABEL,${i},@"

	attempt=0
	until isolate -b $WORKER --cg --cleanup || test $attempt -ge 5; do
		attempt=$(($attempt + 1))
		sleep 0.5
	done
done

rm $perf
