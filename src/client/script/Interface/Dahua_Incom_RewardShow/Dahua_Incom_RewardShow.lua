local g_Dahua_Incom_RewardShowFrame_UnifiedPosition  
local g_Dahua_Incom_RewardShow_ctl = {} 
local g_Dahua_Incom_RewardShow_model = 1
local g_Dahua_Incom_RewardShow_round = 1
local g_Dahua_Incom_RewardShow_id = {0,0,0,0,0,0,0,0,0,0}
local g_Dahua_Incom_RewardShow_type = 1
local g_Dahua_Incom_isanimate = 0
local g_Dahua_Incom_RewardShow_ButtonCDTime = 1; --按钮冷却时间
local g_Dahua_Incom_RewardShow_ButtonLastTime = 0;
local g_Dahua_Incom_RewardShow_YinJiAnimateTick = 0
--=========
-- PreLoad()
--=========
function Dahua_Incom_RewardShow_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false) 
end

--=========
-- OnLoad()
--=========
function Dahua_Incom_RewardShow_OnLoad() 
	g_Dahua_Incom_RewardShowFrame_UnifiedPosition = Dahua_Incom_RewardShow_Frame:GetProperty("UnifiedPosition")
	Dahua_Incom_RewardShow_LoadControl()
end

--=========
-- Event
--=========
function Dahua_Incom_RewardShow_OnEvent(event)

    if(event == "UI_COMMAND" and tonumber(arg0) == 50100601) then	 
        if not this:IsVisible() then 
            g_Dahua_Incom_isanimate = 0
            g_Dahua_Incom_RewardShow_round = 1
            Dahua_Incom_RewardShow_Page1:Hide()
            Dahua_Incom_RewardShow_Page10:Hide()
        end
        g_Dahua_Incom_RewardShow_model  = Get_XParam_INT(0) 
        g_Dahua_Incom_RewardShow_type   = Get_XParam_INT(1)
        for i = 1, 10 do
            g_Dahua_Incom_RewardShow_id[i]     = Get_XParam_INT(i+1)
        end
        Dahua_Incom_RewardShow_Open()         
		this:Show()
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		Dahua_Incom_RewardShow_Hide()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		Dahua_Incom_RewardShow_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

        Dahua_Incom_RewardShow_On_ResetPos()
        		 
	end

end

function Dahua_Incom_RewardShow_Hide() 
    g_Dahua_Incom_isanimate = 0
    g_Dahua_Incom_RewardShow_round = 1
    Dahua_Incom_RewardShow_Page1:Hide()
    Dahua_Incom_RewardShow_Page10:Hide()
	this:Hide()
end

--=========
-- 重置
--=========
function Dahua_Incom_RewardShow_On_ResetPos()

	Dahua_Incom_RewardShow_Frame:SetProperty("UnifiedPosition", g_Dahua_Incom_RewardShowFrame_UnifiedPosition)

end
 
--=========
-- 打开
--=========
function Dahua_Incom_RewardShow_Open()
    Dahua_Incom_RewardShow_Updata()
end 
   
function Dahua_Incom_RewardShow_LoadControl()
    g_Dahua_Incom_RewardShow_ctl[1] = {}
    g_Dahua_Incom_RewardShow_ctl[1].item = {}
    g_Dahua_Incom_RewardShow_ctl[1].item[1] = Dahua_Incom_RewardShow_Item1 
    g_Dahua_Incom_RewardShow_ctl[1].Animate = {}
    g_Dahua_Incom_RewardShow_ctl[1].Animate[1] = Dahua_Incom_RewardShow_Item1_Animate 
    g_Dahua_Incom_RewardShow_ctl[2] = {}
    g_Dahua_Incom_RewardShow_ctl[2].item = {}
    g_Dahua_Incom_RewardShow_ctl[2].item[1] =Dahua_Incom_RewardShow_Item10_1
    g_Dahua_Incom_RewardShow_ctl[2].item[2] =Dahua_Incom_RewardShow_Item10_2
    g_Dahua_Incom_RewardShow_ctl[2].item[3] =Dahua_Incom_RewardShow_Item10_3
    g_Dahua_Incom_RewardShow_ctl[2].item[4] =Dahua_Incom_RewardShow_Item10_4
    g_Dahua_Incom_RewardShow_ctl[2].item[5] =Dahua_Incom_RewardShow_Item10_5
    g_Dahua_Incom_RewardShow_ctl[2].item[6] =Dahua_Incom_RewardShow_Item10_6
    g_Dahua_Incom_RewardShow_ctl[2].item[7] =Dahua_Incom_RewardShow_Item10_7
    g_Dahua_Incom_RewardShow_ctl[2].item[8] =Dahua_Incom_RewardShow_Item10_8
    g_Dahua_Incom_RewardShow_ctl[2].item[9] =Dahua_Incom_RewardShow_Item10_9
    g_Dahua_Incom_RewardShow_ctl[2].item[10]=Dahua_Incom_RewardShow_Item10_10
    g_Dahua_Incom_RewardShow_ctl[2].Animate = {} 
    g_Dahua_Incom_RewardShow_ctl[2].Animate[1] =Dahua_Incom_RewardShow_Item10_1_Animate
    g_Dahua_Incom_RewardShow_ctl[2].Animate[2] =Dahua_Incom_RewardShow_Item10_2_Animate
    g_Dahua_Incom_RewardShow_ctl[2].Animate[3] =Dahua_Incom_RewardShow_Item10_3_Animate
    g_Dahua_Incom_RewardShow_ctl[2].Animate[4] =Dahua_Incom_RewardShow_Item10_4_Animate
    g_Dahua_Incom_RewardShow_ctl[2].Animate[5] =Dahua_Incom_RewardShow_Item10_5_Animate
    g_Dahua_Incom_RewardShow_ctl[2].Animate[6] =Dahua_Incom_RewardShow_Item10_6_Animate
    g_Dahua_Incom_RewardShow_ctl[2].Animate[7] =Dahua_Incom_RewardShow_Item10_7_Animate
    g_Dahua_Incom_RewardShow_ctl[2].Animate[8] =Dahua_Incom_RewardShow_Item10_8_Animate
    g_Dahua_Incom_RewardShow_ctl[2].Animate[9] =Dahua_Incom_RewardShow_Item10_9_Animate
    g_Dahua_Incom_RewardShow_ctl[2].Animate[10]=Dahua_Incom_RewardShow_Item10_10_Animate
end 

--=========
-- 填充活动奖励界面
--=========
function Dahua_Incom_RewardShow_Updata() 
    Dahua_Incom_RewardShow_Client:Hide()
    Dahua_Incom_RewardShow_Page1:Hide()
    Dahua_Incom_RewardShow_Page10:Hide()
    if g_Dahua_Incom_RewardShow_model == 1 then
        g_Dahua_Incom_RewardShow_ctl[g_Dahua_Incom_RewardShow_model].Animate[1]:Show()
        local num = 1
        if g_Dahua_Incom_RewardShow_id[1] < 0 then
            num = math.abs(g_Dahua_Incom_RewardShow_id[1]) 
            g_Dahua_Incom_RewardShow_id[1] = 39924760
            g_Dahua_Incom_RewardShow_ctl[1].Animate[1]:Hide()
        end
        Dahua_Incom_RewardShow_Page1:Show() 
        local theAction = DataPool:CreateActionItemForShow(g_Dahua_Incom_RewardShow_id[1], num)
        if theAction:GetID() ~= 0 then 
            g_Dahua_Incom_RewardShow_ctl[g_Dahua_Incom_RewardShow_model].item[1]:SetActionItem(theAction:GetID()) 
        end   
    else
        for i = 1, 10 do
            g_Dahua_Incom_RewardShow_ctl[g_Dahua_Incom_RewardShow_model].Animate[i]:Show()
            local num = 1
            if g_Dahua_Incom_RewardShow_id[i] < 0 then
                num = math.abs(g_Dahua_Incom_RewardShow_id[i])
                g_Dahua_Incom_RewardShow_id[i] = 39924760
                g_Dahua_Incom_RewardShow_ctl[g_Dahua_Incom_RewardShow_model].Animate[i]:Hide()
            end
            local theAction = DataPool:CreateActionItemForShow(g_Dahua_Incom_RewardShow_id[i], num)
            if theAction:GetID() ~= 0 then 
                g_Dahua_Incom_RewardShow_ctl[g_Dahua_Incom_RewardShow_model].item[i]:SetActionItem(theAction:GetID()) 
            end   
        end        
        Dahua_Incom_RewardShow_Page10:Show()
    end 
    Dahua_Incom_RewardShow_ClientBk:SetProperty("Alpha",0)
    SetTimer("Dahua_Incom_RewardShow","Dahua_Incom_RewardShow_AlphaAnimateTimer()", 50)--计时器
    
end 


function Dahua_Incom_RewardShow_ChouJiang_Clicked(type)
    local curTime = OSAPI:GetTickCount();
	if ( curTime - g_Dahua_Incom_RewardShow_ButtonLastTime < g_Dahua_Incom_RewardShow_ButtonCDTime * 1000) then 
   	    PushDebugMessage("#{DHLS_240611_33}"); --不可连续点击，请稍等片刻后再点击
		return
	end
    g_Dahua_Incom_RewardShow_ButtonLastTime = curTime;
    

    Clear_XSCRIPT()
    Set_XSCRIPT_Function_Name("ChouJiang")
    Set_XSCRIPT_ScriptID( 501006 )
    Set_XSCRIPT_Parameter( 0, type ); 
    Set_XSCRIPT_ParamCount( 1 ); 
Send_XSCRIPT() 
end 

--=========
-- 计时器
--=========
function Dahua_Incom_RewardShow_AlphaAnimateTimer()
    g_Dahua_Incom_RewardShow_YinJiAnimateTick = g_Dahua_Incom_RewardShow_YinJiAnimateTick+1
    if g_Dahua_Incom_RewardShow_YinJiAnimateTick > 0 and g_Dahua_Incom_RewardShow_YinJiAnimateTick < 10 then
        Dahua_Incom_RewardShow_ClientBk:SetProperty("Alpha",g_Dahua_Incom_RewardShow_YinJiAnimateTick*0.1)						
    elseif g_Dahua_Incom_RewardShow_YinJiAnimateTick >= 10 then
            g_Dahua_Incom_RewardShow_YinJiAnimateTick = 0
            Dahua_Incom_RewardShow_ClientBk:SetProperty("Alpha",1)
            KillTimer("Dahua_Incom_RewardShow_AlphaAnimateTimer()")
            Dahua_Incom_RewardShow_Step_Sec()
    end  
end

function Dahua_Incom_RewardShow_Step_Sec() 
    Dahua_Incom_RewardShow_Client:Show()
    Dahua_Incom_RewardShow_Animate_txt:Show()
    SetTimer("Dahua_Incom_RewardShow","Dahua_Incom_RewardShow_txt_Timer()", 1*1000)
    
    if g_Dahua_Incom_RewardShow_type == 3 and g_Dahua_Incom_isanimate == 0 then
        Dahua_Incom_RewardShow_Animate:Show()
        SetTimer("Dahua_Incom_RewardShow","Dahua_Incom_RewardShow_Timer()", 3*1000)
    else
        Dahua_Incom_RewardShow_Animate:Hide()
    end
end

function Dahua_Incom_RewardShow_txt_Timer() 
    Dahua_Incom_RewardShow_Animate_txt:Hide()
    KillTimer("Dahua_Incom_RewardShow_txt_Timer()")
end

function Dahua_Incom_RewardShow_Timer()
    g_Dahua_Incom_isanimate = 0
    Dahua_Incom_RewardShow_Animate:Hide()
    KillTimer("Dahua_Incom_RewardShow_Timer()")
end