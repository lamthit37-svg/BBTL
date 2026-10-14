local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;


function CampPVP2023_Throw_PreLoad()

	--this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function CampPVP2023_Throw_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= CampPVP2023_Throw_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= CampPVP2023_Throw_Frame:GetProperty("UnifiedYPosition");
end

function CampPVP2023_Throw_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		CampPVP2023_Throw_ResetPos()

	--elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
	--	this:Hide();
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998429007) then	--
		this:Show();
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998429008) then	--
		this:Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
	
end

function CampPVP2023_Throw_ResetPos()

	CampPVP2023_Throw_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	CampPVP2023_Throw_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);

end

function CampPVP2023_Throw_AbandonClick()

	 Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PlayerAbandonFlag")
		Set_XSCRIPT_ScriptID(998429)
		Set_XSCRIPT_Parameter(0, 0)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end
