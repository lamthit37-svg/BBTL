// Đọc bảng THẬT của máy chủ (dev/server/tables/server/*.tsv) cho các ca kiểm trên dữ liệu thật. Chỉ có nghĩa khi CMake đặt
// GAME_SERVER_TABLES (có thư mục bảng lúc cấu hình); thiếu bảng thì trả nullopt và ca kiểm tự bỏ qua.
#pragma once

#include "table/tsv.hpp"

#include <cstdio>
#include <fstream>
#include <iterator>
#include <optional>
#include <print>
#include <string>
#include <utility>

namespace game::test {

#ifdef GAME_SERVER_TABLES

[[nodiscard]] inline std::optional<table::Tsv> read_server_table(const std::string& name) {
    std::ifstream stream(std::string(GAME_SERVER_TABLES) + "/server/" + name + ".tsv", std::ios::binary);
    if (!stream) return std::nullopt;
    const std::string text((std::istreambuf_iterator<char>(stream)), std::istreambuf_iterator<char>());
    auto parsed = table::parse_tsv(text);
    if (!parsed) {
        std::print(stderr, "{}: {}\n", name, parsed.error());
        return std::nullopt;
    }
    return std::move(*parsed);
}

#endif

}  // namespace game::test
