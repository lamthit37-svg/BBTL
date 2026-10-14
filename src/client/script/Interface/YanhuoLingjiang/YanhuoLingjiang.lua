
local g_canGetPrize = 0 --是否到了可领奖阶段
local g_StateTips = {

    [3] = "#{SYYH_191206_223}",

    [4] = "#{SYYH_191206_224}",

    [5] = "#{SYYH_191206_225}",

    [6] = "#{SYYH_191206_226}",

}

local g_WaitButton = {
    [2] = 3,
    [9] = 4,
    [10] = 5,
    [11] = 6
}
local g_StateButton = {}
local g_State = 0



function YanhuoLingjiang_PreLoad()
    this:RegisterEvent("UI_COMMAND")
    --this:RegisterEvent("OPEN_YANHUOHUILINGJIANG");
end

function YanhuoLingjiang_OnEvent(event)
    if ( event == "UI_COMMAND" and tonumber(arg0) == 89338301 ) then
			local state = Get_XParam_INT(0)
            local countSec = Get_XParam_INT(1)
            YanhuoLingjiang_ChangState(state,countSec)
    end
end

function YanhuoLingjiang_OnLoad()
    g_StateButton = {
        [3] = YanhuoLingjiang_Button1,
        [4] = YanhuoLingjiang_Button2,
        [5] = YanhuoLingjiang_Button3,
        [6] = YanhuoLingjiang_Button4,
    }
end

function YanhuoLingjiang_ChangState(state,countSec)
    g_State = state
    if state == 1 then
        --20:59 出现主界面 显示烟花会即将开始
        g_canGetPrize = 0
        YanhuoLingjiang_SetTimer(countSec)

        YanhuoLingjiang_Start_text:SetText("#{SYYH_191206_234}")
        YanhuoLingjiang_Start_text:Show()
        YanhuoLingjiang_KeLingQu:Hide()
        YanhuoLingjiang_DaoJiShi:Hide()
        YanhuoLingjiang_BK_Desk:Show()
        YanhuoLingjiang_Animate:Hide()
        YanhuoLingjiang_Button1:Show()
        YanhuoLingjiang_Button1:SetToolTip("#{SYYH_191206_250}")
        YanhuoLingjiang_Button2:Hide()
        YanhuoLingjiang_Button3:Hide()
        YanhuoLingjiang_Button4:Hide()
        YanhuoLingjiang_BK_LingJiang:Hide()
        this:Show()


    elseif state == 3 or state == 4 or state == 5 or state == 6 then
        --state3 : 21:03 领奖1阶段
        --state4 : 21:08 领奖2阶段
        --state5 : 21:13 领奖3阶段
        --state6 : 21:18 领奖4阶段
        g_canGetPrize = 1
        YanhuoLingjiang_SetTimer(countSec)
        YanhuoLingjiang_Start_text:Hide()
        YanhuoLingjiang_BK_Desk:Show()
        YanhuoLingjiang_DaoJiShi:Hide()
        YanhuoLingjiang_KeLingQu:Show()
        YanhuoLingjiang_Time_Prefix:SetText("#{SYYH_191206_236}")
        YanhuoLingjiang_Surfix1:SetText("#{SYYH_191206_238}")
        YanhuoLingjiang_Animate:Show()
        YanhuoLingjiang_Animate:Play(true)
        YanhuoLingjiang_BK_LingJiang:Show()
        for k,v in pairs(g_StateButton) do
            if k == state then
                
                v:Enable()
                v:Show()
                --v:PlayWarning(1)
                if k==6 and tonumber(DataPool:GetServerDayTime()) == 20230509 then
                    v:SetToolTip("#{SYYH_230315_1}")
                else
                    v:SetToolTip(g_StateTips[state])
                end
                
            else
                v:Disable()
                v:Hide()
                --v:PlayWarning(0)
            end
        end
        this:Show()
        

    elseif state == 2 or state == 9 or state == 10 or state == 11 then 
        --state2 :等待领奖1的状态
        --state9 : 领完奖1等待的状态  玩家才有的
        --state10 : 领完奖2等待的状态  玩家才有的
        --state11 : 领完奖3等待的状态  玩家才有的
        g_canGetPrize = 0
        YanhuoLingjiang_SetTimer(countSec)
        YanhuoLingjiang_Start_text:Hide()
        YanhuoLingjiang_BK_Desk:Show()
        YanhuoLingjiang_DaoJiShi:Show()
        YanhuoLingjiang_KeLingQu:Hide()
        YanhuoLingjiang_Surfix2:SetText("#{SYYH_191206_237}")
        YanhuoLingjiang_Animate:Hide()
        YanhuoLingjiang_BK_LingJiang:Hide()
        for k,v in pairs(g_StateButton) do
            if k == g_WaitButton[state]  then
                v:Enable()
                v:Show()
                --v:PlayWarning(0)
                if k==6 and tonumber(DataPool:GetServerDayTime()) == 20230509 then
                    v:SetToolTip("#{SYYH_230315_1}")
                else
                    v:SetToolTip(g_StateTips[state])
                end
            else
                v:Disable()
                v:Hide()
                --v:PlayWarning(0)
            end
        end

        this:Show()


    elseif state == 7 then 
        --领奖结束 
        g_canGetPrize = 0
        this:Hide()
        PushEvent("OPEN_NORMAL_WATCH")
  
    elseif state == 8 then 
        --关闭界面 结束领奖活动
        g_canGetPrize = 0
        this:Hide()
        PushEvent("OPEN_NORMAL_WATCH")
    end
end


function YanhuoLingjiang_UpdatePos( nValue )
end

function YanhuoLingjiang_MouseEnter()
end

function YanhuoLingjiang_MouseLeave()
end

function YanhuoLingjiang_Bn2Click()
    if g_canGetPrize ~= 1 then
        PushDebugMessage("#{SYYH_191206_217}")
        return
    end

    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("OnGetPrize")  --脚本接口
        Set_XSCRIPT_ScriptID(893383) --脚本编号 
        Set_XSCRIPT_ParamCount(0)
    Send_XSCRIPT()
end

function YanhuoLingjiang_TimeOut()
end

function YanhuoLingjiang_TimeOut1()
    YanhuoLingjiang_Time_CountDown1:SetProperty("TextColor","ffff0000");
    YanhuoLingjiang_Time_CountDown2:SetProperty("TextColor","ffff0000");
end

function YanhuoLingjiang_SetTimer(countSec)
    if g_State == 3 or g_State == 4 or g_State == 5 or g_State == 6 then
        --可领奖
        if countSec <= 10 then
            YanhuoLingjiang_Time_CountDown1:SetProperty("TextColor","ffff0000")-- 直接变色
            YanhuoLingjiang_Time_CountDown1:SetProperty("Timer",tostring(countSec))
    
        else 
            YanhuoLingjiang_Time_CountDown1:SetProperty("TextColor","ffffffff") -- 颜色改白色
            YanhuoLingjiang_Time_CountDown1:SetProperty("Timer",tostring(countSec))
            YanhuoLingjiang_Time_CountDown3_Inv:SetProperty("Timer",tostring( countSec - 10 ))
        end
    else
        --不可领奖
        if countSec <= 10 then
            YanhuoLingjiang_Time_CountDown2:SetProperty("TextColor","ffff0000")-- 直接变色
            YanhuoLingjiang_Time_CountDown2:SetProperty("Timer",tostring(countSec))
        else 
            YanhuoLingjiang_Time_CountDown2:SetProperty("TextColor","ffffffff") -- 颜色改回白色
            YanhuoLingjiang_Time_CountDown2:SetProperty("Timer",tostring(countSec))
            YanhuoLingjiang_Time_CountDown3_Inv:SetProperty("Timer",tostring( countSec - 10 ))
        end
    end

end