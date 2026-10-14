--!!!reloadscript =PetHuanhua

local m_PetIndex = -1
local m_ObjCared = -1
local m_needMoney = 0
local m_Comfirmed = 0

local g_PetHuanhua_Frame_UnifiedPosition

local g_PetHuanhua_YuanbaoPay = 1 
 
function PetHuanhua_PreLoad()
	this : RegisterEvent( "UI_COMMAND" )
	this : RegisterEvent( "REPLY_MISSION_PET", false )						-- 玩家从列表选定一只珍兽
	this : RegisterEvent( "UPDATE_PET_PAGE", false )						-- 玩家身上的珍兽数据发生变化，包括增加一只珍兽
	this : RegisterEvent( "DELETE_PET" )							-- 玩家身上减少一只珍兽
	this:RegisterEvent("MONEY_CHANGE_EX", false)
	this : RegisterEvent("MONEYJZ_CHANGE_EX", false)	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	this:RegisterEvent("PET_HUANHUA_CONFIRM_OK") 
end

function PetHuanhua_OnLoad()
	g_PetHuanhua_Frame_UnifiedPosition=PetHuanhua_Frame:GetProperty("UnifiedPosition")
end

function PetHuanhua_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 20090804 then
		
		if this : IsVisible() then
			return
		end

		PetHuanhua_BeginCareObj(Get_XParam_INT(0))
		PetHuanhua_CleanUp()
		this:Show()
		m_Comfirmed = 0
		Pet : ShowPetList( 1 )
		PetHuanhua_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		PetHuanhua_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))

	elseif event == "MONEY_CHANGE_EX" and this:IsVisible() then
		PetHuanhua_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
		PetHuanhua_UICheck()
	elseif event == "MONEYJZ_CHANGE_EX" and this:IsVisible() then
		PetHuanhua_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		PetHuanhua_UICheck()
	elseif event == "REPLY_MISSION_PET" and this : IsVisible() then
		PetHuanhua_OnSelectPet( tonumber( arg0 ) )
	elseif event == "UPDATE_PET_PAGE"  and this:IsVisible() then
		PetHuanhua_UICheck()
		return
		--PetHuanhua_CleanUp()
	elseif event == "DELETE_PET"  and this:IsVisible() then
		this:Hide()
	elseif event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		PetHuanhua_Frame_On_ResetPos()
	elseif event == "PET_HUANHUA_CONFIRM_OK" then
		m_Comfirmed = 1
		PetHuanhua_OK_Clicked()
	end

end

--Close
function PetHuanhua_Close_Window()
	this:Hide()
end

--OK
function PetHuanhua_OK_Clicked()

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
		PushDebugMessage("#{ZSYH_170111_27}")
		return
	end

	local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ")
	if selfMoney < m_needMoney then
		PushDebugMessage("#{WH_090729_18}")  --对不起，你身上金钱不足，无法继续进行。
		return
	end

	local nHuanlingId = Pet:GetHuanlingIdByIndex(m_PetIndex)
	if nHuanlingId >= 0 then
		PushDebugMessage("#{ZSHP_180814_137}")    --幻灵珍兽不能幻化
		return
	end
	
	local isExist = IsItemExist(30502005)
	if isExist == 0 then
		isExist = IsItemExist(30502006)
		if isExist == 0 then 
			local hid,lid = Pet:GetGUID(m_PetIndex) 
			Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "Pet_HH_BuyHuanHuaDan" )
			Set_XSCRIPT_ScriptID( 800124 )
			Set_XSCRIPT_Parameter( 0, hid )
			Set_XSCRIPT_Parameter( 1, lid )
				Set_XSCRIPT_Parameter(2, g_PetHuanhua_YuanbaoPay)
				Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT()
			return
		end
	end

	local hid,lid = Pet:GetGUID(m_PetIndex)
	if m_Comfirmed == 0 then
		Pet:PetHHComfirm(m_PetIndex) 
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "Pet_HH" )
			Set_XSCRIPT_ScriptID( 800124 )
			Set_XSCRIPT_Parameter( 0, hid )
			Set_XSCRIPT_Parameter( 1, lid )
			Set_XSCRIPT_ParamCount(2)
		Send_XSCRIPT()
		m_Comfirmed = 0
		PetHuanhua_CleanUp()
	end
end

--Select Pet
function PetHuanhua_SelectPet_Clicked()
	Pet : ShowPetList( 0 )
	Pet : ShowPetList( 1 )
end

function PetHuanhua_Pet_Modle_TurnLeft( start )
	--向左旋转开始
	if start == 1 then
		PetHuanhua_FakeObject:RotateBegin(-0.3)
	--向左旋转结束
	else
		PetHuanhua_FakeObject:RotateEnd()
	end

end

function PetHuanhua_Pet_Modle_TurnRight( start )
	--向右旋转开始
	if start == 1 then
		PetHuanhua_FakeObject:RotateBegin(0.3)
	--向右旋转结束
	else
		PetHuanhua_FakeObject:RotateEnd()
	end
end

function PetHuanhua_OnHidden()
	PetHuanhua_CleanUp()
	Pet : ShowPetList( 0 )
end

function PetHuanhua_OnSelectPet(petIndex)
	
	if -1 == petIndex then
		return
	end
	
	--珍兽已被其它界面选中
	if Pet:GetPetLocation(petIndex) ~= -1 then
		return
	end

	m_Comfirmed = 0

	--判断是否珍兽加锁
	if PlayerPackage:IsPetLock(petIndex) == 1 then
		PushDebugMessage("#{ZSYH_170111_28}")
		return
	end
	
		--判断是否珍兽出战
	if Pet:GetIsFighting(petIndex) == 1 then
		PushDebugMessage("#{ZSYH_170111_4}")
		return
	end
	
		--附体
	local petname,status = Pet:GetPetList_Appoint(petIndex)
	if status == "on_possession" then
		PushDebugMessage("#{ZSYH_170111_5}")
		return
	end
		
	--珍兽身上有装备	
	if Pet:IsPetHaveEquip(petIndex) == 1 then
		PushDebugMessage("#{ZSYH_170111_29}")	--请先将珍兽装备卸下
		return
	end
	
	--有内丹限制操作 Vega
	if Pet:LuaFnIsPetEquipNeiDan(petIndex) == 1 then
		PushDebugMessage("#{ZSND_230428_131}")
		return
	end
	
	--已幻化
	local gen = Pet:GetType(petIndex)
	if gen ~= nil and gen >= 100 then	--100以上为幻化珍兽
		PushDebugMessage("#{RXZS_090804_3}")    --你选择的珍兽已经完成幻化，不能再次幻化。
		return
	end
	
	--类型不符	
	local isCan = Pet:EnableHuanhua(petIndex)
	if isCan ~= 1 then 
		PushDebugMessage("#{RXZS_090804_5}")   --你选择的珍兽不符合幻化要求。
		return
	end
	
	--跟骨不足
	local savvy = Pet:GetSavvy(petIndex)
	if savvy ~= nil and savvy < 5 then
		PushDebugMessage("#{RXZS_090804_4}")    --你的珍兽悟性等级不足5级，不能进行幻化。
		return
	end

	local nHuanlingId = Pet:GetHuanlingIdByIndex(petIndex)
	if nHuanlingId >= 0 then
		PushDebugMessage("#{ZSHP_180814_137}")    --幻灵珍兽不能幻化
		return
	end
	 
	PetHuanhua_FakeObject:SetFakeObject("")
	Pet:SetSkillStudyModel(petIndex)
	
	PetHuanhua_FakeObject:SetFakeObject("My_PetStudySkill")
	
	--切换珍兽的时候，释放上一个珍兽
	if m_PetIndex ~= -1 then
		Pet:SetPetLocation(m_PetIndex,-1)
	end

	m_PetIndex = petIndex	--已经选好了珍兽
	Pet:SetPetLocation(m_PetIndex,5)
	PetHuanhua_UICheck()
end
	

function PetHuanhua_CleanUp()
	
	Pet:SetPetLocation(m_PetIndex,-1)
	m_PetIndex = -1
	
	PetHuanhua_FakeObject:SetFakeObject("")
	
	PetHuanhua_Money:SetProperty("MoneyNumber", 0)
	PetHuanhua_Pet_Text:SetText("")
	PetHuanhua_OK:Disable()
	m_Comfirmed = 0
	PetHuanhua_Blank_ButtonCheck:SetCheck(g_PetHuanhua_YuanbaoPay)
end

function PetHuanhua_UICheck()
	
	if  m_PetIndex ~= -1 then
		local isMoneyEnough = 0
		
		local szPetName,szOn = Pet:GetPetList_Appoint(m_PetIndex)
		if  szOn ~= "on_huanhua"  then 
			PetHuanhua_CleanUp()
			return
		end
		PetHuanhua_SelfMoney:SetProperty("MoneyNumber", Player:GetData("MONEY") )
		PetHuanhua_SelfJiaozi:SetProperty("MoneyNumber", Player:GetData("MONEY_JZ")  )
		
		local strName , strName2 = Pet:GetName(m_PetIndex)
		PetHuanhua_Pet_Text:SetText(strName)	

		m_needMoney = Pet:GetHuanhuaMoney(m_PetIndex)
		if m_needMoney ~= nil then
			PetHuanhua_Money:SetProperty("MoneyNumber", m_needMoney )
			local selfMoney = Player:GetData("MONEY") + Player:GetData("MONEY_JZ") 
			if selfMoney >= m_needMoney then
				isMoneyEnough = 1
			end
		end
		
		if isMoneyEnough == 1 then
			PetHuanhua_OK:Enable()
		else
			PetHuanhua_OK:Disable()
		end
	else
		PetHuanhua_Money:SetProperty("MoneyNumber", 0)
		PetHuanhua_Pet_Text:SetText("")
		PetHuanhua_OK:Disable()
	end
end

--Care Obj
function PetHuanhua_BeginCareObj(obj_id)
	
	m_ObjCared = DataPool:GetNPCIDByServerID(obj_id)
	this:CareObject(m_ObjCared, 1)
end

function PetHuanhua_Frame_On_ResetPos()
  PetHuanhua_Frame:SetProperty("UnifiedPosition", g_PetHuanhua_Frame_UnifiedPosition)
end

function PetSkillStudy_Blank_ButtonClick()
	g_PetHuanhua_YuanbaoPay = PetHuanhua_Blank_ButtonCheck:GetCheck()
end