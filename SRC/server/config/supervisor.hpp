#pragma once
// Bộ đọc supervisor.toml: PostgreSQL, trần chạy lại, hạn dừng và các bước [[start]].
// Tập process và việc mỗi loại trừ gate có khối trong cluster nằm ở check_startup.

#include "config/issue.hpp"
#include "config/types.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <string_view>
#include <vector>

namespace game::config {

struct SupervisorPostgres {
    bool managed = false;
    std::chrono::seconds ready_timeout_seconds{0};
};

struct SupervisorRestart {
    std::int64_t max_per_hour = 0;
};

struct SupervisorStop {
    std::chrono::seconds timeout_seconds{0};
};

struct StartStep {
    ServiceKind process = ServiceKind::kStore;
    std::chrono::seconds ready_timeout_seconds{0};
    std::size_t line = 0;
};

struct Supervisor {
    SupervisorPostgres postgres;
    SupervisorRestart restart;
    SupervisorStop stop;
    std::vector<StartStep> steps;
};

[[nodiscard]] ReadResult<Supervisor> read_supervisor(std::string_view text);

} // namespace game::config
