// Sổ nhiệm vụ và bản ghi nhị phân: sai thì nhân vật mất hoặc nhân đôi tiến độ nhiệm vụ khi lưu/nạp mà nhìn không ra, và khối
// hỏng từ ổ đĩa hay kẻ tấn công không được để lại gì trong Book. Ghim: bố cục khớp client, giới hạn của ô/bộ đếm/cờ, vòng
// mã hoá-giải mã trên sổ ngẫu nhiên hạt giống cố định, và mọi cách cắt cụt / lật byte / ép giá trị sai.
#include "dice/dice.hpp"
#include "ledger/ledger.hpp"
#include "mission/book.hpp"
#include "mission/codec.hpp"
#include "protocol/wire.hpp"
#include "quest/log.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <span>
#include <utility>
#include <vector>

namespace game::test {
namespace {

using mission::Book;
using mission::Slot;

// Bố cục trùng client (src/client/book/quest/log.hpp): máy chủ ghi đúng sổ này xuống client.
static_assert(mission::kSlotCount == quest::kSlotCount);
static_assert(mission::kParamCount == quest::kParamCount);
static_assert(mission::kDoneWords == quest::kDoneWords);
static_assert(mission::kDoneBits == quest::kDoneBits);
static_assert(mission::kNoMission == quest::kNoMission);
static_assert(sizeof(mission::Slot) == sizeof(quest::Slot));
static_assert(sizeof(mission::Slot::params) == sizeof(quest::Slot::params));

void layout_matches_client(Context& context) {
    quest::Log client;
    Book server;
    for (const std::int32_t id : {0, 1, 31, 32, 33, 1000, 4094, 4095}) {
        quest::mark_done(client, id);
        server.mark_done(id);
    }
    context.expect(std::ranges::equal(client.done, server.done), "cùng từ bit 'đã xong'");
    for (const std::int32_t id : {-1, 0, 5, 4095, 4096, 100000}) {
        context.expect(quest::is_done(client, id) == server.is_done(id), "is_done khớp client");
    }
    context.expect(server.slots.at(0).mission == client.slots.at(0).mission && server.slots.at(0).script == client.slots.at(0).script,
        "ô trống khớp");
}

void slots_obey_limits(Context& context) {
    Book book;
    context.expect(book.active() == 0 && book.free_slots() == 20, "sổ mới trống");
    context.expect(book.add(5, 100, mission::kWatchKill) != nullptr, "thêm");
    context.expect(book.add(5, 100, 0) == nullptr, "trùng nhiệm vụ bị từ chối");
    context.expect(book.add(-1, 1, 0) == nullptr && book.add(4096, 1, 0) == nullptr, "id ngoài miền");
    context.expect(book.find(5) != nullptr && book.find(5)->script == 100 && book.find(5)->flags == mission::kWatchKill, "tìm thấy");
    const Slot* const first = book.find(5);
    context.expect(first != nullptr && first->params == std::array<std::uint32_t, 8>{}, "tham số bắt đầu bằng 0");
    for (std::int32_t quest_id = 10; quest_id < 29; ++quest_id) {
        context.expect(book.add(quest_id, quest_id, 0xFF) != nullptr, "đủ chỗ cho 20 ô");
    }
    context.expect(book.free_slots() == 0 && book.add(500, 1, 0) == nullptr, "đủ 20 ô thì từ chối");
    context.expect(book.find(12)->flags == mission::kWatchMask, "cờ ngoài mặt nạ bị cắt");
    context.expect(book.remove(5) && !book.remove(5) && book.free_slots() == 1, "bỏ rồi bỏ lại");
    context.expect(book.add(500, 1, 0) != nullptr, "ô trống được dùng lại");
    context.expect(book.find(-1) == nullptr, "id -1 không bao giờ tìm thấy ô trống");
}

void counters_and_flags_are_bounded(Context& context) {
    Book book;
    context.expect(book.counter(7) == 0 && !book.flag(7), "mặc định 0 và tắt");
    context.expect(book.set_counter(1000030, 5) && book.counter(1000030) == 5, "chỉ số lớn của script");
    context.expect(book.set_counter(3, -4) && book.counter(3) == -4, "giá trị âm");
    context.expect(book.counters.size() == 2 && book.counters[0].index == 3, "sắp theo chỉ số");
    context.expect(book.set_counter(3, 0) && book.counters.size() == 1, "đặt 0 là xoá");
    context.expect(!book.set_counter(-1, 1) && !book.set_counter(1, mission::kCounterLimit + 1) &&
                       !book.set_counter(1, -mission::kCounterLimit - 1),
        "ngoài miền");
    for (std::int32_t index = 0; index < static_cast<std::int32_t>(mission::kMaxCounters) - 1; ++index) {
        context.expect(book.set_counter(index, 1), "đủ chỗ");
    }
    context.expect(book.counters.size() == mission::kMaxCounters && !book.set_counter(900000, 1), "đầy bộ đếm");
    context.expect(book.set_counter(0, 9) && book.counter(0) == 9, "đổi giá trị ô có sẵn khi đầy vẫn được");
    context.expect(book.set_flag(8, true) && book.set_flag(2, true) && book.flag(2) && book.flags[0] == 2, "cờ sắp tăng");
    context.expect(book.set_flag(2, false) && !book.flag(2) && book.set_flag(2, false), "tắt cờ");
    context.expect(!book.set_flag(-3, true), "cờ âm");
    for (std::int32_t index = 100; book.flags.size() < mission::kMaxFlags; ++index) {
        context.expect(book.set_flag(index, true), "đủ chỗ cờ");
    }
    context.expect(!book.set_flag(99999, true) && book.set_flag(100, true), "đầy cờ");
}

void well_formed_catches_corruption(Context& context) {
    Book clean;
    static_cast<void>(clean.add(3, 30, 1));
    static_cast<void>(clean.set_counter(5, 5));
    context.expect(mission::well_formed(clean), "sổ sạch");
    Book dup = clean;
    dup.slots.at(1) = dup.slots.at(0);
    context.expect(!mission::well_formed(dup), "trùng nhiệm vụ giữa hai ô");
    Book dirty = clean;
    dirty.slots.at(7).params.at(0) = 9;  // ô trống mà có tham số
    context.expect(!mission::well_formed(dirty), "ô trống không sạch");
    Book bad_flags = clean;
    bad_flags.slots.at(0).flags = 0x80;
    context.expect(!mission::well_formed(bad_flags), "cờ ngoài mặt nạ");
    Book unsorted = clean;
    unsorted.counters.push_back({.index = 2, .value = 1});
    context.expect(!mission::well_formed(unsorted), "bộ đếm không tăng");
    Book zero = clean;
    zero.counters.push_back({.index = 9, .value = 0});
    context.expect(!mission::well_formed(zero), "bộ đếm 0 không được lưu");
    Book journal = clean;
    journal.journal.record(9, ledger::Reason::kCommitted);
    context.expect(!mission::well_formed(journal), "mã nhật ký vượt ledger_seq");
}

Book random_book(dice::Dice& rng) {
    Book book;
    for (std::int64_t one = rng.between(0, 20); one > 0; --one) {
        Slot* const slot = book.add(static_cast<std::int32_t>(rng.below(4096)), static_cast<std::int32_t>(rng.between(-1, 2000000)),
            static_cast<std::uint8_t>(rng.below(8)));
        if (slot == nullptr) continue;
        for (std::uint32_t& param : slot->params) param = static_cast<std::uint32_t>(rng.next_u64());
    }
    for (std::int64_t one = rng.between(0, 300); one > 0; --one) book.mark_done(static_cast<std::int32_t>(rng.below(4096)));
    for (std::int64_t one = rng.between(0, 40); one > 0; --one) {
        static_cast<void>(book.set_counter(static_cast<std::int32_t>(rng.below(2000000)), rng.between(-5000000000LL, 5000000000LL)));
    }
    for (std::int64_t one = rng.between(0, 40); one > 0; --one) static_cast<void>(book.set_flag(static_cast<std::int32_t>(rng.below(900)), true));
    book.ledger_seq = static_cast<std::uint64_t>(rng.between(0, 500));
    for (std::uint64_t id = 1; id <= std::min<std::uint64_t>(book.ledger_seq, 40); ++id) {
        book.journal.record(id, id % 3 == 0 ? ledger::Reason::kNoRoom : ledger::Reason::kCommitted);
    }
    return book;
}

void round_trip_random_books(Context& context) {
    dice::Dice rng(0xB00C);
    bool all_equal = true;
    std::size_t biggest = 0;
    for (int round = 0; round < 500; ++round) {
        const Book book = random_book(rng);
        const auto blob = mission::encode(book);
        context.expect(blob.has_value(), "mã hoá được");
        if (!blob) continue;
        biggest = std::max(biggest, blob->size());
        Book decoded;
        decoded.ledger_seq = 999;  // phải bị thay hoàn toàn
        const auto status = mission::decode(*blob, decoded);
        all_equal = all_equal && status.has_value() && decoded == book;
    }
    context.expect(all_equal, "500 sổ ngẫu nhiên: giải mã ra đúng sổ đã mã hoá");
    context.expect(biggest < protocol::kMaxBodyBytes, "mọi sổ nằm trong trần khung");
    Book empty;
    const auto blob = mission::encode(empty);
    context.expect(blob.has_value() && blob->size() < 80, "sổ rỗng nhỏ");
}

void encode_refuses_malformed_book(Context& context) {
    Book broken;
    broken.slots.at(0).mission = 7;
    broken.slots.at(1).mission = 7;
    const auto blob = mission::encode(broken);
    context.expect(!blob.has_value() && blob.error() == mission::CodecError::kEncodeFailed, "không mã hoá sổ sai");
}

Book sample_book() {
    Book book;
    static_cast<void>(book.add(40, 123456, mission::kWatchKill | mission::kWatchItem));
    book.find(40)->params = {1, 2, 3, 4, 5, 6, 7, 8};
    static_cast<void>(book.add(7, 7, 0));
    book.mark_done(100);
    book.mark_done(4095);
    static_cast<void>(book.set_counter(91, 1778000000));
    static_cast<void>(book.set_flag(12, true));
    book.ledger_seq = 3;
    book.journal.record(1, ledger::Reason::kCommitted);
    book.journal.record(3, ledger::Reason::kMissingItems);
    return book;
}

void truncations_and_flips_are_safe(Context& context) {
    const Book original = sample_book();
    const auto blob = mission::encode(original);
    context.expect(blob.has_value(), "mẫu mã hoá được");
    if (!blob) return;
    Book into = original;
    into.ledger_seq = 42;
    const Book before = into;
    bool truncation_safe = true;
    for (std::size_t length = 0; length < blob->size(); ++length) {
        const auto status = mission::decode(std::span<const std::byte>(blob->data(), length), into);
        truncation_safe = truncation_safe && !status.has_value() && into == before;
    }
    context.expect(truncation_safe, "mọi độ dài cắt cụt đều bị từ chối và không đổi gì");
    std::vector<std::byte> longer = *blob;
    longer.push_back(std::byte{0});
    context.expect(!mission::decode(longer, into).has_value() && into == before, "byte thừa");
    bool flips_safe = true;
    for (std::size_t position = 0; position < blob->size(); ++position) {
        for (const unsigned mask : {0x01U, 0x80U, 0xFFU}) {
            std::vector<std::byte> copy = *blob;
            copy[position] = static_cast<std::byte>(static_cast<unsigned>(copy[position]) ^ mask);
            Book target = before;
            const auto status = mission::decode(copy, target);
            if (!status.has_value()) {
                flips_safe = flips_safe && target == before;
            } else {
                flips_safe = flips_safe && mission::well_formed(target) && mission::encode(target).has_value();
            }
        }
    }
    context.expect(flips_safe, "lật byte: hoặc bị từ chối không đổi gì, hoặc ra sổ hợp lệ mã hoá lại được");
}

// Dựng thân thù địch theo bố cục phiên bản 1 để ép từng giá trị sai.
struct Crafted {
    std::uint16_t version = mission::kCodecVersion;
    std::uint64_t seq = 10;
    std::uint64_t floor = 0;
    struct JournalRow {
        std::uint64_t request = 0;
        std::uint8_t reason = 0;
    };
    std::vector<JournalRow> journal;
    struct SlotSpec {
        std::uint8_t index = 0;
        std::int32_t mission = 5;
        std::int32_t script = 5;
        std::uint8_t flags = 0;
    };
    std::vector<SlotSpec> slots;
    struct DoneWord {
        std::uint8_t word = 0;
        std::uint32_t bits = 0;
    };
    std::vector<DoneWord> done;
    struct CounterRow {
        std::int32_t index = 0;
        std::int64_t value = 0;
    };
    std::vector<CounterRow> counters;
    std::vector<std::int32_t> flag_list;
    std::uint16_t kind = mission::kBlobBook;

    [[nodiscard]] std::vector<std::byte> bytes() const {
        std::vector<std::byte> out;
        protocol::Writer w(out);
        w.u16(version);
        w.u64(seq);
        w.u64(floor);
        w.count(journal.size(), 1000);
        for (const JournalRow& row : journal) {
            w.u64(row.request);
            w.u8(row.reason);
        }
        w.count(slots.size(), 1000);
        for (const SlotSpec& slot : slots) {
            w.u8(slot.index);
            w.i32(slot.mission);
            w.i32(slot.script);
            w.u8(slot.flags);
            for (int param = 0; param < 8; ++param) w.u32(0);
        }
        w.count(done.size(), 1000);
        for (const DoneWord& row : done) {
            w.u8(row.word);
            w.u32(row.bits);
        }
        w.count(counters.size(), 2000);
        for (const CounterRow& row : counters) {
            w.i32(row.index);
            w.i64(row.value);
        }
        w.count(flag_list.size(), 2000);
        for (const std::int32_t flag : flag_list) w.i32(flag);
        const auto status = w.finish(kind);
        if (!status) out.clear();  // khung không đóng được thì không có byte nào để thử
        return out;
    }
};

void hostile_values_are_refused(Context& context) {
    const Book before = sample_book();
    const auto refused = [&](const Crafted& crafted) {
        Book target = before;
        const std::vector<std::byte> bytes = crafted.bytes();
        const auto status = mission::decode(bytes, target);
        return !status.has_value() && target == before;
    };
    context.expect(!refused(Crafted{}), "mẫu sạch phải qua (đối chứng cho các ca dưới)");
    Crafted c;
    c.version = 2;
    context.expect(refused(c), "phiên bản lạ");
    c = {};
    c.kind = 0x7001;
    context.expect(refused(c), "khung sai loại");
    c = {};
    c.slots = {{.index = 0, .mission = 5, .script = 5, .flags = 0}, {.index = 0, .mission = 6, .script = 6, .flags = 0}};
    context.expect(refused(c), "hai ô cùng chỉ số");
    c = {};
    c.slots = {{.index = 0, .mission = 5, .script = 5, .flags = 0}, {.index = 1, .mission = 5, .script = 6, .flags = 0}};
    context.expect(refused(c), "hai ô cùng nhiệm vụ");
    c = {};
    c.slots = {{.index = 20, .mission = 5, .script = 5, .flags = 0}};
    context.expect(refused(c), "chỉ số ô 20");
    c = {};
    c.slots = {{.index = 0, .mission = -1, .script = 5, .flags = 0}};
    context.expect(refused(c), "ô dùng mà nhiệm vụ -1");
    c = {};
    c.slots = {{.index = 0, .mission = 4096, .script = 5, .flags = 0}};
    context.expect(refused(c), "nhiệm vụ 4096");
    c = {};
    c.slots = {{.index = 0, .mission = 5, .script = -2, .flags = 0}};
    context.expect(refused(c), "script -2");
    c = {};
    c.slots = {{.index = 0, .mission = 5, .script = 5, .flags = 0x10}};
    context.expect(refused(c), "cờ ngoài mặt nạ");
    c = {};
    c.done = {{.word = 128, .bits = 1}};
    context.expect(refused(c), "từ 'đã xong' số 128");
    c = {};
    c.done = {{.word = 3, .bits = 0}};
    context.expect(refused(c), "từ 'đã xong' bằng 0 không được lưu");
    c = {};
    c.done = {{.word = 4, .bits = 1}, {.word = 4, .bits = 2}};
    context.expect(refused(c), "từ 'đã xong' trùng");
    c = {};
    c.done = {{.word = 5, .bits = 1}, {.word = 4, .bits = 2}};
    context.expect(refused(c), "từ 'đã xong' không tăng");
    c = {};
    c.counters = {{.index = 5, .value = 1}, {.index = 4, .value = 1}};
    context.expect(refused(c), "bộ đếm không tăng");
    c = {};
    c.counters = {{.index = 5, .value = 0}};
    context.expect(refused(c), "bộ đếm bằng 0");
    c = {};
    c.counters = {{.index = -1, .value = 5}};
    context.expect(refused(c), "chỉ số bộ đếm âm");
    c = {};
    c.counters = {{.index = 1, .value = mission::kCounterLimit + 1}};
    context.expect(refused(c), "bộ đếm quá trần");
    c = {};
    for (std::int32_t index = 0; std::cmp_less_equal(index, mission::kMaxCounters); ++index) c.counters.push_back({.index = index, .value = 1});
    context.expect(refused(c), "quá nhiều bộ đếm");
    c = {};
    c.flag_list = {3, 3};
    context.expect(refused(c), "cờ trùng");
    c = {};
    c.flag_list = {-4};
    context.expect(refused(c), "cờ âm");
    c = {};
    for (std::uint64_t id = 1; id <= ledger::kJournalSize + 1; ++id) c.journal.push_back({.request = id, .reason = 0});
    c.seq = 100;
    context.expect(refused(c), "nhật ký quá cỡ");
    c = {};
    c.journal = {{.request = 4, .reason = 99}};
    context.expect(refused(c), "lý do ngoài tập");
    c = {};
    c.journal = {{.request = 0, .reason = 0}};
    context.expect(refused(c), "mã nhật ký 0");
    c = {};
    c.journal = {{.request = 4, .reason = 0}, {.request = 4, .reason = 1}};
    context.expect(refused(c), "mã nhật ký trùng");
    c = {};
    c.seq = 3;
    c.journal = {{.request = 4, .reason = 0}};
    context.expect(refused(c), "mã nhật ký lớn hơn ledger_seq");
    c = {};
    c.seq = 3;
    c.floor = 4;
    context.expect(refused(c), "mốc nhật ký lớn hơn ledger_seq");
}

constexpr std::array kCases{
    Case{.name = "layout_matches_client", .body = layout_matches_client},
    Case{.name = "slots_obey_limits", .body = slots_obey_limits},
    Case{.name = "counters_and_flags_are_bounded", .body = counters_and_flags_are_bounded},
    Case{.name = "well_formed_catches_corruption", .body = well_formed_catches_corruption},
    Case{.name = "round_trip_random_books", .body = round_trip_random_books},
    Case{.name = "encode_refuses_malformed_book", .body = encode_refuses_malformed_book},
    Case{.name = "truncations_and_flips_are_safe", .body = truncations_and_flips_are_safe},
    Case{.name = "hostile_values_are_refused", .body = hostile_values_are_refused},
};

}  // namespace
}  // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
