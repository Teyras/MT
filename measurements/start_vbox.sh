#!/bin/sh
dir=$(realpath .)
n=$1

for i in $($dir/distribute_workers.sh $n); do
	while true; do
		if VAGRANT_CWD=$dir/vagrant/vbox_multi vagrant up vbox_$i; then
			break
		fi
	done
done

