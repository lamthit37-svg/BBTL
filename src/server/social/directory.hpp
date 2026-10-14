#pragma once
// Cổng hỏi "ai đang là ai" mà lõi xã hội cần nhưng không sở hữu: bảng người chơi trực tuyến nằm ở
// tiến trình world (tương ứng OnlineUser của WorldServer 2008). Lõi chỉ đọc qua giao diện này nên
// test dùng bản giả và world dùng bảng thật. Mọi hàm chỉ đọc, không cấp quyền sửa.

#include "social/types.hpp"

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace game::social {

// Cờ cài đặt của người chơi (GAME_SETTING_FLAG của 2008, nửa thấp cần ở world).
namespace setting {
inline constexpr std::uint32_t kCannotAddFriend = 1U << 0U;
inline constexpr std::uint32_t kCannotReceiveMail = 1U << 1U;
inline constexpr std::uint32_t kCannotReceiveStrangerMail = 1U << 2U;
inline constexpr std::uint32_t kRefuseTeamInvite = 1U << 3U;
} // namespace setting

enum class PlayerStatus : std::uint8_t {
    kNormal = 0,   // đang chơi bình thường: nhận được hộp thoại
    kBusy,         // đang chuyển cảnh, giao dịch hoặc hộp thoại khác: không trả lời được ngay
};

// Ảnh chụp thông tin một người chơi ở thời điểm hỏi. Không giữ qua tick.
struct PlayerCard {
    CharacterId id{};
    std::string name;
    std::uint16_t level = 0;
    std::uint8_t sect = 0;     // 0..15 trừ 9 (ids::kSectNone)
    std::uint8_t sex = 0;      // 0 nữ, 1 nam (CharacterRecord của client 2026)
    std::uint32_t portrait = 0;
    SceneId scene{};
    std::uint8_t camp = 0;
    GuildId guild{};           // 0 = chưa vào bang
    std::string title;
    bool online = false;
    PlayerStatus status = PlayerStatus::kNormal;
    std::uint32_t settings = 0;

    [[nodiscard]] bool has(std::uint32_t flag) const noexcept { return (settings & flag) != 0; }
};

class PlayerDirectory {
public:
    PlayerDirectory() = default;
    PlayerDirectory(const PlayerDirectory&) = delete;
    PlayerDirectory& operator=(const PlayerDirectory&) = delete;
    PlayerDirectory(PlayerDirectory&&) = delete;
    PlayerDirectory& operator=(PlayerDirectory&&) = delete;
    virtual ~PlayerDirectory() = default;

    // Người chơi đang hiện diện (kể cả ngoại tuyến nếu world còn giữ hồ sơ). Không có thì nullopt.
    [[nodiscard]] virtual std::optional<PlayerCard> find(CharacterId id) const = 0;
    // Tìm theo tên, không phân biệt hoa thường theo quy tắc của world. Tên là chữ do client gửi.
    [[nodiscard]] virtual std::optional<PlayerCard> find_by_name(std::string_view name) const = 0;
    // Hai bên có thù địch (khác phe) hay không: dùng cho mời đội, kết bạn, thì thầm.
    [[nodiscard]] virtual bool hostile(const PlayerCard& left, const PlayerCard& right) const = 0;
};

} // namespace game::social
