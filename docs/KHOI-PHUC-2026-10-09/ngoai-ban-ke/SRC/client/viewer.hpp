// Cửa sổ xem cảnh của client. Mỗi nền tảng một tệp cài đặt, CMake chọn một: viewer_win32.cpp dùng
// module window, viewer_none.cpp cho nền tảng chưa có cửa sổ.
#pragma once

#include "client/stage.hpp"
#include "map/ground.hpp"

#include <cstdint>
#include <filesystem>
#include <optional>
#include <string>

namespace game::client {

struct ViewerDesc {
    // Tiêu đề cửa sổ, UTF-8.
    std::string title;
    // Số vòng lặp rồi tự thoát; không có thì chạy tới khi người dùng đóng cửa sổ.
    std::optional<std::uint32_t> frames;
    // Nội dung sẽ vẽ; null thì khung chỉ là màu nền. Mượn: phải sống lâu hơn run_viewer.
    const Stage* stage = nullptr;
    // Địa hình đã nạp; null khi cảnh không có. Mượn cùng đời với stage.
    const game::map::Ground* ground = nullptr;
    // Thư mục gốc dữ liệu (chứa Model/ và Material/); rỗng thì không nạp mesh nào.
    std::filesystem::path data_folder;
    // Ảnh chụp khung đầu tiên vẽ được; rỗng thì không chụp.
    std::filesystem::path shot;
    // Bật lớp kiểm tra của API đồ hoạ: bản dựng phát hành tắt mặc định cho đỡ hao CPU mỗi khung.
    bool is_validated = true;
};

// Mở cửa sổ và chạy tới khi nó đóng hoặc đủ số vòng lặp; trả mã thoát của tiến trình (0 là xong).
[[nodiscard]] int run_viewer(const ViewerDesc& desc);

} // namespace game::client
