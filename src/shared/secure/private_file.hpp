#pragma once
// Tệp bí mật trên đĩa: khoá danh tính của gate, khoá ipc, khoá HMAC của nhà cung cấp thanh toán, secrets.local.toml.
// "Riêng" là chỉ tài khoản chạy tiến trình đọc được: Windows chỉ SYSTEM, Administrators và chủ tiến trình (DACL không
// kế thừa khi tạo); POSIX chế độ 0600 của chủ. Máy chủ từ chối tệp lỏng hơn và không tự sửa quyền, để người vận hành
// biết bí mật có thể đã lộ và xoay nó.

#include <cstddef>
#include <filesystem>
#include <span>
#include <string>
#include <string_view>

namespace game::secure {

// true khi tệp riêng theo nghĩa trên. Sai (kể cả tệp thiếu) thì `error` nói vì sao; `label` là tên tệp trong câu lỗi.
[[nodiscard]] bool file_private(const std::filesystem::path& path, std::string_view label, std::string& error);

// Tạo tệp mới (không ghi đè) kèm quyền riêng ngay lúc tạo, ghi `bytes` rồi đẩy xuống đĩa: không có khe giữa "tạo" và
// "khoá quyền". Tệp đã có thì `existed` đặt true, không đụng gì tới tệp và `error` để trống. Ghi hỏng giữa chừng thì
// xoá tệp vừa tạo, để lần chạy sau không gặp một bí mật cụt.
[[nodiscard]] bool create_private_file(const std::filesystem::path& path, std::span<const std::byte> bytes,
    std::string_view label, bool& existed, std::string& error);

} // namespace game::secure
