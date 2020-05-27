# On-demand Scaling \label{scaling}

In this chapter, we survey the current practical applications of on-demand 
scaling and their viability in automated evaluation of assignments. Although we 
do not contribute any implementation of this mechanism, we present an analysis 
and a set of design guidelines that can be built upon in the future. 

On-demand scaling (or auto-scaling) is a feature of many virtualized machine 
platforms. While the exact mechanisms vary among different service kinds and 
providers, the basic principle remains. Execution units that are not utilized at 
the moment are returned to the provider, and when a traffic spike happens, the 
system can quickly react by allocating additional resources.

In this context, the allocated resources can be for example additional memory 
and CPUs (vertical scaling), or whole new virtual machines or containers 
(horizontal scaling). Due to our concern about measurement stability, we will 
only focus on horizontal scaling.

In a certain sense, on-demand scaling is also possible with physical servers -- 
it is feasible to implement a resource management service that starts and shuts 
them down as necessary. Such approach might be even more efficient if we managed 
a large cluster of single-board computers.

![Number of submissions in ReCodEx, divided by hour and day of submission 
\label{submission-time-histograms}](img/scaling/submission-time-histograms.tex)

The benefit of auto-scaling techniques is that they allow to save costs during 
low traffic periods, while being able to deal with unexpected increases in 
traffic when they happen. In systems for evaluation of programming assignments, 
the frequency of submissions can vary wildly, which means we might benefit from 
using these techniques. This is confirmed by submission data from ReCodEx, which 
shows that there is more traffic during evenings and that traffic decreases on 
Fridays and Saturdays (as shown by Figure \ref{submission-time-histograms}).
