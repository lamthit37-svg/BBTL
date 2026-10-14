#pragma once
// Bộ chạy nhiệm vụ: máy trạng thái nhận / đang làm / nộp / bỏ / hỏng trên Book của một nhân vật, chạy chung cho nhiệm vụ bảng
// (kill, loot, delivery, enter-area của client 2026) và nhiệm vụ script đã trích thành điều kiện + hiệu ứng đóng.
//
// Nguyên tắc (ADR-002, MMO-08/LH-12): mỗi thao tác là HAI PHA. Pha một kiểm điều kiện chỉ đọc; pha hai dựng bản nháp của Book và
// danh sách dòng sổ cái, chạy sổ cái (một giao dịch nguyên tử, có mã yêu cầu chống gửi lại) rồi mới thay Book bằng bản nháp.
// Thất bại ở bất kỳ bước nào trả lỗi có kiểu và KHÔNG để lại gì trong Book hay túi/ví.
//
// Tất định: ngẫu nhiên đến từ dice::Dice do bên gọi giữ; lịch (ngày, giờ, tuần) là ĐẦU VÀO (ops::Calendar tính từ tick mô
// phỏng), không có lời gọi đồng hồ thật nào. Nhiều dòng cùng id nhiệm vụ là các biến thể: nhận theo id sẽ chọn biến thể có
// cấp cao nhất không vượt cấp nhân vật và đạt điều kiện (chọn ngẫu nhiên đều trong các biến thể ngang cấp; không tốn ngẫu
// nhiên nếu chỉ có một ứng viên). Quy tắc này là của dự án, không phải của script gốc: bản gốc để script quyết định.

#include "bus/bus.hpp"
#include "dice/dice.hpp"
#include "ledger/ledger.hpp"
#include "mission/catalog.hpp"
#include "mission/hero.hpp"
#include "ops/ops.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <string_view>
#include <vector>

namespace game::mission {

enum class [[nodiscard]] Error : std::uint8_t {
    kUnknownQuest = 1,
    kNotRunnable,        // nhiệm vụ chưa có bộ chạy, không có trong client, hoặc bị chặn bởi vòng tiền đề
    kAlreadyActive,
    kAlreadyDone,
    kBookFull,           // đủ 20 ô
    kLevelTooLow,
    kPrerequisite,
    kCondition,          // điều kiện nhận không đạt
    kBanned,             // đang trong thời gian cấm nhận lại (sau khi bỏ nhiệm vụ vòng)
    kNotActive,
    kNotReady,           // chưa đủ điều kiện nộp
    kNeedChoice,         // nhiệm vụ có phần thưởng chọn một nhưng chưa chọn
    kBadChoice,          // lựa chọn không thuộc phần thưởng chọn
    kBookLimit,          // hiệu ứng làm vượt trần bộ đếm, cờ hay số ô
    kLedger,             // sổ cái từ chối; xem Failure::ledger
};

[[nodiscard]] std::string_view describe(Error error) noexcept;

struct Failure {
    Error error = Error::kUnknownQuest;
    ledger::Reason ledger = ledger::Reason::kCommitted;  // chỉ có nghĩa với kLedger
    friend bool operator==(const Failure&, const Failure&) noexcept = default;
};

enum class NoticeKind : std::uint8_t {
    kAdded,         // nhiệm vụ vào sổ
    kUpdated,       // tiến độ đổi
    kReady,         // đủ điều kiện nộp
    kRemoved,       // ra khỏi sổ (nộp, bỏ, hỏng)
    kDone,          // đánh dấu đã xong
    kFailed,        // hỏng
    kText,          // thông báo cho người chơi
    kAnnounce,      // thông báo toàn máy chủ
    kRewardExp,     // value = kinh nghiệm
    kRewardMoney,   // value = số tiền, ref = 1 nếu tiền khoá
    kRewardItem,    // ref = mẫu vật phẩm, value = số lượng
    kRelation,      // ref = chỉ số bộ đếm quan hệ, value = giá trị mới
};

// Tin gửi cho client, dạng có kiểu (lớp mạng thuộc vai khác sẽ dựng khung từ đây). Chữ là mã chuỗi + tham số có kiểu.
struct Notice {
    NoticeKind kind = NoticeKind::kText;
    std::int32_t quest = -1;
    ops::TextRef text;
    std::int64_t value = 0;
    std::int32_t ref = 0;
};

// Hiệu ứng không phải trạng thái của Book hay sổ cái: giao cho thế giới / hội thoại làm (dịch chuyển, mở cửa hàng, chỉ đường,
// mời nhận nhiệm vụ kế).
struct Directive {
    ops::EffectOp op = ops::EffectOp::kTeleport;
    std::array<std::int32_t, 3> arg{};
    ops::TextRef text;
};

struct Outcome {
    std::int32_t quest = -1;
    std::uint32_t script = 0;
    std::vector<Notice> notices;
    std::vector<Directive> directives;
    ledger::Receipt receipt;  // biên nhận sổ cái; mã 0 nếu thao tác không đụng tới túi/ví/kinh nghiệm
    std::optional<Failure> refused;  // chỉ handle(): sự kiện không áp dụng được (trần sổ, sổ cái từ chối); Book không đổi
};

using Result = std::expected<Outcome, Failure>;

class Engine {
public:
    Engine(const Catalog& catalog, dice::Dice& dice) noexcept : catalog_(catalog), dice_(dice) {}

    // Nguồn ngẫu nhiên dùng chung của cảnh (hội thoại chọn một trong nhiều lời chào dùng cùng nguồn để chạy lại ra cùng kết quả).
    [[nodiscard]] dice::Dice& dice() const noexcept { return dice_; }

    // Nhận nhiệm vụ theo id client (chọn biến thể). Hai pha; không đổi gì khi lỗi.
    [[nodiscard]] Result accept(Character& who, std::int32_t quest, const ops::Calendar& calendar);
    // Nhận đúng một dòng (script): dùng cho tự nhận theo cấp và cho test.
    [[nodiscard]] Result accept_script(Character& who, std::uint32_t script, const ops::Calendar& calendar);

    // Nộp nhiệm vụ đang làm. `choice` là mẫu vật phẩm đã chọn trong nhóm thưởng chọn một (-1 nếu không có nhóm đó).
    [[nodiscard]] Result turn_in(Character& who, std::int32_t quest, std::int32_t choice, const ops::Calendar& calendar);
    [[nodiscard]] Result abandon(Character& who, std::int32_t quest, const ops::Calendar& calendar);
    // Nhiệm vụ hỏng (hết giờ, mục tiêu chết): như bỏ nhưng báo kFailed và không đặt thời gian cấm nhận lại.
    [[nodiscard]] Result fail(Character& who, std::int32_t quest, const ops::Calendar& calendar);

    // Xử lý một sự kiện từ bus cho nhân vật mà nó nhắm tới. Sự kiện không bao giờ "lỗi": phần không áp dụng được (ví dụ túi đầy khi
    // rơi vật phẩm nhiệm vụ) thành thông báo trong Outcome.
    [[nodiscard]] Outcome handle(Character& who, const bus::Event& event, const ops::Calendar& calendar);

    // Ngữ cảnh một lần chạy bộ hiệu ứng của hội thoại. `source` ghi vào nhật ký kiểm toán của sổ cái (thường là id script).
    struct EffectsRun {
        std::int32_t radio = -1;        // phần thưởng chọn (mẫu vật phẩm), -1 là chưa chọn
        std::uint32_t target_name = 0;  // mã tên NPC đang đối thoại
        std::uint32_t source = 0;
    };
    // Áp một bộ hiệu ứng của hội thoại thành MỘT giao dịch trên sổ, túi, ví, kinh nghiệm: hoặc đủ hoặc không gì cả. Điều kiện
    // của từng hiệu ứng được đánh giá trên trạng thái trước khi áp (cùng quy ước với ops::Program::plan).
    [[nodiscard]] Result run_effects(Character& who, std::int32_t effects_id, const EffectsRun& run,
        const ops::Calendar& calendar);

    // Cho hội thoại: id nhiệm vụ này nhận được ngay không (nullopt = được, tức có ít nhất một biến thể đạt). Khi từ chối,
    // lỗi là của biến thể dễ nhất. Không dùng ngẫu nhiên.
    [[nodiscard]] std::optional<Failure> can_accept(Character& who, std::int32_t quest, const ops::Calendar& calendar) const;

    // Truy vấn chỉ đọc cho hội thoại: nhận được ngay không (nullopt = được), và đã đủ điều kiện nộp chưa.
    [[nodiscard]] std::optional<Failure> check_accept(Character& who, const Quest& quest,
        const ops::Calendar& calendar) const;
    [[nodiscard]] bool ready(Character& who, const Quest& quest, const ops::Calendar& calendar) const;

    [[nodiscard]] const Catalog& catalog() const noexcept { return catalog_; }

private:
    // NOLINTBEGIN(cppcoreguidelines-avoid-const-or-ref-data-members): danh bạ và nguồn ngẫu nhiên do cảnh sở hữu, sống lâu hơn Engine, không sở hữu, không giữ qua tick (SH-04)
    const Catalog& catalog_;
    dice::Dice& dice_;
    // NOLINTEND(cppcoreguidelines-avoid-const-or-ref-data-members)
};

// Trần của điểm quan hệ (g_MaxRelationship của mod_event.lua); điểm phạt không đưa quan hệ xuống dưới 0.
inline constexpr std::int64_t kMaxRelationship = 9999;

}  // namespace game::mission
