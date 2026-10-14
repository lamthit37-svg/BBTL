local g_Xiake_Shop_DbBuy_Frame_UnifiedPosition
local g_Xiake_Shop_DbBuy_TokenType

local g_Xiake_Shop_DbBuy_TokenName = {
    [0] = "#{XKSD_250110_80}",
    [1] = "#{XKSD_250110_81}"
}

-- 持有最多 X 个代币
local g_Xiake_Shop_DbBuy_CurMax = {
    [0] = 999999,
    [1] = 999999
}

local g_Xiake_Shop_DbBuy_ExchangeRate = 1
local g_Xiake_Shop_DbBuy_DisplayItemId = 39924916

--===============================================
-- OnLoad()
--===============================================
function Xiake_Shop_DbBuy_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--逻辑相关的事件
    this:RegisterEvent("OPEN_XIA_KE_DB_BUY",true)
    this:RegisterEvent("UPDATE_XIA_KE_SHOP", true)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
    this:RegisterEvent("UI_COMMAND")
    -- this:RegisterEvent("OBJECT_CARED_EVENT",false);
end

function Xiake_Shop_DbBuy_OnLoad()
	g_Xiake_Shop_DbBuy_Frame_UnifiedPosition = Xiake_Shop_DbBuy_Frame:GetProperty("UnifiedPosition")
end 
--===============================================
-- OnEvent()
--===============================================
function Xiake_Shop_DbBuy_OnEvent( event )
    if event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 18204 then
        local defnum = Get_XParam_INT(0)
        Xiake_Shop_DbBuy_InputNumBK:SetProperty("DefaultEditBox", "True")	--设置输入框为默认输入框
        Xiake_Shop_DbBuy_InputNumBK:SetText(tostring(defnum))					--默认输入为1
        Xiake_Shop_DbBuy_InputNumBK:SetSelected(0, -1)

        -- Title
        Xiake_Shop_DbBuy_DragTitle:SetText("#{XKSD_250110_94}")

        -- 数量
        Xiake_Shop_DbBuy_BuyNum_Text:SetText("#{XKSD_250110_96}")
        -- 最大
        Xiake_Shop_DbBuy_Max:SetText("#{XKSD_250110_97}")
        -- 需要勇侠令：XKSD_250110_98
        Xiake_Shop_DbBuy_Price:SetText("#{XKSD_250110_98}")
        -- 拥有勇侠令：XKSD_250110_99
        Xiake_Shop_DbBuy_Cash:SetText("#{XKSD_250110_99}")

        -- 确定
        Xiake_Shop_DbBuy_Submit:SetText("#{XKSD_250110_101}")
        -- 取消
        Xiake_Shop_DbBuy_Cancel:SetText("#{XKSD_250110_102}")
        -- 限购数量
        Xiake_Shop_DbBuy_Item_BuyLimitNumBK:Hide()
        -- 蒙红
        Xiake_Shop_DbBuy_Item_Mask:Hide()
        -- 限购图标
        -- Xiake_Shop_DbBuy_Item_BuyLimit:Hide()
        -- 名称
        Xiake_Shop_DbBuy_ItemInfo_Text:SetText(g_Xiake_Shop_DbBuy_TokenName[0])
        -- 消耗货币 兑换比例
        local str = ScriptGlobal_Format("#{XKSD_250110_19}", g_Xiake_Shop_DbBuy_ExchangeRate)
        Xiake_Shop_DbBuy_ItemInfo_Daibi2:SetText(str)

        Xiake_Shop_DbBuy_FreshWindow()
        this:Show()
    elseif event == "UPDATE_XIA_KE_SHOP" then
        if this:IsVisible() then
            Xiake_Shop_DbBuy_FreshWindow()
        end
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		Xiake_Shop_DbBuy_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Xiake_Shop_DbBuy_Close()
	elseif event == "ADJEST_UI_POS" then
        Xiake_Shop_DbBuy_Frame_On_ResetPos()
    elseif event == "UPDATE_YUANBAO" and this:IsVisible() then
        local yuanbao = Player:GetData("YUANBAO")
        Xiake_Shop_DbBuy_CashNum:SetText(yuanbao)
	end
end

--===============================================
--刷新界面信息
--===============================================
function Xiake_Shop_DbBuy_FreshWindow()
    local info = Lua_GetXiaKeShopData()

    -- Action
    local mActionItem = DataPool:CreateBindActionItemForShow(g_Xiake_Shop_DbBuy_DisplayItemId, 1)
    if mActionItem and mActionItem:GetID() ~= 0 then
        Xiake_Shop_DbBuy_Item:SetActionItem(mActionItem:GetID())
    end

    -- 需要X个勇
    local count = tonumber(Xiake_Shop_DbBuy_InputNumBK:GetText())
    if count then
        local str = ScriptGlobal_Format("#{XKSD_250110_100}", count)
        Xiake_Shop_DbBuy_PriceNum:SetText(str)
    else
        Xiake_Shop_DbBuy_PriceNum:SetText("-")
    end

    -- 拥有X个勇
    local str = ScriptGlobal_Format("#{XKSD_250110_100}", info.mMoney[1])
    Xiake_Shop_DbBuy_CashNum:SetText(str)
end

--===============================================
--取出相应的物资
--===============================================
function Xiake_Shop_DbBuy_OK_Clicked()
    -- 判断，玩家输入数量是否符合规定
	local count = tonumber(Xiake_Shop_DbBuy_InputNumBK:GetText())
    if not count or count <= 0 then
        PushDebugMessage("#{XKSD_250110_41}")
		return
    end

    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("Exchange")				            -- 脚本函数名称
        Set_XSCRIPT_ScriptID(183)										-- 脚本编号 
        Set_XSCRIPT_Parameter(0, count)
        Set_XSCRIPT_ParamCount(1) 	-- 参数个数
    Send_XSCRIPT()
	--隐藏界面
	this:Hide()
end

function Xiake_Shop_DbBuy_GetBuyMaxNum()
    local info = Lua_GetXiaKeShopData()
    local ans = info.mMoney[1]          -- 有多少勇 就能换多少 义
    if info.mMoney[0] + ans > g_Xiake_Shop_DbBuy_CurMax[0] then
        ans = g_Xiake_Shop_DbBuy_CurMax[0] - info.mMoney[0]
    end

    return ans
end

-- 点击最大
function Xiake_Shop_DbBuy_CalMax()
    local maxval = Xiake_Shop_DbBuy_GetBuyMaxNum()
	Xiake_Shop_DbBuy_InputNumBK:SetText(maxval)
end

-- 改变数量
function Xiake_Shop_DbBuy_TextChanged()
    Xiake_Shop_DbBuy_FreshWindow()
end

--===============================================
--关闭界面
--===============================================
function Xiake_Shop_DbBuy_Close()
	this:Hide()
end
function Xiake_Shop_DbBuy_OnHidden()
	this:Hide()
end
function Xiake_Shop_DbBuy_Close_Clicked ()
    this:Hide()
end
function Xiake_Shop_DbBuy_Frame_On_ResetPos()
	Xiake_Shop_DbBuy_Frame:SetProperty("UnifiedPosition", g_Xiake_Shop_DbBuy_Frame_UnifiedPosition)
end
