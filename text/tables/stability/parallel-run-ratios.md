
Table: Ratios between total runtime and time spent with all processes running in 
parallel in ascending order (truncated, there are over 300 groups)
\label{parallel-run-ratios}

|   Workers | Workload       | Isolation      | Ratio   |
|----------:|:---------------|:---------------|:--------|
|        20 | qsort          | vbox-bare      | 67.97%  |
|        20 | qsort          | vbox-isolate   | 72.31%  |
|        20 | gray2bin       | docker-bare    | 82.17%  |
|        20 | bsearch        | docker-bare    | 82.29%  |
|        40 | exp_float      | docker-bare    | 82.83%  |
|        40 | exp_double     | docker-bare    | 83.24%  |
|        40 | gray2bin       | docker-bare    | 84.48%  |
|        40 | insertion_sort | docker-bare    | 85.50%  |
|        20 | insertion_sort | docker-bare    | 86.91%  |
|        40 | insertion_sort | isolate        | 87.12%  |
|        20 | exp_float      | docker-bare    | 87.35%  |
|         8 | bsearch        | vbox-bare      | 87.85%  |
|        20 | exp_float      | vbox-bare      | 87.86%  |
|        40 | qsort          | docker-isolate | 88.43%  |
|        40 | bsearch        | docker-isolate | 88.44%  |
|        40 | qsort          | docker-bare    | 88.48%  |
|         6 | insertion_sort | vbox-bare      | 88.48%  |
|         4 | exp_double     | vbox-bare      | 88.65%  |
|         4 | insertion_sort | vbox-bare      | 88.67%  |
|         4 | exp_float      | vbox-bare      | 88.93%  |
|        40 | bsearch        | docker-bare    | 89.04%  |
|         8 | insertion_sort | vbox-bare      | 89.20%  |
|         4 | qsort          | vbox-bare      | 89.23%  |
|        20 | qsort          | docker-bare    | 89.35%  |
|        10 | exp_double     | vbox-bare      | 89.74%  |
|        40 | exp_double     | isolate        | 89.82%  |
