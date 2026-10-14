local g_QiXi_Qiyu_FrameNULL_UnifiedPosition = nil 

function QiXi_Qiyu_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND", true)
end 

-- QiXi_Qiyu_Right2 => TLBB_StaticImageNULL
-- QiXi_Qiyu_Left => TLBB_StaticImageNULL
-- QiXi_Qiyu_Right1 => TLBB_StaticImageNULL
-- QiXi_Qiyu_Frame => TLBB_MainFrame16
-- QiXi_Qiyu_DragTitleBK => TLBB_Frame_Lace37
-- QiXi_Qiyu_DragTitle => TLBB_DragTitle
function QiXi_Qiyu_OnLoad()
	g_QiXi_Qiyu_FrameNULL_UnifiedPosition = QiXi_Qiyu_FrameNULL:GetProperty("UnifiedPosition");
end

function QiXi_Qiyu_OnEvent(event)
	if(event == "ADJEST_UI_POS") then
		QiXi_Qiyu_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		QiXi_Qiyu_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		QiXi_Qiyu_On_Hide()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 20220730) then
		this:Show()
	end
end



function QiXi_Qiyu_On_ResetPos()
	QiXi_Qiyu_FrameNULL:SetProperty("UnifiedPosition", g_QiXi_Qiyu_FrameNULL_UnifiedPosition)
end

function QiXi_Qiyu_On_Hide()
	this:Hide()
end

function QiXi_Qiyu_Help_Clicked()
	PushEvent("CCSHOP_HELP", 165)

end

