## Related Work

### Problem Categorization

Scheduling is the problem of assigning work units (jobs) to execution units 
(worker machines in our case). Every job has a processing set -- a set of 
machines that are capable of processing it. There are various subproblems with 
different objectives, processing set restrictions and other characteristics.

#### Online/Offline Scheduling

In online scheduling, the algorithm does not have access to the whole input 
instance as it makes decisions[@SgallOnlineScheduling]. This model is 
appropriate for our use case because we need to react to assignment submissions 
immediately.

Two variants of online scheduling are studied -- over list and over time. In the 
former, jobs are presented to the algorithm in a sequence where the next job is 
unknown until the current one is scheduled. In the latter, jobs arrive on their 
release date and can be scheduled at any time after their arrival. Our problem 
corresponds to the time-based variant.

#### Preemption

The ability to interrupt long-running jobs is very useful in scheduling 
algorithms. When it is not available, situations where a machine needed by a 
specialized job is blocked by a particularly long job that could have been 
processed somewhere else can easily arise.

At this moment, preemption is not supported by ReCodEx. The difficulty of 
implementing it depends largely on the exact requirements on the guarantees 
provided by the interruption operation.

A simple cancellation of the current job is a rather simple feature to add, but 
without being able to resume it, it is certain we will lose progress, which 
could be a substantial setback for long-running jobs. Our scheduling algorithm 
would also have to make sure that a job cannot be interrupted ad infinum.

With little added effort, we could let the worker machines keep the state of 
interrupted jobs, which would prevent losing all of the progress. For example, 
if the submitted program is run against multiple test inputs, we could keep the 
results of measurements that are already finished. However, we could still lose 
a substantial amount of time by interrupting a measurement. Moreover, the job 
would have to be resumed on the same machine (and the scheduler would need to 
keep track of the fact).

Suspending measurements so that they can be resumed immediately would be a 
challenging task due to its possible impact on measurement stability.

To sum up, we will mainly be concerned with the non-preemptive variant, but if 
it shows that preemption brings some interesting benefits, we will consider it 
too.

#### Clairvoyance

In the clairvoyant variant of the scheduling problem, the algorithm knows the 
exact processing time of each job on arrival. Naturally, this makes it possible 
to schedule jobs more efficiently. In the non-clairvoyant variant, the algorithm 
knows nothing about the processing times. A middle ground exists, where the 
algorithm has an estimate of the processing time. This is called 
semi-clairvoyant scheduling.

Typically, the longest part of job processing in ReCodEx is compilation and 
execution of code submitted by students. The time required for this is highly 
unpredictable -- there are submissions that fail to compile and therefore are 
evaluated very quickly, and there are those that run until they deplete the time 
limit.

Despite this fact, we might be able to estimate the processing time well enough 
e.g. by analysing runtimes of previous similar jobs. Therefore, we should 
definitely evaluate algorithms for the semi-clairvoyant variant.

#### Processing Set Characteristics

Specialized algorithms exist that solve the online scheduling problem for jobs 
whose processing sets satisfy additional criteria.

The **Inclusive** variant requires the processing sets of every two jobs to be 
comparable (i.e. one must be a subset of the other). This is a criterion we 
cannot satisfy in case there are multiple specialized workers, such as one meant 
for GPU computations and another with a NUMA setup for parallel CPU 
computations.

In the **Nested** variant, the processing sets of every pair of jobs must be 
either disjoint (no common elements) or comparable. Such conditions could be 
achieved with special care by the administrator of the system. Without that, it 
could easily happen that there is e.g. a set of machines capable of evaluating 
highly parallelized submissions, another set of machines that can evaluate 
submissions in Java, and these sets have a non-trivial intersection. In this 
case, a pair of jobs where one requires a worker that can run parallel programs 
and the other needs a Java environment violates the criterion.

A set of machines satisfies the **Tree-hierarchical** criterion if it can be 
arranged into a tree so that the processing set of each job is a path from the 
root to some node. It follows that the machine in the root must be able to 
process any job. Sadly, we cannot guarantee these conditions.

**Interval** processing sets require that the machines can be linearly ordered 
so that the processing set of any job is a continuous interval in this ordering. 
It is possible this could be achieved with care from the administrator.

TODO examine this better

#### Objective

### Past Research

### Existing Algorithms
