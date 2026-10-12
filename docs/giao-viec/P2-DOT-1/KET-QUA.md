# Kết quả P2 đợt 1

Làm trực tiếp trong `F:\tl 2026\THIENLONG`. Không worktree. Không commit.

A, B, C được giao bằng subagent và chết vì HTTP 402 (hết hạn mức Grok Build) trước khi viết `BAO-CAO-*.md`. Mã dở của họ nằm trên đĩa và được nối tiếp trong phiên L. R không chạy. Không có `REVIEW.md`, không có đối chất chéo, không có phán quyết của R. Không bịa phán quyết.

POSIX của `process` đã port, máy này không dựng. Xem `NGUON.md`.

## 1. Tiêu chí

`<tlbb>` là `C:\Users\myhea\Desktop\New folder\TLBB_0859602_Win10_11\tlbb`. `<_raw>` là `F:\tl 2026\_raw`.

| Mã | Kết quả | Lệnh và output |
|---|---|---|
| T1 | Đạt | Không đặt hai biến. `Ran 216 tests in 1.106s`, `OK (skipped=8)`. |
| T2 | Đạt | Đã đặt hai biến. `Ran 216 tests in 943.708s`, `OK`, không bỏ qua. |
| T3 | Đạt | `build_data.py --legacy --raw` thoát 0 sau 288 giây. `tables/server` 71 tệp, 47804 bản ghi. `tables/shared` 574 tệp, 991160 bản ghi. `tables/variants` 61 tệp, 3765 bản ghi. `scenes` 3797 tệp, 54959 bản ghi. Luật 142, tiến trình 26, bỏ 9, chưa rõ 401, lệch tiến trình 0. `lint_names` và `diff_tables` nằm trong lệnh và không làm lệnh thoát khác 0. |
| T4 | Đạt | Cùng lệnh thêm `--digest`, hai lần, đều thoát 0. Cùng `sha256: 62a7295ea66e918a1a7b9dae16fdfcf6bea4f157af83f93cdfe8d73a2d590b6f`. |
| T5 | Đạt | `lint_py.py` thoát 0. |
| T6 | Đạt | `lint_config.py`: `18 tệp sạch, 247 cài đặt`. 244 `scene.toml`: `244 tệp sạch, 4623 cài đặt`. |
| T7 | Đạt | Năm dòng `treehash.py` trước T2 và sau T2 trùng nhau. Sau T3/T4 cây bảng và cột đổi vì E-01; cảnh không đổi. Số ở mục 2. |
| T8 | Đạt | `verify_p1.py` thoát 0. A: 635 bảng, 994925 bản ghi, 18636500 ô, vấn đề 0. B: 67 bảng, 41634 bản ghi, lệch 25 ô. C: 244 cảnh, 1577 bảng spawns, 40168 dòng, lệch 61 ô. D: 4731 tệp, vấn đề 0. `verify_p2.py` thoát 0, giá trị lệch 0. `verify_p3.py`: H lệch 0; J 4015 tệp, 1097688 bản ghi, 22019096 ô; L `files_on_disk` lệch 0; N ở mục 3. E-02 không làm lệch giá trị so với nguồn. |
| T9 | Đạt | `lint_names.py` thoát 0. |
| T10 | Đạt | `diff_tables.py --check` thoát 0. Cặp 106. Id 2026 là 354614, legacy 62374, chung 61522, chỉ 2026 là 293092, chỉ legacy là 852. Dòng tham chiếu 55, dòng thiếu 6. |
| T11 | Đạt | Bảy test `config_tests`, `process_tests`, `supervise_tests`, `content_tests`, `layers`, `server_data_lint`, `server_boot` đều xanh. gcc-debug 11,02 giây. clang-asan 83,80 giây (`server_data_lint` 81,04 giây). msvc-release 4,49 giây. Build các target đó kèm `header_check` thoát 0. Preset bật cảnh báo thành lỗi. |
| T12 | Không đạt | `check.py` trên `host.cpp`, `load.cpp`, `run.cpp`, `service.cpp`, `config_lint.cpp`, `server_boot_tests.cpp` còn clang-tidy (include-cleaner, complexity, initializer). GCC và Clang dịch được các tệp đó. Chưa chạy `check.py` hết mọi tệp C++ mới. |
| T13 | Không đạt hết | `build\msvc-release\thienlong_lint.exe --root SERVER --refs TOOLS\server\refs --report build\p2-l\cpp-coverage.tsv` thoát 0 trong 2523 ms. `lỗi` 0. `tệp` 4276, `bản ghi` 1097688, `ô` 22019096, `dòng tham chiếu` 55. Phần sau dòng `#` trùng `TOOLS/server/table_ref_coverage.tsv`, 5662 byte. Đỉnh working set lấy mẫu 20 ms là 146,4 MiB; private 144,5 MiB. Trần đề bài là 120 MiB. |
| T14 | Đạt | `server_boot` xanh trên cả ba preset. Ca khoá lạ: stderr `gate.toml:49: khoá lạ not_a_real_key`, thoát 2, không có dòng `started`. Ca đúng in 13 dòng ở mục 4. |
| T15 | Không đạt hết | Cài được tám exe vào `SERVER/bin`. `CLIENT/bin` không thêm exe máy chủ. PostgreSQL chỉ khởi động một lần. Giám sát in `started postgres` và sáu `started` rồi `ready` sau 1667 ms, rồi không dừng vì stdin `NUL` không được coi là đóng. L kết thúc tiến trình sau khoảng 245 giây. Job kéo theo postgres. `setup_db.py status` trước và sau đều `cụm không chạy`. Không chạy lần hai. Output ở mục 4. |
| T16 | Đạt, trừ bốn tệp rác | `git diff --no-index` ba tệp với bản `moc/`: số dòng bị xoá là 0. Tệp mới là các module đợt này và `docs/giao-viec/P2-DOT-1/`. Thêm bốn tệp không nằm trong danh sách được tạo: `process-red-err.txt`, `process-red-out.txt`, `supervise-red-err.txt`, `supervise-red-out.txt`. Không mở `secrets.local.toml` và `Account.txt`. |

## 2. Băm

Trước và sau T2, trước lần sinh E-01:

```text
SERVER/tables/shared: 574 tệp, 91894834 byte, 26b703f41f00d718
SERVER/tables/variants: 61 tệp, 2024610 byte, aa4814cb5bb29f01
SERVER/tables/server: 71 tệp, 8733477 byte, 66278d43f609cb0a
SERVER/scenes: 3797 tệp, 149646681 byte, 9cd767cd33c209f3
TOOLS/server/columns: 716 tệp, 1215679 byte, cc29aec1904121b8
```

Sau T4:

```text
SERVER/tables/shared: 574 tệp, 91895752 byte, 658139a20ca382a0
SERVER/tables/variants: 61 tệp, 2024612 byte, e91dda472b64bc5d
SERVER/tables/server: 71 tệp, 8733695 byte, 005bc6749037f2dc
SERVER/scenes: 3797 tệp, 149646681 byte, 9cd767cd33c209f3
TOOLS/server/columns: 716 tệp, 1216817 byte, cfc3b2bcd37b41f3
```

`sha256` của `tables` và `scenes`, hai lần `--digest`:

`sha256: 62a7295ea66e918a1a7b9dae16fdfcf6bea4f157af83f93cdfe8d73a2d590b6f`

## 3. Nợ E-01 tới E-03

E-01. Trước khi sinh lại, `verify_p3.py N` có 0 nhãn hai tên, nhưng token trong cột đã sinh còn `defense` 19, `ice` 9, `miss` 6, `agility` 13, `concentration` 16, `mana` 6, `regen` 4. Sau `build_data.py`:

`defense` 0, `ice` 0, `miss` 0, `agility` 0, `concentration` 0, `mana` 0, `regen` 0. Nhãn nguyên văn có hơn một tên: 0. Ngoại lệ N4 trong `name_exceptions.tsv`: 0. Còn `odds` 2; đề không đòi số đó về 0.

E-02. `legacy_rules.tsv` rồi `import_rules.py` ghi lại luật. `[attribute]` là `strength`, `spirit`, `constitution`, `intellect`, `dexterity`, chú thích có `basis Common/GameDefine_Attr.h` dòng 10 tới 14. `[inner_art] count`. `[start_position] scene = [2, 71, 72]` theo thứ tự `scene0`, `scene1`, `scene2`. `default_move_speed` giữ câu «mã chia cho 1000» và `Đơn vị chưa xác lập.` Số cài đặt 249 còn 247.

E-03. `content` đã tách, mỗi `.cpp` dưới 500 dòng. `thienlong_lint` đưa từng tệp. Báo cáo phủ trùng 5662 byte. Đỉnh bộ nhớ 146,4 MiB, trên trần 120 MiB. `SegmentStep` trong `path_glob.cpp` còn tên cũ.

E-04 đã xoá rác liệt kê trong đề ở phần trước của phiên này. Lần này không đo lại dung lượng.

## 4. T14 và T15

`server_boot` ca cấu hình thật, stdin ống đã đóng, thoát 0. Stdout:

```text
started store 0
started auth 0
started billing 0
started world 0
started zone 0
started gate
ready
stopped gate
stopped zone 0
stopped world 0
stopped billing 0
stopped auth 0
stopped store 0
```

Ca khoá lạ, stderr:

```text
gate.toml:49: khoá lạ not_a_real_key
```

T15, `setup_db.py status` trước: `cụm không chạy`.

`cmake --install build/msvc-release --component server --prefix SERVER` chép tám exe: `thienlong_server`, `thienlong_store`, `thienlong_auth`, `thienlong_billing`, `thienlong_world`, `thienlong_zone`, `thienlong_gate`, `thienlong_lint`. `CLIENT/bin` chỉ còn `thienlong_client.exe`.

`SERVER\bin\thienlong_server.exe --config SERVER\config`, stdin là `NUL`. Đo tới `ready` 1667 ms. Rồi tiến trình không dừng. Sau 245 giây L kết thúc nó. Mã thoát của bộ chạy là 4294967295. Stdout nhận được:

```text
started postgres
started store 0
started auth 0
started billing 0
started world 0
started zone 0
started gate
ready
```

Stderr rỗng. `setup_db.py status` sau: `cụm không chạy`. Không còn tiến trình `thienlong_*` hay `postgres`.

## 5. CMake

So với `moc/`, `vcpkg.json` thêm `tomlplusplus` trước `cgltf`. `CMakeLists.txt` thêm target TOML kiểu interface, module `config`, `process`, `supervise`, `service`, bảy exe, `server_boot`, `thienlong_test_child`, nguồn `content` tách file, `config_lint.cpp`, và `install` component `server`. Danh sách nguồn là tường minh, không còn `GLOB`. `GameLayers.cmake` thêm dòng tầng của các module mới và một dòng `game_layer_linttool` thứ hai để giữ nguyên dòng cũ. Không dòng nào của bản `moc/` bị xoá.

## 6. Bốn mục

Đã kiểm: T1 tới T11, T14, phần thoát 0 và báo cáo của T13, phần cài và trạng thái cụm của T15, diff ba tệp CMake.

Chưa kiểm: `check.py` sạch trên mọi tệp mới. Bản POSIX. R và đối chất. Đỉnh bộ nhớ dưới 120 MiB. Chuỗi `stopped` của T15.

Giả định: stdin `NUL` không phải ống đóng, nên `stop_requested()` không trả lời có. Ca T14 đóng ống thật nên dừng được.

Lệch quy tắc: T12 chưa xanh. T13 vượt trần bộ nhớ. T15 không in đủ 15 dòng và không tự thoát. Bốn tệp `*-red-*.txt` nằm ngoài danh sách được tạo.
