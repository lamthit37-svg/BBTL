
--!!!reloadscript =Nianshou_NingYu

local m_PetIndex = -1
local m_ObjCared = -1
local m_Comfirmed = 0
local g_Nianshou_NingYu_Frame_UnifiedPosition
local g_NianShou_PetDataId = {8834, 8844, 8845, 8854, 8855, 8856, 8864, 8865, 8866, 8867, 8874, 8875, 8876, 8877, 8878}

local m_PetGuidH = 0
local m_petGuidL = 0

function Nianshou_NingYu_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("REPLY_MISSION_PET")						-- 玩家从列表选定一只珍兽
	this:RegisterEvent("UPDATE_PET_PAGE")						-- 玩家身上的珍兽数据发生变化，包括增加一只珍兽
	this:RegisterEvent("DELETE_PET")							-- 玩家身上减少一只珍兽
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	this:RegisterEvent("OPEN_STALL_SALE",false)
end

function Nianshou_NingYu_OnLoad()	

	g_Nianshou_NingYu_Frame_UnifiedPosition = Nianshou_NingYu_Frame:GetProperty("UnifiedPosition")
end

function Nianshou_NingYu_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber( arg0 ) == 880055001 then
		
		if this:IsVisible() then
			if not IsWindowShow("PetList") then
				Pet:ShowPetList(1)
			end	
			return
		end

		Nianshou_NingYu_BeginCareObj( Get_XParam_INT(0) )
		Nianshou_NingYu_CleanUp()
		this:Show()
		Pet:ShowPetList(1)
		Nianshou_NingYu_Item:SetActionItem(-1)
		local theAction = DataPool:CreateActionItemForShow(39921648, 1)
		Nianshou_NingYu_Item:SetActionItem(theAction:GetID())
		
	elseif	event == "UI_COMMAND" and tonumber(arg0) == 880055002 then
		
		if m_PetIndex ~= -1 then
			local hid,lid = Pet:GetGUID(m_PetIndex)	
			local sHid = Get_XParam_INT(0)
			local sLid = Get_XParam_INT(1)
			
			if hid == sHid and lid == sLid then				
				Pet:Lua_NianShouNingYuConfirm(m_PetIndex)
				m_Comfirmed = 1
			end
		end
		return
	elseif event == "REPLY_MISSION_PET" and this : IsVisible() then
		Nianshou_NingYu_OnSelectPet( tonumber( arg0 ) )
	elseif event == "UPDATE_PET_PAGE"  and this:IsVisible() then	
		Nianshou_NingYu_UpdateUI()
		return
	elseif event == "DELETE_PET"  and this:IsVisible() then
		Nianshou_NingYu_CleanUp()
		return
	elseif event == "ADJEST_UI_POS" then
		Nianshou_NingYu_Frame_On_ResetPos()	 
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Nianshou_NingYu_Frame_On_ResetPos()	
	elseif event == "OPEN_STALL_SALE" then
		this:Hide()
	end

end

--Close
function Nianshou_NingYu_Close()
	this:Hide()
end

--OK
function Nianshou_NingYu_OK_Clicked()
	
	if not IsWindowShow("PetList") then
		Pet:ShowPetList(1)
	end	
	
	local hid = 0
	local lid = 0
	
	if m_PetIndex ~= -1  then
		hid,lid = Pet:GetGUID(m_PetIndex)
	end	
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "NingYu" )
		Set_XSCRIPT_ScriptID( 880055 )
		Set_XSCRIPT_Parameter( 0, hid )
		Set_XSCRIPT_Parameter( 1, lid )
		Set_XSCRIPT_Parameter( 2, m_Comfirmed )
		Set_XSCRIPT_ParamCount( 3 )
	Send_XSCRIPT()
end

--Select Pet
function Nianshou_NingYu_SelectPet_Clicked()
	Pet:ShowPetList(0)
	Pet:ShowPetList(1)
end

function Nianshou_NingYu_OnSelectPet(petIndex)
	
	if -1 == petIndex then
		return
	end
	
	--珍兽已被其它界面选中
	if Pet:GetPetLocation(petIndex) ~= -1 then
		return
	end

	--判断是否珍兽加锁
	if PlayerPackage:IsPetLock(petIndex) == 1 then
		PushDebugMessage("#{ZSWG_181211_25}")
		return
	end
	
	--判断是否珍兽出战
	if Pet:GetIsFighting(petIndex) == 1 then
		PushDebugMessage("#{ZSWG_181211_21}")
		return
	end
	
	--附体
	local petname,status = Pet:GetPetList_Appoint(petIndex)
	if status == "on_possession" then
		PushDebugMessage("#{ZSWG_181211_22}")
		return 0
	end	
	
	--珍兽身上有装备	
	if Pet:IsPetHaveEquip(petIndex) == 1 then
		PushDebugMessage("#{ZSWG_181211_115}")
		return
	end
	
	--有内丹限制操作 Vega
	if Pet:LuaFnIsPetEquipNeiDan(petIndex) == 1 then
		PushDebugMessage("#{ZSND_230428_131}")
		return
	end
	
	--幻化并且外观不是基础外观
	local nDataId = Pet:GetDataID(petIndex)
	if nDataId >= 25001 and nDataId <= 26999 then
		PushDebugMessage ("#{ZSWG_181211_24}")
		return
	end
	
	--是不是可以凝玉的年兽
	local nDataId = Pet:GetDataID(petIndex)
	if Nianshou_IsNianShou(nDataId) ~= 1 then
		PushDebugMessage ("#{ZSWG_181211_17}")
		return
	end

	--已幻灵
	local nHuanLingId = Pet:GetHuanlingIdByIndex(petIndex)
	if nHuanLingId >= 0 then
		PushDebugMessage("#{ZSWG_181211_23}")	
		return
	end
		
	--成长率判断
	local nGrowRate = Pet:GetGrowRate(petIndex)
	local nGrowLevel = Pet:GetPetGrowLevel(petIndex,tonumber(nGrowRate))
	if nGrowLevel < 3 then
		PushDebugMessage ("#{ZSWG_181211_27}")
		return
	end
	
	m_Comfirmed = 0
	
	Nianshou_NingYu_FakeObject:SetFakeObject("")
	Pet:SetSkillStudyModel(petIndex)

	Nianshou_NingYu_FakeObject:SetFakeObject( "My_PetStudySkill" )	
	
	--切换珍兽的时候，释放上一个珍兽
	if	m_PetIndex ~= -1 then
		Pet:SetPetLocation(m_PetIndex,-1)
	end

	m_PetIndex = petIndex	--已经选好了珍兽
	m_PetGuidH,m_PetGuidL = Pet:GetGUID(m_PetIndex)
	
	Pet:SetPetLocation(m_PetIndex,1274)
	
	Nianshou_NingYu_OK:Enable()
	
	--贵重标志显示
	if PlayerPackage:IsGoodsProtect_Pet(m_PetIndex) == 1 then
	 	Nianshou_NingYu_FakeObject_Protect_Text:Show()
	else
	 	Nianshou_NingYu_FakeObject_Protect_Text:Hide()
	end
	
	local nTakeLevel = Pet:GetTakeLevel(m_PetIndex)
	local nJinJieGrade = Pet:GetJinJieGrade(m_PetIndex)
	local nJinJieLevel = Pet:GetJinJieLvl(m_PetIndex)
	if nTakeLevel < 55 then
		Nianshou_NingYu_FakeObject_JueXing_Text:SetText("#{ZSWG_181211_110}")
	elseif nJinJieGrade == 10 then
		Nianshou_NingYu_FakeObject_JueXing_Text:SetText("#{ZSWG_181211_111}")
	elseif nJinJieGrade < 10 then
		local szCurJinJieInfo = ScriptGlobal_Format("#{ZSWG_181211_109}", tostring(nJinJieGrade), tostring(nJinJieLevel))
		Nianshou_NingYu_FakeObject_JueXing_Text:SetText(szCurJinJieInfo)
	end
	Nianshou_NingYu_FakeObject_JueXing_Text:Show()
	
	
	local nType = Pet:GetPetType(m_PetIndex)	
	if nType == 1 then	
		local nVLevel = Pet:Lua_GetPetVarLevel(m_PetIndex)
		local strVLevel = ScriptGlobal_Format("#{ZSWG_181211_100}",tostring(nVLevel))
		Nianshou_NingYu_FakeObject_BianYi_Text:SetText(strVLevel)
		Nianshou_NingYu_FakeObject_BianYi_Text:Show()
	else
		Nianshou_NingYu_FakeObject_BianYi_Text:Hide()
	end
	
	if nGrowLevel == 3 then
		local strGrow = ScriptGlobal_Format("#{ZSWG_181211_101}","#{ZSWG_181211_106}",tostring(nGrowRate))
		Nianshou_NingYu_FakeObject_ChengZhang_Text1:SetText(strGrow)
		Nianshou_NingYu_FakeObject_ChengZhang_Text1:Show()
		Nianshou_NingYu_FakeObject_ChengZhang_Text0:Show()
	elseif nGrowLevel == 4 then
		local strGrow = ScriptGlobal_Format("#{ZSWG_181211_101}","#{ZSWG_181211_107}",tostring(nGrowRate))
		Nianshou_NingYu_FakeObject_ChengZhang_Text1:SetText(strGrow)
		Nianshou_NingYu_FakeObject_ChengZhang_Text1:Show()
		Nianshou_NingYu_FakeObject_ChengZhang_Text0:Show()
	else
		Nianshou_NingYu_FakeObject_ChengZhang_Text1:Hide()
		Nianshou_NingYu_FakeObject_ChengZhang_Text0:Hide()
	end	
	
end

function Nianshou_NingYu_UpdateUI()
	
	
	if m_PetIndex == -1 then
		return	
	end
	
	local hid , lid = Pet:GetGUID(m_PetIndex)	
	if m_PetGuidH ~= hid or m_PetGuidL ~= lid then
		Nianshou_NingYu_CleanUp()
		return
	end
	
	--珍兽已被其它界面选中
	if Pet:GetPetLocation(m_PetIndex) ~= -1 then
		Nianshou_NingYu_CleanUp()
		return
	end

	--判断是否珍兽加锁
	if PlayerPackage:IsPetLock(m_PetIndex) == 1 then
		Nianshou_NingYu_CleanUp()
		return
	end
	
	--判断是否珍兽出战
	if Pet:GetIsFighting(m_PetIndex) == 1 then
		Nianshou_NingYu_CleanUp()
		return
	end
	
	--附体
	local petname,status = Pet:GetPetList_Appoint(m_PetIndex)
	if status == "on_possession" then
		Nianshou_NingYu_CleanUp()
		return 0
	end	
	
	--珍兽身上有装备	
	if Pet:IsPetHaveEquip(m_PetIndex) == 1 then
		Nianshou_NingYu_CleanUp()
		return
	end
	
	--有内丹限制操作 Vega
	if Pet:LuaFnIsPetEquipNeiDan(m_PetIndex) == 1 then
		Nianshou_NingYu_CleanUp()
		return
	end
	
	--是不是可以凝玉的年兽
	local nDataId = Pet:GetDataID(m_PetIndex)
	if Nianshou_IsNianShou(nDataId) ~= 1 then
		Nianshou_NingYu_CleanUp()
		return
	end

	--已幻灵
	local nHuanLingId = Pet:GetHuanlingIdByIndex(m_PetIndex)
	if nHuanLingId >= 0 then
		Nianshou_NingYu_CleanUp()
		return
	end
	
	--幻化并且外观不是基础外观
	local nDataId = Pet:GetDataID(m_PetIndex)
	if nDataId >= 25001 and nDataId <= 26999 then
		Nianshou_NingYu_CleanUp()
		return
	end
	
	--成长率判断
	local nGrowRate = Pet:GetGrowRate(m_PetIndex)
	local nGrowLevel = Pet:GetPetGrowLevel(m_PetIndex,tonumber(nGrowRate))
	if nGrowLevel < 3 then
		Nianshou_NingYu_CleanUp()
		return
	end	
	
	Nianshou_NingYu_FakeObject:SetFakeObject("")
	Pet:SetSkillStudyModel(petIndex)

	Nianshou_NingYu_FakeObject:SetFakeObject( "My_PetStudySkill" )	
	
	--切换珍兽的时候，释放上一个珍兽
	if	m_PetIndex ~= -1 then
		Pet:SetPetLocation(m_PetIndex,-1)
	end
	
	Pet:SetPetLocation(m_PetIndex,1274)
	
	Nianshou_NingYu_OK:Enable()
	
	--贵重标志显示
	if PlayerPackage:IsGoodsProtect_Pet(m_PetIndex) == 1 then
	 	Nianshou_NingYu_FakeObject_Protect_Text:Show()
	else
	 	Nianshou_NingYu_FakeObject_Protect_Text:Hide()
	end
	
	local nTakeLevel = Pet:GetTakeLevel(m_PetIndex)
	local nJinJieGrade = Pet:GetJinJieGrade(m_PetIndex)
	local nJinJieLevel = Pet:GetJinJieLvl(m_PetIndex)
	if nTakeLevel < 55 then
		Nianshou_NingYu_FakeObject_JueXing_Text:SetText("#{ZSWG_181211_110}")
	elseif nJinJieGrade == 10 then
		Nianshou_NingYu_FakeObject_JueXing_Text:SetText("#{ZSWG_181211_111}")
	elseif nJinJieGrade < 10 then
		local szCurJinJieInfo = ScriptGlobal_Format("#{ZSWG_181211_109}", tostring(nJinJieGrade), tostring(nJinJieLevel))
		Nianshou_NingYu_FakeObject_JueXing_Text:SetText(szCurJinJieInfo)
	end
	Nianshou_NingYu_FakeObject_JueXing_Text:Show()
	
	
	local nType = Pet:GetPetType(m_PetIndex)	
	if nType == 1 then	
		local nVLevel = Pet:Lua_GetPetVarLevel(m_PetIndex)
		local strVLevel = ScriptGlobal_Format("#{ZSWG_181211_100}",tostring(nVLevel))
		Nianshou_NingYu_FakeObject_BianYi_Text:SetText(strVLevel)
		Nianshou_NingYu_FakeObject_BianYi_Text:Show()
	else
		Nianshou_NingYu_FakeObject_BianYi_Text:Hide()
	end
	
	if nGrowLevel == 3 then
		local strGrow = ScriptGlobal_Format("#{ZSWG_181211_101}","#{ZSWG_181211_106}")
		Nianshou_NingYu_FakeObject_ChengZhang_Text1:SetText(strGrow)
		Nianshou_NingYu_FakeObject_ChengZhang_Text1:Show()
		Nianshou_NingYu_FakeObject_ChengZhang_Text0:Show()
	elseif nGrowLevel == 4 then
		local strGrow = ScriptGlobal_Format("#{ZSWG_181211_101}","#{ZSWG_181211_107}")
		Nianshou_NingYu_FakeObject_ChengZhang_Text1:SetText(strGrow)
		Nianshou_NingYu_FakeObject_ChengZhang_Text1:Show()
		Nianshou_NingYu_FakeObject_ChengZhang_Text0:Show()
	else
		Nianshou_NingYu_FakeObject_ChengZhang_Text1:Hide()
		Nianshou_NingYu_FakeObject_ChengZhang_Text0:Hide()
	end	
end

function Nianshou_IsNianShou(pet_data_id)
	
	for i = 1 ,table.getn(g_NianShou_PetDataId) do
		if g_NianShou_PetDataId[i] == pet_data_id then
			return 1
		end
	end
	
	return 0
end

function Nianshou_NingYu_OnHidden()
	Nianshou_NingYu_CleanUp()
	Pet:ShowPetList(0)
end

function Nianshou_NingYu_CleanUp()
	
	Pet:SetPetLocation(m_PetIndex,-1)
	m_PetIndex = -1
	m_PetGuidH = 0
	m_PetGuidL = 0
	
	Nianshou_NingYu_FakeObject:SetFakeObject("")
	
	m_Comfirmed = 0
	
	Nianshou_NingYu_FakeObject_Protect_Text:Hide()
	Nianshou_NingYu_FakeObject_JueXing_Text:Hide()
	Nianshou_NingYu_FakeObject_BianYi_Text:Hide()
	Nianshou_NingYu_FakeObject_ChengZhang_Text1:Hide()
	Nianshou_NingYu_FakeObject_ChengZhang_Text0:Hide()
end

function Nianshou_NingYu_Pet_Modle_TurnLeft( start )
	--向左旋转开始
	if(start == 1) then
		Nianshou_NingYu_FakeObject:RotateBegin(-0.3)
	--向左旋转结束
	else
		Nianshou_NingYu_FakeObject:RotateEnd()
	end

end

function Nianshou_NingYu_Pet_Modle_TurnRight( start )
	--向右旋转开始
	if(start == 1) then
		Nianshou_NingYu_FakeObject:RotateBegin(0.3)
	--向右旋转结束
	else
		Nianshou_NingYu_FakeObject:RotateEnd()
	end
end

--Care Obj
function Nianshou_NingYu_BeginCareObj(obj_id)
	
	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id)
	this:CareObject(m_ObjCared, 1)
end

function Nianshou_NingYu_Frame_On_ResetPos()
  Nianshou_NingYu_Frame:SetProperty("UnifiedPosition", g_Nianshou_NingYu_Frame_UnifiedPosition)
end

--!!!reloadscript =Nianshou_NingYu