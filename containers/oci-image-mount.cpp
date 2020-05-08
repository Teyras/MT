#include <cerrno>
#include <cstring>
#include <filesystem>
#include <iostream>
#include <sys/mount.h>
#include <yaml-cpp/yaml.h>

#include "common.h"

namespace fs = std::filesystem;

void mount_image(const fs::path &images_dir, const std::string &image_name, const fs::path &target_dir)
{
    auto blobs_dir = images_dir / "blobs";
    auto image = parse_image_data(image_name);

    auto work_dir = fs::canonical(fs::absolute(target_dir)).parent_path() / (target_dir.stem().string() + "_work");
    auto upper_dir = fs::canonical(fs::absolute(target_dir)).parent_path() / (target_dir.stem().string() + "_modifications");

    fs::create_directories(target_dir);
    fs::create_directories(work_dir);
    fs::create_directories(upper_dir);

    auto manifest = YAML::LoadFile(images_dir / "manifests" / image.repository / image.name / (image.tag + ".json"));

    std::stringstream mount_opts;
    mount_opts << "lowerdir=";

    for (int i = 0; i < manifest["layers"].size(); i++) {
        if (i > 0) {
            mount_opts << ":";
        }

        auto digest = manifest["layers"][manifest["layers"].size() - 1 - i]["digest"].as<std::string>();
        mount_opts << fs::canonical(fs::absolute(blobs_dir / strip_digest_type(digest))).string();
    }

    mount_opts << ",workdir=" << work_dir.string() << ",upperdir=" << upper_dir.string();

    int rc = mount("overlay", fs::absolute(target_dir).c_str(), "overlay", 0, mount_opts.str().c_str());
    if (rc != 0) {
        throw std::runtime_error(std::string("mount system call failed: ") + std::strerror(errno));
    }
}

