/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/cast/cast.hpp
 *  PHÂN HỆ   : Client / Cast / Cast
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Các thực thể (quái, NPC, người chơi khác, vật rơi) máy chủ cho client thấy
 *    trong cảnh, và cách chúng chuyển động mượt trên màn hình.
 *  - Thuần logic: không đồ hoạ, không socket, đồng hồ từ ngoài vào (advance),
 *    nên PC, Android và iOS dùng chung và kiểm được bằng test.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Cách hỏng đã tính trước (CL-03):
//   máy chủ gửi quá nhiều thực thể -> trần kMaxActors, Spawn thừa bị bỏ và đếm ở dropped().
//   số NaN/vô cực                   -> cả tin bị bỏ, thực thể giữ trạng thái cũ.
//   tin về id chưa từng hiện        -> bỏ (EntityPos có thể tới sau EntityDisappear vì hàng đợi bỏ tin Entity*).
//   gói vị trí tới trễ hơn gói trước-> bỏ theo tick cảnh, so có dấu nên vòng 2^32 vẫn đúng.
//   khung hình dừng lâu             -> advance kẹp dt; tốc độ đuổi đích có trần, xa quá kSnapDistance thì đặt thẳng.
// Độ phức tạp: apply O(1), advance O(số thực thể); trần đầu vào kMaxActors.

#pragma once

#include "client/cast/note.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <unordered_map>
#include <vector>

namespace game::client::cast {

// Trần số thực thể giữ cùng lúc. Vùng nhìn của máy chủ (AOI) nhỏ hơn nhiều; trần chỉ chặn máy chủ hỏng hay độc hại.
inline constexpr std::size_t kMaxActors = 512;

// Một thực thể như đang vẽ: vị trí và hướng đã làm mượt, không phải gói mới nhất.
struct Actor {
    std::uint32_t id = 0;
    Kind kind = Kind::kMonster;
    std::uint32_t template_id = 0;
    std::string name;
    std::uint16_t level = 0;
    float x = 0.0F;
    float z = 0.0F;
    float facing = 0.0F;
    float speed = 0.0F;
    std::uint8_t hp_percent = 100;
    std::uint8_t gender = 0;
    std::uint16_t face = 0;
    std::uint16_t hair = 0;
    std::uint8_t school = 0;
    Pose pose = Pose::kIdle;
    // kFlagTalk...; Spawn mới đặt lại về 0, máy chủ gửi Flagged ngay sau khi hiện.
    std::uint8_t flags = 0;
};

class Cast {
public:
    // Áp một tin. Arrive xoá mọi thực thể cũ; Pulled không thuộc về Cast (nơi vẽ tự xử lý vị trí của chính mình).
    void apply(const Note& note);
    // Dời mọi thực thể về đích theo seconds giây. Đứng yên khi seconds không dương.
    void advance(float seconds);
    // Bỏ hết (rời cảnh, mất phiên).
    void clear() noexcept;

    // Các thực thể đang vẽ; thứ tự không có nghĩa và đổi khi có thực thể biến mất.
    [[nodiscard]] std::span<const Actor> actors() const noexcept { return actors_; }
    [[nodiscard]] const Actor* find(std::uint32_t id) const noexcept;
    // Cảnh của Arrive gần nhất; rỗng khi chưa có.
    [[nodiscard]] std::optional<std::uint16_t> scene() const noexcept { return scene_; }
    [[nodiscard]] std::uint32_t self_id() const noexcept { return self_id_; }
    // Sinh lực của chính nhân vật theo máy chủ (EntityVitals/EntityAppear của self_id); rỗng khi chưa nhận.
    [[nodiscard]] std::optional<std::uint8_t> self_hp() const noexcept { return self_hp_; }
    // Số Spawn đã bỏ vì chạm trần kMaxActors từ lúc dựng.
    [[nodiscard]] std::size_t dropped() const noexcept { return dropped_; }

private:
    // Phần của một thực thể mà nơi vẽ không cần biết: đích đang chạy tới.
    struct Goal {
        float x = 0.0F;
        float z = 0.0F;
        float facing = 0.0F;
        Pose pose = Pose::kIdle;
        std::uint32_t tick = 0;
        bool has_tick = false;
        // Đã đứng yên ở đích bao lâu khi máy chủ còn báo đang đi.
        float idle_for = 0.0F;
    };

    void on(const Arrive& note);
    void on(const Spawn& note);
    void on(const Vanish& note);
    void on(const Moved& note);
    void on(const Hurt& note);
    void on(const Pulled& /*note*/) noexcept {}
    void on(const Flagged& note);
    void on(const Died& note);
    // Ra chiêu và kết quả đòn không đổi trạng thái thực thể: nơi vẽ đọc chúng từ Note, Cast bỏ qua.
    void on(const Casting& /*note*/) noexcept {}
    void on(const CastEnded& /*note*/) noexcept {}
    void on(const Struck& /*note*/) noexcept {}
    static void step(Actor& shown, Goal& goal, float seconds) noexcept;
    // Dời shown về phía đích; trả khoảng cách còn lại TRƯỚC khi dời (thực thể có đang đi hay không).
    [[nodiscard]] static float chase(Actor& shown, const Goal& goal, float seconds) noexcept;
    void erase_at(std::size_t index);

    std::vector<Actor> actors_;
    std::vector<Goal> goals_;
    std::unordered_map<std::uint32_t, std::size_t> index_;
    std::optional<std::uint16_t> scene_;
    std::uint32_t self_id_ = 0;
    std::optional<std::uint8_t> self_hp_;
    std::size_t dropped_ = 0;
};

} // namespace game::client::cast
