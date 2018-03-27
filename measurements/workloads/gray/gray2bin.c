#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

#include "../common.c"

typedef u_int32_t num_t;

num_t gray2bin(num_t num)
{
	num_t mask = num;

	while (mask != 0) {
		mask = mask >> 1;
		num = num ^ mask;
	}

	return num;
}

int main(int argc, char **argv)
{
	struct timespec before_wall, after_wall, before_cpu, after_cpu;

	clock_gettime(CLOCK_REALTIME, &before_wall);
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &before_cpu);

	char line[128];
	fgets(line, sizeof(line), stdin);

	int n = atoi(line);
	num_t *data = malloc(n * sizeof(num_t));

	int i;
	for (i = 0; i < n; i++) {
		fgets(line, sizeof(line), stdin);
		data[i] = atoi(line);
	}

	for (i = 0; i < n; i++) {
		data[i] = gray2bin(data[i]);
	}
	
	for (i = 0; i < n; i++) {
		printf("%u\n", data[i]);
	}

	clock_gettime(CLOCK_REALTIME, &after_wall);
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &after_cpu);

	fprintf(stderr, "wall: ");
	print_timespec_diff(&before_wall, &after_wall, stderr);
	fprintf(stderr, "cpu:  ");
	print_timespec_diff(&before_cpu, &after_cpu, stderr);


	return 0;
}

