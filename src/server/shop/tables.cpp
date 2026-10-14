// Bảng cửa hàng: xem tables.hpp.
#include "shop/tables.hpp"

#include "item/catalog.hpp"
#include "item/rows.hpp"
#include "item/types.hpp"
#include "shop/types.hpp"

#include "ids/ids.hpp"

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <expected>
#include <functional>
#include <limits>
#include <map>
#include <optional>
#include <set>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace game::shop {

using Fail = std::unexpected<std::string>;
using Loaded = std::expected<void, std::string>;

namespace {

using item::tsv::Bounds;
using item::tsv::Cells;
using item::tsv::Rows;

constexpr std::int64_t kMaxI32 = std::numeric_limits<std::int32_t>::max();
constexpr std::int64_t kMaxU32 = std::numeric_limits<std::uint32_t>::max();
constexpr std::int64_t kMaxU16 = std::numeric_limits<std::uint16_t>::max();
constexpr std::int64_t kMaxPermille = 1'000'000'000;  // 1.000.000,0 lần: trần của hệ số phí sửa
constexpr std::int64_t kMaxScalePermille = 100'000;    // hệ số giá cửa hàng tối đa 100,0
constexpr std::int64_t kMaxOdds = 1'000'000;
constexpr std::int64_t kMaxDiscount = 1000;
constexpr std::size_t kFirstBlockColumn = 29;  // cột mã vật phẩm của khối hàng đầu tiên trong ShopTable.txt
constexpr std::size_t kBlockWidth = 6;         // mã, PNUM, PMAX, giá, chiết khấu, màu
constexpr std::int64_t kFirstCurrency = 1;
constexpr std::int64_t kLastCurrency = 16;

// 14 cột đầu của shops.tsv, theo thứ tự.
constexpr std::array<std::string_view, 14> kShopHeader{"index", "repair_level", "buy_level", "repair_type", "buy_kind",
    "repair_cost", "repair_success_rate", "currency_kind", "can_buy_back", "scale", "time", "column_11", "is_random_shop",
    "random_shop_config_path"};

// Tên tệp RandShop/*.ini (không đuôi) -> khoá shop_key trong random_shop_goods.tsv (docs/SERVER-TEP-CAU-HINH.md mục 6).
struct StemKey {
    std::string_view stem;
    std::string_view key;
};
constexpr std::array<StemKey, 15> kStemKeys{{
    {.stem = "60wufang", .key = "workshop_60"},
    {.stem = "70wufang", .key = "workshop_70"},
    {.stem = "80wufang", .key = "workshop_80"},
    {.stem = "90wufang", .key = "workshop_90"},
    {.stem = "100wufang", .key = "workshop_100"},
    {.stem = "dazaotu", .key = "blueprints"},
    {.stem = "randgemshop", .key = "gems"},
    {.stem = "huanglong_randgemshop", .key = "gems_huanglong"},
    {.stem = "miaojiang_randgemshop", .key = "gems_miaojiang"},
    {.stem = "qiongzhou_randgemshop", .key = "gems_qiongzhou"},
    {.stem = "shuhe_randgemshop", .key = "gems_shuhe"},
    {.stem = "petskillshop", .key = "pet_skills"},
    {.stem = "shanedian", .key = "morality"},
    {.stem = "shide", .key = "mentor_virtue"},
    {.stem = "xunluozawu", .key = "patrol_sundries"},
}};

[[nodiscard]] std::string_view trim(std::string_view text) noexcept {
    constexpr std::string_view kBlank = " \t\r";
    const std::size_t first = text.find_first_not_of(kBlank);
    if (first == std::string_view::npos) return {};
    return text.substr(first, text.find_last_not_of(kBlank) - first + 1);
}

[[nodiscard]] bool is_digit(char c) noexcept { return c >= '0' && c <= '9'; }

// "1" -> 1000, "0.5" -> 500, "1.25" -> 1250, "0.00184" -> 2 (làm tròn nửa lên); nullopt khi không phải số thập phân không âm
// hay vượt kMaxPermille. Giá trị float của bảng là số tròn đến hai chữ số thập phân; phép làm tròn chỉ để không mất gì thầm.
[[nodiscard]] std::optional<std::int64_t> permille_of(std::string_view text) noexcept {
    text = trim(text);
    constexpr std::int64_t kBase = 10;
    constexpr std::size_t kPlaces = 3;
    std::int64_t whole = 0;
    std::size_t at = 0;
    for (; at < text.size() && is_digit(text[at]); ++at) {
        whole = (whole * kBase) + (text[at] - '0');
        if (whole > kMaxPermille) return std::nullopt;
    }
    if (at == 0) return std::nullopt;
    std::int64_t fraction = 0;
    std::size_t taken = 0;
    bool round_up = false;
    if (at < text.size()) {
        if (text[at] != '.' || at + 1 == text.size()) return std::nullopt;
        for (++at; at < text.size(); ++at) {
            if (!is_digit(text[at])) return std::nullopt;
            const int digit = text[at] - '0';
            if (taken < kPlaces) {
                fraction = (fraction * kBase) + digit;
                ++taken;
            } else if (taken == kPlaces) {
                round_up = digit >= 5;
                ++taken;
            }
        }
    }
    for (std::size_t places = std::min(taken, kPlaces); places < kPlaces; ++places) fraction *= kBase;
    const std::int64_t total = (whole * 1000) + fraction + (round_up ? 1 : 0);
    if (total > kMaxPermille) return std::nullopt;
    return total;
}

// Ô thập phân thành phần nghìn trong [low, high]; lỗi thì nhớ vào cells và trả low.
[[nodiscard]] std::int64_t decimal(Cells& cells, std::size_t col, Bounds bounds) {
    const std::optional<std::int64_t> value = permille_of(cells.text(col));
    if (!value || *value < bounds.first || *value > bounds.second) {
        cells.fail(col, "không phải số thập phân trong " + std::to_string(bounds.first) + ".." + std::to_string(bounds.second)
                + " phần nghìn");
        return bounds.first;
    }
    return *value;
}

// Ô số nguyên có thể thừa dấu cách (RandShop/*.ini viết "2  "); ô rỗng trả `fallback`.
[[nodiscard]] std::int64_t padded_integer(Cells& cells, std::size_t col, Bounds bounds, std::int64_t fallback) {
    const std::string_view text = trim(cells.text(col));
    if (text.empty()) return fallback;
    const std::optional<std::int64_t> value = item::tsv::to_int(text);
    if (!value || *value < bounds.first || *value > bounds.second) {
        cells.fail(col, "không phải số nguyên trong " + std::to_string(bounds.first) + ".." + std::to_string(bounds.second));
        return fallback;
    }
    return *value;
}

// NPC_SHOP_TYPE của 2008 cho giá trị 1..7. Hai điều suy ra từ dữ liệu 2026 chứ không có ở nguồn nào:
//  - buy_kind 9 là "thu mua mọi thứ" (160 trên 169 cửa hàng loại 9 có buy_level 120 và can_buy_back 1);
//  - buy_kind 8 là "không thu mua" (206 trên 214 cửa hàng loại 8 có buy_level 0). 2008 cũng cho giá trị lạ vào nhánh default,
//    tức không nhận gì, nên 8 và mọi giá trị lạ khác cho cùng kết quả.
// Sửa đồ chỉ có 1 trong dữ liệu; 2008 chỉ biết 1..4 cho sửa.
[[nodiscard]] Scope scope_of(std::int64_t raw, bool repair) noexcept {
    switch (raw) {
    case 1: return Scope::kAll;
    case 2: return Scope::kDefence;
    case 3: return Scope::kAdorn;
    case 4: return Scope::kWeapon;
    case 5: return repair ? Scope::kNone : Scope::kFood;
    case 6: return repair ? Scope::kNone : Scope::kMaterial;
    case 7: return repair ? Scope::kNone : Scope::kMedicine;
    case 9: return repair ? Scope::kNone : Scope::kAll;
    default: return Scope::kNone;
    }
}

[[nodiscard]] std::optional<std::string_view> stem_key(std::string_view path) noexcept {
    const std::size_t slash = path.find_last_of("/\\");
    std::string_view name = slash == std::string_view::npos ? path : path.substr(slash + 1);
    constexpr std::string_view kExtension = ".ini";
    if (name.ends_with(kExtension)) name.remove_suffix(kExtension.size());
    for (const StemKey& entry : kStemKeys) {
        if (entry.stem == name) return entry.key;
    }
    return std::nullopt;
}

} // namespace

// Bộ nạp: friend của ShopTables để ghi thẳng vào thành viên.
struct ShopLoader {
    using PoolRanges = std::map<std::string, std::pair<std::uint32_t, std::uint16_t>, std::less<>>;

    static Loaded read_pool(ShopTables& out, PoolRanges& ranges, std::string_view text, const item::Catalog& catalog);
    static Loaded read_shops(ShopTables& out, const PoolRanges& ranges, std::string_view text, const item::Catalog& catalog);
    static Loaded read_scenes(ShopTables& out, std::string_view text);
    static Loaded read_junk(ShopTables& out, std::string_view text, const item::Catalog& catalog);
};

Loaded ShopLoader::read_pool(ShopTables& out, PoolRanges& ranges, std::string_view text, const item::Catalog& catalog) {
    Rows rows(text);
    if (rows.error()) return Fail("random_shop_goods: " + *rows.error());
    constexpr std::size_t kColumns = 10;
    if (rows.column_count() != kColumns || rows.name(0) != "shop_key" || rows.name(2) != "id" || rows.name(9) != "within_declared_count") {
        return Fail("random_shop_goods: bố cục cột không phải shop_key, merchandise_id, id, count, count_per_unit, odds_1, odds_2, "
                    "value, rebate, within_declared_count");
    }
    std::map<std::string, std::vector<PoolEntry>, std::less<>> grouped;
    Cells cells(rows, "random_shop_goods");
    while (rows.next()) {
        const std::string key(cells.text(0));
        const std::int64_t item = padded_integer(cells, 2, Bounds{1, kMaxI32}, -1);
        const std::int64_t units = padded_integer(cells, 3, Bounds{1, kMaxI32}, 1);
        const std::int64_t per_unit = padded_integer(cells, 4, Bounds{1, kMaxI32}, 1);
        // Hai cột odds là hai cách viết `Odds`/`odds` của tệp ini gốc; mỗi dòng chỉ có một.
        const std::int64_t odds_a = padded_integer(cells, 5, Bounds{1, kMaxOdds}, 0);
        const std::int64_t odds_b = padded_integer(cells, 6, Bounds{1, kMaxOdds}, 0);
        const std::int64_t value = padded_integer(cells, 7, Bounds{0, kMaxI32}, 0);
        const std::int64_t rebate = padded_integer(cells, 8, Bounds{1, kMaxDiscount}, kPercent);
        const std::int64_t declared = padded_integer(cells, 9, Bounds{0, 1}, 1);
        if (cells.error()) return Fail(*cells.error());
        if (key.empty()) return Fail("random_shop_goods:" + std::to_string(rows.line()) + ": thiếu shop_key");
        if (declared == 0) continue;  // ngoài Total của tệp ini gốc: bộ đọc gốc không nạp dòng này
        if (odds_a == 0 && odds_b == 0) return Fail("random_shop_goods:" + std::to_string(rows.line()) + ": thiếu odds");
        const item::TemplateId id{static_cast<std::uint32_t>(item)};
        if (catalog.find(id) == nullptr) {
            ++out.diagnostics_.unknown_pool_items;
            continue;
        }
        std::vector<PoolEntry>& entries = grouped[key];
        if (entries.size() >= kMaxPool) return Fail("random_shop_goods: kho " + key + " quá " + std::to_string(kMaxPool) + " mục");
        entries.push_back(PoolEntry{.goods = Goods{.item = id,
                                        .group = static_cast<std::uint16_t>(std::min<std::int64_t>(per_unit, kMaxGroupSize)),
                                        .capacity = static_cast<std::int32_t>(units),
                                        .listed_price = value,
                                        .discount_percent = static_cast<std::uint16_t>(rebate)},
            .odds = static_cast<std::uint32_t>(odds_a != 0 ? odds_a : odds_b)});
    }
    if (rows.error()) return Fail("random_shop_goods: " + *rows.error());
    for (auto& [key, entries] : grouped) {
        ranges.emplace(key, std::pair{static_cast<std::uint32_t>(out.pool_.size()), static_cast<std::uint16_t>(entries.size())});
        out.pool_.insert(out.pool_.end(), entries.begin(), entries.end());
    }
    return {};
}

Loaded ShopLoader::read_shops(ShopTables& out, const PoolRanges& ranges, std::string_view text, const item::Catalog& catalog) {
    Rows rows(text);
    if (rows.error()) return Fail("shops: " + *rows.error());
    const std::size_t columns = rows.column_count();
    for (std::size_t col = 0; col < kShopHeader.size(); ++col) {
        if (rows.name(col) != kShopHeader.at(col)) {
            return Fail("shops: cột " + std::to_string(col) + " phải tên " + std::string(kShopHeader.at(col)) + ", thấy '"
                + std::string(rows.name(col)) + "'");
        }
    }
    if (columns < kFirstBlockColumn || (columns - kFirstBlockColumn) % kBlockWidth != 0) {
        return Fail("shops: số cột " + std::to_string(columns) + " không phải 29 + 6 * số khối hàng");
    }
    const std::size_t blocks = (columns - kFirstBlockColumn) / kBlockWidth;
    Cells cells(rows, "shops");
    while (rows.next()) {
        ShopDef shop;
        shop.id = ShopId{static_cast<std::uint32_t>(cells.integer(0, Bounds{1, kMaxU32}))};
        shop.repair_level = static_cast<std::uint16_t>(cells.integer(1, Bounds{0, kMaxU16}));
        shop.buy_level = static_cast<std::uint16_t>(cells.integer(2, Bounds{0, kMaxU16}));
        shop.repair_scope = scope_of(cells.integer(3, Bounds{0, kMaxU16}), true);
        shop.buy_scope = scope_of(cells.integer(4, Bounds{0, kMaxU16}), false);
        shop.repair_permille = static_cast<std::uint32_t>(decimal(cells, 5, Bounds{0, kMaxPermille}));
        constexpr std::int64_t kFullRate = 1000;
        if (decimal(cells, 6, Bounds{0, kMaxPermille}) != kFullRate) ++out.diagnostics_.repair_rate_not_one;
        shop.currency = static_cast<item::Currency>(cells.integer(7, Bounds{kFirstCurrency, kLastCurrency}));
        shop.can_buy_back = cells.integer(8, Bounds{0, 1}) != 0;
        shop.scale_permille = static_cast<std::uint32_t>(decimal(cells, 9, Bounds{1, kMaxScalePermille}));
        shop.refresh_ms = static_cast<std::uint32_t>(cells.integer(10, Bounds{0, kMaxI32}));
        const std::int64_t capacity = cells.integer(11, Bounds{0, static_cast<std::int64_t>(kMaxGoods)});
        shop.random = cells.integer(12, Bounds{0, 1}) != 0;
        if (cells.error()) return Fail(*cells.error());

        if (shop.random) {
            const std::optional<std::string_view> key = stem_key(cells.text(13));
            if (!key) {
                return Fail("shops:" + std::to_string(rows.line()) + ": cửa hàng " + std::to_string(shop.id.value())
                    + " ngẫu nhiên nhưng đường dẫn '" + std::string(cells.text(13)) + "' không có kho tương ứng");
            }
            const auto range = ranges.find(*key);
            if (range == ranges.end()) {
                return Fail("shops:" + std::to_string(rows.line()) + ": cửa hàng " + std::to_string(shop.id.value()) + " cần kho '"
                    + std::string(*key) + "' mà random_shop_goods không có dòng nào");
            }
            shop.pool_begin = range->second.first;
            shop.pool_count = range->second.second;
            shop.pick_count = static_cast<std::uint16_t>(capacity);
        } else {
            shop.goods_begin = static_cast<std::uint32_t>(out.goods_.size());
            // 2008 đọc tối đa Num khối và dừng ở mã 0 đầu tiên; các mã ngoài catalog chiếm chỗ trong khối nhưng bị bỏ.
            const std::size_t scan = std::min<std::size_t>(blocks, static_cast<std::size_t>(capacity));
            for (std::size_t block = 0; block < scan; ++block) {
                const std::size_t base = kFirstBlockColumn + (block * kBlockWidth);
                const std::string_view code = trim(cells.text(base));
                if (code.empty()) break;
                const std::int64_t id = cells.integer(base, Bounds{-1, kMaxI32});
                if (cells.error()) return Fail(*cells.error());
                if (id <= 0) break;
                const std::int64_t group = cells.optional_integer(base + 1, Bounds{-1, kMaxI32}, 1);
                const std::int64_t stock = cells.optional_integer(base + 2, Bounds{-1, kMaxI32}, kUnlimited);
                const std::int64_t price = cells.optional_integer(base + 3, Bounds{-1, kMaxI32}, 0);
                const std::int64_t discount = cells.optional_integer(base + 4, Bounds{1, kMaxDiscount}, kPercent);
                if (cells.error()) return Fail(*cells.error());
                const item::TemplateId item{static_cast<std::uint32_t>(id)};
                if (catalog.find(item) == nullptr) {
                    ++out.diagnostics_.unknown_goods;
                    continue;
                }
                out.goods_.push_back(Goods{.item = item,
                    .group = static_cast<std::uint16_t>(std::clamp<std::int64_t>(group, 1, kMaxGroupSize)),
                    .capacity = stock > 0 ? static_cast<std::int32_t>(stock) : kUnlimited,
                    .listed_price = std::max<std::int64_t>(price, 0),
                    .discount_percent = static_cast<std::uint16_t>(discount)});
            }
            shop.goods_count = static_cast<std::uint16_t>(out.goods_.size() - shop.goods_begin);
        }
        out.shops_.push_back(shop);
    }
    if (rows.error()) return Fail("shops: " + *rows.error());
    std::ranges::sort(out.shops_, {}, &ShopDef::id);
    const auto dup = std::ranges::adjacent_find(out.shops_, {}, &ShopDef::id);
    if (dup != out.shops_.end()) return Fail("shops: cửa hàng " + std::to_string(dup->id.value()) + " xuất hiện hai lần");
    return {};
}

Loaded ShopLoader::read_scenes(ShopTables& out, std::string_view text) {
    Rows rows(text);
    if (rows.error()) return Fail("shop_scene_limits: " + *rows.error());
    if (rows.column_count() < 2 || rows.name(0) != "index") return Fail("shop_scene_limits: cột đầu phải là index và có ít nhất một cột cảnh");
    Cells cells(rows, "shop_scene_limits");
    std::set<ShopId> seen;
    std::vector<std::uint16_t> scenes;
    while (rows.next()) {
        const ShopId id{static_cast<std::uint32_t>(cells.integer(0, Bounds{1, kMaxU32}))};
        scenes.clear();
        for (std::size_t col = 1; col < rows.column_count(); ++col) {
            const std::int64_t scene = cells.optional_integer(col, Bounds{0, kMaxU16}, -1);
            if (scene >= 0) scenes.push_back(static_cast<std::uint16_t>(scene));
        }
        if (cells.error()) return Fail(*cells.error());
        if (!seen.insert(id).second) {
            return Fail("shop_scene_limits:" + std::to_string(rows.line()) + ": cửa hàng " + std::to_string(id.value()) + " có hai dòng");
        }
        const auto shop = std::ranges::lower_bound(out.shops_, id, {}, &ShopDef::id);
        if (shop == out.shops_.end() || shop->id != id) {
            ++out.diagnostics_.scene_rows_without_shop;
            continue;
        }
        std::ranges::sort(scenes);
        scenes.erase(std::ranges::unique(scenes).begin(), scenes.end());
        shop->scene_begin = static_cast<std::uint32_t>(out.scenes_.size());
        shop->scene_count = static_cast<std::uint16_t>(scenes.size());
        shop->scene_limited = !scenes.empty();
        out.scenes_.insert(out.scenes_.end(), scenes.begin(), scenes.end());
    }
    if (rows.error()) return Fail("shop_scene_limits: " + *rows.error());
    return {};
}

Loaded ShopLoader::read_junk(ShopTables& out, std::string_view text, const item::Catalog& catalog) {
    Rows rows(text);
    if (rows.error()) return Fail("junk_recycle: " + *rows.error());
    constexpr std::size_t kColumns = 4;
    if (rows.column_count() != kColumns) return Fail("junk_recycle: phải có 4 cột (số thứ tự, mã vật phẩm, loại, giá)");
    Cells cells(rows, "junk_recycle");
    while (rows.next()) {
        const std::int64_t id = cells.integer(1, Bounds{1, kMaxI32});
        const std::int64_t value = cells.integer(3, Bounds{0, kMaxI32});
        if (cells.error()) return Fail(*cells.error());
        const item::TemplateId item{static_cast<std::uint32_t>(id)};
        if (catalog.find(item) == nullptr) {
            ++out.diagnostics_.unknown_junk_items;
            continue;
        }
        out.junk_.emplace_back(item, value);
    }
    if (rows.error()) return Fail("junk_recycle: " + *rows.error());
    std::ranges::sort(out.junk_, {}, &std::pair<item::TemplateId, std::int64_t>::first);
    const auto dup = std::ranges::adjacent_find(out.junk_, {}, &std::pair<item::TemplateId, std::int64_t>::first);
    if (dup != out.junk_.end()) return Fail("junk_recycle: vật phẩm " + std::to_string(dup->first.value()) + " xuất hiện hai lần");
    return {};
}

std::expected<ShopTables, std::string> ShopTables::load(const ShopSources& sources, const item::Catalog& catalog) {
    if (sources.shops.empty()) return Fail("thiếu bảng shops");
    ShopTables out;
    ShopLoader::PoolRanges ranges;
    if (!sources.random_goods.empty()) {
        if (auto done = ShopLoader::read_pool(out, ranges, sources.random_goods, catalog); !done) return Fail(done.error());
    }
    if (auto done = ShopLoader::read_shops(out, ranges, sources.shops, catalog); !done) return Fail(done.error());
    if (!sources.scene_limits.empty()) {
        if (auto done = ShopLoader::read_scenes(out, sources.scene_limits); !done) return Fail(done.error());
    }
    if (!sources.junk_recycle.empty()) {
        if (auto done = ShopLoader::read_junk(out, sources.junk_recycle, catalog); !done) return Fail(done.error());
    }
    return out;
}

const ShopDef* ShopTables::find(ShopId id) const noexcept {
    const auto at = std::ranges::lower_bound(shops_, id, {}, &ShopDef::id);
    return at != shops_.end() && at->id == id ? &*at : nullptr;
}

std::span<const Goods> ShopTables::goods(const ShopDef& shop) const noexcept {
    return std::span<const Goods>(goods_).subspan(shop.goods_begin, shop.goods_count);
}

std::span<const PoolEntry> ShopTables::pool(const ShopDef& shop) const noexcept {
    return std::span<const PoolEntry>(pool_).subspan(shop.pool_begin, shop.pool_count);
}

bool ShopTables::allowed_in(const ShopDef& shop, ids::SceneId scene) const noexcept {
    if (!shop.scene_limited) return true;
    const std::span<const std::uint16_t> list = std::span<const std::uint16_t>(scenes_).subspan(shop.scene_begin, shop.scene_count);
    return std::ranges::binary_search(list, scene.value());
}

std::optional<std::int64_t> ShopTables::junk_value(item::TemplateId item) const noexcept {
    const auto at = std::ranges::lower_bound(junk_, item, {}, &std::pair<item::TemplateId, std::int64_t>::first);
    if (at == junk_.end() || at->first != item) return std::nullopt;
    return at->second;
}

} // namespace game::shop
