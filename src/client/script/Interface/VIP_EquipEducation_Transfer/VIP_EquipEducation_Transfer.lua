--2015 VIP随身移功能 By YuanPeiLong
local Enchange_Item1 = -1;
local Enchange_Item2 = -1;
--local g_Object = -1;
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

local g_VIP_EquipEducation_Transfer_SourceAction = nil;
local g_VIP_EquipEducation_Transfer_TargetAction = nil;
local g_VIP_EquipEducation_Transfer_Confirm = -1;

local g_VIP_EquipEducation_Transfer_Frame_UnifiedPosition;

function VIP_EquipEducation_Transfer_PreLoad()

	this:RegisterEvent("UI_COMMAND")

	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("SHOUGONG_ZHUANYI");
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("EQUIP_TRANSFER_SENDMSG")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)--TT:192064
end

function VIP_EquipEducation_Transfer_OnLoad()
	g_VIP_EquipEducation_Transfer_SourceAction = VIP_EquipEducation_Transfer_BeforeIcon;
	g_VIP_EquipEducation_Transfer_TargetAction = VIP_EquipEducation_Transfer_AfterIcon;
	g_VIP_EquipEducation_Transfer_Frame_UnifiedPosition=VIP_EquipEducation_Transfer_Frame:GetProperty("UnifiedPosition");
	
	g_ETBefore_Attr[1] = VIP_EquipEducation_Transfer_BeforeAttrFirst
	g_ETBefore_Attr[2] = VIP_EquipEducation_Transfer_BeforeAttrSecond
	g_ETBefore_Attr[3] = VIP_EquipEducation_Transfer_BeforeAttrThird
	
	g_ETAfter_Attr[1] = VIP_EquipEducation_Transfer_AfterAttrFirst
	g_ETAfter_Attr[2] = VIP_EquipEducation_Transfer_AfterAttrSecond
	g_ETAfter_Attr[3] = VIP_EquipEducation_Transfer_AfterAttrThird
	
	
	
	
end

function VIP_EquipEducation_Transfer_OnEvent(event)
	if ( event == "UI_COMMAND" ) then
		--if tonumber(arg0) == 20130628 then	--打开界面
		if tonumber(arg0) == 98760004 then	--打开界面
			if Player:GetData("Is2606S") == 1 then
				return
			end
			-- local xx = Get_XParam_INT(0);
			-- if tonumber(xx) == -1 then
				-- return
			-- end
			-- objCared = -1
			-- objCared = DataPool : GetNPCIDByServerID(xx);
			-- if tonumber(objCared)==nil or  tonumber(objCared)== -1 then
				-- PushDebugMessage("server传过来的数据有问题。");
				-- return;
			-- end
			VIP_EquipEducation_Transfer_OnHiden()
			local GemUnionPos = Variable:GetVariable("2014SuiShenUnionPos");
			if(GemUnionPos ~= nil) then
				VIP_EquipEducation_Transfer_Frame:SetProperty("UnifiedPosition", GemUnionPos);
			end
			VIP_EquipEducation_Transfer_FenYe4:SetCheck(1)			
			
			DataPool : SetEquipTransferSP(-1)
			this:Show();
			--VIP_EquipEducation_Transfer_BeginCareObject(objCared);
			VIP_EquipEducation_Transfer_UpdateMoney()
			VIP_EquipEducation_Transfer_OK:Disable()
		elseif tonumber(arg0) == 20130731 and this:IsVisible() then	--更新状态
			VIP_EquipEducation_Transfer_SetSourceData(Get_XParam_INT(0))
			VIP_EquipEducation_Transfer_SetTargetAfterData(Get_XParam_INT(1))
			VIP_EquipEducation_Transfer_KKKK()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	elseif 	( event == "SHOUGONG_ZHUANYI" and this:IsVisible()) then
		local solt  =  tonumber(arg1);
		if(solt == 135) then
			VIP_EquipEducation_Transfer_SetSourceData(tonumber(arg0))
		elseif(solt == 136) then
			VIP_EquipEducation_Transfer_SetTargetData(tonumber(arg0))
		end
	elseif	( event == "PACKAGE_ITEM_CHANGED_EX" ) then
		if (tonumber(Enchange_Item1) == tonumber(arg0)) then
		end
		if (tonumber(Enchange_Item2) == tonumber(arg0)) then
		end
	elseif (event == "ADJEST_UI_POS" ) then
		VIP_EquipEducation_Transfer_Frame_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		VIP_EquipEducation_Transfer_Frame_On_ResetPos()
	elseif	( event == "MONEY_CHANGE_EX" ) then
		VIP_EquipEducation_Transfer_UpdateMoney()
	elseif (event == "MONEYJZ_CHANGE_EX") then
		VIP_EquipEducation_Transfer_UpdateMoney()
	elseif (event == "RESUME_ENCHASE_GEM_EX") then
		if( tonumber(arg0) == 135 ) then
			VIP_EquipEducation_Transfer_CleanSourceData()
		elseif (tonumber(arg0) == 136) then
			VIP_EquipEducation_Transfer_CleanTargetData()
		end
	elseif (event == "EQUIP_TRANSFER_SENDMSG" and this:IsVisible()) then
		g_VIP_EquipEducation_Transfer_Confirm = 1;	
	end
end

-- function VIP_EquipEducation_Transfer_BeginCareObject(objCared)
	-- g_Object = objCared;
	-- this:CareObject(tonumber(g_Object), 1, "VIP_EquipEducation_Transfer");
-- end

function VIP_EquipEducation_Transfer_SetSourceData(pos)

	if(g_ETBefore_bagIndex >= 0 ) then  --如果已经有数据了	
		VIP_EquipEducation_Transfer_CleanSourceData()	
	end
	
	local pos_packet = tonumber(pos)
	local theAction = EnumAction(pos_packet, "packageitem")
	
	if theAction == nil or theAction:GetID() < 0 then
		return
	end
	
	local ItemID = PlayerPackage : GetItemTableIndex(pos_packet)
	g_ETBefore_bagIndex = pos;
	DataPool:SetEquipTransferSP(theAction:GetEquipPoint())
	g_VIP_EquipEducation_Transfer_SourceAction:SetActionItem(theAction:GetID())
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

function VIP_EquipEducation_Transfer_SetTargetData(pos)

	if(g_ETAfter_bagIndex >= 0 ) then  --如果已经有数据了	
		VIP_EquipEducation_Transfer_CleanTargetData()	
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
	g_VIP_EquipEducation_Transfer_TargetAction:SetActionItem(theAction:GetID())
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
	
	VIP_EquipEducation_Transfer_OK:Enable()
	VIP_EquipEducation_Transfer_WantNum:SetProperty("MoneyNumber",tostring(g_NeedMoney))
	
end

function VIP_EquipEducation_Transfer_SetTargetAfterData(pos)

	if(g_ETAfter_bagIndex >= 0 ) then  --如果已经有数据了	
		VIP_EquipEducation_Transfer_CleanTargetData()	
	end
	
	local pos_packet = tonumber(pos)
	local theAction = EnumAction(pos_packet, "packageitem")
	local ItemID = PlayerPackage : GetItemTableIndex(pos_packet)
	g_ETAfter_bagIndex = pos;
	g_VIP_EquipEducation_Transfer_TargetAction:SetActionItem(theAction:GetID())
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


function VIP_EquipEducation_Transfer_Buttons_Clicked()
	if(g_ETBefore_bagIndex < 0) or (g_ETAfter_bagIndex < 0) then
		return
	end
	
	
	if g_VIP_EquipEducation_Transfer_Confirm == 1 then
			Clear_XSCRIPT();
				Set_XSCRIPT_Function_Name("EquipAttaZhuanyi");
				Set_XSCRIPT_ScriptID(890088);
				Set_XSCRIPT_Parameter(0,g_ETBefore_bagIndex);
				Set_XSCRIPT_Parameter(1,g_ETAfter_bagIndex);
				Set_XSCRIPT_Parameter(2,1);--2015 VIP随身移功能 By YuanPeiLong
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
					Set_XSCRIPT_Parameter(2,1);--2015 VIP随身移功能 By YuanPeiLong
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


function VIP_EquipEducation_Transfer_OnHiden()

	if g_ETBefore_bagIndex ~= -1 then
			LifeAbility : Lock_Packet_Item(g_ETBefore_bagIndex,0)
			g_VIP_EquipEducation_Transfer_SourceAction:SetActionItem(-1)
			g_ETBefore_bagIndex = -1	
	end	
	
	if g_ETAfter_bagIndex ~= -1 then
			LifeAbility : Lock_Packet_Item(g_ETAfter_bagIndex,0)
			g_VIP_EquipEducation_Transfer_TargetAction:SetActionItem(-1)
			g_ETAfter_bagIndex = -1	
	end
	for i = 0, 2 do
		g_ETBefore_Attr[i+1]:SetText("")
		g_ETAfter_Attr[i+1]:SetText("")
	end
	
	g_VIP_EquipEducation_Transfer_Confirm = -1
	DataPool : SetEquipTransferSP(-1)
	this:Hide()

end


function VIP_EquipEducation_Transfer_Frame_On_ResetPos()
  VIP_EquipEducation_Transfer_Frame:SetProperty("UnifiedPosition", g_VIP_EquipEducation_Transfer_Frame_UnifiedPosition);
end

function VIP_EquipEducation_Transfer_UpdateMoney()
	VIP_EquipEducation_Transfer_HaveNum:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")));
	VIP_EquipEducation_Transfer_HaveGoldNum:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
end

function VIP_EquipEducation_Transfer_CleanSourceData()
	if g_ETBefore_bagIndex ~= -1 then
			LifeAbility : Lock_Packet_Item(g_ETBefore_bagIndex,0)
			g_VIP_EquipEducation_Transfer_SourceAction:SetActionItem(-1)
			g_ETBefore_bagIndex = -1	
	end
	for i = 0, 2 do
		g_ETBefore_Attr[i+1]:SetText("")
	end	
	DataPool : SetEquipTransferSP(-1)
	g_VIP_EquipEducation_Transfer_Confirm = -1
	VIP_EquipEducation_Transfer_CleanTargetData()		--清理源装备同时也需要清理目标装备
end

function VIP_EquipEducation_Transfer_CleanTargetData()
	if g_ETAfter_bagIndex ~= -1 then
			LifeAbility : Lock_Packet_Item(g_ETAfter_bagIndex,0)
			g_VIP_EquipEducation_Transfer_TargetAction:SetActionItem(-1)
			g_ETAfter_bagIndex = -1	
	end
	
	for i = 0, 2 do
		g_ETAfter_Attr[i+1]:SetText("")
	end	
	g_VIP_EquipEducation_Transfer_Confirm = -1
end

--2015 VIP随身移功能 By YuanPeiLong
function VIP_EquipEducation_Transfer_FenYe_Clicked( nIndex )

	if not(nIndex==1 or nIndex==2 or nIndex==3 or nIndex==4) then
		return
	end

	local nUI = 0
	if 1 == nIndex then
		nUI = 98760001
	elseif 2 == nIndex then
		nUI = 98760002
	elseif 3 == nIndex then
		nUI = 98760003
	elseif 4 == nIndex then
		return
	else
		return
	end
	if nUI ~= 0 then
		Variable:SetVariable("2014SuiShenUnionPos", VIP_EquipEducation_Transfer_Frame:GetProperty("UnifiedPosition"), 1)
		PushEvent("UI_COMMAND", nUI)
		VIP_EquipEducation_Transfer_OnHiden()
		this:Hide()
	end	
	
end

function VIP_EquipEducation_Transfer_KKKK()

	if g_ETBefore_bagIndex ~= -1 then
			LifeAbility : Lock_Packet_Item(g_ETBefore_bagIndex,0)
			g_VIP_EquipEducation_Transfer_SourceAction:SetActionItem(-1)
			g_ETBefore_bagIndex = -1	
	end	
	
	if g_ETAfter_bagIndex ~= -1 then
			LifeAbility : Lock_Packet_Item(g_ETAfter_bagIndex,0)
			g_VIP_EquipEducation_Transfer_TargetAction:SetActionItem(-1)
			g_ETAfter_bagIndex = -1	
	end
	for i = 0, 2 do
		g_ETBefore_Attr[i+1]:SetText("")
		g_ETAfter_Attr[i+1]:SetText("")
	end
	
	g_VIP_EquipEducation_Transfer_Confirm = -1
	DataPool : SetEquipTransferSP(-1)

end

function VIP_EquipEducation_Transfer_OpenVipZZEquipTransfer()

	Variable:SetVariable("2014SuiShenUnionPos", VIP_EquipEducation_Transfer_Frame:GetProperty("UnifiedPosition"), 1)
	VIP_EquipEducation_Transfer_OnHiden()
	this:Hide()
	Lua_OpenVipZZEquipTransfer()
end
