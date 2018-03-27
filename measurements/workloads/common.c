#include <time.h>

void timespec_diff(struct timespec *start, struct timespec *stop,
                   struct timespec *result)
{
	if ((stop->tv_nsec - start->tv_nsec) < 0) {
		result->tv_sec = stop->tv_sec - start->tv_sec - 1;
		result->tv_nsec = stop->tv_nsec - start->tv_nsec + 1000000000;
	} else {
		result->tv_sec = stop->tv_sec - start->tv_sec;
		result->tv_nsec = stop->tv_nsec - start->tv_nsec;
	}

	return;
}

void print_timespec_diff(struct timespec *start, struct timespec *stop, FILE *fd)
{
	struct timespec result;
	timespec_diff(start, stop, &result);
	fprintf(fd, "%zu.%09zu\n", result.tv_sec, result.tv_nsec);
}

