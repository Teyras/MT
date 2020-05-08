#include <iostream>

#include "oci-image-unpack.h"

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
