/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/android_stdio.cpp
 *  PHÂN HỆ   : Client / Client / Android Stdio
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Xem android_stdio.hpp.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#if defined(__ANDROID__)

#include "client/android_stdio.hpp"

#include <android/log.h>
#include <fcntl.h>
#include <poll.h>
#include <unistd.h>

#include <array>
#include <cerrno>
#include <cstddef>
#include <cstdio>
#include <stop_token>
#include <string>
#include <string_view>
#include <thread>

namespace game::client {
namespace {

constexpr const char* kTag = "THIENLONG";
// Logcat cắt dòng ở khoảng 4 KiB; chừa chỗ cho đầu dòng của hệ thống.
constexpr std::size_t kMaxLine = 3500;
constexpr int kPollMs = 100;
constexpr std::size_t kChunk = 1024;
constexpr std::array<int, 2> kStdFds{STDOUT_FILENO, STDERR_FILENO};
constexpr std::array<int, 2> kPriorities{ANDROID_LOG_INFO, ANDROID_LOG_ERROR};

void emit(int priority, std::string& line) noexcept {
    if (line.empty()) return;
    __android_log_write(priority, kTag, line.c_str());
    line.clear();
}

// Nối byte vừa đọc vào dòng đang dở; mỗi '\n' hay đủ kMaxLine thì ghi một dòng log.
void feed(int priority, std::string& line, std::string_view bytes) {
    for (const char letter : bytes) {
        if (letter == '\n') {
            emit(priority, line);
            continue;
        }
        line.push_back(letter);
        if (line.size() >= kMaxLine) emit(priority, line);
    }
}

// Đọc một lượt từ ống nếu có dữ liệu; false khi ống đã đóng (EOF hay lỗi) và không nên đọc nữa.
[[nodiscard]] bool pull(const pollfd& watch, int priority, std::string& line) {
    if ((watch.revents & (POLLIN | POLLHUP | POLLERR)) == 0) return true;
    std::array<char, kChunk> chunk{};
    const ssize_t got = ::read(watch.fd, chunk.data(), chunk.size());
    if (got > 0) {
        feed(priority, line, std::string_view(chunk.data(), static_cast<std::size_t>(got)));
        return true;
    }
    if (got < 0 && (errno == EINTR || errno == EAGAIN)) return true;
    emit(priority, line);
    return false;
}

// Chạy tới khi cả hai ống đóng. Khi có yêu cầu dừng thì rút nốt phần đã nằm trong ống rồi thoát: dữ liệu ghi trước lúc
// huỷ không mất.
void drain(const std::stop_token& stop, std::array<int, 2> fds) {
    std::array<std::string, 2> lines;
    bool is_stopping = false;
    while (true) {
        std::array<pollfd, 2> watch{};
        int open_count = 0;
        for (std::size_t index = 0; index < watch.size(); ++index) {
            watch[index] = pollfd{.fd = fds[index], .events = POLLIN, .revents = 0};
            if (fds[index] >= 0) ++open_count;
        }
        if (open_count == 0) return;
        const int timeout = is_stopping ? 0 : kPollMs;
        const int ready = ::poll(watch.data(), watch.size(), timeout);
        if (ready < 0 && errno != EINTR) return;
        if (ready == 0 && is_stopping) return;
        if (ready > 0) {
            for (std::size_t index = 0; index < watch.size(); ++index) {
                if (fds[index] < 0) continue;
                if (!pull(watch[index], kPriorities[index], lines[index])) fds[index] = -1;
            }
        }
        if (stop.stop_requested()) is_stopping = true;
    }
}

} // namespace

AndroidStdio::AndroidStdio() noexcept {
    std::array<std::array<int, 2>, kStreams> pipes{};
    for (std::size_t index = 0; index < kStreams; ++index) {
        if (::pipe2(pipes[index].data(), O_CLOEXEC) == 0) continue;
        for (std::size_t made = 0; made < index; ++made) {
            ::close(pipes[made][0]);
            ::close(pipes[made][1]);
        }
        return;
    }
    static_cast<void>(std::fflush(stdout));
    static_cast<void>(std::fflush(stderr));
    for (std::size_t index = 0; index < kStreams; ++index) {
        saved_[index] = ::dup(kStdFds[index]);
        read_ends_[index] = pipes[index][0];
    }
    const bool is_saved = saved_[0] >= 0 && saved_[1] >= 0;
    const bool is_swapped =
        is_saved && ::dup2(pipes[0][1], kStdFds[0]) >= 0 && ::dup2(pipes[1][1], kStdFds[1]) >= 0;
    for (std::size_t index = 0; index < kStreams; ++index) ::close(pipes[index][1]);
    if (!is_swapped) {
        // dup2 đầu có thể đã đổi stdout trước khi cái sau hỏng: trả hai luồng về chỗ cũ rồi bỏ cầu.
        for (std::size_t index = 0; index < kStreams; ++index) {
            if (saved_[index] >= 0) static_cast<void>(::dup2(saved_[index], kStdFds[index]));
            if (saved_[index] >= 0) ::close(saved_[index]);
            ::close(read_ends_[index]);
            saved_[index] = -1;
            read_ends_[index] = -1;
        }
        return;
    }
    // Ống không phải thiết bị cuối nên stdout mặc định đệm đầy: dòng in ra phải tới logcat ngay.
    static_cast<void>(std::setvbuf(stdout, nullptr, _IOLBF, 0));
    reader_ = std::jthread([fds = read_ends_](const std::stop_token& stop) { drain(stop, fds); });
    is_active_ = true;
}

AndroidStdio::~AndroidStdio() {
    if (!is_active_) return;
    static_cast<void>(std::fflush(stdout));
    static_cast<void>(std::fflush(stderr));
    // Trả bộ mô tả cũ: đầu ghi của ống đóng theo, luồng đọc thấy EOF sau khi rút hết.
    for (std::size_t index = 0; index < kStreams; ++index) {
        static_cast<void>(::dup2(saved_[index], kStdFds[index]));
        ::close(saved_[index]);
    }
    reader_.request_stop();
    reader_.join();
    for (const int fd : read_ends_) ::close(fd);
}

} // namespace game::client

#endif
