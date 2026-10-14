-- 
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

function ZongMenPata_Timing_PreLoad()
	 this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end
local g_Timer = -1
function ZongMenPata_Timing_OnLoad()
	g_Frame_UnifiedXPosition	= ZongMenPata_Timing_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= ZongMenPata_Timing_Frame:GetProperty("UnifiedYPosition");
end

function ZongMenPata_Timing_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 998633001 then
	    
		local nLeaveTick = Get_XParam_INT(0)
		local nSecond = math.mod(nLeaveTick, 60)
		local nMin = math.floor(nLeaveTick/60)
		if nSecond < 10 then
			nSecond = "0"..tostring(nSecond)
		end
		if nMin < 10 then
			nMin = "0"..tostring(nMin)
		end
		local szText =  ScriptGlobal_Format("#{BSQZ_210714_100}", nMin, nSecond)
		ZongMenPata_Timing_TimeText:SetText(szText)
		this:Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 998633002 then
		this:Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif( event == "ADJEST_UI_POS" ) then
		ZongMenPata_Timing_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		ZongMenPata_Timing_ResetPos()
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ZongMenPata_Timing_ResetPos()
	ZongMenPata_Timing_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ZongMenPata_Timing_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
