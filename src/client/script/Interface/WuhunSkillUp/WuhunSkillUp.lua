--  WuhunSkillUp
local m_UI_NUM = 20090723
local m_ObjCared = -1
local m_Equip_Idx = -1
local m_Equip_Item = -1

local Skills = {}
local skillSelected = -1
local Kfs_Skill_ID = {}


--魂冰石
local g_HunBing = {
		20310117,	--魂冰珠（1级）
		20310118,	--魂冰珠（2级）
		20310119,	--魂冰珠（3级）
		20310120,	--魂冰珠（4级）
		20310121,	--魂冰珠（5级）
		}

--绑定魂冰石
local g_HunBing_Bind = {
		20310161,	--魂冰珠（1级）
		20310162,	--魂冰珠（2级）
		20310163,	--魂冰珠（3级）
		20310164,	--魂冰珠（4级）
		20310165,	--魂冰珠（5级）
		}
		
local g_LevelMax = 6
		
--PreLoad
function WuhunSkillUp_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_KFS_SKILLUP")
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

--OnLoad
function WuhunSkillUp_OnLoad()
	Skills[1] = WuhunSkillUp_Object2
	Skills[2] = WuhunSkillUp_Object3
	Skills[3] = WuhunSkillUp_Object4
end

--OnEvent
function WuhunSkillUp_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == m_UI_NUM) then
		
		WuhunSkillUp_BeginCareObj( Get_XParam_INT(0) );
		
		WuhunSkillUp_Update(-1)
		WuhunSkillUp_Update_Sub(-1)
		this:Show();

	elseif (event == "UPDATE_KFS_SKILLUP" and this:IsVisible() ) then
		
		--if arg0 ~= nil then
			--WuhunSkillUp_Update( tonumber(arg0) )
		--end
		
		if arg1 ~= nil and tonumber(arg1) == 0 and arg0 ~= nil then
			WuhunSkillUp_Update( tonumber(arg0) )
	
		elseif arg1 ~= nil and tonumber(arg1) == 1 and arg0 ~= nil then
			WuhunSkillUp_Update_Sub( tonumber(arg0) )
		end
	
	elseif (event == "MONEY_CHANGE_EX") then
		WuhunSkillUp_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	
	elseif (event == "MONEYJZ_CHANGE_EX") then 
		WuhunSkillUp_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	
	elseif (event == "PACKAGE_ITEM_CHANGED_EX") then
		--WuhunSkillUp_UICheck()
		if arg0 ~= nil and tonumber(arg0) == m_Equip_Idx then
			WuhunSkillUp_Update(m_Equip_Idx)
		elseif  arg0 ~= nil and tonumber(arg0) == m_Equip_Item then
			WuhunSkillUp_Update_Sub(m_Equip_Item)
		end 
	end
end

--Update UI
function WuhunSkillUp_Update(itemIdx)

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then

		if PlayerPackage:IsBagItemKFS( itemIdx ) ~= 1 then
			PushDebugMessage("#{WHYH_161121_33}")	--此处只能放入武魂。
			return
		end

		local nSumSkill = PlayerPackage:GetBagKfsSkillNum(itemIdx)
		if nSumSkill ~= nil and nSumSkill <= 0 then
			if m_Equip_Idx == itemIdx then
				WuhunSkillUp_Object1:SetActionItem(-1);			
				LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);		
				m_Equip_Idx = -1;
				return
			end
			PushDebugMessage("#{WHYH_161121_61}")	--当前武魂没有领悟技能，请先领悟技能再进行技能升级操作
			return
		end

		if m_Equip_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
			WuhunSkillUp_Update_Sub(-1)--清空材料
		end

		WuhunSkillUp_Object1:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Equip_Idx = itemIdx
	else
		WuhunSkillUp_Object1:SetActionItem(-1);			
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);		
		m_Equip_Idx = -1;
		WuhunSkillUp_Update_Sub(-1)--清空材料
	end
	WuhunSkillUp_UICheck()
end

--Update UI
function WuhunSkillUp_Update_Sub(itemIdx)
	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then
		
		-- 该界面是否已置入武魂
		if m_Equip_Idx == -1 then
			PushDebugMessage("#{WHYH_161121_63}")
			return
		end
		if PlayerPackage:IsBagItemKFS( m_Equip_Idx ) ~= 1 then
			PushDebugMessage("#{WHYH_161121_63}")
			return
		end
		
		-- 当前武魂是否拥有技能
		local nSumSkill = PlayerPackage:GetBagKfsSkillNum(m_Equip_Idx)
		if nSumSkill == nil or nSumSkill <= 0 then
			PushDebugMessage("#{WHYH_161121_64}")	--当前武魂没有领悟技能，请先领悟技能再进行技能升级操作
			return
		end
		
		-- 是否已选中任一希望升级的技能
		if skillSelected == -1 then
			PushDebugMessage("#{WHYH_161121_65}") --请选择需要升级的技能
			return
		end		
		
		-- 升级后技能
		local upSkillID = PlayerPackage:GetBagKfsSkillUpSkill(m_Equip_Idx , skillSelected )
		if upSkillID == nil or upSkillID == 0 then
			PushDebugMessage("#{WHYH_161121_65}")  --请选择需要升级的技能
			return
		end		
		
		-- 武魂的当前技能是否已提升至最高级
		if upSkillID == -1 then
			PushDebugMessage("#{WHYH_161121_66}")  --该技能已经达到最高等级，不能继续升级！
			return
		end
		
		-- 所需材料
		local needItem = PlayerPackage:GetBagKfsSkillUpItem(m_Equip_Idx , skillSelected )
		if needItem ~= nil and needItem <= 0 then
			PushDebugMessage("#{WHYH_161121_66}")
			return
		end
		local needItemBind = WuhunSkillUp_GetBindItemIndex(needItem)
		if needItemBind ~= nil and needItemBind <= 0 then
			PushDebugMessage("#{WHYH_161121_66}")
			return
		end
					
		-- 道具是否为魂冰珠
		local itemID = PlayerPackage:GetItemTableIndex(itemIdx)
		local bValid = WuhunSkillUp_CheckItemValid(itemID)
		if bValid == nil or bValid <= 0 then
			PushDebugMessage("#{WHYH_161121_67}") -- 此处只能放入。
			return
		end

		if PlayerPackage:IsLock( itemIdx ) == 1 then
			PushDebugMessage("#{WHYH_161121_68}")	--上锁了
			return
		end
		
		-- 当前是否符合已选中的升级所需
		if itemID ~= needItem and itemID ~= needItemBind then
			if m_Equip_Item == itemIdx then
				WuhunSkillUp_Object6:SetActionItem(-1);			
				LifeAbility : Lock_Packet_Item(m_Equip_Item,0);		
				m_Equip_Item = -1;
				return
			end
			local needItemName = PlayerPackage:GetItemName(needItem)
			local bRet,strSkillName = DataPool:GetSkillName(upSkillID)
			if bRet == 1 then
				local tips = ScriptGlobal_Format("#{WHYH_161121_69}", strSkillName, needItemName)
				PushDebugMessage(tips)
			end
			return
		end

		if m_Equip_Item ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Item,0);
		end

		WuhunSkillUp_Object6:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Equip_Item = itemIdx
	else
		WuhunSkillUp_Object6:SetActionItem(-1);			
		LifeAbility : Lock_Packet_Item(m_Equip_Item,0);		
		m_Equip_Item = -1;
	end
	
	WuhunSkillUp_UICheck()
end

-- 检测放入的材料是否是魂冰珠，如果是则返回下标
function WuhunSkillUp_CheckItemValid(itemID)
	if itemID == nil or itemID <= 0 then
		return 0
	end
	
	-- 查找放入的道具是否为非绑定材料，返回对应的下标
	for i=1, table.getn(g_HunBing) do
		if g_HunBing[i] == itemID then
			return i
		end
	end
	
	-- 查找放入的道具是否为绑定材料，返回对应的下标
	for i=1, table.getn(g_HunBing_Bind) do
		if g_HunBing_Bind[i] == itemID then
			return i
		end
	end
	
	return 0
end

-- 获得所需的材料对应的绑定材料
function WuhunSkillUp_GetBindItemIndex(needItem)
	if needItem == nil or needItem <= 0 then
		return 0
	end

	-- 所需材料id对应的索引
	local needLevelIndex = 0
	for i=1, table.getn(g_HunBing) do
		if g_HunBing[i] == needItem then
			needLevelIndex = i
			break
		end
	end
	if needLevelIndex == 0 then
		return 0
	end
	
	-- 所需材料对应的绑定材料
	return g_HunBing_Bind[needLevelIndex]
end

-- quick ok
function WuhunSkillUp_Quick_OK_Clicked()
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{WHYH_161121_8}")
		return
	end
	
	-- 判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	-- 是否放入武魂
	if m_Equip_Idx == -1 then
		PushDebugMessage("#{WHYH_161121_70}")
		return
	end
	if PlayerPackage:IsBagItemKFS( m_Equip_Idx ) ~= 1 then
		PushDebugMessage("#{WHYH_161121_70}")
		return
	end

	-- 当前武魂是否拥有技能
	local nSumSkill = PlayerPackage:GetBagKfsSkillNum(m_Equip_Idx)
	if nSumSkill == nil or nSumSkill <= 0 then
		PushDebugMessage("#{WHYH_161121_71}")	--当前武魂没有领悟技能，请先领悟技能再进行技能升级操作
		return
	end
	
	if skillSelected == -1 then
		PushDebugMessage("#{WHYH_161121_72}") --请选择需要升级的技能
		return
	end

	local upSkillID = PlayerPackage:GetBagKfsSkillUpSkill(m_Equip_Idx , skillSelected )
	if upSkillID == -1 then
		PushDebugMessage("#{WHYH_161121_66}")  --该技能已经达到最高等级，不能继续升级！
		return
	end
	
	PlayerPackage:Kfs_Op_Do(7 , m_Equip_Idx , -1 , skillSelected , 1)-- 0 普通 1 快捷 2 快捷确认
end

--OnOK
function WuhunSkillUp_OK_Clicked()
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{WHYH_161121_8}")
		return
	end
	
	-- 判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	-- 是否放入武魂
	if m_Equip_Idx == -1 then
		PushDebugMessage("#{WHYH_161121_70}")
		return
	end
	if PlayerPackage:IsBagItemKFS( m_Equip_Idx ) ~= 1 then
		PushDebugMessage("#{WHYH_161121_70}")
		return
	end

	-- 当前武魂是否拥有技能
	local nSumSkill = PlayerPackage:GetBagKfsSkillNum(m_Equip_Idx)
	if nSumSkill == nil or nSumSkill <= 0 then
		PushDebugMessage("#{WHYH_161121_71}")	--当前武魂没有领悟技能，请先领悟技能再进行技能升级操作
		return
	end
	
	if skillSelected == -1 then
		PushDebugMessage("#{WHYH_161121_72}") --请选择需要升级的技能
		return
	end

	local upSkillID = PlayerPackage:GetBagKfsSkillUpSkill(m_Equip_Idx , skillSelected )
	if upSkillID == nil or upSkillID == 0 then
		PushDebugMessage("#{WHYH_161121_72}")  --请选择需要升级的技能
		return
	end
	
	-- 所需材料
	local needItem = PlayerPackage:GetBagKfsSkillUpItem(m_Equip_Idx , skillSelected )
	if needItem ~= nil and needItem <= 0 then
		PushDebugMessage("#{WHYH_161121_72}")
		return
	end
	local needItemBind = WuhunSkillUp_GetBindItemIndex(needItem)
	if needItemBind ~= nil and needItemBind <= 0 then
		PushDebugMessage("#{WHYH_161121_72}")
		return
	end
		
	if upSkillID == -1 then
		PushDebugMessage("#{WHYH_161121_66}")  --该技能已经达到最高等级，不能继续升级！
		return
	end
	
	-- 界面是否已置入魂冰珠
	if m_Equip_Item == -1 then
		PushDebugMessage("#{WHYH_161121_74}") --请先放入升级技所需的魂冰珠，再进行该操作
		return
	end	
	
	-- 道具是否为魂冰珠
	local itemID = PlayerPackage:GetItemTableIndex(m_Equip_Item)
	local bValid = WuhunSkillUp_CheckItemValid(itemID)
	if bValid == nil or bValid <= 0 then
		PushDebugMessage("#{WHYH_161121_74}") -- 此处只能放入。
		return
	end

	if PlayerPackage:IsLock( m_Equip_Item ) == 1 then
		PushDebugMessage("#{WHYH_161121_68}")	--上锁了
		return
	end
	
	-- 当前是否符合已选中的升级所需
	if itemID ~= needItem and itemID ~= needItemBind then
		local needItemName = PlayerPackage:GetItemName(needItem)
		local bRet,strSkillName = DataPool:GetSkillName(upSkillID)
		if bRet == 1 then
			local tips = ScriptGlobal_Format("#{WHYH_161121_69}", strSkillName, needItemName)
			PushDebugMessage(tips)
		end
		return
	end

	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	local needMoney = PlayerPackage:GetBagKfsSkillUpMoney(m_Equip_Idx , skillSelected )
	
	if selfMoney < needMoney then
		PushDebugMessage("#{WHYH_161121_75}")  --对不起，你身上金钱不足，无法继续进行
		return
	end

	PlayerPackage:Kfs_Op_Do(7 , m_Equip_Idx , m_Equip_Item , skillSelected , 0)-- 0 普通 1 快捷 2 快捷确认
end


--select a skill
function WuhunSkillUp_Select_Skill(skill_index)

	-- 相同则不必更新
	if skillSelected == skill_index then
		return
	end
	
	Skills[1]:SetPushed(0)
	Skills[2]:SetPushed(0)
	Skills[3]:SetPushed(0)

	Skills[skill_index + 1]:SetPushed(1)
	skillSelected = skill_index

	local needMoney = PlayerPackage:GetBagKfsSkillUpMoney(m_Equip_Idx , skill_index )
	WuhunSkillUp_DemandMoney:SetProperty("MoneyNumber", needMoney); 
	
	-- 清空材料栏并在uicheck里更新所需材料
	WuhunSkillUp_Update_Sub(-1)
	
end

--Right button clicked
function WuhunSkillUp_Resume_Equip()

	WuhunSkillUp_Update(-1)

end

--Right button clicked
function WuhunSkillUp_Resume_Item()

	WuhunSkillUp_Update_Sub(-1)

end

--Care Obj
function WuhunSkillUp_BeginCareObj(obj_id)
	
	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id);
	this:CareObject(m_ObjCared, 1);
end

--handle Hide Event
function WuhunSkillUp_OnHiden()

	WuhunSkillUp_Update(-1)
	WuhunSkillUp_Update_Sub(-1)
	
end


function WuhunSkillUp_UICheck()
	WuhunSkillUp_SelfMoney:SetProperty("MoneyNumber", Player:GetData("MONEY"));
	WuhunSkillUp_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ")); 
	WuhunSkillUp_DemandMoney:SetProperty("MoneyNumber", 0); 
	WuhunSkillUp_OK:Disable()
	-- 所需材料
	WuhunSkillUp_Object5:SetActionItem(-1)
	-- 快捷提升	
	WuhunSkillUp_QuicklyUp:Disable()
	WuhunSkillUp_QuicklyUp:SetText("#{WHYH_161121_31}")
	WuhunSkillUp_QuicklyUp_Animate:SetToolTip("")
	WuhunSkillUp_QuicklyUp_Animate:Play(false)

	Skills[1]:SetActionItem(-1)
	Skills[2]:SetActionItem(-1)
	Skills[3]:SetActionItem(-1)
	Skills[1]:SetPushed(0)
	Skills[2]:SetPushed(0)
	Skills[3]:SetPushed(0)
	Kfs_Skill_ID = {}
	
	if m_Equip_Idx ~= -1 then
		local nSumSkill = PlayerPackage:GetBagKfsSkillNum(m_Equip_Idx)
		if nSumSkill ~= nil and nSumSkill > 0 and nSumSkill < 4 then
			for i=1 ,3 do
				local skillID = PlayerPackage:GetBagKfsSkill(m_Equip_Idx , i - 1)
				if skillID ~= nil and skillID > 0 then
					Kfs_Skill_ID[i] = skillID
				else
					Kfs_Skill_ID[i] = -1
				end
			end
			
			local theAction_kfs = EnumAction(m_Equip_Idx, "packageitem");
			local kfsID = -1
			if theAction_kfs:GetID() ~= 0 then
				kfsID = theAction_kfs:GetItemID();
			end
			
			for i=1, nSumSkill do
				local theAction = EnumAction(kfsID * 3 + i -1 , "kfsskill");
				if theAction:GetID() ~= 0 then
					Skills[i]:SetActionItem(theAction:GetID());
				end
			end
			
			if skillSelected ~= -1  then
				Skills[skillSelected + 1]:SetPushed(1)	
				local needMoney = PlayerPackage:GetBagKfsSkillUpMoney(m_Equip_Idx , skillSelected )
				WuhunSkillUp_DemandMoney:SetProperty("MoneyNumber", needMoney); 
			end
			
			-- 所需材料
			local needItem = PlayerPackage:GetBagKfsSkillUpItem(m_Equip_Idx , skillSelected )
			if needItem ~= nil and needItem > 0 then
				local theAction = DataPool:CreateActionItemForShow(needItem, 1)
				if theAction:GetID() ~= 0 then
					WuhunSkillUp_Object5:SetActionItem(theAction:GetID())
				end
			end
			
			-- 快捷提升	
			if skillSelected ~= -1  then
				WuhunSkillUp_QuicklyUp:Enable()
				WuhunSkillUp_QuicklyUp:SetText("#{WHYH_161121_131}")
				WuhunSkillUp_QuicklyUp_Animate:SetToolTip(ScriptGlobal_Format("#{WHYH_161121_60}", g_LevelMax, g_LevelMax))--目前只开放到6级
				WuhunSkillUp_QuicklyUp_Animate:Play(true)
			end
				
		else
			skillSelected = -1	--没有技能
		end
	else
		skillSelected = -1  --武魂栏 空
	end
	
	if m_Equip_Idx ~= -1 and m_Equip_Item ~= -1 then
		WuhunSkillUp_OK:Enable()
	end

end