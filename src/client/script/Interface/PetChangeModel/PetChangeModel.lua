--!!!reloadscript =PetChangeModel

local m_UI_CHANGEMODEL = 20101029	--改变珍兽模型外观

local m_PetIndex = -1
local m_ObjCared = -1
local m_needMoney = 0

local m_Cow = {23761,23762,23763,23764,23765,23766,23767,23769,23771,23772,23773,23774,23775,23776,23777,23778,23779}
local g_PetChangeModel_Frame_UnifiedPosition

function PetChangeModel_PreLoad()
	this : RegisterEvent( "UI_COMMAND" )
	this : RegisterEvent( "REPLY_MISSION_PET", false )						-- 玩家从列表选定一只珍兽
	this : RegisterEvent( "UPDATE_PET_PAGE", false )						-- 玩家身上的珍兽数据发生变化，包括增加一只珍兽
	this : RegisterEvent( "DELETE_PET" )							-- 玩家身上减少一只珍兽
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this : RegisterEvent("MONEYJZ_CHANGE_EX", false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function PetChangeModel_OnLoad()
	g_PetChangeModel_Frame_UnifiedPosition=PetChangeModel_Frame:GetProperty("UnifiedPosition")
end

function PetChangeModel_OnEvent(event)

	if event == "UI_COMMAND" and tonumber( arg0 ) == m_UI_CHANGEMODEL then

		if Get_XParam_INT(0) == 1 then
		if this : IsVisible() then
			return
		end
			
			PetChangeModel_BeginCareObj(Get_XParam_INT(1))
		PetChangeModel_CleanUp()
		this:Show()

		Pet : ShowPetList( 1 )
			PetChangeModel_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
			PetChangeModel_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		elseif Get_XParam_INT(0) == 2 then
			PetChangeModel_CleanUp()		
		end
		
		
	elseif event == "MONEY_CHANGE_EX" and this:IsVisible() then
		PetChangeModel_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		PetChangeModel_UICheck()
	elseif event == "MONEYJZ_CHANGE_EX" and this:IsVisible() then
		PetChangeModel_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		PetChangeModel_UICheck()
	elseif event == "REPLY_MISSION_PET" and this : IsVisible() then
		PetChangeModel_OnSelectPet( tonumber( arg0 ) )
	elseif event == "UPDATE_PET_PAGE"  and this:IsVisible() then
		PetChangeModel_UICheck()
		return
	elseif event == "DELETE_PET"  and this:IsVisible() then
		this:Hide()
	elseif event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		PetChangeModel_Frame_On_ResetPos()
	end

end

--Close
function PetChangeModel_Close_Window()
	this:Hide()
end

--OK
function PetChangeModel_OK_Clicked()

	--判断电话密保和二级密码保护2012.6.12-LIUBO
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end
	
	-- 判断是否为安全时间2012.6.12-LIUBO
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{ZYXT_120528_16}")
		return
	end
	
	if m_PetIndex == -1  then
		return
	end
	
	--金钱不足
	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	if selfMoney < m_needMoney then
		PushDebugMessage("#{RXZS_090804_39}")  --你的金钱不足。
		return
	end

	--选择外观是否相同
	local curDataId = Pet:GetDataID(m_PetIndex)
	local ret,nOriDataId = Pet:GetHHPetOriDataId(m_PetIndex)

	if curDataId == nOriDataId then
		PushDebugMessage("#{RXZS_090804_40}")      --当前外观已经是原有珍兽外观，无法褪玉。
		return
	end

	--选择的是还原老外观 且没有老外观
	if ret ~= 1 then
		PushDebugMessage("#{RXZS_090804_41}")      --由于该珍兽幻化时间较早，已无法更改回原有外观，无法褪玉。
		return
	end

	--缺少道具
--	local isExist = IsItemExist(38004091)
--	if isExist == 0 then
	--	PushDebugMessage("#{RXZS_090804_42}")  --#H缺少珍兽褪玉符，或者道具已加锁。	
	--	return
--	end
	
	local nHuanlingId = Pet:GetHuanlingIdByIndex(m_PetIndex)
	if nHuanlingId >= 0 then
		PushDebugMessage("#{RXZS_090804_38}")    --幻灵珍兽不能幻化
		return
	end
	
 	local hid,lid = Pet:GetGUID(m_PetIndex)
	if PetChangeModel_IsCow(nOriDataId) == 1 then
		Pet:Lua_PetChangemodelConfirm(hid,lid)
	else		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "Pet_ChangeModel" )
			Set_XSCRIPT_ScriptID( 800124 )
			Set_XSCRIPT_Parameter( 0, hid )
			Set_XSCRIPT_Parameter( 1, lid )
		Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
	end
 	

	
	

--	PetChangeModel_CleanUp()
end

--Select Pet
function PetChangeModel_SelectPet_Clicked()
	Pet : ShowPetList( 0 )
	Pet : ShowPetList( 1 )
end

function PetChangeModel_Pet_Modle_TurnLeft( start )
	--向左旋转开始
	if(start == 1) then
		PetChangeModel_FakeObject:RotateBegin(-0.3)
	--向左旋转结束
	else
		PetChangeModel_FakeObject:RotateEnd()
	end

end

function PetChangeModel_Pet_Modle_TurnRight( start )
	--向右旋转开始
	if(start == 1) then
		PetChangeModel_FakeObject:RotateBegin(0.3)
	--向右旋转结束
	else
		PetChangeModel_FakeObject:RotateEnd()
	end
end

function PetChangeModel_OnHidden()
	PetChangeModel_CleanUp()
	Pet : ShowPetList( 0 )
end

function PetChangeModel_OnSelectPet(petIndex)

	if -1 == petIndex then
		return
	end

	--珍兽已被其它界面选中
	if Pet:GetPetLocation(petIndex) ~= -1 then
		return
	end

	--未幻化
	local gen = Pet:GetType(petIndex)
	if gen == nil or gen < 100 then	--100以上为幻化珍兽
		PushDebugMessage("#{RXZS_090804_36}")    	--#H只有携带等级≥85级的幻化珍兽才可以进行褪玉。
		return
	end

	--携带等级是否是85以上
	local takeLevel = Pet:GetTakeLevel(petIndex)
	if takeLevel == nil or takeLevel < 85 then
		PushDebugMessage("#{RXZS_090804_36}")    	--#H只有携带等级≥85级的幻化珍兽才可以进行褪玉。
		return
	end
	
	local curDataId = Pet:GetDataID(petIndex)
	local ret,nOriDataID = Pet:GetHHPetOriDataId(petIndex)

	if curDataId == nOriDataID then
		PushDebugMessage("#{RXZS_090804_37}")
		return
	end

	if ret ~= 1 then
		PushDebugMessage("#{RXZS_090804_41}")
		return
	end
	local nHuanlingId = Pet:GetHuanlingIdByIndex(petIndex)
	if nHuanlingId >= 0 then
		PushDebugMessage("#{RXZS_090804_38}")    	--该珍兽已幻灵，请还原后再进行该操作。
		return
	end

	PetChangeModel_FakeObject:SetFakeObject("")
	Pet:SetSkillStudyModel(petIndex)

	PetChangeModel_FakeObject:SetFakeObject("My_PetStudySkill")

	--切换珍兽的时候，释放上一个珍兽
	if m_PetIndex ~= -1 then
		Pet:SetPetLocation(m_PetIndex,-1)
	end

	m_PetIndex = petIndex				--已经选好了珍兽
	Pet:SetPetLocation(m_PetIndex,18)

	PetChangeModel_UICheck()
end

function PetChangeModel_CleanUp()

	Pet:SetPetLocation(m_PetIndex,-1)
	m_PetIndex = -1

	PetChangeModel_FakeObject:SetFakeObject("")

	PetChangeModel_Money:SetProperty("MoneyNumber", 0)
	PetChangeModel_Pet_Text:SetText("")
	PetChangeModel_OK:Disable()

end

function PetChangeModel_UICheck()

	if  m_PetIndex ~= -1 then
		local isMoneyEnough = 0

		local szPetName,szOn = Pet:GetPetList_Appoint(m_PetIndex)
		if  szOn ~= "on_changemodel"  then
			PetChangeModel_CleanUp()
			return
		end
		
		PetChangeModel_SelfMoney:SetProperty("MoneyNumber", Player:GetData("MONEY"))
		PetChangeModel_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ"))

		local strName , strName2 = Pet:GetName(m_PetIndex)
		PetChangeModel_Pet_Text:SetText(strName)

		m_needMoney = 50000
		if m_needMoney ~= nil then
			PetChangeModel_Money:SetProperty("MoneyNumber", m_needMoney )
			local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
			if selfMoney >= m_needMoney then
				isMoneyEnough = 1
			end
		end

		if isMoneyEnough == 1 then
			PetChangeModel_OK:Enable()
		else
			PetChangeModel_OK:Disable()
		end
	else
		PetChangeModel_Money:SetProperty("MoneyNumber", 0)
		PetChangeModel_Pet_Text:SetText("")
		PetChangeModel_OK:Disable()
	end
end

--Care Obj
function PetChangeModel_BeginCareObj(obj_id)
	m_ObjCared = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(m_ObjCared, 1)
end

function PetChangeModel_Frame_On_ResetPos()
  PetChangeModel_Frame:SetProperty("UnifiedPosition", g_PetChangeModel_Frame_UnifiedPosition)
end

function PetChangeModel_IsCow(nDataId)
	for i = 1 ,table.getn(m_Cow) do
		if m_Cow[i] == nDataId then
			return 1
		end
	end
	
	return 0
end