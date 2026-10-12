#pragma once
// Bộ đọc cluster.toml: thế giới, cụm PostgreSQL, máy và tiến trình ipc.
// Cặp (kind, id) lặp là lỗi của tệp này. Hàm không mở đường dẫn trong giá trị.

#include "config/issue.hpp"
#include "config/types.hpp"

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace game::config {

struct WorldSection {
    WorldId id;
    std::int64_t zone_group = 0;
    std::string name;
    std::string table_variant;
};

struct PostgresPaths {
    Ipv4Address host;
    Port port;
    std::string bin_dir;
    std::string data_dir;
    std::string log_file;
};

struct MachineBlock {
    MachineId id;
    std::size_t line = 0;
};

struct ProcessBlock {
    ProcessKind kind = ProcessKind::kStore;
    ProcessId id;
    MachineId machine;
    Ipv4Address host;
    Port port;
    std::size_t line = 0;
};

struct Cluster {
    WorldSection world;
    PostgresPaths postgres;
    std::vector<MachineBlock> machines;
    std::vector<ProcessBlock> processes;
};

[[nodiscard]] ReadResult<Cluster> read_cluster(std::string_view text);

} // namespace game::config
