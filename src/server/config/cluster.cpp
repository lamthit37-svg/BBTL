#include "config/cluster.hpp"

#include "config/detail/node.hpp"
#include "config/detail/read.hpp"
#include "config/issue.hpp"
#include "config/types.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <optional>
#include <span>
#include <string_view>
#include <utility>
#include <vector>

namespace game::config {
namespace {

using detail::add_issue;
using detail::Bag;
using detail::Choice;
using detail::Cursor;
using detail::keep;
using detail::Node;
using detail::Presence;
using detail::Rows;

constexpr std::array<std::string_view, 5> kRoot{"schema", "world", "postgres", "machine", "process"};
constexpr std::array<std::string_view, 4> kWorld{"id", "zone_group", "name", "table_variant"};
constexpr std::array<std::string_view, 5> kPostgres{"host", "port", "bin_dir", "data_dir", "log_file"};
constexpr std::array<std::string_view, 1> kMachine{"id"};
constexpr std::array<std::string_view, 5> kProcess{"kind", "id", "machine", "host", "port"};
constexpr std::array<Choice<ProcessKind>, 5> kKinds{{
    {.name = "store", .value = ProcessKind::kStore},
    {.name = "auth", .value = ProcessKind::kAuth},
    {.name = "billing", .value = ProcessKind::kBilling},
    {.name = "world", .value = ProcessKind::kWorld},
    {.name = "zone", .value = ProcessKind::kZone},
}};
constexpr std::size_t kBlockMost = 256;

[[nodiscard]] bool has_machine(std::span<const MachineBlock> machines, MachineId id) noexcept {
    const auto same = [&](const MachineBlock& block) { return block.id.same(id); };
    return std::ranges::any_of(machines, same);
}

[[nodiscard]] bool has_process(std::span<const ProcessBlock> blocks, const ProcessBlock& wanted) {
    const auto same = [&](const ProcessBlock& block) { return block.kind == wanted.kind && block.id.same(wanted.id); };
    return std::ranges::any_of(blocks, same);
}

void check_machine(Bag& bag, const Cluster& cluster, std::size_t index) {
    const std::span<const MachineBlock> earlier{cluster.machines.data(), index};
    const MachineBlock& block = cluster.machines[index];
    if (has_machine(earlier, block.id)) add_issue(bag, block.line, "id máy lặp");
}

void check_process(Bag& bag, const Cluster& cluster, std::size_t index) {
    const std::span<const ProcessBlock> earlier{cluster.processes.data(), index};
    const ProcessBlock& block = cluster.processes[index];
    if (has_process(earlier, block)) add_issue(bag, block.line, "cặp kind và id lặp");
    const bool is_placed = has_machine(cluster.machines, block.machine);
    if (!is_placed) add_issue(bag, block.line, "máy không có trong danh sách");
}

// Kiểm chéo giữa các khối: id máy không lặp, cặp (kind, id) không lặp, máy của tiến trình có thật.
void check_blocks(Bag& bag, const Cluster& cluster) {
    for (std::size_t index = 0; index < cluster.machines.size(); ++index) {
        check_machine(bag, cluster, index);
    }
    for (std::size_t index = 0; index < cluster.processes.size(); ++index) {
        check_process(bag, cluster, index);
    }
}

void read_world(Bag& bag, const Node* table, WorldSection& world) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kWorld);
    keep(cursor.world_id("id"), world.id);
    keep(cursor.bounded("zone_group", detail::kAmount), world.zone_group);
    keep(cursor.text("name", detail::kNameText), world.name);
    keep(cursor.text("table_variant", detail::kVariantText), world.table_variant);
}

void read_postgres(Bag& bag, const Node* table, PostgresPaths& postgres) {
    if (table == nullptr) return;
    Cursor cursor{bag, *table};
    cursor.only(kPostgres);
    keep(cursor.ipv4("host"), postgres.host);
    keep(cursor.port("port"), postgres.port);
    keep(cursor.text("bin_dir", detail::kPathText), postgres.bin_dir);
    keep(cursor.text("data_dir", detail::kPathText), postgres.data_dir);
    keep(cursor.text("log_file", detail::kPathText), postgres.log_file);
}

void read_machine(Bag& bag, const Node& table, std::vector<MachineBlock>& out) {
    Cursor cursor{bag, table};
    cursor.only(kMachine);
    const std::optional<MachineId> id = cursor.machine_id("id");
    if (!id) return;
    MachineBlock block;
    block.id = *id;
    block.line = table.line;
    out.push_back(block);
}

void read_process(Bag& bag, const Node& table, std::vector<ProcessBlock>& out) {
    Cursor cursor{bag, table};
    cursor.only(kProcess);
    const std::optional<ProcessKind> kind = cursor.choice("kind", kKinds);
    const std::optional<ProcessId> id = cursor.process_id("id");
    const std::optional<MachineId> machine = cursor.machine_id("machine");
    const std::optional<Ipv4Address> host = cursor.ipv4("host");
    const std::optional<Port> port = cursor.listen_port("port", host);
    const bool is_whole = kind && id && machine && host && port;
    if (!is_whole) return;
    ProcessBlock block;
    block.line = table.line;
    block.kind = *kind;
    block.id = *id;
    block.machine = *machine;
    block.host = *host;
    block.port = *port;
    out.push_back(std::move(block));
}

[[nodiscard]] Cluster read_sections(Bag& bag, const Node& root) {
    Cursor cursor{bag, root};
    cursor.schema();
    cursor.only(kRoot);
    Cluster cluster;
    read_world(bag, cursor.child("world"), cluster.world);
    read_postgres(bag, cursor.child("postgres"), cluster.postgres);
    for (const Node* machine : cursor.rows("machine", Presence::kRequired, kBlockMost)) {
        read_machine(bag, *machine, cluster.machines);
    }
    for (const Node* process : cursor.rows("process", Presence::kRequired, kBlockMost)) {
        read_process(bag, *process, cluster.processes);
    }
    check_blocks(bag, cluster);
    return cluster;
}

} // namespace

ReadResult<Cluster> read_cluster(std::string_view text) {
    return detail::read_document<Cluster>(text, read_sections);
}

} // namespace game::config
