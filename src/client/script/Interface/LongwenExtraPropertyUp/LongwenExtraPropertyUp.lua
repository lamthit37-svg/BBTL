-- 龙纹扩展属性升级界面

local m_UI_NUM = 20110730
local m_ObjCared = -1
local m_Equip_Idx = -1

--扩展属性升级的类型
local UI_TYPE_ATTRLEVELUP_HP		= 0		--血上限
local UI_TYPE_ATTRLEVELUP_RESIST	= 1		--冰火玄毒
local UI_TYPE_ATTRLEVELUP_BUFF		= 2		--减伤BUFF

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
local m_UIType = -1
local m_needMoney = 0
local m_needConfirm = 1
local m_DefaultHight = 400	--窗口默认高度
local m_FrameHight = 440	--窗口高度
local m_FrameHight2 = 460

local m_DepleteItemHp		= { 20310181, 20310189 }	--缀龙石·元
local m_DepleteItemResist	= { 20310182, 20310190 }	--缀龙石·暴
local m_DepleteItemBuff		= { 20310183, 20310191 }	--缀龙石·护


--PreLoad-LongwenExtraPropertyUp.lua
function LongwenExtraPropertyUp_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_LW_ATTRLEVELUP")
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("AFTER_UPDATE_LW_BIND_CONFIRM")
end

--OnLoad
function LongwenExtraPropertyUp_OnLoad()
end

--OnEvent
function LongwenExtraPropertyUp_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == m_UI_NUM) then
		
		if CheckPhoneMibaoAndMinorPassword() ~= 1 then			--判断电话密保和二级密码保护
			return
		end
		
		LongwenExtraPropertyUp_BeginCareObj( Get_XParam_INT(0) );
		m_UIType = Get_XParam_INT(1)
		
		LongwenExtraPropertyUp_Update(-1)
		LongwenExtraPropertyUp_Item_Change(-1)
		LongwenExtraPropertyUp_UICheck()
		this:Show();

	elseif (event == "UPDATE_LW_ATTRLEVELUP" and this:IsVisible() ) then
		if m_UIType == UI_TYPE_ATTRLEVELUP_HP then					--血上限升级
			
			if CheckPhoneMibaoAndMinorPassword() ~= 1 then
				return
			end
			
			if arg0 ~= nil then
				LongwenExtraPropertyUp_Update( tonumber(arg0) )
			end
			
		elseif m_UIType == UI_TYPE_ATTRLEVELUP_RESIST then			--减抗下限升级
			
			if CheckPhoneMibaoAndMinorPassword() ~= 1 then
				return
			end
			
			if arg0 ~= nil then
				LongwenExtraPropertyUp_Update( tonumber(arg0) )
			end
			
		elseif m_UIType == UI_TYPE_ATTRLEVELUP_BUFF then			--减伤BUFF升级
			
			if CheckPhoneMibaoAndMinorPassword() ~= 1 then
				return
			end
			
			if arg0 ~= nil then
				LongwenExtraPropertyUp_Update( tonumber(arg0) )
			end
			
		end
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		LongwenExtraPropertyUp_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));

	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		LongwenExtraPropertyUp_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))

	elseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil and tonumber(arg0) == m_Equip_Idx then
			LongwenExtraPropertyUp_Item_Change(m_Equip_Idx)
		end
		
	elseif (event == "AFTER_UPDATE_LW_BIND_CONFIRM" and this:IsVisible()) then
		LongwenExtraPropertyUp_OK_Clicked_Continue()
		
	end
end

--Update UI
function LongwenExtraPropertyUp_Update(itemIdx)
	
	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then
		
		if m_UIType == UI_TYPE_ATTRLEVELUP_HP or m_UIType == UI_TYPE_ATTRLEVELUP_RESIST or m_UIType == UI_TYPE_ATTRLEVELUP_BUFF then

			if PlayerPackage:IsBagItemLW( itemIdx ) ~= 1 then
				PushDebugMessage("#{LW_KVK_110704_07}")				--此处只能放入龙纹。
				return
			end
		end
		
		if m_UIType == UI_TYPE_ATTRLEVELUP_HP then					--血上限升级
			local nId = PlayerPackage:GetBagLWData(itemIdx, "HP")
			if nId ~= nil and nId > 0 then
				local nLevelupId = PlayerPackage:GetBagLWAttrExInfo(itemIdx, nId, "LEVELUPTO")
				if nLevelupId ~= nil and nLevelupId <= 0 then
					PushDebugMessage("#{LW_KVK_110704_36}")			--当前龙纹的加血上限扩展属性已达到最高等级10级，不能继续提升。
					return
				end
			else
				PushDebugMessage("#{LW_KVK_110704_55}")				--尚未学习对应属性，不能升级
				return
			end
			
		elseif m_UIType == UI_TYPE_ATTRLEVELUP_RESIST then			--减抗下限升级
			local nId = PlayerPackage:GetBagLWData(itemIdx, "RESIST")
			if nId ~= nil and nId > 0 then
				local nLevelupId = PlayerPackage:GetBagLWAttrExInfo(itemIdx, nId, "LEVELUPTO")
				if nLevelupId ~= nil and nLevelupId <= 0 then
					PushDebugMessage("#{LW_KVK_110704_38}")			--当前龙纹的减抗下限扩展属性已达到最高等级10级，不能继续提升。
					return
				end
			else
				PushDebugMessage("#{LW_KVK_110704_55}")				--尚未学习对应属性，不能升级
				return
			end
			
		elseif m_UIType == UI_TYPE_ATTRLEVELUP_BUFF then			--减伤BUFF升级
			local nId = PlayerPackage:GetBagLWData(itemIdx, "BUFF")
			if nId ~= nil and nId > 0 then
				local nLevelupId = PlayerPackage:GetBagLWAttrExInfo(itemIdx, nId, "LEVELUPTO")
				if nLevelupId ~= nil and nLevelupId <= 0 then
					PushDebugMessage("#{LW_KVK_110704_40}")			--当前龙纹的减免伤害扩展属性已达到最高等级10级，不能继续提升。
					return
				end
			else
				PushDebugMessage("#{LW_KVK_110704_55}")				--尚未学习对应属性，不能升级
				return
			end
			
		end
		
		if m_Equip_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		end

		LongwenExtraPropertyUp_Object:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Equip_Idx = itemIdx

	else
		LongwenExtraPropertyUp_Object:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		m_Equip_Idx = -1;
	end
	
	LongwenExtraPropertyUp_UICheck();
end


function LongwenExtraPropertyUp_Item_Change(itemIdx)

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then
		
		if m_UIType == UI_TYPE_ATTRLEVELUP_HP or m_UIType == UI_TYPE_ATTRLEVELUP_RESIST or m_UIType == UI_TYPE_ATTRLEVELUP_BUFF then

			if PlayerPackage:IsBagItemLW( itemIdx ) ~= 1 then
				PushDebugMessage("#{LW_KVK_110704_07}")				--此处只能放入龙纹。
				return
			end
		end
		
		if m_UIType == UI_TYPE_ATTRLEVELUP_HP then					--血上限升级
			local nId = PlayerPackage:GetBagLWData(itemIdx, "HP")
			if nId ~= nil and nId > 0 then
			else
				this:Hide()
				return
			end
			
		elseif m_UIType == UI_TYPE_ATTRLEVELUP_RESIST then			--减抗下限升级
			local nId = PlayerPackage:GetBagLWData(itemIdx, "RESIST")
			if nId ~= nil and nId > 0 then
			else
				this:Hide()
				return
			end
			
		elseif m_UIType == UI_TYPE_ATTRLEVELUP_BUFF then			--减伤BUFF升级
			local nId = PlayerPackage:GetBagLWData(itemIdx, "BUFF")
			if nId ~= nil and nId > 0 then
			else
				this:Hide()
				return
			end
			
		end
		
		if m_Equip_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		end
		
		LongwenExtraPropertyUp_Object:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Equip_Idx = itemIdx
		
	else
		LongwenExtraPropertyUp_Object:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		m_Equip_Idx = -1;
	end
	LongwenExtraPropertyUp_UICheck();
	
end

--Care Obj
function LongwenExtraPropertyUp_BeginCareObj(obj_id)

	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id);
	this:CareObject(m_ObjCared, 1);
end

--OnOK 【确认按钮】
function LongwenExtraPropertyUp_OK_Clicked()
	if m_Equip_Idx == -1 then
		return
	end

	if m_UIType == UI_TYPE_ATTRLEVELUP_HP or m_UIType == UI_TYPE_ATTRLEVELUP_RESIST or m_UIType == UI_TYPE_ATTRLEVELUP_BUFF then
		
		-- 判断玩家材料是否足够
		
		local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
		if selfMoney < m_needMoney then
			PushDebugMessage("#{LW_KVK_110704_13}")  --对不起，你身上金钱不足，无法继续进行。
			return
		end
		
		if m_UIType == UI_TYPE_ATTRLEVELUP_HP then
			
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
				PushEvent("UPDATE_LW_BIND_CONFIRM", "#{LW_KVK_110704_88}")
			else
				LongwenExtraPropertyUp_OK_Clicked_Continue()
			end
			
		elseif m_UIType == UI_TYPE_ATTRLEVELUP_RESIST then
			
			-- 检查绑定情况
			local nBindState = PlayerPackage:GetItemBindStatusByIndex(m_Equip_Idx)
			local isNeedConfirm = 0
			if nBindState ~= 1 then
				for i, tbIndex in ipairs(m_DepleteItemResist) do
					local index, bindState = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(tbIndex))
					if bindState == 1 then
						isNeedConfirm = 1
						break
					end
				end
			end
			
			if isNeedConfirm == 1 then
				PushEvent("UPDATE_LW_BIND_CONFIRM", "#{LW_KVK_110704_89}")
			else
				LongwenExtraPropertyUp_OK_Clicked_Continue()
			end
			
		elseif m_UIType == UI_TYPE_ATTRLEVELUP_BUFF then
			
			-- 检查绑定情况
			local nBindState = PlayerPackage:GetItemBindStatusByIndex(m_Equip_Idx)
			local isNeedConfirm = 0
			if nBindState ~= 1 then
				for i, tbIndex in ipairs(m_DepleteItemBuff) do
					local index, bindState = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(tbIndex))
					if bindState == 1 then
						isNeedConfirm = 1
						break
					end
				end
			end
			
			if isNeedConfirm == 1 then
				PushEvent("UPDATE_LW_BIND_CONFIRM", "#{LW_KVK_110704_90}")
			else
				LongwenExtraPropertyUp_OK_Clicked_Continue()
			end
			
		end
		
	end
end

--OnOK
function LongwenExtraPropertyUp_OK_Clicked_Continue()
	if m_Equip_Idx == -1 then
		return
	end

	if m_UIType == UI_TYPE_ATTRLEVELUP_HP or m_UIType == UI_TYPE_ATTRLEVELUP_RESIST or m_UIType == UI_TYPE_ATTRLEVELUP_BUFF then
		
		if m_UIType == UI_TYPE_ATTRLEVELUP_HP then
			PlayerPackage:Lw_Op_Do(TYPE_ATTRLEVELUP_HP, m_Equip_Idx)
		elseif m_UIType == UI_TYPE_ATTRLEVELUP_RESIST then
			PlayerPackage:Lw_Op_Do(TYPE_ATTRLEVELUP_RESIST, m_Equip_Idx)
		elseif m_UIType == UI_TYPE_ATTRLEVELUP_BUFF then
			PlayerPackage:Lw_Op_Do(TYPE_ATTRLEVELUP_BUFF, m_Equip_Idx)
		end

		-- 升级龙纹仍然保留在窗口内
		local tEquip_Idx = m_Equip_Idx
		local theAction = EnumAction(tEquip_Idx, "packageitem")
		if theAction:GetID() ~= 0 then
			LongwenExtraPropertyUp_Object:SetActionItem(theAction:GetID());
			LifeAbility : Lock_Packet_Item(tEquip_Idx,1);
			m_Equip_Idx = tEquip_Idx
		else
			LongwenExtraPropertyUp_Object:SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
			m_Equip_Idx = -1
		end
		
	end
end


--Right button clicked
function LongwenExtraPropertyUp_Resume_Equip()
	LongwenExtraPropertyUp_Update(-1)
end


function LongwenExtraPropertyUp_UICheck()
	LongwenExtraPropertyUp_SelfMoney:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	LongwenExtraPropertyUp_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	LongwenExtraPropertyUp_NeedMoney : SetProperty("MoneyNumber", 0)
	LongwenExtraPropertyUp_OK:Disable()
	LongwenExtraPropertyUp_Text2:SetText("")
	LongwenExtraPropertyUp_Info:SetText("")
	if SystemSetup:IsClassic() == 0 then
		LongwenExtraPropertyUp_Frame:SetProperty("AbsoluteHeight", m_DefaultHight)
	end
	
	if m_UIType == UI_TYPE_ATTRLEVELUP_HP then						--血上限升级
		LongwenExtraPropertyUp_Info:SetText("#{LW_KVK_XML_26}")
	elseif m_UIType == UI_TYPE_ATTRLEVELUP_RESIST then				--减抗下限升级
		if SystemSetup:IsClassic() == 0 then
			LongwenExtraPropertyUp_Frame:SetProperty("AbsoluteHeight", m_FrameHight)
		end
		LongwenExtraPropertyUp_Info:SetText("#{LW_KVK_XML_30}")
	elseif m_UIType == UI_TYPE_ATTRLEVELUP_BUFF then				--减伤BUFF升级
		if SystemSetup:IsClassic() == 0 then
			LongwenExtraPropertyUp_Frame:SetProperty("AbsoluteHeight", m_FrameHight)
		end
		LongwenExtraPropertyUp_Info:SetText("#{LW_KVK_XML_32}")
	end
	
	if m_Equip_Idx ~= -1 then
		
		local needMoney = 0
		local needItemNum = 0
		m_needMoney = 0
		
		if m_UIType == UI_TYPE_ATTRLEVELUP_HP then					--血上限升级
		
			local nId = PlayerPackage:GetBagLWData(m_Equip_Idx, "HP")
			if nId ~= nil and nId > 0 then
				needMoney = PlayerPackage:GetBagLWAttrExInfo(m_Equip_Idx, nId, "LEVELUPMONEY")
				if needMoney ~= nil and needMoney >=0 then
					LongwenExtraPropertyUp_NeedMoney : SetProperty("MoneyNumber", needMoney)
					m_needMoney = needMoney
				end
				
				needItemNum = PlayerPackage:GetBagLWAttrExInfo(m_Equip_Idx, nId, "LEVELUPITEMNUM")
				if needItemNum ~= nil and needItemNum > 0 then
					local str = string.format("#{LW_KVK_XML_27}#cff0000%s#{LW_KVK_XML_39}#{LW_KVK_XML_41}", tostring(needItemNum))
					LongwenExtraPropertyUp_Text2:SetText(str)
				end
			end
			
		elseif m_UIType == UI_TYPE_ATTRLEVELUP_RESIST then			--减抗下限升级
			local nId = PlayerPackage:GetBagLWData(m_Equip_Idx, "RESIST")
			if nId ~= nil and nId > 0 then
				needMoney = PlayerPackage:GetBagLWAttrExInfo(m_Equip_Idx, nId, "LEVELUPMONEY")
				if needMoney ~= nil and needMoney >=0 then
					LongwenExtraPropertyUp_NeedMoney : SetProperty("MoneyNumber", needMoney)
					m_needMoney = needMoney
				end
				
				needItemNum = PlayerPackage:GetBagLWAttrExInfo(m_Equip_Idx, nId, "LEVELUPITEMNUM")
				if needItemNum ~= nil and needItemNum > 0 then
					local str = string.format("#{LW_KVK_XML_31}#cff0000%s#{LW_KVK_XML_39}#{LW_KVK_XML_41}", tostring(needItemNum))
					LongwenExtraPropertyUp_Text2:SetText(str)
				end
			end
			
		elseif m_UIType == UI_TYPE_ATTRLEVELUP_BUFF then			--减伤BUFF升级
			local nId = PlayerPackage:GetBagLWData(m_Equip_Idx, "BUFF")
			if nId ~= nil and nId > 0 then
				needMoney = PlayerPackage:GetBagLWAttrExInfo(m_Equip_Idx, nId, "LEVELUPMONEY")
				if needMoney ~= nil and needMoney >=0 then
					LongwenExtraPropertyUp_NeedMoney : SetProperty("MoneyNumber", needMoney)
					m_needMoney = needMoney
				end
				
				needItemNum = PlayerPackage:GetBagLWAttrExInfo(m_Equip_Idx, nId, "LEVELUPITEMNUM")
				if needItemNum ~= nil and needItemNum > 0 then
					local str = string.format("#{LW_KVK_XML_33}#cff0000%s#{LW_KVK_XML_39}#{LW_KVK_XML_41}", tostring(needItemNum))
					LongwenExtraPropertyUp_Text2:SetText(str)
				end
			end
			
		end
		
		LongwenExtraPropertyUp_OK:Enable()
	end
end

--CleanUp
function LongwenExtraPropertyUp_CleanUp()
end

--close & cancel
function LongwenExtraPropertyUp_Close()
	this:Hide()
end

function LongwenExtraPropertyUp_Cancel_Clicked()
	this:Hide()
end

--handle Hide Event
function LongwenExtraPropertyUp_Frame_OnHiden()
	LongwenExtraPropertyUp_Update(-1)
	LongwenExtraPropertyUp_Item_Change(-1)
end


