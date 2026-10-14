local adjest_pos
local this_day
local last_day
local count
local flags = { 0, 0, 0, 0, 0, 0, 0 }
local award_btns = {}
local award_gets = {}
local award_anims = {}
local awards =
{
    [1] = { count = 1,  id = 39920181, cnt = 2 },
    [2] = { count = 2,  id = 39920490, cnt = 5 },
    [3] = { count = 4,  id = 39921924, cnt = 1 },
    [4] = { count = 6, id = 39920999, cnt = 2 },
    [5] = { count = 8, id = 39922106, cnt = 1 },
}
local nums =
{
    [0] = "set:MenpaiPre1 image:QD_10",
    [1] = "set:MenpaiPre1 image:QD_1",
    [2] = "set:MenpaiPre1 image:QD_2",
    [3] = "set:MenpaiPre1 image:QD_3",
    [4] = "set:MenpaiPre1 image:QD_4",
    [5] = "set:MenpaiPre1 image:QD_5",
    [6] = "set:MenpaiPre1 image:QD_6",
    [7] = "set:MenpaiPre1 image:QD_7",
    [8] = "set:MenpaiPre1 image:QD_8",
    [9] = "set:MenpaiPre1 image:QD_9",
}

function Menpai_Pre_OnEvent(event)
     local function parse_data()
        last_day = Get_XParam_INT(0)
        count = Get_XParam_INT(1)
        flags[1] = Get_XParam_INT(2)
        flags[2] = Get_XParam_INT(3)
        flags[3] = Get_XParam_INT(4)
        flags[4] = Get_XParam_INT(5)
        flags[5] = Get_XParam_INT(6)
        flags[6] = Get_XParam_INT(7)
        flags[7] = Get_XParam_INT(8) -- animate
    end

	if event == "UI_COMMAND" then
        local cmd = tonumber(arg0)
        if cmd == 89324402 then -- open
            this_day = tonumber(DataPool:GetServerDayTime())
            parse_data()
            Menpai_Pre_Show()
        end

        if this:IsVisible() then
            if cmd == 89324403 then
                parse_data()
                Menpai_Pre_Show()
            end
        end
    end

    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or
           event == "VIEW_RESOLUTION_CHANGED" then
            Menpai_Pre_ResetPos()
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            Menpai_Pre_Clear()
            this:Hide()
        end
    end
end

function Menpai_Pre_Show()
    this:Show()

    Menpai_Pre_Animate7:Hide()
    if flags[7] == 1 then
        Menpai_Pre_Animate7:Show()
        Menpai_Pre_Animate7:Play(true)
    end

    for i = 1, 6 do
        award_btns[i]:Hide()
        award_gets[i]:Hide()
        award_anims[i]:Hide()
    end

    -- 隐藏已领取
    for i = 1, 5 do
        if flags[i] == 0 then
            award_btns[i]:Show()
            if count >= awards[i].count then
                award_anims[i]:Show()
            end
        else
            award_btns[i]:Show()
            award_gets[i]:Show()
        end

        local action = DataPool:CreateActionItemForShow(awards[i].id, awards[i].cnt)
        if action:GetID() ~= 0 then
            award_btns[i]:SetActionItem(action:GetID())
        end
    end

    btn_111 = award_btns[6]
    anim_111 = award_anims[6]
    geted_111 = award_gets[6]

    btn_111:Show()

--    特殊更新，不显示红点
    if this_day < 20200423 or this_day > 20200426 then
        btn_111:Show()
        btn_111:SetToolTip("#{MPYR_190902_08}")

        if flags[6] == 1 then
            geted_111:Show()
        end
    else
        if flags[6] == 0 then
            btn_111:Show()
            anim_111:Show()
            btn_111:SetToolTip("#{MPYR_190902_34}")
        else
            geted_111:Show()
            btn_111:SetToolTip("#{MPYR_190902_08}")
        end
    end

    if last_day == this_day then
        Menpai_Pre_Finish:Show()
        Menpai_Pre_Sure:Hide()
        Menpai_Pre_Text7:SetText("#{MPYR_190902_55}")
    else
        Menpai_Pre_Finish:Hide()
        Menpai_Pre_Sure:Show()
        Menpai_Pre_Text7:SetText("#{MPYR_190902_54}")
    end

    local tens, ones 
    tens = math.floor(count / 10)
    ones = math.mod(count, 10)
    if tens == 0 then
        Menpai_PrePic1:Show()
        Menpai_PrePic2:Hide()
        Menpai_PrePic3:Hide()

        Menpai_PrePic1:SetProperty("Image", nums[ones])
    else
        Menpai_PrePic1:Hide()
        Menpai_PrePic2:Show()
        Menpai_PrePic3:Show()

        Menpai_PrePic2:SetProperty("Image", nums[tens])
        Menpai_PrePic3:SetProperty("Image", nums[ones])
    end


end

function Menpai_Pre_Clear()
end

function Menpai_Pre_Close()
    this:Hide()
    Menpai_Pre_Clear()
end

function Menpai_Pre_ResetPos()
    Menpai_Pre_Frame:SetProperty("UnifiedPosition", adjest_pos)
end

function Menpai_Pre_OnShown()
    Menpai_Pre_Clear()
end

function Menpai_Pre_OnHiden()
    this:Hide()
end

function Menpai_Pre_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function Menpai_Pre_OnLoad()
    adjest_pos = Menpai_Pre_Frame:GetProperty("UnifiedPosition")
    award_btns =
    {
        Menpai_Pre_Button1,
        Menpai_Pre_Button2,
        Menpai_Pre_Button3,
        Menpai_Pre_Button4,
        Menpai_Pre_Button5,
        Menpai_Pre_Button6,
    }
    award_gets =
    {
        Menpai_Pre_Get1,
        Menpai_Pre_Get2,
        Menpai_Pre_Get3,
        Menpai_Pre_Get4,
        Menpai_Pre_Get5,
        Menpai_Pre_Get6,
    }
    award_anims =
    {
        Menpai_Pre_Animate1,
        Menpai_Pre_Animate2,
        Menpai_Pre_Animate3,
        Menpai_Pre_Animate4,
        Menpai_Pre_Animate5,
        Menpai_Pre_Animate6,
    }
end

function Menpai_Pre_Sign()
   Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(893244)
    Set_XSCRIPT_Function_Name("Sign")
    Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end

function Menpai_Pre_Award(which)
    if not which then return end

    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(893244)
    Set_XSCRIPT_Function_Name("Award")
    Set_XSCRIPT_Parameter(0, which)
    Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()
end

