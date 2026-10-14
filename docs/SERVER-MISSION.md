# Máy chủ — nhiệm vụ, hội thoại, NPC (module `ops`, `bus`, `ledger`, `mission`, `talk`, `handlers`)

Sáu module thuần của máy chủ: không mạng, không database, không đồng hồ thật, không luồng, không Lua chạy lúc vận hành. Ngẫu nhiên là
`dice::Dice` do nơi gọi đưa vào; lịch là đầu vào (`ops::Calendar` tính từ tick); mọi thao tác đổi trạng thái là một giao dịch nguyên tử.
Chưa module nào được zone, world hay gate gọi: nối vào là việc của đợt tích hợp (mục 6).

Tài liệu này viết sau khi phiên làm việc bị dừng giữa chừng; số đo ở mục 3 do `mission_data_tests` và `talk_data_tests` in ra
trên bảng thật lúc commit, không phải số nhớ.

## 1. Bản đồ

- `ops` — tập điều kiện và hiệu ứng ĐÓNG. Điều kiện ở dạng tuyển chuẩn (OR của các AND, phủ định ở nguyên tử), kích thước có trần
  (`kMaxClauses`, `kMaxAtoms`), đánh giá không đệ quy và không cấp phát trên một `HeroView` chỉ đọc; kết quả là `Plan` (danh sách hiệu
  ứng đã quyết định) để bên gọi áp dụng. Đọc `ops_conditions.tsv`, `ops_effects.tsv`.
- `bus` — hàng đợi sự kiện theo tick (lên cấp, nói chuyện, giết quái, vào vùng, đổi vật phẩm). Xả theo thứ tự loại cố định rồi giữ thứ
  tự phát, nên kết quả không phụ thuộc thứ tự các hệ phát sự kiện; có trần, đầy thì từ chối và đếm.
- `ledger` — sổ cái nguyên tử: một `Request` là một giao dịch (thu vật phẩm, thu tiền, nhận vật phẩm, nhận tiền, nhận kinh nghiệm theo
  giai đoạn cố định). Idempotent theo mã yêu cầu (`Journal` nhớ 64 biên nhận gần nhất; mã cũ hơn mốc đã quên bị `kStale`). Lõi không
  biết túi hay ví: nó nói chuyện với ba cổng trừu tượng `ItemPort`, `WalletPort`, `ExpPort`, cho phép chụp và quay lại chính xác.
- `mission` — `Book` (sổ nhiệm vụ của một nhân vật, bố cục ô và bit khớp từng trường với `Slot` của client
  `src/client/book/quest/log.hpp`), `Catalog` (nạp `mission_*.tsv`), `Engine` (nhận, đang làm, nộp, bỏ, hỏng; hai pha: kiểm chỉ đọc, rồi
  dựng bản nháp + chạy sổ cái + thay `Book`), `codec` (bản ghi bền). Nhiều dòng cùng id nhiệm vụ là các biến thể: nhận theo id chọn
  biến thể có cấp cao nhất không vượt cấp nhân vật (quy tắc của dự án, không phải của script gốc).
- `talk` — hội thoại do máy chủ giữ (`Service`): client chỉ gửi ý định (`Talk`, `ChooseOption`, `AcceptQuest`, `TurnInQuest`,
  `AbandonQuest`), không bao giờ gửi id script. Mỗi nhân vật tối đa một phiên, mã tăng ngặt; chọn lựa chọn thì máy chủ tính lại hộp
  thoại hiện tại và trả `kOptionGone` kèm hộp mới nếu trạng thái đã đổi.
- `handlers` — bảng handler viết tay cho điểm vào mà bộ trích không dịch được. HIỆN RỖNG (0 handler): mọi họ điểm vào chưa trích được
  đều cần hệ thống ngoài làn này (đội, thành phố bang, kỹ năng sống, phụ bản...), và viết handler trước khi hệ thống ấy tồn tại là viết
  mã giả. Cơ chế (khoá `(script, num)` cố định, một dòng lý do, `audit()` cấm đè điểm vào `ok`) đã chạy và có test.

Tầng (`cmake/GameLayers.cmake`): ops < bus, ledger < mission < talk < handlers.

## 2. Dữ liệu và công cụ

`TOOLS/server/lua_extract.py` (19 tệp `lua_*.py`, `test_lua_extract.py` 35 ca) đọc TĨNH script Lua 4.0 của máy chủ 14 môn phái
(`G:\XJL7457`, `Public/Data`; không bao giờ chạy Lua) bằng bộ phân tích riêng rồi hạ từng hàm bằng bộ đánh giá từng phần với trạng thái
người chơi tượng trưng. Cái hạ được thành điều kiện và hiệu ứng thuộc tập op đóng; cái không hạ được ghi `unsupported` kèm lý do, không
bỏ im. Danh bạ nhiệm vụ của client 2026 là thẩm quyền cao nhất cho tên, cấp, NPC giao/trả, loại; Lua chỉ quyết định logic.

Bảng sinh ra ở `dev/server/tables/server/` (đầu tệp ghi "sửa tay sẽ mất ở lượt xuất sau"): `mission_quests`, `mission_objectives`,
`mission_rewards`, `mission_prereqs`, `mission_hooks`, `mission_auto`, `mission_npcs`, `mission_name_groups`, `mission_strings`;
`talk_entries`, `talk_blocks`, `talk_npc_events`, `talk_npc_roles`; `ops_conditions`, `ops_effects`. Sinh lại: `python -X utf8 -I
TOOLS/server/lua_extract.py --lua <Public/Data> --tables dev/server/tables --out dev/server/tables/server` (`--check` chạy hết nhưng
không ghi, in báo cáo). `mission_strings.id` là fnv1a32 (u32) nên kiểu cột là `text`; khai `int` làm `thienlong_lint` báo 1278 lỗi.

## 3. Số đo (bảng thật, lúc commit `9e0cc4d0`)

Nhiệm vụ (`mission_data_tests`): 1349 nhiệm vụ — chạy được 1063, chưa hỗ trợ 260 (mỗi cái có lý do), ngoài client 26, bị chặn 0; 18 có
tiền đề ngoài danh mục. 1029/1029 nhiệm vụ bảng đi hết nhận, tiến độ, nộp. Chuỗi dài nhất (50 nhiệm vụ, bắt đầu script 1020100, cấp
75) và chuỗi cấp thấp nhất (5 nhiệm vụ, bắt đầu script 1010240, cấp 20) đều đi hết. Lý do lớn nhất của 260 nhiệm vụ chưa hỗ trợ: mục
tiêu loot ngẫu nhiên theo bảng `MissionItem` (107, chưa có bộ chạy), 26 không có trong danh bạ client, hiệu ứng `call` trong hàm giá
trị `CheckAccept` (31), phép tính trên giá trị không phải hằng (14+), hộ tống (6, cần NPC đi theo: vai AI/zone), các API phụ bản
(`LuaFnGetCopySceneData_Param`, 5+4+2+1+1).

Hội thoại (`talk_data_tests`): 9577 khối, 19258 bước, 3916 điểm vào — trích được 2398, không có hội thoại 188, chưa trích được 1330.
1727 script NPC × 3 cấp: mở được 2863 hộp thoại gốc, chạy 3459 lựa chọn (1911 chạy được, 1548 không có hội thoại). Lý do lớn nhất của
1330 điểm chưa trích: `LuaFnIsObjValid` (209), `for-in` trên giá trị không phải bảng (117), `GetAbilityExp` (112), `GetTeamId` (100),
`LuaFnGetCopySceneData_Param` (58), `CityGetCityName` (54), `LuaFnGetAbilityLevelUpConfig` (51), `LuaFnItemBind` (49).

## 4. Khác gốc, giả định

- ADR-001 của TLBB Dev chọn cây biểu thức; bản này dùng dạng tuyển chuẩn vì script gốc dùng `and/or/not` tuỳ ý và bộ trích rút về
  dạng này lúc trích (đánh giá không đệ quy, có chặn trên theo dữ liệu nạp).
- Chọn biến thể nhiệm vụ lúc nhận theo cấp là quy tắc của dự án; script gốc để script quyết định.
- Mỗi bước `effects` của một hộp thoại là một giao dịch; một lần chạy nhiều bước dừng ở bước bị từ chối và giữ các bước trước, đúng
  như script gốc đã chạy tới đó.

## 5. Chưa kiểm, chưa làm

- Theo báo cáo của phiên làm việc (chưa tự đo lại), 827 id nhiệm vụ của client không có script cũng không có bảng, trong đó chuỗi tân
  thủ 1400–1424: client có mà máy chủ không có nội dung. Cần quyết định nguồn (viết tay hay lấy từ nguồn khác) trước khi người chơi mới
  chơi được từ đầu.
- Ba test của `talk` biên dịch sạch `-Werror` với GCC 16 và Clang 23 (`check.py --no-tidy`); clang-tidy trên file test chưa xanh (chủ yếu
  `misc-include-cleaner`, `modernize-use-designated-initializers`, `misc-const-correctness`), theo luật dự án test chỉ cần biên dịch và chạy.
  Mã nguồn sáu module qua `check.py` xanh theo báo cáo của phiên làm việc (33 tệp), chưa chạy lại ở đây. Test xanh dưới MSVC và clang-asan
  (ASan + UBSan). Chưa TSan (Windows không có), chưa GCC debug mode.
- Không có handler viết tay nào; `docs/NGHI-NGO.md` chưa có mục cho việc này.
- `mission_book_tests` include `quest/log.hpp` của client để đối chiếu bố cục (đường include thêm ở `cmake/server/mission.tests.cmake`):
  test duy nhất của máy chủ biết đường dẫn client; `game_reject_foreign` không quét `Test/`.

## 6. Nối vào đâu (đề xuất, chưa làm)

Zone giữ một `mission::Engine` và `talk::Service`; `bus::Bus` nhận sự kiện từ zone (giết quái, vào vùng), từ `item` (đổi vật phẩm), từ
`actor` (lên cấp), xả mỗi tick. `ledger` cần ba cổng thật: `ItemPort` bọc `item::Inventory`/`Planner`, `WalletPort`, `ExpPort` bọc
`actor::Body`. Tin mạng cho nhiệm vụ và hội thoại chưa có trong `protocol` (hiện 27 tin version 3, không có nhóm này).
