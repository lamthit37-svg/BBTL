function Cat_Ad_PreLoad()
	this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
    this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Cat_Ad_OnLoad()
	adjest_pos = Cat_Ad:GetProperty("UnifiedPosition")
end


function Cat_Ad_OnEvent(event)

    if event == "UI_COMMAND" then
        local cmd = tonumber(arg0)
        if cmd == 888081 then
            if not this:IsVisible() then
                Cat_Ad_ResetPos()
                this:Show()
            end
        end
 
    else
        if this:IsVisible() then
            if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
                Cat_Ad_ResetPos()
            elseif event == "HIDE_ON_SCENE_TRANSED" then
                this:Hide()
            end
        end
    end
end


function Cat_Ad_ResetPos()
    Cat_Ad:SetProperty("UnifiedPosition", adjest_pos)
end

--关闭
function Cat_Ad_Close()
    this:Hide()
end

function Cat_Ad_OnHidden()
    this:Hide()
end