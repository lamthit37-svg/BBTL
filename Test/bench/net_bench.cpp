// Đo lịch lane với lõi GNS v1.6.1 (d534c19), steamnetworkingsockets_snp.cpp
// khoảng 2581-2602 và 2686: mỗi lần chọn quét hết lane, thời gian ảo là float.
// LaneQueue của ta dùng số nguyên và bỏ lane rỗng. Chạy Release.
#include "net/carrier.hpp"
#include "net/shard.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <span>
#include <vector>

namespace {

// Hàng tin của SNP là danh sách liên kết. Mỗi lần chọn quét mọi lane trong lớp ưu tiên.
struct GnsMsg {
    float finish = 0.F;
    GnsMsg* next = nullptr;
};

struct GnsLane {
    GnsMsg* head = nullptr;
    float factor = 1.F;
    float virt = 0.F;
};

struct GnsPick {
    int index = -1;
    float finish = 0.F;
    bool found = false;
};

void note_lane(const GnsLane& lane, int index, GnsPick& best) noexcept {
    const GnsMsg* message = lane.head;
    if (message == nullptr) return;
    if (best.found && message->finish >= best.finish) return;
    best.index = index;
    best.finish = message->finish;
    best.found = true;
}

int gns_pick(const std::array<GnsLane, 4>& lanes) noexcept {
    GnsPick best;
    for (int index = 0; index < 4; ++index) note_lane(lanes[static_cast<std::size_t>(index)], index, best);
    return best.index;
}

void gns_take(GnsLane& lane) noexcept {
    GnsMsg* message = lane.head;
    lane.head = message->next;
    lane.virt += lane.factor;
    message->finish = lane.virt;
}

std::int64_t nanos(std::chrono::steady_clock::duration span) noexcept {
    return std::chrono::duration_cast<std::chrono::nanoseconds>(span).count();
}

std::int64_t time_gns(int per_lane) {
    std::vector<GnsMsg> messages(static_cast<std::size_t>(per_lane) * 4U);
    std::array<GnsLane, 4> lanes{};
    for (int lane = 0; lane < 4; ++lane) {
        const std::size_t base = static_cast<std::size_t>(lane * per_lane);
        lanes[static_cast<std::size_t>(lane)].head = &messages[base];
        lanes[static_cast<std::size_t>(lane)].factor = 1.F + static_cast<float>(lane);
        for (int item = 0; item < per_lane; ++item) {
            const std::size_t at = base + static_cast<std::size_t>(item);
            messages[at].finish = static_cast<float>(item);
            if (item + 1 < per_lane) messages[at].next = &messages[at + 1];
        }
    }
    volatile int sink = 0;
    const auto start = std::chrono::steady_clock::now();
    const int total = per_lane * 4;
    for (int step = 0; step < total; ++step) {
        const int pick = gns_pick(lanes);
        gns_take(lanes[static_cast<std::size_t>(pick)]);
        sink += pick;
    }
    const auto elapsed = nanos(std::chrono::steady_clock::now() - start);
    if (sink < 0) return elapsed;
    return elapsed;
}

std::int64_t time_ours(int per_lane) {
    constexpr std::array<game::net::LaneSpec, 4> specs{{
        {.priority = 1, .weight = 1},
        {.priority = 1, .weight = 1},
        {.priority = 1, .weight = 1},
        {.priority = 1, .weight = 1},
    }};
    game::net::LaneQueue<int> queue;
    queue.reset(specs);
    for (int lane = 0; lane < 4; ++lane) {
        for (int item = 0; item < per_lane; ++item) queue.push(static_cast<std::size_t>(lane), item);
    }
    volatile int sink = 0;
    const auto start = std::chrono::steady_clock::now();
    std::array<int, 64> batch{};
    while (queue.size() > 0) {
        const std::size_t count = queue.pop(batch);
        sink += static_cast<int>(count);
    }
    return nanos(std::chrono::steady_clock::now() - start);
}

int shuttle_batch(game::net::Carrier& sender, game::net::Carrier& receiver, int count, std::uint64_t now) {
    std::array<std::byte, game::net::kCarrierPacketBytes> buf{};
    std::size_t written = 0;
    while (sender.write_packet(buf, written, now)) {
        const auto view = std::span<const std::byte>{buf.data(), written};
        if (!receiver.read_packet(view, now)) return -1;
    }
    std::size_t ack = 0;
    while (receiver.write_packet(buf, ack, now)) {
        const auto view = std::span<const std::byte>{buf.data(), ack};
        if (!sender.read_packet(view, now)) return -1;
    }
    int taken = 0;
    game::net::CarrierMessage message;
    while (receiver.take(message)) ++taken;
    if (taken != count) return -1;
    return taken;
}

std::int64_t time_carrier(int messages) {
    game::net::Carrier sender;
    game::net::Carrier receiver;
    std::array<std::byte, 64> body{};
    body[0] = std::byte{1};
    const auto start = std::chrono::steady_clock::now();
    int sent = 0;
    while (sent < messages) {
        const int room = std::min(128, messages - sent);
        for (int index = 0; index < room; ++index) {
            const auto lane = static_cast<std::uint8_t>((sent + index) % 4);
            if (!sender.send(lane, game::net::Delivery::kReliable, body)) return -1;
        }
        const auto now = static_cast<std::uint64_t>(sent);
        if (shuttle_batch(sender, receiver, room, now) < 0) return -1;
        sent += room;
    }
    return nanos(std::chrono::steady_clock::now() - start);
}

} // namespace

int main() {
    constexpr int kPerLane = 200000;
    const std::int64_t gns = time_gns(kPerLane);
    const std::int64_t ours = time_ours(kPerLane);
    const std::int64_t shuttle = time_carrier(20000);
    const double gns_ns = static_cast<double>(gns) / static_cast<double>(kPerLane * 4);
    const double our_ns = static_cast<double>(ours) / static_cast<double>(kPerLane * 4);
    std::printf("GNS lane: %.2f ns/chon\n", gns_ns);
    std::printf("LaneQueue: %.2f ns/chon\n", our_ns);
    std::printf("carrier 20000 tin: %lld ns\n", static_cast<long long>(shuttle));
    if (shuttle < 0) {
        std::printf("carrier khong giao du tin\n");
        return 1;
    }
    if (ours >= gns) {
        std::printf("LaneQueue khong nhanh hon GNS\n");
        return 1;
    }
    std::printf("LaneQueue nhanh hon loi GNS\n");
    return 0;
}
