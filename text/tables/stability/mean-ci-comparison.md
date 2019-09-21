
Table: Results of comparison of 0.95 confidence intervals of the mean of CPU 
time for selected workloads \label{mean-ci-comparison} on the bare metal (B), 
in docker (D) and in VirtualBox (V)


|Setup                    |Workload  |B vs. D |B vs. V |D vs. V |
|:------------------------|:---------|:-------|:-------|:-------|
|single,1                 |bsearch   |overlap |higher  |higher  |
|parallel-synth-cpu,2     |bsearch   |higher  |higher  |higher  |
|parallel-synth-cpu,4     |bsearch   |overlap |lesser  |lesser  |
|parallel-synth-cpu,6     |bsearch   |lesser  |higher  |higher  |
|parallel-synth-cpu,8     |bsearch   |overlap |lesser  |lesser  |
|parallel-synth-cpu,10    |bsearch   |higher  |lesser  |lesser  |
|parallel-synth-cpu,20    |bsearch   |overlap |overlap |lesser  |
|parallel-synth-cpu,40    |bsearch   |higher  |NA      |NA      |
|parallel-synth-memcpy,2  |bsearch   |higher  |overlap |lesser  |
|parallel-synth-memcpy,4  |bsearch   |overlap |lesser  |lesser  |
|parallel-synth-memcpy,6  |bsearch   |overlap |lesser  |lesser  |
|parallel-synth-memcpy,8  |bsearch   |overlap |lesser  |lesser  |
|parallel-synth-memcpy,10 |bsearch   |higher  |overlap |lesser  |
|parallel-synth-memcpy,20 |bsearch   |lesser  |lesser  |same    |
|parallel-synth-memcpy,40 |bsearch   |higher  |NA      |NA      |
|parallel-homogenous,2    |bsearch   |higher  |higher  |higher  |
|parallel-homogenous,4    |bsearch   |higher  |higher  |higher  |
|parallel-homogenous,6    |bsearch   |higher  |higher  |higher  |
|parallel-homogenous,8    |bsearch   |higher  |higher  |higher  |
|parallel-homogenous,10   |bsearch   |higher  |higher  |higher  |
|parallel-homogenous,20   |bsearch   |lesser  |higher  |higher  |
|parallel-homogenous,40   |bsearch   |higher  |NA      |NA      |
|single,1                 |exp_float |overlap |higher  |higher  |
|parallel-synth-cpu,2     |exp_float |higher  |higher  |higher  |
|parallel-synth-cpu,4     |exp_float |overlap |higher  |higher  |
|parallel-synth-cpu,6     |exp_float |higher  |higher  |lesser  |
|parallel-synth-cpu,8     |exp_float |overlap |lesser  |lesser  |
|parallel-synth-cpu,10    |exp_float |higher  |lesser  |lesser  |
|parallel-synth-cpu,20    |exp_float |same    |higher  |higher  |
|parallel-synth-cpu,40    |exp_float |higher  |NA      |NA      |
|parallel-synth-memcpy,2  |exp_float |overlap |higher  |higher  |
|parallel-synth-memcpy,4  |exp_float |higher  |higher  |same    |
|parallel-synth-memcpy,6  |exp_float |lesser  |same    |higher  |
|parallel-synth-memcpy,8  |exp_float |lesser  |lesser  |lesser  |
|parallel-synth-memcpy,10 |exp_float |overlap |lesser  |lesser  |
|parallel-synth-memcpy,20 |exp_float |overlap |overlap |overlap |
|parallel-synth-memcpy,40 |exp_float |higher  |NA      |NA      |
|parallel-homogenous,2    |exp_float |higher  |higher  |higher  |
|parallel-homogenous,4    |exp_float |higher  |higher  |higher  |
|parallel-homogenous,6    |exp_float |higher  |higher  |higher  |
|parallel-homogenous,8    |exp_float |higher  |higher  |higher  |
|parallel-homogenous,10   |exp_float |higher  |higher  |higher  |
|parallel-homogenous,20   |exp_float |higher  |higher  |higher  |
|parallel-homogenous,40   |exp_float |higher  |NA      |NA      |
