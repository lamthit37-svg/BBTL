# Audit A — Build system & nền tảng (2026-10-13, ~16:20 ICT)

Phạm vi: CMakeLists.txt, CMakePresets.json, vcpkg.json, cmake/, android/, apple/, build PC msvc-release, test, khôi phục 2026-10-09.
Chế độ: chỉ đọc mã nguồn. Có chạy `cmake --build build\msvc-release -- -k 0` và `ctest -j8` (chỉ ghi vào build\).
Log: build\scratch\auditA_build.log, build\scratch\auditA_ctest.log.

## 0. Tiến trình build android-arm64 bị ngắt
Lúc 16:05 không còn cmake/ninja/vcpkg nào chạy (chỉ có clangd, python của dự án khác). Không kill gì.
Lưu ý: build\android-arm64 đã có `thienlong.apk` (16:04, 367 MB) và build\msvc-release được dựng lại lúc 16:06. Như vậy **đã có agent khác build song song**. Ghi chung một cây build dễ gây tranh chấp `.ninja_lock`.

## Phát hiện

### A-01 [high] Tuyên bố "8 target lỗi biên dịch" đã lỗi thời
Bằng chứng: `cmake --build build\msvc-release -- -k 0` trả exit 0, không có `FAILED:`/`error C`/`error LNK` (auditA_build.log).
Nguyên nhân: cây mã đã được sửa sau lần đo trước.
Đề xuất: bỏ con số 8 khỏi báo cáo và tài liệu. Chạy lại cấu hình sạch (fresh) để xác nhận. Công sức: 15 phút.

### A-02 [high] 6/92 test fail trên msvc-release (không phải ~15)
ctest: ui_quest_tests, ui_create_tests, gui_real_tests, ui_panel_tests, config_tests, server_data_lint.

- A-02a ui_quest_tests:131, ui_create_tests:300 "số vàng có đủ … bước của kịch bản"; gui_real_tests:319 "golden có đủ mọi cửa sổ".
  Nguyên nhân: `Test\golden` tồn tại nhưng **rỗng**. Golden (panel/create_role_newcomer.tsv, ui_rects.tsv…) chưa được sinh lại sau khôi phục (AGENTS.md mục 0 có ghi là phải sinh lại).
  Đề xuất: sinh lại bằng TOOLS/port/lua_oracle.py (cần LuaPlus.dll gốc) và công cụ ui_rects. Không được làm test tự bỏ qua. Công sức: 2–4 giờ.
- A-02b gui_real_tests:118 thiếu hoạt ảnh (ChatSignMini_MPMJ_1, HZJYR_Luck, BaoJian1…).
  Nguyên nhân: dev/client/assets chưa được trích đủ từ bản 2026, hoặc danh sách "known gaps" đã cũ.
  Đề xuất: trích lại các tệp .animation hoặc cập nhật danh sách gap có ghi lý do. Công sức: 1–2 giờ.
- A-02c ui_panel_tests:537 desk_paints_notice: test mong chuỗi tiếng Việt "Lạc Dương (237, 236)", trong khi CMakeCache có `GAME_LANGUAGE=zh` (mặc định đổi sang zh ngày 2026-10-13).
  Nguyên nhân (khả năng cao, chưa thử với vi): test đang gắn cứng ngôn ngữ vi.
  Đề xuất: test nạp bảng i18n cố định hoặc so theo khoá, không so theo chuỗi hiển thị. Công sức: 1 giờ.
- A-02d config_tests:229–250 `../scenes/huoyangu/scene.toml` không tồn tại.
  Nguyên nhân: `SERVER\scenes` và `SERVER\tables` **không có** (SERVER chỉ còn `config`). Đây là phần thiếu do đợt khôi phục.
  Đề xuất: sinh lại SERVER/scenes và SERVER/tables bằng công cụ tạo. Công sức: 2–3 giờ.
- A-02e server_data_lint: scenes.tsv:5–7 "mẫu không khớp tệp nào", số giá trị thiếu là 16 và 239, khác known_missing.
  Nguyên nhân: cùng gốc với A-02d (thiếu dữ liệu scene server).
  Đề xuất: khôi phục dữ liệu trước, rồi mới chỉnh known_missing. Công sức: gộp vào A-02d.
- Cả 5 test C++ đều kết thúc bằng 0xc0000409. Đây là cách harness tự abort khi check thất bại, không phải crash thật. Nên đổi sang exit code 1 để phân biệt được với lỗi hỏng stack thật. Mức low.

### A-03 [high] Preset PC phụ thuộc đường dẫn tuyệt đối máy dev
CMakePresets.json:53 và :63 `toolchainFile: C:/dev/third_party/vcpkg.cmake` (msvc và android), còn iOS (:77) dùng `$env{VCPKG_ROOT}`.
Rủi ro: máy khác hoặc CI không cấu hình được. PC và mobile cũng lấy toolchain theo hai cách khác nhau.
Đề xuất: thống nhất dùng `$env{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake`. Công sức: 15 phút.

### A-04 [med] Nhánh iOS link game_jobs/game_capture — đã sửa, chưa kiểm chứng
CMakeLists.txt:577 giờ là `if(WIN32 OR ANDROID OR IOS)`, tệp sửa lúc 16:02. Nhánh iOS (dòng 23, 701–723, 906–965) chưa bao giờ qua trình dịch vì không có macOS.
Đề xuất: build thử ios-sim-arm64 trên Mac hoặc CI macOS. Đây là blocker để công bố là có hỗ trợ iOS. Công sức: 1 ngày khi có Mac.

### A-05 [med] iOS phụ thuộc shader do cây PC dựng
CMakeLists.txt:948–955: bundle iOS cần `GAME_IOS_SHADERS` chép từ build PC sang Mac.
Rủi ro mất đồng bộ PC/mobile: shader cũ có thể bị đóng gói vào bản iOS. Android (:992) cũng lấy shader từ cây PC.
Đề xuất: ghi hash hoặc phiên bản của gói .f2s vào bundle và kiểm lúc chạy, hoặc dựng shader bằng một công cụ chạy được trên host. Công sức: 0,5–1 ngày.

### A-06 [med] Test Android không chạy trên máy này
CMakeLists.txt:49–51 chạy test qua adb. Nhiều test có điều kiện `NOT ANDROID` (dòng 1115–1352), nên phần so số vàng không được phủ trên mobile.
Đề xuất: chạy ctest trên thiết bị hoặc emulator x86_64. Preset android-x86_64 chưa có gói vcpkg (AGENTS.md) và đang kế thừa triplet arm64-android. Phải sửa triplet thành x64-android. Công sức: 2–4 giờ.

### A-07 [med] APK 367 MB, chưa cài thử trên thiết bị
build\android-arm64\thienlong.apk lúc 16:04, có .idsig (ký v4). Chưa có bằng chứng đã chạy `adb install` hay khởi động thử.
Đề xuất: smoke test trên thiết bị. Cân nhắc tách asset (AAB / Play Asset Delivery), vì APK trên 150 MB không lên Play được nếu không tách. Công sức: 0,5 ngày.

### A-08 [med] Hai agent cùng ghi một cây build
Bằng chứng: .ninja_lock msvc-release 16:06:17, android-arm64 16:05:19, trong khi task được cho là đã dừng.
Đề xuất: mỗi agent dùng một binaryDir riêng (preset con), hoặc chỉ một agent được build. Công sức: 15 phút.

### A-09 [low] Nhập nhằng khoá ngôn ngữ mặc định
GAME_LANGUAGE=zh trong cache PC. Bước i18n ghi "đưa bản zh vào dev/client/assets", tức sửa thư mục assets dùng chung khi build. Đổi ngôn ngữ giữa các preset sẽ ghi đè lẫn nhau.
Đề xuất: sinh vào thư mục build, không ghi vào dev/client/assets. Công sức: 2 giờ.

### A-10 [low] vcpkg.json không ghim phiên bản từng gói, chỉ có builtin-baseline
Chấp nhận được. Có thể thêm `overrides` cho sdl3 để PC và mobile chắc chắn cùng phiên bản. Công sức: 15 phút.

## Thiếu do khôi phục 2026-10-09 (đã kiểm)
Có: cmake/*.cmake (10 tệp), third_party/libsodium/CMakeLists.txt, assets/i18n, dev/client/assets/Config/startup.id, ios_main.mm, android_main.cpp.
Thiếu: SERVER/scenes, SERVER/tables, nội dung Test/golden (rỗng). Đây là nguyên nhân của 4/6 test fail.
Chưa kiểm: 12 CMakeLists con được nêu trong AGENTS.md (glob không tìm thấy CMakeLists con nào dưới engine/src). Có vẻ dự án dùng một CMakeLists gốc duy nhất, nên mục "12 tệp còn thiếu" trong AGENTS.md cần đối chiếu lại với docs/KHOI-PHUC-2026-10-09/.

### A-11 [med] Nhảy chưa có nút chạm trên mobile
Bằng chứng: nhảy đi qua thao tác trừu tượng Display::act(PlayAct::kJump) (phím Space trên PC gọi nó, viewer_win32.cpp), nhưng android_main.cpp chỉ có TouchGestures cho camera/đi, chưa có nút chạm nào; layout giao diện gốc (bản PC) không có cửa sổ nút nhảy để dùng lại.
Đề xuất: thêm một nút chạm của dự án (vẽ trên HUD mobile) gọi Display::act(PlayAct::kJump); không thêm đường nhảy riêng cho mobile. Công sức: 3 giờ.
