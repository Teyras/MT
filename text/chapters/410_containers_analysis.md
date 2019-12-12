## Analysis \label{containers-analysis}

The evaluation process in a system for programming assignment evaluation 
resembles a continuous integration service (a service that ensures the quality 
of a codebase with each change, typically by building it and running unit tests 
or various static analyzers). Submitted source code is built using a 
pre-configured toolchain and then subjected to tests. Based on its performance, 
the solution is awarded a rating. The main difference from a classical 
continuous integration service is that performance and resource usage is a key 
element of the rating.

Modern continuous integration services often use containers for various tasks, 
and it is reasonable to presume we might be able to use them in a similar 
fashion since the problem of assignment evaluation is so similar to that of 
continuous integration.

TODO mention the paper about evaluation in Docker

### Secure Execution

Public continuous integration servers run thousands of builds on completely 
untrusted codebases every day. Just as in our case, there are two basic 
scenarios to address -- intentional attacks and programming errors that lead to 
system failures.

In Chapter \ref{measurement-stability}, we found that using `isolate` leads to 
problems with wall-clock time measurements. It seems to affect the overall 
stability of measurements as well, and therefore, it is sensible to consider
a different approach to secure execution for ReCodEx.

### User-defined Runtime Environments

The steps required to build and test a codebase can vary enormously. The number 
of existing programming languages, build toolkits, testing frameworks and third 
party libraries is so large that this process is almost unique for every 
project.

Continuous integration services need to provide a way for users to specify the 
building and testing process in a manner that is both simple and versatile 
enough to satisfy the needs of any project.

It seems that the situation is simpler for programming assignment evaluation 
systems. The assignments are usually much less complex than a typical project 
that requires continous integration. Thanks to this, we do not usually need to 
set up complicated build pipelines for every new exercise. However, in some 
areas such as web development, it is common to use a large number of third-party 
libraries. Over time, this trend has also found its way into ReCodEx. For 
example, machine learning classes require a Python environment with the 
TensorFlow library installed. This example also shows us that it is not 
acceptable to install such libraries in a manner that makes them accessible to 
all exercises that use the same language -- using machine learning libraries 
should not be allowed in Python assignments for introductory programming 
courses.

It is clear we need a way to let exercise authors create a new, independent 
runtime environment based on an existing one, and that we can draw inspiration 
from continuous integration services, even though the build and testing steps we 
require are usually much simpler.

### Preparation of Build Environments

As mentioned in previous sections, the requirements on installed build tools, 
libraries and other utilities can vary a lot with every project. The overhead of 
maintaining this manually on multiple worker machines would be hard to manage.

Moreover, in ReCodEx, adding support for a new build environment can mean not 
only installing the required tools on each worker machine, but also modifying 
the code of the HTTP API so that the frontend can use the new environment.

Since we aim to support user-defined software configurations, we should 
investigate how containers are used in existing continuous integration services 
to alleviate this maintenance overhead.
