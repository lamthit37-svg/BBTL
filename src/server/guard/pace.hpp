// Bước đi trên mặt phẳng ngang do máy chủ chấp nhận. Client không được đưa toạ độ vào đây.
// Một bước vượt tốc độ chạy chưa đủ để phạt: phải lặp lại. Dịch chuyển tức thì cũng vậy.
// Ngưỡng tốc độ lấy từ phép đo 4.65 m/s của bộ chống gian lận tham chiếu, đổi sang centimet
// vì thế giới này tính bằng centimet. Không xét độ cao: map có đồi, Y khác 0 không phải bay.
// Mốc chỉ dời tới bước nằm trong tầm. Bước vượt tầm chưa bị phạt vẫn không thành mốc, nên xen
// một bước thường giữa hai cú nhảy không xoá được chuỗi vi phạm. Bước cùng tick được đo với
// thời gian 0. Tick lùi bị bỏ qua và không dời mốc. Máy chủ dịch chuyển hợp lệ thì gọi reset().
#pragma once

#include <cstdint>

namespace game::guard {

enum class [[nodiscard]] Verdict : std::uint8_t { kOk, kSpeed, kTeleport };

struct Step {
    float x_cm = 0;
    float z_cm = 0;
    std::uint32_t tick = 0;
};

class Pace {
public:
    void reset() noexcept;
    [[nodiscard]] Verdict observe(Step step) noexcept;

private:
    bool has_step_ = false;
    float x_cm_ = 0;
    float z_cm_ = 0;
    std::uint32_t tick_ = 0;
    std::uint32_t speed_streak_ = 0;
    std::uint32_t teleport_streak_ = 0;
};

} // namespace game::guard
