-- Thanh action FunctionBarRight_2 (ô 61..69, chín ô): khác MainMenuBar_4 ở chỗ Target:UpdateActionButton chỉ được gọi
-- khi id ô nằm trong dải 61..69, dọn gói quá hạn chuyển tiếp cho MainMenuBar_4 (Clear_ChatAction_Bar), gỡ gói đẩy cấp 5
-- (UNINSTALL_CHAT_ACTION_BAR4), và mở bằng OPEN_RIGHT_BAR_2 khi người chơi không biến hình (DataPool:GetTrans() ~= 1).
-- Chạy: bash TOOLS/port/ui_oracle.sh FunctionBarRight_2 function_bar_right_2 bar --lib TOOLS/port/oracle/ui_common_api.lua
--   --lib TOOLS/port/oracle/action_bar_api.lua
-- Gói cài: ô 2 là gói đơn (id 7, ba hành động từ chỉ số 4 của danh sách chatmood: 904, 905 và một action rỗng), ô 4 là gói đôi
-- (id 9, hai hành động từ chỉ số 1 của danh sách double_chatmood: 1101, 1102), ô 6 có dòng DBC nhưng real id 0,
-- ô 8 có real id nhưng không có hành động nào.
__moods = { 900, 901, 902, 903, 904, 905, 0, 907 }
__double_moods = { 1100, 1101, 1102, 1103, 1104 }
__chat_packs[2] = { id = 7, count = 3, min = 5, kind = 1 }
__chat_packs[4] = { id = 9, count = 2, min = 2, kind = 2 }
__chat_packs[6] = { id = 11, count = 3, min = 5, kind = 1 }
__chat_packs[8] = { id = 13, count = 0, min = 5, kind = 1 }
__real_ids[7] = 7
__real_ids[9] = 9
__real_ids[13] = 13
--@steps
__event("FLASH_COMBOSKILL", "61", "1")
__dump("nháy cấp thấp khi thanh còn ẩn")
__event("CHANGE_BAR", "main", "61", "301")
__dump("đặt ô 61 khi thanh ẩn: cờ nháy không bị gỡ")
__event("OPEN_RIGHT_BAR_2", "1")
__dump("mở thanh")
__event("CHANGE_BAR", "main", "61", "301")
__dump("đặt lại ô 61 khi thanh hiện: nháy bị gỡ")
__event("FLASH_COMBOSKILL", "62", "2")
__dump("nháy cấp cao ô 62")
__event("FLASH_COMBOSKILL", "62", "2")
__dump("nháy cấp cao lần hai không đổi gì")
__event("FLASH_COMBOSKILL", "62", "1")
__dump("đổi sang nháy cấp thấp")
__event("FLASH_COMBOSKILL", "62", "0")
__dump("tắt nháy")
__event("FLASH_COMBOSKILL", "70", "1")
__dump("nháy ngoài dải 61..69")
__event("CHANGE_BAR", "main", "63", "305", "0")
__dump("ô 63 với thú cưng 0 không có")
__event("CHANGE_BAR", "main", "62", "302")
__dump("ô 62 không nêu arg3: dùng arg3 cũ là thú cưng 0")
__pets.present[1] = true
__pets.fighting[1] = true
__event("CHANGE_BAR", "main", "64", "306", "1")
__dump("ô 64 với thú cưng 1 đang chiến đấu")
__pets.fighting[1] = false
__event("CHANGE_BAR", "main", "65", "307", "1")
__dump("ô 65 với thú cưng 1 có mặt nhưng không chiến đấu")
__event("CHANGE_BAR", "main", "66", "308", "9")
__dump("ô 66 với số thú cưng ngoài dải 0..5")
__event("CHANGE_BAR", "main", "69", "309", "9")
__dump("ô cuối 69")
__event("CHANGE_BAR", "main", "60", "1")
__dump("CHANGE_BAR ngoài dải: không gọi UpdateActionButton")
__event("CHANGE_BAR", "main", "70", "1")
__dump("CHANGE_BAR vượt dải: không gọi UpdateActionButton")
__event("CHANGE_BAR", "other", "61", "1")
__dump("CHANGE_BAR có arg0 lạ bị bỏ qua")
pcall(__event, "CHANGE_BAR", "main", "61.5", "2")
__dump("chỉ số không nguyên trong dải: gọi UpdateActionButton rồi dừng")
pcall(__event, "CHANGE_BAR", "main", "chu", "2")
__dump("chỉ số không phải số: dừng ngay, không gọi gì")
__event("FLASH_COMBOSKILL", "61", "1")
__event("FLASH_COMBOSKILL", "65", "2")
__event("ACTION_UPDATE")
__dump("nhắc nháy mới cho mọi ô")
__event("CHANGE_BAR", "mainreset", "3", "61", "65", "99")
__dump("dọn ba ô 61, 65, 99")
__event("CHANGE_BAR", "mainreset", "1", "69")
__dump("dọn một ô 69")
pcall(__event, "CHANGE_BAR", "mainreset", "6", "62")
__dump("dọn nhiều ô hơn số đối số: eventTable còn giá trị cũ rồi gặp nil và dừng")
__event("UNINSTALL_CHAT_ACTION_BAR4", "11")
__dump("gỡ gói ngoài dải 0..10")
pcall(__event, "UNINSTALL_CHAT_ACTION_BAR4", "chu")
__dump("gỡ gói với chỉ số không phải số")
__event("CHANGE_BAR", "main", "62", "905")
__event("CHANGE_BAR", "main", "63", "903")
__event("CHANGE_BAR", "main", "64", "906")
__event("CHANGE_BAR", "main", "65", "0")
__event("CHANGE_BAR", "main", "66", "1102")
__event("CHANGE_BAR", "main", "67", "1101")
__event("UNINSTALL_CHAT_ACTION_BAR4", "2")
__dump("gỡ gói đơn ô 2: ô trùng hành động bị gỡ")
__event("UNINSTALL_CHAT_ACTION_BAR4", "4")
__dump("gỡ gói đôi ô 4: hai ô trùng hành động đôi bị gỡ")
__event("UNINSTALL_CHAT_ACTION_BAR4", "6")
__dump("gỡ gói không có real id")
__event("UNINSTALL_CHAT_ACTION_BAR4", "8")
__dump("gỡ gói không có hành động nào")
__event("UNINSTALL_CHAT_ACTION_BAR4", "3")
__dump("gỡ gói ô chưa cài")
__event("CHANGE_BAR", "main", "68", "904")
__event("CLEAR_CHAT_ACTION_BAR", "MainMenuBar_4", "2", "5", "6")
__dump("dọn gói của thanh khác thì bỏ qua")
__event("CLEAR_CHAT_ACTION_BAR", "FunctionBarRight_2", "2", "5", "6")
__dump("dọn gói quá hạn của FunctionBarRight_2 rồi chuyển cho MainMenuBar_4")
__event("CLEAR_CHAT_ACTION_BAR", "FunctionBarRight_2", "-1", "5", "6")
__dump("dọn gói ô âm")
__event("CLEAR_CHAT_ACTION_BAR", "FunctionBarRight_2", "7", "5", "6")
__dump("dọn gói ô chưa cài vẫn chuyển tiếp")
pcall(__event, "CLEAR_CHAT_ACTION_BAR", "FunctionBarRight_2", "7", "chu", "6")
__dump("dọn gói với dữ liệu không phải số: game từ chối")
__event("OPEN_RIGHT_BAR_2", "0")
__dump("đóng thanh")
__trans = 1
__event("OPEN_RIGHT_BAR_2", "1")
__dump("mở thanh khi biến hình thì đóng")
__trans = 0
__event("OPEN_RIGHT_BAR_2", "2")
__dump("mở thanh với arg0 lạ thì đóng")
__event("OPEN_RIGHT_BAR_2", "1")
__dump("mở lại thanh")
__event("HIDE_THIS_UI")
__dump("HIDE_THIS_UI giấu thanh đang hiện")
__event("HIDE_THIS_UI")
__dump("HIDE_THIS_UI hiện lại")
__fire("FunctionBarRight_2_Button_Action3")
__fire("FunctionBarRight_2_Button_Action4", "RBClicked")
__fire("FunctionBarRight_2_Button_Action9")
__dump("bấm ô 63, 64 và ô trống 69")
__blocking.Shop = true
__fire("FunctionBarRight_2_Button_Action3")
__dump("bấm ô khi cửa hàng hiện")
__blocking.Shop = false
