local g_Collection_Shop_BatchBuy_Frame_UnifiedPosition
local g_Collection_Shop_BatchBuy_Conf

local g_Collection_Shop_BatchBuy_TokenDic = {
    [0] = "#{CPSD_260119_55}",
    [1] = "#{CPSD_260119_53}",
    [2] = "#{CPSD_260119_54}",
}
local g_Collection_Shop_BatchBuy_TokensId = { 3414, 3415 }

-- 角标资源
local g_Collection_Shop_BatchBuy_Corner = {
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Day",                 -- 日
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Week",                -- 周
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever"              -- 永久
}


-- 获取 token 数量
function Collection_Shop_BatchBuy_GetToken (tokenId)
    if tokenId == 0 then
        return Player:GetData("YUANBAO")
    end
    if g_Collection_Shop_BatchBuy_TokensId[tokenId] then
        return DataPool:GetPlayerMission_DataRound (g_Collection_Shop_BatchBuy_TokensId[tokenId])
    end
    return -1
end

-- 获取 最大可购买数量
function Collection_Shop_BatchBuy_CalcMaxNum ()
    if not g_Collection_Shop_BatchBuy_Conf then
        return 0
    end

    local ans = 999999
    -- 过滤货币数量
    local token = Collection_Shop_BatchBuy_GetToken (g_Collection_Shop_BatchBuy_Conf.mCostType)
    local tokenmax = math.floor (token / g_Collection_Shop_BatchBuy_Conf.mCostNum)
    if tokenmax < ans then
        ans = tokenmax
    end
    -- 过滤限购
    if g_Collection_Shop_BatchBuy_Conf.mLimitId >= 0 then
        local _1, _2, _3, maxvalue = DataPool:lua_GetLimitShopConfOne (g_Collection_Shop_BatchBuy_Conf.mLimitId)
        if maxvalue then
            local limmax = maxvalue - g_Collection_Shop_BatchBuy_Conf.mLimitValue
            if limmax < ans then
                ans = limmax
            end
        end
    end
    return ans
end

--===============================================
-- OnLoad()
--===============================================
function Collection_Shop_BatchBuy_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--逻辑相关的事件
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
    this:RegisterEvent("UI_COMMAND")
end

function Collection_Shop_BatchBuy_OnLoad()
	g_Collection_Shop_BatchBuy_Frame_UnifiedPosition = Collection_Shop_BatchBuy_Frame:GetProperty("UnifiedPosition")

    -- 蒙红控件 隐藏掉 这个应该永远不会显示
    Collection_Shop_BatchBuy_Item_Mask:Hide()
end 
--===============================================
-- OnEvent()
--===============================================
-- !!!reloadscript =Collection_Shop_BatchBuy
function Collection_Shop_BatchBuy_OnEvent( event )
    if event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 99985201 then
        local shopId = Get_XParam_INT(0)
        g_Collection_Shop_BatchBuy_Conf = DataPool:lua_GetCangPinShopOne (shopId)
        if not g_Collection_Shop_BatchBuy_Conf then
            PushDebugMessage ("ShopId No Find")
            return
        end

        -- 数量
        Collection_Shop_BatchBuy_TextNum:SetText ("#{CPSD_260119_39}")
        -- 最大
        Collection_Shop_BatchBuy_Number_Max:SetText ("#{CPSD_260119_40}")
        -- 确定
        Collection_Shop_BatchBuy_OK:SetText ("#{CPSD_260119_46}")
        -- 取消
        Collection_Shop_BatchBuy_Cancel:SetText ("#{CPSD_260119_47}")


        Collection_Shop_BatchBuy_NumberInput:SetProperty("DefaultEditBox", "True")	--设置输入框为默认输入框
        Collection_Shop_BatchBuy_NumberInput:SetText("1")					--默认输入为1
        Collection_Shop_BatchBuy_NumberInput:SetSelected(0, -1)

        Collection_Shop_BatchBuy_FreshWindow()
        this:Show()
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		Collection_Shop_BatchBuy_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Collection_Shop_BatchBuy_Close()
	elseif event == "ADJEST_UI_POS" then
		Collection_Shop_BatchBuy_Frame_On_ResetPos()
	end
end

-- 关闭界面的时候调用
function Collection_Shop_BatchBuy_OnHidden ()
    g_Collection_Shop_BatchBuy_Frame_UnifiedPosition = nil
    g_Collection_Shop_BatchBuy_Conf = nil
end

-- 关闭界面按钮
function Collection_Shop_BatchBuy_OnClose ()
    this:Hide ()
end

--===============================================
--刷新界面信息
--===============================================
function Collection_Shop_BatchBuy_FreshWindow()
    if not g_Collection_Shop_BatchBuy_Conf then
        return
    end

    -- 设置 title
    if g_Collection_Shop_BatchBuy_Conf.mCostType == 0 then
        Collection_Shop_BatchBuy_DragTitle:SetText ("#{CPSD_260119_36}")
    else
        Collection_Shop_BatchBuy_DragTitle:SetText ("#{CPSD_260119_35}")
    end

    -- Action
    local mActionItem = DataPool:CreateBindActionItemForShow(g_Collection_Shop_BatchBuy_Conf.mItemId, g_Collection_Shop_BatchBuy_Conf.mItemNum)
    if mActionItem and mActionItem:GetID() ~= 0 then
        Collection_Shop_BatchBuy_Item:SetActionItem(mActionItem:GetID())

        -- 道具名称
        local itemname = ScriptGlobal_Format("#{CPSD_260119_37}", mActionItem:GetName())
        Collection_Shop_BatchBuy_ItemName:SetText (itemname)
    end

    -- 代币名称
    local tokenname = g_Collection_Shop_BatchBuy_TokenDic[g_Collection_Shop_BatchBuy_Conf.mCostType]

    -- 价格
    local strprice = ScriptGlobal_Format("#{CPSD_260119_38}", tokenname, g_Collection_Shop_BatchBuy_Conf.mCostNum)
    Collection_Shop_BatchBuy_ItemPrice:SetText (strprice)

    -- 限购
    if g_Collection_Shop_BatchBuy_Conf.mLimitId < 0 then
        Collection_Shop_BatchBuyBtnNumberBK:Hide ()
        Collection_Shop_BatchBuy_Item_BuyLimit:Hide ()
    else
        local _1, limtype, _3, maxvalue = DataPool:lua_GetLimitShopConfOne (g_Collection_Shop_BatchBuy_Conf.mLimitId)
        if maxvalue then
            Collection_Shop_BatchBuyBtnNumber:SetText (maxvalue - g_Collection_Shop_BatchBuy_Conf.mLimitValue)
            Collection_Shop_BatchBuyBtnNumberBK:Show ()
        else
            Collection_Shop_BatchBuyBtnNumberBK:Hide ()
        end

        if g_Collection_Shop_BatchBuy_Corner[limtype] then
            Collection_Shop_BatchBuy_Item_BuyLimit:SetProperty("Image", g_Collection_Shop_BatchBuy_Corner[limtype])
            Collection_Shop_BatchBuy_Item_BuyLimit:Show ()
        else
            Collection_Shop_BatchBuy_Item_BuyLimit:Hide ()
        end
    end

    -- 数量
    local count = tonumber(Collection_Shop_BatchBuy_NumberInput:GetText()) or 0

    -- 需要 XXXX
    local strneed = ScriptGlobal_Format("#{CPSD_260119_41}", tokenname)
    Collection_Shop_BatchBuy_TextNeed:SetText (strneed)

    -- 需要 num
    local neednum = count * g_Collection_Shop_BatchBuy_Conf.mCostNum
    local strneednum = ScriptGlobal_Format("#{CPSD_260119_42}", neednum)
    Collection_Shop_BatchBuy_TextNeedNum:SetText (strneednum)

    -- 拥有 XXXX
    local strhas = ScriptGlobal_Format("#{CPSD_260119_43}", tokenname)
    Collection_Shop_BatchBuy_TextHave:SetText (strhas)

    -- 拥有 num
    local token = Collection_Shop_BatchBuy_GetToken (g_Collection_Shop_BatchBuy_Conf.mCostType)
    local strtokenfmt = "#{CPSD_260119_45}"
    if neednum > token then
        strtokenfmt = "#{CPSD_260119_44}"
    end
    local strhasnum = ScriptGlobal_Format(strtokenfmt, token)
    Collection_Shop_BatchBuy_TextHaveNum:SetText (strhasnum)
end

--===============================================
--取出相应的物资
--===============================================
function Collection_Shop_BatchBuy_OnSubmit()
    -- 判断，玩家输入数量是否符合规定
	local count = tonumber(Collection_Shop_BatchBuy_NumberInput:GetText())
    if not count or count <= 0 then
        PushDebugMessage("#{CPSD_260119_49}")
		return
    end

    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("Buy")
        Set_XSCRIPT_ScriptID(999852)
        Set_XSCRIPT_Parameter(0, g_Collection_Shop_BatchBuy_Conf.mId)
        Set_XSCRIPT_Parameter(1, count)
        Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
	--隐藏界面
	this:Hide()
end

-- 点击最大
function Collection_Shop_BatchBuy_Max()
    local maxval = Collection_Shop_BatchBuy_CalcMaxNum ()
    Collection_Shop_BatchBuy_NumberInput:SetText (maxval)
end

-- 改变数量
function Collection_Shop_BatchBuy_TextChanged()
    -- local count = tonumber(Collection_Shop_BatchBuy_NumberInput:GetText())
    -- local maxval = Collection_Shop_BatchBuy_CalcMaxNum()
    -- if count <= 0 then
    --     Collection_Shop_BatchBuy_NumberInput:SetText(1)
    -- elseif count > maxval then
    --     Collection_Shop_BatchBuy_NumberInput:SetText(maxval)
    -- end
    Collection_Shop_BatchBuy_FreshWindow()
end

-- 重置位置
function Collection_Shop_BatchBuy_Frame_On_ResetPos()
	Collection_Shop_BatchBuy_Frame:SetProperty("UnifiedPosition", g_Collection_Shop_BatchBuy_Frame_UnifiedPosition)
end
