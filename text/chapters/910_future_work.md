## Future Work

- Running evaluations on single board computers seems like a promising way for 
  programming assignment evaluation. Since each computer would only evaluate one 
  submission at a time, there would be no interference between measurements that 
  would negatively influence their stability. Of course, the influence of 
  isolation technologies would still have to be assessed. Additionaly, 
  implementing on demand scaling using switched power supplies could be a way to 
  make the system more cost-effective while maintaining an acceptable throughput 
  during traffic peaks.
- Repeating measurements multiple times could alleviate the instability of 
  results introduced by isolation technologies and parallel measurements, 
  allowing us to use multi-core CPUs or cloud virtual machines. This would 
  require finding an appropriate statistical operation to aggregate the results 
  and evaluating its efficiency in various settings.
- This text does not closely examine using preemption in scheduling. Proposing a 
  preemption mechanism that could realistically be implemented in an assignment 
  evaluation platform while keeping measurements stable would open a path to 
  using more advanced scheduling algorithms that could prevent starvation of 
  short jobs in a situation where the system is occupied by longer jobs.
- Data from an evaluation system with large enough traffic could be used to 
  implement a practical on demand scaling solution.

