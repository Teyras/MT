## Processing Time Estimation

Some scheduling algorithms (those for the clairvoyant version of the problem and 
those that need an estimate of the length of the queue for the workers) require 
to know the processing time of a job to function. Even though we do not know 
this precisely, we can make an estimate based on previous similar jobs that have 
already completed.

### Estimation Formula

TODO list the info we have, think of a cool formula (rolling mean...)

### Evaluation of the Estimation Formula

TODO use historical data to calculate mean error of predictions (cut off the 
first attempts as warmup)
