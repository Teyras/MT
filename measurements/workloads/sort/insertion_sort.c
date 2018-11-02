#include <stdio.h>
#include <stdlib.h>

#include "../common.c"

void insertion_sort(int *a, int n) {
	size_t i;
	for (i = 1; i < n; ++i) {
		int tmp = a[i];
		size_t j = i;
		while(j > 0 && tmp < a[j - 1]) {
			a[j] = a[j - 1];
			--j;
		}
		a[j] = tmp;
	}
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

	insertion_sort(data, n);
	
	for (i = 0; i < n; i++) {
		printf("%d\n", data[i]);
	}

	clock_gettime(CLOCK_REALTIME, &after_wall);
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &after_cpu);

	print_timespec(&before_wall, stderr, "start-wall");
	print_timespec_diff(&before_wall, &after_wall, stderr, "wall");
	print_timespec_diff(&before_cpu, &after_cpu, stderr, "cpu");

	return 0;
}

