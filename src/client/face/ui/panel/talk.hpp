/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/face/ui/panel/talk.hpp
 *  PHÂN HỆ   : UI / Panel / Talk
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hội thoại NPC, sổ nhiệm vụ, chỉ số bản thân và chiêu thức ở dạng không
 *    biết giao thức: tin máy chủ gửi xuống (Hear), việc người chơi nhờ (Say).
 *  - Bridge dịch hai chiều giữa đây và protocol/messages.hpp để HUD và nơi vẽ
 *    không include protocol (Android và iOS dựng được cả hai).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

// Chữ trong Dialog và Notice máy chủ đã dựng sẵn (UTF-8, thẻ màu #R #W... của game giữ nguyên); client không ghép câu.
// Mã phiên tăng ngặt: cùng mã là cập nhật nội dung của hộp đang mở, mã mới là hộp mới. Cùng cách hiểu với protocol
// phiên bản 6 (docs/PROTOCOL-TIN.md nhóm 06, 07 và 08).

#pragma once

#include <array>
#include <cstddef>
#include <cstdint>
#include <string>
#include <variant>
#include <vector>

namespace game::ui::panel::talk {

// Số từ 32 bit của mảng "đã xong": nhiệm vụ id 0..4095 (cùng quest::kDoneWords).
inline constexpr std::size_t kDoneWords = 128;

enum class Mode : std::uint8_t { kList = 1, kBox = 2, kMissionInfo = 3, kContinue = 4, kDemand = 5, kTips = 6 };

// Dấu nhiệm vụ trên NPC: nhận được, đang làm, đủ điều kiện nộp.
enum class Stage : std::uint8_t { kAvailable = 1, kInProgress = 2, kReady = 3 };

enum class BonusKind : std::uint8_t { kMoney = 1, kItem = 2, kRadio = 3, kRandom = 4, kDemand = 5 };

enum class Reason : std::uint8_t {
    kDone = 1,
    kFar = 2,
    kSceneChanged = 3,
    kNpcGone = 4,
    kExpired = 5,
    kReplaced = 6,
    kDead = 7,
    kClient = 8,
};

// Một lựa chọn: index là số gửi lại trong Choose, không phải id script.
struct Choice {
    std::uint16_t index = 0;
    // Biểu tượng của mục; 0 là không có.
    std::int32_t icon = 0;
    std::string text;
};

struct Mark {
    std::uint16_t quest = 0;
    Stage stage = Stage::kAvailable;
};

// Một dòng thưởng hay yêu cầu của bảng nhiệm vụ. kMoney: a là số tiền. Các loại khác: a là mẫu vật phẩm, b là số lượng.
struct Bonus {
    BonusKind kind = BonusKind::kMoney;
    std::int32_t a = 0;
    std::int32_t b = 0;
    std::int32_t c = 0;
};

// Máy chủ mở hay thay hộp thoại.
struct Dialog {
    std::uint64_t session = 0;
    // Id thực thể của NPC; 0 khi hộp không gắn NPC.
    std::uint32_t npc = 0;
    Mode mode = Mode::kList;
    std::vector<std::string> lines;
    std::vector<Choice> choices;
    std::vector<Mark> marks;
    // Nhiệm vụ của bảng (MissionInfo, Continue, Demand, Tips); -1 khi không có.
    std::int32_t panel_quest = -1;
    std::vector<Bonus> bonuses;
};

// Máy chủ đóng phiên hội thoại.
struct Closed {
    std::uint64_t session = 0;
    Reason reason = Reason::kDone;
};

// Một ô sổ nhiệm vụ đang giữ. params[0] là cờ đủ điều kiện nộp, params[1 + i] là tiến độ mục tiêu i.
struct Slot {
    std::uint16_t quest = 0;
    std::int32_t script = -1;
    std::uint8_t flags = 0;
    std::vector<std::uint32_t> params;
};

// Toàn bộ sổ nhiệm vụ (thay hẳn bản cũ).
struct Book {
    std::vector<Slot> slots;
    // Bit (id % 32) của từ (id / 32) bật là nhiệm vụ id đã xong.
    std::array<std::uint32_t, kDoneWords> done{};
};

enum class NoticeKind : std::uint8_t {
    kAdded = 1,
    kUpdated = 2,
    kReady = 3,
    kRemoved = 4,
    kDone = 5,
    kFailed = 6,
    kText = 7,
    kAnnounce = 8,
    kRewardExp = 9,
    kRewardMoney = 10,
    kRewardItem = 11,
    kRelation = 12,
};

// Thông báo của hệ nhiệm vụ. value và ref theo kind: RewardExp value là kinh nghiệm; RewardMoney value là số tiền,
// ref 1 là tiền khoá; RewardItem value là số lượng, ref là mẫu vật phẩm; Relation value là giá trị mới, ref là chỉ số.
struct Notice {
    NoticeKind kind = NoticeKind::kText;
    // Id nhiệm vụ; -1 khi không gắn nhiệm vụ.
    std::int32_t quest = -1;
    std::string text;
    std::int64_t value = 0;
    std::int32_t ref = 0;
};

// Cấp, kinh nghiệm trong cấp và tiền của chính nhân vật.
struct Stats {
    std::uint16_t level = 0;
    std::uint64_t exp = 0;
    std::uint64_t money = 0;
    std::uint64_t bound_money = 0;
};

// Sinh lực, nội lực và nộ khí thật của chính nhân vật (người khác chỉ thấy phần trăm).
struct Vitals {
    std::int32_t hp = 0;
    std::int32_t hp_max = 0;
    std::int32_t mp = 0;
    std::int32_t mp_max = 0;
    std::int32_t rage = 0;
    std::int32_t rage_max = 0;
};

// Một kỹ năng đã học. cooldown_ms là hồi chiêu còn lại lúc máy chủ gửi; 0 là dùng được.
struct Learned {
    std::uint16_t skill = 0;
    std::uint8_t level = 0;
    std::uint32_t cooldown_ms = 0;
};

// Toàn bộ kỹ năng đã học (thay hẳn bản cũ). Đánh thường (id 0) mọi nhân vật có sẵn nên máy chủ không liệt kê.
struct Skills {
    std::vector<Learned> learned;
};

// Hồi chiêu mới của một kỹ năng sau khi ra chiêu thành công.
struct Cooldown {
    std::uint16_t skill = 0;
    std::uint32_t ms = 0;
};

// Nhân vật vừa chết: kinh nghiệm và tiền bị mất.
struct Slain {
    std::uint64_t exp_lost = 0;
    std::uint64_t money_lost = 0;
};

// Vì sao máy chủ từ chối một việc của hộp thoại, sổ nhiệm vụ hay chiêu thức.
enum class Refusal : std::uint8_t {
    kNoSession,
    kStaleSession,
    kBadOption,
    kTooFar,
    kNoSuchEntity,
    kQuestUnavailable,
    kQuestLogFull,
    kQuestState,
    kBagFull,
    kNotEnoughMoney,
    kNotEnoughItems,
    kBadChoice,
    kCannotAbandon,
    kRateLimited,
    kOther,
};

struct Refused {
    Refusal why = Refusal::kOther;
};

// Vì sao máy chủ từ chối một chiêu, hồi sinh hay nhặt đồ.
enum class Decline : std::uint8_t {
    kNotLearned,
    kCooldown,
    kNotEnoughMana,
    kNotEnoughRage,
    // Mục tiêu không đánh được hay không hợp chiêu.
    kBadTarget,
    kOutOfRange,
    kCannotAttack,
    // Mục tiêu hay vật rơi không còn.
    kGone,
    // Mình đã chết nên không ra chiêu được.
    kDead,
    // Hồi sinh khi chưa chết.
    kNotDead,
    // Vật rơi của người khác.
    kNotYours,
    // Đang trong chiêu khác.
    kBusy,
    kOther,
};

struct Declined {
    Decline why = Decline::kOther;
};

using Hear = std::variant<Dialog, Closed, Book, Notice, Stats, Refused, Vitals, Skills, Cooldown, Slain, Declined>;

// Việc người chơi nhờ gửi lên máy chủ.
struct Talk {
    std::uint32_t npc = 0;
};

struct Choose {
    std::uint64_t session = 0;
    std::uint16_t index = 0;
};

struct Accept {
    std::uint64_t session = 0;
    std::uint16_t quest = 0;
};

struct TurnIn {
    std::uint64_t session = 0;
    std::uint16_t quest = 0;
    // Mẫu vật phẩm đã chọn trong nhóm thưởng chọn một; -1 khi nhiệm vụ không có nhóm đó.
    std::int32_t reward = -1;
};

struct Abandon {
    std::uint16_t quest = 0;
};

struct Close {
    std::uint64_t session = 0;
};

// Ra chiêu (đánh thường là kỹ năng 0). Chỉ là ý định: máy chủ kiểm rồi mới tính. seq do client gán và máy chủ chép lại vào
// tin xác nhận của chính người ra chiêu; 0 là không theo dõi. Điểm nhắm theo mét của game, chỉ dùng cho chiêu nhắm đất.
struct Cast {
    std::uint16_t seq = 0;
    std::uint16_t skill = 0;
    // Id thực thể mục tiêu; 0 là không có.
    std::uint32_t target = 0;
    float x = 0.0F;
    float z = 0.0F;
};

enum class Place : std::uint8_t { kTown = 1, kHere = 2 };

// Xin hồi sinh khi đã chết, ở thành hay tại chỗ.
struct Revive {
    Place place = Place::kTown;
};

// Nhặt một vật rơi (id thực thể của nó).
struct PickUp {
    std::uint32_t drop = 0;
};

using Say = std::variant<Talk, Choose, Accept, TurnIn, Abandon, Close, Cast, Revive, PickUp>;

} // namespace game::ui::panel::talk
