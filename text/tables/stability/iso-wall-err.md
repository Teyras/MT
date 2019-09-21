
Table: Characteristics of the error of isolate wall-clock time measurements, ordered by the relative error (truncated) \label{iso-wall-err}

|Setup                    |Isolation |Workload       | Mean error[s]| Rel. error[%]|
|:------------------------|:---------|:--------------|-------------:|-------------:|
|parallel-homogenous,40   |D+I       |insertion_sort |         0.382|       196.845|
|parallel-homogenous,40   |D+I       |exp_float      |         0.382|       159.590|
|parallel-homogenous,40   |I         |insertion_sort |         0.285|       154.053|
|parallel-homogenous,20   |D+I       |bsearch        |         0.151|        37.179|
|parallel-homogenous,40   |D+I       |qsort.py       |         0.287|        29.900|
|parallel-homogenous,40   |D+I       |qsort_java.sh  |         0.428|        23.014|
|parallel-homogenous,4    |I         |exp_float      |         0.049|         9.555|
|parallel-homogenous,4    |I         |exp_double     |         0.051|         9.317|
|parallel-homogenous,8    |D+I       |qsort_java.sh  |         0.198|         4.954|
|parallel-homogenous,10   |I         |qsort.py       |         0.098|         4.821|
|parallel-synth-cpu,40    |I         |exp_double     |         0.025|         2.255|
|parallel-synth-cpu,8     |D+I       |qsort_java.sh  |         0.195|         2.054|
|parallel-synth-cpu,10    |I         |gray2bin       |         0.032|         1.816|
|parallel-synth-memcpy,4  |D+I       |qsort          |         0.031|         1.660|
|parallel-synth-cpu,8     |I         |qsort          |         0.035|         1.376|
|parallel-synth-memcpy,6  |D+I       |qsort          |         0.027|         1.371|
|parallel-synth-memcpy,8  |I         |bsearch        |         0.028|         1.362|
|parallel-synth-memcpy,10 |D+I       |bsearch        |         0.026|         1.360|
|parallel-synth-cpu,20    |D+I       |bsearch        |         0.020|         1.187|
|parallel-synth-memcpy,20 |D+I       |bsearch        |         0.027|         1.028|
|parallel-synth-cpu,20    |I         |bsearch        |         0.019|         1.012|
|parallel-synth-memcpy,2  |I         |exp_double     |         0.021|         1.005|
|parallel-synth-cpu,4     |V+I       |qsort_java.sh  |         0.074|         0.807|
|parallel-synth-memcpy,8  |D+I       |qsort.py       |         0.064|         0.799|
|single,1                 |I         |insertion_sort |         0.021|         0.795|
|single,1                 |I         |gray2bin       |         0.021|         0.737|
|parallel-synth-memcpy,2  |I         |bsearch        |         0.022|         0.716|
|parallel-synth-cpu,2     |I         |bsearch        |         0.022|         0.702|
|parallel-synth-cpu,8     |V+I       |insertion_sort |         0.001|         0.252|
|parallel-synth-memcpy,2  |V+I       |gray2bin       |         0.002|         0.249|
|parallel-synth-cpu,20    |V+I       |qsort.py       |         0.029|         0.213|
|parallel-homogenous,4    |V+I       |insertion_sort |         0.001|         0.174|
|parallel-synth-memcpy,4  |V+I       |insertion_sort |         0.001|         0.171|
|parallel-homogenous,8    |V+I       |insertion_sort |         0.002|         0.169|
|parallel-synth-cpu,6     |V+I       |exp_float      |         0.001|         0.134|
|parallel-synth-memcpy,8  |V+I       |gray2bin       |         0.002|         0.132|
|parallel-homogenous,8    |V+I       |qsort.py       |         0.026|         0.123|
|parallel-synth-cpu,2     |V+I       |bsearch        |         0.001|         0.121|
