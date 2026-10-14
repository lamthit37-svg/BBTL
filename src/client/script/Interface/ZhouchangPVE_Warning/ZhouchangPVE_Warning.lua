-- 
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;


local g_Timer = -1

function ZhouchangPVE_Warning_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND",true)

end

function ZhouchangPVE_Warning_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= ZhouchangPVE_Warning_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= ZhouchangPVE_Warning_Frame:GetProperty("UnifiedYPosition");
	
	g_Timer = 3
	
end



function ZhouchangPVE_Warning_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		ZhouchangPVE_Warning_ResetPos()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 331105006  ) then
		if g_Timer > 0 then
			KillTimer("ZhouchangPVE_Warning_Timer()")
		end
		g_Timer = 3
		SetTimer("ZhouchangPVE_Warning","ZhouchangPVE_Warning_Timer()", 1*1000)
		ZhouchangPVE_Warning_Fight2:SetProperty("Visible", "True")
		--ZhouchangPVE_Warning_StartPK:Hide()
		this:Show()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ZhouchangPVE_Warning_ResetPos()
	ZhouchangPVE_Warning_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ZhouchangPVE_Warning_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function ZhouchangPVE_Warning_Timer()
	g_Timer = g_Timer - 1 
	if g_Timer == 0 then
		KillTimer("ZhouchangPVE_Warning_Timer()")
		this:Hide()
	end
end
