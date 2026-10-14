// Bảng cổng máy chủ của client: mỗi máy chủ trong danh sách chọn máy chủ (Table/login_servers.tsv) có thể
// kèm địa chỉ cổng game, cổng xác thực và khoá công khai của gate để ghim. Máy chủ không có dòng ở bảng này là
// máy chủ cục bộ (chế độ offline: sổ nhân vật ở tệp, không mở socket). Bảng nằm ở Table/gates.tsv của thư mục
// dữ liệu client; công cụ TOOLS/server/export_gates.py ghi nó từ cấu hình và khoá danh tính của máy chủ.
// Khoá công khai không phải bí mật (client ghim nó), nhưng mỗi máy chủ có khoá riêng nên bảng không vào git.
// Bản mới của dự án, client gốc đọc danh sách máy chủ từ loginserver.txt do bộ khởi động đưa vào.
#pragma once

#include "net/net.hpp"
#include "secure/secure.hpp"

#include <cstddef>
#include <expected>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::client::session {

// Tên bảng trong thư mục Table.
inline constexpr std::string_view kGateTable = "gates.tsv";
// Trần số dòng nhận từ bảng; dòng thừa là lỗi chứ không bị bỏ lặng lẽ.
inline constexpr std::size_t kGateCap = 256;

struct Gate {
    // Tên vùng và tên máy chủ, đúng từng byte với LoginArea::name và LoginServer::name của danh sách máy chủ.
    std::string area;
    std::string server;
    net::Endpoint game;
    net::Endpoint auth;
    secure::PublicKey key;
};

struct GateBook {
    std::vector<Gate> gates;
};

// Câu lỗi tiếng Việt kèm số dòng của tệp.
using GateBookResult = std::expected<GateBook, std::string>;

// Đọc bảng TSV với các cột area, server, host, game_port, auth_port, key. host là địa chỉ IPv4 viết
// thập phân; hai cổng trong 1..65535; key là 64 chữ số hex (32 byte). Một dòng sai, trùng (vùng, máy chủ)
// hoặc vượt kGateCap là lỗi cả bảng: bảng sai thì thà không có máy chủ trực tuyến nào còn hơn nối nhầm.
// O(số dòng bình phương) ở bước kiểm trùng, trần kGateCap dòng.
[[nodiscard]] GateBookResult read_gate_book(std::string_view text);

// Gate của máy chủ có đúng tên vùng và tên máy chủ; nullptr khi không có.
[[nodiscard]] const Gate* find_gate(const GateBook& book, std::string_view area, std::string_view server) noexcept;

// Khoá công khai từ 64 chữ số hex (hoa hay thường); không có khi sai độ dài hay có ký tự lạ.
[[nodiscard]] std::optional<secure::PublicKey> decode_key(std::string_view hex) noexcept;

} // namespace game::client::session
