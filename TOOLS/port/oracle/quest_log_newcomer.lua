-- Bảng nhiệm vụ của nhân vật mới: cấp 1, chưa nhập môn, sổ rỗng, đúng một nhiệm vụ nhận được (loại
-- 17, dòng 1087 của MissionOutline). Tên đã dịch như bản port tra bảng chữ.
-- Script hỏi tên của mọi loại 1..200 trước khi xét loại đó có nhiệm vụ không, nên cả 199 dòng của
-- bảng loại phải có mặt (loại 200 mã gốc trả số 0).
for kind = 1, 199 do __kinds[kind] = "Loại " .. kind end
__kinds[17] = "Vô Lượng Sơn"
__offers[17] = {
    { level = 1, min = 1, max = 31, npc = "Sơn Dân Bị Thương", scene = "Vô Lượng Sơn",
      name = "Duyên Khởi Vô Lượng", x = 187, z = 205, scene_id = 6 },
}
--@steps
__event("TOGLE_MISSION")
__dump("mở bảng")
__check("QuestLog_AcceptMission", "MouseLButtonDown")
__dump("sang thẻ nhận được")
__pick("QuestLog_Listbox", 170001)
__dump("chọn nhiệm vụ")
__pick("QuestLog_Listbox", 170000)
__dump("gập loại")
__pick("QuestLog_Listbox", 170000)
__dump("mở lại loại")
__fire("QuestLog_Refuse")
__dump("nút đóng của thẻ nhận được")
__event("TOGLE_MISSION")
__dump("mở lại bảng")
__toggle("QuestLog_Mode1")
__toggle("QuestLog_Mode2")
__dump("đảo hai ô theo dõi")
__fire("QuestLog_Stop")
__fire("QuestLog_Refuse")
__fire("QuestLog_Close")
__dump("từ bỏ, theo dõi, đóng khi sổ rỗng")
