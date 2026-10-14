#pragma once
// Danh mục mẫu vật phẩm hợp nhất của máy chủ: một bảng tra id -> Template cho đồ thường, trang bị, đá quý và
// trang bị trân thú, nạp từ các bảng TSV của client 2026 (dev/server/tables/shared).
//
// Nguồn: cột và ý nghĩa đọc từ loader ItemTable.cpp của GameServer 2008 (InitWhiteItemTable, InitCommItemInfoTable,
// InitGemInfoTable, InitItemRulerTable) đối chiếu với tiêu đề cột của client 2026; mã vật phẩm
// = lớp*10^7 + phẩm*10^5 + loại*10^3 + số thứ tự nhưng bảng ghi sẵn lớp/phẩm/loại nên đọc từ cột, không tách id.
// Khác gốc: 2008 giữ ba bảng trang bị riêng (trắng, lam, lục) còn client 2026 gộp thành EquipBase.txt;
// bản này đọc bảng gộp và bỏ ba bảng cũ (mọi id của trắng và lam có trong bảng gộp, lục thiếu mười id
// cũ không tham chiếu từ bảng rơi hay cửa hàng nào). Phân túi theo lớp (2 = nguyên liệu, 4 = nhiệm vụ) là suy ra
// từ ITEM_CLASS 2008, client 2026 không có bảng nói thẳng.

#include "item/types.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <span>
#include <string>
#include <string_view>
#include <vector>

namespace game::item {

enum class Kind : std::uint8_t {
    kCommon,        // đồ thường: thuốc, nguyên liệu, nhiệm vụ, sách
    kEquipment,     // trang bị người chơi (lớp 1)
    kGem,           // đá quý (lớp 5)
    kPetEquipment,  // trang bị trân thú (lớp 7)
};

// Một dòng ItemRule.txt: cờ cho phép của mẫu (thứ tự cột 2008 IRL_*).
struct Rule {
    bool discard = false;     // vứt được
    bool tile = false;        // chồng được
    bool shortcut = false;    // đặt lên thanh phím tắt
    bool sell = false;        // bán cho NPC được
    bool exchange = false;    // giao dịch được
    bool use = false;         // dùng được
    bool pick_bind = false;   // khoá khi nhặt
    bool equip_bind = false;  // khoá khi mặc
    bool unique = false;      // chỉ sở hữu một
};

inline constexpr std::uint8_t kAnySect = 0xFF;
inline constexpr std::uint8_t kAnySex = 0xFF;
inline constexpr std::uint8_t kNoEquipPoint = 0xFF;

// Trọng số một thuộc tính trong lượt chọn ngẫu nhiên của trang bị (cột 30..87 của EquipBase.txt).
struct Weighted {
    AttrId attr;
    std::uint16_t weight = 0;
};

// Phần riêng của trang bị. Với trang bị trân thú chỉ điểm lắp và thuộc tính nền là có nghĩa.
struct EquipSpec {
    std::uint8_t point = kNoEquipPoint;  // điểm lắp = equip_point, 0..23
    std::uint8_t sect = kAnySect;        // môn phái yêu cầu
    std::uint8_t sex = kAnySex;          // giới tính yêu cầu (bảng client không có cột này: luôn kAnySex)
    std::uint16_t max_durability = 0;    // độ bền tối đa, 0 = không hao mòn
    std::uint8_t max_repairs = 0;        // số lần sửa tối đa trước khi phế (cột 17)
    std::uint8_t gem_slots = 0;          // số ô đá tối đa (cột 100)
    std::array<std::int32_t, 6> base{};  // thuộc tính nền theo id 58..63, 0 = không có
    // Sinh ngẫu nhiên (phẩm khác trắng): xem roll.hpp.
    std::uint8_t seg_rule = 0;           // quality_rules; 0 = không sinh
    std::int16_t band_start = -1;        // value_band_start; -1 = không có
    std::uint8_t attr_min = 0;
    std::uint8_t attr_max = 0;
    std::uint16_t apt_min = 0;           // aptitude_min; 0 = không có tư chất
    std::uint16_t apt_max = 0;
    std::uint32_t weight_begin = 0;      // đoạn trong kho trọng số của danh mục
    std::uint16_t weight_count = 0;
};

struct Template {
    TemplateId id;
    Kind kind = Kind::kCommon;
    std::uint8_t item_class = 0;
    std::uint8_t quality = 0;
    std::uint8_t type = 0;
    std::uint16_t level = 0;          // cấp yêu cầu
    std::int32_t base_price = 0;
    std::int32_t sale_price = 0;
    Rule rule{};
    std::uint16_t stack_max = 1;      // 1 khi không chồng được
    std::int32_t max_owned = 0;       // giới hạn số lượng sở hữu, 0 = không giới hạn
    std::int32_t duration_hours = 0;  // thời hạn kể từ lúc sinh ra (EquipExtraAttr), 0 = vĩnh viễn
    Place home = Place::kBaseBag;     // túi mặc định
    EquipSpec equip{};
    std::uint32_t gem_begin = 0;      // đá quý: đoạn thuộc tính trong kho của danh mục
    std::uint16_t gem_count = 0;

    [[nodiscard]] bool is_equipment() const noexcept { return kind == Kind::kEquipment; }
    [[nodiscard]] bool wearable() const noexcept {
        return (kind == Kind::kEquipment || kind == Kind::kPetEquipment) && equip.point != kNoEquipPoint;
    }
};

// Nội dung các bảng; trống = bảng không có. Văn bản phải sống tới hết lời gọi Catalog::load.
struct CatalogSources {
    std::string_view rules{};       // item_rules.tsv (bắt buộc)
    std::string_view common{};      // items_common.tsv
    std::string_view equipment{};   // equipment.tsv
    std::string_view gems{};        // gems.tsv
    std::string_view pet_equipment{};      // pet_equipment_base.tsv
    std::string_view extra_attributes{};   // equipment_extra_attributes.tsv (thời hạn)
};

struct CatalogLoader;

class Catalog {
public:
    // Nạp và kiểm chéo (mọi mẫu trỏ tới dòng luật có thật, id không trùng). Lỗi là câu tiếng Việt kèm bảng và dòng.
    [[nodiscard]] static std::expected<Catalog, std::string> load(const CatalogSources& sources);

    // Tra theo id; nullptr khi không có. O(log n).
    [[nodiscard]] const Template* find(TemplateId id) const noexcept;
    [[nodiscard]] std::size_t size() const noexcept { return templates_.size(); }
    [[nodiscard]] std::span<const Template> all() const noexcept { return templates_; }

    // Trọng số ngẫu nhiên và thuộc tính đá quý của một mẫu.
    [[nodiscard]] std::span<const Weighted> weights(const Template& t) const noexcept;
    [[nodiscard]] std::span<const AttrValue> gem_attrs(const Template& t) const noexcept;

    // Tra dòng luật theo chỉ số của bảng; nullptr khi không có.
    [[nodiscard]] const Rule* rule(std::uint32_t index) const noexcept;

private:
    friend struct CatalogLoader;

    std::vector<Template> templates_;      // xếp tăng theo id
    std::vector<Weighted> weight_pool_;
    std::vector<AttrValue> gem_pool_;
    std::vector<Rule> rules_;
    std::vector<std::uint32_t> rule_ids_;  // id dòng luật, tăng dần, song song với rules_
};

} // namespace game::item
