\chapter*{Introduction}
\addcontentsline{toc}{chapter}{Introduction}

This thesis deals with the problem of efficient automated evaluation of 
solutions to programming assignments in a heterogenous distributed computing 
environment. 

Automated programming assignment solution evaluation aids programmer education 
by greatly reducing the time students need to wait for feedback after a 
submission. Moreover, it is possible to grant students multiple attempts to 
solve an assignment with negligible added costs. That, in turn, allows teachers 
to assign more demanding tasks that help developing programming skills more 
efficiently.

From another point of view, the automation also facilitates filtering out 
submissions that do not meet objective criteria prescribed by the teacher. This 
gives the teachers an opportunity to focus on qualities that are difficult to 
assess automatically, such as good object-oriented design or code readability, 
without having to bother with repetitive tasks like compiling submitted source 
code and checking the basic functionality on example inputs and outputs.

We examine the possibilities of exploiting both multiprocessor systems and 
virtual machines created on demand for evaluation of student submissions. We 
analyse the stability of time measurements in both of these environments, 
because unstable time measurements would render the system unusable for many use 
cases.

We also include a comparison of load balancing strategies in the context of 
programming assignment solution evaluation, as the choice of a load balancing 
algorithm greatly affects the overall throughput of the whole system. The 
comparison also takes into account the on demand scaling features of current 
virtual infrastructure providers.

The last part of the thesis deals with the possibility of leveraging container 
technologies to simplify the deployment and maintenance of runtime environments 
for various programming languages and also to support user-defined environments 
for virtually any software platform.

The results of our research could lead to the creation of a community-driven 
programmer training platform, thus making education in programming available to 
the whole world.
