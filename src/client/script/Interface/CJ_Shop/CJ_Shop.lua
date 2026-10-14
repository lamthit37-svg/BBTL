-- 兑换商店UI

-- 服务器逻辑脚本id
local g_CJ_Shop_SvrScriptId = 999270
-- 商店物品最大数量
local g_CJ_Shop_ItemNum = 15
local g_CJ_Shop_MaxItemNum = 30
-- 代币物品id
local g_CJ_Shop_DaiBiNum = 0
local g_CJ_Shop_DaiBi2Num = 0
-- 当前分页
local g_CJ_Shop_Page = 1
local g_CJ_Shop_PageMax = 1
local g_CJ_Shop_PageMax_Limit = 2
-- 目标NPCID
local g_CJ_Shop_TargetNPC = -1
-- 关注NPC
local g_CJ_Shop_CareObjId = -1
local g_CJ_Shop_CareObjSvrId = -1

-- 默认位置
local g_CJ_Shop_UnifiedPosition = nil
-- 控件表
local g_CJ_Shop_CtrlList = nil
-- 代币种类
local g_CJ_Shop_CoinType = {
    fst = 1,
    sec = 2,
}
-- 限购类型
local g_CJ_Shop_ExchangeType = {
    season = 0,
    day = 1,
    week = 2,
}
-- 获得类型
local g_CJ_Shop_BagType = {
    bag = 1,        -- 道具栏
    mat = 2,        -- 材料栏
}

local g_CJ_Shop_Level = 60

function CJ_Shop_PreLoad()
    this:RegisterEvent("TLCJ_OPENSHOP", true)
    this:RegisterEvent("TLCJ_REFRESHSHOPINFO", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func CJ_Shop_PreLoad()

function CJ_Shop_OnEvent(event)
    if (event == "TLCJ_OPENSHOP") then
        CJ_Shop_UpdateShopItem()

        if (not this:IsVisible()) then
            CJ_Shop_BeginCareObject(arg0, arg1)

            CJ_Shop_Show()
        end
    elseif (event == "TLCJ_REFRESHSHOPINFO") then
        CJ_Shop_UpdateShopItem()
    elseif (event == "HIDE_ON_SCENE_TRANSED") then
        CJ_Shop_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        CJ_Shop_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        CJ_Shop_UnifiedPos()
	end
end -- end func CJ_Shop_OnEvent()

function CJ_Shop_OnLoad()
	g_CJ_Shop_UnifiedPosition = CJ_Shop_Frame:GetProperty("UnifiedPosition")
	CJ_Shop_InitCtrlList()
end -- end func CJ_Shop_OnLoad()

-- 界面默认位置
function CJ_Shop_UnifiedPos()
	if (g_CJ_Shop_UnifiedPosition ~= nil) then
		CJ_Shop_Frame:SetProperty("UnifiedPosition", g_CJ_Shop_UnifiedPosition)
	end
end -- end func CJ_Shop_UnifiedPos()

-- 开启NPC关注
function CJ_Shop_BeginCareObject(objSvrId, objId)
	g_CJ_Shop_CareObjId = tonumber(objId)
    if (g_CJ_Shop_CareObjId >= 0) then
        g_CJ_Shop_CareObjSvrId = tonumber(objSvrId)
        g_CJ_Shop_TargetNPC = tonumber(objSvrId)
		this:CareObject(g_CJ_Shop_CareObjId, 1, "CJ_Shop")
	end
end -- end func CJ_Shop_BeginCareObject()

-- 取消NPC关注
function CJ_Shop_StopCareObject()
	if (g_CJ_Shop_CareObjId >= 0) then
		this:CareObject(g_CJ_Shop_CareObjId, 0, "CJ_Shop")
		g_CJ_Shop_CareObjId = -1
		g_CJ_Shop_CareObjSvrId = -1
	end
end -- end func CJ_Shop_StopCareObject()

-- 控件列表
function CJ_Shop_InitCtrlList()
    if (g_CJ_Shop_CtrlList ~= nil) then
        g_CJ_Shop_CtrlList = {}
    end

    local _prefix_l = "CJ_Shop_"
    local makeGroup = function(prefix,item,name,price,coinfst,coinsec,bg,left,day,week,forever, leftbg)
        local _fix = _prefix_l..item
        return {
            ["item"] = _G[prefix..item],
            ["name"] = _G[_fix..name],
            ["price"] = _G[_fix..price],
            ["coinfst"] = _G[_fix..coinfst],
            ["coinsec"] = _G[_fix..coinsec],
            ["bg"] = _G[_fix..bg],
            ["left"] = _G[_fix..left],
            ["day"] = _G[_fix..day],
            ["week"] = _G[_fix..week],
            ["forever"] = _G[_fix..forever],
            ["leftbg"] = _G[_fix..leftbg],
		}
    end
    
    g_CJ_Shop_CtrlList.item = {}
    g_CJ_Shop_CtrlList.item = {
        makeGroup(_prefix_l, "Item1", "Text", "Info_CostNum", "Info_CostyIcon", "Info_CostyIcon2", "Info", "_BuyLimitNum", "Info_DayLimit", "Info_WeekLimit", "Info_ForeverLimit", "_BuyLimitNumBK"),
        makeGroup(_prefix_l, "Item2", "Text", "Info_CostNum", "Info_CostyIcon", "Info_CostyIcon2", "Info", "_BuyLimitNum", "Info_DayLimit", "Info_WeekLimit", "Info_ForeverLimit", "_BuyLimitNumBK"),
        makeGroup(_prefix_l, "Item3", "Text", "Info_CostNum", "Info_CostyIcon", "Info_CostyIcon2", "Info", "_BuyLimitNum", "Info_DayLimit", "Info_WeekLimit", "Info_ForeverLimit", "_BuyLimitNumBK"),
        makeGroup(_prefix_l, "Item4", "Text", "Info_CostNum", "Info_CostyIcon", "Info_CostyIcon2", "Info", "_BuyLimitNum", "Info_DayLimit", "Info_WeekLimit", "Info_ForeverLimit", "_BuyLimitNumBK"),
        makeGroup(_prefix_l, "Item5", "Text", "Info_CostNum", "Info_CostyIcon", "Info_CostyIcon2", "Info", "_BuyLimitNum", "Info_DayLimit", "Info_WeekLimit", "Info_ForeverLimit", "_BuyLimitNumBK"),
        makeGroup(_prefix_l, "Item6", "Text", "Info_CostNum", "Info_CostyIcon", "Info_CostyIcon2", "Info", "_BuyLimitNum", "Info_DayLimit", "Info_WeekLimit", "Info_ForeverLimit", "_BuyLimitNumBK"),
        makeGroup(_prefix_l, "Item7", "Text", "Info_CostNum", "Info_CostyIcon", "Info_CostyIcon2", "Info", "_BuyLimitNum", "Info_DayLimit", "Info_WeekLimit", "Info_ForeverLimit", "_BuyLimitNumBK"),
        makeGroup(_prefix_l, "Item8", "Text", "Info_CostNum", "Info_CostyIcon", "Info_CostyIcon2", "Info", "_BuyLimitNum", "Info_DayLimit", "Info_WeekLimit", "Info_ForeverLimit", "_BuyLimitNumBK"),
        makeGroup(_prefix_l, "Item9", "Text", "Info_CostNum", "Info_CostyIcon", "Info_CostyIcon2", "Info", "_BuyLimitNum", "Info_DayLimit", "Info_WeekLimit", "Info_ForeverLimit", "_BuyLimitNumBK"),
        makeGroup(_prefix_l, "Item10", "Text", "Info_CostNum", "Info_CostyIcon", "Info_CostyIcon2", "Info", "_BuyLimitNum", "Info_DayLimit", "Info_WeekLimit", "Info_ForeverLimit", "_BuyLimitNumBK"),
        makeGroup(_prefix_l, "Item11", "Text", "Info_CostNum", "Info_CostyIcon", "Info_CostyIcon2", "Info", "_BuyLimitNum", "Info_DayLimit", "Info_WeekLimit", "Info_ForeverLimit", "_BuyLimitNumBK"),
        makeGroup(_prefix_l, "Item12", "Text", "Info_CostNum", "Info_CostyIcon", "Info_CostyIcon2", "Info", "_BuyLimitNum", "Info_DayLimit", "Info_WeekLimit", "Info_ForeverLimit", "_BuyLimitNumBK"),
        makeGroup(_prefix_l, "Item13", "Text", "Info_CostNum", "Info_CostyIcon", "Info_CostyIcon2", "Info", "_BuyLimitNum", "Info_DayLimit", "Info_WeekLimit", "Info_ForeverLimit", "_BuyLimitNumBK"),
        makeGroup(_prefix_l, "Item14", "Text", "Info_CostNum", "Info_CostyIcon", "Info_CostyIcon2", "Info", "_BuyLimitNum", "Info_DayLimit", "Info_WeekLimit", "Info_ForeverLimit", "_BuyLimitNumBK"),
        makeGroup(_prefix_l, "Item15", "Text", "Info_CostNum", "Info_CostyIcon", "Info_CostyIcon2", "Info", "_BuyLimitNum", "Info_DayLimit", "Info_WeekLimit", "Info_ForeverLimit", "_BuyLimitNumBK"),
    }
    
end -- end func CJ_Shop_InitCtrlList()

function CJ_Shop_Show()
    if IsWindowShow("YuanbaoShop") then
        CloseWindow("YuanbaoShop", true)
    end

    this:Show()

    OpenWindow("Packet")
end -- end func CJ_Shop_Show()

function CJ_Shop_Hidden()
    g_CJ_Shop_Page = 1
    g_CJ_Shop_PageMax = 1

    CJ_Shop_StopCareObject()

    -- 关闭二级界面
    if IsWindowShow("CJ_Shop_MBuy") then
        CloseWindow("CJ_Shop_MBuy", true)
    end
end -- end func CJ_Shop_Hide()

function CJ_Shop_Hide()
    CJ_Shop_Hidden()
    this:Hide()
end -- end func CJ_Shop_Hide()

-- 关闭按钮
function CJ_Shop_CloseShop()
    CJ_Shop_Hidden()
    this:Hide()
end -- end func CJ_Shop_CloseShop()

function CJ_Shop_ClearShopItem()
    for _, ui in (g_CJ_Shop_CtrlList.item or {}) do
        if ui.item ~= nil then
            ui.item:SetActionItem(-1)
        end
        if ui.left ~= nil then
            ui.left:SetText("")
        end
        if ui.name ~= nil then
            ui.name:SetText("")
        end
        if ui.price ~= nil then
            ui.price:SetText("")
        end
        if ui.coinfst ~= nil then
            ui.coinfst:Hide()
        end
        if ui.coinsec ~= nil then
            ui.coinsec:Hide()
        end
        if ui.day ~= nil then
            ui.day:Hide()
        end
        if ui.week ~= nil then
            ui.week:Hide()
        end
        if ui.forever ~= nil then
            ui.forever:Hide()
        end
        if ui.leftbg ~= nil then
            ui.leftbg:Hide()
        end
        if ui.bg ~= nil then
            ui.bg:Hide()
        end
    end
end

-- 更新兑换物品信息
function CJ_Shop_UpdateShopItem()
    if (g_CJ_Shop_CtrlList == nil or g_CJ_Shop_CtrlList.item == nil) then
        CJ_Shop_InitCtrlList()
    end

    CJ_Shop_ClearShopItem()


    g_CJ_Shop_DaiBiNum = TLCJ:GetShopCoinFst()
    g_CJ_Shop_DaiBi2Num = TLCJ:GetShopCoinSec()

    local daibiNumText = ScriptGlobal_Format("#{TLCJ_20240709_368}", g_CJ_Shop_DaiBiNum)
    CJ_Shop_Currency1:SetText(daibiNumText)
    local daibiNumText2 = ScriptGlobal_Format("#{TLCJ_20240709_370}", g_CJ_Shop_DaiBi2Num)
    CJ_Shop_Currency2:SetText(daibiNumText2)

    --PushDebugMessage(daibiNumText)
    --PushDebugMessage(daibiNumText2)

    local shopItemNum = TLCJ:GetShopItemCount()
    local beginIndex, endIndex = 1, shopItemNum
    if (shopItemNum <= 0) then
        return
    elseif (shopItemNum > g_CJ_Shop_ItemNum) then
        -- 多页
        beginIndex = (g_CJ_Shop_Page - 1)*g_CJ_Shop_ItemNum + 1
        if g_CJ_Shop_Page > 1 and g_CJ_Shop_Page < g_CJ_Shop_PageMax_Limit then
            -- 中间页
            endIndex = g_CJ_Shop_Page*g_CJ_Shop_ItemNum
        elseif g_CJ_Shop_Page == g_CJ_Shop_PageMax_Limit then
            -- 尾页
            endIndex = shopItemNum
        else
            -- 首页
            endIndex = g_CJ_Shop_ItemNum
        end
        g_CJ_Shop_PageMax = g_CJ_Shop_PageMax_Limit
    else
        endIndex = shopItemNum
    end
    
    CJ_Shop_UpPage:Enable()
    CJ_Shop_DownPage:Enable()
    if g_CJ_Shop_Page <= 1 then
        CJ_Shop_UpPage:Disable()
    end
    if g_CJ_Shop_Page >= g_CJ_Shop_PageMax then
        CJ_Shop_DownPage:Disable()
    end

    local szPage = ScriptGlobal_Format("#{FMSD_220705_24}", g_CJ_Shop_Page, g_CJ_Shop_PageMax)
    CJ_Shop_CurrentlyPage:SetText(szPage)

    local uiIndex = 1
    for i=beginIndex, endIndex, 1 do
        -- 获取商店物品信息        
        local data = TLCJ:GetShopItemInfo(i-1)
        if data ~= nil and type(data) == "table" then
            local itemCtrl = g_CJ_Shop_CtrlList.item[uiIndex]
            if (itemCtrl ~= nil) then
                local itemViewId = data.itemid
                if (data.revealid > 0) then
                    itemViewId = data.revealid
                end
                local exchangedNum = TLCJ:GetExchangedNum(data.destindex)
                local leftNum = data.exchangemax - exchangedNum
                if (leftNum < 0) then
                    leftNum = 0
                end

                itemCtrl.item:Enable()
                itemCtrl.item:SetProperty("Gloom", "false")

                local szLeft = ScriptGlobal_Format("#{TLCJ_20240709_325}", leftNum)
                itemCtrl.left:SetText(szLeft)

                local theAction = nil
                if data.bind > 0 then
                    --theAction = DataPool:CreateBindActionItemForShowWithMaxNum(itemViewId, data.exchangenum, leftNum)
                    theAction = DataPool:CreateBindActionItemForShow(itemViewId, 1)
                else
                    --theAction = DataPool:CreateActionItemForShowWithMaxNum(itemViewId, data.exchangenum, leftNum)
                    theAction = DataPool:CreateActionItemForShow(itemViewId, 1)
                end
                if theAction:GetID() ~= 0 then
                    itemCtrl.item:SetActionItem(theAction:GetID())
                end

                if (leftNum <= 0) then
                    itemCtrl.item:SetProperty("Gloom", "true")
                    itemCtrl.item:Disable()
                end

                local itemName = DataPool:Lua_GetItemNameByIndex(itemViewId)
                local szitemName = ScriptGlobal_Format("#{TLCJ_20240709_320}", itemName)
                itemCtrl.name:SetText(szitemName)

                local szNeedNum = ScriptGlobal_Format("#{TLCJ_20240709_325}", data.neednum)
                itemCtrl.price:SetText(szNeedNum)

                if data.cointype == g_CJ_Shop_CoinType.fst then
                    if itemCtrl.coinfst ~= nil then
                        itemCtrl.coinfst:Show()
                    end
                elseif data.cointype == g_CJ_Shop_CoinType.sec then
                    if itemCtrl.coinsec ~= nil then
                        itemCtrl.coinsec:Show()
                    end
                end

                if data.exchangetype == g_CJ_Shop_ExchangeType.season then
                    if itemCtrl.forever ~= nil then
                        itemCtrl.forever:Show()
                    end
                elseif data.exchangetype == g_CJ_Shop_ExchangeType.day then
                    if itemCtrl.day ~= nil then
                        itemCtrl.day:Show()
                    end
                elseif data.exchangetype == g_CJ_Shop_ExchangeType.week then
                    if itemCtrl.week ~= nil then
                        itemCtrl.week:Show()
                    end
                end

                if itemCtrl.leftbg ~= nil then
                    itemCtrl.leftbg:Show()
                end

                if itemCtrl.bg ~= nil then
                    itemCtrl.bg:Show()
                end
            end

            uiIndex = uiIndex + 1
        end
    end -- end for
end -- end func CJ_Shop_UpdateShopItem()


-- 物品点击按钮事件
function CJ_Shop_Clicked(arg)
    local playerLevel = Player:GetLevel()
    if playerLevel < g_CJ_Shop_Level  then        
        PushDebugMessage("#{TLCJ_20240709_14}")
        return
    end

    -- 判断是否为安全时间
    if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
        PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
        return
    end

    -- 判断电话密保和二级密码保护
    if CheckPhoneMibaoAndMinorPassword() ~= 1 then
        return
    end

    local itemIndex = tonumber(arg) - 1
    if (itemIndex < 0) then
        return
    end

    local shopItemMax = TLCJ:GetShopItemCount()
    if (itemIndex >= shopItemMax) then
        return
    end

    local destIndex = (g_CJ_Shop_Page - 1)*g_CJ_Shop_ItemNum + itemIndex
    if (destIndex >= shopItemMax) then
        return
    end
    
    -- 获取商店物品信息
    local data = TLCJ:GetShopItemInfo(destIndex)
    if data == nil or type(data) ~= "table" then
        return
    end

    -- 获取物品已兑换数量
    local exchangedNum = TLCJ:GetExchangedNum(destIndex)
    if (data.exchangemax <= exchangedNum) then
        -- 可兑换数量为0
        PushDebugMessage("#{TLCJ_20240709_339}")
        return
    end
    
    g_CJ_Shop_DaiBiNum = TLCJ:GetShopCoinFst()
    g_CJ_Shop_DaiBi2Num = TLCJ:GetShopCoinSec()

    if data.cointype == g_CJ_Shop_CoinType.fst then
        if (g_CJ_Shop_DaiBiNum < data.neednum) then
            -- 代币数量不足
            local szTips = ScriptGlobal_Format("#{TLCJ_20240709_342}", "#{TLCJ_20240709_366}")
            PushDebugMessage(szTips)
            return
        end
    elseif data.cointype == g_CJ_Shop_CoinType.sec then
        if (g_CJ_Shop_DaiBi2Num < data.neednum) then
            -- 代币数量不足
            local szTips = ScriptGlobal_Format("#{TLCJ_20240709_342}", "#{TLCJ_20240709_365}")
            PushDebugMessage(szTips)
            return
        end
    end

    
    PushEvent("TLCJ_OPENSHOPBUY", destIndex, g_CJ_Shop_CareObjSvrId)
end -- end func CJ_Shop_ItemClicked()

function CJ_Shop_PageUp()
    g_CJ_Shop_Page = g_CJ_Shop_Page - 1
    if g_CJ_Shop_Page <= 1 then
        g_CJ_Shop_Page = 1 
    end
    CJ_Shop_UpdateShopItem()

    if IsWindowShow("CJ_Shop_MBuy") then
        CloseWindow("CJ_Shop_MBuy", true)
    end
end -- end func CJ_Shop_PageUp()


function CJ_Shop_PageDown()
    g_CJ_Shop_Page = g_CJ_Shop_Page + 1
    if g_CJ_Shop_Page >= g_CJ_Shop_PageMax then
        g_CJ_Shop_Page = g_CJ_Shop_PageMax
    end

    CJ_Shop_UpdateShopItem()

    if IsWindowShow("CJ_Shop_MBuy") then
        CloseWindow("CJ_Shop_MBuy", true)
    end
end -- end func CJ_Shop_PageDown()
