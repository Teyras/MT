#!/bin/sh

function run_vagrant() {
	VAGRANT_CWD=$(dirname $0)/vagrant/vbox_multi vagrant "$@"
}

if [ -z "$WORKER" ]; then
	WORKER=0
fi

if [ -n "$PERF_OPTS" ]; then
	PERF_ENV="PERF_OPTS=\"${PERF_OPTS}\""
fi

run_vagrant ssh vbox_$WORKER -- "cd /measurements && LABEL=\"${LABEL}\" $PERF_ENV $@"
