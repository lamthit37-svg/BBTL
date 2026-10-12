# Sổ nguồn: mã chép từ Forge2

Mọi tệp ở đây chép từ Forge2 ở commit `d7fcd76`, lúc chép nằm ở `D:\The-Forge\Forge2`; từ
2026-10-08 cây ấy nằm ở `D:\TÀI LIỆU LÀM VIỆC\code\engine\Forge2`, vẫn commit đó, và
`TOOLS/port/forge2_port.py` trỏ mặc định tới chỗ mới (cây làm việc của Forge2 lúc chép chỉ
lệch commit ấy ở `CLAUDE.md`, `docs/NGHI-NGO.md` và module `audio`, không tệp nào thuộc phần được
chép). Chép từng tệp một theo chuỗi `#include`, mỗi tệp qua `check.py` 0 lỗi rồi mới sang tệp kế.

## Quy ước chung của mọi tệp chép

Các điểm dưới áp cho mọi tệp và không lặp lại ở từng dòng của bảng:

- `namespace forge2` thành `namespace game`.
- Enumerator thêm tiền tố `k` (`ErrorCode::NotFound` thành `ErrorCode::kNotFound`) theo luật đặt tên
  của dự án; chuỗi in ra (`name(ErrorCode)`) giữ nguyên.
- Định dạng theo `.clang-format` của dự án (`case X: return y;` một dòng, danh sách khởi tạo).
- Tệp gọi Win32 include `core/win32.hpp` thay cho `<windows.h>`. Đó là tệp mới của THIENLONG (không
  chép): `<windows.h>` kèm `UNICODE`, `NOMINMAX`, `WIN32_LEAN_AND_MEAN` và `_WIN32_WINNT 0x0A00`.
  Forge2 khai các macro này ở CMake, còn `check.py` dịch từng tệp đứng riêng nên macro phải nằm
  trong mã nguồn.
- Header con của Win32 (`winuser.h`, `winerror.h`...) include trực tiếp ở nhóm nền tảng cho
  `misc-include-cleaner`.
- Khởi tạo aggregate ghi tên thành viên (`{.x = a, .y = b}`).
- `return hàm_void();` trong hàm `void` tách thành lời gọi rồi `return`.
- Thân vòng lặp có nhánh tách thành hàm một lượt; chỗ tách có comment `Khác gốc:` tại chỗ.

Kiểu lỗi `core::Result`, `core::Status`, `core::Error` giữ nguyên như Forge2.

## Bảng tệp

| Đích | Nguồn | Khác gốc ngoài quy ước chung |
|---|---|---|
| `SRC/core/error.hpp` | `src/core/error.hpp` | thông điệp rỗng chặn bằng `core::check` của THIENLONG thay `throw` trong constructor `consteval`; bỏ `{}` thừa của `heap_` |
| `SRC/core/error.cpp` | `src/core/error.cpp` | biến một chữ `c` thành `unit` |
| `SRC/core/text.hpp` | `src/core/text.hpp` | không |
| `SRC/core/text.cpp` | `src/core/text.cpp` | vòng của `is_valid_utf8` tách thành `next_sequence` |
| `SRC/core/handle.hpp` | `src/core/handle.hpp` | không |
| `SRC/core/handle.cpp` | `src/core/handle.cpp` | không |
| `SRC/core/function.hpp` | `src/core/function.hpp` | không |
| `SRC/core/thread.hpp` | `src/core/thread.hpp` | bỏ `{}` thừa của hai thành viên `ThreadConfig` |
| `SRC/core/thread.cpp` | `src/core/thread.cpp` | bỏ `reserve_crash_stack()` (trình báo crash của Forge2 không được chép); thân vòng lặp của `cpu_entries`, `place`, `performance_cpus` tách hàm; `main_thread_id` thành `kMainThreadId` |
| `SRC/core/log.hpp` | `src/core/log.hpp` | tham số constructor `Format` đổi tên (trùng tên trường); tham số `at` của `LogHistory` thành `position` |
| `SRC/core/log.cpp` | `src/core/log.cpp` | `check` là bản của THIENLONG; vòng `while (true)` của `reserve` thành `try_reserve` gọi lặp; thân vòng của `deliver`, `deliver_flushed`, `run_writer` tách hàm; bỏ phép ép `Word` sang `size_t` (kèm `static_assert` nền 64 bit) |
| `SRC/core/log_sink.cpp` | `src/core/log_sink.cpp` | `struct Step` ra khỏi thân `human_time`; biến `at` thành `cursor`; handle cục bộ viết `auto* const` |
| `SRC/window/types.hpp` | `src/window/types.hpp` | không |
| `SRC/window/cursor.hpp` | `src/window/cursor.hpp` | không |
| `SRC/window/cursor.cpp` | `src/window/cursor.cpp` | không |
| `SRC/window/monitor.hpp` | `src/window/monitor.hpp` | không |
| `SRC/window/monitor.cpp` | `src/window/monitor.cpp` | vòng `for` của `find_adapter` thành `while`; thân vòng của `largest`, `largest_aligned`, `monitors` tách hàm; biến `at` thành `slot` |
| `SRC/window/system.hpp` | `src/window/system.hpp` | thêm `defer_quit_if_modal` và `finish_modal_if_idle` |
| `SRC/window/system.cpp` | `src/window/system.cpp` | câu `if` trong vòng của `pump_messages` thành phép chọn; `request_quit` hoãn khi luồng đang kéo; cuối `pump_messages` tắt nhịp kéo sót |
| `SRC/window/window.hpp` | `src/window/window.hpp` | tiêu đề mặc định `"THIENLONG"`; thêm `set_modal_tick` và `cancel_size_move` |
| `SRC/window/window.cpp` | `src/window/window.cpp` | tên lớp cửa sổ `ThienLongWindow`; vòng lặp thêm ngoặc; `atom` thành `kAtom`; nhịp `WM_TIMER` khi kéo hoặc đổi cỡ; `WM_QUIT` trong vòng modal được gửi lại khi vòng kết thúc; huỷ `Window` giữa `window_proc` được hoãn tới proc ngoài cùng |
| `SRC/core/hash.hpp` | `src/core/hash.hpp` | bỏ phép ép `std::size_t` trong `std::hash` của `NameId` mà GCC báo thừa (kèm `static_assert` nền 64 bit) |
| `SRC/core/range.hpp` | `src/core/range.hpp` | constructor của `PageAllocator` thêm `explicit` |
| `SRC/core/range.cpp` | `src/core/range.cpp` | `check` là bản của THIENLONG (thông điệp cố định, không kèm số); vòng `for` của `fit_below` thành `while` |
| `SRC/fs/stream.hpp` | `src/fs/stream.hpp` | bỏ `{}` thừa của `data_` trong `Bytes` |
| `SRC/fs/stream.cpp` | `src/fs/stream.cpp` | vòng `for (;;)` của `scan_forward`, `scan_backward` thành hàm bước gọi lặp; hai câu `if` trong vòng của `read_full` lên điều kiện lặp; bỏ phép ép uint64 sang size_t (kèm `static_assert` nền 64 bit) |
| `SRC/fs/buny.hpp` | `src/fs/buny.hpp` | thêm NOLINT `performance-enum-size` cho `Format` (kiểu nền 64 bit là độ rộng trường trên đĩa) |
| `SRC/fs/buny.cpp` | `src/fs/buny.cpp` | các vòng có `if` trong thân (`has_twins`, `any_twins`, `salted_slots`, `displace`, `place_collisions`, `try_seed`, `is_safe_name`, `build`) đưa điều kiện lên điều kiện lặp hoặc tách hàm, thứ tự thử seed, salt, ô giữ nguyên; `Draft` khởi tạo bằng gán trường; `Miss` có kiểu nền |
| `SRC/fs/codec.hpp` | `src/fs/codec.hpp` | không |
| `SRC/fs/codec.cpp` | `src/fs/codec.cpp` | hai biến `thread_local const` tên `context` thành `kContext` |
| `SRC/shader/types.hpp` | `src/shader/types.hpp` | không |
| `SRC/shader/types.cpp` | `src/shader/types.cpp` | tham số một chữ `c` thành `unit`; vòng `for` của `parse_stage` thành `while` |
| `SRC/shader/failure.hpp` | `src/shader/failure.hpp` | không |
| `SRC/shader/wire.hpp` | `src/shader/wire.hpp` | biến và tham số tên `at` của Writer thành `start` |
| `SRC/shader/reflection.hpp` | `src/shader/reflection.hpp` | bỏ `{}` thừa ở thành viên string, vector và StageSet của các struct |
| `SRC/shader/reflection.cpp` | `src/shader/reflection.cpp` | ba vòng `for` dừng ở lỗi đầu tiên (`add_stage`, `merge`, `check_interface`) đi qua hàm chung `first_error`; thân vòng của `renumber` và `merge` tách hàm |
| `SRC/shader/package.hpp` | `src/shader/package.hpp` | bỏ `{}` thừa ở thành viên string, vector, span và `fs::Bytes` |
| `SRC/shader/package.cpp` | `src/shader/package.cpp` | `Package::load` đọc bằng `io::read_text` của THIENLONG thay `fs::read_file` (không chép `fs/file.*`); thân vòng của `read_variants`, `read_dependencies` tách hàm; hai phép kiểm đầu vào của `write_package` tách thành `check_source`; `at` thành `start` |
| `SRC/gpu/types.hpp` | `src/gpu/types.hpp` | không |
| `SRC/gpu/handle.hpp` | `src/gpu/handle.hpp` | không |
| `SRC/gpu/format.hpp` | `src/gpu/format.hpp` | NOLINT `readability-function-size` cho bảng `switch` 92 định dạng của `info` |
| `SRC/gpu/format.cpp` | `src/gpu/format.cpp` | không |
| `SRC/gpu/barrier.hpp` | `src/gpu/barrier.hpp` | NOLINT `performance-enum-size` cho `Access` (giữ kiểu nền của gốc) |
| `SRC/gpu/resource.hpp` | `src/gpu/resource.hpp` | bỏ `{}` thừa của thành viên `name` ở bốn struct mô tả |
| `SRC/gpu/slots.hpp` | `src/gpu/slots.hpp` | bỏ `{}` của `Slot::value`; NOLINT `bugprone-unchecked-optional-access` có lý do cho `find` và `take_live` |
| `SRC/gpu/retire.hpp` | `src/gpu/retire.hpp` | thân vòng lặp của `take_due` tách thành `sort_entry`; bỏ `{}` thừa của `Entry::action` |
| `SRC/gpu/timestamp.hpp` | `src/gpu/timestamp.hpp` | không |
| `SRC/gpu/memory.hpp` | `src/gpu/memory.hpp` | câu `if` trong vòng `for` của `allocate` chuyển thành điều kiện dừng của vòng |
| `SRC/gpu/command.hpp` | `src/gpu/command.hpp` | bỏ `{}` thừa của `RenderingDesc::colors` và `RenderingDesc::depth` |
| `SRC/gpu/binding.hpp` | `src/gpu/binding.hpp` | bỏ `{}` thừa của `BindEntry::resource`, `BindGroupDesc::name`, `BindGroupDesc::entries` |
| `SRC/gpu/pipeline.hpp` | `src/gpu/pipeline.hpp` | bỏ `{}` thừa của các thành viên `string_view` và `span` ở ba struct mô tả |
| `SRC/gpu/layout.hpp` | `src/gpu/layout.hpp` | bỏ `{}` thừa của các thành viên `vector` và `StageSet` |
| `SRC/gpu/layout.cpp` | `src/gpu/layout.cpp` | thân vòng lặp có nhánh của `check_unique`, `check_complete`, `make_layout`, `check_entries` tách hàm hoặc đổi thành phép tìm (`first_failure`, `is_new_place`, `close_space`) |
| `SRC/gpu/device.hpp` | `src/gpu/device.hpp` | bỏ `{}` thừa của các thành viên `string`, `string_view`, `optional`, `span` ở bốn struct |
| `SRC/gpu/device.cpp` | `src/gpu/device.cpp` | nhánh D3D12 và D3D11 nằm trong macro `GAME_GPU_D3D12` / `GAME_GPU_D3D11` (CMake của `game_gpu` định nghĩa; thiếu thì backend đó trả `kUnsupported`); `create_present_device` thử backend kế khi gặp `kUnsupported`; tham số `c` thành `letter` |
| `SRC/gpu/d3d12/entry.hpp` | `src/gpu/d3d12/entry.hpp` | không |
| `SRC/gpu/d3d12/convert.hpp` | `src/gpu/d3d12/convert.hpp` | `core/win32.hpp` trước `d3d12.h` |
| `SRC/gpu/d3d12/convert.cpp` | `src/gpu/d3d12/convert.cpp` | `if` trong `for` tách hàm; khởi tạo ghi đủ tên trường |
| `SRC/gpu/d3d12/device.hpp` | `src/gpu/d3d12/device.hpp` | `core/win32.hpp` trước `d3d12.h` |
| `SRC/gpu/d3d12/device.cpp` | `src/gpu/d3d12/device.cpp` | `if` trong vòng tách hàm; `submit` tách vì dài; `const HANDLE` thành `auto* const` |
| `SRC/gpu/d3d12/commands.hpp` | `src/gpu/d3d12/commands.hpp` | bỏ `{}` thừa của `error_`; alias để chữ ký còn một dòng |
| `SRC/gpu/d3d12/commands.cpp` | `src/gpu/d3d12/commands.cpp` | thân vòng lồng tách hàm; `return` hàm `void` tách lời gọi |
| `SRC/gpu/d3d12/programs.cpp` | `src/gpu/d3d12/programs.cpp` | thân vòng lồng tách hàm; chữ ký dài gom tham số; pragma C4324 chỉ với MSVC |
| `SRC/gpu/d3d12/resources.cpp` | `src/gpu/d3d12/resources.cpp` | `if` lồng tách hàm; hai case UAV đa mẫu chỉ dịch khi không phải MinGW vì header MinGW không có tên đó, vẫn trả false |
| `SRC/gpu/d3d12/swapchain.hpp` | `src/gpu/d3d12/swapchain.hpp` | không |
| `SRC/gpu/d3d12/swapchain.cpp` | `src/gpu/d3d12/swapchain.cpp` | vòng `adopt_images` đưa điều kiện dừng lên điều kiện lặp; `const HANDLE` thành `auto* const` |
| `SRC/gpu/check.hpp` | `src/gpu/check.hpp` | không |
| `SRC/gpu/check.cpp` | `src/gpu/check.cpp` | enumerator trần sau `using enum` thêm tiền tố k; thân vòng lặp của `check_inputs`, `check_pipeline` tách hàm; `check_features` và `resolve_view` tách bớt cho vừa trần độ phức tạp |
| `SRC/render/screen.hpp` | `src/render/screen.hpp` | không |
| `SRC/render/screen.cpp` | `src/render/screen.cpp` | bỏ `{}` thừa của `State::swapchain` |
| `SRC/gpu/vulkan/api.hpp` | `src/gpu/vulkan/api.hpp` | `core_late` bản Windows bỏ `constexpr`: có `static` cục bộ nên không phải biểu thức hằng, Clang `-Winvalid-constexpr` chặn build |
| `SRC/gpu/vulkan/api.cpp` | `src/gpu/vulkan/api.cpp` | không |
| `SRC/gpu/vulkan/convert.hpp` | `src/gpu/vulkan/convert.hpp` | không |
| `SRC/gpu/vulkan/convert.cpp` | `src/gpu/vulkan/convert.cpp` | 40 hàng của bốn bảng cờ ghi tên trường; phép OR có điều kiện trong vòng lặp của `map_flags` và `to_vk(StageSet)` viết bằng `?:` (đã so 102 nhãn `case` và 127 hàng bảng với gốc: khớp) |
| `SRC/gpu/vulkan/instance.hpp` | `src/gpu/vulkan/instance.hpp` | không |
| `SRC/gpu/vulkan/instance.cpp` | `src/gpu/vulkan/instance.cpp` | đầu `Instance::create` tách thành `probe_support` và `wanted_extensions`; thân vòng lặp của `Instance::devices` tách thành `append_capable`; `AdapterInfo` khai rồi gán trường |
| `SRC/gpu/vulkan/device.hpp` | `src/gpu/vulkan/device.hpp` | không |
| `SRC/gpu/vulkan/device.cpp` | `src/gpu/vulkan/device.cpp` | tách `take_family` (từ `pick_queues`), `pick_extensions` (từ `create_device`), `start_queue`, `Contexts::refill` (từ `begin_commands`), `find_target` (từ `submit`), `wait_queue`; ba vòng của `fill` đưa điều kiện dừng lên điều kiện lặp; handle cục bộ viết `auto* const` |
| `SRC/gpu/vulkan/commands.hpp` | `src/gpu/vulkan/commands.hpp` | bỏ `{}` thừa của `error_` |
| `SRC/gpu/vulkan/commands.cpp` | `src/gpu/vulkan/commands.cpp` | 25 câu `return` kèm lời gọi hàm void tách làm hai; `begin_rendering` tách ra `is_valid_pass`, `run_each`, `area_of`, `begin_pass` (`note_extent` của ảnh độ sâu nay chạy trước hai hàm thuần `depth_info`, `stencil_info`); vòng của `fill_regions` đưa điều kiện dừng lên điều kiện lặp; biến `at` thành `position` |
| `SRC/gpu/vulkan/swapchain.hpp` | `src/gpu/vulkan/swapchain.hpp` | không |
| `SRC/gpu/vulkan/swapchain.cpp` | `src/gpu/vulkan/swapchain.cpp` | phần điền `VkSwapchainCreateInfoKHR` của `build` tách thành `swapchain_info`; lambda huỷ semaphore của `drop_images` tách thành `retire_semaphore`; `TextureDesc` khai rồi gán trường; `present` giữ semaphore chờ trong mảng một phần tử |
| `SRC/gpu/vulkan/programs.cpp` | `src/gpu/vulkan/programs.cpp` | thân vòng lặp có nhánh của `gather`, `create_set_layout`, `fill_layout`, `take_set`, `write_group` tách hàm (`add_shader`, `add_binding`, `keep_set`) hoặc đưa điều kiện dừng lên điều kiện lặp; `allocate_set` bỏ khối `if` lồng |
| `SRC/gpu/vulkan/resources.cpp` | `src/gpu/vulkan/resources.cpp` | thân vòng lặp có nhánh của `find_type`, `format_support`, `memory_budget` đổi thành điều kiện lặp hoặc phép chọn; lambda của `retire_from` bỏ `()` rỗng |
| `SRC/gpu/vulkan/surface_win32.cpp` | `src/gpu/vulkan/surface_win32.cpp` | `windows.h` lấy từ `core/win32.hpp`; hằng `loader` thành `kLoader` |
| `SRC/fs/path.hpp` | `src/fs/path.hpp` | tham số `c` của `is_separator` thành `unit`; bỏ `{}` thừa của ba thành viên `PathParts` |
| `SRC/fs/path.cpp` | `src/fs/path.cpp` | `check` là bản của THIENLONG; thân vòng của `resolve` tách thành `end_segment`; câu `if` trong vòng của `assemble` thành `append` với số lần 0 hoặc 1 |
| `SRC/fs/file.hpp` | `src/fs/file.hpp` | bỏ `{}` thừa của `view_`, `handle_`, `buffer_`, `mapped_` |
| `SRC/fs/file.cpp` | `src/fs/file.cpp` | các `if` trong vòng của `write_at`, `read_at` lên điều kiện lặp; biến `at` thành `target`; bỏ bốn phép ép uint64 sang size_t (kèm `static_assert` nền 64 bit) |
| `SRC/fs/disk.hpp` | `src/fs/disk.hpp` | bỏ `{}` thừa của `PathInfo::modified` và `DirectoryEntry::name` |
| `SRC/fs/disk.cpp` | `src/fs/disk.cpp` | các `if` trong vòng của `make_tree`, `collect`, `DirectoryReader::next` lên điều kiện lặp, `if (keep)` tách thành `keep_name` |
| `SRC/fs/watcher.hpp` | `src/fs/watcher.hpp` | bỏ include `<functional>` không dùng trực tiếp |
| `SRC/fs/watcher.cpp` | `src/fs/watcher.cpp` | vòng của `run` tách thành `pump`, thân vòng của `dispatch` tách thành `dispatch_one`; `ThreadConfig` khai biến rồi gán tên; thứ tự khoá, thứ tự huỷ và dãy lời gọi Win32 không đổi |
| `SRC/math/sse.hpp` | `src/math/sse.hpp` | nội dung bọc trong `#if defined(__aarch64__)` (x64 không có `sse2neon.h`) |
| `SRC/math/simd.hpp` | `src/math/simd.hpp` | không |
| `SRC/math/scalar.hpp` | `src/math/scalar.hpp` | không |
| `SRC/math/types.hpp` | `src/math/types.hpp` | không |
| `SRC/math/vector.hpp` | `src/math/vector.hpp` | 6 chỗ khởi tạo `Point2`, `Vector2` ghi tên thành viên |
| `SRC/math/vector_int.hpp` | `src/math/vector_int.hpp` | `lanes()` khởi tạo `Int4` ghi tên thành viên |
| `SRC/math/quat.hpp` | `src/math/quat.hpp` | không |
| `SRC/math/cofactor.hpp` | `src/math/cofactor.hpp` | 18 định thức con 2x2 của `cofactors` tách sang `minors2x2` (hàm gốc 56 dòng); từng công thức và thứ tự tính giữ nguyên |
| `SRC/math/matrix.hpp` | `src/math/matrix.hpp` | `detail::transpose3` trả struct `Rows3` thay `std::array<__m128, 3>` (GCC báo `-Wignored-attributes`); bỏ `{}` thừa của `AffineTransform::translation` |
| `SRC/math/soa.hpp` | `src/math/soa.hpp` | 35 chỗ khởi tạo `SoaFloat2/3/4`, `SoaQuat` ghi tên thành viên |
| `SRC/math/geometry.hpp` | `src/math/geometry.hpp` | bỏ `{}` thừa ở thành viên `Vector3` của `Ray`, `Plane`, `Obb` |
| `SRC/math/geometry.cpp` | `src/math/geometry.cpp` | hai vòng `for` có `if` trong thân (`intersect(Ray, Aabb)`, `aabb_touches_frustum`) đưa điều kiện dừng lên điều kiện lặp, thứ tự xét trục và điểm dừng như cũ |
| `SRC/shadertool/main.cpp` | `tools/shader/main.cpp` | tên công cụ `thienlong_shader`; `io::use_utf8_console` và hàm cục bộ thay module `scan`; thân vòng có nhánh tách hàm; `CompilerConfig` khai rồi gán |

Không chép, dùng bản của THIENLONG: `core/check.hpp` (Forge2 có `check.hpp` + `check.cpp` kèm trình
báo crash; bản THIENLONG chỉ `check`/`fail`/`assume` và dừng bằng `std::abort`).

## Số đo qua cổng (21 tệp, 4.191 dòng gốc, 4.493 dòng bản đích)

Đo lại bằng `python TOOLS/port/forge2_port.py measure`. "Tổng đổi" là số dòng của bản chỉ-đổi-namespace bị thay hoặc bỏ. "Sửa tay" là phần còn lại sau khi
trừ hai phép đổi cơ học (tiền tố `k` cho enumerator, clang-format của dự án).

| Tệp | Dòng gốc | Tổng đổi | Sửa tay |
|---|---|---|---|
| `core/error.cpp` | 277 | 93 (33,6%) | 6 (2,2%) |
| `core/error.hpp` | 241 | 26 (10,8%) | 3 (1,2%) |
| `core/function.hpp` | 138 | 0 | 0 |
| `core/handle.cpp` | 18 | 1 (5,6%) | 1 (5,6%) |
| `core/handle.hpp` | 39 | 0 | 0 |
| `core/log.cpp` | 636 | 67 (10,5%) | 41 (6,4%) |
| `core/log.hpp` | 260 | 28 (10,8%) | 5 (1,9%) |
| `core/log_sink.cpp` | 330 | 29 (8,8%) | 26 (7,9%) |
| `core/text.cpp` | 142 | 7 (4,9%) | 7 (4,9%) |
| `core/text.hpp` | 49 | 0 | 0 |
| `core/thread.cpp` | 262 | 31 (11,8%) | 30 (11,5%) |
| `core/thread.hpp` | 116 | 13 (11,2%) | 3 (2,6%) |
| `window/cursor.cpp` | 61 | 23 (37,7%) | 1 (1,6%) |
| `window/cursor.hpp` | 53 | 12 (22,6%) | 0 |
| `window/monitor.cpp` | 276 | 35 (12,7%) | 32 (11,6%) |
| `window/monitor.hpp` | 68 | 0 | 0 |
| `window/system.cpp` | 97 | 24 (24,7%) | 4 (4,1%) |
| `window/system.hpp` | 60 | 11 (18,3%) | 0 |
| `window/types.hpp` | 65 | 3 (4,6%) | 3 (4,6%) |
| `window/window.cpp` | 796 | 91 (11,4%) | 28 (3,5%) |
| `window/window.hpp` | 207 | 18 (8,7%) | 2 (1,0%) |

Ba tệp đầu tiên (`window/types.hpp`, `core/text.hpp`, `core/text.cpp`): 4,6%, 0%, 4,9%. Hai tệp
vượt 30% tổng đổi (`core/error.cpp`, `window/cursor.cpp`) là bảng `switch` trên enum: toàn bộ phần
đổi là tiền tố `k` và gộp `case X: return y;` về một dòng, phần sửa tay 2,2% và 1,6%.

## So với các bản tham chiếu trước khi chép

Chủ dự án chỉ thị ngày 2026-10-05: với mỗi phần sắp chép, so mã của Forge2 với bản tương ứng ở các
engine tham chiếu; bên nào tốt hơn rõ rệt thì lấy bên đó. Cây còn trên đĩa lúc so: Platium, Titan,
No1 (`D:\TÀI LIỆU LÀM VIỆC\ENGINE GAME`), orio (`D:\NHÂN VẬT\engine\orio`), The Forge và Wicked
(`D:\The-Forge\repos\engine`). `G:\VnS` và `..\_Ref` không còn. Đo lại 2026-10-08: ba thư mục
vừa nêu đều không còn; Platium, Titan, No1 nay ở `D:\TÀI LIỆU LÀM VIỆC\code\engine`, The Forge
và Wicked ở `D:\TÀI LIỆU LÀM VIỆC\code\reference\engine`, orio không còn thấy trên ổ D.

| Phần | Đã đọc để so | Chọn | Vì sao |
|---|---|---|---|
| Cửa sổ | Platium `engine/platform/window.{hpp,cpp}` (trọn); Titan gần như trùng Platium | Forge2 | Forge2 chặn ngoại lệ ở biên Win32, `WM_CLOSE` không huỷ HWND khi đối tượng còn sống, có hàng sự kiện đổi cỡ cho swapchain, tiêu đề UTF-8 kiểm độ dài. Platium gọn hơn (466 dòng) nhưng để `DefWindowProc` huỷ cửa sổ lúc đóng rồi huỷ lần hai, `window_proc` không `noexcept`. No1 không có tầng này |
| Log | Platium `engine/core/log.{hpp,cpp}` (trọn) | Forge2 | API hàm kiểm kiểu lúc dịch và `noexcept`; Platium dùng macro `FG_LOG_*`, ghi đồng bộ dưới mutex và có thể ném trong hàm `noexcept` |
| Chuột thô và WASD | phần `RawInput` trong `window.cpp` của Platium | chưa chọn | Forge2 để nhập liệu ở module `input` riêng (23 tệp, 5.952 dòng); phần của Platium đủ cho camera bay và nhỏ hơn nhiều. Quyết ở bước B6 |
| Backend D3D12 | Platium và Titan `engine/rhi/d3d12` (22 tệp, RHI bindless riêng); Forge2 `src/gpu/d3d12` (11 tệp). Wicked, The Forge, O3DE có DirectX hoặc Metal nhưng là engine khác, không cắm vào `gpu::Device` | Forge2 | Phần chung của `gpu` đã chép từ Forge2. Backend D3D12 của Forge2 cài đúng `Device` và `CommandList` đó, CMake của Forge2 đã dịch nó cạnh Vulkan. Platium và Titan là đời RHI trước, không cùng chữ ký |
| Backend D3D11 | Forge2, The Forge, Wicked, O3DE, Godot, RavEngine, Platium, Titan, No1, orio, DragonVN: không có RHI D3D11. bgfx `renderer_d3d11.cpp` (BSD-2, khoảng 6696 dòng). `FLydunglai` `src/d3d11.cpp` là một file vẽ da | viết mới, đối chiếu bgfx | Không có bản Forge2 để chép. Không đưa nguồn bgfx vào cây. Lấy feature level, flip-model và staging đã đo của bgfx. Vượt bgfx bằng deferred context mỗi luồng ghi lệnh, cùng đường forward với Vulkan và D3D12 |

Chưa so: phần chung của `gpu` và backend Vulkan (đã chép trước lần so này), `shader`, `resource`, `render`, `capture`.


## Đối chiếu với mã ngày 2026-10-08

Bảng tệp ở trên được viết dần trong hai ngày đầu và chưa theo kịp mã. Đo lại bằng
`TOOLS/port/copied.tsv` (sổ mà `forge2_port.py copy` ghi) và `python -B TOOLS/port/forge2_port.py
measure <tệp>`:

- Sổ chép có 151 tệp; 46 tệp trong đó chưa có dòng nào ở bảng trên: `capture` 6 (`deflate`,
  `frame`, `png`), `core` 7 (`bits.hpp`, `clock.*`, `system.*`, `uarch.*`), `jobs` 4 (`jobs.*`,
  `queue.*`), `render` 10 (`camera.*`, `forward.*`, `target.*`, `shaders/shaders.list`,
  `shaders/model.hlsli`, `model.vs.hlsl`, `model.ps.hlsl`), `resource` 6 (`image.*`, `model.*`,
  `upload.*`), `shader` 13 (`builder.*`, `builtin.hpp`, `compiler.*`, `dxil.*`, `library.*`,
  `manifest.*`, `spirv.*`). Phần "khác gốc" của 46 tệp này chưa ai ghi.
- Các dòng ghi "không" ở cột khác gốc mà bản đích đã dài hơn hẳn bản gốc, tức đã có phần thêm của
  dự án chưa ghi (số dòng gốc sang số dòng đích): `core/text.hpp` 49 sang 91, `core/text.cpp` 142
  sang 256 (nhánh POSIX, các hàm `utf8_*`), `core/function.hpp` 138 sang 253 (lớp bọc ở cả hai
  nhánh), `window/cursor.cpp` 61 sang 175 (`Cursor::from_rgba`), `gpu/retire.hpp` 84 sang 140
  (`MoveOnlyCall`), `gpu/device.cpp` 109 sang 248 (chọn backend tự động, `GAME_GPU_GLES`),
  `render/screen.cpp` 169 sang 258 (MSAA, `set_clear`), `gpu/vulkan/api.hpp` 56 sang 169 (bảng
  `CoreLate` cho Android).
- Thứ không đến từ Forge2 dù nằm trong các module "hạ tầng": toàn bộ `gpu/d3d11` và `gpu/gles`
  (Forge2 chỉ có `d3d12` và `vulkan`), `shader/dxbc.*`, `render/{ui,canvas,shade}.*`, mọi tệp
  `.glsl` và các gói shader `ui.*`, `fx.*`, `resource/{classic,rig}.*`,
  `core/{check,number,thread_slot,win32,ground_point}.hpp`, `core/{system,thread}_posix.cpp`.
- Câu "Định dạng theo `.clang-format` của dự án" ở mục quy ước là luật của cổng cũ: `check.py`
  không còn kiểm định dạng từ ngày 2026-10-08.