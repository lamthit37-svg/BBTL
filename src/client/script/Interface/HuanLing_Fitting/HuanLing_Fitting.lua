
--试衣间类型总数 脚本中不要动
local TOTALFITTINGKIND_NUM = 10; 
local GOODS_CONTAINERTYPE_BY_NUM = 9;
local GOODS_CONTAINERTYPE_BY_STR = "fittingitemhuanling"

-- 界面的默认相对位置
local g_HuanLing_Fitting_Frame_UnifiedXPosition;
local g_HuanLing_Fitting_Frame_UnifiedYPosition;

local g_HuanlingID = -1;
local g_Camera_ClickNum = 3;
local g_HuanLing_Fitting_DistanceMin = 3;


local g_ReqQualText = 
{
	"#{HLYL_181229_16}", --无
	"#{HLYL_181229_21}", --戊
	"#{HLYL_181229_20}", --丁
	"#{HLYL_181229_19}", --丙
	"#{HLYL_181229_18}", --乙
	"#{HLYL_181229_17}", --甲   
}

--设置经典版使用的图片资源
local IconTable = {
	["H"] = "set:CommonFrame20 image:Item_Hot",
	["S"] = "set:CommonFrame20 image:Item_Special",
	["A"] = "set:CommonFrame20 image:Item_Activity",
	["D"] = "set:CommonFrame20 image:Item_Discount",
	["N"] = "set:CommonFrame20 image:Item_New",
	["L"] = "set:CommonFrame20 image:Item_Limit",
}


-- 0是站立休闲
local g_HuanLing_Fitting_ActionID = {1,2,4,162,163,164,0}

function HuanLing_Fitting_PreLoad()
	this:RegisterEvent("OPEN_SHOPHUANLINGREVIEW_DLG");
		--更新预览的物品
	this:RegisterEvent("FITTING_ROOM_UPDATEITEM");
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED");
	this:RegisterEvent("ADJEST_UI_POS");
	this:RegisterEvent("CLOSE_SHOP_FITTING");
end

function HuanLing_Fitting_OnLoad()
	if SystemSetup:IsClassic() == 0 then	--若客户端是唯美版，则重新设置图片素材为唯美版
		IconTable = {
		["H"] = "set:WM_CommonFrame1 image:Re",
		["S"] = "set:WM_CommonFrame1 image:Te",
		["A"] = "set:WM_CommonFrame1 image:Huo",
		["D"] = "set:WM_CommonFrame1 image:Zhe",
		["N"] = "set:WM_CommonFrame1 image:Xin",
		["L"] = "set:WM_CommonFrame1 image:Xian",
		}
	end
	g_HuanLing_Fitting_Frame_UnifiedXPosition	= HuanLing_Fitting_Frame : GetProperty("UnifiedXPosition");
	g_HuanLing_Fitting_Frame_UnifiedYPosition	= HuanLing_Fitting_Frame : GetProperty("UnifiedYPosition");

end

function HuanLing_Fitting_OnEvent(event)
	if (event == "OPEN_SHOPHUANLINGREVIEW_DLG") then
		g_HuanlingID = tonumber(arg0);
		if IsWindowShow("Shop_Fitting2") then
			CloseWindow("Shop_Fitting2", true);
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
		end
		if IsWindowShow("Shop_Fitting") then
			CloseWindow("Shop_Fitting", true);
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
		end
		if IsWindowShow("ShopPet_Fitting") then
			CloseWindow("ShopPet_Fitting",true);
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
		end
		HuanLing_Fitting_Init();
		this:Show();
	end

 	if (event == "FITTING_ROOM_UPDATEITEM") and this:IsVisible() then
		HuanLing_Fitting_Update();
	end

    if (event == "VIEW_RESOLUTION_CHANGED") then
		HuanLing_Fitting_Frame_On_ResetPos();
	elseif (event == "ADJEST_UI_POS") then
		HuanLing_Fitting_Frame_On_ResetPos();
	end

	if (event == "CLOSE_SHOP_FITTING") then
		this:Hide();
		RestoreShopFitting(TOTALFITTINGKIND_NUM);
		g_Camera_ClickNum = 3;
	end

end

function HuanLing_Fitting_Init()
	HuanLing_Fitting_Reset();
end

function HuanLing_Fitting_Reset()
	HuanLing_Fitting_DemandWuxingNum:SetText("");
	HuanLing_Fitting_DemandLingXingNum:SetText("");
	HuanLing_Fitting_DemandBianYiNum:SetText("");
	HuanLing_Fitting_DemandQualityNum:SetText("");
	HuanLing_Fitting_FakeObject:SetFakeObject("");
	HuanLing_Fitting_Item:SetActionItem(-1);
	HuanLing_Fitting_Info_YuanBao:SetText("");
	HuanLing_Fitting_Info_Name:SetText("");
	HuanLing_Fitting_ItemIcon:SetProperty("Image" , "")
	g_Camera_ClickNum = 3;
end

function HuanLing_Fitting_OnHiden()
	HuanLing_Fitting_Reset();
end



function HuanLing_Fitting_Update()
	if(g_HuanlingID < 0) then
		return
	end
	local nReqQuality = Pet:Lua_GetPetHuanLingInfo(g_HuanlingID,"Quality");
	--local strName = Pet:Lua_GetPetHuanLingInfo(g_HuanlingID,"Name");
	---local strIcon = Pet:Lua_GetPetHuanLingInfo(g_HuanlingID,"Icon");
	local nReqSavvy = Pet:Lua_GetPetHuanLingInfo(g_HuanlingID,"ReqSavvy");
	local nReqLing = Pet:Lua_GetPetHuanLingInfo(g_HuanlingID,"ReqLing");
	local nReqVLevel = Pet:Lua_GetPetHuanLingInfo(g_HuanlingID,"ReqVLevel");
	local strExText = Pet:Lua_GetPetHuanLingInfo(g_HuanlingID,"ExText");

	HuanLing_Fitting_Style:SetText(strExText);
	--HuanLing_Fitting_Info_Name:SetText("#gFF0FA0"..strName);
	local strReqSavvy = ScriptGlobal_Format("#{HLYL_181229_10}",tostring(nReqSavvy));
	HuanLing_Fitting_DemandWuxingNum:SetText(strReqSavvy);
	local strReqLing = ScriptGlobal_Format("#{HLYL_181229_11}",tostring(nReqLing));
	HuanLing_Fitting_DemandLingXingNum:SetText(strReqLing);
	if nReqVLevel == 0 then
		HuanLing_Fitting_DemandBianYiNum:SetText("#{HLYL_181229_14}");
	else
		local strReqVLevel = ScriptGlobal_Format("#{HLYL_181229_12}",tostring(nReqVLevel));
		HuanLing_Fitting_DemandBianYiNum:SetText(strReqVLevel);
	end
	if g_ReqQualText[nReqQuality] then
		HuanLing_Fitting_DemandQualityNum:SetText(g_ReqQualText[nReqQuality]);
	else
		HuanLing_Fitting_DemandQualityNum:SetText("");
	end
	HuanLing_Fitting_FakeObject:SetFakeObject("");
	Pet:Lua_UpdateShopPetHuanLingModel(g_HuanlingID);
	HuanLing_Fitting_FakeObject:SetFakeObject("ShopHuanLingPet");

	local theAction = EnumAction(0,GOODS_CONTAINERTYPE_BY_STR);
	if theAction:GetID() ~= 0 then
		local IconKey = theAction:GetItemIconInFittingRoom(GOODS_CONTAINERTYPE_BY_NUM);
		if IconKey ~= nil and IconKey ~= "" and IconTable[IconKey] ~= nil then
		HuanLing_Fitting_ItemIcon:SetProperty("Image" , IconTable[IconKey]);
		else
			HuanLing_Fitting_ItemIcon:SetProperty("Image" , "");
		end
		HuanLing_Fitting_Item:SetActionItem(theAction:GetID());
		local ItemColor = theAction:GetItemColorInFittingRoom(GOODS_CONTAINERTYPE_BY_NUM);
		if ItemColor ~="" then
			HuanLing_Fitting_Info_Name:SetText( ItemColor..theAction:GetName() );
		else
			HuanLing_Fitting_Info_Name:SetText( theAction:GetName() );
		end
		
	else
		HuanLing_Fitting_Item:SetActionItem(-1);
		HuanLing_Fitting_ItemIcon:SetProperty("Image" , "")
		HuanLing_Fitting_Info_Name:SetText("");
	end
	local nPrice = theAction:GetItemPriceInFittingRoom(GOODS_CONTAINERTYPE_BY_NUM);
	local strPrice = ScriptGlobal_Format("#{HLYL_181229_03}",tostring(nPrice));
	HuanLing_Fitting_Info_YuanBao:SetText("#cfff263"..strPrice);
end

function HuanLing_Fitting_Model_TurnLeft(start)
	--向左旋转开始
	if start == 1 and CEArg:GetValue("MouseButton")=="LeftButton" then
		HuanLing_Fitting_FakeObject:RotateBegin(-0.3);
	--向左旋转结束
	else
		HuanLing_Fitting_FakeObject:RotateEnd();
	end
end

function HuanLing_Fitting_Model_TurnRight(start)
	--向右旋转开始
	if start == 1 and CEArg:GetValue("MouseButton")=="LeftButton" then
		HuanLing_Fitting_FakeObject:RotateBegin(0.3);
	--向右旋转结束
	else
		HuanLing_Fitting_FakeObject:RotateEnd();
	end
end

function HuanLing_Fitting_Close_Clicked()
	this:Hide();
end

function HuanLing_Fitting_ClickedCameraCloser()
	if g_Camera_ClickNum <= 0 then
		return;
	end
	g_Camera_ClickNum = g_Camera_ClickNum - 1;
	FakeObj_ChangeCameraDistance("ShopHuanLingPet",1,0.6,g_HuanLing_Fitting_DistanceMin);
end

function HuanLing_Fitting_ClickedCameraFar()
	if g_Camera_ClickNum >= 3 then
		return;
	end
	g_Camera_ClickNum = g_Camera_ClickNum + 1;
	FakeObj_ChangeCameraDistance("ShopHuanLingPet",0,0.6,g_HuanLing_Fitting_DistanceMin);	
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function HuanLing_Fitting_Frame_On_ResetPos()

	HuanLing_Fitting_Frame : SetProperty("UnifiedXPosition", g_HuanLing_Fitting_Frame_UnifiedXPosition);
	HuanLing_Fitting_Frame : SetProperty("UnifiedYPosition", g_HuanLing_Fitting_Frame_UnifiedYPosition);

end

function HuanLing_Fitting_Buy_Clicked()
	if NpcShop:BuyItemWithOutConfirm() > 0 then
		NpcShop:BuyItemFromFittingRoom(GOODS_CONTAINERTYPE_BY_NUM,1);
	else
		PushEvent("FITTINGROOM_BUY_ITEM_CONFIRM", "close");
		local theAction = EnumAction(0,GOODS_CONTAINERTYPE_BY_STR);
		local nPrice = theAction:GetItemPriceInFittingRoom(GOODS_CONTAINERTYPE_BY_NUM);
		local nItemSourceShopUnit = theAction:GetItemSourceShopUnitInFittingRoom(GOODS_CONTAINERTYPE_BY_NUM);
		PushEvent( "FITTINGROOM_BUY_ITEM_CONFIRM", "open", GOODS_CONTAINERTYPE_BY_NUM, theAction:GetName(), nPrice, nItemSourceShopUnit);
	end
end

function HuanLing_Fitting_Action_Change(nIndex)
	local nActionID  = g_HuanLing_Fitting_ActionID[nIndex];
	if nActionID then
		DataPool:HuangLingView_ChangeAction(nActionID);
	end
end