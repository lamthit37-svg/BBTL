-- Thanh action MainMenuBar_4 (ô 71..80): thanh ẩn lúc nạp nên IsVisible của ô con là false cho tới khi thanh hiện,
-- nháy combo cấp thấp và cao, đặt và dọn ô bằng CHANGE_BAR (main và mainreset, đối số arg3 cũ còn lại từ lần
-- trước), nhắc nháy mới, gỡ gói hành động chat (GE_UNINSTALL_CHAT_ACTION_BAR5) và dọn gói quá hạn
-- (CLEAR_CHAT_ACTION_BAR), mở đóng thanh bằng OPEN_UP_BAR_2 và HIDE_THIS_UI, bấm ô khi làm được và khi bị chặn.
-- Chạy: bash TOOLS/port/ui_oracle.sh MainMenuBar_4 main_menu_bar_4 bar --lib TOOLS/port/oracle/ui_common_api.lua
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
__event("FLASH_COMBOSKILL", "71", "1")
__dump("nháy cấp thấp khi thanh còn ẩn")
__event("CHANGE_BAR", "main", "71", "301")
__dump("đặt ô 71 khi thanh ẩn: cờ nháy không bị gỡ")
__event("OPEN_UP_BAR_2", "1", "UpBar2")
__dump("mở thanh")
__event("CHANGE_BAR", "main", "71", "301")
__dump("đặt lại ô 71 khi thanh hiện: nháy bị gỡ")
__event("FLASH_COMBOSKILL", "72", "2")
__dump("nháy cấp cao ô 72")
__event("FLASH_COMBOSKILL", "72", "2")
__dump("nháy cấp cao lần hai không đổi gì")
__event("FLASH_COMBOSKILL", "72", "1")
__dump("đổi sang nháy cấp thấp")
__event("FLASH_COMBOSKILL", "72", "0")
__dump("tắt nháy")
__event("FLASH_COMBOSKILL", "81", "1")
__dump("nháy ngoài dải 71..80")
__event("CHANGE_BAR", "main", "73", "305", "0")
__dump("ô 73 với thú cưng 0 không có")
__event("CHANGE_BAR", "main", "72", "302")
__dump("ô 72 không nêu arg3: dùng arg3 cũ là thú cưng 0")
__pets.present[1] = true
__pets.fighting[1] = true
__event("CHANGE_BAR", "main", "74", "306", "1")
__dump("ô 74 với thú cưng 1 đang chiến đấu")
__pets.fighting[1] = false
__event("CHANGE_BAR", "main", "75", "307", "1")
__dump("ô 75 với thú cưng 1 có mặt nhưng không chiến đấu")
__event("CHANGE_BAR", "main", "76", "308", "9")
__dump("ô 76 với số thú cưng ngoài dải 0..5")
__event("CHANGE_BAR", "main", "77", "309", "9")
__dump("ô 77 với số thú cưng ngoài dải")
__event("CHANGE_BAR", "main", "60", "1")
__dump("CHANGE_BAR ngoài dải vẫn gọi UpdateActionButton")
__event("CHANGE_BAR", "other", "71", "1")
__dump("CHANGE_BAR có arg0 lạ bị bỏ qua")
pcall(__event, "CHANGE_BAR", "main", "71.5", "2")
__dump("chỉ số không nguyên: gọi UpdateActionButton rồi dừng")
pcall(__event, "CHANGE_BAR", "main", "chu", "2")
__dump("chỉ số không phải số: gọi UpdateActionButton rồi dừng")
__event("FLASH_COMBOSKILL", "71", "1")
__event("FLASH_COMBOSKILL", "75", "2")
__event("ACTION_UPDATE")
__dump("nhắc nháy mới cho mọi ô")
__event("CHANGE_BAR", "mainreset", "3", "71", "75", "99")
__dump("dọn ba ô 71, 75, 99")
__event("CHANGE_BAR", "mainreset", "1", "80")
__dump("dọn một ô 80")
pcall(__event, "CHANGE_BAR", "mainreset", "6", "72")
__dump("dọn nhiều ô hơn số đối số: eventTable còn giá trị cũ rồi gặp nil và dừng")
__event("GE_UNINSTALL_CHAT_ACTION_BAR5", "11")
__dump("gỡ gói ngoài dải 0..10")
pcall(__event, "GE_UNINSTALL_CHAT_ACTION_BAR5", "chu")
__dump("gỡ gói với chỉ số không phải số")
__event("CHANGE_BAR", "main", "72", "905")
__event("CHANGE_BAR", "main", "73", "903")
__event("CHANGE_BAR", "main", "74", "906")
__event("CHANGE_BAR", "main", "75", "0")
__event("CHANGE_BAR", "main", "76", "1102")
__event("CHANGE_BAR", "main", "77", "1101")
__event("GE_UNINSTALL_CHAT_ACTION_BAR5", "2")
__dump("gỡ gói đơn ô 2: hai ô trùng hành động bị gỡ")
__event("GE_UNINSTALL_CHAT_ACTION_BAR5", "4")
__dump("gỡ gói đôi ô 4: hai ô trùng hành động đôi bị gỡ")
__event("GE_UNINSTALL_CHAT_ACTION_BAR5", "6")
__dump("gỡ gói không có real id")
__event("GE_UNINSTALL_CHAT_ACTION_BAR5", "8")
__dump("gỡ gói không có hành động nào")
__event("GE_UNINSTALL_CHAT_ACTION_BAR5", "3")
__dump("gỡ gói ô chưa cài")
__event("CHANGE_BAR", "main", "78", "904")
__event("CLEAR_CHAT_ACTION_BAR", "FunctionBarRight", "2", "5", "6")
__dump("dọn gói của thanh khác thì bỏ qua")
__event("CLEAR_CHAT_ACTION_BAR", "MainMenuBar_4", "2", "5", "6")
__dump("dọn gói quá hạn của MainMenuBar_4")
__event("CLEAR_CHAT_ACTION_BAR", "MainMenuBar_4", "-1", "5", "6")
__dump("dọn gói ô âm")
__event("CLEAR_CHAT_ACTION_BAR", "MainMenuBar_4", "7", "5", "6")
__dump("dọn gói ô chưa cài vẫn ghi dữ liệu mới")
pcall(__event, "CLEAR_CHAT_ACTION_BAR", "MainMenuBar_4", "7", "chu", "6")
__dump("dọn gói với dữ liệu không phải số: game từ chối")
__event("OPEN_UP_BAR_2", "0", "UpBar2")
__dump("đóng thanh")
__in_tlcj = 1
__event("OPEN_UP_BAR_2", "1", "UpBar2")
__dump("mở thanh trong cảnh TLCJ thì đóng")
__in_tlcj = 0
__event("OPEN_UP_BAR_2", "1", "Other")
__dump("mở thanh với arg1 lạ thì đóng")
__event("HIDE_THIS_UI")
__dump("HIDE_THIS_UI hiện thanh")
__fire("MainMenuBar_4_Button_Action3")
__fire("MainMenuBar_4_Button_Action4", "RBClicked")
__fire("MainMenuBar_4_Button_Action10")
__dump("bấm ô 73, 74 và ô trống 80")
__blocking.Shop = true
__fire("MainMenuBar_4_Button_Action3")
__dump("bấm ô khi cửa hàng hiện")
__blocking.Shop = false
__event("HIDE_THIS_UI")
__dump("HIDE_THIS_UI giấu thanh")
