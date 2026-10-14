---ShowShop.lua
local TOTALFITTINGKIND_NUM = 10;
local SHOWGOODS_BUTTONS_NUM = 18;
local SHOWGOODS_BUTTONS = {};
local SHOWGOODS_DESCS = {};
local SHOWGOODS_PRICE = {};
local SHOWSHOP_LIST_A = {};
local SHOWSHOP_LIST_B = {};

local g_nPageNum = 1;
local g_maxPage = 1;
local objCared = -1;

local CU_SHOWCREDIT			= 14	--秀场积分

local MAX_OBJ_DISTANCE = 3.0;

--存储随机排序的索引值
local	g_tOrderPool	= {};
--当前商店的商品数量
local	g_nTotalNum		= 0;
local g_IsEnableFanQuanShop = 1--关闭返券商店功能的开关，在YuanBaoShop、XuanShop、ShowShop界面中有这个开关，必须保持一致
local g_nTargetID = -1

local g_ShowShop_Frame_UnifiedPosition;

--标签页索引值
local ShowShopTabIdx = {
	YuanBao 	= 0,	--元宝商店
	Bind		= 1,	--绑定元宝商店
	Fanquan	= 2,	--返券商店
	IMDress		= 3,	--炫装商城
	Show = 6, --秀场商店
}

local g_Show_LastA = 1
local g_Show_LastB = 1
local g_Show_PlayCard_CurPage = 0
local g_Show_PlayCard_Image = {
	[1] = "set:adpic1 image:adpic1_1",
	[2] = "set:adpic1 image:adpic1_2",
	[3] = "set:adpic2 image:adpic2_1",
	[4] = "set:adpic2 image:adpic2_2",
}
local g_Show_PlayCard_CtlButton = {}
local g_Show_PlayCard_URL = {
	[1] = "WEB_YBSDGUANGGAO_1", --"WEB_GUANWANG" ,
	[2] = "WEB_YBSDGUANGGAO_2", --"WEB_LUNTAN",
	[3] = "WEB_YBSDGUANGGAO_3", --"WEB_JIANYI",
	[4] = "WEB_YBSDGUANGGAO_4", --"WEB_VIPJIESHAO",
}
local GOODS_BUTTONS_JiYuan_NUM = 6;
local GOODS_JiYuan_BUTTONS = {}
local GOODS_JiYuan_BUTTONS_ICON = {};
local GOODS_JiYuan_BUTTONS_Buy = {};
local GOODS_JiYuan_DESCS = {};
local GOODS_JiYuan_BAD    = {};
--设置经典版使用的图标资源
local IconTable = {
	["H"] = "set:CommonFrame20 image:Item_Hot",
	["S"] = "set:CommonFrame20 image:Item_Special",
	["A"] = "set:CommonFrame20 image:Item_Activity",
	["D"] = "set:CommonFrame20 image:Item_Discount",
	["N"] = "set:CommonFrame20 image:Item_New",
	["L"] = "set:CommonFrame20 image:Item_Limit",
}
--===============================================
-- PreLoad
--===============================================
function ShowShop_PreLoad()
	-- this:RegisterEvent("OPEN_SHOWCREDITSHOP");
	-- this:RegisterEvent("OBJECT_CARED_EVENT",false);
	-- this:RegisterEvent("CLOSE_BOOTH");
	-- this:RegisterEvent("ADJEST_UI_POS",false)
	-- this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
	-- this:RegisterEvent("UPDATE_SHOWCREDITPOINT")
	-- this:RegisterEvent("TOGGLE_SHOWSHOP")
	-- this:RegisterEvent("OPEN_JIYUAN_BOOTH")
	-- this:RegisterEvent("GAMELOGIN_OPEN_SELECT_CHARACTOR")
	-- this:RegisterEvent("UI_COMMAND");	
end

--===============================================
-- OnLoad
--===============================================
function ShowShop_OnLoad()
	SHOWGOODS_BUTTONS[1] = ShowShop_Item1;
	SHOWGOODS_BUTTONS[2] = ShowShop_Item2;
	SHOWGOODS_BUTTONS[3] = ShowShop_Item3;
	SHOWGOODS_BUTTONS[4] = ShowShop_Item4;
	SHOWGOODS_BUTTONS[5] = ShowShop_Item5;
	SHOWGOODS_BUTTONS[6] = ShowShop_Item6;
	SHOWGOODS_BUTTONS[7] = ShowShop_Item7;
	SHOWGOODS_BUTTONS[8] = ShowShop_Item8;
	SHOWGOODS_BUTTONS[9] = ShowShop_Item9;
	SHOWGOODS_BUTTONS[10]= ShowShop_Item10;
	SHOWGOODS_BUTTONS[11]= ShowShop_Item11;
	SHOWGOODS_BUTTONS[12]= ShowShop_Item12;
	SHOWGOODS_BUTTONS[13]= ShowShop_Item13;
	SHOWGOODS_BUTTONS[14]= ShowShop_Item14;
	SHOWGOODS_BUTTONS[15]= ShowShop_Item15;
	SHOWGOODS_BUTTONS[16]= ShowShop_Item16;
	SHOWGOODS_BUTTONS[17]= ShowShop_Item17;
	SHOWGOODS_BUTTONS[18]= ShowShop_Item18;

	SHOWGOODS_DESCS[1] = ShowShop_ItemInfo1_Text;
	SHOWGOODS_DESCS[2] = ShowShop_ItemInfo2_Text;
	SHOWGOODS_DESCS[3] = ShowShop_ItemInfo3_Text;
	SHOWGOODS_DESCS[4] = ShowShop_ItemInfo4_Text;
	SHOWGOODS_DESCS[5] = ShowShop_ItemInfo5_Text;
	SHOWGOODS_DESCS[6] = ShowShop_ItemInfo6_Text;
	SHOWGOODS_DESCS[7] = ShowShop_ItemInfo7_Text;
	SHOWGOODS_DESCS[8] = ShowShop_ItemInfo8_Text;
	SHOWGOODS_DESCS[9] = ShowShop_ItemInfo9_Text;
	SHOWGOODS_DESCS[10]= ShowShop_ItemInfo10_Text;
	SHOWGOODS_DESCS[11]= ShowShop_ItemInfo11_Text;
	SHOWGOODS_DESCS[12]= ShowShop_ItemInfo12_Text;
	SHOWGOODS_DESCS[13]= ShowShop_ItemInfo13_Text;
	SHOWGOODS_DESCS[14]= ShowShop_ItemInfo14_Text;
	SHOWGOODS_DESCS[15]= ShowShop_ItemInfo15_Text;
	SHOWGOODS_DESCS[16]= ShowShop_ItemInfo16_Text;
	SHOWGOODS_DESCS[17]= ShowShop_ItemInfo17_Text;
	SHOWGOODS_DESCS[18]= ShowShop_ItemInfo18_Text;

	SHOWGOODS_PRICE[1] = ShowShop_ItemInfo1_GB;
	SHOWGOODS_PRICE[2] = ShowShop_ItemInfo2_GB;
	SHOWGOODS_PRICE[3] = ShowShop_ItemInfo3_GB;
	SHOWGOODS_PRICE[4] = ShowShop_ItemInfo4_GB;
	SHOWGOODS_PRICE[5] = ShowShop_ItemInfo5_GB;
	SHOWGOODS_PRICE[6] = ShowShop_ItemInfo6_GB;
	SHOWGOODS_PRICE[7] = ShowShop_ItemInfo7_GB;
	SHOWGOODS_PRICE[8] = ShowShop_ItemInfo8_GB;
	SHOWGOODS_PRICE[9] = ShowShop_ItemInfo9_GB;
	SHOWGOODS_PRICE[10]= ShowShop_ItemInfo10_GB;
	SHOWGOODS_PRICE[11]= ShowShop_ItemInfo11_GB;
	SHOWGOODS_PRICE[12]= ShowShop_ItemInfo12_GB;
	SHOWGOODS_PRICE[13]= ShowShop_ItemInfo13_GB;
	SHOWGOODS_PRICE[14]= ShowShop_ItemInfo14_GB;
	SHOWGOODS_PRICE[15]= ShowShop_ItemInfo15_GB;
	SHOWGOODS_PRICE[16]= ShowShop_ItemInfo16_GB;
	SHOWGOODS_PRICE[17]= ShowShop_ItemInfo17_GB;
	SHOWGOODS_PRICE[18]= ShowShop_ItemInfo18_GB;

	GOODS_JiYuan_BUTTONS[1] = ShowShop_ExItem1;
	GOODS_JiYuan_BUTTONS[2] = ShowShop_ExItem2;
	GOODS_JiYuan_BUTTONS[3] = ShowShop_ExItem3;
	GOODS_JiYuan_BUTTONS[4] = ShowShop_ExItem4;
	GOODS_JiYuan_BUTTONS[5] = ShowShop_ExItem5;
	GOODS_JiYuan_BUTTONS[6] = ShowShop_ExItem6;

	GOODS_JiYuan_BUTTONS_Buy[1] = ShowShop_ExItemInfo1_Buy
	GOODS_JiYuan_BUTTONS_Buy[2] = ShowShop_ExItemInfo2_Buy
	GOODS_JiYuan_BUTTONS_Buy[3] = ShowShop_ExItemInfo3_Buy
	GOODS_JiYuan_BUTTONS_Buy[4] = ShowShop_ExItemInfo4_Buy
	GOODS_JiYuan_BUTTONS_Buy[5] = ShowShop_ExItemInfo5_Buy
	GOODS_JiYuan_BUTTONS_Buy[6] = ShowShop_ExItemInfo6_Buy

	GOODS_JiYuan_BUTTONS_ICON[1] = ShowShop_ExItemIcon_1
	GOODS_JiYuan_BUTTONS_ICON[2] = ShowShop_ExItemIcon_2
	GOODS_JiYuan_BUTTONS_ICON[3] = ShowShop_ExItemIcon_3
	GOODS_JiYuan_BUTTONS_ICON[4] = ShowShop_ExItemIcon_4
	GOODS_JiYuan_BUTTONS_ICON[5] = ShowShop_ExItemIcon_5
	GOODS_JiYuan_BUTTONS_ICON[6] = ShowShop_ExItemIcon_6
	
	GOODS_JiYuan_DESCS[1] = ShowShop_ExItemInfo1_Text;
	GOODS_JiYuan_DESCS[2] = ShowShop_ExItemInfo2_Text;
	GOODS_JiYuan_DESCS[3] = ShowShop_ExItemInfo3_Text;
	GOODS_JiYuan_DESCS[4] = ShowShop_ExItemInfo4_Text;
	GOODS_JiYuan_DESCS[5] = ShowShop_ExItemInfo5_Text;
	GOODS_JiYuan_DESCS[6] = ShowShop_ExItemInfo6_Text;

	GOODS_JiYuan_BAD[1] = ShowShop_ExItemInfo1_GB;
	GOODS_JiYuan_BAD[2] = ShowShop_ExItemInfo2_GB;
	GOODS_JiYuan_BAD[3] = ShowShop_ExItemInfo3_GB;
	GOODS_JiYuan_BAD[4] = ShowShop_ExItemInfo4_GB;
	GOODS_JiYuan_BAD[5] = ShowShop_ExItemInfo5_GB;
	GOODS_JiYuan_BAD[6] = ShowShop_ExItemInfo6_GB;

	SHOWSHOP_LIST_A[1] = {btn = ShowShop_Button1, shoplist = {}}
	SHOWSHOP_LIST_A[1].shoplist[1] = "#{XYBSD_161018_9}"
	
	SHOWSHOP_LIST_A[2] = {btn = ShowShop_Button2, shoplist = {}}
	SHOWSHOP_LIST_A[2].shoplist[1] = "#{XYBSD_161018_16}"
	SHOWSHOP_LIST_A[2].shoplist[2] = "#{XYBSD_161018_17}"
	SHOWSHOP_LIST_A[2].shoplist[3] = "#{XYBSD_161018_18}"
	
	SHOWSHOP_LIST_A[3] = {btn = ShowShop_Button3, shoplist = {}}
	SHOWSHOP_LIST_A[3].shoplist[1] = "#{XYBSD_161018_19}"
	
	--二级商店
	SHOWSHOP_LIST_B[1] = ShowShop_Button01_Bind
	SHOWSHOP_LIST_B[2] = ShowShop_Button02_Bind
	SHOWSHOP_LIST_B[3] = ShowShop_Button03_Bind
	
	if g_Show_LastA ~= nil and g_Show_LastA > 0 and g_Show_LastA < 4 then
		SHOWSHOP_LIST_A[g_Show_LastA].btn : SetCheck(0)
	end
	
	if g_Show_LastB ~= nil and g_Show_LastB > 0 and g_Show_LastB < 4 then
		SHOWSHOP_LIST_B[g_Show_LastB] : SetCheck(0)
	end
	
	for i = 1, 3 do
		SHOWSHOP_LIST_B[i]:Hide()
	end
	
	if g_IsEnableFanQuanShop == 0 then
		ShowShop_Fanquan:Hide()
	end
	 g_ShowShop_Frame_UnifiedPosition=ShowShop_Frame:GetProperty("UnifiedPosition");
	 
	 --广告牌
	 g_Show_PlayCard_CtlButton[1] = ShowShop_ExButton1
	 g_Show_PlayCard_CtlButton[2] = ShowShop_ExButton2
	 g_Show_PlayCard_CtlButton[3] = ShowShop_ExButton3
	 g_Show_PlayCard_CtlButton[4] = ShowShop_ExButton4
end

--===============================================
-- OnEvent
--===============================================
function ShowShop_OnEvent(event)
	-- if ( event == "HIDE_ON_SCENE_TRANSED" ) then
	-- 	ShowShop_Close();
	-- end

	-- if ( event == "OPEN_SHOWCREDITSHOP" ) then
	-- 	if (GetSceneID() == 77 or GetSceneID() == 578) then
	-- 		PushDebugMessage("#{IMXZ_20100919_104}")
	-- 		return;
	-- 	end
		
	-- 	if (Player:GetData("LEVEL") < 15) then
	-- 		PushDebugMessage("#{XCZB_160105_77}")
	-- 		return;
	-- 	end
		
	-- 	if( this:IsVisible() == false ) then
	-- 		if (IsWindowShow("YbMarket")) then
	-- 			CloseWindow("YbMarket", true);
	-- 		end
	-- 		if(IsWindowShow("DressClosetFrame")) then
	-- 			CloseWindow("DressClosetFrame", true);
	-- 		end
	-- 		if(IsWindowShow("DuanWu_JiFenShop")) then
	-- 			CloseWindow("DuanWu_JiFenShop", true);
	-- 		end
	-- 		PushEvent( "CLOSE_DRESSPREVIEW") 
	-- 		if (arg0 and arg0 == "6") then
	-- 			if (arg1 and arg2) then
	-- 				ShowShop_Frame:SetProperty("UnifiedXPosition", arg1);
	-- 				ShowShop_Frame:SetProperty("UnifiedYPosition", arg2);
	-- 			end
	-- 		else
	-- 			ShowShop_Frame_On_ResetPos()
	-- 		end
	
	-- 		--确认购买
	-- 		ShowShop_BuyCheck:Show()
	-- 		ShowShop_BuyCheck_Text:Show()
	-- 		local check  = tonumber(NpcShop:GetCreditShopBuyDirectly())
	-- 		if(check>=1)then
	-- 			ShowShop_BuyCheck:SetCheck(0)
	-- 		else
	-- 			ShowShop_BuyCheck:SetCheck(1)
	-- 		end
			
	-- 		for i=1, SHOWGOODS_BUTTONS_NUM  do
	-- 			SHOWGOODS_BUTTONS[i]:SetActionItem(-1)
	-- 			SHOWGOODS_BUTTONS[i]:Show()
	-- 			SHOWGOODS_DESCS[i]:SetText("")
	-- 			SHOWGOODS_DESCS[i]:Show();
	-- 			SHOWGOODS_PRICE[i]:SetText("")
	-- 			SHOWGOODS_PRICE[i]:Show();
	-- 		end
	-- 		ShowShop_Gift:Disable()
	-- 		--积分和历史积分
	-- 		ShowShop_Integrate_Now:SetText("#{XCZB_160105_54}")
	-- 		ShowShop_Integrate_Now:Show()
	-- 		ShowShop_Integrate_History:SetText("#{XCZB_160105_55}")
	-- 		ShowShop_Integrate_History:Show()
	-- 		ShowShop_Yuanbao:Show()
	-- 		ShowShop_Gongzi:Show()
	-- 		ShowShop_XuanShop:Show()
	-- 		if g_IsEnableFanQuanShop == 1 then
	-- 			ShowShop_Fanquan:Show()
	-- 		end
	-- 		ShowShop_VIP:Show()
	-- 		ShowShop_Lijin:Show()
	-- 		ShowShop_Xinyibi:Show()
	-- 		g_nPageNum = 1
	-- 		g_nTotalNum	= 0;
		
	-- 		if (arg0 and arg0 == "6") then
	-- 			ShowShop_Show(1);  --元宝商店打开
	-- 		else
	-- 			ShowShop_Show(0);  --npc打开
	-- 		end
	-- 		--请求机缘秘宝商店
	-- 		Clear_XSCRIPT();
	-- 			Set_XSCRIPT_Function_Name("OpenJiYuanShop");
	-- 			Set_XSCRIPT_ScriptID(888902);
	-- 			Set_XSCRIPT_Parameter(0,g_nTargetID);
	-- 			Set_XSCRIPT_ParamCount(1);
	-- 		Send_XSCRIPT();
	-- 		--滚动信息
	-- 		ShowShop_ADRandom()
	-- 		ShowShop_PlayCardChangePage(1)
	-- 		this:Show();
	-- 		OpenBooth();
	-- 	end
	-- 	--关心商人Obj
	-- 	objCared = NpcShop:GetNpcId();
	-- 	this:CareObject(objCared, 1, "ShowShop");
	-- 	NpcShop:CloseConfirm();
	-- 	ShowShop_UpdatePage(1);

	-- 	SetDefaultMouse();

	-- 	this:Show();
		
	-- elseif ( event == "UPDATE_BOOTH" ) then
	-- 	ShowShop_UpdatePage(g_nPageNum);

	-- elseif (event == "OBJECT_CARED_EVENT") then
	-- 	if(tonumber(arg0) ~= objCared) then
	-- 		return;
	-- 	end

	-- 	--如果和商人的距离大于一定距离或者被删除，自动关闭
	-- 	if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
	-- 		--取消关心
	-- 		CloseBooth();
	-- 		SetDefaultMouse();
	-- 		this:CareObject(objCared, 0, "ShowShop");
	-- 		NpcShop:CloseConfirm();
	-- 		this:Hide();
	-- 	end

	-- elseif (event == "CLOSE_BOOTH") then
	-- 	--取消关心
	-- 	CloseBooth();
	-- 	this:CareObject(objCared, 0, "ShowShop");
	-- 	NpcShop:CloseConfirm();
	-- 	this:Hide();
	-- 	SetDefaultMouse();

	-- elseif (event == "ADJEST_UI_POS" ) then
	-- 	ShowShop_Frame_On_ResetPos()

	-- elseif (event == "VIEW_RESOLUTION_CHANGED") then
	-- 	ShowShop_Frame_On_ResetPos()

	-- elseif (event == "UPDATE_SHOWCREDITPOINT") then
	-- 	local LjCreditPoint = arg0
	-- 	local uCreditPoint = GetShowShopCredit()

	-- 	ShowShop_Integrate_Now:SetText("#{XCZB_160105_33}" .. tostring(uCreditPoint))
	-- 	ShowShop_Integrate_History:SetText("#{XCZB_160105_34}" .. tostring(LjCreditPoint))
	-- elseif (event == "TOGGLE_SHOWSHOP") then
	-- 	ShowShop_Close()
	-- elseif ( event == "OPEN_JIYUAN_BOOTH" ) then
	-- 	ShowShop_UpdateJiYuanBooth()
	-- elseif( event == "GAMELOGIN_OPEN_SELECT_CHARACTOR") then
	-- 	ShowShop_ResetInfo()
	-- elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 20180801) then
	-- 	if( this:IsVisible() == false ) then
	-- 		if (IsWindowShow("YbMarket")) then
	-- 			CloseWindow("YbMarket", true);
	-- 		end
	-- 		if(IsWindowShow("DressClosetFrame")) then
	-- 			CloseWindow("DressClosetFrame", true);
	-- 		end
	-- 		PushEvent( "CLOSE_DRESSPREVIEW") 

	-- 		ShowShop_Frame_On_ResetPos()
	
	-- 		--确认购买
	-- 		ShowShop_BuyCheck:Show()
	-- 		ShowShop_BuyCheck_Text:Show()
	-- 		local check  = tonumber(NpcShop:GetCreditShopBuyDirectly())
	-- 		if(check>=1)then
	-- 			ShowShop_BuyCheck:SetCheck(0)
	-- 		else
	-- 			ShowShop_BuyCheck:SetCheck(1)
	-- 		end
			
	-- 		for i=1, SHOWGOODS_BUTTONS_NUM  do
	-- 			SHOWGOODS_BUTTONS[i]:SetActionItem(-1)
	-- 			SHOWGOODS_BUTTONS[i]:Show()
	-- 			SHOWGOODS_DESCS[i]:SetText("")
	-- 			SHOWGOODS_DESCS[i]:Show();
	-- 			SHOWGOODS_PRICE[i]:SetText("")
	-- 			SHOWGOODS_PRICE[i]:Show();
	-- 		end
	-- 		ShowShop_Gift:Disable()
	-- 		--积分和历史积分
	-- 		ShowShop_Integrate_Now:SetText("#{XCZB_160105_54}")
	-- 		ShowShop_Integrate_Now:Show()
	-- 		ShowShop_Integrate_History:SetText("#{XCZB_160105_55}")
	-- 		ShowShop_Integrate_History:Show()
	-- 		ShowShop_Yuanbao:Show()
	-- 		ShowShop_Gongzi:Show()
	-- 		ShowShop_XuanShop:Show()
	-- 		if g_IsEnableFanQuanShop == 1 then
	-- 			ShowShop_Fanquan:Show()
	-- 		end
	-- 		ShowShop_VIP:Show()
	-- 		ShowShop_Lijin:Show()
	-- 		ShowShop_Xinyibi:Show()
	-- 		g_nPageNum = 1
	-- 		g_nTotalNum	= 0;
		

	-- 		ShowShop_Show(0);  --npc打开
			
	-- 		--请求机缘秘宝商店
	-- 		Clear_XSCRIPT();
	-- 			Set_XSCRIPT_Function_Name("OpenJiYuanShop");
	-- 			Set_XSCRIPT_ScriptID(888902);
	-- 			Set_XSCRIPT_Parameter(0,g_nTargetID);
	-- 			Set_XSCRIPT_ParamCount(1);
	-- 		Send_XSCRIPT();
	-- 		--滚动信息
	-- 		ShowShop_ADRandom()
	-- 		ShowShop_PlayCardChangePage(1)
	-- 		this:Show();
	-- 		OpenBooth();
	-- 	end
	-- 	--关心商人Obj
	-- 	objCared = NpcShop:GetNpcId();
	-- 	this:CareObject(objCared, 1, "ShowShop");
	-- 	NpcShop:CloseConfirm();

	-- 	SetDefaultMouse();

	-- 	g_Show_LastB = 1
	-- 	SHOWSHOP_LIST_B[g_Show_LastB]:SetCheck(1)
	-- 	ShowShop_UpdateList(1)
	-- end
end

--界面显示
function ShowShop_Show(nFlag)
	if (IsWindowShow("YuanbaoShop")) then
		CloseWindow("YuanbaoShop", true);
	end

-- 	if IsInTServer() == 1 then
-- --		PushDebugMessage("#{BHKF_140909_327}")
-- 		return;
-- 	end	
	
	ShowShop_Yuanbao:SetCheck(0)
	ShowShop_Gongzi:SetCheck(0)
	ShowShop_XuanShop:SetCheck(0)
	ShowShop_Fanquan:SetCheck(0)
	ShowShop_VIP:SetCheck(0)
	ShowShop_Lijin:SetCheck(0)
	ShowShop_Xinyibi:SetCheck(1)
	
	--激活子按钮
	for i = 1, 3 do
		SHOWSHOP_LIST_B[i]:Hide()
		if SHOWSHOP_LIST_A[g_Show_LastA].shoplist[i] ~= nil then
			SHOWSHOP_LIST_B[i]:Show()
			SHOWSHOP_LIST_B[i]:SetText(SHOWSHOP_LIST_A[g_Show_LastA].shoplist[i])
		end
	end
	SHOWSHOP_LIST_A[g_Show_LastA].btn:SetCheck(1)
	SHOWSHOP_LIST_B[g_Show_LastB]:SetCheck(1)
	
	--if nFlag == 1 then
		ShowShop_UpdateItem(g_Show_LastA+500, g_Show_LastB)
	--end
end
--===============================================
-- UpdateItem
--===============================================
function ShowShop_UpdateItem(shopA, shopB)
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OpenYuanbaoShop");
		Set_XSCRIPT_ScriptID(888902);
		Set_XSCRIPT_Parameter(0,g_nTargetID);
		Set_XSCRIPT_Parameter(1,shopA);
		Set_XSCRIPT_Parameter(2,shopB);
		Set_XSCRIPT_ParamCount(3);
	Send_XSCRIPT();
end
--===============================================
-- UpdatePage
--===============================================
function ShowShop_UpdatePage(thePage)
	--使用什么作为货币
	local nUnit = NpcShop:GetShopType("unit")
	if CU_SHOWCREDIT ~= nUnit then
		return
	end

	--批量购买
	local nMult = NpcShop:GetShopType("buymult");
	if nMult <= 0 then
		ShowShop_MBuy:Disable();
	else
		ShowShop_MBuy:Enable();
	end
	
	local	i	= 1;
	g_nTotalNum = GetActionNum("boothitem")

	-- 计算总页数
	local	nTotalPage;
	if( g_nTotalNum < 1 ) then
		nTotalPage	= 1;
	else
		nTotalPage	= math.floor((g_nTotalNum-1)/SHOWGOODS_BUTTONS_NUM)+1;
	end

	g_maxPage = nTotalPage;

	if(thePage < 1 or thePage > nTotalPage) then
		return;
	end

	g_nPageNum = thePage;

	local nStartIndex = (thePage-1)*SHOWGOODS_BUTTONS_NUM;

	local nActIndex = nStartIndex;
	i	= 1;
	while i <= SHOWGOODS_BUTTONS_NUM do
		local theAction = EnumAction(nActIndex, "boothitem");
		if theAction:GetID() ~= 0 then
			SHOWGOODS_BUTTONS[i]:SetActionItem(theAction:GetID());

			if(theAction:GetItemColorInShop()~="") then
				SHOWGOODS_DESCS[i]:SetText( theAction:GetItemColorInShop()..theAction:GetName() );
			else
				SHOWGOODS_DESCS[i]:SetText( theAction:GetName() );
			end

			local	nPrice	= NpcShop:EnumItemPrice(nActIndex)
			SHOWGOODS_PRICE[i]:SetText("#{XCZB_160105_28}" .. tostring(nPrice))

			i = i+1;
		else
			SHOWGOODS_BUTTONS[i]:SetActionItem(-1);
			SHOWGOODS_DESCS[i]:SetText("");
			SHOWGOODS_PRICE[i]:SetText("");

			i = i+1;
		end
		nActIndex = nActIndex+1;
	end


	if( nTotalPage == 1 ) then
		ShowShop_Bk_New:Hide()
	else
		ShowShop_Bk_New:Show()

		ShowShop_UpPage:Enable()
		ShowShop_DownPage:Enable()

		if (g_nPageNum == nTotalPage) then
			ShowShop_DownPage:Disable()
		end

		if (g_nPageNum == 1) then
			ShowShop_UpPage:Disable()
		end

		ShowShop_CurrentlyPage:SetText(tostring(g_nPageNum) .. "/" .. tostring(nTotalPage));
	end
end
--===============================================
-- Fenye_Clicked
--===============================================
function ShowShop_ChangeTabIndex(nIndex)
	nIndex = nIndex - 1
	if (nIndex == ShowShopTabIdx.Fanquan and g_IsEnableFanQuanShop == 0) then --关闭返券商店
		return
	end

	if ( nIndex == ShowShopTabIdx.Show ) then
		return
	end
	
	if(IsWindowShow("ShowShop_MBuy")) then
		CloseWindow("ShowShop_MBuy", true);
	end
	if(IsWindowShow("Shop_Fitting2")) then
		CloseWindow("Shop_Fitting2", true);
	end
	--if ( nIndex == ShowShopTabIdx.IMDress) then
	--	PushEvent("OPEN_IMDRESS_YUANBAOSHOP", tostring(nIndex), ShowShop_Frame:GetProperty("UnifiedXPosition"), ShowShop_Frame:GetProperty("UnifiedYPosition"))
	--else
		PushEvent("TOGGLE_YUANBAOSHOP", tostring(nIndex), ShowShop_Frame:GetProperty("UnifiedXPosition"), ShowShop_Frame:GetProperty("UnifiedYPosition"), -1 ,-1);
	--end
end

--===============================================
--一级菜单
--===============================================
function ShowShop_UpdateList(nIndex)
	if nIndex < 1 or nIndex > 3 or nIndex == g_Show_LastA then
	 	return
	end
	
	if(IsWindowShow("ShowShop_MBuy")) then
		CloseWindow("ShowShop_MBuy", true);
	end
	g_Show_LastA = nIndex
	g_Show_LastB = 1
	
		--激活子按钮
	for i = 1, 3 do
		SHOWSHOP_LIST_B[i]:Hide()
		if SHOWSHOP_LIST_A[g_Show_LastA].shoplist[i] ~= nil then
			SHOWSHOP_LIST_B[i]:Show()
			SHOWSHOP_LIST_B[i]:SetText(SHOWSHOP_LIST_A[g_Show_LastA].shoplist[i])
		end
	end
	SHOWSHOP_LIST_A[g_Show_LastA].btn:SetCheck(1)
	SHOWSHOP_LIST_B[g_Show_LastB]:SetCheck(1)
	ShowShop_UpdateItem(g_Show_LastA+500, g_Show_LastB)
		
end
--===============================================
--二级菜单
--===============================================
function ShowShop_Update_SubList(nIndex)
	if nIndex < 1 or nIndex > 3 then
		return
	end
	if(IsWindowShow("ShowShop_MBuy")) then
		CloseWindow("ShowShop_MBuy", true);
	end
	g_Show_LastB = nIndex
	SHOWSHOP_LIST_B[g_Show_LastB]:SetCheck(1)
	ShowShop_UpdateItem(g_Show_LastA+500, g_Show_LastB)
end
--===============================================
-- Button_Clicked
--===============================================
function ShowGoodButton_Clicked(nIndex)
	if(nIndex < 1 or nIndex > SHOWGOODS_BUTTONS_NUM) then
		return;
	end

	SHOWGOODS_BUTTONS[nIndex]:DoAction();
end

--===============================================
--滚动信息顺序随机排列
--===============================================
function ShowShop_ADRandom()
	ShowShop_ScrollInfo_Frame:ClearInfo()

	local ADInfo = {
				"#{YBSD_081225_093}",
				"#{YBSD_081225_094}",
				"#{YBSD_081225_095}",
			}
	local nADInfoNum = table.getn(ADInfo)
	if (nil == nADInfoNum or nADInfoNum < 1 or nADInfoNum > 3) then
		nADInfoNum = 3
	end

	for i = 0 ,1 do
		local idx = math.random(1 ,nADInfoNum - i)
		local str = ADInfo[idx]
		ADInfo[idx] = ADInfo[nADInfoNum - i]
		ADInfo[nADInfoNum - i] = str
	end

	for i = 1 ,nADInfoNum do
		ShowShop_ScrollInfo_Frame:SetScrollInfoFixed(ADInfo[i],"1")
	end

end
--试穿
function ShowShop_OpenFitting()
	if IsIdleLogic() ~= 1 and IsMoveLogic() ~= 1 then
		SetNotifyTip("#{YBSD_081225_100}");
		return 0;
	end
	StopMove();
	if(IsWindowShow("ShowShop_MBuy")) then
		CloseWindow("ShowShop_MBuy", true);
	end
	RestoreShopFitting(TOTALFITTINGKIND_NUM);
	ClearCurFittingItemByType(TOTALFITTINGKIND_NUM)
	MouseCmd_ShopFittingSet();
	PushEvent("YUANBAOSHOP_FITTING_RESET")
	SetNotifyTip("#{YBSD_081225_099}");
end

--===============================================
-- PageUp
--===============================================
function ShowShop_PageUp()
	local curPage = g_nPageNum - 1;
	if curPage < 1 then
		return
	end

	if ( curPage >= g_maxPage ) then
		curPage = g_maxPage;
	end
	NpcShop:CloseConfirm();
	ShowShop_UpdatePage( curPage );
end

--===============================================
-- PageDown
--===============================================
function ShowShop_PageDown()
	local curPage = g_nPageNum + 1;
	if curPage < 1 then
		return
	end

	if ( curPage >= g_maxPage ) then
		curPage = g_maxPage;
	end

	NpcShop:CloseConfirm();
	ShowShop_UpdatePage( curPage );
end

--===============================================
-- Close
--===============================================
function ShowShop_Close()

	CloseBooth();
	SetDefaultMouse();
	--取消关心
	objCared = -1
	g_nTargetID = -1
	this:CareObject(objCared, 0, "ShowShop");
	NpcShop:CloseConfirm();
	PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "close")
	if(IsWindowShow("Shop_Fitting2")) then
		CloseWindow("Shop_Fitting2", true);
	end
	if(IsWindowShow("ShowShop_MBuy")) then
		CloseWindow("ShowShop_MBuy", true);
	end
	KillTimer("ShowShop_PlayCardTimer()")
	--g_Show_LastA = 1
	--g_Show_LastB = 1
	this:Hide();
end

--===============================================
-- 批量购买
--===============================================
function ShowShop_BuyMult()
	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end	
	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	if(IsWindowShow("ShopPet_Fitting")) then
		CloseWindow("ShopPet_Fitting", true);
	end
	if(IsWindowShow("ShowShop_MBuy")) then
		CloseWindow("ShowShop_MBuy", true);
	end
	NpcShop:CloseConfirm();
	PrepearBuyMult();
	PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "close")
	SetNotifyTip("#{FFSDGZ_120615_94}");
end


function ShowShop_querengoumai_Clicked()
	NpcShop:CloseConfirm();
	PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "close")
	if(NpcShop:GetCreditShopBuyDirectly() == 0)then
		ShowShop_BuyCheck:SetCheck(0);
		NpcShop:SetCreditShopBuyDirectly(1);
	else
		ShowShop_BuyCheck:SetCheck(1);
		NpcShop:SetCreditShopBuyDirectly(0);
	end
end

function ShowShop_Frame_On_ResetPos()
  ShowShop_Frame:SetProperty("UnifiedPosition", g_ShowShop_Frame_UnifiedPosition);
end

function ShowShop_ResetInfo()
	g_Show_LastA = 1
	g_Show_LastB = 1
end
--==================机缘秘宝=============================

function ShowShop_PlayCardChangePage(nPageNum)
	g_Show_PlayCard_CurPage = nPageNum
	if nPageNum <= 0 or nPageNum > 4 then
		return
	end
	ShowShop_Image:SetProperty("NormalImage", g_Show_PlayCard_Image[nPageNum])
	ShowShop_Image:SetProperty("HoverImage", g_Show_PlayCard_Image[nPageNum])
	ShowShop_Image:SetProperty("DisabledImage", g_Show_PlayCard_Image[nPageNum])
	ShowShop_Image:SetProperty("PushedImage", g_Show_PlayCard_Image[nPageNum])
	g_Show_PlayCard_CtlButton[nPageNum]:SetCheck(1)
	KillTimer("ShowShop_PlayCardTimer()")
	SetTimer("ShowShop", "ShowShop_PlayCardTimer()", 5000)
end

function ShowShop_PlayCardTimer()
	g_Show_PlayCard_CurPage = g_Show_PlayCard_CurPage + 1
	if g_Show_PlayCard_CurPage > 4 then
		g_Show_PlayCard_CurPage = 1
	end
	ShowShop_PlayCardChangePage(g_Show_PlayCard_CurPage)
end

function ShowShop_ImageClicked()
	if g_Show_PlayCard_URL[g_Show_PlayCard_CurPage] ~= nil then
		GameProduceLogin:OpenURL(GetWeblink(g_Show_PlayCard_URL[g_Show_PlayCard_CurPage]))
	end
end

function ShowShop_HelpBtn_Clicked()
	if (g_tabIndex == ShopTabIdx.YuanBao) then
		OpenYBShopReference("yuanbao")
	elseif (g_tabIndex == ShopTabIdx.Bind) then
		OpenYBShopReference("yuanbao")
	elseif (g_tabIndex == ShopTabIdx.GiftToken) then
		if GameProduceLogin:IsWeGameClient() > 0 then
			OpenYBShopReference("#{WEJR_230303_27}")
		else
			OpenYBShopReference("#{FQ_101210_08}")
		end
	elseif (g_tabIndex == ShopTabIdx.VipShop) then
		OpenYBShopReference("#{FFSDGZ_120615_85}")
	elseif (g_tabIndex == ShopTabIdx.Lijin) then
		OpenYBShopReference("#{TBSD_130816_6}")
	end
end
function ShowShop_web_Clicked()
	Chongzhi()
end

--机缘商店更新
function ShowShop_UpdateJiYuanBooth()
	local i = 1;
	while i <= GOODS_BUTTONS_JiYuan_NUM do
		local theAction = EnumAction(i - 1, "boothjiyuanitem");
		if theAction:GetID() ~= 0 then
			local IconKey = theAction:GetItemIconInShop_JiYuan()
			if IconKey ~= nil and IconKey ~= "" and IconTable[IconKey] ~= nil then
				GOODS_JiYuan_BUTTONS_ICON[i]:SetProperty("Image" , IconTable[IconKey])
			else
				GOODS_JiYuan_BUTTONS_ICON[i]:SetProperty("Image" , "")
			end
			GOODS_JiYuan_BUTTONS[i]:SetActionItem(theAction:GetID());
			if theAction:GetMaxNum() > 0 then
				GOODS_JiYuan_BUTTONS_Buy[i] : Show()
			else
				GOODS_JiYuan_BUTTONS_Buy[i] : Hide()
			end
			local	nPrice	= NpcShop:EnumItemPriceJiYuanBooth( i - 1 )
			GOODS_JiYuan_BAD[i]:SetText("#{YBSD_081225_101}" .. tostring(nPrice))

			if(theAction:GetItemColorInShop_JiYuan()~="") then
				GOODS_JiYuan_DESCS[i]:SetText( theAction:GetItemColorInShop_JiYuan()..theAction:GetName() );
			else
				GOODS_JiYuan_DESCS[i]:SetText( theAction:GetName() );
			end
			i = i+1;
		else
			GOODS_JiYuan_BUTTONS_ICON[i]:SetProperty("Image" , "")
			GOODS_JiYuan_BUTTONS[i]:SetActionItem(-1);
			GOODS_JiYuan_DESCS[i]:SetText("");
			GOODS_JiYuan_BAD[i]:SetText("");
			GOODS_JiYuan_BUTTONS_Buy[i] : Hide()
			i = i+1;
		end
	end
	NpcShop:CloseConfirm();
end

--机缘秘宝购买物品
function ShowShop_JiYuanGood_Clicked(nIndex, nWhich)
	if(nIndex < 1 or nIndex > 6) then
		return;
	end
	local theAction = EnumAction(nIndex - 1, "boothjiyuanitem");
	if theAction:GetID() == 0 then
		return
	end
	--批量购买状态
	if Player :GetPlayerActionStatus() == 1 and nWhich == 0 then
		PushDebugMessage("#{FFSDGZ_120615_128}")
		return
	elseif Player :GetPlayerActionStatus() == 2 and nWhich == 0 then --试穿状态
		PushDebugMessage("#{FFSDGZ_120615_128}")
		return
	elseif Player :GetPlayerActionStatus() == 3 and nWhich == 0 then --试穿赠送状态
		PushDebugMessage("#{FFSDGZ_120615_128}")
		return
	end
	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	PushEvent( "JIYUANSHOP_BUY_ITEM_CONFIRM", "open", nIndex - 1)
end