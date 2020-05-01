## Related Work

In this section, we research online scheduling algorithms with respect to the 
categories listed in Section \ref{scheduling-categorization}.

In literature, online algorithms (those that only know a part of the input with 
each decision) are evaluated using a measure called the competitiveness ratio. 
For scheduling, the competitiveness ratio is defined as the ratio between the 
worst-case length of the schedule produced by the algorithm being evaluated and 
the worst-case length of the schedule produced by an optimal algorithm. This 
number is often relative to other factors such as the number of worker machines.

Since we are going to evaluate the algorithms experimentally, competitiveness 
ratios are not particularly interesting for us and we will not focus on them in 
our survey.

### Time and List Based Scheduling \label{time-vs-list-based-scheduling}

It seems that the time-based variant of the online scheduling problem is not 
very well researched, despite its practical applications. A heuristic approach 
for minimizing the makespan called OAGM (Online Algorithm based on Greedy 
algorithm and Machine preference) has been described[@HeuristicsScheduling] that 
uses a single queue of incoming jobs ordered by three criteria (the order is 
different for each worker):

- smallest label first (the label of a job on a particular worker is its
  position in a sequence of queued jobs, ordered by their processing times for
  the worker, smallest to largest),
- least flexibility job first (a job is less flexible than another if its 
  processing set is a proper subset of the processing set of the other job) and 
- longest processing time first.

Note that in the case of identical machines (a job takes the same time, 
regardless of the worker processing it), sorting by label degrades into sorting 
by shortest processing time. The other two rules will then only be used to break 
ties in that case.

If a job is due to be sent to an idle worker and there are multiple candidates, 
the job is sent to the worker with the smallest sum of processing times of 
queued jobs that can be processed by that worker. This number can be interpreted 
as a potential load factor of the worker.

This algorithm is expanded upon by a meta-heuristic algorithm (called meta-OAGM) 
that maintains a job queue for each worker and tries to iteratively improve the 
schedule by randomly moving jobs from the most loaded worker to another with a 
probability based on the load of each worker. This approach is based on 
simulated annealing, a probabilistic technique for approximating the global 
optimum of a function.

Most remaining literature is concerned with the list-based variant of the 
problem. We will survey the results in the following sections.

### Preemption

The main benefit of being able to interrupt running jobs is that we can pause a 
job in order to allow a shorter job to complete quickly. A basic algorithm for 
scheduling with preemption is SRPT -- Shortest Remaining Processing 
Time[@ValueOfPreemption]. The idea of this algorithm is that incoming jobs are 
placed into a queue ordered by expected time to completion. If a queued job has 
a lower expected time to completion than some job that is already being 
processed, the active job is interrupted, placed into the queue (with a 
decreased time to completion, because the worker has been processing it for some 
time), and the queued job is started instead. It is evident that this helps 
achieve a better flow time (and thus improves the latency of the system).

A drawback of the SRPT algorithm is that it does not take the cost of preemption 
into consideration. In ReCodEx, interrupting a job would require cancelling the 
current task, which means losing a certain amount of work -- even tens of 
seconds in some cases (e.g., costly compilation or measurement tasks). 
Additionally, it is difficult to predict this cost. A way to counteract this 
cost could be allowing some time before resuming an interrupted job so that 
additional short jobs can be scheduled in the meantime.

Schedulers in operating systems typically switch processses frequently to give 
each a fair share of the computing power (the time each process is alotted is 
called the quantum). This approach would be problematic with our implementation 
of job interruption -- long tasks could keep being interrupted repeatedly, 
causing an unnecessary delay of the job. However, we could still take 
inspiration from algorithms such as multi-level feedback queue scheduling, where 
processes that take long to process are gradually moved to queues with a lower 
priority and a longer quantum.

### Clairvoyance

It is evident that not knowing how long a job will take to process makes it much 
more difficult to schedule it efficiently, since we cannot calculate the exact 
load of a machine. Non-clairvoyance also disqualifies algorithms such as SRPT, 
that need to know the processing time. A similar algorithm, SETF -- Shortest 
Elapsed Time First exists for the preemptive case[@NonClairvoyantMeanSlowdown], 
that does not need to know the processing times. Naturally, this is also the 
case for scheduling algorithms used in operating systems, such as multi-level 
feedback queues.

For the semi-clairvoyant variant of the problem, where we only have approximate 
knowledge of the processing times, it has been shown that SRPT works reasonably 
well and a new algorithm similar to multi-level queues has been 
studied[@SemiClairvoyant].

### Processing Set Characteristics

In the case where the processing sets are arbitrary, it has been shown that an 
algorithm that assigns jobs to the least loaded eligible machine is close to 
being optimal[@CompetitivenessOnline] with respect to the total makespan.

An implicit requirement of this is that we must be able to estimate the job
processing times in order to determine which machine is the least loaded one.

For the case with nested processing sets, a makespan-minimizing
algorithm[@EqualProcessingEligibility] exists that requires the jobs to have 
equal processing times. The basic idea of the algorithm is scheduling the jobs 
with the least flexibility first. The flexibility of a job is defined as the 
number of workers in its processing set. This algorithm can be adapted to 
arbitrary processing sets as well, but we will not have any mathematically 
proven guarantees about its competitiveness (which does not hinder our intention 
to perform experimental evaluation).

For the case with interval processing sets, we have only found results for very 
specific instances of the problem (such as scheduling on exactly two machines) 
that cannot be used in our situation.

### Machine Characteristics

Most literature is concerned with the case where machines are identical, i.e., 
when a job takes the same time on any machine. In the case with related 
machines, an algorithm that assigns jobs to the slowest eligible machine first 
is described[@FlowTimeRelatedUnrelated].

### Job Deadlines

Earliest Deadline First is a well researched approach to scheduling with 
deadlines. It has been used extensively in the development of real time systems. 
Numerous other techniques have been found in this field, but they do not apply 
to our use case.

### Additional Approaches

The "Power of two choices" approach[@PowerOfTwoChoices] is a load balancing 
policy featured in the Nginx web server and reverse proxy. When a job is being 
assigned, two workers (upstream web servers) are selected at random and the job 
gets assigned to the one that is better according to some metric, for example 
the one with a lesser load factor.
