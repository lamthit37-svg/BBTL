# Kết quả P1 đợt 3

A, B, C làm song song, R là phiên mới. Không commit. Bước 0 của L xong trước khi mở ba vai. Cây cuối là cây sau đối chất và sau lần `build_data.py` của R ở bước 4.

## 1. Tiêu chí

Lệnh chạy ở gốc dự án. `<tlbb>` là `C:\Users\myhea\Desktop\New folder\TLBB_0859602_Win10_11\tlbb`. `<_raw>` là `F:\tl 2026\_raw`. Output đầy đủ của T1 tới T14 nằm ở mục Phán quyết trong `docs/giao-viec/P1-DOT-3/REVIEW.md`. Sau phán quyết, L chạy lại `treehash.py`, `lint_names.py --stats` và `lint_py.py`: ba lệnh khớp số trong phán quyết.

| Mã | Kết quả | Lệnh và output |
|---|---|---|
| T1 | Đạt | `python -W error -m unittest discover -s TOOLS/server -p "test_*.py"`, không đặt hai biến. `Ran 211 tests in 1.020s`, `OK (skipped=8)`. |
| T2 | Đạt | Cùng lệnh, đã đặt hai biến. `Ran 211 tests in 830.439s`, `OK`, không bỏ qua. |
| T3 | Đạt | `python -W error TOOLS/server/build_data.py --legacy "<tlbb>" --raw "<_raw>"` thoát 0 sau 262,9 giây. Có `lint_names:` và `diff_tables:`. `tables/server` 71 tệp, 47804 bản ghi. `tables/shared` 574 tệp, 991160 bản ghi. `tables/variants` 61 tệp, 3765 bản ghi. `scenes` 3797 tệp, 54959 bản ghi. `config/rules` 6 tệp. Cảnh `cells_rewritten` 266. Tệp cấp `863 / 80 / 221 / 180`. Luật 142, tiến trình 26, bỏ 9, unknown 401, lệch tiến trình 0. |
| T4 | Đạt | Cùng lệnh thêm `--digest`, hai lần, đều thoát 0. Cùng `sha256: 29a45614a089d6f506b7ffd4d178f365a1935862f7b6a01a28438d1561b8633f`. |
| T5 | Đạt | `python -W error TOOLS/server/lint_py.py` thoát 0. L chạy lại sau phán quyết, cũng thoát 0. |
| T6 | Đạt | `lint_config.py`: `18 tệp sạch, 248 cài đặt`. 244 `scene.toml`: `244 tệp sạch, 4623 cài đặt`. |
| T7 | Đạt | Năm dòng `treehash.py` trước T2, sau T2, sau T3 và sau hai lần T4 trùng nhau. L chạy lại sau phán quyết, vẫn năm dòng đó. |
| T8 | Đạt | `verify_p1.py` và `verify_p2.py` thoát 0. A: 635 bảng, 994925 bản ghi, 18636500 ô, lệch 0. B: 67 bảng, 41634 bản ghi, lệch 25 ô float của `pet_ai_strategies.tsv`. C: 244 cảnh, 1577 bảng spawns, 40168 dòng, lệch 61 ô `script_id`. D: 4731 tệp TSV, vấn đề 0. `verify_p2`: rule 142, tiến trình 26, bỏ 9, unknown 401, lệch giá trị 0. Phần G in 15 dòng tỉ lệ khác vì id cột đầu không chung (`AbilityExpTable.txt`, `Mission_NpcDefault.txt`), hệ quả X-CA-01, script vẫn thoát 0. |
| T9 | Đạt | `lint_names.py` thoát 0. `--stats` in ở mục 3. `M1/M2 còn column_n: 0`. 4015 tệp, int lệch 0, float có trắng 0. |
| T10 | Đạt | `diff_tables.py "<tlbb>" SERVER --check` thoát 0. Cặp 106. Id 2026 là 354614, legacy 62374, chung 61522, chỉ 2026 là 293092, chỉ legacy là 852. Dòng tham chiếu 55, dòng thiếu 6. `refs/shared.tsv` 25 dòng, `refs/server.tsv` 24, `refs/scenes.tsv` 6. |
| T11 | Đạt | `gcc-debug`, `clang-asan`, `msvc-release`: dựng thoát 0, `ctest` `content_tests`, `layers`, `server_data_lint` là 3/3. Log dựng không có cảnh báo. |
| T12 | Đạt | `check.py` trên bốn tệp C++ mới: `4 tệp, 0 lỗi.` |
| T13 | Đạt | `thienlong_lint` của `msvc-release` thoát 0 trong 2278 ms. `lỗi` là 0. `tệp` 4015, `bản ghi` 1097688, `ô` 22019096, `dòng tham chiếu` 55. Sau khi bỏ dòng `#`, báo cáo trùng `table_ref_coverage.tsv`, 5662 byte. |
| T14 | Đạt | `git status --short` so với `moc/git-status.txt` thêm đúng bốn dòng: `M cmake/GameLayers.cmake`, `?? SRC/content/`, `?? SRC/linttool/`, `?? tests/content_tests.cpp`. L chạy lại sau phán quyết, cùng bốn dòng. Hai tệp CMake so với bản `moc/` không có dòng bị xoá. `CMakeLists.txt` thêm khối `content` và `thienlong_lint`. `GameLayers.cmake` thêm hai dòng `game_layer_content` và `game_layer_linttool`. Không có `Account.txt` dưới `SERVER/`, `TOOLS/server/` và thư mục đợt. Không mở `Account.txt` và `secrets.local.toml`. |

## 2. Băm

Mốc đầu đợt, `moc/treehash.txt`, trước khi bật luật đặt tên:

```text
SERVER/tables/shared: 574 tệp, 91885649 byte, ec8f90ea675fb6f4
SERVER/tables/variants: 61 tệp, 2024362 byte, 03024419321c7627
SERVER/tables/server: 70 tệp, 8660785 byte, f666efecc8577cf0
SERVER/scenes: 3797 tệp, 149647004 byte, 7b13dc5b68556b0e
TOOLS/server/columns: 716 tệp, 1179128 byte, fbf28991cf95a421
```

Sau nấc 2 của bước 0, `moc/treehash-sau-buoc-0.txt`. Cảnh chưa đổi. Bảng và cột đổi vì luật M1, M2 và đánh số tên lặp trên bảng máy chủ:

```text
SERVER/tables/shared: 574 tệp, 91885397 byte, f25cb39630582c6a
SERVER/tables/variants: 61 tệp, 2024137 byte, 7bd12f7a889e4927
SERVER/tables/server: 70 tệp, 8660772 byte, ff907c20efc2b015
SERVER/scenes: 3797 tệp, 149647004 byte, 7b13dc5b68556b0e
TOOLS/server/columns: 716 tệp, 1194271 byte, 77ef3fe6e42fa54f
```

Cuối đợt, sau A, B, C và lần sinh của R. L chạy lại `treehash.py` và ra đúng năm dòng trong phán quyết:

```text
SERVER/tables/shared: 574 tệp, 91894834 byte, 26b703f41f00d718
SERVER/tables/variants: 61 tệp, 2024610 byte, aa4814cb5bb29f01
SERVER/tables/server: 71 tệp, 8733477 byte, 66278d43f609cb0a
SERVER/scenes: 3797 tệp, 149646681 byte, 9cd767cd33c209f3
TOOLS/server/columns: 716 tệp, 1215679 byte, cc29aec1904121b8
```

`sha256` của `tables` và `scenes`, hai lần `--digest` của R:

`sha256: 29a45614a089d6f506b7ffd4d178f365a1935862f7b6a01a28438d1561b8633f`

L không chạy lại `--digest`. Năm dòng `treehash` của `tables` và `scenes` vẫn là năm dòng R đo, nên đầu vào của mã này không đổi sau phán quyết.

## 3. Bước 0, đặt tên

Nấc 1 chỉ dời mã sang `column_names.py`. Cây thử `build/p1-d3-stage1` so với `SERVER/tables`, `SERVER/scenes`, `TOOLS/server/columns` và `SERVER/config/rules`: 0 tệp lệch.

Nấc 2 bật thứ tự mục 5.1. `column_terms.tsv` từ 270 dòng bốn cột thành 283 dòng năm cột. Mỗi dòng cũ thành một dòng cho từng bảng ưu tiên có đúng nhãn, `scope` là tên tệp nguồn. Không dòng nào bị bỏ vì không gặp bảng ưu tiên. Không dòng `scope` rỗng. A sau đó mới mở scope.

Cây thử `build/p1-d3-stage2` so với cây đang chạy lúc đó: ô dữ liệu của `tables` và `scenes` lệch 0. Luật TOML lệch 0. Cảnh lệch 0. 18 bảng đổi dòng tên cột. 858 ô `name` trong tệp cột đổi, 816 ô chỉ đổi `note`. `original` và `type` không đổi. Trong 858 tên đổi: 686 theo M1, 172 theo M2.

`glossary.tsv` có 65 dòng, một từ gốc một dòng, khớp bảng mục 1 của phụ lục. Test đọc Markdown và so với tệp. Phụ lục không sửa. `Mission` và `Task` không đổi thành `quest`: phụ lục nói bảng 2026 chưa đổi cột thì giữ mission. `KFS` vẫn có cờ chưa chốt vì phụ lục ghi `martial_soul (?)`.

Cổng N1 tách theo `_`, rồi ghép hai token liền kề. Ghép trùng tên chính thức đã bỏ gạch dưới thì không tính, nên `grow_point` hợp lệ và `copy_scene` vẫn lỗi. Trên cây đầu đợt, một token ra đúng bảy tên đề nêu. Thêm luật ghép thì có tên thứ tám, `zhuan_dan_id`, vì `zhuan` + `dan` là `zhuandan` mà tên chính thức là `gacha`. `[copy]` và `ingot_ticket` không bị bắt. Sau nấc 2, `ZhuandanID` thành `gacha_id`. Cuối đợt `lint_names.py` thoát 0.

Số đầu đợt ở mục 3 của đề và số `lint_names.py --stats` đo trên cây trước nấc 2:

| Nhóm | Cột | Chưa tên | Nhãn rỗng | Chỉ chữ Hán | ASCII và chữ Hán | Chỉ ASCII |
|---|---|---|---|---|---|---|
| shared, đề | 17247 | 16497 | 14531 | 1725 | 241 | 0 |
| shared, đo | 17247 | 16497 | 14531 | 1619 | 347 | 0 |
| server, đề | 2172 | 1750 | 6 | 1215 | 66 | 463 |
| server, đo | 2172 | 1750 | 6 | 1104 | 177 | 463 |
| scenes, đề và đo | 95 | 5 | 0 | 4 | 0 | 1 |

Cột, chưa tên, nhãn rỗng, chỉ ASCII, và cả hàng scenes trùng. Lệch nằm ở ranh chữ Hán và nhãn lẫn. `shops.tsv` riêng trùng đề: 1063 nhãn rỗng, 165 nhãn có chữ chưa tên. Định nghĩa đang dùng: chưa tên là `?` trong `note` hoặc tên `column_<n>`; nhãn rỗng là `original` chỉ có trắng; lẫn là có chữ Hán và có chữ Latin; chỉ ASCII là có chữ Latin và không có chữ Hán; phần còn lại của nhóm chưa tên, kể cả nhãn toàn chữ số, tính là chữ Hán. Không tìm được một ngưỡng độ dài chữ Latin nào vừa ra 1725/241 vừa ra 1215/66. Giữ định nghĩa này. Số cuối đợt, sau khi A và B đặt tên, là số T9:

```text
shared: cột 17247, chưa tên 14657, nhãn rỗng 14516, chỉ chữ Hán 140, ASCII và chữ Hán 1, chỉ ASCII 0
server: cột 2172, chưa tên 283, nhãn rỗng 6, chỉ chữ Hán 277, ASCII và chữ Hán 0, chỉ ASCII 0
scenes: cột 95, chưa tên 5, nhãn rỗng 0, chỉ chữ Hán 4, ASCII và chữ Hán 0, chỉ ASCII 1
```

Bảy nhãn ASCII của máy chủ còn `column_<n>` hoặc `?` ngay sau nấc 2: `Camp\Camp`, ba lần `Delta LvlNpc -LvlPlayer`, `Item Level`, `odds` thành `odds_lower`, `_clientres`. Bốn nhãn đầu không phải định danh. `odds` và `_clientres` là bố cục viết tay. B sửa hai cái sau ở đối chất. Cuối đợt nhóm server còn 0 cột chỉ ASCII chưa tên.

## 4. Bảng nợ

| Mã | Trạng thái | Chứng |
|---|---|---|
| D-01 | Đã trả | B đổi `xinfa_max_level`, `min_level_ingot_voucher`, `pk_modifier`, nhóm `[life_skill]`, nhóm `[instance]`. T9 thoát 0. |
| D-02 | Đã trả | A đổi `inner_art_refix_parameter` thành `inner_art_level_modifier_parameter`. B đổi `pvp_rules` và `gacha_id`. |
| D-03 | Đã trả | `lint_names.py` và `test_lint_names.py`. T9 thoát 0. `achievement_ability` đổi thành `achievement_life_skill.tsv` theo H2 trong `HOI-DAP.md`. Không có `name_exceptions.tsv`. |
| D-04 | Đã trả | Toạ độ xuất phát là `position_x`, `position_z`, giá trị `165.0` và `169.0`. R phán ĐÃ SỬA qua các finding của B. |
| D-05 | Đã trả | Mười một khoá `DefaultChar.ini` thành `rule` với `basis=name`. `luckword` vẫn `unknown`. Unknown cuối là 401. |
| D-06 | Đã trả | `scene_load_refs.tsv` có `files_on_disk`. `scene_level_files.tsv` có 863 `same`, 80 `mismatch`, 221 `unpointed`, 180 `map_unknown`. Bảng máy chủ từ 70 tệp lên 71. |
| D-07 | Đã trả | C: `cells_rewritten` 266, gồm 200 `teleport_to_respawn`, 65 `script_id`, 1 `position_x`. B: 25 ô float `pet_ai_strategies.tsv`. `verify_p1` liệt đúng 25 và 61. `scan_cells` cuối: int lệch 0, float có trắng 0. |
| D-08 | Đã trả | Xoá `docs/giao-viec/P1-DOT-2/kiem/__pycache__` lúc bước 0. Cuối đợt xoá `TOOLS/server/__pycache__` và `docs/giao-viec/P1-DOT-1/kiem/__pycache__` do các lần chạy không có `-B` tạo lại. Phần `build/` còn lại ở mục 6. |
| D-09 | Đã trả | M2 nằm trong `column_names.classify`. `RepairType` thành `repair_type`, `PNUM` thành `pnum_1` trở đi. T9: `M1/M2 còn column_n: 0`. |

## 5. Đối chất

R bước 2 nêu sáu finding. Xét chéo thêm mười ba. Bước 4 chạy lại T1 tới T14. Mười chín finding đều `ĐÃ SỬA`. Không có `BÁC`, không còn `CÒN MỞ`, không có `TRANH CHẤP`. Danh sách và lệnh R tự chạy lại nằm ở cuối `REVIEW.md`.

`build_data.py` gọi `lint_names.main(["--stats"])` rồi `diff_tables.main([legacy, dest, "--check"])` sau khi sinh. Test khế ước `BuildDataContractTest`: 7 ca, thoát 0. L không chạy ca sinh cả cây trong `test_build_data.py`; ca đó nằm trong T2 của R.

## 6. Phần build còn lại của đợt 2

Không xoá. Thư mục `tmp*` dưới đây có tệp, nên không phải thư mục rỗng.

| Đường dẫn | Byte |
|---|---|
| `build/p1c_xem_a.py` | 1555 |
| `build/p1c_xem_a2.py` | 1041 |
| `build/p1c_xem_a3.py` | 3423 |
| `build/p1c_xem_a4.py` | 1204 |
| `build/p1c_xem_a5.py` | 1581 |
| `build/tmpgxvjl6bu/stdout.txt` | 1012 |
| `build/tmpgxvjl6bu/stderr.txt` | 0 |
| `build/tmpisv7u_xy/stdout.txt` | 0 |
| `build/tmpisv7u_xy/stderr.txt` | 0 |
| `build/tmpo8e42u5c/stdout.txt` | 0 |
| `build/tmpo8e42u5c/stderr.txt` | 0 |
| `build/tmpwp8lps8u/stdout.txt` | 0 |
| `build/tmpwp8lps8u/stderr.txt` | 0 |

Cây thử `build/p1-d3-stage1` và `build/p1-d3-stage2` là bản sinh của bước 0. Giữ để đối chiếu.

## 7. Tệp theo vai

L: `glossary.tsv`, `column_names.py`, `lint_names.py`, `table_refs.py` và test, ba tệp `refs/*.tsv` lúc chỉ có phần đầu, dòng `scene_level_files.tsv` trong `table_names.tsv`, rồi đổi đích thành `achievement_life_skill.tsv`. `build_data.py` gắn hai cổng. `moc/` và `HOI-DAP.md`.

A: `column_terms.tsv`, `diff_tables.py`, `refs/shared.tsv`, tên cột `tables/shared` và `variants`.

B: `column_terms_server.tsv`, `refs/server.tsv`, sáu toml luật, bảng `tables/server` trừ phần cảnh của C.

C: `scene_refs.py`, `scene_level_files.tsv`, `refs/scenes.tsv`, `SRC/content/`, `SRC/linttool/main.cpp`, `tests/content_tests.cpp`, dòng thêm trong hai tệp CMake.

R: `REVIEW.md`, script trong `kiem/`.

Báo cáo: `BAO-CAO-A.md`, `BAO-CAO-B.md`, `BAO-CAO-C.md`, `DOI-CHAT-A.md`, `DOI-CHAT-B.md`, `DOI-CHAT-C.md`, `HOI-DAP.md`, `KET-QUA.md`.

## 8. Báo cáo bốn mục

Đã kiểm: đối chiếu byte nấc 1 (0 lệch) và ô dữ liệu nấc 2 (0 lệch). `lint_py.py` trên tệp L sửa, thoát 0. Test `column_names`, `glossary`, `lint_names`, `table_refs`, `table_names`, khế ước `build_data`: xanh trước khi mở A, B, C. Sau phán quyết: `treehash.py` trùng năm dòng mục 2, `lint_names.py --stats` trùng T9, `lint_py.py` thoát 0, `git status` thêm đúng bốn dòng T14, hai diff CMake không xoá dòng cũ.

Chưa kiểm: L không tự chạy lại T1, T2, T3, T4, T6, T8, T10, T11, T12, T13. Các lệnh đó là của R ở bước 4, output trong `REVIEW.md`. Vì `treehash` của `tables` và `scenes` không đổi sau phán quyết, L không chạy thêm `--digest`.

Giả định: output R dán trong mục Phán quyết là output của lệnh R ghi. Ba lệnh L chạy lại khớp phần cây và cổng tên.

Lệch: số chữ Hán và số nhãn lẫn đầu đợt không trùng bảng mục 3 của đề; định nghĩa ở mục 3 của tệp này. N1 có luật ghép hai token, nên cây đầu đợt có thêm `zhuan_dan_id` bên cạnh bảy tên đề nêu. `Mission` và `Task` không bị thay bằng `quest`. Phụ lục vẫn ghi `achievement_ability.tsv`; tên đang chạy là `achievement_life_skill.tsv`.
