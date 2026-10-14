--SH_YunyouShop.lua
local GOODS_BUTTONS_NUM = 12;
local GOODS_BUTTONS = {};
local GOODS_DESCS = {};
local GOODS_PRICE = {};
local GOODS_MASK = {};

local g_nTargetId=-1;
local objCared = -1;

local MAX_OBJ_DISTANCE = 3.0;

--当前商店的商品数量
local	g_nTotalNum		= 0;

local g_SH_YunyouSH_YunyouShopFrame_UnifiedPosition;

local g_SH_YunyouShop_Item={
}

--===============================================
-- PreLoad
--===============================================
function SH_YunyouShop_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面
	this:RegisterEvent("OBJECT_CARED_EVENT", false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--离开场景关闭界面
end

--===============================================
-- OnLoad
--===============================================
function SH_YunyouShop_OnLoad()
	GOODS_BUTTONS[1] = SH_YunyouShopItem1;
	GOODS_BUTTONS[2] = SH_YunyouShopItem2;
	GOODS_BUTTONS[3] = SH_YunyouShopItem3;
	GOODS_BUTTONS[4] = SH_YunyouShopItem4;
	GOODS_BUTTONS[5] = SH_YunyouShopItem5;
	GOODS_BUTTONS[6] = SH_YunyouShopItem6;
	GOODS_BUTTONS[7] = SH_YunyouShopItem7;
	GOODS_BUTTONS[8] = SH_YunyouShopItem8;
	GOODS_BUTTONS[9] = SH_YunyouShopItem9;
	GOODS_BUTTONS[10]= SH_YunyouShopItem10;
	GOODS_BUTTONS[11]= SH_YunyouShopItem11;
	GOODS_BUTTONS[12]= SH_YunyouShopItem12;

	GOODS_DESCS[1] = SH_YunyouShopItemInfo1_Text;
	GOODS_DESCS[2] = SH_YunyouShopItemInfo2_Text;
	GOODS_DESCS[3] = SH_YunyouShopItemInfo3_Text;
	GOODS_DESCS[4] = SH_YunyouShopItemInfo4_Text;
	GOODS_DESCS[5] = SH_YunyouShopItemInfo5_Text;
	GOODS_DESCS[6] = SH_YunyouShopItemInfo6_Text;
	GOODS_DESCS[7] = SH_YunyouShopItemInfo7_Text;
	GOODS_DESCS[8] = SH_YunyouShopItemInfo8_Text;
	GOODS_DESCS[9] = SH_YunyouShopItemInfo9_Text;
	GOODS_DESCS[10]= SH_YunyouShopItemInfo10_Text;
	GOODS_DESCS[11]= SH_YunyouShopItemInfo11_Text;
	GOODS_DESCS[12]= SH_YunyouShopItemInfo12_Text;

	GOODS_PRICE[1] = SH_YunyouShopItemInfo1_Price;
	GOODS_PRICE[2] = SH_YunyouShopItemInfo2_Price;
	GOODS_PRICE[3] = SH_YunyouShopItemInfo3_Price;
	GOODS_PRICE[4] = SH_YunyouShopItemInfo4_Price;
	GOODS_PRICE[5] = SH_YunyouShopItemInfo5_Price;
	GOODS_PRICE[6] = SH_YunyouShopItemInfo6_Price;
	GOODS_PRICE[7] = SH_YunyouShopItemInfo7_Price;
	GOODS_PRICE[8] = SH_YunyouShopItemInfo8_Price;
	GOODS_PRICE[9] = SH_YunyouShopItemInfo9_Price;
	GOODS_PRICE[10]= SH_YunyouShopItemInfo10_Price;
	GOODS_PRICE[11]= SH_YunyouShopItemInfo11_Price;
	GOODS_PRICE[12]= SH_YunyouShopItemInfo12_Price;

	GOODS_MASK[1] = SH_YunyouShopItem1_Mask;
	GOODS_MASK[2] = SH_YunyouShopItem2_Mask;
	GOODS_MASK[3] = SH_YunyouShopItem3_Mask;
	GOODS_MASK[4] = SH_YunyouShopItem4_Mask;
	GOODS_MASK[5] = SH_YunyouShopItem5_Mask;
	GOODS_MASK[6] = SH_YunyouShopItem6_Mask;
	GOODS_MASK[7] = SH_YunyouShopItem7_Mask;
	GOODS_MASK[8] = SH_YunyouShopItem8_Mask;
	GOODS_MASK[9] = SH_YunyouShopItem9_Mask;
	GOODS_MASK[10]= SH_YunyouShopItem10_Mask;
	GOODS_MASK[11]= SH_YunyouShopItem11_Mask;
	GOODS_MASK[12]= SH_YunyouShopItem12_Mask;
	
	g_SH_YunyouSH_YunyouShopFrame_UnifiedPosition=SH_YunyouShopFrame:GetProperty("UnifiedPosition");
end

--===============================================
-- OnEvent
--===============================================
function SH_YunyouShop_OnEvent(event)
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		SH_YunyouShop_Close();
	end

	if ( event == "UI_COMMAND" ) then
		g_nTargetId = Get_XParam_INT(0)		--TargetId
		local isOpen = Get_XParam_INT(1)		--Open

		SH_YunyouShop_UpdatePage();
		if isOpen > 0 then
			this:Show();

			--关心商人Obj
			local objCared = Target:GetServerId2ClientId(g_nTargetId);
			this:CareObject(objCared, 1, "SH_YunyouShop");
		end
		
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end

		--如果和商人的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			--取消关心
			this:CareObject(objCared, 0, "SH_YunyouShop");
			this:Hide();
		end
	elseif (event == "ADJEST_UI_POS" ) then
		SH_YunyouShopFrame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		SH_YunyouShopFrame_On_ResetPos()
	end
end

--===============================================
-- UpdatePage
--===============================================
function SH_YunyouShop_UpdatePage()

	local nCount = Get_XParam_INT(2);
	
	g_SH_YunyouShop_Item = {};
	for i=1, nCount do
		g_SH_YunyouShop_Item[i] = {}
		g_SH_YunyouShop_Item[i].id 	= Get_XParam_INT(i*3);
		g_SH_YunyouShop_Item[i].price= Get_XParam_INT(i*3+1);
		g_SH_YunyouShop_Item[i].cnt = Get_XParam_INT(i*3+2);
	end

	i	= 1;
	while i <= GOODS_BUTTONS_NUM do
		local gGoodInfo = g_SH_YunyouShop_Item[i];
		if gGoodInfo ~= nil then
			local theAction = DataPool:CreateBindActionItemForShowWithMaxNum(gGoodInfo.id, 1, gGoodInfo.cnt)
		    if theAction:GetID() ~= 0 then
				GOODS_BUTTONS[i]:SetActionItem(theAction:GetID());
		    	GOODS_DESCS[i]:SetText( theAction:GetName() );
        	    GOODS_PRICE[i]:SetProperty("MoneyNumber", tostring(gGoodInfo.price))
				GOODS_PRICE[i]:Show();
				if gGoodInfo.cnt > 0 then
					GOODS_MASK[i]:Hide();
				else
					GOODS_MASK[i]:Show();
				end
			end
		else
			GOODS_BUTTONS[i]:SetActionItem(-1);
			GOODS_DESCS[i]:SetText("");
			GOODS_PRICE[i]:Hide();
			GOODS_MASK[i]:Hide();
		end
		i = i+1;
	end
end

--===============================================
-- Button_Clicked
--===============================================
function SH_YunyouShopItem_OnClicked(nIndex)
	if g_SH_YunyouShop_Item[nIndex] == nil then
		return
	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("OnBuyItem")
		Set_XSCRIPT_ScriptID(999420)
		Set_XSCRIPT_Parameter(0,g_nTargetId)
		Set_XSCRIPT_Parameter(1,nIndex)		
		Set_XSCRIPT_Parameter(2,g_SH_YunyouShop_Item[nIndex].id)		
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end

--===============================================
-- Close
--===============================================
function SH_YunyouShop_Close()
	--取消关心
	this:CareObject(objCared, 0, "SH_YunyouShop");
	this:Hide();
end

function SH_YunyouShopFrame_On_ResetPos()
  SH_YunyouShopFrame:SetProperty("UnifiedPosition", g_SH_YunyouSH_YunyouShopFrame_UnifiedPosition);
end
