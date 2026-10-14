-- 侠客商店 
-- 天荒商行 分页5

-- SHZJ_241220_04	云锦行
-- SHZJ_241220_05	华玉集
-- SHZJ_241220_06	聚侠堂
-- SHZJ_241220_07	天荒商行
-- XKSD_250110_05   侠客商店

local g_Xiake_Shop_Money
local g_Xiake_Shop_SubTab = 0
local g_Xiake_Shop_CurPage = 1
-- local g_Xiake_Shop_YuanBaoText
local g_Xiake_Shop_SubShopEnum = {
    LOWLEVEL = 0,
    HIGHLEVEL = 1,
    NEWLEVEL = 2,
}
local g_Xiake_Shop_SubShopUI = {
    [g_Xiake_Shop_SubShopEnum.LOWLEVEL] = {Txt = "#{XKSD_250110_09}", Tip = "#{XKSD_250110_10}"},
    [g_Xiake_Shop_SubShopEnum.HIGHLEVEL] = {Txt = "#{XKSD_250110_138}", Tip = "#{XKSD_250110_139}"},
    [g_Xiake_Shop_SubShopEnum.NEWLEVEL] = {Txt = "#{XKSD_250110_11}", Tip = "#{XKSD_250110_12}"},
}
local g_Xiake_Shop_LimitPic = {
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Day",                 -- 日
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Week",                -- 周
    "set:ActivitySchedule image:ActivitySchedule_ShopTips_Forever"              -- 永久
}
-- 每页显示 15 个
local g_Xiake_Shop_ItemCountPerPage = 15

local g_Xiake_Shop_Type = 1
local g_Xiake_Shop_TargetId = -1
local g_Xiake_Shop_LimitLevel = 60

-- 等级表
local g_Xiake_Shop_Level = { 2000, 6000, 12000, 22000, 1000001 }
local g_Xiake_Shop_LevelLimitDic = { "", "#{XKSD_250110_107}", "#{XKSD_250110_108}", "#{XKSD_250110_109}", "#{XKSD_250110_110}"}
-- 周上限
local g_Xiake_Shop_WeekMaxVal = {
    { Level = 70, Limit = 720 },
    { Level = 80, Limit = 960 },
    { Level = 9999, Limit = 1200 },
}
-- MD_XIAKE_WEEKTIME=3296
local g_Xiake_CopySceneDropExtraMD = 3296
local g_Xiake_CopySceneDropExtraMax = 8


function Xiake_Shop_PreLoad()
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("UPDATE_PVPSHOP_DAIBI1",true)
	this:RegisterEvent("UPDATE_PVPSHOP_DAIBI2",true)
	this:RegisterEvent("UPDATE_PVESHOP_DAIBI1",true)
	this:RegisterEvent("UPDATE_PVESHOP_DAIBI2",true)
	-- this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("UI_COMMAND")
    this:RegisterEvent("UPDATE_XIA_KE_SHOP")
    -- this:RegisterEvent("UPDATE_YUANBAO")
end

function Xiake_Shop_OnLoad()
	local curWorldBank_UIPos = Variable:GetVariable("WorldBank_UIPos")
	if curWorldBank_UIPos ~= nil then
        Xiake_Shop_Frame:SetProperty("UnifiedPosition", curWorldBank_UIPos )
    else
        Variable:SetVariable("WorldBank_UIPos", Xiake_Shop_Frame:GetProperty("UnifiedPosition"), 1)
	end

    Xiake_Shop_ItemList:Clear()

    g_Xiake_Shop_SubShopUI[g_Xiake_Shop_SubShopEnum.LOWLEVEL].Btn = Xiake_Shop_But1
    g_Xiake_Shop_SubShopUI[g_Xiake_Shop_SubShopEnum.HIGHLEVEL].Btn = Xiake_Shop_But2
    g_Xiake_Shop_SubShopUI[g_Xiake_Shop_SubShopEnum.NEWLEVEL].Btn = Xiake_Shop_But3

    for _, v in pairs(g_Xiake_Shop_SubShopUI) do
        v.Btn:SetText (v.Txt)
        v.Btn:SetToolTip (v.Tip)
    end

    g_Xiake_Shop_Money = {
        Icon = Xiake_Shop_CurrencyIcon1,
        Txt = Xiake_Shop_Currency1,
        [0] = {
            Icon = "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon8",
            Txt = "#{XKSD_250110_18}",
            Tooltip = "#{XKSD_250110_28}"
        },
        [1] = {
            Icon = "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon9",
            Txt = "#{XKSD_250110_95}",
            Tooltip = "#{XKSD_250110_129}"
        },
        [2] = {
            Icon = "set:ActivitySchedule image:ActivitySchedule_CurrencyIcon10",
            Txt = "#{XKSD_250110_19}",
            Tooltip = "#{XKSD_250110_30}"
        },
    }
    -- Xiake_Shop_Help

    Xiake_Shop_Frequency:SetToolTip ("#{XKSD_250613_29}")
end

--=========
-- Event
--=========
---   !!!reloadscript =Xiake_Shop
function Xiake_Shop_OnEvent(event) 
    if event == "UI_COMMAND" and arg0 ~= nil and tonumber(arg0) == 18201 then
        local clevel = Player:GetData("LEVEL")
        if clevel < g_Xiake_Shop_LimitLevel then
            PushDebugMessage("#{XKSD_250110_105}")
            return
        end
        -- 打开界面 默认选中第一个
        g_Xiake_Shop_SubTab = g_Xiake_Shop_SubShopEnum.LOWLEVEL
        g_Xiake_Shop_CurPage = 1

        Xiake_Shop_CloseSameGroupWindow()
        Xiake_Shop_Update()
        this:Show()
    elseif event == "UPDATE_XIA_KE_SHOP" then -- 更新
        if this:IsVisible() then
            local isWeekUpdate = arg0
            -- 更新数据 关闭购买界面
            PushEvent("OPEN_XIA_KE_SHOP_MBUY", isWeekUpdate)
            Xiake_Shop_Update()
        end
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Xiake_Shop_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Xiake_Shop_Close()
	elseif event == "ADJEST_UI_POS" then
        Xiake_Shop_On_ResetPos()
    -- elseif event == "UPDATE_YUANBAO" then
        -- local yuanbaostr = ScriptGlobal_Format("#{FMSD_220705_55}", Player:GetData("YUANBAO"))
        -- g_Xiake_Shop_YuanBaoText:SetText(yuanbaostr)
    -- elseif event == "OBJECT_CARED_EVENT" then
	-- 	if tonumber(arg0) ~= objCared then
	-- 		return
	-- 	end
	-- 	--如果和NPC的距离大于一定距离或者被删除，自动关闭
	-- 	if arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy" then
	-- 		this:Hide()
	-- 		--取消关心
	-- 		this:CareObject(objCared, 0, "Xiake_Shop")
	-- 	end
	end

end
 
--=========
-- 重置
--=========
function Xiake_Shop_On_ResetPos()
	local curWorldBank_UIPos = Variable:GetVariable("WorldBank_UIPos")
	if curWorldBank_UIPos then
        Xiake_Shop_Frame:SetProperty("UnifiedPosition", curWorldBank_UIPos)
	end
end

function Xiake_Shop_OnHiden()
    Xiake_Shop_Close()
end
--=========
-- 关闭
--=========
function Xiake_Shop_Close()     
    g_Xiake_Shop_SubTab = g_Xiake_Shop_SubShopEnum.LOWLEVEL
    g_Xiake_Shop_CurPage = 1
	this:Hide()
end

--=========
-- 切换子页面
--=========
function Xiake_Shop_ChangeShowTab(index)
    if index == g_Xiake_Shop_SubTab then
        return
    end
    g_Xiake_Shop_SubTab = tonumber(index)
    g_Xiake_Shop_CurPage = 1
    Xiake_Shop_Update()
end

--=========
-- 更新货币栏
--=========
function Xiake_Shop_UpdateMoney ()
    local shopdata = Lua_GetXiaKeShopData()

    local icon = g_Xiake_Shop_Money.Icon
    local txt = g_Xiake_Shop_Money.Txt
    local info = g_Xiake_Shop_Money[g_Xiake_Shop_SubTab]

    -- 设置图标
    icon:SetProperty("Image", info.Icon)
    icon:SetToolTip(info.Tooltip)

    -- 设置钱数
    local money = shopdata.mMoney[g_Xiake_Shop_SubTab]
    local strmoney = ScriptGlobal_Format(info.Txt, money)
    txt:SetText(strmoney)
    txt:SetToolTip(info.Tooltip)

    -- 本周侠客副本额外掉落次数
    local dropnum = DataPool:GetPlayerMission_DataRound (g_Xiake_CopySceneDropExtraMD)
    dropnum = g_Xiake_CopySceneDropExtraMax - math.mod (dropnum, 100)
    local dropdic = "#{XKSD_250613_28}"
    if dropnum == 0 then
        dropdic = "#{XKSD_250613_30}"
    end
    local strdrop = ScriptGlobal_Format (dropdic, dropnum)
    Xiake_Shop_Frequency:SetText (strdrop)
end

--=========
-- 更新子页栏
--=========
function Xiake_Shop_UpdateSubPage()
    for i = 0, 2 do
        g_Xiake_Shop_SubShopUI[i].Btn:SetProperty("Selected", "False")
    end
    g_Xiake_Shop_SubShopUI[g_Xiake_Shop_SubTab].Btn:SetProperty("Selected", "True")
end

--=========
-- 更新商品页面
--=========
function Xiake_Shop_UpdateItems ()
    if g_Xiake_Shop_SubTab < 0 or g_Xiake_Shop_SubTab > 2 then
        return
    end
    Xiake_Shop_ItemList:Clear()

    local info = Lua_GetXiaKeShopData()
    local conf = Lua_GetXiaKeConfData()
    local limitconf = Lua_GetLimitShopConf()

    local mini = g_Xiake_Shop_ItemCountPerPage * (g_Xiake_Shop_CurPage - 1)
    local maxi = g_Xiake_Shop_ItemCountPerPage * g_Xiake_Shop_CurPage

    local shoplevel = Xiake_Shop_GetLevelFromExp(info.mExp[g_Xiake_Shop_SubTab])
    local i = 0
    for _, one in ipairs(conf) do
        -- 当前页面的设置完了
        if i >= maxi then
            break
        end

        if one.mPriceType == g_Xiake_Shop_SubTab then
            -- 当前第 i 个道具, 需要显示
            if i >= mini and i < maxi then
                local bar = Xiake_Shop_ItemList:AddChild("Xiake_Shop_ItemFrame")
                if not bar then
                    break
                end

                -- Action
                local mActionItem = DataPool:CreateBindActionItemForShow(one.mItemId, one.mItemNum)
                if mActionItem and mActionItem:GetID() ~= 0 then
                    bar:GetSubItem("Xiake_Shop_Item"):SetActionItem(mActionItem:GetID())

                    -- 道具名称
                    local itemname = ScriptGlobal_Format("#{XKSD_250110_25}", mActionItem:GetName())
                    bar:GetSubItem("Xiake_Shop_ItemText"):SetText (itemname)
                end

                -- 限购
                if one.mLimitBuyId < 0 then
                    bar:GetSubItem("Xiake_Shop_ItemInfo_Limit"):Hide()
                else
                    local limitbar = bar:GetSubItem("Xiake_Shop_ItemInfo_Limit")
                    if limitconf[one.mLimitBuyId] then
                        local limittype = limitconf[one.mLimitBuyId].mLimitType
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

                -- 限购数量
                local reamain = Lua_GetXiaKeShopItemLimitNum(one.mLimitBuyId)
                if reamain > 0 then
                    bar:GetSubItem("Xiake_Shop_Item_BuyLimitNum"):SetText(tostring (reamain))
                    bar:GetSubItem("Xiake_Shop_Item_BuyLimitNumBK"):Show()
                else
                    bar:GetSubItem("Xiake_Shop_Item_BuyLimitNumBK"):Hide()
                end

                -- 蒙红
                if reamain == -1 or reamain > 0 then
                    bar:GetSubItem("Xiake_Shop_Item_Mask"):Hide()
                else
                    bar:GetSubItem("Xiake_Shop_Item_Mask"):Show()
                end

                -- 商店等级限制
                if shoplevel < one.mLevelLimit then
                    bar:GetSubItem("Xiake_Shop_Item_Mask"):Show()
                    local lock = bar:GetSubItem("Xiake_Shop_ItemLock")
                    lock:Show()
                    lock:SetText(g_Xiake_Shop_LevelLimitDic[one.mLevelLimit])
                    -- bar:GetSubItem("Xiake_Shop_ItemPrice"):Hide()
                    -- bar:GetSubItem("Xiake_Shop_ItemPriceIcon"):Hide()
                else
                    bar:GetSubItem("Xiake_Shop_ItemLock"):Hide()
                    -- bar:GetSubItem("Xiake_Shop_ItemPrice"):Show()
                    -- bar:GetSubItem("Xiake_Shop_ItemPriceIcon"):Show()
                end

                -- 折扣图标
                bar:GetSubItem("Xiake_Shop_Item_Discount"):Hide()

                -- 所需货币图标
                if one.mPriceType < 0 or one.mPriceType > 2 then
                    bar:GetSubItem("Xiake_Shop_ItemPriceIcon"):Hide()
                else
                    bar:GetSubItem("Xiake_Shop_ItemPriceIcon"):SetProperty("Image", 
                        g_Xiake_Shop_Money[one.mPriceType].Icon)
                end

                -- 价格
                if one.mPriceType == 0 then
                    local str = ScriptGlobal_Format("#{XKSD_250110_18}", one.mPriceNum)
                    bar:GetSubItem("Xiake_Shop_ItemPrice"):SetText(str)
                elseif one.mPriceType == 1 then
                    local str = ScriptGlobal_Format("#{XKSD_250110_95}", one.mPriceNum)
                    bar:GetSubItem("Xiake_Shop_ItemPrice"):SetText(str)
                elseif one.mPriceType == 2 then
                    local str = ScriptGlobal_Format("#{XKSD_250110_19}", one.mPriceNum)
                    bar:GetSubItem("Xiake_Shop_ItemPrice"):SetText(str)
                else
                    bar:GetSubItem("Xiake_Shop_ItemPrice"):Hide()
                end
        
                bar:GetSubItem("Xiake_Shop_Item")
                    :SetEvent("MouseLClick", string.format("Xiake_Shop_Buy(%d)", one.mID))    
            end
            -- 需要显示的 道具 数量+1
            i = i + 1
        end
    end
end

--=========
-- 更新介绍信息
--=========
function Xiake_Shop_UpdateIntro ()
    local data = Lua_GetXiaKeShopData()
    if not data then
        return
    end

    local weeklim = Xiake_Shop_GetWeekMaxVal()
    local str1 = ScriptGlobal_Format("#{XKSD_250110_67}", data.mWeek[0] + data.mWeek[1] + data.mWeek[2])
    Xiake_Shop_Currency2:SetText(str1)
    local strtip1 = ScriptGlobal_Format ("#{XKSD_250110_68}", weeklim)
    Xiake_Shop_Currency2:SetToolTip(strtip1)

    -- 经验
    local curshoplevel, curexp, curmax = Xiake_Shop_GetLevelFromExp(data.mExp[g_Xiake_Shop_SubTab])
    local maxlevel = table.getn(g_Xiake_Shop_Level)
    if curshoplevel < maxlevel then
        local str2 = ScriptGlobal_Format("#{XKSD_250110_150}", curexp, curmax)
        Xiake_Shop_Currency4Text3:SetText(str2)
        Xiake_Shop_Pic1:SetProgress (curexp, curmax)
    else
        -- curmax = g_Xiake_Shop_Level[maxlevel - 1] - g_Xiake_Shop_Level[maxlevel - 2]
        -- Xiake_Shop_Pic1:SetProgress (curmax, curmax)
        Xiake_Shop_Pic1:SetProgress(1, 1)
        Xiake_Shop_Currency4Text3:SetText("#{XKSD_250110_151}")
    end
    
    -- 等级
    local str2 = ScriptGlobal_Format("#{XKSD_250110_149}", curshoplevel)
    Xiake_Shop_Currency4Text2:SetText(str2)

    -- 介绍
    if g_Xiake_Shop_SubTab == g_Xiake_Shop_SubShopEnum.LOWLEVEL then
        local str3 = ScriptGlobal_Format("#{XKSD_250110_06}", weeklim)
        Xiake_Shop_Info:SetText(str3)
        Xiake_Shop_Currency4Text1:SetText("#{XKSD_250110_140}")
    elseif g_Xiake_Shop_SubTab == g_Xiake_Shop_SubShopEnum.HIGHLEVEL then
        local str3 = ScriptGlobal_Format("#{XKSD_250110_137}", weeklim)
        Xiake_Shop_Info:SetText(str3)
        Xiake_Shop_Currency4Text1:SetText("#{XKSD_250110_144}")
    else
        local str3 = ScriptGlobal_Format("#{XKSD_250110_07}", weeklim)
        Xiake_Shop_Info:SetText(str3)
        Xiake_Shop_Currency4Text1:SetText("#{XKSD_250110_148}")
    end
end

--=========
-- 更新页面信息
--=========
function Xiake_Shop_UpdatePageInfo()
    local conf = Lua_GetXiaKeConfData()
    local sumcount = 0
    for _, one in ipairs(conf) do
        if one.mPriceType == g_Xiake_Shop_SubTab then
            sumcount = sumcount + 1
        end
    end

    -- 不满一页的情况 隐藏 上下翻页 以及页码显示
    if sumcount <= g_Xiake_Shop_ItemCountPerPage then
        Xiake_Shop_UpPage:Hide()
        Xiake_Shop_DownPage:Hide()
        Xiake_Shop_CurrentlyPage:Hide()
        return
    else
        Xiake_Shop_UpPage:Show()
        Xiake_Shop_DownPage:Show()
        Xiake_Shop_CurrentlyPage:Show()
    end

    -- 如果已经是第一页了, 则上一页置灰
    if g_Xiake_Shop_CurPage <= 1 then
        Xiake_Shop_UpPage:Disable()
    else
        Xiake_Shop_UpPage:Enable()
    end

    -- 如果已经是最后一页, 则下一页置灰
    local maxi = g_Xiake_Shop_ItemCountPerPage * g_Xiake_Shop_CurPage
    if maxi >= sumcount then
        Xiake_Shop_DownPage:Disable()
    else
        Xiake_Shop_DownPage:Enable()
    end

    -- 页签设置
    local pagestr = ScriptGlobal_Format("#{XKSD_250110_26}", g_Xiake_Shop_CurPage, 
        math.ceil(sumcount / g_Xiake_Shop_ItemCountPerPage))
    Xiake_Shop_CurrentlyPage:SetText (pagestr)
end

--=========
-- 更新界面数据
--=========
function Xiake_Shop_Update ()
    -- 更新货币栏
    Xiake_Shop_UpdateMoney()

    -- 更新 子页签 状态
    Xiake_Shop_UpdateSubPage ()

    -- 更新 Item 数据/状态
    Xiake_Shop_UpdateItems()

    -- 更新页面信息
    Xiake_Shop_UpdatePageInfo()

    -- 更新简介
    Xiake_Shop_UpdateIntro()
end

--=========
-- 上一页
--=========
function Xiake_Shop_PageUp()
    if g_Xiake_Shop_CurPage <= 1 then
        return
    end
    g_Xiake_Shop_CurPage = g_Xiake_Shop_CurPage - 1
    Xiake_Shop_UpdateItems()
    Xiake_Shop_UpdatePageInfo()
end

--=========
-- 下一页
--=========
function Xiake_Shop_PageDown()
    local conf = Lua_GetXiaKeConfData()
    local sumcount = 0
    for _, one in ipairs(conf) do
        if one.mPriceType == g_Xiake_Shop_SubTab then
            sumcount = sumcount + 1
        end
    end

    -- 如果已经是最后一页, 则下一页置灰
    local maxi = g_Xiake_Shop_ItemCountPerPage * g_Xiake_Shop_CurPage
    if maxi >= sumcount then
        return
    end

    g_Xiake_Shop_CurPage = g_Xiake_Shop_CurPage + 1
    Xiake_Shop_UpdateItems()
    Xiake_Shop_UpdatePageInfo()
end

--=========
-- 购买道具
--=========
function Xiake_Shop_Buy(shopid)
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("Buy") 					            -- 脚本函数名称
        Set_XSCRIPT_ScriptID(183)										-- 脚本编号 
        Set_XSCRIPT_Parameter(0, shopid)
        Set_XSCRIPT_Parameter(1, -1)                                    -- -1 弹确认框
        Set_XSCRIPT_ParamCount(2) 	-- 参数个数
    Send_XSCRIPT()

    -- -- 判断是否为安全时间
	-- if tonumber(DataPool:GetLeftProtectTime()) > 0 then
	-- 	PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
	-- 	return
    -- end

    -- --判断电话密保和二级密码保护
	-- if CheckPhoneMibaoAndMinorPassword() ~= 1 then
	-- 	return
	-- end

    -- local info = Lua_GetXiaKeShopData()
    -- if not info then
    --     return
    -- end

    -- -- 判断周购买上限
    -- if g_Xiake_Shop_SubTab == g_Xiake_Shop_SubShopEnum.LOWLEVEL and info.mRandShopBuyCount >= 10 then
    --     PushDebugMessage("#{XKSD_250110_32}")
    --     return
    -- end

    -- -- 判断，玩家兑换的道具是否已达到限购上限
    -- local check = false
    -- for _, product in pairs (info.mProducts[g_Xiake_Shop_SubTab]) do
    --     if product.mProductId == shopid then
    --         if product.mProductNum == 0 then
    --             PushDebugMessage("#{XKSD_250110_34}")
    --             return
    --         end
    --         check = true
    --         break
    --     end
    -- end
    -- if not check then
    --     return
    -- end

    -- PushEvent("OPEN_XIA_KE_SHOP_MBUY", 2, shopid, g_Xiake_Shop_SubTab)
end

-- 兑换代币
function Xiake_Shop_Currency2_Button_Clicked()
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("Exchange") 					            -- 脚本函数名称
        Set_XSCRIPT_ScriptID(183)										-- 脚本编号 
        Set_XSCRIPT_Parameter(0, -1)                                    -- -1 弹确认框
        Set_XSCRIPT_ParamCount(1) 	-- 参数个数
    Send_XSCRIPT()
end

-- 预览
-- function Xiake_Shop_Preview_Clicked ()
--     PushEvent("OPEN_XIA_KE_PREVIEW")
-- end

-- 聚侠堂 分页3
-- SHZJ_241220_04	云锦行
-- SHZJ_241220_05	华玉集
-- SHZJ_241220_06	聚侠堂
-- SHZJ_241220_07	天荒商行
function Xiake_Shop_ChangeWorldBankPage(nPageIndex)
    Xiake_Shop_YunJin:SetCheck(0)
	Xiake_Shop_HuaYu:SetCheck(0)
	Xiake_Shop_JuXia:SetCheck(0)
    Xiake_Shop_TianHuang:SetCheck(0)
    Xiake_Shop_XiaKe:SetCheck(1)

	Variable : SetVariable("WorldBank_UIPos", Xiake_Shop_Frame : GetProperty("UnifiedPosition"), 1)

    if 1 == nPageIndex then
        Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name( "OnAskData_L" ); 	    -- 函数名
            Set_XSCRIPT_ScriptID( 888393 );						-- 脚本编号
            Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
        Send_XSCRIPT()
        return
    end

    if 2 == nPageIndex then
        PushEvent("OPEN_HUOYUESHOP_H")
        return
    end

    if 3 == nPageIndex then
        Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name( "FCOnAskDataByType" ) 					    -- 脚本函数名称
            Set_XSCRIPT_ScriptID( 888969 )											-- 脚本编号  
            Set_XSCRIPT_Parameter( 0, 1 )
            Set_XSCRIPT_Parameter( 1, -1 )
            Set_XSCRIPT_ParamCount( 2 ) 	                                        -- 参数个数  
        Send_XSCRIPT()	
        return
    end

    if 4 == nPageIndex then
        Clear_XSCRIPT()
            Set_XSCRIPT_Function_Name( "OnAskDataByType" ); 					    -- 脚本函数名称
            Set_XSCRIPT_ScriptID( 889833 )											-- 脚本编号 
            Set_XSCRIPT_Parameter( 0, -1 )
            Set_XSCRIPT_Parameter( 1, 0 )
            Set_XSCRIPT_ParamCount( 2 ) 	-- 参数个数
        Send_XSCRIPT()
        return
    end

    if 5 == nPageIndex then
        return
    end
end

function Xiake_Shop_CloseSameGroupWindow()

	Xiake_Shop_On_ResetPos()

    CloseWindow("ActivitySchedule_Shop2", true)
    CloseWindow("ActivitySchedule_Shop", true)
    CloseWindow("Fenzheng_Shop", true)
    CloseWindow("FengmingShop", true)
    -- CloseWindow("Xiake_Shop", true)

    Xiake_Shop_YunJin    :   SetCheck(0)
	Xiake_Shop_HuaYu     :   SetCheck(0)
	Xiake_Shop_JuXia     :   SetCheck(0)
    Xiake_Shop_TianHuang :   SetCheck(0)
    Xiake_Shop_XiaKe:SetCheck(1)
    
    local n2606S = Player:GetData("Is2606S") 
    if n2606S ~= 1 then
        Xiake_Shop_TianHuang:Show()
    else
        Xiake_Shop_TianHuang:Hide()
    end
    
    local nXiaKe = Player:GetData("IsXiaKe") 
    if nXiaKe ~= 1 then
        Xiake_Shop_XiaKe:Hide()
    else
        Xiake_Shop_XiaKe:Show()
    end
end

-- 根据商店经验获得对应的等级
function Xiake_Shop_GetLevelFromExp (exp)
    local lastexp = 0
    for level, needexp in ipairs(g_Xiake_Shop_Level) do
        if exp < needexp then
            return level, exp - lastexp, needexp - lastexp
        end
        lastexp = needexp
    end
    return table.getn(g_Xiake_Shop_Level), -1, -1
end

-- 获取本周能获得的最大 两令 总和
function Xiake_Shop_GetWeekMaxVal ()
    -- 周上限
    local clevel = Player:GetData("LEVEL")
    for _, one in ipairs(g_Xiake_Shop_WeekMaxVal) do
        if clevel < one.Level then
            return one.Limit
        end
    end
    return -1
end

function Xiake_Shop_OnHelpClicked()
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name("OnHelpClicked") 					            -- 脚本函数名称
        Set_XSCRIPT_ScriptID(183)										-- 脚本编号 
        Set_XSCRIPT_ParamCount(0) 	-- 参数个数
    Send_XSCRIPT()
end