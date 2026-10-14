# TỔNG HỢP AUDIT ĐA TÁC TỬ — THIENLONG (2026-10-13, ~16:40 ICT)

Nguồn: `A-build-platform.md` (build/nền tảng), `B-i18n.md` (bản dịch), `C-code-runtime.md` (mã C++/runtime/máy chủ).
Vòng phản biện chéo: kiểm lại từng phát hiện trực tiếp trên mã, CMake, dữ liệu và log build/test hiện có. Chỉ đọc; tệp duy nhất được ghi là tệp này.
Nhãn: **XÁC NHẬN** (đúng, có bằng chứng) · **BÁC BỎ** (sai) · **LỖI THỜI** (từng đúng, nay không còn) · **CẦN CHỦ DỰ ÁN** (đúng về kỹ thuật nhưng phụ thuộc quyết định).

## 1. Tóm tắt điều hành
- **Bản PC build sạch.** `cmake --build build\msvc-release -- -k 0` trả 0 lỗi (log `build\scratch\auditA_build.log`). Con số "8 target lỗi, ~15 test hỏng" (C-11) là **lỗi thời**.
- **Test: 86/92 đạt, 6 fail** (log `build\scratch\auditA_ctest.log`). 4/6 do dữ liệu mất sau khôi phục 2026-10-09: `Test\golden` rỗng (0 tệp), `SERVER\` chỉ còn `config`. 1/6 do test gắn cứng chuỗi tiếng Việt trong khi bản dựng là `zh`. 1/6 do danh sách hoạt ảnh thiếu.
- **Bản dịch sạch về cấu trúc nhưng chưa hiện trong game.** Client không nạp `ui_strings.lang.tsv` (có chú thích ghi là cố ý) và chưa có nơi nào đọc 7 bảng vật phẩm/kỹ năng.
- **Rủi ro chạy thật có thật nhưng ít hơn báo cáo C:** 1 chỗ thật (`downsample_into` cấp phát trong hàm `noexcept`). 2 cảnh báo clang-tidy là dương tính giả (frame.cpp:36, frame.cpp:186). 1 cảnh báo chỉ là vấn đề kiểu viết (prelude.hpp:561).
- **Mobile:** APK ra được nhưng chưa cài thử. iOS chưa từng biên dịch (không có Mac). Preset `android-x86_64` dùng nhầm triplet arm64.
- **Chuẩn mã:** 99/657 tệp lệch `.clang-format`. Mẫu clang-tidy 36/297 TU ra 653 lỗi. **Chưa đạt "production grade"** cho tới khi xong P1.

## 2. Bảng phát hiện đã kiểm (gộp trùng)

| ID gộp | Nguồn | Phát hiện | Phán quyết | Bằng chứng kiểm lại | Mức |
|---|---|---|---|---|---|
| T-01 | C-11 vs A-01 | 8 target PC lỗi biên dịch | **LỖI THỜI** | Build `-k 0` hôm nay: exit 0, không có `FAILED:`/`error C`/`error LNK`. HEAD `9c0d49b` 14:59 | — |
| T-02 | C-11 vs A-02 | ~15 test hỏng | **LỖI THỜI** → thay bằng 6/92 | auditA_ctest.log: "93% tests passed, 6 tests failed out of 92" | Cao |
| T-03 | A-02a, A-02d, A-02e | Golden rỗng; thiếu SERVER/scenes, SERVER/tables | **XÁC NHẬN** | `Test\golden` có 0 tệp; `SERVER\` chỉ có `config` | Cao |
| T-04 | A-02c | ui_panel_tests `desk_paints_notice` gắn cứng tiếng Việt | **XÁC NHẬN** (bằng dữ liệu, không chạy lại) | `Test/Ui/ui_panel_tests.cpp:536` tìm "Lạc Dương (237, 236)". Chuỗi này chỉ có ở `vi.tsv:11499` (BHJM_140520_46); bản triển khai `ui_strings.tsv` là zh "洛阳（237，236）". Không chạy với vi vì việc đó ghi đè `dev/client/assets` dùng chung, trái phạm vi chỉ đọc | TB |
| T-05 | A-02b | gui_real_tests thiếu hoạt ảnh | **XÁC NHẬN** (theo log A) | gui_real_tests:118 | TB |
| T-06 | A-02 | Test abort bằng 0xc0000409, không phân biệt được với hỏng stack | **XÁC NHẬN** | 5 test C++ đều thoát 0xc0000409 | Thấp |
| T-07 | C-12 vs A-04 | iOS link `game_jobs`/`game_capture` không tồn tại | **LỖI THỜI** (đã sửa) / **chưa kiểm chứng** | `CMakeLists.txt:577` `if(WIN32 OR ANDROID OR IOS)` tạo cả hai target. Nhánh iOS chưa từng qua trình dịch | TB (blocker để công bố iOS) |
| T-08 | C-13 | `system_posix.cpp` include `<sys/system_properties.h>` cho mọi nền không phải Apple | **XÁC NHẬN** | `engine/core/system_posix.cpp:12-18`: `#if __APPLE__ … #else #include <sys/system_properties.h>` → Linux (máy chủ) không biên dịch được | Cao |
| T-09 | C-03 | `ActionRequest::action` không khởi tạo | **XÁC NHẬN, hạ mức xuống Thấp** | `prelude.hpp:561`: aggregate, mọi chỗ dùng đều designated-init đủ trường (`kActionRequests`). Không có lối đọc rác; chỉ cần `{}` để sạch tidy | Thấp |
| T-10 | C-04a | `downsample_into` noexcept nhưng `vector::resize` có thể ném | **XÁC NHẬN** | `engine/resource/upload.cpp:906-909`. Hết bộ nhớ → `std::terminate` thay vì lỗi có kiểm soát (nặng hơn trên mobile) | TB |
| T-11 | C-04b | Lambda ở `frame.cpp:36` để lọt ngoại lệ | **BÁC BỎ** | Lambda chạy qua `std::async`: ngoại lệ được giữ trong `std::future`, không thoát ra. Dương tính giả của tidy; nên ghi `NOLINT` kèm lý do | — |
| T-12 | C-05 | `has_astc` không được đọc, nghi dò ASTC bỏ dở | **BÁC BỎ** | `frame.cpp:184-186`: `has_astc` chọn `kAstc`/`kEtc2` khi `ui::kPhone`. Trên PC `kPhone` là hằng false nên analyzer thấy dead store. Dò ASTC trên mobile là thật | — |
| T-13 | C-01 | clang-tidy 653 lỗi trên 36 TU mẫu | **XÁC NHẬN (theo mẫu)** | `build\audit_C_tidy.txt`. Chưa quét 261 TU còn lại | Cao (chuẩn) |
| T-14 | C-02 | 99/657 tệp lệch clang-format | **XÁC NHẬN** (theo log C) | dry-run toàn bộ | TB |
| T-15 | A-03 | Toolchain vcpkg gắn cứng `C:/dev/third_party/vcpkg.cmake` | **XÁC NHẬN** | `CMakePresets.json:53,63`; iOS (:77) dùng `$env{VCPKG_ROOT}` | TB |
| T-16 | A-06 | `android-x86_64` kế thừa triplet `arm64-android` | **XÁC NHẬN** | `CMakePresets.json:176-186` chỉ đặt `ANDROID_ABI=x86_64`; triplet lấy từ preset `android` (:67) | TB |
| T-17 | A-05 | Shader mobile lấy từ cây build PC | **XÁC NHẬN** (theo A) | CMakeLists.txt:948-955, :992 | TB |
| T-18 | A-07 | APK 367 MB chưa cài thử; >150 MB không lên Play nếu không tách asset | **XÁC NHẬN** | build\android-arm64\thienlong.apk 16:04 | TB |
| T-19 | A-08 | Nhiều agent cùng ghi một cây build | **XÁC NHẬN (lịch sử), hiện không có** | `.ninja_lock` 16:05–16:06; lúc kiểm (16:40) không có cmake/ninja/cl/vcpkg nào chạy, chỉ có clangd | TB (quy trình) |
| T-20 | A-09 + mới | `dev/client/assets` dùng chung cho mọi preset; tài liệu mâu thuẫn ngôn ngữ mặc định | **XÁC NHẬN** | Cả hai cache đều `GAME_LANGUAGE=zh`; `AGENTS.md:50` ghi mặc định zh, nhưng `AGENTS.md:286` vẫn ghi "(mặc định `vi`)" | Thấp |
| T-21 | A-10 | vcpkg chỉ ghim baseline | **XÁC NHẬN, chấp nhận được** | vcpkg.json | Thấp |
| T-22 | B-01 | Client không nạp `ui_strings.lang.tsv` | **XÁC NHẬN + CẦN CHỦ DỰ ÁN** | `hud.cpp:226-232`: chú thích "chủ dự án muốn hết bản gốc trước, tiếng Việt để sau". `AGENTS.md:49-51`: từ 2026-10-13 mặc định zh, "vi và en … dựng lại khi chủ dự án cho phép". Vậy chưa nạp là **quyết định có ghi chép**, không phải lỗi quên | Nghiêm trọng (nếu muốn hiện bản dịch) |
| T-23 | B-02 | 7 bảng vật phẩm/kỹ năng đã dịch nhưng không ai đọc | **XÁC NHẬN** | Chỉ faces/hairs/newbie_outfits/portraits/ui_strings/scene_names đi qua `read_table`. Chưa có hệ thống túi đồ/kỹ năng | Nghiêm trọng (về kỳ vọng) |
| T-24 | B-03 | Tên "X之Y" không một luật (1.583 "Chi" / 6.722 kiểu khác) | **XÁC NHẬN + CẦN CHỦ DỰ ÁN** | Theo số liệu B | Cao |
| T-25 | B-04 | ~1.934 tên còn từ thuần Việt | **XÁC NHẬN** | ví dụ "Vai Vải Bông Vô Cực" trong khi `type_name` = "Hộ Kiên" | Cao |
| T-26 | B-05 | Viết hoa không đều | **XÁC NHẬN** | Theo số liệu B | TB |
| T-27 | B-06 | Glossary tự mâu thuẫn; 坐骑 lệch | **XÁC NHẬN + CẦN CHỦ DỰ ÁN** | `glossary.tsv`: `坐骑 mount thú cưỡi`; vi.tsv có 4.466 lần "Toạ Kỵ" | TB |
| T-28 | B-07 | 105 dòng en lẫn tiếng Việt | **XÁC NHẬN** (theo B) | | TB |
| T-29 | B-08 | ~2% sai nghĩa trong mẫu 300 (Hồn→Hỗn Thiên Nghi, Special Tool→Item…) | **XÁC NHẬN** (theo B) | | TB |
| T-30 | B-10 | en thiếu 2 khoá `file/` | **XÁC NHẬN** | en.tsv không có dòng `file/`; vi có `file/Web/coming_soon.html`, `file/Table/login_servers.tsv` | Thấp (Cao khi dựng en) |
| T-31 | B-09, B-11, B-12 | Khoảng trắng gốc; "未使用"; thiếu kiểm khi xuất lại bảng | **XÁC NHẬN**, không sửa dữ liệu | | Thấp |
| T-32 | B-13 | Tệp mới chưa vào git; script dùng một lần | **XÁC NHẬN** | `git status`: `?? src/shared/table/localize.{hpp,cpp}`, `Test/Shared/table_localize_tests.cpp`, `TOOLS/tsv_lint.py` | TB (mất mã nếu khôi phục lần nữa) |
| T-33 | C-06..C-10, C-15, C-16 | Padding, catch(...), detach luồng, đồng bộ, reinterpret_cast/memcpy, TODO, server ngoài db | **XÁC NHẬN là rủi ro cần kiểm tiếp**, chưa có lỗi cụ thể | Chưa chạy sanitizer | Thấp–TB |
| T-34 | C-14 | Mạng/giao thức chưa đủ cho online | **XÁC NHẬN, đúng kế hoạch** | gate chỉ xử lý Hello/Ping/Logout | Thông tin |

## 3. Kế hoạch sửa theo ưu tiên

### P0 — chặn ngay (≈1 ngày)
| Việc | Phát hiện | Công sức | Phụ thuộc |
|---|---|---|---|
| `git add` các tệp i18n mới (localize.*, table_localize_tests, tsv_lint) và commit | T-32 | 10 phút | Chủ dự án cho phép commit |
| Quy ước: một agent build một lúc, hoặc mỗi agent một `binaryDir` riêng | T-19 | 15 phút | — |
| Bọc `<sys/system_properties.h>` và hàm dùng nó bằng `#if defined(__ANDROID__)`, thêm nhánh Linux | T-08 | 1 giờ | Cần môi trường Linux/WSL để build thật |
| Sinh lại `Test\golden`, `SERVER\scenes`, `SERVER\tables` bằng công cụ tạo; không cho test tự bỏ qua | T-03 | 4–7 giờ | LuaPlus.dll gốc (đọc từ F:, chỉ đọc) |
| Sửa `desk_paints_notice`: so theo khoá/chuỗi đọc từ bảng đang triển khai, không gắn cứng tiếng Việt | T-04 | 1 giờ | — |
| Cập nhật hoạt ảnh thiếu hoặc danh sách gap có lý do | T-05 | 1–2 giờ | — |
| Mục tiêu P0: **92/92 test xanh** trên msvc-release | | | |

### P1 — chuẩn production (≈3–5 ngày)
| Việc | Phát hiện | Công sức | Phụ thuộc |
|---|---|---|---|
| `clang-format -i` 99 tệp, commit riêng; thêm cổng `--dry-run --Werror` | T-14 | 1 giờ | P0 xanh |
| clang-tidy toàn bộ 297 TU (+ src/server), `-fix` theo module, build + test sau mỗi module; NOLINT có lý do cho T-11, T-12 | T-13, T-09, T-11, T-12 | 2–4 ngày | format xong |
| `downsample_into`: cấp phát trước hoặc bỏ `noexcept`, trả `core::Result` | T-10 | 1–2 giờ | — |
| Preset: `$env{VCPKG_ROOT}` cho mọi preset; `android-x86_64` dùng `x64-android` | T-15, T-16 | 30 phút | Biến môi trường VCPKG_ROOT trên máy |
| Lint i18n: en không có dấu Việt; kiểm glossary; `--check-tables` | T-28, T-27, T-31 | 0,5 ngày | — |
| Sửa 105 dòng en lẫn Việt + lỗi nghĩa B-08; thêm 2 khoá `file/` cho en | T-28, T-29, T-30 | 0,5 ngày | — |
| Nối dây `ui_strings.lang.tsv` (overlay) + test | T-22 | 1 giờ | **Quyết định Q1** |
| Sinh lại tên trang bị bằng một luật duy nhất; bảng chuyển Hán Việt; quy ước viết hoa | T-24, T-25, T-26 | 1–2 ngày | **Q2, Q3, Q4** |

### P2 — mobile (≈2–4 ngày + cần thiết bị/Mac)
- Smoke test APK trên thiết bị (`adb install`, khởi động, vào màn đăng nhập); chạy ctest trên emulator x86_64 (T-18, T-16). 0,5–1 ngày. Cần thiết bị hoặc emulator.
- Shader mobile: ghi hash gói `.f2s` vào bundle và kiểm lúc chạy (T-17). 0,5–1 ngày.
- Tách asset (AAB/PAD) nếu định lên Play (T-18). 1 ngày. Cần Q6.
- iOS: `cmake --preset ios-sim-arm64` + build trên Mac/CI macOS (T-07). 1 ngày. **Cần Mac.**

### P3 — gia cố (dài hạn)
- Sanitizer: ASan/UBSan/TSan cho jobs, resource, fs; stress tạo/huỷ cho vòng đời Android (T-33). 2–3 ngày.
- Rà 23 `catch (...)`; gom `reinterpret_cast`/`memcpy` vào helper có kiểm kích thước; dọn TODO (T-33).
- Nối hệ thống túi đồ/kỹ năng qua `read_table()` + test tích hợp vi (T-23). Lớn, theo lộ trình gameplay.
- Mạng: fuzz bộ đọc khung, giới hạn kích thước, timeout, rate-limit trước khi online (T-34).
- Đổi abort test sang exit 1 (T-06); sinh i18n vào thư mục build thay vì `dev/client/assets` (T-20); sửa `AGENTS.md:286`.
- Dịch ~43k mô tả, trích quest Lua/Script.dat (1.132 tệp).

## 4. Quyết định cần chủ dự án
- **Q1. Bật nạp bản dịch giao diện (`ui_strings.lang.tsv`)?** Hiện cố ý tắt (hud.cpp:226, AGENTS.md:49-51: mặc định zh, vi/en "khi chủ dự án cho phép"). Bật thì bản dựng `vi`/`en` hiện chữ đã dịch; bản `zh` không đổi.
- **Q2. 坐骑 = "Toạ Kỵ" (4.466 ô đang dùng, đúng kiểu TLBB VN) hay "Thú Cưỡi" (glossary)?** Đề xuất: Toạ Kỵ, sửa glossary.
- **Q3. Luật tên "X之Y":** (a) "X Chi Y" (Hoang Độc Chi Miên Ti Hài), hay (b) "Y X" bỏ "Chi" (Miên Ti Hài Hoang Độc). Chọn một, sinh lại toàn bộ.
- **Q4. Quy ước viết hoa:** `name`/`type_name` Title Case, câu giao diện chỉ hoa đầu câu, "(Cấp N)" — đồng ý?
- **Q5. Có danh sách tên chính thức VNG** để đối chiếu không? Nếu có thì Q2–Q4 lấy theo đó.
- **Q6. Mục tiêu phát hành Android:** cài tay APK, hay lên Google Play (bắt buộc tách asset)?
- **Q7. iOS:** có Mac hoặc CI macOS không? Không có thì iOS dừng ở mức "cấu hình viết sẵn, chưa biên dịch".
- **Q8. Cho phép commit git** các tệp mới và các bước sửa (commit nhỏ, không thao tác phá huỷ)?
- **Q9. Bản dịch en:** 天龙百事 = "Tianlong Pepsi"? 刃 = "Edge"? 刀组类 nghĩa là gì trong game?

## 5. Giới hạn của vòng này (nói thẳng)
- Không build lại hay chạy lại test; dựa vào log của A lúc ~16:06–16:20 và đã kiểm HEAD/thời điểm tệp.
- T-04 xác nhận bằng dữ liệu, không chạy với `GAME_LANGUAGE=vi`, vì làm vậy ghi đè `dev/client/assets` dùng chung.
- Số liệu clang-tidy chỉ trên mẫu 36 TU; số liệu i18n B-03..B-08 lấy theo B, đã kiểm lại điểm 坐骑 và B-10.
- iOS: không có bằng chứng biên dịch nào.