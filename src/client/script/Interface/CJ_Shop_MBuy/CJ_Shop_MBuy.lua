-- 兑换商店UI

-- 服务器逻辑脚本id
local g_CJ_Shop_MBuy_SvrScriptId = 999336

-- 商店物品最大数量
local g_CJ_Shop_MBuy_ItemIndex = -1

-- 代币物品id
local g_CJ_Shop_MBuy_DaiBiNum = 0

-- 默认位置
local g_CJ_Shop_MBuy_UnifiedPosition = nil
-- 控件表
local g_CJ_Shop_MBuy_CtrlList = nil
-- 代币种类
local g_CJ_Shop_MBuy_CoinType = {
    fst = 1,
    sec = 2,
}
-- 限购类型
local g_CJ_Shop_MBuy_ExchangeType = {
    season = 0,
    day = 1,
    week = 2,
}
-- 获得类型
local g_CJ_Shop_MBuy_BagType = {
    bag = 1,        -- 道具栏
    mat = 2,        -- 材料栏
}
local g_CJ_Shop_MBuy_CareObjSvrId = -1
function CJ_Shop_MBuy_PreLoad()
    this:RegisterEvent("TLCJ_OPENSHOPBUY", true)
    this:RegisterEvent("TLCJ_REFRESHSHOPINFO", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func CJ_Shop_MBuy_PreLoad()

function CJ_Shop_MBuy_OnEvent(event)
    if (event == "TLCJ_OPENSHOPBUY") then
        CJ_Shop_MBuy_Show(arg0, arg1)
    elseif (event == "TLCJ_REFRESHSHOPINFO") then
        CJ_Shop_MBuy_FreshTextUI()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        CJ_Shop_MBuy_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        CJ_Shop_MBuy_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        CJ_Shop_MBuy_UnifiedPos()
	end
end -- end func CJ_Shop_MBuy_OnEvent()

function CJ_Shop_MBuy_OnLoad()
	g_CJ_Shop_MBuy_UnifiedPosition = CJ_Shop_MBuy_Frame:GetProperty("UnifiedPosition")
end -- end func CJ_Shop_MBuy_OnLoad()

-- 界面默认位置
function CJ_Shop_MBuy_UnifiedPos()
	if (g_CJ_Shop_MBuy_UnifiedPosition ~= nil) then
		CJ_Shop_MBuy_Frame:SetProperty("UnifiedPosition", g_CJ_Shop_MBuy_UnifiedPosition)
	end
end -- end func CJ_Shop_MBuy_UnifiedPos()

function CJ_Shop_MBuy_Show(arg0, arg1)
    if IsWindowShow("YuanbaoShop") then
        CloseWindow("YuanbaoShop", true)
    end

    g_CJ_Shop_MBuy_ItemIndex = tonumber(arg0)
    g_CJ_Shop_MBuy_CareObjSvrId = tonumber(arg1)

    --CJ_Shop_MBuy_InputNumBK:SetTextOriginal("1")

    CJ_Shop_MBuy_InputNumBK:SetProperty("DefaultEditBox", "True")
    CJ_Shop_MBuy_InputNumBK:SetTextOriginal("1")
    CJ_Shop_MBuy_InputNumBK:SetSelected(0, -1)

    CJ_Shop_MBuy_UpdateShopItem()
    CJ_Shop_MBuy_FreshTextUI()

    this:Show()

    --OpenWindow("Packet")
end -- end func CJ_Shop_MBuy_Show()

function CJ_Shop_MBuy_Hide()
    g_CJ_Shop_MBuy_ItemIndex = -1

    this:Hide()
end -- end func CJ_Shop_MBuy_Hide()

function CJ_Shop_MBuy_Close_Clicked()
    CJ_Shop_MBuy_Hide()
end -- end func CJ_Shop_MBuy_Close_Clicked()

-- 关闭按钮
function CJ_Shop_MBuy_CloseShop()
    CJ_Shop_MBuy_Hide()
end -- end func CJ_Shop_MBuy_CloseShop()

function CJ_Shop_MBuy_ClearShopItem()
    CJ_Shop_MBuy_Item:SetActionItem(-1)
    CJ_Shop_MBuy_Item_Mask:Hide()
    CJ_Shop_MBuy_Item_WeekLimit:Hide()
    CJ_Shop_MBuy_Item_DayLimit:Hide()
    CJ_Shop_MBuy_Item_ForeverLimit:Hide()
    CJ_Shop_MBuy_ItemInfo_Text:SetText("")
    CJ_Shop_MBuy_ItemInfo_Lilianzhi2:SetText("")
    CJ_Shop_MBuy_Price:SetText("")
    CJ_Shop_MBuy_PriceNum:SetText("")
    CJ_Shop_MBuy_Cash:SetText("")
    CJ_Shop_MBuy_CashNum:SetText("")
    CJ_Shop_MBuy_Item_BuyLimitNum:SetText("")
end

-- 更新兑换物品信息
function CJ_Shop_MBuy_UpdateShopItem()

    CJ_Shop_MBuy_ClearShopItem()

    local shopItemNum = TLCJ:GetShopItemCount()
    local data = TLCJ:GetShopItemInfo(g_CJ_Shop_MBuy_ItemIndex)
    if data ~= nil and type(data) == "table" then
        local itemViewId = data.itemid
        if (data.revealid > 0) then
            itemViewId = data.revealid
        end
        local exchangedNum = TLCJ:GetExchangedNum(data.destindex)
        local leftNum = data.exchangemax - exchangedNum
        if (leftNum < 0) then
            leftNum = 0
        end

        local szLeft = ScriptGlobal_Format("#{TLCJ_20240709_325}", leftNum)
        CJ_Shop_MBuy_Item_BuyLimitNum:SetText(szLeft)

        local theAction = nil
        if data.bind > 0 then
            theAction = DataPool:CreateBindActionItemForShow(itemViewId, 1)
        else
            theAction = DataPool:CreateActionItemForShow(itemViewId, 1)
        end
        
        if theAction:GetID() ~= 0 then
            CJ_Shop_MBuy_Item:SetActionItem(theAction:GetID())
        end

        local itemName = DataPool:Lua_GetItemNameByIndex(itemViewId)
        local szitemName = ScriptGlobal_Format("#{TLCJ_20240709_325}", itemName)
        CJ_Shop_MBuy_ItemInfo_Text:SetText(szitemName)

        if data.cointype == g_CJ_Shop_MBuy_CoinType.fst then
            g_CJ_Shop_MBuy_DaiBiNum = TLCJ:GetShopCoinFst()
            local szNeedNum = ScriptGlobal_Format("#{TLCJ_20240709_325}", data.neednum)
            CJ_Shop_MBuy_ItemInfo_Lilianzhi2:SetText("#{TLCJ_20240709_340}"..szNeedNum)
            CJ_Shop_MBuy_Cash:SetText("#{TLCJ_20240709_341}")
            CJ_Shop_MBuy_Price:SetText("#{TLCJ_20240709_340}")
        elseif data.cointype == g_CJ_Shop_MBuy_CoinType.sec then
            g_CJ_Shop_MBuy_DaiBiNum = TLCJ:GetShopCoinSec()
            local szNeedNum = ScriptGlobal_Format("#{TLCJ_20240709_325}", data.neednum)
            CJ_Shop_MBuy_ItemInfo_Lilianzhi2:SetText("#{TLCJ_20240709_363}"..szNeedNum)
            CJ_Shop_MBuy_Cash:SetText("#{TLCJ_20240709_364}")
            CJ_Shop_MBuy_Price:SetText("#{TLCJ_20240709_363}")
        end

        local szCoinNum = ScriptGlobal_Format("#{TLCJ_20240709_325}", g_CJ_Shop_MBuy_DaiBiNum)
        CJ_Shop_MBuy_CashNum:SetText(szCoinNum)

        if data.exchangetype == g_CJ_Shop_MBuy_ExchangeType.season then
            CJ_Shop_MBuy_Item_ForeverLimit:Show()
        elseif data.exchangetype == g_CJ_Shop_MBuy_ExchangeType.day then
            CJ_Shop_MBuy_Item_DayLimit:Show()
        elseif data.exchangetype == g_CJ_Shop_MBuy_ExchangeType.week then
            CJ_Shop_MBuy_Item_WeekLimit:Show()
        end

    end
end -- end func CJ_Shop_MBuy_UpdateShopItem()

function CJ_Shop_MBuy_FreshTextUI()
    local inputNum = 0
    if CJ_Shop_MBuy_InputNumBK:GetText() ~= '' then
        inputNum = tonumber(CJ_Shop_MBuy_InputNumBK:GetText())
        if inputNum < 0 then
            inputNum = 0
        end
    end

    -- 根据当前值的,计算显示
    local data = TLCJ:GetShopItemInfo(g_CJ_Shop_MBuy_ItemIndex)
    if data ~= nil and type(data) == "table" then
        if data.cointype == g_CJ_Shop_MBuy_CoinType.fst then
            g_CJ_Shop_MBuy_DaiBiNum = TLCJ:GetShopCoinFst()
            CJ_Shop_MBuy_Cash:SetText("#{TLCJ_20240709_341}")
            CJ_Shop_MBuy_Price:SetText("#{TLCJ_20240709_340}")
        elseif data.cointype == g_CJ_Shop_MBuy_CoinType.sec then
            g_CJ_Shop_MBuy_DaiBiNum = TLCJ:GetShopCoinSec()
            CJ_Shop_MBuy_Cash:SetText("#{TLCJ_20240709_364}")
            CJ_Shop_MBuy_Price:SetText("#{TLCJ_20240709_363}")
        end

        local needCoin = inputNum*data.neednum
        local szNeedCoin = ScriptGlobal_Format("#{TLCJ_20240709_325}", needCoin)
        local szOwnCoin = ScriptGlobal_Format("#{TLCJ_20240709_325}", g_CJ_Shop_MBuy_DaiBiNum)
        --CJ_Shop_MBuy_PriceNum:SetText(szNeedCoin)
        --CJ_Shop_MBuy_CashNum:SetText(szOwnCoin)

        if needCoin > g_CJ_Shop_MBuy_DaiBiNum then
            CJ_Shop_MBuy_Submit:Disable()
            CJ_Shop_MBuy_PriceNum:SetText(szNeedCoin)
            CJ_Shop_MBuy_CashNum:SetText("#r"..szOwnCoin)
        else
            CJ_Shop_MBuy_PriceNum:SetText(szNeedCoin)
            CJ_Shop_MBuy_CashNum:SetText(szOwnCoin)
            CJ_Shop_MBuy_Submit:Enable()
        end
    else
        CJ_Shop_MBuy_Cash:SetText("#{TLCJ_20240709_341}")
        CJ_Shop_MBuy_Price:SetText("#{TLCJ_20240709_340}")
        CJ_Shop_MBuy_PriceNum:SetText(0)
        CJ_Shop_MBuy_CashNum:SetText(0)
        CJ_Shop_MBuy_Submit:Disable()
    end
end

function CJ_Shop_MBuy_TextChanged()
    local inputNum = 0
    if CJ_Shop_MBuy_InputNumBK:GetText() ~= '' then
        inputNum = tonumber(CJ_Shop_MBuy_InputNumBK:GetText())
        if inputNum < 0 then
            inputNum = 0
        else
            local data = TLCJ:GetShopItemInfo(g_CJ_Shop_MBuy_ItemIndex)
            if data ~= nil and type(data) == "table" then
                local exchangedNum = TLCJ:GetExchangedNum(data.destindex)
                local leftNum = data.exchangemax - exchangedNum
                if (leftNum <= 0) then
                    inputNum = 0
                else
                    local needNum = data.neednum
                    if needNum <= 0 then
                        inputNum = 0
                    else
                        local canBugCount = math.floor(g_CJ_Shop_MBuy_DaiBiNum/needNum)
                        if canBugCount > leftNum then
                            canBugCount = leftNum
                        end
                        if inputNum > canBugCount then
                            inputNum = canBugCount
                        end
                    end
                end
            end
        end
        -- 重新设置一下，目前输入的值
        CJ_Shop_MBuy_InputNumBK:SetTextOriginal(tostring(inputNum))
    end

    CJ_Shop_MBuy_FreshTextUI()
end

function CJ_Shop_MBuy_CalMax()
    local buyMax = CJ_Shop_MBuy_GetMax()
    CJ_Shop_MBuy_InputNumBK:SetTextOriginal(tostring(buyMax))

    CJ_Shop_MBuy_FreshTextUI()
end

function CJ_Shop_MBuy_GetMax()
    local data = TLCJ:GetShopItemInfo(g_CJ_Shop_MBuy_ItemIndex)
    if data ~= nil and type(data) == "table" then
        local exchangedNum = TLCJ:GetExchangedNum(data.destindex)
        local leftNum = data.exchangemax - exchangedNum
        if (leftNum <= 0) then
            return 0
        end

        if data.cointype == g_CJ_Shop_MBuy_CoinType.fst then
            g_CJ_Shop_MBuy_DaiBiNum = TLCJ:GetShopCoinFst()
        elseif data.cointype == g_CJ_Shop_MBuy_CoinType.sec then
            g_CJ_Shop_MBuy_DaiBiNum = TLCJ:GetShopCoinSec()
        end
        local needNum = data.neednum
        if needNum <= 0 then
            return 0
        end

        local canBugCount = math.floor(g_CJ_Shop_MBuy_DaiBiNum/needNum)
        if canBugCount > leftNum then
            canBugCount = leftNum
        end

        -- 设置可以购买的数量
        return canBugCount
    end

    return 0
end

-- 物品点击按钮事件
function CJ_Shop_MBuy_OK_Clicked()
    local destIndex = g_CJ_Shop_MBuy_ItemIndex
    
    -- 获取商店物品信息
    local data = TLCJ:GetShopItemInfo(destIndex)
    if data == nil or type(data) ~= "table" then
        return
    end

    -- 获取物品已兑换数量
    local exchangedNum = TLCJ:GetExchangedNum(data.destindex)
    if (data.exchangemax <= exchangedNum) then
        -- 可兑换数量为0
        PushDebugMessage("#{TLCJ_20240709_339}")
        return
    end
    
    if data.cointype == g_CJ_Shop_MBuy_CoinType.fst then
        if (g_CJ_Shop_MBuy_DaiBiNum < data.neednum) then
            -- 代币数量不足
            local szTips = ScriptGlobal_Format("#{TLCJ_20240709_342}", "#{TLCJ_20240709_366}")
            PushDebugMessage(szTips)
            return
        end
    elseif data.cointype == g_CJ_Shop_MBuy_CoinType.sec then
        if (g_CJ_Shop_MBuy_DaiBiNum < data.neednum) then
            -- 代币数量不足
            local szTips = ScriptGlobal_Format("#{TLCJ_20240709_342}", "#{TLCJ_20240709_365}")
            PushDebugMessage(szTips)
            return
        end
    end

    local inputNum = 0
    if CJ_Shop_MBuy_InputNumBK:GetText() ~= '' then
        inputNum = tonumber(CJ_Shop_MBuy_InputNumBK:GetText())
        if inputNum < 0 then
            inputNum = 0
        end
    end

    if inputNum <= 0 then
        PushDebugMessage("#{TLCJ_20240709_344}")
        return
    end
        
    Clear_XSCRIPT()
        Set_XSCRIPT_ScriptID(g_CJ_Shop_MBuy_SvrScriptId)
        Set_XSCRIPT_Function_Name("Callback_Exchange")
        Set_XSCRIPT_Parameter(0, g_CJ_Shop_MBuy_CareObjSvrId)
        Set_XSCRIPT_Parameter(1, destIndex)
        Set_XSCRIPT_Parameter(2, inputNum)
        Set_XSCRIPT_ParamCount(3)
    Send_XSCRIPT()

    CJ_Shop_MBuy_CloseShop()
end -- end func CJ_Shop_MBuy_ItemClicked()
