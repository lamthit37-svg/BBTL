
local g_SuperWeapon9_TuPo_WeaponSlot;
local g_SuperWeapon9_TuPo_WeaponIndex = -1;

local g_SuperWeapon9_TuPo_Fram_UnifiedPosition;
local g_SuperWeapon9_TuPo_CashCost;
local g_SuperWeapon9_TuPo_PlayerCashJiaozi;
local g_SuperWeapon9_TuPo_PlayerCash;

local MAX_OBJ_DISTANCE = 3.0;
local g_ObjCared = -1;

function SuperWeapon9_TuPo_PreLoad()
	this:RegisterEvent("UI_COMMAND");		--	打开界面

	this:RegisterEvent("SUPERWEAPON9_DRAGEND");--挪出
	this:RegisterEvent("SUPERWEAPON9_TUPOPUT") --挪入

	this:RegisterEvent("ADJEST_UI_POS",false);		--	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);	--	窗口大小变换
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
end

function SuperWeapon9_TuPo_OnLoad()
	g_SuperWeapon9_TuPo_WeaponSlot = SuperWeapon9_TuPo_Item;

	g_SuperWeapon9_TuPo_CashCost = SuperWeapon9_TuPo_CashNum;
	g_SuperWeapon9_TuPo_PlayerCashJiaozi = SuperWeapon9_TuPo_JiaoZiNum;
	g_SuperWeapon9_TuPo_PlayerCash = SuperWeapon9_TuPo_CashMoney;
	g_SuperWeapon9_TuPo_Fram_UnifiedPosition = SuperWeapon9_TuPo_Frame:GetProperty("UnifiedPosition");
	
	--【九星神器引导任务】神器开蒙
	SuperWeapon9_TuPo_Item_Animate:Play(false)
	SuperWeapon9_TuPo_OK_Animate:Play(false)	
end

function SuperWeapon9_TuPo_OnEvent(event)

	if event == "UI_COMMAND" then
		if tonumber(arg0) == 7020061 then
			local bOpen=Get_XParam_INT(0);
			if bOpen==1 then
				local TargetServerID = Get_XParam_INT(1);
				g_ObjCared = DataPool:GetNPCIDByServerID(TargetServerID);
				if g_ObjCared==-1 then
					return
				end

				this:CareObject(g_ObjCared, 1, "SuperWeapon9_TuPo");
				SuperWeapon9_TuPo_UpdataMoney();
				
				--【九星神器引导任务】神器开蒙
				if DataPool:Lua_IsHaveMission(1950) > 0 then
					CloseFreshManGuide()
					local HaveItem = g_SuperWeapon9_TuPo_WeaponSlot:GetActionItem()
					if HaveItem < 0 then
						local fX, fY = this:GetChildOffset("SuperWeapon9_TuPo_Item")			
						OpenFreshManGuide(1, 193, fX+30, fY, "SuperWeapon9_TuPo", "northeast")
						SuperWeapon9_TuPo_Item_Animate:Play(true)
						SuperWeapon9_TuPo_OK_Animate:Play(false)
					else
						local fX, fY = this:GetChildOffset("SuperWeapon9_TuPo_OK")			
						OpenFreshManGuide(1, 194, fX+20, fY, "SuperWeapon9_TuPo", "northeast")
						SuperWeapon9_TuPo_Item_Animate:Play(false)
						SuperWeapon9_TuPo_OK_Animate:Play(true)					
					end
				end
				
				this:Show();
			else
				SuperWeapon9_TuPo_CancleEvent();
			end
		end

	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
		if arg0==nil or tonumber(arg0)==-1 then
			return
		end
		if arg0 ~= nil and tonumber(arg0)==g_SuperWeapon9_TuPo_WeaponIndex then
			SuperWeapon9_TuPo_ResetActionSlot()
		end
	end
	if event == "SUPERWEAPON9_TUPOPUT" and this:IsVisible() then
		if arg0 ~= nil then
			local nIndex = tonumber(arg0)
			SuperWeapon9_TuPo_UpDataSlot(nIndex)
			
			return;
		end
	elseif event=="SUPERWEAPON9_DRAGEND" and this:IsVisible() then
		if arg0 ~= nil and tonumber(arg0)==17 then
			SuperWeapon9_TuPo_ResetActionSlot()		
		end
	elseif event == "OBJECT_CARED_EVENT" then
		if(g_ObjCared ~= objCared) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			SuperWeapon9_TuPo_CancleEvent();
		end
	end

	if event == "ADJEST_UI_POS" then
		SuperWeapon9_TuPo_ResetWindowPos();
		return
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		SuperWeapon9_TuPo_ResetWindowPos()
		return;
	elseif event == "MONEY_CHANGE_EX" and this:IsVisible() then
		SuperWeapon9_TuPo_UpdataMoney();
		return;
	elseif event == "MONEYJZ_CHANGE_EX" and this:IsVisible() then
		SuperWeapon9_TuPo_UpdataMoney();
		return;
	end
end

function SuperWeapon9_TuPo_UpdataMoney()
	--	玩家身上的钱
	local nPlayerCashMoney = Player:GetData("MONEY");
	local nPlayerCashJiaoZi = Player:GetData("MONEY_JZ")
	if g_SuperWeapon9_TuPo_WeaponIndex < 0 then
		g_SuperWeapon9_TuPo_CashCost:SetProperty("MoneyNumber", 0);
	end
	g_SuperWeapon9_TuPo_PlayerCash:SetProperty("MoneyNumber", nPlayerCashMoney);
	g_SuperWeapon9_TuPo_PlayerCashJiaozi:SetProperty("MoneyNumber", nPlayerCashJiaoZi);
end

function SuperWeapon9_TuPo_TPCheck(nIndex)
	local theAction = EnumAction(nIndex, "packageitem");
	if theAction:GetID() ~= 0 then
		local EquipPoint = LifeAbility:Get_Equip_Point(nIndex)
		if EquipPoint~=0 then
			PushDebugMessage("#{JXSQ_170804_17}")
			return 0
		end
		local nEquipLevel = LifeAbility : Get_Equip_Level(nIndex);
		if nEquipLevel ~= 102 then
			PushDebugMessage("#{JXSQ_170804_17}")
			return 0
		end
		local nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(nIndex));
		if nByQual>100 then
			PushDebugMessage("#{JXSQ_170804_18}")
			return 0
		end
		if nByQual ~= 81 and nByQual ~=8 then
			PushDebugMessage("#{JXSQ_170804_17}")
			return 0
		end
		--
	else
		PushDebugMessage("#{JXSQ_170804_17}")
		return 0
	end
	return 1
end

function SuperWeapon9_TuPo_UpDataSlot(nIndex)
	if nIndex < 0 then
		return
	end
	if SuperWeapon9_TuPo_TPCheck(nIndex)==0 then
		return
	end

	local theAction = EnumAction(nIndex, "packageitem");
	if theAction:GetID() ~= 0 then
		if g_SuperWeapon9_TuPo_WeaponIndex ~= -1 then
			LifeAbility : Lock_Packet_Item(g_SuperWeapon9_TuPo_WeaponIndex, 0)
		end

		g_SuperWeapon9_TuPo_WeaponSlot:SetActionItem(theAction:GetID())
		g_SuperWeapon9_TuPo_WeaponIndex = nIndex
		LifeAbility : Lock_Packet_Item(g_SuperWeapon9_TuPo_WeaponIndex, 1)
		local nCashCost = PlayerPackage:GetSuperWeaponEnsoulCashCost(g_SuperWeapon9_TuPo_WeaponIndex)
		g_SuperWeapon9_TuPo_CashCost:SetProperty("MoneyNumber", nCashCost)
		
		--【九星神器引导任务】神器开蒙
		if DataPool:Lua_IsHaveMission(1950) > 0 then
			CloseFreshManGuide()
			local fX, fY = this:GetChildOffset("SuperWeapon9_TuPo_OK")			
			OpenFreshManGuide(1, 194, fX+20, fY, "SuperWeapon9_TuPo", "northeast")
			SuperWeapon9_TuPo_Item_Animate:Play(false)
			SuperWeapon9_TuPo_OK_Animate:Play(true)
		end			
	end
end

function SuperWeapon9_TuPo_ResetActionSlot()

	if this:IsVisible() then
		g_SuperWeapon9_TuPo_WeaponSlot:SetActionItem(-1)
		LifeAbility : Lock_Packet_Item(g_SuperWeapon9_TuPo_WeaponIndex, 0);
		g_SuperWeapon9_TuPo_WeaponIndex = -1;
		--【九星神器引导任务】神器开蒙
		if DataPool:Lua_IsHaveMission(1950) > 0 then
			CloseFreshManGuide()
			local HaveItem = g_SuperWeapon9_TuPo_WeaponSlot:GetActionItem()
			if HaveItem < 0 then
				local fX, fY = this:GetChildOffset("SuperWeapon9_TuPo_Item")			
				OpenFreshManGuide(1, 193, fX+30, fY, "SuperWeapon9_TuPo", "northeast")
				SuperWeapon9_TuPo_Item_Animate:Play(true)
				SuperWeapon9_TuPo_OK_Animate:Play(false)
			else
				local fX, fY = this:GetChildOffset("SuperWeapon9_TuPo_OK")			
				OpenFreshManGuide(1, 194, fX+20, fY, "SuperWeapon9_TuPo", "northeast")
				SuperWeapon9_TuPo_Item_Animate:Play(false)
				SuperWeapon9_TuPo_OK_Animate:Play(true)					
			end
		end		
	end
	g_SuperWeapon9_TuPo_CashCost:SetProperty("MoneyNumber", 0);
end

function SuperWeapon9_TuPo_OKEvent()
	if g_SuperWeapon9_TuPo_WeaponIndex < 0 then
		PushDebugMessage("#{JXSQ_170804_17}")
		return
	end

	--任务检测 server

	--money
	local nCashCost = PlayerPackage:GetSuperWeaponEnsoulCashCost(g_SuperWeapon9_TuPo_WeaponIndex)
	local nPlayerCashMoney = Player:GetData("MONEY");
	local nPlayerCashJiaoZi = Player:GetData("MONEY_JZ")
	if (nPlayerCashMoney+nPlayerCashJiaoZi) < nCashCost then
		PushDebugMessage("#{JXSQ_170804_26}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoSuperWeapon9Up")
		Set_XSCRIPT_ScriptID(702006)
		Set_XSCRIPT_Parameter(0, 1)
		Set_XSCRIPT_Parameter(1, g_SuperWeapon9_TuPo_WeaponIndex)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
--	PushEvent("SUPERWEAPON9_MAKESURE", g_SuperWeapon9_TuPo_WeaponIndex)
--	SuperWeapon9_TuPo_ResetActionSlot();
end


function SuperWeapon9_TuPo_CancleEvent()
	g_SuperWeapon9_TuPo_CashCost:SetProperty("MoneyNumber", 0);

	if g_SuperWeapon9_TuPo_WeaponIndex ~= -1 then
		g_SuperWeapon9_TuPo_WeaponSlot:SetActionItem(-1)
		LifeAbility : Lock_Packet_Item(g_SuperWeapon9_TuPo_WeaponIndex, 0);
		g_SuperWeapon9_TuPo_WeaponIndex = -1;
	end

	--【九星神器引导任务】神器开蒙
	CloseFreshManGuide() 
	SuperWeapon9_TuPo_Item_Animate:Play(false)
	SuperWeapon9_TuPo_OK_Animate:Play(false)
	
	this:CareObject(g_ObjCared, 0, "SuperWeapon9_TuPo");
	g_ObjCared = -1;
	this:Hide()
end

function SuperWeapon9_TuPo_ResetWindowPos()
	 SuperWeapon9_TuPo_Frame:SetProperty("UnifiedPosition", g_SuperWeapon9_TuPo_Fram_UnifiedPosition);
end

--【九星神器引导任务】神器开蒙
function SuperWeapon9_TuPo_OnMoved()
   if "SuperWeapon9_TuPo" == GetFreshManGuideOwner() then
        OpenFreshManGuide(2, -1, -1, -1)
   end
end
