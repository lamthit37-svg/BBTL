#pragma once
// Kiểu dữ liệu của hội thoại: thứ máy chủ trả cho client sau mỗi ý định (nói chuyện, chọn mục, nhận, nộp). Máy chủ không gửi chữ:
// mỗi dòng là mã chuỗi (ops::string_id của khoá) kèm tham số có kiểu, client tự tra bảng chuỗi và dựng câu (ADR-003).
//
// Dialogue là bộ dựng một hộp thoại: vừa giữ View gửi đi, vừa giữ danh tính từng lựa chọn (script đích, giá trị, chữ) để lúc
// client chọn, máy chủ so lại với hộp thoại tính lại ở trạng thái hiện tại (phiên do máy chủ giữ, không tin chỉ số client gửi).

#include "ops/ops.hpp"

#include <cstddef>
#include <cstdint>
#include <optional>
#include <vector>

namespace game::talk {

// Trần của một hộp thoại. Script gốc dùng vài chục dòng/lựa chọn; trần cao hơn nhiều để dữ liệu thù địch không phình bộ nhớ.
inline constexpr std::size_t kMaxLines = 64;
inline constexpr std::size_t kMaxChoices = 128;
inline constexpr std::size_t kMaxBonuses = 64;
inline constexpr std::size_t kMaxMarks = 64;

// Cách client hiển thị hộp thoại, theo hàm Dispatch* của script gốc.
enum class Mode : std::uint8_t {
    kList,         // DispatchEventList: lời NPC + danh sách lựa chọn
    kBox,          // DispatchEventList(-1): hộp thoại không gắn NPC (dùng vật phẩm, bảng)
    kMissionInfo,  // DispatchMissionInfo: mô tả nhiệm vụ + phần thưởng + nút nhận
    kContinue,     // DispatchMissionContinueInfo: nhiệm vụ đang làm, chưa xong
    kDemand,       // DispatchMissionDemandInfo: yêu cầu nộp + phần thưởng + nút nộp
    kTips,         // DispatchMissionTips: nhắc ngắn
};

struct Line {
    ops::TextRef text;
};

struct Choice {
    std::uint16_t index = 0;  // vị trí trong bảng lựa chọn của phiên; client gửi lại đúng số này
    std::int32_t icon = 0;
    ops::TextRef text;
};

// Dấu hiệu nhiệm vụ trên đầu NPC: (!) nhận được, (?) đang làm, (?) đủ điều kiện nộp.
enum class Stage : std::uint8_t { kAvailable, kInProgress, kReady };

struct Mark {
    std::int32_t quest = 0;
    Stage stage = Stage::kAvailable;
    friend bool operator==(const Mark&, const Mark&) noexcept = default;
};

enum class BonusKind : std::uint8_t { kMoney, kItem, kRadio, kRandom, kDemand };

// Dòng phần thưởng / yêu cầu hiển thị trong bảng nhiệm vụ của script: money (a = tiền), còn lại a = mẫu vật phẩm, b = số lượng.
struct Bonus {
    BonusKind kind = BonusKind::kMoney;
    std::int32_t a = 0;
    std::int32_t b = 0;
    std::int32_t c = 0;
    friend bool operator==(const Bonus&, const Bonus&) noexcept = default;
};

struct View {
    Mode mode = Mode::kList;
    std::vector<Line> lines;
    std::vector<Choice> choices;
    std::vector<Mark> marks;
    std::int32_t panel_quest = -1;  // nhiệm vụ của bảng (kMissionInfo, kContinue, kDemand, kTips); -1 nếu không có
    std::vector<Bonus> bonuses;

    [[nodiscard]] bool empty() const noexcept {
        return lines.empty() && choices.empty() && marks.empty() && panel_quest < 0;
    }
};

// Danh tính một lựa chọn: đủ để nhận ra "cùng lựa chọn đó" sau khi tính lại hộp thoại.
struct Option {
    std::uint32_t script = 0;   // script chứa phần xử lý (chính là script có lựa chọn này, không phải số client gửi)
    std::int32_t value = -1;    // GetNumText khi chọn
    std::int32_t icon = 0;
    std::uint32_t text = 0;     // mã chuỗi của chữ lựa chọn

    friend bool operator==(const Option&, const Option&) noexcept = default;
};

class Dialogue {
public:
    // BeginEvent của script gốc: bỏ mọi thứ đang dựng (một lần chạy có thể mở hộp thoại nhiều lần, chỉ cái cuối được gửi).
    void begin() {
        view_ = View{};
        options_.clear();
    }

    [[nodiscard]] bool line(ops::TextRef text) {
        if (view_.lines.size() >= kMaxLines) return false;
        view_.lines.push_back(Line{std::move(text)});
        return true;
    }

    [[nodiscard]] bool choice(std::uint32_t script, std::int32_t icon, std::int32_t value, ops::TextRef text) {
        if (options_.size() >= kMaxChoices) return false;
        options_.push_back(Option{.script = script, .value = value, .icon = icon, .text = text.id});
        view_.choices.push_back(
            Choice{.index = static_cast<std::uint16_t>(options_.size() - 1), .icon = icon, .text = std::move(text)});
        return true;
    }

    [[nodiscard]] bool bonus(const Bonus& one) {
        if (view_.bonuses.size() >= kMaxBonuses) return false;
        view_.bonuses.push_back(one);
        return true;
    }

    void set_mode(Mode mode) noexcept { view_.mode = mode; }
    void set_panel(std::int32_t quest) noexcept { view_.panel_quest = quest; }
    [[nodiscard]] bool mark(const Mark& one) {
        if (view_.marks.size() >= kMaxMarks) return false;
        view_.marks.push_back(one);
        return true;
    }

    [[nodiscard]] const View& view() const noexcept { return view_; }
    [[nodiscard]] View take_view() { return std::move(view_); }
    [[nodiscard]] const std::vector<Option>& options() const noexcept { return options_; }
    [[nodiscard]] std::optional<Option> option(std::size_t index) const {
        if (index >= options_.size()) return std::nullopt;
        return options_[index];
    }

private:
    View view_;
    std::vector<Option> options_;
};

}  // namespace game::talk
