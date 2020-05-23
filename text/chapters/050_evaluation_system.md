# Assignment Evaluation \label{assignment-evaluation}

In this chapter, we outline the specifics of automated evaluation of programming 
assignments from the perspective of load balancing and large-scale deployments. 
We also introduce ReCodEx -- an evaluation system that motivated this thesis. 
The chapter also aims to explain the most important concepts of the problematics 
for future reference.

## Analysis of Requirements \label{analysis-of-requirements}

This section aims to list the features that are required in a programming 
assignment evaluation system so that we can contrast these to the features 
implemented by ReCodEx. The requirements were gathered by surveying various 
assignment evaluation systems and environments for the management of programming 
contests (a closely related topic), and also during the operation of ReCodEx.

### Correctness \label{correctness}

There are many objective qualities of a computer program that can be assessed 
automatically. The most important and obvious one is whether the program
responds correctly to a set of test inputs. In the simplest case, we only need a 
set of input files and a set of corresponding output files that can be compared 
with the actual output of the program.

The more complicated cases involve situations with multiple possible solutions 
(such as finding the shortest path in a graph) or with a non-binary way of 
determining correctness, where the program output is assigned a decimal number 
between 0 (absolutely incorrect) and 1 (absolutely correct). An example of such 
correctness measures could be the accuracy of predictions made by a neural 
network or the ratio of a compression algorithm.

### Execution Time \label{execution-time}

Execution time is another important evaluation criterion. There can be solutions 
that are logically correct, but require too much time to yield the results. 
Also, some solutions might get stuck in an infinite loop or a deadlock for some 
inputs. The second case is especially problematic as it could render the service 
unavailable until an administrator terminates the evaluation. For this reason, 
it is necessary to both measure and limit the execution times.

There are two principal ways of measuring execution time measurement. The first 
one is to measure CPU time -- the amount of time used for the actual execution 
of the program, calculated from the elapsed number of CPU cycles. The other one 
is measuring wall clock time, which is the length of the interval between the 
start and the end of the program execution. The main difference from CPU time is 
that it also includes time used by system calls, waiting for I/O operations, and 
sometimes (depending on implementation details) also the time when the program 
was not running at all due to context switching.

It is critical to limit the wall clock time in every evaluation. Otherwise, a 
program that sleeps indefinitely using a system call would never be terminated. 
A limit on CPU time can also prove useful (even though the CPU time is also 
affected by a wall clock time limit). It can be used to limit the execution time
more precisely for CPU-intensive exercises, or to provide the same amount of 
computation time to all solutions in an exercise that allows using parallel 
computing.

Ideally, all measurements of execution time should be fair and reproducible 
(this applies to other performance metrics as well, but execution time is 
notably unstable). Without this, teachers could not depend on the measurement 
results for grading, because the resulting grade could be different each time.

### Resource Utilization \label{resource-utilization}

Memory usage is another important measure of the efficiency of a program. While 
it sometimes cannot be directly controlled by the programmer (due to garbage 
collection and implementation specifics of memory allocators), a high memory 
usage can be an inidicator of an inefficient algorithm. Moreover, a 
malfunctioning program could bring down the evaluation computer by allocating 
too much memory for other programs to function correctly. 

Apart from time and memory, which are essential performance metrics, there are 
other system resources whose usage shall be limited (or disabled in some cases) 
-- for example disk space and network bandwidth.

### Additional Metrics of Code Quality \label{additional-metrics}

Static code analysis can also provide valuable insights about code quality. For 
example, it might be useful to filter out solutions that do not handle all 
exceptions that can be thrown in the program for some languages and exercise 
types. Another example is ensuring that the source code adheres to a specified 
coding style guideline. This kind of functionality is sometimes provided by 
compilers, and also by specialized utilities called linters.

Other tools can be used during the runtime of the program for various reasons. 
We could for example check for memory leaks with Valgrind (minor ones might 
evade memory limits), detect invalid usage of pointers and arrays with mudflap 
or report performance metrics in environments that use a virtual machine, such 
as Java (where JVM instrumentation could possibly be used).

### Isolation of Executed Code \label{isolation}

It is critical to guarantee that submitted code is run in an isolated 
environment. An untrusted program should not be able to exploit the host system 
(the system performing the evaluation), for example by accessing its files or by 
using inter-process communication (such as shared memory or UNIX signals) to 
communicate with system daemons. Such activities might even lead to a takeover 
of the host system.

Connecting to other evaluated programs must also be prohibited. Otherwise, 
student submissions could for example read output files of other programs to 
bypass limits on processing time and memory.

### Resilience \label{resilience}

Despite isolation technologies being used, it is still possible for parts of the 
system to malfunction. This is even more of a problem in distributed systems, 
where network errors can cause problems. The system must be designed to recover 
gracefully in these cases. In particular, evaluations that failed due to an 
external error (i.e., not because the solution is incorrect) should be retried 
without the need for an intervention from an administrator. Of course, if a 
submission is in fact impossible to evaluate, we must limit these retries so 
that the evaluation does not proceed infinitely.

### Scalability \label{scalability}

We understand scalability as the ability of the system to adapt to a growing or 
declining number of clients by adding or removing resources. In a programming 
assignment evaluation system, the driving factor for scaling is almost 
exclusively the number of submissions.

While automatic on-demand scaling is the ultimate goal, supporting manual 
scaling (aided by an administrator) could also be sufficient. In fact, the main 
benefit of automatic scaling is being able to react to sudden peaks in the 
number of submissions.

### Latency and Throughput \label{latency-and-throughput}

Fast feedback is one of the critical selling points for automating the process 
of evaluation of programming assignments. Therefore, it is necessary that the 
system schedules the received submissions in a way that keeps the latency within 
reasonable bounds. The system should maintain an overall low latency even with 
an increasing number of evaluations performed at the same time.

The scheduling and on-demand scaling (or more broadly, resource management) 
policies should also take throughput in account. The system must be able to 
serve hundreds of clients at the same moment.

### Extensibility \label{extensibility}

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
used as a&nbsp;reference for reasoning about the implementation of features 
discussed in this text.

We can also expect that the results of this thesis will influence the 
development of ReCodEx and that some parts will become direct contributions to 
the project.

### System Components

![A simplified diagram of the components of the ReCodEx code examiner 
\label{recodex-components}](img/recodex/recodex.tex)

The system is divided into multiple independent components depicted in Figure 
\ref{recodex-components}. The functionality of the system is exposed to users by 
an HTTP API provided by a business logic core, which is run as a CGI-like 
application in a web server. The business logic requires persistent storage of 
many kinds of data ranging from user accounts to test inputs for exercises and 
evaluation results. A combination of a relational database and plain file system 
storage is used. Thanks to the wide adoption of the HTTP protocol, the API can 
be used by a variety of client applications. Currently, ReCodEx has a web 
application and a low-level command line frontend.

The broker is a component that is critical for the evaluation of assignment 
solutions. It receives evaluation jobs from the core and forwards them to 
workers. It is also responsible for monitoring the status of the workers, 
balancing their loads efficiently and handling outages and evaluation failures.

Each worker evaluates one job at a time in a secure isolated environment. 
However, multiple workers can be deployed on a single physical machine for a 
more efficient usage of the hardware (typically multiple CPUs). 

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
-- by the business logic core when a solution to an assignment is received. It 
is a responsibility of the broker to select an appropriate worker.

While this provides a great deal of flexibility, it also presents a challenge in 
efficient scheduling of evaluation jobs. Currently, the broker maintans a 
separate queue of pending jobs for each worker and incoming jobs are assigned to 
these queues in a simple round-robin fashion.

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

### Judging Correctness of Output 

ReCodEx supports various ways of judging the correctness of the output of a 
submission using judges -- programs that read the output file and assign it a 
rating between 0 and 1. There are multiple kinds of correctness rating 
implemented by built-in judges and it is also possible to upload a custom 
judging program for specialized exercises. 

### Description of Evaluation Jobs

When the core receives a submission for evaluation, it takes the exercise 
configuration prepared by the author and the submitted files and transforms them 
into a structured file called the job configuration (which is then used by the 
worker).

The job configuration is a YAML-encoded object that contains job metadata and, 
more importantly, the instructions on evaluating the submission. The 
instructions are a set of atomic tasks of various types. One group of tasks are 
internal tasks, which are implemented by the worker itself. Examples of this 
group are downloading a file from the persistent storage, extracting an archive 
or copying a file from one place to another. The other group are external tasks. 
These involve running a program in a sandbox (currently, only `isolate` is 
supported) with a set of limits and with measurements taking place. This is 
mainly used for compilation and execution of submitted code.

The set of tasks is not in a fixed order. Instead, dependencies are specified 
explicitly so that that the tasks form a directed acyclic graph. If a task 
fails, the worker cancels only its dependees and not the whole evaluation. This 
allows for a great deal of flexibility in use cases such as conditional 
evaluation (e.g., a submission must pass at least one of two tests).

### Language Support in Workers

In order to support a programming language, the machine that runs the worker 
must provide some utilities -- typically a compiler or an interpreter. 
Currently, the core relies on the diligence of the administrators that maintain
the worker machine -- each worker must advertise the correct runtime environment 
headers (configured manually) and have the utilities required by their 
environments installed at the exact locations expected by the core. Also, adding 
a new language requires a (rather minor) change in the business logic code 
responsible for the generation of job configuration.

### Result Consistency on Heterogeneous Hardware

The workers can run on completely unrelated machines with different hardware 
specifications. This has numerous advantages, most importantly that we can 
gradually replace obsolete machines with new ones and we can add specialized 
machines for some exercises (e.g., multiprocessor computers for parallel 
programming).

A drawback of this fact is that measurements on different hardware will likely 
have different results -- a faster CPU will execute a test faster than a slower 
one. If not addressed, this would greatly impact the fairness of grading.

The solution chosen by ReCodEx is defining hardware groups -- manually 
configured string identifiers shared by machines with similar hardware 
specifications, and having a separate set of limits for each hardware group 
allowed by an exercise.

## Requirements Fulfilled by ReCodEx

In this section, we examine which requirements from Section 
\ref{analysis-of-requirements} are satisfied by ReCodEx and which are not. We 
shall then evaluate the latter group and clarify which of those will be 
addressed by this thesis.

The requirement on detecting incorrect solutions (Section \ref{correctness}) can 
be considered satisfied. ReCodEx supports a wide range of judges that allow 
testing the correctness in many different ways. One thing that is missing is the 
support for interactive tasks where the solution communicates with another 
program.

Thanks to `isolate`, ReCodEx can measure and limit the usage of a plethora of 
resources, including CPU time, wall clock time, memory and disk usage (Sections 
\ref{execution-time} and \ref{resource-utilization}). However, we do not know if 
the stability of measurements cannot be influenced by the isolation (or by 
multiple parallel measurements sharing the hardware).

The submitted code is also run in isolation from the rest of the host system and 
from other solutions (Section \ref{isolation}). The implementation makes it 
appear to the submission that it runs as the only process in its own operating 
system that includes a file system, inter-process communication and network 
communication. Of course, unless explicitly allowed, the solution cannot reach 
any other programs using these facilities.

ReCodEx is tolerant to failures in evaluation, even when they result in a crash 
of the worker machine (Section \ref{resilience}). In such cases, the broker 
reassigns the evaluation to another worker (with a limit on the number of 
reassignments). Evaluation jobs are not lost even in the case of a broker 
breakdown. They are stored persistently by the system core and once the broker 
becomes available again, they can be resubmitted.

ReCodEx can be easily scaled manually by adding more worker machines (Section 
\ref{scalability}). This also includes adding more powerful hardware over time. 
However, there are two problems that should be addressed. First, manual scaling 
cannot deal with sudden peaks in usage efficiently. Second, we do not know if 
the load balancing algorithm implemented by the broker is good enough to use the 
additional worker machines efficiently. As of now, ReCodEx uses 17 workers, 8 of 
them that are general purpose and 9 that are reserved for specific subjects.

The load balancing algorithm also has a notable influence on the latency and 
throughput of the system (Section \ref{latency-and-throughput}). Therefore, its 
efficiency must be measured and compared to alternatives.

The last two remaining requirements to examine are extensibility (Section 
\ref{extensibility}) and support for additional code quality metrics (Section 
\ref{additional-metrics}). Thanks to the general job configuration format used 
by the worker, the only thing left to satisfy the second requirement is being 
able to provide the quality checking software. The ReCodEx workers can use any 
software installed on the host machine, which partially satisfies both of the 
requirements. However, the software has to be installed first and the system 
core has to be modified to emit job configurations that use it. This would 
introduce a notable administration overhead if we needed to support per-exercise 
runtime environments.

### Summary

From our examination of the requirements and the reality of ReCodEx, we conclude 
that a number of topics has to be researched. The stability of measurements has 
to be measured when `isolate` is used and when multiple measurements are 
performed on the same hardware.

Furthermore, the efficiency of the load balancing algorithm must be examined, 
because it affects the latency, throughput, and scalability of the system. Also
the viability of on-demand scaling should be assessed.

The last obstacle on the path to a large scale deployment of ReCodEx is the 
overhead of adding and extending runtime environments, and it could be removed 
by using container technologies.
