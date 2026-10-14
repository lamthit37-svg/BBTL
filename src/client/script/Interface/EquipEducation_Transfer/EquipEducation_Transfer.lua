local Enchange_Item1 = -1;
local Enchange_Item2 = -1;
local g_Object = -1;
local g_check = -1;--是否二次确认

local EB_FREE_BIND = 0;				-- 无绑定限制
local EB_BINDED = 1;				-- 已经绑定
local	EB_GETUP_BIND =2			-- 拾取绑定
local	EB_EQUIP_BIND =3			-- 装备绑定

local g_ETBefore_Attr= {};
local g_ETAfter_Attr = {};

local g_ETBefore_bagIndex = -1;
local g_ETAfter_bagIndex = -1;
local g_NeedMoney =100000

local g_EquipEducation_Transfer_SourceAction = nil;
local g_EquipEducation_Transfer_TargetAction = nil;
local g_EquipEducation_Transfer_Confirm = -1;

local g_EquipEducation_Transfer_Frame_UnifiedPosition;

function EquipEducation_Transfer_PreLoad()

	this:RegisterEvent("UI_COMMAND")

	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("SHOUGONG_ZHUANYI");
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("EQUIP_TRANSFER_SENDMSG")
end

function EquipEducation_Transfer_OnLoad()
	g_EquipEducation_Transfer_SourceAction = EquipEducation_Transfer_BeforeIcon;
	g_EquipEducation_Transfer_TargetAction = EquipEducation_Transfer_AfterIcon;
	g_EquipEducation_Transfer_Frame_UnifiedPosition=EquipEducation_Transfer_Frame:GetProperty("UnifiedPosition");
	
	g_ETBefore_Attr[1] = EquipEducation_Transfer_BeforeAttrFirst
	g_ETBefore_Attr[2] = EquipEducation_Transfer_BeforeAttrSecond
	g_ETBefore_Attr[3] = EquipEducation_Transfer_BeforeAttrThird
	
	g_ETAfter_Attr[1] = EquipEducation_Transfer_AfterAttrFirst
	g_ETAfter_Attr[2] = EquipEducation_Transfer_AfterAttrSecond
	g_ETAfter_Attr[3] = EquipEducation_Transfer_AfterAttrThird
	
	
	
	
end

function EquipEducation_Transfer_OnEvent(event)
	if ( event == "UI_COMMAND" ) then
		if tonumber(arg0) == 20130628 then	--打开界面
			EquipEducation_Transfer_OnHiden() --2015 VIP随身移功能 By YuanPeiLong
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
			DataPool : SetEquipTransferSP(-1)
			this:Show();
			EquipEducation_Transfer_BeginCareObject(objCared);
			EquipEducation_Transfer_UpdateMoney()
			EquipEducation_Transfer_OK:Disable()
		elseif tonumber(arg0) == 20130731 and this:IsVisible() then	--更新状态
			EquipEducation_Transfer_SetSourceData(Get_XParam_INT(0))
			EquipEducation_Transfer_SetTargetAfterData(Get_XParam_INT(1))
			EquipEducation_Transfer_KKKK()
		end
	elseif 	( event == "SHOUGONG_ZHUANYI" and this:IsVisible()) then
		local solt  =  tonumber(arg1);
		if(solt == 135) then
			EquipEducation_Transfer_SetSourceData(tonumber(arg0))
		elseif(solt == 136) then
			EquipEducation_Transfer_SetTargetData(tonumber(arg0))
		end
	elseif	( event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if (tonumber(Enchange_Item1) == tonumber(arg0)) then
		end
		if (tonumber(Enchange_Item2) == tonumber(arg0)) then
		end
	elseif (event == "ADJEST_UI_POS" ) then
		EquipEducation_Transfer_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		EquipEducation_Transfer_Frame_On_ResetPos()
	elseif	( event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		EquipEducation_Transfer_UpdateMoney()
	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		EquipEducation_Transfer_UpdateMoney()
	elseif (event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible()) then
		if( tonumber(arg0) == 135 ) then
			EquipEducation_Transfer_CleanSourceData()
		elseif (tonumber(arg0) == 136) then
			EquipEducation_Transfer_CleanTargetData()
		end
	elseif (event == "EQUIP_TRANSFER_SENDMSG" and this:IsVisible()) then
		g_EquipEducation_Transfer_Confirm = 1;	
	end
end

function EquipEducation_Transfer_BeginCareObject(objCared)
	g_Object = objCared;
	this:CareObject(tonumber(g_Object), 1, "EquipEducation_Transfer");
end

function EquipEducation_Transfer_SetSourceData(pos)

	if(g_ETBefore_bagIndex >= 0 ) then  --如果已经有数据了	
		EquipEducation_Transfer_CleanSourceData()	
	end
	
	local pos_packet = tonumber(pos)
	local theAction = EnumAction(pos_packet, "packageitem")
	
	if theAction == nil or theAction:GetID() < 0 then
		return
	end
	
	local ItemID = PlayerPackage : GetItemTableIndex(pos_packet)
	g_ETBefore_bagIndex = pos;
	DataPool:SetEquipTransferSP(theAction:GetEquipPoint())
	g_EquipEducation_Transfer_SourceAction:SetActionItem(theAction:GetID())
	for i = 0, 2 do
		local pName,pLevel,pBValue,pPercent,pRValue = theAction:GetEquipAttaProperty(i);
		if(pLevel == nil or pLevel <= 0) then
			g_ETBefore_Attr[i+1]:SetText("#{ZBSX_130625_14}")
		else
			--local perStr = ScriptGlobal_Format("#{ZBSX_130625_15}", pPercent, pRValue)
			local perStr = ScriptGlobal_Format("#{ZBSX_130625_127}", pLevel, pRValue,pBValue,pPercent)
			local szStr = "#cfff263#{"..pName.."}"..perStr;
			g_ETBefore_Attr[i+1]:SetText(szStr)
		end
	end
	LifeAbility:Lock_Packet_Item(pos_packet,1);
	-- g_ShouGongFenpei_ItemPos = pos_packet;
end

function EquipEducation_Transfer_SetTargetData(pos)

	if(g_ETAfter_bagIndex >= 0 ) then  --如果已经有数据了	
		EquipEducation_Transfer_CleanTargetData()	
	end
	local pos_packet = tonumber(pos)
	local theAction = EnumAction(pos_packet, "packageitem")
	local ItemID = PlayerPackage : GetItemTableIndex(pos_packet)
	
	local pSourcePacket = tonumber(g_ETBefore_bagIndex)
	local SourcetheAction = EnumAction(pSourcePacket, "packageitem")
	if SourcetheAction == nil or SourcetheAction:GetID() < 0 then
		return
	end
	
	g_ETAfter_bagIndex = pos; 
	g_EquipEducation_Transfer_TargetAction:SetActionItem(theAction:GetID())
	for i = 0, 2 do
		local nQual,nLevel = theAction:GetEquipAttaBaseValue(i);
		local IsChongLouItem = PlayerPackage:IsChongLouItem(g_ETAfter_bagIndex) 
		local pName,pLevel,pBValue,pPercent,pRValue = SourcetheAction:GetEquipAttaTransferInfo(i,nQual, nLevel, IsChongLouItem);
		if(pLevel == nil or pLevel <= 0) then
			g_ETAfter_Attr[i+1]:SetText("#{ZBSX_130625_14}")
		else
			--local perStr = ScriptGlobal_Format("#{ZBSX_130625_15}", pPercent, pRValue)
			local perStr = ScriptGlobal_Format("#{ZBSX_130625_127}", pLevel, pRValue,pBValue,pPercent)
			local szStr = "#cfff263#{"..pName.."}"..perStr;
			g_ETAfter_Attr[i+1]:SetText(szStr)
		end
	end
	LifeAbility:Lock_Packet_Item(pos_packet,1);
	
	EquipEducation_Transfer_OK:Enable()
	EquipEducation_Transfer_WantNum:SetProperty("MoneyNumber",tostring(g_NeedMoney))
	
end

function EquipEducation_Transfer_SetTargetAfterData(pos)

	if(g_ETAfter_bagIndex >= 0 ) then  --如果已经有数据了	
		EquipEducation_Transfer_CleanTargetData()	
	end
	
	local pos_packet = tonumber(pos)
	local theAction = EnumAction(pos_packet, "packageitem")
	local ItemID = PlayerPackage : GetItemTableIndex(pos_packet)
	g_ETAfter_bagIndex = pos;
	g_EquipEducation_Transfer_TargetAction:SetActionItem(theAction:GetID())
	for i = 0, 2 do
		local pName,pLevel,pBValue,pPercent,pRValue = theAction:GetEquipAttaProperty(i);
		if(pLevel == nil or pLevel <= 0) then
			g_ETAfter_Attr[i+1]:SetText("#{ZBSX_130625_14}")
		else
			--local perStr = ScriptGlobal_Format("#{ZBSX_130625_15}", pPercent, pRValue)
			local perStr = ScriptGlobal_Format("#{ZBSX_130625_127}", pLevel, pRValue,pBValue,pPercent)
			local szStr = "#cfff263#{"..pName.."}"..perStr;
			g_ETAfter_Attr[i+1]:SetText(szStr)
		end
	end
	LifeAbility:Lock_Packet_Item(pos_packet,1);
	
end


function EquipEducation_Transfer_Buttons_Clicked()
	if(g_ETBefore_bagIndex < 0) or (g_ETAfter_bagIndex < 0) then
		return
	end
	
	
	if g_EquipEducation_Transfer_Confirm == 1 then
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("EquipAttaZhuanyi");
				Set_XSCRIPT_ScriptID(890088);
				Set_XSCRIPT_Parameter(0,g_ETBefore_bagIndex);
				Set_XSCRIPT_Parameter(1,g_ETAfter_bagIndex);
				Set_XSCRIPT_Parameter(2,0);--2015 VIP随身移功能 By YuanPeiLong
				Set_XSCRIPT_ParamCount(3);--2015 VIP随身移功能 By YuanPeiLong
			Send_XSCRIPT();
			return
	end
	--目标装备是重楼或者已绑定
	if PlayerPackage:IsChongLouItem(g_ETAfter_bagIndex) == 1 or PlayerPackage:GetItemBindStatusByIndex(g_ETAfter_bagIndex) == 1 then
			local IsHaveAttaProperty = PlayerPackage:IsHaveAttaProperty(g_ETAfter_bagIndex);
			if(IsHaveAttaProperty == 1) then
				PushEvent("EQUIP_TRANSFER_CONFIRM", 0)	--替换
			else
				Clear_XSCRIPT();
					Set_XSCRIPT_Function_Name("EquipAttaZhuanyi");
					Set_XSCRIPT_ScriptID(890088);
					Set_XSCRIPT_Parameter(0,g_ETBefore_bagIndex);
					Set_XSCRIPT_Parameter(1,g_ETAfter_bagIndex);
					Set_XSCRIPT_Parameter(2,0);--2015 VIP随身移功能 By YuanPeiLong
					Set_XSCRIPT_ParamCount(3);--2015 VIP随身移功能 By YuanPeiLong
				Send_XSCRIPT();	
			end
			return
	end
	if(PlayerPackage:GetItemBindStatusByIndex(g_ETAfter_bagIndex) ~= 1) then
		local IsHaveAttaProperty = PlayerPackage:IsHaveAttaProperty(g_ETAfter_bagIndex);
		if(IsHaveAttaProperty == 1) then
			PushEvent("EQUIP_TRANSFER_CONFIRM", 1)	--绑定加替换
		else
			PushEvent("EQUIP_TRANSFER_CONFIRM", 2)	--绑定
		end
	end


end


function EquipEducation_Transfer_OnHiden()

	if g_ETBefore_bagIndex ~= -1 then
			LifeAbility : Lock_Packet_Item(g_ETBefore_bagIndex,0)
			g_EquipEducation_Transfer_SourceAction:SetActionItem(-1)
			g_ETBefore_bagIndex = -1	
	end	
	
	if g_ETAfter_bagIndex ~= -1 then
			LifeAbility : Lock_Packet_Item(g_ETAfter_bagIndex,0)
			g_EquipEducation_Transfer_TargetAction:SetActionItem(-1)
			g_ETAfter_bagIndex = -1	
	end
	for i = 0, 2 do
		g_ETBefore_Attr[i+1]:SetText("")
		g_ETAfter_Attr[i+1]:SetText("")
	end
	
	g_EquipEducation_Transfer_Confirm = -1
	DataPool : SetEquipTransferSP(-1)
	this:Hide()

end


function EquipEducation_Transfer_Frame_On_ResetPos()
  EquipEducation_Transfer_Frame:SetProperty("UnifiedPosition", g_EquipEducation_Transfer_Frame_UnifiedPosition);
end

function EquipEducation_Transfer_UpdateMoney()
	EquipEducation_Transfer_HaveNum:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	EquipEducation_Transfer_HaveGoldNum:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
end

function EquipEducation_Transfer_CleanSourceData()
	if g_ETBefore_bagIndex ~= -1 then
			LifeAbility : Lock_Packet_Item(g_ETBefore_bagIndex,0)
			g_EquipEducation_Transfer_SourceAction:SetActionItem(-1)
			g_ETBefore_bagIndex = -1	
	end
	for i = 0, 2 do
		g_ETBefore_Attr[i+1]:SetText("")
	end	
	DataPool : SetEquipTransferSP(-1)
	g_EquipEducation_Transfer_Confirm = -1
	EquipEducation_Transfer_CleanTargetData()		--清理源装备同时也需要清理目标装备
end

function EquipEducation_Transfer_CleanTargetData()
	if g_ETAfter_bagIndex ~= -1 then
			LifeAbility : Lock_Packet_Item(g_ETAfter_bagIndex,0)
			g_EquipEducation_Transfer_TargetAction:SetActionItem(-1)
			g_ETAfter_bagIndex = -1	
	end
	
	for i = 0, 2 do
		g_ETAfter_Attr[i+1]:SetText("")
	end	
	g_EquipEducation_Transfer_Confirm = -1
end

function EquipEducation_Transfer_KKKK()

	if g_ETBefore_bagIndex ~= -1 then
			LifeAbility : Lock_Packet_Item(g_ETBefore_bagIndex,0)
			g_EquipEducation_Transfer_SourceAction:SetActionItem(-1)
			g_ETBefore_bagIndex = -1	
	end	
	
	if g_ETAfter_bagIndex ~= -1 then
			LifeAbility : Lock_Packet_Item(g_ETAfter_bagIndex,0)
			g_EquipEducation_Transfer_TargetAction:SetActionItem(-1)
			g_ETAfter_bagIndex = -1	
	end
	for i = 0, 2 do
		g_ETBefore_Attr[i+1]:SetText("")
		g_ETAfter_Attr[i+1]:SetText("")
	end
	
	g_EquipEducation_Transfer_Confirm = -1
	DataPool : SetEquipTransferSP(-1)

end
