#ifndef CONTAINERS_COMMON_H
#define CONTAINERS_COMMON_H

struct image_data {
    std::string repository;
    std::string name;
    std::string tag;
};

image_data parse_image_data(const std::string &image_string);

std::string strip_digest_type(const std::string &subject);

#endif //CONTAINERS_COMMON_H
