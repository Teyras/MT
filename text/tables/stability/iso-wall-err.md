
Table: Mean and standard deviation of the error of isolate wall-clock time measurements (truncated) \label{iso-wall-err}

|Setup                    |Isolation |Workload       | Mean [s]|    SD|  CV [%]|
|:------------------------|:---------|:--------------|--------:|-----:|-------:|
|parallel-homogenous,40   |D+I       |insertion_sort |    0.372| 0.506| 197.424|
|parallel-homogenous,40   |D+I       |exp_double     |    0.354| 0.471| 145.660|
|parallel-homogenous,40   |I         |insertion_sort |    0.265| 0.352| 138.451|
|parallel-homogenous,20   |I         |qsort          |    0.146| 0.137|  34.891|
|parallel-homogenous,10   |I         |insertion_sort |    0.072| 0.057|  23.142|
|parallel-homogenous,10   |I         |gray2bin       |    0.078| 0.062|  20.927|
|parallel-homogenous,6    |I         |qsort          |    0.060| 0.034|   9.108|
|parallel-homogenous,6    |D+I       |bsearch        |    0.056| 0.035|   8.427|
|parallel-synth-memcpy,8  |I         |insertion_sort |    0.033| 0.007|   2.554|
|parallel-homogenous,20   |I         |qsort_java.sh  |    0.386| 0.111|   2.487|
|single,1                 |I         |exp_float      |    0.021| 0.002|   0.843|
|single,1                 |D+I       |insertion_sort |    0.021| 0.002|   0.830|
|parallel-synth-memcpy,2  |D+I       |exp_double     |    0.021| 0.002|   0.811|
|parallel-synth-memcpy,2  |D+I       |gray2bin       |    0.021| 0.002|   0.796|
|parallel-synth-memcpy,2  |D+I       |qsort          |    0.021| 0.002|   0.612|
|parallel-synth-cpu,40    |D+I       |qsort          |    0.023| 0.003|   0.602|
|single,1                 |I         |bsearch        |    0.022| 0.002|   0.581|
|parallel-synth-cpu,2     |I         |bsearch        |    0.022| 0.002|   0.571|
|parallel-synth-cpu,2     |V+I       |qsort_java.sh  |    0.068| 0.009|   0.295|
|parallel-homogenous,2    |V+I       |qsort_java.sh  |    0.066| 0.008|   0.274|
|parallel-synth-memcpy,20 |V+I       |exp_double     |    0.006| 0.001|   0.268|
|parallel-synth-memcpy,20 |V+I       |gray2bin       |    0.005| 0.001|   0.225|
|parallel-synth-cpu,20    |V+I       |qsort_java.sh  |    0.092| 0.009|   0.225|
|parallel-homogenous,6    |V+I       |qsort.py       |    0.160| 0.017|   0.222|
|parallel-homogenous,2    |V+I       |qsort.py       |    0.135| 0.011|   0.164|
|parallel-homogenous,2    |V+I       |exp_float      |    0.001| 0.000|   0.163|
|parallel-synth-cpu,2     |V+I       |exp_float      |    0.001| 0.000|   0.163|
|parallel-synth-cpu,2     |V+I       |gray2bin       |    0.002| 0.000|   0.149|
|parallel-synth-memcpy,6  |I         |qsort.py       |    0.155| 0.010|   0.147|
|parallel-homogenous,6    |V+I       |exp_double     |    0.002| 0.000|   0.145|
|parallel-synth-cpu,20    |I         |qsort.py       |    0.146| 0.009|   0.120|
|parallel-synth-cpu,8     |V+I       |gray2bin       |    0.002| 0.000|   0.119|
|parallel-homogenous,4    |V+I       |qsort.py       |    0.161| 0.008|   0.103|
|parallel-homogenous,10   |V+I       |bsearch        |    0.002| 0.000|   0.102|
