/*==============================================================================
 *  THIENLONG  |  SHARED
 *------------------------------------------------------------------------------
 *  TỆP       : src/shared/protocol/messages.hpp
 *  PHÂN HỆ   : Shared / Protocol / Messages
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Tệp sinh bởi gen_protocol.py từ các bảng .tsv trong catalog/; không sửa
 *    tay.
 *  - Sửa bảng rồi chạy: python -B TOOLS/server/gen_protocol.py
 *  - Danh mục tin của protocol (DE-BAI P2 đợt 2 §3): enum, hằng trần, struct
 *    của từng tin, encode và bốn bộ giải mã theo cổng (game, auth) và chiều
 *    (client gửi, server gửi).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "protocol/wire.hpp"

#include <array>
#include <chrono>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <string>
#include <variant>
#include <vector>

namespace game::protocol {

// Bản của danh mục; tin có since lớn hơn bản bên kia đang chạy thì bên kia chưa hiểu.
inline constexpr std::uint16_t kVersion = 9;

enum class AvatarFrame : std::uint8_t {
    kRound = 1,
    kSquare = 2,
};

enum class BonusKind : std::uint8_t {
    kMoney = 1,
    kItem = 2,
    kRadio = 3,
    kRandom = 4,
    kDemand = 5,
};

enum class CombatKind : std::uint8_t {
    kDamage = 1,
    kHeal = 2,
    kMiss = 3,
    kImmune = 4,
};

enum class DialogCloseReason : std::uint8_t {
    kDone = 1,
    kFar = 2,
    kSceneChanged = 3,
    kNpcGone = 4,
    kExpired = 5,
    kReplaced = 6,
    kDead = 7,
    kClient = 8,
};

enum class DialogMode : std::uint8_t {
    kList = 1,
    kBox = 2,
    kMissionInfo = 3,
    kContinue = 4,
    kDemand = 5,
    kTips = 6,
};

enum class DisconnectReason : std::uint8_t {
    kLoggedOut = 1,
    kLoginElsewhere = 2,
    kIdle = 3,
    kKicked = 4,
    kShutdown = 5,
    kProtocolViolation = 6,
    kVersionMismatch = 7,
    kServerFull = 8,
    kContentMismatch = 9,
};

enum class EntityKind : std::uint8_t {
    kPlayer = 1,
    kMonster = 2,
    kNpc = 3,
    kPet = 4,
    kDrop = 5,
    kObject = 6,
};

enum class EntityState : std::uint8_t {
    kIdle = 1,
    kWalk = 2,
    kDead = 3,
};

// NOLINTNEXTLINE(performance-enum-size): cỡ trên dây theo bảng, giữ byte của Dev (HP-07)
enum class ErrorCode : std::uint16_t {
    kMalformed = 1,
    kVersionMismatch = 2,
    kNotAuthenticated = 3,
    kBadCredentials = 4,
    kSessionExpired = 5,
    kOutOfOrder = 6,
    kNameTaken = 7,
    kNameInvalid = 8,
    kCharacterLimit = 9,
    kNoSuchCharacter = 10,
    kMoveBlocked = 11,
    kRateLimited = 12,
    kServerFull = 13,
    kMaintenance = 14,
    kPasswordInvalid = 15,
    kBusy = 16,
    kNoSession = 17,
    kStaleSession = 18,
    kBadOption = 19,
    kTooFar = 20,
    kNoSuchEntity = 21,
    kQuestUnavailable = 22,
    kQuestLogFull = 23,
    kQuestState = 24,
    kBagFull = 25,
    kNotEnoughMoney = 26,
    kNotEnoughItems = 27,
    kDuplicate = 28,
    kCannotAbandon = 29,
    kBadChoice = 30,
    kOutOfRange = 31,
    kCannotAttack = 32,
    kNotLearned = 33,
    kCooldown = 34,
    kNotEnoughMana = 35,
    kNotEnoughRage = 36,
    kBadTarget = 37,
    kDead = 38,
    kNotDead = 39,
    kNotYours = 40,
    kNoCharacterToDelete = 41,
    kCharacterOnline = 42,
    kInternal = 43,
};

enum class Gender : std::uint8_t {
    kFemale = 1,
    kMale = 2,
};

enum class MarkStage : std::uint8_t {
    kAvailable = 1,
    kInProgress = 2,
    kReady = 3,
};

enum class Platform : std::uint8_t {
    kWindows = 1,
    kAndroid = 2,
    kIos = 3,
};

enum class QuestNoticeKind : std::uint8_t {
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

enum class RespawnPlace : std::uint8_t {
    kTown = 1,
    kHere = 2,
};

// Giá trị có trong bảng enum; giải mã gặp giá trị lạ là kBadEnum, mã hoá cũng vậy.
[[nodiscard]] bool is_valid(AvatarFrame value) noexcept;
[[nodiscard]] bool is_valid(BonusKind value) noexcept;
[[nodiscard]] bool is_valid(CombatKind value) noexcept;
[[nodiscard]] bool is_valid(DialogCloseReason value) noexcept;
[[nodiscard]] bool is_valid(DialogMode value) noexcept;
[[nodiscard]] bool is_valid(DisconnectReason value) noexcept;
[[nodiscard]] bool is_valid(EntityKind value) noexcept;
[[nodiscard]] bool is_valid(EntityState value) noexcept;
[[nodiscard]] bool is_valid(ErrorCode value) noexcept;
[[nodiscard]] bool is_valid(Gender value) noexcept;
[[nodiscard]] bool is_valid(MarkStage value) noexcept;
[[nodiscard]] bool is_valid(Platform value) noexcept;
[[nodiscard]] bool is_valid(QuestNoticeKind value) noexcept;
[[nodiscard]] bool is_valid(RespawnPlace value) noexcept;

// Trần của từng trường: số byte của text và bytes, số phần tử của list.
inline constexpr std::size_t kCharacterSummaryNameBytes = 48;
inline constexpr std::size_t kDialogChoiceTextBytes = 256;
inline constexpr std::size_t kDialogLineTextBytes = 1024;
inline constexpr std::size_t kQuestSlotParamsCount = 8;
inline constexpr std::size_t kUiStringTextBytes = 255;
inline constexpr std::size_t kLoginAccountBytes = 64;
inline constexpr std::size_t kLoginTicketBytes = 512;
inline constexpr std::size_t kResumeTokenBytes = 16;
inline constexpr std::size_t kCreateCharacterNameBytes = 48;
inline constexpr std::size_t kCreateAccountAccountBytes = 64;
inline constexpr std::size_t kCreateAccountPasswordBytes = 128;
inline constexpr std::size_t kSignInAccountBytes = 64;
inline constexpr std::size_t kSignInPasswordBytes = 128;
inline constexpr std::size_t kExecuteScriptFunctionBytes = 63;
inline constexpr std::size_t kExecuteScriptParamsCount = 14;
inline constexpr std::size_t kSessionStartTokenBytes = 16;
inline constexpr std::size_t kContentKeyKeyBytes = 32;
inline constexpr std::size_t kContentStampStampBytes = 32;
inline constexpr std::size_t kCharacterListCharactersCount = 8;
inline constexpr std::size_t kEntityAppearNameBytes = 48;
inline constexpr std::size_t kEntityPosBatchPlacesCount = 52;
inline constexpr std::size_t kTicketTokenBytes = 204;
inline constexpr std::size_t kDialogOpenLinesCount = 16;
inline constexpr std::size_t kDialogOpenChoicesCount = 48;
inline constexpr std::size_t kDialogOpenMarksCount = 16;
inline constexpr std::size_t kDialogOpenBonusesCount = 24;
inline constexpr std::size_t kQuestBookSlotsCount = 20;
inline constexpr std::size_t kQuestBookDoneBytes = 512;
inline constexpr std::size_t kQuestNoticeTextBytes = 512;
inline constexpr std::size_t kUiCommandIntsCount = 16;
inline constexpr std::size_t kUiCommandStringsCount = 16;
inline constexpr std::size_t kSelfBagSlotsCount = 256;
inline constexpr std::size_t kSelfSkillsSkillsCount = 128;

// Record: Một ô của túi đồ.
struct BagSlot {
    // Chỉ số ô trong túi.
    std::uint16_t slot = 0;
    // Mẫu vật phẩm.
    std::uint32_t item = 0;
    // Số lượng chồng.
    std::uint16_t count = 0;
    // Đã khoá (ràng buộc).
    bool bound = false;
    friend bool operator==(const BagSlot&, const BagSlot&) = default;
};

// Record: Tóm tắt một nhân vật trong danh sách chọn nhân vật.
struct CharacterSummary {
    // CharacterId của Dev.
    std::uint64_t id = 0;
    // Tên nhân vật, UTF-8, tối đa 48 byte (kNameBytes của Dev).
    std::string name;
    std::uint16_t level = 0;
    Gender gender = Gender::kFemale;
    // Id mặt trong faces.tsv mà server đã lưu (gốc: face_model ở 0x3c); server thay kDefaultLook
    // bằng id thật lúc tạo nhân vật, nên ở đây không có nghĩa mặc định. Dây giữ id chưa cộng 10000,
    // client cộng khi dựng người mẫu.
    std::uint16_t face = 0;
    // Id tóc trong hairs.tsv mà server đã lưu (0 là id tóc hợp lệ; gốc: hair_model ở 0x38);
    // kDefaultLook chỉ có nghĩa trong CreateCharacter. Dây giữ id chưa cộng 10000, client cộng khi
    // dựng người mẫu.
    std::uint16_t hair = 0;
    // Môn phái; 0 là chưa vào môn phái, giữ giá trị canh của Dev thay cho optional.
    std::uint8_t school = 0;
    // SceneId của Dev: cảnh nhân vật đang đứng.
    std::uint16_t scene = 0;
    // Id ảnh chân dung (cột id của portraits.tsv) mà người chơi chọn lúc tạo; không suy từ face.
    // Gốc ghi ở 0x48 của bản ghi 0x1a4 (GetRoleInfo tra FaceImage).
    std::uint16_t portrait = 0;
    // Id bộ đồ tân thủ (cột id của newbie_outfits.tsv) đã chọn lúc tạo; server chỉ lưu và trả lại,
    // client đổi ra áo, giày, bao tay cho người mẫu màn chọn tới khi có trang bị thật (G5).
    std::uint16_t equip_set = 0;
    friend bool operator==(const CharacterSummary&, const CharacterSummary&) = default;
};

// Record: Một dòng phần thưởng hay yêu cầu của bảng nhiệm vụ.
struct DialogBonus {
    // Money: a là số tiền. Item, Radio, Random, Demand: a là mẫu vật phẩm, b là số lượng.
    BonusKind kind = BonusKind::kMoney;
    std::int32_t a = 0;
    std::int32_t b = 0;
    std::int32_t c = 0;
    friend bool operator==(const DialogBonus&, const DialogBonus&) = default;
};

// Record: Một lựa chọn của hộp thoại.
struct DialogChoice {
    // Số client gửi lại trong DialogChoose; không phải id script.
    std::uint16_t index = 0;
    // Biểu tượng của mục; 0 là không có.
    std::int32_t icon = 0;
    // Chữ của lựa chọn.
    std::string text;
    friend bool operator==(const DialogChoice&, const DialogChoice&) = default;
};

// Record: Một dòng lời NPC trong hộp thoại, đã dựng thành chữ.
struct DialogLine {
    // Chữ đã dựng (tham số tên, cấp... đã thay), UTF-8; có thẻ màu #R #W... của game.
    std::string text;
    friend bool operator==(const DialogLine&, const DialogLine&) = default;
};

// Record: Dấu nhiệm vụ của một nhiệm vụ gắn với NPC đang nói chuyện.
struct DialogMark {
    // Id nhiệm vụ (0..4095).
    std::uint16_t quest = 0;
    MarkStage stage = MarkStage::kAvailable;
    friend bool operator==(const DialogMark&, const DialogMark&) = default;
};

// Record: Một vị trí tuyệt đối trong EntityPosBatch. Cùng bố cục 19 byte với thân EntityPos.
struct PosEntry {
    // Id thực thể.
    std::uint32_t id = 0;
    // Toạ độ X, centimet.
    float x_cm = 0.0F;
    // Toạ độ Z, centimet.
    float z_cm = 0.0F;
    // Hướng nhìn: 0..65535 ứng với 0..2π; 0 là hướng +X, tăng dần quay về phía +Z.
    std::uint16_t direction = 0;
    // Tick của cảnh lúc ghi nhận. Nhịp zone mặc định 20, cũng có thể là 30 hoặc 40.
    std::uint32_t tick = 0;
    // Walk khi đang di chuyển; Idle khi dừng; Dead khi chết.
    EntityState state = EntityState::kIdle;
    friend bool operator==(const PosEntry&, const PosEntry&) = default;
};

// Record: Một ô của sổ nhiệm vụ.
struct QuestSlot {
    // Id nhiệm vụ của client 2026.
    std::uint16_t quest = 0;
    // Id script của nhiệm vụ; -1 nếu không có.
    std::int32_t script = 0;
    // Bit 1 giết, 2 vùng, 4 vật phẩm: loại sự kiện nhiệm vụ này theo dõi.
    std::uint8_t flags = 0;
    // Tám tham số của ô; nhiệm vụ bảng: tham số 0 là cờ đủ điều kiện nộp, 1 + i là tiến độ mục tiêu
    // i.
    std::vector<std::uint32_t> params;
    friend bool operator==(const QuestSlot&, const QuestSlot&) = default;
};

// Record: Một kỹ năng đã học của chính nhân vật, kèm hồi chiêu còn lại.
struct SkillEntry {
    // Id kỹ năng (cột id của skills.tsv).
    std::uint16_t skill = 0;
    // Cấp kỹ năng.
    std::uint8_t level = 0;
    // Hồi chiêu còn lại, mili giây; 0 là dùng được.
    std::uint32_t cooldown_ms = 0;
    friend bool operator==(const SkillEntry&, const SkillEntry&) = default;
};

// Record: Một chuỗi tham số của UiCommand.
struct UiString {
    // Chuỗi UTF-8; tổng các chuỗi của một UiCommand không quá 511 byte (kho XParam của client gốc).
    std::string text;
    friend bool operator==(const UiString&, const UiString&) = default;
};

// 0x0101, client gửi, cổng both, từ bản 1: Tin đầu tiên của mọi kết nối, báo phiên bản giao thức,
// nền tảng và bản dựng client.
struct Hello {
    static constexpr std::uint16_t kKind = 0x0101;
    // Phiên bản giao thức của client.
    std::uint16_t version = 0;
    Platform platform = Platform::kWindows;
    // Số bản dựng client.
    std::uint32_t build = 0;
    friend bool operator==(const Hello&, const Hello&) = default;
};

// 0x0102, client gửi, cổng game, từ bản 1: Đăng nhập cổng game bằng vé do cổng xác thực cấp, không
// bao giờ mang mật khẩu.
struct Login {
    static constexpr std::uint16_t kKind = 0x0102;
    // Tên tài khoản (kAccountBytes của Dev).
    std::string account;
    // Vé do cổng xác thực cấp.
    std::string ticket;
    friend bool operator==(const Login&, const Login&) = default;
};

// 0x0103, client gửi, cổng game, từ bản 1: Nối lại phiên cũ bằng token phiên sau khi rớt mạng.
struct Resume {
    static constexpr std::uint16_t kKind = 0x0103;
    // Token phiên nhận trong SessionStart.
    std::array<std::byte, kResumeTokenBytes> token{};
    friend bool operator==(const Resume&, const Resume&) = default;
};

// 0x0104, client gửi, cổng game, từ bản 1: Nhịp tim của client, mang giờ client để đo độ trễ khứ
// hồi.
struct Ping {
    static constexpr std::uint16_t kKind = 0x0104;
    // Giờ client lúc gửi, server trả lại nguyên trong Pong. Khác Dev (duration<uint32_t, milli>):
    // ta dùng std::chrono::milliseconds có dấu để trừ hai mốc không bị quấn; trên dây vẫn u32 như
    // Dev, ghi số âm hay trên 2^32 - 1 ra kOutOfRange.
    std::chrono::milliseconds client_time = std::chrono::milliseconds::zero();
    friend bool operator==(const Ping&, const Ping&) = default;
};

// 0x0105, client gửi, cổng game, từ bản 1: Client chủ động rời phiên; thân rỗng.
struct Logout {
    static constexpr std::uint16_t kKind = 0x0105;
    friend bool operator==(const Logout&, const Logout&) = default;
};

// 0x0201, client gửi, cổng game, từ bản 1: Tạo nhân vật mới với tên, giới tính, khuôn mặt và kiểu
// tóc.
struct CreateCharacter {
    static constexpr std::uint16_t kKind = 0x0201;
    // Tên nhân vật muốn tạo.
    std::string name;
    Gender gender = Gender::kFemale;
    // 0 là mặt mặc định (kDefaultLook của Dev).
    std::uint16_t face = 0;
    // 0 là tóc mặc định (kDefaultLook của Dev).
    std::uint16_t hair = 0;
    // Id ảnh chân dung phải thuộc đúng giới (cột id của portraits.tsv, choice 1 hay 3); khác face
    // vì màn tạo 2026 chọn riêng.
    std::uint16_t portrait = 0;
    // Id bộ đồ tân thủ (cột id của newbie_outfits.tsv); mọi giới dùng chung ba bộ.
    std::uint16_t equip_set = 0;
    friend bool operator==(const CreateCharacter&, const CreateCharacter&) = default;
};

// 0x0202, client gửi, cổng game, từ bản 1: Xoá một nhân vật của tài khoản.
struct DeleteCharacter {
    static constexpr std::uint16_t kKind = 0x0202;
    // CharacterId của Dev.
    std::uint64_t character = 0;
    friend bool operator==(const DeleteCharacter&, const DeleteCharacter&) = default;
};

// 0x0203, client gửi, cổng game, từ bản 1: Vào game bằng nhân vật đã chọn.
struct EnterGame {
    static constexpr std::uint16_t kKind = 0x0203;
    // CharacterId của Dev.
    std::uint64_t character = 0;
    friend bool operator==(const EnterGame&, const EnterGame&) = default;
};

// 0x0301, client gửi, cổng game, từ bản 1: Client xin một bước trên mặt phẳng ngang; server đo bằng
// guard::Pace theo tick của server, không tin vị trí client.
struct Move {
    static constexpr std::uint16_t kKind = 0x0301;
    // Toạ độ X muốn tới, centimet. NaN/vô cực bị Pace từ chối.
    float x_cm = 0.0F;
    // Toạ độ Z muốn tới, centimet.
    float z_cm = 0.0F;
    // Tick client (30/giây) đếm từ tick trong Position gần nhất; chỉ làm trần dưới của thời gian,
    // server cắt theo đồng hồ của mình.
    std::uint32_t tick = 0;
    friend bool operator==(const Move&, const Move&) = default;
};

// 0x0501, client gửi, cổng auth, từ bản 1: Tạo tài khoản mới ở cổng xác thực.
struct CreateAccount {
    static constexpr std::uint16_t kKind = 0x0501;
    // Tên tài khoản (kAccountBytes của Dev).
    std::string account;
    // Mật khẩu, chỉ đi qua cổng xác thực.
    std::string password;
    friend bool operator==(const CreateAccount&, const CreateAccount&) = default;
};

// 0x0502, client gửi, cổng auth, từ bản 1: Đăng nhập bằng mật khẩu ở cổng xác thực để nhận vé.
struct SignIn {
    static constexpr std::uint16_t kKind = 0x0502;
    // Tên tài khoản (kAccountBytes của Dev).
    std::string account;
    // Mật khẩu, chỉ đi qua cổng xác thực.
    std::string password;
    friend bool operator==(const SignIn&, const SignIn&) = default;
};

// 0x0601, client gửi, cổng game, từ bản 5: Bấm vào NPC để nói chuyện: mở phiên hội thoại. Server
// kiểm khoảng cách, cảnh và NPC còn đó.
struct Talk {
    static constexpr std::uint16_t kKind = 0x0601;
    // EntityAppear.id của NPC.
    std::uint32_t npc = 0;
    friend bool operator==(const Talk&, const Talk&) = default;
};

// 0x0602, client gửi, cổng game, từ bản 5: Chọn một lựa chọn của hộp thoại đang mở (theo index
// server đã gửi, không phải id script).
struct DialogChoose {
    static constexpr std::uint16_t kKind = 0x0602;
    // Mã phiên trong DialogOpen.
    std::uint64_t session = 0;
    // DialogChoice.index.
    std::uint16_t index = 0;
    friend bool operator==(const DialogChoose&, const DialogChoose&) = default;
};

// 0x0603, client gửi, cổng game, từ bản 5: Nhận nhiệm vụ mà hộp thoại đang mời.
struct QuestAccept {
    static constexpr std::uint16_t kKind = 0x0603;
    std::uint64_t session = 0;
    std::uint16_t quest = 0;
    friend bool operator==(const QuestAccept&, const QuestAccept&) = default;
};

// 0x0604, client gửi, cổng game, từ bản 5: Nộp nhiệm vụ đang làm, kèm phần thưởng chọn một nếu có.
struct QuestTurnIn {
    static constexpr std::uint16_t kKind = 0x0604;
    std::uint64_t session = 0;
    std::uint16_t quest = 0;
    // Mẫu vật phẩm đã chọn trong nhóm thưởng chọn một; -1 nếu nhiệm vụ không có nhóm đó.
    std::int32_t reward = 0;
    friend bool operator==(const QuestTurnIn&, const QuestTurnIn&) = default;
};

// 0x0605, client gửi, cổng game, từ bản 5: Bỏ nhiệm vụ đang làm; bấm từ sổ nhiệm vụ nên không cần
// phiên hội thoại.
struct QuestAbandon {
    static constexpr std::uint16_t kKind = 0x0605;
    std::uint16_t quest = 0;
    friend bool operator==(const QuestAbandon&, const QuestAbandon&) = default;
};

// 0x0606, client gửi, cổng game, từ bản 5: Client đóng hộp thoại; server đóng phiên.
struct DialogClose {
    static constexpr std::uint16_t kKind = 0x0606;
    std::uint64_t session = 0;
    friend bool operator==(const DialogClose&, const DialogClose&) = default;
};

// 0x0607, client gửi, cổng game, từ bản 8: Client gọi một hàm của script phía máy chủ theo
// CGExecuteScript (2219) của Game.exe: id script, tên hàm và tối đa 14 số. Server chỉ chạy hàm có
// trong bảng xử lý, hàm lạ bị từ chối.
struct ExecuteScript {
    static constexpr std::uint16_t kKind = 0x0607;
    // Id script phía máy chủ (Script.dat); -1 là rỗng.
    std::int32_t script = 0;
    // Tên hàm trong script, ASCII, 1 đến 63 byte (bản ghi gốc có 64 byte kèm NUL).
    std::string function;
    // Tham số số nguyên của lời gọi; tối đa 14 như bản ghi XSCRIPT gốc.
    std::vector<std::int32_t> params;
    friend bool operator==(const ExecuteScript&, const ExecuteScript&) = default;
};

// 0x0801, client gửi, cổng game, từ bản 6: Ra chiêu (đánh thường cũng là một kỹ năng). Chỉ là ý
// định: server kiểm đã học, hồi chiêu, tiêu hao, tầm, mục tiêu rồi mới tính; lỗi trả Reject.
struct CastSkill {
    static constexpr std::uint16_t kKind = 0x0801;
    // Số thứ tự client gán; server chép lại vào SkillCast gửi cho chính người ra chiêu (seq khác
    // 0). Reject không mang seq.
    std::uint16_t seq = 0;
    // Id kỹ năng.
    std::uint16_t skill = 0;
    // EntityAppear.id của mục tiêu; 0 là không có.
    std::uint32_t target = 0;
    // Điểm nhắm đất, centimet; chỉ dùng cho chiêu nhắm đất.
    float x_cm = 0.0F;
    // Điểm nhắm đất, centimet.
    float z_cm = 0.0F;
    friend bool operator==(const CastSkill&, const CastSkill&) = default;
};

// 0x0802, client gửi, cổng game, từ bản 6: Xin hồi sinh khi đã chết, ở thành hay tại chỗ; server áp
// phạt chết và đặt lại máu.
struct Respawn {
    static constexpr std::uint16_t kKind = 0x0802;
    RespawnPlace place = RespawnPlace::kTown;
    friend bool operator==(const Respawn&, const Respawn&) = default;
};

// 0x0803, client gửi, cổng game, từ bản 6: Nhặt một vật rơi trong tầm 3 m; server kiểm luật chủ
// nhặt.
struct PickUp {
    static constexpr std::uint16_t kKind = 0x0803;
    // EntityAppear.id của vật rơi.
    std::uint32_t drop = 0;
    friend bool operator==(const PickUp&, const PickUp&) = default;
};

// 0x8101, server gửi, cổng both, từ bản 1: Server đáp Hello: phiên bản giao thức, giờ server và chu
// kỳ nhịp tim.
struct Welcome {
    static constexpr std::uint16_t kKind = 0x8101;
    // Phiên bản giao thức của server.
    std::uint16_t version = 0;
    // Giờ server theo mili giây. Khác Dev (duration<uint64_t, milli>): ta dùng
    // std::chrono::milliseconds nền int64 có dấu để trừ hai mốc không bị quấn; trên dây vẫn u64,
    // nhưng số trên 2^63 - 1 (khoảng 292 triệu năm, chỉ có ở dữ liệu hỏng) đọc ra kOutOfRange, ghi
    // số âm cũng ra kOutOfRange.
    std::chrono::milliseconds server_time = std::chrono::milliseconds::zero();
    // Chu kỳ client phải gửi Ping. Khác Dev (duration<uint16_t>): ta dùng std::chrono::seconds có
    // dấu cho cùng kiểu giờ với phần còn lại; trên dây vẫn u16 như Dev, ghi số âm hay trên 65535 ra
    // kOutOfRange.
    std::chrono::seconds heartbeat = std::chrono::seconds::zero();
    friend bool operator==(const Welcome&, const Welcome&) = default;
};

// 0x8102, server gửi, cổng game, từ bản 1: Server mở phiên và cấp token để nối lại sau này.
struct SessionStart {
    static constexpr std::uint16_t kKind = 0x8102;
    // Token phiên dùng cho Resume.
    std::array<std::byte, kSessionStartTokenBytes> token{};
    friend bool operator==(const SessionStart&, const SessionStart&) = default;
};

// 0x8103, server gửi, cổng game, từ bản 1: Khoá giải mã gói nội dung của phiên.
struct ContentKey {
    static constexpr std::uint16_t kKind = 0x8103;
    // Khoá giải mã gói nội dung.
    std::array<std::byte, kContentKeyKeyBytes> key{};
    friend bool operator==(const ContentKey&, const ContentKey&) = default;
};

// 0x8104, server gửi, cổng game, từ bản 1: Server đáp Ping, trả lại giờ client kèm giờ server.
struct Pong {
    static constexpr std::uint16_t kKind = 0x8104;
    // Giờ client lấy nguyên từ Ping. Khác Dev như Ping.client_time: std::chrono::milliseconds có
    // dấu thay cho duration<uint32_t, milli>, trên dây vẫn u32.
    std::chrono::milliseconds client_time = std::chrono::milliseconds::zero();
    // Giờ server lúc trả lời. Khác Dev như Welcome.server_time: nền int64 có dấu thay cho u64, số
    // trên 2^63 - 1 đọc ra kOutOfRange.
    std::chrono::milliseconds server_time = std::chrono::milliseconds::zero();
    friend bool operator==(const Pong&, const Pong&) = default;
};

// 0x8106, server gửi, cổng both, từ bản 1: Server từ chối một tin của client và nêu mã lỗi.
struct Reject {
    static constexpr std::uint16_t kKind = 0x8106;
    // Mã tin của client bị từ chối; để u16 thay vì enum để giữ nguyên byte của Dev và không chép mã
    // tin vào enums.tsv.
    std::uint16_t request = 0;
    ErrorCode code = ErrorCode::kMalformed;
    friend bool operator==(const Reject&, const Reject&) = default;
};

// 0x8107, server gửi, cổng both, từ bản 1: Server báo sắp đóng kết nối và nêu lý do.
struct Goodbye {
    static constexpr std::uint16_t kKind = 0x8107;
    DisconnectReason reason = DisconnectReason::kLoggedOut;
    friend bool operator==(const Goodbye&, const Goodbye&) = default;
};

// 0x8108, server gửi, cổng game, từ bản 1: Dấu băm của gói nội dung để client đối chiếu với bản
// đang có.
struct ContentStamp {
    static constexpr std::uint16_t kKind = 0x8108;
    // Dấu băm của gói nội dung.
    std::array<std::byte, kContentStampStampBytes> stamp{};
    friend bool operator==(const ContentStamp&, const ContentStamp&) = default;
};

// 0x8109, server gửi, cổng game, từ bản 2: Cấu hình giao diện do nhà phát hành đặt ở server
// (client.toml): gửi sau SessionStart, chỉ cho client khai phiên bản giao thức từ 2.
struct UiConfig {
    static constexpr std::uint16_t kKind = 0x8109;
    // Dạng khung chân dung của HUD (client.toml, [hud] avatar_frame).
    AvatarFrame avatar_frame = AvatarFrame::kRound;
    friend bool operator==(const UiConfig&, const UiConfig&) = default;
};

// 0x8201, server gửi, cổng game, từ bản 1: Danh sách nhân vật của tài khoản để chọn vào game.
struct CharacterList {
    static constexpr std::uint16_t kKind = 0x8201;
    // Tối đa 8 nhân vật mỗi tài khoản (kCharacterSlots của Dev).
    std::vector<CharacterSummary> characters;
    // Server quyết: còn dưới trần số nhân vật của tài khoản nên bảng tạo mở được; client đọc cờ này
    // thay cho tin hỏi riêng CLCheckAllowCreateChar của gốc.
    bool can_create = false;
    friend bool operator==(const CharacterList&, const CharacterList&) = default;
};

// 0x8301, server gửi, cổng game, từ bản 1: Vị trí server làm chủ: gửi khi vào game (mốc đầu), khi
// dịch chuyển hợp lệ, và khi bước của client bị từ chối (kéo về).
struct Position {
    static constexpr std::uint16_t kKind = 0x8301;
    // Toạ độ X server chấp nhận, centimet.
    float x_cm = 0.0F;
    // Toạ độ Z server chấp nhận, centimet.
    float z_cm = 0.0F;
    // Tick client mới làm gốc: client đặt bộ đếm tick về giá trị này rồi đếm tiếp.
    std::uint32_t tick = 0;
    friend bool operator==(const Position&, const Position&) = default;
};

// 0x8401, server gửi, cổng game, từ bản 4: Server báo nhân vật đã vào một cảnh: id cảnh, vị trí và
// hướng đầu tiên. Gửi lúc vào game và mỗi lần đổi cảnh.
struct SceneEnter {
    static constexpr std::uint16_t kKind = 0x8401;
    // Id cảnh (SceneAttr của client 2026).
    std::uint16_t scene = 0;
    // Toạ độ X đầu tiên, centimet.
    float x_cm = 0.0F;
    // Toạ độ Z đầu tiên, centimet.
    float z_cm = 0.0F;
    // Hướng nhìn: 0..65535 ứng với 0..2π; 0 là hướng +X, tăng dần quay về phía +Z.
    std::uint16_t direction = 0;
    // Id thực thể của chính nhân vật trong cảnh này (cùng không gian id với EntityAppear.id):
    // client dùng để chọn mục tiêu và nhận ra mình trong EntityPos/EntityVitals. Đổi mỗi lần vào
    // cảnh.
    std::uint32_t self_id = 0;
    friend bool operator==(const SceneEnter&, const SceneEnter&) = default;
};

// 0x8402, server gửi, cổng game, từ bản 4: Một thực thể (người, quái, NPC...) bước vào vùng nhìn
// của client.
struct EntityAppear {
    static constexpr std::uint16_t kKind = 0x8402;
    // Id thực thể trong cảnh; không dùng lại ngay sau khi thực thể biến mất (có số thế hệ).
    std::uint32_t id = 0;
    EntityKind kind = EntityKind::kPlayer;
    // Id mẫu: quái (monsters.tsv), NPC; 0 với người chơi.
    std::uint32_t template_id = 0;
    // Tên hiển thị của người chơi; rỗng với quái và NPC (client tra theo mẫu).
    std::string name;
    std::uint16_t level = 0;
    // Toạ độ X, centimet.
    float x_cm = 0.0F;
    // Toạ độ Z, centimet.
    float z_cm = 0.0F;
    // Hướng nhìn: 0..65535 ứng với 0..2π; 0 là hướng +X, tăng dần quay về phía +Z.
    std::uint16_t direction = 0;
    // Tốc độ chạy, centimet mỗi giây.
    std::uint16_t speed_cm = 0;
    // Sinh lực theo phần trăm 0..100.
    std::uint8_t hp_percent = 0;
    // 1 nữ, 2 nam; 0 với thực thể không phải người.
    std::uint8_t gender = 0;
    // Id mặt trong faces.tsv; chỉ có nghĩa với người chơi.
    std::uint16_t face = 0;
    // Id tóc trong hairs.tsv; chỉ có nghĩa với người chơi.
    std::uint16_t hair = 0;
    // Môn phái 0..15; chỉ có nghĩa với người chơi.
    std::uint8_t school = 0;
    // Trạng thái lúc hiện: Idle, Walk (đang đi, EntityPos tiếp theo sẽ tới) hay Dead (xác còn nằm
    // lại, hp_percent là 0).
    EntityState state = EntityState::kIdle;
    friend bool operator==(const EntityAppear&, const EntityAppear&) = default;
};

// 0x8403, server gửi, cổng game, từ bản 4: Một thực thể rời vùng nhìn của client hoặc biến mất khỏi
// cảnh.
struct EntityDisappear {
    static constexpr std::uint16_t kKind = 0x8403;
    // Id thực thể.
    std::uint32_t id = 0;
    friend bool operator==(const EntityDisappear&, const EntityDisappear&) = default;
};

// 0x8404, server gửi, cổng game, từ bản 4: Vị trí mới của một thực thể trong vùng nhìn; client nội
// suy giữa hai lần nhận.
struct EntityPos {
    static constexpr std::uint16_t kKind = 0x8404;
    // Id thực thể.
    std::uint32_t id = 0;
    // Toạ độ X, centimet.
    float x_cm = 0.0F;
    // Toạ độ Z, centimet.
    float z_cm = 0.0F;
    // Hướng nhìn: 0..65535 ứng với 0..2π; 0 là hướng +X, tăng dần quay về phía +Z.
    std::uint16_t direction = 0;
    // Tick của cảnh lúc ghi nhận. Nhịp zone mặc định 20 bước mỗi giây, cũng có thể là 30 hoặc 40;
    // khác bộ đếm tick 30/giây của Move/Position. Client nội suy giữa hai gói theo hiệu hai tick.
    std::uint32_t tick = 0;
    // Walk khi đang di chuyển; gói cuối của một chặng đi mang Idle cùng toạ độ đích. Dead khi chết.
    EntityState state = EntityState::kIdle;
    friend bool operator==(const EntityPos&, const EntityPos&) = default;
};

// 0x8405, server gửi, cổng game, từ bản 4: Sinh lực của một thực thể trong vùng nhìn, theo phần
// trăm.
struct EntityVitals {
    static constexpr std::uint16_t kKind = 0x8405;
    // Id thực thể.
    std::uint32_t id = 0;
    // Sinh lực theo phần trăm 0..100.
    std::uint8_t hp_percent = 0;
    friend bool operator==(const EntityVitals&, const EntityVitals&) = default;
};

// 0x8406, server gửi, cổng game, từ bản 5: Cờ của một thực thể trong vùng nhìn; gửi ngay sau
// EntityAppear khi cờ khác 0 và mỗi khi cờ đổi.
struct EntityFlags {
    static constexpr std::uint16_t kKind = 0x8406;
    // Id thực thể.
    std::uint32_t id = 0;
    // Bit 0: bấm vào được để nói chuyện (Talk).
    std::uint8_t flags = 0;
    friend bool operator==(const EntityFlags&, const EntityFlags&) = default;
};

// 0x8407, server gửi, cổng game, từ bản 7: Nhiều vị trí tuyệt đối của cùng một tick cho một client.
// Không gửi khi rỗng.
struct EntityPosBatch {
    static constexpr std::uint16_t kKind = 0x8407;
    // Tối đa 52 vị trí: khung sau khi niêm phong phải vừa hộp gửi 1024 byte của gate.
    std::vector<PosEntry> places;
    friend bool operator==(const EntityPosBatch&, const EntityPosBatch&) = default;
};

// 0x8501, server gửi, cổng auth, từ bản 1: Vé vào cổng game do cổng xác thực cấp sau khi đăng nhập
// đúng.
struct Ticket {
    static constexpr std::uint16_t kKind = 0x8501;
    // Vé vào cổng game (kConnectTokenBytes của Dev).
    std::array<std::byte, kTicketTokenBytes> token{};
    friend bool operator==(const Ticket&, const Ticket&) = default;
};

// 0x8601, server gửi, cổng game, từ bản 5: Server mở hay thay hộp thoại của phiên: lời NPC, lựa
// chọn, dấu nhiệm vụ, bảng nhiệm vụ và phần thưởng.
struct DialogOpen {
    static constexpr std::uint16_t kKind = 0x8601;
    // Mã phiên, tăng ngặt, không dùng lại; gửi lại trong mọi tin sau của hộp thoại này.
    std::uint64_t session = 0;
    // EntityAppear.id của NPC; 0 với hộp thoại không gắn NPC.
    std::uint32_t npc = 0;
    DialogMode mode = DialogMode::kList;
    std::vector<DialogLine> lines;
    std::vector<DialogChoice> choices;
    std::vector<DialogMark> marks;
    // Nhiệm vụ của bảng (MissionInfo, Continue, Demand, Tips); -1 nếu không có.
    std::int32_t panel_quest = 0;
    std::vector<DialogBonus> bonuses;
    friend bool operator==(const DialogOpen&, const DialogOpen&) = default;
};

// 0x8602, server gửi, cổng game, từ bản 5: Server đóng phiên hội thoại và nêu lý do.
struct DialogClosed {
    static constexpr std::uint16_t kKind = 0x8602;
    std::uint64_t session = 0;
    DialogCloseReason reason = DialogCloseReason::kDone;
    friend bool operator==(const DialogClosed&, const DialogClosed&) = default;
};

// 0x8603, server gửi, cổng game, từ bản 5: Toàn bộ sổ nhiệm vụ: ô đang giữ và tập nhiệm vụ đã xong.
// Gửi sau SceneEnter và mỗi khi sổ đổi.
struct QuestBook {
    static constexpr std::uint16_t kKind = 0x8603;
    std::vector<QuestSlot> slots;
    // 128 từ u32 little-endian: bit (id % 32) của từ (id / 32) bật là nhiệm vụ id đã xong (id
    // 0..4095).
    std::array<std::byte, kQuestBookDoneBytes> done{};
    friend bool operator==(const QuestBook&, const QuestBook&) = default;
};

// 0x8604, server gửi, cổng game, từ bản 5: Thông báo của hệ nhiệm vụ cho người chơi: nhận, tiến độ,
// đủ điều kiện nộp, thưởng, chữ.
struct QuestNotice {
    static constexpr std::uint16_t kKind = 0x8604;
    QuestNoticeKind kind = QuestNoticeKind::kAdded;
    // Id nhiệm vụ; -1 nếu không gắn nhiệm vụ.
    std::int32_t quest = 0;
    // Chữ đã dựng; rỗng với kind không có chữ.
    std::string text;
    // RewardExp: kinh nghiệm. RewardMoney: số tiền. RewardItem: số lượng. Relation: giá trị mới.
    std::int64_t value = 0;
    // RewardMoney: 1 nếu tiền khoá. RewardItem: mẫu vật phẩm. Relation: chỉ số quan hệ.
    std::int32_t ref = 0;
    friend bool operator==(const QuestNotice&, const QuestNotice&) = default;
};

// 0x8605, server gửi, cổng game, từ bản 8: Server bảo client mở cửa sổ hay đẩy sự kiện UI_COMMAND
// theo GCUICommand (481) của Game.exe: chỉ số lệnh, chế độ, tối đa 16 số và 16 chuỗi.
struct UiCommand {
    static constexpr std::uint16_t kKind = 0x8605;
    // Chỉ số lệnh giao diện (arg0 của sự kiện UI_COMMAND; khoá của UICommandIndex.tsv).
    std::int32_t index = 0;
    // 0: lưu XParam rồi bắn sự kiện UI_COMMAND (0x13a); khác 0: gọi bộ xử lý lệnh theo chỉ số.
    std::int32_t mode = 0;
    // Số của XParam, tối đa 16.
    std::vector<std::int32_t> ints;
    // Chuỗi của XParam, tối đa 16.
    std::vector<UiString> strings;
    friend bool operator==(const UiCommand&, const UiCommand&) = default;
};

// 0x8701, server gửi, cổng game, từ bản 5: Cấp, kinh nghiệm và tiền của chính nhân vật. Gửi sau
// SceneEnter và mỗi khi đổi.
struct SelfStats {
    static constexpr std::uint16_t kKind = 0x8701;
    std::uint16_t level = 0;
    // Kinh nghiệm hiện có trong cấp.
    std::uint64_t exp = 0;
    // Tiền thường.
    std::uint64_t money = 0;
    // Tiền khoá.
    std::uint64_t bound_money = 0;
    friend bool operator==(const SelfStats&, const SelfStats&) = default;
};

// 0x8702, server gửi, cổng game, từ bản 6: Sinh lực, nội lực và nộ khí thật của chính nhân vật
// (người khác chỉ thấy phần trăm ở EntityVitals). Gộp, tối đa 5 lần mỗi giây.
struct SelfVitals {
    static constexpr std::uint16_t kKind = 0x8702;
    std::int32_t hp = 0;
    std::int32_t hp_max = 0;
    std::int32_t mp = 0;
    std::int32_t mp_max = 0;
    std::int32_t rage = 0;
    std::int32_t rage_max = 0;
    friend bool operator==(const SelfVitals&, const SelfVitals&) = default;
};

// 0x8703, server gửi, cổng game, từ bản 6: Ảnh chụp toàn bộ túi đồ của chính nhân vật. Gửi sau
// SceneEnter và mỗi khi túi đổi.
struct SelfBag {
    static constexpr std::uint16_t kKind = 0x8703;
    // Các ô có đồ; ô trống không gửi.
    std::vector<BagSlot> slots;
    friend bool operator==(const SelfBag&, const SelfBag&) = default;
};

// 0x8801, server gửi, cổng game, từ bản 6: Một thực thể bắt đầu ra chiêu: client chạy hành động và
// hiệu ứng, đạn tự nội suy từ nguồn tới đích. seq khác 0 chỉ khi là chiêu của chính client.
struct SkillCast {
    static constexpr std::uint16_t kKind = 0x8801;
    // 0 nếu không phải chiêu của chính client nhận tin.
    std::uint16_t seq = 0;
    // Id thực thể ra chiêu.
    std::uint32_t source = 0;
    std::uint16_t skill = 0;
    // Id mục tiêu; 0 là không có.
    std::uint32_t target = 0;
    // Điểm nhắm đất, centimet; bằng toạ độ mục tiêu khi nhắm vào thực thể.
    float x_cm = 0.0F;
    float z_cm = 0.0F;
    // Cấp kỹ năng của người ra chiêu.
    std::uint8_t level = 0;
    friend bool operator==(const SkillCast&, const SkillCast&) = default;
};

// 0x8802, server gửi, cổng game, từ bản 6: Chiêu gom khí hay dẫn khí kết thúc hoặc bị ngắt.
struct SkillCastEnd {
    static constexpr std::uint16_t kKind = 0x8802;
    std::uint32_t source = 0;
    std::uint16_t skill = 0;
    // Bị ngắt giữa chừng.
    bool interrupted = false;
    friend bool operator==(const SkillCastEnd&, const SkillCastEnd&) = default;
};

// 0x8803, server gửi, cổng game, từ bản 6: Kết quả của một chiêu lên một mục tiêu: sát thương, hồi,
// trượt hay miễn nhiễm. Chiêu nhiều mục tiêu gửi nhiều tin.
struct CombatEvent {
    static constexpr std::uint16_t kKind = 0x8803;
    // Id thực thể gây ra; 0 nếu không rõ (hiệu ứng treo).
    std::uint32_t source = 0;
    std::uint32_t target = 0;
    std::uint16_t skill = 0;
    CombatKind kind = CombatKind::kDamage;
    // Lượng sát thương hay hồi; 0 với Miss và Immune.
    std::int32_t value = 0;
    // Bit 0: hội tâm (chí mạng). Bit 1 chừa cho chí mạng phụ.
    std::uint8_t flags = 0;
    friend bool operator==(const CombatEvent&, const CombatEvent&) = default;
};

// 0x8804, server gửi, cổng game, từ bản 6: Một thực thể chết; xác còn lại một lúc rồi mới có
// EntityDisappear.
struct EntityDied {
    static constexpr std::uint16_t kKind = 0x8804;
    std::uint32_t id = 0;
    // Id kẻ hạ gục; 0 nếu không rõ.
    std::uint32_t killer = 0;
    friend bool operator==(const EntityDied&, const EntityDied&) = default;
};

// 0x8805, server gửi, cổng game, từ bản 6: Gửi riêng người chơi vừa chết: kinh nghiệm và tiền mất,
// để dựng bảng hồi sinh.
struct DeathNotice {
    static constexpr std::uint16_t kKind = 0x8805;
    std::uint64_t exp_lost = 0;
    std::uint64_t money_lost = 0;
    friend bool operator==(const DeathNotice&, const DeathNotice&) = default;
};

// 0x8806, server gửi, cổng game, từ bản 6: Các kỹ năng đã học của chính nhân vật kèm hồi chiêu còn
// lại. Gửi sau SceneEnter và mỗi khi đổi.
struct SelfSkills {
    static constexpr std::uint16_t kKind = 0x8806;
    std::vector<SkillEntry> skills;
    friend bool operator==(const SelfSkills&, const SelfSkills&) = default;
};

// 0x8807, server gửi, cổng game, từ bản 6: Hồi chiêu mới của một kỹ năng sau khi ra chiêu thành
// công, để client vẽ nhịp hồi.
struct SkillCooldown {
    static constexpr std::uint16_t kKind = 0x8807;
    std::uint16_t skill = 0;
    // Hồi chiêu mới, mili giây.
    std::uint32_t ms = 0;
    friend bool operator==(const SkillCooldown&, const SkillCooldown&) = default;
};

using GameClientMessage = std::variant<Hello, Login, Resume, Ping, Logout, CreateCharacter,
    DeleteCharacter, EnterGame, Move, Talk, DialogChoose, QuestAccept, QuestTurnIn, QuestAbandon,
    DialogClose, ExecuteScript, CastSkill, Respawn, PickUp>;
using GameClientResult = std::expected<GameClientMessage, WireError>;
using GameServerMessage = std::variant<Welcome, SessionStart, ContentKey, Pong, Reject, Goodbye,
    ContentStamp, UiConfig, CharacterList, Position, SceneEnter, EntityAppear, EntityDisappear,
    EntityPos, EntityVitals, EntityFlags, EntityPosBatch, DialogOpen, DialogClosed, QuestBook,
    QuestNotice, UiCommand, SelfStats, SelfVitals, SelfBag, SkillCast, SkillCastEnd, CombatEvent,
    EntityDied, DeathNotice, SelfSkills, SkillCooldown>;
using GameServerResult = std::expected<GameServerMessage, WireError>;
using AuthClientMessage = std::variant<Hello, CreateAccount, SignIn>;
using AuthClientResult = std::expected<AuthClientMessage, WireError>;
using AuthServerMessage = std::variant<Welcome, Reject, Goodbye, Ticket>;
using AuthServerResult = std::expected<AuthServerMessage, WireError>;

// Ghi một khung (đầu khung 8 byte cộng thân) vào cuối out; lỗi thì out giữ nguyên cỡ cũ.
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Hello& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Login& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Resume& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Ping& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Logout& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const CreateCharacter& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const DeleteCharacter& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const EnterGame& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Move& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const CreateAccount& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const SignIn& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Talk& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const DialogChoose& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const QuestAccept& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const QuestTurnIn& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const QuestAbandon& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const DialogClose& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const ExecuteScript& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const CastSkill& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Respawn& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const PickUp& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Welcome& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const SessionStart& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const ContentKey& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Pong& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Reject& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Goodbye& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const ContentStamp& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const UiConfig& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const CharacterList& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Position& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const SceneEnter& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const EntityAppear& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const EntityDisappear& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const EntityPos& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const EntityVitals& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const EntityFlags& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const EntityPosBatch& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const Ticket& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const DialogOpen& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const DialogClosed& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const QuestBook& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const QuestNotice& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const UiCommand& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const SelfStats& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const SelfVitals& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const SelfBag& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const SkillCast& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const SkillCastEnd& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const CombatEvent& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const EntityDied& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const DeathNotice& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const SelfSkills& message);
[[nodiscard]] WireStatus encode(std::vector<std::byte>& out, const SkillCooldown& message);

// Giải mã thân của một khung đã tách bằng peek_frame. Kind không thuộc cổng hoặc chiều của bộ giải
// mã là kUnknownKind; còn byte sau trường cuối là kTrailingBytes.
[[nodiscard]] GameClientResult decode_game_client(const Frame& frame, ByteView body);
[[nodiscard]] GameServerResult decode_game_server(const Frame& frame, ByteView body);
[[nodiscard]] AuthClientResult decode_auth_client(const Frame& frame, ByteView body);
[[nodiscard]] AuthServerResult decode_auth_server(const Frame& frame, ByteView body);

// Bản danh mục đầu tiên có tin mang mã `kind`; 0 với mã không có trong danh mục.
[[nodiscard]] constexpr std::uint16_t since_of(std::uint16_t kind) noexcept {
    switch (kind) {
    case 0x0101:
    case 0x0102:
    case 0x0103:
    case 0x0104:
    case 0x0105:
    case 0x0201:
    case 0x0202:
    case 0x0203:
    case 0x0301:
    case 0x0501:
    case 0x0502:
    case 0x8101:
    case 0x8102:
    case 0x8103:
    case 0x8104:
    case 0x8106:
    case 0x8107:
    case 0x8108:
    case 0x8201:
    case 0x8301:
    case 0x8501: return 1;
    case 0x8109: return 2;
    case 0x8401:
    case 0x8402:
    case 0x8403:
    case 0x8404:
    case 0x8405: return 4;
    case 0x0601:
    case 0x0602:
    case 0x0603:
    case 0x0604:
    case 0x0605:
    case 0x0606:
    case 0x8406:
    case 0x8601:
    case 0x8602:
    case 0x8603:
    case 0x8604:
    case 0x8701: return 5;
    case 0x0801:
    case 0x0802:
    case 0x0803:
    case 0x8702:
    case 0x8703:
    case 0x8801:
    case 0x8802:
    case 0x8803:
    case 0x8804:
    case 0x8805:
    case 0x8806:
    case 0x8807: return 6;
    case 0x8407: return 7;
    case 0x0607:
    case 0x8605: return 8;
    default: return 0;
    }
}

} // namespace game::protocol
