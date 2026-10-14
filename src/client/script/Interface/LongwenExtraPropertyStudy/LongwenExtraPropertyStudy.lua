-- 龙纹属性学习

local m_UI_NUM = 20110728
local m_ObjCared = -1
local m_Equip_Idx = -1

--扩展属性学习的类型
local UI_TYPE_ATTRSTUDY_HP		= 0		--血上限
local UI_TYPE_ATTRSTUDY_RESIST	= 1		--冰火玄毒
local UI_TYPE_ATTRSTUDY_BUFF	= 2		--减伤BUFF

--给服务器传送的参数
local TYPE_COMPOUND				= 1
local TYPE_STARUP				= 2
local TYPE_PRORESET				= 3
local TYPE_ATTRSTUDY_HP			= 4
local TYPE_ATTRSTUDY_BUFF		= 5
local TYPE_ATTRSTUDY_RESIST		= 6
local TYPE_ATTRLEVELUP_HP		= 7
local TYPE_ATTRLEVELUP_BUFF		= 8
local TYPE_ATTRLEVELUP_RESIST	= 9

--其它
local m_UIType = 0
local m_needMoney = 0
local m_needConfirm = 1
local m_IsReady = 0

--local m_DefaultHight = 400	--默认高度
--local m_FrameHight = 460	--窗口高度

--龙纹三个扩展属性的索引号起始
local m_LearnMoney = 10000								--学习花费的金钱固定
local m_DepleteItemNum = 10							--缀龙石·元、暴、护消耗的数量
local m_DepleteItemHp		= { 20310181, 20310189 }	--缀龙石·元
local m_DepleteItemResist	= { 20310182, 20310190 }	--缀龙石·暴
local m_DepleteItemBuff		= { 20310183, 20310191 }	--缀龙石·护


--PreLoad-LongwenExtraPropertyStudy.lua
function LongwenExtraPropertyStudy_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_LW_ATTRSTUDY")
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("AFTER_UPDATE_LW_BIND_CONFIRM")
end

--OnLoad
function LongwenExtraPropertyStudy_OnLoad()
end

--OnEvent
function LongwenExtraPropertyStudy_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == m_UI_NUM) then
		
		if CheckPhoneMibaoAndMinorPassword() ~= 1 then			--判断电话密保和二级密码保护
			return
		end
		
		LongwenExtraPropertyStudy_BeginCareObj( Get_XParam_INT(0) );
		m_UIType = Get_XParam_INT(1)
		
		if m_UIType == UI_TYPE_ATTRSTUDY_HP then
		
		LongwenExtraPropertyStudy_Update(-1)
		LongwenExtraPropertyStudy_Item_Change(-1)
		LongwenExtraPropertyStudy_UICheck()
		this:Show();
		
		end

	elseif (event == "UPDATE_LW_ATTRSTUDY" and this:IsVisible() ) then
		if m_UIType == UI_TYPE_ATTRSTUDY_HP then
			
			if CheckPhoneMibaoAndMinorPassword() ~= 1 then			--判断电话密保和二级密码保护
				return
			end
			
			if arg0 ~= nil then
				LongwenExtraPropertyStudy_Update( tonumber(arg0) )
			end
		end
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		LongwenExtraPropertyStudy_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));

	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		LongwenExtraPropertyStudy_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))

	elseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil and tonumber(arg0) == m_Equip_Idx then
			LongwenExtraPropertyStudy_Item_Change(m_Equip_Idx)
		end
		
	elseif (event == "AFTER_UPDATE_LW_BIND_CONFIRM" and this:IsVisible()) then
		LongwenExtraPropertyStudy_OK_Clicked_Continue()
		
	end
end

--Update UI
function LongwenExtraPropertyStudy_Update(itemIdx)
	
	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then

		if m_UIType == UI_TYPE_ATTRSTUDY_HP then
		
			if PlayerPackage:IsBagItemLW( itemIdx ) ~= 1 then
				PushDebugMessage("#{LW_KVK_110704_07}") -- 此处只能放入龙纹。
				return
			end
			
			local nId = PlayerPackage:GetBagLWData(itemIdx, "HP")
			if nId ~= nil and nId > 0 then
				PushDebugMessage("#{LW_KVK_110704_27}")				--对不起，当前龙纹已经学习过加血上限的扩展属性，无需再学习。
				return
			end
			
			if m_Equip_Idx ~= -1 then
				LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
			end
			
			LongwenExtraPropertyStudy_Object:SetActionItem(theAction:GetID());
			LifeAbility : Lock_Packet_Item(itemIdx,1);
			m_Equip_Idx = itemIdx
			
		end
	
	else
		LongwenExtraPropertyStudy_Object:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		m_Equip_Idx = -1;
	end
	
	LongwenExtraPropertyStudy_UICheck();
end

function LongwenExtraPropertyStudy_Item_Change(itemIdx)

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then
		
		if m_UIType == UI_TYPE_ATTRSTUDY_HP then
			
			if PlayerPackage:IsBagItemLW( itemIdx ) ~= 1 then
				PushDebugMessage("#{LW_KVK_110704_07}") -- 此处只能放入龙纹。
				return
			end
		
			local nId = PlayerPackage:GetBagLWData(itemIdx, "HP")
			if nId ~= nil and nId > 0 then
				this:Hide()											--隐藏界面
				return
			end
			
			if m_Equip_Idx ~= -1 then
				LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
			end
			
			LongwenExtraPropertyStudy_Object:SetActionItem(theAction:GetID());
			LifeAbility : Lock_Packet_Item(itemIdx,1);
			m_Equip_Idx = itemIdx
			
		end
		
	else
		LongwenExtraPropertyStudy_Object:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		m_Equip_Idx = -1;
	end
	LongwenExtraPropertyStudy_UICheck();
	
end

--Care Obj
function LongwenExtraPropertyStudy_BeginCareObj(obj_id)

	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id);
	this:CareObject(m_ObjCared, 1);
end

--OnOK
function LongwenExtraPropertyStudy_OK_Clicked()
	if m_Equip_Idx == -1 then
		return
	end
	-- 判断是否为安全时间2012.6.8-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end

	if m_UIType == UI_TYPE_ATTRSTUDY_HP then
		
		-- 判断玩家材料是否足够
		
		local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
		
		if selfMoney < m_LearnMoney then
			PushDebugMessage("#{LW_KVK_110704_13}")  --对不起，你身上金钱不足，无法继续进行。
			return
		end
		
		-- 检查绑定情况
		local nBindState = PlayerPackage:GetItemBindStatusByIndex(m_Equip_Idx)
		local isNeedConfirm = 0
		if nBindState ~= 1 then
			for i, tbIndex in ipairs(m_DepleteItemHp) do
				local index, bindState = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(tbIndex))
				if bindState == 1 then
					isNeedConfirm = 1
					break
				end
			end
		end
		
		if isNeedConfirm == 1 then
			PushEvent("UPDATE_LW_BIND_CONFIRM", "#{LW_KVK_110704_85}")
		else
			LongwenExtraPropertyStudy_OK_Clicked_Continue()
		end
		
	end
end

--OnOK
function LongwenExtraPropertyStudy_OK_Clicked_Continue()
	if m_Equip_Idx == -1 then
		return
	end

	if m_UIType == UI_TYPE_ATTRSTUDY_HP then
		
		PlayerPackage:Lw_Op_Do(TYPE_ATTRSTUDY_HP, m_Equip_Idx)
		
		-- 升级龙纹仍然保留在窗口内
		local tEquip_Idx = m_Equip_Idx
		local theAction = EnumAction(tEquip_Idx, "packageitem")
		if theAction:GetID() ~= 0 then
			LongwenExtraPropertyStudy_Object:SetActionItem(theAction:GetID());
			LifeAbility : Lock_Packet_Item(tEquip_Idx,1);
			m_Equip_Idx = tEquip_Idx
		else
			LongwenExtraPropertyStudy_Object:SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
			m_Equip_Idx = -1
		end
	end
end


--Right button clicked
function LongwenExtraPropertyStudy_Resume_Equip()
	LongwenExtraPropertyStudy_Update(-1)
end


function LongwenExtraPropertyStudy_UICheck()
	LongwenExtraPropertyStudy_SelfMoney:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	LongwenExtraPropertyStudy_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	LongwenExtraPropertyStudy_NeedMoney : SetProperty("MoneyNumber", 0)
	LongwenExtraPropertyStudy_OK:Disable()
	LongwenExtraPropertyStudy_Info:SetText("")

	--local str = string.format("#{LW_KVK_XML_18}%s#{LW_KVK_XML_39}#{LW_KVK_XML_41}", tostring(m_DepleteItemNum))		--消耗缀龙石·元x个

	if m_UIType == UI_TYPE_ATTRSTUDY_HP then
		LongwenExtraPropertyStudy_Info:SetText("#{LW_KVK_XML_18}")
	end
	
	if m_Equip_Idx ~= -1 then
		
		if m_UIType == UI_TYPE_ATTRSTUDY_HP then
			LongwenExtraPropertyStudy_NeedMoney : SetProperty("MoneyNumber", m_LearnMoney)
		end
		
		LongwenExtraPropertyStudy_OK:Enable()
	else
		LongwenExtraPropertyStudy_CleanUp()
	end
end

--CleanUp
function LongwenExtraPropertyStudy_CleanUp()
end

--close & cancel
function LongwenExtraPropertyStudy_Close()
	this:Hide()
end

function LongwenExtraPropertyStudy_Cancel_Clicked()
	this:Hide()
end

--handle Hide Event
function LongwenExtraPropertyStudy_Frame_OnHiden()
	LongwenExtraPropertyStudy_Update(-1)
	LongwenExtraPropertyStudy_Item_Change(-1)
end


