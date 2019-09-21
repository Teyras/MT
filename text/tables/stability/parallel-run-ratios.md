
Table: Ratios between total runtime and time spent with all processes running in 
parallel in ascending order (truncated, there are over 300 groups)
\label{parallel-run-ratios}

|   Workers | Workload       | Isolation      | Ratio   |
|----------:|:---------------|:---------------|:--------|
|        20 | exp_float      | vbox-bare      | 64.86%  |
|        20 | insertion_sort | docker-bare    | 81.95%  |
|        40 | insertion_sort | docker-bare    | 83.08%  |
|        20 | gray2bin       | docker-bare    | 83.33%  |
|        40 | exp_float      | docker-bare    | 83.41%  |
|        40 | exp_double     | docker-bare    | 83.73%  |
|        20 | qsort_java.sh  | vbox-isolate   | 83.90%  |
|        40 | gray2bin       | docker-bare    | 84.50%  |
|         4 | gray2bin       | vbox-bare      | 84.85%  |
|        20 | qsort.py       | vbox-isolate   | 85.67%  |
|        40 | qsort          | docker-bare    | 86.19%  |
|        20 | bsearch        | docker-bare    | 86.46%  |
|        40 | qsort          | docker-isolate | 87.42%  |
|        40 | insertion_sort | docker-isolate | 87.60%  |
|         4 | insertion_sort | vbox-bare      | 88.01%  |
|        20 | qsort_java.sh  | vbox-bare      | 88.48%  |
|         4 | bsearch        | vbox-bare      | 88.51%  |
|         2 | gray2bin       | vbox-bare      | 88.51%  |
|        40 | qsort_java.sh  | docker-isolate | 88.53%  |
|        20 | exp_double     | docker-bare    | 88.59%  |
|         4 | exp_double     | vbox-bare      | 88.62%  |
|        40 | bsearch        | docker-bare    | 88.69%  |
|        10 | gray2bin       | vbox-bare      | 88.96%  |
|         6 | exp_double     | vbox-bare      | 89.17%  |
|        10 | exp_float      | vbox-bare      | 89.25%  |
|        40 | exp_float      | docker-isolate | 89.28%  |
|        40 | exp_float      | isolate        | 89.38%  |
|        20 | insertion_sort | vbox-bare      | 89.57%  |
|        40 | bsearch        | isolate        | 89.62%  |
|        40 | gray2bin       | isolate        | 89.78%  |
|        40 | exp_double     | docker-isolate | 89.90%  |
