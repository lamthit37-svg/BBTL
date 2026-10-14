local adjest_pos
local npc_id
local whole
local mid
local show_which
local whole_parts = { bks = {}, text1s = {}, text2s = {}, returns = {} }
local parts = { beautys = {}, null_btns = {}, anims = {}, heads = {}, texts = {}, returns = {}, shows = {} }
local parts_btns = {}
local sachet_btns = {}
local sachet_tips = {}
local flags =
{
    active = {0, 0, 0, 0, 0, 0},
    msg = {0, 0, 0, 0, 0, 0},
    award = 0,
    spec = 0,
}
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
local play_show = { 0, 0, 0, 0, 0, 0 } -- anims

function SL_Clear()
    flags =
    {
        active = {0, 1, 0, 0, 0, 0},
        msg = {0, 0, 0, 0, 0, 0},
        award = 0,
        spec = 0,
    }

    whole_show = { 0, 0, 0, 0, 0, 0 }
    play_show = { 0, 0, 0, 0, 0, 0 }
end

function Six_Beauty_OnEvent(event)
    local function parse()
        local active = flags.active
        local msg = flags.msg

        active[1] = Get_XParam_INT(0)
        active[2] = Get_XParam_INT(1)
        active[3] = Get_XParam_INT(2)
        active[4] = Get_XParam_INT(3)
        active[5] = Get_XParam_INT(4)
        active[6] = Get_XParam_INT(5)
        msg[1] = Get_XParam_INT(6)
        msg[2] = Get_XParam_INT(7)
        msg[3] = Get_XParam_INT(8)
        msg[4] = Get_XParam_INT(9)
        msg[5] = Get_XParam_INT(10)
        msg[6] = Get_XParam_INT(11)
        flags.award = Get_XParam_INT(12)
        flags.spec = Get_XParam_INT(13)
    end

	if event == "UI_COMMAND" then
        local cmd = tonumber(arg0)
        if cmd == 89335603 then
            parse()
            Six_Beauty_Show()
        end

        if this:IsVisible() then
            if cmd == 89335605 then
                local idx = Get_XParam_INT(0)
                SL_Play(idx)
            end
        end
    end

    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or
           event == "VIEW_RESOLUTION_CHANGED" then
            Six_Beauty_ResetPos()
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            this:Hide()
        end
    end
end

local function show_parts()
    local active = flags.active
    local msg = flags.msg
    for i = 1, 6 do
        local bk = assert(parts.beautys[i])
        local null_btn = assert(parts.null_btns[i])
        if active[i] == 1 then
            bk:Show()
            null_btn:Hide()
        else
            bk:Hide()
            null_btn:Show()
        end

        local anim = assert(parts.anims[i])
        if whole_show[i] == 1 then
            anim:Show()
        else
            anim:Hide()
        end

        if msg[i] == 1 then
            sachet_tips[i]:Show()
        else
            sachet_tips[i]:Hide()
        end

        parts.shows[i]:Hide()
    end

    if flags.award == 1 then
        Six_Beauty_Tip:Show()
    else
        Six_Beauty_Tip:Hide()
    end

    if parts.shows[spec] then
        parts.shows[spec]:Show()
    end
end

function Six_Beauty_Show()
    this:Show()
    show_parts()
    --SL_Switch(show_which or which_enum.MID)
end

function Six_Beauty_Close()
    this:Hide()
end

function Six_Beauty_ResetPos()
    Six_Beauty_FrameNULL:SetProperty("UnifiedPosition", adjest_pos)
end

function Six_Beauty_OnHiden()
    this:Hide()
    SL_Clear()
end

function Six_Beauty_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

local function whole_hide(which)
    whole_parts.bks[which]:Hide()
    whole_parts.text1s[which]:Hide()
    whole_parts.text2s[which]:Hide()
    whole_parts.returns[which]:Hide()
end

local function mid_hide(which)
    --parts_btns[which]:Hide()
end

local function show_mid(which)
    assert(which >= 1 and which <= 6)
    mid:Show()
    whole_hide(which)

    -- gray
--    local active = flags.active
--    if active[which] == 1 then
--        parts[which]:SetProperty("Image", normal[which])
--    else
--        parts[which]:SetProperty("Image", gray[which])
--    end
end

local function show_whole(which)
    assert(which >= 1 and which <= 6)
    local part = whole_parts.bks[which]
    part:Show()
    mid_hide(which)
end

local function show()
    for i = 1, 6 do
        if whole_show[i] == 0 then
            show_mid(i)
        else
            show_whole(i)
        end

        -- msg tips
        local msg = flag.msg
        if msg[i] == 1 then
            sachet_tips[i]:Show()
        else
            sachet_tips[i]:Hide()
        end
    end
end

function SL_PlayReq(idx)
    assert(idx)

    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(893356)
    Set_XSCRIPT_Function_Name("play")
    Set_XSCRIPT_Parameter(0, idx)
    Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()
end

function SL_Play(which)
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

function SL_Return(which)
    if whole_show[which] == 0 then
        return
    end

    whole_show[which] = 0
    show_parts()
end

function SL_Switch(which)
    assert(which)
    show(which)
end

function SL_TweenEnd(which)
    parts.heads[which]:Show()
    parts.texts[which]:Show()
    parts.returns[which]:Show()
    --whole_parts.text2s[which]:Show()
end

function SL_Msg(idx)
    assert(idx)

    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(893356)
    Set_XSCRIPT_Function_Name("msg")
    Set_XSCRIPT_Parameter(0, idx)
    Set_XSCRIPT_Parameter(1, 0)
    Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
end

function SL_Award()
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(893356)
    Set_XSCRIPT_Function_Name("award")
    Set_XSCRIPT_Parameter(0, 0)
    Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()
end

function SL_Help()
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(893356)
    Set_XSCRIPT_Function_Name("help")
    Set_XSCRIPT_Parameter(0, 0)
    Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()
end

function Six_Beauty_OnLoad()
    adjest_pos = Six_Beauty_FrameNULL:GetProperty("UnifiedPosition")
    whole = Six_Beauty_LadyQuanTuBK
    mid = Six_Beauty_Mid_LadyFrame
    whole_parts = 
    {
        bks =
        {
            Six_Beauty_LadyQuanTu1BK,
            Six_Beauty_LadyQuanTu2BK,
            Six_Beauty_LadyQuanTu3BK,
            Six_Beauty_LadyQuanTu4BK,
            Six_Beauty_LadyQuanTu5BK,
            Six_Beauty_LadyQuanTu6BK,
        },
        text1s =
        {
            Six_Beauty_Lady1Text1,
            Six_Beauty_Lady2Text1,
            Six_Beauty_Lady3Text1,
            Six_Beauty_Lady4Text1,
            Six_Beauty_Lady5Text1,
            Six_Beauty_Lady6Text1,
        },
        text2s =
        {
            Six_Beauty_Lady1Text2,
            Six_Beauty_Lady2Text2,
            Six_Beauty_Lady3Text2,
            Six_Beauty_Lady4Text2,
            Six_Beauty_Lady5Text2,
            Six_Beauty_Lady6Text2,
        },
        returns =
        {
            Six_Beauty_1FanHui,
            Six_Beauty_2FanHui,
            Six_Beauty_3FanHui,
            Six_Beauty_4FanHui,
            Six_Beauty_5FanHui,
            Six_Beauty_6FanHui,
        },
    }
    parts =
    {
        beautys = -- active
        {
            Six_Beauty_LadyFrame1_Button1_BK,
            Six_Beauty_LadyFrame1_Button2_BK,
            Six_Beauty_LadyFrame1_Button3_BK,
            Six_Beauty_LadyFrame2_Button1_BK,
            Six_Beauty_LadyFrame2_Button2_BK,
            Six_Beauty_LadyFrame2_Button3_BK, 
        },
        null_btns =
        {
            Six_Beauty_LadyFrame1_Button1_NULL,
            Six_Beauty_LadyFrame1_Button2_NULL,
            Six_Beauty_LadyFrame1_Button3_NULL,
            Six_Beauty_LadyFrame1_Button4_NULL,
            Six_Beauty_LadyFrame1_Button5_NULL,
            Six_Beauty_LadyFrame1_Button6_NULL,
        },
        anims =
        {
            Six_Beauty_LadyQuanTu1BK,
            Six_Beauty_LadyQuanTu2BK,
            Six_Beauty_LadyQuanTu3BK,
            Six_Beauty_LadyQuanTu4BK,
            Six_Beauty_LadyQuanTu5BK,
            Six_Beauty_LadyQuanTu6BK,
        },
        heads =
        {
            Six_Beauty_Lady1Head,
            Six_Beauty_Lady2Head,
            Six_Beauty_Lady3Head,
            Six_Beauty_Lady4Head,
            Six_Beauty_Lady5Head,
            Six_Beauty_Lady6Head,
        },
        texts =
        {
            Six_Beauty_Lady1Text2,
            Six_Beauty_Lady2Text2,
            Six_Beauty_Lady3Text2,
            Six_Beauty_Lady4Text2,
            Six_Beauty_Lady5Text2,
            Six_Beauty_Lady6Text2, 
        },
        returns =
        {
            Six_Beauty_1FanHui,
            Six_Beauty_2FanHui,
            Six_Beauty_3FanHui,
            Six_Beauty_4FanHui,
            Six_Beauty_5FanHui,
            Six_Beauty_6FanHui,
        },
        shows =
        {
            Six_Beauty_LadyFrame_Show1,
            Six_Beauty_LadyFrame_Show2,
            Six_Beauty_LadyFrame_Show3,
            Six_Beauty_LadyFrame_Show4,
            Six_Beauty_LadyFrame_Show5,
            Six_Beauty_LadyFrame_Show6,
        },
    }
    parts_btns =
    {
        Six_Beauty_LadyFrame1_Button1,
        Six_Beauty_LadyFrame1_Button2,
        Six_Beauty_LadyFrame1_Button3,
        Six_Beauty_LadyFrame2_Button1,
        Six_Beauty_LadyFrame2_Button2,
        Six_Beauty_LadyFrame2_Button3,
    }
    sachet_btns =
    {
        Six_Beauty_Sachet01,
        Six_Beauty_Sachet02,
        Six_Beauty_Sachet03,
        Six_Beauty_Sachet04,
        Six_Beauty_Sachet05,
        Six_Beauty_Sachet06,
    }
    sachet_tips =
    {
        Six_Beauty_Tip01,
        Six_Beauty_Tip02,
        Six_Beauty_Tip03,
        Six_Beauty_Tip04,
        Six_Beauty_Tip05,
        Six_Beauty_Tip06,
    }
end

