\chapter*{Introduction}
\addcontentsline{toc}{chapter}{Introduction}

Automated evaluation of programming assignments is a valuable aid in the 
teaching of programming. It reduces the time students need to wait for feedback 
after a submission. In addition, it is possible to grant students multiple 
attempts to solve an assignment with negligible added costs. That, in turn, 
allows the teachers to assign more demanding tasks that help developing 
programming skills more efficiently.

The automation also facilitates filtering out submissions that do not meet 
objective criteria prescribed by the teacher, such as being syntactically 
correct, yielding correct outputs for example inputs or finishing in a specified 
amount of time. This gives the teachers an opportunity to focus on qualities 
that are difficult to assess automatically, such as good object-oriented design 
or code readability, without having to bother with repetitive tasks like 
compiling submitted source code and checking the basic functionality on example 
inputs and outputs.

This thesis aims to design a system for programming assignment evaluation that 
is flexible enough to work efficiently both on physical, multiprocessor servers 
and on virtual machines provided by a cloud platform. Such system could be used 
to create a community-driven programmer training platform, thus making education 
in programming available to the whole world. Additionally, universities could 
deploy instances of the system using their own hardware and possibly customizing 
it.

We assess the viability of such deployments in the context of ReCodEx -- a
system for evaluation of programming assignments developed at the department of
the supervisor. There are multiple properties inherent to the problem of
automated assignment evaluation that complicate efficiently scaling the system. 
For example, many assignments rely on time measurements being stable to a 
reasonable degree -- without that, it is impossible to reliably test if an 
algorithm is implemented efficiently. Furthermore, it is necessary to isolate 
the submitted programs to prevent malicious or extremely inefficient code from 
bringing the system down. Various ways of doing this could also impact the 
results of our measurements.

We examine the possibilities of exploiting dedicated (private) multiprocessor 
server machines for evaluation of student submissions. Stressing a dedicated 
server too much with parallel measurements might lead to unpredictable results. 
Despite that, not using multiprocessing at all would waste the potential of 
modern server computers.

The influence of multiple technologies for isolation and secure execution of 
programs submitted by students on the stability of measurement results is also 
examined. Among those, both containers and virtual machines are represented. 
These technologies are necessary for the robustness of the system, but some of 
them might also help stabilize time measurements as a side effect and thus allow 
for more efficient usage of multiprocessor hardware.

Next, we include a comparison of load balancing strategies in the context of 
programming assignment solution evaluation, as the choice of a load balancing 
algorithm greatly affects the overall throughput of the whole system. The 
comparison also takes into account a possibly heterogeneous computing 
environment (e.g., both physical and virtual machines with different 
capabilities) and the on-demand scaling features of current virtual 
infrastructure providers.

The last part of the thesis deals with the possibility of leveraging container 
technologies in other ways than to run submissions in isolation. They could also 
be used to simplify the deployment and maintenance of runtime environments for 
various programming languages. Another possible use case is supporting 
user-defined software stacks by allowing exercise authors to modify the runtime 
environments, for example by installing additional libraries that will not be 
available for other exercises, without introducing overhead for the system 
administrators.

The thesis is structured in the following way. In Chapter 
\ref{assignment-evaluation}, we introduce the problem of automated programming 
assignment evaluation in detail. In Chapter \ref{measurement-stability}, the 
stability of time measurements is evaluated with various isolation technologies 
and degrees of parallelism. We use the results to determine how many parallel 
measurements can be used on a single machine with multiple CPUs, and whether 
using isolation techniques is beneficial or detrimental to the stability. 
Chapter \ref{scheduling} categorizes our specific variant of the scheduling 
problem in the context of prior research in this area, and then presents an 
experiment that compares the performance of existing algorithms. Chapter 
\ref{containers} examines the possibilities of using containers to simplify the 
deployment of software environments required for evaluation. Key parts of the 
functionality is implemented and a short benchmark is presented. Finally, 
Chapter \ref{scaling} analyzes the integration of on-demand scaling into an 
assignment evaluation system. 
