#include <stdio.h>
#include <stdlib.h>

#include "../common.c"

void bubble_sort(int *a, int n)
{
	int i, t, s = 1;
	while (s) {
		s = 0;
		for (i = 1; i < n; i++) {
			if (a[i] < a[i - 1]) {
				t = a[i];
				a[i] = a[i - 1];
				a[i - 1] = t;
				s = 1;
			}
		}
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

	bubble_sort(data, n);
	
	for (i = 0; i < n; i++) {
		printf("%d\n", data[i]);
	}

	clock_gettime(CLOCK_REALTIME, &after_wall);
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &after_cpu);

	fprintf(stderr, "wall: ");
	print_timespec_diff(&before_wall, &after_wall, stderr);
	fprintf(stderr, "cpu:  ");
	print_timespec_diff(&before_cpu, &after_cpu, stderr);

	return 0;
}

