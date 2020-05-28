#include <stdio.h>
#include <stdlib.h>

#include "../common.c"

int cmp (const void * a, const void * b)
{
	return ( *(int*)a - *(int*)b );
}

int main(int argc, char **argv)
{
	struct timespec before_wall, after_wall, before_cpu, after_cpu;

	clock_gettime(CLOCK_REALTIME, &before_wall);
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &before_cpu);

	char line[128];
	fgets(line, sizeof(line), stdin);

	int n = atoi(line);
	int *data = malloc(n * sizeof(int));

	int i;
	for (i = 0; i < n; i++) {
		fgets(line, sizeof(line), stdin);
		data[i] = atoi(line);
	}

	qsort(data, n, sizeof(int), cmp);
	
	for (i = 0; i < n; i++) {
		printf("%d\n", data[i]);
	}

	clock_gettime(CLOCK_REALTIME, &after_wall);
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &after_cpu);

	print_timespec_diff(&before_wall, &after_wall, stderr, "wall");
	print_timespec_diff(&before_cpu, &after_cpu, stderr, "cpu");


	return 0;
}

