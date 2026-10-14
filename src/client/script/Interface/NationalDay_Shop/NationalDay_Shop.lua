--国庆系列

local g_NationalDay_Shop_Frame_UnifiedPosition

--显示何时刷新购买次数
local g_NationalDay_Shop_ReFreshTime1 = 20231004
local g_NationalDay_Shop_ReFreshTime2 = 20231001
local g_NationalDay_Shop_ReFreshTime3 = 20230928

--展示界面 2020年加的 2021年没有展示
local g_NationalDay_Shop_ShowItem1 = 39924008
local g_NationalDay_Shop_ShowItem2 = 39924441

--当前选中物品编号
local g_NationalDay_Shop_CurIndex = -1;
--当前物品购买数量
local g_NationalDay_Shop_BuyNum = 0;
--限购数量
local g_NationalDay_Shop_BuyNumLimit = 0;
--物品最大数量
local g_NationalDay_Shop_MaxCount = 18;
--当前页
local g_NationalDay_Shop_CurPage = 1;
--是否会员
local g_NationalDay_Shop_IsMember = 0;
--1、砍价期间 2、返利期间
local g_NationalDay_Shop_State = -1;  
--砍价令数量
local g_NationalDay_Shop_KanJiaLing = 0;
--折花令数量
local g_NationalDay_Shop_ZheHuaLing = 0;
--返利元宝数量
local g_NationalDay_Shop_YuanBao = 0;
--是否已领取元宝
local g_NationalDay_Shop_IsGetYuanBao = -1;
--使用砍价令数量
local g_NationalDay_Shop_UseKanJiaLing = 0;
--物品折扣
local g_NationalDay_Shop_ItemCut = {};
--已购买
local g_NationalDay_Shop_ItemBuyNum = {};
--物品控件列表
local g_NationalDay_Shop_ItemButton = {}
--砍价返利界面当前选中
local g_NationalDay_Shop_CurrentSelect = -1;
local g_NationalDay_Shop_Showtips = 0;
--按钮CD
local g_NationalDay_Shop_CDTime = 0.2
local g_NationalDay_Shop_LastTime = 0

local g_NationalDay_Shop_KanJiaButton ={}

local g_NationalDay_Shop_KanJiaButtonState = {
	[1] =0,
	[2] =0,
	[3] =0,
	[4] =0,
	[5] =0,
};

local g_NationalDay_Shop_GetGiftsCondition =
{
	[1] = { Exch = 20,  },
	[2] = { Exch = 50,  },
	[3] = { Exch = 90, },
	[4] = { Exch = 150, },
	[5] = { Exch = 240, },
}

local g_NationalDay_Shop_Gifts = {
	[1] = 	{
			{GiftItemID = 39920163, num = 10,},
			},
	[2] =	{
			{GiftItemID = 39920163, num = 15,},{GiftItemID = 39920162, num = 5,},
			},
	[3] =   {
			{GiftItemID = 39920163, num = 20,},{GiftItemID = 39920162, num = 10,},
			},
	[4] = 	{
			{GiftItemID = 39920163, num = 25,},{GiftItemID = 39920162, num = 15,},{ GiftItemID = 39921415, num = 5,},
			},
	[5] =	{
			{GiftItemID = 39920163, num = 30,},{GiftItemID = 39920162, num = 20,},{ GiftItemID = 39921689, num = 1,},{ GiftItemID = 39923853, num = 1,},
			},
}
local g_NationalDay_Shop_Gifts_KJ = {
	[1] = 	{
			{GiftItemID = 39920235, num = 1,},
			},
	[2] =	{
			{GiftItemID = 39920235, num = 2,},{GiftItemID = 39920267, num = 1,},
			},
	[3] =   {
			{GiftItemID = 39920235, num = 3,},{GiftItemID = 39920267, num = 2,},
			},
	[4] = 	{
			{GiftItemID = 39920235, num = 4,},{GiftItemID = 39920267, num = 3,},{ GiftItemID = 39920490, num = 3,},
			},
	[5] =	{
			{GiftItemID = 39920235, num = 5,},{GiftItemID = 39920267, num = 4,},{ GiftItemID = 39920311, num = 3,},{ GiftItemID = 39923853, num = 1,},
			},
}

local g_NationalDay_Shop_GiftsImage = {
	[1] = {Set ="NationalDay4" , Image = "ItemListNum1", },
	[2] = {Set ="NationalDay4" , Image = "ItemListNum2", },
	[3] = {Set ="NationalDay4" , Image = "ItemListNum3", },
	[4] = {Set ="NationalDay4" , Image = "ItemListNum4", },
	[5] = {Set ="NationalDay4" , Image = "ItemListNum5", },
}

local g_NationalDay_Shop_KanJiaButtonimage1 = {"DuanWu6", "BWBoatBtn_Dis2"} --已领取
local g_NationalDay_Shop_KanJiaButtonimage2 = {"DuanWu6", "BWBoatBtn_Dis1"} --未达成

function NationalDay_Shop_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false) 
	this:RegisterEvent("UPDATE_YUANBAO")
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	
end

function NationalDay_Shop_OnLoad()

	g_NationalDay_Shop_Frame_UnifiedPosition = NationalDay_Shop:GetProperty("UnifiedPosition") 
	
	for i = 1, g_NationalDay_Shop_MaxCount do
		g_NationalDay_Shop_ItemCut[i] = 10
	end
	
end

--=========
-- Event
--=========
function NationalDay_Shop_OnEvent(event) 
	if(event == "UI_COMMAND" and tonumber(arg0) == 89315801) then  --打开砍价商店界面 
				
		--0是非活动期间 1是砍价期间 2是返利期间
		g_NationalDay_Shop_State = Get_XParam_INT(0)
		if g_NationalDay_Shop_State < 1 then
			NationalDay_Shop_Close() 
			return
		end
		
		g_NationalDay_Shop_CurPage = Get_XParam_INT(1)	
		-- 芙蓉商店
		if g_NationalDay_Shop_CurPage == 1 then		
			-- 砍价令道具数量
			g_NationalDay_Shop_KanJiaLing = Get_XParam_INT(2)
			-- 是否基金会员
			g_NationalDay_Shop_IsMember = Get_XParam_INT(3)
			--当前选中
			g_NationalDay_Shop_CurIndex = Get_XParam_INT(4)		
			--返利页面是否显示小红点
			g_NationalDay_Shop_Showtips = Get_XParam_INT(5)		
			
			if g_NationalDay_Shop_State == 2 then
				-- 返利元宝数量
				g_NationalDay_Shop_YuanBao = Get_XParam_INT(6)
				-- 是否已领取返利元宝
				g_NationalDay_Shop_IsGetYuanBao = Get_XParam_INT(7)
			else
				-- 折花令数量
				g_NationalDay_Shop_ZheHuaLing = Get_XParam_INT(6)
			end
			
			if g_NationalDay_Shop_CurIndex == -1 then
				g_NationalDay_Shop_CurIndex = 1	
				if IsWindowShow("NationalDay_KanJia") then
					CloseWindow("NationalDay_KanJia", true)
				end
				if IsWindowShow("NationalDay_ShopShow") then
					CloseWindow("NationalDay_ShopShow", true)
				end
			end
		
			g_NationalDay_Shop_MaxCount = Lua_GetNationalShopItemCount() 
			if g_NationalDay_Shop_MaxCount < 1 then
				NationalDay_Shop_Close() 
				return
			end			
			
			-- 物品折扣
			NationalDay_Shop_splitItemCut(Get_XParam_STR(0))
			NationalDay_Shop_splitItemBuyNum(Get_XParam_STR(1))
			
			NationalDay_Shop_Buttontab01:SetCheck(1)
			NationalDay_Shop_Buttontab02:SetCheck(0)
				
			NationalDay_Shop_Client1:Show()
			NationalDay_Shop_Client2:Hide()
		
		-- 砍价返利
		elseif g_NationalDay_Shop_CurPage == 2 then	
			if IsWindowShow("NationalDay_KanJia") then
				CloseWindow("NationalDay_KanJia", true)
			end
			if IsWindowShow("NationalDay_ShopShow") then
				CloseWindow("NationalDay_ShopShow", true)
			end
				
			g_NationalDay_Shop_UseKanJiaLing = Get_XParam_INT(2)	
			
			--返利页面是否显示小红点
			g_NationalDay_Shop_Showtips = Get_XParam_INT(3)	
			
			for i = 1, table.getn(g_NationalDay_Shop_KanJiaButtonState) do
				g_NationalDay_Shop_KanJiaButtonState[i] = Get_XParam_INT(i+3)
			end
			
			NationalDay_Shop_Buttontab01:SetCheck(0)
			NationalDay_Shop_Buttontab02:SetCheck(1)
			
			NationalDay_Shop_Client1:Hide()
			NationalDay_Shop_Client2:Show()
		else
			NationalDay_Shop_Close() 
			return
		end
		this:Show()
		
		NationalDay_Shop_Open()
		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		NationalDay_Shop_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		NationalDay_Shop_Close()

	elseif event == "ADJEST_UI_POS" then

		NationalDay_Shop_On_ResetPos()		
		
	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
	
		NationalDay_Shop_YuanbaoUpdate()
		
	elseif(event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
	
		if arg0 ~= nil then
			NationalDay_Shop_KanJiaLingUpdate()		
		end
		
	end

end
 
--=========
-- 重置
--=========
function NationalDay_Shop_On_ResetPos()

	NationalDay_Shop:SetProperty("UnifiedPosition", g_NationalDay_Shop_Frame_UnifiedPosition)

end

--===============================================
-- 页签
--===============================================
function NationalDay_Shop_Project_Clicked( clickId )
	if g_NationalDay_Shop_CurPage == clickId then
		return
	end
	
	if clickId ~= 1 and clickId ~= 2 then
		return
	end
	
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_NationalDay_Shop_LastTime < g_NationalDay_Shop_CDTime * 1000) then 
		return
	end
	g_NationalDay_Shop_LastTime = curTime;

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnOpenNatiaonalShop")
		Set_XSCRIPT_ScriptID(893158) 
		Set_XSCRIPT_Parameter( 0, clickId )
		Set_XSCRIPT_Parameter( 1, g_NationalDay_Shop_CurIndex )
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()

end

--===============================================
-- 购买
--===============================================
function NationalDay_Shop_Buy_Click()
	if g_NationalDay_Shop_CurIndex == -1 then
		PushDebugMessage("#{GQKJ_190722_04}")
		return
	end
	
	--if g_NationalDay_Shop_BuyNum <= 0 then
	--	PushDebugMessage("#{GQKJ_190722_185}")
	--	return
	--end
	
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_NationalDay_Shop_LastTime < g_NationalDay_Shop_CDTime * 1000) then 
		return
	end
	g_NationalDay_Shop_LastTime = curTime;

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NatiaonalShopBuy")
		Set_XSCRIPT_ScriptID(893158) 
		Set_XSCRIPT_Parameter(0, g_NationalDay_Shop_CurIndex) 
		Set_XSCRIPT_Parameter(1, g_NationalDay_Shop_BuyNum) 
		Set_XSCRIPT_Parameter(2, 1) 
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

end

--===============================================
-- 领取元宝返利
--===============================================
function NationalDay_Shop_Get_Click()
	
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_NationalDay_Shop_LastTime < g_NationalDay_Shop_CDTime * 1000) then 
		return
	end
	g_NationalDay_Shop_LastTime = curTime;

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NatiaonalShopGetYB")
		Set_XSCRIPT_ScriptID(893158) 
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

end

--===============================================
-- 打开帮助
--===============================================
function NationalDay_Shop_Help_Clicked( clickId )
	
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_NationalDay_Shop_LastTime < g_NationalDay_Shop_CDTime * 1000) then 
		return
	end
	g_NationalDay_Shop_LastTime = curTime;

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NatiaonalShopHelp")
		Set_XSCRIPT_ScriptID(893158) 
		Set_XSCRIPT_Parameter( 0, clickId ) --编号
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()

end

--===============================================
-- 查看详情
--===============================================
function NationalDay_Shop_Details_Click()
	
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_NationalDay_Shop_LastTime < g_NationalDay_Shop_CDTime * 1000) then 
		return
	end
	g_NationalDay_Shop_LastTime = curTime;

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NatiaonalShopHelp")
		Set_XSCRIPT_ScriptID(893158) 
		Set_XSCRIPT_Parameter( 0, 3 ) --编号
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
	
end

--===============================================
-- 点击会员或购买会员
--===============================================
function NationalDay_Shop_Member_Clicked()
	
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_NationalDay_Shop_LastTime < g_NationalDay_Shop_CDTime * 1000) then 
		return
	end
	g_NationalDay_Shop_LastTime = curTime;

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NatiaonalMember")
		Set_XSCRIPT_ScriptID(893158) 
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()

end

--=========================================================
--元宝刷新
--=========================================================
function NationalDay_Shop_YuanbaoUpdate()
	NationalDay_Shop_YuanBaoNum:SetText(ScriptGlobal_Format("#{GQKJ_190722_58}",tostring(Player:GetData("YUANBAO"))))
end

--=========================================================
-- 砍价令
--=========================================================
function NationalDay_Shop_KanJiaLingUpdate()	
	local itemcount = PlayerPackage:CountAvailableItemByIDTable(38002871)
	local str = ScriptGlobal_Format("#{GQKJ_190722_208}", itemcount)
	NationalDay_Shop_ZheKouLingNum:SetText(str)
end	

--===============================================
-- 设置Button 小红点
--===============================================
function NationalDay_Shop_ShowButtonTips()

	-- 有返利元宝
	NationalDay_Shop_Buttontab01_Tips:Hide()
	if g_NationalDay_Shop_State == 2 then
		if g_NationalDay_Shop_YuanBao > 0 and g_NationalDay_Shop_IsGetYuanBao == 0 then
			NationalDay_Shop_Buttontab01_Tips:Show()
		end
	end
	
	-- 有返利奖励
	NationalDay_Shop_Buttontab02_Tips:Hide()
	for i = 1, table.getn(g_NationalDay_Shop_KanJiaButtonState) do
		if g_NationalDay_Shop_KanJiaButtonState[i] == 1 then
			NationalDay_Shop_Buttontab02_Tips:Show()
		end
	end
	
	if g_NationalDay_Shop_Showtips == 1 then
		NationalDay_Shop_Buttontab02_Tips:Show()
	end

end

--===============================================
-- 拆字符串
--===============================================
function NationalDay_Shop_splitItemCut(strcut)
	
	for i = 1, g_NationalDay_Shop_MaxCount do
		local temppos = string.find( strcut, "*" );
		local tempstr = string.sub( strcut, 1, temppos-1 )
		g_NationalDay_Shop_ItemCut[i] = tonumber(tempstr)
		strcut = string.sub(strcut, temppos+1, string.len(strcut))
	end
	
end

function NationalDay_Shop_splitItemBuyNum(strbuy)
	
	for i = 1, g_NationalDay_Shop_MaxCount do
		local temppos = string.find( strbuy, "*" );
		local tempstr = string.sub( strbuy, 1, temppos-1 )
		g_NationalDay_Shop_ItemBuyNum[i] = tonumber(tempstr)
		strbuy = string.sub(strbuy, temppos+1, string.len(strbuy))
	end
	
end

function NationalDay_Shop_OnHiden()
	NationalDay_Shop_Close() 
end

--=========
-- 关闭
--=========
function NationalDay_Shop_Close() 

	g_NationalDay_Shop_CurIndex = -1
	
	NationalDay_Shop_CleanItemAction()	
	NationalDay_Shop_ClientList:CleanAllElement("NationalDay_Shop")	
	
	NationalDay_Shop_CleanKanJiaAction()
	NationalDay_Shop_Client2List:CleanAllElement("NationalDay_Shop") 

	this:Hide()
	
	if IsWindowShow("NationalDay_KanJia") then
		CloseWindow("NationalDay_KanJia", true)
	end
	
	if IsWindowShow("NationalDay_ShopShow") then
		CloseWindow("NationalDay_ShopShow", true)
	end
	
end

--=========
-- 打开
--=========
function NationalDay_Shop_Open() 
	
	NationalDay_Shop_CleanItemAction()	
	NationalDay_Shop_CleanKanJiaAction()
	NationalDay_Shop_ClientList:CleanAllElement("NationalDay_Shop")
	NationalDay_Shop_Client2List:CleanAllElement("NationalDay_Shop") 

	if g_NationalDay_Shop_CurPage == 1 then	
		--是否会员
		if g_NationalDay_Shop_IsMember == 1 then
			NationalDay_Shop_MemberBtn:Show()
			NationalDay_Shop_MemberBuyBtn:Hide()
		else
			NationalDay_Shop_MemberBuyBtn:Show()
			NationalDay_Shop_MemberBtn:Hide()
		end
		
		for i = 1, g_NationalDay_Shop_MaxCount do
			NationalDay_Shop_AddItemList( i )
		end		
		NationalDay_Shop_SetItemListSelected(g_NationalDay_Shop_CurIndex)
		NationalDay_Shop_ClientList:Flash()
		NationalDay_Shop_ClientList:SetElementsInView(g_NationalDay_Shop_CurIndex)	

		NationalDay_Shop_UpdateRightInfo()
		
		if g_NationalDay_Shop_State == 1 then
			NationalDay_Shop_YuanBaoNum:Show()
			NationalDay_Shop_XiangNangNum:Show()
			NationalDay_Shop_ZheKouLingNum:Show()
			
			NationalDay_Shop_YuanbaoUpdate()
			NationalDay_Shop_XiangNangNum:SetText(ScriptGlobal_Format("#{GQKJ_190722_59}", g_NationalDay_Shop_ZheHuaLing))
			NationalDay_Shop_KanJiaLingUpdate()	
		else
			NationalDay_Shop_YuanBaoNum:Hide()
			NationalDay_Shop_XiangNangNum:Hide()
			NationalDay_Shop_ZheKouLingNum:Hide()
			
			NationalDay_ShopGetBtn:Enable()
			if g_NationalDay_Shop_IsGetYuanBao == 1 then
				NationalDay_ShopGetBtn:Disable()
			end
		end
	else				
		NationalDay_Shop_FlushKanJiaFanLi()
	end	

	NationalDay_Shop_ShowButtonTips()
	
end

--=========
-- 清空Action数据
--=========
function NationalDay_Shop_CleanItemAction()
		--清空商店数据
		local nListCount = table.getn(g_NationalDay_Shop_ItemButton)
		if nListCount <= 0 then
			g_NationalDay_Shop_ItemButton = {}
			return
		end
		for i = 1, g_NationalDay_Shop_MaxCount do
			if nil ~= g_NationalDay_Shop_ItemButton[i] then
				local itemButton = g_NationalDay_Shop_ItemButton[i]:GetChildItem("NationalDay_Shop", "__auto_FightScoreBarIcon1__")
				if nil ~= itemButton then
					itemButton:SetActionItem(-1)
				end
			end
		end 
		g_NationalDay_Shop_ItemButton = {}
end

--=========================================================
--填充左侧物品
--=========================================================
function NationalDay_Shop_AddItemList(index)

	local nItemId, nItemNum, nPrimeCost, nLimitType, nLimitNum, nZheHuaCut, nlowCut = Lua_GetNationalShopItemInfo(index);
	if nItemId < 0 then
		return
	end
	
	local ItemBar = nil 
	ItemBar = NationalDay_Shop_ClientList:AddItemElement( "NationalDayShopItem", "NationalDay_Shop","" ,"")
	if ItemBar ~= nil then
		ItemBar:SetProperty("SuperBarButtonHover", "SuperBarHoverSection")
	else
		return
	end	
	
	--物品图标
	local itemaction = ItemBar:GetChildItem("NationalDay_Shop", "__auto_FightScoreBarIcon1__")
	local theAction	= DataPool:CreateActionItemForShow(nItemId, nItemNum)
	if theAction:GetID() ~= 0 then 
		itemaction:SetActionItem(theAction:GetID())
	else
		itemaction:SetActionItem(-1)
	end
	
	--物品名字
	local itemName = ItemBar:GetChildItem("NationalDay_Shop", "__auto_SuperBarText1__")
	local nItemname = DataPool:Lua_GetItemNameByIndex(nItemId)	
	itemName:SetText("#L"..tostring(nItemname))
		
	--XX折
	local itemCut = ItemBar:GetChildItem("NationalDay_Shop", "__auto_SuperBarText2__")
	local cutNum = g_NationalDay_Shop_ItemCut[index]
	local str = ScriptGlobal_Format("#{GQKJ_190722_45}", cutNum/10)
	itemCut:SetText(str)
	
	--折扣底图
	local CutImage = ItemBar:GetChildItem("NationalDay_Shop", "__auto_SuperBarImage1__")
	if g_NationalDay_Shop_ItemCut[index] == nlowCut then
		CutImage:Show()
		CutImage:SetProperty("Image","set:NationalDay4 image:zhekouBK2")
	else
		CutImage:Hide()
		CutImage:SetProperty("Image","set:NationalDay4 image:zhekouBK")
	end
	
	--原价
	local initCost = ItemBar:GetChildItem("NationalDay_Shop", "__auto_SuperBarText3__")
	str = ScriptGlobal_Format("#{GQKJ_190722_41}", nPrimeCost)
	initCost:SetText(str)	
	
	--原价划线
	local initLine = ItemBar:GetChildItem("NationalDay_Shop", "__auto_SuperBarText6__")
	if cutNum ~= 100 then
		initLine:Hide()
		initLine:SetText("#{GQKJ_190722_211}")
	else
		initLine:Hide()
	end
	
	--折扣价
	local cutCost = ItemBar:GetChildItem("NationalDay_Shop", "__auto_SuperBarText4__")
	local strcut = math.floor(nPrimeCost * cutNum / 100)
	str = ScriptGlobal_Format("#{GQKJ_190722_42}", strcut)
	cutCost:SetText(str)
	
	--限购数量 去掉
	local limitCount = ItemBar:GetChildItem("NationalDay_Shop", "__auto_SuperBarText5__")	
	limitCount:Hide()	
	if g_NationalDay_Shop_ItemCut[index] == nlowCut then
		limitCount:Show()
		limitCount:SetText("#{GQKJ_190722_218}")
	end
	
	--售罄图片
	local ShouQing = ItemBar:GetChildItem("NationalDay_Shop", "__auto_SuperBarImage2__")	
	ShouQing:Hide()	
		
	local HaveBuy = g_NationalDay_Shop_ItemBuyNum[index]
	if nLimitType == 3 then
		--分阶段
		if HaveBuy >= nLimitNum then
			ShouQing:Show()	
		end
	elseif nLimitType == 2 then
		--活动期间
		if HaveBuy >= nLimitNum then
			ShouQing:Show()	
		end
	end
	
	--砍价按钮
	local kanjianbutton = ItemBar:GetChildItem("NationalDay_Shop", "__auto_SuperBarButton1__")	
	kanjianbutton:SetToolTip("#{GQKJ_190722_47}")
		
	table.insert(g_NationalDay_Shop_ItemButton, ItemBar)
end

--===============================================
-- 砍价
--===============================================
function NationalDay_Shop_KanJia_Click()

	NationalDay_Shop_OnItemListClick()

	if g_NationalDay_Shop_CurIndex == -1 then
		return
	end
	
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_NationalDay_Shop_LastTime < g_NationalDay_Shop_CDTime * 1000) then 
		return
	end
	g_NationalDay_Shop_LastTime = curTime;

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NatiaonalShopCut")
		Set_XSCRIPT_ScriptID(893158) 
		Set_XSCRIPT_Parameter(0, 0) 
		Set_XSCRIPT_Parameter(1, g_NationalDay_Shop_CurIndex) 
		Set_XSCRIPT_Parameter(2, 0) 
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

end

--=========================================================
--左侧物品选中
--=========================================================
function NationalDay_Shop_OnItemListClick()
	
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1

	if nIndex > 0 then
		
		if g_NationalDay_Shop_CurIndex ~= nIndex then
		
			NationalDay_Shop_SetItemListSelected(nIndex)
			NationalDay_Shop_ClientList:Flash()
			g_NationalDay_Shop_CurIndex = nIndex
			
			NationalDay_Shop_UpdateRightInfo()
	
		end
	end

end

--=========================================================
--设置选中
--=========================================================
function NationalDay_Shop_SetItemListSelected(nIndex)
	for nButtonIndex = 1,table.getn(g_NationalDay_Shop_ItemButton) do
		if nil ~= g_NationalDay_Shop_ItemButton[nButtonIndex] then
			if nButtonIndex ~= nIndex then
				g_NationalDay_Shop_ItemButton[nButtonIndex]:SetBarButtonSelected(false)
			else
				g_NationalDay_Shop_ItemButton[nButtonIndex]:SetBarButtonSelected(true)
			end
		end
	end
end

--=========================================================
--刷新右侧信息
--=========================================================
function NationalDay_Shop_UpdateRightInfo()
	
	if g_NationalDay_Shop_State == 1 then
		if IsWindowShow("NationalDay_ShopShow") then
			CloseWindow("NationalDay_ShopShow", true)
		end
				
		--砍价期间
		NationalDay_Shop_BuyClient:Show()
		NationalDay_Shop_YuanBaoClient:Hide()	
				
		local nItemId, nItemNum, nPrimeCost, nLimitType, nLimitNum, nZheHuaCut, nlowCut = Lua_GetNationalShopItemInfo(g_NationalDay_Shop_CurIndex);
		if nItemId > 0 then			
			local theAction = DataPool:CreateActionItemForShow(nItemId, nItemNum)
			if theAction:GetID() ~= 0 then
				NationalDay_Shop_BuyItem:SetActionItem( theAction:GetID() );
			else
				NationalDay_Shop_BuyItem:SetActionItem( -1 );
			end
			
			if nItemId == g_NationalDay_Shop_ShowItem1 or nItemId == g_NationalDay_Shop_ShowItem2 then
				NationalDay_Shop_BuyItem_Show:Show()
			else
				NationalDay_Shop_BuyItem_Show:Hide()
			end
			
			local nItemname = DataPool:Lua_GetItemNameByIndex(nItemId)	
			NationalDay_Shop_BuyItem_Name:SetText("#L"..tostring(nItemname))
			
			local cutNum = g_NationalDay_Shop_ItemCut[g_NationalDay_Shop_CurIndex]
			local str = ScriptGlobal_Format("#{GQKJ_190722_45}", cutNum/10)
			NationalDay_Shop_BuyItem_SaleNum:SetText(str)
			
			if g_NationalDay_Shop_ItemCut[g_NationalDay_Shop_CurIndex] == nlowCut then
				NationalDay_Shop_BuyItem_Mark2:Show()
				--NationalDay_Shop_BuyItem_Mark:SetProperty("Image","set:NationalDay4 image:zhekouBK2")
			else
				NationalDay_Shop_BuyItem_Mark2:Hide()
				--NationalDay_Shop_BuyItem_Mark:SetProperty("Image","set:NationalDay4 image:zhekouBK")
			end
			
			--消耗元宝
			local strcut = math.floor(nPrimeCost * cutNum / 100)
			
			--最低折扣时所需元宝数量
			local NeedYBLow = math.floor(nPrimeCost * nlowCut / 100)
			
			--折华令可抵扣
			local zhehualing = math.floor(nZheHuaCut * nPrimeCost / 100)
			if g_NationalDay_Shop_ZheHuaLing >= zhehualing then
				if strcut-zhehualing < NeedYBLow then
					zhehualing = strcut - NeedYBLow
				end
				str = ScriptGlobal_Format("#{GQKJ_190722_181}", zhehualing)
			else
				zhehualing = g_NationalDay_Shop_ZheHuaLing
				if strcut-zhehualing < NeedYBLow then
					zhehualing = strcut - NeedYBLow
				end
				str = ScriptGlobal_Format("#{GQKJ_190722_181}", zhehualing)
			end
			NationalDay_Shop_BuyItem_Text2:SetText(str)
			
			--消耗元宝
			str = ScriptGlobal_Format("#{GQKJ_190722_180}", strcut-zhehualing)
			NationalDay_Shop_BuyItem_Text1:SetText(str)
			
			--需付
			if zhehualing == 0 then
				str = ScriptGlobal_Format("#{GQKJ_190722_183}", strcut)
			else
				str = ScriptGlobal_Format("#{GQKJ_190722_182}", strcut-zhehualing, zhehualing)
			end
			--NationalDay_Shop_BuyItem_Text3:SetText(str)
			
			local nHaveBuy = g_NationalDay_Shop_ItemBuyNum[g_NationalDay_Shop_CurIndex]
			NationalDay_Shop_BuyItem_XianLiangText:Show()
			NationalDay_Shop_BuyItem_TimeText:Hide()
			NationalDay_Shop_BuyItem_Btn:Enable()
			NationalDay_Shop_BuyItemMark:Hide()
			if nLimitType == 3 then
				if nHaveBuy >= nLimitNum then
					NationalDay_Shop_BuyItemMark:Show()
					--NationalDay_Shop_BuyItem_Btn:Disable()
					str = ScriptGlobal_Format("#{GQKJ_190722_55}", nHaveBuy, nLimitNum)
				else
					str = ScriptGlobal_Format("#{GQKJ_190722_54}", nHaveBuy, nLimitNum)
				end
				NationalDay_Shop_BuyItem_XianLiangText:SetText(str)	
				g_NationalDay_Shop_BuyNumLimit = nLimitNum - nHaveBuy
				
				-- 显示何时刷新购买次数
				if DataPool:GetServerDayTime() < g_NationalDay_Shop_ReFreshTime3 then
					NationalDay_Shop_BuyItem_TimeText:SetText("#{GQKJXZ_220815_14}")
					NationalDay_Shop_BuyItem_TimeText:Show()
				elseif DataPool:GetServerDayTime() < g_NationalDay_Shop_ReFreshTime2 then
					NationalDay_Shop_BuyItem_TimeText:SetText("#{GQKJXZ_220815_15}")
					NationalDay_Shop_BuyItem_TimeText:Show()
				elseif DataPool:GetServerDayTime() < g_NationalDay_Shop_ReFreshTime1 then
					NationalDay_Shop_BuyItem_TimeText:SetText("#{GQKJXZ_220815_16}")
					NationalDay_Shop_BuyItem_TimeText:Show()
				else
					NationalDay_Shop_BuyItem_TimeText:SetText("#{GQKJ_190722_207}")
					NationalDay_Shop_BuyItem_TimeText:Show()
				end
			elseif nLimitType == 2 then
				if nHaveBuy >= nLimitNum then
					NationalDay_Shop_BuyItemMark:Show()
					NationalDay_Shop_BuyItem_Btn:Disable()
					str = ScriptGlobal_Format("#{GQKJ_190722_57}", nHaveBuy, nLimitNum)
				else
					str = ScriptGlobal_Format("#{GQKJ_190722_56}", nHaveBuy, nLimitNum)
				end
				NationalDay_Shop_BuyItem_XianLiangText:SetText(str)	
				g_NationalDay_Shop_BuyNumLimit = nLimitNum - nHaveBuy
						
				-- 显示何时购买结束	
				NationalDay_Shop_BuyItem_TimeText:SetText("#{GQKJ_190722_207}")
				NationalDay_Shop_BuyItem_TimeText:Show()
			else
				NationalDay_Shop_BuyItem_XianLiangText:Hide()
			end			
			
			if g_NationalDay_Shop_BuyNumLimit == 0 then
				g_NationalDay_Shop_BuyNum = 0
				NationalDay_Shop_BuyItemText:SetText("0")
				NationalDay_Shop_BuyItemText:Disable()
				NationalDay_Shop_BuyItemText:SetProperty("DefaultEditBox", "False");
			else
				g_NationalDay_Shop_BuyNum = 1
				NationalDay_Shop_BuyItemText:SetText("1")
				NationalDay_Shop_BuyItemText:Enable()
				NationalDay_Shop_BuyItemText:SetProperty("DefaultEditBox", "True");
			end
		end
	else
		--返利期间
		NationalDay_Shop_BuyClient:Hide()
		NationalDay_Shop_YuanBaoClient:Show()
		
		if g_NationalDay_Shop_YuanBao == 0 then
			NationalDay_Shop_YuanBaoClient2:Show()
			NationalDay_Shop_YuanBaoClient1:Hide()
		else
			NationalDay_Shop_YuanBaoClient1:Show()
			NationalDay_Shop_YuanBaoClient2:Hide()
			
			local str = ScriptGlobal_Format("#{GQKJ_190722_145}", g_NationalDay_Shop_YuanBao)
			NationalDay_Shop_YuanBaoHint1:SetText(str)
		end
	end
end

--===============================================
-- 砍价令领奖
--===============================================
function NationalDay_Shop_SetButtonSelected(nIndex)
	for nButtonIndex = 1,table.getn(g_NationalDay_Shop_KanJiaButton) do
		if nil ~= g_NationalDay_Shop_KanJiaButton[nButtonIndex] then
			if nButtonIndex ~= nIndex then
				g_NationalDay_Shop_KanJiaButton[nButtonIndex]:SetBarButtonSelected(false)
			else
				g_NationalDay_Shop_KanJiaButton[nButtonIndex]:SetBarButtonSelected(true)
			end
		end
	end
end

function NationalDay_Shop_OnItemClick()

	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1))

	if nIndex >= 0 then
		NationalDay_Shop_SetButtonSelected(nIndex + 1)
		NationalDay_Shop_Client2List:Flash()
		g_NationalDay_Shop_CurIndex = nIndex 
	end
	
end

--=========
-- 清空Action数据
--=========
function NationalDay_Shop_CleanKanJiaAction()
	local nListCount = table.getn(g_NationalDay_Shop_KanJiaButton)
	if nListCount <= 0 then
		g_NationalDay_Shop_KanJiaButton = {}
		return
	end
	for i = 1, nListCount do
		if nil ~= g_NationalDay_Shop_KanJiaButton[i] then
			for j = 1, table.getn(g_NationalDay_Shop_Gifts[i]) do
				local itemButton = g_NationalDay_Shop_KanJiaButton[i]:GetLuaActionButton(j, "NationalDay_Shop")
				if nil ~= itemButton then
					itemButton:SetActionItem(-1)
				end
			end
		end
	end 
	g_NationalDay_Shop_KanJiaButton = {}
end

function NationalDay_Shop_FlushKanJiaFanLi()
	local nCurIndex = 0
	
	NationalDay_Shop_Client2List:SetVertScrollbarHide()
	
	local NationalDay_Shop_Gifts = g_NationalDay_Shop_Gifts
	if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(109) > 0 then  --卡级
		NationalDay_Shop_Gifts = g_NationalDay_Shop_Gifts_KJ
	end
	
	for i = 1,  table.getn(NationalDay_Shop_Gifts) do
		local ItemBar = NationalDay_Shop_Client2List:AddItemElement( "NationalDayShopKanJia", "LEFT", "NationalDay_Shop","" ,"")
		if ItemBar == nil then
			return
		end
		ItemBar:SetProperty("AchievementBarWindowButtonHover","AchievementHoverSection") 
		ItemBar:Setm_newImage(1, g_NationalDay_Shop_GiftsImage[i].Set, g_NationalDay_Shop_GiftsImage[i].Image)
		
		for j = 1,  table.getn(NationalDay_Shop_Gifts[i]) do
			local itemButton	= ItemBar:GetLuaActionButton(j, "NationalDay_Shop")
			local GiftItemID	= NationalDay_Shop_Gifts[i][j].GiftItemID
			local GiftItemNum	= NationalDay_Shop_Gifts[i][j].num
			local theAction		= DataPool:CreateActionItemForShow(GiftItemID, GiftItemNum)
			if theAction:GetID() ~= 0 then 
				itemButton:SetActionItem(theAction:GetID())
			end
		end
		
		if i == 1 then
			ItemBar:Setm_newImageHide(3)
			ItemBar:Setm_newImageHide(4)
			ItemBar:Setm_newImageHide(5)
		elseif i == 2 or i == 3 then
			ItemBar:Setm_newImageHide(4)
			ItemBar:Setm_newImageHide(5)
		elseif i == 4 then
			ItemBar:Setm_newImageHide(5)
		end
		
		--未达成
		if g_NationalDay_Shop_KanJiaButtonState[i] == 0 then 
			if g_NationalDay_Shop_UseKanJiaLing < g_NationalDay_Shop_GetGiftsCondition[i].Exch then
				local Text = ScriptGlobal_Format("#{GQKJ_190722_124}", g_NationalDay_Shop_UseKanJiaLing, g_NationalDay_Shop_GetGiftsCondition[i].Exch)
				ItemBar:Setm_newText(1, Text)
			else
				local Text = ScriptGlobal_Format("#{GQKJ_190722_123}", g_NationalDay_Shop_UseKanJiaLing, g_NationalDay_Shop_GetGiftsCondition[i].Exch)
				ItemBar:Setm_newText(1, Text)
			end
			ItemBar:Setm_newImage(7, g_NationalDay_Shop_KanJiaButtonimage2[1], g_NationalDay_Shop_KanJiaButtonimage2[2])
			ItemBar:SetButton1Hide()
			ItemBar:Setm_newImageShow(7)
		--可以领取
		elseif g_NationalDay_Shop_KanJiaButtonState[i] == 1 then 
			local Text = ScriptGlobal_Format("#{GQKJ_190722_123}", g_NationalDay_Shop_GetGiftsCondition[i].Exch,g_NationalDay_Shop_GetGiftsCondition[i].Exch)
			ItemBar:Setm_newText(1, Text)
			ItemBar:Setm_newImageHide(7)
			--已经领取
			if nCurIndex == 0 then
				nCurIndex = i
			end
		--已领取
		elseif g_NationalDay_Shop_KanJiaButtonState[i] == 2 then  
			local Text = ScriptGlobal_Format("#{GQKJ_190722_123}", g_NationalDay_Shop_GetGiftsCondition[i].Exch,g_NationalDay_Shop_GetGiftsCondition[i].Exch)
			ItemBar:Setm_newText(1, Text)
			ItemBar:SetButton1Hide()
			ItemBar:Setm_newImage(7, g_NationalDay_Shop_KanJiaButtonimage1[1], g_NationalDay_Shop_KanJiaButtonimage1[2])
			ItemBar:Setm_newImageShow(7)
		end
		table.insert(g_NationalDay_Shop_KanJiaButton, ItemBar) 
	end
	 
	if nCurIndex ~= 0 then
		g_NationalDay_Shop_CurrentSelect = nCurIndex  
		NationalDay_Shop_SetButtonSelected(nCurIndex)
	end
	
	NationalDay_Shop_Client2List:Flash()
end

function NationalDay_Shop_OnButton1Click()
	
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_NationalDay_Shop_LastTime < g_NationalDay_Shop_CDTime * 1000) then 
		return
	end
	g_NationalDay_Shop_LastTime = curTime;
	
	local sPos, ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1
	if nil ~= g_NationalDay_Shop_KanJiaButton[nIndex] then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("NatiaonalShopCutFanLi")
			Set_XSCRIPT_ScriptID(893158)
			Set_XSCRIPT_Parameter(0,nIndex)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		g_NationalDay_Shop_KanJiaButton[nIndex]:SetBarButtonSelected(false)
		NationalDay_Shop_Client2List:Flash()
	end	
end

--===============================================
-- +
--===============================================
function NationalDay_Shop_BuyItem_Add_Clicked()

	local szNum = NationalDay_Shop_BuyItemText:GetText();
	if szNum == "" then 
		szNum = "1"
	end

	local nNum = szNum + 1;
		
	if( nNum > g_NationalDay_Shop_BuyNumLimit )then
		nNum = g_NationalDay_Shop_BuyNumLimit
		if g_NationalDay_Shop_BuyNumLimit == 0 then
			PushDebugMessage("#{GQKJ_190722_101}")
		else
			PushDebugMessage("#{GQKJ_190722_99}")
		end
	end
		
	NationalDay_Shop_BuyItemText:SetText(tostring(nNum));
	
	g_NationalDay_Shop_BuyNum = tonumber(nNum)
	
	NationalDay_Shop_UpdateYBNeed()

end

--===============================================
-- -
--===============================================
function NationalDay_Shop_BuyItem_Desc_Clicked()

	local szNum = NationalDay_Shop_BuyItemText:GetText();
	if szNum == "" then 
		szNum = "1"
	end
	
	local nNum = szNum - 1;

	if( nNum < 1 )then
		if g_NationalDay_Shop_BuyNumLimit == 0 then
			nNum = 0
			PushDebugMessage("#{GQKJ_190722_101}")
		else
			nNum = 1
			PushDebugMessage("#{GQKJ_190722_100}")
		end
	end
	
	NationalDay_Shop_BuyItemText:SetText(tostring(nNum));
	
	g_NationalDay_Shop_BuyNum = tonumber(nNum)
	
	NationalDay_Shop_UpdateYBNeed()

end

--===============================================
-- 编辑
--===============================================
function NationalDay_Shop_BuyItem_Changed()

	local szNum = NationalDay_Shop_BuyItemText:GetText()
	local num = 1
	
	if szNum == nil then
		return
	elseif szNum == "" then
		num = 1
		NationalDay_Shop_BuyItemText:SetText(tostring(num))
	elseif szNum == "0" then
		if g_NationalDay_Shop_BuyNumLimit == 0 then
			num = 0
		else
			num = 1
			NationalDay_Shop_BuyItemText:SetText(tostring(num))
		end
	else
		num = tonumber(szNum)
	end
	
	g_NationalDay_Shop_BuyNum = num
		
	if (num > g_NationalDay_Shop_BuyNumLimit and g_NationalDay_Shop_BuyNumLimit > 0) then
		g_NationalDay_Shop_BuyNum = g_NationalDay_Shop_BuyNumLimit
		NationalDay_Shop_BuyItemText:SetText(tostring(g_NationalDay_Shop_BuyNum))
	end	
	
	NationalDay_Shop_UpdateYBNeed()
		
end

--===============================================
-- 更新元宝数量
--===============================================
function NationalDay_Shop_UpdateYBNeed()

	if g_NationalDay_Shop_BuyNum <= 0 then
		return
	end
	
	local nItemId, nItemNum, nPrimeCost, nLimitType, nLimitNum, nZheHuaCut, nlowCut = Lua_GetNationalShopItemInfo(g_NationalDay_Shop_CurIndex);
	if nItemId > 0 then	
		--当前折扣
		local cutNum = g_NationalDay_Shop_ItemCut[g_NationalDay_Shop_CurIndex]		
			
		--消耗元宝
		local strcut = math.floor(nPrimeCost * cutNum / 100) * g_NationalDay_Shop_BuyNum
			
		--最低折扣时所需元宝数量
		local NeedYBLow = math.floor(nPrimeCost * nlowCut / 100) * g_NationalDay_Shop_BuyNum
			
		--折华令可抵扣
		local zhehualing = math.floor(nZheHuaCut * nPrimeCost / 100) * g_NationalDay_Shop_BuyNum
			
		if g_NationalDay_Shop_ZheHuaLing >= zhehualing then
			if strcut-zhehualing < NeedYBLow then
				zhehualing = strcut - NeedYBLow
			end
			str = ScriptGlobal_Format("#{GQKJ_190722_181}", zhehualing)
		else
			zhehualing = g_NationalDay_Shop_ZheHuaLing
			if strcut-zhehualing < NeedYBLow then
				zhehualing = strcut - NeedYBLow
			end
			str = ScriptGlobal_Format("#{GQKJ_190722_181}", zhehualing)
		end
		NationalDay_Shop_BuyItem_Text2:SetText(str)
			
		--消耗元宝
		str = ScriptGlobal_Format("#{GQKJ_190722_180}", strcut-zhehualing)
		NationalDay_Shop_BuyItem_Text1:SetText(str)
	end
	
end

function NationalDay_Shop_BuyItem_ShowClick()

	local nItemId, nItemNum, nPrimeCost, nLimitType, nLimitNum, nZheHuaCut, nlowCut = Lua_GetNationalShopItemInfo(g_NationalDay_Shop_CurIndex);
	if nItemId > 0 then	
		if nItemId == g_NationalDay_Shop_ShowItem1 then
			Clear_XSCRIPT()
				Set_XSCRIPT_ScriptID(888051)
				Set_XSCRIPT_Function_Name("DressPreview")
				Set_XSCRIPT_Parameter(0, 10126917 )
				Set_XSCRIPT_Parameter(1, 158 )
				Set_XSCRIPT_Parameter(2, 125 )
				Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()
		end
		if nItemId == g_NationalDay_Shop_ShowItem2 then
			Clear_XSCRIPT()
				Set_XSCRIPT_ScriptID(888051)
				Set_XSCRIPT_Function_Name("DressPreview")
				Set_XSCRIPT_Parameter(0, 10127204 )
				Set_XSCRIPT_Parameter(1, 193 )
				Set_XSCRIPT_Parameter(2, 154 )
				Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()
		end
	end
	
end

