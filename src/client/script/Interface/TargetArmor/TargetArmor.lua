--TargetArmor
--!!!reloadscript =TargetArmor

local g_TargetArmor_Frame_UnifiedPosition

local g_UA_Image = {}
local g_UA_Level_Text = {}
local g_UA_Star_Text = {}
local g_Jewel_Button = {}
local g_Jewel_Lock_Image = {}

local g_UA_StarBK1 = {}
local g_UA_StarBK2 = {}

local g_UA_Star = {}

local g_UA_Lock_Level_TXT = {"#{NJBZ_220816_198}", "#{NJBZ_220816_204}", "#{NJBZ_220816_210}"}

local g_UA_Rank_Name = {
	"#{NJBZ_220816_333}",
	"#{NJBZ_220816_334}",
	"#{NJBZ_220816_335}",
	"#{NJBZ_220816_336}",
	"#{NJBZ_220816_337}",
	"#{NJBZ_220816_338}",
}

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_TargetArmor_Page = {
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

--===============================================
-- OnLoad()
--===============================================
function TargetArmor_PreLoad()
	this:RegisterEvent("OPEN_TARGET_UNDERARMOUR", true)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
end

function TargetArmor_OnLoad()
	g_TargetArmor_Frame_UnifiedPosition = TargetArmor_Frame:GetProperty("UnifiedPosition")

	g_UA_Image[1] = TargetArmor_Armor1
	g_UA_Image[2] = TargetArmor_Armor2
	g_UA_Image[3] = TargetArmor_Armor3
	
	g_UA_Level_Text[1] = TargetArmor_Armor1_Text2
	g_UA_Level_Text[2] = TargetArmor_Armor2_Text2
	g_UA_Level_Text[3] = TargetArmor_Armor3_Text2
	
	g_UA_Star_Text[1] = TargetArmor_Armor1_Text3
	g_UA_Star_Text[2] = TargetArmor_Armor2_Text3
	g_UA_Star_Text[3] = TargetArmor_Armor3_Text3
	
	g_Jewel_Button[1] = TargetArmor_ArmorGem1
	g_Jewel_Button[2] = TargetArmor_ArmorGem2
	g_Jewel_Button[3] = TargetArmor_ArmorGem3
	
	g_Jewel_Lock_Image[1] = TargetArmor_ArmorGem1_Mask
	g_Jewel_Lock_Image[2] = TargetArmor_ArmorGem2_Mask
	g_Jewel_Lock_Image[3] = TargetArmor_ArmorGem3_Mask
	
	g_UA_StarBK1[1] = TargetArmor_Armor1_Text2BK
	g_UA_StarBK1[2] = TargetArmor_Armor2_Text2BK
	g_UA_StarBK1[3] = TargetArmor_Armor3_Text2BK
	
	g_UA_StarBK2[1] = TargetArmor_Armor1_Text3BK
	g_UA_StarBK2[2] = TargetArmor_Armor2_Text3BK
	g_UA_StarBK2[3] = TargetArmor_Armor3_Text3BK
	
	g_UA_Star[1] = {}
	g_UA_Star[1][1] = TargetArmor_Armor1_Star1
	g_UA_Star[1][2] = TargetArmor_Armor1_Star2
	g_UA_Star[1][3] = TargetArmor_Armor1_Star3
	g_UA_Star[1][4] = TargetArmor_Armor1_Star4
	
	g_UA_Star[2] = {}
	g_UA_Star[2][1] = TargetArmor_Armor2_Star1
	g_UA_Star[2][2] = TargetArmor_Armor2_Star2
	g_UA_Star[2][3] = TargetArmor_Armor2_Star3
	g_UA_Star[2][4] = TargetArmor_Armor2_Star4
	
	g_UA_Star[3] = {}
	g_UA_Star[3][1] = TargetArmor_Armor3_Star1
	g_UA_Star[3][2] = TargetArmor_Armor3_Star2
	g_UA_Star[3][3] = TargetArmor_Armor3_Star3
	g_UA_Star[3][4] = TargetArmor_Armor3_Star4

	g_TargetPageButton[1] = TargetArmor_Equip
	g_TargetPageButton[2] = TargetArmor_TargetData
	g_TargetPageButton[3] = TargetArmor_Pet
	g_TargetPageButton[4] = TargetArmor_TargetInfant
	g_TargetPageButton[5] = TargetArmor_TargetWuhun
	g_TargetPageButton[6] = TargetArmor_Miji
	g_TargetPageButton[7] = TargetArmor_ZhenYuan
	g_TargetPageButton[8] = TargetArmor_JingMai
	g_TargetPageButton[9] = TargetArmor_ShenDing
	g_TargetPageButton[10] = TargetArmor_JueWei
	g_TargetPageButton[11] = TargetArmor_BaoJian
	g_TargetPageButton[12] = TargetArmor_WuYi
	g_TargetPageButton[13] = TargetArmor_ShenQi
	g_TargetPageButton[14] = TargetArmor_Armor
	g_TargetPageButton[15] = TargetArmor_CangPin
	
end

function TargetArmor_OnEvent(event)

	if event == "OPEN_TARGET_UNDERARMOUR" then
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
		TargetArmor_Update()
		TargetArmor_Armor:SetCheck(1)

		local otherUnionPos = Variable:GetVariable("OtherUnionPos")
		if otherUnionPos ~= nil then
			TargetArmor_Frame:SetProperty("UnifiedPosition", otherUnionPos)
		end

		TargetArmor_ShowPage()
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		TargetArmor_Frame_On_ResetPos()
		return
	end
end

function TargetArmor_Update()

	local strTemp = ""
	for i = 1, 3 do
		local bActived = DataPool:LuaFnGetOtherUnderArmourData(i - 1, "ACTIVED")	
		if bActived == 0 then
			local strBKImage = DataPool:LuaFnGetUnderArmourInfo(i - 1, "LOCKBK")
			g_UA_Image[i]:SetProperty("Image", tostring(strBKImage))
			
			g_UA_Level_Text[i]:SetText(g_UA_Lock_Level_TXT[i])
			g_UA_Star_Text[i]:SetText("")
			
			g_Jewel_Lock_Image[i]:Show()

			g_UA_StarBK1[i]:Hide()
			g_UA_StarBK2[i]:Hide()
			
			g_UA_Star[i][1]:Hide()
			g_UA_Star[i][2]:Hide()
			g_UA_Star[i][3]:Hide()
			g_UA_Star[i][4]:Hide()
		else
			local iLevel = DataPool:LuaFnGetOtherUnderArmourData(i - 1, "LEVEL")
			local iRank = DataPool:LuaFnGetOtherUnderArmourData(i - 1, "RANK")
			local iStar = DataPool:LuaFnGetOtherUnderArmourData(i - 1, "STAR")
			local iJewel = DataPool:LuaFnGetOtherUnderArmourData(i - 1, "JEWEL")

			local strBKImage = DataPool:LuaFnGetUnderArmourInfo(i - 1, "BKIMAGE", iRank)
			g_UA_Image[i]:SetProperty("Image", tostring(strBKImage))
			
			if iRank == 5 then
				g_UA_Level_Text[i]:SetText("#{NJBZ_220816_395}")
			else
				strTemp = ScriptGlobal_Format("#{NJBZ_220816_200}", tostring(g_UA_Rank_Name[iRank + 1]), tostring(iLevel))
				g_UA_Level_Text[i]:SetText(strTemp)
			end

			strTemp = ScriptGlobal_Format("#{NJBZ_220816_201}", tostring(iStar))
			g_UA_Star_Text[i]:SetText(strTemp)			
			
			if tonumber(iJewel) ~= nil and tonumber(iJewel) > 0 then
				local itemAction = EnumAction(i - 1, "TargetUnderArmourJewel")
				g_Jewel_Button[i]:SetActionItem(itemAction:GetID())
			else
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

	--local ua_exp = CachedTarget:GetData("UAEXP")
	--strTemp = ScriptGlobal_Format("#{NJBZ_220816_219}", tostring(ua_exp))
	--TargetArmor_EXP:SetText(strTemp)
end

function TargetArmor_Frame_OnHiden()

end

function TargetArmor_Frame_On_ResetPos()
	TargetArmor_Frame:SetProperty("UnifiedPosition", g_TargetArmor_Frame_UnifiedPosition);
end

--装备
function TargetArmor_Equip_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetArmor_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenEquipFrame("other")
end

--资料
function TargetArmor_Data_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetArmor_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenPrivatePage("other")
end

--珍兽
function TargetArmor_Pet_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetArmor_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenPetFrame("other")
end

--子女
function TargetArmor_Infant_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetArmor_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Infant:Other_ToggleInfantPage()
	if bRet ~= 1 then
		TargetArmor_TargetInfant:SetCheck(0)
	end
end

--武魂
function TargetArmor_Wuhun_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetArmor_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherWuhun()
end

--秘籍
function TargetArmor_Miji_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetArmor_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherMiji()
	this:Hide()
end

--真元
function TargetArmor_ZhenYuan_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetArmor_Frame:GetProperty("UnifiedPosition"), 1)
	local bRet = Pneuma:ToggleTargetZhenYuanPage()
	if bRet ~= 1 then
		TargetArmor_ZhenYuan:SetCheck(0)
	end
end

--经脉
function TargetArmor_JingMai_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetArmor_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenOtherJingMai()
end

--神鼎
function TargetArmor_ShenDing_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetArmor_Frame:GetProperty("UnifiedPosition"), 1)
	local nLevel = CachedTarget:GetData("LEVEL",1)
	if nLevel == nil or nLevel < 15 then
		PushDebugMessage( "#{XLDL_140606_63}" )
	else
		local bRet = SystemSetup:OpenOtherShenDing()
		if nRet ~= 1 then
			TargetArmor_ShenDing:SetCheck(0)
		end
	end
end

--侠印
function TargetArmor_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetArmor_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage()
	if bRet == 1 then
		this:Hide()
	else
		TargetArmor_JueWei:SetCheck(0)
	end
end

--五行宝鉴
function TargetArmor_BaoJian_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetArmor_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
end

--武意
function TargetArmor_WuYi_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetArmor_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

--神器
function TargetArmor_ShenQi_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetArmor_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

--内甲
function TargetArmor_Armor_Page_Switch()

end

--骑乘
function TargetArmor_Ride_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetArmor_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenRidePage("other")
end

function TargetArmor_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetArmor_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end

function TargetArmor_Armor_MouseLeave(index)
	LuaFnCloseUnderArmourTip(1, index)
end

function TargetArmor_Armor_MouseEnter(index)
	
	if g_UA_Image[index] == nil then
		return
	end

	local bActived = DataPool:LuaFnGetOtherUnderArmourData(index - 1, "ACTIVED")	
	if bActived ~= 1 then
		return
	end
	
	local fX, fY = g_UA_Image[index]:GetAbsolutePositionToScreen()
	local SetWidth = g_UA_Image[index]:GetProperty("AbsoluteWidth")
	local SetHeight = g_UA_Image[index]:GetProperty("AbsoluteHeight")
	LuaFnOpenUnderArmourTip(1, index, tonumber(fX), tonumber(fY), tonumber(SetWidth), tonumber(SetHeight))
end


function TargetArmor_ShowPage()

	for i = 1, table.getn(g_TargetArmor_Page) do
		g_TargetPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	TargetArmor_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_TargetPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_TargetArmor_Page) do
			if i ~= nOtherPageNumber then
				g_TargetPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_TargetPageOrder = {}
	g_TargetPageCount = 0
	for i = 1, table.getn(g_TargetArmor_Page) do
		if TargetArmor_CheckPage(i) == 1 then
			g_TargetPageCount = g_TargetPageCount + 1
			g_TargetPageButton[g_TargetPageCount]:Show()
			g_TargetPageButton[g_TargetPageCount]:SetText(g_TargetArmor_Page[i].Text)	
			g_TargetPageOrder[g_TargetPageCount] = i
		end
	end
	
end

function TargetArmor_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_TargetPageOrder[idx]
	
	if idx == 1 then--装备
		TargetArmor_Equip_Page_Switch();
	elseif idx == 2 then--资料
		TargetArmor_Data_Page_Switch()
	elseif idx == 3 then--珍兽
		TargetArmor_Pet_Page_Switch()
	elseif idx == 4 then--子女
		TargetArmor_Infant_Page_Switch()
	elseif idx == 5 then--武魂
		TargetArmor_Wuhun_Page_Switch()
	elseif idx == 6 then--秘籍
		TargetArmor_Miji_Page_Switch()
	elseif idx == 7 then--真元
		TargetArmor_ZhenYuan_Page_Switch()
	elseif idx == 8 then--经脉
		TargetArmor_JingMai_Page_Switch()
	elseif idx == 9 then--神鼎
		TargetArmor_ShenDing_Page_Switch()
	elseif idx == 10 then--侠印
		TargetArmor_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		TargetArmor_BaoJian_Page_Switch()
	elseif idx == 12 then--武意
		TargetArmor_WuYi_Page_Switch()
	elseif idx == 13 then--神器
		TargetArmor_ShenQi_Page_Switch()
	elseif idx == 14 then--星盘
		TargetArmor_Armor_Page_Switch()
	elseif idx == 15 then--名物
		TargetArmor_CangPin_Page_Switch()
	end
end

function TargetArmor_CheckPage(idx)
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

function TargetArmor_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end


