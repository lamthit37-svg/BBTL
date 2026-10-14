local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

function Play_CG_PreLoad()
	this:RegisterEvent("CG_WINDOW_SHOW")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("GAMELOGIN_CLOSE_SELECT_SERVER",false)
end

function Play_CG_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Play_CG_Frame_1:GetProperty("UnifiedXPosition")
	g_Frame_UnifiedYPosition	= Play_CG_Frame_1:GetProperty("UnifiedYPosition")

end

function Play_CG_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		Play_CG_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		Play_CG_ResetPos()
	elseif( event == "GAMELOGIN_CLOSE_SELECT_SERVER" ) then
		this:Hide()
	elseif( event == "CG_WINDOW_SHOW" ) then
		this:Show()
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Play_CG_ResetPos()
	Play_CG_Frame_1:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Play_CG_Frame_1:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
--================================================

function Play_CG_NewAnimation_Clicked()
	local bRet = Lua_CgPreloadCurVideo()
	if bRet > 0 then
		Lua_CgPlayVideo()
	end
	-- cg动画提示
	--PushDebugMessage("#{CGBF_20230726_06}")
end

function Play_CG_OldAnimation_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_CGBF"))
end

function Play_CG_OnHiden()

end

function Play_CG_Close_Clicked()
	this:Hide()
end