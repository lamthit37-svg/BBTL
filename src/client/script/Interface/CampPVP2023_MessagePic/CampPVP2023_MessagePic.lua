-- 
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;


local g_Timer = -1

function CampPVP2023_MessagePic_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND",true)

end

function CampPVP2023_MessagePic_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= CampPVP2023_MessagePic_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= CampPVP2023_MessagePic_Frame:GetProperty("UnifiedYPosition");
	
	g_Timer = 3
	
end



function CampPVP2023_MessagePic_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		CampPVP2023_MessagePic_ResetPos()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 998429002  ) then
		if g_Timer > 0 then
			KillTimer("CampPVP2023_MessagePic_Timer()")
		end
		g_Timer = 3
		SetTimer("CampPVP2023_MessagePic","CampPVP2023_MessagePic_Timer()", 1*1000)
		CampPVP2023_MessagePic_Start:Show()
		CampPVP2023_MessagePic_End:Hide()
		--CampPVP2023_MessagePic_StartPK:Hide()
		this:Show()

	elseif( event == "UI_COMMAND" and tonumber(arg0) == 998429006  ) then
		if g_Timer > 0 then
			KillTimer("CampPVP2023_MessagePic_Timer()")
		end
		g_Timer = 3
	
		SetTimer("CampPVP2023_MessagePic","CampPVP2023_MessagePic_Timer()", 1*1000)
		CampPVP2023_MessagePic_Start:Hide()
		CampPVP2023_MessagePic_End:Show()
		--CampPVP2023_MessagePic_StartPK:Hide()
		this:Show()
	-- elseif( event == "UI_COMMAND" and tonumber(arg0) == 88894414  ) then
		-- if g_Timer > 0 then
			-- KillTimer("CampPVP2023_MessagePic_Timer()")
		-- end
		-- g_Timer = 3
	
		-- SetTimer("CampPVP2023_MessagePic","CampPVP2023_MessagePic_Timer()", 1*1000)
		-- CampPVP2023_MessagePic_Start:Hide()
		-- CampPVP2023_MessagePic_End:Hide()
		-- CampPVP2023_MessagePic_StartPK:Show()
		-- this:Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function CampPVP2023_MessagePic_ResetPos()
	CampPVP2023_MessagePic_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	CampPVP2023_MessagePic_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function CampPVP2023_MessagePic_Timer()
	g_Timer = g_Timer - 1 
	if g_Timer == 0 then
		KillTimer("CampPVP2023_MessagePic_Timer()")
		this:Hide()
	end
end
