--2024周年庆燕子坞活动

local g_Frame_UnifiedPosition

local g_Begintime = 0
local g_Endtime = 0
local g_LimitLevel = 30

--npc坐标
local g_posX = 70
local g_posZ = 119
local g_name = "李纲"
local g_scene = 4
--=========
-- PreLoad()
--=========
function YanziWu_ActivityEnter_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
end

--=========
-- OnLoad()
--=========
function YanziWu_ActivityEnter_OnLoad()
	g_Frame_UnifiedPosition = YanziWu_ActivityEnter_Frame_BK:GetProperty("UnifiedPosition")	
	g_Begintime = 0
	g_Endtime = 0
end

--=========
-- Event
--=========
function YanziWu_ActivityEnter_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 99909001) then
		local bShow = Get_XParam_INT(0)
		--关闭界面
		if bShow == 0 then
			YanziWu_ActivityEnter_OnHide()		
		--打开界面
		elseif bShow == 1 then
			g_Begintime = Get_XParam_INT(1)
			g_Endtime = Get_XParam_INT(2)			
			if this:IsVisible() then
				YanziWu_ActivityEnter_OnHide()
			else
				YanziWu_ActivityEnter_Open()
				this:Show()
			end
		--刷新界面
		elseif bShow == 2 then
			g_Begintime = Get_XParam_INT(1)
			g_Endtime = Get_XParam_INT(2)	
			if this:IsVisible() then			
				YanziWu_ActivityEnter_Open()
			end			
		end		
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		YanziWu_ActivityEnter_OnHide()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		YanziWu_ActivityEnter_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		YanziWu_ActivityEnter_On_ResetPos()
	end
	
end

--=========
-- 重置
--=========
function YanziWu_ActivityEnter_On_ResetPos()
	YanziWu_ActivityEnter_Frame_BK:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--=========
-- 打开
--=========
function YanziWu_ActivityEnter_Open()
	YanziWu_ActivityEnter_Title:SetText("#{YZWXS_240319_20}") --标题
	YanziWu_ActivityEnter_Text:SetText("#{YZWXS_240319_21}") --文字

	
	local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay < g_Begintime  then
		YanziWu_ActivityEnter_GoBtn:SetToolTip("#{YZWXS_240319_05}")
	elseif curDay > g_Endtime then
		YanziWu_ActivityEnter_GoBtn:SetToolTip("#{YZWXS_240319_07}")
	else
		YanziWu_ActivityEnter_GoBtn:SetToolTip("#{YZWXS_240319_06}")
	end
end


--=========
-- 寻路
--=========
function YanziWu_ActivityEnter_Goto()
	local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay < g_Begintime or curDay > g_Endtime then
		PushDebugMessage("#{YZWXS_240319_08}")
		return
	end
	local nLevel = Player:GetLevel()
	if nLevel < g_LimitLevel then
		PushDebugMessage("#{YZWXS_240319_04}")
		return
	end	
	AutoRuntoTargetExWithName(g_posX, g_posZ, g_scene, g_name)
end


--=========
-- 问号帮助
--=========
function YanziWu_ActivityEnter_ShowHelp()
	PushEvent("CCSHOP_HELP", 209)
end

--=========
-- Close
--=========
function YanziWu_ActivityEnter_OnHide()
	this:Hide()
end