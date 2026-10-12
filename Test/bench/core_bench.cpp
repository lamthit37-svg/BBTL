// Đo lõi máy chủ vừa port: hàng SPSC, lane, và lần chờ reactor so với PollSet.
// In TSV. Không vào ctest.

#include "bench/bench.hpp"
#include "net/net.hpp"
#include "net/reactor.hpp"
#include "net/shard.hpp"

#include <array>
#include <cstdint>
#include <memory>
#include <print>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

namespace {

using game::bench::Clock;
using game::bench::per_second;
using game::bench::seconds_between;

void print_rate(std::string_view axis, double ours, double baseline) {
    std::println("{} ours={:.1f} baseline={:.1f} million_per_s", axis, ours / 1.0e6, baseline / 1.0e6);
}

[[nodiscard]] double spsc_inline(std::uint32_t count) {
    game::net::SpscMail<std::uint32_t, 1024> mail;
    const Clock::time_point start = Clock::now();
    std::jthread producer([&] {
        for (std::uint32_t index = 0; index < count; ++index) {
            std::uint32_t value = index;
            while (!mail.try_push(value)) {
            }
        }
    });
    std::uint32_t expect = 0;
    while (expect < count) {
        std::uint32_t value = 0;
        if (!mail.try_pop(value)) continue;
        ++expect;
    }
    producer.join();
    return per_second(static_cast<double>(count), seconds_between(start, Clock::now()));
}

[[nodiscard]] double spsc_heap(std::uint32_t count) {
    game::net::SpscMail<std::unique_ptr<std::uint32_t>, 1024> mail;
    const Clock::time_point start = Clock::now();
    std::jthread producer([&] {
        for (std::uint32_t index = 0; index < count; ++index) {
            auto value = std::make_unique<std::uint32_t>(index);
            while (!mail.try_push(value)) {
            }
        }
    });
    std::uint32_t expect = 0;
    while (expect < count) {
        std::unique_ptr<std::uint32_t> value;
        if (!mail.try_pop(value)) continue;
        ++expect;
    }
    producer.join();
    return per_second(static_cast<double>(count), seconds_between(start, Clock::now()));
}

[[nodiscard]] double lane_pops(std::uint32_t count) {
    constexpr std::array<game::net::LaneSpec, 2> specs{{
        {.priority = 1, .weight = 4},
        {.priority = 1, .weight = 1},
    }};
    game::net::LaneQueue<std::uint32_t> queue;
    queue.reset(specs);
    for (std::uint32_t index = 0; index < count; ++index) queue.push(index & 1U, index);
    const Clock::time_point start = Clock::now();
    std::uint32_t left = count;
    std::array<std::uint32_t, 64> batch{};
    while (left > 0) {
        const std::size_t got = queue.pop(batch);
        if (got == 0) break;
        left -= static_cast<std::uint32_t>(got);
    }
    return per_second(static_cast<double>(count), seconds_between(start, Clock::now()));
}

struct FloatLane {
    double weight = 1;
    double finish = 0;
    std::uint32_t queued = 0;
};

[[nodiscard]] double float_pops(std::uint32_t count, double& sink) {
    std::array<std::vector<std::uint32_t>, 2> items;
    items[0].reserve(count);
    items[1].reserve(count);
    std::array<FloatLane, 2> lanes{{FloatLane{.weight = 4}, FloatLane{.weight = 1}}};
    double now = 0;
    for (std::uint32_t index = 0; index < count; ++index) {
        const std::size_t lane = index & 1U;
        items[lane].push_back(index);
        lanes[lane].finish = now + 65536.0 / lanes[lane].weight;
        ++lanes[lane].queued;
    }
    const Clock::time_point start = Clock::now();
    for (std::uint32_t index = 0; index < count; ++index) {
        int best = 0;
        if (lanes[1].queued > 0 && (lanes[0].queued == 0 || lanes[1].finish < lanes[0].finish)) best = 1;
        const std::size_t chosen = static_cast<std::size_t>(best);
        now = lanes[chosen].finish;
        lanes[chosen].finish = now + 65536.0 / lanes[chosen].weight;
        --lanes[chosen].queued;
        sink += items[chosen].back();
        items[chosen].pop_back();
    }
    return per_second(static_cast<double>(count), seconds_between(start, Clock::now()));
}

[[nodiscard]] double wait_poll(std::size_t count) {
    auto listener = game::net::TcpListener::open(game::net::Endpoint{.address = {127, 0, 0, 1}, .port = 0});
    if (!listener) return 0;
    const auto target = listener->local();
    if (!target) return 0;
    std::vector<game::net::TcpStream> clients;
    std::vector<game::net::TcpStream> servers;
    clients.reserve(count);
    servers.reserve(count);
    game::net::PollSet poll;
    for (std::size_t index = 0; index < count; ++index) {
        auto client = game::net::TcpStream::begin_connect(*target);
        if (!client) return 0;
        clients.push_back(std::move(*client));
        for (int spin = 0; spin < 1000 && servers.size() == index; ++spin) {
            auto accepted = listener->accept();
            if (accepted && accepted->has_value()) servers.push_back(std::move((*accepted)->stream));
        }
    }
    if (servers.size() != count) return 0;
    for (std::size_t index = 0; index < servers.size(); ++index) {
        if (!poll.add(servers[index].handle(), index + 1)) return 0;
    }
    const std::array<std::byte, 1> byte{std::byte{1}};
    const Clock::time_point start = Clock::now();
    if (clients[0].send(byte) != std::size_t{1}) return 0;
    game::net::PollEvents events;
    if (!poll.wait(game::net::Milliseconds{2000}, events)) return 0;
    return game::bench::micros_between(start, Clock::now());
}

[[nodiscard]] double wait_reactor(std::size_t count) {
    auto listener = game::net::TcpListener::open(game::net::Endpoint{.address = {127, 0, 0, 1}, .port = 0});
    if (!listener) return 0;
    game::net::Reactor reactor;
    if (!reactor.watch_listener(*listener, 1)) return 0;
    const auto target = listener->local();
    if (!target) return 0;
    std::vector<game::net::TcpStream> clients;
    std::vector<game::net::TcpStream> servers;
    clients.reserve(count);
    for (std::size_t index = 0; index < count; ++index) {
        auto client = game::net::TcpStream::begin_connect(*target);
        if (!client) return 0;
        clients.push_back(std::move(*client));
        game::net::PollEvents events;
        if (!reactor.wait(game::net::Milliseconds{2000}, events)) return 0;
        auto accepted = reactor.take_accept(1);
        if (!accepted || !accepted->has_value()) return 0;
        if (!reactor.watch((*accepted)->stream.handle(), index + 2)) return 0;
        servers.push_back(std::move((*accepted)->stream));
    }
    const std::array<std::byte, 1> byte{std::byte{1}};
    const Clock::time_point start = Clock::now();
    if (clients[0].send(byte) != std::size_t{1}) return 0;
    game::net::PollEvents events;
    if (!reactor.wait(game::net::Milliseconds{2000}, events)) return 0;
    return game::bench::micros_between(start, Clock::now());
}

} // namespace

int main() {
    const auto network = game::net::Network::start();
    if (!network) return 1;
    constexpr std::uint32_t kItems = 2'000'000;
    const double inline_rate = spsc_inline(kItems);
    const double heap_rate = spsc_heap(kItems);
    double sink = 0;
    const double lanes = lane_pops(kItems);
    const double floats = float_pops(kItems, sink);
    const double poll128 = wait_poll(128);
    const double reactor128 = wait_reactor(128);
    const double poll512 = wait_poll(512);
    const double reactor512 = wait_reactor(512);
    std::println("axis ours baseline unit");
    print_rate("spsc_inline_vs_heap_pointer", inline_rate, heap_rate);
    print_rate("lane_drr_vs_float_wfq", lanes, floats);
    std::println("wakeup_us_128 reactor={:.1f} poll={:.1f} microseconds", reactor128, poll128);
    std::println("wakeup_us_512 reactor={:.1f} poll={:.1f} microseconds", reactor512, poll512);
    if (sink == 0.0) std::println("sink empty");
    return inline_rate > 0 && lanes > 0 ? 0 : 1;
}
