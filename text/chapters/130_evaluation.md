## Result Analysis

### Evaluation of Isolate Measurements

As mentioned before, our measurements that run in isolate yield four values: the 
cpu and wall clock times as measured by isolate and by the program itself. It is 
safe to assume that there will be some discrepancies between the results from 
isolate and from the program -- isolate also takes into account the time it 
takes to load the binary and start the process while the instrumented 
measurements start when everything is ready. However, this does not concern us 
too much as long as the error is stable -- in ReCodEx, we only observe the 
values reported by isolate.

To examine the stability of the deviations, we calculated the standard deviation 
of the difference between the results from isolate and those from the program in 
every iteration of the measurement for every workload and setup. We then 
normalized this number by dividing it with the mean of the runtime to obtain a 
relative error measure.

The error is rather small and stable for the CPU times (generally in the order 
of milliseconds, the relative error does not exceed 0.2%) -- see Table 
\ref{iso-cpu-err}. This result is not surprising -- starting a process is 
generally not a particularly CPU-intensive task. Measurements of the quicksort 
workload in Python are an exception -- sometimes, the difference in CPU time 
measurements is as high as 200 milliseconds. We can attribute this difference to 
the work required before even starting a Python script. Thankfully, even this 
difference seems to remain fairly stable in the setups where it manifests.
All in all, we can see that the CPU time measured by isolate is fairly reliable.

On the other hand, we found that the wall-clock time error tends to vary a lot 
(see Table \ref{iso-wall-err}). This is most prominent when a high number of 
parallel workers is involved (20-40) -- the relative error goes as high as 150%. 
Smaller values of the relative error (over 5%) start to manifest with as little 
as six parallel workers. This means that there is a large offset between the 
wall-clock time measured by isolate and the value measured by the programs 
themselves. Also, this offset tends to vary a lot in many cases.

We found no obvious link between the value of the relative wall-clock time error 
and the isolation technology in use -- both docker+isolate and isolate on its 
own tend to have largely varying measurement errors. VirtualBox might seem to be 
more stable at first glance because we are missing data for larger amounts of 
parallel workers.

The instability of the error is possibly caused by the overhead of starting new 
processes. This overhead grows larger when we need to start many processes at 
once and both the file system and memory get stressed.

!include tables/stability/iso-cpu-err.md

!include tables/stability/iso-wall-err.md

### Comparison of Measurement Stability

To visualize the effects of isolation technologies, we made scatter plots of CPU 
time (we chose not to examine the wall-clock time because it seems that isolate 
cannot measure it reliably) measurements for each system load level, workload 
and isolation technology so that the plots for each isolation technology are 
side by side for every workload. Because most of the measurements were made in 
parallel, we colorized the measurements from one chosen worker process so that 
we could get an idea about how the measurements differ between the parallel 
workers. The plots revealed a handful of possible trends in the measured data. A 
selection from these plots can be seen in Figure \ref{isolation-comparison}.

<!-- TODO compare SD of bare, docker and vbox -->

![A scatter plot of time measurements grouped by isolation for chosen setups and 
workloads with results from a single worker highlighted in red 
\label{isolation-comparison}](img/stability/isolation-comparison.png)

The most prominent trend is that the measured values are centered around 
different points under different isolation technologies for some workloads.

For example, an iteration of the `bsearch` and `exp_float` workloads tends to 
take about 25-50ms more on the bare metal or in Docker than in VirtualBox. This 
trend is most apparent with four or more workers running in parallel.

Also, there is a cca. 50ms difference between the `isolate` and `docker-bare` 
setups, which is rather strange because both of these technologies use the same 
kernel facilities to achieve isolation.

To examine the first observation in a more formal way, we compared bootstrapped 
0.95 confidence intervals of the mean for the `bare`, `docker-bare` and 
`vbox-bare` isolation setups. As shown by Table \ref{mean-ci-comparison}, the 
comparison confirmed our observation for lower degrees of parallelism. However, 
we could not reproduce the result under either of the synthetic system load 
setups.

!include tables/stability/mean-ci-comparison.md

TODO second observation

TODO try to extend this to other workloads

As to the stability of measurements, it appears that when a single process is 
running, the measured times do not vary a lot for any of the isolation 
techniques. However, with as little as two workers running in parallel, we start 
noticing a decline in stability for the `isolate` and `docker-isolate` isolation 
setups (compared to their counterparts without isolate) in the `exp`, `bsearch` 
and `insertion_sort` workloads.

This decline in stability in setups with isolate only becomes more apparent 
under higher levels of system load. With 10 workers, measurements in isolate 
seem less stable for all of the workloads. An interesting observation is that 
the `vbox` and `vbox-isolate` setups seem to remain stable under high loads 
(compared to other setups).

A comparison of bootstrapped 0.95 confidence intervals of the standard deviation 
(see Table \ref{sd-ci-comparison}) confirmed most of our observations. We did 
not manage to prove that the measurements in isolate are less stable when a 
single process is running. With two processes running in parallel, the 
measurements done in isolate seem to have a higher standard deviation on the 
bare metal and in Docker for the `exp` and `insertion_sort` workloads (we are 
not certain about `bsearch`). When ten processes are running at once, the 
standard deviation is higher in isolate for all workloads except `bsearch`. The 
observation about `vbox-isolate` seeming to remain as stable as `vbox` under 
high loads is reflected by the fact that there are few cases when the standard 
deviation is clearly higher and the comparison is inconclusive most of the time.
Interestingly, we got similar results for both of our synthetic load setups.

!include tables/stability/sd-ci-comparison.md

TODO the wall-clock time measurements in VirtualBox seems to have the largest 
outliers.

TODO try to use data from perf to explain stuff

### Validation of Parallel Worker Results

For the homogenus parallel setup, we needed to make sure that our measurements 
did actually run in parallel. We calculated the total runtime for all the 
measurements (the difference between the timestamps of the first and last 
measured results, regardless of the worker) and the time when all the worker 
processes ran in parallel (the difference between the timestamps of the last 
received result of a first iteration and the first received result of a last 
iteration). We then inspected the ratio of these two numbers.

As we can see in Table \ref{parallel-run-ratios}, this ratio is 68% in one case 
and higher than 90% most of the time. This should guarantee that the
homogenous parallel measurements are not in fact a sequence of sequential 
workloads and their results are similar to actual parallel measurements.

!include tables/stability/parallel-run-ratios.md

### Comparing Parallel Worker Results

When examining how raising the system load affects the stability of 
measurements, we discovered several interesting trends.

First, the execution times seem to be higher under higher system loads for some 
workloads. For example, in Figure \ref{isolation-comparison}, we can see that a 
`bsearch` iteration normally takes about 0.35 seconds on the bare metal with a 
single process and 0.4-0.45s when 10 processes are running in parallel. On the 
other hand, the difference is much smaller for `exp_float`. This could be due to 
the parallel workers competing for the last-level cache -- this would affect 
memory-bound tasks more than it would affect CPU-bound tasks.

TODO use data from perf here

Second, the measurements from different worker processes seem to be centered 
around different values. For an example of this, see the `exp_float` workload on 
4 workers in Figure \ref{isolation-comparison} (`bare` and `docker-bare`). This 
is also more notable under higher system loads.

TODO outdated: Third, for some measurements, the results are stable most of the 
time and start decreasing quickly in the last few iterations (e.g. `bsearch` on 
bare metal with 10 workers in Figure \ref{isolation-comparison}). This is due to 
the fact that the parallel workers do not always all finish at the same time and 
the last iterations are performed under a smaller system load.

A conclusion follows from our observations: we cannot allow a number of parallel 
workers that is so high that any of these effects manifests. Otherwise, we risk 
that our measurements will become too unstable. 

TODO it looks like VirtualBox is doing a little better

TODO find how much does the mean (median?) shift with increasing setup size

### The Effects of Explicit Affinity Settings

![A scatter plot of time measurements with fixed CPU affinities grouped by 
isolation for chosen setups and workloads with points color-coded by parallel 
worker 
\label{isolation-comparison-taskset}](img/stability/isolation-comparison-taskset.png)

Process schedulers in modern operating systems for multi-CPU systems are complex
software that relies on sophisticated algorithms. Trying to bypass the scheduler
by pinning worker processes to CPUs with taskset would not be generally
recommended. However, schedulers are typically not concerned with measurement
stability when they assign processes to CPU cores, so it makes sense to examine
the effects of setting the CPU affinity explicitly.

TODO some citation would be lovely here

As seen in Figure \ref{isolation-comparison-taskset}, the results of 
measurements with taskset are very similar to those without explicit CPU 
affinity settings. It seems that when a worker is pinned to a chosen core, its 
measurements appear more stable -- see for example the plot for `exp_float` with 
4 workers in `docker-bare` and compare it with its counterpart without taskset.

However, this alone does not help remedy the issues outlined in the previous 
section. In real-world scenarios, we have to consider the measurements from all 
the workers, because a repeated measurement of a submission could be assigned to 
any worker.

For a better insight into the effects of CPU affinity settings, we compared the 
means and standard deviations of results grouped by workload, isolation and 
parallel setup, with and without affinity settings. We performed the comparison 
using confidence intervals obtained from a bootstrap procedure.

In Figure \ref{taskset-comparison}, we can see that the comparison does not seem 
to yield any definite results for the mean, but the standard deviation is higher 
for the measurements with explicit affinity settings for about two thirds of the 
groups. Unfortunately, this means that using taskset is detrimental to the 
stability of the measurements.

![A plot showing the results of a comparison between mean and standard deviation 
values for measurement with and without taskset 
\label{taskset-comparison}](img/stability/taskset-comparison.png)

TODO examine numa affinity settings

