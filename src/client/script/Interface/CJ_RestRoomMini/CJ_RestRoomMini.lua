-- 吃鸡玩法 休息室人数、倒计时等展示UI最小化状态
-- 默认位置
local CJ_RestRoomMini_UnifiedPosition = nil



function CJ_RestRoomMini_PreLoad()
    this:RegisterEvent("TLCJ_REST_RESTINFOMINIOPEN", true)
    this:RegisterEvent("TLCJ_REST_RESTINFOMINICLOSE", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func CJ_RestRoomMini_PreLoad()

function CJ_RestRoomMini_OnEvent(event)
    if (event == "TLCJ_REST_RESTINFOMINIOPEN") then
        CJ_RestRoomMini_Show()
    elseif (event == "TLCJ_REST_RESTINFOMINICLOSE") then
        CJ_RestRoomMini_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		CJ_RestRoomMini_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		CJ_RestRoomMini_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		CJ_RestRoomMini_UnifiedPos()
	end
end -- end func CJ_RestRoomMini_OnEvent()

function CJ_RestRoomMini_OnLoad()
	CJ_RestRoomMini_UnifiedPosition = CJ_RestRoomMini_Frame:GetProperty("UnifiedPosition")
end -- end func CJ_RestRoomMini_OnLoad()

-- 界面默认位置
function CJ_RestRoomMini_UnifiedPos()
	if (CJ_RestRoomMini_UnifiedPosition ~= nil) then
		CJ_RestRoomMini_Frame:SetProperty("UnifiedPosition", CJ_RestRoomMini_UnifiedPosition)
	end
end -- end func CJ_RestRoomMini_UnifiedPos()

function CJ_RestRoomMini_Show()
    this:Show()
end -- end func CJ_RestRoomMini_Show()

function CJ_RestRoomMini_Hide()
    this:Hide()
end -- end func CJ_RestRoomMini_Hide()

-- 打开休息室UI按钮点击事件
function CJ_RestRoomMini_Open()
    PushEvent("TLCJ_REST_RESTINFOOPEN")
    
    CJ_RestRoomMini_Hide()
end -- end func CJ_RestRoomMini_Open()