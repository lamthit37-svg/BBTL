#pragma once
// Bộ đọc hình dạng secrets.example.toml. Mật khẩu rỗng hợp lệ vì tệp mẫu để trống.
// Không có hàm nào mở secrets.local.toml.

#include "config/issue.hpp"

#include <string>
#include <string_view>

namespace game::config {

struct Secrets {
    std::string postgres;
    std::string auth;
    std::string billing;
    std::string store;
};

[[nodiscard]] ReadResult<Secrets> read_secrets(std::string_view text);

} // namespace game::config
