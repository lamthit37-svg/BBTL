#include "social/notice.hpp"

#include "ids/ids.hpp"
#include "social/limits.hpp"
#include "social/text.hpp"
#include "social/types.hpp"
#include "table/tsv.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <limits>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::social {
namespace {

constexpr std::uint8_t kModePlain = 0;
constexpr std::uint8_t kModeBirthday = 3;
constexpr std::uint8_t kModeLastLogin = 4;
constexpr std::uint8_t kModeLastLoginProxy = 5;
constexpr std::size_t kLastLoginFields = 8;  // năm tháng ngày giờ và bốn byte IP
constexpr std::int32_t kMinDate = 19'000'101;
constexpr std::int32_t kMaxDate = 29'991'231;

[[nodiscard]] bool plausible_date(std::int32_t date) noexcept {
    if (date < kMinDate || date > kMaxDate) return false;
    const std::int32_t month = (date / 100) % 100;
    const std::int32_t day = date % 100;
    return month >= 1 && month <= 12 && day >= 1 && day <= 31;
}

// Số chỗ "%d" của chuỗi; nullopt nếu có '%' không đi với 'd'.
[[nodiscard]] std::optional<std::size_t> count_directives(std::string_view text) noexcept {
    std::size_t count = 0;
    for (std::size_t pos = 0; pos < text.size(); ++pos) {
        if (text[pos] != '%') continue;
        if (pos + 1 >= text.size() || text[pos + 1] != 'd') return std::nullopt;
        ++count;
        ++pos;
    }
    return count;
}

// Thay lần lượt từng "%d" bằng một số. Bên gọi đã đảm bảo đúng số chỗ.
[[nodiscard]] std::string fill_directives(std::string_view text, const std::array<std::int64_t, kLastLoginFields>& values) {
    std::string out;
    std::size_t next = 0;
    for (std::size_t pos = 0; pos < text.size(); ++pos) {
        if (text[pos] == '%' && pos + 1 < text.size() && text[pos + 1] == 'd' && next < values.size()) {
            out += std::format("{}", values.at(next++));
            ++pos;
        } else {
            out.push_back(text[pos]);
        }
    }
    return out;
}

[[nodiscard]] std::expected<std::string, std::string> checked_text(const table::Tsv& sheet, std::size_t row, std::string_view column,
                                                                    std::size_t max_bytes, bool allow_empty) {
    table::RowReader reader(sheet, row);
    const std::string_view text = reader.text(column);
    if (reader.error()) return std::unexpected(*reader.error());
    if (!is_plain_text(text, max_bytes) || (text.empty() && !allow_empty)) {
        return std::unexpected(std::format("dòng {}: cột {} rỗng, quá {} byte hoặc không phải UTF-8 thường", sheet.lines[row], column, max_bytes));
    }
    return std::string{text};
}

} // namespace

std::expected<NoticeSchedule, std::string> NoticeSchedule::parse(const Limits& limits, const NoticeSources& sources) {
    NoticeSchedule schedule;
    const auto max_bytes = static_cast<std::size_t>(limits.notice_max_text_bytes);

    if (!sources.by_date.empty()) {
        const auto parsed = table::parse_tsv(sources.by_date);
        if (!parsed) return std::unexpected(std::format("notices_by_date: {}", parsed.error()));
        for (std::size_t row = 0; row < parsed->rows.size(); ++row) {
            table::RowReader reader(*parsed, row);
            const std::int32_t begin = reader.integer("begin_date", 0, std::numeric_limits<std::int32_t>::max());
            const std::int32_t end = reader.integer("end_date", 0, std::numeric_limits<std::int32_t>::max());
            if (reader.error()) return std::unexpected(*reader.error());
            if (!plausible_date(begin) || !plausible_date(end) || begin > end) {
                return std::unexpected(std::format("notices_by_date dòng {}: ngày không hợp lệ ({}..{})", parsed->lines[row], begin, end));
            }
            auto text = checked_text(*parsed, row, "info", max_bytes, false);
            if (!text) return std::unexpected(std::format("notices_by_date {}", text.error()));
            schedule.by_date_.push_back({.begin = begin, .end = end, .text = std::move(*text)});
        }
    }
    if (!sources.by_weekday.empty()) {
        const auto parsed = table::parse_tsv(sources.by_weekday);
        if (!parsed) return std::unexpected(std::format("notices_by_weekday: {}", parsed.error()));
        for (std::size_t row = 0; row < parsed->rows.size(); ++row) {
            table::RowReader reader(*parsed, row);
            const std::uint32_t weekday = reader.number("week", 0, 6);
            if (reader.error()) return std::unexpected(*reader.error());
            auto text = checked_text(*parsed, row, "info", max_bytes, false);
            if (!text) return std::unexpected(std::format("notices_by_weekday {}", text.error()));
            schedule.by_weekday_.push_back({.weekday = static_cast<std::uint8_t>(weekday), .text = std::move(*text)});
        }
    }
    if (!sources.on_login.empty()) {
        const auto parsed = table::parse_tsv(sources.on_login);
        if (!parsed) return std::unexpected(std::format("notices_on_login: {}", parsed.error()));
        for (std::size_t row = 0; row < parsed->rows.size(); ++row) {
            table::RowReader reader(*parsed, row);
            const bool shown = reader.flag("is_show");
            const std::uint32_t mode = reader.number("mode", 0, 255);
            if (reader.error()) return std::unexpected(*reader.error());
            auto text = checked_text(*parsed, row, "info", max_bytes, true);
            if (!text) return std::unexpected(std::format("notices_on_login {}", text.error()));
            if (!shown) continue;
            if (mode == kModeLastLogin || mode == kModeLastLoginProxy) {
                if (count_directives(*text) != kLastLoginFields) {
                    return std::unexpected(std::format("notices_on_login dòng {}: mode {} cần đúng {} chỗ %d và không có '%' nào khác",
                                                       parsed->lines[row], mode, kLastLoginFields));
                }
            }
            schedule.on_login_.push_back({.mode = static_cast<std::uint8_t>(mode), .text = std::move(*text)});
        }
    }
    if (!sources.rolling.empty()) {
        const auto parsed = table::parse_tsv(sources.rolling);
        if (!parsed) return std::unexpected(std::format("rolling_announcements: {}", parsed.error()));
        for (std::size_t row = 0; row < parsed->rows.size(); ++row) {
            table::RowReader reader(*parsed, row);
            const bool declared = reader.flag("within_declared_count");
            if (reader.error()) return std::unexpected(*reader.error());
            auto text = checked_text(*parsed, row, "contex", max_bytes, false);
            if (!text) return std::unexpected(std::format("rolling_announcements {}", text.error()));
            schedule.rolling_.push_back({.text = std::move(*text), .declared = declared});
        }
    }
    return schedule;
}

NoticeBook::NoticeBook(const Limits& limits, NoticeSchedule schedule, NoticeRules rules)
    : schedule_(std::move(schedule)),
      rules_(rules),
      daily_minute_(limits.notice_daily_broadcast_minute),
      rolling_every_(millis_to_ticks(rules.rolling_interval_ms)) {}

NoticeEvents NoticeBook::tick(Tick now, const WallClock& wall) {
    NoticeEvents events;
    if (wall.date > 0 && wall.date != last_daily_date_ && std::cmp_greater_equal(wall.minute, daily_minute_)) {
        last_daily_date_ = wall.date;
        for (const DateNotice& notice : schedule_.by_date()) {
            if (notice.begin <= wall.date && wall.date <= notice.end) events.push_back({.source = NoticeSource::kDate, .text = notice.text});
        }
        for (const WeekdayNotice& notice : schedule_.by_weekday()) {
            if (notice.weekday == wall.weekday) events.push_back({.source = NoticeSource::kWeekday, .text = notice.text});
        }
    }
    if (rolling_every_.count <= 0) return events;
    if (!rolling_armed_) {
        rolling_armed_ = true;
        next_rolling_ = ids::advance(now, rolling_every_);
        return events;
    }
    if (now < next_rolling_) return events;
    // Chọn dòng đủ điều kiện kế tiếp theo vòng tròn; không có dòng nào thì chỉ dời hạn.
    const auto& rows = schedule_.rolling();
    for (std::size_t tried = 0; tried < rows.size(); ++tried) {
        const RollingNotice& row = rows[rolling_cursor_ % rows.size()];
        rolling_cursor_ = (rolling_cursor_ + 1) % rows.size();
        if (rules_.declared_only && !row.declared) continue;
        events.push_back({.source = NoticeSource::kRolling, .text = row.text});
        break;
    }
    next_rolling_ = ids::advance(now, rolling_every_);
    return events;
}

NoticeEvents NoticeBook::on_login(const LoginFacts& facts) const {
    NoticeEvents events;
    for (const LoginNotice& notice : schedule_.on_login()) {
        std::string text;
        switch (notice.mode) {
        case kModePlain: text = notice.text; break;
        case kModeBirthday:
            if (!facts.birthday) continue;
            text = notice.text;
            break;
        case kModeLastLogin:
        case kModeLastLoginProxy: {
            if (!facts.last || facts.last->via_proxy != (notice.mode == kModeLastLoginProxy)) continue;
            const LastLogin& last = *facts.last;
            text = fill_directives(notice.text, {last.year, last.month, last.day, last.hour, last.ip[0], last.ip[1], last.ip[2], last.ip[3]});
            break;
        }
        default:
            // Mode 1, 2 và mode lạ: chỉ hiện khi bảng có chữ (dòng trống là chỗ dành cho mã khác).
            if (notice.mode > 2) continue;
            text = notice.text;
            break;
        }
        if (text.empty()) continue;
        events.push_back({.source = NoticeSource::kLogin, .to = facts.who, .text = std::move(text)});
    }
    return events;
}

} // namespace game::social
