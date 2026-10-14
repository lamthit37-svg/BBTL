-- 扩展属性学习界面

local m_UI_NUM = 20110729
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
local m_select = -1
--local m_DefaultHight = 400	--默认高度
--local m_FrameHight = 460	--窗口高度

--龙纹三个扩展属性的索引号起始
local m_LearnMoney			= 10000						--学习花费的金钱固定
local m_DepleteItemNum		= 10						--缀龙石·元、暴、护的个数
local m_DepleteItemHp		= { 20310181, 20310189 }	--缀龙石·元
local m_DepleteItemResist	= { 20310182, 20310190 }	--缀龙石·暴
local m_DepleteItemBuff		= { 20310183, 20310191 }	--缀龙石·护

local m_ResistIdSection =	{							--取值区间，用于减抗学习判定
								{MinId = 21, MaxId = 30},				--冰
								{MinId = 31, MaxId = 40},				--火
								{MinId = 41, MaxId = 50},				--玄
								{MinId = 51, MaxId = 60},				--毒
							}
local m_BuffIdSection =	{							--取值区间
								{MinId = 11, MaxId = 20},				--冰
								{MinId = 61, MaxId = 70},				--火
								{MinId = 71, MaxId = 80},				--玄
								{MinId = 81, MaxId = 90},				--毒
							}

local m_AttrExList = {}


--PreLoad-LongwenExtraPropertyStudy2.lua
function LongwenExtraPropertyStudy2_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_LW_ATTRSTUDY")
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("AFTER_UPDATE_LW_BIND_CONFIRM")
end

--OnLoad
function LongwenExtraPropertyStudy2_OnLoad()
	m_AttrExList[1] = LongwenExtraPropertyStudy2_Property1			--冰
	m_AttrExList[2] = LongwenExtraPropertyStudy2_Property3			--火
	m_AttrExList[3] = LongwenExtraPropertyStudy2_Property2			--玄
	m_AttrExList[4] = LongwenExtraPropertyStudy2_Property4			--毒
end

--OnEvent
function LongwenExtraPropertyStudy2_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == m_UI_NUM) then
		
		if CheckPhoneMibaoAndMinorPassword() ~= 1 then			--判断电话密保和二级密码保护
			return
		end
		
		LongwenExtraPropertyStudy2_BeginCareObj( Get_XParam_INT(0) );
		m_UIType = Get_XParam_INT(1)
		
		if m_UIType == UI_TYPE_ATTRSTUDY_RESIST or m_UIType == UI_TYPE_ATTRSTUDY_BUFF then
			LongwenExtraPropertyStudy2_Update(-1)
			LongwenExtraPropertyStudy2_Item_Change(-1)
			LongwenExtraPropertyStudy2_UICheck()
			this:Show();
		end

	elseif (event == "UPDATE_LW_ATTRSTUDY" and this:IsVisible() ) then
		if m_UIType == UI_TYPE_ATTRSTUDY_RESIST or m_UIType == UI_TYPE_ATTRSTUDY_BUFF then
			
			if CheckPhoneMibaoAndMinorPassword() ~= 1 then			--判断电话密保和二级密码保护
				return
			end
			
			if arg0 ~= nil then
				LongwenExtraPropertyStudy2_Update( tonumber(arg0) )
			end
		end
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		LongwenExtraPropertyStudy2_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));

	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		LongwenExtraPropertyStudy2_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))

	elseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil and tonumber(arg0) == m_Equip_Idx then
			LongwenExtraPropertyStudy2_Item_Change(m_Equip_Idx)
		end
		
	elseif (event == "AFTER_UPDATE_LW_BIND_CONFIRM" and this:IsVisible()) then
		LongwenExtraPropertyStudy2_OK_Clicked_Continue()
		
	end
end

--Update UI
function LongwenExtraPropertyStudy2_Update(itemIdx)
	
	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then

		if m_UIType == UI_TYPE_ATTRSTUDY_RESIST or m_UIType == UI_TYPE_ATTRSTUDY_BUFF then

			if PlayerPackage:IsBagItemLW( itemIdx ) ~= 1 then
				PushDebugMessage("#{LW_KVK_110704_07}") -- 此处只能放入龙纹。
				return
			end
		end
		
		if m_Equip_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		end

		LongwenExtraPropertyStudy2_Object:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Equip_Idx = itemIdx

	else
		LongwenExtraPropertyStudy2_Object:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		m_Equip_Idx = -1;
	end
	
	LongwenExtraPropertyStudy2_UICheck();
end


function LongwenExtraPropertyStudy2_Item_Change(itemIdx)

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then
		
		if m_UIType == UI_TYPE_ATTRSTUDY_RESIST or m_UIType == UI_TYPE_ATTRSTUDY_BUFF then
			
			if PlayerPackage:IsBagItemLW( itemIdx ) ~= 1 then
				PushDebugMessage("#{LW_KVK_110704_07}") -- 此处只能放入龙纹。
				return
			end
			
			if m_UIType == UI_TYPE_ATTRSTUDY_RESIST then
				local nId = PlayerPackage:GetBagLWData(itemIdx, "RESIST")
				if nId ~= nil and nId > 0 then
					this:Hide()											--隐藏界面
					return
				end
				
			elseif m_UIType == UI_TYPE_ATTRSTUDY_BUFF then
				local nId = PlayerPackage:GetBagLWData(itemIdx, "BUFF")
				if nId ~= nil and nId > 0 then
					this:Hide()											--隐藏界面
					return
				end
			end
			
		end
		
		if m_Equip_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		end
		
		LongwenExtraPropertyStudy2_Object:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Equip_Idx = itemIdx
		
	else
		LongwenExtraPropertyStudy2_Object:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		m_Equip_Idx = -1;
	end
	LongwenExtraPropertyStudy2_UICheck();

end

--Select 1 Attr
function LongwenExtraPropertyStudy2_Select_AttrEx(idx)
	m_select = idx
	LongwenExtraPropertyStudy2_UICheck()
end

--Care Obj
function LongwenExtraPropertyStudy2_BeginCareObj(obj_id)

	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id);
	this:CareObject(m_ObjCared, 1);
end

--OnOK
function LongwenExtraPropertyStudy2_OK_Clicked()
	if m_Equip_Idx == -1 then
		return
	end
	-- 判断是否为安全时间2012.6.8-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	
	if m_UIType == UI_TYPE_ATTRSTUDY_RESIST or m_UIType == UI_TYPE_ATTRSTUDY_BUFF then
		
		if m_UIType == UI_TYPE_ATTRSTUDY_RESIST then
			--判断是否已学习对应的减抗
			local nSelfType = PlayerPackage:GetBagLWData(m_Equip_Idx, "RESIST")
			
			if nSelfType ~= nil then
				if nSelfType >= m_ResistIdSection[m_select].MinId and nSelfType <= m_ResistIdSection[m_select].MaxId then
					PushDebugMessage("#{LW_KVK_110704_30}")		--对不起，当前龙纹与您所选择的减抗下限的扩展属性一致，无需再学习。
					return
				else
					--判断,如果已经学习过对应抗性,要修改为新的抗性,则需要做加锁判断2012.6.8-LIUBO
					if PlayerPackage:IsLock(m_Equip_Idx) == 1 then
						PushDebugMessage("#{AQSJ_120608_12}")	-- 物品已加锁，无法进行此操作。
						return
					end
				end
			end
			
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
				for i, tbIndex in ipairs(m_DepleteItemResist) do
					local index, bindState = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(tbIndex))
					if bindState == 1 then
						isNeedConfirm = 1
						break
					end
				end
			end
			
			if isNeedConfirm == 1 then
				PushEvent("UPDATE_LW_BIND_CONFIRM", "#{LW_KVK_110704_86}")
			else
				LongwenExtraPropertyStudy2_OK_Clicked_Continue()
			end
			
		elseif m_UIType == UI_TYPE_ATTRSTUDY_BUFF then
			
			--判断是否已学习对应的BUFF
			local nSelfType = PlayerPackage:GetBagLWData(m_Equip_Idx, "BUFF")
			
			if nSelfType ~= nil then
				if nSelfType >= m_BuffIdSection[m_select].MinId and nSelfType <= m_BuffIdSection[m_select].MaxId then
					PushDebugMessage("#{LW_KVK_110704_33}")		--对不起，当前龙纹与您所选择的减抗下限的扩展属性一致，无需再学习。
					return
				else
					--判断,如果已经学习过对应抗性,要修改为新的抗性,则需要做加锁判断2012.6.8-LIUBO
					if PlayerPackage:IsLock(m_Equip_Idx) == 1 then
						PushDebugMessage("#{AQSJ_120608_12}")	-- 物品已加锁，无法进行此操作。
						return
					end
				end
			end

			
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
				for i, tbIndex in ipairs(m_DepleteItemBuff) do
					local index, bindState = PlayerPackage:FindFirstBindedItemIdxByIDTable(tonumber(tbIndex))
					if bindState == 1 then
						isNeedConfirm = 1
						break
					end
				end
			end
			
			if isNeedConfirm == 1 then
				PushEvent("UPDATE_LW_BIND_CONFIRM", "#{LW_KVK_110704_87}")
			else
				LongwenExtraPropertyStudy2_OK_Clicked_Continue()
			end
			
		end
		
	end
end

--OnOK
function LongwenExtraPropertyStudy2_OK_Clicked_Continue()
	if m_Equip_Idx == -1 then
		return
	end

	if m_UIType == UI_TYPE_ATTRSTUDY_RESIST or m_UIType == UI_TYPE_ATTRSTUDY_BUFF then
		
		if m_UIType == UI_TYPE_ATTRSTUDY_RESIST then
			
			PlayerPackage:Lw_Op_Do(TYPE_ATTRSTUDY_RESIST, m_Equip_Idx, m_select)
			
		elseif m_UIType == UI_TYPE_ATTRSTUDY_BUFF then
			
			PlayerPackage:Lw_Op_Do(TYPE_ATTRSTUDY_BUFF, m_Equip_Idx, m_select)
			
		end
		
		-- 升级龙纹仍然保留在窗口内
		local tEquip_Idx = m_Equip_Idx
		local theAction = EnumAction(tEquip_Idx, "packageitem")
		if theAction:GetID() ~= 0 then
			LongwenExtraPropertyStudy2_Object:SetActionItem(theAction:GetID());
			LifeAbility : Lock_Packet_Item(tEquip_Idx,1);
			m_Equip_Idx = tEquip_Idx
		else
			LongwenExtraPropertyStudy2_Object:SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
			m_Equip_Idx = -1
		end
		
	end
end


--Right button clicked
function LongwenExtraPropertyStudy2_Resume_Equip()
	LongwenExtraPropertyStudy2_Update(-1)
end


function LongwenExtraPropertyStudy2_UICheck()
	LongwenExtraPropertyStudy2_SelfMoney:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	LongwenExtraPropertyStudy2_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	LongwenExtraPropertyStudy2_NeedMoney : SetProperty("MoneyNumber", 0)
	LongwenExtraPropertyStudy2_OK:Disable()
	LongwenExtraPropertyStudy2_Info:SetText("")
	--LongwenExtraPropertyStudy2_Frame:SetProperty("AbsoluteHeight", m_DefaultHight)

	for i = 1 , 4 do
		m_AttrExList[i]:SetCheck(0)
	end

	--local str1 = string.format("#{LW_KVK_XML_20}%s#{LW_KVK_XML_39}#{LW_KVK_XML_41}#{LW_KVK_XML_42}", tostring(m_DepleteItemNum))
	--local str2 = string.format("#{LW_KVK_XML_25}%s#{LW_KVK_XML_39}#{LW_KVK_XML_41}#{LW_KVK_XML_51}", tostring(m_DepleteItemNum))		--消耗缀龙石·护x个

	if m_UIType == UI_TYPE_ATTRSTUDY_RESIST then
		LongwenExtraPropertyStudy2_Property1:SetText("#{LW_KVK_XML_21}")
		LongwenExtraPropertyStudy2_Property2:SetText("#{LW_KVK_XML_22}")
		LongwenExtraPropertyStudy2_Property3:SetText("#{LW_KVK_XML_23}")
		LongwenExtraPropertyStudy2_Property4:SetText("#{LW_KVK_XML_24}")
		--LongwenExtraPropertyStudy2_Frame:SetProperty("AbsoluteHeight", m_FrameHight)
		LongwenExtraPropertyStudy2_Info:SetText("#{LW_KVK_XML_20}")
	elseif m_UIType == UI_TYPE_ATTRSTUDY_BUFF then
		LongwenExtraPropertyStudy2_Property1:SetText("#{LW_KVK_XML_52}")
		LongwenExtraPropertyStudy2_Property2:SetText("#{LW_KVK_XML_53}")
		LongwenExtraPropertyStudy2_Property3:SetText("#{LW_KVK_XML_54}")
		LongwenExtraPropertyStudy2_Property4:SetText("#{LW_KVK_XML_55}")
		--LongwenExtraPropertyStudy2_Frame:SetProperty("AbsoluteHeight", m_FrameHight)
		LongwenExtraPropertyStudy2_Info:SetText("#{LW_KVK_XML_25}")
	end
	
	if m_Equip_Idx ~= -1 then
		
		if m_select < 1 or m_select > 4 then
			return
		end
		
		m_AttrExList[m_select]:SetCheck(1)
		
		if m_UIType == UI_TYPE_ATTRSTUDY_RESIST or m_UIType == UI_TYPE_ATTRSTUDY_BUFF then
			LongwenExtraPropertyStudy2_NeedMoney : SetProperty("MoneyNumber", m_LearnMoney)
		end
		
		LongwenExtraPropertyStudy2_OK:Enable()
	else
		m_select = -1
	end
end

--CleanUp
function LongwenExtraPropertyStudy2_CleanUp()
end

--close & cancel
function LongwenExtraPropertyStudy2_Close()
	this:Hide()
end

function LongwenExtraPropertyStudy2_Cancel_Clicked()
	this:Hide()
end

--handle Hide Event
function LongwenExtraPropertyStudy2_Frame_OnHiden()
	LongwenExtraPropertyStudy2_Update(-1)
	LongwenExtraPropertyStudy2_Item_Change(-1)
end

