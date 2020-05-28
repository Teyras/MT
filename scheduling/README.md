# Selection of a Scheduling Algorithm

This folder contains the implementation of the scheduling algorithms mentioned 
in the text of the thesis and the simulator used to evaluate their performance:

- `broker` -- a copy of the ReCodEx broker source code
- `simulator.cpp` -- an implementation of the simulator
- `common.h` -- declarations shared between the simulator and queue managers
- `queue_managers/single_queue_manager.h` -- implementation of queue managers 
  that work with a single queue
- `queue_managers/multi_queue_manager.h` -- implementation of queue managers 
  that work with multiple queues (one per worker)
- `queue_managers/processing_time_estimators.h` -- implementation of the 
  processing time estimators described in the text of the thesis (`oracle`, 
  `imprecise`, `queue_size`)
- `setups` -- YAML files used by the simulator that describe execution setups 
  (sets of worker machines)
- `workloads` -- CSV files that describe workloads processed by the simulator
- `workloads/generators` -- random workload generation scripts
- `measure.sh` -- a script that performs the measurements of scheduling 
  algorithm performance
- `results-lb.csv` -- the results used in the thesis
- `plots/plot-lb-efficiency.r` -- plots the lateness classification, makespan 
  and relative wait time plots

## Building and Running the Simulation

- Make sure you have cURL, yaml-cpp, libarchive and Boost installed
- Create a `build` directory and switch to it
- Run `cmake ..` and `make`
- Go back to the parent directory and run `measure.sh`
