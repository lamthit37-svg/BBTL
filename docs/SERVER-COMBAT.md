# Máy chủ — lõi chiến đấu (module `actor` và `combat`)

Hai module thuần của máy chủ: không mạng, không đồng hồ thật, không luồng. Ngẫu nhiên là `dice::Dice` do nơi gọi đưa
vào (một nguồn cho mỗi cảnh, rút theo thứ tự cố định nên phát lại được); thời gian là `ids::Tick` (20 Hz, 50 ms).
Zone nắm một `combat::Arena` cho mỗi cảnh, đọc hàng sự kiện sau mỗi bước rồi tự phát tin.

- `actor` — thân thể: thuộc tính và chỉ số dẫn xuất, HP/MP/nộ khí/liên kích, kinh nghiệm và lên cấp (nhiều cấp một
  lượt), hình phạt chết, hồi sinh, đổi phái, tẩy điểm, tâm pháp, bản ghi bền (kind `0x5201`).
- `combat` — kỹ năng, buff và hiệu ứng, chuỗi sát thương và hồi phục, hồi chiêu, nhắm mục tiêu, gom khí và dẫn khí, sự
  kiện đầu ra, bản ghi bền (kind `0x5202`).

Nguồn: mã GameServer 2008 (`Obj_Human_Attributes.cpp`, `Combat_Core.cpp`, `SkillLogic.cpp`, `Impact_Core.cpp`,
`Obj_Character_Impact.cpp`, `MenPai/*.cpp`, `DiePenaltyManager.cpp`, `Action/*.cpp`...) và các bảng ở
`dev/server/tables/{shared,server,client,variants}`. Dữ liệu client 2026 thắng mã 2008 (dữ liệu là chuẩn chạy thật);
chỗ lệch ghi tại chỗ bằng `Khác gốc:` và gom ở mục 10. Số không có nguồn nào ghi `basis=made_up` (mục 11).

Tầng trong `cmake/GameLayers.cmake`: `actor` nằm dưới `combat`; cả hai chỉ dùng `ids`, `dice`, `protocol` (tầng byte),
`table`, `core`. Test: `Test/Actor/actor_tests.cpp` (17 ca), `Test/Combat/combat_tests.cpp` (22 ca).

## 1. Nhịp và hợp đồng thời gian

`Arena::tick()` làm theo đúng thứ tự:

1. `now += 1`.
2. Mỗi thực thể theo `handle` tăng: dọn buff đã tan, nhịp buff (từ cuối về đầu), nhịp gom/dẫn, hồi HP/MP (cứ 60 bước
   một lần; chỉ sinh sự kiện khi giá trị đổi), dọn nhóm hồi chiêu đã hết.
3. Giao mọi hiệu ứng đến hạn theo khoá (hạn, số thứ tự gửi).

Lệnh (`cast`, `send_effect`...) chạy giữa hai bước. Hiệu ứng luôn đi qua hàng đợi, kể cả trễ 0: nó tới ở `tick()` kế
tiếp. Hiệu ứng giao ở bước `t` bắt đầu đếm giờ từ `t+1`, nên buff 1000 ms (20 bước) hiện ở bước `t` và tan ở bước
`t+20` (còn thấy ở `t+19`). `ms_to_ticks` làm tròn lên. Hồi chiêu 3000 ms đặt ở bước `0` từ chối đến bước `59`, nhận ở
bước `60`.

## 2. Luồng một lệnh `Arena::cast`

Thứ tự kiểm (dừng ở lỗi đầu tiên, trả `CastOutcome`): người ra chiêu có và sống → mẫu kỹ năng → trạng thái cho phép
(cờ điều khiển, biến hình, bộ lọc buff) → đã học và đủ cấp → hồi chiêu → không bận hành động → dòng cấp có dữ liệu →
logic có mã (`kUnsupported` nếu không) → kỹ năng bị động (`kForbidden`) → cần vũ khí → điều kiện/tiêu hao
(`kLackMana`, `kLackRage`, `kLackStrike`, `kLackHp`...) → mục tiêu (có, sống, tầm đánh + sai số) → `on_start` của handler.

Sau đó theo loại: tức thời chạy ngay; gom khí đếm lùi trong `tick()` rồi kiểm lại điều kiện và phát; dẫn khí phát mỗi
chu kỳ (< 500 ms thay bằng 2000 ms như bản gốc). `run_activation` → tiêu hao → khoá hành động (≥ 500 ms) → hồi chiêu
(không ngắn hơn thời gian diễn hoạt) → `activate`: quét mục tiêu (gần trước; cùng khoảng cách thì `handle` nhỏ trước;
bỏ xác; tối đa `max_targets`, trần 100), lăn trúng/né cho mọi mục tiêu rồi hội tâm cho mục tiêu bị trúng, rồi handler
gửi hiệu ứng. Trễ `delay_ms` của kỹ năng trễ hiệu ứng tới đích (lần phát thứ `k` trễ `delay × k`).

Bị đánh khi đang gom khí: với xác suất `disrupt_chance` cột 2026, thời gian còn lại cộng thêm lượng đã gom, tối đa 500
ms và tối đa `disrupt_time` phần nghìn tổng thời gian gom. Đang dẫn khí thì mất một chu kỳ.

Handler kỹ năng (cột `handler` của `skill_logics.tsv`): `standard` (mọi việc do cột `roles` quyết định), `dash` (như
standard rồi dời người ra chiêu và phát `kMove`), `passive_armor`, `passive_weapon`, `sect_mimic`, `unsupported`.

`sect_mimic` (logic 671, hoá khí thức của Mộ Dung) và `Arena::cast_borrowed`: phát một lượt của kỹ năng khác thay cho
người dùng ở cấp cao nhất có dữ liệu, bỏ qua sổ kỹ năng, hồi chiêu, tiêu hao, khoá hành động và kiểm tầm. Kỹ năng bị
động, kỹ năng chưa có mã và lời gọi lồng nhau bị từ chối. Mục tiêu thuộc một phái có ô thì mượn kỹ năng của phái ấy
(ô 0..9 là phái 0..9, ô 10..14 là phái 11..15), còn lại rút ngẫu nhiên một ô hợp lệ.

## 3. Chuỗi sát thương và hồi phục

`send_effect` tính sát thương công thức (`compute`) ngay lúc gửi, nên xúc xắc dao động rút ở lúc gửi. Lúc giao:
`critical_refix` nhân đôi mọi ô khi hội tâm → `on_active` → `damage_channels` (hook theo kênh `on_damages`, cộng sáu
kênh, tối thiểu 1) → `deal` (khiên `on_damage`, nộ khí người đánh theo sát thương đã qua khiên, `on_damage_target` của
người đánh được phép đổi số) → `change_hp` → chết (nộ khí về 0, hình phạt do zone áp, sự kiện `kDied`).

Công thức sáu kênh (`combat/damage.cpp`, `Combat_Core`): ngoại và nội là `atk² / (atk + def)` với `atk`, `def` tối thiểu 1,
tính bằng số nguyên 64 bit; miễn nhiễm cắt xuống ở ngoại và làm tròn ở nội; bốn hệ (băng, lửa, điện, độc) là
`công × (100 − kháng) / 100` với kháng đã trừ phần giảm kháng của người đánh, kẹp −100..100 (kháng thô kẹp ±200). Dao
động: `2 × biên × (50 − roll) / 100` làm tròn Float2Int, rồi `v + v × dao_động / 100` cắt về 0. Trúng: `hit × 100 /
(hit + miss)` với `hit`, `miss` kẹp 1..1000, trúng khi `roll < tỉ lệ`. Hội tâm khi `roll < tỉ lệ` (kẹp 0..100).
Sự kiện `kDamaged.value` là sát thương tính được, không kẹp theo máu còn; `extra` bit 0 là hội tâm. `kHealed.value` là
lượng tính được kể cả phần vượt mức tối đa (hồi tự nhiên đã kẹp).

## 4. Buff

Tối đa 20 buff mỗi thực thể. Cùng nhóm loại trừ (`mutex_id`; `mutex_by_caster` tách theo người tạo) thì buff mới thay buff
cũ, trừ khi cùng kỹ năng mà cấp hiệu ứng thấp hơn (từ chối, `kBuffRefused`); đầy 20 buff thì thay buff có lợi, gỡ được, mới
nhất. Chỉ số cộng từ buff tính lại (`recompute`) mỗi khi danh sách đổi. Buff tan khi `elapsed ≥ continuance`
(`fade_out` đánh dấu, `cleanup_faded` gỡ khỏi mảng ở nhịp sau: dùng `Fighter::find_buff_by_effect` để hỏi buff còn
sống, không dùng `buff_count`). Buff "vô hạn" có `continuance = −1`. Hook mà logic hiệu ứng ghi đè: `init`, `refix_power`,
`refix_continuance`, `critical_refix`, `compute`, `on_active`, `on_fade_out`, `on_interval`, `on_damages`, `on_damage`,
`on_damage_target`, `on_be_hit`, `on_hit_target`, `on_critical_hit_target`, `on_be_critical_hit`, `on_heal_target`,
`on_be_heal`, `on_die`, `on_use_skill`, `refix_skill`, `refix_impact`, `filtrate`, `contribute`, `alive_check`.

## 5. API chính (`combat/arena.hpp`)

`add(Fighter&&)`, `remove`, `find`, `tick`, `cast`, `cancel_cast`, `interrupt`, `kill`, `revive`, `accept_relive`,
`learn`, `refresh`, `send_effect`, `dispel_collection`, `cancel_collection`, `events`/`clear_events`/`dropped_events`,
`set_relation_policy`, `set_spouse_policy`, `snapshot`, `restore`, `cast_borrowed`, `units_around`, `cooldown_remaining`,
`set_cooldown`, `clear_cooldown`. Quan hệ bạn/địch mặc định theo ma trận phe của `camp_relations.tsv`; zone cắm chính
sách riêng (PK, tổ đội, bang) bằng `set_relation_policy`; module xã hội cắm `set_spouse_policy` cho điều kiện "đối
tượng là phối ngẫu". Đầu ra duy nhất là hàng `Event` (`combat/types.hpp`): zone đọc rồi phát tin. Sự kiện cần module
ngoài lõi (thú cưng, script Lua, trận pháp, bẫy, triệu hồi, dịch chuyển cảnh) đi qua `kUnsupported`, `kSpawn`,
`kTeleport`, `kAggro`, `kMove`, `kReliveOffered` với `value` là lý do (`UnsupportedReason`).

## 6. Bảng đọc

`combat::load_catalog(CatalogText)` nhận nội dung TSV (không mở tệp), kiểm từng ô bằng `actor::Sheet` (có miền; ô hỏng
trả lỗi nêu bảng, dòng, cột; bảng phải đủ cột và đúng tên cột mốc). Cột đọc theo chỉ số, đã đối chiếu với dữ liệu thật.

- `shared/skills.tsv` (102 cột, cột 0 `skill_id`, cột 96 `column_96`): 1 phái, 6 cần vũ khí, 7/8/9 cờ chặn, 10 tâm pháp,
  12 loại (0 gom, 1 dẫn, 2 tức thời, 3 bị động), 13 nhóm hồi chiêu, 19 trạng thái mục tiêu, 20 lớp người dùng, 21 bị
  động, 22 kiểu chọn, 27 nhóm kỹ năng, 33 logic nhắm, 34 thời gian ra chiêu ms (−1 là 0), 35 tầm xa (mét, ×100 ra cm),
  36 đứng phe, 37 nhắm theo đứng, 38 nhắm theo loại, 41 đòn tự lặp, 43 bán kính, 44 số mục tiêu tối đa, 46 ngắt đòn
  tự lặp, 47 trễ, 48..63 id dòng cấp 1..16, 81 thời gian đẩy lùi, 96 số lần phát/chu kỳ dẫn, 97 độ chính xác, 99 xác
  suất bị gián đoạn.
- `shared/skill_levels.tsv` (54 cột, cột 0 `id`, cột 5 `logic_id`): 6 hồi chiêu ms, 7 gom khí ms, 8 dẫn ms, ba điều kiện
  ở cột `10 + 4t` (loại, a, b), 21 giới hạn cấp mục tiêu, 15 tham số ở cột `25 + 2k`.
- `server/effects.tsv` (76 cột, cột 0 `data_index`, cột 2 `logic_id`): 4 buff kéo dài, 5 id hình ảnh, 7 nhóm loại trừ,
  8 cấp, 9 đứng phe, 10 giữ khi chết, 11 gỡ được, 12 huỷ được, 13 cần dẫn khí duy trì, 14 bỏ qua bộ lọc, 15 tan khi
  mất máu, 16 tan khi hành động, 17 tan khi ngoại tuyến, 18 tính giờ khi ngoại tuyến, 20 thời gian ms (−1 vô hạn),
  21 chu kỳ ms, 22 loại trừ theo người tạo, 16 tham số ở cột `28 + 3k`.
- `shared/id_collections.tsv` (id, ghi chú, loại, số id, các id): loại 0, 7..10 là tập buff; 1 nhóm loại trừ; 2 logic;
  3 kỹ năng; 4 logic kỹ năng; 5 trực tiếp; 6 bẫy.
- `server/camp_relations.tsv`: cột 0 là phe, mỗi cột sau một phe; ô khác 0 là bạn; phe lạ coi là bạn.
- Bảng sinh bởi `TOOLS/server/import_combat.py` (kiểm `--check`): `sect_templates.tsv` (6 dòng), `sect_rage_rules.tsv`
  (4 dòng), `skill_logics.tsv` (130 dòng), `effect_logics.tsv` (67 dòng). Nội dung ở `TOOLS/server/combat_logics.py`;
  sửa ở đó rồi chạy lại, không sửa tay bảng.

Bảng logic (`logic_id, handler, roles, fidelity, note`) gắn mỗi logic của dữ liệu với một mã xử lý trong C++. Nạp lỗi
khi tên mã xử lý lạ, `fidelity` lạ, `roles` sai cú pháp hay logic lặp.

### Cú pháp `roles`

`chỉ_số:loại[@xác_suất][*lặp][+phụ]`, ngăn bằng `;`. `chỉ_số` là ô tham số (0..63) chứa id hiệu ứng; `@n` là ô chứa xác
suất %, `*n` ô chứa số lần lặp, `+n` ô phụ. Loại: `target`, `self`, `target_tick`, `self_tick`, `friend`, `enemy`, `rest`,
`friend_rest`, `enemy_rest`, `rank0..15`, `friend0..15`, `enemy0..15`, `self_male`, `self_female`, `combo0..3`, `trap`,
`trap_tick`, `summon`, `totem`, `dispel_self`, `cut_cooldown` (ô phụ là lượng ms), `sub` (hiệu ứng con của hiệu ứng). Rỗng
hay `-` là không có vai. Tối đa 64 vai.

## 7. Độ phủ dữ liệu

Dòng = một kỹ năng cấp (dòng `skill_levels.tsv`) mà mẫu kỹ năng của phái 0..8, 10..15 trỏ tới qua 16 ô cấp. Một dòng
được **phủ** khi logic của nó có mã xử lý thật (không phải `unsupported`) và mọi hiệu ứng nó chạm tới (theo `roles`,
đệ quy qua vai `sub`) có logic hiệu ứng có mã. **Chắc** = phủ và không logic nào ở mức `event`. **Trọn** = phủ và mọi
logic ở mức `full`. Hai nhóm tách ra khỏi mẫu số vì mã không thể phủ thứ dữ liệu không tồn tại: **thiếu dữ liệu** (hiệu
ứng mà `effects.tsv` không có dòng) và **không tham số** (logic chưa có mã mà mọi ô tham số rỗng: trận pháp, triệu hồi).
Đo bằng `python -B TOOLS/server/skill_coverage.py --markdown` (`--per-sect` xếp hạng logic từng phái, `--pending` liệt kê
logic còn chặn dòng):

| Phái | Dòng | Thiếu dữ liệu | Không tham số | Phủ | Chắc | Trọn | Phủ/dòng còn dữ liệu | Chắc/dòng còn dữ liệu |
|---|---|---|---|---|---|---|---|---|
| 0 | 480 | 89 | 2 | 386 | 369 | 305 | 99.23% | 94.86% |
| 1 | 448 | 72 | 2 | 370 | 369 | 305 | 98.93% | 98.66% |
| 2 | 447 | 56 | 2 | 386 | 385 | 289 | 99.23% | 98.97% |
| 3 | 446 | 59 | 2 | 382 | 381 | 273 | 99.22% | 98.96% |
| 4 | 601 | 258 | 18 | 322 | 321 | 193 | 99.08% | 98.77% |
| 5 | 622 | 330 | 2 | 287 | 286 | 193 | 98.97% | 98.62% |
| 6 | 558 | 232 | 18 | 306 | 305 | 225 | 99.35% | 99.03% |
| 7 | 479 | 56 | 2 | 418 | 417 | 273 | 99.29% | 99.05% |
| 8 | 441 | 114 | 3 | 322 | 321 | 161 | 99.38% | 99.07% |
| 10 | 635 | 452 | 18 | 161 | 160 | 64 | 97.58% | 96.97% |
| 11 | 459 | 403 | 4 | 49 | 48 | 32 | 94.23% | 92.31% |
| 12 | 459 | 338 | 83 | 35 | 34 | 32 | 92.11% | 89.47% |
| 13 | 426 | 372 | 2 | 49 | 48 | 32 | 94.23% | 92.31% |
| 14 | 522 | 436 | 0 | 81 | 80 | 80 | 94.19% | 93.02% |
| 15 | 426 | 388 | 2 | 33 | 32 | 32 | 91.67% | 88.89% |
| Tổng | 7449 | 3655 | 160 | 3587 | 3556 | 2489 | 98.71% | 97.85% |

Phái 1..10 (kể cả Mộ Dung, phái 10) đạt ≥ 95% phủ; phái mới 11..15 dưới 95% (91,67..94,23%) chỉ vì bí pháp tiến giai (dưới).
Với phái 11..15 phần lớn dòng nằm ở "thiếu dữ liệu" (`effects.tsv` hiện hành thiếu hiệu ứng của chúng), nên mẫu số còn lại
nhỏ (36..86 dòng) và 2..5 dòng bí pháp kéo tỉ lệ xuống.

Logic kỹ năng còn chặn dòng (`--pending`): 701 (36 dòng), 700 (4), 707 (2), 702 (2), 703/705/706 (1 mỗi loại), và 734/735
cùng họ. Không logic hiệu ứng nào còn chặn. Lý do 700..707, 734, 735 giữ `unsupported`: đó là bí pháp tiến giai, tác dụng
lên kỹ năng gốc qua điểm tiến giai, mà bảng chỉ nối bí pháp với kỹ năng gốc bằng **tên** (`伏虎拳·发劲1级` — `伏虎拳`). Đo trên
dữ liệu thật: 59 trên 138 bí pháp trùng tên nhiều kỹ năng hoặc không có kỹ năng nào để nối, nên không thể nối chắc chắn.
Làm theo tên cho những cái nối được mà bỏ cái còn lại sẽ cho hành vi khác nhau giữa các bí pháp cùng loại. Chưa làm cho
tới khi có bảng nối (`NGHI-NGO` chưa mở mục riêng vì thiếu dữ liệu, không phải thiếu kiểm).

Các logic kỹ năng `unsupported` còn lại (30 dòng ở `skill_logics.tsv`, mức `event`) cần thứ ngoài lõi: bắt/triệu hồi/kỹ năng
thú (10, 11, 17, 645: module thú cưng), triệu gọi con cái (19: module xã hội), trận pháp (207, 761..765: cơ chế đội hình và
bảng không có tham số hiệu ứng), 176 (ngũ độc: cần theo dõi độc trùng), 201 (chọn ngẫu nhiên theo trọng số), 670 (hiệu ứng
theo tập khống chế mục tiêu đang mang), 768, 833, 869, 870, 883, 886 (chọn ô theo số mục tiêu, tỉ lệ máu, hệ ba hồn, ngưỡng
máu mục tiêu; thiếu nguồn công thức hoặc trạng thái chưa theo dõi). Khi gặp, `cast` trả `kUnsupported` và (nếu có logic)
phát `kUnsupported` với `UnsupportedReason::kUnknownLogic`. Hiệu ứng trỏ id không có trong bảng phát `kUnsupported` với
`kMissingData` và `id` là số thiếu; không bao giờ coi là thành công im lặng.

### Độ trung thực (`fidelity`)

- `full` — hành vi có từ mã nguồn hoặc nghĩa tham số không mơ hồ, đủ cơ chế phụ.
- `core` — phần chính được làm trong lõi, cơ chế phụ chưa.
- `event` — lõi chỉ phát sự kiện cho module ngoài (thú, AI quái, script, trận pháp...).

Logic kỹ năng: 26 `full`, 73 `core`, 31 `event`. Logic hiệu ứng: 27 `full`, 33 `core`, 7 `event` (6, 27, 28, 57 thú cưng;
8 khiêu khích và 74 chế giễu qua `kAggro`; 90 script Lua qua `kUnsupported`). Các logic đánh dấu (0, 38, 51, 52, 72, 87)
là `none` ở mức `full`: hiệu ứng chỉ để kỹ năng khác hỏi qua tập id.

## 8. Lưu trữ

`encode_combat`/`decode_combat` (`combat/codec.hpp`): một khung `protocol` kind `0x5202`, thân bắt đầu bằng phiên bản u16
(`1`); chỉ nằm trong database. Dữ liệu đọc coi như thù địch: thiếu byte, kind/phiên bản lạ, số ngoài miền, trùng hay sai
thứ tự, byte thừa, vượt trần đều trả `CodecError`, không bao giờ `assert`. Bản ghi (`CombatRecord`): sổ kỹ năng sắp theo
id (cấp 1..16, ≤ 512), hồi chiêu còn lại theo số bước (sắp theo nhóm, ≤ 255), buff mang theo (≤ 20) trừ buff có cờ tan
khi ngoại tuyến. `Arena::restore(unit, record, offline_ticks)` cộng thời gian ngoại tuyến chỉ cho buff tính giờ ngoại
tuyến, bỏ buff đã hết hạn và buff mà hiệu ứng không còn trong bảng, không chạy lại `on_active`. Bản ghi thân thể
(`actor::Record`, kind `0x5201`) là khối riêng, lưu độc lập.

## 9. Giới hạn đã biết

- Chưa có thú cưng, trận pháp, bẫy, tượng, triệu hồi, cưỡi, ảnh vệ trong lõi: lõi chỉ phát `kSpawn`, `kAggro`, `kUnsupported`.
- Không chạy Lua: logic 90 và các hiệu ứng gọi script chỉ phát mã script.
- Quét mục tiêu và `units_around` duyệt tuyến tính cả đấu trường: zone phải chia đấu trường theo cảnh (trần 16384 thực thể).
- Không có TSan trên Windows nên đường đa luồng chưa kiểm; lõi vốn đơn luồng theo cảnh.
- Hình phạt chết (`roll_penalty`), cộng kinh nghiệm cho người tham gia, rơi đồ, tổ đội chia kinh nghiệm thuộc zone và module
  vật phẩm/xã hội; lõi chỉ cung cấp phép tính.
- Hàng sự kiện có trần 65536; vượt thì bỏ và đếm ở `dropped_events()`. Hàng hiệu ứng chờ có trần 4096 (`send_effect` trả
  `false` khi đầy).

## 10. Khác gốc (đã chốt)

Thân thể (`actor`):
- Số học nguyên 64 bit thay float (`round_ratio` = Float2Int: từ 0,5 lên với số không âm, cắt về 0 với số âm); chỉ khác bản
  float ở thương rất lớn (trên 2^24).
- Tử số nội công dùng mẫu 100 cho cả ba dòng (bản gốc dùng 1000 ở ba dòng nội công, dữ liệu cùng thang với ngoại công).
- Cột biên độ dao động đọc ở cột 36 (`BaseInfo::kAttackFluctuation`, dữ liệu hiện hành); mã 2008 đọc cột 33.
- Nộ khí khi gây và khi nhận sát thương lấy tỉ lệ theo phái từ `BaseValueTable` cột 37, 38 (dữ liệu hiện hành); mã 2008 chia
  cứng 20 hoặc 40.
- Lên nhiều cấp một lượt khi đủ kinh nghiệm (bản 2008 chỉ lên một cấp mỗi lần gọi).

Chiến đấu (`combat`):
- Công thức `atk²/(atk+def)` dùng 64 bit rồi kẹp (bản gốc nhân int32 và tràn khi `atk > 46340`).
- Giảm kháng của người đánh trừ vào kháng của người bị đánh trước khi kẹp.
- Buff tan khi `elapsed ≥ continuance` (bản 2008 chờ thêm một nhịp: `elapsed > continuance`).
- Chu kỳ hiệu ứng 0 (dữ liệu thiếu) bị bỏ qua (bản 2008 lặp vô hạn).
- Thay thế buff duyệt giảm từ cũ nhất tới mới nhất đúng ý định (bản 2008 duyệt `i--` viết thành `++` nên chạy ra ngoài mảng).
- Xác suất `roll_chance` qua khi `roll < giá trị` (bản 2008 `<=`, lệch +1%).
- `OnDamageTarget` được đổi sát thương, số sau hook là số trừ máu (dữ liệu 2026 có hiệu ứng khuếch đại sát thương gây ra).
- `immune_odds` (logic 24): chỉ rút xúc xắc khi hiệu ứng đến thuộc tập (bản 2008 rút trước, bằng `rand()` ngoài `Dice` của cảnh).
- `absorb_shield` (logic 29): cường hóa chia 100 như mọi `RefixPowerByRate` (bản 2008 chia 1000 nên cường hóa 0 làm khiên
  còn một phần mười).
- `counter` (logic 22): phần phản sát thương trừ máu ngay (bản 2008 xếp qua hiệu ứng trễ 500 ms); các đòn phản kích vẫn trễ 500 ms.
- `restore_rate` (logic 5): bỏ phép cộng 100 vào phần trăm HP (bản 2008 làm giá trị 0 hồi đầy máu; dữ liệu 2026 dùng
  phần trăm thật).
- `damage_percent` (logic 2): theo HP tối đa cuối cùng (bản 2008 lấy HP gốc theo phái không buff; `Body` chỉ giữ giá trị cuối).
- Kỹ năng chuẩn gửi hiệu ứng bản thân một lần cho mỗi lượt phát có ít nhất một mục tiêu trúng (bản 2008 lặp theo từng mục tiêu).
- Quét vùng bỏ xác trừ khi kỹ năng cần xác; kỹ năng đòn tự lặp đặt lại đồng hồ, không cộng dồn phần còn lại.
- Gián đoạn gom khí theo xác suất cột `disrupt_chance` của dữ liệu 2026 (bản 2008 không có xác suất).
- Tốc chạy từ buff gộp làm một phần trăm của tốc gốc (bản 2008 cộng từng buff đã làm tròn riêng).
- Thời gian ra chiêu `-1` (kỹ năng 3296, 3325 của bảng thật) coi là 0 (bộ nạp trước đó từ chối cả bảng).
- `sect_mimic` phát kỹ năng mượn ở cấp cao nhất có dữ liệu thay vì cấp 65 (bảng cấp đánh số theo tâm pháp).
- Logic hiệu ứng 60, 66, 67, 68, 70, 86, và các logic 69, 76, 77, 81, 88, 92..95 chỉ có ở dữ liệu 2026: nghĩa tham số lấy từ
  cột mô tả trong `effects.tsv` (xem ghi chú từng lớp ở `detail/effects_*.cpp`), không có đối chiếu mã 2008.

## 11. Số tự đặt (`basis=made_up`, chờ chủ dự án duyệt)

- `sect_templates.tsv`: các phái mới 10..15 mượn hệ số cơ bản và điểm mỗi cấp của một phái gốc: Mộ Dung (10) mượn Đại Lý (6),
  Đường Môn (11) mượn Thiên Sơn (7), Quỷ Cốc (12) mượn Võ Đang (3), Đào Hoa Đảo (13) mượn Nga Mi (4), Thông Nhân Tông (14)
  mượn Minh Giáo (1), Nga Nhân Cốc (15) mượn Tinh Túc (5). Chọn theo lối đánh gần nhất với tên và kỹ năng; client 2026 có dữ
  liệu cho các phái này nhưng bảng gốc `BaseValueTable` thì không.
- `sect_rage_rules.tsv`: luật nộ khí đặc thù của phái mới theo phái mẫu (chỉ Đào Hoa Đảo mượn luật hồi máu của Nga Mi, 1/20).
  Luật của ba phái gốc (Cái Bang 10/1, Nga Mi 1/20, Tiêu Dao 10/1) có nguồn 2008 (`basis=source_2008`).
- `ArenaLimits::range_tolerance_cm = 100`: sai số tầm đánh chấp nhận, bù độ trễ di chuyển.
- Trần tài nguyên của lõi (`combat/types.hpp`, `ArenaLimits`): 16384 thực thể, 4096 hiệu ứng chờ, 65536 sự kiện, 100 mục tiêu mỗi
  lần quét, 32 lần phát một lượt (`kMaxActivations`); chống bảng sai hay đầu vào thù địch, không phải luật game.
- Nghĩa tham số của các logic hiệu ứng chỉ có ở dữ liệu 2026 (mục 10, dòng cuối) suy từ cột mô tả; ghi chú từng logic ở cột `note`
  của `effect_logics.tsv`.

## 12. Kiểm chứng

- `Test/Actor/actor_tests.cpp`: bảng thật, chỉ số vàng theo phái và cấp, trang bị, quái, nhiều cấp một lượt, tới cấp trần, tiêu
  điểm/tẩy/đổi phái, kinh nghiệm suy giảm theo chênh cấp, hồi theo nhịp, chết và hồi sinh, luật nộ khí, mất kinh nghiệm, tâm
  pháp, id và xúc xắc hình phạt, codec và đầu vào hỏng.
- `Test/Combat/combat_tests.cpp`: nạp bảng thật (đếm dòng 4586/20667/9860, cột kỹ năng 281, 282, hiệu ứng 201, ma trận phe) và
  từ chối bảng hỏng; cú pháp `roles`; công thức hand-computed; chỉ số theo buff (337 → 437 → 471...); bị động giáp; một đòn theo
  hạt giống cố định (trúng, trượt, hội tâm) trên dữ liệu tổng hợp và trên kỹ năng thật 281; từ chối ra chiêu theo từng lý do; hồi
  chiêu và buff đúng bước; chu kỳ; khiên; hồi máu; chết và hồi sinh; gom khí, huỷ và đẩy lùi; đòn vùng (thứ tự, giới hạn, bỏ bạn
  và xác); chính sách quan hệ; logic chưa hỗ trợ và thiếu dữ liệu; codec (vòng khép kín, mọi tiền tố, byte thừa, lật bit, bản ghi
  vi phạm bất biến); snapshot và khôi phục (ngoại tuyến 30 bước và 2000 bước).
- Số vàng của chỉ số và của từng đòn tính độc lập bằng `TOOLS/server/golden_combat.py` (bản Python của `Dice`, công thức, đọc cột
  theo tên từ `dev/server/tables`), không lấy từ đầu ra của C++: `python -B TOOLS/server/golden_combat.py stats <phái> <cấp>` và
  `scan <số hạt> [thật]`.
- `TOOLS/server/test_import_combat.py` (21 ca): bảng sinh khớp bộ sinh, tên mã xử lý có thật trong C++, `roles` đúng cú pháp, độ
  phủ dữ liệu thật không tụt dưới mức đã chốt. `python -B TOOLS/server/import_combat.py dev/server/tables --check` xác nhận bảng
  commit khớp bộ sinh.
