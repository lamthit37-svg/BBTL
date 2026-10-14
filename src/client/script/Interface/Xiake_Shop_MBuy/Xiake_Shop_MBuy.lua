local g_Xiake_Shop_Mbuy_Frame_UnifiedPosition
local g_Xiake_Shop_Mbuy_ShopId
local g_Xiake_Shop_Mbuy_ShopType

local g_Xiake_Shop_LimitPic = {
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Day",                 -- 日
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Week",                -- 周
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever"              -- 永久
}

local g_Xiake_Shop_MBuy_TokenName = {
    [0] = "#{XKSD_250110_80}",
    [1] = "#{XKSD_250110_81}",
    [2] = "#{XKSD_250110_81}"
}

--===============================================
-- OnLoad()
--===============================================
function Xiake_Shop_Mbuy_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--逻辑相关的事件
	this:RegisterEvent("OPEN_XIA_KE_SHOP_MBUY",true)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
    this:RegisterEvent("UI_COMMAND")
	-- this:RegisterEvent("OBJECT_CARED_EVENT",false);
end

function Xiake_Shop_Mbuy_OnLoad()
	g_Xiake_Shop_Mbuy_Frame_UnifiedPosition	=	Xiake_Shop_MBuy_Frame:GetProperty("UnifiedPosition")
end 
--===============================================
-- OnEvent()
--===============================================
function Xiake_Shop_Mbuy_OnEvent( event )
    if event == "OPEN_XIA_KE_SHOP_MBUY" then
        local subtype = tonumber(arg0)
        if subtype == 1 then            -- 非周更
            PushDebugMessage("#{XKSD_250110_33}")
        end
        this:Hide()
        return
    elseif event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 18203 then
        g_Xiake_Shop_Mbuy_ShopId = Get_XParam_INT(0)

        Xiake_Shop_MBuy_InputNumBK:SetProperty("DefaultEditBox", "True")	--设置输入框为默认输入框
        Xiake_Shop_MBuy_InputNumBK:SetText("1")					--默认输入为1
        Xiake_Shop_MBuy_InputNumBK:SetSelected(0, -1)

        -- Title
        Xiake_Shop_MBuy_DragTitle:SetText("#{XKSD_250110_52}")
        -- 数量
        Xiake_Shop_MBuy_BuyNum_Text:SetText("#{XKSD_250110_51}")
        -- 最大
        Xiake_Shop_MBuy_Max:SetText("#{XKSD_250110_53}")
        -- 确定
        Xiake_Shop_MBuy_Submit:SetText("#{XKSD_250110_61}")
        -- 取消
        Xiake_Shop_MBuy_Cancel:SetText("#{XKSD_250110_62}") 

        Xiake_Shop_MBuy_FreshWindow()
        this:Show()
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		Xiake_Shop_MBuy_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Xiake_Shop_MBuy_Close()
	elseif event == "ADJEST_UI_POS" then
		Xiake_Shop_MBuy_Frame_On_ResetPos()
	end
end

--===============================================
--刷新界面信息
--===============================================
function Xiake_Shop_MBuy_FreshWindow()
    local info = Lua_GetXiaKeShopData()
    local conf = Lua_GetXiaKeConfData()
    local limitconf = Lua_GetLimitShopConf()

    local one = nil
    for _, v in ipairs (conf) do
        if v.mID == g_Xiake_Shop_Mbuy_ShopId then
            one = v
            break
        end
    end
    if not one then
        return
    end

    -- Action
    local mActionItem = DataPool:CreateBindActionItemForShow(one.mItemId, one.mItemNum)
    if mActionItem and mActionItem:GetID() ~= 0 then
        Xiake_Shop_MBuy_Item:SetActionItem(mActionItem:GetID())

        -- 道具名称
        local itemname = ScriptGlobal_Format("#{XKSD_250110_47}", mActionItem:GetName())
        Xiake_Shop_MBuy_ItemInfo_Text:SetText (itemname)
    end

    -- 限购
    if one.mLimitBuyId < 0 then
        Xiake_Shop_MBuy_Item_BuyLimit:Hide()
    else
        if limitconf[one.mLimitBuyId] then
            local limittype = limitconf[one.mLimitBuyId].mLimitType
            if g_Xiake_Shop_LimitPic[limittype] then
                Xiake_Shop_MBuy_Item_BuyLimit:SetProperty("Image", g_Xiake_Shop_LimitPic[limittype])
                Xiake_Shop_MBuy_Item_BuyLimit:Show()
            else
                Xiake_Shop_MBuy_Item_BuyLimit:Hide()
            end
        else
            Xiake_Shop_MBuy_Item_BuyLimit:Hide()
        end
    end

    -- 限购数量
    local reamain = Lua_GetXiaKeShopItemLimitNum(one.mLimitBuyId)
    if reamain >= 0 then
        Xiake_Shop_MBuy_Item_BuyLimitNum:SetText(tostring (reamain))
        Xiake_Shop_MBuy_Item_BuyLimitNum:Show()
    else
        Xiake_Shop_MBuy_Item_BuyLimitNum:Hide()
    end

    local count = tonumber(Xiake_Shop_MBuy_InputNumBK:GetText())
    if one.mPriceType == 0 then
        -- 价格
        local strPrice = ScriptGlobal_Format("#{XKSD_250110_48}", one.mPriceNum)
        Xiake_Shop_MBuy_ItemInfo_Daibi2:SetText(strPrice)

        -- 需要代币 类型文字
        Xiake_Shop_MBuy_Price:SetText("#{XKSD_250110_54}")

        -- 拥有代币 类型文字
        Xiake_Shop_MBuy_Cash:SetText("#{XKSD_250110_57}")
        
        -- 拥有代币 数量
        local strCurMoney = ScriptGlobal_Format("#{XKSD_250110_60}", info.mMoney[0])
        Xiake_Shop_MBuy_CashNum:SetText(strCurMoney)
    elseif one.mPriceType == 1 then
        -- 价格
        local str = ScriptGlobal_Format("#{XKSD_250110_49}", one.mPriceNum)
        Xiake_Shop_MBuy_ItemInfo_Daibi2:SetText(str)

        -- 需要代币 类型文字
        Xiake_Shop_MBuy_Price:SetText("#{XKSD_250110_55}")

        -- 拥有代币 类型文字
        Xiake_Shop_MBuy_Cash:SetText("#{XKSD_250110_58}")

        -- 拥有代币 数量
        local strCurMoney = ScriptGlobal_Format("#{XKSD_250110_60}", info.mMoney[1])
        Xiake_Shop_MBuy_CashNum:SetText(strCurMoney)
    elseif one.mPriceType == 2 then
        -- 价格
        local str = ScriptGlobal_Format("#{XKSD_250110_134}", one.mPriceNum)
        Xiake_Shop_MBuy_ItemInfo_Daibi2:SetText(str)

        -- 需要代币 类型文字
        Xiake_Shop_MBuy_Price:SetText("#{XKSD_250110_135}")

        -- 拥有代币 类型文字
        Xiake_Shop_MBuy_Cash:SetText("#{XKSD_250110_136}")

        -- 拥有代币 数量
        local strCurMoney = ScriptGlobal_Format("#{XKSD_250110_60}", info.mMoney[2])
        Xiake_Shop_MBuy_CashNum:SetText(strCurMoney)
    else
        Xiake_Shop_MBuy_ItemInfo_Daibi2:Hide()
    end

    -- 所需代币 数量
    if count then
        local strPrice = ScriptGlobal_Format("#{XKSD_250110_60}", one.mPriceNum * count)
        Xiake_Shop_MBuy_PriceNum:SetText(strPrice)
    else
        local strPrice = ScriptGlobal_Format("#{XKSD_250110_60}", "-")
        Xiake_Shop_MBuy_PriceNum:SetText(strPrice)
    end

    Xiake_Shop_MBuy_Item_Mask:Hide()
end

--===============================================
--取出相应的物资
--===============================================
function Xiake_Shop_MBuy_OK_Clicked()
    -- 判断，玩家输入数量是否符合规定
	local count = tonumber(Xiake_Shop_MBuy_InputNumBK:GetText())
    if count <= 0 then
        PushDebugMessage("#{XKSD_250110_41}")
		return
    end

    -- local info = Lua_GetXiaKeShopData()
    -- local conf = Lua_GetXiaKeConfData()

    -- for _, one in ipairs (conf) do
    --     if one.mID == g_Xiake_Shop_Mbuy_ShopId then

    --     end
    -- end

    -- local one = conf[g_Xiake_Shop_Mbuy_ShopId]
    -- local products = info.mProducts[g_Xiake_Shop_Mbuy_ShopType]
    -- for _, product in pairs (products) do
    --     if product.mProductId == g_Xiake_Shop_Mbuy_ShopId then
    --         if info.mCurMoney[one.MoneyType] * count < product.mMoney then
    --             local str = ScriptGlobal_Format("#{XKSD_250110_37}", g_Xiake_Shop_MBuy_TokenName[one.MoneyType])
    --             PushDebugMessage(str)
    --             return
    --         end
    --         break
    --     end
    -- end

    -- -- 判断，玩家输入数量是否符合规定
    -- local maxcount = Xiake_Shop_MBuy_GetBuyMaxNum()
    -- if count > maxcount then
    --     PushDebugMessage("#{XKSD_250110_41}")
	-- 	return
    -- end

    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("Buy") 					            -- 脚本函数名称
        Set_XSCRIPT_ScriptID(183)										-- 脚本编号 
        Set_XSCRIPT_Parameter(0, g_Xiake_Shop_Mbuy_ShopId)
        Set_XSCRIPT_Parameter(1, count)
        Set_XSCRIPT_ParamCount(2) 	-- 参数个数
    Send_XSCRIPT()
	--隐藏界面
	this:Hide()
end

function Xiake_Shop_MBuy_GetBuyMaxNum()
    local conf = Lua_GetXiaKeConfData()
    for _, one in ipairs (conf) do
        if one.mID == g_Xiake_Shop_Mbuy_ShopId then
            local cmoney = Lua_GetXiaKeShopMoney(one.mPriceType)
            local ans = math.floor(cmoney / one.mPriceNum)
            if one.mLimitBuyId >= 0 then
                local remain = Lua_GetXiaKeShopItemLimitNum(one.mLimitBuyId)
                if remain < ans then
                    ans = remain
                end 
            end

            return ans
        end
    end
    return 0
end

-- 点击最大
function Xiake_Shop_MBuy_CalMax()
    local maxval = Xiake_Shop_MBuy_GetBuyMaxNum()
    Xiake_Shop_MBuy_InputNumBK:SetText(maxval)
    -- Xiake_Shop_MBuy_FreshWindow()
end

-- 改变数量
function Xiake_Shop_MBuy_TextChanged()
    -- local count = tonumber(Xiake_Shop_MBuy_InputNumBK:GetText())
    -- local maxval = Xiake_Shop_MBuy_GetBuyMaxNum()
    -- if count <= 0 then
    --     Xiake_Shop_MBuy_InputNumBK:SetText(1)
    -- elseif count > maxval then
    --     Xiake_Shop_MBuy_InputNumBK:SetText(maxval)
    -- end
    Xiake_Shop_MBuy_FreshWindow()
end

--===============================================
--关闭界面
--===============================================
function Xiake_Shop_MBuy_Close()
	this:Hide()
end
function Xiake_Shop_MBuy_Close_Clicked()
	this:Hide()
end
function Xiake_Shop_MBuy_Frame_On_ResetPos()
	Xiake_Shop_MBuy_Frame:SetProperty("UnifiedPosition", g_Xiake_Shop_Mbuy_Frame_UnifiedPosition)
end
