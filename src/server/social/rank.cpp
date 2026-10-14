#include "social/rank.hpp"

#include "ids/ids.hpp"
#include "protocol/wire.hpp"
#include "social/codec.hpp"
#include "social/limits.hpp"
#include "social/text.hpp"
#include "social/types.hpp"
#include "table/tsv.hpp"

#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <iterator>
#include <limits>
#include <map>
#include <optional>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::social {
namespace {

constexpr std::uint16_t kRankVersion = 1;
constexpr std::size_t kMaxEncodedEntries = 1000;  // trần giải mã mỗi danh sách, rộng hơn mọi bảng thực tế
constexpr std::size_t kMaxBoardNameBytes = 63;

[[nodiscard]] RankResult reject(RankError error) {
    RankResult result;
    result.error = error;
    return result;
}

[[nodiscard]] RankEvent make_event(RankEventKind kind, BoardId board, const RankEntry& entry, std::uint32_t old_rank, std::uint32_t new_rank) {
    return {.kind = kind, .board = board, .subject = entry.id, .old_rank = old_rank, .new_rank = new_rank, .score = entry.score};
}

[[nodiscard]] std::optional<std::size_t> index_of(const std::vector<RankEntry>& list, CharacterId who) {
    const auto found = std::ranges::find(list, who, &RankEntry::id);
    if (found == list.end()) return std::nullopt;
    return static_cast<std::size_t>(std::distance(list.begin(), found));
}

[[nodiscard]] std::string_view list_problem(const std::vector<RankEntry>& list, std::uint32_t capacity) {
    if (std::cmp_greater(list.size(), capacity)) return "nhiều dòng hơn sức chứa";
    std::set<CharacterId> seen;
    for (std::size_t index = 0; index < list.size(); ++index) {
        const RankEntry& entry = list[index];
        if (entry.id.value() == 0 || !seen.insert(entry.id).second) return "id nhân vật 0 hoặc trùng";
        if (!is_plain_text(entry.name, kMaxRankNameBytes) || entry.name.empty()) return "tên sai";
        if (entry.sect >= ids::kSectCount || entry.sex > 1) return "môn phái hoặc giới tính ngoài miền";
        if (index > 0 && !rank_before(list[index - 1], entry)) return "không xếp đúng thứ tự";
    }
    return {};
}

} // namespace

std::string_view describe(RankError error) noexcept {
    switch (error) {
    case RankError::kNoSuchBoard: return "không có bảng xếp hạng này";
    case RankError::kBoardExists: return "bảng xếp hạng đã tồn tại";
    case RankError::kTooManyBoards: return "đã đủ số bảng xếp hạng";
    case RankError::kBadValue: return "giá trị không hợp lệ";
    case RankError::kBadText: return "tên không hợp lệ";
    }
    return "lỗi xếp hạng lạ";
}

bool rank_before(const RankEntry& left, const RankEntry& right) noexcept {
    if (left.score != right.score) return left.score > right.score;
    if (left.since != right.since) return left.since < right.since;
    return left.id < right.id;
}

std::string_view rank_board_problem(const RankBoard& board) {
    if (board.id.value() == 0) return "id bảng 0";
    if (!is_plain_text(board.name, kMaxBoardNameBytes) || board.name.empty()) return "tên bảng sai";
    if (board.capacity == 0 || board.capacity > kMaxBoardCapacity) return "sức chứa ngoài miền";
    if (const auto problem = list_problem(board.live, board.capacity); !problem.empty()) return problem;
    return list_problem(board.published, board.capacity);
}

std::expected<std::vector<RankBoardDef>, std::string> parse_rank_boards(std::string_view tsv_text) {
    auto parsed = table::parse_tsv(tsv_text);
    if (!parsed) return std::unexpected(std::move(parsed.error()));
    const table::Tsv& sheet = *parsed;
    std::vector<RankBoardDef> defs;
    std::set<BoardId> seen;
    for (std::size_t row = 0; row < sheet.rows.size(); ++row) {
        table::RowReader reader(sheet, row);
        RankBoardDef def;
        def.id = BoardId{reader.number("board_id", 1, std::numeric_limits<std::uint32_t>::max())};
        def.name = std::string{reader.text("name")};
        def.capacity = reader.number("capacity", 0, kMaxBoardCapacity);
        if (!reader.error() && (def.name.empty() || !is_plain_text(def.name, kMaxBoardNameBytes))) {
            reader.reject("name", "tên bảng rỗng hoặc không hợp lệ");
        }
        if (reader.error()) return std::unexpected(*reader.error());
        if (!seen.insert(def.id).second) return std::unexpected(std::format("dòng {}: trùng board_id {}", sheet.lines[row], def.id.value()));
        defs.push_back(std::move(def));
    }
    return defs;
}

RankBook::RankBook(const Limits& limits) : limits_(limits), snapshot_every_(seconds_to_ticks(limits.rank_snapshot_interval_seconds)) {}

std::expected<void, RankError> RankBook::define(Tick now, const RankBoardDef& def) {
    if (def.id.value() == 0 || def.name.empty() || !is_plain_text(def.name, kMaxBoardNameBytes)) return std::unexpected(RankError::kBadValue);
    if (def.capacity > kMaxBoardCapacity) return std::unexpected(RankError::kBadValue);
    if (boards_.contains(def.id)) return std::unexpected(RankError::kBoardExists);
    if (std::cmp_greater_equal(boards_.size(), limits_.rank_max_boards)) return std::unexpected(RankError::kTooManyBoards);
    RankBoard board;
    board.id = def.id;
    board.name = def.name;
    board.capacity = def.capacity != 0 ? def.capacity : static_cast<std::uint32_t>(limits_.rank_default_capacity);
    board.published_at = now;
    board.next_snapshot = ids::advance(now, snapshot_every_);
    boards_.emplace(def.id, std::move(board));
    return {};
}

std::expected<void, RankError> RankBook::define_all(Tick now, std::span<const RankBoardDef> defs) {
    for (const RankBoardDef& def : defs) {
        if (const auto done = define(now, def); !done) return done;
    }
    return {};
}

RankBoard* RankBook::mutable_board(BoardId id) {
    const auto found = boards_.find(id);
    return found == boards_.end() ? nullptr : &found->second;
}

const RankBoard* RankBook::board(BoardId id) const {
    const auto found = boards_.find(id);
    return found == boards_.end() ? nullptr : &found->second;
}

RankResult RankBook::submit(Tick now, BoardId board_id, const RankSubject& subject, std::int64_t score) {
    RankBoard* board = mutable_board(board_id);
    if (board == nullptr) return reject(RankError::kNoSuchBoard);
    if (subject.id.value() == 0 || subject.sect >= ids::kSectCount || subject.sex > 1) return reject(RankError::kBadValue);
    if (subject.name.empty() || !is_plain_text(subject.name, kMaxRankNameBytes)) return reject(RankError::kBadText);

    RankResult result;
    std::vector<RankEntry>& live = board->live;
    std::uint32_t old_rank = 0;
    const auto existing = index_of(live, subject.id);
    const RankEntry entry{.id = subject.id, .name = subject.name, .sect = subject.sect, .sex = subject.sex, .score = score, .since = now};
    if (existing) {
        RankEntry& current = live[*existing];
        old_rank = static_cast<std::uint32_t>(*existing + 1);
        if (current.score == score) {
            // Điểm không đổi: hạng không đổi, chỉ làm mới phần hiển thị.
            current.name = subject.name;
            current.sect = subject.sect;
            current.sex = subject.sex;
            return result;
        }
        live.erase(live.begin() + static_cast<std::ptrdiff_t>(*existing));
    } else if (std::cmp_greater_equal(live.size(), board->capacity) && !rank_before(entry, live.back())) {
        return result;  // bảng đầy và chưa hơn dòng chót
    }

    const auto position = std::ranges::lower_bound(live, entry, rank_before);
    const auto new_rank = static_cast<std::uint32_t>(std::distance(live.begin(), position) + 1);
    live.insert(position, entry);
    result.events.push_back(make_event(existing ? RankEventKind::kMoved : RankEventKind::kEntered, board_id, entry, old_rank, new_rank));
    if (std::cmp_greater(live.size(), board->capacity)) {
        // Dòng chót cũ đang đứng ở hạng = sức chứa (sau pop_back, live.size() chính là sức chứa).
        const RankEntry dropped = live.back();
        live.pop_back();
        result.events.push_back(make_event(RankEventKind::kDropped, board_id, dropped, static_cast<std::uint32_t>(live.size()), 0));
    }
    return result;
}

RankEvents RankBook::forget(CharacterId who) {
    RankEvents events;
    for (auto& [id, board] : boards_) {
        if (const auto at = index_of(board.live, who)) {
            events.push_back(make_event(RankEventKind::kDropped, id, board.live[*at], static_cast<std::uint32_t>(*at + 1), 0));
            board.live.erase(board.live.begin() + static_cast<std::ptrdiff_t>(*at));
        }
        if (const auto at = index_of(board.published, who)) {
            board.published.erase(board.published.begin() + static_cast<std::ptrdiff_t>(*at));
        }
    }
    return events;
}

RankEvents RankBook::tick(Tick now) {
    RankEvents events;
    for (auto& [id, board] : boards_) {
        if (board.next_snapshot > now) continue;
        board.published = board.live;
        board.published_at = now;
        board.next_snapshot = ids::advance(now, snapshot_every_);
        events.push_back({.kind = RankEventKind::kSnapshot, .board = id});
    }
    return events;
}

RankResult RankBook::settle(Tick now, BoardId board_id) {
    RankBoard* board = mutable_board(board_id);
    if (board == nullptr) return reject(RankError::kNoSuchBoard);
    board->published = board->live;
    board->published_at = now;
    board->next_snapshot = ids::advance(now, snapshot_every_);
    RankResult result;
    result.events.push_back({.kind = RankEventKind::kSnapshot, .board = board_id});
    return result;
}

std::optional<std::uint32_t> RankBook::rank_of(BoardId board_id, CharacterId who) const {
    const RankBoard* found = board(board_id);
    if (found == nullptr) return std::nullopt;
    const auto at = index_of(found->live, who);
    if (!at) return std::nullopt;
    return static_cast<std::uint32_t>(*at + 1);
}

std::optional<std::uint32_t> RankBook::published_rank_of(BoardId board_id, CharacterId who) const {
    const RankBoard* found = board(board_id);
    if (found == nullptr) return std::nullopt;
    const auto at = index_of(found->published, who);
    if (!at) return std::nullopt;
    return static_cast<std::uint32_t>(*at + 1);
}

std::expected<void, std::string> RankBook::load(RankBoard incoming) {
    if (const auto problem = rank_board_problem(incoming); !problem.empty()) {
        return std::unexpected(std::format("bảng {}: {}", incoming.id.value(), problem));
    }
    if (boards_.contains(incoming.id)) return std::unexpected(std::format("bảng {} đã nạp", incoming.id.value()));
    if (std::cmp_greater_equal(boards_.size(), limits_.rank_max_boards)) return std::unexpected("đã đủ số bảng xếp hạng");
    const BoardId id = incoming.id;
    boards_.emplace(id, std::move(incoming));
    return {};
}

std::expected<void, std::string> RankBook::validate() const {
    if (std::cmp_greater(boards_.size(), limits_.rank_max_boards)) return std::unexpected("quá số bảng xếp hạng");
    for (const auto& [id, board] : boards_) {
        if (board.id != id) return std::unexpected(std::format("bảng {}: id không khớp khoá", id.value()));
        if (const auto problem = rank_board_problem(board); !problem.empty()) {
            return std::unexpected(std::format("bảng {}: {}", id.value(), problem));
        }
    }
    return {};
}

// ---------------------------------------------------------------------------------------------
// Mã hoá. Thời gian lưu tương đối (tuổi hoặc thời gian còn lại) rồi gắn lại vào `now` lúc giải mã.
// ---------------------------------------------------------------------------------------------

namespace {

void write_list(protocol::Writer& writer, const std::vector<RankEntry>& list, Tick now) {
    writer.count(list.size(), kMaxEncodedEntries);
    for (const RankEntry& entry : list) {
        writer.u64(entry.id.value());
        writer.text(entry.name, kMaxRankNameBytes);
        writer.u8(entry.sect);
        writer.u8(entry.sex);
        writer.i64(entry.score);
        writer.i64(now > entry.since ? (now - entry.since).count : 0);
    }
}

// Bộ đếm tick của world bắt đầu lại từ 0 mỗi lần khởi động, nên `now - tuổi` có thể rơi xuống dưới 0 và bị chặn ở 0:
// hai dòng cùng điểm khác tuổi khi đó có since bằng nhau và có thể sai thứ tự id. Danh sách đã lưu đúng thứ tự thì
// thứ tự ấy là thông tin thật: đẩy since của dòng sau lên vừa đủ để rank_before lại đúng, không đổi thứ tự dòng.
void restore_tie_order(std::vector<RankEntry>& list) {
    for (std::size_t index = 1; index < list.size(); ++index) {
        const RankEntry& previous = list[index - 1];
        RankEntry& entry = list[index];
        if (entry.score != previous.score || rank_before(previous, entry)) continue;
        entry.since = previous.since;
        if (entry.id < previous.id) entry.since = ids::advance(previous.since, TickSpan{1});
    }
}

[[nodiscard]] std::optional<CodecError> read_list(protocol::Reader& reader, std::vector<RankEntry>& list, Tick now) {
    const std::size_t count = reader.count(kMaxEncodedEntries);
    if (!reader.is_ok()) return CodecError::kTruncated;
    list.reserve(count);
    for (std::size_t index = 0; index < count && reader.is_ok(); ++index) {
        RankEntry entry;
        entry.id = CharacterId{reader.u64()};
        entry.name = reader.text(kMaxRankNameBytes);
        entry.sect = reader.u8();
        entry.sex = reader.u8();
        entry.score = reader.i64();
        const std::int64_t age = reader.i64();
        if (age < 0) return CodecError::kBadValue;
        entry.since = ids::advance(now, TickSpan{-age});
        list.push_back(std::move(entry));
    }
    restore_tie_order(list);
    return std::nullopt;
}

} // namespace

CodecResult encode_rank(const RankBoard& board, Tick now, Bytes& out) {
    protocol::Writer writer(out);
    writer.u16(kRankVersion);
    writer.u32(board.id.value());
    writer.text(board.name, kMaxBoardNameBytes);
    writer.u32(board.capacity);
    writer.i64(now > board.published_at ? (now - board.published_at).count : 0);
    writer.i64(board.next_snapshot > now ? (board.next_snapshot - now).count : 0);
    write_list(writer, board.live, now);
    write_list(writer, board.published, now);
    return finish_blob(writer, blob::kRank);
}

std::expected<RankBoard, CodecError> decode_rank(std::span<const std::byte> bytes, Tick now) {
    const auto body = open_blob(bytes, blob::kRank);
    if (!body) return std::unexpected(body.error());
    protocol::Reader reader(*body);
    const std::uint16_t version = reader.u16();
    if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
    if (version != kRankVersion) return std::unexpected(CodecError::kBadVersion);
    RankBoard board;
    board.id = BoardId{reader.u32()};
    board.name = reader.text(kMaxBoardNameBytes);
    board.capacity = reader.u32();
    const std::int64_t published_age = reader.i64();
    const std::int64_t remaining = reader.i64();
    if (!reader.is_ok()) return std::unexpected(CodecError::kTruncated);
    if (published_age < 0 || remaining < 0) return std::unexpected(CodecError::kBadValue);
    board.published_at = ids::advance(now, TickSpan{-published_age});
    board.next_snapshot = ids::advance(now, TickSpan{remaining});
    if (const auto problem = read_list(reader, board.live, now)) return std::unexpected(*problem);
    if (const auto problem = read_list(reader, board.published, now)) return std::unexpected(*problem);
    if (const auto done = finish_read(reader); !done) return std::unexpected(done.error());
    if (!rank_board_problem(board).empty()) return std::unexpected(CodecError::kBadValue);
    return board;
}

} // namespace game::social
