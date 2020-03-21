## Processing Time Estimation

Some scheduling algorithms (those for the clairvoyant version of the problem and 
those that need an estimate of the length of the queue for the workers) require 
to know the processing time of a job to function. Even though we do not know 
this precisely, we can make an estimate based on previous similar jobs that have 
already completed. Of course, the margin of error will be rather high, due to 
the characteristics of the problem outlined in Section 
\ref{scheduling-categorization}.

### Estimation Formula

To accurately predict the processing times of incoming evaluation jobs, we need 
to categorize information about recently finished jobs efficiently. With each 
job, we receive the exercise identifier, the required runtime environment and 
hardware group and an identifier of the author. The ReCodEx core can also supply 
us with an upper limit on the runtime of the exercise based on the time limits 
of individual tests. While this information is far from precise, it can help us 
with estimating processing times of exercise types we have never seen before.

Based on this information, we propose the following estimation algorithm: 

- Maintain three dictionary structures. The first one is indexed by runtime 
  environment, the second one by runtime environment and exercise identifier and 
  the third one by runtime environment, exercise identifier and author 
  identifier. The values in these dictionaries are circular buffers of size 10.
- Whenever an evaluation is finished, save the processing time into all three 
  dictionaries under corresponding indexes (the value is inserted into the 
  circular buffers).
- When a new job arrives, estimate its processing time as follows:
  - If there are any historical entries in the third dictionary (by author, 
    exercise and runtime environment), return their median.
  - If there are at least two historical entries in the second dictionary (by 
    exercise and runtime environment), return their median.
  - If there are at least two historical entries in the first dictionary (by 
    runtime environment) that are smaller than the exercise limit supplied by 
    the ReCodEx core, return their median.
  - Otherwise, return the exercise limit divided by two.

We have chosen median over arithmetic mean and other possible central tendencies 
because it returns actual values encountered by the system, which is favorable 
when there are two groups of similar measurements that are very far from each 
other, for example. If such cases were not present in our data, using the 
arithmetic mean might have been preferable for queue managers that estimate the 
length of the queue for a worker and not of an individual job.

The thresholds used when determining whether a particular buffer of measurements 
should be selected were found by evaluating the algorithm on a testing data set.

### Evaluation of the Estimation Formula

To evaluate the quality of the estimates, we let the algorithm process 
historical data and then compared the predictions with the actual results. We 
then analyzed the relative errors of the predictions, which were defined as $100 
\times (T_{prediction} - T_{actual}) / T_{actual}$ -- a negative error means 
that the estimate was too low and vice versa. A quick analysis of the errors for 
the whole dataset revealed that negative errors are more frequent than positive 
ones (74898 vs. 61260) and that the relative error was smaller than 10% for 57% 
of the observations and smaller than 20% for 82% of the observations.

After an inspection of histograms of the relative errors grouped by actual 
processing times (Figure \ref{estimation-error-histograms}), we see that 
positive errors larger than 100% are fairly frequent (around 7% of the total 
number of observations). Also, for very short jobs (less than 100 milliseconds), 
we overestimate the processing time very often. This is not surprising, since 
short processing times often indicate a failure, which is difficult to predict 
based on the available information. This phenomenon is also likely to have 
caused the notably large frequency of 100% negative errors in longer jobs 
(longer than 50 seconds).

In summary, the estimation algorithm seems to perform rather well, despite 
infrequently overestimating the processing time by a margin of several hundred 
percent. It is certainly suitable for usage in our load balancing algorithm 
evaluation experiment. In the future, more sophisticated algorithms could be 
devised, for example using machine learning techniques.

![Histograms of relative errors divided into facets by job processing times (in 
seconds) \label{estimation-error-histograms}](img/lb/estimation-error-histograms.tex)
