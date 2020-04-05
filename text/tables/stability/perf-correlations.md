
Table: Pearson (standard) and Spearman correlation of CPU time and selected performance metrics \label{perf-correlations}
        
|Metric           |Workload  |     Median| Pearson| Spearman|
|:----------------|:---------|----------:|-------:|--------:|
|L1_dcache_misses |exp_float |   270984.5|  -0.009|    0.103|
|LLC_store_misses |exp_float |    14635.5|  -0.016|    0.016|
|LLC_load_misses  |exp_float |     7047.5|  -0.013|   -0.003|
|page_faults      |exp_float |      396.5|  -0.034|   -0.079|
|L1_dcache_misses |bsearch   | 15166744.0|   0.417|    0.254|
|LLC_store_misses |bsearch   |    16644.0|  -0.070|    0.038|
|LLC_load_misses  |bsearch   |    94619.5|  -0.111|   -0.108|
|page_faults      |bsearch   |      388.5|  -0.082|    0.015|
|L1_dcache_misses |gray2bin  |   826283.5|  -0.002|    0.100|
|LLC_store_misses |gray2bin  |    17990.0|  -0.125|   -0.003|
|LLC_load_misses  |gray2bin  |   123149.5|  -0.076|   -0.088|
|page_faults      |gray2bin  |     1348.5|  -0.143|   -0.088|
|L1_dcache_misses |qsort     |  1570664.0|   0.083|    0.148|
|LLC_store_misses |qsort     |    19243.5|  -0.099|    0.037|
|LLC_load_misses  |qsort     |   124440.0|  -0.080|   -0.086|
|page_faults      |qsort     |     1348.5|  -0.117|   -0.041|
