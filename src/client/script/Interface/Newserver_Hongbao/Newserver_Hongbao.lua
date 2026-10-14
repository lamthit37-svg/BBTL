local Newserver_Hongbao_Frame_UnifiedXPosition = 0
local Newserver_Hongbao_Frame_UnifiedYPosition = 0
local g_Newserver_Hongbao_shop_listitem ={}
local g_Newserver_Hongbao_Ahieve_listitem ={}
local g_Newserver_Hongbao_tab = 1
local g_Newserver_Hongbao_CurLevel = 1
local g_Newserver_Hongbao_Tab_Ctl = {}
local g_Newserver_wdc_tbl = {}
local g_Newserver_go = {
    [1] = nil,
    [2] = "#{HBF_241219_82}",
    [3] = "#{HBF_241219_83}",
    [4] = "#{HBF_241219_84}",
    [5] = "#{HBF_241219_85}",
    [6] = nil,
    [7] = "#{HBF_241219_82}",
    [8] = "#{HBF_241219_83}",
    [9] = "#{HBF_241219_84}",
    [10] = "#{HBF_241219_85}",
    [11] = "#{HBF_241219_113}",
    [12] = "#{HBF_241219_114}",
    [13] = "#{HBF_241219_115}",
    [14] = "#{HBF_241219_116}",
    [15] = "#{HBF_241219_86}",
    [16] = "#{HBF_241219_87}",
    [17] = "#{HBF_241219_88}",
    [18] = "#{HBF_241219_89}",
    [19] = "#{HBF_241219_118}",
    [20] = nil,
    [21] = "#{HBF_241219_117}",
    [22] = "#{HBF_241219_117}",
    [23] = "#{HBF_241219_119}",
    [24] = nil,
    [25] = nil,
    [26] = "#{HBF_260515_19}",
    [27] = "#{HBF_260515_20}",
    [28] = "#{HBF_260515_21}",
    [29] = "#{HBF_260515_22}",
    [30] = "#{HBF_260515_23}",
    [31] = "#{HBF_260515_24}",
    [32] = "#{HBF_260515_25}",
    [33] = "#{HBF_260515_24}",
    [34] = "#{HBF_260515_25}",
}
 
local g_Newserver_Hongbao_bossReward = 
{
    [1] = {itemid = 38007948, num = 1,vipLevel = 0},
    [2] = {itemid = 38007948, num = 2,vipLevel = 1},
    [3] = {itemid = 38007978, num = 1,vipLevel = 2},
    [4] = {itemid = 38007949, num = 2,vipLevel = 3},
    [5] = {itemid = 38007979, num = 1,vipLevel = 4},
}
--*********************************
-- PreLoad
--*********************************
function Newserver_Hongbao_PreLoad()
	this : RegisterEvent( "UPDATE_XFHB_SHOP" );					--
	this : RegisterEvent( "UI_COMMAND" );					--
	this : RegisterEvent(" ADJEST_UI_POS",false)
	this : RegisterEvent( "VIEW_RESOLUTION_CHANGED" );		-- 游戏分辨率发生了变化
	this : RegisterEvent( "GAMELOGIN_SELECTCHARACTER" );	-- 选择人物
    this : RegisterEvent( "HIDE_ON_SCENE_TRANSED" );		-- 离开场景
    this : RegisterEvent ( "TODAY_ACTIVE_POINT",false)
end

--*********************************
-- OnLoad
--*********************************
function Newserver_Hongbao_OnLoad()
    -- 保存界面的默认相对位置
	Newserver_Hongbao_Frame_UnifiedXPosition	= Newserver_Hongbao_Frame:GetProperty("UnifiedXPosition");
    Newserver_Hongbao_Frame_UnifiedYPosition	= Newserver_Hongbao_Frame:GetProperty("UnifiedYPosition");
    g_Newserver_Hongbao_Tab_Ctl[1] = Newserver_Hongbao_Left_Buttontab01
    g_Newserver_Hongbao_Tab_Ctl[2] = Newserver_Hongbao_Left_Buttontab02
    g_Newserver_Hongbao_Tab_Ctl[3] = Newserver_Hongbao_Left_Buttontab03
end

--================================================
-- 界面的默认相对位置
--================================================
function Newserver_Hongbao_ResetPos()
	Newserver_Hongbao_Frame:SetProperty("UnifiedXPosition", Newserver_Hongbao_Frame_UnifiedXPosition);
	Newserver_Hongbao_Frame:SetProperty("UnifiedYPosition", Newserver_Hongbao_Frame_UnifiedYPosition);
end

--**********************************
-- ONEvent
--**********************************
function Newserver_Hongbao_OnEvent( event )
    if ( event == "UPDATE_XFHB_SHOP" ) then
        local isshow = tonumber(arg0)
        if isshow == 1 then
            if not (this:IsVisible()) then
                this:Show() 
            else
                this:Hide()
            end
        end

        local nBossOpen = tonumber(arg2)
        NewServerHongbaoUpadateBossReward(nBossOpen)
        Newserver_Hongbao_Open()
    elseif event == "UI_COMMAND" and  tonumber(arg0) == 9996761 then
        if  this:IsVisible() then
            NewServerHongbaoUpadateBossReward(1)
            Newserver_Hongbao_Open()
        end    
    elseif event == "TODAY_ACTIVE_POINT" then
        if this:IsVisible() then
            if Newserver_Hongbao_Left_Buttontab03:IsVisible() then
                NewServerHongbaoUpadateBossReward(1)
                Newserver_Hongbao_Open()
            end
		end    
    elseif event == "UI_COMMAND" and this:IsVisible() then
        Newserver_Hongbao_Close()
    elseif event == "VIEW_RESOLUTION_CHANGED" then
		Newserver_Hongbao_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Newserver_Hongbao_Close()
	elseif event == "ADJEST_UI_POS" then
        Newserver_Hongbao_ResetPos()
    end
end
--**********************************
-- 关闭
--**********************************
function Newserver_Hongbao_Close()
    if(IsWindowShow("Newserver_Hongbao_MBuy")) then
		CloseWindow("Newserver_Hongbao_MBuy", true);
    end
    if(IsWindowShow("Newserver_Hongbao_JSB_Buy")) then
		CloseWindow("Newserver_Hongbao_JSB_Buy", true);
	end
    g_Newserver_Hongbao_tab = 1
    this:Hide()
end
function Newserver_Hongbao_OnHiden()
    Newserver_Hongbao_Close()
end
--**********************************
-- 打开界面
--**********************************
function Newserver_Hongbao_Open()
    Newserver_Hongbao_Left_Buttontab01_Tips:Hide()
    Newserver_Hongbao_Left_Buttontab02_Tips:Hide()

    g_Newserver_Hongbao_Tab_Ctl[g_Newserver_Hongbao_tab]:SetCheck(1)
    if g_Newserver_Hongbao_tab == 1 then
        Newserver_Hongbao_Client1:Show()
        Newserver_Hongbao_Client2:Hide()
        Newserver_Hongbao_Client3:Hide()
        Newserver_Hongbao_MainDian_Refresh()
    elseif g_Newserver_Hongbao_tab == 2 then
        Newserver_Hongbao_Client2:Show()
        Newserver_Hongbao_Client1:Hide()
        Newserver_Hongbao_Client3:Hide()
        Newserver_Hongbao_Shop_Refresh()
    else
        Newserver_Hongbao_Client1:Hide()
        Newserver_Hongbao_Client2:Hide()
        Newserver_Hongbao_Client3:Show()
        Newserver_Hongbao_BossReward_Refresh()
    end
    
    Newserver_Hongbao_RedPoint_Refresh()
end
function Newserver_Hongbao_MainDian_Refresh()
    local hb_data = Lua_GetXinFuHongBaoDataInfo()
    if type(hb_data) ~= "table" then
        return
    end

    local Weekinfo = Lua_GetXinFuHongBaoWeekInfo()
    if type(Weekinfo) ~= "table" or table.getn(Weekinfo) < 1  then
        return
    end
    for i = 1, table.getn(g_Newserver_Hongbao_Ahieve_listitem) do
		if g_Newserver_Hongbao_Ahieve_listitem[i] ~= nil then
			g_Newserver_Hongbao_Ahieve_listitem[i] = nil
		end
    end

    for i = 1, table.getn(g_Newserver_Hongbao_Ahieve_listitem) do
		if g_Newserver_Hongbao_Ahieve_listitem[i] ~= nil then
			g_Newserver_Hongbao_Ahieve_listitem[i] = nil
		end
    end
    for key, value in pairs(g_Newserver_wdc_tbl) do
        g_Newserver_wdc_tbl[key] = nil
    end

    Newserver_Hongbao_PageList:Clear()

    local opentime      = hb_data.OpenTime
    local closetime     = hb_data.CloseTime
    local openyear      = math.floor(opentime/10000)
    local openmonth     = math.floor(math.mod(opentime,10000)/100)
    local openday       = math.mod(opentime,100)
    local closeyear     = math.floor(closetime/10000)
    local closemonth    = math.floor(math.mod(closetime,10000)/100)
    local closeday      = math.mod(closetime,100)


    Newserver_Hongbao_Client1_Info:SetText(ScriptGlobal_Format("#{HBF_241219_15}",openyear,openmonth,openday,closeyear,closemonth,closeday))
    idx = 1
    local GourpIDTbl = Newserver_Hongbao_Achieve_GetGroupPaiXu() 
    --未完成
    for i = 1, table.getn(GourpIDTbl) do
        local tblgroupid = GourpIDTbl[i]
        local showidx = Newserver_Hongbao_Achieve_GetByGroup_WeiLingQu(tblgroupid)
        if showidx == -1 then
            continue;
        end
        g_Newserver_wdc_tbl[table.getn(g_Newserver_wdc_tbl)+1] = i
        local bar1 = Newserver_Hongbao_PageList:AddChild("Newserver_Hongbao_CoinAItem1")
        if not bar1 then
           break
        end
        local needvalue = Weekinfo[showidx].NeedValue
        local NeedVIP   = Weekinfo[showidx].NeedVIP        
        local selfvalue = hb_data.maidian[Weekinfo[showidx].EventId].curcount
        local setday    = hb_data.Groupinfo[Weekinfo[showidx].GroupID].setday
        local cishu     = hb_data.Groupinfo[Weekinfo[showidx].GroupID].cishu
        Lua_TDU_Log("Newserver_Hongbao_Achieve_GetByGroup_WeiLingQu needvalue:"..needvalue);
        Lua_TDU_Log("Newserver_Hongbao_Achieve_GetByGroup_WeiLingQu NeedVIP:"..NeedVIP);
        Lua_TDU_Log("Newserver_Hongbao_Achieve_GetByGroup_WeiLingQu selfvalue:"..selfvalue);
        Lua_TDU_Log("Newserver_Hongbao_Achieve_GetByGroup_WeiLingQu selfvalue:"..selfvalue);
        Lua_TDU_Log("Newserver_Hongbao_Achieve_GetByGroup_WeiLingQu eventid:"..Weekinfo[showidx].EventId);
        Lua_TDU_Log("Newserver_Hongbao_Achieve_GetByGroup_WeiLingQu Desc:"..Weekinfo[showidx].Desc);
        local selfvip   = hb_data.CurVip
        local lingqu    = hb_data.maidian[Weekinfo[showidx].EventId].lingqu
        local itemid    = Weekinfo[showidx].ItemID
        local itemnum   = Weekinfo[showidx].ItemNum
        bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Name"):SetText(Weekinfo[showidx].Desc)

        if NeedVIP > 0  then
            if selfvip >= NeedVIP then
                bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Art"):SetText(ScriptGlobal_Format(Weekinfo[showidx].JD,selfvalue,1))
            else
                bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Art"):SetText(ScriptGlobal_Format(Weekinfo[showidx].JD,selfvalue,0))
            end
        else
            bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Art"):SetText(ScriptGlobal_Format(Weekinfo[showidx].JD,selfvalue))
        end

        if tblgroupid >=3 and tblgroupid <= 6 then
            if selfvip >= NeedVIP then
                bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Art"):SetText(ScriptGlobal_Format(Weekinfo[showidx].JD, 1))
            else
                bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Art"):SetText(ScriptGlobal_Format(Weekinfo[showidx].JD, 0))
            end
        end

        if tblgroupid >=7 and tblgroupid <= 10 then
            if selfvip >= NeedVIP and selfvalue >= needvalue then
                bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Art"):SetText(ScriptGlobal_Format(Weekinfo[showidx].JD, 1))
            else
                bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Art"):SetText(ScriptGlobal_Format(Weekinfo[showidx].JD, 0))
            end
        end
        
        local theAction = DataPool:CreateActionItemForShow(itemid, itemnum)
		if theAction:GetID() ~= 0 then
            bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Icon"):SetActionItem(theAction:GetID());
        end
        bar1:GetSubItem("Newserver_Hongbao_Client1_Item1_Received"):Hide()
        if selfvalue >= needvalue and selfvip >= NeedVIP then
            bar1:GetSubItem("Newserver_Hongbao_Client1_Item1_OK"):Show()
            bar1:GetSubItem("Newserver_Hongbao_Client1_Item1_Tips"):Show()
            bar1:GetSubItem("Newserver_Hongbao_Client1_Item1_GO"):Hide()
            Newserver_Hongbao_Left_Buttontab01_Tips:Show()
        else
            bar1:GetSubItem("Newserver_Hongbao_Client1_Item1_OK"):Hide()
            bar1:GetSubItem("Newserver_Hongbao_Client1_Item1_Tips"):Hide()
            bar1:GetSubItem("Newserver_Hongbao_Client1_Item1_GO"):Show()
        end
        bar1:GetSubItem("Newserver_Hongbao_Client1_Item1_OK"):SetEvent("MouseLClick", string.format("Newserver_Hongbao_Achieve_OK(%d,%d)", Weekinfo[showidx].GroupID, Weekinfo[showidx].EventId))
        bar1:GetSubItem("Newserver_Hongbao_Client1_Item1_GO"):SetEvent("MouseLClick", string.format("Newserver_Hongbao_Achieve_GO(%d,%d)", Weekinfo[showidx].GroupID, Weekinfo[showidx].EventId))
        g_Newserver_Hongbao_Ahieve_listitem[idx] = bar1
        idx = idx + 1
    end

    --已领取
    for i = 1, table.getn(GourpIDTbl) do
        local tblgroupid = GourpIDTbl[i]
        local showidx = Newserver_Hongbao_Achieve_GetByGroup_LingQu(tblgroupid)
        if showidx == -1 then
            continue;
        end
        local bar1 = Newserver_Hongbao_PageList:AddChild("Newserver_Hongbao_CoinAItem1")
        if not bar1 then
           break
        end
        local needvalue = Weekinfo[showidx].NeedValue
        local selfvalue = hb_data.maidian[Weekinfo[showidx].EventId].curcount
        local lingqu    = hb_data.maidian[Weekinfo[showidx].EventId].lingqu
        local itemid    = Weekinfo[showidx].ItemID
        local itemnum   = Weekinfo[showidx].ItemNum
        local NeedVIP   = Weekinfo[showidx].NeedVIP
        local selfvip   = hb_data.CurVip
        bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Name"):SetText(Weekinfo[showidx].Desc)
        bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Art"):SetText(ScriptGlobal_Format(Weekinfo[showidx].JD,selfvalue))
        bar1:GetSubItem("Newserver_Hongbao_Client1_Item1_Tips"):Hide()
        if NeedVIP > 0  then
            if selfvip >= NeedVIP then
                bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Art"):SetText(ScriptGlobal_Format(Weekinfo[showidx].JD,selfvalue,1))
            else
                bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Art"):SetText(ScriptGlobal_Format(Weekinfo[showidx].JD,selfvalue,0))
            end
        else
            bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Art"):SetText(ScriptGlobal_Format(Weekinfo[showidx].JD,selfvalue))
        end

        if tblgroupid >=3 and tblgroupid <= 6 then
            if selfvip >= NeedVIP then
                bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Art"):SetText(ScriptGlobal_Format(Weekinfo[showidx].JD, 1))
            else
                bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Art"):SetText(ScriptGlobal_Format(Weekinfo[showidx].JD, 0))
            end
        end
        
        if tblgroupid >=7 and tblgroupid <= 10 then
            if selfvip >= NeedVIP and selfvalue >= needvalue then
                bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Art"):SetText(ScriptGlobal_Format(Weekinfo[showidx].JD, 1))
            else
                bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Art"):SetText(ScriptGlobal_Format(Weekinfo[showidx].JD, 0))
            end
        end

        local theAction = DataPool:CreateActionItemForShow(itemid, itemnum)
		if theAction:GetID() ~= 0 then
            bar1:GetSubItem("Newserver_Hongbao_CoinAItem1_Icon"):SetActionItem(theAction:GetID());
        end
        bar1:GetSubItem("Newserver_Hongbao_Client1_Item1_Received"):Show()
        g_Newserver_Hongbao_Ahieve_listitem[idx] = bar1
        idx = idx + 1
    end

    if type(Weekinfo) == "table" and Weekinfo[1]~= nil and Weekinfo[1].OpenTime ~= nil then
        local openweekTime      = Weekinfo[1].OpenTime
        local closeweekTime     = Weekinfo[1].CloseTime
        local openweekyear      = math.floor(openweekTime/10000)
        local openweekmonth     = math.floor(math.mod(openweekTime,10000)/100)
        local openweekday       = math.mod(openweekTime,100)
        local closeweekyear     = math.floor(closeweekTime/10000)
        local closeweekmonth    = math.floor(math.mod(closeweekTime,10000)/100)
        local closeweekday      = math.mod(closeweekTime,100)
        if Weekinfo[1].WeekID ~= 8 then
            Newserver_Hongbao_PageList_Text:SetText(ScriptGlobal_Format("#{HBF_241219_121}",closeweekmonth,closeweekday))
        else
            Newserver_Hongbao_PageList_Text:SetText(ScriptGlobal_Format("#{HBF_241219_140}",closeweekmonth,closeweekday))
        end        
    end

end

function Newserver_Hongbao_Achieve_OK(groupid, EventId)
    Clear_XSCRIPT()
        Set_XSCRIPT_Function_Name( "LingQu" ); 					-- 脚本函数名称
        Set_XSCRIPT_ScriptID( 501016 );							-- 脚本编号
        Set_XSCRIPT_Parameter( 0, EventId );
        Set_XSCRIPT_ParamCount( 1 ); 	-- 参数个数
    Send_XSCRIPT()

end
function Newserver_Hongbao_Achieve_GO(groupid, EventId) 
    if g_Newserver_go[EventId] ~= nil then
        PushDebugMessage(g_Newserver_go[EventId])
        return
    end
    if (EventId==1) or (EventId ==6) or (EventId ==24) or (EventId ==25)  then
        OpenTodayCampaignList()
        return
    end
    if (EventId ==20)  then
	    --如果界面打开了 就关闭界面
	    if(IsWindowShow("Fuli_MonthlySign")) then
	    	CloseWindow("Fuli_MonthlySign", true);
	    	return
	    end

	    if(IsWindowShow("Fuli_QiankunBag")) then
	    	CloseWindow("Fuli_QiankunBag", true);
	    	return
	    end

	    if(IsWindowShow("Fuli_StrongRoad_DiaoWen")) then
	    	CloseWindow("Fuli_StrongRoad_DiaoWen", true);
	    	return
	    end

	    if(IsWindowShow("MonthlySignSP")) then
	    	CloseWindow("MonthlySignSP", true);
	    	return
	    end

	    if(IsWindowShow("StrongRoadSP_DiaoWen")) then
	    	CloseWindow("StrongRoadSP_DiaoWen", true);
	    	return
	    end

	    if(IsWindowShow("QiankunBagSP")) then
	    	CloseWindow("QiankunBagSP", true);
	    	return
	    end

	    if(IsWindowShow("Fuli_Dailyburden")) then
	    	CloseWindow("Fuli_Dailyburden", true);
	    	return
	    end

	    if(IsWindowShow("DailyburdenSP")) then
	    	CloseWindow("DailyburdenSP", true);
	    	return
	    end

	    if(IsWindowShow("Fuli_ZhanLing")) then
	    	CloseWindow("Fuli_ZhanLing", true);
	    	return
	    end

	    local curDay = tonumber(DataPool:GetServerDayTime());
	    -- 等级
	    local nLevel = Player:GetLevel();
	    if ( nLevel < 15 ) then
	    	--打开升级界面
	    	if ( g_HuoDong[2].nCharCreateDate < 904691712 ) or (g_HuoDong[2].g_bIsNewServerGiftsForLevelUpValid == 1 or g_HuoDong[2].g_bIsNewServerGiftsForLevelUpValid_2023 == 1) then
	    		PushDebugMessage("#{FLRK_160608_11}")
	    		return
	    	end
	    	OpenQianKunDai(0)
	    elseif ( nLevel >= 15 ) then
	    	--打开每月签到界面
	    	if(IsWindowShow("MonthlySign")) then
	    		CloseWindow("MonthlySign", true)
	    		return
	    	end
	    	OpenMonthlySign(0)
        end 
    end
end
function Newserver_Hongbao_Shop_Refresh()
    local hb_data = Lua_GetXinFuHongBaoDataInfo()
    if type(hb_data) ~= "table" then
        return
    end

    local hb_shop_info = Lua_GetXinFuHongBaoShopInfo()
    if type(hb_shop_info) ~= "table" then
        return
    end
    for i = 1, table.getn(g_Newserver_Hongbao_shop_listitem) do
		if g_Newserver_Hongbao_shop_listitem[i] ~= nil then
			g_Newserver_Hongbao_shop_listitem[i] = nil
		end
    end
    local OpenShopID    = hb_data.OpenShopID
    local Daibi         = hb_data.Daibi
    local opentime      = hb_data.OpenTime
    local closetime     = hb_data.CloseTime
    local openyear      = math.floor(opentime/10000)
    local openmonth     = math.floor(math.mod(opentime,10000)/100)
    local openday       = math.mod(opentime,100)
    local closeyear     = math.floor(closetime/10000)
    local closemonth    = math.floor(math.mod(closetime,10000)/100)
    local closeday      = math.mod(closetime,100)
    Newserver_Hongbao_Client2_UpBK_Text:SetText(ScriptGlobal_Format("#{HBF_241219_54}",Daibi))
    Newserver_Hongbao_Client2_Info_Text:SetText(ScriptGlobal_Format("#{HBF_241219_31}",openyear, openmonth, openday, closeyear, closemonth, closeday))
    Newserver_Hongbao_Client2_Lace:Clear()
    local idx = 1
    for tblidx, iteminfo in ipairs(hb_shop_info) do
        local bar1 = Newserver_Hongbao_Client2_Lace:AddChild("Newserver_Hongbao_Client2_CoinAItem1")
        if not bar1 then
           break
        end
        local CXid      = iteminfo.CXID
        local itemid    = iteminfo.ItemID
        local Price     = iteminfo.Price
        local ItemLevel = iteminfo.ItemLevel
        local LimitNum  = iteminfo.LimitNum
        local YunLan    = iteminfo.YuLan
        local ZheKou    = iteminfo.ZheKou
        local clshoptime= iteminfo.CloseTime
        local curnum    = hb_data.BuyNum[CXid]
        local theAction = DataPool:CreateActionItemForShow(itemid, 1)
		if theAction:GetID() ~= 0 then
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_Icon"):SetActionItem(theAction:GetID());
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_Icon"):SetEvent("MouseLClick", string.format("Newserver_Hongbao_Buy(%d,%d)", tblidx, CXid))
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_Name"):SetText(ScriptGlobal_Format("#{HBF_241219_34}",theAction:GetName())) 
        end
        --bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_Text"):SetText(ItemLevel)
        bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_Num"):SetText(ScriptGlobal_Format("#{HBF_241219_35}",Price))
        if ZheKou == 1 then
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_Discount"):Show()
        else
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_Discount"):Hide()
        end
        if YunLan == 1 then
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_EyeSign"):Show()
        else
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_EyeSign"):Hide()
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_EyeSign"):SetEvent("MouseLClick", string.format("Newserver_Hongbao_Eye(%d,%d)", tblidx, CXid))

        end
        if LimitNum == -1 then
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_Mask"):Hide()
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_BuyLimitNum"):Hide()
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_Icon"):Enable()
        elseif curnum >= LimitNum then
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_Mask"):Show()
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_BuyLimitNum"):SetText(0)
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_BuyLimitNum"):Show()
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_Icon"):Disable()
        else
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_Mask"):Hide()
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_BuyLimitNum"):SetText(LimitNum-curnum)
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_BuyLimitNum"):Show()
            bar1:GetSubItem("Newserver_Hongbao_Client2_CoinAItem1_Icon"):Enable()
        end
        g_Newserver_Hongbao_shop_listitem[idx] = bar1
        idx = idx + 1
        local closeshopyear     = math.floor(clshoptime/10000)
        local closeshopmonth    = math.floor(math.mod(clshoptime,10000)/100)
        local closeshopday      = math.mod(clshoptime,100)
                
        if OpenShopID ~= 8 then
            Newserver_Hongbao_Client2_UpBK_Text2:SetText(ScriptGlobal_Format("#{HBF_241219_33}",closeshopmonth,closeshopday))
        else
            Newserver_Hongbao_Client2_UpBK_Text2:SetText(ScriptGlobal_Format("#{HBF_241219_140}",closeshopmonth,closeshopday))
        end
    end
end
function Newserver_Hongbao_Buy(tblidx, cxid)
    local hb_shop_info = Lua_GetXinFuHongBaoShopInfo()
    if type(hb_shop_info) ~= "table" then
        return
    end
    if hb_shop_info[tblidx].CXID ~= cxid then
        PushDebugMessage("cxid err")
        return
    end

    PushEvent("OPEN_NSHB_M_BUY", tblidx, cxid)

end

function Newserver_Hongbao_Client2_CoinAItem1_Click()
    PushEvent("OPEN_NSHB_JSB_BUY")
end

function Newserver_Hongbao_Eye(tblidx, cxid)
    local hb_shop_info = Lua_GetXinFuHongBaoShopInfo()
    if type(hb_shop_info) ~= "table" then
        return
    end
    local itemid    = hb_shop_info[tblidx].ItemID
    if hb_shop_info[tblidx].CXID ~= cxid then
        PushDebugMessage("cxid err")
        return
    end
    Clear_XSCRIPT()
	    Set_XSCRIPT_ScriptID(888051)
	    Set_XSCRIPT_Function_Name("DressPreview")
	    Set_XSCRIPT_Parameter(0, itemid)
	    Set_XSCRIPT_Parameter(1, 240)   --发型
	    Set_XSCRIPT_Parameter(2, 178)   --脸型
	    Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

function Newserver_Hongbao_Achieve_GetByGroup_WeiLingQu(groupid)
    local idx = -1
    Lua_TDU_Log("groupid:"..groupid);
    local hb_info = Lua_GetXinFuHongBaoDataInfo()
    local Weekinfo= Lua_GetXinFuHongBaoWeekInfo()
    for index, value in ipairs(Weekinfo) do
        if value.GroupID == groupid then
            local needvalue  = value.NeedValue
            local needvip    = value.NeedVIP
            local perweekcost= value.MaxCountPerWeek
            local ncurvip    = hb_info.CurVip
            local selfvalue = hb_info.maidian[value.EventId].curcount
            local lingqu    = hb_info.maidian[value.EventId].lingqu            
            local setday    = hb_info.Groupinfo[groupid].setday
            local cishu     = hb_info.Groupinfo[groupid].cishu
            Lua_TDU_Log("groupid:"..groupid.."needvalue:"..needvalue);
            Lua_TDU_Log("groupid:"..groupid.."needvip:"..needvip);
            Lua_TDU_Log("groupid:"..groupid.."perweekcost:"..perweekcost);
            Lua_TDU_Log("groupid:"..groupid.."selfvalue:"..selfvalue);
            Lua_TDU_Log("groupid:"..groupid.."lingqu:"..lingqu);
            Lua_TDU_Log("groupid:"..groupid.."setday:"..setday);
            Lua_TDU_Log("groupid:"..groupid.."GetServerDayTime:"..DataPool:GetServerDayTime());
            if needvalue > selfvalue or needvip > ncurvip then
                idx = index
                break
            elseif selfvalue >= needvalue and ncurvip >= needvip and lingqu == 0 then
                idx = index
                break
            elseif lingqu == 0 then
                idx =  index
            end
        end
    end
    if idx > 0 then
        local perweekcost= Weekinfo[idx].MaxCountPerWeek           
        local setday    = hb_info.Groupinfo[groupid].setday
        local cishu     = hb_info.Groupinfo[groupid].cishu      
        if (groupid == 1 or groupid == 2) and ( cishu >= perweekcost and setday ~= tonumber(DataPool:GetServerDayTime()) ) then
            idx = -1
        end
    end
    return idx
end

function Newserver_Hongbao_Achieve_GetByGroup_LingQu(groupid)
    Lua_TDU_Log("Newserver_Hongbao_Achieve_GetByGroup_LingQu groupid:"..groupid);
    for index, value in ipairs(g_Newserver_wdc_tbl) do
        Lua_TDU_Log("g_Newserver_wdc_tbl index:"..index);
        Lua_TDU_Log("g_Newserver_wdc_tbl value:"..value);
        if groupid == value then
            return -1
        end
    end

    local idx = -1
    local hb_info = Lua_GetXinFuHongBaoDataInfo()
    local Weekinfo= Lua_GetXinFuHongBaoWeekInfo()
    for index, value in ipairs(Weekinfo) do
        if value.GroupID == groupid then
            local lingqu    = hb_info.maidian[value.EventId].lingqu
            if lingqu == 1 then
                idx = index
            end
        end
    end
    
    
    if idx > 0 then
        local perweekcost= Weekinfo[idx].MaxCountPerWeek           
        local setday    = hb_info.Groupinfo[groupid].setday
        local cishu     = hb_info.Groupinfo[groupid].cishu      
        if (groupid == 1 or groupid == 2) and ( cishu >= perweekcost and setday ~= tonumber(DataPool:GetServerDayTime()) ) then
            idx = -1
        end
    end

    Lua_TDU_Log("idx:"..idx);
    return idx
end

function Newserver_Hongbao_Tab_Click(idx)
    g_Newserver_Hongbao_tab = idx
    Newserver_Hongbao_Open()
end

function Newserver_Hongbao_Client1_Info_Help()
    PushEvent("CCSHOP_HELP", 232)

end


function Newserver_Hongbao_RedPoint_Refresh()
    local hb_data = Lua_GetXinFuHongBaoDataInfo()
    if type(hb_data) ~= "table" then
        return
    end

    local Weekinfo = Lua_GetXinFuHongBaoWeekInfo()
    if type(Weekinfo) ~= "table" or table.getn(Weekinfo) < 1  then
        return
    end  
    Newserver_Hongbao_Left_Buttontab01_Tips:Hide()
    local ShowMainTip = 0
    --未领取
    for i = 1, Weekinfo[table.getn(Weekinfo)].GroupID do
        local showidx = Newserver_Hongbao_Achieve_GetByGroup_WeiLingQu(i)
        if showidx == -1 then
            continue;
        end 
        local needvalue = Weekinfo[showidx].NeedValue
        local NeedVIP   = Weekinfo[showidx].NeedVIP
        local selfvalue = hb_data.maidian[Weekinfo[showidx].EventId].curcount 
        local selfvip   = hb_data.CurVip
        local lingqu    = hb_data.maidian[Weekinfo[showidx].EventId].lingqu
        local itemid    = Weekinfo[showidx].ItemID
        local itemnum   = Weekinfo[showidx].ItemNum  
        if selfvalue >= needvalue and selfvip >= NeedVIP then 
            Newserver_Hongbao_Left_Buttontab01_Tips:Show() 
            ShowMainTip = 1
        end 
    end 
end

function Newserver_Hongbao_Achieve_GetGroupPaiXu()
    local pxtbl = {}
    local Weekinfo = Lua_GetXinFuHongBaoWeekInfo()
    if type(Weekinfo) ~= "table" or table.getn(Weekinfo) < 1  then
        return
    end  

    for index, value in ipairs(Weekinfo) do
        local GroupID = value.GroupID
        local isexist = 0
        for pxtblidx, pxvalue in ipairs(pxtbl) do
            if pxvalue == GroupID then
                isexist = 1
            end
        end
        if isexist == 0 then
            pxtbl[table.getn(pxtbl)+1] = GroupID
        end
    end
    return pxtbl
end

function Newserver_Hongbao_Client2_Info_Help()
    PushEvent("CCSHOP_HELP", 232)

end


--领取450活跃奖励
function NewServerHongbaoBossReward()

    local nTodayActivePoint = Player:GetData("TODAYACTIVEPOINT")
    Newserver_Hongbao_Client3_Text2:SetText(ScriptGlobal_Format("#{CJZH_250313_44}",nTodayActivePoint))

    if nTodayActivePoint < 450 then
        PushDebugMessage("#{CJZH_250313_10}")
        return
    end

    local nReciveReward =    Pneuma:GetMF(5094)
    if nReciveReward == 1 then
        PushDebugMessage("#{CJZH_250313_09}")
        return
    end

    local myLevel = Player:GetData("LEVEL")
    if myLevel < 60 then
        PushDebugMessage("#{CJZH_250313_08}")
        return
    end

    Clear_XSCRIPT()
	    Set_XSCRIPT_ScriptID(999676)
	    Set_XSCRIPT_Function_Name("ReciveBossReward")
	    Set_XSCRIPT_Parameter(0, 1)
	    Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end    

function NewServerHongbaoUpadateBossReward(nOpenBoss)
   local nReciveReward =    Pneuma:GetMF(5094)

   local nTodayActivePoint = Player:GetData("TODAYACTIVEPOINT")

   Newserver_Hongbao_Left_Buttontab03_Tips:Hide()
   if nOpenBoss == 0 then
        Newserver_Hongbao_Client3:Hide()
        Newserver_Hongbao_Left_Buttontab03:Hide()
        Newserver_Hongbao_Left_Buttontab01_Line2:Show()
        Newserver_Hongbao_Left_Buttontab01_Line1:Hide()
   else
        Newserver_Hongbao_Left_Buttontab03:Show()
        Newserver_Hongbao_Left_Buttontab01_Line1:Show()
        Newserver_Hongbao_Left_Buttontab01_Line2:Hide()

        if nReciveReward ~= 1 and nTodayActivePoint >= 450 then
            Newserver_Hongbao_Left_Buttontab03_Tips:Show()
       end    
   end

end   


function Newserver_Hongbao_BossReward_Refresh()

    --活跃度
    local nTodayActivePoint = Player:GetData("TODAYACTIVEPOINT")
    Newserver_Hongbao_Client3_Text2:SetText(ScriptGlobal_Format("#{CJZH_250313_44}",nTodayActivePoint))

    -- VIP等级
    local hb_info = Lua_GetXinFuHongBaoDataInfo()
    local vipLevel =  hb_info.YearFuFei

    Newserver_Hongbao_Client3_Text:SetText(ScriptGlobal_Format("#{CJZH_250313_03}",vipLevel))

    local nReciveReward =    Pneuma:GetMF(5094)

    local nIndex  = 1
    for i =1, table.getn(g_Newserver_Hongbao_bossReward) do 
        if vipLevel >= g_Newserver_Hongbao_bossReward[i].vipLevel   then
            nIndex = i
        end
    end

    local nOpenBoss,beginTime,EndTime = DataPool:Lua_OpenNewServerBoss()

    local nBeginYear =  math.floor(beginTime/10000)
    local nBeginTemp = math.mod(beginTime,10000)
    local nBeginMonth =  math.floor(nBeginTemp/100)
    local nBeginDay = math.mod(beginTime,100)


    local nEndYear =  math.floor(EndTime/10000)
    local nEndTemp = math.mod(EndTime,10000)
    local nEndMonth =  math.floor(nEndTemp/100)
    local nEndDay = math.mod(EndTime,100)


    Newserver_Hongbao_Client3_Info:SetText( ScriptGlobal_Format("#{CJZH_250313_02}",nBeginYear,nBeginMonth,nBeginDay,nEndYear,nEndMonth,nEndDay) )

    Newserver_Hongbao_Left_Buttontab03_Tips:Hide()
    if nReciveReward ~= 1 and nTodayActivePoint >= 450 then
         Newserver_Hongbao_Left_Buttontab03_Tips:Show()
    end
 

    local rewraInfo = g_Newserver_Hongbao_bossReward[nIndex]
    if rewraInfo ~= nil then
        local theAction	= DataPool:CreateActionItemForShow(rewraInfo.itemid, rewraInfo.num)
        if theAction:GetID() ~= 0 then 
            Newserver_Hongbao_Client3_Text_Icon1:SetActionItem(theAction:GetID())
        end
    end

    if nReciveReward == 1 then
        Newserver_Hongbao_Client3_Text_Icon1_Btn:Hide()
        Newserver_Hongbao_Client3_Text_Icon1_Received:Show()
        Newserver_Hongbao_Client3_Text_Icon1_Mask:Show()
        Newserver_Hongbao_Client3_Text_Icon1_Animate:Hide()
    else
        Newserver_Hongbao_Client3_Text_Icon1_Btn:Show()
        Newserver_Hongbao_Client3_Text_Icon1_Received:Hide()
        Newserver_Hongbao_Client3_Text_Icon1_Mask:Hide()

        if nTodayActivePoint >= 450 then
            Newserver_Hongbao_Client3_Text_Icon1_Animate:Show()
        else
            Newserver_Hongbao_Client3_Text_Icon1_Animate:Hide()
        end
    end
end

function Newserver_Hongbao_Client3_Help()
    PushEvent("CCSHOP_HELP", 235)
end