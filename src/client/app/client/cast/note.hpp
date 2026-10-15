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

using Note = std::variant<Arrive, Spawn, Vanish, Moved, Hurt, Pulled>;

} // namespace game::client::cast
