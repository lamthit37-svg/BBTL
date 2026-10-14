// Bảng xếp hạng: thứ tự (điểm, tick ghi, id), thay điểm, bảng đầy, ảnh chụp định kỳ, xoá nhân vật, đọc bảng định
// nghĩa và khối bền. Xếp sai thì client thấy hạng nhảy hay mất người, nên số vàng ở đây tính tay từ hợp đồng.
#include "ids/ids.hpp"
#include "social/codec.hpp"
#include "social/rank.hpp"
#include "social/types.hpp"
#include "social_support.hpp"
#include "test.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using social::BoardId;
using social::CodecError;
using social::RankBoard;
using social::RankBoardDef;
using social::RankBook;
using social::RankEntry;
using social::RankError;
using social::RankEvent;
using social::RankEventKind;
using social::RankSubject;
using social::Tick;

constexpr BoardId kBoard{1};
constexpr Tick kT0{1000};
constexpr std::uint64_t kSnapshotTicks = 6000;  // rank_snapshot_interval 300 giây, 20 tick mỗi giây

RankSubject subject(std::uint64_t id, std::string_view name = "ten", std::uint8_t sect = 0, std::uint8_t sex = 0) {
    return {.id = cid(id), .name = std::string{name}, .sect = sect, .sex = sex};
}

// Khai báo bảng thử kBoard vào `book`. Không trả RankBook theo giá trị: tránh dựa vào move của std::map.
bool setup(RankBook& book, std::uint32_t capacity, Tick now = kT0) {
    return book.define(now, {.id = kBoard, .name = "Đua cấp", .capacity = capacity}).has_value();
}

std::vector<std::uint64_t> order_of(const std::vector<RankEntry>& list) {
    std::vector<std::uint64_t> out;
    out.reserve(list.size());
    for (const RankEntry& entry : list) out.push_back(entry.id.value());
    return out;
}

bool is_event(const RankEvent& event, RankEventKind kind, std::uint64_t who, std::uint32_t old_rank, std::uint32_t new_rank) {
    return event.kind == kind && event.subject == cid(who) && event.old_rank == old_rank && event.new_rank == new_rank;
}

void ordering_and_ties(Context& context) {
    RankBook book(sample_limits());
    context.expect(setup(book, 10), "khai báo bảng thử");
    context.expect(book.submit(Tick{1001}, kBoard, subject(5), 70).events.size() == 1, "người đầu vào bảng");
    static_cast<void>(book.submit(Tick{1002}, kBoard, subject(3), 90));
    static_cast<void>(book.submit(Tick{1003}, kBoard, subject(9), 70));  // hòa điểm với 5, đến sau
    static_cast<void>(book.submit(Tick{1003}, kBoard, subject(2), 70));  // hòa điểm và cùng tick với 9: id nhỏ trước
    static_cast<void>(book.submit(Tick{1004}, kBoard, subject(7), 10));
    const RankBoard* board = book.board(kBoard);
    context.expect(board != nullptr, "bảng có sẵn");
    if (board == nullptr) return;
    context.expect(order_of(board->live) == std::vector<std::uint64_t>{3, 5, 2, 9, 7}, "điểm cao trước; hòa thì ghi trước; hòa nữa thì id nhỏ");
    context.expect(book.rank_of(kBoard, cid(2)) == 3U && book.rank_of(kBoard, cid(7)) == 5U && !book.rank_of(kBoard, cid(99)).has_value(), "hạng tra theo id");
    context.expect(!book.rank_of(BoardId{9}, cid(2)).has_value(), "bảng lạ không có hạng");
    context.expect(book.validate().has_value(), "bảng vẫn hợp lệ sau chuỗi cập nhật");
    context.expect(social::rank_before(board->live[0], board->live[1]) && !social::rank_before(board->live[1], board->live[0]), "rank_before là thứ tự chặt");
}

void replace_and_refresh(Context& context) {
    RankBook book(sample_limits());
    context.expect(setup(book, 10), "khai báo bảng thử");
    static_cast<void>(book.submit(Tick{1001}, kBoard, subject(1, "a"), 50));
    static_cast<void>(book.submit(Tick{1002}, kBoard, subject(2, "b"), 40));
    static_cast<void>(book.submit(Tick{1003}, kBoard, subject(3, "c"), 30));

    // Tăng điểm vượt người trên: kMoved từ hạng 3 lên hạng 1.
    const auto up = book.submit(Tick{1010}, kBoard, subject(3, "c"), 60);
    context.expect(up.ok() && up.events.size() == 1 && is_event(up.events[0], RankEventKind::kMoved, 3, 3, 1) && up.events[0].score == 60, "tăng điểm: hạng 3 lên 1");
    // Giảm điểm: tụt xuống cuối.
    const auto down = book.submit(Tick{1011}, kBoard, subject(3, "c"), 5);
    context.expect(down.ok() && down.events.size() == 1 && is_event(down.events[0], RankEventKind::kMoved, 3, 1, 3), "giảm điểm: hạng 1 xuống 3");
    // Điểm bằng nhau: không đổi hạng, không sự kiện, chỉ làm mới tên và môn phái; tick ghi không đổi nên thứ tự hòa không đổi.
    const auto same = book.submit(Tick{1500}, kBoard, subject(1, "A mới", 4, 1), 50);
    const RankBoard* board = book.board(kBoard);
    context.expect(same.ok() && same.events.empty(), "điểm bằng nhau: không sự kiện");
    context.expect(board != nullptr && board->live[0].name == "A mới" && board->live[0].sect == 4 && board->live[0].sex == 1 && board->live[0].since == Tick{1001},
                   "làm mới hiển thị mà giữ tick ghi cũ");
    // Điểm âm vẫn là điểm hợp lệ.
    const auto negative = book.submit(Tick{1600}, kBoard, subject(4, "d"), -7);
    context.expect(negative.ok() && is_event(negative.events.at(0), RankEventKind::kEntered, 4, 0, 4), "điểm âm vào cuối bảng");
    context.expect(book.validate().has_value(), "bảng hợp lệ");
}

void full_board(Context& context) {
    RankBook book(sample_limits());
    context.expect(setup(book, 3), "khai báo bảng thử");
    static_cast<void>(book.submit(Tick{1001}, kBoard, subject(1), 30));
    static_cast<void>(book.submit(Tick{1002}, kBoard, subject(2), 20));
    static_cast<void>(book.submit(Tick{1003}, kBoard, subject(3), 10));
    // Bằng dòng chót nhưng đến sau thì không vượt: ok, không sự kiện, không đổi gì.
    const auto tie = book.submit(Tick{1004}, kBoard, subject(4), 10);
    context.expect(tie.ok() && tie.events.empty() && !book.rank_of(kBoard, cid(4)).has_value(), "bằng dòng chót, đến sau: không vào");
    const auto below = book.submit(Tick{1005}, kBoard, subject(5), 1);
    context.expect(below.ok() && below.events.empty(), "thấp hơn dòng chót: không vào");
    // Hơn dòng chót: vào, đẩy dòng chót ra.
    const auto better = book.submit(Tick{1006}, kBoard, subject(6), 25);
    context.expect(better.ok() && better.events.size() == 2 && is_event(better.events[0], RankEventKind::kEntered, 6, 0, 2) &&
                       is_event(better.events[1], RankEventKind::kDropped, 3, 3, 0),
                   "vào hạng 2 và đẩy hạng chót ra");
    const RankBoard* board = book.board(kBoard);
    context.expect(board != nullptr && order_of(board->live) == std::vector<std::uint64_t>{1, 6, 2}, "bảng giữ đúng ba dòng đầu");
    // Người đang trong bảng giảm điểm không bị đẩy ra dù bảng đầy.
    const auto lower = book.submit(Tick{1007}, kBoard, subject(1), 1);
    context.expect(lower.ok() && lower.events.size() == 1 && is_event(lower.events[0], RankEventKind::kMoved, 1, 1, 3), "người trong bảng tụt hạng nhưng còn trong bảng");
    // Người bị đẩy ra rồi quay lại với điểm cao: vào như người mới.
    const auto back = book.submit(Tick{1008}, kBoard, subject(3), 99);
    context.expect(back.ok() && back.events.size() == 2 && is_event(back.events[0], RankEventKind::kEntered, 3, 0, 1) &&
                       is_event(back.events[1], RankEventKind::kDropped, 1, 3, 0),
                   "người cũ quay lại");
    context.expect(book.validate().has_value(), "bảng hợp lệ");
}

void rejects_bad_input(Context& context) {
    RankBook book(sample_limits());
    context.expect(setup(book, 5), "khai báo bảng thử");
    context.expect(book.submit(kT0, BoardId{7}, subject(1), 1).error == RankError::kNoSuchBoard, "bảng không tồn tại");
    context.expect(book.submit(kT0, kBoard, subject(0), 1).error == RankError::kBadValue, "id 0");
    context.expect(book.submit(kT0, kBoard, subject(1, "x", ids::kSectCount), 1).error == RankError::kBadValue, "môn phái ngoài miền");
    context.expect(book.submit(kT0, kBoard, subject(1, "x", 0, 2), 1).error == RankError::kBadValue, "giới tính ngoài miền");
    context.expect(book.submit(kT0, kBoard, subject(1, ""), 1).error == RankError::kBadText, "tên rỗng");
    context.expect(book.submit(kT0, kBoard, subject(1, "\xff\xfe"), 1).error == RankError::kBadText, "tên UTF-8 hỏng");
    context.expect(book.submit(kT0, kBoard, subject(1, std::string(64, 'a')), 1).error == RankError::kBadText, "tên quá 63 byte");
    context.expect(book.submit(kT0, kBoard, subject(1, std::string(63, 'a')), 1).ok(), "tên đúng 63 byte qua");
    context.expect(book.submit(kT0, kBoard, subject(2, "a\nb"), 1).error == RankError::kBadText, "tên có ký tự điều khiển");
    const RankBoard* board = book.board(kBoard);
    context.expect(board != nullptr && board->live.size() == 1, "đầu vào sai không để lại dấu vết");
    for (const RankError error : {RankError::kNoSuchBoard, RankError::kBoardExists, RankError::kTooManyBoards, RankError::kBadValue, RankError::kBadText}) {
        context.expect(!social::describe(error).empty(), "mỗi lỗi có lời mô tả");
    }
}

void define_boards(Context& context) {
    RankBook book(sample_limits());
    context.expect(book.define(kT0, {.id = BoardId{1}, .name = "a", .capacity = 0}).has_value(), "định nghĩa bảng, sức chứa 0 lấy mặc định");
    const RankBoard* board = book.board(BoardId{1});
    context.expect(board != nullptr && board->capacity == 100 && board->next_snapshot == Tick{kT0.value() + kSnapshotTicks}, "mặc định 100 dòng; chụp đầu sau 300 giây (20 tick mỗi giây)");
    context.expect(book.define(kT0, {.id = BoardId{1}, .name = "b", .capacity = 5}).error() == RankError::kBoardExists, "trùng id");
    context.expect(book.define(kT0, {.id = BoardId{0}, .name = "b", .capacity = 5}).error() == RankError::kBadValue, "id 0");
    context.expect(book.define(kT0, {.id = BoardId{2}, .name = "", .capacity = 5}).error() == RankError::kBadValue, "tên rỗng");
    context.expect(book.define(kT0, {.id = BoardId{2}, .name = "b", .capacity = social::kMaxBoardCapacity + 1}).error() == RankError::kBadValue, "vượt trần sức chứa");
    context.expect(book.define(kT0, {.id = BoardId{2}, .name = "b", .capacity = social::kMaxBoardCapacity}).has_value(), "đúng trần sức chứa");
    // Đủ 256 bảng thì bảng thứ 257 bị từ chối.
    bool all_defined = true;
    for (std::uint32_t id = 3; id <= 256; ++id) all_defined = book.define(kT0, {.id = BoardId{id}, .name = "x", .capacity = 1}).has_value() && all_defined;
    context.expect(all_defined, "định nghĩa 254 bảng còn lại");
    context.expect(book.board_count() == 256, "đủ 256 bảng");
    context.expect(book.define(kT0, {.id = BoardId{257}, .name = "x", .capacity = 1}).error() == RankError::kTooManyBoards, "bảng thứ 257");

    RankBook many(sample_limits());
    const std::array<RankBoardDef, 3> defs{{{.id = BoardId{1}, .name = "a", .capacity = 1}, {.id = BoardId{1}, .name = "dup", .capacity = 1}, {.id = BoardId{3}, .name = "c", .capacity = 1}}};
    context.expect(many.define_all(kT0, defs).error() == RankError::kBoardExists && many.board_count() == 1, "define_all dừng ở lỗi đầu tiên");
}

void snapshots(Context& context) {
    RankBook book(sample_limits());
    context.expect(setup(book, 5), "khai báo bảng thử");
    static_cast<void>(book.submit(Tick{1001}, kBoard, subject(1), 10));
    static_cast<void>(book.submit(Tick{1002}, kBoard, subject(2), 20));
    const Tick due{kT0.value() + kSnapshotTicks};
    context.expect(book.tick(Tick{due.value() - 1}).empty(), "chưa đến hạn chụp");
    context.expect(!book.published_rank_of(kBoard, cid(1)).has_value(), "ảnh chưa công bố thì chưa có hạng");
    const auto events = book.tick(due);
    context.expect(events.size() == 1 && events[0].kind == RankEventKind::kSnapshot && events[0].board == kBoard, "đến hạn: một sự kiện chụp");
    context.expect(book.published_rank_of(kBoard, cid(2)) == 1U && book.published_rank_of(kBoard, cid(1)) == 2U, "ảnh đã công bố có hạng");
    // Sau chụp, bảng sống đổi nhưng ảnh giữ nguyên tới lần chụp sau.
    static_cast<void>(book.submit(Tick{due.value() + 1}, kBoard, subject(1), 99));
    context.expect(book.rank_of(kBoard, cid(1)) == 1U && book.published_rank_of(kBoard, cid(1)) == 2U, "ảnh không nhảy giữa hai lần chụp");
    context.expect(book.tick(Tick{due.value() + 1}).empty(), "vừa chụp xong, chưa đến hạn kế");
    const Tick next{due.value() + kSnapshotTicks};
    context.expect(book.tick(next).size() == 1 && book.published_rank_of(kBoard, cid(1)) == 1U, "lần chụp sau thấy điểm mới");
    // Chốt kỳ: chụp ngay và hẹn lại.
    static_cast<void>(book.submit(Tick{next.value() + 5}, kBoard, subject(3), 500));
    const auto settled = book.settle(Tick{next.value() + 10}, kBoard);
    context.expect(settled.ok() && settled.events.size() == 1 && book.published_rank_of(kBoard, cid(3)) == 1U, "settle chụp ngay");
    context.expect(book.tick(Tick{next.value() + 10 + kSnapshotTicks - 1}).empty() && book.tick(Tick{next.value() + 10 + kSnapshotTicks}).size() == 1, "settle dời hạn kế một nhịp");
    context.expect(book.settle(kT0, BoardId{9}).error == RankError::kNoSuchBoard, "settle bảng lạ");
}

void forgetting(Context& context) {
    RankBook book(sample_limits());
    context.expect(book.define(kT0, {.id = BoardId{1}, .name = "a", .capacity = 5}).has_value() &&
                       book.define(kT0, {.id = BoardId{2}, .name = "b", .capacity = 5}).has_value(),
                   "hai bảng");
    for (const BoardId board : {BoardId{1}, BoardId{2}}) {
        static_cast<void>(book.submit(Tick{1001}, board, subject(1), 10));
        static_cast<void>(book.submit(Tick{1002}, board, subject(2), 20));
    }
    static_cast<void>(book.settle(Tick{1003}, BoardId{1}));
    static_cast<void>(book.submit(Tick{1004}, BoardId{2}, subject(3), 5));
    const auto events = book.forget(cid(1));
    context.expect(events.size() == 2 && events[0].board == BoardId{1} && is_event(events[0], RankEventKind::kDropped, 1, 2, 0) &&
                       events[1].board == BoardId{2} && is_event(events[1], RankEventKind::kDropped, 1, 2, 0),
                   "xoá nhân vật: một sự kiện mỗi bảng sống, theo thứ tự id bảng");
    context.expect(!book.rank_of(BoardId{1}, cid(1)).has_value() && !book.published_rank_of(BoardId{1}, cid(1)).has_value(), "gỡ cả ảnh đã công bố");
    context.expect(book.rank_of(BoardId{2}, cid(2)) == 1U && book.rank_of(BoardId{2}, cid(3)) == 2U, "người khác giữ hạng");
    context.expect(book.forget(cid(1)).empty() && book.forget(cid(404)).empty(), "xoá người không có trong bảng: không gì xảy ra");
    context.expect(book.validate().has_value(), "bảng hợp lệ");
}

constexpr std::string_view kBoardsOk =
    "# schema 1\nboard_id\tname\tcapacity\n"
    "1\tĐua cấp\t10\n"
    "11\tĐua cấp A\t0\n";

void boards_table(Context& context) {
    const auto defs = social::parse_rank_boards(kBoardsOk);
    context.expect(defs.has_value() && defs->size() == 2 && (*defs)[0].id == BoardId{1} && (*defs)[0].name == "Đua cấp" && (*defs)[0].capacity == 10 &&
                       (*defs)[1].id == BoardId{11} && (*defs)[1].capacity == 0,
                   "đọc bảng định nghĩa");
    RankBook book(sample_limits());
    context.expect(defs.has_value() && book.define_all(kT0, *defs).has_value() && book.board_count() == 2, "định nghĩa từ bảng đọc được");
    const auto bad = [&context](std::string_view tsv, std::string_view why) {
        context.expect(!social::parse_rank_boards(tsv).has_value(), why);
    };
    bad("# schema 1\nboard_id\tname\tcapacity\n0\ta\t5\n", "id 0");
    bad("# schema 1\nboard_id\tname\tcapacity\n1\ta\t5\n1\tb\t5\n", "trùng id");
    bad("# schema 1\nboard_id\tname\tcapacity\n1\t\t5\n", "tên rỗng");
    bad("# schema 1\nboard_id\tname\tcapacity\n1\ta\t100001\n", "sức chứa quá trần");
    bad("# schema 1\nboard_id\tname\tcapacity\n1\ta\t-1\n", "sức chứa âm");
    bad("# schema 1\nboard_id\tname\tcapacity\n1\ta\n", "thiếu ô");
    bad("# schema 1\nboard_id\tname\n1\ta\n", "thiếu cột capacity");
    bad("", "bảng rỗng không có tiêu đề");
    context.expect(social::parse_rank_boards("# schema 1\nboard_id\tname\tcapacity\n")->empty(), "bảng chỉ có tiêu đề: không có bảng nào");
}

RankBoard sample_board() {
    RankBoard board;
    board.id = BoardId{3};
    board.name = "ab";
    board.capacity = 4;
    board.published_at = Tick{900};
    board.next_snapshot = Tick{1300};
    board.live.push_back({.id = cid(7), .name = "x", .sect = 1, .sex = 0, .score = 50, .since = Tick{990}});
    return board;
}

void load_and_validate(Context& context) {
    RankBook book(sample_limits());
    context.expect(book.load(sample_board()).has_value() && book.board_count() == 1 && book.validate().has_value(), "nạp bảng hợp lệ");
    context.expect(!book.load(sample_board()).has_value(), "nạp trùng id bảng");
    const auto rejects = [&context](const RankBoard& board, std::string_view why) {
        RankBook fresh(sample_limits());
        context.expect(!fresh.load(board).has_value() && fresh.board_count() == 0, why);
    };
    RankBoard no_id = sample_board();
    no_id.id = BoardId{};
    rejects(no_id, "id bảng 0");
    RankBoard no_name = sample_board();
    no_name.name.clear();
    rejects(no_name, "tên bảng rỗng");
    RankBoard no_capacity = sample_board();
    no_capacity.capacity = 0;
    rejects(no_capacity, "sức chứa 0");
    RankBoard too_big = sample_board();
    too_big.capacity = social::kMaxBoardCapacity + 1;
    rejects(too_big, "sức chứa quá trần");
    RankBoard over = sample_board();
    over.capacity = 1;
    over.live.push_back({.id = cid(8), .name = "y", .sect = 0, .sex = 0, .score = 10, .since = Tick{991}});
    rejects(over, "nhiều dòng hơn sức chứa");
    RankBoard unsorted = sample_board();
    unsorted.live.push_back({.id = cid(8), .name = "y", .sect = 0, .sex = 0, .score = 60, .since = Tick{991}});
    rejects(unsorted, "dòng sau điểm cao hơn dòng trước");
    RankBoard duplicate = sample_board();
    duplicate.live.push_back({.id = cid(7), .name = "x", .sect = 1, .sex = 0, .score = 40, .since = Tick{991}});
    rejects(duplicate, "trùng id nhân vật");
    RankBoard zero = sample_board();
    zero.live[0].id = cid(0);
    rejects(zero, "id nhân vật 0");
    RankBoard bad_sect = sample_board();
    bad_sect.live[0].sect = ids::kSectCount;
    rejects(bad_sect, "môn phái ngoài miền");
    RankBoard bad_sex = sample_board();
    bad_sex.live[0].sex = 2;
    rejects(bad_sex, "giới tính ngoài miền");
    RankBoard bad_name = sample_board();
    bad_name.published.push_back({.id = cid(9), .name = "", .sect = 0, .sex = 0, .score = 1, .since = Tick{1}});
    rejects(bad_name, "ảnh có dòng tên rỗng");

    // Bảng đã đầy sức chứa trong sổ: không nạp thêm bảng thứ 257.
    RankBook full(sample_limits());
    for (std::uint32_t id = 1; id <= 256; ++id) {
        RankBoard board = sample_board();
        board.id = BoardId{id};
        context.expect(full.load(board).has_value(), "nạp tới trần số bảng");
    }
    RankBoard extra = sample_board();
    extra.id = BoardId{500};
    context.expect(!full.load(extra).has_value(), "bảng thứ 257");
}

std::vector<std::byte> from_hex(std::string_view hex) {
    const auto digit = [](char c) { return c <= '9' ? c - '0' : c - 'a' + 10; };
    std::vector<std::byte> bytes;
    for (std::size_t index = 0; index + 1 < hex.size(); index += 2) {
        bytes.push_back(static_cast<std::byte>((digit(hex[index]) * 16) + digit(hex[index + 1])));
    }
    return bytes;
}

void codec_golden_and_round_trip(Context& context) {
    const RankBoard board = sample_board();
    social::Bytes bytes;
    context.expect(social::encode_rank(board, kT0, bytes).has_value(), "mã hoá");
    // Số vàng tính tay: đầu khung (thân 63 byte, kind 0x5105), phiên bản 1, bảng 3 tên "ab" sức chứa 4, ảnh đã công bố
    // cách đây 100 tick, hẹn chụp sau 300 tick; bảng sống một dòng: id 7, tên "x", môn phái 1, nam, 50 điểm, ghi cách đây
    // 10 tick; ảnh không dòng nào.
    const auto golden = from_hex(
        "3f000000" "0551" "0000"
        "0100" "03000000" "0200" "6162" "04000000"
        "6400000000000000" "2c01000000000000"
        "0100" "0700000000000000" "0100" "78" "01" "00" "3200000000000000" "0a00000000000000"
        "0000");
    context.expect(bytes == golden, "khớp số vàng");
    const auto back = social::decode_rank(bytes, kT0);
    context.expect(back.has_value() && back->id == board.id && back->name == "ab" && back->capacity == 4 && back->published_at == Tick{900} &&
                       back->next_snapshot == Tick{1300} && back->live.size() == 1 && back->live[0].id == cid(7) && back->live[0].since == Tick{990} &&
                       back->live[0].score == 50 && back->published.empty(),
                   "giải mã đúng, thời gian gắn lại vào mốc nạp");
    // Nạp ở mốc tick khác (world khởi động lại): tuổi và thời gian còn lại giữ nguyên.
    const auto restarted = social::decode_rank(bytes, Tick{5000});
    context.expect(restarted.has_value() && restarted->published_at == Tick{4900} && restarted->next_snapshot == Tick{5300} && restarted->live[0].since == Tick{4990},
                   "nạp ở mốc khác: tương đối giữ nguyên");
    // Bộ đếm tick về 0 sau khởi động: tuổi lớn hơn mốc nạp thì since bị chặn ở 0, bảng vẫn nạp được.
    const auto fresh_process = social::decode_rank(bytes, Tick{5});
    context.expect(fresh_process.has_value() && fresh_process->live[0].since == Tick{0} && fresh_process->published_at == Tick{0}, "tick về 0 sau khởi động: chặn ở 0");
}

void codec_restores_tie_order(Context& context) {
    // Ba người cùng điểm, tuổi khác nhau, id đi ngược thứ tự ghi: id 9 ghi trước (tuổi 80), id 4 sau (tuổi 50), id 6 sau cùng (tuổi 20).
    RankBoard board;
    board.id = BoardId{1};
    board.name = "t";
    board.capacity = 10;
    board.published_at = Tick{1000};
    board.next_snapshot = Tick{1100};
    board.live.push_back({.id = cid(9), .name = "a", .sect = 0, .sex = 0, .score = 5, .since = Tick{920}});
    board.live.push_back({.id = cid(4), .name = "b", .sect = 0, .sex = 0, .score = 5, .since = Tick{950}});
    board.live.push_back({.id = cid(6), .name = "c", .sect = 0, .sex = 0, .score = 5, .since = Tick{980}});
    context.expect(social::rank_board_problem(board).empty(), "bảng mẫu đúng thứ tự");
    social::Bytes bytes;
    context.expect(social::encode_rank(board, Tick{1000}, bytes).has_value(), "mã hoá");
    const auto same_clock = social::decode_rank(bytes, Tick{1000});
    context.expect(same_clock.has_value() && order_of(same_clock->live) == std::vector<std::uint64_t>{9, 4, 6}, "cùng mốc: thứ tự giữ nguyên");
    // Mốc nạp 10 < mọi tuổi: cả ba since bị chặn ở 0; thứ tự đã lưu vẫn phải còn và bảng vẫn hợp lệ.
    const auto fresh_process = social::decode_rank(bytes, Tick{10});
    context.expect(fresh_process.has_value() && order_of(fresh_process->live) == std::vector<std::uint64_t>{9, 4, 6} && social::rank_board_problem(*fresh_process).empty(),
                   "since bị chặn ở 0: thứ tự hòa điểm vẫn giữ");
    context.expect(fresh_process.has_value() && fresh_process->live[0].since == Tick{0} && fresh_process->live[1].since == Tick{1} && fresh_process->live[2].since == Tick{1},
                   "since dòng sau đẩy lên vừa đủ: 9 -> 0, 4 -> 1 (id nhỏ hơn 9), 6 -> 1 (id lớn hơn 4)");
    // Người mới đến sau khởi động lại vẫn đứng sau cả ba.
    RankBook book(sample_limits());
    context.expect(fresh_process.has_value() && book.load(*fresh_process).has_value(), "nạp vào sổ");
    static_cast<void>(book.submit(Tick{10}, BoardId{1}, subject(2), 5));
    context.expect(book.rank_of(BoardId{1}, cid(2)) == 4U, "người mới sau khởi động đứng sau ba người cùng điểm");
}

void codec_rejects_garbage(Context& context) {
    RankBoard board = sample_board();
    board.live.push_back({.id = cid(8), .name = "y", .sect = 3, .sex = 1, .score = 40, .since = Tick{995}});
    board.published = board.live;
    social::Bytes bytes;
    context.expect(social::encode_rank(board, kT0, bytes).has_value(), "mã hoá");
    bool every_cut_rejected = true;
    for (std::size_t cut = 0; cut < bytes.size(); ++cut) {
        every_cut_rejected = every_cut_rejected && !social::decode_rank(std::span<const std::byte>(bytes.data(), cut), kT0).has_value();
    }
    context.expect(every_cut_rejected, "mọi bản cụt bị từ chối");
    social::Bytes extra = bytes;
    extra.push_back(std::byte{0});
    context.expect(!social::decode_rank(extra, kT0).has_value(), "byte thừa");
    for (std::size_t index = 0; index < bytes.size(); ++index) {
        for (const unsigned flip : {0x01U, 0x80U, 0xFFU}) {
            social::Bytes copy = bytes;
            copy.at(index) = static_cast<std::byte>(static_cast<unsigned>(copy.at(index)) ^ flip);
            const auto decoded = social::decode_rank(copy, kT0);
            if (decoded.has_value()) {
                // Bản nào lọt qua phải đủ điều kiện nạp vào sổ.
                RankBook book(sample_limits());
                context.expect(book.load(*decoded).has_value(), "bản lật byte nào lọt giải mã đều nạp được");
            }
        }
    }
    social::Bytes wrong = bytes;
    wrong.at(4) = std::byte{0x04};
    context.expect(social::decode_rank(wrong, kT0).error() == CodecError::kBadKind, "kind sai");
    social::Bytes future = bytes;
    future.at(8) = std::byte{7};
    context.expect(social::decode_rank(future, kT0).error() == CodecError::kBadVersion, "phiên bản lạ");
    const auto reject_board = [&context](const RankBoard& bad, std::string_view why) {
        social::Bytes out;
        context.expect(social::encode_rank(bad, kT0, out).has_value(), "mã hoá bản sai hình dạng");
        context.expect(!social::decode_rank(out, kT0).has_value(), why);
    };
    RankBoard unsorted = board;
    std::swap(unsorted.live[0], unsorted.live[1]);
    reject_board(unsorted, "danh sách sai thứ tự điểm");
    RankBoard duplicate = board;
    duplicate.live[1].id = duplicate.live[0].id;
    reject_board(duplicate, "trùng id");
    RankBoard over = board;
    over.capacity = 1;
    reject_board(over, "nhiều dòng hơn sức chứa");
    RankBoard zero_capacity = board;
    zero_capacity.capacity = 0;
    reject_board(zero_capacity, "sức chứa 0");
    RankBoard bad_sect = board;
    bad_sect.live[1].sect = ids::kSectCount;
    reject_board(bad_sect, "môn phái ngoài miền");
    RankBoard empty_name = board;
    empty_name.name.clear();
    reject_board(empty_name, "tên bảng rỗng");
    // Quá số dòng mã hoá tối đa: bên mã hoá báo kTooLarge, không tạo khối.
    RankBoard huge = board;
    huge.capacity = social::kMaxBoardCapacity;
    huge.live.clear();
    for (std::uint64_t id = 1; id <= 1001; ++id) {
        huge.live.push_back({.id = cid(id), .name = "n", .sect = 0, .sex = 0, .score = 100000 - static_cast<std::int64_t>(id), .since = Tick{1}});
    }
    huge.published.clear();
    social::Bytes out;
    const auto too_large = social::encode_rank(huge, kT0, out);
    context.expect(!too_large.has_value() && too_large.error() == CodecError::kTooLarge, "quá 1000 dòng một danh sách: kTooLarge");
}

constexpr std::array kCases{
    Case{.name = "ordering_and_ties", .body = ordering_and_ties},
    Case{.name = "replace_and_refresh", .body = replace_and_refresh},
    Case{.name = "full_board", .body = full_board},
    Case{.name = "rejects_bad_input", .body = rejects_bad_input},
    Case{.name = "define_boards", .body = define_boards},
    Case{.name = "snapshots", .body = snapshots},
    Case{.name = "forgetting", .body = forgetting},
    Case{.name = "boards_table", .body = boards_table},
    Case{.name = "load_and_validate", .body = load_and_validate},
    Case{.name = "codec_golden_and_round_trip", .body = codec_golden_and_round_trip},
    Case{.name = "codec_restores_tie_order", .body = codec_restores_tie_order},
    Case{.name = "codec_rejects_garbage", .body = codec_rejects_garbage},
};

} // namespace
} // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
