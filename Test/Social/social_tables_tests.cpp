// Bảng thật của lõi xã hội: đọc dev/server/tables rồi nạp qua đúng bộ nạp mà world dùng. Sai ở đây nghĩa là bảng và
// mã lệch nhau (thiếu khoá, đổi tên cột, số ngoài miền) và world sẽ không khởi động được, nên test đọc từng bảng
// thật và đối chiếu vài số vàng đọc tay từ tệp nguồn. Bảng ở thư mục shared/ không vào git (xuất từ client 2026),
// thiếu thì ca tương ứng tự bỏ qua và nói rõ.
#include "social/chat.hpp"
#include "social/city.hpp"
#include "social/guild.hpp"
#include "social/limits.hpp"
#include "social/notice.hpp"
#include "social/rank.hpp"
#include "social/relation.hpp"
#include "social/types.hpp"
#include "social/wordfilter.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdio>
#include <fstream>
#include <ios>
#include <iterator>
#include <optional>
#include <sstream>
#include <string>
#include <string_view>


namespace game::test {
namespace {

using social::ChannelId;
using social::ChannelRole;
using social::ChatCatalog;
using social::CityCatalog;
using social::CityId;
using social::NameKind;
using social::WordFilter;

// Thư mục bảng do cmake/server/social.tests.cmake gắn vào lúc dựng; không có thì mọi ca tự bỏ qua.
#ifdef GAME_SERVER_TABLES
constexpr std::string_view kTablesRoot = GAME_SERVER_TABLES;

bool tables_available() { return true; }
#else
constexpr std::string_view kTablesRoot{};

bool tables_available() {
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg): in thông báo bỏ qua như test.hpp
    static_cast<void>(std::fprintf(stderr, "[bỏ qua] dựng không có GAME_SERVER_TABLES\n"));
    return false;
}
#endif

std::optional<std::string> read_table(std::string_view relative) {
    std::ifstream file(std::string{kTablesRoot} + "/" + std::string{relative}, std::ios::binary);
    if (!file) return std::nullopt;
    return std::string{std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>()};
}

// Số dòng dữ liệu của bảng: bỏ dòng chú thích '#', dòng trống và dòng tên cột.
std::size_t data_rows(const std::string& tsv) {
    std::istringstream stream(tsv);
    std::string line;
    std::size_t rows = 0;
    bool header_seen = false;
    while (std::getline(stream, line)) {
        if (line.empty() || line.front() == '#') continue;
        if (!header_seen) {
            header_seen = true;
            continue;
        }
        ++rows;
    }
    return rows;
}

// Số dòng dữ liệu có ô `column` (đếm từ 0) bằng `wanted`.
std::size_t rows_with(const std::string& tsv, std::size_t column, std::string_view wanted) {
    std::istringstream stream(tsv);
    std::string line;
    std::size_t rows = 0;
    bool header_seen = false;
    while (std::getline(stream, line)) {
        if (line.empty() || line.front() == '#') continue;
        if (!header_seen) {
            header_seen = true;
            continue;
        }
        std::istringstream cells(line);
        std::string cell;
        for (std::size_t index = 0; std::getline(cells, cell, '\t'); ++index) {
            if (index == column) {
                if (cell == wanted) ++rows;
                break;
            }
        }
    }
    return rows;
}

// Trả bảng, hoặc in lý do bỏ qua và trả nullopt (bảng của client không vào git).
std::optional<std::string> shared_or_skip(std::string_view name) {
    auto table = read_table("shared/" + std::string{name});
    if (!table) {
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg): in thông báo bỏ qua như test.hpp
        static_cast<void>(std::fprintf(stderr, "[bỏ qua] thiếu dev/server/tables/shared/%.*s (bảng client không vào git)\n", static_cast<int>(name.size()), name.data()));
    }
    return table;
}

std::optional<social::Limits> real_limits(Context& context) {
    const auto text = read_table("server/social_limits.tsv");
    context.expect(text.has_value(), "social_limits.tsv có trong kho");
    if (!text) return std::nullopt;
    auto limits = social::parse_limits(*text);
    context.expect(limits.has_value(), "social_limits.tsv nạp được");
    if (!limits) {
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg): in lý do nạp hỏng để người đọc thấy ngay dòng sai
        static_cast<void>(std::fprintf(stderr, "%s\n", limits.error().c_str()));
        return std::nullopt;
    }
    return *limits;
}

void limits_table(Context& context) {
    if (!tables_available()) return;
    const auto text = read_table("server/social_limits.tsv");
    const auto limits = real_limits(context);
    if (!text || !limits) return;
    context.expect(data_rows(*text) == social::limits_key_count(), "bảng có đúng mỗi khoá một dòng, không dòng thừa");
    // Số vàng đọc tay từ nguồn: 2008 MAX_TEAM_MEMBER = 6, MAX_FRIEND_COUNT = 80; client 2026 hộp thư 15 thư.
    context.expect(limits->team_max_members == 6 && limits->relation_max_friends == 80 && limits->mail_inbox_cap == 15, "ba số có nguồn 2008 và client");
    // Mọi dòng khai nguồn thuộc một trong ba loại; số tự đặt đếm riêng để chủ dự án duyệt.
    const std::size_t total = data_rows(*text);
    const std::size_t known = rows_with(*text, 2, "source_2008") + rows_with(*text, 2, "client_2026") + rows_with(*text, 2, "made_up");
    context.expect(known == total, "cột basis chỉ có source_2008, client_2026 hoặc made_up");
    context.expect(rows_with(*text, 2, "made_up") > 0, "có số tự đặt được khai là made_up");
    // Giới hạn thật đủ cho các hằng của lõi: một sổ xếp hạng mặc định dựng được.
    social::RankBook rank(*limits);
    context.expect(rank.define(social::Tick{0}, {.id = social::BoardId{1}, .name = "t", .capacity = 0}).has_value(), "sổ xếp hạng dựng được với giới hạn thật");
}

void chat_channels_table(Context& context) {
    if (!tables_available()) return;
    const auto text = shared_or_skip("chat_channels.tsv");
    if (!text) return;
    const auto catalog = ChatCatalog::parse(*text);
    context.expect(catalog.has_value(), "chat_channels.tsv nạp được");
    if (!catalog) return;
    context.expect(catalog->channels().size() == data_rows(*text), "mỗi dòng bảng thành một kênh");
    const social::ChatChannelInfo* world = catalog->find(ChannelId{2});
    context.expect(world != nullptr && world->role == ChannelRole::kWorld && world->level_limit == 15 && world->costs.size() == 2 &&
                       world->interval.count == 3600,
                   "kênh thế giới: cấp 15, hai khoản phí, giãn cách 180 giây (3600 tick)");
    const social::ChatChannelInfo* nearby = catalog->find(ChannelId{0});
    context.expect(nearby != nullptr && nearby->role == ChannelRole::kNearby && nearby->interval.count == 60 && nearby->costs.empty(), "kênh lân cận: 3 giây (60 tick), miễn phí");
}

void city_tables(Context& context) {
    if (!tables_available()) return;
    const auto cities = shared_or_skip("guild_cities.tsv");
    const auto buildings = shared_or_skip("city_buildings.tsv");
    if (!cities || !buildings) return;
    const auto catalog = CityCatalog::parse({.cities_tsv = *cities, .buildings_tsv = *buildings});
    context.expect(catalog.has_value(), "bảng thành phố và công trình nạp được");
    if (!catalog) {
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg): in lý do nạp hỏng
        static_cast<void>(std::fprintf(stderr, "%s\n", catalog.error().c_str()));
        return;
    }
    context.expect(catalog->size() == data_rows(*cities), "mỗi dòng bảng thành một thành phố");
    context.expect(catalog->building_count() <= data_rows(*buildings) && catalog->building_count() > 0, "có công trình, không nhiều hơn số dòng bảng");
    const social::CityInfo* first = catalog->find(CityId{1});
    // Thành 1 = 雁南正南, cảnh 205 (dòng đầu guild_cities.tsv).
    context.expect(first != nullptr && first->scene == 205, "thành 1 ở cảnh 205");
}

void mentor_and_war_tables(Context& context) {
    if (!tables_available()) return;
    const auto rewards = read_table("server/mentor_exp_rewards.tsv");
    const auto share = shared_or_skip("mentor_exp_share.tsv");
    const auto war = read_table("server/guild_war_points.tsv");
    context.expect(rewards.has_value() && war.has_value(), "bảng thưởng sư đồ và điểm bang chiến có trong kho");
    if (rewards && share) {
        const auto table = social::MentorTable::parse({.rewards_tsv = *rewards, .share_tsv = *share});
        context.expect(table.has_value(), "bảng thưởng và hệ số sư đồ nạp được");
        // Hàng đầu của MasterExpBounty: đồ đệ cấp 30 thưởng 250000 kinh nghiệm khi không cùng bang.
        context.expect(table.has_value() && table->rewards().front().apprentice_level == 30 && table->rewards().front().exp_no_guild == 250'000,
                       "hàng thưởng đầu: cấp 30, 250000");
    }
    if (war) {
        const auto points = social::WarPointTable::parse(*war);
        context.expect(points.has_value() && points->size() == data_rows(*war), "bảng điểm bang chiến nạp được, mỗi dòng một mã");
        // GuildWarPoint.txt: mã 0 (giết một thành viên đối phương) 3 điểm, mã 2 (phá một tháp) 50 điểm.
        context.expect(points.has_value() && points->points_for(0) == 3 && points->points_for(2) == 50 && points->points_for(999'999) == 0, "điểm của mã 0, 2 và mã lạ");
    }
}

void notice_tables(Context& context) {
    if (!tables_available()) return;
    const auto limits = real_limits(context);
    const auto by_date = read_table("server/notices_by_date.tsv");
    const auto by_weekday = read_table("server/notices_by_weekday.tsv");
    const auto on_login = read_table("server/notices_on_login.tsv");
    const auto rolling = read_table("server/rolling_announcements.tsv");
    context.expect(by_date && by_weekday && on_login && rolling, "bốn bảng thông báo có trong kho");
    if (!limits || !by_date || !by_weekday || !on_login || !rolling) return;
    const auto schedule = social::NoticeSchedule::parse(*limits, {.by_date = *by_date, .by_weekday = *by_weekday, .on_login = *on_login, .rolling = *rolling});
    context.expect(schedule.has_value(), "bốn bảng thông báo nạp được");
    if (!schedule) {
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg): in lý do nạp hỏng
        static_cast<void>(std::fprintf(stderr, "%s\n", schedule.error().c_str()));
        return;
    }
    context.expect(schedule->by_date().size() == data_rows(*by_date) && schedule->by_weekday().size() == data_rows(*by_weekday) &&
                       schedule->rolling().size() == data_rows(*rolling),
                   "mỗi dòng bảng ngày, thứ và luân phiên thành một thông báo");
    // Dòng is_show = 0 không vào lịch.
    context.expect(schedule->on_login().size() == rows_with(*on_login, 1, "1"), "chỉ dòng is_show = 1 vào lịch thông báo vào game");
    const social::NoticeBook book(*limits, *schedule, {.rolling_interval_ms = 0, .declared_only = true});
    // Người vào game bình thường thấy ít nhất lời chào mode 0 của bảng thật.
    const auto greeting = book.on_login({.who = social::CharacterId{1}, .birthday = false, .last = std::nullopt});
    context.expect(!greeting.empty(), "người vào game có ít nhất một thông báo");
}

void rank_boards_table(Context& context) {
    if (!tables_available()) return;
    const auto text = read_table("server/rank_boards.tsv");
    context.expect(text.has_value(), "rank_boards.tsv có trong kho");
    if (!text) return;
    const auto boards = social::parse_rank_boards(*text);
    context.expect(boards.has_value() && boards->size() == data_rows(*text), "rank_boards.tsv nạp được");
    if (!boards) return;
    // ScriptGlobal.lua: khoá 1, 11, 12, 13, mỗi bảng mười dòng.
    context.expect(boards->size() == 4 && boards->front().id == social::BoardId{1} && boards->front().capacity == 10 && boards->back().id == social::BoardId{13}, "bốn bảng khoá 1, 11, 12, 13 mỗi bảng 10 dòng");
    const auto limits = real_limits(context);
    if (!limits) return;
    social::RankBook book(*limits);
    context.expect(book.define_all(social::Tick{0}, *boards).has_value() && book.board_count() == 4, "định nghĩa đủ bốn bảng vào sổ");
}

void word_filter_tables(Context& context) {
    if (!tables_available()) return;
    const auto words = shared_or_skip("text_filter.tsv");
    const auto reserved = shared_or_skip("full_compare_filters.tsv");
    const auto extra = read_table("server/chat_blocked_words.tsv");
    context.expect(extra.has_value(), "chat_blocked_words.tsv có trong kho");
    if (!words || !reserved || !extra) return;
    const auto filter = WordFilter::parse({.words_tsv = *words, .reserved_tsv = *reserved, .extra_tsv = *extra});
    context.expect(filter.has_value(), "ba bảng chữ cấm nạp được");
    if (!filter) {
        // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg): in lý do nạp hỏng
        static_cast<void>(std::fprintf(stderr, "%s\n", filter.error().c_str()));
        return;
    }
    const WordFilter& built = **filter;
    context.expect(built.stats().loose_words > 100'000 && built.stats().regex_rules > 0 && built.stats().reserved_names > 0, "bảng thật đủ cỡ: từ, mẫu và tên dành riêng");
    // Số vàng đọc tay từ nguồn: "江泽民" là dòng type 1 đầu bảng client; "G*M" và "#666" chỉ có ở Filt.txt của máy chủ gốc.
    context.expect(!built.allowed("江泽民万岁") && !built.allowed("xin chào G*M nhé") && !built.allowed("tặng #666 cho bạn"), "từ cấm của client và của máy chủ gốc đều bị chặn");
    context.expect(built.allowed("chào các bạn, hôm nay trời đẹp"), "câu thường qua");
    // full_compare_filters.tsv: "中国" kind all, "少林" kind guild, "队伍" kind team.
    context.expect(built.reserved_name(NameKind::kCharacter, "中国") && !built.reserved_name(NameKind::kCharacter, "少林"), "tên nhân vật: chỉ loại all bị dành riêng");
    context.expect(built.reserved_name(NameKind::kGuild, "少林") && built.reserved_name(NameKind::kTeam, "队伍"), "tên bang và tên đội có loại riêng");
}

constexpr std::array kCases{
    Case{.name = "limits_table", .body = limits_table},
    Case{.name = "chat_channels_table", .body = chat_channels_table},
    Case{.name = "city_tables", .body = city_tables},
    Case{.name = "mentor_and_war_tables", .body = mentor_and_war_tables},
    Case{.name = "notice_tables", .body = notice_tables},
    Case{.name = "rank_boards_table", .body = rank_boards_table},
    Case{.name = "word_filter_tables", .body = word_filter_tables},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
