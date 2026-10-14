
local g_SuperWeapon9_Change_WeaponSlot;
local g_SuperWeapon9_Change_WeaponIndex = -1;

local g_SuperWeapon9_Change_CashCost;
local g_SuperWeapon9_Change_PlayerCashJiaoZi;
local g_SuperWeapon9_Change_PlayerCash;

local g_SuperWeapon9_Change_Fram_UnifiedPosition;

local MAX_OBJ_DISTANCE = 3.0;
local g_ObjCared = -1;

function SuperWeapon9_Change_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("SUPERWEAPON9_WGCHANGE");
	this:RegisterEvent("SUPERWEAPON9_DRAGEND");--挪出
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("ADJEST_UI_POS",false);		--	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);	--	窗口大小变换
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("REFRESH_EQUIP",false);
end

function SuperWeapon9_Change_OnLoad()
	g_SuperWeapon9_Change_CashCost = SuperWeapon9_Change_DemandMoney;
	g_SuperWeapon9_Change_PlayerCashJiaoZi = SuperWeapon9_Change_SelfJiaozi;
	g_SuperWeapon9_Change_PlayerCash = SuperWeapon9_Change_SelfMoney;
	g_SuperWeapon9_Change_WeaponSlot = SuperWeapon9_Change_Object;
	g_SuperWeapon9_Change_Fram_UnifiedPosition = SuperWeapon9_Change_Frame:GetProperty("UnifiedPosition");
end

function SuperWeapon9_Change_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 7020065 then
		local bOpen=Get_XParam_INT(0);
		if bOpen==1 then
			local TargetServerID = Get_XParam_INT(1);
			g_ObjCared = DataPool:GetNPCIDByServerID(TargetServerID);
			if g_ObjCared==-1 then
				return
			end
			this:CareObject(g_ObjCared, 1, "SuperWeapon9_Change");
			SuperWeapon9_Change_UpdataMoney()
			SuperWeapon9_Change_Choice:SetText("#{JXSQ_170810_160}")
			SuperWeapon9_Change_Choice:Disable()
			SuperWeapon9_Change_Choice_Pic:Show()
			SuperWeapon9_Change_Fitting_FakeObject:SetFakeObject("")
			this:Show()
--		SuperWeapon9_Change_CancleEvent()
		elseif bOpen==0 then
			local iWeaponIndex=Get_XParam_INT(1);
			local okWG = Get_XParam_INT(2);
			if iWeaponIndex>=0 and okWG>0 then
				local n9ID,str9WG,n8ID,str8WG,n5ID,str5WG,needMoney = PlayerPackage:GetSuperWeapon9WG(iWeaponIndex,"tbl")
				if okWG==n9ID then
					local str = ScriptGlobal_Format("#{JXSQ_170810_165}", str9WG)
					PushDebugMessage(str)
				elseif okWG==n8ID then
					local str = ScriptGlobal_Format("#{JXSQ_170810_165}", str8WG)
					PushDebugMessage(str)
				elseif okWG==n5ID then
					local str = ScriptGlobal_Format("#{JXSQ_170810_165}", str5WG)
					PushDebugMessage(str)
				end
			end
			SuperWeapon9_Change_CancleEvent()
		end
	end

	if event == "SUPERWEAPON9_WGCHANGE" and this:IsVisible() then
		if arg0 ~= nil then
			local nIndex = tonumber(arg0)
			SuperWeapon9_Change_UpDataFrame(nIndex)
		end
	elseif event == "SUPERWEAPON9_DRAGEND" then
		if arg0 ~= nil and tonumber(arg0)==19 then
			SuperWeapon9_Change_ResetSlot()
		end
	elseif event == "REFRESH_EQUIP" then
		SuperWeapon9_Change_ResetSlot()
	end

	if event == "OBJECT_CARED_EVENT" then
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1=="destroy") then
			SuperWeapon9_Change_CancleEvent()
		end
	end

	if event == "ADJEST_UI_POS" then
		SuperWeapon9_Change_ResetWindowPos();
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		SuperWeapon9_Change_ResetWindowPos()
	elseif (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and this:IsVisible() then
		SuperWeapon9_Change_UpdataMoney();
	end
end

function SuperWeapon9_Change_ResetWindowPos()
	SuperWeapon9_Change_Frame:SetProperty("UnifiedPosition", g_SuperWeapon9_Change_Fram_UnifiedPosition);
end

function SuperWeapon9_Change_ResetSlot()
	if g_SuperWeapon9_Change_WeaponIndex > -1 then
		LifeAbility:Lock_Packet_Item(g_SuperWeapon9_Change_WeaponIndex, 0);
		g_SuperWeapon9_Change_WeaponSlot:SetActionItem(-1);
		g_SuperWeapon9_Change_WeaponIndex = -1;
	end
	
	g_SuperWeapon9_Change_CashCost:SetProperty("MoneyNumber", 0);
	SuperWeapon9_Change_Choice:SetText("#{JXSQ_170810_160}")
	SuperWeapon9_Change_Choice:Disable()
	SuperWeapon9_Change_Choice_Pic:Show()
	SuperWeapon9_Change_Fitting_FakeObject:SetFakeObject("")

	LifeAbility:Wear_Equip_SetStopState(0)
end

function SuperWeapon9_Change_OKEvent()
	if g_SuperWeapon9_Change_WeaponIndex < 0 then
		PushDebugMessage("#{JXSQ_170810_158}")
		return
	end
	-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	-- 二级密码 电话密保检查
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
	if SuperWeapon9_Change_EquipChange(g_SuperWeapon9_Change_WeaponIndex)==0 then
		return
	end
	local sSel,iSel =  SuperWeapon9_Change_Choice:GetCurrentSelect()
	local n9ID,str9WG,n8ID,str8WG,n5ID,str5WG,needMoney = PlayerPackage:GetSuperWeapon9WG(g_SuperWeapon9_Change_WeaponIndex,"tbl")
	local nPlayerCashMoney = Player:GetData("MONEY");
	local nPlayerCashJiaoZi = Player:GetData("MONEY_JZ");
	if (nPlayerCashMoney+nPlayerCashJiaoZi) < needMoney then
		PushDebugMessage("#{JXSQ_170810_164}")
		return
	end
	local iSelID=0
	if iSel==1 then
		iSelID=n5ID
	elseif iSel==2 then
		iSelID=n8ID
	elseif iSel==3 then
		iSelID=n9ID
	else
		PushDebugMessage("#{JXSQ_170810_162}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoSuperWeapon9Up")
		Set_XSCRIPT_ScriptID(702006)
		Set_XSCRIPT_Parameter(0, 5)
		Set_XSCRIPT_Parameter(1, g_SuperWeapon9_Change_WeaponIndex)
		Set_XSCRIPT_Parameter(2, iSelID)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

	SuperWeapon9_Change_ResetSlot()
	SuperWeapon9_Change_UpdataMoney()
end

function SuperWeapon9_Change_CancleEvent()
	SuperWeapon9_Change_ResetSlot()

	this:CareObject(g_ObjCared, 0, "SuperWeapon9_Change");
	g_ObjCared = -1;

	this:Hide();
end

function SuperWeapon9_Change_UpdataMoney()

	if g_SuperWeapon9_Change_WeaponIndex ~= -1 then
		local _,_,_,_,_,_,nMoneyCost = PlayerPackage:GetSuperWeapon9WG(g_SuperWeapon9_Change_WeaponIndex,"tbl")
		if nMoneyCost==nil then
			return
		end
		g_SuperWeapon9_Change_CashCost:SetProperty("MoneyNumber", nMoneyCost);
	end
	--	玩家身上的钱
	local nPlayerCashMoney = Player:GetData("MONEY");
	local nPlayerCashJiaoZi = Player:GetData("MONEY_JZ");
	g_SuperWeapon9_Change_PlayerCashJiaoZi:SetProperty("MoneyNumber", nPlayerCashJiaoZi);
	g_SuperWeapon9_Change_PlayerCash:SetProperty("MoneyNumber", nPlayerCashMoney);
end

function SuperWeapon9_Change_EquipChange(nIndex)
	local theAction = EnumAction(nIndex, "packageitem");
	if theAction:GetID() ~= 0 then
		local EquipPoint = LifeAbility:Get_Equip_Point(nIndex)
		if EquipPoint~=0 then
			PushDebugMessage("#{JXSQ_170810_158}")
			return 0
		end
		local nEquipLevel = LifeAbility:Get_Equip_Level(nIndex);
		if nEquipLevel ~= 102 then
			PushDebugMessage("#{JXSQ_170810_158}")
			return 0
		end
		local nByQual = tonumber(PlayerPackage:GetSuperWeaponQual(nIndex));
		if nByQual ~= 9 then
			PushDebugMessage("#{JXSQ_170810_158}")
			return 0
		end
	else
		PushDebugMessage("#{JXSQ_170810_158}")
		return 0
	end
	return 1
end
function SuperWeapon9_Change_UpDataFrame(nIndex)
	if nIndex < 0 then
		return
	end

	if SuperWeapon9_Change_EquipChange(nIndex)==0 then
		return
	end

	local theAction = EnumAction(nIndex, "packageitem");
	if theAction:GetID() ~= 0 then
		local n9ID,str9WG,n8ID,str8WG,n5ID,str5WG,needMoney = PlayerPackage:GetSuperWeapon9WG(nIndex,"tbl")
		if n9ID==nil or n9ID==-1 then
			PushDebugMessage("#{JXSQ_170810_158}")
			return
		end

		g_SuperWeapon9_Change_CashCost:SetProperty("MoneyNumber", needMoney);
		if g_SuperWeapon9_Change_WeaponIndex > -1 then
			LifeAbility:Lock_Packet_Item(g_SuperWeapon9_Change_WeaponIndex, 0);
		end
		g_SuperWeapon9_Change_WeaponSlot:SetActionItem(theAction:GetID());
		g_SuperWeapon9_Change_WeaponIndex = nIndex;
		LifeAbility:Lock_Packet_Item(g_SuperWeapon9_Change_WeaponIndex, 1);
		--更新 TLBB_ComboList
		local nCurWGID = PlayerPackage:GetSuperWeapon9WG(nIndex,"cur")
		SuperWeapon9_Change_Choice:Enable()
		SuperWeapon9_Change_Choice:SetText("#{JXSQ_170810_160}")
		SuperWeapon9_Change_Choice:ResetList()

--		SuperWeapon9_Change_Choice:AddTextItem("sel", 0)
		if nCurWGID==n9ID then
			SuperWeapon9_Change_Choice:AddTextItem(str5WG, 1)
			SuperWeapon9_Change_Choice:AddTextItem(str8WG, 2)
		elseif nCurWGID==n8ID then
			SuperWeapon9_Change_Choice:AddTextItem(str5WG, 1)
			SuperWeapon9_Change_Choice:AddTextItem(str9WG, 3)
		elseif nCurWGID==n5ID then
			SuperWeapon9_Change_Choice:AddTextItem(str8WG, 2)
			SuperWeapon9_Change_Choice:AddTextItem(str9WG, 3)
		else
		end
--		SuperWeapon9_Change_Choice:SetCurrentSelect(-1);
		SuperWeapon9_Change_Choice_Pic:Hide()
		--当前外形 
		SuperWeapon9_Change_Fitting_FakeObject:SetFakeObject("");	
		SuperWeapon9_Change_Fitting_FakeObject:SetFakeObject("EquipChange_Player");	
		--让人穿上
		LifeAbility : Wear_Equip_VisualID(g_SuperWeapon9_Change_WeaponIndex,nCurWGID)
	end
end

function SuperWeapon9_Change_SelChanged()
	if g_SuperWeapon9_Change_WeaponIndex==-1 then
		return
	end
	local sSel,iSel =  SuperWeapon9_Change_Choice:GetCurrentSelect()
	local n9ID,str9WG,n8ID,str8WG,n5ID,str5WG,needMoney = PlayerPackage:GetSuperWeapon9WG(g_SuperWeapon9_Change_WeaponIndex,"tbl")
	if n9ID==nil or n9ID==-1 then
		return
	end
	local iSelID=0
	if iSel==1 then
		iSelID=n5ID
	elseif iSel==2 then
		iSelID=n8ID
	elseif iSel==3 then
		iSelID=n9ID
	end
	if iSelID==0 then
		return
	end
	--当前外形
	SuperWeapon9_Change_Fitting_FakeObject:SetFakeObject("");	
	SuperWeapon9_Change_Fitting_FakeObject:SetFakeObject("EquipChange_Player");	
	--让人穿上
	LifeAbility : Wear_Equip_VisualID(g_SuperWeapon9_Change_WeaponIndex, iSelID)
end

function SuperWeapon9_Change_Fitting_TurnLeft(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向左旋转开始
		if(start == 1) then
			SuperWeapon9_Change_Fitting_FakeObject:RotateBegin(-0.3);
		--向左旋转结束
		else
			SuperWeapon9_Change_Fitting_FakeObject:RotateEnd();
		end
	end
end

function SuperWeapon9_Change_Fitting_TurnRight(start)
	local mouse_button = CEArg:GetValue("MouseButton");
	if(mouse_button == "LeftButton") then
		--向右旋转开始
		if(start == 1) then
			SuperWeapon9_Change_Fitting_FakeObject:RotateBegin(0.3);
		--向右旋转结束
		else
			SuperWeapon9_Change_Fitting_FakeObject:RotateEnd();
		end
	end
end
