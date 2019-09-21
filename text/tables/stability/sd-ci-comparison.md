
Table: Results of comparison of 0.95 confidence intervals of the standard 
deviation of CPU time, with isolate vs. without isolate
\label{sd-ci-comparison}


|Setup                    |Workload       |Bare    |Docker  |VBox    |
|:------------------------|:--------------|:-------|:-------|:-------|
|single,1                 |bsearch        |lesser  |lesser  |same    |
|parallel-synth-cpu,2     |bsearch        |lesser  |lesser  |overlap |
|parallel-synth-cpu,4     |bsearch        |lesser  |lesser  |overlap |
|parallel-synth-cpu,6     |bsearch        |lesser  |lesser  |lesser  |
|parallel-synth-cpu,8     |bsearch        |lesser  |lesser  |higher  |
|parallel-synth-cpu,10    |bsearch        |lesser  |same    |higher  |
|parallel-synth-cpu,20    |bsearch        |same    |same    |overlap |
|parallel-synth-cpu,40    |bsearch        |higher  |overlap |NA      |
|parallel-synth-memcpy,2  |bsearch        |lesser  |overlap |overlap |
|parallel-synth-memcpy,4  |bsearch        |lesser  |lesser  |lesser  |
|parallel-synth-memcpy,6  |bsearch        |lesser  |lesser  |higher  |
|parallel-synth-memcpy,8  |bsearch        |lesser  |lesser  |lesser  |
|parallel-synth-memcpy,10 |bsearch        |lesser  |overlap |same    |
|parallel-synth-memcpy,20 |bsearch        |same    |overlap |higher  |
|parallel-synth-memcpy,40 |bsearch        |higher  |overlap |NA      |
|parallel-homogenous,2    |bsearch        |lesser  |lesser  |lesser  |
|parallel-homogenous,4    |bsearch        |lesser  |overlap |overlap |
|parallel-homogenous,6    |bsearch        |overlap |overlap |same    |
|parallel-homogenous,8    |bsearch        |overlap |overlap |overlap |
|parallel-homogenous,10   |bsearch        |higher  |overlap |same    |
|parallel-homogenous,20   |bsearch        |higher  |lesser  |overlap |
|parallel-homogenous,40   |bsearch        |higher  |same    |NA      |
|single,1                 |exp_float      |lesser  |lesser  |overlap |
|parallel-synth-cpu,2     |exp_float      |lesser  |overlap |same    |
|parallel-synth-cpu,4     |exp_float      |lesser  |lesser  |lesser  |
|parallel-synth-cpu,6     |exp_float      |lesser  |lesser  |higher  |
|parallel-synth-cpu,8     |exp_float      |lesser  |lesser  |lesser  |
|parallel-synth-cpu,10    |exp_float      |lesser  |lesser  |lesser  |
|parallel-synth-cpu,20    |exp_float      |same    |overlap |overlap |
|parallel-synth-cpu,40    |exp_float      |higher  |overlap |NA      |
|parallel-synth-memcpy,2  |exp_float      |lesser  |lesser  |overlap |
|parallel-synth-memcpy,4  |exp_float      |lesser  |lesser  |lesser  |
|parallel-synth-memcpy,6  |exp_float      |lesser  |lesser  |same    |
|parallel-synth-memcpy,8  |exp_float      |lesser  |lesser  |higher  |
|parallel-synth-memcpy,10 |exp_float      |lesser  |lesser  |overlap |
|parallel-synth-memcpy,20 |exp_float      |overlap |overlap |higher  |
|parallel-synth-memcpy,40 |exp_float      |higher  |overlap |NA      |
|parallel-homogenous,2    |exp_float      |lesser  |lesser  |overlap |
|parallel-homogenous,4    |exp_float      |lesser  |lesser  |overlap |
|parallel-homogenous,6    |exp_float      |lesser  |overlap |overlap |
|parallel-homogenous,8    |exp_float      |overlap |overlap |same    |
|parallel-homogenous,10   |exp_float      |overlap |overlap |lesser  |
|parallel-homogenous,20   |exp_float      |higher  |higher  |lesser  |
|parallel-homogenous,40   |exp_float      |higher  |higher  |NA      |
|single,1                 |insertion_sort |overlap |lesser  |overlap |
|parallel-synth-cpu,2     |insertion_sort |lesser  |overlap |same    |
|parallel-synth-cpu,4     |insertion_sort |lesser  |lesser  |lesser  |
|parallel-synth-cpu,6     |insertion_sort |lesser  |lesser  |higher  |
|parallel-synth-cpu,8     |insertion_sort |lesser  |overlap |higher  |
|parallel-synth-cpu,10    |insertion_sort |lesser  |lesser  |higher  |
|parallel-synth-cpu,20    |insertion_sort |same    |same    |same    |
|parallel-synth-cpu,40    |insertion_sort |higher  |overlap |NA      |
|parallel-synth-memcpy,2  |insertion_sort |lesser  |lesser  |higher  |
|parallel-synth-memcpy,4  |insertion_sort |lesser  |lesser  |higher  |
|parallel-synth-memcpy,6  |insertion_sort |lesser  |lesser  |overlap |
|parallel-synth-memcpy,8  |insertion_sort |lesser  |lesser  |higher  |
|parallel-synth-memcpy,10 |insertion_sort |lesser  |lesser  |overlap |
|parallel-synth-memcpy,20 |insertion_sort |higher  |overlap |higher  |
|parallel-synth-memcpy,40 |insertion_sort |higher  |overlap |NA      |
|parallel-homogenous,2    |insertion_sort |lesser  |lesser  |overlap |
|parallel-homogenous,4    |insertion_sort |lesser  |overlap |lesser  |
|parallel-homogenous,6    |insertion_sort |lesser  |overlap |overlap |
|parallel-homogenous,8    |insertion_sort |lesser  |overlap |overlap |
|parallel-homogenous,10   |insertion_sort |overlap |overlap |same    |
|parallel-homogenous,20   |insertion_sort |overlap |overlap |overlap |
|parallel-homogenous,40   |insertion_sort |higher  |lesser  |NA      |
