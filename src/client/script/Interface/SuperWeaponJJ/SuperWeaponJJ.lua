
local g_SuperWeaponJJ_WeaponSlot;
local g_SuperWeaponJJ_WeaponIndex = -1;

local g_SuperWeaponJJ_CashCost;
local g_SuperWeaponJJ_PlayerCashJiaoZi;
local g_SuperWeaponJJ_PlayerCash;
local g_SuperWeaponJJ_Fram_UnifiedPosition;

local MAX_OBJ_DISTANCE = 3.0;
local g_ObjCared = -1;
local g_TargetServerID = -1;

function SuperWeaponJJ_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("SUPERWEAPONSTARUP_PUTWEAPON");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("ADJEST_UI_POS",false);		--	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);	--	窗口大小变换
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
end

function SuperWeaponJJ_OnLoad()
	g_SuperWeaponJJ_CashCost = SuperWeaponJJ_CashNum;
	g_SuperWeaponJJ_PlayerCashJiaoZi = SuperWeaponJJ_JiaoZiNum;
	g_SuperWeaponJJ_PlayerCash = SuperWeaponJJ_CashMoney;
	g_SuperWeaponJJ_WeaponSlot = SuperWeaponJJ_Item;
	g_SuperWeaponJJ_Fram_UnifiedPosition = SuperWeaponJJ_Frame:GetProperty("UnifiedPosition");
end

function SuperWeaponJJ_OnEvent(event)
	local objCared = DataPool:GetCurDialogNpcId();
	if event == "UI_COMMAND" then
		if tonumber(arg0) == 201208092 then
			g_TargetServerID = Get_XParam_INT(0);
			g_ObjCared = objCared
			this:CareObject(objCared, 1, "SuperWeaponJJ");
			SuperWeaponJJ_UpdataMoney()
			this:Show();
			return;
		end

		if tonumber(arg0) == 201208096 then
			SuperWeaponJJ_CancleEvent();
			return;
		end
		SuperWeaponJJ_CancleEvent();
	end

	if event == "SUPERWEAPONSTARUP_PUTWEAPON" then
		if arg0 ~= nil then
			local nSlot = tonumber(arg0);
			local nIndex = tonumber(arg1);
			SuperWeaponJJ_UpdataFrame(nSlot, nIndex)
		end
	end

	if event == "OBJECT_CARED_EVENT" then
		if(g_ObjCared ~= objCared) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			SuperWeaponJJ_CancleEvent()
		end
	end

	if event == "ADJEST_UI_POS" then
		SuperWeaponJJ_ResetWindowPos();
		return
	end

	if event == "VIEW_RESOLUTION_CHANGED" then
		SuperWeaponJJ_ResetWindowPos()
		return;
	end

	if event == "MONEY_CHANGE_EX" then
		SuperWeaponJJ_UpdataMoney();
		return;
	end

	if event == "MONEYJZ_CHANGE_EX" then
		SuperWeaponJJ_UpdataMoney();
		return;
	end
end

function SuperWeaponJJ_ResetWindowPos()
	 SuperWeaponJJ_Frame:SetProperty("UnifiedPosition", g_SuperWeaponJJ_Fram_UnifiedPosition);
end

function SuperWeaponJJ_ResetSlot()
	if g_SuperWeaponJJ_WeaponIndex ~= -1 then
		LifeAbility : Lock_Packet_Item(g_SuperWeaponJJ_WeaponIndex, 0)
		g_SuperWeaponJJ_WeaponSlot:SetActionItem(-1)
		g_SuperWeaponJJ_WeaponIndex = -1;
	end

	g_SuperWeaponJJ_CashCost:SetProperty("MoneyNumber", 0);
end

function SuperWeaponJJ_OKEvent()
	if g_SuperWeaponJJ_WeaponIndex < 0 then
		PushDebugMessage("#{SQSX_120806_34}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoSuperWeaponStartUpAction")
		Set_XSCRIPT_ScriptID(890009)
		Set_XSCRIPT_Parameter(0, 3)
		Set_XSCRIPT_Parameter(1, g_SuperWeaponJJ_WeaponIndex)
		Set_XSCRIPT_Parameter(2, g_TargetServerID);
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

--	SuperWeaponJJ_ResetSlot()
--	SuperWeaponJJ_UpdataMoney()
end

function SuperWeaponJJ_CancleEvent()
	SuperWeaponJJ_ResetSlot()

	this:CareObject(g_ObjCared, 0, "SuperWeaponJJ");
	g_ObjCared = -1;

	g_TargetServerID = -1;

	this:Hide()
end

function SuperWeaponJJ_UpdataMoney()
	--	玩家身上的钱
	local nPlayerCashMoney = Player:GetData("MONEY");
	local nPlayerCashJiaoZi = Player:GetData("MONEY_JZ");
	local nMoneyCost = 0;
	if g_SuperWeaponJJ_WeaponIndex >= 0 then
		nMoneyCost = PlayerPackage:GetSuperWeaponStarUpCashCost(g_SuperWeaponJJ_WeaponIndex)
	end
	g_SuperWeaponJJ_CashCost:SetProperty("MoneyNumber", nMoneyCost);
	g_SuperWeaponJJ_PlayerCashJiaoZi:SetProperty("MoneyNumber", nPlayerCashJiaoZi);
	g_SuperWeaponJJ_PlayerCash:SetProperty("MoneyNumber", nPlayerCashMoney);

end

function SuperWeaponJJ_UpdataFrame(nSlot, nIndex)
	if nSlot ~= 7 then
		return
	end

	if nIndex < 0 then
		return
	end

	local theAction = EnumAction(nIndex, "packageitem");
	if theAction:GetID() ~= 0 then
		local ret = LifeAbility : CheckSuperWeaponCanStarUp(nIndex)
		local nByQual = 0
		if ret < 0 then
			nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(nIndex));
			if nByQual > 80 then
				PushDebugMessage("#{SQSX_120806_61}")
				return
			end
			PushDebugMessage("#{SQSX_120806_32}")
			return
		end

		--	检测物品等级
		local nEquipLevel = LifeAbility : Get_Equip_Level(nIndex);
		if nEquipLevel ~= 86 and nEquipLevel ~= 96 and nEquipLevel ~= 102 then
			PushDebugMessage("#{SQSX_120806_32}")
			return
		end
		
		--	检测物品星级（品质）
		nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(nIndex));
		if nByQual < 10 then
			PushDebugMessage("#{SQSX_120806_32}")
			return
		end

		if nByQual > 80 then
			PushDebugMessage("#{SQSX_120806_61}")
			return
		end

		local starNum = math.floor(nByQual / 10);
		local nFit = math.mod(nByQual, 10);
		if starNum > 7 or starNum < 6 then
			PushDebugMessage("#{SQSX_120806_32}")
			return
		end

		if nFit ~= 9 then
			PushDebugMessage("#{SQSX_120806_32}")
			return
		end

		local nCashCount = PlayerPackage:GetSuperWeaponStarUpCashCost(nIndex)
		--	玩家身上的钱
		local nPlayerCashMoney = Player:GetData("MONEY");
		local nPlayerCashJiaoZi = Player:GetData("MONEY_JZ");

		g_SuperWeaponJJ_CashCost:SetProperty("MoneyNumber", nCashCount);
		g_SuperWeaponJJ_PlayerCashJiaoZi:SetProperty("MoneyNumber", nPlayerCashJiaoZi);
		g_SuperWeaponJJ_PlayerCash:SetProperty("MoneyNumber", nPlayerCashMoney);
		
		if g_SuperWeaponJJ_WeaponIndex > -1 then
			LifeAbility:Lock_Packet_Item(g_SuperWeaponJJ_WeaponIndex, 0);
		end
		g_SuperWeaponJJ_WeaponSlot:SetActionItem(theAction:GetID());
		g_SuperWeaponJJ_WeaponIndex = nIndex;
		LifeAbility:Lock_Packet_Item(g_SuperWeaponJJ_WeaponIndex, 1);
	end
end

