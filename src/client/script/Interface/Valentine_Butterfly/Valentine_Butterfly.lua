
local g_Frame_UnifiedPosition = nil

local g_UICOMMAND = 99834001

local g_ImageIndex = {
    [1] = "set:Valentine_Butterfly image:Valentine_Butterfly_Text5", --情
    [2] = "set:Valentine_Butterfly image:Valentine_Butterfly_Text6", --深
    [3] = "set:Valentine_Butterfly image:Valentine_Butterfly_Text1", --不负
    [4] = "set:Valentine_Butterfly image:Valentine_Butterfly_Text7", --意
    [5] = "set:Valentine_Butterfly image:Valentine_Butterfly_Text3", --绵绵
    [6] = "set:Valentine_Butterfly image:Valentine_Butterfly_Text4", --浓
    [7] = "set:Valentine_Butterfly image:Valentine_Butterfly_Text2", --蜜
}


function Valentine_Butterfly_PreLoad()
    this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Valentine_Butterfly_OnLoad()
    g_Frame_UnifiedPosition = Valentine_Butterfly_Frame:GetProperty("UnifiedPosition")


end

function Valentine_Butterfly_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND then
        local huDieIndex = Get_XParam_INT(0)
        Valentine_Butterfly_Open(huDieIndex)

	elseif event == "VIEW_RESOLUTION_CHANGED" or event=="ADJEST_UI_POS" then
        Valentine_Butterfly_On_ResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
		Valentine_Butterfly_OnHide()
	end

end




function Valentine_Butterfly_Open(huDieIndex)
    if g_ImageIndex[huDieIndex] then
        Valentine_Butterfly_Info1:SetProperty("Image", g_ImageIndex[huDieIndex] )        
    end
    this:Show()
end


function Valentine_Butterfly_On_ResetPos()
    if (this:IsVisible()) then
        if (g_Frame_UnifiedPosition ~= nil) then
            Valentine_Butterfly_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
        end
    end
end



function Valentine_Butterfly_OnHide()
    this:Hide()
end



function Valentine_Butterfly_Close()
    Valentine_Butterfly_OnHide()
end 