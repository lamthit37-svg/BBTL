#pragma once
// Sổ nhiệm vụ của một nhân vật phía máy chủ: 20 ô đang giữ, 4096 bit "đã xong", bộ đếm và cờ dữ liệu nhiệm vụ, nhật ký sổ
// cái chống gửi lại. Bố cục ô và bit khớp từng trường với `Slot` của client (src/client/book/quest/log.hpp: id nhiệm vụ,
// id script, cờ, 8 tham số), vì máy chủ ghi đúng sổ này xuống client; test mission_wire_tests đối chiếu cả hai bằng static_assert.
//
// Tham số của ô: ở nhiệm vụ bảng, tham số 0 là cờ "đã đủ điều kiện nộp" và tham số 1 + i là tiến độ mục tiêu thứ i; ở nhiệm
// vụ script, chỉ số tham số do script khai (mục tiêu `progress` đọc đúng chỉ số đó).
//
// Giá trị thuần, không I/O. Bộ đếm và cờ có trần (kMaxCounters, kMaxFlags): script thù địch không làm sổ phình vô hạn.

#include "ledger/ledger.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::mission {

inline constexpr std::size_t kSlotCount = 20;
inline constexpr std::size_t kParamCount = 8;
inline constexpr std::size_t kDoneWords = 128;
inline constexpr std::int32_t kDoneBits = 32;
inline constexpr std::int32_t kQuestIdLimit = static_cast<std::int32_t>(kDoneWords) * kDoneBits;  // id hợp lệ: 0..4095
inline constexpr std::size_t kMaxCounters = 512;
inline constexpr std::size_t kMaxFlags = 512;
inline constexpr std::int32_t kNoMission = -1;
inline constexpr std::int64_t kCounterLimit = std::int64_t{1} << 40;  // |giá trị bộ đếm| tối đa

// Bit của Slot::flags: sự kiện nào cần chuyển cho nhiệm vụ này (như pKill/pArea/pItem của AddMission gốc).
inline constexpr std::uint8_t kWatchKill = 1;
inline constexpr std::uint8_t kWatchArea = 2;
inline constexpr std::uint8_t kWatchItem = 4;
inline constexpr std::uint8_t kWatchMask = 7;

struct Slot {
    std::int32_t mission = kNoMission;
    std::int32_t script = kNoMission;
    std::uint8_t flags = 0;
    std::array<std::uint32_t, kParamCount> params{};

    [[nodiscard]] bool used() const noexcept { return mission != kNoMission; }
    friend bool operator==(const Slot&, const Slot&) noexcept = default;
};

struct Counter {
    std::int32_t index = 0;
    std::int64_t value = 0;
    friend bool operator==(const Counter&, const Counter&) noexcept = default;
};

class Book {
public:
    std::array<Slot, kSlotCount> slots{};
    std::array<std::uint32_t, kDoneWords> done{};
    std::vector<Counter> counters;      // tăng ngặt theo index, không lưu giá trị 0
    std::vector<std::int32_t> flags;    // tăng ngặt
    ledger::Journal journal;
    std::uint64_t ledger_seq = 0;       // mã yêu cầu sổ cái đã cấp; cấp tiếp là ledger_seq + 1

    // ----- ô -----
    [[nodiscard]] const Slot* find(std::int32_t quest) const noexcept;
    [[nodiscard]] Slot* find(std::int32_t quest) noexcept;
    [[nodiscard]] std::int32_t active() const noexcept;
    [[nodiscard]] std::int32_t free_slots() const noexcept;
    // Thêm vào ô trống đầu tiên. nullptr khi sổ đầy, đang giữ rồi hoặc id ngoài 0..4095.
    Slot* add(std::int32_t quest, std::int32_t script, std::uint8_t watch) noexcept;
    bool remove(std::int32_t quest) noexcept;

    // ----- đã xong -----
    [[nodiscard]] bool is_done(std::int32_t quest) const noexcept;
    void mark_done(std::int32_t quest) noexcept;
    void clear_done(std::int32_t quest) noexcept;

    // ----- bộ đếm và cờ -----
    [[nodiscard]] std::int64_t counter(std::int32_t index) const noexcept;
    // false khi index âm, |giá trị| quá trần hoặc đã đủ kMaxCounters ô khác 0.
    [[nodiscard]] bool set_counter(std::int32_t index, std::int64_t value);
    [[nodiscard]] bool flag(std::int32_t index) const noexcept;
    [[nodiscard]] bool set_flag(std::int32_t index, bool on);

    // Cấp mã yêu cầu sổ cái kế tiếp.
    [[nodiscard]] std::uint64_t next_request() noexcept { return ++ledger_seq; }

    friend bool operator==(const Book&, const Book&) = default;
};

// Sổ có hợp lệ không: ô không trùng nhiệm vụ, id trong miền, cờ trong mặt nạ, bộ đếm/cờ tăng ngặt trong trần, mã sổ cái
// không vượt ledger_seq. Bộ giải mã bắt buộc kiểm trước khi gán.
[[nodiscard]] bool well_formed(const Book& book) noexcept;

}  // namespace game::mission
