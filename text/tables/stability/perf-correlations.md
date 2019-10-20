
Table: Correlation of CPU time and selected performance metrics \label{perf-correlations}
        
|Metric           |Workload  | Pearson correlation| Spearman correlation|
|:----------------|:---------|-------------------:|--------------------:|
|L1_dcache_misses |exp_float |              -0.009|                0.103|
|LLC_store_misses |exp_float |              -0.016|                0.016|
|LLC_load_misses  |exp_float |              -0.013|               -0.003|
|L1_dcache_misses |bsearch   |               0.417|                0.254|
|LLC_store_misses |bsearch   |              -0.070|                0.038|
|LLC_load_misses  |bsearch   |              -0.111|               -0.108|
|L1_dcache_misses |gray2bin  |              -0.002|                0.100|
|LLC_store_misses |gray2bin  |              -0.125|               -0.003|
|LLC_load_misses  |gray2bin  |              -0.076|               -0.088|
|L1_dcache_misses |qsort     |               0.083|                0.148|
|LLC_store_misses |qsort     |              -0.099|                0.037|
|LLC_load_misses  |qsort     |              -0.080|               -0.086|
