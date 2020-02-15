## Custom Algorithms

In this section, we present two online load-balancing algorithms created by a 
modification of well-known algorithms that could not be applied directly for our 
use case.

### Earliest Deadline First Approach \label{custom-edf}

Scheduling jobs in an order of increasing deadlines is frequently used in 
development of real time systems and other applications. In our situation, no 
deadlines are given explicitly. However, we can set a deadline based on the 
expected processing time of the job (an estimate based on recorded processing 
times of similar jobs) and allow additional time for longer jobs (based on the 
requirements on fast feedback described in Section 
\ref{scheduling-requirements}).

TODO the exact formula

### Multi-level Feedback Queue Approach \label{custom-mlfq}

In its standard form, the multi-level feedback queue algorithm maintains 
multiple queues, each of which has a numeric level. Every incoming job is placed 
into the top-level queue. At some point, it is dequeued from the queue and a 
worker starts processing it. If it is not completed within a certain time period 
(the quantum), it is preempted and placed into a lower-level queue, which has a 
longer quantum. The jobs in the lower levels only get processed when the upper 
queues are empty.

The algorithm requires preemption to work. We propose a modification where jobs 
are assigned queue levels based on their estimated processing time. The 
resulting algorithm becomes similar to an older approach, multi-level queue 
scheduling. An obvious drawback of our modification is that it does not prevent 
starvation (a job being held in a queue indefinitely). Our way to remedy this is 
by adjusting the way queues on different levels are processed. Instead of 
waiting for all the queues on higher levels to empty, we will dequeue jobs from 
lower queues less frequently than from those on upper levels.

TODO exact number of queues (possibly 3), proportions, etc.
