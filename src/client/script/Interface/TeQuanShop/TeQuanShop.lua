local g_TeQuanShop_Frame_UnifiedPosition

local g_UI_Items = {}

local g_UICOMMAND = 99840101

local g_ExeScript = 998401

local g_CurShopLevel = 0 

local g_MaxShopLevel = 3

local g_CostLevel = 0

local g_PlayerCreatedDays = 0

local g_ServerCreatedDays = 0

local g_ShopNeedCostLevel = {
    [1] = 4,
    [2] = 7,
    [3] = 2,
}

local g_SpecialLimitNum = 12
local g_SpecialLimitTypeCom = nil
local g_SpecialLimitStr = {
    [1] = {"#{TQSD_230201_48}","#{TQSD_230201_56}"}, --装备8个5级紫色真元
    [2] = {"#{TQSD_230201_49}","#{TQSD_230201_57}"}, --装备15个6级雕纹
    [3] = {"#{TQSD_230201_50}","#{TQSD_230201_58}"}, --装备3件强化+9装备
    [4] = {"#{TQSD_230201_51}","#{TQSD_230201_59}"}, --装备6件强化+9装备
    [5] = {"#{TQSD_230201_52}","#{TQSD_230201_60}"}, --装备9件强化+9装备
    [6] = {"#{TQSD_230201_53}","#{TQSD_230201_61}"}, --装备8个6级橙色真元
    [7] = {"#{TQSD_230201_54}","#{TQSD_230201_62}"}, --装备35颗5级宝石
    [8] = {"#{TQSD_230201_55}","#{TQSD_230201_63}"}, --装备35颗6级宝石
    [9] = {"#{TQSD_230201_65}","#{TQSD_230201_69}"}, --装备35可4级宝石可购买
    [10] = {"#{TQSD_230201_66}","#{TQSD_230201_70}"}, --充值超值赠达到第5档可购买
    [11] = {"#{TQSD_230201_67}","#{TQSD_230201_71}"}, --充值超值赠达到第6档可购买
    [12] = {"#{TQSD_230201_68}","#{TQSD_230201_72}"}, --30天内装评达到25万可购买
}

local g_ShopInfo = {} --[i] = itemID,showID,uniqueID,itemGroupNum,limitType,limitNum,limitSpecialType,sellDays,discount,itemPriceYuanbao,haveGotNums

local actionBtnRes = {
    ["price"] = "TeQuanShop_CoinAItem1_Cost",
    ["name"] = "TeQuanShop_CoinAItem1_Name",
    ["action"] = "TeQuanShop_CoinAItem1_Icon",
    ["leftnum"] = "TeQuanShop_ItemNum",
    ["imageqin"] = "TeQuanShop_IconMark",
    ["weekLimit"] = "TeQuanShop_IconMark_Zhou",
    ["monthLimit"] = "TeQuanShop_IconMark_Yue",
    ["fovLimit"] = "TeQuanShop_IconMark_YongJiu",
    ["discountBK"] = "TeQuanShop_CoinAItem1_DiscountBK",
    ["discount"] = "TeQuanShop_CoinAItem1_Discount_Text",
    ["LimitDays"] = "TeQuanShop_CoinAItem1_DiscountSign",
    ["yuanbaoImg"] = "TeQuanShop_CoinAItem1_CostSign",
    ["specialLimit"] = "TeQuanShop_CoinAItem1_Cost_TiaoJian",
    ["redPoint"] = "TeQuanShop_CoinAItem1_Icon_Tips",
}

local g_openShopDay = 0
local g_ShopTabRedPointData = 0
local g_ShowShop3 = 0
local g_TabPos = {
    [1] = "{{0.000000,0.000000},{0.000000,0.000000}}",
    [2] = "{{0.000000,100.000000},{0.000000,0.000000}}",
    [3] = "{{0.000000,200.000000},{0.000000,0.000000}}",
}

function TeQuanShop_PreLoad()
    this:RegisterEvent("UI_COMMAND",true)
--	this:RegisterEvent("UPDATE_XFTQSHOP",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
    this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
    this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
    this:RegisterEvent("UPDATE_YUANBAO",false);
end

function TeQuanShop_OnLoad()
    g_TeQuanShop_Frame_UnifiedPosition = TeQuanShop_Frame:GetProperty("UnifiedPosition")
    g_UI_Items  = {}
    g_UI_Items.tabBtn = {}
    g_UI_Items.tabLock = {}
    g_UI_Items.tabTips = {}
    for i = 1, g_MaxShopLevel do
        g_UI_Items.tabBtn[i] = _G["TeQuanShop_PageBtn"..i]
        g_UI_Items.tabLock[i] = _G["TeQuanShop_CoinAItem1_Lock"..i]
        g_UI_Items.tabTips[i] = _G[string.format( "TeQuanShop_PageBtn%d_Tips",i )]
    end
    g_UI_Items.ShopItemListBox = TeQuanShop_Lace1
    g_UI_Items.TeQuanLevelText = TeQuanShop_Bk1_text
    g_UI_Items.MyYuanBao = TeQuanShop_Money
    g_UI_Items.actionBtns = {}
end



local function CleanShop()
    g_ShopInfo = {}
    g_CurShopLevel = 0
    g_CostLevel = 0
    g_PlayerCreatedDays = 0
    g_ServerCreatedDays = 0
    g_SpecialLimitTypeCom = nil
    g_openShopDay = 0
    if  g_UI_Items.actionBtns then
        for k, v in pairs( g_UI_Items.actionBtns) do
            g_UI_Items.actionBtns[k]:SetActionItem(-1)
            g_UI_Items.actionBtns[k] = nil
        end
        g_UI_Items.actionBtns = {}
        g_UI_Items.ShopItemListBox:Clear()
    end
    g_ShopTabRedPointData = 0
    g_ShowShop3 = 0
end
local function DateAddDay(date,adddays)
    local days = math.mod(date , 100)
	date = math.floor(date / 100)
	local month = math.mod(date , 100)
    local year = math.floor(date / 100)
    local maxDayInMonth = 31
    local addOnce = 0
    local remain = adddays
	if 4 == month or 6 == month or 9 == month or 11 == month  then
		maxDayInMonth = 30
	elseif 2 == month then
		if ( 0 == math.mod(year , 4) and 0 ~= math.mod(year,100) ) or 0 == math.mod(year , 400) then
			--闰年
			maxDayInMonth = 29
		else
			maxDayInMonth = 28
		end
    end
    while remain > 0 do
        if days + remain > maxDayInMonth then
            local oddonce = maxDayInMonth-days+1
            days = 1
            remain = remain - oddonce
            month = month + 1
            if month > 12 then
                month = 1
                year = year + 1
            end
            if 4 == month or 6 == month or 9 == month or 11 == month  then
                maxDayInMonth = 30
            elseif 2 == month then
                if ( 0 == math.mod(year , 4) and 0 ~= math.mod(year,100) ) or 0 == math.mod(year , 400) then
                    --闰年
                    maxDayInMonth = 29
                else
                    maxDayInMonth = 28
                end
            end
        else
            days = days + remain
            remain = 0
        end
    end
    return year,month,days

end

local function OpenShop(shopLevel)
    this:Hide()
    if shopLevel < 1 or shopLevel > g_MaxShopLevel then
        return 
    end
        
    g_ShopInfo =  Lua_GetXFTQShopData(shopLevel)
    assert(type(g_ShopInfo) == "table")
    g_CurShopLevel = shopLevel

    --设置tab页签check
    for i = 1, g_MaxShopLevel do
        if shopLevel == i then
            g_UI_Items.tabBtn[i]:SetCheck(1)
        else
            g_UI_Items.tabBtn[i]:SetCheck(0)
        end
    end
    
    --设置tab页签上的锁锁
    local tabRedData = g_ShopTabRedPointData
    for i = 1, g_MaxShopLevel do
        local curTabRed = math.mod(tabRedData,10)
        tabRedData = math.floor(tabRedData/10)
        if g_CostLevel < g_ShopNeedCostLevel[i] then
            --不满足消费等级 上锁
             g_UI_Items.tabLock[i]:Show()
             g_UI_Items.tabBtn[i]:SetToolTip(ScriptGlobal_Format("#{TQSD_230201_09}",g_ShopNeedCostLevel[i]))
             g_UI_Items.tabTips[i]:Hide()
        else
             g_UI_Items.tabLock[i]:Hide()
             g_UI_Items.tabBtn[i]:SetToolTip("")
             if curTabRed  ==  1 then
                g_UI_Items.tabTips[i]:Show()
             else
                g_UI_Items.tabTips[i]:Hide()
             end
        end
    end
    --特写 调整tab位置
    local startp = 1
    if g_ShowShop3 == 1 then
        g_UI_Items.tabBtn[3] : Show()
        startp = 2
    else
        g_UI_Items.tabBtn[3] : Hide()
    end
    for i = 1, 2 do
        g_UI_Items.tabBtn[i]:SetProperty("UnifiedPosition", g_TabPos[startp])
        startp = startp + 1
    end

    --商店的特权等级
    g_UI_Items.TeQuanLevelText:SetText(ScriptGlobal_Format("#{TQSD_230201_06}",g_CostLevel))
    g_UI_Items.TeQuanLevelText:SetToolTip("#{TQSD_230201_07}")
    this:Show()
    --添加商品
    for k, v in pairs( g_UI_Items.actionBtns) do
        g_UI_Items.actionBtns[k]:SetActionItem(-1)
        g_UI_Items.actionBtns[k] = nil
    end
    g_UI_Items.actionBtns = {}
    g_UI_Items.ShopItemListBox:Clear()
    local itemCount = table.getn(g_ShopInfo)
    local actBtnIndex = 1
    for i = 1, itemCount do
        --[i] = itemID,showID,uniqueID,itemGroupNum,limitType,limitNum,limitSpecialType,sellDays,discount,itemPriceYuanbao,haveGotNums
        local itemInfo = g_ShopInfo[i]
        assert(type(itemInfo) == "table")
        local showItem = true
        if itemInfo.sellDays > 0 and itemInfo.sellDays < g_ServerCreatedDays then
            showItem = false
        end
        if itemInfo.limitSpecialType == 12 and g_PlayerCreatedDays > 30 then
            --超过30天了
            showItem = false
        end
        if showItem then
            local itemCommon = g_UI_Items.ShopItemListBox:AddChild("TeQuanShop_CoinAItem1")
            local btn = assert(itemCommon:GetSubItem(actionBtnRes["action"])) 
            btn:SetEvent("Clicked", string.format("TeQuanShop_OnItemCliecked(%d)", i))
            --商品价格
            local Price = itemInfo.itemPriceYuanbao 
            if itemInfo.discount >= 0 then
                Price = math.floor((itemInfo.itemPriceYuanbao*itemInfo.discount)*0.01)
            end
            local priceText = assert(itemCommon:GetSubItem(actionBtnRes["price"])) 
            local specialLimitText = assert(itemCommon:GetSubItem(actionBtnRes["specialLimit"])) 
            local yuanbaoImg = assert(itemCommon:GetSubItem(actionBtnRes["yuanbaoImg"])) 
            specialLimitText:Hide()
            priceText:Show()
            yuanbaoImg:Show()
            priceText:SetText(ScriptGlobal_Format("#{TQSD_230201_11}",Price ))
            --设置商品名称
            itemCommon:GetSubItem(actionBtnRes["name"]):SetText(ScriptGlobal_Format("#{TQSD_230201_10}",DataPool:Lua_GetItemNameByIndex(itemInfo.itemID)))
            --设置剩余数量
            local haveGotNums = itemInfo.haveGotNums
            if haveGotNums < 0 then
                haveGotNums = 999
            end
            local leftNum = itemInfo.limitNum - haveGotNums
            if leftNum <= 0  then
                itemCommon:GetSubItem(actionBtnRes["imageqin"]):Show()
            else
                itemCommon:GetSubItem(actionBtnRes["imageqin"]):Hide()
            end

            local textnum =  assert(itemCommon:GetSubItem(actionBtnRes["leftnum"]))
            textnum:Show()
            textnum:SetText(leftNum)

            --设置商品限量标示
            local imageWeek = assert(itemCommon:GetSubItem(actionBtnRes["weekLimit"]))
            local imageMonth = assert(itemCommon:GetSubItem(actionBtnRes["monthLimit"]))
            local imageFov = assert(itemCommon:GetSubItem(actionBtnRes["fovLimit"]))
            if itemInfo.limitType == 1 then
                --周限购
                imageWeek:Show()
                imageMonth:Hide()
                imageFov:Hide()
            elseif itemInfo.limitType == 2 then
                --月限购
                imageWeek:Hide()
                imageMonth:Show()
                imageFov:Hide()
            elseif itemInfo.limitType == 3 then
                --永远限购
                imageWeek:Hide()
                imageMonth:Hide()
                imageFov:Show()
            else
                --不限量
                textnum:Hide()
                imageWeek:Hide()
                imageMonth:Hide()
                imageFov:Hide()
            end

            --限时购买
            local imagLimitDays = assert(itemCommon:GetSubItem(actionBtnRes["LimitDays"]))
            if itemInfo.sellDays > 0 then
                imagLimitDays:Show()
                local nCurDay = tonumber(DataPool:GetServerDayTime());
                local beginDay,_ = DataPool:Lua_XFTQShopTime()
                local  year,month,days = DateAddDay(beginDay,itemInfo.sellDays)
                imagLimitDays:SetToolTip(ScriptGlobal_Format("#{TQSD_230201_64}",year,month,days))
            else
                imagLimitDays:Hide()
            end

            --特殊购买条件2 
            if itemInfo.limitSpecialType > 0 and g_SpecialLimitStr[itemInfo.limitSpecialType] and type(g_SpecialLimitTypeCom) == "table" then
                if g_SpecialLimitTypeCom[itemInfo.limitSpecialType] ~= 1 then
                    specialLimitText:Show()
                    specialLimitText:SetText(g_SpecialLimitStr[itemInfo.limitSpecialType][1])
                end
            end

            --折扣
        
            local discountBK = assert(itemCommon:GetSubItem(actionBtnRes["discountBK"])) 
            if itemInfo.discount >= 0  then
                discountBK:Show()
                local discount = assert(itemCommon:GetSubItem(actionBtnRes["discount"])) 
                -- local fmtCut = itemInfo.discount/100
                -- if math.mod(fmtCut*100,10) ~= 0 then
                -- 	discount:SetText("#cffe1b8" .. string.format("%.1f",fmtCut*10) .. "折")
                -- else
                -- 	discount:SetText("#cffe1b8" .. fmtCut*10 .. "折")
                -- end
                
                discount:SetText("#cffe1b8" .. string.format("%.1f",itemInfo.discount/10) .. "折")
            else
                discountBK:Hide()
            end

            --是否显示红点
            local redPoint = assert(itemCommon:GetSubItem(actionBtnRes["redPoint"]))
            if 1== TeQuanShop_ItemShowTips(i) then
                redPoint:Show()
            else
                redPoint:Hide()
            end

            --设置actionbutton
            local action_item = DataPool:CreateActionItemForShow(itemInfo.showID, itemInfo.itemGroupNum)
            if action_item:GetID() ~= 0 then
                btn:SetActionItem(action_item:GetID())
                g_UI_Items.actionBtns[actBtnIndex] = btn
                actBtnIndex = actBtnIndex +1
            end
        end
        
    end
    

    local nHaveYB = Player:GetData("YUANBAO")
    g_UI_Items.MyYuanBao:SetText(ScriptGlobal_Format("#{TQSD_230201_46}",nHaveYB))
end




function TeQuanShop_CloseShop()
    CleanShop()
    this:Hide()
    --关闭二次确认 关闭批量购买
    if IsWindowShow("TeQuanShop_Mbuy") then
        CloseWindow("TeQuanShop_Mbuy", true)
    end
    
end

function TeQuanShop_OnHiden()
    
end

local function GetSpecialLimitTypeCom(data)
    local BitTable = {}
	local oct = data
	for i = 1 , g_SpecialLimitNum do
		BitTable[i] = math.mod(oct , 2)
		oct = math.floor(oct / 2)
	end
	return BitTable
end

function TeQuanShop_OnEvent(event)
    if event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND then
        local opt = Get_XParam_INT(0)
        if opt == 1 then
            CleanShop()
            g_CurShopLevel = Get_XParam_INT(1)
            g_CostLevel = Get_XParam_INT(2)
            local dataSpecialLimitTypeCom = Get_XParam_INT(3)
            g_SpecialLimitTypeCom = GetSpecialLimitTypeCom(dataSpecialLimitTypeCom)
            g_openShopDay = Get_XParam_INT(4)
            g_PlayerCreatedDays = Get_XParam_INT(5)
            g_ServerCreatedDays = Get_XParam_INT(6)
            g_ShopTabRedPointData =  Get_XParam_INT(7)
            g_ShowShop3 =  Get_XParam_INT(8)
            OpenShop(g_CurShopLevel)
            --OpenWindow("Packet")
        elseif  opt == 2 and this:IsVisible() then
            --更新商店页面
            assert(g_UI_Items.ShopItemListBox)
            local oldScrollPos = g_UI_Items.ShopItemListBox :GetScrollPosition()	--保存上一次滚动条位置
            g_CurShopLevel = Get_XParam_INT(1)
            g_CostLevel = Get_XParam_INT(2)
            local dataSpecialLimitTypeCom = Get_XParam_INT(3)
            g_SpecialLimitTypeCom = GetSpecialLimitTypeCom(dataSpecialLimitTypeCom)
            g_openShopDay = Get_XParam_INT(4)
            g_PlayerCreatedDays = Get_XParam_INT(5)
            g_ServerCreatedDays = Get_XParam_INT(6)
            g_ShopTabRedPointData =  Get_XParam_INT(7)
            g_ShowShop3 =  Get_XParam_INT(8)
            OpenShop(g_CurShopLevel)
            g_UI_Items.ShopItemListBox :SetScrollPosition(oldScrollPos)
        end
        
    elseif event == "UPDATE_XFTQSHOP" and this:IsVisible() then
        --更新商店页面

    elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
        local nHaveYB = Player:GetData("YUANBAO")
        if g_UI_Items.MyYuanBao then
            g_UI_Items.MyYuanBao:SetText(ScriptGlobal_Format("#{TQSD_230201_46}",nHaveYB))
        end
    end

    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or
			event == "VIEW_RESOLUTION_CHANGED" then
				TeQuanShop_ResetPos()
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            this:Hide()
        end
    end
end

function TeQuanShop_OpenShop_Cliecked(level)
    if level < 1 or level > g_MaxShopLevel then
        return 
    end
    if 1 ~= DataPool:Lua_XFTQShopIsOpen() then
		PushDebugMessage("#{TQSD_230201_01}")
		return
	end
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenShop" ); 	-- 脚本函数名称
		Set_XSCRIPT_ScriptID( g_ExeScript );				-- 脚本编号
		Set_XSCRIPT_Parameter( 0, level );				-- 参数一
		Set_XSCRIPT_ParamCount( 1 );				-- 参数个数
	Send_XSCRIPT()
end

function TeQuanShop_ItemShowTips(index)
    if g_CurShopLevel < 1 then
        return 0
    end
    if g_ShopInfo[index] ~= nil then
        local nLevel = Player:GetLevel()
        if nLevel< 30 then
            return 0
        end
        if g_CostLevel < g_ShopNeedCostLevel[g_CurShopLevel] then
            return 0
        end

        --特殊购买条件2 
        if g_ShopInfo[index].limitSpecialType > 0 and g_SpecialLimitStr[g_ShopInfo[index].limitSpecialType] and type(g_SpecialLimitTypeCom) == "table" then
            if g_SpecialLimitTypeCom[g_ShopInfo[index].limitSpecialType] ~= 1 then
                return 0
            end
        end
        if g_ShopInfo[index].limitNum - g_ShopInfo[index].haveGotNums < 1 then
            return 0
        end

        if g_ShopInfo[index].itemPriceYuanbao > 0 then
            return 0
        end
        return 1
    end
    return 0
end

function TeQuanShop_OnItemCliecked(index)
    if g_CurShopLevel < 1 then
        return 
    end
    if g_ShopInfo[index] ~= nil then
        local nLevel = Player:GetLevel()
        if nLevel< 30 then
            PushDebugMessage("#{TQSD_230201_17}")
            return 
        end
        if g_CostLevel < g_ShopNeedCostLevel[g_CurShopLevel] then
            PushDebugMessage(ScriptGlobal_Format("#{TQSD_230201_18}",g_ShopNeedCostLevel[g_CurShopLevel]) )
            return 
        end

        --特殊购买条件2 
        if g_ShopInfo[index].limitSpecialType > 0 and g_SpecialLimitStr[g_ShopInfo[index].limitSpecialType] and type(g_SpecialLimitTypeCom) == "table" then
            if g_SpecialLimitTypeCom[g_ShopInfo[index].limitSpecialType] ~= 1 then
                PushDebugMessage(g_SpecialLimitStr[g_ShopInfo[index].limitSpecialType][2])
                return 
            end
        end
        if g_ShopInfo[index].limitNum - g_ShopInfo[index].haveGotNums < 1 then
            PushDebugMessage("#{TQSD_230201_19}")
            return 
        end


        TeQuanShop_OpenMutiBuy(index)
    end
end

function TeQuanShop_OpenMutiBuy(index)
    if g_ShopInfo[index] ~= nil then
        local maxNum = -1
        if  g_ShopInfo[index].limitNum > 0 and g_ShopInfo[index].limitType > 0 then
            if g_ShopInfo[index].limitNum < g_ShopInfo[index].haveGotNums then
                PushDebugMessage("#{TQSD_230201_19}")
                return 
            end
            maxNum = g_ShopInfo[index].limitNum - g_ShopInfo[index].haveGotNums
        end
        local Price = g_ShopInfo[index].itemPriceYuanbao 
        if g_ShopInfo[index].discount >= 0 then
            Price = math.floor((g_ShopInfo[index].itemPriceYuanbao*g_ShopInfo[index].discount)*0.01)
        end
        PushEvent("TeQuanShop_MITYBUY",
        Price ,
        g_ShopInfo[index].itemID,
        maxNum,
        g_ShopInfo[index].itemGroupNum,
        g_CurShopLevel,
        g_openShopDay,
        g_ShopInfo[index].uniqueID,
        g_ShopInfo[index].showID
        )
    end
end

function TeQuanShop_OnHelpBtnCliecked()
    	-- 借用一下别人的通道
        PushEvent("CCSHOP_HELP", 193)
end

function TeQuanShop_ResetPos()
    TeQuanShop_Frame:SetProperty("UnifiedPosition", g_TeQuanShop_Frame_UnifiedPosition)
end