# Advanced Usage of Containers

This folder contains an implementation of downloading, unpacking and mounting of 
OCI container images:

- `oci-image-fetch.cpp` -- Downloads an image from an OCI Distribution registry 
  and stores the layers as files
- `oci-image-unpack.cpp` -- Copies image layer contents to create a single 
  directory that contains all files from an image
- `oci-image-mount.cpp` -- Same as above, but uses OverlayFS instead of copying
- `benchmark.cpp` -- A simple benchmark that compares the performance of 
  mounting and unpacking an image
- `benchmark_results.csv` -- Results of the benchmark as used in the thesis
- `plots/plot-mount-vs-unpack.r` -- A script that plots the results of the 
  benchmark

## Running the Benchmark

- Make sure you have cURL, yaml-cpp and libarchive installed
- Create a `build` directory and switch to it
- Run `cmake ..` and `make`
- Run the benchmark with `./benchmark IMAGES_DIR MOUNT_POINT` where `IMAGES_DIR` 
  is the directory where downloaded image layers are stored and `MOUNT_POINT` is 
  a directory where the images will be copied or mounted. Note that the 
  benchmark requires root permissions because it works with OverlayFS.

