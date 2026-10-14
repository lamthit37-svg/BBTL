-- 周卡界面的默认位置
local g_YouLongKa_Frame_UnifiedXPosition;
local g_YouLongKa_Frame_UnifiedYPosition;

function YouLongKa_PreLoad()
    this:RegisterEvent("SHOW_WEEKCARD_DE_BUTTON");
    this:RegisterEvent("HIDE_WEEKCARD_DE_BUTTON");
    --this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("UPDATE_DOUBLE_EXP")
    this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function YouLongKa_OnLoad()
	g_YouLongKa_Frame_UnifiedXPosition = YouLongKa_Frame:GetProperty("UnifiedXPosition");
	g_YouLongKa_Frame_UnifiedYPosition = YouLongKa_Frame:GetProperty("UnifiedYPosition");
    
end

function YouLongKa_OnEvent(event)
    if ( event == "SHOW_WEEKCARD_DE_BUTTON" )  then
        local year,mon,day = ANSI2TM(tonumber(arg1))
        local name = Player:GetName()
        local time = "7"
        local str = ScriptGlobal_Format("#{YLK_120307_31}",name,tostring(year),tostring(mon),tostring(day), time)
        
        YouLongKa_Text1:SetText(str)
        
        --if tonumber(arg2) == 1 then
            
            --local str1 = "#{YLK_120307_20}"
            --YouLongKa_Text3:SetText(str1)
        --else
            
            --local str =""
            --if tonumber(arg3) >= 3600 then
                --local time = 0
                --time = math.floor(arg3/3600)
                --str = tostring(time).."h"
                
            --else
                --local min = math.floor(arg3/60)
                --local sec = math.mod(arg3,60)
                --str =  tostring(min)..":"..tostring(sec)
            --end
            --YouLongKa_Text3:SetText(tostring(str))
        --end
        YouLongKa_Button01_Clicked()
        
        this:Show()
    end
    
    if ( event == "HIDE_WEEKCARD_DE_BUTTON" )  then
        if this:IsVisible() then
            this:Hide()
            local str = "#{YLK_120307_07}"
            PushDebugMessage(str)
        end
    end
    
    if ( event == "UPDATE_DOUBLE_EXP" )  then
		local DT = SystemSetup : GetDoubleExp("remaintime");
        YouLongKa_Text3:SetProperty("Timer",DT);    
    end
    
    -- 游戏窗口尺寸发生了变化
    if ( event == "ADJEST_UI_POS" )  then
        -- 恢复游龙卡界面的默认相对位置
        YouLongKa_Frame_On_ResetPos()
    end
    
    -- 游戏分辨率发生了变化
    if ( event == "VIEW_RESOLUTION_CHANGED" )  then
        -- 恢复游龙卡界面的默认相对位置
        YouLongKa_Frame_On_ResetPos()
    end
    
    --进场景关闭界面
    if ( event == "HIDE_ON_SCENE_TRANSED" ) then  
        YouLongKa_Close()
    end
end

function YouLongKa_DE_Btn_Clicked()

    Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnUseDoubleTime")  --脚本接口
		Set_XSCRIPT_ScriptID(889678) --脚本编号
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
    
end

function YouLongKa_Close()
   if this:IsVisible() then
       this:Hide()
   end
end

function YouLongKa_Button01_Clicked()
    YouLongKa_Button01:SetCheck(1)
    YouLongKa_Text4:Hide()
    YouLongKa_BK1:Show()
    YouLongKa_Text2:Show()
    YouLongKa_Text3:Show()
end

function YouLongKa_Button02_Clicked()
    YouLongKa_BK1:Hide()
    YouLongKa_Text2:Hide()
    YouLongKa_Text3:Hide()
    local name = Player:GetName()
    local times = Player:WeekcardTakeTimes()
    local str = " "
    if tonumber(times) == 1 then
        times ="0"
        str = ScriptGlobal_Format("#{YLK_120307_38}",name,times)
    else
        times ="1"
        str = ScriptGlobal_Format("#{YLK_120307_28}",name,times)
    end
        
    YouLongKa_Text4:SetText(str)
    
    YouLongKa_Text4:Show()
end

function YouLongKa_Button03_Clicked()
    YouLongKa_BK1:Hide()
    YouLongKa_Text2:Hide()
    YouLongKa_Text3:Hide()
    local name = Player:GetName()
    local str = ScriptGlobal_Format("#{YLK_120307_29}",name)
    YouLongKa_Text4:SetText(str)
    --YouLongKa_Text4:RemoveAllChatString()
    --YouLongKa_Text4:InsertChatString(str)
    YouLongKa_Text4:Show()
end

-- 恢复游龙卡界面的默认相对位置
function YouLongKa_Frame_On_ResetPos()

	YouLongKa_Frame:SetProperty("UnifiedXPosition", g_YouLongKa_Frame_UnifiedXPosition);
	YouLongKa_Frame:SetProperty("UnifiedYPosition", g_YouLongKa_Frame_UnifiedYPosition);

end