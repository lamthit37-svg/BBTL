// Tuỳ chọn dòng lệnh của thienlong_client, tách khỏi main để kiểm được bằng test. Mỗi tuỳ chọn là
// một cặp "--khoá giá trị"; sai cách dùng thì không có kết quả, main in hướng dẫn và thoát mã 2.
#pragma once

#include "client/viewer/client_size.hpp"

#include <cstdint>
#include <filesystem>
#include <optional>
#include <span>
#include <string>
#include <string_view>

namespace game::client {

inline constexpr std::string_view kUsage =
    "Cách dùng: thienlong_client [--scene-id <resid>] [--scene <tên map>] [--data <thư mục>]\n"
    "                         [--frames <số vòng>] [--shot <tệp.png>] [--validate]\n"
    "                         [--backend <tên>] [--size <rộng>x<cao>] [--login] [--bare] [--pace]\n"
    "--scene-id là resid trong Config/SceneDefineEx.txt. --scene tìm tên file .Scene trong bảng "
    "đó.\n"
    "Không nêu --scene và --scene-id: mở đăng nhập, như bấm đúp exe. Nút vào game đọc "
    "Config/startup.id.\n"
    "--shot: ghi ảnh chụp khung đầu tiên vẽ được ra tệp PNG.\n"
    "--size: cỡ vùng chơi, như View_Resoution của client 2026 (1280x720 hoặc 1280,720), mỗi\n"
    "cạnh từ 800x600 tới 16384. Không nêu thì 1280x720. Cửa sổ cố định như bản gốc.\n"
    "--backend: vulkan, gles, d3d12 hoặc d3d11. Không nêu thì tự chọn.\n"
    "--validate: bật lớp kiểm tra của API đồ hoạ (bản debug bật sẵn, bản phát hành tắt cho nhanh).\n"
    "--login: mở thủ tục đăng nhập (bảng nhập tài khoản) thay vì vào thẳng một cảnh.\n"
    "--bare: không vẽ lớp giao diện, chỉ cảnh 3D và hiệu ứng; dùng với --shot để chụp cảnh nền.\n"
    "--pace: mở bảng đo nhịp khung ngay từ đầu (F11 bật tắt), so với ngân sách khung của 120 Hz.";

struct Options {
    // Rỗng: không chọn theo tên file. resid được ưu tiên hơn tên này.
    std::string scene_name;
    // resid trong SceneDefineEx.txt. Không nêu thì không chọn theo số.
    std::optional<int> scene_id;
    // Rỗng: lấy <thư mục chứa exe>/../assets.
    std::filesystem::path data_folder;
    // Số vòng lặp của cửa sổ rồi tự thoát, cho chạy tự động; không có thì chạy tới khi đóng cửa sổ.
    std::optional<std::uint32_t> frames;
    // Ảnh chụp khung đầu tiên vẽ được; rỗng thì không chụp.
    std::filesystem::path shot_path;
    // Bật lớp kiểm tra của API đồ hoạ; không nêu thì theo loại bản dựng (debug bật, phát hành tắt).
    std::optional<bool> validate;
    // Rỗng: tự chọn. Có thì ép đúng backend đó, không đổi sang backend khác.
    std::optional<std::string> backend;
    // Cỡ vùng chơi của cửa sổ PC; không nêu thì kDefaultClientSize (View_Resoution của 2026).
    std::optional<ClientSize> client_size;
    // Ép mở đăng nhập kể cả khi đã nêu --scene hoặc --scene-id. Không nêu cảnh thì main cũng
    // mở đăng nhập, để bấm đúp exe vào được game.
    bool is_login = false;
    // Không vẽ lớp giao diện (khung, nút, chữ, bảng đo): khung hình chỉ còn cảnh 3D và hiệu ứng.
    bool is_bare = false;
    // Mở bảng đo nhịp khung ngay từ khung đầu; F11 vẫn bật tắt như thường.
    bool shows_pace = false;
};

using Arguments = std::span<const std::string_view>;

// Tuỳ chọn đọc từ các đối số sau tên exe; không có khi sai cách dùng. Không đối số nào là hợp lệ.
[[nodiscard]] std::optional<Options> parse_options(Arguments arguments);

using SceneNames = std::span<const std::string>;
using SceneChoice = std::optional<std::string>;

// Cảnh sẽ mở: cảnh được nêu; không nêu thì cảnh duy nhất trong available; còn lại không có.
[[nodiscard]] SceneChoice choose_scene(std::string_view requested, SceneNames available);

} // namespace game::client
