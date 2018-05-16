#!/bin/sh

cmd=$1
data=$2
iterations=$3

err=$(mktemp)

for i in $(seq $iterations); do
	$cmd > /dev/null < $data 2> $err
	cat $err | sed "s@^@$LABEL @"
done 2>&1

rm $err
