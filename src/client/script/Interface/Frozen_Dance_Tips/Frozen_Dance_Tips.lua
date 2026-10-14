-- 
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;


local g_Timer = -1

function Frozen_Dance_Tips_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")

end

function Frozen_Dance_Tips_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Frozen_Dance_Tips_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Frozen_Dance_Tips_Frame:GetProperty("UnifiedYPosition");
	
	g_Timer = -1
	
end



function Frozen_Dance_Tips_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		Frozen_Dance_Tips_ResetPos()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 331180008  ) then
		local nType = Get_XParam_INT(0)
		if nType == 2 then
			if g_Timer > 0 then
				KillTimer("Frozen_Dance_Tips_Timer()")
			end
			g_Timer = 10
			SetTimer("Frozen_Dance_Tips","Frozen_Dance_Tips_Timer()", 1*1000)
			Frozen_Dance_Tips_Bk:Show()
			local str = Get_XParam_STR(0)
			Frozen_Dance_Tips_Text:SetText(str)
			Frozen_Dance_Tips_Text:Show()
			--Frozen_Dance_Tips_StartPK:Hide()
			this:Show()
		elseif nType == 1 then
		
			Frozen_Dance_Tips_Bk:Show()
			local str = Get_XParam_STR(0)
			Frozen_Dance_Tips_Text:SetText(str)
			Frozen_Dance_Tips_Text:Show()
			--Frozen_Dance_Tips_StartPK:Hide()
			this:Show()
		end

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_Dance_Tips_ResetPos()
	Frozen_Dance_Tips_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Frozen_Dance_Tips_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Frozen_Dance_Tips_Timer()
	g_Timer = g_Timer - 1 
	if g_Timer == 0 then
		KillTimer("Frozen_Dance_Tips_Timer()")
		this:Hide()
	end
end
