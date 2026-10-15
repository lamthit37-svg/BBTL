/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/app/client/display/creature.hpp
 *  PHÂN HỆ   : Client / Display / Creature
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Quái và NPC trên màn hình: phần dùng chung của mọi thực thể cùng template
 *    (hình đã giải, xương và clip, lưới đã tải lên GPU) và phần riêng của từng
 *    thực thể (clip đang phát, tư thế skin, ma trận đặt). Lớp này không giữ tài
 *    nguyên GPU: nơi vẽ nạp lưới giúp qua CreatureMeshLoader, giống
 *    PlayerActor, nên huỷ một thực thể không đụng tới GPU.
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Hướng mặt 0 là +z (quy ước của client gốc: hướng = atan2(dx, dz)), cùng quy ước với PlayerActor.
//
// Cách hỏng đã tính trước (CL-03):
//   thiếu xương hay clip, lưới không nạp -> create trả lỗi, nơi vẽ ghi log một lần cho template đó và không vẽ.
//   một lưới trong mô hình không nạp được -> bỏ lưới đó, vẽ phần còn lại (như PlayerActor).
//   mô hình tĩnh                         -> không dựng avatar; vẽ ở tư thế nghỉ của lưới.
//   tỉ lệ khác 1 theo từng trục          -> ma trận đặt phóng theo ba trục riêng.

#pragma once

#include "avatar/avatar.hpp"
#include "avatar/gait.hpp"
#include "core/clock.hpp"
#include "core/error.hpp"
#include "look/creature.hpp"
#include "math/matrix.hpp"
#include "math/vector.hpp"
#include "render/forward.hpp"

#include <cstdint>
#include <filesystem>
#include <functional>
#include <future>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <vector>

namespace game::client {

// Bốn bảng quái và NPC đọc ở luồng riêng (thư mục Table/ dưới data_root); nullptr khi thiếu hay hỏng, lỗi đã in ra.
using CreatureTablesJob = std::future<std::shared_ptr<const look::CreatureTables>>;
[[nodiscard]] CreatureTablesJob start_creature_tables(std::filesystem::path data_root);

// Lưới (tên dưới Model/) kèm material chồng (nullptr là dùng material của lưới) thành drawable đã tải lên GPU; nullptr khi
// không nạp được. Drawable phải sống lâu hơn mọi CreatureAsset đã dùng nó.
using CreatureMeshLoader = std::function<const render::Drawable*(const std::string& mesh, const look::CreatureMaterial* skin)>;

// Chỗ đứng của một thực thể trong một khung: chân ở toạ độ thế giới, hướng mặt (radian), đang đi hay không.
struct CreatureStand {
    math::Point3 foot;
    float facing = 0.0F;
    bool is_moving = false;
};

class CreatureAsset {
public:
    // Nạp xương và clip (nếu mô hình có xương) rồi các lưới. Lỗi khi thiếu tệp xương hay clip, hoặc không lưới nào nạp được.
    [[nodiscard]] static core::Result<std::shared_ptr<const CreatureAsset>> create(look::CreatureFigure figure,
        const look::CreatureTables& tables, const std::filesystem::path& data_root, const CreatureMeshLoader& load_mesh);

    // Rỗng khi mô hình tĩnh.
    [[nodiscard]] const std::optional<avatar::Avatar>& avatar() const noexcept { return avatar_; }
    [[nodiscard]] std::span<const render::Drawable* const> parts() const noexcept { return parts_; }
    [[nodiscard]] const look::CreatureFigure& figure() const noexcept { return figure_; }

    // Dựng từ phần đã nạp; nơi gọi dùng create, hàm này công khai chỉ để make_shared gọi được.
    CreatureAsset(look::CreatureFigure figure, std::optional<avatar::Avatar> avatar,
        std::vector<const render::Drawable*> parts)
        : figure_(std::move(figure)), avatar_(std::move(avatar)), parts_(std::move(parts)) {}

private:
    look::CreatureFigure figure_;
    std::optional<avatar::Avatar> avatar_;
    std::vector<const render::Drawable*> parts_;
};

class CreatureActor {
public:
    // seed cho khoảng nghỉ ngẫu nhiên của riêng thực thể này, để hai NPC đứng cạnh nhau không nghỉ cùng lúc.
    CreatureActor(std::shared_ptr<const CreatureAsset> asset, std::uint32_t seed);

    // Dựng tư thế và ma trận đặt ở thời điểm now; now không được lùi.
    [[nodiscard]] core::Status update(core::Clock::time_point now, const CreatureStand& stand);
    // Thêm một instance cho mỗi lưới; ma trận skin trỏ vào bộ đệm của lần update gần nhất.
    void append(std::vector<render::Instance>& out) const;

private:
    std::shared_ptr<const CreatureAsset> asset_;
    avatar::Gait gait_;
    avatar::Skinner skinner_;
    avatar::ClipLengths lengths_;
    math::Matrix4 placed_ = math::Matrix4::identity();
};

} // namespace game::client
