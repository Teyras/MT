
Table: Results of comparison of 0.95 confidence intervals of the mean of CPU 
time for selected workloads \label{mean-ci-comparison} on the bare metal (B), 
in docker (D) and in VirtualBox (V)


|Setup                    |Workload  |B vs. D |B vs. V |D vs. V |
|:------------------------|:---------|:-------|:-------|:-------|
|single,1                 |bsearch   |overlap |overlap |same    |
|parallel-synth-cpu,2     |bsearch   |higher  |higher  |overlap |
|parallel-synth-cpu,4     |bsearch   |lesser  |lesser  |lesser  |
|parallel-synth-cpu,6     |bsearch   |lesser  |lesser  |lesser  |
|parallel-synth-cpu,8     |bsearch   |lesser  |lesser  |lesser  |
|parallel-synth-cpu,10    |bsearch   |higher  |lesser  |lesser  |
|parallel-synth-cpu,20    |bsearch   |lesser  |lesser  |lesser  |
|parallel-synth-cpu,40    |bsearch   |higher  |NA      |NA      |
|parallel-synth-memcpy,2  |bsearch   |higher  |higher  |same    |
|parallel-synth-memcpy,4  |bsearch   |higher  |lesser  |lesser  |
|parallel-synth-memcpy,6  |bsearch   |lesser  |lesser  |lesser  |
|parallel-synth-memcpy,8  |bsearch   |lesser  |lesser  |lesser  |
|parallel-synth-memcpy,10 |bsearch   |overlap |lesser  |lesser  |
|parallel-synth-memcpy,20 |bsearch   |lesser  |lesser  |lesser  |
|parallel-synth-memcpy,40 |bsearch   |higher  |NA      |NA      |
|parallel-homogenous,2    |bsearch   |overlap |higher  |higher  |
|parallel-homogenous,4    |bsearch   |overlap |higher  |higher  |
|parallel-homogenous,6    |bsearch   |higher  |higher  |higher  |
|parallel-homogenous,8    |bsearch   |higher  |higher  |same    |
|parallel-homogenous,10   |bsearch   |higher  |higher  |overlap |
|parallel-homogenous,20   |bsearch   |lesser  |overlap |higher  |
|parallel-homogenous,40   |bsearch   |higher  |NA      |NA      |
|single,1                 |exp_float |higher  |higher  |same    |
|parallel-synth-cpu,2     |exp_float |higher  |higher  |same    |
|parallel-synth-cpu,4     |exp_float |higher  |higher  |overlap |
|parallel-synth-cpu,6     |exp_float |lesser  |lesser  |lesser  |
|parallel-synth-cpu,8     |exp_float |higher  |overlap |overlap |
|parallel-synth-cpu,10    |exp_float |overlap |lesser  |lesser  |
|parallel-synth-cpu,20    |exp_float |overlap |lesser  |lesser  |
|parallel-synth-cpu,40    |exp_float |higher  |NA      |NA      |
|parallel-synth-memcpy,2  |exp_float |higher  |higher  |same    |
|parallel-synth-memcpy,4  |exp_float |higher  |lesser  |lesser  |
|parallel-synth-memcpy,6  |exp_float |lesser  |lesser  |lesser  |
|parallel-synth-memcpy,8  |exp_float |lesser  |lesser  |lesser  |
|parallel-synth-memcpy,10 |exp_float |overlap |same    |same    |
|parallel-synth-memcpy,20 |exp_float |same    |lesser  |lesser  |
|parallel-synth-memcpy,40 |exp_float |higher  |NA      |NA      |
|parallel-homogenous,2    |exp_float |higher  |higher  |higher  |
|parallel-homogenous,4    |exp_float |overlap |higher  |higher  |
|parallel-homogenous,6    |exp_float |higher  |higher  |higher  |
|parallel-homogenous,8    |exp_float |higher  |higher  |higher  |
|parallel-homogenous,10   |exp_float |higher  |higher  |higher  |
|parallel-homogenous,20   |exp_float |higher  |lesser  |lesser  |
|parallel-homogenous,40   |exp_float |higher  |NA      |NA      |
