
local g_SuperWeapon9_ShengXing_WeaponSlot;
local g_SuperWeapon9_ShengXing_WeaponIndex = -1;

local g_SuperWeapon9_ShengXing_Fram_UnifiedPosition;

local MAX_OBJ_DISTANCE = 3.0;
local g_ObjCared = -1;

function SuperWeapon9_ShengXing_PreLoad()
	this:RegisterEvent("UI_COMMAND");		--	打开界面

	this:RegisterEvent("SUPERWEAPON9_DRAGEND");--挪出
	this:RegisterEvent("SUPERWEAPON9_SX") --挪入

	this:RegisterEvent("ADJEST_UI_POS",false);		--	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);	--	窗口大小变换
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
end

function SuperWeapon9_ShengXing_OnLoad()
	g_SuperWeapon9_ShengXing_WeaponSlot = SuperWeapon9_ShengXing_Item;
end

function SuperWeapon9_ShengXing_OnEvent(event)
	if event == "UI_COMMAND" then
		if tonumber(arg0) == 7020066 then
			local bOpen=Get_XParam_INT(0);
			if bOpen==1 then
				local TargetServerID = Get_XParam_INT(1);
				g_ObjCared = DataPool:GetNPCIDByServerID(TargetServerID);
				if g_ObjCared==-1 then
					return
				end

				this:CareObject(g_ObjCared, 1, "SuperWeapon9_ShengXing");
				this:Show();
			else
				SuperWeapon9_ShengXing_CancleEvent();
			end
		end

	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
		if arg0==nil or tonumber(arg0)==-1 then
			return
		end
		if arg0 ~= nil and tonumber(arg0)==g_SuperWeapon9_ShengXing_WeaponIndex then
			SuperWeapon9_ShengXing_ResetActionSlot()
		end
	end
	if event == "SUPERWEAPON9_SX" and this:IsVisible() then
		if arg0 ~= nil then
			local nIndex = tonumber(arg0)
			SuperWeapon9_ShengXing_UpDataSlot(nIndex)
			return;
		end
	elseif event=="SUPERWEAPON9_DRAGEND" and this:IsVisible() then
		if arg0 ~= nil and tonumber(arg0)==20 then
			SuperWeapon9_ShengXing_ResetActionSlot()
		end
	elseif event == "OBJECT_CARED_EVENT" then
		if(g_ObjCared ~= objCared) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			SuperWeapon9_ShengXing_CancleEvent();
		end
	end

	if event == "ADJEST_UI_POS" then
		SuperWeapon9_ShengXing_ResetWindowPos();
		return
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		SuperWeapon9_ShengXing_ResetWindowPos()
		return;
	end
end

function SuperWeapon9_ShengXing_SXCheck(nIndex)
	local theAction = EnumAction(nIndex, "packageitem");
	if theAction:GetID() ~= 0 then
		local EquipPoint = LifeAbility:Get_Equip_Point(nIndex)
		if EquipPoint~=0 then
			PushDebugMessage("#{JXSQ_170804_54}")
			return 0
		end
		local nEquipLevel = LifeAbility : Get_Equip_Level(nIndex);
		if nEquipLevel ~= 102 then
			PushDebugMessage("#{JXSQ_170804_54}")
			return 0
		end
		local nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(nIndex));
		if nByQual ~= 120 then
			PushDebugMessage("#{JXSQ_170804_54}")
			return 0
		end
		local ret = LifeAbility : CheckSuperWeaponCanStarUp(nIndex)
		if ret<0 then
			PushDebugMessage("#{JXSQ_170804_54}")
			return 0
		end
	else
		PushDebugMessage("#{JXSQ_170804_54}")
		return 0
	end
	return 1
end
function SuperWeapon9_ShengXing_UpDataSlot(nIndex)
	if nIndex < 0 then
		return
	end

	if SuperWeapon9_ShengXing_SXCheck(nIndex)==0 then
		return
	end
	local theAction = EnumAction(nIndex, "packageitem");
	if theAction:GetID() ~= 0 then
		if g_SuperWeapon9_ShengXing_WeaponIndex ~= -1 then
			LifeAbility : Lock_Packet_Item(g_SuperWeapon9_ShengXing_WeaponIndex, 0)
		end

		g_SuperWeapon9_ShengXing_WeaponSlot:SetActionItem(theAction:GetID())
		g_SuperWeapon9_ShengXing_WeaponIndex = nIndex
		LifeAbility : Lock_Packet_Item(g_SuperWeapon9_ShengXing_WeaponIndex, 1)

	end
end

function SuperWeapon9_ShengXing_ResetActionSlot()

	if this:IsVisible() then
		g_SuperWeapon9_ShengXing_WeaponSlot:SetActionItem(-1)
		LifeAbility : Lock_Packet_Item(g_SuperWeapon9_ShengXing_WeaponIndex, 0);
		g_SuperWeapon9_ShengXing_WeaponIndex = -1;
	end
end

function SuperWeapon9_ShengXing_OKEvent()
	if g_SuperWeapon9_ShengXing_WeaponIndex < 0 then
		PushDebugMessage("#{JXSQ_170804_57}")
		return
	end

	--任务检测 server

	if SuperWeapon9_ShengXing_SXCheck(g_SuperWeapon9_ShengXing_WeaponIndex)==0 then
		return
	end
	--gogogo
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoSuperWeapon9Up")
		Set_XSCRIPT_ScriptID(702006)
		Set_XSCRIPT_Parameter(0, 3)
		Set_XSCRIPT_Parameter(1, g_SuperWeapon9_ShengXing_WeaponIndex)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function SuperWeapon9_ShengXing_CancleEvent()
	if g_SuperWeapon9_ShengXing_WeaponIndex ~= -1 then
		g_SuperWeapon9_ShengXing_WeaponSlot:SetActionItem(-1)
		LifeAbility : Lock_Packet_Item(g_SuperWeapon9_ShengXing_WeaponIndex, 0);
		g_SuperWeapon9_ShengXing_WeaponIndex = -1;
	end

	this:CareObject(g_ObjCared, 0, "SuperWeapon9_ShengXing");
	g_ObjCared = -1;
	this:Hide()
end

function SuperWeapon9_ShengXing_ResetWindowPos()
	 SuperWeapon9_ShengXing_Frame:SetProperty("UnifiedPosition", g_SuperWeapon9_ShengXing_Fram_UnifiedPosition);
end
