-- Thanh kỹ năng thú cưng (MainMenuBar_3): thanh rỗng, một action, hai action, action rỗng xen kẽ, nhiều hơn
-- hai ô, bấm nút khi làm được và khi bị chặn, ẩn hiện bằng HIDE_THIS_UI. Chạy: python -B TOOLS/port/lua_oracle.py
-- <Bin64> <MainMenuBar_3.lua> <layout> main_menu_bar_3_pet.lua <tệp ra> --lib ui_common_api.lua --lib main_menu_bar_3_api.lua
--@steps
__event("CHANGE_PETSKILL_BAR")
__dump("thanh rỗng")
__pet_bar = { 301 }
__event("CHANGE_PETSKILL_BAR")
__dump("một action")
__pet_bar = { 301, 305 }
__event("CHANGE_PETSKILL_BAR")
__dump("hai action")
__pet_bar = { 0, 305, 309 }
__event("CHANGE_PETSKILL_BAR")
__dump("action rỗng đứng đầu, ba mục")
__pet_bar = { 0, 0 }
__event("CHANGE_PETSKILL_BAR")
__dump("mọi action rỗng")
__pet_bar = { 311, 312, 313 }
__event("CHANGE_PETSKILL_BAR")
__dump("ba action, chỉ nhận hai")
__event("CHAT_ADJUST_MOVE_CTL", "1280", "720")
__dump("điều chỉnh vị trí theo khung chat")
__fire("MainMenuBar_3_Button_Action1")
__fire("MainMenuBar_3_Button_Action2", "RBClicked")
__dump("bấm hai nút")
__blocking.Bank = true
__fire("MainMenuBar_3_Button_Action1")
__dump("bấm nút khi bảng ngân hàng hiện")
__blocking.Bank = false
__event("HIDE_THIS_UI")
__dump("ẩn bằng HIDE_THIS_UI")
__event("HIDE_THIS_UI")
__dump("hiện lại bằng HIDE_THIS_UI")
