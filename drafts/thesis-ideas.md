# ReCodEx advanced scheduling

## Load balancing

- research current state of art in online scheduling with machine eligibility 
  constraints
- re-scheduling in case of worker failure
	- most real world applications of the problem want the new schedule to 
	  be similar to the original one, but we do not need that (schedules are 
	  easily rearranged)
	- on the other hand, similar schedules make it easy to roll back to a 
	  previous schedule if a worker reappears soon enough (short-term 
	  network failure), but it is not clear if this brings any benefits
- hypothesis: job processing time is not predictable -- some will fail 
  immediately, some will spin until timeout (especially introductory courses)
- hypothesis: wrong solutions are more frequent than correct ones
- information about current load can be acquired from progress reports (we might 
  want to make the reports richer -- task types etc.)
- workers with specific capabilities (NUMA) shouldn't be used for trivial jobs, 
  but they also shouldn't wait needlessly when there are no massively parallel 
  jobs in the queue
- current implementation keeps a job queue for every worker and uses round-robin 
  to schedule jobs
- alternative: maintain a single queue of jobs, workers take new jobs when they 
  become free
	- scheduling runs in a single thread -- no lock-related overhead
	- no obvious way to tell the load factor of workers (or hardware groups)

## Automatic scaling

- some hardware groups that run on virtual hardware could be automatically 
  scaled up and down according to queue
	- power saving
	- better handling of spikes in traffic (very likely -- assignment 
	  deadlines)
- to achieve this, we need to communicate with the virtualization manager
	- CLI, REST API, ... -- needs research
	- vSphere is accessible and supports CLI
- autoscaling facilities commonly used by PaaS providers cannot be applied here 
  -- neither network traffic nor CPU load corellate with the actual load factor
	- each load balancing algorithm has its own way of telling the load

## Dockerized Workers

- We could ship a base image that contains a pre-configured ReCodEx worker that 
  can be adjusted with environment variables
- This would facilitate easy deployment of user-defined runtime environments
- Exotic workers could easily be started on demand and bound to arbitrary ports
- On-demand worker deployment would require a manager service connected to the 
  Docker daemon on the host that communicates with the broker
- Broker would have to accept jobs that are not processable at the moment. Then 
  it shall start the workers (via a management API of some sort) and keep the 
  jobs for them - that is a non-trivial implementation task

## Broker fault tolerance

- offloading jobs to persistent storage (HDD/DB/...) so that they survive a 
  crash
	- probably unnecessary -- they are already stored in the API, it should 
	  be possible to detect those that failed due to broker crash and 
	  resubmit them
- broker redundancy -- multiple brokers

## Evaluation

- to evaluate an online algorithm, we need long workloads (ideally based on real 
  world data)
- total processing time (makespan) is irrelevant
- how should we count jobs that fail because nobody can process them? This might 
  happen because a worker breaks down. Some algorithms could come out of this 
  better than others if they get lucky and assign the job well before a 
  breakdown.
	- breakdown times should be the same for the measurement of all 
	  algorithms (deterministic)
	- option: if we do not simulate permanent breakdowns, we can try to 
	  re-submit failed jobs
- metric: round trip time -- perceived delay between submission and arrival of 
  results
	- a long wait is acceptable for jobs that take a long time to evaluate 
	  -- measure (and minimize) something like T_wait/T_total
- metric: used worker time -- regardless of whether they are idle or busy -- 
  measure of autoscaling efficiency
- metric: all of the above with random worker breakdowns

## Technical details

- workers, broker and fileserver can be run without modifications
- jobs can be rigged to run for a specified amount of time (`/usr/bin/sleep`)
	- if we want to use progress data for load balancing, it will be a bit 
	  more complicated, but still feasible
- a minimal subset of the API has to be reimplemented (notifications when a job 
  is finished)
	- it is convenient to collect these notifications from the same program 
	  that replays a workload (it can output measurements immediately)
- how to measure total running time of all workers (autoscaling efficiency)?
