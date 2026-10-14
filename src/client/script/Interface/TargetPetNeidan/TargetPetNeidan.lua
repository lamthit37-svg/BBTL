--!!!reloadscript =TargetPetNeidan

local g_TargetPetNeidan_Frame_UnifiedPosition = ""

local g_CurrentSelectPet = 0

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

function TargetPetNeidan_PreLoad()
	this:RegisterEvent("OPEN_TRANSFER_PET_NEIDAN", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("PLAYER_ENTERING_WORLD", false)
end

function TargetPetNeidan_OnLoad()

	g_TargetPetNeidan_Frame_UnifiedPosition = TargetPetNeidan_Frame:GetProperty("UnifiedPosition")
	
	g_PetSkillAct[1] = TargetPetNeidan_Skill1
	g_PetSkillAct[2] = TargetPetNeidan_Skill2
	g_PetSkillAct[3] = TargetPetNeidan_Skill3
	g_PetSkillAct[4] = TargetPetNeidan_Skill4
	g_PetSkillAct[5] = TargetPetNeidan_Skill5
	g_PetSkillAct[6] = TargetPetNeidan_Skill6
	g_PetSkillAct[7] = TargetPetNeidan_Skill7
	g_PetSkillAct[8] = TargetPetNeidan_Skill8
	g_PetSkillAct[9] = TargetPetNeidan_Skill9
	g_PetSkillAct[10] = TargetPetNeidan_Skill10
	g_PetSkillAct[11] = TargetPetNeidan_Skill11
	g_PetSkillAct[12] = TargetPetNeidan_Skill12
	
	g_SkillFixTip[1] = TargetPetNeidan_Skill1_Mask
	g_SkillFixTip[2] = TargetPetNeidan_Skill2_Mask
	g_SkillFixTip[3] = TargetPetNeidan_Skill3_Mask
	g_SkillFixTip[4] = TargetPetNeidan_Skill4_Mask
	g_SkillFixTip[5] = TargetPetNeidan_Skill5_Mask
	g_SkillFixTip[6] = TargetPetNeidan_Skill6_Mask
	g_SkillFixTip[7] = TargetPetNeidan_Skill7_Mask
	g_SkillFixTip[8] = TargetPetNeidan_Skill8_Mask
	g_SkillFixTip[9] = TargetPetNeidan_Skill9_Mask
	g_SkillFixTip[10] = TargetPetNeidan_Skill10_Mask
	g_SkillFixTip[11] = TargetPetNeidan_Skill11_Mask
	g_SkillFixTip[12] = TargetPetNeidan_Skill12_Mask
	
	g_PetNeiDanAct[1] = TargetPetNeidan_BK1_Icon1
	g_PetNeiDanAct[2] = TargetPetNeidan_BK1_Icon2
	g_PetNeiDanAct[3] = TargetPetNeidan_BK1_Icon3
	g_PetNeiDanAct[4] = TargetPetNeidan_BK1_Icon4
	g_PetNeiDanAct[5] = TargetPetNeidan_BK1_Icon5
	g_PetNeiDanAct[6] = TargetPetNeidan_BK1_Icon6
	g_PetNeiDanAct[7] = TargetPetNeidan_BK1_Icon7
	
	g_PetNeiDanAct_Lock[1] = TargetPetNeidan_BK1_Icon1_Lock
	g_PetNeiDanAct_Lock[2] = TargetPetNeidan_BK1_Icon2_Lock
	g_PetNeiDanAct_Lock[3] = TargetPetNeidan_BK1_Icon3_Lock
	g_PetNeiDanAct_Lock[4] = TargetPetNeidan_BK1_Icon4_Lock
	g_PetNeiDanAct_Lock[5] = TargetPetNeidan_BK1_Icon5_Lock
	g_PetNeiDanAct_Lock[6] = TargetPetNeidan_BK1_Icon6_Lock
	g_PetNeiDanAct_Lock[7] = TargetPetNeidan_BK1_Icon7_Lock
	
	g_PetNeiDanAct_NoEffect[1] = TargetPetNeidan_BK1_Icon1_Cornermark
	g_PetNeiDanAct_NoEffect[2] = TargetPetNeidan_BK1_Icon2_Cornermark
	g_PetNeiDanAct_NoEffect[3] = TargetPetNeidan_BK1_Icon3_Cornermark
	g_PetNeiDanAct_NoEffect[4] = TargetPetNeidan_BK1_Icon4_Cornermark
	g_PetNeiDanAct_NoEffect[5] = TargetPetNeidan_BK1_Icon5_Cornermark
	g_PetNeiDanAct_NoEffect[6] = TargetPetNeidan_BK1_Icon6_Cornermark
	g_PetNeiDanAct_NoEffect[7] = TargetPetNeidan_BK1_Icon7_Cornermark
	
	g_PetNeiDanAct_Level[1] = TargetPetNeidan_BK1_Icon1_Jie
	g_PetNeiDanAct_Level[2] = TargetPetNeidan_BK1_Icon2_Jie
	g_PetNeiDanAct_Level[3] = TargetPetNeidan_BK1_Icon3_Jie
	g_PetNeiDanAct_Level[4] = TargetPetNeidan_BK1_Icon4_Jie
	g_PetNeiDanAct_Level[5] = TargetPetNeidan_BK1_Icon5_Jie
	g_PetNeiDanAct_Level[6] = TargetPetNeidan_BK1_Icon6_Jie
	g_PetNeiDanAct_Level[7] = TargetPetNeidan_BK1_Icon7_Jie
	
	g_EffectText[1] = TargetPetNeidan_NumListInfo1
	g_EffectText[2] = TargetPetNeidan_NumList2Info
	g_EffectText[3] = TargetPetNeidan_NumList3Info
	g_EffectText[4] = TargetPetNeidan_NumList4Info
	g_EffectText[5] = TargetPetNeidan_NumList5Info
	g_EffectText[6] = TargetPetNeidan_NumList6Info
	
	g_EffectNumText[1] = TargetPetNeidan_NumListInfo2
	g_EffectNumText[2] = TargetPetNeidan_NumList2Info2
	g_EffectNumText[3] = TargetPetNeidan_NumList3Info2
	g_EffectNumText[4] = TargetPetNeidan_NumList4Info2
	g_EffectNumText[5] = TargetPetNeidan_NumList5Info2
	g_EffectNumText[6] = TargetPetNeidan_NumList6Info2
	
end

function TargetPetNeidan_OnEvent(event)
	
	if event == "OPEN_TRANSFER_PET_NEIDAN" then
		
		if Player:GetData("IsOriginalJD") == 1 then
			return
		end
		
		if Player:GetData("Is2606S") == 1 then
			return
		end
		
		local targetPetUnionPos = Variable:GetVariable("TargetPetUnionPos")
		if targetPetUnionPos ~= nil then
			TargetPetNeidan_Frame:SetProperty("TargetPetUnionPos", targetPetUnionPos)
		end
		
		TargetPetNeidan_CloseConflictWindow()
		
		if not TargetPet:IsPresent() then
			return
		end
		
		if this:IsVisible() then			
			this:Activate()
		else
			this:Show()
			TargetPetNeidan_FakeObject:AttachWindowEx("My_TargetPet")
		end
		TargetPetNeidan_Update()

		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		TargetPetNeidan_Frame_On_ResetPos()
		return
	end

	if event == "PLAYER_ENTERING_WORLD" then
		if this:IsVisible() then
			this:Hide()
		end
		return
	end
	
end

function TargetPetNeidan_CleanUp()
	TargetPetNeidan_Client_Button01:SetCheck(0)
	TargetPetNeidan_Client_Button02:SetCheck(1)
end

function TargetPetNeidan_Update()

	TargetPetNeidan_Client_Button01:SetCheck(0)
	TargetPetNeidan_Client_Button02:SetCheck(1)

	TargetPetNeidan_UpdatePetInfo()
end

function TargetPetNeidan_UpdatePetInfo()
	
	--技能
	for i = 1, g_MaxPetSkill do
		if g_PetSkillAct[i] ~= nil then
			g_PetSkillAct[i]:SetActionItem(-1)
			g_PetSkillAct[i]:SetProperty("DraggingEnabled", "False")
			g_SkillFixTip[i]:Hide()
		end
	end

	local act_index = 1
	for i = 1, g_MaxPetSkill do
		local theSkillAction = Pet:EnumPetSkill(100, i - 1, "petskill")
		if theSkillAction:GetID() ~= 0 then
			if g_PetSkillAct[act_index] ~= nil then
				g_PetSkillAct[act_index]:SetActionItem(theSkillAction:GetID())
				if DataPool:LuaFnIsTargetPetSkillFixedByPND(i - 1) == 1 then
					g_SkillFixTip[act_index]:Show()
				end
				act_index = act_index + 1
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

	for i = 1, g_MaxEquipNeiDanCount do
		local theNeiDanAction = DataPool:LuaFnEnumTargetPetEquipNeiDanAction(i - 1)
		if theNeiDanAction:GetID() ~= 0 then
			g_PetNeiDanAct[i]:SetActionItem(theNeiDanAction:GetID())
			
			local pnd_level = DataPool:LuaFnEnumTargetPetEquipNeiDanLevel(i - 1)
			if pnd_level >= 1 and pnd_level <= 5 then
				g_PetNeiDanAct_Level[i]:Show()
				g_PetNeiDanAct_Level[i]:SetProperty("Image", g_PND_Level_Image[pnd_level])
			end
			
			local bWork = DataPool:LuaFnEnumTargetPetEquipNeiDanIsWork(i - 1)
			if bWork ~= 1 then
				g_PetNeiDanAct_NoEffect[i]:Show()
			end
		else
			local pet_savvy = TargetPet:GetSavvy()
			local pet_lx = TargetPet:GetLixing()
			local pet_level = TargetPet:GetLevel()
			if pet_level < g_PetLevelLimit or pet_savvy < g_NeiDanSlotInfo[i].savvy or pet_lx < g_NeiDanSlotInfo[i].lx then
				local strTemp = ScriptGlobal_Format("#{ZSND_230428_25}", tostring(g_NeiDanSlotInfo[i].savvy))
				--g_PetNeiDanAct[i]:SetToolTip(strTemp)
				g_PetNeiDanAct_Lock[i]:Show()
			end
		end
	end

	
	--资质
	local strApt = TargetPet:GetStrAptitude()
	local sprApt = TargetPet:GetIntAptitude()
	local conApt = TargetPet:GetPFAptitude()
	local intApt = TargetPet:GetStaAptitude()
	local dexApt = TargetPet:GetDexAptitude()
	
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

	TargetPetNeidan_KongWei_ZizhiText2:SetText(stringApt)
	
	for i = 1, 6 do
		local strNum = DataPool:LuaFnGetTargetOuterPetNeiDanEffectNum(i)
		g_EffectNumText[i]:SetText(strNum.."% ")
		g_EffectText[i]:SetText(g_EffectName[i])
	end
	
	local aType = TargetPet:GetAttackTraitID()
	if aType == 11 then
		TargetPetNeidan_KongWei_Class:SetText("#{ZSND_230428_156}")
	elseif aType == 12 then
		TargetPetNeidan_KongWei_Class:SetText("#{ZSND_230428_155}")
	elseif aType == 13 then
		TargetPetNeidan_KongWei_Class:SetText("#{ZSND_230428_154}")
	end

	TargetPet:SetModelAboutHuanLing()
end

function TargetPetNeidan_CloseClick()
	this:Hide()
end

function TargetPetNeidan_OnHidden()
	TargetPetNeidan_CleanUp()
	TargetPetNeidan_FakeObject:DetachWindowEx("My_TargetPet")
end

function TargetPetNeidan_Frame_On_ResetPos()
	TargetPetNeidan_Frame:SetProperty("UnifiedPosition", g_TargetPetNeidan_Frame_UnifiedPosition)
end

--内丹图鉴
function TargetPetNeidan_OpenTujian()
	Pet:LuaFnOpenPetNeiDan("tujian")
end

--珍兽
function TargetPetNeidan_Pet_Switch()
	Variable:SetVariable("TargetPetUnionPos", TargetPetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	
	if Pet:LuaFnOpenTargetPet() ~= 1 then
		TargetPetNeidan_Client_Button01:SetCheck(0)
		TargetPetNeidan_Client_Button02:SetCheck(1)
	end
end

function TargetPetNeidan_CloseConflictWindow()
	if IsWindowShow("OtherPet") then
		CloseWindow("OtherPet", true)
	end
	
	if IsWindowShow("OtherYuShou_BaiHu") then
		CloseWindow("OtherYuShou_BaiHu", true)
	end
	
	if IsWindowShow("OtherYuShou_QingLong") then
		CloseWindow("OtherYuShou_QingLong", true)
	end
	
	if IsWindowShow("OtherYuShou_XuanWu") then
		CloseWindow("OtherYuShou_XuanWu", true)
	end
	
	if IsWindowShow("OtherYuShou_ZhuQue") then
		CloseWindow("OtherYuShou_ZhuQue", true)
	end
	
	if IsWindowShow("OtherHuanLing") then
		CloseWindow("OtherHuanLing", true)
	end
	
	if IsWindowShow("OtherPetNeidan") then
		CloseWindow("OtherPetNeidan", true)
	end

	if IsWindowShow("TargetPet2") then
		CloseWindow("TargetPet2", true)
	end
	
	if IsWindowShow("TargetPet") then
		CloseWindow("TargetPet", true)
	end
end
