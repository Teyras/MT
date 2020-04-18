## Conclusion

The experiment provided us with evidence that isolate has an effect on the 
stability of CPU time measurements. Measurements with isolate exhibit a higher 
mean, but a reduced standard deviation. The exact cause of this remains to be 
researched, along with the curious case of VirtualBox, where this effect does 
not seem to be present. Also, the measurements in VirtualBox seem to be faster 
and more stable than those on the bare metal and in Docker.

Also, we found that measuring many submissions at once impacts the stability of 
measurements. On a system with two 10-core CPUs, a notable decrease in stability 
appeared with as little as 4 parallel workers. However, the requirements for 
measurement stability vary for different assignments and decisions about worker 
deployment should be based on test measurement data.

The fact that measurements on the same machine interfere with each other has one 
more consequence -- using common virtualized platforms for evaluation is not an 
option when stable measurements are required, since we have no control of 
neither the hardware performing the measurements nor other programs being 
executed in parallel.

Our experiment also yielded three smaller results. First, the wall-clock time 
measured by isolate tends to be unstable and should not be trusted when high 
precision measurements are required. Of course, this phenomenon should be 
researched further, possibly with newer versions of the kernel.

Second, setting the CPU affinity explicitly does not generally yield any 
improvements to the overall measurement stability, even though the multicore 
affinity setting policy seems to improve the stability for batch measurements on 
the bare metal. The results with `isolate` are less conclusive

Third, disabling logical cores also seems to improve measurement stability on 
the bare metal when the number of parallel workers is constant. Same as in the 
case of multicore affinity setting, this phenomenon is less evident when
`isolate` is used, and therefore less likely to bring any practical 
improvements.

### Discussion

It seems that taking advantage of servers with multiple CPU cores for assignment 
evaluation is difficult due to the instability introduced by parallel 
measurements. Here, we present a handful of proposals that could improve the 
situation, and that could serve as a basis for future work.

#### Repeated Measurements

Performing multiple measurements and outputting an extended summary of the 
results, such as a trimmed mean and standard deviation, could be a statistically 
sound way of counteracting the instability. This approach comes with a higher 
computational cost, which would incur both a larger latency (and worse user 
experience) and a smaller throughput of the whole system. However, there are 
several measures we could take to alleviate this:

- Provide preliminary results after the first measurement, so that students 
  receive feedback quickly, even if it might be subject to change later.
- Abort repeated evaluations if the submission fails for reasons different than 
  an exceeded time limit (typically a wrong output) in at least one of the 
  tests.
- If a test exceeds the time limit by a large margin, abort repeated 
  measurements.

These mitigation steps, along with being able to use more cores than if we 
relied on a single measurement, might lead to a better overall throughput of the 
system and a tolerable increase in latency.

#### Instruction Counting

The count of executed instructions is a stable measure of execution time that we 
could use for judging instead of the CPU time or wall clock time. However, there 
are multiple considerations:

- The execution time of different types of instructions can vary. A possible 
  implementation could assign a cost to each instruction type and then calculate 
  the sum of the instruction counts multiplied by their respective costs. 
- To our best knowledge, there is no practical way of measuring the exact number 
  of executed instructions divided by type. A sample could be obtained by 
  profiling the submission using the `perf` tool. If we chose to sample too 
  frequently, we might unnecessarily prolong the evaluation.
- Sampling parallelized programs might impact their performance.
- The execution costs of instructions, and even the instruction set itself, can 
  vary with different processor models.

#### Using Single-board Computers

Using a large number of single board computers (such as the Raspberry Pi), where 
each evaluates a single submission might prove to be a viable alternative to 
using a server machine. We could achieve a large degree of parallelism without 
any concern about measurements influencing each other. The total power 
consumption of these computers should be comparable to that of a single server 
computer. However, the fact that most single computers use a different 
instruction set than x86 might restrict the set of usable exercises.
