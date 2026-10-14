// Bước đi trên mặt phẳng ngang do máy chủ chấp nhận. Mốc đầu tiên do máy chủ đặt (reset với toạ độ
// sinh ra hoặc dịch chuyển hợp lệ), không bao giờ lấy từ bước đầu của client.
// Ngưỡng tốc độ lấy từ phép đo 4.65 m/s của bộ chống gian lận tham chiếu, đổi sang centimet
// vì thế giới này tính bằng centimet. Không xét độ cao: map có đồi, Y khác 0 không phải bay.
//
// Thời gian: client khai tick của bước, nhưng thời gian dùng để đo là min(tick client trôi, tick máy
// chủ trôi + kJitterTicks). Client khai tick vọt lên không mua thêm quãng đường (G2). Tick client lùi
// hoặc đứng yên thì bước bị đo với 0 tick; tick lùi không dời mốc và trả kRejected (G6).
//
// Vi phạm: mỗi bước vượt tầm cộng 1 điểm vào ngân sách tốc độ (hoặc dịch chuyển); ngân sách rò dần
// theo thời gian máy chủ. Xen bước thường giữa hai cú vượt không xoá điểm như chuỗi cũ (G3).
// Bước vượt tầm nhưng ngân sách chưa đầy trả kRejected: người gọi kéo về anchor(), chưa phạt (G4).
// Mốc chỉ dời tới bước được nhận (kOk); bước cùng tick đo với thời gian 0 nên nhảy trong một tick
// không lọt (G5).
#pragma once

#include <cstdint>

namespace game::guard {

enum class [[nodiscard]] Verdict : std::uint8_t {
    kOk, // nhận bước, mốc dời tới đây
    kRejected, // không nhận bước, chưa phạt: kéo về anchor()
    kSpeed, // không nhận bước và phạt: vượt tốc lặp lại
    kTeleport, // không nhận bước và phạt: dịch chuyển lặp lại
    kNoAnchor, // máy chủ chưa đặt mốc: không nhận bước nào
};

struct Step {
    float x_cm = 0;
    float z_cm = 0;
    std::uint32_t tick = 0; // tick client khai, chỉ dùng làm trần dưới của thời gian
};

struct Anchor {
    float x_cm = 0;
    float z_cm = 0;
};

class Pace {
public:
    // Máy chủ đặt mốc: lúc vào bản đồ, hồi sinh, dịch chuyển hợp lệ. Xoá ngân sách vi phạm.
    void reset(Anchor at, std::uint32_t client_tick, std::uint32_t server_tick) noexcept;
    // server_tick: tick máy chủ lúc nhận bước (đồng hồ của máy chủ, client không chạm được).
    [[nodiscard]] Verdict observe(Step step, std::uint32_t server_tick) noexcept;
    [[nodiscard]] Anchor anchor() const noexcept { return {.x_cm = x_cm_, .z_cm = z_cm_}; }

private:
    void leak(std::uint32_t server_ticks) noexcept;

    bool has_anchor_ = false;
    float x_cm_ = 0;
    float z_cm_ = 0;
    std::uint32_t client_tick_ = 0;
    std::uint32_t server_tick_ = 0;
    std::uint32_t leak_tick_ = 0;
    float speed_debt_ = 0;
    float teleport_debt_ = 0;
};

} // namespace game::guard
