# Evaluation of Measurement Stability

In this chapter, we examine the influence of various factors on the stability of 
time measurements in a system that evaluates programming assignments. 
Informally, we define a stable measurement as one that yields the same or very 
similar value each time it is repeated. 

This property is crucial in assignments that require students to submit programs 
that are not only correct, but also fast. For many problems, the benefit of an 
efficient algorithm manifests only on large data. On the other hand, it is 
important that the evaluation takes as little time as possible so that the 
system can provide feedback quickly. The more stable are the measurements, the 
shorter can be the testing workloads.

TODO add a comparison of e.g. insertion sort and quick sort with some error 
margin lines to demonstrate that bigger data makes a cleaner distinction

We examine two groups of factors that influence measurement stability. In the 
first one, there are various kinds of system load on the hardware performing the 
measurements. In the second one, there are technologies that allow us to run 
untrusted code in a controlled environment (e.g. process isolation or 
virtualization). Even though these technologies are required for the system to 
work, some of them might also help with mitigating the influence of the system 
load.

The reason for introducing these factors in a real world application is being 
able to increase the throughput of the system if necessary.
