---
geometry: margin=0.8in
---

# Stability of Time Measurements in Virtualized Environments

The objective of our experiment is to verify the claim that the results of time 
measurements performed on virtual machines tend to be less stable than those 
performed with direct access to the hardware. In this context, less stable means 
that the measured values tend to differ when the experiment is repeated. We also 
examine the effects of system load on measurement stability and whether some 
isolation techniques mitigate could help mitigate them.

We also extend our research to containers -- lightweight runtime environments 
that use facilities provided by the host operating system to isolate programs 
from the outside world and potentially also restrict their resource usage. 
Namely, we use Docker, the most popular tool for container management as of 
today, for our comparison.

The experiment is motivated by the ReCodEx project -- a system for automatic 
evaluation of submissions to programming homework assignments. On top of 
checking that the submission provides correct outputs for a set of configured 
inputs, ReCodEx also limits and measures time and memory consumption. The more 
unstable our measurements get, the more likely we are to mistake an efficient 
program for an inefficient one (and vice versa, although less frequently).

If we found a class of tasks that can be run on a virtual machine without losing 
stability of measurements, we could run a part of the workload of the system in 
a cloud environment, which would help us deal with irregular traffic more 
efficiently.

## Experiment Methodology

We shall measure multiple types of workloads under different isolation 
configurations and system loads. We will try multiple ways of simulating various 
levels of system load. First, we will run multiple instances of the measurements 
of the same workload in parallel. While it might seem artifical, it is actually 
a likely scenario -- it often happens that multiple students start submitting 
solutions to an assignment at the same time (for example for in-class 
assignments). This setup is called `parallel-homogenous` in plots and 
measurement scripts. Then, we will use the `stress-ng` utility to create 
multiple configurations of synthetic system loads and run measurements of a 
single workload. This method is less realistic, but the results might be easier 
to interpret and reproduce. In plots and measurement scripts, the names of these 
setups start with `parallel-synth`.

In order to examine the behavior of the system under varying levels of load, we 
will repeat the measurements with different amounts of workers running in 
parallel. The amounts of workers shall be chosen with regard to the topology of 
CPU cores so that they exercise all variants of cache utilization. For example, 
on a system with two dual-core CPUs with hyperthreading, we will want to run 1) 
a single process, 2) two processes (each uses one CPU cache), 3) four processes 
(two pairs of processes will share the last level cache) and 4) eight processes 
(one process per hyperthreading core). 

Launching more processes than there is hyperthreading cores might be an
interesting experiment, but there is little value in it because all these
processes could not run in parallel at the same time. Such configurations would
be viable if ReCodEx was used for IO-bound tasks more often -- we could have
more parallel measurements than there are CPU threads running while other
threads wait for IO.

The parallel workers will be launched using GNU parallel, a relatively 
lightweight utility that simplifies the task of launching the same process N 
times in parallel with a variable parameter. There are numerous alternatives to 
parallel with negligible differences (considering our use-case). In future work, 
we might evaluate the possible advantages of using these.

### Isolation Technologies

We will be measuring the effects on the stability of time measurements of the 
following isolation technologies:

- Bare metal -- no isolation at all (used as a reference value).
- Isolate -- a thin wrapper around CGroups and kernel namespaces that is used by 
  ReCodEx both for isolated execution of untrusted code and for measuring its 
  performance.
- Docker -- the most popular container platform as of today.
- Isolate in Docker -- a combination that might be used to support user-supplied 
  runtime environments in ReCodEx. Isolate might still be necessary to protect 
  the insides of the container from the code supplied by students (an attacker 
  that gains control of the container could e.g. report any grades they like to 
  the rest of the system).
- VirtualBox -- a readily available "user-grade" virtualization solution. We 
  will manage our VMs using Vagrant so that we can easily take measurements of 
  other virtualization platforms if necessary.
- Isolate in VirtualBox -- the reasoning for adding isolate is the same as with 
  Docker.

The measured data will be compared to values measured on the bare metal. 
Measurements will also be performed with manually configured CPU affinities to 
see if such configuration has any effect on the stability of time measurements. 
Setting the affinity for VirtualBox VMs is very difficult when parallel 
processes are involved, so this setup will not be included in the experiment.

### Workload Types

We will concentrate on two basic groups of workloads -- CPU-bound and 
memory-bound. We expect that the runtimes of memory-bound tasks will be less 
stable due to factors such as cache and page misses (these effects are further 
amplified by virtualization technologies). Apart from that, there are factors 
that are detrimental even to the measurement stability of purely CPU-bound tasks 
-- for example, frequency scaling or sharing of CPU core components when 
hyperthreading is taking effect. Our chosen workloads are:

- `exp`: Approximation of $e^x$ using the $(1 + \frac{x}{n})^n$ formula with $x$ 
  and $n$ as parameters that are read from the memory. This workload tests 
  floating point operations while reading inputs sequentially from the memory.
- `gray2bin`: Conversion of numbers in memory from Gray code to binary. This 
  workload measures the performance of integer operations while inputs are being 
  read sequentially from the memory.
- `bsearch`: A series of binary searches in a large integer array in the memory. 
  This workload tests random access memory reads, which is a very common memory 
  access scheme in both real-world and synthetic workloads.
- `sort`: Sorting a large integer array in the memory using both the insertion 
  sort and quicksort algorithms. This workload tests random access memory reads 
  and writes. This memory access scheme is also common in many real-world and 
  synthetic workloads.

The workloads are implemented in C, which promises a relatively small overhead 
induced by the runtime environment (at least compared to managed languages).

The input sizes were chosen empirically so that the runtime of a single 
iteration is between 100 and 500 milliseconds. The main reason for this is that 
the time values reported by isolate are truncated to three decimal numbers and 
measurements of shorter workloads would be too granular. The iterations should 
not be too long either, because we measure multiple iterations using multiple 
isolation technologies, each under multiple setups, which totals to a 
substantial multiplicative factor on the total runtime. It is also noteworthy 
that most ReCodEx tests run in tens or hundreds of milliseconds.

The inputs are generated randomly using the `shuf` command from GNU coreutils. 
Typically, we generate sets of numbers from a given range, chosen with 
replacement. According to the documentation, `shuf` chooses the output numbers
with equal probabilities (sampling a uniform distribution with replacement).

### The Measured Data

ReCodEx uses CPU and wall clock time measurements reported by isolate. 
Therefore, the stability of these values is the most important result of our 
experiment.

Our workloads are also instrumented manually to "measure themselves" using the 
`clock_gettime` call. `CLOCK_PROCESS_CPUTIME_ID` is used to measure CPU time and 
`CLOCK_REALTIME` is used for wall clock time.

This instrumentation is necessary because some isolation setups cannot provide 
us with measurements from isolate (in fact, a half of them does not use isolate 
at all), yet we want to use these setups in our comparison. Measuring all this 
data also lets us examine the overhead caused by isolate and any potential 
discrepancies between the values.

## Hardware and OS Configuration

Dell PowerEdge M1000e

- CPU: 2* Intel(R) Xeon(R) CPU E5-2630 v4 @ 2.20GHz (A total of 20 physical CPUs 
  with hyperthreading) in a NUMA setup
- Memory: 256GB DDR4 (8 DIMMs by 32GB) @2400Mhz

Due to the CPU topology, we will measure the following parallel configurations:

- a single process
- 2 processes (each process can use one whole CPU cache)
- 4 processes (2 processes share the last-level cache on each CPU)
- 6 processes (3 processes share the last-level cache on each CPU)
- 8 processes (4 processes share the last-level cache on each CPU)
- 10 processes (5 processes share the last-level cache on each CPU)
- 20 processes (one process per physical CPU core, 10 processes share the 
  last-level cache)
- 40 processes (one process per logical CPU core, 20 processes share the 
  last-level cache)

The server runs CentOS 7 with Linux 3.10.0 kernel. The OS is configured 
according to the recommendations by the authors of isolate in its documentation:

- swap is disabled
- CPU frequency scaling governor is set to "performance"
- kernel address space randomization is disabled
- transparent hugepage support is disabled

The exact method of distributing the workloads over CPU cores when measuring
with `taskset` can be seen in the `distribute_workers.sh` script. The main idea
is that the workloads should be distributed evenly over physical CPUs (i.e. each
CPU should have the same amount of workloads running on it and it does not
matter which CPU cores in the same socket we choose because the cores only share
the last level cache, which is shared by all the cores). It is also noteworthy 
that we do not run multiple measurements of the same physical core
(using hyperthreading) unless absolutely necessary. The script might require
adjustments if we replicate this experiment on other CPUs with different 
topologies as it does not attempt to cover all possible CPU configurations.

## Preliminary Checks

Considering the objective of our experiment, we had to ensure that the results 
of our measurements are stable in ideal conditions (only one process at a time 
being measured on the bare metal without isolation) in the first place. 
Otherwise, the comparison with results in less than ideal conditions would be 
much more difficult. In other words, we are going to check that conditions exist 
under which the workloads we chose yield stable results.

### Dependence of Result Variance on Input

Being able to use randomly generated inputs in our workloads is very useful -- 
we can demonstrate that our results have not been "rigged" by carefully choosing 
inputs by simply regenerating the input data and seeing if we get the same 
outcome. However, this only holds when the generated inputs are large enough so 
that the measurement take the same amount of time on every repetition.

To see if the input sizes we chose are sufficient, we measured the execution 
time of each workload (100 iterations) on 300 randomly generated input files and 
calculated the mean and standard deviation of the measurements for each of the 
inputs. As we see in Figure \ref{dep-input-mean}, the mean execution time does 
not vary a lot -- the range between the minimum and maximum time stays close to 
2ms. However, as shown by Figure \ref{dep-input-sd}, the range of standard 
deviations is rather large, reaching up to 11ms. After inspecting the histogram 
(Figure \ref{dep-input-hist}) of the deviations, we found that this is due to a 
small number of outliers. We conclude that the input data has a neglible effect 
on the execution time, even though there is a handful of inputs for the `qsort`, 
`bsearch` and `gray2bin` workloads on which the time measurements are unusually 
unstable.

![The min-max range of mean times for each workload \label{dep-input-mean}](dependence-on-input-means.png)

![The min-max range of standard deviations of times for each workload \label{dep-input-sd}](dependence-on-input-sds.png)

![A histogram of standard deviations of execution times for each input \label{dep-input-hist}](dependence-on-input-sds-histogram.png)

### Detecting "Warming up"

In computer performance evaluation, it is common to let the benchmark warm up by 
performing a handful of iterations without measuring them. This way, the 
measurements are not influenced by e.g. initialization of the runtime 
environment or population of caches.

We expect that warming up will not occur in our experiment because each 
iteration runs in a separate process, but it is still necessary to verify this 
assumption. To do so, we compute the standard deviation of a sliding window of 
10 observations and compare it to the standard deviation of the whole sample. 
This is done for the single process measurement of each workload on the bare 
metal.

![Running SD (black) vs. total SD (blue) for the binary search 
workload](warmup-bsearch.png)

The plot for the binary search workload shows us that the rolling standard 
deviation is not clearly higher at the beginning of the measurement sequence 
than at the end. The plots for the other workloads (see the attachments) show 
similar results. In fact, some workloads exhibit sudden peaks in the standard 
deviation when nearing 50 iterations. Although it is possible that 100 
measurements is not enough to detect a warmup period, it seems improbable. It is 
also important to note that the deviation stays relatively low the whole time 
(close to 1ms). Therefore, we can conclude that warming up is not an important 
factor in our measurements.

If the opposite was true, we would have to change the way ReCodEx measures 
submissions -- if a student submitted the same program in a quick succession, 
they could get a better score for the later solution.

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

![A scatter plot of time measurements grouped by isolation for chosen setups and workloads with results from a single worker highlighted in red \label{isolation-comparison}](isolation-comparison.png)

The most obvious trend is that the measured values are centered around different 
points under different isolation technologies for some workloads. For example, 
an iteration of the `bsearch` and `qsort` workloads tends to take about 100ms 
more in docker than on the bare metal or in isolate and about 300ms less in 
VirtualBox. The difference between the `isolate` and `docker-bare` setups is 
rather strange because both of these technologies use the same kernel facilities 
to achieve isolation.

To verify this in a more formal way, we compared boostrapped 0.95 confidence 
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

![A scatter plot of time measurements with fixed CPU affinities grouped by isolation for chosen setups and workloads with points color-coded by parallel worker \label{isolation-comparison-taskset}](isolation-comparison-taskset.png)

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
\label{taskset-comparison}](taskset-comparison.png)

## Conclusion

The experiment provided us with evidence that isolate has a negative effect on 
the stability of CPU time measurements. The exact cause of this remains to be 
researched, along with the curious case of VirtualBox, where this effect does 
not seem to be present. The difference in measurement stability does not seem to 
be too big for the examined isolation technologies.

Also, we found that measuring many submissions at once impacts the stability of 
measurements. On a system with two 10-core CPUs, a notable decrease in stability 
appeared with as little as 4 parallel workers.

Our experiment also yielded two smaller results. First, the wall-clock time 
measured by isolate tends to be unstable and should not be trusted when high 
precision measurements are required. Of course, this phenomenon should be 
researched further, possibly with newer versions of the kernel.

Second, setting the CPU affinity explicitly does not generally yield any 
improvements to the overall measurement stability, even though it seems to 
improve the stability for the individual worker processes.
