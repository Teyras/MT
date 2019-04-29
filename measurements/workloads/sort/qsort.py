#!/usr/bin/env python3

import sys
import time

def quicksort(data, offset, count):
	if count < 2:
		return

	pivot = data[offset + count // 2]

	i = 0
	j = count - 1

	while True:
		while data[offset + i] < pivot:
			i += 1

		while data[offset + j] > pivot:
			j -= 1

		if i >= j:
			break

		tmp = data[offset + i]
		data[offset + i] = data[offset + j]
		data[offset + j] = tmp

		i += 1
		j -= 1
	
	quicksort(data, offset, i)
	quicksort(data, offset + i, count - i)

before_cpu = time.process_time()
before_wall = time.time()

lines = iter(sys.stdin)
length = int(next(lines))
data = []

for line in lines:
	data.append(int(line))

quicksort(data, 0, length)

for item in data:
	print(item)

after_cpu = time.process_time()
after_wall = time.time()

print(f"start-wall,{before_wall:.9f}", file=sys.stderr)
print(f"cpu,{(after_cpu - before_cpu):.9f}", file=sys.stderr)
print(f"wall,{(after_wall - before_wall):.9f}", file=sys.stderr)

