local adjest_pos
local frame -- for shop content
local selected_catalog
local catalog_btns
local catalog_btns2
local catalog_btns_red
local catalog_btns_red2
local catalog_btns_lock
local catalog_btns_lock2
local actions = {}
local cur_list =
{
    -- id in config
    -- name, show id, time_type, time_start, time_end, num, price
}

local level_images =
{
    "set:Pretty01 image:Normal_1",
    "set:Pretty01 image:Normal_2",
    "set:Pretty01 image:Normal_3",
    "set:Pretty01 image:Normal_4",
    "set:Pretty01 image:Normal_5",
    "set:Pretty01 image:Normal_6",
    "set:Pretty01 image:Normal_7",
    "set:Pretty01 image:Normal_8",
    "set:Pretty01 image:Normal_9",
    "set:Pretty01 image:Normal_10",
	"set:Pretty01 image:Normal_11",
}

local pretty_shop_money_images = {
	"set:Pretty01 image:Small_Yuanbao",			-- 元宝
	"set:CommonFrame38 image:Lace_JiaoziJin2",	-- 金币
	"set:Pretty01 image:Small_Yubi",			-- 代币
}


local pretty_shop_zhekou_images = {
	"set:Jincheng01 image:Zhe_BK",   -- 显示红色的
	"set:Pretty01 image:Discount_BK", --正常的
}

local g_Pretty_Shop_Limit_BeginDay = 20210409
local g_Pretty_Shop_Limit_EndDay = 20210411

--时装代币购买
local g_wg_coinbind = 38005274
local g_wg_coin = 38005275

-------------------------------------------------
--以下是周年庆特写参数---------------------------
-------------------------------------------------

--周年庆放出的焦骨时装 ZNQ_ITEMIDS
 
local g_ZNQ_ITEMIDS = {20307227,30008212,10126219,38005256}
local g_ZNQ_TIPS_CHECKID =  38005256

--周年庆时装资格活动开关
local g_ZNQ_OPEN = 1
--周年庆时间
local g_ZNQ_LimitDate = {
	20210422,
	20210512,
}
--临时激活商店等级
local g_ZNQ_ShopUIInd = 4

--临时折扣最大力度
local g_DiscountMax = 5

local g_Pretty_Shop_Limit_ItemTimers = {
	20210422,
	20210423
}

local function findItemByID(ID)
	for i, itemID in g_ZNQ_ITEMIDS do
		if itemID == ID then
			return true
		end
	end
	return false
end

--**********************************
--是否临时激活
--**********************************
local function ZNQ_IsTempActiveTempShop(curData)
	if not curData then
		curData = WGAch:GetCJMaxCur()
	end
	local today = tonumber(DataPool:GetServerDayTime())
	if today >= g_ZNQ_LimitDate[1] and today <= g_ZNQ_LimitDate[2]  then
		if curData.param0 == 1 and curData.cur_level < g_ZNQ_ShopUIInd  then
			return 1
		end
	end	
	return 0
end



--**********************************
--是否永久激活
--**********************************
local function ZNQ_IsNotActiveTempShop()
	local curData = WGAch:GetCJMaxCur()
	if curData.param0 ~= 1 and curData.cur_level < g_ZNQ_ShopUIInd then
		return 1
	end
	return 0
end


--**********************************
--是否激活临时购买资格 
--**********************************
local function ZNQ_IsActiveTempShop()
	local curData = WGAch:GetCJMaxCur()
	if curData.param0 == 1 or curData.cur_level >= g_ZNQ_ShopUIInd then
		return 1
	end
	return 0
end

--***************************************************
--获取折扣数值和最小值、最大值、折扣次数已经用光则为1
--***************************************************
local function ZNQ_OnGetDiscount()
	local nowday = tonumber(DataPool:GetServerDayTime())
	local curData = WGAch:GetCJMaxCur()
	local nMDData = curData.param1
	local nMDDay = math.floor(nMDData/10000)
	local nTodaySHFlag = 0
	if nowday == nMDDay then
		nTodaySHFlag = 1
	end
	local nMDCurDiscount = math.mod(nMDData,100)
	return 100-nMDCurDiscount, 100-g_DiscountMax, nTodaySHFlag
end

--**********************************
--是否处于活动时间 
--**********************************
local function ZNQ_CheckRightTime()
	local today = tonumber(DataPool:GetServerDayTime())
	if today >= g_ZNQ_LimitDate[1] and today <= g_ZNQ_LimitDate[2]  then
		return 1
	end
	
	if today < g_ZNQ_LimitDate[1] then
		return -1
	end
	
	if today > g_ZNQ_LimitDate[2] then
		return -2
	end
	return 0
end

local function isShowLimitShop()
	local curTime2Day = tonumber(DataPool:GetServerDayTime())
	if curTime2Day >= g_Pretty_Shop_Limit_BeginDay and curTime2Day <= g_Pretty_Shop_Limit_EndDay then
		return 1
	end
	return 0
end

local function update_red_point()
	local cur = WGAch:GetCJMaxCur()
	if not cur then
		Lua_TDU_Log("[Pretty_Shop]Error update_red_point: cur = nil")
		return
	end
	if not cur.cur_level then
		Lua_TDU_Log("[Pretty_Shop]Error update_red_point: cur_level = nil")
		return
	end
	local znq = ZNQ_IsTempActiveTempShop(cur)
	Lua_TDU_Log("[Pretty_Shop]update_red_point: cur_level = "..tostring(cur.cur_level))

	if isShowLimitShop() == 1 then
		for k, v in pairs(catalog_btns_red) do
        	v:Hide()
    	end
		if DataPool:Lua_IsRedPointInUIShow(26) == 1 then
			catalog_btns_red[cur.cur_level]:Show()
		end

		for k, v in pairs(catalog_btns_lock) do
			if k <= cur.cur_level or (znq == 1 and k == g_ZNQ_ShopUIInd) then
				v:Hide()
			else
				v:Show()	
			end
		end
	else
		for k, v in pairs(catalog_btns_red2) do
        	v:Hide()
    	end
		if DataPool:Lua_IsRedPointInUIShow(26) == 1 then
			catalog_btns_red2[cur.cur_level]:Show()
		end

		for k, v in pairs(catalog_btns_lock2) do
			if k <= cur.cur_level or (k == g_ZNQ_ShopUIInd and znq == 1) then
				v:Hide()
			else
				v:Show()
			end
		end
	end
end

local function clean()
    selected_catalog = nil
    cur_list = {}
    for k, v in pairs(actions) do
        actions[k]:SetActionItem(-1)
        actions[k] = nil
    end
    actions = {}
end

function Pretty_Shop_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OPEN_WG_SHOP")
	this:RegisterEvent("UPDATE_WG_SHOP")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UPDATE_YUANBAO", false)
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

function Pretty_Shop_OnLoad()
	adjest_pos = Pretty_Shop_Frame:GetProperty("UnifiedPosition")
    frame = Pretty_Shop_Lace
    catalog_btns =
    {
		[0] = Pretty_Shop_ButtonTime,
        [1] = Pretty_Shop_Button01,
        [2] = Pretty_Shop_Button02,
        [3] = Pretty_Shop_Button03,
        [4] = Pretty_Shop_Button04,
        [5] = Pretty_Shop_Button05,
        [6] = Pretty_Shop_Button06,
        [7] = Pretty_Shop_Button07,
        [8] = Pretty_Shop_Button08,
        [9] = Pretty_Shop_Button09,
        [10] = Pretty_Shop_Button10,
		[11] = Pretty_Shop_Button11,
    }
    
    catalog_btns2 = {
    	[1] = Pretty_Shop_Button01_0,
    	[2] = Pretty_Shop_Button02_0,
    	[3] = Pretty_Shop_Button03_0,
    	[4] = Pretty_Shop_Button04_0,
    	[5] = Pretty_Shop_Button05_0,
    	[6] = Pretty_Shop_Button06_0,
    	[7] = Pretty_Shop_Button07_0,
    	[8] = Pretty_Shop_Button08_0,
    	[9] = Pretty_Shop_Button09_0,
    	[10] = Pretty_Shop_Button10_0,
		[11] = Pretty_Shop_Button11_0,
    }
    
    catalog_btns_red = {
		[0] = Pretty_Shop_ButtonTime_tips,
        [1] = Pretty_Shop_Button01_tips,
        [2] = Pretty_Shop_Button02_tips,
        [3] = Pretty_Shop_Button03_tips,
        [4] = Pretty_Shop_Button04_tips,
        [5] = Pretty_Shop_Button05_tips,
        [6] = Pretty_Shop_Button06_tips,
        [7] = Pretty_Shop_Button07_tips,
        [8] = Pretty_Shop_Button08_tips,
        [9] = Pretty_Shop_Button09_tips,
        [10] = Pretty_Shop_Button10_tips,
		[11] = Pretty_Shop_Button11_tips,
    }
    
    catalog_btns_red2 = {
    	[1] = Pretty_Shop_Button01_0_tips,
    	[2] = Pretty_Shop_Button02_0_tips,
    	[3] = Pretty_Shop_Button03_0_tips,
    	[4] = Pretty_Shop_Button04_0_tips,
    	[5] = Pretty_Shop_Button05_0_tips,
    	[6] = Pretty_Shop_Button06_0_tips,
    	[7] = Pretty_Shop_Button07_0_tips,
    	[8] = Pretty_Shop_Button08_0_tips,
    	[9] = Pretty_Shop_Button09_0_tips,
    	[10] = Pretty_Shop_Button10_0_tips,
		[11] = Pretty_Shop_Button11_0_tips,
    }
    
    catalog_btns_lock = {
		[0] = Pretty_Shop_ButtonTimeLock,
        [1] = Pretty_Shop_Button01Lock,
        [2] = Pretty_Shop_Button02Lock,
        [3] = Pretty_Shop_Button03Lock,
        [4] = Pretty_Shop_Button04Lock,
        [5] = Pretty_Shop_Button05Lock,
        [6] = Pretty_Shop_Button06Lock,
        [7] = Pretty_Shop_Button07Lock,
        [8] = Pretty_Shop_Button08Lock,
        [9] = Pretty_Shop_Button09Lock,
        [10] = Pretty_Shop_Button10Lock,
		[11] = Pretty_Shop_Button11Lock,
    }
    
    catalog_btns_lock2 = {
    	[1] = Pretty_Shop_Button01_0Lock,
    	[2] = Pretty_Shop_Button02_0Lock,
    	[3] = Pretty_Shop_Button03_0Lock,
    	[4] = Pretty_Shop_Button04_0Lock,
    	[5] = Pretty_Shop_Button05_0Lock,
    	[6] = Pretty_Shop_Button06_0Lock,
    	[7] = Pretty_Shop_Button07_0Lock,
    	[8] = Pretty_Shop_Button08_0Lock,
    	[9] = Pretty_Shop_Button09_0Lock,
    	[10] = Pretty_Shop_Button10_0Lock,
		[11] = Pretty_Shop_Button11_0Lock,
    }
end

local res_names =
{
    ["price"] = "Pretty_Shop_CoinAItem1_Cost",
    ["leftnum"] = "Pretty_Shop_CoinAItem1_Num",
    ["leftnumbk"] = "Pretty_Shop_CoinAItem1_NumBK",
    ["name"] = "Pretty_Shop_CoinAItem1_Name",
	["action"] = "Pretty_Shop_CoinAItem1_Icon",
	["look"]  = "Pretty_Shop_CoinAItem1_EyeSign",
    ["btn"] = "Pretty_Shop_CoinAItem1Btn",
    ["imageqin"] = "Pretty_Shop_CoinAItem1_IconMark",
    ["imagezhou"] = "Pretty_Shop_CoinAItem1_IconMark2",
    ["imagexian"] = "Pretty_Shop_CoinAItem1_IconMark3",
    ["sellcutnum"] = "Pretty_Shop_CoinAItem1_Discount",
    ["sellcutbk"] = "Pretty_Shop_CoinAItem1_DiscountBK",
    ["imagetime"] = "Pretty_Shop_CoinAItem1_DiscountSign",
    ["imagetimebk"] = "Pretty_Shop_CoinAItem1_TimeBK",
    ["moneyicon"] = "Pretty_Shop_CoinAItem1_CostSign"
}

local time_type =
{
    normal = 0,
    week   = 1,
    specify= 2,
}

local function level_show()
    local text = Pretty_Shop_Text
    local cur = WGAch:GetCJMaxCur()
    assert(type(cur) == "table")
    local max_value = WGAch:GetMaxVal()
    if cur.cur_level == cur.max_level then
		text:SetText(ScriptGlobal_Format("#{WGPF_191106_14}", cur.cur_value))
    else
        text:SetText(ScriptGlobal_Format("#{WGPF_191106_13}", cur.cur_value, cur.max_value))
    end

    text = Pretty_Shop_Text2
   	local textIcon = Pretty_Shop_PicDOT
    if cur.cur_level >= selected_catalog then
        text:Hide()
        textIcon:Hide()
    else
        text:Show()
        textIcon:Show()
        local val = WGAch:GetLvScore(selected_catalog)
        text:SetText(ScriptGlobal_Format("#{WGPF_191106_37}", val))
    end

    local pic = Pretty_Shop_Pic
    pic:SetProperty("Image", level_images[cur.cur_level] or "")
end

local function date(t)
		local year = math.floor(t/10000)
    local month_day = math.mod(t,10000)
    local month = math.floor(month_day/100)
    local day = math.mod(month_day,100)
    return year, month, day
end

--: !!!reloadscript =Pretty_Shop
local function cur_show()
		local curTime2Day = tonumber(DataPool:GetServerDayTime())
		if isShowLimitShop() == 1 then
			Pretty_Shop_Bk1:Hide()
			Pretty_Shop_Bk2:Show()
		else
			Pretty_Shop_Bk1:Show()
			Pretty_Shop_Bk2:Hide()
		end
		
    for k, v in pairs(actions) do
        actions[k]:SetActionItem(-1)
        actions[k] = nil
    end
    actions = {}
    frame:Clear()

    local cnt = table.getn(cur_list)
    for idx = 1, cnt do
        local item = cur_list[idx]
        local one = frame:AddChild("Pretty_Shop_CoinAItem1")
        local btn =assert(one:GetSubItem(res_names["action"])) 
		btn:SetEvent("Clicked", string.format("PS_OnButton(%d)", item.id))
		
		local lookBtn = one:GetSubItem(res_names["look"])
		--lookBtn:Hide()
		btn =assert(lookBtn)
		-- 是否可以预览
		if item.preview > 0 then
			btn:Show()
		else
			btn:Hide()
		end
		btn:SetEvent("Clicked", string.format("Pretty_Shop_Look_OnButton(%d)", item.id))

        --设置商品价格显示
        local strPrice = ""
        local strCutTip = ""
		local fmtCut = item.sellcut/100
        --设置商品折扣显示
        local sellCutBk = assert(one:GetSubItem(res_names["sellcutbk"]))
        if item.moneytype == 0 then
        	--周年庆特写
			if g_ZNQ_OPEN == 1 then
				if ZNQ_CheckRightTime() == 1 and item.item_id == g_ZNQ_TIPS_CHECKID then
        			local ranDis,ranDisMax,disUsed = ZNQ_OnGetDiscount()
					strCutTip = "#{ZNFCSZ_210316_28}"
        			fmtCut = tonumber(string.format("%.2f",(item.sellcut/100)*ranDis*0.01))
				end

				local today = tonumber(DataPool:GetServerDayTime())
				if today >= g_Pretty_Shop_Limit_ItemTimers[1] and today < g_Pretty_Shop_Limit_ItemTimers[2] and item.item_id == g_ZNQ_TIPS_CHECKID then
					sellCutBk:SetToolTip(strCutTip)
				end
        	end
        	
        	strPrice = ScriptGlobal_Format("#{WGPF_191106_77}", item.price*fmtCut)
        elseif item.moneytype == 1 then
        	strPrice = ScriptGlobal_Format("#{WGPF_191106_78}",item.price*fmtCut)
        elseif item.moneytype == 2 then
        	strPrice = ScriptGlobal_Format("#{WGPF_191106_82}", item.price*fmtCut)
        end
		one:GetSubItem(res_names["price"]):SetText(strPrice)
		
		-- 显示代币图标 这个内容是跟类型，一一对应的，如果改变，需要同时调整table内容
		local moneyimage = pretty_shop_money_images[item.moneytype + 1]
		one:GetSubItem(res_names["moneyicon"]):SetProperty("Image", moneyimage)

		local sellCutNum = assert(one:GetSubItem(res_names["sellcutnum"]))
      
		if (fmtCut > 0 and fmtCut < 1) or strCutTip ~= "" then
			-- PushDebugMessage("最低折扣 Tips 要显示了！！！！！")
        	sellCutBk:Show()
        	sellCutNum:Show()
        	--保留两位有效数字
        	if math.mod(fmtCut*100,10) ~= 0 then
        		sellCutNum:SetText("#cffe1b8" .. string.format("%.1f",fmtCut*10) .. "折")
        	else
        		sellCutNum:SetText("#cffe1b8" .. fmtCut*10 .. "折")
			end
			if item.item_id == g_ZNQ_TIPS_CHECKID then
				sellCutBk:SetProperty("Image",pretty_shop_zhekou_images[1] )
			end
        else
        	sellCutBk:Hide()
			sellCutNum:Hide()	

        end
        
        --设置商品限量标示[售罄 周限量 永久限量]
        local imageqing = assert(one:GetSubItem(res_names["imageqin"]))
        local imagezhou = assert(one:GetSubItem(res_names["imagezhou"]))
        local imagexian = assert(one:GetSubItem(res_names["imagexian"]))
        local leftnum = assert(one:GetSubItem(res_names["leftnum"]))
        local leftnumbk = assert(one:GetSubItem(res_names["leftnumbk"]))
        local imageTime = assert(one:GetSubItem(res_names["imagetime"]))
        local imagetimebk = assert(one:GetSubItem(res_names["imagetimebk"]))
        if item.count == -1 then
        	--不限购
        	imageqing:Hide()
        	imagezhou:Hide()
        	imagexian:Hide()
        	leftnum:Hide()
        	leftnumbk:Hide()
        	imageTime:Hide()
			imagetimebk:Hide()
			
        	if item.time_type == time_type.specify then
        		--自定义限购设置限购日期
				imageTime:Show()
				imagetimebk:Show()
        		local year_s, month_s, day_s = date(item.time_start)
            	local year_e, month_e, day_e = date(item.time_end)
        		local sMsg = ScriptGlobal_Format("#{WGPF_191106_66}", year_s, month_s, day_s, year_e, month_e, day_e)
        		imageTime:SetToolTip(sMsg)
        	end
        else
        	--限购
        	--剩余数量设置
        	leftnum:Show()
        	leftnumbk:Show()
        	if item.count - item.now >= 0 then
        		leftnum:SetText("" .. item.count - item.now)
        	else
        		leftnum:SetText("0")
        	end
        	--设置限购图标
        	if item.time_type == time_type.specify then
        		imageqing:Hide()
        		imagezhou:Hide()
        		imagexian:Show()
        		--自定义限购设置限购日期
				imageTime:Show()
				imagetimebk:Show()
        		local year_s, month_s, day_s = date(item.time_start)
            local year_e, month_e, day_e = date(item.time_end)
        		local sMsg = ScriptGlobal_Format("#{WGPF_191106_66}", year_s, month_s, day_s, year_e, month_e, day_e)
        		imageTime:SetToolTip(sMsg)
        	elseif item.time_type == time_type.week then
        		imageqing:Hide()
        		imagezhou:Show()
        		imagexian:Hide()
				imageTime:Hide()
				imagetimebk:Hide()
        	elseif item.time_type == time_type.normal then
        		imageqing:Hide()
        		imagezhou:Hide()
        		imagexian:Hide()
				imageTime:Hide()
				imagetimebk:Hide()
        	end
        	
        	--售罄处理
        	if item.count - item.now <= 0 then
				imageqing:Show()
				leftnum:Hide()
				leftnumbk:Hide()
        		-- imagezhou:Show()
        		-- imagexian:Hide()
        	end
        end
        
				--设置商品名称
        one:GetSubItem(res_names["name"]):SetText("#cffe1b8" .. item.name)
				--设置actionbutton
        local action_item = DataPool:CreateActionItemForShow(item.show_id, item.gpcount)
        if action_item:GetID() ~= 0 then
            local action = one:GetSubItem(res_names["action"])
            action:SetActionItem(action_item:GetID())
            actions[idx] = action
        end
    end
end

local function select_catalog(which)
    	assert(selected_catalog)
		if not catalog_btns2[selected_catalog] or not catalog_btns2[selected_catalog].SetCheck then
			return
		end
		if isShowLimitShop() == 1 then
			for k, v in pairs(catalog_btns) do
				v:SetCheck(0)
				v:SetToolTip("")
			end
    		catalog_btns[selected_catalog]:SetCheck(1)
		else
			for k, v in pairs(catalog_btns2) do
				v:SetCheck(0)
				v:SetToolTip("")
    		end
    		catalog_btns2[selected_catalog]:SetCheck(1)
		end

		cur_list = WGAch:GetShopByLv(selected_catalog)
		assert(type(cur_list) == "table")
		table.sort(cur_list,function(a, b) return a.sortnum > b.sortnum end) 

		level_show()
		cur_show()
		local sYuanBaoNum = ScriptGlobal_Format("#{WGPF_210226_07}",Player:GetData("YUANBAO"))	
		Pretty_Shop_TextYuanbao:SetText(sYuanBaoNum)
   	
   	-- local itemcount = PlayerPackage:CountAvailableItemByIDTable(g_wg_coin)
		-- local itemcountBind = PlayerPackage:CountAvailableItemByIDTable(g_wg_coinbind)
		-- local sDBNum = ScriptGlobal_Format("#{ZNFCSZ_210316_56}",itemcount+itemcountBind)	
		-- Pretty_Shop_Text_Daibi:SetText(sDBNum)
		
		--周年庆活动特写
		-- if g_ZNQ_OPEN == 1 and ZNQ_CheckRightTime() == 1 then
		-- 	Pretty_Shop_Text_Daibi:SetToolTip("#{ZNFCSZ_210316_57}")
		-- end
		if g_ZNQ_OPEN == 1 and ZNQ_CheckRightTime() == 1  then

			if ZNQ_IsTempActiveTempShop() == 1  then --临时激活
				Pretty_Shop_Text_Fanchang:Hide()
				catalog_btns_lock2[g_ZNQ_ShopUIInd]:Hide()
				catalog_btns_lock[g_ZNQ_ShopUIInd]:Hide()
				catalog_btns2[g_ZNQ_ShopUIInd]:SetToolTip("#{ZNFCSZ_210316_26}")
			elseif ZNQ_IsNotActiveTempShop() == 1 then  --没有任何资格
				Pretty_Shop_Text_Fanchang:Show()
				Pretty_Shop_Text_Fanchang:SetText("#{ZNFCSZ_210316_24}")
				catalog_btns2[g_ZNQ_ShopUIInd]:SetToolTip("#{ZNFCSZ_210316_25}")
			else
				Pretty_Shop_Text_Fanchang:Hide()
				catalog_btns2[g_ZNQ_ShopUIInd]:SetToolTip("")
			end
		else
			Pretty_Shop_Text_Fanchang:Hide()
		end
end

local function send_request(idx,bagType)
    assert(idx)
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(888051)
    Set_XSCRIPT_Function_Name("WaiGuanShopBuy")
	Set_XSCRIPT_Parameter(0, idx)
	Set_XSCRIPT_Parameter(1, 1)
	Set_XSCRIPT_Parameter(2, bagType)
    Set_XSCRIPT_ParamCount(3)
    Send_XSCRIPT()
end

function PS_OnButton(idx)
	--判断材料 和道具栏
	local cnt = table.getn(cur_list)
	local itemCgn = nil
	for i = 1, cnt do
		if cur_list[i].id == idx then
			itemCgn = cur_list[i]
		end
	end

	local nBagType = itemCgn.bagType
    send_request(idx,nBagType)
end

--点击预览
function Pretty_Shop_Look_OnButton(idx)
	-- 先判断是否为展示道具
	--local showitem = 1
	--if showitem < 1 then
	--	return
	--end

	-- 根据ID获得当前需要的展示
	local dressid,hairid,faceid = Exterior:LuaFnGetPrettyShopPreviewDressInfo(idx)
	if dressid < 0 and hairid < 0 and faceid < 0 then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(888051)
		Set_XSCRIPT_Function_Name("DressPreview")
		Set_XSCRIPT_Parameter(0, dressid)
		Set_XSCRIPT_Parameter(1, hairid)
		Set_XSCRIPT_Parameter(2, faceid)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end


function PS_Select_Catalog(which)
	if isShowLimitShop() == 1 then
		selected_catalog = (which or selected_catalog) or 0
		--显示限时商店时间提示
		if selected_catalog == 0 then
			local year_s, month_s, day_s = date(g_Pretty_Shop_Limit_BeginDay)
			local year_e, month_e, day_e = date(g_Pretty_Shop_Limit_EndDay)
			local sMsg = ScriptGlobal_Format("#{WGPF_210226_06}", year_s, month_s, day_s, year_e, month_e, day_e)
			Pretty_Shop_TimeText:Show()
			Pretty_Shop_TimeText:SetText(sMsg)
		else
			Pretty_Shop_TimeText:Hide()
		end
	else
		selected_catalog = (which or selected_catalog) or 1
		--隐藏限时商店时间提示
		Pretty_Shop_TimeText:Hide()
	end
    
    select_catalog(selected_catalog)
    local cur = WGAch:GetCJMaxCur()
    if cur.cur_level == selected_catalog then
    	if DataPool:Lua_IsRedPointInUIShow(26) == 1 then
    		DataPool:Lua_SetRedPointInUIShow(26, 0)
    		PushEvent("UPDATE_REDPOINT_IN_UI_EX")
    	end
    end
    update_red_point()
end

function Pretty_Shop_OnEvent(event)
    if event == "UI_COMMAND" then
        local cmd = tonumber(arg0)
		if cmd == 88805101 then
			local cmd_str = Get_XParam_STR(0)
			if cmd_str == "REFERES_YAOHUABI_SHOW" then
				if this:IsVisible() then
					local huayaobi = Get_XParam_INT(1)		
					local sYuanBaoNum = ScriptGlobal_Format("#{WGPF_191106_85}",huayaobi)	
					Pretty_Shop_Text_Daibi:SetText(sYuanBaoNum)
				end
			else
				clean()
				this:Show()
				update_red_point()

				local seleLevel = Get_XParam_INT(2)	
				PS_Select_Catalog(seleLevel)		
				OpenWindow("Packet")

				local huayaobi = Get_XParam_INT(1)		
				local sYuanBaoNum = ScriptGlobal_Format("#{WGPF_191106_85}",huayaobi)	
				Pretty_Shop_Text_Daibi:SetText(sYuanBaoNum)
			end
        end
    elseif event == "OPEN_WG_SHOP" then
        clean()
        this:Show()
        update_red_point()
        PS_Select_Catalog()
        OpenWindow("Packet")
    elseif event == "UPDATE_WG_SHOP" then
        if this:IsVisible() == false then
            return
        end
        assert(selected_catalog)
        local oldScrollPos = frame:GetScrollPosition()	--保存上一次滚动条位置
        PS_Select_Catalog()
        frame:SetScrollPosition(oldScrollPos)
    elseif event == "UPDATE_YUANBAO" then
    	local sYuanBaoNum = ScriptGlobal_Format("#{WGPF_210226_07}",Player:GetData("YUANBAO"))	
    	Pretty_Shop_TextYuanbao:SetText(sYuanBaoNum)
    elseif event == "PACKAGE_ITEM_CHANGED_EX" then
    	-- local itemcount = PlayerPackage:CountAvailableItemByIDTable(g_wg_coin)
		-- 	local itemcountBind = PlayerPackage:CountAvailableItemByIDTable(g_wg_coinbind)
		-- 	local sDBNum = ScriptGlobal_Format("#{ZNFCSZ_210316_56}",itemcount+itemcountBind)	
		-- 	Pretty_Shop_Text_Daibi:SetText(sDBNum)
    elseif event == "UPDATE_REDPOINT_IN_UI" then
    	update_red_point()
    end

    if this:IsVisible() then
        if event == "ADJEST_UI_POS" or
			event == "VIEW_RESOLUTION_CHANGED" then
				Pretty_Shop_ResetPos()
        elseif event == "HIDE_ON_SCENE_TRANSED" then
            this:Hide()
        end
    end
end

function Pretty_Shop_ResetPos()
    Pretty_Shop_Frame:SetProperty("UnifiedPosition", adjest_pos)
end

function Pretty_Shop_OnClosed()
    this:Hide()
	clean()
end

function Pretty_Shop_OnHiden()
	Pretty_Shop_OnClosed()
	PushEvent("CLOSE_MYSELF_PRETTYBUY")
end

function PS_Help()
    Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(888051)
    Set_XSCRIPT_Function_Name("help")
    Set_XSCRIPT_Parameter(0, 2)
    Set_XSCRIPT_ParamCount(1)
    Send_XSCRIPT()
end

function Pretty_Shop_OpenWaiGuanAch()
	PushEvent("OPEN_WG_ACHIEVEMENT")
end


