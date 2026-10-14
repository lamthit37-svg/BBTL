local g_XingXia_Buy_Frame_UnifiedPosition
local g_HistoryDaiBi = 0
local g_YuanBao = 0
local g_MAX = 4000
local g_Price = 20
local g_CD = 5
local g_LastClickTime = 0
local g_BuyNum = 1
--===============================================
-- OnLoad()
--===============================================
function XingXia_Buy_PreLoad()
    this:RegisterEvent("UI_COMMAND",true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	--逻辑相关的事件
    this:RegisterEvent("OPEN_XINGXIA_BUY",true)
    
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

    this:RegisterEvent("UPDATE_YUANBAO",false);
end

function XingXia_Buy_OnLoad()
	g_XingXia_Buy_Frame_UnifiedPosition	=	XingXia_Buy_Frame:GetProperty("UnifiedPosition")
end 
--===============================================
-- OnEvent()
--===============================================
function XingXia_Buy_OnEvent( event )
	if event == "UI_COMMAND" and tonumber(arg0) == 88896302 then
        if Get_XParam_INT(0) == 2 then
            XingXia_Buy_OnHidden() 
            return
        end

        g_YuanBao =  Get_XParam_INT(1)
        g_HistoryDaiBi =  Get_XParam_INT(2)
	    XingXia_Buy_InputNum:SetProperty("DefaultEditBox", "True");	--设置输入框为默认输入框
        XingXia_Buy_InputNum:SetProperty("NormalTextColour", "#M"); --设置输入框为默认输入框
        g_BuyNum = 1 
        XingXia_Buy_InputNum:SetText(tostring(g_BuyNum))					--默认输入为1  

        XingXia_Buy_InputNum:SetSelected( 0, -1 ); 
        XingXia_Buy_ItemInfo:SetText(ScriptGlobal_Format("#{XXSD_220209_53}", g_HistoryDaiBi))
        XingXia_Buy_Price_Yuanbao:SetText("#M"..tostring(g_Price))
        if g_Price > g_YuanBao then
            XingXia_Buy_Cash_Yuanbao:SetText("#cff0000"..tostring(g_YuanBao))
        else
            XingXia_Buy_Cash_Yuanbao:SetText("#M"..tostring(g_YuanBao))
        end
        this:Activate()
        this:Show()
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		XingXia_Buy_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		XingXia_Buy_Closed()
	elseif event == "ADJEST_UI_POS" then
		XingXia_Buy_Frame_On_ResetPos() 
    elseif (event == "UPDATE_YUANBAO") then		
        g_YuanBao = Player:GetData("YUANBAO")
        if (g_Price * g_BuyNum) > g_YuanBao then
            XingXia_Buy_Cash_Yuanbao:SetText("#cff0000"..tostring(g_YuanBao))
        else
            XingXia_Buy_Cash_Yuanbao:SetText("#M"..tostring(g_YuanBao))
        end
	end
end

function XingXia_Buy_CalMax()
    local nMax = g_MAX - g_HistoryDaiBi
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
    XingXia_Buy_Price_Yuanbao:SetText("#M"..tostring(nNeedYB))
    XingXia_Buy_InputNum:SetText(tostring(g_BuyNum))  
    if g_YuanBao < nNeedYB or g_YuanBao == 0 then
        XingXia_Buy_Cash_Yuanbao:SetText("#cff0000"..tostring(g_YuanBao))--red
    else
        XingXia_Buy_Cash_Yuanbao:SetText("#M"..tostring(g_YuanBao))
    end       
end

function XingXia_Buy_TextChanged()

    local nString = XingXia_Buy_InputNum:GetText()
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

    local nMax = g_MAX - g_HistoryDaiBi

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
        XingXia_Buy_InputNum:SetText(tostring(g_BuyNum))
    end

    XingXia_Buy_Price_Yuanbao:SetText("#M"..tostring(nNeedYB))

    if g_YuanBao < nNeedYB or g_YuanBao == 0 then
        XingXia_Buy_Cash_Yuanbao:SetText("#cff0000"..tostring(g_YuanBao))--red
    else
        XingXia_Buy_Cash_Yuanbao:SetText("#M"..tostring(g_YuanBao))
    end
   
end

--===============================================

--===============================================
function XingXia_Buy_Buy_Clicked()

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
        Set_XSCRIPT_Function_Name( "DoBuyDaiBi" )
        Set_XSCRIPT_ScriptID( 888963 )
        Set_XSCRIPT_Parameter(0, g_BuyNum)
        Set_XSCRIPT_Parameter(1, 0)
        Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()      	
end


function XingXia_Buy_OnHidden() 
    XingXia_Buy_Clear()   
	this:Hide()
end
function XingXia_Buy_CancelClicked()
    XingXia_Buy_Clear()
	this:Hide()
end
--===============================================
--关闭界面
--===============================================
function XingXia_Buy_Closed()
    XingXia_Buy_Clear()
	this:Hide()
end

function XingXia_Buy_Frame_On_ResetPos()
	 XingXia_Buy_Frame:SetProperty("UnifiedPosition", g_XingXia_Buy_Frame_UnifiedPosition)
end

function XingXia_Buy_Clear()
    g_YuanBao = 0
    g_HistoryDaiBi = 0
    g_BuyNum = 1
    g_LastClickTime = 0
end