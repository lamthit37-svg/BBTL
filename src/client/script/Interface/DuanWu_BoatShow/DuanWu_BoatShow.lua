--端午抽奖
local g_Position
--*********************************
-- PreLoad
--*********************************
function DuanWu_BoatShow_PreLoad()
	this : RegisterEvent( "UI_COMMAND" );					-- UI_COMMAND
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED", false);		-- 游戏分辨率发生了变化
	this : RegisterEvent( "HIDE_ON_SCENE_TRANSED" , false);		-- 离开场景
	this : RegisterEvent( "ADJEST_UI_POS" , false);
end


--*********************************
-- OnLoad
--*********************************
function DuanWu_BoatShow_OnLoad()
	g_Position = DuanWu_BoatShow_Frame_BK:GetProperty("UnifiedPosition")
end


--*********************************
-- OnEvent
--*********************************
function DuanWu_BoatShow_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 50508709) then
		local opt = tonumber(arg1);
		if opt == 1 then
			if (this:IsVisible()) then
				this:Hide()
			end
			this:Show()
		end
		if opt == 2 then
			if (not this:IsVisible()) then
				return
			end
			this:Hide()
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 恢复默认位置
		DuanWu_BoatShow_Frame_BK:SetProperty("UnifiedPosition", g_Position)
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif (event == "ADJEST_UI_POS") then
		DuanWu_BoatShow_Frame_BK:SetProperty("UnifiedPosition", g_Position)
	end 
end

function DuanWu_BoatShow_ClickClose()
	this:Hide()
end
