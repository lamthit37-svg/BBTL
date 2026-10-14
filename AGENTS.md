# THIENLONG — quy định riêng của dự án cho AI coding agent

## 0. Thông tin dự án — riêng dự án này

- Tên: THIENLONG
- Mục tiêu một câu: client tự viết nạp và vẽ lại tài nguyên của client Thiên Long Bát Bộ (XTLBB-JD
  3.71) đúng toạ độ gốc, chạy offline trước, trên PC và mobile.
- Trạng thái (đối chiếu với mã ngày 2026-10-14, `main` ở `1ff6703`; số đo tốc độ là của các ngày
  trước, ở `docs/TIEN-DO.md`; chỉ mục tài liệu ở `docs/README.md`):
  - Khôi phục (2026-10-09), đọc như lịch sử, không như hiện trạng: `F:\tl 2026` bị xoá nhầm ngày 2026-10-09; cây
    này ghép lại từ nhật ký của các công cụ và nằm ở `D:\THIENLONG`. Lúc mới ghép chưa có `.git`, chưa dựng và
    chưa chạy test lần nào sau khôi phục (56 tệp `SRC` và 31 tệp test là bản cũ hơn bản cuối, 12
    tệp `CMakeLists.txt` nêu còn thiếu; client gốc,
    `_raw`, `_glb`, `dev/client/assets`, `SERVER/tables`, `SERVER/scenes`, `Test/golden`, ảnh
    `assets/i18n` và `third_party/libsodium` phải cài, sinh hoặc tải lại). Nay cây đã có `.git`,
    đã dựng được (`build/msvc-release/` có đủ exe và lib) và `ctest` đã chạy; hồ sơ vụ mất
    (danh sách từng tệp, lịch sử git 25 commit đầu) ở `docs/KHOI-PHUC-2026-10-09/`. Các dòng dưới tả mã hiện tại.
  - Hình: vẽ được map (địa hình, vật thể tĩnh, hạt và hiệu ứng cộng sáng của bản 2026) và người
    chơi có xương trên PC và máy tính bảng, 60 fps ở map nhỏ. Nước và vòm trời đã có mã dựng và vẽ
    (`ensure_water`, `ensure_sky` ở `client/display/graphic/scene.cpp`, gọi từ `frame.cpp`); chưa
    ai nhìn ảnh để đối chiếu với bản 2026. Chưa có NPC, quái, vật phẩm hay người chơi khác. Vũ khí cầm tay, đòn đánh,
    tuyệt chiêu và hiệu ứng đồ (đá quý gắn vũ khí) đã chạy bằng công cụ thử `--weapon`, `--skill`, `--gem`, `--auto-strike`
    (hành trang, skill, đá quý chưa nối máy chủ; phần chưa làm ở `docs/NGHI-NGO.md` mục 51).
    Nhảy đã có mã: `src/client/figure/motion/jump.cpp` (`can_jump`/`start_jump`, port `Game.exe`
    64-bit), clip nhảy `跑跳a`/`跑跳b` đã vào `anim_sets.tsv`, `Gait::jump`/`land` theo
    `CObject_Character::Jump` (`docs/TIEN-DO.md` mục 2026-10-14); chưa nhìn tận mắt khi chạy.
  - Backend: `gpu` có bốn backend (Vulkan, D3D12, D3D11, OpenGL/GLES). Windows dựng cả bốn, client
    tự chọn Vulkan phần cứng trước rồi tới các backend sau; Android dựng Vulkan và GLES. Vulkan
    và GLES đã vẽ lên cửa sổ; D3D12 và D3D11 chưa hiển thị được (`docs/NGHI-NGO.md` mục 25).
  - Màn chơi: camera và chuột port từ mã máy của client 2026 (`docs/CAMERA-2026.md`); đi bằng nhấp
    chuột, phím, cảm ứng và cần gạt, bị vật cản chặn và tìm đường vòng theo lưới đi `.path` của
    client 2026 (`docs/DUONG-DI-2026.md`); chân nhân vật được nâng lên mặt công trình `.WCollision`
    (mặt cầu, bậc thang: `surface_y` ở `display/graphic/play.cpp`, `building_height_tests` xanh; chưa
    nhìn thử tay). Lưới đi `.path` có ở 4 cảnh (`dali_new_320`, `erengu_DL`, `huoyangu`,
    `luoyang_new`), `.WCollision` có ở khoảng 70 cảnh trong `dev/client/assets/Scene`;
    `luoyang_new` và `erengu_DL` đủ bộ Terrain + Scene + path + WCollision, `tl3chuangjian`
    thiếu cả hai; `collect_map.py` đã có `collect_walk` gom hai tệp ấy (trước 2026-10-13 bản cũ
    không gom, chỉ hai map Đại Lý và Lạc Dương gom tay mới có).
  - Giao diện: HUD nạp 36 layout của client 2026. Lúc nạp một cảnh của màn chơi, bảng chuyển cảnh
    `SceneTrans` của bản gốc hiện tên cảnh sẽ tới và phần trăm đã nạp (`ui/panel/scene_trans`).
    Khung nhân vật, minimap, thanh kinh nghiệm và
    bảng nhân vật có số, số lấy từ nhân vật mẫu viết cứng `hero::newcomer()`. Hành trang, nhiệm
    vụ, thương thành, hệ thống và bốn trang cài đặt, sách kỹ năng, trân thú, hảo hữu, tổ đội mới là
    khung. Sổ nhiệm vụ (`ui/panel/quest_log`, module `quest`) đã port, có test và đã nối
    vào HUD (`face/ui/hud.cpp` gọi `press_quest_book`/`paint_quest_book`); module `skill`
    chưa được `ui` hay `client` dùng (`docs/NGHI-NGO.md` mục 43).
  - Đăng nhập (`--login`, chỉ bản Windows; Android và iOS vào thẳng cảnh của `Config/startup.id`):
    cảnh nền 3D `erengu_DL` với camera cố định của bản gốc, gõ tài khoản và mật khẩu (không kiểm,
    không lưu), nút "Vào Game" mở chọn nhân vật trên cảnh `tl3chuangjian` (tối đa 3; nhân vật mới
    cấp 1, môn Vô Phái) rồi vào màn chơi bằng nhân vật đó. Bảng tạo là bản dịch của `CreateRole.lua`
    đối chiếu số vàng: 15 ảnh chân dung mỗi giới, kiểu tóc, kiểu mặt, ba bộ đồ tân thủ đúng phân bố
    bản 2026. Người mẫu đứng trong cảnh ở chỗ và tỉ lệ của bản gốc, camera là bản port của
    `CCamera_CharSel` (lướt giữa mắt nam và mắt nữ, phóng bằng nút và con lăn, chạy spline giữa ba ô
    của bảng chọn); xem trước môn phái hiện người mẫu riêng của môn múa bài `演武`
    (`docs/TAO-NHAN-VAT-2026.md` mục 8). Ô mô tả môn phái là khung cuộn chữ tự trôi và lăn chuột
    được; nút, tiêu đề, nhãn và câu đối của màn tạo là ảnh chữ Việt. Còn thiếu ở màn này (chủ dự
    án thử tay ngày 2026-10-09): hiệu ứng tuyệt chiêu và hào quang vũ khí của người mẫu môn phái;
    bảng chọn mới vẽ một nhân vật. Ảnh có chữ Hán của các bảng khác chưa thay (`docs/TIEN-DO.md`).
    Sổ nhân vật là tệp cục bộ
    `dev/client/assets/Save/roles.tsv`. Các nút web mở trang "Coming soon", bàn phím
    ảo gõ vào ô đang ngắm. Cảnh nền có lửa và quầng đèn từ hiệu ứng bản 2026, còn thiếu nước,
    sương, nến và quạ.
  - Chữ và ảnh dựng cùng client từ `assets/i18n`. Từ 2026-10-13 bản dựng mặc định là `zh`: chỉ tiếng
    Trung gốc của client 2026, không trộn Việt hay Anh. `vi` và `en` giữ nguyên làm nguồn, dựng lại
    bằng `-DGAME_LANGUAGE=vi|en` khi chủ dự án cho phép. Chữ người chơi thấy là khoá `#{...}` hoặc tên
    gốc của cảnh; chữ nằm trong `assets/i18n/<mã>.tsv`, tệp riêng của ngôn ngữ (danh sách máy chủ
    đăng nhập, trang "Coming soon") ở `assets/i18n/<mã>/` và khai bằng dòng `file/` của tệp nguồn.
  - Client chưa mở socket nào và chưa có module nối máy chủ.
  - `WEB/` là trang giới thiệu tĩnh (Vite, React, three.js), không có backend, không nối client
    hay máy chủ, không nằm trong CMake.
  - Máy chủ: bảy exe khởi động và dừng theo thứ tự dưới trình giám sát, gate nghe hai cổng và giữ
    phiên đã bắt tay (`gate.toml` `[listen]` game 7000/auth 7001; sau `SessionStart` gửi `UiConfig`
    rồi `Position`). Đã có logic tài khoản/nhân vật dùng chung (`src/server/account/`: sổ, luật,
    vé, RPC loopback, bản SQL) và `serve_auth`/`serve_game` qua ipc; `store`/`auth`/`billing`/
    `world`/`zone` mới in `ready` rồi chờ. Chưa có migration nào của database, client chưa nối
    máy chủ — P2 còn dở, mốc và số đo ở `docs/KE-HOACH-SERVER.md` mục 10.
- Nền tảng đích: Windows x64 (MSVC 19.51 là bản phát hành; GCC 16 MinGW và Clang 23 để kiểm chéo;
  GCC MinGW không dựng `fs`, `shader`, `gpu`, `resource`, `render`, module `ui` và phần hiển thị
  có GPU của client, còn `gui` và `ui/panel` thì có, nên `gcc-debug` chỉ kiểm chéo phần không có
  GPU), Android arm64 (NDK 30, API 29; preset `android-x86_64` có sẵn nhưng trên máy chưa có cây
  dựng hay gói vcpkg nào cho nó, và nó đang kế thừa triplet `arm64-android`),
  iOS arm64 (mã và preset có sẵn, CHƯA build: máy phát triển không có macOS; ngày 2026-10-13 đã dọn
  nguồn theo đọc mã: bật Objective-C++ và ARC, miniaudio dịch Objective-C++, `VK_EXT_metal_surface`,
  preset kế thừa vcpkg `arm64-ios`, `game_jobs` và `game_capture` tạo cả cho iOS; chỗ còn nghi và
  cách dựng trên máy Apple ở `docs/NGHI-NGO.md` mục 49 và `apple/HUONG-DAN.txt`).
  Máy chủ: Windows x64 và Linux x64 (chủ dự án nêu ngày 2026-10-08); bản POSIX của mã máy chủ mới
  qua kiểm cú pháp bằng trình dịch NDK, CHƯA dựng trên Linux: máy phát triển có WSL nhưng chưa có
  distro. Phép kiểm NDK không thay được Linux thật: `SRC/core/system_posix.cpp` include
  `<sys/system_properties.h>` cho mọi nền không phải Apple, header ấy chỉ Android có, mà mọi module
  máy chủ đều link `game_core` (`docs/NGHI-NGO.md` mục 45).
- Module hiện có: core, io, xml, scene, window, math, fs, jobs, capture, shader,
  shadertool, gpu, resource, render, ogre, fx, anim, motion, nav, collision, table, look, avatar,
  control, audio,
  audiotool, seal, sealtool, gui, hero, quest (nhiệm vụ nhận được, sổ 20 ô, theo dõi), skill (bảng
  và sách kỹ năng, action), ui (panel), client (stage, map, world, display, viewer);
  dùng chung ở `src/shared/`: protocol (tầng byte, khung, kênh, danh mục tin sinh từ bảng: 22 tin
  version 2 của bốn nhóm phiên, nhân vật, di chuyển, xác thực), secure (bắt tay
  và bản ghi mã hoá nằm dưới khung, gọi libsodium; `docs/SERVER-BAO-MAT.md`), table (TSV),
  link (nối net + protocol + secure); mạng ở `engine/net` (socket TCP không chặn, tập chờ);
  của máy chủ: content (kiểm bảng TSV và tham chiếu chéo), linttool (exe
  `thienlong_lint`), config (TOML thành struct đã kiểm miền), process (chạy tiến trình con, yêu cầu
  dừng), supervise (máy trạng thái của trình giám sát), service (điểm vào chung của bảy exe:
  `supervisor`, `stored`, `authd`, `billingd`, `worldd`, `zoned`, `gated`; giao kèo ở mục 3.1 của
  `docs/KE-HOACH-SERVER.md`), gate (bảng kết nối
  và vòng tick 60 Hz của `thienlong_gate`: exe duy nhất đã mở cổng, sau bắt tay mới xử lý `Hello`,
  `Ping`, `Logout`; năm exe `store`, `auth`, `billing`, `world`, `zone` mới in `ready` rồi chờ
  dừng) — bảng tầng ở `cmake/GameLayers.cmake`, nguồn sự thật về ai include ai.
  Hạ tầng (core, window, math, fs, jobs, capture, shader, gpu, resource, render) chép từ Forge2;
  logic game (ogre, anim, motion, table, look, avatar, control gồm cử chỉ chạm, cần gạt) port
  thẳng từ TLBB Dev (`docs/NGUON-TLBB.md`); camera và chuột của `control` port từ mã máy của
  client 2026 (`docs/CAMERA-2026.md`); `nav` (lưới đi, tìm đường, luật đi) port từ mã máy của
  `PathLib.dll` và `Game.exe` 2026 (`docs/DUONG-DI-2026.md`).
- Ngân sách (ghi bằng số, hoặc "chưa có"): nạp đầu của cảnh Đại Lý (resid 2) trên PC, tính từ lúc chạy lệnh tới khung đầu
  đã có đủ cảnh lẫn HUD: trung vị ≤ 450 ms (đo 2026-10-13: 387 ms, 15 lượt, i5-14600KF, RTX 5060, Vulkan; G:\TLBB cùng máy:
  khung ổn định trung vị 1239 ms). Đo lại bằng `TOOLS/run/bench_load.py`, số liệu và điều kiện hai bên ở
  `TAILIEU/TOC-DO-NAP-SO-VOI-TLBB.md`. Các ngân sách khác (khung hình, bộ nhớ, dung lượng): chưa có.
- Quyết định đã chốt (mỗi dòng: quyết định — lý do):
  - Mã nguồn client là C++23, C11 chỉ khi một thư viện C buộc phải thế; công cụ xử lý dữ liệu ở
    `TOOLS/` viết bằng Python — chủ dự án chốt ngày 2026-10-05.
  - Mã lấy từ Forge2 chép từng tệp một, chỉ tệp đang cần, build và chạy xong mới chép tiếp — chủ
    dự án chốt ngày 2026-10-05. Forge2 nay nằm ở `D:\TÀI LIỆU LÀM VIỆC\code\engine\Forge2`, vẫn commit
    `d7fcd76` (đo 2026-10-08; thư mục `D:\The-Forge\Forge2` lúc chép không còn).
  - Giữ nguyên đơn vị và hệ toạ độ của OGRE (centimet, tay phải, Y lên); số trong tệp gốc đọc theo
    đúng cách client gốc đọc — để vật thể nằm đúng toạ độ gốc.
  - Chưa nấu hay nén tài nguyên: client nạp thẳng GLB và PNG đã kiểm khớp tệp gốc; nén theo nền tảng
    quyết sau bằng số đo trên map lớn.
  - Trước khi chép một phần từ Forge2, so nó với bản tương ứng ở các engine tham chiếu còn trên đĩa
    (Platium, Titan, No1, orio, The Forge, Wicked); bên nào tốt hơn rõ rệt thì lấy bên đó, ngang nhau
    thì giữ Forge2; kết quả so ghi ở `docs/NGUON-FORGE2.md` — chủ dự án chỉ thị ngày 2026-10-05. Đo
    2026-10-08: Platium, Titan, No1 ở `D:\TÀI LIỆU LÀM VIỆC\code\engine`, The Forge và Wicked ở
    `D:\TÀI LIỆU LÀM VIỆC\code\reference\engine`; không còn thấy orio trên ổ D.
  - Logic game (xương và animation, ngoại hình, điều khiển, camera, NPC) port thẳng từ
    `G:\TLBB\Dev` kèm test của họ; Forge2 chỉ cho hạ tầng — chủ dự án chốt ngày 2026-10-06 ("mã anim
    không giống thì port trực tiếp để sửa được"). Dữ liệu đã nấu và bảng của TLBB KHÔNG dùng: nó nấu từ
    một bản client khác; bảng ngoại hình xuất từ Config của chính client này.
  - Mã chép giữ kiểu lỗi của Forge2 (`core::Result`, `core::Status`, `core::Error`); chưa viết lại
    sang `std::expected` trần — chủ dự án chốt ngày 2026-10-05 cho bước cửa sổ và Vulkan.
  - Máy chủ: không Lua; cấu hình là TOML, bảng theo dòng là TSV; database là PostgreSQL; có tiến
    trình billing riêng; tên tệp cấu hình và bảng viết bằng tiếng Anh, không pinyin; không có chế độ
    offline, máy phát triển là máy chủ thử online; bảng chỉ máy chủ giữ vào git; làm nội dung bản
    0859602 trước rồi mở lên 2026. Kế hoạch ở `docs/KE-HOACH-SERVER.md` — chủ dự án chốt ngày
    2026-10-06.
  - Tệp TOML của `dev/server/config` bố cục theo mẫu chủ dự án đưa: đầu tệp là khung tiêu đề in hoa
    kẹp giữa hai dòng `#====`, mỗi nhóm cài đặt một khung tiêu đề, các cài đặt nằm sát nhau, mỗi
    cài đặt có chú thích tiếng Việt ngang hàng (dài quá thì ngay dòng trên), không sót; dấu `=` và
    dấu `#` căn thẳng cột trong nhóm. Không căn tay: `python TOOLS/server/lint_config.py --fix` căn,
    cùng lệnh không có `--fix` thì kiểm; công cụ sinh TOML dùng `config_style.render`. Hai luật
    "không comment cuối dòng" và "không căn thẳng cột" nới riêng cho các tệp này — chủ dự án
    chốt ngày 2026-10-06.
  - Bản địa hoá dựng cùng client từ một tệp nguồn cho mỗi ngôn ngữ; ngôn ngữ chọn lúc dựng, bản
    triển khai chỉ mang chữ và ảnh của ngôn ngữ đó (không giữ hai bộ ảnh), client không chọn ngôn
    ngữ lúc chạy — chủ dự án chốt ngày 2026-10-08. Chủ dự án chốt ngày 2026-10-13 ("chỉ tiếng Trung
    bản gốc, không lẫn chữ Việt chữ Trung; ba ngôn ngữ để sau"): mặc định `zh`; chữ cứng trong mã mà
    người chơi thấy cũng là chữ Trung gốc (không còn câu tiếng Việt nào trong `src/client/face`).
  - Một client cho PC, APK và iOS. Tách vỏ và gói cài, không tách mã game và không đưa game
    sang Java. APK và iOS là cùng phía mobile. `world.toml` `[platform] pc_meets_mobile` mặc định
    tắt: PC chỉ gặp mobile khi cờ bật. Engine không biết luật này — chủ dự án chốt ngày 2026-10-12.
  - Layout điện thoại là `Interface/phone/`, Android và iOS dùng chung; thiếu tệp thì layout PC.
    Texture PC là DDS. Bản điện thoại là `mobile/astc/` rồi `mobile/etc2/`, cùng đường tương đối,
    định dạng TLTX. GPU có ASTC thì chọn ASTC, không thì ETC2 — chủ dự án chốt ngày 2026-10-12.
  - Dạng khung chân dung của HUD (tròn hoặc vuông) chọn lúc dựng client trong `src/client/client.build.toml`
    (khoá `avatar_frame = "square"` hoặc `"round"`; CMake đọc rồi gắn thẳng vào exe, client không đọc tệp lúc chạy)
    (mặc định `square`; `round` là nền tròn `CommonFrame8` và đầu 3D có mặt nạ `HeadRoundRegion`). `square` là chế độ
    classic của client 2026, port đúng nhánh `SystemSetup:IsClassic() == 1` của `PlayerFrame_UpdateShow2DHead`
    (`PlayerFrame.lua` 2026 giải bằng `TOOLS/content/lua_plain.py`, dòng 957-995): nền vuông
    `CommonFrame18 image:PlayerFrame`, ảnh chân dung 2D ở `Head_2D`, đầu 3D bị giấu, các ô trên nền dời theo
    (`kClassicFrame` ở `ui/panel/player_frame.cpp`). Mọi giá trị lấy từ script 2026, không tự ghép ảnh — chủ
    dự án chốt ngày 2026-10-14 ("mình có client bản 2026 mà", "cấm ghép linh tinh"). Hiện chỉ khung `PlayerFrame`
    (Target, Party, Pet chưa có trên HUD). Mặc định là `square` — chủ dự án chốt ngày 2026-10-14 ("để mặc định avt
    vuông đi"). Đổi giá trị: sửa tệp rồi dựng lại `thienlong_client` (CMake tự cấu hình lại) — chủ dự án
    chốt ngày 2026-10-14 ("đưa nó thành file toml đặt ở client"; "build gắn thẳng vào dll hoặc exe").
  - Nhà phát hành không có source vẫn đổi được giao diện, người chơi thì không: server gửi cấu hình giao diện cho
    client — chủ dự án chốt ngày 2026-10-14 ("NẾU CHỈ LÀ NHÀ PHÁT HÀNH KO CÓ SOURCE. THAY ĐỔI LÀM SAO ĐƯỢC GIAO
    DIỆN"; "LÀM CÁI NÀY ĐI"; "TẠO 1 FILE TOML RIÊNG ĐẶT TÊN client.toml"). Đổi ý so với "phần này ở giao diện
    không nên đẩy lên server" cùng ngày: lý do là nhà phát hành không có source nên không dựng lại được client, còn
    tệp ini cạnh exe thì người chơi sửa được. `dev/server/config/client.toml` (`[hud] avatar_frame = "round"` hoặc
    `"square"`, bộ đọc `config::read_client`, lint bằng `lint_config.py`) do gate đọc lúc khởi động (thiếu hay
    sai thì gate không chạy). Sau `SessionStart` gate gửi tin `UiConfig` (0x8109, `since` 2, `protocol::kVersion`
    thành 2) cho client có `Hello.version >= 2`; client khai phiên bản 1 không nhận vì coi tin lạ là vi phạm.
    Client CHƯA nhận: chưa mở socket nào, nên exe vẫn dùng giá trị gắn lúc dựng ở `client.build.toml`; khi có module
    nối máy chủ thì `UiConfig` đè lên giá trị gắn. Đã chạy thật bằng một probe tạm, không vào repo (`Table` thật với
    auth và store giả): Hello 2, Login, EnterGame cho ra `SessionStart`, `UiConfig`, `Position` với khung đúng như
    `Ui` đã đặt; Hello 1 cho ra `SessionStart`, `Position`. Chưa có test trong `ctest` cho đường này: `serve_loop`
    của auth và store chạy tới khi `process::stop_requested()` đúng, hàm ấy cũng đúng khi stdin hết dòng (đọc
    `self_win32.cpp`, chưa đo stdin của `ctest`) và không có móc để test dừng chúng, nên probe phải chạy với stdin là
    ống mở (`sleep 60 | probe.exe`) và thoát bằng `_Exit`.
  - Nạp đầu: khung đầu phải có đủ cảnh lẫn HUD (nạp đồng bộ, `settle_first_scene`), và phải nhanh hơn G:\TLBB có số đo —
    chủ dự án chốt ngày 2026-10-13 ("load full giao diện game phải vượt qua G:\TLBB, có số làm dẫn chứng"; "load đồng bộ map
    cũng hiện luôn nhanh vẫn nhanh hơn"). Mọi việc không cần thiết bị GPU (đọc giao diện, bảng chuỗi, phông, mesh, địa hình,
    nạp driver) chạy ở luồng riêng từ đầu tiến trình (`Display::preload`, `ui::HudPrep`, `Display::State::kick_loading`);
    luồng vẽ chỉ làm việc cần thiết bị. Việc mới thêm vào đường nạp phải giữ ngân sách ở mục "Ngân sách" và đo bằng
    `TOOLS/run/bench_load.py`; mốc `Mốc <ms> ms` của `core/timeline.hpp` là bảng đo của đường nạp.
  - Bảng đo nhịp khung để dev giao diện đạt 120 fps, theo bảng thông số dev của Crazy — chủ dự án giao ngày 2026-10-13 ("thêm bảng
    đo giống crazy", "dịch sang tiếng Việt"): `ui/pace` (luôn hiện ở màn chơi trên PC, không phím hay cờ nào tắt được — chủ dự án chốt ngày 2026-10-14 ("Bật bộ hiển thị đo lường đi . cấm tắt"), thay quyết định F3 bật tắt cùng ngày; `--shot` chờ đủ 30 mẫu rồi mới chụp nên cần `--frames` từ 30, ảnh không có bảng thì `--bare`). Ba cột nhãn /
    giá trị căn phải / đơn vị, bốn nhóm (nhịp, chặng của khung, tải, đích vẽ), nhãn tiếng Việt vì là công cụ dev, không phải chữ
    người chơi. Kết luận ĐẠT khi không quá 5% khung vượt ngân sách cộng dung sai 10% (`meets_budget`); ngân sách là một nhịp quét của màn khi trình Fifo, không biết nhịp quét thì `1000 / render_hz`. Số là
    cửa sổ 90 khung gần nhất. Chưa có mili-giây GPU thật: lớp `gpu` đã có `write_timestamp`/`read_queries` (`engine/gpu/command.hpp`)
    nhưng client chưa dùng lần nào và chưa đo trên backend nào; "Xin ảnh" cao là dấu hiệu GPU chưa kịp.
  - Màn chơi, chủ dự án giao ngày 2026-10-13 ("hoàn tất toàn bộ giao diện chính xác", "fix triệt để mọi thứ làm mất texture"): bản
    đồ lớn (SceneMap) và bản đồ thế giới (LargeMap, widget WorldMap) port từ mã máy, hòm đồ và ô tiền, xoay người mẫu bảng nhân vật,
    con trỏ chuột của game (22 con trỏ đọc từ tài nguyên của `Game.exe`, `TOOLS/content/export_cursors.py`), phông Việt cho chữ có dấu
    (GBK12 cho chữ gốc, VTNAM14 khi cả run có chữ Việt), mặt đất nướng lọc tam tuyến 16 điểm ảnh mỗi ô (trần 8192 trên PC, 2048 trên điện
    thoại), hệ hạt thêm `SequenceFrame`, `DirectionRandomiser` và kiểu trộn `zero one_minus_src_colour`. Dữ liệu cần chạy theo thứ tự:
    `collect_map.py` rồi `collect_fx.py` (thiếu bước sau thì tên hệ hạt của cảnh "không có trong thư viện" và hiệu ứng biến mất), rồi
    `export_worldmap.py` (ghép `jpg_WorldMap00..19.dds` thành `Interface/LargeMap/WorldMap.png`). Tài liệu đo ở `TAILIEU/MAN-CHOI-GIAO-DIEN-2026.md`.
  - `TOOLS/run/click_shot.py` (chụp giao diện sau thao tác, chỉ Windows): SDL lấy vị trí nhấn từ CON TRỎ THẬT nên công cụ đặt con trỏ thật lên
    điểm bấm và trả lại khi xong; kéo (`--turn`, `--tilt`) và giữ (`--hold`) dùng nút thật `mouse_event` vì SDL hỏi `GetAsyncKeyState` khi gặp
    thông điệp di chuyển và tự nhả nút giả; cửa sổ được mở khoá và đưa lên trên cùng trong lúc dùng nút thật, client chạy với
    `SDL_MOUSE_FOCUS_CLICKTHROUGH=1`. CHỦ DỰ ÁN CẤM agent chạy công cụ này với bước chuột (2026-10-13: "ngừng ngay việc chiếm chuột tự
    test"): nó cướp con trỏ thật của người đang dùng máy. Agent dựng bản mới rồi chạy cho người chơi tự test, và nói rõ phần nào chưa kiểm.
- Thư viện ngoài (tên — nguồn): cgltf, stb, meshoptimizer, sse2neon (Android), lz4, zstd, xxhash
  (ba gói của `fs` và gói shader), opus (tải Opus của tệp âm thanh `.tla`), tomlplusplus 3.4.0
  (module `config`) — vcpkg manifest (`vcpkg.json`, `C:\dev\vcpkg`); libsodium 1.0.22 (`seal`,
  `secure`) và miniaudio (`audio`) — chép nguồn trong `third_party/`, mỗi thư mục có `NGUON.txt`;
  Vulkan SDK của máy cho shader (`slang.dll` dịch nguồn `.slang`, `dxcompiler.dll` chỉ đọc phản chiếu DXIL). Cho máy chủ: libpq
  (không default-features) đã vào manifest, module `store/pg` đã dùng; đã duyệt ngày 2026-10-06 và đã build thử.
  PostgreSQL 18.6 nằm trong `dev/server/pgsql`, tải bằng `setup_db.py`.
- Tài liệu dự án (chỉ mục ở `docs/README.md`): `docs/TIEN-DO.md` (tiến độ việc nhiều phiên), `docs/NGUON-FORGE2.md` (tệp chép từ
  Forge2: nguồn, khác gốc, số đo), `docs/NGUON-TLBB.md` (tệp port từ TLBB Dev),
  `docs/CAMERA-2026.md` (camera và chuột đọc từ mã máy của client 2026: địa chỉ, hành vi, lệnh
  tái hiện), `docs/VA-CHAM-2026.md` (mặt công trình `.WCollision` đọc từ mã máy `PathLib.dll`; module
  `collision` có bộ đọc, lưới, cây OPCODE và `Model::height`/`raycast`; client dùng `height` để nâng chân),
  `docs/DUONG-DI-2026.md` (lưới đi `.path`, tìm đường và luật đi của client 2026, lệnh
  chạy trọng tài), `docs/TAO-NHAN-VAT-2026.md` (màn tạo nhân vật: ba bộ quản dữ liệu của
  `Game.exe`, phân bố ảnh chân dung, mặt, tóc, bộ đồ, thói quen của `CreateRole.lua`, lệnh sinh số
  vàng), `docs/NGHI-NGO.md` (sổ nghi ngờ), `docs/KE-HOACH-SERVER.md` (kế hoạch máy chủ, mười ba mốc), `docs/SERVER-TEP-CAU-HINH.md`
  (từng tệp cấu hình và bảng của máy chủ, tên gốc sang tên tiếng Anh), `docs/PROTOCOL-TIN.md`
  (bảng tra danh mục tin của protocol, tệp sinh), `docs/NHIEM-VU-VO-CONG-2026.md` (VẮNG sau vụ mất
  2026-10-09 — code `src/client/book/*`, `Test/Quest`, `Test/Skill`, `TOOLS/port/oracle/*` còn trỏ
  tới; bản cũ ở `docs/KHOI-PHUC-2026-10-09/chua-du/docs/`), `docs/GIAO-DIEN-2026.md` (widget của bản 2026 đọc
  từ mã máy CEGUI: listbox, thanh cuộn, cửa sổ phức hợp, nút action, ô tiền, phông và thẻ chữ),
  `docs/SERVER-BAO-MAT.md` (thiết kế bắt tay, bản ghi mã hoá và mặt trước của gate),
  `docs/SERVER-DI-CHUYEN.md` (di chuyển do server làm chủ),
  `docs/CHEP-FORGE2.md` (quy trình chép một tệp từ Forge2), `docs/DINH-DANG-TLA.md` (định dạng
  tệp âm thanh đã cook `.tla`), `docs/I18N-BAO-CAO-2026-10-13.md` (báo cáo bản địa hoá, bản cuối),
  `TAILIEU/` (phân tích mã máy mới: `DANG-NHAP-GOC`, `GOI-TIN-DANG-NHAP`, `MAY-CHU-SUY-RA`,
  `MAN-CHOI-GIAO-DIEN-2026`, `TOC-DO-NAP-SO-VOI-TLBB`; chỉ mục ở `TAILIEU/README.md`),
  `dev/server/README.md` (bố cục runtime của máy chủ, lệnh chạy cụm),
  `docs/giao-viec/` (hồ sơ từng đợt giao việc cho phiên AI phụ; `KD-DOT-1/GHI-CHU.md` giữ các ý
  tối ưu đã hoãn), `docs/BAY-DA-BIET.md` (bẫy đã đo của từng vùng; chỉ mục ở mục 11).
  Bộ quy cách C++23 không nằm trong repo (bản duy nhất ở `D:\CLAUDE\cpp23`).
- Lệch quy định chung bên dưới (mỗi dòng: mục nào — dự án làm gì thay — vì sao):
  - Mục 3, bố cục — chủ dự án chốt 2026-10-12: `engine/` là hạ tầng tái sử dụng. Target engine
    chỉ nhận `engine/` trên dòng include; client không thấy `src/server`, server không thấy
    `src/client`. Configure dừng nếu một tệp include module ngoài cây của nó
    (`game_reject_foreign`). Phần game ở `src/client/`, `src/server/`, `src/shared/`. Include vẫn
    `"<m>/x.hpp"`. Nguyên liệu dựng (chữ, ảnh nguồn, icon) ở `assets/`.
    `dev/` và `release/` là hai bản dành cho người chơi và nhà phát hành, không có mã.
    `dev` là máy chủ thử, `release` là bản chính thức. Mỗi bản tự chứa đủ phần:
    `client` (exe ở `client/bin`, assets ở `client/assets`), `server` (config, bảng,
    cảnh, SQL, exe, PostgreSQL), `web`, `tools`, `admin`, `load`. Assets của mỗi bản
    là của bản đó, không trỏ chung về `assets/`. APK ở `<bản>/client/APK`, bundle iOS
    ở `<bản>/client/IOS`.
    Vỏ Android ở `android/`. Vỏ Apple ở `apple/`. Một mã client cho cả ba. Công cụ
    Python nguồn ở `TOOLS/`, thư viện chép nguồn ở `third_party/`, trang web nguồn ở
    `WEB/`. Chủ dự án chốt ngày 2026-10-12.
  - Mục 2 bước 3, mục 6 và mục 8, test — chủ dự án chốt 2026-10-12: test nằm ở
    `Test/<Domain>/<tên>_tests.cpp`, một domain một thư mục, tên domain trùng module
    (`Test/Gpu/gpu_tests.cpp`, `Test/Protocol/protocol_tests.cpp`). Không dàn phẳng ở `tests/`.
    Header dùng chung ở gốc `Test/`: `test.hpp`, `support/`, `bench/`, `fuzz/`, `golden/`.
    `game_test` tìm `Test/*/<tên>_tests.cpp`. Tệp không có thì CMake in một dòng và bỏ target;
    configure không đỏ, và thiếu file test không phải nợ phải viết bù. Không dựng một file test
    cho mỗi file nguồn. Chỉ viết test khi logic thuần sai thì hỏng thầm, khi sửa bug cần chặn tái
    phát, hoặc khi người dùng yêu cầu. Shader, mesh, camera, vẽ, layout và hiệu ứng kiểm bằng chạy
    bản vừa build. Mục 6 ("hành vi mới có test", "mỗi ca biên có test") không áp ngoài ba trường
    hợp đó.
  - Mục 3, thư mục `build/`: chỉ chứa thứ xoá đi là dựng lại được (cây dựng của preset, log, ảnh
    chụp, tệp giải mã, bản chép tạm). Không đặt ở đó thứ gì mất là mất việc: công cụ viết ra để
    dùng lại vào `TOOLS/`, mã thử có giá trị vào `Test/<Domain>/`, worktree của phiên agent chạy song song
    vào `.worktrees/<tên>` (đã ignore), không vào `build/<tên>`. Agent dùng `build/` làm chỗ nháp
    thì trước khi báo xong phải dời thứ đáng giữ ra đúng chỗ và xoá phần còn lại — chủ dự án nhắc
    ngày 2026-10-08 ("tools phải ở tools, build sau này tôi xoá là mất code").
  - Mục 3, máy chủ: `dev/server/` là máy chủ thử (exe ở
    `dev/server/bin`, cấu hình, bảng, cảnh, SQL, PostgreSQL và dữ liệu). Bản chính thức
    cùng hình ở `release/server/`, database riêng, không dùng dữ liệu của bản thử. Bố cục ở
    `dev/README.md`. Database bản thử: `python TOOLS/server/setup_db.py
    fetch|init|start|stop|status`. Kiểm cấu hình: `python TOOLS/server/lint_config.py` (chạy trong
    `ctest` dưới tên `server_config_lint`; sửa tệp TOML xong thì chạy `--fix` rồi mới commit).
  - Mục 3, preset: thêm `msvc-debug`, `msvc-release` (chạy trong `dev.bat`), `android-arm64`,
    `android-x86_64` (test chạy trên thiết bị qua adb, `cmake/GameAndroidRun.cmake`), `ios-arm64`,
    `ios-sim-arm64` (chỉ hiện trên macOS). Mọi preset bật cảnh báo thành lỗi.
  - Mục 3, cài bản chạy: `cmake --install build/msvc-release` chép client vào
    `release/client/bin`. Preset dev cài vào `dev/client/bin`. APK vào `<prefix>/client/APK`.
    Bundle iOS vào `<prefix>/client/IOS`. Exe máy chủ cùng một lần cài, component `server`,
    vào `<prefix>/server/bin`. Kiểm đầu cuối trình giám sát: `python -B
    docs/giao-viec/P2-DOT-1/kiem-claude/boot_check.py <thư mục exe> dev/server/config`.
  - Mục 3, tệp sinh của protocol: sửa bảng ở `src/shared/protocol/catalog/*.tsv` rồi chạy `python -B
    TOOLS/server/gen_protocol.py`; nó ghi `src/shared/protocol/messages.hpp`, `messages.cpp`,
    `Test/Protocol/protocol_samples.hpp` và `docs/PROTOCOL-TIN.md`. Không sửa tay bốn tệp đó; test
    `protocol_catalog_fresh` đỏ khi tệp sinh cũ hơn bảng. Bộ sinh tự bẻ dòng theo trần cột đọc
    từ `.clang-format`: đổi `.clang-format` hay chạy clang-format cả cây xong thì chạy lại bộ
    sinh, và `python -B -m unittest discover -s TOOLS/server -p "test_gen_protocol.py"` phải
    xanh (một ca chạy clang-format thật trên đầu ra).
  - Mục 3, module máy chủ cần header của tomlplusplus: preset MSVC cài nó qua vcpkg vào
    `vcpkg_installed/`, `clang-asan` cũng kế thừa preset `vcpkg` nên tự cài; `gcc-debug` và `ci-gcc`
    không chạy vcpkg, chỉ lấy header ở chính thư mục đó. Chưa cấu hình một preset có vcpkg lần nào
    thì ở preset GCC CMake in "không thấy toml++/toml.hpp" và bỏ mọi target máy chủ. Trên Linux
    (`gcc-asan`, `clang-tsan` không kế thừa `vcpkg`) header ấy phải có sẵn trong đường tìm của hệ
    thống.
  - Dữ liệu người chơi: `python TOOLS/content/export_look.py <_raw> <_glb> dev/client/assets` (bảng
    `Table/*.tsv` từ Config nhị phân của client; `faces.tsv`, `hairs.tsv` giữ mọi dòng theo thứ tự
    tệp gốc kèm `name`, `choice` cho màn tạo nhân vật), `export_config.py` (dòng dưới, cho
    `newbie_outfits.tsv`), rồi `python TOOLS/content/collect_avatar.py <_raw> <_glb> dev/client/assets`
    (GLB và ảnh của bộ mặc định, mọi mặt, tóc, bộ đồ chọn được lúc tạo và 30 người mẫu xem trước
    môn phái của `Table/sect_models.tsv` do `export_look.py` sinh; danh sách
    `Table/avatar.files.tsv`; APK đóng theo danh sách đó). `Table/portraits.tsv` (ảnh chân dung kèm
    `choice`, `order`) do `collect_ui.py` sinh.
  - Bảng nhiệm vụ và võ công: `python -B TOOLS/content/export_config.py "F:/tl 2026/_raw"
    dev/client/assets` (bảng `Table/*.tsv` xuất từ Config nhị phân, công cụ tự đối chiếu từng ô với bảng
    gốc; `--check` chỉ kiểm) và `python -B TOOLS/content/export_icons.py "F:/tl 2026/_raw"
    dev/client/assets` (`Table/icons.tsv`: tên icon sang bộ ảnh). `quest_tests`, `skill_tests` chỉ chạy
    ca bảng thật khi các tệp đó có lúc cấu hình CMake.
  - Bảng port từ script Lua (`ui/panel/quest_log`...): số vàng ở `Test/golden/panel/` do trọng
    tài sinh, tức script gốc chạy trên `LuaPlus.dll` của client: `python -B TOOLS/port/lua_oracle.py
    "F:/tl 2026/2026/Bin64" <script đã giải bằng lua_plain.py> <layout> <kịch bản ở TOOLS/port/oracle>
    <tệp số vàng> --words TOOLS/port/oracle/words.vi.tsv --lib TOOLS/port/oracle/<api>.lua`. Script
    đọc bảng của game thì thêm `--table <tên>=<tệp .tsv>` (bảng thành `__tables.<tên>` cho tệp
    `--lib`), tên đăng ký của script khác tên tệp thì thêm `--name` (lệnh đủ của bảng tạo nhân vật
    ở `docs/TAO-NHAN-VAT-2026.md` mục 6). Không sửa tay số vàng.
  - Check của một tệp có math: `CPP23_G14="g++ -msse4.1" CPP23_G15="g++ -msse4.1"
    CPP23_C20="clang++ -msse4.1" python ~/.claude/cpp23/tools/check.py <tệp>` (CMake thêm cờ này cho
    game_math; check.py dịch từng tệp riêng nên phải tự thêm).
  - Dữ liệu của một map gom bằng `python TOOLS/content/collect_map.py <_raw> <_glb> dev/client/assets <map>`;
    cây `_raw` và `_glb` nằm ở `F:\tl 2026`, ngoài dự án, chỉ là nguồn để gom. Cây `_glb` sinh từ
    `_raw` bằng `python TOOLS/glb/export_glb.py <_raw> <_glb>` và kiểm lại bằng
    `TOOLS/glb/verify_glb.py`.
  - Mục 3, chép mã từ Forge2: `python TOOLS/port/forge2_port.py copy|measure|includes` (chép một
    tệp và đổi namespace, tiền tố `k`; đo tỉ lệ phải sửa; hỏi header cần include). Forge2 chỉ đọc.
  - Mục 8, tệp Win32: lấy `<windows.h>` qua `core/win32.hpp` (kèm `UNICODE`, `NOMINMAX`,
    `_WIN32_WINNT`), rồi include trực tiếp header con (`winuser.h`...) — xem nhóm "Trình dịch, cờ
    và cổng kiểm" của `docs/BAY-DA-BIET.md`.
  - Mục 3, bản địa hoá: nguồn của một ngôn ngữ là `assets/i18n/<mã>.tsv` (chuỗi giao diện,
    `scene/<tên cảnh>`, `image/<bộ ảnh>/<tên ảnh>`, `file/<đường dẫn trong dữ liệu>`) kèm tệp ở
    `assets/i18n/<mã>/`. Target
    `thienlong_i18n` (`cmake/GameI18n.cmake`) chạy `TOOLS/content/build_i18n.py` ở mỗi lượt dựng
    client và đưa ngôn ngữ của `-DGAME_LANGUAGE=<mã>` (mặc định `zh`) vào `dev/client/assets`. Chạy tay:
    `python -B TOOLS/content/build_i18n.py assets/i18n/vi.tsv dev/client/assets --state build/i18n`.
    `dev/client/assets` dùng chung cho mọi preset nên các preset dựng cùng một `GAME_LANGUAGE`. Làm ảnh
    thay: `python -B TOOLS/content/export_layout_images.py` xuất ảnh gốc của một layout kèm cỡ ô;
    ảnh nút có chữ thì đặt chữ lên nền nút gốc, không thay cả nút. Ba thẻ và nút vào game của bảng
    đăng nhập lấy chữ từ tấm nút chủ dự án vẽ: `python -B TOOLS/content/letter_buttons.py
    assets/i18n/vi/source/button_sheet.png build/i18n/base assets/i18n/vi`. Mọi ảnh có chữ khác
    (nút, tiêu đề, nhãn, câu đối) dựng chữ bằng phông Merienda Bold theo bảng
    `assets/i18n/vi/source/labels.tsv`: sửa bảng rồi chạy `python -B TOOLS/content/letter_labels.py
    assets/i18n/vi/source/labels.tsv dev/client/assets build/i18n assets/i18n/vi --sync` (ghi
    `assets/i18n/vi/labels/` và khối dòng `image/...` của `vi.tsv`; `--sheet <tệp.png>` ra tấm so
    trước sau). Chữ dài thì dùng từ Hán Việt ngắn, không thu cỡ chữ — chủ dự án dặn ngày 2026-10-09.
  - Mục 6, `ctest` xanh: `window_modal_tests` (sáu ca vào vòng kéo thật của Windows) luôn dựng
    nhưng không nằm trong `ctest` thường ngày vì nó làm con trỏ chuột của người đang dùng máy
    nháy; chạy tay một lượt khi sửa `SRC/window/window.cpp` — xem nhóm "Test và công cụ đụng máy
    người dùng" của `docs/BAY-DA-BIET.md`.
  - Mục 10 và 11, bẫy mới: mục 11 chỉ giữ bẫy mà việc nào cũng có thể dính; bẫy của riêng một
    vùng ghi ở `docs/BAY-DA-BIET.md`, mục 11 có chỉ mục tới từng nhóm — tệp này nạp vào mọi phiên
    của mọi agent, và đo ngày 2026-10-09 nó nặng 62 KB, riêng mục 11 là 30 KB (55 bẫy).

---

# Quy định chung cho AI coding agent

Phần dưới giống nhau ở mọi dự án tạo từ mẫu cpp23 — không sửa riêng ở đây; muốn đổi thì đổi ở mẫu. Chỗ
dự án buộc phải khác (preset, bố cục, trình dịch) ghi ở dòng "Lệch quy định chung" của mục 0, và dòng đó thắng.
Áp dụng cho mọi agent (Claude Code, Codex, Grok, DeepSeek, OpenCode…); `CLAUDE.md` chỉ nhập tệp này.
Luật ở đây thắng thói quen của agent; yêu cầu tường minh của người dùng trong phiên thắng tệp này. Gặp
mâu thuẫn thì nói ra, không tự chọn im lặng.

## 1. Nguồn sự thật, theo thứ bậc

1. Yêu cầu tường minh của người dùng trong phiên.
2. Tệp này và mã hiện có của dự án (phong cách tệp đang sửa đi trước thói quen).
3. Bộ quy cách C++23: `~/.claude/cpp23/MAP.md` (luật sắt, quy trình 7 bước, tra quy tắc theo mã) và
   `~/.claude/cpp23/refs/`. Máy không có bộ này: tra bản trong repo gốc của người dùng, không đoán.
4. Hiểu biết chung của agent — thấp nhất. Trí nhớ về phiên bản, cờ, API, mức hỗ trợ tính năng KHÔNG
   phải bằng chứng: tra tài liệu hoặc build thử một tệp 10 dòng.

## 2. Vòng làm việc — mọi thay đổi đi qua đủ các bước

1. **Hiểu trước khi sửa.** Đọc code xung quanh, test liên quan, và mọi nơi gọi (grep tên hàm/kiểu) trước
   khi đổi chữ ký. Không sửa tệp chưa đọc.
2. **Kế hoạch ngắn** khi việc chạm > 3 tệp, API công khai, đa luồng, giao thức mạng hay dữ liệu lưu:
   tệp sẽ đổi, rủi ro, cách kiểm. Việc nhỏ thì làm luôn.
3. **Test đỏ trước** cho bug và tính năng mới: test phải thất bại vì đúng lý do, rồi mới sửa code.
4. **Sửa từng bước nhỏ, build sau mỗi bước.** Không viết 500 dòng rồi mới biên dịch lần đầu.
5. **Kiểm bằng máy** (lệnh ở mục 3) — không tự tuyên bố "chạy được" khi chưa thấy output.
6. **Đọc lại diff của chính mình** một lượt: tên, đường lỗi, comment còn đúng, không sót code debug.
7. **Báo cáo bốn mục:** Đã kiểm (lệnh + kết quả thật) / Chưa kiểm (vì sao) / Giả định / Lệch quy tắc.

## 3. Lệnh của dự án

- Cấu hình + build + test: `cmake --preset gcc-debug`, `cmake --build --preset gcc-debug`,
  `ctest --preset gcc-debug` (preset khác: `clang-asan`, `ci-gcc`; Linux thêm `gcc-asan`, `clang-tsan`).
- Kiểm quy cách tệp đã đổi, chạy ở gốc repo: `python ~/.claude/cpp23/tools/check.py <tệp…>`
  (GCC + Clang `-Werror` với 84 cờ cảnh báo, clang-tidy 23). Lặp nhanh: `--no-tidy --only gcc`.
- Chạy test của thay đổi qua cổng đầy đủ: `python ~/.claude/cpp23/tools/check.py --run
  tests/<m>_tests.cpp --with src/<m>/<x>.cpp` — Clang dưới ASan + UBSan mở rộng + hardening STL, GCC
  với debug mode của libstdc++ (cpp23 CL-02).
- Chạy test dưới sanitizer: `ctest --preset clang-asan` (Windows: runtime ASan của LLVM phải có trên PATH).
- Kiểm tầng: test `layers` nằm sẵn trong `ctest`. Header tự đủ: target `header_check` nằm sẵn trong build.
- MSVC (khi cần ABI/IDE của MSVC): skill `cpp-build`, cổng `dev.bat`.

## 4. Thái độ

- **Trung thực tuyệt đối.** Không bịa API, cờ, tên target, kết quả đo. Chưa chạy thì nói "chưa chạy".
  Test đỏ thì nói đỏ và dán output. Nói "tôi không chắc, cần kiểm" tốt hơn mọi câu trả lời tự tin mà sai.
- **Phản biện có lý do.** Yêu cầu có rủi ro (UB, mất dữ liệu, vỡ giao thức, tối ưu không đo) thì nói thẳng,
  kèm lý do và phương án thay thế; quyết định cuối thuộc người dùng. Không chiều theo cho vừa lòng.
- **Thấy là sửa.** Đã chắc chắn một thứ là vấn đề (bug, UB, hợp đồng lệch nhau, số chép nhiều nơi,
  trùng lặp, comment sai, cảnh báo, thiếu test canh, thứ được nhờ kiểm mà thấy hỏng hoặc thiếu) thì
  giải quyết ngay trong cùng lượt làm việc: nguyên nhân gốc, test đỏ trước xanh sau, qua đủ bộ kiểm.
  Rồi ghi chú lại: báo cáo nêu vấn đề, chỗ và cách sửa; quyết định mới ghi vào mục 0. Cấm trả về danh
  sách "để lại, cần bạn quyết" cho thứ đã chắc là sai.
- **Chưa chắc thì kiểm tới khi chắc** (đọc mã, build thử, đo), không báo cáo nghi ngờ rồi dừng.
  `docs/NGHI-NGO.md` chỉ dành cho thứ đã kiểm hết cách mà vẫn chưa kết luận được, kèm điều còn thiếu.
- **Tự chọn, không dừng để hỏi.** Có nhiều cách sửa thì chọn cách tốt nhất theo quy cách và số đo, làm
  luôn, ghi lý do chọn và giả định trong báo cáo. Chỉ hỏi trước khi làm với thao tác khó đảo ngược
  (mục 9).
- **Không phình phạm vi tính năng.** Không thêm tính năng, tuỳ chọn hay lớp trừu tượng không ai yêu
  cầu. Sửa một vấn đề đã chắc chắn không phải là phình phạm vi.
- **Sửa nguyên nhân, không vá triệu chứng.** Thêm `if (p)` mà không trả lời được vì sao `p` null là chưa xong.
- **Dừng khi bế tắc.** Hai lần sửa cùng một lỗi không ăn → dừng thử bừa, quay lại tìm nguyên nhân gốc
  (skill `investigating-bugs`), báo người dùng điều đã biết và chưa biết.

## 5. Cấm — những cách "làm cho xanh" giả

- Xoá, nới, bỏ qua hay sửa kỳ vọng của test để nó qua mà không chứng minh kỳ vọng cũ sai.
- Thêm `sleep`/retry để che race; nuốt lỗi bằng `catch (...) {}`; trả giá trị mặc định thay vì báo lỗi.
- Tắt warning, thêm NOLINT không nêu check + lý do + mã quy tắc, `#if 0` code hỏng, hạ chuẩn ngôn ngữ.
- Sửa `.clang-tidy`, `config/warnings-*.txt` để né lỗi — đổi luật thì đổi ở bộ cpp23 và nói rõ.
- Đổi định dạng dữ liệu lưu hay giao thức mạng mà không tăng phiên bản (cpp23 KTR-09).
- Copy-paste một khối lần thứ ba thay vì tách hàm.

## 6. Định nghĩa "xong"

Một thay đổi chỉ được gọi là xong khi:

- Build 0 warning với GCC và Clang (`-Werror`); `check.py` xanh trên mọi tệp đã đổi.
- `ctest` xanh, gồm `layers`; hành vi mới có test; bug đã sửa có test chặn tái phát (đỏ
  trước, xanh sau). Mỗi mã lỗi, câu bảo vệ, ca biên có test đi tới (cpp23 CL-04).
- Báo cáo có bằng chứng cho năm thuộc tính an toàn, bền, tối ưu, hiện đại, thông minh (cpp23 CL-01).
- Code đụng bộ nhớ, con trỏ, vòng đời: đã chạy `clang-asan`. Code đa luồng: đã chạy `clang-tsan` trên
  Linux, hoặc ghi rõ "chưa kiểm TSan" (Windows không có TSan).
- Comment và tài liệu khớp code mới; không TODO mồ côi; không code chết trong comment.
- Diff chỉ chứa thay đổi của việc này và phần sửa những vấn đề đã chắc chắn gặp trên đường. Không
  còn vấn đề đã chắc chắn nào bị để lại; mỗi vấn đề đã sửa có ghi chú. Đã nói rõ phần chưa kiểm.

## 7. Quy cách code — cốt lõi (đầy đủ: 13 luật sắt trong MAP.md)

- Chất lượng cực hạn (cpp23 `refs/20`): liệt kê cách hỏng trước khi viết; đường lỗi nào cũng có test;
  ghi độ phức tạp và trần đầu vào; tiện ích chuẩn C++23 thay idiom cũ; điều gì máy chứng minh được
  (kiểu, `static_assert`, thuộc tính) thì không để cho comment; không thêm trừu tượng chưa có nơi dùng.
- Ưu tiên: Đúng > An toàn, ổn định > Rõ ràng > Hiệu năng > Ngắn gọn. Hiệu năng chỉ thắng khi có số đo.
- Không UB dưới mọi hình thức. Dữ liệu từ client/tệp/mạng không bao giờ đi vào `check`/`assert`/`.at()`:
  kiểm biên và trần trước, trả lỗi.
- Lỗi lập trình → `core::check`/`core::fail`; lỗi dự kiến → `std::expected` + `enum class` lỗi; không `throw`.
- Kiểu mạnh cho ID và đơn vị (`core::StrongId`, `core::Tick`); giá trị trước tham chiếu; `unique_ptr` mặc định.
- Logic game tất định: không phụ thuộc thứ tự `unordered_*`, đồng hồ thật, phân phối `<random>`.
- Định danh tiếng Anh, không dấu; comment, log, chuỗi UI tiếng Việt có dấu.
- Comment nói TẠI SAO, hợp đồng, bất biến; sửa code thì sửa comment cùng lúc.
- Hình thức mã (định dạng, độ dài dòng, độ lồng, cỡ hàm, số tham số, quy ước đặt tên, dạng comment)
  không phải luật: viết theo phong cách tệp đang sửa, không sửa mã chỉ để đổi hình thức.

## 8. Bố cục và kiến trúc

- Module là thư mục `src/<m>/`: `x.hpp` đặt cạnh `x.cpp`; include `"<m>/x.hpp"` từ gốc `src/`; header
  nội bộ ở `src/<m>/detail/`, module khác không include.
- Thêm module: target `game_<m>` trong `CMakeLists.txt` (chỉ link tầng dưới) → link vào
  `game_all_modules` → một dòng trong bảng `cmake/GameLayers.cmake` → `tests/<m>_tests.cpp` + `add_test`.
- Thêm phụ thuộc ngoài (vcpkg, FetchContent): hỏi người dùng trước; ưu tiên thư viện chuẩn C++23.
- Tài nguyên nhị phân (`.blend`, `.fbx`, ảnh, âm thanh) đi qua Git LFS (`.gitattributes`).

## 9. Ranh giới an toàn

- Không commit, push, force-push, rebase, xoá nhánh, `git clean` khi chưa được yêu cầu rõ.
- Không xoá hay ghi đè tệp chưa đọc; không động vào tệp ngoài repo trừ khi việc đòi hỏi và đã nói ra.
- Không ghi key, token, mật khẩu vào repo, log hay test. Cấu hình bí mật: `*.local.toml`, `.env` (đã ignore).
- Lệnh chạy lâu (build vcpkg lần đầu, benchmark): báo trước, chạy nền, không huỷ giữa chừng.

## 10. Để agent làm việc hiệu quả nhất

- **Tra rẻ trước, đọc đắt sau:** grep tên, đọc đúng hàm cần; tra quy tắc theo mã trong `INDEX.md` của
  cpp23 thay vì đọc trọn tệp refs.
- **Việc độc lập thì làm song song** (nhiều lệnh đọc/tìm một lượt, subagent cho khảo sát lớn) — nhưng
  không giao cho agent khác việc mà mình cần kết quả để làm bước tiếp.
- **Việc kéo dài nhiều phiên:** ghi `docs/TIEN-DO.md` (đã xong, đang làm, còn lại, lệnh kiểm, quyết định
  đã chốt) để phiên sau hoặc agent khác nối tiếp mà không phải đoán.
- **Học bền vững:** phát hiện bẫy mới của dự án (đã đo, có lệnh tái hiện) → thêm vào mục 11 trong cùng thay
  đổi. Người dùng sửa hướng làm việc lâu dài → đề xuất ghi vào tệp này.
- **Không tin output của chính mình khi chưa kiểm:** code agent sinh ra trông đúng nhất là lúc nguy hiểm nhất.

## 11. Bẫy đã biết (đã đo — thêm dần, kèm lệnh tái hiện)

Mục này giữ nguyên văn những bẫy mà việc nào cũng có thể dính. Bẫy của riêng một vùng nằm nguyên
văn ở `docs/BAY-DA-BIET.md`, chia theo nhóm; cuối mục là chỉ mục "sắp làm gì thì đọc nhóm nào".
Đọc nhóm đó TRƯỚC khi sửa vùng ấy. Chỗ khác trong kho ghi "mục 11 của `AGENTS.md`" cho một bẫy
không còn ở đây thì tra chỉ mục. Bẫy mới: việc nào cũng dính thì thêm vào danh sách dưới, của riêng
một vùng thì thêm vào nhóm của nó ở `docs/BAY-DA-BIET.md` kèm một cụm trong chỉ mục. Mỗi bẫy chỉ
nằm một nơi.

- Windows + Clang + ASan: build Debug phải dùng CRT phát hành `/MD`; CRT debug làm ASan báo nhầm
  "attempting free on address which was not malloc()-ed" (`cmake/GameSanitize.cmake` đã xử lý).
- Windows: `detect_leaks` không có; TSan không có; GCC MinGW không có runtime sanitizer.
- MSVC + CMake `cxx_std_23`: thiếu `/Zc:__cplusplus` thì `__cplusplus` = 199711 (`game::warnings` đã thêm).
- MSVC `/std:c++23` không tồn tại (D9002, lặng lẽ tụt về C++14): dùng `/std:c++23preview`.
- Dò tính năng bằng `__cpp_lib_*`, không bằng `__has_include` (MSVC trả 1 cả khi tính năng không có).
- Công cụ Bash của agent: heredoc Python (`python - <<'EOF'`) nuốt `\\` thành `\` và hỏng khi nội
  dung có dấu `'` lẻ (`0xFFFF'FFFFU`). Script có `\` hay `'` thì viết ra tệp bằng công cụ ghi tệp
  rồi chạy tệp. Ghi tệp bằng `cat > x.py <<'EOF'` cũng có lúc hỏng (đo 2026-10-08: một script 140
  dòng dừng với `unexpected EOF while looking for matching`, chưa tìm ra ký tự gây lỗi; cùng nội
  dung ghi bằng công cụ ghi tệp thì chạy). Công cụ ghi tệp lại cắt dấu cách cuối dòng: bảng TSV
  cần dấu cách cuối thì dùng ký hiệu thay, như `␣` của `TOOLS/port/oracle/words.vi.tsv`.
- Công cụ Bash của agent chạy Git Bash: `cmd /c "..."` bị đổi thành `cmd.exe C:/ ...` (MSYS đổi `/c` thành
  đường dẫn), cmd mở ra rồi treo không thoát (đo 2026-10-13: treo 10 phút trên lượt build MSVC). Lệnh `cmd`,
  `dev.bat`, `.bat` gọi bằng công cụ PowerShell, hoặc ở Git Bash thì `MSYS2_ARG_CONV_EXCL='*'` / `cmd //c`.
- Windows PowerShell 5.1: tệp `.ps1` UTF-8 không BOM bị đọc theo bảng mã ANSI, chuỗi tiếng Việt vỡ
  thành lỗi cú pháp; `Start-Process -PassThru` trả `ExitCode` rỗng nếu chưa đọc `.Handle` của tiến
  trình trước khi nó thoát.
- Chạy song song `check.py -j 6` (clang-tidy trên tệp vài nghìn dòng) với một lượt build Android
  làm cạn bộ nhớ dù máy có 64 GB: clang-tidy dừng với `LLVM ERROR: out of memory`, `apksigner`
  dừng với `java.lang.OutOfMemoryError` ở bước ký APK (đo 2026-10-07). Hai kết quả đó trông như
  lỗi mã nhưng không phải: chạy lại từng việc một thì qua. Việc nặng chạy tuần tự.
- `ctest --preset clang-asan` chạy trong `dev.bat` thì hỏng hàng loạt với mã `0xc0000139`:
  `dev.bat` đưa `clang_rt.asan_dynamic-x86_64.dll` của MSVC 14.51 lên trước bản của LLVM 23
  trong PATH (đội Grok đo ngày 2026-10-08: 41 trên 49 test hỏng; `fx_tests.exe` qua `dev.bat`
  thoát -1073741511, ngoài `dev.bat` thoát 0). Preset `clang-asan` dựng và chạy ở shell
  thường; chỉ preset MSVC cần `dev.bat`.
- `check.py --run` gọi từ Git Bash: exe dựng bằng GCC chết ngay với mã `0xC0000139` khi test dùng
  `<filesystem>`, vì `libstdc++-6.dll` cũ trong `mingw64/bin` của Git đứng trước bản của WinLibs
  trong PATH (đo 2026-10-08 ở `quest_tests`). Chạy với `PATH="<thư mục bin của WinLibs>:$PATH"`.
  Macro của test đưa qua biến trình dịch, đường dẫn tương đối: `CPP23_G14='g++
  -DGAME_CLIENT_DATA=\"dev/client/assets\"'` (cả `CPP23_G15`, `CPP23_C20`).
- Hai phiên agent trên cùng repo (đo 2026-10-08, 21:37 tới 21:54): phiên ở cây chính commit hộ, gộp
  rồi xoá worktree của phiên kia trong lúc phiên kia còn agent đang sửa tệp. Ba commit chụp trạng
  thái giữa chừng (`108a504`, `5934a9a`, `386607b`: commit trung gian có thể không dựng được), và
  `build/scratch` của worktree mất theo nó. Chỉ gộp và xoá worktree của một phiên sau khi phiên đó
  báo đã chốt; thứ đáng giữ dời khỏi `build/` ngay khi nó thành hình, đừng chờ cuối việc.
- Cây dựng `build/<preset>` là của chung mọi phiên trên cây chính, nên kết quả của nó trộn việc
  của mọi phiên: một lượt dựng dừng giữa chừng để lại exe cũ làm `ctest` đỏ giả (đo 2026-10-08:
  `clang-asan` dừng ở một tệp client, 16 test báo đỏ vì exe cũ hoặc thiếu exe, trong đó
  `config_tests` và `server_data_lint` "đỏ" chỉ vì exe chưa biết khoá `idle_timeout_ms`).
  Cần số đo riêng mà cây chung đang bận thì dựng cây riêng, chỉ các target cần: `cmake --preset
  <preset> -B build/<tên riêng>` rồi `cmake --build build/<tên riêng> --target <danh sách>` và
  `ctest --test-dir build/<tên riêng> -R <mẫu>`. Không dựng `all` ở cây riêng: target `compile_db`
  của `all` chép `compile_commands.json` của cây đó đè lên bản ở gốc dự án mà clangd đang dùng.
  Xong thì xoá cây riêng.
- Test và công cụ chạy exe máy chủ không được nghe cổng cố định hay địa chỉ ngoài loopback (đo
  2026-10-08, sửa xong 2026-10-09). Trước đó `service_tests` và `server_boot` chạy cụm bằng
  `SERVER/config`, tức gate nghe mọi địa chỉ ở hai cổng cố định, còn `gate_loop_tests` và
  `thienlong_gate_load` nghe bốn cổng cố định khác: hai lượt `ctest` cùng lúc là tranh cổng, và mỗi
  đường dẫn exe mới nghe địa chỉ ngoài loopback làm Windows thêm một cặp rule tường lửa, có thể bật
  hộp thoại hỏi người đang dùng máy (liệt kê: `Get-NetFirewallApplicationFilter | Where-Object
  Program -match thienlong`; hôm đó 12 rule cho 6 đường dẫn, 4 đường dẫn thuộc worktree đã xoá).
  Nay cấu hình của test khai `127.0.0.1:0` cho gate và cổng 0 cho mọi `[[process]]`: hệ điều hành
  cấp cổng lúc nghe, gate báo cổng thật ở dòng `ready game=<cổng> auth=<cổng>`, giám sát báo lại ở
  dòng `ready gate.game=<cổng> ...` của cụm (mục 3.1 của `docs/KE-HOACH-SERVER.md`). Test mới chạy
  exe máy chủ thì dựng cấu hình bằng `stage_config` của `Test/support/loopback_config.hpp` và lấy
  cổng bằng `supervise::parse_ready`, không đưa thẳng `SERVER/config` cho tiến trình sẽ nghe cổng
  và không xin cổng trước rồi ghi số vào cấu hình. Tái hiện ca đỏ cũ: ở bản trước `2026-10-09`,
  chạy hai `thienlong_gate.exe` trên cùng một cấu hình khai `127.0.0.1:0` thì cả hai thoát 2 với
  `gate.toml:21: khoá game ngoài miền`; nay ca `two_gates_share_one_config` của `gate_loop_tests`
  chạy đúng việc đó và xanh. Exe chỉ nghe `127.0.0.1` không làm Windows thêm rule.
- `audio_tests` phát tiếng thật (đọc mã 2026-10-08): ca `device_reports` mở thiết bị âm thanh của
  máy, phát nhạc đăng nhập cùng một tiếng bấm rồi chờ 400 ms (`Test/Audio/audio_tests.cpp`), nên mỗi
  lượt `ctest` có test này là một lần loa của người đang dùng máy kêu. Chạy lặp thì loại nó ra:
  `ctest --preset <p> -E "^audio_tests$"`.

Chỉ mục `docs/BAY-DA-BIET.md`: sắp làm một việc kể dưới đây thì đọc nhóm in đậm trước.

- **Trình dịch, cờ và cổng kiểm:** viết hay sửa tệp Win32 (`_WIN32_WINNT` của MinGW, macro
  `UNICODE` và `NOMINMAX` dưới `check.py`, header con mà `misc-include-cleaner` đòi, `<jobapi2.h>`,
  `WaitOnAddress`); đọc biến môi trường; khởi tạo ghi tên cho struct có thành viên kiểu lớp; khai
  `thread_local` cho kiểu có destructor; viết `if constexpr` không có `else`; gắn `target("sse4.1")`
  bằng pragma; thêm tệp `.rc`; chạy `check.py` trên tệp include header của Vulkan SDK (`dxcapi.h`,
  `slang.h`); đổi cách trình dịch shader ghép phản chiếu (`kPipeline`); ép con trỏ hàm lấy từ DLL; dựng
  `gcc-debug` trên Windows (SDL3, test `Not Run` vì thư viện vcpkg dựng bằng MSVC).
- **Công cụ Python và git:** đưa chữ vào stdin của tiến trình con (`git apply`); tách cây làm việc
  thành nhiều commit; gõ tên nhánh `server` trong lệnh git.
- **Test và công cụ đụng máy người dùng:** sửa `SRC/window/window.cpp`; viết hay chạy test, công cụ
  đụng cửa sổ, con trỏ chuột hay bàn phím thật; bấm thử, gõ thử giao diện (`click_shot.py`,
  `desk_watch.py`).
- **Máy chủ:** dùng `tomlplusplus` (không exception, dưới `check.py`); link `libpq`; đọc stdin hay
  nhận Ctrl+C trong exe máy chủ; chạy `pg_ctl` hay lệnh tự tách nền từ trình giám sát; viết mã
  Winsock; viết harness libFuzzer; chạy cụm bằng bản cài `dev/server/bin`; dựng cụm PostgreSQL tạm
  cho test (không nhận cổng 0).
- **Port từ client 2026:** port một hành vi của client gốc (mã 2008 và TLBB Dev không phải chuẩn;
  tháo `Bin64` bằng `pe_refs.py`); gọi DLL gốc làm trọng tài; sửa `SRC/nav` hay đụng lưới đi
  `.path`; đọc hay chạy script Lua của client; sinh số vàng bằng `lua_oracle.py` (widget CEGUI mà
  script dựa vào phải mô phỏng, `math.random` phải đưa sẵn số); đụng tệp `_iv` của nhân vật; port
  animation của node OGRE (camera chạy track); đặt tên kiểu mới trong một module.
- **Giao diện và bản địa hoá:** thêm chuỗi `#{khoá}` trong `SRC/ui/panel`; gom thêm một layout;
  đụng ảnh của `dev/client/assets/Interface` hay xoá `build/i18n`; làm ảnh nút tiếng Việt; tính ô cửa sổ
  có cỡ lẻ hay cỡ cửa sổ con trong `SRC/gui`; tách tên ảnh `set:... image:...`; đọc `Imageset` của scheme.
- **Vũ khí, hiệu ứng đồ, đòn đánh:** đọc mốc `BreakTime`/`HitTime` của `all.skill` (phần độ dài, không phải giây); chụp
  đòn bằng `--shot` (cố định khung, dùng `--auto-strike`); thử đá quý (`FFFFFF09` gần như tàng hình); chạy `check.py` cho tệp
  `src/client/*/` (cần `-I` từng thư mục); Ghidra `s:` không tìm chữ Hán.
- **Dữ liệu, hình và bản dựng client:** đọc kết quả `collision_tests` (Skipped, thư mục `_raw`);
  cảnh thiếu hiệu ứng hay gom lại `dev/client/assets/effect`; nạp texture và mip; thêm gói shader; dựng
  `thienlong_client` (cần Pillow); sửa đường nạp cảnh hay giao diện (đo bằng `bench_load.py`, ba bẫy đã đo);
  chụp bằng `--shot` (cần `--frames`, cửa sổ thu nhỏ, ảnh hai lượt không giống hệt); gom lại map cũ (thiếu
  lưới đi `.path` và `.WCollision` nếu gom trước 2026-10-13); ghi bộ đệm GPU đánh số theo ảnh swapchain (phải
  sau `wait_slot`); đọc chữ TRƯỢT của bảng đo nhịp khung.

## 12. Sổ tay

- `docs/NGHI-NGO.md` — mọi `// TODO(mô tả):` phải có một mục ở đây: chỗ nghi, vì sao chưa chắc, cần gì để
  kết luận. Tạo khi có TODO đầu tiên.
- `docs/TIEN-DO.md` — tiến độ việc nhiều phiên (mục 10). Tạo khi cần.
