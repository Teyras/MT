#ifndef CONTAINERS_OCI_IMAGE_FETCH_H
#define CONTAINERS_OCI_IMAGE_FETCH_H

#include <filesystem>
#include <string>

void fetch_image(const std::filesystem::path &images_dir, const std::string &image_name);

#endif
