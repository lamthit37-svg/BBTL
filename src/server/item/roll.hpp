#pragma once
// Sinh phần ngẫu nhiên của trang bị: thuộc tính cộng và tư chất, theo bộ bảng ItemSeg* của máy chủ 14 môn
// phái (XJL7457 Server/Config) và ItemSegValue/ItemAptRate của client 2026.
//
// Nguồn: ItemCreateRuler::CreateBlueEquipAttrib của 2008 (GameServer/Server/Item/ItemRuler.cpp) chọn thuộc
// tính theo trọng số, rồi MỖI thuộc tính tự quay phẩm chất riêng (CaculateQualityIndex) và lấy giá trị theo phẩm
// chất đó. Bảng EquipBase.txt của client 2026 đã đổi sang bộ ItemSeg: mỗi dòng trang bị khai số thuộc tính
// [attribute_count_min, attribute_count_max], trọng số chọn thuộc tính (cột 30..87), `quality_rules` (dòng của
// ItemSegQuality), `value_band_start` (đoạn ItemSegValue gốc) và khoảng tư chất. Máy chủ 14 môn phái chỉ có bản
// nhị phân, nên phép tính dưới đây SUY RA từ dữ liệu và từ mã 2008 (docs/SERVER-ITEM.md mục "Giả định"):
//   1. n = ngẫu nhiên đều trong [attr_min, attr_max], không quá số thuộc tính có trọng số.
//   2. Chọn n thuộc tính khác nhau, mỗi lần theo trọng số trên phần còn lại.
//   3. Dòng ItemSegQuality `quality_rules`, cột theo NGUỒN của món đồ (tên cột trong tệp gốc: 0 quái thường,
//      1 thủ lĩnh, 2 đầu mục, 3 rương, 4 BOSS phó bản, 5 BOSS giờ, 6 BOSS ngày, 7 rèn không nguyên liệu, 9..16 rèn
//      nguyên liệu cấp 1..8; cột 7 và 9..16 "đã tách": truy cập thì ánh xạ theo điểm lắp 0..18 sang cột 19.. và
//      38..) cho id một dòng ItemSegAffect: 9 trọng số của chín phẩm chất. Ô -1 = không có phân bố, lấy phẩm chất 1.
//   4. MỖI thuộc tính quay phẩm chất riêng theo dòng ItemSegAffect đó (chia cho tổng trọng số; cột "total" của tệp
//      gốc không khớp tổng ở 36 dòng nên không dùng). Đoạn = value_band_start + (phẩm chất - 1); giá trị =
//      ItemSegValue[đoạn][thuộc tính]. Đoạn không có thì lấy đoạn lớn nhất nhỏ hơn trong cùng nghìn; không có giá
//      trị thì bỏ thuộc tính ấy.
//   5. Tư chất ngẫu nhiên đều trong [apt_min, apt_max]; mỗi thuộc tính nền (id 58..63) của mẫu được cộng thêm
//      nền * ItemAptRate[tư chất] / 100 (làm tròn xuống) thành một thuộc tính riêng trên thể hiện.
// Khác gốc: không dùng ItemQuality/ItemValue của 2008 (bảng gộp của client 2026 không còn cột tỉ lệ của chúng);
// ItemSegRate (10 dòng x 63 cột "rate" theo phẩm chất) chưa rõ nghĩa nên chưa dùng.

#include "item/catalog.hpp"
#include "item/instance.hpp"
#include "item/types.hpp"

#include "dice/dice.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace game::item {

// Nguồn của món đồ khi sinh, quyết định cột ItemSegQuality (xem bước 3 ở đầu tệp).
enum class Origin : std::uint8_t {
    kMonster = 0,      // 普通怪
    kLeader = 1,       // 首领
    kHeadman = 2,      // 头目
    kChest = 3,        // 宝箱
    kDungeonBoss = 4,  // 副本BOSS
    kHourlyBoss = 5,   // 小时BOSS
    kDailyBoss = 6,    // 天BOSS
    kForge = 7,        // rèn / chế tạo: thêm forge_level
};

inline constexpr std::uint8_t kMaxForgeLevel = 8;   // cấp nguyên liệu rèn lớn nhất của ItemSegQuality
inline constexpr std::uint8_t kMaxAssemblyPoint = 18;  // điểm lắp 0..18 có cột tách; điểm lớn hơn dùng cột gộp

struct RollContext {
    Origin origin = Origin::kMonster;
    std::uint8_t forge_level = 0;  // chỉ dùng khi origin == kForge: 0 không nguyên liệu, 1..8 cấp nguyên liệu
};

struct RollSources {
    std::string_view values_shared{};   // shared/item_segment_values.tsv (client 2026, thắng khi trùng đoạn)
    std::string_view values_xjl{};      // server/item_segment_values_xjl.tsv (import_item.py; thắng bản 0859602)
    std::string_view values_server{};   // server/item_segment_values.tsv (0859602, thấp nhất)
    std::string_view affects{};         // server/item_segment_distributions_xjl.tsv (hoặc bản 0859602 khi chưa nhập)
    std::string_view quality_rules{};   // server/item_segment_quality_rules_xjl.tsv (hoặc bản 0859602)
    std::string_view apt_rates{};       // shared/item_aptitude_rates.tsv
};

struct RollLoader;

class RollTables {
public:
    [[nodiscard]] static std::expected<RollTables, std::string> load(const RollSources& sources);

    // Điền attrs, attr_count, aptitude của `out` (đã đặt tmpl) cho một trang bị. Trang bị không sinh ngẫu nhiên
    // (seg_rule 0, hay không trọng số) giữ nguyên các trường ấy. Tất định theo trạng thái của `dice`.
    // `context.forge_level` ngoài 0..8 coi như 8 (nơi gọi đã kiểm; hàm không được làm hỏng bộ nhớ vì đầu vào xấu).
    void roll(const Template& tmpl, const Catalog& catalog, const RollContext& context, dice::Dice& dice,
        Instance& out) const;

    // Id dòng ItemSegAffect mà `rule` (dòng ItemSegQuality) chỉ cho nguồn `context` ở điểm lắp `point`; nullopt khi
    // không có dòng luật, hay ô là -1. Rèn: ô tách theo điểm lắp thắng ô gộp; ô tách -1 thì lấy ô gộp.
    [[nodiscard]] std::optional<std::uint32_t> affect_for(std::uint32_t rule, const RollContext& context,
        std::uint8_t point) const noexcept;

    // Chín trọng số phẩm chất của một dòng ItemSegAffect; nullopt khi không có dòng.
    [[nodiscard]] std::optional<std::array<std::uint32_t, 9>> tier_weights(std::uint32_t affect) const noexcept;

    // Giá trị ItemSegValue sau khi lùi đoạn như bước 4; nullopt khi không có.
    [[nodiscard]] std::optional<std::int32_t> segment_value(std::uint32_t segment, AttrId attr) const noexcept;

    // Phần trăm cộng của tư chất `apt` (1..255) cho thuộc tính nền `base_attr` (id 58..63); 0 khi không có.
    [[nodiscard]] std::uint32_t aptitude_percent(std::uint32_t apt, AttrId base_attr) const noexcept;

    [[nodiscard]] std::size_t segment_count() const noexcept { return segment_ids_.size(); }

private:
    static constexpr std::size_t kValueColumns = 64;
    static constexpr std::size_t kBuckets = 9;

    std::vector<std::uint32_t> segment_ids_;                           // tăng dần
    std::vector<std::array<std::int32_t, kValueColumns>> segment_values_;  // song song với segment_ids_
    std::vector<std::uint32_t> affect_ids_;                            // tăng dần
    std::vector<std::array<std::uint32_t, kBuckets>> affect_weights_;
    std::vector<std::uint32_t> rule_ids_;                              // tăng dần
    std::vector<std::vector<std::int32_t>> rule_columns_;
    std::vector<std::array<std::uint16_t, kBaseAttrCount>> apt_;       // chỉ số = tư chất - 1

    friend struct RollLoader;
    [[nodiscard]] std::uint32_t pick_offset(std::optional<std::uint32_t> affect, dice::Dice& dice) const noexcept;
};

} // namespace game::item
