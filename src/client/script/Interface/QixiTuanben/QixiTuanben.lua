local g_QixiTuanben_BK_UnifiedPosition = nil 
local g_QixiTuanben_FBtype = 0;
function QixiTuanben_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND", true)

end 

-- QixiTuanbenNULL_Right2 => TLBB_StaticImageNULL
-- QixiTuanben => TLBB_MainFrame16
-- QixiTuanben_DragTitle => TLBB_DragTitle
-- QixiTuanbenNULL_Left => TLBB_StaticImageNULL
-- QixiTuanben_Title => TLBB_Frame_Lace37
-- QixiTuanbenNULL_Right1 => TLBB_StaticImageNULL
function QixiTuanben_OnLoad()
	g_QixiTuanben_BK_UnifiedPosition = QixiTuanben_Frame_BK:GetProperty("UnifiedPosition");
end

function QixiTuanben_OnEvent(event)
	if(event == "ADJEST_UI_POS") then
		QixiTuanben_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		QixiTuanben_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		QixiTuanben_Hide()
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 20220729) then
		this:Show()
		QixiTuanben_GoBtn:Hide()
		QixiTuanben_GoBtn2:Hide()

		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("AskFubenType")
			Set_XSCRIPT_ScriptID(800996) 
			Set_XSCRIPT_Parameter( 0, 2022072901 );	
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()		
	elseif(event == "UI_COMMAND" and tonumber(arg0)== 2022072901) then
		QixiTuanben_GotoLogic(Get_XParam_INT(0))
	end
end

function QixiTuanben_GotoLogic(type)
	if this:IsVisible() ~= true then
		return
	end
	if type == 1 then
		QixiTuanben_GoBtn:Show()
		QixiTuanben_GoBtn:Enable()
		QixiTuanben_GoBtn2:Show()
		QixiTuanben_GoBtn2:Disable()

	else
		QixiTuanben_GoBtn:Show()
		QixiTuanben_GoBtn:Disable()
		QixiTuanben_GoBtn2:Show()
		QixiTuanben_GoBtn2:Enable()

	end

	g_QixiTuanben_FBtype = type
end

function QixiTuanben_On_ResetPos()
	QixiTuanben_Frame_BK:SetProperty("UnifiedPosition", g_QixiTuanben_BK_UnifiedPosition)
end

function QixiTuanben_OnHide()

end
function QixiTuanben_Hide()
	this:Hide()
end





function QixiTuanben_Goto()
	if g_QixiTuanben_FBtype == 0 then
		PushDebugMessage("#{QXTB_220610_08}")
		AutoRuntoTargetExWithName(308, 244, 0, "穆小妹")
	else
		PushDebugMessage("#{QXTB_220610_09}")
		AutoRuntoTargetExWithName(308, 258, 0, "高阳")
	end
end

function QixiTuanben_ShowHelp()
	PushEvent("CCSHOP_HELP", 166)

end