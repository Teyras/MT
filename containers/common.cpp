#include <regex>
#include <string>

#include "common.h"

image_data parse_image_data(const std::string &image_string)
{
    std::regex image_name_re("([^/]+/)?([^:]+)(:.+)?");
    std::smatch match;

    auto matched = std::regex_match(image_string, match, image_name_re);

    if (!matched) {
        throw std::invalid_argument("Invalid image name format");
    }

    return image_data{
        .repository = match[1].matched ? match[1].str().substr(0, match[1].str().size() - 1) : "library",
        .name = match[2].str(),
        .tag = match[3].matched ? match[3].str().substr(1) : "latest"
    };
}

std::string strip_digest_type(const std::string &subject)
{
    return subject.substr(subject.find(':') + 1);
}
