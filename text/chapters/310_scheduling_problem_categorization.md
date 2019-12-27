## Problem Categorization

Scheduling is the problem of assigning work units (jobs) to execution units 
(worker machines in our case). Every job has a processing set -- a set of 
machines that are capable of processing it. There are various subproblems with 
different requirements on the worker machines, processing set restrictions and 
other characteristics.

In this section, we list the subcategories of the scheduling problem that were 
studied in previous work. The categories are based on whether the problem is 
online or offline, on the characteristics of the worker machines and the 
processing sets of the jobs, the characteristics of deadlines and on the ability 
of the scheduler to interrupt jobs and estimate the processing times. Then, we
attempt to assign our use case to these categories. We shall use this knowledge 
to select the algorithms to be evaluated in subsequent experiments.

### Online/Offline Scheduling

In online scheduling, the algorithm does not have access to the whole input 
instance as it makes decisions[@SgallOnlineScheduling], as opposed to offline 
scheduling where the input is available immediately. This model is appropriate 
for our use case because we need to react to assignment submissions immediately.

Two variants of online scheduling are studied -- over list and over time. In 
scheduling over list, jobs are presented to the algorithm in a sequence. The 
scheduling decision has to be made immediately, it is irrevocable and after it 
is made, another job is presented to the algorithm.

In scheduling over time, jobs arrive on their release date and can be scheduled 
at any time after their arrival. The problem of scheduling assignment solutions 
to worker machines corresponds to the time-based variant -- jobs that enter the 
system can be held in a queue until a scheduling decision is made and other jobs 
might arrive in the meantime. However, an algorithm for list-based scheduling 
could also be used in an evaluation system without any problems.

### Preemption

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

We will mainly be concerned with the non-preemptive variant, but if it shows 
that preemption brings interesting benefits, it will also be considered.

### Clairvoyance

In the clairvoyant variant of the scheduling problem, the algorithm knows the 
exact processing time of each job on arrival. Naturally, this makes it possible 
to schedule jobs more efficiently. In the non-clairvoyant variant, the algorithm 
knows nothing about the processing times. A similar subcategory of the problem 
exists, where the algorithm has an estimate of the processing time. This is 
called semi-clairvoyant scheduling.

Typically, the longest part of job processing in ReCodEx is compilation and 
execution of code submitted by students. The time required for this is highly 
unpredictable -- there are submissions that fail to compile and therefore are 
evaluated very quickly, and there are those that run until they deplete the time 
limit. This is especially true for exercises in languages that allow 
pre-computing some values during compilation or feature complex compile time 
metaprogramming, such as C++.

Despite this fact, we might be able to estimate the processing time well enough 
e.g., by analysing runtimes of previous similar jobs. Therefore, we should 
definitely evaluate algorithms for the semi-clairvoyant variant, along with 
those for the non-clairvoyant variant.

### Processing Set Characteristics

Specialized algorithms exist that solve the online scheduling problem for jobs 
whose processing sets satisfy additional criteria.

The **Inclusive** variant requires the processing sets of any two jobs to be 
comparable (i.e., one must be a subset of the other). This is a criterion we 
cannot satisfy in case there are multiple specialized workers, such as one meant 
for GPU computations and another with a NUMA setup for parallel CPU 
computations. With a worker pool like this, jobs meant for either of the two 
specialized machines could not be processed on the other machine -- in other 
words, we would receive two disjoint processing sets.

In the **Nested** variant, the processing sets of every pair of jobs must be 
either disjoint (no common elements) or comparable. Such conditions could be 
achieved with special care by the administrator of the system. Without that, it 
could easily happen that there is for example a set of machines capable of 
evaluating highly parallelized submissions, another set of machines that can 
evaluate submissions in Java, and these sets have a non-trivial intersection. In 
this case, a pair of jobs where one requires a worker that can run parallel 
programs and the other needs a Java environment violates the criterion.

However, the requirements of the nested variant can be easily satisfied by a 
setup where there is a large pool of general purpose workers and a handful of 
specialized worker groups that do not accept any of the regular jobs. The 
requirements hold even when the general purpose group is composed of workers 
with different hardware groups (as described in TODO), provided that jobs that 
allow multiple hardware groups are not issued.

A set of machines satisfies the **Tree-hierarchical** criterion if it can be 
arranged into a tree so that the processing set of each job is a path from the 
root to some node. It follows that the machine in the root must be able to 
process any job. Sadly, we cannot guarantee these conditions.

A special case of the Tree-hierarchical variant exists that we mention for the 
sake of completeness. In this setup, the machines form a single chain and the 
processing set of every job is a segment of this chain that starts with the 
first node. This is called a **Grade of Service** processing set structure.

**Interval** processing sets require that the machines can be linearly ordered 
so that the processing set of any job is a continuous interval in this ordering. 
A setup with a general-purpose group of workers and multiple specialized groups 
where each job can be accepted exactly by the workers from one particular group 
satisfies this criterion. However, it would be difficult to determine whether or 
not the criterion holds under more complicated eligibility constraints (for 
example, if we wanted to filter the processing sets by additional criteria such 
as the allowed number of parallel threads).

For our purpose, we will mainly be looking for algorithms that allow arbitrary 
processing sets. We shall also consider interesting results for the nested and 
interval variants, even though these would impose restrictions on the pool of 
workers.

### Machine Characteristics

In a setup with **related** machines, each job takes the same time on all of the 
machines. In the **unrelated** case, the times can vary. For our problem, we 
should mainly be concerned with algorithms for the unrelated case, because our 
worker pool can contain machines of different processing power. However, 
restricting the processing sets of jobs to machines with the same speed is also 
a viable option.

### Job Deadlines

Although there are no inherent deadlines in the context of a programming 
assignment evaluation system, we could determine them e.g., using an estimated 
processing time of the jobs. This could help the subjective responsiveness of 
the system -- the scheduler could prioritize short jobs while allowing a longer 
waiting time for long jobs.

