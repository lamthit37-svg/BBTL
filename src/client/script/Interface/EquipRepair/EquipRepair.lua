
-- [ QUFEI 2007-10-15 15:31 UPDATE BugID 26358 ]

local EQUIP_BUTTONS;
local EQUIP_QUALITY = -1;
local Need_Item = 0
local Need_Money =0
local Need_Item_Count = 0
local Bore_Count=0
local g_objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;
local g_targetId = -1
local g_sel_price = -1
local EQUIP_SHENQI_BEGIN = 10300000
local EQUIP_SHENQI_END = 10399999
local g_SaveEquip = -1

local g_nTotalPrice = 0
local g_nRepairLine = 0

local g_EquipRepair_SuperWeaponStartUpCommandList = 
{
	201208094, 201208093, 201208092, 201208091, 201208098
}

local g_EquipRepair_Frame_UnifiedPosition;
local EQUIP_ACTIONBUTTON ={}
local EQUIP_MASKBUTTON={}
local EQUIP_ANIMATEBTN={}
local g_ValidEquipPos={
1,15,14,3,5,4,6,11,12,13,
0,2,7,21,19,20
}
local g_CurSelect=-1
--	HEQUIP_WEAPON		=0,		//武器	WEAPON                    帽子  武器  衣服  项链  骑乘  时装
--	HEQUIP_CAP			=1,		//帽子	DEFENCE                   护肩
--	HEQUIP_ARMOR		=2,		//衣服	DEFENCE                   护腕
--	HEQUIP_CUFF			=3,		//手套	DEFENCE                   手套
--	HEQUIP_BOOT			=4,		//鞋	DEFENCE                   腰带
--	HEQUIP_SASH			=5,		//腰带	DEFENCE                   鞋
--	HEQUIP_RING			=6,		//戒指	ADORN                     戒指
--	HEQUIP_NECKLACE		=7,		//项链	ADORN                     戒指
--	HEQUIP_RIDER		=8,		//骑乘	                          护符
--	HEQUIP_BAG			=9,		//行囊                            护符
--	HEQUIP_BOX			=10,	//箱格                   
--	HEQUIP_RING_2		=11,	//第二个戒指	ADORN                   
--	HEQUIP_CHARM		=12,	//护符	            ADORN               
--	HEQUIP_CHARM_2		=13,	//第二个护符	    ADORN               
--	HEQUIP_WRIST		=14,	//护腕	DEFENCE                   
--	HEQUIP_SHOULDER		=15,	//护肩	DEFENCE     
--	HEQUIP_DRESS		=16,	//时装                   
--	HEQUIP_RESERVE		=17,	//暗器
--	HEQUIP_RESERVE_2	=18,	//武魂 20090702 Vega
--	HEQUIP_NUMBER,				//主角装备点总数
--	//扩展的64个装备点
--	//0 - 9
--	HEQUIPEX_LONGWEN		=	19,	//披风-龙纹 【注意】在枚举里面，之前的HEQUIP_NUMBER和HEQUIPEX_LONGWEN都是19！！
--	HEQUIPEX_RUNE,				//令牌 2014Q2 新装备 Vega 
--	HEQUIPEX_HXY,					//爵位 豪侠印 Vega 20141101

local g_EquipRepair_14_pos 
local g_EquipRepair_15_pos 
local g_EquipRepair_16_pos 

function EquipRepair_PreLoad()

	this:RegisterEvent("UI_COMMAND",true);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("UPDATE_EQUIP_REPAIR",true);--挪入
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false);--挪出
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("REFRESH_EQUIP",false)--装备更新
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function EquipRepair_OnLoad()
	EQUIP_BUTTONS = EquipRepair_Item
	EQUIP_ACTIONBUTTON={
	EquipRepair_1,EquipRepair_2,EquipRepair_3,EquipRepair_4,EquipRepair_5,EquipRepair_6,
	EquipRepair_7,EquipRepair_8,EquipRepair_9,EquipRepair_10,EquipRepair_11,EquipRepair_12,
	EquipRepair_13,EquipRepair_14,EquipRepair_15,EquipRepair_16
	}
	EQUIP_MASKBUTTON={
	EquipRepair_1_Mask,EquipRepair_2_Mask,EquipRepair_3_Mask,EquipRepair_4_Mask,EquipRepair_5_Mask,
	EquipRepair_6_Mask,EquipRepair_7_Mask,EquipRepair_8_Mask,EquipRepair_9_Mask,EquipRepair_10_Mask,
	EquipRepair_11_Mask,EquipRepair_12_Mask,EquipRepair_13_Mask,EquipRepair_14_Mask,EquipRepair_15_Mask,
	EquipRepair_16_Mask
	}
	EQUIP_ANIMATEBTN={
	EquipRepair_1_Animate,EquipRepair_2_Animate,EquipRepair_3_Animate,EquipRepair_4_Animate,EquipRepair_5_Animate,
	EquipRepair_6_Animate,EquipRepair_7_Animate,EquipRepair_8_Animate,EquipRepair_9_Animate,EquipRepair_10_Animate,
	EquipRepair_11_Animate,EquipRepair_12_Animate,EquipRepair_13_Animate,EquipRepair_14_Animate,EquipRepair_15_Animate,
	EquipRepair_16_Animate
	}
	g_EquipRepair_Frame_UnifiedPosition=EquipRepair_Frame:GetProperty("UnifiedPosition");
	
	g_EquipRepair_14_pos = EquipRepair_14:GetProperty("UnifiedPosition");
	g_EquipRepair_15_pos = EquipRepair_15:GetProperty("UnifiedPosition");
	g_EquipRepair_16_pos = EquipRepair_16:GetProperty("UnifiedPosition");
end

function EquipRepair_OnEvent(event)
--PushDebugMessage(event)
	--g_Npc_Name =	Target:GetDialogNpcName();
--	神器升星互斥
	if ( event == "UI_COMMAND" ) then
		if tonumber(arg0) == 19810313 then
			g_targetId = Get_XParam_INT(0)
			g_sel_price = Get_XParam_INT(1)

			EquipRepair_UpdateRepairLine(Get_XParam_INT(2), Get_XParam_INT(3))
			
			g_SaveEquip = -1
			if  g_sel_price == -1 then
				EquipRepair_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
				EquipRepair_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))

				if g_targetId == -1 then
					EquipRepair_DragTitle:SetText("#{VIPTQ_120221_17}")
				else
					EquipRepair_DragTitle:SetText("#{INTERFACE_XML_92}")
					g_objCared = DataPool : GetNPCIDByServerID(g_targetId);
					if g_objCared == -1 then
						PushDebugMessage("server传过来的数据有问题。");
						return;
					end
					BeginCareObject_EquipRepair()
				end
				EquipRepair_InitShowInEquip()
				this:Show();
			else
				if this:IsVisible() then
					--显示价钱
					EquipRepair_DemandMoney:SetProperty("MoneyNumber", g_sel_price)
--					g_sel_price = -1
				end
			end
		elseif 80502701 == tonumber(arg0) then
			-- 新增的刷新
			if this:IsVisible() then
				if -1 ~= Get_XParam_INT(1) then
					g_sel_price = Get_XParam_INT(1)
					EquipRepair_DemandMoney:SetProperty("MoneyNumber", g_sel_price)
				end

				EquipRepair_UpdateRepairLine(Get_XParam_INT(2), Get_XParam_INT(3))
			end

		else
			for i, tempValue in g_EquipRepair_SuperWeaponStartUpCommandList do
				if tonumber(arg0) == tempValue then					
					EquipRepair_Close();
					return;
				end
			end
		end
	elseif ( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() ) then
		if arg0==nil or tonumber(arg0)==-1 then
			return
		end

		if g_SaveEquip ~= -1 and g_SaveEquip == tonumber(arg0) then
			g_CurSelect=EquipRepair_UpdateFail()
			g_SaveEquip = -1
		end
		if (g_CurSelect == tonumber(arg0) ) then
--		EquipRepair_Clear()
			EquipRepair_UpdateInBag(tonumber(arg0))
		end

	elseif( event == "UPDATE_EQUIP_REPAIR") then
		if arg0 ~= nil then
--			EquipRepair_Clear()
			EquipRepair_UpdateInBag(tonumber(arg0));
		end
	elseif( event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible() ) then
		if (arg0~=nil and tonumber(arg0) == 33) then
			EquipRepair_Clear()
		end
	elseif (event == "ADJEST_UI_POS" ) then
		EquipRepair_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipRepair_Frame_On_ResetPos()

	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif	( event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		EquipRepair_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		EquipRepair_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	end
	if (event=="REFRESH_EQUIP" and this:IsVisible()) then
		if g_CurSelect>100 then
			EquipRepair_Clear()
		end
		EquipRepair_InitShowInEquip()
		if g_SaveEquip ~= -1 then
			local retSel=EquipRepair_UpdateFail()
			g_SaveEquip=-1
			if retSel>100 then
				EquipRepair_ActionButton_Clk(math.mod(retSel,100))
			end
		end
	end
end

--=========================================================
-- 刷新装备修理线和一键修理钱数
--=========================================================
function EquipRepair_UpdateRepairLine(nTotalPrice, nRepairLine)

	if g_nRepairLine ~= nRepairLine then
		g_nRepairLine = nRepairLine
	end

	EquipRepair_Number : SetText(g_nRepairLine)

	if g_nTotalPrice ~= nTotalPrice then
		g_nTotalPrice = nTotalPrice
	end

	local nGold, nSilver, nCopper = Bank:TransformCoin(g_nTotalPrice);

	local strMoney = ""

	if 0 ~= nGold then
		strMoney = tostring(nGold).."#-14"
	end

	if 0 ~= nSilver then
		strMoney = strMoney..tostring(nSilver).."#-15"
	end

	strMoney = strMoney..tostring(nCopper).."#-16"

	EquipRepair_YijianXiuli : SetToolTip( ScriptGlobal_Format("#{YJXLZB_20220818_04}", strMoney) )
end

--=========================================================
-- 修理线改变
--=========================================================
function EquipRepair_OnRepairLineChanged()
	local nCurRepairLine = tonumber(EquipRepair_Number : GetText())
	if nil == nCurRepairLine or nCurRepairLine < 0 then
		nCurRepairLine = 0
	end

	if nCurRepairLine ~= g_nRepairLine then
		-- x805027_SetEquipRepairLine( sceneId, selfId, nValue, targetId, bCurSelectedEquipIsEquiped, nCurSelectedEquipPos )
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("SetEquipRepairLine")
			Set_XSCRIPT_ScriptID(805027)
			Set_XSCRIPT_Parameter(0, nCurRepairLine)
			Set_XSCRIPT_Parameter(1, g_targetId)
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()	
	end
end

--=========================================================
-- 快速一键修理
--=========================================================
function EquipRepair_OnQuickRepair()
	-- 执行一键修理 nOpType 1、普通一键修理 2、VIP一键修理
	-- nComfirmForShenQi 0 未二次确认 1 确认使用神魂液 2 确认不使用神魂液
	-- x805027_DoQuickRepairAllEquip( sceneId, selfId, targetId, nOpType, nYuanBaoPayFlag, nComfirmForShenQi )

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("DoQuickRepairAllEquip")
		Set_XSCRIPT_ScriptID(805027)
		Set_XSCRIPT_Parameter(0, g_targetId)
		Set_XSCRIPT_Parameter(1, 1)
		Set_XSCRIPT_Parameter(2, 1)
		Set_XSCRIPT_Parameter(3, 0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()	
end

function EquipRepair_UpdateFail()
	local ActionEquip=nil
	if g_SaveEquip>100 then
		--装备位
		if g_ValidEquipPos[g_SaveEquip-100]==nil then
			return -1
		end
		ActionEquip=EnumAction(g_ValidEquipPos[g_SaveEquip-100], "equip")
	elseif g_SaveEquip>=0 then
		--背包位
		ActionEquip = EnumAction(g_SaveEquip, "packageitem")
	end
	if ActionEquip==nil then
		return -1
	end
	if ActionEquip:GetID() == 0 then
		return -1
	end

	local nDur = ActionEquip : GetEquipDur()
	if nDur < 1.0 then
		if g_CurSelect == -1 then
			local nTimes = ActionEquip : GetRemainRepairCount()
			if nTimes ~= 0 then
				return g_SaveEquip
			else
				PushDebugMessage("#{CZDYH_161122_11}")	--#H装备可修理次数为0，请增加可修理次数后再进行修理。	
			end
		end
	end
	return -1
end
function EquipRepair_InitShowInEquip()
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
		EquipRepair_14:Hide()
		EquipRepair_15:Hide()
		EquipRepair_16:SetProperty("UnifiedPosition", g_EquipRepair_14_pos);
		EquipRepair_16_Animate:SetProperty("UnifiedPosition", g_EquipRepair_14_pos);
	else
		EquipRepair_14:Show()
		EquipRepair_15:Show()
		EquipRepair_16:SetProperty("UnifiedPosition", g_EquipRepair_16_pos);
		EquipRepair_16_Animate:SetProperty("UnifiedPosition", g_EquipRepair_16_pos);
	end
	-- EquipRepair_Number : SetProperty("DefaultEditBox", "True")
end

function EquipRepair_OnShown()
	EquipRepair_Clear()
end

function EquipRepair_Clear()
	if g_CurSelect>=0 then
		EQUIP_BUTTONS : SetActionItem(-1);
		if g_CurSelect>100 then
			EQUIP_ANIMATEBTN[g_CurSelect-100]:Hide()
		elseif g_CurSelect>=0 then
			LifeAbility : Lock_Packet_Item(g_CurSelect,0);
		end
		g_CurSelect=-1
	end

	EquipRepair_DemandMoney : SetProperty("MoneyNumber", 0);
	EquipRepair_Endurance_Num:SetText("")
end

function EquipRepair_UpdateInBag(pos0)
	local pos_packet = tonumber(pos0);
	local theAction = EnumAction(pos_packet, "packageitem");
	local ItemID = PlayerPackage : GetItemTableIndex(pos_packet)

	if theAction:GetID() ~= 0 then
		local EquipPoint = LifeAbility:Get_Equip_Point(pos_packet)
		if EquipPoint == -1 or EquipPoint == 8 or EquipPoint == 9 or EquipPoint == 10
			or PlayerPackage:IsBagItemKFS(pos_packet) ==1 then --武魂的限制
			if EquipPoint ~= -1 then
				PushDebugMessage("此物品不需要修理。")
			end
			return
		end
		if EquipPoint==16 then
			PushDebugMessage("#{XHRYH_170614_51}")
			return
		end

		local nEquipID = PlayerPackage : GetItemTableIndex(pos_packet)
		if nEquipID >= EQUIP_SHENQI_BEGIN and nEquipID <= EQUIP_SHENQI_END then
			--SetNotifyTip("#{XLSQ_20101209_01}")
			PushDebugMessage("#{XHRYH_170614_52}")
			return
		end
		--可修理次数是否为0
		local nTimes = theAction : GetRemainRepairCount()
		if nTimes==0 then
			PushDebugMessage("#{XHRYH_170614_53}")
			return
		end
		local curDur,MaxDur= theAction:GetEquipDurValue()
		if curDur>=MaxDur then
			PushDebugMessage("#{XHRYH_170614_54}")
			return
		end
		EquipRepair_Clear()
		EQUIP_BUTTONS:SetActionItem(theAction:GetID());
		--让之前的东西变亮
		g_CurSelect = pos_packet
		LifeAbility : Lock_Packet_Item(pos_packet,1);
		if curDur<=10 then
			curDur="#cff0000"..curDur
		end
		local nValueText = ScriptGlobal_Format( "#{XHRYH_170608_16}", curDur, MaxDur )
		EquipRepair_Endurance_Num:SetText(nValueText)
		if ItemID < EQUIP_SHENQI_BEGIN or ItemID > EQUIP_SHENQI_END then
			-- Clear_XSCRIPT();
			-- 	Set_XSCRIPT_Function_Name("CalRepairPrice");
			-- 	Set_XSCRIPT_ScriptID(805027);
			-- 	Set_XSCRIPT_Parameter(0,math.floor(g_CurSelect/100));
			-- 	Set_XSCRIPT_Parameter(1,g_CurSelect);
			-- 	Set_XSCRIPT_Parameter(2,g_targetId);
			-- 	Set_XSCRIPT_ParamCount(3);
			-- Send_XSCRIPT();

			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("AskRefreshCommonEquipRepairUI")
				Set_XSCRIPT_ScriptID(805027)
				Set_XSCRIPT_Parameter(0, g_targetId)
				Set_XSCRIPT_Parameter(1, math.floor(g_CurSelect/100))
				Set_XSCRIPT_Parameter(2, g_CurSelect)
				Set_XSCRIPT_ParamCount(3)
			Send_XSCRIPT()
		end
		g_SaveEquip=-1
	else

		EQUIP_BUTTONS:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(g_CurSelect,0);
		g_CurSelect = -1;
	end

end

function EquipRepair_OK_InEquip()
	
	--可修理次数
	local ActionEquip=EnumAction(g_ValidEquipPos[g_CurSelect-100], "equip")
	if ActionEquip:GetID()==0 then
		PushDebugMessage("#{XHRYH_170608_24}")
		return
	end
	local nTimes = ActionEquip:GetRemainRepairCount()
	if nTimes<=0 then
		PushDebugMessage("#{XHRYH_170608_26}")
		return
	end
	local curDur,MaxDur= ActionEquip:GetEquipDurValue()
	
end

function EquipRepair_Buttons_Clicked()
	if g_CurSelect==-1 then
		PushDebugMessage("#{XHRYH_170608_24}")
		return
	end
	if g_CurSelect>100 then
		if g_ValidEquipPos[g_CurSelect-100]==nil then
			PushDebugMessage("#{XHRYH_170608_24}")
			return
		end
	end
	local ActionEquip=nil
	if g_CurSelect>100 then
		ActionEquip=EnumAction(g_ValidEquipPos[g_CurSelect-100], "equip")
	else
		ActionEquip=EnumAction(g_CurSelect, "packageitem")
	end
	--有效否
	if ActionEquip:GetID()==0 then
		PushDebugMessage("#{XHRYH_170608_24}")
		return
	end
	--神器？
	local nEquipID=0
	if g_CurSelect>100 then
		nEquipID= ActionEquip:GetItemTableIndex()
	else
		nEquipID = PlayerPackage : GetItemTableIndex(g_CurSelect)--可以合并
	end
	if nEquipID >= EQUIP_SHENQI_BEGIN and nEquipID <= EQUIP_SHENQI_END then
		PushDebugMessage("#{XLSQ_20101209_01}")
		return
	end
	--可修理次数？
	local nTimes = ActionEquip:GetRemainRepairCount()
	if nTimes<=0 then
		PushDebugMessage("#{XHRYH_170608_26}")
		return
	end
	--钱够不？
	local playerMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	if playerMoney<g_sel_price then
		local ValueTip = ScriptGlobal_Format( "#{XHRYH_170614_56}", g_sel_price )
		PushDebugMessage(ValueTip)
		return
	end
	
	-- local enterID = 2;
	-- if targetId ~= -1 then enterID = 0; end
	-- 上面这个targetId正常不存在，是个nil，这里笔误了，为了不改变外网状况，直接赋值0
	
	local enterID = 0

	if g_CurSelect>100 then
		-- Clear_XSCRIPT();
		-- 	Set_XSCRIPT_Function_Name("OnEquipRepairofEquip");
		-- 	Set_XSCRIPT_ScriptID(805027);
		-- 	Set_XSCRIPT_Parameter(0,enterID);
		-- 	Set_XSCRIPT_Parameter(1,g_targetId);
		-- 	Set_XSCRIPT_Parameter(2,g_ValidEquipPos[g_CurSelect-100]);
		-- 	Set_XSCRIPT_ParamCount(3);
		-- Send_XSCRIPT();

		-- x805027_OnEquipRepairNew(sceneId, selfId, targetId, bEquipedEquip, nRepairEquipPos, nCaiLiaoPos, nYuanBaoPayFlag, nEnterID)
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnEquipRepairNew")
			Set_XSCRIPT_ScriptID(805027)
			Set_XSCRIPT_Parameter(0, g_targetId)
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_Parameter(2, g_ValidEquipPos[g_CurSelect-100])
			Set_XSCRIPT_Parameter(3, -1)
			Set_XSCRIPT_Parameter(4, 1)
			Set_XSCRIPT_Parameter(5, enterID)
			Set_XSCRIPT_ParamCount(6)
		Send_XSCRIPT()

		g_SaveEquip = g_CurSelect
		EquipRepair_Clear();
	else
		-- Clear_XSCRIPT();
		-- 	Set_XSCRIPT_Function_Name("OnEquipRepair");
		-- 	Set_XSCRIPT_ScriptID(805027);
		-- 	Set_XSCRIPT_Parameter(0,enterID);
		-- 	Set_XSCRIPT_Parameter(1,g_targetId);
		-- 	Set_XSCRIPT_Parameter(2,g_CurSelect);
		-- 	Set_XSCRIPT_ParamCount(3);
		-- Send_XSCRIPT();

		-- x805027_OnEquipRepairNew(sceneId, selfId, targetId, bEquipedEquip, nRepairEquipPos, nCaiLiaoPos, nYuanBaoPayFlag, nEnterID)
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnEquipRepairNew")
			Set_XSCRIPT_ScriptID(805027)
			Set_XSCRIPT_Parameter(0, g_targetId)
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_Parameter(2, g_CurSelect)
			Set_XSCRIPT_Parameter(3, -1)
			Set_XSCRIPT_Parameter(4, 1)
			Set_XSCRIPT_Parameter(5, enterID)
			Set_XSCRIPT_ParamCount(6)
		Send_XSCRIPT()
		g_SaveEquip = g_CurSelect
		EquipRepair_Clear();
	end
end

function EquipRepair_Close()
	EquipRepair_Clear();
	StopCareObject_EquipRepair()
	this:Hide()
end

function EquipRepair_Cancel_Clicked()
	EquipRepair_Close();
end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function BeginCareObject_EquipRepair()
	this:CareObject(g_objCared, 1, "EquipRepair");
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function StopCareObject_EquipRepair(g_objCaredId)

	this:CareObject(g_objCared, 0, "EquipRepair");
	g_objCared = -1;

end

function EquipRepair_Frame_On_ResetPos()
  EquipRepair_Frame:SetProperty("UnifiedPosition", g_EquipRepair_Frame_UnifiedPosition);
end

--待修理装备清理
function EquipRepair_Item_RClick()
	EquipRepair_Clear()
end

function EquipRepair_ActionButton_Clk(index)
	if g_ValidEquipPos[index]==nil then
		return
	end
--	g_CurSelect=-1
	--当选==前选 返回
	if g_CurSelect==100+index then
		return
	end

	--当前选中的是否合乎要求
	--穿戴
	local ActionEquip=EnumAction(g_ValidEquipPos[index], "equip")
	if ActionEquip:GetID()~=0 then
	else
		PushDebugMessage("#{XHRYH_170608_25}")
		return
	end

	--神器否
	local nEquipID= ActionEquip:GetItemTableIndex()
	if nEquipID >= EQUIP_SHENQI_BEGIN and nEquipID <= EQUIP_SHENQI_END then
		PushDebugMessage("#{XHRYH_170614_52}")
		return
	end
	--可修理次数是否为0
	local nTimes = ActionEquip : GetRemainRepairCount()
	if nTimes==0 then
		PushDebugMessage("#{XHRYH_170614_53}")
		return
	end
	--耐久度满否
	local curDur,MaxDur= ActionEquip:GetEquipDurValue()
	if curDur>=MaxDur then
		PushDebugMessage("#{XHRYH_170608_27}")
		return
	end

	--可以放入了，清理记录
	if g_CurSelect>100 then
		EQUIP_ANIMATEBTN[g_CurSelect-100]:Hide()
	elseif g_CurSelect>=0 then
		--装备位取消
		LifeAbility : Lock_Packet_Item(g_CurSelect,0);
	end

	--放入逻辑
	g_CurSelect = index+100;
	EQUIP_ANIMATEBTN[index]:Show()
	EQUIP_BUTTONS:SetActionItem(ActionEquip:GetID());
	if curDur<=10 then
		curDur="#cff0000"..curDur
	end
	local nValueText = ScriptGlobal_Format( "#{XHRYH_170608_16}", curDur, MaxDur )
	EquipRepair_Endurance_Num:SetText(nValueText)

	--请求花费
	-- Clear_XSCRIPT();
	-- 	Set_XSCRIPT_Function_Name("CalRepairPrice");
	-- 	Set_XSCRIPT_ScriptID(805027);
	-- 	Set_XSCRIPT_Parameter(0,math.floor(g_CurSelect/100));--1表示装备位; 0表示背包位
	-- 	Set_XSCRIPT_Parameter(1,g_ValidEquipPos[index]);
	-- 	Set_XSCRIPT_Parameter(2,g_targetId);
	-- 	Set_XSCRIPT_ParamCount(3);
	-- Send_XSCRIPT();

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("AskRefreshCommonEquipRepairUI")
		Set_XSCRIPT_ScriptID(805027)
		Set_XSCRIPT_Parameter(0, g_targetId)
		Set_XSCRIPT_Parameter(1, math.floor(g_CurSelect/100))
		Set_XSCRIPT_Parameter(2, g_ValidEquipPos[index])
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

	g_SaveEquip=-1
end
