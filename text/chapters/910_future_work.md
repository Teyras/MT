## Future Work

There are multiple possible continuations of our research that could lead to 
even better performance in evaluation of programming assignments. In this 
section, we present the most promising ones.

Single board computers seem like a promising platform for assignment evaluation. 
If we managed to prove that these devices can process assignments similarly to 
conventional computers and that their measurements are reasonably stable, they 
could be used for most exercise types. This has two considerable advantages. 
Firstly, using each computer to only evaluate one submission at a time is not as 
wasteful as in the case of machines with modern multi-core CPUs. Secondly, the 
cost of adding a new single-board computer to the system is rather small in 
comparison to e.g., server machines. Due to these facts, we could increase the 
overall throughput of the system much more easily and without concerns about 
measurement stability.

Furthermore, implementing on demand scaling using switched power supplies could 
be a way to make the system more cost-effective while maintaining an acceptable 
throughput during traffic peaks.

Another way of mitigating measurement instability introduced by isolation 
technologies and parallel measurements is repeating them multiple times. 
Proposing a process that summarizes these results for grading and evaluating it 
in various settings is an interesting research topic. If such process was found, 
it would allow us to use multi-core CPUs and cloud virtual machines more freely, 
without risking awarding a solution with an unfair grade due to measurement 
interference. Additionally, the influence of this mechanism on scheduling should 
be studied, since the amount of work to be distributed over the worker machines 
would become larger.

In our survey of scheduling algorithms, we did not closely examine those that 
employ preemption. Designing a preemption mechanism that could realistically be 
implemented in an assignment evaluation platform while keeping measurements 
stable would open a path to using more advanced scheduling algorithms that could 
prevent starvation of short jobs in a situation where the system is occupied by 
longer jobs.
