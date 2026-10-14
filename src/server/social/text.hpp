#pragma once
// Kiểm chữ người chơi gõ, dùng chung cho tên bang, tên liên minh, tên chức vị, tâm trạng, tiêu đề thư.
// Mọi chuỗi từ client là dữ liệu thù địch: trước khi lưu phải qua UTF-8 chặt và chặn ký tự điều khiển.

#include <cstddef>
#include <string>
#include <string_view>

namespace game::social {

// UTF-8 hợp lệ (RFC 3629), không quá max_bytes byte, không ký tự điều khiển C0/DEL. Chuỗi rỗng hợp lệ.
[[nodiscard]] bool is_plain_text(std::string_view text, std::size_t max_bytes) noexcept;

// Số điểm mã của chuỗi đã qua is_plain_text.
[[nodiscard]] std::size_t codepoint_count(std::string_view text) noexcept;

// Chuỗi có dấu cách ở đầu hoặc cuối (ASCII) - tên như vậy dễ giả mạo tên khác.
[[nodiscard]] bool has_edge_space(std::string_view text) noexcept;

// Khoá so tên trùng: hạ chữ HOA ASCII xuống thường, giữ nguyên mọi byte còn lại. Không gập chữ Unicode
// (hoa/thường của chữ có dấu, chữ rộng toàn góc): ghi ở docs/SERVER-SOCIAL.md.
[[nodiscard]] std::string fold_name(std::string_view text);

} // namespace game::social
