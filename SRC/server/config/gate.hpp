#pragma once
// Bộ đọc gate.toml: khoá danh tính, cổng nghe, trần kết nối và lọc địa chỉ.

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
};

struct GateClient {
    std::int64_t min_version = 0;
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
};

[[nodiscard]] ReadResult<Gate> read_gate(std::string_view text);

} // namespace game::config
