# Vật phẩm, rơi đồ, cửa hàng, lò rèn của máy chủ

Đọc tài liệu này là đủ để nối bốn module vào zone mà không cần mở mã. Mọi thứ ở đây là lõi thuần: không mạng, không database,
không đồng hồ thật, không `<random>` (dùng `dice::Dice` do nơi gọi đưa vào), không `throw`. Thời gian là `ids::Tick` (20 tick/giây,
`item::kTicksPerSecond`). Mã ở `src/server/{item,loot,shop,forge}/`, test ở `Test/{Item,Loot,Shop,Forge}/`, công cụ nhập bảng ở
`TOOLS/server/import_item.py`.

## 1. Bản đồ

| Module | Việc | Phụ thuộc |
|---|---|---|
| `item` | catalog mẫu vật phẩm, túi/kho/trang bị/ví (`Inventory`), dựng kế hoạch (`Planner`), sinh vật phẩm (`Factory`, `RollTables`), giá bán và phí sửa, tổng thuộc tính trang bị, bản ghi nhị phân có phiên bản | core ids dice protocol |
| `loot` | bảng rơi, cuộn đồ khi quái chết, chia hộp cho người có quyền, hộp rơi trên đất và việc nhặt, rút thăm từ hộp/bảng xác suất riêng | item |
| `shop` | bảng cửa hàng NPC, cửa hàng đang chạy của một NPC (tồn kho, làm mới), mua, bán, mua lại, sửa, thu hồi phế phẩm | item |
| `forge` | công thức nung ngọc, chạm ngọc, nâng cấp siêu vũ khí và việc chế biến | item |

Bảng tầng ở `cmake/GameLayers.cmake`: `item` không biết `loot`, `shop`, `forge`; ba module kia không biết nhau.

## 2. Nguyên tắc chung (đọc trước khi nối)

**Kế hoạch rồi áp dụng.** Không hàm nghiệp vụ nào ghi vào `Inventory`. `Planner` đọc `Inventory`, ghi vào lớp phủ của chính nó,
`std::move(planner).finish()` ra một `Plan` (danh sách thay đổi tuyệt đối có kiểu: ô nào sau kế hoạch là gì, ví nào từ số dư nào
sang số dư nào), `Inventory::apply(plan)` kiểm TẤT CẢ (revision, biên, trùng ô, số dư, trần) rồi mới gán; lỗi thì không đổi một byte.
`Plan` cũng là thứ zone gửi cho client (ghi đè ô, không "thêm/bớt" nên không cộng lệch).

**Mọi thao tác nhiều bước là nguyên tử trên Planner.** Mọi `plan_*` của `shop` và `forge`, và `plan_pick` của `loot`: lỗi thì Planner
giữ nguyên trạng thái trước lời gọi (cài bằng `Planner trial = planner; ... planner = std::move(trial);`, vì Planner không có
hoàn tác). Nên một lượt chơi gồm "mua, rồi bán, rồi chế" dựng liên tiếp trên cùng một Planner được, bước hỏng không làm hỏng bước trước.

**Bước hai của thứ nằm ngoài Inventory.** Tồn kho cửa hàng, hộp rơi trên đất, danh sách mua lại không nằm trong `Inventory`, nên
chúng là thao tác hai pha: `plan_*` ra một phiếu (`BuyTicket`, `PickTicket`, `SellTicket`, `BuyBackTicket`), nơi gọi áp dụng Plan
của túi, và CHỈ khi áp dụng thành công mới đưa phiếu cho `NpcShop::commit`, `loot::take`, `SoldList::remember/take`. Phiếu mang
revision hay serial nên thứ đã đổi ở giữa thì bước hai từ chối (`kStalePlan`).

**Tính tất định.** Cùng seed của `Dice`, cùng bảng, cùng chuỗi lời gọi cho cùng kết quả. Không nơi nào phụ thuộc thứ tự `unordered_*`
hay đồng hồ.

**Đầu vào thù địch.** Chỉ số ô, số lượng, mã vật phẩm, khối nhị phân từ client/store đều được kiểm biên và trả `item::Error`, không
bao giờ vào `check`/`assert`/`.at()`.

**Một bảng lỗi chung** `item::Error` (`item/types.hpp`), chỉ nối thêm ở cuối: `kUnknownTemplate` … `kBadOrigin`, rồi `kNotOwner`,
`kBoxExpired`, `kNoSuchEntry` (loot), `kSoldOut`, `kShopRefuses`, `kWrongScene` (shop). `describe(Error)` ra câu tiếng Việt.

## 3. `item`

### 3.1 Bảng đọc

Văn bản bảng phải sống tới hết lời gọi `load`. Thứ bậc nguồn của dự án: client 2026 > XJL7457 > 0859602; bảng nhập từ XJL7457 có
hậu tố `_xjl` khi đã có bảng cùng tên từ 0859602, và bộ nạp đọc bản `_xjl` trước.

| Bộ nạp | Tệp trong `dev/server/tables` |
|---|---|
| `Catalog::load` | `shared/item_rules.tsv` (bắt buộc), `items_common.tsv`, `equipment.tsv`, `gems.tsv`, `pet_equipment_base.tsv`, `equipment_extra_attributes.tsv` |
| `Limits::load` | `server/item_limits.tsv`, `shared/money_caps_by_level.tsv` |
| `RollTables::load` | `values_shared`=`shared/item_segment_values.tsv`, `values_xjl`=`server/item_segment_values_xjl.tsv`, `values_server`=`server/item_segment_values.tsv`, `affects`=`server/item_segment_distributions_xjl.tsv`, `quality_rules`=`server/item_segment_quality_rules_xjl.tsv`, `apt_rates`=`shared/item_aptitude_rates.tsv` |

Bảng thật: 47 148 mẫu; 628 đoạn `ItemSegValue` sau khi hợp ba nguồn (client thắng khi trùng đoạn). `Catalog` bỏ mười id lục cũ mà
client 2026 không có (không bảng rơi hay cửa hàng nào tham chiếu).

### 3.2 Dựng trạng thái

```
Limits limits = Limits::load(...) hoặc Limits::defaults();   // cỡ túi/kho, ô mở sẵn, trần từng loại tiền
Inventory inventory(limits);                                  // ba túi, 24 điểm lắp, kho, ví
SerialAllocator serials(first, last);                         // khối serial do world cấp cho zone; hết khối là lỗi, không quay vòng
Factory factory(catalog, rolls);
```

(Đoạn trên là minh hoạ, chưa biên dịch.) `Inventory` giữ ba túi (`Place::kBaseBag`, `kMaterialBag`, `kQuestBag`), điểm lắp
(`kEquip`, chỉ số 0..23 theo `equip_point`; 11 là nhẫn thứ hai, 13 bùa hộ thân thứ hai), kho (`kBank`) và ví. Ví có một số dư cho
mỗi mã tiền `Currency` 1..16 (mã của client 2026: vàng, nguyên bảo, giao tử …) cộng vàng gửi kho (tài khoản 0); `Planner::earn/spend`
từ chối mã 0 (`kUnknownCurrency`) để mã tiền hỏng từ bảng cửa hàng không chạm được vào vàng kho. Ô có thể bị khoá
(`Inventory::set_lock`, dùng lúc giao dịch hay mở cửa hàng): Planner từ chối đụng ô khoá, `remove_count` bỏ qua ô khoá.

### 3.3 `Planner`

Dựng từ `Planner(inventory, catalog, serials)`. Mọi hàm trả `Result = expected<void, Error>`; lỗi thì lớp phủ không đổi.

| Nhóm | Hàm |
|---|---|
| Vật phẩm | `add` (túi mặc định của mẫu), `add_to` (kho), `remove_count` (theo mẫu, ba túi), `remove_at`, `move`, `split`, `merge`, `sort` |
| Trang bị | `equip` (cấp, môn phái, giới tính, giám định, khoá khi mặc), `unequip`, `identify`, `update` (thay thể hiện cùng serial), `wear_armor`, `wear_weapon` (hao mòn theo ngưỡng; ngưỡng đưa từ config `EquipmentDamagePoint`=500), `repair` |
| Tiền | `earn`, `spend`, `deposit_gold`, `withdraw_gold` |
| Đọc | `get`, `count_of`, `free_slots`, `balance`, `wallet` |

Luật chồng/tách: `add` lấp chồng cũ (cùng mẫu, cùng cờ khoá) rồi mới ô trống; số lượng vượt cỡ chồng tách thành nhiều chồng (mỗi
chồng mới một serial); `max_owned` và đồ duy nhất chặn bằng `kUniqueOwned`. Thao tác hỏng không để lại gì, kể cả khi `add` đã lấp
một phần (ví dụ 25 thuốc vào túi chỉ còn chỗ cho 20: không lấp dở).

### 3.4 `Factory` và sinh ngẫu nhiên

`Factory::create({tmpl, count, picked, now, roll}, dice, serials)` ra một `Instance`: serial mới, độ bền = tối đa, số ô đá,
`expires_at` theo `duration_hours` của mẫu, khoá ngay nếu `picked` và mẫu có cờ khoá-khi-nhặt, và (trang bị phẩm khác trắng)
thuộc tính ngẫu nhiên + tư chất qua `RollTables::roll`. Đồ chồng được có `count` trong `[1, stack_max]`, trang bị luôn 1 (ngoài ra `kBadCount`).

`RollContext{origin, forge_level}` quyết định cột `ItemSegQuality`: `Origin` 0 quái thường, 1 thủ lĩnh, 2 đầu mục, 3 rương, 4 BOSS
phó bản, 5 BOSS giờ, 6 BOSS ngày, 7 rèn (thêm `forge_level` 0..8; >8 là `kBadOrigin` ở `Factory`, `RollTables::roll` kẹp về 8).
Thuật toán năm bước (số thuộc tính → chọn theo trọng số không hoàn lại → dòng `ItemSegAffect` theo nguồn → mỗi thuộc tính quay phẩm
chất riêng và lấy giá trị `ItemSegValue` → tư chất cộng vào thuộc tính nền) mô tả trong `item/roll.hpp`; **đây là suy ra** (mục 9.1).

### 3.5 Giá, thuộc tính, mã hoá

- `sell_value(tmpl, item, rules, shop_scale_permille)`: giá NPC trả cho cả chồng. `PriceRules` mặc định 250‰ (đã giám định) và 100‰
  (đồ lam chưa giám định) bằng `dev/server/config/rules/economy.toml [price]`; nơi tích hợp truyền giá trị đọc từ config (module `item`
  không đọc TOML). Tính một phép chia cuối, làm tròn xuống.
- `repair_cost(tmpl, item, shop_repair_permille)`: phí sửa về đủ độ bền, làm tròn nửa lên. `Planner::repair` dùng nó.
- `equipment_bonuses(inventory, catalog)`: tổng thuộc tính của đồ đang mặc, gộp theo id (xếp tăng, kẹp int32); món hết độ bền không
  cho thuộc tính. Module `actor` ghép `AttrId` với chỉ số nhân vật bằng tên (`attr_name`).
- `encode_bags/equipment/bank/wallet` và `decode_*` (`item/codec.hpp`): bốn khối nhị phân, mỗi khối là khung protocol (loại
  0x7001..0x7004) + thân little-endian bắt đầu bằng số phiên bản u16 (`kCodecVersion` = 1). Bộ giải mã coi đầu vào là thù địch
  (độ dài, số phần tử, mẫu không có trong catalog, ô trùng, serial trùng, số thừa) và đọc vào bản nháp rồi mới gán nên khối hỏng
  không để lại gì; nạp cả bốn khối vào cùng một `Inventory` để bắt serial trùng chéo khối. Mỗi lần nạp lại tăng `revision`, nên Plan
  dựng trước đó không áp dụng được (`kStalePlan`).

## 4. `loot`

Công thức xác suất rơi của một gói (`ItemBoxRuler::CreateItemFromMonsterDrop`, 2008):
`p = (mvalue / box_value) × hệ số chênh cấp × DropParam × hệ số chống nghiện`, mọi thừa số là số nguyên phần triệu, tích tính 128 bit
(`loot/chance.hpp`), nên không tràn và không phụ thuộc kiểu dấu phẩy động. Mỗi lần thử luôn hỏi `dice` đúng một lần.

```
LootTables::load({packs, monsters, level_gaps, rate_items, boxes}, catalog)
Roller roller(tables, factory, LootConfig{drop_param_ppm, box_lifetime});
roller.roll_kill(Kill{monster, level, origin, now}, claimants, dice, serials) → KillOutcome{boxes, announcements}
```

(Minh hoạ, chưa biên dịch.) `Claimant` là người có quyền chia đã lọc bởi zone (sát thương tối thiểu, nhóm, tầm nhìn); tối đa 18
người, mỗi người tối đa 5 đồ nhiệm vụ. Cách chia theo `Ruler` của dòng quái: `kCommon` một người được chọn đều nhận đồ, mọi người
khác chỉ nhận đồ nhiệm vụ; `kBoss` mỗi người tự cuộn một hộp. Hộp tối đa 10 món (đồ nhiệm vụ đứng trước, đồ cuộn lấp phần còn
lại). Người không có gì thì không có hộp. `Announcement` cho nơi gọi phát thanh (gói có loại phát thanh `DropNotify`).

Hộp rơi (`DropBox`): chủ nhặt (rỗng = ai cũng nhặt), `expires_at` (từ `box_recycle_ms` đã đổi sang tick), `public_from` (từ mốc này ai cũng
nhặt được). Nhặt:

1. `plan_pick(box, index, who, now, catalog, planner)` hoặc `plan_pick_all(...)` → `PickTicket{index, serial}`; hộp không đổi.
2. `inventory.apply(plan)`.
3. `take(box, ticket)` lấy món khỏi hộp. Ô giữ nguyên chỉ số khi một món bị nhặt (client gọi nhặt theo chỉ số).

`pick_rate_item(dice)` (bảng `item_drop_rates`) và `pick_box(key, dice)` (bảng `loot_box_entries`, `"default"`, `"gacha_7"` …) rút một
vật phẩm theo trọng số. `Roller::make(...)` tạo một món ngoài lần quái chết (rương, thưởng).

Bảng thật (đo 2026-10-14): `drop_packages` 2034 gói, `monster_drops` 3984 dòng, `item_drop_rates` 233 mục, `loot_box_entries` 1512 mục.
Mục có mã ngoài catalog bị bỏ và đếm ở `diagnostics()`; không làm hỏng bảng.

## 5. `shop`

### 5.1 Bảng đọc

| Bộ nạp | Tệp |
|---|---|
| `ShopTables::load` | `shared/shops.tsv` (bắt buộc), `shared/shop_scene_limits.tsv`, `server/random_shop_goods.tsv` (bắt buộc khi có cửa hàng ngẫu nhiên), `shared/junk_recycle.tsv` |

Bảng thật: 383 cửa hàng, trong đó 14 cửa hàng ngẫu nhiên; 8078 mặt hàng cố định có mã quen và 329 mã ngoài catalog (bỏ và đếm);
292 mã phế phẩm.

### 5.2 Cửa hàng đang chạy

`NpcShop::open(tables, shop, scene, now, dice)` mở bản sao của một NPC (`kNoSuchEntry`, `kWrongScene`). Cửa hàng có dòng trong
bảng cảnh chỉ mở ở các cảnh đó; không có thì mở ở đâu cũng được.

- Tồn kho từng dòng (`Line.stock` = số nhóm còn lại, `kUnlimited` = bán không hạn). `revision()` tăng mỗi khi hàng hoặc tồn đổi;
  gửi lại danh sách cho client khi nó đổi.
- `tick(now, dice)` làm mới khi tới hạn `refresh_ms` (đổi sang tick): một lần cho mỗi hạn bị lỡ, hạn kế = `now` + chu kỳ.
  Cửa hàng ngẫu nhiên chọn LẠI hàng mỗi lần làm mới.
- Cửa hàng ngẫu nhiên: chọn `Num` mục từ kho RandShop theo trọng số `Odds`, rút không hoàn lại, mục chọn xếp theo thứ tự trong kho.

### 5.3 Mua, bán, mua lại, sửa, phế phẩm (`shop/trade.hpp`)

| Việc | Hàm | Phiếu / bước hai |
|---|---|---|
| Mua | `plan_buy(store, {line, groups}, factory, dice, serials, now, planner)` | `BuyTicket` → `store.commit(ticket)` sau `apply` |
| Bán | `plan_sell(shop, catalog, rules, from, planner)` | `SellTicket` → `SoldList::remember(ticket)` sau `apply` |
| Mua lại | `plan_buy_back(list, planner)` | `BuyBackTicket` → `list.take(ticket)` sau `apply` |
| Sửa một món | `plan_repair(shop, catalog, where, planner)` | không |
| Sửa hết | `plan_repair_all(shop, catalog, planner)` | không |
| Phế phẩm | `plan_recycle(tables, from, count, planner)` | không |

**Giá một nhóm** (`price_of`): tiền vàng/giao tử (`is_gold_like`) lấy `base_price` của vật phẩm × số cái trong nhóm; tiền khác lấy
GIÁ GHI SẴN trong bảng cho cả nhóm. Rồi × `scale_permille` × `discount_percent` / (1000 × 100), làm tròn nửa lên đúng một lần, tối
thiểu 1 khi giá ghi sẵn > 0. Mua kiểm theo thứ tự hết hàng → thiếu tiền → hết chỗ; mỗi lượt tối đa `kMaxBuyGroups` (100) nhóm.

**Bán**: toàn bộ chồng ở ô túi; cổng cấp (`buy_level`) và loại (`buy_scope`); tiền luôn là vàng, `sell_value` của `item`; kiểm trần
ví (2008 để tràn). Danh sách mua lại (`SoldList`): 5 món, món mới ở trên cùng, món thứ sáu đè món cũ nhất, chỉ mua lại được món trên
cùng với đúng giá đã nhận, món về túi với serial cũ; chỉ ghi khi cửa hàng có `can_buy_back`; mất khi đóng cửa hàng (`clear`).

**Sửa hết dừng ở món đầu tiên không đủ tiền** (như 2008, không nhảy sang món rẻ hơn), giữ các món đã sửa và đặt `short_of_money`; không
sửa được món nào vì thiếu tiền thì `kInsufficientFunds`, không có gì cần sửa thì `kNoChange`.

**Phế phẩm**: giá cố định mỗi cái theo `junk_recycle`, không theo giá vật phẩm; NPC nào thu hồi là việc của script, hàm không gắn với cửa hàng.

## 6. `forge`

`ForgeTables::load({melting, carving, advances}, catalog)`:

| Loại (`Kind`) | Tệp | Cột |
|---|---|---|
| `kMelt` nung ngọc | `shared/gem_melting.tsv` | `gem_id` → `smelted_gem_id`, `required_item_id`, `required_money`, `substitute_item_id` |
| `kCarve` chạm ngọc | `shared/gem_carving.tsv` | `gem_id` → `carved_gem_id`, `required_item_id`, `required_money` |
| `kAdvance` nâng cấp siêu vũ khí | `server/super_weapon_advances.tsv` | `item_id` → `advanced_item_id`, `gold_cost`, `material_count`, `material_1_id`, `material_2_id` |

Bảng thật: 64 + 128 công thức nung/chạm, 312 công thức nâng cấp mở được (126 dòng `gold_cost` = -1 chưa mở, bị bỏ và đếm ở
`diagnostics().disabled_advances`, KHÔNG phải nâng cấp miễn phí). Mọi mã đều có trong catalog.

`plan_craft(tables, kind, from, factory, dice, serials, now, planner)` → `CraftReport{input, produced, gold, used_substitute}`:
bớt 1 món ở ô túi `from`, trừ vật liệu (bộ chính; thiếu thì bộ thay thế của nung ngọc), trừ vàng, sinh món ra
(`Origin::kForge`, `forge_level` 0) và cất vào túi. Món ra là món MỚI (thuộc tính ngẫu nhiên mới), chỉ giữ cờ khoá của món vào.
Thứ tự kiểm: món vào → công thức (`kNoSuchEntry`) → vật liệu (`kNotEnoughItems`) → vàng (`kInsufficientFunds`) → chỗ (`kBagFull`). Món
ra được sinh SAU các kiểm rẻ, nên lỗi vật liệu/vàng không tốn serial; riêng `kBagFull` (và lỗi cất khác) để lại một serial bỏ phí.

## 7. Công cụ `TOOLS/server/import_item.py`

```
python TOOLS/server/import_item.py <gốc dev/server> <gốc tlbb của XJL7457>          # ghi bảng
python TOOLS/server/import_item.py <gốc dev/server> <gốc tlbb của XJL7457> --check   # chỉ kiểm
```

Chỉ nhập dòng mà client 2026 xác nhận (mã có trong `items_common`/`equipment`/`gems`/`pet_equipment_base`, hay đoạn/luật được một
trang bị của client trỏ tới); dòng riêng của bản private bị bỏ và đếm. Ghi `item_segment_values_xjl`, `item_segment_quality_rules_xjl`,
`item_segment_distributions_xjl`, `item_sale_limits_xjl`, `super_weapon_advances` vào `tables/server`. Không nhập, kèm lý do in ra khi
chạy: `EquipEnance`, `PetEquipUpProductInfo`, `XYJ_*`, `mystery_shop.ini`. Test: `TOOLS/server/test_import_item.py`. Máy chủ XJL7457
chỉ được đọc làm dữ liệu: không chạy exe của nó, không nối địa chỉ của nó, không chép script hay nhị phân.

## 8. Kiểm chứng

```
cmake --build build/<preset> --target item_bag_tests item_catalog_tests item_codec_tests item_conserve_tests item_roll_tests \
    loot_box_tests loot_roll_tests loot_tables_tests shop_stock_tests shop_tables_tests shop_trade_tests \
    forge_craft_tests forge_tables_tests
ctest --test-dir build/<preset> -R ^item_     # rồi ^loot_, ^shop_, ^forge_ (mỗi lần một mẫu: ctest -R với "|" hỏng qua cmd)
python TOOLS/server/test_import_item.py
```

Các test có ca đọc bảng thật chỉ chạy khi có `dev/server/tables` (macro `GAME_SERVER_TABLES`). Mỗi module có: ca bảo toàn trên chuỗi
thao tác ngẫu nhiên đối chiếu với mô hình độc lập (`item_conserve`, `shop_trade conservation_fuzz`, `forge_craft conservation_fuzz`),
ca phân bố so với bảng (`loot_roll`, `item_roll`, `shop_stock`), ca biên và ca đầu vào thù địch của bộ giải mã, và ca nguyên tử
(lỗi không để lại gì, dấu vân tay `Inventory` trước/sau bằng nhau). Cổng máy: `check.py` trên mọi tệp nguồn; `check.py --run` (Clang
ASan + UBSan + hardening STL, GCC debug mode) trên mọi test; kiểm đột biến thủ công: 10/10 đột biến của `loot`, 23/23 của `shop`,
18/18 của `forge` bị test bắt.

## 9. Giả định

Mỗi mục: điều đã chọn, vì sao, cách đổi.

1. **Sinh thuộc tính trang bị** (`item/roll.hpp`): bảng gộp `EquipBase.txt` của client 2026 dùng bộ `ItemSeg*` nhưng máy chủ 14 môn
   phái chỉ có bản nhị phân, nên năm bước sinh được SUY RA từ dữ liệu và từ `CreateBlueEquipAttrib` 2008; `ItemSegRate` chưa rõ nghĩa,
   không dùng. Cột `ItemSegAffect.total` của tệp gốc không khớp tổng ở 36 dòng nên không dùng, chia cho tổng 9 trọng số.
2. **Cột `ItemSegQuality` theo nguồn đồ**: 0 quái thường … 6 BOSS ngày, 7 rèn không nguyên liệu, 9..16 rèn nguyên liệu cấp 1..8; cột
   7 và 9..16 "đã tách" theo điểm lắp 0..18. Đọc từ tên cột của tệp gốc.
3. **Gói rơi** (`drop_packages`): cặp (vật phẩm, cấp) bắt đầu ở cột 4 (cột 2 là loại phát thanh, cột 3 là cờ ép khoá) — đo trên bảng
   thật. Cột "cấp" của cặp (chỉ gặp 1..6 ở trang bị) đọc là nguồn sinh đồ cho `ItemSegQuality`; ô để trống thì lấy hạng của quái. Đoán
   theo cấu trúc bảng, chưa được client hay máy chủ gốc xác nhận. (Ghi chú cột ở `TOOLS/server/columns/server/drop_packages.tsv` từng
   nói "cặp bắt đầu ở cột 2, 100 cặp" của mã 2008, lệch với bố cục XJL7457 mà bộ nạp dùng; đã sửa 2026-10-15 ở `import_legacy.py` và
   tệp cột: mã 2008 đọc từ cột 2 vì tệp 2008 không có hai cột phát thanh và ép khoá, tệp này bắt đầu cặp ở cột 4.)
4. **Cửa hàng**: `buy_kind` 9 là "thu mua mọi thứ", 8 là "không thu mua" — suy ra từ phân bố dữ liệu (160/169 cửa hàng loại 9 có
   `buy_level` 120 và `can_buy_back`; 206/214 cửa hàng loại 8 có `buy_level` 0); sửa đồ chỉ có loại 1 trong dữ liệu. Khối hàng bắt
   đầu ở cột 29 (sáu cột mỗi khối); tên cột của `shops.tsv` sau khối thứ 29 lệch nên bộ nạp kiểm tên 14 cột đầu rồi dựa vào VỊ TRÍ,
   đã đối chiếu trên cả 383 cửa hàng. `Num` là số mục của cửa hàng ngẫu nhiên hoặc sức chứa; nạp quét `min(200, Num)` khối và dừng ở
   mã không dương.
5. **Giá cửa hàng**: giá ghi sẵn chỉ dùng khi tiền không phải vàng/giao tử (chú thích `Value` trong `RandShop/*.ini`: "khi tiền là
   vàng thì bỏ qua"). Số đo trên `shops.tsv`: ở cửa hàng tiền vàng 1907 trên 1933 hàng ghi đúng 100 (giá giữ chỗ), nên với tiền vàng
   giá lấy từ bảng vật phẩm; tiền khác luôn có giá ghi sẵn dương. Chiết khấu là phần trăm (`Rebate`).
6. **Cửa hàng ngẫu nhiên**: 2008 khai báo `GenerateRandItemPrice` mà không cài hàm chọn, nên luật chọn (trọng số `Odds`, không hoàn lại,
   chọn lại mỗi lần làm mới) suy ra từ chú thích tệp ini.
7. **Lò rèn**: không hệ thống nào trong ba hệ thống này có ở 2008. Giả định: thành công 100% (bảng không có cột xác suất);
   `material_count` là số cái của MỖI vật liệu; dòng `gold_cost` -1 là chưa mở; món ra mới sinh. Gốc 2008 chỉ có khảm ngọc qua Lua
   (`AbilityInlay`), chưa port (mục 11).
8. **Tick**: 20 tick/giây (`KE-HOACH-SERVER` mục 1); mọi hạn (hộp rơi, vật phẩm có thời hạn, làm mới cửa hàng) đổi từ mili giây sang tick
   bằng `ids::to_ticks`, làm tròn lên (hạn 1 ms không thành 0 tick).
9. **Hao mòn**: ngưỡng `EquipmentDamagePoint` = 500 là tham số của `wear_armor/wear_weapon`; nơi gọi đọc từ config.

## 10. Số tự đặt (cần chủ dự án duyệt)

- `dev/server/tables/server/item_limits.tsv`: mỗi dòng có cột `basis` (`client_lua`, `source_2008`, `made_up`). Dòng `made_up`: túi
  nhiệm vụ 60 ô (client không ghi số), ô mở sẵn của túi nguyên liệu (20), túi nhiệm vụ (60) và kho (100), trần vàng trước khi biết cấp
  (100 000 000), trần 2 000 000 000 cho mọi loại tiền khác kể cả các mã 13..16 mà client không đặt tên.
- `shop::kMaxBuyGroups` = 100: số nhóm tối đa một lượt mua (2008 luôn một nhóm; client 2026 có cột "mua nhiều" chưa rõ nghĩa).
- `shop::kMaxPool` = 1024: trần kho ngẫu nhiên (bảng thật: 84). `loot` hộp 10 món, 18 người chia, 5 đồ nhiệm vụ: số của 2008.
- `loot::kMaxDropParamPpm` = 100 lần: trần `DropParam` chấp nhận.
- `forge`: trần `material_count` = 100 (bảng thật: 1), `gold` ≤ int32.

## 11. Chưa làm (và vì sao)

- Hệ thống Lua của 2008 cho ngọc: khảm/tháo ngọc (`AbilityInlay`: `TooManyGems`, `IsGemFitEquip`, `IsGemConflict`, `EmbedProc`, xác suất
  25/50/75 đã lỗi thời), nâng cấp ngọc (`GemLevelup`, `DoubleGemCompound`), nâng cấp trang bị (`ItemEnhance` với `equipment_enhance`
  cột không tên, `EquipUpstage*`, `EquipLevelUp` với bảng xác suất theo cấp 60..120 → 100..30%), `SlotCost`, `installgemprice`:
  kịch bản Lua chưa rút ra dạng dữ liệu, cột bảng chưa có tên. `Planner::update` đã có làm đường thay thể hiện cho chúng.
- Thuộc tính cộng của cường hoá (`EquipEnance`, không nhập: không có id để client xác nhận).
- Đường `ItemQuality/ItemValue` của 2008 (bảng gộp client 2026 không còn cột tỉ lệ của chúng); `ItemSegRate`.
- `RepairRate.txt`: công thức phí hiển thị của client nằm trong mã máy chưa kết luận; `repair_success_rate` và `max_repairs` của
  cửa hàng chưa bị cưỡng chế (2008 đọc `repair_success_rate` mà không dùng; bản này cũng vậy và đếm ở `repair_rate_not_one`).
- Bộ trang bị (`SetEquip`), kiểm giới tính khi mặc (bảng client không có cột này: luôn `kAnySex`).
- `ShopRandom`/`ShopTime` (cửa hàng theo giờ), cột 14..28 của `shops.tsv` (chưa rõ nghĩa), `money_recycle_items`.
- `item_sale_limits_xjl.tsv` (cấm bày bán ở cửa hàng người chơi) đã nhập nhưng chưa có module đọc: cửa hàng người chơi chưa làm.
- Không nhập `PetEquipUpProductInfo` (0/680 dòng có id trong client), `XYJ_*` (hệ thống riêng của nhà phát hành).
- Nối vào zone/gate/protocol: các module này không có socket, không có mã tin; tích hợp (đổi `Plan` thành tin cho client, giữ
  `NpcShop`, `SoldList`, `DropBox` ở zone, đọc `economy.toml` thành `PriceRules`) là việc của nơi gọi.

## 12. Khác gốc

- 2008 có một túi; bản này ba túi theo client 2026, tiền gom vào một bảng số dư theo mã `CU_*`.
- 2008 sửa thẳng container và hoàn tác tay; bản này dựng Plan, áp dụng một lần, không bao giờ ghi nửa chừng.
- Tiền, xác suất, giá: số nguyên (phần triệu/phần nghìn), không `double`.
- Bán hàng: trần ví được kiểm lúc bán (2008 để tràn); hệ số cửa hàng và chiết khấu nhân một lần rồi làm tròn nửa lên (2008 ép hệ số về
  int trước nên hệ số 0,5 cho giá 0); số nhóm một lượt mua là tham số; danh sách mua lại chỉ ghi khi cửa hàng có `can_buy_back`.
- Rơi đồ: người không được chọn ở `BDR_COMMON` không bị cuộn (2008 cuộn rồi vứt); hộp đầy 10 món không ghi tràn mảng (2008 ghi
  tràn); `public_from` có cho cả hộp rơi (2008 chỉ cho điểm sinh trưởng).
- Mặc đồ: kiểm môn phái và giới tính ở server (2008 để client chặn).
