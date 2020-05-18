## Evaluation

Our survey of scheduling algorithms provided us with a variety of possible 
approaches that we will proceed to evaluate. We decided to exclude algorithms 
that require preemption (such as SRPT and SETF), because implementing it in 
ReCodEx would be difficult and it may show that non-preemptive approaches work 
sufficiently well.

The algorithms can be divided into two categories -- those that maintain a 
separate queue for each worker and assign jobs immediately, and those that delay 
the assignment until a worker is available.

The current load balancing algorithm (`multi_rr`, a simple round robin over all 
workers) in ReCodEx belongs to the first category (immediate dispatch), along 
with assigning incoming jobs to the least loaded worker (`multi_ll`) and the 
"Power of two choices" randomized algorithm (`multi_rand2`). We will employ 
three ways of estimating the load of the workers:

- `queue_size` -- simply counting the jobs and summing the processing time 
  estimates,
- `oracle` -- an estimator which has access to the simulation data and returns 
  the exact right processing time, and
- `imprecise`, which was described in Section \ref{estimation-in-simulation}. 

This gives us a total of seven algorithms to evaluate -- three variants of both 
`multi_ll` and `multi_rand2` and the original algorithm, `multi_rr`.

The delayed dispatch category contains two broad approaches. One is based on a 
single priority queue of jobs with various policies. We will evaluate the 
following priority policies:

Possibly the most straightforward algorithm in the delayed dispatch category is 
based on a single priority queue of jobs. There are many possible policies for 
assigning priorities to jobs. From these, we will evaluate the following:

- `single_fcfs` -- first come, first served, also known as earliest time of 
  arrival first,
- `oagm` -- the policy mentioned in Section \ref{time-vs-list-based-scheduling},
- `single_spt` -- shortest job first (based on previous processing times),
- `single_edf` -- earliest deadline first (the modification presented in Section 
  \ref{custom-edf}), and
- `single_lf` -- least flexibility job first.

From these algorithms, three employ processing time estimation (`single_edf`, 
`single_spt` and `oagm`). These algorithms will be evaluated twice, once with 
the `oracle` estimator and once with the `imprecise` estimator.

The multi-level queue family contains examples of more sophisticated deleayed 
dispatch algorithms. The MLFQ algorithm depends heavily on preemption, which 
disqualifies it from our experiment. We could evaluate the modification 
described in Section \ref{custom-mlfq}, but it would require extensive 
preliminary testing to find appropriate values for its parameters. We will 
therefore omit the multi-level queue algorithms from our evaluation.

### Experimental Workloads

To cover multiple use cases, we will measure the queue manager performance on 
various sequences of jobs with different sets of workers, which are described in 
this section.

The worker sets are configured manually and are not intended to change between 
iterations of the experiment. The job sequences, on the other hand, are randomly 
generated to ensure the robustness of our experiment. The job processing times 
are sampled from a normal distribution with a mean ($\mu$) and standard 
deviation ($\sigma$) based on historical data from ReCodEx, which are depicted 
in Figure \ref{processing-time-histograms}. No rigorous tests for goodness of 
fit of a normal distribution on actual job processing times have been performed.

Throughout the experiment, we use the following job types:

- `common_short`, with $\mu=500ms$ and $\sigma=200ms$, which corresponds to the 
  parameters of a trivial program in C, C++ or Pascal,
- `common_medium`, with $\mu=2000ms$ and $\sigma=500ms$, a plausible processing 
  time for an exercise in C, C++, Python or Node.js,
- `common_long`, with $\mu=10000ms$ and $\sigma=4000ms$, which could be a long 
  exercise in C++, Java or C#,
- `parallel`, with $\mu=8000ms$ and $\sigma=2000$, which could be a parallel 
  workload in C++, and
- `gpu`, with $\mu=1000000ms$ (16 minutes and 40 seconds) and $\sigma=120000$ (2 
  minutes), which could correspond to a long GPU-based workload.

The delays between jobs are sampled from an exponential distribution with a mean 
that varies with the workload types (although 100ms is a common value), which is 
a common assumption when modelling queueing scenarios.

![A breakdown of job processing times divided by runtime environments
\label{processing-time-histograms}](img/lb/processing-times-histograms.tex)

#### Simple and Parallel Jobs

The simple and parallel workload, which is denoted as `simple+para_small` and 
`simple+para_large` in measurement scripts and results, contains jobs of the 
`common_medium` and `parallel` types in a 3:1 ratio. In the small variant, there 
are 1000 jobs executed on 10 workers capable of processing the `common_medium` 
type and 1 worker capable of processing the `parallel` type.

In the large variant, there are 4000 job executed on four parallel workers and 
40 common workers. Both variants have a mean delay of 100ms. The purpose of the 
workload is to show how queue managers handle job types with disjoint processing 
sets.

#### Two-phase Workload

In the two-phase workload (denoted as `two_phase_small` and `two_phase_large` in 
measurement scripts and results), there are 2000 jobs. The first 1000 is of the 
`common_short` type. The second 1000 contains jobs of both the `common_short` 
and `common_long` types in a 1:5 ratio.

The workload is executed on 40 identical workers with a mean delay of 550ms in 
the large variant and on 4 workers with a 45ms mean delay in the small variant. 
The values of the mean delay were chosen empirically to make sure that the 
workers are not oversaturated at the end of the first phase. The purpose of this 
workload is to see how different queue managers react to a sudden change in the 
character of incoming jobs.

#### Long and Short Jobs

The are two workloads that employ a sequence of jobs of two different lengths. 
The first one is called `medium+short` and it is composed of `common_medium` and 
`common_short` jobs in a 1:1 ratio with a 100ms average delay. It is executed on 
a set of 4 identical workers. The other workload is called `long+short` and 
contains `common_short` and `common_long` jobs in a 4:1 ratio with a 100ms mean 
delay. We use 40 identical worker machines to execute this workload.

This kind of workloads aims to test whether the load is distributed evenly among 
the workers. If not, we should observe a longer makespan.

#### Multiple Job Types

The last workload type we will use is called `multi_type` and it contains a 
multitude of job types (as described by Table \ref{multi-type-workload-jobs}). 
There are 1000 jobs with an average delay of 100ms. The worker pool contains 
contains two common groups of workers, one with 6 workers and the other with 4. 
Apart from these two, there is a parallel group with 2 workers and a GPU group 
with 4 workers.

This workload is meant to test the queue managers in a setting that is closer to 
a real-world usage scenario than the others, with multiple kinds of jobs 
arriving in a short period of time.

Table: Parameters of jobs in the `multi_type` workload type 
\label{multi-type-workload-jobs}

| Probability | Job type                                      | 
|------------:|:----------------------------------------------|
| 35%         | common_medium (common hardware group 1)       |
| 30%         | common_medium (common hardware group 2        |
| 30%         | common_medium (common hardware group 1 and 2) |
| 4%          | parallel                                      |
| 1%          | gpu                                           |

### Summary of Results

To allow evaluation of the results of the simulation at a glance, we decided to 
classify the jobs based on the wait time as follows:

- For jobs shorter than 5000ms:
	- "On time" if the wait time is shorter than 2000ms,
	- "Delayed" if it is shorter than 15000ms,
	- "Late" if it is shorter than 45000ms and
	- "Extremely late" otherwise
- For jobs longer than 5000ms:
	- "On time" if the relative wait time is smaller than 0.4,
	- "Delayed" if it is smaller than 3,
	- "Late" if it is smaller than 9 and
	- "Extremely late" otherwise

The breakpoints in the classification are partially chosen empirically and 
partially based on the wait time requirements outlined in Section 
\ref{scheduling-requirements}. The justification for the split between short and 
long jobs is that it would be unreasonable to classify a 500 millisecond job as 
extremely late if it was delayed by 5 seconds (a relative wait time of 10). 
Analogoues to this, it would not be accurate if we classified a 10 minute job as 
extremely late if it got delayed by one minute (which is however a substantial 
delay for a job that is processed in mere seconds).

After the classification, we made a plot for each workload that compares the 
share of each of these classes between different queue manager implementations.
To reveal the development of these ratios in time, the jobs are split into 20 
bins of equal size based on their time of arrival (for a workload with 1000 
jobs, the first bin contains the first 50 jobs to arrive, the second bin 
contains jobs 51 to 100, and so on). The share of each class is then displayed 
separately for each bin using a stacked bar plot.

Our examination of the measurements revealed several interesting trends. First 
of all, most of the queue managers that use per-worker queues perform worse than 
others, even on simple workloads. This is demonstrated in the case of the 
`multi_ll`, `multi_rand2` and `multi_rr` strategies and the `long+short` 
workload (as shown by Figure \ref{lb-lateness-long-short}). While other 
algorithms manage to process most jobs on time, the multi-queue algorithms only 
achieve that for a fraction of the workload. The share of "late" jobs is 
somewhat larger for the `multi_rr` algorithm, which is much less sophisticated 
than the others. 

![Lateness classification for each queue manager over arrival time windows for 
the \texttt{long+short} workload 
\label{lb-lateness-long-short}](img/lb/lateness,uniform_large,long+short.tex)

A similar situation can be seen in the case of the `multi_type` workload (
depicted by Figure \ref{lb-lateness-multiple-types}). Here, the `multi-ll` 
algorithms perform better than the `multi-rr` and `multi-rand2` variants. 
However, the single-queue algorithms still outperform them in terms of the ratio 
of jobs processed on time. On the other hand, it is worth noting that most of 
the single-queue approaches processed some jobs extremely late, which did not 
happen with multi-queue approaches.

![Lateness classification for each queue manager over arrival time windows for 
the \texttt{multi\_type} workload
\label{lb-lateness-multiple-types}](img/lb/lateness,multiple_types,multi_type.tex)

![Lateness classification for each queue manager over arrival time windows for 
the \texttt{two\_phase\_large} workload
\label{lb-lateness-two-phase}](img/lb/lateness,uniform_large,two_phase_large.tex)

![Lateness classification for each queue manager over time for the 
\texttt{simple+para\_small} workload 
\label{lb-lateness-simple-para-small}](img/lb/lateness,two_types_small,simple+para_small.tex)

Our second observation is that the `single-spt` algorithm performs better or 
similarly well as the others on all measured workloads, as long as we are 
concerned about the number of jobs processed on time. This fact can be seen in 
Figure \ref{lb-lateness-two-phase}, where most queue managers initially perform 
rather well, but their performance drops dramatically after roughly 250 jobs, 
while `single_spt` still manages to process a part of the jobs on time. The 
`oagm` and `single_lf` algorithms also seem to have somewhat better results than 
other algorithms. In the case of `single_lf`, this should be attributed to 
coincidence, since this workload employs identical workloads and all jobs are 
considered equal by the queue manager.

Another occurence of this trend is the `simple+para_small` workload, whose 
lateness classification can be seen in Figure 
\ref{lb-lateness-simple-para-small}. The results show `single_spt` to be the 
best performing algorithm, with `oagm` on the second place. In this case, 
`single_spt` prevails not only in terms of the number of jobs processed on 
times, but also in terms of the number of jobs that were processed late or 
extremely late.

The last observation we made is that the exact mechanism of processing time 
estimation does not cause a noticeable change in the ratio of lateness classes. 
However, the lateness class graphs are a rather crude visualization that is 
useful for a quick comparison, but it might fall short in this case. 

For a more detailed insight, we plotted separate histograms of the relative 
waiting times for each queue manager (as depicted in Figure 
\ref{lb-rel-wait-time-histogram}). In these, we have noticed that using the 
imprecise estimator causes an increase in cases with very large relative waiting 
times for `single_spt`. The other algorithms that employ processing time 
estimation do not seem to be affected in any notable way. In the case of 
`multi_ll` and `multi_rand2`, this could be caused by the larger estimation 
errors being compensated for by other jobs with better estimates in each queue.
It is difficult to find an explanation in the case of `single_edf` and `oagm`. 
We hypothesize that `oagm` is not as reliant on processing time estimation 
because it also uses other metrics to order the job queue. The results for 
`single_edf` should probably be attributed to coincidence.

The last subject of our evaluation were the makespans (total time it takes to 
process a workload) of the individual queue managers. A selection of comparison 
plots can be seen in Figure \ref{lb-makespans}. In most workloads, the queue 
managers exhibit very similar makespans. An exception to this trend are the 
`multi_ll_imprecise` and `multi_rand2_imprecise`, whose makespans are longer. A 
plausible explanation of this is that they fail to balance the load on the 
individual workers due to not being able to estimate the length of their queues 
well enough. In some cases, longer makespans can be observed for 
`multi_rand2_oracle` too, probably because of its inherent randomness.

It is worth noting that using the imprecise estimator does not seem to affect 
the makespan of queue managers that maintain a single queue nearly as much. It 
can be conjectured that the estimation error becomes a problem only when many 
estimates are summed, which is the case with multiple-queue strategies.

![Histogram of relative wait times for each queue manager, throughout all 
executed workloads \label{lb-rel-wait-time-histogram}](img/lb/rel_wait_time.tex)

![A comparison of makespans for individual queue managers and selected workloads
\label{lb-makespans}](img/lb/makespans-selection.tex)

## Conclusion

Our experiment has shown that a simple "Shortest job first" algorithm beats all 
the other approaches we evaluated. Judging by intuition, long jobs could be 
prone to starvation when this algorithm is used. However, our data suggests this 
is not the case. On the contrary, it exhibits the least number of outliers in 
terms of relative wait time with an ideal processing time estimator. With an 
imprecise time estimator, its number of outliers is still competitive.

There were cases where some other heuristic approaches showed promising results. 
For example, the OAGM algorithm, the "Least flexible job first" heuristic or our 
implementation of the "Earliest deadline first" policy. It is possible that some 
combination of these approaches would have interesting performance, but an 
exploration of such a large pool of combination is out of the scope of our 
research. There is also a chance that the "Earliest deadline first" approach 
could be improved by adjusting the deadline thresholds to fit the actual running 
times of jobs better, or by implementing a mechanism that adjusts them 
automatically.

We have also found that imprecise processing time estimation does not greatly 
affect the performance of single-queue load balancing algorithms, but it causes 
longer makespans in multi-queue algorithms. As a side note, small flexibility is 
a general problem of multi-queue algorithms that dispatch jobs immediately after 
arrival. In setups where workers can go offline at any time or where new workers 
can be added to the pool over time, additional measures must be taken to 
redistribute the work and avoid starvation.
