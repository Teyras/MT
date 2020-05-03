#include <filesystem>
#include <iostream>
#include <yaml-cpp/yaml.h>

#include "common.h"

namespace fs = std::filesystem;

void unpack_image(const fs::path &images_dir, const std::string &image_name, const fs::path &target_dir)
{
    auto blobs_dir = images_dir / "blobs";
    fs::create_directories(target_dir);
    auto image = parse_image_data(image_name);
    auto manifest = YAML::LoadFile(images_dir / "manifests" / image.repository / image.name / (image.tag + ".json"));

    for (int i = 0; i < manifest["layers"].size(); i++) {
        auto digest = manifest["layers"][manifest["layers"].size() - 1 - i]["digest"].as<std::string>();
        fs::copy(blobs_dir / strip_digest_type(digest), target_dir, fs::copy_options::recursive | fs::copy_options::copy_symlinks);
    }
}

void print_usage(const char *program_name)
{
    std::cerr << "usage: " << program_name << " IMAGES_DIR IMAGE_NAME MOUNT_POINT" << std::endl;
}

int main(int argc, char **argv)
{
    if (argc < 3) {
        print_usage(argv[0]);
        return 1;
    }

    unpack_image(argv[1], argv[2], argv[3]);
    return 0;
}
