// Thông báo theo lịch: nạp bốn bảng, phát theo ngày một lần, luân phiên cách đều, thông báo lúc vào game. Sai thì
// thông báo phát lặp mỗi tick hoặc không bao giờ phát (hỏng thầm), nên mỗi ca nêu ngày giờ và danh sách mong đợi.
#include "ids/ids.hpp"
#include "social/notice.hpp"
#include "social/types.hpp"
#include "social_support.hpp"
#include "test.hpp"

#include <array>
#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using social::LastLogin;
using social::NoticeBook;
using social::NoticeEvent;
using social::NoticeEvents;
using social::NoticeSchedule;
using social::NoticeSource;
using social::NoticeSources;
using social::Tick;
using social::WallClock;

constexpr std::string_view kDates =
    "# schema 1\nindex\tbegin_date\tend_date\tinfo\n"
    "0\t20261014\t20261016\tba ngày\n"
    "1\t20261016\t20261016\thôm nay là 16\n"
    "2\t20261201\t20261201\tmột ngày\n";

constexpr std::string_view kWeekdays =
    "# schema 1\nindex\tweek\tinfo\n"
    "0\t3\tthứ tư vui vẻ\n"
    "1\t0\tchủ nhật nghỉ ngơi\n";

constexpr std::string_view kLogins =
    "# schema 1\nindex\tis_show\tmode\tinfo\n"
    "0\t1\t0\tchào mừng\n"
    "1\t1\t4\tlần trước %d-%d-%d giờ %d từ %d.%d.%d.%d\n"
    "2\t0\t0\tẩn\n"
    "3\t1\t1\t\n"
    "4\t1\t3\tsinh nhật vui vẻ\n"
    "5\t1\t5\tqua proxy %d-%d-%d giờ %d từ %d.%d.%d.%d\n"
    "6\t1\t2\tmode hai có chữ\n"
    "7\t1\t9\tmode lạ\n"
    "8\t1\t1\tmode một có chữ\n";

constexpr std::string_view kRolling =
    "# schema 1\nannouncement_id\tcontex\twithin_declared_count\n"
    "0\tA\t1\n"
    "1\tB\t0\n"
    "2\tC\t1\n";

NoticeSources all_sources() { return {.by_date = kDates, .by_weekday = kWeekdays, .on_login = kLogins, .rolling = kRolling}; }

// Dựng sổ từ bốn bảng mẫu; trả nullptr kèm kỳ vọng sai nếu bảng mẫu không nạp được.
NoticeSchedule schedule_of(Context& context, const NoticeSources& sources) {
    auto parsed = NoticeSchedule::parse(sample_limits(), sources);
    context.expect(parsed.has_value(), "bảng mẫu nạp được");
    if (!parsed) return NoticeSchedule{};
    return std::move(*parsed);
}

std::vector<std::string> texts_of(const NoticeEvents& events) {
    std::vector<std::string> out;
    out.reserve(events.size());
    for (const NoticeEvent& event : events) out.push_back(event.text);
    return out;
}

WallClock clock_at(std::int32_t date, std::uint8_t weekday, std::uint16_t minute) { return {.date = date, .weekday = weekday, .minute = minute}; }

void parsing(Context& context) {
    const NoticeSchedule schedule = schedule_of(context, all_sources());
    context.expect(schedule.by_date().size() == 3 && schedule.by_weekday().size() == 2, "số dòng ngày và thứ");
    // Dòng is_show = 0 bị bỏ: 9 dòng bảng, 1 dòng ẩn.
    context.expect(schedule.on_login().size() == 8 && schedule.rolling().size() == 3, "dòng ẩn bị bỏ khi nạp");
    context.expect(schedule.by_date()[0].begin == 20261014 && schedule.by_date()[0].end == 20261016 && schedule.by_date()[0].text == "ba ngày", "khoảng ngày đọc đúng");
    context.expect(schedule.by_weekday()[0].weekday == 3 && schedule.rolling()[0].declared && !schedule.rolling()[1].declared, "thứ và cờ khai báo");
    const NoticeSchedule empty = schedule_of(context, {});
    context.expect(empty.by_date().empty() && empty.on_login().empty() && empty.rolling().empty(), "không có bảng nào: lịch rỗng");
}

void rejects_bad_tables(Context& context) {
    const auto rejects = [&context](const NoticeSources& sources, std::string_view why) {
        context.expect(!NoticeSchedule::parse(sample_limits(), sources).has_value(), why);
    };
    constexpr std::string_view kDateHead = "# schema 1\nindex\tbegin_date\tend_date\tinfo\n";
    rejects({.by_date = "# schema 1\nindex\tbegin_date\tend_date\tinfo\n0\t20261301\t20261302\tx\n", .by_weekday = {}, .on_login = {}, .rolling = {}}, "tháng 13");
    rejects({.by_date = "# schema 1\nindex\tbegin_date\tend_date\tinfo\n0\t20261020\t20261010\tx\n", .by_weekday = {}, .on_login = {}, .rolling = {}}, "ngày đầu sau ngày cuối");
    rejects({.by_date = "# schema 1\nindex\tbegin_date\tend_date\tinfo\n0\t20260100\t20260110\tx\n", .by_weekday = {}, .on_login = {}, .rolling = {}}, "ngày 0");
    rejects({.by_date = "# schema 1\nindex\tbegin_date\tend_date\tinfo\n0\t100\t200\tx\n", .by_weekday = {}, .on_login = {}, .rolling = {}}, "ngày quá nhỏ");
    rejects({.by_date = "# schema 1\nindex\tbegin_date\tend_date\tinfo\n0\t20261010\t20261012\t\n", .by_weekday = {}, .on_login = {}, .rolling = {}}, "chữ rỗng ở bảng ngày");
    rejects({.by_date = "# schema 1\nindex\tbegin_date\tend_date\tinfo\n0\t20261010\tabc\tx\n", .by_weekday = {}, .on_login = {}, .rolling = {}}, "ngày không phải số");
    const std::string utf8 = std::string{kDateHead} + "0\t20261010\t20261012\t\xff\xfe\n";
    rejects({.by_date = utf8, .by_weekday = {}, .on_login = {}, .rolling = {}}, "chữ UTF-8 hỏng");
    const std::string long_text = std::string{kDateHead} + "0\t20261010\t20261012\t" + std::string(1025, 'a') + "\n";
    rejects({.by_date = long_text, .by_weekday = {}, .on_login = {}, .rolling = {}}, "chữ quá notice_max_text_bytes");
    const std::string exact = std::string{kDateHead} + "0\t20261010\t20261012\t" + std::string(1024, 'a') + "\n";
    context.expect(NoticeSchedule::parse(sample_limits(), {.by_date = exact, .by_weekday = {}, .on_login = {}, .rolling = {}}).has_value(), "chữ đúng 1024 byte qua");
    rejects({.by_date = {}, .by_weekday = "# schema 1\nindex\tweek\tinfo\n0\t7\tx\n", .on_login = {}, .rolling = {}}, "thứ 7");
    rejects({.by_date = {}, .by_weekday = "# schema 1\nindex\tweek\tinfo\n0\t-1\tx\n", .on_login = {}, .rolling = {}}, "thứ âm");
    rejects({.by_date = {}, .by_weekday = "# schema 1\nindex\tinfo\n0\tx\n", .on_login = {}, .rolling = {}}, "thiếu cột week");
    rejects({.by_date = {}, .by_weekday = {}, .on_login = "# schema 1\nindex\tis_show\tmode\tinfo\n0\t2\t0\tx\n", .rolling = {}}, "is_show ngoài 0..1");
    rejects({.by_date = {}, .by_weekday = {}, .on_login = "# schema 1\nindex\tis_show\tmode\tinfo\n0\t1\t256\tx\n", .rolling = {}}, "mode ngoài 0..255");
    rejects({.by_date = {}, .by_weekday = {}, .on_login = "# schema 1\nindex\tis_show\tmode\tinfo\n0\t1\t4\tchỉ 7 chỗ %d %d %d %d %d %d %d\n", .rolling = {}}, "mode 4 thiếu một %d");
    rejects({.by_date = {}, .by_weekday = {}, .on_login = "# schema 1\nindex\tis_show\tmode\tinfo\n0\t1\t4\ttới 9 chỗ %d %d %d %d %d %d %d %d %d\n", .rolling = {}}, "mode 4 thừa một %d");
    rejects({.by_date = {}, .by_weekday = {}, .on_login = "# schema 1\nindex\tis_show\tmode\tinfo\n0\t1\t5\t%d %d %d %d %d %d %d %s\n", .rolling = {}}, "mode 5 có %s");
    rejects({.by_date = {}, .by_weekday = {}, .on_login = "# schema 1\nindex\tis_show\tmode\tinfo\n0\t1\t4\t100% %d %d %d %d %d %d %d %d\n", .rolling = {}}, "mode 4 có % lẻ");
    // Dòng ẩn không bị kiểm số %d (không bao giờ hiện), nhưng vẫn phải là chữ hợp lệ.
    context.expect(NoticeSchedule::parse(sample_limits(), {.by_date = {}, .by_weekday = {}, .on_login = "# schema 1\nindex\tis_show\tmode\tinfo\n0\t0\t4\tẩn %d\n", .rolling = {}}).has_value(), "dòng ẩn qua");
    rejects({.by_date = {}, .by_weekday = {}, .on_login = {}, .rolling = "# schema 1\nannouncement_id\twithin_declared_count\n0\t1\n"}, "thiếu cột contex");
    rejects({.by_date = {}, .by_weekday = {}, .on_login = {}, .rolling = "# schema 1\nannouncement_id\tcontex\twithin_declared_count\n0\t\t1\n"}, "chữ luân phiên rỗng");
    rejects({.by_date = "# schema 1\nindex\tbegin_date\tend_date\tinfo\n0\t20261010\n", .by_weekday = {}, .on_login = {}, .rolling = {}}, "dòng thiếu ô");
}

void daily_broadcast(Context& context) {
    NoticeBook book(sample_limits(), schedule_of(context, {.by_date = kDates, .by_weekday = kWeekdays, .on_login = {}, .rolling = {}}), {});
    // 2026-10-14 là thứ tư (3). Trước 08:00 chưa phát.
    context.expect(book.tick(Tick{1}, clock_at(20261014, 3, 479)).empty(), "07:59 chưa phát");
    const NoticeEvents first = book.tick(Tick{2}, clock_at(20261014, 3, 480));
    context.expect(texts_of(first) == std::vector<std::string>{"ba ngày", "thứ tư vui vẻ"}, "08:00: dòng theo ngày rồi dòng theo thứ");
    context.expect(first.size() == 2 && first[0].source == NoticeSource::kDate && first[1].source == NoticeSource::kWeekday && first[0].to == social::CharacterId{} && first[1].to == social::CharacterId{},
                   "nguồn đúng, gửi cho mọi người (to = 0)");
    context.expect(book.last_daily_date() == 20261014, "ghi nhận ngày đã phát");
    context.expect(book.tick(Tick{3}, clock_at(20261014, 3, 481)).empty() && book.tick(Tick{4}, clock_at(20261014, 3, 1439)).empty(), "cùng ngày không phát lại");
    // Qua nửa đêm sang 10-15 (thứ năm): chưa tới 08:00 nên chưa phát; ngày 15 còn trong khoảng "ba ngày".
    context.expect(book.tick(Tick{5}, clock_at(20261015, 4, 0)).empty(), "00:00 ngày mới chưa phát");
    context.expect(texts_of(book.tick(Tick{6}, clock_at(20261015, 4, 480))) == std::vector<std::string>{"ba ngày"}, "ngày 15: chỉ dòng khoảng ngày (thứ năm không có dòng)");
    // Ngày 16 có hai dòng trùng ngày: cả hai phát, theo thứ tự bảng.
    context.expect(texts_of(book.tick(Tick{7}, clock_at(20261016, 5, 700))) == std::vector<std::string>{"ba ngày", "hôm nay là 16"}, "hai khoảng ngày cùng chứa hôm nay");
    // Ngày ngoài mọi khoảng nhưng đúng chủ nhật: chỉ dòng theo thứ.
    context.expect(texts_of(book.tick(Tick{8}, clock_at(20261018, 0, 480))) == std::vector<std::string>{"chủ nhật nghỉ ngơi"}, "chủ nhật");
    // Ngày không có dòng nào: không sự kiện nhưng vẫn ghi nhận đã xét.
    context.expect(book.tick(Tick{9}, clock_at(20261019, 1, 480)).empty() && book.last_daily_date() == 20261019, "ngày trống");
    // Đồng hồ hỏng (ngày 0) thì không phát và không ghi nhận.
    context.expect(book.tick(Tick{10}, clock_at(0, 3, 900)).empty() && book.last_daily_date() == 20261019, "ngày 0 bị bỏ qua");
    // Ngày 1 tháng 12 đúng một ngày.
    context.expect(texts_of(book.tick(Tick{11}, clock_at(20261201, 2, 480))) == std::vector<std::string>{"một ngày"}, "khoảng ngày một ngày");
}

void restart_does_not_repeat(Context& context) {
    NoticeBook book(sample_limits(), schedule_of(context, {.by_date = kDates, .by_weekday = kWeekdays, .on_login = {}, .rolling = {}}), {});
    // World khởi động lại lúc 09:00 sau khi đã phát ở 08:00: ngày đã lưu thì không phát lại.
    book.set_last_daily_date(20261014);
    context.expect(book.tick(Tick{1}, clock_at(20261014, 3, 540)).empty(), "đã phát hôm nay (theo sổ lưu): không phát lại");
    // Khởi động lúc 09:00 mà chưa phát hôm nay (sổ lưu ngày hôm qua): phát ngay ở tick đầu.
    NoticeBook late(sample_limits(), schedule_of(context, {.by_date = kDates, .by_weekday = kWeekdays, .on_login = {}, .rolling = {}}), {});
    late.set_last_daily_date(20261013);
    context.expect(late.tick(Tick{1}, clock_at(20261014, 3, 540)).size() == 2, "chưa phát hôm nay: phát bù ngay khi qua giờ");
}

void rolling(Context& context) {
    const NoticeSources only_rolling{.by_date = {}, .by_weekday = {}, .on_login = {}, .rolling = kRolling};
    constexpr std::uint64_t kEvery = 1200;  // 60 000 ms, 20 tick mỗi giây
    NoticeBook book(sample_limits(), schedule_of(context, only_rolling), {.rolling_interval_ms = 60'000, .declared_only = true});
    const WallClock no_clock{};
    context.expect(book.tick(Tick{100}, no_clock).empty(), "tick đầu chỉ lên dây");
    context.expect(book.tick(Tick{100 + kEvery - 1}, no_clock).empty(), "chưa đến hạn");
    context.expect(texts_of(book.tick(Tick{100 + kEvery}, no_clock)) == std::vector<std::string>{"A"}, "đến hạn: dòng khai báo đầu tiên");
    context.expect(texts_of(book.tick(Tick{100 + (2 * kEvery)}, no_clock)) == std::vector<std::string>{"C"}, "dòng B (không khai báo) bị bỏ qua");
    context.expect(texts_of(book.tick(Tick{100 + (3 * kEvery)}, no_clock)) == std::vector<std::string>{"A"}, "vòng lại từ đầu");
    // Bỏ lỡ nhiều nhịp (tick nhảy xa): chỉ phát một dòng, không dồn bù.
    const NoticeEvents jump = book.tick(Tick{100 + (50 * kEvery)}, no_clock);
    context.expect(jump.size() == 1 && jump[0].source == NoticeSource::kRolling, "nhảy xa vẫn một dòng");
    context.expect(book.tick(Tick{100 + (50 * kEvery) + 1}, no_clock).empty(), "hạn kế tính từ lúc phát");

    NoticeBook all(sample_limits(), schedule_of(context, only_rolling), {.rolling_interval_ms = 60'000, .declared_only = false});
    static_cast<void>(all.tick(Tick{0}, no_clock));
    std::string order;
    for (std::uint64_t round = 1; round <= 4; ++round) {
        for (const NoticeEvent& event : all.tick(Tick{round * kEvery}, no_clock)) order += event.text;
    }
    context.expect(order == "ABCA", "declared_only = false: phát cả ba dòng theo vòng");

    NoticeBook off(sample_limits(), schedule_of(context, only_rolling), {.rolling_interval_ms = 0, .declared_only = false});
    context.expect(off.tick(Tick{0}, no_clock).empty() && off.tick(Tick{1'000'000}, no_clock).empty(), "interval 0: tắt luân phiên");

    constexpr std::string_view kUndeclared = "# schema 1\nannouncement_id\tcontex\twithin_declared_count\n0\tB\t0\n";
    NoticeBook none(sample_limits(), schedule_of(context, {.by_date = {}, .by_weekday = {}, .on_login = {}, .rolling = kUndeclared}), {.rolling_interval_ms = 60'000, .declared_only = true});
    static_cast<void>(none.tick(Tick{0}, no_clock));
    context.expect(none.tick(Tick{kEvery}, no_clock).empty() && none.tick(Tick{kEvery + 1}, no_clock).empty(), "không dòng nào đủ điều kiện: không phát và không treo");
    NoticeBook blank(sample_limits(), schedule_of(context, {}), {.rolling_interval_ms = 60'000, .declared_only = false});
    static_cast<void>(blank.tick(Tick{0}, no_clock));
    context.expect(blank.tick(Tick{kEvery}, no_clock).empty(), "không có dòng luân phiên nào");
}

void login_notices(Context& context) {
    const NoticeBook book(sample_limits(), schedule_of(context, {.by_date = {}, .by_weekday = {}, .on_login = kLogins, .rolling = {}}), {});
    // Người thường, chưa có lần đăng nhập trước, không sinh nhật: dòng mode 0, mode 1/2 có chữ.
    const NoticeEvents plain = book.on_login({.who = cid(42), .birthday = false, .last = std::nullopt});
    context.expect(texts_of(plain) == std::vector<std::string>{"chào mừng", "mode hai có chữ", "mode một có chữ"}, "mode 0, mode 2 và mode 1 có chữ; mode 1 trống, mode 9, mode 3/4/5 bỏ qua");
    bool all_to_player = !plain.empty();
    for (const NoticeEvent& event : plain) all_to_player = all_to_player && event.to == cid(42) && event.source == NoticeSource::kLogin;
    context.expect(all_to_player, "mọi dòng gửi riêng cho người vào");

    const NoticeEvents birthday = book.on_login({.who = cid(42), .birthday = true, .last = std::nullopt});
    context.expect(texts_of(birthday) == std::vector<std::string>{"chào mừng", "sinh nhật vui vẻ", "mode hai có chữ", "mode một có chữ"}, "sinh nhật: thêm dòng mode 3 đúng vị trí bảng");

    const LastLogin direct{.year = 2026, .month = 10, .day = 13, .hour = 21, .ip = {10, 0, 3, 255}, .via_proxy = false};
    const NoticeEvents with_last = book.on_login({.who = cid(1), .birthday = false, .last = direct});
    context.expect(texts_of(with_last) == std::vector<std::string>{"chào mừng", "lần trước 2026-10-13 giờ 21 từ 10.0.3.255", "mode hai có chữ", "mode một có chữ"}, "mode 4: điền 8 số, không dùng dòng proxy");
    const LastLogin proxied{.year = 2026, .month = 1, .day = 2, .hour = 3, .ip = {1, 2, 3, 4}, .via_proxy = true};
    const NoticeEvents with_proxy = book.on_login({.who = cid(1), .birthday = false, .last = proxied});
    context.expect(texts_of(with_proxy) == std::vector<std::string>{"chào mừng", "qua proxy 2026-1-2 giờ 3 từ 1.2.3.4", "mode hai có chữ", "mode một có chữ"}, "mode 5: chỉ khi qua proxy");

    // Không còn dòng nào hiển thị: danh sách rỗng, không lỗi.
    const NoticeBook empty(sample_limits(), schedule_of(context, {}), {});
    context.expect(empty.on_login({.who = cid(1), .birthday = true, .last = direct}).empty(), "lịch rỗng: không có thông báo vào game");
}

constexpr std::array kCases{
    Case{.name = "parsing", .body = parsing},
    Case{.name = "rejects_bad_tables", .body = rejects_bad_tables},
    Case{.name = "daily_broadcast", .body = daily_broadcast},
    Case{.name = "restart_does_not_repeat", .body = restart_does_not_repeat},
    Case{.name = "rolling", .body = rolling},
    Case{.name = "login_notices", .body = login_notices},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
