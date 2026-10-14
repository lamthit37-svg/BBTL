-- 龙纹提升星级界面

local m_UI_NUM = 20110726
local m_ObjCared = -1
local m_Equip_Idx = -1

local UI_TYPE_STARUP	= 1 --在三个势力城市提星级
local UI_TYPE_STARUP_FENGYANG	= 2 --在凤阳镇提星级

local TYPE_COMPOUND		= 1
local TYPE_STARUP		= 2
local TYPE_PRORESET		= 3

local m_UIType = 0
local m_needMoney = 0
local m_needConfirm = 1
local m_IsReady = 0

local m_Money_COMPOUND = 10000			--合成花费固定为1J

--提升星级所需要的材料1和材料2的id和数量
local m_StuffId1 = -1
local m_StuffId2 = -1
local m_StuffNum1 = -1
local m_StuffNum2 = -1
local m_StuffName1 = ""
local m_StuffName2 = ""
local m_str1 = "#{LW_KVK_XML_12}"		--当前龙纹提升星级需要：
local m_str2 = "#{LW_KVK_XML_39}"		--个
local m_str3 = "#{LW_KVK_XML_40}"		--，
local m_str4 = "#{LW_KVK_XML_41}"		--。

--不同星级所需要的材料
local m_StarUpStuff = {
	[1] = { 20310176, 20310185 },
	[2] = { 20310176, 20310185 },
	[3] = { 20310176, 20310185 },
	[4] = { 20310176, 20310185 },
	[5] = { 20310176, 20310185, 20310177, 20310186, 20310178, 20310187, 20310179, 20310188 },--,初中高级可以用
	[6] = { 20310176, 20310185, 20310178, 20310187, 20310179, 20310188 },--,中高级可用
	[7] = { 20310176, 20310185, 20310179, 20310188 },--,高级可用
	[8] = { 20310176, 20310185, 20310196, 20310197 },	-- 幻色可用
	[9]	= { 20310196, 20310197, },
}



--PreLoad
function LongwenStarUp_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_LW_STARUP")
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false);
	this:RegisterEvent("AFTER_UPDATE_LW_BIND_CONFIRM")
end

--OnLoad
function LongwenStarUp_OnLoad()
end

--OnEvent
function LongwenStarUp_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == m_UI_NUM) then

		if CheckPhoneMibaoAndMinorPassword() ~= 1 then			--判断电话密保和二级密码保护
			return
		end

		LongwenStarUp_BeginCareObj( Get_XParam_INT(0) );
		m_UIType = Get_XParam_INT(1)

		LongwenStarUp_Update(-1)
		LongwenStarUp_UICheck()
		this:Show();

	elseif (event == "UPDATE_LW_STARUP" and this:IsVisible() ) then
		if m_UIType == UI_TYPE_STARUP or m_UIType == UI_TYPE_STARUP_FENGYANG then

			if CheckPhoneMibaoAndMinorPassword() ~= 1 then			--判断电话密保和二级密码保护
				return
			end

			if arg0 ~= nil then
				LongwenStarUp_Update( tonumber(arg0) )
			end
		end
	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		LongwenStarUp_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));

	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		LongwenStarUp_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))

	elseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if arg0 ~= nil and tonumber(arg0) == m_Equip_Idx then
			LongwenStarUp_Item_Change(m_Equip_Idx)
		end

	elseif (event == "AFTER_UPDATE_LW_BIND_CONFIRM" and this:IsVisible()) then
		LongwenStarUp_OK_Clicked_Continue()
		
	end
end

--Update UI
function LongwenStarUp_Update(itemIdx)

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then

		if m_UIType == UI_TYPE_STARUP then

			if PlayerPackage:IsBagItemLW( itemIdx ) ~= 1 then
				PushDebugMessage("#{LW_KVK_110704_07}") -- 此处只能放入龙纹。
				return
			end

			local main_lv = PlayerPackage:GetBagLWData(itemIdx, "STAR")

			if  main_lv ~= nil and main_lv >= 9 then
				PushDebugMessage("#{LW_KVK_110704_58}")  --该龙纹已达到最高星级9星，不能继续提升。
				return
			end
		end

		if m_UIType == UI_TYPE_STARUP_FENGYANG then

			if PlayerPackage:IsBagItemLW( itemIdx ) ~= 1 then
				PushDebugMessage("#{LW_KVK_110704_07}") -- 此处只能放入龙纹。
				return
			end

			local main_lv = PlayerPackage:GetBagLWData(itemIdx, "STAR")

			if  main_lv ~= nil and main_lv >= 9 then
				PushDebugMessage("#{LW_KVK_110704_58}")  --该龙纹已达到最高星级9星，不能继续提升。
				return
			end
		end

		if m_Equip_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		end

		LongwenStarUp_Object:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Equip_Idx = itemIdx

	else
		LongwenStarUp_Object:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		m_Equip_Idx = -1;
	end

	LongwenStarUp_UICheck();
end

--Item_Change
function LongwenStarUp_Item_Change(itemIdx)

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then

		if m_UIType == UI_TYPE_STARUP or m_UIType == UI_TYPE_STARUP_FENGYANG then

			if PlayerPackage:IsBagItemLW( itemIdx ) ~= 1 then
				PushDebugMessage("#{LW_KVK_110704_07}") -- 此处只能放入龙纹。
				return
			end

--			this:Hide()
--			return

		end

	else
		LongwenStarUp_Object:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		m_Equip_Idx = -1;
	end

	LongwenStarUp_UICheck();
end

--Care Obj
function LongwenStarUp_BeginCareObj(obj_id)

	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id);
	this:CareObject(m_ObjCared, 1);
end

--OnOK
function LongwenStarUp_OK_Clicked()
	if m_Equip_Idx == -1 then
		return
	end
	
	if m_UIType == UI_TYPE_STARUP or m_UIType == UI_TYPE_STARUP_FENGYANG then

		local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")

		if m_needMoney ~= nil and m_needMoney > 0 and selfMoney < m_needMoney then
			PushDebugMessage("#{LW_KVK_110704_13}")  --对不起，你身上金钱不足，无法继续进行。
			return
		end

		-- 检查绑定情况
		local nLevel = PlayerPackage:GetBagLWData(m_Equip_Idx, "STAR")
		local nBindState = PlayerPackage:GetItemBindStatusByIndex(m_Equip_Idx)
		--实在是太太太太太麻烦了,这种提示方法，某部位疼到不行了啊!!
		local isNeedConfirm = 0 --是否绑定确认
		local isHaveUseTips = 0 --是否有各个等级苟天才的消耗数量提示

		local nCount_Have_Diji_bind = 0--持有低级材料数
		local nCount_Have_Diji = 0--持有低级材料数
		local nCount_Have_zhongJI_bind = 0--持有中级材料数
		local nCount_Have_zhongJI = 0--持有中级材料数
		local nCount_Have_gaoJI_bind = 0--持有高级级材料数
		local nCount_Have_gaoJI = 0--持有高级级材料数
		local nCount_Have_HuanSe_bind = 0;	-- 持有幻色勾天彩数
		local nCount_Have_HuanSe = 0;		-- 持有幻色勾天彩数
		local nCount_Need = PlayerPackage:GetBagLWStarUpInfo(m_Equip_Idx, "STUFFNUM2") --升星需要苟天才数量
		local nCount_YLS = PlayerPackage:GetBagLWStarUpInfo(m_Equip_Idx, "STUFFNUM1") --需要玉龙随数量

		--最后使用的各个等级苟天才的数量
		local nCount_Use_Diji = 0
		local nCount_Use_Zhongji = 0
		local nCount_Use_Gaoji = 0


		--玉龙随的数量
		local nCount_Have_YuLongSui_bind = PlayerPackage:CountAvailableItemByIDTable(20310176)
		local nCount_Have_YuLongSui = PlayerPackage:CountAvailableItemByIDTable(20310185)

		if nCount_Have_YuLongSui_bind + nCount_Have_YuLongSui < nCount_YLS then
			PushDebugMessage("#{LW_KVK_110704_21}")
			return
		end

		if nLevel >= 5 then
			nCount_Have_Diji_bind = PlayerPackage:CountAvailableItemByIDTable(20310177)		-- 初级勾天彩
			nCount_Have_Diji = PlayerPackage:CountAvailableItemByIDTable(20310186)			-- 初级勾天彩
			nCount_Have_zhongJI_bind = PlayerPackage:CountAvailableItemByIDTable(20310178)	-- 中级勾天彩
			nCount_Have_zhongJI = PlayerPackage:CountAvailableItemByIDTable(20310187)		-- 中级勾天彩
			nCount_Have_gaoJI_bind = PlayerPackage:CountAvailableItemByIDTable(20310179)	-- 高级勾天彩
			nCount_Have_gaoJI = PlayerPackage:CountAvailableItemByIDTable(20310188)			-- 高级勾天彩
			nCount_Have_HuanSe_bind = PlayerPackage:CountAvailableItemByIDTable(20310196)	-- 幻色勾天彩
			nCount_Have_HuanSe = PlayerPackage:CountAvailableItemByIDTable(20310197)		-- 幻色勾天彩


			local nHave = 0
			if nLevel == 5 then
				nHave = nCount_Have_Diji_bind + nCount_Have_Diji + nCount_Have_zhongJI_bind + nCount_Have_zhongJI + nCount_Have_gaoJI_bind + nCount_Have_gaoJI
			end

			if nLevel == 6 then
				nHave = nCount_Have_zhongJI_bind + nCount_Have_zhongJI + nCount_Have_gaoJI_bind + nCount_Have_gaoJI
			end

			if nLevel == 7 then
				nHave = nCount_Have_gaoJI_bind + nCount_Have_gaoJI
			end

			if nLevel == 8 then
				nHave = nCount_Have_HuanSe_bind + nCount_Have_HuanSe
			end

			if nHave < nCount_Need then
				PushDebugMessage("#{LW_KVK_110704_21}")
				return
			end
		end


		if nBindState ~= 1 and m_StarUpStuff[nLevel] ~= nil then
			if nCount_Have_YuLongSui_bind > 0 then
				isNeedConfirm = 1
			end

			if isNeedConfirm == 0 then
				if nLevel == 5 then  -- 5-->6
					if nCount_Have_Diji_bind > 0 then
						isNeedConfirm = 1
					elseif nCount_Have_Diji < nCount_Need then--初级绑定的为0个，并且初级诽谤小于需要的数量
						local nRemian = nCount_Need - nCount_Have_Diji
						if nCount_Have_zhongJI_bind > 0 then --中级绑定大于0
							isNeedConfirm = 1
						elseif nCount_Have_zhongJI < nRemian then--中级绑定为0，并且中级诽谤数量小于需要的数量
							if nCount_Have_gaoJI_bind > 0 then --高级绑定数量大于0
								isNeedConfirm = 1
							end
						end
					end
				end

				if nLevel == 6 then ---6--->7
					if nCount_Have_zhongJI_bind > 0 then --中级绑定大于0
						isNeedConfirm = 1
					elseif nCount_Have_zhongJI < nCount_Need then --中级绑定的为0个，并且中级诽谤小于需要的数量
						if nCount_Have_gaoJI_bind > 0 then
							isNeedConfirm = 1
						end
					end
				end

				if nLevel == 7 then   ----7--->8
					if nCount_Have_gaoJI_bind > 0 then
						isNeedConfirm = 1
					end
				end

				if nLevel == 8 then	---8---->9
					-- 当玩家放入的龙纹为8星龙纹时，点击“确定”按钮时增加8星提升9星所需材料的计算操作；
					if nCount_Have_HuanSe_bind > 0 then
						isNeedConfirm = 1
					end
				end
			end
		end

		--为了提示计算最后使用的各个苟天才的数量
		local nCount_Remain = 0
		local tmptmp = nCount_Have_Diji_bind + nCount_Have_Diji
		if nLevel == 5 then
			if tmptmp >= nCount_Need then
				nCount_Use_Diji = nCount_Need
				nCount_Remain = 0
			else
				nCount_Use_Diji = tmptmp
				nCount_Remain = nCount_Need - nCount_Use_Diji
			end

			if nCount_Remain > 0 then
				tmptmp = nCount_Have_zhongJI_bind + nCount_Have_zhongJI
				if tmptmp >= nCount_Remain then
					nCount_Use_Zhongji = nCount_Remain
					nCount_Remain = 0
				else
					nCount_Use_Zhongji = tmptmp
					nCount_Remain = nCount_Remain - tmptmp
				end
			end

			if nCount_Remain > 0 then
				tmptmp = nCount_Have_gaoJI_bind + nCount_Have_gaoJI
				if tmptmp >= nCount_Remain then
					nCount_Use_Gaoji = nCount_Remain
					nCount_Remain = 0
				else
					nCount_Remain = nCount_Remain - tmptmp
				end
			end

			if nCount_Use_Zhongji > 0 or nCount_Use_Gaoji > 0 then --如果有消耗中高级
				isHaveUseTips = 1
			end
		end

		if nLevel == 6 then
			tmptmp = nCount_Have_zhongJI_bind + nCount_Have_zhongJI
			if tmptmp >= nCount_Need then
				nCount_Use_Zhongji = nCount_Need
				nCount_Remain = 0
			else
				nCount_Use_Zhongji = tmptmp
				nCount_Remain = nCount_Need - tmptmp
			end

			if nCount_Remain > 0 then
				tmptmp = nCount_Have_gaoJI_bind + nCount_Have_gaoJI
				if tmptmp >= nCount_Remain then
					nCount_Use_Gaoji = nCount_Remain
					nCount_Remain = 0
				else
					nCount_Remain = nCount_Remain - tmptmp
				end
			end

			if nCount_Use_Gaoji > 0 then --如果有消耗高级
				isHaveUseTips = 1
			end
		end

		if nCount_Remain > 0 then
			return --bug
		end

		local strtips = "#{LW_KVK_110704_84}"
		if nLevel == 5 then
			if isHaveUseTips == 1 then
				if isNeedConfirm == 1 then
					strtips = ScriptGlobal_Format("#{LW_KVK_110704_93}", tostring(nCount_Use_Diji), tostring(nCount_Use_Zhongji), tostring(nCount_Use_Gaoji))
				else
					strtips = ScriptGlobal_Format("#{LW_KVK_110704_91}", tostring(nCount_Use_Diji), tostring(nCount_Use_Zhongji), tostring(nCount_Use_Gaoji))
				end
			end
		elseif nLevel == 6 then
			if isHaveUseTips == 1 then
				if isNeedConfirm == 1 then
					strtips = ScriptGlobal_Format("#{LW_KVK_110704_94}", tostring(nCount_Use_Zhongji), tostring(nCount_Use_Gaoji))
				else
					strtips = ScriptGlobal_Format("#{LW_KVK_110704_92}", tostring(nCount_Use_Zhongji), tostring(nCount_Use_Gaoji))
				end
			end
		end
		if isNeedConfirm == 1 or isHaveUseTips == 1 then
			PushEvent("UPDATE_LW_BIND_CONFIRM", strtips)
		else
			LongwenStarUp_OK_Clicked_Continue()
		end
		
	end
end

--OnOK
function LongwenStarUp_OK_Clicked_Continue()
	if m_Equip_Idx == -1 then
		return
	end

	if m_UIType == UI_TYPE_STARUP or m_UIType == UI_TYPE_STARUP_FENGYANG then
		
		PlayerPackage:Lw_Op_Do(TYPE_STARUP, m_Equip_Idx)

		-- 升级龙纹仍然保留在窗口内
		local tEquip_Idx = m_Equip_Idx
		local theAction = EnumAction(tEquip_Idx, "packageitem")
		if theAction:GetID() ~= 0 then
			LongwenStarUp_Object:SetActionItem(theAction:GetID());
			LifeAbility : Lock_Packet_Item(tEquip_Idx,1);
			m_Equip_Idx = tEquip_Idx
		else
			LongwenStarUp_Object:SetActionItem(-1);
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
			m_Equip_Idx = -1
		end

	end
end


--Right button clicked
function LongwenStarUp_Resume_Equip()
	LongwenStarUp_Update(-1)
end


function LongwenStarUp_UICheck()
	LongwenStarUp_SelfMoney:SetProperty("MoneyNumber", Player:GetData("MONEY"))
	LongwenStarUp_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))
	LongwenStarUp_NeedMoney : SetProperty("MoneyNumber", 0)
	LongwenStarUp_OK:Disable()
	LongwenStarUp_Text2:SetText("")						-- 成功率

	local str = ""
	m_StuffId1 = -1
	m_StuffId2 = -1
	m_StuffNum1 = -1
	m_StuffNum2 = -1
	m_StuffName1 = ""
	m_StuffName2 = ""
	m_needMoney = 0

	if m_Equip_Idx ~= -1 then

		m_needMoney = PlayerPackage:GetBagLWStarUpInfo(m_Equip_Idx, "MONEY")
		m_StuffId1 = PlayerPackage:GetBagLWStarUpInfo(m_Equip_Idx, "STUFFID1")
		m_StuffId2 = PlayerPackage:GetBagLWStarUpInfo(m_Equip_Idx, "STUFFID2")
		m_StuffNum1 = PlayerPackage:GetBagLWStarUpInfo(m_Equip_Idx, "STUFFNUM1")
		m_StuffNum2 = PlayerPackage:GetBagLWStarUpInfo(m_Equip_Idx, "STUFFNUM2")

		if m_StuffId1 ~= nil and m_StuffId1 > 0 then
			m_StuffName1 = PlayerPackage:GetItemName(m_StuffId1);
		end

		if m_StuffId2 ~= nil and m_StuffId2 > 0 then
			m_StuffName2 = PlayerPackage:GetItemName(m_StuffId2);
		end

		if m_StuffId1 ~= nil and m_StuffId2 ~= nil then
			if m_StuffId1 > 0 and m_StuffId2 > 0 then		--例：当前龙纹提升星级需要：材料A10个，材料B20个。
				str = m_str1 .. m_StuffName1 .. "#cff0000" .. tostring(m_StuffNum1) .. m_str2 .. m_str3 .. m_StuffName2 .. "#cff0000" .. tostring(m_StuffNum2) .. m_str2
			elseif m_StuffId1 <= 0 and m_StuffId2 > 0 then
				str = m_str1 .. m_StuffName2 .. "#cff0000" .. tostring(m_StuffNum2) .. m_str2
			elseif m_StuffId1 > 0 and m_StuffId2 <= 0 then
				str = m_str1 .. m_StuffName1 .. "#cff0000" .. tostring(m_StuffNum1) .. m_str2
			elseif m_StuffId1 <= 0 and m_StuffId2 <= 0 then
				str = ""
			end
		else
			return
		end

		if m_needMoney ~= nil and m_needMoney >= 0 then
			LongwenStarUp_NeedMoney : SetProperty("MoneyNumber", m_needMoney)
		else
			return
		end

		LongwenStarUp_Text2:SetText(str)
		LongwenStarUp_OK:Enable()

	end
end


--close & cancel
function LongwenStarUp_Close()
	this:Hide()
end

function LongwenStarUp_Cancel_Clicked()
	this:Hide()
end

--handle Hide Event
function LongwenStarUp_Frame_OnHiden()
	LongwenStarUp_Update(-1)
end


