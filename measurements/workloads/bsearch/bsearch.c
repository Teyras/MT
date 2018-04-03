#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

#include "../common.c"

typedef u_int32_t num_t;

size_t binsearch(num_t needle, num_t *haystack, size_t count)
{
	size_t offset = 0;

	while (count > 0) {
		size_t step = count / 2;
		if (haystack[offset + step] < needle) {
			offset += step + 1;
			count -= step + 1;
		} else {
			count = step;
		}
	}

	return offset;
}

int main(int argc, char **argv)
{
	struct timespec before_wall, after_wall, before_cpu, after_cpu;

	clock_gettime(CLOCK_REALTIME, &before_wall);
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &before_cpu);

	char line[128];

	fgets(line, sizeof(line), stdin);
	int n = atoi(line);

	fgets(line, sizeof(line), stdin);
	int m = atoi(line);

	num_t *data = malloc(n * sizeof(num_t));

	int i;
	for (i = 0; i < n; i++) {
		fgets(line, sizeof(line), stdin);
		data[i] = atol(line);
	}

	for (i = 0; i < m; i++) {
		fgets(line, sizeof(line), stdin);
		num_t needle = atol(line);
		printf("%ld\n", binsearch(needle, data, n));
	}

	clock_gettime(CLOCK_REALTIME, &after_wall);
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &after_cpu);

	fprintf(stderr, "wall: ");
	print_timespec_diff(&before_wall, &after_wall, stderr);
	fprintf(stderr, "cpu:  ");
	print_timespec_diff(&before_cpu, &after_cpu, stderr);

	return 0;
}

