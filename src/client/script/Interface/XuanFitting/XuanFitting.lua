----------------------------------------------------------------------------------------------------------------
--
-- 全局变量定义
--
local g_XuanFitting_Dress	= {}	--与Animate对应
local g_XuanFitting_Item	= {}	--试衣间内的按钮
local g_XuanFitting_ItemText	= {}	--试衣间的说明
local g_XuanFitting_ItemGB	= {}
local g_XuanFitting_TempDress	= {}	--试衣服的临时数据

local g_XuanFitting_Male_Default	= {}
g_XuanFitting_Male_Default[0] = nil
g_XuanFitting_Male_Default[1] = "Base_M_DownBody"
g_XuanFitting_Male_Default[2] = "Base_M_UpBody"
g_XuanFitting_Male_Default[3] = "Base_M_Head"
g_XuanFitting_Male_Default[4] = nil
g_XuanFitting_Male_Default[5] = nil

local g_XuanFitting_Female_Default	= {}
g_XuanFitting_Female_Default[0] = nil
g_XuanFitting_Female_Default[1] = "Base_F_DownBody"
g_XuanFitting_Female_Default[2] = "Base_F_UpBody"
g_XuanFitting_Female_Default[3] = "Base_F_Head"
g_XuanFitting_Female_Default[4] = nil
g_XuanFitting_Female_Default[5] = nil

local g_XuanFitting_Deleting = 0;
local g_XuanFitting_ItemNum = 10;
local g_XuanFitting_MaxPage = 2;

local g_XuanFitting_PACKUPENABLE = true;

local g_XuanFitting_DressPoint = {
	BackGround	= 0,
	Leg		= 1,
	Body		= 2,
	Head		= 3,
	Front		= 4,
	Suit		= 5,
}

local g_XuanFitting_Frame_UnifiedXPosition;
local g_XuanFitting_Frame_UnifiedYPosition;

-----------------------------------------------------------------------------------------------------------------
--
-- 函数定义
--

function XuanFitting_PreLoad()
	-- 打开界面
	this:RegisterEvent("OPEN_IMDRESS_CHEST");
	this:RegisterEvent("IMDRESSCHEST_ITEM_CHANGED");
	this:RegisterEvent("IMDRESS_SELECT");
	this:RegisterEvent("UPDATE_MYSELF_IMDRESS");
	this:RegisterEvent("CLOSE_SHOP_FITTING");
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("BEGIN_PACKUP_IMDRESSCHEST")
	this:RegisterEvent("END_PACKUP_IMDRESSCHEST")
	this:RegisterEvent("IMDRESSCHEST_ITEM_SWAPED")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

-- 注册onLoad事件
function XuanFitting_OnLoad()
	g_XuanFitting_Dress[0] = XuanFitting_fitting_BK
	g_XuanFitting_Dress[1] = XuanFitting_fitting_DownBody
	g_XuanFitting_Dress[2] = XuanFitting_fitting_UpBody
	g_XuanFitting_Dress[3] = XuanFitting_fitting_Head
	g_XuanFitting_Dress[4] = XuanFitting_fitting_FK
	g_XuanFitting_Dress[5] = XuanFitting_fitting_Suit

	g_XuanFitting_TempDress[0] = -1
	g_XuanFitting_TempDress[1] = -1
	g_XuanFitting_TempDress[2] = -1
	g_XuanFitting_TempDress[3] = -1
	g_XuanFitting_TempDress[4] = -1
	g_XuanFitting_TempDress[5] = -1

	g_XuanFitting_Item[0] = XuanFitting_Item1
	g_XuanFitting_Item[1] = XuanFitting_Item2
	g_XuanFitting_Item[2] = XuanFitting_Item3
	g_XuanFitting_Item[3] = XuanFitting_Item4
	g_XuanFitting_Item[4] = XuanFitting_Item5
	g_XuanFitting_Item[5] = XuanFitting_Item6
	g_XuanFitting_Item[6] = XuanFitting_Item7
	g_XuanFitting_Item[7] = XuanFitting_Item8
	g_XuanFitting_Item[8] = XuanFitting_Item9
	g_XuanFitting_Item[9] = XuanFitting_Item10

	g_XuanFitting_ItemText[0] = XuanFitting_ItemInfo1_Text
	g_XuanFitting_ItemText[1] = XuanFitting_ItemInfo2_Text
	g_XuanFitting_ItemText[2] = XuanFitting_ItemInfo3_Text
	g_XuanFitting_ItemText[3] = XuanFitting_ItemInfo4_Text
	g_XuanFitting_ItemText[4] = XuanFitting_ItemInfo5_Text
	g_XuanFitting_ItemText[5] = XuanFitting_ItemInfo6_Text
	g_XuanFitting_ItemText[6] = XuanFitting_ItemInfo7_Text
	g_XuanFitting_ItemText[7] = XuanFitting_ItemInfo8_Text
	g_XuanFitting_ItemText[8] = XuanFitting_ItemInfo9_Text
	g_XuanFitting_ItemText[9] = XuanFitting_ItemInfo10_Text

	g_XuanFitting_ItemGB[0] = XuanFitting_ItemInfo1_GB
	g_XuanFitting_ItemGB[1] = XuanFitting_ItemInfo2_GB
	g_XuanFitting_ItemGB[2] = XuanFitting_ItemInfo3_GB
	g_XuanFitting_ItemGB[3] = XuanFitting_ItemInfo4_GB
	g_XuanFitting_ItemGB[4] = XuanFitting_ItemInfo5_GB
	g_XuanFitting_ItemGB[5] = XuanFitting_ItemInfo6_GB
	g_XuanFitting_ItemGB[6] = XuanFitting_ItemInfo7_GB
	g_XuanFitting_ItemGB[7] = XuanFitting_ItemInfo8_GB
	g_XuanFitting_ItemGB[8] = XuanFitting_ItemInfo9_GB
	g_XuanFitting_ItemGB[9] = XuanFitting_ItemInfo10_GB

	g_XuanFitting_Frame_UnifiedXPosition	= XuanFitting_Frame:GetProperty("UnifiedXPosition");
	g_XuanFitting_Frame_UnifiedYPosition	= XuanFitting_Frame:GetProperty("UnifiedYPosition");
end

-- OnEvent
function XuanFitting_OnEvent(event)

	if( event == "OPEN_IMDRESS_CHEST" ) then
		if (this:IsVisible() == false) then
			XuanFitting_Show()
		end
		XuanFitting_ShowMyDress()
		XuanFitting_UpdateChest()

		return
	end

	if( event == "IMDRESSCHEST_ITEM_CHANGED" ) then
		if (this:IsVisible() == false) then
			return
		end
		XuanFitting_ShowMyDress()
		XuanFitting_UpdateChest()
		if g_XuanFitting_PACKUPENABLE == true then
			PackUpIMDressChest()
		end
		return
	end

	if( event == "IMDRESSCHEST_ITEM_SWAPED" ) then
		XuanFitting_ShowMyDress()
		XuanFitting_UpdateChest()
		return
	end



	if( event == "BEGIN_PACKUP_IMDRESSCHEST" ) then
			g_XuanFitting_PACKUPENABLE = false
		return
	end

	if( event == "END_PACKUP_IMDRESSCHEST" ) then
			g_XuanFitting_PACKUPENABLE = true
		return
	end

	if( event == "IMDRESS_SELECT" ) then
		if (this:IsVisible() == false) then
			return
		end
		XuanFitting_PutOnDress()
		return
	end

	if (event == "UPDATE_MYSELF_IMDRESS") then
		if (this:IsVisible() == false) then
			return
		end
		XuanFitting_ShowMyDress();
		return
	end

	if (event == "CLOSE_SHOP_FITTING") then
		XuanFitting_DelItem:SetCheck(0)
		g_XuanFitting_Deleting = 0;
		return
	end

	if( event == "ADJEST_UI_POS" ) then
		XuanFitting_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		XuanFitting_ResetPos()
	end
	
	if (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end

function XuanFitting_Show()
	this:Show();
	g_XuanFitting_Deleting = 0;
	g_XuanFitting_CurPage = 1;
	XuanFitting_DelItem:SetCheck(0)
end

function XuanFitting_ShowMyDress()
	local anim = {};
	anim[0], anim[1], anim[2], anim[3], anim[4], anim[5] = DataPool:GetMySelfIMDress();

	for i = 0, 5 do
		g_XuanFitting_TempDress[i] = IMDressGetIndexByDressPoint(i);
		g_XuanFitting_Dress[i]:Play(false);
		if anim[i] ~= nil then
			g_XuanFitting_Dress[i]:SetProperty("Animate", anim[i]);
			g_XuanFitting_Dress[i]:Play(true);
		end
	end

	XuanFitting_UpdateChest()
end

function XuanFitting_UpdateChest()
	if g_XuanFitting_CurPage == nil or g_XuanFitting_CurPage < 1 or g_XuanFitting_CurPage > g_XuanFitting_MaxPage then
		return
	end

	XuanFitting_CurrentlyPage:SetText(""..g_XuanFitting_CurPage.."/"..g_XuanFitting_MaxPage);

	XuanFitting_UpPage:Enable();
	XuanFitting_DownPage:Enable();
	if (g_XuanFitting_CurPage == 1) then
		XuanFitting_UpPage:Disable();
	elseif (g_XuanFitting_CurPage == g_XuanFitting_MaxPage) then
		XuanFitting_DownPage:Disable();
	end

	local startIndex = (g_XuanFitting_CurPage-1) * g_XuanFitting_ItemNum;
	local endIndex = g_XuanFitting_CurPage * g_XuanFitting_ItemNum - 1;

	for i = startIndex, endIndex do
		--local isOn = IMDressIsDressOn(i);
		local index = i - startIndex;
		g_XuanFitting_Item[index]:SetPushed(0);
		local theAction = EnumAction(i, "imdress");
		if theAction:GetID() ~= 0 then
			g_XuanFitting_Item[index]:SetActionItem(theAction:GetID());
			g_XuanFitting_ItemText[index]:SetText(theAction:GetName());

			local time = IMDressGetUsefulLife(i);
			if (time ~= nil) then
				g_XuanFitting_ItemGB[index]:SetText(time);
			else
				g_XuanFitting_ItemGB[index]:SetText("")
			end

			--if (isOn == 1) then
			--	g_XuanFitting_Item[i]:SetPushed(1);
			--end
		else
			g_XuanFitting_Item[index]:SetActionItem(-1);
			g_XuanFitting_ItemText[index]:SetText("");
			g_XuanFitting_ItemGB[index]:SetText("")
		end
	end

	for i = 0, table.getn(g_XuanFitting_TempDress) do
		if (g_XuanFitting_TempDress[i] >= startIndex and g_XuanFitting_TempDress[i] <= endIndex) then
			local index = g_XuanFitting_TempDress[i] - startIndex;
			g_XuanFitting_Item[index]:SetPushed(1);
		end
	end
end

function XuanFitting_DressButton_Clicked(index)
	if index < 0 or index > table.getn(g_XuanFitting_Item) then
		return
	end

	g_XuanFitting_Item[index]:DoAction()
end

function XuanFitting_PutOnDress()
	local index = IMDressChestGetSelIndex()
	local dressPoint, animate = IMDressGetDressInfo(index, "imdress")
	if dressPoint == nil or animate == nil or (dressPoint < 0 or dressPoint > table.getn(g_XuanFitting_Dress)) then
		return
	end

	local nNeedSex = IMDressGetDressInfo(index, "getsex")
	if nNeedSex == nil then
		return
	end

	local iSexy = Player:GetMySex()
	if nNeedSex ~= -1 and nNeedSex ~= iSexy then
		PushDebugMessage("#{ZXD_20120406_12}")
		return
	end

	local startIndex = (g_XuanFitting_CurPage-1) * g_XuanFitting_ItemNum;
	local endIndex = g_XuanFitting_CurPage * g_XuanFitting_ItemNum - 1;
	--判断是穿还是脱
	if (g_XuanFitting_TempDress[dressPoint] ~= index) then
		--穿上一件新的
		--判断是不是套装
		if (dressPoint == g_XuanFitting_DressPoint.Suit) then
			--是套装，先清空所有身上的衣服
			XuanFitting_ShowDefault();
		else
			--不是套装，查看套装位置是否有衣服，有的话，脱掉
			local suitPoint = g_XuanFitting_DressPoint.Suit
			local suitIndex = g_XuanFitting_TempDress[suitPoint]
			if (suitIndex ~= -1) then
				--脱掉套装
				g_XuanFitting_Dress[suitPoint]:Play(false);
				g_XuanFitting_TempDress[suitPoint] = -1;
				--更新选中状态
				if (suitIndex >= startIndex and suitIndex <= endIndex) then
					local buttonIndex = suitIndex - startIndex;
					g_XuanFitting_Item[buttonIndex]:SetPushed(0);
				end
			end
		end
		--执行换装逻辑
		g_XuanFitting_Dress[dressPoint]:SetProperty("Animate", animate)
		g_XuanFitting_Dress[dressPoint]:Play(true);
		local lastIndex = g_XuanFitting_TempDress[dressPoint];
		g_XuanFitting_TempDress[dressPoint] = index;
		--设置为选中状态
		g_XuanFitting_Item[index-startIndex]:SetPushed(1);

		if (lastIndex ~= -1) then
			if (lastIndex >= startIndex and lastIndex <= endIndex) then
				local buttonIndex = lastIndex - startIndex;
				g_XuanFitting_Item[buttonIndex]:SetPushed(0);
			end
		end
	else
		--脱掉一件旧的
		g_XuanFitting_Dress[dressPoint]:Play(false);
		g_XuanFitting_TempDress[dressPoint] = -1;
		--取消选中状态
		g_XuanFitting_Item[index-startIndex]:SetPushed(0);

		local raceId = GetMySelfRaceId();
		local tempTable = g_XuanFitting_Female_Default;
		if raceId == 1 then
			tempTable = g_XuanFitting_Male_Default;
		end

		if (tempTable[dressPoint] ~= nil) then
			g_XuanFitting_Dress[dressPoint]:SetProperty("Animate", tempTable[dressPoint])
			g_XuanFitting_Dress[dressPoint]:Play(true);
		end

	end
end

function XuanFitting_ChangeMyDress_Clicked()
	for i = 0, table.getn(g_XuanFitting_TempDress) do
		if (g_XuanFitting_TempDress[i] <= -1) then
			IMDressSendChangeDress(i, g_XuanFitting_TempDress[i]);
		end
	end

	for i = 0, table.getn(g_XuanFitting_TempDress) do
		if (g_XuanFitting_TempDress[i] > -1) then
			IMDressSendChangeDress(i, g_XuanFitting_TempDress[i]);
		end
	end
end

function XuanFitting_OnClose()
	SetDefaultMouse();
	this:Hide();
end

function XuanFitting_ShowDefault()

	local raceId = GetMySelfRaceId();

	local tempTable = g_XuanFitting_Female_Default;
	if raceId == 1 then
		tempTable = g_XuanFitting_Male_Default;
	end

	for i = 0, 5 do
		g_XuanFitting_TempDress[i] = -1;
		g_XuanFitting_Dress[i]:Play(false);
		if tempTable[i] ~= nil then
			g_XuanFitting_Dress[i]:SetProperty("Animate", tempTable[i]);
			g_XuanFitting_Dress[i]:Play(true);
		end
	end

	for _, item in g_XuanFitting_Item do
		item:SetPushed(0);
	end
end

function XuanFitting_ShowXuanShop()
	PushEvent("OPEN_IMDRESS_YUANBAOSHOP")
end

function XuanFitting_DeleteItem()
	if g_XuanFitting_Deleting == 0 then
		MouseCmd_ShopFittingSet();
		g_XuanFitting_Deleting = 1
	else
		SetDefaultMouse();
		g_XuanFitting_Deleting = 0
	end

end

function XuanFitting_UpPageClicked()
	local page = g_XuanFitting_CurPage - 1;
	if (page < 1) then
		page = 1
	end
	g_XuanFitting_CurPage = page
	XuanFitting_UpdateChest();
end

function XuanFitting_DownPageClicked()
	local page = g_XuanFitting_CurPage + 1;
	if (page > g_XuanFitting_MaxPage) then
		page = g_XuanFitting_MaxPage
	end
	g_XuanFitting_CurPage = page
	XuanFitting_UpdateChest();
end

function XuanFitting_ResetPos()
	XuanFitting_Frame:SetProperty("UnifiedXPosition", g_XuanFitting_Frame_UnifiedXPosition);
	XuanFitting_Frame:SetProperty("UnifiedYPosition", g_XuanFitting_Frame_UnifiedYPosition);
end
