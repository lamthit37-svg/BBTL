#pragma once
// Kiểm chéo supervisor với cluster: bước khởi động không lặp, thuộc tập đã chốt,
// và mỗi loại trừ gate có ít nhất một khối [[process]].

#include "config/cluster.hpp"
#include "config/issue.hpp"
#include "config/supervisor.hpp"

namespace game::config {

[[nodiscard]] StartupResult check_startup(const Cluster& cluster, const Supervisor& supervisor);

} // namespace game::config
