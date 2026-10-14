local m_UI_NUM = 880053001	--珍兽炼化

local m_PetIndex = -1
local m_ObjCared = -1
local m_needMoney = 1000000
local m_Comfirmed = 0

local m_PetGuid = { HGuid = 0 , LGuid = 0}
local g_PetLianHua_Frame_UnifiedPosition

local g_PetLianHua_YuanbaoPay = 1 

--品质
local g_Quality_Str = {
	"#{ZSHP_180814_156}",
	"#{ZSHP_180814_155}",
	"#{ZSHP_180814_154}",
	"#{ZSHP_180814_153}",
	"#{ZSHP_180814_152}",
	"#{ZSHP_180814_151}",
	"#{ZSHP_180814_150}",
}

local g_NumToStrTable =
{
	"#{JJKHD_120808_64}",		--零
	"#{JJKHD_120808_65}",		--一
	"#{JJKHD_120808_66}",		--二
	"#{JJKHD_120808_67}",
	"#{JJKHD_120808_68}",		--四
	"#{JJKHD_120808_69}",
	"#{JJKHD_120808_70}",
	"#{JJKHD_120808_71}",
	"#{JJKHD_120808_72}",
	"#{JJKHD_120808_73}",
	"#{JJKHD_120808_74}",
}

local g_GrowLevelText = 
{
	[0] = "#{ZSHP_190716_07}",
	[1] = "#{ZSHP_190716_21}",
	[2] = "#{ZSHP_190716_22}",
	[3] = "#{ZSHP_190716_23}",
	[4] = "#{ZSHP_190716_24}",
	[5] = "#{ZSHP_190716_25}",

}

local g_GrowLevelTextNoColor = 
{
	[1] = "#{ZSHP_190716_21}",
	[2] = "#{ZSHP_190716_22}",
	[3] = "#{ZSHP_190716_23}",
	[4] = "#{ZSHP_190716_24}",
	[5] = "#{ZSHP_190716_25}",

}

local PET_JINJIE_LIMIT_BYTLVL = 55
local PET_JINJIELVL_MAXGRADE	= 10

local g_ApplyState = 0

function PetLianHua_PreLoad()
	this : RegisterEvent( "UI_COMMAND" )
	this : RegisterEvent( "REPLY_MISSION_PET" )						-- 玩家从列表选定一只珍兽
	this : RegisterEvent( "UPDATE_PET_PAGE" )						-- 玩家身上的珍兽数据发生变化，包括增加一只珍兽
	this : RegisterEvent( "DELETE_PET" )							-- 玩家身上减少一只珍兽
	this : RegisterEvent("MONEY_CHANGE_EX")
	this : RegisterEvent("MONEYJZ_CHANGE_EX")	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false) 
	this:RegisterEvent("PET_LIANHUA_CONFIRM_RET",false) 
end

function PetLianHua_OnLoad()	

	g_PetLianHua_Frame_UnifiedPosition = PetLianHua_Frame:GetProperty("UnifiedPosition")
end

function PetLianHua_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber( arg0 ) == m_UI_NUM then
		
		local flag = Get_XParam_INT(0)
		
		if flag == 1 then		
			if this:IsVisible() then
				g_ApplyState = Get_XParam_INT(1)
				return
			end
		else
			if this:IsVisible() then
				return
			end
			g_ApplyState = Get_XParam_INT(2)
			PetLianHua_BeginCareObj(Get_XParam_INT(1))
			PetLianHua_CleanUp()
			this:Show()
			Pet:ShowPetList(1)
			PetLianHua_Money1:SetProperty("MoneyNumber", "1000000")
			PetLianHua_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
			PetLianHua_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
		
		end
		
		
		

	elseif (event == "MONEY_CHANGE_EX" and this : IsVisible()) then
		PetLianHua_SelfMoney:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY")))
	elseif (event == "MONEYJZ_CHANGE_EX" and this : IsVisible()) then
		PetLianHua_SelfJiaozi:SetProperty("MoneyNumber", tostring(Player:GetData("MONEY_JZ")))
	elseif event == "REPLY_MISSION_PET" and this : IsVisible() then
		PetLianHua_OnSelectPet( tonumber( arg0 ) )
	elseif event == "UPDATE_PET_PAGE"  and this:IsVisible() then
		PetLianHua_CheckPet()
	elseif event == "ADJEST_UI_POS" then
		PetLianHua_Frame_On_ResetPos()	 
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		PetLianHua_Frame_On_ResetPos()	
	elseif event == "PET_LIANHUA_CONFIRM_RET" then
		m_Comfirmed = 1
	end

end

--Close
function PetLianHua_Close_Window()
	this:Hide()
end

--OK
function PetLianHua_OK_Clicked()
	
	if m_PetIndex == -1  then
		PushDebugMessage("#{ZSHP_180814_74}")
		return
	end
	
	-- 判断是否为安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
		return
	end	
	
	local hid,lid = Pet:GetGUID(m_PetIndex)
	if m_Comfirmed == 0 then
		Pet:Lua_LianHuaConfirm(m_PetIndex)
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "PetLianHua" )
			Set_XSCRIPT_ScriptID( 880053 )
			Set_XSCRIPT_Parameter( 0, hid )
			Set_XSCRIPT_Parameter( 1, lid )
			Set_XSCRIPT_ParamCount( 2 )
		Send_XSCRIPT()
		m_Comfirmed = 0
		this:Hide()
	end
end

--Select Pet
function PetLianHua_SelectPet_Clicked()
	Pet:ShowPetList(0)
	Pet:ShowPetList(1)
end

function PetLianHua_OnSelectPet(petIndex)
	
	if -1 == petIndex then
		return
	end	
	
	-- 判断是否为安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return
	end
	
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then			
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
	
	--已幻灵
	local nHuanLingId = Pet:GetHuanlingIdByIndex(petIndex)
	if nHuanLingId >= 0 then
		PushDebugMessage("#{ZSWG_181211_23}")	
		return
	end
	
	--幻化并且外观不是基础外观
	local nDataId = Pet:GetDataID(petIndex)
	if nDataId >= 25001 and nDataId <= 26999 then
		PushDebugMessage ("#{ZSWG_181211_24}")
		return
	end

	--不可炼化
	if Pet:Lua_IsEnableLianHua(petIndex) ~= 1 then 
		PushDebugMessage("#{ZSHP_180814_76}")
		return
	end
	
	local nGrowLevelDemand = Pet:Lua_GetLianHuaNeedGrowLevel(petIndex)
	if nGrowLevelDemand == nil then
		PushDebugMessage("#{ZSHP_180814_76}")
		return	
	end
	
	local petname,status = Pet:GetPetList_Appoint(petIndex)
	local nGrowRate = Pet:GetGrowRate(petIndex)
	local nGrowLevel = Pet:GetPetGrowLevel(petIndex,tonumber(nGrowRate))
	
	if nGrowLevel < 0 then			
		if nGrowLevelDemand >= 0 and g_GrowLevelTextNoColor[nGrowLevelDemand] then
			local strTemp = ScriptGlobal_Format("#{ZSHP_190716_20}", g_GrowLevelTextNoColor[nGrowLevelDemand])
			PushDebugMessage(strTemp)
			return
		end
	end
	
	nGrowLevel = nGrowLevel + 1
	if nGrowLevel < nGrowLevelDemand then
		if g_GrowLevelTextNoColor[nGrowLevelDemand] then
			local strTemp = ScriptGlobal_Format("#{ZSHP_190716_20}", g_GrowLevelTextNoColor[nGrowLevelDemand])
			PushDebugMessage(strTemp)
			return
		end
	end
	
	--判断是否珍兽出战
	if Pet:GetIsFighting(petIndex) == 1 then
		PushDebugMessage("#{ZSWG_181211_13}")
		return
	end
	
	--附体	
	if status == "on_possession" then
		PushDebugMessage("#{ZSWG_181211_22}")
		return
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
	
	--携带等级
	local nTakeLevel = Pet:GetTakeLevel(petIndex)
--	if nTakeLevel < 85 then
	--	PushDebugMessage("#{ZSHP_180814_75}")
	--	return
--	end	
	
	m_Comfirmed = 0
	
	PetLianHua_FakeObject:SetFakeObject("")
	Pet:SetSkillStudyModel(petIndex)

	PetLianHua_FakeObject:SetFakeObject( "My_PetStudySkill" )	
	
	--切换珍兽的时候，释放上一个珍兽
	if	m_PetIndex ~= -1 then
		Pet:SetPetLocation(m_PetIndex,-1)
	end

	m_PetIndex = petIndex	--已经选好了珍兽
	
	local guidH, guidL = Pet:GetGUID(petIndex)
	m_PetGuid.HGuid = guidH
	m_PetGuid.LGuid = guidL

	Pet:SetPetLocation(m_PetIndex,5)
	
	--贵重标志显示
	if PlayerPackage:IsGoodsProtect_Pet(m_PetIndex) == 1 then
	 	PetLianHua_Protect_Text:Show()
	else
	 	PetLianHua_Protect_Text:Hide()
	end
	
	--宠物名字显示
	PetLianHua_Pet_Text:SetText(tostring(petname))	
	
	--宠物类型显示
	local nType = Pet:GetPetType(m_PetIndex)	
	if nType == 0 then
		PetLianHua_Pet_Info:SetText("#{ZSHP_180814_60}")
	elseif nType == 1 then	
		local nVLevel = Pet:Lua_GetPetVarLevel(m_PetIndex)
		local str = ScriptGlobal_Format("#{ZSHP_180814_61}",tostring(nVLevel))
		PetLianHua_Pet_Info:SetText(str)		
	else
		PetLianHua_Pet_Info:SetText("")
	end
	
	local petQuality = Pet:GetPetQuality(m_PetIndex)
	if g_Quality_Str[petQuality] ~= nil then
		PetLianHua_Quality_Text:SetText(g_Quality_Str[petQuality])
	end
	
	local nJinJieGrade = Pet:GetJinJieGrade(m_PetIndex)
	local nJinJieLevel = Pet:GetJinJieLvl(m_PetIndex)
	
	if nTakeLevel < PET_JINJIE_LIMIT_BYTLVL then
		PetLianHua_Pet_JueXing:SetText("#{ZSHP_190716_14}")
	elseif nJinJieGrade == PET_JINJIELVL_MAXGRADE then
		PetLianHua_Pet_JueXing:SetText("#{ZSHP_190716_15}")
	elseif nJinJieGrade < PET_JINJIELVL_MAXGRADE then
		if g_NumToStrTable[nJinJieGrade + 1] ~= nil and g_NumToStrTable[nJinJieLevel + 1] ~= nil then
			local szCurJinJieInfo = ScriptGlobal_Format("#{ZSHP_190716_13}", g_NumToStrTable[nJinJieGrade + 1], g_NumToStrTable[nJinJieLevel + 1])
			PetLianHua_Pet_JueXing:SetText(szCurJinJieInfo)
		end
	end
	
	if nGrowLevel > 0 then
		if g_GrowLevelText[nGrowLevel] then
			local strGLevel = ScriptGlobal_Format("#{ZSHP_190716_06}", g_GrowLevelText[nGrowLevel],tostring(nGrowRate))
			PetLianHua_Pet_Grow2:SetText(strGLevel)
			PetLianHua_Pet_Grow:Show()
		end
	else
		local strGLevel = ScriptGlobal_Format("#{ZSHP_190716_06}", g_GrowLevelText[0],"")
		PetLianHua_Pet_Grow2:SetText(strGLevel)
		PetLianHua_Pet_Grow:Show()
	end
	
	PetLianHua_AtPresent_WuXinglevel:SetText("")
	PetLianHua_Need_WuXinglevel:SetText("")

	if nGrowLevelDemand > 0 and nGrowLevelDemand <= 5 then
		local strGLevel = ScriptGlobal_Format("#{ZSHP_190716_17}", g_GrowLevelText[nGrowLevelDemand])
		PetLianHua_Need_WuXinglevel:SetText(strGLevel)
	end
	
	if nGrowLevel > 0 and nGrowLevel <= 5 then
		local strGLevel = ScriptGlobal_Format("#{ZSHP_190716_17}", g_GrowLevelText[nGrowLevel])
		PetLianHua_AtPresent_WuXinglevel:SetText(strGLevel)	
	end
	
	PetLianHua_OK:Enable()
	
	Pet:UpdatePetList()
end

function PetLianHua_CheckPet()
	
	if m_PetIndex == -1 then
		return
	end

	m_PetIndex = Pet:GetPetIndexByGUID(m_PetGuid.HGuid, m_PetGuid.LGuid)
	
	if m_PetIndex == -1 then
		PetLianHua_CleanUp()
		return		
	end
	
	--判断是否珍兽加锁
	if PlayerPackage:IsPetLock(m_PetIndex) == 1 then
		PetLianHua_CleanUp()
		return
	end
	
	--已幻灵
	local nHuanLingId = Pet:GetHuanlingIdByIndex(m_PetIndex)
	if nHuanLingId >= 0 then
		PetLianHua_CleanUp()
		return
	end
	
	--幻化并且外观不是基础外观
	local nDataId = Pet:GetDataID(m_PetIndex)
	if nDataId >= 25001 and nDataId <= 26999 then
		PetLianHua_CleanUp()
		return
	end
	
	--判断是否珍兽出战
	if Pet:GetIsFighting(m_PetIndex) == 1 then
		PetLianHua_CleanUp()
		return
	end
	
	--附体
	local petname,status = Pet:GetPetList_Appoint(m_PetIndex)
	if status == "on_possession" then
		PetLianHua_CleanUp()
		return
	end
	
	--珍兽身上有装备
	if Pet:IsPetHaveEquip(m_PetIndex) == 1 then
		PetLianHua_CleanUp()
		return
	end
	
	--有内丹限制操作 Vega
	if Pet:LuaFnIsPetEquipNeiDan(m_PetIndex) == 1 then
		PetLianHua_CleanUp()
		return
	end
end

function PetLianHua_OnHidden()
	PetLianHua_CleanUp()
	Pet:ShowPetList(0)
end

function PetLianHua_CleanUp()
	
	if m_PetIndex ~= -1 then
		Pet:SetPetLocation(m_PetIndex,-1)
	end
	m_PetIndex = -1
	
	PetLianHua_FakeObject:SetFakeObject("")
	
	PetLianHua_Pet_Text:SetText("")
	PetLianHua_OK:Disable()
	
	PetLianHua_Protect_Text:Hide()
	
	PetLianHua_Pet_Info:SetText("")
	PetLianHua_Quality_Text:SetText("")
	
	PetLianHua_AtPresent_WuXinglevel:SetText("")
	PetLianHua_Need_WuXinglevel:SetText("")
	
	PetLianHua_Pet_JueXing:SetText("")
	PetLianHua_Pet_Grow2:SetText("")
	PetLianHua_Pet_Grow:Hide()
	
	PetLianHua_Money1:SetProperty("MoneyNumber", "0")
	
	m_Comfirmed = 0
	
end

function PetLianHua_Pet_Modle_TurnLeft( start )
	--向左旋转开始
	if(start == 1) then
		PetLianHua_FakeObject:RotateBegin(-0.3)
	--向左旋转结束
	else
		PetLianHua_FakeObject:RotateEnd()
	end

end

function PetLianHua_Pet_Modle_TurnRight( start )
	--向右旋转开始
	if(start == 1) then
		PetLianHua_FakeObject:RotateBegin(0.3)
	--向右旋转结束
	else
		PetLianHua_FakeObject:RotateEnd()
	end
end

--Care Obj
function PetLianHua_BeginCareObj(obj_id)
	
	m_ObjCared = DataPool : GetNPCIDByServerID(obj_id)
	this:CareObject(m_ObjCared, 1)
end

function PetLianHua_Frame_On_ResetPos()
  PetLianHua_Frame:SetProperty("UnifiedPosition", g_PetLianHua_Frame_UnifiedPosition)
end
