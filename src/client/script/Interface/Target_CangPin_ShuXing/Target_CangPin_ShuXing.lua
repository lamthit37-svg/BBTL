--Target_CangPin_ShuXing
--!!!reloadscript =Target_CangPin_ShuXing

local g_Target_CangPin_ShuXing_Frame_UnifiedPosition = ""
local m_ObjServerId = -1
local g_objCared = -1

local g_CurClass = 0	--当前大类

local g_InitList = 0

local g_MaxSetBarNum = 0
local g_MaxCangPinBarNum = 10

local g_SetBarList = {}
local g_CangPinBarList = {}

local g_SetList = {}

local g_CurSet = -1
local g_CurCangPin = 0
local g_CurCangPinPage = 0
local g_CurCangPinMaxPage = 1
local g_EachPageCangPinNum = 4
local g_EachPageCangPinNum_Set2 = 7
local g_SetCount = {}

local g_ClassCount = 4
local g_MaxStar = 9

local g_TargetCangPinId = 0

local g_LimitLevel = 30

local g_StarImg = {
	"set:CangPin image:CangPin_Level1",
	"set:CangPin image:CangPin_Level2",
	"set:CangPin image:CangPin_Level3",
	"set:CangPin image:CangPin_Level4",
	"set:CangPin image:CangPin_Level5",
	"set:CangPin image:CangPin_Level6",
	"set:CangPin image:CangPin_Level7",
	"set:CangPin image:CangPin_Level8",
	"set:CangPin image:CangPin_Level9",
}

local g_ClassBtn = {}

local g_ClassLevelStr = {
	"#{CPSJ_260112_5}",
	"#{CPSJ_260112_78}",
	"#{CPSJ_260112_77}",
	"#{CPSJ_260112_79}",
}

local g_CangPinActionButtons = {}
local g_CangPinLockImages = {}
local g_CangPinStarImages = {}
local g_CangPinChipTexts = {}
local g_CangPinNameTexts = {}
local g_CangPinNameBKs = {}
local g_CangPinBKImages = {}

local g_CangPinActionButtons_Set2 = {}
local g_CangPinLockImages_Set2 = {}
local g_CangPinStarImages_Set2 = {}
local g_CangPinChipTexts_Set2 = {}
local g_CangPinNameTexts_Set2 = {}
local g_CangPinNameBKs_Set2 = {}
local g_CangPinBKImages_Set2 = {}

local g_BannerImages = {
	"set:CangPin_1 image:CangPin_YiShouBanner",
	"set:CangPin_1 image:CangPin_YuShangBanner",
	"set:CangPin_1 image:CangPin_TianBingBanner",
	"set:CangPin_1 image:CangPin_BaiBaoBanner",
}

local g_MaxQualUpLevel = 4

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_Target_CangPin_ShuXing_Page = {
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

local g_TargetPageButton = {}
local g_TargetPageCount = 0
local g_TargetPageOrder = {}

function Target_CangPin_ShuXing_PreLoad()
	this:RegisterEvent("OPEN_OTHER_CANGPIN", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
end

function Target_CangPin_ShuXing_OnLoad()
	g_Target_CangPin_ShuXing_Frame_UnifiedPosition = Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition")
	
	g_ClassBtn[1] = Target_CangPin_ShuXing_GoTo_PageBtn_1
	g_ClassBtn[2] = Target_CangPin_ShuXing_GoTo_PageBtn_3
	g_ClassBtn[3] = Target_CangPin_ShuXing_GoTo_PageBtn_2
	g_ClassBtn[4] = Target_CangPin_ShuXing_GoTo_PageBtn_4
	
	g_CangPinActionButtons[1] = Target_CangPin_ShuXing_CangPin_ActionButton
	g_CangPinActionButtons[2] = Target_CangPin_ShuXing_CangPin2_ActionButton
	g_CangPinActionButtons[3] = Target_CangPin_ShuXing_CangPin3_ActionButton
	g_CangPinActionButtons[4] = Target_CangPin_ShuXing_CangPin4_ActionButton
	
	g_CangPinLockImages[1] = Target_CangPin_ShuXing_CangPin_LockImage
	g_CangPinLockImages[2] = Target_CangPin_ShuXing_CangPin2_LockImage
	g_CangPinLockImages[3] = Target_CangPin_ShuXing_CangPin3_LockImage
	g_CangPinLockImages[4] = Target_CangPin_ShuXing_CangPin4_LockImage
	
	g_CangPinStarImages[1] = Target_CangPin_ShuXing_CangPin_LevelNum
	g_CangPinStarImages[2] = Target_CangPin_ShuXing_CangPin2_LevelNum
	g_CangPinStarImages[3] = Target_CangPin_ShuXing_CangPin3_LevelNum
	g_CangPinStarImages[4] = Target_CangPin_ShuXing_CangPin4_LevelNum
	
	g_CangPinChipTexts[1] = Target_CangPin_ShuXing_CangPin_NumText
	g_CangPinChipTexts[2] = Target_CangPin_ShuXing_CangPin2_NumText
	g_CangPinChipTexts[3] = Target_CangPin_ShuXing_CangPin3_NumText
	g_CangPinChipTexts[4] = Target_CangPin_ShuXing_CangPin4_NumText
	
	g_CangPinNameTexts[1] = Target_CangPin_ShuXing_CangPin_NameBK_Text
	g_CangPinNameTexts[2] = Target_CangPin_ShuXing_CangPin2_NameBK_Text
	g_CangPinNameTexts[3] = Target_CangPin_ShuXing_CangPin3_NameBK_Text
	g_CangPinNameTexts[4] = Target_CangPin_ShuXing_CangPin4_NameBK_Text
	
	g_CangPinNameBKs[1] = Target_CangPin_ShuXing_CangPin_NameBK
	g_CangPinNameBKs[2] = Target_CangPin_ShuXing_CangPin2_NameBK
	g_CangPinNameBKs[3] = Target_CangPin_ShuXing_CangPin3_NameBK
	g_CangPinNameBKs[4] = Target_CangPin_ShuXing_CangPin4_NameBK
	
	g_CangPinBKImages[1] = Target_CangPin_ShuXing_CangPin_BKImage
	g_CangPinBKImages[2] = Target_CangPin_ShuXing_CangPin2_BKImage
	g_CangPinBKImages[3] = Target_CangPin_ShuXing_CangPin3_BKImage
	g_CangPinBKImages[4] = Target_CangPin_ShuXing_CangPin4_BKImage
	
	--
	
	g_CangPinActionButtons_Set2[1] = Target_CangPin_ShuXing_Special_CangPin_ActionButton_1_1
	g_CangPinActionButtons_Set2[2] = Target_CangPin_ShuXing_Special_CangPin_ActionButton_1_2
	g_CangPinActionButtons_Set2[3] = Target_CangPin_ShuXing_Special_CangPin_ActionButton_1_3
	g_CangPinActionButtons_Set2[4] = Target_CangPin_ShuXing_Special_CangPin_ActionButton_1_4
	g_CangPinActionButtons_Set2[5] = Target_CangPin_ShuXing_Special_CangPin2_ActionButton
	g_CangPinActionButtons_Set2[6] = Target_CangPin_ShuXing_Special_CangPin3_ActionButton
	g_CangPinActionButtons_Set2[7] = Target_CangPin_ShuXing_Special_CangPin4_ActionButton
	
	g_CangPinLockImages_Set2[1] = Target_CangPin_ShuXing_Special_CangPin_LockImage_1_1
	g_CangPinLockImages_Set2[2] = Target_CangPin_ShuXing_Special_CangPin_LockImage_1_2
	g_CangPinLockImages_Set2[3] = Target_CangPin_ShuXing_Special_CangPin_LockImage_1_3
	g_CangPinLockImages_Set2[4] = Target_CangPin_ShuXing_Special_CangPin_LockImage_1_4
	g_CangPinLockImages_Set2[5] = Target_CangPin_ShuXing_Special_CangPin2_LockImage
	g_CangPinLockImages_Set2[6] = Target_CangPin_ShuXing_Special_CangPin3_LockImage
	g_CangPinLockImages_Set2[7] = Target_CangPin_ShuXing_Special_CangPin4_LockImage
	
	g_CangPinStarImages_Set2[1] = Target_CangPin_ShuXing_Special_CangPin_LevelNum_1_1
	g_CangPinStarImages_Set2[2] = Target_CangPin_ShuXing_Special_CangPin_LevelNum_1_2
	g_CangPinStarImages_Set2[3] = Target_CangPin_ShuXing_Special_CangPin_LevelNum_1_3
	g_CangPinStarImages_Set2[4] = Target_CangPin_ShuXing_Special_CangPin_LevelNum_1_4
	g_CangPinStarImages_Set2[5] = Target_CangPin_ShuXing_Special_CangPin2_LevelNum
	g_CangPinStarImages_Set2[6] = Target_CangPin_ShuXing_Special_CangPin3_LevelNum
	g_CangPinStarImages_Set2[7] = Target_CangPin_ShuXing_Special_CangPin4_LevelNum
	
	g_CangPinChipTexts_Set2[1] = Target_CangPin_ShuXing_Special_CangPin_NumText_1_1
	g_CangPinChipTexts_Set2[2] = Target_CangPin_ShuXing_Special_CangPin_NumText_1_2
	g_CangPinChipTexts_Set2[3] = Target_CangPin_ShuXing_Special_CangPin_NumText_1_3
	g_CangPinChipTexts_Set2[4] = Target_CangPin_ShuXing_Special_CangPin_NumText_1_4
	g_CangPinChipTexts_Set2[5] = Target_CangPin_ShuXing_Special_CangPin2_NumText
	g_CangPinChipTexts_Set2[6] = Target_CangPin_ShuXing_Special_CangPin3_NumText
	g_CangPinChipTexts_Set2[7] = Target_CangPin_ShuXing_Special_CangPin4_NumText
	
	g_CangPinNameTexts_Set2[1] = nil
	g_CangPinNameTexts_Set2[2] = nil
	g_CangPinNameTexts_Set2[3] = nil
	g_CangPinNameTexts_Set2[4] = nil
	g_CangPinNameTexts_Set2[5] = Target_CangPin_ShuXing_Special_CangPin2_NameBK_Text
	g_CangPinNameTexts_Set2[6] = Target_CangPin_ShuXing_Special_CangPin3_NameBK_Text
	g_CangPinNameTexts_Set2[7] = Target_CangPin_ShuXing_Special_CangPin4_NameBK_Text
	
	g_CangPinNameBKs_Set2[1] = nil
	g_CangPinNameBKs_Set2[2] = nil
	g_CangPinNameBKs_Set2[3] = nil
	g_CangPinNameBKs_Set2[4] = nil
	g_CangPinNameBKs_Set2[5] = Target_CangPin_ShuXing_Special_CangPin2_NameBK
	g_CangPinNameBKs_Set2[6] = Target_CangPin_ShuXing_Special_CangPin3_NameBK
	g_CangPinNameBKs_Set2[7] = Target_CangPin_ShuXing_Special_CangPin4_NameBK
	
	g_CangPinBKImages_Set2[1] = nil
	g_CangPinBKImages_Set2[2] = nil
	g_CangPinBKImages_Set2[3] = nil
	g_CangPinBKImages_Set2[4] = nil
	g_CangPinBKImages_Set2[5] = Target_CangPin_ShuXing_Special_CangPin2_BKImage
	g_CangPinBKImages_Set2[6] = Target_CangPin_ShuXing_Special_CangPin3_BKImage
	g_CangPinBKImages_Set2[7] = Target_CangPin_ShuXing_Special_CangPin4_BKImage
	
	g_TargetPageButton[1] = Target_CangPin_ShuXing_SelfEquip
	g_TargetPageButton[2] = Target_CangPin_ShuXing_SelfData
	g_TargetPageButton[3] = Target_CangPin_ShuXing_Pet
	g_TargetPageButton[4] = Target_CangPin_ShuXing_infant
	g_TargetPageButton[5] = Target_CangPin_ShuXing_Wuhun
	g_TargetPageButton[6] = Target_CangPin_ShuXing_Miji
	g_TargetPageButton[7] = Target_CangPin_ShuXing_ZhenYuan
	g_TargetPageButton[8] = Target_CangPin_ShuXing_JingMai
	g_TargetPageButton[9] = Target_CangPin_ShuXing_ShenDing
	g_TargetPageButton[10] = Target_CangPin_ShuXing_JueWei
	g_TargetPageButton[11] = Target_CangPin_ShuXing_BaoJian
	g_TargetPageButton[12] = Target_CangPin_ShuXing_WuYi
	g_TargetPageButton[13] = Target_CangPin_ShuXing_ShenQi
	g_TargetPageButton[14] = Target_CangPin_ShuXing_Armor
	g_TargetPageButton[15] = Target_CangPin_ShuXing_CangPin
	
end

function Target_CangPin_ShuXing_OnEvent(event)

	if event == "OPEN_OTHER_CANGPIN" then
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

		g_CurSet = -1
		g_CurClass = 3
		--Target_CangPin_ShuXing_CleanUp()
		this:Show()
		Target_CangPin_ShuXing_Update()
		
		Target_CangPin_ShuXing_ShowPage()
		
		local otherUnionPos = Variable:GetVariable("OtherUnionPos")
		if otherUnionPos ~= nil then
			Target_CangPin_ShuXing_Frame:SetProperty("UnifiedPosition", otherUnionPos)
		end
		return
	end

	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		Target_CangPin_ShuXing_Frame_On_ResetPos()	 
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end
end

function Target_CangPin_ShuXing_InitList()
	if g_InitList == 0 then
		for i = 1, g_ClassCount do
			g_SetCount[i] = 0
			g_SetList[i] = {}
		end

		local all_set_count = LuaFnGetMaxCangPinSetCount()
		for i = 1, all_set_count do
			local set_id, class_id = LuaFnGetCangPinSetFromTable(i - 1)
			if set_id >= 0 and class_id >= 0 and class_id < g_ClassCount then
				g_SetCount[class_id + 1] = g_SetCount[class_id + 1] + 1
				g_SetList[class_id + 1][g_SetCount[class_id + 1]] = set_id
			end
		end
		
		for i = 1, g_ClassCount do
			for m = 1, g_SetCount[i] - 1 do
				for n = m + 1, g_SetCount[i] do
					local oValue_a = LuaFnGetCangPinSetOrderValue(g_SetList[i][m])
					local oValue_b = LuaFnGetCangPinSetOrderValue(g_SetList[i][n])
					if oValue_b > oValue_a then
						local tmp = g_SetList[i][m]
						g_SetList[i][m] = g_SetList[i][n]
						g_SetList[i][n] = tmp
					end
				end
			end
		end
		
		g_MaxSetBarNum = 0
		for i = 1, g_ClassCount do
			if g_SetCount[i] > g_MaxSetBarNum then
				g_MaxSetBarNum = g_SetCount[i]
			end
		end
		
		for i = 1, g_MaxSetBarNum do
			local bar = Target_CangPin_ShuXing_TypeList:AddChild("Target_CangPin_ShuXing_TypeListItem")
		--	bar:SetProperty("SuperBarButtonHover", "SuperBarHoverSection")
			g_SetBarList[i] = bar			
			
			bar:GetSubItem("Target_CangPin_ShuXing_TypeListItem_Btn"):SetProperty("CheckMode", "2")
			bar:GetSubItem("Target_CangPin_ShuXing_TypeListItem_Btn"):SetEvent("MouseLButtonDown", string.format("Target_CangPin_ShuXing_SetSelect(%d)", i))
		end

		g_InitList = 1
	end
end

function Target_CangPin_ShuXing_Update()
	Target_CangPin_ShuXing_CangPin:SetCheck(1)
	Target_CangPin_ShuXing_Update_ClassBtn()
	Target_CangPin_ShuXing_Update_SetList()
	Target_CangPin_ShuXing_Update_CangPinList()
	Target_CangPin_ShuXing_Update_SetInfo()
	local strTemp = ""
	
	Target_CangPin_ShuXing_TotalLevelBK:SetProperty("Image", tostring(g_BannerImages[g_CurClass]))
	
	local collect_val = DataPool:LuaFnGetOtherCangPinClassCollectValue(g_CurClass - 1)
	local max_collect_val = DataPool:LuaFnGetCangPinMaxClassCollectValue(g_CurClass - 1)
	local class_level, cur_val, max_val = LuaFnGetCangPinClassLevel(collect_val)
	Target_CangPin_ShuXing_TotalLevel_Progress:SetProgress(tonumber(cur_val), tonumber(max_val))
	
	strTemp = ScriptGlobal_Format("#{CPSJ_260112_147}", tostring(cur_val), tostring(max_val))
	Target_CangPin_ShuXing_TotalLevel_JinDuNumText:SetText(tostring(strTemp))
	
	Target_CangPin_ShuXing_TotalLevel_Text:SetText("")
	if g_ClassLevelStr[g_CurClass] ~= nil then
		strTemp = ScriptGlobal_Format(g_ClassLevelStr[g_CurClass], tostring(class_level))
	end
	Target_CangPin_ShuXing_TotalLevel_Text:SetText(tostring(strTemp))
	
	Target_CangPin_ShuXing_ShowClassLevelImage(tonumber(class_level))
end

local g_NumImages = {
	[0] = "set:CangPin_1 image:CangPin_LevelNum0",
	[1] = "set:CangPin_1 image:CangPin_LevelNum1",
	[2] = "set:CangPin_1 image:CangPin_LevelNum2",
	[3] = "set:CangPin_1 image:CangPin_LevelNum3",
	[4] = "set:CangPin_1 image:CangPin_LevelNum4",
	[5] = "set:CangPin_1 image:CangPin_LevelNum5",
	[6] = "set:CangPin_1 image:CangPin_LevelNum6",
	[7] = "set:CangPin_1 image:CangPin_LevelNum7",
	[8] = "set:CangPin_1 image:CangPin_LevelNum8",
	[9] = "set:CangPin_1 image:CangPin_LevelNum9",
}

function Target_CangPin_ShuXing_ShowClassLevelImage(lv)
	Target_CangPin_ShuXing_LevelNumImage_1:Hide()
	Target_CangPin_ShuXing_LevelNumImage_2:Hide()
	Target_CangPin_ShuXing_LevelNumImage_3:Hide()
	
	if lv >= 0 and lv < 10 then
		Target_CangPin_ShuXing_LevelNumImage_1:Show()
		Target_CangPin_ShuXing_LevelNumImage_1_1:SetProperty("Image", tostring(g_NumImages[lv]))
	elseif lv >= 10 and lv < 100 then
		local num1 = math.floor(lv / 10)
		local num2 = math.mod(lv, 10)
		Target_CangPin_ShuXing_LevelNumImage_2:Show()
		Target_CangPin_ShuXing_LevelNumImage_2_1:SetProperty("Image", tostring(g_NumImages[num1]))
		Target_CangPin_ShuXing_LevelNumImage_2_2:SetProperty("Image", tostring(g_NumImages[num2]))
	elseif lv >= 100 and lv < 1000 then
		local num1 = math.floor(lv / 100)
		local num2 = math.floor(math.mod(lv, 100) / 10)
		local num3 = math.mod(lv, 10)
		Target_CangPin_ShuXing_LevelNumImage_3:Show()
		Target_CangPin_ShuXing_LevelNumImage_3_1:SetProperty("Image", tostring(g_NumImages[num1]))
		Target_CangPin_ShuXing_LevelNumImage_3_2:SetProperty("Image", tostring(g_NumImages[num2]))
		Target_CangPin_ShuXing_LevelNumImage_3_3:SetProperty("Image", tostring(g_NumImages[num3]))
	end
end

function Target_CangPin_ShuXing_GetClassCollectLevel(val)
	local lv = 0
	local cur_val = val
	local max_val = 10
	if val >= 10 and val < 30 then
		lv = 1
		cur_val = val - 10
		max_val = 20
	elseif val >= 30 and val < 50 then
		lv = 2
		cur_val = val - 30
		max_val = 20
	elseif val >= 50 and val < 70 then
		lv = 3
		cur_val = val - 50
		max_val = 20
	elseif val >= 70 and val < 90 then
		lv = 4
		cur_val = val - 70
		max_val = 20
	elseif val >= 90 and val < 120 then
		lv = 5
		cur_val = val - 90
		max_val = 30
	elseif val >= 120 and val < 150 then
		lv = 6
		cur_val = val - 120
		max_val = 30
	elseif val >= 150 and val < 200 then
		lv = 7
		cur_val = val - 150
		max_val = 50
	elseif val >= 200 then
		lv = math.floor(val / 100) + 6
		cur_val = math.mod(val, 100)
		max_val = 100
	end
	return lv, cur_val, max_val
end

function Target_CangPin_ShuXing_Update_SetList()
	Target_CangPin_ShuXing_InitList()
	
	local uClassNum = 0
	if g_SetCount[g_CurClass] ~= nil then
		uClassNum = g_SetCount[g_CurClass]
	end

	for i = 1, g_MaxSetBarNum do
		local bar = g_SetBarList[i]
		if bar ~= nil then
			if i > uClassNum then
				bar:Hide()
			else
				bar:Show()
				
				local set_id = g_SetList[g_CurClass][i]
				local set_name = LuaFnGetCangPinSetName(set_id)
				bar:GetSubItem("Target_CangPin_ShuXing_TypeListItem_Btn_Text"):SetText(tostring(set_name))
				if g_CurSet == -1 then
					g_CurSet = set_id
				end

				if g_CurSet == set_id then
					bar:GetSubItem("Target_CangPin_ShuXing_TypeListItem_Btn"):SetCheck(1)
				else
					bar:GetSubItem("Target_CangPin_ShuXing_TypeListItem_Btn"):SetCheck(0)
				end
			end
		end
	end
	
	Target_CangPin_ShuXing_TypeList:RefreshLayout()
end

function Target_CangPin_ShuXing_Update_SetInfo()

	Target_CangPin_ShuXing_TaoZhuang_BuffText:ClearAllElement()
	Target_CangPin_ShuXing_ActiveBuffList:Clear()
	
	local strTemp = ""
	
	if g_CurSet >= 0 then
		local set_lv = DataPool:LuaFnGetOtherCangPinSetEffectLevel(g_CurSet)
		local have_set_effect = LuaFnIsCangPinSetHaveEffect(g_CurSet)
		local have_set_xj_effect = LuaFnIsCangPinSetHaveXianJieEffect(g_CurSet)
		
		if have_set_effect == 1 then
			if have_set_xj_effect == 1 then
				local xj_level = DataPool:LuaFnGetOtherCangPinSetXianJieLevel(g_CurSet)
				local set_effect_desc = ""
				local xj_effect_desc = ""
				
				if set_lv ~= 0 then
					set_effect_desc = LuaFnGetCangPinSetEffectDesc(g_CurSet, set_lv)
					set_effect_desc = "#cfff263"..tostring(set_effect_desc)
				else 
					set_effect_desc = LuaFnGetCangPinSetEffectDesc(g_CurSet, 1)
					set_effect_desc = "#c7F7F7F"..tostring(set_effect_desc)
				end
				
				if xj_level ~= 0 and set_lv ~= 0  then
					xj_effect_desc = LuaFnGetCangPinSetXianJieEffectDesc(g_CurSet, xj_level)
					xj_effect_desc = "#cfff263"..tostring(xj_effect_desc)
				else
					xj_effect_desc = LuaFnGetCangPinSetXianJieEffectDesc(g_CurSet, 1)
					xj_effect_desc = "#c7F7F7F"..tostring(xj_effect_desc)
				end
				
				Target_CangPin_ShuXing_TaoZhuang_BuffText:AddTextElement(tostring(set_effect_desc).."#r"..tostring(xj_effect_desc))
			else
				if set_lv ~= 0 then
					local set_effect_desc = LuaFnGetCangPinSetEffectDesc(g_CurSet, set_lv)
					Target_CangPin_ShuXing_TaoZhuang_BuffText:AddTextElement("#cfff263"..tostring(set_effect_desc))
				else 
					local set_effect_desc = LuaFnGetCangPinSetEffectDesc(g_CurSet, 1)
					Target_CangPin_ShuXing_TaoZhuang_BuffText:AddTextElement("#c7F7F7F"..tostring(set_effect_desc))
				end
			end
		end
		DataPool:LuaFnInitOtherCangPinSetSumAttrList(g_CurSet)
		local ct = DataPool:LuaFnGetOtherCangPinSetSumAttrCount()

		if ct > 0 then
			for i = 1, ct do
				local attrString = DataPool:LuaFnGetOtherCangPinSetSumAttr(i - 1)
				if tostring(attrString) ~= nil and tostring(attrString) ~= "" then
					local bar = Target_CangPin_ShuXing_ActiveBuffList:AddChild("Target_CangPin_ShuXing_ActiveBuffListItem")
					bar:GetSubItem("Target_CangPin_ShuXing_ActiveBuff_Text"):SetText("#cfff263"..tostring(attrString))
				end
			end
			Target_CangPin_ShuXing_ActiveBuffList:RefreshLayout()
		end
	end
end

function Target_CangPin_ShuXing_SetSelect(idx)
	local set_id = g_SetList[g_CurClass][idx]
	if set_id == nil then
		return
	end

	g_CurSet = set_id
	Target_CangPin_ShuXing_SetClassSelected(idx)
	
	g_CurCangPinPage = 0
	Target_CangPin_ShuXing_Update_CangPinList()
	Target_CangPin_ShuXing_Update_SetInfo()
end

function Target_CangPin_ShuXing_SetClassSelected(idx)
	for i = 1, g_MaxSetBarNum do
		local bar = g_SetBarList[i]
		if bar ~= nil then
			if i == idx then
				bar:GetSubItem("Target_CangPin_ShuXing_TypeListItem_Btn"):SetCheck(1)
			else
				bar:GetSubItem("Target_CangPin_ShuXing_TypeListItem_Btn"):SetCheck(0)
			end
		end
	end
end

function Target_CangPin_ShuXing_Update_CangPinList()

	if g_CurSet == 2 then
		Target_CangPin_ShuXing_Update_CangPinList_Set2()
		return
	end
	
	Target_CangPin_ShuXing_CangPinListBK:Show()
	Target_CangPin_ShuXing_Special_CangPinListBK:Hide()
	
	local uCangPinNum = 0
	if g_CurSet >= 0 then
		uCangPinNum = LuaFnGetCangPinCountInSet(g_CurSet)
	end
	
	g_CurCangPinMaxPage = math.floor((uCangPinNum - 1) / g_EachPageCangPinNum) + 1
	if g_CurCangPinPage >= g_CurCangPinMaxPage then
		g_CurCangPinPage = 0
	end
	
	local star_cangpin_idx = g_CurCangPinPage * g_EachPageCangPinNum
	
	local strTemp = ""
	
	for i = 1, g_EachPageCangPinNum do
		if star_cangpin_idx >= uCangPinNum then
			g_CangPinNameBKs[i]:Hide()
			g_CangPinActionButtons[i]:SetActionItem(-1)
			g_CangPinBKImages[i]:Hide()
			g_CangPinStarImages[i]:Hide()
			g_CangPinLockImages[i]:Hide()
			g_CangPinChipTexts[i]:Hide()
		else
			g_CangPinNameBKs[i]:Show()
			g_CangPinActionButtons[i]:SetActionItem(-1)
			g_CangPinBKImages[i]:Show()
			g_CangPinChipTexts[i]:Hide()
			
			local cangpin_id = LuaFnGetCangPinIdInSet(g_CurSet, star_cangpin_idx)
			local nUnLocked = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "UnLocked")
			local nChipCount = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "ChipCount")
			local strName = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "Name")
			local qual = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "Quality")
			local bCanQualUp = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "CanQualUp")			
			local nQualUpLevel = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "QualUpLevel")
			
			if nQualUpLevel == g_MaxQualUpLevel then
				strName = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "QualUpName")
			end
			
			strTemp = ScriptGlobal_Format("#{CPSJ_260112_148}", tostring(strName))
			g_CangPinNameTexts[i]:SetText(tostring(strTemp))
			
			local theAction = EnumAction(cangpin_id, "other_cangpin")
			if theAction:GetID() ~= 0 then
				g_CangPinActionButtons[i]:SetActionItem(theAction:GetID())
			end
			
			if nUnLocked == 1 then
				g_CangPinLockImages[i]:Hide()
				
				local nQualUpLevel = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "QualUpLevel")
				if qual == 4 and bCanQualUp == 1 and nQualUpLevel == g_MaxQualUpLevel then
					local strBK = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "XianJieBKImage")
					g_CangPinBKImages[i]:SetProperty("Image", tostring(strBK))
				else
					local strBK = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "BKImage")
					g_CangPinBKImages[i]:SetProperty("Image", tostring(strBK))
				end

				g_CangPinStarImages[i]:Show()
				
				local nStar = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "Star")
				
				g_CangPinStarImages[i]:SetProperty("Image", tostring(g_StarImg[nStar]))
			else
				g_CangPinLockImages[i]:Show()
				local strLockBK = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "LockBK")
				g_CangPinBKImages[i]:SetProperty("Image", tostring(strLockBK))

				g_CangPinStarImages[i]:Hide()
			end
		end
		star_cangpin_idx = star_cangpin_idx + 1
	end
end

function Target_CangPin_ShuXing_Update_CangPinList_Set2()

	--特写
	if g_CurSet ~= 2 then
		return
	end
	
	Target_CangPin_ShuXing_CangPinListBK:Hide()
	Target_CangPin_ShuXing_Special_CangPinListBK:Show()
	
	local uCangPinNum = LuaFnGetCangPinCountInSet(g_CurSet)
	
	g_CurCangPinMaxPage = math.floor((uCangPinNum - 1) / g_EachPageCangPinNum_Set2) + 1
	if g_CurCangPinPage >= g_CurCangPinMaxPage then
		g_CurCangPinPage = 0
	end
	
	local star_cangpin_idx = g_CurCangPinPage * g_EachPageCangPinNum_Set2
	
	local strTemp = ""
	
	local fourIn1_actived = 0
	for i = 1, g_EachPageCangPinNum_Set2 do
		if star_cangpin_idx >= uCangPinNum then
			if g_CangPinNameBKs_Set2[i] ~= nil then
				g_CangPinNameBKs_Set2[i]:Hide()
			end
			g_CangPinActionButtons_Set2[i]:SetActionItem(-1)
			if g_CangPinBKImages_Set2[i] ~= nil then
				g_CangPinBKImages_Set2[i]:Hide()
			end
			g_CangPinStarImages_Set2[i]:Hide()
			g_CangPinLockImages_Set2[i]:Hide()
			g_CangPinChipTexts_Set2[i]:Hide()
		else
			if g_CangPinNameBKs_Set2[i] ~= nil then
				g_CangPinNameBKs_Set2[i]:Show()
			end
			g_CangPinActionButtons_Set2[i]:SetActionItem(-1)
			if g_CangPinBKImages_Set2[i] ~= nil then
				g_CangPinBKImages_Set2[i]:Show()
			end
			g_CangPinChipTexts_Set2[i]:Hide()
			
			local cangpin_id = LuaFnGetCangPinIdInSet(g_CurSet, star_cangpin_idx)
			local nUnLocked = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "UnLocked")
			local nChipCount = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "ChipCount")
			local strName = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "Name")
			local qual = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "Quality")
			local bCanQualUp = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "CanQualUp")
			local nQualUpLevel = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "QualUpLevel")
			
			if nQualUpLevel == g_MaxQualUpLevel then
				strName = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "QualUpName")
			end
			
			if g_CangPinNameTexts_Set2[i] ~= nil then
				strTemp = ScriptGlobal_Format("#{CPSJ_260112_148}", tostring(strName))
				g_CangPinNameTexts_Set2[i]:SetText(tostring(strTemp))
			end
			
			local theAction = EnumAction(cangpin_id, "other_cangpin")
			if theAction:GetID() ~= 0 then
				g_CangPinActionButtons_Set2[i]:SetActionItem(theAction:GetID())
			end
			
			if nUnLocked == 1 then
				if i >= 1 and i <= 4 then
					fourIn1_actived = 1
				end
				g_CangPinLockImages_Set2[i]:Hide()
				
				if qual == 4 and bCanQualUp == 1 and nQualUpLevel == g_MaxQualUpLevel then
					local strBK = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "XianJieBKImage")
					if g_CangPinBKImages_Set2[i] ~= nil then
						g_CangPinBKImages_Set2[i]:SetProperty("Image", tostring(strBK))
					end
				else
					local strBK = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "BKImage")
					if g_CangPinBKImages_Set2[i] ~= nil then
						g_CangPinBKImages_Set2[i]:SetProperty("Image", tostring(strBK))
					end
				end

				g_CangPinStarImages_Set2[i]:Show()
				
				local nStar = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "Star")
				
				g_CangPinStarImages_Set2[i]:SetProperty("Image", tostring(g_StarImg[nStar]))
			else
				g_CangPinLockImages_Set2[i]:Show()
				local strLockBK = DataPool:LuaFnGetOtherCangPinData(cangpin_id, "LockBK")
				if g_CangPinBKImages_Set2[i] ~= nil then 
					g_CangPinBKImages_Set2[i]:SetProperty("Image", tostring(strLockBK))
				end
				
				g_CangPinStarImages_Set2[i]:Hide()
			end
		end
		star_cangpin_idx = star_cangpin_idx + 1
	end
	
	Target_CangPin_ShuXing_Special_Table_Image_3_TitleBK_Text:SetText("#{CPSJ_260112_151}")
	if fourIn1_actived == 1 then
		Target_CangPin_ShuXing_Special_Table_Image_3_ShowLight:Show()
	else
		Target_CangPin_ShuXing_Special_Table_Image_3_ShowLight:Hide()
	end
end

function Target_CangPin_ShuXing_SwitchClass(idx)
	if g_CurClass == idx then
		return
	end
	g_CurClass = idx
	g_CurSet = -1
	Target_CangPin_ShuXing_Update()
end

function Target_CangPin_ShuXing_Update_ClassBtn()
	for i = 1, g_ClassCount do
		if i == g_CurClass then
			g_ClassBtn[i]:SetCheck(1)
		else
			g_ClassBtn[i]:SetCheck(0)
		end
	end
end

function Target_CangPin_ShuXing_CloseClicked()
	this:Hide()
end

function Target_CangPin_ShuXing_CleanUp()
	g_CurSet = -1
end

function Target_CangPin_ShuXing_LeftArrowBtn_OnClick()
	if g_CurCangPinPage > 0 then
		g_CurCangPinPage = g_CurCangPinPage - 1
		 Target_CangPin_ShuXing_Update_CangPinList()
	end
end

function Target_CangPin_ShuXing_RightArrowBtn_OnClick()
	if g_CurCangPinPage < g_CurCangPinMaxPage - 1 then
		g_CurCangPinPage = g_CurCangPinPage + 1
		 Target_CangPin_ShuXing_Update_CangPinList()
	end
end

function Target_CangPin_ShuXing_OnHidden()
	Target_CangPin_ShuXing_CleanUp()
end

function Target_CangPin_ShuXing_Frame_On_ResetPos()
	if g_Target_CangPin_ShuXing_Frame_UnifiedPosition ~= nil then
		Target_CangPin_ShuXing_Frame:SetProperty("UnifiedPosition", g_Target_CangPin_ShuXing_Frame_UnifiedPosition)
	end
end

--装备
function Target_CangPin_ShuXing_Equip_Page_Switch()
	Variable:SetVariable("OtherUnionPos", Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenEquipFrame("other")
end

--资料
function Target_CangPin_ShuXing_Data_Page_Switch()
	Variable:SetVariable("OtherUnionPos", Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenPrivatePage("other")
end

--珍兽
function Target_CangPin_ShuXing_Pet_Page_Switch()
	Variable:SetVariable("OtherUnionPos", Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenPetFrame("other")
end

--子女
function Target_CangPin_ShuXing_Infant_Page_Switch()
	Variable:SetVariable("OtherUnionPos", Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Infant:Other_ToggleInfantPage()
	if bRet ~= 1 then
		Target_CangPin_ShuXing_TargetInfant:SetCheck(0)
	end
end

--武魂
function Target_CangPin_ShuXing_Wuhun_Page_Switch()
	Variable:SetVariable("OtherUnionPos", Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherWuhun()
end

--秘籍
function Target_CangPin_ShuXing_Miji_Page_Switch()
	Variable:SetVariable("OtherUnionPos", Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherMiji()
	this:Hide()
end

--真元
function Target_CangPin_ShuXing_ZhenYuan_Page_Switch()
	Variable:SetVariable("OtherUnionPos", Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Pneuma:ToggleTargetZhenYuanPage()
	if bRet ~= 1 then
		Target_CangPin_ShuXing_ZhenYuan:SetCheck(0)
	end
end

--经脉
function Target_CangPin_ShuXing_JingMai_Page_Switch()
	Variable:SetVariable("OtherUnionPos", Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherJingMai()
end

--神鼎
function Target_CangPin_ShuXing_ShenDing_Page_Switch()
	Variable:SetVariable("OtherUnionPos", Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	local nLevel = CachedTarget:GetData("LEVEL",1)
	if nLevel == nil or nLevel < 15 then
		PushDebugMessage( "#{XLDL_140606_63}" )
	else
		local bRet = SystemSetup:OpenOtherShenDing()
		if nRet ~= 1 then
			Target_CangPin_ShuXing_ShenDing:SetCheck(0)
		end
	end
end

--侠印
function Target_CangPin_ShuXing_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage()
	if bRet == 1 then
		this:Hide()
	else
		Target_CangPin_ShuXing_JueWei:SetCheck(0)
	end
end

--五行宝鉴
function Target_CangPin_ShuXing_BaoJian_Page_Switch()
	Variable:SetVariable("OtherUnionPos", Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
end

--武意
function Target_CangPin_ShuXing_WuYi_Page_Switch()
	Variable:SetVariable("OtherUnionPos", Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

--神器
function Target_CangPin_ShuXing_ShenQi_Page_Switch()
	Variable:SetVariable("OtherUnionPos", Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

--内甲
function Target_CangPin_ShuXing_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

--骑乘
function Target_CangPin_ShuXing_Ride_Page_Switch()
	Variable:SetVariable("OtherUnionPos", Target_CangPin_ShuXing_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenRidePage("other")
end

--珍粹
function Target_CangPin_ShuXing_CangPin_Page_Switch()

end


function Target_CangPin_ShuXing_ShowPage()

	for i = 1, table.getn(g_Target_CangPin_ShuXing_Page) do
		g_TargetPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	Target_CangPin_ShuXing_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_TargetPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_Target_CangPin_ShuXing_Page) do
			if i ~= nOtherPageNumber then
				g_TargetPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_TargetPageOrder = {}
	g_TargetPageCount = 0
	for i = 1, table.getn(g_Target_CangPin_ShuXing_Page) do
		if Target_CangPin_ShuXing_CheckPage(i) == 1 then
			g_TargetPageCount = g_TargetPageCount + 1
			g_TargetPageButton[g_TargetPageCount]:Show()
			g_TargetPageButton[g_TargetPageCount]:SetText(g_Target_CangPin_ShuXing_Page[i].Text)	
			g_TargetPageOrder[g_TargetPageCount] = i
		end
	end
	
end

function Target_CangPin_ShuXing_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_TargetPageOrder[idx]
	
	if idx == 1 then--装备
		Target_CangPin_ShuXing_Equip_Page_Switch();
	elseif idx == 2 then--资料
		Target_CangPin_ShuXing_Data_Page_Switch()
	elseif idx == 3 then--珍兽
		Target_CangPin_ShuXing_Pet_Page_Switch()
	elseif idx == 4 then--子女
		Target_CangPin_ShuXing_Infant_Page_Switch()
	elseif idx == 5 then--武魂
		Target_CangPin_ShuXing_Wuhun_Page_Switch()
	elseif idx == 6 then--秘籍
		Target_CangPin_ShuXing_Miji_Page_Switch()
	elseif idx == 7 then--真元
		Target_CangPin_ShuXing_ZhenYuan_Page_Switch()
	elseif idx == 8 then--经脉
		Target_CangPin_ShuXing_JingMai_Page_Switch()
	elseif idx == 9 then--神鼎
		Target_CangPin_ShuXing_ShenDing_Page_Switch()
	elseif idx == 10 then--侠印
		Target_CangPin_ShuXing_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		Target_CangPin_ShuXing_BaoJian_Page_Switch()
	elseif idx == 12 then--武意
		Target_CangPin_ShuXing_WuYi_Page_Switch()
	elseif idx == 13 then--神器
		Target_CangPin_ShuXing_ShenQi_Page_Switch()
	elseif idx == 14 then--星盘
		Target_CangPin_ShuXing_Armor_Page_Switch()
	elseif idx == 15 then--名物
		Target_CangPin_ShuXing_CangPin_Page_Switch()
	end
end

function Target_CangPin_ShuXing_CheckPage(idx)
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

function Target_CangPin_ShuXing_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end


