-- 【2024Q2】 大话七夕商店
local g_DaHua_DaiBiGouMai_MainScriptId = 999236

local g_DaHua_DaiBiGouMai_start_time = 20250911
local g_DaHua_DaiBiGouMai_end_time = 20250917
local g_DaHua_DaiBiGouMai_BuyLevel = 30 -- 30级以上才可以购买

local g_DaHua_DaiBiGouMai_DaibiGouMai_Type = 1 -- 代币类型

local g_DaHua_DaiBiGouMai_Frame_UnifiedXPosition
local g_DaHua_DaiBiGouMai_Frame_UnifiedYPosition

-- 代币名称
local g_DaHua_DaiBiGouMai_Daibi_Strs = {
    "#{DHSD_20240522_53}", --倩心玉
    "#{DHSD_20240522_54}", --菩提珠
}
-- 购买代币介绍
local g_DaHua_DaiBiGouMai_Daibi_Intro = {
    "#{DHSD_20240522_33}",
    "#{DHSD_20240522_33}",
}
-- 代币兑换倍率
local g_DaHua_DaiBiGouMai_Daibi_ExchangeRate = {
    10,
    10,
}

--************************
-- PreLoad
--************************
function DaHua_DaiBiGouMai_PreLoad()
    this:RegisterEvent("DAHUASHOP_DAIBI_GOUMAI", true)
	this:RegisterEvent("DAHUASHOP_DAIBI_EXCHANGE", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("UPDATE_YUANBAO", false)
end

--************************
-- OnLoad
--************************
function DaHua_DaiBiGouMai_OnLoad()
    g_DaHua_DaiBiGouMai_Frame_UnifiedXPosition = DaHua_DaiBiGouMai_Frame:GetProperty("UnifiedXPosition") 
	g_DaHua_DaiBiGouMai_Frame_UnifiedYPosition = DaHua_DaiBiGouMai_Frame:GetProperty("UnifiedYPosition")
end

--************************
-- OnEvent
--************************
function DaHua_DaiBiGouMai_OnEvent(event)
	if event == "DAHUASHOP_DAIBI_GOUMAI" then
        g_DaHua_DaiBiGouMai_DaibiGouMai_Type = tonumber(arg0)
        DaHua_DaiBiGouMai_Moral_Value:SetTextOriginal("1")
        DaHua_DaiBiGouMai_Count_Change()
        local daibiName = DaHua_DaiBiGouMai_GetDaibiName()
        local daibiIntro = DaHua_DaiBiGouMai_GetDaibiExchangeIntro()
        _G["DaHua_DaiBiGouMai_DragTitle"]:SetText(ScriptGlobal_Format("#{DHSD_20240522_32}", daibiName))
        _G["DaHua_DaiBiGouMai_Text4"]:SetText(daibiIntro)
        _G["DaHua_DaiBiGouMai_Text2"]:SetText(ScriptGlobal_Format("#{DHSD_20240522_34}", daibiName))
        
        DaHua_DaiBiGouMai_Moral_Value:SetProperty("DefaultEditBox", "True")--设置输入框为默认输入框
        DaHua_DaiBiGouMai_Moral_Value:SetSelected(0, -1)

        this:Show()
    elseif event == "DAHUASHOP_DAIBI_EXCHANGE" then
        local daibiName = DaHua_DaiBiGouMai_GetDaibiName()
        local str = DaHua_DaiBiGouMai_Moral_Value:GetText()
        local strNumber = 0
    
        DaHua_DaiBiGouMai_Moral_Value:SetProperty("ClearOffset", "True")
        if str == nil then
            return
        elseif str == "" then
            strNumber = 0
            DaHua_DaiBiGouMai_Moral_Value:SetTextOriginal("")
        else
            strNumber = tonumber(str)
            str = tostring(strNumber)
            DaHua_DaiBiGouMai_Moral_Value:SetTextOriginal(str)
        end

        local totalNeedYB = DaHua_DaiBiGouMai_GetDaibiExchangeRate() * strNumber
        local str = ScriptGlobal_Format("#{DHSD_20240522_43}", totalNeedYB, strNumber, daibiName)
        MessageBoxSelf3("DaHua_DaiBiGouMai_OnConfirmed", {
            ["Content"] = str,
            ["Type"] = "YesNo"
        })
    elseif event == "UPDATE_YUANBAO" then
        DaHua_DaiBiGouMai_Count_Change()
	elseif event == "VIEW_RESOLUTION_CHANGED" or event == "ADJEST_UI_POS" then
		DaHua_DaiBiGouMai_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		DaHua_DaiBiGouMai_Close()
	end
end

--************************
-- 二次确认购买
--************************
function DaHua_DaiBiGouMai_OnConfirmed(strRet)
    if not strRet then
		return
	end
    local str = DaHua_DaiBiGouMai_Moral_Value:GetText()
    local inputNumber = tonumber(str)
	if "Yes" == strRet or "Ok" == strRet then
        Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name("DaibiExchangeConfirmed")
            Set_XSCRIPT_ScriptID(g_DaHua_DaiBiGouMai_MainScriptId)
            Set_XSCRIPT_Parameter(0, g_DaHua_DaiBiGouMai_DaibiGouMai_Type)
            Set_XSCRIPT_Parameter(1, inputNumber)
            Set_XSCRIPT_ParamCount(2)
        Send_XSCRIPT()
        this:Hide()
	end
end

--************************
-- 输入文本变化
--************************
function DaHua_DaiBiGouMai_Count_Change()
	local str = DaHua_DaiBiGouMai_Moral_Value:GetText()
	local strNumber = 0

    DaHua_DaiBiGouMai_Moral_Value:SetProperty("ClearOffset", "True")
	if str == nil then
		return
	elseif str == "" then
		strNumber = 0
        DaHua_DaiBiGouMai_Moral_Value:SetTextOriginal("")
	else
		strNumber = tonumber(str)
        str = tostring(strNumber)
        DaHua_DaiBiGouMai_Moral_Value:SetTextOriginal(str)
	end
	DaHua_DaiBiGouMai_Moral_Value:SetProperty("CaratIndex", 1024)

    -- 需要元宝
    local totalNeedYB = DaHua_DaiBiGouMai_GetDaibiExchangeRate() * strNumber
	DaHua_DaiBiGouMai_Text3YB:SetText(ScriptGlobal_Format("#{DHSD_20240522_19}", totalNeedYB))
    -- 拥有元宝
    local yuanbao = Player:GetData("YUANBAO")
    if yuanbao >= totalNeedYB then
        DaHua_DaiBiGouMai_Text1YB:SetText("#M" .. yuanbao)
    else
        DaHua_DaiBiGouMai_Text1YB:SetText("#cff0000" .. yuanbao)
    end
end

function DaHua_DaiBiGouMai_GetDaibiName()
    return g_DaHua_DaiBiGouMai_Daibi_Strs[g_DaHua_DaiBiGouMai_DaibiGouMai_Type]
end

function DaHua_DaiBiGouMai_GetDaibiExchangeIntro()
    return g_DaHua_DaiBiGouMai_Daibi_Intro[g_DaHua_DaiBiGouMai_DaibiGouMai_Type]
end

function DaHua_DaiBiGouMai_GetDaibiExchangeRate()
    return g_DaHua_DaiBiGouMai_Daibi_ExchangeRate[g_DaHua_DaiBiGouMai_DaibiGouMai_Type]
end

--************************
-- 确认兑换
--************************
function DaHua_DaiBiGouMai_OK_Clicked()
    local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay < g_DaHua_DaiBiGouMai_start_time or curDay > g_DaHua_DaiBiGouMai_end_time then
		PushDebugMessage("#{DHSD_20240522_55}") -- 当前非活动期间，无法进行此操作。
		return
	end
	
	if IsInTServer() == 1 then
		PushDebugMessage("#{DHSD_20240522_4}") -- 无法在天荒古境或汴京参与该活动。
		return
	end

    -- 判断是否为安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	-- 判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
    end

    local nLevel = Player:GetLevel()
	if nLevel < g_DaHua_DaiBiGouMai_BuyLevel then
		PushDebugMessage("#{DHSD_20240522_23}") -- 您的等级不足30级，无法进行此操作。
		return
	end

	local str = DaHua_DaiBiGouMai_Moral_Value:GetText()
    local inputNumber = tonumber(str)
	if inputNumber == nil or inputNumber == 0 then
		PushDebugMessage("#{DHSD_20240522_39}") -- 请重新输入需要购买的数量。
		return
	end

    local daibiName = DaHua_DaiBiGouMai_GetDaibiName()
    local daibiBuyCount = Lua_GetDaHua_DaiBiGouMai_DaibiBuyCount()
    local daibiMaxBuyCount = Lua_GetDaHua_DaiBiGouMai_DaibiMaxBuyCount()
    if daibiBuyCount >= daibiMaxBuyCount then
		PushDebugMessage("#{DHSD_20240522_40}") -- 倩心玉 仅能购买1000个。
        return
    end
    
    if inputNumber + daibiBuyCount > daibiMaxBuyCount then
        inputNumber = daibiMaxBuyCount - daibiBuyCount
        DaHua_DaiBiGouMai_Moral_Value:SetTextOriginal(tostring(inputNumber))
        DaHua_DaiBiGouMai_Count_Change()
        -- 活动期间仅能通过购买获得1000个倩心玉，您已购买了%s0个倩心玉，本次仅能购买%s1个。
        PushDebugMessage(ScriptGlobal_Format("#{DHSD_20240522_41}", daibiBuyCount, inputNumber))
        return
    end

    local totalNeedYB = DaHua_DaiBiGouMai_GetDaibiExchangeRate() * inputNumber
    local yuanbao = Player:GetData("YUANBAO")
    if yuanbao < totalNeedYB then
		PushDebugMessage("#{DHSD_20240522_42}") -- 您的元宝数量不足。
        return
    end
    
	Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("DaibiExchange")
        Set_XSCRIPT_ScriptID(g_DaHua_DaiBiGouMai_MainScriptId)
        Set_XSCRIPT_Parameter(0, g_DaHua_DaiBiGouMai_DaibiGouMai_Type)
        Set_XSCRIPT_Parameter(1, inputNumber)
        Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
end

--************************
-- 点击最大按钮
--************************
function DaHua_DaiBiGouMai_Max_Clicked()
    local yuanbao = Player:GetData("YUANBAO")
    local canBuyMax = math.floor(yuanbao / DaHua_DaiBiGouMai_GetDaibiExchangeRate())
	if canBuyMax < 0 then
        canBuyMax = 1
    end
    local daibiBuyCount = Lua_GetDaHua_DaiBiGouMai_DaibiBuyCount()
    local daibiMaxBuyCount = Lua_GetDaHua_DaiBiGouMai_DaibiMaxBuyCount()
    if canBuyMax + daibiBuyCount > daibiMaxBuyCount then
        canBuyMax = daibiMaxBuyCount - daibiBuyCount
    end

    DaHua_DaiBiGouMai_Moral_Value:SetTextOriginal(tostring(canBuyMax))
    DaHua_DaiBiGouMai_Count_Change()
end

--************************
-- On_ResetPos
--************************
function DaHua_DaiBiGouMai_On_ResetPos()
	DaHua_DaiBiGouMai_Frame:SetProperty("UnifiedXPosition", g_DaHua_DaiBiGouMai_Frame_UnifiedXPosition)
	DaHua_DaiBiGouMai_Frame:SetProperty("UnifiedYPosition", g_DaHua_DaiBiGouMai_Frame_UnifiedYPosition)
end

--************************
-- OnHiden
--************************
function DaHua_DaiBiGouMai_OnHiden()
    DaHua_DaiBiGouMai_Close()
end

--************************
-- 关闭界面
--************************
function DaHua_DaiBiGouMai_Cancel_Clicked()
	this:Hide()
end