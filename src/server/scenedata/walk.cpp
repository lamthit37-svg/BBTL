#include "scenedata/walk.hpp"

#include "core/ground_point.hpp"
#include "core/number.hpp"
#include "nav/finder.hpp"
#include "nav/mesh.hpp"
#include "scenedata/types.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <functional>
#include <optional>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::scenedata {
namespace {

constexpr std::string_view kClientSource = "client_2026_path";
constexpr std::string_view kLegacySource0859 = "legacy_nav_0859602";
constexpr std::string_view kLegacySourceXjl = "legacy_nav_xjl7457";
constexpr std::string_view kNoneSource = "none";
constexpr std::string_view kBlanks = " \t\r";
constexpr std::size_t kLegacyHeaderBytes = 4;
constexpr std::size_t kLegacyCellBytes = 4;
constexpr std::uint8_t kStateMask = 0x0FU;

[[nodiscard]] std::unexpected<LoadError> fail(std::string_view file, std::size_t line, std::string_view what) {
    std::string message(file);
    if (line != 0) message += ":" + std::to_string(line);
    message += ": " + std::string(what);
    return std::unexpected(LoadError{std::move(message)});
}

[[nodiscard]] std::string_view trim(std::string_view text) noexcept {
    const std::size_t first = text.find_first_not_of(kBlanks);
    if (first == std::string_view::npos) return {};
    return text.substr(first, text.find_last_not_of(kBlanks) - first + 1);
}

[[nodiscard]] bool valid_key(std::string_view key) noexcept {
    return !key.empty() && std::ranges::all_of(key, [](char byte) {
        return (byte >= 'a' && byte <= 'z') || (byte >= '0' && byte <= '9') || byte == '_';
    });
}

struct Value {
    bool quoted = false;
    std::string_view text;
};

// Giá trị sau dấu `=`: chuỗi trong nháy kép (không dấu gạch ngược) hoặc số nguyên có dấu trừ tuỳ chọn; sau đó
// chỉ được có khoảng trắng hoặc chú thích. nullopt khi sai dạng.
[[nodiscard]] std::optional<Value> read_value(std::string_view rest) noexcept {
    std::string_view tail;
    Value value;
    if (rest.starts_with('"')) {
        const std::size_t close = rest.find('"', 1);
        if (close == std::string_view::npos) return std::nullopt;
        value = Value{.quoted = true, .text = rest.substr(1, close - 1)};
        tail = rest.substr(close + 1);
        if (value.text.find('\\') != std::string_view::npos) return std::nullopt;
    } else {
        const std::size_t end = rest.find_first_of(" \t#");
        value = Value{.quoted = false, .text = rest.substr(0, end)};
        tail = end == std::string_view::npos ? std::string_view{} : rest.substr(end);
        const std::string_view digits = value.text.starts_with('-') ? value.text.substr(1) : value.text;
        if (digits.empty() || !std::ranges::all_of(digits, [](char byte) { return byte >= '0' && byte <= '9'; })) {
            return std::nullopt;
        }
    }
    tail = trim(tail);
    if (!tail.empty() && !tail.starts_with('#')) return std::nullopt;
    return value;
}

struct Entry {
    std::size_t line = 0;
    Value value;
};

using Found = std::vector<std::pair<std::string, Entry>>;

[[nodiscard]] const Entry* find_entry(const Found& found, std::string_view key) noexcept {
    const auto at = std::ranges::find(found, key, [](const auto& item) -> std::string_view { return item.first; });
    return at == found.end() ? nullptr : &at->second;
}

[[nodiscard]] Loaded<std::optional<std::uint32_t>> read_dimension(const Found& found, std::string_view key) {
    const Entry* const entry = find_entry(found, key);
    if (entry == nullptr) return std::optional<std::uint32_t>{};
    const std::optional<int> number = entry->value.quoted ? std::nullopt : core::parse_whole_int(entry->value.text);
    if (!number || *number < 1 || *number > 65'535) {
        return fail("scene.toml", entry->line, std::string(key) + " không phải số trong 1..65535");
    }
    return std::optional<std::uint32_t>{static_cast<std::uint32_t>(*number)};
}

[[nodiscard]] std::uint32_t le16(std::string_view bytes, std::size_t at) noexcept {
    return static_cast<std::uint32_t>(static_cast<unsigned char>(bytes[at])) |
           (static_cast<std::uint32_t>(static_cast<unsigned char>(bytes[at + 1])) << 8U);
}

struct Choice {
    WalkSource source = WalkSource::kNone;
    std::string declared;
};

[[nodiscard]] Loaded<Choice> choose_source(const Manifest& manifest, bool has_path, bool has_nav) {
    if (!manifest.walk_source) {
        if (has_path) return Choice{.source = WalkSource::kClientPath, .declared = {}};
        return Choice{.source = has_nav ? WalkSource::kLegacyNav : WalkSource::kNone, .declared = {}};
    }
    const std::string& declared = *manifest.walk_source;
    if (declared == kClientSource) {
        if (!has_path) return fail("scene.toml", 0, "walk_source = client_2026_path nhưng không có walk.path");
        return Choice{.source = WalkSource::kClientPath, .declared = declared};
    }
    if (declared == kLegacySource0859 || declared == kLegacySourceXjl) {
        if (!has_nav) return fail("scene.toml", 0, "walk_source = " + declared + " nhưng không có walk.nav");
        return Choice{.source = WalkSource::kLegacyNav, .declared = declared};
    }
    if (declared == kNoneSource) return Choice{.source = WalkSource::kNone, .declared = declared};
    return fail("scene.toml", 0, "walk_source lạ: " + declared.substr(0, 64));
}

} // namespace

std::optional<std::uint8_t> LegacyGrid::state_at(core::GroundPoint point) const noexcept {
    // Ô vuông 0,5 đơn vị gốc (0, 0): chỉ số ô là phần nguyên của toạ độ nhân đôi. So sánh dạng phủ định để
    // NaN rơi ra ngoài.
    const float cell_x = point.x * 2.0F;
    const float cell_z = point.z * 2.0F;
    if (!(cell_x >= 0.0F) || !(cell_z >= 0.0F)) return std::nullopt;
    if (!(cell_x < static_cast<float>(width)) || !(cell_z < static_cast<float>(height))) return std::nullopt;
    const auto column = static_cast<std::size_t>(cell_x);
    const auto row = static_cast<std::size_t>(cell_z);
    return state[row * width + column];
}

bool LegacyGrid::can_go(core::GroundPoint point, std::int32_t level) const noexcept {
    const std::optional<std::uint8_t> cell = state_at(point);
    return cell && std::cmp_greater_equal(level, *cell);
}

bool Walk::walkable(core::GroundPoint point, std::int32_t level) const noexcept {
    switch (source) {
    case WalkSource::kClientPath: return mesh && nav::locate(*mesh, point, nav::Ground::kOpen).has_value();
    case WalkSource::kLegacyNav: return grid && grid->can_go(point, level);
    case WalkSource::kNone: return false;
    }
    return false;
}

Loaded<Manifest> parse_manifest(std::string_view text) {
    if (text.size() > kMaxManifestBytes) return fail("scene.toml", 0, "tệp quá lớn");
    Found found;
    std::set<std::string, std::less<>> seen;
    std::size_t line_number = 0;
    for (std::size_t start = 0; start < text.size();) {
        const std::size_t end = std::min(text.find('\n', start), text.size());
        const std::string_view line = trim(text.substr(start, end - start));
        start = end + 1;
        ++line_number;
        if (line_number > kMaxManifestLines) return fail("scene.toml", 0, "quá nhiều dòng");
        if (line.empty() || line.starts_with('#')) continue;
        const std::size_t equals = line.find('=');
        const std::string_view key = equals == std::string_view::npos ? std::string_view{} : trim(line.substr(0, equals));
        if (!valid_key(key)) return fail("scene.toml", line_number, "dòng không phải `khoá = giá trị`");
        const std::optional<Value> value = read_value(trim(line.substr(equals + 1)));
        if (!value) return fail("scene.toml", line_number, "giá trị sai dạng");
        if (!seen.emplace(key).second) return fail("scene.toml", line_number, "khoá lặp: " + std::string(key));
        found.emplace_back(std::string(key), Entry{.line = line_number, .value = *value});
    }
    const Entry* const schema = find_entry(found, "schema");
    if (schema == nullptr || schema->value.quoted || schema->value.text != "1") {
        return fail("scene.toml", 0, "thiếu `schema = 1`");
    }
    Manifest manifest;
    if (const Entry* const source = find_entry(found, "walk_source"); source != nullptr) {
        if (!source->value.quoted) return fail("scene.toml", source->line, "walk_source phải là chuỗi");
        manifest.walk_source = std::string(source->value.text);
    }
    Loaded<std::optional<std::uint32_t>> width = read_dimension(found, "grid_width");
    if (!width) return std::unexpected(std::move(width.error()));
    Loaded<std::optional<std::uint32_t>> height = read_dimension(found, "grid_height");
    if (!height) return std::unexpected(std::move(height.error()));
    manifest.grid_width = *width;
    manifest.grid_height = *height;
    return manifest;
}

Loaded<LegacyGrid> parse_legacy_grid(std::string_view bytes) {
    if (bytes.size() < kLegacyHeaderBytes) return fail("walk.nav", 0, "tệp cụt, thiếu đầu tệp");
    LegacyGrid grid;
    grid.width = le16(bytes, 0);
    grid.height = le16(bytes, 2);
    if (grid.width == 0 || grid.height == 0) return fail("walk.nav", 0, "lưới rỗng");
    const std::size_t cells = static_cast<std::size_t>(grid.width) * grid.height;
    if (cells > kLegacyGridCells) return fail("walk.nav", 0, "lưới quá lớn");
    // cells <= 2^24 nên cells * 4 + 4 không tràn size_t.
    if (bytes.size() != kLegacyHeaderBytes + cells * kLegacyCellBytes) {
        return fail("walk.nav", 0, "cỡ tệp không khớp rộng * cao * 4 + 4");
    }
    grid.state.resize(cells);
    for (std::size_t cell = 0; cell < cells; ++cell) {
        // Mã 2008 đọc cả INT bốn byte vào trường bit state:4, tức bốn bit thấp của byte đầu (little-endian).
        const auto first = static_cast<std::uint8_t>(bytes[kLegacyHeaderBytes + cell * kLegacyCellBytes]);
        grid.state[cell] = static_cast<std::uint8_t>(first & kStateMask);
    }
    return grid;
}

Loaded<Walk> build_walk(const Manifest& manifest, std::optional<std::string_view> path_bytes,
    std::optional<std::string_view> nav_bytes) {
    Walk walk;
    if (path_bytes) {
        const std::span<const std::byte> raw = std::as_bytes(std::span(path_bytes->data(), path_bytes->size()));
        nav::MeshResult mesh = nav::read_mesh(raw);
        if (!mesh) return fail("walk.path", 0, nav::describe(mesh.error()));
        walk.mesh = std::move(*mesh);
    }
    if (nav_bytes) {
        Loaded<LegacyGrid> grid = parse_legacy_grid(*nav_bytes);
        if (!grid) return std::unexpected(std::move(grid.error()));
        if ((manifest.grid_width && *manifest.grid_width != grid->width) ||
            (manifest.grid_height && *manifest.grid_height != grid->height)) {
            return fail("scene.toml", 0, "grid_width / grid_height lệch với đầu walk.nav");
        }
        walk.grid = std::move(*grid);
    }
    Loaded<Choice> choice = choose_source(manifest, walk.mesh.has_value(), walk.grid.has_value());
    if (!choice) return std::unexpected(std::move(choice.error()));
    walk.source = choice->source;
    walk.declared = std::move(choice->declared);
    return walk;
}

} // namespace game::scenedata
