#pragma once
// Bảng rơi đồ đã nạp và kiểm chéo: gói rơi (DropBoxContent), bảng rơi của quái (MonsterDropBoxs), hệ số chênh cấp
// (DropAttenuation), bảng xác suất riêng của vật phẩm (DropRateOfItemTable) và các hộp rút thăm (boxdroplist*).
//
// Nguồn: loader InitDropBoxTable, InitMonsterDropBoxTable, InitDropAttTable của ItemTable.cpp (2008) cho cột và thứ tự tra;
// tệp XJL7457 (bản 3.71) mở rộng bố cục: DropBoxContent có thêm hai cột trước các cặp (cột 2 là loại phát thanh trỏ
// DropNotify.txt, cột 3 là cờ ép khoá), 256 cặp (vật phẩm, cấp) thay vì 100 cặp bắt đầu từ cột 2. Cặp bắt đầu ở cột 4: đo
// trên bảng thật, cột 2 và 3 không bao giờ là mã vật phẩm còn cột 4 luôn là mã vật phẩm. Cột "cấp" của cặp chỉ gặp ở trang
// bị với giá trị 1..6: đọc là nguồn sinh đồ cho ItemSegQuality (xem Origin ở item/roll.hpp), đoán theo cấu trúc bảng chứ chưa
// được client hay máy chủ gốc xác nhận (docs/SERVER-ITEM.md, mục Giả định).
//
// Hợp đồng nạp: lỗi bảng (cột lạ, số ngoài miền, id trùng, quái trỏ gói không có, ô trống chen giữa gói) trả câu lỗi tiếng
// Việt kèm bảng và dòng, không dựng gì một nửa. Mục vật phẩm không có trong catalog (id của máy chủ gốc mà client 2026 không
// biết) KHÔNG làm hỏng bảng: bị bỏ và đếm ở diagnostics(), vì 2008 dừng bằng Assert ở chỗ này còn bản này phải chạy tiếp.

#include "item/catalog.hpp"
#include "item/types.hpp"
#include "loot/types.hpp"

#include "dice/dice.hpp"
#include "ids/ids.hpp"

#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::loot {

// Nội dung các bảng; văn bản phải sống tới hết lời gọi LootTables::load. Hai bảng cuối được để trống.
struct LootSources {
    std::string_view packs{};       // drop_packages.tsv (bắt buộc)
    std::string_view monsters{};    // monster_drops.tsv (bắt buộc)
    std::string_view level_gaps{};  // drop_level_gap_factors.tsv (bắt buộc)
    std::string_view rate_items{};  // item_drop_rates.tsv
    std::string_view boxes{};       // loot_box_entries.tsv
};

inline constexpr std::int8_t kInheritOrigin = -1;  // ô cấp để trống: nguồn sinh đồ lấy theo hạng của quái

struct PackEntry {
    item::TemplateId item;
    std::int8_t origin = kInheritOrigin;  // 0..6 theo item::Origin, hoặc kInheritOrigin
};

struct Pack {
    PackId id;
    std::int64_t value = 1;        // box_value: mẫu số của xác suất rơi
    std::int32_t broadcast = -1;   // loại phát thanh trong DropNotify.txt, -1 là không phát
    bool force_bind = false;       // đồ rơi ra bị khoá ngay
    std::uint32_t begin = 0;       // đoạn trong kho mục của bảng
    std::uint16_t count = 0;       // số mục còn lại sau khi bỏ mục lạ
};

struct MonsterDrop {
    ids::MonsterTemplateId monster;
    std::int64_t value = 0;        // mvalue: tử số của xác suất rơi
    Ruler ruler = Ruler::kCommon;
    std::uint8_t pack_count = 0;
    std::array<PackId, kMaxPacksPerMonster> packs{};
};

// Kết quả rút thăm một vật phẩm từ bảng xác suất riêng hay từ một hộp.
struct Pick {
    item::TemplateId item;
    bool announce = false;  // sends_message / notice của dòng: máy chủ phát thanh khi rơi
};

// Những gì bảng có mà không dùng được, để người soạn bảng thấy; khác 0 không phải lỗi.
struct Diagnostics {
    std::size_t unknown_pack_items = 0;
    std::size_t empty_packs = 0;  // gói không còn mục nào dùng được (kể cả gói trống từ bảng gốc)
    std::size_t unknown_rate_items = 0;
    std::size_t unknown_box_items = 0;
    std::vector<std::string> samples;  // vài mục lạ đầu tiên
};

class LootTables {
public:
    [[nodiscard]] static std::expected<LootTables, std::string> load(const LootSources& sources,
        const item::Catalog& catalog);

    // Dòng rơi của một loại quái; nullptr khi quái không có bảng (không rơi gì). O(log n).
    [[nodiscard]] const MonsterDrop* monster(ids::MonsterTemplateId id) const noexcept;
    [[nodiscard]] const Pack* pack(PackId id) const noexcept;
    [[nodiscard]] std::span<const PackEntry> entries(const Pack& pack) const noexcept;

    // Hệ số chênh cấp (cấp quái trừ cấp người) theo phần triệu; 1'000'000 khi chênh lệch ngoài bảng (2008 giữ hệ số 1,0).
    [[nodiscard]] std::uint32_t gap_ppm(std::int64_t level_delta) const noexcept;

    // Rút một vật phẩm theo trọng số drop_chance (bảng DropRateOfItemTable, hàm Lua GetItemSnByDropRateOfItemTable của XJL
    // trả về mã vật phẩm và cờ phát thanh). nullopt khi bảng trống hay mọi trọng số bằng 0.
    [[nodiscard]] std::optional<Pick> pick_rate_item(dice::Dice& dice) const noexcept;

    // Rút một vật phẩm từ hộp `key` ("default", "gacha_7", ...) theo trọng số rate. nullopt khi hộp không có.
    [[nodiscard]] std::optional<Pick> pick_box(std::string_view key, dice::Dice& dice) const noexcept;

    [[nodiscard]] bool has_box(std::string_view key) const noexcept;
    [[nodiscard]] std::size_t pack_count() const noexcept { return packs_.size(); }
    [[nodiscard]] std::size_t monster_count() const noexcept { return monsters_.size(); }
    [[nodiscard]] std::size_t box_count() const noexcept { return boxes_.size(); }
    [[nodiscard]] const Diagnostics& diagnostics() const noexcept { return diagnostics_; }

private:
    friend struct LootLoader;

    struct BoxRange {
        std::string key;
        std::uint32_t begin = 0;
        std::uint32_t count = 0;
    };

    std::vector<Pack> packs_;                   // tăng theo id
    std::vector<PackEntry> pack_entries_;
    std::vector<MonsterDrop> monsters_;         // tăng theo mã quái
    std::vector<std::pair<std::int64_t, std::uint32_t>> gaps_;  // (chênh cấp, ppm) tăng theo chênh cấp
    std::vector<Pick> rate_items_;
    std::vector<std::uint32_t> rate_weights_;
    std::vector<BoxRange> boxes_;               // tăng theo khoá
    std::vector<Pick> box_items_;
    std::vector<std::uint32_t> box_weights_;
    Diagnostics diagnostics_;
};

} // namespace game::loot
