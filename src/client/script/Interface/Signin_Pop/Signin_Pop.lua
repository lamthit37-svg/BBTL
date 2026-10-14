local g_Signin_Pop_Frame_UnifiedPosition
local g_CurrentCoins = 0
local g_YuanBao = 0
local g_DrawTimes = 0
local g_MAX = 14
local g_Price = 500
local g_CD = 5
local g_LastClickTime = 0
local g_BuyNum = 1
--===============================================
-- OnLoad()
--===============================================
function Signin_Pop_PreLoad()
    this:RegisterEvent("UI_COMMAND",true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 

	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

    this:RegisterEvent("UPDATE_YUANBAO",false);
end

function Signin_Pop_OnLoad()
	g_Signin_Pop_Frame_UnifiedPosition	=	Signin_Pop_Frame:GetProperty("UnifiedPosition")
end 
--===============================================
-- OnEvent()
--===============================================
function Signin_Pop_OnEvent( event )
	if event == "UI_COMMAND" and tonumber(arg0) == 88872302 then
        if this:IsVisible() then
            Signin_Pop_Closed()
            return
        end
       
       
        g_YuanBao =  Get_XParam_INT(0)
        g_CurrentCoins = Get_XParam_INT(1)
        g_DrawTimes = Get_XParam_INT(2)

	    Signin_Pop_FeudalName:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
        --Signin_Pop_FeudalName:SetProperty("NormalTextColour", "#M"); --设置输入框为默认输入框

        g_BuyNum = 1 

        Signin_Pop_FeudalName:SetText(tostring(g_BuyNum))					--默认输入为1  

        Signin_Pop_FeudalName:SetSelected( 0, -1 ); 

        Signin_Pop_Text3_Num:SetText("#M"..tostring(g_Price*g_BuyNum))

        if g_Price > g_YuanBao then
            Signin_Pop_Text4_Num:SetText("#cff0000"..tostring(g_YuanBao))
        else
            Signin_Pop_Text4_Num:SetText("#M"..tostring(g_YuanBao))
        end
        this:Activate()
        this:Show()

    elseif event == "VIEW_RESOLUTION_CHANGED" then
		Signin_Pop_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Signin_Pop_Closed()
	elseif event == "ADJEST_UI_POS" then
		Signin_Pop_Frame_On_ResetPos() 
    elseif (event == "UPDATE_YUANBAO") then		
        g_YuanBao = Player:GetData("YUANBAO")
        if (g_Price * g_BuyNum) > g_YuanBao then
            Signin_Pop_Text4_Num:SetText("#cff0000"..tostring(g_YuanBao))
        else
            Signin_Pop_Text4_Num:SetText("#M"..tostring(g_YuanBao))
        end
	end
end

function Signin_Pop_CalMax()
    local nMax = g_MAX - g_DrawTimes - g_CurrentCoins
    if nMax < 0 then
        nMax = 0
    end

    local nCanBuy = math.floor(g_YuanBao/g_Price)

    local nMaxValue = 0
    local nNeedYB = 0

    if nMax > nCanBuy then
        nMaxValue = nCanBuy
    else
        nMaxValue = nMax
    end

    if nMaxValue <= 0 then
        nMaxValue = 1
    end

    nNeedYB = nMaxValue * g_Price
    g_BuyNum = nMaxValue
    Signin_Pop_Text3_Num:SetText("#M"..tostring(nNeedYB))
    Signin_Pop_FeudalName:SetText(tostring(g_BuyNum))  
    if g_YuanBao < nNeedYB or g_YuanBao == 0 then
        Signin_Pop_Text4_Num:SetText("#cff0000"..tostring(g_YuanBao))--red
    else
        Signin_Pop_Text4_Num:SetText("#M"..tostring(g_YuanBao))
    end       
end

function Signin_Pop_TextChanged()

    local nString = Signin_Pop_FeudalName:GetText()
    local nChangNum = 1
    if nString == nil or nString == "" then
        g_BuyNum = 0
        return
    else
        nChangNum = tonumber(nString)
        if nChangNum <= 0 then
            nChangNum = 1
        end
    end

    local nMax = g_MAX - g_DrawTimes - g_CurrentCoins
    if nMax < 0 then
        nMax = 0
    end

    local nCanBuy = math.floor(g_YuanBao/g_Price)

    local nMaxValue = 0
    local nNeedYB = 0

    if nMax > nCanBuy then
        nMaxValue = nCanBuy
    else
        nMaxValue = nMax
    end
    if nMaxValue <= 0 then
        nMaxValue = 1
    end

    if nChangNum > nMaxValue then
        nNeedYB = nMaxValue * g_Price
        nChangNum = nMaxValue
    else
        nNeedYB = nChangNum * g_Price
    end

    if g_BuyNum ~= tonumber(nString) then
        g_BuyNum = nChangNum
        Signin_Pop_FeudalName:SetText(tostring(g_BuyNum))
    end

    Signin_Pop_Text3_Num:SetText("#M"..tostring(nNeedYB))

    if g_YuanBao < nNeedYB or g_YuanBao == 0 then
        Signin_Pop_Text4_Num:SetText("#cff0000"..tostring(g_YuanBao))--red
    else
        Signin_Pop_Text4_Num:SetText("#M"..tostring(g_YuanBao))
    end
   
end

--===============================================

--===============================================
function Signin_Pop_Buy_Clicked()

    --判断是否处于兑换CD中
    local curTime = OSAPI:GetTickCount();
    if curTime - g_LastClickTime < 3000 then
        PushDebugMessage("#{XXSD_220209_63}")
        return
    end
    g_LastClickTime = curTime

    if g_BuyNum <= 0 then
        return
    end

	Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "DoBuy" )
        Set_XSCRIPT_ScriptID( 888723 )
        Set_XSCRIPT_Parameter(0, g_BuyNum)
        Set_XSCRIPT_Parameter(1, 0)
        Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()      	
end


function Signin_Pop_OnHidden() 
    Signin_Pop_Clear()   
	this:Hide()
end
function Signin_Pop_CancelClicked()
    Signin_Pop_Clear()
	this:Hide()
end
--===============================================
--关闭界面
--===============================================
function Signin_Pop_Closed()
    Signin_Pop_Clear()
	this:Hide()
end

function Signin_Pop_Frame_On_ResetPos()
	 Signin_Pop_Frame:SetProperty("UnifiedPosition", g_Signin_Pop_Frame_UnifiedPosition)
end

function Signin_Pop_Clear()
    g_YuanBao = 0
    g_CurrentCoins = 0
    g_BuyNum = 1
    g_DrawTimes = 0
    g_LastClickTime = 0
end