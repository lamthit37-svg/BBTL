// Sổ nhân vật cục bộ trên đĩa (xem login_data.hpp).
#include "client/display/login_data.hpp"

#include "io/file.hpp"

#include <filesystem>
#include <fstream>
#include <ios>
#include <string>
#include <string_view>
#include <system_error>

namespace game::client {

std::string read_role_book(const std::filesystem::path& file) {
    const io::TextResult text = io::read_text(file);
    if (!text) return {};
    return *text;
}

bool write_role_book(const std::filesystem::path& file, std::string_view text) {
    std::error_code error;
    std::filesystem::create_directories(file.parent_path(), error);
    if (error) return false;
    std::ofstream out(file, std::ios::binary | std::ios::trunc);
    if (!out) return false;
    out.write(text.data(), static_cast<std::streamsize>(text.size()));
    out.flush();
    return out.good();
}

} // namespace game::client
