# Đề bài P1 đợt 3: tên cột, độ phủ tham chiếu, `thienlong_lint`

Soạn ngày 2026-10-07 cho Grok Build. Người kiểm cuối là Claude; người duyệt là chủ dự án.

## 1. Việc này là gì

Đợt 2 đã được nhận: Claude chạy lại đủ T1 tới T10 và ra cùng kết quả, cùng mã SHA-256. Đợt 3 làm bốn
việc để đóng mốc P1 của `docs/KE-HOACH-SERVER.md`:

1. Trả nợ đợt 2 (mục 2).
2. Đặt tên tiếng Anh cho cột của 69 bảng máy chủ và của các bảng client có bản 0859602 đối chiếu.
3. `diff_tables.py`: đo hiệu id giữa bản 2026 và bản 0859602, và độ phủ tham chiếu giữa các bảng.
4. `thienlong_lint`: exe C++ đầu tiên của máy chủ, đọc cây `SERVER/` bằng chính
   `game::table::parse_tsv`. Đây là lần đầu dữ liệu đã sinh được đọc bằng bộ đọc thật.

Cách tổ chức như hai đợt trước: bạn là phiên chính L; A, B, C viết mã song song; R review trong phiên
mới không thừa hưởng ngữ cảnh của người viết; rồi đối chất chéo; L ghi `KET-QUA.md`. Giao việc cho
subagent bằng đường dẫn tệp này và tên vai, không kể lại bằng lời của bạn. Làm trực tiếp trong
`F:\tl 2026\THIENLONG`, không dùng worktree.

Đọc trước khi viết mã, theo thứ tự:

1. Tệp này.
2. `docs/giao-viec/P1-DOT-1/DE-BAI.md`: mục 3, 4, 6, 7, 8, 9, 11. `docs/giao-viec/P1-DOT-2/DE-BAI.md`:
   mục 5 (cổng `lint_py.py`, luật test, bảng soạn tay) và mục 6. Các mục đó vẫn có hiệu lực.
3. `docs/giao-viec/P1-DOT-2/KET-QUA.md` và `REVIEW.md`.
4. `AGENTS.md` của dự án; `docs/KE-HOACH-SERVER.md` mục 5 và mục 9; `docs/SERVER-TEP-CAU-HINH.md`
   mục 1 (quy tắc đặt tên và bảng thuật ngữ).
5. Vai C và R đọc thêm trọn mục 2 tới mục 11 của `AGENTS.md` (luật C++ của dự án, lệnh kiểm, bẫy đã
   biết), rồi `SRC/table/tsv.hpp`, `SRC/io/file.hpp`, `SRC/sealtool/main.cpp`, `tests/test.hpp`,
   `tests/look_tests.cpp`.

Quy định áp cho đợt này là `AGENTS.md` của dự án. Công cụ dữ liệu viết bằng Python 3.13; tệp TOML
căn cột bằng `config_style`. Mã C++ theo trọn `AGENTS.md`, không có ngoại lệ nào cho máy chủ.

## 2. Kết quả kiểm đợt 2 và nợ phải trả

Claude chạy lại bằng lệnh của mình:

- T1 173 test xanh, 8 bỏ qua. T2 173 test xanh trong 458,6 giây, không bỏ qua. T5, T6 sạch (18 tệp
  TOML, 244 `scene.toml`).
- `build_data.py --digest` hai lần, đều thoát 0, cùng mã
  `d3ffb5bf6599f34f341cc19d10f7136eb48c1b277cebdbb1ae6041a25cbadb62`. Năm dòng `treehash.py` không
  đổi sau T2 và sau hai lần sinh.
- `verify_p1.py`: A, B, C, D đều 0 lệch.
- Script mới `docs/giao-viec/P1-DOT-2/kiem-claude/verify_p2.py` (đọc và chạy được, không sửa), không
  dùng mã của bạn: 578 khoá phủ kín; 131 khoá `rule` và 26 khoá `process_config` bằng giá trị trong
  TOML; không cài đặt TOML nào thiếu dòng nguồn. 250 lời gọi `LuaFnSetSceneLoad_*` trùng từng (tệp,
  dòng, loại) với phép quét lại; 140 `literal` trùng chuỗi trong mã. 1.897 cột đã ghép của 76 cặp
  bảng: tỉ lệ khớp tính lại trùng từng con số ghi trong `note`; không neo nào dưới 95%.
- `check_basis.py` cùng thư mục: 134 chỗ dẫn `code:` đều trỏ tới tệp có thật và dòng có thật. 95 chỗ
  khớp tự động với trường nêu ở `note`; 39 chỗ còn lại Claude đọc bằng mắt, đều là đoạn mã liên quan
  (dòng enum chỉ số cột, dòng `Skip`, dòng `ReadInt` dựng tên khoá bằng `sprintf`).
- Ranh giới ghi tệp sạch. Báo cáo trung thực, kể cả phần "chưa kiểm".

Nợ. Mã `D-` là finding của Claude ở đợt 2.

**D-01 (B): năm tên trong tệp luật trái bảng thuật ngữ ở mục 1 của phụ lục.** `character.toml`
`xinfa_max_level` (XinFa là `inner_art`) và `min_level_ingot_ticket` (YuanBaoPiao là
`ingot_voucher`); `combat.toml` `pk_refix` (Refix là `modifier`); `new_character.toml` nhóm
`[ability]` (Ability là `life_skill`); `instances.toml` nhóm `[copy]` (CopyScene là `instance`).

**D-02 (A, B): ba tên cột trái thuật ngữ.** `column_terms.tsv` `inner_art_refix_parameter` (A); cột
`pvp_ruler` của `tables/server/scenes.tsv` (B; Ruler là `rules`); cột `zhuandan_id` của
`tables/server/gacha_machines.tsv` (B; Zhuandan là `gacha`).

**D-03 (L): bảng thuật ngữ không có cổng.** Đợt 2 không ai đo nên các tên trên lọt qua. Viết
`lint_names.py` (mục 5.1). Claude thử luật N1 trên 3.554 tên hiện có, với mọi từ gốc của 53 dòng
thuật ngữ, và thấy ba nhóm:

- Vi phạm thật, sáu tên: `xinfa_max_level`, `pk_refix`, `[ability]`, `inner_art_refix_parameter`,
  `pvp_ruler`, `zhuandan_id`.
- Một tên phải xét: bảng đích `achievement_ability` (`ChengjiuAbility.txt` của bản 2026). A đọc bảng
  rồi đổi tên theo nghĩa, hoặc ghi ngoại lệ kèm lý do.
- Từ tiếng Anh thông dụng mà chính dự án đang dùng đúng nghĩa, đặt `banned` là 0: `task` (bảng
  thuật ngữ có `sect_task`; 9 tên), `variance` (`disrupt_time_variance_percent`), `mission` (phụ lục
  cho giữ ở bảng 2026; 7 tên).

Trên mã đầu đợt, cổng phải báo đúng bảy tên của hai nhóm đầu. `[copy]` và `ingot_ticket` không bắt
được bằng token; B sửa theo D-01.

**D-04 (B): đơn vị và toạ độ trong tệp luật.**

- Toạ độ không phải tỉ lệ. `pos_x_permille = 165000` sai tên và khác cách bảng cảnh ghi toạ độ.
  Dùng `position_x`, `position_z` kiểu số thực, cùng tên và cùng kiểu với `spawns.tsv`. Thêm
  `convert` loại `decimal`: kiểm bằng `decimal.Decimal`, ghi nguyên văn chữ số của nguồn (`165.0`).
  `_permille` và `_ppm` chỉ dùng cho tỉ lệ và hệ số.
- `[start_position]` có toạ độ mà không có cảnh: `scene0`, `scene1`, `scene2`, `scenecount` của
  `[startscene]` đang là `unknown`, nên ba điểm xuất phát không dùng được. Xem D-05.
- `pilfer_lock_time`: chú thích gốc ghi `(毫少)`, nhiều khả năng gõ nhầm của 毫秒. Đọc chỗ mã dùng
  giá trị rồi quyết tên. `[rolling_notice] interval`, `can_get_exp_range`, `default_move_speed`,
  `default_attack_speed`, `pk_refix` cũng chưa có đơn vị. Luật: chú thích gốc hoặc mã xác lập được
  đơn vị thì đơn vị nằm trong tên; không xác lập được thì `note_vi` kết thúc bằng câu `Đơn vị chưa
  xác lập.` Không đoán.

**D-05 (B): mười hai khoá `unknown` của `DefaultChar.ini`.** `[attribute]` `str`, `spr`, `con`,
`int`, `dex`; `[baseinfo] camp`; `[xinfa] number`; `[startscene]` `scenecount`, `scene0`, `scene1`,
`scene2`; `[private] luckword`. Thêm loại `basis` mới là `name`: tên khoá tự nó là một từ tiếng Anh
gọi đúng giá trị (`scene0`, `str`, `dex`, `camp`). Khoá như vậy được là `rule`, `note_vi` chỉ nói
điều cái tên nói. `luckword` không thuộc loại này; có căn cứ thì xếp, không thì giữ `unknown`.

**D-06 (C): `scene_load_refs.tsv` không cho biết tệp có trên đĩa không.** Claude đo: bốn dòng
`literal` của `event/fuben/efuben_3_shuilao.lua` (dòng 314, 318, 322, 326) trỏ tới
`shuilao_monster_15.ini`, `_25`, `_35`, `_45`, bốn tệp không có trong `Public/Scene`. Thêm cột số
nguyên `files_on_disk`: số tệp của `Public/Scene` khớp `resolved` (so tên không phân biệt hoa
thường; dòng `format` đếm trên mọi phương án cách nhau bằng `|`; dòng `unresolved` để trống). Và số
1.123, 221, 180, 80 của phép đối chiếu 1.344 tệp hiện chỉ nằm trong `DOI-CHAT-C.md`: ghi kết quả
thành bảng `SERVER/tables/server/scene_level_files.tsv`, mỗi tệp một dòng, cột `file`,
`scene_by_name`, `script_scenes` (cách nhau bằng `;`), `verdict` (`same`, `mismatch`, `unpointed`,
`map_unknown`), do `scene_refs.py` ghi trong cùng lượt. Claude chạy lại `compare_level_files` trên
mã cuối đợt 2 và ra đúng bốn số đó, nên bảng phải có 863 dòng `same`, 80 `mismatch`, 221
`unpointed`, 180 `map_unknown`.

**D-07 (B, C): ô số không ở dạng chính tắc.** Claude đo trên 4.014 tệp TSV của `SERVER/tables` và
`SERVER/scenes` (1.096.344 bản ghi, 22.013.470 ô): 265 ô cột `int` không khớp `-?(0|[1-9][0-9]*)`
và 26 ô cột `float` có khoảng trắng. Cụ thể: 200 ô `teleport_to_respawn` của các `patrols*.tsv` có
dấu cách cuối; 61 ô `script_id` của `spawns*.tsv` và 4 ô `script_id` của `areas*.tsv` có số 0 đứng
đầu (`040001`); 25 ô của `pet_ai_strategies.tsv` có dấu cách cuối (`0.50 `); 1 ô `position_x` của
một `platforms.tsv`. Bộ đọc gốc dùng `atoi` và `atof` nên đọc ra cùng số. Từ đợt này ô `int` ghi
dạng chính tắc của giá trị `atoi` đọc được, ô `float` bỏ khoảng trắng hai đầu; công cụ đếm số ô đã
đổi trong tổng kết. C sửa phần cảnh, B sửa `pet_ai_strategies.tsv`.

**D-08 (L, mọi vai): dọn dẹp và số liệu cũ trong báo cáo.** `docs/giao-viec/P1-DOT-2/kiem/` có
`__pycache__`; `build/` còn `p1c_xem_a.py` tới `p1c_xem_a5.py`, `tmpgxvjl6bu`, `tmpisv7u_xy`.
`BAO-CAO-A.md` và `BAO-CAO-C.md` của đợt 2 giữ số đo trước lần sửa. Đợt này: script kiểm chạy bằng
`python -B`; thư mục tạm xoá khi xong; mỗi báo cáo vai được cập nhật sau lần sửa cuối, số trong đó
là số của mã cuối. Không xoá các thứ cũ nêu trên của đợt 2 trừ `__pycache__` và thư mục `tmp*`
rỗng; liệt kê phần còn lại kèm dung lượng trong `KET-QUA.md`.

**D-09 (L, A, B): nhãn có sẵn định danh ASCII vẫn chưa có tên.** `PNUM(每组多少个)`,
`RepairType(修理类型)`, `ID(掉落包编号)`, `BoxValue(掉落包价值)` đều thành `column_<n>` vì
`english_name` chỉ nhận nhãn thuần ASCII. Luật M2 ở mục 5.1.

## 3. Số đo đầu đợt

Claude đo bằng script riêng. Công cụ của đợt phải tái hiện các số này ở bước 0; lệch thì tìm ra bên
nào sai trước khi đi tiếp, và ghi lại.

Cột chưa có tên (cột có `?` trong `note` hoặc tên dạng `column_<n>`), theo
`TOOLS/server/columns/`:

| Nhóm | Cột | Chưa tên | Nhãn rỗng | Nhãn chỉ chữ Hán | Nhãn có cả ASCII và chữ Hán | Nhãn chỉ ASCII |
|---|---|---|---|---|---|---|
| `shared` | 17.247 | 16.497 | 14.531 | 1.725 | 241 | 0 |
| `server` | 2.172 | 1.750 | 6 | 1.215 | 66 | 463 |
| `scenes` | 95 | 5 | 0 | 4 | 0 | 1 |

14.531 cột nhãn rỗng thuộc bảng chỉ có ở bản 2026 hoặc cột `mới ở 2026`; chúng nằm ngoài đợt này.
Gộp chữ số thành một ký hiệu thì nhãn chỉ chữ Hán còn 372 dạng ở `shared` và 408 dạng ở `server`.
Bảng nhiều cột chưa tên nhất: `shops` 2.456 (gộp bảng gốc và biến thể; riêng `shared/shops.tsv`
có 1.063 cột nhãn rỗng và 165 cột có nhãn chưa tên, như `PNUM(每组多少个)` 38 lần, `商品颜色` 35
lần), `drop_packages` 416, `item_attribute_value_ranges` 201, `gacha_item_pools` 200,
`item_segment_quality_rules` 191, `item_quality_odds` 101, `pet_skill_odds` 96, `effects` 75.

Hiệu id của 106 cặp bảng cùng tên (`public_config` `reference` so với bảng client), so nguyên văn ô
đầu: bản 2026 có 354.614 id, bản 0859602 có 62.374, chung 61.522, chỉ ở 2026 là 293.092, chỉ ở
0859602 là 852. Vài cặp: `monsters` 28.969 so với 9.535, chung 9.503; `skills` 4.586 so với 810,
chung 810; `items_common` 20.474 so với 4.947, chung 4.839; `equipment` 24.577 so với 13.639, chung
13.629.

Một tham chiếu mẫu: cột `type` của 1.577 tệp `scenes/*/spawns*.tsv` (40.168 dòng, 3.490 loại quái
khác nhau) trỏ vào `monster_id` của `tables/shared/monsters.tsv`: thiếu đúng một loại, `3364`, ở 10
dòng. Loại đó cũng không có trong `MonsterAttrExTable.txt` của bản 0859602.

Mã C++: `cmake --build --preset gcc-debug --target look_tests` dựng được; `ctest --preset gcc-debug
-R "^look_tests|layers"` xanh (đo 2026-10-07). `CMakeLists.txt` đang có thay đổi chưa commit của
phiên client; không ai làm việc ở `SRC/` từ 23:54 ngày 2026-10-06. `io::read_text` nhận tệp tới
256 MiB; bảng lớn nhất là `skill_levels.tsv`, 13,2 MB. Tên 244 thư mục cảnh đều là ASCII.

## 4. Việc của từng vai

Mỗi vai chỉ sửa tệp của mình (tệp vai đó đã tạo ở hai đợt trước và tệp mới nêu dưới đây). Trả nợ
trước, việc mới sau.

### L

Bước 0, một mình, xong hết rồi mới mở A, B, C:

- Ghi mốc vào `docs/giao-viec/P1-DOT-3/moc/`: `git-status.txt`, `treehash.txt`, `verify_p1.txt`,
  `verify_p2.txt` (`python -B docs/giao-viec/P1-DOT-2/kiem-claude/verify_p2.py`, cần
  `THIENLONG_LEGACY_ROOT`), và bản chép nguyên của `CMakeLists.txt` và `cmake/GameLayers.cmake`.
- `TOOLS/server/glossary.tsv`: bản máy đọc của bảng thuật ngữ ở mục 1 của phụ lục, soạn tay. Hiện
  bảng này nằm trong mã (`_TERMS` của `export_tables.py`); chuyển thành dữ liệu. Có test đọc bảng
  Markdown của phụ lục và so với tệp này, để hai bản không lệch nhau. Thấy phụ lục sai thì báo,
  không sửa phụ lục.
- `TOOLS/server/column_names.py` và test: một nơi đặt tên cột cho cả `export_tables.py` lẫn
  `import_legacy.py` (mục 5.1). Làm hai nấc. Nấc một chỉ dời mã (`english_name`, `_TERMS`, phần
  đánh số tên lặp của `export_tables.py`; `_snake`, `_named_columns` của `import_legacy.py`), cây
  đầu ra phải trùng `moc/treehash.txt` từng dòng. Nấc hai mới bật luật của mục 5.1, sinh lại, và ghi
  băm mới vào `moc/treehash-sau-buoc-0.txt`. Ở nấc hai L chuyển 270 dòng cũ của
  `column_terms.tsv` sang hình dạng mới mà không đổi phạm vi: mỗi dòng cũ thành một dòng cho từng
  bảng ưu tiên có nhãn đó, `scope` là tên tệp nguồn của bảng ấy, đúng phạm vi `_allow_terms` đang
  áp. Tên cột của các bảng khác vì vậy chưa đổi; mở dòng nào ra mọi bảng là việc của A.
- `TOOLS/server/lint_names.py` và test (D-03, mục 5.1).
- `TOOLS/server/table_refs.py` và test: đọc và kiểm hình dạng các tệp của `TOOLS/server/refs/` (mục
  5.2). Tạo ba tệp chỉ có phần đầu: `refs/shared.tsv` (của A), `refs/server.tsv` (của B),
  `refs/scenes.tsv` (của C).
- Thêm dòng cho bảng mới vào `table_names.tsv` (`scene_level_files.tsv`).

Bước 5: gắn `lint_names.py` và `diff_tables.py --check` vào `build_data.py`; chạy đủ mục 7; ghi
`KET-QUA.md`.

### A: tên cột bảng client có bản đối chiếu, và `diff_tables.py`

- Trả D-02 phần mình và tên bảng `achievement_ability` của D-03. Kiểm kết quả của D-09 trên bảng
  của mình.
- Mở rộng `column_terms.tsv` theo hình dạng mới của mục 5.1 cho nhãn của 106 cặp bảng: 1.725 cột
  nhãn chỉ chữ Hán và 241 cột nhãn lẫn. Các dòng cũ L đã gắn `scope` theo bảng: dòng có `basis` là
  `code:` giữ `scope` của bảng mà đoạn mã đó đọc; dòng mà nhãn chỉ có một nghĩa ở mọi bảng thì gộp
  lại thành một dòng `scope` rỗng. Làm theo thứ tự số cột giải được; dùng mẫu `{n}` cho nhóm cột
  lặp có số thứ tự trong nhãn.
- Viết `TOOLS/server/diff_tables.py` và test (mục 5.3).
- Soạn `TOOLS/server/refs/shared.tsv`: tham chiếu giữa các bảng của `tables/shared`. Ít nhất 12
  dòng, mỗi dòng có căn cứ theo mục 5.2. Bắt đầu từ mười một bảng ưu tiên của đợt 2 (kỹ năng, cấp kỹ
  năng, tâm pháp, quái, vật phẩm, hiệu ứng hình, đạn, đặc tính đánh, vật thể đặc biệt).
- Ô dữ liệu của `SERVER/tables/shared` và `variants` không đổi một byte; chỉ dòng tên cột đổi.

### B: tên cột bảng máy chủ, sửa tệp luật

- Trả D-01, D-02 phần mình, D-04, D-05, D-07 phần mình.
- Soạn `TOOLS/server/column_terms_server.tsv` (cùng hình dạng với `column_terms.tsv`) cho 69 bảng của
  `tables/server`: đầu đợt 2.172 cột, 1.750 chưa tên. 463 cột nhãn thuần ASCII phải có tên nhờ luật
  máy; nhãn nào luật máy không đặt được thì nêu lý do theo nhóm. Mã 2008 đọc phần lớn các bảng này
  (`GameTable.cpp`, `ItemTable.cpp`, `DataRecords.cpp`, `WorldTable.cpp`): có mã thì dẫn mã.
- Soạn `TOOLS/server/refs/server.tsv`: tham chiếu từ bảng máy chủ sang bảng máy chủ và sang bảng
  `shared`. Ít nhất 15 dòng. Ví dụ phải xét: `monster_drops` sang `drop_packages`; `drop_packages`
  sang các bảng vật phẩm; `effects` sang bảng mà cột logic của nó chỉ tới; `scene_hosting` sang
  `scenes`.
- Bảy tệp luật còn lại (`pet`, `hidden_weapon`, `pvp`, `guild`, `social`, `economy`, `fatigue`)
  không làm ở đợt này; 410 khoá giữ `unknown` kèm `reason` đổi thành `chưa làm ở đợt 3`.
- Mười một tệp TOML tiến trình của `SERVER/config` không đụng.

### C: `thienlong_lint`, tham chiếu của cảnh

- Trả D-06, D-07 phần mình.
- Soạn `TOOLS/server/refs/scenes.tsv`: tham chiếu của bảng trong `scenes/*/`. Ít nhất 6 dòng. Phải
  có dòng mẫu ở mục 3 (`type` sang `monster_id`, `known_missing` là 1), và phải xét: `script_id` của
  `spawns` và `areas` sang `script_index.tsv`; `patrol_id` của `spawns` sang `patrols.tsv` của cùng
  cảnh; cảnh đích của `portals.tsv` sang `tables/server/scenes.tsv`.
- Viết module `SRC/content/` và exe `thienlong_lint` (mục 5.4, 5.5): `SRC/content/*.hpp`,
  `SRC/content/*.cpp`, `SRC/linttool/main.cpp`, `tests/content_tests.cpp`. Sửa đúng hai tệp có sẵn,
  chỉ thêm dòng: `CMakeLists.txt` và `cmake/GameLayers.cmake`.

## 5. Hợp đồng thêm

Hợp đồng TSV, dòng lệnh, cổng `lint_py.py` và luật test của hai đợt trước giữ nguyên.

### 5.1 Tên cột và cổng thuật ngữ

Hai bảng thuật ngữ soạn tay, đọc gộp: `column_terms.tsv` (A) và `column_terms_server.tsv` (B). Cột:
`original`, `scope`, `name`, `basis`, `note`.

- `original`: nguyên văn nhãn. Có thể chứa `{n}` ở một hay nhiều chỗ; mỗi `{n}` khớp một dãy chữ
  số, và `name` phải chứa cùng số lượng `{n}`, điền theo thứ tự.
- `scope`: rỗng là mọi bảng; tên tệp nguồn (`ShopTable.txt`, `DropBoxContent.txt`) là chỉ bảng đó
  và thắng dòng `scope` rỗng. Khoá của bảng là cặp (`original`, `scope`); cùng khoá ở hai tệp mà
  `name` khác nhau là lỗi.
- `basis`: `glossary`, `direct`, hoặc `code:<tệp>:<dòng>` như đợt 2. Không chắc thì không thêm dòng.

Thứ tự đặt tên cho một nhãn, trong `column_names.py`:

1. Dòng thuật ngữ khớp nguyên văn, `scope` của bảng trước, `scope` rỗng sau.
2. Dòng thuật ngữ có `{n}`.
3. M1: nhãn là định danh ASCII, đổi `snake_case`, từng token đi qua `glossary.tsv` (đang có).
4. M2: nhãn là một định danh ASCII theo sau bởi phần giải thích trong ngoặc `(...)` hoặc `（...）`.
   Lấy định danh rồi làm như M1; phần trong ngoặc không dùng.
5. Còn lại: `column_<chỉ số>` và `?` trong `note`.

Hậu tố `$1$` bỏ như đang làm. Tên lặp trong một bảng: đánh số mọi lần xuất hiện theo thứ tự, từ 1
(`pnum_1`, `pnum_2`); luật này từ nay áp cho cả bảng máy chủ. Tệp cột ghi luật nào đã đặt tên.

`glossary.tsv`, soạn tay: `original` (từ của bản gốc, như `XinFa`; dòng của phụ lục có nhiều từ gốc
thì mỗi từ một dòng), `chinese`, `name`, `banned` (1 khi từ gốc không được xuất hiện trong tên mới;
0 khi từ gốc được giữ hoặc là từ tiếng Anh thông dụng dùng đúng nghĩa, như `Platform`, `Point`,
`Task`, `Variance`, `Mission`).

`python TOOLS/server/lint_names.py [--stats]`. Thoát 0 khi sạch, 1 khi có lỗi, mỗi lỗi một dòng
`tệp:dòng: nội dung`. Kiểm mọi khoá và tên nhóm của `SERVER/config/rules/*.toml`, mọi `name` trong
`TOOLS/server/columns/`, trong hai bảng thuật ngữ, và mọi tên tệp đích của `table_names.tsv`:

- N1: tách tên theo `_`; token nào, hoặc hai token liền nhau ghép lại, bằng dạng chữ thường của một
  từ `banned` thì lỗi (`xinfa`, `refix`, `copy_scene`, `copyscene`).
- N2: tên khớp `[a-z][a-z0-9_]*`, không có `__`, không kết thúc bằng `_`.
- Ngoại lệ cho từng tên đặt trong `TOOLS/server/name_exceptions.tsv` (`name`, `reason`), soạn tay.
  Ngoại lệ là cho một tên cụ thể có lý do; từ nào được dùng rộng thì đặt `banned` là 0.
- `--stats` in cho từng nhóm `shared`, `server`, `scenes` đúng sáu số của bảng ở mục 3.

### 5.2 Bảng tham chiếu `TOOLS/server/refs/*.tsv`

Soạn tay, hình dạng như `table_names.tsv`. Cột: `child`, `child_column`, `parent`, `parent_column`,
`absent`, `known_missing` (int), `basis`, `note`.

- `child`: đường dẫn tính từ gốc `SERVER`, dùng `/`. Có thể chứa `*`; mỗi `*` khớp một dãy ký tự bất
  kỳ, kể cả rỗng, trong đúng một đoạn đường dẫn, không vượt qua `/`. Không có `?`, không có `[]`.
  Mẫu không khớp tệp nào là lỗi.
- `parent`: một tệp. Hoặc có đúng một `*`, khi đó `child` cũng phải có `*`, và `*` của `parent` nhận
  đúng chuỗi mà `*` đầu tiên của `child` đã khớp (bảng cùng cảnh: `scenes/*/spawns*.tsv` sang
  `scenes/*/patrols.tsv`). Cảnh không có tệp cha thì mọi giá trị trỏ tới nó tính là thiếu.
- `child_column`, `parent_column`: tên cột thật. Không dùng tên dạng `column_<n>`: muốn tham chiếu
  thì đặt tên cột trước. Hai cột phải cùng kiểu, và không phải `float`.
- `absent`: các giá trị nghĩa là không trỏ tới đâu, cách nhau bằng `;` (thường `-1;0`). Ô rỗng luôn
  là không trỏ.
- `known_missing`: số giá trị khác nhau của cột con, sau khi bỏ `absent`, không có trong cột cha, đo
  trên dữ liệu hiện tại. Đây là số đo được ghi lại, không phải mục tiêu: công cụ đo khác số này, dù
  nhiều hơn hay ít hơn, là lỗi.
- `basis`: `code:<tệp>:<dòng>` (mã 2008 lấy giá trị cột này đi tra bảng kia); `label` (nhãn gốc của
  cột nói thẳng bảng đích, như `广播类型ID（Form DropNotify.txt）`); `data` (chỉ có số liệu: `note`
  phải ghi tỉ lệ đã đo, và tên cột phải gọi được thứ nó trỏ tới). So giá trị bằng nguyên văn ô.
- Cột cha phải là khoá: không giá trị lặp, không ô rỗng. Cột cha có giá trị lặp ngay trong dữ liệu
  gốc thì dòng đó không vào `refs/`; nêu bảng, cột và số giá trị lặp trong báo cáo.
- Bộ (`child`, `child_column`, `parent`, `parent_column`) không lặp trên cả ba tệp. Tệp đọc theo thứ
  tự tên tệp, dòng theo thứ tự trong tệp.
- Cần cột cha của vai khác mà cột đó chưa có tên: nêu trong báo cáo; L ghép ở bước 5.

### 5.3 `diff_tables.py`

`python TOOLS/server/diff_tables.py <tlbb> <gốc SERVER> [--refs <thư mục>] [--output <thư mục>]
[--check]`. Mặc định `--refs` là `TOOLS/server/refs`, `--output` là `TOOLS/server`. Ghi hai bảng:

- `table_id_diff.tsv`: mỗi cặp bảng cùng tên một dòng (106 dòng). Cột `source`, `target`,
  `ids_2026`, `ids_legacy`, `common`, `only_2026`, `only_legacy`. So id theo kiểu của cột đầu, như
  phép ghép dòng của `export_tables.py`. Tổng phải đối chiếu được với số ở mục 3; chỗ khác vì so
  theo kiểu thay cho nguyên văn thì nêu từng bảng.
- `table_ref_coverage.tsv`: mỗi dòng của `refs/` một dòng, cùng thứ tự. Cột `child`,
  `child_column`, `parent`, `parent_column`, `child_files`, `child_rows`, `references` (số ô có trỏ,
  tức không rỗng và không thuộc `absent`), `distinct_values`, `missing_values` (số giá trị khác
  nhau bị thiếu), `missing_rows` (số ô mang giá trị thiếu), `first_missing` (tối đa năm giá trị
  thiếu nhỏ nhất, cách nhau bằng `;`; cột `int` xếp theo số, cột `text` xếp theo byte UTF-8).
  Với `parent` có `*`, mỗi cảnh tính riêng: `distinct_values` và `missing_values` đếm cặp (chuỗi mà
  `*` khớp, giá trị); `first_missing` ghi `chuỗi khớp:giá trị`, xếp theo chuỗi khớp (byte UTF-8) rồi
  theo giá trị.

`--check` không ghi tệp; thoát 1 khi một dòng `refs/` sai hình dạng, mẫu không khớp tệp nào, cột
không tồn tại, hoặc `missing_values` khác `known_missing`. Lệnh in tổng kết: số cặp, năm tổng của
bảng hiệu id, số dòng tham chiếu, số dòng có giá trị thiếu.

### 5.4 `thienlong_lint`

`thienlong_lint --root <gốc SERVER> --refs <thư mục refs> [--report <tệp>]`. Mã thoát: 0 khi không
lỗi, 1 khi dữ liệu có lỗi, 2 khi dòng lệnh sai. Đọc mọi `*.tsv` dưới `<gốc>/tables` và
`<gốc>/scenes`, theo thứ tự đường dẫn đã sắp. Mỗi lỗi một dòng `đường/dẫn/từ/gốc:dòng: nội dung`
bằng tiếng Việt; mỗi tệp in tối đa 20 lỗi rồi một dòng đếm phần còn lại. Cuối cùng in `tệp`, `bản
ghi`, `ô`, `dòng tham chiếu`, `lỗi`, mỗi số một dòng.

- K1, tệp: UTF-8 hợp lệ; không BOM; không `\r`; kết thúc bằng `\n`; trước dòng tên cột có đúng một
  dòng `# schema 1` và đúng một dòng `# types: `; `game::table::parse_tsv` đọc được.
- K2, cột: số kiểu bằng số cột; kiểu là `int`, `float` hoặc `text`; tên cột khớp
  `[a-z][a-z0-9_]*` và không lặp.
- K3, ô: ô `int` rỗng hoặc khớp `-?(0|[1-9][0-9]*)` và nằm trong miền `int32`; ô `float` rỗng hoặc
  là số thập phân hữu hạn dạng `-?(chữ số[.chữ số]|.chữ số)([eE][+-]?chữ số)?`, đọc trọn bằng
  `std::from_chars`; ô `text` không kiểm thêm.
- K4, khoá: cột cha của mỗi dòng `refs/` không có giá trị lặp và không có ô rỗng.
- K5, tham chiếu: đo như mục 5.3; `missing_values` khác `known_missing` là lỗi, câu lỗi ghi cả hai
  số và tệp `refs` cùng số dòng.

`--report <tệp>` ghi đúng các cột và các dòng của `table_ref_coverage.tsv`. Sau khi bỏ các dòng bắt
đầu bằng `#`, tệp này và tệp do `diff_tables.py` ghi phải trùng nhau từng byte: hai bản cài đặt độc
lập, một bằng Python, một bằng C++, cùng một kết quả. Vì vậy C không đọc mã của A để viết phần này,
và A không đọc mã của C; cả hai chỉ đọc mục 5.2 và 5.3. Chỗ nào đề bài chưa đủ rõ để hai bên ra
cùng byte thì hỏi L, L ghi câu trả lời vào `docs/giao-viec/P1-DOT-3/HOI-DAP.md` cho cả hai.

Đo và ghi vào báo cáo: thời gian chạy trên cây thật ở `msvc-release` và ở `clang-asan`, bộ nhớ đỉnh
ở `msvc-release`. Dự án chưa đặt ngân sách cho công cụ này; số đo là để đặt.

Ngoài phạm vi của exe ở đợt này: đọc TOML (cần module `config` và `tomlplusplus`, việc của P2),
`cmake --install` vào `SERVER/bin`.

### 5.5 Luật mã C++ của đợt

`AGENTS.md` là luật; dưới đây là những điều dễ trật nhất, không thay cho việc đọc nó.

- Bố cục: `SRC/content/` là module `game_content` (namespace `game::content`), chỉ phụ thuộc `core`
  và `table`. Nó nhận chữ và trả kết quả: không mở tệp, không in. `SRC/linttool/main.cpp` là nơi duy
  nhất đụng đĩa và màn hình, làm theo `SRC/sealtool/main.cpp` (đọc tệp qua `io/file.hpp`, in bằng
  `std::print`, đối số Windows qua `CommandLineToArgvW`, `<windows.h>` qua `core/win32.hpp`).
- CMake, chỉ thêm dòng: `game_module(content ...)` và `target_link_libraries(game_content PUBLIC
  game_table game_core)`; exe `thienlong_lint` trong khối `if(NOT CMAKE_CROSSCOMPILING)`, nối
  `game_content game_io game::warnings`, có `game_split_debug`; `game_test(content game_content)`;
  một test `server_data_lint` chạy exe trên `SERVER/` thật với `TOOLS/server/refs`, chỉ đăng ký khi
  `SERVER/tables/server` tồn tại. `cmake/GameLayers.cmake`: hai dòng `game_layer_content` và
  `game_layer_linttool`.
- Không sửa `SRC/table`, `SRC/io`, `SRC/core` hay bất cứ tệp nào khác của `SRC/`, `tests/`,
  `cmake/`. Không sửa `vcpkg.json`, `CMakePresets.json`, `.clang-format`, `.clang-tidy`. Thiếu thứ
  gì ở module có sẵn thì viết phần đó trong `content` và báo.
- Hình dạng mã: độ lồng điều khiển không quá 1 mỗi hàm; hàm không quá 40 dòng, không quá 5 tham số;
  chữ ký nằm trọn một dòng không quá 100 cột; `[[nodiscard]]` cho hàm trả giá trị; không `throw`;
  lỗi dự kiến là `std::expected`; dữ liệu từ tệp không đi vào `core::check`, `assert`, `.at()`. Số
  đọc bằng `std::from_chars`, không `atoi`, không `stoi`. Comment tiếng Việt, không comment cuối
  dòng, không căn thẳng cột.
- Tất định: thứ tự in và thứ tự dòng báo cáo không phụ thuộc thứ tự của `unordered_*` hay thứ tự hệ
  tệp trả về.
- Test đỏ trước: `tests/content_tests.cpp` có ít nhất một ca sai và một ca đúng cho mỗi luật K1 tới
  K5, cho phép khớp `*`, cho biên `int32` và cho thứ tự của `first_missing`. Dán lần chạy đỏ vào báo
  cáo. Dữ liệu test là chuỗi trong mã, không phải tệp.
- Lệnh kiểm, chạy ở gốc dự án, cho từng preset `gcc-debug`, `clang-asan`, `msvc-release` (preset
  MSVC chạy trong `dev.bat` như mục 3 của `AGENTS.md`):
  `cmake --preset <p>`, `cmake --build --preset <p> --target thienlong_lint content_tests
  header_check`, `ctest --preset <p> -R "^(content_tests|layers|server_data_lint)$"`. Rồi
  `python ~/.claude/cpp23/tools/check.py <mọi tệp C++ mới>`.
- Cây làm việc có thay đổi chưa commit của phiên client. Target nào khác của dự án không dựng được
  thì ghi tên target và dòng lỗi đầu vào báo cáo, không sửa.

## 6. Ranh giới và các bước

Ranh giới như mục 8 của đề bài đợt 1 và mục 6 của đề bài đợt 2, với các thay đổi:

- Được tạo mới: `SRC/content/`, `SRC/linttool/`, `tests/content_tests.cpp`,
  `TOOLS/server/refs/`, và các tệp mới nêu ở mục 4.
- Được sửa bằng cách chỉ thêm dòng: `CMakeLists.txt`, `cmake/GameLayers.cmake`. So với bản chép ở
  `moc/`, không dòng cũ nào bị xoá hay đổi.
- Thư mục báo cáo là `docs/giao-viec/P1-DOT-3/`. Hai thư mục đợt trước chỉ đọc, trừ việc dọn nêu ở
  D-08.
- Không sửa `AGENTS.md`, `docs/*.md`, `SERVER/README.md`, mười một tệp TOML tiến trình,
  `setup_db.py`, `config_style.py`, `lint_config.py`. Git chỉ dùng lệnh đọc. Không commit.
- Không mở, không in, không chép `Server\Config\Account.txt` và `SERVER/config/secrets.local.toml`.

Các bước như mục 9 của đề bài đợt 1, với các thay đổi sau.

Bước 1: mỗi vai trả nợ trước, chạy test của mình, rồi làm việc mới. Vai đổi tên cột thì chạy lại
`verify_p1.py` phần của mình: ô dữ liệu không được lệch.

Bước 2, R review. Như đợt 2, thêm:

- Lấy mẫu ngữ nghĩa, hạt giống 20261008: 40 dòng mới của `column_terms.tsv`, 40 dòng của
  `column_terms_server.tsv`, 15 dòng của `refs/`. Mở đúng căn cứ ghi ở `basis`, xếp `đúng`, `sai`,
  `không đủ căn cứ`, ghi cả ba con số.
- Với mỗi tệp `refs`: tự chọn hai dòng, tự viết script đếm lại `missing_values` mà không dùng
  `diff_tables.py` hay `thienlong_lint`.
- Với mã C++: chạy `check.py` và ba preset; chép `SERVER/tables/server` và hai thư mục cảnh sang
  `build/`, cấy vào đó năm lỗi (BOM, `\r`, ô `int` có số 0 đứng đầu, khoá cha lặp, một giá trị trỏ
  hụt) và xác nhận exe báo đủ năm, mỗi lỗi đúng tệp và đúng dòng; đọc mã tìm chỗ dữ liệu từ tệp có
  thể làm chương trình dừng hay đọc ngoài biên, thử bằng tệp cụt, tệp rỗng, dòng thiếu ô.
- So `--report` của exe với `table_ref_coverage.tsv`.

Bước 4, R phán quyết trên mã cuối: chạy lại đủ T1 tới T14 sau mọi lần sửa.

## 7. Tiêu chí đạt

`<tlbb>` và `<_raw>` như đợt 1. Lệnh chạy ở gốc dự án.

| Mã | Lệnh hoặc phép kiểm | Đạt khi |
|---|---|---|
| T1 | `python -W error -m unittest discover -s TOOLS/server -p "test_*.py"`, không đặt biến | xanh; output chỉ có dòng của `unittest` |
| T2 | cùng lệnh, đã đặt hai biến | xanh, không test nào bị bỏ qua |
| T3 | `python -W error TOOLS/server/build_data.py --legacy "<tlbb>" --raw "<_raw>"` | thoát 0; có tổng kết của `lint_names` và `diff_tables` |
| T4 | cùng lệnh thêm `--digest`, hai lần | hai mã bằng nhau; ghi mã vào `KET-QUA.md` |
| T5 | `python -W error TOOLS/server/lint_py.py` | thoát 0 |
| T6 | `python TOOLS/server/lint_config.py`, rồi cùng lệnh với mọi `scene.toml` | sạch |
| T7 | `treehash.py` trước và sau T2 | năm dòng băm không đổi |
| T8 | `verify_p1.py` và `verify_p2.py` | 0 lệch, trừ các dòng do thay đổi có chủ đích của đợt (ô đổi theo D-07, khoá đổi theo D-01, D-04, D-05): liệt kê từng nhóm kèm số ô và lý do, không sửa script |
| T9 | `python TOOLS/server/lint_names.py`, rồi `--stats` | thoát 0; không còn cột nào có nhãn khớp M1 hoặc M2 mà mang tên `column_<n>`; sáu số của từng nhóm ghi vào `KET-QUA.md` cạnh số đầu đợt |
| T10 | `python TOOLS/server/diff_tables.py "<tlbb>" SERVER --check` | thoát 0; 106 cặp; mọi dòng `refs/` khớp `known_missing`; ít nhất 12, 15 và 6 dòng ở ba tệp |
| T11 | ba preset ở mục 5.5 | dựng 0 cảnh báo; ba test xanh ở cả ba preset |
| T12 | `check.py` trên mọi tệp C++ mới | xanh |
| T13 | exe của preset `msvc-release`: `thienlong_lint --root SERVER --refs TOOLS/server/refs --report build/p1-l/cpp-coverage.tsv` | thoát 0, `lỗi` là 0; báo cáo trùng `table_ref_coverage.tsv` sau khi bỏ dòng `#` |
| T14 | `git status --short` so với `moc/git-status.txt`; `diff` hai tệp CMake với bản ở `moc/`; tìm `Account.txt` và mật khẩu | tệp mới chỉ ở chỗ được phép; hai tệp CMake chỉ thêm dòng; không có nội dung bí mật |

Tiêu chí không đạt thì ghi không đạt kèm output.

## 8. Báo cáo

Mọi tệp ở `docs/giao-viec/P1-DOT-3/`, cùng tên và cùng hình dạng như hai đợt trước: `BAO-CAO-A.md`,
`BAO-CAO-B.md`, `BAO-CAO-C.md`, `REVIEW.md`, `DOI-CHAT-A.md`, `DOI-CHAT-B.md`, `DOI-CHAT-C.md`,
`KET-QUA.md`, script kiểm của R ở `kiem/`, và `HOI-DAP.md` nếu có. Thêm:

- Bảng nợ: từng mã `D-` của mình, đã trả hay chưa, lệnh chứng minh.
- A và B: số cột có tên trước và sau, theo từng bảng; số dòng thuật ngữ theo `basis`; số cột được
  đặt tên bởi từng luật (thuật ngữ nguyên văn, mẫu `{n}`, M1, M2); danh sách nhãn còn `?` gộp theo
  dạng, kèm lý do.
- A: năm tổng của bảng hiệu id và mười cặp có `only_legacy` lớn nhất. B: ba tệp luật đã đổi, từng
  khoá trước và sau.
- A, B, C: từng dòng `refs` của mình kèm `missing_values`; dòng nào có giá trị thiếu thì nói thiếu
  cái gì và vì sao tin đó là dữ liệu gốc thiếu chứ không phải ghép sai cột.
- C: lần chạy test đỏ; output của ba preset; output của `check.py`; số đo thời gian và bộ nhớ; hai
  tệp CMake đã thêm những dòng nào.
- Mỗi báo cáo vai được cập nhật sau lần sửa cuối.

## 9. Ngoài phạm vi

Để các đợt sau: bảy tệp luật còn lại; cột nhãn rỗng của bảng chỉ có ở bản 2026; 91 tên bảng còn
`?`; đọc TOML bằng C++ và module `config`; `cmake --install` vào `SERVER/bin`; `ai_convert.py`,
`lua_extract.py`, `bake_nav.py`; định dạng `.path`, `.stall`, `.ObjRegion`; chuyển tệp cảnh giữa các
thư mục cảnh; dịch nội dung bảng sang tiếng Việt; commit.

Thấy vấn đề ngoài phạm vi thì ghi vào báo cáo, không tự sửa.
