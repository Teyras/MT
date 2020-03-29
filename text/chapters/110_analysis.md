## Analysis

To explore the influence of aforementioned factors on measurement stability, we 
shall measure a reasonable set of workloads under different execution setups 
with varying levels of system load and different isolation technologies.

### Inherent Stability-influencing Factors

The design of modern computers introduced numerous optimizations to increase the 
overall throughput of the system. Conversely, reproducible measurement of 
execution time is not a primary objective in the design of a contemporary 
processor. Therefore, there are many factors that increase the performance of a 
computer at the cost of introducing a certain level of non-determinism to time 
measurements.

Caching has a large influence on the performance of some operations and it 
happens on many levels during the execution of a program. In the case of 
evaluation of programming assignments, CPU cache and disk cache are the most 
important.

CPU cache exists to speed up accesses to frequently used areas of memory and it 
also helps during sequential reads of data (although most modern processors 
feature memory prefetchers whose influence is much larger in this case). 
Unfortunately, we have no control over the content of the cache when the program 
is launching. In addition, the cache is shared with other programs running on 
the machine, whose memory accesses cannot be controlled. Both of these facts 
make the time required for memory accesses less predictable, making the CPU 
cache a source of time measurement instability.

Disk cache (or page cache) is a mechanism for improving the speed of accesses to 
external memory (e.g., a HDD or SSD). Especially for HDDs, random accesses can 
be costly, which again introduces instability into time measurements. Although
exercises that require a substantial usage of external storage (such as sorting 
in external memory) should not base the grading on precise time measurements, 
the effects of page cache might also manifest in reading an input file or when 
the measured binary itself is being loaded. 

In a modern CPU, frequency scaling and power management (disabling inactive 
parts of the processor) take place to save energy when the system is idle. This 
becomes a problem when the system suddenly needs to start working after a period 
of inactivity. The frequency is typically not increased instantly, which can 
offset time measurements. Some of these features can be disabled to alleviate 
these effects.

Multiprocessing introduces another set of problems. Some parts of the CPU can 
become a bottleneck by not allowing simultaneous access for all cores that can 
be running in parallel -- the memory controller is an important example of this.

Also, the processes can contend for the CPU cache in multiple ways. For example, 
when two processes run on the same core, they can access the L3 cache in a 
pattern that makes each of them force the cached addresses of the other process 
out. This can also happen when one process is suspended by the scheduler to 
allow another process to run or when it is migrated to another core.

Languages that feature JIT (just in time compilation), such as C# or Java, can 
also suffer from measurement instability because of this. It is common practice 
when benchmarking these languages to let the benchmark warm up before starting 
the actual measurements. This way, the JIT compiler has a chance to optimize the 
critical parts and we do not have to account for the overhead of both running 
unoptimized code and performing the optimizations when we evaluate the results. 
This practice can also help in environments without JIT by populating the CPU 
caches and pre-loading the binary into the page cache.

### Isolation Technologies

The primary purpose of running submitted code in an isolated environment is to 
ensure that it will not damage the host system by excessively using its 
resources (e.g., memory or disk space), and that it will not bypass the 
restrictions on resource usage by communicating with the outside world (e.g., by 
reading results from other submissions or delegating work to network services). 
Additionally, some isolation technologies also provide accounting of resource 
usage, which is necessary for grading of submissions. 

In this section, we survey existing isolation technologies and select a handful 
whose effects on the stability of measurements will be examined. By intuition, 
any additional isolation layer adds overhead and therefore might make the time 
measurements less predictable. On the other hand, the opposite might also be 
true -- especially when there are multiple measurements running in parallel, 
process isolation could help stabilize the results.

#### UNIX chroot

The `chroot` system call (present in the UNIX specification since version 7, 
released in 1979) changes the root directory of the calling process[@Chroot], 
thus isolating it from the rest of the system and preventing it from accessing 
files not needed for assignment evaluation. Historically, this has been used as 
an additional layer of security for services that handle potentionally dangerous 
input such as web servers.

Chroot itself however does neither limit resource usage nor provide accounting. 
Inter-process communication and network access are also not limited.

#### Debugger-based Isolation

`ptrace` is the UNIX interface primarily used by userspace debuggers. It can 
also be used to intercept system calls to achieve process isolation. By 
combining this with `chroot` and a resource limiting call such as `ulimit`, a 
full-fledged sandbox can be created.

The MO system for evaluation of submissions in programming contests features a 
sandbox like this[@MaresPerspectives]. The same sandbox was also used in CodEx 
(a programming assignment evaluator released in 2006) and the CMS contest 
management system [@CMS].

A notable problem of this approach is that it does not work well with 
multithreaded programs. The `ptrace` interface only suspends the main thread on 
system calls. Therefore, a sandbox with multithreading support would have to 
intercept calls that spawn new threads and start monitoring them too. Such 
approach would however introduce a host of new problems and attack surfaces. For 
example, it would be possible to spawn two threads, A and B, where A performs a 
permissible system call and B changes the context of thread A before the system 
call is actually executed, but after the sandbox is done inspecting it.

#### FreeBSD Jails

Jails[@FreeBSDJail] (featured since 2000) expand on the concept of chroots. In 
addition to confining a process to a part of the filesystem, they also provide 
network and process isolation and time, memory, and disk usage 
limits[@FreeBSDRLimit].

Many other UNIX systems also have their own implementations of jails, e.g., 
zones in Solaris or sysjail in OpenBSD and NetBSD.

#### Linux Containers

The Linux kernel supports creating containers -- lightweight execution units 
that can be used for isolation and resource limiting.

Process isolation can be achieved using namespaces[@LinuxNamespacesCommit], a 
feature present in the kernel since 2006. These allow locking the process in an 
environment where communication methods such as networking or reading files 
seemingly works without restrictions, but the sandboxed process can only 
communicate with processes in the same namespaces (granular sharing is also 
possible to allow e.g., connecting to services over the Internet).

Resource limiting and usage accounting is implemented using control groups 
(cgroups)[@LinuxCgroupsLWN], merged into the kernel in 2007.

It can be reasoned that these measures should not have any noticeable overhead, 
at least compared to processes running in the global process namespace and 
cgroup -- in modern versions of Linux, the same restriction mechanisms are used 
in any case, even when no isolation is desired and no additional namespaces and 
cgroups are created by the user.

Linux containers have been adopted by many projects, some of which we list here:

- **Docker**[@Docker], which is the most prominent container technology as of 
  now. It provides means for building images (templates for creating 
  containers), transferring them between hosts via Docker Registry, creating 
  containers based on the images and running programs in them. Docker is based 
  on an open source project called Moby, which implements a number of 
  specifications authored by the OCI (Open Containers Initiative)[@OCI], mainly 
  the Runtime Specification (which describes how to run a container from a local 
  filesystem) and the Image Specification (which describes the format of image 
  data and metadata). Over time, projects that provide alternative 
  implementations for parts of the OCI-specified functionality have emerged, 
  such as Podman[@Podman] or Buildah[@Buildah]. The main use case supported by 
  Docker is deployment of applications or services as containers, as opposed to 
  projects that use containers as lightweight virtual machines. This choice has 
  many consequences in the way Docker is used -- for example, data persistence 
  must be set up explicitly by binding paths in the host file system into the 
  container.
- **LXC**[@LXC] (an abbreviation of "Linux Containers") provides a usage flow 
  that is more similar to the traditional virtual machine computation model -- a 
  template is downloaded and used to create a container, which is a fully 
  functional operating system that uses the kernel of the host. Users can then 
  attach to this container and run commands inside it like they would in a 
  virtual machine or a remote server. At the inception of the project, Docker 
  used LXC as its backend for running containers.
- **Isolate**[@MaresIsolate] is a minimalistic wrapper around cgroups, 
  namespaces and other resource limiting facilities provided by Linux. It was 
  designed for running and measuring resource usage of untrusted code in 
  programming contests and homework assignment evaluation.
- **Singularity**[@Singularity] is an effort to bring user-defined software 
  stacks to systems for high-performance computing. It uses Linux namespaces to 
  isolate executed code. It can also integrate with resource managers such as 
  Slurm, which is not a typical use case for Docker, for example. However, OCI 
  images can be used as a base for Singularity images.
- **Charliecloud**[@Charliecloud] is a set of scripts for running Docker images 
  on existing infrastructure with minimal alterations, without the Docker daemon 
  itself. It does however use Linux namespaces for isolation.

As a side note, there were efforts to implement container support in Linux even 
before the inception of namespaces and cgroups. Possibly the most widely adopted 
one was OpenVZ[@OpenVZ] (released in 2005, based on commercial Virtuozzo
from 2000). It shipped a modified Linux kernel that enabled container isolation 
and also provided hardware virtualization support in later versions.

#### Virtualization and Paravirtualization

Virtualization allows to run multiple guest operating systems on a single 
physical host without modifying them. The guests then operate under an illusion 
that they are running alone on a physical machine[@IntelVirtualization].

The virtualization is enabled by having a virtual machine monitor (commonly 
called the hypervisor) installed in the host system. There are multiple ways of 
running the code of the virtual machine, but in all of them, it is desirable to 
run as many instructions directly, without any intervention from the hypervisor.
However, for some instructions, this is not possible -- for example, memory 
access instructions can have a multitude of possible side effects, such as 
triggering memory-mapped IO or page table modifications. This can be handled in 
a variety of ways, like trapping these instructions and emulating them, 
dynamically translating them to different instructions or exploiting 
infrastructure for virtualization provided by CPU manufacturers.

Paravirtualization requires the guest operating system to be modified to avoid 
emulation of some instructions. For example, a block device driver can be 
implemented by directly calling the virtual machine monitor on the host which 
can keep the data from an emulated drive in a file or in memory. Xen[@Xen] is 
one of the most prominent paravirtualization technologies.

It is evident that these mechanisms can affect measurement stability. The effect 
can be either negative, because the virtualization could introduce additional 
non-deterministic factors into the measurements, or positive -- the virtualized 
equivalents of IO operations, for example, might prove to be more stable than 
the actual operations.

#### The Selection for our Measurements

From the survey of possible approaches to process isolation, we have selected 
the following technologies for our measurements:

- Bare metal (**B**) -- no isolation at all (used as a baseline value).
- Isolate (**I**) -- a sandbox solution used in ReCodEx and other systems (such 
  as CMS or Kattis[@Kattis])
- Docker (**D**) -- the most popular container platform as of today.
- Isolate in Docker (**D+I**) -- a combination that might be used to support 
  user-supplied runtime environments in ReCodEx. Isolate might still be 
  necessary to protect the insides of the container from the code supplied by 
  students (an attacker that gains control of the container could e.g., report 
  any grades they like to the rest of the system) and to measure resource usage.
- VirtualBox (**V**) -- a readily available virtualization solution that does 
  not need extensive setup. We will manage our VMs using Vagrant so that we can 
  easily take measurements of other virtualization platforms in the future.
- Isolate in VirtualBox (**V+I**) -- the reasoning for adding isolate is the 
  same as with Docker.

An important deciding factor in the selection of isolation technologies was the 
adoption of GNU/Linux, both in the field of programming contests and internet 
servers in general. In addition, ReCodEx, while being built to also support 
measurements on Windows, primarily uses GNU/Linux. Unfortunately, this choice 
disqualifies technologies like FreeBSD jails. On the other hand, these are 
conceptually very similar to Linux containers.

The measured data will be compared to values measured on the bare metal. 
Measurements will also be performed with manually configured CPU affinities to 
see if such configuration has any effect on the stability of time measurements. 
Setting the affinity for VirtualBox VMs is very difficult when parallel 
processes are involved, so this setup will not be included in the experiment.

The Linux kernel also allows setting per-process NUMA affinity, which determines 
which memory nodes should be used by the process. Restricting a process to the 
memory node that belongs to the CPU where it is running is certainly reasonable. 
Since this restriction is the default policy in Linux[@NumaMemPolicy], we will 
not measure the setup where the CPU affinity is already set explicitly. However, 
we will experiment with setting the NUMA affinity without an explicit CPU 
affinity (i.e., restricting a process to a memory node and not to a CPU).

### Execution Setups

There are multiple ways of simulating measurements on a machine where other 
processes are running. First, we can run multiple instances of the measurements 
of the same exercise type in parallel. While it might seem like an artificial 
situation, it is actually a likely scenario -- it often happens that multiple 
students start submitting solutions to the same assignment at the same time (for 
example when the deadline is close). This execution setup type is called 
`parallel-homogeneous` in plots and measurement scripts.

Second, we can use a tool that generates system load with configurable 
characteristics. Such experiment does not imitate real traffic as well as the 
`parallel-homogeneous` variant, but the results might prove easier to interpret 
and reproduce. Moreover, the ability to configure the characteristics of the 
system load could help identify which kind of system load influences the 
measurement stability the most.

To implement this type of execution setups, we will use the 
`stress-ng`[@StressNG] utility, and along with that, we will run measurements of 
a single exercise type. In plots and measurement scripts, the names of these 
setups start with `parallel-synth`.

In order to examine the behavior of the system under varying levels of system 
load, we will repeat the measurements with different amounts of workers running 
in parallel. The amounts of workers shall be chosen with regard to the topology 
of CPU cores so that they exercise all variants of cache utilization. For 
example, on a system with two dual-core CPUs where each physical core has two 
logical cores, we will want to run:

1) a single process, 
2) two processes (each uses one CPU cache), 
3) four processes (one per physical core, two pairs of processes will share the 
   last level cache) and 
4) eight processes (one process per logical core, i.e., exploiting the logical 
   cores). 

Launching more processes than there are logical cores might be an interesting 
experiment. Sadly, there is little value in it in for our research, because all 
these processes could not run in parallel at the same time and therefore, the 
total throughput would not increase. Such configurations would be viable if we 
included IO-bound workloads in our measurements -- we could have more parallel 
measurements than there are CPU threads, some of which could run while other 
threads wait for IO.

The parallel workers will be launched using GNU parallel[@Parallel], a 
relatively lightweight utility that simplifies the task of launching the same 
process N times in parallel with a variable parameter. There are numerous 
alternatives to parallel with negligible differences, at least considering our 
use-case where we simply need to launch a fixed number of commands 
simultaneously on the same machine. Nonetheless, we shall make sure that the 
measurements did in fact run in parallel in the evaluation of results.

Throughout the text, we understand "execution setup" as a union of execution 
setup type (e.g., `parallel-homogeneous`) and system load level (the number of 
parallel workers).

### Choice of Measured Assignment Types

There are numerous types of programming assignments suitable for automated 
evaluation that differ in their characteristics and requirements. We mostly 
differentiate them by the bounding factor in their performance -- the speed of 
the CPU, memory accesses or IO operations.

The performance of CPU-bound programs is primarily limited by the speed at which 
the procesor can execute instructions. An example of this class are exercises 
that require students to perform a computation with small input data, such as 
iterative approximation of values of mathematical functions.

In memory-bound programs, the performance is limited by the speed of memory 
accesses. This can manifest in common tasks such as binary search or reduce-type 
operations such as summing.

Both CPU-bound and memory-bound tasks can be easily graded with respect to 
either processor time or wall-clock time. However, there are classes of tasks 
where selecting an appropriate grading criterion is more complicated.

IO-bound programs (e.g., external sorting) are limited by the speed of accesses 
to external memory, such as HDDs or network resources. Due to the inherent 
instability of access time of external memory, such tasks are hard to measure 
reliably. Since we need to account for time taken by waiting for IO, CPU time 
cannot be used for grading this class -- an efficient solution will need to work 
with the external memory in a way that minimizes the IO wait time, which is not 
included in CPU time (but it is included in wall-clock time).

Exercises in parallel computing (both CPU and GPU based) mostly fall into the 
CPU and memory-bound categories, but, like in the IO-bound case, we cannot use 
CPU time to grade them -- the CPU time of a multithreaded program is the sum of 
the CPU times of its threads. Therefore, we cannot use it to measure the speedup 
gained from parallelization and we are left with wall-clock time. Moreover, we 
can expect a larger time measurement instability due to the inherent 
non-determinism of scheduling of multiple threads.

Many assignments are not at all concerned with the performance of the submission 
and only check its correctness. For those, the evaluation process is similar to 
unit testing. A de-facto subclass of these assignments are those where the 
solution is not a computer program in the classical sense -- for example, some 
courses require the students to train and submit a neural network that reaches 
some level of accuraccy on a chosen dataset. Usually, the processing time is not 
interesting in such assignments, even though it is still necessary to limit it 
to avoid leaving the evaluation system stuck in an infinite loop.

We will concentrate on two basic groups of workloads -- CPU-bound and 
memory-bound. We expect that the runtimes of memory-bound tasks will be less 
stable due to factors such as cache and page misses (these effects are further 
amplified by virtualization technologies). Apart from that, there are factors 
that are detrimental even to the measurement stability of purely CPU-bound tasks 
-- for example, frequency scaling, context switching or sharing of CPU core 
units when logical cores are being used.

We excluded exercises that are IO-bound or use parallel computing from our 
analysis. IO-bound tasks are difficult to run in parallel because of shared 
access to external memory. Also, there are many factors to take into account 
when running them in a virtualized environment, making their evaluation too 
complicated for this experiment. Parallel tasks typically require a dedicated 
machine with a multicore CPU that should not be used by other measurements. 
Finally, we do not have to be concerned with the stability of measurements for 
assignments that are not graded with respect to measured time.

It is also worth noting that being CPU or memory bound is a characteristic of 
the submitted program and not the assignment. In many tasks, the students can 
choose the degree of the memory-speed tradeoff they want to make (for example, 
the number of intermediate results stored in a lookup table to avoid 
recalculation). Also, students might choose to solve problems intended e.g., as 
CPU-bound with memory-bound programs.

The exercise types we selected for the experiment are:

- `exp`: Approximation of $e^x$ using the $(1 + \frac{x}{n})^n$ formula with $x$ 
  and $n$ as integer parameters that are read from the memory. The calculation 
  itself only uses two integer variables (the parameters) and one float variable 
  (the result). We can expect they will probably stay in CPU registers for most 
  of the execution time. 16384 iterations with pre-generated inputs (`x` and 
  `n`) loaded into memory are performed. This way, the workload tests floating 
  point operations with inputs being read sequentially from the memory.
- `gray2bin`: Conversion of numbers in an in-memory array from Gray code to 
  binary. This workload measures the performance of integer operations while 
  inputs are being read sequentially from the memory.
- `bsearch`: A series of binary searches in a large integer array in the memory. 
  This workload tests random access memory reads, which is a very common memory 
  access scheme in both real-world and synthetic workloads.
- `sort`: Sorting a large integer array in the memory using both the insertion 
  sort and quicksort algorithms. This workload tests a combination of random
  access and sequential memory reads and writes. This memory access scheme is 
  also common in many real-world and synthetic workloads.

The inputs are generated randomly using the `shuf` command from GNU coreutils. 
Typically, we generate sets of numbers from a given range, chosen with 
replacement. According to the documentation, `shuf` chooses the output numbers
with equal probabilities (sampling a uniform distribution with replacement).

The input sizes were chosen empirically so that the runtime of a single 
iteration is between 100 and 500 milliseconds. The main reason for this is that 
the time values reported by `isolate` are truncated to three decimal numbers and 
measurements of short workloads would often falsely seem equal to each other due 
to rounding/truncation of decimals. The iterations should not be too long 
either, because we measure multiple iterations using multiple isolation 
technologies, each under multiple execution setups, which totals to a 
substantial multiplicative factor on the total runtime. It is also noteworthy 
that most ReCodEx tests run in tens or hundreds of milliseconds.

The input sizes are as follows:

- `exp`: 65536 random exponents between 0 and 32 with `n=1000` (performed with 
  both `float` and `double` data types)
- `gray2bin`: 1048576 random 32-bit integers
- `bsearch`: 1048576 lookups in a 65536-item array of 32-bit integers
- `sort/insertion_sort`: 16384 32-bit integers
- `sort/qsort`: 1048576 32-bit integers

### Exercise Workload Languages

The core exercises for our experiments shall be implemented in a compiled, 
low-level language. Such languages should have a relatively small overhead 
induced by the runtime environment (at least compared to managed languages with 
features such as garbage collection and JIT compilation).

The most frequently used language in this category as of today is C/C++. 
Languages such as Fortran, Pascal and Rust could also be considered.
We exclude functional languages such as Haskell or OCaml since they operate on a 
level of abstraction different than that of imperative languages and it could 
prove difficult to understand how exactly is the code going to be compiled and 
executed by the CPU. Go is excluded because it features a non-trivial runtime 
with garbage collection. 

For the core exercise types, we selected C as the implementation language. 
Pascal and Fortran, respectively, are sometimes used in programmer education and 
scientific computations, but they are not known to the general public as much as 
C or C++. Rust is a relatively new language that is still evolving rather 
rapidly. Although it promises memory and concurrency safety thanks to its type 
system, there are not many ways we could exploit this in our workloads. Also, 
the adoption is still rather small.

C++ has a multitude of features compared to C, such as type-safe collections and 
support for namespaces, object oriented programming and template 
metaprogramming. Its standard library is also much larger. However, the argument 
that applies to Rust holds here too -- our exercises are too trivial to benefit 
from these features significantly (although templates could make for marginally 
cleaner code in the `exp` exercise workload). Also, using collections from the 
standard library could make the measured code harder to reason about in terms of 
how it will be executed. The final argument for C is that it is still used in 
many introductory programming courses.

Although a comprehensive study of measurement stability among a large set of 
programming languages is out of scope of this thesis, it is important to measure 
with more than one language because computer science programs at universities 
typically cover more than one.

Admittedly, most courses concerned with the precision of measurements will use 
low-level languages where we can expect that the measurement stability will be 
similar to C. However, finding that some class of languages performs poorly in 
terms of measurement stability would raise a major concern.

We will include a quicksort implementation in Java and Python to see how the 
stability of measurements is affected by the implementation language. The reason 
for choosing Java is that it is a language with garbage collection and JIT 
compilation and it is used in many courses on object-oriented programming. 
Python on the other hand is a scripting language with many use cases ranging 
from web development to machine learning. It is also used by introductory 
programming courses at many universities.

The exercises implemented in Java and Python took much longer per iteration, 
making the total runtime of the experiment impractical. Therefore, we chose to 
reduce the input size to 131072 items ($\frac{1}{8}$ of the original size) in 
order to make their runtime closer to that of the C implementation. This is not 
a concern since we are not aiming to compare the performance of the 
implementations anyway.

### Measured Data \label{measured-data}

ReCodEx uses CPU and wall clock time measurements reported by isolate. 
Therefore, the stability of these values is the most important result of our 
experiment.

Our workloads are also instrumented manually to measure and report the runtime 
of the solution (minus the initialization and finalization time of the program) 
using the `clock_gettime` call. `CLOCK_PROCESS_CPUTIME_ID` is used to measure 
CPU time and `CLOCK_REALTIME` is used for wall clock time.

This instrumentation is necessary because some isolation technologies cannot 
provide us with measurements from isolate (in fact, a half of them does not use 
isolate at all), yet we want to use these technologies in our comparison. 
Measuring all this data also lets us examine the overhead caused by isolate and 
any potential discrepancies between the values.

Along with the measurements themselves, we will collect performance data using 
the `perf` tool that provides access to performance counters in the Linux 
kernel. We will focus on events that are known to cause unstable runtimes, such 
as cache misses and page faults (although our workloads are not very likely to 
generate a notable amount of page faults). The measurements with `perf` enabled 
will be run separately to make sure that the profiling does not influence our 
results. With this data, we will have a better insight into the causes of 
potential unstable measurements.

The exact counted events are:

- `L1-dcache-loads` -- loads from the L1 data cache
- `L1-dcache-misses` -- unsuccessful loads from the L1 data cache
- `LLC-stores` -- stores to the last level cache (shared by all cores)
- `LLC-store-misses` -- memory stores that resulted into a write to the memory 
  (instead of just altering the cache)
- `LLC-loads` -- loads from the last level cache
- `LLC-load-misses` -- unsuccessful loads from the last level cache that led to 
  a memory load
- `page-faults` -- memory loads that led to a page walk

For some workloads, it might be interesting to observe disk-related metrics such 
as latency. However, the computational workloads we measure are not likely to be 
influenced by such factors. Also, this kind of events does not seem to be 
supported by perf to our best knowledge. 

## Hardware and OS Configuration \label{hw-and-os}

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
- CPU frequency scaling governor is set to `performance`
- kernel address space randomization is disabled
- transparent hugepage support is disabled

There are two ways of distributing the measured exercises over CPU cores when 
measuring with `taskset`. Both are implemented by the `distribute_workers.sh` 
script. The main idea (shared by both of these approaches) is that the numbers 
of parallel workers running on each physical CPU should be balanced. The same 
should apply to logical cores in a physical CPU.

The first approach to workload distribution is illustrated in Figure
\ref{taskset-naive}. Each workload is assigned to a single core and using two 
logical cores on the same physical core is avoided as long as possible. Which 
exact cores are chosen is not important, because the only layer of cache shared 
by the cores is the last level cache, which is shared by all the cores.

The other approach is illustrated in Figure \ref{taskset-multi}. It tries to 
divide the CPU cores into equally-sized sets where logical cores that belong to 
the same physical core always belong to the same set.

The `distribute_workers.sh` script might require adjustments if we try to 
replicate this experiment on other CPUs with different topologies - in other 
words, it does not attempt to cover all possible CPU configurations.

![Placement of 10 measurements on our CPU cores using the fixed affinity setting 
policy \label{taskset-naive}](img/stability/cpu-layout-taskset-naive.tex)
![Placement of 8 measurements on our CPU cores using the multi-core affinity 
setting policy \label{taskset-multi}](img/stability/cpu-layout-taskset-multi.tex)
