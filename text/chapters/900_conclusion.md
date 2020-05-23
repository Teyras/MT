# Conclusion 

We have presented and examined several problems related to large-scale 
deployments of programming assignment evaluation systems. Most of the results 
can be directly applied to the ReCodEx system, but they are general enough to 
also benefit other similar systems.

Measuring the influence of running multiple measurements in parallel and using 
various isolation technologies on the stability of results provided us with 
insights about using modern CPUs for assignment evaluation. We found that 
simultaneous measurements interfere with each other, causing a decline in 
stability. A plausible explanation is that this is caused by contention for the 
memory controller and last level of the CPU cache.

The most profound consequence of this is that it is not advisable to use CPUs 
with many cores and cloud platforms when stable measurements are required (e.g., 
performance-oriented programming courses or programming contests). We examined 
several methods that could alleviate this instability: explicit CPU and NUMA 
affinity settings and disabling logical cores. There is an improvement in 
stability when the available cores are split into disjoint groups, each of which 
is dedicated to a single evaluation worker, and when logical cores are disabled.
This improvement, however, did not increase the number of parallel measurements 
that can be run simultaneously without a loss in precision on our testing 
machine.

Although we have shown that multi-core CPUs are not particularly suitable where 
precise measurements are required, they can be very useful for numerous other 
exercise types where a correct answer the focus, and not performance. It is a 
responsibility of administrators to allocate resources in a way suitable for the 
workload being processed by the system. However, the measurement framework we 
laid out can be a substantial aid in this task.

We also found that using isolation technologies affects the results of 
measurements, both in terms of overall speed and stability. Using the `isolate` 
sandbox seems to make the standard deviation of measurements higher than when 
they are performed on the bare metal or in Docker. Interestingly enough, this 
phenomenon was not as prominent when VirtualBox was used. Due to the nature of 
programming assignment evaluation, we cannot abandon isolation technologies. 
However, we should continuously evaluate their impact on measurement stability, 
which is one of the key elements of fair grading.

Our survey of online scheduling algorithms and a subsequent experimental 
examination yielded results that allow more efficient utilization of evaluation 
hardware.

In addition to existing algorithms applicable to the problem, we have proposed 
two custom algorithms -- one based on multi-level feedback queues and another 
based on the earliest-deadline-first approach. We have also contributed a 
practical implementation of the latter algorithm and included it in our 
experiment.

The experiment revealed that an algorithm that processes the job with the 
shortest processing time first has the best performance of the tested approaches 
in terms of the number of jobs processed without a large delay. A disadvantage 
of this approach is that it requires a mechanism for estimation of processing 
time for incoming jobs. Fortunately, our results have shown that estimates based 
on historical data should be sufficient for this use case. 

The performance of the custom earliest-deadline-first approach were very close 
to that of a trivial first come, first served algorithm. There is a possibility 
that this is caused by inadequately chosen parameters for determining job 
deadlines or by test inputs not being similar enough to real world jobs.

On-demand scaling of infrastructure is a topic that is related to load 
balancing. After a survey that explored the implementation possibilites ranging 
from physical server machines to containers and virtual machines provided by 
cloud computing platforms, we concluded that a practical implementation is out 
of the scope of this thesis. Nonetheless, we compiled a set of guidelines that 
could serve as a basis for future work.

During our research of scheduling algorithms, we found that container 
technologies could be used to simplify administration of job runtime 
environments over distributed evaluation workers. This would make it feasible to 
maintain a more homogeneous pool of workers where specialized software and 
updates can be deployed to all general purpose machines without manual 
intervention. Such improvement also makes scheduling more simple and more 
efficient.

We proposed a solution that automates the deployment of runtime environments,
and also facilitates supporting custom environments defined by exercise authors 
(course instructors) without additional maintenance costs. We also implemented 
the core parts of this functionality and performed a simple experiment which 
showed that the overhead of the proposed solution is manageable (rarely over 1 
second and typically in the order of hundreds of milliseconds for size-optimized 
environment images).

In summary, the presented results can serve as a foundation for building a
large-scale system for evaluation of programming assignments that is efficient 
in terms of both cost and performance. This, in turn, can help make programming
education more efficient and accessible.

