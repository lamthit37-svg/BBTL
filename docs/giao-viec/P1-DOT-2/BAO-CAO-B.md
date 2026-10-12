# Báo cáo vai B — P1 đợt 2

## 1. Tệp đã tạo hoặc sửa

- `TOOLS/server/import_legacy.py` — tách hàm đã xong ở lượt trước; lượt này thêm cột `within_declared_count`, bỏ ba cột lặp, `prepare_directory` của `tables/server` giữ `scene_refs.py`.
- `TOOLS/server/test_import_legacy.py` — test cột mới; `main` bị bắt cả stdout và stderr.
- `TOOLS/server/import_rules.py` — đọc `legacy_rules.tsv`, ghi TOML luật, so khoá tiến trình.
- `TOOLS/server/test_import_rules.py` — hình dạng bảng soạn tay, ca giả trong `build/`, ca dữ liệu thật khi có biến môi trường.
- `TOOLS/server/legacy_rules.tsv` — một dòng cho mỗi cặp section và khoá của tám nguồn ở mục 3.
- `SERVER/config/rules/global.toml`, `combat.toml`, `character.toml`, `new_character.toml`, `monster.toml`, `instances.toml` — sáu tệp luật đã làm kỹ.
- `SERVER/tables/server/` và `TOOLS/server/columns/server/` — chỉ chép lại năm bảng `scenes`, `scene_hosting`, `rolling_announcements`, `scheduled_events`, `random_shop_goods`. Không chạy `prepare_directory` trên cây thật.

## 2. Đã kiểm

Lệnh chạy ở gốc dự án. Dữ liệu thật: `THIENLONG_LEGACY_ROOT=C:\Users\myhea\Desktop\New folder\TLBB_0859602_Win10_11\tlbb`.

Không có lần đỏ đã lưu của ca mới. Test được viết cùng mã; lần chạy đầu sau khi có mã là xanh. Không bịa một lần đỏ.

Lint bốn tệp của vai B:

```text
python -W error TOOLS/server/lint_py.py TOOLS/server/import_legacy.py TOOLS/server/test_import_legacy.py TOOLS/server/import_rules.py TOOLS/server/test_import_rules.py
```

Thoát 0, không in dòng lỗi.

Test không đặt biến môi trường. Output chỉ có dòng của `unittest`:

```text
python -W error -m unittest discover -s TOOLS/server -p "test_import_legacy.py"
```

`Ran 22 tests in 0.025s`, `OK (skipped=1)`.

```text
python -W error -m unittest discover -s TOOLS/server -p "test_import_rules.py"
```

`Ran 5 tests in 0.006s`, `OK (skipped=1)`.

Cùng hai lệnh sau khi đã đặt `THIENLONG_LEGACY_ROOT` và `THIENLONG_RAW_ROOT`. Không ca nào bị bỏ qua. `test_import_legacy.py`: `Ran 22 tests in 2.995s`, `OK`. `test_import_rules.py`: `Ran 5 tests in 0.015s`, `OK`. Ca thật ghi vào `build/p1-b/` rồi xoá thư mục tạm.

Ghi luật vào đúng đích:

```text
python -W error TOOLS/server/import_rules.py "<THIENLONG_LEGACY_ROOT>" SERVER/config/rules
```

Thoát 0, 0,046 giây:

```text
luật: 131
tiến trình: 26
bỏ: 9
chưa rõ: 412
lệch tiến trình: 0
đã ghi: global.toml, combat.toml, monster.toml, character.toml, new_character.toml, instances.toml
```

```text
python -W error TOOLS/server/lint_config.py SERVER/config/rules/global.toml SERVER/config/rules/combat.toml SERVER/config/rules/character.toml SERVER/config/rules/new_character.toml SERVER/config/rules/monster.toml SERVER/config/rules/instances.toml
```

`6 tệp sạch, 93 cài đặt đều có chú thích và thẳng cột`.

Năm bảng C-04 được xuất vào `build/p1-b/c04-out` bằng `export_legacy` (1,936 giây, không lỗi) rồi chép đè năm tệp và năm tệp cột. Dòng tổng kết của năm bảng:

```text
scene_hosting.tsv: bản ghi 923, cột 5, tên thật 5, cột ? 0, cắt chú thích ini 3, dòng ngoài số khai báo 200
scenes.tsv: bản ghi 923, cột 11, tên thật 10, cột ? 1, cắt chú thích ini 10, dòng ngoài số khai báo 200, cột text toàn số: clientres, pvp_ruler
rolling_announcements.tsv: bản ghi 10, cột 3, tên thật 3, cột ? 0, cắt chú thích ini 2, dòng ngoài số khai báo 10
scheduled_events.tsv: bản ghi 30, cột 14, tên thật 14, cột ? 0, cắt chú thích ini 181, dòng ngoài số khai báo 30
random_shop_goods.tsv: bản ghi 458, cột 10, tên thật 9, cột ? 1, cắt chú thích ini 2167, dòng ngoài số khai báo 1
```

Cột cuối của cả năm bảng trên cây `SERVER/tables/server` là `within_declared_count`. `rolling_announcements.tsv` không còn `broadtime` hay `broadcount`. `scheduled_events.tsv` không còn `huodongcount`.

## 3. Số đo

`legacy_rules.tsv`: 578 dòng khoá. Cộng: luật 131, tiến trình 26, bỏ 9, chưa rõ 412.

Nguồn, đếm bằng chính bộ đọc của `import_rules.py`: `ConfigInfo.ini` 212, `DefaultChar.ini` 83, `PetConfigTable.ini` 246, `DarkConfigTable.ini` 15, `CopyScene.ini` 5, `CombatLimits.ini` 7, `SystemInfo.ini` chỉ section `[info]` 3 khoá, `MergeConfig.txt` 7 bản ghi theo cột KEY. Tổng 578.

Sáu tệp luật, 93 cài đặt kể cả `schema`. Bảy tệp chưa sinh: `pet.toml`, `hidden_weapon.toml`, `pvp.toml`, `guild.toml`, `social.toml`, `economy.toml`, `fatigue.toml`.

Năm bảng đổi cột, số bản ghi không đổi so với đợt 1. `scenes` 11 cột, `scene_hosting` 5, `rolling_announcements` 3, `scheduled_events` 14, `random_shop_goods` 10.

`within_declared_count` là 1 khi chỉ số section nhỏ hơn số khai báo. Trên dữ liệu thật: cảnh 0 tới 722 là 1, cảnh 723 tới 922 là 0; cả 10 thông báo và 30 sự kiện là 0 vì `broadcount=0` và `huodongcount=0`; cửa hàng ngẫu nhiên có đúng 1 dòng 0.

## 4. Bảng nợ

| Mã | Trạng thái | Chứng |
|---|---|---|
| C-03 | Đã trả | Tách hàm ở lượt trước, treehash trùng mốc. Lượt này hết dòng dài hơn 120 và hết hàm thiếu kiểu trong bốn tệp của B. `lint_py.py` trên bốn tệp thoát 0. |
| C-04 | Đã trả | Năm bảng có `within_declared_count`. Đã bỏ `broadtime`, `broadcount`, `huodongcount`. Ba khoá `[info]` nằm trong `global.toml`. Test thật kiểm cảnh 722/723 và đếm 1 dòng cửa hàng ngoài số khai báo. |
| C-06 | Đã trả | `test_import_legacy.py` và `test_import_rules.py` bắt stdout và stderr của `main`, kể cả `--nope`. Output lượt test chỉ còn dòng `unittest`. |
| C-07 | Đã trả ở lượt tách hàm | `_foreign` gọi `tsv_file.owned_tool`. |

`prepare_directory` của thư mục bảng truyền `keep_tools=("scene_refs.py",)`. Thư mục cột không truyền, vì `scene_load_refs.tsv` không nằm ở đó.

## 5. Khoá theo fate

Luật 131, tiến trình 26, bỏ 9, chưa rõ 412. Lệch giá trị ini với mười một tệp TOML tiến trình: 0.

Chín khoá bỏ, lý do đúng câu trong phụ lục hoặc chú thích của chính khoá: `PrenticeProfferExp`, `RecoverTime`, `DefaultRespawnTime`, `DefaultAIType`, `DefaultRefuseScanTime`, `[Portal] MaxCount`, `[SkillObj] MaxCount`, `[Temp] UserPath`, `Human.DefaultRefreshRate`.

Hai khoá unknown theo phụ lục mục 3, để mốc P3, không xuất: `TimeSetting.SMUKickUserTime`, `CacheLogTime.LogInCacheTime`.

412 khoá unknown còn lại mang `reason` là `chưa làm ở đợt 2`. Nhóm theo tệp:

- `ConfigInfo.ini` 132: `[Guild]` 52, `[Pet]` 17, `[GoodBad]` 11, `[CommisionShop]` 11, `[Economic]` 7, `[MinorPassword]` 6, `[GuildLeague]` 3, `[Relation]` 3, `[Duel]` 3, `[Team]` 2, `[JuqingPoint]` 2, `[ActiveRichesCard]` 2, `[PK]` 2, `[PlayerShop]` 1 (`PaymentPerHour`), `[Warfare]` 1, `[FightBack]` 1, `[Fatigue]` 4, `[EnableYuanBaoPiao]` 1, `[AntiCheat]` 1, cộng hai khoá P3 ở trên.
- `DefaultChar.ini` 12: `[baseinfo] camp`, `[attribute]` `str`, `spr`, `con`, `int`, `dex`, `[xinfa] number`, `[startscene]` `scenecount`, `scene0`, `scene1`, `scene2`, `[private] luckword`.
- `PetConfigTable.ini` 246, cả tệp.
- `DarkConfigTable.ini` 15, cả tệp.
- `MergeConfig.txt` 7: `Procreate`, `Guild`, `City`, `PShop`, `Commision`, `YBCash`, `YBUse`.

Danh sách từng khoá là các dòng `fate=unknown` trong `TOOLS/server/legacy_rules.tsv`.

## 6. Chưa kiểm

Chưa chạy `unittest discover` cả `TOOLS/server`. A và C đang sửa tệp của họ; discover có thể đỏ vì việc của họ, không chứng minh được phần B.

Chưa chạy `lint_config.py` không tham số trên cả `SERVER/config`. Đã kiểm sáu tệp luật. Không đụng mười một tệp tiến trình.

Chưa chạy `build_data.py`. Không xuất lại 64 bảng kia; chúng không đổi cột ở đợt này.

## 7. Giả định

Chỉ số section nhỏ hơn số khai báo thì `within_declared_count` là 1. `scenenumber=723` nên cảnh 0 tới 722 được nạp. `Total=9` với `Merchandise0` tới `Merchandise9` thì chỉ số 9 là 0.

`SystemInfo.ini` chỉ đưa section `[info]` vào bảng luật. Các section `broadN` và `huodongN` vẫn là bản ghi TSV, không phải cặp khoá luật.

`MergeConfig.txt` đếm 7 giá trị cột KEY, bỏ hai dòng đầu kiểu và tên cột.

Số thực chia hết cho 0,001 thì ghi phần nghìn. Toạ độ `165.0` thành `165000` ở khoá có hậu tố `_permille`.

`1` và `0` của khoá tiến trình kiểu bool được so với `true` và `false`. Lần chạy này không lệch.

## 8. Lệch quy tắc

Không. Bốn tệp Python của vai B qua `lint_py.py`. Sáu TOML qua `lint_config.py`.

## 9. Chỗ tài liệu không khớp đĩa

`CharConfig.cpp` của mã 2008 đọc `camp_%d`, không đọc `baseinfo.scene`. Tệp 0859602 có `baseinfo` và `startscene`, không có section `camp_N`. Khoá có chú thích hoặc có đúng lời `ReadInt` thì vào `new_character.toml`. Mười hai khoá không có căn cứ đó để `unknown`.

`Config.cpp` đọc `TimeSetting.DisconnectTime`. Tệp 0859602 có `DisconnectTime1` và `DisconnectTime2`. Map sang `linger_after_disconnect_ms` và `linger_hidden_ms` theo chú thích và vì giá trị bằng đúng toml. Không có dòng lệch.

`Human.DefaultAttackSpeed`: chú thích nói chỉ nạp, không nơi nghiệp vụ đọc, nhưng `Config.cpp:125` vẫn gán `m_DefaultAttackSpeed`. Phụ lục đưa tốc độ đánh vào `character.toml`, nên khoá này là luật, chú thích ghi cả hai điều.

`Pet.PetBodyTime` cũng ghi chỉ nạp, nhưng không nằm trong danh sách bỏ của phụ lục. Chưa làm `pet.toml` nên để `unknown`, không tự xếp vào bỏ.
