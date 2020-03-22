## Custom Algorithms

In this section, we explore the possibility of modifiyng two well-known online 
load balancing algorithms that could not be directly applied to our use case.

### Earliest Deadline First Approach \label{custom-edf}

Scheduling jobs in an order of increasing deadlines is frequently used in 
development of real time systems and other applications. In our situation, no 
deadlines are given explicitly. However, we can set a deadline based on the 
expected processing time of the job (an estimate based on recorded processing 
times of similar jobs) and allow additional time for longer jobs (based on the 
requirements on fast feedback described in Section 
\ref{scheduling-requirements}).

The formula to obtain a deadline is as follows:

- Time of arrival + the estimated processing time for jobs shorter than 15 
  seconds
- Time of arrival + the estimated processing time + 15 seconds for jobs shorter 
  than 45 seconds
- Time of arrival + twice the estimated processing time for jobs longer than 45 
  seconds

Deadlines set like this should ensure that short jobs are processed as soon as 
possible, but longer jobs do not wait in the queue indefinitely.

### Multi-level Feedback Queue Approach \label{custom-mlfq}

In its standard form, the multi-level feedback queue algorithm maintains 
multiple queues, each of which has a numeric level. Every incoming job is placed 
into the top-level queue. At some point, it is dequeued from the queue and a 
worker starts processing it. If it is not completed within a certain time period 
(the quantum), it is preempted and placed into a lower-level queue, which has a 
longer quantum. The jobs in the lower levels only get processed when the upper 
queues are empty.

A similar approach[@SemiClairvoyant] was presented for semi-clairvoyant 
scheduling with preemption on a single machine. Each job is assigned a level -- 
an integer $l$ such that the estimated processing time of the job is between 
$2^{l}$ and $2^{l + 1}$. At any given time, jobs from the lowest level are 
processed, with one exception: if there is a single partial job (a job that has 
been processed for a time but was preempted) in the second lowest level and no 
total jobs (jobs that have not yet been processed), it is processed first. While 
it is not straightforward to extend this approach to a setup with multiple 
machines, we can use the idea of leveraging semi-clairvoyance to improve the
multi-level feedback queue algorithm. As a side note, if we took away 
preemption, the algorithm would degrade to a simple shortest job first policy.

Standard multi-level feedback queue scheduling requires preemption to work. We 
propose a modification where jobs are assigned queue levels based on their 
estimated processing time (similarly to the aforementioned semi-clairvoyant 
algorithm). The resulting algorithm becomes similar to an older approach, 
multi-level queue scheduling, since we miss the feedback that a job failed to 
complete within the given time quantum. An obvious drawback of our modification 
is that it does not prevent starvation (a job being held in a queue 
indefinitely). In fact, the result is a slightly more convoluted shortest job 
first policy.

Our way to remedy this is by adjusting the way queues on different levels are 
processed. Instead of waiting for all the queues on higher levels to empty, we 
determine a share of processing time for each queue level. The queue manager 
keeps a history of recently dispatched jobs and selects queues for assignment in 
a way that the proportions of usage levels determined from the active queue 
levels are maintained.

This modification could prevent starvation for long-running jobs while 
maintaining a low response time for most short jobs. However, there are multiple 
parameters that need to be fine tuned: the exact boundaries for assigning jobs 
to queue levels, the weight of each level to be used to determine its share of 
processing time and the length of the dispatched job history to be kept.
