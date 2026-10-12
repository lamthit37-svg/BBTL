# Báo cáo vai C — đợt 3

Làm trực tiếp trong `F:\tl 2026\THIENLONG`. Không worktree, không commit. Không sửa `glossary.tsv`, `column_names.py`, `lint_names.py`, `table_refs.py`, test của các tệp đó, `table_names.tsv`, `docs/giao-viec/P1-DOT-3/moc/`, `refs/shared.tsv`, `refs/server.tsv`. Không đọc `diff_tables.py`.

## 1. Tệp đã tạo hoặc sửa

- `TOOLS/server/scene_refs.py`, `TOOLS/server/test_scene_refs.py`: cột `files_on_disk`; ghi thêm `scene_level_files.tsv`.
- `TOOLS/server/export_scene.py`, `TOOLS/server/test_export_scene.py`: ô `int` của cảnh về dạng `atoi`, ô `float` bỏ trắng hai đầu, đếm `cells_rewritten`.
- `TOOLS/server/refs/scenes.tsv`: 6 dòng tham chiếu.
- `SERVER/tables/server/scene_load_refs.tsv`, `SERVER/tables/server/scene_level_files.tsv`: bản công cụ ghi ra `build/p1c-scene-out` rồi chép vào đây. `diff_tables.py --check` của vai khác đang đọc `SERVER`, nên không gọi `prepare_directory` trên `SERVER/tables/server`.
- `SERVER/scenes/`: xuất lại trong phiên, `cells_rewritten` 266.
- `SRC/content/lint.hpp`, `SRC/content/lint.cpp`, `SRC/linttool/main.cpp`, `tests/content_tests.cpp`.
- `CMakeLists.txt`, `cmake/GameLayers.cmake`: chỉ thêm dòng. `git diff --no-index` với `docs/giao-viec/P1-DOT-3/moc/` không có dòng cũ bị xoá hay đổi.

## 2. Nợ

D-06 đã trả. `python -B -W error TOOLS/server/scene_refs.py "<THIENLONG_LEGACY_ROOT>" build/p1c-scene-out` thoát 0 trong 15,88 giây:

```text
lời gọi: 250
chú thích bỏ qua: 5
how:
  constant 48
  format 50
  literal 140
  unresolved 12
tệp cấp: 1344
  same 863
  mismatch 80
  unpointed 221
  map_unknown 180
```

`efuben_3_shuilao.lua` dòng 314, 318, 322, 326 (`shuilao_monster_15/25/35/45.ini`) có `files_on_disk` 0. Dòng 312 (`_10`) là 1. Ô `unresolved` để trống. Dòng `format` đếm mọi phương án `|` bằng glob, không lọc mảnh dài 8 như `compare_level_files`.

D-07 phần cảnh đã trả. `RealSceneTest` (có `THIENLONG_LEGACY_ROOT`) khẳng định `cells_rewritten` 266, `int_not_canonical` 289, `padded_count` 24: 200 `teleport_to_respawn`, 65 `script_id`, 24 `PATROLPOINTNUM` (chỗ này không thành ô bảng). Ô `int` rỗng giữ rỗng. `pet_ai_strategies.tsv` là của B. `grep` `040001` trong `SERVER/scenes` không còn dòng.

## 3. `refs/scenes.tsv`

Sáu dòng, `missing_values` đo bằng `thienlong_lint --report` trên cây cuối (sha256 dưới đây).

- `spawns*.tsv` `type` → `monsters.monster_id`. `known_missing` 1. 1577 tệp, 40168 dòng, 40168 ô trỏ, 3490 giá trị, thiếu 1 giá trị ở 10 dòng: `3364`. `MonsterManager.cpp:311` gọi `GetExtAttr` theo `type`. `3364` không có trong cột `monster_id`.
- `spawns*.tsv` `script_id` → `script_index.script_id`, `absent` `-1`. Thiếu 2 giá trị, 2 dòng: `13021`, `13022`. 3500 ô trỏ, 1248 giá trị. `Obj_Monster.cpp:1098` chỉ gọi script khi id khác `INVALID_ID` (`-1`). `0` là id thật nên không đưa vào `absent`.
- `areas*.tsv` `script_id` → `script_index.script_id`, `absent` `-1`. Thiếu 0. 247 tệp, 382 dòng, 288 ô trỏ, 239 giá trị. `Obj_Human.cpp:924`: `(UINT)atoi("-1")` là `UINT_MAX`, không gọi script vùng.
- `portals.tsv` `target_scene_id` → `scenes.scene_id`. Thiếu 0. 2 tệp, 8 dòng, 8 ô trỏ, 7 giá trị (một cảnh đích lặp). 8/8 ô có trong `scene_id`. Mã 2008 không đọc portal, nên `basis` là `data`.
- `spawns*.tsv` `base_ai` → `monster_ai_types.ai_id`. Thiếu 0. 40168 ô trỏ, 14 giá trị, không có `-1`. `AI_Monster.cpp:1588` lấy AI theo `base_ai`.
- `spawns*.tsv` `ai_file` → `monster_ai_scripts.ai_id`, `absent` `-1`. Thiếu 1 giá trị, 1 dòng: `97`. 28233 ô trỏ, 114 giá trị. `AI_Monster.cpp:1548`: `-1` là không có kịch bản. `0` có trong bảng script nên vẫn là tham chiếu.

`patrol_id` của `spawns` không vào `refs/`. Cột cha cùng cảnh là `patrols*.tsv` `patrol_index`. Đếm lại trên cây cuối: 244 tệp, cộng số giá trị lặp trong từng tệp là 246. Mỗi đường có nhiều điểm nên khoá lặp. Đề mục 5.2: cột cha lặp thì không đưa vào `refs/`.

## 4. Test đỏ

Stub `content_tests` trước khi có K1–K5, sau khi đã chặn chỉ số rỗng. Exit `-1073740791` (`core::check` dừng). Ca đúng (`errors == 0`) qua vì stub chưa báo lỗi. Ca sai:

```text
./tests/content_tests.cpp:74: [k1_file_shape] đếm tệp và ô
./tests/content_tests.cpp:76: [k1_file_shape] BOM là lỗi
./tests/content_tests.cpp:78: [k1_file_shape] CR là lỗi
./tests/content_tests.cpp:80: [k1_file_shape] thiếu LF cuối
./tests/content_tests.cpp:82: [k1_file_shape] thiếu schema
./tests/content_tests.cpp:84: [k1_file_shape] parse_tsv từ chối
./tests/content_tests.cpp:86: [k1_file_shape] mẫu không khớp tệp
./tests/content_tests.cpp:92: [k2_columns] tên hoa là lỗi
./tests/content_tests.cpp:94: [k2_columns] tên cột lặp
./tests/content_tests.cpp:96: [k2_columns] kiểu lạ
./tests/content_tests.cpp:98: [k2_columns] thiếu kiểu
./tests/content_tests.cpp:109: [k3_int_bounds] số 0 đứng đầu là lỗi
./tests/content_tests.cpp:111: [k3_int_bounds] lỗi int đúng dòng dữ liệu
./tests/content_tests.cpp:113: [k3_int_bounds] vượt int32 dương
./tests/content_tests.cpp:115: [k3_int_bounds] vượt int32 âm
./tests/content_tests.cpp:125: [k3_float] dấu chấm trần là lỗi
./tests/content_tests.cpp:127: [k3_float] vô hạn là lỗi
./tests/content_tests.cpp:129: [k3_float] float có trắng là lỗi
./tests/content_tests.cpp:141: [k4_parent_key] khoá cha lặp
./tests/content_tests.cpp:147: [k4_parent_key] khoá cha rỗng
./tests/content_tests.cpp:165: [k5_missing] ghi số thiếu
./tests/content_tests.cpp:166: [k5_missing] ghi known_missing
./tests/content_tests.cpp:168: [k5_missing] lỗi K5 trỏ tệp refs
./tests/content_tests.cpp:172: [k5_missing] một dòng refs một dòng phủ
./tests/content_tests.cpp:175: [k5_missing] ô -1 không phải tham chiếu
./tests/content_tests.cpp:176: [k5_missing] một giá trị thiếu
./tests/content_tests.cpp:177: [k5_missing] một ô mang giá trị thiếu
./tests/content_tests.cpp:178: [k5_missing] giá trị thiếu đầu
./tests/content_tests.cpp:197: [star_and_order] * không vượt qua dấu /
./tests/content_tests.cpp:198: [star_and_order] cộng bản ghi mọi tệp con
./tests/content_tests.cpp:199: [star_and_order] hai giá trị khác nhau
./tests/content_tests.cpp:200: [star_and_order] thiếu 10
./tests/content_tests.cpp:211: [star_and_order] int xếp theo số, lấy năm
./tests/content_tests.cpp:229: [star_parent] đếm cặp cảnh và giá trị
./tests/content_tests.cpp:230: [star_parent] xếp theo cảnh rồi theo số
./tests/content_tests.cpp:232: [star_parent] báo cáo có schema
./tests/content_tests.cpp:234: [star_parent] báo cáo có dòng tên cột
./tests/content_tests.cpp:235: [star_parent] dòng phủ giữ nguyên mẫu
./tests/content_tests.cpp:254: check thất bại: content_tests: mọi ca phải qua
EXIT:-1073740791
```

Hai lỗi thật gặp sau khi stub đã xanh, sửa trước lần đo cuối:

- Nhiều dòng `refs` cùng một cột cha. Lần đi sau coi mọi khoá đã nạp là lặp. `server_data_lint` gcc in `lỗi: 444338` rồi thoát 1. Sửa: mỗi cặp (tệp, cột) chỉ duyệt một lần. Ca `hai dòng refs cùng cột cha` khoá việc này.
- `parent` không có `*` mà `distinct_values` vẫn đếm cặp (cảnh, giá trị). Bản `--report` lúc đó ghi `type` 6183 giá trị khác nhau. Mục 5.3 chỉ đếm cặp khi `parent` có `*`. Sửa xong, cùng cột là 3490. Ca `plain_distinct`: giá trị `9` thiếu ở hai cảnh vẫn là một giá trị thiếu, hai dòng.

## 5. Ba preset, sau lần sửa cuối

`cmake --build --preset <p> --target thienlong_lint content_tests header_check` thoát 0 ở cả ba. `header_check` đã dựng ở lượt có `lint.hpp` hiện tại; lượt cpp sau không dịch lại header. MSVC qua `dev.bat`.

`ctest --preset <p> -R "^(content_tests|layers|server_data_lint)$" --output-on-failure`:

gcc-debug, exit 0:

```text
1/3 Test #33: layers ...........................   Passed    0.20 sec
2/3 Test #34: content_tests ....................   Passed    0.23 sec
3/3 Test #35: server_data_lint .................   Passed    9.60 sec
100% tests passed out of 3
Total Test time (real) =  10.03 sec
```

clang-asan, exit 0:

```text
1/3 Test #42: layers ...........................   Passed    0.19 sec
2/3 Test #43: content_tests ....................   Passed    0.10 sec
3/3 Test #44: server_data_lint .................   Passed   90.76 sec
100% tests passed out of 3
Total Test time (real) =  91.06 sec
```

msvc-release, exit 0:

```text
1/3 Test #42: layers ...........................   Passed    0.20 sec
2/3 Test #43: content_tests ....................   Passed    0.12 sec
3/3 Test #44: server_data_lint .................   Passed    2.76 sec
100% tests passed out of 3
Total Test time (real) =   3.08 sec
```

`server_data_lint` đọc cả `refs/shared.tsv` và `refs/server.tsv`. Thoát 0 nên `known_missing` của A và B cũng khớp cây hiện tại.

Python, `THIENLONG_LEGACY_ROOT` đã đặt. Dấu chấm của unittest xen `echo` vì hai luồng stdout/stderr:

```text
..REFS_EXIT:0......
Ran 8 tests in 24.328s
OK
..................SCENE_EXIT:0.
Ran 22 tests in 5.432s
OK
LINT_EXIT:0
```

`lint_py.py` trên `scene_refs.py`, `test_scene_refs.py`, `export_scene.py`, `test_export_scene.py` không in dòng.

## 6. `check.py`

Lệnh, sau lần sửa cuối:

```text
python C:\Users\myhea\.claude\cpp23\tools\check.py SRC\content\lint.hpp SRC\content\lint.cpp SRC\linttool\main.cpp tests\content_tests.cpp
```

Exit 0. Bốn tệp đều đạt clang-format, độ lồng ≤ 1, g++ 16.2, clang 23.1, clang-tidy. `run_lint` đúng 40 dòng. Hàm dài khác ngắn hơn.

## 7. Thời gian và bộ nhớ

Cây cuối, `--root SERVER --refs TOOLS/server/refs --report <tệp>`. Đồng hồ là `ExitTime - StartTime` của tiến trình. Đỉnh là `PeakWorkingSet64`, lấy mẫu mỗi 5 ms lúc chạy.

msvc-release: exit 0, 2192 ms, đỉnh 250322944 byte (238,7 MiB).

clang-asan: exit 0, 79289 ms. Cùng lệnh trong ctest là 90,76 giây vì cộng cả phần ctest.

Cả hai in:

```text
tệp: 4015
bản ghi: 1097688
ô: 22019096
dòng tham chiếu: 55
lỗi: 0
```

Hai tệp `--report` trùng từng byte. SHA-256 `BB68402FC2DC994D9503376A82436BC81FFC8132A788A9DAF87597E9718E3CEE`. Nằm ở `build/p1c-msvc-coverage.tsv` và `build/p1c-asan-coverage.tsv`.

## 8. Dòng CMake đã thêm

`CMakeLists.txt`, sau `target_link_libraries(game_table ...)`:

```text
game_module(content SRC/content/lint.cpp)
target_link_libraries(game_content PUBLIC game_table game_core)
if(NOT CMAKE_CROSSCOMPILING)
    add_executable(thienlong_lint SRC/linttool/main.cpp)
    target_link_libraries(thienlong_lint PRIVATE game_content game_io game::warnings)
    if(WIN32)
        target_link_libraries(thienlong_lint PRIVATE shell32)
    endif()
    game_split_debug(thienlong_lint)
endif()
```

Sau test `layers`:

```text
game_test(content game_content)
if(NOT CMAKE_CROSSCOMPILING AND EXISTS "${PROJECT_SOURCE_DIR}/SERVER/tables/server")
    add_test(NAME server_data_lint COMMAND thienlong_lint
        --root "${PROJECT_SOURCE_DIR}/SERVER"
        --refs "${PROJECT_SOURCE_DIR}/TOOLS/server/refs")
endif()
```

`cmake/GameLayers.cmake`, sau `game_layer_table`:

```text
set(game_layer_content "core table content")
set(game_layer_linttool "core io content linttool")
```

## 9. Đã kiểm

- Unit Python cảnh và `lint_py.py`: mục 5, exit 0.
- `scene_refs.py` trên cây gốc: bốn số phán quyết và bốn dòng Thuỷ Lao.
- `content_tests` đỏ (mục 4) rồi xanh ở ba preset.
- `layers` và `server_data_lint` xanh ở ba preset.
- `check.py` bốn tệp, exit 0.
- Đo thời gian hai preset và bộ nhớ đỉnh `msvc-release`.
- Hai `--report` cùng sha256.
- Diff CMake với bản mốc: chỉ thêm dòng.

## 10. Chưa kiểm

- Chưa so `--report` với `table_ref_coverage.tsv`. Tệp đó chưa có trên đĩa. Không đọc `diff_tables.py`, không sửa báo cáo cho khớp mã của A.
- Chưa chạy `build_data.py` cả chuỗi. Việc đó đụng bước của A và B.
- Chưa cài `thienlong_lint` vào `SERVER/bin`. Đề để đợt sau.
- `run_lint` đếm tay là 40 dòng. `check.py` không có thước 40 dòng; tidy và độ lồng thì có.

## 11. Giả định

- Ô `int` rỗng nghĩa là khoá không có, không phải `atoi` ra 0. K3 cho phép ô rỗng. 265 ô Claude kể là ô không rỗng.
- `scene_by_name` nối bằng `;` như `script_scenes`. Cây này không có tên nhiều cảnh.
- `files_on_disk` của dòng `format` là glob cả cụm, không dùng trần 8 ký tự của phép so cấp.
- Câu đếm cặp ở mục 5.3 chỉ áp khi `parent` có `*`. `child` có `*` mà cha không có thì `distinct_values` và `missing_values` là số giá trị.
- Không viết `HOI-DAP.md`: mục 5.2 và 5.3 đủ để ra các cột báo cáo.

## 12. Lệch quy tắc

- Đề 5.5 nói lỗi dự kiến là `std::expected`. Lần chạy có nhiều lỗi dữ liệu, nên gom vào `LintResult` (danh sách `Issue` cộng số thống kê). Không `throw`. Lỗi cách dùng của exe trả mã 2.
- `struct Tally` có `NOLINT` `bugprone-exception-escape`: tidy coi bộ dựng `std::set` của STL MSVC là `noexcept` dù cấp phát nút. Cùng cách với `SRC/anim/rig.cpp` (HP-07).
