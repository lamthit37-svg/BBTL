#pragma once
// Thông báo hệ thống theo lịch: (1) thông báo theo khoảng ngày và theo thứ trong tuần, phát một lần mỗi
// ngày; (2) thông báo luân phiên cách đều nhau; (3) thông báo riêng cho từng người lúc vào game. Lõi thuần:
// lịch là ĐẦU VÀO của tick (WallClock do world đọc đồng hồ rồi đưa vào), lõi không đọc giờ thật.
//
// Nguồn: bảng của máy chủ XJL7457 do import_legacy.py nhập: notices_by_date.tsv (NotifyDate.txt: khoảng ngày
// yyyymmdd), notices_by_weekday.tsv (NotifyWeek.txt), notices_on_login.tsv (NotifyOnline.txt: cột is_show,
// mode), rolling_announcements.tsv (SystemInfo.ini [broadN]); nhịp luân phiên ở rules/global.toml
// [rolling_notice]. Mã 2008 không có bộ nạp các tệp này (đã grep), nên cách phát là thiết kế của lõi:
//   * Ngày: khi đồng hồ qua phút notice_daily_broadcast_minute (số tự đặt) thì phát mọi dòng theo ngày và
//     theo thứ trùng hôm nay, mỗi ngày một lần. Thứ 0 là Chủ nhật (tm_wday của C, giả định).
//   * Vào game: is_show = 0 thì bỏ; mode 0 hiện thẳng; mode 1/2 chỉ hiện khi có chữ (dòng trống trong bảng
//     là chỗ dành cho mã khác); mode 3 chỉ hiện đúng ngày sinh nhật; mode 4 là "lần đăng nhập trước" với
//     giờ và IP (8 chỗ %d), mode 5 như 4 nhưng qua máy chủ trung gian; mode khác bỏ qua.
//   * Luân phiên: mỗi rolling_interval_ms phát một dòng kế tiếp theo vòng tròn. Chỉ dòng
//     within_declared_count = 1 (nằm trong số khai báo của SystemInfo.ini) được phát; bảng thật hiện khai
//     0 dòng nên mặc định không có gì chạy - declared_only = false để phát cả mười dòng.
// Chữ trong bảng là chữ của máy chủ: giữ nguyên '#' và màu; không bao giờ ghép chữ người chơi vào.

#include "social/limits.hpp"
#include "social/types.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::social {

struct NoticeSources {
    std::string_view by_date;     // notices_by_date.tsv
    std::string_view by_weekday;  // notices_by_weekday.tsv
    std::string_view on_login;    // notices_on_login.tsv
    std::string_view rolling;     // rolling_announcements.tsv
};

struct DateNotice {
    std::int32_t begin = 0;  // yyyymmdd
    std::int32_t end = 0;
    std::string text;
};

struct WeekdayNotice {
    std::uint8_t weekday = 0;  // 0 = Chủ nhật
    std::string text;
};

struct LoginNotice {
    std::uint8_t mode = 0;
    std::string text;
};

struct RollingNotice {
    std::string text;
    bool declared = false;
};

class NoticeSchedule {
public:
    // Nạp bốn bảng (mỗi bảng có thể rỗng). Lỗi: bảng sai dạng, ngày sai, thứ ngoài 0..6, chữ quá
    // notice_max_text_bytes hay không phải UTF-8, số %d không khớp mode. Thông báo kèm số dòng.
    [[nodiscard]] static std::expected<NoticeSchedule, std::string> parse(const Limits& limits, const NoticeSources& sources);

    [[nodiscard]] const std::vector<DateNotice>& by_date() const noexcept { return by_date_; }
    [[nodiscard]] const std::vector<WeekdayNotice>& by_weekday() const noexcept { return by_weekday_; }
    [[nodiscard]] const std::vector<LoginNotice>& on_login() const noexcept { return on_login_; }
    [[nodiscard]] const std::vector<RollingNotice>& rolling() const noexcept { return rolling_; }

private:
    std::vector<DateNotice> by_date_;
    std::vector<WeekdayNotice> by_weekday_;
    std::vector<LoginNotice> on_login_;
    std::vector<RollingNotice> rolling_;
};

// Đồng hồ treo tường (giờ máy chủ) mà world đọc rồi đưa vào mỗi tick.
struct WallClock {
    std::int32_t date = 0;      // yyyymmdd
    std::uint8_t weekday = 0;   // 0 = Chủ nhật .. 6 = Thứ bảy
    std::uint16_t minute = 0;   // phút trong ngày, 0..1439
};

struct NoticeRules {
    std::int64_t rolling_interval_ms = 0;  // rules/global.toml [rolling_notice] interval; 0 = tắt luân phiên
    bool declared_only = true;
};

struct LastLogin {
    std::int32_t year = 0;
    std::int32_t month = 0;
    std::int32_t day = 0;
    std::int32_t hour = 0;
    std::array<std::uint8_t, 4> ip{};
    bool via_proxy = false;
};

struct LoginFacts {
    CharacterId who{};
    bool birthday = false;
    std::optional<LastLogin> last;
};

enum class NoticeSource : std::uint8_t {
    kDate,
    kWeekday,
    kRolling,
    kLogin,
};

struct NoticeEvent {
    NoticeSource source = NoticeSource::kDate;
    CharacterId to{};  // 0 = phát cho mọi người chơi trực tuyến, khác 0 = chỉ người này
    std::string text;
};

using NoticeEvents = std::vector<NoticeEvent>;

class NoticeBook {
public:
    NoticeBook(const Limits& limits, NoticeSchedule schedule, NoticeRules rules);

    // Mỗi tick: phát thông báo của ngày (một lần mỗi ngày) và thông báo luân phiên đến hạn.
    [[nodiscard]] NoticeEvents tick(Tick now, const WallClock& wall);

    // Thông báo riêng lúc người chơi vào game, theo thứ tự trong bảng.
    [[nodiscard]] NoticeEvents on_login(const LoginFacts& facts) const;

    // Ngày (yyyymmdd) đã phát thông báo của ngày; world lưu để khởi động lại giữa ngày không phát lại.
    [[nodiscard]] std::int32_t last_daily_date() const noexcept { return last_daily_date_; }
    void set_last_daily_date(std::int32_t date) noexcept { last_daily_date_ = date; }

    [[nodiscard]] const NoticeSchedule& schedule() const noexcept { return schedule_; }

private:
    NoticeSchedule schedule_;
    NoticeRules rules_;
    std::int64_t daily_minute_ = 0;
    TickSpan rolling_every_{};
    Tick next_rolling_{};
    bool rolling_armed_ = false;
    std::size_t rolling_cursor_ = 0;
    std::int32_t last_daily_date_ = 0;
};

} // namespace game::social
