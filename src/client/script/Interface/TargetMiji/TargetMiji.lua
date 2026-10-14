
local g_OTHER_COMBO_BOOK = {}
local g_OTHER_BOOK_NAME = {}
local g_OTHER_COMBO_BOOK_TEXT = {}
local g_BOOK_EMPTY_TEST = {}
local g_OtherRate_Skill = {}
local g_SKILL_ACTION = {}

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_TargetMiji_Page = {
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

local g_TargetMiji_Frame_UnifiedPosition = nil;
function TargetMiji_PreLoad()
	this:RegisterEvent("OPEN_OTHERPLAYER_MIJI")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	this:RegisterEvent("ADJEST_UI_POS",false);
end

function TargetMiji_OnLoad()

	g_TargetMiji_Frame_UnifiedPosition = TargetMiji_Frame:GetProperty("UnifiedPosition")
	g_OTHER_COMBO_BOOK[1] = TargetMiji_Miji1_Skill
	g_OTHER_COMBO_BOOK[2] = TargetMiji_Miji2_Skill
	g_OTHER_COMBO_BOOK[3] = TargetMiji_Miji3_Skill

	g_OTHER_BOOK_NAME[1] = TargetMiji_Miji1_name
	g_OTHER_BOOK_NAME[2] = TargetMiji_Miji2_name
	g_OTHER_BOOK_NAME[3] = TargetMiji_Miji3_name

	g_OTHER_COMBO_BOOK_TEXT[1] = TargetMiji_Miji1_level
	g_OTHER_COMBO_BOOK_TEXT[2] = TargetMiji_Miji2_level
	g_OTHER_COMBO_BOOK_TEXT[3] = TargetMiji_Miji3_level

	g_BOOK_EMPTY_TEST[1] = TargetMiji_Miji1_text
	g_BOOK_EMPTY_TEST[2] = TargetMiji_Miji2_text
	g_BOOK_EMPTY_TEST[3] = TargetMiji_Miji3_text

	g_OtherRate_Skill[1] = TargetMiji_InfoFrame_pro1to2
	g_OtherRate_Skill[2] = TargetMiji_InfoFrame_pro2to3

	g_SKILL_ACTION[1] = TargetMiji_InfoFrame_Icon1
	g_SKILL_ACTION[2] = TargetMiji_InfoFrame_Icon2
	g_SKILL_ACTION[3] = TargetMiji_InfoFrame_Icon3
	
	g_TargetPageButton[1] = TargetMiji_Equip
	g_TargetPageButton[2] = TargetMiji_Data
	g_TargetPageButton[3] = TargetMiji_Pet
	g_TargetPageButton[4] = TargetMiji_TargetInfant
	g_TargetPageButton[5] = TargetMiji_Wuhun
	g_TargetPageButton[6] = TargetMiji_Miji
	g_TargetPageButton[7] = TargetMiji_ZhenYuan
	g_TargetPageButton[8] = TargetMiji_JingMai
	g_TargetPageButton[9] = TargetMiji_ShenDing
	g_TargetPageButton[10] = TargetMiji_JueWei
	g_TargetPageButton[11] = TargetMiji_BaoJian
	g_TargetPageButton[12] = TargetMiji_WuYi
	g_TargetPageButton[13] = TargetMiji_ShenQi
	g_TargetPageButton[14] = TargetMiji_Armor
	g_TargetPageButton[15] = TargetMiji_CangPin
	
end


function TargetMiji_OnEvent(event)

	if (event == "OPEN_OTHERPLAYER_MIJI") then
		if(this:IsVisible()) then
			this:Hide();
			return;
		end

		local obj_id = CachedTarget:GetData("NPCID", 1)
		if (type(obj_id) ~="number") then
			PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
			return
		end
		this:CareObject(obj_id , 1)
		TargetMiji_CleanAll()
		 for i = 1, 3 do
			 local theAction = EnumAction(i - 1, "othercombobook")
			 if (theAction:GetID() ~= 0 ) then
				g_OTHER_COMBO_BOOK[i] : SetActionItem(theAction:GetID())
				TargetMiji_Updata_Book(i-1);
			 else
				g_BOOK_EMPTY_TEST[i]:SetText("#{WLMJ_130121_12}")
			 end
		 end

		TargetMiji_Miji:SetCheck(1)
		local OtherUnionPos = Variable:GetVariable("OtherUnionPos");
	    if(OtherUnionPos ~= nil) then
		    TargetMiji_Frame:SetProperty("UnifiedPosition", OtherUnionPos);
    	end

		TargetMiji_ShowPage()
		
		this:Show();
	elseif(event == "ADJEST_UI_POS") then
		TargetMiji_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		TargetMiji_ResetPos()
	end

end

function TargetMiji_CleanAll()
	for i =1,3 do
		g_OTHER_COMBO_BOOK[i]:SetActionItem(-1);
		g_OTHER_COMBO_BOOK_TEXT[i]:SetText("")
		g_SKILL_ACTION[i]:SetActionItem(-1)
		g_OTHER_BOOK_NAME[i]:SetText("")
		g_BOOK_EMPTY_TEST[i]:SetText("")
	end
	TargetMiji_InfoFrame_detailtext:ClearAllElement()
	TargetMiji_InfoFrame_detailtext:AddTextElement("#{WLMJ_130121_20}")
	g_OtherRate_Skill[1]:SetText("#{WLMJ_130121_19}".."#{WLMJ_130121_29}")
	g_OtherRate_Skill[2]:SetText("#{WLMJ_130121_19}".."#{WLMJ_130121_29}")

end

function TargetMiji_AskDeleteBook(Index)

end
function TargetMiji_ResetPos()
	TargetMiji_Frame:SetProperty("UnifiedPosition",g_TargetMiji_Frame_UnifiedPosition)
end

function TargetMiji_GetXiuWeiLevel(xiuweivalue)
	if xiuweivalue >= 0 and xiuweivalue < 300000 then
		return "#{WLMJ_130121_59}"
	elseif xiuweivalue >= 300000 and xiuweivalue < 600000 then
		return "#{WLMJ_130121_60}"
	elseif xiuweivalue >= 600000 and xiuweivalue < 900000 then
		return "#{WLMJ_130121_61}"
	elseif xiuweivalue >= 900000 and xiuweivalue < 1200000 then
		return "#{WLMJ_130121_62}"
	elseif xiuweivalue >= 1200000 and xiuweivalue < 1600000 then
		return "#{WLMJ_130121_63}"
	elseif xiuweivalue >= 1600000 and xiuweivalue < 2000000 then
		return "#{WLMJ_130121_64}"
	elseif xiuweivalue >= 2000000 and xiuweivalue < 2400000 then
		return "#{WLMJ_130121_65}"
	elseif xiuweivalue >= 2400000 and xiuweivalue < 2900000 then
		return "#{WLMJ_130121_66}"
	elseif xiuweivalue >= 2900000 and xiuweivalue < 3400000 then
		return "#{WLMJ_130121_67}"
	elseif xiuweivalue >= 3400000 and xiuweivalue < 3900000 then
		return "#{WLMJ_130121_68}"
	elseif xiuweivalue >= 3900000 and xiuweivalue < 4400000 then
		return "#{WLMJ_130121_69}"
	else
		return "#{WLMJ_130121_69}"
	end
end
function TargetMiji_Updata_Book(Index)
	TargetMiji_InfoFrame_detailtext:ClearAllElement()
	local theAction = EnumAction(Index, "othercombobook")
	if(theAction:GetID() ~= 0 ) then
		local skill1, skill2, skill3 = Player:GetOtherComboBookInfo(Index, "comboskill");
		local rate1, rate2 = Player:GetOtherComboBookInfo(Index, "rate");
		local bookname = Player:GetOtherComboBookInfo(Index, "bookname");
		local nLevel = Player:GetOtherComboBookInfo(Index, "level");
		g_OTHER_BOOK_NAME[Index+1]:SetText("#cfff263"..bookname)
		g_OTHER_COMBO_BOOK_TEXT[Index+1]:SetText("#{WLMJ_130121_13}"..nLevel)
		local rate1str = string.format("%d",rate1/100);
		local rate2str = string.format("%d",rate2/100);
		g_OtherRate_Skill[1]:SetText("#{WLMJ_130121_19}"..rate1str.."%")
		g_OtherRate_Skill[2]:SetText("#{WLMJ_130121_19}"..rate2str.."%")
		local nSumSkill = GetActionNum("skill");
		-- for i = 1, nSumSkill do
			-- local thetempAction = EnumAction(i, "othercomboskill");
			local thetempAction1 = EnumAction(skill1, "othercomboskill")
			if thetempAction1 ~=nil and thetempAction1:GetID() > 0 then
				TargetMiji_InfoFrame_Icon1 : SetActionItem(thetempAction1 : GetID())
			end
			local thetempAction2 = EnumAction(skill2, "othercomboskill")
			if thetempAction2 ~=nil and thetempAction2:GetID() > 0 then
				TargetMiji_InfoFrame_Icon2 : SetActionItem(thetempAction2 : GetID())
			end
			local thetempAction3 = EnumAction(skill3, "othercomboskill")
			if thetempAction3 ~=nil and thetempAction3:GetID() > 0 then
				TargetMiji_InfoFrame_Icon3 : SetActionItem(thetempAction3 : GetID())
			end
			local bookdesc = Player:GetOtherComboBookInfo(Index, "bookdesc");
			TargetMiji_InfoFrame_detailtext:AddTextElement(bookdesc);
			TargetMiji_SetSelectState(Index+1)
	else
		TargetMiji_InfoFrame_detailtext:AddTextElement("#{WLMJ_130121_20}")
	end
end

function TargetMiji_SetSelectState(Index)
	for i=1, 3 do
		if( i == Index) then
			g_OTHER_COMBO_BOOK[i]:SetPushed(1)
		else
			g_OTHER_COMBO_BOOK[i]:SetPushed(0)
		end
	end
end

function TargetMiji_Updata_All_Book()

end

function TargetMiji_Updata_All_BookLevel()

end

function TargetMiji_Book_Clicked(Index)
	local theAction = EnumAction(Index, "othercombobook")
	if ( theAction ~= nil and theAction:GetID() > 0 ) then
		TargetMiji_Updata_Book(Index)
	end
end

function TargetMiji_Close()
	this:Hide()
end

--***************************************************************
--装备
function TargetMiji_OtherEquip_Down()
	Variable:SetVariable("OtherUnionPos", TargetMiji_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenEquipFrame("other");
	TargetMiji_Close()
end

-- 资料
--
function TargetMiji_TargetData_Down()
	Variable:SetVariable("OtherUnionPos", TargetMiji_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("other")
	TargetMiji_Close()
end

--
-- 珍兽
--
function TargetMiji_OtherPet_Down()
	Variable:SetVariable("OtherUnionPos", TargetMiji_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPetFrame("other");
	TargetMiji_Close()
end

--神木王鼎
function TargetMiji_TargetShenDing_Down()
	Variable:SetVariable("OtherUnionPos", TargetMiji_Frame:GetProperty("UnifiedPosition"), 1);
	local nLevel = CachedTarget:GetData("LEVEL",1);
	if nLevel == nil or nLevel < 15 then
		PushDebugMessage( "#{XLDL_140606_63}" );
	else
		local bRet = SystemSetup:OpenOtherShenDing();
		if bRet == 1 then
			TargetMiji_Close()
		end
	end	
	
end

--
-- 骑乘
--
function TargetMiji_OtherRide_Down()
	Variable:SetVariable("OtherUnionPos", TargetMiji_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenRidePage("other");
	TargetMiji_Close()
end

--武魂

function TargetMiji_TargetWuhun_Switch()
	Variable:SetVariable("OtherUnionPos", TargetMiji_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherWuhun();
	TargetMiji_Close()
end

--经脉
function TargetMiji_OtherJingMai_Down()
	Variable:SetVariable("OtherUnionPos", TargetMiji_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherJingMai();
	TargetMiji_Close()
end

function TargetMiji_ZhenYuan_Down()
	Variable:SetVariable("OtherUnionPos", TargetMiji_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleTargetZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end


function TargetMiji_TargetInfant_Switch()
	Variable:SetVariable("OtherUnionPos", TargetMiji_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:Other_ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetMiji_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetMiji_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetMiji_OpenBaoJian()
	Variable:SetVariable("OtherUnionPos", TargetMiji_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
	TargetMiji_Close()
end

function TargetMiji_OpenWuYi()
	Variable:SetVariable("OtherUnionPos", TargetMiji_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

function TargetMiji_OpenShenQi()
	Variable:SetVariable("OtherUnionPos", TargetMiji_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

function TargetMiji_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetMiji_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

function TargetMiji_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetMiji_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end

function TargetMiji_ShowPage()

	for i = 1, table.getn(g_TargetMiji_Page) do
		g_TargetPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	TargetMiji_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_TargetPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_TargetMiji_Page) do
			if i ~= nOtherPageNumber then
				g_TargetPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_TargetPageOrder = {}
	g_TargetPageCount = 0
	for i = 1, table.getn(g_TargetMiji_Page) do
		if TargetMiji_CheckPage(i) == 1 then
			g_TargetPageCount = g_TargetPageCount + 1
			g_TargetPageButton[g_TargetPageCount]:Show()
			g_TargetPageButton[g_TargetPageCount]:SetText(g_TargetMiji_Page[i].Text)	
			g_TargetPageOrder[g_TargetPageCount] = i
		end
	end
	
end

function TargetMiji_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_TargetPageOrder[idx]
	
	if idx == 1 then--装备
		TargetMiji_OtherEquip_Down();
	elseif idx == 2 then--资料
		TargetMiji_TargetData_Down()
	elseif idx == 3 then--珍兽
		TargetMiji_OtherPet_Down()
	elseif idx == 4 then--子女
		TargetMiji_TargetInfant_Switch()
	elseif idx == 5 then--武魂
		TargetMiji_TargetWuhun_Switch()
	elseif idx == 6 then--秘籍
		--TargetWuhun_TargetMiji_Down()
	elseif idx == 7 then--真元
		TargetMiji_ZhenYuan_Down()
	elseif idx == 8 then--经脉
		TargetMiji_OtherJingMai_Down()
	elseif idx == 9 then--神鼎
		TargetMiji_TargetShenDing_Down()
	elseif idx == 10 then--侠印
		TargetMiji_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		TargetMiji_OpenBaoJian()
	elseif idx == 12 then--武意
		TargetMiji_OpenWuYi()
	elseif idx == 13 then--神器
		TargetMiji_OpenShenQi()
	elseif idx == 14 then--星盘
		TargetMiji_Armor_Page_Switch()
	elseif idx == 15 then--名物
		TargetMiji_CangPin_Page_Switch()
	end
end

function TargetMiji_CheckPage(idx)
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

function TargetMiji_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end


