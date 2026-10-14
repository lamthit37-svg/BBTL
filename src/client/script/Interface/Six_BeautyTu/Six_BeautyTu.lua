local adjest_pos
local parts = { beautys = {}, anims = {}, heads = {}, texts = {}, returns = {} }
local which_enum =
{
    WHOLE_1 = 1,
    WHOLE_2 = 2,
    WHOLE_3 = 3,
    WHOLE_4 = 4,
    WHOLE_5 = 5,
    WHOLE_6 = 6,

    MID     = 7,
}
local how_move =
{
    "curve:Liner mode:Once duration:1.8 startx:-360 starty:0 endx:0 endy:0",
    "curve:Liner mode:Once duration:1.8 startx:-360 starty:0 endx:0 endy:0",
    "curve:Liner mode:Once duration:1.8 startx:-360 starty:0 endx:0 endy:0",
    "curve:Liner mode:Once duration:1.8 startx:-360 starty:0 endx:0 endy:0",
    "curve:Liner mode:Once duration:1.8 startx:-360 starty:0 endx:0 endy:0",
    "curve:Liner mode:Once duration:1.8 startx:-360 starty:0 endx:0 endy:0",
}
local poss =
{
    "{{0.000000,0.000000},{0.000000,0.000000}}",
    "{{0.000000,0.000000},{0.000000,0.000000}}",
    "{{0.000000,0.000000},{0.000000,0.000000}}",
    "{{0.000000,0.000000},{0.000000,0.000000}}",
    "{{0.000000,0.000000},{0.000000,0.000000}}",
    "{{0.000000,0.000000},{0.000000,0.000000}}",
}
local whole_show = { 0, 0, 0, 0, 0, 0 }

function Six_BeautyTu_OnEvent(event)
	if event == "UI_COMMAND" then
        local cmd = tonumber(arg0)
        if cmd == 89338101 then
            Six_BeautyTu_Show()
        end
    end

    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or
           event == "VIEW_RESOLUTION_CHANGED" then
            Six_BeautyTu_ResetPos()
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            this:Hide()
        end
    end
end

local function show_parts()
    for i = 1, 6 do
        local anim = assert(parts.anims[i])
        if whole_show[i] == 1 then
            anim:Show()
        else
            anim:Hide()
        end
    end
end

function Six_BeautyTu_Show()
    this:Show()
    show_parts()
end

function SLT_TweenEnd(which)
    parts.heads[which]:Show()
    parts.texts[which]:Show()
    parts.returns[which]:Show()
end

function SLT_Play(which)
    if whole_show[which] == 1 then
        return
    end
    for i = 1, 6 do
        whole_show[i] = 0
    end
    whole_show[which] = 1

    local anim = assert(parts.anims[which])
    local head = assert(parts.heads[which])
    local text = assert(parts.texts[which])
    local rtn_btn = assert(parts.returns[which])
    anim:Show()
    head:Hide()
    text:Hide()
    rtn_btn:Hide()
    
    anim:SetProperty("UnifiedPosition", poss[which])
    anim:Tween_SetInfo("Position", how_move[which])
    anim:Tween_Play("Position", true, true)

    show_parts()
end

function SLT_Return(which)
    if whole_show[which] == 0 then
        return
    end

    whole_show[which] = 0
    show_parts()
end

function Six_BeautyTu_Close()
    this:Hide()
end

function Six_BeautyTu_ResetPos()
    Six_BeautyTu_FrameNULL:SetProperty("UnifiedPosition", adjest_pos)
end

function Six_BeautyTu_OnHiden()
    this:Hide()
end

function Six_BeautyTu_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Six_BeautyTu_OnLoad()
    adjest_pos = Six_BeautyTu_FrameNULL:GetProperty("UnifiedPosition")
    parts =
    {
        beautys = -- active
        {
            Six_BeautyTu_LadyFrame1_Button1_BK,
            Six_BeautyTu_LadyFrame1_Button2_BK,
            Six_BeautyTu_LadyFrame1_Button3_BK,
            Six_BeautyTu_LadyFrame2_Button1_BK,
            Six_BeautyTu_LadyFrame2_Button2_BK,
            Six_BeautyTu_LadyFrame2_Button3_BK, 
        },
        anims =
        {
            Six_BeautyTu_LadyQuanTu1BK,
            Six_BeautyTu_LadyQuanTu2BK,
            Six_BeautyTu_LadyQuanTu3BK,
            Six_BeautyTu_LadyQuanTu4BK,
            Six_BeautyTu_LadyQuanTu5BK,
            Six_BeautyTu_LadyQuanTu6BK,
        },
        heads =
        {
            Six_BeautyTu_Lady1Head,
            Six_BeautyTu_Lady2Head,
            Six_BeautyTu_Lady3Head,
            Six_BeautyTu_Lady4Head,
            Six_BeautyTu_Lady5Head,
            Six_BeautyTu_Lady6Head,
        },
        texts =
        {
            Six_BeautyTu_Lady1Text2,
            Six_BeautyTu_Lady2Text2,
            Six_BeautyTu_Lady3Text2,
            Six_BeautyTu_Lady4Text2,
            Six_BeautyTu_Lady5Text2,
            Six_BeautyTu_Lady6Text2, 
        },
        returns =
        {
            Six_BeautyTu_1FanHui,
            Six_BeautyTu_2FanHui,
            Six_BeautyTu_3FanHui,
            Six_BeautyTu_4FanHui,
            Six_BeautyTu_5FanHui,
            Six_BeautyTu_6FanHui,
        },
    }
end

function SLT_Help()
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(893381)
    Set_XSCRIPT_Function_Name("help")
    Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end

