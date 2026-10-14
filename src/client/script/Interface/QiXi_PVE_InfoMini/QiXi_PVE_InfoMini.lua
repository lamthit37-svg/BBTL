
local g_unifiedposistion
local g_QiXi_PVE_InfoMini_SceneId = 0
local g_QiXi_PVE_InfoMini_opType = {
	update = 2,
	updateTime=4,
	close = 999,					-- 关闭UI
}
local g_QiXi_PVE_InfoMini_UICommand = 05123801

local g_MaxMoHuaZhi = 100

local g_UI_Items = {
}
local g_PointInfo = {
    {v = 30,u = "#{QXFB_260529_325}",r="#{QXFB_260529_326}"},
    {v = 60,u = "#{QXFB_260529_325}",r="#{QXFB_260529_326}"},
    {v = 90,u = "#{QXFB_260529_325}",r="#{QXFB_260529_326}"},
    {v = 100,u = "#{QXFB_260529_325}",r="#{QXFB_260529_326}"},
}
function QiXi_PVE_InfoMini_PreLoad()
	this:RegisterEvent("OPEN_QiXi_PVE_InfoMini")
	this:RegisterEvent("UI_COMMAND", false)
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)	
end

function QiXi_PVE_InfoMini_OnLoad()	
	g_unifiedposistion = QiXi_PVE_InfoMini_Frame:GetProperty("UnifiedPosition")

	g_UI_Items.Points = {}
    for i=1,4 do
        g_UI_Items.Points[i] = {}
        g_UI_Items.Points[i].Arrow = _G["QiXi_PVE_InfoMini_TopProgress_ArrowUp"..i]
    end

	g_UI_Items.topBK1 = QiXi_PVE_InfoMini_TopBK1
    g_UI_Items.topBK2 = QiXi_PVE_InfoMini_TopBK2
end

function QiXi_PVE_InfoMini_OnEvent(event)
	if event == "OPEN_QiXi_PVE_InfoMini" then
		local progressValue = tonumber(arg0)
		local stepName = arg1
		QiXi_PVE_InfoMini_Init(progressValue,stepName)
		this:Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_QiXi_PVE_InfoMini_UICommand then
		local opType =  Get_XParam_INT( 0 )
		if opType == g_QiXi_PVE_InfoMini_opType.close then
			this:Hide()
		elseif opType == g_QiXi_PVE_InfoMini_opType.update then
            if (this:IsVisible()) then
				local progressValue = Get_XParam_INT( 2 )
				local stepName = Get_XParam_STR( 1 )
				QiXi_PVE_InfoMini_Init(progressValue,stepName)
			end
		end

	elseif event == "PLAYER_LEAVE_WORLD" then
		this:Hide()
	elseif event == "ADJEST_UI_POS" then
		QiXi_PVE_InfoMini_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		QiXi_PVE_InfoMini_ResetPos()
	end
end

function QiXi_PVE_InfoMini_ResetPos()
	QiXi_PVE_InfoMini_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function QiXi_PVE_InfoMini_OnHide()
	
end
function QiXi_PVE_InfoMini_Init(progressValue,stepName)

	QiXi_PVE_InfoMini_TopProgress:SetProgress(progressValue,g_MaxMoHuaZhi)

	QiXi_PVE_InfoMini_TopText:SetText(ScriptGlobal_Format("#{QXFB_260529_217}",progressValue))

	for i=1,4 do
		if progressValue < g_PointInfo[i].v then
			g_UI_Items.Points[i].Arrow:SetToolTip(g_PointInfo[i].u)
		else
			g_UI_Items.Points[i].Arrow:SetToolTip(g_PointInfo[i].r)
		end
	end

	if (stepName == "S4" or stepName == "E4") and progressValue == 0 then
		for i=1,4 do
			g_UI_Items.Points[i].Arrow:Hide()
		end
		g_UI_Items.topBK2:Show()
		g_UI_Items.topBK1:Hide()
	else
		for i=1,4 do
			g_UI_Items.Points[i].Arrow:Show()
		end
		g_UI_Items.topBK1:Show()
		g_UI_Items.topBK2:Hide()
	end

end
	

function QiXi_PVE_InfoMini_Close()
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("OpenInfoUI")
    Set_XSCRIPT_ScriptID(051238)
    Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end

function QiXi_PVE_InfoMini_TopHelp_Clicked()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("UIHelp")
	Set_XSCRIPT_ScriptID(051238)
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end