cmake_minimum_required(VERSION 3.17)
project(containers)

set(CMAKE_CXX_STANDARD 17)

set(FETCH_EXEC oci-image-fetch)
add_executable(${FETCH_EXEC} common.cpp oci-image-fetch.cpp oci-image-fetch-main.cpp)

set(MOUNT_EXEC oci-image-mount)
add_executable(${MOUNT_EXEC} common.cpp oci-image-mount.cpp oci-image-mount-main.cpp)

set(UNPACK_EXEC oci-image-unpack)
add_executable(${UNPACK_EXEC} common.cpp oci-image-unpack.cpp oci-image-unpack-main.cpp)

set(BENCHMARK_EXEC benchmark)
add_executable(${BENCHMARK_EXEC} common.cpp oci-image-unpack.cpp oci-image-mount.cpp oci-image-fetch.cpp benchmark.cpp)

# Set up LibArchive
find_package(LibArchive REQUIRED)

include_directories(AFTER, ${LibArchive_INCLUDE_DIRS})
target_link_libraries(${FETCH_EXEC} ${LibArchive_LIBRARIES})
target_link_libraries(${BENCHMARK_EXEC} ${LibArchive_LIBRARIES})

# Set up cURL
find_package(CURL REQUIRED)
include_directories(${CURL_INCLUDE_DIRS})
target_link_libraries(${FETCH_EXEC} ${CURL_LIBRARIES})
target_link_libraries(${BENCHMARK_EXEC} ${CURL_LIBRARIES})

# Set up yaml-cpp (for JSON parsing)
find_package(yaml-cpp REQUIRED)
include_directories(${YAML_CPP_INCLUDE_DIR})
target_link_libraries(${FETCH_EXEC} ${YAML_CPP_LIBRARIES})
target_link_libraries(${MOUNT_EXEC} ${YAML_CPP_LIBRARIES})
target_link_libraries(${UNPACK_EXEC} ${YAML_CPP_LIBRARIES})
target_link_libraries(${BENCHMARK_EXEC} ${YAML_CPP_LIBRARIES})
