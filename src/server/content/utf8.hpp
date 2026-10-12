#pragma once
// Việc kiểm byte của một tệp TSV: UTF-8, BOM, CR và xuống dòng cuối.

#include "content/detail/scan.hpp"

namespace game::content {

// true khi chữ đạt K1 phần byte. Lỗi đã ghi vào issues và lần sai đầu dừng.
[[nodiscard]] bool file_bytes_ok(TextView text, TextView path, IssueList& issues);

} // namespace game::content
