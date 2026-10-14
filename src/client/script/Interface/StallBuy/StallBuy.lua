--购买物品和珍兽的界面
local STALL_BUTTONS_NUM = 20;
local STALL_BUTTON = {};

-- 下列两个值需要保持同步（物品ID、物品位置）
local g_nCurSelectItemID = -1;
local g_nCurSelectItem = -1;

local g_CurrentPage = -1;
local g_DefaultPage = -1;

local PAGE_ITEM  =0;
local PAGE_PET   =1;

local objCared = -1;
local MAX_OBJ_DISTANCE = 6.0;

local g_nCutSelectPet = -1;

local g_nPetID = {};				--珍兽ID表

-- 界面的默认相对位置
local g_StallBuy_Frame_UnifiedXPosition;
local g_StallBuy_Frame_UnifiedYPosition;

--===============================================
-- OnLoad()
--===============================================
function StallBuy_PreLoad()

	this:RegisterEvent("OPEN_STALL_BUY",true);
	this:RegisterEvent("CLOSE_STALL_BUY",false);
	this:RegisterEvent("STALL_BUY_SELECT",false);
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("UPDATE_STALL_BUY",false);
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("UPDATE_YUANBAO",false);
	this:RegisterEvent("UPDATE_STALL_BUY_PET",false)

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function StallBuy_OnLoad()

	STALL_BUTTON[1] 	= StallBuy_Item1;
	STALL_BUTTON[2] 	= StallBuy_Item2;
	STALL_BUTTON[3] 	= StallBuy_Item3;
	STALL_BUTTON[4] 	= StallBuy_Item4;
	STALL_BUTTON[5] 	= StallBuy_Item5;
	STALL_BUTTON[6] 	= StallBuy_Item6;
	STALL_BUTTON[7] 	= StallBuy_Item7;
	STALL_BUTTON[8] 	= StallBuy_Item8;
	STALL_BUTTON[9] 	= StallBuy_Item9;
	STALL_BUTTON[10] 	= StallBuy_Item10;
	STALL_BUTTON[11] 	= StallBuy_Item11;
	STALL_BUTTON[12] 	= StallBuy_Item12;
	STALL_BUTTON[13] 	= StallBuy_Item13;
	STALL_BUTTON[14]	= StallBuy_Item14;
	STALL_BUTTON[15]	= StallBuy_Item15;
	STALL_BUTTON[16]	= StallBuy_Item16;
	STALL_BUTTON[17]	= StallBuy_Item17;
	STALL_BUTTON[18]	= StallBuy_Item18;
	STALL_BUTTON[19]	= StallBuy_Item19;
	STALL_BUTTON[20]	= StallBuy_Item20;

	for i=0, 20  do
		g_nPetID[i] = -1;
	end

	--暂时屏蔽拖动功能
	for i=1 ,STALL_BUTTONS_NUM     do
		STALL_BUTTON[i]:SetProperty("DraggingEnabled","False");
	end

	-- 保存界面的默认相对位置
	g_StallBuy_Frame_UnifiedXPosition	= StallBuy_Frame : GetProperty("UnifiedXPosition");
	g_StallBuy_Frame_UnifiedYPosition	= StallBuy_Frame : GetProperty("UnifiedYPosition");

end

--===============================================
-- OnEvent()
--===============================================
function StallBuy_OnEvent(event)

	--PushDebugMessage ("StallBuy : "..event)

	if(event == "OPEN_STALL_BUY") then
		StallBuy_OnStallBuyOpen()

	elseif(event == "UPDATE_STALL_BUY") then
		g_nCurSelectItemID = -1;
		g_nCurSelectItem = -1;
		--StallBuy_Buy:Disable();
		--清空标价
		StallBuy_TargetPrice_Money:SetProperty("MoneyNumber","");
		StallBuy_TargetUnitPrice_Money:SetProperty("MoneyNumber","");
		--清空元宝标价
		StallBuy_TargetPrice_Yuanbao:SetText("#cff99000 #W元宝")
		-- 填写摊主的名字
		StallBuy_Master_Text:SetText("摊主:" .. StallBuy:GetStallerName());
		-- 填写摊主的GUID
		local ownerGuidText = ConvertGuidToShow( StallBuy:GetGuid() )
		StallBuy_ID_Text:SetText("ID:" .. ownerGuidText);
		--打开需要的页面
		StallBuy_ChangePage(g_CurrentPage);
	elseif event == "UPDATE_STALL_BUY_PET" then	--补齐剩余的珍兽而已，其他信息不用改变
		if g_CurrentPage == PAGE_PET then
			StallBuy_UpdatePet()
		end
		StallBuy_SetTabColor();

	elseif(event == "STALL_BUY_SELECT") then
		StallBuy_TargetPrice_Money:SetProperty("MoneyNumber","");
		StallBuy_TargetUnitPrice_Money:SetProperty("MoneyNumber","");
		StallBuy_SelectUpdate();

	elseif(event == "CLOSE_STALL_BUY") then
		--取消关心
		if objCared ~= nil then
			this:CareObject(objCared, 0, "StallBuy");
		end
		this:Hide();

	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			StallBuy:CloseStallMessage();
			this:Hide();
			--取消关心
			if objCared ~= nil then
				this:CareObject(objCared, 0, "StallBuy");
			end
		end

	elseif (event == "MONEY_CHANGE_EX") then
		StallBuy_modifymoney();

	elseif (event == "UPDATE_YUANBAO") then
		local nCoinType = StallBuy:GetStallType()
		if(nCoinType == 1) then
			local nYuanbao = Player:GetData("YUANBAO");
			if(nYuanbao ~= nil) then
				StallBuy_Cash_Yuanbao:SetText("#Y"..nYuanbao.." 元宝")
			end
		end

	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		StallBuy_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		StallBuy_Frame_On_ResetPos()
	end

end

--===============================================
-- SelectUpdate
--===============================================
function StallBuy_OnStallBuyOpen()
	this:Show();

  --打开留言版
	StallBuy:OpenMessageFrame()

	--关心交易对象
	objCared = tonumber(arg0)
	if objCared ~= nil then
		this:CareObject(objCared, 1, "StallBuy")
	end

	local nServerType = StallBuy:GetServerType()
	--从数据池中获得缺省页面
	--g_DefaultPage = StallBuy:GetDefaultPage();
	g_DefaultPage = StallBuy_GetDefalutPage();

	g_CurrentPage = g_DefaultPage;
	if 1 == nServerType then
		g_CurrentPage = PAGE_ITEM
	end

	if(g_CurrentPage == PAGE_ITEM)  then
		StallBuy_Item:SetCheck(1);
		StallBuy_Pet:SetCheck(0);
	else
		StallBuy_Item:SetCheck(0);
		StallBuy_Pet:SetCheck(1);
	end

	g_nCurSelectItemID = -1;
	g_nCurSelectItem = -1;

	--清空标价
	StallBuy_TargetPrice_Money:SetProperty("MoneyNumber","");
	StallBuy_TargetUnitPrice_Money:SetProperty("MoneyNumber","");

	--清空元宝标价
	StallBuy_TargetPrice_Yuanbao:SetText("#cff99000 #W元宝")
	-- 填写摊主的名字
	StallBuy_Master_Text:SetText("摊主:" .. StallBuy:GetStallerName());
	-- 填写摊主的GUID
	local ownerGuid = StallBuy:GetGuid()
	local ownerGuidText = ConvertGuidToShow(ownerGuid)
	StallBuy_ID_Text:SetText("ID:" .. ownerGuidText);

	--打开需要的页面
	StallBuy_ChangePage(g_CurrentPage);


	StallBuy_Cash_Money:Hide();
	StallBuy_Cash_Yuanbao:Hide();
	StallBuy_TargetPrice_Yuanbao:Hide();
	StallBuy_TargetPrice_Money:Hide();
	StallBuy_TargetUnitPrice:Hide()

	local nCoinType = StallBuy:GetStallType()

	-- 如果是金币摆摊
	if (nCoinType == 0) then
		StallBuy_Cash_Money:Show();
		StallBuy_Cash_Yuanbao:Hide();
		StallBuy_TargetUnitPrice:Show()
		StallBuy_TargetPrice_Money:Show();
		StallBuy_Pet:Show();
		StallBuy_ViewPets:Hide();
		StallBuy_Cash:SetText("#{INTERFACE_XML_761}");
		if 1 == nServerType then
			StallBuy_Pet:Hide()
		end

	-- 元宝摆摊
	elseif( nCoinType == 1 ) then
		StallBuy_Cash_Yuanbao:Show();
		StallBuy_Cash_Money:Hide();
		StallBuy_TargetPrice_Yuanbao:Show();
		StallBuy_Pet:Show();
		StallBuy_Cash:SetText("#{YBBT_81021_06}");
		if 1 == nServerType then
			StallBuy_Pet:Hide()
		end
	else
		PushDebugMessage("摆摊类型错误");
	end
end

--===============================================
-- 获取默认的页面
--===============================================
function StallBuy_GetDefalutPage()

	--local nCoinType = StallBuy:GetStallType()

	--if( nCoinType == 1 ) then
	--	return  PAGE_ITEM;
	--end

	return StallBuy:GetDefaultPage();

end

--===============================================
-- SelectUpdate
--===============================================
function StallBuy_SelectUpdate()

	local theAction = EnumAction(arg0+0, "st_other");

	g_nCurSelectItemID = theAction:GetID();
	g_nCurSelectItem = 0+arg0;

	for i=1, STALL_BUTTONS_NUM do
		if(i==arg0+1) then
			STALL_BUTTON[i]:SetPushed(1);
			--StallBuy_Buy:Enable();

		else
			STALL_BUTTON[i]:SetPushed(0);
		end
	end

	--关闭先前弹出是否购买的提示框
	CloseMessageBoxCommon()

	--显示标价
	local nMoney;
	local nGoldCoin;
	local nSilverCoin;
	local nCopperCoin;

	nMoney = StallBuy:GetPrice("item",arg0+0);

	local nCoinType = StallBuy:GetStallType()

	-- 如果是金币摆摊
	if (nCoinType == 0) then
		StallBuy_SetItemOrPetPrice(0, nMoney);
		--StallBuy_TargetPrice_Money:SetProperty("MoneyNumber",tostring(nMoney));

	-- 元宝摆摊
	elseif( nCoinType == 1 ) then
		StallBuy_SetItemOrPetPrice(1, nMoney);
		--StallBuy_TargetPrice_Yuanbao:SetText("#Y"..tostring(nMoney).." 元宝");
	else
		PushDebugMessage("摆摊类型错误");
	end
end


--===============================================
-- StallBuy_UpdateFrame
--===============================================
function StallBuy_UpdateFrame()

	StallBuy_ClearSelect();

	--填写自己的金钱数
	local nMoney;
	local nGoldCoin;
	local nSilverCoin;
	local nCopperCoin;

	nMoney,nGoldCoin,nSilverCoin,nCopperCoin = Player:GetData("MONEY");
	local nYuanbao = Player:GetData("YUANBAO")
	local nCoinType = StallBuy:GetStallType()
	-- 如果是金币摆摊
	if (nCoinType == 0) then
		StallBuy_Cash_Money:SetProperty("MoneyNumber",tostring(nMoney));
	-- 元宝摆摊
	elseif( nCoinType == 1 ) then
		StallBuy_Cash_Yuanbao:SetText("#Y"..tostring(nYuanbao).." 元宝");
	else
		PushDebugMessage("摆摊类型错误");
	end

	StallBuy_Name_Text:SetText("摊位名:" .. StallBuy:GetStallName());

	if(g_CurrentPage == PAGE_ITEM)     then
		StallBuy_UpdateItem();
	elseif (g_CurrentPage == PAGE_PET) then
		StallBuy_UpdatePet();
	end

	StallBuy_SetTabColor();

end

--===============================================
-- 点击购买
--===============================================
function StallBuy_Buy_Clicked()

	local nCoinType = StallBuy:GetStallType();

	if (nCoinType == 1) then
		local nSelfYuanbao = Player:GetData("YUANBAO");

		--local nPriceYuanbao = StallBuy:GetPrice("item", g_nCurSelectItem);
		--local nItemName = StallBuy:GetItemName(g_nCurSelectItemID);
		local nPriceYuanbao = 0;
		local nItemName = "";

		if(g_CurrentPage == PAGE_ITEM) then
			nPriceYuanbao = StallBuy:GetPrice("item", g_nCurSelectItem);
			nItemName = StallBuy:GetItemName(g_nCurSelectItemID);
			if( nItemName == nil or nPriceYuanbao == nil) then
				PushDebugMessage("请选择您需要的物品");
				return
			end
		else
			local nMyPetName = "";
			if(g_nCutSelectPet == -1)  then
				PushDebugMessage("请选择您需要的珍兽");
				return;
			end
			nItemName, nMyPetName = StallBuy:EnumPet(g_nPetID[g_nCutSelectPet]);
			nPriceYuanbao = StallBuy:GetPrice("pet",g_nPetID[g_nCutSelectPet]);
			if( nItemName == nil or nPriceYuanbao == nil) then
				PushDebugMessage("请选择您需要的珍兽");
				return
			end
		end

		if (nPriceYuanbao > nSelfYuanbao) then
			if(g_CurrentPage == PAGE_ITEM) then
				PushDebugMessage("#{YBBT_81021_07}");
			else
				PushDebugMessage("#{YBBT_90211_1}");
			end
			return
		else
			local nRet,nPrice = StallBuy:CheckItemPrice(g_nCurSelectItemID,g_nCurSelectItem)
			--如果返回1 代表超过之前购买的100%  提示 
			if nRet == 1 then
				StallBuy_OnBtnBuyOK()
			else
				if (g_CurrentPage == PAGE_PET) then
					local isProtectForYuanBaoStall = StallBuy:IsPetGoodsProtectForYuanBaoStall(g_nPetID[g_nCutSelectPet]);
					if isProtectForYuanBaoStall == 1 then
						local MsgBox = ScriptGlobal_Format("#{YBBT_251103_5}",nPriceYuanbao,nItemName)
						MessageBoxCommon("#{YBBT_081023_3}"  , MsgBox, 
						"StallBuy"        , "OnBtnBuyHighValuePetCheckOK("..'"'..nItemName..'","'..nPriceYuanbao..'")', "OnBtnBuyCancel()");
					else
						MessageBoxCommon("#{YBBT_081023_3}", "#{YBBT_081023_4}"..nItemName.."#{YBBT_081023_5}"..nPriceYuanbao.."#{YBBT_081023_6}", "StallBuy", "OnBtnBuyOK()", "OnBtnBuyCancel()");
					end
				else
					MessageBoxCommon("#{YBBT_081023_3}", "#{YBBT_081023_4}"..nItemName.."#{YBBT_081023_5}"..nPriceYuanbao.."#{YBBT_081023_6}", "StallBuy", "OnBtnBuyOK()", "OnBtnBuyCancel()");
				end
			end
		end

	else
		StallBuy_OnBtnBuyOK()
	end
end
function StallBuy_OnBtnBuyHighValuePetCheckOK(nItemName,nPriceYuanbao)
	MessageBoxCommon("#{YBBT_081023_3}", "#{YBBT_081023_4}"..nItemName.."#{YBBT_081023_5}"..nPriceYuanbao.."#{YBBT_081023_6}", "StallBuy", "OnBtnBuyOK()", "OnBtnBuyCancel()");

end
function StallBuy_OnBtnBuyOK()
	local nRet,nPrePrice = StallBuy:CheckItemPrice(g_nCurSelectItemID,g_nCurSelectItem) 
	--如果返回1 代表超过之前购买的100%  提示 
	if nRet == 1 then
		local nCoinType = StallBuy:GetStallType();
		local nItemName = StallBuy:GetItemName(g_nCurSelectItemID);
		local nItemNum  = StallBuy:GetItemNum(g_nCurSelectItemID);
		if nItemNum <= 0 then
			return
		end
		nPriceYuanbao = StallBuy:GetPrice("item", g_nCurSelectItem);
		local MsgBox;
		-- 如果是金币摆摊
		local nPriceYuanbao  =  nPriceYuanbao/nItemNum;
		local strMoney = string.format("%.1f", nPriceYuanbao)
		if (nCoinType == 0) then 
			MsgBox = ScriptGlobal_Format("#{BTDB_141021_02}",nItemName,strMoney,nPrePrice)
		-- 元宝摆摊
		elseif( nCoinType == 1 ) then  
			MsgBox = ScriptGlobal_Format("#{BTDB_141021_01}",nItemName,strMoney,nPrePrice)
		else
			PushDebugMessage("摆摊类型错误");
			return
		end 
		MessageBoxCommon("#{YBBT_081023_3}", MsgBox, "StallBuy", "OnBtnConfirmOK()", "OnBtnConfirmCancel()");
		return 
	end 
	if( g_CurrentPage == PAGE_ITEM )  then
		StallBuy:BuyItem(g_nCurSelectItemID,g_nCurSelectItem);
	else
		if(g_nCutSelectPet == -1)  then
			return;
		end
		StallBuy:BuyPet(g_nPetID[g_nCutSelectPet]);
	end
end

function StallBuy_OnBtnConfirmOK() 
	if( g_CurrentPage == PAGE_ITEM )  then
		StallBuy:BuyItem(g_nCurSelectItemID,g_nCurSelectItem);
	else
		if(g_nCutSelectPet == -1)  then
			return;
		end
		StallBuy:BuyPet(g_nPetID[g_nCutSelectPet]);
	end
end

function StallBuy_OnBtnConfirmCancel()
end
function StallBuy_OnBtnBuyCancel()
end

--===============================================
-- 点击打开摊位信息
--===============================================
function StallBuy_Message_Clicked()

	StallBuy:OpenMessageBuy();

end

--===============================================
-- 关闭按钮
--===============================================
function StallBuy_Close_Clicked()

	--取消关心
	if objCared ~= nil then
		this:CareObject(objCared, 0, "StallBuy");
	end
	StallBuy:CloseStallMessage();
	CloseMessageBoxCommon();
	CloseInputYuanbao();

	this:Hide();

end

--===============================================
-- 显示物品
--===============================================
function StallBuy_UpdateItem()
	local nItemNum = GetActionNum("st_other");
	for i=0, STALL_BUTTONS_NUM - 1  do
		local theAction = EnumAction(i, "st_other");
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
function StallBuy_UpdatePet()
	StallBuy_PetList:ClearListBox();

	local nPetNum = StallBuy:GetPetNum();
	local nIndex =0;
	for i=1 ,STALL_BUTTONS_NUM  do
		local szPetName, szType = StallBuy:EnumPet(i-1);
		if(szPetName ~= "")    then
			StallBuy_PetList:AddItem("#cffff00"..szType .. "#W(" .. szPetName .. ")" , nIndex);
			g_nPetID[nIndex] = i-1;
			nIndex = nIndex + 1;
		end
	end
end

--===============================================
-- 换页
--===============================================
function StallBuy_ChangeTabIndex(nIndex)
	--关闭先前弹出是否购买的提示框
	CloseMessageBoxCommon()

	if( nIndex == 1 )    then
		StallBuy_ChangePage(PAGE_ITEM)
	else
		StallBuy_ChangePage(PAGE_PET)
	end

	StallBuy_TargetPrice_Money:SetProperty("MoneyNumber","");
	StallBuy_TargetUnitPrice_Money:SetProperty("MoneyNumber","");
	StallBuy_TargetPrice_Yuanbao:SetText("#cff99000 #W元宝")
end


--===============================================
-- 换页刷新
--===============================================
function StallBuy_ChangePage(nPage)
	g_CurrentPage = nPage;
	if(g_CurrentPage == PAGE_ITEM) then
		StallBuy_PetList:Hide();
		StallBuy_Item_Set:Show();
		for i=1, STALL_BUTTONS_NUM   do
			STALL_BUTTON[i]:Show();
		end
		StallBuy_ViewPets:Hide();
	else
		StallBuy_Item_Set:Hide();
		StallBuy_PetList:Show();
		for i=1, STALL_BUTTONS_NUM   do
			STALL_BUTTON[i]:Hide();
		end
		
		local nCoinType = StallBuy:GetStallType()
		if ( nCoinType == 1 ) then
			StallBuy_ViewPets:Show();
		end
	end

	StallBuy_UpdateFrame();
end


--===============================================
-- 点击珍兽列表
--===============================================
function StallBuy_PetList_Selected()

	g_nCutSelectPet = StallBuy_PetList:GetFirstSelectItem();

	--StallBuy_Buy:Enable();

	--获得这个物品的价格
	if (g_nCutSelectPet == -1)   then
		return;
	end
	nMoney = StallBuy:GetPrice("pet",g_nPetID[g_nCutSelectPet]);

	--关闭先前弹出是否购买的提示框
	CloseMessageBoxCommon()

	-- 如果是金币摆摊
	local nCoinType = StallBuy:GetStallType()
	if (nCoinType == 0) then
		StallBuy_SetItemOrPetPrice(0, nMoney);
		--StallBuy_TargetPrice_Money:SetProperty("MoneyNumber",tostring(nMoney));
	-- 元宝摆摊
	elseif( nCoinType == 1 ) then
		StallBuy_SetItemOrPetPrice(1, nMoney);
		--StallBuy_TargetPrice_Yuanbao:SetText("#Y"..tostring(nMoney).." 元宝");
	else
		PushDebugMessage("摆摊类型错误");
	end
end

--===============================================
-- 右键点击
--===============================================
function StallBuy_PetList_RClick()
	g_nCutSelectPet = StallBuy_PetList:GetFirstSelectItem();

	if(g_nCutSelectPet == -1)  then
		PushDebugMessage("请选择一只珍兽后点击查看")
		return;
	end

	--显示珍兽
	StallSale:ViewPetDesc("other", g_nPetID[g_nCutSelectPet]);
end

--===============================================
-- 显示Tab上字体的颜色
--===============================================
function StallBuy_SetTabColor()

	local selColor = "#e010101#Y";
	local noselColor = "#e010101";

	local newColor = "#e010101#c888888"

	if( PAGE_ITEM == g_CurrentPage ) then
		StallBuy_Item:SetText(selColor .. "物品");
		StallBuy_Pet:SetText(noselColor .. "珍兽");

		-- 看另一页，如果没有东西，就设置为灰色
		-- Tab上的字体颜色
		local nObjNum = StallBuy:IsHaveObject("pet")
		if nObjNum == 0    then
			StallBuy_Pet:SetText(newColor .. "珍兽");
		end

	else
		StallBuy_Item:SetText(noselColor .. "物品");
		StallBuy_Pet:SetText(selColor .. "珍兽");

		local nItemNum = StallBuy:IsHaveObject("item")
		if nItemNum == 0    then
			StallBuy_Item:SetText(newColor .. "物品");
		end
	end

end

--===============================================
-- 恢复选中状态（清空选中）
--===============================================
function StallBuy_ClearSelect()
	g_nCutSelectPet = -1;
	g_nCurSelectItemID = -1;
	g_nCurSelectItem = -1;
end


--===============================================
-- 如果完家的金钱改变
--===============================================
function StallBuy_modifymoney()
	--更新完家的金钱
	--填写自己的金钱数
	local nMoney;
	local nGoldCoin;
	local nSilverCoin;
	local nCopperCoin;

	nMoney,nGoldCoin,nSilverCoin,nCopperCoin = Player:GetData("MONEY");
	StallBuy_Cash_Money:SetProperty("MoneyNumber",tostring(nMoney));
end


function StallBuy_SetItemOrPetPrice(nCoinType, nMoney)

	local nMoneyEnd = 0;
	local nMoneyBegin = 0
	local nMoneyMid = 0;
	local strMoney = "";

	-- 如果是金币摆摊
	if (nCoinType == 0) then
		StallBuy_TargetPrice_Money:SetProperty("MoneyNumber",tostring(nMoney));
		local nCount = 1;
		if( g_CurrentPage == PAGE_ITEM )  then
			nCount = StallBuy:GetItemNum(g_nCurSelectItemID)
		end
		if nCount == nil or nCount <= 0 then
			nCount = 1
		end
		StallBuy_TargetUnitPrice_Money:SetProperty("MoneyNumber", tostring(Division(nMoney, nCount) ) );
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

		StallBuy_TargetPrice_Yuanbao:SetText("#Y"..strMoney.." #W元宝");
	else
		PushDebugMessage("摆摊类型错误");
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function StallBuy_Frame_On_ResetPos()

	StallBuy_Frame : SetProperty("UnifiedXPosition", g_StallBuy_Frame_UnifiedXPosition);
	StallBuy_Frame : SetProperty("UnifiedYPosition", g_StallBuy_Frame_UnifiedYPosition);

end
