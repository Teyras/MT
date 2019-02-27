#!/bin/sh

function process_opts() {
	for opt in $(echo $1 | tr "," " "); do
		echo -n "-e $opt "
	done
}

function perf_wrapper() {
	outfile=$1
	shift

	if [ -z "$PERF_OPTS" ]; then
		$@
	else
		sudo perf stat -x "," -o $outfile $(process_opts $PERF_OPTS) $@
	fi
}

function perf_print() {
	outfile=$1
	if [ -n "$PERF_OPTS" ]; then
		cat $outfile | grep -v '^#\|^\s*$' | awk -F "," '{ print $3 "," $1  }'
	fi
}
