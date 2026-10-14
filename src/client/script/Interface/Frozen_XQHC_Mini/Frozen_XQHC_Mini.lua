local g_Frame_UnifiedPosition = nil
local g_ExeScript = 999473
local g_UICOMMAND = 99947301
local g_UICOMMAND_Challenge = 99947303
local g_StagetLevel = 0
local g_NumToNextLevel = 0
local g_levelText = {
    "#{XBDK_240922_74}",
    "#{XBDK_240922_75}",
    "#{XBDK_240922_76}",
    "#{XBDK_240922_77}"
}

function Frozen_XQHC_Mini_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Frozen_XQHC_Mini_OnLoad()
    g_Frame_UnifiedPosition = Frozen_XQHC_Mini_Frame:GetProperty("UnifiedPosition")

end



function Frozen_XQHC_Mini_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND then
		local nOpt = Get_XParam_INT(0)
        if nOpt == 1 then
            --开始前倒计时
            g_StagetLevel = Get_XParam_INT(1)
            g_NumToNextLevel = Get_XParam_INT(2)
            Frozen_XQHC_Mini_ShowInfo()
            this:Show()
        elseif nOpt == 88 then
            --结束 关闭界面
            this:Hide()
        end
    elseif event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND_Challenge then
		local nOpt = Get_XParam_INT(0)
        if nOpt==2 then
             --返回挑战秒数
            local sec=  Frozen_XQHC_Mini_Countdown_Time:GetProperty("Timer")
            Frozen_XQHC_Mini_Countdown_Time:SetProperty("Step", 0)--暂停
            local numSec = -1
            if sec then
                numSec = tonumber(sec)
            end
            if numSec then
                Clear_XSCRIPT()
                Set_XSCRIPT_Function_Name("OnCheckChallenge")
                Set_XSCRIPT_ScriptID(g_ExeScript)
                Set_XSCRIPT_Parameter(0,numSec)
                Set_XSCRIPT_ParamCount(1)
                Send_XSCRIPT()
            end
        elseif nOpt==3 then
            Frozen_XQHC_Mini_Text2:SetText("#{XBDK_240922_86}")
        elseif nOpt==777 then
            local fixedSec =  Get_XParam_INT(1)
            Frozen_XQHC_Mini_Countdown_Time:SetProperty("Timer",fixedSec)
        end
        
	elseif event == "VIEW_RESOLUTION_CHANGED" or event=="ADJEST_UI_POS" then
        Frozen_XQHC_Mini_On_ResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
		Frozen_XQHC_Mini_OnClose()


	end

end

function Frozen_XQHC_Mini_ShowInfo()

    if g_StagetLevel == 5 then
        Frozen_XQHC_Mini_Text1:Hide()
        Frozen_XQHC_Mini_Text2:SetText("#{XBDK_240922_39}")
    else
        Frozen_XQHC_Mini_Text1:Show()
        Frozen_XQHC_Mini_Text1:SetText(ScriptGlobal_Format("#{XBDK_240922_40}",g_levelText[g_StagetLevel]))
        Frozen_XQHC_Mini_Text2:SetText(ScriptGlobal_Format("#{XBDK_240922_41}",g_NumToNextLevel,g_levelText[g_StagetLevel]))
    end
    if g_StagetLevel == 1 and g_NumToNextLevel == 4 then
        --开始计时
        Frozen_XQHC_Mini_Countdown_Time:SetProperty("Step", 1) -- 正计时
        Frozen_XQHC_Mini_Countdown_Time:SetProperty("Timer",1)

    end
end


function Frozen_XQHC_Mini_On_ResetPos()
    if (this:IsVisible()) then
        if (g_Frame_UnifiedPosition ~= nil) then
            Frozen_XQHC_Mini_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
        end
    end
end

function Frozen_XQHC_Mini_Countdown_Help_Cliecked()
    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("ChallengeHelp")
    Set_XSCRIPT_ScriptID(g_ExeScript)
    Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end


function Frozen_XQHC_Mini_OnClose()

    this:Hide()
end