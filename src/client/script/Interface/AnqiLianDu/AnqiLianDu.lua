--暗器金翅翎羽炼毒界面逻辑（客户端）
local MAX_OBJ_DISTANCE = 3.0
local objCared = -1
local g_Object = -1
local g_CommandType = 1
local g_Dark_Bag_Index = -1
local g_Dark_SelectPro = -1
local g_Dark_LianDuPro = -1
local g_Dark_LianDuValue = -1
local g_Mainitem = 10155008
local g_LingYuLianDuItem = {20800039,20800041,20800043}
local g_LingYuLanDuMaxValue = {10688,176,2175}
local g_LingYuProStr = {"#{equip_attr_attack_cold}","#{equip_attr_attack_fire}","#{equip_attr_attack_light}","#{equip_attr_attack_poison}"};

function AnqiLianDu_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("MONEY_CHANGE_EX",false)
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false)
	this:RegisterEvent("UPDATE_ANQILIANDU")
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false)
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("LYDARK_LIANDU_REFRESH")
end

function AnqiLianDu_OnLoad()
end

function AnqiLianDu_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 800034) then
		
		if this:IsVisible() then
			AnqiLianDu_Close()
		end

		objCared = -1;
		local tempID = Get_XParam_INT(1);
		objCared = DataPool : GetNPCIDByServerID(tempID);

		if objCared == -1 then
			PushDebugMessage("异常数据，请稍后再试！")
			return
		end
		
		AnqiLianDu_BeginCareObject(objCared)

		g_CommandType = Get_XParam_INT(0)
		if g_CommandType == 13 then
			AnqiLianDu_InitDlg()
		end
	elseif (event == "UPDATE_ANQILIANDU" and this:IsVisible()) then
		if arg0~= nil then
			AnqiLianDu_Update(arg0)
		end
	elseif (event == "LYDARK_LIANDU_REFRESH" and this:IsVisible()) then
		if arg0 ~= nil and arg1 ~= nil then
			g_Dark_LianDuPro = tonumber(arg0)
			g_Dark_LianDuValue = tonumber(arg1)
		end
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= objCared) then
			return
		end

		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			AnqiLianDu_Close()
		end
	elseif( (event == "MONEY_CHANGE_EX" or event == "MONEYJZ_CHANGE_EX") and this:IsVisible()) then
		AnqiLianDu_UpdateMoneyDisp()
	elseif(event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible())then
		if(tonumber(arg0) == 177) then
			AnqiLianDu_Resume()
		end
	elseif(event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil then
			if (g_Dark_Bag_Index == tonumber(arg0)) then
				AnqiLianDu_UpdateProDes()
			end
		end
	end
end

function AnqiLianDu_UpdateMoneyDisp()
	if g_Dark_Bag_Index ~= -1 then
		local playerMoney = Player:GetData("MONEY");
		local playerMoneyJZ = Player:GetData("MONEY_JZ");
		AnqiLianDu_SelfJiaozi:SetProperty("MoneyNumber", playerMoneyJZ);
		AnqiLianDu_SelfMoney:SetProperty("MoneyNumber", playerMoney);
	end
end

function AnqiLianDu_InitDlg()
	AnqiLianDu_Reset()
	AnqiLianDu_DemandMoney:SetProperty("MoneyNumber", 0)
	AnqiLianDu_SelfJiaozi:SetProperty("MoneyNumber", 0)
	AnqiLianDu_SelfMoney:SetProperty("MoneyNumber", 0)
	this:Show()
end

--确认进阶按钮回调
function AnqiLianDu_OK_Clicked()
	--请先放入暗器。
	if (g_Dark_Bag_Index == -1) then
		PushDebugMessage("#{AQJJ_160127_93}")
		return
	end
	
	--请选择重洗类型
	if (g_Dark_SelectPro == -1) then
		PushDebugMessage("#{AQJJ_160127_101}")
		return
	end

	local EquipPoint = LifeAbility : Get_Equip_Point(g_Dark_Bag_Index)
	if (EquipPoint ~= 17) then
		PushDebugMessage("#{AQJJ_160127_99}")
		return
	end
	
	--暗器炼毒
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("LingyuLianDu")
		Set_XSCRIPT_ScriptID(260001)
		Set_XSCRIPT_Parameter(0,g_Dark_Bag_Index)
		Set_XSCRIPT_Parameter(1,g_Dark_SelectPro)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

--取消按钮回调
function AnqiLianDu_Cancel_Clicked()
	AnqiLianDu_Close()
end

--关闭界面按钮回调
function AnqiLianDu_CloseUI_Clicked()
	AnqiLianDu_Close()
end

--炼毒属性选择按钮回调
function AnqiLianDu_ProSelect_Clicked(ind)
	if ind >= 0 and ind < 3 then
		g_Dark_SelectPro = ind
		local needItemCount,needJz = DataPool : GetLYDarkLianduCostDataInBag(g_Dark_Bag_Index, g_Dark_SelectPro)
		if needItemCount == nil or needItemCount == -1 or needJz == nil or needJz == -1 then
			AnqiLianDu_Frame_NeedItem : SetText("")
			AnqiLianDu_DemandMoney:SetProperty("MoneyNumber", 0);
			return
		end
		local tips = ScriptGlobal_Format("#{AQJJ_160127_98}",needItemCount,PlayerPackage:GetItemName(g_LingYuLianDuItem[ind + 1]))
		AnqiLianDu_Frame_NeedItem : SetText(tips)
		AnqiLianDu_DemandMoney:SetProperty("MoneyNumber", needJz * 10000);
	end
end

--界面Hide回调
function AnqiLianDu_Clear()
	AnqiLianDu_Reset()
	AnqiLianDu_StopCareObject()
end

function AnqiLianDu_Update(Item_index)
	local i_index = tonumber(Item_index)
	local theAction = EnumAction(i_index, "packageitem");

	if theAction:GetID() ~= 0 then
		if PlayerPackage : GetItemTableIndex( i_index ) ~= g_Mainitem then
			PushDebugMessage("#{AQJJ_160127_99}")
			return
		end
		
		--判断金翅翎羽是否粹毒
		local addMaxHP,addPro,addHit,addProType = DataPool : GetLYDarkCuiDuData(i_index)
		if addMaxHP <= 0 or addPro <= 0 or addHit <= 0 or addProType < 0 or addProType > 3 then
			PushDebugMessage("#{AQJJ_160127_151}")
			return
		end 
		
		if i_index == g_Dark_Bag_Index then
			return
		end

		--界面清空
		AnqiLianDu_Reset()
		--设置ActionItem
		AnqiLianDu_Frame_Icon:SetActionItem(theAction:GetID());
		g_Dark_Bag_Index = i_index
		LifeAbility : Lock_Packet_Item(i_index,1)
		AnqiLianDu_OK:Enable()
		AnqiLianDu_UpdateMoneyDisp()
		
		AnqiLianDu_Frame_AttrFirst : Enable()
		AnqiLianDu_Frame_AttrSecond : Enable()
		AnqiLianDu_Frame_AttrThird : Enable()
		--更新描述
		AnqiLianDu_UpdateProDes()
	end

end

function AnqiLianDu_UpdateProDes()
	if g_Dark_Bag_Index == -1 then
		return
	end

	local addMaxHP,addPro,addHit,addProType = DataPool : GetLYDarkCuiDuData(g_Dark_Bag_Index)
	if addMaxHP <= 0 or addPro <= 0 or addHit <= 0 or addProType < 0 or addProType > 3 then
		return
	end
	
	local tip1 = ScriptGlobal_Format("#{AQJJ_160127_95}","#{equip_attr_maxhp}",addMaxHP,g_LingYuLanDuMaxValue[1])
	local tip2 = ScriptGlobal_Format("#{AQJJ_160127_95}",g_LingYuProStr[addProType + 1],addPro,g_LingYuLanDuMaxValue[2])
	local tip3 = ScriptGlobal_Format("#{AQJJ_160127_95}","#{equip_attr_hit}",addHit,g_LingYuLanDuMaxValue[3])

	local tip4 = ""
	if g_Dark_LianDuValue >= 0 then
		tip4 = ScriptGlobal_Format("#{AQJJ_160127_96}",g_Dark_LianDuValue)
	end 
	
	--星级加成
	local tip11 = ""
	local tip21 = ""
	local tip31 = ""
	local skillPersent,cuiduPersent = DataPool : GetLYDarkStarAddDataInBag(g_Dark_Bag_Index)
	if skillPersent ~= nil and skillPersent ~= -1 and cuiduPersent ~= nil and cuiduPersent ~= -1 then
		tip11 = ScriptGlobal_Format("#{AQJJ_160127_153}",math.ceil(addMaxHP * cuiduPersent / 100))
		tip21 = ScriptGlobal_Format("#{AQJJ_160127_153}",math.ceil(addPro * cuiduPersent / 100))
		tip31 = ScriptGlobal_Format("#{AQJJ_160127_153}",math.ceil(addHit * cuiduPersent / 100))
	end
	--tip1 = tip1 .. tip11
	--tip2 = tip2 .. tip21
	--tip3 = tip3 .. tip31
	--炼毒加成
	--if g_Dark_LianDuPro == 0 then
	--	tip1 = tip1 .. tip4
	--elseif g_Dark_LianDuPro == 1 then
	--	tip2 = tip2 .. tip4
	--elseif g_Dark_LianDuPro == 2 then
	--	tip3 = tip3 .. tip4
	--end

	AnqiLianDu_Frame_AttrFirst : SetText(tip1)
	AnqiLianDu_Frame_AttrSecond : SetText(tip2)
	AnqiLianDu_Frame_AttrThird : SetText(tip3)
	
	if g_Dark_SelectPro < 0 or g_Dark_SelectPro >= 3 then
		return
	end
	local needItemCount,needJz = DataPool : GetLYDarkLianduCostDataInBag(g_Dark_Bag_Index, g_Dark_SelectPro)
	if needItemCount == nil or needItemCount == -1 or needJz == nil or needJz == -1 then
		AnqiLianDu_Frame_NeedItem : SetText("")
		AnqiLianDu_DemandMoney:SetProperty("MoneyNumber", 0);
		return
	end
	local tips = ScriptGlobal_Format("#{AQJJ_160127_98}",needItemCount,PlayerPackage:GetItemName(g_LingYuLianDuItem[g_Dark_SelectPro + 1]))
	AnqiLianDu_Frame_NeedItem : SetText(tips)
	AnqiLianDu_DemandMoney:SetProperty("MoneyNumber", needJz * 10000);
end

function AnqiLianDu_Reset()
	AnqiLianDu_Frame_Icon:SetActionItem(-1);
	LifeAbility : Lock_Packet_Item(g_Dark_Bag_Index,0);
	g_Dark_Bag_Index = -1
	g_Dark_SelectPro = -1
	g_Dark_LianDuPro = -1
	g_Dark_LianDuValue = -1
	AnqiLianDu_OK:Disable()
	AnqiLianDu_Frame_NeedItem : SetText("")
	AnqiLianDu_Frame_AttrFirst : Disable()
	AnqiLianDu_Frame_AttrSecond : Disable()
	AnqiLianDu_Frame_AttrThird : Disable()
	AnqiLianDu_Frame_AttrFirst : SetCheck(0)
	AnqiLianDu_Frame_AttrSecond : SetCheck(0)
	AnqiLianDu_Frame_AttrThird : SetCheck(0)
	AnqiLianDu_Frame_AttrFirst : SetText("")
	AnqiLianDu_Frame_AttrSecond : SetText("")
	AnqiLianDu_Frame_AttrThird : SetText("")
	AnqiLianDu_DemandMoney:SetProperty("MoneyNumber", 0);
end

function AnqiLianDu_Close()
	AnqiLianDu_Reset()
	AnqiLianDu_StopCareObject()
	this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function AnqiLianDu_BeginCareObject(objCaredId)
	if g_Object ~= -1 then
		this:CareObject(objCaredId, 0, "AnqiLianDu");
	end
	g_Object = objCaredId
	this:CareObject(g_Object, 1, "AnqiLianDu")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function AnqiLianDu_StopCareObject()
	if g_Object ~= -1 then
		this:CareObject(g_Object, 0, "AnqiLianDu");
		g_Object = -1;
	end
end

function AnqiLianDu_Resume()
	AnqiLianDu_Reset()
	AnqiLianDu_DemandMoney:SetProperty("MoneyNumber", 0)
	AnqiLianDu_SelfJiaozi:SetProperty("MoneyNumber", 0)
	AnqiLianDu_SelfMoney:SetProperty("MoneyNumber", 0)			
end
