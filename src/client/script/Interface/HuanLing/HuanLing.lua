
local m_CurrentSelectPet = -1
local m_PetMaxNumber = 10

local g_CurrentSelect = 0
local g_nContentButton = {}

local g_ReqQualText = 
{
	"#{ZSHP_180814_149}",	--无	品质1
	"#{ZSHP_180814_146}",	--5级	品质2
	"#{ZSHP_180814_145}",	--4级	品质3
	"#{ZSHP_180814_144}",	--4级	品质4
	"#{ZSHP_180814_143}",	--2级	品质5
	"#{ZSHP_180814_142}",	--1级	品质6
	"#{ZSHP_180814_148}",	--至尊	品质7
}

local g_MyQualText = 
{
	"#{ZSHP_180814_147}",	--万象	品质1
	"#{ZSHP_180814_146}",	--5级	品质2
	"#{ZSHP_180814_145}",	--4级	品质3
	"#{ZSHP_180814_144}",	--4级	品质4
	"#{ZSHP_180814_143}",	--2级	品质5
	"#{ZSHP_180814_142}",	--1级	品质6
	"#{ZSHP_180814_148}",	--至尊	品质7
}

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_HuanLing_Page = {
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

local g_HuanLing_PageButton = {}
local g_HuanLing_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

local g_HuanLing_Client_Button02_UnifiedPosition	
local g_HuanLing_Client_Button03_UnifiedPosition

function HuanLing_PreLoad()
	
	this:RegisterEvent("UI_COMMAND")
	
	this:RegisterEvent("OPEN_PET_HUANLING_UI")
	this:RegisterEvent("PET_HUANLING_ADD_COLLECTION")
	this:RegisterEvent("PET_HUANLING_COLLECTION_UPDATE",false)

	this:RegisterEvent("MARTIAL_UPDATE",false)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)
	
	this:RegisterEvent("FINISH_MISSION")
	this:RegisterEvent("TOGGLE_UPDATE_INFANT")
	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK")
	this:RegisterEvent("PET_HUANLING_UPDATE")
	
	this:RegisterEvent("ADD_PET",false)
	this:RegisterEvent("DELETE_PET",false)
	
	this:RegisterEvent("NEIDAN_CHIP_UPDATE", false)
	
	this:RegisterEvent("CANGPIN_UPDATE", false)
end

function HuanLing_OnLoad()
	
	g_HuanLing_PageButton[1] = HuanLing_SelfEquip
	g_HuanLing_PageButton[2] = HuanLing_SelfData
	g_HuanLing_PageButton[3] = HuanLing_Pet
	g_HuanLing_PageButton[4] = HuanLing_Infant
	g_HuanLing_PageButton[5] = HuanLing_Wuhun
	g_HuanLing_PageButton[6] = HuanLing_Xiulian
	g_HuanLing_PageButton[7] = HuanLing_Miji
	g_HuanLing_PageButton[8] = HuanLing_ZhenYuan
	g_HuanLing_PageButton[9] = HuanLing_JingMai
	g_HuanLing_PageButton[10] = HuanLing_ShenDing
	g_HuanLing_PageButton[11] = HuanLing_JueWei
	g_HuanLing_PageButton[12] = HuanLing_BaoJian
	g_HuanLing_PageButton[13] = HuanLing_WuYi
	g_HuanLing_PageButton[14] = HuanLing_ShenQi
	g_HuanLing_PageButton[15] = HuanLing_Armor
	g_HuanLing_PageButton[16] = HuanLing_CangPin
	g_HuanLing_PageButton[17] = HuanLing_OtherInfo
	
	g_HuanLing_PageMask[1] = HuanLing_SelfEquip_tips
	g_HuanLing_PageMask[2] = HuanLing_SelfData_tips
	g_HuanLing_PageMask[3] = HuanLing_Pet_tips
	g_HuanLing_PageMask[4] = HuanLing_Infant_tips
	g_HuanLing_PageMask[5] = HuanLing_Wuhun_tips
	g_HuanLing_PageMask[6] = HuanLing_Xiulian_tips
	g_HuanLing_PageMask[7] = HuanLing_Miji_tips
	g_HuanLing_PageMask[8] = HuanLing_ZhenYuan_tips
	g_HuanLing_PageMask[9] = HuanLing_JingMai_tips
	g_HuanLing_PageMask[10] = HuanLing_ShenDing_tips
	g_HuanLing_PageMask[11] = HuanLing_JueWei_tips
	g_HuanLing_PageMask[12] = HuanLing_BaoJian_tips
	g_HuanLing_PageMask[13] = HuanLing_WuYi_tips
	g_HuanLing_PageMask[14] = HuanLing_ShenQi_tips
	g_HuanLing_PageMask[15] = HuanLing_Armor_tips
	g_HuanLing_PageMask[16] = HuanLing_CangPin_tips
	g_HuanLing_PageMask[17] = HuanLing_OtherInfo_tips

	g_HuanLing_Client_Button02_UnifiedPosition = HuanLing_Client_Button02:GetProperty("UnifiedPosition")	
	g_HuanLing_Client_Button03_UnifiedPosition = HuanLing_Client_Button03:GetProperty("UnifiedPosition")
	
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

function HuanLing_OnEvent(event)

	if event == "PET_HUANLING_ADD_COLLECTION"  then
		
		local new_HL_id = tonumber(arg0)
		if this:IsVisible() then
			HuanLing_Update(new_HL_id)
			return
		end
		
		HuanLing_Init()
		this:Show()
		local nLevel = Player:GetLevel()
		HuanLing_Refresh_Page_Button(nLevel)
		HuanLing_UpdatePetList()
		HuanLing_Update(new_HL_id)
		HuanLing_ShowPage()
	end

	if event == "PET_HUANLING_COLLECTION_UPDATE"  then
		if this:IsVisible() then
			HuanLing_Update(-1)
		end
	end
	
	if event == "OPEN_PET_HUANLING_UI" then

		if this:IsVisible() then
			return
		end
		
		HuanLing_Init()
		this:Show()
		local nLevel = Player:GetLevel()
		HuanLing_Refresh_Page_Button(nLevel)
		HuanLing_UpdatePetList()
		HuanLing_Update(-1)
		HuanLing_ShowPage()
		return

	end
	
	if event == "MARTIAL_UPDATE" or event == "MARTIAL_HIDE_ZHAOHUI_TIP" then
		HuanLing_RefreshWuYiTip()
	end
	
	if event == "UPDATE_WILLGET_MISSION_TRACK" or event=="TOGGLE_UPDATE_INFANT" or event == "FINISH_MISSION" then
		local nLevel =Player:GetLevel()
		HuanLing_Refresh_Page_Button(nLevel)
		HuanLing_ShowPage()
	end

	if event == "PET_HUANLING_UPDATE" then
		if this:IsVisible() then		
			HuanLing_UpdateListItem(tonumber(arg0) , tonumber(arg1))
			HuanLing_Update(-1)
		end
	end
	
	if event == "ADD_PET" or event == "DELETE_PET" then
		HuanLing_Reset()
		HuanLing_UpdatePetList()
		HuanLing_Update(-1)
		return
	end
	
	if event == "NEIDAN_CHIP_UPDATE" then
		HuanLing_Refresh_PetTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		HuanLing_RefreshCangPinTip()
	end
end

function HuanLing_Reset()
	
	g_CurrentSelect = 0
	m_CurrentSelectPet = -1
	g_nContentButton = {}
	HuanLing_Pet_List:CleanAllElement("HuanLing")
	HuanLing_Pet_Choose_Select:ResetList()
	HuanLing_Pet_Choose_Select:ResetText()
	HuanLing_Pet_Choose_Select:ResetLastSelectIndex()
	HuanLing_Client_Button01:SetCheck(0)
	HuanLing_Client_Button02:SetCheck(0)
	HuanLing_Client_Button03:SetCheck(1)
	
	HuanLing_Pet:SetCheck(1)
	
	HuanLing_FakeObject:SetFakeObject("")
	
	HuanLing_Need_WuXinglevel_Text:SetText("")
	HuanLing_Need_LingXinglevel_Text:SetText("")
	HuanLing_Need_BianYilevel_Text:SetText("")
	HuanLing_Need_Quality_Text:SetText("")
	
	HuanLing_AtPresent_WuXinglevel_Text:SetText("")
	HuanLing_AtPresent_LingXinglevel_Text:SetText("")
	HuanLing_AtPresent_BianYilevel_Text:SetText("")
	HuanLing_AtPresent_Quality_Text:SetText("")

	if Player:GetData("IsOriginalJD") == 1 then
		HuanLing_Client_Button04:Hide()
	else
		HuanLing_Client_Button04:Show()
	end
	
	if Player:GetData("Is2606S") == 1 then
		HuanLing_Client_Button02:Hide()
		HuanLing_Client_Button02:SetProperty("UnifiedPosition", g_HuanLing_Client_Button03_UnifiedPosition);
		HuanLing_Client_Button03:SetProperty("UnifiedPosition", g_HuanLing_Client_Button02_UnifiedPosition);
		HuanLing_Client_Button04:Hide()
	else
		HuanLing_Client_Button02:Show()
		HuanLing_Client_Button02:SetProperty("UnifiedPosition", g_HuanLing_Client_Button02_UnifiedPosition);
		HuanLing_Client_Button03:SetProperty("UnifiedPosition", g_HuanLing_Client_Button03_UnifiedPosition);
		HuanLing_Client_Button04:Show()
	end
	
end

function HuanLing_Adjust_Position()

	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		HuanLing_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end

end

function HuanLing_Init()
	
	HuanLing_Reset()
	HuanLing_Adjust_Position()
	
end

function HuanLing_UpdatePoint(update , nActivePointIndex)



end

function HuanLing_UpdatePageButton()

	
end

function HuanLing_UpdatePetList()
	
	local nPetCount = Pet:GetPet_Count()

	if nPetCount > 0 then
		
		for	i = 1, m_PetMaxNumber do
		
			if Pet:IsPresent(i-1) then				
				
				local szPetName = Pet:GetPetList_Appoint(i-1)
				
				local nHuanLingId = Pet:GetHuanlingIdByIndex(i-1)
				
				if nHuanLingId < 0 then
					if Pet:GetIsFighting(i-1) then
					
						HuanLing_Pet_Choose_Select:AddTextItem("#c0A9605"..szPetName, i-1)

					elseif (Pet:GetIsPossession(i-1)) then
					
						HuanLing_Pet_Choose_Select:AddTextItem("#c996699"..szPetName, i-1)
						
					else
					
						HuanLing_Pet_Choose_Select:AddTextItem(szPetName, i-1)
					
					end
				else
				
					szPetName = szPetName.."#{ZSHP_180814_26}"
					
					if Pet:GetIsFighting(i-1) then
					
						HuanLing_Pet_Choose_Select:AddTextItem("#c0A9605"..szPetName, i-1)

					elseif Pet:GetIsPossession(i-1) then
					
						HuanLing_Pet_Choose_Select:AddTextItem("#c996699"..szPetName, i-1)
						
					else
					
						HuanLing_Pet_Choose_Select:AddTextItem(szPetName, i-1)
					
					end
				end

			end
		end
	end
end

function HuanLing_Update(hl_id)

	g_nContentButton = {}	
	
	Pet:Lua_InitPetHuanLingList(m_CurrentSelectPet)
	
	HuanLing_Pet_List:CleanAllElement("HuanLing")
	
	local count = Pet:Lua_GetHuanLingListCount()
	
	if count > 0 then
		
		g_CurrentSelect = 1
		
		for i = 0 , count - 1 do		
			
			HuanLing_AddHuanLingItem(i)
			
			local nHuanLingId = Pet:Lua_GetPetHuanLingInfoFromList(i,"Id")
			
			if nHuanLingId == hl_id then
				g_CurrentSelect = i + 1
			end
		
		end
		
		HuanLing_SetItemSelected(g_CurrentSelect)
		
		HuanLing_Pet_List:Flash()
		
		HuanLing_Pet_List:SetElementsInView(g_CurrentSelect)		
		
		HuanLing_UpdateLeftInfo()
	end
	
	
	
end

function HuanLing_AddHuanLingItem(index)
	
	local ItemBar = HuanLing_Pet_List:AddItemElement( "HuanLing_Head", "HuanLing","" ,"")
	ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
	
	local bkImage 		= 	ItemBar:GetChildItem("HuanLing","__auto_SuperBarImage1__")	
	local headImage		= 	ItemBar:GetChildItem("HuanLing","__auto_SuperBarImage2__")
	local redImage 		= 	ItemBar:GetChildItem("HuanLing","__auto_SuperBarImage3__")
	local grayImage 	= 	ItemBar:GetChildItem("HuanLing","__auto_SuperBarImage4__")
	local inUseImage 	= 	ItemBar:GetChildItem("HuanLing","__auto_SuperBarImage5__")	
	
	local nHuanLingId = Pet:Lua_GetPetHuanLingInfoFromList(index,"Id")
	local nReqSavvy = Pet:Lua_GetPetHuanLingInfoFromList(index,"ReqSavvy")
	local nReqLing = Pet:Lua_GetPetHuanLingInfoFromList(index,"ReqLing")
	local nReqVLevel = Pet:Lua_GetPetHuanLingInfoFromList(index,"ReqVLevel")
	local nReqQuality = Pet:Lua_GetPetHuanLingInfoFromList(index,"Quality")
	local nHuanLingName = Pet:Lua_GetPetHuanLingInfoFromList(index,"Name")
	local strQualText = Pet:Lua_GetPetHuanLingInfoFromList(index,"QualText")
	
	local strImage = Pet:Lua_GetPetHuanLingInfoFromList(index,"Icon")	
	headImage:SetProperty("Image", strImage)
	
	ItemBar:SetToolTip(tostring(nHuanLingName)..tostring(strQualText))
	
	if Pet:Lua_IsHavePetHuanLingCollection(nHuanLingId) ~= 1 then
		grayImage:Show()
		redImage:Hide()
		inUseImage:Hide()
	else
		grayImage:Hide()
		
		local bMask = 0
		if m_CurrentSelectPet >= 0 then
			
			local nSavvy = Pet:GetSavvy(m_CurrentSelectPet)
			if nSavvy < nReqSavvy then
				bMask = 1
			end
			
			
			local nLing = Pet:GetLixing(m_CurrentSelectPet)
			if nLing < nReqLing then
				bMask = 1
			end
			
			local nType = Pet:GetPetType(m_CurrentSelectPet)	
			if nType == 0 then	--宝宝
				if nReqVLevel > 0 then
					bMask = 1
				end
			elseif nType == 1 then	
				local nVLevel = Pet:Lua_GetPetVarLevel(m_CurrentSelectPet)
				if nVLevel < nReqVLevel then
					bMask = 1
				end
			else
				bMask = 1
			end

			local petQuality = Pet:GetPetQuality(m_CurrentSelectPet)
			if petQuality < nReqQuality then
				bMask = 1
			end
		end
		
		
		
		if bMask == 1 then
			redImage:Show()
		else
			redImage:Hide()
		end
		
		if Pet:Lua_IsHuanLingInUse(m_CurrentSelectPet,nHuanLingId) == 1 then
			inUseImage:Show()
		else
			inUseImage:Hide()	
		end
	
	end
	
	table.insert(g_nContentButton,ItemBar)
end

function HuanLing_OnItemClick()
	
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1

	if nIndex > 0 then
		
		if g_CurrentSelect ~= nIndex then
		
			HuanLing_SetItemSelected(nIndex)
			HuanLing_Pet_List:Flash()
			g_CurrentSelect = nIndex
			
			HuanLing_UpdateLeftInfo()
	
		end
	end

end

function HuanLing_SetItemSelected(nIndex)
	for nButtonIndex = 1,table.getn(g_nContentButton) do
		if nil ~= g_nContentButton[nButtonIndex] then
			if nButtonIndex ~= nIndex then
				g_nContentButton[nButtonIndex]:SetBarButtonSelected(false)
			else
				g_nContentButton[nButtonIndex]:SetBarButtonSelected(true)
			end
		end
	end
end

function HuanLing_OnSelectPet()

	local _,nIndex = HuanLing_Pet_Choose_Select:GetCurrentSelect()
	
	if m_CurrentSelectPet ~= nIndex then
		m_CurrentSelectPet = nIndex
		HuanLing_Update(-1)
	end

end

function HuanLing_UpdateLeftInfo()
	
	local nHuanLingId = Pet:Lua_GetPetHuanLingInfoFromList(g_CurrentSelect - 1,"Id")
	local nHuanLingName = Pet:Lua_GetPetHuanLingInfoFromList(g_CurrentSelect - 1,"Name")
	local nReqSavvy = Pet:Lua_GetPetHuanLingInfoFromList(g_CurrentSelect - 1,"ReqSavvy")
	local nReqLing = Pet:Lua_GetPetHuanLingInfoFromList(g_CurrentSelect - 1,"ReqLing")
	local nReqVLevel = Pet:Lua_GetPetHuanLingInfoFromList(g_CurrentSelect - 1,"ReqVLevel")
	local nReqQuality = Pet:Lua_GetPetHuanLingInfoFromList(g_CurrentSelect - 1,"Quality")
	local strQualText = Pet:Lua_GetPetHuanLingInfoFromList(g_CurrentSelect - 1,"QualText")
	
	HuanLing_PetName:SetText("#gFF0FA0"..nHuanLingName)
	HuanLing_PetText:SetText(strQualText)
	
	local strReqSavvy = ScriptGlobal_Format("#{ZSHP_180814_22}",tostring(nReqSavvy))
	HuanLing_Need_WuXinglevel_Text:SetText(strReqSavvy)
	
	local strReqLing = ScriptGlobal_Format("#{ZSHP_180814_22}",tostring(nReqLing))
	HuanLing_Need_LingXinglevel_Text:SetText(strReqLing)
	
	if nReqVLevel == 0 then
		HuanLing_Need_BianYilevel_Text:SetText("#{ZSHP_180814_21}")
	else
		local strReqVLevel = ScriptGlobal_Format("#{ZSHP_180814_22}",tostring(nReqVLevel))
		HuanLing_Need_BianYilevel_Text:SetText(strReqVLevel)
	end
	
	if g_ReqQualText[nReqQuality] then
		HuanLing_Need_Quality_Text:SetText(g_ReqQualText[nReqQuality])
	else
		HuanLing_Need_Quality_Text:SetText("")	
	end	
	
	HuanLing_FakeObject:SetFakeObject("")
	Pet:Lua_UpdatePetHuanLingModel(nHuanLingId)
	HuanLing_FakeObject:SetFakeObject("HuanLingPet")
	
	if m_CurrentSelectPet < 0 then
	
		HuanLing_AtPresent_WuXinglevel_Text:SetText("")
		HuanLing_AtPresent_LingXinglevel_Text:SetText("")
		HuanLing_AtPresent_BianYilevel_Text:SetText("")
		HuanLing_AtPresent_Quality_Text:SetText("")
		
	else
		
		local nSavvy = Pet:GetSavvy(m_CurrentSelectPet)
		if nSavvy >= nReqSavvy then
			local strSavvy = ScriptGlobal_Format("#{ZSHP_180814_16}",tostring(nSavvy))
			HuanLing_AtPresent_WuXinglevel_Text:SetText(strSavvy)
		else
			local strSavvy = ScriptGlobal_Format("#{ZSHP_180814_17}",tostring(nSavvy))
			HuanLing_AtPresent_WuXinglevel_Text:SetText(strSavvy)
		end	
		
		local nLing = Pet:GetLixing(m_CurrentSelectPet)		
		if nLing >= nReqLing then
			local strLing = ScriptGlobal_Format("#{ZSHP_180814_16}",tostring(nLing))
			HuanLing_AtPresent_LingXinglevel_Text:SetText(strLing)
		else
			local strLing = ScriptGlobal_Format("#{ZSHP_180814_17}",tostring(nLing))
			HuanLing_AtPresent_LingXinglevel_Text:SetText(strLing)
		end
		
		local nType = Pet:GetPetType(m_CurrentSelectPet)	
		if nType == 0 then
			if nReqVLevel == 0 then
				HuanLing_AtPresent_BianYilevel_Text:SetText("#{ZSHP_180814_135}")
			else
				HuanLing_AtPresent_BianYilevel_Text:SetText("#{ZSHP_180814_134}")
			end
		elseif nType == 1 then	
			local nVLevel = Pet:Lua_GetPetVarLevel(m_CurrentSelectPet)
			if nVLevel >= nReqVLevel then
				local strVLevel = ScriptGlobal_Format("#{ZSHP_180814_16}",tostring(nVLevel))
				HuanLing_AtPresent_BianYilevel_Text:SetText(strVLevel)
			else
				local strVLevel = ScriptGlobal_Format("#{ZSHP_180814_17}",tostring(nVLevel))
				HuanLing_AtPresent_BianYilevel_Text:SetText(strVLevel)
			end
		else
			HuanLing_AtPresent_BianYilevel_Text:SetText("#{ZSHP_180814_132}")
		end
		
		local petQuality = Pet:GetPetQuality(m_CurrentSelectPet)
		if petQuality >= nReqQuality then
			if g_MyQualText[petQuality] then
				HuanLing_AtPresent_Quality_Text:SetText("#G"..g_MyQualText[petQuality])
			else
				HuanLing_AtPresent_Quality_Text:SetText("")
			end
		else
			if g_MyQualText[petQuality] then
				HuanLing_AtPresent_Quality_Text:SetText("#cff0000"..g_MyQualText[petQuality])
			else
				HuanLing_AtPresent_Quality_Text:SetText("")
			end
		end
	end
	
end

function HuanLing_HuanLingButton_Clicked()
	if m_CurrentSelectPet < 0 then
		PushDebugMessage("#{ZSHP_180814_40}")
		return
	end	
	
	local nHuanLingId = Pet:Lua_GetPetHuanLingInfoFromList(g_CurrentSelect - 1,"Id")
	if Pet:Lua_IsHavePetHuanLingCollection(nHuanLingId) ~= 1 then	
		PushDebugMessage("#{ZSHP_180814_39}")
		return
	end	

	if not Pet:IsPresent(m_CurrentSelectPet) then
		return
	end
	
	local strName,strName2 = Pet:GetName(m_CurrentSelectPet)
	local msg = ""
	--出战
	if Pet:GetIsFighting(m_CurrentSelectPet) then
		msg = ScriptGlobal_Format("#{ZSHP_180814_49}",strName2)
		PushDebugMessage(msg)
		return	
	end
	
	--附体
	if Pet:GetIsPossession(m_CurrentSelectPet) then
		msg = ScriptGlobal_Format("#{ZSHP_180814_50}",strName2)
		PushDebugMessage(msg)
		return	
	end

	local hid,lid = Pet:GetGUID(m_CurrentSelectPet);
	Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(892940)
    Set_XSCRIPT_Function_Name("Pet_Huanling")
    Set_XSCRIPT_Parameter(0, hid)
	Set_XSCRIPT_Parameter(1, lid)
	Set_XSCRIPT_Parameter(2, nHuanLingId)
	Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

end

function HuanLing_RestoreButton_Clicked()

	if m_CurrentSelectPet < 0 then
		PushDebugMessage("#{ZSHP_180814_53}")
		return
	end	
	
	if not Pet:IsPresent(m_CurrentSelectPet) then
		return
	end
	
	local strName,strName2 = Pet:GetName(m_CurrentSelectPet)
	local msg = ""
	--出战
	if Pet:GetIsFighting(m_CurrentSelectPet) then
		msg = ScriptGlobal_Format("#{ZSHP_180814_55}",strName2)
		PushDebugMessage(msg)
		return	
	end
	
	--附体
	if Pet:GetIsPossession(m_CurrentSelectPet) then
		msg = ScriptGlobal_Format("#{ZSHP_180814_56}",strName2)
		PushDebugMessage(msg)
		return	
	end
	
	local hid,lid = Pet:GetGUID(m_CurrentSelectPet);
	Clear_XSCRIPT()
    Set_XSCRIPT_ScriptID(892940)
    Set_XSCRIPT_Function_Name("Pet_Cancel_Huanling")
    Set_XSCRIPT_Parameter(0, hid)
	Set_XSCRIPT_Parameter(1, lid)
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function HuanLing_TurnLeft(start)
	--向左旋转开始
	if start == 1 and CEArg:GetValue("MouseButton")=="LeftButton" then
		HuanLing_FakeObject:RotateBegin(-0.3);
	--向左旋转结束
	else
		HuanLing_FakeObject:RotateEnd();
	end
end

function HuanLing_TurnRight(start)
	--向右旋转开始
	if start == 1 and CEArg:GetValue("MouseButton")=="LeftButton" then
		HuanLing_FakeObject:RotateBegin(0.3);
	--向右旋转结束
	else
		HuanLing_FakeObject:RotateEnd();
	end
end

function HuanLing_Close()

	this:Hide()

end

function HuanLing_OnHidden()

	HuanLing_Reset()

end

function HuanLing_UpdateListItem(pHID , pLID)
		
	local item_count = HuanLing_Pet_Choose_Select:GetListCount()
	
	if item_count > 0 then
	
		for i = 0 , item_count - 1 do
		
			local pet_index = HuanLing_Pet_Choose_Select:GetTextItemId(i)
			
			if pet_index ~= nil then
			
				if Pet:IsPresent(pet_index) then					
					
					local hid,lid = Pet:GetGUID(pet_index)
					
					if hid == pHID and lid == pLID then
					
						local szPetName = Pet:GetPetList_Appoint(pet_index)					
						local nHuanLingId = Pet:GetHuanlingIdByIndex(pet_index)						
						if nHuanLingId >= 0 then						
							szPetName = szPetName.."#{ZSHP_180814_26}"
						end
						
						local szText = szPetName						
						if Pet:GetIsFighting(pet_index) then
							szText = "#c0A9605"..szPetName
						elseif Pet:GetIsPossession(pet_index) then
							szText = "#c996699"..szPetName					
						end

						HuanLing_Pet_Choose_Select:SetTextItemText(i ,szText)	
						
						if m_CurrentSelectPet == pet_index then
							HuanLing_Pet_Choose_Select:SetText(szText)
						end
						
					end				

				end
	
			end
		end
	end
	
	
	
end

--装备
function HuanLing_SelfEquip_Page_Switch()
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	OpenEquip(1);
end

--资料
function HuanLing_SelfData_Page_Switch()
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("self");
end

--子女
function HuanLing_Infant_Page_Switch()
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	else
		HuanLing_Infant:SetCheck(0)
	end
end

--武魂
function HuanLing_Wuhun_Page_Switch()
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	ToggleWuhunPage();
end

--修炼
function HuanLing_Xiulian_Page_Switch()
    local nLevel = Player:GetData("LEVEL")
	if(nLevel >= 70) then
		Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
		XiuLianPage();
	else
	    HuanLing_Xiulian:SetCheck(0)
	    PushDebugMessage("#{XL_090707_62}")
	end
end

--秘籍
function HuanLing_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenMijiPage();
	if nRet ~= 1 then
		HuanLing_Miji:SetCheck(0)
	end
end

--真元
function HuanLing_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	if bRet ~= 1 then
		HuanLing_ZhenYuan:SetCheck(0)
	end
end

--经脉
function HuanLing_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenJingMaiPage();
	if nRet ~= 1 then
		HuanLing_JingMai:SetCheck(0)
	end
end

--神鼎
function  HuanLing_ShenDing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenShenDingPage();
	if nRet ~= 1 then
		HuanLing_ShenDing:SetCheck(0)
	end
end

--侠印
function  HuanLing_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if ( bRet == 1 ) then
		this:Hide();
	else
		HuanLing_JueWei:SetCheck(0)
	end
end

--骑乘
function HuanLing_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	OpenRidePage();
end

--其他
function HuanLing_OtherInfo_Page_Switch()
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	OtherInfoPage();
end

--五行宝鉴
function HuanLing_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()

end

--珍兽
function HuanLing_Pet_Page_Switch()
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	TogglePetPage();
end

--御兽
function HuanLing_YuShou_Page_Switch()
	
	if Player:GetData("Is2606S") == 1 then
		return
	end
	
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	
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
		HuanLing_Client_Button03:SetCheck(0)
	end

end

function HuanLing_Refresh_Page_Button( nLevel)

	if 1 == 1 then
		return
	end
	
	--神鼎
	if nLevel < 15 then
		HuanLing_ShenDing:Disable()
		HuanLing_ShenDing_tips:Show()
	else
		HuanLing_ShenDing:Enable()
		HuanLing_ShenDing_tips:Hide()
	end
	
	--子女
	local InfantCount = Infant:GetInfantCount();
	if nLevel < 50 or InfantCount <= 0 then
		HuanLing_Infant:Disable()
		HuanLing_Infant_tips:Show()
	else
		HuanLing_Infant:Enable()
		HuanLing_Infant_tips:Hide()
	end
	
	HuanLing_Wuhun:Enable()
	HuanLing_Wuhun_tips:Hide()

	--修炼
	if nLevel < 70 then
		HuanLing_Xiulian:Disable()
		HuanLing_Xiulian_tips:Show()
	else
		HuanLing_Xiulian:Enable()
		HuanLing_Xiulian_tips:Hide()
	end
	
	--秘籍
	local ret = DataPool:Lua_IsMissionHaveDone(1651)
	if nLevel < 75 or ret == 0 then
		HuanLing_Miji:Disable()
		HuanLing_Miji_tips:Show()
	else
		HuanLing_Miji:Enable()
		HuanLing_Miji_tips:Hide()
	end
	
	--真元
	local ret = DataPool:Lua_IsMissionHaveDone(1600)
	if nLevel < 80 or ret == 0 then
		HuanLing_ZhenYuan:Disable()
		HuanLing_ZhenYuan_tips:Show()
	else
		HuanLing_ZhenYuan:Enable()
		HuanLing_ZhenYuan_tips:Hide()
	end
	
	--侠印
	if nLevel < 85 then
		HuanLing_JueWei:Disable()
		HuanLing_JueWei_tips:Show()
	else
		HuanLing_JueWei:Enable()
		HuanLing_JueWei_tips:Hide()
	end
	
	--经脉
	local ret = DataPool:Lua_IsMissionHaveDone(1554)
	if nLevel < 90 or ret == 0  then
		HuanLing_JingMai:Disable()
		HuanLing_JingMai_tips:Show()
	else
		HuanLing_JingMai:Enable()
		HuanLing_JingMai_tips:Hide()
	end

	if nLevel < 85 then
		HuanLing_BaoJian:Disable()
		HuanLing_BaoJian_tips:Show()
	else
		HuanLing_BaoJian:Enable()
		HuanLing_BaoJian_tips:Hide()
	end

	--武意
	if MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85 then
		HuanLing_WuYi:Enable()
		HuanLing_WuYi_tips:Hide()
	else
		HuanLing_WuYi:Disable()
		HuanLing_WuYi_tips:Show()
	end
	
	HuanLing_RefreshWuYiTip()
		
	--九星神器DIY技能
	if DataPool:Lua_IsMissionHaveDone(1950) == 1 then
		HuanLing_ShenQi:Enable()
		HuanLing_ShenQi_tips:Hide()
	else
		HuanLing_ShenQi:Disable()
		HuanLing_ShenQi_tips:Show()
	end
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		HuanLing_Armor:Enable()
		HuanLing_Armor_tips:Hide()
	else
		HuanLing_Armor:Disable()
		HuanLing_Armor_tips:Show()
	end
	
	HuanLing_Refresh_PetTip()
	
	if nLevel >= 30 then
		HuanLing_CangPin:Enable()
		HuanLing_CangPin_tips:Hide()
	else
		HuanLing_CangPin:Disable()
		HuanLing_CangPin_tips:Show()
	end
	
	HuanLing_RefreshCangPinTip()
end

function HuanLing_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

--九星神器DIY技能
function HuanLing_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function HuanLing_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_HuanLing_PageButton[idx]:GetProperty("UnifiedXPosition");
			HuanLing_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1 then
		HuanLing_WuYi_Buttontips:Show()
	else
		HuanLing_WuYi_Buttontips:Hide()
	end
end

--内甲
function HuanLing_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

--珍兽内丹
function HuanLing_NeiDan_Page_Switch()

	if Player:GetData("IsOriginalJD") == 1 then
		return
	end
	if Player:GetData("Is2606S") == 1 then
		return
	end
	
	local nLevel = Player:GetData("LEVEL")
	if nLevel < 60 then
		PushDebugMessage("#{ZSND_230428_05}")
		HuanLing_Client_Button04:SetCheck(0)
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(3000) ~= 1 then
		PushDebugMessage("#{ZSND_230428_06}")
		HuanLing_Client_Button04:SetCheck(0)
		return
	end
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1)	
	Pet:LuaFnOpenPetNeiDan("self")
end

function HuanLing_Refresh_PetTip()
	local bShowTip = DataPool:LuaFnHavePetNeiDanChipCanCompound()
	if bShowTip == 1 then
		HuanLing_Client_Button04tips:Show()
		HuanLing_Pet_Buttontips:Show()
	else
		HuanLing_Client_Button04tips:Hide()
		HuanLing_Pet_Buttontips:Hide()
	end
end

function HuanLing_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", HuanLing_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function HuanLing_RefreshCangPinTip()
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
			local newpos = g_PageButtonTipsPos[idx] --28 + g_HuanLing_PageButton[idx]:GetProperty("UnifiedXPosition");
			HuanLing_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		HuanLing_CangPin_Buttontips:Show()
	else
		HuanLing_CangPin_Buttontips:Hide()
	end
end


function HuanLing_ShowPage()

	for i = 1, table.getn(g_HuanLing_Page) do
		g_HuanLing_PageButton[i]:Hide()
		g_HuanLing_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	HuanLing_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_HuanLing_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_HuanLing_Page) do
			if i ~= nPageNumber then
				g_HuanLing_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_HuanLing_Page) do
		if HuanLing_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_HuanLing_PageButton[g_PageCount]:Show()
			g_HuanLing_PageButton[g_PageCount]:SetText(g_HuanLing_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if HuanLing_IsPageEnable(i) == 1 then
				g_HuanLing_PageButton[g_PageCount]:Enable()
				g_HuanLing_PageMask[g_PageCount]:Hide()
			else
				g_HuanLing_PageButton[g_PageCount]:Disable()
				g_HuanLing_PageMask[g_PageCount]:Show()
				if g_HuanLing_Page[i].Tip ~= "" then
					g_HuanLing_PageMask[g_PageCount]:SetToolTip(g_HuanLing_Page[i].Tip)
				end
			end
		end
	end
	
	HuanLing_RefreshWuYiTip()
	HuanLing_Refresh_PetTip()
	HuanLing_RefreshCangPinTip()
	
end

function HuanLing_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		HuanLing_SelfEquip_Page_Switch(0);
	elseif idx == 2 then--资料
		HuanLing_SelfData_Page_Switch()
	elseif idx == 3 then--珍兽
		--SelfData_Pet_Down()
	elseif idx == 4 then--子女
		HuanLing_Infant_Page_Switch()
	elseif idx == 5 then--武魂
		HuanLing_Wuhun_Page_Switch()
	elseif idx == 6 then--修炼
		HuanLing_Xiulian_Page_Switch()
	elseif idx == 7 then--秘籍
		HuanLing_Miji_Page_Switch()
	elseif idx == 8 then--真元
		HuanLing_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		HuanLing_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		HuanLing_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		HuanLing_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		HuanLing_OpenBaoJian()
	elseif idx == 13 then--武意
		HuanLing_OpenWuYi()
	elseif idx == 14 then--神器
		HuanLing_OpenShenQi()
	elseif idx == 15 then--星盘
		HuanLing_Armor_Page_Switch()
	elseif idx == 16 then--名物
		HuanLing_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		HuanLing_OtherInfo_Page_Switch()
	end
end

function HuanLing_CheckPage(idx)
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

function HuanLing_IsPageEnable(idx)
	
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

function HuanLing_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


