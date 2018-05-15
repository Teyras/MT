#!/bin/sh

root=$(dirname $(realpath $0))
cd $root

docker build -t recodex-measurements:latest -f $root/docker/Dockerfile
