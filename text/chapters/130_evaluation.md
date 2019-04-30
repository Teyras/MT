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

The error is rather small and stable for the CPU times (not higher than 2.5ms 
+/- 0.5%) - see Table \ref{iso-cpu-err}. This result is not surprising -- 
starting a process is generally not a particularly CPU-intensive task. However, 
it tells us that the CPU time measured by isolate is fairly reliable.

On the other hand, we found that the wall-clock time error tends to vary a lot 
(see Table \ref{iso-wall-err}). This is most prominent when a high number of 
parallel workers is involved (20-40) - the relative error goes as high as 150% 
and exceeds 20% in most cases. Smaller values of the relative error (over 5%) 
start to manifest with as little as four parallel workers. This means that there 
is a large offset between the wall-clock time measured by isolate and the value 
measured by the programs themselves. Also, this offset tends to vary a lot in 
many cases.

We found no obvious link between the value of the relative wall-clock time error 
and the isolation technology in use - both docker+isolate and isolate on its own 
tend to have largely varying measurement errors. VirtualBox might seem to be 
more stable at first glance because we are missing data for larger amounts of 
parallel workers.

The instability of the error is possibly caused by the overhead of starting new 
processes. This overhead grows larger when we need to start many processes at 
once and both the file system and memory get stressed.

Table: Mean and standard deviation of the error of isolate CPU time measurements, sorted by relative error (truncated) \label{iso-cpu-err}

|setup                  |isolation      |workload                      | cpu_err_mean| cpu_err_sd| cpu_err_cv|
|:----------------------|:--------------|:-----------------------------|------------:|----------:|----------:|
|parallel-homogenous,40 |isolate        |sort/insertion_sort 16384     |    0.0019296|  0.0009837|  0.4297969|
|parallel-homogenous,40 |isolate        |exp/exp_float 65536           |    0.0019481|  0.0011159|  0.3823136|
|parallel-homogenous,40 |docker-isolate |sort/insertion_sort 16384     |    0.0020107|  0.0008493|  0.3667278|
|parallel-homogenous,40 |isolate        |exp/exp_double 65536          |    0.0019603|  0.0010326|  0.3407997|
|parallel-homogenous,40 |isolate        |gray/gray2bin 1048576         |    0.0022868|  0.0008212|  0.2922161|
|parallel-homogenous,40 |docker-isolate |gray/gray2bin 1048576         |    0.0023603|  0.0007924|  0.2918224|
|parallel-homogenous,40 |docker-isolate |exp/exp_double 65536          |    0.0019724|  0.0007227|  0.2443991|
|parallel-homogenous,20 |docker-isolate |sort/insertion_sort 16384     |    0.0016962|  0.0004967|  0.2282317|
|parallel-homogenous,20 |isolate        |sort/insertion_sort 16384     |    0.0015976|  0.0004811|  0.2196254|
|parallel-homogenous,40 |docker-isolate |exp/exp_float 65536           |    0.0019607|  0.0006346|  0.2188820|

Table: Mean and standard deviation the error of isolate wall-clock time measurements (truncated) \label{iso-wall-err}

|setup                  |isolation      |workload                      | wall_err_mean| wall_err_sd| wall_err_cv|
|:----------------------|:--------------|:-----------------------------|-------------:|-----------:|-----------:|
|parallel-homogenous,40 |docker-isolate |sort/insertion_sort 16384     |     0.3020682|   0.4587180| 197.9905824|
|parallel-homogenous,40 |docker-isolate |gray/gray2bin 1048576         |     0.3068423|   0.4456143| 164.0531814|
|parallel-homogenous,40 |docker-isolate |exp/exp_double 65536          |     0.3118389|   0.4629482| 156.5151922|
|parallel-homogenous,40 |isolate        |sort/insertion_sort 16384     |     0.2147323|   0.3429101| 149.7948918|
|parallel-homogenous,20 |docker-isolate |sort/insertion_sort 16384     |     0.0926428|   0.1332219|  61.2041077|
|parallel-homogenous,20 |docker-isolate |gray/gray2bin 1048576         |     0.1052375|   0.1484750|  57.9439769|
|parallel-homogenous,10 |isolate        |sort/insertion_sort 16384     |     0.0558234|   0.0428460|  20.1191935|
|parallel-homogenous,10 |docker-isolate |gray/gray2bin 1048576         |     0.0571874|   0.0449239|  17.9554209|
|parallel-homogenous,6  |docker-isolate |exp/exp_float 65536           |     0.0426826|   0.0265100|  10.0680829|
|parallel-homogenous,6  |isolate        |sort/insertion_sort 16384     |     0.0341460|   0.0204968|   9.8415938|
|parallel-homogenous,20 |vbox-isolate   |exp/exp_float 65536           |     0.0026738|   0.0286388|   8.8553625|
|parallel-homogenous,4  |docker-isolate |sort/insertion_sort 16384     |     0.0372781|   0.0179162|   8.7399654|
|parallel-homogenous,4  |docker-isolate |gray/gray2bin 1048576         |     0.0382769|   0.0207584|   8.6290874|

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

The most obvious trend is that the measured values are centered around different 
points under different isolation technologies for some workloads. For example, 
an iteration of the `bsearch` and `qsort` workloads tends to take about 100ms 
more in docker than on the bare metal or in isolate and about 300ms less in 
VirtualBox. The difference between the `isolate` and `docker-bare` setups is 
rather strange because both of these technologies use the same kernel facilities 
to achieve isolation.

To verify this in a more formal way, we compared bootstrapped 0.95 confidence 
intervals of the mean for the `bare`, `docker-bare` and `vbox-bare` isolation 
setups. As shown by Table \ref{mean-ci-comparison}, the comparison confirmed our 
observation, although the difference between the means of bare-metal 
measurements is not as clear as in the other comparisons when a larger degree of 
parallelism is employed.

Table: Results of comparison of 0.95 confidence intervals of the mean of CPU 
time for selected workloads \label{mean-ci-comparison}

|setup                  |workload                      |bare.vs.docker |bare.vs.vbox |docker.vs.vbox |
|:----------------------|:-----------------------------|:--------------|:------------|:--------------|
|single,1               |bsearch/bsearch 65536_1048576 |lesser         |higher       |higher         |
|single,1               |sort/qsort 1048576            |lesser         |higher       |higher         |
|parallel-homogenous,2  |bsearch/bsearch 65536_1048576 |lesser         |higher       |higher         |
|parallel-homogenous,2  |sort/qsort 1048576            |lesser         |higher       |higher         |
|parallel-homogenous,4  |bsearch/bsearch 65536_1048576 |lesser         |higher       |higher         |
|parallel-homogenous,4  |sort/qsort 1048576            |lesser         |higher       |higher         |
|parallel-homogenous,6  |bsearch/bsearch 65536_1048576 |lesser         |higher       |higher         |
|parallel-homogenous,6  |sort/qsort 1048576            |same           |higher       |higher         |
|parallel-homogenous,10 |bsearch/bsearch 65536_1048576 |overlap        |higher       |higher         |
|parallel-homogenous,10 |sort/qsort 1048576            |higher         |higher       |higher         |
|parallel-homogenous,20 |bsearch/bsearch 65536_1048576 |lesser         |higher       |higher         |
|parallel-homogenous,20 |sort/qsort 1048576            |higher         |higher       |higher         |

<!-- TODO update this, +synth setups -->

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

Table: Results of comparison of 0.95 confidence intervals of the standard 
deviation of CPU time measured with and without isolate for selected workloads 
\label{sd-ci-comparison}

|setup                  |workload                      |bare    |docker  |vbox    |
|:----------------------|:-----------------------------|:-------|:-------|:-------|
|single,1               |exp/exp_float 65536           |overlap |lesser  |overlap |
|single,1               |exp/exp_double 65536          |same    |overlap |overlap |
|single,1               |bsearch/bsearch 65536_1048576 |overlap |same    |overlap |
|single,1               |gray/gray2bin 1048576         |overlap |overlap |overlap |
|single,1               |sort/insertion_sort 16384     |same    |overlap |same    |
|single,1               |sort/qsort 1048576            |overlap |overlap |same    |
|parallel-homogenous,2  |exp/exp_float 65536           |higher  |higher  |overlap |
|parallel-homogenous,2  |exp/exp_double 65536          |higher  |higher  |overlap |
|parallel-homogenous,2  |bsearch/bsearch 65536_1048576 |overlap |overlap |overlap |
|parallel-homogenous,2  |gray/gray2bin 1048576         |overlap |higher  |overlap |
|parallel-homogenous,2  |sort/insertion_sort 16384     |higher  |higher  |overlap |
|parallel-homogenous,2  |sort/qsort 1048576            |lesser  |higher  |higher  |
|parallel-homogenous,10 |exp/exp_float 65536           |higher  |higher  |overlap |
|parallel-homogenous,10 |exp/exp_double 65536          |higher  |higher  |higher  |
|parallel-homogenous,10 |bsearch/bsearch 65536_1048576 |overlap |lesser  |overlap |
|parallel-homogenous,10 |gray/gray2bin 1048576         |higher  |higher  |overlap |
|parallel-homogenous,10 |sort/insertion_sort 16384     |higher  |higher  |overlap |
|parallel-homogenous,10 |sort/qsort 1048576            |higher  |overlap |overlap |

<!-- TODO update this table, sort out synth workloads -->

<!-- The last noteworthy observation is that the wall-clock time measurements in 
VirtualBox seems to have the largest outliers. -->

### Validation of Parallel Worker Results

For the homogenus parallel setup, we needed to make sure that our measurements 
did actually run in parallel. We calculated the total runtime for all the 
measurements (the difference between the timestamps of the first and last 
measured results, regardless of the worker) and the time when all the worker 
processes ran in parallel (the difference between the timestamps of the last 
received result of a first iteration and the first received result of a last 
iteration). We then inspected the ratio of these two numbers.

As we can see in Table \ref{parallel-run-ratios}, this ratio is never smaller 
than 75% and higher than 90% most of the time. This should guarantee that the
homogenous parallel measurements are not in fact a sequence of sequential 
workloads and thus their correspond with reality.

Table: Ratios between total runtime and time spent with all processes running in 
parallel (truncated, there are over 200 groups) in ascending order
\label{parallel-run-ratios}

|   setup_size | workload_label                | isolation      | parallel_ratio   |
|-------------:|:------------------------------|:---------------|:-----------------|
|           20 | exp/exp_float 65536           | vbox-isolate   | 77.51%           |
|           20 | sort/insertion_sort 16384     | docker-bare    | 79.94%           |
|           40 | sort/insertion_sort 16384     | docker-bare    | 81.86%           |
|           40 | exp/exp_double 65536          | docker-bare    | 82.74%           |
|           20 | gray/gray2bin 1048576         | docker-bare    | 84.15%           |
|           40 | exp/exp_float 65536           | docker-bare    | 84.55%           |
|           40 | gray/gray2bin 1048576         | docker-bare    | 84.93%           |
|           20 | exp/exp_double 65536          | docker-bare    | 85.42%           |
|           20 | bsearch/bsearch 65536_1048576 | docker-bare    | 85.60%           |
|            4 | sort/qsort 1048576            | vbox-bare      | 86.15%           |
|           20 | sort/qsort 1048576            | docker-bare    | 86.48%           |
|           20 | exp/exp_float 65536           | docker-bare    | 86.84%           |
|           40 | sort/insertion_sort 16384     | isolate        | 87.13%           |
|            4 | gray/gray2bin 1048576         | vbox-bare      | 87.42%           |
|           40 | exp/exp_double 65536          | docker-isolate | 87.46%           |
|           10 | exp/exp_float 65536           | vbox-bare      | 87.54%           |
|            6 | sort/qsort 1048576            | vbox-bare      | 87.54%           |
|           10 | exp/exp_double 65536          | vbox-bare      | 87.58%           |
|           40 | sort/qsort 1048576            | docker-bare    | 87.85%           |
|            8 | gray/gray2bin 1048576         | vbox-bare      | 87.97%           |
|           20 | sort/qsort 1048576            | vbox-bare      | 88.52%           |

### Comparing Parallel Worker Results

When examining how raising the system load affects the stability of 
measurements, we discovered several interesting trends.

First, the execution times seem to be higher under higher system loads for some 
workloads. For example, in Figure \ref{isolation-comparison}, we can see that a 
`bsearch` iteration normally takes about 0.6 seconds on the bare metal with a 
single process and 1-1.5s when 10 processes are running in parallel. On the 
other hand, the difference is much smaller for `exp_float`. This could be due to 
the parallel workers competing for the last-level cache -- this would affect 
memory-bound tasks more than it would affect CPU-bound tasks.

Second, the measurements from different worker processes seem to be centered 
around different values. For an example of this, see the `exp_float` workload on 
4 workers in Figure \ref{isolation-comparison} (`bare` and `docker-bare`). This 
is also more notable under higher system loads.

Third, for some measurements, the results are stable most of the time and start 
decreasing quickly in the last few iterations (e.g. `bsearch` on bare metal with 
10 workers in Figure \ref{isolation-comparison}). This is due to the fact that 
the parallel workers do not always all finish at the same time and the last 
iterations are performed under a smaller system load.

A conclusion follows from our observations: we cannot allow a number of parallel 
workers that is so high that any of these effects manifests. Otherwise, we risk 
that our measurements will become too unstable. 

<!-- TODO it looks like VirtualBox is doing a little better -->

<!-- TODO find how much does the mean (median?) shift with increasing setup size 
     -->

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

<!-- TODO some citation would be lovely here -->

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
groups. Unfortunetaly, this means that using taskset is detrimental to the 
stability of the measurements.

![A plot showing the results of a comparison between mean and standard deviation 
values for measurement with and without taskset 
\label{taskset-comparison}](img/stability/taskset-comparison.png)

