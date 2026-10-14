# gui_real_tests — phân loại ô lệch và manh mối Timeout (chỉ đọc)
Ghi 2026-10-13 ~19:10 ICT. Không sửa source/golden/build, không chạy cmake/ctest.

## 1. Bản tsv trước/sau
- ctest 11604 / gui_real_tests 10544 chạy từ 19:01:20 / 19:01:31.
- build\msvc-release\gui_real_misses.tsv: LastWriteTime 18:40:35 (TRƯỚC 19:01) -> đúng bản 192 ô. 32310 B, SHA256 4C75B3C708177FE55D29E69BA2B7F35F94E704794EB3E0F1923A22D9CDC10F2F -> gui_real_misses_pre.tsv (193 dòng gồm tiêu đề).
- Sau lượt 19:01: tệp KHÔNG được ghi lại (mtime vẫn 18:40:35, cùng SHA256) -> gui_real_misses_post.tsv giống hệt pre, Compare-Object = 0 khác. Lý do: tiến trình bị giết ở 300 s trước khi tới dòng ghi (gui_real_tests.cpp:344). Lượt này KHÔNG cung cấp bằng chứng mới về tập ô lệch.

## 2. LastTest.log (build\msvc-release\Testing\Temporary, mtime 19:06:31)
64/94 gui_real_tests: start 19:01, end 19:06, Test time = 300.03 sec, Test Failed (Timeout). Output duy nhất:
  `gui_real_tests.cpp:133: [notes_are_known_gaps] ít tham chiếu hỏng`  -> loader->notes().size() >= 20: ca 2 ĐỎ thật, lỗi mới, độc lập với golden.
LastTestsFailed.log: 57 ui_quest_book_tests, 64 gui_real_tests.

## 3. Phân loại 192 ô (48 ô x 4 cỡ màn hình, mẫu lặp y hệt ở 1024/1280/1920/2560)
| Layout | ô | Mẫu delta (dx,dy,dw,dh) | Nhóm |
|---|---|---|---|
| ContexMenu | 48 | golden 0x0 tại (W/4,H/4); Hub 510x30 | A trùng tên (tên rỗng, trùng BT_TeamInfo) |
| BaZheTianXia_Pop | 24 | Frame 8,0,-4,-4; BK 8,0,0,0; DragTitle 8,0,-4,0; Image 4,0,0,0; Client1_Info3 25,3,-4,-4 | A trùng tên với BaZheTianXia/BaZheTianXia.layout.xml |
| ZM_Boss_Dps | 8 | AutoPickUpSet_Tit -332,13,30,0 ... | A trùng AutoPickUpSet |
| PetAgname | 4 | PetAgname_Blank -68,313,87,0 | A trùng Packet_NonPortable |
| ZBS_TeamInfo | 4 | NoDiffMatch_TeamManger_BottomFrame -19,27,37,5 | A trùng NoDiffMatch_TeamManger |
| test.layout.xml | 4 | Button_Pack 1156,1007,-80,-80 | A trùng MainMenuBar |
| BieYePersonnelManage | 40 | 0,0,+1,0 (List*_Text_3) | B ±1 rộng |
| Chengzhan_TopList | 32 | 0,0,+1,0 (Title5/8, AItemText5/8) | B |
| Chengzhan_BangHui_TopList | 16 | 0,0,+1,0 | B |
| NewBangHui_Auction | 8 | 0,0,+1,0 | B |
| NoDiffMatch_TeamInfo | 4 | 0,0,+1,0 | B |
Tổng: A = 92, B = 100. Không có ô nào theo tỉ lệ (scale): B giống nhau ở cả 4 cỡ màn hình.

### Nhóm A — so theo tên, bỏ qua layout (lỗi của TEST, không phải layout engine)
- Test/Gui/gui_real_tests.cpp:285 `hub.box(row.window)` — row.layout bị bỏ qua.
- src/client/face/gui/hub.cpp:200-203 `shown_window` = find_if theo tên, trả cửa sổ ĐẦU TIÊN cùng tên.
- Kiểm golden 1024: mỗi tên lệch nhóm A có mặt ở đúng 2 layout (vd BaZheTianXia_Pop_Frame trong BaZheTianXia.layout.xml và BaZheTianXia_Pop.layout.xml). Hub trả ô của layout kia. ui_rects.py:109-111 coi tên rỗng là "không trùng", nên ContexMenu có 12 dòng tên rỗng/cỡ.
- BaZheTianXia_Pop_Frame: golden 648,418 310x54 là của BaZheTianXia_Pop; Hub 656,418 306x50 là bản trong BaZheTianXia.layout.xml.

### Nhóm B — Hub rộng hơn 1 px, không phụ thuộc cỡ màn hình
pixel_align giống nhau: ui_rects.py:206-215 và src/client/face/gui/layout.cpp:550-553 cùng (int)(x+0.5f). Gốc CHƯA xác định: cần đọc khai Size của các cửa sổ này (không tìm thấy CLIENT\data\Interface trong D:\THIENLONG; cần đường dẫn GAME_CLIENT_DATA). Giả thuyết: cột chữ cuối của list/title bị Hub cộng hay làm tròn độ rộng cột theo cách khác (offset .5 hoặc tràn phần dư).

## 4. Manh mối Timeout
- Golden Test/golden/ui_rects.tsv = 45.128.981 B, 94.554 dòng ở 1024 (~378k dòng tổng). Đọc 1 lần (golden_rows, :253-262), không đọc lại theo layout.
- O(n^2): compare_screen (:320) lọc toàn bộ ~378k dòng cho mỗi cỡ, và mỗi dòng gọi hub.box -> hub.cpp:200 tìm tuyến tính trên ~94k cửa sổ, so chuỗi. ~94.5k x 94.5k x 4 ≈ 3.6e10 lượt so -> đủ vượt 300 s.
- load_all (nạp lại mọi layout từ đĩa) bị gọi 6 lần (:102,118,139,156,194,329).
- check-fail: main :368 `core::check(run_all(...)==0, ...)` -> abort -> 0xC0000409 (crash 281 s trước đó là ca đỏ chứ không phải hỏng bộ nhớ).
## 5. Bổ sung 19:10 ICT — tên khung HUD (chỉ đọc)
- panel/create_role.hpp:90 kCreateDetailFrame = "Createshow_Info2_Back"; panel/scene_board.hpp:22 kBoardWindow = "SceneMap_Board"; hud.cpp:1154 literal "MiniMap_MapArea".
- Khai trong dev/client/assets/Interface: Createshow_Info2_Back -> CreateRole.layout.xml:522 và phone\CreateRole.layout.xml:523; MiniMap_MapArea -> MiniMap.layout.xml:354 và phone\MiniMap.layout.xml:355; SceneMap_Board -> chỉ SceneMap.layout.xml:56.
- Golden: mỗi tên đúng 1 layout. Ô (x,y w x h):
  - Createshow_Info2_Back (CreateRole): 1024 798,198 214x190 | 1280 1054,174 | 1920 1694,354 | 2560 2334,614 (cùng 214x190)
  - MiniMap_MapArea (MiniMap): 868/1124/1764/2404 ,42 119x121
  - SceneMap_Board (SceneMap): 25,102 829x580 | 1085x532 | 1725x892 | 2365x1412
- HUD nạp hud.cpp:74 kLayouts (40 đường dẫn, không có "phone/") qua add_layouts :149-155; DiskSource::read loader.cpp:48-61 chọn MỘT bản (phone/ khi phone_, bản PC khi desktop) -> mỗi tên chỉ có 1 cửa sổ trong asset của HUD, shown_window (hub.cpp:200-203) không thể lấy nhầm. Kết luận: KHÔNG chọn nhầm ở cả 3 tên. Trùng tên chỉ xảy ra trong test khi load_all(with_phone=true) nạp cả phone/.

## 6. notes_are_known_gaps
- notes() = loader.cpp:533-534 trả cook.notes; nguồn ghi: loader.cpp:157 "không có ảnh", :302 "không có hoạt ảnh" (chỉ 1 lần/tên nhờ cook.animates), :345 "không có bộ ảnh", loader_look.cpp:68,119,302,495.
- loader.cpp:150-158 KHÔNG ghi nhớ ảnh thiếu (chỉ emplace khi tìm thấy, :161) -> mỗi lần tham chiếu ảnh thiếu thêm 1 ghi chú trùng.
- Quét tĩnh (không chạy test) mọi "set:X image:Y" trong 2071 layout so 3797 imageset: 74 tham chiếu thiếu (~45 khoá khác nhau), gồm 2 bản trùng phone\ (Chat/CommonEditBoxBK, MainMenuBar/EXPBar_3). SeventhFestivalTopList_1 một mình 12 lần, BaseInterface/Red_Dot 9 lần. + 7 hoạt ảnh đã biết => ~81 >> 20. Con số chính xác cần chạy test (không chạy).
- Nguồn gốc: code và ngưỡng 20 cùng từ d36f5e4 (2026-10-12, git blame). Dữ liệu dev/client/ bị .gitignore:16 nên không có lịch sử git; mtime: 2035 layout ngày 2026-10-10, 36 ngày 2026-10-12. Ngưỡng 20 có lẽ đặt khi còn ít layout.