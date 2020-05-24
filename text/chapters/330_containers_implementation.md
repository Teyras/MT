## Implementation Analysis

Based on our analysis of the features of continuous integration systems, we 
propose a way of leveraging container platforms in automated evaluation of 
programming assignments, using ReCodEx as a model. We also provide a basic 
implementation of this functionality.

Since Docker is one of the most well-known container technologies and all the 
continuous integration services we surveyed support it in some way, we will use 
it in our implementation. However, the ideas we present here should be trivially 
transferable to any container platform based on the OCI[@OCI] (the Open 
Containers Initiative) specification.

### Docker Overview

Before we describe the implementation itself, we shall outline the basic 
features of Docker needed to understand the reasoning behind our design choices.

Docker is a software distribution platform that uses Linux containers to build 
and ship programs along with their dependencies and to allow deploying them on 
any host, without conflicting with installed software and other containers.

This functionality is enabled by the Docker daemon. The daemon is controlled 
through an HTTP API, which is even used by the command line application 
typically used to manage Docker containers. Since the API is usually accessible 
through a UNIX socket, it is even possible to have containers that control the 
Docker daemon.

The most important concept is an image, which is basically a snapshot of a 
minimal operating system that contains an application and its dependencies. An 
image is composed of layers -- collections of files that we can imagine being 
laid on top of each other, making only the latest version of a file visible. 
This mechanism is useful for efficient updates and extension of images -- image 
authors can easily add layers to install additional libraries, for example.
Every image contains a manifest - a collection of various metadata about the 
image, its contents and the intended usage. It is also possible to add 
user-defined labels that could be leveraged by higher layers of an assignment
evaluation system.

Images are used for the creation of containers. These can be thought of as 
concrete instances of an image. A container is created by adding a writable 
layer on top of the layers of an image, which is a rather fast operation. 
Typically, there should only be a single process running inside a container. 
However, this rule is not enforced by the platform in any way -- it is more of a 
design recommendation. Containers are often configured using environment 
variables passed from the host when they are created. It is also possible to 
bind network ports of a container to host ports and to mount parts of the host 
file system into a container.

Typically, images are built using a `Dockerfile` -- a structured file that 
contains instructions on the build process. These are for example copying files 
from the build machine and running shell commands inside the container. Each 
instruction results in the creation of a new layer. The `Dockerfile` format 
provides a simple way of extending an existing image. Alternative ways of 
creating an image exist too, such as launching a shell inside a container, 
making changes to it manually and then copying the writable layer of the 
container and marking it as a new image layer (using the `commit` Docker 
command).

The layers of images are stored persistently on the file system of the Docker 
host. Multiple storage backends exist, but `overlay2` is the recommended and 
most widely used one. It is based on the OverlayFS file system module present in 
the Linux kernel, which allows mounting several directories on top of each 
other, where files are read from the highest layer that contains the requested 
file and writes are only made to the uppermost layer. Alternatives to `overlay2` 
are for example `devicemapper` or `btrfs` (which uses copy on write file system 
subvolumes, a feature of the btrfs filesystem in Linux).

To allow transferring container images between hosts, Docker defines the 
Registry API, which has a simple implementation that can be deployed using 
Docker. The Registry API was standardized by the OCI distribution specification 
after being used extensively in practice. The daemon can upload images to the 
registry with the `push` command and download them with the `pull` command. Both 
of these commands utilize layers, which makes transferring the images efficient.

### Secure Execution

It is not surprising that virtual machines are considered secure enough to run 
untrusted code by the likes of Appveyor and Travis CI. The more interesting fact 
is that Docker containers are also used as an isolation layer (for example in 
CircleCI).

Since Docker uses Linux namespaces to create an isolated environment for the 
programs running inside the container, it should, at least in theory, be on par 
with `isolate`. In the default setup, it does not feature measurements and 
limiting of resource usage (time, memory, disk usage, ...). With further 
configuration, a memory limit can be set. However, adding time and disk usage 
limits and gathering statistics after the evaluated solution finishes would 
require implementing a supervisor program instead of just launching Docker 
containers and waiting for them to finish.

Because Docker cannot be used for securely measuring assignment solutions on its 
own, it will probably not replace `isolate` in ReCodEx in the near future. 
However, there are ways in which it could complement it -- for example, it could 
be leveraged to add precise definitions of runtime environments -- in ReCodEx, 
they all rely on the diligence of administrators to function correctly.

### Deployment of New Runtime Environments

CircleCI and GitLab CI both run tests in Docker containers and it is possible to 
supply custom containers, which allows a great deal of flexibility and also a 
performance increase, since the environment does not have to be prepared again 
with each build.

This kind of functionality would also be useful in ReCodEx. An additional 
benefit in this case would be that the evaluations would be more reproducible, 
theoretically even after a longer period of time.

There are two possibilities of integrating containers into ReCodEx. We could put 
the worker binary itself into a container, along with `isolate` and the tools 
required by a particular set of runtime environments, to create an all-in-one 
image of sorts. This approach is similar to supplying custom runners in GitLab 
CI. The alternative is packaging each runtime environment in a separate image, 
keeping the worker separated and implementing launching images in the worker, 
which is more similar to how CircleCI and GitLab CI work with containers.

The all-in-one image approach allows things such as running specialized, heavily 
modified versions of the worker itself, which might be needed by some future 
exercises (for example running a program on a remotely controlled cluster of 
servers). Also, while adding a new runtime environment would mean extending the 
worker image and deploying it everywhere, we would not have to change the worker 
selection algorithm in the broker -- the available runtime environments could 
still be enumerated in the configuration broadcast by the worker bundled in 
the image.

However, extending a particular environment with a library only for a set of 
exercises would either mean adding it to an existing environment (thus making it 
accessible in other assignments), or creating a new, globally visible runtime 
environment that would eventually be deployed on every worker. Supporting 
multiple versions of libraries or runtime environments at the same time would 
also be a challenge. 

An advantage of the worker-less, single purpose image approach is that we would 
not need to maintain a large worker image with all the desired runtime 
environments. The images would be smaller, easier to review and faster to build. 
Also, a single worker could handle multiple versions of a runtime environment 
without significant effort, which would contribute to the repeatability of 
assignment evaluations. A drawback of this approach is that support for fetching 
and updating these single purpose images would have to be added to the worker 
daemon.

We could also implement a middle-ground approach that puts the worker inside a 
container (similarly to the all-in-one image variant), but only with the support 
for a single runtime environment (e.g., Java or Python). This would make it easy 
to create isolated, single-purpose runtime environment images. However, every 
time a different environment was requested, the container with the worker would 
have to be stopped and a different image would have to be used. Instructing the 
host machine to switch worker containers would be a responsibility of the 
broker. The lack of advantages over the single purpose image approach and the 
need to add more responsibilities to the broker makes this approach impractical.

From the two basic approaches, we selected the second one, where only a single 
runtime environment is contained in each images and the worker is responsible 
for handling and switching the images. The main reason for this choice is that 
it makes it easier to maintain a set of curated runtime environments created by 
exercise authors. With the first approach, this would require administrators to 
modify the main worker image each time somebody wishes to create a new runtime 
environment. Furthermore, the second approach makes it much simpler to create 
single use environments that will only be used for a small set of exercises.

#### Building and Distribution of Images

In our implementation, we shall deploy a registry instance to be used by the 
workers and the Web API server, without being directly accessible to the public.
The registry will serve as a storage of runtime environment images.

As opposed to the variant with a publicly accessible registry, we have full 
control of the images. However, we have to build them too, which would not be a 
requirement with the public registry -- users could build the images locally and 
just upload them. Although it would be more convenient (we would not need to 
maintain a build service), it would also be much harder to audit the built 
images, since the images are basically just archives that can contain anything. 

The exercise authors who desire to create a new runtime environment will simply 
write a `Dockerfile` that creates an image with all the tools they need to 
evaluate an exercise. The `Dockerfile` will then be uploaded to the backend 
using the Web API. After a review by an administrator, it will be passed to a 
build server, which will then push the resulting image to the registry, making 
it available to workers. An advantage of this approach is that it is easy to 
extend existing images using the `FROM` clause in a `Dockerfile`. Aside from 
being simple for exercise authors, this also allows for efficient use of storage 
space -- the base image is only stored once and the images that extend it only 
contain new and changed files.

When a worker starts evaluating a solution that requires a newly created runtime 
environment, it will simply pull the image from the registry. The worker will 
also have to be modified to advertise the runtime environments that are 
available in the Docker registry so that the broker assigns jobs to it 
correctly.

### Launching Containers with `isolate` \label{launching-containers}

Each time the worker encounters a command that instructs it to execute a command 
in a container, it has to perform multiple steps:

1. Pull the image from the registry (if the image is not present yet)
2. Make the image accessible through the file system so that it can be used by 
   `isolate`
3. Launch a command with `isolate`, using the image as the file system root

Of these steps, number 1 and 3 are rather simple. Number 1 only requires us to 
execute a single command and the Docker daemon will fetch all the files for us. 
Number 3 is already implemented by the worker and it does not need any 
adjustments.

Step number 2 is more challenging. A naïve approach would be to simply unpack 
the image data each time we need to execute a command in it. This is implemented 
by tools such as Charliecloud or `umoci`, but the process is not very 
complicated and we could also easily implement it on our own. Repeated copying 
of image contents is inefficient for obvious reasons -- typically, an evaluation 
requires the execution of tens of commands and an image can have hundreds of 
megabytes. In total, this might cause a sizable overhead, as well as wear of the 
hard drive.

There are two similar ways we could improve this situation. First, we could 
mount the image exactly the way Docker does it. The default way is mounting the 
layers of the image using `overlay2`. Since the default configuration is also 
recommended by the developers and supported on all recent versions of the Linux 
kernel, supporting the other storage backends is not much of a concern.

A less complicated way of accessing the image contents is unpacking the images 
immediately at the moment when they are downloaded. Then, when the image is 
needed, we could simply link the image contents to the working directory of 
`isolate`. A drawback of this approach is that it is not as efficient with disk 
space usage. Each image has to be stored by the Docker daemon (which is 
efficient thanks to the layers mechanism), and the unpacked data have to be 
stored elsewhere, duplicating data of base images.

Since it is feasible to implement both of the alternatives and compare them, the 
exact method of making the image contents accessible to the evaluation sandbox 
should be chosen with respect to the results of this comparison.

### Adding Auxiliary Services 

Some types of exercises require a number of supporting services to run during 
the execution. For example, there might be an exercise in web programming that 
requires students to query a relational database server and output the result in 
a prescribed form. In this case, this requirement could be bypassed using a 
single file-backed database such as SQLite. However, this is not possible for 
every exercise type. There have even been exercises based on communication with 
a daemon-like service created by the exercise author.

The current job configuration format consumed by the worker does not allow this. 
With Docker, we can easily start a set of pre-configured containers using 
publicly available images (or, if needed, images from our private registry used 
for runtime environments) for each test and shut them down afterwards. These 
services will run in an isolated network namespace into which the tested program 
will be added. This ensures that we can run multiple evaluations of such 
exercises without a risk of network address and port conflicts.

Implementing this feature will require changes to the job configuration format. 
Since the individual tests of a solution should be isolated and independent on 
the order of execution, it would make sense to start the auxiliary services 
before each test and tear them down after it finishes. This could be implemented 
by adding a parameter to execution types. However, cases exist where keeping the 
services running for multiple tests makes sense -- for example, when the 
services are guaranteed to have no changing internal state or when they take a 
lot of time to launch.

Due to the explicit and rather verbose nature of the job configurations, we 
decided to create two new atomic task types that start and stop a container with 
a service. This will typically be hidden from end users by a higher level 
configuration form.

## Implementation and Evaluation

To prove that the implementation we propose is practically feasible, we 
implemented three core parts of it:

1. fetching the contents of an image from a Docker registry,
2. unpacking an image into a directory by copying its layers, and
3. mounting the image layers using the `overlay2` file system driver.

The reason why we decided to also implement the image fetching is that it allows 
our solution to work on systems without a Docker installation. This is an 
important consideration because the Docker daemon is relatively complex and 
requires extensive privileges, which might be a concern for some administrators.

The unpacking and mounting of images are alternative approaches discussed in 
Section \ref{launching-containers}. We performed a rather simple experiment to 
compare their performance. We selected four official Docker images with varying 
overall size and number of layers:

- `alpine`, version 3.11.6 (2 MB, 1 layer)
- `fedora`, version 31 (64 MB, 1 layer)
- `python`, version 3.8.2 (341 MB, 9 layers)
- `glassfish`, version 4.1-jdk8 (334 MB, 10 layers)

For these images, we performed a sequence of 10 mount and unmount cycles and 10 
unpack and remove cycles. This procedure was measured 100 times, giving 1000 
measured operations in total. We measured blocks of 10 operations to alleviate 
the overhead of the benchmark program in cases where the operations only took 
milliseconds to complete (this is the case of the `alpine` image).

The measurements were performed on a laptop computer with an Intel i7-8850H CPU 
and a NVMe SSD hard drive (Toshiba KSG60ZMV256) running Linux 5.6.8.

The measurement results are depicted in Figure \ref{container-unpack-results}. 
We can safely conclude that unpacking an image by copying its content onto the 
file system is slower than mounting it, even though the difference is not as 
large as we have presumed. A more important result is that accessing image 
contents usually takes less than a second (and much less than that for small 
images), which is a reasonable amount of overhead in the case of programming 
assignment evaluation.

We decided that despite its large implementation complexity, directly mounting 
the layers of the image is a better approach because of its efficiency in terms 
of storage and because it is generally advisable to avoid writing large 
quantities of data on the hard drive frequently to prevent unnecessary 
shortening its lifespan.

![The results of experimental evaluation of the performance of unpacking and 
mounting the contents of various Docker images 
\label{container-unpack-results}](img/containers/mount-vs-unpack.tex)
