// Ghi ảnh PNG từ một khung hình. _Ref chụp màn hình bằng stbi_write_png_to_mem (mức nén 4, một
// luồng) ngay trên luồng vẽ, sau khi chép cả ảnh sang bộ đệm khác để bỏ alpha. Ở đây ảnh chia thành
// các dải hàng; mỗi dải tự lọc (filter của PNG) và tự nén deflate trên một luồng của JobSystem, rồi
// các dải ghép lại thành một dòng zlib duy nhất (capture/deflate.hpp). Tệp ra là PNG chuẩn, mở được
// bằng mọi trình đọc; tests/capture_tests.cpp giải lại bằng bộ inflate viết riêng trong test và so
// từng byte điểm ảnh.
// Nguồn: Forge2 src/capture/png.hpp@d7fcd76. Khác gốc: enumerator mang tiền tố k; comment về phép
// thử và về Rgba32F nói theo THIENLONG (gốc thử bằng WIC, ảnh float đi qua capture/hdr.hpp chưa
// chép).
#pragma once

#include "capture/deflate.hpp"
#include "capture/frame.hpp"

#include <cstddef>
#include <cstdint>
#include <vector>

namespace game::jobs {
class JobSystem;
}

namespace game::capture {

struct PngOptions {
    // false: bỏ kênh alpha, ghi RGB (discardAlpha của _Ref). Ảnh chụp màn hình thường không cần
    // alpha và tệp nhỏ hơn.
    bool alpha = true;
    // Fast lọc mọi hàng bằng Up. Balanced chọn filter từng hàng theo tổng trị tuyệt đối. Best nén
    // mỗi dải theo cả hai cách và giữ bản nhỏ hơn, tốn gấp đôi thời gian.
    Effort effort = Effort::kFast;
    // Ghi chunk sRGB: điểm ảnh đã mã hoá sRGB, như ảnh lấy từ swapchain SDR.
    bool srgb = true;
    // Số byte thô của một dải nén độc lập. Dải nhỏ thì song song hơn, tệp to hơn một chút.
    std::size_t band_bytes = std::size_t{1} << 20U;
};

// Mã hoá frame thành nội dung một tệp PNG. Rgba8 và Bgra8 ra PNG 8 bit, Rgba16 ra PNG 16 bit.
// jobs khác null thì các dải nén song song và luồng gọi cùng làm. InvalidArgument khi frame không
// valid(); Unsupported cho Rgba32F (PNG không có mẫu float).
[[nodiscard]] Result<std::vector<std::byte>> encode_png(const FrameView& frame, const PngOptions& options = {},
    jobs::JobSystem* jobs = nullptr);

} // namespace game::capture
