## Conclusion

The experiment provided us with evidence that isolate has an effect on the 
stability of CPU time measurements. Measurements with isolate exhibit a higher 
mean, but a reduced standard deviation. The exact cause of this remains to be 
researched, along with the curious case of VirtualBox, where this effect does 
not seem to be present. Also, the measurements in VirtualBox seem to be faster 
and more stable than those on the bare metal and in Docker.

Also, we found that measuring many submissions at once impacts the stability of 
measurements. On a system with two 10-core CPUs, a notable decrease in stability 
appeared with as little as 4 parallel workers.

Our experiment also yielded two smaller results. First, the wall-clock time 
measured by isolate tends to be unstable and should not be trusted when high 
precision measurements are required. Of course, this phenomenon should be 
researched further, possibly with newer versions of the kernel.

Second, setting the CPU affinity explicitly does not generally yield any 
improvements to the overall measurement stability, even though the multicore 
affinity setting policy seems to improve the stability for batch measurements on 
the bare metal.

### Discussion

TODO multiple measurements - longer feedback loop (but we can 1. provide 
preliminary results 2. abort on wrong answers 3. abort when a limit is broken by 
a large margin)

TODO instruction counting - pretty stable, but especially memory loads are hard 
to evaluate. Also, the output might be garbage for scripted/managed languages.
