/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/gbk.hpp
 *  PHÂN HỆ   : Core / Gbk
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Giải chuỗi GBK (trang 936 của Windows) sang UTF-8 trên mọi nền. Dữ liệu
 *    của client gốc (all.material, script hạt) ghi tên ảnh bằng GBK, còn tên
 *    tệp trên đĩa là UTF-8. Trước đây chỉ Windows giải được
 *    (MultiByteToWideChar(936)); Android và iOS không có trang mã đó nên đường
 *    dẫn giữ byte GBK, không mở được tệp, và vỏ cây, đá, lá thành ảnh trắng.
 *    Quyết định: một bảng tra cho mọi nền, sinh từ chính
 *    MultiByteToWideChar(936) bằng TOOLS/content/gen_gbk_table.py, để PC và
 *    điện thoại giải ra cùng một chuỗi và test trên PC kiểm luôn đường của điện
 *    thoại.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <optional>
#include <string>
#include <string_view>

namespace game::core {

// nullopt khi text không phải GBK hợp lệ (như MultiByteToWideChar với MB_ERR_INVALID_CHARS): byte đầu đứng cuối chuỗi,
// cặp không có trong trang mã, byte đơn 0x81..0xFF. Byte dưới 0x80 giữ nguyên. O(n) theo số byte; chuỗi ra dài nhiều
// nhất 1,5 lần chuỗi vào (ký tự hai byte thành ba byte UTF-8).
[[nodiscard]] std::optional<std::string> utf8_from_gbk(std::string_view text);

} // namespace game::core
