#ifndef CONTAINERS_OCI_IMAGE_MOUNT_H
#define CONTAINERS_OCI_IMAGE_MOUNT_H

#include <filesystem>
#include <string>

void mount_image(const std::filesystem::path &images_dir, const std::string &image_name, const std::filesystem::path &target_dir);

#endif
