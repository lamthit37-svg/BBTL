local Enchange_Item1 = -1;
local Enchange_Item2 = -1;
local TianGangWuPinID = 30900006;	--天罡强化精华物品ID
local TianGangCaiLiaoID = 20600050;  --天罡强化精华材料ID
local g_Object = -1;
local QianghualuId = 30900045

local g_EnhanceQHJH1 = 38000571	--至尊强化精华（绑定）
local g_EnhanceQHJH2 = 38000572 --至尊强化精华（不绑定）

local g_CheckQuickUp = 0;
local g_QuickUpState = 0;


local EB_FREE_BIND = 0;				-- 无绑定限制
local EB_BINDED = 1;				-- 已经绑定
local	EB_GETUP_BIND =2			-- 拾取绑定
local	EB_EQUIP_BIND =3			-- 装备绑定

local g_EquipStrengthen_Frame_UnifiedPosition;

function EquipStrengthen_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	--this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("PUT_STENGTHEN_ITEM",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("TAKE_STENGTHEN_ITEM",true)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false); --zchw
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("EQUIPSTRENGTH_QUICK_CONFIRM_RET",false) --装备自动强化二次确认，确认为完毕返回
end

function EquipStrengthen_OnLoad()

	g_EquipStrengthen_Frame_UnifiedPosition=EquipStrengthen_Frame:GetProperty("UnifiedPosition");
end

function EquipStrengthen_OnEvent(event)
	if ( event == "UI_COMMAND" ) then
		if tonumber(arg0) == 1002 then
			EquipStrengthen_Clear();
			Init_EquipStrengthen_Frame();
			objCared = -1
			local xx = Get_XParam_INT(0);
			objCared = DataPool : GetNPCIDByServerID(xx);
			if tonumber(objCared)==nil or  tonumber(objCared)== -1 then
				PushDebugMessage("server传过来的数据有问题。");
				return;
			end
			EquipStrengthen_Reset()
			this:Show();
			BeginCareObject_EquipStrengthen(objCared);
		end
	elseif  ( event == "PUT_STENGTHEN_ITEM" ) then
		if arg0~= nil then
			EquipStrengthen_Update(arg0);
		end
		local playerMoney = Player:GetData("MONEY");
		EquipStrengthen_SelfMoney:SetProperty("MoneyNumber", playerMoney);
		EquipStrengthen_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ")); --zchw
	elseif	( event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		EquipStrengthen_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		EquipStrengthen_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ")); --zchw
	elseif	( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if(tonumber(arg0) and PlayerPackage:GetItemTableIndex(tonumber(arg0)) == Enchange_Item2) then
				--EquipStrengthen_Clear();
				if(PlayerPackage:IsLock(tonumber(arg0)) == 1) then
					--push事件干掉msgbox
					LifeAbility:CloseStrengthMsgBox();
					return;
				end
		end
		if (Enchange_Item1 == tonumber(arg0)) then
			--if(PlayerPackage:IsLock(tonumber(Enchange_Item1)) == 1) then
				--EquipStrengthen_Clear();
				--Init_EquipStrengthen_Frame();
				--return
			--end
			EquipStrengthen_Update(arg0);
		end
	elseif (event == "TAKE_STENGTHEN_ITEM") then
		EquipStrengthen_Clear();
		Init_EquipStrengthen_Frame();

	elseif (event == "ADJEST_UI_POS" ) then
		EquipStrengthen_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipStrengthen_Frame_On_ResetPos()
	elseif	( event == "EQUIPSTRENGTH_QUICK_CONFIRM_RET" ) then
		-- 置灰等级框、确定按钮
		EquipStrengthen_Grade : Disable()
		EquipStrengthen_Grade : SetProperty("DefaultEditBox", "False")
		EquipStrengthen_OK:Disable()
		g_QuickUpState = 1
		EquipStrengthen_Quick_Up:SetText("#{ZDQH_161107_07}")
		local ret = EquipStrengthen_DoQuick_Up()
		if ret == 0 then
			EquipStrengthen_Quick_Up_Stop()
			return
		end
		SetTimer("EquipStrengthen","EquipStrengthen_Quick_Up_Timeproc()", 200)
	end
end

function Init_EquipStrengthen_Frame()
	local playerMoney = Player:GetData("MONEY");
	EquipStrengthen_SelfMoney:SetProperty("MoneyNumber", playerMoney);
	EquipStrengthen_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ")); --zchw

	if Player:GetData("Is2606S") == 1 then
		EquipStrengthen_Info4:SetText("#{QXF_260623_12}");
	else
		EquipStrengthen_Info4:SetText("#{ZBQH_130521_43}");
	end
	
	EquipStrengthen_Info5:SetText("");

	EquipStrengthen_Info7:SetText("");

	EquipStrengthen_Info11:SetText("");
	EquipStrengthen_Info11:Hide();
	EquipStrengthen_Info10:Hide();

	EquipStrengthen_Info16:SetText("");

	EquipStrengthen_Info17:SetText("");

	EquipStrengthen_Object2:SetProperty("Image","")

	--EquipStrengthen_Quick_Up:Disable();
	EquipStrengthen_Quick_Up:SetText("#{ZBQH_130521_62}")

	g_CheckQuickUp = 0;
end

function BeginCareObject_EquipStrengthen(objCared)
	g_Object = objCared;
	this:CareObject(tonumber(g_Object), 1, "EquipStrengthen");
end

--=========================================================
-- 重置数据
--=========================================================
function EquipStrengthen_Reset()
	-- 清空输入框并设置为默认输入框、可使用
	EquipStrengthen_Grade : SetText("")
	EquipStrengthen_Grade : SetProperty("DefaultEditBox", "True")
	EquipStrengthen_Grade : Enable()
	
	-- 置灰自动升级和特效
	EquipStrengthen_Quick_Up:Disable()
	EquipStrengthen_Quick_Up_Animate:Disable()
	EquipStrengthen_Quick_Up_Animate:Play(false)
end

function EquipStrengthen_Update(Item_index)
	local i_index = tonumber(Item_index)
	local theAction = EnumAction(i_index, "packageitem");
	local NeedMoney
	local Property

	if theAction:GetID() ~= 0 then
			local EquipPoint = LifeAbility : Get_Equip_Point(i_index)

			if EquipPoint == -1 or EquipPoint == 8 or EquipPoint == 9 or EquipPoint == 10
			or PlayerPackage:IsBagItemKFS(i_index) ==1 then --武魂的限制
				if EquipPoint ~= -1 then
					PushDebugMessage("不能放入这种装备。")
				end
				return
			end
			
			--宗门装备暂时关闭
			if EquipPoint == 23 then
				PushDebugMessage("#{XWXT_230825_18}")
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

			local StrongLevel = LifeAbility : Get_Equip_CurStrengthLevel(i_index)
			if StrongLevel == 99 then
				if Enchange_Item1 ~= i_index then
					PushDebugMessage("#{ZBQH_130521_32}")
				else
					NeedMoney,Property,arg1= LifeAbility : Get_Equip_StrengthLevel(i_index);
						EquipStrengthen_Info5:SetText("");
						EquipStrengthen_Info7:SetText("");
						EquipStrengthen_Info11:SetText("");
						EquipStrengthen_Info16:SetText(arg1);
						EquipStrengthen_Info17:SetText("");
						EquipStrengthen_Object2:SetProperty("Image","")
				end
				EquipStrengthen_Quick_Up_Stop()
				return
			end
			NeedMoney,Property,arg1,arg2,arg3 = LifeAbility : Get_Equip_StrengthLevel(i_index);

			--现在上限开放到99级
			if(NeedMoney<=0 ) then
				PushDebugMessage("此装备无法强化。")
				EquipStrengthen_Quick_Up_Stop()
				return
			end

			if Enchange_Item1 ~= -1 then
				LifeAbility : Lock_Packet_Item(Enchange_Item1,0);
			end

			if Enchange_Item1 == -1 or Enchange_Item1 ~= i_index then
				EquipStrengthen_Quick_Up_Stop()
			end
			--push事件干掉msgbox
			LifeAbility:CloseStrengthMsgBox();
			EquipStrengthen_Info5:SetText(Property);
			EquipStrengthen_Object1:SetActionItem(theAction:GetID());
			LifeAbility : Lock_Packet_Item(i_index,1);
			Enchange_Item1 = i_index
			EquipStrengthen_Money : SetProperty("MoneyNumber", tostring(NeedMoney));

      -- <Property Name="Image" Value="set:Button13 image:Btn_Right_Normal"/>
			local icon =  tostring(LifeAbility : Get_Item_Icon_Name(i_index))
			EquipStrengthen_Object2:SetProperty("Image",icon)--"set:Button13 image:Btn_Right_Normal")

			local Equip_Level = LifeAbility : Get_Equip_Level(i_index);

			--显示需要的物品
			if StrongLevel < 9 then
				if Equip_Level < 40 then
					Enchange_Item2 = 30900005;
					EquipStrengthen_Info7 : SetText("#G#{_ITEM30900005}")
				else
					Enchange_Item2 = TianGangCaiLiaoID;
					EquipStrengthen_Info7 : SetText("#G#{_ITEM30900006}#W或#G#{_ITEM30900045}")
				end
				EquipStrengthen_Info5 : SetToolTip( "" )
			else
				Enchange_Item2 = g_EnhanceQHJH1;
				EquipStrengthen_Info7 : SetText("#G#{_ITEM38000571}")
				EquipStrengthen_Info5 : SetToolTip( "#{ZBQH_130521_61}" )
			end

			local szmsg;
			--显示距离成功还需多少次
			if arg3 <= 0 then
				EquipStrengthen_Info11 : SetText("")
				EquipStrengthen_Info10:Hide()
				EquipStrengthen_Info11:Hide()
			else
				EquipStrengthen_Info10:Show()
				EquipStrengthen_Info11:Show()
				szmsg = tostring(arg3).."次"
				EquipStrengthen_Info11 : SetText(szmsg)
			end

			--显示这一等级的数值
			EquipStrengthen_Info16:SetText(arg1)
			--显示下一等级的数值
			EquipStrengthen_Info17:SetText(arg2)
			-- 点亮自动升级和特效
			EquipStrengthen_Quick_Up:Enable()
			EquipStrengthen_Quick_Up_Animate:Enable()
			EquipStrengthen_Quick_Up_Animate:Play(true)
	else
			-- 置灰自动升级和特效
			EquipStrengthen_Quick_Up:Disable()
			EquipStrengthen_Quick_Up_Animate:Disable()
			EquipStrengthen_Quick_Up_Animate:Play(false)
			return;
	end
end

function EquipStrengthen_Buttons_Clicked()

	if Enchange_Item1 == -1 then
		PushDebugMessage("#{ZBQH_130521_14}") --请放入一件装备
		return
	end
	--天罡材料
	local index,BindState = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(Enchange_Item2));
	
	--天罡物品
	if index == -1 and Enchange_Item2 == TianGangCaiLiaoID then
		--TT:216449 By YPL:start
		local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(38001553));
		index = index1;
		BindState =BindState1;
		Enchange_Item2 = 38001553;
		if index == -1 then
			local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber( TianGangWuPinID));
			index = index1;
			BindState =BindState1;
			Enchange_Item2 =  TianGangWuPinID;
		end
		--END
	end
	
	if index == -1 and Enchange_Item2 == TianGangWuPinID then
		--TT:216449 By YPL:start
		local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(38001553));
		index = index1;
		BindState =BindState1;
		Enchange_Item2 = 38001553;
		if index == -1 then
			local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber( TianGangWuPinID));
			index = index1;
			BindState =BindState1;
			Enchange_Item2 =  TianGangWuPinID;
		end
		--END
	end	
	
	--强化露
	--TT:216449 By YPL:start
	--if index == -1 and Enchange_Item2 == TianGangWuPinID then
	if index == -1 and (Enchange_Item2 == TianGangWuPinID or Enchange_Item2 == 38001553) then

		local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(38001554));
		if(index1 == -1)then
			index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(QianghualuId));
			if index1 == -1 then
				local str = "你没有#{_ITEM"..Enchange_Item2.."}或#{_ITEM"..QianghualuId.."},如果你的天罡强化精华或天罡强化露已加锁，请解锁后再来进行强化";
				PushDebugMessage(str);
				return
			else
				index = index1;
				BindState =BindState1;
				Enchange_Item2 = QianghualuId;			
			end
		else
			index = index1;
			BindState =BindState1;
			Enchange_Item2 = 38001554;
		end
	--END
	end

	--先找 38000571至尊强化精华（绑定）,如果没有,再找  38000572至尊强化精华（不绑定）
	if index == -1 and Enchange_Item2 == g_EnhanceQHJH1 then
		local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(g_EnhanceQHJH2));
		if(index1 >= 0)then
			index = index1;
			BindState =BindState1;
			Enchange_Item2 = g_EnhanceQHJH2;
		end
	end


	if(index == -1)then
		local str =  "缺少#{_ITEM"..Enchange_Item2.."}，或者#{_ITEM"..Enchange_Item2.."}已加锁。";
		PushDebugMessage(str);
		return
	end

	if(BindState == EB_BINDED)then
		--如果已绑定
		local tmp = PlayerPackage:GetItemBindStatusByIndex(Enchange_Item1);
		if(tmp == EB_BINDED)then
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("FinishEnhance");
				Set_XSCRIPT_ScriptID(809262);
				Set_XSCRIPT_Parameter(0,Enchange_Item1);
				Set_XSCRIPT_Parameter(1,index);
				Set_XSCRIPT_Parameter(2,-1);
				Set_XSCRIPT_ParamCount(3);
			Send_XSCRIPT();
		else
			local equip_index = PlayerPackage:GetItemTableIndex( Enchange_Item1 );
--~ 			--[屈彦2010.11.24 新增非绑定重楼系列物品]
--~ 			if IsUnbindChongLouEquip(equip_index) == 1 then
--~ 					ShowSystemInfo("CLBD_091211_6");
--~ 			  	return
--~ 			else
				PlayerPackage:OpenStengMsgBox(tonumber(Enchange_Item1),tonumber(index));
--~ 			end
		end
	else
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("FinishEnhance");
				Set_XSCRIPT_ScriptID(809262);
				Set_XSCRIPT_Parameter(0,Enchange_Item1);
				Set_XSCRIPT_Parameter(1,index);
				Set_XSCRIPT_Parameter(2,-1);
				Set_XSCRIPT_ParamCount(3);
			Send_XSCRIPT();
	end
end

function EquipStrengthen_Clear()
	if Enchange_Item1 ~= -1 then
		EquipStrengthen_Object1:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(Enchange_Item1,0);
		Enchange_Item1 = -1
		--push事件干掉msgbox
		LifeAbility:CloseStrengthMsgBox();
	end
	Enchange_Item2 = -1
	EquipStrengthen_Money : SetProperty("MoneyNumber", 0)
	EquipStrengthen_Quick_Up_Stop()
end

function EquipStrengthen_OnHiden()
	EquipStrengthen_Clear();
	g_CheckQuickUp = 0;
end

function EquipStrengthen_Frame_On_ResetPos()
  EquipStrengthen_Frame:SetProperty("UnifiedPosition", g_EquipStrengthen_Frame_UnifiedPosition);
end



function EquipStrengthen_Quick_Up_Click()
	if g_QuickUpState == 0 then
		--开始一键强化
		EquipStrengthen_Quick_Up_Start()
	elseif g_QuickUpState == 1 then
		--停止一键强化
		EquipStrengthen_Quick_Up_Stop()
	end
end

function EquipStrengthen_Quick_Up_Start()
	local curDay 	= tonumber(DataPool:GetServerDayTime());
	local opentime  = Lua_GetTeSeServerOpenTime(2)
	if opentime>=0 and opentime > curDay then
		PushDebugMessage(ScriptGlobal_Format("#{TSFCL_220210_01}", math.floor(math.mod(opentime,10000)/100), math.mod(opentime,100)))
		return
	end 

	if g_QuickUpState ~= 0 then
		return
	end

	if Enchange_Item1 == -1 then
		PushDebugMessage("#{ZBQH_130521_14}")
		return
	end
	
	-- 检测目标等级是否合法
	local StrongLevel = LifeAbility : Get_Equip_CurStrengthLevel(Enchange_Item1)
	
	local nDesLevel = tonumber(EquipStrengthen_Grade:GetText())
	if nil == StrongLevel then
		StrongLevel = 0
	end
	if nil == nDesLevel then
		PushDebugMessage("#{ZDQH_161123_08}")
		return
	end
	
	if StrongLevel >= 99 then
		PushDebugMessage("#{ZBQH_130521_42}")
		return
	end
	
	--检测钱和强化表
	local NeedMoney,Property,arg1,arg2,arg3 = LifeAbility : Get_Equip_StrengthLevel(Enchange_Item1);
	if NeedMoney < 0 then
		return
	end

	local nMoney = Player:GetData("MONEY");
	local nJiaozi = Player:GetData("MONEY_JZ");
	if nMoney + nJiaozi < NeedMoney then
		PushDebugMessage("#{ZBQH_130521_24}")
		return
	end
	
	if nDesLevel <= StrongLevel then
		PushDebugMessage("#{ZDQH_161107_03}")
		return
	end
	
	--天罡材料
	local index,BindState = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(Enchange_Item2));
	
	--天罡物品
	if index == -1 and Enchange_Item2 == TianGangCaiLiaoID then
		--TT:216449 By YPL:start
		local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(38001553));
		index = index1;
		BindState =BindState1;
		Enchange_Item2 = 38001553;
		if index == -1 then
			local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(TianGangWuPinID));
			index = index1;
			BindState =BindState1;
			Enchange_Item2 = TianGangWuPinID;		
		end
		--END
	end
	
	if index == -1 and Enchange_Item2 == TianGangWuPinID then
		--TT:216449 By YPL:start
		local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(38001553));
		index = index1;
		BindState =BindState1;
		Enchange_Item2 = 38001553;
		if index == -1 then
			local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(TianGangWuPinID));
			index = index1;
			BindState =BindState1;
			Enchange_Item2 = TianGangWuPinID;		
		end
		--END
	end	
	
	--强化露
	--TT:216449 By YPL:start
	--if index == -1 and Enchange_Item2 == TianGangWuPinID then
	if index == -1 and (Enchange_Item2 == TianGangWuPinID or Enchange_Item2 == 38001553) then

		local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(38001554));
		if(index1 == -1)then
			index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(QianghualuId));
			if index1 == -1 then
				local str = "你没有#{_ITEM"..Enchange_Item2.."}或#{_ITEM"..QianghualuId.."},如果你的天罡强化精华或天罡强化露已加锁，请解锁后再来进行强化";
				PushDebugMessage(str);
				return
			else
				index = index1;
				BindState =BindState1;
				Enchange_Item2 = QianghualuId;			
			end
		else
			index = index1;
			BindState =BindState1;
			Enchange_Item2 = 38001554;
		end
	--END
	end

	--先找 38000571至尊强化精华（绑定）,如果没有,再找  38000572至尊强化精华（不绑定）
	if index == -1 and Enchange_Item2 == g_EnhanceQHJH1 then
		local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(g_EnhanceQHJH2));
		if(index1 >= 0)then
			index = index1;
			BindState =BindState1;
			Enchange_Item2 = g_EnhanceQHJH2;
		end
	end
	--如果已绑定
	if(BindState == EB_BINDED)then
		local tmp = PlayerPackage:GetItemBindStatusByIndex(Enchange_Item1);
		if(tmp ~= EB_BINDED)then
			local equip_index = PlayerPackage:GetItemTableIndex( Enchange_Item1 );
--~ 			--[屈彦2010.11.24 新增非绑定重楼系列物品]
--~ 			if IsUnbindChongLouEquip(equip_index) == 1 then
--~ 				PushDebugMessage("#{CLBD_091211_6}");
--~ 				return
--~ 			end
		end
	end
	PushEvent( "EQUIPSTRENGTH_QUICK_CONFIRM" )
end

function EquipStrengthen_Quick_Up_Timeproc()

	local ret = EquipStrengthen_DoQuick_Up()
	if ret == 0 then
		EquipStrengthen_Quick_Up_Stop()
	end

end

function EquipStrengthen_Quick_Up_Stop()
	-- 点亮等级框、确定按钮
	EquipStrengthen_Grade : Enable()
	EquipStrengthen_Grade : SetProperty("DefaultEditBox", "True")	
	EquipStrengthen_OK:Enable()
	KillTimer("EquipStrengthen_Quick_Up_Timeproc()")
	g_QuickUpState = 0;
	EquipStrengthen_Quick_Up:SetText("#{ZBQH_130521_62}")

end

function EquipStrengthen_DoQuick_Up()
	--自动强化每次检测内容
	if g_QuickUpState ~= 1 then
		return 0
	end

	local curDay 	= tonumber(DataPool:GetServerDayTime());
	local opentime  = Lua_GetTeSeServerOpenTime(2)
	if opentime>=0 and opentime > curDay then
		PushDebugMessage(ScriptGlobal_Format("#{TSFCL_220210_01}", math.floor(math.mod(opentime,10000)/100), math.mod(opentime,100)))
		return
	end 
	
	if Enchange_Item1 == -1 then
		PushDebugMessage("#{ZBQH_130521_14}")
		return 0
	end

	--检测等级
	local StrongLevel = LifeAbility : Get_Equip_CurStrengthLevel(Enchange_Item1)
	if StrongLevel >= 99 then
		PushDebugMessage("#{ZBQH_130521_42}")
		return 0
	end
	
	-- 检测停止
	local nDesLevel = tonumber(EquipStrengthen_Grade:GetText())
	if nil == nDesLevel then
		nDesLevel = 0
	end
	if nDesLevel <= StrongLevel then
		return 0
	end
	
	--检测钱和强化表
	NeedMoney,Property,arg1,arg2,arg3 = LifeAbility : Get_Equip_StrengthLevel(Enchange_Item1);
	if NeedMoney < 0 then
		return 0
	end

	local nMoney = Player:GetData("MONEY");
	local nJiaozi = Player:GetData("MONEY_JZ");
	if nMoney + nJiaozi < NeedMoney then
		PushDebugMessage("#{ZBQH_130521_24}")
		return 0
	end

	--天罡材料
	local index,BindState = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(Enchange_Item2));
	
	--天罡物品
	if index == -1 and Enchange_Item2 == TianGangCaiLiaoID then
		--TT:216449 By YPL:start
		local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(38001553));
		index = index1;
		BindState =BindState1;
		Enchange_Item2 = 38001553;
		if index == -1 then
			local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(TianGangWuPinID));
			index = index1;
			BindState =BindState1;
			Enchange_Item2 = TianGangWuPinID;		
		end
		--END
	end
	
	if index == -1 and Enchange_Item2 == TianGangWuPinID then
		--TT:216449 By YPL:start
		local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(38001553));
		index = index1;
		BindState =BindState1;
		Enchange_Item2 = 38001553;
		if index == -1 then
			local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(TianGangWuPinID));
			index = index1;
			BindState =BindState1;
			Enchange_Item2 = TianGangWuPinID;		
		end
		--END
	end	

 --先找强化精华(没有强化精华,则找强化露)
	--TT:216449 By YPL:start
	--if index == -1 and Enchange_Item2 == TianGangWuPinID then
	if index == -1 and (Enchange_Item2 == TianGangWuPinID or Enchange_Item2 == 38001553) then
		local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(38001554));
		if(index1 == -1)then
			index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(QianghualuId));
			if index1 == -1 then
				local str = "你没有#{_ITEM"..Enchange_Item2.."}或#{_ITEM"..QianghualuId.."},如果你的天罡强化精华或天罡强化露已加锁，请解锁后再来进行强化";
				PushDebugMessage(str);
				return 0
			else
				index = index1;
				BindState =BindState1;
				Enchange_Item2 = QianghualuId;	
			end
		else
			index = index1;
			BindState =BindState1;
			Enchange_Item2 = 38001554;
		end
	--END
	end

	--先找 38000571至尊强化精华（绑定）,如果没有,再找  38000572至尊强化精华（不绑定）
	if index == -1 and Enchange_Item2 == g_EnhanceQHJH1 then
		local index1,BindState1 = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(g_EnhanceQHJH2));
		if(index1 >= 0)then
			index = index1;
			BindState =BindState1;
			Enchange_Item2 = g_EnhanceQHJH2;
		end
	end

	if(index == -1)then
		local str =  "缺少#{_ITEM"..Enchange_Item2.."}，或者#{_ITEM"..Enchange_Item2.."}已加锁。";
		PushDebugMessage(str);
		return 0
	end

	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("FinishEnhance");
		Set_XSCRIPT_ScriptID(809262);
		Set_XSCRIPT_Parameter(0,Enchange_Item1);
		Set_XSCRIPT_Parameter(1,index);
		Set_XSCRIPT_Parameter(2,nDesLevel);
		Set_XSCRIPT_ParamCount(3);
	Send_XSCRIPT();
end
