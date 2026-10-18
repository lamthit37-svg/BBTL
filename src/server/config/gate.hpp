/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/config/gate.hpp
 *  PHÂN HỆ   : Server / Config / Gate
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Bộ đọc gate.toml: khoá danh tính, cổng nghe, trần kết nối và lọc địa chỉ.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/
#pragma once

#include "config/issue.hpp"
#include "config/types.hpp"

#include <chrono>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace game::config {

struct GateListen {
    Endpoint game;
    Endpoint auth;
};

struct GateLimits {
    std::int64_t max_connections = 0;
    std::int64_t per_ip_connections = 0;
    std::chrono::milliseconds handshake_timeout_ms{0};
    std::chrono::milliseconds idle_timeout_ms{0};
    std::int64_t client_frame_bytes = 0;
    std::int64_t messages_per_second = 0;
    // Bình chứa riêng cho Move (H1-B): nạp moves_per_second Move mỗi giây, chứa tối đa move_burst
    // Move. Client thật gửi 20 Move mỗi giây. Ràng buộc: move_burst ≥ nhịp Move của client ×
    // idle_timeout_ms (20 × 15 = 300, lấy 320), để mạng đứng chưa tới hạn idle không bị bình tin
    // ngắt khi xả dồn. Tuỳ chọn.
    std::int64_t moves_per_second = 25;
    std::int64_t move_burst = 320;
    // Trần per_ip_connections tính theo dải /per_ip_prefix (32 = từng IP, 24 = cả dải /24). Tuỳ
    // chọn.
    std::int64_t per_ip_prefix = 32;
};

// Nối lại phiên sau rớt mạng. Nhóm [resume] tuỳ chọn; token luôn dùng một lần (không có nút tắt).
struct GateResume {
    // true: Resume từ IP khác IP đã vào game thì huỷ phiên (token coi như lộ).
    bool bind_to_ip = true;
    // Phiên rớt mạng chờ Resume chừng này; 0 là tắt Resume.
    std::chrono::milliseconds grace_ms{30000};
};

struct GateClient {
    std::int64_t min_version = 0;
    // Rỗng: không lọc bản dựng. Có số: Hello.build phải nằm trong danh sách.
    std::vector<std::int64_t> allowed_builds;
};

struct GateIpFilter {
    std::vector<std::string> allow;
    std::vector<std::string> deny;
};

struct Gate {
    std::string identity_key_file;
    std::vector<std::string> trusted_proxies;
    GateListen listen;
    GateLimits limits;
    GateClient client;
    GateIpFilter ip_filter;
    GateResume resume;
};

[[nodiscard]] ReadResult<Gate> read_gate(std::string_view text);

} // namespace game::config
