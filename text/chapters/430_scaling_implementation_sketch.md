## Implementation Sketch

As demonstrated by the previous sections, on-demand scaling is a rather complex 
problem that requires careful evaluation based on performance data from real 
traffic. We conclude that such experiment is out of the scope of this text, but 
we present a brief overview of how auto-scaling could be integrated into a 
programming assignment evaluation system.

### Performance Monitoring

Since the queue length is the only useful metric of worker utilization, the load 
balancer (the broker in the case of ReCodEx) must be responsible for publishing 
performance data.

In the case of AWS, this can be done either by invoking an HTTP API or a command 
line program[@AWSCustomMetrics]. We presume that such interface is also 
available with other cloud providers. For the ReCodEx broker, using the HTTP API 
is certainly preferred over the CLI, since the infrastructure for working with 
HTTP requests is already implemented there.

For other use cases, leveraging a performance monitoring solution such as 
Prometheus[@Prometheus] could be a possibility. For Prometheus in particular, a 
C++ client library exists that could be used to instrument the broker to send 
queue usage statistics that would be stored and processed by an auto-scaler.

### Analysis and Planning

There are numerous approaches to the analysis of performance data and planning 
of scaling operations. Multiple solutions exist that could be used directly, 
such as AWS Predictive Scaling or the auto-scalers mentioned in Section 
\ref{available-auto-scalers}. It is worth noting that each of these would 
require a certain amount of experimenting with configuration parameters.

If a custom approach was chosen, it could either be implemented as a part of the 
load balancer (broker), which already has all the relevant information, or as a 
standalone service that would consume performance metrics from the load balancer 
or from a monitoring service such as Prometheus.

Adding a standalone auto-scaling service would not require any modifications to 
the ReCodEx broker since it already has the ability to deal with unexpected 
termination of workers and with new workers appearing. However, load balancing 
algorithms with immediate dispatch and no mechanism of redistribution should be 
avoided due to their inability to react to changes in the worker pool.

### Execution

The method of execution of the scaling actions depends heavily on the exact 
computation model used in each deployment, such as:

- Spawning workers as virtual machines using a service such as Amazon AWS, 
  Microsoft Azure or Google Cloud Platform, or a self-hosted solution like 
  VMware vSphere.
- Running workers in containers orchestrated by Kubernetes or Apache Meson, for 
  example.
- Turning physical servers on and off using a proprietary remote management 
  console or KVM over IP
- Controlling a cluster of single board computers by switching their power 
  supply on and off through a custom monitor device.

With the exception of the last one, all these methods are rather simple to 
implement, typically by leveraging HTTP APIs exposed by the respective services. 
This functionality should be included in the auto-scaling service (or the load 
balancer, if a monolithic architecture is preferred).

It is also possible to combine these methods as necessary to cover use cases 
such as using physical servers for assignments that require precise measurements 
and virtual machines for the other assignments.

### Evaluation using Simulation

Using simulation to evaluate auto-scaling performance is preferred over 
measuring it on actual hardware or cloud platform to save costs and provide 
reproducible results.

If we were to use the simulator used for evaluation of load balancing algorithms 
in Chapter \ref{scheduling}, only minor changes would be required. New event 
types would have to be implemented for worker startup and shutdown, and for the 
invocation of the auto-scaler. The auto-scaler would then emit scaling actions 
that would result into worker startup and shutdown events being added to the 
simulation event queue.

To use the Clusterman simulator, a file containing performance metrics must be 
supplied as input. A random input generator has also been implemented as a part 
of the project. The simulator then outputs scaling actions.
