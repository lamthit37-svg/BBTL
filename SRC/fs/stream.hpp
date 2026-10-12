// Luồng byte — thay IFileSystem (bảng con trỏ hàm), FileStream (48 byte dữ liệu riêng chép theo giá
// trị) và các shortcut fs*Stream của _Ref. Stream là lớp trừu tượng move-only, sở hữu bằng giá trị
// hay unique_ptr, đóng bằng RAII; lỗi trả qua core::Result thay FS_ERR_CTX thread_local. Ba bản cài
// đặt: File (fs/file.hpp), MemoryStream (fs/memory_stream.hpp), ArchiveStream (fs/archive.hpp).
// Ngữ nghĩa thống nhất cho mọi bản, chỗ gốc mỗi backend một kiểu:
// - đọc ở EOF trả 0 byte, không lỗi (gốc: bộ nhớ báo INVALID_STATE, tệp thì không);
// - at_end đúng ngay khi vị trí chạm cỡ (gốc: tệp dùng feof, chỉ đúng sau lần đọc chạm đáy);
// - map trả đúng cỡ dữ liệu (gốc: bộ nhớ trả capacity).
// Nguồn: Forge2 src/fs/stream.hpp@d7fcd76. Khác gốc: bỏ {} thừa của thành viên data_ trong Bytes.
#pragma once

#include "core/error.hpp"

#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <utility>

namespace game::fs {

using core::Result;
using core::Status;

// FileMode của _Ref. Tổ hợp bằng |, ví dụ Mode::kRead | Mode::kWrite.
enum class Mode : std::uint8_t {
    kRead = 1U << 0U,
    // Một mình: tạo mới hoặc cắt rỗng. Cùng Read: mở hoặc tạo, giữ nội dung.
    kWrite = 1U << 1U,
    // Vị trí đầu ở cuối. Cùng Write: mọi lần ghi về cuối tệp. Đứng một mình nghĩa là Write | Append
    // (gốc rơi vào "r" nên ghi luôn thất bại).
    kAppend = 1U << 2U,
    // Tiến trình khác vẫn đọc được tệp đang mở để ghi.
    kAllowRead = 1U << 4U,
    // Handle kế thừa được sang tiến trình con (stdout của CreateProcess); không có ở _Ref vì CRT
    // mặc định kế thừa. Chỉ File::open dùng.
    kInherit = 1U << 5U,
    // Gợi ý truy cập ngẫu nhiên (FILE_FLAG_RANDOM_ACCESS) thay cho tuần tự mặc định của tệp chỉ
    // đọc; Archive đọc tệp dùng cờ này. Chỉ File::open dùng.
    kRandom = 1U << 6U,
};

[[nodiscard]] constexpr Mode operator|(Mode left, Mode right) noexcept {
    return static_cast<Mode>(std::to_underlying(left) | std::to_underlying(right));
}

[[nodiscard]] constexpr bool has(Mode set, Mode flag) noexcept {
    return (std::to_underlying(set) & std::to_underlying(flag)) != 0;
}

// Append đứng một mình thành Write | Append; mọi Stream giữ mode đã qua hàm này.
[[nodiscard]] constexpr Mode normalized(Mode mode) noexcept {
    const bool lone = has(mode, Mode::kAppend) && !has(mode, Mode::kRead) && !has(mode, Mode::kWrite);
    return lone ? mode | Mode::kWrite : mode;
}

// SeekBaseOffset của _Ref.
enum class Seek : std::uint8_t {
    kBegin,
    kCurrent,
    kEnd,
};

// Khối byte sở hữu, cấp không khởi tạo: đọc cả tệp ghi đè ngay nên zero-fill như vector::resize
// (Wicked, No1) là ghi bộ nhớ hai lần.
class Bytes {
public:
    Bytes() = default;
    explicit Bytes(std::size_t size) : data_(std::make_unique_for_overwrite<Raw>(size)), size_(size) {}
    ~Bytes() = default;
    Bytes(const Bytes&) = delete;
    Bytes& operator=(const Bytes&) = delete;
    // Move tường minh để khối bị lấy báo rỗng: move mặc định giữ size_ cũ cạnh con trỏ null.
    Bytes(Bytes&& other) noexcept : data_(std::move(other.data_)), size_(std::exchange(other.size_, 0)) {}
    Bytes& operator=(Bytes&& other) noexcept {
        data_ = std::move(other.data_);
        size_ = std::exchange(other.size_, 0);
        return *this;
    }

    [[nodiscard]] std::byte* data() noexcept { return data_.get(); }
    [[nodiscard]] const std::byte* data() const noexcept { return data_.get(); }
    [[nodiscard]] std::size_t size() const noexcept { return size_; }
    [[nodiscard]] bool empty() const noexcept { return size_ == 0; }
    [[nodiscard]] std::span<std::byte> span() noexcept { return {data_.get(), size_}; }
    [[nodiscard]] std::span<const std::byte> span() const noexcept { return {data_.get(), size_}; }

    // Thu cỡ về size (đọc được ít hơn dự kiến); không cấp lại.
    void shrink(std::size_t size) noexcept { size_ = size < size_ ? size : size_; }

private:
    // NOLINTNEXTLINE(*-avoid-c-arrays): mảng động không khởi tạo; vector ghi 0 cả vùng trước.
    using Raw = std::byte[];

    std::unique_ptr<Raw> data_;
    std::size_t size_ = 0;
};

class Stream {
public:
    explicit Stream(Mode mode) noexcept : mode_(normalized(mode)) {}
    virtual ~Stream() = default;
    Stream(const Stream&) = delete;
    Stream& operator=(const Stream&) = delete;

    [[nodiscard]] Mode mode() const noexcept { return mode_; }

    // Đọc tối đa out.size() byte; trả số byte đọc được, 0 ở EOF.
    [[nodiscard]] virtual Result<std::size_t> read(std::span<std::byte> out) = 0;

    // Ghi toàn bộ data hoặc trả lỗi. Mặc định: luồng chỉ đọc (Write NULL của _Ref).
    [[nodiscard]] virtual Result<std::size_t> write(std::span<const std::byte> data);

    // Vị trí âm là lỗi; quá cuối chỉ hợp lệ với luồng ghi được (lần ghi sau điền 0 vào khoảng
    // trống).
    [[nodiscard]] virtual Status seek(Seek base, std::int64_t offset) = 0;

    [[nodiscard]] virtual std::uint64_t position() const noexcept = 0;

    // Cỡ hiện tại, tính cả byte đang chờ trong bộ đệm ghi.
    [[nodiscard]] virtual Result<std::uint64_t> size() const = 0;

    // Đẩy bộ đệm ghi xuống tầng dưới. Mặc định: không có bộ đệm.
    [[nodiscard]] virtual Status flush();

    // Toàn bộ nội dung như một mảng chỉ đọc (MemoryMap của _Ref); có thể tạo ánh xạ mới. Vùng sống
    // tới khi luồng bị huỷ.
    [[nodiscard]] virtual Result<std::span<const std::byte>> map();

    // Vị trí đã chạm cỡ; không hỏi được cỡ thì coi như hết.
    [[nodiscard]] bool at_end() const;

protected:
    Stream(Stream&&) noexcept = default;
    Stream& operator=(Stream&&) noexcept = default;

private:
    Mode mode_;
};

// Đích của seek: base cộng offset, lỗi khi âm hay tràn. Dùng chung cho mọi bản cài đặt Stream.
[[nodiscard]] Result<std::uint64_t> seek_target(Seek base, std::int64_t offset, std::uint64_t position,
    std::uint64_t size);

// Đọc tới khi đầy out hoặc hết luồng; trả số byte đọc được.
[[nodiscard]] Result<std::size_t> read_full(Stream& stream, std::span<std::byte> out);

// Phần còn lại từ vị trí hiện tại tới hết luồng.
[[nodiscard]] Result<Bytes> read_all(Stream& stream);

// Tối đa max byte thành chuỗi, npos là tới hết luồng (fsReadBstringFromStream).
[[nodiscard]] Result<std::string> read_text(Stream& stream, std::size_t max = std::string::npos);

// Tìm pattern nằm trọn trong max_bytes byte tính từ vị trí hiện tại (fsFindStream). Thấy thì luồng
// đứng ở đầu chỗ khớp và trả vị trí đó; không thấy thì trả nullopt, vị trí trở về chỗ cũ.
[[nodiscard]] Result<std::optional<std::uint64_t>> find(Stream& stream, std::span<const std::byte> pattern,
    std::uint64_t max_bytes);

// Như find nhưng tìm lùi trong max_bytes byte đứng trước vị trí hiện tại, lấy chỗ khớp gần nhất
// (fsFindReverseStream).
[[nodiscard]] Result<std::optional<std::uint64_t>> rfind(Stream& stream, std::span<const std::byte> pattern,
    std::uint64_t max_bytes);

} // namespace game::fs
