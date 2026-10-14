local g_unifiedposistion

function ZBS_Camera_Tiny_PreLoad()
	this:RegisterEvent("ZBS_GMVISABLE_TINYSHOW")
	this:RegisterEvent("ZBS_GMVISABLE_SHOW",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function ZBS_Camera_Tiny_OnLoad()
	-- 保存界面的默认相对位置
	g_unifiedposistion	= ZBS_Camera_Tiny_Frame:GetProperty("UnifiedPosition")

end

function ZBS_Camera_Tiny_OnEvent(event)
	if( event == "ZBS_GMVISABLE_TINYSHOW" ) then
		ZBS_Camera_Tiny_OnShow()
	elseif( event == "ADJEST_UI_POS" ) then
		ZBS_Camera_Tiny_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		ZBS_Camera_Tiny_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		ZBS_Camera_Tiny_Close()
	elseif( event == "ZBS_GMVISABLE_SHOW" ) then
		this:Hide()
	end
end

function ZBS_Camera_Tiny_OnShow()
	this:Show()
end

function ZBS_Camera_Tiny_Close()
	ZBS:CancelGMWatch()
	this:Hide()
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function ZBS_Camera_Tiny_ResetPos()
	ZBS_Camera_Tiny_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end
--================================================

function ZBS_Camera_Tiny_OnShowNormalUI()
	this:Hide()
	PushEvent( "ZBS_GMVISABLE_SHOW" )
end
