http://link.springer.com/article/10.1007/s10288-010-0149-1 
	makespan opt with eligibility constraints (2010)
https://iuuk.mff.cuni.cz/~sgall/ps/schsurv.ps
	Sgall - online scheduling - a survey (98)	
http://link.springer.com/chapter/10.1007/BFb0029570
	Sgall - online scheduling - conference paper (05)
https://s3.amazonaws.com/academia.edu.documents/43002134/A_better_lower_bound_for_on-line_schedul20160224-3725-19pvood.pdf?AWSAccessKeyId=AKIAIWOWYYGZ2Y53UL3A&Expires=1504705072&Signature=gvS5WMFrBlX%2FoasUi2IZ7bUw6kU%3D&response-content-disposition=inline%3B%20filename%3DA_better_lower_bound_for_on-line_schedul.pdf
	presents a randomized scheduling alg
http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.10.992
	Pruhs, Sgall, etc.
http://www.sciencedirect.com/science/article/pii/S0925527316000190
	Scheduling with processing set restrictions: A literature update
http://www.sciencedirect.com/science/article/pii/S0304397515000420
	Online scheduling with equal processing times and machine eligibility
	constraints - optimal time-based alg
https://arxiv.org/pdf/1403.6918.pdf - comparative study of load balancing in cloud
	Probably not a lot of interesting stuff, but there are some pointers. Mentions FCFS (round-robin), CLBDM (Central load balancing decision module (2011))

http://link.springer.com/article/10.1007/s10796-013-9459-0 - autoscaling
https://www.usenix.org/sites/default/files/icac14_full_proceedings_interior.pdf#page=65 - more stuff about autoscaling, contains some interesting related work
http://dl.acm.org/citation.cfm?id=3030214 - performance evaluation of autoscaling methods - might be interesting as fuck

## Alg.
Sgall - list scheduling (assign first eligible job in the queue to an idle machine),
	randomized alg. for 2 machines
Berman (On-line LB, related machines) - assign to slowest machines first to minimize
	maximum load, improved alg that works in phases (for permanent jobs -
	definition??) - this idea could be reused
	- same approach is analyzed in a paper by Anand, Bringmann, Friedrich,
	Garg and Kumar (2013) wrt. to max (weighted) flow time - some incomprehensible stuff
	was found


scheduling over time - we don't have to assign anything immediately

online service scheduling - pool of jobs, ordinary/special, assignment order

metrics - total completion/flow (how long jobs stay in the
system)/waiting(flow - running) time

other possibilities - makespan (not intereseting for the user)
	- (weighted) throughput - based on declining jobs

nonclairvoyant online scheduling - we do not know the requirements (most
importantly, time)
	- however, we receive progress information, so we're not totally in
	  the dark when the job finally runs
	- also, we can keep track of previous run times of simmilar jobs and use that
		- we need to measure how much these times usually vary
		- we could use some sort of clustering to get better estimates
		  (processing time is either close to the sum of time limits or much
		  lower in most cases)

preemption - it should be possible to implement it on the worker (long running
	tasks would have to be restarted) - does it help??
	- it does help, but is hard to implement (killing isolate is
	  relatively simple, but interrupting other task types might prove
	  challenging)

objective - weighted tardiness (w_i = 1/E[T_i])
	- most research is centered
	around makespan minimization (idiots everywhere...)
	- flow time - from release to completion - better than makespan
	- delay factor - introduced in 2018

job load vector - specifies how much the job increases the load of the machine it's
	assigned to
	- identical - all coordinates are the same
	- related - each machine has a speed (s_i) and the coordinates are equal to
	p_j/s_i (j is fixed in the vector)
	- unrelated - everything else

immediate dispatch - the worker is chosen right when the job arrives

dynamic posted pricing - with every job, a vector (c) of prices for each machine is
	calculated
	- the vector is used to choose the machine 
		- min procesing-time_ij + Load_ij + c_ij
	- the way of updating the costs is not specified

broadcast scheduling - processing a job satisfies multiple clients
	- irrelevant, but mentioned in literature

processing set 
	- inclusive - no, e.g. Windows .NET workers and NUMA are
		disjoint
	- nested - acceptable (for any two jobs and their processing
		sets it holds that they are either disjoint or one is a
		subset of the other), but requires attention of the
		administrator (J_1 - hwgroup=i7&env=C, J_2 - env=Java, some
		(not all) i7 machines have Java installed -> processing
		sets of J_1 and J_2 are uncomparable)
	- interval - who knows? probably not and this class is underresearched
	  as fuck anyways
	- tree-based - nope, there just won't be a machine that can process
	  anything
	- we need arbitrary processing sets - bummer
		- It is proven (Hwang, 2004) that assigning jobs to the least loaded
		machine is O(log(m))-competitive and no better alg exists (wrt makespan)
		- wrt. average flow time, no online alg with a bounded competitive
		ratio that deals with constraints exists

Applicable algorithms

- FIFO
- Longest first (should suck according to [minmax response and delay])
- Longest wait first

- Earliest deadline first (except we have to estimate deadlines)

