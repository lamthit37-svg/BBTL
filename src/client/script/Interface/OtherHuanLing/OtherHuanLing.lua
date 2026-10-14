
local m_CurrentSelectPet = -1

local g_CurrentSelect = 0
local g_nContentButton = {}
local g_ReqQualText = 
{
	"#{CKHL_20230427_13}",	--无	品质1
	"#{CKHL_20230427_18}",	--5级	品质2
	"#{CKHL_20230427_17}",	--4级	品质3
	"#{CKHL_20230427_16}",	--4级	品质4
	"#{CKHL_20230427_15}",	--2级	品质5
	"#{CKHL_20230427_14}",	--1级	品质6
	"#{CKHL_20230427_19}",	--至尊	品质7
}

local g_Frame_UnifiedPosition = 0

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_OtherHuanLing_Page = {
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

local g_OtherHuanLing_Button02_UnifiedPosition	
local g_OtherHuanLing_Button03_UnifiedPosition

function OtherHuanLing_PreLoad()
	
	this:RegisterEvent("OPEN_OTHERHUANLING")
	this:RegisterEvent("ON_SCENE_TRANS",false)
	this:RegisterEvent("ON_SERVER_TRANS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

	this:RegisterEvent("ADJEST_UI_POS",false)	
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function OtherHuanLing_OnLoad()
	
	g_Frame_UnifiedPosition = OtherHuanLing_Frame:GetProperty("UnifiedPosition");
		
	g_OtherPageButton[1] = OtherHuanLing_SelfEquip
	g_OtherPageButton[2] = OtherHuanLing_TargetData
	g_OtherPageButton[3] = OtherHuanLing_Pet
	g_OtherPageButton[4] = OtherHuanLing_TargetInfant
	g_OtherPageButton[5] = OtherHuanLing_TargetWuhun
	g_OtherPageButton[6] = OtherHuanLing_Miji
	g_OtherPageButton[7] = OtherHuanLing_ZhenYuan
	g_OtherPageButton[8] = OtherHuanLing_JingMai
	g_OtherPageButton[9] = OtherHuanLing_ShenDing
	g_OtherPageButton[10] = OtherHuanLing_JueWei
	g_OtherPageButton[11] = OtherHuanLing_BaoJian
	g_OtherPageButton[12] = OtherHuanLing_WuYi
	g_OtherPageButton[13] = OtherHuanLing_ShenQi
	g_OtherPageButton[14] = OtherHuanLing_Armor
	g_OtherPageButton[15] = OtherHuanLing_CangPin
	
	g_OtherHuanLing_Button02_UnifiedPosition = OtherHuanLing_Client_Button02:GetProperty("UnifiedPosition")	
	g_OtherHuanLing_Button03_UnifiedPosition = OtherHuanLing_Client_Button03:GetProperty("UnifiedPosition")
	
end

function OtherHuanLing_OnEvent(event)

	if event == "OPEN_OTHERHUANLING" then

		if this:IsVisible() then
			return
		end
		
		local objCared = CachedTarget:GetData("NPCID", 1)
		if type(objCared) ~= "number" then
			return
		end
		
		this:CareObject(objCared , 1)

		OtherHuanLing_Init()
		this:Show()
		OtherHuanLing_Update()
		local otherUnionPos = Variable:GetVariable("OtherUnionPos");
		if(otherUnionPos ~= nil) then
			OtherHuanLing_Frame:SetProperty("UnifiedPosition", otherUnionPos);
		end
		OtherHuanLing_ShowPage()
		return
	end
	
	if event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" or event == "HIDE_ON_SCENE_TRANSED" then
		if this:IsVisible() then
			OtherHuanLing_OnHidden()
		end
	end
	
	-- 游戏窗口尺寸发生了变化 or 游戏分辨率发生了变化
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		if this:IsVisible() then
			OtherHuanLing_Adjust_Position()
		end
	end

end

function OtherHuanLing_Reset()
	
	g_CurrentSelect = 0
	g_nContentButton = {}
	OtherHuanLing_Pet_List:CleanAllElement("OtherHuanLing")
	
	OtherHuanLing_Client_Button01:SetCheck(0)
	OtherHuanLing_Client_Button02:SetCheck(0)
	OtherHuanLing_Client_Button03:SetCheck(1)
	
	OtherHuanLing_Pet:SetCheck(1)
	
	OtherHuanLing_FakeObject:SetFakeObject("")
	
	if Player:GetData("IsOriginalJD") == 1 then
		OtherHuanLing_Client_Button04:Hide()
	else
		OtherHuanLing_Client_Button04:Show()
	end
	
	if Player : GetData("Is2606S") == 1 then
		OtherHuanLing_Client_Button02:Hide()
		OtherHuanLing_Client_Button02:SetProperty("UnifiedPosition", g_OtherHuanLing_Button03_UnifiedPosition);
		OtherHuanLing_Client_Button03:SetProperty("UnifiedPosition", g_OtherHuanLing_Button02_UnifiedPosition);
		OtherHuanLing_Client_Button04:Hide()
	else
		OtherHuanLing_Client_Button02:Show()
		OtherHuanLing_Client_Button02:SetProperty("UnifiedPosition", g_OtherHuanLing_Button02_UnifiedPosition);
		OtherHuanLing_Client_Button03:SetProperty("UnifiedPosition", g_OtherHuanLing_Button03_UnifiedPosition);
		OtherHuanLing_Client_Button04:Show()
	end
end

function OtherHuanLing_Adjust_Position()
	OtherHuanLing_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition);
end

function OtherHuanLing_Init()
	
	OtherHuanLing_Reset()
	OtherHuanLing_Adjust_Position()
	
end


function OtherHuanLing_Update()

	g_nContentButton = {}	
	
	Pet:Lua_InitOtherHuanLingList()
	
	OtherHuanLing_Pet_List:CleanAllElement("OtherHuanLing")
	
	local count = Pet:Lua_GetOtherHuanLingListCount()
	
	if count > 0 then
		
		g_CurrentSelect = 1
		
		for i = 0 , count - 1 do		
			
			OtherHuanLing_AddOtherHuanLingItem(i)
				
		end
		
		OtherHuanLing_SetItemSelected(g_CurrentSelect)
		
		OtherHuanLing_Pet_List:Flash()
		
		OtherHuanLing_Pet_List:SetElementsInView(g_CurrentSelect)		
		
		OtherHuanLing_UpdateLeftInfo()
	end
	
	
	
end

function OtherHuanLing_AddOtherHuanLingItem(index)
	
	local ItemBar = OtherHuanLing_Pet_List:AddItemElement( "OtherHuanLing_Head", "OtherHuanLing","" ,"")
	ItemBar:SetProperty("SuperBarButtonHover","SuperBarHoverSection")
	
	local bkImage 		= 	ItemBar:GetChildItem("OtherHuanLing","__auto_SuperBarImage1__")	
	local headImage		= 	ItemBar:GetChildItem("OtherHuanLing","__auto_SuperBarImage2__")
	local redImage 		= 	ItemBar:GetChildItem("OtherHuanLing","__auto_SuperBarImage3__")
	local grayImage 	= 	ItemBar:GetChildItem("OtherHuanLing","__auto_SuperBarImage4__")
	local inUseImage 	= 	ItemBar:GetChildItem("OtherHuanLing","__auto_SuperBarImage5__")	
	
	local nOtherHuanLingId = Pet:Lua_GetOtherrHuanLingInfoFromList(index,"Id")
	local nReqSavvy = Pet:Lua_GetOtherrHuanLingInfoFromList(index,"ReqSavvy")
	local nReqLing = Pet:Lua_GetOtherrHuanLingInfoFromList(index,"ReqLing")
	local nReqVLevel = Pet:Lua_GetOtherrHuanLingInfoFromList(index,"ReqVLevel")
	local nReqQuality = Pet:Lua_GetOtherrHuanLingInfoFromList(index,"Quality")
	local nOtherHuanLingName = Pet:Lua_GetOtherrHuanLingInfoFromList(index,"Name")
	local strQualText = Pet:Lua_GetOtherrHuanLingInfoFromList(index,"QualText")
	
	local strImage = Pet:Lua_GetOtherrHuanLingInfoFromList(index,"Icon")	
	headImage:SetProperty("Image", strImage)
	
	ItemBar:SetToolTip(tostring(nOtherHuanLingName)..tostring(strQualText))
	
	if Pet:Lua_IsHaveOtherHuanLingCollection(nOtherHuanLingId) ~= 1 then
		grayImage:Show()
		redImage:Hide()
		inUseImage:Hide()
	else
		grayImage:Hide()
		redImage:Hide()
		inUseImage:Hide()
	end
	
	table.insert(g_nContentButton,ItemBar)
end

function OtherHuanLing_OnItemClick()
	
	local sPos,ePos = string.find(arg0, "_auto_element")
	local nIndex = tonumber(string.sub(arg0, ePos + 1, -1)) + 1

	if nIndex > 0 then
		
		if g_CurrentSelect ~= nIndex then
		
			OtherHuanLing_SetItemSelected(nIndex)
			OtherHuanLing_Pet_List:Flash()
			g_CurrentSelect = nIndex
			
			OtherHuanLing_UpdateLeftInfo()
	
		end
	end

end

function OtherHuanLing_SetItemSelected(nIndex)
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

function OtherHuanLing_UpdateLeftInfo()
	
	local nOtherHuanLingId = Pet:Lua_GetOtherrHuanLingInfoFromList(g_CurrentSelect - 1,"Id")
	local nOtherHuanLingName = Pet:Lua_GetOtherrHuanLingInfoFromList(g_CurrentSelect - 1,"Name")
	local nReqSavvy = Pet:Lua_GetOtherrHuanLingInfoFromList(g_CurrentSelect - 1,"ReqSavvy")
	local nReqLing = Pet:Lua_GetOtherrHuanLingInfoFromList(g_CurrentSelect - 1,"ReqLing")
	local nReqVLevel = Pet:Lua_GetOtherrHuanLingInfoFromList(g_CurrentSelect - 1,"ReqVLevel")
	local nReqQuality = Pet:Lua_GetOtherrHuanLingInfoFromList(g_CurrentSelect - 1,"Quality")
	local strQualText = Pet:Lua_GetOtherrHuanLingInfoFromList(g_CurrentSelect - 1,"QualText")
	
	OtherHuanLing_PetName:SetText("#gFF0FA0"..nOtherHuanLingName)
	OtherHuanLing_PetText:SetText(strQualText)
	
	OtherHuanLing_FakeObject:SetFakeObject("")
	Pet:Lua_UpdateOhterHuanLingModel(nOtherHuanLingId)
	OtherHuanLing_FakeObject:SetFakeObject("OtherHuanLingPet")
	
	local strReqSavvy = ScriptGlobal_Format("#{CKHL_20230427_21}",tostring(nReqSavvy))
	OtherHuanLing_WuXinglevel_Text:SetText(strReqSavvy)
	
	local strReqLing = ScriptGlobal_Format("#{CKHL_20230427_21}",tostring(nReqLing))
	OtherHuanLing_LingXinglevel_Text:SetText(strReqLing)
	
	if nReqVLevel == 0 then
		OtherHuanLing_BianYilevel_Text:SetText("#{CKHL_20230427_20}")
	else
		local strReqVLevel = ScriptGlobal_Format("#{CKHL_20230427_21}",tostring(nReqVLevel))
		OtherHuanLing_BianYilevel_Text:SetText(strReqVLevel)
	end
	
	if g_ReqQualText[nReqQuality] then
		OtherHuanLing_Quality_Text:SetText(g_ReqQualText[nReqQuality])
	else
		OtherHuanLing_Quality_Text:SetText("")	
	end	

end

function OtherHuanLing_TurnLeft(start)
	--向左旋转开始
	if start == 1 and CEArg:GetValue("MouseButton")=="LeftButton" then
		OtherHuanLing_FakeObject:RotateBegin(-0.3);
	--向左旋转结束
	else
		OtherHuanLing_FakeObject:RotateEnd();
	end
end

function OtherHuanLing_TurnRight(start)
	--向右旋转开始
	if start == 1 and CEArg:GetValue("MouseButton")=="LeftButton" then
		OtherHuanLing_FakeObject:RotateBegin(0.3);
	--向右旋转结束
	else
		OtherHuanLing_FakeObject:RotateEnd();
	end
end

function OtherHuanLing_Close()

	this:Hide()

end

function OtherHuanLing_OnHidden()

	OtherHuanLing_Reset()
	this:Hide()
end

function OtherHuanLing_TargetEquip_Down()
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenEquipFrame("other");
end

function OtherHuanLing_TargetData_Down()
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("other")
end

function OtherHuanLing_TargetInfant_Switch()
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:Other_ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function OtherHuanLing_TargetWuhun_Switch()
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherWuhun();
end

function OtherHuanLing_TargetMiji_Down()
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherMiji();
	this:Hide()
end

function OtherHuanLing_ZhenYuan_Down()
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleTargetZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end

function OtherHuanLing_OtherJingMai_Down()
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherJingMai();
end

function OtherHuanLing_TargetShenDing_Down()
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	local nLevel = CachedTarget:GetData("LEVEL",1);
	if nLevel == nil or nLevel < 15 then
		PushDebugMessage( "#{XLDL_140606_63}" );
	else
		local bRet = SystemSetup:OpenOtherShenDing();
		if bRet == 1 then
			this:Hide()
		end
	end	
end

function OtherHuanLing_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage();
	if bRet == 1 then
		this:Hide()
	end
end

function OtherHuanLing_OpenBaoJian()
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
end

function OtherHuanLing_OpenWuYi()
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

function OtherHuanLing_OpenShenQi()
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

function OtherHuanLing_OtherRide_Down()
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenRidePage("other");
end

function OtherHuanLing_YuShou_Page_Switch()
	
	if Player:GetData("Is2606S") == 1 then
		return
	end
	
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1)
	local nLevel = CachedTarget:GetData("LEVEL",1)
	if nLevel == nil or nLevel < 85 then
		PushDebugMessage( "对方等级不足85，尚未开启御兽之道" )
		OtherHuanLing_Client_Button02:SetCheck(0)
	else
		local bRet = Lua_OpenOtherPetMasterPage(0)
		if bRet ~= 1 then
			OtherHuanLing_Client_Button02:SetCheck(0)
		end
	end
end

function OtherHuanLing_Armor_Page_Switch()

	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

function OtherHuanLing_Pet_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1)
	SystemSetup:OpenPetFrame("other")
end

function OtherHuanLing_NeiDan_Page_Switch()

	if Player:GetData("IsOriginalJD") == 1 then
		return
	end
	if Player:GetData("Is2606S") == 1 then
		return
	end
	
   	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1)
	Pet:LuaFnOpenPetNeiDan("other")
end

function OtherHuanLing_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherHuanLing_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end

function OtherHuanLing_ShowPage()

	for i = 1, table.getn(g_OtherHuanLing_Page) do
		g_OtherPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	OtherHuanLing_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_OtherPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_OtherHuanLing_Page) do
			if i ~= nOtherPageNumber then
				g_OtherPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_OtherPageOrder = {}
	g_OtherPageCount = 0
	for i = 1, table.getn(g_OtherHuanLing_Page) do
		if OtherHuanLing_CheckPage(i) == 1 then
			g_OtherPageCount = g_OtherPageCount + 1
			g_OtherPageButton[g_OtherPageCount]:Show()
			g_OtherPageButton[g_OtherPageCount]:SetText(g_OtherHuanLing_Page[i].Text)	
			g_OtherPageOrder[g_OtherPageCount] = i
		end
	end
	
end

function OtherHuanLing_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_OtherPageOrder[idx]
	
	if idx == 1 then--装备
		OtherHuanLing_TargetEquip_Down();
	elseif idx == 2 then--资料
		OtherHuanLing_TargetData_Down()
	elseif idx == 3 then--珍兽
		--OtherHuanLing_Pet_Switch()
	elseif idx == 4 then--子女
		OtherHuanLing_TargetInfant_Switch()
	elseif idx == 5 then--武魂
		OtherHuanLing_TargetWuhun_Switch()
	elseif idx == 6 then--秘籍
		OtherHuanLing_TargetMiji_Down()
	elseif idx == 7 then--真元
		OtherHuanLing_ZhenYuan_Down()
	elseif idx == 8 then--经脉
		OtherHuanLing_OtherJingMai_Down()
	elseif idx == 9 then--神鼎
		OtherHuanLing_TargetShenDing_Down()
	elseif idx == 10 then--侠印
		OtherHuanLing_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		OtherHuanLing_OpenBaoJian()
	elseif idx == 12 then--武意
		OtherHuanLing_OpenWuYi()
	elseif idx == 13 then--神器
		OtherHuanLing_OpenShenQi()
	elseif idx == 14 then--星盘
		OtherHuanLing_Armor_Page_Switch()
	elseif idx == 15 then--名物
		OtherHuanLing_CangPin_Page_Switch()
	end
end

function OtherHuanLing_CheckPage(idx)
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

function OtherHuanLing_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end
