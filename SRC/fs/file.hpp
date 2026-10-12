// Tệp của hệ điều hành — thay WindowsFileStream (FILE* của CRT kèm HANDLE) và các bước "mở, hỏi cỡ,
// tf_malloc, đọc" mà _Ref để người gọi tự ghép. Gọi thẳng CreateFileW, ReadFile, WriteFile:
// - bộ đệm riêng 64 KiB, không khoá (FILE* khoá CRT mỗi lần gọi, đệm 4 KiB); đọc ghi từ 64 KiB trở
//   lên đi thẳng xuống hệ điều hành;
// - vị trí giữ ở tầng người dùng, mọi lần đọc ghi mang offset trong OVERLAPPED: seek không tốn lời
//   gọi hệ thống, read_at an toàn đa luồng;
// - đường dẫn UTF-8, dài quá giới hạn thì thành dạng \\?\ (gốc: wchar_t[512] chỉ ASSERT);
// - size() tính cả byte chờ trong bộ đệm (gốc hỏi handle nên thấy 0 sau khi ghi qua FILE*);
// - map() trên tệp rỗng trả vùng rỗng (gốc: CreateFileMappingW lỗi 1006).
// Nguồn: Forge2 src/fs/file.hpp@d7fcd76. Khác gốc (so với Forge2): bỏ {} thừa của các thành viên
// view_, handle_, buffer_, mapped_; include thêm <cstddef>, <cstdint>, <span> mà header dùng trực
// tiếp.
#pragma once

#include "core/handle.hpp"
#include "fs/stream.hpp"

#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>

namespace game::fs {

// UTF-8 sang đường dẫn Win32: '/' thành '\'; dài quá giới hạn của API thì thành \\?\ tuyệt đối.
[[nodiscard]] std::wstring native_path(std::string_view path);

class File;

// Bỏ ánh xạ của MapViewOfFile.
struct ViewCloser {
    void operator()(const std::byte* view) const noexcept;
};

// Ánh xạ chỉ đọc cả một tệp. Vùng ánh xạ tự giữ tệp sống, nên tệp nguồn đóng được ngay sau khi map.
class MappedFile {
public:
    [[nodiscard]] static Result<MappedFile> open(std::string_view path);
    // Ánh xạ một tệp đang mở chỉ đọc.
    [[nodiscard]] static Result<MappedFile> open(const File& file);

    [[nodiscard]] std::span<const std::byte> bytes() const noexcept { return {view_.get(), size_}; }

    // Gợi ý nạp trước [offset, offset + size) (PrefetchVirtualMemory) khi sắp đọc liền cả vùng:
    // gom các lỗi trang mềm thành một lời gọi.
    void prefetch(std::uint64_t offset, std::size_t size) const noexcept;

private:
    MappedFile(const std::byte* view, std::size_t size) noexcept : view_(view), size_(size) {}

    std::unique_ptr<const std::byte, ViewCloser> view_;
    std::size_t size_ = 0;
};

class File final : public Stream {
public:
    static constexpr std::size_t kBufferSize = std::size_t{64} * 1024;

    // Chia sẻ với tiến trình khác như CRT của gốc (_SH_SECURE): mở chỉ đọc cho người khác đọc,
    // không cho ghi, nên không ai sửa tệp giữa lúc đang đọc; thêm quyền xoá và đổi tên để trình sửa
    // thay tệp bằng đổi tên được (nạp nóng). Mở để ghi thì độc quyền, trừ khi có Mode::kAllowRead.
    [[nodiscard]] static Result<File> open(std::string_view path, Mode requested);

    File(const File&) = delete;
    File& operator=(const File&) = delete;
    File(File&&) noexcept = default;
    // Đẩy bộ đệm của tệp đang giữ như destructor rồi nhận tệp của other.
    File& operator=(File&& other) noexcept;
    // Đẩy bộ đệm ghi; lỗi lúc này chỉ ghi được vào log, muốn biết thì gọi close().
    ~File() override;

    [[nodiscard]] Result<std::size_t> read(std::span<std::byte> out) override;
    [[nodiscard]] Result<std::size_t> write(std::span<const std::byte> data) override;
    [[nodiscard]] Status seek(Seek base, std::int64_t offset) override;
    [[nodiscard]] std::uint64_t position() const noexcept override { return position_; }
    [[nodiscard]] Result<std::uint64_t> size() const override;
    [[nodiscard]] Status flush() override;
    [[nodiscard]] Result<std::span<const std::byte>> map() override;

    // Đọc tại offset, không dùng bộ đệm, không đổi vị trí; nhiều luồng gọi cùng lúc được.
    [[nodiscard]] Result<std::size_t> read_at(std::uint64_t offset, std::span<std::byte> out) const;

    // flush() rồi FlushFileBuffers: dữ liệu đã nằm trên đĩa (Unix của _Ref là fdatasync, Windows
    // chỉ fflush).
    [[nodiscard]] Status sync();

    // Đẩy bộ đệm rồi đặt cỡ bằng size (cắt hay nới, phần nới là số 0). Kho ghi nối đuôi
    // cắt lần ghi dở về chỗ tốt cuối. Vị trí sau cỡ mới thì lùi về đó. Chỉ đọc thì
    // PermissionDenied.
    [[nodiscard]] Status truncate(std::uint64_t size);

    // Đẩy bộ đệm, bỏ ánh xạ, đóng handle và báo lỗi của cả ba (fsCloseStream).
    [[nodiscard]] Status close();

    // HANDLE của Win32 (fsGetSystemHandle).
    [[nodiscard]] void* native_handle() const noexcept { return handle_.get(); }

private:
    File(core::UniqueHandle handle, Mode mode, std::uint64_t position) noexcept;

    [[nodiscard]] std::span<std::byte> buffer() noexcept { return buffer_.span(); }
    [[nodiscard]] std::size_t take_buffered(std::span<std::byte> out) noexcept;
    [[nodiscard]] Result<std::size_t> read_through(std::span<std::byte> out);
    [[nodiscard]] Status write_through(std::span<const std::byte> data);
    [[nodiscard]] Status write_at(std::uint64_t offset, std::span<const std::byte> data);
    [[nodiscard]] Status flush_writes();
    void begin_writes();
    // Đẩy bộ đệm ghi, lỗi vào log; dùng khi không còn ai nhận lỗi (huỷ, gán đè).
    void flush_quietly() noexcept;

    core::UniqueHandle handle_;
    // kBufferSize byte, cấp ở lần đầu cần. Giữ byte đọc trước, hoặc byte chờ ghi khi dirty_.
    Bytes buffer_;
    // Ánh xạ của map(), sống tới khi đóng.
    std::optional<MappedFile> mapped_;
    std::uint64_t position_ = 0;
    // Vị trí trong tệp của byte đầu bộ đệm.
    std::uint64_t buffer_start_ = 0;
    std::size_t buffered_ = 0;
    bool dirty_ = false;
};

// Cả tệp vào một khối không zero-fill: CreateFileW, GetFileSizeEx, ReadFile thẳng vào khối.
[[nodiscard]] Result<Bytes> read_file(std::string_view path);

// Tạo mới hoặc cắt rỗng rồi ghi data.
[[nodiscard]] Status write_file(std::string_view path, std::span<const std::byte> data);

// Ghi vào tệp tạm cùng thư mục, FlushFileBuffers, rồi thay tệp đích trong một lần MoveFileExW:
// người đọc chỉ thấy bản cũ hoặc bản mới đủ. Tên tạm riêng theo tiến trình và lần gọi.
[[nodiscard]] Status write_file_atomic(std::string_view path, std::span<const std::byte> data);

} // namespace game::fs
