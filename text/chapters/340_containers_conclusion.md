## Conclusion

We have shown that the proposed method of incorporating containers into 
programming assignment evaluation systems is practically usable. The parts we 
implemented as a part of this thesis can be easily adopted by ReCodEx or a 
similar system.

Employing containers helps solve the problem of scheduling over workers with 
diverse runtime environments by automating the process of distributing new or 
updated software to the worker machines, which leads to a more efficient 
operation and easier maintenance.

Using our work, it is also possible to add support for user-defined environments 
for specific courses. This helps widen the range of exercise types that can 
benefit from automated evaluation.

Even though our work is motivated by the Docker container engine, it does not 
depend on it directly. We do not require it to be installed on worker machines, 
runtime environments can be built with any tools that output OCI-compliant 
container images and any implementation of the OCI Distribution API 
specification can be used.
