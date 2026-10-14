
local g_SuperWeaponQH_WeaponIndex = -1;	--	契合神器背包中的索引
local g_SuperWeaponQH_Slot;		--	契合物品框
local g_SuperWeaponQH_CashCost;
local g_SuperWeaponQH_PlayerCashJiaoZi;
local g_SuperWeaponQH_PlayerCash;

local g_SuperWeaponQH_FitText;
local g_SuperWeaponQH_FitMaterialName;
local g_SuperWeaponQH_MaterialCostText;
local g_SuperWeaponQH_UnifiedPos;

local MAX_OBJ_DISTANCE = 3.0;
local g_ObjCared = -1;
local g_TargetServerID = -1

function SuperWeaponQH_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("SUPERWEAPONADVANCE_PUTWEAPON");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("ADJEST_UI_POS",false);		--	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);	--	窗口大小变换
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
end

function SuperWeaponQH_OnLoad()
	g_SuperWeaponQH_Slot = SuperWeaponQH_Item;
	g_SuperWeaponQH_CashCost = SuperWeaponQH_CashNum;
	g_SuperWeaponQH_PlayerCashJiaoZi = SuperWeaponQH_JiaoZiNum;
	g_SuperWeaponQH_PlayerCash = SuperWeaponQH_CashMoney;
	g_SuperWeaponQH_FitText = SuperWeaponQH_Explain6;
	g_SuperWeaponQH_FitMaterialName = SuperWeaponQH_Explain7;
	g_SuperWeaponQH_MaterialCostText = SuperWeaponQH_Explain8;
	g_SuperWeaponQH_UnifiedPos = SuperWeaponQH_Frame:GetProperty("UnifiedPosition");
end

function SuperWeaponQH_OnEvent(event)
	local objCared = DataPool:GetCurDialogNpcId();
	if event == "UI_COMMAND" then
		if tonumber(arg0) == 201208093 then
			g_ObjCared = objCared
			g_TargetServerID = Get_XParam_INT(0);
			this:CareObject(objCared, 1, "SuperWeaponQH");
			SuperWeaponQH_UpdataFrame();
			this:Show()
			return;
		elseif tonumber(arg0) == 201208097 then
			SuperWeaponQH_ResetActionSlot();
			SuperWeaponQH_UpdataFrame();
			return;
		end

		SuperWeaponQH_CancleEvent();
		return;
	end

	
	if event == "SUPERWEAPONADVANCE_PUTWEAPON" then
		if arg0 ~= nil then
			local nSlot = tonumber(arg0);
			local nIndex = tonumber(arg1);
			SuperWeaponQH_UpDataSlot(nSlot, nIndex)
			return;
		end
		return;
	end

	if event == "OBJECT_CARED_EVENT" then
		if(g_ObjCared ~= objCared) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			this:Hide();
			--取消关心
			this:CareObject(g_ObjCared, 0, "SuperWeaponQH");
			g_ObjCared = -1;
		end
	end

	if event == "ADJEST_UI_POS" then
		SuperWeaponQH_ResetWindow();
		return
	end

	if event == "PACKAGE_ITEM_CHANGED_EX" then
		SuperWeaponQH_UpdataFrame();
		return;
	end

	if event == "VIEW_RESOLUTION_CHANGED" then
		SuperWeaponQH_ResetWindow()
		return;
	end

	if event == "MONEY_CHANGE_EX" then
		SuperWeaponQH_UpdataFrame();
		return;
	end

	if event == "MONEYJZ_CHANGE_EX" then
		SuperWeaponQH_UpdataFrame();
		return;
	end
end

function SuperWeaponQH_ResetActionSlot()
	if g_SuperWeaponQH_WeaponIndex > -1 then
		LifeAbility : Lock_Packet_Item(g_SuperWeaponQH_WeaponIndex, 0)
		g_SuperWeaponQH_Slot:SetActionItem(-1);
		g_SuperWeaponQH_WeaponIndex = -1;
	end
end

function SuperWeaponQH_CancleEvent()
	SuperWeaponQH_ResetActionSlot()
	SuperWeaponQH_UpdataFrame()
	this:CareObject(g_ObjCared, 0, "SuperWeaponQH");
	g_ObjCared = -1;
	g_TargetServerID = -1;

	this:Hide();
end

function SuperWeaponQH_OKEvent()
	if g_SuperWeaponQH_WeaponIndex < 0 then
		PushDebugMessage("#{SQSX_120806_25}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoSuperWeaponStartUpAction")
		Set_XSCRIPT_ScriptID(890009)
		Set_XSCRIPT_Parameter(0, 2)
		Set_XSCRIPT_Parameter(1, g_SuperWeaponQH_WeaponIndex)
		Set_XSCRIPT_Parameter(2, g_TargetServerID)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

--	local nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(g_SuperWeaponQH_WeaponIndex));
--	local nFit = math.mod(nByQual, 10);
--	if nFit >= 8 then
--		SuperWeaponQH_ResetActionSlot()
--		SuperWeaponQH_UpdataFrame()
--	end
end

function SuperWeaponQH_UpdataFrame()
	--	玩家身上的钱
	local nPlayerCashMoney = Player:GetData("MONEY");
	local nPlayerCashJiaoZi = Player:GetData("MONEY_JZ")

	g_SuperWeaponQH_PlayerCashJiaoZi:SetProperty("MoneyNumber", nPlayerCashJiaoZi);
	g_SuperWeaponQH_PlayerCash:SetProperty("MoneyNumber", nPlayerCashMoney);

	if g_SuperWeaponQH_WeaponIndex < 0 then
		g_SuperWeaponQH_CashCost:SetProperty("MoneyNumber", 0);
		g_SuperWeaponQH_FitText:SetProperty("Text", "")
		g_SuperWeaponQH_FitMaterialName:SetProperty("Text", "")
		g_SuperWeaponQH_MaterialCostText:SetProperty("Text", "")
		return
	end

	local nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(g_SuperWeaponQH_WeaponIndex));
	if nByQual > 10 then
		local nFit = math.mod(nByQual, 10);
		g_SuperWeaponQH_FitText:SetProperty("Text", "" .. nFit .. "级")
	end
	--	获取材料名称
	local strMaterialName = PlayerPackage:GetSuperWeaponAdvanceMaterialName(g_SuperWeaponQH_WeaponIndex);
	if strMaterialName == nil or strMaterialName == "" then
		return
	end
	g_SuperWeaponQH_FitMaterialName:SetProperty("Text", strMaterialName)
	--	获取材料数量
	local nMaterialCount = PlayerPackage:GetSuperWeaponAdvanceMaterialCount(g_SuperWeaponQH_WeaponIndex);
	
	--	获取材料物品ID
	local nMaterialIDNum = PlayerPackage:GetSuperWeaponAdvanceMaterialIDNum(g_SuperWeaponQH_WeaponIndex);
	local tempIDList = {}
	local curIndex = 1
	for i = 0, nMaterialIDNum do
		local nMaterialID = PlayerPackage:GetSuperWeaponAdvanceMaterialID(g_SuperWeaponQH_WeaponIndex, i);
		if nMaterialID > 0 then
			tempIDList[curIndex] = nMaterialID;
			curIndex = curIndex + 1;
		end
	end
	
	--	获取材料物品数量
	local nPlayerItemNum = 0	
	for i = 0, nMaterialIDNum - 1 do
		nPlayerItemNum = nPlayerItemNum + PlayerPackage:CountAvailableItemByIDTable(tempIDList[i+1])
	end

	local strMaterialCount = ""
	if nMaterialCount > nPlayerItemNum then
		--strMaterialCount = "#cFF0000"
		g_SuperWeaponQH_MaterialCostText:SetProperty("TextColor", "ffff0000")
	else
		--strMaterialCount = "#cFFFFFF"
		g_SuperWeaponQH_MaterialCostText:SetProperty("TextColor", "ff00ff00")
	end

	g_SuperWeaponQH_MaterialCostText:SetProperty("Text", strMaterialCount .. nMaterialCount)
	

	local nCashCount = PlayerPackage:GetSuperWeaponAdvanceCashCost(g_SuperWeaponQH_WeaponIndex);
	g_SuperWeaponQH_CashCost:SetProperty("MoneyNumber", nCashCount);
end

function SuperWeaponQH_ItemCheck(nIndex)
	if nIndex < 0 then
		return 0
	end
	
	--	检测物品是否可契合
	local ret = LifeAbility : CheckSuperWeaponCanAdvance(nIndex)
	if ret < 0 then
		local nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(nIndex));
		if nByQual > 80 then
			PushDebugMessage("#{SQSX_120806_61}")
			return 0
		end

		PushDebugMessage("#{SQSX_120806_23}")
		return 0
	end
	--	检测物品等级
	local nEquipLevel = LifeAbility : Get_Equip_Level(nIndex);
	if nEquipLevel ~= 86 and nEquipLevel ~= 96 and nEquipLevel ~= 102 then
		PushDebugMessage("#{SQSX_120806_23}")
		return 0
	end

	return 1
end

function SuperWeaponQH_UpDataSlot(nSlot, nIndex)
	if nSlot ~= 6 then 
		return
	end

	if nIndex < 0 then
		return
	end

	local theAction = EnumAction(nIndex, "packageitem");
	if theAction:GetID() ~= 0 then
		if SuperWeaponQH_ItemCheck(nIndex) ~= 1 then
			return
		end
		
		--	检测物品星级（品质）
		local nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(nIndex));
		if nByQual < 10 then
			PushDebugMessage("#{SQSX_120806_23}")
			return
		end

		if nByQual > 80 then
			PushDebugMessage("#{SQSX_120806_61}")
			return
		end
		local starNum = math.floor(nByQual / 10);
		local nFit = math.mod(nByQual, 10);
		if starNum > 7 or starNum < 6 then
			PushDebugMessage("#{SQSX_120806_26}")
			return
		end

		if nFit > 8 or nFit < 1 then
			PushDebugMessage("#{SQSX_120806_24}")
			return
		end
		g_SuperWeaponQH_FitText:SetProperty("Text", "" .. nFit .. "级")
		
		--	获取契合金钱
		local nCashCount = PlayerPackage:GetSuperWeaponAdvanceCashCost(nIndex);
		g_SuperWeaponQH_CashCost:SetProperty("MoneyNumber", nCashCount);

		if g_SuperWeaponQH_WeaponIndex > -1 then
			LifeAbility : Lock_Packet_Item(g_SuperWeaponQH_WeaponIndex, 0)
		end
		--	设置物品并锁定
		g_SuperWeaponQH_Slot:SetActionItem(theAction:GetID());
		g_SuperWeaponQH_WeaponIndex = nIndex;
		LifeAbility : Lock_Packet_Item(g_SuperWeaponQH_WeaponIndex, 1)

		SuperWeaponQH_UpdataFrame()
	end
end

function SuperWeaponQH_ResetWindow()
	SuperWeaponQH_Frame:SetProperty("UnifiedPosition", g_SuperWeaponQH_UnifiedPos);
end
