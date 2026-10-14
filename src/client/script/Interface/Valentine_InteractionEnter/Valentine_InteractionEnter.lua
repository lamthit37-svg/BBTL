
local g_Frame_UnifiedPosition = nil
local g_ExeScript = 998352
local g_UICOMMAND = 99835201


function Valentine_InteractionEnter_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Valentine_InteractionEnter_OnLoad()
    g_Frame_UnifiedPosition = Valentine_InteractionEnter_Frame_BK:GetProperty("UnifiedPosition")

end

function Valentine_InteractionEnter_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND then
        local nOpt = Get_XParam_INT(0)
        if nOpt == 1 then
            --打开界面
            this:Show()
        elseif nOpt == 2 then
            --寻路
            local bRet = AutoRuntoTargetExWithName(178, 108, 164, "乔思") 
            if 0 == bRet then
                PushDebugMessage("无法自动寻路")
                return
            end
        end

	elseif event == "VIEW_RESOLUTION_CHANGED" or event=="ADJEST_UI_POS" then
        Valentine_InteractionEnter_On_ResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
		Valentine_InteractionEnter_OnHide()
	end

end





-- function Valentine_InteractionEnter_OnClickedHelp()
--    	-- 借用一下别人的通道
--        PushEvent("CCSHOP_HELP", 139)
-- end


function Valentine_InteractionEnter_On_ResetPos()
    if (this:IsVisible()) then
        if (g_Frame_UnifiedPosition ~= nil) then
            Valentine_InteractionEnter_Frame_BK:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
        end
    end
end



function Valentine_InteractionEnter_OnHide()
    this:Hide()
end

function Valentine_InteractionEnter_Hide()
    Valentine_InteractionEnter_OnHide()
end 

function Valentine_InteractionEnter_Goto()
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( g_ExeScript )
    Set_XSCRIPT_Function_Name( "OnJoinAct" )
    Set_XSCRIPT_ParamCount( 0 )
    Send_XSCRIPT()
end

function Valentine_InteractionEnter_ShowHelp()
    -- 借用一下别人的通道
    PushEvent("CCSHOP_HELP", 178)
end