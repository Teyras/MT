#!/bin/sh

n=$1
m=$2

echo $n > data.$n_$m.in
echo $m > data.$n_$m.in

shuf -r -i 0-$(( 2 ** 32 - 1  )) -n $n | sort -n >> data.$n_$m.in
shuf -r -i 0-$(( 2 ** 32 - 1  )) -n $m >> data.$n_$m.in
