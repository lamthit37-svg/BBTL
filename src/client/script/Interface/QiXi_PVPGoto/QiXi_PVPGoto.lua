local g_Frame_UnifiedPosition
local g_qixipvpLevel = 60
--=========
-- PreLoad()
--=========
function QiXi_PVPGoto_PreLoad()

	this:RegisterEvent("UI_COMMAND")--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED")	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
	this:RegisterEvent("ADJEST_UI_POS")

end

--=========
-- OnLoad()
--=========
function QiXi_PVPGoto_OnLoad()
	g_Frame_UnifiedPosition = QiXi_PVPGoto_Frame_BK:GetProperty("UnifiedPosition")
end

--=========
-- Event
--=========
function QiXi_PVPGoto_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0)== 50714001 ) then
		this:Show()
	elseif (event == "UI_COMMAND" and tonumber(arg0)== 50714002 ) then
		QiXi_PVPGoto_Npc()	
	elseif event == "HIDE_ON_SCENE_TRANSED" then
        this:Hide()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		QiXi_PVPGoto_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		QiXi_PVPGoto_On_ResetPos()
    end
end


function QiXi_PVPGoto_On_ResetPos()
	QiXi_PVPGoto_Frame_BK:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

-- 
function QiXi_PVPGoto_GoTo()
	local playerLevel = Player:GetLevel()
    if playerLevel < g_qixipvpLevel  then        
        PushDebugMessage("#{XQPVP_260526_10}")
        return
	end
	
	-- 请求
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("PlayerClickGoTo")
		Set_XSCRIPT_ScriptID(507140)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function QiXi_PVPGoto_Npc()
	local playerLevel = Player:GetLevel()
    if playerLevel < g_qixipvpLevel  then        
        PushDebugMessage("#{XQPVP_260526_10}")
        return
    end

	AutoRuntoTargetExWithName(88, 210, 1075, "苏星河")
	this:Hide()
end

-- 帮助
function QiXi_PVPGoto_Help()
	PushEvent("CCSHOP_HELP", 250)
end

function  QiXi_PVPGoto_OnClose()
	this:Hide()
end

function QiXi_PVPGoto_OnHide()
	this:Hide()
end