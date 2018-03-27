#include <stdio.h>
#include <stdlib.h>

#include "../common.c"

void quicksort(int *A, int len)
{
	if (len < 2) return;
 
	int pivot = A[len / 2];
 
	int i, j;
	for (i = 0, j = len - 1; ; i++, j--) {
		while (A[i] < pivot) i++;
		while (A[j] > pivot) j--;
 
		if (i >= j) break;
 
		int temp = A[i];
		A[i]		 = A[j];
		A[j]		 = temp;
	}
 
	quicksort(A, i);
	quicksort(A + i, len - i);
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

	quicksort(data, n);
	
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

