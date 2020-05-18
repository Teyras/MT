# Conclusion 

In this text, we have presented and examined several problems related to 
large-scale deployments of programming assignment evaluation systems. Most of 
the results can be directly applied to the ReCodEx system, but they are general 
enough to also benefit other similar systems.

First, we measured the influence of running multiple measurements in parallel 
and using various isolation technologies on the stability of results. We found 
that simultaneous measurements interfere with each other, causing a decline in 
stability. A plausible explanation is that this is caused by contention for the 
memory controller and last level of the CPU cache.

The most profound consequence of this is that it is not advisable to use CPUs 
with many cores and cloud platforms when stable measurements are required (e.g., 
performance-oriented programming courses or programming contests). We examined 
several methods that could alleviate this instability, such as explicit CPU or 
NUMA affinity settings and disabling logical cores, but none of the results were 
enough to change our conclusion.

We also found that using isolation technologies affects the results of 
measurements as well, both in terms of overall speed and stability. Using the 
`isolate` sandbox seems to make the standard deviation of measurements higher 
than when they are performed on the bare metal or in Docker. Interestingly 
enough, this phenomenon was not as prominent when VirtualBox was used. Due to 
the nature of programming assignment evaluation, we cannot abandon isolation 
technologies. However, we should continuously evaluate their impact on 
measurement stability, which is one of the key elements of fair grading.

The central part of the thesis was a survey of online scheduling algorithms in 
the context of automated assignment grading and their experimental evaluation. 
We contribute two custom algorithms, one based on multi-level feedback queues 
and another based on the earliest deadline first approach. The multi-level 
feedback queue scheduler was not implemented due to the large number of 
parameters that would have to be fine-tuned to obtain a practically usable 
algorithm.

Our experiment revealed that an algorithm that processes the job with the 
shortest processing time first has the best performance of the tested approaches 
in terms of the number of jobs processed without a large delay. A disadvantage 
of this approach is that it requires a mechanism for estimation of processing 
time for incoming jobs. Fortunately, our results have shown that estimates based 
on historical data should be sufficient for this use case. 

The performance of the custom earliest deadline first approach were very close 
to that of a trivial first come, first served algorithm. A chance exists that 
this is caused by inadequately chosen parameters for choosing job deadlines or 
by test inputs not being similar enough to real world jobs.

After scheduling algorithms, we examined the possibility of using container 
technologies to simplify administration of job runtime environments over 
distributed evaluation workers. We proposed a solution that automates this 
maintenance task, and also facilitates supporting custom runtime environments 
defined by exercise authors (course instructors) without additional maintenance 
costs. We also implemented the core parts of this functionality and performed a 
simple experiment which showed that the overhead of the proposed solution is 
manageable (rarely over 1 second).

Our last contribution is a survey of on demand scaling possibilites in various 
environments, ranging from physical server machines to containers and virtual 
machines provided by cloud computing providers. Because of the number of 
possible implementations of this mechanism and the difficulty of evaluating its 
performance, we decided not to provide a practical implementation. Nonetheless, 
we compiled a set of guidelines that could serve as a basis for future work.

In summary, the presented results can serve as a foundation for building a
large-scale system for evaluation of programming assignments that is efficient 
in terms of both cost and performance. This, in turn, can help make programming
education more efficient and accessible.

