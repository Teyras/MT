# Requirements

- VirtualBox, Docker, Vagrant and isolate
- GNU parallel
- The following R packages need to be installed:
	- `zoo`
	- `ggplot2`
	- `ggpubr`
	- `ggrepel`
	- `boot`
	- `knitr`
	- `tidyr`
- Python 3 with `pandas`, `numpy`, `click` and `seaborn`

# Attached Files

## measurements/
- `build_docker.sh` -- Build a Docker image for Docker measurement workers
- `build_vbox.sh` -- Build a VirtualBox measurement worker template and then use 
  it to create VMs for all the workers
- `distribute_workers.sh` -- Print `n` CPU core indices selected according to 
  criteria explained in `text.pdf`
- `generate_data.sh` -- Generate inputs for workloads specified by a workload 
  file passed via arguments
- `measure_all.sh` -- Run stability measurements for workloads specified by a 
  file passed via arguments
- `measure_dependence_on_input.sh` -- Measure execution times for specified 
  workloads on multiple randomly generated inputs
- `measure_parallel_homogenous.sh` -- Measure a workload on `n` workers in 
  parallel, optionally with `taskset`
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

## results/

- `results-dependence-on-input.2018-09-08_10:35:26.csv` -- Results of 
  measurements of our workloads on multiple inputs
- `results.2018-08-19_23:40:42.csv` -- Results of stability measurements

## plots/

All the plotting scripts require a result CSV file to be passed as an argument.

- `check-warmup.r` -- Make a plot that compares rolling standard deviations with 
  the total standard deviation for each workload and metric on the bare metal
- `compare-bootstrap-means.r` -- Compare the confidence intervals of 
  bootstrapped means between bare metal, isolate and VirtualBox for the `qsort` 
  and `bsearch` workloads on each system load setup
- `compare-bootstrap-sd.r` -- Compare the confidence intervals of bootstrapped 
  standard deviations between measurements with and without isolate for each 
  system load setup and workload
- `compare-isolation.py` -- Make HTML heatmap tables for various statistics for 
  reach workload, metric, system load setup and isolation technology.  
- `helpers.r` -- Various utility functions
- `plot-dependence-on-input.r` -- Visualize how the execution times depend on 
  the particular input data for each workload.
- `plot.r` -- Make various plots for comparing measurement stability in various 
  isolation technologies and system load setups
- `time-isolate-vs-bare.r` -- Compare the CPU and wall time measurements made by 
  isolate and by the workload programs themselves to see how big and how stable 
  is their difference
