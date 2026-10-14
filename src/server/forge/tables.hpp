#pragma once
// Công thức chế biến một-món-vào-một-món-ra của lò rèn: nung ngọc (GemMelting.txt), chạm ngọc (GemCarve.txt) và nâng cấp
// siêu vũ khí (SuperWeaponUpgrade.txt của XJL7457). Mỗi công thức: món đầu vào, món đầu ra, vàng, vật liệu phải trừ, và
// (chỉ nung ngọc) bộ vật liệu thay thế.
//
// Nguồn: tiêu đề cột của ba bảng (宝石ID / 熔炼后宝石ID / 需要物品ID / 需要金钱 / 可替代物品ID; 宝石ID / 雕琢后宝石ID / 需要物品ID /
// 需要金钱; bảng nâng cấp siêu vũ khí do import_item.py đặt tên cột). 2008 không có hệ thống nào trong ba hệ thống này: gốc 2008
// chỉ có khảm ngọc qua kịch bản Lua (AbilityInlay), nên luật dưới đây là suy ra từ dữ liệu 2026 và XJL7457.
// Giả định (docs/SERVER-ITEM.md, mục Lò rèn): (1) mọi công thức thành công 100%: bảng không có cột xác suất;
// (2) `material_count` của bảng nâng cấp là số cái của MỖI vật liệu trong hai vật liệu; (3) dòng nâng cấp có gold_cost = -1
// (126 trên 438 dòng, không vật liệu) là chưa mở: không phải nâng cấp miễn phí, nên bị bỏ và chỉ đếm ở diagnostics();
// (4) món ra là món MỚI sinh bằng Factory (thuộc tính ngẫu nhiên mới), chỉ giữ cờ khoá của món vào.
//
// Hợp đồng nạp: lỗi bảng (thiếu cột, số ngoài miền, đầu vào trùng) trả câu lỗi tiếng Việt kèm bảng và dòng. Dòng có mã ngoài
// catalog (đầu vào, đầu ra hay vật liệu) bị bỏ và đếm ở diagnostics().

#include "item/catalog.hpp"
#include "item/types.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::forge {

enum class Kind : std::uint8_t {
    kMelt = 0,     // nung ngọc
    kCarve = 1,    // chạm ngọc
    kAdvance = 2,  // nâng cấp siêu vũ khí
};

inline constexpr std::size_t kKindCount = 3;

// Nội dung các bảng; trống = không có công thức loại đó. Văn bản phải sống tới hết lời gọi ForgeTables::load.
struct ForgeSources {
    std::string_view melting{};   // shared/gem_melting.tsv
    std::string_view carving{};   // shared/gem_carving.tsv
    std::string_view advances{};  // server/super_weapon_advances.tsv
};

struct Material {
    item::TemplateId item;
    std::uint16_t count = 1;

    friend constexpr bool operator==(const Material&, const Material&) noexcept = default;
};

struct Recipe {
    item::TemplateId input;
    item::TemplateId output;
    std::int64_t gold = 0;
    std::uint32_t needs_begin = 0;  // đoạn vật liệu chính trong kho vật liệu
    std::uint8_t needs_count = 0;
    std::uint32_t alt_begin = 0;    // đoạn vật liệu thay thế (nung ngọc); alt_count = 0 là không có
    std::uint8_t alt_count = 0;
};

struct Diagnostics {
    std::size_t unknown_rows = 0;     // dòng có mã ngoài catalog
    std::size_t disabled_advances = 0;  // dòng nâng cấp gold_cost = -1
};

class ForgeTables {
public:
    [[nodiscard]] static std::expected<ForgeTables, std::string> load(const ForgeSources& sources, const item::Catalog& catalog);

    // Công thức của món đầu vào; nullptr khi không có. O(log n).
    [[nodiscard]] const Recipe* find(Kind kind, item::TemplateId input) const noexcept;
    [[nodiscard]] std::span<const Recipe> all(Kind kind) const noexcept;
    [[nodiscard]] std::span<const Material> needs(const Recipe& recipe) const noexcept;
    [[nodiscard]] std::span<const Material> alternative(const Recipe& recipe) const noexcept;
    [[nodiscard]] const Diagnostics& diagnostics() const noexcept { return diagnostics_; }

private:
    friend struct ForgeLoader;

    std::array<std::vector<Recipe>, kKindCount> recipes_;  // mỗi loại xếp tăng theo mã đầu vào
    std::vector<Material> materials_;
    Diagnostics diagnostics_{};
};

} // namespace game::forge
