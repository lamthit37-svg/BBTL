// Phần hiển thị của cửa sổ xem cảnh: một LUỒNG VẼ riêng giữ thiết bị đồ hoạ, màn hình vẽ và
// render::Forward, quay đều mỗi khung cho tới khi bị dừng — lõi của mọi engine mượt (o3de, Wicked):
// luồng thông điệp chỉ bơm thông điệp, không bao giờ chặn GPU, nên kéo hay đổi cỡ cửa sổ không bao
// giờ giật. Nội dung stage được luồng vẽ nạp một lần lúc khởi tạo: mỗi mesh một GLB (Model/<tên>.glb,
// ảnh ngoài giải trong thư mục dữ liệu), một upload, một Drawable; mỗi vật thể là một Instance với
// ma trận thế giới T * R * S từ phép đặt gốc. Luồng vẽ tự xoay camera quanh hộp bao thế giới theo
// đồng hồ, vẽ đèn directional đầu tiên và ambient của cảnh, và ghi PNG khung đầu (--shot).
// Hai bản cài đặt, CMake chọn một: display_gpu.cpp dùng module gpu và render (Vulkan, có lớp kiểm
// tra theo Desc), display_none.cpp cho cấu hình không dựng chuỗi đồ hoạ — không vẽ gì. Nhờ vậy mã
// gọi không cần biết cấu hình nào đang dựng.
#pragma once

#include "client/stage.hpp"
#include "core/error.hpp"
#include "map/ground.hpp"

#include <atomic>
#include <cstdint>
#include <filesystem>
#include <memory>
#include <string>

namespace game::client {

// Cỡ vùng vẽ của cửa sổ tính bằng điểm ảnh; bằng 0 khi cửa sổ đang thu nhỏ.
struct PixelSize {
    std::uint32_t width = 0;
    std::uint32_t height = 0;
};

struct DisplayDesc {
    // HWND của cửa sổ (window::Window::native_handle).
    void* window = nullptr;
    PixelSize size;
    // Bật lớp kiểm tra của API đồ hoạ; lỗi nó báo được đếm ở validation_errors.
    bool is_validated = true;
    // Nội dung sẽ vẽ; null hoặc không có vật thể thì khung chỉ là màu nền. Display mượn con trỏ:
    // stage phải sống lâu hơn Display.
    const Stage* stage = nullptr;
    // Địa hình của cảnh. Null khi cảnh không có .Terrain. Display mượn; ground sống lâu hơn Display.
    const game::map::Ground* ground = nullptr;
    // Thư mục gốc dữ liệu (chứa Model/ và Material/); rỗng thì không nạp mesh nào.
    std::filesystem::path data_root;
    // Ghi ảnh chụp khung đầu tiên vẽ được ra tệp PNG này; rỗng thì không chụp.
    std::filesystem::path shot_path;
};

class Display {
public:
    // Dựng luồng vẽ; khởi tạo thiết bị, màn hình vẽ và renderer xảy ra trên luồng ấy nên lỗi trả
    // về từ đây. Mượn cửa sổ và stage: Display phải bị huỷ trước cả hai.
    [[nodiscard]] static core::Result<Display> create(const DisplayDesc& desc);

    Display(Display&&) noexcept;
    Display& operator=(Display&&) noexcept;
    Display(const Display&) = delete;
    Display& operator=(const Display&) = delete;
    // Dừng luồng vẽ (nếu chưa dừng), chờ GPU rỗi cho tới khi mọi lệnh đã nộp chạy xong.
    ~Display();

    // Vùng vẽ của cửa sổ đã đổi cỡ: luồng vẽ dựng lại màn hình vẽ ở khung kế. An toàn mọi luồng,
    // không chặn.
    void notify_resized(PixelSize size) noexcept;
    // Dừng luồng vẽ và chờ GPU rỗi; trả lỗi vẽ đầu tiên của luồng (nếu có) hoặc lỗi khi chờ. Gọi
    // một lần trước khi huỷ; huỷ cũng tự gọi.
    [[nodiscard]] core::Status finish();
    // Số lỗi lớp kiểm tra đã báo, bản lưu gần nhất của luồng vẽ; 0 khi không bật.
    [[nodiscard]] std::uint64_t validation_errors() const noexcept;
    // Số lệnh vẽ của khung gần nhất; 0 ở bản không có chuỗi đồ hoạ.
    [[nodiscard]] std::uint32_t draw_count() const noexcept;
    // Luồng vẽ còn quay hay không: dừng khi lỗi vẽ hoặc mất thiết bị, vòng cửa sổ nên kết thúc.
    [[nodiscard]] bool is_spinning() const noexcept;
    // Một dòng mô tả để in ra: tên API và tên card, hoặc lý do không vẽ.
    [[nodiscard]] std::string description() const;

private:
    struct State;

    explicit Display(std::unique_ptr<State> state) noexcept;

    std::unique_ptr<State> state_;
};

} // namespace game::client
