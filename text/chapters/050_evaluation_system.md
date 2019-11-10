# Automated Evaluation of Programming Assignments

In this chapter, we outline the specifics of automated evaluation of programming 
assignments from the perspective of load balancing and large-scale deployments. 
We also introduce ReCodEx -- the evaluation system that motivated this thesis.

## Analysis of Requirements

This section aims to list the features that are required in a programming 
assignment evaluation system.

### Low Latency

Fast feedback is one of the critical selling points for automating the process 
of evaluation of programming assignments. Therefore, it is necessary that the 
system schedules the received submissions in a way that keeps the latency within 
reasonable bounds. The system should maintain an overall low latency even with 
an increasing number of evaluations performed at the same time.

### Filtering of Incorrect Solutions

There are many objective qualities of a computer program that can be assessed 
automatically. The most important and obvious one is whether the program
responds correctly to a set of test inputs. In the simplest case, we only need a 
set of input files and a set of corresponding output files that can be compared 
with the actual output of the program.

Execution time is another important evaluation criterion. There can be solutions 
that are logically correct, but require too much time to yield the results. 
Also, some solutions might get stuck in an infinite loop for some inputs. The 
second case is especially problematic as it could render the service unavailable 
until an administrator terminates the evaluation. For this reason, it is 
necessary to both measure and limit the execution times.

There are two principal ways of execution time measurement. The first one is CPU 
time -- the amount of time used for the actual execution of the program, 
calculated from the elapsed number of CPU cycles. The other one is wall clock 
time, which is the length of the interval between the start and end of the 
program execution. The main difference from CPU time is that it also includes 
time spent by system calls and waiting for IO operations, and sometimes 
(depending on implementation details) also the time when the program was not 
running at all due to context switching.

It is necessary to limit at least the wall clock time. Otherwise, a program that 
sleeps indefinitely using a system call would never be terminated.

Memory usage is another important measure of the efficiency of a program. While 
it sometimes cannot be directly controlled by the programmer (due to garbage 
collection and implementation specifics of memory allocators), a high memory 
usage can be an inidicator of an inefficient algorithm. Moreover, a 
malfunctioning program could bring down the evaluation computer by allocating 
too much memory for other programs to function. 

Apart from time and memory, which are essential performance metrics, there are 
other system resources whose usage shall be limited (or disabled in some cases) 
-- for example disk usage and network bandwidth.

Statical code analysis can also provide us with valuable insights on code 
quality. For some languages and exercise types, it might be useful to for 
example filter out solutions that do not handle all exceptions that can be 
thrown in the program. This kind of functionality is sometimes provided by 
compilers, and also by specialized utilities called linters.

### Isolation of Executed Code

It is critical to guarantee that code submitted by students is run in an 
isolated environment. An untrusted program should not be able to communicate 
with the host system (the system performing the evaluation), for example by 
reading its files or by using inter-process communication (such as shared memory 
or UNIX signals) to communicate with system daemons. Communication with other 
evaluated programs must also be prohibited.

There are also indirect ways in which the evaluated code can interfere with the 
function of the host system, such as consuming all of its memory, disk space or 
other system resources. Therefore, the usage of all such resources must be 
limited by the evaluation system.

### Resilience

Despite isolation technologies being used, it is still possible for parts of the 
system to malfunction. This is even more of a problem in distributed systems, 
where network errors can cause problems. The system must be designed to recover 
gracefully in these cases. In particular, evaluations that failed due to an 
external error (i.e., not because the solution is incorrect) should be retried 
without the need for an intervention from an administrator.

### Fairness of Grading Based on Performance

Ideally, all measurements of execution time should be reproducible (this applies 
to other performance metrics as well, but execution time is notably unstable). 
Without this, teachers could not depend on the measurement results for grading, 
because the grade could be different each time.

### Extensibility

The system should allow adding support for new languages without significant 
changes to the code base and without overhead for the administrators. Also, 
extending the runtime environments with libraries should be possible on a 
per-exercise basis, as installing a library system-wide would make it available 
even for exercises where using it is not desirable.

## ReCodEx

ReCodEx is a system for evaluation of programming assignments developed at the 
Faculty of Mathematics and Physics of the Charles University. It was first 
deployed in 2016, but it still undergoes active development. Since it is 
relatively modern and also well known to the author of the thesis, it will be 
used as a reference for reasoning about the implementation of features discussed 
in this text.

### System Components

![A simplified diagram of the components of the ReCodEx code examiner 
\label{recodex-components}](img/recodex/recodex.tex)

The system is divided into multiple independent components depicted in Figure 
\ref{recodex-components}. The functionality of the system is exposed to users by 
an HTTP API, which is run as a CGI-like application in a web server. The 
business logic requires persistent storage of many kinds of data ranging from 
user accounts to test inputs for exercises and evaluation results. A combination 
of a relational database and plain file system storage is used. Thanks to the 
wide adoption of the HTTP protocol, the API can be used by a variety of client 
applications. Currently, ReCodEx has a web application and a command line 
frontend.

The broker is the component that is critical for the evaluation of assignment 
solutions. It receives evaluation jobs from the HTTP API and forwards them to 
workers. It is also responsible for monitoring the status of the workers, 
balancing their loads efficiently and handling outages and evaluation failures.

Each worker evaluates one job at a time in a secure isolated environment. 
However, multiple workers can be deployed on a single physical machine for a 
more efficient usage of the hardware. 

### Worker Selection

The pool of worker machines in ReCodEx can be fairly diverse. There can be 
machines that differ in hardware (newer and faster machines can be added while 
the old ones remain), operating systems (most workers use GNU/Linux, but future 
assignments might require Microsoft Windows, for example), available software 
(support for some languages does not have to be installed on every worker 
machine), and possibly in other characteristics.

Each worker machine advertises its properties when it is registered with the 
broker. Evaluation jobs are also assigned a set of headers -- a structured
specification of the requirements on the worker that is going to process the job 
-- by the HTTP API when a solution to an assignment is received. It is a 
responsibility of the broker to an appropriate worker.

While this provides a great deal of flexibility, it also presents a challenge in 
efficient scheduling of evaluation jobs.

### Secure Execution of Submissions

ReCodEx uses the `isolate`[@MaresIsolate] sandbox to ensure that code submitted 
by students is executed in a secure and isolated environment and that their 
usage of resources is limited. The sandbox is controlled by the `isolate` 
command line utility, which is executed as a subprocess by the worker daemon.

A separate instance of the sandbox is used for each stage of the evaluation 
process where untrusted code is involved. In particular, this means compilation 
of source codes and running the resulting program with test inputs. Files that 
should be kept between the stages (typically compiled binaries) must be copied 
by the worker (the files that are supposed to be copied are specified by the 
configuration of the exercise).
