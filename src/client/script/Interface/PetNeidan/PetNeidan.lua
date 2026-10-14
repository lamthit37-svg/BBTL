--!!!reloadscript =PetNeidan
local g_InitList = 0
local g_PetMaxNumber = 10

local g_ChipOrNot = 0

local g_CurrentSelectPet = -1
local g_MaxNeiDanBarNum = 0
local g_MaxNeiDanBagSize = 60
local g_NeiDanBarList = {}

local g_NeedChangeNeiDanScrollSize = 0

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

local g_CurrentFilter = 0
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
local g_PetNeidan_Page = {
	[1] = {Text = "#{INTERFACE_XML_877}",		NeedCheck = 0, Tip = ""},
	[2] = {Text = "#{INTERFACE_XML_882}",		NeedCheck = 0, Tip = ""},
	[3] = {Text = "#{INTERFACE_XML_854}",		NeedCheck = 0, Tip = ""},
	[4] = {Text = "#{ZNJCS_130825_7}",			NeedCheck = 0, Tip = "#{RWYQ_150707_01}"},
	[5] = {Text = "#{WH_xml_XX(95)}",			NeedCheck = 0, Tip = "#{RWYQ_150707_02}"},
	[6] = {Text = "#{XL_XML_35}",				NeedCheck = 0, Tip = "#{RWYQ_150707_03}"},
	[7] = {Text = "#{WLMJ_130121_54}",			NeedCheck = 0, Tip = "#{RWYQ_150707_04}"},
	[8] = {Text = "#{ZYXT_120528_154}",			NeedCheck = 0, Tip = "#{RWYQ_150707_05}"},
	[9] = {Text = "#{MPJJ_XT_XML_01}",  	 	NeedCheck = 0, Tip = "#{RWYQ_150707_06}"},
	[10] = {Text = "#{XLDL_140606_04}",			NeedCheck = 0, Tip = "#{RWYQ_150707_07}"},
	[11] = {Text = "#{JXJW_140822_22}",  	 	NeedCheck = 0, Tip = "#{RWYQ_150707_08}"},
	[12] = {Text = "#{ZZZB_150811_113}",		NeedCheck = 0, Tip = "#{ZZZB_150811_114}"},
	[13] = {Text = "#{WYXT_20170807_86}",		NeedCheck = 0, Tip = "#{WYXT_20170907_302}"},
	[14] = {Text = "#{JXSQ_170829_216}",		NeedCheck = 0, Tip = "#{JXSQ_170829_217}"},
	[15] = {Text = "#{NJBZ_220816_11}",			NeedCheck = 0, Tip = "#{NJBZ_220816_12}"},
	[16] = {Text = "#{CPSJ_260112_1}",			NeedCheck = 0, Tip = "#{CPSJ_260112_2}"},
	[17] = {Text = "#{INTERFACE_XML_496}",		NeedCheck = 0, Tip = ""},
}

local g_PetNeidan_PageButton = {}
local g_PetNeidan_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

function PetNeidan_PreLoad()
	
	this:RegisterEvent("UI_COMMAND")
	
	this:RegisterEvent("OPEN_PET_NEIDAN")

	this:RegisterEvent("MARTIAL_UPDATE", false)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP", false)
	
	this:RegisterEvent("FINISH_MISSION")
	this:RegisterEvent("TOGGLE_UPDATE_INFANT", false)
	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK")
	
	this:RegisterEvent("PACKET_NEIDAN_UPDATE", false)
	this:RegisterEvent("PET_NEIDAN_UPDATE", false)
	this:RegisterEvent("ADD_PET", false)
	this:RegisterEvent("DELETE_PET", false)
	this:RegisterEvent("UPDATE_PET_PAGE", false)
	
	this:RegisterEvent("EQUIP_NEIDAN", false)	
	this:RegisterEvent("UNEQUIP_NEIDAN", false)
	this:RegisterEvent("NEIDAN_CHIP_UPDATE", false)
	
	this:RegisterEvent("UPDATE_DANQI_I", false)
	this:RegisterEvent("UPDATE_DANQI_II", false)
	this:RegisterEvent("UPDATE_DANQI_III", false)
	
	this:RegisterEvent("PLAYER_ENTERING_WORLD", false)
	
	this:RegisterEvent("CANGPIN_UPDATE", false)
end

function PetNeidan_OnLoad()
	g_PetSkillAct[1] = PetNeidan_Skill1
	g_PetSkillAct[2] = PetNeidan_Skill2
	g_PetSkillAct[3] = PetNeidan_Skill3
	g_PetSkillAct[4] = PetNeidan_Skill4
	g_PetSkillAct[5] = PetNeidan_Skill5
	g_PetSkillAct[6] = PetNeidan_Skill6
	g_PetSkillAct[7] = PetNeidan_Skill7
	g_PetSkillAct[8] = PetNeidan_Skill8
	g_PetSkillAct[9] = PetNeidan_Skill9
	g_PetSkillAct[10] = PetNeidan_Skill10
	g_PetSkillAct[11] = PetNeidan_Skill11
	g_PetSkillAct[12] = PetNeidan_Skill12
	
	g_SkillFixTip[1] = PetNeidan_Skill1_Mask
	g_SkillFixTip[2] = PetNeidan_Skill2_Mask
	g_SkillFixTip[3] = PetNeidan_Skill3_Mask
	g_SkillFixTip[4] = PetNeidan_Skill4_Mask
	g_SkillFixTip[5] = PetNeidan_Skill5_Mask
	g_SkillFixTip[6] = PetNeidan_Skill6_Mask
	g_SkillFixTip[7] = PetNeidan_Skill7_Mask
	g_SkillFixTip[8] = PetNeidan_Skill8_Mask
	g_SkillFixTip[9] = PetNeidan_Skill9_Mask
	g_SkillFixTip[10] = PetNeidan_Skill10_Mask
	g_SkillFixTip[11] = PetNeidan_Skill11_Mask
	g_SkillFixTip[12] = PetNeidan_Skill12_Mask
	
	g_PetNeiDanAct[1] = PetNeidan_BK1_Icon1
	g_PetNeiDanAct[2] = PetNeidan_BK1_Icon2
	g_PetNeiDanAct[3] = PetNeidan_BK1_Icon3
	g_PetNeiDanAct[4] = PetNeidan_BK1_Icon4
	g_PetNeiDanAct[5] = PetNeidan_BK1_Icon5
	g_PetNeiDanAct[6] = PetNeidan_BK1_Icon6
	g_PetNeiDanAct[7] = PetNeidan_BK1_Icon7
	
	g_PetNeiDanAct_Lock[1] = PetNeidan_BK1_Icon1_Lock
	g_PetNeiDanAct_Lock[2] = PetNeidan_BK1_Icon2_Lock
	g_PetNeiDanAct_Lock[3] = PetNeidan_BK1_Icon3_Lock
	g_PetNeiDanAct_Lock[4] = PetNeidan_BK1_Icon4_Lock
	g_PetNeiDanAct_Lock[5] = PetNeidan_BK1_Icon5_Lock
	g_PetNeiDanAct_Lock[6] = PetNeidan_BK1_Icon6_Lock
	g_PetNeiDanAct_Lock[7] = PetNeidan_BK1_Icon7_Lock
	
	g_PetNeiDanAct_NoEffect[1] = PetNeidan_BK1_Icon1_Cornermark
	g_PetNeiDanAct_NoEffect[2] = PetNeidan_BK1_Icon2_Cornermark
	g_PetNeiDanAct_NoEffect[3] = PetNeidan_BK1_Icon3_Cornermark
	g_PetNeiDanAct_NoEffect[4] = PetNeidan_BK1_Icon4_Cornermark
	g_PetNeiDanAct_NoEffect[5] = PetNeidan_BK1_Icon5_Cornermark
	g_PetNeiDanAct_NoEffect[6] = PetNeidan_BK1_Icon6_Cornermark
	g_PetNeiDanAct_NoEffect[7] = PetNeidan_BK1_Icon7_Cornermark
	
	g_PetNeiDanAct_Level[1] = PetNeidan_BK1_Icon1_Jie
	g_PetNeiDanAct_Level[2] = PetNeidan_BK1_Icon2_Jie
	g_PetNeiDanAct_Level[3] = PetNeidan_BK1_Icon3_Jie
	g_PetNeiDanAct_Level[4] = PetNeidan_BK1_Icon4_Jie
	g_PetNeiDanAct_Level[5] = PetNeidan_BK1_Icon5_Jie
	g_PetNeiDanAct_Level[6] = PetNeidan_BK1_Icon6_Jie
	g_PetNeiDanAct_Level[7] = PetNeidan_BK1_Icon7_Jie
	
	PetNeidan_List2_ShowType:AddTextItem("#{ZSND_230428_48}" ,1)	--全部
	PetNeidan_List2_ShowType:AddTextItem("#{ZSND_230428_49}" ,2)	--核心
	PetNeidan_List2_ShowType:AddTextItem("#{ZSND_230428_50}" ,3)	--内层
	PetNeidan_List2_ShowType:AddTextItem("#{ZSND_230428_51}" ,4)	--外层
	
	g_EffectText[1] = PetNeidan_NumListInfo1
	g_EffectText[2] = PetNeidan_NumList2Info
	g_EffectText[3] = PetNeidan_NumList3Info
	g_EffectText[4] = PetNeidan_NumList4Info
	g_EffectText[5] = PetNeidan_NumList5Info
	g_EffectText[6] = PetNeidan_NumList6Info
	
	g_EffectNumText[1] = PetNeidan_NumListInfo2
	g_EffectNumText[2] = PetNeidan_NumList2Info2
	g_EffectNumText[3] = PetNeidan_NumList3Info2
	g_EffectNumText[4] = PetNeidan_NumList4Info2
	g_EffectNumText[5] = PetNeidan_NumList5Info2
	g_EffectNumText[6] = PetNeidan_NumList6Info2
	
	g_PetNeidan_PageButton[1] = PetNeidan_SelfEquip
	g_PetNeidan_PageButton[2] = PetNeidan_SelfData
	g_PetNeidan_PageButton[3] = PetNeidan_Pet
	g_PetNeidan_PageButton[4] = PetNeidan_Infant
	g_PetNeidan_PageButton[5] = PetNeidan_Wuhun
	g_PetNeidan_PageButton[6] = PetNeidan_Xiulian
	g_PetNeidan_PageButton[7] = PetNeidan_Miji
	g_PetNeidan_PageButton[8] = PetNeidan_ZhenYuan
	g_PetNeidan_PageButton[9] = PetNeidan_JingMai
	g_PetNeidan_PageButton[10] = PetNeidan_ShenDing
	g_PetNeidan_PageButton[11] = PetNeidan_JueWei
	g_PetNeidan_PageButton[12] = PetNeidan_BaoJian
	g_PetNeidan_PageButton[13] = PetNeidan_WuYi
	g_PetNeidan_PageButton[14] = PetNeidan_ShenQi
	g_PetNeidan_PageButton[15] = PetNeidan_Armor
	g_PetNeidan_PageButton[16] = PetNeidan_CangPin
	g_PetNeidan_PageButton[17] = PetNeidan_OtherInfo
	
	g_PetNeidan_PageMask[1] = PetNeidan_SelfEquip_tips
	g_PetNeidan_PageMask[2] = PetNeidan_SelfData_tips
	g_PetNeidan_PageMask[3] = PetNeidan_Pet_tips
	g_PetNeidan_PageMask[4] = PetNeidan_Infant_tips
	g_PetNeidan_PageMask[5] = PetNeidan_Wuhun_tips
	g_PetNeidan_PageMask[6] = PetNeidan_Xiulian_tips
	g_PetNeidan_PageMask[7] = PetNeidan_Miji_tips
	g_PetNeidan_PageMask[8] = PetNeidan_ZhenYuan_tips
	g_PetNeidan_PageMask[9] = PetNeidan_JingMai_tips
	g_PetNeidan_PageMask[10] = PetNeidan_ShenDing_tips
	g_PetNeidan_PageMask[11] = PetNeidan_JueWei_tips
	g_PetNeidan_PageMask[12] = PetNeidan_BaoJian_tips
	g_PetNeidan_PageMask[13] = PetNeidan_WuYi_tips
	g_PetNeidan_PageMask[14] = PetNeidan_ShenQi_tips
	g_PetNeidan_PageMask[15] = PetNeidan_Armor_tips
	g_PetNeidan_PageMask[16] = PetNeidan_CangPin_tips
	g_PetNeidan_PageMask[17] = PetNeidan_OtherInfo_tips
	
	g_PageButtonTipsPos[1] = "{0.000000,28.000000}" 
	g_PageButtonTipsPos[2] = "{0.000000,64.000000}" 
	g_PageButtonTipsPos[3] = "{0.000000,100.000000}"
	g_PageButtonTipsPos[4] = "{0.000000,136.000000}"
	g_PageButtonTipsPos[5] = "{0.000000,172.000000}"
	g_PageButtonTipsPos[6] = "{0.000000,208.000000}"
	g_PageButtonTipsPos[7] = "{0.000000,244.000000}"
	g_PageButtonTipsPos[8] = "{0.000000,280.000000}"
	g_PageButtonTipsPos[9] = "{0.000000,316.000000}" 
	g_PageButtonTipsPos[10] = "{0.000000,352.000000}" 
	g_PageButtonTipsPos[11] = "{0.000000,388.000000}" 
	g_PageButtonTipsPos[12] = "{0.000000,424.000000}" 
	g_PageButtonTipsPos[13] = "{0.000000,460.000000}" 
	g_PageButtonTipsPos[14] = "{0.000000,496.000000}"
	g_PageButtonTipsPos[15] = "{0.000000,532.000000}"
	g_PageButtonTipsPos[16] = "{0.000000,568.000000}"
	g_PageButtonTipsPos[17] = "{0.000000,604.000000}"
	
end

function PetNeidan_OnEvent(event)
	if event == "OPEN_PET_NEIDAN" then
		if this:IsVisible() then
			return
		end
		
		if Player:GetData("IsOriginalJD") == 1 then
			return
		end
		if Player:GetData("Is2606S") == 1 then
			return
		end
		
		this:Show()
		PetNeidan_FakeObject:AttachWindowEx("My_Pet")
		g_ChipOrNot = 0
		g_CurrentFilter = 1
		PetNeidan_List2_ShowType:SetText("#{ZSND_230428_48}")
		g_NeedChangeNeiDanScrollSize = 1
		local nLevel = Player:GetLevel()
		PetNeidan_Refresh_Page_Button(nLevel)
		PetNeidan_Update()
		PetNeidan_ShowPage()
		return
	end
	
	if event == "MARTIAL_UPDATE" or event == "MARTIAL_HIDE_ZHAOHUI_TIP" then
		PetNeidan_RefreshWuYiTip()
	end
	
	if event == "UPDATE_WILLGET_MISSION_TRACK" or event=="TOGGLE_UPDATE_INFANT" or event == "FINISH_MISSION" then
		local nLevel = Player:GetLevel()
		PetNeidan_Refresh_Page_Button(nLevel)
		PetNeidan_ShowPage()
	end

	if event == "ADD_PET" or event == "DELETE_PET" or event == "UPDATE_PET_PAGE" then
		PetNeidan_UpdatePetList()
		PetNeidan_UpdatePetInfo()
		return
	end
	
	if event == "EQUIP_NEIDAN" then
		PetNeidan_Equip_NeiDan(tonumber(arg0), tonumber(arg1))
	end
	
	if event == "UNEQUIP_NEIDAN" then
		PetNeidan_UnEquip_NeiDan(tonumber(arg0))
	end
	
	if event == "PET_NEIDAN_UPDATE" then
		PetNeidan_UpdatePetInfo()
	end
	
	if event == "PACKET_NEIDAN_UPDATE" then
		if g_ChipOrNot == 0 then
			PetNeidan_UpdateNeiDanList()
		end
	end
	
	if event == "NEIDAN_CHIP_UPDATE" then
		if g_ChipOrNot == 1 then
			PetNeidan_UpdateNeiDanList()
		end
		PetNeidan_Refresh_ChipPageTip()
	end
	
	if event == "PLAYER_ENTERING_WORLD" then
		if this:IsVisible() then
			this:Hide()
		end
		return
	end
	
	if event == "UPDATE_DANQI_I" then
		local danqi = Player:GetData("DANQI_I")	
		PetNeidan_Huaqi_Text4_NUM:SetText(tostring(danqi))
	end
	
	if event == "UPDATE_DANQI_II" then
		local danqi = Player:GetData("DANQI_II")	
		PetNeidan_Huaqi_Text3_NUM:SetText(tostring(danqi))
	end
	
	if event == "UPDATE_DANQI_III" then
		local danqi = Player:GetData("DANQI_III")	
		PetNeidan_Huaqi_Text2_NUM:SetText(tostring(danqi))
	end

	if event == "CANGPIN_UPDATE" then
		PetNeidan_RefreshCangPinTip()
	end
end

function PetNeidan_InitListBar()

	if g_InitList == 0 then
		g_MaxNeiDanBarNum = DataPool:LuaFnGetPetNeiDanChipMaxCount()
		if g_MaxNeiDanBarNum < g_MaxNeiDanBagSize then
			g_MaxNeiDanBarNum = g_MaxNeiDanBagSize
		end

		for i = 1, g_MaxNeiDanBarNum do
			local bar = PetNeidan_List2_Lace:AddChild("PetNeidan_List2_LaceItem1")
			bar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
			g_NeiDanBarList[i] = bar
			bar:GetSubItem("PetNeidan_List2_LaceItem1_Icon"):SetEvent("MouseLClick", string.format("PetNeidan_NeiDanClicked(%d)", i))
			bar:GetSubItem("PetNeidan_List2_LaceItem1_Icon"):SetEvent("MouseMove", string.format("PetNeidan_NeiDanMouseMove(%d)", i))
			bar:GetSubItem("PetNeidan_List2_LaceItem1_Icon"):SetEvent("MouseRClick", string.format("PetNeidan_NeiDanRClicked(%d)", i))
			bar:GetSubItem("PetNeidan_List2_LaceItem1_Icon"):SetProperty("DragAcceptName", "WE"..tostring(i))
			bar:GetSubItem("PetNeidan_List2_LaceItem1_Icon"):SetProperty("DraggingEnabled", "True")
		end
		g_InitList = 1
	end
end

function PetNeidan_CleanUp()
	PetNeidan_Client_Button04:SetCheck(1)
	PetNeidan_Pet:SetCheck(1)
	g_CurrentSelectPet = -1
end

function PetNeidan_UpdatePetList()
	--local szPetName = Pet:GetPetList_Appoint(idx - 1)

	PetNeidan_Choice_NumberList:ResetList()
	PetNeidan_Choice_NumberList:ResetText()
	PetNeidan_Choice_NumberList:ResetLastSelectIndex()
	
	local nPetCount = Pet:GetPet_Count()
	
	local first_valid_pet = -1
	if nPetCount > 0 then
		for	i = 1, g_PetMaxNumber do
			if Pet:IsPresent(i - 1) then
				local szPetName = Pet:GetPetList_Appoint(i - 1)
				
				local pet_level = Pet:GetLevel(i - 1)
				
				if pet_level >= g_PetLevelLimit then
					if Pet:GetIsFighting(i - 1) then --出战
						PetNeidan_Choice_NumberList:AddTextItem("#c0A9605"..szPetName, i - 1)
					elseif Pet:GetIsPossession(i - 1) then --附体					
						PetNeidan_Choice_NumberList:AddTextItem("#c996699"..szPetName, i - 1)
					else
						PetNeidan_Choice_NumberList:AddTextItem(szPetName, i - 1)
					end
					
					if first_valid_pet == -1 then
						first_valid_pet = i - 1
					end
				else
					PetNeidan_Choice_NumberList:AddTextItem("#c808080"..szPetName, i - 1)
				end
			end
		end
	end
	
	if g_CurrentSelectPet == -1 then
		g_CurrentSelectPet = first_valid_pet
	else
		if not Pet:IsPresent(g_CurrentSelectPet) then
			g_CurrentSelectPet = first_valid_pet
		else
			local pet_level = Pet:GetLevel(g_CurrentSelectPet)
			if pet_level < g_PetLevelLimit then
				g_CurrentSelectPet = first_valid_pet
			end
		end
	end
	
	PetNeidan_UpdateListText()
end

function PetNeidan_OnSelectPet()
	local _, nIndex = PetNeidan_Choice_NumberList:GetCurrentSelect()
	
	if not Pet:IsPresent(nIndex) then
		PetNeidan_UpdateListText()
		return
	end
	
	local my_level = Player:GetData("LEVEL")
	if my_level < g_PlayerLevelLimit then
		PushDebugMessage("#{ZSND_230428_05}")
		PetNeidan_UpdateListText()
		return
	end
	
	local pet_level = Pet:GetLevel(nIndex)
	if pet_level < g_PetLevelLimit then
		PushDebugMessage("#{ZSND_230428_130}")
		PetNeidan_UpdateListText()
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(g_PreMissionID) ~= 1 then
		PushDebugMessage("#{ZSND_230428_06}")
		PetNeidan_UpdateListText()
		return
	end
	
	if g_CurrentSelectPet ~= nIndex then
		g_CurrentSelectPet = nIndex
		PetNeidan_UpdateNeiDanList()
		PetNeidan_UpdatePetInfo()
	end

end

function PetNeidan_UpdateListText()
	PetNeidan_Choice_NumberList:SetText("")
	if g_CurrentSelectPet >= 0 then
		local szPetName = Pet:GetPetList_Appoint(g_CurrentSelectPet)
		if Pet:GetIsFighting(g_CurrentSelectPet) then --出战
			PetNeidan_Choice_NumberList:SetText("#c0A9605"..szPetName)
		elseif Pet:GetIsPossession(g_CurrentSelectPet) then --附体
			PetNeidan_Choice_NumberList:SetText("#c996699"..szPetName)
		else
			PetNeidan_Choice_NumberList:SetText(szPetName)
		end
	end
end

function PetNeidan_UpdateNeiDanList()
	
	DataPool:LuaFnSortPlayerPetNeiDanList(g_CurrentSelectPet)
	
	for i = 1, g_MaxNeiDanBarNum do
		if g_NeiDanBarList[i] then
			g_NeiDanBarList[i]:GetSubItem("PetNeidan_List2_LaceItem1_Icontips"):Hide()
			g_NeiDanBarList[i]:GetSubItem("PetNeidan_List2_LaceItem1_IconJie"):Hide()
			g_NeiDanBarList[i]:GetSubItem("PetNeidan_List2_LaceItem1_IconMaskGray"):Hide()
			local ctrlAction = g_NeiDanBarList[i]:GetSubItem("PetNeidan_List2_LaceItem1_Icon")
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
				ctrlAction:SetActionItem(-1)
				ctrlAction:SetProperty("DraggingEnabled", "False")
			end
		end	
	end
	
	if g_ChipOrNot == 0 then
		PetNeidan_List2FenYe1:SetCheck(1)
		PetNeidan_List2FenYe2:SetCheck(0)
		
		local bar_index = 1
		for	i = 1, g_MaxNeiDanBarNum do
			local bShow = 1
			local posType = DataPool:LuaFnEnumPetNeiDanPosType(i - 1)
			if g_CurrentFilter == 2 and posType ~= 2 then
				bShow = 0
			elseif g_CurrentFilter == 3 and posType ~= 1 then
				bShow = 0
			elseif g_CurrentFilter == 4 and posType ~= 0 then
				bShow = 0
			end
			
			if bShow == 1 then
				PetNeidan_NeiDanList_SetItem(i - 1, bar_index, g_MaxNeiDanBagSize)
				bar_index = bar_index + 1
			end
		end
		
		if g_NeedChangeNeiDanScrollSize == 1 then
			PetNeidan_List2_Lace:RefreshLayout()
			PetNeidan_List2_Lace:SetScrollPosition(0)
			g_NeedChangeNeiDanScrollSize = 0
		end
	else
		PetNeidan_List2FenYe1:SetCheck(0)
		PetNeidan_List2FenYe2:SetCheck(1)
		
		DataPool:LuaFnInitPetNeiDanChipList(g_CurrentFilter)
		local nCount = DataPool:LuaFnGetPetNeiDanChipListCount()	
		
		for	i = 1, g_MaxNeiDanBarNum do
			PetNeidan_NeiDanList_SetItem_Chip(i, nCount)
		end
		
		if g_NeedChangeNeiDanScrollSize == 1 then
			PetNeidan_List2_Lace:RefreshLayout()
			PetNeidan_List2_Lace:SetScrollPosition(0)
			g_NeedChangeNeiDanScrollSize = 0
		end
	end
end

function PetNeidan_NeiDanList_SetItem(nd_index, idx, max_count)
	if g_NeiDanBarList[idx] == nil then
		return
	end
	
	if idx > max_count then
		g_NeiDanBarList[idx]:Hide()
		return
	end
	
	local bar = g_NeiDanBarList[idx]
	bar:Show()	
	
	local ctrlAction = bar:GetSubItem("PetNeidan_List2_LaceItem1_Icon")
	if ctrlAction ~= nil then
		ctrlAction:SetActionItem(-1)
		ctrlAction:SetProperty("DraggingEnabled", "True")
		local theNeiDanAction = DataPool:LuaFnEnumPlayerNeiDanAction(nd_index)
		if theNeiDanAction:GetID() ~= 0 then
			ctrlAction:SetActionItem(theNeiDanAction:GetID())
		end
	end
	
	local pnd_level = DataPool:LuaFnEnumPetNeiDanLevel(nd_index)
	if pnd_level >= 1 and pnd_level <= 5 then
		bar:GetSubItem("PetNeidan_List2_LaceItem1_IconJie"):Show()
		bar:GetSubItem("PetNeidan_List2_LaceItem1_IconJie"):SetProperty("Image", g_PND_Level_Image[pnd_level])
	end
	
	if g_CurrentSelectPet >= 0 then
		local posType = DataPool:LuaFnEnumPetNeiDanPosType(nd_index)
		if posType ~= 0 then
			local nd_id = DataPool:LuaFnEnumPetNeiDanId(nd_index)
			if nd_id > 0 then
				if DataPool:LuaFnIsPetHaveSkillCanFixedByPND(g_CurrentSelectPet, nd_id) ~= 1 then
					bar:GetSubItem("PetNeidan_List2_LaceItem1_IconMaskGray"):Show()
				end
			end
		end
	end
end

function PetNeidan_NeiDanList_SetItem_Chip(idx, max_count)
	if g_NeiDanBarList[idx] == nil then
		return
	end
	
	local bar = g_NeiDanBarList[idx]
	bar:Show()
	
	if idx > max_count then
	--	g_NeiDanBarList[idx]:Hide()
		return
	end
	
	local nd_id = DataPool:LuaFnGetPetNeiDanIDFromChipList(idx - 1)
	
	local ctrlAction = bar:GetSubItem("PetNeidan_List2_LaceItem1_Icon")
	if ctrlAction ~= nil then
		ctrlAction:SetActionItem(-1)
		
		local theNeiDanAction = EnumAction(nd_id, "pndchip")
		if theNeiDanAction:GetID() ~= 0 then
			ctrlAction:SetActionItem(theNeiDanAction:GetID())
		end
	end
	
	local bShowTip = DataPool:LuaFnIsPetNeiDanChipCanCompound(nd_id)
	if bShowTip == 1 then
		bar:GetSubItem("PetNeidan_List2_LaceItem1_Icontips"):Show()
	else
		bar:GetSubItem("PetNeidan_List2_LaceItem1_Icontips"):Hide()
	end
end

function PetNeidan_Update()
	
	local selfUnionPos = Variable:GetVariable("SelfUnionPos")
	if selfUnionPos ~= nil then
		PetNeidan_Frame:SetProperty("UnifiedPosition", selfUnionPos)
	end
	
	PetNeidan_Client_Button04:SetCheck(1)

	PetNeidan_InitListBar()
	
	local nLevel = Player:GetLevel()
	PetNeidan_Refresh_Page_Button(nLevel)
	PetNeidan_ShowPage()
	
	PetNeidan_ListCleanUpAction()
	
	PetNeidan_UpdatePetList()
	PetNeidan_UpdatePetInfo()
	
	PetNeidan_UpdateNeiDanList()
	
	local danqi_i = Player:GetData("DANQI_I")
	local danqi_ii = Player:GetData("DANQI_II")
	local danqi_iii = Player:GetData("DANQI_III")
	PetNeidan_Huaqi_Text4_NUM:SetText(tostring(danqi_i))
	PetNeidan_Huaqi_Text3_NUM:SetText(tostring(danqi_ii))
	PetNeidan_Huaqi_Text2_NUM:SetText(tostring(danqi_iii))
end

function PetNeidan_UpdatePetInfo()
	
	--技能
	for i = 1, g_MaxPetSkill do
		if g_PetSkillAct[i] ~= nil then
			g_PetSkillAct[i]:SetActionItem(-1)
			g_SkillFixTip[i]:Hide()
		end
	end
	
	if g_CurrentSelectPet >= 0 then
		local act_index = 1
		for i = 1, g_MaxPetSkill do
			local theSkillAction = Pet:EnumPetSkill(g_CurrentSelectPet, i - 1, "petskill")
			if theSkillAction:GetID() ~= 0 then
				if g_PetSkillAct[act_index] ~= nil then
					g_PetSkillAct[act_index]:SetActionItem(theSkillAction:GetID())
					if DataPool:LuaFnIsPetSkillFixedByPND(g_CurrentSelectPet, i - 1) == 1 then
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
		g_PetNeiDanAct[i]:SetProperty("DraggingEnabled", "True")
	end

	if g_CurrentSelectPet >= 0 then		

		for i = 1, g_MaxEquipNeiDanCount do
			
			local theNeiDanAction = DataPool:LuaFnEnumPetEquipNeiDanAction(g_CurrentSelectPet, i - 1)
			if theNeiDanAction:GetID() ~= 0 then
				g_PetNeiDanAct[i]:SetActionItem(theNeiDanAction:GetID())
				
				local pnd_level = DataPool:LuaFnEnumPetEquipNeiDanLevel(g_CurrentSelectPet, i - 1)
				if pnd_level >= 1 and pnd_level <= 5 then
					g_PetNeiDanAct_Level[i]:Show()
					g_PetNeiDanAct_Level[i]:SetProperty("Image", g_PND_Level_Image[pnd_level])
				end
				
				local bWork = DataPool:LuaFnEnumPetEquipNeiDanIsWork(g_CurrentSelectPet, i - 1)
				if bWork ~= 1 then
					g_PetNeiDanAct_NoEffect[i]:Show()
				end
			else
				local pet_savvy = Pet:GetSavvy(g_CurrentSelectPet)
				local pet_lx = Pet:GetLixing(g_CurrentSelectPet)
				if pet_savvy < g_NeiDanSlotInfo[i].savvy or pet_lx < g_NeiDanSlotInfo[i].lx then
					local strTemp = ScriptGlobal_Format("#{ZSND_230428_25}", tostring(g_NeiDanSlotInfo[i].savvy))
					g_PetNeiDanAct[i]:SetToolTip(strTemp)
					g_PetNeiDanAct_Lock[i]:Show()
				else
					if i >= 1 and i <= 3 then
						g_PetNeiDanAct[i]:SetToolTip("#{ZSND_230428_26}")
					elseif i >= 4 and i <= 6 then
						g_PetNeiDanAct[i]:SetToolTip("#{ZSND_230428_27}")
					elseif i == 7 then
						g_PetNeiDanAct[i]:SetToolTip("#{ZSND_230428_28}")
					end
				end
			end
		end
	end
	
	--资质
	PetNeidan_KongWei_ZizhiText1:Hide()
	PetNeidan_KongWei_ZizhiText2:SetText("")
	PetNeidan_KongWei_ZizhiText2:Hide("")
	PetNeidan_KongWei_Class:SetText("")

	if g_CurrentSelectPet >= 0 then
		local strApt = Pet:GetStrAptitude(g_CurrentSelectPet)
		local sprApt = Pet:GetIntAptitude(g_CurrentSelectPet)
		local conApt = Pet:GetPFAptitude(g_CurrentSelectPet)
		local intApt = Pet:GetStaAptitude(g_CurrentSelectPet)
		local dexApt = Pet:GetDexAptitude(g_CurrentSelectPet)
		
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
		
		PetNeidan_KongWei_ZizhiText1:Show()
		PetNeidan_KongWei_ZizhiText2:Show()
		PetNeidan_KongWei_ZizhiText2:SetText(stringApt)
		
		local aType = Pet:GetAttackTraitID(g_CurrentSelectPet)
		if aType == 11 then
			PetNeidan_KongWei_Class:SetText("#{ZSND_230428_156}")
		elseif aType == 12 then
			PetNeidan_KongWei_Class:SetText("#{ZSND_230428_155}")
		elseif aType == 13 then
			PetNeidan_KongWei_Class:SetText("#{ZSND_230428_154}")
		end
	end
	
	for i = 1, 6 do
		g_EffectText[i]:SetText("")
		g_EffectNumText[i]:SetText("")
	end
	
	if g_CurrentSelectPet >= 0 then
		for i = 1, 6 do
			local strNum = DataPool:LuaFnGetOuterPetNeiDanEffectNum(g_CurrentSelectPet, i)
			g_EffectNumText[i]:SetText(strNum.."% ")
			g_EffectText[i]:SetText(g_EffectName[i])
		end	
	end
	
	PetNeidan_FakeObject:Hide()
	if g_CurrentSelectPet >= 0 then
		PetNeidan_FakeObject:Show()
		Pet:SetModel(g_CurrentSelectPet)
	end
end

function PetNeidan_NeiDanClicked(idx)
	if g_NeiDanBarList[idx] ~= nil then	
		local ctrlAction = g_NeiDanBarList[idx]:GetSubItem("PetNeidan_List2_LaceItem1_Icon")
		if ctrlAction ~= nil then
			ctrlAction:DoSubAction()
		end
	end
end

function PetNeidan_NeiDanRClicked(idx)
	if g_ChipOrNot == 0 then
		if g_NeiDanBarList[idx] ~= nil then	
			local ctrlAction = g_NeiDanBarList[idx]:GetSubItem("PetNeidan_List2_LaceItem1_Icon")
			if ctrlAction ~= nil then
				ctrlAction:DoAction()
			end
		end
	else		
		local my_level = Player:GetData("LEVEL")
		if my_level < g_PlayerLevelLimit then
			PushDebugMessage("#{ZSND_230428_60}")
			return
		end

		if g_NeiDanBarList[idx] ~= nil then	
			local ctrlAction = g_NeiDanBarList[idx]:GetSubItem("PetNeidan_List2_LaceItem1_Icon")
			if ctrlAction ~= nil then
				ctrlAction:DoAction()
			end
		end
	end
end

function PetNeidan_NeiDanMouseMove(idx)

end

function PetNeidan_ListCleanUpAction()
	for i = 1, g_MaxNeiDanBarNum do
		if g_NeiDanBarList[i] then
			local ctrlAction = g_NeiDanBarList[i]:GetSubItem("PetNeidan_List2_LaceItem1_Icon")
			if ctrlAction then
				ctrlAction:SetProperty("NormalImage", "")
				ctrlAction:SetProperty("HoverImage", "")
				ctrlAction:SetToolTip("")
				ctrlAction:SetActionItem(-1)
			end
		end	
	end
end

function PetNeidan_Equip_NeiDan(nd_index, equip_index)

	local my_level = Player:GetData("LEVEL")
	if my_level < g_PlayerLevelLimit then
		PushDebugMessage("#{ZSND_230428_60}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(g_PreMissionID) ~= 1 then
		PushDebugMessage("#{ZSND_230428_06}")
		return
	end
	
	if g_CurrentSelectPet < 0 then
		PushDebugMessage("#{ZSND_230428_53}")
		return
	end
	
	local pet_level = Pet:GetLevel(g_CurrentSelectPet)
	if pet_level == nil or pet_level < g_PetLevelLimit then
		PushDebugMessage("#{ZSND_230428_130}")
		return
	end

	Pet:LuaFnEquipNeiDan(g_CurrentSelectPet, tonumber(nd_index), tonumber(equip_index))

end

function PetNeidan_UnEquip_NeiDan(equip_index)

	local my_level = Player:GetData("LEVEL")
	if my_level < g_PlayerLevelLimit then
		PushDebugMessage("#{ZSND_230428_60}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(g_PreMissionID) ~= 1 then
		PushDebugMessage("#{ZSND_230428_06}")
		return
	end
	
	if g_CurrentSelectPet < 0 then
	--	PushDebugMessage("#{ZSND_230428_53}")
		return
	end
	
	Pet:LuaFnUnEquipNeiDan(g_CurrentSelectPet, tonumber(equip_index))

end

function PetNeidan_PetEquipNeiDan_RClick(index)
	g_PetNeiDanAct[index]:DoAction()
end

function PetNeidan_Close()
	this:Hide()
end

function PetNeidan_OnHidden()
	PetNeidan_CleanUp()
	DataPool:LuaFn_MouseCmd_Cancel_PND_HQ()
	PetNeidan_FakeObject:DetachWindowEx("My_Pet")
	DataPool:LuaFnSortPlayerPetNeiDanList(-1)
end

function PetNeidan_Refresh_ChipPageTip()
	local bShowTip = DataPool:LuaFnHavePetNeiDanChipCanCompound()
	PetNeidan_List2FenYe1tips:Hide()
	if bShowTip == 1 then
		PetNeidan_List2FenYe2tips:Show()
		PetNeidan_Client_Button04tips:Show()
		PetNeidan_Pet_Buttontips:Show()
	else
		PetNeidan_List2FenYe2tips:Hide()
		PetNeidan_Client_Button04tips:Hide()
		PetNeidan_Pet_Buttontips:Hide()
	end
end

function PetNeidan_Huaqi_Click()
	DataPool:LuaFn_MouseCmd_PND_HQ()
end
--珍兽技能点击
function PetNeidan_Skill_Clicked(skill_idx)
	if g_CurrentSelectPet < 0 or g_CurrentSelectPet >= g_PetMaxNumber then
		return
	end

	if not Pet:IsPresent(g_CurrentSelectPet) then
		return
	end

	if Pet:GetSkillPassive(g_CurrentSelectPet, skill_idx - 1) == 0 then
		PushDebugMessage("请将该技能拖拽到技能快捷栏使用 。")
	end
end

--碎片内丹切换
function PetNeidan_SubFenYe_Switch(idx)
	if g_ChipOrNot == idx then
		return
	end
	
	g_ChipOrNot = idx
	g_CurrentFilter = 1
	PetNeidan_List2_ShowType:SetText("#{ZSND_230428_48}")
	g_NeedChangeNeiDanScrollSize = 1
	PetNeidan_UpdateNeiDanList()
end

--显示内丹类别选择
function PetNeidan_OnSelectShowType()
	local _, nIndex = PetNeidan_List2_ShowType:GetCurrentSelect()
	
	if g_CurrentFilter == nIndex then
		return
	end
	g_CurrentFilter = nIndex
	g_NeedChangeNeiDanScrollSize = 1
	PetNeidan_UpdateNeiDanList()
end

--内丹图鉴
function PetNeidan_OpenTujian()
	Pet:LuaFnOpenPetNeiDan("tujian")
end

--装备
function PetNeidan_SelfEquip_Page_Switch()
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	OpenEquip(1);
end

--资料
function PetNeidan_SelfData_Page_Switch()
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("self");
end

--子女
function PetNeidan_Infant_Page_Switch()
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	else
		PetNeidan_Infant:SetCheck(0)
	end
end

--武魂
function PetNeidan_Wuhun_Page_Switch()
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	ToggleWuhunPage();
end

--修炼
function PetNeidan_Xiulian_Page_Switch()
    local nLevel = Player:GetData("LEVEL")
	if(nLevel >= 70) then
		Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
		XiuLianPage();
	else
	    PetNeidan_Xiulian:SetCheck(0)
	    PushDebugMessage("#{XL_090707_62}")
	end
end

--秘籍
function PetNeidan_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenMijiPage();
	if nRet ~= 1 then
		PetNeidan_Miji:SetCheck(0)
	end
end

--真元
function PetNeidan_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	if bRet ~= 1 then
		PetNeidan_ZhenYuan:SetCheck(0)
	end
end

--经脉
function PetNeidan_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenJingMaiPage();
	if nRet ~= 1 then
		PetNeidan_JingMai:SetCheck(0)
	end
end

--神鼎
function PetNeidan_ShenDing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenShenDingPage();
	if nRet ~= 1 then
		PetNeidan_ShenDing:SetCheck(0)
	end
end

--侠印
function PetNeidan_JueWei_Page_Switch()
	-- 等级限制
	if Player:GetLevel() < 85 then
		PushDebugMessage("#{JXJW_140822_20}");
		return
	end
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if bRet == 1 then
		this:Hide();
	else
		PetNeidan_JueWei:SetCheck(0)
	end
end

--骑乘
function PetNeidan_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	OpenRidePage();
end

--其他
function PetNeidan_OtherInfo_Page_Switch()
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	OtherInfoPage();
end

--五行宝鉴
function PetNeidan_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()

end

--珍兽
function PetNeidan_Pet_Page_Switch()
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	TogglePetPage();
end

--御兽
function PetNeidan_YuShou_Page_Switch()
	
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	
	local nPage = 0;
	
	local p1_LastPointState = Player:GetPetMasterPointState(28 , "State")
	if p1_LastPointState ~= nil and p1_LastPointState == 2 then
		nPage = 1;
	end

	local p2_LastPointState = Player:GetPetMasterPointState(57 , "State")
	if p2_LastPointState ~= nil and p2_LastPointState == 2 then
		nPage = 2;
	end

	local p3_LastPointState = Player:GetPetMasterPointState(86 , "State")
	if p3_LastPointState ~= nil and p3_LastPointState == 2 then
		nPage = 3;
	end
		
	local ret = Lua_OpenPetMasterPage(nPage)
	if ret ~= 1 then
		PetNeidan_Client_Button03:SetCheck(0)
	end

end

--幻灵
function PetNeidan_HuanLing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	Pet:Lua_OpenPetHuanLingUI()
end

function PetNeidan_Refresh_Page_Button(nLevel)

	if 1 == 1 then
		return
	end
	
	--神鼎
	if nLevel < 15 then
		PetNeidan_ShenDing:Disable()
		PetNeidan_ShenDing_tips:Show()
	else
		PetNeidan_ShenDing:Enable()
		PetNeidan_ShenDing_tips:Hide()
	end
	
	--子女
	local InfantCount = Infant:GetInfantCount();
	if nLevel < 50 or InfantCount <= 0 then
		PetNeidan_Infant:Disable()
		PetNeidan_Infant_tips:Show()
	else
		PetNeidan_Infant:Enable()
		PetNeidan_Infant_tips:Hide()
	end
	
	PetNeidan_Wuhun:Enable()
	PetNeidan_Wuhun_tips:Hide()

	--修炼
	if nLevel < 70 then
		PetNeidan_Xiulian:Disable()
		PetNeidan_Xiulian_tips:Show()
	else
		PetNeidan_Xiulian:Enable()
		PetNeidan_Xiulian_tips:Hide()
	end
	
	--秘籍
	local ret = DataPool:Lua_IsMissionHaveDone(1651)
	if nLevel < 75 or ret == 0 then
		PetNeidan_Miji:Disable()
		PetNeidan_Miji_tips:Show()
	else
		PetNeidan_Miji:Enable()
		PetNeidan_Miji_tips:Hide()
	end
	
	--真元
	local ret = DataPool:Lua_IsMissionHaveDone(1600)
	if nLevel < 80 or ret == 0 then
		PetNeidan_ZhenYuan:Disable()
		PetNeidan_ZhenYuan_tips:Show()
	else
		PetNeidan_ZhenYuan:Enable()
		PetNeidan_ZhenYuan_tips:Hide()
	end
	
	--侠印
	if nLevel < 85 then
		PetNeidan_JueWei:Disable()
		PetNeidan_JueWei_tips:Show()
	else
		PetNeidan_JueWei:Enable()
		PetNeidan_JueWei_tips:Hide()
	end
	
	--经脉
	local ret = DataPool:Lua_IsMissionHaveDone(1554)
	if nLevel < 90 or ret == 0  then
		PetNeidan_JingMai:Disable()
		PetNeidan_JingMai_tips:Show()
	else
		PetNeidan_JingMai:Enable()
		PetNeidan_JingMai_tips:Hide()
	end

	if nLevel < 85 then
		PetNeidan_BaoJian:Disable()
		PetNeidan_BaoJian_tips:Show()
	else
		PetNeidan_BaoJian:Enable()
		PetNeidan_BaoJian_tips:Hide()
	end

	--武意
	if MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85 then
		PetNeidan_WuYi:Enable()
		PetNeidan_WuYi_tips:Hide()
	else
		PetNeidan_WuYi:Disable()
		PetNeidan_WuYi_tips:Show()
	end
	
	PetNeidan_RefreshWuYiTip()
		
	--九星神器DIY技能
	if DataPool:Lua_IsMissionHaveDone(1950) == 1 then
		PetNeidan_ShenQi:Enable()
		PetNeidan_ShenQi_tips:Hide()
	else
		PetNeidan_ShenQi:Disable()
		PetNeidan_ShenQi_tips:Show()
	end
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		PetNeidan_Armor:Enable()
		PetNeidan_Armor_tips:Hide()
	else
		PetNeidan_Armor:Disable()
		PetNeidan_Armor_tips:Show()
	end
	
	PetNeidan_Refresh_ChipPageTip()
	
	if nLevel >= 30 then
		PetNeidan_CangPin:Enable()
		PetNeidan_CangPin_tips:Hide()
	else
		PetNeidan_CangPin:Disable()
		PetNeidan_CangPin_tips:Show()
	end
	
	PetNeidan_RefreshCangPinTip()
end

--武意
function PetNeidan_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

--九星神器DIY技能
function PetNeidan_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function PetNeidan_RefreshWuYiTip()
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_PetNeidan_PageButton[idx]:GetProperty("UnifiedXPosition");
			PetNeidan_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1 then
		PetNeidan_WuYi_Buttontips:Show()
	else
		PetNeidan_WuYi_Buttontips:Hide()
	end
end

--内甲
function PetNeidan_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function PetNeidan_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", PetNeidan_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function PetNeidan_RefreshCangPinTip()
	local CangPinClassCount = 4
	local bHaveChipToMelt = DataPool:LuaFnIsCanMeltCangPinChip()
	local bTip = 0
	for i = 1, CangPinClassCount do
		if DataPool:LuaFnIsCangPinClassShowTip(i - 1) == 1 then
			bTip = 1
		end
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 16 and g_PageButtonTipsPos[idx] then -- 名物
			local newpos = g_PageButtonTipsPos[idx] --28 + g_PetNeidan_PageButton[idx]:GetProperty("UnifiedXPosition");
			PetNeidan_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		PetNeidan_CangPin_Buttontips:Show()
	else
		PetNeidan_CangPin_Buttontips:Hide()
	end
end

function PetNeidan_ShowPage()

	for i = 1, table.getn(g_PetNeidan_Page) do
		g_PetNeidan_PageButton[i]:Hide()
		g_PetNeidan_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	PetNeidan_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_PetNeidan_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_PetNeidan_Page) do
			if i ~= nPageNumber then
				g_PetNeidan_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_PetNeidan_Page) do
		if PetNeidan_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_PetNeidan_PageButton[g_PageCount]:Show()
			g_PetNeidan_PageButton[g_PageCount]:SetText(g_PetNeidan_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if PetNeidan_IsPageEnable(i) == 1 then
				g_PetNeidan_PageButton[g_PageCount]:Enable()
				g_PetNeidan_PageMask[g_PageCount]:Hide()
			else
				g_PetNeidan_PageButton[g_PageCount]:Disable()
				g_PetNeidan_PageMask[g_PageCount]:Show()
				if g_PetNeidan_Page[i].Tip ~= "" then
					g_PetNeidan_PageMask[g_PageCount]:SetToolTip(g_PetNeidan_Page[i].Tip)
				end
			end
		end
	end
	
	PetNeidan_RefreshWuYiTip()
	PetNeidan_Refresh_ChipPageTip()
	PetNeidan_RefreshCangPinTip()
	
end

function PetNeidan_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		PetNeidan_SelfEquip_Page_Switch(0);
	elseif idx == 2 then--资料
		PetNeidan_SelfData_Page_Switch()
	elseif idx == 3 then--珍兽
		--SelfData_Pet_Down()
	elseif idx == 4 then--子女
		PetNeidan_Infant_Page_Switch()
	elseif idx == 5 then--武魂
		PetNeidan_Wuhun_Page_Switch()
	elseif idx == 6 then--修炼
		PetNeidan_Xiulian_Page_Switch()
	elseif idx == 7 then--秘籍
		PetNeidan_Miji_Page_Switch()
	elseif idx == 8 then--真元
		PetNeidan_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		PetNeidan_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		PetNeidan_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		PetNeidan_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		PetNeidan_OpenBaoJian()
	elseif idx == 13 then--武意
		PetNeidan_OpenWuYi()
	elseif idx == 14 then--神器
		PetNeidan_OpenShenQi()
	elseif idx == 15 then--星盘
		PetNeidan_Armor_Page_Switch()
	elseif idx == 16 then--名物
		PetNeidan_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		PetNeidan_OtherInfo_Page_Switch()
	end
end

function PetNeidan_CheckPage(idx)
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
	elseif idx == 6 then--修炼
		return 1
	elseif idx == 7 then--秘籍
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 8 then--真元
		--if Player:GetData("Is2606S") == 1 then
		--	return 0
		--end
		return 1
	elseif idx == 9 then--经脉
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 10 then--神鼎
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 11 then--侠印
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 12 then--宝鉴
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 13 then--武意
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 14 then--神器
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 15 then--星盘
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 16 then--名物
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 17 then--其他
		return 1
	end
	return 0
end

function PetNeidan_IsPageEnable(idx)
	
	local nLevel = Player:GetLevel()
	
	if idx == 1 then--装备
		return 1
	elseif idx == 2 then--资料
		return 1
	elseif idx == 3 then--珍兽
		return 1
	elseif idx == 4 then--子女
		local InfantCount = Infant:GetInfantCount();
		if ( nLevel < 50 ) or ( InfantCount <= 0 ) then
			return 0
		end
		return 1
	elseif idx == 5 then--武魂
		return 1
	elseif idx == 6 then--修炼
		if ( nLevel < 70 ) then
			return 0
		end
		return 1
	elseif idx == 7 then--秘籍
		local ret = DataPool:Lua_IsMissionHaveDone(1651)
		if ( nLevel < 75 ) or ( ret == 0 ) then
			return 0
		end
		return 1
	elseif idx == 8 then--真元
		local ret = DataPool:Lua_IsMissionHaveDone(1600)
		if ( nLevel < 80 ) or ( ret == 0 ) then
			return 0
		end
		return 1
	elseif idx == 9 then--经脉
		local ret = DataPool:Lua_IsMissionHaveDone(1554)
		if ( nLevel < 90 ) or ( ret == 0 )  then
			return 0
		end
		return 1
	elseif idx == 10 then--神鼎
		if ( nLevel < 15 ) then
			return 0
		end
		return 1
	elseif idx == 11 then--侠印
		if ( nLevel < 85 ) then
			return 0
		end
		return 1
	elseif idx == 12 then--宝鉴
		if ( nLevel < 85 ) then
			return 0
		end
		return 1
	elseif idx == 13 then--武意
		if (MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
			return 1
		end
		return 0
	elseif idx == 14 then--神器
		if (DataPool:Lua_IsMissionHaveDone(1950) == 1) then
			return 1
		end
		return 0
	elseif idx == 15 then--星盘
		if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
			return 1
		end
		return 0
	elseif idx == 16 then--名物
		if nLevel < 30 then
			return 0
		end
		return 1
	elseif idx == 17 then--其他
		return 1
	end
	return 0
end

function PetNeidan_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


