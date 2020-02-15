## Analysis

- TODO forward link to Docker section? it will justify some of our workload 
  choices (thanks to Docker, most workers know how to do everything)

### Requirements \label{scheduling-requirements}

Principally, there are two main performance metrics for scheduling algorithms: 
latency and throughput. Latency is important for interactive workloads and 
throughput is valued in batch workloads.

We consider giving feedback to students quickly the main benefit of a system for 
automated evaluation of programming assignments. Thus, optimizing latency should 
be preferred over optimizing throughput (but we should be vary of algorithms 
that grant a small improvement of latency at the cost of a large negative effect 
on throughput).

However, the acceptable latency varies with the processing time of the jobs. It 
is possible to delay jobs that take several minutes by a whole minute without a 
negative effect on the user experience, but the same cannot be said for jobs 
that take just a few seconds.

The time a user is willing to wait for an evaluation to finish is rather 
difficult to estimate. For a regular web page, the tolerable response time is 
about 5-10 seconds[@WaitingTimeStudy]. In our case, the motivation to see the 
results is higher than for a web page, which implies that the user might be 
willing to wait longer. Also, it is reported that providing the user with a 
progress feedback prolongs the tolerable waiting time (between 15-46 seconds).

In ReCodEx, the user receives information about the progress after the 
evaluation starts, but not while the solution is waiting in a queue. We could 
however provide the users with the number of solutions in the queue and an 
estimate of the waiting time for a better user experience.

Despite this, if an evaluation takes more than a minute to finish (including the 
queue time), it is unlikely that a user will wait for it -- it is more likely 
they will switch to a different task and return to see the results later. 
Therefore, we should strive to keep the queue time in jobs that take tens of 
seconds short, even if it means postponing longer jobs by minutes.

### Objective Function

Many different flavors of the online scheduling problem are studied. In this 
section, we explore currently researched objective functions to select those
that align well with our requirements. Surveying the objective functions is also 
important for researching prior art, since literature typically focuses on the 
optimization of a single metric.

One of the most researched objectives in scheduling is the **makespan** -- the 
total time it takes to process a whole workload. This has an obvious correlation 
with the total throughput of the system, but individual jobs can be delayed for 
a long time.

The **flow time** is the time spent in the system for a job. Minimizing the sum 
of these times (or a weighted sum) might lead to more constrained delays for 
individual jobs, which would mean better response times for our system.

**Tardiness** of a job is defined as the difference between the completion time 
and the deadline. The usability of this metric depends on our choice of 
deadlines. Tardiness seems similar to latency, but it is often used in 
literature about scheduling. When discussing this particular objective function, 
we prefer using tardiness instead of latency throughout this text. Typically, an 
aggregate of tardiness over all jobs (such as the arithmetic mean) is used to 
evaluate scheduling algorithms.

**Stretch** of a job is defined as the ratio between the time spent in the queue 
and the processing time. A benefit of this metric is that it accounts for the 
length of the job itself and therefore allows longer waiting times for long 
jobs. Exactly like in the case of tardiness, an aggregate of the stretches of 
all jobs is used to compare scheduling algorithms.

It would also be possible to define a custom metric based on a function of the 
processing time and queue time that captures the aforementioned requirements on 
the wait time for users based on the processing time of the job. However, this 
can also be achieved by setting appropriate deadlines and using the tardiness of 
jobs as a metric.

From our list of metrics, we see that the flow time, tardiness and stretch are 
all closely related to the latency, as opposed to the makespan, which 
corresponds to the throughput.

When researching the problem in literature, we should be primarily concerned 
with the first group (focused on latency). In experimental evaluation, we should 
observe both the makespan and some subset of the metrics related to latency.

### Experiment Methodology

To select the right scheduling algorithm, we will perform an experimental 
evaluation. In this section, we attempt to find the optimal methodology for such 
an experiment.

We shall observe the selected metrics for each algorithm so that we can compare 
their performance. Each algorithm will be evaluated on a set of workloads -- 
sequences of jobs with timestamps that specify when they should be presented to 
the system. The experiment will also be repeated on multiple sets of workers 
with varying sizes to get a better understanding of how the algorithms handle 
larger worker pools.

Since this text is mainly motivated by the ReCodEx system, we shall use parts of 
it in our experiment. The main benefit of this is that it already has a clearly 
defined API for queue management. We can use this to lessen the amount of 
programming needed to create a testing environment. Moreover, using the queue 
management API in ReCodEx lets us incorporate the best scheduling algorithms 
into the system after we finish our evaluation.

For an easily reproducible experiment, we should use some degree of simulation 
to avoid setting up the entirety of the ReCodEx system, along with writing a 
script that submits jobs to the system at scheduled times. Another problem of 
measuring with the whole system up is that the results would contain noise 
unrelated to the efficiency of the load balancing algorithm, such as delays 
caused by network communication.

Our experiment will be performed by a script that directly uses the scheduling 
code of the ReCodEx broker and simulates incoming jobs based on a structured 
description. The script will also support configuring the set of worker 
machines.
