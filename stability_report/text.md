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
likely scenario - it often happens that multiple students start submitting 
solutions to an assignment at the same time.

The levels of system load will differ according to the number of measurements 
running in parallel. The levels shall be chosen with regard to the topology of 
CPU cores so that they exercise all variants of cache utilization. For example, 
on a system with two dual-core CPUs, we will want to run 1) a single process 2) 
two processes (each uses one CPU cache) and 3) four processes (two pairs of 
processes will share the last level cache).

### Isolation Technologies

We will be measuring the effects on the stability of time measurements of the 
following isolation technologies:

- Isolate - a thin wrapped around CGroups and kernel namespaces that is used by 
  ReCodEx.
- Docker - the most popular container platform as of today.
- Docker + isolate - a combination that might be used to support user-supplied 
  runtime environments in ReCodEx. Isolate might still be necessary to protect 
  the insides of the container from the code supplied by students (an attacker 
  that gains control of the container could e.g. report any grades they like to 
  the rest of the system).
- VirtualBox - a readily available "user-grade" virtualization solution. We will 
  manage our VMs using Vagrant so that we can easily take measurements of other 
  virtualization platforms if necessary.
- VirtualBox + isolate - the reasoning for adding isolate is the same as with 
  Docker.

The measured data will be compared to values measured on the bare metal. 
Measurements will also be performed with manually configured CPU affinities to 
see if such configuration has any effect on the time measurement stability. 
Setting the affinity for VirtualBox VMs is very difficult, so this setup will 
not be included in the experiment.

### Choosing Workloads

We will concentrate on two basic groups of workloads - CPU-bound and 
memory-bound. We expect that the runtimes of memory-bound tasks will be less 
stable due to factors such as cache and page misses (these effects are further 
amplified by virtualization technology). Of course, there are factors that are 
detrimental to measurement stability of CPU-bound tasks too - for example 
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

## Preliminary Checks

### Dependence of Result Variance on Input

### Detecting "Warming up"

## Result Analysis

### Evaluation of Isolate Measurements

### The Effects of Explicit Affinity Settings

### Comparing Parallel Worker Results

### Comparison of Measurement Stability

## Conclusion
