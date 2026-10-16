/*==============================================================================
 *  THIENLONG  |  SHARED
 *------------------------------------------------------------------------------
 *  TỆP       : src/shared/secure/private_file.hpp
 *  PHÂN HỆ   : Shared / Secure / Private File
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Tệp bí mật trên đĩa: khoá gate, khoá ipc, HMAC thanh toán,
 *    secrets.local.toml. Riêng: chỉ SYSTEM, Administrators và chủ được đọc,
 *    ghi, xoá hoặc chiếm quyền. SYNCHRONIZE và READ_CONTROL của tài khoản khác
 *    không tính. POSIX là 0600 của chủ. Symlink bị từ chối. Không tự sửa quyền:
 *    tệp lỏng thì xoay bí mật.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/
#pragma once

#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <span>
#include <string>
#include <string_view>

namespace game::secure {

enum class [[nodiscard]] PrivateRead : std::uint8_t {
    kOk,
    kMissing,
    kNotFile,
    kExposed,
    kIo,
    kWrongSize,
};

// true khi tệp riêng theo nghĩa trên. Sai (kể cả tệp thiếu) thì `error` nói vì sao; `label` là tên
// tệp trong câu lỗi.
[[nodiscard]] bool file_private(const std::filesystem::path& path, std::string_view label,
    std::string& error);

// Đọc đúng out.size() byte trên handle vừa xét quyền, để nội dung và quyền là một lần mở.
[[nodiscard]] PrivateRead read_private_exact(const std::filesystem::path& path,
    std::span<std::byte> out, std::string_view label, std::string& error);

// Tạo tệp mới (không ghi đè) với quyền riêng ngay lúc tạo, ghi hết `bytes` rồi đẩy xuống đĩa.
// Tệp đã có: `existed` = true, không đụng tệp, `error` trống. Ghi cụt thì xoá tệp vừa tạo.
[[nodiscard]] bool create_private_file(const std::filesystem::path& path, std::span<const std::byte> bytes,
    std::string_view label, bool& existed, std::string& error);

} // namespace game::secure
