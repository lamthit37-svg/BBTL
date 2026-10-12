#include "client/map/gates.hpp"

#include "core/check.hpp"

#include <bit>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string_view>

namespace game::client::map {
namespace {

constexpr std::uint32_t kMagic = 0xDDBBCC00U;
constexpr std::size_t kColumnCount = 12;
constexpr std::size_t kHeadBytes = 16;
constexpr std::size_t kRecordBytes = kColumnCount * sizeof(std::uint32_t);
// Lệch byte trong bản ghi, đúng struct đã dịch từ Game.exe 0x9b8ff0.
constexpr std::size_t kSourceSceneAt = 8;
constexpr std::size_t kSourceXAt = 12;
constexpr std::size_t kSourceZAt = 16;
constexpr std::size_t kDestSceneAt = 24;
constexpr std::size_t kDestXAt = 28;
constexpr std::size_t kDestZAt = 32;
constexpr std::size_t kFieldNineAt = 36;
constexpr std::size_t kFieldTenAt = 40;
constexpr std::size_t kFieldElevenAt = 44;

struct TableHead {
    std::uint32_t columns = 0;
    std::uint32_t rows = 0;
    std::uint32_t strings = 0;
};

struct EntranceNote {
    int count = 0;
    int x = 0;
    int z = 0;
    bool clash = false;
};

[[nodiscard]] std::uint32_t read_u32(std::string_view bytes, std::size_t offset) noexcept {
    const bool fits = offset <= bytes.size() && bytes.size() - offset >= 4;
    core::check(fits, "đọc số cổng ngoài bảng");
    const auto first = static_cast<unsigned char>(bytes[offset]);
    const auto second = static_cast<unsigned char>(bytes[offset + 1]);
    const auto third = static_cast<unsigned char>(bytes[offset + 2]);
    const auto fourth = static_cast<unsigned char>(bytes[offset + 3]);
    const auto low = static_cast<std::uint32_t>(first);
    const auto next = static_cast<std::uint32_t>(second) << 8;
    const auto high = static_cast<std::uint32_t>(third) << 16;
    const auto top = static_cast<std::uint32_t>(fourth) << 24;
    return low | next | high | top;
}

[[nodiscard]] int read_int(std::string_view bytes, std::size_t offset) noexcept {
    const std::uint32_t raw = read_u32(bytes, offset);
    const auto value = std::bit_cast<std::int32_t>(raw);
    return static_cast<int>(value);
}

[[nodiscard]] std::optional<TableHead> read_head(std::string_view bytes) noexcept {
    if (bytes.size() < kHeadBytes) return std::nullopt;
    if (read_u32(bytes, 0) != kMagic) return std::nullopt;
    TableHead head;
    head.columns = read_u32(bytes, 4);
    head.rows = read_u32(bytes, 8);
    head.strings = read_u32(bytes, 12);
    return head;
}

// Khối kiểu cột dài đúng một bản ghi vì bảng này cố định 12 cột.
[[nodiscard]] bool shape_ok(std::string_view bytes, TableHead head) noexcept {
    if (bytes.size() < kHeadBytes) return false;
    if (head.columns != kColumnCount || head.strings == 0) return false;
    const std::uint64_t records = static_cast<std::uint64_t>(head.rows) + 1;
    const std::uint64_t body = (records * kRecordBytes) + head.strings;
    return body <= (bytes.size() - kHeadBytes);
}

// Sáu kiểu đầu: INT, STRING, INT, INT, INT, STRING.
[[nodiscard]] bool front_types(std::string_view bytes) noexcept {
    bool matches = read_u32(bytes, kHeadBytes) == 0;
    matches = matches && read_u32(bytes, kHeadBytes + 4) == 2;
    matches = matches && read_u32(bytes, kHeadBytes + 8) == 0;
    matches = matches && read_u32(bytes, kHeadBytes + 12) == 0;
    matches = matches && read_u32(bytes, kHeadBytes + 16) == 0;
    matches = matches && read_u32(bytes, kHeadBytes + 20) == 2;
    return matches;
}

// Sáu kiểu sau đều là INT.
[[nodiscard]] bool back_types(std::string_view bytes) noexcept {
    bool matches = read_u32(bytes, kHeadBytes + 24) == 0;
    matches = matches && read_u32(bytes, kHeadBytes + 28) == 0;
    matches = matches && read_u32(bytes, kHeadBytes + 32) == 0;
    matches = matches && read_u32(bytes, kHeadBytes + 36) == 0;
    matches = matches && read_u32(bytes, kHeadBytes + 40) == 0;
    matches = matches && read_u32(bytes, kHeadBytes + 44) == 0;
    return matches;
}

[[nodiscard]] bool types_ok(std::string_view bytes) noexcept {
    const bool front = front_types(bytes);
    const bool back = back_types(bytes);
    return front && back;
}

// Cột chuỗi (lệch 4 và 20) không đọc: hàm tra chỉ so số nguyên.
[[nodiscard]] Gate gate_at(std::string_view bytes, std::uint32_t row) noexcept {
    const std::size_t row_at = kHeadBytes + kRecordBytes + (static_cast<std::size_t>(row) * kRecordBytes);
    Gate gate;
    gate.id = read_int(bytes, row_at);
    gate.source_scene = read_int(bytes, row_at + kSourceSceneAt);
    gate.source_x = read_int(bytes, row_at + kSourceXAt);
    gate.source_z = read_int(bytes, row_at + kSourceZAt);
    gate.dest_scene = read_int(bytes, row_at + kDestSceneAt);
    gate.dest_x = read_int(bytes, row_at + kDestXAt);
    gate.dest_z = read_int(bytes, row_at + kDestZAt);
    gate.field_nine = read_int(bytes, row_at + kFieldNineAt);
    gate.field_ten = read_int(bytes, row_at + kFieldTenAt);
    gate.field_eleven = read_int(bytes, row_at + kFieldElevenAt);
    return gate;
}

void append_row(GateList& table, std::string_view bytes, std::uint32_t row) {
    const Gate gate = gate_at(bytes, row);
    table.push_back(gate);
}

[[nodiscard]] GateList rows_of(std::string_view bytes, std::uint32_t rows) {
    GateList table;
    table.reserve(rows);
    for (std::uint32_t row = 0; row < rows; ++row)
        append_row(table, bytes, row);
    return table;
}

[[nodiscard]] int asked_scene(int scene) noexcept {
    if (scene == kLuoyangMirror) return 0;
    return scene;
}

[[nodiscard]] GateEnds asked_ends(GateEnds ends) noexcept {
    GateEnds query;
    query.source_scene = asked_scene(ends.source_scene);
    query.dest_scene = asked_scene(ends.dest_scene);
    return query;
}

[[nodiscard]] bool same_ends(const Gate& row, GateEnds query) noexcept {
    return row.source_scene == query.source_scene && row.dest_scene == query.dest_scene;
}

[[nodiscard]] const Gate* take_match(const Gate* found, const Gate& row, GateEnds query) noexcept {
    if (found != nullptr) return found;
    if (!same_ends(row, query)) return nullptr;
    return &row;
}

[[nodiscard]] const Gate* first_match(std::span<const Gate> rows, GateEnds query) noexcept {
    const Gate* found = nullptr;
    for (const Gate& row : rows)
        found = take_match(found, row, query);
    return found;
}

void remember_point(EntranceNote& note, const Gate& row) noexcept {
    note.x = row.dest_x;
    note.z = row.dest_z;
    note.count = 1;
}

void note_another(EntranceNote& note, const Gate& row) noexcept {
    const bool differs = row.dest_x != note.x || row.dest_z != note.z;
    if (differs) note.clash = true;
    ++note.count;
}

void note_row(EntranceNote& note, const Gate& row) noexcept {
    if (note.count == 0) {
        remember_point(note, row);
        return;
    }
    note_another(note, row);
}

void note_entrance(EntranceNote& note, const Gate& row, int scene) noexcept {
    if (row.dest_scene != scene) return;
    note_row(note, row);
}

[[nodiscard]] GateStand stand_from(const EntranceNote& note) noexcept {
    if (note.count == 0 || note.clash) return {};
    GateStand stand;
    stand.x = static_cast<float>(note.x);
    stand.z = static_cast<float>(note.z);
    stand.has = true;
    return stand;
}

[[nodiscard]] GateStand dest_stand(const Gate& gate) noexcept {
    GateStand stand;
    stand.x = static_cast<float>(gate.dest_x);
    stand.z = static_cast<float>(gate.dest_z);
    stand.has = true;
    return stand;
}

[[nodiscard]] GateStand linked_stand(std::span<const Gate> rows, SceneStep step) noexcept {
    if (step.previous < 0) return {};
    GateEnds ends;
    ends.source_scene = step.previous;
    ends.dest_scene = step.scene;
    const Gate* gate = find_gate(rows, ends);
    if (gate == nullptr) return {};
    return dest_stand(*gate);
}

} // namespace

GateResult read_gates(std::string_view bytes) {
    const std::optional<TableHead> head = read_head(bytes);
    if (!head) return std::unexpected(GateError::kBadMagic);
    if (!shape_ok(bytes, *head) || !types_ok(bytes)) return std::unexpected(GateError::kBadShape);
    return rows_of(bytes, head->rows);
}

const Gate* find_gate(std::span<const Gate> rows, GateEnds ends) noexcept {
    const GateEnds query = asked_ends(ends);
    if (query.source_scene == query.dest_scene) return nullptr;
    return first_match(rows, query);
}

GateStand entrance_of(std::span<const Gate> rows, int scene) noexcept {
    EntranceNote note;
    for (const Gate& row : rows)
        note_entrance(note, row, scene);
    return stand_from(note);
}

GateStand arrival_at(std::span<const Gate> rows, SceneStep step) noexcept {
    const GateStand linked = linked_stand(rows, step);
    if (linked.has) return linked;
    return entrance_of(rows, step.scene);
}

WorldPoint plan_to_world(PlanFrame frame, GameCell cell) noexcept {
    WorldPoint world;
    world.x = frame.origin_x + (frame.scale_x * cell.x);
    world.z = frame.origin_z + (frame.scale_z * cell.z);
    return world;
}

std::string_view describe(GateError error) noexcept {
    switch (error) {
    case GateError::kBadMagic: return "bảng cổng không phải DBC";
    case GateError::kBadShape: return "bảng cổng sai số cột hoặc lệch cỡ";
    }
    return "lỗi bảng cổng không rõ";
}

} // namespace game::client::map
