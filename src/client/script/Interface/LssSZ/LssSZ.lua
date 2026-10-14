local adjest_pos
local bagid
local free
local pay
local action_btn1
local action_btn2
local btn1
local btn2
local itemid1 = 38004070
local itemid2 = 39922095
local enum =
{
    FREE = 1,
    PAY = 2,
}

function LssSZ_OnEvent(event)
	if event == "UI_COMMAND" then
        local cmd = tonumber(arg0)
        if cmd == 89337901 then
            bagid = Get_XParam_INT(0)
            free = Get_XParam_INT(1)
            pay = Get_XParam_INT(2)

            LssSZ_Show()
        end
    end

    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or
           event == "VIEW_RESOLUTION_CHANGED" then
            LssSZ_ResetPos()
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            this:Hide()
        end
    end
end

function LssSZ_Clear()
    bagid = nil
    free = nil
    pay = nil
end

function LssSZ_Show()
    this:Show()
    
    local action = DataPool:CreateActionItemForShow(39922053, 1)
    if action:GetID() ~= 0 then
        action_btn1:SetActionItem(action:GetID())
    end
    action = DataPool:CreateActionItemForShow(39922095, 1)
    if action:GetID() ~= 0 then
        action_btn2:SetActionItem(action:GetID())
    end

    if free == 1 then
        btn1:SetText("#{SYYR_191204_25}")
        btn1:Disable()
    else
        btn1:SetText("#{SYYR_191204_23}")
        btn1:Enable()
    end

    if pay == 1 then
        btn2:SetText("#{SYYR_191204_26}")
        btn2:Disable()
    else
        btn2:SetText("#{SYYR_191204_24}")
        btn2:Enable()
    end

    if free == 1 or pay == 1 then
        this:Hide()
    end
end

function LssSZ_Close()
    this:Hide()
    LssSZ_Clear()
end

function LssSZ_ResetPos()
    LssSZ:SetProperty("UnifiedPosition", adjest_pos)
end

function LssSZ_OnHiden()
    this:Hide()
end

function LssSZ_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function LssSZ_OnLoad()
    adjest_pos = LssSZ:GetProperty("UnifiedPosition")
    btn1 = LssSZ_ReFresh_Btn
    btn2 = LssSZ_ReFresh_Btn2
    action_btn1 = LssSZ_Yuanbao_Icon
    action_btn2 = LssSZ_Yuanbao2_Icon
end

function LssSZ_Buy(which)
    if not which then return end
    if which ~= enum.FREE and
        which ~= enum.PAY then
        assert(false)
        return
    end

    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("buy")
    Set_XSCRIPT_ScriptID(893379)
    Set_XSCRIPT_Parameter(0, bagid)
    Set_XSCRIPT_Parameter(1, which)
    Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
end
