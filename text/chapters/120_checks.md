## Analysis of Measurement Conditions

Considering the objective of our experiment, we had to ensure that the results 
of our measurements are stable in ideal conditions (only one process at a time 
being measured on the bare metal without isolation) in the first place. 
Otherwise, the comparison with results in less than ideal conditions would be 
much more difficult. In other words, we are going to make sure that conditions 
exist under which the workloads we chose yield stable results.

### Dependence of Result Variance on Input

Being able to use randomly generated inputs in our workloads is very useful -- 
we can demonstrate that the outcome of our measurements was not influenced by 
carefully choosing inputs that yield the desired results. This can be done by 
simply regenerating the input data and seeing if we get the same outcome. 
However, this only holds when the generated inputs are large enough so that the 
measurements take the same amount of time on every repetition.

To see if the input sizes we chose are sufficient, we measured the execution 
time of each workload (100 iterations) on 300 randomly generated input files and 
calculated the mean and standard deviation of the measurements for each of the 
inputs. As we see in Figure \ref{dep-input-mean}, the mean execution time almost 
does not vary -- even the outliers are within milliseconds from the median of 
the means. However, as shown by Figure \ref{dep-input-sd}, the range of standard 
deviations is rather large, reaching up to 11ms. Upon closer inspection, we 
found that this is due to a small number of outliers. We conclude that the input 
data has a neglible effect on the execution time, even though there is a handful 
of inputs for the `qsort`, `bsearch` and `gray2bin` workloads on which the time 
measurements exhibit a notably higher standard deviation.

![A box plot of the iteration means of CPU time for each workload 
\label{dep-input-mean}](img/stability/dependence-on-input-means.png)

![A box plot of the iteration standard deviations of CPU time for each workload 
\label{dep-input-sd}](img/stability/dependence-on-input-sds.png)

### Behavior of Repeated Measurements

In computer performance evaluation, it is common to let the benchmark warm up by 
performing a handful of iterations without measuring them. This way, the 
measurements are not influenced by initialization of the runtime environment or 
population of caches, for example.

We expect that warming up will not occur in our experiment because each 
iteration runs in a separate process and actual submissions are different 
binaries. However, factors that could cause this phenomenon in our case do 
exist. For example, if the submission read a very large input file, it would 
have to wait for it to be read from the disk, but subsequent submissions could 
probably get it from the disk cache. Also, many successive submissions of a 
short program could vary in their runtime thanks to CPU frequency scaling. 
Therefore, it is still necessary to verify whether or not warming up occurs.

![A scatter plot of CPU times for selected workloads with no isolation and a 
single measurement worker running
\label{warmup}](img/stability/warmup.tex)

As seen in Figure \ref{warmup}, the results are not clearly higher during the 
first iterations of the measurements than at the end. A handful of outliers can 
be observed, but the overall trend seems stable enough. Although it is possible 
that 100 measurements is not enough to detect a warmup period, it seems 
improbable. Therefore, we can conclude that warming up is not an important 
factor in our measurements.

If the opposite was true, we would have to change the way ReCodEx measures 
submissions -- if a student submitted the same program in a quick succession, 
they could get a better score for the later solution.
