-- 藏品商店
-- 代币 Id
local g_WuShenTan_Guide_Shop_TokensId = 3485
local g_WuShenTan_Guide_Shop_WeekLimId = 3519
-- UI 位置
local g_WuShenTan_Guide_Shop_UnifiedPosition
-- 角标资源
local g_WuShenTan_Guide_Shop_Corner = {
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Day",                 -- 日
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Week",                -- 周
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever"              -- 永久
}

-- token 数量
local g_WuShenTan_Guide_Shop_TokenTx
-- view list
local g_WuShenTan_Guide_Shop_ViewList
-- 排名
local g_WuShenTan_Guide_Shop_RankLevel = 0

function WuShenTan_Guide_Shop_PreLoad()
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--进场景关闭界面
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("OBJECT_CARED_EVENT",false)
    this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("WUSHENTAN_SHOP")
end

function WuShenTan_Guide_Shop_OnLoad()
    g_WuShenTan_Guide_Shop_UnifiedPosition = WuShenTan_Guide_Shop_Frame:GetProperty("UnifiedPosition")

    g_WuShenTan_Guide_Shop_TokenTx = WuShenTan_Guide_ShopInfo_HaveDBNum
    g_WuShenTan_Guide_Shop_ViewList = WuShenTan_Guide_Shop_List
end

--=========
-- Event
--=========
---   !!!reloadscript =WuShenTan_Guide_Shop
function WuShenTan_Guide_Shop_OnEvent(event) 
    if event == "WUSHENTAN_SHOP" then
        g_WuShenTan_Guide_Shop_RankLevel = tonumber (arg0)
        WuShenTan_Guide_Shop_Update ()
        this:Show ()
    elseif event == "UI_COMMAND" and arg0 and tonumber (arg0) == 89365101 then
        if this:IsVisible() then
            local limitId = Get_XParam_INT(0)
            local limitVal = Get_XParam_INT(1)

            if limitId and limitVal and limitId >= 0 and limitVal >= 0 then
                DataPool:Lua_ChangWuShenTanLimitData (limitId, limitVal)
                WuShenTan_Guide_Shop_Update ()
            else
                WuShenTan_Guide_Shop_UpdateToken ()
            end
        end
    elseif event == "VIEW_RESOLUTION_CHANGED" then
        WuShenTan_Guide_Shop_On_ResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
        WuShenTan_Guide_Shop_Close()
    elseif event == "ADJEST_UI_POS" then
        WuShenTan_Guide_Shop_On_ResetPos()
    elseif event == "OBJECT_CARED_EVENT" then
        if tonumber(arg0) ~= g_WuShenTan_Guide_Shop_objcare then
            return
        end
        --如果和NPC的距离大于一定距离或者被删除，自动关闭
        if arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1 == "destroy" then
            this:Hide()
            --取消关心
            this:CareObject(g_WuShenTan_Guide_Shop_objcare, 0, "WuShenTan_Guide_Shop")
        end
    end
end
 
--=========
-- 重置
--=========
function WuShenTan_Guide_Shop_On_ResetPos()
    WuShenTan_Guide_Shop_Frame:SetProperty("UnifiedPosition", g_WuShenTan_Guide_Shop_UnifiedPosition)
end

-- -- 关闭界面的时候会调用这个接口
-- function WuShenTan_Guide_Shop_OnHidden ()
--     if IsWindowShow ("WuShenTan_Guide_Shop_BatchBuy") then
--         CloseWindow ("WuShenTan_Guide_Shop_BatchBuy", true)
--     end
-- end

--=========
-- 关闭
--=========
function WuShenTan_Guide_Shop_Close()
    this:Hide()
end

--=========
-- 更新界面数据
--=========
function WuShenTan_Guide_Shop_Update ()
    local conf = DataPool:Lua_GetWuShenTanShopTable ()
    g_WuShenTan_Guide_Shop_ViewList:Clear ()
    for i, one in ipairs (conf or {}) do
        local bar = g_WuShenTan_Guide_Shop_ViewList:AddChild ("WuShenTan_Guide_ShopFrame")
        if not bar then
            break
        end

        -- action button
        local mActionItem = DataPool:CreateBindActionItemForShow(one.mItemId, one.mItemNum)
        if mActionItem and mActionItem:GetID () ~= 0 then
            local actionbutton = bar:GetSubItem ("WuShenTan_Guide_Shop")
            actionbutton:SetActionItem (mActionItem:GetID())
            -- actionbutton:SetEvent("Clicked", string.format("Assist_Shop_Buy(%d)", one.mId))

            -- Item Name
            local name = mActionItem:GetName()
            local strname = ScriptGlobal_Format ("#{WSZH_260408_87}", name)
            bar:GetSubItem ("WuShenTan_Guide_ShopText"):SetText (strname)
        end

        -- item cost
        local cost = ScriptGlobal_Format ("#{WSZH_260408_22}", one.mCost)
        bar:GetSubItem ("WuShenTan_Guide_ShopInfo_CostNumText"):SetText (cost)

        local vis = true

        -- limit num & mask
        if one.mLimitId >= 0 then
            local _1, limittype, _2, nummax = DataPool:lua_GetLimitShopConfOne (one.mLimitId)
            if nummax then
                local remain = nummax - one.mPurchased
                vis = remain > 0
                -- bar:GetSubItem ("Assist_Shop_ItemInfo_IconMark"):SetProperty ("Image", g_WuShenTan_Guide_Shop_Corner[limittype])
                bar:GetSubItem ("WuShenTan_Guide_Shop_BuyLimitNumBK"):Show()
                if remain <= 0 then
                    bar:GetSubItem ("WuShenTan_Guide_Shop_BuyLimitNum"):SetText("#{WSZH_260408_24}")
                    bar:GetSubItem ("WuShenTan_Guide_Shop_BuyBtn"):SetText ("#{WSZH_260408_86}")
                else
                    local str = ScriptGlobal_Format ("#{WSZH_260408_23}", remain)
                    bar:GetSubItem ("WuShenTan_Guide_Shop_BuyLimitNum"):SetText(str)
                    bar:GetSubItem ("WuShenTan_Guide_Shop_BuyBtn"):SetText ("#{WSZH_260408_25}")
                end
            else
                vis = true
                bar:GetSubItem ("WuShenTan_Guide_Shop_BuyLimitNumBK"):Hide()
            end
        else
            vis = true
            bar:GetSubItem ("WuShenTan_Guide_Shop_BuyLimitNumBK"):Hide()
        end

        -- 冠军商品
        if one.mViewRule > 0 then
            bar:GetSubItem ("WuShenTan_Guide_Shop_LimitBK"):Show ()
            bar:GetSubItem ("WuShenTan_Guide_Shop_LimitText"):SetText ("#{WSZH_260408_88}")
            if vis and (g_WuShenTan_Guide_Shop_RankLevel == 0 or one.mViewRule < g_WuShenTan_Guide_Shop_RankLevel) then
                vis = false
            end
        else
            bar:GetSubItem ("WuShenTan_Guide_Shop_LimitBK"):Hide ()
        end

        -- 是否可以购买
        if vis then
            bar:GetSubItem ("WuShenTan_Guide_Shop_Mask"):Hide()
            bar:GetSubItem ("WuShenTan_Guide_Shop_BuyBtn"):Enable ()
        else
            bar:GetSubItem ("WuShenTan_Guide_Shop_Mask"):Show()
            bar:GetSubItem ("WuShenTan_Guide_Shop_BuyBtn"):Disable ()
        end

        -- buy event
        bar:GetSubItem ("WuShenTan_Guide_Shop_BuyBtn"):SetEvent("Clicked", string.format("WuShenTan_Guide_Shop_Buy(%d)", one.mId))
    end

    -- 更新当前 token 信息
    WuShenTan_Guide_Shop_UpdateToken ()
end

-- 更新货币数量
function WuShenTan_Guide_Shop_UpdateToken ()
    local token = Lua_GetMissionData(g_WuShenTan_Guide_Shop_TokensId)
    local content = ScriptGlobal_Format ("#{WSZH_260408_21}", token)
    g_WuShenTan_Guide_Shop_TokenTx:SetText (content)

    local weekLim = Lua_GetMissionData(g_WuShenTan_Guide_Shop_WeekLimId)
    local wlimContent = ScriptGlobal_Format ("#{WSZH_260408_156}", weekLim)
    WuShenTan_Guide_Shop_WeekLimitTipNum:SetText (wlimContent)
end

--=========
-- 购买道具
--=========
function WuShenTan_Guide_Shop_Buy(shopId)
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("Buy")
        Set_XSCRIPT_ScriptID(893651)
        Set_XSCRIPT_Parameter(0, shopId)
        Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()
end
