/*==============================================================================
 *  THIENLONG  |  GAME SERVER
 *------------------------------------------------------------------------------
 *  TỆP       : src/server/play/stage.hpp
 *  PHÂN HỆ   : Server / Play / Stage
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hai thứ gameplay chia sẻ với zone: Surroundings (zone cho gameplay biết
 *    và làm hộ trên cảnh: NPC, người và quái quanh, xác, vật rơi, tin phát cho
 *    người quanh) và Output (tin riêng từng phiên, trạng thái cần ghi).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Gameplay không biết Scene: mọi việc trên cảnh đi qua Surroundings để thử được riêng. Tin phát cho cả vùng nhìn đi qua
// Surroundings::tell (cảnh biết ai đang nhìn), tin riêng một người đi qua Output.

#pragma once

#include "account/play.hpp"
#include "protocol/messages.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <span>
#include <string>
#include <utility>
#include <vector>

namespace game::play {

class Surroundings {
public:
    // NPC nói chuyện được: `entity` là id thực thể trong cảnh (duy nhất mỗi cảnh, khác GUID của bảng cảnh vốn có thể trùng).
    struct Npc {
        std::uint32_t entity = 0;
        std::int32_t scene = -1;
        // GUID của bảng cảnh: khoá của danh bạ nhiệm vụ theo NPC (không duy nhất trong cảnh; `entity` mới duy nhất).
        std::uint32_t guid = 0;
        std::uint32_t script = 0;
        std::string name;
    };
    // Thực thể được hỏi (đóng gói để không lẫn với mã phiên cùng kiểu số nguyên).
    struct Target {
        std::uint32_t entity = 0;
    };
    struct Spot {
        std::uint32_t entity = 0;
        std::int32_t scene = -1;
    };
    struct Presence {
        std::int32_t hero_scene = -1;
        std::int32_t npc_scene = -1;
        float distance_m = 0.0F;
    };
    // Một thực thể trong cảnh nhìn từ chiến đấu: loại, mẫu, cấp, chỗ đứng (centimet nguyên) và sống hay chết.
    struct Unit {
        std::uint32_t entity = 0;
        protocol::EntityKind kind = protocol::EntityKind::kMonster;
        std::uint32_t template_id = 0;
        std::uint16_t level = 0;
        std::int32_t x_cm = 0;
        std::int32_t z_cm = 0;
        std::uint8_t hp_percent = 100;
        bool dead = false;
        // Chỉ `unit()` điền tên (units_near để trống cho nhẹ).
        std::string name;
    };
    // Chỗ và mẫu của một vật rơi cần đặt vào cảnh.
    struct DropSpot {
        std::uint32_t item_template = 0;
        std::int32_t x_cm = 0;
        std::int32_t z_cm = 0;
    };
    // Cảnh của một lời hỏi, đóng gói để không lẫn với id thực thể cùng kiểu số nguyên.
    struct Place {
        std::uint16_t scene = 0;
        std::uint32_t entity = 0;
    };

    Surroundings() = default;
    Surroundings(const Surroundings&) = delete;
    Surroundings& operator=(const Surroundings&) = delete;
    Surroundings(Surroundings&&) = delete;
    Surroundings& operator=(Surroundings&&) = delete;
    virtual ~Surroundings() = default;

    // NPC (kind = Npc) có id thực thể `entity` trong cảnh của người chơi `session`; nullopt khi không có hay không phải NPC.
    [[nodiscard]] virtual std::optional<Npc> npc(std::uint64_t session, Target target) const = 0;
    // Cảnh và khoảng cách (mét, 2D) giữa người chơi và NPC; nullopt khi một trong hai không còn.
    [[nodiscard]] virtual std::optional<Presence> presence(std::uint64_t session, Spot npc) const = 0;

    // ---- chiến đấu ----
    // Thực thể sống trong cảnh; nullopt khi id lạ hay đã biến mất.
    [[nodiscard]] virtual std::optional<Unit> unit(Place place) const = 0;
    // Mọi thực thể trong vùng nhìn quanh `place.entity` (gồm chính nó), thêm vào `out`.
    virtual void units_near(Place place, std::vector<Unit>& out) const = 0;
    // Gửi một khung cho mọi người chơi trong vùng nhìn quanh `place.entity`; `include_self` là gồm cả chính nó nếu nó là người.
    virtual void tell(Place place, std::span<const std::byte> frame, bool include_self) = 0;
    // Sinh lực theo phần trăm của thực thể đổi (báo EntityVitals cho người quanh).
    virtual void hurt(Place place, std::uint8_t percent) = 0;
    // Thực thể chết: nằm lại, quái hồi sinh theo bảng. EntityDied do nơi gọi phát qua tell.
    virtual void fell(Place place) = 0;
    // Người chơi hồi sinh tại (x_cm, z_cm) với sinh lực `percent`.
    virtual void raise(Place place, std::int32_t x_cm, std::int32_t z_cm, std::uint8_t percent) = 0;
    // Người chơi lên cấp: cảnh nhớ cấp mới cho người nhìn sau này.
    virtual void promote(Place place, std::uint16_t level) = 0;
    // Đặt một vật rơi (nhặt được) vào cảnh; nullopt khi cảnh hết chỗ.
    [[nodiscard]] virtual std::optional<std::uint32_t> drop(std::uint16_t scene, const DropSpot& spot) = 0;
    // Gỡ một vật rơi (đã nhặt hay hết hạn).
    virtual void sweep(Place place) = 0;
};

struct Output {
    struct Frame {
        std::uint64_t session = 0;
        std::vector<std::byte> bytes;
    };
    // Trạng thái chơi cần ghi: host ghép với điểm đứng hiện tại của nhân vật thành một lần ghi.
    struct Keep {
        std::uint64_t session = 0;
        std::uint64_t character = 0;
        account::PlayRecord record;
    };

    std::vector<Frame> frames;
    std::vector<Keep> keeps;
    // Tin không mã hoá được (trường quá trần): scene luôn điền trong trần, nên đây là lỗi lập trình lộ ra bằng số.
    std::size_t encode_failures = 0;

    template <typename Message>
    void down(std::uint64_t session, const Message& message) {
        std::vector<std::byte> bytes;
        if (!protocol::encode(bytes, message)) {
            ++encode_failures;
            return;
        }
        frames.push_back(Frame{.session = session, .bytes = std::move(bytes)});
    }
    void reject(std::uint64_t session, std::uint16_t request, protocol::ErrorCode code) {
        down(session, protocol::Reject{.request = request, .code = code});
    }
};

} // namespace game::play
