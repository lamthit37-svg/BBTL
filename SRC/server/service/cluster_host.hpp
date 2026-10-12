#pragma once
// Bộ chạy thật của trình giám sát: mỗi ô của kế hoạch là một exe thienlong_<loại> trong cùng một
// thư mục, PostgreSQL điều khiển qua pg_ctl. Header công khai để test chạy nó với exe thật.

#include "config/cluster.hpp"
#include "supervise/supervise.hpp"

#include <filesystem>
#include <memory>

namespace game::service {

struct HostSetup {
    // Thư mục chứa các exe thienlong_<loại>.
    std::filesystem::path program_dir;
    // Thư mục cấu hình đưa cho từng con; đường dẫn tương đối của PostgreSQL tính từ đây.
    std::filesystem::path config_dir;
    config::PostgresPaths postgres;
};

[[nodiscard]] std::unique_ptr<supervise::Host> make_cluster_host(const HostSetup& setup);

} // namespace game::service
