---
geometry: margin=0.8in
---

# Stability of Time Measurements in Virtualized Environments

The objective of our experiment is to verify that the results of time 
measurements performed on virtual machines tend to be less stable than those 
performed directly on physical hardware. By "less stable", we understand that 
the measured values tend to differ when the experiment is repeated.

We also extend our research to containers -- lightweight runtime environments 
that use facilities provided by the host operating system to isolate programs 
from the outside world and potentially also restrict their resource usage. 
Currently, the most popular tool for container management is Docker.

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
configurations and system loads. To simulate various levels of system load, we 
will run multiple instances of the measurements of the same workload in 
parallel. Although this might sound like a synthetic use case, it is actually a 
likely scenario -- it often happens that multiple students start submitting 
solutions to an assignment at the same time.

The levels of system load will differ according to the number of measurements 
running in parallel. The levels shall be chosen with regard to the topology of 
CPU cores so that they exercise all variants of cache utilization. For example, 
on a system with two dual-core CPUs, we will want to run 1) a single process 2) 
two processes (each uses one CPU cache) and 3) four processes (two pairs of 
processes will share the last level cache). The parallel workers will be 
launched using GNU parallel.

### Isolation Technologies

We will be measuring the effects on the stability of time measurements of the 
following isolation technologies:

- Isolate -- a thin wrapped around CGroups and kernel namespaces that is used by 
  ReCodEx.
- Docker -- the most popular container platform as of today.
- Docker + isolate -- a combination that might be used to support user-supplied 
  runtime environments in ReCodEx. Isolate might still be necessary to protect 
  the insides of the container from the code supplied by students (an attacker 
  that gains control of the container could e.g. report any grades they like to 
  the rest of the system).
- VirtualBox -- a readily available "user-grade" virtualization solution. We 
  will manage our VMs using Vagrant so that we can easily take measurements of 
  other virtualization platforms if necessary.
- VirtualBox + isolate -- the reasoning for adding isolate is the same as with 
  Docker.

The measured data will be compared to values measured on the bare metal. 
Measurements will also be performed with manually configured CPU affinities to 
see if such configuration has any effect on the time measurement stability. 
Setting the affinity for VirtualBox VMs is very difficult, so this setup will 
not be included in the experiment.

### Choosing Workloads

We will concentrate on two basic groups of workloads -- CPU-bound and 
memory-bound. We expect that the runtimes of memory-bound tasks will be less 
stable due to factors such as cache and page misses (these effects are further 
amplified by virtualization technology). Of course, there are factors that are 
detrimental to measurement stability of CPU-bound tasks too -- for example 
frequency scaling or sharing of CPU core components when hyperthreading is 
taking effect. Our chosen workloads are:

- Approximation of `e^x` using the `(1 + x / n)^n` formula with `x` and `n` as 
  parameters that are read from the memory. This workload tests floating point 
  operations while reading inputs sequentially from the memory.
- Conversion of numbers in memory from Gray code to binary. This workload tests 
  integer operations while inputs sequentially from the memory.
- A series of binary searches in a large integer array in the memory. This 
  workload tests random access memory reads.
- Sorting a large integer array in the memory using both the insertion sort and 
  quicksort algorithms. This workload tests random access memory reads and 
  writes.

The workloads are implemented in C, which promises a relatively small overhead 
induced by the runtime environment (at least compared to managed languages).

The input sizes were chosen empirically so that the runtime of a single 
iteration is between 100 and 500 milliseconds. The main reason for this is that 
the time values reported by isolate are truncated to three decimal numbers and 
measurements of shorter workloads would be too granular. The workloads should 
not be too long either, because we measure multiple iterations using multiple 
isolation technologies, each under multiple setups, which totals to a 
substantial multiplicative factor on the total runtime.

### The Measured Data

ReCodEx uses CPU and wall clock time measurements reported by isolate. 
Therefore, the stability of these values is the most important result of our 
experiment.

Our workloads are also instrumented manually to "measure themselves" using the 
`clock_gettime` call. `CLOCK_PROCESS_CPUTIME_ID` is used to measure CPU time and 
`CLOCK_REALTIME` is used for wall clock time.

Measuring all this data lets us examine the overhead caused by isolate and any 
potential discrepancies between the values.

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
according to the recommendations by the authors of isolate:

- swap is disabled
- CPU frequency scaling governor is set to "performance"
- kernel address space randomization is disabled
- transparent hugepage support is disabled

The exact method of distributing the workloads over CPU cores when measuring 
with `taskset` can be seen in the `distribute_workers.sh` script. The main idea 
is that the workloads should be distributed evenly over physical CPUs (i.e. each 
CPU should have the same amount of workloads running on it and it does not 
matter which CPU cores in the same socket we choose because the cores only share 
the last level cache and it is shared between all the cores). This script will 
probably need changes if we replicate this experiment on other CPUs.

TODO maybe we are using HT pairs unnecessarily.

## Preliminary Checks

Considering the objective of our experiment, we had to ensure that the results 
of our measurements are stable in ideal conditions -- that is when we only 
measure a single workload at a time on the bare metal. Otherwise, the comparison 
with results in less than ideal conditions would be much more difficult.

### Dependence of Result Variance on Input

It is practical to use randomly generated inputs in our workloads -- we can 
demonstrate that our results have not been "rigged" by carefully choosing inputs 
by simply regenerating the inputs and seeing if the results are the same.

To do this, we measured each workload on 300 randomly generated input files, 
took the mean for each of the inputs and observed the variance of these sets of 
means. TODO


### Detecting "Warming up"

In computer performance evaluation, it is common to let the benchmark warm up by 
performing a handful of iterations without measuring them. This way, the 
measurements are not influenced by e.g. initialization of the runtime 
environment or population of caches.

We expect that warming up will not occur in our experiment because each 
iteration runs in a separate process, but it is still necessary to verify this 
assumption. To do so, we take the standard deviation of a sliding window of 10 
observations and compare this to the standard deviation of the whole sample. 
This is done for the single process measurement of each workload on the bare 
metal.

The plot (TODO) shows us that the rolling standard deviation is not clearly 
higher at the beginning of the measurement sequence than at the end. In fact, 
some workloads exhibit sudden peaks in the standard deviation when nearing 50 
iterations. Although it is possible that 100 measurements is not enough to 
detect a warmup period, it seems improbable. It is also important to note that 
the deviation stays relatively low the whole time (close to 1ms). Therefore, we 
conclude that warming up is not an important factor in our measurements.

If the opposite was true, we would have to change the way ReCodEx measures 
submissions -- if a student submitted the same program in a quick succession, 
they could get a better score for the later solution.

## Result Analysis

### Evaluation of Isolate Measurements

As mentioned before, our measurements that run in isolate yield four values the 
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
+/- 0.5%). This result is not surprising -- starting a process is generally not 
a particularly CPU-intensive task. However, it tells us that the CPU time 
measured by isolate is fairly reliable.

On the other hand, we found that the wall-clock time error tends to vary a lot. 
This is most prominent when a high number of parallel workers is involved 
(20-40) - the relative error goes as high as 150% and exceeds 20% in most cases. 
Smaller values of the relative error (over 5%) start to manifest with as little 
as four parallel workers.

We found no obvious link between the value of the relative wall-clock time error 
and the isolation technology being used - both docker+isolate and isolate on its 
own tend to have largely varying measurement errors. VirtualBox might seem to be 
more stable at first glance because we are missing data for larger amounts of 
parallel workers.

The instability of the error is probably caused with the overhead of starting 
new processes. This overhead grows larger when we need to start many processes 
at once and both the file system and memory get stressed.

TODO maybe add a table here?

### The Effects of Explicit Affinity Settings

- tampering with the scheduler is probably a bad idea, but schedulers are 
  generally not concerned with measurement stability

To explore how explicitly setting the CPU affinity influences the stability of 
measurements, we made violin plots of our measurements for each combination of 
workload, setup and isolation technology. In some instances, `taskset` caused 
the measurement to be particularly - see iso-cpu measurements with 4 workers.

TODO plot

TODO do the results vary for any isolation technique?

### Comparing Parallel Worker Results

- warmup/cooldown when workers are spawning/dying
- difference between the results

### Comparison of Measurement Stability

## Conclusion

WIP blah blah summary.

Our experiment also yielded several smaller results. First, the wall-clock time 
measured by isolate tends to be unstable and should not be trusted when high 
precision measurements are required. Of course, this phenomenon should be 
researched further, possibly on newer versions of the kernel.

Second, setting the CPU affinity explicitly does not generally yield any 
improvements. 
