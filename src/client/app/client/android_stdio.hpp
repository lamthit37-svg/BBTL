/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/android_stdio.hpp
 *  PHÂN HỆ   : Client / Client / Android Stdio
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Chuyển stdout và stderr của tiến trình Android sang logcat. Client in chẩn
 *    đoán bằng std::println (nạp cảnh, giao diện, âm thanh, bảng đo); Android
 *    bỏ hai luồng ấy, nên không có cầu này thì mọi lỗi nạp đều câm trên thiết
 *    bị.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Mỗi luồng một ống: dòng của stdout ghi mức INFO, dòng của stderr ghi mức ERROR. Một luồng nền đọc cả hai ống, chờ có
// hạn (poll 100 ms) nên hàm huỷ dừng được trong khoảng ấy. Dòng dài quá kMaxLine thì cắt thành nhiều dòng log.
// Hàm huỷ trả stdout/stderr về bộ mô tả ban đầu.

#pragma once

#if defined(__ANDROID__)

#include <array>
#include <cstddef>
#include <thread>

namespace game::client {

class AndroidStdio {
public:
    // Không chuyển được (hết bộ mô tả tệp) thì is_active() là false và stdout, stderr giữ nguyên.
    AndroidStdio() noexcept;
    ~AndroidStdio();
    AndroidStdio(const AndroidStdio&) = delete;
    AndroidStdio& operator=(const AndroidStdio&) = delete;
    AndroidStdio(AndroidStdio&&) = delete;
    AndroidStdio& operator=(AndroidStdio&&) = delete;

    [[nodiscard]] bool is_active() const noexcept { return is_active_; }

private:
    static constexpr std::size_t kStreams = 2;

    std::array<int, kStreams> read_ends_{-1, -1};
    std::array<int, kStreams> saved_{-1, -1};
    bool is_active_ = false;
    std::jthread reader_;
};

} // namespace game::client

#endif
