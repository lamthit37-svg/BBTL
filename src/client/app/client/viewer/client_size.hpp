// Cỡ vùng chơi của cửa sổ PC, điểm ảnh: View_Resoution của System.cfg client 2026 ("1280,720").
// Client 2026 tạo cửa sổ kiểu 0xCA0000 (WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX: không viền kéo,
// không nút phóng to) nên người chơi không kéo méo tỉ lệ được; cỡ chỉ đổi qua cài đặt. Tỉ lệ khung
// chơi vì thế luôn là tỉ lệ của cỡ đã chọn. Số đo từ Bin64/Game.exe: hằng 0x500 x 0x2d0 ở hàm tạo
// cửa sổ, và hàm đặt độ phân giải nâng cỡ ngoài tối thiểu lên 0x320 x 0x258 (800 x 600).
#pragma once

#include <cstdint>

namespace game::client {

struct ClientSize {
    std::uint32_t width = 0;
    std::uint32_t height = 0;

    friend constexpr bool operator==(const ClientSize&, const ClientSize&) = default;
};

// Mặc định của client 2026: View_Resoution=1280,720 (16:9).
inline constexpr ClientSize kDefaultClientSize{.width = 1280, .height = 720};

// Thủ tục đăng nhập luôn mở cỡ này, bất kể View_Resoution: CGamePro_Login::Init (Game.exe
// 0x140630900) bỏ viền kéo và nút phóng to của cửa sổ rồi gọi 0x140631270, hàm đó đặt vùng chơi
// 0x500 x 0x2d0, khôi phục cửa sổ đang phóng to và canh giữa vùng làm việc.
inline constexpr ClientSize kLoginClientSize{.width = 1280, .height = 720};

// Nhỏ nhất mà cửa sổ giữ được đúng cỡ đã chọn: dưới 800 x 600 thì cửa sổ ngoài của client 2026 bị
// nâng lên 800 x 600 và vùng chơi không còn đúng cỡ.
inline constexpr ClientSize kMinClientSize{.width = 800, .height = 600};

// Lớn nhất một cạnh: giới hạn texture của D3D11/Vulkan mức thấp nhất, cũng chặn số vô lý.
inline constexpr std::uint32_t kMaxClientSide = 16384;

} // namespace game::client
