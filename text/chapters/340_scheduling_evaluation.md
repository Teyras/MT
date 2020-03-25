## Evaluation

Our survey of scheduling algorithms provided us with a variety of possible 
approaches that we will proceed to evaluate. We decided to exclude algorithms 
that require preemption (such as SRPT and SETF), because implementing it in 
ReCodEx would be difficult and it may show that non-preemptive approaches work 
sufficiently well.

The algorithms can be divided into two categories -- those that maintain a queue 
for each worker and assign jobs immediately, and those that delay the assignment 
until a worker is available.

The current load balancing algorithm (a simple round robin over all workers) in 
ReCodEx belongs to the first category, along with assigning incoming jobs to the 
least loaded worker and the "Power of two choices" randomized algorithm. We will 
employ three ways of estimating the load of the workers -- simply counting the 
jobs and summing the processing time estimates, once using an estimator called 
`oracle`, which has access to the simulation data and returns the exact right
processing time, and once using the `imprecise` estimator, which was described 
in Section \ref{estimation-in-simulation}. This gives a total of seven 
algorithms to evaluate.

The non-immediate dispatch category contains two broad approaches. One is based 
on a single priority queue of jobs with various policies. We will evaluate the 
following priority policies:

- earliest time of arrival first (first come, first served)
- OAGM -- the policy mentioned in Section \ref{time-vs-list-based-scheduling}
- shortest job first (based on previous processing times)
- earliest deadline first (the modification presented in section 
  \ref{custom-edf})
- least flexibility job first

From these algorithms, three employ processing time estimation (earliest 
deadline, shortest job and OAGM). These algorithms will be evaluated twice, once 
with the `oracle` estimator and once with the `imprecise` estimator.

The other approach is employed by the multi-level queue algorithm family. The 
MLFQ algorithm depends heavily on preemption, which disqualifies it from our 
experiment. We could evaluate the modification described in Section 
\ref{custom-mlfq}, but it would require extensive preliminary testing to find 
appropriate values for its parameters. We will therefore omit the multi-level 
queue algorithms from our evaluation.

### Execution Setups

To cover multiple use cases, we will measure the queue manager performance on 
different sets of workers and various sequences of jobs, which are described 
later in this section.

The worker sets are configured manually and are not intended to change between 
iterations of the experiment. The job sequences, on the other hand, are randomly 
generated to ensure the robustness of our experiment. The processing times of 
jobs are sampled from the normal distribution with varying parameters. No 
rigorous tests for goodness of fit of a normal distribution on actual job 
processing times have been performed, but a similarity can be observed in Figure 
\ref{processing-time-histograms}. The delays are sampled from an exponential 
distribution with a mean of 30ms (unless stated otherwise), which is a common 
assumption when modelling queueing scenarios.

![A breakdown of job processing times divided by runtime environments
\label{processing-time-histograms}](img/lb/processing-times-histograms.tex)

#### Uniform Workers

Called `uniform_small` and `uniform_large` in measurements scripts and results. 
The setup contains workers from a single hardware group with identical headers.
It contains 4 workers in the small variant and 40 workers in the large variant.

Three types of workloads are executed in this setup. The first one is 
`medium+short_small` which consists of equal parts of two kinds of jobs: medium, 
which have a mean processing time of 500ms with a standard deviation of 100ms 
and short with a mean of 300ms and a standard deviation of 100ms.

The second workload is `long+short_small`. The long jobs are four times less 
likely to be generated than short jobs and their mean execution time is 10000ms
with a 4000ms standard deviation. The short jobs have a mean processing time of 
500ms with a standard deviation of 100ms.

The purpose of these two workloads is to test whether the queue managers can 
balance the load of workers well, without overloading some of them with a 
disproportionate amount of long jobs.

The last workload type is `two_phase`. As its name suggests, it consists of two 
phases. In the first one, jobs of a single type with a mean duration of 300ms
with a 100ms standard deviation arrive. After 600 jobs are sent, jobs of a 
second type start arriving. Their execution time has a mean of 500ms and a 
standard deviation of 150ms. In the second phase, the jobs of the second type 
are four times more likely to arrive. Differently from the other workloads, the 
mean delay between jobs is 70ms.

The `two_phase` workload is intended to reveal how well the queue managers adapt 
to a new job type.

#### Two Worker Types

Called `two_types_small` and `two_types_large` in measurement scripts and 
results. This setup contains workers of two types - common and parallel. There 
is a single parallel machine and 10 common machines in the small variant and 4 
parallel machines and 40 common machines in the large variant.

In this setup, we run the `simple+para` workload, which consists of two kinds of 
jobs, each targeted on one of the hardware groups. The common jobs have 
processing times with a mean of 1000ms and a standard deviation of 500ms. The 
parallel jobs have a mean processing time of 4000ms with a standard deviation of 
2000ms. The workload has two variants, `simple+para_small` with 1000 jobs and 
`simple+para_large` with 4000 jobs.

After a preliminary run of the experiment, we decided to not run the 
`simple+para_large` workload on the `two_types_small` setup because no queue 
manager processed it well.

This workload exercises the capability of queue managers to handle two disjoint
sets of workers and jobs, which we expect should be an easy enough task for any 
load balancing algorithm.

#### Multiple Worker Types

This setup is called `multi_type_small` in measurement scripts and results. It 
contains two common groups of workers, one with 6 workers and the other with 4. 
Apart from these two, there is a parallel group with 2 workers and a GPU group 
with 4 workers.

We run a workload with many different types of jobs in this setup, that is also 
called `multi_type_small`. The parameters of jobs are described by Table 
\ref{multi-type-workload-jobs}.

This workload is meant to test the queue managers in a setting that is closer to 
a real-world usage scenario than the others, with multiple kinds of jobs 
arriving in a short period of time.

Table: Parameters of jobs in the `multi_type_small` workload type 
\label{multi-type-workload-jobs}

| Probability | Hardware group                   | Processing time mean [ms] | Processing time std. dev. [ms] |
|------------:|:---------------------------------|--------------------------:|-------------------------------:|
| 50%         | group_common_1                   | 1000                      | 500                            |
| 20%         | group_common_1 or group_common_2 | 600                       | 300                            |
| 10%         | group_parallel                   | 4000                      | 2000                           |
| 20%         | group_gpu                        | 1,000,000                 | 120,000                        |

## Summary of Results

To allow evaluation of the results at a glance, we decided to classify the jobs 
based on the relative wait time as "on time" (less than 0.1), "delayed" (less 
than 1), "late" (less than 3) or "extremely late" (more than 3). Then, we made a 
plot for each execution setup that compares the share of each of these classes 
between different queue manager implementation. To reveal the development of 
these ratios, the jobs are split into 20 bins of equal size based on their time 
of arrival. The share of each class is then displayed separately for each bucket 
using a stacked bar plot.

Our examination of the measurements revealed several interesting trends. First 
of all, most of the queue managers that use per-worker queues perform worse than 
others, even on simple workloads. This is demonstrated in the case of the 
`multi_ll` and `multi_rand2` strategies and the `simple+para_small` workload on 
the `two_types_large` worker layout (as shown by Figure 
\ref{lb-lateness-simple-para-small}). While most other algorithms manage to 
process most job on time, `multi_ll` only achieves that for a fraction of the 
workload. The `multi_rand2` performs slightly better, but it still has notably 
more jobs in the "delayed" and "late" categories. Curiously, the much less 
sophisticated `multi_rr` algorithm does not suffer from this problem.

![TODO 
\label{lb-lateness-simple-para-small}](img/lb/lateness,two_types_large,simple+para_small.tex)

Our second observation is that the `single-spt` algorithm performs better or 
equally to the others on all measured workloads. This fact can be seen in Figure 
\ref{lb-lateness-long-short-small}, where most queue managers initially perform 
rather well, but their performance drops dramatically after roughly 250 jobs, 
while `single_spt` still manages to process a part of the jobs in time. Another 
illustration of the trend can be seen in Figure 
\ref{lb-lateness-multiple-types}. The results show `single_spt` to be the best 
performing algorithms, with `single_lf` and `oagm` reaching the second and third 
place.

![TODO 
\label{lb-lateness-long-short-small}](img/lb/lateness,uniform_large,long+short_small.tex)

![TODO 
\label{lb-lateness-multiple-types}](img/lb/lateness,multiple_types,multi_type_small.tex)

The last observation we made is that the exact mechanism of processing time 
estimation does not cause a noticeable change in the ratio of lateness classes. 
However, the lateness class graphs are a rather crude visualization that is 
useful for a quick comparison, but it might fall short in this case. 

For a more detailed insight, we plotted separate histogram of the relative 
waiting times for each queue manager (as depicted in Figure 
\ref{lb-rel-wait-time-histogram}). In these, we have noticed that using the 
imprecise estimator causes an increase in cases with very large waiting times 
for `single_spt` and, to some extent, `single_edf`. The `oagm` algorithm does 
not seem to be affected, possibly due to the other metrics it uses for ordering 
the queue.

The last subject of our evaluation were the makespans (total time it takes to 
process a workload) of the individual queue managers. A selection of comparison 
plots can be seen in Figure \ref{lb-makespans}. In most workloads, the queue 
managers exhibit very similar makespans. An exception to this trend are the 
`multi_ll_imprecise` and `multi_rand2_imprecise`, whose makespans are longer. A 
plausible explanation of this is that they fail to balance the load on the 
individual workers due to not being able to estimate the length of their queues 
well enough.

It is worth noting that using the imprecise estimator does not seem to affect 
queue managers that keep a single queue nearly as much. It can be conjectured 
that the estimation error becomes a problem only when many estimates are summed, 
which is the case with multiple-queue strategies.

On the `long+short_small` workload, the `oagm_oracle` algorithm seems to have 
finished with a slightly shorter makespan than the other algorithms. However, 
even if this was more than a random occurence, we would not prefer it over 
`single_spt` because of its tendency to cause large relative waiting times for 
some jobs (as shown in Figure \ref{lb-rel-wait-time-histogram}).

![A comparison of makespans for individual queue managers and selected workloads
\label{lb-makespans}](img/lb/makespans-selection.tex)

![TODO 
\label{lb-rel-wait-time-histogram}](img/lb/rel_wait_time,uniform_large,long+short_small.tex)

## Conclusion

Our experiment has shown that a simple "Shortest job first" algorithm beats all 
the other approaches we evaluated.
