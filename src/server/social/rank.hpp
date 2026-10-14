#pragma once
// Bảng xếp hạng: nhiều bảng, mỗi bảng giữ N dòng đứng đầu theo điểm giảm dần; cập nhật tăng dần (mỗi lần một
// người đổi điểm chỉ đụng một dòng) và chụp ảnh định kỳ - client xem ảnh đã công bố, không xem bảng sống,
// nên thứ hạng không nhảy lung tung giữa hai lần chụp. Lõi thuần: bên gọi đưa Tick, nhận sự kiện.
//
// Nguồn: bảng đua cấp của máy chủ XJL7457 (kịch bản ScriptGlobal.lua SetPaimingold/GetPaimingold/
// Getpaiminccold + tệp Config/Paiming/*.txt): mười dòng đầu, xếp theo cấp giảm dần, người đã có tên thì
// thay dòng cũ, hòa điểm thì người đến trước đứng trên (sắp bằng hoán đổi chỉ khi nhỏ hơn hẳn). Nhịp chụp
// ảnh, sức chứa mặc định và số bảng tối đa là số tự đặt (social_limits.tsv, rank.*).
// Khác gốc: (1) tổng quát cho mọi loại điểm, sức chứa theo từng bảng (rank_boards.tsv); (2) hòa điểm phân
// định bằng tick đạt điểm rồi id, tất định ở mọi lần chạy; (3) có chụp ảnh định kỳ và xoá nhân vật bị
// xoá khỏi mọi bảng; (4) lưu nhị phân có phiên bản thay cho tệp chữ năm dòng một người.

#include "social/codec.hpp"
#include "social/limits.hpp"
#include "social/types.hpp"

#include <cstddef>
#include <cstdint>
#include <expected>
#include <map>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::social {

// Trần sức chứa một bảng: chặn dữ liệu thù địch khi nạp bảng và khi giải mã; không phải luật chơi.
inline constexpr std::uint32_t kMaxBoardCapacity = 100'000;
inline constexpr std::size_t kMaxRankNameBytes = 63;

enum class RankError : std::uint8_t {
    kNoSuchBoard = 1,
    kBoardExists,
    kTooManyBoards,
    kBadValue,
    kBadText,
};

[[nodiscard]] std::string_view describe(RankError error) noexcept;

// Người được xếp hạng. Tên, môn phái, giới tính là thứ client hiển thị ở dòng bảng.
struct RankSubject {
    CharacterId id{};
    std::string name;
    std::uint8_t sect = 0;
    std::uint8_t sex = 0;
};

struct RankEntry {
    CharacterId id{};
    std::string name;
    std::uint8_t sect = 0;
    std::uint8_t sex = 0;
    std::int64_t score = 0;
    Tick since{};  // tick điểm hiện tại được ghi: hòa điểm thì ai ghi trước đứng trên
};

struct RankBoard {
    BoardId id{};
    std::string name;
    std::uint32_t capacity = 0;
    std::vector<RankEntry> live;       // bảng sống, đã xếp
    std::vector<RankEntry> published;  // ảnh chụp gần nhất, đã xếp
    Tick published_at{};
    Tick next_snapshot{};
};

enum class RankEventKind : std::uint8_t {
    kEntered,   // subject vào bảng: new_rank
    kMoved,     // điểm của subject đổi: old_rank -> new_rank
    kDropped,   // subject rời bảng (bị đẩy ra hay bị xoá): old_rank
    kSnapshot,  // bảng vừa chụp ảnh mới
};

struct RankEvent {
    RankEventKind kind = RankEventKind::kMoved;
    BoardId board{};
    CharacterId subject{};
    std::uint32_t old_rank = 0;  // 1 là hạng nhất; 0 = chưa có hạng
    std::uint32_t new_rank = 0;
    std::int64_t score = 0;
};

using RankEvents = std::vector<RankEvent>;
using RankResult = Outcome<RankEvent, RankError>;

struct RankBoardDef {
    BoardId id{};
    std::string name;
    std::uint32_t capacity = 0;  // 0 = rank_default_capacity
};

// Bảng định nghĩa các bảng xếp hạng (dev/server/tables/server/rank_boards.tsv do import_social.py sinh).
[[nodiscard]] std::expected<std::vector<RankBoardDef>, std::string> parse_rank_boards(std::string_view tsv_text);

class RankBook {
public:
    explicit RankBook(const Limits& limits);

    // Khai báo một bảng; lần chụp đầu sau rank_snapshot_interval kể từ `now`.
    [[nodiscard]] std::expected<void, RankError> define(Tick now, const RankBoardDef& def);
    [[nodiscard]] std::expected<void, RankError> define_all(Tick now, std::span<const RankBoardDef> defs);

    // Ghi điểm của một người. Người đã có dòng thì thay điểm (tăng hay giảm đều được); điểm bằng nhau chỉ
    // làm mới hiển thị. Bảng đầy mà không hơn dòng chót thì không vào (ok, không sự kiện). Chuỗi sự kiện: nhập
    // bảng/đổi hạng cho subject, kèm kDropped cho người bị đẩy ra.
    [[nodiscard]] RankResult submit(Tick now, BoardId board, const RankSubject& subject, std::int64_t score);


    // Nhân vật bị xoá: gỡ khỏi mọi bảng (cả ảnh đã công bố).
    [[nodiscard]] RankEvents forget(CharacterId who);

    // Chụp ảnh các bảng đến hạn.
    [[nodiscard]] RankEvents tick(Tick now);
    // Chốt kỳ: chụp ảnh ngay, hẹn lần kế sau một nhịp.
    [[nodiscard]] RankResult settle(Tick now, BoardId board);

    [[nodiscard]] const RankBoard* board(BoardId id) const;
    // Hạng (từ 1) trong bảng sống / ảnh đã công bố; nullopt = không có trong bảng.
    [[nodiscard]] std::optional<std::uint32_t> rank_of(BoardId board, CharacterId who) const;
    [[nodiscard]] std::optional<std::uint32_t> published_rank_of(BoardId board, CharacterId who) const;
    [[nodiscard]] std::size_t board_count() const noexcept { return boards_.size(); }

    // Nạp một bảng đọc từ kho (kiểm hình dạng đầy đủ; bảng trùng id thì lỗi).
    [[nodiscard]] std::expected<void, std::string> load(RankBoard incoming);
    [[nodiscard]] std::expected<void, std::string> validate() const;

private:
    [[nodiscard]] RankBoard* mutable_board(BoardId id);

    Limits limits_;
    TickSpan snapshot_every_{};
    std::map<BoardId, RankBoard> boards_;
};

// Thứ tự xếp hạng: điểm cao trước, hòa thì ghi trước, hòa nữa thì id nhỏ trước.
[[nodiscard]] bool rank_before(const RankEntry& left, const RankEntry& right) noexcept;

// Hình dạng đúng của một bảng (dùng khi nạp và giải mã): xếp đúng thứ tự, không trùng id, trong sức chứa.
[[nodiscard]] std::string_view rank_board_problem(const RankBoard& board);

// Một bảng là một khối bền (blob::kRank) gồm bảng sống và ảnh đã công bố. Khối tối đa 64 KiB nên mỗi bảng
// giữ được chừng 300 dòng (mỗi dòng ≤ 100 byte, hai danh sách); bảng lớn hơn trả CodecError::kTooLarge và
// bên gọi phải chia nhỏ bảng.
[[nodiscard]] CodecResult encode_rank(const RankBoard& board, Tick now, Bytes& out);
[[nodiscard]] std::expected<RankBoard, CodecError> decode_rank(std::span<const std::byte> bytes, Tick now);

} // namespace game::social
