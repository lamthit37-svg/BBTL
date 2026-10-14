--UI COMMAND ID 104
local g_MembersCtl = {};
local g_clientNpcId = -1;
local MAX_OBJ_DISTANCE = 3.0;

local g_CurPage = 1;			--当前在第几页
local g_TotalPage = 0;		--最大页数

local g_shoplist = {}

function CityShop_PreLoad()
	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("OBJECT_CARED_EVENT",false);

	this:RegisterEvent("CITY_SHOW_SHOP",true);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX", false);
end

function CityShop_OnLoad()
	--隐藏无用的控件
	CityShop_Repair:Hide();
	CityShop_AllRepair:Hide();

	--hzp 2009-03-02
	CityShop_Repair_bk:Hide();
	CityShop_AllRepair1_bk:Hide();

	CityShop_Callback1:Hide();
	CityShop_Callback2:Hide();
	CityShop_Callback3:Hide();
	CityShop_Callback4:Hide();
	CityShop_Callback5:Hide();
	
	g_shoplist = { [1] = {ntype = 11, buildname="武坊", maxlevel=5},
						    [2] = { ntype = 5, buildname="锻台", maxlevel =5},
							[3] = {ntype = 2,	buildname="酒肆", maxlevel=3},
							[4] = {ntype = 10, buildname="医舍",	maxlevel=3},
							[5] = {ntype = 3, buildname="钱庄",	maxlevel=5},
							}
end

function CityShop_OnEvent(event)
	City_Shop_SetCtl();
	if(event == "UI_COMMAND" and tonumber(arg0) == 104) then
		g_clientNpcId = Get_XParam_INT(0);
		g_clientNpcId = Target:GetServerId2ClientId(g_clientNpcId);
		City:AskCityShop(Get_XParam_INT(1));

	elseif ( event == "CITY_SHOW_SHOP" and arg0 == "open") then
		if(this:IsVisible() and City_Shop_Is_TicketPrice_Idx(City:GetCityShopInfo(0, "bid")) > 0) then
			City_Shop_Update_CurPage();
		else
		
		local ntype = City:GetCityShopInfo(0, "bid")
		for i=1,5 do
			if tonumber(ntype) == g_shoplist[i].ntype then
				local str = ScriptGlobal_Format("#{BHTZ_140520_10}",g_shoplist[i].buildname, g_shoplist[i].buildname, g_shoplist[i].maxlevel)
				CityShop_SimpleText:SetText(str)
			end
		end		
		this:CareObject(g_clientNpcId, 1, "CityShop");
		City_Shop_Clear();
		City_Shop_Update();
		this:Show();
		end
	elseif ( event == "CITY_SHOW_SHOP" and arg0 == "close") then
		this:Hide();
	elseif ( event == "OBJECT_CARED_EVENT") then
		City_Shop_CareEventHandle(arg0,arg1,arg2);
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" ) then
		City_Shop_SaleBack2Set()
	end
end

function City_Shop_CareEventHandle(careId, op, distance)
		if(nil == careId or nil == op or nil == distance) then
			return;
		end

		if(tonumber(careId) ~= g_clientNpcId) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(op == "distance" and tonumber(distance)>MAX_OBJ_DISTANCE or op=="destroy") then
			this:Hide();
		end
end

function City_Shop_SetCtl()
	g_MembersCtl = 	{
										{act = CityShop_Item1, money = CityShop_ItemInfo1_Price, txt = CityShop_ItemInfo1_Text, mtxt = CityShop_ItemInfo1_GB,
										name=CityShop_ItemInfo1_Name, jiantext = CityShop_ItemInfo1_JianText, jianprice = CityShop_ItemInfo1_JianPrice, jianbk=CityShop_ItemInfo1_Jian},
										{act = CityShop_Item2, money = CityShop_ItemInfo2_Price, txt = CityShop_ItemInfo2_Text, mtxt = CityShop_ItemInfo2_GB,
										name=CityShop_ItemInfo2_Name, jiantext = CityShop_ItemInfo2_JianText, jianprice = CityShop_ItemInfo2_JianPrice, jianbk=CityShop_ItemInfo2_Jian},
										{act = CityShop_Item3, money = CityShop_ItemInfo3_Price, txt = CityShop_ItemInfo3_Text, mtxt = CityShop_ItemInfo3_GB,
										name=CityShop_ItemInfo3_Name, jiantext = CityShop_ItemInfo3_JianText, jianprice = CityShop_ItemInfo3_JianPrice, jianbk=CityShop_ItemInfo3_Jian},
										{act = CityShop_Item4, money = CityShop_ItemInfo4_Price, txt = CityShop_ItemInfo4_Text, mtxt = CityShop_ItemInfo4_GB,
										name=CityShop_ItemInfo4_Name, jiantext = CityShop_ItemInfo4_JianText, jianprice = CityShop_ItemInfo4_JianPrice, jianbk=CityShop_ItemInfo4_Jian},
										{act = CityShop_Item5, money = CityShop_ItemInfo5_Price, txt = CityShop_ItemInfo5_Text, mtxt = CityShop_ItemInfo5_GB,
										name=CityShop_ItemInfo5_Name, jiantext = CityShop_ItemInfo5_JianText, jianprice = CityShop_ItemInfo5_JianPrice, jianbk=CityShop_ItemInfo5_Jian},
										{act = CityShop_Item6, money = CityShop_ItemInfo6_Price, txt = CityShop_ItemInfo6_Text, mtxt = CityShop_ItemInfo6_GB,
										name=CityShop_ItemInfo6_Name, jiantext = CityShop_ItemInfo6_JianText, jianprice = CityShop_ItemInfo6_JianPrice, jianbk=CityShop_ItemInfo6_Jian},
										{act = CityShop_Item7, money = CityShop_ItemInfo7_Price, txt = CityShop_ItemInfo7_Text, mtxt = CityShop_ItemInfo7_GB,
										name=CityShop_ItemInfo7_Name, jiantext = CityShop_ItemInfo7_JianText, jianprice = CityShop_ItemInfo7_JianPrice, jianbk=CityShop_ItemInfo7_Jian},
										{act = CityShop_Item8, money = CityShop_ItemInfo8_Price, txt = CityShop_ItemInfo8_Text, mtxt = CityShop_ItemInfo8_GB,
										name=CityShop_ItemInfo8_Name, jiantext = CityShop_ItemInfo8_JianText, jianprice = CityShop_ItemInfo8_JianPrice, jianbk=CityShop_ItemInfo8_Jian},
										{act = CityShop_Item9, money = CityShop_ItemInfo9_Price, txt = CityShop_ItemInfo9_Text, mtxt = CityShop_ItemInfo9_GB,
										name=CityShop_ItemInfo9_Name, jiantext = CityShop_ItemInfo9_JianText, jianprice = CityShop_ItemInfo9_JianPrice, jianbk=CityShop_ItemInfo9_Jian},
										{act = CityShop_Item10, money = CityShop_ItemInfo10_Price, txt = CityShop_ItemInfo10_Text, mtxt = CityShop_ItemInfo10_GB,
										name=CityShop_ItemInfo10_Name, jiantext = CityShop_ItemInfo10_JianText, jianprice = CityShop_ItemInfo10_JianPrice, jianbk=CityShop_ItemInfo10_Jian},
										{act = CityShop_Item11, money = CityShop_ItemInfo11_Price, txt = CityShop_ItemInfo11_Text, mtxt = CityShop_ItemInfo11_GB,
										name=CityShop_ItemInfo11_Name, jiantext = CityShop_ItemInfo11_JianText, jianprice = CityShop_ItemInfo11_JianPrice, jianbk=CityShop_ItemInfo11_Jian},
										{act = CityShop_Item12, money = CityShop_ItemInfo12_Price, txt = CityShop_ItemInfo12_Text, mtxt = CityShop_ItemInfo12_GB,
										name=CityShop_ItemInfo12_Name, jiantext = CityShop_ItemInfo12_JianText, jianprice = CityShop_ItemInfo12_JianPrice, jianbk=CityShop_ItemInfo12_Jian},

										prv = CityShop_UpPage,
										nxt	=	CityShop_DownPage,
										ptxt = CityShop_CurrentlyPage,
									};
end

function City_Shop_Clear()
	City_Shop_Act_Clear();
	g_CurPage = 1;
	g_TotalPage = 0;
end

function City_Shop_Act_Clear()
	local i;
	for i = 1, table.getn(g_MembersCtl) do
		g_MembersCtl[i].act:SetActionItem(-1);
		g_MembersCtl[i].act:SetPushed(0);
		g_MembersCtl[i].act:Bright();
		g_MembersCtl[i].act:Hide();

		g_MembersCtl[i].money:SetProperty("MoneyNumber", "0");
		g_MembersCtl[i].money:Hide();

		g_MembersCtl[i].txt:SetText("");
		g_MembersCtl[i].txt:Hide();
		
		g_MembersCtl[i].name:SetText("");
		g_MembersCtl[i].name:Hide()

		g_MembersCtl[i].mtxt:SetText("");
		g_MembersCtl[i].mtxt:Hide();
		
		g_MembersCtl[i].jianbk:Hide()
		g_MembersCtl[i].jiantext:SetText("");
		g_MembersCtl[i].jiantext:Hide();
		g_MembersCtl[i].jianprice:SetProperty("MoneyNumber", "0");
		g_MembersCtl[i].jianprice:Hide();
	end
	CityShop_SaleBack2_Text:SetText("");
	CityShop_SaleBack2_Text:Hide();
	CityShop_SaleBack2_Price:SetProperty("MoneyNumber", "0");
	CityShop_SaleBack2_Price:Hide();
end

function City_Shop_UpPage()
	City_Shop_NextPage(-1);
end

function City_Shop_DownPage()
	City_Shop_NextPage(1);
end

function City_Shop_NextPage(dir)
	if(g_CurPage == 1 and dir < 0) then return; end --已经是第一页
	local newPage = g_CurPage+dir;
	local newAction = (City:EnumCityShop((newPage-1)*12+1));
	if(newAction:GetID() == 0 and g_CurPage > 1) then return; end
	g_CurPage = newPage;
	City_Shop_Update_CurPage();
end

function City_Shop_Update_CurPage()
	City_Shop_Act_Clear();
	local i = 1;
	while i <= 12 do
		City_Shop_Act_Set(i);

		i = i + 1;
	end
	City_Shop_SaleBack2Set()
	City_Shop_BtnSet();
end

function City_Shop_Act_Set(i)
	local theAction, isSoldOut = City:EnumCityShop((g_CurPage-1)*12+(tonumber(i)));
		if theAction:GetID() ~= 0 then
			--设置ActionItem
			g_MembersCtl[i].act:SetActionItem(theAction:GetID());

			--设置是否已经售完
			--if(isSoldOut < 0) then
			--	g_MembersCtl[i].act:Bright();
			--elseif(isSoldOut > 0) then
			--	g_MembersCtl[i].act:Gloom();
			--end

			g_MembersCtl[i].act:Show();

		if(City_Shop_Is_TicketPrice_Idx(City:GetCityShopInfo(0, "bid")) > 0) then
			--设置商票金钱
			local money = City:GetCityShopInfo((g_CurPage-1)*12+(tonumber(i)), "tprice");
			g_MembersCtl[i].money:SetProperty("MoneyNumber", tostring(money));
			g_MembersCtl[i].money:Show();

			g_MembersCtl[i].txt:SetText("商票金钱");
			g_MembersCtl[i].txt:Show();
			
			local money2 = City:GetCityShopInfo((g_CurPage-1)*12+(tonumber(i)), "price");
			
--			g_MembersCtl[i].jianbk:Show()
--			g_MembersCtl[i].jiantext:SetText("#{CKPS_260119_41}");
--			g_MembersCtl[i].jiantext:Show();
--			g_MembersCtl[i].jianprice:SetProperty("MoneyNumber", tostring(money2));
--			g_MembersCtl[i].jianprice:Show();
		else
			--设置金钱
			local money = City:GetCityShopInfo((g_CurPage-1)*12+(tonumber(i)), "price");
			g_MembersCtl[i].money:SetProperty("MoneyNumber", tostring(money));
			g_MembersCtl[i].money:Show();
			--设置帮贡
			local contribute = City:GetCityShopInfo((g_CurPage-1)*12+(tonumber(i)), "contribute");
			g_MembersCtl[i].txt:SetText("帮贡："..tostring(contribute));
			g_MembersCtl[i].txt:Show();
			
			g_MembersCtl[i].name:SetText(theAction:GetName())
			g_MembersCtl[i].name:Show();
		end
		else
			g_MembersCtl[i].act:SetActionItem(-1);
		end
	end

function City_Shop_BtnSet()
	local preAction = (City:EnumCityShop((g_CurPage-1)*12));
	local nextAction = (City:EnumCityShop((g_CurPage-1)*12+12+1));

	if(preAction:GetID() ~= 0)then
		g_MembersCtl.prv:Enable();
	else
		g_MembersCtl.prv:Disable();
	end

	if(nextAction:GetID() ~= 0)then
		g_MembersCtl.nxt:Enable();
	else
		g_MembersCtl.nxt:Disable();
	end

	if g_TotalPage <= 0 then
		g_MembersCtl.ptxt:SetText("0/0");
	else
		g_MembersCtl.ptxt:SetText(tostring(g_CurPage).."/"..tostring(g_TotalPage));
	end
end

function City_Shop_Update()
	local total = City:GetCityShopInfo(0, "total");
	if(math.mod(total,12) > 0) then
		g_TotalPage = math.floor(total/12) + 1;
	else
		g_TotalPage = math.floor(total/12);
	end

	City_Shop_NextPage(0);
end

function City_Shop_Act_Clicked(idx)
	City:DoCityShop((g_CurPage-1)*12+(tonumber(idx)));
end

function City_Shop_Is_TicketPrice_Idx(bid)
	--目前消耗商票金钱的建筑物类型，对应enum BUILDING_TYPE
	local tTicket = {3};
	local i = 1;
	while i <= table.getn(tTicket) do
		if(tTicket[i] == bid) then return 1; end
		i = i + 1;
	end
	return -1;
end
function City_Shop_SaleBack2Set()
	if(City_Shop_Is_TicketPrice_Idx(City:GetCityShopInfo(0, "bid")) > 0) then
		local nPos = PlayerPackage:GetBagPosByItemIndex(40002000)
		if nPos > 0 then
			local money = PlayerPackage:Lua_GetItemAttachParam(nPos, 0, 2)
			CityShop_SaleBack2_Text:Show()
			CityShop_SaleBack2_Text:SetText("#{CKPS_260119_42}")
			CityShop_SaleBack2_Price:Show()
			CityShop_SaleBack2_Price:SetProperty("MoneyNumber", tostring(money));
		end
	end
end