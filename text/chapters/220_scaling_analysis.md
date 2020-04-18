## Analysis

In previous sections, we have presented an overview of existing auto-scaling 
implementations. Here we assess the challenges of adapting them for automated 
evaluation of programming assignments. We focus on the Monitoring and Execution 
phases of the auto-scaling process, and also investigate the specifics of 
automatically scaling worker pools with different capabilities.

### Execution Model

Automatic scaling is possible on many different execution models -- using 
dedicated physical machines, virtual machines, containers and other 
abstractions.

#### Physical Machines

Remote management of server machines is a standard tool used by system 
administrators. Therefore it should be simple to launch and power off the 
machines automatically.

In the case of clusters of single-board computers, the situation is more 
complicated. Typically, these devices have a simple design without any 
facilities for being powered on remotely (such as Wake-on-LAN). This is 
justified by both the intended use case and the low overall power consumption.
However, the device boots at the moment the power supply is plugged in, so it 
should be feasible to build a monitor machine that would manage the cluster by 
interrupting and restoring the power supply of each individual device.

An obvious drawback of using physical machines owned by the maintainer of the 
system is that we cannot scale them up infinitely on demand -- we are always 
limited by the amount of machines we have.

#### Virtual Machines and Containers

Virtual machines are a feasible execution model for assignment evaluation. 
Interfaces that allow automated launching and suspending of instances (such as 
REST APIs) are featured by most providers. However, using the services of common 
virtual machine providers requires caution. The most important consideration 
here is potential instability of measurements caused by interference with other 
virtual machines running on the same physical host.

There are two ways of resolution to this problem -- either ignoring it, which 
might be valid for assignments that emphasize correctness of solutions and do 
not wish to grade them by efficiency, or using cloud platforms that can 
guarantee that our virtual machines do not share hardware with other tenants of 
the cloud platform. For example, Amazon AWS can provide such service, but it can 
be expected to incur additional costs.

As a side note, AWS also facilitates automated deployment of dedicated physical 
machines with remote access, which could be a viable option for auto-scaling 
physical servers.

As far as on-demand scaling is concerned, container platforms are very similar 
to virtual machine platforms. The problem with measurement stability is also 
present, and interfaces for automated management of instances (containers) are 
ubiquitous.

#### Summary

Both physical machines and virtual machines are viable for usage in an 
automatically scaled system, but adjusting the total capacity of a virtual 
machine pool is a much simpler task. Being able to combine both execution models 
could also be valuable.

### Performance Indicators

By performance indicators, we mean metrics that drive the decision to scale in 
or out. Our selection of the indicator is critical for the performance of the 
auto-scaling system.

#### CPU and Memory Utilization

In our case, The average CPU utilization over a certain time window does not 
indicate an overloaded system well. Even if this number is close to 100% for 
some worker, it can mean that it is processing a submission that takes a long 
time to evaluate and that it uses the CPU efficiently. Of course, it can also 
mean that the worker is continuously processing submissions and the queue is 
filling up, but we have no way to infer this from the CPU usage.

Low CPU utilization is a better marker in the sense that it is very probable 
that a worker for which this number is close to 0% is not very well utilized. 
There are cases where this might not be true, for example long-running IO-bound 
exercises, but it is a rare scenario in ReCodEx.

Memory utilization is not at all correlated with the actual utilization of a 
worker -- it depends mostly on the submission that is being executed (and 
resource limits).

#### Network Traffic

In the case of ReCodEx, network traffic might be indicative of incoming jobs for 
a worker, because the workers communicate with the broker using TCP. However, 
there is no way to tell how long the queue is for a particular worker using this 
statistic on its own, similarly as in the case of CPU utilization.

#### Queue Length

As discussed in Chapter \ref{scheduling}, we are able to estimate the length of 
a job on its arrival based on historical data. Using the same technique, it is 
straightforward to also estimate the load of a worker when we use a queue 
manager that maintains a separate queue for each worker.

For queue managers that use a single queue for all workers, we could calculate a 
potential load for each worker -- the sum of estimated processing times of all 
the queued jobs the worker can process. Although this seems like a reasonable 
approach that is also utilized by the OAGM scheduling algorithm, an experiment 
that evaluates its usefulness would be necessary.

#### Summary

It is evident that low level metrics such as CPU utilization do not reflect the 
actual worker utilization in a programming assignment evaluation system. The 
queue length, which is a more promising indicator, cannot be inferred by the 
autoscaler itself from these low level metrics, and if we are to use it, we will 
have to implement support for reporting it to the autoscaler from the broker.

### Load Balancing Constraints

In Chapter \ref{scheduling}, we outlined a number of challenges specific to load 
balancing in a system for assignment evaluation. From these, only the need to 
handle arbitrary machine eligibility constraints is relevant to the auto-scaling 
problem.

The problem of autoscaling workers with different capabilities is more difficult 
than when every worker can process any job. If a worker gets overloaded because 
it is the only one that can process some class of jobs, the autoscaler needs to 
know what exact requirements the jobs have to launch a machine of the correct 
type and actually improve the situation. In the case of ReCodEx, this can be a 
substantial amount of information in the form of headers (key-value pairs with 
diverse semantics).

Interpreting arbitrary headers for efficient auto-scaling appears to be a 
difficult problem and we failed to find any prior art on this topic. This fact 
leads us to a conclusion that we should instead restrict the diversity of 
workers that are going to support auto-scaling. Since cloud auto-scaling 
typically allows defining multiple auto-scaling groups that are managed 
independently, we can require workers in each of these groups to have equal 
processing power and capabilities.

With this restriction in place, we cannot provide as much flexibility as we 
could if we supported arbitrary job requirements. However, it makes the work of 
the autoscaler (and also the scheduler) much easier. If we employ container 
technologies to automatically deploy new runtime environments as laid out in 
Chapter \ref{containers}, we will also eliminate the only cause of diverse 
worker headers within a single hardware group encountered in ReCodEx until now.
