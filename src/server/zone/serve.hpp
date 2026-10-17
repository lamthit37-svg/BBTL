/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/zone/serve.hpp
 *  PHÂN HỆ   : Server / Zone / Serve
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - zoned: nghe cổng ipc của zone trong cluster.toml, nhận kênh bền từ gate và
 *    chạy các cảnh ở nhịp đã chọn. Cổng 0 (cấp động, chỉ loopback) vẫn chạy;
 *    gate không tìm được thì không nối. Dòng `ready ipc=<cổng>` báo cổng thật
 *    cho giám sát.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/
#pragma once

#include <filesystem>

namespace game::zone {

[[nodiscard]] int serve(const std::filesystem::path& config_dir);

} // namespace game::zone
