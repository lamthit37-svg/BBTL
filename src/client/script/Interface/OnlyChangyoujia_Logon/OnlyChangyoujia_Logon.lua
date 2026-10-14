local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

function OnlyChangyoujia_Logon_PreLoad()

	this:RegisterEvent("OPEN_RECHECK_APPWARE_UI")
	this:RegisterEvent("OPEN_RECHECK_CLOSE_ALL_UI")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("LOGIN_OVER_TIME");

end

function OnlyChangyoujia_Logon_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= OnlyChangyoujia_Logon_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= OnlyChangyoujia_Logon_Frame:GetProperty("UnifiedYPosition");
	OnlyChangyoujia_Logon_Clear()

end

function OnlyChangyoujia_Logon_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		OnlyChangyoujia_Logon_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		OnlyChangyoujia_Logon_ResetPos()
	elseif ( event == "OPEN_RECHECK_APPWARE_UI") then

		OnlyChangyoujia_Logon_Clear()
		this:Show()
	elseif (event == "OPEN_RECHECK_CLOSE_ALL_UI" ) then
		this:Hide()
	elseif( event == "LOGIN_OVER_TIME" ) then
		this:Hide()
	end
end

function OnlyChangyoujia_Logon_Clear()
	OnlyChangyoujia_Logon_ChangyoujiaBox:SetText("")
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function OnlyChangyoujia_Logon_ResetPos()
	OnlyChangyoujia_Logon_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	OnlyChangyoujia_Logon_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function OnlyChangyoujia_Logon_CheckButton_Clicked()
	local nReCheckStr = OnlyChangyoujia_Logon_ChangyoujiaBox:GetText()
	if ( nReCheckStr == nil or nReCheckStr == "" or string.len(nReCheckStr) ~= 6 )then
		ShowSystemInfoEx("DHYZ_140507_06")
		this:Hide()
		return
	end

	--调用客户端lua接口
	Lua_SendRecheckInfo(nReCheckStr, 1);
	this:Hide()
end

function OnlyChangyoujia_Logon_CloseButton_Clicked()
	ChangeToAccountInputDlgForReCheckMibao()
	this:Hide()
end


