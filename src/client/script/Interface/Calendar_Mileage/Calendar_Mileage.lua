local g_Frame_UnifiedPosition = nil

--今日总惬意值的上限
local g_LuckyPointLimit = 20

--剩余分享次数
local g_ShareTimes = 0
--基础惬意值
local g_BasePoint = 0
--总惬意值
local g_LuckyPoint = 0
--活动A基础春意
local g_BaseMileagePointA = 0
--活动B基础春意
local g_BaseMileagePointB = 0
--活动的完成情况 
local g_FinishStateA= 0
local g_FinishStateB= 0

local g_LimitLevel = 30
--春意倍率 = (惬意值或者叫里程暴击点或者叫福星点)+1
--春意 = 里程点
--春意倍率文字对应的图片1 
local g_LuckyPointImagesText = {
	[0] = {set ="Calendar3" ,image="1_0"},
	[5] = {set ="Calendar3" ,image="1_5"},
	[10] = {set ="Calendar3" ,image="2_0"},
	[15] = {set ="Calendar3" ,image="2_5"},
	[20] = {set ="Calendar3" ,image="3_0"},
}
--春意倍率盒子对应的图片2
local g_LuckyPointImagesBox = {
	[0] = {set ="Calendar3" ,image="Level_1"},
	[5] = {set ="Calendar3" ,image="Level_2"},
	[10] = {set ="Calendar4" ,image="Level_3"},
	[15] = {set ="Calendar4" ,image="Level_4"},
	[20] = {set ="Calendar5" ,image="Level_5"},
}

--=========
--PreLoad==
--=========
function Calendar_Mileage_PreLoad()
	this:RegisterEvent("SIRILIEX_JRLCD_UI", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end
--=========
--OnLoad
--=========
function Calendar_Mileage_OnLoad()
	g_Frame_UnifiedPosition = Calendar_Mileage_Frame_BK:GetProperty("UnifiedPosition")
end
--=========
--OnEvent
--=========
function Calendar_Mileage_OnEvent(event)
    if event == "SIRILIEX_JRLCD_UI" then
    -- 0:关闭1:打开2:刷新3:鼠标选完人了4:服务端要求选人
    local Opt = tonumber(arg0)
    if 4 == Opt then
        --鼠标进入点人状态 关闭界面
        MouseEnterShareLucky()
        if this:IsVisible() then
            Calendar_Mileage_OnHide()
        end
        return 
    elseif 3 == Opt then
        if IsInTServer()  == 1 then
            PushDebugMessage("#{SRLQY_201230_42}")
            return
        end
        local targetID = tonumber(arg1)
        if targetID < 15000 then
            return 
        end
        Clear_XSCRIPT()
        Set_XSCRIPT_ScriptID( 888333 )
        Set_XSCRIPT_Function_Name( "OnSharedToPlayer" )
        Set_XSCRIPT_Parameter(0, targetID)
        Set_XSCRIPT_ParamCount( 1 )
        Send_XSCRIPT()
        return 
    elseif 0 == Opt then
       Calendar_Mileage_OnHide()
        return 
    elseif 2 == Opt then
        if not this:IsVisible() then	
            return 
        end
    end
    --打开
        g_ShareTimes = tonumber(arg1)
        g_BasePoint = tonumber(arg2)
        g_LuckyPoint = tonumber(arg3)
        g_BaseMileagePointA = tonumber(arg4)
        g_BaseMileagePointB = tonumber(arg5)
        g_FinishStateA = tonumber(arg6)
        g_FinishStateB = tonumber(arg7)
        Calendar_Mileage_Open()
	elseif event == "VIEW_RESOLUTION_CHANGED" or event=="ADJEST_UI_POS" then
        Calendar_Mileage_On_ResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
		Calendar_Mileage_OnHide()
	end

end

function Calendar_Mileage_OnClickExchange()
    if IsInTServer()  == 1 then
        PushDebugMessage("#{SRLQY_201230_42}")
        return
	end
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( 888333 )
    Set_XSCRIPT_Function_Name( "OnSharedToPlayer" )
    Set_XSCRIPT_Parameter(0, 0)
    Set_XSCRIPT_ParamCount( 1 )
    Send_XSCRIPT()
end


function Calendar_Mileage_Open()
    --活动介绍
    Calendar_Mileage_Description_Text:SetText("#{SRLQY_201230_08}")
    --春意获取途径 
    Calendar_Mileage_BottomInfo1:SetText("#{SRLQY_201230_11}")
    Calendar_Mileage_BottomInfo2:SetText("#{SRLQY_201230_12}")

    --倍率礼盒
    local strPoint = string.format("%.1f", 1 + g_LuckyPoint/10 );
    Calendar_Mileage_HaveNumLevel:SetToolTip(ScriptGlobal_Format("#{SRLQY_201230_54}",strPoint))
    local imagetable = g_LuckyPointImagesBox[g_LuckyPoint]  
    if nil ~= imagetable then
        Calendar_Mileage_HaveNumLevel:SetImage(imagetable.set,imagetable.image)
    end
    --倍率文字
    imagetable = g_LuckyPointImagesText[g_LuckyPoint]
    if nil ~= imagetable then
        Calendar_Mileage_HaveNumPoint:SetImage(imagetable.set,imagetable.image)
    end

    --分享点和次数
    local strBasePoint = string.format("%.1f", g_BasePoint/10 );
    Calendar_Mileage_ShareNum:SetText(ScriptGlobal_Format("#{SRLQY_201230_17}",strBasePoint))
    Calendar_Mileage_ShareNumLeft:SetText(ScriptGlobal_Format("#{SRLQY_201230_18}",g_ShareTimes))
    
    --活动A基础春意
    Calendar_Mileage_BottomText1:SetText(ScriptGlobal_Format("#{SRLQY_200115_01}",g_BaseMileagePointA))
    --活动A额外春意
    Calendar_Mileage_BottomInfo1:SetText(ScriptGlobal_Format("#{SRLQY_200115_02}",math.ceil(g_LuckyPoint*g_BaseMileagePointA/10)))
     --活动B基础春意
    Calendar_Mileage_BottomText2:SetText(ScriptGlobal_Format("#{SRLQY_200115_03}",g_BaseMileagePointB))
     --活动B额外春意
    Calendar_Mileage_BottomInfo2:SetText(ScriptGlobal_Format("#{SRLQY_200115_04}",math.ceil(g_LuckyPoint*g_BaseMileagePointB/10)))
     if g_FinishStateA == 1 then
        Calendar_Mileage_RewardButton1:SetProperty("DisabledImage", "set:Calendar3 image:Finished")
        Calendar_Mileage_RewardButton1:Disable()
     else
        Calendar_Mileage_RewardButton1:Enable()
     end
     if g_FinishStateB == 1 then
        Calendar_Mileage_RewardButton2:SetProperty("DisabledImage", "set:Calendar3 image:Finished")
        Calendar_Mileage_RewardButton2:Disable()
     else
        Calendar_Mileage_RewardButton2:Enable()
     end

     this:Show()
end

function Calendar_Mileage_OnHelpClicked()
    -- 借用一下别人的通道
	PushEvent("OPEN_SWEEPPAGE_QUEST", "Calendar_Mileage_Help")
end

function Calendar_Mileage_ClickCanjia(num)
    if 1 == num then
        --春节1应景
        local curDay = DataPool:GetServerDayTime()
        if curDay < 20220117 or curDay > 20220130 then
            PushDebugMessage("#{CJYJ_211203_173}")
            return
        end
    
        local nLevel = Player:GetLevel();
        if nLevel < 30 then
            PushDebugMessage("#{CJYJ_211203_174}")
            return
        end
    
        local bRet = AutoRuntoTargetExWithName(244,337, 0, "陈弘海")
        if 0 == bRet then
            PushDebugMessage("无法自动寻路")
            return
        end
    
        Calendar_Mileage_OnHide()
    elseif 2 == num then
        --竹爆平安
        local curDay = tonumber(DataPool:GetServerDayTime())
        if curDay < 20220117 or curDay > 20220130 then
            PushDebugMessage("#{RACL_181206_443}")
            return
        end
        local nLevel = Player:GetLevel()
        if nLevel < g_LimitLevel then
            PushDebugMessage("#{RACL_181206_444}")
            return
        end
    
        --寻路
        AutoRunToTargetEx(215, 275, 0)	
        PushDebugMessage("#{RACL_181206_680}")
        Calendar_Mileage_OnHide()
    end
end

--=========
--OnClose "X"
--=========
function Calendar_Mileage_OnHide()
	this:Hide()
end

function Calendar_Mileage_OnHiden()
    this:Hide()
end



function Calendar_Mileage_On_ResetPos()
    if (this:IsVisible()) then
        if (g_Frame_UnifiedPosition ~= nil) then
            Calendar_Mileage_Frame_BK:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
        end
    end
end


