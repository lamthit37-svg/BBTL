
local g_SuperWeaponChange_WeaponSlot;
local g_SuperWeaponChange_WeaponIndex = -1;

local g_SuperWeaponChange_CashCost;
local g_SuperWeaponChange_PlayerCashJiaoZi;
local g_SuperWeaponChange_PlayerCash;

local g_SuperWeaponChange_Fram_UnifiedPosition;

local MAX_OBJ_DISTANCE = 3.0;
local g_ObjCared = -1;

function SuperWeaponChange_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("SUPERWEAPONVIRSUAL_PUTWEAPON");
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("ADJEST_UI_POS",false);		--	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);	--	窗口大小变换
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
end

function SuperWeaponChange_OnLoad()
	g_SuperWeaponChange_CashCost = SuperWeaponChange_CashNum;
	g_SuperWeaponChange_PlayerCashJiaoZi = SuperWeaponChange_JiaoZiNum;
	g_SuperWeaponChange_PlayerCash = SuperWeaponChange_CashMoney;
	g_SuperWeaponChange_WeaponSlot = SuperWeaponChange_Item;
	g_SuperWeaponChange_Fram_UnifiedPosition = SuperWeaponChange_Frame:GetProperty("UnifiedPosition");
end

function SuperWeaponChange_OnEvent(event)
	local objCared = DataPool:GetCurDialogNpcId();

	if event == "UI_COMMAND" then
		if tonumber(arg0) == 201208091 then
			g_ObjCared = objCared
			this:CareObject(objCared, 1, "SuperWeaponChange");
			SuperWeaponChange_UpdataMoney()
			this:Show()
			return
		end

		SuperWeaponChange_CancleEvent()
	end

	if event == "SUPERWEAPONVIRSUAL_PUTWEAPON" then
		if arg0 ~= nil then
			local nSlot = tonumber(arg0)
			local nIndex = tonumber(arg1)

			SuperWeaponChange_UpDataFrame(nSlot, nIndex)
		end
	end

	if event == "OBJECT_CARED_EVENT" then
		if (g_ObjCared ~= objCared) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy") then
			SuperWeaponChange_CancleEvent()
		end
	end

	if event == "ADJEST_UI_POS" then
		SuperWeaponChange_ResetWindowPos();
		return
	end

	if event == "VIEW_RESOLUTION_CHANGED" then
		SuperWeaponChange_ResetWindowPos()
		return;
	end

	if event == "MONEY_CHANGE_EX" then
		SuperWeaponChange_UpdataMoney();
		return;
	end

	if event == "MONEYJZ_CHANGE_EX" then
		SuperWeaponChange_UpdataMoney();
		return;
	end
end

function SuperWeaponChange_ResetWindowPos()
	SuperWeaponChange_Frame:SetProperty("UnifiedPosition", g_SuperWeaponChange_Fram_UnifiedPosition);
end

function SuperWeaponChange_ResetSlot()
	if g_SuperWeaponChange_WeaponIndex > -1 then
		LifeAbility:Lock_Packet_Item(g_SuperWeaponChange_WeaponIndex, 0);
		g_SuperWeaponChange_WeaponSlot:SetActionItem(-1);
		g_SuperWeaponChange_WeaponIndex = -1;
	end
	
	g_SuperWeaponChange_CashCost:SetProperty("MoneyNumber", 0);
end

function SuperWeaponChange_OKEvent()
	if g_SuperWeaponChange_WeaponIndex < 0 then
		PushDebugMessage("#{SQSX_120806_41}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoSuperWeaponStartUpAction")
		Set_XSCRIPT_ScriptID(890009)
		Set_XSCRIPT_Parameter(0, 4)
		Set_XSCRIPT_Parameter(1, g_SuperWeaponChange_WeaponIndex)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

	SuperWeaponChange_ResetSlot()
	SuperWeaponChange_UpdataMoney()
end

function SuperWeaponChange_CancleEvent()
	SuperWeaponChange_ResetSlot()

	this:CareObject(g_ObjCared, 0, "SuperWeaponChange");
	g_ObjCared = -1;

	this:Hide();
end

function SuperWeaponChange_UpdataMoney()
	--	玩家身上的钱
	local nPlayerCashMoney = Player:GetData("MONEY");
	local nPlayerCashJiaoZi = Player:GetData("MONEY_JZ");
	local nMoneyCost = 0;
	if g_SuperWeaponChange_WeaponIndex ~= -1 then
		nMoneyCost = PlayerPackage:GetSuperWeaponChangeVirsualCashCost(g_SuperWeaponChange_WeaponIndex)
	end
	g_SuperWeaponChange_CashCost:SetProperty("MoneyNumber", nMoneyCost);
	g_SuperWeaponChange_PlayerCashJiaoZi:SetProperty("MoneyNumber", nPlayerCashJiaoZi);
	g_SuperWeaponChange_PlayerCash:SetProperty("MoneyNumber", nPlayerCashMoney);
end

function SuperWeaponChange_UpDataFrame(nSlot, nIndex)
	if nSlot ~= 8 then
		return
	end

	if nIndex < 0 then
		return
	end

	local theAction = EnumAction(nIndex, "packageitem");
	if theAction:GetID() ~= 0 then
		local ret = LifeAbility : CheckSuperWeaponCanChangeVirsual(nIndex);
		if ret < 0 then
			PushDebugMessage("#{SQSX_120806_41}")
			return
		end

		local nCashCount = PlayerPackage:GetSuperWeaponChangeVirsualCashCost(nIndex)
		--	玩家身上的钱
		local nPlayerCashMoney = Player:GetData("MONEY");
		local nPlayerCashJiaoZi = Player:GetData("MONEY_JZ");

		g_SuperWeaponChange_CashCost:SetProperty("MoneyNumber", nCashCount);
		g_SuperWeaponChange_PlayerCashJiaoZi:SetProperty("MoneyNumber", nPlayerCashJiaoZi);
		g_SuperWeaponChange_PlayerCash:SetProperty("MoneyNumber", nPlayerCashMoney);

		if g_SuperWeaponChange_WeaponIndex > -1 then
			LifeAbility:Lock_Packet_Item(g_SuperWeaponChange_WeaponIndex, 0);
		end
		g_SuperWeaponChange_WeaponSlot:SetActionItem(theAction:GetID());
		g_SuperWeaponChange_WeaponIndex = nIndex;
		LifeAbility:Lock_Packet_Item(g_SuperWeaponChange_WeaponIndex, 1);
	end
end
