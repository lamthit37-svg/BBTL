/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/error.hpp
 *  PHÂN HỆ   : Core / Error
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Lỗi vận hành của engine: hàm thất bại vì môi trường (tệp thiếu, hết chỗ,
 *    dữ liệu hỏng) trả Result<T> hay Status, dựng trên std::expected. Lỗi lập
 *    trình thì dùng check (core/check.hpp). Thay FSErrorCode và FS_ERR_CTX của
 *    _Ref (mã lỗi để trong biến thread_local, hàm sau ghi đè hàm trước, người
 *    gọi phải nhớ đọc ngay) theo khuôn 128 B của VnS: không cấp phát tới 88 B
 *    chi tiết. Thêm so với VnS: giữ mã lỗi hệ điều hành và tự suy ErrorCode từ
 *    nó; không macro lan truyền, dùng and_then/or_else của std::expected hay
 *    một dòng if.
 *  - Nguồn: Forge2 src/core/error.hpp@d7fcd76. Khác gốc: enumerator mang tiền
 *    tố k; thông điệp rỗng bị chặn bằng core::check của THIENLONG thay cho
 *    throw trong constructor consteval.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "core/check.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <format>
#include <memory>
#include <source_location>
#include <string>
#include <string_view>
#include <utility>

namespace game::core {

enum class ErrorCode : std::uint8_t {
    // Nguyên nhân không phân loại được, như mã lạ của hệ điều hành.
    kUnknown,
    kInvalidArgument,
    kOutOfRange,
    kOutOfMemory,
    kNotFound,
    kAlreadyExists,
    kPermissionDenied,
    // Đối tượng chưa ở trạng thái cho phép thao tác (FS_INVALID_STATE_ERR của _Ref).
    kInvalidState,
    kNotADirectory,
    kIsADirectory,
    kNoSpace,
    kReadOnly,
    // Tài nguyên đang bị nơi khác giữ (chia sẻ tệp, khoá vùng).
    kBusy,
    kUnsupported,
    kIo,
    // Dữ liệu đọc vào (tệp, archive, gói tin) không hợp lệ.
    kCorrupt,
    // Phép tính hay kích thước vượt giới hạn của kiểu.
    kOverflow,
    // Hết một tài nguyên có hạn ngạch (ô, handle, slot), không phải bộ nhớ.
    kExhausted,
    kTimeout,
    kWouldBlock,
    kCancelled,
    // Thiết bị đồ hoạ mất: mọi tài nguyên đã tạo hết hiệu lực.
    kDeviceLost,
    // Bất biến của chính engine bị vi phạm mà còn phục hồi được.
    kInternal,
};

// Tên enumerator. Không default: thêm mã mà quên ở đây là C4062.
[[nodiscard]] std::string_view name(ErrorCode code) noexcept;

// Mã Win32 (GetLastError) sang ErrorCode — translateErrno của _Ref cho Windows.
[[nodiscard]] ErrorCode from_system(std::uint32_t system) noexcept;

// Thông điệp hệ điều hành của một mã Win32 hay HRESULT, theo ngôn ngữ của Windows; rỗng nếu không
// có.
[[nodiscard]] std::string system_message(std::uint32_t system);

// Thông điệp tĩnh cộng vị trí của chỗ chuyển chuỗi thành Message, tức chỗ gọi fail. consteval: con
// trỏ phải là hằng lúc dịch, nên chỉ trỏ được vào vùng nhớ tĩnh; std::string hay mảng trên stack là
// lỗi dịch chứ không phải con trỏ treo. Hàm phụ nhận Message làm tham số thì vị trí là chỗ gọi hàm
// phụ, không phải chuyển std::source_location tay.
class Message {
public:
    // Chuyển ngầm từ chuỗi là chủ ý: vị trí được bắt đúng ở chỗ viết thông điệp (lệch API-04).
    // NOLINTNEXTLINE(cppcoreguidelines-explicit-constructor,google-explicit-constructor,misc-explicit-constructor)
    consteval Message(const char* text, std::source_location where = std::source_location::current())
        : text_(text), file_(where.file_name()), line_(where.line()) {
        // Khác gốc: gốc throw một chuỗi; check sai trong consteval cũng là lỗi dịch (KG-14).
        check(text != nullptr && *text != '\0', "Message: thông điệp lỗi không được rỗng");
    }

    [[nodiscard]] constexpr const char* text() const noexcept { return text_; }
    [[nodiscard]] constexpr const char* file() const noexcept { return file_; }
    [[nodiscard]] constexpr std::uint32_t line() const noexcept { return line_; }

private:
    const char* text_;
    const char* file_;
    std::uint32_t line_;
};

// Mã, thông điệp, vị trí, mã hệ điều hành và chi tiết động. 128 B: chi tiết tới kInlineCapacity
// byte nằm ngay trong đối tượng, dài hơn thì lên heap đúng một lần. Mọi thao tác noexcept; hết bộ
// nhớ hay quá kMaxDetail thì giữ phần đuôi (đuôi đường dẫn là tên tệp), không chẻ ký tự UTF-8.
class Error {
public:
    static constexpr std::size_t kSize = 128;
    static constexpr std::size_t kInlineCapacity = 88;
    static constexpr std::size_t kMaxDetail = 0xFFFF;
    // Chi tiết thay thế khi formatter của một đối số ném.
    static constexpr std::string_view kFormatFailure = "(lỗi khi định dạng chi tiết)";

    Error(ErrorCode code, Message message, std::uint32_t system = 0) noexcept
        : message_(message.text()), file_(message.file()), line_(message.line()), system_(system), code_(code) {}
    Error(ErrorCode code, Message message, std::string_view detail, std::uint32_t system = 0) noexcept;
    Error(const Error& other) noexcept;
    Error& operator=(const Error& other) noexcept;
    ~Error() = default;

    // Move nằm trong header: mỗi tầng lan truyền move một lần nên phải inline được. Nguồn sau khi
    // move giữ mã, thông điệp, vị trí; chi tiết rỗng.
    Error(Error&& other) noexcept
        : message_(other.message_),
          file_(other.file_),
          line_(other.line_),
          system_(other.system_),
          code_(other.code_),
          truncated_(std::exchange(other.truncated_, false)),
          size_(std::exchange(other.size_, std::uint16_t{0})),
          heap_(std::move(other.heap_)),
          storage_(other.storage_) {}

    Error& operator=(Error&& other) noexcept {
        message_ = other.message_;
        file_ = other.file_;
        line_ = other.line_;
        system_ = other.system_;
        code_ = other.code_;
        truncated_ = std::exchange(other.truncated_, false);
        size_ = std::exchange(other.size_, std::uint16_t{0});
        heap_ = std::move(other.heap_);
        storage_ = other.storage_;
        return *this;
    }

    [[nodiscard]] ErrorCode code() const noexcept { return code_; }
    [[nodiscard]] std::string_view message() const noexcept { return message_; }
    // Tệp tính từ gốc dự án (/d1trimfile cắt đường dẫn máy dựng).
    [[nodiscard]] std::string_view file() const noexcept { return file_; }
    [[nodiscard]] std::uint32_t line() const noexcept { return line_; }
    // Mã Win32, HRESULT hay NTSTATUS gốc; 0 khi lỗi không đến từ hệ điều hành.
    [[nodiscard]] std::uint32_t system() const noexcept { return system_; }
    // Mượn: hết hiệu lực khi Error bị huỷ hay gán đè.
    [[nodiscard]] std::string_view detail() const noexcept {
        return heap_ ? std::string_view(heap_.get(), size_) : std::string_view(storage_.data(), size_);
    }
    // Chi tiết đã mất phần đầu: quá kMaxDetail, hoặc hết bộ nhớ khi cần lên heap.
    [[nodiscard]] bool truncated() const noexcept { return truncated_; }

    // Ghi chi tiết dạng std::format thẳng vào chỗ nội tuyến; dài hơn thì định dạng lại lên heap.
    template <class... Args>
    void format_detail(std::format_string<Args...> format, const Args&... args) noexcept {
        format_erased(format.get(), std::make_format_args(args...));
    }

private:
    // Phần không template của format_detail, một bản cho mọi bộ đối số. Đối số đi qua
    // std::format_args nên giá trị tạm, lvalue hay const đều như nhau.
    void format_erased(std::string_view format, std::format_args args) noexcept;
    void assign(std::string_view text) noexcept;

    const char* message_;
    const char* file_;
    std::uint32_t line_;
    std::uint32_t system_;
    ErrorCode code_;
    bool truncated_ = false;
    std::uint16_t size_ = 0;
    // Chi tiết dài hơn kInlineCapacity; null khi chi tiết nằm nội tuyến. Mảng động của
    // make_unique_for_overwrite, không có kiểu thay.
    // NOLINTNEXTLINE(*-avoid-c-arrays)
    std::unique_ptr<char[]> heap_;
    std::array<char, kInlineCapacity> storage_{};
};

static_assert(sizeof(Error) == Error::kSize, "Error phải vừa đúng 128 B, không đệm ngầm");

using Failure = std::unexpected<Error>;

template <class T>
using Result = std::expected<T, Error>;

using Status = std::expected<void, Error>;

[[nodiscard]] inline Status ok() noexcept {
    return {};
}

[[nodiscard]] inline Failure fail(ErrorCode code, Message message) noexcept {
    return Failure(std::in_place, code, message);
}

// detail chỉ được đọc trong lời gọi, không bị giữ.
[[nodiscard]] inline Failure fail(ErrorCode code, Message message, std::string_view detail) noexcept {
    return Failure(std::in_place, code, message, detail);
}

// Chi tiết định dạng: fail(code, "khoá ngoài miền", "{} = {}", khoá, giá trị). Không dựng
// std::string trước, không cấp phát khi vừa chỗ nội tuyến.
template <class... Args>
[[nodiscard]] Failure fail(ErrorCode code, Message message, std::format_string<Args...> format,
    const Args&... args) noexcept {
    Failure failure(std::in_place, code, message);
    failure.error().format_detail(format, args...);
    return failure;
}

// Lỗi hệ điều hành: ErrorCode suy từ mã Win32, mã gốc giữ lại để in thông điệp của Windows.
[[nodiscard]] inline Failure fail_system(std::uint32_t system, Message message, std::string_view detail = {}) noexcept {
    return Failure(std::in_place, from_system(system), message, detail, system);
}

} // namespace game::core

// "src/fs/file.cpp:42: NotFound: không mở được tệp (C:/x.txt) [hệ thống 0x2: ...]". Tệp:dòng đứng
// đầu để terminal của VS Code bấm được; '\' đổi thành '/' để log giống nhau mọi máy. Đặc tả định
// dạng như {:x} là lỗi dịch.
template <>
struct std::formatter<game::core::Error> {
    static constexpr auto parse(std::format_parse_context& context) {
        const auto it = context.begin();
        const bool plain = it == context.end() || *it == '}';
        if (!plain) throw std::format_error("Error không nhận đặc tả định dạng");
        return it;
    }

    static std::format_context::iterator format(const game::core::Error& error, std::format_context& context);
};

template <>
struct std::formatter<game::core::ErrorCode> : std::formatter<std::string_view> {
    auto format(game::core::ErrorCode code, std::format_context& context) const {
        return std::formatter<std::string_view>::format(game::core::name(code), context);
    }
};
