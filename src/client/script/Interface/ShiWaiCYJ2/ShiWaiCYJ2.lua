local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

function ShiWaiCYJ2_PreLoad()
	this:RegisterEvent("OPEN_REGISTER_APPWARE_UI")
	this:RegisterEvent("CLOSE_REGISTER_ALL_UI")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("LOGIN_OVER_TIME")
end

function ShiWaiCYJ2_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= ShiWaiCYJ2_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= ShiWaiCYJ2_Frame:GetProperty("UnifiedYPosition");
	Changyoujia_Register_Clear()

end

function ShiWaiCYJ2_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		Changyoujia_Register_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		Changyoujia_Register_ResetPos()
	elseif ( event == "OPEN_REGISTER_APPWARE_UI") then
		Changyoujia_Register_Clear()
		this:Show()
	elseif (event == "CLOSE_REGISTER_ALL_UI" ) then
		this:Hide()
	elseif( event == "LOGIN_OVER_TIME" ) then
		this:Hide()
	end
end

function Changyoujia_Register_Clear()
	--ShiWaiCYJ1_Input:SetText("")
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function Changyoujia_Register_ResetPos()
	ShiWaiCYJ2_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	ShiWaiCYJ2_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function Changyoujia_Register_Clicked()
	--直接弹出网页
	GameProduceLogin:ReturnToAccountDlg()
	OpenUrl_ChangYouJia()
	this:Hide()
end

function Changyoujia_Register_CloseButton_Clicked()
	GameProduceLogin:ReturnToAccountDlg()
	this:Hide()
end

function OpenUrl_ChangYouJia()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_ZZB"))
end