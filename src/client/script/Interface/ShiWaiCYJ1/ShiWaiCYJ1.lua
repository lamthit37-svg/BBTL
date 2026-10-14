local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

function ShiWaiCYJ1_PreLoad()
	this:RegisterEvent("OPEN_LOGIN_APPWARE_UI")
	this:RegisterEvent("CLOSE_LOGIN_ALL_UI")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("LOGIN_OVER_TIME")
end

function ShiWaiCYJ1_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= ShiWaiCYJ1_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= ShiWaiCYJ1_Frame:GetProperty("UnifiedYPosition");
	Changyoujia_Login_Clear()

end

function ShiWaiCYJ1_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		Changyoujia_Login_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		Changyoujia_Login_ResetPos()
	elseif ( event == "OPEN_LOGIN_APPWARE_UI") then
		Changyoujia_Login_Clear()
		this:Show()
		ShiWaiCYJ1_Input:SetProperty("DefaultEditBox", "True");
	elseif (event == "CLOSE_LOGIN_ALL_UI" ) then
		this:Hide()
	elseif( event == "LOGIN_OVER_TIME" ) then
		this:Hide()
	end
end

function Changyoujia_Login_Clear()
	ShiWaiCYJ1_Input:SetText("")
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function Changyoujia_Login_ResetPos()
	ShiWaiCYJ1_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ShiWaiCYJ1_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Changyoujia_Login_CheckButton_Clicked()
	local nReCheckStr = ShiWaiCYJ1_Input:GetText()
	if ( nReCheckStr == nil or nReCheckStr == "" or string.len(nReCheckStr) ~= 6 )then
		GameProduceLogin:ReturnToAccountDlg()
		ShowSystemInfoEx("LYDL_150327_3")
		this:Hide()
		return
	end

	--调用客户端lua接口
	Lua_SendRecheckInfo(nReCheckStr, 3)
	this:Hide()
	--ShowSystemInfoEx("DHYZ_140507_09")
end

function Changyoujia_Login_CloseButton_Clicked()
	GameProduceLogin:ReturnToAccountDlg()
	this:Hide()
end


