-- 
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;


local g_Timer = -1

function Frozen_GeCao_Tips_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")

end

function Frozen_GeCao_Tips_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Frozen_GeCao_Tips_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Frozen_GeCao_Tips_Frame:GetProperty("UnifiedYPosition");
	
	g_Timer = -1
	
end



function Frozen_GeCao_Tips_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		Frozen_GeCao_Tips_ResetPos()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 331141008  ) then
		if g_Timer > 0 then
			KillTimer("Frozen_GeCao_Tips_Timer()")
		end
		g_Timer = 10
		SetTimer("Frozen_GeCao_Tips","Frozen_GeCao_Tips_Timer()", 1*1000)
		Frozen_GeCao_Tips_Bk:Show()
		local str = Get_XParam_STR(0)
		Frozen_GeCao_Tips_Text:SetText(str)
		Frozen_GeCao_Tips_Text:Show()
		--Frozen_GeCao_Tips_StartPK:Hide()
		this:Show()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_GeCao_Tips_ResetPos()
	Frozen_GeCao_Tips_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Frozen_GeCao_Tips_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Frozen_GeCao_Tips_Timer()
	g_Timer = g_Timer - 1 
	if g_Timer == 0 then
		KillTimer("Frozen_GeCao_Tips_Timer()")
		this:Hide()
	end
end
