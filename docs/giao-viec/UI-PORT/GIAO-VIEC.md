# UI-PORT — port script giao diện của client 2026 sang C++ (điều phối: phiên thienlong-2d)

Chủ dự án giao ngày 2026-10-15: chuyển toàn bộ script `src/client/script/Interface` (2 032 cửa sổ, 784 828 dòng Lua 5.0)
sang C++23 thuần, production grade, đối chứng với script gốc; cửa sổ nào cần máy chủ thì làm luôn phần máy chủ; commit
từng phần. Được dựng công cụ chuyển đổi hoặc tải công cụ ngoài khi cần (chủ dự án cho phép ngày 2026-10-15).

## Hàng đợi

`HANG-DOI.tsv`, sinh bằng `python -B TOOLS/port/ui_inventory.py` (đọc tĩnh, không chạy Lua). Cột: thứ tự, cửa sổ, độ sâu
từ HUD (đồ thị "A đẩy sự kiện B đăng ký", bỏ sự kiện phát chung), `server_opened` (đăng ký `UI_COMMAND`: script máy chủ
bật cửa sổ bằng `DispatchUICommand`), `npc_bound` (đăng ký `OBJECT_CARED_EVENT`), số dòng, số hàm, sự kiện vào/ra, đối
tượng API của `Game.exe` được gọi, đã có bản port chưa. Số đo 2026-10-15: 33 cửa sổ HUD (39 808 dòng), 322 cửa sổ cách HUD
1..3 bước, 1 403 cửa sổ do máy chủ bật (551 755 dòng; cần client nối máy chủ, client chưa mở socket nào).

## Đợt 1: 33 cửa sổ HUD (độ sâu 0)

| Phiên | Cửa sổ (thứ tự làm) |
|---|---|
| thienlong-e7 | ProgressBar, DebugListBox, Operation, SoundSetup, GameSetup, ViewSetup, AcceSetup, PlayerImpactFrame, AutoAttack_Button, MiniMap, LargeMap, SceneMap |
| thienlong-c8 | MainMenuBar_3, MainMenuBar_4, FunctionBarRight_2, FunctionBarRight, MainMenuBar_2, MainMenuBar, ZhenfaSkill, LifeSkill, CommonSkill, ActionSkill, AutoAttackSkill, ZongMenSkill |
| sau (giao khi xong phần trên) | PlayerFrame, ChatFrame, Friend, TeamFrame, Pet, YuanbaoShop, Packet, SelfEquip, QuestLog (bốn cái cuối đã port một phần) |

## Một cửa sổ là xong khi

1. Mỗi hàm Lua của cửa sổ (kể cả hàm trong tệp phụ của thư mục) có đúng một trong hai: hàm C++ dịch nó (comment ghi tên
   hàm Lua gốc), hoặc một dòng trong mục "Khác gốc" ở đầu `.hpp` nói hoãn vì sao (hệ thống nào chưa có). Ghi số
   "port X/Y hàm" vào commit và vào `TIEN-DO.tsv`.
2. Số vàng: ít nhất một kịch bản chạy script gốc trên `LuaPlus.dll` của `D:\XTLBB\Bin64` bằng `TOOLS/port/lua_oracle.py`;
   mọi widget và hàm game mà kịch bản đi qua phải được mô phỏng (thiếu là số vàng sai mà test vẫn xanh); `math.random`
   đưa dãy sẵn. Test `Test/Ui/ui_<cửa sổ>_tests.cpp` so từng byte với `Test/golden/panel/<cửa sổ>_<kịch bản>.tsv`.
   Không sửa tay số vàng.
3. Tệp: `src/client/face/ui/panel/<tên>.hpp/.cpp`, API giả `TOOLS/port/oracle/<tên>_api.lua`, kịch bản
   `TOOLS/port/oracle/<tên>_<kịch bản>.lua`. Hàm game mà script gọi (`Player:...`, `DataPool:...`) port từ mã máy
   (`TAILIEU/GAME-EXE-2026/lua_api.tsv` cho địa chỉ, `decompile.zip` cho thân hàm) vào module game đúng tầng, không
   viết tắt trong panel.
4. Nối vào HUD (`face/ui/hud.cpp`) nếu cửa sổ đang hiện trên HUD; chạy client vừa dựng bằng `--shot` để nhìn
   (không dùng `click_shot.py` với bước chuột, không chiếm chuột).
5. Kiểm: cây dựng riêng trong worktree (`cmake --preset msvc-release` rồi chỉ build target cần, không build `all`),
   0 cảnh báo; `check.py` xanh trên mọi tệp C++ đã đổi (cần `CPP23_G14/G15/C20` và `CPP23_TIDY_ARGS` với `-I` của
   `engine`, `src`, `src/client`, `src/client/face` ..., xem BAY-DA-BIET); test của cửa sổ xanh, `layers` xanh.
6. Cần dữ liệu máy chủ: thêm tin vào `src/shared/protocol/catalog/*.tsv` rồi `gen_protocol.py`, làm phía máy chủ
   (gate/zone/world), test logic thuần; ghi rõ phía client chưa nhận được vì client chưa có socket.
7. Mỗi cửa sổ một commit trên nhánh của phiên (`git -c user.name=myhea -c user.email=myhea@localhost commit`, thông điệp
   tiếng Việt, dòng cuối `Co-Authored-By: Claude ... <noreply@anthropic.com>` theo model của phiên). Báo thienlong-2d
   mã commit; thienlong-2d gộp vào `main`, dựng lại và chạy `ctest` sau mỗi lần gộp. Phiên không tự gộp, không push.

## Luật chung

- Worktree riêng: thienlong-e7 ở `.worktrees/ui-e7` (nhánh `ui/e7`), thienlong-c8 ở `.worktrees/ui-c8` (nhánh `ui/c8`).
  Không sửa cây chính `D:\THIENLONG`, không đụng `build/` của cây chính.
- Worktree thiếu thư mục gitignore (`dev/client/assets`, `dev/server/tables/shared`): đọc từ cây chính bằng đường tuyệt
  đối, không chép vào worktree.
- Tệp dùng chung dễ đụng nhau: `ui/panel/call.hpp` (enum `Ask`), `face/ui/hud.cpp`, `CMakeLists.txt`/`cmake/*`. Thêm vào
  cuối danh sách, mỗi lần một ít, nói rõ trong commit; thienlong-2d giải xung đột khi gộp.
- Gọi skill `cpp23` và đọc `MAP.md` trước khi viết C++. Comment, log tiếng Việt có dấu; định danh tiếng Anh.
