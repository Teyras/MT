#!/bin/sh

n=$(echo $1 | cut -d "_" -f 1)
m=$(echo $1 | cut -d "_" -f 2)

echo $n > data.${n}_${m}.in
echo $m > data.${n}_${m}.in

shuf -r -i 0-$(( 2 ** 32 - 1  )) -n $n | sort -n >> data.${n}_${m}.in
shuf -r -i 0-$(( 2 ** 32 - 1  )) -n $m >> data.${n}_${m}.in
