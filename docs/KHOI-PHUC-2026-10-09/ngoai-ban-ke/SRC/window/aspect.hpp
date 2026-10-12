// Giữ tỉ lệ vùng vẽ khi người dùng kéo mép cửa sổ. Client 2026 mở đúng View_Resoution (System.cfg
// mặc định 1280,720) và cửa sổ không được méo tỉ lệ đó; bản 2008 làm việc này ở KeepWindowFOV
// (WXClient/Procedure/GameProcedure.cpp@_ref) lúc WM_SIZING. Đây chỉ là số học trên chữ nhật cả
// cửa sổ nên thử được không cần Win32; window.cpp nối vào WM_SIZING và WM_GETMINMAXINFO.
// Quyết định: tỉ lệ là rộng:cao của vùng vẽ (không tính khung), nên khung dày bao nhiêu cũng không
// làm lệch. Kéo mép trái/phải thì rộng dẫn, trên/dưới thì cao dẫn, góc thì lấy hình lớn nhất vừa
// trong khung đề nghị; cạnh đối diện đứng yên.
// Khác gốc: tỉ lệ và cỡ nhỏ nhất là tham số (gốc đọc biến toàn cục), góc dùng hình vừa khung thay
// vì luôn để rộng dẫn.
#pragma once

#include "window/types.hpp"

#include <cstdint>

namespace game::window {

// Mép hay góc đang kéo, đúng giá trị WMSZ_* của WM_SIZING.
enum class DragEdge : std::uint8_t {
    kLeft = 1,
    kRight = 2,
    kTop = 3,
    kTopLeft = 4,
    kTopRight = 5,
    kBottom = 6,
    kBottomLeft = 7,
    kBottomRight = 8,
};

// Độ dày khung (viền và thanh tiêu đề) quanh vùng vẽ, điểm ảnh.
struct FrameInsets {
    std::int32_t left = 0;
    std::int32_t top = 0;
    std::int32_t right = 0;
    std::int32_t bottom = 0;
};

struct AspectFit {
    // Chữ nhật cả cửa sổ mà hệ thống đề nghị lúc đang kéo.
    Rect proposed;
    FrameInsets insets;
    // Tỉ lệ rộng:cao của vùng vẽ cần giữ, ví dụ 1280 và 720; có cạnh bằng 0 thì không chỉnh gì.
    Size ratio;
    // Vùng vẽ nhỏ nhất; {0, 0} là không đòi. Kết quả vẫn đúng tỉ lệ khi chạm sàn này.
    Size min_client;
    DragEdge edge = DragEdge::kRight;
};

// Chữ nhật cả cửa sổ sau khi chỉnh cho vùng vẽ đúng tỉ lệ; cạnh đối diện với phía đang kéo đứng yên.
[[nodiscard]] Rect fit_aspect(const AspectFit& fit) noexcept;

} // namespace game::window
