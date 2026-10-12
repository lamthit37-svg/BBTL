// HANDLE của Win32 sở hữu độc quyền, đóng bằng CloseHandle khi huỷ (hiến pháp III.4: RAII cho mọi
// tài nguyên, kể cả HANDLE). _Ref giữ HANDLE trần trong struct C và đóng tay, có chỗ đóng HANDLE
// NULL (WindowsFileSystem.cpp:315) và chỗ quên đóng khi lỗi. Không include windows.h: HANDLE là
// void*.
// Nguồn: Forge2 src/core/handle.hpp@d7fcd76. Khác gốc: không.
#pragma once

#include <utility>

namespace game::core {

class UniqueHandle {
public:
    UniqueHandle() noexcept = default;
    // Nhận cả nullptr và INVALID_HANDLE_VALUE; hai giá trị đó không bị đóng.
    explicit UniqueHandle(void* handle) noexcept : handle_(handle) {}
    ~UniqueHandle() { reset(); }

    UniqueHandle(const UniqueHandle&) = delete;
    UniqueHandle& operator=(const UniqueHandle&) = delete;
    UniqueHandle(UniqueHandle&& other) noexcept : handle_(std::exchange(other.handle_, nullptr)) {}
    UniqueHandle& operator=(UniqueHandle&& other) noexcept {
        if (this != &other) reset(std::exchange(other.handle_, nullptr));
        return *this;
    }

    [[nodiscard]] void* get() const noexcept { return handle_; }
    [[nodiscard]] bool valid() const noexcept;
    explicit operator bool() const noexcept { return valid(); }

    // Đóng handle đang giữ (nếu hợp lệ) rồi nhận handle mới.
    void reset(void* handle = nullptr) noexcept;
    // Trả quyền sở hữu cho người gọi.
    [[nodiscard]] void* release() noexcept { return std::exchange(handle_, nullptr); }

private:
    void* handle_ = nullptr;
};

} // namespace game::core
