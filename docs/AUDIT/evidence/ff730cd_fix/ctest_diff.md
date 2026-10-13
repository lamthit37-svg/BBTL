# So danh sách bài ctest: 69/84 (7e1c6a4) với 70/85 (e98e5cd)

- Mốc cũ: `docs/AUDIT/evidence/xreview_head_msvc-release_build_ctest.log` (cây `D:/THIENLONG/build/xr/build/msvc-release`, HEAD `7e1c6a4`, 19:11, 84 bài, 69 qua). Đây là log mà `asan_15_red.md` dòng 3 trích.
- Lần mới: `ff730cd_fix/ctest.log` (worktree `D:/THIENLONG_wt/ff730cd-fix`, `build/msvc-release`, nguồn b0f8904 + bản sửa = e98e5cd, `ctest --preset msvc-release --output-on-failure`, 85 bài, 70 qua).
- Cách so: trích tên bài từ dòng `Test #N: <tên>` ở cả hai log, so từng tên và trạng thái.

## Kết quả
| Bài | 7e1c6a4 (84) | e98e5cd (85) |
|---|---|---|
| `audio_tests` | không có trong danh sách | Passed (0,58 s) |

- 84 bài chung: **trạng thái giống hệt nhau**, cùng 15 bài đỏ (7 Not Run/Failed + 8 0xc0000409).
- Bài thêm là **`audio_tests`**, **không phải** `gles_rejects_pass_without_attachment`.

## Vì sao giả thuyết f6286b9 sai
- `gles_rejects_pass_without_attachment` là một **ca bên trong `gpu_tests`** (`Test/Gpu/gpu_tests.cpp:488`, đăng ký `:542`), không phải bài ctest riêng, nên không làm đổi số bài.
- `f6286b9` đã nằm trong `7e1c6a4` (`git merge-base --is-ancestor f6286b9 7e1c6a4` trả 0), nên cũng có trong mốc 84.

## Commit nào thêm audio_tests
- Không commit nào giữa 7e1c6a4 và HEAD thêm nó: `git diff 7e1c6a4 HEAD --stat -- CMakeLists.txt cmake Test/Audio` rỗng.
- `game_test(audio game_audio)` (`CMakeLists.txt:1079`, đăng ký không điều kiện) có từ `d36f5e4` (khôi phục cây nguồn 2026-10-09), theo `git log -S audio_tests -- CMakeLists.txt`.
- Chênh 84 với 85 là do **cách chạy mốc cũ**, không do commit mới. Bằng chứng: lần msvc-asan cùng loạt chạy `ctest --preset msvc-asan -E ^audio_tests$ -V` (asan_15_red.md:4, xreview_clang_asan_inputs.md:24/28 "`-E` duy nhất là audio_tests do mình thêm vì bài phát loa").
- **Giới hạn:** log msvc-release 19:11 không ghi dòng lệnh ctest (dòng 938 chỉ có `=== ctest <giờ>`). Việc nó cũng dùng `-E ^audio_tests$` là **suy luận** từ log asan cùng loạt và từ việc audio_tests đăng ký không điều kiện, chưa chứng minh trực tiếp. Lần e98e5cd không dùng `-E` nên có audio_tests và bài này qua.

## Kết luận
So cùng tập 84 bài thì kết quả vẫn **69/84, không đổi**. Bản sửa e98e5cd không thêm và không bớt bài nào.