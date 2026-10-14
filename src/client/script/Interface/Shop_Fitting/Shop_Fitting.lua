local TOTALFITTINGKIND_NUM = 10;
local g_ItemMax = 0;
local g_ItemIdx = -1;

local CU_MONEY			= 1	-- 钱

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
local g_Shop_Fitting_Frame_UnifiedPosition;
local g_MountIds = {
	["TaoHuaDao"] = { 252, 253, 254 },
	["Tianhelingque"] = 172,
	["Congren"] = { 278, 279 },
	["Lidengyou"] = 284,
	["YingYueHuaChuan"] = 302,
	["CaiFengFeiHuang"] = { 313, 315 },
	["Valentine"] = { 339,341, 385, 387 },
	["SeventhFestival"] = { 383,381 },
}


function Shop_Fitting_PreLoad()
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("OPEN_SHOP_FITTING",true);
	this:RegisterEvent("CLOSE_SHOP_FITTING",true);
	this:RegisterEvent("OBJECT_CARED_EVENT",true);
	this:RegisterEvent("SEX_CHANGED",false);

	-- FakeObject模型界面互斥
	this:RegisterEvent("OPEN_EQUIP",false);										-- 角色资料界面
	this:RegisterEvent("OPEN_DRESS_PAINT_FITTING",false);			-- 时装染色试衣间
	this:RegisterEvent("OPEN_DRESS_ENCHASE_FITTING",false);		-- 时装镶嵌试衣间
	this:RegisterEvent("YIGUI_OPEN",false);				-- 衣柜
	this:RegisterEvent("UI_COMMAND",false);				-- 变性
	this:RegisterEvent("OPEN_YB_SHOP_FITTING",false)
	this:RegisterEvent("FASHION_DEPOT_OP", false);				-- 华裳阁
	this:RegisterEvent("FEIYUSHOW_WINDOW", false)
	this:RegisterEvent("OPEN_SPECIALDRESSPAINT", false)

	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function Shop_Fitting_OnLoad()
g_Shop_Fitting_Frame_UnifiedPosition= Shop_Fitting_Frame:GetProperty("UnifiedPosition");
end


function ShopFitting_OnHiden()
	Shop_Fitting_FakeObject:SetFakeObject("");
	SetDefaultMouse();
	RestoreShopFitting(TOTALFITTINGKIND_NUM);
	this:Hide();
end

function Shop_Fitting_OnEvent(event)

	if ( event == "HIDE_ON_SCENE_TRANSED" ) then
		Shop_Fitting_Booth_Close();
	end

	-- FakeObject模型界面互斥
	if ( event == "OPEN_EQUIP" ) or												-- 角色资料界面
		( event == "OPEN_YB_SHOP_FITTING" )or			--元宝商店试衣间
		 ( event == "OPEN_DRESS_PAINT_FITTING" ) or					-- 时装染色试衣间
		 ( event == "OPEN_DRESS_ENCHASE_FITTING" ) or	-- 时装镶嵌试衣间
		 ( event == "YIGUI_OPEN") or			-- 衣柜
		 ((event == "UI_COMMAND" and tonumber(arg0) == 20120406)) or --变性
		  (event == "FASHION_DEPOT_OP" and tonumber(arg0) == 1) or --华裳阁
		  (event == "FEIYUSHOW_WINDOW" and tonumber(arg0) >= 0) or
		 (event == "OPEN_SPECIALDRESSPAINT" and tonumber(arg0) >= 0) then
		if (this:IsVisible()) then
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
			this:Hide();
		end
	end

	if(event == "OPEN_SHOP_FITTING") then
		if(IsWindowShow("Shop_Fitting2")) then
			CloseWindow("Shop_Fitting2", true);
		end
		this:Show();

		objCared = NpcShop:GetNpcId();
		this:CareObject(objCared, 1, "Shop_Fitting");

		Shop_Fitting_FakeObject:SetFakeObject("");
		Shop_Fitting_FakeObject:SetFakeObject("EquipChange_Player");

		local nMountID = GetMountID();
		if g_MountXueYuID == nMountID or g_MountMingYuID == nMountID or g_MountHuanYuID == nMountID or g_MountJuYuanID == nMountID then   --翅膀的试骑比较特殊，单独设置摄像机的位置
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
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
		elseif nMountID == g_MountIds.Tianhelingque then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,4);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,16);
		elseif nMountID == g_MountIds.Lidengyou then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,16);
		elseif nMountID == g_MountIds.YingYueHuaChuan then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.2);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,16);
		elseif nMountID == g_MountIds.SeventhFestival[1] or nMountID == g_MountIds.SeventhFestival[2] then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,5.5);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,16);
		--天河灵鹊
		elseif nMountID == g_MountTHLingQue then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,17);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3);
		elseif nMountID == g_MountIds.TaoHuaDao[1] or nMountID == g_MountIds.TaoHuaDao[2] or nMountID == g_MountIds.TaoHuaDao[3] then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.8);
		elseif nMountID == g_MountIds.Congren[1] or nMountID == g_MountIds.Congren[2] then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,4);
		elseif nMountID == g_MountIds.CaiFengFeiHuang[1] or nMountID == g_MountIds.CaiFengFeiHuang[2] then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,4);
		elseif nMountID == g_MountIds.Valentine[1] or nMountID == g_MountIds.Valentine[2] then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,13);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2.3);
		elseif nMountID == g_MountIds.Valentine[3] or nMountID == g_MountIds.Valentine[4] then
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
		end

	end

	if(event == "CLOSE_SHOP_FITTING") then
		--PushDebugMessage("Fitting 关闭");
		RestoreShopFitting(TOTALFITTINGKIND_NUM);
		this:Hide();
	end

	if (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= objCared) then
			return;
		end

		--如果和商人的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			--取消关心
			--PushDebugMessage("Fitting 取消关心");
			RestoreShopFitting(TOTALFITTINGKIND_NUM);
			this:CareObject(objCared, 0, "Shop_Fitting");
			this:Hide();
		end
	end

	if event == "SEX_CHANGED" and  this:IsVisible() then
		Shop_Fitting_FakeObject : Hide();
		Shop_Fitting_FakeObject : Show();
		Shop_Fitting_FakeObject:SetFakeObject("EquipChange_Player");

		local nMountID = GetMountID();
		if g_MountXueYuID == nMountID or g_MountMingYuID == nMountID or g_MountHuanYuID == nMountID or g_MountJuYuanID == nMountID then   --翅膀的试骑比较特殊，单独设置摄像机的位置
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
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
		elseif nMountID == g_MountJiJu then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,13);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
		elseif nMountID == g_MountChiLinBaiZeID or nMountID == g_MountQingLinBaiZeID or nMountID == g_MountQiBaoLianZuoID then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,15);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
		elseif nMountID == g_HongMeiRuanJia then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,2);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,18);
		elseif nMountID == g_MountIds.Lidengyou then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,16);
		elseif nMountID == g_MountIds.YingYueHuaChuan then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.2);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,16);
		elseif nMountID == g_MountIds.Tianhelingque then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,4);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,16);
		--天河灵鹊
		elseif nMountID == g_MountTHLingQue then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,17);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3);
		elseif nMountID == g_MountIds.TaoHuaDao[1] or nMountID == g_MountIds.TaoHuaDao[2] or nMountID == g_MountIds.TaoHuaDao[3] then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,3.8);
		elseif nMountID == g_MountIds.Congren[1] or nMountID == g_MountIds.Congren[2] then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
			FakeObj_SetCamera( "EquipChange_Player", g_CameraHeight,4);
		elseif nMountID >= 0 then
			FakeObj_SetCamera( "EquipChange_Player", g_CameraDistance,12);
		end

	end

	if (event == "ADJEST_UI_POS" ) then
		Shop_Fitting_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Shop_Fitting_Frame_On_ResetPos()
	end


end

function Shop_Fitting_Booth_Close()

	--取消关心
	this:CareObject(objCared, 0, "Shop_Fitting");
	RestoreShopFitting(TOTALFITTINGKIND_NUM);
	--CloseShopFitting();
	this:Hide();
end


function Shop_Fitting_Accept_Clicked()

	this:Hide();
end

function Shop_Fitting_TextChanged()


end


----------------------------------------------------------------------------------
--
-- 旋转人物头像模型（向左)
--
function Shop_Fitting_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			Shop_Fitting_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			Shop_Fitting_FakeObject:RotateEnd();
		end
	end
end

----------------------------------------------------------------------------------
--
--旋转人物头像模型（向右)
--
function Shop_Fitting_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			Shop_Fitting_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			Shop_Fitting_FakeObject:RotateEnd();
		end
	end
end

function Shop_Fitting_Frame_On_ResetPos()
  Shop_Fitting_Frame:SetProperty("UnifiedPosition", g_Shop_Fitting_Frame_UnifiedPosition);
end
