// Đọc một dòng stdout của con, có hạn chờ và trần 4 KiB. Tách khỏi
// process_win32.cpp để mỗi tệp không quá 500 dòng.
#include "process/process.hpp"

#include "core/win32.hpp" // IWYU pragma: keep
#include "process/detail/child_state.hpp"
#include "process/detail/line_buffer.hpp"

#include <array>
#include <chrono>
#include <cstdint>
#include <string>

#include <errhandlingapi.h>
#include <fileapi.h>
#include <namedpipeapi.h>
#include <synchapi.h>

namespace game::process {
namespace {

constexpr DWORD kPauseMs = 15;
constexpr std::size_t kReadChunk = 256;

[[nodiscard]] HANDLE as_handle(const core::UniqueHandle& handle) noexcept {
    return handle.get();
}

void mark_exited(detail::ChildState& state) noexcept {
    DWORD code = 1;
    static_cast<void>(GetExitCodeProcess(as_handle(state.process), &code));
    state.exited = true;
    state.code = static_cast<int>(code);
}

[[nodiscard]] bool exited_now(detail::ChildState& state) noexcept {
    if (!state.process) return true;
    if (state.exited) return true;
    const DWORD waited = WaitForSingleObject(as_handle(state.process), 0);
    if (waited == WAIT_TIMEOUT) return false;
    if (waited != WAIT_OBJECT_0) {
        state.exited = true;
        state.code = 1;
        return true;
    }
    mark_exited(state);
    return true;
}

[[nodiscard]] DWORD clamp_timeout(std::chrono::milliseconds limit) noexcept {
    if (limit.count() <= 0) return 0;
    constexpr auto kMax = static_cast<std::chrono::milliseconds::rep>(0xFFFFFFFE);
    if (limit.count() > kMax) return 0xFFFFFFFE;
    return static_cast<DWORD>(limit.count());
}

struct ReadChunk {
    bool failed = false;
    bool closed = false;
    std::uint32_t system = 0;
    std::string bytes{};
};

[[nodiscard]] ReadChunk read_chunk(core::UniqueHandle& output) {
    ReadChunk chunk;
    if (!output) {
        chunk.closed = true;
        return chunk;
    }
    DWORD available = 0;
    const BOOL peeked =
        PeekNamedPipe(as_handle(output), nullptr, 0, nullptr, &available, nullptr);
    if (peeked == FALSE) {
        const DWORD error = GetLastError();
        const bool closed = error == ERROR_BROKEN_PIPE || error == ERROR_INVALID_HANDLE;
        chunk.closed = closed;
        chunk.failed = !closed;
        chunk.system = error;
        return chunk;
    }
    if (available == 0) return chunk;
    const DWORD want = available > kReadChunk ? static_cast<DWORD>(kReadChunk) : available;
    std::array<char, kReadChunk> buffer{};
    DWORD got = 0;
    const BOOL read = ReadFile(as_handle(output), buffer.data(), want, &got, nullptr);
    if (read == FALSE) {
        chunk.failed = true;
        chunk.system = GetLastError();
        return chunk;
    }
    chunk.bytes.assign(buffer.data(), got);
    return chunk;
}

struct ReadProgress {
    bool done = false;
    bool failed = false;
    std::uint32_t system = 0;
    LineKind kind = LineKind::kTimeout;
    std::string text{};
};

void accept_feed(std::string& pending, detail::Feed fed, ReadProgress& progress) {
    if (fed.kind == detail::FeedKind::kNeedMore) return;
    if (fed.kind == detail::FeedKind::kTooLong) {
        pending.clear();
        progress.done = true;
        progress.kind = LineKind::kTooLong;
        return;
    }
    pending = std::move(fed.rest);
    progress.text = std::move(fed.line);
    progress.done = true;
    progress.kind = LineKind::kText;
}

void consume_pending(std::string& pending, bool& held_cr, ReadProgress& progress) {
    if (progress.done || (pending.empty() && !held_cr)) return;
    std::string held = std::move(pending);
    pending.clear();
    accept_feed(pending, detail::feed(pending, held, held_cr), progress);
}

void pause_until(HANDLE process, std::chrono::steady_clock::time_point deadline) {
    const auto left = deadline - std::chrono::steady_clock::now();
    if (left <= std::chrono::steady_clock::duration::zero()) return;
    const auto milliseconds = std::chrono::duration_cast<std::chrono::milliseconds>(left);
    DWORD slice = kPauseMs;
    if (milliseconds.count() < static_cast<std::chrono::milliseconds::rep>(kPauseMs)) {
        slice = clamp_timeout(milliseconds);
    }
    static_cast<void>(WaitForSingleObject(process, slice));
}

void pump(detail::ChildState& state, ReadProgress& progress,
    std::chrono::steady_clock::time_point deadline) {
    if (progress.done) return;
    consume_pending(state.pending, state.held_cr, progress);
    if (progress.done) return;
    const ReadChunk chunk = read_chunk(state.output);
    if (chunk.failed) {
        progress.done = true;
        progress.failed = true;
        progress.system = chunk.system;
        return;
    }
    if (!chunk.bytes.empty()) {
        accept_feed(state.pending, detail::feed(state.pending, chunk.bytes, state.held_cr), progress);
        return;
    }
    if (chunk.closed || exited_now(state)) {
        progress.done = true;
        progress.kind = LineKind::kClosed;
        return;
    }
    pause_until(as_handle(state.process), deadline);
}

[[nodiscard]] core::Result<Line> finish_read(ReadProgress& progress) {
    if (progress.failed) return core::fail_system(progress.system, "không đọc được ống");
    Line line;
    line.kind = progress.done ? progress.kind : LineKind::kTimeout;
    line.text = std::move(progress.text);
    return line;
}

} // namespace

core::Result<Line> Child::read_line(std::chrono::milliseconds limit) {
    if (state_ == nullptr || !state_->process) {
        return core::fail(core::ErrorCode::kInvalidState, "không có tiến trình để đọc");
    }
    ReadProgress progress;
    consume_pending(state_->pending, state_->held_cr, progress);
    const auto deadline = std::chrono::steady_clock::now() + limit;
    while (!progress.done && std::chrono::steady_clock::now() < deadline) {
        pump(*state_, progress, deadline);
    }
    return finish_read(progress);
}

} // namespace game::process
