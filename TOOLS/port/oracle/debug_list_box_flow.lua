-- Danh sách lời nhắn gỡ lỗi (DebugListBox): khởi động xoá danh sách và hiện bảng, mỗi NEW_DEBUGMESSAGE thêm một
-- dòng "#c<màu>#e<viền><chữ>" (màu mặc định 00FFFF và 010101 vì GetUIColor(1000) trả "-1"), danh sách giữ tối đa 5
-- dòng, chữ dài hơn 400 byte bị cắt ở 400 byte (399 khi 400 byte đầu kết thúc giữa một ký tự).
-- Chạy: python -B TOOLS/port/lua_oracle.py <Bin64> <DebugListBox.lua> <layout> debug_list_box_flow.lua <tệp ra>
--       --lib debug_list_box_api.lua
--@steps
__dump_events("sự kiện đăng ký")
__event("APPLICATION_INITED")
__dump("khởi động")
__event("NEW_DEBUGMESSAGE", "Bạn chưa có bang hội")
__dump("một lời nhắn")
__event("NEW_DEBUGMESSAGE", "Dòng hai")
__event("NEW_DEBUGMESSAGE", "Dòng ba")
__event("NEW_DEBUGMESSAGE", "Dòng bốn")
__event("NEW_DEBUGMESSAGE", "Dòng năm")
__dump("đủ năm dòng")
__event("NEW_DEBUGMESSAGE", "Dòng sáu")
__event("NEW_DEBUGMESSAGE", "Dòng bảy")
__dump("quá năm dòng bỏ dòng cũ nhất")
__event("NEW_DEBUGMESSAGE", string.rep("a", 400))
__dump("đúng 400 byte giữ nguyên")
__event("NEW_DEBUGMESSAGE", string.rep("b", 401))
__dump("401 byte cắt còn 400")
__event("NEW_DEBUGMESSAGE", string.rep("c", 399) .. "ă")
__dump("ký tự hai byte bị cắt giữa chừng thì còn 399")
__event("NEW_DEBUGMESSAGE", string.rep("d", 399) .. "ế")
__dump("ký tự ba byte bị cắt giữa chừng thì còn 399")
__event("NEW_DEBUGMESSAGE", string.rep("đ", 200) .. "e")
__dump("ký tự hai byte nằm trọn trong 400 byte")
__event("APPLICATION_INITED")
__dump("khởi động lại xoá danh sách")
