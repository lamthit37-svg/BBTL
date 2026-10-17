/*==============================================================================
 *  THIENLONG  |  GAME CLIENT
 *------------------------------------------------------------------------------
 *  TỆP       : src/client/figure/look/impact.hpp
 *  PHÂN HỆ   : Figure / Look / Impact
 *  CHUẨN     : C++23
 *------------------------------------------------------------------------------
 *  CHỨC NĂNG
 *  - Hiệu ứng trên người: đếm tham chiếu, hiệu ứng bật một lần và hiệu ứng
 *    giữ. Logic thuần, không I/O. Số cột lấy từ ImpactSEData_V1 của client 2026.
 *  - Nguồn hành vi: CObject_Character::InsertImpact / RemoveImpact (client 2008).
 *------------------------------------------------------------------------------
 *  TÁC GIẢ   : HiepHoon
 *  TELEGRAM  : @Hoon9xx
 *============================================================================*/

#pragma once

#include "look/appearance.hpp"

#include <cstdint>
#include <expected>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::look {

// Trần số hiệu ứng khác nhau cùng lúc trên một người. UI gốc cũng dừng ở 256.
inline constexpr std::size_t kMaxImpacts = 256;

enum class ImpactCueKind : std::uint8_t { kOnce, kSound, kAttach, kDetach };

// Một việc nơi vẽ phải làm. anchor là tên locator gốc; nơi vẽ chưa có locator thân thì gắn ở chân.
struct ImpactCue {
    ImpactCueKind kind = ImpactCueKind::kOnce;
    std::uint32_t id = 0;
    std::string name;
    std::string anchor;
};

// Một dòng bảng. Hiệu ứng tuyến chưa có chỗ vẽ: cờ được giữ, không bịa đoạn thẳng.
struct ImpactRow {
    std::uint32_t id = 0;
    std::string trigger_effect;
    std::string trigger_sound;
    std::string trigger_anchor;
    std::string continuous_effect;
    std::string continuous_sound;
    std::string continuous_anchor;
    bool kept_after_death = false;
    bool is_linear = false;
    std::string linear_anchor;
};

// Ô đang gắn. continuous rỗng là không có hạt để tháo.
struct ImpactSlot {
    std::uint32_t id = 0;
    std::uint32_t refs = 0;
    std::string continuous;
    std::string anchor;
    bool kept_after_death = true;
    bool is_linear = false;
    std::string linear_anchor;
};

// Sổ hiệu ứng của một nhân vật. Id lạ vẫn chiếm một ô (gốc vẫn new SImpactEffect) nhưng không phát
// hạt.
class ImpactBook {
public:
    void reset(std::vector<ImpactRow> rows);
    [[nodiscard]] bool known(std::uint32_t id) const noexcept;
    // show bật hạt và tiếng một lần. Lần sau cùng id chỉ tăng đếm, không phát thêm.
    [[nodiscard]] std::vector<ImpactCue> enable(std::uint32_t id, bool show);
    [[nodiscard]] std::vector<ImpactCue> disable(std::uint32_t id);
    // Bỏ ô không giữ sau khi chết. RemoveAllImpact là clear(), bỏ hết.
    [[nodiscard]] std::vector<ImpactCue> drop_dead();
    [[nodiscard]] std::vector<ImpactCue> clear();
    [[nodiscard]] std::span<const ImpactSlot> slots() const noexcept { return slots_; }

private:
    [[nodiscard]] const ImpactRow* find_row(std::uint32_t id) const noexcept;
    [[nodiscard]] std::vector<ImpactSlot>::iterator find_slot(std::uint32_t id) noexcept;
    [[nodiscard]] std::vector<ImpactCue> enable_new(std::uint32_t id, bool show);

    std::vector<ImpactRow> rows_;
    std::vector<ImpactSlot> slots_;
};

using ImpactRows = std::expected<std::vector<ImpactRow>, std::string>;

// Bảng impacts.tsv. Thiếu cột, ô sai, khoá trùng: lỗi, không dựng nửa bảng.
[[nodiscard]] ImpactRows parse_impacts(std::string_view text);

} // namespace game::look
