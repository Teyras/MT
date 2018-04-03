# Evaluation of Measurement Stability in Virtualized Environments

- The ability to measure time usage consistently is crucial for a fair 
  evaluation of submissions (and for a number of other applications in 
  performance evaluation as well)
- Virtualization eases building large-scale distributed applications that are 
  scalable (even on demand)
  - But it comes with an overhead, which is not a big problem if the added time 
    stays the same. It becomes a problem when the overhead is large enough to 
    "shadow" the results of our measurements. Therefore, we have to measure how 
    big the overhead is.
    - There are also non-deterministic factors at work here - multiple levels of 
      scheduling, virtual memory, interference with other VMs, ...
  - It might be possible to save money/energy if it proved feasible to measure 
    inside VMs
  - IaaS/PaaS providers offer little to no guarantee regarding the way the host 
    is utilized (source?)
  - Could virtualization also shield us from interference with other processes 
    on the same hardware? (can we measure a lot of stuff on the same machine 
    more reliably if we wrap it in VMs?)

## "Discussion"

- It might be possible to perform multiple (tens/hundreds) measurements for 
  every submission
- This could help eliminate outliers and give more reliable results
- The cost here is that the evaluation would take much more time, which leads to 
  higher utilization of the infrastructure and longer response time

## Measured Data

- The most important quantity is time
- CPU time is not dependent on external factors such as IO waits, which is why 
  it is often the first choice as a performance metric (even more so in ReCodEx)
- Wall clock time is inherently less stable, but necessary for some workloads 
  (heavily parallelized programs) -> we are primarily concerned with CPU time
- Memory usage should always be the same for low-level languages (without GC)
  - It would be interesting to see how garbage collected languages deal with 
    restricted space and how it affects the time
- As opposed to student submissions, we can modify the programs to "measure
  themselves" - we shall examine any potential discrepancies between these 
  results and the values reported by isolate

## Measured Workloads

- The workloads should be similar to what we can encounter in ReCodEx
- They will be measured under every combination of virtualization technologies,
  hardware configurations and synthetic stress workloads (stress-ng)

### Core Workloads

The following workloads serve to exercise small parts of the system so that we 
can observe the effects of virtualization in isolation. They will be implemented 
in C (closest to the metal).

- integer computations - gray code to binary
- float/double operations - approximation of exp()?

- random access memory reads - binary search
- memory reads and writes - sorting

- a synthetic workload where the ratio between memory and cpu usage can be 
  tuned, e.g. scrypt
  - we could also use stress-ng for this, provided that we specify a maximum for 
    each operation type so that we can compare the individual runs

### Non-essential Workloads

- a workload that employs more parts of the CPU (e.g. matrix multiplication)
- IO - merge sort in external memory
- some of the above in higher-level languages - Java, Mono, Python (most 
  frequently used in ReCodEx)

## Virtualization Environments

The stability of results will be compared with that of measurements on bare 
metal

- isolate (GNU/Linux) - used in ReCodEx
- docker (GNU/Linux) - most popular container platform
- virtualbox (GNU/Linux) - "home-level" virtualization technology
- vsphere - enterprise-grade technology

## Worker Configurations

We will try to simulate situations where multiple workers use the same server 
(that cannot be reasonably used by a single worker). This will be tested under 
different isolation technologies and all the workers will be isolated in the 
same way (bare processes/Linux containers/VMs/...)..

- one worker per logical CPU (assess the influence of hyperthreading)
- one worker per physical CPU
- one worker per two CPUs
- one worker per CPU group (assess the influence of L2 cache)

