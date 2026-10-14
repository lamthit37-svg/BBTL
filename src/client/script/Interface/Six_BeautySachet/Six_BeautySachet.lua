local adjest_pos
local msg =
{
    [1] = "#{SYLM_191212_16}",
    [2] = "#{SYLM_191212_17}",
    [3] = "#{SYLM_191212_18}",
    [4] = "#{SYLM_191212_19}",
    [5] = "#{SYLM_191212_20}",
    [6] = "#{SYLM_191212_21}",
}

function Six_BeautySachet_OnEvent(event)
	if event == "UI_COMMAND" then
        local cmd = tonumber(arg0)
        if cmd == 89335604 then
            local npc = Get_XParam_INT(0)
            local idx = Get_XParam_INT(1)
            Six_BeautySachet_Show(idx)
        end
    end

    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or
           event == "VIEW_RESOLUTION_CHANGED" then
            Six_BeautySachet_ResetPos()
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            this:Hide()
        end
    end
end

function Six_BeautySachet_Show(idx)
    this:Show()

    Six_BeautySachetText:SetText(msg[idx] or "")
end

function Six_BeautySachet_Close()
    this:Hide()
end

function Six_BeautySachet_ResetPos()
    Six_BeautySachet_FrameNULL:SetProperty("UnifiedPosition", adjest_pos)
end

function Six_BeautySachet_OnHiden()
    this:Hide()
end

function Six_BeautySachet_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Six_BeautySachet_OnLoad()
    adjest_pos = Six_BeautySachet_FrameNULL:GetProperty("UnifiedPosition")
end

