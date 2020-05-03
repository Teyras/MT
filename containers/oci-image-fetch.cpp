#include <archive.h>
#include <archive_entry.h>
#include <cstring>
#include <curl/curl.h>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <map>
#include <regex>
#include <yaml-cpp/yaml.h>

#include "common.h"

namespace fs = std::filesystem;

struct curl_slist_wrapper
{
    curl_slist *pointer = nullptr;

    ~curl_slist_wrapper()
    {
        if (pointer != nullptr){
            curl_slist_free_all(pointer);
        }
    }

    void append(const std::string &value)
    {
        pointer = curl_slist_append(pointer, value.c_str());
    }
};

std::string download_as_string(const std::string &url, const std::map<std::string, std::string> &headers)
{
    std::unique_ptr<CURL, decltype(&curl_easy_cleanup)> curl = {curl_easy_init(), curl_easy_cleanup};

    std::string result;

    // Destination URL
    curl_easy_setopt(curl.get(), CURLOPT_URL, url.c_str());

    // HTTP headers
    curl_slist_wrapper curl_headers;
    for (auto &it : headers) {
        curl_headers.append(it.first + ": " + it.second);
    }

    curl_easy_setopt(curl.get(), CURLOPT_HTTPHEADER, curl_headers.pointer);

    // Configure response body handler
    auto handler = [] (void *contents, size_t size, size_t nmemb, void *userp) {
        size_t real_size = nmemb * size;
        auto contents_char = static_cast<char *>(contents);

        auto dest = static_cast<std::string *>(userp);
        dest->append(contents_char, contents_char + real_size);

        return real_size;
    };

    curl_easy_setopt(curl.get(), CURLOPT_WRITEFUNCTION, +handler);
    // Pass destination as user data since lambdas with captures cannot be converted to function pointers required by cURL
    curl_easy_setopt(curl.get(), CURLOPT_WRITEDATA, &result);

    // Follow redirects
    curl_easy_setopt(curl.get(), CURLOPT_FOLLOWLOCATION, 1L);
    // Enable support for HTTP2
    curl_easy_setopt(curl.get(), CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_2_0);
    // Enable SSL verification
    curl_easy_setopt(curl.get(), CURLOPT_SSL_VERIFYPEER, 1L);
    curl_easy_setopt(curl.get(), CURLOPT_SSL_VERIFYHOST, 2L);
    // Throw exception on HTTP responses >= 400
    curl_easy_setopt(curl.get(), CURLOPT_FAILONERROR, 1L);

    // curl_easy_setopt(curl.get(), CURLOPT_VERBOSE, 1L);

    CURLcode res = curl_easy_perform(curl.get());

    if (res != CURLE_OK) {
        throw std::runtime_error("Fetching `" + url + "` failed");
    }

    return result;
}

void unpack_layer_archive(const std::string &archive_content, const fs::path &target_directory)
{
    std::unique_ptr<archive, decltype(&archive_read_free)> a = {archive_read_new(), archive_read_free};
    archive_read_support_format_all(a.get());
    archive_read_support_filter_all(a.get());

    int rc = archive_read_open_memory(a.get(), archive_content.c_str(), archive_content.length());
    if (rc != ARCHIVE_OK) {
        throw std::runtime_error(std::string("Failed to read archive: ") + archive_error_string(a.get()));
    }

    std::unique_ptr<archive, decltype(&archive_write_free)> ext = {archive_write_disk_new(), archive_write_free};
    rc = archive_write_disk_set_options(ext.get(), ARCHIVE_EXTRACT_TIME | ARCHIVE_EXTRACT_PERM | ARCHIVE_EXTRACT_ACL | ARCHIVE_EXTRACT_FFLAGS | ARCHIVE_EXTRACT_SECURE_NODOTDOT);
    if (rc != ARCHIVE_OK) {
        throw std::runtime_error(std::string("Failed to set writing options: ") + archive_error_string(ext.get()));
    }

    rc = archive_write_disk_set_standard_lookup(ext.get());
    if (rc != ARCHIVE_OK) {
        throw std::runtime_error(std::string("Cannot set lookup for writing to disk: ") + archive_error_string(ext.get()));
    }

    // Read archive entries and extract them
    while (true) {
        archive_entry *entry;
        rc = archive_read_next_header(a.get(), &entry);

        if (rc == ARCHIVE_EOF) {
            break;
        }

        if (rc != ARCHIVE_OK) {
            continue;
        }

        auto current_file = archive_entry_pathname(entry);

        archive_entry_set_pathname(entry, (target_directory / current_file).c_str());

        auto hardlink = archive_entry_hardlink(entry);
        if (hardlink != nullptr) {
            archive_entry_set_hardlink(entry, (target_directory / hardlink).c_str());
        }

        rc = archive_write_header(ext.get(), entry);
        if (rc != ARCHIVE_OK) {
            throw std::runtime_error(std::string("Failed to write file metadata: ") + archive_error_string(ext.get()));
        }

        // Copy the data of the entry
        if (archive_entry_size(entry) > 0) {
            const void *buffer;
            size_t size;
            la_int64_t offset;

            while (true) {
                rc = archive_read_data_block(a.get(), &buffer, &size, &offset);

                if (rc == ARCHIVE_EOF) {
                    break;
                }

                if (rc != ARCHIVE_OK) {
                    throw std::runtime_error(std::string("Failed to read source file: ") + archive_error_string(a.get()));
                }

                rc = archive_write_data_block(ext.get(), buffer, size, offset);
                if (rc != ARCHIVE_OK) {
                    throw std::runtime_error(std::string("Failed to write file contents: ") + archive_error_string(a.get()));
                }
            }
        }

        rc = archive_write_finish_entry(ext.get());
        if (rc != ARCHIVE_OK) {
            throw std::runtime_error(std::string("Failed to write file: ") + archive_error_string(ext.get()));
        }
    }
}

void fetch_image(const fs::path &images_dir, const std::string &image_name)
{
    auto blobs_dir = images_dir / "blobs";
    fs::create_directory(blobs_dir);

    auto manifests_dir = images_dir / "manifests";
    fs::create_directory(manifests_dir);
    
    auto config_dir = images_dir / "config";
    fs::create_directory(config_dir);

    std::string registry("registry-1.docker.io");
    std::string auth_server("auth.docker.io");
    auto image = parse_image_data(image_name);

    auto auth = download_as_string("https://" + auth_server + "/token?service=registry.docker.io&scope=repository:" + image.repository + "/" + image.name + ":pull", {});
    auto token = YAML::Load(auth)["token"].as<std::string>();
    std::map<std::string, std::string> auth_headers{{"Authorization", "Bearer " + token}};

    auto image_url = "https://" + registry + "/v2/" + image.repository + "/" + image.name;

    auto manifest_headers = auth_headers;
    manifest_headers.emplace("Accept", "application/vnd.docker.distribution.manifest.v2+json");
    auto manifest = download_as_string(image_url + "/manifests/" + image.tag, manifest_headers);

    auto manifest_dir = manifests_dir / image.repository / image.name;
    fs::create_directories(manifest_dir);

    {
        std::ofstream manifest_file(manifest_dir / (image.tag + ".json"));
        manifest_file << manifest;
    }

    auto parsed_manifest = YAML::Load(manifest);
    auto layers = parsed_manifest["layers"];

    auto config = download_as_string(image_url + "/blobs/" + parsed_manifest["config"]["digest"].as<std::string>(), auth_headers);
    fs::create_directories(config_dir / image.repository / image.name);
    {
        std::ofstream config_file(config_dir / image.repository / image.name / (image.tag + ".json"));
        config_file << config;
    }

    auto layer_headers = auth_headers;
    layer_headers.emplace("Accept", "application/vnd.docker.image.rootfs.diff.tar.gzip");

    for (auto it = std::cbegin(layers); it != std::cend(layers); ++it) {
        auto blob_digest = (*it)["digest"].as<std::string>();

        if (fs::exists(blobs_dir / strip_digest_type(blob_digest))) {
            continue;
        }

        auto blob_content = download_as_string(image_url + "/blobs/" + blob_digest, layer_headers);
        unpack_layer_archive(blob_content, blobs_dir / strip_digest_type(blob_digest));
    }
}

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