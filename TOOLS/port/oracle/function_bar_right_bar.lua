-- Thanh action FunctionBarRight (ô 41..49, chín ô): khác FunctionBarRight_2 ở chỗ trước mọi sự kiện script hỏi người chơi
-- có phải GM đang ẩn hay đang xem trận (giấu thanh rồi thôi), Target:UpdateActionButton gọi ở mọi CHANGE_BAR main, ACTION_UPDATE
-- đăng ký cờ false (thanh ẩn thì không nhận), có PLAYER_ENTERING_WORLD và SHOW_TRANSFIGURATION_SKILL, gỡ gói đẩy cấp 4
-- (UNINSTALL_CHAT_ACTION_BAR3), dọn gói chuyển tiếp cho FunctionBarRight_2.
-- Chạy: bash TOOLS/port/ui_oracle.sh FunctionBarRight function_bar_right bar --lib TOOLS/port/oracle/ui_common_api.lua
--   --lib TOOLS/port/oracle/action_bar_api.lua
-- Gói cài như function_bar_right_2_bar.lua: ô 2 gói đơn (id 7, ba hành động từ chỉ số 4 của danh sách chatmood), ô 4 gói đôi
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
--@steps
__event("FLASH_COMBOSKILL", "41", "1")
__dump("nháy cấp thấp khi thanh còn ẩn")
__event("CHANGE_BAR", "main", "41", "301")
__dump("đặt ô 41 khi thanh ẩn: cờ nháy không bị gỡ")
__event("PLAYER_ENTERING_WORLD")
__dump("vào thế giới: hiện thanh")
__event("CHANGE_BAR", "main", "41", "301")
__dump("đặt lại ô 41 khi thanh hiện: nháy bị gỡ")
__event("FLASH_COMBOSKILL", "42", "2")
__dump("nháy cấp cao ô 42")
__event("FLASH_COMBOSKILL", "42", "2")
__dump("nháy cấp cao lần hai không đổi gì")
__event("FLASH_COMBOSKILL", "42", "1")
__dump("đổi sang nháy cấp thấp")
__event("FLASH_COMBOSKILL", "42", "0")
__dump("tắt nháy")
__event("FLASH_COMBOSKILL", "50", "1")
__dump("nháy ngoài dải 41..49")
__event("CHANGE_BAR", "main", "43", "305", "0")
__dump("ô 43 với thú cưng 0 không có")
__event("CHANGE_BAR", "main", "42", "302")
__dump("ô 42 không nêu arg3: dùng arg3 cũ là thú cưng 0")
__pets.present[1] = true
__pets.fighting[1] = true
__event("CHANGE_BAR", "main", "44", "306", "1")
__dump("ô 44 với thú cưng 1 đang chiến đấu")
__pets.fighting[1] = false
__event("CHANGE_BAR", "main", "45", "307", "1")
__dump("ô 45 với thú cưng 1 có mặt nhưng không chiến đấu")
__event("CHANGE_BAR", "main", "46", "308", "9")
__dump("ô 46 với số thú cưng ngoài dải 0..5")
__event("CHANGE_BAR", "main", "49", "309", "9")
__dump("ô cuối 49")
__event("CHANGE_BAR", "main", "40", "1")
__dump("CHANGE_BAR ngoài dải vẫn gọi UpdateActionButton")
__event("CHANGE_BAR", "main", "50", "1")
__dump("CHANGE_BAR vượt dải vẫn gọi UpdateActionButton")
__event("CHANGE_BAR", "other", "41", "1")
__dump("CHANGE_BAR có arg0 lạ bị bỏ qua")
pcall(__event, "CHANGE_BAR", "main", "41.5", "2")
__dump("chỉ số không nguyên trong dải: gọi UpdateActionButton rồi dừng")
pcall(__event, "CHANGE_BAR", "main", "chu", "2")
__dump("chỉ số không phải số: gọi UpdateActionButton rồi dừng")
__event("FLASH_COMBOSKILL", "41", "1")
__event("FLASH_COMBOSKILL", "45", "2")
__event("ACTION_UPDATE")
__dump("nhắc nháy mới cho mọi ô")
__event("CHANGE_BAR", "mainreset", "3", "41", "45", "99")
__dump("dọn ba ô 41, 45, 99")
__event("CHANGE_BAR", "mainreset", "1", "49")
__dump("dọn một ô 49")
pcall(__event, "CHANGE_BAR", "mainreset", "6", "42")
__dump("dọn nhiều ô hơn số đối số: eventTable còn giá trị cũ rồi gặp nil và dừng")
__event("UNINSTALL_CHAT_ACTION_BAR3", "11")
__dump("gỡ gói ngoài dải 0..10")
pcall(__event, "UNINSTALL_CHAT_ACTION_BAR3", "chu")
__dump("gỡ gói với chỉ số không phải số")
__event("CHANGE_BAR", "main", "42", "905")
__event("CHANGE_BAR", "main", "43", "903")
__event("CHANGE_BAR", "main", "44", "906")
__event("CHANGE_BAR", "main", "45", "0")
__event("CHANGE_BAR", "main", "46", "1102")
__event("CHANGE_BAR", "main", "47", "1101")
__event("UNINSTALL_CHAT_ACTION_BAR3", "2")
__dump("gỡ gói đơn ô 2: ô trùng hành động bị gỡ")
__event("UNINSTALL_CHAT_ACTION_BAR3", "4")
__dump("gỡ gói đôi ô 4: hai ô trùng hành động đôi bị gỡ")
__event("UNINSTALL_CHAT_ACTION_BAR3", "6")
__dump("gỡ gói không có real id")
__event("UNINSTALL_CHAT_ACTION_BAR3", "8")
__dump("gỡ gói không có hành động nào")
__event("UNINSTALL_CHAT_ACTION_BAR3", "3")
__dump("gỡ gói ô chưa cài")
__event("CHANGE_BAR", "main", "48", "904")
__event("CLEAR_CHAT_ACTION_BAR", "MainMenuBar_4", "2", "5", "6")
__dump("dọn gói của thanh khác thì bỏ qua")
__event("CLEAR_CHAT_ACTION_BAR", "FunctionBarRight_2", "2", "5", "6")
__dump("tên FunctionBarRight_2 không phải FunctionBarRight: bỏ qua")
__event("CLEAR_CHAT_ACTION_BAR", "FunctionBarRight", "2", "5", "6")
__dump("dọn gói quá hạn của FunctionBarRight rồi chuyển cho FunctionBarRight_2")
__event("CLEAR_CHAT_ACTION_BAR", "FunctionBarRight", "-1", "5", "6")
__dump("dọn gói ô âm")
__event("CLEAR_CHAT_ACTION_BAR", "FunctionBarRight", "7", "5", "6")
__dump("dọn gói ô chưa cài vẫn chuyển tiếp")
pcall(__event, "CLEAR_CHAT_ACTION_BAR", "FunctionBarRight", "7", "chu", "6")
__dump("dọn gói với dữ liệu không phải số: game từ chối")
__event("SHOW_TRANSFIGURATION_SKILL", "2")
__dump("biến hình kỹ năng arg0 là 2: giấu thanh")
__event("SHOW_TRANSFIGURATION_SKILL", "1")
__dump("arg0 là 1: không đổi")
__event("SHOW_TRANSFIGURATION_SKILL", "0")
__dump("arg0 là 0: hiện thanh")
__event("SHOW_TRANSFIGURATION_SKILL", "2")
__event("SHOW_TRANSFIGURATION_SKILL", "chu")
__dump("arg0 lạ khi thanh đang ẩn: vẫn ẩn")
__event("PLAYER_ENTERING_WORLD")
__dump("vào thế giới lần nữa: hiện lại")
__event("HIDE_THIS_UI")
__dump("HIDE_THIS_UI giấu thanh đang hiện")
__event("HIDE_THIS_UI")
__dump("HIDE_THIS_UI hiện lại")
__gm_visible = 1
__event("CHANGE_BAR", "main", "41", "301")
__dump("GM đang ẩn: giấu thanh, không xử lý CHANGE_BAR (không gọi UpdateActionButton)")
__event("PLAYER_ENTERING_WORLD")
__dump("GM đang ẩn: vào thế giới cũng không hiện")
__gm_visible = 0
__viewer = 1
__event("PLAYER_ENTERING_WORLD")
__dump("đang xem trận: vào thế giới cũng không hiện")
__viewer = 0
__event("PLAYER_ENTERING_WORLD")
__dump("hết xem trận: hiện")
__viewer = -1
__event("HIDE_THIS_UI")
__dump("số xem trận âm không tính là đang xem: HIDE_THIS_UI giấu thanh")
__viewer = 0
__event("PLAYER_ENTERING_WORLD")
__fire("FunctionBarRight_Button_Action3")
__fire("FunctionBarRight_Button_Action4", "RBClicked")
__fire("FunctionBarRight_Button_Action9")
__dump("bấm ô 43, 44 và ô trống 49")
__blocking.Shop = true
__fire("FunctionBarRight_Button_Action3")
__dump("bấm ô khi cửa hàng hiện")
__blocking.Shop = false
