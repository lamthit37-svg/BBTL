local g_Frame_UnifiedPosition

local g_StartTime = 20240829
local g_EndTime = 20240915
local g_Level = 30
--=========
-- PreLoad()
--=========
function ShiBaoHuanZhu_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function ShiBaoHuanZhu_OnLoad()

	
	g_Frame_UnifiedPosition = ShiBaoHuanZhu_Frame_BK:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function ShiBaoHuanZhu_OnEvent(event)

	if(event == "UI_COMMAND" and tonumber(arg0) == 892885888) then -- 
		ShiBaoHuanZhu_Text:SetText("#{JFLZ_220713_3}")
		this:Show()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 892885999) then -- 
		local TipsState = Get_XParam_INT(0)
		if TipsState == 0 then
			
		else
			
		end
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		ShiBaoHuanZhu_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		ShiBaoHuanZhu_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		ShiBaoHuanZhu_On_ResetPos()


	end

end

function ShiBaoHuanZhu_Close()
	this:Hide()
end

--=========
-- 重置
--=========
function ShiBaoHuanZhu_On_ResetPos()

	ShiBaoHuanZhu_Frame_BK:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end





--=========
-- 问号帮助
--=========
function ShiBaoHuanZhu_Help_Clicked()
	 PushEvent("CCSHOP_HELP", 214)
end




--=========
-- 
--=========
function ShiBaoHuanZhu_Click()

	local curDay = DataPool:GetServerDayTime()
	if curDay < g_StartTime or curDay > g_EndTime then
		PushDebugMessage("#{JFLZ_200803_03}")
		return
	end

	if Player:GetLevel() < g_Level then
		PushDebugMessage("#{JFLZ_200803_04}")
		return
	end
	local bRet = AutoRuntoTargetExWithName(231, 186, 1, "巴巴克")
	if 0 == bRet then
		PushDebugMessage("无法自动寻路")
		return
	end
	PushDebugMessage("#{JFLZ_220713_5}")
	
end

