local TOTALFITTINGKIND_NUM = 10;
local objCared = -1;

local g_CameraHeight = 1;     --摄影机高度
local g_CameraDistance = 2;   --摄影机距离
local g_CameraPitch = 3;      --摄影机角度

-- 需要为一些在坐骑上的试穿效果单独设置摄像机位置

local g_MountXueYuID = 39;	--座骑雪羽的id
local g_MountMingYuID = 44;	--座骑冥羽的id
local g_MountHuanYuID = 62;	--座骑幻羽的id
local g_MountJuYuanID = 52;	--座骑巨猿的id
local g_MountDaFengID = 41; --座骑大风的id
--local g_MountLingWuID = 221;	--灵物雀羽
--local g_MountLiuLiID = 22; --琉璃雀羽id

--TT78319 向下
local g_MountKuMuKuiLeiID = 76; --坐骑枯木傀儡的id
local g_MountHuoYunXieShouID = 77; --坐骑火云邪兽的id
local g_MountXuanZhuanMuMa = 47; --旋转木马
local g_MountFeiLongYi = 69; --飞龙椅
--TT78319 向上
local g_MountJiuZhouShenLong = 79; --九州神龙ID
--鹤，金翼鹤，瑞莲鹤
local g_MountWuDang = {5,14,55}
--雕，白雕，鹜影雕
local g_MountTianShan = {3,12,53}
--青凤，红白凤，琉璃凤
local g_MountEMei = {6,15,54}

--赤魅鹰,暗魅鹰,紫魅鹰
local g_MountAFanDa = {73,74,75}
local g_YanYuQingHe = 83 --烟雨清荷
local g_HuanHuoShou = 84 --幻火赤麟兽
local g_LuXingNiao = 88 --陆行鸟
local g_MountJiJu = 90--寄居蟹


local g_HongMeiRuanJia = 165 --红梅软架

local g_MountQiBaoLianZuoID = 91	--坐骑：七宝莲座
local g_MountChiLinBaiZeID 	= 92	--坐骑：赤麟白泽
local g_MountQingLinBaiZeID = 93	--坐骑：青麟白泽
local g_MountMouse = 87
local g_MountGoldenWing = 94 -- 坐骑：金翅
local g_MountFlyDaFeng = 151 --飞行大风
local g_MountGoldenWing_BLUE = 153 -- 蓝色坐骑：金翅
local g_MountGoldenWing_GREEN = 154 -- 青色坐骑：金翅

local g_MountTHLingQue = 172 --天河灵鹊
local g_MountXingHongYunZhou = 179 --星虹云舟
local g_MountAnYanMingShi = 180 --暗炎冥狮

local g_Shop_Fitting2_Frame_UnifiedPosition;

local GOODS_TOTAL_NUM = 7;
local GOODS_BUTTONS = {};
local GOODS_PREVIEW_STATUS = {};
local GOODS_BUTTONS_ICON = {};

local g_SwitchFlag = 0
local g_Shop_Fitting2_CurDressID=0

--设置经典版使用的图片资源
local IconTable = {
	["H"] = "set:CommonFrame20 image:Item_Hot",
	["S"] = "set:CommonFrame20 image:Item_Special",
	["A"] = "set:CommonFrame20 image:Item_Activity",
	["D"] = "set:CommonFrame20 image:Item_Discount",
	["N"] = "set:CommonFrame20 image:Item_New",
	["L"] = "set:CommonFrame20 image:Item_Limit",
}
local FITTING_TYPE_KIND =
{
	fittingitemhair = 3,
	fittingitemface = 2,
	fittingitemdress = 0,
	fittingitemrider = 1,
	fittingitempet = 4,
	fittingitemgemshoulder = 6,
	fittingitemgemwaist = 7,
	fittingitemgemfeet = 8,
	
}
local GOODS_CONTAINERTYPE = {
		"fittingitemhairstyle",
		"fittingitemfacestyle",
		"fittingitemdress",
		"fittingitemhorse",
		"fittingitemshoulder",
		"fittingitemwaist",
		"fittingitemfeet",
		
}
--这个table标明程序中enum的顺序
local GOODS_CONTAINERTYPE_BY_NUM = {
		3,
		2,
		0,
		1,
		6,
		7,
		8,
		9,		--预览池的大小
}
local GOODS_DESCS = {};
local GOODS_BUY_BTN = {};
local GOODS_FITTING_CTL_BTN = {};
local GOOD_BAD = {};


local ShopUnitID = {
		YuanBao = 5,
		GiftToken = 10,
		BindYuanBao = 9,
		ShowCredit = 14,
}
--对应于containertype中的顺序
local PreViewStatus = {
	0,
	0,
	0,
	0,
}

local Shop_Fitting2_CameraLevel = 0
local Shop_Fitting2_CameraPosition =
{
	--女性相关位置
	[0] = { 
				[0] = { fHeight = 0.95, fDistance = 5.4, fPitch = 0.28, XOffset = 0 },
				[1] = { fHeight = 1.55, fDistance = 2, fPitch = 0.28, XOffset = 0 },
				[2] = { fHeight = 1.65, fDistance = 1.2, fPitch = 0.28, XOffset = 0 }, 
			},
			
	--男性相关位置
	[1] = {
				[0] = { fHeight = 1,	fDistance = 6, fPitch = 0.28, XOffset = 0 },
				[1] = { fHeight = 1.65,	fDistance = 2.2, fPitch = 0.28, XOffset = 0 },
				[2] = { fHeight = 1.82,	fDistance = 1.2, fPitch = 0.28, XOffset = 0 },
			},
}  


local Shop_Fitting2_CameraPosition_IV =
{
	--女性相关位置
	[0] = { 
				[0] = { fHeight = 0.95, fDistance = 5.4, fPitch = 0.13, XOffset = 0 },
				[1] = { fHeight = 1.55, fDistance = 2, fPitch = 0.13, XOffset = 0 },
				[2] = { fHeight = 1.65, fDistance = 1.2, fPitch = 0.13, XOffset = 0 }, 
			},
			
	--男性相关位置
	[1] = {
				[0] = { fHeight = 1,	fDistance = 6, fPitch = 0.13, XOffset = 0 },
				[1] = { fHeight = 1.70,	fDistance = 2.2, fPitch = 0.13, XOffset = 0 },
				[2] = { fHeight = 1.82,	fDistance = 1.2, fPitch = 0.13, XOffset = 0 },
			},
}  


function Shop_Fitting2_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("OPEN_YB_SHOP_FITTING");
	this:RegisterEvent("OPEN_SHOP_FITTING")
	this:RegisterEvent("CLOSE_SHOP_FITTING");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("SEX_CHANGED");

	-- FakeObject模型界面互斥
	this:RegisterEvent("OPEN_EQUIP");										-- 角色资料界面
	this:RegisterEvent("OPEN_DRESS_PAINT_FITTING");			-- 时装染色试衣间
	this:RegisterEvent("OPEN_DRESS_ENCHASE_FITTING");		-- 时装镶嵌试衣间
	this:RegisterEvent("YIGUI_OPEN");				-- 衣柜
	this:RegisterEvent("UI_COMMAND");				-- 变性
	this:RegisterEvent("FASHION_DEPOT_OP", false);				-- 华裳阁
	this:RegisterEvent("FEIYUSHOW_WINDOW", false)
	this:RegisterEvent("OPEN_SPECIALDRESSPAINT", false)


	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("FITTING_ROOM_UPDATEITEM")

	this:RegisterEvent("UPDATE_FAKE_OBJECT")
	this:RegisterEvent("DRESS_FIT_PAGE_SWITCH")
	this:RegisterEvent("YUANBAOSHOP_FITTING_RESET")
end

function Shop_Fitting2_OnLoad()
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


	GOODS_BUTTONS[1] = Shop_Fitting2_HairItem;
	GOODS_BUTTONS[2] = Shop_Fitting2_FaceItem;
	GOODS_BUTTONS[3] = Shop_Fitting2_DressItem;
	GOODS_BUTTONS[4] = Shop_Fitting2_RideItem;
	GOODS_BUTTONS[5] = Shop_Fitting2_ShouderItem;
	GOODS_BUTTONS[6] = Shop_Fitting2_WaistItem;
	GOODS_BUTTONS[7] = Shop_Fitting2_FootItem;

	GOODS_BUTTONS_ICON[1] = Shop_Fitting2_HairItemIcon;
	GOODS_BUTTONS_ICON[2] = Shop_Fitting2_FaceItemIcon;
	GOODS_BUTTONS_ICON[3] = Shop_Fitting2_DressItemIcon;
	GOODS_BUTTONS_ICON[4] = Shop_Fitting2_RideItemIcon;
	GOODS_BUTTONS_ICON[5] = Shop_Fitting2_ShouderItemIcon;
	GOODS_BUTTONS_ICON[6] = Shop_Fitting2_WaistItemIcon;
	GOODS_BUTTONS_ICON[7] = Shop_Fitting2_FootItemIcon;
		

	GOODS_DESCS[1] = Shop_Fitting2_HairInfo_Text;
	GOODS_DESCS[2] = Shop_Fitting2_FaceInfo_Text;
	GOODS_DESCS[3] = Shop_Fitting2_DressInfo_Text;
	GOODS_DESCS[4] = Shop_Fitting2_RideInfo_Text;
	GOODS_DESCS[5] = Shop_Fitting2_ShouderInfo_Text;
	GOODS_DESCS[6] = Shop_Fitting2_WaistInfo_Text;
	GOODS_DESCS[7] = Shop_Fitting2_FootInfo_Text;

	GOOD_BAD[1]  =     Shop_Fitting2_HairInfo_GB;
	GOOD_BAD[2]  =     Shop_Fitting2_FaceInfo_GB;
	GOOD_BAD[3]  =     Shop_Fitting2_DressInfo_GB;
	GOOD_BAD[4]  =     Shop_Fitting2_RideInfo_GB;
	GOOD_BAD[5]  =     Shop_Fitting2_ShouderInfo_GB;
	GOOD_BAD[6]  =     Shop_Fitting2_WaistInfo_GB;
	GOOD_BAD[7]  =     Shop_Fitting2_FootInfo_GB;

	GOODS_BUY_BTN[1] = Shop_Fitting2_HairBuy;
	GOODS_BUY_BTN[2] = Shop_Fitting2_FaceBuy;
	GOODS_BUY_BTN[3] = Shop_Fitting2_DressBuy;
	GOODS_BUY_BTN[4] = Shop_Fitting2_RideBuy;
	GOODS_BUY_BTN[5] = Shop_Fitting2_ShouderBuy;
	GOODS_BUY_BTN[6] = Shop_Fitting2_WaistBuy;
	GOODS_BUY_BTN[7] = Shop_Fitting2_FootBuy;
	

	GOODS_FITTING_CTL_BTN[1] = Shop_Fitting2_HairTry;
	GOODS_FITTING_CTL_BTN[2] = Shop_Fitting2_FaceTry;
	GOODS_FITTING_CTL_BTN[3] = Shop_Fitting2_DressTry;
	GOODS_FITTING_CTL_BTN[4] = Shop_Fitting2_RideTry;
	GOODS_FITTING_CTL_BTN[5] = Shop_Fitting2_ShouderTry;
	GOODS_FITTING_CTL_BTN[6] = Shop_Fitting2_WaistTry;
	GOODS_FITTING_CTL_BTN[7] = Shop_Fitting2_FootTry;
	

	GOODS_PREVIEW_STATUS[1] = Shop_Fitting2_HairIcon;
	GOODS_PREVIEW_STATUS[2] = Shop_Fitting2_FaceIcon;
	GOODS_PREVIEW_STATUS[3] = Shop_Fitting2_DressIcon;
	GOODS_PREVIEW_STATUS[4] = Shop_Fitting2_RideIcon;
	GOODS_PREVIEW_STATUS[5] = Shop_Fitting2_ShouderIcon;
	GOODS_PREVIEW_STATUS[6] = Shop_Fitting2_WaistIcon;
	GOODS_PREVIEW_STATUS[7] = Shop_Fitting2_FootIcon

	GOODS_PREVIEW_STATUS[1]:Hide()
	GOODS_PREVIEW_STATUS[2]:Hide()
	GOODS_PREVIEW_STATUS[3]:Hide()
	GOODS_PREVIEW_STATUS[4]:Hide()
	GOODS_PREVIEW_STATUS[5]:Hide()
	GOODS_PREVIEW_STATUS[6]:Hide()
	GOODS_PREVIEW_STATUS[7]:Hide()
	
	g_Shop_Fitting2_Frame_UnifiedPosition= Shop_Fitting2_Frame:GetProperty("UnifiedPosition");

end


function Shop_Fitting2_OnHiden()
	Shop_Fitting2_FakeObject:SetFakeObject("")
	Shop_Fitting2_CameraLevel = 0
	
	if g_SwitchFlag == 0 then
		RestoreShopFitting(TOTALFITTINGKIND_NUM);
		ChangeShopFittingRaceID(GetMySelfRaceId())
		Infant:ClearInfantFittingData()
	else
		g_SwitchFlag = 0
	end
	PushEvent( "FITTINGROOM_BUY_ITEM_CONFIRM", "close")
end

function Shop_Fitting2_OnEvent(event)
	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Shop_Fitting2_Booth_Close();
	end

	-- FakeObject模型界面互斥
	if ( event == "OPEN_EQUIP" ) or												-- 角色资料界面
		(event == "OPEN_SHOP_FITTING") or				--普通商店试衣间
		 ( event == "OPEN_DRESS_PAINT_FITTING" ) or					-- 时装染色试衣间
		 ( event == "OPEN_DRESS_ENCHASE_FITTING" ) or	-- 时装镶嵌试衣间
		 ( event == "YIGUI_OPEN") or			-- 衣柜
		 ((event == "UI_COMMAND" and tonumber(arg0) == 20120406)) or --变性
		 ( event == "UI_COMMAND" and tonumber(arg0) == 120203161 ) or  -- 时装预览
		 (event == "FASHION_DEPOT_OP" and tonumber(arg0) == 1) or --华裳阁
		 (event == "FEIYUSHOW_WINDOW" and tonumber(arg0) >= 0) or
		 (event == "UI_COMMAND" and tonumber(arg0) == 2024082101) or
		 (event == "OPEN_SPECIALDRESSPAINT" and tonumber(arg0) >= 0) then
		if (this:IsVisible()) then
			this:Hide();
			g_CurentRideFitFlag = 0
			RestoreShopFitting(TOTALFITTINGKIND_NUM)
		end
	end

	local bSwitchTo = 0
	if event == "DRESS_FIT_PAGE_SWITCH" then
		if tonumber(arg0) and tonumber(arg0) == 0 then
			bSwitchTo = 1
			Shop_Fitting2_Frame:SetProperty("UnifiedPosition",arg1)
		end
	end


	if event == "OPEN_YB_SHOP_FITTING" or bSwitchTo == 1 then
		local szcmd = arg0
		local bOnlyRefresh = 0
		if szcmd ~= nil and szcmd == "onlyrefresh" then
			bOnlyRefresh = 1
		end

		if event == "OPEN_YB_SHOP_FITTING" and IsWindowShow("Shop_InfantFitting") then
			bOnlyRefresh = 1
		end
		
		PushEvent( "CLOSE_DRESSPREVIEW") 
		PushEvent( "CLOSE_GEMEFFECTPREVIEW") 

		if bOnlyRefresh == 0 then
			if IsWindowShow("ShopPet_Fitting") then
				CloseWindow("ShopPet_Fitting", true);
			end
			if(IsWindowShow("Shop_Fitting")) then
				CloseWindow("Shop_Fitting", true);
			end
			if(IsWindowShow("HuanLing_Fitting")) then
				CloseWindow("HuanLing_Fitting", true);
			end
			this:Show();
		end 
		if bSwitchTo == 1 then
		
			Shop_Fitting2_UpdateItemList()
		end

		Shop_Fitting2_FakeObject:SetFakeObject("");

		if this:IsVisible() then
			Shop_Fitting2_CheckUI()
			objCared = NpcShop:GetNpcId();
			this:CareObject(objCared, 1, "Shop_Fitting2");
		end

		UpdateUIStatuts()
		local nMountID = GetMountID();
		FitMountCamera(nMountID)

		if this:IsVisible() then
			Shop_Fitting2_FakeObject:SetFakeObject("EquipChange_Player");
			Shop_Fitting2_setCameraPosition()
			local nMountID = GetMountID();
			FitMountCamera(nMountID)
		end

	end

	if(event == "UPDATE_FAKE_OBJECT" ) then
		if( arg0 == "EquipChange_Player" ) and this:IsVisible() then
			Shop_Fitting2_FakeObject : Hide()
			Shop_Fitting2_FakeObject : Show()
			Shop_Fitting2_FakeObject:SetFakeObject("EquipChange_Player")
			Shop_Fitting2_setCameraPosition()

			local nMountID = GetMountID()
			FitMountCamera(nMountID)
		end
	end

	if(event == "CLOSE_SHOP_FITTING") then
		g_CurentRideFitFlag = 0
		this:Hide();
		RestoreShopFitting(TOTALFITTINGKIND_NUM);
	end

	if (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end

		--如果和商人的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			--取消关心
			this:CareObject(objCared, 0, "Shop_Fitting2");
			this:Hide();
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
		end
	end

	if event == "SEX_CHANGED" and  this:IsVisible() then
		Shop_Fitting2_FakeObject : Hide();
		Shop_Fitting2_FakeObject : Show();
		Shop_Fitting2_FakeObject:SetFakeObject("EquipChange_Player");
		Shop_Fitting2_setCameraPosition()

		local nMountID = GetMountID();
		FitMountCamera(nMountID)

	end

	if (event == "ADJEST_UI_POS" ) then
		Shop_Fitting2_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Shop_Fitting2_Frame_On_ResetPos()
	elseif (event == "FITTING_ROOM_UPDATEITEM" and this:IsVisible()) then 
		Shop_Fitting2_UpdateItemList()
	end

	if (event =="YUANBAOSHOP_FITTING_RESET") then
		g_Shop_Fitting2_CurDressID = 0
	end

end
function Shop_Fitting2_UpdateItemList()
	GOOD_BAD[1]  =     Shop_Fitting2_HairInfo_GB;
	GOOD_BAD[2]  =     Shop_Fitting2_FaceInfo_GB;
	GOOD_BAD[3]  =     Shop_Fitting2_DressInfo_GB;
	GOOD_BAD[4]  =     Shop_Fitting2_RideInfo_GB;
	GOOD_BAD[5]  =     Shop_Fitting2_ShouderInfo_GB; 
	GOOD_BAD[6]  =     Shop_Fitting2_WaistInfo_GB;
	GOOD_BAD[7]  =     Shop_Fitting2_FootInfo_GB;

	local i = 1
	while i <= GOODS_TOTAL_NUM do
		--PushDebugMessage("FITTING_ROOM_UPDATEITEM-----i"..i)
		local theAction = EnumAction(0, GOODS_CONTAINERTYPE[i]);
		
		if theAction:GetID() ~= 0 then  
		
			local IconKey = theAction:GetItemIconInFittingRoom(GOODS_CONTAINERTYPE_BY_NUM[i])
			if IconKey ~= nil and IconKey ~= "" and IconTable[IconKey] ~= nil then
				GOODS_BUTTONS_ICON[i]:SetProperty("Image" , IconTable[IconKey])
			else
				GOODS_BUTTONS_ICON[i]:SetProperty("Image" , "")
			end
			if i == 3 then
				local itemTableIndex = theAction:GetItemTableIndex()
				local bret = Infant:GetDressConvertInfo(itemTableIndex)
				if bret and bret == 1 then
					Shop_Fitting2_InfantButton:Enable()
				end
				Shop_Fitting2_UpdateComboList(theAction:GetItemTableIndex())
			end 
			GOODS_BUTTONS[i]:SetActionItem(theAction:GetID());
			GOODS_BUY_BTN[i]:Enable()
			GOODS_FITTING_CTL_BTN[i]:Show()
			if(theAction:GetItemColorInFittingRoom(GOODS_CONTAINERTYPE_BY_NUM[i]) ~= "") then
				GOODS_DESCS[i]:SetText( theAction:GetItemColorInFittingRoom(GOODS_CONTAINERTYPE_BY_NUM[i])..theAction:GetName() );
			else
				GOODS_DESCS[i]:SetText( theAction:GetName() );
			end

			local	nPrice	= theAction:GetItemPriceInFittingRoom( GOODS_CONTAINERTYPE_BY_NUM[i] )
			local 	nItemSourceShopUnit = theAction:GetItemSourceShopUnitInFittingRoom( GOODS_CONTAINERTYPE_BY_NUM[i] )
			if (nItemSourceShopUnit == ShopUnitID.YuanBao) then
				local 	nItemSourceShopID = theAction:GetItemSourceShopIDInFittingRoom( GOODS_CONTAINERTYPE_BY_NUM[i] )
				if nItemSourceShopID == 288 or nItemSourceShopID == 299 or nItemSourceShopID ==300 then
					Shop_Fitting2_DragTitle:SetText("#{FFSDGZ_120615_12}")
					GOOD_BAD[i]:SetText("#cfff263".."#{YBSD_081225_101}" .. tostring(nPrice))
				else
					Shop_Fitting2_DragTitle:SetText("#{FFSDGZ_120615_10}")
					GOOD_BAD[i]:SetText("#cfff263".."#{YBSD_081225_101}" .. tostring(nPrice))
				end
			elseif (nItemSourceShopUnit == ShopUnitID.GiftToken) then
				GOOD_BAD[i]:SetText("#cfff263".."#{YBFQ_XML_1}" .. tostring(nPrice))
				Shop_Fitting2_DragTitle:SetText("#{FFSDGZ_120615_11}")
			elseif (nItemSourceShopUnit == ShopUnitID.ShowCredit) then
				GOOD_BAD[i]:SetText("#cfff263".."#{XCZB_160105_28}" .. tostring(nPrice))
				Shop_Fitting2_DragTitle:SetText("#{XYBSD_161018_12}")
			end
		else
			GOODS_BUTTONS_ICON[i]:SetProperty("Image" , "")
			GOODS_BUTTONS[i]:SetActionItem(-1);
			GOODS_DESCS[i]:SetText("");
			GOOD_BAD[i]:SetText("");
			GOODS_BUY_BTN[i]:Disable()
			GOODS_FITTING_CTL_BTN[i]:Hide()
		end
		i = i + 1
	end
	UpdateUIStatuts()
	PushEvent( "FITTINGROOM_BUY_ITEM_CONFIRM", "close")
end
function Shop_Fitting2_Booth_Close()

	--取消关心
	this:CareObject(objCared, 0, "Shop_Fitting2");
	--CloseShopFitting();
	this:Hide();
end

function Shop_Fitting2_CheckUI()
	if IsWindowShow("Shop_InfantFitting") then
		CloseWindow("Shop_InfantFitting", true)
	end
end

function UpdateUIStatuts() 
	local Sex = GetShopFittingRaceID()
	
	if Sex == 0 then
		Shop_Fitting2_SexChange:SetText( "#{SZYL_150626_03}" );
		Shop_Fitting2_SexChange:SetToolTip( "#{SZYL_150626_04}" );
	else
		Shop_Fitting2_SexChange:SetText( "#{SZYL_150626_01}" );
		Shop_Fitting2_SexChange:SetToolTip( "#{SZYL_150626_02}" );
	end
	
	Shop_Fitting2_UpdateZoomButton()

	Shop_Fitting2_PlayerButton:SetCheck(1)
	Shop_Fitting2_InfantButton:SetCheck(0)

	for i = 1, GOODS_TOTAL_NUM do
		
		local status = CurFittingItemByTypeStatus(GOODS_CONTAINERTYPE_BY_NUM[i]) 
		GOODS_PREVIEW_STATUS[i]:Hide()
		PreViewStatus[i] = 0
		GOODS_FITTING_CTL_BTN[i]:SetText("#{FFSDGZ_120615_01}")
		if status > 0 then 
			GOODS_FITTING_CTL_BTN[i]:SetText("#{FFSDGZ_120615_02}")
			GOODS_PREVIEW_STATUS[i]:Show()
			PreViewStatus[i] = 1
		end
	end

	local theAction = EnumAction(0, GOODS_CONTAINERTYPE[3])
	if theAction:GetItemTableIndex() <= 0 then
		Shop_Fitting2_ALLChoice:Hide()
		Shop_Fitting2_DressPrint:Hide()
		Shop_Fitting2_ALLChoice_Pic:Hide()
	elseif theAction:GetItemTableIndex() > 0 and DressReplaceColor:DressIsCanColour(theAction:GetItemTableIndex()) == 1 and PreViewStatus[i] == 1 then
		Shop_Fitting2_ALLChoice:Show()
		Shop_Fitting2_DressPrint:Show()
	end

end
----------------------------------------------------------------------------------
--
-- 旋转人物头像模型（向左)
--
function Shop_Fitting2_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			Shop_Fitting2_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			Shop_Fitting2_FakeObject:RotateEnd();
		end
	end
end

----------------------------------------------------------------------------------
--
--旋转人物头像模型（向右)
--
function Shop_Fitting2_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			Shop_Fitting2_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			Shop_Fitting2_FakeObject:RotateEnd();
		end
	end
end

function Shop_Fitting2_Frame_On_ResetPos()
  Shop_Fitting2_Frame:SetProperty("UnifiedPosition", g_Shop_Fitting2_Frame_UnifiedPosition);
end


function Shop_Fitting2_Crl_Clicked(nIndex)
	if nIndex < 1 or nIndex > GOODS_TOTAL_NUM then
		return
	end

	if PreViewStatus[nIndex] == 1 then 
		--处于试穿状态
		RestoreShopFitting(GOODS_CONTAINERTYPE_BY_NUM[nIndex]);			--取消试穿
		GOODS_FITTING_CTL_BTN[nIndex]:SetText("#{FFSDGZ_120615_01}") --按钮设置为试穿
		GOODS_PREVIEW_STATUS[nIndex]:Hide()
		PreViewStatus[nIndex] = 0
		if nIndex == 3 then
			--Shop_Fitting2_ALLChoice:Hide()
			--Shop_Fitting2_ALLChoice_Pic:Hide()
			--Shop_Fitting2_DressPrint:Hide()
			--RestoreShopFitting(GOODS_CONTAINERTYPE_BY_NUM[5]);			--取消试穿
			--RestoreShopFitting(GOODS_CONTAINERTYPE_BY_NUM[6]);			--取消试穿
			--RestoreShopFitting(GOODS_CONTAINERTYPE_BY_NUM[7]);			--取消试穿
		end
	else 
		--试穿 
		if nIndex == 5 or nIndex == 6 or nIndex == 7 then
				--if PreViewStatus[3] == 0 then
				--	PushDebugMessage("#{SZBSYL_150327_103}")
				--	return
				--end 
		end
	
		if Player : GetPlayerChangeModel() > 0 then
			PushDebugMessage("#{GMActionSystem_Item_Info_RideOrDressFailedInBianShen}")
			return
		end
		--重新试穿
		ReWearFromFittingItem(GOODS_CONTAINERTYPE_BY_NUM[nIndex]);			--穿上
		local status = CurFittingItemByTypeStatus(GOODS_CONTAINERTYPE_BY_NUM[nIndex]) 
		if status == 0 then
			return
		end 		
		GOODS_FITTING_CTL_BTN[nIndex]:SetText("#{FFSDGZ_120615_02}")	--按钮设置为取消试穿
		GOODS_PREVIEW_STATUS[nIndex]:Show()
		PreViewStatus[nIndex] = 1
		if nIndex == 3 then
			local theAction = EnumAction(0, GOODS_CONTAINERTYPE[nIndex]);
			if theAction:GetItemTableIndex() == 0  then
				return
			end
			if DressReplaceColor:DressIsCanColour(theAction:GetItemTableIndex()) ~= 1 then
				Shop_Fitting2_ALLChoice_Pic:Show()
			end
			Shop_Fitting2_ALLChoice:Show()

--~ 			Shop_Fitting2_ALLChoice:SetCurrentSelect(0)
			Shop_Fitting2_DressPrint:Show()
		end
	end
end

function Shop_Fitting2_Buy_Clicked(nIndex)
	if nIndex <= 0 or nIndex > GOODS_TOTAL_NUM then
		return
	end
	local theAction = EnumAction(0, GOODS_CONTAINERTYPE[nIndex]);
	if theAction:GetID() == 0  then
		return
	end
	if NpcShop:BuyItemWithOutConfirm() > 0 then
		NpcShop:BuyItemFromFittingRoom(GOODS_CONTAINERTYPE_BY_NUM[nIndex], 1)
	else
		PushEvent( "FITTINGROOM_BUY_ITEM_CONFIRM", "close")
		local theAction = EnumAction(0, GOODS_CONTAINERTYPE[nIndex]);
		if theAction:GetID() ~= 0  then
			local	nPrice	= theAction:GetItemPriceInFittingRoom( GOODS_CONTAINERTYPE_BY_NUM[nIndex] )
			local 	nItemSourceShopUnit = theAction:GetItemSourceShopUnitInFittingRoom( GOODS_CONTAINERTYPE_BY_NUM[nIndex] )
			PushEvent( "FITTINGROOM_BUY_ITEM_CONFIRM", "open", GOODS_CONTAINERTYPE_BY_NUM[nIndex], theAction:GetName(), nPrice, nItemSourceShopUnit)
		end
	end
end

function Shop_Fitting2_Close_Clicked()
	this:Hide();
end

function Shop_Fitting2_Type_Switch( nPos )
	if nPos == 1 then
		Shop_Fitting2_FakeObject:SetFakeObject("")
		local pos = Shop_Fitting2_Frame:GetProperty("UnifiedPosition")
		g_SwitchFlag = 1
		PushEvent("DRESS_FIT_PAGE_SWITCH", "1", pos )
		return
	end
end

function FitMountCamera(nMountID)
	if g_MountXueYuID == nMountID or g_MountMingYuID == nMountID or g_MountHuanYuID == nMountID or g_MountJuYuanID == nMountID then   --翅膀的试骑比较特殊，单独设置摄像机的位置
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == 221 or nMountID == 222  then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3);
	elseif nMountID == g_MountWuDang[1] or nMountID == g_MountWuDang[2]  then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == g_MountWuDang[3] or nMountID == g_MountTianShan[3] then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3);
	elseif nMountID == g_MountTianShan[1] or nMountID == g_MountTianShan[2] then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == g_MountEMei[1] or nMountID == g_MountEMei[2] or nMountID == g_MountEMei[3] then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3);
	elseif nMountID == g_MountDaFengID then     --大风坐骑
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,23);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,4);
	elseif nMountID == g_MountAFanDa[1] or nMountID == g_MountAFanDa[2] or nMountID == g_MountAFanDa[3] then
		--赤魅鹰,暗魅鹰,紫魅鹰
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,15);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3);
	--TT78319 向下
	elseif nMountID == g_MountKuMuKuiLeiID or nMountID == g_MountXuanZhuanMuMa or nMountID == g_MountFeiLongYi then
		--枯木傀儡
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,18);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == g_MountHuoYunXieShouID then
		--火云邪兽
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,14);
	--TT78319 向上
	elseif nMountID == g_MountJiuZhouShenLong then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,18);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3);
	elseif nMountID == g_MountJiJu then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,13);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == g_MountChiLinBaiZeID or nMountID == g_MountQingLinBaiZeID or nMountID == g_MountQiBaoLianZuoID then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,15);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == g_MountMouse then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,18);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == g_MountGoldenWing or nMountID == g_MountGoldenWing_BLUE or nMountID == g_MountGoldenWing_GREEN then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,18);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,5);
	elseif nMountID == g_YanYuQingHe then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,4);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,11);
	elseif nMountID == g_HuanHuoShou then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,15);
	elseif nMountID == g_LuXingNiao then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,13);
	elseif nMountID == g_MountFlyDaFeng then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,5);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,23);
	elseif nMountID == g_HongMeiRuanJia then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,18);
	--天河灵鹊
	elseif nMountID == g_MountTHLingQue then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,17);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3);
	--暗炎开明兽
	elseif nMountID == 177 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,17);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	--瑶光开明兽
	elseif nMountID == 178 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,17);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == g_MountXingHongYunZhou then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,18);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == g_MountAnYanMingShi then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,18);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == 196 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == 187 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,18);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,4);
    --- 蝶羽
    elseif nMountID == 64 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight, 2 );
	elseif nMountID == 194 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,15);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,1);
	elseif nMountID == 197 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,15);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3);
	elseif nMountID == 199 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == 202 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,18);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3);
	elseif nMountID == 204 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == 201 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,15);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,1);
	elseif nMountID == 171 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == 208 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,18);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == 209 or nMountID == 210 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,15);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
	elseif nMountID == 219 or nMountID == 220 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3);
	elseif nMountID == 235 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,20);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,1.8);
	elseif nMountID == 237 or nMountID == 238 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,15);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,1.6);
	elseif nMountID == 239 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2.6);
	elseif nMountID == 242 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2.7);
	elseif nMountID == 247 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,14);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2.7);
	elseif nMountID == 249 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.8);
	elseif nMountID == 252 or nMountID == 253 or nMountID == 254 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.8);
	elseif nMountID == 261 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,11);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.2);
	elseif nMountID == 262 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,15);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2.5);
	--玉枕兰舟
	elseif nMountID == 276 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,13);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.5);
		
	--260	水客乘鲤去
	elseif nMountID == 260 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,17);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.2);
	--264	云水叠
	elseif nMountID == 264 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,11);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.0);
	--263	坠风莲
	elseif nMountID == 263 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,11);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.0);
	--269	碧海照玉阶
	elseif nMountID == 269 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,18);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2.8);
	--270	寒宫倚桂枝
	elseif nMountID == 270 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,18);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2.8);
	--271	与春归
	elseif nMountID == 271 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,19);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.2);
	--273	踏兰山
	elseif nMountID == 273 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,14);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2.2);	
	--274	芳遥天坠
	elseif nMountID == 274 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,18);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,5.5);		
	--284 lidengyou
	elseif nMountID == 284 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,16);
	--291 幽竹乘风
	elseif nMountID == 291 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.2);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,15);
	--292 扁舟梦蜀		
	elseif nMountID == 292 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2.2);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,14);		
	--279 绝情谷坐骑
	elseif nMountID == 278 or nMountID == 279 or nMountID == 280 then
		FakeObj_SetCamera("EquipChange_Player", g_CameraHeight, 4)
		FakeObj_SetCamera("EquipChange_Player", g_CameraDistance, 12)
	--293 重明玉凰
	elseif nMountID == 293 then
		FakeObj_SetCamera("EquipChange_Player", g_CameraHeight, 3.2)
		FakeObj_SetCamera("EquipChange_Player", g_CameraDistance, 12)
	--299 翎月椅
	elseif nMountID == 299 then
		--FakeObj_SetCamera("EquipChange_Player", g_CameraHeight, 2.9)
		--FakeObj_SetCamera("EquipChange_Player", g_CameraDistance, 15)
		local h_,d_,p_ = FakeObj_GetCamera("EquipChange_Player")
		NewFakeObj_SetCamera_WithXOffset("EquipChange_Player", 3.2, 14, p_, 22)
	elseif nMountID == 301 then
		FakeObj_SetCamera("EquipChange_Player", g_CameraHeight, 3.2)
		FakeObj_SetCamera("EquipChange_Player", g_CameraDistance, 16)
	--302 映月华川
	elseif nMountID == 302 then
		FakeObj_SetCamera("EquipChange_Player", g_CameraHeight, 3.2)
		FakeObj_SetCamera("EquipChange_Player", g_CameraDistance, 16)
	--383 惊流云 381 掠千峰
	elseif nMountID == 383 or nMountID == 381 then
		FakeObj_SetCamera("EquipChange_Player", g_CameraHeight, 5.5)
		FakeObj_SetCamera("EquipChange_Player", g_CameraDistance, 16)
	--315 飞凰引梦 313 彩凤呈祥
	elseif nMountID == 313 or nMountID == 315 then
		FakeObj_SetCamera("EquipChange_Player", g_CameraHeight, 4)
		FakeObj_SetCamera("EquipChange_Player", g_CameraDistance, 16)
	elseif nMountID == 326 or nMountID == 327 or nMountID == 330 or nMountID == 335 or nMountID == 336 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,16);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,4);
	elseif nMountID == 339 or nMountID == 341 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,13);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2.3);
	elseif nMountID == 385 or nMountID == 387 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,13);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.2);
	elseif nMountID == 345 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,17);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.2);
	elseif nMountID == 350 or nMountID == 352 then
		FakeObj_SetCamera("EquipChange_Player", g_CameraHeight, 5.5)
		FakeObj_SetCamera("EquipChange_Player", g_CameraDistance, 23)
	elseif nMountID == 366 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,17);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.2);
	elseif nMountID >= 0 then
		FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,1.6);
	end
end

function Shop_Fitting2_setCameraPosition()
		local Sex = GetShopFittingRaceID()
		if Sex > 1 or Sex < 0 then 
			return
		end
		
		if Shop_Fitting2_CameraLevel < 0 or Shop_Fitting2_CameraLevel > 2 then
			return
		end
		
		local isIVMode = LuaFnGetCurModelState()
		local camerainfo = Shop_Fitting2_CameraPosition
		if isIVMode == 1 then
			camerainfo = Shop_Fitting2_CameraPosition_IV
		end
		--FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,Shop_Fitting2_CameraPosition[Sex][Shop_Fitting2_CameraLevel].fDistance)
		--FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,Shop_Fitting2_CameraPosition[Sex][Shop_Fitting2_CameraLevel].fHeight)
		local  fHeight, fDistance, fPitch = FakeObj_GetCamera( "EquipChange_Player" )
		--PushDebugMessage("fHeight = "..fHeight.." fDistance = "..fDistance.." fPitch = "..fPitch)
		NewFakeObj_SetCamera_WithXOffset( "EquipChange_Player", camerainfo[Sex][Shop_Fitting2_CameraLevel].fHeight, 
																camerainfo[Sex][Shop_Fitting2_CameraLevel].fDistance,
																camerainfo[Sex][Shop_Fitting2_CameraLevel].fPitch,
																camerainfo[Sex][Shop_Fitting2_CameraLevel].XOffset )
end

function Shop_Fitting2_UpdateComboList(itemindex)
	if PreViewStatus[3] == 0 then
		Shop_Fitting2_ALLChoice_Pic:Hide()
		Shop_Fitting2_ALLChoice:Hide();
		Shop_Fitting2_DressPrint:Hide()
		return
	end
	if g_Shop_Fitting2_CurDressID == itemindex then
		return
	end
	Shop_Fitting2_ALLChoice:ResetList();
	g_Shop_Fitting2_CurDressID=0
	Shop_Fitting2_ALLChoice:Show()
	Shop_Fitting2_DressPrint:Show()
	if itemindex <= 0 then
		return
	end

	g_Shop_Fitting2_CurDressID = itemindex

	if DressReplaceColor:DressIsCanColour(itemindex) == 1 then
		DressReplaceColor :StoreDressByIndex(itemindex);
		Shop_Fitting2_ALLChoice:Enable()
		Shop_Fitting2_ALLChoice:SetProperty("Visible", "True")
		Shop_Fitting2_ALLChoice:AddTextItem("默认风格",1)
		Shop_Fitting2_ALLChoice_Pic:Hide()
		for i=1 ,8 do
			local nVisual,ndesc,nRate = DressReplaceColor:GetDressDesc(i-1)
			if nVisual <= 0 then
				continue
			end

			local DressNames =""

			if nRate == 23000 then
				DressNames = ScriptGlobal_Format("#{SZRSYH_120912_07}", ndesc);
			elseif nRate == 14000 then
				DressNames = ScriptGlobal_Format("#{SZRSYH_120912_08}", ndesc)
			elseif nRate == 1000 then
				DressNames = ScriptGlobal_Format("#{SZRSYH_120912_09}", ndesc)
			elseif nRate == -1 then
				DressNames = ndesc
			end

			Shop_Fitting2_ALLChoice:AddTextItem(DressNames,i+1)
			Shop_Fitting2_DressPrint:SetText("染色风格预览")
		end
	else
		Shop_Fitting2_ALLChoice:Disable()
		Shop_Fitting2_ALLChoice:AddTextItem("无法染色",0)
		Shop_Fitting2_ALLChoice_Pic:Show()
		Shop_Fitting2_DressPrint:SetText("染色风格预览")
	end
	Shop_Fitting2_ALLChoice:SetCurrentSelect(0)
	Shop_Fitting2_FakeObject:SetFakeObject("EquipChange_Player")
	Shop_Fitting2_ComboList_Changed()
end

function Shop_Fitting2_ComboList_Changed()
	if g_Shop_Fitting2_CurDressID == 0 then
		return
	end

	local _, Index = Shop_Fitting2_ALLChoice:GetCurrentSelect()
	if Index > 9 or Index < 1 then
		return
	end

	if Index == 1 then --默认风格
		Index = 9
	else
		Index = Index -1
	end

	local nVisual,ndesc,nRate = DressReplaceColor:GetDressDesc(Index-1)
	if nVisual <= 0 then
		return
	end

	DressReplaceColor : FittingOnDressByYuanBaoShop(g_Shop_Fitting2_CurDressID,nVisual)
end

function Shop_Fitting2_ChangeSex()
	Shop_Fitting2_FakeObject:SetFakeObject("");
	
	local Sex = GetShopFittingRaceID()
	if Sex == 0 then
		Shop_Fitting2_SexChange:SetText( "#{SZYL_150626_01}" );
		Shop_Fitting2_SexChange:SetToolTip( "#{SZYL_150626_02}" );
		ChangeShopFittingRaceID(1)
	else
		Shop_Fitting2_SexChange:SetText( "#{SZYL_150626_03}" );
		Shop_Fitting2_SexChange:SetToolTip( "#{SZYL_150626_04}" );
		ChangeShopFittingRaceID(0)
	end
	
	Shop_Fitting2_setCameraPosition()
	
	local nMountID = GetMountID();
	FitMountCamera(nMountID)
end

function Shop_Fitting2_ZoomIn()
	if Shop_Fitting2_CameraLevel < 0 or Shop_Fitting2_CameraLevel > 1 then
		return
	end
	
	Shop_Fitting2_CameraLevel = Shop_Fitting2_CameraLevel + 1
	
	Shop_Fitting2_setCameraPosition()
	Shop_Fitting2_UpdateZoomButton()
end

function Shop_Fitting2_ZoomOut()
	if Shop_Fitting2_CameraLevel < 1 or Shop_Fitting2_CameraLevel > 2then
		return
	end
	
	Shop_Fitting2_CameraLevel = Shop_Fitting2_CameraLevel - 1
	
	Shop_Fitting2_setCameraPosition()
	Shop_Fitting2_UpdateZoomButton()
end

function Shop_Fitting2_UpdateZoomButton()
	Shop_Fitting2_Model_ZoomIn:Enable()
	Shop_Fitting2_Model_ZoomOut:Enable()
	
	Shop_Fitting2_Model_ZoomIn_Tips:SetToolTip("")
	Shop_Fitting2_Model_ZoomIn_Tips:Hide()
	Shop_Fitting2_Model_ZoomOut_Tips:SetToolTip("")
	Shop_Fitting2_Model_ZoomOut_Tips:Hide()
	
	if Shop_Fitting2_CameraLevel == 0 then 
		Shop_Fitting2_Model_ZoomOut:Disable()
		Shop_Fitting2_Model_ZoomOut_Tips:Show()
		Shop_Fitting2_Model_ZoomOut_Tips:SetToolTip( "#{YBDYL_150703_03}" );
	elseif Shop_Fitting2_CameraLevel == 2 then
		Shop_Fitting2_Model_ZoomIn:Disable()
		Shop_Fitting2_Model_ZoomIn_Tips:Show()
		Shop_Fitting2_Model_ZoomIn_Tips:SetToolTip( "#{YBDYL_150703_01}" );
	end
	
	local nMountID = GetMountID();
	if nMountID >= 0 then
		Shop_Fitting2_Model_ZoomOut:Disable()
		Shop_Fitting2_Model_ZoomIn:Disable()
		Shop_Fitting2_Model_ZoomOut_Tips:Show()
		Shop_Fitting2_Model_ZoomOut_Tips:SetToolTip( "#{YBDYL_150703_02}" );
		Shop_Fitting2_Model_ZoomIn_Tips:Show()
		Shop_Fitting2_Model_ZoomIn_Tips:SetToolTip( "#{YBDYL_150703_02}" );
	end
end
