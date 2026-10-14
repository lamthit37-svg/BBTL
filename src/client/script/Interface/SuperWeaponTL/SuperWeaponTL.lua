
local g_SuperWeaponTL_WeaponSlot;
local g_SuperWeaponTL_MaterialSlot;
local g_SuperWeaponTL_WeaponIndex = -1;
local g_SuperWeaponTL_MaterialIndex = -1;

local g_SuperWeaponTL_Fram_UnifiedPosition;
local g_SuperWeaponTL_CashCost;
local g_SuperWeaponTL_PlayerCashJiaozi;
local g_SuperWeaponTL_PlayerCash;

local MAX_OBJ_DISTANCE = 3.0;
local g_ObjCared = -1;
local g_TargetServerID = -1;

function SuperWeaponTL_PreLoad()
	this:RegisterEvent("UI_COMMAND");		--	打开界面
	this:RegisterEvent("SUPERWEAPONENSOUL_PUTWEAPON");		--	打开界面
	this:RegisterEvent("SUPERWEAPONENSOUL_PUTMATERIAL");		--	打开界面
	this:RegisterEvent("ADJEST_UI_POS",false);		--	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);	--	窗口大小变换
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
end

function SuperWeaponTL_OnLoad()
	g_SuperWeaponTL_WeaponSlot = SuperWeaponTL_Item1;
	g_SuperWeaponTL_MaterialSlot = SuperWeaponTL_Item2;
	g_SuperWeaponTL_CashCost = SuperWeaponTL_CashNum;
	g_SuperWeaponTL_PlayerCashJiaozi = SuperWeaponTL_JiaoZiNum;
	g_SuperWeaponTL_PlayerCash = SuperWeaponTL_CashMoney;
	g_SuperWeaponTL_Fram_UnifiedPosition = SuperWeaponTL_Frame:GetProperty("UnifiedPosition");
end

function SuperWeaponTL_OnEvent(event)
	local objCared = DataPool:GetCurDialogNpcId();
	if event == "UI_COMMAND" then
		
		if tonumber(arg0) == 201208094 then
			g_TargetServerID = Get_XParam_INT(0);
			g_ObjCared = objCared
			this:CareObject(objCared, 1, "SuperWeaponTL");
			SuperWeaponTL_UpdataFrame();
			this:Show();
			return;
		end

		--	关闭窗口
		if tonumber(arg0) == 201208095 then
			SuperWeaponTL_CancleEvent();
			return;
		end
		SuperWeaponTL_CancleEvent();
		return;
	end
	
	if event == "SUPERWEAPONENSOUL_PUTWEAPON" then
		if arg0 ~= nil then
			local nSlot = tonumber(arg0)
			local nIndex = tonumber(arg1)
			SuperWeaponTL_UpDataSlot(nSlot, nIndex)
			return;
		end
		return;
	end

	if event == "SUPERWEAPONENSOUL_PUTMATERIAL" then
		if arg0 ~= nil then
			local nSlot = tonumber(arg0)
			local nIndex = tonumber(arg1)
			SuperWeaponTL_UpDataSlot(nSlot, nIndex)
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
			SuperWeaponTL_CancleEvent();
		end
	end

	if event == "ADJEST_UI_POS" then
		SuperWeaponTL_ResetWindowPos();
		return
	end

	if event == "VIEW_RESOLUTION_CHANGED" then
		SuperWeaponTL_ResetWindowPos()
		return;
	end

	if event == "MONEY_CHANGE_EX" then
		SuperWeaponTL_UpdataFrame();
		return;
	end

	if event == "MONEYJZ_CHANGE_EX" then
		SuperWeaponTL_UpdataFrame();
		return;
	end
end

function SuperWeaponTL_UpdataFrame()
	--	玩家身上的钱
	local nPlayerCashMoney = Player:GetData("MONEY");
	local nPlayerCashJiaoZi = Player:GetData("MONEY_JZ")
	if g_SuperWeaponTL_WeaponIndex < 0 then
		g_SuperWeaponTL_CashCost:SetProperty("MoneyNumber", 0);
	end
	g_SuperWeaponTL_PlayerCash:SetProperty("MoneyNumber", nPlayerCashMoney);
	g_SuperWeaponTL_PlayerCashJiaozi:SetProperty("MoneyNumber", nPlayerCashJiaoZi);
end

function SuperWeaponTL_UpDataSlot(nSlot, nIndex)
	
	if nSlot ~= 4 and nSlot ~= 5 then
		return
	end

	if nIndex < 0 then
		return
	end

	local theAction = EnumAction(nIndex, "packageitem");

	if nSlot == 4 then
		if theAction:GetID() ~= 0 then
			local nEquipLevel = LifeAbility : Get_Equip_Level(nIndex);
			if nEquipLevel ~= 86 and nEquipLevel ~= 96 and nEquipLevel ~= 102 then
				PushDebugMessage("#{SQSX_120806_11}")
				return
			end
			local nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(nIndex));
			local ret = LifeAbility : CheckSuperWeaponCanEnsoul(nIndex)
			if ret < 0 then
				nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(nIndex));
				if nByQual > 80 then
					PushDebugMessage("#{SQSX_120806_61}")
					return
				end
				
				if nByQual == 5 then
					PushDebugMessage("#{SQSX_120806_62}")
					return
				end
				
				PushDebugMessage("#{SQSX_120806_11}")
				return
			end
			
				--	检测物品星级（品质）
			nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(nIndex));
			if nByQual > 6 then
				PushDebugMessage("#{SQSX_120806_11}")
				return
			end

			if nByQual < 6 then
				PushDebugMessage("#{SQSX_120806_11}")
				return
			end

			if g_SuperWeaponTL_WeaponIndex ~= -1 then
				LifeAbility : Lock_Packet_Item(g_SuperWeaponTL_WeaponIndex, 0)
			end
			--	玩家身上的钱
			local nPlayerCashMoney = Player:GetData("MONEY");
			local nPlayerCashJiaoZi = Player:GetData("MONEY_JZ")

			g_SuperWeaponTL_WeaponSlot:SetActionItem(theAction:GetID())
			g_SuperWeaponTL_WeaponIndex = nIndex
			LifeAbility : Lock_Packet_Item(g_SuperWeaponTL_WeaponIndex, 1)
			local nCashCost = PlayerPackage:GetSuperWeaponEnsoulCashCost(g_SuperWeaponTL_WeaponIndex)
			g_SuperWeaponTL_CashCost:SetProperty("MoneyNumber", nCashCost);
			g_SuperWeaponTL_PlayerCash:SetProperty("MoneyNumber", nPlayerCashMoney);
			g_SuperWeaponTL_PlayerCashJiaozi:SetProperty("MoneyNumber", nPlayerCashJiaoZi);
		end
	elseif nSlot == 5 then
		if theAction:GetID() ~= 0 then
			if g_SuperWeaponTL_WeaponIndex < 0 then
				PushDebugMessage("#{SQSX_120806_12}")
				return
			end
			
			local nItemID = PlayerPackage:GetItemTableIndex(nIndex)
			local nMaterialID = PlayerPackage:GetSuperWeaponEnsoulMaterialID(g_SuperWeaponTL_WeaponIndex)
			if nItemID ~= nMaterialID then
				PushDebugMessage("#{SQSX_120806_13}")
				return
			end

			if g_SuperWeaponTL_MaterialIndex ~= -1 then
				LifeAbility : Lock_Packet_Item(g_SuperWeaponTL_MaterialIndex, 0)
			end

			g_SuperWeaponTL_MaterialSlot:SetActionItem(theAction:GetID())
			g_SuperWeaponTL_MaterialIndex = nIndex
			LifeAbility : Lock_Packet_Item(g_SuperWeaponTL_MaterialIndex, 1)	
		end
	end
end

function SuperWeaponTL_ResetActionSlot(nIndex)
	if nIndex < 4 or nIndex > 5 then
		return
	end

	if this:IsVisible() then
		if nIndex == 4 then
			g_SuperWeaponTL_WeaponSlot:SetActionItem(-1)
			LifeAbility : Lock_Packet_Item(g_SuperWeaponTL_WeaponIndex, 0);
			g_SuperWeaponTL_WeaponIndex = -1;
		elseif nIndex == 5 then
			g_SuperWeaponTL_MaterialSlot:SetActionItem(-1)
			LifeAbility : Lock_Packet_Item(g_SuperWeaponTL_MaterialIndex, 0);
			g_SuperWeaponTL_MaterialIndex = -1;		
		end
	end

	SuperWeaponTL_UpdataFrame()
end

function SuperWeaponTL_OkEvent()
	if g_SuperWeaponTL_WeaponIndex < 0 then
		PushDebugMessage("#{SQSX_120806_12}")
		return
	end

	if g_SuperWeaponTL_MaterialIndex < 0 then
		strWeaponName = PlayerPackage:GetBagItemName(g_SuperWeaponTL_WeaponIndex)
		strMaterialName = PlayerPackage:GetSuperWeaponEnsoulMaterialName(g_SuperWeaponTL_WeaponIndex)
		PushDbgMsgEx("#{SQSX_120806_17}", strWeaponName, 1, strMaterialName)
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoSuperWeaponStartUpAction")
		Set_XSCRIPT_ScriptID(890009)
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_Parameter(1, g_SuperWeaponTL_WeaponIndex)
		Set_XSCRIPT_Parameter(2, g_SuperWeaponTL_MaterialIndex)
		Set_XSCRIPT_Parameter(3, g_TargetServerID)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
	
--	SuperWeaponTL_ResetActionSlot(4);
--	SuperWeaponTL_ResetActionSlot(5);
	SuperWeaponTL_UpdataFrame();
end

function SuperWeaponTL_CancleEvent()
	g_SuperWeaponTL_CashCost:SetProperty("MoneyNumber", 0);

	if g_SuperWeaponTL_WeaponIndex ~= -1 then
		g_SuperWeaponTL_WeaponSlot:SetActionItem(-1)
		LifeAbility : Lock_Packet_Item(g_SuperWeaponTL_WeaponIndex, 0);
		g_SuperWeaponTL_WeaponIndex = -1;
	end

	if g_SuperWeaponTL_MaterialIndex ~= -1 then
		g_SuperWeaponTL_MaterialSlot:SetActionItem(-1)
		LifeAbility : Lock_Packet_Item(g_SuperWeaponTL_MaterialIndex, 0);
		g_SuperWeaponTL_MaterialIndex = -1;
	end

	this:CareObject(g_ObjCared, 0, "SuperWeaponTL");
	g_ObjCared = -1;

	g_TargetServerID = -1;

	this:Hide()
end

function SuperWeaponTL_ResetWindowPos()
	 SuperWeaponTL_Frame:SetProperty("UnifiedPosition", g_SuperWeaponTL_Fram_UnifiedPosition);
end
