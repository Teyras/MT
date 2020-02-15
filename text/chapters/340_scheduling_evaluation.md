## Evaluation

Our survey of scheduling algorithms provided us with a variety of possible 
approaches that we will proceed to evaluate. We decided to exclude algorithms 
that require preemption (such as SRPT and SETF), because implementing it in 
ReCodEx would be difficult and it may show that non-preemptive approaches work 
sufficiently well.

The algorithms can be divided into two categories -- those that maintain a queue 
for each worker and assign jobs immediately, and those that delay the assignment 
until a worker is available.

The current load balancing algorithm (a simple round robin over all workers) in 
ReCodEx belongs to the first category, along with assigning incoming jobs to the 
least loaded worker and the "Power of two choices" randomized algorithm. We 
propose two ways of estimating the load of the workers -- simply counting the 
jobs and summing the processing time estimates (calculated from processing times 
of previous similar jobs). This gives a total of five algorithms to evaluate.

The non-immediate dispatch category contains two broad approaches. One is based 
on a single priority queue of jobs with various policies. We will evaluate the 
following priority policies:

- earliest time of arrival first (first come, first served)
- the policy mentioned in Section \ref{time-vs-list-based-scheduling}
- shortest job first (based on previous processing times)
- earliest deadline first (the modification presented in section 
  \ref{custom-edf})
- least flexibility job first

The other approach is employed by the multi-level feedback queue algorithm. The 
original algorithm is depends heavily on preemption. Therefore, we will evaluate 
the modification described in Section \ref{custom-mlfq}.

