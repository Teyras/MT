# Load Balancing

note: k-competitive algorithm .. gives results that are no more than k times 
worse than the optimum

## Problem Categorization

- On-line scheduling over time - jobs arrive over time, we do not know when
	- the other studied case is over list
- Non-clairvoyant - we do not know the running times of jobs when they arrive 
  (but they can be predicted to some extent)
- Non-preemptive - it is technically possible to implement restarts (a weaker 
  variety of preemptiveness), but it affects the user experience
- Arbitrary processing set - every job can have an arbitrary set of machines 
  that can process it. Alternatives are:
  - inclusive - for every two processing sets, one must be a subset of the 
    other. This does not apply to our case - for example the processing sets of 
    Windows .NET jobs and parallel programming jobs could be disjoint (In 
    general, highly specialized worker sets)
  - nested - every two processing sets are either disjoint or comparable - this 
    could be achieved with special care from the administrator
  - tree-based - machines can be organized into a tree where every job can be 
    assigned to a node so that all nodes on the path to the root (inclusive) can 
    process it. We do not have a universal worker, so this does not apply to our 
    case.
  - interval-based - does not apply, not much interesting research
- Unrelated machines - the processing time of a job on a machine can be an 
  arbitrary number
  - as opposed to related machines, where every machine has a speed property and 
    processing times can be calculated by dividing the job processing time with 
    the speed, and identical machines, that have the same speed

## Objective

- The most researched objective function is the makespan - the total time it 
  takes to complete all jobs
  - this is irrelevant from the perspective of the user
- Other, less researched objectives are total completion time (the sum of 
  completion times for all jobs - also irrelevant) and total flow time - the 
  time for which the job stays in the system
  - weighted variants can also be considered
  - there can be no competitive on-line algorithm for average flow time 
    minimization (proved by Kumar and Garg in 2007)

## Related work, existing algorithms

- a big part of the research covers only special cases such as two machines or 
  proves the existence of a competitive algorithm
- Jia Xu, Zhaohui Liu (2014) - an optimal makespan algorithm for a nested 
  processing set (equal processing times)
- Becchetti, Leonardi (2001) - RMLF - multiple queues, random assignment (could 
  be modified) - flow time optimization
- There is a comparative study from 2013 that list a large number of LB 
  algorithms - TODO
- Lee, Leung and Pinedo - survey from 2012 - lists some results in online 
  service scheduling
  - there are some insights on priority policies and their comparison
- A literature update by Leung and Li from 2016 on scheduling with processing 
  set restrictions - points to many other sources, states that objectives other 
  than makespan need research
- A tertiary study on machine scheduling from 2017 lists more surveys
