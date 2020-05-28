# Stability of Measurements

This folder contains scripts for launching measurements of time measurement 
stability under varying levels of system load and isolation technologies:

## measurements/
- `build_docker.sh` -- Build a Docker image for Docker measurement workers
- `build_vbox.sh` -- Build a VirtualBox measurement worker template and then use 
  it to create VMs for all the workers
- `distribute_workers.sh` -- Print `n` CPU core indices selected according to 
  criteria explained in the thesis
- `generate_data.sh` -- Generate inputs for workloads specified by a workload 
  file passed via arguments
- `measure_all.sh` -- Run stability measurements for workloads specified by a 
  file passed via arguments
- `measure_dependence_on_input.sh` -- Measure execution times for specified 
  workloads on multiple randomly generated inputs
- `measure_parallel_homogenous.sh` -- Measure a workload on `n` workers in 
  parallel, optionally with `taskset`
- `measure_parallel_synth_stress.sh` -- Measure a workload on single worker, 
  with `n - 1` workers executing a syntethic stress-ng workload in parallel, 
  optionally with `taskset`
- `measure_workload.sh` -- Measure a single workload and print the results
- `run_docker.sh` -- Run a measurement in Docker (it must be already built)
- `run_vbox.sh` -- Start a VirtualBox VM via Vagrant and run a set of 
  measurements in it
- `workloads.txt` -- A list of workloads to be measured (allows for multiple 
  configurations of measurements)

## measurements/docker

The Dockerfile used to build the container image used for measurements

## measurements/runners

Scripts that run a specified amount of iterations of a workload in a specific 
environment

- `run_baremetal.sh` -- Run a set of measurements on the bare metal
- `run_isolate.sh` -- Run a set of measurements in isolate

## measurements/vagrant

- `vbox_template/Vagrantfile` -- Used to build a template file used for our 
  measurement worker VM images
- `vbox_multi/Vagrantfile` -- Contains the definitions of our measurement worker 
  images

## measurements/workloads

Sources of our workload programs. Each workload folder contains a 
`generate_data.sh` script and a `Makefile`.

## results.zip

An archive that contains the following four CSV files:

- `results-dependence-on-input.csv` -- Results of measurements of our workloads 
  on multiple inputs
- `results-stability.csv` -- Results of stability measurements
- `results-stability+noht.csv` -- Results of stability measurements, 
  concatenated with results of stability measurements without HyperThreading 
  enabled
- `results-stability-perf.csv` -- Results of stability measurements with `perf` 
  being used to gather additional performance metrics

## plots/

Most of the plotting scripts require a result CSV file to be passed as an 
argument. The selelection of plots used in the Stability of Measurements chapter 
can be seen in the `stability_plots.sh` script.

- `stability-illustration.r` -- Output an illustration of two asymptotically 
  different function graphs with 5% and 20% error margins highlighted
- `check-warmup.r` -- Make a set of scatter plots for selected workloads that 
  can be used to check for warming-up effects
- `compare-bootstrap-means.r` -- Compare the confidence intervals of 
  bootstrapped means between bare metal, isolate and VirtualBox for each 
  workload on each system load setup
- `compare-bootstrap-sd.r` -- Compare the confidence intervals of bootstrapped 
  standard deviations between measurements with and without isolate for each 
  system load setup and workload
- `plot-dependence-on-input.r` -- Visualize how the execution times depend on 
  the particular input data for each workload.
- `plot.r` -- Make various plots for comparing measurement stability in various 
  isolation technologies and system load setups
- `time-isolate-vs-bare.r` -- Compare the CPU and wall time measurements made by 
  isolate and by the workload programs themselves using correlation plots and 
  tables of relative errors to see how big and how stable is their difference
- `plot-paralelization.r` -- Outputs plots that compare the stability of 
  measurements with varying isolation technologies with increasing system load
- `plot-means-by-setup-size.r` -- Make a plot that shows the increase of 
  measured CPU time mean and standard deviation with increasing system load for 
  each isolation technology
- `calculate-parallel-ratios.py` and `plot-parallel-ratios.r` -- Make a plot 
  that shows the portion of total measuring time spent with all the measurement 
  processes being active at the same time for the `parallel-homogeneous` setup
- `compare-taskset.r` -- Evaluate the effects of different affinity settings 
  (`taskset`, `numactl`, multi-core `taskset`, disabled HyperThreading)
- `plot-cache-miss-ratios.r` -- Outputs a table of correlations of measured 
  `perf` metrics with the CPU time and a graph that shows the number of page 
  faults based on isolation technology and system load

