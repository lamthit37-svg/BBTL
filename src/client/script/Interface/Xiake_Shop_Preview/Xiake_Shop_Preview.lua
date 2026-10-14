local g_Xiake_Shop_Preview_Frame_UnifiedPosition
local g_Xiake_Shop_Preview_TokenType

local g_Xiake_Shop_Preview_SubShopEnum = {
    RANDOM = 0,
    NORMAL = 1,
}

local g_Xiake_Shop_Preview_TokenName = {
    [0] = "#{XKSD_250110_80}",
    [1] = "#{XKSD_250110_81}"
}

local g_Xiake_Shop_LimitPic = {
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Day",                 -- 日
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Week",                 -- 周
}

g_Xiake_Shop_Money = {
    -- 代币 A
    [0] = "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon3",
    -- 代币 B
    [1] = "set:ActivitySchedule image:THGB",
}

--===============================================
-- OnLoad()
--===============================================
function Xiake_Shop_Preview_PreLoad()
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	--逻辑相关的事件
	this:RegisterEvent("OPEN_XIA_KE_PREVIEW",true)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
    -- this:RegisterEvent("OBJECT_CARED_EVENT",false);
    -- this:RegisterEvent("UPDATE_YUANBAO")
end

function Xiake_Shop_Preview_OnLoad()
	g_Xiake_Shop_Preview_Frame_UnifiedPosition = Xiake_Shop_Preview_Frame:GetProperty("UnifiedPosition")
end 
--===============================================
-- OnEvent()
--===============================================
function Xiake_Shop_Preview_OnEvent( event )
    if event == "OPEN_XIA_KE_PREVIEW" then
        Xiake_Shop_Preview_Info:SetText ("#{XKSD_250110_69}")

        Xiake_Shop_Preview_ItemList:Clear()

        local conf = Lua_GetXiaKeConfData()
        local limitconf = Lua_GetLimitShopConf()
        for _, one in pairs (conf) do
            if one.PageId == g_Xiake_Shop_Preview_SubShopEnum.RANDOM then
                local bar = Xiake_Shop_Preview_ItemList:AddChild("Xiake_Shop_Preview_ItemFrame")

                -- Action
                local mActionItem = DataPool:CreateBindActionItemForShow(one.ItemId, one.ItemNum)
                if mActionItem and mActionItem:GetID() ~= 0 then
                    bar:GetSubItem("Xiake_Shop_Preview_Item"):SetActionItem(mActionItem:GetID())

                    -- 道具名称
                    local itemname = ScriptGlobal_Format("#{XKSD_250110_25}", mActionItem:GetName())
                    bar:GetSubItem("Xiake_Shop_Preview_ItemText"):SetText (itemname)
                end

                -- 限购
                local limitbar = bar:GetSubItem("Xiake_Shop_Preview_ItemInfo_Limit")
                if one.LimitBuyId < 0 then
                    limitbar:Hide()
                else
                    if limitconf[one.LimitBuyId] then
                        local limittype = limitconf[one.LimitBuyId].mLimitType
                        if g_Xiake_Shop_LimitPic[limittype] then
                            limitbar:SetProperty("Image", g_Xiake_Shop_LimitPic[limittype])
                            limitbar:Show()
                        else
                            limitbar:Hide()
                        end
                    else
                        limitbar:Hide()
                    end
                end

                -- 所需货币图标
                if one.MoneyType < 0 or one.MoneyType > 1 then
                    bar:GetSubItem("Xiake_Shop_Preview_ItemPriceIcon"):Hide()
                else
                    bar:GetSubItem("Xiake_Shop_Preview_ItemPriceIcon"):SetProperty("Image", 
                        g_Xiake_Shop_Money[one.MoneyType])
                end

                -- 价格
                if one.MoneyType == 0 then
                    local str = ScriptGlobal_Format("#{XKSD_250110_18}", one.MoneyValue)
                    bar:GetSubItem("Xiake_Shop_Preview_ItemPrice"):SetText(str)
                elseif one.MoneyType == 1 then
                    local str = ScriptGlobal_Format("#{XKSD_250110_19}", one.MoneyValue)
                    bar:GetSubItem("Xiake_Shop_Preview_ItemPrice"):SetText(str)
                else
                    bar:GetSubItem("Xiake_Shop_Preview_ItemPrice"):Hide()
                end

                -- 蒙红
                bar:GetSubItem("Xiake_Shop_Preview_Item_Mask"):Hide()

                -- 绑定图标隐藏
                bar:GetSubItem("Xiake_Shop_Preview_Item_Feibang"):Hide()

                -- 限购数据
                bar:GetSubItem("Xiake_Shop_Preview_Item_BuyLimitNumBK"):Hide()

                -- 右下角的不知道什么东西... 说隐藏掉...
                bar:GetSubItem("Xiake_Shop_Preview_ItemInfo_Dynamic"):Hide()
            end
        end
        this:Show()
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		Xiake_Shop_Preview_Frame_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Xiake_Shop_Preview_Close()
	elseif event == "ADJEST_UI_POS" then
        Xiake_Shop_Preview_Frame_On_ResetPos()
    -- elseif event == "UPDATE_YUANBAO" and this:IsVisible() then
    --     local yuanbao = Player:GetData("YUANBAO")
    --     Xiake_Shop_Preview_CashNum:SetText(yuanbao)
	end
end

--===============================================
--关闭界面
--===============================================
function Xiake_Shop_Preview_OnHiden()
	this:Hide()
end
function Xiake_Shop_Preview_Frame_On_ResetPos()
	Xiake_Shop_Preview_Frame:SetProperty("UnifiedPosition", g_Xiake_Shop_Preview_Frame_UnifiedPosition)
end
