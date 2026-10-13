// Trạng thái của nhân vật người chơi mà giao diện hiển thị: tên, cấp, máu, khí, nộ, kinh nghiệm,
// điểm liên kích, chân dung, và các số của bảng nhân vật (môn phái, năm chỉ số gốc, tám chỉ số
// chiến đấu, hoạt lực, tinh lực, điểm trang bị, các mốc mở tính năng). Client gốc giữ các số này
// trong CCharacterData do gói máy chủ cập nhật (GCCharBaseAttrib, GCDetailAttrib) rồi script Lua
// đọc qua Player:GetData; ở đây là một giá trị thuần: phần mạng (khi có) ghi vào, các bảng của
// ui/panel đọc. Không GPU, không đồng hồ, không tệp, nên dựng và test được ở mọi preset.
// Chưa có máy chủ thì client dùng newcomer(): nhân vật vừa tạo theo cấu hình của máy chủ gốc.
#pragma once

#include <algorithm>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::hero {

// Một chỉ số có trần (máu, khí, nộ, kinh nghiệm). Dữ liệu đúng thì now nằm trong 0..top.
struct Gauge {
    std::int64_t now = 0;
    std::int64_t top = 0;
};

// Phần đầy của chỉ số trong 0..1, như SetProgress(now, top) của script gốc: trần bằng 0 thì chia
// cho 1 (PlayerFrame.lua), kết quả kẹp về 0..1.
[[nodiscard]] constexpr float fill_of(Gauge gauge) noexcept {
    const std::int64_t top = gauge.top == 0 ? 1 : gauge.top;
    const double part = static_cast<double>(gauge.now) / static_cast<double>(top);
    return static_cast<float>(std::clamp(part, 0.0, 1.0));
}

// Khoá của bảng chân dung (CharacterFace.txt của client); máy chủ gửi số này cho từng nhân vật.
enum class PortraitId : std::int32_t {};

// Số ô điểm liên kích trên khung nhân vật (PlayerFrame_DoubleHit1..9).
inline constexpr std::uint8_t kStrikeSlots = 9;

// Môn phái theo số MENPAI của máy chủ gốc (Player:GetData("MEMPAI")), 0..15. Chỉ đặt tên số mà
// mã dùng tới: 9 là chưa nhập môn; bảng tên của cả mười sáu số nằm ở nơi hiển thị.
enum class Sect : std::uint8_t { kNone = 9 };

// Năm chỉ số gốc: STR, SPR, CON, INT, DEX của Player:GetData.
struct Roots {
    std::int32_t strength = 0;
    std::int32_t spirit = 0;
    std::int32_t constitution = 0;
    std::int32_t stability = 0;
    std::int32_t agility = 0;

    friend constexpr bool operator==(const Roots&, const Roots&) = default;
};

// Tám chỉ số chiến đấu: ATT_PHYSICS, ATT_MAGIC, DEF_PHYSICS, DEF_MAGIC, HIT, MISS, CRITICALATTACK,
// CRITICALDEFENCE.
struct Combat {
    std::int32_t attack_physical = 0;
    std::int32_t attack_magic = 0;
    std::int32_t defence_physical = 0;
    std::int32_t defence_magic = 0;
    std::int32_t hit = 0;
    std::int32_t miss = 0;
    std::int32_t critical_attack = 0;
    std::int32_t critical_defence = 0;

    friend constexpr bool operator==(const Combat&, const Combat&) = default;
};

// Phần tu luyện cộng thêm (XIULIAN_*); bảng nhân vật không hiện phần cộng của hai chỉ số hội tâm.
struct Cultivation {
    Roots roots;
    Combat combat;
};

// Mốc mở tính năng mà bảng nhân vật xét: đang có con, nhiệm vụ võ ý đã xong, và năm nhiệm vụ mà
// SelfEquip.lua bản 2026 hỏi bằng DataPool:Lua_IsMissionHaveDone: 1651 (bí tịch), 1600 (chân
// nguyên), 1554 (kinh mạch), 1950 (thần khí), 1564 (tinh bàn).
enum class Milestone : std::uint8_t {
    kChild,
    kManual,
    kTrueEssence,
    kMeridian,
    kMartialIntent,
    kArtifact,
    kStarChart,
};

// Tập các mốc đã đạt.
struct Milestones {
    std::uint8_t bits = 0;

    [[nodiscard]] constexpr bool has(Milestone mark) const noexcept {
        const auto mask = static_cast<unsigned>(bits);
        return ((mask >> static_cast<unsigned>(mark)) & 1U) != 0U;
    }
    constexpr void add(Milestone mark) noexcept {
        bits = static_cast<std::uint8_t>(bits | (1U << static_cast<unsigned>(mark)));
    }
    // Tập chỉ gồm một mốc.
    [[nodiscard]] static constexpr Milestones of(Milestone mark) noexcept {
        Milestones only;
        only.add(mark);
        return only;
    }
    // Đã đạt mọi mốc của wanted; wanted rỗng thì luôn đúng.
    [[nodiscard]] constexpr bool covers(Milestones wanted) const noexcept {
        return (bits & wanted.bits) == wanted.bits;
    }
};

// Khoá lên cấp của nhân vật (SelfEquip_CheckLevelupLock): chưa khoá, đang khoá, đang chờ mở.
enum class LevelLock : std::uint8_t { kOpen, kLocked, kOpening };

// Tiền và điểm nằm ở hòm đồ (Player:GetData "MONEY", "MONEY_JZ", "YUANBAO", "BIND_YUANBAO", "GIFTTOKEN",
// "ZENGDIAN", "LIJIN"). Đơn vị đồng; ô tiền của client gốc chỉ nhận int (FalagardMoney::setMoneyNumber).
// Mọi số do máy chủ gửi; nhân vật mới là 0.
struct Purse {
    std::int32_t money = 0;
    std::int32_t money_voucher = 0;
    std::int32_t yuanbao = 0;
    std::int32_t bind_yuanbao = 0;
    std::int32_t gift_token = 0;
    std::int32_t bonus_point = 0;
    std::int32_t cash_gift = 0;
};

struct Hero {
    std::string name;
    std::int32_t level = 1;
    Gauge health;
    Gauge mana;
    Gauge rage;
    Gauge experience;
    // Điểm liên kích đang có, 0..kStrikeSlots.
    std::uint8_t strike_points = 0;
    PortraitId portrait{};
    // Đang là đội trưởng: khung nhân vật hiện dấu đội trưởng.
    bool is_leader = false;
    Sect sect = Sect::kNone;
    Roots roots;
    // Điểm tiềm năng chưa phân (POINT_REMAIN).
    std::int32_t spare_points = 0;
    Combat combat;
    // Có giá trị khi XIULIANFLAG > 0.
    std::optional<Cultivation> cultivation;
    // Hoạt lực và tinh lực (VIGOR, ENERGY).
    Gauge vigor;
    Gauge energy;
    // Điểm trang bị (BATTLESCORE).
    std::int32_t battle_score = 0;
    // Cấp cao nhất máy chủ đang cho lên (Lua_GetMyMaxLevelLimit); 129 là số mặc định của
    // SelfEquip.lua bản 2026.
    std::int32_t level_cap = 129;
    Milestones milestones;
    LevelLock level_lock = LevelLock::kOpen;
    Purse purse;
};

// Lên cấp được chưa, như Player:IsCanLevelup của Game.exe 2026 (0x1403954d0): kinh nghiệm đang có
// không nhỏ hơn kinh nghiệm cần.
[[nodiscard]] constexpr bool can_level_up(const Hero& hero) noexcept {
    return hero.experience.now >= hero.experience.top;
}

// Nhân vật vừa tạo, chưa nhập môn phái: cấp 1, máu và khí đầy, nộ 0, kinh nghiệm 0, chỉ số gốc
// và chỉ số chiến đấu theo cấu hình của máy chủ gốc.
[[nodiscard]] Hero newcomer();

// Kinh nghiệm cần để lên cấp kế, theo Config/PlayerExpLevel.txt của client 2026: bảng DBC hai cột
// (INT cấp, STRING số cần, vì cấp cao vượt int32 của cột INT). Phần tử i là số cần ở cấp i + 1.
using ExpTable = std::vector<std::int64_t>;

// Đọc cả tệp DBC. Lỗi là câu tiếng Việt ngắn: sai dấu bảng, sai kiểu cột, cấp không liền từ 1, số
// cần không phải số nguyên dương, hoặc tham chiếu chuỗi ra ngoài khối chuỗi.
[[nodiscard]] std::expected<ExpTable, std::string_view> read_exp_table(std::string_view bytes);

// Số cần ở một cấp; cấp ngoài bảng thì nullopt (giữ trần cũ, không bịa số).
[[nodiscard]] std::optional<std::int64_t> exp_need(std::span<const std::int64_t> table, std::int32_t level) noexcept;

} // namespace game::hero
