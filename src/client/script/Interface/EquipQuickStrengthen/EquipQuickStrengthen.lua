local Enchange_Item1 = -1;
local Enchange_Item2 = -1;
local g_Object = -1;
local g_check = -1;--是否二次确认

local g_JuanzhouType = {
				{38000552,-1,5},
				{38000548,-1,5},
				{38000553,-1,7},
				{38000549,-1,7},
				{38000554,-1,8},
				{38000550,-1,8},
				{38000555,-1,9},
				{38000551,-1,9},
				{38000873,8,9},
				{38000874,8,9},
				{38001094,-1,20},--新增卷轴数据：索引、需求等级、卷轴等级——元宝交易
				{38001095,-1,30},
				{38001096,-1,40},
				{38001097,-1,50},
				{38001098,-1,60},
				{38001099,-1,70},
				{38001100,-1,80},
				{38001101,-1,90},
				{38001102,-1,99},
				{38001103,-1,20},--新增卷轴数据：索引、需求等级、卷轴等级——绑定
				{38001104,-1,30},
				{38001105,-1,40},
				{38001106,-1,50},
				{38001107,-1,60},
				{38001108,-1,70},
				{38001109,-1,80},
				{38001110,-1,90},
				{38001111,-1,99}
				};

local g_EquipQuickStrengthen_Frame_UnifiedPosition;

function EquipQuickStrengthen_PreLoad()

	this:RegisterEvent("UI_COMMAND")

	this:RegisterEvent("PUT_QUICK_STENGTHEN_ITEM")
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("ENCHANCE_ITEM_CHANGE")
	this:RegisterEvent("TAKE_STENGTHEN_ITEM")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function EquipQuickStrengthen_OnLoad()

	g_EquipQuickStrengthen_Frame_UnifiedPosition=EquipQuickStrengthen_Frame:GetProperty("UnifiedPosition");
end

function EquipQuickStrengthen_OnEvent(event)
	if ( event == "UI_COMMAND" ) then
		if tonumber(arg0) == 20130510 then	--打开界面
			EquipQuickStrengthen_Clear();
			local xx = Get_XParam_INT(0);
			if tonumber(xx) == -1 then
				return
			end
			objCared = -1
			objCared = DataPool : GetNPCIDByServerID(xx);
			if tonumber(objCared)==nil or  tonumber(objCared)== -1 then
				PushDebugMessage("server传过来的数据有问题。");
				return;
			end
			this:Show();
			EquipQuickStrengthen_BeginCareObject(objCared);
		end
		if tonumber(arg0) == 20130511 then	--强化成功,清空界面
			EquipQuickStrengthen_Clear();
		end
	elseif  ( event == "PUT_QUICK_STENGTHEN_ITEM" ) then
		--更新窗口上的装备和卷轴
		if tonumber(arg0) == 10 or tonumber(arg0) == 11 or tonumber(arg0) == 12 then
			EquipQuickStrengthen_Update(arg0,arg1);
		end
	elseif  ( event == "ENCHANCE_ITEM_CHANGE" ) then
		--背包生成新物品的刷新
		if (Enchange_Item1 == tonumber(arg0)) then
			EquipQuickStrengthen_Update(10,arg0);
		end
		if (Enchange_Item2 == tonumber(arg0)) then
			EquipQuickStrengthen_Update(11,arg0);
		end
	elseif	( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if(tonumber(arg0) and PlayerPackage:GetItemTableIndex(tonumber(arg0)) == Enchange_Item2) then
				if(PlayerPackage:IsLock(tonumber(arg0)) == 1) then
					--push事件干掉msgbox
					LifeAbility:CloseStrengthMsgBox();
					return;
				end
		end
		if (Enchange_Item1 == tonumber(arg0)) then
			EquipQuickStrengthen_Update(10,arg0);
		end
		if (Enchange_Item2 == tonumber(arg0)) then
			EquipQuickStrengthen_Update(11,arg0);
		end
	elseif (event == "TAKE_STENGTHEN_ITEM") then
		if arg0 == "I10" then
			if Enchange_Item1 ~= -1 then
				EquipQuickStrengthen_Object1:SetActionItem(-1);
				LifeAbility : Lock_Packet_Item(Enchange_Item1,0);
				Enchange_Item1 = -1
			end
			g_check = -1;
			EquipQuickStrengthen_OK:Disable()
		elseif arg0 == "I11" then
			if Enchange_Item2 ~= -1 then
				EquipQuickStrengthen_Object2:SetActionItem(-1);
				LifeAbility : Lock_Packet_Item(Enchange_Item2,0);
				Enchange_Item2 = -1
			end
			g_check = -1;
			EquipQuickStrengthen_OK:Disable()
		end
		--EquipQuickStrengthen_Clear();

	elseif (event == "ADJEST_UI_POS" ) then
		EquipQuickStrengthen_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipQuickStrengthen_Frame_On_ResetPos()
	end
end

function EquipQuickStrengthen_BeginCareObject(objCared)
	g_Object = objCared;
	this:CareObject(tonumber(g_Object), 1, "EquipQuickStrengthen");
end

function EquipQuickStrengthen_Update(boxpos,Item_index)

	local i_index = tonumber(Item_index)
	local theAction = EnumAction(i_index, "packageitem");

	if theAction:GetID() ~= 0 then
		if(tonumber(boxpos) == 10) then
			--如果是装备
			local EquipPoint = LifeAbility : Get_Equip_Point(i_index)

			if EquipPoint == -1 or EquipPoint == 8 or EquipPoint == 9 or EquipPoint == 10 then
				if EquipPoint ~= -1 then
					PushDebugMessage("#{ZBQHJ_130508_15}")
				end
				return
			end
			
			--宗门装备暂时关闭
			if EquipPoint == 23 then
				PushDebugMessage("#{XWXT_230825_18}")
				return
			end
			
			if PlayerPackage:IsBagItemKFS(i_index) ==1 then  --武魂的限制
				PushDebugMessage("#{ZBQHJ_130508_12}")
				return
			end
			
			-- 15级神器不可以刻铭 by lishilong 2016-9-19 
			local nitemTableIndex = PlayerPackage : GetItemTableIndex( i_index )
			if nil == nitemTableIndex then
				return
			end
				
			if 10300422 == nitemTableIndex or 10302448 == nitemTableIndex or 
				10304426 == nitemTableIndex or 10305444 == nitemTableIndex or 10316042 == nitemTableIndex or
				10306042 == nitemTableIndex or 10307042 == nitemTableIndex or 10308042 == nitemTableIndex then
				PushDebugMessage("#{XSQSJ_160812_30}")
				return
			end

			if Enchange_Item1 ~= -1 then
				LifeAbility : Lock_Packet_Item(Enchange_Item1,0);
			end

			EquipQuickStrengthen_Object1:SetActionItem(theAction:GetID());
			LifeAbility : Lock_Packet_Item(i_index,1);
			Enchange_Item1 = i_index
		end

		if(tonumber(boxpos) == 11 or tonumber(boxpos) == 12 ) then
			--如果是卷轴
			local itemType = PlayerPackage : GetItemTableIndex( i_index );
			local isjuanzhou = 0;
			for i = 1,28 do--新增卷轴数量
				if g_JuanzhouType[i][1] == itemType then
					isjuanzhou = 1;
				end
			end

			if isjuanzhou == 1 then

				if PlayerPackage:IsLock(i_index) == 1 then
					local msg =  ScriptGlobal_Format("#{ZBQHJ_130508_13}", PlayerPackage:GetBagItemName(i_index))
					PushDebugMessage(msg);
					return
				end
				if Enchange_Item2 ~= -1 then
					LifeAbility : Lock_Packet_Item(Enchange_Item2,0);
				end

				EquipQuickStrengthen_Object2:SetActionItem(theAction:GetID());
				LifeAbility : Lock_Packet_Item(i_index,1);
				Enchange_Item2 = i_index
			else
				if(tonumber(boxpos) == 11) then
					PushDebugMessage("#{ZBQHJ_130508_17}")
				elseif (tonumber(boxpos) == 12) then
					PushDebugMessage("#{ZBQHJ_130508_14}")
				end
				return
			end
		end
		if Enchange_Item1 >= 0 and Enchange_Item2 >= 0 then
			EquipQuickStrengthen_OK:Enable()
			g_check = -1
		else
			EquipQuickStrengthen_OK:Disable()
		end
	else
			return;
	end
end

local EB_FREE_BIND = 0;				-- 无绑定限制
local EB_BINDED = 1;				-- 已经绑定
local	EB_GETUP_BIND =2			-- 拾取绑定
local	EB_EQUIP_BIND =3			-- 装备绑定
function EquipQuickStrengthen_Buttons_Clicked()
	 
	local msg = "";
	if Enchange_Item1 == -1 then
		PushDebugMessage("#{ZBQHJ_130508_19}")
		return
	end
	local EquipPoint = LifeAbility : Get_Equip_Point(Enchange_Item1)

	if EquipPoint == -1 or EquipPoint == 8 or EquipPoint == 9 or EquipPoint == 10 then
		if EquipPoint ~= -1 then
			PushDebugMessage("#{ZBQHJ_130508_15}")	--不是装备
		end
		return
	end
	
	--宗门装备暂时关闭
	if EquipPoint == 23 then
		PushDebugMessage("#{XWXT_230825_18}")
		return
	end
			
	if PlayerPackage:IsBagItemKFS(Enchange_Item1) ==1 then  --武魂的限制
		PushDebugMessage("#{ZBQHJ_130508_16}")
		return
	end
	------------------
	if Enchange_Item2 == -1 then
		PushDebugMessage("#{ZBQHJ_130508_20}")
		return
	end
	local itemType = PlayerPackage : GetItemTableIndex( Enchange_Item2 );
	local juanzhoulevel = 0;
	local equipneedlevel = -1;
	for i = 1,28 do--新增卷轴数量
		if g_JuanzhouType[i][1] == itemType then
			juanzhoulevel = g_JuanzhouType[i][3];
			equipneedlevel = g_JuanzhouType[i][2];
		end
	end
	if isjuanzhou == 0 then
		PushDebugMessage("#{ZBQHJ_130508_20}")	--不是卷轴
		return
	end

	if PlayerPackage:IsLock(Enchange_Item2) == 1 then
		msg =  ScriptGlobal_Format("#{ZBQHJ_130508_13}", PlayerPackage:GetBagItemName(Enchange_Item2))
		PushDebugMessage(msg);
		return
	end

	local curlevel = LifeAbility:Get_Equip_CurStrengthLevel(Enchange_Item1);
	if equipneedlevel == -1 and curlevel >= juanzhoulevel then
		PushDebugMessage("#{ZBQHJ_140310_1}")
		return
	end
	if equipneedlevel >= 0 and curlevel ~= equipneedlevel then
		msg =  ScriptGlobal_Format("#{ZBQHJ_140310_2}", equipneedlevel)
		PushDebugMessage(msg)
		return
	end

	-----------
	local BindState1 = PlayerPackage:GetItemBindStatusByIndex(tonumber(Enchange_Item1));
	local BindState2 = PlayerPackage:GetItemBindStatusByIndex(tonumber(Enchange_Item2));
	if BindState1 ~= EB_BINDED and BindState2 == EB_BINDED and g_check == -1 then
--~ 		if IsUnbindChongLouEquip(PlayerPackage:GetItemTableIndex(tonumber(Enchange_Item1))) == 1 then
--~ 			PushDebugMessage("#{ZBQHJ_130508_25}")
--~ 			return
--~ 		end
		local msg = "#{ZBQHJ_130508_24}"
		GameProduceLogin : ShowMessageBox( msg, "Close", "-1")
		g_check = 1;
		return
	end
	g_check = -1;
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("FinishQuickEnhance");
		Set_XSCRIPT_ScriptID(809262);
		Set_XSCRIPT_Parameter(0,Enchange_Item1);
		Set_XSCRIPT_Parameter(1,Enchange_Item2);
		Set_XSCRIPT_ParamCount(2);
	Send_XSCRIPT();

end

function EquipQuickStrengthen_Clear()
	if Enchange_Item1 ~= -1 then
		EquipQuickStrengthen_Object1:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(Enchange_Item1,0);
		Enchange_Item1 = -1
	end
	if Enchange_Item2 ~= -1 then
		EquipQuickStrengthen_Object2:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(Enchange_Item2,0);
		Enchange_Item2 = -1
	end
	g_check = -1;
	EquipQuickStrengthen_OK:Disable()
end

function EquipQuickStrengthen_OnHiden()
	EquipQuickStrengthen_Clear();
end

function EquipQuickStrengthen_Frame_On_ResetPos()
  EquipQuickStrengthen_Frame:SetProperty("UnifiedPosition", g_EquipQuickStrengthen_Frame_UnifiedPosition);
end

function EquipQuickStrengthen_Object1_RClicked()
	if Enchange_Item1 ~= -1 then
		EquipQuickStrengthen_Object1:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(Enchange_Item1,0);
		Enchange_Item1 = -1
	end
	g_check = -1;
	EquipQuickStrengthen_OK:Disable()
end

function EquipQuickStrengthen_Object2_RClicked()
	if Enchange_Item2 ~= -1 then
		EquipQuickStrengthen_Object2:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(Enchange_Item2,0);
		Enchange_Item2 = -1
	end
	g_check = -1;
	EquipQuickStrengthen_OK:Disable()
end
