// Hướng chủ của runtime Lua: định nghĩa mọi hàm khai ở host.hpp bằng State (state.hpp).
#include "lua/host.hpp"

#include "core/check.hpp"
#include "lua/lib.hpp"
#include "lua/state.hpp"
#include "lua/vm.hpp"

#include <algorithm>
#include <cstddef>
#include <expected>
#include <memory>
#include <string_view>

namespace game::lua {
namespace {

// Trần heap thật sự áp dụng: bảng lớn nhất Table cho phép (2^24 nút) đã vượt xa 512 MiB, nên với trần này mọi lần cấp bảng
// bị chặn bởi reserve() trước khi chạm miền kMaxBits của Table.
constexpr std::size_t kMaxHeapBytes = std::size_t{512} * 1024 * 1024;

[[nodiscard]] Failure take_failure(State& state) {
    return Failure{State::error_text(state.take_error())};
}

} // namespace

void StateDeleter::operator()(State* state) const noexcept {
    delete state; // NOLINT(cppcoreguidelines-owning-memory): StatePtr là chủ duy nhất, tạo bởi new_state.
}

StatePtr new_state(const Limits& limits) {
    Limits applied = limits;
    applied.heap_bytes = std::min(limits.heap_bytes, kMaxHeapBytes);
    return StatePtr(std::make_unique<State>(applied).release());
}

void open_standard(State& state) {
    open_base(state);
    open_string(state);
    open_table(state);
    open_math(state);
}

void set_host(State& state, Host* host) noexcept {
    state.set_host(host);
}

Host* host(const State& state) noexcept {
    return state.host();
}

Value intern(State& state, std::string_view bytes) {
    return state.make_string(bytes);
}

std::string_view bytes_of(Value string) {
    return string.as_string().view();
}

void put_global(State& state, std::string_view name, Value value) {
    state.set_global(name, value);
}

Value find_global(State& state, std::string_view name) {
    return state.global(name);
}

Value native(State& state, const Proto& proto) {
    return state.make_native(proto);
}

Outcome run(State& state, const Chunk& chunk) {
    core::check(chunk.main != nullptr, "run: chunk lỗi cú pháp không chạy được");
    if (state.depth() == 0) state.reset_ticks();
    const State::LoadedChunk& loaded = state.load_chunk(chunk);
    const Value main = state.make_closure(*chunk.main, &loaded, {});
    if (state.failed()) return std::unexpected(take_failure(state));
    Results results = state.invoke(main.as_function(), {});
    if (state.failed()) return std::unexpected(take_failure(state));
    return results;
}

Outcome protected_call(State& state, Value callee, Args args) {
    if (state.depth() == 0) state.reset_ticks();
    Results results = call(state, callee, args);
    if (state.failed()) return std::unexpected(take_failure(state));
    return results;
}

void collect(State& state) {
    state.collect();
}

} // namespace game::lua
