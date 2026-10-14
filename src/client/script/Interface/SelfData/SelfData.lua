
local CTRL_NUM = 11
local CTRL = {};

local SELF_PAGE  = 0;
local OTHER_PAGE = 1;
local g_Current_Page;
local SELFDATA_TAB_TEXT = {};

local objCared = -1;
local MAX_OBJ_DISTANCE = 3.0;

-- 界面的默认相对位置
local g_SelfData_Frame_UnifiedXPosition;
local g_SelfData_Frame_UnifiedYPosition;

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_SelfData_Page = {
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

local g_SelfData_PageButton = {}
local g_SelfData_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

--===============================================
-- OnLoad()
--===============================================
function SelfData_PreLoad()
	this:RegisterEvent("OPEN_PRIVATE_INFO",true);
	this:RegisterEvent("UPDATE_PRIVATE_INFO",false);
	this:RegisterEvent("OBJECT_CARED_EVENT",false);

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK",false);		--升级

	this:RegisterEvent("TOGGLE_UPDATE_INFANT",false); --子女有变化 刷新按钮状态

	this:RegisterEvent("FINISH_MISSION",false);
	this:RegisterEvent("MARTIAL_UPDATE",false)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)
end

function SelfData_OnLoad()
	--生肖
	SelfData_YearAnimal:ComboBoxAddItem("-",0);
	SelfData_YearAnimal:ComboBoxAddItem("鼠",1);
	SelfData_YearAnimal:ComboBoxAddItem("牛",2);
	SelfData_YearAnimal:ComboBoxAddItem("虎",3);
	SelfData_YearAnimal:ComboBoxAddItem("兔",4);
	SelfData_YearAnimal:ComboBoxAddItem("龙",5);
	SelfData_YearAnimal:ComboBoxAddItem("蛇",6);
	SelfData_YearAnimal:ComboBoxAddItem("马",7);
	SelfData_YearAnimal:ComboBoxAddItem("羊",8);
	SelfData_YearAnimal:ComboBoxAddItem("猴",9);
	SelfData_YearAnimal:ComboBoxAddItem("鸡",10);
	SelfData_YearAnimal:ComboBoxAddItem("狗",11);
	SelfData_YearAnimal:ComboBoxAddItem("猪",12);

	--省份
	SelfData_Province:ComboBoxAddItem("-",		 0);
	SelfData_Province:ComboBoxAddItem("北京",  1);
	SelfData_Province:ComboBoxAddItem("天津",  2);
	SelfData_Province:ComboBoxAddItem("上海",  3);
	SelfData_Province:ComboBoxAddItem("重庆",  4);
	SelfData_Province:ComboBoxAddItem("河北",  5);
	SelfData_Province:ComboBoxAddItem("辽宁",  6);
	SelfData_Province:ComboBoxAddItem("山东",  7);
	SelfData_Province:ComboBoxAddItem("黑龙江",8);
	SelfData_Province:ComboBoxAddItem("山西",  9);
	SelfData_Province:ComboBoxAddItem("吉林",  10);
	SelfData_Province:ComboBoxAddItem("陕西",  11);
	SelfData_Province:ComboBoxAddItem("河南",  12);
	SelfData_Province:ComboBoxAddItem("安徽",  13);
	SelfData_Province:ComboBoxAddItem("江苏",  14);
	SelfData_Province:ComboBoxAddItem("湖北",  15);
	SelfData_Province:ComboBoxAddItem("浙江",  16);
	SelfData_Province:ComboBoxAddItem("湖南",  17);
	SelfData_Province:ComboBoxAddItem("江西",  18);
	SelfData_Province:ComboBoxAddItem("福建",  19);
	SelfData_Province:ComboBoxAddItem("台湾",  20);
	SelfData_Province:ComboBoxAddItem("内蒙古",21);
	SelfData_Province:ComboBoxAddItem("甘肃",  22);
	SelfData_Province:ComboBoxAddItem("宁夏",  23);
	SelfData_Province:ComboBoxAddItem("四川",  24);
	SelfData_Province:ComboBoxAddItem("贵州",  25);
	SelfData_Province:ComboBoxAddItem("云南",  26);
	SelfData_Province:ComboBoxAddItem("广西",  27);
	SelfData_Province:ComboBoxAddItem("广东",  28);
	SelfData_Province:ComboBoxAddItem("海南",  29);
	SelfData_Province:ComboBoxAddItem("新疆",  30);
	SelfData_Province:ComboBoxAddItem("青海",  31);
	SelfData_Province:ComboBoxAddItem("西藏",  32);
	SelfData_Province:ComboBoxAddItem("澳门",  33);
	SelfData_Province:ComboBoxAddItem("香港",  34);
	SelfData_Province:ComboBoxAddItem("其他",  35);

	 --澳门  香港 和其他

	--性别
	SelfData_Sex:ComboBoxAddItem("-",0);
	SelfData_Sex:ComboBoxAddItem("男",1);
	SelfData_Sex:ComboBoxAddItem("女",2);

	--血型
	SelfData_BloodType:ComboBoxAddItem("-",0);
	SelfData_BloodType:ComboBoxAddItem("A",1);
	SelfData_BloodType:ComboBoxAddItem("B",2);
	SelfData_BloodType:ComboBoxAddItem("AB",3);
	SelfData_BloodType:ComboBoxAddItem("O",4);


	--星座
	SelfData_Constellation:ComboBoxAddItem("-",0);
	SelfData_Constellation:ComboBoxAddItem("魔羯座",1);
	SelfData_Constellation:ComboBoxAddItem("水瓶座",2);
	SelfData_Constellation:ComboBoxAddItem("双鱼座",3);
	SelfData_Constellation:ComboBoxAddItem("白羊座",4);
	SelfData_Constellation:ComboBoxAddItem("金牛座",5);
	SelfData_Constellation:ComboBoxAddItem("双子座",6);
	SelfData_Constellation:ComboBoxAddItem("巨蟹座",7);
	SelfData_Constellation:ComboBoxAddItem("狮子座",8);
	SelfData_Constellation:ComboBoxAddItem("处女座",9);
	SelfData_Constellation:ComboBoxAddItem("天秤座",10);
	SelfData_Constellation:ComboBoxAddItem("天蝎座",11);
	SelfData_Constellation:ComboBoxAddItem("射手座",12);

	CTRL[1] = SelfData_Age;
	CTRL[2] = SelfData_Sex;
	CTRL[3] = SelfData_Job;
	CTRL[4] = SelfData_School;
	CTRL[5] = SelfData_BloodType;
	CTRL[6] = SelfData_YearAnimal;
	CTRL[7] = SelfData_Constellation;
	CTRL[8] = SelfData_Province;
	CTRL[9] = SelfData_City;
	CTRL[10] = SelfData_EMail;
	CTRL[11] = SelfData_MessageBoard;

	SELFDATA_TAB_TEXT = {
		[0] = "装备",
		"资料",
		"珍兽",
		"骑乘",
		"其他",
		"经脉",
	};

	-- 保存界面的默认相对位置
	g_SelfData_Frame_UnifiedXPosition	= SelfData_Frame : GetProperty("UnifiedXPosition");
	g_SelfData_Frame_UnifiedYPosition	= SelfData_Frame : GetProperty("UnifiedYPosition");

	--屏蔽玩家资料页签中“电子邮件相关内容”，TT62640
	SelfData_EMail_Text:Hide();
	SelfData_EMail:Hide();
		
	g_SelfData_PageButton[1] = SelfData_SelfEquip
	g_SelfData_PageButton[2] = SelfData_SelfData
	g_SelfData_PageButton[3] = SelfData_Pet
	g_SelfData_PageButton[4] = SelfData_Infant
	g_SelfData_PageButton[5] = SelfData_Wuhun
	g_SelfData_PageButton[6] = SelfData_Xiulian
	g_SelfData_PageButton[7] = SelfData_Miji
	g_SelfData_PageButton[8] = SelfData_ZhenYuan
	g_SelfData_PageButton[9] = SelfData_JingMai
	g_SelfData_PageButton[10] = SelfData_ShenDing
	g_SelfData_PageButton[11] = SelfData_JueWei
	g_SelfData_PageButton[12] = SelfData_BaoJian
	g_SelfData_PageButton[13] = SelfData_WuYi
	g_SelfData_PageButton[14] = SelfData_ShenQi
	g_SelfData_PageButton[15] = SelfData_Armor
	g_SelfData_PageButton[16] = SelfData_CangPin
	g_SelfData_PageButton[17] = SelfData_OtherInfo
	
	g_SelfData_PageMask[1] = SelfData_SelfEquip_tips
	g_SelfData_PageMask[2] = SelfData_SelfData_tips
	g_SelfData_PageMask[3] = SelfData_Pet_tips
	g_SelfData_PageMask[4] = SelfData_Infant_tips
	g_SelfData_PageMask[5] = SelfData_Wuhun_tips
	g_SelfData_PageMask[6] = SelfData_Xiulian_tips
	g_SelfData_PageMask[7] = SelfData_Miji_tips
	g_SelfData_PageMask[8] = SelfData_ZhenYuan_tips
	g_SelfData_PageMask[9] = SelfData_JingMai_tips
	g_SelfData_PageMask[10] = SelfData_ShenDing_tips
	g_SelfData_PageMask[11] = SelfData_JueWei_tips
	g_SelfData_PageMask[12] = SelfData_BaoJian_tips
	g_SelfData_PageMask[13] = SelfData_WuYi_tips
	g_SelfData_PageMask[14] = SelfData_ShenQi_tips
	g_SelfData_PageMask[15] = SelfData_Armor_tips
	g_SelfData_PageMask[16] = SelfData_CangPin_tips
	g_SelfData_PageMask[17] = SelfData_OtherInfo_tips
	
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


--===============================================
-- OnEvent()
--===============================================
function SelfData_OnEvent(event)

	if event == "UPDATE_TOY_TIP" then
		SelfData_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		SelfData_RefreshCangPinTip()
	end
	
	if ( event == "UPDATE_WILLGET_MISSION_TRACK" ) or (event=="TOGGLE_UPDATE_INFANT") or (event == "FINISH_MISSION")  then
		local nLevel =Player:GetLevel()
		 SelfData_Refresh_Page_Button(nLevel)
		 SelfData_ShowPage()
	end
	if ( event == "OPEN_PRIVATE_INFO" ) then
		local LocArg = arg0;
		SelfData_SetTabColor(1);

		if(LocArg ~= "self")     then
			return;
		end

		this:Show();
		objCared = SystemSetup:GetCaredObjId();
		this:CareObject(objCared, 1, "SelfData");

		SelfData_SelfEquip:SetCheck(0);
		SelfData_SelfData:SetCheck(1);
		SelfData_Pet:SetCheck(0);

		if(LocArg == "self")     then
			local selfUnionPos = Variable:GetVariable("SelfUnionPos");
			if(selfUnionPos ~= nil) then
				SelfData_Frame:SetProperty("UnifiedPosition", selfUnionPos);
			end

			g_Current_Page = SELF_PAGE;
			SelfData_UpdateFrame("self");
			for i=1 ,CTRL_NUM  do
				CTRL[i]:Enable();
			end
			SelfData_DataShareMode:Show();
			SelfData_Accept:Show();
			SelfData_DataShareMode_Text:Show()
			SelfData_Pet:Show();
		else
			local otherUnionPos = Variable:GetVariable("OtherUnionPos");
			if(otherUnionPos ~= nil) then
				SelfData_Frame:SetProperty("UnifiedPosition", otherUnionPos);
			end

			g_Current_Page = OTHER_PAGE;
			SelfData_UpdateFrame("other");
			for i=1 ,CTRL_NUM  do
				CTRL[i]:Disable();
			end
			SelfData_DataShareMode:Hide();
			SelfData_Accept:Hide();
			SelfData_DataShareMode_Text:Hide();
			SelfData_Pet:Hide();
			SelfData_Ride: Hide();
			SelfData_OtherInfo:Hide();
			SelfData_JingMai:Hide()
		end
		local nLevel =Player:GetLevel()
		 SelfData_Refresh_Page_Button(nLevel)
		SelfData_ShowPage()
		
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

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		SelfData_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		SelfData_Frame_On_ResetPos()
	elseif(event == "MARTIAL_UPDATE"  or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		SelfData_RefreshWuYiTip()
	end
end

--===============================================
-- UpdateFrame()
--===============================================
function SelfData_UpdateFrame(whose)

	--标题显示玩家的名字
	local szName = SystemSetup:GetPrivateInfo(whose,"name");
 	SelfData_PageHeader:SetText("#gFF0FA0"..szName);

	local nType = SystemSetup:GetPrivateInfo(whose,"type");
	if nType == 0      then
		SelfData_Mode1:SetCheck(1);
		SelfData_Mode2:SetCheck(0);
		SelfData_Mode3:SetCheck(0);

	elseif nType == 1  then
		SelfData_Mode1:SetCheck(0);
		SelfData_Mode2:SetCheck(1);
		SelfData_Mode3:SetCheck(0);

	elseif nType == 2  then
		SelfData_Mode1:SetCheck(0);
		SelfData_Mode2:SetCheck(0);
		SelfData_Mode3:SetCheck(1);

	end

	local szGuid = SystemSetup:GetPrivateInfo(whose,"guid");
	local szGuidText = ConvertGuidToShow( szGuid )
	SelfData_ID:SetText("ID:".. szGuidText);

	local nAge = SystemSetup:GetPrivateInfo(whose,"age");
	SelfData_Age:SetText(tostring(nAge));


	local nSex = SystemSetup:GetPrivateInfo(whose,"sex");

	SelfData_Sex:SetCurrentSelect(nSex);

	local szJob = SystemSetup:GetPrivateInfo(whose,"job");
	SelfData_Job:SetText(szJob);


	local szSchool = SystemSetup:GetPrivateInfo(whose,"school");
	SelfData_School:SetText(szSchool);

	local nBlood = SystemSetup:GetPrivateInfo(whose,"blood");

	SelfData_BloodType:SetCurrentSelect(nBlood);

	local nAnimal = SystemSetup:GetPrivateInfo(whose,"animal");

	SelfData_YearAnimal:SetCurrentSelect(nAnimal);

	local nConsella = SystemSetup:GetPrivateInfo(whose,"Consella");

	SelfData_Constellation:SetCurrentSelect(nConsella);

	local nProvince = SystemSetup:GetPrivateInfo(whose,"Province");

	SelfData_Province:SetCurrentSelect(nProvince);

	local szCity = SystemSetup:GetPrivateInfo(whose,"city");
	SelfData_City:SetText(szCity);


	local szEmail = SystemSetup:GetPrivateInfo(whose,"email");
	SelfData_EMail:SetText(szEmail);


	local szLuck = SystemSetup:GetPrivateInfo(whose,"luck");
	SelfData_MessageBoard:SetText(szLuck);


end

--===============================================
-- Accept()
--===============================================
function SelfData_Accept_Clicked()

	local nType;
	if SelfData_Mode1:GetCheck() == 1     	then
		nType = 0;
	elseif SelfData_Mode2:GetCheck() == 1   then
		nType = 1;
	elseif SelfData_Mode3:GetCheck() == 1   then
		nType = 2;
	end

	local bCanUse=1;

	bCanUse = SystemSetup:SetPrivateInfo("self", "type", 		nType);
	--SystemSetup:SetPrivateInfo("self", "guid", 		2);

	if(bCanUse == 0)  then
		return;
	end

	local nAge = SelfData_Age:GetText();
	bCanUse = SystemSetup:SetPrivateInfo("self", "age", 		nAge);
	if(bCanUse == 0)  then
		return;
	end

	local szSex,nSex = SelfData_Sex:GetCurrentSelect();
	bCanUse = SystemSetup:SetPrivateInfo("self", "sex", 		nSex);
	if(bCanUse == 0)  then
		return;
	end

	local szJob = SelfData_Job:GetText();
	bCanUse = SystemSetup:SetPrivateInfo("self", "job", 		szJob);
	if(bCanUse == 0)  then
		return;
	end

	local szSchool = SelfData_School:GetText();
	bCanUse = SystemSetup:SetPrivateInfo("self", "school",	szSchool);
	if(bCanUse == 0)  then
		return;
	end

	local szBlood,nBlood = SelfData_BloodType:GetCurrentSelect();
	bCanUse = SystemSetup:SetPrivateInfo("self", "blood", 	nBlood);
	if(bCanUse == 0)  then
		return;
	end

	local szAnimal,nAnimal = SelfData_YearAnimal:GetCurrentSelect();
	bCanUse = SystemSetup:SetPrivateInfo("self", "animal",	nAnimal);
	if(bCanUse == 0)  then
		return;
	end

	local szConsella,nConsella = SelfData_Constellation:GetCurrentSelect();
	bCanUse = SystemSetup:SetPrivateInfo("self", "Consella",nConsella);
	if(bCanUse == 0)  then
		return;
	end

	local szProvince,nProvince = SelfData_Province:GetCurrentSelect();
	bCanUse = SystemSetup:SetPrivateInfo("self", "Province",nProvince);
	if(bCanUse == 0)  then
		return;
	end

	local szCity = SelfData_City:GetText();
	bCanUse = SystemSetup:SetPrivateInfo("self", "city", 		szCity);
	if(bCanUse == 0)  then
		return;
	end

	local szEmail = SelfData_EMail:GetText();
	bCanUse = SystemSetup:SetPrivateInfo("self", "email", 	szEmail);
	if(bCanUse == 0)  then
		return;
	end

	local szLuck = SelfData_MessageBoard:GetText();
	bCanUse = SystemSetup:SetPrivateInfo("self", "luck", 		szLuck);
	if(bCanUse == 0)  then
		return;
	end

	--提交
	SystemSetup:ApplyPrivateInfo();

	this:Hide();
	--取消关心
	this:CareObject(objCared, 0, "SelfData");

end

--===============================================
-- 打开
--===============================================
function SelfData_SelfEquip_Down()
	if( g_Current_Page == SELF_PAGE )     then
		Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
		SystemSetup:OpenEquipFrame("self");
	else
		Variable:SetVariable("OtherUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
		SystemSetup:OpenEquipFrame("other");
	end

	--取消关心
	this:CareObject(objCared, 0, "SelfData");
end

--===============================================
-- 打开
--===============================================
function SelfData_Pet_Down()

	if( g_Current_Page == SELF_PAGE )     then
		Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
		SystemSetup:OpenPetFrame("self");
		--取消关心
		this:CareObject(objCared, 0, "SelfData");

	else
		Variable:SetVariable("OtherUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
		SystemSetup:OpenPetFrame("other");
	end


end

--===============================================
-- OnHiden
--===============================================
function SelfData_Frame_OnHiden()
	SelfData_Job:SetProperty("DefaultEditBox", "False");
	SelfData_School:SetProperty("DefaultEditBox", "False");
	SelfData_City:SetProperty("DefaultEditBox", "False");
	SelfData_EMail:SetProperty("DefaultEditBox", "False");

	SelfData_Age:SetProperty("DefaultEditBox", "False");
	SelfData_MessageBoard:SetProperty("DefaultEditBox", "False");
end

--===============================================
-- SetTabColor
--===============================================
function SelfData_SetTabColor(idx)
	if(idx == nil or idx < 0 or idx > 5) then
		return;
	end


	local i = 0;
	local selColor = "#Y";
	local noselColor = "";
	local tab = {
								[0] = SelfData_SelfEquip,
								SelfData_SelfData,
								SelfData_Pet,
								SelfData_Ride,
								SelfData_OtherInfo,
								SelfData_JingMai,
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

--神木王鼎
function SelfData_ShenDing_Switch()
	Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenShenDingPage();
	if nRet == 1 then
		SelfData_SelfData:SetCheck(0);
	else
		SelfData_ShenDing:SetCheck(0)
	end
end

function SelfData_Ride_Switch()
	Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
	OpenRidePage();
	SelfData_SelfEquip : SetCheck(0);
	SelfData_SelfData : SetCheck(1);
	SelfData_Pet : SetCheck(0);
	SelfData_Ride : SetCheck(0);
	SelfData_OtherInfo : SetCheck(0);
	SelfData_JingMai : SetCheck(0);
	SelfData_SetTabColor(1);
end

function SelfData_Other_Info_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
	OtherInfoPage();
	SelfData_SelfEquip : SetCheck(0);
	SelfData_SelfData : SetCheck(1);
	SelfData_Pet : SetCheck(0);
	SelfData_Ride : SetCheck(0);
	SelfData_OtherInfo : SetCheck(0);
	SelfData_JingMai : SetCheck(0);
	SelfData_SetTabColor(1);
end

function SelfData_Xiulian_Switch()
    nLevel = Player:GetData("LEVEL")
	if(nLevel >= 70) then
		Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
		XiuLianPage();
	else
	    SelfData_Xiulian : SetCheck(0)
	    PushDebugMessage("#{XL_090707_62}")
	end
end

function SelfData_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenJingMaiPage();
	if nRet == 1 then
		SelfData_SelfData:SetCheck(0);
	else
		SelfData_JingMai:SetCheck(0)
	end
end

--显示武魂UI
function SelfData_Wuhun_Switch()
	Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
	ToggleWuhunPage();
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function SelfData_Frame_On_ResetPos()

	SelfData_Frame : SetProperty("UnifiedXPosition", g_SelfData_Frame_UnifiedXPosition);
	SelfData_Frame : SetProperty("UnifiedYPosition", g_SelfData_Frame_UnifiedYPosition);

end

function SelfData_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end

function SelfData_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenMijiPage();
	if bRet == 1 then
		this:Hide()
	end
end

function SelfData_Infant_Switch()
	Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = Infant:ToggleInfantPage();
	if nRet == 1 then
		this:Hide()
		SelfData_SelfData:SetCheck(0);
	else
		SelfData_Infant:SetCheck(0)
	end
end


function SelfData_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if ( bRet == 1 ) then
		this:Hide();
	end
end

function SelfData_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()

end


function SelfData_Refresh_Page_Button( nLevel)

	if 1 == 1 then
		return
	end
	
	--神鼎
	if ( nLevel < 15 ) then
		SelfData_ShenDing:Disable()
		SelfData_ShenDing_tips:Show()
	--	SelfData_ShenDing:SetToolTip("#{RWYQ_150707_07}")
	else
		SelfData_ShenDing:Enable()
		SelfData_ShenDing_tips:Hide()
	end
	--子女
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 ) or InfantCount<=0 then
		SelfData_Infant:Disable()
		SelfData_Infant_tips:Show()
	--	SelfData_Infant:SetToolTip("#{RWYQ_150707_01}")
	else
		SelfData_Infant:Enable()
		SelfData_Infant_tips:Hide()
	end
	--武魂
--	if ( nLevel < 65 ) then
--		SelfData_Wuhun:Disable()
--		SelfData_Wuhun_tips:Show()
	--	SelfData_Wuhun:SetToolTip("#{RWYQ_150707_02}")
--	else
		SelfData_Wuhun:Enable()
		SelfData_Wuhun_tips:Hide()
--	end
	--修炼
	if ( nLevel < 70 ) then
		SelfData_Xiulian:Disable()
		SelfData_Xiulian_tips:Show()
	--	SelfData_Xiulian:SetToolTip("#{RWYQ_150707_03}")
	else
		SelfData_Xiulian:Enable()
		SelfData_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		SelfData_Miji:Disable()
		SelfData_Miji_tips:Show()
	--	SelfData_Miji:SetToolTip("#{RWYQ_150707_04}")
	else
		SelfData_Miji:Enable()
		SelfData_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		SelfData_ZhenYuan:Disable()
		SelfData_ZhenYuan_tips:Show()
	--	SelfData_ZhenYuan:SetToolTip("#{RWYQ_150707_05}")
	else
		SelfData_ZhenYuan:Enable()
		SelfData_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		SelfData_JueWei:Disable()
		SelfData_JueWei_tips:Show()
	--	SelfData_JueWei:SetToolTip("#{RWYQ_150707_08}")
	else
		SelfData_JueWei:Enable()
		SelfData_JueWei_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		SelfData_JingMai:Disable()
		SelfData_JingMai_tips:Show()
	--	SelfData_JingMai:SetToolTip("#{RWYQ_150707_06}")
	else
		SelfData_JingMai:Enable()
		SelfData_JingMai_tips:Hide()
	end

	if ( nLevel < 85 ) then
		SelfData_BaoJian:Disable()
		SelfData_BaoJian_tips:Show()
	else
		SelfData_BaoJian:Enable()
		SelfData_BaoJian_tips:Hide()
	end
	
	--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		SelfData_WuYi:Enable()
		SelfData_WuYi_tips:Hide()
	else
		SelfData_WuYi:Disable()
		SelfData_WuYi_tips:Show()
	end
	SelfData_RefreshWuYiTip()
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		SelfData_ShenQi:Enable()
		SelfData_ShenQi_tips:Hide()
	else
		SelfData_ShenQi:Disable()
		SelfData_ShenQi_tips:Show()
	end

	SelfData_RefreshOtherInfoTip()

	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		SelfData_Armor:Enable()
		SelfData_Armor_tips:Hide()
	else
		SelfData_Armor:Disable()
		SelfData_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		SelfData_CangPin:Enable()
		SelfData_CangPin_tips:Hide()
	else
		SelfData_CangPin:Disable()
		SelfData_CangPin_tips:Show()
	end
	
	SelfData_RefreshCangPinTip()

end

function SelfData_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

-- 九星神器DIY技能
function SelfData_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function SelfData_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfData_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfData_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		SelfData_WuYi_Buttontips:Show()
	else
		SelfData_WuYi_Buttontips:Hide()
	end
end

function SelfData_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfData_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfData_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then
		SelfData_OtherInfo_ButtonTips:Show()
	else
		SelfData_OtherInfo_ButtonTips:Hide()
	end
end

--内甲
function SelfData_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function SelfData_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfData_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function SelfData_RefreshCangPinTip()
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
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfData_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfData_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		SelfData_CangPin_Buttontips:Show()
	else
		SelfData_CangPin_Buttontips:Hide()
	end
end

function SelfData_ShowPage()

	for i = 1, table.getn(g_SelfData_Page) do
		g_SelfData_PageButton[i]:Hide()
		g_SelfData_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	SelfData_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_SelfData_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_SelfData_Page) do
			if i ~= nPageNumber then
				g_SelfData_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_SelfData_Page) do
		if SelfData_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_SelfData_PageButton[g_PageCount]:Show()
			g_SelfData_PageButton[g_PageCount]:SetText(g_SelfData_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if SelfData_IsPageEnable(i) == 1 then
				g_SelfData_PageButton[g_PageCount]:Enable()
				g_SelfData_PageMask[g_PageCount]:Hide()
			else
				g_SelfData_PageButton[g_PageCount]:Disable()
				g_SelfData_PageMask[g_PageCount]:Show()
				if g_SelfData_Page[i].Tip ~= "" then
					g_SelfData_PageMask[g_PageCount]:SetToolTip(g_SelfData_Page[i].Tip)
				end
			end
		end
	end

	SelfData_RefreshWuYiTip()
	SelfData_RefreshOtherInfoTip()
	SelfData_RefreshCangPinTip()
	
end

function SelfData_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		SelfData_SelfEquip_Down(0);
	elseif idx == 2 then--资料
		--Pet_Page_SelfData()
	elseif idx == 3 then--珍兽
		SelfData_Pet_Down()
	elseif idx == 4 then--子女
		SelfData_Infant_Switch()
	elseif idx == 5 then--武魂
		SelfData_Wuhun_Switch()
	elseif idx == 6 then--修炼
		SelfData_Xiulian_Switch()
	elseif idx == 7 then--秘籍
		SelfData_Miji_Page_Switch()
	elseif idx == 8 then--真元
		SelfData_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		SelfData_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		SelfData_ShenDing_Switch()
	elseif idx == 11 then--侠印
		SelfData_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		SelfData_OpenBaoJian()
	elseif idx == 13 then--武意
		SelfData_OpenWuYi()
	elseif idx == 14 then--神器
		SelfData_OpenShenQi()
	elseif idx == 15 then--星盘
		SelfData_Armor_Page_Switch()
	elseif idx == 16 then--名物
		SelfData_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		SelfData_Other_Info_Page_Switch()
	end
end

function SelfData_CheckPage(idx)
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

function SelfData_IsPageEnable(idx)
	
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

function SelfData_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


