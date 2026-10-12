#pragma once
// Đọc và kiểm các tệp cấu hình của một tiến trình. Lỗi trả về từng dòng `tệp:dòng: câu`, đủ mọi
// lỗi của mọi tệp một lượt. Không hàm nào ở đây mở secrets.local.toml.

#include "config/cluster.hpp"
#include "config/supervisor.hpp"
#include "service/detail/request.hpp"
#include "service/service.hpp"

#include <expected>
#include <filesystem>
#include <string>
#include <vector>

namespace game::service::detail {

using ErrorLines = std::vector<std::string>;

// Hai tệp trình giám sát cần để lập kế hoạch chạy.
struct ClusterFiles {
    config::Cluster cluster;
    config::Supervisor supervisor;
};

using ClusterResult = std::expected<ClusterFiles, ErrorLines>;

// Trình giám sát kiểm mọi tệp nó biết, của nó và của từng con, trước khi chạy bất cứ thứ gì.
[[nodiscard]] ClusterResult load_cluster(const std::filesystem::path& config_dir);

// Tiến trình con kiểm cluster.toml, log.toml, tệp của chính nó, và việc cluster.toml có khối
// [[process]] đúng loại và số của nó. Rỗng khi không lỗi.
[[nodiscard]] ErrorLines check_child(Kind kind, const Request& request);

} // namespace game::service::detail
