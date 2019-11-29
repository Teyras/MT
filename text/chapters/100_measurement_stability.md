# Stability of Measurements \label{measurement-stability}

In this chapter, we examine the influence of various factors on the stability of 
time measurements in a system that evaluates programming assignments. 
Informally, we define a stable measurement as one that yields the same or very 
similar value each time it is repeated (provided that the input data is the same 
and that the measured program is deterministic). 

This property is crucial in assignments which require students to submit 
programs that are not only correct, but also efficient in terms of execution 
time. For many problems, the benefit of an efficient algorithm manifests only on 
large inputs. On the other hand, it is important that the evaluation takes as 
little time as possible so the system can provide feedback quickly. If the 
measurements are not stable, the difference between efficient and inefficient 
solutions might be visible only after we test them with larger inputs, thus 
counteracting the instability. Stable measurements allow us to keep the input 
data small, which in turn makes the response period of the system shorter.

This idea is illustrated in Figure \ref{stability-illustration}. For `n=25`, the 
5% relative error margins do not overlap, while the 20% ones do. The value of 
`n` has to be increased over 50 before a clear distinction can be made with 20% 
relative error margins. 

![A comparison of the plots of two asymptotically distinct time complexity 
functions with 5\\% and 20\\% relative error margins outlined, where $n$ is the 
input size 
\label{stability-illustration}](img/stability/stability-illustration.tex)

We examine two groups of factors that influence measurement stability. In the 
first one, there are various kinds of system load on the hardware performing the 
measurements. In the second one, there are technologies that allow us to run 
untrusted code in a controlled environment (e.g., process isolation or 
virtualization). Even though these technologies are required for the system to 
function securely, some of them might also help with mitigating the influence of 
the system load.
