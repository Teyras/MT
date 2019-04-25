## Conclusion

The experiment provided us with evidence that isolate has a negative effect on 
the stability of CPU time measurements. The exact cause of this remains to be 
researched, along with the curious case of VirtualBox, where this effect does 
not seem to be present. The difference in measurement stability does not seem to 
be too big for the examined isolation technologies.

Also, we found that measuring many submissions at once impacts the stability of 
measurements. On a system with two 10-core CPUs, a notable decrease in stability 
appeared with as little as 4 parallel workers.

Our experiment also yielded two smaller results. First, the wall-clock time 
measured by isolate tends to be unstable and should not be trusted when high 
precision measurements are required. Of course, this phenomenon should be 
researched further, possibly with newer versions of the kernel.

Second, setting the CPU affinity explicitly does not generally yield any 
improvements to the overall measurement stability, even though it seems to 
improve the stability for the individual worker processes.
