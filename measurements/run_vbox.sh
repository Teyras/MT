#!/bin/sh

function run_vagrant() {
	VAGRANT_CWD=$(dirname $0)/vagrant/vbox_multi vagrant "$@"
}

if [ -z "$WORKER" ]; then
	WORKER=0
fi

run_vagrant up vbox_$WORKER > /dev/null 2> /dev/null

run_vagrant ssh vbox_$WORKER -- "cd /measurements && LABEL=\"${LABEL}\" $@"

run_vagrant halt vbox_$WORKER > /dev/null 2> /dev/null
