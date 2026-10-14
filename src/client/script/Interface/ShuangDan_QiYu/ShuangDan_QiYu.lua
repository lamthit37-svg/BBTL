--2021Q4 踏雪寻芳
local g_Frame_UnifiedPosition = nil
local g_ExeScript = 888800
local g_UICOMMAND = 88880001
local g_HuaBaoNum = 9
local g_BitNum = 11
local g_UI_Items = {}
local g_BitState = {}
local g_HumanActivePoint = 0
--每朵花需要的活跃
local g_KJ_TAXUEXUNFANG = 118
local g_NeedActivePoint	=	
{
    nomarl = {50,100,150,200,250,300,350,400,450},
    kaji69 = {20,40,60,80,100,120,140,160,180},
}
local g_SpecialDay = 0



function ShuangDan_QiYu_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function ShuangDan_QiYu_OnLoad()
    g_Frame_UnifiedPosition = ShuangDan_QiYu_Frame:GetProperty("UnifiedPosition")
    g_UI_Items.HuaBao = {}
    for i=1,g_HuaBaoNum do
        g_UI_Items.HuaBao[i] = {
            btn = _G["ShuangDan_QiYu_Meihua"..i],
            redpoint = _G[string.format( "ShuangDan_QiYu_Meihua%d_Tips",i)],
            anim =  _G[string.format( "ShuangDan_QiYu_Meihua%d_Bloom",i)],
            finished = _G[string.format( "ShuangDan_QiYu_Meihua%d_BloomFinished",i)]
        }
    end
    g_UI_Items.Prize = {
        FukaBtn = ShuangDan_QiYu_FuKa,
        FukaRedPoint = ShuangDan_QiYu_FuKa_Tips,
        FukaAccepted = ShuangDan_QiYu_FuKa_Accept,
        XuYuanKaBtn = ShuangDan_QiYu_XuYuanKa,
        XuYuanKaRedPoint = ShuangDan_QiYu_XuYuanKa_Tips,
        XuYuanKaAccepted = ShuangDan_QiYu_XuYuanKa_Accept,
    }
    g_UI_Items.HuaBaoNumText = ShuangDan_QiYu_BloomNum
    g_UI_Items.ActivePointText = ShuangDan_QiYu_HuoYueValue

end

function ShuangDan_QiYu_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND then
        local nOpt = Get_XParam_INT(0)
        if nOpt == 1 then
            --打开界面
            local nState = Get_XParam_INT(1)	--花苞状态
            g_HumanActivePoint  = Get_XParam_INT(2) --玩家当日活跃
            g_BitState = ShuangDan_QiYu_GetBitTable(nState)
           -- PushDebugMessage("nState:"..nState..",g_HumanActivePoint:"..g_HumanActivePoint)
            g_SpecialDay =  Get_XParam_INT(3)
            ShuangDan_QiYu_Open(0)
        elseif nOpt == 2 then
            --刷新界面
            local nState = Get_XParam_INT(1)	--花苞状态
            g_HumanActivePoint  = Get_XParam_INT(2) --玩家当日活跃
            g_BitState = ShuangDan_QiYu_GetBitTable(nState)
            local anim = Get_XParam_INT(3)
            g_SpecialDay =  Get_XParam_INT(4)
            if ShuangDan_QiYu_Frame:IsVisible() then	
                ShuangDan_QiYu_Open(anim)
            end
            
        end

	elseif event == "VIEW_RESOLUTION_CHANGED" or event=="ADJEST_UI_POS" then
        ShuangDan_QiYu_On_ResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
		ShuangDan_QiYu_OnHide()
	end

end

function ShuangDan_QiYu_Open(aniIndex)
    if g_SpecialDay == 1 then
        g_UI_Items.Prize.FukaBtn:SetProperty("PushedImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_JinYuJian_Pushed")
        g_UI_Items.Prize.FukaBtn:SetProperty("NormalImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_JinYuJian_Normal")
        g_UI_Items.Prize.FukaBtn:SetProperty("HoverImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_JinYuJian_Hover")  
        g_UI_Items.Prize.FukaBtn:SetProperty("DisabledImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_JinYuJian_Normal")  
        g_UI_Items.Prize.XuYuanKaBtn:SetProperty("PushedImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_JinYuJian_Pushed")
        g_UI_Items.Prize.XuYuanKaBtn:SetProperty("NormalImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_JinYuJian_Normal")
        g_UI_Items.Prize.XuYuanKaBtn:SetProperty("HoverImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_JinYuJian_Hover")
        g_UI_Items.Prize.XuYuanKaBtn:SetProperty("DisabledImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_JinYuJian_Normal")
    else
        g_UI_Items.Prize.FukaBtn:SetProperty("PushedImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_YuJian_Pushed")
        g_UI_Items.Prize.FukaBtn:SetProperty("NormalImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_YuJian_Normal")
        g_UI_Items.Prize.FukaBtn:SetProperty("HoverImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_YuJian_Hover")  
        g_UI_Items.Prize.FukaBtn:SetProperty("DisabledImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_YuJian_Normal")
        g_UI_Items.Prize.XuYuanKaBtn:SetProperty("PushedImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_YuJian_Pushed")
        g_UI_Items.Prize.XuYuanKaBtn:SetProperty("NormalImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_YuJian_Normal")
        g_UI_Items.Prize.XuYuanKaBtn:SetProperty("HoverImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_YuJian_Hover")
        g_UI_Items.Prize.XuYuanKaBtn:SetProperty("DisabledImage", "set:ShuangDan_QiYu2 image:ShuangDan_QiYu_YuJian_Normal")
    end
    --动画
    if aniIndex < 0 or aniIndex > g_HuaBaoNum then
        return 
    end
    local tableNeedActivePoint = g_NeedActivePoint.nomarl
    if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(g_KJ_TAXUEXUNFANG) > 0 then 
        tableNeedActivePoint = g_NeedActivePoint.kaji69
    end
    --设置花苞状态
    local firstRed = 0 
    for i = 1,g_HuaBaoNum do
        if tableNeedActivePoint[i] > g_HumanActivePoint then
            --活跃值没达标
            g_UI_Items.HuaBao[i].btn:Show()
            g_UI_Items.HuaBao[i].finished:Hide()
            g_UI_Items.HuaBao[i].redpoint:Hide()
            g_UI_Items.HuaBao[i].anim:Hide()
            g_UI_Items.HuaBao[i].btn:SetToolTip(ScriptGlobal_Format("#{SDQY_211101_07}",tableNeedActivePoint[i]) )
        elseif g_BitState[i] == 1 then
            --花苞点过了
            g_UI_Items.HuaBao[i].btn:Hide()
            g_UI_Items.HuaBao[i].redpoint:Hide()
            if aniIndex == i then
                g_UI_Items.HuaBao[i].finished:Hide()
                g_UI_Items.HuaBao[i].anim:Show()
                g_UI_Items.HuaBao[i].anim:Play(true)
            else
                g_UI_Items.HuaBao[i].anim:Hide()   
                g_UI_Items.HuaBao[i].finished:Show()
            end
        else
            --即达标了 也没点过
            g_UI_Items.HuaBao[i].btn:Show()
            g_UI_Items.HuaBao[i].finished:Hide()
            g_UI_Items.HuaBao[i].anim:Hide()
            --第一个给红点
            if firstRed == 0 then
                g_UI_Items.HuaBao[i].redpoint:Show()
                g_UI_Items.HuaBao[i].btn:SetToolTip("#{SDQY_211101_05}")
                firstRed = 1
            else
                g_UI_Items.HuaBao[i].redpoint:Hide()
                g_UI_Items.HuaBao[i].btn:SetToolTip("#{SDQY_211101_06}")
            end
        end
    end
    --福卡状态
    if g_BitState[10] == 1 then
        g_UI_Items.Prize.FukaBtn:Disable()
        g_UI_Items.Prize.FukaRedPoint:Hide()
        g_UI_Items.Prize.FukaAccepted:Show()
    else
        if g_BitState[3] == 1 then
            g_UI_Items.Prize.FukaBtn:Enable()
            if g_SpecialDay==1 then
                g_UI_Items.Prize.FukaBtn:SetToolTip("#{SDQY_211101_11}")
            else
                g_UI_Items.Prize.FukaBtn:SetToolTip("#{SDQY_211101_09}")
            end
            g_UI_Items.Prize.FukaRedPoint:Show()
            g_UI_Items.Prize.FukaAccepted:Hide()
        else
            g_UI_Items.Prize.FukaBtn:Enable()
            g_UI_Items.Prize.FukaBtn:SetToolTip("#{SDQY_211101_08}")
            g_UI_Items.Prize.FukaRedPoint:Hide()
            g_UI_Items.Prize.FukaAccepted:Hide()
        end
    end
    --许愿卡状态
    if g_BitState[11] == 1 then
        g_UI_Items.Prize.XuYuanKaBtn:Disable()
        g_UI_Items.Prize.XuYuanKaRedPoint:Hide()
        g_UI_Items.Prize.XuYuanKaAccepted:Show()
    else
        if g_BitState[9] == 1 then
            g_UI_Items.Prize.XuYuanKaBtn:Enable()
            if g_SpecialDay==1 then
                g_UI_Items.Prize.XuYuanKaBtn:SetToolTip("#{SDQY_211101_11}")
            else
                g_UI_Items.Prize.XuYuanKaBtn:SetToolTip("#{SDQY_211101_09}")
            end
            g_UI_Items.Prize.XuYuanKaRedPoint:Show()
            g_UI_Items.Prize.XuYuanKaAccepted:Hide()
        else
            g_UI_Items.Prize.XuYuanKaBtn:Enable()
            g_UI_Items.Prize.XuYuanKaBtn:SetToolTip("#{SDQY_211101_10}")
            g_UI_Items.Prize.XuYuanKaRedPoint:Hide()
            g_UI_Items.Prize.XuYuanKaAccepted:Hide()
        end
    end
    --花苞绽放数量
    g_UI_Items.HuaBaoNumText:Show()
    g_UI_Items.HuaBaoNumText:SetText("#{SDQY_211101_13}"..ShuangDan_QiYu_HuaDuoNum())
    --活跃值
    g_UI_Items.ActivePointText:Show()
    g_UI_Items.ActivePointText:SetText(ScriptGlobal_Format("#{SDQY_211101_12}",g_HumanActivePoint))

    --描述 卡级服有区别
    local kajiType = KaJi:LuaFnGetKaJiType(32)
    if kajiType == 1 then
        ShuangDan_QiYu_Info:SetText("#{SDQY_211126_02}")
    else
        ShuangDan_QiYu_Info:SetText("#{SDQY_211101_14}")
    end
   

    this:Show()
end

function ShuangDan_QiYu_OnAnmiateEnd(anin)
    g_UI_Items.HuaBao[anin].anim:Hide() 
    g_UI_Items.HuaBao[anin].finished:Show()
end

function ShuangDan_QiYu_OnClickedHuaBao(index)
    --判断点击的是否是第一可以点击的
    local tableNeedActivePoint = g_NeedActivePoint.nomarl
    if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(g_KJ_TAXUEXUNFANG) > 0 then 
        tableNeedActivePoint = g_NeedActivePoint.kaji69
    end
    if g_HumanActivePoint < tableNeedActivePoint[index] then
        PushDebugMessage("#{SDQY_211101_15}")
        return 
    end
    local firstindex = 0
    for i=1,g_HuaBaoNum do
        if g_BitState[i] == 0 then
            firstindex = i
            break
        end
    end
    if firstindex < index then
        PushDebugMessage("#{SDQY_211101_17}")
        return 
    end
    
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( g_ExeScript )
    Set_XSCRIPT_Function_Name( "OnGetHuaBao" )
    Set_XSCRIPT_Parameter(0,index)
    Set_XSCRIPT_ParamCount( 1 )
    Send_XSCRIPT()
end

function ShuangDan_QiYu_OnClickedPrize(index)
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID( g_ExeScript )
    Set_XSCRIPT_Function_Name( "OnGetPrize" )
    Set_XSCRIPT_Parameter(0,index)
    Set_XSCRIPT_ParamCount( 1 )
    Send_XSCRIPT()
end

function ShuangDan_QiYu_OnClickedHelp()
   	-- 借用一下别人的通道
       PushEvent("CCSHOP_HELP", 139)
end


function ShuangDan_QiYu_On_ResetPos()
    if (this:IsVisible()) then
        if (g_Frame_UnifiedPosition ~= nil) then
            ShuangDan_QiYu_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
        end
    end
end



function ShuangDan_QiYu_OnHide()
    this:Hide()
end

function ShuangDan_QiYu_GetBitTable(nOct)
	local BitTable = {}
	local oct = nOct
	for i = 1 , g_BitNum do
		BitTable[i] = math.mod(oct , 2)
		oct = math.floor(oct / 2)
	end
	return BitTable
end

function ShuangDan_QiYu_HuaDuoNum()
    local num = 0
    for i = 1 , g_HuaBaoNum do
		num = num + g_BitState[i]
    end
    return num
end
