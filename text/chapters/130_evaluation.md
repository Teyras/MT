## Result Analysis

### Evaluation of Isolate Measurements

As mentioned in Section \ref{measured-data}, our measurements that run in 
isolate yield four values: the CPU and wall clock times as measured by isolate 
and by the program itself. It is safe to assume that there will be some 
discrepancies between the results from isolate and from the program -- isolate 
also takes into account the time it takes to load the binary and start the 
process, as opposed to the instrumented measurements start when everything is 
ready. However, since we only observe the values reported by isolate in ReCodEx, 
this does not concern us as long as the error is deterministic (i.e., it stays 
the same in repeated measurements). Additionally, if the error was 
deterministic, but larger than the runtime of the program itself, it would be 
more difficult to recognize inefficient solutions.

To examine this, we took the results of measurements with the 
`parallel-homogeneous` execution setup type and made a correlation plot of times 
reported by the program itself and by isolate for each exercise type and both 
CPU and wall-clock time measurements. There is a problem with the interpretation 
of these plots -- execution setups with many parallel workers yield more 
observations in total. Therefore, the results from highly parallelized execution 
setups are more prominent in the correlation plots. To alleviate this, we 
plotted a random sample from the observations using the inverse of the number of 
parallel workers as a weight for each observation (e.g., an observation from a 
setup with 40 workers has a weight of $\frac{1}{40}$ and is therefore less 
likely to be selected than an observation from a setup with 10 workers which has 
a weight of $\frac{1}{10}$).

As depicted in Figure \ref{iso-cpu-err-correlation}, the error is rather small 
and stable for the CPU times. This result is not surprising -- starting a 
process is generally not a CPU-intensive task. Measurements of the quicksort 
workload in Java are an exception -- the times measured by isolate were twice as 
long in almost every iteration. Also, the results seem less stable when the 
execution time is longer. We can attribute this difference to the work required 
to launch the JVM. Still, the measurements for all the other exercise types seem 
fairly reliable.

On the other hand, we found that the wall-clock time error tends to vary a lot 
(Figure \ref{iso-wall-err-correlation}). To find out if there is a correlation 
between the exercise type, isolation technology or system load level and the 
error rate, we calculated the mean and standard deviation of the difference 
between the times measured by the program and by isolate for each iteration and 
grouped them by exercise type, isolation, execution setup type and load level. 
We also normalized the standard deviation by dividing it by the mean of the 
runtime to obtain a relative error measure. The results can be seen in 
Attachment \ref{attachment-errors}.

We found that the instability in wall-clock time measurements is most prominent 
when a high number of parallel workers is involved (20-40) -- the relative error 
goes as high as 196%. Smaller values of the relative error (over 5%) start to 
manifest with as little as six parallel workers. This means that there is a 
large offset between the wall-clock time measured by isolate and the value 
measured by the programs themselves. Also, this offset tends to vary a lot in 
many cases.

We found no obvious link between the value of the relative wall-clock time error 
and the isolation technology in use -- both docker+isolate and isolate on its 
own tend to have largely varying measurement errors. VirtualBox might seem to be 
more stable at first glance because we are missing data for larger amounts of 
parallel workers.

The instability of the error is possibly caused by the overhead of starting new 
processes. This overhead grows larger when we need to start many processes at 
once and both the file system and memory get stressed.

![A correlation plot of CPU time reported by the measured program and by 
isolate, with $y=x$ as a reference line
\label{iso-cpu-err-correlation}](img/stability/iso-cpu-err.tex)

![A correlation plot of wall-clock time reported by the measured program and by 
isolate, with $y=x$ as a reference line
\label{iso-wall-err-correlation}](img/stability/iso-wall-err.tex)

### Method of Comparison

In the following sections, we will need to compare groups of measurements made 
under different conditions (e.g. with CPU affinity settings or under varying 
degrees of system load). We cannot make assumptions about the distribution of 
the data, which disqualifies well-known tests such as the pairwise t-test, which 
requires normally distributed data. 

Our approach is to compare confidence intervals of characteristics (such as the 
mean or standard deviation) of the different groups. When the confidence 
intervals of a characteristic do not overlap for a pair of groups, we can 
conclude that the characteristic differs for the groups. When one of the 
intervals engulfs the other, the characteristic is probably the same. When the 
intervals overlap, we cannot conclude anything.

We obtain the confidence interval using the Bootstrap method[@Bootstrap], which 
is a resampling method that does not rely on any particular distribution of the 
data. The core idea is that we take random samples of our measurements 
repeatedly (1000 times in our case), calculating the statistic whose confidence 
interval we are trying to estimate in each iteration. This way, we get a set of 
observations of our statistic. Then, we select the 0.05-th and 0.95-th 
percentile to receive a 0.95 confidence interval. The implementation we use is 
provided by the `boot` package for the R statistic toolkit.

### Isolation and Measurement Stability

To visualize the effects of isolation technologies, we made scatter plots of CPU 
time (we chose not to examine the wall-clock time because it seems that isolate 
cannot measure it reliably) measurements for each system load level, exercise 
type and isolation technology so that the plots for each isolation technology 
are side by side for every exercise type. Because most of the measurements were 
made in parallel, we colorized the measurements from one chosen worker process 
so that we could get an idea about how the measurements differ between the 
parallel workers. The plots revealed a handful of possible trends in the 
measured data. A selection from these plots can be seen in Figure 
\ref{isolation-comparison}.

![A scatter plot of time measurements grouped by isolation for chosen setups and 
exercise types with results from a single worker highlighted in red 
\label{isolation-comparison}](img/stability/isolation-comparison.png)

The most prominent trend is that the measured values are centered around 
different means under different isolation technologies for some exercise types.

For example, an iteration of the `bsearch` and `exp_float` workloads tends to 
take about 25-50ms more on the bare metal or in Docker than in VirtualBox. This 
trend is most apparent with four or more workers running in parallel.

Also, there is a cca. 50ms difference between the `I` and `D` (and also between 
`I` and `B`) setups on a single worker, which is rather strange because both of 
these technologies use the same kernel facilities to achieve isolation.

To examine the first observation in a more formal way, we compared 0.95 
confidence intervals of the mean and standard deviation for the `bare`, 
`docker-bare` and `vbox-bare` isolation setups. The comparison was performed 
separately for each execution setup type and system load level and exercise 
type. As shown by Figure \ref{virt-ci-comparison}, the comparison of the means 
confirmed our observation -- measurements in VirtualBox often yield lower times 
than in Docker and on the bare metal. Measurements in Docker also yield lower 
times than on the bare metal most of the time. The comparison of the standard 
deviations suggests that measurements in VirtualBox are more stable than those 
on the bare metal and in Docker and that there are no notable differences in 
stability between Docker and the bare metal.

We assessed the effect of adding Isolate to a setup in a similar way -- we 
grouped the measurements by execution setup type and system load level, 
isolation technology and exercise type and compared confidence intervals of the 
mean and standard deviation among groups of measurements with and without 
Isolate. The results of this comparison (Figure \ref{isolate-ci-comparison}) 
show that measurements with Isolate are generally slower (exhibit a higher mean) 
on the bare metal and with Docker. In VirtualBox, adding Isolate does not seem 
to influence the mean in any obvious way.

However, we found that the addition of Isolate reduces the standard deviation of 
measurement in many cases. This trend is most prevalent on the bare metal, but 
it does also manifest in Docker. In VirtualBox, it is safer to conclude that the 
standard deviation remains the same.

![Results of comparisons of confidence intervals of means and standard 
deviations among various measurement groups, divided by isolation technology
\label{virt-ci-comparison}](img/stability/virt-ci-comparison.tex)

![Results of comparisons of confidence intervals of means and standard 
deviations among various measurement groups, with and without isolate
\label{isolate-ci-comparison}](img/stability/isolate-ci-comparison.tex)

As a side note, in VirtualBox, the wall-clock time measurements of some 
workloads such as `qsort.py` tend to have larger outliers (such as 12 seconds 
when the median is around 6 seconds). However, this phenomenon only manifests in 
a few cases and we decided not to study it further.

### Validation of Parallel Worker Results

For the homogeneous parallel setup, we needed to make sure that our measurements 
did actually run in parallel. We calculated the total runtime for all the 
measurements (the difference between the timestamps of the first and last 
measured results, regardless of the worker) and the time when all the worker 
processes ran in parallel (the difference between the timestamps of the last 
received result of a first iteration and the first received result of a last 
iteration). We then inspected the ratio of these two numbers.

As depicted in Figure \ref{parallel-run-ratios}, this ratio is 68% in one case 
and higher than 90% most of the time. This should guarantee that the
homogeneous parallel measurements are not in fact a sequence of sequential 
workloads and their results are similar to actual parallel measurements.

![A histogram of parallel run ratios
\label{parallel-run-ratios}](img/stability/parallel-run-ratios.tex)

### Comparing Parallel Worker Results

![Box plots of CPU time measurements for the bsearch workload with an increasing 
number of parallel workers (divided by isolation technology) 
\label{bsearch-over-isolations}](img/stability/bsearch-over-isolations.tex)

When examining how raising the system load affects the stability of 
measurements, we discovered several interesting trends.

First, the execution times seem to be higher under higher levels of system load
for all exercise types. For example, in Figure \ref{bsearch-over-isolations}, we 
can see that a `bsearch` iteration normally takes about 0.35 seconds on the bare 
metal with a single process and 0.4-0.45s when 10 processes are running in 
parallel. It is worth mentioning that the difference seems much smaller for 
`exp_float`. This could be due to the parallel workers competing for the 
last-level cache and memory controller, which would affect memory-bound tasks 
more than it would affect CPU-bound tasks.

Second, the measurements seem to be notably stable with a single worker on the 
bare metal (`B`) and in Docker (`D`). This stability, however, decays quickly 
with as little as two workers measuring in parallel. In `isolate` (`I`) on the 
bare metal, in Docker with `isolate` (`D+I`) and in VirtualBox (`V` and `V+I`), 
the stability of measurements seems similar in the cases with one and two 
parallel workers. A noticeable decay appears with four workers. These trends are 
illustrated by Figure \ref{isolation-comparison}.

Third, the instability related to a higher degree of parallelism seems more 
prominent in measurements of memory-bound workloads than in those of CPU-bound 
workloads. This could however be a coincidence since the CPU-bound workloads 
take less time per iteration than the memory-bound ones.

A conclusion follows from our observations: we cannot allow a number of parallel 
workers that is so high that any of these effects manifests. Otherwise, we risk 
that our measurements will become too unstable. In the case of our hardware, it 
seems that running as little as four workers in parallel might lead to a 
measurable instability.

### Evaluation of Performance Metrics

In this section, we try to explain the changes in results of our time 
measurements caused by using `isolate` and increasing the system load using the 
data gathered by `perf` (the exact list of counted events can be found in 
Section \ref{measured-data}). With the exception of `page-faults`, the events 
form pairs of the number of misses and the total number of accesses for a type 
of cache. Therefore, it is natural to also examine the miss ratio for these 
counters, which is depicted in Figure \ref{perf-miss-ratios}.

![The ratios of the number of miss events and number of load/store events for 
the L1 data cache (L1D) and the last-level cache (LLC), shown as box plots 
divided by isolation technology and number of parallel workers
\label{perf-miss-ratios}](img/stability/miss-ratios-combined.tex)

The miss ratio for L1 data cache loads seems close to zero for every exercise 
type except `bsearch`. However, the absolute number of misses is substantial (in 
the order of millions of events per iteration). The miss ratio is also higher 
when using `isolate`, although it is still in the order of tenths of a percent. 
No change in the number of misses was observed with increasing system load. This 
shows that the values in L1 cache are used very frequently and it performs well 
in all cases.

For stores in the last level cache, the miss ratio seems larger with `isolate` 
than on the bare metal. However, it does not increase with the system load as 
much. The ratio is mostly less than 0.05% on the bare metal and close to 0.1% 
with `isolate`. This might be a part of the explanation for `isolate` 
measurements being slightly less unstable with increasing number of parallel 
workers than measurements on the bare metal.

We observed an unexpectedly small last level cache load miss ratio in `bsearch` 
(around 0.5%), when compared to the other exercise types (up to 60%). This could 
indicate that our binary search workload utilizes the last-level cache more than 
the other workloads, which is plausible -- the other exercise types seem to work 
with the L1 data cache more efficiently and might not need to use the last level 
cache as much. We could not find any interesting trend in the data related to 
neither using `isolate` nor increasing the system load.

To see if there is a relationship between the results of measurements of 
performance metrics and the measurements of CPU time, we calculated the standard 
(Pearson) correlation coefficient and also the Spearman coefficient of each of 
the performance metrics and the CPU time for every tested exercise type. The 
Spearman coefficient should help in pointing out nonlinear relationships between 
the variables.

The correlation coefficients are listed in Table \ref{perf-correlations}. It 
seems that no value from our selection influences the CPU time. The only result 
that does not clearly suggest that the values are unrelated is that the standard 
(Pearson) correlation of the number of L1 cache misses and the CPU time is 
`0.417` for the `bsearch` workload. However, this is not nearly enough evidence 
for any conclusion. Also, even though L1 data cache misses occur more during the 
`bsearch` workload than during other workloads, their frequency does not seem to 
be greatly influenced neither by the number of parallel workers nor by using 
`isolate`.

!include tables/stability/perf-correlations.md

The last metric left to examine is the number of page faults (depicted in Figure 
\ref{perf-page-faults}). We can see that it does not increase with the number of 
parallel workers, which is not a surprising result. Apart from this, it is 
evident that using `isolate` results in cca. 300 page faults, regardless of the 
workload type. This is likely the cost for loading the `isolate` binary, which 
is also measured by `perf`.

![Box plots of the number of page faults, divided by number of parallel workers, 
workload type and isolation technology
\label{perf-page-faults}](img/stability/pagefaults.tex)

The result of our analysis is that we could not find any explanation of the 
phenomena observed in the previous section based on the data obtained from 
`perf`. If the experiment was to be repeated, a more careful selection of 
observed events would be required. 

### The Effects of Explicit Affinity Settings

Process schedulers in modern operating systems for multi-CPU systems are complex
software that relies on sophisticated algorithms. Trying to bypass the scheduler
by pinning worker processes to CPUs with taskset would not be generally
recommended.

However, schedulers are typically concerned about objectives such as throughput, 
latency of IO-bound tasks and fairness (prevention of 
starvation)[@UnderstandingLinuxSched], and measurement stability is not an 
important consideration when they assign processes to CPU cores, so it makes 
sense to examine the effects of setting the CPU affinity explicitly.

We ran our experiment using three different ways of setting the affinity -- 
using `numactl`, using `taskset` with a single core and using `taskset` with a 
fixed subset of the available cores (this is elaborated on in Section 
\ref{hw-and-os}).

To get an insight into the effects of CPU affinity settings, we compared the 
means and standard deviations of results grouped by exercise type, isolation and 
execution setup, with and without affinity settings. We performed the comparison 
using confidence intervals obtained from a bootstrap procedure (the same way as 
we used in previous sections).

In Figure \ref{taskset-comparison}, we can see that the measurements performed 
with `numactl` have the same mean and standard deviation as their counterpart 
without affinity settings in most cases. This seems to confirm the assumption 
that running processes on the memory node that belongs to the executing CPU is 
the default behavior. Therefore, using `numactl` would be redundant.

Fixating a worker process to a single core with `taskset` seems to make the 
measurements less stable in terms of standard deviation in two thirds of the 
compared groups. It is clear that the mean was influenced by this setting in 
some way, but it is difficult to summarize the difference -- the number of 
groups where it got smaller is very similar to the number of groups where it got 
higher. Since the comparison did not yield any positive results, we will not 
consider the single-core `taskset` setup any further.

Finally, the multi-core way of using `taskset` seems to improve both the mean and 
the standard deviation in more than three quarters of the compared groups. This 
seems like a notable breakthrough. Upon closer inspection, we found that the 
results seem much more stable without any isolation technology (as shown by 
Figure \ref{taskset-points-bare}). However, it is worth noting that the mean 
execution time still rises with the increasing setup size. For example, 
`bsearch` takes roughly 0.35ms on two workers and about 0.425ms on eight workers 
(20% more).

Furthermore, it can be seen in Figure \ref{taskset-points-isolate} that using
multi-core `taskset` does not cause any improvement when we use `isolate` for 
process isolation. The results of measurements in Docker without `isolate` look 
similar to those of measurements with no isolation at all. Docker with `isolate` 
performs similarly to `isolate`.

From these observations, we can conclude that using multi-core taskset could help 
stabilize measurements on the bare metal or in Docker in case they were run in 
batches with a fixed number of workers. However, setting the CPU (or NUMA) 
affinity does not bring any improvement in the case of ReCodEx, where the number 
of active workers varies in time and where isolation is critical.

![A plot showing the results of a comparison between mean and standard deviation 
values for measurements with and without explicit affinity settings, for 
different ways of setting the affinity
\label{taskset-comparison}](img/stability/taskset-comparison.tex)

![A scatter plot of measured CPU times by iteration for increasing setup sizes 
(no isolation technology) 
\label{taskset-points-bare}](img/stability/taskset-default-vs-taskset-multi-bare.tex)

![A scatter plot of measured CPU times by iteration for increasing setup sizes 
(using isolate for process isolation) 
\label{taskset-points-isolate}](img/stability/taskset-default-vs-taskset-multi-isolate.tex)

### The Effects of Disabling Logical Cores

Disabling logical cores (HyperThreading) might improve the stability of 
measurements, since it stands to reason that processes that run on different 
logical cores in a single physical core influence each other more than processes 
on separate physical cores.

As a side note, disabling HyperThreading can also help increase the security of 
a server, since many exploits have surfaced recently that use this technology. 
We do not expect students to submit functional HyperThreading exploits into 
ReCodEx, but it might be a concern if we were building a public programmer 
education platform.

To verify our hypothesis about stability, we repeated the measurements on the 
same machine with the HyperThreading feature disabled (using a startup 
configuration option). The results for selected workloads on the bare metal and 
with `isolate` can be seen in Figure \ref{taskset-points-bare} and Figure 
\ref{taskset-points-isolate}, respectively. It seems that disabling logical 
cores increases the stability for bare metal measurements in some workloads and 
that the multi-core taskset setting further improves the situation. This trend 
is not as prominent when `isolate` is used. In fact, the scatter plot of 
measurements without logical cores in Figure \ref{taskset-points-isolate} looks 
almost indistinguishable from that with logical cores enabled.

A comparison of confidence intervals of the means and standard deviations for 
all groups of measurements by workload type, execution setup and isolation 
technique (as depicted in Figure \ref{taskset-comparison-noht}) shows that with 
no affinity settings, the measurements with logical cores disabled have a lesser 
mean and standard deviation that those with logical cores enabled in almost all 
cases.

The results are not as conclusive when we compare measurements performed with 
the multi-core taskset setting (again, we compare measurements with logical cores 
disabled to those that use logical cores). While the mean is decreased in the 
majority cases and increased in none of them, the standard deviation increases 
in about 20% of the cases.

![A plot showing the results of a comparison between mean and standard deviation 
values for measurements with and without logical cores enabled. One group of 
comparisons was made with no explicit affinity setting and the other was made 
with the multi-core taskset policy.
\label{taskset-comparison-noht}](img/stability/taskset-comparison-noht.tex)

In summary, it seems that disabling logical cores improves the overall stability 
of measurements, but the improvement is not as large when `isolate` is used.
