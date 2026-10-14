local TOTALFITTINGKIND_NUM = 10;
local g_petNum = 0;
local g_CurSel = -1;
local g_Icon = "";
local g_ShopPet_Fitting_DistanceMin=3
local g_Camera_ClickNum =0

local Max_BtnNum = 10;
local PetNames = {
	"成年珍兽",
	"珍兽宝宝",
	"1级变异",
	"2级变异",
	"3级变异",
	"4级变异",
	"5级变异",
	"6级变异",
	"7级变异",
	"8级变异",
};

--设置经典版使用的图片资源
local IconTable = {
	["H"] = "set:CommonFrame20 image:Item_Hot",
	["S"] = "set:CommonFrame20 image:Item_Special",
	["A"] = "set:CommonFrame20 image:Item_Activity",
	["D"] = "set:CommonFrame20 image:Item_Discount",
	["N"] = "set:CommonFrame20 image:Item_New",
	["L"] = "set:CommonFrame20 image:Item_Limit",
}

local g_ShopPet_Fitting_ShopUnitID = {
		YuanBao = 5,
		VipShop = 1111,		--待修改
		GiftToken = 10,
}
local g_ShopPet_Fitting_ActionID={0,1,2,4,162,163,164}

local GOODS_CONTAINERTYPEBYSTR = "fittingitemhairpetegg"
local GOODS_CONTAINERTYPE_BY_NUM = 4
-- 界面的默认相对位置
local g_ShopPet_Fitting_Frame_UnifiedXPosition;
local g_ShopPet_Fitting_Frame_UnifiedYPosition;

function ShopPet_Fitting_PreLoad()
	this:RegisterEvent("OPEN_PETSHOPPREVIEW_DLG");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	--更新预览的物品
	this:RegisterEvent("FITTING_ROOM_UPDATEITEM")

	--关闭试穿状态
	this:RegisterEvent("CLOSE_SHOP_FITTING")
	
	this:RegisterEvent("FAKEOBJ_MODEL_CHANGE", false)
end

function ShopPet_Fitting_OnLoad()
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
	-- 保存界面的默认相对位置
	g_ShopPet_Fitting_Frame_UnifiedXPosition	= ShopPet_Fitting_Frame : GetProperty("UnifiedXPosition");
	g_ShopPet_Fitting_Frame_UnifiedYPosition	= ShopPet_Fitting_Frame : GetProperty("UnifiedYPosition");

end

function ShopPet_Fitting_OnEvent(event)
	if ( event == "OPEN_PETSHOPPREVIEW_DLG" ) then
		if IsWindowShow("Shop_Fitting2") then
			CloseWindow("Shop_Fitting2", true);
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
		end
		if IsWindowShow("Shop_Fitting") then
			CloseWindow("Shop_Fitting", true);
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
		end
		if IsWindowShow("HuanLing_Fitting") then
			CloseWindow("HuanLing_Fitting", true);
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
		end
		ShopPet_Fitting_FakeObject : AttachWindowEx("PetOneType_ShopView");
		ShopPet_Fitting_Init()
		this:Show();
	end
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide();
		g_petNum = 0;
		g_CurSel = -1;
		g_Icon = "";
		g_Camera_ClickNum = 0
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		ShopPet_Fitting_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		ShopPet_Fitting_Frame_On_ResetPos()
	end

	if event == "FITTING_ROOM_UPDATEITEM" then

		ShopPet_Fitting_UpdateItemList()
	end

	if event == "CLOSE_SHOP_FITTING" then
		this:Hide();
		RestoreShopFitting(TOTALFITTINGKIND_NUM);
		g_Camera_ClickNum=0
	end
	
	if event == "FAKEOBJ_MODEL_CHANGE" then
		Update_FakeObj_Camera()
	end

end

function ShopPet_Fitting_UpdateItemList()
	local theAction = EnumAction(0, GOODS_CONTAINERTYPEBYSTR);
	if theAction:GetID() ~= 0 then
		local IconKey = theAction:GetItemIconInFittingRoom(GOODS_CONTAINERTYPE_BY_NUM)
		if IconKey ~= nil and IconKey ~= "" and IconTable[IconKey] ~= nil then
			ShopPet_Fitting_PetItemIcon:SetProperty("Image" , IconTable[IconKey])
		else
			ShopPet_Fitting_PetItemIcon:SetProperty("Image" , "")
		end

		ShopPet_Fitting_PetItem:SetActionItem(theAction:GetID());

		if(theAction:GetItemColorInFittingRoom(GOODS_CONTAINERTYPE_BY_NUM) ~= "") then
			ShopPet_Fitting_PetInfo_Text:SetText( theAction:GetItemColorInFittingRoom(GOODS_CONTAINERTYPE_BY_NUM)..theAction:GetName() );
		else
			ShopPet_Fitting_PetInfo_Text:SetText( theAction:GetName() );
		end

		local	nPrice	= theAction:GetItemPriceInFittingRoom( GOODS_CONTAINERTYPE_BY_NUM )
		local 	nItemSourceShopUnit = theAction:GetItemSourceShopUnitInFittingRoom( GOODS_CONTAINERTYPE_BY_NUM )
		if (nItemSourceShopUnit == g_ShopPet_Fitting_ShopUnitID.YuanBao) then
			ShopPet_Fitting_DragTitle:SetText("#{FFSDGZ_120615_10}")
			ShopPet_Fitting_PetInfo_GB:SetText("#cfff263".."#{YBSD_081225_101}" .. tostring(nPrice))
		elseif (nItemSourceShopUnit == g_ShopPet_Fitting_ShopUnitID.VipShop) then
			ShopPet_Fitting_PetInfo_GB:SetText("#cfff263".."#{YBSD_081225_101}" .. tostring(nPrice))
			ShopPet_Fitting_DragTitle:SetText("#{FFSDGZ_120615_12}")
		elseif (nItemSourceShopUnit == g_ShopPet_Fitting_ShopUnitID.GiftToken) then
			ShopPet_Fitting_PetInfo_GB:SetText("#cfff263".."#{YBFQ_XML_1}" .. tostring(nPrice))
			ShopPet_Fitting_DragTitle:SetText("#{FFSDGZ_120615_11}")
		end

	else
		ShopPet_Fitting_PetItemIcon:SetProperty("Image" , "")
		ShopPet_Fitting_PetItem:SetActionItem(-1);
		ShopPet_Fitting_PetInfo_Text:SetText("");
		ShopPet_Fitting_PetInfo_GB:SetText("");
	end
end

function ShopPet_Fitting_Init()
	local nIsBaiShou = Pet:GetIsBaiShou()
	if(nIsBaiShou == 1) then
		ShopPet_Proficient_Text:Show()
	else
		ShopPet_Proficient_Text:Hide()
	end
	ShopPet_Fitting_TujianList : ClearListBox();
	g_petNum = DataPool:GetPetsShopPreViewNum();
	g_CurSel = -1;
	if(Max_BtnNum <  g_petNum) then
		g_petNum = Max_BtnNum;
	end
	--------------------------------------------------
	for i = 1 , g_petNum do
		--珍兽界面
		ShopPet_Fitting_TujianList : AddItem(PetNames[i], i-1);
	end
	local nIndex = g_petNum;
	--默认选中最后一

	--没有原始外观 又 点了选中原始外观的BT情况
	if(g_petNum < nIndex) then
		nIndex = 1
	end

	ShopPet_Fitting_TujianList : SetItemSelectByItemID(0);
	ShopPet_Fitting_SelectOneType(1);
end

function ShopPet_Fitting_Onshow()
	---------------------------------------------------------
	--DisableSomeThing
	
	local ret = 0
	ShopPet_Fitting_FoodType   : Hide();
	ShopPet_Fitting_Type : Hide();
	ShopPet_Fitting_NeedLevel  : Hide();
	ShopPet_Proficient_Text:Hide()
	ShopPet_Fitting_Model_TurnLeft : Disable();
	ShopPet_Fitting_Model_TurnRight: Disable();
	g_Camera_ClickNum = 0

	if(g_CurSel < 0 or g_petNum <= 0)then
		return ret;
	end
	
	ret = DataPool : PetsShopView_SetModel(g_CurSel);
	---------------------------------------------------------------------
	ShopPet_Fitting_ChangePetAction(0)
	ShopPet_Fitting_Model_TurnLeft : Enable();
	ShopPet_Fitting_Model_TurnRight: Enable();
	ShopPet_Fitting_NeedLevel      : Show();
	---------------------------------------------------
	--get TakeLevel
	local nTakeLevel = DataPool : PetsShopPreView_GetAttr(g_CurSel,"takelevel");
	local strNeedLevelColor = "";
	local nTakeLevel_BaiShou = nTakeLevel
	local nIsBaiShou = Pet:GetIsBaiShou()
	if(nIsBaiShou == 1) then
		nTakeLevel_BaiShou = nTakeLevel - 10
	    if nTakeLevel_BaiShou < 1 then
			nTakeLevel_BaiShou = 1
		end
	end
	if( nTakeLevel_BaiShou > Player:GetData( "LEVEL" ) )then
		strNeedLevelColor ="#cFF0000";
	else
		strNeedLevelColor ="#c00FF00";
	end
	local strNeedLevel = strNeedLevelColor..tostring( nTakeLevel ).."级#W可携带";
	ShopPet_Fitting_NeedLevel:SetText( strNeedLevel );
	-----------------------------------------------------
	if(nIsBaiShou == 1) then
		ShopPet_Proficient_Text:Show()
	end
	--get AttackTrait (暂缺)
	strName,strIcon = DataPool : PetsShopPreView_GetAttr(g_CurSel,"attacktype");
	if strIcon ~= "" then
		ShopPet_Fitting_Type : SetProperty( "Image", "set:Button6 image:"..strIcon )
		ShopPet_Fitting_Type : SetToolTip(strName)
		ShopPet_Fitting_Type : Show();
	end
	-----------------------------------------------------
	--get FoodType
	local food = DataPool : PetsShopPreView_GetAttr(g_CurSel,"food");
	strName = "";
	if(food >= 1000) then
		strName = strName .. "肉";
		food = food - 1000;
		if food > 0 then
			strName = strName .. ",";
		end
	end
	if(food >= 100) then
		strName = strName .. "草";
		food = food - 100;
		if food > 0 then
			strName = strName .. ",";
		end
	end
	if(food >= 10) then
		strName = strName .. "虫";
		food = food - 10;
		if food > 0 then
			strName = strName .. ",";
		end
	end

	if(food >= 1) then
		strName = strName .. "谷";
	end


	ShopPet_Fitting_FoodType : Show();
	ShopPet_Fitting_FoodType : SetToolTip( strName );

	_,g_ShopPet_Fitting_DistanceMin,_ = FakeObj_GetCamera("PetOneType_ShopView")
	
	return ret
end

function ShopPet_Fitting_SelectOneType(typeIdx)
	if(g_CurSel + 1 == typeIdx or typeIdx < 1 or typeIdx > g_petNum) then
		return;
	end
	g_CurSel = typeIdx - 1;
	g_Camera_ClickNum = 0
	local ret = ShopPet_Fitting_Onshow();
	if ret > 0 and SystemSetup:IsClassic() == 1 then
		ShopPet_Fitting_FakeObject : RestPositonEx()
		ShopPet_Fitting_FakeObject : ChangeCameraDistanceEx("PetOneType_ShopView", 0, 1.8)
		--FakeObj_ChangeCameraDistance( "PetOneType_ShopView",0,1.8,3)
		g_Camera_ClickNum = 3
	end
end

function ShopPet_Fitting_TujianList_Click()
	local typeIdx =  ShopPet_Fitting_TujianList : GetFirstSelectItem();
	ShopPet_Fitting_SelectOneType(typeIdx + 1);
end

----------------------------------------------------------------------------------
--
-- 旋转珍兽模型（向左)
--
function ShopPet_Fitting_Modle_TurnLeft(start)
	--向左旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		ShopPet_Fitting_FakeObject:RotateBeginEx("PetOneType_ShopView", -0.3);
	--向左旋转结束
	else
		ShopPet_Fitting_FakeObject:RotateEndEx();
	end
end

----------------------------------------------------------------------------------
--
--旋转珍兽模型（向右)
--
function ShopPet_Fitting_Modle_TurnRight(start)
	--向右旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		ShopPet_Fitting_FakeObject:RotateBeginEx("PetOneType_ShopView", 0.3);
	--向右旋转结束
	else
		ShopPet_Fitting_FakeObject:RotateEndEx();
	end
end

function ShopPet_Fitting_OnHiden()
	PushEvent( "FITTINGROOM_BUY_ITEM_CONFIRM", "close")
	ShopPet_Fitting_FakeObject : DetachWindowEx("PetOneType_ShopView");
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ShopPet_Fitting_Frame_On_ResetPos()

	ShopPet_Fitting_Frame : SetProperty("UnifiedXPosition", g_ShopPet_Fitting_Frame_UnifiedXPosition);
	ShopPet_Fitting_Frame : SetProperty("UnifiedYPosition", g_ShopPet_Fitting_Frame_UnifiedYPosition);

end

function ShopPet_Fitting_Buy_Clicked(nIndex)
	if NpcShop:BuyItemWithOutConfirm() > 0 then
		NpcShop:BuyItemFromFittingRoom(GOODS_CONTAINERTYPE_BY_NUM, 1)
	else
		PushEvent( "FITTINGROOM_BUY_ITEM_CONFIRM", "close")
		local theAction = EnumAction(0, GOODS_CONTAINERTYPEBYSTR);
		local	nPrice	= theAction:GetItemPriceInFittingRoom( GOODS_CONTAINERTYPE_BY_NUM )
		local 	nItemSourceShopUnit = theAction:GetItemSourceShopUnitInFittingRoom( GOODS_CONTAINERTYPE_BY_NUM )
		PushEvent( "FITTINGROOM_BUY_ITEM_CONFIRM", "open", GOODS_CONTAINERTYPE_BY_NUM, theAction:GetName(), nPrice, nItemSourceShopUnit)
	end
end

function ShopPet_Fitting_Close_Clicked()
	this:Hide()
end

function ShopPet_Fitting_ChangePetAction( nIndex )
	local Mark = 0
	for i=1,table.getn(g_ShopPet_Fitting_ActionID) do
		if nIndex == g_ShopPet_Fitting_ActionID[i] then
			Mark = 1
			break
		end
	end
	if Mark == 1 then
		DataPool:PetShopView_ChangeAction(nIndex)
	end
end

function ShopPet_Fitting_ChickCameraFar()
	if g_Camera_ClickNum >=3 then
		return
	end
	g_Camera_ClickNum = g_Camera_ClickNum+1
	ShopPet_Fitting_FakeObject : ChangeCameraDistanceEx("PetOneType_ShopView", 0, 0.6)
	--FakeObj_ChangeCameraDistance( "PetOneType_ShopView",0,0.6,g_ShopPet_Fitting_DistanceMin)
end

function ShopPet_Fitting_ChickCameraClose()
	if g_Camera_ClickNum <= 0 then
		return
	end
	g_Camera_ClickNum = g_Camera_ClickNum-1
	ShopPet_Fitting_FakeObject : ChangeCameraDistanceEx("PetOneType_ShopView", 1, 0.6)
	--FakeObj_ChangeCameraDistance( "PetOneType_ShopView",1,0.6,g_ShopPet_Fitting_DistanceMin)
end

function Update_FakeObj_Camera()
	if( not this:IsVisible() ) then
		return
	end
	-- 调整珍兽大小 先放这儿吧
	local modelid = DataPool : PetsShopPreView_GetAttr(g_CurSel,"modelid")
	if modelid<=29449 and modelid>=29440 then
		
		local fh, fd, fp = ShopPet_Fitting_FakeObject:GetCameraEx()
		fd = 7
		ShopPet_Fitting_FakeObject:SetCameraEx(fh, fd, fp)
	end
end
