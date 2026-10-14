--装备可修理次数+1

local Current = 0;
local MAX_OBJ_DISTANCE = 3.0;

local g_Enchange_Item1 = -1
local g_Enchange_Item2 = -1
local g_Object = -1;

local Enchange_Cost = {}
local g_EquipEnchange_Frame_UnifiedPosition;

local g_NPC_ID = -1

--local g_CurEquipPos = -1
local g_RunWuLuID=30900007

local EQUIP_ACTIONBUTTON ={}
local EQUIP_MASKBUTTON={}
local EQUIP_ANIMATEBTN={}
local g_ValidEquipPos={
1,15,14,3,5,4,6,11,12,13,
0,2,7,21,19,20
}
local g_SaveEquip=-1
local g_SaveItem=-1

local g_EquipEnchange_14_pos 
local g_EquipEnchange_15_pos 
local g_EquipEnchange_16_pos 

function EquipEnchange_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("UPDATE_ENHANCE",false)
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("BUY_ITEM",false)				--add:lby注册购买商品消息，更新修改次数界面
	this:RegisterEvent("REFRESH_EQUIP",false)
end

function EquipEnchange_OnLoad()
	Enchange_Cost[1] = 20000
	Enchange_Cost[2] = 30000
	Enchange_Cost[3] = 40000
	Enchange_Cost[4] = 50000
	Enchange_Cost[5] = 60000
	Enchange_Cost[6] = 70000
	Enchange_Cost[7] = 80000
	Enchange_Cost[8] = 90000
	Enchange_Cost[9] = 100000
	Enchange_Cost[10] = 0

	g_EquipEnchange_Frame_UnifiedPosition=EquipEnchange_Frame:GetProperty("UnifiedPosition");
	EQUIP_ACTIONBUTTON={
	EquipEnchange_1,EquipEnchange_2,EquipEnchange_3,EquipEnchange_4,EquipEnchange_5,
	EquipEnchange_6,EquipEnchange_7,EquipEnchange_8,EquipEnchange_9,EquipEnchange_10,
	EquipEnchange_11,EquipEnchange_12,EquipEnchange_13,EquipEnchange_14,EquipEnchange_15,
	EquipEnchange_16
	}
	EQUIP_MASKBUTTON={
	EquipEnchange_1_Mask,EquipEnchange_2_Mask,EquipEnchange_3_Mask,EquipEnchange_4_Mask,
	EquipEnchange_5_Mask,EquipEnchange_6_Mask,EquipEnchange_7_Mask,EquipEnchange_8_Mask,
	EquipEnchange_9_Mask,EquipEnchange_10_Mask,EquipEnchange_11_Mask,EquipEnchange_12_Mask,
	EquipEnchange_13_Mask,EquipEnchange_14_Mask,EquipEnchange_15_Mask,EquipEnchange_16_Mask
	}
	EQUIP_ANIMATEBTN={
	EquipEnchange_1_Animate,EquipEnchange_2_Animate,EquipEnchange_3_Animate,EquipEnchange_4_Animate,
	EquipEnchange_5_Animate,EquipEnchange_6_Animate,EquipEnchange_7_Animate,EquipEnchange_8_Animate,
	EquipEnchange_9_Animate,EquipEnchange_10_Animate,EquipEnchange_11_Animate,EquipEnchange_12_Animate,
	EquipEnchange_13_Animate,EquipEnchange_14_Animate,EquipEnchange_15_Animate,EquipEnchange_16_Animate,
	}
	
	g_EquipEnchange_14_pos = EquipEnchange_14:GetProperty("UnifiedPosition");
	g_EquipEnchange_15_pos = EquipEnchange_15:GetProperty("UnifiedPosition");
	g_EquipEnchange_16_pos = EquipEnchange_16:GetProperty("UnifiedPosition");
end

function EquipEnchange_OnEvent(event)

--	PushDebugMessage(event);
	if ( event == "UI_COMMAND" ) then
			local playerMoney = Player:GetData("MONEY");
			EquipEnchange_SelfMoney:SetProperty("MoneyNumber", playerMoney);
			EquipEnchange_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ")); --zchw
			if tonumber(arg0) == 1003 then
				--其他界面隐藏其按钮
				EquipEnchange_Queren : Hide()
				EquipEnchange_Queren_Text : Hide()

				EquipEnchange_Info4  : SetText("提升装备等级之后可以提升基础属性")
				EquipEnchange_Info : SetText("请将装备拖入此框")
				EquipEnchange_Info2 : SetText("提升等级需要")
				EquipEnchange_Title : SetText("#gFF0FA0提升装备等级")
				EquipEnchange_Object2 : SetToolTip("需要#{_ITEM30900008}")
				Current = 3
				if this:IsVisible() then
					EquipEnchange_Close();
				end

				this:Show();
				g_Object = -1
				g_NPC_ID = Get_XParam_INT(0);
				g_Object = DataPool : GetNPCIDByServerID(g_NPC_ID);
				if g_Object == -1 then
						PushDebugMessage("server传过来的数据有问题。");
						return;
				end
				BeginCareObject_EquipEnchange()
			elseif tonumber(arg0) == 1004 then
				EquipEnchange_Queren : Show()
				EquipEnchange_Queren_Text : Show()
				EquipEnchange_Title : SetText("#{XHRYH_170608_33}")
				local bState = tonumber(LifeAbility : GetYuanbaoRepairTimes())
				if bState == 0 then
					EquipEnchange_Queren : SetCheck(1)
				else
					EquipEnchange_Queren : SetCheck(0)
				end
				--增加可修理次数功能
				--其他界面隐藏其按钮
				Current = 4
				g_SaveEquip=-1
				g_SaveItem=-1
				g_NPC_ID = Get_XParam_INT(0);
				if g_NPC_ID == -1 then
					--随身
				else
					g_Object = DataPool : GetNPCIDByServerID(g_NPC_ID);
					if g_Object == -1 then
							PushDebugMessage("server传过来的数据有问题。");
							return;
					end
					BeginCareObject_EquipEnchange()
				end
				EquipEnchange_InitShow()
				this:Show();
			end
	elseif (event=="REFRESH_EQUIP" and this:IsVisible()) then
		if Current == 4 then
			if g_Enchange_Item1>100 then
				EquipEnchange_Clear(1)
			end

			EquipEnchange_InitShow()
--			if g_SaveEquip ~= -1 then
--				local retSel=EquipEnchange_UpdateFail()
--				g_SaveEquip=-1
--				if retSel>100 then
--					EquipEnchange_ActionButton_Clk(math.mod(retSel,100))
--					--润物露
--					EquipEnchange_ReUpdateItem()
--				end
--			end
		end
	elseif  ( event == "UPDATE_ENHANCE" ) then
		if Current ~= 4 then
			return
		end
		if arg0~= nil and arg1 ~= nil then
			EquipEnchange_Update(arg0,arg1)
		end
	elseif ( event == "RESUME_ENCHASE_GEM_EX" ) then
		if arg0 ~= nil then
			EquipEnchange_Resume_Gem(tonumber(arg0));
		end
		local playerMoney = Player:GetData("MONEY");
		EquipEnchange_SelfMoney:SetProperty("MoneyNumber", playerMoney);
		EquipEnchange_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ")); --zchw
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= g_Object) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then

			--取消关心
			EquipEnchange_Close()
		end
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
		if arg0==nil or Current~=4 then
			return
		end
--		PushDebugMessage(event.." arg0="..arg0)
		if tonumber(arg0)~=-1 then
			if (g_Enchange_Item1 == tonumber(arg0) ) then
				local bIsClear = 1
				local theAction = EnumAction(g_Enchange_Item1, "packageitem");
				if theAction:GetID() ~= 0 then
					local nTimes = theAction : GetRemainRepairCount()

					if nTimes < 3 then
							bIsClear = 0
					end
				end

				if bIsClear == 1 then
						EquipEnchange_Resume_Gem(21)
				end
			end
			if (g_Enchange_Item2 == tonumber(arg0) ) then
				EquipEnchange_Resume_Gem(22)
			end
		else
			--回包也许
			if g_SaveEquip ~= -1 then
				EquipEnchange_Clear()
				local retSel=EquipEnchange_UpdateFail()
				g_SaveEquip=-1
--				PushDebugMessage("retSel="..retSel)
				if retSel>100 then
					EquipEnchange_ActionButton_Clk(math.mod(retSel,100))
					--润物露
					EquipEnchange_ReUpdateItem()
				elseif retSel>=0 then
					EquipEnchange_Update(1,retSel)
					--润物露
					EquipEnchange_ReUpdateItem()
				end
			end
		end

	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		EquipEnchange_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then --zchw
		EquipEnchange_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))

	elseif (event == "ADJEST_UI_POS" ) then
		EquipEnchange_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipEnchange_Frame_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif event == "BUY_ITEM" and this:IsVisible() then	--add:lby2016
		local item = tonumber(arg1)
		if 30900007 ~= item then
			return
		end
		if Current == 4 then
			EquipEnchange_Update(2,PlayerPackage:GetBagPosByItemIndex(item))
		end
	end


end

function EquipEnchange_UpdateFail()
	if g_SaveEquip==-1 then
		return -1
	end
	local ActionEquip=nil
	if g_SaveEquip>100 then
		--装备位
		if g_ValidEquipPos[g_SaveEquip-100]==nil then
			return -1
		end
		ActionEquip=EnumAction(g_ValidEquipPos[g_SaveEquip-100], "equip")
	else
		--背包位
		ActionEquip = EnumAction(g_SaveEquip, "packageitem")
	end
	if ActionEquip==nil then
		return -1
	end
	local nTimes = ActionEquip : GetRemainRepairCount()
	if nTimes>=3 then
		return -1
	end
	return g_SaveEquip
end

function EquipEnchange_ReUpdateItem()
--	PushDebugMessage("ReUpdateItem g_SaveItem="..g_SaveItem)
	if g_SaveItem==-1 then
		return -1
	end

	local theAction = EnumAction(g_SaveItem, "packageitem")
	if theAction:GetID() == 0 then
		return -1
	end
	if PlayerPackage : GetItemTableIndex( g_SaveItem ) ~= 30900007 and
		 PlayerPackage : GetItemTableIndex( g_SaveItem ) ~= 30900000	 then
		return -1
	end
	EquipEnchange_Object2:SetActionItem(theAction:GetID());
	LifeAbility : Lock_Packet_Item(g_SaveItem,1);
	g_Enchange_Item2 = g_SaveItem
	g_SaveEquip=-1
	g_SaveItem=-1
end

function EquipEnchange_YBPay_Clicked() --add:lby2016增加元宝确认购买
	local check  = tonumber(LifeAbility : GetYuanbaoRepairTimes());

		if(check>=1)then
			EquipEnchange_Queren : SetCheck(1);
			LifeAbility:SetYuanbaoRepairTimes(0);
		else
			EquipEnchange_Queren : SetCheck(0);
			LifeAbility:SetYuanbaoRepairTimes(1);
		end

end

function EquipEnchange_OnShown()
	EquipEnchange_Clear();
end

function EquipEnchange_Clear(part)
	if part==nil or part==1 then
		if g_Enchange_Item1 ~= -1 then
			EquipEnchange_Object1:SetActionItem(-1);
			if g_Enchange_Item1>100 then
				EQUIP_ANIMATEBTN[g_Enchange_Item1-100]:Hide()
			else
				LifeAbility : Lock_Packet_Item(g_Enchange_Item1,0);
			end
		end
		g_Enchange_Item1 = -1
		EquipEnchange_Endurance_Num:SetText("")
		EquipEnchange_Money : SetProperty("MoneyNumber", 0)
	end
	if part==nil or part==2 then
		if g_Enchange_Item2 ~= -1 then
			EquipEnchange_Object2:SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(g_Enchange_Item2,0);
			g_Enchange_Item2 = -1
		end
	end

end

function EquipEnchange_Update(UI_index,Item_index)
	local i_index = tonumber(Item_index)
	local u_index = tonumber(UI_index)
	local theAction = EnumAction(i_index, "packageitem");
	local NeedMoney
--PushDebugMessage("i_index="..i_index.." u_index="..u_index)
	if u_index == 1 then
		if theAction:GetID() ~= 0 then
				local EquipPoint = LifeAbility : Get_Equip_Point(i_index)
				if EquipPoint == -1 or EquipPoint == 8 or EquipPoint == 9 or EquipPoint == 10 or EquipPoint == 18 then
					if EquipPoint ~= -1 then
						PushDebugMessage("不能放入这种装备。")
					end
					return
				end
				if EquipPoint==16 then
					PushDebugMessage("#{XHRYH_170614_51}")
					return
				end
				
				if EquipPoint == 23 then
					PushDebugMessage("#{XWXT_230825_15}")
					return
				end
				
				--可修理次数是否满着
				local nTimes = theAction : GetRemainRepairCount()
				if nTimes>=3 then
					PushDebugMessage("#{XHRYH_170614_57}")
					return
				end

				EquipEnchange_Clear(1)
				local Equip_Level = LifeAbility : Get_Equip_Level(i_index);
				EquipEnchange_Object1:SetActionItem(theAction:GetID());
				LifeAbility : Lock_Packet_Item(i_index,1);
				g_Enchange_Item1 = i_index
				if Current == 4 then
					NeedMoney = Equip_Level * 200
				elseif Current == 3 then
					NeedMoney = Equip_Level * 20000
				elseif Current == 2 then
					NeedMoney = LifeAbility : Get_Equip_StrengthLevel(i_index);
					if(NeedMoney<=0) then
						return;
					end
				end
				if IsTBFinalServer() >= 1 then
					--雄霸天下总决赛服务器不计消耗
					NeedMoney = 0
				end
				EquipEnchange_Money : SetProperty("MoneyNumber", tostring(NeedMoney));
				--次数
				local RemainCnt = theAction:GetRemainRepairCount()
				if RemainCnt<=1 then
					RemainCnt="#cff0000"..RemainCnt
				end
				local nValueText = ScriptGlobal_Format( "#{XHRYH_170608_35}", RemainCnt )
				EquipEnchange_Endurance_Num:SetText(nValueText)
				if Current == 2 then
					local Equip_Level = LifeAbility : Get_Equip_Level(i_index);
						if Equip_Level < 40 then
							EquipEnchange_Object2 : SetToolTip("需要#{_ITEM30900005}。")
						else
							EquipEnchange_Object2 : SetToolTip("需要#{_ITEM30900006}。")
						end
				end
		else
				EquipEnchange_Object1:SetActionItem(-1);
				LifeAbility : Lock_Packet_Item(g_Enchange_Item1,0);
				g_Enchange_Item1 = -1;
				EquipEnchange_Money : SetProperty("MoneyNumber", 0)
		end
	elseif u_index == 2 then
		if theAction:GetID() ~= 0 then
				if Current == 2 then--装备强化
					if PlayerPackage : GetItemTableIndex( i_index ) ~= 30900005 and
						 PlayerPackage : GetItemTableIndex( i_index ) ~= 30900006 then
						PushDebugMessage("这里必须放入#{_ITEM30900005}或者#{_ITEM30900006}。")
						return
					end
				end
				if Current == 3 then--装备升级
					if PlayerPackage : GetItemTableIndex( i_index ) ~= 30900008 then
						PushDebugMessage("这里必须放入#{_ITEM30900008}。")
						return
					end
				end
				if Current == 4 then--装备耐久
					if PlayerPackage : GetItemTableIndex( i_index ) ~= 30900007 and
						 PlayerPackage : GetItemTableIndex( i_index ) ~= 30900000	 then
						PushDebugMessage("这里必须放入#{_ITEM30900007}或者#{_ITEM30900000}。")
						return
					end
				end
				if g_Enchange_Item2 ~= -1 then
					LifeAbility : Lock_Packet_Item(g_Enchange_Item2,0);
				end
				EquipEnchange_Object2:SetActionItem(theAction:GetID());
				LifeAbility : Lock_Packet_Item(i_index,1);
				g_Enchange_Item2 = i_index
				g_SaveEquip=-1
				g_SaveItem=-1
		else
				EquipEnchange_Object2:SetActionItem(-1);
				LifeAbility : Lock_Packet_Item(g_Enchange_Item2,0);
				g_Enchange_Item2 = -1;
		end
	end

end

--add:lby2016
function EquipYuanbaoBuyTSAsk(Item1, bInEquip)

	local _material = 30900007

	--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return 0
	end

	-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{XCZB_160105_36}")
		return 0
	end

	local bIsNotice = 1
	local check  = tonumber(LifeAbility : GetYuanbaoRepairTimes());
	if check == 1 then
	--不提示 自动购买
		bIsNotice = 0
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("EquipRepair_Yuanbao_Pay")
		Set_XSCRIPT_ScriptID(809265)
		Set_XSCRIPT_Parameter(0,_material)
		Set_XSCRIPT_Parameter(1,bIsNotice)
		Set_XSCRIPT_Parameter(2,Item1)
		Set_XSCRIPT_Parameter(3,bInEquip)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
end
function EquipEnchange_Buttons_OKClicked()
	if g_Enchange_Item1 == -1 then
		PushDebugMessage("#{XHRYH_170608_39}")
		return
	end

	--可修理次数
	local theAction = nil
	if g_Enchange_Item1>100 then
		theAction = EnumAction(g_ValidEquipPos[g_Enchange_Item1-100], "equip");
	else
		theAction = EnumAction(g_Enchange_Item1, "packageitem");
	end
	if theAction==nil then
		PushDebugMessage("#{XHRYH_170608_39}")
		return
	end
	if theAction:GetID() == 0 then
		PushDebugMessage("#{XHRYH_170608_39}")
		return
	end
	--次数是否==3
	local nTimes = theAction : GetRemainRepairCount()
	if nTimes >= 3 then
		PushDebugMessage("#{XHRYH_170608_41}")
		return
	end
	--	检测物品等级
	local EquipLevel = 0
	if g_Enchange_Item1>100 then
		Equip_Level = theAction:GetEquipLevel()--物品的获取不到，哈
	else
		Equip_Level = LifeAbility : Get_Equip_Level(g_Enchange_Item1);
	end
	local need_money = EquipLevel * 200
	local playerMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	if playerMoney<need_money then
		PushDebugMessage("#{XHRYH_170608_30}")
		return
	end
	if g_Enchange_Item2 == -1 then
		EquipYuanbaoBuyTSAsk(math.mod(g_Enchange_Item1,100),math.floor(g_Enchange_Item1/100))--0背包位，1装备位
		return
	end
	if g_Enchange_Item1>100 then
		local actionidx=math.mod(g_Enchange_Item1,100)
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("EquipFaileTimesOnEquip");
			Set_XSCRIPT_ScriptID(809265);
			Set_XSCRIPT_Parameter(0,g_NPC_ID);
			Set_XSCRIPT_Parameter(1,g_ValidEquipPos[actionidx]);
			Set_XSCRIPT_Parameter(2,g_Enchange_Item2);
			Set_XSCRIPT_ParamCount(3);
		Send_XSCRIPT();
	else
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("EquipFaileTimes");
			Set_XSCRIPT_ScriptID(809265);
			Set_XSCRIPT_Parameter(0,g_NPC_ID);
			Set_XSCRIPT_Parameter(1,g_Enchange_Item1);
			Set_XSCRIPT_Parameter(2,g_Enchange_Item2);
			Set_XSCRIPT_ParamCount(3);
		Send_XSCRIPT();
	end
	g_SaveEquip=g_Enchange_Item1
	g_SaveItem=g_Enchange_Item2
end

function EquipEnchange_Buttons_Clicked()
	if Current == 2 then--装备强化
		if g_Enchange_Item1 == -1 then
			PushDebugMessage("请放入一个装备。")
			return
		end
		if g_Enchange_Item2 == -1 then
			PushDebugMessage("请放入#{_ITEM30900005}或者#{_ITEM30900006}。")
			return
		end
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("FinishEnhance");
				Set_XSCRIPT_ScriptID(809262);
				Set_XSCRIPT_Parameter(0,g_Enchange_Item1);
				Set_XSCRIPT_Parameter(1,g_Enchange_Item2);
				Set_XSCRIPT_Parameter(2,-1);
				Set_XSCRIPT_ParamCount(3);
			Send_XSCRIPT();
	elseif Current == 3 then--装备升级
		if g_Enchange_Item1 == -1 then
			PushDebugMessage("请放入一个装备。")
			return
		end
		if g_Enchange_Item2 == -1 then
			PushDebugMessage("请放入#{_ITEM30900008}。")
			return
		end
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("EquipLevelUp");
				Set_XSCRIPT_ScriptID(809263);
				Set_XSCRIPT_Parameter(0,g_Enchange_Item1);
				Set_XSCRIPT_Parameter(1,g_Enchange_Item2);
				Set_XSCRIPT_ParamCount(2);
			Send_XSCRIPT();
	elseif Current == 4 then--装备耐久
		EquipEnchange_Buttons_OKClicked()
	end
end

function EquipEnchange_Close()
	this:Hide()
end

function EquipEnchange_Cancel_Clicked()
	EquipEnchange_Close();
	return;
end

function EquipEnchange_OnHiden()
--PushDebugMessage("EquipEnchange_OnHiden")
	StopCareObject_EquipEnchange()
	EquipEnchange_Clear()
end
--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_EquipEnchange()
	this:CareObject(g_Object, 1, "EquipEnchange");
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_EquipEnchange()
	this:CareObject(g_Object, 0, "EquipEnchange");
	g_Object = -1;
end

function EquipEnchange_Resume_Gem(nIndex)--21取消装备选择；22取消润物露选择
	if nIndex < 21 or nIndex > 22 then
		return
	end

	nIndex = nIndex - 20
	if( this:IsVisible() ) then
		if nIndex == 1 then
			if g_Enchange_Item1 ~= -1 then
				EquipEnchange_Object1:SetActionItem(-1)
				if g_Enchange_Item1>100 then
					EQUIP_ANIMATEBTN[g_Enchange_Item1-100]:Hide()
				else
					LifeAbility : Lock_Packet_Item(g_Enchange_Item1,0);
				end
				g_Enchange_Item1 = -1
				EquipEnchange_Money : SetProperty("MoneyNumber", 0)
				EquipEnchange_Endurance_Num:SetText("")
			end
		else
			if g_Enchange_Item2 ~= -1 then
				EquipEnchange_Object2:SetActionItem(-1)
				LifeAbility : Lock_Packet_Item(g_Enchange_Item2,0);
				g_Enchange_Item2 = -1
			end
		end
	end

end

function EquipEnchange_Frame_On_ResetPos()
  EquipEnchange_Frame:SetProperty("UnifiedPosition", g_EquipEnchange_Frame_UnifiedPosition);
end

function EquipEnchange_InitShow()
	--穿戴装备增加
	EquipEnchange_InitShowInEquip()
	EquipEnchange_Clear()

	EquipEnchange_Money:SetProperty("MoneyNumber", 0)
	EquipEnchange_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	EquipEnchange_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
end

function EquipEnchange_InitShowInEquip()
	local nShowButton = 1
	if Player:GetData("Is2606S") == 1 and (i == 14 or i == 15) then
		nShowButton = 0
	end
	for i=1,16 do
		local ActionEquip=EnumAction(g_ValidEquipPos[i], "equip")
		if ActionEquip:GetID()~=0 and nShowButton == 1 then
			EQUIP_ACTIONBUTTON[i]:SetActionItem(ActionEquip:GetID())
			if ActionEquip:GetEquipDur()<0.1 then
				EQUIP_MASKBUTTON[i]:Show()
			else
				EQUIP_MASKBUTTON[i]:Hide()
			end
		else
			EQUIP_MASKBUTTON[i]:Hide()
		end
		EQUIP_ANIMATEBTN[i]:Hide()
	end
		
	if Player:GetData("Is2606S") == 1 then
		EquipEnchange_14:Hide()
		EquipEnchange_15:Hide()
		EquipEnchange_16:SetProperty("UnifiedPosition", g_EquipEnchange_14_pos);
		EquipEnchange_16_Animate:SetProperty("UnifiedPosition", g_EquipEnchange_14_pos);
	else
		EquipEnchange_14:Show()
		EquipEnchange_15:Show()
		EquipEnchange_16:SetProperty("UnifiedPosition", g_EquipEnchange_16_pos);
		EquipEnchange_16_Animate:SetProperty("UnifiedPosition", g_EquipEnchange_16_pos);
	end
end

function EquipEnchange_ActionButton_Clk(index)
	if g_ValidEquipPos[index]==nil then
		return
	end
	if g_Enchange_Item1==100+index then
		return
	end
	local ActionEquip=EnumAction(g_ValidEquipPos[index], "equip")
	if ActionEquip:GetID()==0 then
		PushDebugMessage("#{XHRYH_170608_25}")
		return
	end
	local RemainCnt = ActionEquip:GetRemainRepairCount()
	if RemainCnt>=3 then
		PushDebugMessage("#{XHRYH_170608_41}")
		return
	end
	EquipEnchange_Clear(1)
	local EquipLevel = ActionEquip:GetEquipLevel()
	local need_money = EquipLevel * 200
	EquipEnchange_Money : SetProperty("MoneyNumber", need_money)
	if RemainCnt<=1 then
		RemainCnt="#cff0000"..RemainCnt
	end
	local nValueText = ScriptGlobal_Format( "#{XHRYH_170608_35}", RemainCnt )
	EquipEnchange_Endurance_Num:SetText(nValueText)
	EquipEnchange_Object1:SetActionItem(ActionEquip:GetID());
	--放入逻辑
	g_Enchange_Item1 = index+100;
	g_SaveEquip=-1
end

