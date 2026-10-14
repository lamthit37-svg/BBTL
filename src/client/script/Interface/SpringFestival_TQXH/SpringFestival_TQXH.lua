
local SpringFestival_TQXH_Frame_UnifiedPosition;
local g_StartTime = 20250205
local g_EndTime = 20250223
local g_IsKaJi = 0
local g_Tip = 0
local g_Info = {
	[0] = "#{CJWH_211125_51}",
	[1] = "#{CJWH_211125_52}",
}
local g_Tips = {
	[1] = "#{CJWH_211125_1}",
	[2] = "#{CJWH_211125_2}",
	[3] = "#{CJWH_211125_3}",
}
local g_Help = {
	[0] = 146,
	[1] = 147,
}
--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function SpringFestival_TQXH_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED" , false);		-- 离开场景
end

--=========================================================
-- 载入初始化
--=========================================================
function SpringFestival_TQXH_OnLoad()
	
	SpringFestival_TQXH_Frame_UnifiedPosition = SpringFestival_TQXH_Frame_BK:GetProperty("UnifiedPosition");
end

--=========================================================
-- 事件处理
--=========================================================
function SpringFestival_TQXH_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == 88889402) then 
		g_IsKaJi = Get_XParam_INT(0)
		g_Tip = Get_XParam_INT(1)
		SpringFestival_TQXH_ShowFrame()
	elseif (event == "ADJEST_UI_POS" ) then
		SpringFestival_TQXH_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SpringFestival_TQXH_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		SpringFestival_TQXH_OnHide()
	end
end


function SpringFestival_TQXH_Clear()

end

--=========================================================
-- 界面控件数据
--=========================================================
function SpringFestival_TQXH_ShowFrame()
	SpringFestival_TQXH_Text:SetText(g_Info[g_IsKaJi])
	SpringFestival_TQXH_GoBtn:SetToolTip(g_Tips[g_Tip])
	this:Show()
end

--=========================================================
-- 关闭界面
--=========================================================
function SpringFestival_TQXH_OnHide()
	SpringFestival_TQXH_Clear()
	this:Hide()
end


function SpringFestival_TQXH_On_ResetPos()
  	SpringFestival_TQXH_Frame_BK:SetProperty("UnifiedPosition", SpringFestival_TQXH_Frame_UnifiedPosition);
end

function SpringFestival_TQXH_Goto()
	--稳活跃活动
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CJWH_211125_5}")
		return
	end	

	local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay >= g_StartTime and curDay <= g_EndTime then
		AutoRuntoTargetExWithName(250, 361, 0, "布春风")
	else
		PushDebugMessage("#{CJWH_211125_4}")
	end
end

function SpringFestival_TQXH_ShowHelp()
	PushEvent("CCSHOP_HELP", g_Help[g_IsKaJi])
end
