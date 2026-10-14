-- 龙纹重洗属性界面

local m_UI_NUM = 20110727
local m_ObjCared = -1
local m_Equip_Idx = -1

local UI_TYPE_PRORESET	= 1

local TYPE_COMPOUND		= 1
local TYPE_STARUP		= 2
local TYPE_PRORESET		= 3

local m_UIType = 0

--重洗属性需要的物品
local m_DepleteItem = 20310180		--静元水，暂时用高级根骨丹替代
local m_NeedMoney   = {2000, 4000, 6000, 8000, 10000, 12000, 14000, 14000, 14000, 14000, 14000}	--按静云水个数不同而不同
local m_NeedItemNum = {1, 2, 3, 4, 5, 6, 7, 7, 7, 7, 7}			--数量按等级不同而不同

local g_LongwenIsWashed =0


--PreLoad
function LongwenPropertyResetNEW_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_LW_PRORESET")
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("EUQIPATTR_UPDATE_RECOIN")
	this:RegisterEvent("LW_ATTR_RECOIN_CONFIRM_OK");
	this:RegisterEvent("RESUME_ENCHASE_GEM");
end

--OnLoad
function LongwenPropertyResetNEW_OnLoad()
end

--OnEvent
function LongwenPropertyResetNEW_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == m_UI_NUM) then

		if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then			--判断电话密保和二级密码保护
			return
		end

		LongwenPropertyResetNEW_BeginCareObj( Get_XParam_INT(0) );
		m_UIType = Get_XParam_INT(1)
		LongwenPropertyResetNEW_Clear(1)
		--LongwenPropertyResetNEW_Update(-1)

		this:Show()

	elseif (event == "UPDATE_LW_PRORESET" and this:IsVisible() ) then

		if m_UIType == UI_TYPE_PRORESET then

			if CheckPhoneMibaoAndMinorPasswordForCYJ() ~= 1 then			--判断电话密保和二级密码保护
				return
			end

			if arg0 ~= nil then
				LongwenPropertyResetNEW_Update( tonumber(arg0) )
			end
		end
	elseif event == "RESUME_ENCHASE_GEM" then
		if(tonumber(arg0) == 113) then
			LongwenPropertyResetNEW_TryClear()
		end
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
			LongwenPropertyResetNEW_HaveGoldNum:SetProperty("MoneyNumber", Player:GetData("MONEY"));
	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then

		LongwenPropertyResetNEW_HaveNum:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"));

	elseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil and tonumber(arg0) == m_Equip_Idx then
			LongwenPropertyResetNEW_Update(m_Equip_Idx)
		end
	elseif (event == "EUQIPATTR_UPDATE_RECOIN") then
		--更新重启的属性
		LongwenPropertyResetNEW_UpDateRecoin()

	elseif (event =="LW_ATTR_RECOIN_CONFIRM_OK") then
		if tonumber(arg1) == 1 then
			LongwenPropertyResetNEW_Clear(1) --先把原来的清空了
			LongwenPropertyResetNEW_Update(tonumber(arg0)) --再放上新的~
		elseif tonumber(arg1) == 0 then
			LongwenPropertyResetNEW_Clear(1)
			this:Hide()
		elseif tonumber(arg1) == 2 then
			LongwenPropertyResetNEW_Clear(1) --先把原来的清空了
		end

	end
end

--Update UI
function LongwenPropertyResetNEW_Update(itemIdx)

	local theAction = EnumAction(itemIdx, "packageitem")

	if theAction:GetID() ~= 0 then
		if m_UIType == UI_TYPE_PRORESET then
			if PlayerPackage:IsBagItemLW( itemIdx ) ~= 1 then
				PushDebugMessage("#{CXYH_140813_58}") -- 此处只能放入龙纹。
				return
			end
		end
		-- 如果空格内已经有对应物品了,需要弹一个二次确认……
		if m_Equip_Idx ~= -1 and itemIdx ~= m_Equip_Idx and  g_LongwenIsWashed == 1  then
			LongwenPropertyResetNEW_SendLW_AttrConfirm(itemIdx,1)
			return
		end

		LongwenPropertyResetNEW_Clear(1)
		if m_Equip_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		end

		LongwenPropertyResetNEW_BeforeIcon:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Equip_Idx = itemIdx

		local icon =  tostring(LifeAbility : Get_Item_Icon_Name(itemIdx))
		LongwenPropertyResetNEW_AfterIcon:SetProperty("Image",icon)

		local num = theAction:GetEquipAttrCount()
		local str = ""
		for i = 0, num-1 do
			local tempstr = theAction:EnumEquipExtAttr(i)
		--	g_BeforeTextList[i]:SetText(tempstr)
			str = str..tempstr
		--	PushDebugMessage("tempstr="..tempstr.."/str="..str)
		end
		LongwenPropertyResetNEW_BeforeAttrFirst:SetText(str)
		LongwenPropertyResetNEW_OK:Enable()

--	else
--		LongwenPropertyResetNEW_BeforeIcon:SetActionItem(-1);
--		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
--		m_Equip_Idx = -1;
--	end

		LongwenPropertyResetNEW_UICheck();
	end
end

--Care Obj
function LongwenPropertyResetNEW_BeginCareObj(obj_id)

	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id);
	this:CareObject(m_ObjCared, 1, "LongwenPropertyResetNEW");
end

--StopCare Obj
function LongwenPropertyResetNEW_StopCareObj(objCaredId)
	this:CareObject(objCaredId, 0, "LongwenPropertyResetNEW");
	m_ObjCared = -1;
end

--OnOK
function LongwenPropertyResetNEW_OK_Clicked()
	if m_Equip_Idx == -1 then
		return
	end

	-- 判断是否为安全时间2012.6.8-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	--判断,如果加锁则不能重洗2012.6.8-LIUBO
	if PlayerPackage:IsLock(m_Equip_Idx) == 1 then
		PushDebugMessage("#{AQSJ_120608_12}")	-- 物品已加锁，无法进行此操作。
		return
	end


	if m_UIType == UI_TYPE_PRORESET then

		local main_lv = PlayerPackage:GetBagLWData(m_Equip_Idx, "LEVEL")
		local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
		local nNeedMoney = m_NeedMoney[math.floor(main_lv / 10) + 1]

		if selfMoney < nNeedMoney then
			PushDebugMessage("#{CXYH_140813_61}")  --对不起，你身上金钱不足，无法继续进行。
			return
		end

	--	PlayerPackage:Lw_Op_Do(TYPE_PRORESET, m_Equip_Idx)
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("Lw_PropertyReset");
			Set_XSCRIPT_ScriptID(809273);
			Set_XSCRIPT_Parameter(0,m_Equip_Idx);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();




		-- 升级龙纹仍然保留在窗口内
		local tEquip_Idx = m_Equip_Idx
		local theAction = EnumAction(tEquip_Idx, "packageitem")
		if theAction:GetID() ~= 0 then
			LongwenPropertyResetNEW_BeforeIcon:SetActionItem(theAction:GetID());
			LifeAbility : Lock_Packet_Item(tEquip_Idx,1);
			m_Equip_Idx = tEquip_Idx
		else
			LongwenPropertyResetNEW_BeforeIcon:SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
			m_Equip_Idx = -1
		end

	end
end
--保留新属性
function LongwenPropertyResetNEW_Tihuan_Clicked(nGiveUp)
--PushDebugMessage(g_LongwenIsWashed)
	if g_LongwenIsWashed ==1 then

 		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("DoRefreshLw_Property");
			Set_XSCRIPT_ScriptID(809273);
			Set_XSCRIPT_Parameter(0,m_Equip_Idx);
			Set_XSCRIPT_Parameter(1,nGiveUp);
			Set_XSCRIPT_ParamCount(2);
		Send_XSCRIPT();
	end

		--设置重洗状态
	g_LongwenIsWashed =0

	LongwenPropertyResetNEW_Clear(0)
	LongwenPropertyResetNEW_Update(m_Equip_Idx)
end


--Right button clicked
function LongwenPropertyResetNEW_Resume_Equip()
	LongwenPropertyResetNEW_Update(-1)
end


function LongwenPropertyResetNEW_UICheck()
	LongwenPropertyResetNEW_HaveGoldNum:SetProperty("MoneyNumber", Player:GetData("MONEY"));
	LongwenPropertyResetNEW_HaveNum:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"));
	LongwenPropertyResetNEW_WantNum : SetProperty("MoneyNumber", 0)
--	LongwenPropertyResetNEW_CaiLiaoText:SetText("")
	LongwenPropertyResetNEW_OK:Disable()

	needConfirm = 1

	local str = ""		--当前龙纹重洗属性需要：净元水%s个
	local costItemNum = 0

	if m_Equip_Idx ~= -1 then

		local main_lv = PlayerPackage:GetBagLWData(m_Equip_Idx, "LEVEL")

		if main_lv ~= nil and main_lv > 0 and main_lv <= 100 then

			local nNeedMoney = m_NeedMoney[math.floor(main_lv / 10) + 1]
			LongwenPropertyResetNEW_WantNum : SetProperty("MoneyNumber", nNeedMoney)

			costItemNum = m_NeedItemNum[math.floor(main_lv / 10) + 1]
			str = ScriptGlobal_Format("#{CXYH_140813_71}", tostring(costItemNum))
			LongwenPropertyResetNEW_ShuliangText:SetText(str)
		end

		LongwenPropertyResetNEW_OK:Enable()
	end
end

--close & cancel
function LongwenPropertyResetNEW_Close()

	--关闭前也要来个二次确认
	if m_Equip_Idx ~= -1 and g_LongwenIsWashed == 1  then
		LongwenPropertyResetNEW_SendLW_AttrConfirm(m_Equip_Idx,0)
		return
	end
	LongwenPropertyResetNEW_Clear(1);
	this:Hide()
	LongwenPropertyResetNEW_StopCareObj(m_ObjCared)
end

function LongwenPropertyResetNEW_Cancel_Clicked()
	LongwenPropertyResetNEW_Close()
end

--handle Hide Event
function LongwenPropertyResetNEW_Frame_OnHiden()
	LongwenPropertyResetNEW_Update(-1)
end

function LongwenPropertyResetNEW_Clear(cleanaction)

	g_LongwenIsWashed = 0
	g_LongwenPropertyReset_Confirm = -1

--	for i = 0, 6 do
--			local tempTextbefore =LongwenPropertyResetNEW_BeforeAttr..i
--			local tempTextafter =LongwenPropertyResetNEW_AfterAttr..i
--			tempTextbefore:SetText("")
--			tempTextafter:SetText("")
--	end

	LongwenPropertyResetNEW_BeforeAttrFirst:SetText("")
	LongwenPropertyResetNEW_AfterAttrFirst:SetText("")
	LongwenPropertyResetNEW_ShuliangText:SetText("")
	LongwenPropertyResetNEW_OK:Disable()
	LongwenPropertyResetNEW_AfterIcon:SetProperty("Image","")
--	LongwenPropertyResetNEW_Baoliu:Disable()
	LongwenPropertyResetNEW_Tihuan:Disable()
	if cleanaction == 1 then
		if m_Equip_Idx ~= -1 then
			LongwenPropertyResetNEW_BeforeIcon:SetActionItem(-1)
			LifeAbility:Lock_Packet_Item(m_Equip_Idx, 0)
			m_Equip_Idx = -1
		end
	end
end

function LongwenPropertyResetNEW_TryClear()
	if m_Equip_Idx ~= -1 and g_LongwenIsWashed == 1  then
		LongwenPropertyResetNEW_SendLW_AttrConfirm(m_Equip_Idx,2)
		return
	end

	LongwenPropertyResetNEW_Clear(1) --先把原来的清空了

end

function LongwenPropertyResetNEW_UpDateRecoin()
	local num =  DataPool : Lua_GetRecoinNum();

	local str = ""
	for i = 0, num-1 do
		local tempstr = DataPool :Lua_GetRecoinEnumAttr(i)
		str = str..tempstr
	end

	LongwenPropertyResetNEW_AfterAttrFirst:SetText(str)
--	LongwenPropertyResetNEW_Baoliu:Enable()
	LongwenPropertyResetNEW_Tihuan:Enable()
	g_LongwenIsWashed =1
end


--发送替换龙纹属性的二次确认
function LongwenPropertyResetNEW_SendLW_AttrConfirm(nIndex,keepopen)
	PushEvent("LW_ATTR_RECOIN_CONFIRM",tostring(nIndex),tostring(keepopen))
end


