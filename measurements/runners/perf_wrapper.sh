#!/bin/sh

function perf_wrapper() {
	outfile=$1
	shift

	if [ -z "$PERF_OPTS" ]; then
		$@
	else
		# TODO use opts
		perf stat -x "," -o $outfile \
			-e L1-dcache-loads \
			-e L1-dcache-load-misses \
			-e LLC-stores \
			-e LLC-store-misses \
			-e LLC-loads \
			-e LLC-load-misses \
			-e page-faults \
			$@
		#cat $outfile >&2
		cat $outfile | grep -v '^#\|^\s*$' | awk -F "," '{ print $3 "," $1  }' >&2
	fi
}
