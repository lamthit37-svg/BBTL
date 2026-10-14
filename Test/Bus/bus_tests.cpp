// Hàng đợi sự kiện: sai thứ tự xả hoặc để sự kiện đệ quy kéo dài lượt thì kết quả nhiệm vụ phụ thuộc thứ tự các hệ phát,
// chạy và nhìn không lộ. Ghim thứ tự xả cố định, ổn định trong cùng loại, tách lượt và trần dung lượng.
#include "bus/bus.hpp"
#include "test.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::test {
namespace {

using bus::Bus;
using bus::Event;
using bus::Kind;

// NOLINTNEXTLINE(bugprone-easily-swappable-parameters): loại, tham số a và mã nhân vật khác vai, nơi gọi nêu tên (HP-07)
Event make(Kind kind, std::uint32_t a, std::uint64_t hero = 1) {
    Event event;
    event.kind = kind;
    event.a = a;
    event.hero = ids::CharacterId{hero};
    return event;
}

void drains_in_fixed_kind_order(Context& context) {
    Bus bus(16);
    // Phát lộn xộn giữa các loại, thứ tự trong cùng loại là 1, 2, 3.
    const std::array<Event, 7> published{make(Kind::kItemChanged, 1), make(Kind::kKill, 1), make(Kind::kTalk, 1),
        make(Kind::kKill, 2), make(Kind::kLevelUp, 1), make(Kind::kItemChanged, 2), make(Kind::kKill, 3)};
    for (const Event& event : published) context.expect(bus.publish(event), "publish");
    const auto batch = bus.take();
    const std::array<Event, 7> expected{make(Kind::kLevelUp, 1), make(Kind::kTalk, 1), make(Kind::kKill, 1),
        make(Kind::kKill, 2), make(Kind::kKill, 3), make(Kind::kItemChanged, 1), make(Kind::kItemChanged, 2)};
    context.expect(batch.size() == expected.size() && std::ranges::equal(batch, expected),
        "sắp theo loại, ổn định trong cùng loại");
    context.expect(bus.pending() == 0 && bus.take().empty(), "lượt sau rỗng");
}

void order_does_not_depend_on_publishing_system(Context& context) {
    // Hai hệ phát cùng tick theo hai thứ tự khác nhau: lượt xả của các loại khác nhau phải như nhau.
    const auto run = [](bool kill_first) {
        Bus bus(8);
        if (kill_first) {
            static_cast<void>(bus.publish(make(Kind::kKill, 7)));
            static_cast<void>(bus.publish(make(Kind::kEnterArea, 3)));
        } else {
            static_cast<void>(bus.publish(make(Kind::kEnterArea, 3)));
            static_cast<void>(bus.publish(make(Kind::kKill, 7)));
        }
        const auto batch = bus.take();
        return std::vector<Event>(batch.begin(), batch.end());
    };
    context.expect(run(true) == run(false), "thứ tự hệ phát không đổi kết quả");
}

void events_published_while_handling_wait_for_next_take(Context& context) {
    Bus bus(8);
    static_cast<void>(bus.publish(make(Kind::kKill, 1)));
    const auto batch = bus.take();
    std::size_t handled = 0;
    for (const Event& event : batch) {
        ++handled;
        // Xử lý một kill sinh ra item_changed: nó thuộc lượt sau, không chen vào lượt đang duyệt.
        context.expect(bus.publish(make(Kind::kItemChanged, event.a)), "phát trong lúc duyệt");
    }
    context.expect(handled == 1 && batch.size() == 1, "lượt hiện tại không dài thêm");
    context.expect(bus.pending() == 1, "chờ lượt sau");
    const auto next = bus.take();
    context.expect(next.size() == 1 && next[0].kind == Kind::kItemChanged, "lượt sau có sự kiện mới");
}

void capacity_is_bounded(Context& context) {
    Bus bus(3);
    context.expect(bus.publish(make(Kind::kKill, 1)) && bus.publish(make(Kind::kKill, 2)) && bus.publish(make(Kind::kKill, 3)),
        "đủ chỗ");
    context.expect(!bus.publish(make(Kind::kKill, 4)) && !bus.publish(make(Kind::kTalk, 5)), "đầy thì từ chối");
    context.expect(bus.dropped() == 2 && bus.pending() == 3, "đếm sự kiện bị bỏ");
    context.expect(bus.take().size() == 3, "ba sự kiện đầu còn nguyên");
    context.expect(bus.publish(make(Kind::kKill, 9)), "xả xong lại có chỗ");
    Event bad = make(Kind::kKill, 1);
    bad.kind = static_cast<Kind>(77);
    context.expect(!bus.publish(bad) && bus.dropped() == 3, "loại sự kiện ngoài tập bị từ chối");
    Bus empty(0);
    context.expect(!empty.publish(make(Kind::kKill, 1)) && empty.take().empty(), "dung lượng 0");
}

constexpr std::array kCases{
    Case{.name = "drains_in_fixed_kind_order", .body = drains_in_fixed_kind_order},
    Case{.name = "order_does_not_depend_on_publishing_system", .body = order_does_not_depend_on_publishing_system},
    Case{.name = "events_published_while_handling_wait_for_next_take", .body = events_published_while_handling_wait_for_next_take},
    Case{.name = "capacity_is_bounded", .body = capacity_is_bounded},
};

}  // namespace
}  // namespace game::test

int main() { return game::test::run_all(game::test::kCases) == 0 ? 0 : 1; }
