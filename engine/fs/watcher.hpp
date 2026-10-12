// Theo dõi thư mục — thay fsCreateFileWatcher/fsFreeFileWatcher (WindowsToolsFileSystem.cpp) của
// _Ref. Gốc: tên dài hơn 99 byte UTF-8 làm luồng quay vô hạn 100% CPU; tràn bộ đệm 1 KiB thì đọc
// lại bộ đệm cũ; đóng handle khi I/O overlapped còn treo; thư mục không mở được vẫn trả watcher như
// thường. Ở đây: bộ đệm 64 KiB căn DWORD, tràn thì báo Change::kOverflow để người dùng quét lại,
// dừng bằng CancelIoEx rồi chờ I/O xong, lỗi mở trả qua Result. Đổi tên báo thành Deleted rồi
// Created như gốc.
// Nguồn: Forge2 src/fs/watcher.hpp@d7fcd76. Khác gốc (so với Forge2): bỏ include <functional> mà
// header không dùng trực tiếp.
#pragma once

#include "core/function.hpp"
#include "fs/stream.hpp"

#include <cstdint>
#include <memory>
#include <string_view>
#include <thread>
#include <utility>

namespace game::fs {

// FileWatcherEventMask của _Ref, thêm Overflow.
enum class Change : std::uint8_t {
    kModified = 1U << 0U,
    kAccessed = 1U << 1U,
    kCreated = 1U << 2U,
    kDeleted = 1U << 3U,
    // Hệ điều hành bỏ một loạt sự kiện vì đến quá nhanh; luôn được báo, không cần đăng ký.
    kOverflow = 1U << 4U,
};

[[nodiscard]] constexpr Change operator|(Change left, Change right) noexcept {
    return static_cast<Change>(std::to_underlying(left) | std::to_underlying(right));
}

[[nodiscard]] constexpr bool has(Change set, Change flag) noexcept {
    return (std::to_underlying(set) & std::to_underlying(flag)) != 0;
}

class Watcher {
public:
    // Chạy trên luồng theo dõi. path đầy đủ với '/'; Overflow mang path của thư mục.
    using Callback = core::MoveOnlyFunction<void(std::string_view path, Change change)>;

    // Theo dõi directory và mọi thư mục con. Modified cùng Accessed thì Windows không phân biệt
    // được hai loại, mọi thay đổi báo thành Modified.
    [[nodiscard]] static Result<Watcher> start(std::string_view directory, Change events, Callback callback);

    Watcher(Watcher&&) noexcept;
    // Dừng và join luồng cũ trước, rồi mới huỷ trạng thái mà nó đang dùng.
    Watcher& operator=(Watcher&& other) noexcept;
    Watcher(const Watcher&) = delete;
    Watcher& operator=(const Watcher&) = delete;
    // Dừng luồng, huỷ I/O đang treo, chờ luồng thoát.
    ~Watcher();

private:
    struct State;

    Watcher(std::unique_ptr<State> state, std::jthread thread) noexcept;

    // Huỷ theo thứ tự ngược: thread_ dừng và join trước, rồi mới tới state_ mà luồng đang dùng.
    std::unique_ptr<State> state_;
    std::jthread thread_;
};

} // namespace game::fs
