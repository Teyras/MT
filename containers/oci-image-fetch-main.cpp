#include <iostream>

#include "oci-image-fetch.h"

void print_usage(const char *program_name)
{
    std::cerr << "usage: " << program_name << " IMAGE_DIR IMAGE_URL" << std::endl;
}

int main(int argc, char **argv)
{
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }

    fetch_image(argv[1], argv[2]);
    return 0;
}
