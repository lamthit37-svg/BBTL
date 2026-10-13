# Đầu vào chấm chéo clang-tidy / ASan cho 97ed65b, 9d2b4c5, ff730cd, b28ab83, 5ee414f

Lập 2026-10-13, 19:20 (giờ Bangkok). Mọi build chạy trên **cây sạch** `build/xr` (git worktree tách rời tại
`7e1c6a4`, đúng mã đã commit, chỉ thêm test mới của mục (e)), không dùng cây chính vì cây chính đang có
thay đổi chưa commit của các luồng khác ngay trong các tệp được chấm (`commands.cpp`, `table.cpp`,
`upload.cpp`, `reactor_win32.cpp`, `prelude.hpp`, `CMakePresets.json`...). Giữ `build/BUILD.lock` suốt lượt.
vcpkg dùng chung `D:/THIENLONG/vcpkg_installed` (`-DVCPKG_MANIFEST_INSTALL=OFF`).

## (a) Build + ctest msvc-release
- `xreview_diff_to_head.log`: từ mỗi commit tới `7e1c6a4`, tệp của 9d2b4c5, ff730cd, b28ab83, 5ee414f **không
  đổi**; tệp của 97ed65b chỉ bị 5ee414f đổi (gate_load/upload/table, tự sửa literal suffix/contains).
- `xreview_head_msvc-release_build_ctest.log` (`ninja -k 0`): **cây đã commit không build trọn**. 7 TU lỗi,
  không TU nào thuộc 5 commit: `linttool/main.cpp` (thiếu `feed_lint_file`, lỗi có từ `9c0d49b` = origin/main),
  `world_tests` (thiếu `nav_sample.hpp`), `classic_tests`, `gui_sheet_tests`, `ui_flow_tests`,
  `wire_loop_tests` (thiếu `protocol_samples.hpp`), `gate_tests` (thiếu `metrics`). Các tệp sửa của các
  luồng đó mới chỉ nằm ở cây chính, chưa commit.
- ctest: 69/84 qua, 15 đỏ = 6 Not Run (các test ở trên; `thienlong_lint` là công cụ) + `layers` + 8 bài `0xc0000409` (core, gpu, skill, config,
  process, service, server_boot, server_boot_source_clean). `gpu_tests` đỏ ở 2 ca D3D có sẵn
  (`d3d12_depth_view_keeps_device`, `d3d11_swapchain_accepts_srgb`), không liên quan 5 commit.
- Kết luận: chưa có lượt "build xanh + ctest xanh" nào chứng minh được trên mã đã commit. Muốn có, các
  luồng phải commit phần còn thiếu trước.

## (b) 9d2b4c5, preset msvc-asan
- `9d2b4c5_msvc-asan_build_ctest.log`: `ctest --preset msvc-asan -E ^audio_tests$ -V`, 69/84 qua, **đúng
  cùng 15 bài đỏ như msvc-release**, không có báo cáo `ERROR: AddressSanitizer` nào.
- `9d2b4c5_asan_loaded.log`: `dumpbin /dependents io_tests.exe` có `clang_rt.asan_dynamic-x86_64.dll`; chạy với
  `verbosity=1` in `AddressSanitizer Init done` -> ASan thật sự nạp.
- **Không có "5 bài bị loại"**: preset không loại bài nào (`-E` duy nhất là audio_tests do mình thêm vì bài
  phát loa). Cây sạch chỉ có 84 bài; con số 86/91 không tái hiện được và không có danh sách nào ghi lại.
- Cờ (build.ninja): compile có `/fsanitize=address /Zi`, không có `/RTC*` (RelWithDebInfo không có sẵn; regex
  chỉ gỡ ở `_DEBUG`). Link: `/debug /INCREMENTAL ... /INCREMENTAL:NO /DEBUG` -> `/INCREMENTAL` **chưa bị gỡ**,
  chỉ bị đè bởi cờ sau. Không dùng `_DISABLE_VECTOR_ANNOTATION` ở đâu cả.

## (c) Số cảnh báo clang-tidy (LLVM 23.1.2)
Lệnh: `python docs/AUDIT/evidence/tidy_count.py <commit>`; cùng `build/msvc-release/compile_commands.json`
(đường dẫn nguồn đổi sang worktree `build/xt`), cùng `.clang-tidy` của cây, chỉ đếm chẩn đoán nằm trong tệp
commit đã đổi (header qua TU `cap.cpp`, `book.cpp`, `char_camera.cpp`).
- b28ab83: 66 -> 64; `bugprone-implicit-widening-of-multiplication-result` 2 -> 0; không check nào tăng.
- 5ee414f: 437 -> 373; `readability-uppercase-literal-suffix` 40 -> 0, `readability-container-contains` 10 -> 0,
  `readability-redundant-member-init` 14 -> 0; không check nào tăng.
- Chi tiết: `tidy_<commit>_counts.txt`, log đầy đủ `tidy_<commit>_{truoc,sau}.log`.

## (d) ff730cd, `#pragma clang attribute`
- Trong `prelude.hpp`: 1 `push` (dòng 7) và 1 `pop` (dòng 1317), cả hai dưới `__clang__ && __x86_64__`.
- **Nhưng commit làm gãy clang x86-64**: sáu tệp `graphic/{effect,face,frame,play,scene,stream}.cpp` đã có sẵn
  `pop` riêng ở cuối (cùng điều kiện) để đóng `push` của prelude. Nay mỗi TU có 1 push, 2 pop.
  clang-cl `-fsyntax-only -Werror=pragma-clang-attribute`: cha `9d2b4c5` 6/6 qua; `ff730cd` 6/6 lỗi
  `'#pragma clang attribute pop' with no matching '#pragma clang attribute push'`; HEAD `7e1c6a4` vẫn 6/6 lỗi
  (`ff730cd_clangcl_syntax_<hash>.log`, script `clangcl_syntax.py`). Ảnh hưởng clang-cl Windows, clang
  Linux x64, preset android-x86_64. Cần commit mới bỏ 6 `pop` thừa (chưa làm, chờ chủ luồng nhận).
- MSVC: sáu TU đó build được trong log (a) (nhánh không phải clang không ảnh hưởng).
- Chưa có lượt build clang-cl trọn cây: cây đã commit còn gãy ở (a) và ở chính lỗi này.
- Chú thích "mọi nền trình Fifo" sai ở ff730cd: đã ghi vào `docs/AUDIT/TIEN-DO-GAMEPLAY.md`.

## (e) 97ed65b, GLES không attachment
- Chặn của 97ed65b (`commands.cpp:258`) gọi `reject(fail(kBad, ...))`, lỗi trả ra ở `submit` -> **không im
  lặng**. Lưu ý: dòng 230 (có từ trước) đã chặn pass rỗng, nên chặn ở 258 là lưới dự phòng, không tới được
  khi dòng 230 còn.
- Test mới `gles_rejects_pass_without_attachment` (`Test/Gpu/gpu_tests.cpp`): pass rỗng và pass có view màu
  chết, đòi `submit` trả lỗi. `97ed65b_gles_test_pass.log`: ca qua.
- Phá thử: bỏ cả chặn 230 và 258 -> `gpu_tests` chết `0xC0000005` (đọc `first` null)
  (`97ed65b_gles_test_break.log`). Chỉ bỏ 230, giữ 258 -> ca vẫn qua (`97ed65b_gles_guard_only.log`), tức chặn
  của 97ed65b tự đứng được. Khôi phục xong, ca qua lại.
