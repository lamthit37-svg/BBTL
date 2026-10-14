local WuXingTbl = {
			{level =1,	per = "1.0%" ,	maxlevel=1,	color = "#c00D000"},
			{level =2,	per = "1.5%" ,	maxlevel=1,	color = "#c00D000"},
			{level =3,	per = "2.1%" ,	maxlevel=2,	color = "#c00D000"},
			{level =4,	per = "3.0%" ,	maxlevel=2,	color = "#c00D000"},
			{level =5,	per = "8.0%" ,	maxlevel=3,	color = "#c43DBFF"},
			{level =6,	per = "11.0%" ,	maxlevel=3,	color = "#c43DBFF"},
			{level =7,	per = "14.5%" ,	maxlevel=4,	color = "#c43DBFF"},
			{level =8,	per = "23.5%" ,	maxlevel=4,	color = "#cFF8001"},
			{level =9,	per = "30.0%" ,	maxlevel=5,	color = "#cFF8001"},
			{level =10,	per = "39.3%" ,	maxlevel=5,	color = "#cFF8001"},
			{level =11,	per = "42.3%" ,	maxlevel=5,	color = "#cFF8001"},
			{level =12,	per = "46.0%" ,	maxlevel=5,	color = "#cFF8001"},
			{level =13,	per = "50.2%" ,	maxlevel=5,	color = "#cFF8001"},
			{level =14,	per = "54.7%" ,	maxlevel=5,	color = "#cFF8001"},
			{level =15,	per = "59.5%", maxlevel=5,	color = "#cFF8001"},
}
local ShowColor = "#H";
local PETSKILL_BUTTONS_NUM = 12;
local PETSKILL_BUTTONS = {};
local PET_POTREMAIN = 0;
local PET_ATTR_COUNT = 5;
local PET_MAX_NUMBER = 6+4;
local PETNUM = 0;
local PET_REST = 1;
local PET_FIGHT= 0;
local PET_CURRENT_SELECT = 0;
local PET_AITYPE = {};
local Changed_Name_Flag = 0;
--			// 创建珍兽(即放出) 0
--			// 收回珍兽					1
--			// 销毁珍兽(即放生)	2
--			// 捕捉珍兽					3
--			可以在被放出后，通过消息，改变该珍兽在listbox中的名字的颜色。
local PET_TAB_TEXT = {};
local PET_ORIGINAL_NAME = "";

--珍兽进阶 限制可携带等级55级以上的珍兽才可以进阶
local PET_JINJIE_LIMIT_BYTLVL = 55
local PET_JINJIELVL_PERGRADE	= 10
local PET_JINJIELVL_MAXGRADE	= 10
local g_NumToStrTable =
{
	"#{JJKHD_120808_64}",		--零
	"#{JJKHD_120808_65}",		--一
	"#{JJKHD_120808_66}",		--二
	"#{JJKHD_120808_67}",
	"#{JJKHD_120808_68}",		--四
	"#{JJKHD_120808_69}",
	"#{JJKHD_120808_70}",
	"#{JJKHD_120808_71}",
	"#{JJKHD_120808_72}",
	"#{JJKHD_120808_73}",
	"#{JJKHD_120808_74}",
}
------------------------------------------------------
--珍兽装备按钮数据定义 zchw
local g_Pet_Head; 		--头
local g_Pet_Claw;			--爪
local g_Pet_Body; 		--躯干
local g_Pet_Neck;			--项圈
local g_Pet_Charm;		--护符

local g_OtherPet_Frame_UnifiedPosition;

------------------------------------------------------

local g_PetFoodType1 =
{
	"肉食",
	"草食",
	"虫食",
	"谷食"
}
local g_PetFoodType2 =
{
	"肉",
	"草",
	"虫",
	"谷"
}

--品质
local g_Quality_Str = {
	"#{ZSHP_180814_156}", 
	"#{ZSHP_180814_155}",
	"#{ZSHP_180814_154}",
	"#{ZSHP_180814_153}",
	"#{ZSHP_180814_152}",
	"#{ZSHP_180814_151}",
	"#{ZSHP_180814_150}",
}

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_OtherPet_Page = {
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

local g_OtherPet_Button02_UnifiedPosition	
local g_OtherPet_Button03_UnifiedPosition

function OtherPet_PreLoad()
	this:RegisterEvent("TOGLE_OTHERPET_PAGE",true);
	this:RegisterEvent("UPDATE_OTHERPET_PAGE",false);

	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function OtherPet_OnLoad()

	PETSKILL_BUTTONS[1] = OtherPet_Skill1;
	PETSKILL_BUTTONS[2] = OtherPet_Skill2;
	PETSKILL_BUTTONS[3] = OtherPet_Skill3;
	PETSKILL_BUTTONS[4] = OtherPet_Skill4;
	PETSKILL_BUTTONS[5] = OtherPet_Skill5;
	PETSKILL_BUTTONS[6] = OtherPet_Skill6;
	PETSKILL_BUTTONS[7] = OtherPet_Skill7;
	PETSKILL_BUTTONS[8] = OtherPet_Skill8;
	PETSKILL_BUTTONS[9] = OtherPet_Skill9;
	PETSKILL_BUTTONS[10] = OtherPet_Skill10;
	PETSKILL_BUTTONS[11] = OtherPet_Skill11;
	PETSKILL_BUTTONS[12] = OtherPet_Skill12;

	PET_AITYPE[0] = "胆小";
	PET_AITYPE[1] = "谨慎";
	PET_AITYPE[2] = "忠诚";
	PET_AITYPE[3] = "精明";
	PET_AITYPE[4] = "勇猛";

	PET_TAB_TEXT = {
		[0] = "装备",
		"资料",
		"秘籍",
		"珍兽",
		"骑乘",
		"经脉",
	};
	--------------------------
	-- 珍兽装备与全局变量关联 zchw
	g_Pet_Head = OtherPetEquip_1;
	g_Pet_Claw = OtherPetEquip_2;
	g_Pet_Body = OtherPetEquip_3;
	g_Pet_Neck = OtherPetEquip_4;
	g_Pet_Charm = OtherPetEquip_5;
	---------------------------

	g_OtherPet_Frame_UnifiedPosition=OtherPet_Frame:GetProperty("UnifiedPosition");
	
	g_OtherPageButton[1] = OtherPet_SelfEquip
	g_OtherPageButton[2] = OtherPet_TargetData
	g_OtherPageButton[3] = OtherPet_Pet
	g_OtherPageButton[4] = OtherPet_TargetInfant
	g_OtherPageButton[5] = OtherPet_TargetWuhun
	g_OtherPageButton[6] = OtherPet_Miji
	g_OtherPageButton[7] = OtherPet_ZhenYuan
	g_OtherPageButton[8] = OtherPet_JingMai
	g_OtherPageButton[9] = OtherPet_ShenDing
	g_OtherPageButton[10] = OtherPet_JueWei
	g_OtherPageButton[11] = OtherPet_BaoJian
	g_OtherPageButton[12] = OtherPet_WuYi
	g_OtherPageButton[13] = OtherPet_ShenQi
	g_OtherPageButton[14] = OtherPet_Armor
	g_OtherPageButton[15] = OtherPet_CangPin
	
	g_OtherPet_Button02_UnifiedPosition = OtherPet_Frame_Client_Button02:GetProperty("UnifiedPosition")	
	g_OtherPet_Button03_UnifiedPosition = OtherPet_Frame_Client_Button03:GetProperty("UnifiedPosition")
	
end

function OtherPet_OnEvent(event)
	OtherPet_SetTabColor(3);
	--this:Show();

	if ( event == "TOGLE_OTHERPET_PAGE" ) then

		if arg0 ~= nil and tonumber(arg0) < PET_MAX_NUMBER and tonumber(arg0) >= 0 then
			PET_CURRENT_SELECT = tonumber(arg0)
		end
		if(IsWindowShow("TargetPet")) then
			CloseWindow("TargetPet", true);
			return;
		end
		
		if IsWindowShow("OtherPetNeidan") then
			CloseWindow("OtherPetNeidan", true)
		end

		local obj_id = CachedTarget:GetData("NPCID", 1)
		if (type(obj_id) ~="number") then
			PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
			return
		end
		this:CareObject(obj_id , 1)

		OtherPet_OnShown();
		OtherPet_Open();
		OtherPet_ShowPage()		
		return;
	elseif ( event == "UPDATE_OTHERPET_PAGE" and this:IsVisible() ) then
		OtherPet_Update();
		OtherPet_SetStateTooltip(PET_CURRENT_SELECT);
		return;

	elseif (event == "ADJEST_UI_POS" ) then
		OtherPet_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		OtherPet_Frame_On_ResetPos()
	end

end

function OtherPet_OnShown()
	
	local otherUnionPos = Variable:GetVariable("OtherUnionPos")
	if otherUnionPos ~= nil then
		OtherPet_Frame:SetProperty("UnifiedPosition", otherUnionPos)
	end
	
	OtherPet_FakeObject:AttachWindowEx("My_OtherPet")

	OtherPet_SelfEquip:SetCheck(0)
	OtherPet_TargetData:SetCheck(0)
	OtherPet_Pet:SetCheck(1)
	OtherPet_Miji:SetCheck(0)
	OtherPet_Frame_Client_Button01:SetCheck(1)
	OtherPet_Frame_Client_Button02:SetCheck(0)
	OtherPet_Frame_Client_Button03:SetCheck(0)
		
	if Player:GetData("IsOriginalJD") == 1 then
		OtherPet_Frame_Client_Button04:Hide()
	else
		OtherPet_Frame_Client_Button04:Show()
	end
	
	if Player : GetData("Is2606S") == 1 then
		OtherPet_Frame_Client_Button02:Hide()
		OtherPet_Frame_Client_Button02:SetProperty("UnifiedPosition", g_OtherPet_Button03_UnifiedPosition);
		OtherPet_Frame_Client_Button03:SetProperty("UnifiedPosition", g_OtherPet_Button02_UnifiedPosition);
		OtherPet_Frame_Client_Button04:Hide()
	else
		OtherPet_Frame_Client_Button02:Show()
		OtherPet_Frame_Client_Button02:SetProperty("UnifiedPosition", g_OtherPet_Button02_UnifiedPosition);
		OtherPet_Frame_Client_Button03:SetProperty("UnifiedPosition", g_OtherPet_Button03_UnifiedPosition);
		OtherPet_Frame_Client_Button04:Show()
	end
	
	OtherPet_Page_Clear()
	OtherPet_Update()
	OtherPet_SetStateTooltip(PET_CURRENT_SELECT)
end

function OtherPet_Page_Clear()
	OtherPet_FakeObject:RotateEndEx()

	--Add By YuanPeiLong
	OtherPet_NeedLevel : SetText("")
	--End
	--PushDebugMessage("555555")
	OtherPet_Proficient_Text : Hide()
	OtherPet_OtherPetName:SetText("")
	OtherPet_Type : SetText("");

	OtherPet_PageHeader : SetText( "#gFF0FA0" );
	OtherPet_ConsortID : SetText( "" );
	OtherPet_Model_Protect_Text : SetText( "" );
	OtherPet_OtherPetID : SetText( "" );
	OtherPet_Sex : SetText("");
	OtherPet_Life : SetText( "" );
	OtherPet_Happy : SetText("");
	OtherPet_Level : SetText( "" );
	OtherPet_StrAptitude : SetText( "" );
	OtherPet_PhysicalStrengthAptitude : SetText( "" );
	OtherPet_DexterityAptitude : SetText( "" );
	OtherPet_NimbusAptitude : SetText( "" );
	OtherPet_StabilityAptitude : SetText( "" );
	OtherPet_Exp : SetText( "" );
	OtherPet_Blood : SetText( "" );
	OtherPet_Str : SetText( "" );
	OtherPet_Nimbus : SetText( "" );
	OtherPet_Dexterity : SetText( "" );
	OtherPet_PhysicalStrength : SetText( "" );
	OtherPet_Stability : SetText( "" );
	OtherPet_GenGu : SetText( "" );
	OtherPet_Potential : SetText( "" );
	OtherPet_PhysicsAttack : SetText( "" );
	OtherPet_MagicAttack : SetText( "" );
	OtherPet_PhysicsRecovery : SetText( "" );
	OtherPet_MagicRecovery : SetText( "" );
	OtherPet_Miss : SetText( "" );
	OtherPet_WuXing : SetText( "" );

	OtherPet_Ronghedu : SetText("")
	-- 不显示 tooltips
	OtherPet_Ronghedu : Disable()

	OtherPet_ShootProbability : SetText( "" );
	OtherPet_CriticalAttack:SetText("");
	OtherPet_CriticalDefence:SetText("")

	OtherPet_Growth:SetText("");
	OtherPetAttack_Type : Hide();
	OtherPet_Lingxing : SetText("")
	OtherPet_Lingxing_Info : SetText("")


	--added by dun.liu
	g_Pet_Head : SetActionItem(-1);
	g_Pet_Claw : SetActionItem(-1);
	g_Pet_Body : SetActionItem(-1);
	g_Pet_Neck : SetActionItem(-1);
	g_Pet_Charm : SetActionItem(-1);

	for i=1, PETSKILL_BUTTONS_NUM do
		PETSKILL_BUTTONS[i]:SetActionItem(-1);
	end
	OtherPetFood_Type : Hide();
	OtherPet_lock : Hide();
	OtherPet_Jian : Hide();

	--设置珍兽数量信息--add by xindefeng
	local nPetCount = Pet:Other_GetPet_Count();
	local nMaxPetCount = GetOtherCurMaxPetCount();
	OtherPet_List_Text:SetText("珍兽列表 "..nPetCount.."/"..nMaxPetCount);

	OtherPet_ClearStateTooltip();

	--珍兽进阶
	OtherPet_Str_jieduan : SetText("")
	OtherPet_Nimbus_jieduan : SetText( "" );
	OtherPet_Pet_Dexterity_jieduan : SetText( "" );
	OtherPet_PhysicalStrength_jieduan : SetText( "" );
	OtherPet_Stability_jieduan : SetText( "" );
	OtherPet_jieduan : SetText("");
	OtherPet_HuanLing : Hide();
	OtherPet_Quality_Text : SetText("")
end

function OtherPet_ListBox_Selected()
	PETNUM = OtherPet_List : GetFirstSelectItem();
	local nOtherPetCount = Pet : Other_GetPet_Count();

	if(PETNUM == PET_CURRENT_SELECT) then
		return;
	end

	if(PETNUM < 0 and nPetCount > 0) then
		PETNUM = PET_CURRENT_SELECT;
		return;
	end

	OtherPet_Page_Clear()
	Changed_Name_Flag = 0
	PET_CURRENT_SELECT = PETNUM

	Pet:Other_SetModel(PETNUM)


	OtherPet_Show_Appoint(PETNUM);
	OtherPet_Refresh_Equip();
	OtherPet_SetStateTooltip(PETNUM);
	Pet : Other_SetSelectedIdx(PETNUM)

end

function OtherPet_ListBox_RClicked()
	local clkNum = OtherPet_List : GetClickItem();

	if(clkNum >= 0) then
		Pet:CheckRClick(clkNum);
	end
end

function OtherPet_Update()
	OtherPet_SelfEquip : SetCheck(0);
	OtherPet_TargetData : SetCheck(0);
	OtherPet_Pet : SetCheck(1);
	OtherPet_Miji : SetCheck(0);

	local nPetCount = Pet : Other_GetPet_Count();
	local szPetName;

	OtherPet_Page_Clear();
	OtherPet_List : ClearListBox();

	if nPetCount < 1 then
		return;
	end

	local bSelect = 0;

	for	i=1, PET_MAX_NUMBER do
		if Pet:Other_IsPresent(i-1) then
			szPetName = Pet : Other_GetPetList_Appoint(i-1);


			OtherPet_List : AddItem(szPetName, i-1);

			if( i-1 == PET_CURRENT_SELECT) then
				bSelect = 1;
			end
		end
	end

	--yuanfengfeng for tt 50330，在PET_CURRENT_SELECT对应的宠物不存在的情况下，将PET_CURRENT_SELECT置为第一个，然后设置bSelect为1
	--能走到这里，肯定至少有一个宠物
	if bSelect == 0 then
		bSelect = 1;
		PET_CURRENT_SELECT = 0;
	end

	--有选中对象的，才进行选中操作。
	if bSelect == 1 then
		OtherPet_List:SetItemSelectByItemID(PET_CURRENT_SELECT)
		Pet:Other_SetModel(PET_CURRENT_SELECT)
		OtherPet_Show_Appoint(PET_CURRENT_SELECT)
	end

	if PET_CURRENT_SELECT > PET_MAX_NUMBER then
		PET_CURRENT_SELECT = PET_MAX_NUMBER;
	end

	local strNeedLevel;
	local strNeedLevelColor;
	local nIsBaiShou = Pet:GetIsBaiShou() --CachedTarget:GetIsBaiShouFlag()
	local nTakeLevel = Pet:Other_GetTakeLevel(PET_CURRENT_SELECT );
	local nTakeLevel_BaiShou = nTakeLevel
	if(nIsBaiShou == 1) then
		nTakeLevel_BaiShou = nTakeLevel - 10
	    if nTakeLevel_BaiShou < 1 then
			nTakeLevel_BaiShou = 1
		end
	end

	if( nTakeLevel_BaiShou > Player:GetData( "LEVEL" ) )then
		strNeedLevelColor="#cFF0000";
	else
		strNeedLevelColor="#c00FF00";
	end
	strNeedLevel = strNeedLevelColor..tostring( nTakeLevel ).."级#W可携带";
	OtherPet_NeedLevel:SetText( strNeedLevel );

	local targetIsBaiShou = CachedTarget:GetIsBaiShouFlag()
	if (nIsBaiShou == 1) then
		OtherPet_Proficient_Text : Show()
		OtherPet_Proficient_Text : SetToolTip("#{BSJT_130114_04}")
	else
		if targetIsBaiShou == 1 then
			OtherPet_Proficient_Text : Show()
			OtherPet_Proficient_Text : SetToolTip("#{BSJT_130114_05}")
		else
			OtherPet_Proficient_Text : Hide()
		end
	end
	--品质
	local nQuality = Pet:Other_GetQuality(PET_CURRENT_SELECT );
	if nQuality > 0 and nQuality <= 7 then
		OtherPet_Quality_Text:SetText( g_Quality_Str[nQuality]  )
	end
	
end

--zchw
function OtherPet_Refresh_Equip()
	--  清空按钮显示图标
	g_Pet_Head : SetActionItem(-1);
	g_Pet_Claw : SetActionItem(-1);
	g_Pet_Body : SetActionItem(-1);
	g_Pet_Neck : SetActionItem(-1);
	g_Pet_Charm : SetActionItem(-1);

	local ActionClaw 		= EnumAction(5*PET_CURRENT_SELECT, "other_pet_equip");
	local ActionHead		= EnumAction(5*PET_CURRENT_SELECT + 1, "other_pet_equip");
	local ActionBody  	= EnumAction(5*PET_CURRENT_SELECT + 2, "other_pet_equip");
	local ActionNeck   	= EnumAction(5*PET_CURRENT_SELECT + 3, "other_pet_equip");
	local ActionCharm   = EnumAction(5*PET_CURRENT_SELECT + 4, "other_pet_equip");

	g_Pet_Head : SetActionItem(ActionHead : GetID());
	g_Pet_Claw : SetActionItem(ActionClaw : GetID());
	g_Pet_Body : SetActionItem(ActionBody : GetID());
	g_Pet_Neck : SetActionItem(ActionNeck : GetID());
	g_Pet_Charm : SetActionItem(ActionCharm : GetID());
end

function OtherPet_Show_Appoint(nIndex)

	local i;

	if(not (Pet:Other_IsPresent(nIndex)) ) then
		return;
	end

	for i=1, PETSKILL_BUTTONS_NUM do
		PETSKILL_BUTTONS[i]:SetActionItem(-1);
	end

 	local strName = Pet:Other_GetAIType(nIndex);
	local effectStr = "" 
	
	local strAI;
	if(strName>4 or strName <0) then
		strAI = "错误";
	else
		strAI =	PET_AITYPE[strName];
	end

	local	strName2 = ""
 	strName,strName2 = Pet:Other_GetName(nIndex);
	local nEra, strTypeName = Pet:Other_GetPetTypeName(nIndex);
 	if( 1 == nEra ) then
 	    strName2 = "二代"..strTypeName
 	end


 	OtherPet_PageHeader : SetText("#gFF0FA0"..strName2);
 	OtherPet_Type :SetText("#gFF8E92"..strAI);

	OtherPet_OtherPetName : SetText( strName );

--	OtherPet_PageHeader : SetText( strAI .. strName2 );

	strName,strName2,sex = Pet : Other_GetID(nIndex);
	OtherPet_OtherPetID : SetText( "珍兽ID:"..strName2 );


	strName = Pet : Other_GetConsort(nIndex);
	if(strName == "00000000") then
		strName = "";
	end;
	OtherPet_ConsortID : SetText( "配偶ID:"..strName );

	if Pet : Other_GetGoodsProtect_Pet(nIndex) == 1 then
		OtherPet_Model_Protect_Text : SetText( "#{GDWPBH_090507_4}" );
	else
		OtherPet_Model_Protect_Text : SetText( "" );
	end
	--品质
	local nQuality = Pet:Other_GetQuality(nIndex );
	if nQuality > 0 and nQuality <= 7 then
		OtherPet_Quality_Text:SetText( g_Quality_Str[nQuality]  )
	end

	if(sex == 1) then
		strName = "雄性";
	else
		strName = "雌性";
	end

	local nGeneration  = Pet : Other_GetGeneration(nIndex)
	if nGeneration ~= nil and nGeneration >= 100 then
		strName = "#{RXZS_XML_35}";
	end

	OtherPet_Sex : SetText( strName );
	local strNeedLevel;
	local strNeedLevelColor;
	local nTakeLevel = Pet:Other_GetTakeLevel(nIndex);
	local nIsBaiShou = Pet:GetIsBaiShou()
	local nTakeLevel_BaiShou = nTakeLevel
	if(nIsBaiShou == 1) then
		nTakeLevel_BaiShou = nTakeLevel - 10
	    if nTakeLevel_BaiShou < 1 then
			nTakeLevel_BaiShou = 1
		end
	end

	if( nTakeLevel_BaiShou > Player:GetData( "LEVEL" ) )then
		strNeedLevelColor="#cFF0000";
	else
		strNeedLevelColor="#c00FF00";
	end
	strNeedLevel = strNeedLevelColor..tostring( nTakeLevel ).."级#W可携带";
	local targetIsBaiShou = CachedTarget:GetIsBaiShouFlag()
	if (nIsBaiShou == 1) then
		OtherPet_Proficient_Text : Show()
		OtherPet_Proficient_Text : SetToolTip("#{BSJT_130114_04}")
	else
		if targetIsBaiShou == 1 then
			OtherPet_Proficient_Text : Show()
			OtherPet_Proficient_Text : SetToolTip("#{BSJT_130114_05}")
		else
			OtherPet_Proficient_Text : Hide()
		end
	end

	OtherPet_NeedLevel:SetText( strNeedLevel );
	--幻灵
	local nHuanlingId = Pet:Other_GetHuanlingID(nIndex)
	if nHuanlingId >= 0 then
		local strName = Pet:Lua_GetPetHuanLingInfo(nHuanlingId, "Name")
		local strStyle = Pet:Lua_GetPetHuanLingInfo(nHuanlingId, "ExText")
		OtherPet_HuanLing : SetText("#{ZSHP_180814_05}")
		OtherPet_HuanLing : SetToolTip(ScriptGlobal_Format("#{ZSHP_180814_06}", strName, strStyle))
		OtherPet_HuanLing : Show()
	end
	strName = Pet : Other_GetNaturalLife(nIndex);
--	strName2 = OtherPet:	GetMaxLife(nIndex);
	OtherPet_Life : SetText( "寿命:"..strName );

--	strName = Pet : Other_GetLoyalgGade(nIndex);
--	OtherPet_LoyalgGade : SetText( strName );

--	strName = Pet : Other_GetBasic(nIndex);
--	OtherPet_GenGu : SetText( "根骨:"..strName );

	strName = Pet : Other_GetLevel(nIndex);
	OtherPet_Level : SetText( "等级:"..strName );

--	strName = Pet : Other_GetType(nIndex);
--	OtherPet_Type : SetText( "第".. tostring(strName).."代" );

	strName = Pet : Other_GetHappy(nIndex);
	OtherPet_Happy : SetText( "快乐:"..strName );

	strName = Pet : Other_GetLixing(nIndex);
	OtherPet_Lingxing : SetText("#{RXZS_XML_28}"..strName)

	strName = Pet : Other_GetPercent_Lx(nIndex)
	if tonumber(strName) ~= nil and tonumber(strName) > 0 then
		local rateStr = string.format("%0.1f" , strName / 10.0)
		OtherPet_Lingxing_Info:SetText("#cFF00FF(+"..rateStr.."%)")
	end

	strName = Pet : Other_GetFitValue(nIndex)
	OtherPet_Ronghedu : SetText("#{ZSHT_XML_04}:" .. strName)
	-- 显示 ToolTips
	OtherPet_Ronghedu : Enable()

	-- 注意, 必须把悟性放在最后, 因为后面计算珍兽一级属性加成的时候要用到, 并且直接用的 strName
	strName = Pet : Other_GetSavvy(nIndex);
	OtherPet_WuXing : SetText( "悟性:"..strName );

	local WuXingVal = tonumber(strName);
	strName = Pet : Other_GetStrAptitude(nIndex);
	if(WuXingTbl[WuXingVal])then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")";
	end
	
	if Pet:Other_IsPetMasterEffectActive(nIndex,1) == 1 or Pet:Other_GetPetMasterTotalEffect(nIndex,9) > 0 then
		effectStr = Pet:Other_GetPetMasterTotalEffect(nIndex,9)
		OtherPet_StrAptitude:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		if(WuXingTbl[WuXingVal])then
			OtherPet_StrAptitude:SetToolTip("#{YSSJ_140818_59}")
			OtherPet_StrAptitude_Text:SetToolTip("#{YSSJ_140818_59}")
		else
			OtherPet_StrAptitude:SetToolTip("#{YSSJ_140818_103}")
			OtherPet_StrAptitude_Text:SetToolTip("#{YSSJ_140818_103}")
		end
	else
		OtherPet_StrAptitude:SetText( strName )
		OtherPet_StrAptitude:SetToolTip("")
		OtherPet_StrAptitude_Text:SetToolTip("")
	end

	strName = Pet : Other_GetIntAptitude(nIndex);
	if(WuXingTbl[WuXingVal])then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")";
	end
	
	if Pet:Other_IsPetMasterEffectActive(nIndex,1) == 1 or Pet:Other_GetPetMasterTotalEffect(nIndex,10) > 0 then
		effectStr = Pet:Other_GetPetMasterTotalEffect(nIndex,10)
		OtherPet_NimbusAptitude:SetText( strName.."#G(+"..tostring(effectStr)..")"  )
		if(WuXingTbl[WuXingVal])then
			OtherPet_NimbusAptitude:SetToolTip("#{YSSJ_140818_60}")
			OtherPet_NimbusAptitude_Text:SetToolTip("#{YSSJ_140818_60}")
		else
			OtherPet_NimbusAptitude:SetToolTip("#{YSSJ_140818_104}")
			OtherPet_NimbusAptitude_Text:SetToolTip("#{YSSJ_140818_104}")
		end
	else
		OtherPet_NimbusAptitude:SetText( strName )
		OtherPet_NimbusAptitude:SetToolTip("")
		OtherPet_NimbusAptitude_Text:SetToolTip("")
	end
	
	
	strName = Pet : Other_GetPFAptitude(nIndex);
	if(WuXingTbl[WuXingVal])then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")";
	end

	if Pet:Other_IsPetMasterEffectActive(nIndex,1) == 1 or Pet:Other_GetPetMasterTotalEffect(nIndex,11) > 0 then
		effectStr = Pet:Other_GetPetMasterTotalEffect(nIndex,11)
		OtherPet_PhysicalStrengthAptitude:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		if(WuXingTbl[WuXingVal])then
			OtherPet_PhysicalStrengthAptitude:SetToolTip("#{YSSJ_140818_61}")
			OtherPet_PhysicalStrengthAptitude_Text:SetToolTip("#{YSSJ_140818_61}")
		else
			OtherPet_PhysicalStrengthAptitude:SetToolTip("#{YSSJ_140818_105}")
			OtherPet_PhysicalStrengthAptitude_Text:SetToolTip("#{YSSJ_140818_105}")
		end
	else
		OtherPet_PhysicalStrengthAptitude:SetText( strName )
		OtherPet_PhysicalStrengthAptitude:SetToolTip("")
		OtherPet_PhysicalStrengthAptitude_Text:SetToolTip("")
	end
	

	strName = Pet : Other_GetStaAptitude(nIndex);
	if(WuXingTbl[WuXingVal])then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")";
	end

	if Pet:Other_IsPetMasterEffectActive(nIndex,1) == 1 or Pet:Other_GetPetMasterTotalEffect(nIndex,12) > 0 then
		effectStr = Pet:Other_GetPetMasterTotalEffect(nIndex,12)
		OtherPet_StabilityAptitude:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		if(WuXingTbl[WuXingVal])then
			OtherPet_StabilityAptitude:SetToolTip("#{YSSJ_140818_62}")
			OtherPet_StabilityAptitude_Text:SetToolTip("#{YSSJ_140818_62}")
		else
			OtherPet_StabilityAptitude:SetToolTip("#{YSSJ_140818_106}")
			OtherPet_StabilityAptitude_Text:SetToolTip("#{YSSJ_140818_106}")
		end
	else
		OtherPet_StabilityAptitude:SetText( strName )
		OtherPet_StabilityAptitude:SetToolTip("")
		OtherPet_StabilityAptitude_Text:SetToolTip("")
	end
	
	strName = Pet : Other_GetDexAptitude(nIndex);
	if(WuXingTbl[WuXingVal])then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")";
	end
	
	if Pet:Other_IsPetMasterEffectActive(nIndex,1) == 1 or Pet:Other_GetPetMasterTotalEffect(nIndex,13) > 0 then
		effectStr = Pet:Other_GetPetMasterTotalEffect(nIndex,13)
		OtherPet_DexterityAptitude:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		if(WuXingTbl[WuXingVal])then
			OtherPet_DexterityAptitude:SetToolTip("#{YSSJ_140818_63}")
			OtherPet_FootworkAptitude_Text:SetToolTip("#{YSSJ_140818_63}")
		else
			OtherPet_DexterityAptitude:SetToolTip("#{YSSJ_140818_107}")
			OtherPet_FootworkAptitude_Text:SetToolTip("#{YSSJ_140818_107}")
		end
	else
		OtherPet_DexterityAptitude:SetText( strName )
		OtherPet_DexterityAptitude:SetToolTip("")
		OtherPet_FootworkAptitude_Text:SetToolTip("")
	end

	strName,strName2 = Pet : Other_GetExp(nIndex);
	OtherPet_Exp : SetText( "经验:"..strName .."/"..strName2);
	
	strName = Pet : Other_GetHP(nIndex);
	strName2 = Pet:	Other_GetMaxHP(nIndex);
	if Pet:Other_IsPetMasterEffectActive(nIndex,0) == 1 or Pet:Other_GetPetCangpinEffect(nIndex,3) > 0 then
		effectStr = Pet:Other_GetPetMasterTotalEffect(nIndex,0) + Pet:Other_GetPetCangpinEffect(nIndex,0)
		OtherPet_Blood:SetText( "血:"..strName .."/".. strName2.."#G(+"..tostring(effectStr)..")" )
		OtherPet_Blood:SetToolTip("#{YSSJ_140818_64}")
	else
		OtherPet_Blood:SetText( "血:"..strName .."/".. strName2 )
		OtherPet_Blood:SetToolTip("")
	end
	
--	strName = Pet : Other_GetMP(nIndex);
--	strName2 = Pet:	Other_GetMaxMP(nIndex);
--	OtherPet_MP : SetText( strName .." / ".. strName2);
	--local Sum_Attr = 0;--modi:lby20071108
	--珍兽进阶 废除传承标志
	--local bJinJieImpact = Pet : Other_GetJinJieImpact(nIndex);
	local nJinJieGrade = Pet : Other_GetJinJieGrade(nIndex);
	local nJinJieLevel = Pet : Other_GetJinJieLvl(nIndex);
	if nTakeLevel < PET_JINJIE_LIMIT_BYTLVL then
		OtherPet_jieduan:SetText("#{JJKHD_120808_21}");
		OtherPet_jieduan:SetToolTip("#{JJKHD_120808_35}");
	elseif nJinJieGrade == PET_JINJIELVL_MAXGRADE then
		OtherPet_jieduan:SetText("#{JJKHD_120808_24}");
		OtherPet_jieduan:SetToolTip("#{JJKHD_120808_37}");
	elseif nJinJieGrade < PET_JINJIELVL_MAXGRADE then
		if g_NumToStrTable[nJinJieGrade + 1] ~= nil and g_NumToStrTable[nJinJieLevel + 1] ~= nil then
			local szCurJinJieInfo = ScriptGlobal_Format("#{JJKHD_120808_22}", g_NumToStrTable[nJinJieGrade + 1], g_NumToStrTable[nJinJieLevel + 1])
			OtherPet_jieduan:SetText(szCurJinJieInfo);
		end
		OtherPet_jieduan:SetToolTip("#{JJKHD_120808_36}");
	end


	local strJinJie = 0
	local SprJinJie = 0
	local DexJinJie = 0
	local ConJinJie = 0
	local IntJinJie = 0
	if(nJinJieGrade > 0 or nJinJieLevel > 0) then
		OtherPet_Str_jieduan:Show()
		OtherPet_Nimbus_jieduan:Show()
		OtherPet_Pet_Dexterity_jieduan:Show()
		OtherPet_PhysicalStrength_jieduan:Show()
		OtherPet_Stability_jieduan:Show()

		strJinJie = Pet : Other_GetJinJieStr(nIndex);	--力量
		OtherPet_Str_jieduan : SetText("+"..tonumber(strJinJie))

		SprJinJie = Pet : Other_GetJinJieSpr(nIndex);	--灵气
		OtherPet_Nimbus_jieduan : SetText("+"..tonumber(SprJinJie))

		DexJinJie = Pet : Other_GetJinJieDex(nIndex);	--身法
		OtherPet_Pet_Dexterity_jieduan : SetText("+"..tonumber(DexJinJie))

		ConJinJie = Pet : Other_GetJinJieCon(nIndex);	--体力
		OtherPet_PhysicalStrength_jieduan : SetText("+"..tonumber(ConJinJie))

		IntJinJie = Pet : Other_GetJinJieINT(nIndex);	--定力
		OtherPet_Stability_jieduan : SetText("+"..tonumber(IntJinJie))
	else
		OtherPet_Str_jieduan:Hide()
		OtherPet_Nimbus_jieduan:Hide()
		OtherPet_Pet_Dexterity_jieduan:Hide()
		OtherPet_PhysicalStrength_jieduan:Hide()
		OtherPet_Stability_jieduan:Hide()
	end

	strName = Pet : Other_GetStr(nIndex);
--	Sum_Attr = Sum_Attr + tonumber(strName)
	OtherPet_Str : SetText( tonumber(strName - strJinJie)  );
--	Pet_Str : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");

	strName = Pet : Other_GetInt(nIndex);
--	Sum_Attr = Sum_Attr + tonumber(strName)
	OtherPet_Nimbus : SetText( tonumber(strName - SprJinJie)  );
--	OtherPet_Nimbus : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");

	strName = Pet : Other_GetDex(nIndex);
--	Sum_Attr = Sum_Attr + tonumber(strName)
	OtherPet_Dexterity : SetText( tonumber(strName - DexJinJie) );
--	OtherPet_Dexterity : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");

	strName = Pet : Other_GetPF(nIndex);
--	Sum_Attr = Sum_Attr + tonumber(strName)
	OtherPet_PhysicalStrength : SetText( tonumber(strName - ConJinJie) );
--	OtherPet_PhysicalStrength : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");

	strName = Pet : Other_GetSta(nIndex);
--	Sum_Attr = Sum_Attr + tonumber(strName)
	OtherPet_Stability : SetText( tonumber(strName - IntJinJie) );
--	OtherPet_Stability : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");

	strName = Pet : Other_GetBasic(nIndex);
	OtherPet_GenGu : SetText( "根骨:"..tonumber(strName) );
	--会心攻击
	if Pet:Other_IsPetMasterEffectActive(nIndex,0) == 1 or Pet:Other_GetPetCangpinEffect(nIndex,3) > 0 then
		effectStr = Pet:Other_GetPetMasterTotalEffect(nIndex,7) + Pet:Other_GetPetCangpinEffect(nIndex,7)
		OtherPet_CriticalAttack:SetText( tostring(Pet:Other_GetCriticalAttack(nIndex)).."#G(+"..tostring(effectStr)..")"   )
		OtherPet_CriticalAttack:SetToolTip("#{YSSJ_140818_71}")
		OtherPet_CriticalAttack_Text:SetToolTip("#{YSSJ_140818_71}")
	else
		OtherPet_CriticalAttack:SetText( Pet:Other_GetCriticalAttack(nIndex)   )
		OtherPet_CriticalAttack:SetToolTip("")
		OtherPet_CriticalAttack_Text:SetToolTip("")
	end
	--会心防御
	if Pet:Other_IsPetMasterEffectActive(nIndex,0) == 1 or Pet:Other_GetPetCangpinEffect(nIndex,3) > 0 then
		effectStr = Pet:Other_GetPetMasterTotalEffect(nIndex,8) + Pet:Other_GetPetCangpinEffect(nIndex,8)
		OtherPet_CriticalDefence:SetText( tostring(Pet:Other_GetCriticalDefence(nIndex)).."#G(+"..tostring(effectStr)..")"   )
		OtherPet_CriticalDefence:SetToolTip("#{YSSJ_140818_72}")
		OtherPet_CriticalDefence_Text:SetToolTip("#{YSSJ_140818_72}")
	else
		OtherPet_CriticalDefence:SetText( Pet:Other_GetCriticalDefence(nIndex)   )
		OtherPet_CriticalDefence:SetToolTip("")
		OtherPet_CriticalDefence_Text:SetToolTip("")
	end

	--modi:lby20071108 start
	strName = Pet : Other_GetPotential(nIndex);
	strName2 = tonumber(strName);
--	strName2 = strName2 - Sum_Attr;
	OtherPet_Potential : SetText( strName2 );
	--modi:lby20071108 end
--	OtherPet_Potential : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
	
	--外功
	strName = Pet : Other_GetPhysicsAttack(nIndex);
	if Pet:Other_IsPetMasterEffectActive(nIndex,0) == 1 or Pet:Other_GetPetCangpinEffect(nIndex,3) > 0 then
		effectStr = Pet:Other_GetPetMasterTotalEffect(nIndex,1) + Pet:Other_GetPetCangpinEffect(nIndex,1)
		OtherPet_PhysicsAttack:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		OtherPet_PhysicsAttack:SetToolTip("#{YSSJ_140818_65}")
		OtherPet_PhysicsAttack_Text:SetToolTip("#{YSSJ_140818_65}")
	else
		OtherPet_PhysicsAttack:SetText( strName )
		OtherPet_PhysicsAttack:SetToolTip("")
		OtherPet_PhysicsAttack_Text:SetToolTip("")
	end
	--内功
	strName = Pet : Other_GetMagicAttack(nIndex);
	if Pet:Other_IsPetMasterEffectActive(nIndex,0) == 1 or Pet:Other_GetPetCangpinEffect(nIndex,3) > 0 then
		effectStr = Pet:Other_GetPetMasterTotalEffect(nIndex,2) + Pet:Other_GetPetCangpinEffect(nIndex,2)
		OtherPet_MagicAttack:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		OtherPet_MagicAttack:SetToolTip("#{YSSJ_140818_66}")
		OtherPet_MagicAttack_Text:SetToolTip("#{YSSJ_140818_66}")
	else
		OtherPet_MagicAttack:SetText( strName )
		OtherPet_MagicAttack:SetToolTip("")
		OtherPet_MagicAttack_Text:SetToolTip("")
	end
	--外防
	strName = Pet : Other_GetPhysicsRecovery(nIndex);
	if Pet:Other_IsPetMasterEffectActive(nIndex,0) == 1 or Pet:Other_GetPetCangpinEffect(nIndex,3) > 0 then
		effectStr = Pet:Other_GetPetMasterTotalEffect(nIndex,3) + Pet:Other_GetPetCangpinEffect(nIndex,3)
		OtherPet_PhysicsRecovery:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		OtherPet_PhysicsRecovery:SetToolTip("#{YSSJ_140818_67}")
		OtherPet_PhysicsRecovery_Text:SetToolTip("#{YSSJ_140818_67}")
	else
		OtherPet_PhysicsRecovery:SetText( strName)
		OtherPet_PhysicsRecovery:SetToolTip("")
		OtherPet_PhysicsRecovery_Text:SetToolTip("")
	end
	--内防
	strName = Pet : Other_GetMagicRecovery (nIndex);
	if Pet:Other_IsPetMasterEffectActive(nIndex,0) == 1 or Pet:Other_GetPetCangpinEffect(nIndex,3) > 0 then
		effectStr = Pet:Other_GetPetMasterTotalEffect(nIndex,4) + Pet:Other_GetPetCangpinEffect(nIndex,4)
		OtherPet_MagicRecovery:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		OtherPet_MagicRecovery:SetToolTip("#{YSSJ_140818_68}")
		OtherPet_MagicRecovery_Text:SetToolTip("#{YSSJ_140818_68}")
	else
		OtherPet_MagicRecovery:SetText( strName )
		OtherPet_MagicRecovery:SetToolTip("")
		OtherPet_MagicRecovery_Text:SetToolTip("")
	end
	--闪避率
	strName = Pet : Other_GetMiss(nIndex);
	if Pet:Other_IsPetMasterEffectActive(nIndex,0) == 1 or Pet:Other_GetPetCangpinEffect(nIndex,3) > 0 then
		effectStr = Pet:Other_GetPetMasterTotalEffect(nIndex,5) + Pet:Other_GetPetCangpinEffect(nIndex,5)
		OtherPet_Miss:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		OtherPet_Miss:SetToolTip("#{YSSJ_140818_69}")
		OtherPet_Miss_Text:SetToolTip("#{YSSJ_140818_69}")
	else
		OtherPet_Miss:SetText( strName )
		OtherPet_Miss:SetToolTip("")
		OtherPet_Miss_Text:SetToolTip("")
	end
	--命中率
	strName = Pet : Other_GetShootProbability(nIndex);
	if Pet:Other_IsPetMasterEffectActive(nIndex,0) == 1 or Pet:Other_GetPetCangpinEffect(nIndex,3) > 0 then
		effectStr = Pet:Other_GetPetMasterTotalEffect(nIndex,6) + Pet:Other_GetPetCangpinEffect(nIndex,6)
		OtherPet_ShootProbability:SetText( strName.."#G(+"..tostring(effectStr)..")"  )
		OtherPet_ShootProbability:SetToolTip("#{YSSJ_140818_70}")
		OtherPet_ShootProbability_Text:SetToolTip("#{YSSJ_140818_70}")
	else
		OtherPet_ShootProbability:SetText( strName)
		OtherPet_ShootProbability:SetToolTip("")
		OtherPet_ShootProbability_Text:SetToolTip("")
	end


	strName = Pet : Other_GetGrowRate(nIndex);
	OtherPet_Growth : SetText("#G未知")
	local nGrowLevel = Pet : Other_GetPetGrowLevel(nIndex,tonumber(strName));
	local strTbl = {"普通","优秀","杰出","卓越","完美"};

	if(nGrowLevel >= 0) then
		nGrowLevel = nGrowLevel + 1;	--c里是从0开始的枚举
		local nGrowRate = Pet : Other_GetGrowRate(nIndex);
		if(strTbl[nGrowLevel]) then
			OtherPet_Growth : SetText("#G"..strTbl[nGrowLevel]..nGrowRate)
		end
	end

	strName,strIcon = Pet : Other_GetAttackTrait(nIndex);

	if strIcon ~= "" then
		OtherPetAttack_Type : SetProperty( "Image", "set:Button6 image:"..strIcon )
		OtherPetAttack_Type : SetToolTip(strName)
		OtherPetAttack_Type : Show();
	end

	local SumPetSkill = GetActionNum("petskill");
	local k=1;
	local i=1;


	while i <= PETSKILL_BUTTONS_NUM do
		local theSkillAction = Pet:EnumPetSkill( 1000+nIndex, i-1, "petskill");
		i = i + 1;

		if theSkillAction:GetID() ~= 0 then

			PETSKILL_BUTTONS[k]:SetActionItem(theSkillAction:GetID());
			k = k+1;
		end


	end

	--zchw
	OtherPet_Refresh_Equip();

	local food = Pet : Other_GetFoodType(nIndex);
	local strFoodName = ""
	local strFoodType = ""

	if(food >= 1000) then
		strFoodName = strFoodName .. g_PetFoodType1[1];
		strFoodType = strFoodType .. g_PetFoodType2[1];
		food = food - 1000;
		if food > 0 then
			strFoodName = strFoodName .. "、";
			strFoodType = strFoodType .. "、";
		end
	end
	if(food >= 100) then
		strFoodName = strFoodName .. g_PetFoodType1[2];
		strFoodType = strFoodType .. g_PetFoodType2[2];
		food = food - 100;
		if food > 0 then
			strFoodName = strFoodName .. "、";
			strFoodType = strFoodType .. "、";
		end
	end
	if(food >= 10) then
		strFoodName = strFoodName .. g_PetFoodType1[3];
		strFoodType = strFoodType .. g_PetFoodType2[3];
		food = food - 10;
		if food > 0 then
			strFoodName = strFoodName .. "、";
			strFoodType = strFoodType .. "、";
		end
	end

	if(food >= 1) then
		strFoodName = strFoodName .. g_PetFoodType1[4];
		strFoodType = strFoodType .. g_PetFoodType2[4];
	end
	local strToShow = "";
	strToShow = ScriptGlobal_Format("#{XSLC_121220_10}", strFoodName, strFoodType)
	OtherPetFood_Type : Show();
	OtherPetFood_Type : SetToolTip( strToShow );

	OtherPet_Jian     : Show();

end

function OtherPetEquip_Equip_Click(num, type)
end

----------------------------------------------------------------------------------
--
-- 旋转珍兽模型（向左)
--
function OtherPet_Modle_TurnLeft(start)
	--向左旋转开始
	if start == 1 and CEArg:GetValue("MouseButton")=="LeftButton" then
		OtherPet_FakeObject:RotateBeginEx("My_OtherPet", -0.3)
	--向左旋转结束
	else
		OtherPet_FakeObject:RotateEndEx()
	end
end

----------------------------------------------------------------------------------
--
--旋转珍兽模型（向右)
--
function OtherPet_Modle_TurnRight(start)
	--向右旋转开始
	if start == 1 and CEArg:GetValue("MouseButton")=="LeftButton" then
		OtherPet_FakeObject:RotateBeginEx("My_OtherPet", 0.3)
	--向右旋转结束
	else
		OtherPet_FakeObject:RotateEndEx()
	end
end

function OtherPet_SetTabColor(idx)
	-- if(idx == nil or idx < 0 or idx > 3) then
		-- return;
	-- end


	-- local i = 0;
	-- local selColor = "#e010101#Y";
	-- local noselColor = "#e010101";
	-- local tab = {
								-- [0] = OtherPet_SelfEquip,
								-- OtherPet_TargetData,
								-- OtherPet_Miji,		--2013武林秘籍修改
								-- OtherPet_Pet,
								-- OtherPet_Ride,
								-- OtherPet_JingMai,
							-- };

	-- while i < 6 do
		-- if(i == idx) then
			-- tab[i]:SetText(selColor..PET_TAB_TEXT[i]);
		-- else
			-- tab[i]:SetText(noselColor..PET_TAB_TEXT[i]);
		-- end
		-- i = i + 1;
	-- end
end

function OtherPet_Open()
	this:Show();
	Pet : Other_SetSelectedIdx(0)
	OtherPet_List : SetItemSelectByItemID(0);
end
function OtherPet_Close()
	this:Hide();
	Pet : Other_SetSelectedIdx(0)
end

function OtherPet_OnHidden()
	OtherPet_FakeObject:DetachWindowEx("My_OtherPet")
end

function OtherPet_Skill_Clicked(nIndex)

end

--===============================================
-- 打开玩家装备UI
--===============================================
function OtherPet_TargetEquip_Down()
  Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenEquipFrame("other");
end

--===============================================
-- 打开玩家资料UI
--===============================================
function OtherPet_TargetData_Down()
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("other")
end

--神木王鼎
function OtherPet_TargetShenDing_Down()
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1);
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

function OtherPet_OtherRide_Down()
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenRidePage("other");
end

--武魂

function OtherPet_TargetWuhun_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherWuhun();
end

function OtherPet_Jian_Clicked()
	if(not (Pet:Other_IsPresent(PETNUM)) ) then
		return;
	end
	Pet:PetOpenPetJian(PETNUM,"other");
end

--经脉
function OtherPet_OtherJingMai_Down()
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherJingMai();
end

--真元
function OtherPet_ZhenYuan_Down()
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleTargetZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end

function OtherPet_TargetMiji_Down()
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherMiji();
	this:Hide()
end

function OtherPet_TargetHuanLing_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherHuanLing();
end

--获取玩家当前等级最大携带数量 --add by xindefeng
function GetOtherCurMaxPetCount()
	local mylevel = CachedTarget:GetData("LEVEL") --获取玩家等级
	if mylevel == nil or type(mylevel) ~= "number" then
		return 2;
	end
	local MaxCount = 0	--携带上限

	--根据等级获取常规携带上限
	if mylevel < 21 then
		MaxCount = 2	--一开始就携带上限就是2
	elseif mylevel < 41 then
		MaxCount = 3
	elseif mylevel < 61 then
		MaxCount = 4
	elseif mylevel < 81 then
		MaxCount = 5
	else
		MaxCount = 6
	end

	--携带上限再加上兽栏数量
	MaxCount = MaxCount + CachedTarget:GetData("PET_EXTRANUM")

	if MaxCount > PET_MAX_NUMBER then
		MaxCount = PET_MAX_NUMBER
	end

	return MaxCount
end

--added by dun.liu
function OtherPet_SetStateTooltip( nIndex )

	if (nIndex == nil) then
		return;
	end
	-- 得到状态属性
	local iIceAttack  		= Pet:Other_GetAttackCold( nIndex );
	local iFireAttack 		= Pet:Other_GetAttackFire( nIndex );
	local iThunderAttack	= Pet:Other_GetAttackLight( nIndex );
	local iPoisonAttack		= Pet:Other_GetAttackPoison( nIndex );

	local iIceDefine  		= Pet:Other_GetDefenceCold( nIndex );
	local iFireDefine 		= Pet:Other_GetDefenceFire( nIndex );
	local iThunderDefine	= Pet:Other_GetDefenceLight( nIndex );
	local iPoisonDefine		= Pet:Other_GetDefencePoison( nIndex );

	local iIceResistOther		= Pet:Other_GetResistCold( nIndex );
	local iFireResistOther		= Pet:Other_GetResistFire( nIndex );
	local iThunderResistOther	= Pet:Other_GetResistLight( nIndex );
	local iPoisonResistOther	= Pet:Other_GetResistPoison( nIndex );

	------------------------------
	if( iIceAttack == nil ) then
		iIceAttack = 0;
	end
	if( iFireAttack == nil ) then
		iFireAttack = 0;
	end
	if( iThunderAttack == nil ) then
		iThunderAttack = 0;
	end
	if( iPoisonAttack == nil ) then
		iPoisonAttack = 0;
	end
	------------------------------
	if( iIceDefine == nil ) then
		iIceDefine = 0;
	end

	if( iFireDefine == nil ) then
		iFireDefine = 0;
	end

	if( iPoisonDefine == nil ) then
		iPoisonDefine = 0;
	end
	if( iThunderDefine == nil ) then
		iThunderDefine = 0;
	end
	------------------------------
	if( iIceResistOther == nil ) then
		iIceResistOther = 0;
	end
	if( iFireResistOther == nil ) then
		iFireResistOther = 0;
	end
	if( iThunderResistOther == nil ) then
		iThunderResistOther = 0;
	end
	if( iPoisonResistOther == nil ) then
		iPoisonResistOther = 0;
	end


	OtherPet_IceFastness:SetToolTip("冰攻:"..tostring(iIceAttack).."#r冰抗:"..tostring(iIceDefine).."#r减冰抗:"..tostring(iIceResistOther) );
	OtherPet_FireFastness:SetToolTip("火攻:"..tostring(iFireAttack).."#r火抗:"..tostring(iFireDefine).."#r减火抗:"..tostring(iFireResistOther) );
	OtherPet_ThunderFastness:SetToolTip("玄攻:"..tostring(iThunderAttack).."#r玄抗:"..tostring(iThunderDefine).."#r减玄抗:"..tostring(iThunderResistOther) );
	OtherPet_PoisonFastness:SetToolTip("毒攻:"..tostring(iPoisonAttack).."#r毒抗:"..tostring(iPoisonDefine).."#r减毒抗:"..tostring(iPoisonResistOther) );

end

--added by dun.liu
function OtherPet_ClearStateTooltip()
	-- 得到状态属性
	local iIceAttack  		= 0;
	local iFireAttack 		= 0;
	local iThunderAttack	= 0;
	local iPoisonAttack		= 0;

	local iIceDefine  		= 0;
	local iFireDefine 		= 0;
	local iThunderDefine	= 0;
	local iPoisonDefine		= 0;

	local iIceResistOther		= 0;
	local iFireResistOther		= 0;
	local iThunderResistOther	= 0;
	local iPoisonResistOther	= 0;

	OtherPet_IceFastness:SetToolTip("冰攻:"..tostring(iIceAttack).."#r冰抗:"..tostring(iIceDefine).."#r减冰抗:"..tostring(iIceResistOther) );
	OtherPet_FireFastness:SetToolTip("火攻:"..tostring(iFireAttack).."#r火抗:"..tostring(iFireDefine).."#r减火抗:"..tostring(iFireResistOther) );
	OtherPet_ThunderFastness:SetToolTip("玄攻:"..tostring(iThunderAttack).."#r玄抗:"..tostring(iThunderDefine).."#r减玄抗:"..tostring(iThunderResistOther) );
	OtherPet_PoisonFastness:SetToolTip("毒攻:"..tostring(iPoisonAttack).."#r毒抗:"..tostring(iPoisonDefine).."#r减毒抗:"..tostring(iPoisonResistOther) );

end

function OtherPet_Frame_On_ResetPos()
  OtherPet_Frame:SetProperty("UnifiedPosition", g_OtherPet_Frame_UnifiedPosition);
end

function OtherPet_TargetInfant_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:Other_ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function OtherPet_YuShou_Page_Switch()

	if Player:GetData("Is2606S") == 1 then
		return
	end
	
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1)
	local nLevel = CachedTarget:GetData("LEVEL",1)
	if nLevel == nil or nLevel < 85 then
		PushDebugMessage( "对方等级不足85，尚未开启御兽之道" )
		OtherPet_Frame_Client_Button02:SetCheck(0)
	else
		local bRet = Lua_OpenOtherPetMasterPage(0)
		if bRet ~= 1 then
			OtherPet_Frame_Client_Button02:SetCheck(0)
		end
	end
end

function OtherPet_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage();
	if bRet == 1 then
		this:Hide()
	end
end

function OtherPet_OpenBaoJian()
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
end

function OtherPet_OpenWuYi()
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

function OtherPet_OpenShenQi()
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

function OtherPet_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

function OtherPet_PetNeiDan_Page_Switch()
	
	if Player:GetData("IsOriginalJD") == 1 then
		return
	end
	if Player:GetData("Is2606S") == 1 then
		return
	end
	
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1)
	Pet:LuaFnOpenPetNeiDan("other")
end

function OtherPet_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherPet_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end


function OtherPet_ShowPage()

	for i = 1, table.getn(g_OtherPet_Page) do
		g_OtherPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	OtherPet_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_OtherPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_OtherPet_Page) do
			if i ~= nOtherPageNumber then
				g_OtherPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_OtherPageOrder = {}
	g_OtherPageCount = 0
	for i = 1, table.getn(g_OtherPet_Page) do
		if OtherPet_CheckPage(i) == 1 then
			g_OtherPageCount = g_OtherPageCount + 1
			g_OtherPageButton[g_OtherPageCount]:Show()
			g_OtherPageButton[g_OtherPageCount]:SetText(g_OtherPet_Page[i].Text)	
			g_OtherPageOrder[g_OtherPageCount] = i
		end
	end
	
end

function OtherPet_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_OtherPageOrder[idx]
	
	if idx == 1 then--装备
		OtherPet_TargetEquip_Down();
	elseif idx == 2 then--资料
		OtherPet_TargetData_Down()
	elseif idx == 3 then--珍兽
		--OtherMartial_WuYi_Pet_Switch()
	elseif idx == 4 then--子女
		OtherPet_TargetInfant_Switch()
	elseif idx == 5 then--武魂
		OtherPet_TargetWuhun_Switch()
	elseif idx == 6 then--秘籍
		OtherPet_TargetMiji_Down()
	elseif idx == 7 then--真元
		OtherPet_ZhenYuan_Down()
	elseif idx == 8 then--经脉
		OtherPet_OtherJingMai_Down()
	elseif idx == 9 then--神鼎
		OtherPet_TargetShenDing_Down()
	elseif idx == 10 then--侠印
		OtherPet_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		OtherPet_OpenBaoJian()
	elseif idx == 12 then--武意
		OtherPet_OpenWuYi()
	elseif idx == 13 then--神器
		OtherPet_OpenShenQi()
	elseif idx == 14 then--星盘
		OtherPet_Armor_Page_Switch()
	elseif idx == 15 then--名物
		OtherPet_CangPin_Page_Switch()
	end
end

function OtherPet_CheckPage(idx)
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

function OtherPet_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end


