## Analysis

- description of ReCodEx, how machines are selected for jobs (headers etc.) TODO 
  this should be described earlier -- maybe at the start of the chapter? or make 
  a separate chapter?
- TODO should we justify this choice somehow? using it is a part of the thesis 
  assignment
- the most important thing is to minimize the waiting times for users
- TODO forward link to Docker section? it will justify some of our workload 
  choices (thanks to Docker, most workers know how to do everything)

### Requirements

Principally, there are two main performance metrics for scheduling algorithms: 
latency and throughput. Latency is important for interactive workloads and 
throughput is valued in batch workloads.

We consider giving feedback to students quickly the main benefit of a system for 
automated evaluation of programming assignments. Thus, optimizing latency should 
be preferred over optimizing throughput.

However, the acceptable latency varies with the processing time of the jobs. It 
is possible to delay jobs that take several minutes by a whole minute without a 
negative effect on the user experience, but the same cannot be said for jobs 
that take just a few seconds.

### Objective Function

Many different flavors of the online scheduling problem are studied. In this 
section, we explore currently researched objective functions to select one that 
aligns well with our requirements.

One of the most researched objectives in scheduling is the **makespan** -- the 
total time it takes to process a whole workload. This has an obvious correlation 
with the total throughput of the system, but individual jobs can be delayed for 
a long time.

The **flow time** is the time spent in the system for a job. Minimizing the sum 
of these times (or a weighted sum) might lead to more constrained delays for 
individual jobs, which would mean better response times for our system.

**Tardiness** of a job is defined as the difference between the completion time 
and the deadline. The usability of this metric depends on our choice of 
deadlines.

**Stretch** of a job is defined as the ratio between the time spent in the queue 
and the processing time. A benefit of this metric is that it accounts for the 
length of the job itself and therefore allows longer waiting times for long 
jobs.

### Experiment Methodology

- why simulation? we could bring the whole system up, but it would mean 
  measuring network delays and similar stuff too, which does not have anything 
  to do with the efficiency of scheduling 
