
local g_CurrentPage = -1;
local g_DefaultPage = -1;

local PAGE_ITEM  =0;
local PAGE_PET   =1;

-- 物品相关
local STALL_BUTTONS_NUM = 20;
local STALL_BUTTON = {};

local g_nCurSelectItemID = -1;	--物品ID
local g_nCurSelectItem = -1;		--物品位置

--珍兽相关
local MAX_PET_NUM  = 20;		--最大上架的珍兽数量
local g_nSelectPet = -1;		--当前选中的Pet
local g_nPetID = {};				--珍兽ID表

-- 界面的默认相对位置
local g_StallSale_Frame_UnifiedXPosition;
local g_StallSale_Frame_UnifiedYPosition;

--===============================================
-- OnLoad()
--===============================================
function StallSale_PreLoad()

	this:RegisterEvent("OPEN_STALL_SALE",true);
	this:RegisterEvent("UPDATE_STALL_SALE",false);
	this:RegisterEvent("STALL_SALE_SELECT",true);
	this:RegisterEvent("OPEN_STALL_BUY",false);
	this:RegisterEvent("UPDATE_STALL_ITEM_PRICE",true);
	this:RegisterEvent("UPDATE_STALL_NAME",true);
	this:RegisterEvent("CLOSE_STALL_SALE",false);

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function StallSale_OnLoad()
	STALL_BUTTON[1] 	= StallSale_Item1;
	STALL_BUTTON[2] 	= StallSale_Item2;
	STALL_BUTTON[3] 	= StallSale_Item3;
	STALL_BUTTON[4] 	= StallSale_Item4;
	STALL_BUTTON[5] 	= StallSale_Item5;
	STALL_BUTTON[6] 	= StallSale_Item6;
	STALL_BUTTON[7] 	= StallSale_Item7;
	STALL_BUTTON[8] 	= StallSale_Item8;
	STALL_BUTTON[9] 	= StallSale_Item9;
	STALL_BUTTON[10] 	= StallSale_Item10;
	STALL_BUTTON[11] 	= StallSale_Item11;
	STALL_BUTTON[12] 	= StallSale_Item12;
	STALL_BUTTON[13] 	= StallSale_Item13;
	STALL_BUTTON[14]	= StallSale_Item14;
	STALL_BUTTON[15]	= StallSale_Item15;
	STALL_BUTTON[16]	= StallSale_Item16;
	STALL_BUTTON[17]	= StallSale_Item17;
	STALL_BUTTON[18]	= StallSale_Item18;
	STALL_BUTTON[19]	= StallSale_Item19;
	STALL_BUTTON[20]	= StallSale_Item20;

	--AxTrace(0,0,"StallSale_OnLoad begin\n");
	for i=0, MAX_PET_NUM  do
		g_nPetID[i] = -1;
	end

	--暂时屏蔽拖动功能
	for i=1 ,STALL_BUTTONS_NUM     do
		STALL_BUTTON[i]:SetProperty("DraggingEnabled","False");
	end

	-- 保存界面的默认相对位置
	g_StallSale_Frame_UnifiedXPosition	= StallSale_Frame : GetProperty("UnifiedXPosition");
	g_StallSale_Frame_UnifiedYPosition	= StallSale_Frame : GetProperty("UnifiedYPosition");

end

--===============================================
-- OnEvent()
--===============================================
function StallSale_StallInfo(event)
	--填写摊位名字
	StallSale_Name:SetText(StallSale:GetStallName());
	--填写名字
	StallSale_Master_Text:SetText("摊主:" .. Player:GetName());
	--填写自己的GUID
	local ownerGuidText = ConvertGuidToShow( StallSale:GetGuid() )
	StallSale_ID_Text:SetText( "ID:" .. ownerGuidText);
	--清除价格
	StallSale_TargetPrice_Money:SetProperty("MoneyNumber","");
	StallSale_TargetUnitPrice_Money:SetProperty("MoneyNumber","");
	--填写税率
	StallSale_Tax_Text:SetText(tostring(StallSale:GetTradeTax()).."%");
end

--===============================================
-- OnEvent()
--===============================================
function StallSale_OnEvent(event)

	--PushDebugMessage ("StallSale : "..event)

	if(event == "OPEN_STALL_SALE") then
		StallSale_OnStallSaleOpen();

	elseif(event == "UPDATE_STALL_SALE")  then
		g_DefaultPage = StallSale_GetDefalutPage();
		StallSale_StallInfo();
		StallSale_ChangePage(g_CurrentPage);
		g_nCurSelectItemID = -1;
		g_nCurSelectItem = -1;
		--离线摆摊状态
		local nStallOfflineState = StallSale:GetStallOfflineState();
		if(nStallOfflineState ~= nil and nStallOfflineState > 0) then
			StallSale_Offline_Page:SetCheck(1)
		else
			StallSale_Offline_Page:SetCheck(0)
		end

	elseif(event == "UPDATE_STALL_ITEM_PRICE")   then
		--获得修改第几个，然后修改价格
		StallSale_UpdateFrame();
		StallSale_ViewSelectAndPrice();

	elseif(event == "STALL_SALE_SELECT") then
		StallSale_SelectUpdate();
		--将InputMoney需要的数据保存到全局数据区
		SetGlobalInteger(g_nCurSelectItemID,"StallSale_ItemID");
		SetGlobalInteger(g_nCurSelectItem,"StallSale_Item");

	elseif(event == "OPEN_STALL_BUY") then
		--实现买卖界面的互斥
		this:Hide();

	elseif(event == "UPDATE_STALL_NAME")  then
		--更改商店名字
		StallSale_Name:SetText(arg0);
		StallSale:ModifStallName(StallSale_Name:GetText());

	elseif(event == "CLOSE_STALL_SALE")  then
		this:Hide();
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		StallSale_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		StallSale_Frame_On_ResetPos()
	end

end

function StallSale_GetDefalutPage()

	return StallSale:GetDefaultPage();

end

--===============================================
-- 初始化摆摊界面
--===============================================
function StallSale_OnStallSaleOpen()


	StallSale_TargetPrice_Frame1:Hide();
	StallSale_TargetPrice_Frame2:Hide();
	StallSale_TargetUnitPrice_Frame1:Hide();
	StallSale_TargetUnitPrice_Frame2:Hide();

	--清空选择
	StallSale_ClearSelect();

	--打开留言版
	StallSale:OpenMessageSale();

	local nServerType = StallSale:GetStallServerType()
	if 1 ~= nServerType then
		--打开珍兽列表
		StallSale:OpenPetList();
	end

	g_DefaultPage = StallSale_GetDefalutPage();
	g_CurrentPage = g_DefaultPage;
	if 1 == nServerType then
		g_CurrentPage = PAGE_ITEM
	end
	if(g_CurrentPage == PAGE_ITEM)  then
		StallSale_Check_Item:SetCheck(1);
		StallSale_Check_Pet:SetCheck(0);
	else
		StallSale_Check_Item:SetCheck(0);
		StallSale_Check_Pet:SetCheck(1);
	end

	--是否可以看到离线摆摊设置按钮
	local nCanView = StallSale:GetCanSOCoin()
	if nCanView and nCanView == 1 then
	  StallSale_Offline_Text:Show()
	  StallSale_Offline_Page:Show()
	else
		StallSale_Offline_Text:Hide()
	  StallSale_Offline_Page:Hide()
	end

	--离线摆摊状态
	local nStallOfflineState = StallSale:GetStallOfflineState();
	if(nStallOfflineState ~= nil and nStallOfflineState > 0) then
		StallSale_Offline_Page:SetCheck(1)
	else
		StallSale_Offline_Page:SetCheck(0)
	end

	StallSale_StallInfo();

	-- 填入内容
	StallSale_ChangePage(g_CurrentPage);

	local nCoinType = StallSale:GetStallType()

	--tooltips
	local nSelfLevel = Player:GetLevel()
	local nNeedAcPoint = StallSale:GetNeedAcPointByLevel(nCoinType, nSelfLevel)
	StallSale_Offline_Text:SetToolTip(ScriptGlobal_Format("#{LXBT_111226_49}", nSelfLevel, nNeedAcPoint))

	-- 如果是金币摆摊
	if (nCoinType == 0) then
		StallSale_TargetPrice_Frame1:Show();
		StallSale_TargetUnitPrice_Frame1:Show();
		StallSale_Check_Pet:Show()
		StallSale_Default_Page:Show()
		StallSale_SetPage_Text:Show()
		--是否显示离线摆摊按钮
		local bShow = StallSale:GetCanSOCoin()
		if(bShow ~= nil and bShow == 1) then
			StallSale_Offline_Page:Show()
			StallSale_Offline_Text:Show()
		else
			StallSale_Offline_Page:Hide()
			StallSale_Offline_Text:Hide()
		end
		if 1 == nServerType then
			StallSale_Check_Pet:Hide()
		end

	-- 如果是元宝摆摊
	elseif( nCoinType == 1 ) then
		StallSale_TargetPrice_Frame2:Show();
		StallSale_Check_Pet:Show()
		StallSale_Default_Page:Show();
		StallSale_SetPage_Text:Show();
		StallSale_TargetPrice_Yuanbao:SetText("#cff99000 #W元宝")
		--是否显示离线摆摊按钮
		local bShow = StallSale:GetCanSOYuanBao()
		if(bShow ~= nil and bShow == 1) then
			StallSale_Offline_Page:Show()
			StallSale_Offline_Text:Show()
		else
			StallSale_Offline_Page:Hide()
			StallSale_Offline_Text:Hide()
		end
		if 1 == nServerType then
			StallSale_Check_Pet:Hide()
		end
	else
		PushDebugMessage("摆摊类型错误");
	end


	this:Show();

end

--===============================================
-- 选中物品
--===============================================
function StallSale_SelectUpdate()

	local theAction = EnumAction(arg0+0, "st_self");

	g_nCurSelectItemID = theAction:GetID();
	g_nCurSelectItem = tonumber(arg0);

	StallSale_ViewSelectAndPrice();

end

--===============================================
-- 显示选中的物品（珍兽），和他们的标价
--===============================================
function StallSale_ViewSelectAndPrice()

	local nMoney = 0;
	local nGoldCoin;
	local nSilverCoin;
	local nCopperCoin;
	local nCount = 1;

	if (g_CurrentPage == PAGE_ITEM) then
		for i=1, STALL_BUTTONS_NUM do
			if(i==g_nCurSelectItem+1) then
				STALL_BUTTON[i]:SetPushed(1);
			else
				STALL_BUTTON[i]:SetPushed(0);
			end
		end
		nMoney,nGoldCoin,nSilverCoin,nCopperCoin = StallSale:GetPrice("item",g_nCurSelectItem);
		nCount = StallSale:GetItemNum(g_nCurSelectItemID)

	elseif(g_CurrentPage == PAGE_PET)  then
		if(g_nSelectPet ~= -1)   then
			StallSale_PetList:SetItemSelect(g_nSelectPet);
			nMoney,nGoldCoin,nSilverCoin,nCopperCoin = StallSale:GetPrice("pet",g_nPetID[g_nSelectPet]);
		end
	end

	local nCoinType = StallSale:GetStallType()
	if (nCoinType == 0) then
		StallSale_TargetPrice_Money:SetProperty("MoneyNumber",tostring(nMoney));

		--检查nCount值，以免除0
		if nCount == nil or nCount <= 0 then
			nCount = 1
		end
		StallSale_TargetUnitPrice_Money:SetProperty("MoneyNumber", tostring(Division(nMoney, nCount)))

	elseif( nCoinType == 1 ) then
		StallSale_SetTargetPrice(1, nMoney)

	else
		PushDebugMessage("摆摊类型错误");
	end

end


--===============================================
-- 选中珍兽
--===============================================
function StallSale_PetList_Selected()

	--需要显示价格
	g_nSelectPet = StallSale_PetList:GetFirstSelectItem();

	if( g_nSelectPet == -1 )  then
		return;
	end

	StallSale:SetSelectPet(g_nPetID[g_nSelectPet]);

	StallSale_ViewSelectAndPrice();

end

--===============================================
-- StallSale_UpdateFrame
--===============================================
function StallSale_UpdateFrame()

	if(g_CurrentPage == PAGE_ITEM)     then
		UpdateItem();
		if( g_DefaultPage == g_CurrentPage  )   then
			StallSale_Default_Page:SetCheck(1);
		else
			StallSale_Default_Page:SetCheck(0);
		end

	elseif (g_CurrentPage == PAGE_PET) then
		if( g_DefaultPage == g_CurrentPage  )   then
			StallSale_Default_Page:SetCheck(1);
		else
			StallSale_Default_Page:SetCheck(0);
		end
		UpdatePet();

	end

	StallSale_SetTabColor();
end

--===============================================
-- 重新命名摊位名称
--===============================================
function StallSaleRename_Clicked()

	StallSale:ModifStallName(StallSale_Name:GetText());

end

--===============================================
-- 重新指定物品的价格（打开价格输入框）
--===============================================
function StallSaleReprice_Clicked()

	if (g_CurrentPage == PAGE_ITEM) then
		-- 需要先判定是否有物品
		if(g_nCurSelectItemID~=-1) then
			if(g_nCurSelectItem~=-1) then
				StallSale:ModifItemPrice("item");
			end
		end

	elseif(g_CurrentPage == PAGE_PET)  then
		if(g_nSelectPet ~= -1) then
			StallSale:ModifItemPrice("pet",g_nPetID[g_nSelectPet]);
		end
	end

end

--===============================================
-- 让一个物品(珍兽)下架
--===============================================
function StallSaleDelete_Clicked()

	if (g_CurrentPage == PAGE_ITEM) then
		-- 需要先判定是否有物品
		if(g_nCurSelectItemID~=-1) then
			if(g_nCurSelectItem~=-1) then
				StallSale:DeleteItem("item",g_nCurSelectItemID);
			end
		end

	elseif(g_CurrentPage == PAGE_PET)  then
		if(g_nSelectPet ~= -1) then
			StallSale:DeleteItem("pet",g_nPetID[g_nSelectPet]);
		end
	end

end

--===============================================
-- 收摊走人
--===============================================
function StallSalePutUpTheShutters_Clicked()

	StallSale:ConfirmRemoveStall();

end

--===============================================
-- 打开信息界面
--===============================================
function StallSale_Message_Clicked()

	if (IsWindowShow("StallMessage")) then
		CloseWindow("StallMessage", true);
		return
	end
	StallSale:OpenMessageSale();

end

--===============================================
-- 关闭按钮
--===============================================
function StallSale_Close_Clicked()

	this:Hide();
	StallSale:CloseStallMessage();
	StallSale_Name:SetProperty("DefaultEditBox", "False");
	CloseMessageBoxCommon();
	CloseInputYuanbao();

end

--===============================================
-- 显示物品
--===============================================
function UpdateItem()

	local nItemNum = GetActionNum("st_self");
	for i=0, STALL_BUTTONS_NUM - 1  do
		local theAction = EnumAction(i, "st_self");
		if theAction:GetID() ~= 0 then
			STALL_BUTTON[i+1]:SetActionItem(theAction:GetID());
		else
			STALL_BUTTON[i+1]:SetActionItem(-1);
		end
	end

end

--===============================================
-- 显示珍兽
--===============================================
function UpdatePet()
	StallSale_PetList:ClearListBox();

	local nIndex = 0;
	for i=1 ,MAX_PET_NUM  do
		local szPetName, szType = StallSale:EnumPet(i-1);
		if(szPetName ~= "") then
			StallSale_PetList:AddItem("#cffff00"..szType .. "#W(" .. szPetName .. ")" , nIndex);
			g_nPetID[nIndex] = i-1;
			nIndex = nIndex + 1;
		end

	end

end

--===============================================
-- 换页
--===============================================
function StallSale_ChangeTabIndex(nIndex)

	if(g_CurrentPage == nIndex)    then
		return;
	else
		StallSale_ChangePage(nIndex)
		StallSale_TargetPrice_Money:SetProperty("MoneyNumber","0");
		StallSale_TargetUnitPrice_Money:SetProperty("MoneyNumber","0");
		StallSale_TargetPrice_Yuanbao:SetText("#cff99000 #W元宝")
	end

end

--===============================================
-- 换页刷新
--===============================================
function StallSale_ChangePage(nPage)

	StallSale_ClearSelect();

	g_CurrentPage = nPage;
	if(g_CurrentPage == PAGE_ITEM) then
		StallSale_PetList:Hide();
		StallSale_Item_Set:Show();
		for i=1, STALL_BUTTONS_NUM   do
			STALL_BUTTON[i]:Show();
		end
		StallSale_ViewPets:Hide();
	else
		StallSale_PetList:Show();
		StallSale_Item_Set:Hide();
		for i=1, STALL_BUTTONS_NUM   do
			STALL_BUTTON[i]:Hide();
		end
		StallSale_ViewPets:Show();
	end
	StallSale_UpdateFrame();

end

--===============================================
-- 选中缺省页面
--===============================================
function StallSale_Default_Page_Clicked()

	local nCurrent = StallSale_Default_Page:GetCheck();
	if( g_CurrentPage == PAGE_ITEM )  then
		if( nCurrent == 1  )   then
			g_DefaultPage = PAGE_ITEM;
		else
			g_DefaultPage = PAGE_PET;
		end
	else
		if( nCurrent == 1  )   then
			g_DefaultPage = PAGE_PET;
		else
			g_DefaultPage = PAGE_ITEM;
		end

	end

	StallSale:SetDefaultPage(g_DefaultPage);

end

--设置离线摆摊
function StallSale_SetOffiline_Clicked()
	local IsSet = StallSale:GetStallOfflineState();
	if IsSet == nil then
		return
	end
	if IsSet == 0 then --想设置离线摆摊
		StallSale:SetStallOfflineState(1);
	else--想取消离线摆摊
		StallSale:SetStallOfflineState(0);
	end
end

--===============================================
-- 右键选中
--===============================================
function StallSale_PetList_RClick()

	g_nSelectPet = StallSale_PetList:GetFirstSelectItem();
	if(g_nSelectPet == -1)then
		PushDebugMessage("请选择一只珍兽后点击查看")
		return;
	end

	--显示珍兽
	StallSale:ViewPetDesc("self",g_nPetID[g_nSelectPet]);

end

--===============================================
-- 设置Tab颜色
--===============================================
function StallSale_SetTabColor()

	local selColor = "#e010101#Y";
	local noselColor = "#e010101";

	if( PAGE_ITEM == g_CurrentPage ) then
		StallSale_Check_Item:SetText(selColor .. "物品");
		StallSale_Check_Pet:SetText(noselColor .. "珍兽");
	else
		StallSale_Check_Item:SetText(noselColor .. "物品");
		StallSale_Check_Pet:SetText(selColor .. "珍兽");
	end

end

--===============================================
-- 恢复选中状态（清空选中）
--===============================================
function StallSale_ClearSelect()
	g_nSelectPet = -1;				--当前选中的Pet
	g_nCurSelectItemID = -1;	--物品ID
	g_nCurSelectItem = -1;		--物品位置
end


function StallSale_SetTargetPrice(nCoinType, nMoney)

	local nMoneyEnd = 0;
	local nMoneyBegin = 0
	local nMoneyMid = 0;
	local strMoney = "";

	-- 如果是金币摆摊
	if (nCoinType == 0) then
		StallSale_TargetPrice_Money:SetProperty("MoneyNumber",tostring(nMoney));
			-- 元宝摆摊
	elseif( nCoinType == 1 ) then
		--[[if (nMoney <100 ) then
			strMoney = string.format("#cff9900%s", nMoney);
		elseif (nMoney < 10000) then
			nMoneyEnd = nMoney - math.floor(nMoney/100)*100;
			nMoneyMid = math.floor(nMoney/100) - math.floor((math.floor(nMoney/100))/100)*100;
			local strEnd = "00";
			if (nMoneyEnd < 10) then
				strEnd = string.format("0%d", nMoneyEnd);
			else
				strEnd = tostring(nMoneyEnd);
			end
			strMoney = string.format("#W%d#cff9900%s", nMoneyMid, strEnd);
		else
			nMoneyEnd = nMoney - math.floor(nMoney/100)*100;
			nMoneyMid = math.floor(nMoney/100) - math.floor((math.floor(nMoney/100))/100)*100;
			nMoneyBegin = math.floor(nMoney/10000);
			local strEnd = "00";
			if (nMoneyEnd < 10) then
				strEnd = string.format("0%d", nMoneyEnd);
			else
				strEnd = tostring(nMoneyEnd);
			end
			local strMid = "00";
			if (nMoneyMid < 10) then
				strMid = string.format("0%d", nMoneyMid);
			else
				strMid = tostring(nMoneyMid);
			end
			strMoney = string.format("#Y%d#W%s#cff9900%s", nMoneyBegin, strMid, strEnd);
		end
		--]]
		nMoneyBegin = math.floor(nMoney/10000)
		nMoneyEnd = nMoney - math.floor(nMoney/10)*10
		nMoneyMid = (nMoney - nMoneyBegin*10000 - nMoneyEnd)/10
		if nMoneyBegin~=0 then
			strMoney = string.format("#Y%d#cff9900%03d#W%d", nMoneyBegin, nMoneyMid, nMoneyEnd);
		elseif nMoneyMid~=0 then
			strMoney = string.format("#cff9900%d#W%d", nMoneyMid, nMoneyEnd)
		else
		    strMoney = string.format("#W%d", nMoneyEnd)
		end

		StallSale_TargetPrice_Yuanbao:SetText("#Y"..strMoney.." #W元宝");
	else
		PushDebugMessage("摆摊类型错误");
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function StallSale_Frame_On_ResetPos()

	StallSale_Frame : SetProperty("UnifiedXPosition", g_StallSale_Frame_UnifiedXPosition);
	StallSale_Frame : SetProperty("UnifiedYPosition", g_StallSale_Frame_UnifiedYPosition);

end
