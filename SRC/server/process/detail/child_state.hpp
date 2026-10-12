#pragma once
// Trạng thái một tiến trình con và ba thao tác mà mỗi nền tảng tự cài; vòng đọc dòng ở
// process.cpp dùng chung cho mọi nền tảng.

#include "core/handle.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <string>

namespace game::process::detail {

struct ChildState {
#if defined(_WIN32)
    core::UniqueHandle process;
    core::UniqueHandle input;
    core::UniqueHandle output;
    std::uint32_t pid = 0;
#else
    int pid = -1;
    int input = -1;
    int output = -1;
#endif
    // Byte đã đọc khỏi ống nhưng chưa trả cho bên gọi.
    std::string pending;
    bool held_cr = false;
    bool exited = false;
    int code = 0;
};

// Số byte tối đa một lần lấy khỏi ống.
inline constexpr std::size_t kReadChunk = 256;

enum class ChunkKind : std::uint8_t {
    kEmpty,
    kBytes,
    kClosed,
    kFailed,
};

// bytes có nghĩa khi kind là kBytes; system là mã lỗi hệ điều hành khi kind là kFailed.
struct Chunk {
    ChunkKind kind = ChunkKind::kEmpty;
    std::string bytes;
    std::uint32_t system = 0;
};

// Không chặn: lấy những byte đang nằm sẵn trong ống stdout của con.
[[nodiscard]] Chunk read_available(const ChildState& state);

// Ngủ tối đa limit; dậy sớm khi con thoát hoặc có byte mới, nơi hệ điều hành báo được.
void pause(const ChildState& state, std::chrono::milliseconds limit) noexcept;

// Con đã thoát chưa. Lần đầu thấy thoát thì ghi mã thoát vào state.
[[nodiscard]] bool exited_now(ChildState& state) noexcept;

} // namespace game::process::detail
