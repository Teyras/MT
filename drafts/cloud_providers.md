# PaaS

## Amazon EC2

- GNU/Linux, should support cgroups and namespaces
- autoscaling based on network traffic and cpu-utilization rules
- has an HTTP API that is capable of copying/starting/stopping instances

## Rackspace cloud

- has an API

## Microsoft Azure

- has API, CLI

## Google App Engine

- probably not a good idea...

## BlueMix (CloudFoundry)

- no buildpack can run the worker (other ways? containers?)
- Kubernetes support

# Self-hosted

## OpenShift

- OpenShift Online is a PaaS thing
- Based on Kubernetes and Docker

## OpenStack

- By Rackspace
- A bunch of components that cover most cloud stuff

## vSphere

- installed at school
- has an API https://github.com/vmware/vsphere-automation-sdk-rest

# Summary

- almost everyone has something that can be used to launch more virtual machines
- the core functionality is +/- the same everywhere
- prices might vary
- interesting options are Kubernetes (supported on many platforms) and vSphere 
  (available at school)
