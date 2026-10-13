# 15 bài đỏ trùng nhau giữa msvc-release và msvc-asan (cây `build/xr`, HEAD `7e1c6a4`)

Nguồn: `xreview_head_msvc-release_build_ctest.log` (19:11, 69/84) và `9d2b4c5_msvc-asan_build_ctest.log`
(19:18, 69/84, `ctest --preset msvc-asan -E ^audio_tests$ -V`). Hai lần chạy có **đúng cùng 15 bài đỏ**.
Không có báo cáo `ERROR: AddressSanitizer` nào, nhưng điều đó chỉ đúng cho **69 bài đã chạy xong**: 6 bài Not Run
không được ASan kiểm, và 8 bài 0xc0000409 dừng giữa chừng sau ca đỏ đầu tiên của `main`.

Lưu ý: cây `build/xr` là worktree sạch, **không có thư mục `dev/`** (dữ liệu không theo dõi bởi git), nên các bài
cần dữ liệu thật được đánh dấu "nghi thiếu dữ liệu"; chưa chạy lại với `dev/` đủ.

0xc0000409 = `__fastfail`/abort từ `core::check` trong `main` khi có ca đỏ (`check thất bại: <tên> mọi ca phải qua`),
không phải crash bộ nhớ.

| # | Bài | Kết quả | Nguyên nhân (theo log) | Nhóm |
|---|-----|---------|------------------------|------|
| 9 | world_tests | Not Run | Lỗi build: `world_tests.cpp(5)` thiếu `nav_sample.hpp` (tệp chưa commit) | build |
| 28 | classic_tests | Not Run | Lỗi build: `classic_tests.cpp(31..)` `std::string_viewextras` (thiếu dấu cách, mã đã commit hỏng; bản sửa nằm ở cây chính, chưa commit) | build |
| 48 | gui_sheet_tests | Not Run | Lỗi build: tệp ở HEAD không biên dịch (mảnh hàm dán nhầm, `run` không khai báo, hàm định nghĩa 2 lần; xem phân tích của TL QA) | build |
| 59 | ui_flow_tests | Not Run | Lỗi build: `ui_flow_tests.cpp:294` gọi `paint_flow(deck, flow)` 2 tham số; chữ ký 3 tham số từ `c618cea` | build |
| 78 | wire_loop_tests | Not Run | Lỗi build: thiếu `protocol_samples.hpp` (chưa commit) | build |
| 80 | gate_tests | Not Run | Lỗi build: thiếu `metrics` (chưa commit) | build |
| 63 | layers | Failed | `GameLayers.cmake`: vi phạm tầng `client/display→client` (`graphic/prelude.hpp`), `client/viewer→client`, `classic→render`, `classic→resource` (`place/classic/bake.hpp`), `gate→guard` (`gate/motion.hpp`); module `metrics`, `metrics/serve` chưa có trong bảng | kiến trúc tầng |
| 15 | core_tests | 0xc0000409 | Ca `error_maps_and_prints_system_codes` (`core_tests.cpp:144`, đường dẫn in ra dòng đầu `/`) | mã/test |
| 23 | gpu_tests | 0xc0000409 | D3D: `d3d12_depth_view_keeps_device` (lớp debug D3D12 báo `GetGPUVirtualAddress returns NULL for non-buffer`, `device.cpp:197`) và `d3d11_swapchain_accepts_srgb` (`gpu_tests.cpp:441`) | D3D/máy |
| 45 | skill_tests | 0xc0000409 | `actions_start_with_pets`, `actions_are_made_in_original_order`, `sync_drops_gone_and_keeps_ids` (id action/thứ tự, `skill_tests.cpp:328-369`) | mã/test |
| 65 | config_tests | 0xc0000409 | `real_rules_and_scene_have_schema`: không đọc được `../scenes/huoyangu/scene.toml` (`config_tests.cpp:229-250`) | nghi thiếu dữ liệu |
| 66 | process_tests | 0xc0000409 | `spawn_path_with_space_prints_ready` (`process_tests.cpp:83`, exe có dấu cách) | mã/test |
| 68 | service_tests | 0xc0000409 | `relaunch_replaces_live_process`: gate không in ready; `cluster.toml:1` không có khối zone id 7 | nghi thiếu dữ liệu/cấu hình |
| 69 | server_boot | 0xc0000409 | `closed_input_runs_full_cycle`, `empty_input_runs_full_cycle`, `cluster_stays_up_until_input_closes`: "gate thoát mã 2 trước khi sẵn sàng", thiếu `secrets.local.toml` | nghi thiếu dữ liệu/cấu hình |
| 70 | server_boot_source_clean | 0xc0000409 | `server_boot_leaves_source_tree_alone`: phụ thuộc `server_boot` chạy xong và xanh (`server_boot_source_tests.cpp:117`) | hệ quả của #69 |

Ngoài 15 bài: công cụ `thienlong_lint` cũng lỗi build (`linttool/main.cpp`, `feed_lint_file/open_lint/finish_lint`
không còn trong `game::content`, có từ `9c0d49b`), không phải bài ctest.

Kết luận: không bài nào trong 15 bài liên quan tới 9d2b4c5 (preset/cờ ASan). Để ASan phủ đủ 84 bài cần:
commit các tệp còn thiếu (6 bài build), sửa `layers`, và chạy lại với `dev/` đủ.