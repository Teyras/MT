#!/bin/sh

n=$1
echo $n > data.$n.in
shuf -r -i 0-$((2**32)) -n $n >> data.$n.in
