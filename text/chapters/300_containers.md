# Advanced Usage of Containers \label{containers}

In previous chapters, we only considered containers as isolated execution 
environments for programs that save computing resources thanks to sharing most 
of the operating system with the host machine (as opposed to virtual machines, 
for example). Docker containers have also been used as an execution unit for 
assignment evaluation on their own[@DockerAssignmentEvaluation].

However, the capabilities of modern container platforms extend beyond this 
scope. They provide features such as automated building of containers and
transferring them between physical hosts.

This particular functionality can be implemented in multiple ways:

- build containers as Docker images using Dockerfiles (a script-like format that 
  describes the steps to build a container)
- use an alternative image builder based on Dockerfiles (such as 
  `podman`[@Podman] or `buildah`[@Buildah])
- script their creation using simple shell scripts
- use specialized tools such as Ansible or Chef.

Execution of programs in containers can be also done in many ways independent of 
the build mechanism -- even Docker images can be unpacked and executed directly 
or using a different container runtime such as LXC or slurm.

In this chapter, we discuss the possibilities of exploiting these features to 
solve previously mentioned problems in systems for evaluation of programming 
assignments. We also implement a small part of the functionality to show that 
such solution is practically viable.
