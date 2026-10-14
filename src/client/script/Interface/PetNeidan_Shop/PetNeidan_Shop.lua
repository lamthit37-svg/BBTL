-- 23Q2 内丹商店 Created by wanghongao

local g_PetNeidan_Shop_Type1 = "" --当前一级页签名
local g_PetNeidan_Shop_Type2 = "" --当前二级页签名
local g_PetNeidan_Shop_Type_Saved = {} --保存上一次打开某个一级页签时，选中的二级页签名

local g_PetNeidan_Shop_CurPage = 1 --当前页数
local g_PetNeidan_Shop_PerPageCount = 15 --每一页显示的商品数量
local g_PetNeidan_Shop_ItemsCount = {} --某个页签下的商品总数量
local g_PetNeidan_Shop_Page_Saved = {} --保存上一次打开某个二级页签时，在浏览第几页

local g_PetNeidan_Shop_Frame_UnifiedXPosition
local g_PetNeidan_Shop_Frame_UnifiedYPosition

local g_PetNeidan_Shop_PageName_1 = {} --一级页签名列表
local g_PetNeidan_Shop_PageName_2 = {} --二级页签名字典
local g_PetNeidan_Shop_PageNameToolTip = {
    -- 一级页签悬浮提示
    [1] = {"#{NDSD_20230510_49}", "#{NDSD_20230510_10}", "#{NDSD_20230510_12}", "#{NDSD_20230510_47}"},
    -- 二级页签悬浮提示
    [2] = {
        {"#{NDSD_20230510_51}", "#{NDSD_20230510_53}"},
        {"#{NDSD_20230510_41}", "#{NDSD_20230510_43}", "#{NDSD_20230510_45}"},
        {"#{NDSD_20230510_41}", "#{NDSD_20230510_43}", "#{NDSD_20230510_45}"},
        {"#{NDSD_20230510_41}", "#{NDSD_20230510_43}", "#{NDSD_20230510_45}"}
    }
}

local g_PetNeidan_Shop_UIList = {
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
local g_PetNeidan_Shop_ItemsInfo = {}
local g_PetNeidan_Shop_BuyingIndex = -1
local g_PetNeidan_Shop_BuyingCount = 0
local g_PetNeidan_Shop_CurWeek = 0
local g_PetNeidan_Shop_NeedUpdateData = 0
local g_PetNeidan_Shop_CareObj = 0
local g_PetNeidan_Shop_ServerObj = 0

local g_PetNeidan_Shop_HuoBi_Icons = {
    "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon2", --代币1
    "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon2", --代币2
    "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon2", --代币3
    "set:Pretty01 image:Small_Yuanbao", --元宝
    "set:CommonFrame38 image:Icon_GoldCoin2", --金币
}
local g_PetNeidan_Shop_HuoBi_Strs = {
    "#{NDSD_20230510_29}", --精品元液
    "#{NDSD_20230510_30}", --珍品元液
    "#{NDSD_20230510_31}", --神品元液
    "#{NDSD_20230510_60}", --元宝
    "#{TLBC_090617_12}", --金币
}

-- 将以下道具替换为展示道具
local g_PetNeidan_Shop_ItemId_Show = {
    [38007513] = 39924338,
    [38007514] = 39924336,
    [38007515] = 39924339,
}

--************************
-- PreLoad
--************************
function PetNeidan_Shop_PreLoad()
    this:RegisterEvent("NEIDAN_SHOP_UPDATE", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("UPDATE_YUANBAO", false)
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this:RegisterEvent("NEIDAN_DAIBI_CHANGED", false)
    this:RegisterEvent("CHANGE_WEEK", false)
    this:RegisterEvent("OBJECT_CARED_EVENT",false)
end

--************************
-- OnLoad
--************************
function PetNeidan_Shop_OnLoad() 
    if table.getn(g_PetNeidan_Shop_UIList.box) > 0 then
        return
    end
    for i = 1, g_PetNeidan_Shop_PerPageCount do
        local str = "PetNeidan_ShopItem"..i
        g_PetNeidan_Shop_UIList.box[i] = _G[str]
        g_PetNeidan_Shop_UIList.cnt[i] = _G[str.."_Num"]
        g_PetNeidan_Shop_UIList.cntb[i]= _G[str.."_NumBK"]
        g_PetNeidan_Shop_UIList.sgn[i] = _G[str.."_CostSign"]
        g_PetNeidan_Shop_UIList.prz[i] = _G[str.."_Cost"]
        -- g_PetNeidan_Shop_UIList.btn[i] = _G[str.."Btn"]
        g_PetNeidan_Shop_UIList.abtn[i]= _G[str.."_Icon"]
        g_PetNeidan_Shop_UIList.disi[i]= _G[str.."_Icon_Discount"]
        g_PetNeidan_Shop_UIList.disc[i]= _G[str.."_Discount"]
        g_PetNeidan_Shop_UIList.disp[i]= _G[str.."_DiscountBK"]
        g_PetNeidan_Shop_UIList.disc[i]:Hide()
        g_PetNeidan_Shop_UIList.disp[i]:Hide()
        g_PetNeidan_Shop_UIList.name[i]= _G[str.."_Name"]
        g_PetNeidan_Shop_UIList.mask[i]= _G[str.."_IconMark"]
        g_PetNeidan_Shop_UIList.day[i] = _G[str.."_IconMark1"]
        g_PetNeidan_Shop_UIList.week[i]= _G[str.."_IconMark2"]
        g_PetNeidan_Shop_UIList.xian[i]= _G[str.."_IconMark3"]
        g_PetNeidan_Shop_UIList.abtn[i]:SetEvent("MouseLClick", string.format("PetNeidan_Shop_Clicked(%d)", i))
    end
    g_PetNeidan_Shop_Frame_UnifiedXPosition = PetNeidan_Shop_Frame:GetProperty("UnifiedXPosition") 
	g_PetNeidan_Shop_Frame_UnifiedYPosition = PetNeidan_Shop_Frame:GetProperty("UnifiedYPosition")

    -- 设置一级页签
    g_PetNeidan_Shop_PageName_1 = Lua_GetNeiDanShopPages()
    if type(g_PetNeidan_Shop_PageName_1) ~= "table" or table.getn(g_PetNeidan_Shop_PageName_1) <= 0 then
        PushDebugMessage("PetNeidan_Shop_OnLoad failed 0")
        return
    end
    for i = 1, 4 do
        if g_PetNeidan_Shop_PageName_1[i] then
            _G["PetNeidan_Shop_Fenye_Button0"..i]:Show()
            _G["PetNeidan_Shop_Fenye_Button0"..i]:SetText("#Y"..g_PetNeidan_Shop_PageName_1[i])
            _G["PetNeidan_Shop_Fenye_Button0"..i]:SetToolTip(g_PetNeidan_Shop_PageNameToolTip[1][i])
            g_PetNeidan_Shop_ItemsCount[g_PetNeidan_Shop_PageName_1[i]] = {}
            g_PetNeidan_Shop_Page_Saved[g_PetNeidan_Shop_PageName_1[i]] = {}
        else
            _G["PetNeidan_Shop_Fenye_Button0"..i]:Hide()
        end
    end
    g_PetNeidan_Shop_Type1 = g_PetNeidan_Shop_PageName_1[1]

    -- 设置二级页签
    for i = 1, table.getn(g_PetNeidan_Shop_PageName_1) do
        local pageName = g_PetNeidan_Shop_PageName_1[i]
        g_PetNeidan_Shop_PageName_2[pageName] = Lua_GetNeiDanShopPages(pageName)
        if type(g_PetNeidan_Shop_PageName_2[pageName]) ~= "table" or table.getn(g_PetNeidan_Shop_PageName_2[pageName]) <= 0 then
            PushDebugMessage("PetNeidan_Shop_OnLoad failed "..i)
            return
        end
        for j = 1, table.getn(g_PetNeidan_Shop_PageName_2[pageName]) do
            local pageName2 = g_PetNeidan_Shop_PageName_2[pageName][j]
            g_PetNeidan_Shop_Page_Saved[pageName][pageName2] = 1
            g_PetNeidan_Shop_ItemsCount[pageName][pageName2] = Lua_GetNeiDanShop_ItemsTotalCount(pageName, pageName2)
            -- Lua_TDU_Log(string.format("PetNeidan_Shop_OnLoad %s,%s,cnt=%d", pageName, pageName2, g_PetNeidan_Shop_ItemsCount[pageName][pageName2]))
        end
    end
    g_PetNeidan_Shop_Type2 = g_PetNeidan_Shop_PageName_2[g_PetNeidan_Shop_Type1][1]
    PetNeidan_Shop_SetPageName(1)
end

--************************
-- OnEvent
--************************
function PetNeidan_Shop_OnEvent(event)
	if event == "NEIDAN_SHOP_UPDATE" then
        if arg0 == "show" then
            if arg1 and arg2 then
                g_PetNeidan_Shop_CurWeek = tonumber(arg1)
                g_PetNeidan_Shop_NeedUpdateData = 0
                if tonumber(arg2) > 0 then
                    g_PetNeidan_Shop_ServerObj = tonumber(arg2)
                    g_PetNeidan_Shop_CareObj = DataPool:GetNPCIDByServerID(g_PetNeidan_Shop_ServerObj)
			        this:CareObject(g_PetNeidan_Shop_CareObj, 1, "PetNeidan_Shop")
                end
                PetNeidan_Shop_Update()
                this:Show()
            end
        elseif arg0 == "on_confirm" then
            PetNeidan_Shop_ShowSecConfirm(tonumber(arg1), tonumber(arg2))
        elseif arg0 == "on_cancle" then
            g_PetNeidan_Shop_BuyingIndex = -1
        elseif arg0 == "on_buy" then
            if this:IsVisible() then
                PetNeidan_Shop_Update()
            end
        end

    elseif event == "UPDATE_YUANBAO" then
        local yuanbao = tostring(Player:GetData("YUANBAO"))
        PetNeidan_Shop_Currency4:SetText(ScriptGlobal_Format("#{NDSD_20230510_20}", yuanbao))
    elseif event == "MONEY_CHANGE_EX" then
        local jinbi = tostring(Player:GetData("MONEY"))
        PetNeidan_Shop_Currency5:SetText(ScriptGlobal_Format("#{NDSD_20230510_21}", jinbi))
    elseif event == "NEIDAN_DAIBI_CHANGED" then
        PetNeidan_Shop_Currency1:SetText(ScriptGlobal_Format("#{NDSD_20230510_17}", arg0))
        PetNeidan_Shop_Currency2:SetText(ScriptGlobal_Format("#{NDSD_20230510_18}", arg2))
        PetNeidan_Shop_Currency3:SetText(ScriptGlobal_Format("#{NDSD_20230510_19}", arg1))

	elseif event == "VIEW_RESOLUTION_CHANGED" or event == "ADJEST_UI_POS" then
		PetNeidan_Shop_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		PetNeidan_Shop_Close()

    elseif event == "CHANGE_WEEK" then
        if this:IsVisible() then
            g_PetNeidan_Shop_NeedUpdateData = 1
            Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name("OnClientAskData")
            Set_XSCRIPT_ScriptID(505111)
            Set_XSCRIPT_ParamCount(0)
            Send_XSCRIPT()
            PushDebugMessage("#{NDSD_20230510_54}") --商店因跨周已刷新
        end

    elseif event == "OBJECT_CARED_EVENT" then
		if tonumber(arg0) ~= g_PetNeidan_Shop_CareObj then
			return
		end
		if (arg1 == "distance" and tonumber(arg2) > 5) or arg1 == "destroy" then
			PetNeidan_Shop_Close()
		end
	end
end

--************************
-- On_ResetPos
--************************
function PetNeidan_Shop_On_ResetPos()
	PetNeidan_Shop_Frame:SetProperty("UnifiedXPosition", g_PetNeidan_Shop_Frame_UnifiedXPosition)
	PetNeidan_Shop_Frame:SetProperty("UnifiedYPosition", g_PetNeidan_Shop_Frame_UnifiedYPosition)
end

--************************
-- OnHiden
--************************
function PetNeidan_Shop_OnHiden()
    PetNeidan_Shop_Close()
end

--************************
-- 关闭界面
--************************
function PetNeidan_Shop_Close()
    PushEvent("CLOSE_BOOTH") --关闭批量购买窗口Shop_MBuy
    if g_PetNeidan_Shop_PageName_1[1] ~= g_PetNeidan_Shop_Type1 then
        g_PetNeidan_Shop_Type1 = g_PetNeidan_Shop_PageName_1[1]
        PetNeidan_Shop_SetPageName(1)
    end
    g_PetNeidan_Shop_Type2 = g_PetNeidan_Shop_PageName_2[g_PetNeidan_Shop_Type1][1]
    g_PetNeidan_Shop_Type_Saved = {}
    g_PetNeidan_Shop_CurPage = 1
    g_PetNeidan_Shop_ItemsInfo = {}
    g_PetNeidan_Shop_BuyingIndex = -1
    g_PetNeidan_Shop_BuyingCount = 0
    for i = 1, table.getn(g_PetNeidan_Shop_PageName_1) do
        local pageName1 = g_PetNeidan_Shop_PageName_1[i]
        for j = 1, table.getn(g_PetNeidan_Shop_PageName_2[pageName1]) do
            local pageName2 = g_PetNeidan_Shop_PageName_2[pageName1][j]
            g_PetNeidan_Shop_Page_Saved[pageName1][pageName2] = 1
        end
    end
    this:CareObject(g_PetNeidan_Shop_CareObj, 0, "PetNeidan_Shop")
	this:Hide()
end

--************************
-- 购买商品
--************************
function PetNeidan_Shop_Clicked(index)
    if g_PetNeidan_Shop_BuyingIndex ~= -1 then --防止在购买没完成时购买
        return
    end

    -- 判断是否为安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	-- 判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
    end
	if type(g_PetNeidan_Shop_ItemsInfo) ~= "table" or g_PetNeidan_Shop_ItemsInfo[index] == nil then
	    return
    end
    if g_PetNeidan_Shop_ItemsInfo[index].leftnum == 0 then
        PushDebugMessage("#{NDSD_20230510_24}") --该商品已售罄，购买失败。
		return
    end

    local itemId = g_PetNeidan_Shop_ItemsInfo[index].itemid
    local itemNum = g_PetNeidan_Shop_ItemsInfo[index].num
    local num = Lua_GetNeiDanShop_MaxNumCanBuy(itemId, itemNum) --计算空间后的最大购买组数（有空间不足的提示）
    if num <= 0 then
        return
    end

    g_PetNeidan_Shop_BuyingIndex = index
    PushEvent("OPEN_YUANBAOSHOP_MULTI_BUYWND", g_PetNeidan_Shop_ItemsInfo[index].ID, 505111, g_PetNeidan_Shop_CareObj)
end

--************************
-- 弹出二次确认
--************************
function PetNeidan_Shop_ShowSecConfirm(ID, num)
    if g_PetNeidan_Shop_ItemsInfo[g_PetNeidan_Shop_BuyingIndex].ID ~= ID then
        PushDebugMessage("购买数据异常")
        return
    end
    g_PetNeidan_Shop_BuyingCount = num
    local price = g_PetNeidan_Shop_ItemsInfo[g_PetNeidan_Shop_BuyingIndex].price
    local huobi = g_PetNeidan_Shop_ItemsInfo[g_PetNeidan_Shop_BuyingIndex].huobi
    local itemId = g_PetNeidan_Shop_ItemsInfo[g_PetNeidan_Shop_BuyingIndex].itemid
    local itemNum = g_PetNeidan_Shop_ItemsInfo[g_PetNeidan_Shop_BuyingIndex].num * num
    local str
    if huobi == 5 then
        str = ScriptGlobal_Format("#{NDSD_20230510_28}", price * num, itemNum, DataPool:Lua_GetItemNameByIndex(itemId))
        -- str = string.format("#cfff263    您确定要消耗#G#{_MONEY%d}#cfff263,兑换#G%d#cfff263个#G%s#cfff263吗？", price * num, itemNum, DataPool:Lua_GetItemNameByIndex(itemId))
    else
        str = ScriptGlobal_Format("#{NDSD_20230510_27}", price * num, g_PetNeidan_Shop_HuoBi_Strs[huobi], itemNum, DataPool:Lua_GetItemNameByIndex(itemId)) --您确定要消耗%s0个%s1,兑换%s2个%s3吗？ 
    end
    MessageBoxSelf3("PetNeidan_Shop_OnComfirmed_BuyNeiDan", {
        ["Content"] = str,
        ["CaredObj"] = g_PetNeidan_Shop_CareObj,
        ["Type"] = "YesNo"
    })
end

--************************
-- 二次确认购买
--************************
function PetNeidan_Shop_OnComfirmed_BuyNeiDan(strRet)
    if not strRet or not g_PetNeidan_Shop_ItemsInfo[g_PetNeidan_Shop_BuyingIndex] then
		return
	end
	if "Yes" == strRet or "Ok" == strRet then
		Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("OnClientBuyItem")
        Set_XSCRIPT_ScriptID( 505111 )
        Set_XSCRIPT_Parameter(0, g_PetNeidan_Shop_ItemsInfo[g_PetNeidan_Shop_BuyingIndex].ID)
        Set_XSCRIPT_Parameter(1, g_PetNeidan_Shop_BuyingCount)
        Set_XSCRIPT_Parameter(2, g_PetNeidan_Shop_CurWeek)
        Set_XSCRIPT_Parameter(3, g_PetNeidan_Shop_ServerObj)
        Set_XSCRIPT_ParamCount(4)
        Send_XSCRIPT()
	end
    g_PetNeidan_Shop_BuyingIndex = -1
end

--************************
-- 向下翻页
--************************
function PetNeidan_Shop_PageDown()
    if g_PetNeidan_Shop_CurPage * g_PetNeidan_Shop_PerPageCount < g_PetNeidan_Shop_ItemsCount[g_PetNeidan_Shop_Type1][g_PetNeidan_Shop_Type2] then
        g_PetNeidan_Shop_CurPage = g_PetNeidan_Shop_CurPage + 1
        g_PetNeidan_Shop_Page_Saved[g_PetNeidan_Shop_Type1][g_PetNeidan_Shop_Type2] = g_PetNeidan_Shop_CurPage
        PetNeidan_Shop_Update()
    end
end

--************************
-- 向上翻页
--************************
function PetNeidan_Shop_PageUp()
    if g_PetNeidan_Shop_CurPage > 1 then
        g_PetNeidan_Shop_CurPage = g_PetNeidan_Shop_CurPage - 1
        g_PetNeidan_Shop_Page_Saved[g_PetNeidan_Shop_Type1][g_PetNeidan_Shop_Type2] = g_PetNeidan_Shop_CurPage
        PetNeidan_Shop_Update()
    end
end

--************************
-- 切换分页（一级页签）
--************************
function PetNeidan_Shop_Fenye_Click(id)
    if not g_PetNeidan_Shop_PageName_1[id] then
        return
    end
    if g_PetNeidan_Shop_Type1 == g_PetNeidan_Shop_PageName_1[id] then
        return
    end

    g_PetNeidan_Shop_Type1 = g_PetNeidan_Shop_PageName_1[id]
    g_PetNeidan_Shop_Type2 = PetNeidan_Shop_GetSavedPageName2()
    g_PetNeidan_Shop_CurPage = g_PetNeidan_Shop_Page_Saved[g_PetNeidan_Shop_Type1][g_PetNeidan_Shop_Type2]
    PetNeidan_Shop_SetPageName(id)
    PetNeidan_Shop_Update()
end

--************************
-- 切换分页（二级页签）
--************************
function PetNeidan_Shop_Fenye2_Click(id)
    local pageName2 = g_PetNeidan_Shop_PageName_2[g_PetNeidan_Shop_Type1][id]
    if not pageName2 then
        return
    end
    if g_PetNeidan_Shop_Type2 == pageName2 then
        return
    end
    g_PetNeidan_Shop_Type_Saved[g_PetNeidan_Shop_Type1] = pageName2

    g_PetNeidan_Shop_Type2 = pageName2
    g_PetNeidan_Shop_CurPage = g_PetNeidan_Shop_Page_Saved[g_PetNeidan_Shop_Type1][g_PetNeidan_Shop_Type2]
    PetNeidan_Shop_Update()
end

--************************
-- 获取保存的二级页签名
--************************
function PetNeidan_Shop_GetSavedPageName2()
    if g_PetNeidan_Shop_Type_Saved[g_PetNeidan_Shop_Type1] then
        return g_PetNeidan_Shop_Type_Saved[g_PetNeidan_Shop_Type1]
    else
        -- 没有保存，则默认选中第一个
        return g_PetNeidan_Shop_PageName_2[g_PetNeidan_Shop_Type1][1]
    end
end

--************************
-- 刷新界面
--************************
function PetNeidan_Shop_Update()
    if g_PetNeidan_Shop_NeedUpdateData == 1 then --需要向服务器请求新的数据，收到后再刷新
        Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("OnClientAskData")
        Set_XSCRIPT_ScriptID(505111)
        Set_XSCRIPT_ParamCount(0)
        Send_XSCRIPT()
        PushDebugMessage("#{NDSD_20230510_54}") --商店因跨周已刷新
        return
    end
    g_PetNeidan_Shop_BuyingIndex = -1
    PushEvent("CLOSE_BOOTH") --关闭批量购买窗口Shop_MBuy

    g_PetNeidan_Shop_ItemsInfo = {}
    g_PetNeidan_Shop_ItemsInfo = Lua_GetNeiDanShopData(g_PetNeidan_Shop_Type1, g_PetNeidan_Shop_Type2, g_PetNeidan_Shop_CurPage, g_PetNeidan_Shop_PerPageCount)
	if type(g_PetNeidan_Shop_ItemsInfo) ~= "table" then
        PushDebugMessage("PetNeidan_Shop_Update failed 0")
		return
    end

    local item_count = table.getn(g_PetNeidan_Shop_ItemsInfo)
    for i = 1, item_count do
        g_PetNeidan_Shop_UIList.box[i]:Show()
        PetNeiDan_Shop_UpdateItemUI(i)
    end
    for i = item_count + 1, g_PetNeidan_Shop_PerPageCount do
        g_PetNeidan_Shop_UIList.box[i]:Hide()
    end
    
    PetNeiDan_Shop_UpdatePageUI()
end

--************************
-- 刷新某商品
--************************
function PetNeiDan_Shop_UpdateItemUI(i)
    local itemid = g_PetNeidan_Shop_ItemsInfo[i].itemid
    local num    = g_PetNeidan_Shop_ItemsInfo[i].num
    local huobi  = g_PetNeidan_Shop_ItemsInfo[i].huobi
    local price  = g_PetNeidan_Shop_ItemsInfo[i].price
    local leftnum= g_PetNeidan_Shop_ItemsInfo[i].leftnum
    local zhekou = g_PetNeidan_Shop_ItemsInfo[i].zhekou
    
    -- 展示物品
    if g_PetNeidan_Shop_ItemId_Show[itemid] then
        itemid = g_PetNeidan_Shop_ItemId_Show[itemid]
    end
    local theAction = DataPool:CreateBindActionItemForShow(itemid, num)
    local actionId = theAction:GetID()
    if actionId ~= 0 then
        g_PetNeidan_Shop_UIList.abtn[i]:SetActionItem(actionId)
    end

    -- 上方显示限购数量和标记
    if leftnum == -1 then --不限购
        g_PetNeidan_Shop_UIList.cnt[i]:Hide()
        g_PetNeidan_Shop_UIList.cntb[i]:Hide()
        g_PetNeidan_Shop_UIList.mask[i]:Hide()
        g_PetNeidan_Shop_UIList.day[i]:Hide()
        g_PetNeidan_Shop_UIList.week[i]:Hide()
        g_PetNeidan_Shop_UIList.xian[i]:Hide()
    else
        g_PetNeidan_Shop_UIList.cnt[i]:Show()
        g_PetNeidan_Shop_UIList.cntb[i]:Show()
        g_PetNeidan_Shop_UIList.cnt[i]:SetText(tostring(leftnum))
        if leftnum == 0 then
            g_PetNeidan_Shop_UIList.mask[i]:Show()
        else
            g_PetNeidan_Shop_UIList.mask[i]:Hide()
        end
        local limit_type = g_PetNeidan_Shop_ItemsInfo[i].limit_type
        if limit_type == 2 then --永久限购
            g_PetNeidan_Shop_UIList.xian[i]:Show()
            g_PetNeidan_Shop_UIList.week[i]:Hide()
            g_PetNeidan_Shop_UIList.day[i]:Hide()
        elseif limit_type == 1 then --周限购
            g_PetNeidan_Shop_UIList.week[i]:Show()
            g_PetNeidan_Shop_UIList.xian[i]:Hide()
            g_PetNeidan_Shop_UIList.day[i]:Hide()
        else --日限购
            g_PetNeidan_Shop_UIList.week[i]:Hide()
            g_PetNeidan_Shop_UIList.xian[i]:Hide()
            g_PetNeidan_Shop_UIList.day[i]:Show()
        end
    end

    -- 折扣
    if zhekou > 0 then
        -- local n1 = math.floor(zhekou / 10)
        -- local n2 = zhekou - n1 * 10
        -- g_PetNeidan_Shop_UIList.disc[i]:SetText(ScriptGlobal_Format("#{NDSD_20230510_13}", n1.."."..n2))
        -- g_PetNeidan_Shop_UIList.disc[i]:Show()
        -- g_PetNeidan_Shop_UIList.disp[i]:Show()
        g_PetNeidan_Shop_UIList.disi[i]:Show()
    else
        -- g_PetNeidan_Shop_UIList.disc[i]:Hide()
        -- g_PetNeidan_Shop_UIList.disp[i]:Hide()
        g_PetNeidan_Shop_UIList.disi[i]:Hide()
    end
    
    -- 货币图片
    -- g_PetNeidan_Shop_UIList.sgn[i]:SetProperty("Image", g_PetNeidan_Shop_HuoBi_Icons[huobi])
    if g_PetNeidan_Shop_UIList.sgn[i] then g_PetNeidan_Shop_UIList.sgn[i]:Hide() end --不再显示图标
    -- 物品名称
    g_PetNeidan_Shop_UIList.name[i]:SetText(DataPool:Lua_GetItemNameByIndex(itemid))

    -- 价格
    local strDic = {
        "#{NDSD_20230510_17}",
        "#{NDSD_20230510_18}",
        "#{NDSD_20230510_19}",
        "#{NDSD_20230510_20}",
        "#{NDSD_20230510_21}"
    }
    g_PetNeidan_Shop_UIList.prz[i]:SetText("#cfff263"..ScriptGlobal_Format(strDic[huobi], price))
end

--************************
-- 刷新Page相关UI
--************************
function PetNeiDan_Shop_UpdatePageUI()
    if not g_PetNeidan_Shop_ItemsInfo[1] then return end
    local huobi_type = g_PetNeidan_Shop_ItemsInfo[1].huobi
    
    -- 用元宝或金币买
    if huobi_type >= 4 then
        PetNeidan_Shop_CurrencyClient2:Show()
        PetNeidan_Shop_CurrencyClient1:Hide()
        local yuanbao = tostring(Player:GetData("YUANBAO"))
        PetNeidan_Shop_Currency4:SetText(ScriptGlobal_Format("#{NDSD_20230510_20}", yuanbao))
        local jinbi = tostring(Player:GetData("MONEY"))
        PetNeidan_Shop_Currency5:SetText(ScriptGlobal_Format("#{NDSD_20230510_21}", jinbi))

    -- 用代币买
    else
        PetNeidan_Shop_CurrencyClient1:Show()
        PetNeidan_Shop_CurrencyClient2:Hide()
        PetNeidan_Shop_Currency1:SetText(ScriptGlobal_Format("#{NDSD_20230510_17}", LuaFnGetDanqiCount("blue")))
        PetNeidan_Shop_Currency2:SetText(ScriptGlobal_Format("#{NDSD_20230510_18}", LuaFnGetDanqiCount("purple")))
        PetNeidan_Shop_Currency3:SetText(ScriptGlobal_Format("#{NDSD_20230510_19}", LuaFnGetDanqiCount("orange")))
    end

    -- 设置页签按钮的选中状态
    for i = 1, 4 do
        if g_PetNeidan_Shop_PageName_1[i] == g_PetNeidan_Shop_Type1 then
            _G["PetNeidan_Shop_Fenye_Button0"..i]:SetCheck(1)
            _G["PetNeidan_Shop_Fenye_Button0"..i]:SetText("#G"..g_PetNeidan_Shop_PageName_1[i])
        else
            _G["PetNeidan_Shop_Fenye_Button0"..i]:SetCheck(0)
            _G["PetNeidan_Shop_Fenye_Button0"..i]:SetText("#Y"..g_PetNeidan_Shop_PageName_1[i])
        end
    end
    local tempPage2NameList = g_PetNeidan_Shop_PageName_2[g_PetNeidan_Shop_Type1]
    for i = 1, 3 do
        if tempPage2NameList[i] then
            if g_PetNeidan_Shop_Type2 == tempPage2NameList[i] then
                _G["PetNeidan_Shop_Fenye2_Button0"..i]:SetCheck(1)
            else
                _G["PetNeidan_Shop_Fenye2_Button0"..i]:SetCheck(0)
            end
        end
    end

    if g_PetNeidan_Shop_CurPage == 1 then
        PetNeidan_Shop_UpPage:Disable()
    else
        PetNeidan_Shop_UpPage:Enable()
    end
    
    local TotalCount = g_PetNeidan_Shop_ItemsCount[g_PetNeidan_Shop_Type1][g_PetNeidan_Shop_Type2]
    if not TotalCount then
        PushDebugMessage("内丹商店数据错误")
        TotalCount = 0
    end

    if g_PetNeidan_Shop_CurPage * g_PetNeidan_Shop_PerPageCount >= TotalCount then
        PetNeidan_Shop_DownPage:Disable()
    else
        PetNeidan_Shop_DownPage:Enable()
    end

    local npagecount = 1
    if TotalCount > g_PetNeidan_Shop_PerPageCount then
        npagecount = math.floor(TotalCount / g_PetNeidan_Shop_PerPageCount)
        if math.mod(TotalCount, g_PetNeidan_Shop_PerPageCount) > 0 then
            npagecount = npagecount + 1
        end
    end
    PetNeidan_Shop_CurrentlyPage:SetText( ScriptGlobal_Format("#{NDSD_20230510_16}", g_PetNeidan_Shop_CurPage, npagecount) )
end

--************************************
-- 根据页签1选中的id，刷新页签2
--************************************
function PetNeidan_Shop_SetPageName(id)
    if g_PetNeidan_Shop_Type1 ~= g_PetNeidan_Shop_PageName_1[id] then
        return
    end
    local tempPage2NameList = g_PetNeidan_Shop_PageName_2[g_PetNeidan_Shop_Type1]
    for i = 1, 3 do
        if tempPage2NameList[i] then
            _G["PetNeidan_Shop_Fenye2_Button0"..i]:SetText("#cfff263"..tempPage2NameList[i])
            _G["PetNeidan_Shop_Fenye2_Button0"..i]:SetToolTip(g_PetNeidan_Shop_PageNameToolTip[2][id][i])
            _G["PetNeidan_Shop_Fenye2_Button0"..i]:Show()
        else
            _G["PetNeidan_Shop_Fenye2_Button0"..i]:Hide()
        end
    end
end

--************************************
-- 帮助按钮
--************************************
function PetNeidan_Shop_Help_Clicked()
    PushEvent("CCSHOP_HELP", 198)
end