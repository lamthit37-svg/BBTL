/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/script/mission_data.cpp
 *  PHÂN HỆ   : Client / Giao diện / Script
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Nối quest::DefBook với tệp trên đĩa: Script.dat một lần lúc mở, tệp event
 *    theo yêu cầu.
 *  - Đường dẫn trong Script.dat là dữ liệu ngoài nên bị chặn ra khỏi
 *    Script/Config.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "ui/script/mission_data.hpp"

#include "io/file.hpp"
#include "table/tsv.hpp"

#include <cstddef>
#include <format>
#include <limits>
#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace game::ui::script {
namespace {

// Đường tương đối, không ':' và không đoạn "..": tệp event không thoát khỏi Script/Config.
[[nodiscard]] bool is_inside(std::string_view path) noexcept {
    if (path.empty() || path.front() == '/') return false;
    if (path.contains(':') || path.contains('\\')) return false;
    const bool has_up = path == ".." || path.starts_with("../") || path.contains("/../");
    return !has_up && !path.ends_with("/..");
}

// Đọc một tệp event dưới thư mục gốc của Script/Config; nullopt khi thiếu hay đường dẫn lạ.
class EventReader {
public:
    explicit EventReader(std::filesystem::path root) : root_(std::move(root)) {}

    [[nodiscard]] std::optional<std::string> operator()(std::string_view path) const {
        if (!is_inside(path)) return std::nullopt;
        const io::TextResult text = io::read_text(root_ / io::path_from_utf8(path));
        if (!text) return std::nullopt;
        return *text;
    }

private:
    std::filesystem::path root_;
};

[[nodiscard]] std::unexpected<std::string> unreadable(const std::filesystem::path& file) {
    std::string reason = std::format("không đọc được {}", file.string());
    return std::unexpected(std::move(reason));
}

} // namespace

std::expected<TrackTexts, std::string> parse_track_texts(std::string_view text) {
    auto table = table::parse_tsv(text);
    if (!table) return std::unexpected(std::move(table.error()));
    TrackTexts texts;
    constexpr std::int32_t kLast = std::numeric_limits<std::int32_t>::max();
    for (std::size_t index = 0; index < table->rows.size(); ++index) {
        table::RowReader reader(*table, index);
        const std::int32_t script = reader.integer("id", 0, kLast);
        const std::string_view line = reader.text("text");
        if (reader.error()) return std::unexpected(*reader.error());
        texts.emplace(script, std::string(line));
    }
    return texts;
}

OpenedMission open_mission_data(const std::filesystem::path& data_root) {
    const std::filesystem::path config = data_root / "Script" / "Config";
    const std::filesystem::path index_file = config / "Script.dat";
    const io::TextResult index_text = io::read_text(index_file);
    if (!index_text) return unreadable(index_file);
    std::expected<quest::ScriptIndex, std::string> index = quest::parse_script_index(*index_text);
    if (!index) return std::unexpected(std::move(index.error()));
    const std::filesystem::path track_file = data_root / "Table" / "mission_track.tsv";
    const io::TextResult track_text = io::read_text(track_file);
    if (!track_text) return unreadable(track_file);
    std::expected<TrackTexts, std::string> tracks = parse_track_texts(*track_text);
    if (!tracks) return std::unexpected(std::move(tracks.error()));
    quest::DefBook defs(std::move(*index), EventReader(config));
    return MissionData{.defs = std::move(defs), .track_texts = std::move(*tracks)};
}

} // namespace game::ui::script
