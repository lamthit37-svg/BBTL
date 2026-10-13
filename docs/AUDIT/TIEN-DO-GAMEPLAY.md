# Tiến độ gameplay (executor-gameplay)

Cập nhật: 2026-10-13 17:52 (UTC+7)

## Phần 1: Run khi di chuyển (đang làm)

Nguyên nhân gốc (đo lại 17:46, bản msvc-release cũ, `thienlong_client --data dev\client\assets --scene-id 2 --frames 900`,
RTX 5060, Vulkan, màn 60 Hz theo Win32_VideoController.CurrentRefreshRate):

- Trình `mailbox`, 893 khung sau khi cảnh hiện, trung vị 8,3 ms, p95 8,3 ms, 893/893 khung dưới 12 ms.
- Tức là vẽ 120 khung/giây trên màn 60 Hz: một nửa số khung không bao giờ lên màn. Đồng hồ trần 120 Hz
  (`hold_pace`) không khoá pha với nhịp quét, nên khung được hiện ở mỗi lần quét có thời điểm mô phỏng lệch
  nhau 8,3 / 16,7 / 25 ms tuỳ pha trôi: bước di chuyển trên màn không đều, nhìn thấy run.
- Mô phỏng đã là bước cố định + nội suy (`simulate_motion`, `core::FixedStep`), không phải nguyên nhân.

Sửa (sao lưu ở `build\backup-gameplay-p1-20261013-174339\`):

- `frame.cpp` open_gpu: mọi nền trình `Fifo` (khung khoá vào nhịp quét).
- `face.cpp` hold_pace: không ngủ thêm khi swapchain thật sự là Fifo; đồng hồ trần 120 Hz chỉ còn cho bề mặt
  không có Fifo.
- `prelude.hpp`: sửa chú thích cho đúng hành vi mới.

Bằng chứng sau sửa (18:10, cùng lệnh, bản dựng mới):

- Trình `fifo`, 458 khung sau khi cảnh hiện, trung vị 16,7 ms, p95 17,3 ms, 444 khung 12-20 ms, 6 dưới 12 ms,
  8 khung quá 20 ms (max 35,5 ms; phần lớn là "xin ảnh" 18-32 ms, tức trượt một nhịp quét). Trong lúc đo, một
  tiến trình `msvc-asan\gui_real_tests.exe` của agent khác treo từ 17:00 vẫn ăn CPU.
- ctest msvc-release: 88/92 đạt (trước 86/91). Đỏ: ui_quest_tests, config_tests, server_data_lint (thiếu dữ liệu,
  đã biết), gui_real_tests timeout 300 s.
- Commit `2953249` (chỉ frame.cpp, face.cpp). Phần chú thích prelude.hpp đã bị commit `ff730cd` của agent khác
  gom vào. Dòng tiêu đề commit có ký tự BOM ở đầu, không amend được theo luật.

Còn thiếu: chưa có số đo bước di chuyển trên màn khi đang chạy (mới đo nhịp khung), chưa kiểm tay. 8 khung
trượt nhịp chưa tìm nguyên nhân.

## gui_real_tests (18:05)

PID 30220 và 36640 đã tự thoát trước khi kiểm. Chạy riêng `ctest -R ^gui_real_tests$ --timeout 600`: vẫn đỏ sau
310,7 s, lỗi thật là `window_boxes_match_golden`: 11952 ô lệch golden (vd BaZheTianXia_Pop_Frame golden
648,418 310x54, Hub 656,418 306x50). Timeout trước đó không phải do tiến trình treo, mà do test vốn chạy ~300 s
trong khi giới hạn là 300 s.

## Phần 2, lát HUD: trần kinh nghiệm thật (XONG, commit 0d171da)

- `hero::read_exp_table` / `hero::exp_need` (hero.hpp/.cpp): đọc DBC `Config/PlayerExpLevel.txt` (2 cột INT, STRING),
  kiểm dấu, số cột, kiểu cột, cấp liền từ 1, số dương, biên khối chuỗi.
- `apply_role` (face.cpp): `experience.top` theo cấp của nhân vật đã chọn; bảng lỗi thì in stderr, giữ trần cũ.
- Dữ liệu: chép `F:\tl 2026\_goc\Config\PlayerExpLevel.txt` sang `dev\client\assets\Config\` (SHA256 khớp; thư mục
  dev/client bị .gitignore). Bảng thật: 150 cấp, cấp 1 = 90 (khớp hằng cũ), cấp 150 = 1707414660.
- Test: `hero_tests` ca `exp_table_reads_client_layout`. ctest msvc-release 90/92; đỏ: gui_real_tests, server_data_lint.
- Sao lưu: `build\backup-gameplay-hud-20261013-180919\`.
- CÒN THIẾU: máu, khí, chỉ số ở cấp > 1 vẫn là số cấp 1 (cần bảng tăng chỉ số theo cấp hoặc gói máy chủ);
  chưa có test đọc tệp thật trong ctest; công cụ gom dữ liệu (collect_*) chưa gom bảng này, máy khác/APK sẽ thiếu;
  chưa thử tay qua màn đăng nhập.

## Bằng chứng cho QA (18:27-18:35, BUILD.lock của executor-gameplay, không ai khác test)

Mọi log ở `docs\AUDIT\evidence\`. `Test/test.hpp` giờ in một dòng `[ca] <tên>: đạt|ĐỎ (n kỳ vọng sai)` mỗi ca.

- `hero_tests_0d171da.log`: mã hero và Test/Hero không đổi từ 0d171da tới HEAD (git diff --stat rỗng); 5 ca đạt, có
  `exp_table_reads_client_layout`.
- `hero_tests_break.log`: cố ý bỏ kiểm tệp cụt và nhận chuỗi không kết thúc bằng NUL trong hero.cpp -> ca
  `exp_table_reads_client_layout` ĐỎ ở hero_tests.cpp:122 "tệp cụt thì từ chối", exe thoát 0xC0000409; khôi phục
  từ sao lưu, dựng lại, đạt. (Lần thử đầu dựng hỏng vì C4189, exe cũ chạy; log đã ghi đè bằng lần đúng.)
- `config_tests.log`: `ctest -R ^config_tests$` đạt (dữ liệu cảnh đã được luồng khác khôi phục).
- `map_tests_music.log`: ca `book_reads_scene_music` đạt; cố ý đọc cột nhạc lệch một cột -> ĐỎ 4 kỳ vọng
  (Đại Lý không ra 2106...), kéo theo book_reads_radar_token và book_reads_clip_planes đỏ; khôi phục, đạt.
- `collect_sound.log`: 2031 tệp khớp SHA256, 0 lệch; 1985/1985 id, 0 thiếu; thoát 0.
- `client_scene_0.log`, `client_scene_2.log`: "nhạc nền cảnh 0 là id 2121", "nhạc nền cảnh 2 là id 2106", đỉnh 0.75.
- `ctest_full_1830.log`: 91/92 đạt, chỉ gui_real_tests đỏ (golden, giao cho luồng dữ liệu/đồ hoạ).

## Dữ liệu của 0d171da trên máy sạch

`dev/client/` bị .gitignore nên commit 0d171da chỉ có mã; tệp `Config/PlayerExpLevel.txt` được giao bằng công cụ
`TOOLS/content/collect_sound.py` (commit 7942f28), cùng lúc với âm thanh. Máy sạch chạy:

    python TOOLS/content/collect_sound.py "<thư mục _goc của client 2026>" dev/client/assets

Công cụ chép `Sound/**`, `Config/SoundInfo.txt`, `Config/PlayerExpLevel.txt`, so SHA256 từng tệp, sinh
`sound/sound_table.xml`, thoát 1 nếu có tệp lệch hay id thiếu. Thiếu tệp thì client vẫn chạy: in lỗi ra stderr
và giữ trần kinh nghiệm cấp 1. CHƯA kiểm: android/package_apk.py có đóng gói thư mục sound/ và Config/ mới không.

## Phần 4, âm thanh: nhạc nền theo cảnh XONG (7942f28)
Còn thiếu: tiếng hiệu ứng trong cảnh (bước chân, kỹ năng, môi trường), nhạc nền trên Android (android_main.cpp
chưa nối), chưa nghe thử bằng tai.

## Chưa bắt đầu
Nhảy, nối module skill, quest_log vào desk.cpp, NPC/quái/vật phẩm, socket client tới gate, máy chủ P2.
