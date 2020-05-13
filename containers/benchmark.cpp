#include <cstring>
#include <filesystem>
#include <iostream>
#include <string>
#include <sys/mount.h>
#include <thread>
#include <vector>

#include "oci-image-fetch.h"
#include "oci-image-mount.h"
#include "oci-image-unpack.h"

namespace fs = std::filesystem;

void print_usage(const char *program_name)
{
    std::cerr << "usage: " << program_name << " IMAGES_DIR MOUNT_POINT" << std::endl;
}

void measure_mount(const fs::path &images_dir, const std::string &image_name, const fs::path &mount_point)
{
    auto before = std::chrono::steady_clock::now();
    for (size_t i = 0; i < 10; i++) {
        mount_image(images_dir, image_name, mount_point);
        auto rc = umount(mount_point.c_str());
        if (rc != 0) {
            throw std::runtime_error(std::string("umount system call failed: ") + std::strerror(errno));
        }
    }
    auto after = std::chrono::steady_clock::now();

    fs::remove_all(fs::absolute(mount_point).parent_path() / (mount_point.stem().string() + "_work"));
    fs::remove_all(fs::absolute(mount_point).parent_path() / (mount_point.stem().string() + "_modifications"));

    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(after - before);

    std::cout << image_name << ",mount," << duration.count() << std::endl;
}

void measure_unpack(const fs::path &images_dir, const std::string &image_name, const fs::path &unpack_destination)
{
    auto before = std::chrono::steady_clock::now();
    for (size_t i = 0; i < 10; i++) {
        fs::remove_all(unpack_destination);
        unpack_image(images_dir, image_name, unpack_destination);
    }
    auto after = std::chrono::steady_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(after - before);

    std::cout << image_name << ",unpack," << duration.count() << std::endl;
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }

    std::vector<std::string> images {"alpine:3.11.6", "fedora:31", "python:3.8.2", "glassfish:4.1-jdk8"};

    for (auto &image: images) {
        fetch_image(argv[1], image);

        for (size_t i = 0; i < 100; i++) {
            measure_mount(argv[1], image, argv[2]);
            measure_unpack(argv[1], image, argv[2]);
        }
    }

    return 0;
}
