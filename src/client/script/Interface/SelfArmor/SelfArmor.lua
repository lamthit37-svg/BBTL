--SelfArmor
--!!!reloadscript =SelfArmor

-- 界面的默认相对位置
local g_SelfArmor_Frame_UnifiedPosition

local g_UA_Image = {}
local g_UA_Level_Text = {}
local g_UA_Star_Text = {}
local g_Jewel_Button = {}
local g_Jewel_Lock_Image = {}

local g_UA_StarBK1 = {}
local g_UA_StarBK2 = {}

local g_UA_Star = {}

local g_UA_Lock_Icon_Tip = {"#{NJBZ_220816_16}", "#{NJBZ_220816_202}", "#{NJBZ_220816_208}"}
local g_UA_Lock_Level_TXT = {"#{NJBZ_220816_198}", "#{NJBZ_220816_204}", "#{NJBZ_220816_210}"}
local g_UA_Lock_Level_Tip = {"#{NJBZ_220816_199}", "#{NJBZ_220816_205}", "#{NJBZ_220816_211}"}
local g_Jewel_Button_Lock_Tip = {"#{NJBZ_220816_215}", "#{NJBZ_220816_216}", "#{NJBZ_220816_217}"}

local g_UA_Rank_Name = {
	"#{NJBZ_220816_333}",
	"#{NJBZ_220816_334}",
	"#{NJBZ_220816_335}",
	"#{NJBZ_220816_336}",
	"#{NJBZ_220816_337}",
	"#{NJBZ_220816_338}",
}


--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_SelfArmor_Page = {
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

local g_SelfArmor_PageButton = {}
local g_SelfArmor_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

function SelfArmor_PreLoad()

	--打开界面
	this:RegisterEvent("OPEN_UNDERARMOUR", true)	
	this:RegisterEvent("UA_DATA_UPDATE", false)
	this:RegisterEvent("UPDATE_UA_EXP", false)
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false)
	--任务数据发生变化
	this:RegisterEvent("UPDATE_MISSION_DATA", false)
	--玩家使用兽栏--add by xindefeng
	this:RegisterEvent("UPDATE_PET_EXTRANUM", false)

	--游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS", false)
	--游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK", false)		--升级
	this:RegisterEvent("TOGGLE_UPDATE_INFANT", false) 				--子女有变化刷新按钮状态
	this:RegisterEvent("FINISH_MISSION", false)	
	this:RegisterEvent("MARTIAL_UPDATE", false)	
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP", false)
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)
end

--OnLoad
function SelfArmor_OnLoad()
	g_SelfArmor_Frame_UnifiedPosition = SelfArmor_Frame:GetProperty("UnifiedPosition")
	
	g_UA_Image[1] = SelfArmor_Armor1
	g_UA_Image[2] = SelfArmor_Armor2
	g_UA_Image[3] = SelfArmor_Armor3
	
	g_UA_Level_Text[1] = SelfArmor_Armor1_Text2
	g_UA_Level_Text[2] = SelfArmor_Armor2_Text2
	g_UA_Level_Text[3] = SelfArmor_Armor3_Text2
	
	g_UA_Star_Text[1] = SelfArmor_Armor1_Text3
	g_UA_Star_Text[2] = SelfArmor_Armor2_Text3
	g_UA_Star_Text[3] = SelfArmor_Armor3_Text3
	
	g_Jewel_Button[1] = SelfArmor_ArmorGem1
	g_Jewel_Button[2] = SelfArmor_ArmorGem2
	g_Jewel_Button[3] = SelfArmor_ArmorGem3
	
	g_Jewel_Lock_Image[1] = SelfArmor_ArmorGem1_Mask
	g_Jewel_Lock_Image[2] = SelfArmor_ArmorGem2_Mask
	g_Jewel_Lock_Image[3] = SelfArmor_ArmorGem3_Mask
	
	g_UA_StarBK1[1] = SelfArmor_Armor1_Text2BK
	g_UA_StarBK1[2] = SelfArmor_Armor2_Text2BK
	g_UA_StarBK1[3] = SelfArmor_Armor3_Text2BK
	
	g_UA_StarBK2[1] = SelfArmor_Armor1_Text3BK
	g_UA_StarBK2[2] = SelfArmor_Armor2_Text3BK
	g_UA_StarBK2[3] = SelfArmor_Armor3_Text3BK
	
	g_UA_Star[1] = {}
	g_UA_Star[1][1] = SelfArmor_Armor1_Star1
	g_UA_Star[1][2] = SelfArmor_Armor1_Star2
	g_UA_Star[1][3] = SelfArmor_Armor1_Star3
	g_UA_Star[1][4] = SelfArmor_Armor1_Star4
	
	g_UA_Star[2] = {}
	g_UA_Star[2][1] = SelfArmor_Armor2_Star1
	g_UA_Star[2][2] = SelfArmor_Armor2_Star2
	g_UA_Star[2][3] = SelfArmor_Armor2_Star3
	g_UA_Star[2][4] = SelfArmor_Armor2_Star4
	
	g_UA_Star[3] = {}
	g_UA_Star[3][1] = SelfArmor_Armor3_Star1
	g_UA_Star[3][2] = SelfArmor_Armor3_Star2
	g_UA_Star[3][3] = SelfArmor_Armor3_Star3
	g_UA_Star[3][4] = SelfArmor_Armor3_Star4
	
	g_SelfArmor_PageButton[1] = SelfArmor_SelfEquip
	g_SelfArmor_PageButton[2] = SelfArmor_SelfData
	g_SelfArmor_PageButton[3] = SelfArmor_Pet
	g_SelfArmor_PageButton[4] = SelfArmor_Infant
	g_SelfArmor_PageButton[5] = SelfArmor_Wuhun
	g_SelfArmor_PageButton[6] = SelfArmor_Xiulian
	g_SelfArmor_PageButton[7] = SelfArmor_Miji
	g_SelfArmor_PageButton[8] = SelfArmor_ZhenYuan
	g_SelfArmor_PageButton[9] = SelfArmor_JingMai
	g_SelfArmor_PageButton[10] = SelfArmor_ShenDing
	g_SelfArmor_PageButton[11] = SelfArmor_JueWei
	g_SelfArmor_PageButton[12] = SelfArmor_BaoJian
	g_SelfArmor_PageButton[13] = SelfArmor_WuYi
	g_SelfArmor_PageButton[14] = SelfArmor_ShenQi
	g_SelfArmor_PageButton[15] = SelfArmor_Armor
	g_SelfArmor_PageButton[16] = SelfArmor_CangPin
	g_SelfArmor_PageButton[17] = SelfArmor_OtherInfo
	
	g_SelfArmor_PageMask[1] = SelfArmor_SelfEquip_tips
	g_SelfArmor_PageMask[2] = SelfArmor_SelfData_tips
	g_SelfArmor_PageMask[3] = SelfArmor_Pet_tips
	g_SelfArmor_PageMask[4] = SelfArmor_Infant_tips
	g_SelfArmor_PageMask[5] = SelfArmor_Wuhun_tips
	g_SelfArmor_PageMask[6] = SelfArmor_Xiulian_tips
	g_SelfArmor_PageMask[7] = SelfArmor_Miji_tips
	g_SelfArmor_PageMask[8] = SelfArmor_ZhenYuan_tips
	g_SelfArmor_PageMask[9] = SelfArmor_JingMai_tips
	g_SelfArmor_PageMask[10] = SelfArmor_ShenDing_tips
	g_SelfArmor_PageMask[11] = SelfArmor_JueWei_tips
	g_SelfArmor_PageMask[12] = SelfArmor_BaoJian_tips
	g_SelfArmor_PageMask[13] = SelfArmor_WuYi_tips
	g_SelfArmor_PageMask[14] = SelfArmor_ShenQi_tips
	g_SelfArmor_PageMask[15] = SelfArmor_Armor_tips
	g_SelfArmor_PageMask[16] = SelfArmor_CangPin_tips
	g_SelfArmor_PageMask[17] = SelfArmor_OtherInfo_tips
	
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

--OnEvent
function SelfArmor_OnEvent(event)

	if event == "UPDATE_WILLGET_MISSION_TRACK" or event == "TOGGLE_UPDATE_INFANT" or event == "FINISH_MISSION" then
		local iLevel = Player:GetLevel()
		SelfArmor_Refresh_Page_Button(iLevel)
		SelfArmor_ShowPage()
		return
	end

	if event == "OPEN_UNDERARMOUR" then
		if this:IsVisible() then
			this:Hide()
			return
		end
		
		SelfArmor_CleanUp()
		SelfArmor_OnShow()		
		this:Show()
		SelfArmor_Update()
		local iLevel = Player:GetLevel()
		SelfArmor_Refresh_Page_Button(iLevel)
		SelfArmor_ShowPage()
		return
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
		return
	end

	if event == "UPDATE_MISSION_DATA" then
		local iLevel = Player:GetLevel()
		SelfArmor_Refresh_Page_Button(iLevel)
		SelfArmor_ShowPage()
	end

	--处理兽栏事件--add by xindefeng
	if event == "UPDATE_PET_EXTRANUM" then
		if this:IsVisible() then
			SelfArmor_OnShow()
		end
	end

	--游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		SelfArmor_Frame_On_ResetPos()
		return
	end
	
	if event == "MARTIAL_UPDATE"  or event == "MARTIAL_HIDE_ZHAOHUI_TIP" then
		SelfArmor_RefreshWuYiTip()
		return
	end
	
	if event == "UPDATE_TOY_TIP" then
		SelfArmor_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		SelfArmor_RefreshCangPinTip()
	end
	
	if event == "UPDATE_UA_EXP" then
		local ua_exp = Player:GetData("UAEXP")
		local strTemp = ScriptGlobal_Format("#{NJBZ_220816_219}", tostring(ua_exp))
		SelfArmor_EXP:SetText(strTemp)
	end
	
	if event == "UA_DATA_UPDATE" then
		SelfArmor_Update()
	end
	
end

function SelfArmor_OnShow()
	SelfArmor_Armor:SetCheck(1)
	local selfUnionPos = Variable:GetVariable("SelfUnionPos")
	if selfUnionPos ~= nil then
		SelfArmor_Frame:SetProperty("UnifiedPosition", selfUnionPos)
	end
end

function SelfArmor_Update()

	local strTemp = ""
	for i = 1, 3 do
		local bActived = DataPool:LuaFnGetUnderArmourData(i - 1, "ACTIVED")		
		if bActived == 0 then
			local strBKImage = DataPool:LuaFnGetUnderArmourInfo(i - 1, "LOCKBK")
			g_UA_Image[i]:SetProperty("Image", strBKImage)
			g_UA_Image[i]:SetToolTip(g_UA_Lock_Icon_Tip[i])

			g_UA_Level_Text[i]:SetText(g_UA_Lock_Level_TXT[i])
			g_UA_Level_Text[i]:SetToolTip(g_UA_Lock_Level_Tip[i])
			g_UA_Star_Text[i]:SetText("")
			
			g_UA_Star_Text[i]:SetText("")
			
			g_Jewel_Button[i]:SetToolTip(g_Jewel_Button_Lock_Tip[i])
			g_Jewel_Lock_Image[i]:Show()
			
			g_UA_StarBK1[i]:Hide()
			g_UA_StarBK2[i]:Hide()
			
			g_UA_Star[i][1]:Hide()
			g_UA_Star[i][2]:Hide()
			g_UA_Star[i][3]:Hide()
			g_UA_Star[i][4]:Hide()
		else
			local iLevel = DataPool:LuaFnGetUnderArmourData(i - 1, "LEVEL")
			local iRank = DataPool:LuaFnGetUnderArmourData(i - 1, "RANK")
			local iStar = DataPool:LuaFnGetUnderArmourData(i - 1, "STAR")
			local iJewel = DataPool:LuaFnGetUnderArmourData(i - 1, "JEWEL")
			
			local strBKImage = DataPool:LuaFnGetUnderArmourInfo(i - 1, "BKIMAGE", iRank)
			g_UA_Image[i]:SetProperty("Image", strBKImage)
			g_UA_Image[i]:SetToolTip("")

			if iRank == 5 then
				g_UA_Level_Text[i]:SetText("#{NJBZ_220816_395}")
			else
				strTemp = ScriptGlobal_Format("#{NJBZ_220816_200}", tostring(g_UA_Rank_Name[iRank + 1]), tostring(iLevel))
				g_UA_Level_Text[i]:SetText(strTemp)
			end			
			g_UA_Level_Text[i]:SetToolTip("")

			strTemp = ScriptGlobal_Format("#{NJBZ_220816_201}", tostring(iStar))
			g_UA_Star_Text[i]:SetText(strTemp)

			if tonumber(iJewel) ~= nil and tonumber(iJewel) > 0 then
				local itemAction = EnumAction(i - 1, "UnderArmourJewel")
				g_Jewel_Button[i]:SetActionItem(itemAction:GetID())
				g_Jewel_Button[i]:SetToolTip("")
			else
				g_Jewel_Button[i]:SetToolTip("#{NJBZ_220816_218}")
				g_Jewel_Button[i]:SetActionItem(-1)
			end
			g_Jewel_Lock_Image[i]:Hide()
			
			g_UA_StarBK1[i]:Show()
			g_UA_StarBK2[i]:Show()
			
			if iStar >= 0 and iStar <= 2 then
				g_UA_StarBK2[i]:SetProperty("Image", "set:SelfArmor1 image:SelfArmor_StarBK1")
			elseif iStar >= 3 and iStar <= 5 then
				g_UA_StarBK2[i]:SetProperty("Image", "set:SelfArmor1 image:SelfArmor_StarBK2")
			elseif iStar >= 6 and iStar <= 8 then
				g_UA_StarBK2[i]:SetProperty("Image", "set:SelfArmor1 image:SelfArmor_StarBK3")
			elseif iStar == 9 then
				g_UA_StarBK2[i]:SetProperty("Image", "set:SelfArmor1 image:SelfArmor_StarBK4")
			end
			
			g_UA_Star[i][1]:Hide()
			g_UA_Star[i][2]:Hide()
			g_UA_Star[i][3]:Hide()
			g_UA_Star[i][4]:Hide()
			if iStar >= 0 then
				g_UA_Star[i][1]:Show()
			end
			if iStar >= 3 then
				g_UA_Star[i][2]:Show()
			end
			if iStar >= 6 then
				g_UA_Star[i][3]:Show()
			end
			if iStar >= 9 then
				g_UA_Star[i][4]:Show()
			end
		end	
	end
	
	local ua_exp = Player:GetData("UAEXP")
	strTemp = ScriptGlobal_Format("#{NJBZ_220816_219}", tostring(ua_exp))
	SelfArmor_EXP:SetText(strTemp)
end

function SelfArmor_CleanUp()

end

--装备
function SelfArmor_SelfEquip_Page_Switch()	
	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	OpenEquip(1)
end

--资料
function SelfArmor_SelfData_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenPrivatePage("self")
end

--珍兽
function SelfArmor_Pet_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	TogglePetPage()
end

--子女
function SelfArmor_Infant_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Infant:ToggleInfantPage()
	if bRet == 1 then
		this:Hide()
	else
		SelfArmor_Infant:SetCheck(0)
	end
end

--武魂
function SelfArmor_Wuhun_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	ToggleWuhunPage()
end

--修炼
function SelfArmor_Xiulian_Page_Switch()
    local iLevel = Player:GetData("LEVEL")
	if iLevel >= 70 then
		Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
		XiuLianPage()
	else
		SelfArmor_Xiulian:SetCheck(0)
		PushDebugMessage("#{XL_090707_62}")
	end
end

--秘籍
function SelfArmor_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	local nRet = OpenMijiPage()
	if nRet ~= 1 then
		SelfArmor_Miji:SetCheck(0)
	end
end

--真元
function SelfArmor_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Pneuma:ToggleZhenYuanPage()
	if bRet == 1 then
		this:Hide()
	end
end

--经脉
function SelfArmor_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	local nRet = OpenJingMaiPage()
	if nRet == 1 then
		this:Hide()
		-- SelfArmor_SelfArmor:SetCheck(0)
	else
		SelfArmor_JingMai:SetCheck(0)
	end
end

--神木王鼎
function SelfArmor_ShenDing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	local nRet = OpenShenDingPage()
	if nRet ~= 1 then
		SelfArmor_ShenDing:SetCheck(0)
	end
end

--侠印
function SelfArmor_JueWei_Page_Switch()
	if Player:GetLevel() < 85 then
		PushDebugMessage("#{JXJW_140822_20}")
		return
	end
	
	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = OpenJunXianPage()
	if bRet == 1 then
		this:Hide()
	else
		SelfArmor_JueWei:SetCheck(0)
	end
end

--五行宝鉴
function SelfArmor_OpenBaoJian()
	local iLevel = Player:GetLevel()
	if iLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()
end

--武意
function SelfArmor_OpenWuYi()
	local iLevel = Player:GetLevel()
	if MaritialSys:HasFinishWuYiMisson() ~= 1 or iLevel < 85 then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("MARTIAL_SHOWWUYI")
end

--神器
function SelfArmor_OpenShenQi()
	if DataPool:Lua_IsMissionHaveDone(1950) ~= 1 then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

--内甲
function SelfArmor_Armor_Page_Switch()

end

--其他
function SelfArmor_OtherInfo_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	OtherInfoPage()
end

--骑乘
function SelfArmor_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	OpenRidePage()
end

--藏品
function SelfArmor_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfArmor_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function SelfArmor_RefreshCangPinTip()
	local CangPinClassCount = 4
	local bHaveChipToMelt = DataPool:LuaFnIsCanMeltCangPinChip()
	local bTip = 0
	for i = 1, CangPinClassCount do
		if DataPool:LuaFnIsCangPinClassShowTip(i - 1) == 1 then
			bTip = 1
		end
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 16 then -- 名物
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfArmor_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfArmor_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		SelfArmor_CangPin_Buttontips:Show()
	else
		SelfArmor_CangPin_Buttontips:Hide()
	end
end

--恢复界面的默认相对位置
function SelfArmor_Frame_On_ResetPos()
	SelfArmor_Frame:SetProperty("UnifiedPosition", g_SelfArmor_Frame_UnifiedPosition)
end

function SelfArmor_Refresh_Page_Button(nLevel)

	if 1 == 1 then
		return
	end
	
	--神鼎
	if nLevel < 15 then
		SelfArmor_ShenDing:Disable()
		SelfArmor_ShenDing_tips:Show()
	else
		SelfArmor_ShenDing:Enable()
		SelfArmor_ShenDing_tips:Hide()
	end

	--子女
	local InfantCount = Infant:GetInfantCount()
	if nLevel < 50 or InfantCount <= 0 then
		SelfArmor_Infant:Disable()
		SelfArmor_Infant_tips:Show()
	else
		SelfArmor_Infant:Enable()
		SelfArmor_Infant_tips:Hide()
	end

	SelfArmor_Wuhun:Enable()
	SelfArmor_Wuhun_tips:Hide()

	--修炼
	if nLevel < 70 then
		SelfArmor_Xiulian:Disable()
		SelfArmor_Xiulian_tips:Show()
	else
		SelfArmor_Xiulian:Enable()
		SelfArmor_Xiulian_tips:Hide()
	end

	--秘籍
	if nLevel < 75 or DataPool:Lua_IsMissionHaveDone(1651) == 0 then
		SelfArmor_Miji:Disable()
		SelfArmor_Miji_tips:Show()
	else
		SelfArmor_Miji:Enable()
		SelfArmor_Miji_tips:Hide()
	end

	--真元
	if nLevel < 80 or DataPool:Lua_IsMissionHaveDone(1600) == 0 then
		SelfArmor_ZhenYuan:Disable()
		SelfArmor_ZhenYuan_tips:Show()
	else
		SelfArmor_ZhenYuan:Enable()
		SelfArmor_ZhenYuan_tips:Hide()
	end

	--侠印
	if nLevel < 85 then
		SelfArmor_JueWei:Disable()
		SelfArmor_JueWei_tips:Show()
	else
		SelfArmor_JueWei:Enable()
		SelfArmor_JueWei_tips:Hide()
	end

	--经脉
	if nLevel < 90 or DataPool:Lua_IsMissionHaveDone(1554) == 0  then
		SelfArmor_JingMai:Disable()
		SelfArmor_JingMai_tips:Show()
	else
		SelfArmor_JingMai:Enable()
		SelfArmor_JingMai_tips:Hide()
	end

	if nLevel < 85 then
		SelfArmor_BaoJian:Disable()
		SelfArmor_BaoJian_tips:Show()
	else
		SelfArmor_BaoJian:Enable()
		SelfArmor_BaoJian_tips:Hide()
	end

	--武意
	if MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85 then
		SelfArmor_WuYi:Enable()
		SelfArmor_WuYi_tips:Hide()
	else
		SelfArmor_WuYi:Disable()
		SelfArmor_WuYi_tips:Show()
	end

	SelfArmor_RefreshWuYiTip()

	--九星神器DIY技能
	if DataPool:Lua_IsMissionHaveDone(1950) == 1 then
		SelfArmor_ShenQi:Enable()
		SelfArmor_ShenQi_tips:Hide()
	else
		SelfArmor_ShenQi:Disable()
		SelfArmor_ShenQi_tips:Show()
	end

	SelfArmor_RefreshOtherInfoTip()
	
	if nLevel >= 30 then
		SelfArmor_CangPin:Enable()
		SelfArmor_CangPin_tips:Hide()
	else
		SelfArmor_CangPin:Disable()
		SelfArmor_CangPin_tips:Show()
	end
	
	SelfArmor_RefreshCangPinTip()
end

--刷新武意上的红点
function SelfArmor_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfArmor_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfArmor_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum, nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1 then
		SelfArmor_WuYi_Buttontips:Show()
	else
		SelfArmor_WuYi_Buttontips:Hide()
	end
end

--刷新其他上的红点
function SelfArmor_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfArmor_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfArmor_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then		
		SelfArmor_OtherInfo_ButtonTips:Show()
	else
		SelfArmor_OtherInfo_ButtonTips:Hide()
	end
end

function SelfArmor_GetPercentageString(num)	
	if tonumber(num) == nil then
		return ""
	end
	
	local intPart = math.floor(num / 100)
	local floatPart = math.floor(math.mod(num, 100) / 10)
			
	if floatPart == 0 then
		return tostring(intPart)
	else
		return tostring(intPart).."."..tostring(floatPart)
	end
end

function SelfArmor_Armor_MouseLeave(index)
	LuaFnCloseUnderArmourTip(0, index)
end

function SelfArmor_Armor_MouseEnter(index)
	
	if g_UA_Image[index] == nil then
		return
	end
	
	local bActived = DataPool:LuaFnGetUnderArmourData(index - 1, "ACTIVED")
	if bActived == 0 then
		return
	end
	
	local fX, fY = g_UA_Image[index]:GetAbsolutePositionToScreen()
	local SetWidth = g_UA_Image[index]:GetProperty("AbsoluteWidth")
	local SetHeight = g_UA_Image[index]:GetProperty("AbsoluteHeight")
	LuaFnOpenUnderArmourTip(0, index, tonumber(fX), tonumber(fY), tonumber(SetWidth), tonumber(SetHeight))
end

function SelfArmor_Help2Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_ScriptID(555005)
		Set_XSCRIPT_Function_Name("ShowUnderArmourIntro")
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


function SelfArmor_ShowPage()

	for i = 1, table.getn(g_SelfArmor_Page) do
		g_SelfArmor_PageButton[i]:Hide()
		g_SelfArmor_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	SelfArmor_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_SelfArmor_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_SelfArmor_Page) do
			if i ~= nPageNumber then
				g_SelfArmor_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_SelfArmor_Page) do
		if SelfArmor_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_SelfArmor_PageButton[g_PageCount]:Show()
			g_SelfArmor_PageButton[g_PageCount]:SetText(g_SelfArmor_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if SelfArmor_IsPageEnable(i) == 1 then
				g_SelfArmor_PageButton[g_PageCount]:Enable()
				g_SelfArmor_PageMask[g_PageCount]:Hide()
			else
				g_SelfArmor_PageButton[g_PageCount]:Disable()
				g_SelfArmor_PageMask[g_PageCount]:Show()
				if g_SelfArmor_Page[i].Tip ~= "" then
					g_SelfArmor_PageMask[g_PageCount]:SetToolTip(g_SelfArmor_Page[i].Tip)
				end
			end
		end
	end
	
	SelfArmor_RefreshWuYiTip()
	SelfArmor_RefreshOtherInfoTip()
	SelfArmor_RefreshCangPinTip()
	
end

function SelfArmor_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		SelfArmor_SelfEquip_Page_Switch(0);
	elseif idx == 2 then--资料
		SelfArmor_SelfData_Page_Switch()
	elseif idx == 3 then--珍兽
		SelfArmor_Pet_Page_Switch()
	elseif idx == 4 then--子女
		SelfArmor_Infant_Page_Switch()
	elseif idx == 5 then--武魂
		SelfArmor_Wuhun_Page_Switch()
	elseif idx == 6 then--修炼
		SelfArmor_Xiulian_Page_Switch()
	elseif idx == 7 then--秘籍
		SelfArmor_Miji_Page_Switch()
	elseif idx == 8 then--真元
		SelfArmor_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		SelfArmor_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		SelfArmor_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		SelfArmor_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		SelfArmor_OpenBaoJian()
	elseif idx == 13 then--武意
		SelfArmor_OpenWuYi()
	elseif idx == 14 then--神器
		SelfArmor_OpenShenQi()
	elseif idx == 15 then--星盘
		SelfArmor_Armor_Page_Switch()
	elseif idx == 16 then--名物
		SelfArmor_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		SelfArmor_OtherInfo_Page_Switch()
	end
end

function SelfArmor_CheckPage(idx)
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

function SelfArmor_IsPageEnable(idx)
	
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

function SelfArmor_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


