
local CTRL_NUM = 11
local CTRL = {};

local SELFDATA_TAB_TEXT = {};

local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;

local g_TargetData_Frame_UnifiedPosition;

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_TargetData_Page = {
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
function TargetData_PreLoad()
	this:RegisterEvent("OPEN_PRIVATE_INFO",true);
	this:RegisterEvent("UPDATE_PRIVATE_INFO",false);
	this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

end

function TargetData_OnLoad()
	--生肖
	TargetData_YearAnimal:ComboBoxAddItem("-",0);
	TargetData_YearAnimal:ComboBoxAddItem("鼠",1);
	TargetData_YearAnimal:ComboBoxAddItem("牛",2);
	TargetData_YearAnimal:ComboBoxAddItem("虎",3);
	TargetData_YearAnimal:ComboBoxAddItem("兔",4);
	TargetData_YearAnimal:ComboBoxAddItem("龙",5);
	TargetData_YearAnimal:ComboBoxAddItem("蛇",6);
	TargetData_YearAnimal:ComboBoxAddItem("马",7);
	TargetData_YearAnimal:ComboBoxAddItem("羊",8);
	TargetData_YearAnimal:ComboBoxAddItem("猴",9);
	TargetData_YearAnimal:ComboBoxAddItem("鸡",10);
	TargetData_YearAnimal:ComboBoxAddItem("狗",11);
	TargetData_YearAnimal:ComboBoxAddItem("猪",12);

	--省份
	TargetData_Province:ComboBoxAddItem("-",		 0);
	TargetData_Province:ComboBoxAddItem("北京",  1);
	TargetData_Province:ComboBoxAddItem("天津",  2);
	TargetData_Province:ComboBoxAddItem("上海",  3);
	TargetData_Province:ComboBoxAddItem("重庆",  4);
	TargetData_Province:ComboBoxAddItem("河北",  5);
	TargetData_Province:ComboBoxAddItem("辽宁",  6);
	TargetData_Province:ComboBoxAddItem("山东",  7);
	TargetData_Province:ComboBoxAddItem("黑龙江",8);
	TargetData_Province:ComboBoxAddItem("山西",  9);
	TargetData_Province:ComboBoxAddItem("吉林",  10);
	TargetData_Province:ComboBoxAddItem("陕西",  11);
	TargetData_Province:ComboBoxAddItem("河南",  12);
	TargetData_Province:ComboBoxAddItem("安徽",  13);
	TargetData_Province:ComboBoxAddItem("江苏",  14);
	TargetData_Province:ComboBoxAddItem("湖北",  15);
	TargetData_Province:ComboBoxAddItem("浙江",  16);
	TargetData_Province:ComboBoxAddItem("湖南",  17);
	TargetData_Province:ComboBoxAddItem("江西",  18);
	TargetData_Province:ComboBoxAddItem("福建",  19);
	TargetData_Province:ComboBoxAddItem("台湾",  20);
	TargetData_Province:ComboBoxAddItem("内蒙古",21);
	TargetData_Province:ComboBoxAddItem("甘肃",  22);
	TargetData_Province:ComboBoxAddItem("宁夏",  23);
	TargetData_Province:ComboBoxAddItem("四川",  24);
	TargetData_Province:ComboBoxAddItem("贵州",  25);
	TargetData_Province:ComboBoxAddItem("云南",  26);
	TargetData_Province:ComboBoxAddItem("广西",  27);
	TargetData_Province:ComboBoxAddItem("广东",  28);
	TargetData_Province:ComboBoxAddItem("海南",  29);
	TargetData_Province:ComboBoxAddItem("新疆",  30);
	TargetData_Province:ComboBoxAddItem("青海",  31);
	TargetData_Province:ComboBoxAddItem("西藏",  32);
	TargetData_Province:ComboBoxAddItem("澳门",  33);
	TargetData_Province:ComboBoxAddItem("香港",  34);
	TargetData_Province:ComboBoxAddItem("其他",  35);

	 --澳门  香港 和其他

	--性别
	TargetData_Sex:ComboBoxAddItem("-",0);
	TargetData_Sex:ComboBoxAddItem("男",1);
	TargetData_Sex:ComboBoxAddItem("女",2);

	--血型
	TargetData_BloodType:ComboBoxAddItem("-",0);
	TargetData_BloodType:ComboBoxAddItem("A",1);
	TargetData_BloodType:ComboBoxAddItem("B",2);
	TargetData_BloodType:ComboBoxAddItem("AB",3);
	TargetData_BloodType:ComboBoxAddItem("O",4);


	--星座
	TargetData_Constellation:ComboBoxAddItem("-",0);
	TargetData_Constellation:ComboBoxAddItem("魔羯座",1);
	TargetData_Constellation:ComboBoxAddItem("水瓶座",2);
	TargetData_Constellation:ComboBoxAddItem("双鱼座",3);
	TargetData_Constellation:ComboBoxAddItem("白羊座",4);
	TargetData_Constellation:ComboBoxAddItem("金牛座",5);
	TargetData_Constellation:ComboBoxAddItem("双子座",6);
	TargetData_Constellation:ComboBoxAddItem("巨蟹座",7);
	TargetData_Constellation:ComboBoxAddItem("狮子座",8);
	TargetData_Constellation:ComboBoxAddItem("处女座",9);
	TargetData_Constellation:ComboBoxAddItem("天秤座",10);
	TargetData_Constellation:ComboBoxAddItem("天蝎座",11);
	TargetData_Constellation:ComboBoxAddItem("射手座",12);

	CTRL[1] = TargetData_Age;
	CTRL[2] = TargetData_Sex;
	CTRL[3] = TargetData_Job;
	CTRL[4] = TargetData_School;
	CTRL[5] = TargetData_BloodType;
	CTRL[6] = TargetData_YearAnimal;
	CTRL[7] = TargetData_Constellation;
	CTRL[8] = TargetData_Province;
	CTRL[9] = TargetData_City;
	CTRL[10] = TargetData_EMail;
	CTRL[11] = TargetData_MessageBoard;

	SELFDATA_TAB_TEXT = {
		[0] = "装备",
		"资料",
		"秘籍",
		"珍兽",
		"骑乘",
		"经脉",
	};

	--屏蔽玩家资料页签中“电子邮件相关内容”，TT62640
	TargetData_EMail_Text:Hide();
	TargetData_EMail:Hide();

	 g_TargetData_Frame_UnifiedPosition=TargetData_Frame:GetProperty("UnifiedPosition");
	 
	g_TargetPageButton[1] = TargetData_SelfEquip
	g_TargetPageButton[2] = TargetData_TargetData
	g_TargetPageButton[3] = TargetData_Pet
	g_TargetPageButton[4] = TargetData_TargetInfant
	g_TargetPageButton[5] = TargetData_TargetWuhun
	g_TargetPageButton[6] = TargetData_Miji
	g_TargetPageButton[7] = TargetData_ZhenYuan
	g_TargetPageButton[8] = TargetData_JingMai
	g_TargetPageButton[9] = TargetData_ShenDing
	g_TargetPageButton[10] = TargetData_JueWei
	g_TargetPageButton[11] = TargetData_BaoJian
	g_TargetPageButton[12] = TargetData_WuYi
	g_TargetPageButton[13] = TargetData_ShenQi
	g_TargetPageButton[14] = TargetData_Armor
	g_TargetPageButton[15] = TargetData_CangPin
	
end

function TargetData_SetTabColor(idx)

	local i = 0;
	local selColor = "#e010101#Y";
	local noselColor = "#e010101";
	local tab = {
								[0] = TargetData_SelfEquip,
								TargetData_TargetData,
								TargetData_Miji,
								TargetData_Pet,
								TargetData_Ride,
								TargetData_JingMai,
							};

	while i < 6 do
		if(i == idx) then
			tab[i]:SetText(selColor..SELFDATA_TAB_TEXT[i]);
		else
			tab[i]:SetText(noselColor..SELFDATA_TAB_TEXT[i]);
		end
		i = i + 1;
	end
end
--===============================================
-- OnEvent()
--===============================================
function TargetData_OnEvent(event)
	if ( event == "OPEN_PRIVATE_INFO" ) then
		if(arg0 ~= "other")     then
			return;
		end
		local obj_id = CachedTarget:GetData("NPCID", 1)
		if (type(obj_id) ~="number") then
			PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
			return
		end
		this:CareObject(obj_id , 1)

		this:Show();
		TargetData_SetTabColor(1);
		TargetData_SelfEquip:SetCheck(0);
		TargetData_TargetData:SetCheck(1);

		local otherUnionPos = Variable:GetVariable("OtherUnionPos");
		if(otherUnionPos ~= nil) then
			TargetData_Frame:SetProperty("UnifiedPosition", otherUnionPos);
		end

		TargetData_UpdateFrame("other");
		for i=1 ,CTRL_NUM -1   do
			CTRL[i]:Disable();
		end
		
		TargetData_ShowPage()
		
	elseif (event == "OBJECT_CARED_EVENT") then

		if(tonumber(arg0) ~= objCared) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1=="destroy") then
			g_InitiativeClose = 1;
			this:Hide();

			--取消关心
			this:CareObject(objCared, 0, "SelfData");
		end

	elseif (event == "ADJEST_UI_POS" ) then
		TargetData_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TargetData_Frame_On_ResetPos()

	end
end

--===============================================
-- UpdateFrame()
--===============================================
function TargetData_UpdateFrame(whose)

	--标题显示玩家的名字
	local szName = SystemSetup:GetPrivateInfo(whose,"name");
 	TargetData_PageHeader:SetText("#gFF0FA0"..szName);

	local szGuid = SystemSetup:GetPrivateInfo(whose,"guid");
	local szGuidText = ConvertGuidToShow(szGuid)
	TargetData_ID:SetText("ID:".. szGuidText);

	local nAge = SystemSetup:GetPrivateInfo(whose,"age");
	TargetData_Age:SetText(tostring(nAge));

	local nSex = SystemSetup:GetPrivateInfo(whose,"sex");
	TargetData_Sex:SetCurrentSelect(nSex);

	local szJob = SystemSetup:GetPrivateInfo(whose,"job");
	TargetData_Job:SetText(szJob);

	local szSchool = SystemSetup:GetPrivateInfo(whose,"school");
	TargetData_School:SetText(szSchool);

	local nBlood = SystemSetup:GetPrivateInfo(whose,"blood");
	TargetData_BloodType:SetCurrentSelect(nBlood);

	local nAnimal = SystemSetup:GetPrivateInfo(whose,"animal");
	TargetData_YearAnimal:SetCurrentSelect(nAnimal);

	local nConsella = SystemSetup:GetPrivateInfo(whose,"Consella");
	TargetData_Constellation:SetCurrentSelect(nConsella);

	local nProvince = SystemSetup:GetPrivateInfo(whose,"Province");
	TargetData_Province:SetCurrentSelect(nProvince);

	local szCity = SystemSetup:GetPrivateInfo(whose,"city");
	TargetData_City:SetText(szCity);

	local szEmail = SystemSetup:GetPrivateInfo(whose,"email");
	TargetData_EMail:SetText(szEmail);

	local szLuck = SystemSetup:GetPrivateInfo(whose,"luck");
	TargetData_MessageBoard:SetText(szLuck);
end

--===============================================
-- 打开
--===============================================
function TargetData_TargetEquip_Down()
	Variable:SetVariable("OtherUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenEquipFrame("other");
	this:CareObject(objCared, 0, "SelfData");
end

--===============================================
-- 打开
--===============================================
function TargetData_OtherPet_Down()

	Variable:SetVariable("OtherUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPetFrame("other");

end

--===============================================
-- OnHiden
--===============================================
function TargetData_Frame_OnHiden()
	TargetData_Job:SetProperty("DefaultEditBox", "False");
	TargetData_School:SetProperty("DefaultEditBox", "False");
	TargetData_City:SetProperty("DefaultEditBox", "False");
	TargetData_EMail:SetProperty("DefaultEditBox", "False");
	TargetData_Age:SetProperty("DefaultEditBox", "False");
	TargetData_MessageBoard:SetProperty("DefaultEditBox", "False");
end


function TargetData_Ride_Switch()
	Variable:SetVariable("SelfUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1);
	OpenRidePage();

end

function TargetData_Other_Info_Page_Switch()
	Variable:SetVariable("SelfUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1);
	OtherInfoPage();
end

--神木王鼎
function TargetData_TargetShenDing_Down()
	Variable:SetVariable("OtherUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1);
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

function TargetData_OtherRide_Down()
	Variable:SetVariable("OtherUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenRidePage("other");
end

--武魂

function TargetData_TargetWuhun_Switch()
	Variable:SetVariable("OtherUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherWuhun();
end

--经脉
function TargetData_OtherJingMai_Down()
	Variable:SetVariable("OtherUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherJingMai();
end

function TargetData_Frame_On_ResetPos()
  TargetData_Frame:SetProperty("UnifiedPosition", g_TargetData_Frame_UnifiedPosition);
end

function TargetData_ZhenYuan_Down()
	Variable:SetVariable("OtherUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleTargetZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetData_TargetMiji_Down()
	Variable:SetVariable("OtherUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherMiji();
	this:Hide()
end

function TargetData_TargetInfant_Switch()
	Variable:SetVariable("OtherUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:Other_ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetData_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetData_OpenBaoJian()
	Variable:SetVariable("OtherUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
end

function TargetData_OpenWuYi()
	Variable:SetVariable("OtherUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

function TargetData_OpenShenQi()
	Variable:SetVariable("OtherUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

function TargetData_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

function TargetData_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetData_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end


function TargetData_ShowPage()

	for i = 1, table.getn(g_TargetData_Page) do
		g_TargetPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	TargetData_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_TargetPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_TargetData_Page) do
			if i ~= nOtherPageNumber then
				g_TargetPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_TargetPageOrder = {}
	g_TargetPageCount = 0
	for i = 1, table.getn(g_TargetData_Page) do
		if TargetData_CheckPage(i) == 1 then
			g_TargetPageCount = g_TargetPageCount + 1
			g_TargetPageButton[g_TargetPageCount]:Show()
			g_TargetPageButton[g_TargetPageCount]:SetText(g_TargetData_Page[i].Text)	
			g_TargetPageOrder[g_TargetPageCount] = i
		end
	end
	
end

function TargetData_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_TargetPageOrder[idx]
	
	if idx == 1 then--装备
		TargetData_TargetEquip_Down(0);
	elseif idx == 2 then--资料
		--TargetWuhun_OtherData_Page_Switch()
	elseif idx == 3 then--珍兽
		TargetData_OtherPet_Down()
	elseif idx == 4 then--子女
		TargetData_TargetInfant_Switch()
	elseif idx == 5 then--武魂
		TargetData_TargetWuhun_Switch()
	elseif idx == 6 then--秘籍
		TargetData_TargetMiji_Down()
	elseif idx == 7 then--真元
		TargetData_ZhenYuan_Down()
	elseif idx == 8 then--经脉
		TargetData_OtherJingMai_Down()
	elseif idx == 9 then--神鼎
		TargetData_TargetShenDing_Down()
	elseif idx == 10 then--侠印
		TargetData_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		TargetData_OpenBaoJian()
	elseif idx == 12 then--武意
		TargetData_OpenWuYi()
	elseif idx == 13 then--神器
		TargetData_OpenShenQi()
	elseif idx == 14 then--星盘
		TargetData_Armor_Page_Switch()
	elseif idx == 15 then--名物
		TargetData_CangPin_Page_Switch()
	end
end

function TargetData_CheckPage(idx)
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

function TargetData_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end


