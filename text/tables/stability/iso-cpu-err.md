
Table: Mean and standard deviation of the error of isolate CPU time measurements, sorted by relative error (truncated) \label{iso-cpu-err}

|Setup                    |Isolation |Workload       | Mean [s]|    SD| CV [%]|
|:------------------------|:---------|:--------------|--------:|-----:|------:|
|parallel-synth-cpu,4     |D+I       |insertion_sort |    0.003| 0.000|  0.182|
|parallel-homogenous,4    |D+I       |exp_float      |    0.003| 0.001|  0.182|
|parallel-homogenous,8    |D+I       |exp_float      |    0.003| 0.001|  0.182|
|parallel-synth-cpu,4     |I         |insertion_sort |    0.003| 0.000|  0.182|
|parallel-homogenous,4    |D+I       |exp_double     |    0.003| 0.001|  0.180|
|parallel-homogenous,2    |I         |insertion_sort |    0.003| 0.000|  0.180|
|parallel-homogenous,10   |I         |exp_double     |    0.003| 0.001|  0.179|
|single,1                 |D+I       |insertion_sort |    0.003| 0.000|  0.179|
|parallel-synth-memcpy,20 |V+I       |exp_float      |    0.004| 0.001|  0.178|
|parallel-homogenous,10   |D+I       |exp_double     |    0.003| 0.001|  0.178|
|parallel-homogenous,10   |I         |exp_float      |    0.003| 0.001|  0.176|
|parallel-homogenous,20   |V+I       |qsort.py       |    0.179| 0.017|  0.176|
|parallel-synth-memcpy,2  |I         |insertion_sort |    0.003| 0.000|  0.174|
|parallel-homogenous,8    |I         |exp_double     |    0.003| 0.001|  0.174|
|parallel-synth-cpu,8     |D+I       |insertion_sort |    0.003| 0.000|  0.170|
|parallel-homogenous,8    |D+I       |exp_double     |    0.003| 0.001|  0.167|
|parallel-synth-memcpy,20 |I         |insertion_sort |    0.003| 0.000|  0.167|
|parallel-synth-memcpy,6  |D+I       |gray2bin       |    0.003| 0.000|  0.166|
|parallel-homogenous,2    |V+I       |gray2bin       |    0.001| 0.000|  0.166|
|parallel-homogenous,2    |V+I       |insertion_sort |    0.001| 0.000|  0.166|
|parallel-synth-memcpy,10 |D+I       |gray2bin       |    0.004| 0.000|  0.165|
|parallel-homogenous,20   |I         |bsearch        |    0.003| 0.001|  0.165|
|parallel-homogenous,4    |I         |exp_double     |    0.003| 0.001|  0.165|
|parallel-synth-memcpy,20 |V+I       |exp_double     |    0.004| 0.001|  0.164|
|parallel-synth-cpu,20    |V+I       |exp_float      |    0.001| 0.001|  0.164|
|parallel-homogenous,20   |D+I       |bsearch        |    0.003| 0.001|  0.164|
|parallel-homogenous,2    |I         |exp_float      |    0.003| 0.000|  0.163|
|parallel-homogenous,2    |D+I       |exp_double     |    0.003| 0.000|  0.163|
|parallel-synth-memcpy,20 |D+I       |exp_double     |    0.004| 0.001|  0.162|
|parallel-synth-memcpy,40 |D+I       |exp_float      |    0.007| 0.001|  0.162|
|parallel-synth-memcpy,10 |D+I       |exp_float      |    0.003| 0.001|  0.161|
|parallel-homogenous,2    |V+I       |qsort.py       |    0.135| 0.011|  0.161|
|parallel-synth-memcpy,4  |I         |insertion_sort |    0.003| 0.000|  0.161|
|single,1                 |D+I       |exp_double     |    0.003| 0.000|  0.154|
