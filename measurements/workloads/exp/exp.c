#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>

#include "../common.c"

#ifdef FLOAT
typedef float num_t;
#else
typedef double num_t;
#endif

num_t exp_approx(int x, int n)
{
	int i;
	num_t base = 1.0 + (num_t) x / n;
	num_t e = 1.0;

	for (i = 0; i < n; i++) {
		e *= base;
	}

	return e;
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

	fgets(line, sizeof(line), stdin);
	int iterations = atoi(line);

	int i;
	for (i = 0; i < n; i++) {
		fgets(line, sizeof(line), stdin);
		data[i] = atoi(line);
	}

	for (i = 0; i < n; i++) {
		data[i] = exp_approx(data[i], iterations);
	}
	
	for (i = 0; i < n; i++) {
		printf("%f\n", data[i]);
	}

	clock_gettime(CLOCK_REALTIME, &after_wall);
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &after_cpu);

	fprintf(stderr, "wall: ");
	print_timespec_diff(&before_wall, &after_wall, stderr);
	fprintf(stderr, "cpu:  ");
	print_timespec_diff(&before_cpu, &after_cpu, stderr);


	return 0;
}

