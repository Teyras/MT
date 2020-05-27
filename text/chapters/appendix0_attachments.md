The following is a description of files contained in the attachments. The files 
are laid out as follows:

- `/measurement_stability` -- scripts for evaluation of measurement stability
- `/measurement_stability/distribute_workers.sh` -- a script that implements the 
  placement of measurements on CPU cores as described in 
  Section&nbsp;\ref{hw-and-os}
- `/measurement_stability/workloads` -- the programs measured in the experiments 
  and test inputs
- `/measurement_stability/plots` -- scripts for processing and plotting results
- `/scheduling` -- implementation of various scheduling algorithms and scripts 
  for their experimental evaluation
- `/scheduling/simulator.cpp` -- source code of the simulator used for 
  evaluation of queue managers
- `/scheduling/setups` -- descriptions of simulated worker pools used in 
  evaluation of queue managers
- `/scheduling/queue_managers` -- source code of the evaluated queue managers
- `/scheduling/workloads/generators` -- generators of random inputs for the 
  queue manager simulator
- `/scheduling/plots` -- scripts for processing and plotting of measurement 
  results
- `/containers` -- implementation of downloading, unpacking and mounting of OCI 
  images
- `/containers/plots` -- evaluation and plotting of results of performance 
  measurements
- `/user_behaviour` -- scripts for collection and evaluation of data about user 
  behaviour
- `/user_behaviour/predict_processing_times.py` -- an implementation of the 
  processing time estimation formula described in Section 
  \ref{processing-time-estimation}
- `/thesis.pdf` -- an electronic version of this thesis

This description is not exhaustive. Each of the top-level folders mentioned here 
contain a `README.md` file with a detailed description of the contents and usage
instructions.
