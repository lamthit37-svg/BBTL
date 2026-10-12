#pragma once
// Chạy một tiến trình con và đọc stdout của nó theo dòng. Nơi duy nhất include header tiến trình
// của hệ điều hành.
// Quyết định: không gọi shell; một dòng của con có trần 4 KiB; huỷ Child khi con còn sống thì buộc
// dừng rồi chờ; con chỉ thừa hưởng đúng ba handle chuẩn, không thừa hưởng handle nào khác của cha.
// "Đã có yêu cầu dừng" là stdin hết dòng, hoặc tín hiệu console khi stdin không phải ống.
// Nguồn: TLBB Dev src/platform/process.hpp, process_win32.cpp, process_posix.cpp, console.hpp,
// console.cpp @e0d89a6.
// Khác gốc: lỗi là core::Result; đọc dòng có hạn chờ và trần; hai kiểu con (Mode); danh sách
// handle thừa hưởng tường minh; câu hỏi dừng.

#include "core/error.hpp"

#include <chrono>
#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::process {

namespace detail {
struct ChildState;
} // namespace detail

// Trần một dòng stdout của con, không tính dấu xuống dòng. Dài hơn là lỗi của con.
inline constexpr std::size_t kLineCeiling = 4096;

enum class LineKind : std::uint8_t {
    kText,
    kTimeout,
    kClosed,
    kTooLong,
};

// Một kết quả đọc. text chỉ có nghĩa khi kind là kText.
struct Line {
    LineKind kind = LineKind::kTimeout;
    std::string text;
};

enum class WaitKind : std::uint8_t {
    kExited,
    kTimeout,
};

// Kết quả chờ thoát. code chỉ có nghĩa khi kind là kExited.
struct ExitStatus {
    WaitKind kind = WaitKind::kTimeout;
    int code = 0;
};

// kService: tiến trình do cha giám sát. stdin là ống cha giữ (đóng ống là bảo con dừng), stderr
// thừa hưởng, cha chết thì hệ điều hành dừng con theo.
// kCommand: một lệnh chạy rồi thoát và có thể để lại tiến trình nền (pg_ctl start). stdin là
// thiết bị rỗng, stderr gộp vào stdout, lệnh cùng con cháu của nó không chết theo cha.
enum class Mode : std::uint8_t {
    kService,
    kCommand,
};

// executable là đường dẫn, không phải tên trên PATH. arguments không gồm tên exe.
struct Spawn {
    std::string_view executable;
    std::span<const std::string_view> arguments;
    Mode mode = Mode::kService;
};

// Một tiến trình con. Huỷ khi con còn sống thì buộc dừng rồi chờ, không để mồ côi.
class Child {
public:
    Child() noexcept;
    ~Child();
    Child(Child&& other) noexcept;
    Child& operator=(Child&& other) noexcept;
    Child(const Child&) = delete;
    Child& operator=(const Child&) = delete;

    // Còn giữ tiến trình, kể cả khi nó đã thoát.
    [[nodiscard]] explicit operator bool() const noexcept;
    // Số của hệ điều hành; 0 khi không có tiến trình.
    [[nodiscard]] std::uint32_t id() const noexcept;

    // Đóng stdin của con. Con kiểu kService thấy hết dòng và tự thoát.
    void close_input() noexcept;
    // Buộc dừng rồi chờ tới khi hệ điều hành thu hồi tiến trình.
    void force_stop() noexcept;

    // nullopt khi còn chạy. Gọi lại sau khi đã thoát vẫn trả cùng mã.
    [[nodiscard]] std::optional<int> try_wait() noexcept;
    // Chờ tới khi thoát hoặc hết hạn. Hết hạn thì con vẫn sống.
    [[nodiscard]] ExitStatus wait_for(std::chrono::milliseconds limit) noexcept;
    // Đọc một dòng, bỏ `\n` hoặc `\r\n` cuối. Không cấp phát quá kLineCeiling. Sau kTooLong phần
    // còn lại của dòng đó vẫn nằm trong ống: bên gọi coi con là hỏng và dừng nó.
    [[nodiscard]] core::Result<Line> read_line(std::chrono::milliseconds limit);

private:
    void shutdown() noexcept;
    std::unique_ptr<detail::ChildState> state_;
    friend core::Result<Child> spawn(const Spawn& request);
};

// Tạo con. Thất bại thì không để lại tiến trình.
[[nodiscard]] core::Result<Child> spawn(const Spawn& request);

// Bắt tín hiệu dừng của console từ lúc này; gọi ở đầu main. Tiến trình có stdin là ống thì do cha
// điều khiển: Ctrl+C và Ctrl+Break bị bỏ qua để cha dừng các con đúng thứ tự.
void watch_stop_signals() noexcept;

// Không chặn. Đúng khi stdin đã hết dòng (ống đã đóng, thiết bị rỗng, tệp) hoặc đã nhận tín hiệu
// dừng. stdin là console thì chỉ tín hiệu mới là yêu cầu dừng.
[[nodiscard]] bool stop_requested() noexcept;

// false khi không mở được hoặc tiến trình đã thoát. Số có thể bị hệ điều hành tái sử dụng.
[[nodiscard]] bool process_alive(std::uint32_t id) noexcept;

// Đối số sau tên exe, UTF-8. Windows đọc lại dòng lệnh UTF-16, không dùng argv đã hỏng dấu.
[[nodiscard]] std::vector<std::string> utf8_arguments(int argc, const char* const* argv);

// Tách một dòng lệnh theo quy tắc CommandLineToArgvW. Dùng để kiểm và để đọc dòng lệnh thật.
[[nodiscard]] std::vector<std::string> split_command_line(std::string_view command);

} // namespace game::process
