-- 
local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;


local g_Timer = -1

function ZhouchangPVE_Tips_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND",true)

end

function ZhouchangPVE_Tips_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= ZhouchangPVE_Tips:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= ZhouchangPVE_Tips:GetProperty("UnifiedYPosition");
	
	g_Timer = 3
	
end



function ZhouchangPVE_Tips_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		ZhouchangPVE_Tips_ResetPos()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 331105001  ) then
		if g_Timer > 0 then
			KillTimer("ZhouchangPVE_Tips_Timer()")
		end
		g_Timer = 10
		SetTimer("ZhouchangPVE_Tips","ZhouchangPVE_Tips_Timer()", 1*1000)
		ZhouchangPVE_Tips_ImageBK:Show()
		local str = Get_XParam_STR(0)
		ZhouchangPVE_Tips_Text:SetText(str)
		ZhouchangPVE_Tips_Text:Show()
		ZhouchangPVE_Tips_End:Hide()
		--ZhouchangPVE_Tips_StartPK:Hide()
		this:Show()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 331105002  ) then
		if g_Timer > 0 then
			KillTimer("ZhouchangPVE_Tips_Timer()")
		end
		g_Timer = 10
		SetTimer("ZhouchangPVE_Tips","ZhouchangPVE_Tips_Timer()", 1*1000)
		ZhouchangPVE_Tips_ImageBK:Show()
		local str = Get_XParam_STR(0)
		ZhouchangPVE_Tips_Text:SetText(str)
		ZhouchangPVE_Tips_Text:Show()
		ZhouchangPVE_Tips_End:Hide()
		--ZhouchangPVE_Tips_StartPK:Hide()
		this:Show()
	elseif( event == "UI_COMMAND" and tonumber(arg0) == 331105004  ) then
		if g_Timer > 0 then
			KillTimer("ZhouchangPVE_Tips_Timer()")
		end
		g_Timer = 3
		SetTimer("ZhouchangPVE_Tips","ZhouchangPVE_Tips_Timer()", 1*1000)
		ZhouchangPVE_Tips_ImageBK:Hide()
		
		ZhouchangPVE_Tips_Text:Hide()
		ZhouchangPVE_Tips_End:Show()
		--ZhouchangPVE_Tips_StartPK:Hide()
		this:Show()

	elseif( event == "UI_COMMAND" and tonumber(arg0) == 331126001  ) then
		if g_Timer > 0 then
			KillTimer("ZhouchangPVE_Tips_Timer()")
		end
		g_Timer = 10
		SetTimer("ZhouchangPVE_Tips","ZhouchangPVE_Tips_Timer()", 1*1000)
		ZhouchangPVE_Tips_ImageBK:Show()
		local str = Get_XParam_STR(0)
		ZhouchangPVE_Tips_Text:SetText(str)
		ZhouchangPVE_Tips_Text:Show()
		ZhouchangPVE_Tips_End:Hide()
		--ZhouchangPVE_Tips_StartPK:Hide()
		this:Show()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ZhouchangPVE_Tips_ResetPos()
	ZhouchangPVE_Tips:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ZhouchangPVE_Tips:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function ZhouchangPVE_Tips_Timer()
	g_Timer = g_Timer - 1 
	if g_Timer == 0 then
		KillTimer("ZhouchangPVE_Tips_Timer()")
		this:Hide()
	end
end
