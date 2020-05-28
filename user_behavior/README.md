# User Behavior Analysis

This folder contains scripts for gathering and evaluating user behavior in 
ReCodEx:

- `dump.sh` -- fetches data about submissions from the ReCodEx database using 
  `ssh` (the ReCodEx server must be accessible under the `recodex` alias) and 
  saves it as `out.tsv`
- `dump.sql` -- the SQL script used to gather the data
- `collect_runtimes.py` -- Extends `out.tsv` with precise processing times and 
  outputs the result as `processed.tsv`
- `predict_processing_times.py` -- Reads `processed.tsv` as a sequence of 
  incoming jobs and predicts their processing times, the results are stored in 
  `predictions.tsv`
- `utils.py` -- utilities for reading input files
- `stats.py` -- calculates and outputs various statistics about user behavior
- `plots/plot_estimation_accuracy.r` -- plots histograms of processing time 
  prediction accuracy
- `plots/plot_processing_times.r` -- plots histograms of processing times 
  divided by runtime environment
- `plots/plot_submission_times.r` -- plots histograms of hour and day of 
  submission
- `out.tsv`, `processed.tsv` and `predictions.tsv` -- data used in the thesis
