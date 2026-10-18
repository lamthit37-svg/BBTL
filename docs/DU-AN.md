# THIENLONG — tài liệu dự án duy nhất

Cập nhật: 2026-10-16, nhánh `chuan-hoa`, HEAD `834caccb`. Đây là nơi duy nhất ghi hiện trạng,
vấn đề và hướng đi. Tài liệu khác chỉ là đặc tả tham chiếu (mục 8) hoặc sổ chi tiết; không đọc
chúng để biết "dự án đang ở đâu".

Quy tắc giữ tài liệu này sống:

- Đổi trạng thái thì sửa đúng chỗ ở đây, ghi ngày và lệnh đo. Không tạo tài liệu trạng thái mới.
- Mỗi vấn đề có mã (`A1`, `B3`...), đóng vấn đề thì ghi "ĐÃ SỬA" kèm commit rồi xoá dòng ở lượt
  chuẩn hoá kế tiếp.
- Nhãn kiểm chứng: **[tự kiểm]** là phiên 2026-10-16 tự chạy hoặc tự đọc mã. **[đọc mã]** là đọc
  mã, chưa chạy lại. **[tài liệu]** là chép từ tài liệu hay commit cũ, chưa đối chiếu. Số "đo",
  "ảnh", "test" lấy từ nhật ký cũ đều thuộc nhóm [tài liệu].

## 1. Dự án là gì

Client C++23 tự viết, nạp và vẽ lại tài nguyên của client Thiên Long Bát Bộ (XTLBB-JD 3.71, bản
2026) đúng toạ độ gốc, kèm máy chủ C++23 nhiều tiến trình và công cụ dữ liệu bằng Python. Chạy PC
Windows và Android; iOS có mã nhưng chưa từng build.

Bố cục (chốt 2026-10-12):

- `engine/` hạ tầng dùng lại được (core, io, xml, fs, jobs, audio, window, math, shader, gpu,
  resource, render, net, capture). Chỉ include chính nó.
- `src/client/` sáu nhóm `app figure place face book pack`. `src/server/` các module máy chủ.
  `src/shared/` protocol, secure, table, link, nav, collision, ids.
- `Test/<Module>/` test theo module. `TOOLS/` công cụ Python. `assets/` nguyên liệu dựng.
- `dev/` bản thử, `release/` bản chính thức (không vào git), `android/`, `apple/` vỏ mobile,
  `third_party/` nguồn chép, `cmake/` bảng tầng `GameLayers.cmake` là nguồn sự thật về include.

**Mục tiêu cuối (chủ dự án nêu 2026-10-16):** đưa source và server về chuẩn tuyệt đối, chạy được
làm mô hình nghiên cứu về TLBB; chủ dự án sẽ tự chuyển đổi sau đó. Hệ quả cho mọi quyết định:
trung thực với bản gốc, tái hiện được và an toàn đứng trước hình thức; mã port giữ nguyên toán tử
và thứ tự để đối chiếu được. Cụm TLBB gốc cũng đang chạy trên máy này và giữ cổng 7000/7001
(`dev/server/config/gate.toml` dòng 6), nên cụm thử của dự án nghe 7100/7101.

Quy mô đo ngày 2026-10-16 [tự kiểm, đếm tệp theo git]: `engine` 272 tệp 74,8 nghìn dòng,
`src/client` 387 tệp 75,9 nghìn, `src/server` 336 tệp 60,4 nghìn, `src/shared` 39 tệp 8,9 nghìn,
`Test` 221 tệp 80,2 nghìn, `TOOLS` Python 69,4 nghìn dòng.

## 2. Trạng thái đo hôm nay

Đo trên cây làm việc hiện tại, tức HEAD cộng việc dở chưa commit của phiên khác (mục A5). Chưa có
số đo trên cây sạch.

| Phép đo | Kết quả |
|---|---|
| `cmake --build --preset msvc-release` | 0 lỗi, 0 warning, dựng lại 986 bước trong 126 s [tự kiểm] |
| `ctest --preset msvc-release -j 12` | Đầu phiên 176/180. Sau khi sửa hai ca lỗi ở HEAD: **177/180**, còn 3 đỏ đều do việc dở của phiên khác (bên dưới), 80 s [tự kiểm] |
| `clang-format --dry-run -Werror` với ColumnLimit 100 | 816 trên 1032 tệp nguồn `engine` và `src` lệch [tự kiểm] |
| `shape.js engine src` | 12 218 vi phạm trong 1040 tệp: 10 564 dòng dài, 887 lồng, 412 bậc thang, 354 lồng lời gọi [tự kiểm] |
| `new`/`delete` trần trong `engine`, `src` | 8 chỗ: `audio/detail/native.cpp:155,201`, `core/thread_slot.hpp:60`, `shader/detail/slang.cpp:202,251,261`, `display/fx_view.cpp:523`, `server/play/player.cpp:72` [tự kiểm, chưa phân loại chỗ nào là COM hợp lệ] |
| `TODO(` trong `engine`, `src`, `Test` | 0 [tự kiểm] |
| Cổng hình thức của máy `check_style.js` | stub luôn trả 0, không kiểm gì [tự kiểm] |

Bốn ca ctest đỏ đầu phiên, nguyên nhân đã tra bằng cách so HEAD với cây làm việc [tự kiểm]:

| Ca | Nguyên nhân | Trạng thái |
|---|---|---|
| `protocol_catalog_fresh` | Lỗi ở HEAD. Tệp sinh và bảng cùng đổi 10-15 17:30, rồi `.clang-format` hạ trần 120 → 100 lúc 10-16 01:47; bộ sinh bẻ dòng theo trần cột nên tệp sinh cũ đi | **ĐÃ SỬA**: sinh lại `messages.hpp` và `protocol_samples.hpp`; so token thấy chỉ khác khoảng trắng và dấu `//` do bẻ lại chú thích |
| `config_tests` ca `real_gate` | Lỗi ở HEAD. `834caccb` đổi `gate.toml` sang `127.0.0.1:7100/7101` (7000/7001 do cụm TLBB giữ) nhưng test còn đòi `0.0.0.0:7000/7001` | **ĐÃ SỬA**: cập nhật kỳ vọng (`config_tests.cpp:325-328`) |
| `config_tests` ca `real_zone` | Test đòi `language == "vi"` (`:411`), còn `zone.toml` đang sửa dở đặt `zh` đúng theo quyết định mặc định `zh` | MỞ, thuộc việc dở. Sửa kỳ vọng thành `zh` khi phiên đó commit |
| `layers` | 4 vi phạm: `main.cpp → ui` (`ui/cjk_trace.hpp`), `online/bridge.cpp` và `bridge.hpp → net`, `viewer → client/host`. Không include nào có ở HEAD | MỞ, thuộc việc dở. Phiên đó chọn sửa mã hay sửa bảng tầng `GameLayers.cmake` |
| `ui_text_tests` ca `writer_clip` | 2 kỳ vọng sai (`ui_text_tests.cpp:325,330`); `ui/text.cpp` đang sửa dở (+40 dòng) | MỞ, thuộc việc dở |

Git [tự kiểm]: `chuan-hoa` hơn `main` 31 commit; `main` hơn `origin/main` 52 commit, nên 83 commit
chưa lên origin. Cây làm việc: 75 tệp sửa và 12 tệp mới chưa commit, đều của phiên khác. Bốn
worktree `agent-*` ở trạng thái `prunable`. `build/` nặng 27 GB, `dev/` 20 GB, `release/` 17 GB.

## 3. Đang ở đâu

Phần này tóm từ `AGENTS.md`, `docs/TIEN-DO.md`, `docs/NGHI-NGO.md`, `docs/KE-HOACH-SERVER.md` và
git log, rồi sửa theo mã ở những chỗ chúng mâu thuẫn nhau (24 chỗ, xem A1). Mọi nhãn "đo" là của
nhật ký cũ [tài liệu].

### Đồ hoạ và nền tảng

- Vulkan (mặc định) và GLES vẽ lên cửa sổ. D3D12 và D3D11 vẽ Đại Lý như Vulkan, lớp kiểm tra
  báo 0 lỗi, `gpu_tests` 49/49 (2026-10-17, `a0b31fa3`; xem E3). GLES dừng phát triển.
- Khởi động GPU không còn tạo thiết bị thừa (2026-10-17): khung đầu D3D12 1014 → 652 ms
  (`bench_load.py`, 10 lượt); Vulkan mặc định 592 → 598 ms, trong nhiễu. Swapchain Vulkan dựng ở
  luồng phụ: khung đầu Vulkan 566 → 498 ms (TIEN-DO cùng ngày).
- Vulkan hạ xuống lõi 1.1 và chạy trên tablet PowerVR GE8320 (`e10bdbdc`); màu thô cho Vulkan trên
  điện thoại 43,9 → 40,1 ms (`db617d7d`).
- Trên cửa sổ khoá Fifo vào nhịp quét, nâng Hz theo `loop_plan`; đo 120 Hz, 99,8% khung đúng một
  nhịp. Tablet màn đăng nhập về 30,0 FPS, hết chớp LOD (`d9d7665e`, `23ec96f8`).
- Android: APK chạy trên TB-X306F, có cảm ứng, IME, trần khung theo `RateGovernor`. iOS: chưa
  build lần nào, máy không có macOS (E1).
- Shader HLSL của client gốc (100 tệp, 289 chương trình) chuyển thành gói .f2s cho SPIR-V, DXIL và
  DXBC qua Slang (2026-10-18, target `game_origin_shaders`). Mã máy fxc của bản đã chuyển trùng bản
  gốc 289/289. Chưa nạp vào lượt vẽ, chưa so ảnh (NGHI-NGO 64).
- Tablet giữ 60 Hz ở Đại Lý (2026-10-17): địa hình ghép toạ độ atlas ở đỉnh nên không điều tốc đạt
  59,6 FPS (trước 46,5); điều tốc không còn kẹt ở 30 (khung đầu 59,9 FPS, 58,4 cả lượt 45 giây);
  nạp cảnh vẫn 8,7–10,4 giây. Trôi dần xuống ~57,7 FPS sau ~25 giây chạy, cả khi không điều tốc.
  Hiệu ứng ngoài khung nhìn không còn dựng quad (PC: 3852 xuống ~500 quad, CPU chặng hiệu ứng 0,55
  xuống 0,15 ms); chưa có số sạch trên tablet. Số đo ở `TIEN-DO.md`, chỗ chưa chắc ở NGHI-NGO 63.
- Tablet, cùng ngày (tối): luồng vẽ ghim ở cụm lõi mạnh (`core/cores.cpp`); điều tốc, bảng đo và
  "Khung chậm" đếm nhịp màn thật suy từ acquire (`core/cadence.hpp`), khớp SurfaceFlinger từng cửa
  sổ 10 giây. Đứng yên: 59,87 FPS, bảng đo xanh hết, không lùi về 30. Đi bộ: máy về 30 Hz thật, đỉnh
  là HUD relayout ~40 ms mỗi lần toạ độ minimap đổi (NGHI-NGO 63j, chưa sửa).

### Map, nhân vật, hiệu ứng

- Địa hình, vật thể tĩnh, hạt cộng sáng, nước và vòm trời của bản 2026. Nước và vòm trời có mã
  vẽ, chưa ai đối chiếu ảnh [tài liệu].
- Bầu trời EnScene của Render.dll (vòm, mây, mây vòng, trăng, mặt trời, sao, EnvKey, hiệu ứng nền) vẽ
  theo mã máy, đã chụp màn đăng nhập (2026-10-16). Còn thiếu: chùm sáng mặt trời, trộn nhiều vùng, tắt
  dải `.skysphere` cũ, gom tài sản các map khác. Chi tiết và danh sách: `docs/TAILIEU/EN-SCENE-RENDER-DLL.md` mục 12.
- Sương mù của cảnh (tuyến tính và cao độ, từ Scene, `.hfog` và EnvKey) và object Model có xương (quạ bay,
  quạ đậu ở màn đăng nhập, `avatar::Ambient`) đã bật, chụp màn đăng nhập thấy quạ vỗ cánh (2026-10-16).
  Chưa đối chiếu sương với ảnh bản gốc; lệch pha giữa các quạ chưa làm.
- Hạt mesh dựng theo mã máy (2026-10-16): màu và độ mờ của hạt, `local_position`, `local_rotation`, bề sâu mặc định 0
  và sáu kiểu `orientation_type`. Tấm sương `远景雾片` nay nằm sau núi xa thay vì phủ xám lên núi. Sương thung lũng còn
  nhạt hơn ảnh gốc (`docs/NGHI-NGO.md` mục 61). Logo "Thiên Long Bát Bộ" chủ dự án đưa thay logo gốc ở góc
  trên bên phải bảng đăng nhập (`assets/i18n/<mã>/logo.png` qua `image/CommonFrame9/Logo`); ánh lửa của đèn giả phơ phất
  theo thời gian (mục 13 của `docs/TAILIEU/EN-SCENE-RENDER-DLL.md`).
- Đèn giả FakeLight (51 đèn ở màn đăng nhập: đầu Phật, miệng quỷ) tính ở điểm ảnh của model và địa hình, chụp
  thấy mặt Phật ánh cam, mặt quỷ ánh xanh (2026-10-16). Trăng to thêm 30% theo yêu cầu. Máy yếu (GLES, ánh
  sáng ở đỉnh) bỏ đèn giả; shader GLSL dịch được bằng glslangValidator (310 es và 450 core), chưa chạy ở thiết bị.
  Chi tiết: `docs/TAILIEU/EN-SCENE-RENDER-DLL.md` mục 13.
- Người chơi có xương trên PC và tablet. Vũ khí bảy khe, đòn thường, tuyệt chiêu, hiệu ứng đá quý
  chạy bằng công cụ thử `--weapon --skill --gem --auto-strike`. Nhảy có mã, chưa ai nhìn tận mắt.
- Quái và NPC vẽ từ tin máy chủ. Người chơi khác có mã `show_player` và cờ `--peer` (`834caccb`),
  chưa có mục nhật ký nào xác nhận đã kiểm.
- Thú cưỡi (2026-10-18, `--mount <id>`, 353 dòng `rides.tsv`): clip người cưỡi tách theo giới
  (`ride_anims.tsv` cột race). 105 thú dùng chất liệu luồng sáng, viền sáng của
  `Model_Flow_ps.hlsl`: bảng `Material/programs.tsv` (`TOOLS/content/export_material_programs.py`,
  3457 chất liệu) vẽ trong `model.ps`, kèm pass ghi độ sâu của mẫu hai pass. Hiệu ứng gắn theo mã
  máy Render.dll (`translateAll` thiếu thì giữ trục thế giới). Emitter vùng, góc nón, xoay billboard,
  `billboard_origin`, `scroll_anim`, scale UV, vệt NewRibbonTrail, hạt mesh one/one theo mã máy
  Plugin_ParticleFX và OgreMain. Chụp trên Vulkan, D3D12, D3D11. Còn mở: NGHI-NGO 65. Ngày 10-18 sửa hai lỗi
  chủ dự án chụp: tên mẫu `all.obj` lệch hoa thường (330, 329 mất neo ghế và hiệu ứng) và tấm trộn
  `zero one_minus_src_colour` (393, 383, 298, 3 mẫu) nay có pipeline riêng; hiệu ứng của 329, 330 chờ nạp lại
  `Effect/all.effect` (NGHI-NGO 65 k).
- Nạp đầu cảnh Đại Lý: 387 ms ngày 10-13, đo lại 490–528 ms, vượt ngân sách 450 ms, chưa kết luận
  (C3).

### Giao diện

- HUD nạp 36 layout; khung nhân vật, minimap, bảng nhân vật có số nhưng số lấy từ `hero::newcomer()`
  viết cứng. Túi, thương thành, sách kỹ năng, trân thú, hảo hữu, tổ đội mới là khung.
- Lua: máy LuaPlus 5.0.1 gốc khớp 2 060/2 060 đơn vị. Thực tế mới chạy bằng script đúng hai cửa
  sổ (`kScripted` ở `ui/hud.cpp:160`: ProgressBar, DebugListBox). Hàm game tầng B đang thêm theo
  các làn A/B.
- Đăng nhập `--login` (chỉ PC) và tạo nhân vật theo số vàng của `CreateRole.lua`. Combobox đuôi tài
  khoản theo mã gốc.

### Client nối máy chủ

- Có `session` và `online`: SignIn 195 ms, Create 257 ms, EnterGame 303 ms trên cụm thật, bằng
  chương trình thử tạm. Client gửi `Move` mỗi 50 ms (`session.hpp:137` `kMoveEvery{50}`) [đọc
  mã]. Vẽ thực thể từ `Entity*`. Hội thoại, nhiệm vụ (protocol v5), chiến đấu (v6) phía client có
  test và đường vẽ thử `--talk-demo`.
- **Chưa ai chạy client thật với cụm v6** (C1).

### Máy chủ

- Bảy exe dưới trình giám sát: supervisor, stored, authd, billingd, worldd, zoned, gated. `world`
  mới in `ready` rồi chờ.
- `gate`: bắt tay X25519/Ed25519, tick 60 Hz, tách cổng auth và game; 2 000 khách p99 12,4 ms,
  10 000 khách vỡ (B5). `auth`, `store`: vòng thật trên PostgreSQL 18.6.
- `zone`: tick 20 Hz, lưới AOI, 47 970 chỗ đặt quái và NPC, luật đi theo `.path`, AI quái tất
  định, hội thoại, nhiệm vụ, chiến đấu, đồ rơi. `thienlong_bot --fight` hạ 12 quái, +330 kinh nghiệm.
- `billing`: sổ điểm chỉ-thêm, webhook HMAC, đổi điểm hai pha; chưa nối `world` (B14).
- Lõi `item loot shop forge social` đã có và có test. Mới `loot` nối vào `zone` (qua `play`, túi
  riêng `play::Bag`); `social`, `shop`, `forge`, `item::Inventory` chưa ai gọi (grep ngoài module
  ra 0) [đọc mã].
- Database: 9 migration (auth 2, billing 5, game 2). Nhiệm vụ ghi được vào PostgreSQL.
- Mốc `KE-HOACH-SERVER.md` mục 10: P0, P1 đạt; P2 đạt về thực chất; P3 thiếu hai tiêu chí; P4 đạt
  một phần; P5–P8 có lõi và lát cắt 2/3; P9 chưa nối `world`; P10–P12 chưa bắt đầu.

### Công cụ dữ liệu và bản địa hoá

- `build_data.py` dựng cả cây bằng một lệnh, chạy hai lần ra cùng SHA-256. `thienlong_lint`: 5 083
  tệp 0 lỗi. `gen_protocol`, `cfgtool`, `collect_*`, `export_*`, `lua_extract` (1 349 nhiệm vụ,
  1 063 chạy được).
- Bản địa hoá chọn lúc dựng. **Mặc định `zh`** (chủ dự án chốt 10-13, nhắc lại 10-16). Bản `vi`
  dựng xong, nhìn ảnh ngày 10-16 rồi bị hoãn cùng ngày; cây đang ở trạng thái lửng (D1).
- Giao diện đã trả về gốc (chủ dự án yêu cầu 10-16, i18n triệt để để sau) [tự kiểm]: 28 atlas
  `dev/client/assets/Interface/**/*.png` trùng từng byte với bản gốc ở `build/i18n/base` (nhìn ảnh:
  nút 充值/兑换 vẫn chữ Hán), không còn `Table/*.lang.tsv` (`i18n.applied.tsv` còn nhưng rỗng 0
  byte), `login_servers.tsv` và `coming_soon.html` là bản `zh`, bảng chữ và Lua không còn chữ Việt
  hiển thị. Chữ Việt còn trong mã `src/client` đều là log, thông báo lỗi hoặc bảng đo `ui/pace`
  (công cụ dev). Đã đổi nút "Đóng" của trang web trên iOS (`ios_main.mm:326`) thành "关闭", chưa
  build (không có macOS). Tên ứng dụng giữ "Thiên Long Bát Bộ" (chủ dự án chốt 10-16:
  `viewer.hpp:36`, `AndroidManifest.xml`, `CMakeLists.txt` bundle iOS). Icon là icon gốc của
  `Game.exe` 2026 (con rồng đồng; icon cũ là hình tam giác tự vẽ): `TOOLS/content/export_app_icon.py
  <Game.exe>` ghi `assets/icon1.ico` và `icon2.ico` (byte nguyên của RT_ICON, nhóm 107 và 108 cùng
  một bộ ảnh 16/24/32/48/64/256), `android/res/mipmap-*/ic_launcher.png` (aapt2 qua `package_apk.py
  --res`) và `apple/icons/*.png` (nền đen vì App Store cấm alpha; chưa build trên macOS). Ninja
  không biết `app.rc` đọc `.ico` nên exe giữ icon cũ sau khi đổi ảnh; đã khai `OBJECT_DEPENDS`.
- APK `build/android-arm64/thienlong.apk` và `release/client/APK/thienlong.apk` dựng lại 2026-10-16
  21:19 từ cây hiện tại (`cmake --build --preset android-arm64 --target thienlong_apk`; không build
  mọi target vì test máy chủ của cây Android đang thiếu include `guard/pace.hpp`): `.so` 21:12,
  12 297 tệp, mang logo mới, hạt mesh theo mã máy, thác cuộn UV và shader ánh lửa. Hai lỗi chặn
  đường đi tới APK đã sửa cùng ngày: (1) `bake_mobile_textures.py` đọc `x.dds` gốc nên ảnh giao diện
  địa hoá (`x.dds.png`, như logo) không bao giờ lên điện thoại và kiểm tươi báo 0 tệp cần nấu; nay
  theo luật `sheet_file` của painter (cùng cỡ mới thay), nấu lại 8 tệp. (2) `decode_model` bỏ
  `scroll_anim` nên thác đã có cache đứng im trên cả PC lẫn gói điện thoại (chỉ mang cache). Chưa
  cài lên thiết bị nên chưa nhìn màn hình thật. iOS: không có thay đổi riêng, vẫn chưa dựng được
  (không có macOS); hai sửa trên cũng áp cho bundle iOS vì dùng chung bộ nấu và `decode_model`.
- Packer `.tlpak` (`TOOLS/bake/bake.py`, `thienlong_seal`): đã chạy vòng `new-key`, `seal`, `verify`,
  `open` với cụm mật khẩu (Argon2id mức vừa): byte mở ra trùng, lật một byte thì `verify` thoát 1,
  bản mã không chứa chữ gốc; 24 test Python đạt (2 bỏ qua vì thiếu quyền symlink của Windows), gồm test chéo
  Python ↔ `thienlong_seal.exe` mở được gói của nhau. Game cố ý không đọc gói này. Khi không đặt
  `BAKE_PASSPHRASE` mà chạy với stdin là `NUL` trên Windows thì `bake.py` treo chờ bàn phím (xem
  `docs/NGHI-NGO.md` mục 62).
- Thoại máy chủ bản `vi`: 2 507 câu, `dialogue_i18n.py check` 0 lỗi; máy chủ chưa nạp ngôn ngữ nào.

## 4. Vấn đề

Mức: **chặn** là chặn mốc kế tiếp hoặc một nền tảng đích; **cao** là người chơi thấy sai hoặc có
rủi ro dữ liệu/bảo mật; **vừa** là lệch gốc nhưng có đường vòng; **thấp** là thẩm mỹ, tài liệu,
suy đoán.

### A. Dự án và quy trình

| Mã | Mức | Vấn đề | Bằng chứng |
|---|---|---|---|
| A1 | cao | Tài liệu trạng thái mâu thuẫn mã ở 24 chỗ. Ví dụ: `AGENTS.md:104` "chưa gửi Move" trong khi `session.hpp:137` đã gửi; `WEB/` đã gỡ ở `8a714e17` nhưng còn được nhắc ở 6 tài liệu; `AGENTS.md` đối chiếu mã ngày 10-14 (`1ff6703`) khi HEAD là `834caccb`; "Gameplay chưa nối zone" trong khi `zone/host.cpp:158` đã dựng `play::Gameplay` | [đọc mã] |
| A2 | cao | Không có cổng hình thức nào thi hành. `check_style.js` là stub (gỡ 2026-10-08, luôn trả 0), `CLAUDE.md` V.5 ghi sai là trả 1. Cổng thật `shape.js` chỉ chạy như hook cấp người dùng, chưa gắn vào CMake | [tự kiểm] |
| A3 | cao | Mã chưa khớp trần cột 100 vừa hạ từ 120 (`45fd7c75`, 10-16): 816/1032 tệp lệch. Chính sách đã chốt 10-15 là "chạm tệp nào chuẩn tệp đó, cấm dọn hàng loạt", xung đột với yêu cầu chuẩn hoá tuyệt đối | [tự kiểm]; quyết định D-1 |
| A4 | vừa | Ba ca ctest còn đỏ, đều do việc dở của phiên khác; hai ca lỗi ở HEAD đã sửa (mục 2) | [tự kiểm] |
| A5 | cao | Cây làm việc dùng chung nhiều phiên: 75 tệp sửa và 12 tệp mới của phiên khác chưa commit, nên mọi phép đo hôm nay đo trên cây lẫn. 83 commit chưa lên origin | [tự kiểm] |
| A6 | thấp | Rác: 4 worktree `agent-*` prunable và 4 nhánh `worktree-agent-*`; `build/` 27 GB với 20 thư mục `backup-*`, hàng chục log, ảnh chụp lẻ (trái quy ước "build chỉ chứa thứ xoá đi dựng lại được") | [tự kiểm] |
| A7 | vừa | Comment trỏ tới tài liệu không tồn tại: `docs/NHIEM-VU-VO-CONG-2026.md` (15 tệp), `docs/modules/*.md` của Forge2 (8 tệp engine), `docs/CON-TRO-2026.md`, hồ sơ `so-do/...` của DH-DOT-1 (17 dòng ở `src/shared/collision`), 19 chỗ viết `tests/` thay vì `Test/`. Sau đợt lưu trữ 10-16 còn thêm các chỗ trỏ vào tài liệu đã chuyển: 22 dòng trong `TIEN-DO.md` (nhật ký), 4 dòng `# source:` ở `TOOLS/server/*.tsv`, `src/shared/protocol/wire.hpp:3`, `CMakeLists.txt:1515`. Tất cả là comment hoặc macro không ai đọc, không làm gãy build hay test | [tự kiểm bằng `git grep`] |
| A8 | vừa | `NHIEM-VU-VO-CONG-2026.md` mất thật: bản trong thư mục khôi phục chỉ có 223/6 226 dòng thật, còn lại là `⟪thiếu dòng này⟫`. Đặc tả của `book/quest`, `book/skill`, `quest_log` không còn | [tự kiểm]; quyết định D-5 |
| A9 | vừa | Hai bộ luật hình thức mâu thuẫn: `CLAUDE.md` mục 0.3 giới hạn comment đầu tệp 15 dòng và cấm ghi tác giả, còn khung ENGINEHP dài 16–18 dòng có TÁC GIẢ (CTO duyệt ngoại lệ 10-15, ghi ở `NHAT-KY-CHUAN-HOA`, nay lưu trữ). `CLAUDE.md` chưa ghi ngoại lệ đó | [tài liệu]; quyết định D-6 |
| A10 | thấp | Luật `// TODO(...)` phải có mục ở `docs/NGHI-NGO.md` không có cổng. Mã hiện 0 TODO nên chưa phát sinh | [tự kiểm] |
| A11 | thấp | `CMakeLists.txt:1513-1515` đặt macro `GAME_COLLISION_COUNTS` trỏ tệp không tồn tại, không mã nào đọc; `forge2_port.py:27` mặc định trỏ `D:/The-Forge/Forge2` đã mất | [tự kiểm] |
| A12 | vừa | Thiếu tái hiện: `F:\tl 2026` còn nhưng không có `Bin64`, `_raw`, `2026`; Forge2 không còn ở cả hai đường dẫn cũ. Lệnh tái hiện địa chỉ trong tài liệu client 2026 không chạy được; khoảng 180 địa chỉ `Game.exe` rơi giữa lệnh (NGHI-NGO 53) | [tài liệu + agent tự kiểm] |

### B. Máy chủ, mạng, bảo mật

| Mã | Mức | Vấn đề | Bằng chứng |
|---|---|---|---|
| B1 | cao | Gate bỏ lặng mọi khung zone lớn hơn 4 104 byte, không log (`gate/table.cpp:575`; `kMaxPlainBytes = 8+4096`), trong khi thân `DialogOpen` tối đa 29 473 byte (`PROTOCOL-TIN.md:403`). Chưa biết zone có sinh khung lớn thật không | [tự kiểm] đọc cả hai phía; chưa đo |
| B2 | cao | `auto_register = true` ở cả `dev` lẫn `release/server/config/auth.toml:25`: đăng nhập bằng tên chưa có thì tạo tài khoản | [tự kiểm]; quyết định D-2 |
| B3 | vừa | Bắt tay X25519 và ký không có giới hạn nhịp; chỉ có trần số kết nối đồng thời mỗi IP (`table.cpp:339`, `:1576-1590`) | [đọc mã] |
| B4 | vừa | Ban hoặc cap hết hạn giữa phiên không bị kiểm lại ở `on_move` (`table.cpp:1212-1224`) | [đọc mã] |
| B5 | vừa | Gate 10 000 khách: tick vỡ, p99 121 ms; chưa đo lại sau khi sửa lỗi trôi hạn tick (NGHI-NGO 44a). Heartbeat ghi cứng 1 s (`table.cpp:790`) | [tài liệu] |
| B6 | vừa | Client không kiểm `Welcome.version` với `kVersion` (`link.cpp:166-168`) | [đọc mã] |
| B7 | vừa | Hàng đợi client đầy `EntityAppear` (không bỏ được) làm client mất phiên (`session.cpp:118-122,211-214`) | [đọc mã] |
| B8 | vừa | `zone` cổng store = 0 vẫn chạy nhưng không lưu gì (`serve.cpp:285`); hết hạn xả lúc dừng thì bỏ hàng chờ ghi điểm đứng (`saver.cpp:109`); kênh gate đầy thì bỏ phần thư còn lại (`serve.cpp:193`, có chủ ý) | [đọc mã] |
| B9 | vừa | Serial vật phẩm vẫn tiến khi plan thất bại, người chơi có thể đốt cạn serial (`item/planner.hpp:11`, `shop/trade.cpp:106`) | [đọc mã] |
| B10 | vừa | `Journal::record` đuổi bản ghi giả định id tăng đơn điệu, hợp đồng không được kiểm (`ledger/ledger.cpp:169`) | [đọc mã] |
| B11 | thấp | `zone/host.cpp:464` `drop_all` duyệt `unordered_map`, thứ tự lưu và đóng không tất định | [đọc mã] |
| B12 | thấp | `ipc` không chống phát lại (`ipc/link.hpp:20`), chỉ nằm trên loopback | [đọc mã] |
| B13 | thấp | `SECURE_DROP_LENGTH_CHECK` là chốt thử của bộ fuzz nằm trong mã sản xuất (`secure/record.cpp:88-110`); bản thường có kiểm độ dài. Nên tách ra khỏi mã chính | [tự kiểm] |
| B14 | vừa | Billing: `max_clients` vô hiệu (`config/billing.cpp:51`), `world` chưa nối billing, chưa có bộ chuyển VNPay/MoMo, chưa xác thực GM, tỉ giá và quà còn tạm | [đọc mã] |
| B15 | vừa | `pg.cpp:111` `sslmode=disable`; `account/rpc.cpp:68` ép độ dài text về u16 không kiểm | [đọc mã] |
| B16 | vừa | `PollSet` giữ handle thô, OS cấp lại handle thì nhầm tag (`net/net.hpp:232`); `jobs.cpp:1080-1082` có đường `detach`; không xử lý `EPIPE` ở `socket_posix.cpp`; `messages.cpp` không đối chiếu `body.size()` với `body_bytes` | [đọc mã] |
| B17 | thấp | `game_reject_foreign` chỉ bắt `#include "..."` chữ thường (`CMakeLists.txt:131`, `GameLayers.cmake:142` cùng mẫu): lọt `<>`, chữ hoa, gạch nối | [đọc mã] |
| B18 | cao | Gói `.f2s` không mang số đời giao kèo, APK có thể nạp gói shader lệch đời (NGHI-NGO 45l) | [tài liệu] |
| B19 | cao | Luật đi chỉ kiểm điểm đến, không quét đoạn và trục Y, có thể xuyên tường mỏng (`zone/scene.cpp:221-224`); điểm đặt quái nằm ngoài lưới, Đại Lý 50/164 (NGHI-NGO 54) | [đọc mã + tài liệu] |
| B20 | cao | Chiến đấu máy chủ (NGHI-NGO 57): kỹ năng ban đầu là luật tạm; chưa có trang bị; nhặt đồ làm mất thuộc tính vật phẩm; quái chưa phản công; đường chết và hồi sinh chưa test; arena chỉ tick khi có người | [tài liệu] |
| B21 | vừa | Nhiệm vụ: 827/1 617 id nhiệm vụ của client không có dòng ở máy chủ; thiếu 22/25 nhiệm vụ chuỗi tân thủ; NPC mời nhiệm vụ đòi cấp 20/30; nhiều lựa chọn menu trả `kNoSuchEntity` | [tài liệu] |
| B22 | vừa | Linux chưa dựng lần nào; TSan chưa chạy; nhánh POSIX (`reactor_posix`, `socket_posix`) và `system_posix` chưa chạy. Lỗi `system_properties.h` đã sửa trong mã (`8e13f0d4`) nhưng `AGENTS.md:116` và NGHI-NGO 45a còn ghi lỗi cũ | [đọc mã] |
| B23 | vừa | Máy chủ chưa nạp chữ thoại và chưa chọn ngôn ngữ (bộ nạp trong cây chưa commit); bộ nạp tệp đè `config/tables`, `config/text` chưa có; `starter.hpp:23` `kMotto` còn chữ Hán | [đọc mã] |

### C. Client

| Mã | Mức | Vấn đề | Bằng chứng |
|---|---|---|---|
| C1 | cao | **ĐÃ SỬA** 2026-10-18 (gói G0: `9adc2de5`, `d08b9b6e`, `bba77680`): client thật tự đăng nhập, tạo nhân vật, vào Đại Lý và đi trên cụm v7, chạy bằng `TOOLS/run/e2e_client.py TOOLS/run/e2e/g0.script` không chiếm chuột; bot quan sát thấy client, log kiểm của zone ghi từng việc | [tự kiểm 2026-10-18] |
| C2 | cao | `SceneDefineEx` client đang nạp không phải bảng 2026: 297 so với 680 dòng, 43 dòng khác, thiếu 395 id (NGHI-NGO 20) | [tài liệu] |
| C3 | vừa | Nạp đầu 490–528 ms, vượt ngân sách 450 ms (NGHI-NGO 51g); phải nhanh hơn `G:\TLBB` là cam kết của chủ dự án. Đo lại 2026-10-17: trung vị 566 ms; swapchain Vulkan dựng ở luồng phụ → 498 ms. Còn lại trên luồng vẽ: `prepare_hud` ~70 ms thuần CPU, mesh ~90 ms sau `Display::create` | [tài liệu + tự kiểm] |
| C4 | vừa | Mô hình cảnh còn thiếu ở góc trái tablet, nghi LOD thô (`TIEN-DO.md:2884`); APK bản `vi` chưa dựng | [tài liệu] |
| C5 | vừa | HUD: số viết cứng `hero::newcomer()`; `--ui-event OPEN_WINDOW` không mở được túi, sách kỹ năng, bản đồ, sổ nhiệm vụ; module `book/skill` không nơi dùng (`grep '#include "skill/'` ngoài chính nó: 0) | [đọc mã] |
| C6 | vừa | Camera: 59 cảnh `SpecialSceneCamera` chưa nối; tia chuột trúng mặt công trình chưa nối (`raycast(` không có trong `src/client`); ô `+0x260` chưa tháo hết | [đọc mã] |
| C7 | vừa | Đường đi: nhấp sát vách không ra lệnh (14/32 lần); thiếu thuật toán dự phòng, vùng cấm động, trạng thái bay, câu báo "không tới được"; số vàng `Test/golden/nav_*.tsv` không còn nên test tìm đường tự bỏ qua | [đọc mã] |
| C8 | vừa | Điện thoại: chưa có phông vector, chưa có bản thiết kế `Interface/phone/` theo khung 1080 (đang dùng bộ tạm, HUD co khung ảo 800x640) | [đọc mã] |
| C9 | vừa | Animation (NGHI-NGO 52): sampler lệch số đếm thì `.at()` ném và chương trình thoát 1; key times không sắp thì nội suy sai thầm; `check_same_bones` chỉ so tiền tố; NaN/Inf lọt | [tài liệu] |
| C10 | vừa | Âm thanh giải mã trên luồng game, thu hồi clip chờ tới 200 ms (NGHI-NGO 14) | [tài liệu] |
| C11 | thấp | Chiến đấu client: số bay dùng phông bitmap, `Declined` không hiện, người chơi chết không có động tác, tầm 2,5 m dùng chung mọi chiêu; client chưa dùng GPU timestamp | [tài liệu + đọc mã] |
| C12 | vừa | **ĐÃ SỬA** `a0b31fa3`: `submit` chỉ ghi `submitted` khi `Signal` thành công (`d3d12/device.cpp:877-881`) | [tự kiểm] |

### D. Dữ liệu và bản địa hoá

| Mã | Mức | Vấn đề | Bằng chứng |
|---|---|---|---|
| D1 | vừa | Cây `vi` lửng: `cmake/GameI18n.cmake` (chưa commit) đặt `zh` và gỡ `thienlong_i18n` khỏi lượt dựng thường, trong khi `ui_i18n_tests`, `cjk_trace`, `assets/i18n/vi/labels/`, `Merienda-Bold.ttf`, `zone.cpp [text] language` còn chưa track; NGHI-NGO 60 viết như thể `vi` đang chạy. Lỗi gốc đã sửa 10-16: `trace_assets.py` ghi cả `*.lang.tsv` vào `mobile.files.tsv`, nên khi trả về `zh` thì `package_apk.py` dừng với "thiếu 9 tệp"; nay vết bỏ lớp dịch (`Table/` vốn đóng nguyên thư mục) | [tự kiểm] |
| D2 | vừa | Quy trình dịch không tái lập: `ui_batch.py` và `inventory.tsv` chỉ còn trong `build/i18n_extract` (bị ignore), `C:\tlx` mất | [đọc mã] |
| D3 | vừa | Tên trang bị dịch không theo một luật (NGHI-NGO, T-24/25); 坐骑 dịch hai kiểu; 13 ảnh `#CHO_ANH`; chưa dịch tên quái | [tài liệu] |
| D4 | thấp | `cfgtool/schema.py` thiếu `[text] language` của `zone.toml`, nên `cfgtool check` có thể báo "nhóm lạ"; còn 94 tên cột `?` chưa chốt, ba khoá chưa rõ nghĩa | [đọc mã] |
| D5 | vừa | Dữ liệu cảnh chỉ có đủ trên máy này: `walk.nav` 310 tệp nhưng git chỉ theo dõi 52, `dev/server/tables/shared/` bị `.gitignore`. Bản checkout sạch có số đo khác, và test đọc bảng thật bỏ ca lặng lẽ (xanh giả) | [đọc mã] |
| D6 | thấp | Chưa đăng ký ba bảng `social_limits`, `rank_boards`, `chat_blocked_words` và sáu bảng scenedata vào `TOOLS/server/table_names.tsv`; `build_data.py` mới gọi 4 trong 5 công cụ cảnh | [đọc mã] |

### E. Nền tảng

| Mã | Mức | Vấn đề | Bằng chứng |
|---|---|---|---|
| E1 | chặn (cho iOS) | iOS chưa từng qua trình dịch; 11 điểm cần máy Apple (NGHI-NGO 49). Điểm Vulkan 1.3 có thể đã đổi nghĩa sau `e10bdbdc` | [tài liệu] |
| E2 | vừa | Prefix cài APK: `android-arm64` là `release`, `android-x86_64` không đặt nên kế thừa `dev`, dễ lẫn APK | [đọc mã] |
| E3 | vừa | **ĐÃ SỬA** `a0b31fa3` (2026-10-17): D3D12 và D3D11 khởi tạo, vẽ và chụp Đại Lý với lớp kiểm tra 0 lỗi. Gốc của các lỗi thấy được: stride đỉnh chốt lúc gắn buffer (cột nhiễu ở Đại Lý), fxc đọc ma trận instanced theo hàng, chép mip BC nhỏ. Còn mở: D3D11 có MSAA lệch khoảng 200 điểm ảnh giữa hai lần chạy (NGHI-NGO 25) | [tự kiểm] |
| E4 | vừa | `msvc-release` và `android` dùng chung thư mục vcpkg installed: cấu hình xen kẽ hai nền thì gói của bên kia bị gỡ (`BAY-DA-BIET`) | [tài liệu] |

## 5. Hướng đi

**Đợt hoàn thiện tính năng (giao 2026-10-18).** Ba phiên: làn K (client, `thienlong-14`) và làn M
(máy chủ, `thienlong-6a`) làm gói G0–G9; làn N (nội dung: nhiệm vụ, phụ bản, boss, sự kiện,
`thienlong-1e`) làm gói N0–N6. Điều phối `thienlong-f7`. Hồ sơ, quyền sở hữu
tệp, quy trình kiểm chéo và trạng thái từng gói ở `docs/giao-viec/HOAN-THIEN/HO-SO.md`.

Chuẩn hoá đi từng bước. Mỗi bước có tiêu chí "xong khi"; chưa qua rà soát của chủ dự án thì không
sang bước kế tiếp.

**B0 — Rà soát (xong lượt này).** Hồ sơ này; dọn ảnh tự chế; lưu trữ tài liệu lỗi thời (mục 8).

**B1 — Cây đo được (làm một nửa).** Đã sửa hai ca lỗi ở HEAD (`protocol_catalog_fresh`, `real_gate`);
còn chờ phiên đang giữ việc dở commit hoặc cất nó để xử lý ba ca còn lại (`layers`, `real_zone`,
`writer_clip`). Việc của tôi chưa commit: `messages.hpp`, `protocol_samples.hpp`,
`Test/Config/config_tests.cpp`, `CLAUDE.md`, `AGENTS.md`, `README.md`, `docs/DU-AN.md`. Xong khi:
`ctest` 180/180 trên cây sạch, ghi số vào mục 2, `git worktree prune`, đặt thẻ baseline.

**B2 — Tài liệu đợt hai.** Gộp rồi bỏ: `NGUON-FORGE2`, `NGUON-TLBB`, `I18N-BAO-CAO-2026-10-13`,
`SERVER-BAO-MAT`, `SERVER-DI-CHUYEN`, `SERVER-DU-LIEU`, `SERVER-MISSION`, `SERVER-SCENEDATA`,
`SERVER-TEP-CAU-HINH` (kèm sửa hai test Python `test_glossary.py`, `test_term_morphemes.py` đang
đọc nó), phần nhật ký của `VA-CHAM-2026`, `UI-DIEN-THOAI` (mục 1, 2, 6), `android/HUONG-DAN.txt`,
`apple/HUONG-DAN.txt`. Mỗi tài liệu bỏ kéo theo sửa các chỗ trỏ tới nó; danh sách chỗ trỏ đã có
trong báo cáo thẩm định và tìm lại được bằng `git grep` tên tệp. Chuyển "Quyết định đã chốt" từ
`AGENTS.md` mục 0 sang tài liệu này rồi cắt `AGENTS.md` về quy tắc làm việc. Lưu trữ `TIEN-DO.md`
và rút sổ `NGHI-NGO.md` về mục còn mở. Sửa tham chiếu mồ côi (A7). Xong khi: `git grep` tên mọi
tài liệu đã bỏ ra 0 trong mã, mọi tham chiếu tài liệu trong comment trỏ tới tệp tồn tại.

**B3 — Cổng hình thức thật.** Sau khi chủ dự án chọn D-1: gắn `shape.js` và `clang-format` vào
CMake thành target chạy trước biên dịch, ghi số vi phạm hiện tại làm trần "không tăng", thay dần
về 0 theo module. Xong khi: cổng đỏ khi cố ý thêm một vi phạm (thử rồi gỡ).

**B4 — Máy chủ và đường mạng.** Theo thứ tự B1, B2, B3–B4, B6–B9, B15–B16, B18–B19; mỗi mục sửa
kèm test hồi quy đỏ rồi xanh. Xong khi: không còn mức cao ở nhóm B.

**B5 — Đa nền.** Dựng và chạy máy chủ trên Linux (WSL có sẵn, chưa có distro), TSan, ASan/UBSan
ba preset. iOS chờ máy Apple. Xong khi: `ctest` xanh trên Linux; bảng sanitizer có số.

**B6 — Đường đầu cuối.** `auto_login` rồi chạy client thật với cụm v6, đóng C1, C2, C5; sau đó mới
tối ưu C3, C4.

Sản phẩm (tiến độ chức năng) đi theo `docs/KE-HOACH-SERVER.md` mục 10 cho máy chủ, và danh sách C
cho client; hai đường này không chặn B1–B3.

### Sáu quyết định đã chốt (2026-10-16)

Chủ dự án uỷ quyền ("bạn quyết định đi") sau khi nêu mục tiêu cuối ở mục 1. Căn cứ chung: độ trung
thực với bản gốc, tái hiện được và an toàn đứng trước hình thức.

- **D-1 Hình thức mã: ba lớp, không dọn cả cây một lần.**
  (1) B3 gắn cổng "không tăng" vào CMake. (2) Sau B1, chuẩn `clang-format` từng module; mỗi module
  một commit chỉ chứa thay đổi máy móc, build và ctest xanh trước và sau, ghi mã commit vào
  `.git-blame-ignore-revs` để `blame` không mất. (3) Lỗi cấu trúc của `shape.js` (lồng, bậc thang,
  lồng lời gọi) chỉ sửa khi chạm tới tệp, không đổi hành vi ở mã port. Lý do: 816 tệp trộn với 75
  tệp việc dở của phiên khác thì diff không còn đọc được; còn đổi cấu trúc ở mã port thì mất khả
  năng đối chiếu với bản gốc (quy tắc fork/port).
- **D-2 `auto_register`: dev giữ `true`, release đặt `false`.** Dev là máy nghiên cứu, bot cần tự
  đăng ký. Đã sửa `release/server/config/auth.toml` (ngoài git, chép tay, không công cụ nào ghi
  đè); `lint_config.py` vẫn sạch 26 tệp. Còn lại ở bản release: gate nghe `0.0.0.0` (chủ ý).
- **D-3 `docs/refs/` bỏ.** Bản trong repo là bản cũ (sửa 10-08 tới 10-11), khác 20/21 tệp so với
  bản chuẩn ở `~/.claude/cpp23/refs` mà chủ dự án viết lại 10-16 15:01 (ngắn hơn 1,4 tới 2,2 lần).
  Hai bản luật lệch nhau là nguồn mâu thuẫn. Đã lưu trữ.
- **D-4 `assets/i18n/vi/` giữ tại chỗ.** Là nguồn của `-DGAME_LANGUAGE=vi`, gồm tấm nút do chủ dự
  án vẽ; bản `vi` chỉ hoãn, chưa bỏ.
- **D-5 Không dựng lại đặc tả nhiệm vụ đã mất.** Sửa 15 comment trỏ vào `NHIEM-VU-VO-CONG-2026.md`
  ở B2 để trỏ vào mã, bảng `mission_*` và `lua_extract`; khi cần đặc tả thì sinh từ dữ liệu đó. Lý
  do: tệp mất 96% dòng, dựng lại từ trí nhớ là bịa; nguồn thật là Config và Lua của client 2026.
- **D-6 Ngoại lệ khung ENGINEHP ghi vào `CLAUDE.md` mục 0.3**, kèm sửa câu sai ở V.5 về
  `check_style.js`. Đã làm. Khung ENGINEHP giữ nguyên.

Việc còn phải phối hợp (không quyết hộ được): B1 cần phiên đang giữ việc dở commit hoặc cất nó.
Tôi không commit hộ vì không phải thay đổi của tôi.

## 6. Quyết định đã chốt còn hiệu lực

Danh sách đầy đủ vẫn ở `AGENTS.md` mục 0, phần "Quyết định đã chốt" (dòng 148–300), cho tới B2.
Quyết định mới của phiên này:

- 2026-10-16: sáu quyết định D-1…D-6 ở mục 5, do chủ dự án uỷ quyền cho phiên chuẩn hoá.
- 2026-10-16: ảnh và đồ tự chế không coi là thứ dùng được, gom hết về một nơi ngoài cây dự án:
  `D:\THIENLONG-luu-tru\tu-che\`.
- 2026-10-16: một tài liệu dự án duy nhất là tài liệu này; tài liệu cũ không hợp thì bỏ để tránh
  nhiễu.

## 7. Bẫy chung (đã đo)

Bẫy riêng từng vùng ở `docs/BAY-DA-BIET.md` (giữ cho tới B2); đây là bẫy việc nào cũng có thể dính.

- `cl /std:c++23` không tồn tại, cho `D9002` và exit 0, lặng lẽ tụt về C++14; dùng
  `/std:c++23preview` kèm `/Zc:__cplusplus`. `cl /fsanitize=undefined` cũng bị nuốt.
- GCC MinGW giả lập TLS: `thread_local` có destructor làm hỏng heap; dùng `core::thread_slot`.
- Test dựng MSVC thoát `0xC0000409` mà không in gì thường là `std::abort` cộng stdout bị đệm.
- MSVC 14.51 `/O2` dịch sai `x == -1 ? 0 : 1 << x`; viết điều kiện `x < 0`.
- `<windows.h>` định nghĩa `far` và `near` thành macro rỗng.
- `if constexpr` không có `else` sinh C4702, chỉ lộ ở `msvc-debug`.
- `git apply --unidiff-zero` đặt hunk lệch mà không báo khi cây còn sửa của phiên khác; dựng HEAD
  trong worktree sạch sau khi commit.
- Nhánh tên `server` trùng thư mục `SERVER` (hệ tệp không phân biệt hoa thường): thêm `--` sau tên
  nhánh. Worktree sạch thiếu thư mục bị ignore thì test đọc bảng thật bỏ ca lặng lẽ và xanh giả.
- Bản cài không tự theo mã: thêm khoá cấu hình mới làm exe cũ từ chối cả tệp; exe client phải đi
  cùng `shaders/` của cùng bản dựng; đổi `compiler.cpp` hay `reconcile.cpp` thì tăng `kPipeline`.
- PowerVR: `discard` tắt HSR; xử lý `SUBOPTIMAL` đúng một lần; kiểm định dạng swapchain; `round()`
  đắt. Đo nhịp bằng lúc ảnh lên màn (`wait_shown`) và xem p95/max, không chỉ trung vị.
- `--shot` không kèm `--frames` thì không thoát; so ảnh bằng `--bare`.
- Địa chỉ `0x14…` trong mã và tài liệu có thể thuộc bản `Game.exe` khác (NGHI-NGO 53); tra theo tên
  hàm script, chuỗi hoặc lớp RTTI.
- Không chạy công cụ bấm chuột hay test vòng kéo khi có người dùng máy (`window_modal_tests`,
  `click_shot.py`).
- `~/.claude/bin/check_style.js` là stub: exit 0 không có nghĩa là mã sạch.

## 8. Chỉ mục tài liệu còn giữ

Đặc tả mà mã hoặc công cụ dựa vào, không dựng lại được từ mã. Cột cuối là việc cần làm ở B2.

| Tài liệu | Dùng cho | Cần sửa |
|---|---|---|
| `docs/PROTOCOL-TIN.md` | Danh mục tin. **Tệp sinh**, ctest `protocol_catalog_fresh` đọc nó. Không sửa tay | Không |
| `docs/CAMERA-2026.md` | Camera và chuột từ mã máy 2026 | Đường dẫn `SRC/…`; bỏ mục "chưa port rung kỹ năng" (đã có) |
| `docs/DUONG-DI-2026.md` | Định dạng `.path`, thuật toán, luật đi | Lưới tự vẽ 66 tam giác; số vàng phải sinh lại |
| `docs/VA-CHAM-2026.md` | Định dạng `.WCollision`, thứ tự phép f32 | Bỏ nhật ký giao việc; `load` không `noexcept` |
| `docs/TAO-NHAN-VAT-2026.md` | Màn tạo nhân vật, số vàng | `body.hpp` vẫn có `kBodyFovDegrees = 20`; địa chỉ lệch |
| `docs/GIAO-DIEN-2026.md` | Widget CEGUI 2026 (203 KB, 28 địa chỉ chỉ có ở đây) | 15 đường dẫn `SRC/*`; bỏ các mục "chưa có Money/kPlain" đã sai |
| `docs/DINH-DANG-TLA.md` | Định dạng âm thanh `.tla` | Một đường dẫn |
| `docs/SERVER-BILLING.md` | Billing: Op, mã lỗi, webhook | Khung ipc 80 KiB, `secure::file_private` |
| `docs/SERVER-COMBAT.md`, `SERVER-ITEM.md`, `SERVER-SOCIAL.md` | Đặc tả máy chủ, có "số tự đặt" chờ duyệt. `SOCIAL` còn là hợp đồng tích hợp world chưa ai thực hiện (không module nào gọi `social::`) | Khớp mã. Giữ vì có thứ không dựng lại được: bản đồ cột bảng của `COMBAT` (§6; `dev/server/tables/shared/` bị `.gitignore`), hợp đồng nối `world` của `SOCIAL` (§3), nguyên tắc kế hoạch rồi áp dụng của `ITEM` (§2). Ở B2 chỉ rút bảng độ phủ từng phái, danh sách test, API trùng header. Hai lượt thẩm định bất đồng: một bên đề nghị giữ, một bên đề nghị gộp rồi xoá |
| `docs/KE-HOACH-SERVER.md` | Kế hoạch máy chủ, mục 10 là mốc | Phần đầu (trạng thái 10-09) và đường dẫn `SERVER/…` |
| `docs/BAY-DA-BIET.md`, `docs/TIEN-DO.md`, `docs/NGHI-NGO.md` | Bẫy theo vùng; nhật ký; sổ nghi ngờ (`compare_client.py` đọc `NGHI-NGO`) | Gộp/lưu trữ ở B2 sau khi phiên khác commit |
| `docs/UI-DIEN-THOAI.md` | Quyết định giao diện điện thoại; số ở `TOOLS/content/phone_wireframe.py` | Đang có sửa chưa commit |
| `docs/TAILIEU/` | Trích xuất `Game.exe` 2026; công cụ `TOOLS/port/rea/*` đọc và ghi ở đây | Không |
| `docs/giao-viec/LUA-GEN`, `UI-FULL`, `UI-PORT`, `KD-DOT-1`, `P2-DOT-1`, `GAMEPLAY-DOT-1` | Thiết kế Lua tầng B/C; ý tối ưu hoãn; `boot_check.py` kiểm đầu cuối trình giám sát | Dời `boot_check.py` sang `TOOLS/server/` |
| `docs/AUDIT/` (5 tệp) | Bằng chứng mã còn trỏ tới: `G-XJL7457.md`, `evidence/xjl7457_config_coverage.md`, `evidence/jump_oracle.log`, `evidence/jump_re.log`, `TIEN-DO-DU-LIEU-HINH.md` | Không |
| `docs/NHIEM-VU-NGUON.md` | Sổ nguồn nhiệm vụ (bảng client 2026, Lua 14 phái, id 1400–1424). Không phải đặc tả cột và không dựng lại `NHIEM-VU-VO-CONG-2026.md` | Đếm lại khi xuất bảng lại |
| `docs/refs/` | Bộ quy cách (D-3) | Chờ quyết định |
| `docs/ui-dien-thoai/` | Ảnh phác điện thoại | Đã chuyển sang thư mục tự chế |
| `AGENTS.md`, `CLAUDE.md`, `README.md` | Quy tắc làm việc, hiến pháp mã, giới thiệu | `AGENTS.md` mục 0 cắt ở B2; `CLAUDE.md` V.5 sửa lại cho khớp (A2) |
| `TOOLS/cfgtool/HUONG-DAN.md`, `dev/server/README.md`, `android/HUONG-DAN.txt`, `apple/HUONG-DAN.txt` | Hướng dẫn vận hành | `Info.plist` thành `Info.plist.in`; thêm lệnh `doc` |

Đã chuyển ra ngoài cây (mọi tệp vẫn nằm trong lịch sử git và trong thư mục lưu trữ):

- `D:\THIENLONG-luu-tru\tu-che\` — ảnh và đồ tự chế (xem `README.txt` ở đó).
- `D:\THIENLONG-luu-tru\tai-lieu-cu\` — tài liệu lỗi thời, giữ nguyên đường dẫn tương đối. Chứa
  `lich-su-git-2026-10-05.bundle` (25 commit đầu, commit `28d4c74` không còn trong kho hiện tại)
  và `DANH-SACH-MAT.tsv`.
