
local g_Token_Shop_UnifiedPosition;

local g_Token_Shop_ButtonCDTime = 500
local g_Token_Shop_LastClickTime = 0

local g_Token_Shop_BuyConfirm = 0
local g_Token_Shop_RefershConfirm = 0

local g_Token_Shop_CurPage = 1
local g_Token_Shop_CDTime = 0.2
local g_Token_Shop_LastTime = 0

local g_Token_Shop_YBList = {};
local g_Token_Shop_DBList = {};

local g_Token_Shop_ShopId = 0;
local g_Token_Shop_ReFreshNum = -1;
local g_Token_Shop_ReFreshAllNum = -1;
local g_Token_Shop_DBCount = -1;
local g_Token_Shop_IsHaveBuy = 0;
local g_Token_Shop_IsKaJi = 0;

local g_Token_Shop_YBItem = "";
local g_Token_Shop_DBItem = "";

local g_Token_Shop_YBItemList = {
[1] = {39920085, 2, 60, 2, 0, 8.6, 1}, 
[2] = {39920089, 1, 85, 5, 0, 8.5, 1}, 
[3] = {39921313, 2, 170, 17, 0, 8.5, 1}, 
[4] = {39920163, 20, 140, 40, 0, 7.0, 1},
}; -- id num cost idx canbuy
local g_Token_Shop_DBItemList = {
[1] = {39920462, 1, 85, 2, 0}, 
[2] = {39920329, 1, 40, 4, 0}, 
[3] = {39920163, 1, 2, 11, 0}, 
[4] = {39920332, 1, 20, 18, 0},
};

local g_Token_Shop_nContentButton = {}
local g_Token_Shop_Page2_RewardClient = {
[1] = "Token_Shop_RewardItemClient_1",
[2] = "Token_Shop_RewardItemClient_2",
[3] = "Token_Shop_RewardItemClient_3",
}
local g_Token_Shop_Page2_RewardClientList = {
[1] = {"Token_Shop_RewardItemClient_1_Item1"},
[2] = {"Token_Shop_RewardItemClient_2_Item1","Token_Shop_RewardItemClient_2_Item2"},
[3] = {"Token_Shop_RewardItemClient_3_Item1","Token_Shop_RewardItemClient_3_Item2","Token_Shop_RewardItemClient_3_Item3"},
}

local g_Token_Shop_ShowFanLiTips = 0
local g_Token_Shop_IsGetFanLi = {0, 0, 0, 0, 0, 0}
local g_Token_Shop_Cost = 0
local g_Token_Shop_FanliList = {
	[1] = { Exch = 4000,  	ItemList = { {38000956, 3}, }, },
	[2] = { Exch = 12000,  	ItemList = { {38000956, 3}, {38008153, 2}, }, },
	[3] = { Exch = 24000, 	ItemList = { {38000956, 4}, {38008153, 3}, }, },
	[4] = { Exch = 40000,	ItemList = { {38000956, 4}, {38008153, 5}, }, },
	[5] = { Exch = 100000, 	ItemList = { {38000956, 8}, {38008153, 12},}, },
	[6] = { Exch = 160000, ItemList = { {38000956, 10},{38008153, 18},}, },
}
local g_Token_Shop_FanliList_KJ = {
	[1] = { Exch = 4000,  	ItemList = { {38000956, 3}, }, },
	[2] = { Exch = 12000,  	ItemList = { {38000956, 3}, {38000571, 12}, }, },
	[3] = { Exch = 24000, 	ItemList = { {38000956, 4}, {38003001, 4},  }, },
	[4] = { Exch = 40000,	ItemList = { {38000956, 4}, {38000571, 28}, }, },
	[5] = { Exch = 100000, 	ItemList = { {38000956, 8}, {38006327, 3},  }, },
	[6] = { Exch = 160000, ItemList = { {38000956, 10},{38006327, 5},  }, },	
}

function Token_Shop_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	
	this:RegisterEvent("UPDATE_YUANBAO")
end

function Token_Shop_OnLoad()
	g_Token_Shop_UnifiedPosition = Token_Shop:GetProperty("UnifiedPosition")
	
	g_Token_Shop_YBList[1] = {Token_Shop_Yuanbao1_Icon, Token_Shop_Yuanbao1_Item, Token_Shop_Yuanbao1_Count, 
								Token_Shop_Yuanbao1_Icon_Mask, Token_Shop_Yuanbao1_Discount, Token_Shop_Yuanbao1_Unbind, Token_Shop_Yuanbao1_DiscountBK}
	g_Token_Shop_YBList[2] = {Token_Shop_Yuanbao2_Icon, Token_Shop_Yuanbao2_Item, Token_Shop_Yuanbao2_Count,  
								Token_Shop_Yuanbao2_Icon_Mask, Token_Shop_Yuanbao2_Discount, Token_Shop_Yuanbao2_Unbind, Token_Shop_Yuanbao2_DiscountBK}
	g_Token_Shop_YBList[3] = {Token_Shop_Yuanbao3_Icon, Token_Shop_Yuanbao3_Item, Token_Shop_Yuanbao3_Count,  
								Token_Shop_Yuanbao3_Icon_Mask, Token_Shop_Yuanbao3_Discount, Token_Shop_Yuanbao3_Unbind, Token_Shop_Yuanbao3_DiscountBK}
	g_Token_Shop_YBList[4] = {Token_Shop_Yuanbao4_Icon, Token_Shop_Yuanbao4_Item, Token_Shop_Yuanbao4_Count,  
								Token_Shop_Yuanbao4_Icon_Mask, Token_Shop_Yuanbao4_Discount, Token_Shop_Yuanbao4_Unbind, Token_Shop_Yuanbao4_DiscountBK}	
	
	g_Token_Shop_DBList[1] = {Token_Shop_Cuiyi1_Icon, Token_Shop_Cuiyi1_Item, Token_Shop_Cuiyi1_Count, Token_Shop_Cuiyi1_Icon_Mask}
	g_Token_Shop_DBList[2] = {Token_Shop_Cuiyi2_Icon, Token_Shop_Cuiyi2_Item, Token_Shop_Cuiyi2_Count, Token_Shop_Cuiyi2_Icon_Mask}
	g_Token_Shop_DBList[3] = {Token_Shop_Cuiyi3_Icon, Token_Shop_Cuiyi3_Item, Token_Shop_Cuiyi3_Count, Token_Shop_Cuiyi3_Icon_Mask}
	g_Token_Shop_DBList[4] = {Token_Shop_Cuiyi4_Icon, Token_Shop_Cuiyi4_Item, Token_Shop_Cuiyi4_Count, Token_Shop_Cuiyi4_Icon_Mask}
	
end

function Token_Shop_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 89292101 ) then
	
		--打开商店	
		g_Token_Shop_ReFreshNum = Get_XParam_INT(0)		
		if g_Token_Shop_ReFreshNum < 0 then
			this:Hide()
		end
		g_Token_Shop_DBCount = Get_XParam_INT(1)
		g_Token_Shop_IsHaveBuy = Get_XParam_INT(2)	
		g_Token_Shop_IsShowtips = Get_XParam_INT(3)
		g_Token_Shop_ShopId = Get_XParam_INT(4)
		g_Token_Shop_ShowFanLiTips = Get_XParam_INT(5)
		g_Token_Shop_ReFreshAllNum = Get_XParam_INT(6)
		
		g_Token_Shop_YBItem = Get_XParam_STR(0)
		g_Token_Shop_DBItem = Get_XParam_STR(1)
		
		Token_Shop_Update()	--填充数据
		
		Token_Shop_Init()	--填充界面
		
		local bConfirm = Variable:GetVariable("TokenShopBuyConfirm")
		if bConfirm == nil then
			Variable:SetVariable("TokenShopBuyConfirm","1",0)
			bConfirm = 1
		end
			
		local mark = tonumber(bConfirm)
		if mark == 1 then
			Token_Shop_BuyConfirm_Button:SetCheck(1)
		else
			Token_Shop_BuyConfirm_Button:SetCheck(0)
		end
		g_Token_Shop_BuyConfirm = Token_Shop_BuyConfirm_Button : GetCheck()
		
							
		local bRefershConfirm = Variable:GetVariable("TokenShopRefershConfirm")
		if bRefershConfirm == nil then
			Variable:SetVariable("TokenShopRefershConfirm","1",0)
			bRefershConfirm = 1
		end
		mark = tonumber(bRefershConfirm)
		if mark == 1 then
			Token_Shop_RefershConfirm_Button:SetCheck(1)
		else
			Token_Shop_RefershConfirm_Button:SetCheck(0)
		end
		g_Token_Shop_RefershConfirm = Token_Shop_RefershConfirm_Button : GetCheck()
		
		this:Show()
	    
	elseif( event == "UI_COMMAND" 
			and tonumber(arg0) == 89292106 
			and IsWindowShow("Token_Shop") ) then
			
		--刷新商店			
		if IsWindowShow("Weapon_Pre") then
			CloseWindow("Weapon_Pre", true)
		end
		
		if IsWindowShow("Token_Weapon") then
			CloseWindow("Token_Weapon", true)
		end

		g_Token_Shop_ReFreshNum = Get_XParam_INT(0)		
		if g_Token_Shop_ReFreshNum < 0 then
			this:Hide()
		end	
		g_Token_Shop_DBCount = Get_XParam_INT(1)	
		g_Token_Shop_IsHaveBuy = Get_XParam_INT(2)	
		g_Token_Shop_IsShowtips = Get_XParam_INT(3)
		g_Token_Shop_ShopId = Get_XParam_INT(4)
		if g_Token_Shop_IsShowtips ~= nil and g_Token_Shop_IsShowtips == 3 then
			PushDebugMessage("#{SJSD_180817_16}")
		end
		g_Token_Shop_ShowFanLiTips = Get_XParam_INT(5)
		g_Token_Shop_ReFreshAllNum = Get_XParam_INT(6)
		
		g_Token_Shop_YBItem = Get_XParam_STR(0)
		g_Token_Shop_DBItem = Get_XParam_STR(1)
		
		Token_Shop_Update()	--填充数据
		
		Token_Shop_Init()	--填充界面
		
	elseif( event == "UI_COMMAND" 
			and tonumber(arg0) == 89292110 ) then 
			--and IsWindowShow("Token_Shop") ) then 
			
		g_Token_Shop_Cost = 	Get_XParam_INT(0)
		
		g_Token_Shop_ShowFanLiTips = Get_XParam_INT(1)
		
		g_Token_Shop_IsKaJi = Get_XParam_INT(2)
		
		for i = 1, table.getn(g_Token_Shop_IsGetFanLi) do
			g_Token_Shop_IsGetFanLi[i] = Get_XParam_INT(i+2)
		end
		
		Token_Shop_InitFanLi()
			
		this:Show()
	    
	elseif (event == "ADJEST_UI_POS" ) then
		Token_Shop_On_ResetPos()
		
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Token_Shop_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
		
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		Token_Shop_YuanbaoUpdate()
	end

end

--=========================================================
--切换页签
--=========================================================
function Token_Shop_PageClick( clickId )

	if clickId ~= 1 and clickId ~= 2 then
		return
	end
	
	if g_Token_Shop_CurPage == clickId then
		return
	end
	
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_Token_Shop_LastTime < g_Token_Shop_CDTime * 1000) then 
		return
	end
	g_Token_Shop_LastTime = curTime;
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnTokenShopChangePage" )
		Set_XSCRIPT_ScriptID(892921)
		Set_XSCRIPT_Parameter(0, g_Token_Shop_CurPage) 
		Set_XSCRIPT_Parameter(1, clickId) 
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()		
	
end

--=========================================================
--初始化界面
--=========================================================
function Token_Shop_SetUIText()
	if g_Token_Shop_ShopId == 0 then
		Token_Shop_Close()
		return
	end
	
	if	g_Token_Shop_ShopId == 1 or g_Token_Shop_ShopId == 2 then		
		Token_Shop_DragTitle:SetText("#{SJSD_180817_17}")

		if g_Token_Shop_ShopId == 2 then
			Token_Shop_Description_Text:SetText("#{SJSD_180817_80}")
		elseif g_Token_Shop_ShopId == 1 then
			Token_Shop_Description_Text:SetText("#{SJSD_180817_18}")
		end
		
		Token_Shop_Purchase_text:SetText("#{SJSD_180817_19}")
		Token_Shop_Purchase_Help:SetToolTip("#{SJSD_180817_21}")	
		
		Token_Shop_Exchange_text:SetText("#{SJSD_180817_20}")
		Token_Shop_Exchange_Help:SetToolTip("#{SJSD_180817_23}")
		
		Token_Shop_Refresh1_Text:SetText("#{SJSD_180817_30}")
		Token_Shop_ReFresh_Btn1:SetText("#{SJSD_180817_31}")	
		Token_Shop_ReFresh_Btn1:SetToolTip("#{SJSD_180817_32}")		
	elseif g_Token_Shop_ShopId == 3 or g_Token_Shop_ShopId == 4 then
		Token_Shop_DragTitle:SetText("#{QXSD_190615_70}")
		
		local descStr = ScriptGlobal_Format("#{QXSD_190615_29}", g_Token_Shop_ReFreshAllNum)
		Token_Shop_Description_Text:SetText(descStr)
		
		Token_Shop_Purchase_text:SetText("#{QXSD_190615_30}")
		Token_Shop_Purchase_Help:SetToolTip("#{QXSD_190615_90}")	
		
		Token_Shop_Exchange_text:SetText("#{QXSD_190615_31}")
		Token_Shop_Exchange_Help:SetToolTip("#{QXSD_190615_91}")	
		
		Token_Shop_Refresh1_Text:SetText("#{QXSD_190615_92}")
		Token_Shop_ReFresh_Btn1:SetText("#{QXSD_190615_51}")	
		Token_Shop_ReFresh_Btn1:SetToolTip("#{QXSD_190615_80}")	
	end
end

--=========================================================
--初始化界面
--=========================================================
function Token_Shop_Init()
		
	g_Token_Shop_CurPage = 1
	Token_Shop_Button01:SetCheck(1)
	Token_Shop_Button02:SetCheck(0)

	Token_Shop_Page1:Show()
	Token_Shop_Page2:Hide()
	
	Token_Shop_SetUIText()	--设置控件的字典号

	-- 设置元宝数值
	Token_Shop_YuanbaoUpdate()
	
	-- 设置代币数量
	if g_Token_Shop_ShopId == 3 or g_Token_Shop_ShopId == 4 then
		Token_Shop_Remain2_Text:SetText(ScriptGlobal_Format("#{QXSD_190615_82}",g_Token_Shop_DBCount))
	else
		Token_Shop_Remain2_Text:SetText(ScriptGlobal_Format("#{SJSD_180817_29}",g_Token_Shop_DBCount))
	end
	
	-- 返利红点
	Token_Shop_Button02Tips:Hide()
	if g_Token_Shop_ShowFanLiTips == 1 then
		Token_Shop_Button02Tips:Show()
	end
	
	-- 刷新次数
	if g_Token_Shop_ShopId == 3 or g_Token_Shop_ShopId == 4 then
		if tonumber(g_Token_Shop_ReFreshNum) < 500 then
			Token_Shop_Refresh2_Text:SetText(ScriptGlobal_Format("#{QXSD_190615_34}",g_Token_Shop_ReFreshNum))
		else
			Token_Shop_Refresh2_Text:SetText(ScriptGlobal_Format("#{QXSD_190615_78}",g_Token_Shop_ReFreshNum))
		end
	else
		if tonumber(g_Token_Shop_ReFreshNum) < 300 then
			Token_Shop_Refresh2_Text:SetText(ScriptGlobal_Format("#{SJSD_180817_77}",g_Token_Shop_ReFreshNum))
		else
			Token_Shop_Refresh2_Text:SetText(ScriptGlobal_Format("#{SJSD_180817_78}",g_Token_Shop_ReFreshNum))
		end
	end

	DataPool:Lua_ClearXiGuaShopActionItem();	
		for i = 1, table.getn(g_Token_Shop_YBItemList) do
			DataPool:Lua_SetXiGuaShopActionItem( i-1, g_Token_Shop_YBItemList[i][1], g_Token_Shop_YBItemList[i][2] );
			
			g_Token_Shop_YBList[i][2]:SetText("#cfff263"..DataPool:Lua_GetItemNameByIndex(g_Token_Shop_YBItemList[i][1]))
			local textShow = ScriptGlobal_Format("#{SJSD_180817_25}",g_Token_Shop_YBItemList[i][3])
			g_Token_Shop_YBList[i][3]:SetText(textShow)
		end
		for i = 1, table.getn(g_Token_Shop_DBItemList) do
			DataPool:Lua_SetXiGuaShopActionItem( i+3, g_Token_Shop_DBItemList[i][1], g_Token_Shop_DBItemList[i][2] );
			
			g_Token_Shop_DBList[i][2]:SetText("#cfff263"..DataPool:Lua_GetItemNameByIndex(g_Token_Shop_DBItemList[i][1]))
			if g_Token_Shop_ShopId == 3 or g_Token_Shop_ShopId == 4 then
				local textShow = ScriptGlobal_Format("#{QXSD_190615_33}",g_Token_Shop_DBItemList[i][3])
				g_Token_Shop_DBList[i][3]:SetText(textShow)
			else
				local textShow = ScriptGlobal_Format("#{SJSD_180817_26}",g_Token_Shop_DBItemList[i][3])
				g_Token_Shop_DBList[i][3]:SetText(textShow)
			end
		end
	DataPool:Lua_UpdateXiGuaShopActionItem();
	for i=1, 4 do
		local theAction = EnumAction( i-1, "xiguashop_item");
		if theAction:GetID() ~= 0 then
			g_Token_Shop_YBList[i][1]:SetActionItem( theAction:GetID() );
		else
			g_Token_Shop_YBList[i][1]:SetActionItem( -1 );
		end
	end
	for i=5, 8 do
		local theAction = EnumAction( i-1, "xiguashop_item");
		if theAction:GetID() ~= 0 then
			g_Token_Shop_DBList[i-4][1]:SetActionItem( theAction:GetID() );
		else
			g_Token_Shop_DBList[i-4][1]:SetActionItem( -1 );
		end
	end
	
	for idx = 1, 4 do
		if g_Token_Shop_YBItemList[idx][5] == 0 then
			--未购买
			g_Token_Shop_YBList[idx][4]:Hide()
		else
			--已购买
			g_Token_Shop_YBList[idx][4]:Show()
		end
		if g_Token_Shop_DBItemList[idx][5] == 0 then
			--未购买
			g_Token_Shop_DBList[idx][4]:Hide()
		else
			--已购买
			g_Token_Shop_DBList[idx][4]:Show()
		end
		
		--显示折扣
		if g_Token_Shop_YBItemList[idx][6] ~= 10 then
			g_Token_Shop_YBList[idx][5]:Show()	
			g_Token_Shop_YBList[idx][7]:Show()	
			local msgstr = ScriptGlobal_Format("#{SJSD_180817_27}", g_Token_Shop_YBItemList[idx][6])
			g_Token_Shop_YBList[idx][5]:SetText(msgstr)
		else
			g_Token_Shop_YBList[idx][5]:Hide()		
			g_Token_Shop_YBList[idx][7]:Hide()		
		end
		
		if g_Token_Shop_YBItemList[idx][7] == 0 then
			--非绑
			g_Token_Shop_YBList[idx][6]:Show()
		else
			--绑定
			g_Token_Shop_YBList[idx][6]:Hide()
		end
	end
	
end

--=========================================================
--更新界面
--=========================================================
function Token_Shop_Update()
	
	local strItem = g_Token_Shop_YBItem
	for i = 1, 4 do
		local iPos = string.find( strItem, "-" );
		if ( iPos == nil ) then
			Token_Shop_Close()
		else
			local tempstr = string.sub(strItem, 1, iPos-1)
			local temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_Token_Shop_YBItemList[i][1] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_Token_Shop_YBItemList[i][2] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_Token_Shop_YBItemList[i][3] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_Token_Shop_YBItemList[i][4] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_Token_Shop_YBItemList[i][6] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_Token_Shop_YBItemList[i][7] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			strItem = string.sub(strItem, iPos+1, string.len(strItem))
		end
	end

	local strDBItem = g_Token_Shop_DBItem
	for i = 1, 4 do
		local iPos = string.find( strDBItem, "-" );
		if ( iPos == nil ) then
			Token_Shop_Close()
		else
			local tempstr = string.sub(strDBItem, 1, iPos-1)
			local temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_Token_Shop_DBItemList[i][1] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_Token_Shop_DBItemList[i][2] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_Token_Shop_DBItemList[i][3] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			temppos = string.find( tempstr, "*" );
			if temppos ~= nil then
				g_Token_Shop_DBItemList[i][4] = tonumber(string.sub(tempstr, 1, temppos-1))
				tempstr = string.sub(tempstr, temppos+1, string.len(tempstr))
			end
			strDBItem = string.sub(strDBItem, iPos+1, string.len(strDBItem))
		end
	end
	
	if g_Token_Shop_IsHaveBuy ~= nil and g_Token_Shop_IsHaveBuy >= 0 then	
		g_Token_Shop_YBItemList[1][5] = math.floor(g_Token_Shop_IsHaveBuy/10000000)
		g_Token_Shop_YBItemList[2][5] = math.floor(math.mod(g_Token_Shop_IsHaveBuy/1000000, 10))
		g_Token_Shop_YBItemList[3][5] = math.floor(math.mod(g_Token_Shop_IsHaveBuy/100000, 10))
		g_Token_Shop_YBItemList[4][5] = math.floor(math.mod(g_Token_Shop_IsHaveBuy/10000, 10))
		
		g_Token_Shop_DBItemList[1][5] = math.floor(math.mod(g_Token_Shop_IsHaveBuy/1000, 10))
		g_Token_Shop_DBItemList[2][5] = math.floor(math.mod(g_Token_Shop_IsHaveBuy/100,10))
		g_Token_Shop_DBItemList[3][5] = math.floor(math.mod(g_Token_Shop_IsHaveBuy/10,10))
		g_Token_Shop_DBItemList[4][5] = math.floor(math.mod(g_Token_Shop_IsHaveBuy,10))
	end
	
end

--=========================================================
--刷新确认
--=========================================================
function Token_Shop_RefershConfirm_Clicked( )
	
	local bConfirm = Variable:GetVariable("TokenShopRefershConfirm")
	if tonumber(bConfirm) == 0 then
		Token_Shop_RefershConfirm_Button:SetCheck(1)
		Variable:SetVariable("TokenShopRefershConfirm","1",0)
	else
		Token_Shop_RefershConfirm_Button:SetCheck(0)
		Variable:SetVariable("TokenShopRefershConfirm","0",0)
	end

	g_Token_Shop_RefershConfirm = Token_Shop_RefershConfirm_Button : GetCheck()
	
end

--=========================================================
--刷新商店
--=========================================================
function Token_Shop_ReFresh_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnRefreshShopItem" )
		Set_XSCRIPT_ScriptID(892921)
		Set_XSCRIPT_Parameter(0,1) --暂时只有代币刷新 1、表示代币刷新 2、表示元宝刷新
		Set_XSCRIPT_Parameter(1,1)
		Set_XSCRIPT_Parameter(2,g_Token_Shop_RefershConfirm) 
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
end

--=========================================================
--刷新商店
--=========================================================
function Token_Shop_Yb_ReFresh_Clicked()	

	local curTime = OSAPI:GetTickCount()
	if ( curTime - g_Token_Shop_LastClickTime < g_Token_Shop_ButtonCDTime ) then
		return
	end
	g_Token_Shop_LastClickTime = curTime
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnRefreshShopItem" )
		Set_XSCRIPT_ScriptID(892921)
		Set_XSCRIPT_Parameter(0,2) --暂时只有代币刷新 1、表示代币刷新 2、表示元宝刷新
		Set_XSCRIPT_Parameter(1,1)
		Set_XSCRIPT_Parameter(2,g_Token_Shop_RefershConfirm) 
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()	
end

--=========================================================
--商店说明
--=========================================================
function Token_Shop_Help_Clicked( index )

	if index ~= 1 and index ~= 2 then
		return 
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ShowHelpText" )
		Set_XSCRIPT_ScriptID(892921)
		Set_XSCRIPT_Parameter(0,index) --1、表示元宝 2、表示代币
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

--=========================================================
--代币购买
--=========================================================
function Token_Shop_CuiyiBuy( index )

	if index < 1 or index > 4 then
		return 
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnCommonShopBuy" )
		Set_XSCRIPT_ScriptID(892921)
		Set_XSCRIPT_Parameter(0,1) --1、表示代币 2、表示元宝
		Set_XSCRIPT_Parameter(1,index) 
		Set_XSCRIPT_Parameter(2,g_Token_Shop_DBItemList[index][4])
		Set_XSCRIPT_Parameter(3,g_Token_Shop_DBItemList[index][1])
		Set_XSCRIPT_Parameter(4,1) 
		Set_XSCRIPT_Parameter(5,g_Token_Shop_BuyConfirm) 
		Set_XSCRIPT_ParamCount(6)
	Send_XSCRIPT()	

end

--=========================================================
--元宝刷新
--=========================================================
function Token_Shop_YuanbaoUpdate()
	Token_Shop_Remain1_Text:SetText(ScriptGlobal_Format("#{SJSD_180817_28}",tostring(Player:GetData("YUANBAO"))))
end

--=========================================================
--购买确认
--=========================================================
function Token_Shop_BuyConfirm_Clicked( )
	
	local bConfirm = Variable:GetVariable("TokenShopBuyConfirm")
	if tonumber(bConfirm) == 0 then
		Token_Shop_BuyConfirm_Button:SetCheck(1)
		Variable:SetVariable("TokenShopBuyConfirm","1",0)
	else
		Token_Shop_BuyConfirm_Button:SetCheck(0)
		Variable:SetVariable("TokenShopBuyConfirm","0",0)
	end

	g_Token_Shop_BuyConfirm = Token_Shop_BuyConfirm_Button : GetCheck()
	
end

--=========================================================
--元宝购买
--=========================================================
function Token_Shop_YuanbaoBuy( index )

	if index < 1 or index > 4 then
		return 
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnCommonShopBuy" )
		Set_XSCRIPT_ScriptID(892921)
		Set_XSCRIPT_Parameter(0,2) --1、表示代币 2、表示元宝
		Set_XSCRIPT_Parameter(1,index) 
		Set_XSCRIPT_Parameter(2,g_Token_Shop_YBItemList[index][4])
		Set_XSCRIPT_Parameter(3,g_Token_Shop_YBItemList[index][1])
		Set_XSCRIPT_Parameter(4,1) 
		Set_XSCRIPT_Parameter(5,g_Token_Shop_BuyConfirm) 
		Set_XSCRIPT_ParamCount(6)
	Send_XSCRIPT()	

end

--=========================================================
--关闭
--=========================================================
function Token_Shop_Close()
	this:Hide()
end

--=========================================================
--刷新位置
--=========================================================
function Token_Shop_On_ResetPos()
	Token_Shop:SetProperty("UnifiedPosition", g_Token_Shop_UnifiedPosition);
end

--=========================================================
--返利
--=========================================================
function Token_Shop_InitFanLi()
		
	g_Token_Shop_CurPage = 2
	Token_Shop_Button01:SetCheck(0)
	Token_Shop_Button02:SetCheck(1)

	Token_Shop_Page2:Show()
	Token_Shop_Page1:Hide()
	
	-- 返利红点
	Token_Shop_Button02Tips:Hide()
	if g_Token_Shop_ShowFanLiTips == 1 then
		Token_Shop_Button02Tips:Show()
	end
	
	for i = 1, table.getn(g_Token_Shop_nContentButton) do
		g_Token_Shop_nContentButton[i]:GetSubItem("Token_Shop_RewardItemClient_1_Item1"):SetActionItem(-1)
		g_Token_Shop_nContentButton[i]:GetSubItem("Token_Shop_RewardItemClient_2_Item1"):SetActionItem(-1)
		g_Token_Shop_nContentButton[i]:GetSubItem("Token_Shop_RewardItemClient_2_Item2"):SetActionItem(-1)
		g_Token_Shop_nContentButton[i]:GetSubItem("Token_Shop_RewardItemClient_3_Item1"):SetActionItem(-1)
		g_Token_Shop_nContentButton[i]:GetSubItem("Token_Shop_RewardItemClient_3_Item2"):SetActionItem(-1)
		g_Token_Shop_nContentButton[i]:GetSubItem("Token_Shop_RewardItemClient_3_Item3"):SetActionItem(-1)
	end	
	
	Token_Shop_Page2List:Clear()		
	g_Token_Shop_nContentButton = {}
	
	local nFanliTable = g_Token_Shop_FanliList
	if g_Token_Shop_IsKaJi == 1 then
		nFanliTable = g_Token_Shop_FanliList_KJ
	end

	for i = 1, table.getn(nFanliTable) do
		local bar = Token_Shop_Page2List:AddChild("Token_Shop_Page2List_Content")
		if nil ~= bar then
			local strmsg = ""
			-- 达成条件
			if g_Token_Shop_Cost >= nFanliTable[i].Exch then
				-- 已达成
				strmsg = ScriptGlobal_Format("#{QXSD_220613_36}", g_Token_Shop_Cost, nFanliTable[i].Exch)
			else
				-- 未达成
				strmsg = ScriptGlobal_Format("#{QXSD_220613_42}", g_Token_Shop_Cost, nFanliTable[i].Exch)
			end
			bar:GetSubItem("Token_Shop_Page2_RewardText1"):SetText( strmsg )
			
			-- 奖励显示
			for clientidx = 1, table.getn(g_Token_Shop_Page2_RewardClient) do
				bar:GetSubItem(g_Token_Shop_Page2_RewardClient[clientidx]):Hide()		
			end
			local itemlistcount = table.getn(nFanliTable[i].ItemList)
			if g_Token_Shop_Page2_RewardClientList[itemlistcount] ~= nil and g_Token_Shop_Page2_RewardClient[itemlistcount] ~= nil then
				local Clientbutton = g_Token_Shop_Page2_RewardClient[itemlistcount]
				bar:GetSubItem(Clientbutton):Show()
				for itemidx = 1, itemlistcount do
					local itemid = nFanliTable[i].ItemList[itemidx][1]
					local itemnum = nFanliTable[i].ItemList[itemidx][2]
					if itemid > 0 and itemnum > 0 then
						local theAction = DataPool:CreateBindActionItemForShow(itemid, itemnum)
						if theAction:GetID() ~= 0 then
							local itemaction = g_Token_Shop_Page2_RewardClientList[itemlistcount][itemidx]
							bar:GetSubItem(itemaction):SetActionItem(theAction:GetID());
						end
					end
				end
			end
						
			-- 按钮
			bar:GetSubItem("Token_Shop_Page2_RewardBK3_Button"):Hide()
			-- 已领取
			bar:GetSubItem("Token_Shop_Page2_RewardBK3_Mark"):Hide()
			-- 小红点
			bar:GetSubItem("Token_Shop_Page2_RewardBK3_ButtonTips"):Hide()
			if nFanliTable[i] ~= nil then
				if g_Token_Shop_IsGetFanLi[i] == 1 then	-- 已领取
					bar:GetSubItem("Token_Shop_Page2_RewardBK3_Mark"):Show()
				else
					bar:GetSubItem("Token_Shop_Page2_RewardBK3_Button"):Show()
					if g_Token_Shop_Cost >= nFanliTable[i].Exch then
						bar:GetSubItem("Token_Shop_Page2_RewardBK3_ButtonTips"):Show()
					end
				end				
			end
			bar:SetSubItemEvent("Token_Shop_Page2_RewardBK3_Button", "Clicked", "Token_Shop_GetReward_Click("..i..")")	
			
			g_Token_Shop_nContentButton[i] = bar
			
		end
	end
	
end

--===============================================
-- 领取返利
--===============================================
function Token_Shop_GetReward_Click( nFanLiIdx )
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGetTokenShopFanLi" )
		Set_XSCRIPT_ScriptID(892921)
		Set_XSCRIPT_Parameter(0, nFanLiIdx)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
	
end

