## Preliminary Checks

Considering the objective of our experiment, we had to ensure that the results 
of our measurements are stable in ideal conditions (only one process at a time 
being measured on the bare metal without isolation) in the first place. 
Otherwise, the comparison with results in less than ideal conditions would be 
much more difficult. In other words, we are going to check that conditions exist 
under which the workloads we chose yield stable results.

### Dependence of Result Variance on Input

Being able to use randomly generated inputs in our workloads is very useful -- 
we can demonstrate that our results have not been "rigged" by carefully choosing 
inputs by simply regenerating the input data and seeing if we get the same 
outcome. However, this only holds when the generated inputs are large enough so 
that the measurement take the same amount of time on every repetition.

To see if the input sizes we chose are sufficient, we measured the execution 
time of each workload (100 iterations) on 300 randomly generated input files and 
calculated the mean and standard deviation of the measurements for each of the 
inputs. As we see in Figure \ref{dep-input-mean}, the mean execution time does 
not vary a lot -- the range between the minimum and maximum time stays close to 
2ms. However, as shown by Figure \ref{dep-input-sd}, the range of standard 
deviations is rather large, reaching up to 11ms. After inspecting the histogram 
(Figure \ref{dep-input-hist}) of the deviations, we found that this is due to a 
small number of outliers. We conclude that the input data has a neglible effect 
on the execution time, even though there is a handful of inputs for the `qsort`, 
`bsearch` and `gray2bin` workloads on which the time measurements are unusually 
unstable.

![The min-max range of mean times for each workload 
\label{dep-input-mean}](img/stability/dependence-on-input-means.png)

![The min-max range of standard deviations of times for each workload 
\label{dep-input-sd}](img/stability/dependence-on-input-sds.png)

![A histogram of standard deviations of execution times for each input 
\label{dep-input-hist}](img/stability/dependence-on-input-sds-histogram.png)

### Detecting "Warming up"

In computer performance evaluation, it is common to let the benchmark warm up by 
performing a handful of iterations without measuring them. This way, the 
measurements are not influenced by e.g. initialization of the runtime 
environment or population of caches.

We expect that warming up will not occur in our experiment because each 
iteration runs in a separate process, but it is still necessary to verify this 
assumption. To do so, we compute the standard deviation of a sliding window of 
10 observations and compare it to the standard deviation of the whole sample. 
This is done for the single process measurement of each workload on the bare 
metal.

![Running SD (black) vs. total SD (blue) for the binary search 
workload](img/stability/warmup-bsearch.png)

The plot for the binary search workload shows us that the rolling standard 
deviation is not clearly higher at the beginning of the measurement sequence 
than at the end. The plots for the other workloads (see the attachments) show 
similar results. In fact, some workloads exhibit sudden peaks in the standard 
deviation when nearing 50 iterations. Although it is possible that 100 
measurements is not enough to detect a warmup period, it seems improbable. It is 
also important to note that the deviation stays relatively low the whole time 
(close to 1ms). Therefore, we can conclude that warming up is not an important 
factor in our measurements.

If the opposite was true, we would have to change the way ReCodEx measures 
submissions -- if a student submitted the same program in a quick succession, 
they could get a better score for the later solution.
