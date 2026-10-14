--  NewWuhunSkillStudy
local m_UI_NUM = 20090722
local m_ObjCared = -1
local m_Equip_Idx = -1

local UI_TYPE_STUDY	= 1
local UI_TYPE_RESET	= 2
local UI_TYPE_RESET_WX = 3
local UI_TYPE_RESET_GROWRATE1 = 4 --回天精石重洗武魂成长率
local UI_TYPE_RESET_GROWRATE2 = 5 --回天神石重洗武魂成长率
local m_UIType = 0

local needMoney = 0

local resetConfirm = 0

local g_YBCheck = 1--默认选中

local g_Wuhun_Wx = -1;
local g_WUhun_IsReset =0
--PreLoad
function NewWuhunSkillStudy_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_RESET_KFS_SKILL")
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
	this:RegisterEvent("RESUME_ENCHASE_GEM_EX",false);
	this:RegisterEvent("KFS_SKILL_UPDATE_RECOIN");
	this:RegisterEvent("WUHUN_SKILL_RECOIN_CONFIRM_OK");


end

--OnLoad
function NewWuhunSkillStudy_OnLoad()

end

--OnEvent
function NewWuhunSkillStudy_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == m_UI_NUM) then

		NewWuhunSkillStudy_BeginCareObj( Get_XParam_INT(0) );
		m_UIType = Get_XParam_INT(1)
		g_Wuhun_Wx = Get_XParam_INT(2)
		if m_UIType == UI_TYPE_RESET then
		--	NewWuhunSkillStudy_DragTitle:SetText("#{WH_xml_XX(39)}")
		--	NewWuhunSkillStudy_Info:SetText("#{WH_xml_XX(40)}")
		--	NewWuhunSkillStudy_Info2:SetText("#{WH_xml_XX(41)}")
			NewWuhunSkillStudy_Update(-1)
			this:Show();
			-- 元宝确认
			if g_YBCheck == 1 then
				NewWuhunSkillStudy_Blank_Queren:SetCheck( 1 )
			elseif g_YBCheck == 0 then
				NewWuhunSkillStudy_Blank_Queren:SetCheck( 0 )
			end			
			NewWuhunSkillStudy_OK:Disable();
		end
	elseif(event == "RESUME_ENCHASE_GEM_EX" and this:IsVisible())then
		if(tonumber(arg0) == 170) then
			NewWuhunSkillStudy_Resume_Equip()
		end

	elseif (event == "UPDATE_RESET_KFS_SKILL" and this:IsVisible() ) then
		if arg0 ~= nil then
			NewWuhunSkillStudy_Update( tonumber(arg0) )
		end

	elseif (event == "MONEY_CHANGE_EX" and this:IsVisible()) then
		NewWuhunSkillStudy_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));

	elseif (event == "MONEYJZ_CHANGE_EX" and this:IsVisible()) then
		NewWuhunSkillStudy_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))

	elseif (event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible()) then
		if m_Equip_Idx ~= -1 and arg0 ~= nil and tonumber(arg0) == m_Equip_Idx then
			NewWuhunSkillStudy_Update(m_Equip_Idx)
		end
	elseif (event == "KFS_SKILL_UPDATE_RECOIN" and this:IsVisible() ) then
		--更新重启的属性
		NewWuhunSkillStudy_UpDateRecoin()
	elseif (event == "WUHUN_SKILL_RECOIN_CONFIRM_OK") then
		if tonumber(arg1) == 1 then
			NewWuhunSkillStudy_Clear(1) --先把原来的清空了
			NewWuhunSkillStudy_Update(tonumber(arg0)) --再放上新的~
		elseif tonumber(arg1) == 0 then
			NewWuhunSkillStudy_Clear(1)
			this:Hide()
		elseif tonumber(arg1) == 2 then
			NewWuhunSkillStudy_Clear(1) --先把原来的清空了
		end
	end
end

--Update UI
function NewWuhunSkillStudy_Update(itemIdx)

	if m_Equip_Idx ~= -1 and i_index ~= m_Equip_Idx and  g_WUhun_IsReset == 1  then

		--二次确认框
			NewWuhunSkillStudy_SendKFSSkillConfirm(itemIdx,1)
		-- 如果空格内已经有对应物品了,需要弹一个二次确认……
			return
		end
	NewWuhunSkillStudy_Clear(1)
	NewWuhunSkillStudy_SelfMoney:SetProperty("MoneyNumber", Player:GetData("MONEY"));
	NewWuhunSkillStudy_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"));
	resetConfirm = 0

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then

		if PlayerPackage:IsBagItemKFS( itemIdx ) ~= 1 then
				PushDebugMessage("#{WHZN_141216_14}")	--此处只能放入武魂。
				return
		end

		if PlayerPackage:IsLock( itemIdx ) == 1 then
			PushDebugMessage("#{WHZN_141216_15}")	--道具已上锁
			return
		end

		local skillNum = PlayerPackage:GetBagKfsSkillNum(itemIdx)
		if skillNum == 0 then
			PushDebugMessage("#{WHZN_141216_16}")	--还没有领悟技能
			return
		end

		if m_Equip_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		end

		NewWuhunSkillStudy_Object:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		local icon =  tostring(LifeAbility : Get_Item_Icon_Name(itemIdx))
		NewWuhunSkillStudy_Object2:SetProperty("Image",icon)
		m_Equip_Idx = itemIdx
		NewWuhunSkillStudy_OK:Enable();

	else
		NewWuhunSkillStudy_Object:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		NewWuhunSkillStudy_Object2:SetProperty("Image","")
		m_Equip_Idx = -1;
	end

	if m_Equip_Idx ~= -1 then
	--	if m_UIType == UI_TYPE_RESET  then
			needMoney = 50000
			NewWuhunSkillStudy_DemandMoney:SetProperty("MoneyNumber", needMoney);
	--	end
		local desc = DataPool:GetKFSSkillDesc(m_Equip_Idx,0)
		NewWuhunSkillStudy_Bk1_Text2:SetText(desc)

		desc = DataPool:GetKFSSkillDesc(m_Equip_Idx,1)
		NewWuhunSkillStudy_Bk1_Text4:SetText(desc)

		desc = DataPool:GetKFSSkillDesc(m_Equip_Idx,2)
		NewWuhunSkillStudy_Bk1_Text6:SetText(desc)

	else

		NewWuhunSkillStudy_DemandMoney:SetProperty("MoneyNumber", 0);
		NewWuhunSkillStudy_Bk1_Text2:SetText("")
		NewWuhunSkillStudy_Bk1_Text4:SetText("")
		NewWuhunSkillStudy_Bk1_Text6:SetText("")
	end
	if g_WUhun_IsReset == 1 then
		NewWuhunSkillStudy_Bk2_Btn:Enable()
	else
		NewWuhunSkillStudy_Bk2_Btn:Disable()
	end
end

--OnOK
function NewWuhunSkillStudy_OK_Clicked()

	-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{WHYH_161121_8}")
		return
	end
	
	--	改变武魂属性 需要验证密保 --
	--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	if m_Equip_Idx == -1 then
		PushDebugMessage("#{WHYH_161121_48}")	--请先放入重洗技能的武魂，再进行该操作。
		return
	end

	if PlayerPackage:IsBagItemKFS( m_Equip_Idx ) ~= 1 then
		PushDebugMessage("#{WHYH_161121_48}")	--此处只能放入武魂。
		return
	end
		
	if PlayerPackage:IsLock( m_Equip_Idx ) == 1 then
		PushDebugMessage("#{WHYH_161121_124}")	--道具已上锁
		return
	end

	local skillNum = PlayerPackage:GetBagKfsSkillNum(m_Equip_Idx)
	if skillNum == 0 then
		PushDebugMessage("#{WHYH_161121_49}")	--还没有领悟技能
		return
	end

	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")

	if selfMoney < needMoney then
		PushDebugMessage("#{WHYH_161121_50}")  --对不起，你身上金钱不足，无法继续进行
		return
	end
	
	PlayerPackage:Kfs_Op_Do(6 , m_Equip_Idx, 0, 0, g_YBCheck)

end

--Right button clicked
function NewWuhunSkillStudy_Resume_Equip()

	if m_Equip_Idx ~= -1 and g_WUhun_IsReset == 1  then
		NewWuhunSkillStudy_SendKFSSkillConfirm(Dark_Bag_Index,2)
		return
	end
	NewWuhunSkillStudy_Update(-1)
    NewWuhunSkillStudy_OK:Disable();
end

--Care Obj
function NewWuhunSkillStudy_BeginCareObj(obj_id)

	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id);
	this:CareObject(m_ObjCared, 1);
end

--handle Hide Event
function NewWuhunSkillStudy_OnHiden()

--	NewWuhunSkillStudy_Update(-1)
--	resetConfirm = 0
	NewWuhunSkillStudy_Clear(1)
	this:Hide()

end

function NewWuhunSkillStudy_Close()

	if m_Equip_Idx ~= -1 and g_WUhun_IsReset == 1  then
		NewWuhunSkillStudy_SendKFSSkillConfirm(m_Equip_Idx,0)
		return
	end

	NewWuhunSkillStudy_Update(-1)
--	resetConfirm = 0
	NewWuhunSkillStudy_Clear(1)
	this:Hide()

end




function NewWuhunSkillStudy_Help_Clicked()
	if m_UIType == UI_TYPE_RESET_WX then
		Helper:GotoHelper("whsx")
	else
		Helper:GotoHelper("*NewWuhunSkillStudy")
	end
end


function NewWuhunSkillStudy_UpDateRecoin()

	local str =  DataPool : GetKFSNewSkillDesc(m_Equip_Idx,0);
	NewWuhunSkillStudy_Bk2_Text2:SetText(str)
	str =  DataPool : GetKFSNewSkillDesc(m_Equip_Idx,1);
	NewWuhunSkillStudy_Bk2_Text4:SetText(str)
	str =  DataPool : GetKFSNewSkillDesc(m_Equip_Idx,2);
	NewWuhunSkillStudy_Bk2_Text6:SetText(str)


	NewWuhunSkillStudy_Bk2_Btn:Enable()
	g_WUhun_IsReset = 1
end

function NewWuhunSkill_SaveChange_OK()

	--	改变武魂属性 需要验证密保 --
		--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end
		-- 判断是否为安全时间2012.6.12-LIUBO
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{WHZN_141216_18}")
		return
	end
	if g_WUhun_IsReset ==1 then

 		PlayerPackage:Kfs_Op_Do(13 , m_Equip_Idx)
	end

		--设置重洗状态
	g_WUhun_IsReset =0

	NewWuhunSkillStudy_Clear(0)
	NewWuhunSkillStudy_Update(m_Equip_Idx)

end

function NewWuhunSkillStudy_Clear(cleanaction)

	g_WUhun_IsReset = 0
--	g_EquipIdentify_Confirm = -1
	NewWuhunSkillStudy_Bk1_Text2:SetText("")
	NewWuhunSkillStudy_Bk1_Text4:SetText("")
	NewWuhunSkillStudy_Bk1_Text6:SetText("")

	NewWuhunSkillStudy_Bk2_Text2:SetText("")
	NewWuhunSkillStudy_Bk2_Text4:SetText("")
	NewWuhunSkillStudy_Bk2_Text6:SetText("")

	--EquipAttributeChange_CaiLiaoText:SetText("")
	NewWuhunSkillStudy_OK:Disable()
--	IdentifyTwice_Object2:SetProperty("Image","")
	NewWuhunSkillStudy_Bk2_Btn:Disable()
	if cleanaction == 1 then
		if g_WUhun_IsReset ~= -1 then
			NewWuhunSkillStudy_Object:SetActionItem(-1)
			NewWuhunSkillStudy_Object2:SetProperty("Image","")
			LifeAbility:Lock_Packet_Item(m_Equip_Idx, 0)
			m_Equip_Idx = -1
		end
	end
end

--发送替换武魂技能的二次确认
function NewWuhunSkillStudy_SendKFSSkillConfirm(nIndex,keepopen)
	PushEvent("WUHUN_SKILL_RECOIN_CONFIRM",tostring(nIndex),tostring(keepopen))
end

function NewWuhunSkillStudy_Queren_Clicked()
	local bCheck = NewWuhunSkillStudy_Blank_Queren:GetCheck();
	if ( bCheck == 1 ) then
		g_YBCheck = 1
		NewWuhunSkillStudy_Blank_Queren:SetCheck( 1 )
	elseif ( bCheck == 0 ) then
		g_YBCheck = 0
		NewWuhunSkillStudy_Blank_Queren:SetCheck( 0 )
	end
end
