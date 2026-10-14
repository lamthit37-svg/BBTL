local m_UI_NUM = 20090727	--一次8金

local m_ObjCared = -1
local m_Equip_Idx = -1
local m_Equip_Item = -1

local m_sel = -1

local INDEX_ATTRUP_BEGIN	= 20310122	--润魂石·御（1级）
local INDEX_ATTRUP_END		= 20310157	--润魂石·暴（9级）

local m_AttrBnList = {}

local isComfirmed = 0
--PreLoad
function WuhunExtraPropertyDel_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_KFSATTR_DEL")
	this:RegisterEvent("MONEY_CHANGE_EX",false);
	this:RegisterEvent("MONEYJZ_CHANGE_EX",false);
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)
end

--Onload
function WuhunExtraPropertyDel_OnLoad()
	m_AttrBnList[1] = WuhunExtraPropertyDel_Property1
	m_AttrBnList[2] = WuhunExtraPropertyDel_Property2
	m_AttrBnList[3] = WuhunExtraPropertyDel_Property3
	m_AttrBnList[4] = WuhunExtraPropertyDel_Property4
	m_AttrBnList[5] = WuhunExtraPropertyDel_Property5
	m_AttrBnList[6] = WuhunExtraPropertyDel_Property6
	m_AttrBnList[7] = WuhunExtraPropertyDel_Property7
	m_AttrBnList[8] = WuhunExtraPropertyDel_Property8
	m_AttrBnList[9] = WuhunExtraPropertyDel_Property9
	m_AttrBnList[10] = WuhunExtraPropertyDel_Property10
end

--OnEvent
function WuhunExtraPropertyDel_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == m_UI_NUM) then
		
		WuhunExtraPropertyDel_BeginCareObj( Get_XParam_INT(0) );
		
		WuhunExtraPropertyDel_Update(-1)
		this:Show();

	elseif (event == "UPDATE_KFSATTR_DEL" and this:IsVisible() ) then
		if arg0 ~= nil then
			WuhunExtraPropertyDel_Update( tonumber(arg0) )
		end
	elseif (event == "MONEY_CHANGE_EX") then
		WuhunExtraPropertyDel_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")));
	
	elseif (event == "MONEYJZ_CHANGE_EX") then 
		WuhunExtraPropertyDel_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	
	elseif (event == "PACKAGE_ITEM_CHANGED_EX") then
		if arg0 ~= nil and tonumber(arg0) == m_Equip_Idx then
			WuhunExtraPropertyDel_Update(m_Equip_Idx)
		end 
	end
end

--Update UI
function WuhunExtraPropertyDel_Update(itemIdx)
	
	local theAction = EnumAction(itemIdx, "packageitem");
	if theAction:GetID() ~= 0 then
		
		if PlayerPackage:IsBagItemKFS( itemIdx ) ~= 1 then
			PushDebugMessage("#{WH_090729_13}") -- 此处只能放入武魂。
			return
		end

		if PlayerPackage:IsLock( itemIdx ) == 1 then
			PushDebugMessage("#{WH_090729_07}")	--道具已上锁
			return
		end
		
		local attrNum = PlayerPackage:GetBagKfsAttrExNum(itemIdx)
		if attrNum ~= nil and attrNum <= 0 then
			if m_Equip_Idx == itemIdx then
				WuhunExtraPropertyDel_Object1:SetActionItem(-1);			
				LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);		
				m_Equip_Idx = -1;
				return
			end
			PushDebugMessage("#{WH_090729_57}")	--没有扩展属性
			return
		end
		if m_Equip_Idx ~= -1 then
			LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);
		end
		WuhunExtraPropertyDel_Object1:SetActionItem(theAction:GetID());
		LifeAbility : Lock_Packet_Item(itemIdx,1);
		m_Equip_Idx = itemIdx
	else
		WuhunExtraPropertyDel_Object1:SetActionItem(-1);			
		LifeAbility : Lock_Packet_Item(m_Equip_Idx,0);		
		m_Equip_Idx = -1;
		
	end
	WuhunExtraPropertyDel_UICheck()
end

--OK
function WuhunExtraPropertyDel_OK_Clicked()
	if m_Equip_Idx == -1 then
		return
	end
	
	if m_sel == -1 then
		PushDebugMessage("#{WH_090729_67}")   --请选择需要升级的属性
		return
	end
	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	local needMoney = 1000
	
	if selfMoney < needMoney then
		PushDebugMessage("#{WH_090729_18}")   --对不起，你身上金钱不足，无法继续进行。
		return
	end

	if CheckPhoneMibaoAndMinorPassword() ~= 1 then
		return
	end

	if isComfirmed == 1 then
		PlayerPackage:Kfs_Op_Do(8 , m_Equip_Idx , m_sel - 1)
	else
		local iText , iValue = PlayerPackage:GetKfsAttrEx(m_Equip_Idx , m_sel - 1 )
		PopComfirm_Alpha0("#{WH_090817_01}#G"..iText.."#W#{WH_090817_02}")
		isComfirmed = 1
	end
end

--
function WuhunExtraPropertyDel_Resume_Equip()
	WuhunExtraPropertyDel_Update(-1)

end

--Select 1 Attr
function WuhunExtraPropertyDel_Select_AttrEx(idx)
	m_sel = idx
	isComfirmed = 0
end

--Close UI
function WuhunExtraPropertyDel_Close()
	this:Hide();
end

--Care Obj
function WuhunExtraPropertyDel_BeginCareObj(obj_id)
	
	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id);
	this:CareObject(m_ObjCared, 1);
end

--OnHiden
function WuhunExtraPropertyDel_OnHiden()

	WuhunExtraPropertyDel_Update(-1)
end


function WuhunExtraPropertyDel_UICheck()
	
	WuhunExtraPropertyDel_SelfMoney:SetProperty("MoneyNumber", Player:GetData("MONEY"));
	WuhunExtraPropertyDel_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ")); 
	WuhunExtraPropertyDel_DemandMoney : SetProperty("MoneyNumber", 0)
	WuhunExtraPropertyDel_OK:Disable()
	m_sel = -1
	isComfirmed = 0
	for i = 1 , 10 do
		m_AttrBnList[i]:Disable()
		m_AttrBnList[i]:SetText("")
		m_AttrBnList[i]:SetCheck(0)
	end

	if m_Equip_Idx ~= -1 then
		for i = 1 , 10 do
			local iText , iValue = PlayerPackage:GetKfsAttrEx(m_Equip_Idx , i - 1 )
			if iValue ~= nil and iValue > 0 and iText ~= nil then
				m_AttrBnList[i]:Enable()
				m_AttrBnList[i]:SetText(iText)
				if i == 1 then
					m_sel = 1
					m_AttrBnList[i]:SetCheck(1)
				end
			end
		end
		local needMoney = 1000
		WuhunExtraPropertyDel_DemandMoney : SetProperty("MoneyNumber", needMoney)
		WuhunExtraPropertyDel_OK:Enable()
	end
end