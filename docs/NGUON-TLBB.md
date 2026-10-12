# Tệp port từ TLBB Dev (`G:\TLBB\Dev`, commit e0d89a6)

TLBB Dev là client viết lại của Thiên Long Bát Bộ (C++23) làm tham chiếu ngữ nghĩa: mỗi tệp dưới đây
đã đọc trọn tệp gốc, giữ toán tử và thứ tự phép tính, và ghi `Nguồn: ...@e0d89a6. Khác gốc: ...` ở
đầu tệp. Test của TLBB được port cùng, kể cả khung vàng sinh từ mã OGRE 1.2.5 (`anim_tests`). Cổng
`check.py` lúc port chặt hơn của TLBB (không `if` trong vòng lặp, tên từ ba ký tự, hậu tố `F`,
khởi tạo ghi tên), nên phần lớn "khác gốc" là hình thức, không đổi phép tính. Từ 2026-10-08 các
bước hình thức đó đã gỡ khỏi `check.py`; mã đã port giữ nguyên dạng cũ.

| Tệp của THIENLONG | Gốc ở TLBB Dev | Khác gốc đáng kể |
|---|---|---|
| `SRC/ogre/{vec3,quat}.hpp`, `quat.cpp` | `src/math/{vec3,quat}.hpp`, `quat.cpp` | namespace `game::ogre`; bỏ `operator<=>` của Vec3 |
| `SRC/anim/{asset,rig,pose}.*` | `src/cooked/asset.hpp` (xương, animation), `src/anim/{rig,pose}.*` | kiểu nằm trong `game::anim`; `apply` nhận `Blend`; bộ nạp từ GLB là mã mới (`SRC/resource/rig.*`) |
| `SRC/motion/motion.*`, `SRC/core/ground_point.hpp` | `src/motion/motion.*`, `GroundPoint` của `protocol` | `GroundPoint` chỉ còn hai trường |
| `SRC/look/{appearance,look}.*` | `src/look/{look,load}.*`, `src/tables/appearance.*` | giới là `Race` của CharRace; khoá faces, hairs là (id, race); bảng đọc bằng `table::Tsv`; chưa có vũ khí, NPC; cột `is_creatable` đã dùng để lọc mặt và tóc của bảng tạo nhân vật (`SRC/client/display/login_data.cpp`) |
| `SRC/avatar/{gait,turning}.*` | `src/client_app/{gait,turning}.*` | `core::Clock`; engine số ngẫu nhiên đúng 32 bit để cùng dãy ở mọi trình dịch |
| `SRC/control/{ground,view_ray}.*` | `src/control/{ground,view_ray}.*` | `GroundShape` thay dữ liệu đã nấu; tia tính từ mắt, hướng nhìn, góc nhìn và tỉ lệ khung (không cần nghịch đảo ma trận 4x4); chưa có mặt công trình. `Ground` có đủ `vertical_scale`, `base_scale`, `touches_sphere`, `camera_box` như Dev; vòng bốn ô quanh đỉnh tách thành `camera_boxes`; thêm `probe_sphere` ba kết quả (trống, chạm, không có hộp) cho camera 2026 |
| `SRC/control/{input.hpp,touch.*}` | `src/render/{input.hpp,touch.*}` | namespace `game::control`; bỏ sự kiện Key (chưa có phím tắt); sự kiện chữ `InputKind::kText` thêm lại ngày 2026-10-08 cho ô nhập của màn đăng nhập; `emit` thay cho `push_back(at_event(...))` lồng |
| `SRC/control/stick.*` | `src/control/stick.*` | `Aim` thay hai điểm kề nhau của `is_due`; cùng ngưỡng và luật lọc lệnh |
| `SRC/control/hover.*` | `src/control/hover.{hpp,cpp}` | namespace `game::control`; có test trong `tests/control_tests.cpp`; client chưa gọi (chưa có danh sách NPC để soi) |
| `SRC/control/cursor_rules.*` | `src/control/cursor_rules.{hpp,cpp}` | namespace `game::control`; 23 loại con trỏ; đã nối qua `SRC/client/viewer/cursors.cpp`; các chế độ sửa, giám định, kết bạn, giao dịch chưa có |
| `SRC/fx/script.*` | `src/fx/script.hpp`, `words.hpp` | namespace `game::fx`; phần còn lại của `fx` (hệ hạt, cast, billboard) viết theo OGRE và `Render.dll`, không port từ Dev |
| `SRC/render/{camera,view_size}.*` | `src/render/{camera,view_size}.*` | `Lens`, `look_camera`, `Orbit`, `orbit_camera` cùng số (FOV dọc 35, mặt gần 0,25 và xa 150 nhân thước; quay 60 độ, lùi 3,2 bán kính); ma trận tay phải độ sâu đảo của gpu thay bgfx nên bỏ cờ `homogeneous_depth`; bỏ `frame_camera` (khung bao) và các hàm cắt khuất |

Camera và chuột của màn chơi không còn là bản của TLBB Dev: `SRC/control/follow_camera.*` và
`SRC/control/player_input.*` viết lại ngày 2026-10-08 theo mã máy của client 2026
(`docs/CAMERA-2026.md`), vì bản của Dev theo mã nguồn 2008 mà bản 2026 đã khác (pitch kéo được,
zoom mượt, điểm nhìn cao 1,5, mặt cắt theo cảnh). Bản của Dev xem lại bằng `git show b99a861`.
Thuật toán kính Cool3D và ClientCamera của Loong (`SRC/camera`, commit fcd09c9, đưa lại ở
83c87f4) gỡ cùng ngày; xem lại bằng `git show 83c87f4`.
Test của Dev đã port: các ca mặt đất, tia nhìn và con trỏ trong `tests/control_tests.cpp`,
`tests/touch_tests.cpp` (từ `touch_test.cpp`), `tests/camera_tests.cpp` (ca `orbit` và
`look_camera_centre`). Các ca camera và `ClickMove` của Dev đã bỏ cùng mã; `tests/pilot_tests.cpp`
là test mới theo hành vi của bản 2026.

Tệp mới của dự án, không port: `SRC/resource/rig.*` (GLB sang xương OGRE: khoá tuyệt đối trừ ngược
bind pose, vì `TOOLS/glb` ghi khoá đã ghép bind pose), `SRC/table/tsv.*` (bảng TSV), `SRC/avatar/
avatar.*` (nạp skeleton, clip, ra ma trận skin), `SRC/client/display/player.*` (ghép người chơi lên
màn hình), `TOOLS/content/{dbc,export_look,collect_avatar}.py`.

## Máy chủ: chạy và giám sát tiến trình (P2 đợt 1, 2026-10-07)

Dev chỉ có bốn tiến trình và không có PostgreSQL; phần port là việc chạy tiến trình con và vòng
giám sát. `SRC/config`, `SRC/service` và bảy `main.cpp` là mã mới, không có bản tương ứng ở Dev.

| Tệp của THIENLONG | Gốc ở TLBB Dev | Khác gốc đáng kể |
|---|---|---|
| `SRC/process/process.{hpp,cpp}`, `detail/{child_state,line_buffer}.hpp` | `src/platform/process.hpp`, `console.hpp` | lỗi là `core::Result`; hai chế độ chạy: `Mode::kService` (stdin là ống cha giữ, stderr thừa hưởng) và `Mode::kCommand` (stdin là thiết bị rỗng, stderr gộp vào stdout, dùng cho `pg_ctl`); đọc một dòng có hạn chờ và trần 4 KiB, vòng đọc viết một lần cho mọi nền tảng; huỷ đối tượng thì buộc dừng rồi chờ; không gọi shell |
| `SRC/process/process_win32.cpp`, `self_win32.cpp` | `src/platform/process_win32.cpp`, `console.cpp` | con `kService` nằm trong job `KILL_ON_JOB_CLOSE`, tạo treo rồi mới đưa vào job; con `kCommand` ở ngoài job; con chỉ thừa hưởng ba handle chuẩn (`PROC_THREAD_ATTRIBUTE_HANDLE_LIST`); nhóm tiến trình riêng; câu hỏi dừng phân biệt ống, console và thiết bị rỗng; sự kiện đóng cửa sổ, đăng xuất, tắt máy giữ trình xử lý lại để luồng chính dừng êm |
| `SRC/process/process_posix.cpp` | `src/platform/process_posix.cpp`, `console.cpp` | cùng hợp đồng; `posix_spawn`, nhóm tiến trình riêng, SIGINT, SIGTERM và SIGHUP. CHƯA chạy lần nào: mới qua kiểm cú pháp bằng trình dịch NDK (arm64, x86_64) |
| `SRC/supervise/supervise.{hpp,cpp}` | `src/server/supervise.{hpp,cpp}` | máy trạng thái thuần: không include `process`, không đọc đồng hồ, bên gọi đưa thời điểm; thêm PostgreSQL, trần chạy lại mỗi giờ, nhiều tiến trình cùng loại, yêu cầu dừng tới sớm được nhớ |

Test của Dev cho phần này chỉ có `tests/platform/process_test.cpp` (bốn ca của `quote_arg`); các ca
đó nằm trong `arguments_arrive_unchanged` của `tests/process_tests.cpp`, kiểm bằng cả chuyến đi tới
tiến trình con. Dev không có test cho `supervise`; `tests/supervise_tests.cpp` (bộ chạy giả ở
`tests/supervise_script.hpp`) là mã mới.

## Khác biệt dữ liệu đã đo

- Bảng của TLBB nấu từ bản client khác: bộ động tác của nữ là 263 (TLBB) so với 819 (client này), của
  nam 530 so với 1415; skeleton `女主角.skeleton` 18 373 byte (TLBB) so với 30 892 byte. Vì vậy bảng
  ngoại hình xuất lại từ `Config` nhị phân của client này, không dùng `content/tables` của TLBB.
- Tên hành động trong ActionSetKV có thể là tên skill (`g01_跑步`), phải giải qua `Effect/all.skill`
  (dòng `Animation`) để ra tên clip thật (`跑步`), rồi tìm tệp chứa clip: skeleton chính trước, rồi khối
  `Skeletons` của mẫu trong `Model/all.obj`.
- Khoá animation trong GLB là tuyệt đối (`TOOLS/glb/rig.py`), còn `anim::apply` cần độ lệch so với bind
  pose của skeleton CHÍNH; `resource::animation_of` làm phép trừ ngược. Thử: dịch ở khoá cuối của clip
  đứng của nữ khớp khoá tuyệt đối của tệp trong 1e-4 (`rig_tests`).

## Chưa port (TLBB có, THIENLONG chưa)

WalkMap (va chạm công trình; phần vùng cấm và tìm đường KHÔNG port từ `src/walk` của TLBB mà từ
`PathLib.dll` của client 2026, xem `docs/DUONG-DI-2026.md`), vũ khí và locator, NPC (`creature`, `model_anims`, `spawns`),
`melee`, `hotkey`, bảng tên, nạp nhiều luồng (`world_load`),
rung camera của kỹ năng (`AddOneVib`), phím tắt Alt+Lên và Alt+Xuống để zoom, skeleton mở rộng của 17 trang phục thời
trang (`anim::retarget` đã có, chưa nối), vẽ chất liệu theo `all.obj` (1 364 mesh dính `BaseWhite`).

Đã port sau khi bảng trên được viết, đối chiếu mã 2026-10-08: con trỏ chuột và `hover` (hai dòng
trong bảng đầu), và các hàm cắt khuất của `render/camera` (`frame_camera`, `box_in_view`,
`frustum_of`, `sphere_in_view`; có ca test trong `tests/camera_tests.cpp`, chưa nơi nào ngoài test
gọi ba hàm cắt khuất).

Thiếu dòng `Nguồn:` ở đầu tệp so với quy ước nêu trên: `SRC/motion/motion.hpp`, `motion.cpp`, và
bốn tệp `SRC/control/{ground,view_ray,touch,stick}.cpp` (chỉ `.hpp` của chúng có);
`SRC/control/hover.hpp` và `SRC/fx/script.hpp` có `Nguồn:` nhưng thiếu `@e0d89a6`.

