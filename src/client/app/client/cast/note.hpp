/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/cast/note.hpp
 *  PHÂN HỆ   : Client / Cast / Note
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Tin thế giới mà phiên mạng đưa cho nơi vẽ ở dạng không biết giao thức: mét
 *    của game, hướng theo quy ước của client, trạng thái đã đổi sang Pose.
 *  - Bridge dịch từ protocol sang đây để Cast và Display không include protocol
 *    (Android và iOS vẫn dựng được hai thứ này).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/
#pragma once

#include <cstdint>
#include <string>
#include <variant>

namespace game::client::cast {

enum class Kind : std::uint8_t { kPlayer, kMonster, kNpc, kPet, kDrop, kObject };

enum class Pose : std::uint8_t { kIdle, kWalk, kDead };

// Một thực thể vào vùng nhìn.
struct Spawn {
    std::uint32_t id = 0;
    Kind kind = Kind::kMonster;
    // Id mẫu: quái (monsters.tsv) hay NPC; 0 với người chơi.
    std::uint32_t template_id = 0;
    // Tên của người chơi; rỗng với quái và NPC (nơi vẽ tra theo mẫu).
    std::string name;
    std::uint16_t level = 0;
    float x = 0.0F;
    float z = 0.0F;
    float facing = 0.0F;
    // Mét mỗi giây.
    float speed = 0.0F;
    std::uint8_t hp_percent = 100;
    // Ngoại hình người chơi: giới 1 nữ 2 nam, mặt, tóc, môn phái.
    std::uint8_t gender = 0;
    std::uint16_t face = 0;
    std::uint16_t hair = 0;
    std::uint8_t school = 0;
    Pose pose = Pose::kIdle;
};

// Thực thể rời vùng nhìn hay biến mất khỏi cảnh.
struct Vanish {
    std::uint32_t id = 0;
};

// Vị trí mới của một thực thể. tick là tick cảnh (20 mỗi giây), chỉ để bỏ gói cũ hơn gói đã nhận.
struct Moved {
    std::uint32_t id = 0;
    float x = 0.0F;
    float z = 0.0F;
    float facing = 0.0F;
    std::uint32_t tick = 0;
    Pose pose = Pose::kIdle;
};

// Sinh lực theo phần trăm.
struct Hurt {
    std::uint32_t id = 0;
    std::uint8_t hp_percent = 0;
};

// Nhân vật của người chơi vào một cảnh (lúc vào game và mỗi lần đổi cảnh): xoá hết thực thể cũ.
struct Arrive {
    std::uint16_t scene = 0;
    float x = 0.0F;
    float z = 0.0F;
    float facing = 0.0F;
    // Id thực thể của chính nhân vật; không bao giờ nằm trong danh sách vẽ.
    std::uint32_t self_id = 0;
};

// Máy chủ kéo nhân vật về một điểm (bước đi bị từ chối hay dịch chuyển): nơi vẽ đặt lại vị trí đã dự đoán.
struct Pulled {
    float x = 0.0F;
    float z = 0.0F;
};

// Cờ của thực thể (EntityFlags). Bit 0: bấm vào được để nói chuyện. Bit 1: vật rơi nhặt được.
inline constexpr std::uint8_t kFlagTalk = 1;
inline constexpr std::uint8_t kFlagPick = 2;

// Cờ mới của một thực thể đang thấy; thay cờ cũ, không cộng dồn.
struct Flagged {
    std::uint32_t id = 0;
    std::uint8_t flags = 0;
};

// Một thực thể bắt đầu ra chiêu (đánh thường cũng là một kỹ năng). seq khác 0 chỉ khi là chiêu do chính client nhờ: lúc đó
// nơi vẽ chạy động tác của nhân vật mình; client không đoán trước chiêu khi máy chủ chưa xác nhận. Điểm nhắm theo mét của
// game; bằng chỗ mục tiêu khi nhắm vào một thực thể.
struct Casting {
    std::uint32_t source = 0;
    std::uint16_t skill = 0;
    // 0 là không có mục tiêu thực thể.
    std::uint32_t target = 0;
    float x = 0.0F;
    float z = 0.0F;
    std::uint8_t level = 0;
    std::uint16_t seq = 0;
};

// Chiêu gom khí hay dẫn khí kết thúc hoặc bị ngắt giữa chừng.
struct CastEnded {
    std::uint32_t source = 0;
    std::uint16_t skill = 0;
    bool is_interrupted = false;
};

enum class Blow : std::uint8_t { kDamage, kHeal, kMiss, kImmune };

// Kết quả của một chiêu lên một mục tiêu; chiêu nhiều mục tiêu đến thành nhiều tin. value là lượng sát thương hay hồi, 0
// với kMiss và kImmune. source là 0 khi không rõ kẻ gây (hiệu ứng treo).
struct Struck {
    std::uint32_t source = 0;
    std::uint32_t target = 0;
    std::uint16_t skill = 0;
    Blow kind = Blow::kDamage;
    std::int32_t value = 0;
    // Hội tâm (chí mạng).
    bool is_critical = false;
};

// Một thực thể chết (có thể là chính nhân vật). Xác còn lại một lúc rồi mới có Vanish.
struct Died {
    std::uint32_t id = 0;
    // Kẻ hạ gục; 0 nếu không rõ.
    std::uint32_t killer = 0;
};

// Ghim vị trí do chính client tính (thú demo đi theo). Không phải tin giao thức.
// advance một khung kế chép điểm này lên người, không đuổi như Moved.
struct Placed {
    std::uint32_t id = 0;
    float x = 0.0F;
    float z = 0.0F;
    float facing = 0.0F;
    Pose pose = Pose::kIdle;
};

// Canh giờ trong game theo máy chủ (GCWorldTime của gốc): 0 (Tý) tới 11 (Hợi). Máy chủ gửi sau mỗi
// lần vào cảnh và mỗi lần canh đổi; minimap hiện chữ canh và GetCurrentTime của script đọc số này.
struct Clocked {
    std::uint8_t watch = 0;
};

using Note = std::variant<Arrive, Spawn, Vanish, Moved, Hurt, Pulled, Flagged, Casting, CastEnded,
    Struck, Died, Placed, Clocked>;

} // namespace game::client::cast
