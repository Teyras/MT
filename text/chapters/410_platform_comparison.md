## Auto-scaling in Cloud Platforms

In this section, we compare the auto-scaling facilities provided by the three 
largest cloud providers as of today (based on anecdotal evidence) -- Google 
Cloud Platform, Amazon Web Services and Microsoft Azure.

It seems that even though the product names and precise terminology differs, the 
mechanisms for auto-scaling offered by the three providers are mostly 
equal[@GCPScaling][@AzureScaling][@AWSScaling]. All the providers support 
rule-based horizontal scaling based on resource utilization over time. The 
supported utilization metrics include variations of CPU usage, memory usage and 
network traffic. All of the providers also allow the services to report custom 
utilization metrics that can be used for auto-scaling. The scaling rules 
typically instruct the platform to create or remove instances if the average of 
some utilization metrics over a time period reaches a user-defined threshold.

Another common feature is scaling based on time. If the user knows that the 
traffic is periodic, they can set up a rule that launches new instances at a 
given time of a day.

Amazon EC2 (a service included in AWS) also provides a service that does not 
seem to have an equivalent in the other platforms: Predictive 
Scaling[@AWSScalingPlans]. It is advertised to use machine learning to predict 
traffic spikes and react to them. This allows the end user to specify a 
utilization target (e.g., CPU utilization should be 80%) which will be maintaned 
by the autoscaler without a need to configure other thresholds.
