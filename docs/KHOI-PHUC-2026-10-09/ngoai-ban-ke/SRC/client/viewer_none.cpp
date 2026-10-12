// Bản cho nền tảng chưa có module window (Android, iOS, Linux): không mở gì, chỉ báo cho người
// dùng.
#include "client/viewer.hpp"

#include <print>

namespace game::client {

int run_viewer(const ViewerDesc& /*desc*/) {
    std::println("Nền tảng này chưa có cửa sổ: chỉ in tóm tắt cảnh.");
    return 0;
}

} // namespace game::client
