#!/bin/sh

n=$1
echo $1 > data.$n.in
echo 1024 >> data.$n.in
shuf -r -i 0-32 -n $n >> data.$n.in
