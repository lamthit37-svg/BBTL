--!!!reloadscript =OtherPetNeidan

local g_OtherPetNeidan_Frame_UnifiedPosition = ""

local g_PetMaxNumber = 10

local g_CurrentSelectPet = -1
local g_MaxNeiDanBagSize = 60

local g_MaxPetSkill = 12
local g_PetSkillAct = {}
local g_SkillFixTip = {}

local g_MaxEquipNeiDanCount = 7
local g_PetNeiDanAct = {}
local g_PetNeiDanAct_Lock = {}
local g_PetNeiDanAct_NoEffect = {}
local g_PetNeiDanAct_Level = {}

local g_NeiDanSlotInfo = {
	[1] = {savvy = 4, lx = 4},
	[2] = {savvy = 7, lx = 7},
	[3] = {savvy = 10, lx = 10},
	[4] = {savvy = 4, lx = 4},
	[5] = {savvy = 7, lx = 7},
	[6] = {savvy = 10, lx = 10},
	[7] = {savvy = 4, lx = 4}
}

local g_PreMissionID = 3000

local g_PlayerLevelLimit = 60
local g_PetLevelLimit = 60

local g_PND_Level_Image = {
	"set:PetNeidan image:Item1",
	"set:PetNeidan image:Item2",
	"set:PetNeidan image:Item3",
	"set:PetNeidan image:Item4",
	"set:PetNeidan image:Item5",
}

local g_EffectText = {}
local g_EffectNumText = {}

local g_EffectName = {
	"#{ZSND_230428_37}",
	"#{ZSND_230428_39}",
	"#{ZSND_230428_38}",
	"#{ZSND_230428_42}",
	"#{ZSND_230428_41}",
	"#{ZSND_230428_40}",
}

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_OtherPetNeidan_Page = {
	[1] = {Text = "#{INTERFACE_XML_877}",		NeedCheck = 0, Tip = ""},
	[2] = {Text = "#{INTERFACE_XML_882}",		NeedCheck = 0, Tip = ""},
	[3] = {Text = "#{INTERFACE_XML_854}",		NeedCheck = 0, Tip = ""},
	[4] = {Text = "#{ZNJCS_130825_7}",			NeedCheck = 0, Tip = ""},
	[5] = {Text = "#{WH_xml_XX(95)}",			NeedCheck = 0, Tip = ""},
	[6] = {Text = "#{WLMJ_130121_54}",			NeedCheck = 0, Tip = ""},
	[7] = {Text = "#{ZYXT_120528_154}",			NeedCheck = 0, Tip = ""},
	[8] = {Text = "#{MPJJ_XT_XML_01}",  	 	NeedCheck = 0, Tip = ""},
	[9] = {Text = "#{XLDL_140606_04}",			NeedCheck = 0, Tip = ""},
	[10] = {Text = "#{JXJW_140822_22}",  	 	NeedCheck = 0, Tip = ""},
	[11] = {Text = "#{ZZZB_150811_113}",		NeedCheck = 0, Tip = ""},
	[12] = {Text = "#{WYXT_20170807_86}",		NeedCheck = 0, Tip = ""},
	[13] = {Text = "#{JXSQ_170829_216}",		NeedCheck = 0, Tip = ""},
	[14] = {Text = "#{NJBZ_220816_11}",			NeedCheck = 0, Tip = ""},
	[15] = {Text = "#{CPSJ_260112_1}",			NeedCheck = 0, Tip = ""},
}

local g_OtherPageButton = {}
local g_OtherPageCount = 0
local g_OtherPageOrder = {}

function OtherPetNeidan_PreLoad()
	this:RegisterEvent("OPEN_OTHER_PET_NEIDAN", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("PLAYER_ENTERING_WORLD", false)
end

function OtherPetNeidan_OnLoad()

	g_OtherPetNeidan_Frame_UnifiedPosition = OtherPetNeidan_Frame:GetProperty("UnifiedPosition")
	
	g_PetSkillAct[1] = OtherPetNeidan_Skill1
	g_PetSkillAct[2] = OtherPetNeidan_Skill2
	g_PetSkillAct[3] = OtherPetNeidan_Skill3
	g_PetSkillAct[4] = OtherPetNeidan_Skill4
	g_PetSkillAct[5] = OtherPetNeidan_Skill5
	g_PetSkillAct[6] = OtherPetNeidan_Skill6
	g_PetSkillAct[7] = OtherPetNeidan_Skill7
	g_PetSkillAct[8] = OtherPetNeidan_Skill8
	g_PetSkillAct[9] = OtherPetNeidan_Skill9
	g_PetSkillAct[10] = OtherPetNeidan_Skill10
	g_PetSkillAct[11] = OtherPetNeidan_Skill11
	g_PetSkillAct[12] = OtherPetNeidan_Skill12
	
	g_SkillFixTip[1] = OtherPetNeidan_Skill1_Mask
	g_SkillFixTip[2] = OtherPetNeidan_Skill2_Mask
	g_SkillFixTip[3] = OtherPetNeidan_Skill3_Mask
	g_SkillFixTip[4] = OtherPetNeidan_Skill4_Mask
	g_SkillFixTip[5] = OtherPetNeidan_Skill5_Mask
	g_SkillFixTip[6] = OtherPetNeidan_Skill6_Mask
	g_SkillFixTip[7] = OtherPetNeidan_Skill7_Mask
	g_SkillFixTip[8] = OtherPetNeidan_Skill8_Mask
	g_SkillFixTip[9] = OtherPetNeidan_Skill9_Mask
	g_SkillFixTip[10] = OtherPetNeidan_Skill10_Mask
	g_SkillFixTip[11] = OtherPetNeidan_Skill11_Mask
	g_SkillFixTip[12] = OtherPetNeidan_Skill12_Mask
	
	g_PetNeiDanAct[1] = OtherPetNeidan_BK1_Icon1
	g_PetNeiDanAct[2] = OtherPetNeidan_BK1_Icon2
	g_PetNeiDanAct[3] = OtherPetNeidan_BK1_Icon3
	g_PetNeiDanAct[4] = OtherPetNeidan_BK1_Icon4
	g_PetNeiDanAct[5] = OtherPetNeidan_BK1_Icon5
	g_PetNeiDanAct[6] = OtherPetNeidan_BK1_Icon6
	g_PetNeiDanAct[7] = OtherPetNeidan_BK1_Icon7
	
	g_PetNeiDanAct_Lock[1] = OtherPetNeidan_BK1_Icon1_Lock
	g_PetNeiDanAct_Lock[2] = OtherPetNeidan_BK1_Icon2_Lock
	g_PetNeiDanAct_Lock[3] = OtherPetNeidan_BK1_Icon3_Lock
	g_PetNeiDanAct_Lock[4] = OtherPetNeidan_BK1_Icon4_Lock
	g_PetNeiDanAct_Lock[5] = OtherPetNeidan_BK1_Icon5_Lock
	g_PetNeiDanAct_Lock[6] = OtherPetNeidan_BK1_Icon6_Lock
	g_PetNeiDanAct_Lock[7] = OtherPetNeidan_BK1_Icon7_Lock
	
	g_PetNeiDanAct_NoEffect[1] = OtherPetNeidan_BK1_Icon1_Cornermark
	g_PetNeiDanAct_NoEffect[2] = OtherPetNeidan_BK1_Icon2_Cornermark
	g_PetNeiDanAct_NoEffect[3] = OtherPetNeidan_BK1_Icon3_Cornermark
	g_PetNeiDanAct_NoEffect[4] = OtherPetNeidan_BK1_Icon4_Cornermark
	g_PetNeiDanAct_NoEffect[5] = OtherPetNeidan_BK1_Icon5_Cornermark
	g_PetNeiDanAct_NoEffect[6] = OtherPetNeidan_BK1_Icon6_Cornermark
	g_PetNeiDanAct_NoEffect[7] = OtherPetNeidan_BK1_Icon7_Cornermark
	
	g_PetNeiDanAct_Level[1] = OtherPetNeidan_BK1_Icon1_Jie
	g_PetNeiDanAct_Level[2] = OtherPetNeidan_BK1_Icon2_Jie
	g_PetNeiDanAct_Level[3] = OtherPetNeidan_BK1_Icon3_Jie
	g_PetNeiDanAct_Level[4] = OtherPetNeidan_BK1_Icon4_Jie
	g_PetNeiDanAct_Level[5] = OtherPetNeidan_BK1_Icon5_Jie
	g_PetNeiDanAct_Level[6] = OtherPetNeidan_BK1_Icon6_Jie
	g_PetNeiDanAct_Level[7] = OtherPetNeidan_BK1_Icon7_Jie
	
	g_EffectText[1] = OtherPetNeidan_NumListInfo1
	g_EffectText[2] = OtherPetNeidan_NumList2Info
	g_EffectText[3] = OtherPetNeidan_NumList3Info
	g_EffectText[4] = OtherPetNeidan_NumList4Info
	g_EffectText[5] = OtherPetNeidan_NumList5Info
	g_EffectText[6] = OtherPetNeidan_NumList6Info
	
	g_EffectNumText[1] = OtherPetNeidan_NumListInfo2
	g_EffectNumText[2] = OtherPetNeidan_NumList2Info2
	g_EffectNumText[3] = OtherPetNeidan_NumList3Info2
	g_EffectNumText[4] = OtherPetNeidan_NumList4Info2
	g_EffectNumText[5] = OtherPetNeidan_NumList5Info2
	g_EffectNumText[6] = OtherPetNeidan_NumList6Info2
	
	g_OtherPageButton[1] = OtherPetNeidan_Equip
	g_OtherPageButton[2] = OtherPetNeidan_Data
	g_OtherPageButton[3] = OtherPetNeidan_Pet
	g_OtherPageButton[4] = OtherPetNeidan_Infant
	g_OtherPageButton[5] = OtherPetNeidan_Wuhun
	g_OtherPageButton[6] = OtherPetNeidan_Miji
	g_OtherPageButton[7] = OtherPetNeidan_ZhenYuan
	g_OtherPageButton[8] = OtherPetNeidan_JingMai
	g_OtherPageButton[9] = OtherPetNeidan_ShenDing
	g_OtherPageButton[10] = OtherPetNeidan_JueWei
	g_OtherPageButton[11] = OtherPetNeidan_BaoJian
	g_OtherPageButton[12] = OtherPetNeidan_WuYi
	g_OtherPageButton[13] = OtherPetNeidan_ShenQi
	g_OtherPageButton[14] = OtherPetNeidan_Armor
	g_OtherPageButton[15] = OtherPetNeidan_CangPin
	
end

function OtherPetNeidan_OnEvent(event)
	if event == "OPEN_OTHER_PET_NEIDAN" then
		
		if Player:GetData("IsOriginalJD") == 1 then
			return
		end
		
		if Player:GetData("Is2606S") == 1 then
			return
		end
		
		if not CachedTarget:IsPresent(1) then
			return
		end
		
		if not CachedTarget:CanGetTargetEquip() then
			PushDebugMessage("#{JSCK_90507_1}")		--距离该玩家太远，无法查看资料。
			return
		end
		
		local objCared = CachedTarget:GetData("NPCID", 1)
		if tonumber(objCared) == nil then
			PushDebugMessage ("#{JSCK_90507_1}")	--距离该玩家太远，无法查看资料。
			return
		end
		
		this:CareObject(objCared , 1)

		this:Show()
		OtherPetNeidan_FakeObject:AttachWindowEx("My_OtherPet")
		g_CurrentSelectPet = -1
		OtherPetNeidan_Update()
		OtherPetNeidan_ShowPage()
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		OtherPetNeidan_Frame_On_ResetPos()
		return
	end

	if event == "PLAYER_ENTERING_WORLD" then
		if this:IsVisible() then
			this:Hide()
		end
		return
	end
	
end

function OtherPetNeidan_CleanUp()
	OtherPetNeidan_Frame_Client_Button04:SetCheck(1)
	OtherPetNeidan_Pet:SetCheck(1)
	g_CurrentSelectPet = -1
	OtherPetNeidan_KongWei_Class:SetText("")
end

function OtherPetNeidan_UpdatePetList()
	OtherPetNeidan_Choice_NumberList:ResetList()
	OtherPetNeidan_Choice_NumberList:ResetText()
	OtherPetNeidan_Choice_NumberList:ResetLastSelectIndex()
	
	local nPetCount = Pet:Other_GetPet_Count()
	
	local first_valid_pet = -1
	if nPetCount > 0 then
		for	i = 1, g_PetMaxNumber do
			if Pet:Other_IsPresent(i - 1) then
				local szPetName, zsTypeName = Pet:Other_GetName(i - 1)
				
				local pet_level = Pet:Other_GetLevel(i - 1)
				
				if pet_level >= g_PetLevelLimit then
					OtherPetNeidan_Choice_NumberList:AddTextItem(szPetName, i - 1)
				else
					OtherPetNeidan_Choice_NumberList:AddTextItem("#c808080"..szPetName, i - 1)
				end
				
				if first_valid_pet == -1 then
					first_valid_pet = i - 1
				end
			end
		end
	end
	
	if g_CurrentSelectPet == -1 then
		g_CurrentSelectPet = first_valid_pet
	else
		if not Pet:Other_IsPresent(g_CurrentSelectPet) then
			g_CurrentSelectPet = first_valid_pet
		end
	end
	
	OtherPetNeidan_UpdateListText()
end

function OtherPetNeidan_UpdateListText()
	OtherPetNeidan_Choice_NumberList:SetText("")
	if g_CurrentSelectPet >= 0 then
		local szPetName, zsTypeName = Pet:Other_GetName(g_CurrentSelectPet)
		local pet_level = Pet:Other_GetLevel(g_CurrentSelectPet)		
		if pet_level >= g_PetLevelLimit then
			OtherPetNeidan_Choice_NumberList:SetText(szPetName)
		else
			OtherPetNeidan_Choice_NumberList:SetText("#c808080"..szPetName)
		end
	end
end

function OtherPetNeidan_OnSelectPet()
	local _, nIndex = OtherPetNeidan_Choice_NumberList:GetCurrentSelect()
	
	if not Pet:Other_IsPresent(nIndex) then
		OtherPetNeidan_UpdateListText()
		return
	end
	
	if g_CurrentSelectPet ~= nIndex then
		g_CurrentSelectPet = nIndex
		OtherPetNeidan_UpdatePetInfo()
	end

end

function OtherPetNeidan_Update()
	
	local otherUnionPos = Variable:GetVariable("OtherUnionPos")
	if otherUnionPos ~= nil then
		OtherPetNeidan_Frame:SetProperty("UnifiedPosition", otherUnionPos)
	end
	
	OtherPetNeidan_Pet:SetCheck(1)
	
	OtherPetNeidan_UpdatePetList()
	OtherPetNeidan_UpdatePetInfo()
end

function OtherPetNeidan_UpdatePetInfo()
	
	--技能
	for i = 1, g_MaxPetSkill do
		if g_PetSkillAct[i] ~= nil then
			g_PetSkillAct[i]:SetActionItem(-1)
			g_PetSkillAct[i]:SetProperty("DraggingEnabled", "False")
			g_SkillFixTip[i]:Hide()
		end
	end
	
	if g_CurrentSelectPet >= 0 then
		local act_index = 1
		for i = 1, g_MaxPetSkill do
			local theSkillAction = Pet:EnumPetSkill(1000 + g_CurrentSelectPet, i - 1, "petskill")
			if theSkillAction:GetID() ~= 0 then
				if g_PetSkillAct[act_index] ~= nil then
					g_PetSkillAct[act_index]:SetActionItem(theSkillAction:GetID())
					if DataPool:LuaFnIsOtherPetSkillFixedByPND(g_CurrentSelectPet, i - 1) == 1 then
						g_SkillFixTip[act_index]:Show()
					end
					act_index = act_index + 1
				end
			end
		end
	end
	
	--内丹
	for i = 1, g_MaxEquipNeiDanCount do
		g_PetNeiDanAct[i]:SetActionItem(-1)
		g_PetNeiDanAct_Lock[i]:Hide()
		g_PetNeiDanAct_NoEffect[i]:Hide()
		g_PetNeiDanAct_Level[i]:Hide()
		g_PetNeiDanAct[i]:SetToolTip("")
		g_PetNeiDanAct[i]:SetProperty("DraggingEnabled", "False")
	end

	if g_CurrentSelectPet >= 0 then	

		for i = 1, g_MaxEquipNeiDanCount do
			
			local theNeiDanAction = DataPool:LuaFnEnumOtherPetEquipNeiDanAction(g_CurrentSelectPet, i - 1)
			if theNeiDanAction:GetID() ~= 0 then
				g_PetNeiDanAct[i]:SetActionItem(theNeiDanAction:GetID())
				
				local pnd_level = DataPool:LuaFnEnumOtherPetEquipNeiDanLevel(g_CurrentSelectPet, i - 1)
				if pnd_level >= 1 and pnd_level <= 5 then
					g_PetNeiDanAct_Level[i]:Show()
					g_PetNeiDanAct_Level[i]:SetProperty("Image", g_PND_Level_Image[pnd_level])
				end
				
				local bWork = DataPool:LuaFnEnumOtherPetEquipNeiDanIsWork(g_CurrentSelectPet, i - 1)
				if bWork ~= 1 then
					g_PetNeiDanAct_NoEffect[i]:Show()
				end
			else
				local pet_savvy = Pet:Other_GetSavvy(g_CurrentSelectPet)
				local pet_lx = Pet:Other_GetLixing(g_CurrentSelectPet)
				local pet_level = Pet:Other_GetLevel(g_CurrentSelectPet)
				if pet_level < g_PetLevelLimit or pet_savvy < g_NeiDanSlotInfo[i].savvy or pet_lx < g_NeiDanSlotInfo[i].lx then
					local strTemp = ScriptGlobal_Format("#{ZSND_230428_25}", tostring(g_NeiDanSlotInfo[i].savvy))
					--g_PetNeiDanAct[i]:SetToolTip(strTemp)
					g_PetNeiDanAct_Lock[i]:Show()
				end
			end
		end
	end
	
	--资质
	OtherPetNeidan_KongWei_ZizhiText1:Hide()
	OtherPetNeidan_KongWei_ZizhiText2:SetText("")
	OtherPetNeidan_KongWei_ZizhiText2:Hide("")
	OtherPetNeidan_KongWei_Class:SetText("")
	
	if g_CurrentSelectPet >= 0 then
		local strApt = Pet:Other_GetStrAptitude(g_CurrentSelectPet)
		local sprApt = Pet:Other_GetIntAptitude(g_CurrentSelectPet)
		local conApt = Pet:Other_GetPFAptitude(g_CurrentSelectPet)
		local intApt = Pet:Other_GetStaAptitude(g_CurrentSelectPet)
		local dexApt = Pet:Other_GetDexAptitude(g_CurrentSelectPet)
		
		local maxApt = strApt
		if sprApt > maxApt then maxApt = sprApt end
		if conApt > maxApt then maxApt = conApt end
		if intApt > maxApt then maxApt = intApt end
		if dexApt > maxApt then maxApt = dexApt end
		
		local stringApt = ""		
		if strApt == maxApt then
			stringApt = ScriptGlobal_Format("#{ZSND_230428_30}", "#{ZSND_230428_31}", tostring(maxApt))
		elseif sprApt == maxApt then
			stringApt = ScriptGlobal_Format("#{ZSND_230428_30}", "#{ZSND_230428_32}", tostring(maxApt))
		elseif conApt == maxApt then
			stringApt = ScriptGlobal_Format("#{ZSND_230428_30}", "#{ZSND_230428_33}", tostring(maxApt))
		elseif intApt == maxApt then
			stringApt = ScriptGlobal_Format("#{ZSND_230428_30}", "#{ZSND_230428_35}", tostring(maxApt))
		elseif dexApt == maxApt then
			stringApt = ScriptGlobal_Format("#{ZSND_230428_30}", "#{ZSND_230428_34}", tostring(maxApt))
		end
		
		OtherPetNeidan_KongWei_ZizhiText1:Show()
		OtherPetNeidan_KongWei_ZizhiText2:Show()
		OtherPetNeidan_KongWei_ZizhiText2:SetText(stringApt)
		
		local aType = Pet:Other_GetAttackTraitID(g_CurrentSelectPet)
		if aType == 11 then
			OtherPetNeidan_KongWei_Class:SetText("#{ZSND_230428_156}")
		elseif aType == 12 then
			OtherPetNeidan_KongWei_Class:SetText("#{ZSND_230428_155}")
		elseif aType == 13 then
			OtherPetNeidan_KongWei_Class:SetText("#{ZSND_230428_154}")
		end
	end
	
	for i = 1, 6 do
		g_EffectText[i]:SetText("")
		g_EffectNumText[i]:SetText("")
	end
	
	if g_CurrentSelectPet >= 0 then
		for i = 1, 6 do
			local strNum = DataPool:LuaFnGetOtherOuterPetNeiDanEffectNum(g_CurrentSelectPet, i)
			g_EffectNumText[i]:SetText(strNum.."% ")
			g_EffectText[i]:SetText(g_EffectName[i])
		end	
	end
	
	if g_CurrentSelectPet >= 0 then
		Pet:Other_SetModel(g_CurrentSelectPet)
	end
end

function OtherPetNeidan_Close()
	this:Hide()
end

function OtherPetNeidan_OnHidden()
	OtherPetNeidan_CleanUp()
	DataPool:LuaFn_MouseCmd_Cancel_PND_HQ()
	OtherPetNeidan_FakeObject:DetachWindowEx("My_OtherPet")
end

function OtherPetNeidan_Frame_On_ResetPos()
	OtherPetNeidan_Frame:SetProperty("UnifiedPosition", g_OtherPetNeidan_Frame_UnifiedPosition)
end

--内丹图鉴
function OtherPetNeidan_OpenTujian()
	Pet:LuaFnOpenPetNeiDan("tujian")
end

--装备
function OtherPetNeidan_Equip_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenEquipFrame("other")
end

--资料
function OtherPetNeidan_Data_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenPrivatePage("other")
end

--子女
function OtherPetNeidan_Infant_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Infant:Other_ToggleInfantPage()
	if bRet == 1 then
		this:Hide()
	end
end

--武魂
function OtherPetNeidan_Wuhun_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherWuhun()
end

--秘籍
function OtherPetNeidan_Miji_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherMiji()
	this:Hide()
end

--真元
function OtherPetNeidan_ZhenYuan_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Pneuma:ToggleTargetZhenYuanPage()
	if bRet == 1 then
		this:Hide()
	end
end

--经脉
function OtherPetNeidan_JingMai_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherJingMai()
end

--神鼎
function OtherPetNeidan_ShenDing_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	local nLevel = CachedTarget:GetData("LEVEL", 1)
	if nLevel == nil or nLevel < 15 then
		PushDebugMessage("#{XLDL_140606_63}")
	else
		local bRet = SystemSetup:OpenOtherShenDing()
		if bRet == 1 then
			this:Hide()
		end
	end
end

--侠印
function OtherPetNeidan_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = OpenOtherJunXianPage()
	if bRet == 1 then
		this:Hide()
	end
end

--骑乘
function OtherPetNeidan_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	OpenRidePage();
end

--其他
function OtherPetNeidan_OtherInfo_Page_Switch()
	Variable:SetVariable("SelfUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	OtherInfoPage();
end

--五行宝鉴
function OtherPetNeidan_OpenBaoJian()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
end

--珍兽
function OtherPetNeidan_Pet_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenPetFrame("other")
end

--御兽
function OtherPetNeidan_YuShou_Page_Switch()	
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	local nLevel = CachedTarget:GetData("LEVEL", 1)
	if nLevel == nil or nLevel < 85 then
		PushDebugMessage("对方等级不足85，尚未开启御兽之道")
		OtherPetNeidan_Frame_Client_Button02:SetCheck(0)
	else
		local bRet = Lua_OpenOtherPetMasterPage(0)
		if bRet ~= 1 then
			OtherPetNeidan_Frame_Client_Button02:SetCheck(0)
		end
	end
end

--幻灵
function OtherPetNeidan_HuanLing_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherHuanLing()
end

--武意
function OtherPetNeidan_OpenWuYi()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

--九星神器DIY技能
function OtherPetNeidan_OpenShenQi()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()ShenQi()
	
end

function OtherPetNeidan_RefreshWuYiTip()
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1 then
		OtherPetNeidan_WuYi_Buttontips:Show()
	else
		OtherPetNeidan_WuYi_Buttontips:Hide()
	end
end

--内甲
function OtherPetNeidan_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

function OtherPetNeidan_Ride_Page_Switch()

end

function OtherPetNeidan_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end

function OtherPetNeidan_ShowPage()

	for i = 1, table.getn(g_OtherPetNeidan_Page) do
		g_OtherPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	OtherPetNeidan_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_OtherPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_OtherPetNeidan_Page) do
			if i ~= nOtherPageNumber then
				g_OtherPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_OtherPageOrder = {}
	g_OtherPageCount = 0
	for i = 1, table.getn(g_OtherPetNeidan_Page) do
		if OtherPetNeidan_CheckPage(i) == 1 then
			g_OtherPageCount = g_OtherPageCount + 1
			g_OtherPageButton[g_OtherPageCount]:Show()
			g_OtherPageButton[g_OtherPageCount]:SetText(g_OtherPetNeidan_Page[i].Text)	
			g_OtherPageOrder[g_OtherPageCount] = i
		end
	end
	
end

function OtherPetNeidan_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_OtherPageOrder[idx]
	
	if idx == 1 then--装备
		OtherPetNeidan_Equip_Page_Switch();
	elseif idx == 2 then--资料
		OtherPetNeidan_Data_Page_Switch()
	elseif idx == 3 then--珍兽
		--OtherMartial_WuYi_Pet_Switch()
	elseif idx == 4 then--子女
		OtherPetNeidan_Infant_Page_Switch()
	elseif idx == 5 then--武魂
		OtherPetNeidan_Wuhun_Page_Switch()
	elseif idx == 6 then--秘籍
		OtherPetNeidan_Miji_Page_Switch()
	elseif idx == 7 then--真元
		OtherPetNeidan_ZhenYuan_Page_Switch()
	elseif idx == 8 then--经脉
		OtherPetNeidan_JingMai_Page_Switch()
	elseif idx == 9 then--神鼎
		OtherPetNeidan_ShenDing_Page_Switch()
	elseif idx == 10 then--侠印
		OtherPetNeidan_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		OtherPetNeidan_OpenBaoJian()
	elseif idx == 12 then--武意
		OtherPetNeidan_OpenWuYi()
	elseif idx == 13 then--神器
		OtherPetNeidan_OpenShenQi()
	elseif idx == 14 then--星盘
		OtherPetNeidan_Armor_Page_Switch()
	elseif idx == 15 then--名物
		OtherPetNeidan_CangPin_Page_Switch()
	end
end

function OtherPetNeidan_CheckPage(idx)
	if idx == 1 then--装备
		return 1
	elseif idx == 2 then--资料
		return 1
	elseif idx == 3 then--珍兽
		return 1
	elseif idx == 4 then--子女
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 5 then--武魂
		return 1
	elseif idx == 6 then--秘籍
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 7 then--真元
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 8 then--经脉
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 9 then--神鼎
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 10 then--侠印
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 11 then--宝鉴
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 12 then--武意
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 13 then--神器
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 14 then--星盘
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 15 then--名物
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	end
	return 0
end

function OtherPetNeidan_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end


