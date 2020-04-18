## Current State of the Art

Automatic scaling is a rather well researched problem with a large taxonomy of 
subproblems[@AutoscalingSurvey]. Many general and problem-specific approaches to 
auto-scaling exist an multiple frameworks have been proposed for the evaluation 
of their 
performance[@AutoscalingExperimentalPeva][@AutoscalingPerformanceModelling]. In 
this section, we present an overview of the problem and some of its details that 
are relevant to our efforts.

### The Auto-scaling Process

The operation of an auto-scaling service (auto-scaler) can be decomposed into 
the following abstract steps[@AutoscalingSurvey]:

- **Monitoring**: A performance indicator metric is observed periodically.
- **Analysis**: The auto-scaler determines whether scaling actions should be 
  performed based on the performance indicator data. Scaling can be performed 
  either proactively (before a change in traffic happens) or reactively (after 
  it happens). For successful proactive scaling, a prediction of future traffic 
  is needed. Although more complicated, proactive scaling is a better approach 
  when the scaling action takes a substantial amount of time. Also, oscillation 
  (opposite scaling actions being done in a quick succession) should be 
  mitigated at this step.
- **Planning**: The auto-scaler calculates how many resources should be 
  allocated or deallocated to handle the traffic. It should also be aware of the 
  budget imposed on cloud service usage.
- **Execution**: The actual execution of the scaling plan.

While the Monitoring step depends on the character of the workload and the 
Execution step depends on the execution model in place (such as virtual 
machines, containers or physical servers), the Analysis and Planning steps can 
be implemented in a more general fashion.

In the Analysis and Planning steps, various approaches are taken to process the 
performance data, such as:

- Rule-based policies
- Time-based policies
- Fuzzy rule-based policies (the rules do not have concrete parameters, their 
  values are determined automatically)
- Predictions based on the rate of change (slope) of the performance data
- Regression models (linear regression, auto regressive moving average, etc.)
- Neural networks

Oscillation mitigation is typically implemented by either adjusting the 
thresholds dynamically or by adding a cooldown period after a scaling decision 
during which an opposite decision cannot be made.

### Available Auto-scalers \label{available-auto-scalers}

ConPaaS[@ConPaaS] is an open source cloud platform that allegedly features 
automatic scaling. Unfortunately, we failed to find any documentation of this 
functionality so we cannot assess it.

Numerous open source auto-scalers exist for the Kubernetes workload 
orchestrator. One example is Clusterman[@Clusterman], an auto-scaler developed 
by Yelp that also features a simulator that receives a time series of 
performance indicator values, and outputs whether the cluster is 
under-provisioned or over-provisioned and an approximate cost. As more examples, 
we can mention Cerebral (part of the Containership cloud 
platform[@Containership]), KEDA[@KEDA] or Escalator[@Escalator].
