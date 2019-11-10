# Advanced Usage of Containers

In previous chapters, we only considered containers as isolated execution 
environments for programs that save computing resources thanks to sharing most 
of the operating system with the host machine (as opposed to virtual machines, 
for example).

However, the capabilities of modern container platforms extend beyond this 
scope. They provide features such as reproducible building of containers and
transferring them between physical hosts.

This particular functionality can be implemented in multiple ways -- we can 
build containers as Docker images using Dockerfiles (a script-like format that 
describes the steps to build a container), we can script their creation using 
simple shell scripts or use specialized tools such as Ansible or Chef. Execution 
of programs in containers can be also implemented in many ways independent of 
the build mechanism -- even Docker images can be unpacked and executed directly 
or using a different container runtime such as LXC or slurm.

In this chapter, we discuss the possibilities of exploting these features to 
solve previously mentioned problems in systems for evaluation of programming 
assignments.
