--  WuhunSkillStudy
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
--PreLoad
function WuhunSkillStudy_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_KFS_SKILL")
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

--OnLoad
function WuhunSkillStudy_OnLoad()

end

--OnEvent
function WuhunSkillStudy_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == m_UI_NUM) then

		WuhunSkillStudy_BeginCareObj( Get_XParam_INT(0) );
		m_UIType = Get_XParam_INT(1)
		g_Wuhun_Wx = Get_XParam_INT(2)
		
		-- 元宝确认
		WuhunSkillStudy_Blank_QuerenLace:Hide()

		if m_UIType == UI_TYPE_STUDY then
			WuhunSkillStudy_Title:SetText("#{WH_xml_XX(26)}")
			WuhunSkillStudy_Info:SetText("#{WH_xml_XX(27)}")
			WuhunSkillStudy_Info2:SetText("#{WH_xml_XX(28)}")

		elseif m_UIType == UI_TYPE_RESET then
			return
	--		WuhunSkillStudy_Title:SetText("#{WH_xml_XX(39)}")
	--		WuhunSkillStudy_Info:SetText("#{WH_xml_XX(40)}")
	--		WuhunSkillStudy_Info2:SetText("#{WH_xml_XX(41)}")
		elseif m_UIType == UI_TYPE_RESET_WX then
			-- 旧界面逻辑废弃
			return
			--if(g_Wuhun_Wx < 0 or g_Wuhun_Wx > 4) then
				--return
			--end
			--WuhunSkillStudy_Title:SetText("#{WHGBSX_xml_XX(01)}")
			--if( g_Wuhun_Wx == 1) then
				--WuhunSkillStudy_Info:SetText("#{WHGBSX_091015_02}")
			--elseif( g_Wuhun_Wx == 2) then
				--WuhunSkillStudy_Info:SetText("#{WHGBSX_091015_13}")
			--elseif( g_Wuhun_Wx == 3) then
				--WuhunSkillStudy_Info:SetText("#{WHGBSX_091015_14}")
			--elseif( g_Wuhun_Wx == 4) then
				--WuhunSkillStudy_Info:SetText("#{WHGBSX_091015_15}")
			--end
			--WuhunSkillStudy_Info2:SetText("#{WHGBSX_091015_03}")
		elseif m_UIType == UI_TYPE_RESET_GROWRATE1 then
			WuhunSkillStudy_Title:SetText("#{WHXCZL_xml_XX(06)}")
			WuhunSkillStudy_Info:SetText("#{WHXCZL_xml_XX(07)}")
			WuhunSkillStudy_Info2:SetText("#{WHXCZL_xml_XX(08)}")
		elseif m_UIType == UI_TYPE_RESET_GROWRATE2 then
			WuhunSkillStudy_Title:SetText("#{WHXCZL_xml_XX(06)}")
			WuhunSkillStudy_Info:SetText("#{WHXCZL_xml_XX(09)}")
			WuhunSkillStudy_Info2:SetText("#{WHXCZL_xml_XX(08)}")
			-- 元宝确认
			WuhunSkillStudy_Blank_QuerenLace:Show()
			if g_YBCheck == 1 then
				WuhunSkillStudy_Blank_Queren:SetCheck( 1 )
			elseif g_YBCheck == 0 then
				WuhunSkillStudy_Blank_Queren:SetCheck( 0 )
			end
		end

		WuhunSkillStudy_Update(-1)
		this:Show();
		WuhunSkillStudy_OK:Disable();
	elseif (event == "UPDATE_KFS_SKILL" and this:IsVisible() ) then

		if arg0 ~= nil then
			WuhunSkillStudy_Update( tonumber(arg0) )
		end

	elseif (event == "MONEY_CHANGE_EX") then
		WuhunSkillStudy_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));

	elseif (event == "MONEYJZ_CHANGE_EX") then
		WuhunSkillStudy_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))

	elseif (event == "PACKAGE_ITEM_CHANGED_EX") then
		if arg0 ~= nil and tonumber(arg0) == m_Equip_Idx then
			WuhunSkillStudy_Update(m_Equip_Idx)
		end
	end
end

--Update UI
function WuhunSkillStudy_Update(itemIdx)
	WuhunSkillStudy_SelfMoney:SetProperty("MoneyNumber", Player:GetData("MONEY"));
	WuhunSkillStudy_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"));
	resetConfirm = 0

	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then

		if PlayerPackage:IsBagItemKFS( itemIdx ) ~= 1 then
				PushDebugMessage("#{WH_090729_13}")	--此处只能放入武魂。
				return
		end

		if m_UIType == UI_TYPE_STUDY then
			local skillNum = PlayerPackage:GetBagKfsSkillNum(itemIdx)
			if skillNum == 3 then
				if itemIdx == m_Equip_Idx then
					WuhunSkillStudy_Object:SetActionItem(-1);
					LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
					m_Equip_Idx = -1;
					return
				end

				PushDebugMessage("#{WH_090729_22}")	--已经有3个技能了
				return
			end
		elseif m_UIType == UI_TYPE_RESET then

			if PlayerPackage:IsLock( itemIdx ) == 1 then
				PushDebugMessage("#{WH_090729_07}")	--道具已上锁
				return
			end

			local skillNum = PlayerPackage:GetBagKfsSkillNum(itemIdx)
			if skillNum == 0 then
				PushDebugMessage("#{WH_090729_33}")	--还没有领悟技能
				return
			end
		elseif m_UIType == UI_TYPE_RESET_WX then
			-- 旧界面逻辑废弃
			return
			--local nWx = PlayerPackage:GetBagKfsData(itemIdx, "MAGIC")
			--if nWx == 0 then
				--PushDebugMessage("#{WHGBSX_091015_05}")	--还没有领悟五行
				--return
			--end
		end

		if m_Equip_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		end

		WuhunSkillStudy_Object:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Equip_Idx = itemIdx

		WuhunSkillStudy_OK:Enable();

	else
		WuhunSkillStudy_Object:SetActionItem(-1);
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		m_Equip_Idx = -1;
	end

	if m_Equip_Idx ~= -1 then
		if m_UIType == UI_TYPE_STUDY then
			local skillNum = PlayerPackage:GetBagKfsSkillNum(m_Equip_Idx)

			needMoney = 0
			if skillNum == 0 then
				needMoney = 50000			--第一个技能5金
			elseif 	skillNum == 1 then
				needMoney = 100000			--第二个技能10金
			elseif 	skillNum == 2 then
				needMoney = 150000			--第三个技能15金
			elseif	skillNum == 3 then
				needMoney = 0
				WuhunSkillStudy_OK:Disable();
			end
			WuhunSkillStudy_DemandMoney:SetProperty("MoneyNumber", needMoney);

		elseif m_UIType == UI_TYPE_RESET then--or m_UIType == UI_TYPE_RESET_WX then
			needMoney = 50000
			WuhunSkillStudy_DemandMoney:SetProperty("MoneyNumber", needMoney);
		elseif m_UIType == UI_TYPE_RESET_GROWRATE1 or m_UIType == UI_TYPE_RESET_GROWRATE2 then
			needMoney =50000
			WuhunSkillStudy_DemandMoney:SetProperty("MoneyNumber", needMoney);
		end
	else

		WuhunSkillStudy_DemandMoney:SetProperty("MoneyNumber", 0);
	end
end

--OnOK
function WuhunSkillStudy_Growrate2_OK_Clicked()
	
	if m_UIType ~= UI_TYPE_RESET_GROWRATE2 then
		return
	end
	
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
		PushDebugMessage("#{WHYH_161121_116}")
		return
	end
	if PlayerPackage:IsBagItemKFS( m_Equip_Idx ) ~= 1 then
		PushDebugMessage("#{WHYH_161121_116}")
		return
	end
		
	PlayerPackage:Kfs_Op_Do(12 , m_Equip_Idx,0,0,g_YBCheck)
end

--OnOK
function WuhunSkillStudy_OK_Clicked()

	if m_UIType == UI_TYPE_RESET_GROWRATE2 then
		WuhunSkillStudy_Growrate2_OK_Clicked()
		return
	end
	--	改变武魂属性 需要验证密保 --
	--if m_UIType == UI_TYPE_RESET_WX then
		--判断电话密保和二级密码保护2012.6.12-LIUBO
		--if CheckPhoneMibaoAndMinorPassword() ~= 1 then
			--return
		--end
		-- 判断是否为安全时间2012.6.12-LIUBO
		--if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
			--PushDebugMessage("#{ZYXT_120528_16}")
			--return
		--end
	--end

	if m_Equip_Idx == -1 then
		return
	end

	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")

	if selfMoney < needMoney then
		PushDebugMessage("#{WH_090729_18}")  --对不起，你身上金钱不足，无法继续进行
		return
	end

	if m_UIType == UI_TYPE_STUDY then
		PlayerPackage:Kfs_Op_Do(5 , m_Equip_Idx)
	elseif m_UIType == UI_TYPE_RESET then
		if CheckPhoneMibaoAndMinorPassword() ~= 1 then
			return
		end

-- Deleted by FengLiang
--		if resetConfirm == 0 then
--			for i=1 , 3 do
--				local skillUpItem = PlayerPackage:GetBagKfsSkillUpItem(m_Equip_Idx , i - 1)
--				if skillUpItem ~= nil and skillUpItem ~= 0 and skillUpItem ~= 20310117 and skillUpItem ~= 20310161  then
--					PopComfirm_Alpha0("#{WH_090916_01}")
--					resetConfirm = 1
--					return
--				end
--			end
--		end

		PlayerPackage:Kfs_Op_Do(6 , m_Equip_Idx, 0, 0, 0)--默认0，貌似这里根本走不到，保险还是加上吧
	--elseif m_UIType == UI_TYPE_RESET_WX then
		--PlayerPackage:Kfs_Op_Do( 10 , m_Equip_Idx ,g_Wuhun_Wx);
		--this:Hide();
    elseif m_UIType == UI_TYPE_RESET_GROWRATE1 then
		 PlayerPackage:Kfs_Op_Do(11 , m_Equip_Idx,0,0)
	--elseif m_UIType == UI_TYPE_RESET_GROWRATE2 then
		 --PlayerPackage:Kfs_Op_Do(12 , m_Equip_Idx,0,0,g_YBCheck)
	end
end

--Right button clicked
function WuhunSkillStudy_Resume_Equip()

	WuhunSkillStudy_Update(-1)
    WuhunSkillStudy_OK:Disable();
end

--Care Obj
function WuhunSkillStudy_BeginCareObj(obj_id)

	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id);
	this:CareObject(m_ObjCared, 1);
end

--handle Hide Event
function WuhunSkillStudy_OnHiden()

	WuhunSkillStudy_Update(-1)
	resetConfirm = 0

end

function WuhunSkillStudy_Queren_Clicked()
	local bCheck = WuhunSkillStudy_Blank_Queren:GetCheck();
	if ( bCheck == 1 ) then
		g_YBCheck = 1
		WuhunSkillStudy_Blank_Queren:SetCheck( 1 )
	elseif ( bCheck == 0 ) then
		g_YBCheck = 0
		WuhunSkillStudy_Blank_Queren:SetCheck( 0 )
	end
end

function WuhunSkillStudy_Help_Clicked()
	if m_UIType == UI_TYPE_RESET_WX then
		Helper:GotoHelper("whsx")
	else
		Helper:GotoHelper("*WuhunSkillStudy")
	end
end
