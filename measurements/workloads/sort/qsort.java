import java.util.Scanner;
import java.lang.management.ThreadMXBean;
import java.lang.management.ManagementFactory;

class Sort {
	private ThreadMXBean timer = ManagementFactory.getThreadMXBean();
	public void quicksort(long[] data, int offset, int count) {
		if (count < 2) {
			return;
		}

		long pivot = data[offset + count / 2];

		int i, j;
		for (i = 0, j = count - 1; ; i++, j--) {
			while (data[offset + i] < pivot) i++;
			while (data[offset + j] > pivot) j--;

			if (i >= j) {
				break;
			}

			long tmp = data[offset + i];
			data[offset + i] = data[offset + j];
			data[offset + j] = tmp;
		}

		quicksort(data, offset, i);
		quicksort(data, offset + i, count - i);
	}

	public void run() {
		long beforeCpu = timer.getCurrentThreadCpuTime();
		long beforeWall = System.nanoTime();
		long startWall = System.currentTimeMillis();

		Scanner scanner = new Scanner(System.in);
		int length = Integer.parseInt(scanner.nextLine());

		long data[] = new long[length];
		int i = 0;

		while (scanner.hasNext()) {
			data[i] = Long.parseLong(scanner.nextLine());
			i += 1;
		}

		quicksort(data, 0, length);

		for (i = 0; i < length; i++) {
			System.out.println(data[i]);
		}

		long afterCpu = timer.getCurrentThreadCpuTime();
		long afterWall = System.nanoTime();

		System.err.printf("start-wall,%.9f%n", startWall / 1e3);
		System.err.printf("cpu,%.9f%n", ((double) (afterCpu - beforeCpu)) / 1e9);
		System.err.printf("wall,%.9f%n", ((double) (afterWall - beforeWall)) / 1e9);
	}

	public static void main(String[] args) {
		Sort sort = new Sort();
		sort.run();
	}
}
