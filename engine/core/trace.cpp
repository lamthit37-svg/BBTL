/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/trace.cpp
 *  PHÂN HỆ   : Core / Trace
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Cài đặt core/trace.hpp: tệp vết mở một lần theo biến môi trường, tập đường
 *    dẫn đã ghi giữ dưới một khoá.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#include "core/trace.hpp"

#include <atomic>
#include <cstdlib>
#include <exception>
#include <filesystem>
#include <fstream>
#include <ios>
#include <mutex>
#include <optional>
#include <string>
#include <unordered_set>

namespace game::core {
namespace {

constexpr const char* kVariable = "THIENLONG_TRACE_FILES";

[[nodiscard]] std::optional<std::string> trace_target() {
#if defined(_WIN32)
    char* value = nullptr;
    std::size_t length = 0;
    if (_dupenv_s(&value, &length, kVariable) != 0 || value == nullptr) return std::nullopt;
    std::string text(value);
    std::free(value); // NOLINT(cppcoreguidelines-no-malloc,cppcoreguidelines-owning-memory): bộ nhớ của _dupenv_s
    if (text.empty()) return std::nullopt;
    return text;
#else
    // Đọc một lần lúc khởi tạo tĩnh, trước khi luồng nào đổi môi trường.
    const char* value = std::getenv(kVariable); // NOLINT(concurrency-mt-unsafe)
    if (value == nullptr || *value == '\0') return std::nullopt;
    return std::string(value);
#endif
}

class Recorder {
public:
    Recorder() noexcept {
        try {
            const std::optional<std::string> target = trace_target();
            if (!target) return;
            out_.open(std::filesystem::path(*target), std::ios::app | std::ios::binary);
            is_on_.store(out_.is_open(), std::memory_order_relaxed);
        } catch (const std::exception&) {
            is_on_.store(false, std::memory_order_relaxed);
        }
    }
    ~Recorder() = default;
    Recorder(const Recorder&) = delete;
    Recorder& operator=(const Recorder&) = delete;
    Recorder(Recorder&&) = delete;
    Recorder& operator=(Recorder&&) = delete;

    [[nodiscard]] bool is_on() const noexcept { return is_on_.load(std::memory_order_relaxed); }

    void note(std::string_view path) noexcept {
        try {
            const std::scoped_lock<std::mutex> locked(guard_);
            if (!is_on() || !seen_.emplace(path).second) return;
            out_ << path << '\n';
            out_.flush();
            if (!out_) is_on_.store(false, std::memory_order_relaxed);
        } catch (const std::exception&) {
            // Hết bộ nhớ hay lỗi khoá: tắt ghi vết, chương trình chạy tiếp.
            is_on_.store(false, std::memory_order_relaxed);
        }
    }

private:
    std::mutex guard_;
    std::unordered_set<std::string> seen_;
    std::ofstream out_;
    std::atomic<bool> is_on_{false};
};

[[nodiscard]] Recorder& recorder() noexcept {
    static Recorder instance;
    return instance;
}

} // namespace

void trace_file(std::string_view path) noexcept {
    Recorder& active = recorder();
    if (active.is_on()) active.note(path);
}

} // namespace game::core
