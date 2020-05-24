## Related work

In Section \ref{containers-analysis}, we listed requirements on a programming 
evaluation system that could be solved using container technologies. Because of 
the similarity between automated assignment evaluation and continuous 
integration, we shall survey a handful of public continuous integration services 
and the way they address these requirements.

### GitLab CI

GitLab is a complex platform for developers based on the `git` version control 
system that can be both used as a service and hosted on private infrastructure. 
Continuous integration is one of its features beyond the scope of source code 
management.

The build configuration of a project is a YAML file that specifies a series of 
jobs to be executed. The actual commands to be executed in order to process a 
job are specified either by referencing a shell script or a Docker image name 
and a command to launch inside a container based on the image.

The jobs are executed with the help of GitLab runner -- a program that can be 
installed on worker machines that process builds. Shell scripts invoked by jobs 
are executed without any security layer, which means allowing those is not 
suitable for publicly accessible runners. Docker-based jobs are considered safe 
enough for public runners. The runners shipped with the community GitLab 
instance are run in a virtualized environment[@GitLabScaling], which provides 
another layer of security, along with the possibility of on-demand scaling.

In order to prepare a custom build environment, one must either configure a 
custom runner and use a script-based job, or build a Docker image, push it to a 
Docker registry and use it in the job specification. When the second way is 
used, the GitLab runner automatically fetches the image from the registry before 
the build.

With GitLab CI, it is also possible to use Docker containers to launch 
additional services needed for testing the project -- a typical example would be 
a database or file storage server.

The way the building and testing process is described and processed in CircleCI 
is very similar to that of GitLab CI. Since the way our requirements are handled 
is nearly identical, too, we will not cover CircleCI any further.

### Travis CI

Travis CI is a popular continuous integration server with a straightforward 
configuration language. Unlike GitLab CI and CircleCI, it does not prefer using 
containers to pre-build the testing environment (although it is technically 
possible). Instead, the developers (or the community, in some cases) implement 
the support for each language individually. For many languages, testing against 
multiple versions is supported, and this is achieved either with tools specific 
for each language (such as `phpenv` for PHP) or using the system package manager 
(this is the case for Python).

Since the build configuration can contain arbitrary commands, it is in theory 
possible to support any language by installing the required tools before the 
build itself. However, this approach tends to prolong the builds unnecessarily.

The security of the build process is ensured by launching a separate virtual 
machine that runs Ubuntu (a popular GNU/Linux distribution) for each build of a 
project.

### AppVeyor

At the time of its inception, the most interesting feature of AppVeyor was 
support for Windows builds (alongside Linux builds). Later, other services also 
got this feature. The builds are performed in virtual machines created on demand 
for each build.

The virtual machines are created from an image with a predefined set of 
pre-installed packages. If the build has additional dependencies, they must be 
installed manually (for example, using the NuGet package manager), similarly to 
the case of Travis CI.

In the basic configuration, the builds rely on virtualization for isolation. A 
new virtual machine is created for every build.
