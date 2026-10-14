local g_StealSkill_Guide_Frame_UnifiedPosition
local g_nUICommandID = 99975501

-- 入口NPC
local g_StealSkill_EnterNPCInfo =
{
    scn = 2,
    pos = { 280, 30 },
    name = "万晓生",
}
--=========================================================
-- PreLoad
--=========================================================
function StealSkill_Guide_PreLoad()
    this:RegisterEvent("UI_COMMAND") -- UI_COMMAND
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false) -- 离开场景
end

--=========================================================
-- OnLoad
--=========================================================
function StealSkill_Guide_OnLoad()
    g_StealSkill_Guide_Frame_UnifiedPosition = StealSkill_Guide_Frame_BK:GetProperty("UnifiedPosition")
end

--=========================================================
-- OnEvent
--=========================================================
function StealSkill_Guide_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_nUICommandID then
    	this:Show()
    	StealSkill_Guide_UpdateText()
    elseif event == "VIEW_RESOLUTION_CHANGED" or event == "ADJEST_UI_POS" then
        StealSkill_Guide_OnResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
        StealSkill_Guide_OnHide()
    end
end

function StealSkill_Guide_UpdateText()
	local HuoDongStartTime, HuoDongEndTime = GeTSSActiveTime()
	if HuoDongStartTime ~= -1 then
		local HDStartYear = math.floor(HuoDongStartTime / 10000)
		local HDStartMonth = math.floor( (math.mod(HuoDongStartTime, 10000)) / 100 )
		local HDStartDay =math. mod(HuoDongStartTime, 100)

		local HDEndYear = math.floor(HuoDongEndTime / 10000)
		local HDEndMonth = math.floor( (math.mod(HuoDongEndTime, 10000)) / 100 )
		local HDEndDay = math.mod(HuoDongEndTime, 100)
		
		local strText = ScriptGlobal_Format( "#{TXJN_250903_7}", HDStartYear, HDStartMonth, HDStartDay, HDEndYear, HDEndMonth, HDEndDay )
		StealSkill_Guide_Text:SetText(strText)
	else
		StealSkill_Guide_Text:Hide()	
	end	
end

--=========================================================
-- 点击前往
--=========================================================
function StealSkill_Guide_Goto()
    -- 寻路前往入口NPC
    local targetInfo = g_StealSkill_EnterNPCInfo
    if targetInfo ~= nil then
        AutoRuntoTargetExWithName(targetInfo.pos[1], targetInfo.pos[2], targetInfo.scn, targetInfo.name)
    end

    -- 关闭UI
    StealSkill_Guide_OnHide()
end

--=========================================================
-- 界面隐藏
--=========================================================
function StealSkill_Guide_OnHide()
    this:Hide()
end

--=========================================================
-- 界面重置
--=========================================================
function StealSkill_Guide_OnResetPos()
    StealSkill_Guide_Frame_BK:SetProperty("UnifiedPosition", g_StealSkill_Guide_Frame_UnifiedPosition)
end

function StealSkill_Guide_ShowHelp()
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnClickGuideInterfaceHelp")
			Set_XSCRIPT_ScriptID(999755)
			Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end
