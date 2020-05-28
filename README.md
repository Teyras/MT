# Load Balancing in Evaluation Systems for Programming Assignments

## Requirements

### Plotting and Data Processing

The following R packages need to be installed:

- `boot`
- `dplyr`
- `ggplot2`
- `ggpubr`
- `ggrepel`
- `knitr`
- `lubridate`
- `magrittr`
- `patchwork`
- `scales`
- `tidyr`
- `tikzDevice`
- `zoo`

Python version 3.8 or newer is required, with the following packages:

- `numpy`
- `pandas`
- `seaborn`
- `click`
- `pyyaml`

### Repeating Container and Scheduling Experiments

A C++ compiler that supports C++17 is required to build the code, along with 
`cmake`, `make` and the following libraries:

- `curl`
- `libarchive`
- `yaml-cpp`
- `boost`

### Repeating Evaluation of Measurement Stability

- Vagrant
- Docker
- VirtualBox
- GNU parallel
- Isolate
- perf

## Contents

- `measurement_stability` -- scripts for examining the stability of time 
  measurements with various isolation technologies and degrees of system load
- `scheduling` -- implementation of a handful of scheduling algorithms and a 
  simulation environment for their evaluation
- `containers` -- programs for container manipulation (as described in the 
  Advanced Usage of Containers chapter)
- `user_behavior` -- scripts for gathering and evaluating information about 
  ReCodEx submissions
