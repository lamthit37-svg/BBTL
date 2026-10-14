-- 藏品商店
-- 代币 Id { 低级: 1, 高级: 2 }
local g_Collection_Shop2_TokensId = { 3414, 3415 }
-- 商店分页编号, 默认低级代币
local g_Collection_Shop2_TabIdx = 1
-- 商店当前显示的页码
local g_Collection_Shop2_CurPage = 1
-- 缓存数据
local g_Collection_Shop2_Cache
-- ui index -> shopid
local g_Collection_Shop2_Ui2Id

-- UI 位置
local g_Collection_Shop2_UnifiedPosition
-- UI 控件
local g_Collection_Shop2_UI = {}
-- item 框数量
local g_Collection_Shop2_PageNum = 15
-- 不同标签的 字典
local g_Collection_Shop2_DicTx = {
    Price = "#{CPSD_260119_19}", TkNum = "#{CPSD_260119_22}", Explain = "#{CPSD_260119_61}",
}
-- 角标资源
local g_Collection_Shop2_Corner = {
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Day",                 -- 日
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Week",                -- 周
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever"              -- 永久
}

local g_Collection_Shop2_objcare


-- 获取某标签全部数据
function Collection_Shop2_GetConf (index)
    local ans = {}
    local conf = DataPool:lua_GetCangPinShop ()
    if not conf then
        return
    end
    for _, one in ipairs (conf) do
        if one.mCostType == index then
            table.insert (ans, one)
        end
    end
    return ans
end

-- 获取某标签最大页数
function Collection_Shop2_GetMaxPage (index)
    local conf = Collection_Shop2_GetConf (index)
    if not conf then
        return 0
    end
    local sum = table.getn (conf)
    return math.ceil (sum / g_Collection_Shop2_PageNum)
end

-- 获取 token 数量
function Collection_Shop2_GetToken (tokenId)
    if tokenId == 0 then
        return Player:GetData("YUANBAO")
    end
    if g_Collection_Shop2_TokensId[tokenId] then
        return DataPool:GetPlayerMission_DataRound (g_Collection_Shop2_TokensId[tokenId])
    end
    return -1
end

function Collection_Shop2_PreLoad()
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)	--进场景关闭界面
    this:RegisterEvent("ADJEST_UI_POS", false)
    this:RegisterEvent("OBJECT_CARED_EVENT",false)
    this:RegisterEvent("UPDATE_YUANBAO", false)
    this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("OPEN_CANG_PIN_YUANBAO_SHOP")
end

function Collection_Shop2_OnLoad()
    g_Collection_Shop2_UnifiedPosition = Collection_Shop2_Frame:GetProperty("UnifiedPosition")

    -- Collection_Shop2_Text:SetText ("#{CPSD_260119_12}")

    -- 初始化 Item 框
    g_Collection_Shop2_UI.Item = {}
    for i = 1, g_Collection_Shop2_PageNum do
        g_Collection_Shop2_UI.Item[i] = {
            Bg = _G["Collection_Shop2_Item" .. tostring (i) .. "BK"],
            ActBtn = _G["Collection_Shop2_Item" .. tostring (i)],
            LmBg = _G["Collection_Shop2_Item" .. tostring (i) .. "LimitNumberBK"],
            LmTx = _G["Collection_Shop2_Item" .. tostring (i) .. "LimitNumber"],
            Name = _G["Collection_Shop2_ItemInfo" .. tostring (i) .. "_Text"],
            Price = _G["Collection_Shop2_ItemInfo" .. tostring (i) .. "_GB"],
            Mask = _G["Collection_Shop2_Item" .. tostring (i) .. "_Mask"],
            Corner = _G["Collection_Shop2_Item" .. tostring (i) .. "Info_Limit"],
        }
    end
    -- 初始化 翻页组
    g_Collection_Shop2_UI.Page = {
        Prev = Collection_Shop2_UpPage,
        Num = Collection_Shop2_CurrentlyPage,
        Next = Collection_Shop2_DownPage,
    }
    -- 初始化 显示当前页 token 数量的 tx 控件
    g_Collection_Shop2_UI.TokenTx = Collection_Shop2_Text1

    -- 隐藏 Item 框框 ...
    g_Collection_Shop2_UI.HideItem = function (index)
        if index < 1 or index > g_Collection_Shop2_PageNum then
            return
        end
        g_Collection_Shop2_UI.Item[index].Bg:Hide ()
    end

    -- 显示 Item 框框 ...
    g_Collection_Shop2_UI.ShowItem = function (index, cont)
        if index < 1 or index > g_Collection_Shop2_PageNum then
            return
        end
        local tab = g_Collection_Shop2_UI.Item[index]
        -- Action Button
        local mActionItem = DataPool:CreateBindActionItemForShow(cont.mItemId, cont.mItemNum)
        if mActionItem and mActionItem:GetID() ~= 0 then
            tab.ActBtn:SetActionItem(mActionItem:GetID())

            -- 道具名称
            local itemname = ScriptGlobal_Format("#{CPSD_260119_16}", mActionItem:GetName())
            tab.Name:SetText (itemname)
        end

        -- 限购
        if cont.mLimitId < 0 then
            tab.LmBg:Hide ()
            tab.Mask:Hide ()
            tab.Corner:Hide ()
        else
            -- local limittype = limitconf[one.mLimitBuyId].mLimitType
            -- if g_Xiake_Shop_LimitPic[limittype] then
            --     limitbar:SetProperty("Image", g_Xiake_Shop_LimitPic[limittype])
            --     limitbar:Show()
            -- else
            --     limitbar:Hide()
            -- end
            local _1, limtype, _3, maxvalue = DataPool:lua_GetLimitShopConfOne (cont.mLimitId)
            if maxvalue then
                local val = maxvalue - cont.mLimitValue
                tab.LmTx:SetText (val)
                if val > 0 then
                    tab.Mask:Hide ()
                else
                    tab.Mask:Show ()
                end
                tab.LmBg:Show ()
            else
                tab.LmBg:Hide ()
                tab.Mask:Hide ()
            end

            -- 角标设置
            if limtype and g_Collection_Shop2_Corner[limtype] then
                tab.Corner:SetProperty("Image", g_Collection_Shop2_Corner[limtype])
                tab.Corner:Show ()
            else
                tab.Corner:Hide ()
            end
        end

        -- 价格
        local txprice = ScriptGlobal_Format(g_Collection_Shop2_DicTx.Price, cont.mCostNum)
        tab.Price:SetText (txprice)

        tab.Bg:Show ()
    end

    -- 更新当前页面的 token
    g_Collection_Shop2_UI.UpdateToken = function ()
        local tokenval = Collection_Shop2_GetToken (g_Collection_Shop2_TabIdx)
        local txprice = ScriptGlobal_Format(g_Collection_Shop2_DicTx.TkNum, tokenval)
        g_Collection_Shop2_UI.TokenTx:SetText (txprice)
    end

    -- 更新页数信息
    g_Collection_Shop2_UI.UpdatePage = function ()
        local sum = Collection_Shop2_GetMaxPage (g_Collection_Shop2_TabIdx)
        local page = ScriptGlobal_Format("#{CPSD_260119_50}", g_Collection_Shop2_CurPage, sum)
        g_Collection_Shop2_UI.Page.Num:SetText (page)

        if g_Collection_Shop2_CurPage <= 1 then
            g_Collection_Shop2_UI.Page.Prev:Disable ()
        else
            g_Collection_Shop2_UI.Page.Prev:Enable ()
        end

        if g_Collection_Shop2_CurPage >= sum then
            g_Collection_Shop2_UI.Page.Next:Disable ()
        else
            g_Collection_Shop2_UI.Page.Next:Enable ()
        end
    end
end

--=========
-- Event
--=========
---   !!!reloadscript =Collection_Shop2
function Collection_Shop2_OnEvent(event) 
    if event == "OPEN_CANG_PIN_YUANBAO_SHOP" then -- 更新
        local serverObjId = tonumber(arg0)
        g_Collection_Shop2_objcare = DataPool:GetNPCIDByServerID(serverObjId)
        this:CareObject(g_Collection_Shop2_objcare, 1, "Collection_Shop2")
        -- 暂时 TabIdx 设置为无效值, 后面初始化
        g_Collection_Shop2_TabIdx = -1
        Collection_Shop2_OnChangeTab(0)
        this:Show ()
    elseif event == "UI_COMMAND" and arg0 and tonumber (arg0) == 99985203 then
        if this:IsVisible() then
            local limitId = Get_XParam_INT(0)
            local limitVal = Get_XParam_INT(1)

            if limitId >= 0 and limitVal >= 0 then
                local ans = DataPool:lua_ChangeCangPinShopData (limitId, limitVal)
                if ans > 0 then
                    Collection_Shop2_Update()
                end
            else
                if g_Collection_Shop2_UI then
                    g_Collection_Shop2_UI.UpdateToken ()
                end
            end
        end
    elseif event == "VIEW_RESOLUTION_CHANGED" then
        Collection_Shop2_On_ResetPos()
    elseif event == "HIDE_ON_SCENE_TRANSED" then
        Collection_Shop2_OnClose()
    elseif event == "ADJEST_UI_POS" then
        Collection_Shop2_On_ResetPos()
    elseif event == "UPDATE_YUANBAO" then
        -- 如果显示的是元宝页签 才更新
        if g_Collection_Shop2_TabIdx == 0 then
            g_Collection_Shop2_UI.UpdateToken ()
        end
    elseif event == "OBJECT_CARED_EVENT" then
        if tonumber(arg0) ~= g_Collection_Shop2_objcare then
            return
        end
        --如果和NPC的距离大于一定距离或者被删除，自动关闭
        if arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1 == "destroy" then
            this:Hide()
            --取消关心
            this:CareObject(g_Collection_Shop2_objcare, 0, "Collection_Shop2")
        end
    end
end
 
--=========
-- 重置
--=========
function Collection_Shop2_On_ResetPos()
    Collection_Shop2_Frame:SetProperty("UnifiedPosition", g_Collection_Shop2_UnifiedPosition)
end

-- 关闭界面的时候会调用这个接口
function Collection_Shop2_OnHidden ()
    if IsWindowShow ("Collection_Shop2_BatchBuy") then
        CloseWindow ("Collection_Shop2_BatchBuy", true)
    end

    if g_Collection_Shop2_objcare then
        this:CareObject(g_Collection_Shop2_objcare, 0, "Collection_Shop2")
        g_Collection_Shop2_objcare = nil
    end
end

--=========
-- 关闭
--=========
function Collection_Shop2_OnClose()
    g_Collection_Shop2_TabIdx = g_Collection_Shop2_SubShopEnum.LOWLEVEL
    g_Collection_Shop2_CurPage = 1
    this:Hide()
end

--=========
-- 切换子页面
--=========
function Collection_Shop2_OnChangeTab(index)
    if index == g_Collection_Shop2_TabIdx then
        return
    end
    g_Collection_Shop2_TabIdx = tonumber(index)
    g_Collection_Shop2_CurPage = 1

    Collection_Shop2_Info:SetText (g_Collection_Shop2_DicTx.Explain)

    Collection_Shop2_Update()
end

--=========
-- 更新界面数据
--=========
function Collection_Shop2_Update ()
    local conf = Collection_Shop2_GetConf (g_Collection_Shop2_TabIdx)
    local startindex = (g_Collection_Shop2_CurPage - 1) * g_Collection_Shop2_PageNum + 1
    local finishindex = g_Collection_Shop2_CurPage * g_Collection_Shop2_PageNum

    g_Collection_Shop2_Ui2Id = {}
    for i = startindex, finishindex do
        local uiindex = math.mod (i, g_Collection_Shop2_PageNum)
        if uiindex == 0 then
            uiindex = 15
        end
        local oneconf = conf[i]
        if oneconf then
            g_Collection_Shop2_Ui2Id[uiindex] = oneconf.mId
            g_Collection_Shop2_UI.ShowItem (uiindex, oneconf)
        else
            g_Collection_Shop2_UI.HideItem (uiindex)
        end
    end

    -- 更新当前 token 信息
    g_Collection_Shop2_UI.UpdateToken ()

    -- 更新页数信息
    g_Collection_Shop2_UI.UpdatePage ()
end

--=========
-- 上一页
--=========
function Collection_Shop2_PageUp()
    if g_Collection_Shop2_CurPage <= 1 then
        return
    end
    g_Collection_Shop2_CurPage = g_Collection_Shop2_CurPage - 1
    Collection_Shop2_Update ()
end

--=========
-- 下一页
--=========
function Collection_Shop2_PageDown()
    local sum = Collection_Shop2_GetMaxPage (g_Collection_Shop2_TabIdx)
    if g_Collection_Shop2_CurPage >= sum then
        return
    end
    
    g_Collection_Shop2_CurPage = g_Collection_Shop2_CurPage + 1
    Collection_Shop2_Update()
end

--=========
-- 购买道具
--=========
function Collection_Shop2_Buy(uiindex)
    if not g_Collection_Shop2_Ui2Id[uiindex] then
        return
    end
    local shopId = g_Collection_Shop2_Ui2Id[uiindex]
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("Buy")
        Set_XSCRIPT_ScriptID(999852)
        Set_XSCRIPT_Parameter(0, shopId)
        Set_XSCRIPT_Parameter(1, -1)
        Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
end
