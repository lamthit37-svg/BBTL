# Audit C — Chất lượng mã C++ và độ đúng lúc chạy (src/, engine/, SERVER/, mạng)

Ngày: 2026-10-13 (giờ Bangkok). Người làm: thành viên C, chỉ đọc, không sửa mã.
Công cụ: clang-tidy và clang-format (LLVM tại `C:\Program Files\LLVM\bin`), `compile_commands.json` ở gốc (MSVC 19.51, 871 mục, ghi lúc 15:30 13/10).

## Phạm vi và giới hạn (đọc trước)
- clang-format `--dry-run`: chạy **toàn bộ** 657 tệp `.cpp/.hpp/.h` trong `src/`, `engine/`, `SERVER/`.
- clang-tidy: chạy **mẫu 36/297 TU** (chọn ngẫu nhiên, seed 7) của `src/` và `engine/`. Chạy hết mất khoảng 30 phút; chưa chạy. Log: `build\audit_C_tidy.txt`.
- **Chưa** build lại với cảnh báo mức cao (/W4, -Wall -Wextra), **chưa** chạy ASan/UBSan/TSan. Những phần đó nằm ở các mục "đề xuất".
- Đã so sánh với client gốc `F:\tl 2026\_goc` qua danh sách khôi phục trong `docs/KHOI-PHUC-2026-10-09`, không so từng byte với ổ F:.

## Bảng phát hiện

| ID | Mức | Phát hiện | Bằng chứng | Nguyên nhân gốc | Đề xuất sửa | Công sức |
|---|---|---|---|---|---|---|
| C-01 | Cao | clang-tidy không sạch: 36 TU mẫu ra 653 lỗi (do `WarningsAsErrors` nên cảnh báo thành lỗi) | `build\audit_C_tidy.txt`. Chia theo check: misc-include-cleaner 372, readability-uppercase-literal-suffix 117, identifier-length 29, designated-initializers 23, function-size 20, pointer-arithmetic 12, easily-swappable 8, các check khác ít hơn | Mã khôi phục hoặc chép từ Forge2 chưa từng đi qua cổng tidy; cổng tidy không chặn trong CI | Chạy `run-clang-tidy -fix` cho các check máy móc như include-cleaner và literal-suffix theo từng module, rồi build và test; xử lý tay các check còn lại; thêm cổng tidy cho mỗi PR | L (2–4 ngày) |
| C-02 | TB | 99/657 tệp lệch `.clang-format` | Ví dụ `src/client/app/client/display/assets.hpp` 84 chỗ, `face/gui/paint.cpp` 13, `radar.cpp` 9, `boot.cpp`, `map/splat.cpp`, `map/terrain.cpp` mỗi tệp 6 | Tệp khôi phục là bản cũ, sửa tay không qua formatter | Chạy `clang-format -i` trên 99 tệp trong một commit riêng chỉ đổi định dạng; thêm kiểm `--dry-run --Werror` vào CI | S (1 giờ) |
| C-03 | Cao | Thành viên không được khởi tạo | `src/client/app/client/display/graphic/prelude.hpp:561` constructor không khởi tạo `action` (pro-type-member-init) | Thiếu giá trị mặc định cho thành viên | Thêm `{}` cho thành viên; kiểm lại lối đọc `action` | S |
| C-04 | Cao | Ngoại lệ có thể thoát ra từ hàm `noexcept` hoặc callback, gây `std::terminate` | `engine/resource/upload.cpp:905` `downsample_into`; `src/client/app/client/display/graphic/frame.cpp:36` (lambda) — bugprone-exception-escape | Cấp phát vector hoặc string trong hàm `noexcept` | Cấp phát trước khi vào hàm, hoặc bỏ `noexcept` và trả `core::Result` | S–M |
| C-05 | TB | Dead store hoặc logic bị bỏ dở | `frame.cpp:186` giá trị khởi tạo `has_astc` không bao giờ được đọc (clang-analyzer deadcode) | Có thể việc dò ASTC bị ghi đè hoặc bỏ dở sau khôi phục; đây là nghi lỗi chọn định dạng nén trên mobile | Xác minh với bản gốc Forge2; trên Android cần dò ASTC thật | S |
| C-06 | TB | Struct có padding lớn trên đường nóng | `display/graphic/state.hpp:9` `Display::State` 63 byte padding, tối ưu chỉ 15 | Thứ tự thành viên | Sắp lại thành viên theo kích thước giảm dần | S |
| C-07 | TB | 23 khối `catch (...)` | `main.cpp:384`, `android_main.cpp:197,624`, `frame.cpp:21`, `core/error.cpp:252,261`, `core/range.cpp:302`, `fs/watcher.cpp:243`… | Chặn ngoại lệ ở biên, có chỗ nuốt mất ngoại lệ | Rà từng chỗ: mỗi chỗ phải ghi log kèm `std::current_exception` và trả lỗi; cấm nuốt im lặng | M |
| C-08 | TB | `jobs` tách (detach) luồng thợ khi dừng | `engine/jobs/jobs.cpp:1061` `detach_workers`: `handle.detach()` | Thiết kế có chủ ý: State được đếm tham chiếu để tránh tự join | Ổn nếu đếm tham chiếu đúng. Cần test TSan hoặc stress cho việc khởi tạo và hủy lặp, quan trọng với vòng đời Android `onDestroy` | M |
| C-09 | TB | Độ phủ đồng bộ rộng: 176 `std::atomic`, 68 `std::mutex`, 38 `std::thread/jthread` | grep `src/` và `engine/` | Engine đa luồng (jobs, upload, watcher) | Chạy test dưới TSan (clang-cl hoặc Linux) ít nhất cho `jobs`, `resource`, `fs` | M |
| C-10 | Thấp | 96 `reinterpret_cast`, 101 `memcpy` | Ví dụ `seal/detail/sodium.cpp:25,29`, `resource/upload.cpp:720` | Ranh giới C API và pixel | Gom vào helper `as_bytes` / `std::bit_cast`; thêm kiểm kích thước tại mỗi `memcpy` từ dữ liệu tệp (dữ liệu không tin cậy) | M |
| C-11 | TB | Lỗi xây dựng sẵn có | Báo cáo trước đó: 8 target PC lỗi và khoảng 15 test hỏng sau khôi phục | 56 tệp nguồn là bản cũ hơn bản cuối, 12 `CMakeLists.txt` còn thiếu (AGENTS.md); `docs/KHOI-PHUC-2026-10-09/DANH-SACH-GAN-DUNG.tsv` 120 dòng (54 dòng là mã), `DANH-SACH-MAT.tsv` 48.459 dòng | Khôi phục từ nhật ký công cụ, không đủ | Ưu tiên số 1: lấy danh sách 8 target và 15 test, sửa theo `DANH-SACH-GAN-DUNG`, đối chiếu `lich-su-git-2026-10-05.bundle` | L |
| C-12 | Cao | iOS không cấu hình được | AGENTS.md: nhánh iOS link `game_jobs` và `game_capture`, hai target chỉ tạo cho Windows và Android | Điều kiện nền tảng trong CMake | Tạo hai target cho `APPLE`, hoặc bỏ link có điều kiện; thêm job CI `cmake --preset ios` (chỉ cấu hình) trên macOS runner | M |
| C-13 | Cao | Máy chủ chưa build được trên Linux thật | AGENTS.md và NGHI-NGO §45: `core/system_posix.cpp` include `<sys/system_properties.h>` (chỉ Android có) cho mọi nền tảng không phải Apple | Thiếu `#if __ANDROID__` | Bọc include và hàm bằng `#if defined(__ANDROID__)`; dựng trên WSL hoặc Linux CI | S |
| C-14 | Info | Mạng và giao thức | Client không mở socket nào (AGENTS.md). Mã máy chủ ở `src/server/*` và `src/shared/{protocol,secure}`; socket chỉ ở `src/server/gate/front.cpp` (175–300). `SERVER/` chỉ có `config` (TOML), không có mã nguồn. gate xử lý `Hello`, `Ping`, `Logout`; chưa có tài khoản, nhân vật, migration DB | Theo đúng kế hoạch P2 | Chưa đủ cho client mobile online. Trước khi nối: cần fuzz bộ đọc khung (`protocol`), giới hạn kích thước khung, timeout handshake, rate-limit ở gate | L |
| C-15 | Thấp | Còn TODO và chú thích cần dọn | `engine/shader/package.hpp:4` TODO (về hash khớp giữa C++ và tool) | Mã chép từ Forge2 | Hoàn tất hoặc xóa TODO, vì chuẩn production không để TODO | S |
| C-16 | TB | `compile_commands.json` không chứa `SERVER/`; mã máy chủ trong `src/server` có trong db | 871 mục: src 194, engine 103, Test 90, build 341, third_party 141 | — | Chạy tidy riêng cho `src/server`, `src/shared` (có trong mẫu: `server/account/book.hpp:103`) | S |

## Đề xuất thứ tự xử lý
1. C-11 (build và test xanh), C-13, C-12: mở khóa cho Android, iOS và Linux.
2. C-03, C-04, C-05: rủi ro chạy thật.
3. C-02, sau đó C-01 theo từng module, mỗi module một commit, có build và test.
4. C-08, C-09, C-10: chạy sanitizer.
5. C-14 trước khi làm client online.

## Chưa làm trong lượt audit này
- clang-tidy cho 261 TU còn lại; build lại với /W4 /permissive- hoặc -Wall -Wextra -Wconversion; chạy ASan, UBSan, TSan; so byte với `F:\tl 2026\_goc`.
