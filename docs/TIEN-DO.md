# Tiến độ của dự án THIENLONG

Tệp này là nhật ký theo mục, mỗi mục ghi ngày: mục nào nói điều đúng vào ngày của nó. Trạng thái
hiện tại của cả dự án đọc ở ba chỗ: mục "Khảo sát theo mã, 2026-10-08" và mục "Còn lại" gần cuối
tệp này, và dòng "Trạng thái" ở mục 0 của `AGENTS.md`. Tên cũ của tệp là "cửa sổ, Vulkan và 57 vật
thể tĩnh của map huoyangu": đó là đích của sáu bước B1 tới B6 đầu tiên, tả ngay dưới.

## Máy chủ: gameplay đợt 2 — vật phẩm, chiến đấu, xã hội, nhiệm vụ (2026-10-15)

Bốn phiên con làm song song trong các thư mục riêng (một phiên mỗi vai); phiên điều phối chỉ nghiệm thu rồi commit từng phase. Chủ dự án
ra lệnh dừng giữa chừng ("commit dừng lại nào"), nên mỗi phase ghi rõ phần chưa nghiệm thu. Mỗi phase được dựng trong worktree sạch
(`msvc-release`, 0 warning), chạy `ctest` phần của phase, rồi dựng và chạy lại dưới `clang-asan` (ASan + UBSan).

| Phase | Commit | Nội dung | Đã kiểm |
|---|---|---|---|
| vật phẩm | `28327b34` | `item` (danh mục 47 148 mẫu, `Inventory`/`Planner`/`Plan` kế hoạch rồi áp dụng nguyên tử, sinh thuộc tính, giá, codec 4 khối kind `0x7001..0x7004`), `loot` (xác suất số nguyên phần triệu, hộp rơi nhặt hai pha), `shop` (tồn kho, mua, bán, mua lại, sửa), `forge` (nung, chạm, nâng cấp siêu vũ khí); `import_item.py`; `docs/SERVER-ITEM.md` | 13 test (item 5, loot 3, shop 3, forge 2) và `layers` xanh ở MSVC và ASan/UBSan; bảo toàn vật phẩm và tiền qua 3000–4000 bước ngẫu nhiên; chạy mọi công thức forge của bảng thật (64 nung, 128 chạm, 312 nâng cấp) |
| ghi chú cột | `2bbaba8b` | ghi chú cột `drop_packages` do `import_legacy.py` sinh nói "cặp bắt đầu ở cột 2" của tệp 2008, sai với tệp đang dùng (cặp bắt đầu ở cột 4) | `test_import_legacy` 29 ca |
| chiến đấu | `797c914c` | `actor` (thuộc tính, HP/MP/nộ khí, kinh nghiệm, chết và hồi sinh, bản ghi kind `0x5201`), `combat` (`Arena` theo cảnh, kỹ năng, buff, chuỗi sát thương, hồi chiêu, gom khí, kind `0x5202`); `import_combat.py`, `skill_coverage.py`, `golden_combat.py`; `docs/SERVER-COMBAT.md` | `actor_tests` 17 ca, `combat_tests` 22 ca ở MSVC và ASan/UBSan; số vàng tính độc lập bằng Python; `check.py --no-tidy` GCC 16 và Clang 23 sạch trên hai test |
| xã hội | `824748e7` | `social` (tổ đội, quan hệ, bang, thành, thư, chat và lọc chữ 340 từ, xếp hạng, thông báo; kind `0x5101..0x5107`); `import_social.py`; `docs/SERVER-SOCIAL.md` | 11 test (gồm mô phỏng 200 người, 30000 bước, kiểm đột biến) ở MSVC và ASan/UBSan; `test_import_social` 8 ca |
| nhiệm vụ | `9e0cc4d0`, `docs: SERVER-MISSION.md` | `ops`, `bus`, `ledger`, `mission` (kind `0x7101`), `talk`, `handlers` (rỗng) và bộ rút Lua tĩnh `lua_extract.py` (19 tệp `lua_*.py`); `docs/SERVER-MISSION.md` | 11 test ở MSVC và ASan/UBSan; `test_lua_extract` 35 ca; trên bảng thật: 1349 nhiệm vụ (1063 chạy được, 260 chưa hỗ trợ), 1029/1029 đi hết nhận–tiến độ–nộp, 3916 điểm vào hội thoại (2398 trích được, 1330 chưa) |
| cmake | `9105fc20` | gom tầng gameplay một chỗ, giữ chú thích của nhóm nhiệm vụ | `cmake --preset msvc-release` và `layers` xanh |

Không có xung đột kind giữa các bản ghi bền (đo bằng đọc mã): xã hội `0x5101..0x5107` (`0x5102` bỏ trống), thân thể `0x5201`, chiến đấu `0x5202`,
vật phẩm `0x7001..0x7004`, nhiệm vụ `0x7101`.

Chưa làm / biết rõ (chi tiết ở tài liệu của từng module):
- Chưa module nào của đợt này được zone, world, gate hay store dùng; `protocol` chưa có nhóm tin cho chiến đấu, vật phẩm, nhiệm vụ, hội thoại, xã hội
  (27 tin version 3); bản ghi bền chưa có cột trong migration nào của database (chưa có migration nào).
- Số tự đặt chờ chủ dự án duyệt: `item_limits.tsv` (dòng `made_up`), 30 khoá `made_up` của `social_limits.tsv`, các số `basis=made_up` của
  `docs/SERVER-COMBAT.md` mục 10–11, `shop::kMaxBuyGroups`, `shop::kMaxPool`, `loot::kMaxDropParamPpm`, trần `material_count` của forge.
- Chiến đấu: phái 11..15 phủ 91,67..94,23% dữ liệu (dưới 95%) vì bí pháp tiến giai (logic 700..707, 734, 735) giữ `unsupported`; 59/138 bí pháp chỉ nối
  với kỹ năng gốc bằng tên.
- Vật phẩm: chưa có khảm/tháo ngọc, nâng cấp ngọc, `ItemEnhance`, `EquipUpstage*`, `EquipLevelUp`, bộ trang bị, kiểm giới tính khi mặc.
- Nhiệm vụ: không có handler viết tay; đo 2026-10-15: 827 trong 1617 id nhiệm vụ của client không có dòng nào ở máy chủ, gồm 22 trên 25 id của chuỗi tân thủ 1400–1424.
- Xã hội: lời mời có nhớ và có hạn, không làm giai đoạn chuẩn bị lập bang và đột kích, `battle_time` đơn vị phút theo giả định.
- `check.py` đầy đủ (kể cả clang-tidy) chưa xanh trên các tệp test của talk, combat, actor (nhiễu hình thức: include-cleaner, designated initializer,
  const-correctness) và chưa chạy lại trên mã nguồn sau các sửa cuối của combat, social, talk; biên dịch `-Werror` bằng GCC 16 và Clang 23 thì sạch cho các
  test đó. `TOOLS/server/table_names.tsv` chưa biết các bảng mới (cần dữ liệu `--legacy` 2008 không có trên máy này). Chưa TSan (Windows không có).

## Máy chủ: gameplay đợt 1 — zone thật, dữ liệu cảnh, billing, luật đi (2026-10-14)

Chủ dự án giao ("triển khai hoàn thành hết toàn bộ các phần của server, dựa source gốc và bản 14 môn phái; đặt cao nhất và đáng tin nhất là
client 2026"; nguồn máy chủ 14 môn ở `G:\XJL7457`, chỉ đọc). Làm theo phase, mỗi phase một commit, kiểm trong worktree sạch rồi đẩy lên `main`:

| Phase | Commit | Nội dung | Đã kiểm |
|---|---|---|---|
| P1 nền | `ce1f194d` | `src/shared/ids` (kiểu mạnh), `src/server/dice` (xúc xắc tất định), `nav`/`collision` dời sang `src/shared/`, protocol v3 nhóm thế giới (`SceneEnter`, `EntityAppear/Disappear/Pos/Vitals`) | nav, ids, dice, protocol, layers |
| P2 zone | `ab35c898` | zone 20 Hz thật: lưới AOI 5×5 ô, cảnh tạo lười, `Saver` ghi điểm đứng (`Op::kSave`); kênh `ipc::Link` gate ↔ zone (`Attach/Detach/Moved` lên, `Down/Refuse/Close` xuống); `thienlong_bot` | zone, ipc, gate, gate_loop, server_boot; cụm thật: 6 khách thấy nhau, 3218 vị trí, 0 lỗi |
| P3 dữ liệu cảnh | `adc620e1` | `src/server/scenedata`: 325 thư mục cảnh (từ 244), quái/NPC đặt sẵn 47 970 (từ 40 168), lưới đi `.path` của client 2026 cho 273 cảnh; luật AI quái (307 kịch bản, 1 073 luật); công cụ `scene_xref`, `import_scene_xjl`, `scene_walk`, `scene_diff`, `ai_convert` | scenedata_tests 23 ca (nạp 325 cảnh thật), `test_scene_xjl.py` 51 ca; `docs/SERVER-SCENEDATA.md` |
| P4 zone đặt quái | `06414404` | khi tạo cảnh, zone đọc dữ liệu cảnh và đặt quái/NPC (1 đơn vị game = 100 cm, độ → 0..65535) | zone_tests; cụm thật với Đại Lý: 6 khách thấy 40 lượt NPC hiện ra, 0 lỗi |
| billing | `47159261` | `src/server/billing`: sổ điểm chỉ-thêm, webhook ký HMAC, đổi điểm hai pha, mã đổi, quà, hạn mức tiêu, PgBook trên PostgreSQL, tiến trình `thienlong_billing`, `fake_provider.py` | billing_tests 22, billing_db_tests 10 (PostgreSQL thật), billing_serve_tests 6 (exe thật), ASan/UBSan 38/38; `docs/SERVER-BILLING.md` |
| khoá HMAC | `9cc8a928` | `account::file_private`/`create_private_file`: billing từ chối khoá nhà cung cấp lỏng quyền (khe hở mà phiên billing đã nêu) | `secret_files_must_be_private`, ca khoá lỏng của `serve_bad_config` |
| luật đi | `9f6d8267` | zone kiểm ô đi được bằng lưới `.path`; bước đi từ chỗ đi được vào chỗ không đi được bị hoàn bằng `Relay::kPlace` (zone → gate → `Motion::place` + `Position`) | `walkable_*`, `host_*` trong zone_tests; cụm thật: 8 bot Đại Lý đi thẳng vào tường, 2.006 lần kéo về, không lần nào xa quá 45 cm; ASan/UBSan zone, ipc, gate |

Quyết định mới (ghi vào mục 0 của `AGENTS.md` khi xong cả đợt): lưới `.path` của client 2026 là luật đi của zone (client thắng); `walk.nav` 2008 chỉ
dùng cho cảnh không có `.path`; độ nới ở mép 20 cm; hướng quái/NPC đổi từ độ của bảng cảnh theo `0..360 -> 0..65535`
(quy ước gốc của góc chưa đối chiếu với client 2026: `docs/NGHI-NGO.md`). Cảnh Đại Lý: 2008 lệch lưới 2026 (50/164 điểm đặt quái nằm ngoài lưới).

Chưa làm / biết rõ:
- Bảng quái theo cấp người chơi (`spawns.level_*.tsv`), AI, tuần tra, hồi sinh chưa chạy trong zone: cảnh dựng xong thì quái đứng yên.
- Zone chỉ kiểm điểm đến (không quét đoạn đường) và chưa kiểm trục Y.
- Gate trả `kBusy` cho `EnterGame` khi đã cấu hình zone mà zone chưa lên.
- `build_data.py`/`table_names.tsv` chưa biết năm công cụ cảnh và sáu bảng máy chủ mới (cần dữ liệu `--legacy` 2008 không có trên máy này).
- 21 thư mục cảnh ứng viên bỏ và 44 cảnh XJL bị bỏ qua chờ chủ dự án quyết (`docs/SERVER-SCENEDATA.md`).
- Chưa chạy TSan (Windows không có) và debug mode libstdc++ cho zone, billing.

## Audit kỹ thuật một lượt theo mã hiện tại (2026-10-14)

Chạy audit chỉ-đọc ở `main 1ff6703`, không sửa production source. Đã đo:
778 file C++ (`engine/src/Test`) ~142k LOC, 53 module, 17 exe, 12 preset,
38 test domain, protocol 22 tin version 2, 4 backend GPU (không Metal gốc).
`gen_protocol --check` True. Kết quả ở `docs/AUDIT-2026-10-14/` (7 tệp:
README, inventory, architecture AS-IS, findings 17 mục `AUD-*`, gap + gate,
metrics, evidence). Trạng thái `PARTIALLY COMPLETE`: build/ctest/sanitizer/
benchmark chưa chạy (working tree bẩn + cấm việc nặng song song) nên mọi gate
trừ protocol-freshness là Unknown; không nhận platform nào ngoài Windows-x64
hiện tại là supported.

Phiên tiếp cùng ngày: consistency 120 evidence-ref (78 full-path, đã gắn đủ tiền
tố repo, 2 điểm đọc lại đúng chữ); type-surface 2228 class/struct + 277 enum class,
13501 điểm rẽ proxy (~9,5/100 LOC, không thay công cụ complexity); phiên khác đang
thêm vũ khí (`look/weapon`, `look/skill`, `avatar/locator`, `export_weapons/skills`,
chưa track — đã đọc lướt, giữ nhãn Stub).

Phiên tiếp cùng ngày: `lint_config.py` check-only sạch (26 tệp/437 cài đặt);
review tay toàn bộ 130 dòng quét secret — sạch (VERIFIED, không hardcoded);
đo thêm 419 TU + 366 header, sâu include client `main.cpp` = 10, 206 nhóm trùng
khối gom ở bộ ba `gpu/*/device.hpp` (by-design); đọc `client.build.toml`
(`schema = 1`, `avatar_frame = "square"`). Ba gate G-CONFIG/G-SECRET chuyển
Unknown → Pass; G-BUILD/G-TEST/G-SAN/G-LOAD vẫn Unknown (BLOCKED như cũ).

## Dọn tài liệu một lượt theo mã hiện tại (2026-10-14)

Quét toàn cây, đối chiếu `AGENTS.md` mục 0 với mã ở `main 1ff6703`, không động tới
code. Đã sửa: ngày/commit đối chiếu, đoạn khôi phục ghi rõ nay đã có `.git` và đã
dựng; nhảy đã có mã (`figure/motion/jump.cpp`, clip `跑跳a`/`跑跳b`); `.path` có ở
4 cảnh và `.WCollision` ở khoảng 70 cảnh (`collect_walk` đã gom); sổ nhiệm vụ đã
nối vào HUD (`hud.cpp` gọi `press_quest_book`/`paint_quest_book`); máy chủ đã có
`account/` (sổ, luật, vé, RPC, SQL) và gate gửi `SessionStart`/`UiConfig`/`Position`;
`protocol`/`secure`/`link` ở `src/shared/`, mạng ở `engine/net`, 22 tin version 2
bốn nhóm; `libpq` đã vào manifest (`store/pg` đã dùng); danh sách tài liệu thêm
`docs/README.md`, `TAILIEU/*`, `SERVER-DI-CHUYEN.md`, `I18N-BAO-CAO-2026-10-13.md`
và ghi rõ `NHIEM-VU-VO-CONG-2026.md` đang vắng (bản cũ ở `KHOI-PHUC-2026-10-09/chua-du/docs/`).

Đã dọn: xoá 6 bản nháp `I18N-BAO-CAO-2026-10-13.truoc-*`/`*.bak-*`; xoá bản sao bộ
quy cách C++23 trong repo (`docs/refs/`, `docs/MAP.md`, `docs/INDEX.md`, nội dung
cũ của `README.md` gốc) — bản duy nhất ở `D:\CLAUDE\cpp23`; viết mới `README.md`
gốc (bố cục, dựng, kiểm) và `docs/README.md` (chỉ mục sống/lưu trữ, tệp thiếu).
`docs/giao-viec/`, `docs/AUDIT/`, `docs/KHOI-PHUC-2026-10-09/` giữ làm lưu trữ.

Chưa kiểm: build/test sau dọn (chỉ sửa `.md`, không sửa code nên không dựng lại);
nội dung từng tài liệu `docs/*2026.md` chưa rà từng dòng, chỉ sửa chỗ đã chắc vênh
với mã.

Hiện trạng 2026-10-06 (của riêng phần chọn backend): máy có Vulkan 1.3 vẫn chọn Vulkan. Không có thì Android rơi xuống GLES
(đã chạy trên PowerVR Rogue GE8320, log `gles trên PowerVR Rogue GE8320`). iOS không có GLES
(Apple đã gỡ); mã iOS đi MoltenVK và chưa build vì máy này không có macOS. APK
`build/android-arm64/thienlong.apk` đóng cảnh `Config/startup.id` (251, huoyangu) và gói `.f2s`
của bản PC, không đóng cả cây data.

Việc nhiều phiên. Đích: `CLIENT\bin\thienlong_client.exe --scene huoyangu` mở cửa sổ và vẽ 57
StaticEntity bằng Vulkan đúng phép đặt gốc, có camera bay; `--shot <tệp.png>` vẽ một khung ra PNG;
`--dump-bounds <tệp.tsv>` ghi hộp bao thế giới của từng vật thể. Sáu bước con làm đúng thứ tự, bước
sau chỉ bắt đầu khi bước trước đạt mọi tiêu chí.

## Giật khi di chuyển, nhịp khung, nhảy (2026-10-14)

Chủ dự án báo: cây cối, trời đất nhảy loạn mỗi khi nhân vật đi, minimap giật, bảng đo báo TRƯỢT ở 60 FPS, animation
nhảy sai. Đã sửa:

- Bộ đệm GPU theo ảnh swapchain bị CPU ghi đè lúc GPU còn đọc (bẫy ở `docs/BAY-DA-BIET.md`): `gpu::Timeline` của khung
  và `Display::State::wait_slot` ở `frame.cpp`. Đo `--scene-id 2 --walk`: trước 893/893 khung ghi vào bộ đệm còn dùng;
  sau 871 khung, trung vị 16,7 ms, p95 17,4 ms, lớn nhất 33,5 ms, 0 lỗi lớp kiểm Vulkan.
- Ngân sách của bảng đo khi trình Fifo là một nhịp quét (`frame_budget_ms`); màn của máy đặt 60 Hz (hỗ trợ tới 200 Hz).
- Vòng cửa sổ nghỉ 1 ms thay 8 ms (`kInputPause` ở `viewer_win32.cpp`): chuột không còn tới thành chùm 8 ms, gần
  `CInputSystem::MouseTick` của gốc đọc mỗi khung.
- Bảng đo luôn hiện, bỏ F3 và `--pace`/`--no-pace` (chủ dự án: "cấm tắt"). Thêm `--walk` để đo lúc di chuyển.
- Nhảy: clip `跑跳a`/`跑跳b` của ActionSet (hành động 9, 12) vào `anim_sets.tsv` của `dev` và `release` (28 dòng mỗi
  bảng; `export_look.py` nay xuất hai hành động này), `avatar.files.tsv` thêm bốn GLB. `Gait::jump`/`land` theo
  `CObject_Character::Jump`, `NotifyPhyEvent`, `FreshAnimation` của ref, đối chiếu Game.exe 2026 bằng Ghidra
  (`0x1405ea2b0` Jump, `0x1405e2740` ChangeAction: phát một lần, tốc độ 1; `0x1405c5440` Tick).

- Nhịp khung theo lúc ảnh lên màn (cùng ngày, chủ dự án: "cực mượt", "sự ổn định ngay lập tức khi vào game"):
  `gpu::Swapchain::wait_shown` (Vulkan `VK_KHR_present_id` + `VK_KHR_present_wait`, GPU máy này có cả hai). Trình Fifo
  thì `Display::State::await_shown` chờ khung trước nữa lên màn rồi mới bắt đầu khung mới; mốc `frame_time` đó dùng cho
  mô phỏng, hoạt ảnh, HUD và bảng đo. Trước: chu kỳ khung 16,7 ms nhưng p95 18–19 ms, bước chân p5–p95 0–7,2 cm;
  sau (`--scene-id 2 --walk`, sau khi cảnh hiện): 871 khung, p95 16,8 ms, lớn nhất 17,0 ms, bước chân 6,95–7,05 cm.
  Bề mặt không báo được (D3D, GLES, driver thiếu phần mở rộng) thì giữ đo bằng đồng hồ CPU như cũ.
- CPU của khung: hiệu ứng hạt 2,19 → 0,59 ms/khung (3500 quad, 124 lô): tra ảnh theo con trỏ `Paint` thay vì dựng chuỗi
  khoá mỗi lô, `reserve` đỉnh, tái dùng bộ đệm khung, dò `SequenceFrame` một lần mỗi hệ, `axes_of` chỉ tính hướng cho kiểu
  billboard cần nó, nạp trước ảnh hiệu ứng lúc `adopt`. Tổng CPU mỗi khung trên cảnh Đại Lý khoảng 1,3 ms.
- Mũi tên minimap rung khi chạy: radar 119 px (MiniMap của 2026) có tâm ở nửa điểm ảnh; vị trí mũi tên suy lại từ u0
  (sai số số thực 86,49994 rồi 86,50003) nên phép làm tròn lật 1 px qua lại mỗi khung. Nay `Radar::is_centred_u/v` và
  `radar_mark` đặt thẳng vào tâm ô khi vùng thấy canh giữa người chơi. Test hồi quy `radar_arrow_steady` (đỏ trước sửa).
- Khung chậm còn lại: vài khung ngay lúc mở cảnh (khung #3–#7, 22–48 ms) trước khi cảnh hiện; "GPU còn 0 khung" nên chặn
  nằm ở phía trình bày của Windows lúc cửa sổ mới hiện. Tần số quét Windows đang đặt 60 Hz (màn hỗ trợ tới 200 Hz): client
  khoá theo nhịp quét của màn nên 60 FPS là trần của cài đặt hiện tại; đặt 120 Hz trở lên thì client chạy theo.

Chưa kiểm: nhìn tận mắt khi chạy và nhảy (agent không được điều khiển chuột, phím của máy); `PresentClock` (thời gian
khung lượng tử theo nhịp quét) chưa làm: sau một nhịp quét bị lỡ, bước chân của hai khung kế không đều.

## Vũ khí, hiệu ứng đồ, đòn đánh, tuyệt chiêu (2026-10-14)

Chủ dự án giao ("làm chuẩn tuyệt đối theo pipe") và dặn "đọc source gốc để hiểu trước, rồi phân tích mã máy và khớp nối". Thứ tự
pipe: `collect_map` -> `export_skills` -> `export_weapons` -> `collect_avatar` -> `collect_fx` (đọc cả `weapon_effects.tsv`) -> client.

- Dữ liệu: `export_weapons.py` (vũ khí bảy khe, mẫu, locator, `weapon_effects.tsv` 1319 hình, `gems.tsv` 1195 đá),
  `export_skills.py` (năm bảng đòn đánh); có `test_export_weapons.py` (14 ca xanh).
- Logic: `look/weapon` (`gem_effect`), `look/skill` (`strikes_of`), `avatar/locator` + `Avatar::effect_pose`, `avatar/gait`
  (`Stance::kStrike`, khoá lệnh tới `BreakTime`), `place/fx` (hiệu ứng theo dõi: `Spawn::is_tracked`, `Cast::move`,
  `release`, `is_live`; `Field::set_timed`, `stop`, `is_spent`, `set_tint`), `display` (`PlayerActor::gear_effects`,
  `follows`; `Display::State::sync_gear`, `sync_follows`).
- Công cụ thử (client gốc không có): `--weapon <item>`, `--gem <đá quý>`, `--skill <skill>`, `--auto-strike <khung>` (phím 1 tới
  9 dùng skill ở ô n). `--shot` chụp ở khung đầu sau khi bảng đo đủ 30 mẫu, không theo `--frames`: dùng `--auto-strike` để chụp
  đòn. Ví dụ: `thienlong_client --scene-id 2 --weapon 10100002 --gem 50902003 --frames 60 --shot x.png` (lửa bám lưỡi đao,
  cũng bám khi chạy `--walk` và khi đánh `--skill 358 --auto-strike 22`).
- Đã chạy: `fx_tests` (cộng 6 ca vòng đời), `look_tests` (cộng 3 ca đá quý), `avatar_tests`, `test_export_weapons.py`; ảnh chụp
  thật có lửa, độc bám vũ khí. `check.py` xanh ở các tệp mới đổi (xem NGHI-NGO mục 51 cho những lỗi tidy cũ còn trên dòng không
  đụng tới: `place/fx/{field,billboard,system}.cpp`, `display/graphic/*`).
- Chưa làm: danh sách đầy đủ ở `docs/NGHI-NGO.md` mục 51.

## Shader chuyển sang Slang (2026-10-13)

Nguồn shader của render là `src/client/render/shaders/*.slang` (cú pháp HLSL chạy nguyên văn). Slang dịch ra
SPIR-V, DXIL, DXBC trong tiến trình (`engine/shader/detail/slang.cpp`); `d3dcompiler` và `dxbc.*` đã bỏ. DXC chỉ đọc
phản chiếu DXIL. `reconcile.cpp` đối chiếu phản chiếu SPIR-V với DXIL của cùng nguồn mỗi lần dịch: bố cục lệch thì
lỗi lúc dựng gói, semantic lấy từ DXIL, tên sạch lấy từ SPIR-V. Khoá cache của gói có `kPipeline` (`compiler.cpp`).

Đã đo: băm phản chiếu 7 gói × 4 đích bằng bản DXC cũ; ảnh chụp Vulkan `--scene-id 2 --bare` giống bản cũ từng điểm
ảnh; `--scene-id 2` và `--login` lệch ít hơn nhiễu giữa hai lượt chạy cùng một bản. Còn mở ở `docs/NGHI-NGO.md` mục 50
(D3D12/D3D11 thật, cỡ DXIL, sinh GLSL của GLES từ Slang). Lệnh kiểm:
`thienlong_shader build src/client/render/shaders/shaders.list --out <thư mục> --target spirv,dxil,dxbc,glsl`
rồi `thienlong_shader show <gói>.f2s` so băm `phản chiếu` giữa các đích (phải bằng nhau).

## Lưới đi của Đại Lý và Lạc Dương (2026-10-13)

`dev/client/assets/Scene` của `dali_new_320` và `luoyang_new` thiếu `.path` và `.WCollision` dù kho gốc có đủ: công cụ
`collect_map.py` bản cũ không gom hai tệp ấy, nên client in "cảnh không có tệp .path" và nhân vật đi xuyên vật cản.
Đã thêm `collect_walk` (có `TOOLS/content/test_collect_map.py`, 5 ca xanh) và gom lại cả hai map. Đã chạy
`thienlong_client --scene-id <id> --frames 3` thoát 0: Đại Lý "Lưới đi: 11669 đỉnh, 23324 tam giác, 11665 cạnh vật cản",
Lạc Dương "10546 đỉnh, 21080 tam giác, 10543 cạnh vật cản". Chưa kiểm: nhân vật bị chặn thật trong tay người chơi
(công cụ bấm chuột bị cấm). Có `.WCollision` thì `surface_y` nâng chân nhân vật lên mặt cầu, bậc thang của hai map
(`docs/VA-CHAM-2026.md`); trước đó hai map không có tệp nên chân luôn ở địa hình. Chưa nhìn thử tay.

## Đăng ký, đăng nhập, nhân vật (2026-10-12)

PostgreSQL 18.6 trong `SERVER/pgsql`, libpq 18.4. Schema `SERVER/sql/auth` và `SERVER/sql/game`:
tài khoản Argon2id, vé một lần (SHA-256, không lưu vé thô), nhân vật tách cột và bảng con
(`player_skill`, `player_life_skill`, `player_recipe`, `player_setting`, `item`) với id `bigint`.
`thienlong_auth` và `thienlong_store` nghe ipc `7011` và `7010` khi có `secrets.local.toml`; không
có tệp đó thì vẫn in `ready` để cụm thử khởi động. Gate chuyển CreateAccount, SignIn, Login,
CreateCharacter, DeleteCharacter, EnterGame. Trần nhân vật đang sống là 3, khớp màn chọn của client
2026. Chưa có IPC tổng quát, chưa có zone, chưa nạp vật phẩm tân thủ.

Đã chạy: `account_tests` thoát 0; vòng thật trên PostgreSQL tạo tài khoản, từ chối trùng tên và sai
mật khẩu, đổi vé một lần, tạo nhân vật `Lý Mộ`, từ chối trùng tên, vào game, xoá. Lệnh:
`py -B TOOLS/server/setup_db.py start` rồi `thienlong_auth` và `thienlong_store --config SERVER/config`.

## Đã xong

- **B1 — cửa sổ** (2026-10-05). Cửa sổ mở, đổi cỡ, đóng sạch, mã thoát 0. Chép 21 tệp từ Forge2
  (`docs/NGUON-FORGE2.md`): phần lỗi, đổi mã, log, luồng của `core` và trọn module `window` bản
  Win32. Client có module `client` (tuỳ chọn dòng lệnh có test, vòng lặp cửa sổ) và tuỳ chọn
  `--frames <n>` để chạy tự động.

## Phiên 2026-10-06: camera, điều khiển và người chơi

Đã làm và đã đo (số thật ở `docs/NGUON-TLBB.md` và các test):

- Giật hình: map nhỏ huoyangu đứng ở 60 fps trên PC (Vulkan) và máy tính bảng PowerVR GE8320 (GLES,
  median 16,7 ms, 0 khung quá 20 ms). Nguyên nhân gốc trên máy tính bảng là ghi UBO từng lệnh vẽ (đã
  đổi sang uniform), sRGB của bề mặt EGL và tên tệp phân biệt hoa thường (186 trong 219 cảnh).
- Camera là bản của TLBB Dev, không còn camera nào khác (camera Cool3D và camera tự đi bộ đã bỏ):
  `control/follow_camera`, `control/player_input`, `control/ground` (va chạm của mắt), `render/camera`
  (`look_camera`, `orbit_camera`). Không còn tự quay khi chưa ai chạm; máy cảm ứng bắt đầu ở zoom
  0,45 như `kStartZoom` của Dev. (Thay ngày 2026-10-08 bằng bản port từ mã máy của client 2026,
  xem mục "Camera và chuột theo mã máy của client 2026".) PC: kéo chuột phải xoay (con trỏ ẩn, nhả thì về chỗ cũ), lăn chuột
  và mũi tên lên xuống zoom, mũi tên trái phải xoay, V đặt lại, nhấp trái đi tới điểm đất dưới con
  trỏ, giữ trái quá 1 giây thì chạy theo con trỏ, W A S D đi. Máy cảm ứng: `control/touch` (một ngón
  như chuột trái, kéo nhanh để xoay, hai ngón xoay và chụm mở để zoom) và cần gạt ảo ở góc trái
  dưới (`control/stick`). Đã chạy thật trên PC (kéo, lăn, phím, nhấp, giữ, V) và trên máy tính bảng
  (kéo, chạm, giữ, cần gạt) với 59,7 fps; 26 test xanh trên msvc-release và clang-asan, 21 trên
  máy tính bảng.
- Người chơi có xương: xuất bảng ngoại hình từ Config (`export_look.py`), port `ogre`, `anim`,
  `look`, `avatar` từ TLBB kèm test (khung vàng OGRE khớp trong 1e-5), cầu nối GLB sang xương
  (`resource/rig`), vẽ bằng `Instance::joints`. Đã thấy đúng dáng đứng và dáng chạy trên PC và máy
  tính bảng. 26 test xanh trên msvc-release và clang-asan, 21 trên máy tính bảng.

Chưa làm: NPC (dữ liệu ở `Config/MissionNPC_HashTable.txt`, `MonsterAttrExTable.txt`,
`CharModelEx.txt`; mesh dính `BaseWhite` cần chất liệu theo `all.obj`), con trỏ chuột (hình con trỏ
của client), bảng chỉ số trên màn hình, WalkMap, vũ khí, tải map lớn nhanh và mượt trên máy tính bảng (map `shuhe`
~6 fps: bộ nhớ ảnh RGBA8, không cắt khuất), địa hình còn là một ảnh nướng sẵn (mờ, giãn ở dốc).

## Khung chơi trên PC theo client 2026 (2026-10-06)

Chuẩn lấy từ client 2026 cài ở `F:\tl 2026`, không lấy từ mã 2008 ở `G:\TLBB\_ref` (hai bản đã khác
nhau, ví dụ 2026 đổi tên `notifyScreenResolution` thành `notifyDisplaySizeChanged`). Số đo:

- `Bin/System.cfg`: `View_Resoution = 1280,720`, `View_FullScreen = 0`, `Camera_FOV = 35` (góc dọc,
  trùng `Lens` của dự án).
- `Bin64/Game.exe`, đọc mã máy bằng pefile và capstone: hàm tạo cửa sổ dùng hằng 0x500 x 0x2d0
  (1280 x 720) và kiểu `0xCA0000` (WS_CAPTION, WS_SYSMENU, WS_MINIMIZEBOX) cho cả `AdjustWindowRect`
  lẫn `CreateWindowExA` (RVA 0x624e6c): không viền kéo, không nút phóng to, nên người chơi không kéo
  méo tỉ lệ được. Hàm đặt độ phân giải (quanh RVA 0x642600) nâng cỡ cửa sổ ngoài lên tối thiểu
  0x320 x 0x258 (800 x 600) rồi canh giữa vùng làm việc.
- Bản của dự án: `viewer_win32.cpp` tạo cửa sổ không cho đổi cỡ bằng chuột (đo trên tiến trình thật:
  kiểu `0x14CA0000`, phần cờ đúng `0x00CA0000`, không THICKFRAME, không MAXIMIZEBOX), vùng chơi
  1280 x 720, hoặc `--size <rộng>x<cao>` (cũng nhận `1280,720`; từ 800 x 600 tới 16384; 1024 x 768
  đo ra đúng 1024 x 768). Kiểu cỡ nằm ở `client/viewer/client_size.hpp`; `client_tests` thêm 2 ca đọc
  đúng và 12 dòng cỡ sai bị từ chối (đã thử đột biến biên 800: ca đỏ đúng chỗ).
- Chưa làm: toàn màn hình theo `View_FullScreen`, danh sách độ phân giải trong cài đặt, phóng to
  (`View_MaxWindow`: mã 2026 ghi biến này khi cửa sổ phóng to hoặc khôi phục, suy từ mã máy, chưa
  xác nhận bằng chạy).

## Ô cửa sổ HUD đối chiếu client 2026 (2026-10-06)

- Chuẩn là mã máy `Bin64/CEGUIBase.dll` của client 2026 (tháo bằng pefile + capstone, không chạy
  client): `UDim::asAbsolute` 0x1c1d0, `setWindowArea_impl` 0xa7e10, `windowToScreen` 0xa9090,
  `getUnclippedPixelRect` 0xa2000, `onParentSized` 0xa44f0, `GUISheet::initialise` 0x8a840, các hàm
  `set` của `WindowProperties` (tìm qua RTTI) và trình nạp layout. Khớp mã 2008 ở làm tròn
  `(int)(x + 0,5)`, UDim, căn lề, ZoomMode mặc định 2, mẫu `sscanf`, thứ tự áp Property.
- Ba chỗ bản 2026 khác mã 2008: (a) không kẹp cỡ theo Min/MaxSize; (b) `Size`, `AbsoluteSize`,
  `Width`, `Height` và bản Absolute bỏ qua giá trị âm; (c) `setSize` bỏ qua lời gọi lặp cùng giá trị
  (ô nhớ 0x2e0, `onSized` xoá). Thêm ZoomMode 3 và 4 mà layout gốc không dùng.
- `TOOLS/content/ui_rects.py` là bản tính thứ hai, độc lập với `SRC/gui` (mô phỏng từng lời gọi,
  float32), đã chỉnh theo ba chỗ trên; tự kiểm 38 ca. Nó sinh `tests/golden/ui_rects.tsv`: 942 cửa
  sổ của 21 layout HUD ở 1024x768, 1280x720, 1920x1080, 2560x1600 (3.768 dòng).
- `gui_real_tests` thêm ca `window_boxes_match_golden`. Lần đầu đỏ 864 ô: `layout.cpp` thiếu
  `UnifiedXPosition` và `UnifiedYPosition` (cửa sổ gốc của FunctionBarRight, FunctionBarRight_2,
  MissionTrack, PartyFrame, PetFrame nằm sai chỗ). Đã thêm các thuộc tính đó, căn lề, `Relative*`,
  cỡ mặc định `{1,1}` của `DefaultWindow` và luật bỏ cỡ âm; nay 3.768/3.768 ô khớp. Bảy đột biến
  của `layout.cpp` đều bị ca đơn vị hoặc golden bắt.
- `TOOLS/content/verify_ui.py` so dữ liệu đã gom với `_raw` (tệp, cây XML, từng điểm ảnh PNG, bao
  đóng, ba bảng). Nó lộ hai lỗi của `collect_ui.py` đã sửa: `ui.files.tsv` thiếu 5 tệp phông (nay
  `collect_ui.py` gọi `ui_font.py` trong cùng lượt ghi) và `ui_strings.tsv` thiếu 13 khoá của look
  chưa cửa sổ nào dùng. Nay 7/8 mục qua.
- Bốn bộ test `gui_*` chạy sạch dưới Clang `-fsanitize=address,undefined`. Lần chạy đầu ASan bắt
  một lỗi của test cũ `pressed_button` (giữ con trỏ vào `Sheet` tạm đã huỷ); đã sửa trong test.
- HUD đã chạy trên tablet thật (Lenovo TB-X306F, 1280x800, GLES trên PowerVR Rogue GE8320): APK
  đóng thêm 126 tệp `Interface` theo `ui.files.tsv` và hai gói `ui.*.f2s`; bốn bảng mặc định hiện
  đúng chỗ như bản PC. APK này dựng từ một worktree tạm của commit 4e99315 cộng phần HUD, chưa phải
  từ cây chính. iOS chưa build được vì máy không có macOS.
- Chưa làm: mục 4b của `verify_ui.py` còn đỏ — 51 hoạt ảnh trong `Schema/wowanimate.xml` (kéo theo 8
  texture) và ảnh `Common/MeshBack.dds` của MeshWindow chưa gom, vì `SRC/gui` chưa vẽ `Animate` và
  MeshWindow. `Hub::box` trả cỡ điểm ảnh của cửa sổ; bản gốc vẽ theo cỡ đã làm tròn lần hai, chỉ
  khác khi offset cỡ là số lẻ (HUD không có ca nào). Layout ngoài 21 layout HUD chưa có golden.

## Audit hằng, trùng lặp và nguồn sự thật (2026-10-06)

Quét cả kho (364 tệp nguồn, 88 nghìn dòng) bằng script regex và clang-tidy `readability-magic-numbers`
trên AST. Mã do dự án sở hữu gần như sạch: 62 magic number, phần lớn là mặt nạ bit và số của bản
port. Mutable global chỉ có 4 chỗ có NOLINT (jobs, window), đều của hạ tầng chép từ Forge2.

Đã sửa (mỗi nhóm build MSVC `-WX` và chạy 32 test trong một bản sao riêng của cây chính):

- `gui`: bảng tên enum Falagard (căn ảnh, căn chữ) từng chép ở `loader_look.cpp`, `paint.cpp`,
  `text.cpp` nay chỉ còn ở `gui/detail/names.hpp`, kèm `static_assert` khớp số phần tử enum. Màu
  trắng mặc định (5 chỗ) thành `kWhiteArgb`, độ phân giải gốc 640x480 của Imageset (2 chỗ) thành
  `kNativeWidth`, `kNativeHeight` ở `asset.hpp`.
- `core::parse_whole_int` (`core/number.hpp`) thay ba bản chép "số nguyên không âm chiếm trọn chuỗi"
  ở `client/map/book.cpp`, `client/options.cpp`, `client/world/world.cpp`; có test riêng.
- `render/detail/shaders.hpp`: cặp shader của pipeline, phép trộn alpha và thư mục gói shader mặc
  định, trước đây chép nguyên ở `forward.cpp` và `ui.cpp`. Nhân tiện `forward.cpp` hết 90 lỗi
  clang-tidy có sẵn (73 lỗi include thiếu).
- Sửa lỗi (không phải refactor): commit 97a7398 xoá hai dòng `ui.vs`, `ui.ps` khỏi
  `render/shaders/shaders.list`, nên build sạch không sinh gói shader giao diện và HUD tắt lặng lẽ.
  Đã khôi phục; CMake nay dừng cấu hình khi một gói render cần không có dòng trong tệp đó.
- Sửa lỗi build: `client/stage/sky.hpp` dùng `std::uint32_t` mà thiếu `<cstdint>`, nên preset
  `gcc-debug` vỡ ở HEAD (MSVC và Clang có sẵn qua header khác). Đã thêm include.

Lượt hai cùng ngày (cũng build và test trong bản sao; backend gles là mã của dự án, không phải mã
chép Forge2 như lượt đầu ghi nhầm):

- `gpu/gles/probe.hpp`, `probe.cpp`: phần đọc năng lực của context và callback debug từng chép đôi
  ở `context_wgl.cpp` và `context_egl.cpp` (122 dòng) về một chỗ, nhận `GlFlavor` cho ba chỗ hai
  dòng API khác nhau. Ba ca test chạy trên driver giả, sáu đột biến đều bị bắt.
- `gpu/gles/programs.cpp` băm bằng `core::fnv1a` thay bản FNV-1a tự viết (cùng hằng, cùng giá trị).
- `gpu/gles/context_wgl.cpp` lấy `<windows.h>` qua `core/win32.hpp`, bỏ năm khai báo `wgl*` trùng
  `wingdi.h`.
- `gpu/gles/gl_api.hpp`: ghi lý do giữ tên hằng của Khronos (NOLINT), tệp qua cổng; 174 lỗi đặt
  tên không còn phủ lên mọi tệp gles.
- `client/map`: kiểu tệp `"standard"` của `.Terrain` (5 chỗ) thành `kStandardType` ở `terrain.hpp`.
- `client/stage/sky.cpp` qua cổng: (cột, hàng) của một đỉnh vòm gom vào `GridNode`. Ca test mới
  ghim lưới vòm; chạy xanh trên mã cũ, đột biến đảo cột và hàng bị bắt.
- `tests/gpu_tests.cpp`, `tests/map_tests.cpp` qua cổng.

Đã xét và giữ nguyên vì khác nghĩa dù cùng số hay cùng hình dạng: `Rgb` của `client/map` (màu tô theo
độ cao) và của `client/stage` (màu trong tệp cảnh); `Lens` của `control` và `render`; `kPi` cắt cụt
của `follow_camera.cpp` (số của bản gốc); hằng định dạng gói shader lặp trong `shader_tests.cpp`
(test tự khai lại định dạng là chủ ý); `write_atomic` ở bốn công cụ Python (bốn hợp đồng khác nhau:
kiểu đường dẫn, có bỏ qua khi nội dung trùng hay không, lỗi riêng `FontError`, bản chạy trong
Blender; hai bộ kiểm độc lập cố ý không dùng chung mã với bộ gom); `kFramePause` của
`viewer_win32.cpp` (8 ms) và `display_none.cpp` (16 ms) nay là hai giá trị khác nhau.

Chưa làm, chờ cây chính yên (tệp đang bị phiên khác sửa) hoặc cần chủ dự án quyết:

- Tên thư mục và tệp của cây dữ liệu (`Scene`, `Config/SceneDefineEx.txt`, `Model`, `Interface`,
  `Table`, `shaders`) viết thẳng ở `main.cpp`, `android_main.cpp`, `ios_main.mm`, `display_gpu.cpp`,
  `viewer_win32.cpp`, `hud.cpp`, `avatar.cpp`: cần một chủ cho từng tên (world, avatar, ui, render).
  Ba điểm vào còn chép cùng một chuỗi "đọc bảng cảnh, đọc `startup.id`, vào cảnh".
- Nhãn log Android `"THIENLONG"` ở 5 chỗ (`log_sink_posix.cpp`, `android_main.cpp`,
  `display_gpu.cpp`).
- Nợ cổng của backend gles (mã của dự án): 12 tệp chưa đúng clang-format, 9 tệp còn lồng quá một
  mức, clang-tidy còn đỏ chủ yếu vì include thiếu và hàm quá dài (`open_context`,
  `create_pipeline`). Đây là một đợt dọn riêng, nên làm sau khi phần vsync của gles ổn.
- 10 tệp mã chép (capture, gpu, resource, shader) lệch clang-format 3–20 dòng mỗi tệp sau commit
  97a7398; hai chỗ là chữ ký 101 cột (`run_at` của `deflate.cpp`, `add_row` của `upload.cpp`),
  cần chọn giữa luật chữ ký một dòng và luật không đặt alias để né cột.
- Số nên thành cấu hình lúc chạy như bản gốc đọc `System.cfg`: FOV 35 và hai mặt cắt (đang là mặc
  định của `CameraRules` và `render::Lens`), cỡ cửa sổ (đã có `--size`).

## Âm thanh: nguyên nhân rè, giật, lẫn tạp âm và bản sửa (2026-10-06)

Đo trước khi sửa (bản trộn ở luồng riêng vào vòng đệm 4096 khung, miniaudio đổi tần số):

- Tablet GE8320: thiết bị xin 4104 khung mỗi lần gọi, vòng đệm chỉ chứa 4096. Bộ đếm gắn tạm đếm
  được đúng 8 khung trống mỗi lần gọi, tức một tiếng tách mỗi 85 ms: đó là tiếng rè và giật.
  AudioFlinger báo 0 underrun vì khung trống là của ta, không phải của hệ điều hành.
- Mọi tệp client gốc là 22,05 hoặc 44,1 kHz, bộ trộn chạy 48 kHz, miniaudio đổi bằng nội suy tuyến
  tính: sin 10 kHz ở 44,1 kHz ra kèm thành phần lạ -21 dB (13,9 kHz) và -29 dB (6,1 kHz); tổng
  phần không phải sin -20 dB, ở 15 kHz là -11 dB. Đó là "lẫn tạp chất". Trên PC này thiết bị chạy
  44,1 kHz nên còn thêm một lượt đổi tuyến tính 48 về 44,1 kHz ở đầu ra.
- Dựng ngoại tuyến 60 giây nhạc đăng nhập: đỉnh 0,76, không chạm trần; khe lặng 64 ms ở điểm lặp là
  của chính bản nhạc (tắt dần rồi vào dần), không phải lỗi giải mã.

Đã sửa:

- `audio/resample`: sinc cửa sổ Kaiser đa pha, 96 hệ số, vị trí đọc bằng số nguyên. Hiệu ứng đổi một
  lần lúc nạp, nhạc đổi theo khối ở luồng giải mã, đầu ra đổi khi thiết bị không chạy 48 kHz.
  miniaudio giờ chỉ giải mã và mở thiết bị ở tần số riêng của chúng. Cùng phép đo: -90 dB ở mọi
  tần số thử (sàn của 16 bit), thành phần lạ lớn nhất -104 dB.
- Bộ trộn chạy ngay trong callback của thiết bị, chia khối 256 khung: thiết bị xin bao nhiêu khung
  cũng đủ, và bỏ được 85 ms trễ của vòng đệm cũ. Callback không cấp phát, không giải phóng, không
  giải mã: mẫu clip do luồng API giữ; nhạc giải mã ở luồng riêng (`audio/detail/music`, ba bàn,
  vòng đệm 0,68 giây mỗi bàn).
- `audio/limiter` thay việc cắt cụt ở +-1: hạ ngay, giữ 20 ms, nhả 150 ms; tín hiệu dưới trần đi qua
  nguyên vẹn từng bit. Hệ số âm lượng của tiếng và của nhạc đổi theo đường thẳng trong khối thay vì
  nhảy bậc. Con trỏ đọc của tiếng là `double`.
- Hai lỗi có sẵn lộ ra khi viết lại: tiếng lặp bị `stop` không bao giờ trả chỗ (giữ luôn clip), và
  mỗi lần phát lại một tiếng đã nạp vẫn đọc cả tệp từ đĩa rồi mới tra cache.
- `Engine::stats()` và `describe(Stats)`: số lần gọi, khối lớn nhất, khung nhạc bị hụt, đỉnh, mức
  ép. Ba điểm vào của client ghi dòng này khi đóng bộ âm thanh.

Đã kiểm: `audio_tests` 22 ca và `audio_dsp_tests` 12 ca (16 ca sau phần cooker bên dưới) qua trên
MSVC và Clang ASan + UBSan; `check.py` 0 lỗi trên 13 tệp nguồn và hai tệp test. PC (thiết bị 44,1 kHz): 1236 lần gọi, khối 441
khung, hụt 0 khung nhạc. Tablet: 3725 lần gọi, khối lớn nhất 960 khung, hụt 0 khung nhạc,
AudioFlinger 0 underrun. Tablet này không có đầu ra FAST trong audio policy (chỉ primary và
deep_buffer) nên độ trễ đầu ra khoảng 180 ms là của máy.

Cooker (cùng ngày), theo sơ đồ master, cook, rồi PCM hoặc Opus theo lớp:

- `thienlong_audio cook <cây sound gốc> <cây ra>` (`SRC/audiotool`, lõi ở `audio/cook`): mọi tệp ra
  ở 48 kHz nên lúc chạy không còn đổi tần số. Tệp không quá 0,4 giây thành PCM16; còn lại thành
  Opus, bitrate theo lớp (nhạc 144, ambience 112, lời thoại 48 đến 72, hiệu ứng 64 đến 96
  kbit/s). Chạy song song, chạy lại chỉ cook tệp đổi. Định dạng `.tla` ghi ở
  `docs/DINH-DANG-TLA.md`: bảng gói Opus riêng, lúc chạy chỉ cần libopus, không cần Ogg.
- Cây sound của client: 2259 tệp, 1204,6 MB thành 470,4 MB trong 28,8 giây, 0 lỗi.
- Lúc chạy: bộ âm thanh thử tệp `.tla` cùng tên trước tệp gốc; nhạc cook phát luồng qua cùng bàn
  nhạc, hiệu ứng cook giải mã một lần lúc nạp. Bản build không có libopus (preset GCC) vẫn đọc tệp
  gốc và tải PCM.
- `opus` 1.6.1 vào manifest vcpkg, đã cài cho `x64-windows-static-md` và `arm64-android`. Preset có
  sanitizer dùng bản Release của `opus.lib` (bản Debug kéo CRT debug).
- APK: target `cook_sound` của preset PC cook ra `build/cooked/sound`; có cây đó thì
  `package_apk.py --sound` đóng nó thay cho `CLIENT/data/sound`. APK 1322 MB còn 590 MB. Dấu giải nén
  trên thiết bị tăng lên `da-giai-nen-6`.
- Đã kiểm: nhạc đăng nhập dựng từ bản cook khớp bản gốc tới từng khung (lệch 0 khung, cùng RMS);
  tablet phát bản cook 40 giây, hụt 0 khung nhạc, AudioFlinger 0 underrun. Sin thuần qua Opus 160
  kbit/s còn phần lạ -44 dB (96 kbit/s: -38 dB): đó là mức của bộ mã mất mát, không phải của ta.

Chưa làm:

- Nạp hiệu ứng còn đồng bộ trên luồng game (đọc tệp, giải mã, đổi tần số); thu hồi clip còn chờ bộ
  trộn tới 200 ms; Doppler vẫn nội suy tuyến tính. Xem `docs/NGHI-NGO.md` mục 14.
- Nguồn của cooker vẫn là MP3 và WAV đã nén của client gốc: muốn trong hơn nữa thì cần master
  không nén (WAV, FLAC) cho từng bài.
- Client PC vẫn đọc tệp gốc trong `CLIENT/data`; muốn chạy bản cook trên PC thì trỏ `--data` vào
  một cây có `sound/` đã cook. Chưa gom `.tla` thành ngân hàng theo cảnh.
- iOS chưa build được trên máy này (chưa cài `opus` cho triplet iOS).

## Giao diện HUD: chữ, minimap, lớp vẽ, bản dịch (2026-10-06)

Phân loại theo submodule (bảng tầng ở `cmake/GameLayers.cmake`):

- `gui`: bộ widget đọc thẳng XML gốc (đã có). Thêm số lớp trên quad và dòng chữ, thứ tự vẽ của
  các gốc theo thứ tự kê, tên phông trên dòng chữ, đường dẫn ô ảnh minimap, bảng dịch nạp đè.
- `ui/panel` (mới, thuần logic, không GPU): thay script Lua của từng cửa sổ. `Deck` gom các lời
  Show, Hide, SetText, SetProperty, SetProgress của một khung; `start` là trạng thái lúc vào game
  theo `OnLoad` của các script đọc được ở `G:\TLBB\_content\source\Interface`.
- `ui` (GPU): `text` (thẻ # của `UIString.cpp`, bẻ dòng, canh, cắt, viền), `radar` (atlas
  minimap), `painter` (vẽ theo lớp), `hud` (ghép lại).
- Chưa có: kho trạng thái nhân vật (máu, đồ, kỹ năng). Dự kiến là module riêng không GPU, để
  `ui/panel` đọc và sau này lớp mạng ghi vào.

Đã làm và đã chạy:

- Chữ: phông bitmap `VTNAM14` của scheme bản tiếng Việt. Thẻ đọc đúng độ dài như bản gốc; `#b`,
  `#u`, liên kết, biểu cảm và `#{_ITEM/_TIME/_MONEY}` đọc rồi bỏ, chưa vẽ.
- Minimap: ô ảnh `Scene/jpg_<token>_<cột>_<hàng>` (256 điểm ảnh, 64 đơn vị cảnh) do
  `collect_map.py` đổi sang PNG. Chỉ giữ một atlas 2x2 ô quanh người chơi (1 MB cố định) thay vì
  ghép cả cảnh như bản port TLBB Dev (cảnh 1024 đơn vị ở đó tốn 64 MB). `UiPass::replace_texture`
  thay ảnh khi người chơi sang vùng ô khác. Token là cột thứ 11 của bảng cảnh.
- Lớp vẽ: ảnh tĩnh, ảnh động rồi chữ của một cửa sổ gốc vẽ xong mới tới gốc kế, để bảng mở sau
  đè trọn lên bảng dưới (trước đây mọi chữ nằm trên mọi ảnh).
- HUD nhận chuột (nút dưới chuột đổi trạng thái) và giữ lại cú bấm rơi trên nó, không cho xuống
  thế giới.
- Bản dịch: `TOOLS/content/lang/ui_strings.vi.tsv` (132 khoá của 21 layout đã gom và 3 chuỗi viết
  thẳng), `collect_ui.py` chép thành `Table/ui_strings.vi.tsv` và báo khoá chưa dịch; client nạp
  đè lên bảng gốc. Chữ nằm trong ảnh nút chưa dịch (theo yêu cầu, làm sau). (Từ ngày 2026-10-08
  nguồn là `assets/i18n/vi.tsv`, bảng triển khai là `Table/*.lang.tsv`: mục "Thủ tục đăng nhập,
  phần 1".)

Đã kiểm: cổng `check.py` 0 lỗi trên 30 tệp; MSVC build 0 cảnh báo, 36/37 test (ca `layers` đỏ vì
`fx_view.cpp` của phiên khác); client PC chạy 200 khung, lớp kiểm tra GPU 0 lỗi, khung 8,3 ms.
Tablet (Lenovo TB-X306F, GLES trên PowerVR GE8320, APK 620,7 MB dựng từ bản sao): HUD hiện đủ
chữ tiếng Việt, minimap và nút như bản PC, 59,8 khung/giây, chạy 30 giây không lỗi trong logcat,
189 MB PSS. iOS chưa build được (máy không có macOS); bundle
iOS dùng cùng danh sách tệp với APK (`package_apk.py --stage`) nên sẽ nhận ô ảnh minimap và bảng
dịch, nhưng điều đó chưa được chạy.

Chưa làm, theo thứ tự dự kiến:

1. (Xong ở lát 2, mục kế.) Kho trạng thái nhân vật và nhân vật mẫu; điền khung nhân vật (tên,
   cấp, máu, khí, nộ, chân dung 2D), toạ độ và tên cảnh ở minimap, thanh kinh nghiệm.
2. Bấm nút mở và đóng bảng (nhân vật, kỹ năng, thùng đồ, nhiệm vụ), kéo bảng, phím tắt. (Mở và
   đóng ba bảng nhân vật, hành trang, nhiệm vụ: xong ngày 2026-10-08, mục "Giao diện: ba bảng mở
   từ thanh menu chính". Còn lại: sách kỹ năng, kéo bảng, phím tắt, nội dung từng bảng.)
3. Ô kỹ năng và ô vật phẩm (`Falagard/ActionButton`, 182 ô trong các layout đã xét): icon, hồi
   chiêu, số lượng, kéo thả.
4. Widget chưa vẽ: `Animate`, `AnimateImage`, `StopWatch`, `Money`, `Star`, `MapImage`,
   `DragTitle`, `SuperTooltip`, `ChatHistory`, `ListBoxEx`, `Combobox`, `MeshWindow` (đầu 3D).
5. Phông FreeType của scheme (tahoma.ttf, 7 cửa sổ dùng) hiện vẽ bằng phông bitmap mặc định.

## Giao diện HUD: nhân vật, khung nhân vật, minimap sống (2026-10-06, lát 2)

Thêm vào bảng submodule:

- `hero` (mới, thuần giá trị, chỉ cần `core`): trạng thái nhân vật mà giao diện hiển thị (tên, cấp,
  máu, khí, nộ, kinh nghiệm, điểm liên kích, chân dung). `newcomer()` là nhân vật vừa tạo theo
  `DefaultChar.ini` và `BaseValueTable.ini` của máy chủ gốc (585 máu, 310 khí, nộ 0/1000, kinh
  nghiệm 0/90). Phần mạng sau này ghi vào đây; `client/display` giữ một bản và đưa cho HUD.
- `ui/panel`: thêm `player_frame` (PlayerFrame_Update của script gốc), `minimap` (tên cảnh, toạ độ,
  canh giờ), `menubar` (thanh kinh nghiệm), `portraits` (bảng chân dung). `Deck::compose` cho chuỗi
  dựng lúc chạy ghi thẳng vào bộ đệm của khung trước (không cấp phát mỗi khung).
- `gui`: bảng hoạt ảnh của AnimateManager (`GuiAnimate`, nạp từ `Schema/wowanimate.xml` đã lọc);
  radar vẽ mũi tên người chơi theo hướng mặt (`arrow_frame`, công thức của
  `FalagardRadar::updateMyselfDir`), cắt theo ô radar; `Falagard/MapImage`; Hub tự trượt thanh như
  `FalagardSuperProgress` theo `Place::clock` và `MoveSpeed` của cửa sổ.

Dữ liệu và công cụ:

- `collect_ui.py` ghi thêm `Interface/Schema/wowanimate.xml` (51/2001 hoạt ảnh mà 21 layout đã gom
  dùng, kèm texture của chúng), `Table/portraits.tsv` (150 chân dung của `CharacterFace.txt`) và
  `Table/scene_names.vi.tsv` (241 tên cảnh tiếng Việt, nguồn `TOOLS/content/lang/`); in tên cảnh
  chưa dịch. `verify_ui.py` biết ba tệp này (tệp hoạt ảnh so theo kiểu bản lọc).
- Tên cảnh, tên nhân vật mẫu ("Thiếu Hiệp") và mọi chữ mới đều là tiếng Việt.

Đã kiểm:

- Cổng `check.py` 0 lỗi trên 33 tệp. MSVC (bản sao): build 0 cảnh báo, 37/38 test, ca `layers` đỏ
  vì `fx_view.cpp` của phiên khác. Test mới viết sau mã nên kiểm bằng đột biến: 8/8 đột biến bị
  bắt (thanh trượt, hướng mũi tên, cắt mũi tên, MapImage, khung hoạt ảnh thiếu ảnh, ngưỡng máu
  thấp, chấm canh giờ, id chân dung lặp).
- Client PC: 240 khung với lớp kiểm tra GPU, 0 lỗi, khung 8,3 ms. Chạy tay có nhấp chuột: thanh
  nộ và kinh nghiệm rút về 0 sau một giây, toạ độ đổi theo bước đi, mũi tên quay đúng hướng đi
  (đi về +x mũi tên chỉ phải, về -z chỉ lên).
- Tablet (APK 624,7 MB dựng từ bản sao, GLES trên GE8320): HUD giống bản PC; 125 khung liên tiếp
  cách nhau 16,32–17,12 ms (trung vị 16,70), 0 khung trễ; 178,9 MB PSS; logcat không có lỗi.
- `verify_ui.py`: mục XML, texture, bao đóng, hai bảng đạt; còn đỏ mục 1 và 5a (tệp
  `Interface/cursor` của phiên khác chưa vào danh sách) và 4b (`Common/MeshBack.dds`, NGHI-NGO 23).
- Clang ASan + UBSan (bản sao): 37/38, đỏ `layers`. Lượt đầu ASan bắt một con trỏ treo trong ca
  `text_font` của lát trước (giữ con trỏ vào `Sheet` tạm); đã sửa ca test, mã chạy không đổi.
  GCC 16 (bản sao): 29/31, đỏ `layers` và `log_tests` thoát 0xC0000374 (NGHI-NGO 12, có từ trước).
- Chưa kiểm: iOS (máy không có macOS).

Chỗ lệch và chỗ suy đoán ghi ở `docs/NGHI-NGO.md` mục 18–23. Còn lại của giao diện: chân dung là
ảnh phẳng 2D, bản 2026 vẽ đầu 3D có mặt nạ `HeadRoundRegion` (đang tháo mã 2026); các mục 2–5 của
danh sách ở lát trước (bấm nút mở bảng, ô kỹ năng, widget còn thiếu, phông FreeType) chưa làm.

## Mặt nạ ô chân dung của client 2026 (tháo mã 2026-10-06)

Ô chân dung "tròn méo" của bản 2026 không phải quạt `LookLikeRound` của mã 2008. Đọc tĩnh mã máy
x64 ở `F:\tl 2026\Bin64` (không chạy client); ĐO là đọc trực tiếp, SUY là suy ra.

- Cửa sổ `PlayerFrame_Head_Parent` (`Falagard/MeshWindow/ParentWindow`, 80x80) là lớp
  `FalagardMeshWindow::ParentWindow` kế thừa `Window` và `MutiTexHost` (ĐO, CEGUIFalagard.dll:
  setter MaskImage RVA 0xE0BD0, RoundEnabled 0xEB670, drawSelf 0xE0780, notifyDrawEnd 0xE08C0).
  `RoundEnabled` chỉ là cờ bật mặt nạ và phải được đặt TRƯỚC `MaskImage` (setter MaskImage chỉ tra
  imageset khi cờ đang bật); lớp này không sinh hình học nào.
- `drawSelf` của cha gọi `renderer.enterMultiTextureMode(host, getPixelRect(), texture của
  imageset)`, `notifyDrawEnd` gọi `exitMultiTextureMode` (ĐO, CEGUIOgreRenderer.dll 0x10F10,
  0x11050). Mặt nạ là CẢ texture của imageset (ảnh con "RoundRegion" không dùng), áp lên quad ảnh
  của mọi cửa sổ con cháu vẽ giữa hai lời gọi; phần vẽ của chính cha không bị.
- Mỗi quad con nhận bộ UV thứ hai (ĐO, 0xB910, đã tự kiểm lại bằng `re_tool.py dis`):
  `uv2 = (toạ độ màn hình của đỉnh - góc trái trên ô cha) / cỡ ô cha`; chỉ tính khi buffer có
  đúng 6 đỉnh (một quad). Texture mặt nạ ở stage 1, lọc tuyến tính, kẹp mép.
- Công thức từng điểm ảnh (ĐO: hằng LayerBlendModeEx ở 0x19F00 và 0x19E00; chuỗi HLSL của
  RenderSystem_Direct3D11.dll ở offset tệp 0x48F50 và 0x492A8, đã tự kiểm lại):
  `c = ảnh(uv) * màu đỉnh; m = mặt nạ(uv2); rgb = c.rgb * m.a + m.rgb * (1 - m.a); a = c.a * m.a`,
  rồi trộn alpha thường. `System.cfg` đặt `Gfx_API=D3D11`.
- Dữ liệu: `HeadRoundRegion.dds` và `HeadRoundRegionTarget.dds` 80x80, RGB toàn 0, alpha chỉ có 0
  và 255 (nửa trên chữ nhật đặc, nửa dưới nửa hình tròn lệch tâm): mặt nạ nhị phân, phần đầu nhô
  lên trên khung tròn không bị cắt. `HeadRoundRegionParty` và `HeadRoundRegionPet` 48x48 có alpha
  nhiều mức (Party RGB trắng, Pet RGB bằng alpha).
- Nội dung bị che là đầu 3D: `PlayerFrame_Head_3D` (`Falagard/MeshWindow`) vẽ ảnh "View" phủ cả
  texture `<FakeObject>_RenderTexture`, kéo giãn kín ô (ĐO, UI_CEGUI.dll 0x69390; CEGUIFalagard
  0xE0AA0). Texture dựng ở Render.dll 0x17C10: cỡ cửa sổ làm tròn lên luỹ thừa 2 (ô 80 thành 128),
  nền (0,0,0,0), camera near 10, FOVy 20 độ (bản 2008 là 45). Vị trí camera, ánh sáng và tên fake
  object của đầu người chơi đang tháo tiếp.

## Ảnh đầu 3D của khung người chơi (2026-10-06)

Đọc tĩnh mã máy x64 và giải script 2026 (không chạy client). ĐO là tự đọc trực tiếp, SUY là suy ra.

- `Player_Head` thuộc bộ ảnh giả CŨ, không phải bộ Ex: `CObject_PlayerMySelf` đăng ký
  `NewFakeObject("CObject_PlayerOther", "Player_Head", "Camera_Head", 0x1B, -1)` (ĐO, Game.exe
  0x5F8ACA). Bộ Ex (Game.exe 0x1F8C40) chỉ giữ các ảnh toàn thân như `Player`, `Exterior_Player`.
- Đường đi của một ô đầu: script gọi `SetFakeObject(tên)` rồi `Character:AdjustHeadCamera(tên,
  loại)` (ĐO, Game.exe 0x2BC050; loại 0..3). Hàm này đọc `Config/Character_3DHead.txt` (DBC 0x123,
  25 cột: id mô hình và bốn nhóm [chuỗi, turn, height, distance, pitch, shift]) rồi gọi
  `RenderSystem` ô +0x4A8 (height, distance, pitch, shift) và `SetFaceDir(turn)`; chuỗi của nhóm là
  tên ảnh mặt nạ trả về script (cả 3870 dòng đều rỗng nên mặt nạ là của layout).
- `SetFaceDir` ghi góc vào thành phần y rồi `SetRotation` (ĐO, Game.exe 0x5C54C0, 0x5C5400); phía
  bộ vẽ là `Quaternion::FromAngleAxis(góc, UNIT_Y)` (ĐO, Render.dll 0x10DB0): quay quanh +y đúng
  góc của bảng, không đảo dấu.
- Camera (ĐO, Render.dll 0x35550 ghi bốn số, 0x36DC0 đặt): điểm nhìn = (x + shift, y + height *
  sy, z); mắt = (x, y + (height + distance * pitch) * sy, z + distance * sz); `setPosition` rồi
  `lookAt`. Lúc tạo (ĐO, 0x35E50): mặt cắt gần 10, FOV dọc 20 độ, tỉ lệ khung = rộng / cao,
  viewport phủ cả texture, số mặc định height 0,3, distance 1,2 trước khi đọc `Model_Parameter`
  theo thuộc tính mang tên camera.
- Loại ô: script 2026 hiện ảnh 2D ở khung người chơi nên không còn lời gọi nào; lời gọi còn sót (đã
  tắt) là khung đội: `Target:AdjustHeadCamera(strModelName, 2)` (ĐO, PartyFrame.lua giải bằng
  `lua_plain.py`). Bảng: loại 0 có turn âm (quay trái màn hình), loại 1..3 dương (quay phải). SUY:
  khung người chơi nằm mép trái như khung đội nên dùng bộ số quay phải; dự án dùng loại 2
  (NGHI-NGO 24). Nữ chính: turn 0,373, height 1,6, distance 0,9, pitch 0, shift -2.
- Dự án: `look/head` đọc `Table/head_cameras.tsv` (do `collect_ui.py` trích), `client/display/
  portrait` vẽ người chơi thứ hai vào `render::Canvas` 128x128 mỗi khung, giao diện lấy mẫu ảnh đó
  dưới mặt nạ `HeadRoundRegion`. Ảnh vẽ ra texture trên OpenGL có hàng đầu là hàng dưới cùng:
  `Canvas::is_bottom_up` báo để bộ vẽ giao diện lật trục v.
- Hai lỗi GL lộ ra khi có lượt vẽ thứ hai: (1) `glBlitFramebuffer` lúc trình bày tuân theo scissor
  còn bật từ lượt 128x128 nên màn hình đen chỉ còn một góc, đã tắt scissor ở `end_rendering`; (2)
  nhịp khung nhảy trên PC GLES (NGHI-NGO 26).
- Đã kiểm: PC Vulkan và PC GLES có lớp kiểm tra (0 lỗi), tablet PowerVR GE8320 (kín màn hình, đầu
  đứng thẳng, quay vào giữa, 500 khung hiện đều 16,7 ms). iOS chưa build được trên máy này.

## Ánh sáng, sương và chất liệu theo shader của bộ vẽ gốc (2026-10-06)

Nguồn: mã HLSL của bộ vẽ 2026 nằm sẵn trong dữ liệu (`_raw/MaterialTemplates`: `Model_vs.hlsl`,
`Model_ps.hlsl`, `ShaderLib/CalcLight.inc`, `FairyTerrain.hlsl`), phía CPU đọc tĩnh mã máy x64 của
OgreMain và Render.dll (không chạy client). ĐO là tự đọc trực tiếp, SUY là suy ra.

- Công thức (ĐO từ shader): mỗi đèn `att = pow(saturate(1 - d / range), attenuation)`, cộng
  `saturate(att * max(N·L, 0) * màu)`; màu đỉnh = `saturate(tổng * surface_diffuse + sceneColor)`;
  điểm ảnh = texture (nhân 1, 2, 4 hoặc cộng theo `BLEND_OP_0`) nhân màu đỉnh, cộng specular Blinn
  của đèn 0, rồi `lerp(màu sương, màu, f)` với `f` theo kiểu sương (không, exp, exp2, linear) tính
  từ độ sâu view. Địa hình tính tổng đèn ở điểm ảnh và không kẹp từng đèn. Mọi phép tính làm trên
  số đã mã hoá (không gian gamma), bản gốc không dùng sRGB.
- Phía CPU (ĐO): `sceneColor` = emissive + ambient nhân `surface_ambient`; màu đèn = diffuse nhân
  power scale; sương theo `AutoParamDataSource::setFog` (OgreMain 0x47240); nhân vật (cờ user của
  `LogicModel`, Render.dll 0x18A940) lấy ba hằng riêng `actor_lightone`, `actor_lighttwo`,
  `actor_ambient`; SkySphere (Render.dll 0xF4260) nội suy tuyến tính các `EnvKey` theo giờ rồi ghi
  đè ambient, sương, nền và hai đèn chính; cảnh không khai màu nhân vật thì nhân vật nhận xám 0,5
  (EnvKey ctor 0xE6B80). Đèn (`LightObject` 0x10C320) chỉ còn ba thuộc tính: range, intensity,
  attenuation.
- Dự án: `resource/classic` đọc thông số chất liệu OGRE từ `extras.ogre` của GLB; `client/stage`
  thêm đèn điểm, sương, nền, `DayKey` (`sky.cpp`); `client/display/lighting` gộp cảnh và giờ thành
  `render::Lighting`; `render/shade` chọn cờ và đèn điểm gần nhất cho từng vật (cách Ogre chọn);
  `render/forward` đẩy khối khung 1280 byte (2 đèn chính, sương, 32 ô đèn) và khối lệnh vẽ 128 byte.
  Giờ trong ngày khi chưa có máy chủ: 0,5 (NGHI-NGO 28).
- Vulkan: texture và đích là sRGB nên shader đổi về gamma, tính, rồi đổi lại (mô phỏng số trên mọi
  cặp texel và mức sáng: lệch tối đa 1 mức 8 bit so với phép tính gamma). GL: xem mục dưới.
- **Backend GL là thiết bị màu thô** (`gpu/gles/device.hpp`): định dạng khai sRGB cất là RGBA8
  thường, không phép đổi sRGB nào của phần cứng, bề mặt EGL mặc định; `model.ps.glsl` tính thẳng
  công thức gamma, không đổi màu; màu xoá vẫn nhận số tuyến tính và được mã hoá ở CPU (`gpu_tests`
  `gles_clear_of_srgb_target_is_encoded`). Backend GLES còn tính ánh sáng ở đỉnh
  (`ForwardDesc::lights_at_vertices`). Số đo trên PowerVR GE8320, 1280 x 800, 125 khoảng hiện mỗi
  lượt: shader đổi màu bằng pow ở điểm ảnh 33 ms mỗi khung; bỏ pow mà còn ánh sáng ở điểm ảnh 52
  khoảng quá 20 ms; ánh sáng ở đỉnh mà còn pow 58; lấy mẫu thô nhưng bật tắt
  `GL_FRAMEBUFFER_SRGB` theo pipeline 25; lấy mẫu thô và đổi ra tuyến tính bằng đa thức bậc 5 thay
  pow 40; màu thô toàn thiết bị 0 (sáu lượt liền, trung vị 16,70 ms, max 17,06).
- Sổ assets Android (`client/assets`, `android_main.cpp`, `package_apk.py`): `manifest.txt` ghi
  nhóm, CRC kèm cỡ và đường dẫn của từng tệp; máy giữ sổ của lần giải nén trước và chỉ chép tệp có
  dấu khác. Thay cho dấu đời tăng bằng tay: quên tăng một lần là máy chạy mã mới với gói shader cũ,
  khối hằng lệch bố cục và PowerVR huỷ cả khung (màn hình đen, không lỗi GL). `render/detail/
  shaders.hpp` nay từ chối gói shader có khối hằng khác cỡ với mã ("gói shader lệch đời với mã").
- Dữ liệu vào APK: `collect_map.py` nay kê cả tệp `.skysphere` của cảnh (loại `sky`); thiếu nó
  tablet mất ánh sáng theo giờ, nền ra (170, 51, 0) trong khi PC ra (209, 63, 0). 309 danh sách
  cảnh gom từ trước đã được bổ sung đúng dòng đó (cùng kết quả với chạy lại `collect_map`).
  `package_apk.py --depfile` kê mọi tệp và thư mục đã đọc, CMake nối vào `DEPFILE` của lệnh đóng
  APK: trước đó dữ liệu đổi mà Ninja báo "no work to do" và giữ APK cũ.
- Đã kiểm: 42/42 test ở bản sao (HEAD 629e73f cộng phần này), `test_collect_map.py` 2/2; PC Vulkan
  và PC GLES 0 lỗi lớp kiểm tra, trung vị 8,3 ms, 0 khung quá 12 ms sau khi cảnh hiện; tablet
  GE8320 hiện đúng cảnh và HUD, nền (209, 63, 0) trùng bản PC, 0 khoảng hiện quá 20 ms. iOS chưa
  build được trên máy này.
- Còn lại của Render.dll (chưa làm): bầu trời, hậu kỳ (`.hdr`, bloom, `.hfog`, godrays), bóng, nước,
  địa hình nhiều lớp thật, chất liệu LSScene/PBR, FakeLight, Projector, ánh sáng riêng của ảnh đầu.

## Máy chủ: kế hoạch và mốc P0 (2026-10-06)

Kế hoạch ở `docs/KE-HOACH-SERVER.md` (mười ba mốc P0 tới P12), danh sách từng tệp cấu hình và bảng ở
`docs/SERVER-TEP-CAU-HINH.md`. Chủ dự án duyệt cùng ngày: không Lua, cấu hình TOML, PostgreSQL,
billing riêng, tên tệp tiếng Anh, `SERVER/` ngang `CLIENT/` chứa trọn runtime, không có chế độ
offline, máy này là máy chủ thử online.

Đã làm và đã chạy (mốc P0):

- `SERVER/`: mười một tệp TOML ở `SERVER/config`, `README.md` và các thư mục con. `.gitignore` bỏ qua
  `bin`, `pgsql`, `data`, `log`, bảng xuất từ client và lưới đã nấu.
- `TOOLS/server/setup_db.py`: tải PostgreSQL 18.6 (kiểm SHA-256), giải nén 144 MB vào `SERVER/pgsql`,
  initdb vào `SERVER/data/pg`, sinh `SERVER/config/secrets.local.toml`, tạo ba database
  (`thienlong_auth`, `thienlong_billing`, `thienlong_game_1`) và ba role. Đã chạy `fetch`, `init` hai
  lần (lần hai giữ nguyên dữ liệu và mật khẩu), `status`, `stop`, `start`.
- `TOOLS/server/lint_config.py` và `config_style.py`: kiểm bố cục tệp cấu hình theo mẫu chủ dự án
  đưa (khung tiêu đề kẹp giữa hai dòng `#====` cho tệp và cho từng nhóm, cài đặt nằm sát nhau, mỗi
  cài đặt một chú thích tiếng Việt ngang hàng, dấu `=` và dấu `#` thẳng cột); `--fix` căn cột lại.
  Kết quả: 12 tệp sạch, 144 cài đặt đều có chú thích và thẳng cột; tám ca đột biến đều bị bắt.
- Hai phép thử, dựng bằng MSVC 19.51 và Clang 23.1 trong thư mục tạm của phiên (đã xoá sau khi chạy):
  `tomlplusplus` 3.4.0 ở chế độ header-only, exception tắt, đọc đúng `SERVER/config/cluster.toml` và
  báo lỗi kèm số dòng cho tệp có khoá trùng; `libpq` 18.4 bản tĩnh không OpenSSL nối PostgreSQL 18.6
  bằng SCRAM-SHA-256, chạy truy vấn có tham số, bị từ chối khi sai mật khẩu và khi role của store nối
  database của auth.
- Ba bẫy đo được đã vào mục 11 của `AGENTS.md`: `libpq` tĩnh cần `ws2_32`; không link thư viện
  `tomlplusplus` dịch sẵn khi tắt exception; `std::getenv` là C4996 dưới `/W4 /WX`.

Chưa làm: `vcpkg.json` của dự án chưa có hai gói (thêm ở P2, khi có module dùng); chưa có mã C++ của
máy chủ; việc đọc trọn sáu tài liệu máy chủ của TLBB Dev dời sang đầu P2. Mốc kế là P1: công cụ xuất
bảng và dữ liệu cảnh vào `SERVER/tables` và `SERVER/scenes`.

Lệnh kiểm:

```
python TOOLS/server/setup_db.py start
python TOOLS/server/setup_db.py status
python TOOLS/server/lint_config.py
```

## Máy chủ: P1 đợt 1, đường ống dữ liệu (2026-10-07)

Cách làm từ đợt này: Claude viết đề bài ở `docs/giao-viec/<đợt>/DE-BAI.md`, Grok Build viết mã (ba
vai viết mã, một vai review, đối chất chéo) và ghi `KET-QUA.md` cùng thư mục, Claude chạy lại rồi mới
nhận. Chưa commit gì của máy chủ.

Đã có và đã kiểm lại bằng script riêng (`docs/giao-viec/P1-DOT-1/kiem-claude/verify_p1.py`):

- `TOOLS/server/table_names.tsv`: 2.266 dòng, mỗi tệp của `Server/Config`, `Public/Config`,
  `Public/Data` (hai tệp `.dat`) và `_raw/Config` thành gì. `tsv_file.py`: ghi và đọc bảng theo hợp
  đồng mà `game::table::parse_tsv` đọc được.
- `export_tables.py`: 635 bảng DBC của client 2026 vào `SERVER/tables/shared` (574) và `variants`
  (61). 994.925 bản ghi, 18.636.500 ô, so từng ô với DBC: 0 lệch.
- `import_legacy.py`: 69 bảng vào `SERVER/tables/server` theo ngữ nghĩa của bộ đọc gốc
  (`OpenFromMemoryImpl_Text`, `Ini.cpp`). So 92 tệp chữ và 22 tệp ini bằng bộ đọc viết lại: 0 lệch.
- `export_scene.py`: 244 cảnh vào `SERVER/scenes`. 1.570 bảng quái, 39.932 dòng, so từng khoá với tệp
  ini: 0 lệch. 244 `walk.nav` trùng băm với `.nav` mà `.scn` trỏ tới.
- 4.719 tệp TSV đều đúng hợp đồng. Chạy lại hai lần ra cây trùng từng byte.

Chưa đạt, chuyển sang đợt 2 (`docs/giao-viec/P1-DOT-2/DE-BAI.md`):

- `build_data.py` thoát 1 vì 45 tệp của `Public/Scene` không có `.scn` cha, nên chưa có mã SHA-256
  của cả cây. 7 tệp trong đó do script nạp, 38 tệp là cảnh đăng nhập của client.
- Tên cột: 148 trên 17.247 cột của bảng client có tên tiếng Anh; bảng máy chủ còn 1.814 cột `?`.
- Hàm dài và lồng sâu trong `import_legacy.py`, `export_scene.py`, `export_tables.py`; test dữ liệu
  thật ghi thẳng vào `SERVER/tables`.
- Chưa đọc bảng bằng bộ đọc C++ thật; mới mô phỏng luật của nó bằng Python.

Lệnh kiểm (đặt `THIENLONG_LEGACY_ROOT` là thư mục `tlbb` bản 0859602, `THIENLONG_RAW_ROOT` là `_raw`):

```
python -W error -m unittest discover -s TOOLS/server -p "test_*.py"
python docs/giao-viec/P1-DOT-1/kiem-claude/verify_p1.py
python docs/giao-viec/P1-DOT-1/kiem-claude/treehash.py
```

## Máy chủ: P1 đợt 2, một lệnh sinh cả cây (2026-10-07)

Đề bài `docs/giao-viec/P1-DOT-2/DE-BAI.md`, kết quả của Grok ở `KET-QUA.md` cùng thư mục. Claude
chạy lại đủ mười tiêu chí và ra cùng kết quả. Chưa commit gì của máy chủ.

Đã có và đã kiểm lại:

- `python TOOLS/server/build_data.py --legacy <tlbb> --raw <_raw> --digest` thoát 0; hai lần chạy
  cùng mã `d3ffb5bf6599f34f341cc19d10f7136eb48c1b277cebdbb1ae6041a25cbadb62`. Cây: 574 bảng `shared`,
  61 `variants`, 70 `server`, 3.797 tệp của 244 cảnh, 6 tệp luật.
- 173 test Python xanh (458,6 giây khi có dữ liệu thật), không test nào ghi vào cây thật: năm dòng
  `treehash.py` không đổi sau khi chạy test. `lint_py.py` sạch: không hàm nào quá 50 dòng hay lồng
  quá 3 mức.
- `import_rules.py`: `legacy_rules.tsv` phủ kín 578 khoá của tám tệp nguồn; 131 khoá luật vào sáu
  tệp `SERVER/config/rules`, giá trị trùng nguồn cả 131; 26 khoá đối chiếu với tệp tiến trình, trùng
  cả 26.
- `align_columns.py`: 1.897 cột đã ghép của 76 cặp bảng; Claude tính lại tỉ lệ khớp của từng cột,
  trùng con số công cụ ghi; không cột ghép chắc nào dưới 95%.
- `scene_refs.py`: 250 lời gọi nạp tệp cảnh của script, trùng phép quét lại theo (tệp, dòng, loại).
  45 tệp cảnh không có `.scn` đã xử xong (10 gắn theo script, 35 chỉ client dùng).
- Ô dữ liệu vẫn 0 lệch nguồn sau khi đổi tên cột và thêm cột: `verify_p1.py` A, B, C, D sạch.

Claude tìm thêm, đưa vào đợt 3 (`docs/giao-viec/P1-DOT-3/DE-BAI.md`):

- Sáu tên trái bảng thuật ngữ của phụ lục (`xinfa_max_level`, `pk_refix`, `[ability]`,
  `inner_art_refix_parameter`, `pvp_ruler`, `zhuandan_id`): bảng thuật ngữ chưa có cổng kiểm.
- Tệp luật ghi toạ độ thành `pos_x_permille`; ba điểm xuất phát có toạ độ mà thiếu cảnh; vài khoá
  thời lượng chưa có đơn vị trong tên.
- Bốn lời gọi của `efuben_3_shuilao.lua` nạp tệp quái không có trên đĩa.
- 265 ô `int` và 26 ô `float` chưa ở dạng chính tắc (số 0 đứng đầu, dấu cách cuối).
- Tên cột: bảng client 16.497 trên 17.247 cột chưa có tên, trong đó 14.531 cột không có nhãn nào
  (bảng chỉ có ở bản 2026); bảng máy chủ 1.750 trên 2.172 cột chưa có tên.

Đợt 3 giao: tên cột bảng máy chủ và bảng client có bản đối chiếu, `diff_tables.py` (hiệu id và độ
phủ tham chiếu), `thienlong_lint` bằng C++ (`SRC/content`, `SRC/linttool`), và các sửa trên.

Lệnh kiểm thêm của đợt 2 (cần `THIENLONG_LEGACY_ROOT`):

```
python -B docs/giao-viec/P1-DOT-2/kiem-claude/verify_p2.py
python -B docs/giao-viec/P1-DOT-2/kiem-claude/check_basis.py <tlbb_server>
```

## Máy chủ: P1 đợt 3, mốc P1 đạt (2026-10-07)

Đề bài `docs/giao-viec/P1-DOT-3/DE-BAI.md`, kết quả của Grok ở `KET-QUA.md` cùng thư mục. Claude
chạy lại đủ mười bốn tiêu chí và ra cùng kết quả. Chưa commit gì của máy chủ.

Đã có và đã kiểm lại:

- `thienlong_lint` (`SRC/content`, `SRC/linttool`): mã C++ đầu tiên của máy chủ. Dựng lại từ đầu
  bằng GCC 16, Clang 23 (ASan, UBSan) và MSVC 19.51: 0 cảnh báo; `check.py` 0 lỗi. Trên cây thật:
  4.015 tệp, 1.097.688 bản ghi, 22.019.096 ô, 0 lỗi, 2,2 giây, bộ nhớ đỉnh 239,5 MiB.
- `diff_tables.py`: 106 cặp bảng cùng tên (bản 2026 có 354.614 id, bản 0859602 có 62.374, chung
  61.522) và 55 dòng tham chiếu của `TOOLS/server/refs/` (21 quan hệ; 6 dòng có giá trị thiếu, ví
  dụ loại quái `3364` không có ở bảng quái của cả hai bản). Báo cáo của exe C++ trùng từng byte với bảng của Python, và
  trùng phép đếm lại của `docs/giao-viec/P1-DOT-3/kiem-claude/verify_p3.py`.
- Tên cột: bảng máy chủ từ 422 lên 1.889 trên 2.172 cột; bảng client từ 750 lên 2.590 trên 17.247
  (14.516 cột còn lại không có nhãn nào). Cổng `lint_names.py` chặn từ trái bảng thuật ngữ.
- 211 test Python xanh (514,9 giây); `build_data.py --digest` hai lần cùng mã
  `29a45614a089d6f506b7ffd4d178f365a1935862f7b6a01a28438d1561b8633f`.
- Ô số của bảng đã ở dạng chính tắc (291 ô đổi theo giá trị `atoi`, `atof` đọc ra); tệp luật đã
  sửa toạ độ, thêm cảnh xuất phát; `scene_level_files.tsv` ghi 1.344 tệp quái theo cấp thuộc cảnh
  nào theo script.

Claude tìm thêm, đưa vào đợt sau:

- Hai bảng tên cột dịch cùng một chữ thành hai từ: 48 nhãn có hơn một tên (`defence` và `defense`,
  `cold` và `ice`, `dodge` và `miss`). Phụ lục mục 1 đã chốt 15 từ; cần cổng kiểm.
- `lint.cpp` 1.226 dòng một tệp; exe giữ cả cây trong bộ nhớ; ba chỗ nuốt lỗi lúc duyệt thư mục.
- Thư viện TOML không qua được `check.py` nếu đưa bằng `-I`; cách qua đã ghi ở mục 11 của
  `AGENTS.md`.

Bước kế: `docs/giao-viec/P2-DOT-1/DE-BAI.md` mở mốc P2 (đọc cấu hình TOML, chạy và dừng tiến trình
con, bảy exe rỗng, cài vào `SERVER/bin`) kèm các sửa trên. Claude đã thêm `[stop] timeout_seconds`
vào `SERVER/config/supervisor.toml` và module `content`, `linttool` vào mục 0 của `AGENTS.md`.

Lệnh kiểm thêm của đợt 3:

```
python -B docs/giao-viec/P1-DOT-3/kiem-claude/verify_p3.py
cmake --build --preset gcc-debug --target thienlong_lint content_tests
ctest --preset gcc-debug -R "^(content_tests|layers|server_data_lint)$"
build/msvc-release/thienlong_lint.exe --root SERVER --refs TOOLS/server/refs
```

## Máy chủ: P2 đợt 1, bảy exe khởi động và dừng theo thứ tự (2026-10-07)

Đề bài `docs/giao-viec/P2-DOT-1/DE-BAI.md`, kết quả của Grok ở `KET-QUA.md` cùng thư mục. Grok hết
hạn mức giữa đợt: ba vai phụ dừng vì HTTP 402, không có vòng review, T12, T13 và T15 không đạt.
Claude làm nốt, đóng luôn vai review, rồi chạy lại T1 tới T16. Toàn bộ phần máy chủ từ P0 tới đợt
này vào git ngày 2026-10-07, mười hai commit theo từng phần: kế hoạch, runtime và cấu hình, công
cụ dữ liệu, bảng và cảnh, sáu commit mã (`content`, `config`, `linttool`, `process`, `supervise`,
`service`), nối build, tài liệu. Sáu commit mã chưa nối vào CMake; commit `build` làm việc đó.

Đã có và đã kiểm lại:

- `config` (`SRC/config`): mười một bộ đọc TOML thành struct đã kiểm miền và một phép kiểm chung
  cho tệp chưa có struct; khoá lạ, thiếu khoá, sai kiểu, ngoài miền đều là lỗi kèm số dòng, báo đủ
  một lượt. Chỉ `detail/parse.cpp` thấy thư viện TOML. Mọi số nguyên bị chặn ở int32.
- `process` (`SRC/process`): chạy tiến trình con, đọc dòng có hạn chờ và trần 4 KiB, câu hỏi "đã
  có yêu cầu dừng chưa". `supervise`: máy trạng thái thuần của trình giám sát. `service`: điểm vào
  chung của bảy exe (`thienlong_server`, `_store`, `_auth`, `_billing`, `_world`, `_zone`, `_gate`).
  Giao kèo giữa các tiến trình ghi ở mục 3.1 của `docs/KE-HOACH-SERVER.md`.
- `thienlong_lint` đọc bảng theo từng bản ghi, không dựng bảng trong bộ nhớ, và kiểm cả TOML: 4.276
  tệp (4.015 TSV, 261 TOML), 1.097.688 bản ghi, 22.019.096 ô, 0 lỗi, 1,4 đến 1,9 giây, đỉnh working
  set 41 MiB (bản của đợt 3 là 239,5 MiB, bản Grok nộp 146,4 MiB, trần 120 MiB). Báo cáo phủ
  trùng `TOOLS/server/table_ref_coverage.tsv`; một test giữ luật dòng trùng `table::parse_tsv`.
- Tám test xanh ở `gcc-debug`, `clang-asan`, `msvc-release`; build 0 cảnh báo; `check.py` 86 tệp 0
  lỗi (bản POSIX kiểm riêng: clang-format, độ lồng, cú pháp bằng trình dịch NDK).
- Chạy thật sau `cmake --install build/msvc-release --component server --prefix SERVER`:
  `thienlong_server --config SERVER/config` với stdin rỗng in đúng 15 dòng (`started postgres` đầu,
  `stopped postgres` cuối), thoát 0, 0,5 giây tới `ready`; PostgreSQL dừng kiểu `fast`. Cụm chạy sẵn
  thì in `using postgres` và không bị dừng. Giết một con thì nó được chạy lại; quá trần thì cả cụm
  dừng, thoát 1. Giết giám sát: sau 5 giây không còn `thienlong_*`, PostgreSQL vẫn sống và lần chạy
  sau dùng lại. Ctrl+C và Ctrl+Break ở console thật: dừng ngược thứ tự, thoát 0.

Lỗi Claude tìm thấy ngoài báo cáo của Grok và đã sửa:

- T15 treo vì con coi stdin `NUL` là "chưa có yêu cầu dừng"; và `pg_ctl` thừa hưởng job cùng ống
  của giám sát, nên lần chạy thử lúc 21:05 phải giết cả PostgreSQL. Lần chạy kế PostgreSQL tự phục
  hồi (redo không có gì để phát lại, không mất dữ liệu).
- Bộ chạy thật thêm tiến trình mới mà không thay tiến trình cũ của cùng ô: chạy lại một con là giữ
  hai bản ghi cho một ô. Có test chặn (`relaunch_replaces_dead_process`, `..._live_process`).
- Bộ đọc cấu hình không có trần chung cho số nguyên (đọc mã thấy vậy; chưa chạy đối chứng trên exe
  cũ). Nay mọi số nguyên ngoài int32 là lỗi ngoài miền, có ba mẫu sai trong `config_samples.hpp`.
- `thienlong_lint` coi thư mục thiếu là "không có gì để kiểm"; nay là lỗi.

Còn nợ, không chặn đợt 2: bản POSIX của `process` chưa chạy lần nào; không có TSan trên Windows nên
`process` (hai luồng: luồng chính và trình xử lý sự kiện console) chưa kiểm đua; `check_basis.py`
tìm thấy 45 trên 69 dẫn chứng mã nguồn 2008, 24 dẫn chứng còn lại chưa xem.

Bước kế: P2 đợt 2 (`net`, `protocol`, `gen_protocol.py`, fuzz).

Lệnh kiểm của đợt:

```
cmake --build --preset <p> --target thienlong_server thienlong_lint config_tests process_tests supervise_tests service_tests content_tests server_boot
ctest --preset <p> -R "^(layers|content_tests|config_tests|process_tests|supervise_tests|service_tests|server_boot|server_data_lint)$"
python -B docs/giao-viec/P2-DOT-1/kiem-claude/lint_peak.py build/msvc-release/thienlong_lint.exe
python -B docs/giao-viec/P2-DOT-1/kiem-claude/boot_check.py build/msvc-release SERVER/config
python -B docs/giao-viec/P2-DOT-1/kiem-claude/boot_check.py SERVER/bin SERVER/config postgres using survive
```

## Máy chủ: P2 đợt 2, protocol và net (2026-10-08)

Đội Grok viết trong worktree `build/p2-dot-2` (nhánh `p2-dot-2`) theo
`docs/giao-viec/P2-DOT-2/DE-BAI.md`, trong lúc Claude viết mã client ở cây chính. Claude nghiệm thu
ngày 2026-10-08, dời các commit của nhánh lên đầu `main` rồi đưa vào `main`; worktree và nhánh đã
xoá. Báo cáo của đội ở `docs/giao-viec/P2-DOT-2/` (`KET-QUA.md`, `REVIEW.md`, log gốc ở `so-do/`);
script và log kiểm lại của Claude ở `kiem-claude/`.

Có gì:

- `SRC/protocol`: tầng byte (`Reader`, `Writer`, `peek_frame`; số little-endian ghép từng byte,
  UTF-8 theo RFC 3629 và cấm byte 0, trần kiểm trước mọi lần cấp phát, mười giá trị `WireError`),
  kênh (`Channel`: hộp nhận và hộp gửi có trần, khung hỏng thì kênh hỏng hẳn), danh mục tin sinh từ
  bốn bảng TSV ở `SRC/protocol/catalog` (19 tin, 1 record, 38 trường, 4 enum của ba nhóm phiên, nhân
  vật, xác thực). Phiên bản protocol là 1.
- `SRC/net`: socket TCP không chặn và `PollSet` (Winsock chạy được; bản POSIX mới qua kiểm cú pháp
  bằng trình dịch NDK). Header mạng của hệ điều hành chỉ nằm trong hai tệp nền.
- `TOOLS/server/gen_protocol.py`: bảng thành `messages.hpp`, `messages.cpp`,
  `tests/protocol_samples.hpp` (57 mẫu, byte do bộ mã hoá Python tính độc lập) và
  `docs/PROTOCOL-TIN.md`; từ chối bảng sai theo luật G1 tới G11. Sửa bảng thì chạy lại lệnh này;
  test `protocol_catalog_fresh` đỏ khi quên.
- Fuzz hai tầng: `protocol_fuzz_tests` trong ctest (năm đích, 200.000 vòng mỗi đích) và
  `TOOLS/server/fuzz_protocol.py` (libFuzzer, ASan và UBSan).
- Bảy exe của máy chủ chưa mở cổng nào: nối `gate`, `auth` vào `net` là việc của đợt 3.

Claude kiểm lại trên cây đã dời lên `main` (đầu nhánh `c29eee8`, trước commit tài liệu):

- Ba preset, dựng `all` và `header_check`, 0 cảnh báo: `gcc-debug` 46/46, `clang-asan` 52/52,
  `msvc-release` 52/52 (bản checkout không có `CLIENT/data`). Bốn commit trung gian đều dựng được
  bằng `gcc-debug`.
- 249 test Python (8 bỏ qua), `lint_py.py` thoát 0, `gen_protocol.py --check` thoát 0; sửa một ô
  `limit` thì `--check` thoát 1 và nêu đúng ba tệp cũ.
- `net_tests` và `wire_loop_tests` lặp 20 lần ở `msvc-release`: 20 lần xanh mỗi test.
- libFuzzer `--runs 1000000 --seed 20261008`: năm đích đủ một triệu vòng, thoát 0, không tệp crash
  (`so-do/fuzz-20261008-114727.tsv`). Bản chép bị bỏ phép kiểm biên của `Reader::take`: bốn đích
  giải mã sập vì `heap-buffer-overflow` trong 0,2 giây; đích `frame` không dùng `Reader` thì sạch.
- `check.py` trên 28 tệp C++ mới: GCC, Clang và clang-tidy sạch ở 27 tệp; `socket_posix.cpp` không
  dịch được trên Windows (thiếu `arpa/inet.h`) và qua hai lệnh kiểm cú pháp NDK. Định dạng sạch
  theo `.clang-format` đã commit (100 cột).
- Số đo của đội tái hiện trong ngưỡng 30% (`msvc-release`, năm lượt, trung vị; trong ngoặc là số
  của đội): mã hoá 6.040.887 tin mỗi giây (5.929.633), giải mã 6.459.594 (6.260.513); khứ hồi p50
  18,3 µs (18,4), p99 35,7 µs (32,1); thông lượng 2.844 MiB mỗi giây (3.127); `gen_protocol.py
  --check` 0,067 giây (0,067).

Claude sửa thêm trước khi commit:

- 24 vòng lặp không có ngoặc nhọn (vai review chỉ nêu hai chỗ), gồm hai chỗ trong mã nguồn `net`
  và bốn chỗ trong tệp sinh: sửa hai mẫu của bộ sinh rồi sinh lại.
- M2 của `REVIEW.md`: thêm hai ca `channel_server_tight_*` ở trần hộp nhận sát của server (65.544).
- `NetError` thiếu `[[nodiscard]]`; `net_tests.cpp` gom cổng bằng `std::ranges::transform` để tệp
  không vượt 500 dòng sau khi thêm ngoặc.

Còn mở, đưa vào đề bài đợt 3: M1 (POSIX: RST sau FIN ra `kConnect` thay cho `kReset`; chưa có máy
Linux để thử), N6 (bộ giải mã sinh ra không đối chiếu `body.size()` với `frame.body_bytes`), N10
(`fuzz_protocol.py` chưa nhận `--source`, `--out`), N12 (`optional:optional:u8` được chấp nhận, đề
bài chưa nói). `check.py` toàn cục đổi luật trong ngày 2026-10-08 (trần 120 cột, thêm bước "hình
dạng") sau khi đội đóng băng mã: 22 trong 28 tệp mới chưa theo luật mới (62 câu lệnh trải nhiều
dòng, đo ở `kiem-claude/check-all-2.log`).

Bước kế: P2 đợt 3 (`secure`, `ipc`, `metrics`, cho bảy exe mở cổng).

Lệnh kiểm của đợt:

```
python -B -W error -m unittest discover -s TOOLS/server -p "test_*.py"
python -B TOOLS/server/gen_protocol.py --check
ctest --preset <p> -R "^(protocol_tests|protocol_channel_tests|protocol_catalog_tests|protocol_fuzz_tests|net_tests|wire_loop_tests|protocol_catalog_fresh)$"
python -B TOOLS/server/fuzz_protocol.py --runs 1000000 --seed 20261008
```

## Máy chủ: P2 đợt 3, phần đầu: `secure` và mặt trước `gate` (2026-10-08)

Một phiên AI phụ viết trên nhánh `gate-front` theo một prompt trực tiếp (không có thư mục
`docs/giao-viec`), bốn commit `a14cc10`, `f74a41a`, `3d92acd`, `ae8c135`, gộp vào `main` ở
`21fe0ba` lúc 20:44. Mục này do Claude ghi sau khi đọc mã và đo lại tối cùng ngày, `main` ở
`501743a`.

Có gì, theo mã:

- `SRC/secure` (7 tệp, 1.139 dòng): `ServerHandshake` và `ClientHandshake` (lời chào 42 byte, lời
  đáp 96 byte, khoá X25519 tạm, chữ ký Ed25519 ghim sẵn), `RecordPipe` (bản ghi ChaCha20-Poly1305
  IETF, đầu 2 byte, thân rõ tối đa 4.104 byte, bộ đếm `u64` không quay vòng), `Identity` (tệp khoá
  64 byte, `store_new` không ghi đè). Mọi phép mật mã gọi libsodium 1.0.22 qua
  `secure/detail/sodium.cpp`. Thiết kế và chỗ khác bản Dev ở `docs/SERVER-BAO-MAT.md`.
- `SRC/gate` (4 tệp, 1.463 dòng): `Table` là bảng kết nối cấp một lần theo `max_connections` (tay
  nắm gồm chỉ số và thế hệ, trần mỗi IP, lọc CIDR, hạn bắt tay, hạn im lặng, thùng token, hộp gửi
  1.024 byte mỗi ô); `front.cpp` là vòng tick 60 Hz một luồng trên `net::PollSet`. Sau bắt tay gate
  chỉ nhận `Hello` (đáp `Welcome`), `Ping` (đáp `Pong`), `Logout` (đáp `Goodbye` rồi đóng); mã tin
  khác bị ngắt mà không giải mã thân.
- `thienlong_gate --gen-key <tệp>` sinh khoá danh tính, in khoá công khai dạng hex. `gate.toml`
  thêm khoá `idle_timeout_ms`.
- Test: `secure_tests` 26 ca, `gate_tests` 13 ca (đồng hồ tiêm, không ngủ), `gate_loop_tests` 1 ca
  (gate thật qua loopback). Fuzz: `tests/fuzz/fuzz_handshake.cpp`, `fuzz_record.cpp` cùng
  `TOOLS/server/fuzz_secure.py`. Đo tải: `TOOLS/server/gate_load.cpp` (exe `thienlong_gate_load`,
  chỉ Windows).

Claude đo lại (hai cây dựng riêng `build/survey-clang` và `build/survey-msvc` chỉ gồm target máy
chủ, vì cây `build/<preset>` dùng chung đang có phiên khác dựng):

- Clang 23 với ASan và UBSan: 263 bước, 0 cảnh báo. MSVC bản phát hành: 267 bước, 0 cảnh báo.
- Mười ba test xanh ở cả hai cây: `content_tests`, `config_tests`, `process_tests`,
  `supervise_tests`, `protocol_tests`, `protocol_channel_tests`, `protocol_catalog_tests`,
  `protocol_fuzz_tests`, `net_tests`, `wire_loop_tests`, `secure_tests`, `gate_tests`,
  `gate_loop_tests`.
- `check.py -j 2` trên 10 tệp của `SRC/gate` và `SRC/secure`: GCC 16.2, Clang 23.1 và clang-tidy
  sạch, 0 lỗi.
- Bản cài: tám exe ở `SERVER/bin` là bản ngày 07, dừng với `gate.toml:32: khoá lạ
  idle_timeout_ms`. Đã cài lại từ `build/survey-msvc`. Sau đó `thienlong_lint --root SERVER --refs
  TOOLS/server/refs` in 4.276 tệp, 1.097.688 bản ghi, 22.019.096 ô, 55 dòng tham chiếu, 0 lỗi; và
  `thienlong_server --config <bản chép cấu hình nghe 127.0.0.1> --no-postgres` với stdin rỗng in
  đủ 13 dòng (`started store 0` tới `stopped store 0`), thoát 0.
- Đo tải, `thienlong_gate_load` bản MSVC, loopback, cùng máy với gate:

| Kịch bản | Bắt tay | Tick p99 | Tick trễ | Pha chậm nhất |
|---|---|---|---|---|
| `--good 2000 --hostile 400 --seconds 10 --rate 10` | 2.000 trong 0,478 giây | 12,4 ms | 0 | đẩy hộp gửi 9,9 ms |
| mặc định: 10.000 khách tốt, 2.000 thù địch, 20 giây | 3.908 trong 20 giây | 121,4 ms | 1.088 | đọc 112,6 ms |

  Hạn một tick là 16,7 ms. Gate giữ được trần đang cấu hình (2.000 kết nối) nhưng không giữ được
  kịch bản mặc định của chính công cụ đo. Bộ nhớ: 51,6 MiB với bảng 2.416 ô, 219,1 MiB với bảng
  12.016 ô, tức khoảng 18 KiB cấp sẵn cho mỗi ô.

Chưa chạy trong lượt đo này: `service_tests` và `server_boot` ở hai cây riêng (chúng chạy cụm với
`SERVER/config` thật, gate nghe `0.0.0.0:7000`, mỗi đường dẫn exe mới sinh một rule tường lửa);
log của phiên khác lúc 21:57 ghi hai test đó xanh ở `gcc-debug` (71 trên 71). Cả preset
`clang-asan` và `msvc-release` ở cây dùng chung chưa dựng lại từ khi gộp: lượt `clang-asan` của
phiên khác lúc 22:03 dừng ở `SRC/client/display/display_gpu.cpp:2798` (`role_canvas_box` thiếu
khai báo trước, `-Wmissing-prototypes`), nên 16 test ở đó báo đỏ vì exe cũ hoặc không có exe. Đã
đưa hàm vào namespace ẩn danh; số đo của cả cây ở hai cây riêng nằm ở mục "Khảo sát theo mã".

Fuzz chạy lại trên cây làm việc lúc 23:15 (`fuzz_protocol.py --runs 1000000 --seed 20261008`, rồi
`fuzz_secure.py --runs 1000000`, rồi `fuzz_secure.py --teeth`): năm đích của protocol (`frame`,
`game_client`, `game_server`, `auth_client`, `auth_server`) và hai đích của secure (`handshake`,
`record`), mỗi đích 1.000.000 vòng dưới ASan và UBSan, đều thoát 0; chậm nhất là `handshake` 73
giây và `frame` 53 giây. Phép thử có răng in `safe=0 broken=1 caught=1`: bản bỏ kiểm biên bị ASan
bắt. Log của năm đích protocol ở `docs/giao-viec/P2-DOT-2/so-do/fuzz-*-20261008-231514.*`.

`thienlong_gate_load` bỏ qua đối số lạ: gõ `--help` là nó chạy luôn kịch bản mặc định 20 giây (đo
2026-10-08). Đối số nó hiểu: `--good`, `--hostile`, `--seconds`, `--rate`.

Còn thiếu để P2 đạt, và các nợ thấy khi đọc mã: liệt kê ở mục 10 của `docs/KE-HOACH-SERVER.md`
(đoạn "Còn thiếu để P2 đạt") và mục 44 của `docs/NGHI-NGO.md`.

Lệnh kiểm của đợt (cây riêng thì thay `--preset <p>` bằng `--test-dir <cây>`):

```
ctest --preset <p> -R "^(secure_tests|gate_tests|gate_loop_tests|service_tests|server_boot)$"
python ~/.claude/cpp23/tools/check.py -j 2 SRC/gate/*.cpp SRC/gate/*.hpp SRC/secure/*.cpp SRC/secure/*.hpp
python -B TOOLS/server/fuzz_secure.py --runs 1000000 --seed 20261008
build/msvc-release/thienlong_gate_load.exe --good 2000 --hostile 400 --seconds 10 --rate 10
```

## Client: đóng các việc còn dở trong cây (2026-10-07)

Tối 2026-10-06 ba nguồn để lại việc chưa commit trong cùng cây làm việc rồi dừng: phiên Claude
của client (màu thô trên GL, ánh sáng ở đỉnh, sổ assets Android, đóng APK; mục "Ánh sáng, sương
và chất liệu" ở trên là của phiên đó), phiên Claude của dự án VnNet (lệnh `cook-map` của
`TOOLS/bake`), và một công cụ khác (nước, bảng bản đồ, HUD). Phiên máy chủ nhận lại ngày
2026-10-07: đọc trọn diff, kiểm trên mọi nền tảng dựng được, sửa chỗ hỏng, commit theo từng phần.

Phần chưa có mục nào trong tệp này:

- Nước cho camera (`client/map/liquid`, `display_gpu.cpp`): `WaterCover` là lưới ô theo cỡ ô địa
  hình, mỗi ô giữ mực nước hoặc NaN; `pour_liquid` chạy lại phép lan của `build_liquid` rồi ghi mực
  lên các ô có tam giác nước, hai mặt chồng thì lấy mực cao. `water_at` trả mực tại một điểm (ngoài
  bản đồ thì kẹp vào ô biên như `BitMap::SafeGetValue`), `ray_water` dò tia bước 10 cm như
  `NavCollider::RayCollideWater`. `Display` đưa hai hàm đó vào `Probe` của camera, để mắt kính
  không chìm dưới mặt nước. Khác gốc: dữ liệu mới không có `waterarea.bmap` và `waterheight.hmap`
  nên lưới dựng từ chính các mặt `TerrainLiquid` của cảnh. (Gỡ ngày 2026-10-08 cùng kính Loong:
  camera 2026 không dò nước.)
- Bản đồ cảnh và bản đồ thế giới (`ui/panel/maps`, `ui/hud`): trạng thái mở, đóng, đổi tầng của
  `SceneMap.lua` và `LargeMap.lua` viết lại thành hàm thuần; HUD dò nút dưới con trỏ lúc vừa bấm
  rồi gọi `press_map`; đổi cảnh thì đóng bản đồ cảnh. Bốn nhóm cảnh có tầng (Bảo Tàng Động, Yên
  Vương Cổ Mộ, Tần Hoàng Địa Cung, Thông Thiên Tháp). Chưa có widget bản đồ thế giới nên chưa chọn
  được thành.
- `TOOLS/bake`: lệnh `cook-map` và thẻ "Cook bản đồ" gọi chương trình `map_cook` của dự án VnNet
  (tìm qua biến `BAKE_MAP_COOK` hoặc PATH, không ghi cứng đường dẫn), ghi ra `<đích>.partial` rồi
  mới đổi tên; hỏng thì giữ tệp cũ.

Chỗ hỏng có sẵn ở HEAD, lộ ra khi dựng đủ mọi preset, đã sửa:

- `SRC/fx/script.cpp` và `field.cpp` không qua `-Werror` của GCC và Clang từ commit `836f759`
  (hàm thiếu khai báo trước, biến chỉ gán không dùng), nên `gcc-debug` và `clang-asan` không dựng
  được cả cây.
- `windres` của MinGW không dịch được `SRC/client/app.rc` vì thư mục `-I` có dấu cách; tệp `.rc`
  nay nằm trong target `OBJECT` riêng không có thư mục include.
- Trên thiết bị Android ba test (`audio_tests`, `ui_text_tests`, `pace_tests`) đỏ vì CMake nhét
  đường dẫn dữ liệu của máy dựng vào chúng; nay chỉ khai đường dẫn đó khi không dựng cho Android.
- Mã nước mới thêm lỗi cổng (thiếu ngoặc phép tính, vòng `for` đếm bằng số thực, test dài quá
  ngưỡng); đã sửa, chỉ số ô gom về một hàm `cell_slot`.

Đã kiểm trên cây cuối:

- `msvc-release`: 0 cảnh báo, 49/49 test. `clang-asan` (ASan + UBSan): 0 cảnh báo, 49/49.
  `gcc-debug`: 0 cảnh báo, 40/40 ở lượt không dính lỗi TLS của toolchain (mục 12 của `NGHI-NGO.md`:
  `log_tests` chết khoảng 1 trong 4 tới 1 trong 30 lần lúc luồng thoát).
- `android-arm64`: 0 cảnh báo; 31/31 test chạy trên tablet Lenovo TB-X306F (trước khi sửa là 30/33);
  APK 1.333 MB với 2.523 tệp assets. Cài và chạy thật: lần đầu sổ assets chép 2.257/2.257 tệp đổi,
  lần hai không chép gì và từ "nền tảng sẵn sàng" tới lúc hiển thị chạy là 1,1 giây; cảnh, HUD và
  màu trùng bản PC; khung trung vị 16,7 ms, p95 18,3 ms theo bảng trên màn hình.
- Client PC bản `msvc-release` với dữ liệu thật, 400 khung: Vulkan và GLES đều thoát 0, trung vị
  8,3 ms, sau khi cảnh hiện không khung nào quá 12 ms, lớp kiểm tra GPU 0 lỗi; ảnh chụp ra đúng cảnh.
- Python: `test_bake.py` 29 test (2 bỏ qua vì Windows không cho tạo symlink), `test_collect_map.py`
  2 test.
- `check.py` trên 27 tệp C++ của phần này: 17 tệp sạch. 10 tệp còn lỗi cổng đều là lỗi có sẵn từ các
  commit trước; so bằng clang-tidy chạy trên bản HEAD thì phần mới không thêm lỗi nào.

Kiểm sau khi commit, trong một `git worktree` sạch (không có `CLIENT/data`, `SERVER/tables`), preset
`msvc-release`, dựng lại lần lượt từng commit của mười ba commit `88f7e24` tới `7e379d4`:

- Lần dựng đầu lộ hai dòng bị đặt lệch chỗ ở commit trung gian (commit bản đồ không tự dựng được vì
  một dòng của `display_gpu.cpp` rơi nhầm hàm; ba commit `render` có `shaders.sizes` nằm sau lời gọi
  `shaders.load`). Nguyên nhân: lát diff không ngữ cảnh (`git apply --unidiff-zero`) đặt dòng thêm
  theo số dòng của tệp đích. Ngày 2026-10-08 chủ dự án cho viết lại lịch sử: mười một commit sau
  `98eba33` được dựng lại với hai dòng nằm đúng commit, cây cuối trùng từng byte với cây đã kiểm.
  Sau khi viết lại: cả mười ba commit dựng được, 0 cảnh báo, không còn dòng nào vừa thêm vừa gỡ
  trong chuỗi. Chuỗi cũ còn ở ref `refs/backup/main-truoc-viet-lai-2026-10-08`.
- Ở `7e379d4` bản checkout sạch chạy 41/43 test: `audio_tests` và `map_tests` đỏ vì CMake khai
  đường dẫn `CLIENT/data` cả khi thư mục chưa có. Đã sửa ở `e583131`: chỉ khai khi có
  `sound/sound_table.xml` và `Config/ScenePosDefineEx.txt`; bản checkout sạch 43/43, cây chính vẫn
  49/49.

Còn nợ:

- Nợ cổng có sẵn: `client/display/display_gpu.cpp` (15 chẩn đoán clang-tidy, một dòng lệch định
  dạng), `client/map/liquid.cpp` (25), năm tệp `gpu/gles`, hai tệp `fx`. (`display_gpu.cpp` và
  `liquid.cpp` đã trả ngày 2026-10-08.)
- Quyết định còn mở của phiên client: GL trộn trong suốt trên số đã mã hoá, Vulkan trộn tuyến tính,
  nên giao diện mờ lệch nhau giữa hai backend (`NGHI-NGO.md` mục 29).
- Chưa dựng: `android-x86_64` (chưa từng cài gói vcpkg cho triplet đó trên máy này), iOS.
- Lỗi TLS giả lập của GCC MinGW làm bộ test `gcc-debug` thỉnh thoảng đỏ (`NGHI-NGO.md` mục 12).

## Giao diện: ba bảng mở từ thanh menu chính (2026-10-08)

Nút `Button_Character`, `Button_Pack`, `Button_Mission` của thanh menu chính mở và đóng bảng nhân
vật (`SelfEquip`), hành trang (`Packet`), nhiệm vụ (`QuestLog`); nút đóng của mỗi bảng giấu nó;
bảng mở sau nằm trên. Client gốc: nút gọi `OpenEquip`, `ToggleContainer`, `ToggleMission`, ba hàm
chỉ đẩy sự kiện, script của từng bảng tự đảo trạng thái hiện (`GMGameInterface_Script.cpp` của
mã 2008; `SelfEquip.lua`, `Packet.lua`, `QuestLog.lua` ở `G:\TLBB\_content\source\Interface`).

- `ui/panel/desk` (mới, thuần logic): `Desk` giữ thứ hạng mở của từng bảng, `press_desk` nhận
  tên cửa sổ vừa bị nhấn, `paint_desk` kê gốc các bảng đang mở theo thứ tự mở. `ui/hud` nạp thêm
  ba layout (15 layout) và nối `press_desk`, `paint_desk` vào khung.
- `collect_ui.py` gom thêm `SelfEquip`, `Packet`, `QuestLog` (24 cửa sổ). Golden
  `tests/golden/ui_rects.tsv` sinh lại: 1367 cửa sổ ở bốn cỡ màn hình, 425 cửa sổ mới, các dòng
  cũ không đổi; `gui_real_tests` so ô của `Hub` với bản tính độc lập, không ô nào lệch.
- Bảng dịch thêm 119 khoá của ba bảng (0 khoá chưa dịch).
- Nhãn của nút viết ngắn, hoa đầu mỗi chữ, kiểu "Thú", "Thể Lực", "Đóng/Mở" (chủ dự án chốt
  ngày 2026-10-08): layout gốc vẽ ô cho hai chữ Hán, chữ Việt dài thì bị cắt. Bộ đo mới
  `TOOLS/content/ui_text_fit.py` đo chữ bằng độ tiến của phông client đang vẽ (`VTNAM14.bin`) và
  so với ô ở 1280x720. Trước khi rút: 37 nút tràn ô trong 24 layout, kể cả nút đã dịch từ các lát
  trước (thẻ kênh trò chuyện, nút tổ đội). 18 nhãn cũ được rút ngắn, 119 khoá mới viết ngắn từ
  đầu; còn 0 nút tràn và 7 cửa sổ loại khác (chỗ điền mẫu như tên, cấp, 9999/9999). Lệnh:
  `python TOOLS/content/ui_text_fit.py CLIENT/data tests/golden/ui_rects.tsv`.

Ba chỗ hỏng lộ ra khi bấm thử trên client thật, đã sửa trong cùng lát:

1. Nút Hành trang và nút Giao dịch không bấm được: `Hub::hit` trả `MainMenuBar_Center` (khung ô
   kỹ năng, 383..897 ở 1280x720) thay cho nút nằm trong ô đó. Nguyên nhân: `visit_list` của
   `gui/hub.cpp` xếp anh em `AlwaysOnTop` ngược thứ tự khai (chép từ TLBB Dev). CEGUI gắn cửa sổ
   vào cha rồi mới đặt thuộc tính (`CEGUIGUILayout_xmlHandler.cpp`), và `setAlwaysOnTop` gỡ cửa sổ
   ra rồi thêm lại vào cuối danh sách vẽ của cha (`Window::addWindowToDrawList`), nên anh em
   luôn-trên-cùng khai sau nằm trên. Đã sửa theo mã gốc; ảnh thanh menu trước và sau khi sửa
   trùng nhau, chỉ phép dò chuột đổi. 66 cặp anh em luôn-trên-cùng chồng nhau trong 24 layout
   đổi thứ tự theo.
2. `Hub::hit` nhận loại dò (`gui::Probe`): nhấn trái bỏ qua thêm cửa sổ `MouseLButtonHollow`, như
   `nEventType` 1 của `Window::getChildAtPosition`. 36 cửa sổ của các layout đã gom chỉ thủng với
   nút trái (mặt nạ ô trang bị, mặt nạ chân dung, khung minimap); trước đó lần nhấn rơi vào chính
   chúng thay vì cửa sổ bên dưới.
3. Sau một lần nhấn trái bị huỷ (nút nhả ngoài cửa sổ, cửa sổ mất focus) thì lần bấm kế tiếp lên
   giao diện bị bỏ qua: `Display` chỉ gọi `click.cancel()`, để `is_left_held` còn bật nên giao
   diện không thấy cạnh lên của lần nhấn sau. Đã sửa (`cancel_left`). Tái hiện và kiểm:
   `python TOOLS/run/click_shot.py build/msvc-release/thienlong_client.exe --out <thư mục> --drop
   860,676 --click 860,676 --click 860,676 -- --scene huoyangu --data CLIENT/data`; ba ảnh phải
   lần lượt có, không có, có bảng hành trang (bản trước khi sửa: có, có, không).

`TOOLS/run/click_shot.py` (mới): chạy client, bấm theo danh sách điểm, chụp vùng chơi sau mỗi
bước. Cửa sổ client hiện mà không lấy focus, nằm ngoài màn hình và được chụp bằng `PrintWindow`,
vì bản đầu (cửa sổ trên màn hình, chụp từ màn hình) cho kết quả sai khi con trỏ thật nằm trên
vùng chơi và còn cướp bàn phím của người đang dùng máy (`AGENTS.md` mục 11).

Đã kiểm ngày 2026-10-08: `check.py` 0 lỗi trên 7 tệp C++ đã đổi của `gui` và `ui`;
`display_gpu.cpp` còn đúng 16 lỗi cổng như bản `0e6da48` (so trong một worktree tạm, phần sửa
không thêm lỗi). `msvc-release` 49/49 test, 0 cảnh báo; `clang-asan` 49/49; `gcc-debug` 39/40 ở
lượt đầu (`log_tests` hỏng heap, `NGHI-NGO.md` mục 12), chạy lại ca đó thì qua. Client thật, tám
lần bấm liên tiếp (mở ba bảng, đóng ba bảng bằng nút đóng, mở rồi đóng hành trang bằng nút của
thanh menu): cả tám ảnh đúng trạng thái, lớp kiểm tra GPU 0 lỗi.

`verify_ui.py` trên dữ liệu vừa gom lại: 5 mục đạt (cây XML, điểm ảnh texture, bao đóng kiểu tới
texture, sổ cửa sổ, bảng chuỗi), 3 mục đỏ. Hai mục đỏ vì 24 tệp con trỏ không có công cụ nào sinh
ra, có từ trước lát này (`NGHI-NGO.md` mục 35); mục 4b đỏ vì hai nền của cửa sổ 3D chưa được gom,
trong đó `Common/jpg_RoleBack.dds` là mới do bảng `SelfEquip` (`NGHI-NGO.md` mục 23).

Đã đo, để tối ưu sau: mỗi lượt chạy có mở bảng có đúng một khung dài 87–100 ms (bảy lượt: 86,9;
89,3; 87,9; 87,3; 88,6; 95,0; 99,5 ms), lượt không mở bảng thì khung dài nhất 9,0 ms. Chưa tìm bảng
nào và bước nào gây ra.

Chưa làm:

- Nội dung của bảng hành trang và bảng nhiệm vụ: còn là layout thô, chưa có trạng thái lúc mở
  của script, chưa có ô vật phẩm. Bảng nhân vật đã có ở mục kế tiếp.
- Sách kỹ năng (`Button_Skills`: `ToggleSkillBook` chọn giữa ba trang), trân thú, giao dịch, hảo
  hữu, tổ đội, danh vọng, hệ thống; phím tắt; kéo bảng; nhớ vị trí bảng.
- Chữ dài hơn vùng chữ của look (hẹp hơn ô của cửa sổ) chưa có bộ đo (`NGHI-NGO.md` mục 33).
- Chưa dựng lại APK với danh sách tệp giao diện mới; chưa chạy trên tablet.

## Giao diện: bảng nhân vật theo script của client 2026 (2026-10-08)

Bảng nhân vật (`SelfEquip`) mở ra với đúng trạng thái mà script của bản 2026 đặt lúc mở, đọc số từ
`hero::Hero`, thay cho layout thô (số mẫu 99999, mười sáu mặt nạ đỏ) của lát trước.

Đọc được script 2026. Trong kho `_raw` có 2047 tệp `Interface/**/*.lua`: 1821 tệp là văn bản GBK
thường, 226 tệp mã hoá (trong đó `SelfEquip`, `Packet`, `QuestLog`, `MainMenuBar`). Định dạng đã
đo: 8 byte dấu hiệu `D2 D1 E2 E1 B2 B1 C2 C1`, ba số u32 (1, 2, 16), bảng số tới hết byte 0xFF;
từ byte 0x100 là văn bản GBK XOR với khoá hai byte "AS" theo vị trí trong tệp (chẵn 'A', lẻ 'S').
24 byte đầu của văn bản còn một lớp khoá riêng từng tệp chưa giải được (thường là dòng chú thích
đầu tệp). Công cụ: `python TOOLS/content/lua_plain.py "F:/tl 2026/_raw" build/lua-2026` (đích
không vào git; đây là script gốc của game, chỉ để đọc khi port). Bằng chứng khoá đúng: phần giải
ra của `SelfEquip.lua` trùng từng byte với đầu tệp cùng tên của bản cũ từ byte thứ 24. Từ nay
port hành vi cửa sổ theo cây `build/lua-2026`, không theo script bản cũ ở `G:\TLBB\_content`.

Hàm C++ mà script gọi, đọc từ mã máy của `F:\tl 2026\Bin64\Game.exe` (không đóng gói; hàm Lua
đăng ký bằng `lea r8,[hàm]` ngay trước `lea rdx,[chuỗi tên]`; tháo bằng `llvm-objdump -d
--x86-asm-syntax=intel --start-address=... --stop-address=...`):

- `GetEquipDur` (0x140013a70): trả độ bền chia độ bền tối đa; ô trống trả 1.0.
- `IsLevelEnoughEquip` (0x140013eb0, phần chính 0x140012750): ô trống trả 1.
- `Lua_GetEquipZhiZunType` (0x140014bc0): ô trống trả -1.
- `Player:IsCanLevelup` (0x1403954d0): kinh nghiệm đang có không nhỏ hơn kinh nghiệm cần (so 64
  bit).

Nên với mọi ô trang bị trống, script giấu cả mười sáu mặt nạ nhắc và mười hai hoạt ảnh chí tôn.

Số của nhân vật mới lấy từ cấu hình máy chủ gốc: `Server/Config/DefaultChar.ini` (cấp 1, môn phái
9, sức mạnh 7, linh khí 6, thể lực 5, định lực 5, thân pháp 2, hoạt lực và tinh lực 10/50) và
dòng `[MENPAI9]` của `BaseValueTable.ini`, công thức của `Obj_Human_Attributes.cpp`:
`Float2Int((gốc + chỉ số x hệ số + cấp x hệ số) / 100)`, `Float2Int` làm tròn nửa lên. Ra máu 585,
khí 310, ngoại kích 56, nội kích 51, ngoại thủ và nội thủ 46, chính xác 38, né tránh 13, hai chỉ
số hội tâm 1. Các số này là `static_assert` trong `SRC/hero/hero.cpp`.

Mã:

- `hero`: `Hero` thêm môn phái, năm chỉ số gốc (`Roots`), điểm dư, tám chỉ số chiến đấu
  (`Combat`), phần tu luyện (`optional<Cultivation>`), hoạt lực, tinh lực, điểm trang bị, trần
  cấp, các mốc mở tính năng (`Milestones`), khoá lên cấp; `can_level_up`.
- `ui/panel/self_equip` (mới): `fill_self_equip` ghi chỉ thị của nhánh `OPEN_EQUIP`
  (`Equip_OnUpdateShow`, `Equip_RefreshEquip`, `SelfEquip_LevelupButtonShow`,
  `SelfEquip_LevelupLock_Update`, `SelfEquip_UpdateGemContainer`, `SelfEquip_ShowPage`): tên có
  màu, cấp theo mẫu từ điển, môn phái, máu/khí/nộ, kinh nghiệm, chỉ số, phần tu luyện `#H+n`,
  phòng thủ quá 999999 thành `??????`, nút cộng điểm mở khi còn điểm dư, nút lên cấp (cấp 119 bị
  giữ), khoá lên cấp từ cấp 30, ô bảo thạch chỉ còn nền, và mười sáu thẻ: thẻ chưa đủ cấp hay chưa
  đạt mốc thì khoá và hiện lớp che mang tooltip. `ui/hud` gọi nó khi bảng đang mở.
- `ui/panel/wording` (mới): `format_key` điền mẫu `%s0`, `%s1` của từ điển như
  `ScriptGlobal_Format("#{khoá}", ...)`.
- `collect_ui.py` gom thêm khoá `#{...}` mà mã `SRC/ui/panel/*.cpp` viết (script gốc đặt các chữ
  đó lúc chạy nên layout không nhắc tới): thêm 6 khoá, trong đó hai lời nhắc của bản đồ lớn
  (`KCJXL_130417_1`, `_3`) trước giờ không có trong bảng chuỗi nên không hiện. Bảng dịch thêm 6
  dòng; còn 0 khoá chưa dịch. Khoá `DFJY_250710_82` mà `MainMenuBar.layout.xml` dùng không có trong
  `StrDictionary.txt` của chính client gốc (bộ gom báo "thiếu 1" từ các lát trước).

Chỗ hỏng lộ ra khi nhìn ảnh chụp, đã sửa trong cùng lát: nhãn của mọi nút không đổi theo trạng
thái và không mang màu của look (thẻ khoá trông như thẻ mở, chữ nút nào cũng trắng). Nguyên nhân ở
`gui/text.cpp` (chép từ TLBB Dev): chữ của nút luôn lấy ở state `Enabled` hay `Normal`, và bỏ qua
`<Colours>` của Section trong StateImagery. CEGUI gốc (`FalagardButton::doButtonRender`,
`SectionSpecification::render`, `FalagardComponentBase::initColoursRect`,
`colour::calculateARGB`): nút vẽ StateImagery của đúng trạng thái đang có (không có thì
`Normal`), và màu cuối của từng thành phần là màu của nó nhân từng kênh với Colours của Section,
nhân số thực rồi cắt. Đã sửa theo mã gốc: `gui::modulate` (nhân với trắng giữ nguyên màu),
`detail::tinted` dùng chung cho khung, ảnh và chữ (trước đó ảnh lấy thẳng Colours thay vì nhân),
`detail::button_look_state` dùng chung cho ảnh và chữ của nút; bỏ nhánh "không có `Normal` thì vẽ
`Enabled`" vì gốc không có và không look nút nào của client cần tới (quét 230 kiểu nút: look nào
cũng có `Normal`, nhãn có ở mọi state). Trên client thật: thẻ đang chọn vàng `FFFF00`, thẻ mở
`FDEB78`, thẻ khoá xám `BBBBBB` kèm ảnh nền khoá; nhãn của các nút khác trong HUD cũng về màu của
look.

Đã kiểm ngày 2026-10-08: test đỏ trước, xanh sau (`gui_sheet_tests` thêm `label_follows_state` và
`section_colours_modulate`, sáu kỳ vọng đỏ trước khi sửa; `ui_board_tests` mới, 8 ca, có ca đối
chiếu mọi tên cửa sổ bảng nêu với layout thật; `hero_tests` thêm 2 ca; `gui_value_tests` thêm phép
nhân màu). `check.py` 0 lỗi trên 16 tệp C++ đã đổi. `msvc-release` 50/50 test, `clang-asan`
50/50, `gcc-debug` 41/41 (GCC trên Windows không dựng các module GPU nên ít hơn 9 test), 0 cảnh
báo. `ui_text_fit.py`: 0 nút tràn ô. Client thật
(`click_shot.py ... --click 260,676`): bảng hiện 585/585, 310/310, 0/1000, 7/6/5/5/2,
56/51/46/46/38/13/1/1, 10/50, "Cấp 1", "Vô Phái", không còn mặt nạ đỏ.

Chưa làm (chi tiết ở `NGHI-NGO.md` mục 36):

- Mô hình 3D của nhân vật giữa bảng (`SelfEquip_FakeObject:AttachWindowEx("Player")`) và hai nút
  xoay: cần ảnh fake object toàn thân.
- Bấm thẻ để sang trang khác, cộng điểm, lên cấp, tooltip, chấm đỏ nhắc việc.
- Nội dung bảng hành trang (`Packet.lua`, 954 dòng) và bảng nhiệm vụ (`QuestLog.lua`, 3939 dòng).
- Ô số liệu khung hình của bản dựng thử đè lên nửa trái của bảng khi bảng mở.

## Lỗi TLS của GCC MinGW đã chặn; test vòng kéo ra khỏi ctest thường ngày (2026-10-08)

Hai việc lộ ra khi chạy cổng của lát bảng nhân vật, làm xong trong cùng ngày.

`log_tests` của `gcc-debug` chết chập chờn 0xC0000374 (ba trên năm lượt hôm nay). Nguyên nhân đã
biết từ ngày 2026-10-07 (`NGHI-NGO.md` mục 12): GCC MinGW dùng TLS giả lập và trả bộ nhớ của biến
`thread_local` trước khi chạy destructor của nó. Sửa: `core::thread_slot` (`core/thread_slot.hpp`)
cho mọi biến `thread_local` có destructor mà bản GCC dựng (năm chỗ ở `core` và `window`); ở GCC
MinGW giá trị nằm trên heap và không bị huỷ, toolchain khác không đổi gì. Test đỏ trước, xanh sau:
`thread_slot_tests` (mới, ba ca) chết 6 trên 6 lượt khi `thread_slot` còn là `thread_local`
thường; sau khi sửa, `ctest --preset gcc-debug -R "^(log_tests|thread_slot_tests|core_tests)$"
--repeat until-fail:40` qua hai đợt liền. `window.cpp` còn một nợ cổng cũ (`apply_clip_owner` lồng
hai mức), tách `release_clip` cho phẳng.

Trong lúc lặp test để kiểm, tôi làm phiền người dùng máy: các ca vòng kéo của `window_tests` gửi
`SC_MOVE` thật, mỗi lượt kéo con trỏ chuột của họ về cửa sổ thử, đổi hình con trỏ và lấy focus;
hơn một nghìn lượt lặp là con trỏ nháy liên tục. Đã đo từng thứ bằng bộ canh (nay là
`TOOLS/run/desk_watch.py`) và sửa theo số đo:

- Kéo bằng bàn phím (`SC_MOVE` trần) dời vị trí con trỏ sáu lần mỗi lượt, kể cả khi tiến trình
  nằm trên desktop riêng hay window station không tương tác. Đổi sang kéo bằng chuột
  (`SC_MOVE | HTCAPTION`, đúng đường người dùng kéo cửa sổ): hết dời vị trí. Kiểu này chỉ sống khi
  nút trái đang giữ và Windows chờ 500 ms mới vào vòng, nên test đánh dấu nút trái trong trạng
  thái phím của riêng luồng và gửi kèm một `WM_MOUSEMOVE` (mỗi ca 65 ms thay vì 555 ms).
- Cho tiến trình test sang window station không tương tác (`tests/quiet_desktop.hpp`, tự chạy
  lại chính nó với `STARTUPINFO::lpDesktop`): không cửa sổ nào của test nằm trên desktop của
  người dùng, không đổi cửa sổ ở trước (150 lượt, 26.292 lần soi).
- Không chặn được: mỗi ca vẫn bật rồi tắt vùng giam con trỏ (1080 thành 1032 rồi về) và đổi hình
  con trỏ sang đồng hồ cát 15 tới 35 ms. Con trỏ là của cả phiên đăng nhập. Vì vậy sáu ca vòng
  kéo tách sang `window_modal_tests`: luôn dựng, `ctest` không chạy (`GAME_DESKTOP_TESTS` mặc
  định tắt), chạy tay một lượt khi sửa `SRC/window/window.cpp`.

Một lượt `ctest --preset msvc-release` thường ngày dưới bộ canh: 51 test chạy, vùng giam không
đổi, vị trí không nhảy, cửa sổ ở trước không đổi. Hình con trỏ đổi 16 lần trong lượt đó, nhưng mẫu
nền 10 giây không chạy gì cũng có 11 lần cùng kiểu (chính người dùng rê chuột), nên không quy
được cho test.

Lỗi chập chờn của chính các ca vòng kéo (vòng kết thúc trước nhịp đầu, khoảng 1 trên 150 lượt)
CHƯA tìm ra nguyên nhân; ghi ở `NGHI-NGO.md` mục 37.

Đã kiểm ngày 2026-10-08: `check.py` 0 lỗi trên 11 tệp C++ đã đổi hoặc thêm. `msvc-release` 51/51,
`clang-asan` 51/51, `gcc-debug` 42/42, 0 cảnh báo, `window_modal_tests` hiện "Disabled" ở cả ba.
`window_modal_tests` chạy tay một lượt trên bản MSVC: thoát 0. Chưa chạy `window_modal_tests` của
bản Clang và bản GCC (mỗi lượt là sáu lần con trỏ nháy; chỉ dựng).

Máy chủ: chủ dự án nêu cùng ngày rằng máy chủ thiết kế cho cả Linux và Windows. Đã ghi vào
`AGENTS.md` mục 0 và `docs/KE-HOACH-SERVER.md` mục 1 kèm thực trạng: bản POSIX mới qua kiểm cú
pháp bằng trình dịch NDK, chưa dựng và chưa chạy trên Linux lần nào (máy chưa có distro WSL).

## Camera và chuột theo mã máy của client 2026 (2026-10-08)

Yêu cầu của chủ dự án: tìm mã camera và mã chuột gốc rồi sửa cho giống hệt bản 2026. Mã gốc, địa
chỉ, hằng số và từng hành vi đã đọc ghi ở `docs/CAMERA-2026.md`; phần còn ngờ ở mục 38 của
`NGHI-NGO.md`.

Hai điều lộ ra trước khi sửa:

- Client đang chạy `camera::Rig` (ClientCamera của Loong, commit `83c87f4` đưa lại sau khi đã bỏ
  ngày 2026-10-06), không phải camera của Thiên Long. Không tệp nào của client 2026 có lớp đó
  (đã tìm RTTI và chuỗi trong `Game.exe`, `Render.dll`, `OgreMain.dll`, `tEngine.dll`).
- `control/follow_camera` của TLBB Dev theo mã nguồn 2008; bản 2026 đã khác: pitch kéo được và có
  giới hạn, zoom mượt qua đích, điểm nhìn cao 1,5 thay cho 0,7, khoảng zoom 6 đến 27,5, mặt cắt
  lấy theo cảnh, thêm kéo nút giữa, phím xoay bị bỏ.

Đã làm:

- `control/follow_camera`: port `CCamera_Scene` và các hàm `Camera_*` của `Render.dll`; mỗi hàm
  đặt gọi `update` ngay như bản gốc. Mắt vướng địa hình thì pitch tự dốc lên từng 1 độ
  (`CameraFit::kPitch`); cách chữa bằng khoảng cách của các cảnh đặc biệt (`kDistance`) có mã và
  test, chưa có cảnh nào dùng.
- `control/player_input`: `MouseTicker` là `CInputSystem::MouseTick` (bấm là nhả trong 500 ms và
  lệch không quá 4 điểm ảnh, kéo, giữ trái lặp sau 1000 ms, một sự kiện lăn mỗi nhịp); `Pilot` là
  phần chuột và camera của `CGamePro_Main` (kéo phải xoay và ngẩng cúi, ngưỡng 4 điểm ảnh ngang,
  chia 300; kéo nút giữa 0,25 độ mỗi điểm ảnh; lăn đổi đích zoom 0,1; nhả trái mới ra lệnh đi,
  cách nhau ít nhất 100 ms; giữ trái thì chạy theo con trỏ, mỗi 500 ms một lệnh; `ResetCamera`;
  tự chỉnh pitch khi đi, mặc định tắt).
- `control/ground`: `probe_sphere` trả ba kết quả như `_IsValidEye`.
- `client/display`: bỏ kính Loong; mỗi khung gom sự kiện của cửa sổ thành một mẫu chuột cho
  `Pilot`; vào cảnh như `CGamePro_Enter` (hướng 3,1415, zoom đã lưu, pitch theo zoom); đổi cảnh
  giữ zoom. `client/viewer`: nút giữa, ẩn và kéo con trỏ về chỗ cũ khi đang kéo camera, Shift +
  lăn không zoom.
- `client/map/book`, `client/world`: mặt cắt xa, gần của cảnh từ cột 16, 17 của bảng cảnh.
- Gỡ module `camera` (tám tệp) và test `loong_camera`. Gỡ `WaterCover`, `water_at`, `ray_water`
  của `client/map/liquid`: chỉ kính Loong gọi.
- `client/map/liquid` viết lại phần còn lại để qua cổng: bốn góc phần tư quanh đỉnh thành một
  bảng thay cho bốn hàm chép nhau. Bản mới ra đúng từng byte so với bản cũ trên 400 địa hình
  7 x 7 sinh ngẫu nhiên; ca `liquid_keeps_the_visit_order` chốt một địa hình mà đổi thứ tự nào
  cũng đỏ. Sửa hai chỗ hành vi không xác định với dữ liệu đọc từ tệp: chỗ đặt mặt nước quá xa
  hay NaN bị ép thẳng sang `int` (UBSan báo ở mã cũ), số khung `anim_texture` vô lý cũng vậy
  (trần 256; chất liệu của client nhiều nhất 40 khung). `build_liquid` và `find_liquid_look`
  vẫn chưa có đường vẽ nào gọi.
- Sáu tệp gắn `target("sse4.1")` cho cả đích ARM (`display_gpu.cpp`, `lighting.cpp`,
  `render/{camera,forward,shade}.cpp`, `tests/shade_tests.cpp`): thêm `defined(__x86_64__)`,
  bản dựng Android hết in `'+sse4.1' is not a recognized feature`.
- Công cụ: `TOOLS/port/pe_refs.py` (soi PE: chuỗi, tham chiếu, RTTI, tháo hàm, bảng nhảy, nơi gọi
  hàm ảo), `TOOLS/port/lua_native.py` (hàm C++ đăng ký cho một tên hàm Lua);
  `TOOLS/run/click_shot.py` thêm `--turn`, `--tilt`, `--wheel`.
- Nợ cổng trả vì chạm tệp: `client/display/display_gpu.cpp`, `client/map/liquid.cpp`, ba header
  `fx` (`field.hpp`, `mesh.hpp`, `system.hpp`).

Điều khiển trên PC bây giờ: kéo phải xoay và ngẩng cúi (con trỏ ẩn, đứng yên một chỗ); kéo nút
giữa chỉ ngẩng cúi; lăn chuột zoom mượt; nhấp trái đi tới điểm đất dưới con trỏ; giữ trái quá 1
giây chạy theo con trỏ. Phím của cửa sổ: mũi tên lên xuống là lệnh phím zoom của bản gốc, V là
`ResetCamera`; mũi tên trái phải (xoay 0,04 radian của bản 2008) và W A S D là phần thêm của cửa
sổ này, bản 2026 không có.

Đã kiểm trên cây cuối (2026-10-08):

- `msvc-release` 0 cảnh báo, 51/51 test; `clang-asan` (ASan + UBSan) 51/51; `gcc-debug` 42/42.
  `window_modal_tests` không nằm trong lượt thường ngày (mục 37 của `NGHI-NGO.md`).
- `check.py` 0 lỗi trên 26 tệp C++ của phần camera, và trên sáu tệp sửa pragma.
- `tests/pilot_tests.cpp` 17 ca mới. Đỏ trước trên mã cũ: ca điểm nhìn cao 1,5 và ca zoom gần
  nhất, ca đọc mặt cắt của bảng cảnh, ca chỗ đặt mặt nước ngoài bản đồ (UBSan). Đột biến đều đỏ:
  chia 200 thay 300, chốt tự chạy 250 ms, pitch gần 20 độ, ngưỡng kéo 3 điểm ảnh; chín đột biến
  của `liquid` qua `map_tests` (đột biến thứ mười, bỏ luật đỉnh biên, không dựng được dưới
  `-Werror` và bị bắt ở phép so 400 địa hình).
- `android-arm64`: `thienlong_activity` và tám test liên quan dựng được, 0 cảnh báo.
- Hai lượt client thật ngoài màn hình bằng `click_shot.py` dưới `desk_watch.py`, lượt sau với bản
  cài cuối: client thoát 0, lớp kiểm tra GPU 0 lỗi, 1777 khung, trung vị 8,3 ms, sau khi cảnh
  hiện không khung nào quá 11,5 ms. Ảnh: vào cảnh ở xa nhất nhìn xuống 40 độ, kéo phải xoay và
  dốc lên, năm nấc lăn kéo gần, kéo giữa ngẩng, nhấp trái đi (minimap 68,23 sang 74,19). Trình
  theo dõi: vùng giam con trỏ đổi 0 lần, con trỏ nhảy 0 lần, cửa sổ ở trước đổi 0 lần, một cửa
  sổ mới (chính client), hình con trỏ đổi 13 lần quanh lúc client mở và đóng. Mã cửa sổ chỉ gọi
  `SetCursor` khi con trỏ thật nằm trên vùng vẽ hoặc khi đang giam chuột lúc có focus, nên 13
  lần đó không quy được cho client; CHƯA tách được chúng là do giao diện VS Code dưới con trỏ
  hay do người dùng rê chuột (mẫu nền 14 giây lúc sau: 0 lần).

Chưa kiểm: đối chiếu với client 2026 đang chạy; APK và máy tính bảng (mục 38j của
`NGHI-NGO.md`); Linux không dính.

## Tối ưu khởi động client: hoãn, đã ghi số nền (2026-10-07)

Chủ dự án nêu mục tiêu "mở là lên ngay" rồi hoãn trong cùng ngày: viết mã cho xong client và máy
chủ trước, tối ưu sau. Số nền đã đo bằng bộ đo ngoài tiến trình, bản `msvc-release` ở `7e379d4`,
bộ đệm tệp ấm: cửa sổ hiện sau 39 ms, khung đầu có cảnh và giao diện sau 427 ms (Vulkan) và 516 ms
(GLES), tới khung đó đã đọc 19 MiB bằng hơn 5.400 lần đọc. Số đầy đủ, đường khởi động, chín chỗ
nghi, chỗ bộ đo chưa chắc và thứ tự làm khi quay lại: `docs/giao-viec/KD-DOT-1/GHI-CHU.md`. Bộ đo:
`docs/giao-viec/KD-DOT-1/kiem-claude/startup_probe.py`. Chưa có đề bài, chưa sửa dòng mã nào.

## Đã đưa vào git theo module (2026-10-05)

Chuỗi gpu, shader, fs, math, jobs, render, resource, capture và phần client được commit từng module.
Hai phần khép ở phiên chép:

- `client::stage_of` trích StaticEntity có mesh (đúng thứ tự tệp, phép đặt qua `placement_of`),
  đèn `type=directional` và ambient của Enviroment. `stage_tests` thoát 0 trên gcc-debug.
  `check.py` 0 lỗi trên `SRC/client/stage.cpp` và `tests/stage_tests.cpp`.
- Ảnh ngoài của GLB: `image_path` và `load_glb_file(path, root)` cho phép `../../Material/...` khi
  còn trong thư mục data, từ chối khi thoát khỏi data (kể cả sau giải mã phần trăm), và khi `root`
  rỗng thì giữ luật cũ (ảnh phải nằm trong thư mục GLB). `resource_tests` thoát 0 trên clang-asan
  (ASan + UBSan). `check.py` 0 lỗi trên `tests/resource_tests.cpp`. `SRC/resource/model.cpp` vẫn
  đỏ `check.py` vì độ lồng và tidy của bản chép, chưa dọn hết.

Module `resource` chỉ dựng khi `GAME_HAS_GPU` và `GAME_HAS_MATH`.

## Render Vulkan trên Android/iOS đã vào git (2026-10-05, commit 3480405)

- Chuỗi gpu/fs/shader/resource/render/capture/jobs biên dịch cho arm64-android: math arm64 qua
  sse2neon (vcpkg, `math/sse.hpp` của bản trước), fs thiết bị tối giản (buny/codec/path/stream),
  `model.cpp`/`package.cpp` đọc tệp qua `io` (bản POSIX của phiên trước), preset android qua
  vcpkg chainload NDK (`VCPKG_CHAINLOAD_TOOLCHAIN_FILE`).
- Loader Android API 29 không xuất tĩnh hàm lõi 1.2/1.3 → bảng `CoreLate` trong
  `gpu/vulkan/api.hpp` xin qua `vkGetInstanceProcAddr` sau `vkCreateInstance` (hợp đồng loader);
  Windows vẫn gọi trực tiếp. `retire.hpp` có `MoveOnlyCall` vì libc++ NDK 30 thiếu
  `std::move_only_function` (đo bằng `__cpp_lib_move_only_function`).
- `android_main` giải nén assets theo `manifest.txt` (AAssetDir của NDK KHÔNG liệt kê thư mục
  con — mất một lần đo mới biết) rồi dựng `Display` y hệt Windows; `package_apk.py` đóng
  `CLIENT/data` + gói `.f2s` (biến `GAME_ANDROID_SHADERS`) → APK 43,5 MB. Trên máy thật
  HA1RC00J chạy đúng tới kiểm Vulkan: probe OK, giải nén 65 tệp, `Display::create` báo
  "không thiết bị nào đạt Vulkan 1.3" → tô màu đặc đúng thiết kế.
- **Số đo thiết bị** (`TOOLS/android/probe_vulkan.cpp`, chạy qua adb): PowerVR Rogue GE8320,
  API 1.1.100, không có KHR_synchronization2/dynamic_rendering/timeline_semaphore. GPU này không
  thể chạy kiến trúc Vulkan 1.3 của engine; điện thoại Vulkan 1.3 (chip 2022+) chạy được ngay.
- iOS đủ mã chờ macOS: `surface_ios.mm` (VK_EXT_metal_surface qua CAMetalLayer, MoltenVK nhúng),
  `ios_main.mm` dựng `Display` trên lớp Metal, CMake gate `IOS` với framework Metal/QuartzCore.
- **Quyết định của chủ dự án (2026-10-05)**: Vulkan là backend chính, KHÔNG fallback tự động;
  GLES lấy từ `G:\TLBB\Dev` (dự án TLBB viết lại — Android bên đó mặc định GLES) về làm backend
  phụ chọn tường minh, để GPU cũ như GE8320 vẽ được. Việc cùng cỡ backend D3D12: hàng đợi.

## Client tách submodule (2026-10-05, commit 1cbe8e0 + ddca0fe)

- Bố cục cuối của client: `client/stage` (nội dung cảnh cần vẽ: stage, props), `client/display`
  (phần đồ hoạ: display_gpu/display_none), `client/viewer` (vòng lặp cửa sổ), `client/map` (render
  địa hình của phiên song song, namespace `game::client::map`), gốc client giữ options và các điểm
  vào. Mỗi submodule một target CMake (`game_client_stage`...), include `client/<con>/<tệp>`.
- `cmake/GameLayers.cmake` nhận module hai cấp "cha/con": dòng `game_layer_client/stage`...;
  include tên dài thắng tên ngắn; cha không quét lại module con; `detail/` và backend của gpu
  (`vulkan`, `d3d12`, `d3d11`, `gles`) quét chung cha. Module mới ở mức hai PHẢI có dòng
  `game_layer_cha/con`.
- Đã đi kèm: android activity nối `game_client_map`; `map_tests.cpp` theo namespace mới.
  gcc-debug 13/13, clang-asan 15/15 (thêm map_tests), android đóng APK 44,8 MB; worktree xác
  minh commit độc lập.

## Đường đi và vật cản theo `PathLib.dll` của client 2026 (2026-10-08)

Yêu cầu của chủ dự án: nhân vật leo được tường thành và vách núi dựng đứng; sửa, rồi làm đúng toàn bộ
địa hình của bản 2026. Nguồn, bố cục tệp, thuật toán kèm địa chỉ, lệnh trọng tài và số đo ở
`docs/DUONG-DI-2026.md`; phần còn ngờ ở mục 39 của `NGHI-NGO.md`.

Nguyên nhân: client chỉ có độ cao địa hình và mép bản đồ. Lệnh đi là một đường thẳng tới điểm nhấp
chuột, không hỏi chỗ nào bị chặn. Bản 2026 không dùng `.region` như client cũ mà giao tệp `.path` của
cảnh (lưới tam giác có cờ vật cản) cho `PathLib.dll`; mọi luật chặn và tìm đường chạy trên lưới đó.

Đã làm:

- `SRC/nav` (module mới, tầng `core nav`): `mesh` đọc `.path` (hai bản 0x2000 và 0x1000, mọi số đếm
  và chỉ số kiểm trước khi dùng); `finder` port `PathFinderImpl` (định vị, chỗ đoạn thẳng cắt cạnh vật
  cản, A* trên tam giác, kéo căng, né góc 0,1, tỉa điểm); `route` port `CPath` và phần chọn cách đi
  của `CAI_MySelf` trong `Game.exe` (nhấp chuột thì tìm đường, giữ chuột thì đi thẳng tới sát vật cản,
  đang kẹt trong vật cản thì chỉ được đi thẳng ra). Dựng với `-ffp-contract=off`.
- `TOOLS/port/pathlib_oracle.py`: nạp chính `PathLib.dll` và `tEngine.dll` gốc, ghi câu trả lời thành
  số vàng theo mẫu bit. `TOOLS/port/make_path_mesh.py`: lưới tự vẽ cho test chạy không cần dữ liệu
  client.
- `client/map/book` đọc cột thứ 6 của bảng cảnh (tệp `.path`); `client/world` nạp lưới vào
  `ShownScene::walk` và in một dòng "Lưới đi: ..." khi vào cảnh; `client/display`: lệnh đi là một dãy
  điểm (`WalkOrder::path`) lấy từ `nav::Field::plan_move`, phím đi và cần gạt dừng trước vật cản
  (`step_reach`), đổi cảnh thì bỏ lệnh đang chạy.

Đã kiểm (ngày 2026-10-08, trên cây đã định dạng lại theo trần 120 cột):

- `nav_tests` so từng bit với DLL gốc: lưới tự vẽ 200 định vị, 200 cắt cạnh, 402 tìm đường, 200 chỗ
  dừng; cảnh `huoyangu` 200, 200, 400, 200; lệch 0 dòng ở `gcc-debug`, `clang-asan`, `msvc-release`.
  `map_tests` (cột `.path`), `world_tests` (cảnh có lưới, lưới hỏng, thiếu tệp) và `layers` xanh ở ba
  preset; dựng 0 cảnh báo.
- Răng của test: 17 đột biến trong `SRC/nav`, 13 bị bắt; bốn cái sống ghi ở `docs/DUONG-DI-2026.md`.
- `check.py` đủ bộ trên bảy tệp của `nav` và test của nó: 0 lỗi.
- Client thật, một lượt ngoài màn hình (`click_shot.py` dưới `desk_watch.py`), cảnh `huoyangu`: log
  "Lưới đi: 416 đỉnh, 809 tam giác, 411 cạnh vật cản"; nhấp lên vách ở đầu hẻm thì nhân vật dừng ở
  (68, 16), hàng cuối còn đi được, không leo lên; nhấp vào vách trái thì dừng ở chân vách; client
  thoát 0, lớp kiểm tra GPU 0 lỗi, trung vị 8,3 ms.

Chưa xong:

- Mặt đi được của công trình (`.WCollision`: cầu, bậc thang, sàn đài) giao cho một phiên AI khác:
  `docs/giao-viec/DH-DOT-1/DE-BAI.md`, worktree `build/dh-dot-1`.
- Vùng cấm động, trạng thái bay, thuật toán dự phòng khi né góc, câu báo "không tới được": chưa port.
- Android: thư viện dựng chung mã, nhưng test số vàng không chạy trên thiết bị; chưa đóng APK.
- Trong lượt client trên, cửa sổ ngoài màn hình của client đã thành cửa sổ ở trước năm lần trong lúc
  chủ dự án Alt+Tab: `click_shot.py` phải cho cửa sổ ra khỏi danh sách Alt+Tab (mục 39 của
  `NGHI-NGO.md`).

Lệnh kiểm:

```
cmake --build --preset <p> --target nav_tests map_tests world_tests
ctest --preset <p> -R "^(nav_tests|map_tests|world_tests|layers)$"
python ~/.claude/cpp23/tools/check.py SRC/nav/mesh.hpp SRC/nav/mesh.cpp SRC/nav/finder.hpp SRC/nav/finder.cpp SRC/nav/route.hpp SRC/nav/route.cpp tests/nav_tests.cpp tests/nav_sample.hpp
```

## Trần 120 cột và luật hình dạng (2026-10-08)

Chủ dự án nâng trần cột của bộ quy cách cpp23 từ 100 lên 120 và thêm luật hình dạng: mỗi câu lệnh và
mỗi chữ ký nằm trọn một dòng, câu vượt trần thì rút gọn thiết kế chứ không bẻ dòng. Lý do và số đo của
trần mới ở đầu `.clang-format`; bảng nguyên nhân và cách chữa ở `~/.claude/CLAUDE.md`.

Đã làm:

- `.clang-format` (trần 120, hai điểm phạt chặn kiểu bẻ sau `(` và sau kiểu trả), `.editorconfig`,
  `.vscode/settings.json`. Bản chép bộ quy cách ở gốc dự án (`MAP.md`, `INDEX.md`, `README.md`,
  `refs/`) trùng từng byte với `D:\CLAUDE\cpp23` lúc 12:36 ngày 2026-10-08.
- Định dạng lại cả cây bằng clang-format 23: 335 tệp đổi, đo từng tệp thì bản mới đúng bằng
  clang-format của bản cũ, không có sửa đổi nào khác. Thêm hai tệp không sạch định dạng từ trước nên
  bị bỏ sót: `SRC/resource/model.cpp` và `SRC/gpu/vulkan/surface_android.cpp` (tệp sau giữ
  `vulkan_core.h` trước `vulkan_android.h` bằng một dòng comment ngắt khối include). Mọi tệp C++ dưới
  `SRC/` và `tests/` nay đứng yên dưới clang-format, trừ hai tệp `.mm`: cấu hình `Language: Cpp`
  không áp cho Objective-C++.
- Bộ sinh protocol tự bẻ dòng theo số 100 chép tay, nên lượt định dạng lại đã sửa hai tệp sinh và
  `protocol_catalog_fresh` đỏ. `TOOLS/server/protocol_cxx.py` nay đọc trần cột từ `.clang-format`,
  bảng `kParts` của tệp mẫu đi qua hàm bẻ dòng chung, ba tệp C++ sinh lại; ca
  `test_clang_format_keeps_generated_code` chạy clang-format thật trên đầu ra để canh.

Chưa xong:

- Luật hình dạng: 1.131 câu lệnh ở 250 tệp còn trải nhiều dòng (264 vòng lặp một lệnh thiếu ngoặc
  nhọn, 249 chữ ký bị bẻ, 232 lời gọi hoặc biểu thức bị bẻ, 217 khối khởi tạo nhiều dòng trong thân
  hàm, 129 vế phải xuống dòng, 28 điều kiện tràn dòng, 11 danh sách khởi tạo của constructor). Nặng
  nhất: `tests/gui_sheet_tests.cpp` 51, `SRC/gpu/d3d12/commands.cpp` 28, `SRC/resource/upload.cpp`
  26, `SRC/gpu/vulkan/commands.cpp` 25, `SRC/fx/field.cpp` 23. `check.py` vì thế đỏ ở bước "hình
  dạng" trên các tệp đó dù định dạng, độ lồng, biên dịch và clang-tidy sạch. Chữa từng module theo
  bảng nguyên nhân, mỗi tệp đang chạm thì chữa trọn tệp; `SRC/nav` và test của nó đã sạch. Một câu
  trong số đó nằm ở tệp sinh (`SRC/protocol/messages.hpp`, `using GameServerMessage =
  std::variant<…>`, khoảng 126 cột): phải chữa ở bộ sinh, và danh sách kiểu còn dài thêm theo danh
  mục tin.
- Dự án chưa có bản `cmake/check_shape.py` của riêng mình; đo bằng bản gốc của bộ quy cách.
- Năm tệp C++ làm vật chứng dưới `docs/giao-viec/P2-DOT-2/so-do/` giữ nguyên như lúc đo, không định
  dạng lại.

Lệnh đo:

```
python D:/CLAUDE/cpp23/templates/project/cmake/check_shape.py SRC tests
python -B TOOLS/server/gen_protocol.py --check
python -B -m unittest discover -s TOOLS/server -p "test_gen_protocol.py"
```

## Đã vào git (2026-10-05)

- `thienlong_shader` (nguồn `tools/shader/main.cpp`) dịch `SRC/render/shaders/shaders.list` lúc
  build. Lệnh build clang-asan in: DXC 1.9.5512, `[dịch] model.vs`, `[dịch] model.ps`,
  `2 dịch, 0 còn mới, 0 hỏng`. Gói nằm ở `build/clang-asan/shaders/` (`model.vs.f2s` 11228 byte,
  `model.ps.f2s` 8064 byte). `show` gói vertex thoát 0: cả spirv và dxil, cùng băm phản chiếu.
  `check.py` 0 lỗi trên `SRC/shadertool/main.cpp`.
- `Display` tạo `render::Forward` theo định dạng và số ảnh của `Screen`, rồi mỗi khung gọi
  `draw` với danh sách vật thể trống. `thienlong_client --scene huoyangu --data CLIENT/data
  --frames 2` in `Hiển thị: vulkan trên NVIDIA GeForce RTX 5060, có forward`, 2 vòng, lớp kiểm
  tra 0 lỗi, thoát 0. Màn vẫn là màu nền vì chưa có instance.
- Backend D3D12 của Forge2 (`SRC/gpu/d3d12`, 11 tệp) đã vào `game_gpu`. Macro `GAME_GPU_D3D12`
  bật. `check.py` 0 lỗi trên 11 tệp đó. `cmake --build --preset clang-asan --target gpu_tests
  --target header_check` thoát 0. `build/clang-asan/gpu_tests.exe` thoát 0: bốn ca, Vulkan và
  D3D12, mỗi bên tạo thiết bị có lớp kiểm tra rồi chép 256 byte qua GPU và đọc lại đúng, 0 lỗi
  kiểm tra. Cửa sổ client vẫn xin Vulkan (mặc định của `DeviceDesc`). Chưa chạy swapchain,
  pipeline hay present của D3D12. Chưa vẽ model.
- Backend D3D11 là fallback, không chép từ engine nào. Đã so Forge2, The Forge, Wicked, O3DE,
  Godot, RavEngine, Platium, Titan, No1, orio và DragonVN: không bản nào có RHI D3D11 cài
  `gpu::Device`. Mã D3D11 dùng được trên máy là bgfx `renderer_d3d11.cpp` (BSD-2, không đưa vào
  cây) và `FLydunglai` (một file vẽ da, không phải RHI). Backend mới ở `SRC/gpu/d3d11` lấy các lựa
  chọn đã đo của bgfx (feature level 11.1 rồi 11.0, flip-model rồi DISCARD, staging, info queue)
  và ghi deferred context cho từng luồng. `check.py` 0 lỗi trên 14 tệp `SRC/gpu/d3d11`. Cùng
  `gpu_tests.exe` lúc này là sáu ca: Vulkan, D3D12 và D3D11, mỗi bên tạo thiết bị có lớp kiểm tra
  rồi chép 256 byte qua GPU và đọc lại đúng, thoát 0. `create_present_device` chỉ thử backend sau
  khi backend trước trả `kUnsupported`. Gói `build/clang-asan/shaders/model.vs.f2s` (15568 byte)
  và `model.ps.f2s` (10660 byte) đều chứa DXBC và DXIL. Chưa present một khung D3D11 lên cửa sổ.
- iOS trong thiết kế của Forge2 là Metal. Backend Metal không có trong Forge2 và không có trong
  dự án này. Android là Vulkan.
- **Bước vẽ hình (B4 nạp + B5 vẽ, làm trọn cảnh thay vì một GLB)**. `client::table_of` (mới,
  `SRC/client/props.cpp`, có `tests/props_tests.cpp`) gom stage thành danh sách mesh duy nhất theo
  thứ tự gặp; `Display` nạp mỗi mesh đúng một lần (`Model/<tên>.glb`, ảnh ngoài qua `root` của
  thư mục dữ liệu), `upload` lên GPU rồi `prepare` thành Drawable, dựng instance cho cả 57 vật thể
  với ma trận T * R * S làm tròn float từ `world_transform` double. Mỗi khung: camera quay quanh
  hộp bao thế giới (bước quay theo thứ tự khung, tất định, không theo đồng hồ), đèn directional
  đầu tiên của cảnh (hướng OGRE đổi sang hướng TỚI đèn) và ambient trung bình ba kênh. `--shot
  <tệp.png>` chép khung đầu vẽ được ra buffer đọc ngược (hai rào Present↔CopySource quanh lệnh
  chép, cùng lần nộp với khung) rồi ghi PNG qua module `capture` (mới vào CMake, chỉ Windows cùng
  `jobs`). Chạy bản cài `CLIENT\bin\thienlong_client --scene huoyangu --frames 90 --shot ...`:
  `Nạp cảnh: 19 mesh dùng chung, 57 vật thể vẽ được`, 78 lệnh vẽ, lớp kiểm tra 0 lỗi, thoát 0; ảnh
  PNG 1280x720 nhìn thấy núi đá đỏ, rặng cột, tượng Phật, chuỗi tinh thể đỏ trên nền xám đúng màu
  xoá. `check.py` 0 lỗi trên mọi tệp đã đổi; ctest: clang-asan 13/13, gcc-debug 11/11, msvc-debug
  và msvc-release 13/13. Đèn directional thứ hai chưa vẽ (Forward một đèn, thuộc B6). Một lần
  `log_tests` trên gcc-debug thoát 0xc0000374 rồi pass lại bốn lần liên tiếp (đơn lẻ lẫn cả bộ):
  nghi flake của ca stress log tám luồng, chưa tái hiện có chủ đích; ghi mục 12 `NGHI-NGO.md`.
  Phiên vẽ hình cũng thêm prototypes cho `raise_thread`, `raise_critical`, `this_tid` của
  `core/clock.cpp` (bản sửa dở cùng lúc của phiên khác) để mọi preset dựng lại được: chỉ khai báo
  đặt trước định nghĩa, không đổi logic.

`SRC/shader/manifest.cpp`, `builder.cpp`, `dxil.cpp` chỉ sửa để Clang `-Werror` biên dịch được
(ép kiểu khoảng cách iterator, đủ trường khởi tạo có tên). `verify.py --nesting` vẫn báo 20 chỗ
lồng sẵn của bản chép. `compiler.cpp` không sửa; Clang tắt `-Wlanguage-extension-token` vì COM
của DXC dùng `__uuidof`. Bước kế để có hình: nạp một GLB, `upload`, `prepare`, một
`Instance`. Chưa làm ở bước D3D12 này.

## Thủ tục đăng nhập, phần 1 và 2: màn đăng nhập; bản địa hoá dựng cùng client (2026-10-08)

Chủ dự án giao làm luồng từ lúc mở client (giao diện client và máy chủ), xong từng phần một. Luồng
gốc của client 2026, đọc từ script và mã máy: `CGamePro_Login::Init` (`Game.exe` 0x140630900) tắt
màn chờ nạp (`BGINFO_CLOSE`, 0x1a2), ép cửa sổ về vùng chơi 1280 x 720 (0x140631270), nạp cảnh nền
`erengu_DL.Scene` qua hệ vẽ rồi đặt camera cố định, rồi các bảng `SelectServer`
(`GAMELOGIN_OPEN_SELECT_SERVER`, 0x118), `LogOn` (`GAMELOGIN_OPEN_COUNT_INPUT`, 0x11a),
`SelectRole`, `CreateRole`. Sáu phần đã chia: (1) bảng nhập tài khoản, (2) bàn phím và ô nhập chữ,
(3) máy chủ mở cổng và client quay số, (4) tài khoản thật qua `auth` và PostgreSQL, (5) chọn và tạo
nhân vật, (6) vào game qua máy chủ. Phần 5 đã làm cục bộ, không qua máy chủ; phần 3, 4 và 6 chưa.

Đã làm (chạy bằng `thienlong_client --login`; cờ tạm tới khi đây là đường mở mặc định):

- `ui/panel/logon` (mới): trạng thái của bảng theo `LogOn.lua` bản 2026: hai thẻ kiểu tài khoản,
  dòng nhắc, thẻ mã QR, ô thẻ bảo mật, ô đang nhận phím, chữ gõ vào ba ô (ASCII in được, trần 50 và
  32 ký tự của layout, xoá lùi, Tab đổi ô, Enter), và việc mỗi nút nhờ client làm
  (`LogonAction`, lấy bằng `take_request`). `SystemSetup:IsClassic` luôn trả 1 (`Game.exe`
  0x14045fbb0).
- Đường đi của phím và nút: `WM_CHAR` ở `client/viewer` thành `control::InputKind::kText`, qua
  `Display::input` tới `ui::Hud` (`HudView::typed`); việc của nút đi ngược lại bằng
  `Hud::take_action`, `Display::take_requests` (`client::Request`) tới vòng cửa sổ.
- Các nút: "Vào Game" (và Enter ở ô mật khẩu) khi tài khoản và mật khẩu đều đã gõ thì mở bảng chọn
  nhân vật, CHƯA kiểm tài khoản với máy chủ nào. Chọn một nhân vật rồi mới vào cảnh của `--scene`,
  `--resid` hay `Config/startup.id` (`Display::play`); "Nạp Thẻ", "Đăng Ký", "Quên MK", "Gắn
  Thẻ" mở trang web, "Giúp" tạm mở trang web (bản gốc mở bảng Helper); mọi trang hiện là trang
  "Coming soon" đi kèm bản dựng (`Web/coming_soon.html`, chủ dự án chốt cho nút nạp thẻ; mở bằng
  `io::open_in_browser`, mới có trên Windows); "Quay Lại" đóng client (bản gốc về màn chọn máy
  chủ, chưa có).
- Nền: cảnh `erengu_DL` nạp dần như một cảnh chơi (`ViewerDesc::backdrop`), nhìn bằng camera cố
  định port từ `Render.dll` 0x180002a30 (`control/login_view.hpp`, `render::posed_camera`; mục "Màn
  đăng nhập" của `docs/CAMERA-2026.md`). Hàm `Tick` của thủ tục đăng nhập (`Game.exe` 0x140630bc0)
  không đụng camera: camera đứng yên là đúng bản gốc.
- Cửa sổ đăng nhập luôn 1280 x 720 kể cả khi có `--size`.
- Ô nhập: dòng chữ và con nháy nằm giữa chiều cao ô như `FalagardIMEEditBox` của mã 2008
  (`gui/text.cpp`); trước đó con nháy thò ra dưới ô một điểm ảnh.
- Bàn phím ảo (nút `LogOn_Keyboard` bật cửa sổ `SoftKeyBoard`), port từ mã máy lớp
  `FalagardSoftKeyBoard` của `CEGUIFalagard.dll` bản 2026 (`setKeyPosition` 0x180080d90,
  `resetAllPosition` 0x18007eb80, `ResetAllKey` 0x18007d200, `populateRenderCache` 0x18007e220,
  `onMouseButtonUp` 0x18007e0b0; tìm bằng `pe_refs.py exports "FalagardSoftKeyBoard@"`):
  - `gui/softkey` (bộ vẽ, kiểu cửa sổ `Kind::kSoftKeys`): lưới 15 cột, 5 hàng, bước bằng cỡ phím
    cộng 1 (mã 2008 không có cộng 1); 68 ô ký tự mỗi ô một ảnh nền, ba phím lớn (xoá lùi, Shift,
    Return) mỗi phím một ảnh rộng hai phím, Return cao hai hàng; phím dưới chuột vẽ đè ảnh trỏ hay
    ảnh nhấn; chữ của phím theo Override `Keys`; `Hub::soft_key` đổi một điểm ra chỉ số ô. Hub dựng
    lại trang động khi chuột sang phím khác, không dựng lại khi chuột nhích trong một phím.
  - `ui/panel/softkey` (trạng thái): mở, đóng, Shift, và ô bắt đầu của ba nhóm ký tự (số, chữ, dấu)
    lấy ngẫu nhiên lại sau mỗi lần gõ hay bấm Shift như `ResetAllKey`. Return không làm gì: sự
    kiện `ReturnPush` của nó không có ai nghe trong cả `Bin64`.
  - Bảng đăng nhập có ô ngắm riêng với ô đang nhận phím, như `SetSoftKeyAim` của `LogOn.lua`: nút
    bàn phím ngắm ô mật khẩu, bấm vào ô nào thì ngắm ô đó; rời màn đăng nhập thì bàn phím đóng.
  - Chữ người chơi gõ và chữ mặt phím là nguyên văn (`TextRun::is_plain`): dấu `#` không thành thẻ
    màu. Trước đó gõ `#c` vào ô tài khoản bị bộ vẽ chữ coi là thẻ.
  - Chỗ còn khác bản gốc ghi ở mục 40(h) của `NGHI-NGO.md` (phím ăn lúc nhấn, ảnh tiêu đề còn chữ
    Hán, chưa kéo được cửa sổ, nút trợ giúp).
- Lỗi lộ ra khi khảo sát cảnh nền, đã sửa: `CMakeLists.txt` chép tay bốn tên gói shader nên
  `fx.vs.f2s`, `fx.ps.f2s` được dịch mà không được cài, bản `CLIENT/bin` không vẽ hạt nào và không
  báo gì. Danh sách gói giờ lấy thẳng từ `SRC/render/shaders/shaders.list`.
- `resource/upload.cpp` trả hết nợ hình dạng và 43 chẩn đoán clang-tidy (ngữ cảnh một lần tải gom
  vào lớp `Transfer`, nướng mip đọc ghi qua `std::span`), hành vi giữ nguyên từng byte so với bản
  trước. Test thường trực mới `resource_upload_tests` (9 ca trên thiết bị giả viết tay ở
  `tests/resource_upload_device.hpp`): thứ tự lời gọi thiết bị, thứ tự trả tay nắm, tiêm lỗi vào
  từng lời gọi, bảng vàng mip của 16 cỡ ảnh (sinh lại: `resource_upload_tests.exe --golden`). Số
  đo span so với con trỏ ghi ở comment đầu tệp. Lỗi sót của lượt này, đã sửa: `msvc-debug` không
  dựng được vì C4702 ở `encode_channel` (xem bẫy trong `AGENTS.md`).
- `build_i18n.py` giữ dấu `Table/i18n.applied.tsv` trong thư mục dữ liệu: xoá `build/i18n` lúc atlas
  đang mang ảnh thay thì lượt dựng kế dừng và nêu lệnh gom lại, không coi ảnh đã thay là bản gốc.
- Ảnh nút tiếng Việt: chữ lấy từ tấm nút chủ dự án đưa, đặt lên đúng nền nút gốc bằng
  `TOOLS/content/letter_buttons.py` (ba thẻ 88 x 17, nút vào game 132 x 54). Thay cả nút bằng nút vẽ
  kiểu khác thì lệch khung (chủ dự án thấy trên cửa sổ thật).
- Lỗi lộ ra khi bấm thử, đã sửa: luồng vẽ chỉ lấy sự kiện chuột khi cảnh có mặt đất, nên ở thủ tục
  đăng nhập không cú bấm nào tới giao diện (`Display::State::idle_view`).
- Nạp cảnh nhanh hơn, cho mọi cảnh: chuỗi mip của ảnh nướng ở các luồng nạp thay vì tuần tự trên
  luồng vẽ (`resource::stage_images`, `upload_queued` nhận chuỗi đã nướng), ảnh cọ của mặt đất giải
  mã song song. Số đo ở `docs/giao-viec/KD-DOT-1/GHI-CHU.md` mục 6.
- Trả nợ hình dạng ở các tệp chạm tới: `hud.cpp`, `display_gpu.cpp`, `painter.cpp`, `main.cpp`,
  `options.cpp`, `viewer_win32.cpp`, `camera.cpp`, `gui/text.cpp`, `tests/gui_sheet_tests.cpp` (51
  chỗ), `tests/resource_tests.cpp`, `tests/camera_tests.cpp`.

Bản địa hoá (chủ dự án chốt cùng ngày): ngôn ngữ chọn lúc dựng bằng `GAME_LANGUAGE` của CMake, bản
triển khai chỉ chứa chữ và ảnh của ngôn ngữ đó, client không chọn ngôn ngữ lúc chạy.

- Nguồn của một ngôn ngữ là một tệp `assets/i18n/<mã>.tsv` (chuỗi giao diện, `scene/<tên cảnh>`,
  `image/<bộ ảnh>/<tên ảnh>`, `file/<đường dẫn trong dữ liệu>`) kèm tệp ở `assets/i18n/<mã>/`.
  `assets/i18n/vi.tsv` gộp hai bảng cũ của `TOOLS/content/lang` (đã bỏ): 281 chuỗi, 241 tên cảnh,
  13 ảnh, 1 tệp.
- `TOOLS/content/build_i18n.py` chạy ở mỗi lượt dựng client (target `thienlong_i18n`,
  `cmake/GameI18n.cmake`): ghi `Table/ui_strings.lang.tsv`, `Table/scene_names.lang.tsv`, thay ảnh
  ngay trong atlas của `CLIENT/data/Interface`, chép các tệp `file/`. Atlas gốc giữ ở
  `build/i18n/base`, sổ băm ở `build/i18n/atlases.tsv`, mốc `build/i18n/deployed.stamp` để APK đóng
  lại ngay trong lượt dựng vừa đổi chữ hay ảnh. Hai ô ảnh chồng nhau trong atlas (bộ ảnh gốc khai
  `Logon_Erweima_Pushed` lệch một hàng) phải giống nhau ở phần chung.
- `collect_ui.py` không ghi bảng dịch nữa, chỉ báo khoá chưa dịch; `verify_ui.py --i18n build/i18n`
  so bản gốc của atlas đã thay ảnh với kho gốc.
- `TOOLS/content/export_layout_images.py`: xuất ảnh mà các cửa sổ của một layout dùng ra từng tệp
  kèm danh sách ô và tấm ghép có tên, cỡ, để làm bản thay thế.

Đã kiểm ngày 2026-10-08: `ui_logon_tests` 11 ca, `gui_sheet_tests` (ca ô nhập đỏ trước xanh sau),
`camera_tests` thêm 2 ca, `resource_tests` thêm 1 ca, `io_tests` thêm 1 ca, `client_tests` thêm 2
ca, `i18n_tool_tests` 13 ca; `gcc-debug` 52/52, `msvc-release` 61/61, `clang-asan` 61/61 (lượt
ASan chạy trước phần nướng mip sẵn), `android-arm64` dựng 418 bước 0 cảnh báo (trước phần gõ chữ
và nút). Client thật: chủ dự án bấm bốn nút web trên cửa sổ thật, log ghi bốn lần mở trang; chuỗi
gõ tài khoản, Tab, gõ mật khẩu, bấm "Vào Game" chạy ngoài màn hình bằng `click_shot.py --type` vào
tới Hỏa Diệm Cốc, lớp kiểm tra GPU 0 lỗi. Từ phần 5 bên dưới, cùng cú bấm dừng ở bảng chọn nhân vật.

Đã kiểm thêm cho bàn phím ảo (cùng ngày): `gui_softkey_tests` 7 ca và `ui_softkey_tests` 11 ca,
`ui_logon_tests` thêm 2 ca, `ui_text_tests` thêm 1 ca, ca ô nhập của `gui_sheet_tests` thêm kỳ vọng
chữ nguyên văn; mọi ca đỏ trước khi nối, xanh sau. Thử đột biến: 15 chỗ ở `gui` (lượt đầu 3 chỗ
sống sót, đã thêm test mép phải, mép dưới của ô phím và nút nằm đè lên bàn phím; lượt sau cả 15 bị
bắt), 8 chỗ ở `ui/panel` (7 bị test bắt, 1 bị trình dịch chặn). `tests/golden/ui_rects.tsv` sinh
lại bằng `ui_rects.py`: thêm đúng 36 dòng của 9 cửa sổ `SoftKeyBoard` ở bốn cỡ màn hình, dòng cũ
không đổi. Cây hoàn chỉnh (bàn phím ảo, hiệu ứng 2026, `upload.cpp` đã làm phẳng): `gcc-debug`
54/54, `clang-asan` 64/64, `msvc-release` 64/64, `msvc-debug` dựng 615 bước, tất cả 0 cảnh báo;
`check.py` 0 lỗi trên 13 tệp `gui` và `ui` đã chạm, 5 tệp `fx` và `fx_view`, `upload.cpp`. Client thật chạy ngoài màn hình bằng `click_shot.py` (11 lần bấm): mở bàn phím,
bốn phím vào ô mật khẩu, Shift ra chữ hoa, xoá lùi bớt một, bấm ô tài khoản rồi gõ ra `J4` ở ô tài
khoản, đóng bằng nút X; sau khi cảnh hiện, cả 1643 khung của lượt đó dưới 8,4 ms (kể cả khung mở
bàn phím lần đầu), lớp kiểm tra GPU 0 lỗi. `ls CLIENT/bin/shaders` sau khi cài: đủ 6 gói.

Chọn và tạo nhân vật, phần 5 làm cục bộ (2026-10-08): "Vào Game" không còn nhảy thẳng vào cảnh.
`ui/panel` giữ sổ (`roles`), bảng chọn (`select_role`), bảng tạo (`create_role`) và chuỗi
(`login_flow`). Sổ là TSV phiên bản 1 ở `CLIENT/data/Save/roles.tsv`, chung mọi tài khoản, không
lưu mật khẩu. Nhân vật mới cấp 1, môn 9. Mặt và tóc lấy từ cột creatable của bảng ngoại hình; chân
dung nam không trùng id mặt nam nên rơi về hàng chân dung nam đầu (id 13) khi mặt không có ảnh.
Vào game thì `apply_role` ghi tên, cấp, môn, chân dung và `Look` mặt/tóc vào người chơi. Layout
`SelectRole` và `CreateRole` nằm trong `CLIENT/data`; `tests/golden/ui_rects.tsv` là 28 layout.
Cửa sổ tạo vẽ người toàn thân (`role_preview`, fake object của script). Khác gốc ghi ở mục
40(e) của `NGHI-NGO.md`.

Đã kiểm phần 5: `ui_role_tests`, `ui_select_tests`, `ui_create_tests`, `ui_flow_tests` và
`ui_logon_tests`, `ui_panel_tests` xanh trên `gcc-debug`. `check.py` (GCC, Clang, clang-tidy) xanh
trên `roles.cpp`, `select_role.cpp`, `create_role.cpp`, `login_flow.cpp`, `sect.hpp`,
`self_equip.cpp`, `hud.cpp`, `login_data.cpp`. `msvc-release` dựng `thienlong_client` 0 cảnh báo.
`click_shot.py` ngoài màn hình: gõ tài khoản, "Vào Game" ra bảng chọn còn trống, "Tạo nhân vật",
gõ tên `Lang`, nút tạo quay về ô `Lang` / Vô Phái / cấp 1, "Vào Game" vào Hỏa Diệm Cốc với tên
`Lang` và chân dung nữ; lớp kiểm tra GPU 0 lỗi. Mở lại `--login` cùng tài khoản thì ô `Lang` còn.
Tệp sổ có dòng `ten`, giới 0, mặt 1, tóc 1, cấp 1, môn 9.

Màn tạo nhân vật: người mẫu trong cảnh 3D, camera, phóng, người mẫu môn phái (2026-10-09, sau đoạn
dưới; chưa commit). Chủ dự án hỏi ba điều: bản 2026 có camera 3D ở khâu tạo không, người mẫu có hoạt
ảnh không, vì sao mọi nhân vật nam "hơi ngước lên trời"; rồi yêu cầu "phân tích được bao nhiêu trong
Render.dll thì lấy đủ bấy nhiêu", "không viết test logic nữa, để tôi test tay".

- ĐÃ XONG, đã dựng `msvc-release` 0 cảnh báo, cài `CLIENT/bin`, chủ dự án đang thử tay:
  - Người mẫu đứng trong cảnh `tl3chuangjian` ở (818, 1064, 3033), tỉ lệ 1,5, không còn vẽ trong
    cửa sổ `CreateRole_Model` (`ShownModel::is_creating`, `Stand::scale`, `RoleShot` bỏ canvas).
  - `control::CharCamera` (`SRC/control/char_camera.*`): port trọn `CCamera_CharSel` của `Render.dll`
    (bốn track, chạy xuôi ngược, giữ, phóng hai chế độ, cờ đang chạy), nội suy theo OGRE của client
    (`ogre::quat_slerp`, `quat_log`, `quat_exp`, `quat_squad`, `quat_z_axis` mới). `client::RoleStage`
    (`SRC/client/display/role_stage.*`) là phần thủ tục: vào màn, `ChangeNewRoleEquipSet`, nút phóng,
    con lăn, đổi ô của bảng chọn (camera chạy spline giữa ba ô).
  - Hướng mặt người mẫu theo `ShowModel` gốc: mỗi giới một hướng, đặt lại khi người mẫu đổi
    (`settle_models` của `create_role.cpp`, `LoginFlow::create_yaw`).
  - Người mẫu xem trước môn phái: 30 mẫu của `CharModelEx` 4950..4979, bảng
    `Table/sect_models.tsv` (`export_look.py`), lưới và xương gom bằng `collect_avatar.py`
    (`look::sect_figure`, `PlayerDesc::sect`); mẫu múa bài `演武` một lần lúc hiện rồi đứng, mười hai
    môn đầu thỉnh thoảng múa lại.
  - Nguyên nhân "nam ngước lên trời": clip đứng của nam trong dữ liệu ngẩng cằm 12 đến 15 độ so với
    bind, camera cũ đặt ngang thắt lưng; camera gốc ngang tầm mắt, cúi 5 độ. Bộ tài nguyên `_iv`
    (đầu thẳng) không được `Game.exe` dùng. Số đo và địa chỉ: mục 8 của `docs/TAO-NHAN-VAT-2026.md`.
- CHỦ DỰ ÁN THỬ TAY RỒI BÁO CÒN THIẾU (2026-10-09, chưa làm): (1) môn phái dưới cùng của danh sách
  chưa có; (2) không có hiệu ứng tuyệt chiêu khi múa (skill của ba môn cuối và hiệu ứng gắn vũ khí
  trong khối `Effects` của mẫu chưa vẽ; cần xem `演武` của mười hai môn đầu có hiệu ứng từ đâu); (3)
  không thấy vũ khí (log không báo bỏ lưới nào: chưa biết lưới vũ khí vẽ sai chỗ hay thiếu material);
  (4) phần mô tả môn phái có môn có, môn không; (5) ô mô tả không cuộn lên xuống được; (6) chưa có
  hiệu ứng chuyển cảnh ở đâu cả (`Render.dll` có post filter `Fade` và `FadeColor`, tên ở
  `0x1802c03a8`, hàm dùng ở `0x180021700`, `0x180028000`; chưa tháo). Yêu cầu: "port toàn bộ chính
  xác tuyệt đối phần này".
- Sau khi chủ dự án thử tay lần hai (2026-10-09): ảnh tên môn phái của khung giới thiệu hiện đủ 15
  môn (`collect_ui.py` nay gom cả ảnh `set:... image:...` viết trong `SRC/ui/panel/*.cpp`; giao diện
  nạp trọn các bộ ảnh của `panel::create_imagesets`); cú bấm vào khung chữ giới thiệu góc dưới trái
  đi xuống nút Thiếu Lâm bị khung đó đè ở vùng vẽ cao 720 (về sau khung này tắt hẳn, xem mục kế);
  dòng nhắc `XZRW_XML_12` rút ngắn cho vừa ô 154 điểm; mẫu nam cơ bản cúi mặt thêm 10,8 độ ở clip
  đứng tay không theo lời chủ dự án (`look::BoneTrim`, khác gốc). Ô mô tả `Createshow_Info2` rộng
  144 cao 180: bản gốc (phông 12, bước dòng 17) vừa khít 11 đến 12 dòng, phông tiếng Việt cỡ 14
  bước dòng 19 chỉ chứa 9 dòng (đo bằng `TOOLS/port/text_wrap_sim.py`). Lần đầu Claude rút mười lăm
  đoạn mô tả xuống 9 dòng; chủ dự án bác ("Code tạo khung trượt ở đó để chứa đủ chữ"), xem mục kế.
- Sau khi chủ dự án thử tay lần ba (2026-10-09, chiều):
  - Ô mô tả môn phái là khung cuộn chữ (`gui::TextScroll`, khác gốc): mười lăm đoạn mô tả trả về bản
    đủ (10 đến 12 dòng); chữ dài hơn ô thì nghỉ 4 giây, trôi lên 10 điểm mỗi giây theo phần lẻ điểm
    ảnh, nghỉ, về đầu; chuột nằm trên khung thì chữ đứng yên, mỗi nấc lăn dời 18 điểm và camera
    không phóng (`panel::roll_detail`, `Hud::takes_wheel`). Không có thanh cuộn, theo lời chủ dự án.
  - Lỗi gặp trên đường, đã sửa: `Hud::prepare` chưa từng đưa `Place::meter` cho bộ dàn trang, nên
    trong client danh sách và cửa sổ phức hợp không có mục nào, khung cuộn không bật. Nay đưa
    `TextWriter` của chính HUD.
  - Khung chữ góc dưới trái (`Createshow_Info_Back`: lời mời xem trước, câu đối viết bằng chữ thường,
    dòng sở trường, dòng cấp 10) tắt hẳn theo lời chủ dự án; bảng vẫn đặt chữ cho nó như script gốc.
    `panel::covered_button` và `Hud::State::window_at` vì thế đã gỡ.
  - Nút, tiêu đề, nhãn và câu đối của màn tạo (75 mảnh ảnh của 9 atlas) có chữ Việt, một kiểu chữ:
    `TOOLS/content/letter_labels.py` dựng chữ bằng phông Merienda Bold (OFL, nét trùng chữ của tấm
    nút chủ dự án vẽ; `assets/i18n/vi/source/NGUON.txt`) lên đúng nền gốc theo bảng
    `assets/i18n/vi/source/labels.tsv`, ghi `assets/i18n/vi/labels/` và khối dòng `image/...` của
    `vi.tsv` (`--sync`). Chữ dài thì dùng từ Hán Việt ngắn (lời chủ dự án): "Giới Thiệu", "Môn
    Phái", "Huỷ Xem", "Y Phục".
  - ĐANG DỞ, chủ dự án bảo để đó (2026-10-09): thay chữ cho mọi ảnh có chữ Hán của cả giao diện. Đã
    kiểm kê bằng tấm ghép 667 mảnh mà 43 layout và mã bảng dùng: ngoài màn tạo còn chừng 180 mảnh,
    chia nhóm: (a) nút chữ nhật: `Button13/HelpBtn_*`, `PayBtn_*`, `Button8/MiniMap_AutoSearch_*`,
    `CommonFrame20/SafeCenter_*`, `CustomMail_*`, `ZidingyiMail_*`, `CommonItem/Chongzhibtn_*`,
    `Duihuanbtn_*`, `MissionAtrack/MKAcceptMission_*`, `MKCurrentMission_*`, `MK_Mission`,
    `MainFrameLuo01/Softkeyboard`, `LevelUpLock/LevelUpLock_Opening`, `ImageButtons/*`,
    `ZongMenSkill/ZongMenSkill_PataEnter_*`, `MainFrameLuo03/CreateRole_*`, `DelRole_*`, đầu của
    `MainFrameLuo04/SelectRoleBKG1`; (b) thẻ dọc `AutoFight/*` (chữ phải xoay 90 độ); (c) nút tròn
    một chữ: `AutoAttack_Button/*`, `Button13/Community_*`, `CommonFrame11/Xuan_*`,
    `CommonFrame15/DiaoIcon_*`, `CommonFrame2/FenIcon_*`, `XinNiuIcon_*`,
    `CommonFrame3/TragetProperty0..6`, `CommonFrame39/Fenxian_*`, `Xian_Button_*`,
    `CommonFrame5/YouLongKaBtn_*`, `CommonFrame6/TuJian_*`, `CommonFrame7/XunIcon_*`,
    `Face_Authentication/*`, `TServerUI2/Bang_Xuanzhan_*`, `Button6/PetAttack_Type1`; (d) mười hai
    con giáp `CommonStaticImage/Minimap_Time1..12` (20 x 20); (e) tên phe ở khung mục tiêu, 37 x 18:
    `CommonFrame4/TragetCamp_*` (33), `CommonFrame39/TragetCamp_ERenGu`, `KVKLeague_UI04/*` (5),
    cuộn dọc `CommonFrame3/TragetCamp`; (f) huy hiệu sự kiện có chữ lẫn trong hình: `XSHLY01/*`,
    `XSYNew02/*`, `KJRK_3/ButtonSCJL_*`, `Pretty01/*`, `SectTitle/SectTitle_M0_*`,
    `MainFrame3/MainFrame3_12`, `_13`. Công cụ cần thêm cho các nhóm này: mặt nạ theo ô và ngưỡng
    riêng từng loại (nền đồng, nền xám), chữ xoay, ép ngang chữ dài, tô lại hình tròn. Ảnh `_Hover`
    và `_Disabled` của nút môn phái không cửa sổ nào dùng nên còn chữ Hán.
- Bảng đo khung hình (chữ chẩn đoán của dự án, client gốc không có) mặc định ẩn từ 2026-10-09 theo
  lời chủ dự án, rồi mặc định hiện từ 2026-10-14 ("hiển thị bảng thông số bật tắt bằng f3"); F3 bật tắt trên
  Windows (đổi từ F11), `--no-pace` tắt từ đầu (`Steering::toggles_pace`). Android và iOS chưa có cách
  bật: cần đo trên máy tính bảng thì phải thêm một thao tác chạm.
- Bảng chuyển cảnh (2026-10-09, sau commit tạm `4bfb14a`): `ui/panel/scene_trans` là bản dịch của
  `SceneTrans.lua`; `Display::State::scene_load` báo cho HUD cảnh của màn chơi đang nạp (tên và
  phần mesh đã đặt), HUD phát ba sự kiện của script từ đó. Layout `SceneTrans` gom thêm (số vàng
  `tests/golden/ui_rects.tsv` thành 44 layout, chỉ thêm 12 dòng của layout mới); hai mẫu chữ của
  script dịch ở `vi.tsv` ("Đến %s0", "Đến %s0 [%s1]"); dòng chú vẽ sẵn trên tấm ảnh thành "Đang
  Chuyển Cảnh" (`labels.tsv`, loại `trans`). Khác gốc: bảng đã hiện thì ở lại ít nhất 900 ms (cảnh
  nhỏ nạp trong 123 ms, bảng gốc giấu ngay khi nạp xong); thủ tục đăng nhập đổi cảnh nền không hiện
  bảng. Đã nhìn trên cửa sổ thật: tấm rồng và dòng "Đến Hỏa Diệm Cốc" hiện lúc vào cảnh 251.
  Lỗi gặp trên đường, đã sửa: gốc đồng hồ khung `Display::State::started` đặt SAU các lần dựng giao
  diện đầu tiên của `open`, nên giao diện nhận một mốc rất lớn rồi mốc tụt về 0. Chưa port:
  `SceneTransB`, nhánh chờ biệt dã của `SceneTrans`, video nạp (`PlayLoadingVideo` của `Game.exe`).
  Chưa rõ (`docs/NGHI-NGO.md` mục 46): bản gốc có hiện bảng này lúc từ bảng chọn nhân vật vào game
  lần đầu hay không.
- Đã chạy trên mã cuối (2026-10-09, trước commit tạm): `msvc-release` dựng 0 cảnh báo, `ctest`
  85/85 (bỏ `audio_tests`), `check.py` xanh trên mọi tệp C++ đã đổi kể cả `display_gpu.cpp`, 137
  test Python của `TOOLS/content` xanh. Chưa chạy: `clang-asan`, `gcc-debug`. Phần hình của đợt này
  chủ dự án thử tay, không có test mới (lời chủ dự án: "ko được viết test logics nữa"); riêng
  `letter_labels.py` chưa có test.

Bảng tạo nhân vật port lại từ script gốc (2026-10-09; thay các câu về mặt, tóc, chân dung và bộ đồ
của đoạn trên). `ui/panel/create_role` nay là bản dịch từng hàm của `CreateRole.lua` trên `Widgets`
và `Call`, dữ liệu ở `ui/panel/role_cast` tra đúng như ba bộ quản của `Game.exe`
(`docs/TAO-NHAN-VAT-2026.md`: địa chỉ, phân bố, sáu thói quen lạ của script được giữ nguyên, lệnh
tái hiện). Bốn thứ chọn độc lập: ảnh chân dung (15 ảnh mỗi giới, hai trang, đúng thứ tự 49..51 rồi
1..12 của nữ, 52..54 rồi 13..24 của nam), kiểu tóc (3), kiểu mặt (mũi tên tới 3 trong 6 kiểu, như
bản gốc), bộ đồ tân thủ (3, gieo ngẫu nhiên lúc mở và lúc đổi giới). Người mẫu vẽ bằng dòng cao mô
(id cộng 10000) và mặc bộ đồ đang chọn; nhân vật lưu mang id thường và ba id hình trang phục, vào
game mặc đúng bộ đó. Sổ `roles.tsv` lên phiên bản 2 (thêm áo, bao tay, giày; tệp phiên bản 1 vẫn
đọc). Nguồn dữ liệu: `portraits.tsv` thêm cột `choice`, `order`; `faces.tsv`, `hairs.tsv` giữ mọi
dòng theo thứ tự tệp, thêm `name`, `choice`, bỏ cột `creatable` (module `look` không còn
`is_creatable`); `newbie_outfits.tsv` mới; `collect_avatar.py` gom thêm 96 tệp lưới và ảnh của mọi
thứ chọn được. HUD nay báo cho chuỗi đăng nhập cửa sổ dưới chuột (dòng mô tả) và lần nhả chuột (nút
xoay giữ chuột tới khi nhả). Trọng tài `lua_oracle.py` thêm `--table`, `--schema`, `--name` và luật
nút chọn một của CEGUI; số vàng bảng nhiệm vụ sinh lại (thẻ "hiện tại" tắt khi bấm thẻ "nhận
được") và `quest_log.cpp` sửa theo. Bản tiếng Việt thêm 77 khoá (mô tả, lời giới thiệu mười lăm môn
phái viết vừa ô 134 x 80, tên kiểu mặt, tóc, bộ đồ). Chưa port: mô hình riêng của từng môn phái
khi xem trước, phóng camera, hộp thông báo, tên ngẫu nhiên (mục 7 của tài liệu trên).

Bảng chọn và bảng tạo nhìn `tl3chuangjian.Scene` (2026-10-08, `build/login-select2`): "Vào Game"
nạp 40 mesh, 142 vật thể trong 150 ms. Nhân vật đứng trên đài, camera là tư thế nghỉ của track
ô đó, FOV 65. Bảng tạo nhìn khoá cuối của CameraTrack, người trong `CreateRole_Model`. Chưa tua
đoạn chạy giữa các ô và chưa zoom. Lớp kiểm tra GPU 0 lỗi.

Chưa làm (chi tiết ở `NGHI-NGO.md` mục 40):

- Cảnh nền (chủ dự án nêu: "camera đứng yên thì khác gì bức ảnh"): bước 1 đã xong, thư viện hiệu
  ứng gom từ nguồn bản 2026 bằng `TOOLS/content/collect_fx.py` (thay `cook_fx.py`; cả 513 cảnh: 423
  effect, 1658 hệ hạt, 1432 material, 741 ảnh PNG, 142 mesh hạt), `fx_view` nạp PNG và không còn
  cắt lặng ở 4096 quad, `fx::Cast` bỏ hệ chưa vẽ đúng được và đếm lý do. Trên `erengu_DL` đang vẽ 86
  hệ hạt (lửa, quầng đèn); còn 77 hệ chưa vẽ: mặt nước, sương, khói (trộn alpha), ngọn nến
  (`SequenceFrame`), hạt mesh. 12 vật thể `Model` có hoạt ảnh (quạ) chưa vào `Stage`; mặt nước
  `TerrainLiquid` chưa vẽ. Chi tiết và số đếm ở mục 40(a) của `NGHI-NGO.md`.
- Số lệnh vẽ của cảnh nền (chủ dự án nêu hai lần: "685 lệnh vẽ là sai hoàn toàn ở khâu login",
  rồi 2026-10-09 "vẫn dùng hơn 600 lệnh vẽ"): ĐÃ SỬA 2026-10-09 hai nguyên nhân trong
  `render::Forward`. Một, bản sao của một mesh bị tách thành một lệnh cho mỗi đèn điểm nó nhận:
  nay chỉ số đèn của từng bản nằm trong buffer `worlds` (ô hàng cuối, cột đầu của ma trận thế giới
  của bản đó; vertex shader đọc rồi chuyển sang pixel shader bằng biến không nội suy), nên mọi
  bản của một primitive đi một lệnh. Hai, không loại theo khung nhìn: nay bản sao và vật thể đứng
  yên (không skin, không đặt tư thế) có hình cầu bao nằm hẳn ngoài một mặt của khung thì bỏ
  (`render::see_copies`, `reach_at` ở `render/shade`, test ở `shade_tests`). Đo trên
  `msvc-release`, Vulkan và GLES cho cùng số: `--login` 682 xuống 429 lệnh, Hỏa Diệm Cốc 50 xuống
  13, lớp kiểm tra GPU 0 lỗi; ảnh `--shot` trước và sau chỉ khác ở hạt lửa, chữ số bảng đo và nút
  đang được rê chuột. Thời gian ghi lệnh mỗi khung gần như không đổi (Vulkan 0,51 xuống 0,48 ms,
  GLES 1,31 xuống 1,25 ms): chi phí nằm ở việc duyệt 895 bản sao mỗi khung, không ở số lệnh.
  429 gồm 282 primitive khác nhau và 147 lệnh của model có chất liệu trộn alpha, vốn không gom
  thành bản sao để còn xếp xa trước gần sau (`can_batch` ở `display_gpu.cpp`). Ý đi tiếp ghi ở
  mục 7 của `docs/giao-viec/KD-DOT-1/GHI-CHU.md`.
- Bản gốc 2026 vẽ cảnh thế nào (đọc từ `F:\tl 2026\Bin64`, 2026-10-09): OGRE với
  `RenderSystem_Direct3D9.dll` và `RenderSystem_Direct3D11.dll`, quản cảnh bằng
  `Plugin_OctreeSceneManager.dll`. `OgreMain.dll` không xuất `InstancedGeometry` hay
  `InstanceManager`; `Render.dll`, `Game.exe`, `tEngine.dll` không import hàm nào có chữ
  `Instanc` hay `StaticGeometry` (`python TOOLS/port/pe_refs.py <pe> imports <chữ>`).
  `Render.dll` có đường `Ogre::StaticGeometry` (chuỗi `Fairy/StaticGeometry/0`) nhưng cờ
  `EnableStaticGeometry` chỉ bật khi biến môi trường `Fairy_Hack` chứa chữ đó: hàm
  `0x180086d90` gọi `getenv("Fairy_Hack")` rồi `strstr`, mặc định ba cờ là 0 (`mov dword ptr
  [rcx+0x1c], 1`); không tệp nào trong 512 tệp `.Scene` hay trong `Config` nhắc `StaticGeometry`.
  Tức bản phát hành vẽ mỗi `StaticEntity` còn trong khung bằng một lệnh cho mỗi sub-mesh.
  `erengu_DL.Scene` có 894 `StaticEntity`; với khung hình đăng nhập, tổng số bản vẽ của mọi lệnh
  bên mình là 1163, tức cách vẽ ấy cần khoảng chừng đó lệnh cho vật thể tĩnh (số suy từ bộ vẽ của
  mình, CHƯA đo trên client gốc đang chạy).
- Chụp cảnh nền không có giao diện: `thienlong_client --login --bare --shot <tệp.png> --frames
  500` (`--bare` thêm 2026-10-09: giao diện vẫn chạy nhưng không ra hình). Chủ dự án định thay
  cảnh nền 3D của màn đăng nhập bằng một video làm từ ảnh này.
- Nạp tức thì: còn 0,9 giây cho cảnh nền; muốn đủ hình ngay khung đầu phải nấu texture (giữ BCn
  của tệp gốc kèm mip), xem mục 6 của ghi chú khởi động.
- Ô chọn đuôi tài khoản (`Falagard/Combobox`), lời nhắc Caps Lock, IME, màn chọn máy chủ, bảng
  trợ giúp; máy chủ đăng nhập (phần 3 và 4).

Lệnh kiểm:

```
cmake --build --preset <p> --target ui_logon_tests client_tests camera_tests resource_tests io_tests
cmake --build --preset <p> --target gui_softkey_tests ui_softkey_tests gui_sheet_tests gui_real_tests
ctest --preset <p> -R "^(ui_logon_tests|client_tests|camera_tests|i18n_tool_tests)$"
ctest --preset <p> -R "^(gui_softkey_tests|ui_softkey_tests|gui_sheet_tests|gui_real_tests)$"
python -B TOOLS/content/ui_rects.py --raw "F:/tl 2026/_raw" --collected CLIENT/data
    --out tests/golden/ui_rects.tsv
python -B TOOLS/run/click_shot.py build/msvc-release/thienlong_client.exe --out build/softkey-shot
    --click 643,317 --click 454,413 --click 826,413 --click 423,444 --click 826,382
    --click 575,278 --click 454,444 --click 850,351 -- --login --data CLIENT/data
ls CLIENT/bin/shaders
python -B TOOLS/content/build_i18n.py assets/i18n/vi.tsv CLIENT/data --state build/i18n
python -B TOOLS/content/letter_buttons.py assets/i18n/vi/source/button_sheet.png build/i18n/base assets/i18n/vi
python -B TOOLS/content/ui_text_fit.py CLIENT/data tests/golden/ui_rects.tsv
python -B TOOLS/run/click_shot.py build/msvc-release/thienlong_client.exe --out build/login-shot
    --type "575,278,ten\t" --type "575,316,matkhau" --click 640,567 --click 1166,511
    --type "692,617,Lang" --click 1160,552 --click 1166,457 -- --login --data CLIENT/data
cmake --build --preset gcc-debug --target ui_role_tests ui_select_tests ui_create_tests ui_flow_tests
ctest --preset gcc-debug -R "^(ui_role_tests|ui_select_tests|ui_create_tests|ui_flow_tests)$"
CLIENT/bin/thienlong_client.exe --login
```

## Va chạm công trình, đợt DH 1: việc dở của phiên AI phụ đã gộp vào main (2026-10-08)

Chủ dự án yêu cầu gộp toàn bộ phiên đó vào `main`. Phiên dừng giữa đợt (tệp cuối ghi lúc 16:26),
không commit lần nào; Claude commit việc của nó thành ba commit trên nhánh `dh-dot-1` rồi gộp
(`merge: gộp nhánh dh-dot-1`). Đề bài ở `docs/giao-viec/DH-DOT-1/DE-BAI.md`, kết quả và nhật ký đo
của phiên ở cùng thư mục, tài liệu ở `docs/VA-CHAM-2026.md`.

Có trong `main`: module `collision` (tầng `core`): `parse_building_file` đọc `.WCollision` thành view
không cấp phát và kiểm mọi số đếm, chỉ số, số thực; `mesh` dựng lưới sau nạp; `opcode_tree` dựng
cây `AABBQuantizedNoLeafTree` của OPCODE 1.3. Công cụ `TOOLS/port/building_oracle.py` (trọng tài
bằng `PathLib.dll` gốc), `make_building_file.py`, `fuzz_building.py`. Test `collision_tests`,
`collision_alloc_tests`, `collision_fuzz_tests`, `collision_model_tests`, exe đo `collision_bench`.

Đã kiểm sau gộp (2026-10-08): `gcc-debug` dựng 0 cảnh báo và `ctest` qua, `clang-asan` 68/68,
`msvc-release` 68/68; `collision_fuzz_tests` và `collision_model_tests` qua trên tệp thật;
`collision_tests` và `collision_alloc_tests` báo Skipped (mã 77) vì các ca chờ API truy vấn. Lint
Python của bốn công cụ 0 lỗi sau khi Claude chữa hai lỗi của `fuzz_building.py` (hàm `main` dài 71
dòng, chuỗi có đường dẫn ổ đĩa). Mặc định `GAME_RAW_SCENE` trỏ `..` ra ngoài dự án đã bỏ: lấy từ
biến môi trường `THIENLONG_RAW_ROOT` hoặc `-DGAME_RAW_SCENE`.

CHƯA xong, chi tiết ở mục 41 của `NGHI-NGO.md`:

- Chưa có API công khai `load`, `height`, `raycast`; module chưa nối vào client (nhân vật vẫn đi
  xuyên mặt cầu, bậc thang).
- Bảng tiêu chí của đợt (`KET-QUA.md`): T1 đạt, T6 đạt sau khi chữa lint, còn lại ghi CHỜ.
- `check.py`: 16 trên 22 tệp C++ qua; sáu tệp của phần Model còn nợ.

## Máy chủ: test và công cụ chỉ nghe loopback ở cổng do hệ điều hành cấp (2026-10-09)

Nợ (c) của mục 44 trong `docs/NGHI-NGO.md`, làm trên nhánh `server` (worktree `.worktrees/server`)
trước mọi việc khác của P2 vì nó chặn việc chạy `service_tests` ở cây dựng mới.

Đã làm:

- `tests/support/loopback_config.hpp`: `free_loopback_ports` xin hai cổng trống trên `127.0.0.1`
  (nghe cổng 0, đọc lại số, trả cổng); `stage_config` chép mọi tệp `.toml` của `SERVER/config`
  (trừ `*.local.toml`) vào `<thư mục exe>/<tên>/config` và đổi hai dòng `[listen]` của `gate.toml`.
  `gate.toml` không còn đúng hai dòng `game`, `auth` thì hàm trả rỗng và test đỏ, không chạy tiếp
  với địa chỉ thật.
- `service_tests`, `server_boot`: cụm chạy trên bản chép đó; khoá danh tính sinh ở
  `<thư mục exe>/<tên>/data/gate`, không còn ghi vào `SERVER/data` của cây nguồn. Các ca chỉ chờ
  mã thoát 2 (dòng lệnh sai, cấu hình sai) vẫn đọc cấu hình thật vì không tiến trình nào kịp nghe.
- `gate_loop_tests`, `thienlong_gate_load`: bỏ cổng 17921, 17922, 17931, 17932.
- `docs/giao-viec/P2-DOT-1/kiem-claude/boot_check.py`: bảy phần không chạy PostgreSQL dùng bản chép
  loopback ở `build/p2-claude-boot`.
- Giao kèo mục 3.1 của kế hoạch không đổi.

Đã kiểm, trong worktree, ngày 2026-10-09:

- Đỏ trước: một socket khác giữ `127.0.0.1:17921` thì `gate_loop_tests` bản cũ dừng ở "gate in
  ready" (gate in "không nghe được cổng game: không gắn được cổng"), thoát 1. Xanh sau: cùng điều
  kiện, giữ cả 17921 và 17922, bản mới thoát 0.
- `check.py -j 2` trên sáu tệp đã đổi: GCC 16, Clang 23 và clang-tidy, 6 tệp 0 lỗi.
- Dựng `gate_loop_tests`, `service_tests`, `server_boot`, `thienlong_gate_load` ở `clang-asan`,
  `gcc-debug`, `msvc-release`: 0 cảnh báo.
- Ba test ấy chạy cùng lúc ở ba cây dựng, mỗi cây `ctest -j 3`, lặp ba vòng: 27 lượt, 0 đỏ.
- Hai lượt `thienlong_gate_load --good 300 --hostile 60 --seconds 3` chạy cùng lúc (bản MSVC và
  bản GCC): cả hai thoát 0, đủ 300 bắt tay.
- `boot_check.py build/msvc-release SERVER/config`: 30 phép kiểm đạt, 0 hỏng.
- `Get-NetFirewallApplicationFilter` sau mọi lượt chạy: 12 rule như trước, 0 rule cho đường dẫn
  của worktree. Không còn tiến trình `thienlong_*`. Cây nguồn không sinh `SERVER/data`.
- `grep` trong `tests` và `TOOLS/server`: số cổng viết cứng chỉ còn ở dữ liệu của test phân tích
  địa chỉ và cấu hình (`net_tests`, `config_tests`, `config_samples.hpp`), không chỗ nào mở socket.

Sau khi gộp `main` vào nhánh (commit `506b446`: có chỗ sửa `display_gpu.cpp`, bốn test mới trong
`ctest` và phần tài liệu còn lại của lượt khảo sát), dựng mọi target test, `header_check` và
`game_client_display` của nhánh ở ba preset, 0 cảnh báo, rồi `ctest -j 4` trừ `audio_tests` (mở
loa thật): `clang-asan` 74 qua, `gcc-debug` 65 qua, `msvc-release` 74 qua, 0 đỏ ở cả ba. Ba test
`collision` Skipped (worktree không khai `_raw`), `window_modal_tests` Disabled.

Chưa kiểm: target `all` (exe client và bước i18n; worktree không có `CLIENT/data`);
`server_data_lint` (worktree chưa sinh `SERVER/tables/shared` nên CMake không đăng ký test này);
bản POSIX (`loopback_config.hpp` chỉ dùng `game::net` và `std::filesystem`, chưa dựng trên Linux).

## Máy chủ: P2-1, cổng 0 trên loopback và dòng `ready` mang cổng thật (2026-10-09)

**Nhánh và dải commit:** `server`, `9f80491` (gói P2-1) rồi `08eb7f9` (commit riêng dọn
`messages_per_second`, cuối mục này). Worktree `.worktrees/server`.
**Người kiểm độc lập (worktree sạch):** chưa có; nhóm Grok Bot đối chiếu sau khi commit vào nhánh.

Gói P2-1 của `THIENLONG-PHAN-CONG.md` (danh mục PC:1018, mục (8) của PC:1019), đóng nốt nợ (a). Mục
ngay trên là bước một (`a8cf96b`): test xin cổng trước rồi ghi số vào bản chép cấu hình, còn một
khe giữa lúc trả cổng và lúc gate nghe. Gói này bỏ hẳn bước xin cổng.

Đã làm, theo số của danh mục:

1. Cổng 0 chỉ nhận khi bên nghe đứng ở đúng `127.0.0.1`: `config::Endpoint::parse` (hai dòng
   `[listen]` của `gate.toml`, `listen` của `admin.toml`), `Cursor::listen_port` (`port` của
   `[[process]]`) và `endpoint_of` của gate (`ZeroPort::kAllow` chỉ ở loopback). `0.0.0.0:0`,
   `127.0.0.2:0`, `127.0.0.1:00` và `[postgres] port = 0` vẫn bị từ chối kèm số dòng.
2. Gate đọc lại cổng thật bằng `TcpListener::local()` và in `ready game=<cổng> auth=<cổng>`.
   `supervise::parse_ready` là bộ đọc chung của dòng đó: khoá cổng `ipc`, `game`, `auth`,
   `metrics`; khoá lạ bỏ qua; năm lỗi `ReadyFault`. Trình giám sát in dòng `ready` của cụm kèm cổng
   của từng con (`ready gate.game=<cổng> gate.auth=<cổng>`), in dòng `ports ...` khi một con chạy
   lại ở cổng khác, và dừng cả cụm khi một con gửi dòng `ready` hỏng. Năm chỗ từng so `"ready"`
   nguyên văn nay gọi bộ đọc: `supervise.cpp`, `service_tests`, `server_boot`, `gate_loop_tests`,
   `gate_load.cpp`; `boot_check.py` có bản Python tương đương. Kế hoạch có thể sinh dòng `ready`
   dài quá trần một dòng của `process` (4096 byte) thì `thienlong_server` thoát 2 trước khi chạy
   tiến trình nào (`supervise::ready_line_bound`).
3. `stage_config` đổi `port` của mọi `[[process]]` thành 0 và giữ nguyên `[postgres]`; số dòng đổi
   khác số khối, hay một khối không nghe `127.0.0.1`, thì trả rỗng. `free_loopback_ports` và
   `pick_ports` đã xoá; `service_tests`, `server_boot` thôi link `game_net`.
4. Ca đỏ B là test `server_boot_source_clean`, đúng một tên trong `ctest`: chạy trọn `server_boot`
   rồi so tên, cỡ và giờ ghi của mọi tệp dưới `SERVER/data/gate` của cây nguồn trước và sau. Ca
   đỏ A là ca `two_gates_share_one_config` của `gate_loop_tests`.
5. Chú thích đầu `tests/support/loopback_config.hpp` viết lại, không còn chuỗi địa chỉ của cấu
   hình thật.
6. Ba phần `postgres`, `using`, `survive` của `boot_check.py` dựng một cụm PostgreSQL tạm ở
   `build/p2-claude-boot/pg-data` (`listen_addresses = '127.0.0.1'`, mật khẩu sinh lúc chạy rồi
   xoá), trỏ `[postgres]` của bản chép `cluster.toml` vào đó, xong thì dừng và xoá. Không còn đụng
   `SERVER/data/pg` hay cấu hình PostgreSQL của chủ dự án.
7. `reset_stage` kiểm `error_code` sau từng lệnh (L1 của phiếu review `a8cf96b`).
8. Bẫy cổng ở mục 11 của `AGENTS.md` viết lại theo cách mới, kèm lệnh tái hiện.

### Đã kiểm (cây làm việc sắp commit, ngày 2026-10-09)

Đỏ trước: ở `8357eca`, hai `thienlong_gate.exe` chạy cùng một cấu hình khai `127.0.0.1:0` đều
thoát 2 với `gate.toml:21: khoá game ngoài miền` (ca A). Ca B đã xanh từ `a8cf96b`, nơi khoá danh
tính dời vào cây dựng; răng của phép so nằm ở ca `snapshot_sees_new_changed_and_removed_files`
(tệp mới, tệp ghi lại, tệp bị xoá đều làm hai lần chụp khác nhau).

| Lệnh | Kết quả |
|---|---|
| Dựng lần lượt mọi exe test, exe máy chủ và `header_check` của `gcc-debug`, `clang-asan` (ngoài `dev.bat`), `msvc-release` (trong `dev.bat`) | 149, 167, 167 target; 0 cảnh báo ở cả ba |
| `ctest --test-dir build/msvc-release -E '^audio_tests$' -j 4` | `100% tests passed out of 78` |
| Hai lượt `ctest -E '^audio_tests$' -j 8` cùng lúc (`gcc-debug` và `clang-asan`), lặp ba vòng | sáu lượt, mỗi vòng `100% tests passed out of 69` và `out of 78`; 0 đỏ |
| `check.py -j 4` trên mọi tệp C++ đã đổi hoặc mới | `19 tệp, 0 lỗi.` |
| NDK `aarch64-linux-android29` và `x86_64-linux-android29`, `-fsyntax-only -Wall -Wextra -Werror`, sáu tệp `.cpp` dùng chung đã sửa của `config`, `gate`, `supervise`, `service` | 12 lượt, mã 0 |
| `lint_py.py`; `unittest test_*.py`; `lint_config.py`; `gen_protocol.py --check` | mã 0; `Ran 250 tests`, `OK (skipped=8)`; `17 tệp sạch, 243 cài đặt đều có chú thích và thẳng cột`; mã 0 |
| `boot_check.py build/msvc-release SERVER/config` | 30 phép kiểm đạt, 0 hỏng |
| `boot_check.py build/msvc-release SERVER/config postgres using survive` | 24 phép kiểm đạt, 0 hỏng; log của PostgreSQL tạm chỉ có `127.0.0.1` |
| `Get-NetFirewallApplicationFilter \| Where-Object Program -like '*\.worktrees\server*'` | 0 dòng (cả máy vẫn 12 rule cũ) |
| Lệnh grep thu hẹp của `tester/P2-truoc-khi-chay.md` mục 5 | 8 dòng: `config_samples.hpp:57, 78, 81` (mẫu cấu hình hỏng), `net_tests.cpp:140, 141, 157, 158, 159` |
| Lệnh kèm cho `tests/config_tests.cpp` | 3 dòng `323, 324, 403`, nội dung như `a6ad779:303, 304, 383` |

Trong ba lượt `ctest`: ba test `collision` Skipped (worktree không khai `_raw`), `window_modal_tests`
Disabled; không test máy chủ nào Skipped. Tám ca `unittest` bị bỏ đều là ca đọc cây `_raw` hay cây
nguồn cũ (`THIENLONG_RAW_ROOT`, `THIENLONG_LEGACY_ROOT` không khai trong worktree).

Fuzz, đo tải, đo từng pha, giết và đứng im, bảng đối chiếu gốc: không thuộc gói này (không có bộ
giải mã byte của client, công thức hay đường nóng mới).

### Chưa kiểm và vì sao

- `cmake --workflow --preset <p>` nguyên văn: nó dựng `all`, gồm exe client và bước i18n, mà
  worktree không có `CLIENT/data`. Đã dựng mọi exe test, exe máy chủ và `header_check` bằng danh
  sách target rồi chạy `ctest`.
- `server_data_lint`: worktree chưa sinh `SERVER/tables/shared` nên CMake không đăng ký test này.
- TSan: chưa kiểm TSan (Windows không có TSan). Mã của gói không thêm luồng nào.
- Linux: chưa dựng trên Linux; chỉ kiểm cú pháp NDK hai ABI.
- `parse_ready` chưa có đích libFuzzer: đầu vào là stdout của tiến trình con do chính trình giám
  sát sinh, dài tối đa 4096 byte; test `ready_line_parses_ports_and_names_each_fault` sinh đủ năm
  lỗi và chạy dưới ASan, UBSan.
- `thienlong_gate_load`: ở `9f80491` chỉ dựng 0 cảnh báo ở ba preset; lượt chạy thật sau khi đổi
  sang đọc cổng ở dòng `ready` làm ở `08eb7f9` (cuối mục này). Số tải chính thức là việc của P2-5.

### Giả định, Khác gốc, số tự đặt, chưa port

- Lệch danh mục, có chủ ý: dòng `ready` của gate chưa có `metrics=<cổng>`. Cổng đọc số đo thuộc
  module `metrics` của P2-2, chưa có trong mã; in một cổng chưa ai nghe là nói sai. Bộ đọc đã nhận
  khoá `metrics` và bỏ qua khoá lạ, nên P2-2 thêm khoá mà không phải sửa bên đọc nào.
- `ipc=<cổng>` và việc giám sát điền cổng đã học vào khối khởi động của bên nối: P2-10.
- Còn một chỗ xin cổng trước, biết mà chấp nhận: cụm PostgreSQL tạm của `boot_check.py`, vì
  PostgreSQL không nhận cổng 0 (bẫy mới ở nhóm "Máy chủ" của `docs/BAY-DA-BIET.md`).
- Số tự đặt: không có. Trần 4096 byte là `process::kLineCeiling` có sẵn.

### Tệp ngoài phạm vi máy chủ đã chạm

- `AGENTS.md` (bẫy cổng và chỉ mục của mục 11), `docs/BAY-DA-BIET.md` (hai bẫy mới): theo mục (8)
  của PC:1019. Không chạm module client, `CLIENT/`, `assets/`, `third_party/`.

### Dọn dẹp

- Tiến trình `thienlong_*` và `postgres` do phiên này sinh còn lại: 0.
- Rule tường lửa của `.worktrees\server`: 0 dòng.
- Dung lượng worktree: 5382 MiB (ba cây dựng, `vcpkg_installed`, bản chép `SERVER/pgsql`); cụm
  PostgreSQL thử đã xoá: có. `build/p2-1-red` và `build/p2-claude-boot` đã xoá.

### Nợ mới, bẫy mới, việc dở

- `docs/BAY-DA-BIET.md`, nhóm "Máy chủ": PostgreSQL từ chối `port = 0`. Nhóm "Công cụ Python và
  git": tên nhánh `server` trùng thư mục `SERVER` trên Windows.
- `docs/NGHI-NGO.md` mục 44(c): nợ (a) ghi đã sửa, còn nêu chỗ xin cổng của PostgreSQL tạm.
- Việc kế: P2-2 (`metrics`, kèm khoá `metrics=` ở dòng `ready`), P2-5, P2-10.

### Commit riêng `08eb7f9`: `messages_per_second` (PC:839-842, `metrics.md` mục 7.5)

Đúng ba tệp. `SERVER/config/gate.toml`: chú thích đổi "số tạm" thành "chưa có nguồn", giá trị 60
giữ nguyên. `tests/config_tests.cpp`: bỏ phép so với 60, còn kiểm khoá có mặt và giá trị lớn hơn
0. `TOOLS/server/gate_load.cpp`: bỏ số 40 viết cứng; công cụ đọc bảng `[limits]` của
`SERVER/config/gate.toml` bằng bộ đọc của `config`, ghi `messages_per_second` đó vào `gate.toml`
của lượt đo, đọc lại chính tệp vừa ghi và in dòng `config messages_per_second=<v>
handshake_timeout_ms=<v> idle_timeout_ms=<v> max_connections=<v>` trước kết quả đo.

| Lệnh | Kết quả |
|---|---|
| `git grep -n -E "messages_per_second *= *[0-9]" -- TOOLS/server` | 0 dòng (trước đó 1 dòng) |
| `lint_config.py`; `lint_py.py` | `17 tệp sạch, 243 cài đặt đều có chú thích và thẳng cột`; mã 0 |
| Dựng `config_tests`, `thienlong_gate_load` ở ba preset; `ctest -R '^(config_tests\|server_config_lint)$'` | 0 cảnh báo; `100% tests passed out of 2` ở cả ba |
| `check.py -j 2 TOOLS/server/gate_load.cpp tests/config_tests.cpp` | `2 tệp, 0 lỗi.` |
| `build/msvc-release/thienlong_gate_load.exe --good 50 --hostile 10 --seconds 2`, đứng ở gốc worktree | `config messages_per_second=60 handshake_timeout_ms=2000 idle_timeout_ms=60000 max_connections=76`; `handshakes 50`; `good_live 50`; `late 0`; thoát 0 |
| Cùng lệnh, đứng ở một thư mục có bản chép `SERVER/config` khai `messages_per_second = 45` | `config messages_per_second=45 ...`; thoát 0 |
| Cùng lệnh, bản chép khai `messages_per_second = 0` (ngoài miền) | `không đọc được bảng [limits] của SERVER/config/gate.toml`, `không chuẩn bị được lượt đo, gate chưa chạy`; thoát 1 |
| Cùng lệnh, thư mục không có `SERVER/config` | `không chuẩn bị được lượt đo, gate chưa chạy`; thoát 1 |

Lượt đầu cũng là lượt chạy thật của công cụ sau P2-1: cổng game lấy từ dòng `ready` của gate, đủ
50 bắt tay. Đây là lượt thử 2 giây, không phải số tải.

Chưa làm, để P2-5: đường dẫn `SERVER/config` của công cụ vẫn tính từ thư mục đang đứng (như
`cluster.toml`, `log.toml` nó vốn chép); đổi sang định nghĩa `GAME_SERVER_CONFIG` cần sửa
`CMakeLists.txt`, ngoài ba tệp của commit này. Giá trị 30 của `tests/gate_loop_tests.cpp` là số
riêng của bài test, giữ nguyên theo PC:825.

## Máy chủ: P2-2, số đo `metrics` và cổng đọc qua loopback; lỗi hạn tick trôi của gate (2026-10-09)

**Nơi làm:** thẳng trên cây chính `main` (chủ dự án chốt ngày 2026-10-09: "làm trực tiếp trên
main"), chưa commit lúc viết mục này. Cùng lúc có một phiên khác sửa client Android và iOS trên
cùng cây, nên mọi số dưới đây đo ở ba cây dựng riêng chỉ dựng target máy chủ: `build/srv-msvc`,
`build/srv-asan`, `build/srv-gcc` (`cmake --preset <preset> -B build/srv-<tên>`).
**Đặc tả:** `thienlong-specs/coder-server/metrics.md` và gói P2-2 của `THIENLONG-PHAN-CONG.md`.

Đã làm:

1. `SRC/core/effects.hpp`: macro `GAME_NONALLOCATING`, `GAME_NONBLOCKING` (cpp23 CL-09). Phần còn
   lại của gói P2-9 (`Tick`, `TickSpan`, `to_ticks`, `StrongId`, phép thu hẹp số có kiểm) chưa
   thêm vì chưa có nơi dùng thật; vào cùng `ipc` và zone.
2. Module `metrics` (`SRC/metrics/metrics.hpp`, `.cpp`; tầng `core metrics`): danh mục cố định 25
   bộ đếm, 3 mức đo, 7 pha; `Registry` là mảng `std::atomic` cấp sẵn, `add`, `set`, `record` khai
   `GAME_NONBLOCKING`; biểu đồ pha 2.000 cột 100 µs đóng bên phải và một cột tràn; ảnh chụp văn
   bản và bộ đọc `parse_snapshot` có trần 896.846 byte với mười mã lỗi; phân vị theo hạng gần nhất
   (`percentile_us`). Clang của `check.py` (`-Wfunction-effects`) chứng minh ba hàm tăng không
   khoá, không cấp phát, và `snapshot`, `write_snapshot`, `parse_snapshot` không cấp phát, nên
   không có test bọc `operator new`.
3. Module con `metrics/serve` (tầng `core net metrics metrics/serve`): `Readers` (hàng bên đọc,
   lái được từng bước trong test) và `Server` (luồng riêng, `127.0.0.1` cổng 0). Tối đa 4 bên chờ,
   mỗi bên 1 giây, gửi từng khúc 16 KiB, mỗi vòng nhận tối đa 16 kết nối.
4. Gate: `Drop::kLocal` (lỗi phía gate, tách khỏi "bên kia đóng"); `Table` nhận `Backing{identity,
   registry}`, bỏ mảng đếm riêng, ba nhánh từ chối của `admit` nay đếm và ghi log; bảng tên
   `kDropNames` buộc vào `metrics::Counter` bằng `static_assert`; bộ đếm `gate.accept.total`,
   `gate.accept.error`, `gate.admit.ok`, `gate.handshake.done`, `gate.closed.overflow`,
   `gate.tick.total`, `gate.tick.overrun`, `gate.tick.skipped`; mức đo `gate.live`,
   `gate.listening`, `gate.handshake.per_tick`; bảy pha `gate.phase.*`.
5. Dòng sẵn sàng: gate in `ready game=<cổng> auth=<cổng> metrics=<cổng>`, năm tiến trình kia in
   `ready metrics=<cổng>` (mục 3.1 của `docs/KE-HOACH-SERVER.md` đã sửa).
6. Exe `thienlong_metrics_snap` (`TOOLS/server/metrics_snap.cpp`): `capture`, `counter`, `gauge`,
   `phase`. Không nằm trong component cài `server`.
7. Đích fuzz `tests/fuzz/fuzz_metrics_snapshot.cpp` (lệnh dựng ở đầu tệp).

**Lỗi có sẵn bắt được trên đường: hạn tick của gate trôi.** `catch_up` cộng một nhịp 16,7 ms vào
hạn tick ở MỌI vòng, kể cả vòng thức sớm vì có I/O. Ca xả tin 600 khách cho gate chạy 2.790 vòng
trong chưa đầy hai giây, hạn lệch ra khoảng 44 giây; khi khách ngừng thì gate nằm trong
`PollSet::wait` trọn khoảng đó: `gate.tick.total` đứng im ở 2.790, mức đo `gate.live` kẹt ở 1, đóng
stdin 10 giây gate không thoát (luồng số đo vẫn trả ảnh chụp, nhờ đó thấy được). Sửa ở
`SRC/gate/front.cpp`: hạn chỉ dời khi vòng bắt đầu ở hoặc sau hạn, và thời gian chờ làm tròn lên
mili giây (làm tròn xuống thì vòng thức sớm dưới 1 ms quay rỗng tới khi qua hạn). Số nền của mục
"P2 đợt 3, phần đầu" và của P2-3 đo TRƯỚC khi sửa lỗi này.

Đã kiểm (2026-10-09, sau lần sửa cuối):

- `ctest --test-dir build/srv-msvc -R "^(layers|metrics_tests|metrics_serve_tests|gate_tests|gate_loop_tests|service_tests|server_boot|server_boot_source_clean|supervise_tests|config_tests|process_tests|net_tests|server_config_lint)$"`:
  13/13 qua. Cùng danh sách (trừ `server_config_lint`) ở `build/srv-asan` (Clang ASan + UBSan):
  12/12; ở `build/srv-gcc` (GCC 16 debug): 12/12. Dựng MSVC không cảnh báo.
- Đỏ trước, xanh sau: bỏ phép đếm ở nhánh từ chối của `admit` (trạng thái trước gói này) thì
  `gate_tests` đỏ 7 kỳ vọng, ca `admit_refusals_are_counted` và `counters_balance_after_mixed_run`.
  Trước khi sửa hạn tick, `gate_loop_tests` đỏ ở `flooders_are_counted_exactly` ("gate lặng sau khi
  ngắt hết khách", "đóng ống thì gate thoát 0") và chạy 45 giây; sau khi sửa xanh trong 6 giây.
- `flooders_are_counted_exactly`: 100 khách chỉ xả tin rồi thêm 500 trên cùng một gate, đọc qua
  cổng metrics: `gate.drop.rate` đúng 100 rồi đúng 600; lúc gate lặng `gate.admit.ok` = 600,
  `gate.handshake.done` = 600, hai đẳng thức của sổ đúng (nhận = ngắt sau khi nhận + sống; accept =
  nhận + từ chối). Tham số `messages_per_second` = 30 là số của gate.toml do test tự ghi.
- `per_ip_refusals_are_counted_exactly`: 22 khách, trần 2 mỗi địa chỉ: `gate.drop.per_ip` = 20,
  `gate.accept.total` = 22, `gate.admit.ok` = 2.
- `snap_tool_reads_gate`: 6 lượt gọi đúng và 18 lượt gọi sai của `thienlong_metrics_snap`, mã thoát
  0, 1, 2 như đặc tả, stdout rỗng ở mọi lượt sai.
- `metrics_tests` có răng: ba đột biến (cột đóng trái, bỏ kiểm cột tăng dần, bỏ trần `kTooLarge`)
  đều làm nó đỏ. `check.py --run tests/metrics_tests.cpp --with SRC/metrics/metrics.cpp` xanh (Clang
  ASan + UBSan + hardening STL; GCC debug mode của libstdc++).
- `check.py` xanh trên 15 tệp C++ đã đổi hoặc thêm (GCC 16 và Clang 23 `-Werror`, clang-tidy 23).
- Fuzz: `fuzz_metrics_snapshot -runs=1000000 -seed=20261008 -max_len=896847`, thoát 0, `cov: 231`,
  5 giây. Có răng: bỏ phép kiểm chỉ số cột khỏi bộ đọc thì dừng với "deadly signal" sau khoảng
  47.000 vòng (cần `-D_MSVC_STL_HARDENING=1`, xem nhóm "Máy chủ" của `docs/BAY-DA-BIET.md`).

Chưa làm, chưa kiểm:

- Ba pha con của bắt tay (`gate.handshake.keygen`, `.sign`, `.derive`, qua `StepClock` của
  `secure`) và pha `gate.handshake.absorb`: thuộc gói P2-3, chưa thêm vào danh mục.
- `thienlong_gate_load` vẫn đếm qua log và vẫn đọc dòng `gate: tick ...` trên stderr; chuyển sang
  cổng metrics là gói P2-5. Chưa chạy lại nó sau khi sửa hạn tick.
- Danh sách `llvm-cov` cho `SRC/metrics` chưa lấy.
- Chưa chạy trọn `ctest` của ba preset (phiên kia đang sửa client trên cùng cây); chưa dựng Linux.
- Bộ Tester của nhóm Grok (`tester/P2-kich-ban.md`) chưa chạy.

Khác đặc tả, có lý do:

- `parse_snapshot(text, out)` ghi vào `Snapshot` do bên gọi cấp và trả `std::expected<void, ...>`,
  không trả `Snapshot` theo giá trị: một `Snapshot` khoảng 280 KB, trả theo giá trị là đặt nó lên
  stack.
- Cột của một dòng `phase` phải tăng dần; cột lặp và cột lùi đều là `kBucket`.
- Ca vòng thật "N khách vượt `max_connections` thì `gate.drop.full` = N" không viết được: bảng đầy
  thì gate ngừng nhận, khách nằm ở hàng chờ của hệ điều hành chứ không bị từ chối, nên `admit`
  không bao giờ trả `kFull` qua vòng thật. Lý do "đầy" kiểm trên bảng thuần (`gate_tests`); vòng
  thật kiểm lý do "đầy theo địa chỉ".
- Ca "5 bên đọc cùng lúc, bên thứ 5 bị huỷ" và ca "bên giữ quá 1 giây" kiểm trên `Readers` lái
  từng bước (`metrics_serve_tests`), không qua exe gate: ảnh chụp thật của gate chỉ vài KiB nên
  bên không đọc không giữ được lượt, và thứ tự nhận qua luồng thật không tất định.
- Enum `Counter`, `Gauge`, `Phase` có kiểu nền `std::uint8_t` (đặc tả ghi `std::uint16_t`):
  clang-tidy `performance-enum-size`; đổi lại khi danh mục vượt 255.

## Khảo sát theo mã, 2026-10-08

Đối chiếu toàn bộ `SRC/`, `tests/`, `TOOLS/`, `CMakeLists.txt` với tài liệu, `main` ở `501743a`
(194 commit). Cách làm: đọc mã và đếm trước, đọc tài liệu sau; mỗi điều ghi dưới đây đã có lệnh
kiểm (grep, đếm, hoặc chạy). Lúc khảo sát cây dựng `build/<preset>` đang có phiên khác dùng, nên số
đo dựng và test của Clang ASan và MSVC lấy ở hai cây riêng (`build/survey-clang`,
`build/survey-msvc`), số của `gcc-debug` lấy ở log của phiên kia, trừ `math_tests` dựng ở một cây
GCC riêng (`build/survey-gcc`); ba cây riêng xoá sau khi đo. Thứ được đo là
cây làm việc lúc 23:00, tức `501743a` cộng các tệp đang sửa dở chưa commit: sáu tệp của phiên khác
(`SRC/gui/widgets.cpp`, `SRC/ui/pace.cpp`, `SRC/ui/text.cpp`, `SRC/ui/text.hpp`,
`tests/pace_tests.cpp`, `tests/ui_text_tests.cpp`) và chỗ sửa `display_gpu.cpp` nêu dưới.

Kích thước: 51 thư mục module trong `SRC/` (587 tệp git theo dõi, 118.706 dòng `.cpp`, `.hpp`, `.h`, `.mm`), 81
tệp `tests/*_tests.cpp` (khoảng 36 nghìn dòng cả thư mục), 114 tệp Python trong `TOOLS/` (89 công
cụ, 25 tệp test), `WEB/` 54 tệp (trang giới thiệu tĩnh, Vite cùng React và three.js, không có
backend).

Test đăng ký theo preset, đếm từ `CTestTestfile.cmake` lúc bắt đầu khảo sát: `clang-asan` 82,
`gcc-debug` 72 (GCC không dựng phần có GPU). Lượt này đăng ký thêm bốn test (xem "Đã sửa" cuối
mục), nên sau lần cấu hình lại là 86 và 74. Kết quả gần nhất:

- `gcc-debug`, 21:57, log của phiên khác: 71 trên 71 qua, `window_modal_tests` Disabled,
  `collision_tests` và `collision_alloc_tests` Skipped.
- `clang-asan`, 22:03, log của phiên khác: lượt dựng dừng ở `SRC/client/display/display_gpu.cpp`
  (`role_canvas_box` thiếu khai báo trước, `-Wmissing-prototypes`, có từ commit `b830c03`), nên 16
  test báo đỏ vì exe cũ hoặc thiếu exe. Đã đưa hàm vào namespace ẩn danh.
- Clang 23 ASan và UBSan ở cây riêng, sau chỗ sửa đó: dựng mọi target test, `header_check` và
  `game_client_display`, 903 bước (263 của phần máy chủ, 640 của phần còn lại), 0 cảnh báo;
  `ctest -j 4` 75 qua, 0 đỏ, 50 giây. Lượt cuối, sau mọi chỗ sửa của lượt khảo sát (dựng lại 93
  bước, 0 cảnh báo, có thêm bốn test mới đăng ký): 79 qua, 0 đỏ, 71 giây.
- MSVC bản phát hành ở cây riêng: cùng tập target, 907 bước (267 và 640), 0 cảnh báo; `ctest -j 4`
  75 qua, 0 đỏ, 6 giây.
- Ở cả hai cây riêng: `window_modal_tests` Disabled; ba test `collision_tests`,
  `collision_alloc_tests`, `collision_model_tests` Skipped (hai test đầu Skipped ở mọi cây vì ca
  "chờ Model"; test thứ ba vì cây riêng không khai `GAME_RAW_SCENE`). KHÔNG chạy ba test:
  `service_tests` và `server_boot` (chúng nghe `0.0.0.0:7000`, mỗi đường dẫn exe mới là một rule
  tường lửa mới) và `audio_tests` (mở loa thật). KHÔNG dựng exe `thienlong_client` (bước i18n của
  nó ghi vào `CLIENT/data` dùng chung).
- Cây chung `build/clang-asan` và `build/msvc-release` thì CHƯA dựng lại: phần máy chủ của
  `msvc-release` dựng lần cuối 17:16, trước khi gộp `gate`; client 21:30; chưa có lượt `ctest` nào
  của hai preset này ở cây chung sau các lần gộp tối 2026-10-08.
- Số đo riêng của phần máy chủ: xem mục "Máy chủ: P2 đợt 3, phần đầu".

Cổng của công cụ và dữ liệu máy chủ, chạy lại lúc 23:20: `python -B TOOLS/server/lint_py.py` thoát
0; `python -B -m unittest discover -s TOOLS/server -p "test_*.py"` 250 test, 8 bỏ qua, 0 đỏ;
`gen_protocol.py --check` thoát 0; `build_data.py --legacy <tlbb> --raw <_raw> --check` thoát 0 sau
151 giây, không ghi tệp nào. Dòng tổng kết `diff_tables` của lượt đó là thước đo khoảng trống nội
dung giữa bản 0859602 và client 2026: trong 106 cặp bảng, bảng client 2026 có 354.614 id, bản
0859602 có 62.374, chung 61.522; 293.092 id chỉ bản 2026 có, 852 id chỉ bản cũ có; 6 trên 55 dòng
tham chiếu có giá trị thiếu.

Điều mã có mà các mục cũ của tệp này chưa ghi:

- Bốn backend của `gpu` (Vulkan, D3D12, D3D11, OpenGL/GLES), có chọn backend tự động
  (`gpu/device.cpp`, `open_automatic`); `--backend` nhận cả bốn tên. Câu "không fallback tự động" ở
  mục "Render Vulkan trên Android/iOS" đã cũ.
- Tham số dòng lệnh của client là chín cái: `--frames`, `--scene-id`, `--backend`, `--size`,
  `--scene`, `--data`, `--shot`, `--validate`, `--login`. Không có `--resid` và chưa có
  `--dump-bounds` (các mục cũ còn nhắc hai tên này).
- Module `quest`, `skill` (bảng và sổ phía hiển thị, port theo mã máy `Game.exe`), bảng
  `ui/panel/quest_log` cùng bộ vẽ Listbox, ComplexWindow, ActionButton, Scrollbar của `gui`
  (commit `108a504`, `5934a9a`, `63fe94d`); đã có test và số vàng, CHƯA nối vào HUD
  (`docs/NGHI-NGO.md` mục 43). Lần port lại bộ viết chữ theo mã máy (`386607b`).
- Module `seal` và exe `thienlong_seal` (niêm asset thành `.tlpak`), cố ý không nối client.
- HUD nạp 35 layout; số vàng `tests/golden/ui_rects.tsv` có 43 layout, 3.258 cửa sổ ở bốn cỡ màn
  hình. Tám layout đã gom mà HUD chưa nạp: TargetFrame, TargetBuff, PetFrame, PartyFrame, ChatInfo,
  MissionTrack, ScrollInfo, SuperTooltip. Hai layout `SceneMap`, `LargeMap` chưa gom nên bản đồ
  cảnh và bản đồ thế giới có mã mở đóng (`ui/panel/maps.cpp`) mà không có khung để hiện.
- `WEB/` (commit `501743a`).

Đường dẫn và tên đã đổi kể từ khi các mục cũ được viết: `SRC/client/stage.cpp` và
`SRC/client/props.cpp` nay ở `SRC/client/stage/`; nguồn của `thienlong_shader` là
`SRC/shadertool/main.cpp`; `Table/scene_names.vi.tsv` nay là `Table/scene_names.lang.tsv` và thư mục
`TOOLS/content/lang` đã bỏ (nguồn là `assets/i18n/vi.tsv`); công cụ tháo mã máy là
`TOOLS/port/pe_refs.py` (không có `re_tool.py`); worktree `build/dh-dot-1`, `build/p2-dot-2` không
còn; các lệnh `check.py --fix`, `verify.py --nesting`, `check_shape.py` và cả mục "Trần 120 cột và
luật hình dạng" tả cổng hình thức đã gỡ khỏi bộ cpp23 tối 2026-10-08; Forge2 nay ở
`D:\TÀI LIỆU LÀM VIỆC\code\engine\Forge2`.

Đã sửa trong lượt khảo sát này:

- `display_gpu.cpp`: chỗ làm hỏng lượt dựng (nêu trên), rồi bảy trên tám chẩn đoán clang-tidy mà
  `check.py` báo ở tệp này, đều có từ commit `b830c03`: ba include thiếu, `store_roles` thành
  `const`, ba chỗ đọc `role_shot` sau lời gọi hàm thành viên. Dòng `client/display` của
  `cmake/GameLayers.cmake` thêm `gui` và `ui/panel` (kịch bản kiểm tầng đỏ với bảng cũ, xanh với
  bảng mới). Sau phần này `check.py` trên tệp: GCC 16 và Clang 23 biên dịch sạch, clang-tidy còn
  một chẩn đoán (đệm của `Display::State`, `NGHI-NGO.md` mục 45k); lệnh biên dịch của preset
  `cl /Zs` với cờ của `msvc-release` thoát 0; dựng lại `game_client_display` và `client_tests` ở
  một cây Clang ASan riêng, 209 bước 0 cảnh báo, `client_tests`, `layers`, `server_config_lint`
  qua. Exe client CHƯA dựng và chưa chạy với bảy chỗ sửa này.
- `TOOLS/port/forge2_port.py` trỏ mặc định tới chỗ mới của Forge2 (lệnh `measure` chạy lại được).
- Cài lại tám exe ở `SERVER/bin`.
- `SERVER/config/gate.toml` lệch cột từ commit `f74a41a` (thêm `idle_timeout_ms`), nên `python -B
  TOOLS/server/lint_config.py` đỏ với 6 lỗi mà không ai thấy: bộ kiểm ấy không nằm trong `ctest`.
  Căn lại bằng `--fix` (chỉ đổi dấu cách) và đăng ký test `server_config_lint`; test đỏ với bản
  lệch cột, xanh sau khi căn (18 tệp, 248 cài đặt).
- Ba tệp test có sẵn mà CMake chưa từng dựng (`fs_tests`, `math_tests`, `shader_tests`, 2.233
  dòng) nay đăng ký cho Windows: dựng 0 cảnh báo và qua ở Clang ASan, MSVC bản phát hành (cả ba)
  và GCC (`math_tests`).
- Ba comment nói sai mã: `SRC/client/main.cpp` còn gọi tham số là `--resid` (tên thật
  `--scene-id`); `SRC/client/options.hpp` ghi luồng đăng nhập "chưa vào được cảnh chơi" (đã vào
  được); đầu `SRC/gui/sheet.hpp` ghi danh sách, thanh cuộn và MeshWindow "chưa có" (đã có, bảng
  loại ở `gui/layout.cpp`). Chỉ đổi comment; năm tệp dùng chúng qua kiểm cú pháp bằng lệnh biên
  dịch của preset `clang-asan`.
- Đồng bộ bản chép bộ quy cách ở gốc repo (`MAP.md`, `INDEX.md`, `README.md`, `refs/`) và phần
  "Quy định chung" của `AGENTS.md` theo bộ cpp23 hiện tại.

Lỗ hổng thấy mà chưa sửa ghi ở `docs/NGHI-NGO.md` mục 44 (máy chủ) và mục 45 (hạ tầng và cổng
dựng).

## Gộp các mạch chưa commit về main (2026-10-14)

**Việc:** chủ dự án giao "xem các mạch chưa commit, kiểm chứng từng mã, chỉ đúng và chất lượng hơn thì mới
gộp, rồi dọn". Làm trong worktree `.worktrees/merge_all` từ `192f181`, chưa push.

Đã gộp (mỗi mảnh dựng và chạy test trước khi nhận):

1. Snapshot cây chính dơ lúc 08:50 (`8e13f0d`, nhánh `thay-doi-chua-commit`) cùng luồng `lint_uiflow`
   (`e5f5027`: timeline sang `engine/core`, tầng `GameLayers.cmake`, API `linttool`, `ui_flow_tests`) và ba
   sửa include test (`dbc6be1`, `8f861a4`, `4e22b54`): commit `d53698d`.
2. `TOOLS/content`: `collect_avatar.py` đọc cột `choice` (`export_look.py` không còn ghi `creatable`) và có
   `creation_ids`; `bake_image` không sập khi ảnh gốc hỏng (`df3326b`). Bốn lỗi test cũ của `TOOLS/content`
   hết.
3. `TOOLS/server`: `--digest-per-table` của `build_data.py`, `export_tables.py` (`95e8140`).
4. Gate: `Table` nhận `Backing{identity, registry}`, mọi lý do từ chối đếm vào `metrics::Counter`, ca test số
   đo và kiểm stderr chặt của `server_boot` được phục hồi (`d88ef03`).
5. `gui_sheet_tests.cpp`: 39 ca thay cho 12 (`4aa55e3`); `hud.cpp` include trực tiếp `call.hpp`,
   `quest_log.hpp` (`e820bab`).
6. Lỗi mà chỉ Clang/GCC bắt (`d88ef03`, `2842a96`): xem thân hai commit. Đáng nhớ nhất: bộ đệm
   `thread_local std::string` của `core/log.cpp`, `log_sink.cpp`, `thread.cpp` quay về dạng trần sau đợt khôi
   phục 2026-10-09 (`docs/NGHI-NGO.md` mục 12), `log_tests` chết 21/30 lần dưới `gcc-debug`, nay 0/40.
7. `gui_real_tests`, chạy ở cây chính có dữ liệu thật `dev/` (cây gộp không có dữ liệu nên hai ca bị bỏ qua,
   chỉ lộ ở đây). Hai ca đỏ ngay trên snapshot, đã sửa tận gốc:
   - `window_boxes_match_golden`, 192 ô lệch golden. 100 ô lệch 1 điểm ảnh là lỗi của `layout.cpp`: CEGUI 2026
     lưu vùng cửa sổ dạng `URect(min, max)` và tính lại cỡ điểm ảnh bằng `max - min` trong float32 lúc layout
     gắn vào tấm nền (`onParentSized`), còn `layout.cpp` dùng thẳng UDim cỡ đã đặt. Ví dụ vị trí `0,5` rồi cỡ
     `0,15` trong cha 430 cho 64 chứ không phải 65 (`BieYePersonnelManage_List1_Text_3`). `layout.cpp` nay giữ
     vùng như `URect` và mô phỏng một lượt `onParentSized` từ gốc xuống (`Placed::is_resized`,
     `is_resizing_children`). 92 ô còn lại là lỗi của test: 48 dòng golden của cửa sổ không có tên và 44 dòng
     của tên khai ở nhiều layout (cột `is_duplicate`) mà `Hub::box` tra theo tên không chỉ tới được; test nay
     bỏ dòng không tên và so tên trùng với mọi ô golden cùng tên. Hai ca mới của `gui_sheet_tests`
     (`area_size_is_max_minus_min`, `fixed_parent_does_not_resize_children`) canh lỗi, đã thấy đỏ trên
     `layout.cpp` cũ.
   - `notes_are_known_gaps`: trần "< 20 ghi chú" không còn đúng khi đã gom đủ 2.027 layout (112 ghi chú). Một
     ghi chú là lỗi thật: `parse_image` tìm `" image:"` nên thuộc tính ngắt dòng giữa `set:` và `image:`
     (`NewExterior_PetPossJian.layout.xml:595`) làm tên bộ dính xuống dòng. Client gốc tách bằng
     `sscanf(" set:%s image:%s")` (`PropertyHelper::stringToImage`, cây `_ref`) nên khoảng trắng nào cũng ngăn
     cách; `parse_image` nay tách y như vậy, `gui_value_tests` có ca hồi quy. Phần còn lại là chỗ hỏng của dữ
     liệu gốc, nay kê đủ từng cái trong test (52 ảnh, 7 hoạt ảnh) thay cho trần số lượng: 20 ảnh thuộc bộ không có
     tệp imageset nào, 23 ảnh thuộc ba bộ (`chunfen`, `chunfen1`, `WeixinHongbaoPaisong`) có tệp riêng nhưng
     `WoWLookSkin.scheme.xml` gốc kê chúng trong chú thích XML (hoạt động đã ngừng), 9 ảnh thiếu trong bộ có
     tệp. Thêm một chỗ hỏng lạ làm ca đỏ.
   - Sửa kèm (tìm thấy trên đường): `loader.cpp` bỏ chuyển `std::string` thừa; `value.cpp` đưa `scaled_channel`
     vào namespace ẩn danh; `gui_real_tests.cpp` `GoldenPass::rows` thành `std::span`; `ui_panel_tests.cpp`
     include `logon.hpp` và hai ca `player_frame_*` theo hình khung chân dung lúc dựng (vuông là mặc định, nhánh
     tròn vẫn giữ kỳ vọng cũ nhưng chưa dựng bản `round` để chạy nó).
   - Tốc độ: ở cây chính `ctest -j 4 --timeout 300` làm `gui_real_tests` đỏ vì hết giờ (459 s). Đo từng ca: năm
     ca đầu cộng lại khoảng 10 s; `window_boxes_match_golden` tốn gần hết, trong đó `Hub::update` 50–72 s và 94
     nghìn lần `Hub::box` 10–18 s mỗi cỡ màn hình. Nguyên nhân là `show_all` của test ép `Visible=True` lên cả
     94 nghìn cửa sổ trong khi `layout.cpp` quét tuyến tính danh sách override cho từng cửa sổ. Mã sản phẩm không
     đổi (game thật chỉ có vài override); test nay chỉ ép cửa sổ mà layout khai ẩn (`show_hidden`): 96 s, vẫn 0 ô
     lệch.
   - Đã kiểm ở cây chính có dữ liệu thật (`msvc-release`, 2026-10-14): dựng 538 bước 0 cảnh báo; `ctest -j 4
     --timeout 900 -E "^audio_tests$"` 93/93 qua, `gui_real_tests` 55–159 s tùy tải máy (trước sửa 459 s).
     Ca hồi quy `parse_image` của `gui_value_tests` đỏ trên `value.cpp` của `HEAD` (hai kỳ vọng sai: xuống dòng
     giữa `set:` và `image:`, tên bộ có dấu cách), xanh trên bản sửa. `check.py` xanh trên cả tám tệp mã và test
     đã đổi. `check.py --run` (Clang ASan + UBSan + hardening STL và GCC debug mode của libstdc++) xanh cho
     `gui_value_tests` và `gui_sheet_tests`; mỗi `--with` chỉ nhận một tệp nên phải lặp cờ, và `gui_sheet_tests`
     cần thêm `src/shared/table/tsv.cpp`, `localize.cpp`, bỏ `loader*.cpp`. Chưa chạy `gui_loader_tests` dưới
     sanitizer (cần thêm nguồn `core`, `io`, `xml` và cờ liên kết Windows; `loader.cpp` chỉ đổi một dòng
     `path_from_utf8`) và nhánh khung tròn của `ui_panel_tests` (chưa dựng bản `round`). Ảnh `--shot` của bản cài
     ở `dev/client/bin` (màn chọn máy chủ và màn chơi cảnh Đại Lý): không mất texture, chữ không chồng nhau.
     Nạp đầu (`bench_load.py`, cảnh Đại Lý 1280x720, 15 lượt): trung vị 528,7 ms, vượt ngân sách 450 ms của
     2026-10-13 (387 ms). A/B xen kẽ hai vòng x 10 lượt, cùng cây, chỉ khác `layout.cpp` (bản `ca33733` và bản mới):
     585 / 506 ms (cũ) và 608 / 487 ms (mới), lẫn nhau theo từng vòng, nên `layout.cpp` mới không làm chậm nạp. Nguyên
     nhân thật của phần vượt chưa tìm ra: lúc đo có một cửa sổ client khác đang chạy, số tăng dần trong một lượt chạy
     (482 lên 646 ms), và HUD đã đổi nhiều từ 2026-10-13. Cần đo lại lúc máy rảnh trước khi kết luận ngân sách đã vỡ.
     Cảnh báo `ninja: premature end of file` ở cây này do
     `.ninja_deps` bị cụt (nhiều lượt dựng chồng nhau); `ninja -t recompact` xoá được, và dựng lại toàn bộ một lần.
   - Bẫy đã đo: ghi ở `docs/BAY-DA-BIET.md` nhóm "Giao diện và bản địa hoá" (cỡ con là `max - min`; `grep` thấy
     dòng `<Imageset>` trong scheme không có nghĩa client nạp nó; thuộc tính ảnh ngắt dòng).

Không gộp: worktree `.worktrees/v97ed65b` (bản cũ hơn của khung chân dung/bảng đo nhịp đã nằm trong `69dd513`
..`192f181`; mọi tệp trùng `69dd513` hoặc cũ hơn `main`). Log bằng chứng chưa theo dõi của các worktree (219
tệp) nằm trong `D:\THIENLONG_wt\bang-chung-worktree-20261014.zip`; mọi trạng thái đã theo dõi có ref sao lưu
`refs/backup/wt-*` và `refs/backup/main-dirty-20261014-1120`.

Đã kiểm trên đầu nhánh gộp: `msvc-release` dựng 0 warning, `ctest` 86/86; `clang-asan` (ASan + UBSan +
hardening STL) dựng 0 lỗi, `ctest` 86/86 (bỏ `audio_tests`, `window_modal_tests` vì đụng thiết bị);
`gcc-debug` 0 lỗi biên dịch, `ctest` 70/74 (bốn test `audio_dsp_tests`, `world_tests`, `client_tests`,
`boot_tests` không link được vì thư viện vcpkg dựng bằng MSVC; Clang và MSVC chạy chúng); `unittest`
`TOOLS/content` 143, `TOOLS/server` 252 (8 bỏ qua).

Còn lại, đã biết và chưa làm (không do đợt gộp gây ra):

- Gate chưa nối kho số đo ở production: `front.cpp` dựng `Table` bằng constructor không có `Backing`, không
  có luồng `metrics::serve::Server` và dòng `ready` không mang khoá `metrics=` như mục "Máy chủ: P2-2" ở
  trên mô tả; phần đó mất cùng đợt khôi phục. Module `metrics`, `metrics/serve` và test của chúng nguyên vẹn.
- Client nhận `UiConfig` từ 2026-10-15 (xem mục "Client nối máy chủ thật (2026-10-15)"); chế độ cục bộ vẫn lấy
  `avatar_frame` từ `src/client/client.build.toml` lúc dựng.
- `check.py` (clang-tidy 438 check) còn đỏ ở mã của snapshot chưa chấm: `account/*`, `store/pg.cpp`,
  `engine/net/reactor_win32.cpp` (include-cleaner, độ phức tạp, tên ngắn...), và ở mã Forge2 `core/log.cpp:180`
  (`-Wexit-time-destructors` của `static Hub`), `core/thread.cpp:88` (`-Wcast-align` GCC), `thread.cpp:138`
  (`-Wglobal-constructors`). Cổng biên dịch `-Werror` của hai trình dịch đã xanh trên mọi tệp đụng tới ở
  lượt này.

## Client nối máy chủ thật (2026-10-15)

Nhánh `worktree-agent-a4b42ef1786c38bd5`, chưa gộp vào `main`. Thiết kế và giới hạn ở `AGENTS.md` mục 0 ("Client
đã nối máy chủ thật"). Mô-đun mới `client/session` (luồng nền, máy trạng thái thuần, bảng cổng `gates.tsv`) và
`client/online` (cầu nối với `ui/panel/online.hpp`); `link::Link` nhận `stop_token` để huỷ lúc bắt tay; chuỗi đăng
nhập (`LoginFlow`) có chế độ trực tuyến; `Display` có hai kênh `OnlineAsk`/`OnlineReply` và `EntryPoint` để đặt
nhân vật theo `Position`. Công cụ `TOOLS/server/export_gates.py` ghi `Table/gates.tsv`.

Kiểm trên cụm thật (đo 2026-10-15, MSVC `msvc-release`): dựng cụm tạm (PostgreSQL tạm, gate `127.0.0.1:0`) bằng
bản sao `dev/server/config`, rồi chạy một chương trình thử tạm (không vào repo) đi đúng đường của viewer qua
`Bridge`. Kết quả thật: SignIn 195 ms ra danh sách rỗng, Create nhân vật `Lam` (nam, mặt 100, tóc 5) 257 ms ra danh
sách 1 nhân vật (id=1, cấp 1), EnterGame 303 ms ra `UiConfig` (khung vuông) rồi `Position` cảnh 2, x=16500 cm,
z=16900 cm; giữ phiên 4 giây vẫn ở `kInGame`; `Drop` về `kIdle`. Cụm dừng sạch (mã thoát 0, không còn tiến trình).
`thienlong_client --login --frames 150` với `gates.tsv` tạm in `Bảng cổng máy chủ: 1 máy chủ trực tuyến`. Chưa bấm
thật giao diện đăng nhập (cấm điều khiển chuột); đường UI được kiểm bằng `ui_flow_tests` và `online_tests`.

Bẫy đã đo: tên tài khoản chỉ nhận `[0-9A-Za-z_]` (dấu `-` bị trả `kBadCredentials` dù `auto_register = true`);
khuôn mặt/tóc phải thuộc bảng của máy chủ (`default_look_policy`: nam mặt 100..104/113, tóc 5/12/14), sai thì
`kBadOption` và client báo `kOther`. `check.py` chỉ in 15 chẩn đoán đầu và `misc-include-cleaner` cần `-I` tuyệt đối.

Còn thiếu: gửi `Move`, vẽ thực thể `Entity*`, bộ đồ và chân dung theo máy chủ, báo mất kết nối khi đang chơi,
`SceneEnter` khác cảnh đã nạp, Android và iOS (vẫn vào thẳng cảnh).

## Còn lại

Đối chiếu với mã ngày 2026-10-08, `main` ở `501743a`; các dòng "Giao diện", "Hình" và "Dựng lại cây chung"
đã đối chiếu lại với mã ngày 2026-10-13. Mỗi dòng trỏ tới mục giữ chi tiết.

- **Dựng lại cây chung**: `build/clang-asan` và `build/msvc-release` chưa dựng lại từ các lần gộp
  tối 2026-10-08; số đo của hai trình dịch ấy mới có ở cây riêng, thiếu `service_tests`,
  `server_boot`, `audio_tests` và exe `thienlong_client` (mục "Khảo sát theo mã"; `NGHI-NGO.md`
  mục 44h). Cổng cảnh báo của CMake còn là bộ 23 cờ cũ (`NGHI-NGO.md` mục 45g).
- **B6, phép so hộp bao bằng số**: `TOOLS/content/expected_bounds.py` đã có, client chưa có tuỳ
  chọn `--dump-bounds`, nên chưa lần nào so được ngưỡng 0,001.
- **Máy chủ**: P2 còn `ipc`, `metrics`, việc gate chuyển tiếp và các nợ của mục "Máy chủ: P2 đợt
  3, phần đầu"; rồi tới P3 (tài khoản, nhân vật, `store`, migration, `link`). Bảng mốc và trạng thái
  theo mã ở `KE-HOACH-SERVER.md` mục 10. Ba bộ dữ liệu máy chủ gốc và bản Linux 0.85.8130 còn ký
  hiệu chưa được dùng để đối chiếu (cùng tệp, mục 2). Linux: chưa dựng lần nào, và `core` còn một
  chỗ chỉ Android có (`NGHI-NGO.md` mục 45a).
- **Mặt đi được của công trình** (`.WCollision`): `SRC/collision` đã có bộ đọc, lưới, cây OPCODE;
  còn API truy vấn (`Model`, `load`, `height`, `raycast`), sáu tệp chưa qua `check.py`, và việc nối
  vào client (mục "Va chạm công trình, đợt DH 1"; `NGHI-NGO.md` mục 41).
- **Đường đi**: vùng cấm động, trạng thái bay, thuật toán dự phòng khi né góc, câu báo "không tới
  được" (mục "Đường đi và vật cản"; `NGHI-NGO.md` mục 39).
- **Giao diện**: nối sổ nhiệm vụ và sách võ đã port vào HUD (`NGHI-NGO.md` mục 43); nội dung bảng
  hành trang; bấm thẻ và cộng điểm của bảng nhân vật (`NGHI-NGO.md` mục 36). Thương thành hiện tám
  mục và kệ, chưa có hàng và giá (script 888902 không có trong cây); giao dịch không mở khung khi
  chưa có lời mời; Về Đăng Nhập chưa có đường (`NGHI-NGO.md` mục 42). Bản đồ cảnh và bản đồ thế
  giới đã port ngày 2026-10-13 (`TAILIEU/MAN-CHOI-GIAO-DIEN-2026.md`). Chữ giao diện còn viết thẳng trong
  C++ ở vài bảng.
- **Hình**: nước và vòm trời có mã dựng và vẽ (`ensure_water`, `ensure_sky` ở `client/display/graphic/scene.cpp`),
  chưa ai đối chiếu ảnh với bản 2026; `fx` còn thiếu pipeline trộn alpha, hạt mesh, xoay hạt, thời
  lượng của emitter (`NGHI-NGO.md` mục 40a; ngày 2026-10-13 đã thêm `SequenceFrame`, `DirectionRandomiser` và
  kiểu trộn `zero one_minus_src_colour`); D3D12 và D3D11 chưa hiển thị (`NGHI-NGO.md` mục 25).
- **Client chưa có**: NPC, quái, vật phẩm, vũ khí, người chơi khác, kết nối máy chủ (module `link`
  là việc của P3). Mọi số trên HUD lấy từ nhân vật mẫu viết cứng.
- **Android / iOS** (2026-10-09): thủ tục đăng nhập dùng chung `client/boot` với PC (`--login`):
  nền `erengu_DL`, chọn nhân vật `tl3chuangjian`, vào game mới nạp `Config/startup.id`. APK
  `build/android-arm64/thienlong.apk` 1.667.694.510 byte, 3.597 tệp assets, có cả hai cảnh đăng
  nhập. Chạm Android đổi sang điểm (dp). Acquire Vulkan chờ tối đa 100 ms để pause không kẹt join.
  Máy tính bảng HA1RC00J đang `unauthorized` nên chưa cài. iOS đủ mã (MoltenVK, chạm, Documents
  cho `Save/roles.tsv`, ngang, trang Coming soon trong app) nhưng máy này không có macOS nên chưa
  dựng bundle. GLES `eglSwapBuffers` vẫn không có hạn chờ: kẹt pause trên máy chỉ có GLES là nợ cũ.

Mục "Phạm vi đã đo của phần còn lại" ngay dưới là số đo ngày 2026-10-05, trước khi làm B2 tới B5:
phần mã đó đã chép xong, bảng giữ lại làm số tham chiếu chứ không còn là việc phải làm.

## Phạm vi đã đo của phần còn lại (2026-10-05)

Đo bằng bao đóng `#include` trên `src/` của Forge2@d7fcd76, bỏ thư mục `d3d12` và các tệp
`*_android.cpp`, mỗi header kéo theo tệp `.cpp` cùng tên; trừ đi 12 tệp core dự án đã có. Đây là
trần: phần `fs` có thể thay bằng `io` của THIENLONG, `anim` chỉ vào qua `resource/rig.hpp` mà vật
thể tĩnh không cần.

| Hạt giống | Tệp còn thiếu | Dòng còn thiếu | Theo module |
|---|---|---|---|
| `gpu` (B2) | 59 | 13.115 | gpu 35 tệp 8.095 dòng; shader 8 tệp 1.511; fs 8 tệp 1.684; core 8 tệp 1.825 |
| `gpu`, `shader`, `resource`, `render`, `capture/png.hpp` (B2 tới B5) | 125 | 30.562 | gpu 8.095; math 4.499; shader 4.263; resource 3.122; fs 2.581; core 2.244; jobs 2.142; render 1.430; capture 1.378; anim 808 |

B1 là 21 tệp, 4.191 dòng gốc. B2 lớn cỡ ba lần B1 và không tách nhỏ được: chỉ để xoá màn một màu
cũng cần thiết bị, bộ nhớ, danh sách lệnh và swapchain của backend. Hai việc cần chủ dự án chốt
trước khi vào B2: có cho commit giữa chừng trong một bước con hay không (hiện chỉ được commit khi
bước con đạt đủ tiêu chí), và phần `fs` mà `shader` kéo theo thay bằng `io` tới mức nào.

## Cách làm đã dùng ở B1 (dùng tiếp)

1. Đọc trọn tệp gốc của Forge2. Trước mỗi phần mới: so với bản tương ứng ở các engine tham chiếu,
   ghi kết quả vào `docs/NGUON-FORGE2.md`.
2. `python TOOLS/port/forge2_port.py copy <nguồn> <đích>` — từng tệp một, theo chuỗi `#include`.
3. `python ~/.claude/cpp23/tools/check.py --fix <đích>`; sửa tới 0 lỗi. Lỗi thường gặp và cách đã
   xử lý nằm ở mục "Quy ước chung" của `docs/NGUON-FORGE2.md`; include thiếu thì hỏi
   `forge2_port.py includes <đích>`.
4. Thêm dòng `// Nguồn: Forge2 <đường dẫn>@d7fcd76. Khác gốc: ...` ở đầu tệp, `Khác gốc:` tại chỗ
   cho mỗi chỗ đổi hình dạng, một dòng trong bảng của `docs/NGUON-FORGE2.md`.
5. Nối vào CMake, build, rồi mới sang tệp kế. `python TOOLS/port/forge2_port.py measure` cho số đo.

## Lệnh kiểm của mỗi bước con

```
cmake --workflow --preset gcc-debug
cmake --workflow --preset clang-asan
cmd /c "call %USERPROFILE%\.claude\skills\cpp-build\dev.bat && cmake --workflow --preset msvc-debug"
cmd /c "call %USERPROFILE%\.claude\skills\cpp-build\dev.bat && cmake --workflow --preset msvc-release && cmake --install build/msvc-release"
cmake --workflow --preset android-arm64
CLIENT\bin\thienlong_client.exe --scene huoyangu --frames 90
```

Preset `android-arm64` chạy test trên thiết bị qua adb; không có thiết bị thì chỉ dựng.

## Quyết định và giả định của B1

- Ngưỡng 30% của ba tệp đầu: đo được 4,6%, 0% và 4,9% nên đi tiếp. Hai tệp về sau vượt 30% tổng số
  dòng đổi (`core/error.cpp`, `window/cursor.cpp`) nhưng phần đổi là cơ học (tiền tố `k`, định dạng);
  phần sửa tay lớn nhất của một tệp là 11,6%. Giả định của phiên làm việc: đổi cơ học bằng công cụ
  không tính vào ngưỡng dừng; chủ dự án chưa xác nhận.
- Phần GPU chưa có nên chưa có gì bị loại khỏi GCC, Android, iOS. Module `window` dựng trên cả ba
  trình dịch của Windows; Android và iOS dựng bản client không cửa sổ (`viewer_none.cpp`).
- Phần cửa sổ và log giữ bản Forge2 sau khi so với Platium (bảng ở `docs/NGUON-FORGE2.md`).
