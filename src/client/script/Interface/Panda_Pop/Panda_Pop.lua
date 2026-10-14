--2022熊猫外观
--获取途径

local g_Frame_UnifiedPosition

--=========
-- PreLoad()
--=========
function Panda_Pop_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
end

--=========
-- OnLoad()
--=========
function Panda_Pop_OnLoad()	
	g_Frame_UnifiedPosition = Panda_Pop_Frame:GetProperty("UnifiedPosition")
end

--=========
-- Event
--=========
function Panda_Pop_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 88896702) then	
		if Get_XParam_INT(0) == 1 then
			this:Show()--打开界面
			Panda_Pop_DragTitle:SetText(tostring(Get_XParam_STR(0)))
			Panda_Pop_Info:SetText(tostring(Get_XParam_STR(1)))
		else
			Panda_Pop_Close()--关闭界面
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Panda_Pop_Close()
	elseif event == "VIEW_RESOLUTION_CHANGED" then	
		Panda_Pop_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Panda_Pop_On_ResetPos()
	end	
end

--=========
-- OnHiden
--=========
function Panda_Pop_OnHiden()
end

--=========
-- Close
--=========
function Panda_Pop_Close()
	Panda_Pop_OnHiden()
	this:Hide()
end

--=========
-- 重置
--=========
function Panda_Pop_On_ResetPos()
	Panda_Pop_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end
