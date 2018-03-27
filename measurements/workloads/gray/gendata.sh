#!/bin/sh

n=$1
echo $1 > data.$n.in
shuf -r -i 0-$(( 2 ** 32 - 1  )) -n $n >> data.$n.in
