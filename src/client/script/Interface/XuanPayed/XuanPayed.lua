local XUANPAYED_GOODS_BUTTONS_NUM	= 12;
local XUANPAYED_GOODS_BUTTONS		= {};
local XUANPAYED_GOODS_DESCS		= {};
local XUANPAYED_GOOD_BAD		= {};
local XUANPAYED_ISBUY_GOOD		= {};
local XUANPAYED_GOODS_PRICE		= {};
local XUANPAYED_TOTAL_PRICE		= 0;
local XUANPAYED_TOTAL_COUNT		= 0;


local XuanPayed_nPageNum = 1;
local XuanPayed_maxPage = 1;

local g_XuanPayed_Frame_UnifiedXPosition;
local g_XuanPayed_Frame_UnifiedYPosition;

local g_XuanPayed_Type;
local g_XuanPayed_friendid;

function XuanPayed_PreLoad()
	this:RegisterEvent("OPEN_IMDRESS_PAYED");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UPDATE_YUANBAO");
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function XuanPayed_OnLoad()

	XUANPAYED_GOODS_BUTTONS[1] = XuanPayed_Item1;
	XUANPAYED_GOODS_BUTTONS[2] = XuanPayed_Item2;
	XUANPAYED_GOODS_BUTTONS[3] = XuanPayed_Item3;
	XUANPAYED_GOODS_BUTTONS[4] = XuanPayed_Item4;
	XUANPAYED_GOODS_BUTTONS[5] = XuanPayed_Item5;
	XUANPAYED_GOODS_BUTTONS[6] = XuanPayed_Item6;
	XUANPAYED_GOODS_BUTTONS[7] = XuanPayed_Item7;
	XUANPAYED_GOODS_BUTTONS[8] = XuanPayed_Item8;
	XUANPAYED_GOODS_BUTTONS[9] = XuanPayed_Item9;
	XUANPAYED_GOODS_BUTTONS[10]= XuanPayed_Item10;
	XUANPAYED_GOODS_BUTTONS[11]= XuanPayed_Item11;
	XUANPAYED_GOODS_BUTTONS[12]= XuanPayed_Item12;

	XUANPAYED_GOODS_DESCS[1] = XuanPayed_ItemInfo1_Text;
	XUANPAYED_GOODS_DESCS[2] = XuanPayed_ItemInfo2_Text;
	XUANPAYED_GOODS_DESCS[3] = XuanPayed_ItemInfo3_Text;
	XUANPAYED_GOODS_DESCS[4] = XuanPayed_ItemInfo4_Text;
	XUANPAYED_GOODS_DESCS[5] = XuanPayed_ItemInfo5_Text;
	XUANPAYED_GOODS_DESCS[6] = XuanPayed_ItemInfo6_Text;
	XUANPAYED_GOODS_DESCS[7] = XuanPayed_ItemInfo7_Text;
	XUANPAYED_GOODS_DESCS[8] = XuanPayed_ItemInfo8_Text;
	XUANPAYED_GOODS_DESCS[9] = XuanPayed_ItemInfo9_Text;
	XUANPAYED_GOODS_DESCS[10]= XuanPayed_ItemInfo10_Text;
	XUANPAYED_GOODS_DESCS[11]= XuanPayed_ItemInfo11_Text;
	XUANPAYED_GOODS_DESCS[12]= XuanPayed_ItemInfo12_Text;

	XUANPAYED_GOOD_BAD[1]  =     XuanPayed_ItemInfo1_GB;
	XUANPAYED_GOOD_BAD[2]  =     XuanPayed_ItemInfo2_GB;
	XUANPAYED_GOOD_BAD[3]  =     XuanPayed_ItemInfo3_GB;
	XUANPAYED_GOOD_BAD[4]  =     XuanPayed_ItemInfo4_GB;
	XUANPAYED_GOOD_BAD[5]  =     XuanPayed_ItemInfo5_GB;
	XUANPAYED_GOOD_BAD[6]  =     XuanPayed_ItemInfo6_GB;
	XUANPAYED_GOOD_BAD[7]  =     XuanPayed_ItemInfo7_GB;
	XUANPAYED_GOOD_BAD[8]  =     XuanPayed_ItemInfo8_GB;
	XUANPAYED_GOOD_BAD[9]  =     XuanPayed_ItemInfo9_GB;
	XUANPAYED_GOOD_BAD[10] =     XuanPayed_ItemInfo10_GB;
	XUANPAYED_GOOD_BAD[11] =     XuanPayed_ItemInfo11_GB;
	XUANPAYED_GOOD_BAD[12] =     XuanPayed_ItemInfo12_GB;

	g_XuanPayed_Frame_UnifiedXPosition	= XuanPayed_Frame:GetProperty("UnifiedXPosition");
	g_XuanPayed_Frame_UnifiedYPosition	= XuanPayed_Frame:GetProperty("UnifiedYPosition");
end


function XuanPayed_OnEvent(event)

	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		XuanPayed_Close_Clicked()
	end

	if event == "OPEN_IMDRESS_PAYED" then
		local ret = IMDressLoadPayBox();
		if (ret == nil or ret <= 0) then
			return
		end
		
		if arg0 ~= "PresentShop" and arg0 ~= "XuanShop" then
		  return
		end
		
		XuanPayed_Show();
		
		if (arg0 and arg0 == "PresentShop") then 	--如果是赠品商店购买
			g_XuanPayed_Type = arg0;
			g_XuanPayed_friendid = arg1;
			XuanPayed_GetCheck:Hide();
			XuanPayed_GetCheck_Text:Hide();
			XuanPayed_DragTitle:SetText("#{ZSGN_101129_27}")
		elseif (arg0 and arg0 == "XuanShop") then  --如果是炫装商城
		 	g_XuanPayed_Type = arg0;
		 	local check  = tonumber(NpcShop:GetAutoPutOnBuyStuff());
			if(check>=1)then
				XuanPayed_GetCheck:SetCheck(1);
			else
				XuanPayed_GetCheck:SetCheck(0);
			end
			XuanPayed_GetCheck:Show();
			XuanPayed_GetCheck_Text:Show();
			XuanPayed_DragTitle:SetText("#{IMXZ_20100813_39}")
		end
	 
		SetDefaultMouse();

	elseif (event == "UPDATE_YUANBAO" and this:IsVisible()) then
		XuanPayed_YuanbaoNum : SetText( "#{YBSD_081225_068}"..tostring(Player:GetData("YUANBAO")) )
	elseif( event == "ADJEST_UI_POS" ) then
		XuanPayed_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		XuanPayed_ResetPos()
	end
end
--==================
--打开商店
function XuanPayed_Show()
	this:Show();
	for i = 1, table.getn(XUANPAYED_GOODS_BUTTONS) do
		XUANPAYED_GOODS_BUTTONS[i]:SetActionItem(-1);
		XUANPAYED_GOODS_BUTTONS[i]:SetPushed(0);
		XUANPAYED_GOODS_DESCS[i]:SetText("");
		XUANPAYED_GOOD_BAD[i]:SetText("");
		XUANPAYED_ISBUY_GOOD[i] = false;
		XUANPAYED_GOODS_PRICE[i] = 0;
	end
	XUANPAYED_TOTAL_PRICE = 0;
	XUANPAYED_TOTAL_COUNT = 0;
	XuanPayed_UpdatePage();
end
--===============================
--刷新一页
function XuanPayed_UpdatePage()

	XuanPayed_YuanbaoNum : SetText( "#{YBSD_081225_068}"..tostring(Player:GetData("YUANBAO")) )
	XuanPayed_CurrentlyPage : SetText("1/1");
	XuanPayed_DownPage:Disable();
	XuanPayed_UpPage:Disable();

	local index = 1
	local totalPrice = 0
	for i = 1, table.getn(XUANPAYED_GOODS_BUTTONS) do
		local theAction = EnumAction(i-1, "paybox");
		if theAction:GetID() ~= 0 then
			XUANPAYED_GOODS_BUTTONS[index]:SetActionItem(theAction:GetID());
			XUANPAYED_GOODS_BUTTONS[index]:SetPushed(1);
			XUANPAYED_ISBUY_GOOD[index] = true;
			XUANPAYED_GOODS_DESCS[index]:SetText(theAction:GetName());

			local nPrice = IMDressGetPayBoxPrice( i-1 )
			XUANPAYED_GOODS_PRICE[index] = nPrice;
			XUANPAYED_GOOD_BAD[index]:SetText("#{YBSD_081225_101}" .. tostring(nPrice))

			index = index + 1
			totalPrice = totalPrice + nPrice;
		end
	end
	--共购买#G%s0#W件道具，需要付款#G%s1#W绑定元宝
	XuanPayed_Info:SetText("#{IMXZ_20101122_106}"..(index - 1).."#{IMXZ_20101122_107}"..totalPrice.."#{IMXZ_20101122_108}");
	XUANPAYED_TOTAL_PRICE = totalPrice;
	XUANPAYED_TOTAL_COUNT = index - 1;
end

function XuanPayed_GoodButton_Clicked(nIndex)
	if(nIndex < 1 or nIndex > 12) then
		return;
	end
	
	if XUANPAYED_GOODS_BUTTONS[nIndex]:GetActionItem() == -1 then
		return
	end
	
	if (XUANPAYED_ISBUY_GOOD[nIndex] == true) then
		XUANPAYED_ISBUY_GOOD[nIndex] = false;
		XUANPAYED_GOODS_BUTTONS[nIndex]:SetPushed(0);
		XUANPAYED_GOOD_BAD[nIndex]:SetText("#{IMXZ_20101122_109}")
		XUANPAYED_TOTAL_PRICE = XUANPAYED_TOTAL_PRICE - XUANPAYED_GOODS_PRICE[nIndex];
		XUANPAYED_TOTAL_COUNT = XUANPAYED_TOTAL_COUNT - 1;
	else
		XUANPAYED_ISBUY_GOOD[nIndex] = true;
		XUANPAYED_GOODS_BUTTONS[nIndex]:SetPushed(1);
		XUANPAYED_GOOD_BAD[nIndex]:SetText("#{YBSD_081225_101}" .. tostring(XUANPAYED_GOODS_PRICE[nIndex]))
		XUANPAYED_TOTAL_PRICE = XUANPAYED_TOTAL_PRICE + XUANPAYED_GOODS_PRICE[nIndex];
		XUANPAYED_TOTAL_COUNT = XUANPAYED_TOTAL_COUNT + 1;
	end
	XuanPayed_Info:SetText("#{IMXZ_20101122_106}"..XUANPAYED_TOTAL_COUNT.."#{IMXZ_20101122_107}"..XUANPAYED_TOTAL_PRICE.."#{IMXZ_20101122_108}");
end
--===============================================
-- PageUp
--===============================================
function XuanPayed_PageUp()

end

--===============================================
-- PageDown
--===============================================
function XuanPayed_PageDown()

end

--===============================================
-- Close
--===============================================
function XuanPayed_Close_Clicked()
	SetDefaultMouse();
	if(IsWindowShow("XuanShop") == false) then
		IMDressCleanUpPayBox();
	end
	
	this:Hide();
end

--确认按钮
function XuanPayed_GetCheckClicked()
	if(NpcShop:GetAutoPutOnBuyStuff() == 0)then
		NpcShop:SetAutoPutOnBuyStuff(1);
	else
		NpcShop:SetAutoPutOnBuyStuff(0);
	end
end

function XuanPayed_Payed_Clicked()
	if (XUANPAYED_TOTAL_COUNT > 0) then
		if g_XuanPayed_Type == "PresentShop" then 

			local ret = 1
			if g_XuanPayed_friendid == "" then
				ret = -1		
			end
			
			local Friendgroup, Friendindex = DataPool:GetFriendByGUID(g_XuanPayed_friendid);	
			if Friendgroup == 0 or Friendindex == -1 then
				ret = -1
			end
			
			--如果不是好友
			local friendRelationType = DataPool:GetFriend( Friendgroup, Friendindex, "RELATION_TYPE"  )
				--只有好友可以赠送
			if friendRelationType == 0  or friendRelationType == 4  or friendRelationType == 5 or
			   friendRelationType == 6  or friendRelationType == 9 then
			   ret = -1
			end	
			
			if ret == -1 then
				PushDebugMessage("#{ZSGN_101129_24}");
				PushEvent("IMDRESS_CLEAN_SHOP_SELECTED")
				XuanPayed_Close_Clicked();
				return
			end
			
      IMDressPayMoneyToOther(XUANPAYED_ISBUY_GOOD, g_XuanPayed_friendid)
      PushEvent("IMDRESS_CLEAN_SHOP_SELECTED")
		else
			IMDressPayMoney(XUANPAYED_ISBUY_GOOD);
			PushEvent("IMDRESS_CLEAN_SHOP_SELECTED")			
	  end  
	end
	XuanPayed_Close_Clicked();
end

function XuanPayed_Cancel_Clicked()
	XuanPayed_Close_Clicked();
end

function XuanPayed_DownPageClicked()
end

function XuanPayed_UpPageClicked()
end

function XuanPayed_ResetPos()
	XuanPayed_Frame:SetProperty("UnifiedXPosition", g_XuanPayed_Frame_UnifiedXPosition);
	XuanPayed_Frame:SetProperty("UnifiedYPosition", g_XuanPayed_Frame_UnifiedYPosition);
end
