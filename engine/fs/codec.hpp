/*==============================================================================
 *  ENGINEHP  |  HIGH-PERFORMANCE GAME ENGINE
 *------------------------------------------------------------------------------
 *  TỆP       : engine/fs/codec.hpp
 *  PHÂN HỆ   : Fs / Codec
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Nén, giải nén và băm khối cho archive — gói lz4, zstd, xxhash (vcpkg) sau
 *    một mặt phẳng nhỏ: archive không gọi thẳng thư viện ngoài, và checksum
 *    chuyển được xuống core sau này mà không đổi định dạng. Ngữ cảnh zstd và
 *    trạng thái lz4 là thread_local, dùng lại giữa mọi lần gọi (gốc cấp một
 *    ZSTD_DCtx cho mỗi mục mở, bộ ghi một ZSTD_CCtx mỗi luồng). Mức nén giữ
 *    luật của bộ ghi buny: lz4 mặc định HC 9, mức <= 0 là chế độ nhanh với
 *    acceleration = -mức, 1 và 2 kẹp lên 3; zstd mặc định 3.
 *  - Nguồn: Forge2 src/fs/codec.hpp@d7fcd76. Khác gốc: hết bộ nhớ cho trạng
 *    thái XXH3 thì core::check, không ném std::bad_alloc.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "fs/buny.hpp"

#include <cstddef>
#include <cstdint>
#include <memory>
#include <optional>
#include <span>

namespace game::fs {

// XXH3-64 seed 0 của byte lưu (khối đã nén): kiểm được trước khi đưa dữ liệu vào bộ giải nén.
[[nodiscard]] std::uint64_t checksum(std::span<const std::byte> data) noexcept;

// checksum tính dần qua nhiều khúc nối nhau, cùng kết quả với checksum trên cả vùng.
class Checksum {
public:
    // Hết bộ nhớ cho trạng thái XXH3 (vài trăm byte) thì core::check dừng tiến trình.
    Checksum();
    void update(std::span<const std::byte> data) noexcept;
    [[nodiscard]] std::uint64_t digest() const noexcept;

private:
    struct Free {
        void operator()(void* state) const noexcept;
    };

    // XXH3_state_t; void* để header không kéo xxhash.h.
    std::unique_ptr<void, Free> state_;
};

namespace codec {

// Mức nén hợp lệ và mặc định của một định dạng chia khối (bunyArLibCompressionLevelLimits).
struct Levels {
    int min = 0;
    int max = 0;
    int standard = 0;
};

[[nodiscard]] Levels levels(buny::Format format) noexcept;

// Giải nén packed vào out; cỡ ra phải đúng out.size(), không thì Corrupt.
[[nodiscard]] Status decode(buny::Format format, std::span<const std::byte> packed, std::span<std::byte> out);

// Nén data vào out, level kẹp vào [min, max]; nullopt khi kết quả không vừa out, tức khối nên để
// thô (bộ ghi đặt out nhỏ hơn data một byte để chỉ nhận khối nén thật sự nhỏ hơn).
[[nodiscard]] Result<std::optional<std::size_t>> encode(buny::Format format, int level, std::span<const std::byte> data,
    std::span<std::byte> out);

} // namespace codec

} // namespace game::fs
