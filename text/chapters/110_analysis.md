## Analysis

To explore the influence of aforementioned factors on measurement stability, we 
shall measure a reasonable set of workloads under different types of system load 
and different isolation technologies.

### Stability-influencing Factors on the Bare Metal

TODO

### Isolation Technologies

The primary purpose of running submitted code in an isolated environment is to 
ensure that it will not harm the host system by excessively using its resources 
(e.g. memory or disk space), and that it will not bypass the restrictions on 
resource usage by communicating with the outside world (e.g. by reading results 
from other submissions or delegating work to network services). Also, some 
isolation technologies also provide accounting of resource usage, which are 
necessary for grading of submissions. 

In this section, we survey existing isolation technologies, and select a handful 
whose effects on the stability of measurements will be examined. By intuition, 
any additional isolation layer adds overhead and therefore might introduce 
unpredictable components to the time measurements. However, the opposite might 
also be true -- especially when there are multiple measurements running in 
parallel, process isolation could help stabilize the results.

#### UNIX chroot

The `chroot` system call (present in the UNIX specification since version 7, 
released in 1979) changes the root directory of the calling process[@Chroot], 
thus isolating it from the rest of the system and preventing it from accessing 
files not needed for assignment evaluation. Historically, this has been used as 
an added layer of security for services that handle potentionally dangerous 
input.

Chroot itself however does neither limit resource usage nor provide accounting. 
Inter-process communication and network access are also not limited.

#### Ptrace-based Isolation

The MO system for evaluation of submissions in programming contests contains a 
sandbox implementation with resource limiting capabilities based on ptrace -- 
the Linux interface primarily used by userspace debuggers[@MaresPerspectives]. 
This sandbox was also used in CodEx (a programming assignment evaluator released 
cca. in 2006) and the CMS contest management system. Ptrace is used to intercept 
system calls and achieve process isolation and most of the resource limiting 
functionality uses `ulimit`. A notable problem of this approach is that it does 
not work well with multithreaded programs.

#### FreeBSD Jails

Jails[@FreeBSDJail] (featured since 2000) expand on the concept of chroots. In 
addition to confining a process to a part of the filesystem, they also provide 
network and process isolation and time, memory and disk usage 
limits[@FreeBSDRLimit].

Many other UNIX systems also have their own implementations of jails, e.g. zones 
in Solaris or sysjail in OpenBSD and NetBSD.

#### Linux Containers

The Linux kernel supports creating containers -- lightweight execution units 
that can be used for isolation and resource limiting.

Process isolation can be achieved using namespaces, a feature present in the 
kernel since 2006[@LinuxNamespacesCommit]. These allow locking the process in an 
environment where communication methods such as networking or reading files 
seemingly works without restrictions, but the sandboxed process can only 
communicate with processes in the same namespaces (granular sharing is also 
possible to allow e.g. connecting to services over the Internet).

Resource limiting and usage accounting is implemented using control groups 
(cgroups), merged into the kernel in 2007[{LinuxCgroupsLWN}].

It can be reasoned that these measures should not have any noticeable overhead, 
at least compared to processes running in the global process namespace and 
cgroup. After all, the global namespace is still a namespace.

TODO LXC

TODO Docker

TODO Isolate (used for measurements and isolation in ReCodEx)

TODO Charliecloud and Singularity

There were efforts to implement container support in Linux even before the 
inception of namespaces and cgroups. Possibly the most widely adopted one was 
OpenVZ[@OpenVZ] (released in 2005, based on commercial Virtuozzo from 2000). It 
shipped a modified Linux kernel that enabled container isolation and also 
provided hardware virtualization support in later versions.

#### Virtualization and Paravirtualization

Virtualization allows to run multiple guest operating systems on a single 
physical host without modifying them. The guests then operate under an illusion 
that they are running alone on a physical machine[@IntelVirtualization].

TODO something about trapping interrupts, emulating instructions, ...

Paravirtualization requires the guest operating system to be modified to avoid 
emulation of some instructions. For example, a block device driver can be 
implemented by directly calling the virtual machine monitor on the host which 
can keep the data from an emulated drive in a file or in memory. Xen[@Xen] is 
one of the most prominent pravirtualization technologies.

TODO how these might affect measurements

#### The Selection for our Measurements

From the survey of possible approaches to process isolation, we have selected 
the following technologies for our measurements:

- Bare metal -- no isolation at all (used as a reference value).
- Isolate -- a sandbox solution used in ReCodEx and other systems (such as CMS 
  or Kattis)
- Docker -- the most popular container platform as of today.
- Isolate in Docker -- a combination that might be used to support user-supplied 
  runtime environments in ReCodEx. Isolate might still be necessary to protect 
  the insides of the container from the code supplied by students (an attacker 
  that gains control of the container could e.g. report any grades they like to 
  the rest of the system) and to measure resource usage.
- VirtualBox -- a readily available "user-grade" virtualization solution. We 
  will manage our VMs using Vagrant so that we can easily take measurements of 
  other virtualization platforms if necessary.
- Isolate in VirtualBox -- the reasoning for adding isolate is the same as with 
  Docker.

An important deciding factor in the selection of isolation technologies was the 
fact that the computer performing the measurements runs on GNU/Linux, which 
disqualifies technologies like FreeBSD jails.

The measured data will be compared to values measured on the bare metal. 
Measurements will also be performed with manually configured CPU affinities to 
see if such configuration has any effect on the stability of time measurements. 
Setting the affinity for VirtualBox VMs is very difficult when parallel 
processes are involved, so this setup will not be included in the experiment.

TODO numa nodes?

### Types and Levels of System Load

There are multiple ways of simulating measurements on a machine where other 
processes are running. Firstly, we can run multiple instances of the 
measurements of the same workload in parallel. While it might seem like an 
artificial situation, it is actually a likely scenario -- it often happens that 
multiple students start submitting solutions to the same assignment at the same 
time (for example when the deadline is close). This setup is called 
`parallel-homogenous` in plots and measurement scripts.

Secondly, we can use a tool that generates system load with configurable 
characteristics. Such experiment does not imitate real traffic as well as the 
`parallel-homogenous` variant, but the results might prove easier to interpret 
and reproduce. Moreover, the ability to configure the characteristics of the 
system load could help identify which kind of system load influences the 
measurement stability the most.

To create this kind of synthetic system loads, we will use the `stress-ng` 
utility, and along with that, we will run measurements of a single workload. In 
plots and measurement scripts, the names of these setups start with 
`parallel-synth`.

In order to examine the behavior of the system under varying levels of load, we 
will repeat the measurements with different amounts of workers running in 
parallel. The amounts of workers shall be chosen with regard to the topology of 
CPU cores so that they exercise all variants of cache utilization. For example, 
on a system with two dual-core CPUs with hyperthreading, we will want to run 1) 
a single process, 2) two processes (each uses one CPU cache), 3) four processes 
(two pairs of processes will share the last level cache) and 4) eight processes 
(one process per hyperthreading core). 

Launching more processes than there are hyperthreading cores might be an 
interesting experiment. Sadly, there is little value in it in for our 
experiment, because all these processes could not run in parallel at the same 
time and therefore, the total throughput would not increase. Such configurations 
would be viable if we included IO-bound workloads in our measurements -- we 
could have more parallel measurements than there are CPU threads, some of which 
could run while other threads wait for IO.

The parallel workers will be launched using GNU parallel[@Parallel], a 
relatively lightweight utility that simplifies the task of launching the same 
process N times in parallel with a variable parameter. There are numerous 
alternatives to parallel with negligible differences (considering our use-case). 
In future work, we might evaluate the possible advantages of using these.

### Choice of Workloads

TODO outline possible types of workloads -- CPU, memory, IO, network, unit-test 
like, parallel stuff, DNNs

We will concentrate on two basic groups of workloads -- CPU-bound and 
memory-bound. We expect that the runtimes of memory-bound tasks will be less 
stable due to factors such as cache and page misses (these effects are further 
amplified by virtualization technologies). Apart from that, there are factors 
that are detrimental even to the measurement stability of purely CPU-bound tasks 
-- for example, frequency scaling or sharing of CPU core components when 
hyperthreading is taking effect.

The workloads we selected for the experiment are:

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

The inputs are generated randomly using the `shuf` command from GNU coreutils. 
Typically, we generate sets of numbers from a given range, chosen with 
replacement. According to the documentation, `shuf` chooses the output numbers
with equal probabilities (sampling a uniform distribution with replacement).

The input sizes were chosen empirically so that the runtime of a single 
iteration is between 100 and 500 milliseconds. The main reason for this is that 
the time values reported by isolate are truncated to three decimal numbers and 
measurements of shorter workloads would be too granular. The iterations should 
not be too long either, because we measure multiple iterations using multiple 
isolation technologies, each under multiple setups, which totals to a 
substantial multiplicative factor on the total runtime. It is also noteworthy 
that most ReCodEx tests run in tens or hundreds of milliseconds.

TODO forward declaration of ReCodEx?

### Workload Languages

Most workloads will be implemented in C, which promises a relatively small 
overhead induced by the runtime environment (at least compared to managed 
languages).

TODO also Java and Python

### Measured Data

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

TODO perf statistics

## Hardware and OS Configuration

TODO needs more prose

Dell PowerEdge M1000e

- CPU: 2* Intel(R) Xeon(R) CPU E5-2630 v4 @ 2.20GHz (A total of 20 physical CPUs 
  with hyperthreading) in a NUMA setup
- Memory: 256GB DDR4 (8 DIMMs by 32GB) \@2400Mhz

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
