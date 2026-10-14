
-- 七夕商店 购买代币

local g_QiXi_Guide_2026_Shop_Cur_X
local g_QiXi_Guide_2026_Shop_Cur_Y

local g_QiXi_Guide_2026_Shop_CurrencyBuy = 10
local g_QiXi_Guide_2026_Shop_CurrencyNum = 0

--************************
-- PreLoad
--************************
function QiXi_Guide_2026_Shop_CurrencyBuy_PreLoad()

	this:RegisterEvent("UI_COMMAND",true);

    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("UPDATE_YUANBAO", false)
end

--************************
-- OnLoad
--************************
function QiXi_Guide_2026_Shop_CurrencyBuy_OnLoad()

    g_QiXi_Guide_2026_Shop_Cur_X = QiXi_Guide_2026_Shop_CurrencyBuy_Frame:GetProperty("UnifiedXPosition") 
	g_QiXi_Guide_2026_Shop_Cur_Y = QiXi_Guide_2026_Shop_CurrencyBuy_Frame:GetProperty("UnifiedYPosition")
	
end

--************************
-- OnEvent
--************************
function QiXi_Guide_2026_Shop_CurrencyBuy_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 89377701 ) then
	
		if Get_XParam_INT(0) == 0 or Get_XParam_INT(0) == 3 then
			QiXi_Guide_2026_Shop_CurrencyBuy_Close_Clicked()
			return
		end
		
		g_QiXi_Guide_2026_Shop_CurrencyNum = Get_XParam_INT(1)
		
		QiXi_Guide_2026_Shop_CurrencyBuy_InputNumBK:SetTextOriginal("1")
		QiXi_Guide_2026_Shop_CurrencyBuy_TextChanged()
      
		QiXi_Guide_2026_Shop_CurrencyBuy_InputNumBK:SetProperty("DefaultEditBox", "True")--设置输入框为默认输入框
		QiXi_Guide_2026_Shop_CurrencyBuy_InputNumBK:SetSelected(0, -1)
		
		this:Show()
		
    elseif event == "UPDATE_YUANBAO" then
        QiXi_Guide_2026_Shop_CurrencyBuy_TextChanged()
		
	elseif event == "VIEW_RESOLUTION_CHANGED" or event == "ADJEST_UI_POS" then
		QiXi_Guide_2026_Shop_CurrencyBuy_On_ResetPos()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		QiXi_Guide_2026_Shop_CurrencyBuy_Close_Clicked()
		
	end
end

--************************
-- 输入文本变化
--************************
function QiXi_Guide_2026_Shop_CurrencyBuy_TextChanged()

	local str = QiXi_Guide_2026_Shop_CurrencyBuy_InputNumBK:GetText()
	local strNumber = 0

    QiXi_Guide_2026_Shop_CurrencyBuy_InputNumBK:SetProperty("ClearOffset", "True")
	if str == nil then
		return
	elseif str == "" then
		strNumber = 0
        QiXi_Guide_2026_Shop_CurrencyBuy_InputNumBK:SetTextOriginal("")
	else
		strNumber = tonumber(str)
        str = tostring(strNumber)
        QiXi_Guide_2026_Shop_CurrencyBuy_InputNumBK:SetTextOriginal(str)
	end
	QiXi_Guide_2026_Shop_CurrencyBuy_InputNumBK:SetProperty("CaratIndex", 1024)

    -- 需要元宝
    local totalNeedYB = g_QiXi_Guide_2026_Shop_CurrencyBuy * strNumber
	QiXi_Guide_2026_Shop_CurrencyBuy_PriceNum:SetText(ScriptGlobal_Format("#{QXZH_250528_143}", totalNeedYB))
			
    -- 拥有元宝
    local yuanbao = Player:GetData("YUANBAO")
    if yuanbao >= totalNeedYB then
        QiXi_Guide_2026_Shop_CurrencyBuy_CashNum:SetText("#G" .. yuanbao)
    else
        QiXi_Guide_2026_Shop_CurrencyBuy_CashNum:SetText("#cff0000" .. yuanbao)
    end
	
	local nHaveBuy = ScriptGlobal_Format("#{QXZH_250528_141}", g_QiXi_Guide_2026_Shop_CurrencyNum)
	QiXi_Guide_2026_Shop_CurrencyBuy_LimitNum:SetText(nHaveBuy)
	
end

--************************
-- 确认兑换
--************************
function QiXi_Guide_2026_Shop_CurrencyBuy_OK_Clicked()
	
	local str = QiXi_Guide_2026_Shop_CurrencyBuy_InputNumBK:GetText()
    local inputNumber = tonumber(str)
	if inputNumber == nil or inputNumber == 0 then
		PushDebugMessage("#{QXZH_250528_145}")
		return
	end
    
	Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("OnQiXiShopDaibiBuy")
        Set_XSCRIPT_ScriptID(893777)
        Set_XSCRIPT_Parameter(0, inputNumber)
        Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()
	
end

--************************
-- 点击最大按钮
--************************
function QiXi_Guide_2026_Shop_CurrencyBuy_CalMax()

    local yuanbao = Player:GetData("YUANBAO")
    local canBuyMax = math.floor(yuanbao / g_QiXi_Guide_2026_Shop_CurrencyBuy)
	if canBuyMax <= 0 then
        canBuyMax = 1
    end
	
    if canBuyMax + g_QiXi_Guide_2026_Shop_CurrencyNum > 500 then
        canBuyMax = 500 - g_QiXi_Guide_2026_Shop_CurrencyNum
    end

    QiXi_Guide_2026_Shop_CurrencyBuy_InputNumBK:SetTextOriginal(tostring(canBuyMax))
    QiXi_Guide_2026_Shop_CurrencyBuy_TextChanged()
	
end

--************************
-- On_ResetPos
--************************
function QiXi_Guide_2026_Shop_CurrencyBuy_On_ResetPos()

	QiXi_Guide_2026_Shop_CurrencyBuy_Frame:SetProperty("UnifiedXPosition", g_QiXi_Guide_2026_Shop_Cur_X)
	QiXi_Guide_2026_Shop_CurrencyBuy_Frame:SetProperty("UnifiedYPosition", g_QiXi_Guide_2026_Shop_Cur_Y)
	
end

--************************
-- OnHiden
--************************
function QiXi_Guide_2026_Shop_CurrencyBuy_OnHidden()

	g_QiXi_Guide_2026_Shop_CurrencyNum = 0
	
end

--************************
-- 关闭界面
--************************
function QiXi_Guide_2026_Shop_CurrencyBuy_Close_Clicked()

	this:Hide()
	
end

