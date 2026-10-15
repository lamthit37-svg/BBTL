/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/core/trace.hpp
 *  PHÂN HỆ   : Core / Trace
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Ghi vết tệp dữ liệu mà tiến trình đã mở để đọc, phục vụ dựng gói APK và
 *    bundle iOS: bao đóng thật của một cảnh là những gì client PC mở, không
 *    phải danh sách ai đó viết tay.
 *  - Bật bằng biến môi trường THIENLONG_TRACE_FILES=<tệp>; không đặt thì mỗi
 *    lời gọi chỉ là một lần đọc cờ, không I/O.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include <string_view>

namespace game::core {

// Ghi path (UTF-8) vào tệp vết nếu bật; mỗi đường dẫn đúng một lần, mỗi dòng một đường. Gọi từ mọi luồng, không ném.
// Lỗi ghi (đĩa đầy, tệp vết không mở được) tắt việc ghi vết chứ không ảnh hưởng chương trình. Mỗi dòng được xả ngay để
// tiến trình bị dừng đột ngột vẫn để lại vết. Độ phức tạp O(1) trung bình; tập đường dẫn chỉ lớn bằng số tệp khác nhau
// mà tiến trình mở (bao đóng một cảnh, hàng chục nghìn).
void trace_file(std::string_view path) noexcept;

} // namespace game::core
