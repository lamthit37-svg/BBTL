-- Hàm của game mà MainMenuBar_4.lua gọi ngoài bộ dùng chung ui_common_api.lua và action_bar_api.lua:
-- TLCJ:IsInTLCJScene (1 khi đang ở cảnh TLCJ, kịch bản đặt vào __in_tlcj).
__in_tlcj = 0

TLCJ = rawget(_G, "TLCJ") or {}
function TLCJ:IsInTLCJScene() return __in_tlcj end
