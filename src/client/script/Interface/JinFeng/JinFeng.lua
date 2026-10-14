local npcid 
local objCaredId
local adjest_pos
local cur_day
local limit_lv = 30
local fengyebi  -- 筹码
local bet   -- 下注选大小
local remain_times = 3  -- 默认3次机会, 并根据remain算出回合数
local fn_result = { 0, 0, 0 }   -- 上次结果,3个骰子(正常结果为1-6)
local mine_result = { 0, 0, 0 }
local last_win -- 上次输赢
local last_bet
local reward_count
local last_round
local wl_data = { [1] = {}, [2] = {}, [3] = {} }

local active_time =
{
    start_t = 20220815,
    end_t = 20220828
}
local round_info =
{
    [1] = "#{JFHD_180803_19}",
    [2] = "#{JFHD_180803_20}",
    [3] = "#{JFHD_180803_21}"
}
local touzi_image = { 
    [1] = "set:JinFeng image:Touzi_1",
    [2] = "set:JinFeng image:Touzi_2",
    [3] = "set:JinFeng image:Touzi_3",
    [4] = "set:JinFeng image:Touzi_4",
    [5] = "set:JinFeng image:Touzi_5",
    [6] = "set:JinFeng image:Touzi_6",
}
local enum = {
    MUCH    = 1,
    LITTLE  = 2
}
local yazhu_image = {
    [enum.MUCH] = "set:JinFeng image:JF_Big_Normal",
    [enum.LITTLE] = "set:JinFeng image:JF_Little_Nomal",
}


function JinFeng_OnEvent(event)
    local function parse_data()
        npcid = Get_XParam_INT(0)
        fengyebi = Get_XParam_INT(1)
        remain_times = Get_XParam_INT(2)
        last_win = Get_XParam_INT(3)
        last_bet = Get_XParam_INT(4)
        fn_result[1] = Get_XParam_INT(5)
        fn_result[2] = Get_XParam_INT(6)
        fn_result[3] = Get_XParam_INT(7)
        mine_result[1] = Get_XParam_INT(8)
        mine_result[2] = Get_XParam_INT(9)
        mine_result[3] = Get_XParam_INT(10)
        last_round = Get_XParam_INT(11)
        reward_count = Get_XParam_INT(12)
    end

    local function parse_cfg()
        wl_data[1].win = Get_XParam_INT(0)
        wl_data[1].lose = Get_XParam_INT(1)
        wl_data[2].win = Get_XParam_INT(2)
        wl_data[2].lose = Get_XParam_INT(3)
        wl_data[3].win = Get_XParam_INT(4)
        wl_data[3].lose = Get_XParam_INT(5)
    end

	if event == "UI_COMMAND" then
        local cmd = tonumber(arg0)
        if cmd == 2018080801 then -- open
            cur_day = tonumber(DataPool:GetServerDayTime())
            parse_data()
            if not npcid or npcid < 0 then
                return
            end

            objCaredId = DataPool:GetNPCIDByServerID(npcid)
            if not objCaredId then
                return
            end
            BeginCareObject_JinFeng(objCaredId)

            JF_Init_Show()
        end

        if this:IsVisible() then
            if cmd == 2018080802 then -- return result
                parse_data()
                JF_Server_Return()
            end
            if cmd == 2018080803 then
                parse_data()
                JF_Reward_Result()
                --:JF_Init_Show()
            end
            if cmd == 2018080804 then
                parse_cfg()
            end
        end
    end

    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or
           event == "VIEW_RESOLUTION_CHANGED" then
            JF_ResetPos()
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            JF_Clear()
            this:Hide()
        elseif event == "OBJECT_CARED_EVENT" then
            if objCaredId ~= tonumber(arg0) then
                return
            end
        elseif event == "JINFENGHAODU_SELECT_UI" then
            JF_Select_Show()
        elseif event == "JINFENGHAODU_REWARD_RESP" then
            JF_Reward_Confirm(tonumber(arg0))
        end
    end
end

function JF_Server_Return()
    JinFeng_FengNian_Pic_Animate:Show()
    JinFeng_Player_Pic_Animate:Show()
    JinFeng_FengNian_Pic_Animate:Play(true)
    JinFeng_Player_Pic_Animate:Play(true)
    JinFeng_Player_Wan:Hide()
    JinFeng_FengNian_Wan:Hide()

    SetTimer("JinFeng", "AnimateEnd()", 3000)
end

function AnimateEnd()
    KillTimer("AnimateEnd()")
    JinFeng_FengNian_Pic_Animate:Hide()
    JinFeng_Player_Pic_Animate:Hide()
    if last_win == 1 then
        local msg = ScriptGlobal_Format("#{JFHD_180803_46}", fengyebi or 0)
        PushDebugMessage(msg)

        if remain_times <= 0 then
            PushDebugMessage("#{JFHD_180803_36}")
        end
    else
        local msg
        if last_round == 1 then
            msg = "#{JFHD_180803_53}"
        else
            msg = ScriptGlobal_Format("#{JFHD_180803_54}", math.abs(wl_data[last_round].lose or 0))
        end
        PushDebugMessage(msg)
        PushDebugMessage("#{JFHD_180803_36}")
    end
    if this:IsVisible() then
        JF_Init_Show()
    end

    if remain_times <= 0 then
        JinFeng_StartButton_Animate:Play(false)
        if fengyebi > 0 then
            JinFeng_CollectButton_Animate:Play(true)
        else
            JinFeng_CollectButton_Animate:Play(false)
        end
    else
        JinFeng_StartButton_Animate:Play(true)
        JinFeng_CollectButton_Animate:Play(false)
    end

    JinFeng_Result_Animate:Show()
    JinFeng_Result_Animate:Play(true)
    SetTimer("JinFeng", "WinLoseEnd()", 1000)
end

function WinLoseEnd()
    KillTimer("WinLoseEnd()")
    JinFeng_Result_Animate:Hide()
end

function JF_Select_Show()
    JinFeng_Yazhu_BK:Show()
    JinFeng_FengNian_Pic_Animate:Hide()
    JinFeng_Player_Pic_Animate:Hide()
    JinFeng_Result_Animate:Hide()
end

function JF_Reward_Result()
    this:Show()
    
    JinFeng_FengNian_Win:Hide()
    JinFeng_FengNian_Lose:Hide()
    JinFeng_FengNian_Begin:Show()

    local msg
    if remain_times > 0 then
        msg = ScriptGlobal_Format("#{JFHD_180803_62}", 6)
    else
        msg = "#{JFHD_180803_65}"
    end
    JinFeng_Own_Slogan:SetText(msg)

    if last_round > 0 then
        JinFeng_Round_Times:SetText(round_info[last_round])
        JinFeng_Round_Times:Show()
    else
        JinFeng_Round_Times:Hide()
    end
 
    JF_Show_Cube(true)
    JinFeng_FengNian_Cube1:SetProperty("Image", touzi_image[fn_result[1] or 6])
    JinFeng_FengNian_Cube2:SetProperty("Image", touzi_image[fn_result[2] or 6])
    JinFeng_FengNian_Cube3:SetProperty("Image", touzi_image[fn_result[3] or 6])
    if fn_result[1] and fn_result[1] > 0 then
        JinFeng_FengNian_Num:SetText(ScriptGlobal_Format("#{JFHD_180803_16}",
            fn_result[1] + fn_result[2] + fn_result[3]))
        JinFeng_FengNian_Num:Show()
    else
        JinFeng_FengNian_Num:Hide()
    end

    JinFeng_Player_Cube1:SetProperty("Image", touzi_image[mine_result[1] or 6])
    JinFeng_Player_Cube2:SetProperty("Image", touzi_image[mine_result[2] or 6])
    JinFeng_Player_Cube3:SetProperty("Image", touzi_image[mine_result[3] or 6])
    if mine_result[1] and mine_result[1] > 0 then
        JinFeng_Player_Num:SetText(ScriptGlobal_Format("#{JFHD_180803_18}",
            mine_result[1] + mine_result[2] + mine_result[3]))
        JinFeng_Player_Num:Show()
    else
        JinFeng_Player_Num:Hide()
    end

    if last_bet then
        if last_bet == enum.MUCH then
            JinFeng_Round_Yazhu_Pic:SetProperty("Image", yazhu_image[last_bet])
            JinFeng_Round_Yazhu_Pic:Show()
            JinFeng_Round_Yazhu:SetText("#{JFHD_180803_48}")
            JinFeng_Round_Yazhu:Show()
        elseif last_bet == enum.LITTLE then
            JinFeng_Round_Yazhu_Pic:SetProperty("Image", yazhu_image[last_bet])
            JinFeng_Round_Yazhu_Pic:Show()
            JinFeng_Round_Yazhu:SetText("#{JFHD_180803_49}")
            JinFeng_Round_Yazhu:Show()
        else
            JinFeng_Round_Yazhu_Pic:Hide()
            JinFeng_Round_Yazhu:Hide()
        end
    else
        JinFeng_Round_Yazhu_Pic:Hide()
        JinFeng_Round_Yazhu:Hide()
    end

    JinFeng_StartButton:Disable()
    local fengyebi_info = ScriptGlobal_Format("#{JFHD_180803_22}", fengyebi or 0)
    JinFeng_Own:SetText(fengyebi_info)
    local times_info = ScriptGlobal_Format("#{JFHD_180803_23}", remain_times or 3)
    JinFeng_RemainTimes:SetText(times_info)
end

-- 隐藏押注界面 和 动画
function JF_Init_Show()
    this:Show()

    -- hide
    JinFeng_Yazhu_BK:Hide()
    JinFeng_Result_Animate:Hide()
    JinFeng_FengNian_Pic_Animate:Hide()
    JinFeng_Player_Pic_Animate:Hide()
    JinFeng_Own_Coin:SetToolTip(ScriptGlobal_Format("#{JFHD_180803_66}",fengyebi))
    JinFeng_Own:SetToolTip(ScriptGlobal_Format("#{JFHD_180803_66}",fengyebi))
    local msg
    if remain_times > 0 then
        msg = ScriptGlobal_Format("#{JFHD_180803_62}", 6)
    else
        msg = "#{JFHD_180803_65}"
    end
    JinFeng_Own_Slogan:SetText(msg)

    -- show lattest
    if last_round > 0 then
        JinFeng_FengNian_NumBK:Show()
        JinFeng_Player_NumBK:Show()
        JinFeng_Player_ResultBK:Show()
        JinFeng_FengNian_ResultBK:Show()

        if fn_result[1] + fn_result[2] + fn_result[3] >
            mine_result[1] + mine_result[2] + mine_result[3] then
            JinFeng_FengNian_ResultNum:SetText("#{JFHD_180803_63}")
            JinFeng_Player_ResultNum:SetText("#{JFHD_180803_64}")
        else
            JinFeng_FengNian_ResultNum:SetText("#{JFHD_180803_64}")
            JinFeng_Player_ResultNum:SetText("#{JFHD_180803_63}")
        end

        JinFeng_Player_Wan:Hide()
        JinFeng_FengNian_Wan:Hide()

        JinFeng_FengNian_Begin:Hide()
        JinFeng_Round_Times:Show()
        JinFeng_FengNian_Num:Show()
        JinFeng_Player_Num:Show()

        JinFeng_Round_Times:SetText(round_info[last_round])
        
        JF_Show_Cube(true)
        JinFeng_FengNian_Cube1:SetProperty("Image", touzi_image[fn_result[1]])
        JinFeng_FengNian_Cube2:SetProperty("Image", touzi_image[fn_result[2]])
        JinFeng_FengNian_Cube3:SetProperty("Image", touzi_image[fn_result[3]])
        JinFeng_FengNian_Num:SetText(ScriptGlobal_Format("#{JFHD_180803_16}",
                fn_result[1] + fn_result[2] + fn_result[3]))

        JinFeng_Player_Cube1:SetProperty("Image", touzi_image[mine_result[1]])
        JinFeng_Player_Cube2:SetProperty("Image", touzi_image[mine_result[2]])
        JinFeng_Player_Cube3:SetProperty("Image", touzi_image[mine_result[3]])
        JinFeng_Player_Num:SetText(ScriptGlobal_Format("#{JFHD_180803_18}",
                mine_result[1] + mine_result[2] + mine_result[3]))
        if last_win == 1 then
            JinFeng_FengNian_Win:Show()
            JinFeng_FengNian_Lose:Hide()
        else
            JinFeng_FengNian_Lose:Show()
            JinFeng_FengNian_Win:Hide()
        end

        if last_bet == enum.MUCH then
            JinFeng_Round_Yazhu_Pic:SetProperty("Image", yazhu_image[last_bet])
            JinFeng_Round_Yazhu:SetText("#{JFHD_180803_48}")
        else
            JinFeng_Round_Yazhu_Pic:SetProperty("Image", yazhu_image[last_bet])
            JinFeng_Round_Yazhu:SetText("#{JFHD_180803_49}")
        end
        JinFeng_Round_Yazhu_Pic:Show()
        JinFeng_Round_Yazhu:Show()
    else
        JinFeng_Round_Times:SetText(round_info[1])
        JinFeng_Round_Times:Show()
        JinFeng_Round_Yazhu:Hide()
        JinFeng_Round_Yazhu_Pic:Hide()
        JinFeng_FengNian_Lose:Hide()
        JinFeng_FengNian_Win:Hide()

        JinFeng_FengNian_Num:Hide()
        JinFeng_Player_Num:Hide()
        JinFeng_FengNian_Begin:Show()

        JF_Show_Cube(false)
        JinFeng_Player_Wan:Show()
        JinFeng_FengNian_Wan:Show()

        JinFeng_Player_ResultBK:Hide()
        JinFeng_FengNian_ResultBK:Hide()
        JinFeng_FengNian_NumBK:Hide()
        JinFeng_Player_NumBK:Hide()
    end

    if remain_times then
        if remain_times <= 0 then
            JinFeng_StartButton:Disable()
            JinFeng_StartButton_Animate:Play(false)
            if fengyebi > 0 then
                JinFeng_CollectButton_Animate:Play(true)
            else
                JinFeng_CollectButton_Animate:Play(false)
            end
        else
            JinFeng_StartButton:Enable()
            JinFeng_StartButton_Animate:Play(true)
            JinFeng_CollectButton_Animate:Play(false)
        end
    end

    local fengyebi_info = ScriptGlobal_Format("#{JFHD_180803_22}", fengyebi or 0)
    JinFeng_Own:SetText(fengyebi_info)
    local times_info = ScriptGlobal_Format("#{JFHD_180803_23}", remain_times or 3)
    JinFeng_RemainTimes:SetText(times_info)
end

function JinFeng_Check()
    --if cur_day < active_time.start_t or cur_day > active_time.end_t then
    --    PushDebugMessage("#{JFHD_180803_29}")
    --    return false
    --end
    local lv = Player:GetLevel()
    if lv < limit_lv then
        PushDebugMessage("#{JFHD_180803_30}")
        return false
    end
    if not fengyebi or fengyebi <= 0 then
        PushDebugMessage("#{JFHD_180803_31}")
        return false
    end
    if not remain_times or remain_times <= 0 then
        PushDebugMessage("#{JFHD_180803_32}")
        return false
    end

    return true
end

-- 弹出二级确认框
function JinFeng_Play_Click()
    if JinFeng_Check() == false then
        return
    end

    -- 二级框
    local next_round = math.mod(last_round, 3) + 1
    PushEvent("JINFENGHAODU_CONFIRM",
        fengyebi,
        fengyebi + wl_data[next_round].win or 0,
        math.max(fengyebi + wl_data[next_round].lose or 0, 0),
        remain_times)
end

function JF_Show_Cube(show)
    if show then
        JinFeng_Player_Cube1:Show()
        JinFeng_Player_Cube2:Show()
        JinFeng_Player_Cube3:Show()
        JinFeng_FengNian_Cube1:Show()
        JinFeng_FengNian_Cube2:Show()
        JinFeng_FengNian_Cube3:Show()
    else
        JinFeng_Player_Cube1:Hide()
        JinFeng_Player_Cube2:Hide()
        JinFeng_Player_Cube3:Hide()
        JinFeng_FengNian_Cube1:Hide()
        JinFeng_FengNian_Cube2:Hide()
        JinFeng_FengNian_Cube3:Hide()
    end
end

function JinFeng_Yazhu(which)
    if JinFeng_Check() == false then
        return
    end

    bet = which
    if bet == enum.MUCH then
        JinFeng_Round_Yazhu_Pic:SetProperty("Image", yazhu_image[bet])
        JinFeng_Round_Yazhu:SetText("#{JFHD_180803_48}")
        PushDebugMessage("#{JFHD_180803_44}")
    else
        JinFeng_Round_Yazhu_Pic:SetProperty("Image", yazhu_image[bet])
        JinFeng_Round_Yazhu:SetText("#{JFHD_180803_49}")
        PushDebugMessage("#{JFHD_180803_45}")
    end
    JinFeng_Round_Yazhu_Pic:Show()
    JinFeng_Round_Yazhu:Show()

    JinFeng_Yazhu_BK:Hide()
    JF_Show_Cube(false)

    JinFeng_FengNian_Win:Hide()
    JinFeng_FengNian_Lose:Hide()
    JinFeng_FengNian_Begin:Show()
    if last_round + 1 >= 1 and last_round + 1 <= 3 then
        JinFeng_Round_Times:SetText(round_info[last_round+1])
        JinFeng_Round_Times:Show()
    end
    local times_info = ScriptGlobal_Format("#{JFHD_180803_23}", (remain_times and remain_times - 1) or 3)
    JinFeng_RemainTimes:SetText(times_info)

    JinFeng_FengNian_NumBK:Hide()
    JinFeng_Player_NumBK:Hide()
    JinFeng_Player_Num:Hide()
    JinFeng_FengNian_Num:Hide()
    JinFeng_Player_ResultBK:Hide()
    JinFeng_FengNian_ResultBK:Hide() 

    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(892890)
    Set_XSCRIPT_Function_Name("dubo")
    Set_XSCRIPT_Parameter(0, npcid or 0)
    Set_XSCRIPT_Parameter(1, bet)
    Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
end

function JinFeng_DuBo()
    if remain_times <= 0 then
        return
    end

    if not bet then
        return
    end

    -- 发送请求
    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Dubo")
		Set_XSCRIPT_ScriptID(898890)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function JF_Reward_Check()
    --if cur_day < active_time.start_t or cur_day > active_time.end_t then
    --    PushDebugMessage("#{JFHD_180803_29}")
    --    return false
    --end
    if Player:GetLevel() < limit_lv then
        PushDebugMessage("#{JFHD_180803_30}")
        return false
    end
    if reward_count >= 2 then
        PushDebugMessage("#{JFHD_180803_37}")
        return false
    end
    -- 改服务器判断
    --if not fengyebi or fengyebi <= 0 then
    --    PushDebugMessage("#{JFHD_180803_38}")
    --    return false
    --end

    return true
end

function JF_Reward_Confirm(which)
    if which == 1 then -- 确定
        -- 发送请求
        Clear_XSCRIPT()
        Set_XSCRIPT_ScriptID(892890)
        Set_XSCRIPT_Function_Name("reward")
        Set_XSCRIPT_Parameter(0, npcid or 0)
        Set_XSCRIPT_ParamCount(1)
        Send_XSCRIPT()

        JinFeng_Close()
    else
        -- nothing
    end
end

-- 领取筹码到累积值
function JinFeng_Reward()
    if JF_Reward_Check() == false then
        return
    end
    
    -- 二次弹框
    if remain_times and remain_times > 0 then
        PushEvent("JINFENGHAODU_REWARD_CONFIRM", fengyebi, remain_times)
    else
        JF_Reward_Confirm(1)
    end
end

function JF_Help_Clicked()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("helpinfo")
	Set_XSCRIPT_ScriptID(892890)
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end

function JF_Clear()
end

function JinFeng_Close()
    StopCareObject_JinFeng()
    this:Hide()
    JF_Clear()
end

function JF_ResetPos()
    JinFeng_FrameNULL:SetProperty("UnifiedPosition", adjest_pos)
end

function JinFeng_OnShown()
    JF_Clear()
end

function JinFeng_OnHiden()
    StopCareObject_JinFeng()
    this:Hide()
end

function BeginCareObject_JinFeng(id)
	objCaredId = id
	this:CareObject(objCaredId, 1, "JinFeng")
end

function StopCareObject_JinFeng()
    if objCaredId then
        this:CareObject(objCaredId, 0, "JinFeng")
        objCaredId = nil
    end
end

function JinFeng_PreLoad()
	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
    this:RegisterEvent("OBJECT_CARED_EVENT",false)
    this:RegisterEvent("JINFENGHAODU_SELECT_UI",false)
    this:RegisterEvent("JINFENGHAODU_REWARD_RESP",false)
end

function JinFeng_OnLoad()
    adjest_pos = JinFeng_FrameNULL:GetProperty("UnifiedPosition")
end

