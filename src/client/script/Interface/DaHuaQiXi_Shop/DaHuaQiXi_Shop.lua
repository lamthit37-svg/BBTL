-- 【2024Q2】 大话七夕商店
local g_DaHuaQiXiShop_MainScriptId = 999236

local g_DaHuaQiXiShop_start_time = 20250821
local g_DaHuaQiXiShop_end_time = 20250917
local g_DaHuaQiXiShop_CurrencyBuy_start_time = 20250911
local g_DaHuaQiXiShop_CurrencyBuy_end_time = 20250917
local g_DaHuaQiXiShop_BuyLevel = 30 -- 30级以上才可以购买

local g_DaHuaQiXiShop_CurTag = 1 --当前分页id，从1开始
local g_DaHuaQiXiShop_CurPage = 1 --当前页数
local g_DaHuaQiXiShop_PerPageCount = 15 --每一页显示的商品数量
local g_DaHuaQiXiShop_ItemsCount = {} --某个页签下的商品总数量
local g_DaHuaQiXiShop_Page_Saved = {} --保存上一次打开某个二级页签时，在浏览第几页

local g_DaHuaQiXiShop_Frame_UnifiedXPosition
local g_DaHuaQiXiShop_Frame_UnifiedYPosition

local g_DaHuaQiXiShop_UIList = {
    box = {}, --整个商品的UI
    cnt = {}, --限购Text
    cntb= {}, --限购的背景图
    sgn = {}, --货币icon
    prz = {}, --价格Text
    -- btn = {}, --购买按钮
    abtn= {}, --展示道具的ActionButton
    disi= {}, --折扣角标
    disc= {}, --折扣Text
    disp= {}, --折扣背景图
    name= {}, --商品名Text
    mask= {}, --蒙红遮罩
    day = {}, --右上小字日限购
    week= {}, --右上小字“周”
    xian= {}, --右上小字“限”
}
local g_DaHuaQiXiShop_ItemsInfo = {}
local g_DaHuaQiXiShop_BuyingIndex = -1
local g_DaHuaQiXiShop_BuyingCount = 0
local g_DaHuaQiXiShop_OpenDay = 0
local g_DaHuaQiXiShop_CurWeek = 0
local g_DaHuaQiXiShop_NeedUpdateData = 0

local g_DaHuaQiXiShop_Daibi_Icons = {
    "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon2", --代币1
    "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon2", --代币2
}
local g_DaHuaQiXiShop_Daibi_Strs = {
    "#{DHSD_20240522_53}", --倩心玉
    "#{DHSD_20240522_54}", --菩提珠
}

--************************
-- PreLoad
--************************
function DaHuaQiXi_Shop_PreLoad()
    this:RegisterEvent("DAHUAQIXI_SHOP_UPDATE", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("DAHUAQIXI_DAIBI_CHANGED", false)
    this:RegisterEvent("DAHUAQIXI_CHANGE_WEEK", false)
end

--************************
-- OnLoad
--************************
function DaHuaQiXi_Shop_OnLoad() 
    if table.getn(g_DaHuaQiXiShop_UIList.box) > 0 then
        return
    end

    for i = 1, g_DaHuaQiXiShop_PerPageCount do
        local str = "DaHuaQiXi_ShopItem"..i
        g_DaHuaQiXiShop_UIList.box[i] = _G[str]
        g_DaHuaQiXiShop_UIList.cnt[i] = _G[str.."_Num"]
        g_DaHuaQiXiShop_UIList.cntb[i]= _G[str.."_NumBK"]
        g_DaHuaQiXiShop_UIList.sgn[i] = _G[str.."_CostSign"]
        g_DaHuaQiXiShop_UIList.prz[i] = _G[str.."_Cost"]
        -- g_DaHuaQiXiShop_UIList.btn[i] = _G[str.."Btn"]
        g_DaHuaQiXiShop_UIList.abtn[i]= _G[str.."_Icon"]
        g_DaHuaQiXiShop_UIList.disi[i]= _G[str.."_Icon_Discount"]
        g_DaHuaQiXiShop_UIList.disc[i]= _G[str.."_Discount"]
        g_DaHuaQiXiShop_UIList.disp[i]= _G[str.."_DiscountBK"]
        g_DaHuaQiXiShop_UIList.disc[i]:Hide()
        g_DaHuaQiXiShop_UIList.disp[i]:Hide()
        g_DaHuaQiXiShop_UIList.name[i]= _G[str.."_Name"]
        g_DaHuaQiXiShop_UIList.mask[i]= _G[str.."_IconMark"]
        g_DaHuaQiXiShop_UIList.day[i] = _G[str.."_IconMark1"]
        g_DaHuaQiXiShop_UIList.week[i]= _G[str.."_IconMark2"]
        g_DaHuaQiXiShop_UIList.xian[i]= _G[str.."_IconMark3"]
        g_DaHuaQiXiShop_UIList.abtn[i]:SetEvent("Clicked", string.format("DaHuaQiXi_Shop_Clicked(%d)", i))
    end
    g_DaHuaQiXiShop_Frame_UnifiedXPosition = DaHuaQiXi_Shop_Frame:GetProperty("UnifiedXPosition") 
	g_DaHuaQiXiShop_Frame_UnifiedYPosition = DaHuaQiXi_Shop_Frame:GetProperty("UnifiedYPosition")
    DaHuaQiXi_Shop_Currency2_buy:SetToolTip(ScriptGlobal_Format("#{DHSD_20240522_14}", g_DaHuaQiXiShop_Daibi_Strs[1]))

    -- 设置一级页签
    g_DaHuaQiXiShop_CurTag = 1
end

--************************
-- OnEvent
--************************
function DaHuaQiXi_Shop_OnEvent(event)
	if event == "DAHUAQIXI_SHOP_UPDATE" then
        if arg0 == "show" then
	        g_DaHuaQiXiShop_OpenDay = tonumber(DataPool:GetServerDayTime())
            g_DaHuaQiXiShop_CurWeek = tonumber(arg1)
            g_DaHuaQiXiShop_NeedUpdateData = 0
            g_DaHuaQiXiShop_Page_Saved[1], g_DaHuaQiXiShop_Page_Saved[2] = 1, 1
            g_DaHuaQiXiShop_ItemsCount[1], g_DaHuaQiXiShop_ItemsCount[2] = Lua_GetDaHuaQiXiShop_ItemsTotalCount(g_DaHuaQiXiShop_OpenDay)
            DaHuaQiXi_Shop_Update()
            this:Show()
        elseif arg0 == "on_confirm" then
            local idInTable, buyCount = tonumber(arg1), tonumber(arg2)
            local index = DaHuaQiXi_Shop_GetIndex(idInTable)
            if index == -1 or DaHuaQiXi_Shop_Check(index, buyCount) == 0 then
                g_DaHuaQiXiShop_BuyingIndex = -1
                return
            end
            DaHuaQiXi_Shop_ConfirmBuy(idInTable, buyCount)
        elseif arg0 == "on_cancel" then
            g_DaHuaQiXiShop_BuyingIndex = -1
        elseif arg0 == "on_buy" then
            if this:IsVisible() then
                DaHuaQiXi_Shop_Update()
            end
        end
    elseif event == "DAHUAQIXI_DAIBI_CHANGED" then
        local daibiCount1, daibiCount2, weekGain1 = Lua_GetDaHuaQiXiShop_GetDaibiCount()
        if daibiCount1 then
            DaHuaQiXi_Shop_Currency1:SetText(ScriptGlobal_Format("#{DHSD_20240522_17}", daibiCount1))
            DaHuaQiXi_Shop_Currency2:SetText(ScriptGlobal_Format("#{DHSD_20240522_88}", weekGain1))
        end
	elseif event == "VIEW_RESOLUTION_CHANGED" or event == "ADJEST_UI_POS" then
		DaHuaQiXi_Shop_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		DaHuaQiXi_Shop_Close()
    elseif event == "DAHUAQIXI_CHANGE_WEEK" then
        if this:IsVisible() then
            g_DaHuaQiXiShop_NeedUpdateData = 1
            Clear_XSCRIPT()
                Set_XSCRIPT_Function_Name("OnClientAskData")
                Set_XSCRIPT_ScriptID(g_DaHuaQiXiShop_MainScriptId)
                Set_XSCRIPT_ParamCount(0)
            Send_XSCRIPT()
            PushDebugMessage("#{DHSD_20240522_68}") --商店因跨周已刷新
        end
	end
end

--************************
-- On_ResetPos
--************************
function DaHuaQiXi_Shop_On_ResetPos()
	DaHuaQiXi_Shop_Frame:SetProperty("UnifiedXPosition", g_DaHuaQiXiShop_Frame_UnifiedXPosition)
	DaHuaQiXi_Shop_Frame:SetProperty("UnifiedYPosition", g_DaHuaQiXiShop_Frame_UnifiedYPosition)
end

--************************
-- OnHiden
--************************
function DaHuaQiXi_Shop_OnHiden()
    DaHuaQiXi_Shop_Close()
end

--************************
-- 关闭界面
--************************
function DaHuaQiXi_Shop_Close()
    PushEvent("CLOSE_BOOTH") --关闭批量购买窗口Shop_MBuy
    g_DaHuaQiXiShop_CurTag = 1
    g_DaHuaQiXiShop_CurPage = 1
    g_DaHuaQiXiShop_ItemsInfo = {}
    g_DaHuaQiXiShop_BuyingIndex = -1
    g_DaHuaQiXiShop_BuyingCount = 0
    for i = 1, 2 do
        g_DaHuaQiXiShop_Page_Saved[i] = 1
    end
	this:Hide()
    if IsWindowShow("DaHua_DaiBiGouMai") then
        CloseWindow("DaHua_DaiBiGouMai", true)
    end
end

--************************
-- 通过表Id获取界面道具index
--************************
function DaHuaQiXi_Shop_GetIndex(idInTable)
    for i = 1, table.getn(g_DaHuaQiXiShop_ItemsInfo) do
        if g_DaHuaQiXiShop_ItemsInfo[i].ID == idInTable then
            return i
        end
    end
    return -1
end

--************************
-- 购买验证
--************************
function DaHuaQiXi_Shop_Check(index, buyCount)
    local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay < g_DaHuaQiXiShop_start_time or curDay > g_DaHuaQiXiShop_end_time then
		PushDebugMessage("#{DHSD_20240522_55}") -- 当前非活动期间，无法进行此操作。
		return 0
	end
	
	if IsInTServer() == 1 then
		PushDebugMessage("#{DHSD_20240522_4}") -- 无法在天荒古境或汴京参与该活动。
		return 0
	end

    -- 判断是否为安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return 0
	end
	-- 判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return 0
    end

    local nLevel = Player:GetLevel()
	if nLevel < g_DaHuaQiXiShop_BuyLevel then
		PushDebugMessage("#{DHSD_20240522_23}") -- 您的等级不足30级，无法进行此操作。
		return 0
	end

    -- local curDay = tonumber(DataPool:GetServerDayTime())
    -- if g_DaHuaQiXiShop_OpenDay ~= curDay then
	-- 	-- PushDebugMessage("#{DHSD_20240522_24}") -- 奖励已更新，请稍后重试。
    --     g_DaHuaQiXiShop_NeedUpdateData = 1
    --     DaHuaQiXi_Shop_Update()
    --     return 0
    -- end

	if type(g_DaHuaQiXiShop_ItemsInfo) ~= "table" or g_DaHuaQiXiShop_ItemsInfo[index] == nil then
	    return 0
    end

    if g_DaHuaQiXiShop_ItemsInfo[index].leftNum == 0 then
        PushDebugMessage("#{DHSD_20240522_25}") --该商品已售罄，购买失败。
		return 0
    end

    local itemId = g_DaHuaQiXiShop_ItemsInfo[index].itemId
    local itemNum = g_DaHuaQiXiShop_ItemsInfo[index].itemNum
    local itemNum = Lua_GetDaHuaQiXiShop_MaxNumCanBuy(itemId, itemNum) --计算空间后的最大购买组数（有空间不足的提示）
    if itemNum <= 0 then
        return 0
    end
    return 1
end

--************************
-- 购买商品
--************************
function DaHuaQiXi_Shop_Clicked(index)
    if g_DaHuaQiXiShop_BuyingIndex ~= -1 then --防止在购买没完成时购买
        return
    end

    if DaHuaQiXi_Shop_Check(index, 1) == 0 then
        return
    end

    local daibiCount1, daibiCount2, weekGain1 = Lua_GetDaHuaQiXiShop_GetDaibiCount()
	if not daibiCount1 then
		return
	end
    
    local daibiType = g_DaHuaQiXiShop_ItemsInfo[index].daibiType
    local daibiNum = g_DaHuaQiXiShop_ItemsInfo[index].daibiNum
    local playerCoin_Token = 0 --持有货币数量
	if daibiType == 1 then
		playerCoin_Token = daibiCount1
	elseif daibiType == 2 then
		playerCoin_Token = daibiCount2
    else
        return
	end

    if CheckBuyMult() == 1 then
        if playerCoin_Token < daibiNum then
            PushDebugMessage(ScriptGlobal_Format("#{DHSD_20240522_30}", g_DaHuaQiXiShop_Daibi_Strs[daibiType]))
        else
            g_DaHuaQiXiShop_BuyingIndex = index
            PushEvent("OPEN_YUANBAOSHOP_MULTI_BUYWND", g_DaHuaQiXiShop_ItemsInfo[index].ID, g_DaHuaQiXiShop_MainScriptId)
        end
    else
        if playerCoin_Token < daibiNum then
            PushDebugMessage(ScriptGlobal_Format("#{DHSD_20240522_29}", g_DaHuaQiXiShop_Daibi_Strs[daibiType]))
        else
            g_DaHuaQiXiShop_BuyingIndex = index
            local itemId = g_DaHuaQiXiShop_ItemsInfo[index].itemId
            local itemName = DataPool:Lua_GetItemNameByIndex(itemId)
            local str = ScriptGlobal_Format("#{DHSD_20240522_60}", daibiNum, 1, itemName)
            MessageBoxSelf3("DaHuaQiXi_Shop_OnConfirmed", {
                ["Content"] = str,
                ["Type"] = "YesNo"
            })
        end
    end
end

function DaHuaQiXi_Shop_OnConfirmed(strRet)
    if not strRet or not g_DaHuaQiXiShop_ItemsInfo[g_DaHuaQiXiShop_BuyingIndex] then
		return
	end
	if "Yes" == strRet or "Ok" == strRet then
        DaHuaQiXi_Shop_ConfirmBuy(g_DaHuaQiXiShop_ItemsInfo[g_DaHuaQiXiShop_BuyingIndex].ID, 1)
	end
    g_DaHuaQiXiShop_BuyingIndex = -1
end

--************************
-- 确认购买
--************************
function DaHuaQiXi_Shop_ConfirmBuy(ID, num)
    if g_DaHuaQiXiShop_ItemsInfo[g_DaHuaQiXiShop_BuyingIndex].ID ~= ID then
        PushDebugMessage("购买数据异常")
        return
    end

    g_DaHuaQiXiShop_BuyingCount = num
    local daibiNum = g_DaHuaQiXiShop_ItemsInfo[g_DaHuaQiXiShop_BuyingIndex].daibiNum
    local daibiType = g_DaHuaQiXiShop_ItemsInfo[g_DaHuaQiXiShop_BuyingIndex].daibiType
    local itemId = g_DaHuaQiXiShop_ItemsInfo[g_DaHuaQiXiShop_BuyingIndex].itemId
    local itemNum = g_DaHuaQiXiShop_ItemsInfo[g_DaHuaQiXiShop_BuyingIndex].itemNum * num

    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("OnClientBuyItem")
        Set_XSCRIPT_ScriptID(g_DaHuaQiXiShop_MainScriptId)
        Set_XSCRIPT_Parameter(0, g_DaHuaQiXiShop_ItemsInfo[g_DaHuaQiXiShop_BuyingIndex].ID)
        Set_XSCRIPT_Parameter(1, g_DaHuaQiXiShop_BuyingCount)
        Set_XSCRIPT_Parameter(2, g_DaHuaQiXiShop_CurWeek)
        Set_XSCRIPT_ParamCount(3)
    Send_XSCRIPT()
    g_DaHuaQiXiShop_BuyingIndex = -1
end

--************************
-- 向下翻页
--************************
function DaHuaQiXi_Shop_PageDown()
    if g_DaHuaQiXiShop_CurPage * g_DaHuaQiXiShop_PerPageCount < g_DaHuaQiXiShop_ItemsCount[g_DaHuaQiXiShop_CurTag] then
        g_DaHuaQiXiShop_CurPage = g_DaHuaQiXiShop_CurPage + 1
        g_DaHuaQiXiShop_Page_Saved[g_DaHuaQiXiShop_CurTag] = g_DaHuaQiXiShop_CurPage
        DaHuaQiXi_Shop_Update()
    end
end

--************************
-- 向上翻页
--************************
function DaHuaQiXi_Shop_PageUp()
    if g_DaHuaQiXiShop_CurPage > 1 then
        g_DaHuaQiXiShop_CurPage = g_DaHuaQiXiShop_CurPage - 1
        g_DaHuaQiXiShop_Page_Saved[g_DaHuaQiXiShop_CurTag] = g_DaHuaQiXiShop_CurPage
        DaHuaQiXi_Shop_Update()
    end
end

--************************
-- 切换分页
--************************
function DaHuaQiXi_Shop_Fenye_Click(id)
    g_DaHuaQiXiShop_CurTag = id
    g_DaHuaQiXiShop_CurPage = g_DaHuaQiXiShop_Page_Saved[g_DaHuaQiXiShop_CurTag]
    DaHuaQiXi_Shop_Update()
end

--************************
-- 刷新界面
--************************
function DaHuaQiXi_Shop_Update()
    if g_DaHuaQiXiShop_NeedUpdateData == 1 then --需要向服务器请求新的数据，收到后再刷新
        Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name("OnClientAskData")
            Set_XSCRIPT_ScriptID(g_DaHuaQiXiShop_MainScriptId)
            Set_XSCRIPT_ParamCount(0)
        Send_XSCRIPT()
        PushDebugMessage("#{DHSD_20240522_24}") --奖励已更新，请稍后重试。
        return
    end
    g_DaHuaQiXiShop_BuyingIndex = -1
    PushEvent("CLOSE_BOOTH") --关闭批量购买窗口Shop_MBuy

    -- 元宝兑换代币按钮显隐
    local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay < g_DaHuaQiXiShop_CurrencyBuy_start_time or curDay > g_DaHuaQiXiShop_CurrencyBuy_end_time then
		DaHuaQiXi_Shop_Currency2_buy:Hide()
    else
        DaHuaQiXi_Shop_Currency2_buy:Show()
    end

    g_DaHuaQiXiShop_ItemsInfo = {}
    g_DaHuaQiXiShop_ItemsInfo = Lua_GetDaHuaQiXiShopData(g_DaHuaQiXiShop_CurTag, g_DaHuaQiXiShop_CurPage, g_DaHuaQiXiShop_PerPageCount, g_DaHuaQiXiShop_OpenDay)
	if type(g_DaHuaQiXiShop_ItemsInfo) ~= "table" then
        PushDebugMessage("DaHuaQiXiShop_Update failed 0")
		return
    end

    local item_count = table.getn(g_DaHuaQiXiShop_ItemsInfo)
    for i = 1, item_count do
        g_DaHuaQiXiShop_UIList.box[i]:Show()
        DaHuaQiXi_Shop_UpdateItemUI(i)
    end
    for i = item_count + 1, g_DaHuaQiXiShop_PerPageCount do
        g_DaHuaQiXiShop_UIList.box[i]:Hide()
    end
    
    -- if item_count > 0 then
        DaHuaQiXi_Shop_UpdatePageUI()
    -- end
end

--************************
-- 刷新某商品
--************************
function DaHuaQiXi_Shop_UpdateItemUI(i)
    local itemId = g_DaHuaQiXiShop_ItemsInfo[i].itemId
    local itemNum = 1
    local limitType = g_DaHuaQiXiShop_ItemsInfo[i].limitType
    local limitNum = g_DaHuaQiXiShop_ItemsInfo[i].limitNum
    local daibiType = g_DaHuaQiXiShop_ItemsInfo[i].daibiType
    local daibiNum = g_DaHuaQiXiShop_ItemsInfo[i].daibiNum
    local leftNum = g_DaHuaQiXiShop_ItemsInfo[i].leftNum
    
    local theAction = DataPool:CreateBindActionItemForShow(itemId, itemNum)
    local actionId = theAction:GetID()
    if actionId ~= 0 then
        g_DaHuaQiXiShop_UIList.abtn[i]:SetActionItem(actionId)
    end

    -- 上方显示限购数量和标记
    if leftNum == -1 then --不限购
        g_DaHuaQiXiShop_UIList.cnt[i]:Hide()
        g_DaHuaQiXiShop_UIList.cntb[i]:Hide()
        g_DaHuaQiXiShop_UIList.mask[i]:Hide()
        g_DaHuaQiXiShop_UIList.day[i]:Hide()
        g_DaHuaQiXiShop_UIList.week[i]:Hide()
        g_DaHuaQiXiShop_UIList.xian[i]:Hide()
    else
        g_DaHuaQiXiShop_UIList.cnt[i]:Show()
        g_DaHuaQiXiShop_UIList.cntb[i]:Show()
        g_DaHuaQiXiShop_UIList.cnt[i]:SetText(leftNum)
        if leftNum == 0 then
            g_DaHuaQiXiShop_UIList.mask[i]:Show()
        else
            g_DaHuaQiXiShop_UIList.mask[i]:Hide()
        end
        
        if limitType == 2 then --永久限购
            g_DaHuaQiXiShop_UIList.xian[i]:Show()
            g_DaHuaQiXiShop_UIList.week[i]:Hide()
            g_DaHuaQiXiShop_UIList.day[i]:Hide()
        elseif limitType == 1 then --周限购
            g_DaHuaQiXiShop_UIList.week[i]:Show()
            g_DaHuaQiXiShop_UIList.xian[i]:Hide()
            g_DaHuaQiXiShop_UIList.day[i]:Hide()
        end
    end
    -- 折扣
    g_DaHuaQiXiShop_UIList.disi[i]:Hide()
    
    -- 货币图片
    -- g_DaHuaQiXiShop_UIList.sgn[i]:SetProperty("Image", g_DaHuaQiXiShop_Daibi_Icons[huobi])
    if g_DaHuaQiXiShop_UIList.sgn[i] then g_DaHuaQiXiShop_UIList.sgn[i]:Hide() end --不再显示图标
    -- 物品名称
    g_DaHuaQiXiShop_UIList.name[i]:SetText(ScriptGlobal_Format("#{DHSD_20240522_19}", DataPool:Lua_GetItemNameByIndex(itemId)))
    -- 价格
    g_DaHuaQiXiShop_UIList.prz[i]:SetText(ScriptGlobal_Format("#{DHSD_20240522_17}", daibiNum))
end

--************************
-- 刷新Page相关UI
--************************
function DaHuaQiXi_Shop_UpdatePageUI()
    -- if not g_DaHuaQiXiShop_ItemsInfo[1] then
    --     return
    -- end

    -- 设置代币数量
    local daibiCount1, daibiCount2, weekGain1 = Lua_GetDaHuaQiXiShop_GetDaibiCount()
    if daibiCount1 then
        DaHuaQiXi_Shop_Currency1:SetText(ScriptGlobal_Format("#{DHSD_20240522_17}", daibiCount1))
        DaHuaQiXi_Shop_Currency1:SetToolTip("#{DHSD_20240522_20}")
        DaHuaQiXi_Shop_Currency2:SetText(ScriptGlobal_Format("#{DHSD_20240522_88}", weekGain1))
        DaHuaQiXi_Shop_Currency2:SetToolTip("#{DHSD_20240522_89}")
    end

    -- 设置页签按钮的选中状态
    -- _G["DaHuaQiXi_Shop_Fenye_Button01"]:SetCheck(g_DaHuaQiXiShop_CurTag == 1 and 1 or 0)
    -- _G["DaHuaQiXi_Shop_Fenye_Button02"]:SetCheck(g_DaHuaQiXiShop_CurTag == 2 and 1 or 0)

    if g_DaHuaQiXiShop_CurPage == 1 then
        DaHuaQiXi_Shop_UpPage:Disable()
    else
        DaHuaQiXi_Shop_UpPage:Enable()
    end
    
    local TotalCount = g_DaHuaQiXiShop_ItemsCount[g_DaHuaQiXiShop_CurTag]
    if not TotalCount then
        PushDebugMessage("大话七夕商店数据错误")
        TotalCount = 0
    end

    if g_DaHuaQiXiShop_CurPage * g_DaHuaQiXiShop_PerPageCount >= TotalCount then
        DaHuaQiXi_Shop_DownPage:Disable()
    else
        DaHuaQiXi_Shop_DownPage:Enable()
    end

    local totalPageCount = 1
    if TotalCount > g_DaHuaQiXiShop_PerPageCount then
        totalPageCount = math.floor(TotalCount / g_DaHuaQiXiShop_PerPageCount)
        if math.mod(TotalCount, g_DaHuaQiXiShop_PerPageCount) > 0 then
            totalPageCount = totalPageCount + 1
        end
    end
    DaHuaQiXi_Shop_CurrentlyPage:SetText("#L" .. g_DaHuaQiXiShop_CurPage .. "/" .. totalPageCount)
end

--************************************
-- 帮助按钮
--************************************
function DaHuaQiXi_Shop_Help_Clicked()
    PushEvent("CCSHOP_HELP", 211)
end

--************************************
-- 打开批量购买标记
--************************************
function DaHuaQiXi_Shop_MultiBuy()
    PrepearBuyMult()
end

function DaHuaQiXi_Shop_CurrencyBuy()
    PushEvent("DAHUASHOP_DAIBI_GOUMAI", g_DaHuaQiXiShop_CurTag)
end

function DaHuaQiXi_Shop_OnView()
	Clear_XSCRIPT()
        Set_XSCRIPT_ScriptID(888051)
        Set_XSCRIPT_Function_Name("DressPreview")
        Set_XSCRIPT_Parameter(0, 10127791)
        Set_XSCRIPT_Parameter(1, 234) --hairId
        Set_XSCRIPT_Parameter(2, 175) --faceid
        Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end