# Tóm tắt e98e5cd (bỏ 6 pop thừa của ff730cd)

- Nguồn: b0f8904446a10c2725698758a18a78cf6c8c4b0b, bản sửa là commit e98e5cd. Worktree: D:/THIENLONG_wt/ff730cd-fix. Thư mục build: build/msvc-release.
- Lệnh: xem commands.txt và syntax_check.ps1.

## Kiểm cú pháp 6 file (syntax_before.log / syntax_after.log)
| Target | Trước | Sau |
|---|---|---|
| clang-cl x64 (VS18 LLVM) | 6/6 lỗi "pop with no matching push" | 6/6 sạch |
| NDK 30.0.16248370, x86_64-android29 | 6/6 lỗi như trên | 6/6 sạch |
| NDK, aarch64-android29 (arm64-v8a) | 6/6 sạch | 6/6 sạch |
| iOS arm64-apple-ios | **chưa kiểm, máy thiếu Apple SDK** | **chưa kiểm, máy thiếu Apple SDK** |

- arm64-v8a: thư mục sse2neon của arm64-android trong compile_commands không còn trên máy. Lần kiểm này dùng bản header-only `C:/dev/third_party/installed/x64-windows-static-md/include/sse2neon`.
- iOS: lệnh `--target=arm64-apple-ios15` bằng clang của NDK dừng ngay ở `'cstdio' file not found`, vì không có SDK. Dòng ios trong syntax_*.log **không phải kết quả kiểm**.
- **SUY LUẬN, KHÔNG PHẢI SỐ ĐO:** câu "khối pop chỉ bật khi `__x86_64__`, nên iOS arm64 vốn sạch, còn simulator Intel (x86_64) được sửa" chỉ được suy ra từ điều kiện tiền xử lý `#if defined(__clang__) && defined(__x86_64__)`. Chưa build hay kiểm cú pháp target iOS nào.

## Build / ctest
- msvc-release --fresh: KHÔNG ĐẠT ở 566/574. 7 target lỗi có sẵn từ trước, không liên quan bản sửa: world_tests, classic_tests, gui_sheet_tests, ui_flow_tests, wire_loop_tests, gate_tests, thienlong_lint. Xem build.log và build_k0.log.
- ctest: 70/85. Cùng tập 84 bài thì vẫn 69/84. Bài thêm là audio_tests, xem ctest_diff.md.

## Nợ
| Nợ | Người phụ trách | Điều kiện đóng |
|---|---|---|
| Chưa kiểm cú pháp iOS (arm64-apple-ios và simulator x86_64) cho 6 file graphic sau e98e5cd | TL Kiến trúc C++ | Chạy kiểm cú pháp `-fsyntax-only` (preset ios-arm64 và ios-sim) trên máy có Xcode, lưu log vào thư mục này |