-- Thanh action MainMenuBar_2 (ô 31..40, mười ô): khác FunctionBarRight ở chỗ mở bằng OPEN_MENUBAR_2 (hiện rồi chạy hoạt ảnh
-- <ô>_Mask của mười ô; ở cảnh TLCJ thì đóng), hai dải id của CHANGE_BAR lệch nhau ở hai đầu (đặt khi 31 <= id < 41, gỡ nháy khi
-- 30 < id <= 40), gỡ gói đẩy cấp 3 (UNINSTALL_CHAT_ACTION_BAR2), dọn gói chuyển tiếp cho FunctionBarRight, và nhánh hướng dẫn
-- tân thủ của UI_COMMAND 20130527 (mở lớp hướng dẫn quanh ô mới đặt, Clicked đóng nó).
-- Chạy: bash TOOLS/port/ui_oracle.sh MainMenuBar_2 main_menu_bar_2 bar --lib TOOLS/port/oracle/ui_common_api.lua
--   --lib TOOLS/port/oracle/action_bar_api.lua --lib TOOLS/port/oracle/main_menu_bar_4_api.lua
-- Gói cài như function_bar_right_bar.lua: ô 2 gói đơn (id 7, ba hành động từ chỉ số 4 của danh sách chatmood), ô 4 gói đôi
-- (id 9, hai hành động từ chỉ số 1 của danh sách double_chatmood), ô 6 có dòng DBC nhưng real id 0, ô 8 có real id nhưng
-- không có hành động nào.
__moods = { 900, 901, 902, 903, 904, 905, 0, 907 }
__double_moods = { 1100, 1101, 1102, 1103, 1104 }
__chat_packs[2] = { id = 7, count = 3, min = 5, kind = 1 }
__chat_packs[4] = { id = 9, count = 2, min = 2, kind = 2 }
__chat_packs[6] = { id = 11, count = 3, min = 5, kind = 1 }
__chat_packs[8] = { id = 13, count = 0, min = 5, kind = 1 }
__real_ids[7] = 7
__real_ids[9] = 9
__real_ids[13] = 13
__place_frame(150.5, 600.25)
__place_button(1, 6, 18, 32, 32)
__place_button(3, 70, 4.5, 32, 30.5)
__place_button(10, 316, 4, 31.5, 32)
--@steps
__event("FLASH_COMBOSKILL", "31", "1")
__dump("nháy cấp thấp khi thanh còn ẩn")
__event("CHANGE_BAR", "main", "31", "301")
__dump("đặt ô 31 khi thanh ẩn: cờ nháy không bị gỡ")
__event("OPEN_MENUBAR_2", "1")
__dump("mở thanh: hiện và chạy hoạt ảnh mười ô")
__event("CHANGE_BAR", "main", "31", "301")
__dump("đặt lại ô 31 khi thanh hiện: nháy bị gỡ")
__event("FLASH_COMBOSKILL", "32", "2")
__dump("nháy cấp cao ô 32")
__event("FLASH_COMBOSKILL", "32", "2")
__dump("nháy cấp cao lần hai không đổi gì")
__event("FLASH_COMBOSKILL", "32", "1")
__dump("đổi sang nháy cấp thấp")
__event("FLASH_COMBOSKILL", "32", "0")
__dump("tắt nháy")
__event("FLASH_COMBOSKILL", "41", "1")
__dump("nháy vượt dải 31..40")
__event("FLASH_COMBOSKILL", "30", "1")
__dump("nháy dưới dải 31..40")
__event("FLASH_COMBOSKILL", "40", "1")
__dump("nháy ô cuối 40")
__event("CHANGE_BAR", "main", "33", "305", "0")
__dump("ô 33 với thú cưng 0 không có")
__event("CHANGE_BAR", "main", "32", "302")
__dump("ô 32 không nêu arg3: dùng arg3 cũ là thú cưng 0")
__pets.present[1] = true
__pets.fighting[1] = true
__event("CHANGE_BAR", "main", "34", "306", "1")
__dump("ô 34 với thú cưng 1 đang chiến đấu")
__pets.fighting[1] = false
__event("CHANGE_BAR", "main", "35", "307", "1")
__dump("ô 35 với thú cưng 1 có mặt nhưng không chiến đấu")
__event("CHANGE_BAR", "main", "36", "308", "9")
__dump("ô 36 với số thú cưng ngoài dải 0..5")
__event("CHANGE_BAR", "main", "40", "309", "9")
__dump("ô cuối 40")
__event("CHANGE_BAR", "main", "30", "1")
__dump("CHANGE_BAR dưới dải vẫn gọi UpdateActionButton")
__event("CHANGE_BAR", "main", "41", "1")
__dump("CHANGE_BAR vượt dải vẫn gọi UpdateActionButton")
__event("CHANGE_BAR", "other", "31", "1")
__dump("CHANGE_BAR có arg0 lạ bị bỏ qua")
pcall(__event, "CHANGE_BAR", "main", "40.5", "2")
__dump("40,5 nằm trong dải đặt (< 41) nhưng không có ô: gọi UpdateActionButton rồi dừng")
pcall(__event, "CHANGE_BAR", "main", "30.5", "2")
__dump("30,5 ngoài dải đặt (>= 31) nhưng trong dải gỡ nháy (> 30): ô không có, dừng")
pcall(__event, "CHANGE_BAR", "main", "31.5", "2")
__dump("31,5 không nguyên trong cả hai dải: dừng ở SetActionItem")
pcall(__event, "CHANGE_BAR", "main", "chu", "2")
__dump("chỉ số không phải số: gọi UpdateActionButton rồi dừng")
__event("FLASH_COMBOSKILL", "31", "1")
__event("FLASH_COMBOSKILL", "35", "2")
__event("ACTION_UPDATE")
__dump("nhắc nháy mới cho mọi ô")
__event("CHANGE_BAR", "mainreset", "3", "31", "35", "99")
__dump("dọn ba ô 31, 35, 99")
__event("CHANGE_BAR", "mainreset", "1", "40")
__dump("dọn một ô 40")
pcall(__event, "CHANGE_BAR", "mainreset", "6", "32")
__dump("dọn nhiều ô hơn số đối số: eventTable còn giá trị cũ rồi gặp nil và dừng")
__event("UNINSTALL_CHAT_ACTION_BAR2", "11")
__dump("gỡ gói ngoài dải 0..10")
pcall(__event, "UNINSTALL_CHAT_ACTION_BAR2", "chu")
__dump("gỡ gói với chỉ số không phải số")
__event("CHANGE_BAR", "main", "32", "905")
__event("CHANGE_BAR", "main", "33", "903")
__event("CHANGE_BAR", "main", "34", "906")
__event("CHANGE_BAR", "main", "35", "0")
__event("CHANGE_BAR", "main", "36", "1102")
__event("CHANGE_BAR", "main", "37", "1101")
__event("UNINSTALL_CHAT_ACTION_BAR2", "2")
__dump("gỡ gói đơn ô 2: ô trùng hành động bị gỡ")
__event("UNINSTALL_CHAT_ACTION_BAR2", "4")
__dump("gỡ gói đôi ô 4: hai ô trùng hành động đôi bị gỡ")
__event("UNINSTALL_CHAT_ACTION_BAR2", "6")
__dump("gỡ gói không có real id")
__event("UNINSTALL_CHAT_ACTION_BAR2", "8")
__dump("gỡ gói không có hành động nào")
__event("UNINSTALL_CHAT_ACTION_BAR2", "3")
__dump("gỡ gói ô chưa cài")
__event("CHANGE_BAR", "main", "38", "904")
__event("CLEAR_CHAT_ACTION_BAR", "MainMenuBar_4", "2", "5", "6")
__dump("dọn gói của thanh khác thì bỏ qua")
__event("CLEAR_CHAT_ACTION_BAR", "FunctionBarRight", "2", "5", "6")
__dump("tên FunctionBarRight không phải MainMenuBar_2: bỏ qua")
__event("CLEAR_CHAT_ACTION_BAR", "MainMenuBar_2", "2", "5", "6")
__dump("dọn gói quá hạn của MainMenuBar_2 rồi chuyển cho FunctionBarRight")
__event("CLEAR_CHAT_ACTION_BAR", "MainMenuBar_2", "-1", "5", "6")
__dump("dọn gói ô âm")
__event("CLEAR_CHAT_ACTION_BAR", "MainMenuBar_2", "7", "5", "6")
__dump("dọn gói ô chưa cài vẫn chuyển tiếp")
pcall(__event, "CLEAR_CHAT_ACTION_BAR", "MainMenuBar_2", "7", "chu", "6")
__dump("dọn gói với dữ liệu không phải số: game từ chối")
__event("CHAT_ADJUST_MOVE_CTL", "1920", "1080")
__dump("CHAT_ADJUST_MOVE_CTL: thân hàm toàn dòng chú thích, không đổi gì")
__event("UI_COMMAND", "20130527")
__dump("UI_COMMAND khi PutItemToMainmenuBar2 trả isShow 0: không làm gì")
__put.is_show = 1
__put.index = 33
__event("UI_COMMAND", "1")
__dump("UI_COMMAND với arg0 lạ: không làm gì")
__xparam = 77
__event("UI_COMMAND", "20130527")
__dump("UI_COMMAND đặt vào ô 33: mở lớp hướng dẫn, làm tròn xuống toạ độ")
__put.index = 30
__event("UI_COMMAND", "20130527")
__dump("chỉ số ô 30 ngoài 31..40: không mở thêm")
__put.index = 41
__event("UI_COMMAND", "20130527")
__dump("chỉ số ô 41 ngoài 31..40: không mở thêm")
__put.is_show = 2
__put.index = 31
__event("UI_COMMAND", "20130527")
__dump("isShow khác 1: không mở thêm")
__put.is_show = 1
__event("UI_COMMAND", "20130527")
__dump("ô đầu 31")
__put.index = 40
__event("UI_COMMAND", "20130527")
__dump("ô cuối 40 với độ rộng lẻ")
__guide_owner = "Other"
__fire("MainMenuBar_2_Button_Action3")
__dump("bấm ô 33 khi chủ lớp hướng dẫn là cửa sổ khác: chỉ đánh dấu đã đóng")
__fire("MainMenuBar_2_Button_Action3")
__dump("bấm lại: không còn lớp hướng dẫn")
__event("UI_COMMAND", "20130527")
__blocking.Shop = true
__fire("MainMenuBar_2_Button_Action3")
__dump("bấm ô khi cửa hàng hiện: không làm được, lớp hướng dẫn giữ nguyên")
__blocking.Shop = false
__guide_owner = "MainMenuBar_2"
__fire("MainMenuBar_2_Button_Action3", "RBClicked")
__dump("bấm phải ô 33 khi chủ lớp hướng dẫn là MainMenuBar_2: DoAction rồi CloseFreshManGuide")
__fire("MainMenuBar_2_Button_Action3")
__dump("bấm lại: không đóng lần nữa")
__fire("MainMenuBar_2_Button_Action9")
__dump("bấm ô trống 39")
__event("OPEN_MENUBAR_2", "0")
__dump("đóng thanh")
__in_tlcj = 1
__event("OPEN_MENUBAR_2", "1")
__dump("mở thanh ở cảnh TLCJ thì đóng")
__in_tlcj = 0
__event("OPEN_MENUBAR_2", "2")
__dump("mở thanh với arg0 lạ thì đóng")
__event("OPEN_MENUBAR_2", "1")
__dump("mở lại thanh")
__event("HIDE_THIS_UI")
__dump("HIDE_THIS_UI giấu thanh đang hiện")
__event("HIDE_THIS_UI")
__dump("HIDE_THIS_UI hiện lại")
