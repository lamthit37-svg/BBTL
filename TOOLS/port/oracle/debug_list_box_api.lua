-- Hàm của game mà DebugListBox.lua (danh sách lời nhắn gỡ lỗi) gọi, viết lại bằng Lua theo mã máy Game.exe và
-- UI_CEGUI.dll của client D:\XTLBB 3.71.9509 (địa chỉ ở docs/giao-viec/UI-PORT và ui/panel/data_pool.hpp):
--  - DataPool:GetUIColor(id) (Game.exe 0x1402e7710) tra SystemColour (DBC id 0xa7) theo id, trả cột màu chữ và
--    cột màu viền; id không có trong bảng thì trả "-1" và "-1". Bảng của 3.71.9509 có 47 dòng (id 1 tới 16,
--    21 tới 26, 100 tới 114, 2000 tới 2009), không có 1000, nên DebugListBox luôn nhận hai chuỗi "-1".
--  - DataPool:Check_StringCode(chuỗi) (UI_CEGUI.dll 0x180055430 qua CUISystem ô ảo 73) trả 0 khi chuỗi có
--    byte đầu hay byte đuôi của ký tự hai byte GBK sai hoặc kết thúc giữa ký tự, ngược lại 1. Dự án giữ chữ
--    bằng UTF-8, nên bản này kiểm theo UTF-8 với cùng hợp đồng: 0 khi chuỗi kết thúc giữa một ký tự hay có
--    byte không hợp lệ, hay có ký tự điều khiển ngoài tab, xuống dòng, về đầu dòng.

DataPool = {}

function DataPool:GetUIColor(id)
    return "-1", "-1"
end

-- Số byte tiếp nối mà byte đầu này đòi, nil khi không thể là byte đầu của ký tự hợp lệ.
local function follow_of(lead)
    if lead < 128 then return 0 end
    if lead >= 194 and lead <= 223 then return 1 end
    if lead >= 224 and lead <= 239 then return 2 end
    if lead >= 240 and lead <= 244 then return 3 end
    return nil
end

function DataPool:Check_StringCode(text)
    local at, size = 1, string.len(text)
    while at <= size do
        local lead = string.byte(text, at)
        if lead < 32 and lead ~= 9 and lead ~= 10 and lead ~= 13 then return 0 end
        local follow = follow_of(lead)
        if follow == nil then return 0 end
        for step = 1, follow do
            local byte = string.byte(text, at + step)
            if byte == nil or byte < 128 or byte > 191 then return 0 end
        end
        at = at + 1 + follow
    end
    return 1
end
