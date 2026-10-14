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

local PET_TYPE = {
[1] = {image = "set:CommonFrame2 image:ZhenShouHeart_Hui", tooltip1 = "#{FZDJ_120717_1}", tooltip2 = "#{FZDJ_120717_2}", tooltip3 = "#{FZDJ_120717_3}", tooltip4 = "#{FZDJ_120717_4}", tooltip5 = "#{FZDJ_120717_5}" },
[2] = {image = "set:CommonFrame2 image:ZhenShouHeart_Hong", tooltip1 = "#{FZDJ_120717_6}", tooltip2 = "#{FZDJ_120717_7}", tooltip3 = "#{FZDJ_120717_8}" } };

local ShowColor = "#H";
local PETSKILL_BUTTONS_NUM = 12;
local PETSKILL_BUTTONS = {};
local PETATTR = {};
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
------------------------------------------------------
--珍兽装备按钮数据定义 zchw
local g_Pet_Head; 		--头
local g_Pet_Claw;			--爪
local g_Pet_Body; 		--躯干
local g_Pet_Neck;			--项圈
local g_Pet_Charm;		--护符

------------------------------------------------------

-- 界面的默认相对位置
local g_Pet_Frame_UnifiedXPosition;
local g_Pet_Frame_UnifiedYPosition;

local g_Pet_Client_Button02_UnifiedPosition	
local g_Pet_Client_Button03_UnifiedPosition
	
--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_Pet_Page = {
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

local g_Pet_PageButton = {}
local g_Pet_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

--------------------------------------------
-- 提供长按左键进行连加的功能	-- HenryFour@2010-04-16
local g_AutoClick_BtnFlag = -1			-- 记录当前鼠标左键是在哪个按钮按下
local g_AutoClickTimer_Step = 144		-- 多少时间(毫秒)模拟一次 Click 操作
local g_AutoClick_FunList = {}			-- 将公用一个 Timer 的回调功能函数放到一个数组
local g_AutoClick_Going = -1			-- 标志是否开始自动点击操作(第一次LButton后经过X个Timer才算开始, 也就是说是 g_AutoClickTimer_Step * X 的时候开始进行自动加, 这样为了防止本来要点击一下的结果点了好多下)

local g_NeedTipID = -1
local g_NeedTipText = -1
local g_CurActFlash = 0
local g_CurProce = 0
local g_IsRecmmend = 0			--是否使用了珍兽自动加点
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

local g_CloseButton
local g_nShouLan_ItemInfo={
{item=30509500, YB=400},
{item=30509501, YB=1200},
{item=30509502, YB=1400},
{item=30509503, YB=1600}
}
local tabNeiDanLianHuaNeedGrowLevel =  --想要炼化需要的成长率
{
	{tl = 65,gl=1325},
	{tl = 75,gl=1443},
	{tl = 85,gl=1560},
	{tl = 95,gl=1677},
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
function Pet_PreLoad()
	this:RegisterEvent("TOGLE_PET_PAGE",true);
	this:RegisterEvent("UPDATE_PET_PAGE",false);
	this:RegisterEvent("DELETE_PET",false);
	this:RegisterEvent("ACCELERATE_KEYSEND",true);
	this:RegisterEvent("RESET_ALLUI",false);
	this:RegisterEvent("UPDATE_PET_EXTRANUM",false);
	this:RegisterEvent("UNIT_LEVEL",false);
	this:RegisterEvent("PET_EQUIP_ATTR_CHANGE",false)

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("NOTIFY_POP_UITIP",false)
	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK",false);		--升级
	this:RegisterEvent("TOGGLE_UPDATE_INFANT",false); --子女有变化 刷新按钮状态

	this:RegisterEvent("FINISH_MISSION",false);
	--界面互斥
	this:RegisterEvent("ONOPENBIEYEFURCREATE",false)
	this:RegisterEvent("MARTIAL_UPDATE",false)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)

	this:RegisterEvent("PLAYER_ENTERING_WORLD", false)
	this:RegisterEvent("NEIDAN_CHIP_UPDATE", false)
	
	this:RegisterEvent("PET_NEIDAN_LIANHUA_UPDATE")
end

function Pet_OnLoad()

	PETSKILL_BUTTONS[1] = Pet_Skill1;
	PETSKILL_BUTTONS[2] = Pet_Skill2;
	PETSKILL_BUTTONS[3] = Pet_Skill3;
	PETSKILL_BUTTONS[4] = Pet_Skill4;
	PETSKILL_BUTTONS[5] = Pet_Skill5;
	PETSKILL_BUTTONS[6] = Pet_Skill6;
	PETSKILL_BUTTONS[7] = Pet_Skill7;
	PETSKILL_BUTTONS[8] = Pet_Skill8;
	PETSKILL_BUTTONS[9] = Pet_Skill9;
	PETSKILL_BUTTONS[10] = Pet_Skill10;
	PETSKILL_BUTTONS[11] = Pet_Skill11;
	PETSKILL_BUTTONS[12] = Pet_Skill12;
	PET_AITYPE[0] = "胆小";
	PET_AITYPE[1] = "谨慎";
	PET_AITYPE[2] = "忠诚";
	PET_AITYPE[3] = "精明";
	PET_AITYPE[4] = "勇猛";

	PET_TAB_TEXT = {
		[0] = "装备",
		"资料",
		"珍兽",
		"骑乘",
		"其他",
		"经脉"
	};
	--------------------------
	--zchw
	g_Pet_Head = PetEquip_1;
	g_Pet_Claw = PetEquip_2;
	g_Pet_Body = PetEquip_3;
	g_Pet_Neck = PetEquip_4;
	g_Pet_Charm = PetEquip_5;
	--------------------------

	Pet_chenghao:SetText("称号");

	-- 保存界面的默认相对位置
	g_Pet_Frame_UnifiedXPosition	= Pet_Frame : GetProperty("UnifiedXPosition");
	g_Pet_Frame_UnifiedYPosition	= Pet_Frame : GetProperty("UnifiedYPosition");

	-- 初始化自动加点功能相关变量
	g_AutoClick_FunList[1] = Pet_Str_Add_Clicked
	g_AutoClick_FunList[2] = Pet_Int_Add_Clicked
	g_AutoClick_FunList[3] = Pet_PF_Add_Clicked
	g_AutoClick_FunList[4] = Pet_Sta_Add_Clicked
	g_AutoClick_FunList[5] = Pet_Dex_Add_Clicked
	g_AutoClick_FunList[6] = Pet_Str_Sub_Clicked
	g_AutoClick_FunList[7] = Pet_Int_Sub_Clicked
	g_AutoClick_FunList[8] = Pet_PF_Sub_Clicked
	g_AutoClick_FunList[9] = Pet_Sta_Sub_Clicked
	g_AutoClick_FunList[10] = Pet_Dex_Sub_Clicked

	g_AutoClick_Going = -1
	g_AutoClick_BtnFlag = -1
	g_CloseButton = Pet_Close
		
	g_Pet_PageButton[1] = Pet_SelfEquip
	g_Pet_PageButton[2] = Pet_SelfData
	g_Pet_PageButton[3] = Pet_Pet
	g_Pet_PageButton[4] = Pet_Infant
	g_Pet_PageButton[5] = Pet_Wuhun
	g_Pet_PageButton[6] = Pet_Xiulian
	g_Pet_PageButton[7] = Pet_Miji
	g_Pet_PageButton[8] = Pet_ZhenYuan
	g_Pet_PageButton[9] = Pet_JingMai
	g_Pet_PageButton[10] = Pet_ShenDing
	g_Pet_PageButton[11] = Pet_JueWei
	g_Pet_PageButton[12] = Pet_BaoJian
	g_Pet_PageButton[13] = Pet_WuYi
	g_Pet_PageButton[14] = Pet_ShenQi
	g_Pet_PageButton[15] = Pet_Armor
	g_Pet_PageButton[16] = Pet_CangPin
	g_Pet_PageButton[17] = Pet_OtherInfo
	
	g_Pet_PageMask[1] = Pet_SelfEquip_tips
	g_Pet_PageMask[2] = Pet_SelfData_tips
	g_Pet_PageMask[3] = Pet_Pet_tips
	g_Pet_PageMask[4] = Pet_Infant_tips
	g_Pet_PageMask[5] = Pet_Wuhun_tips
	g_Pet_PageMask[6] = Pet_Xiulian_tips
	g_Pet_PageMask[7] = Pet_Miji_tips
	g_Pet_PageMask[8] = Pet_ZhenYuan_tips
	g_Pet_PageMask[9] = Pet_JingMai_tips
	g_Pet_PageMask[10] = Pet_ShenDing_tips
	g_Pet_PageMask[11] = Pet_JueWei_tips
	g_Pet_PageMask[12] = Pet_BaoJian_tips
	g_Pet_PageMask[13] = Pet_WuYi_tips
	g_Pet_PageMask[14] = Pet_ShenQi_tips
	g_Pet_PageMask[15] = Pet_Armor_tips
	g_Pet_PageMask[16] = Pet_CangPin_tips
	g_Pet_PageMask[17] = Pet_OtherInfo_tips
		
	g_Pet_Client_Button02_UnifiedPosition = Pet_Client_Button02:GetProperty("UnifiedPosition")	
	g_Pet_Client_Button03_UnifiedPosition = Pet_Client_Button03:GetProperty("UnifiedPosition")
	
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

function Pet_OnEvent(event)
	-- 显示tooltips zchw
	Pet_SetStateTooltip();
	
	if ( event == "UPDATE_WILLGET_MISSION_TRACK" )  or (event=="TOGGLE_UPDATE_INFANT")  or (event == "FINISH_MISSION")  then
		local nLevel =Player:GetLevel()
		 Pet_Refresh_Page_Button(nLevel)
		 Pet_ShowPage()
	end

	if ( event == "TOGLE_PET_PAGE" ) then
		local arg0_cache = nil;
		if arg0 ~= nil and tonumber(arg0)~=nil and tonumber(arg0) < PET_MAX_NUMBER and tonumber(arg0) >= 0 then
			arg0_cache = tonumber(arg0)
		end

		if( this:IsVisible() ) then
			Pet_CloseFunction();
			return
		else
			Pet_Open();
		end
		for i=1,PET_ATTR_COUNT do
			PETATTR[i] = 0;
		end

		if arg0_cache ~= nil then
			PET_CURRENT_SELECT = arg0_cache
		end

		Pet_OnShown();
		local nLevel =Player:GetLevel()
		 Pet_Refresh_Page_Button(nLevel)
		 Pet_ShowPage()
		return;
	elseif ( event == "UPDATE_PET_PAGE") then
		if(this:IsVisible())then
			Pet_Update();
			if g_NeedTipID == 2 and Player:IsHaveCurrentPet() then
				Pet_CloseFunction()
			    --Pet_FreshManGuide(1, g_NeedTipText, 2)
			    g_NeedTipID = -1
			end
		else
			Pet_Update_NotVisible();
		end

		return;
	elseif( event == "ACCELERATE_KEYSEND" ) then
		Pet_HandleAccKey(arg0);
	elseif ( event == "DELETE_PET" ) then
		if(this:IsVisible())then
			for i=1,PET_ATTR_COUNT do
				PETATTR[i] = 0;
			end
			Pet_Update();
		else
			Pet_Update_NotVisible();
		end
	elseif(event == "RESET_ALLUI")then
		PET_CURRENT_SELECT = 0;
		Pet:SetSelectPetIdx(0);
	elseif(event == "UPDATE_PET_EXTRANUM" or event == "UNIT_LEVEL")then
		local nPetCount = Pet:GetPet_Count()
		local nMaxPetCount = GetMyCurMaxPetCount()
		Pet_List_Text:SetText("珍兽列表"..nPetCount.."/"..nMaxPetCount)--空格去掉

		local nShouLanCnt = tonumber(Player:GetData("PET_EXTRANUM"))--兽栏空间
		if nShouLanCnt>=4 then
			Pet_List_Text_Addition:Disable()
		else
			Pet_List_Text_Addition:Enable()
		end
	-- Tooltips 更新 zchw
	elseif(event == "PET_EQUIP_ATTR_CHANGE") then
		Pet_SetStateTooltip();

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		Pet_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		Pet_Frame_On_ResetPos()
    elseif "NOTIFY_POP_UITIP" == event and arg0 == "Pet" then
        g_NeedTipText = tonumber(arg1)
        g_NeedTipID = tonumber(arg2)
        if not this:IsVisible() then
            return
        end
        if g_NeedTipID == 1 and Player:IsHaveCurrentPet() then
            g_NeedTipID = -1
            return
        end
        Pet_FreshManGuide(1, g_NeedTipText, g_NeedTipID)
	elseif (event == "ONOPENBIEYEFURCREATE" and this:IsVisible()) then
		Pet_CloseFunction()
	elseif (event == "MARTIAL_UPDATE" or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		Pet_RefreshWuYiTip()
	end
	
	if event == "UPDATE_TOY_TIP" then
		Pet_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		Pet_RefreshCangPinTip()
	end
	
	if event == "PLAYER_ENTERING_WORLD" then
		if this:IsVisible() then
			this:Hide()
		end
		return
	end
	
	if event == "NEIDAN_CHIP_UPDATE" then
		Pet_Refresh_PetTip()
	end
	if  event == "PET_NEIDAN_LIANHUA_UPDATE"  then
		Pet_RefreshNeidanLianhuaTip()
	end

end

function Pet_HandleAccKey(op)
	if(op == "acc_pet") then
		if(this:IsVisible()) then
			Pet_CloseFunction();
			return;
		end

		--模拟收到了一个打开珍兽界面的事件。
		arg0 = "-1";
		Pet_OnEvent("TOGLE_PET_PAGE");
	end
end

function Pet_OnShown()
	
	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		Pet_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end


	Pet_SelfEquip : SetCheck(0);
	Pet_SelfData : SetCheck(0);
	Pet_Pet : SetCheck(1);
	Pet_Ride : SetCheck(0);
	Pet_Xiulian : SetCheck(0);
	Pet_OtherInfo : SetCheck(0);
	Pet_JingMai : SetCheck(0);
	
	Pet_Client_Button01:SetCheck(1)
	Pet_Client_Button02:SetCheck(0)
	Pet_Client_Button03:SetCheck(0)

	if Player:GetData("IsOriginalJD") == 1 then
		Pet_Client_Button04:Hide()
	else
		Pet_Client_Button04:Show()
	end
	
	if Player:GetData("Is2606S") == 1 then
		Pet_Client_Button02:Hide()
		Pet_Client_Button02:SetProperty("UnifiedPosition", g_Pet_Client_Button03_UnifiedPosition);
		Pet_Client_Button03:SetProperty("UnifiedPosition", g_Pet_Client_Button02_UnifiedPosition);
		Pet_Client_Button04:Hide()
	else
		Pet_Client_Button02:Show()
		Pet_Client_Button02:SetProperty("UnifiedPosition", g_Pet_Client_Button02_UnifiedPosition);
		Pet_Client_Button03:SetProperty("UnifiedPosition", g_Pet_Client_Button03_UnifiedPosition);
		Pet_Client_Button04:Show()
	end
	
	Pet_Accept:Disable();
	Pet_Cancel:Disable();
	Pet_Amend:Disable();
	Pet_Free:Disable();
	Pet_LockPet:Disable();
	Pet_Domesticate:Disable();
	Pet_Feed:Disable();
	Pet_YanShou_Button:Disable();
	Pet_Heti:Disable();
	Pet_Fenli:Disable();
	Pet_Rest:Disable();
	Pet_Campaign:Disable();
	Pet_Str_Addition:Disable();
	Pet_Int_Addition:Disable();
	Pet_Dex_Addition:Disable();
	Pet_PF_Addition:Disable();
	Pet_Sta_Addition:Disable();
	Pet_Str_Subtraction:Disable();
	Pet_Int_Subtraction:Disable();
	Pet_Dex_Subtraction:Disable();
	Pet_PF_Subtraction:Disable();
	Pet_Sta_Subtraction:Disable();
	Pet_Recommend:Disable();
	Pet_Page_Clear();

    g_Pet_Head : SetActionItem(-1);
	g_Pet_Claw : SetActionItem(-1);
	g_Pet_Body : SetActionItem(-1);
	g_Pet_Neck : SetActionItem(-1);
	g_Pet_Charm : SetActionItem(-1);
	
	Pet_FakeObject : AttachWindowEx( "My_Pet" );


	Pet_Update();


end

function Pet_Page_Clear()
	Pet_Accept:Disable();
	Pet_Cancel:Disable();
	Pet_Amend:Disable();
	Pet_Rest:Disable();
	Pet_Free:Disable();
	Pet_LockPet:Disable();
	Pet_Domesticate:Disable();
	Pet_Feed:Disable();
	Pet_YanShou_Button:Disable();
	Pet_Heti:Disable();
	Pet_Fenli:Disable();
	Pet_Campaign:Disable();
	Pet_Str_Addition:Disable();
	Pet_Int_Addition:Disable();
	Pet_Dex_Addition:Disable();
	Pet_PF_Addition:Disable();
	Pet_Sta_Addition:Disable();
	Pet_Str_Subtraction:Disable();
	Pet_Int_Subtraction:Disable();
	Pet_Dex_Subtraction:Disable();
	Pet_PF_Subtraction:Disable();
	Pet_Sta_Subtraction:Disable();
	Pet_Recommend:Disable();

	Pet_PetName : SetText( "" );
	Pet_PetName : Disable();
	Pet_Type : SetText("");

	Pet_PageHeader : SetText( "#gFF0FA0珍兽" );
	Pet_ConsortID : SetText( "" );
	Pet_PetID : SetText( "" );
	Pet_Sex : SetText("");
	Pet_HuanLing : Hide();
	Pet_Life : SetText( "" );
	Pet_Quick_Up_Animate:Hide();
	Pet_Happy : SetText("");
--	Pet_LoyalgGade : SetText( "" );
	Pet_Level : SetText( "" );
--	Pet_Type : SetText( "" );

	-- 清空融合度界面, 不显示tooltips
	Pet_Ronghedu : SetText("")
	Pet_Ronghedu : Disable()

	Pet_StrAptitude : SetText( "" );
	Pet_PhysicalStrengthAptitude : SetText( "" );
	Pet_DexterityAptitude : SetText( "" );
	Pet_NimbusAptitude : SetText( "" );
	Pet_StabilityAptitude : SetText( "" );
	Pet_Exp : SetText( "" );
	Pet_Blood : SetText( "" );
--	Pet_MP : SetText( "" .. " / " .. "" );
	Pet_Str : SetText( "" );
	--珍兽进阶
	Pet_Str_jieduan : SetText("")
	Pet_Nimbus_jieduan : SetText( "" );
	Pet_Pet_Dexterity_jieduan : SetText( "" );
	Pet_PhysicalStrength_jieduan : SetText( "" );
	Pet_Stability_jieduan : SetText( "" );
	Pet_jieduan : SetText("");
--	Pet_Str : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
	Pet_Nimbus : SetText( "" );
--	Pet_Nimbus : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
	Pet_Dexterity : SetText( "" );
--	Pet_Dexterity : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
	Pet_PhysicalStrength : SetText( "" );
--	Pet_PhysicalStrength : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
	Pet_Stability : SetText( "" );
--	Pet_Stability : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
	Pet_GenGu : SetText( "" );
	Pet_Potential : SetText( "" );
--	Pet_Potential : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
	Pet_PhysicsAttack : SetText( "" );
	Pet_MagicAttack : SetText( "" );
	Pet_PhysicsRecovery : SetText( "" );
	Pet_MagicRecovery : SetText( "" );
	Pet_Miss : SetText( "" );
	Pet_WuXing : SetText( "" );
	Pet_ShootProbability : SetText( "" );
	Pet_CriticalAttack:SetText("");
	Pet_CriticalDefence:SetText("")
	Pet_Growth : SetText("")
	Pet_Lingxing : SetText("")
	Pet_Lingxing_Info:SetText("")
	-------------------------------
	--zchw 44493
	Pet_Growth1 : SetText("")
	Pet_GenGu	: SetToolTip("")
	Pet_WuXing : SetToolTip("")
	Pet_Growth : SetToolTip("")
	Pet_Type : SetToolTip("")
	-------------------------------
	PetAttack_Type : Hide();
	for i=1, PETSKILL_BUTTONS_NUM do
		PETSKILL_BUTTONS[i]:SetActionItem(-1);
	end
	PetFood_Type : Hide();
	Pet_lock : Hide();
	Pet_Model_Protect_Text:SetText( "" );
	PET_POTREMAIN = 0
	Pet_Refresh_ADDSUB_Button();
	Pet_NeedLevel:SetText( "" );
	Pet_Jian : Hide();
	Pet_Peach : Hide();
	Pet_Quality_Text : SetText("")
	--设置珍兽数量信息--add by xindefeng
	local nPetCount = Pet:GetPet_Count()
	local nMaxPetCount = GetMyCurMaxPetCount()
	Pet_List_Text:SetText("珍兽列表"..nPetCount.."/"..nMaxPetCount)--空格去掉
end

function Pet_ListBox_Selected()

	PETNUM = Pet_List : GetFirstSelectItem();
	local nPetCount = Pet : GetPet_Count();

	if(PETNUM == PET_CURRENT_SELECT) then
		return;
	end

	if(PETNUM < 0 and nPetCount > 0) then
		PETNUM = PET_CURRENT_SELECT;
		return;
	end

	for i=1,PET_ATTR_COUNT do
		PETATTR[i] = 0;
	end

	Pet_Page_Clear();
	Changed_Name_Flag = 0;
	PET_CURRENT_SELECT = PETNUM;
	--PushDebugMessage("PETNUM2="..PETNUM)

	Pet : SetModel(PETNUM);


	Pet_Show_Appoint(PETNUM);

	Pet:NotifySelChange(PETNUM);

	local	tcount = Pet:GetTitleNum(PET_CURRENT_SELECT);
	if(tcount>0)then
		Pet_chenghao:Enable()
	else
		Pet_chenghao:Disable()
	end

	Pet_SetStateTooltip();
	Pet_Refresh_Equip()
end

function Pet_ListBox_RClicked()
	local clkNum = Pet_List : GetClickItem();

	if(clkNum >= 0) then
		Pet:CheckRClick(clkNum);
	end
end

function Pet_Update_NotVisible()
	local nPetCount = Pet : GetPet_Count();
	if nPetCount < 1 then
		PET_CURRENT_SELECT = -1;
		Pet:SetSelectPetIdx(-1);
		return;
	end
	local bSelect = 0;
	local firSel = -1;
	for	i=1, PET_MAX_NUMBER do
		if Pet:IsPresent(i-1) then
			if(firSel == -1)then
				firSel = i-1;
			end
			if( i-1 == PET_CURRENT_SELECT) then
				bSelect = 1;
			end
		end
	end
	--有选中对象的，才进行选中操作。
	if bSelect == 1 then
		--do nothing
	else
		PET_CURRENT_SELECT = firSel;
		Pet:SetSelectPetIdx(firSel);
	end
end

function Pet_Update()
	Pet_chenghao:Disable()
	Pet_SelfEquip : SetCheck(0);
	Pet_SelfData : SetCheck(0);
	Pet_Pet : SetCheck(1);
	Pet_Ride : SetCheck(0);
	Pet_OtherInfo : SetCheck(0);
	Pet_JingMai : SetCheck(0);
	Pet_FakeObject : Hide()
	local nPetCount = Pet : GetPet_Count();

	local szPetName;

	local nIsBaiShou = Pet:GetIsBaiShou()
	if(nIsBaiShou == 1) and (nPetCount > 0)then
		Pet_Proficient_Text:Show()
		--Pet_Proficient_Text:SetToolTip("1111111")
	else
		Pet_Proficient_Text:Hide()
	end
	local nShouLanCnt = tonumber(Player:GetData("PET_EXTRANUM"))--兽栏空间
	if nShouLanCnt>=4 then
		Pet_List_Text_Addition:Disable()
	else
		Pet_List_Text_Addition:Enable()
	end
	Pet_Page_Clear();
	Pet_List : ClearListBox();
	if nPetCount < 1 then
		PET_CURRENT_SELECT = -1;
		Pet:SetSelectPetIdx(-1);
		--zchw
		OneKeyUnEquip:Disable();
		Pet_Neidan_Lianhua_Mask:Hide() --默认不蒙红
		Pet_Neidan_Lianhua:Hide()
		return;
	end

	local bSelect = 0;
	local firSel = -1;
	for	i=1, PET_MAX_NUMBER do
		if Pet:IsPresent(i-1) then
			if(firSel == -1)then
				firSel = i-1;
			end
			szPetName = Pet : GetPetList_Appoint(i-1);


			if(Pet : GetIsFighting(i-1)) then
				Pet_List : AddItem(szPetName, i-1,"FF0A9605");
			--	PushDebugMessage("i1="..PETNUM)
			elseif (Pet:GetIsPossession(i-1)) then
				Pet_List : AddItem(szPetName, i-1,"FF996699");
			else
				Pet_List : AddItem(szPetName, i-1);
			end
			if( i-1 == PET_CURRENT_SELECT) then
				bSelect = 1;
			end
			--这里必须有这么2句，要不会出错。
			Pet_DisableAddButton();
			Pet_DisableSubButton();
		end
	end
	local tcount = 0;
	--有选中对象的，才进行选中操作。
	if bSelect == 1 then
		Pet_List : SetItemSelectByItemID(PET_CURRENT_SELECT);
		Pet_FakeObject : Show()
		Pet : SetModel(PET_CURRENT_SELECT);
		Pet_Show_Appoint(PET_CURRENT_SELECT);
		tcount = Pet:GetTitleNum(PET_CURRENT_SELECT);
		if(tcount>0)then
			Pet_chenghao:Enable()
		end
	else
		PET_CURRENT_SELECT = firSel;
		if(firSel == -1)then
			Pet:SetSelectPetIdx(-1);
			--zchw
			OneKeyUnEquip:Disable();
			return;
		end
		Pet_List : SetItemSelectByItemID(PET_CURRENT_SELECT);
		Pet_FakeObject : Show()
		Pet : SetModel(PET_CURRENT_SELECT);
		Pet_Show_Appoint(PET_CURRENT_SELECT);
		tcount = Pet:GetTitleNum(PET_CURRENT_SELECT);
		if(tcount>0)then
			Pet_chenghao:Enable()
		end
	end

	if PET_CURRENT_SELECT > PET_MAX_NUMBER then
		PET_CURRENT_SELECT = PET_MAX_NUMBER;
	end

	Pet_PetName:SetProperty("DefaultEditBox", "False");
	local strNeedLevel;
	local strNeedLevelColor;
	local nTakeLevel = Pet:GetTakeLevel(PET_CURRENT_SELECT );
	local nTakeLevel_BaiShou = nTakeLevel
	local nIsBaiShou = Pet:GetIsBaiShou()
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
	Pet_NeedLevel:SetText( strNeedLevel );
	local nQuality = Pet:GetPetQuality(PET_CURRENT_SELECT );
	if nQuality > 0 and nQuality <= 7 then
		Pet_Quality_Text:SetText( g_Quality_Str[nQuality]  )
	end
end

--zchw
function PetEquip_Equip_Click(num, type)
	if num == 1 then
		if type == 1 then
			g_Pet_Head : DoAction();
		elseif type == 0 then
			g_Pet_Head : DoSubAction();
		end
	elseif num == 2 then
		if type == 1 then
			g_Pet_Claw : DoAction();
		elseif type == 0 then
			g_Pet_Claw : DoSubAction();
		end
	elseif num == 3 then
		if type == 1 then
			g_Pet_Body : DoAction();
		elseif type == 0 then
			g_Pet_Body : DoSubAction();
		end
	elseif num == 4 then
		if type == 1 then
			g_Pet_Neck : DoAction();
		elseif type == 0 then
			g_Pet_Neck : DoSubAction();
		end
	elseif num == 5 then
		if type == 1 then
			g_Pet_Charm : DoAction();
		elseif type == 0 then
			g_Pet_Charm : DoSubAction();
		end
	end
end

--zchw
function Pet_Refresh_Equip()
	--  清空按钮显示图标
	g_Pet_Head : SetActionItem(-1);
	g_Pet_Claw : SetActionItem(-1);
	g_Pet_Body : SetActionItem(-1);
	g_Pet_Neck : SetActionItem(-1);
	g_Pet_Charm : SetActionItem(-1);

	local ActionClaw 		= EnumAction(5*PET_CURRENT_SELECT, "my_pet_equip");
	local ActionHead		= EnumAction(5*PET_CURRENT_SELECT + 1, "my_pet_equip");
	local ActionBody  	= EnumAction(5*PET_CURRENT_SELECT + 2, "my_pet_equip");
	local ActionNeck   	= EnumAction(5*PET_CURRENT_SELECT + 3, "my_pet_equip");
	local ActionCharm   = EnumAction(5*PET_CURRENT_SELECT + 4, "my_pet_equip");
--	PushDebugMessage("PET_CURRENT_SELECT="..PET_CURRENT_SELECT)
--    PushDebugMessage("1="..ActionHead : GetID().." 2="..ActionClaw : GetID().." 3="..ActionBody : GetID().." 4="..ActionNeck : GetID().." 5="..ActionCharm : GetID())
	g_Pet_Head : SetActionItem(ActionHead : GetID());
	g_Pet_Claw : SetActionItem(ActionClaw : GetID());
	g_Pet_Body : SetActionItem(ActionBody : GetID());
	g_Pet_Neck : SetActionItem(ActionNeck : GetID());
	g_Pet_Charm : SetActionItem(ActionCharm : GetID());

end

--zchw
function Pet_SetStateTooltip()

	-- 得到状态属性
	local iIceAttack  		= Pet:GetData( "ATTACKCOLD" );
	local iFireAttack 		= Pet:GetData( "ATTACKFIRE" );
	local iThunderAttack	= Pet:GetData( "ATTACKLIGHT" );
	local iPoisonAttack		= Pet:GetData( "ATTACKPOISON" );

	local iIceDefine  		= Pet:GetData( "DEFENCECOLD" );
	local iFireDefine 		= Pet:GetData( "DEFENCEFIRE" );
	local iThunderDefine	= Pet:GetData( "DEFENCELIGHT" );
	local iPoisonDefine		= Pet:GetData( "DEFENCEPOISON" );

	local iIceResistOther	= Pet:GetData( "RESISTOTHERCOLD" );
	local iFireResistOther= Pet:GetData( "RESISTOTHERFIRE" );
	local iThunderResistOther	= Pet:GetData( "RESISTOTHERLIGHT" );
	local iPoisonResistOther= Pet:GetData( "RESISTOTHERPOISON" );

	Pet_IceFastness:SetToolTip("冰攻:"..tostring(iIceAttack).."#r冰抗:"..tostring(iIceDefine).."#r减冰抗:"..tostring(iIceResistOther) );
	Pet_FireFastness:SetToolTip("火攻:"..tostring(iFireAttack).."#r火抗:"..tostring(iFireDefine).."#r减火抗:"..tostring(iFireResistOther) );
	Pet_ThunderFastness:SetToolTip("玄攻:"..tostring(iThunderAttack).."#r玄抗:"..tostring(iThunderDefine).."#r减玄抗:"..tostring(iThunderResistOther) );
	Pet_PoisonFastness:SetToolTip("毒攻:"..tostring(iPoisonAttack).."#r毒抗:"..tostring(iPoisonDefine).."#r减毒抗:"..tostring(iPoisonResistOther) );

end

function Pet_Show_Appoint(nIndex)

	local i;

	if(not (Pet:IsPresent(nIndex)) ) then
		return;
	end
	Pet:SetSelectPetIdx(nIndex);
	Pet_Accept:Disable();
	Pet_Cancel:Disable();
	Pet_Amend:Enable();
	Pet_Rest:Enable();
	Pet_Free:Enable();
	Pet_LockPet:Enable();
	Pet_Domesticate:Enable();
	Pet_Feed:Enable();
	Pet_YanShou_Button:Enable();
	Pet_Heti:Enable();
	Pet_Fenli:Enable();
	Pet_Campaign:Enable();

	Pet_Str_Addition:Disable();
	Pet_Int_Addition:Disable();
	Pet_Dex_Addition:Disable();
	Pet_PF_Addition:Disable();
	Pet_Sta_Addition:Disable();
	Pet_Str_Subtraction:Disable();
	Pet_Int_Subtraction:Disable();
	Pet_Dex_Subtraction:Disable();
	Pet_PF_Subtraction:Disable();
	Pet_Sta_Subtraction:Disable();
	Pet_Peach:Show();

	local effectStr = ""

	for i=1, PETSKILL_BUTTONS_NUM do
		PETSKILL_BUTTONS[i]:SetActionItem(-1);
	end

 	local strName = Pet:GetAIType(nIndex);

	local strAI;
	if(strName>4 or strName <0) then
		strAI = "错误";
	else
		strAI =	PET_AITYPE[strName];
	end

	local strName2 = ""
 	strName,strName2 = Pet:GetName(nIndex);
	local nEra, strTypeName = Pet:GetPetTypeName(nIndex);
 	if( 1 == nEra ) then
 	    strName2 = "二代"..strTypeName
 	end


 	Pet_PageHeader : SetText("#gFF0FA0"..strName2);
 	Pet_Type :SetText("#gFF8E92"..strAI);
 	Changed_Name = Pet_PetName : GetText();

 	if(PlayerPackage:IsPetLock(nIndex) == 1) then
	 	Pet_lock : Show();

	 	local nUnlockElapsedTime = PlayerPackage:GetPUnlockElapsedTime_Pet(nIndex);
	 	if( nUnlockElapsedTime ==0) then
	 		Pet_lock : SetProperty("Image","set:UIIcons image:Icon_Lock");
	 		Pet_lock : SetToolTip ("已加锁");
	 	else
	 		local strLeftTime = g_GetUnlockingStr(nUnlockElapsedTime);
	 		Pet_lock : SetProperty("Image","set:CommonFrame6 image:NewLock");
	 		Pet_lock : SetToolTip (strLeftTime);
	 	end

	else
	 	Pet_lock : Hide();
 end

  if(PlayerPackage:IsGoodsProtect_Pet(nIndex) == 1) then
	 	Pet_Model_Protect_Text : Show();
	 	Pet_Model_Protect_Text : SetText( "#{GDWPBH_090507_4}" );
	else
	 	Pet_Model_Protect_Text : Hide();
  end


--	if Changed_Name_Flag == 1 then
--		Pet_PetName : SetText( strName );
	if Changed_Name ~= strName and Changed_Name ~= "" then
		Pet_PetName : Enable();
--		PET_ORIGINAL_NAME = strName;
	else
		Pet_PetName : Enable();
		Pet_PetName : SetText( strName );
		Pet_PetName : SetProperty("ClearOffset" ,"True" )
	end

--	Pet_PageHeader : SetText( strAI .. strName2 );

	strName,strName2,sex = Pet : GetID(nIndex);
	Pet_PetID : SetText( "珍兽ID:"..strName2 );


	strName = Pet : GetConsort(nIndex);
	if(strName == "00000000") then
		strName = "";
	end;
	Pet_ConsortID : SetText( "配偶ID:"..strName );

	if(sex == 1) then
		strName = "雄性";
	else
		strName = "雌性";
	end
	local nGeneration  = Pet : GetGeneration(nIndex)
	if nGeneration ~= nil and nGeneration >= 100 then
		strName = "#{RXZS_XML_35}";
	end
	--炼化内丹标志相关 
	Pet_RefreshNeidanLianhuaTip()
	--该珍兽的繁殖情况
	local nPetType = Pet : GetPetType(nIndex);
	local nColor = 1;
	if (nGeneration == 1) then
		--1:二代
		nColor = 1;
		Pet_Peach : SetToolTip(PET_TYPE[1].tooltip4);
	elseif (nGeneration >= 100) then
		-->=100:幻化
		nColor = 1;
		Pet_Peach : SetToolTip(PET_TYPE[1].tooltip1);
	else
		if (nPetType == 0) then
			--0:宝宝 2022年6月 修改 由记录 上次繁殖等级 改成记录 已经繁殖次数
			--由于要兼容之前的数据，再更新后没繁殖之前 这个数值仍然记录上次繁殖等级，繁殖之后记录已经繁殖次数
			local nLevel = Pet:GetLevel(nIndex);
			local nLastProcreateLevel = Pet:GetLastProcreateLevel(nIndex);
			if nLastProcreateLevel < 0 then
				nLastProcreateLevel = 0
			end
			local nTarget = {30, 50, 70, 90, 110}
			local nTimes = 0
			local nCounts = 0
			local nRemainCounts = 0
			if nLastProcreateLevel >= 30 then --没修改过之前
				if nLastProcreateLevel >= nTarget[5] then
					nRemainCounts = 0
				else
					for i = 1, table.getn(nTarget) do
						if nLastProcreateLevel < nTarget[i] then
							nTimes = i - 1
							break
						end
					end
					for i = 1, table.getn(nTarget) do
						if nLevel < nTarget[i] then
							nCounts = i - 1
							break
						end
					end
					if nLevel >= nTarget[5] then
						nCounts = 5
					end

					nRemainCounts = nCounts - nTimes
				end
			else
				if nLevel >= nTarget[5] then
					nCounts = 5
				else
					for i = 1, table.getn(nTarget) do
						if nLevel < nTarget[i] then
							nCounts = i - 1
							break
						end
					end
				end
				nRemainCounts = nCounts - nLastProcreateLevel
			end

			if nRemainCounts > 0 or nLevel < nTarget[5] then
				nColor = 2
			else
				nColor = 1
			end
			Pet_Peach : SetToolTip(ScriptGlobal_Format("#{ZSFZYH_220606_01}", nRemainCounts));

		elseif (nPetType == 1) then
			--1:变异
			nColor = 1;
			Pet_Peach : SetToolTip(PET_TYPE[1].tooltip3);
		elseif (nPetType == 2) then
			--2:成年
			nColor = 1;
			Pet_Peach : SetToolTip(PET_TYPE[1].tooltip2);
		end
	end
	Pet_Peach : SetProperty("Image", PET_TYPE[nColor].image);


	Pet_Sex : SetText( strName );
	
	--幻灵
	local nHuanlingId = Pet:GetHuanlingIdByIndex(nIndex)
	if nHuanlingId >= 0 then
		local strName = Pet:Lua_GetPetHuanLingInfo(nHuanlingId, "Name")
		local strStyle = Pet:Lua_GetPetHuanLingInfo(nHuanlingId, "ExText")
		Pet_HuanLing : SetText("#{ZSHP_180814_05}")
		Pet_HuanLing : SetToolTip(ScriptGlobal_Format("#{ZSHP_180814_06}", strName, strStyle))
		Pet_HuanLing : Show()
	end
	
	local strNeedLevel;
	local strNeedLevelColor;
	local nTakeLevel = Pet:GetTakeLevel(nIndex);
	local nTakeLevel_BaiShou = nTakeLevel
	local nIsBaiShou = Pet:GetIsBaiShou()
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
	Pet_NeedLevel:SetText( strNeedLevel );
	
	local nQuality = Pet:GetPetQuality(nIndex );
	if nQuality > 0 and nQuality <= 7 then
		Pet_Quality_Text:SetText( g_Quality_Str[nQuality]  )
	end

	strName = Pet : GetNaturalLife(nIndex);
--	strName2 = Pet:	GetMaxLife(nIndex);
	if strName < 2200 then
		Pet_Life : SetText( "寿命:".."#cFF0000"..strName );
		Pet_Quick_Up_Animate:Show()
	else
		Pet_Life : SetText( "寿命:"..strName );
		Pet_Quick_Up_Animate:Hide()
	end

--	strName = Pet : GetLoyalgGade(nIndex);
--	Pet_LoyalgGade : SetText( strName );

--	strName = Pet : GetBasic(nIndex);
--	Pet_GenGu : SetText( "根骨:"..strName );

	strName = Pet : GetLevel(nIndex);
	Pet_Level : SetText( "等级:"..strName );

--	strName = Pet : GetType(nIndex);
--	Pet_Type : SetText( "第".. tostring(strName).."代" );

	strName = Pet : GetHappy(nIndex);
	Pet_Happy : SetText( "快乐:"..strName );

	strName = Pet : GetLixing(nIndex);
	Pet_Lingxing : SetText("#{RXZS_XML_28}"..strName)

	strName = Pet : GetPercent_Lx(nIndex)
	if tonumber(strName) ~= nil and tonumber(strName) > 0 then
		local rateStr = string.format("%0.1f" , strName / 10.0)
		Pet_Lingxing_Info:SetText("#cFF00FF(+"..rateStr.."%)")
	end

	strName = Pet : GetFitValue(nIndex);
	Pet_Ronghedu : SetText( "#{ZSHT_XML_04}:"..strName );
	Pet_Ronghedu : Enable()
	-- 注意, 必须把悟性放在最后, 因为后面计算珍兽一级属性加成的时候要用到, 并且直接用的 strName

	strName = Pet : GetSavvy(nIndex);
	Pet_WuXing : SetText( "悟性:"..strName );

	local WuXingVal = tonumber(strName);
	strName = Pet : GetStrAptitude(nIndex);
	if(WuXingTbl[WuXingVal])then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")";
	end

	if (Pet:GetIsPossession(nIndex)) and (Player:IsPetMasterEffectActive(1) == 1 or DataPool:LuaFnGetCangPinSetEffectLevel(0) > 0) then
		effectStr = Pet:GetPetMasterTotalEffectValue(nIndex,9)
		Pet_StrAptitude:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		if(WuXingTbl[WuXingVal])then
			Pet_StrAptitude:SetToolTip("#{YSSJ_140818_59}")
			Pet_StrAptitude_Text:SetToolTip("#{YSSJ_140818_59}")
		else
			Pet_StrAptitude:SetToolTip("#{YSSJ_140818_103}")
			Pet_StrAptitude_Text:SetToolTip("#{YSSJ_140818_103}")
		end
	else
		Pet_StrAptitude:SetText( strName )
		Pet_StrAptitude:SetToolTip("")
		Pet_StrAptitude_Text:SetToolTip("")
	end

	strName = Pet : GetIntAptitude(nIndex);
	if(WuXingTbl[WuXingVal])then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")";
	end

	if (Pet:GetIsPossession(nIndex)) and (Player:IsPetMasterEffectActive(1) == 1 or DataPool:LuaFnGetCangPinSetEffectLevel(0) > 0) then
		effectStr = Pet:GetPetMasterTotalEffectValue(nIndex,10)
		Pet_NimbusAptitude:SetText( strName.."#G(+"..tostring(effectStr)..")"  )
		if(WuXingTbl[WuXingVal])then
			Pet_NimbusAptitude:SetToolTip("#{YSSJ_140818_60}")
			Pet_NimbusAptitude_Text:SetToolTip("#{YSSJ_140818_60}")
		else
			Pet_NimbusAptitude:SetToolTip("#{YSSJ_140818_104}")
			Pet_NimbusAptitude_Text:SetToolTip("#{YSSJ_140818_104}")
		end
	else
		Pet_NimbusAptitude:SetText( strName )
		Pet_NimbusAptitude:SetToolTip("")
		Pet_NimbusAptitude_Text:SetToolTip("")
	end


	strName = Pet : GetPFAptitude(nIndex);
	if(WuXingTbl[WuXingVal])then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")";
	end

	if (Pet:GetIsPossession(nIndex)) and (Player:IsPetMasterEffectActive(1) == 1 or DataPool:LuaFnGetCangPinSetEffectLevel(0) > 0) then
		effectStr = Pet:GetPetMasterTotalEffectValue(nIndex,11)
		Pet_PhysicalStrengthAptitude:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		if(WuXingTbl[WuXingVal])then
			Pet_PhysicalStrengthAptitude:SetToolTip("#{YSSJ_140818_61}")
			Pet_PhysicalStrengthAptitude_Text:SetToolTip("#{YSSJ_140818_61}")
		else
			Pet_PhysicalStrengthAptitude:SetToolTip("#{YSSJ_140818_105}")
			Pet_PhysicalStrengthAptitude_Text:SetToolTip("#{YSSJ_140818_105}")
		end
	else
		Pet_PhysicalStrengthAptitude:SetText( strName )
		Pet_PhysicalStrengthAptitude:SetToolTip("")
		Pet_PhysicalStrengthAptitude_Text:SetToolTip("")
	end

	strName = Pet : GetStaAptitude(nIndex);
	if(WuXingTbl[WuXingVal])then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")";
	end

	if (Pet:GetIsPossession(nIndex)) and (Player:IsPetMasterEffectActive(1) == 1 or DataPool:LuaFnGetCangPinSetEffectLevel(0) > 0) then
		effectStr = Pet:GetPetMasterTotalEffectValue(nIndex,12)
		Pet_StabilityAptitude:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		if(WuXingTbl[WuXingVal])then
			Pet_StabilityAptitude:SetToolTip("#{YSSJ_140818_62}")
			Pet_StabilityAptitude_Text:SetToolTip("#{YSSJ_140818_62}")
		else
			Pet_StabilityAptitude:SetToolTip("#{YSSJ_140818_106}")
			Pet_StabilityAptitude_Text:SetToolTip("#{YSSJ_140818_106}")
		end
	else
		Pet_StabilityAptitude:SetText( strName )
		Pet_StabilityAptitude:SetToolTip("")
		Pet_StabilityAptitude_Text:SetToolTip("")
	end

	strName = Pet : GetDexAptitude(nIndex);
	if(WuXingTbl[WuXingVal])then
		strName = (WuXingTbl[WuXingVal].color)..strName..ShowColor.."(+"..(WuXingTbl[WuXingVal].per)..")";
	end

	if (Pet:GetIsPossession(nIndex)) and (Player:IsPetMasterEffectActive(1) == 1 or DataPool:LuaFnGetCangPinSetEffectLevel(0) > 0) then
		effectStr = Pet:GetPetMasterTotalEffectValue(nIndex,13)
		Pet_DexterityAptitude:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		if(WuXingTbl[WuXingVal])then
			Pet_DexterityAptitude:SetToolTip("#{YSSJ_140818_63}")
			Pet_FootworkAptitude_Text:SetToolTip("#{YSSJ_140818_63}")
		else
			Pet_DexterityAptitude:SetToolTip("#{YSSJ_140818_107}")
			Pet_FootworkAptitude_Text:SetToolTip("#{YSSJ_140818_107}")
		end
	else
		Pet_DexterityAptitude:SetText( strName )
		Pet_DexterityAptitude:SetToolTip("")
		Pet_FootworkAptitude_Text:SetToolTip("")
	end

	strName,strName2 = Pet : GetExp(nIndex);
	Pet_Exp : SetText( "经验:"..strName .."/"..strName2);
--yy说，不空格
	strName = Pet : GetHP(nIndex);
	strName2 = Pet:	GetMaxHP(nIndex);
	if (Pet: GetIsFighting(nIndex)) and (Player:IsPetMasterEffectActive(0) == 1 or Pet:GetPetCangpinEffectValue(nIndex,3) > 0) then
		effectStr = Pet:GetPetMasterTotalEffectValue(nIndex,0) + Pet:GetPetCangpinEffectValue(nIndex,0)
		Pet_Blood:SetText( "血:"..strName .."/".. strName2.."#G(+"..tostring(effectStr)..")" )
		Pet_Blood:SetToolTip("#{YSSJ_140818_64}")
	else
		Pet_Blood:SetText( "血:"..strName .."/".. strName2)
		Pet_Blood:SetToolTip("")
	end


--	strName = Pet : GetMP(nIndex);
--	strName2 = Pet:	GetMaxMP(nIndex);
--	Pet_MP : SetText( strName .." / ".. strName2);
	--珍兽进阶 废除珍兽传承标志
	--local bJinJieImpact = Pet : GetJinJieImpact(nIndex);
	local nJinJieGrade = Pet : GetJinJieGrade(nIndex);
	local nJinJieLevel = Pet : GetJinJieLvl(nIndex);
	if nTakeLevel < PET_JINJIE_LIMIT_BYTLVL then
		Pet_jieduan:SetText("#{JJKHD_120808_21}");
		Pet_jieduan:SetToolTip("#{JJKHD_120808_35}");
	elseif nJinJieGrade == PET_JINJIELVL_MAXGRADE then
		Pet_jieduan:SetText("#{JJKHD_120808_24}");
		Pet_jieduan:SetToolTip("#{JJKHD_120808_37}");
	elseif nJinJieGrade < PET_JINJIELVL_MAXGRADE then
		if g_NumToStrTable[nJinJieGrade + 1] ~= nil and g_NumToStrTable[nJinJieLevel + 1] ~= nil then
			local szCurJinJieInfo = ScriptGlobal_Format("#{JJKHD_120808_22}", g_NumToStrTable[nJinJieGrade + 1], g_NumToStrTable[nJinJieLevel + 1])
			Pet_jieduan:SetText(szCurJinJieInfo);
		end
		Pet_jieduan:SetToolTip("#{JJKHD_120808_36}");
	end

	local strJinJie = 0
	local SprJinJie = 0
	local DexJinJie = 0
	local ConJinJie = 0
	local IntJinJie = 0
	if(nJinJieGrade > 0 or nJinJieLevel > 0) then
		Pet_Str_jieduan:Show()
		Pet_Nimbus_jieduan:Show()
		Pet_Pet_Dexterity_jieduan:Show()
		Pet_PhysicalStrength_jieduan:Show()
		Pet_Stability_jieduan:Show()


		strJinJie = Pet : GetJinJieStr(nIndex);	--力量
		Pet_Str_jieduan : SetText("+"..tonumber(strJinJie))

		SprJinJie = Pet : GetJinJieSpr(nIndex);	--灵气
		Pet_Nimbus_jieduan : SetText("+"..tonumber(SprJinJie))

		DexJinJie = Pet : GetJinJieDex(nIndex);	--身法
		Pet_Pet_Dexterity_jieduan : SetText("+"..tonumber(DexJinJie))

		ConJinJie = Pet : GetJinJieCon(nIndex);	--体力
		Pet_PhysicalStrength_jieduan : SetText("+"..tonumber(ConJinJie))

		IntJinJie = Pet : GetJinJieINT(nIndex);	--定力
		Pet_Stability_jieduan : SetText("+"..tonumber(IntJinJie))
	else
		Pet_Str_jieduan:Hide()
		Pet_Nimbus_jieduan:Hide()
		Pet_Pet_Dexterity_jieduan:Hide()
		Pet_PhysicalStrength_jieduan:Hide()
		Pet_Stability_jieduan:Hide()
	end

	strName = Pet : GetStr(nIndex);
	Pet_Str : SetText( tonumber(strName - strJinJie) + PETATTR[1] );

	strName = Pet : GetInt(nIndex);
	Pet_Nimbus : SetText( tonumber(strName - SprJinJie) + PETATTR[2] );

	strName = Pet : GetDex(nIndex);
	Pet_Dexterity : SetText( tonumber(strName - DexJinJie) + PETATTR[3] );

	strName = Pet : GetPF(nIndex);
	Pet_PhysicalStrength : SetText( tonumber(strName - ConJinJie) + PETATTR[4] );

	strName = Pet : GetSta(nIndex);
	Pet_Stability : SetText( tonumber(strName - IntJinJie) + PETATTR[5] );


	strName = Pet : GetBasic(nIndex);
	Pet_GenGu : SetText( "根骨:"..tonumber(strName) );

	if(Pet : GetIsFighting(nIndex)) and (Player:IsPetMasterEffectActive(0) == 1 or Pet:GetPetCangpinEffectValue(nIndex,3) > 0) then
		effectStr = Pet:GetPetMasterTotalEffectValue(nIndex,7) + Pet:GetPetCangpinEffectValue(nIndex,7)
		Pet_CriticalAttack : SetText( tostring(Pet:GetCriticalAttack(nIndex)).."#G(+"..tostring(effectStr)..")"   )
		Pet_CriticalAttack:SetToolTip("#{YSSJ_140818_71}")
		Pet_CriticalAttack_Text:SetToolTip("#{YSSJ_140818_71}")
	else
		Pet_CriticalAttack:SetText( Pet:GetCriticalAttack(nIndex)  )
		Pet_CriticalAttack:SetToolTip("")
		Pet_CriticalAttack_Text:SetToolTip("")
	end

	if(Pet : GetIsFighting(nIndex)) and (Player:IsPetMasterEffectActive(0) == 1 or Pet:GetPetCangpinEffectValue(nIndex,3) > 0) then
		effectStr = Pet:GetPetMasterTotalEffectValue(nIndex,8) + Pet:GetPetCangpinEffectValue(nIndex,8)
		Pet_CriticalDefence : SetText(tostring(Pet:GetCriticalDefence(nIndex)).."#G(+"..tostring(effectStr)..")" )
		Pet_CriticalDefence:SetToolTip("#{YSSJ_140818_72}")
		Pet_CriticalDefence_Text:SetToolTip("#{YSSJ_140818_72}")
	else
		Pet_CriticalDefence : SetText(Pet:GetCriticalDefence(nIndex) )
		Pet_CriticalDefence:SetToolTip("")
		Pet_CriticalDefence_Text:SetToolTip("")
	end

	strName = Pet : GetPotential(nIndex);
	strName2 = tonumber(strName);
	local Sum_Attr = 0;
	for i=1,PET_ATTR_COUNT do
		Sum_Attr = Sum_Attr + PETATTR[i];
	end
	strName2 = strName2 - Sum_Attr;
	--出现这种情况是
	if(strName2 < 0) then
	 strName2 = 0
	 for i=1,PET_ATTR_COUNT do
			PETATTR[i] = 0;
	 end
	end
	PET_POTREMAIN = strName2



	Pet_Potential : SetText( strName2 );
--	Pet_Potential : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
	Pet_Refresh_ADDSUB_Button();

	strName = Pet : GetPhysicsAttack(nIndex);
	if(Pet : GetIsFighting(nIndex)) and (Player:IsPetMasterEffectActive(0) == 1 or Pet:GetPetCangpinEffectValue(nIndex,3) > 0) then
		effectStr = Pet:GetPetMasterTotalEffectValue(nIndex,1) + Pet:GetPetCangpinEffectValue(nIndex,1)
		Pet_PhysicsAttack : SetText( strName.."#G(+"..tostring(effectStr)..")" )
		Pet_PhysicsAttack:SetToolTip("#{YSSJ_140818_65}")
		Pet_PhysicsAttack_Text:SetToolTip("#{YSSJ_140818_65}")
	else
		Pet_PhysicsAttack : SetText( strName )
		Pet_PhysicsAttack:SetToolTip("")
		Pet_PhysicsAttack_Text:SetToolTip("")
	end

	strName = Pet : GetMagicAttack(nIndex);
	if(Pet : GetIsFighting(nIndex)) and (Player:IsPetMasterEffectActive(0) == 1 or Pet:GetPetCangpinEffectValue(nIndex,3) > 0) then
		effectStr = Pet:GetPetMasterTotalEffectValue(nIndex,2) + Pet:GetPetCangpinEffectValue(nIndex,2)
		Pet_MagicAttack : SetText( strName.."#G(+"..tostring(effectStr)..")" )
		Pet_MagicAttack:SetToolTip("#{YSSJ_140818_66}")
		Pet_MagicAttack_Text:SetToolTip("#{YSSJ_140818_66}")
	else
		Pet_MagicAttack : SetText( strName )
		Pet_MagicAttack:SetToolTip("")
		Pet_MagicAttack_Text:SetToolTip("")
	end

	strName = Pet : GetPhysicsRecovery(nIndex);
	if(Pet : GetIsFighting(nIndex)) and (Player:IsPetMasterEffectActive(0) == 1 or Pet:GetPetCangpinEffectValue(nIndex,3) > 0) then
		effectStr = Pet:GetPetMasterTotalEffectValue(nIndex,3) + Pet:GetPetCangpinEffectValue(nIndex,3)
		Pet_PhysicsRecovery:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		Pet_PhysicsRecovery:SetToolTip("#{YSSJ_140818_67}")
		Pet_PhysicsRecovery_Text:SetToolTip("#{YSSJ_140818_67}")
	else
		Pet_PhysicsRecovery:SetText( strName)
		Pet_PhysicsRecovery:SetToolTip("")
		Pet_PhysicsRecovery_Text:SetToolTip("")
	end

	strName = Pet : GetMagicRecovery (nIndex);
	if(Pet : GetIsFighting(nIndex)) and (Player:IsPetMasterEffectActive(0) == 1 or Pet:GetPetCangpinEffectValue(nIndex,3) > 0) then
		effectStr = Pet:GetPetMasterTotalEffectValue(nIndex,4) + Pet:GetPetCangpinEffectValue(nIndex,4)
		Pet_MagicRecovery:SetText( strName.."#G(+"..tostring(effectStr)..")" )
		Pet_MagicRecovery:SetToolTip("#{YSSJ_140818_68}")
		Pet_MagicRecovery_Text:SetToolTip("#{YSSJ_140818_68}")
	else
		Pet_MagicRecovery:SetText( strName )
		Pet_MagicRecovery:SetToolTip("")
		Pet_MagicRecovery_Text:SetToolTip("")
	end

	strName = Pet : GetGrowRate(nIndex);
	-----------------------------------------
	-- zchw 44493
	Pet_Growth1 : SetText("#{ZS_CZL}");
	Pet_GenGu : SetToolTip("#{INTERFACE_XML_287}");
	Pet_WuXing : SetToolTip("#{INTERFACE_XML_733}");
	Pet_Growth : SetToolTip("#{INTERFACE_XML_986}")
	Pet_Type : SetToolTip("#{INTERFACE_XML_857}")
	-----------------------------------------
	Pet_Growth : SetText("#G未知")
	local nGrowLevel = Pet : GetPetGrowLevel(nIndex,tonumber(strName));
	local strTbl = {"普通","优秀","杰出","卓越","完美"};

	if(nGrowLevel >= 0) then
		nGrowLevel = nGrowLevel + 1;	--c里是从0开始的枚举
		local nGrowRate = Pet : GetGrowRate(nIndex);
		if(strTbl[nGrowLevel]) then
			Pet_Growth : SetText("#G"..strTbl[nGrowLevel]..nGrowRate)
		end
	end

	--闪避率
	strName = Pet : GetMiss(nIndex);
	if(Pet : GetIsFighting(nIndex)) and (Player:IsPetMasterEffectActive(0) == 1 or Pet:GetPetCangpinEffectValue(nIndex,3) > 0) then
		effectStr = Pet:GetPetMasterTotalEffectValue(nIndex,5) + Pet:GetPetCangpinEffectValue(nIndex,5)
		Pet_Miss : SetText( strName.."#G(+"..tostring(effectStr)..")" )
		Pet_Miss:SetToolTip("#{YSSJ_140818_69}")
		Pet_Miss_Text:SetToolTip("#{YSSJ_140818_69}")
	else
		Pet_Miss : SetText( strName )
		Pet_Miss:SetToolTip("")
		Pet_Miss_Text:SetToolTip("")
	end

	--命中率
	strName = Pet : GetShootProbability(nIndex)
	if(Pet : GetIsFighting(nIndex)) and (Player:IsPetMasterEffectActive(0) == 1 or Pet:GetPetCangpinEffectValue(nIndex,3) > 0) then
		effectStr = Pet:GetPetMasterTotalEffectValue(nIndex,6) + Pet:GetPetCangpinEffectValue(nIndex,6)
		Pet_ShootProbability : SetText( strName.."#G(+"..tostring(effectStr)..")"  )
		Pet_ShootProbability:SetToolTip("#{YSSJ_140818_70}")
		Pet_ShootProbability_Text:SetToolTip("#{YSSJ_140818_70}")
	else
		Pet_ShootProbability : SetText( strName)
		Pet_ShootProbability:SetToolTip("")
		Pet_ShootProbability_Text:SetToolTip("")
	end

	strName,strIcon = Pet : GetAttackTrait(nIndex);

	if strIcon ~= "" then
		PetAttack_Type : SetProperty( "Image", "set:Button6 image:"..strIcon )
		PetAttack_Type : SetToolTip(strName)
		PetAttack_Type : Show();
	end

	local SumPetSkill = GetActionNum("petskill");
	local k=1;
	local i=1;


	while i <= PETSKILL_BUTTONS_NUM do
		local theSkillAction = Pet:EnumPetSkill( nIndex, i-1, "petskill");
		i = i + 1;
		if theSkillAction:GetID() ~= 0 then

			PETSKILL_BUTTONS[k]:SetActionItem(theSkillAction:GetID());
			k = k+1;

--		if( (theSkillAction : GetPetSkillOwner() == nIndex) and (k <= PETSKILL_BUTTONS_NUM ) ) then
--			PETSKILL_BUTTONS[k]:SetActionItem(theSkillAction:GetID());

--			k = k + 1;
--		else
--			PETSKILL_BUTTONS[i]:SetActionItem(-1);
		end

--	PETSKILL_DESC[i]:SetText(theSkillAction:GetName());
	end

	-- 珍兽装备 zchw
	----------------------------------------
	Pet_Refresh_Equip();
	if Pet:IsPetHaveEquip(nIndex) == 1 then
		OneKeyUnEquip:Enable();
	else
		OneKeyUnEquip:Disable();
	end
	---------------------------------------

	if (Pet:GetIsPossession(nIndex)) then
		Pet_Heti:Hide()
		Pet_Fenli:Show()
	else
		Pet_Fenli:Hide()
		Pet_Heti:Show()
	end

	if(Pet : GetIsFighting(nIndex)) then
		Pet_Campaign : Hide();
		Pet_Rest : Show();

	else
		Pet_Rest : Hide();
		Pet_Campaign : Show();

	end

	local food = Pet : GetFoodType(nIndex);
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
	PetFood_Type : Show();
	PetFood_Type : SetToolTip( strToShow );

	Pet_Jian : Show();

	if( PET_POTREMAIN + PETATTR[1] + PETATTR[2] + PETATTR[3] + PETATTR[4] + PETATTR[5]  >0 ) then
		Pet_Recommend:Enable();
	else
		Pet_Recommend:Disable();
	end

	local isLock = Pet : GetExpLock(nIndex);
	if isLock == 1 then
		Pet_Exp_LevelUpLock_Opening:Hide()
		Pet_Exp_LevelUpLock_Locked:SetToolTip("#{ZSSJ_20240918_9}")
		Pet_Exp_LevelUpLock_Locked:Show()
	else
		Pet_Exp_LevelUpLock_Opening:Show()
		Pet_Exp_LevelUpLock_Opening:SetToolTip("#{ZSSJ_20240918_1}")
		Pet_Exp_LevelUpLock_Locked:Hide()
	end
end

function Pet_Str_Add_Clicked()
	if( PET_POTREMAIN >0 ) then
		g_IsRecmmend = 0
		PETATTR[1] = PETATTR[1] +1;
		PET_POTREMAIN = PET_POTREMAIN - 1;
		Pet_Potential : SetText( PET_POTREMAIN );
--		Pet_Potential : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
		Pet_Str : SetText( Pet_Str : GetText() + 1 );
--		Pet_Str : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
	Pet_Str_Subtraction:Enable()
	end
	if( PET_POTREMAIN <=0 ) then
--		Pet_Str_Addition:Disable();
		Pet_DisableAddButton();
	end
end

function Pet_Int_Add_Clicked()
	if( PET_POTREMAIN >0 ) then
		g_IsRecmmend = 0
		PETATTR[2] = PETATTR[2] +1;
		PET_POTREMAIN = PET_POTREMAIN - 1;
		Pet_Potential : SetText( PET_POTREMAIN );
--		Pet_Potential : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
		Pet_Nimbus : SetText( Pet_Nimbus : GetText() + 1 );
--		Pet_Nimbus : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
		Pet_Int_Subtraction:Enable();
	end
	if( PET_POTREMAIN <=0 ) then
--		Pet_Int_Addition:Disable();
		Pet_DisableAddButton();
	end
end

function Pet_Dex_Add_Clicked()
	if( PET_POTREMAIN >0 ) then
		g_IsRecmmend = 0
		PETATTR[3] = PETATTR[3] +1;
		PET_POTREMAIN = PET_POTREMAIN - 1;
		Pet_Potential : SetText( PET_POTREMAIN );
--		Pet_Potential : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
		Pet_Dexterity : SetText( Pet_Dexterity : GetText() + 1 );
--		Pet_Dexterity : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
		Pet_Dex_Subtraction:Enable();
	end
	if( PET_POTREMAIN <=0 ) then
--		Pet_Dex_Addition:Disable();
		Pet_DisableAddButton();
	end
end

function Pet_PF_Add_Clicked()
	if( PET_POTREMAIN >0 ) then
		g_IsRecmmend = 0
		PETATTR[4] = PETATTR[4] +1;
		PET_POTREMAIN = PET_POTREMAIN - 1;
		Pet_Potential : SetText( PET_POTREMAIN );
--		Pet_Potential : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
		Pet_PhysicalStrength : SetText( Pet_PhysicalStrength : GetText() + 1 );
--		Pet_PhysicalStrength : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
		Pet_PF_Subtraction:Enable();
	end
	if( PET_POTREMAIN <=0 ) then
--		Pet_PF_Addition:Disable();
		Pet_DisableAddButton();
	end
end

function Pet_Sta_Add_Clicked()
	if( PET_POTREMAIN >0 ) then
		g_IsRecmmend = 0
		PETATTR[5] = PETATTR[5] +1;
		PET_POTREMAIN = PET_POTREMAIN - 1;
		Pet_Potential : SetText( PET_POTREMAIN );
--		Pet_Potential : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
		Pet_Stability : SetText( Pet_Stability : GetText() + 1 );
--		Pet_Stability : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
		Pet_Sta_Subtraction:Enable();
	end
	if( PET_POTREMAIN <=0 ) then
--		Pet_Sta_Addition:Disable();
		Pet_DisableAddButton();
	end
end

function Pet_Str_Sub_Clicked()
	if( PETATTR[1] >0 ) then
		g_IsRecmmend = 0
		PETATTR[1] = PETATTR[1] -1;
		PET_POTREMAIN = PET_POTREMAIN + 1;
		Pet_Potential : SetText( PET_POTREMAIN );
--		Pet_Potential : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
		Pet_Str : SetText( Pet_Str : GetText() - 1 );
--		Pet_Str : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
--		Pet_Str_Addition:Enable();
		Pet_EnableAddButton();
	end
	if( PETATTR[1] <= 0 ) then
		Pet_Str_Subtraction:Disable();
	end
end

function Pet_Int_Sub_Clicked()
	if( PETATTR[2] >0 ) then
		g_IsRecmmend = 0
		PETATTR[2] = PETATTR[2] -1;
		PET_POTREMAIN = PET_POTREMAIN + 1;
		Pet_Potential : SetText( PET_POTREMAIN );
--		Pet_Potential : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
		Pet_Nimbus : SetText( Pet_Nimbus : GetText() - 1 );
--		Pet_Nimbus : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
--		Pet_Int_Addition:Enable();
		Pet_EnableAddButton();
	end
	if( PETATTR[2] <= 0 ) then
		Pet_Int_Subtraction:Disable();
	end
end

function Pet_Dex_Sub_Clicked()
	if( PETATTR[3] >0 ) then
		g_IsRecmmend = 0
		PETATTR[3] = PETATTR[3] -1;
		PET_POTREMAIN = PET_POTREMAIN + 1;
		Pet_Potential : SetText( PET_POTREMAIN );
--		Pet_Potential : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
		Pet_Dexterity : SetText( Pet_Dexterity : GetText() - 1 );
--		Pet_Dexterity : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
--		Pet_Dex_Addition:Enable();
		Pet_EnableAddButton();
	end
	if( PETATTR[3] <= 0 ) then
		Pet_Dex_Subtraction:Disable();
	end
end

function Pet_PF_Sub_Clicked()
	if( PETATTR[4] >0 ) then
		g_IsRecmmend = 0
		PETATTR[4] = PETATTR[4] -1;
		PET_POTREMAIN = PET_POTREMAIN + 1;
		Pet_Potential : SetText( PET_POTREMAIN );
--		Pet_Potential : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
		Pet_PhysicalStrength : SetText( Pet_PhysicalStrength : GetText() - 1 );
--		Pet_PhysicalStrength : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
--		Pet_PF_Addition:Enable();
		Pet_EnableAddButton();
	end
	if( PETATTR[4] <= 0 ) then
		Pet_PF_Subtraction:Disable();
	end
end

function Pet_Sta_Sub_Clicked()
	if( PETATTR[5] >0 ) then
		g_IsRecmmend = 0
		PETATTR[5] = PETATTR[5] -1;
		PET_POTREMAIN = PET_POTREMAIN + 1;
		Pet_Potential : SetText( PET_POTREMAIN );
--		Pet_Potential : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
		Pet_Stability : SetText( Pet_Stability : GetText() - 1 );
--		Pet_Stability : SetProperty("TextColours","tl:FFFEE601 tr:FFFEE601 bl:FFFEE601 br:FFFEE601");
--		Pet_Sta_Addition:Enable();
		Pet_EnableAddButton();
	end
	if( PETATTR[5] <= 0 ) then
		Pet_Sta_Subtraction:Disable();
	end
end

function Pet_Accept_Clicked()
	if(not (Pet:IsPresent(PETNUM)) ) then
		return;
	end
	--if(PlayerPackage:IsPetLock(PETNUM) == 1)    then
	--	PushDebugMessage("珍兽已加锁")
	--	for i=1,PET_ATTR_COUNT do
	--		PETATTR[i] = 0;
	--	end
	--	Pet_Show_Appoint(PETNUM);
	--	return;
	--end
	if(tonumber(DataPool:GetLeftProtectTime()) >0)    then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		for i=1,PET_ATTR_COUNT do
			PETATTR[i] = 0;
		end
		Pet_Show_Appoint(PETNUM);
		return;
	end
 	Pet : Add_Attribute(PETNUM ,PETATTR[1] ,PETATTR[2], PETATTR[3], PETATTR[4], PETATTR[5]);
	for i=1,PET_ATTR_COUNT do
		PETATTR[i] = 0;
	end

	if( g_IsRecmmend == 1 ) then
		--日志
		local hid,lid = Pet:GetGUID(PET_CURRENT_SELECT)
		local AttackTraitID = Pet : GetAttackTraitID(PET_CURRENT_SELECT)
		Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("PetRecommendAuditLog")
		Set_XSCRIPT_ScriptID(800105)
		Set_XSCRIPT_Parameter(0,hid)
		Set_XSCRIPT_Parameter(1,lid)
		Set_XSCRIPT_Parameter(2,AttackTraitID)
		Set_XSCRIPT_ParamCount(3)
		Send_XSCRIPT();
	end

	g_IsRecmmend = 0

end

function Pet_Cancel_Clicked()
	if(not (Pet:IsPresent(PETNUM)) ) then
		return;
	end

	for i=1,PET_ATTR_COUNT do
		PETATTR[i] = 0;
	end

	Pet_Show_Appoint(PETNUM);
end

--推荐加点
function Pet_Recommend_Clicked()
	if( PET_POTREMAIN + PETATTR[1] + PETATTR[2] + PETATTR[3] + PETATTR[4] + PETATTR[5]  >0 ) then
		local AttackTraitID = Pet : GetAttackTraitID(PET_CURRENT_SELECT)
		if( AttackTraitID == 11 ) then			--外功攻击型珍兽
			Pet_Recommend_Distribute(1)

		elseif( AttackTraitID == 12 ) then	--内功攻击型珍兽
			Pet_Recommend_Distribute(2)

		elseif( AttackTraitID == 13 or  AttackTraitID == 10 ) then	--平衡攻击型珍兽 or 无类型珍兽
			local Aptitude = {
				{ index = 1,value = tonumber(Pet : GetStrAptitude(PET_CURRENT_SELECT)) },		--力量
				{ index = 2,value = tonumber(Pet : GetIntAptitude(PET_CURRENT_SELECT)) },		--灵气
				{ index = 3,value = tonumber(Pet : GetDexAptitude(PET_CURRENT_SELECT)) },		--身法
				{ index = 4,value = tonumber(Pet : GetPFAptitude(PET_CURRENT_SELECT)) },		--体力
			}
			--排序
			local IsHigher = function( a, b )
								return (a.value > b.value)
							  end

			table.sort(Aptitude, IsHigher)
			--计算并列第一的数量
			local maxnum = 1
			for i=2,4 do
				if( Aptitude[i].value == Aptitude[1].value ) then
					maxnum = maxnum + 1
				end
			end

			if( maxnum == 1 ) then
				Pet_Recommend_Distribute(Aptitude[1].index)
			else
				--并列第一中是否存在灵气、力量、身法
				local targetindex = 0
				for i=1,maxnum do
					if( Aptitude[i].index == 2 ) then
						targetindex = 2
					end
				end

				if( targetindex == 0 ) then
					for i=1,maxnum do
						if( Aptitude[i].index == 1 ) then
							targetindex = 1
						end
					end
				end

				if( targetindex == 0 ) then
					targetindex = 4
				end

				Pet_Recommend_Distribute(targetindex)
			end
		end

	else																				--这块应该走不到
		PushDebugMessage("#{ZSZDJD_130812_03}")		--该珍兽尚无可分配的潜能点。
		Pet_CloseFunction()
	end
end

function Pet_Recommend_Distribute(nindex)
	local Str = tonumber(Pet : GetStr(PET_CURRENT_SELECT)) - tonumber(Pet : GetJinJieStr(PET_CURRENT_SELECT))								--力量
	local Nimbus = tonumber(Pet : GetInt(PET_CURRENT_SELECT)) - tonumber(Pet : GetJinJieSpr(PET_CURRENT_SELECT))						--灵气
	local Dexterity = tonumber(Pet : GetDex(PET_CURRENT_SELECT)) - tonumber(Pet : GetJinJieDex(PET_CURRENT_SELECT))					--身法
	local PhysicalStrength = tonumber(Pet : GetPF(PET_CURRENT_SELECT)) - tonumber(Pet : GetJinJieCon(PET_CURRENT_SELECT))			--体力
	local Stability = tonumber(Pet : GetSta(PET_CURRENT_SELECT)) - tonumber(Pet : GetJinJieINT(PET_CURRENT_SELECT))						--定力

	PETATTR[nindex] = PET_POTREMAIN + PETATTR[1] + PETATTR[2] + PETATTR[3] + PETATTR[4] + PETATTR[5]
	for i = 1,5 do
		if(i ~= nindex) then
			PETATTR[i] = 0
		end
	end
	PET_POTREMAIN = 0
	Pet_Potential : SetText( PET_POTREMAIN )
	Pet_Str : SetText( Str + PETATTR[1] )
	Pet_Nimbus : SetText( Nimbus + PETATTR[2] )
	Pet_Dexterity : SetText( Dexterity + PETATTR[3] )
	Pet_PhysicalStrength : SetText( PhysicalStrength + PETATTR[4] )
	Pet_Stability : SetText( Stability + PETATTR[5] )

	Pet_Refresh_ADDSUB_Button()

	g_IsRecmmend = 1

end

-- 珍兽附体
function Pet_Possession_Clicked()
	-- 已经提交到指定界面容器的珍兽不能出战
	if (IsWindowShow("PetSavvy") and Pet:GetPetLocation(PETNUM) == 12)			-- 用成年珍兽提升珍兽悟性
		or (IsWindowShow("PetSavvyGGD")	and Pet:GetPetLocation(PETNUM) == 3)	-- 用根骨丹提升珍兽悟性
		or (IsWindowShow("MissionReply") and Pet:GetPetLocation(PETNUM) == 7)	-- 任务提交物品或珍兽
		or (IsWindowShow("PetHuanhua") and Pet:GetPetLocation(PETNUM) == 5)		-- 珍兽在幻化，位置为5
		or (IsWindowShow("PetRHD") and Pet:GetPetLocation(PETNUM) == 17)		-- 提升珍兽融合度
		then
		-- 珍兽处于提交状态，无法附体。
		PushDebugMessage("#{ZSHT_BC_1008_05}")
		return
	end
	Pet:PossessionPet(PETNUM)
end

-- 珍兽分离
function Pet_Restore_Clicked()
	Pet:RestorePet(PETNUM)
end

function Pet_Relax_Clicked()
	Pet:Go_Relax(PETNUM);

	if g_NeedTipText == 13 then
        if "Pet" == GetFreshManGuideOwner() then
            CloseFreshManGuide() --一旦点击,清除引导
        end
        g_NeedTipText = -1
    end
end

function Pet_Fight_Clicked()
	-- 已经提交到指定界面容器的珍兽不能出战
	if (IsWindowShow("PetSavvy") and Pet:GetPetLocation(PETNUM) == 12)			-- 用成年珍兽提升珍兽悟性
		or (IsWindowShow("PetSavvyGGD")	and Pet:GetPetLocation(PETNUM) == 3)	-- 用根骨丹提升珍兽悟性
		or (IsWindowShow("MissionReply") and Pet:GetPetLocation(PETNUM) == 7)	-- 任务提交物品或珍兽
		or (IsWindowShow("PetHuanhua") and Pet:GetPetLocation(PETNUM) == 5)		-- 珍兽在幻化，位置为5
		or (IsWindowShow("PetRHD") and Pet:GetPetLocation(PETNUM) == 17)		-- 提升珍兽融合度
		then
		-- "珍兽处于提交状态，无法出战。"
		PushDebugMessage("#{ZSTJZT_090904}")
		return
	end

	Pet	:	Go_Fight(PETNUM);

    if g_NeedTipID == 1 then
        if "Pet" == GetFreshManGuideOwner() then
            CloseFreshManGuide() --一旦点击,清除引导
        end
        g_NeedTipID = 2
        g_NeedTipText = 13
    end
end

function Pet_Free_Clicked()

    -- 如果还在安全时间内，则无法释放珍兽
    if(tonumber(DataPool:GetLeftProtectTime()) >0)    then
		PushDebugMessage("#{OR_PILFER_LOCK_FLAG}")
		return;
	end

	if(Pet : GetIsFighting(PETNUM)) then
		--此为BUG 3921中杨婷的原话，在策划案中并没有该需求。
		--但项目紧急，没时间确认，所以就以BUG系统为准。
		PushDebugMessage("珍兽正在出战，不能被放生")
		return;
	end

	if (Pet:GetIsPossession(PETNUM)) then
		PushDebugMessage("珍兽已被附身，不能被放生")
		return
	end

	if(PlayerPackage:IsPetLock(PETNUM) == 1)    then
		PushDebugMessage("珍兽已加锁")
		return;
	end

	if Pet:GetPetLocation(PETNUM) ~= -1 then
		PushDebugMessage("珍兽正在进行其他操作，不能放生。")
		return;
	end

    -- 如果此时该珍兽正在被放生：已经发送“确认放生”的封包消息给服务器端
    -- 服务器端还没有返回相应封包，此处为了同步，
    if Pet:IsFreeing(PETNUM) == 1 then
        --- #H该珍兽正在进行其他操作，不能放生。
		PushDebugMessage("#{RXZSBC_101028_06}")
        return;
    end

	Pet	:	Free_Confirm(PETNUM);

	if g_NeedTipID == 3 then
    	if "Pet" == GetFreshManGuideOwner() then
            CloseFreshManGuide()   --一旦点击,清除引导
        end
        g_NeedTipID = -1
    end
end

function Pet_LockPet_Clicked()
	PlayerPackage:OpenLockFrame(2);
end

function Pet_Feed_Clicked()
	Pet:Feed(PETNUM);
end

function Pet_YanShou_Clicked()

	if( tonumber( IsInStall() ) == 1 ) then
		PushDebugMessage("#{ResultText_119}")			--摆摊状态无法进行这种操作。
		return
	end

	if( PET_CURRENT_SELECT < 0 ) then
		PushDebugMessage("#{ZSYSYH_130812_02}")			--请先选择需要进行延寿的珍兽。
		return
	end

	if( Pet: GetNaturalLife( PET_CURRENT_SELECT ) >= Pet: GetMaxLife( PET_CURRENT_SELECT ) ) then
		PushDebugMessage("#{ZSYSYH_130812_03}")			--此珍兽寿命已达上限。
		return
	end

	--优先扣除绑定的，其次优先扣除增加寿命少的，再次优先扣除配表绑定的珍兽延年丹
	local bagIndex, bindstate = PlayerPackage:FindFirstBindedItemIdxByIDTable( 30606023 )
	if bagIndex == nil or bagIndex < 0 or bindstate == 0 then
		bagIndex, bindstate = PlayerPackage:FindFirstBindedItemIdxByIDTable( 30606001 )
		if bagIndex == nil or bagIndex < 0 or bindstate == 0 then
			bagIndex, bindstate = PlayerPackage:FindFirstBindedItemIdxByIDTable( 30606024 )
			if bagIndex == nil or bagIndex < 0 or bindstate == 0 then
				bagIndex, bindstate = PlayerPackage:FindFirstBindedItemIdxByIDTable( 30606002 )
				if bagIndex == nil or bagIndex < 0 or bindstate == 0 then
					bagIndex = PlayerPackage:GetBagPosByItemIndex( 30606023 )
					if bagIndex == nil or bagIndex < 0 then
						bagIndex = PlayerPackage:GetBagPosByItemIndex( 30606001 )
						if bagIndex == nil or bagIndex < 0 then
							bagIndex = PlayerPackage:GetBagPosByItemIndex( 30606024 )
							if bagIndex == nil or bagIndex < 0 then
								bagIndex = PlayerPackage:GetBagPosByItemIndex( 30606002 )
								if bagIndex == nil or bagIndex < 0 then
									local hid,lid = Pet:GetGUID(PET_CURRENT_SELECT);
									Clear_XSCRIPT();
									Set_XSCRIPT_Function_Name("PetSkillStudy_YanShou");
									Set_XSCRIPT_ScriptID(311111);
									Set_XSCRIPT_Parameter(0,1);
									Set_XSCRIPT_Parameter(1,hid);
									Set_XSCRIPT_Parameter(2,lid);
									Set_XSCRIPT_ParamCount(3);
									Send_XSCRIPT(); 
									return; 
								end
							end
						end
					end
				end
			end
		end
	end

	Pet:SkillStudy_Do(3, PET_CURRENT_SELECT, bagIndex);

end

function Pet_Dome_Clicked()
	Pet:Dome(PETNUM);
end

function Pet_AmendName_Clicked()
	if(not (Pet:IsPresent(PETNUM)) ) then
		return;
	end
	local strName = Pet_PetName : GetText()
	Changed_Name_Flag = 0;
	
	local szOldName,szName2 = Pet:GetName(PETNUM);
	if szOldName == strName then
		PushDebugMessage("#{MCCS_260302_2}")
		return
	end
	
	if string.len(strName) <= 0 then
		Pet:Change_Name(PETNUM, "")
		return
	end

	if(string.len(strName) < 2  or string.len(strName) > 12 ) then
		PushDebugMessage("#{MCCS_260302_5}")
		Pet_Update();
		return;
	end
	Pet : Change_Name(PETNUM,Pet_PetName : GetText());
end

function Pet_Skill_Button_Clicked(nIndex)
--将来主动技能和被动技能，可以在表里查到。
	if(nIndex < 3) then

	end

	PETSKILL_BUTTONS[nIndex] : DoAction();

	local SumPetSkill = GetActionNum("petskill");
	local k=1;
	for i=1, SumPetSkill do
		local theSkillAction = EnumAction( i-1, "petskill");
		if( (theSkillAction : GetPetSkillOwner() == nIndex) and (k <= PETSKILL_BUTTONS_NUM ) ) then
			PETSKILL_BUTTONS[k]:SetActionItem(theSkillAction:GetID());
			k = k + 1;
		end
	end
end

----------------------------------------------------------------------------------
--
-- 旋转珍兽模型（向左)
--
function Pet_Modle_TurnLeft(start)
	--向左旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Pet_FakeObject:RotateBeginEx("My_Pet", -0.3);
	--向左旋转结束
	else
		Pet_FakeObject:RotateEndEx();
	end
end

----------------------------------------------------------------------------------
--
--旋转珍兽模型（向右)
--
function Pet_Modle_TurnRight(start)
	--向右旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Pet_FakeObject:RotateBeginEx("My_Pet", 0.3);
	--向右旋转结束
	else
		Pet_FakeObject:RotateEndEx();
	end
end

function SelfEquip_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1);

	OpenEquip(1);
	Pet_CloseFunction();
	Pet_SelfEquip : SetCheck(0);
	Pet_SelfData : SetCheck(0);
	Pet_Pet : SetCheck(1);

end

function Pet_Skill_Clicked(nSkillIndex)



	if(PETNUM < 0 or PETNUM > PET_MAX_NUMBER) then
		return;
	end

	if(not (Pet:IsPresent(PETNUM)) ) then
		return;
	end

	if Pet : GetSkillPassive(PETNUM,nSkillIndex-1) == 0 then

		PushDebugMessage("请将该技能拖拽到技能快捷栏使用 。");

	end

end

function Pet_OnHiden()
	Pet:NotifyPetDlgClosed()
	Pet_PetName:SetProperty("DefaultEditBox", "False");
end

function Pet_EnableAddButton()
		Pet_Str_Addition:Enable();
		Pet_Int_Addition:Enable();
		Pet_Dex_Addition:Enable();
		Pet_PF_Addition:Enable();
		Pet_Sta_Addition:Enable();
end

function Pet_EnableSubButton()
		Pet_Str_Subtraction:Enable();
		Pet_Int_Subtraction:Enable();
		Pet_Dex_Subtraction:Enable();
		Pet_PF_Subtraction:Enable();
		Pet_Sta_Subtraction:Enable();
end

function Pet_DisableAddButton()
		Pet_Str_Addition:Disable();
		Pet_Int_Addition:Disable();
		Pet_Dex_Addition:Disable();
		Pet_PF_Addition:Disable();
		Pet_Sta_Addition:Disable();
end

function Pet_DisableSubButton()
		Pet_Str_Subtraction:Disable();
		Pet_Int_Subtraction:Disable();
		Pet_Dex_Subtraction:Disable();
		Pet_PF_Subtraction:Disable();
		Pet_Sta_Subtraction:Disable();
end

function Pet_Refresh_ADDSUB_Button()

	Pet_DisableSubButton()

	if PETATTR[1] > 0 then
		Pet_Str_Subtraction:Enable();
		Pet_Accept:Enable();
		Pet_Cancel:Enable();
	end
	if PETATTR[2] > 0 then
		Pet_Int_Subtraction:Enable();
		Pet_Accept:Enable();
		Pet_Cancel:Enable();
	end
	if PETATTR[3] > 0 then
		Pet_Dex_Subtraction:Enable();
		Pet_Accept:Enable();
		Pet_Cancel:Enable();
	end
	if PETATTR[4] > 0 then
		Pet_PF_Subtraction:Enable();
		Pet_Accept:Enable();
		Pet_Cancel:Enable();
	end
	if PETATTR[5] > 0 then
		Pet_Sta_Subtraction:Enable();
		Pet_Accept:Enable();
		Pet_Cancel:Enable();
	end

	if PET_POTREMAIN > 0 then

		Pet_EnableAddButton();
		Pet_Accept:Enable();
		Pet_Cancel:Enable();
	else
		Pet_DisableAddButton();
	end

	local Sum_Attr = 0;
	for i=1,PET_ATTR_COUNT do
		Sum_Attr = Sum_Attr + PETATTR[i];
	end

	if PET_POTREMAIN <=0 and Sum_Attr <= 0 then
		Pet_Accept:Disable();
		Pet_Cancel:Disable();
	end

end

function PetName_Change()
	if Pet_PetName:GetText() ~= "" then
		Changed_Name_Flag = 0;

	end
end

--神木王鼎
function Pet_ShenDing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1);

	local nRet = OpenShenDingPage();
	if nRet == 1 then
		Pet_CloseFunction();
		Pet_Pet:SetCheck(0);
	else
		Pet_ShenDing:SetCheck(0)
	end
end

function Pet_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1);

	OpenRidePage();
	Pet_CloseFunction();
	Pet_SelfEquip : SetCheck(0);
	Pet_SelfData : SetCheck(0);
	Pet_Pet : SetCheck(1);
	Pet_Ride : SetCheck(0);
	Pet_OtherInfo : SetCheck(0);
	Pet_JingMai : SetCheck(0);
end

function Pet_Other_Info_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1);

	OtherInfoPage();
	Pet_CloseFunction();
	Pet_SelfEquip : SetCheck(0);
	Pet_SelfData : SetCheck(0);
	Pet_Pet : SetCheck(1);
	Pet_Ride : SetCheck(0);
	Pet_OtherInfo : SetCheck(0);
	Pet_JingMai : SetCheck(0);
end

function Pet_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1);

	local nRet = OpenJingMaiPage();
	if nRet == 1 then
		Pet_CloseFunction();
		Pet_Pet:SetCheck(0);
	else
		Pet_JingMai:SetCheck(0)
	end
end

function Pet_Xiulian_Switch()
    nLevel = Player:GetData("LEVEL")
	if(nLevel >= 70) then
		Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1);
		XiuLianPage();
	else
	    Pet_Xiulian : SetCheck(0);
	    PushDebugMessage("#{XL_090707_62}")
	end
end

--打开自己的资料页面
function Pet_SelfData_Switch()
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1);

	SystemSetup:OpenPrivatePage("self");
	Pet_CloseFunction();
end


function Pet_Open()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	g_AutoClick_Going = -1
	g_AutoClick_BtnFlag = -1
	SetTimer("Pet", "Pet_AutoClick_Timer()", g_AutoClickTimer_Step)
	
	-- 增加界面互斥关闭逻辑
	if(IsWindowShow("TargetPet")) then
		CloseWindow("TargetPet", true)
	end
	
	if(IsWindowShow("TargetPet2")) then
		CloseWindow("TargetPet2", true)
	end
	
	if(IsWindowShow("BieYePetBar_Awake")) then
		CloseWindow("BieYePetBar_Awake", true)
	end
	
	if(IsWindowShow("PetBankMain")) then
		CloseWindow("PetBankMain", true)
	end
	
	if(IsWindowShow("BieYePetBar")) then
		CloseWindow("BieYePetBar", true)
	end
		
	this:Show();
end

function Pet_CloseFunction()
	g_AutoClick_Going = -1
	g_AutoClick_BtnFlag = -1
	KillTimer("Pet_AutoClick_Timer()")
	if g_CurActFlash > 0 then
		CloseFreshManGuide()
		--NotifyPopUITip("MissionTrack", 1, 8)
		g_CurActFlash = 0
	end
	
	this:Hide();
end

function Pet_chenghao_Clicked()
	if(not (Pet:IsPresent(PETNUM)) ) then
		return;
	end
	Pet:PetOpenTitleList(PETNUM);
end

function Pet_Jian_Clicked()
	if(not (Pet:IsPresent(PETNUM)) ) then
		return;
	end
	Pet:PetOpenPetJian(PETNUM,"self");
end


--获取玩家当前等级最大携带数量(以后增加兽栏后要废除,而采用新的方法)-add by xindefeng
function GetMyCurMaxPetCount()
	local mylevel = Player:GetData("LEVEL") --获取玩家等级
	if mylevel == nil or type(mylevel) ~= "number" then
		return 2;
	end
	local MaxCount = 0	--携带上限

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
	MaxCount = MaxCount + Player:GetData("PET_EXTRANUM")

	if MaxCount > PET_MAX_NUMBER then
		MaxCount = PET_MAX_NUMBER
	end

	return MaxCount
end

--zchw 一键卸装
function OneKeyUnEquip_Clicked()
	Pet:Lua_OneKeyUnEquip();
end

--显示武魂UI
function Pet_Wuhun_Switch()
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1);
	ToggleWuhunPage();
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Pet_Frame_On_ResetPos()

	Pet_Frame : SetProperty("UnifiedXPosition", g_Pet_Frame_UnifiedXPosition);
	Pet_Frame : SetProperty("UnifiedYPosition", g_Pet_Frame_UnifiedYPosition);

end

--***************************************************
-- 清空鼠标长按标记
--***************************************************
function Pet_AutoClick_Clear(id)
	id = tonumber(id)
	if (id == g_AutoClick_BtnFlag) then
		g_AutoClick_BtnFlag = -1
	end
end

--***************************************************
-- 定时器回调函数
--    实现慢启动, 以后可以考虑加速(必要性不大)
--***************************************************
function Pet_AutoClick_Timer()
	if (g_AutoClick_BtnFlag ~= -1) then
		-- 第一次LButton后经过X个Timer才算开始, 也就是说是 g_AutoClickTimer_Step * X 的时候开始进行自动加, 这样为了防止本来要点击一下的结果点了好多下
		if (g_AutoClick_Going < 4) then
			g_AutoClick_Going = g_AutoClick_Going + 1
		else
			--目前先设置 6 Step 的等待时间, 下面注释的代码可以后来用于实现慢启动, 逐渐加速效果.
			--if (g_AutoClick_Going == 2 or g_AutoClick_Going == 5) then
				--g_AutoClick_FunList[g_AutoClick_BtnFlag]()
			--end
			g_AutoClick_FunList[g_AutoClick_BtnFlag]()
		end
	end
end

--***************************************************
-- 鼠标左键松开操作
--    注意这里其实是代替 Click, 所以需要执行一次 Click 操作
--***************************************************
function Pet_AutoClick_LButtonUp(id)
	id = tonumber(id)
	Pet_AutoClick_Clear(id)
	g_AutoClick_FunList[id]()
end

--***************************************************
-- 设置定时器
--    设置标记说明鼠标已经按下
--***************************************************
function Pet_AutoClick_SetTimer(id)
	id = tonumber(id)
	g_AutoClick_Going = -1
	g_AutoClick_BtnFlag = id
end

--!!!reloadscript =Pet
function Pet_FreshManGuide(nType, nTextID, nPosID)
    if nType ~= 1 and      --1 is reset and open
        nType ~= 2 then    --2 is modify
        return
    end
    if g_NeedTipID < 1 then
        return
    end
    if Player:GetData("LEVEL") > 15 then
        return
    end

    local fX = 0
    local fY = 0
    local nPosX = tonumber(Pet_Frame:GetProperty("AbsoluteXPosition"))
    local nPosY = tonumber(Pet_Frame:GetProperty("AbsoluteYPosition"))

    if 1 == nPosID then --or 2 == nPosID then  --Pet_Rest or Pet_Campaign
        fX, fY = this:GetChildOffset("Pet_Rest")
--        fX = fX + Pet_Rest:GetProperty("AbsoluteWidth") / 2
--        fY = fY + Pet_Rest:GetProperty("AbsoluteHeight") - 10

	local fH = tonumber(Pet_Campaign:GetProperty("AbsoluteHeight"))
	local fW = tonumber(Pet_Campaign:GetProperty("AbsoluteWidth"))
	fX = math.floor(tonumber(fX + nPosX + fW))
	fY = math.floor(tonumber(fY + nPosY + (fH * 0.5)))
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 13, 3, "Pet")
	g_CurActFlash = nPosID
	return
    elseif 2 == nPosID then
	fX = tonumber(g_CloseButton:GetProperty("AbsoluteXPosition"))
	fY = tonumber(g_CloseButton:GetProperty("AbsoluteYPosition"))
	local fH = tonumber(g_CloseButton:GetProperty("AbsoluteHeight"))
	local fW = tonumber(g_CloseButton:GetProperty("AbsoluteWidth"))
	fX = math.floor(tonumber(fX + nPosX + fW))
	fY = math.floor(tonumber(fY + nPosY + (fH)))
	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 14, 3, "Pet")
	g_CurActFlash = nPosID
    	return
    elseif 3 == nPosID then             --Pet_Free
        fX, fY = this:GetChildOffset("Pet_Free")
        fX = fX + Pet_Free:GetProperty("AbsoluteWidth") / 2
        fY = fY + Pet_Free:GetProperty("AbsoluteHeight") - 10
--	local fH = tonumber(Pet_Free:GetProperty("AbsoluteHeight"))
--	local fW = tonumber(Pet_Free:GetProperty("AbsoluteWidth"))
--	fX = math.floor(tonumber(fX + nPosX + fW))
--	fY = math.floor(tonumber(fY + nPosY + (fH * 0.5)))
--	OpenFreshManGuideNew(nType, fX, fY, fW, fH, 4, 4, "Pet")
	return
    else
        return                          --unkown position
    end
    OpenFreshManGuide(nType, nTextID, fX, fY, "Pet", "southeast")
end

--2011Q3新手任务ui指引
function Pet_OnShow()
    if g_NeedTipID < 1 then
        return
    end
    if g_NeedTipID == 1 then
        if not Player:IsHaveCurrentPet() then
            Pet_FreshManGuide(1, g_NeedTipText, 1)
        end
    elseif g_NeedTipID == 2 then
        if Player:IsHaveCurrentPet() then
            Pet_FreshManGuide(1, g_NeedTipText, 2)
        end
    else
        Pet_FreshManGuide(1, g_NeedTipText, g_NeedTipID)
    end
end
function Pet_OnMoved()
    if "Pet" == GetFreshManGuideOwner() then
	    Pet_FreshManGuide(2, -1, g_CurActFlash)
--        OpenFreshManGuide(2, -1, -1, -1)
    end
end
function Pet_OnHidden()
    if "Pet" == GetFreshManGuideOwner() then
        CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
    end
    g_NeedTipID = -1
    
    Pet_FakeObject : DetachWindowEx( "My_Pet" );
end

function Pet_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end


function Pet_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenMijiPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Pet_Infant_Switch()
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Pet_YuShou_Page_Switch()
	
	if Player:GetData("Is2606S") == 1 then
		return
	end
	
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1);
	
	--add:lby2015 start
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
		
	--add:lby2015 end
	local ret = Lua_OpenPetMasterPage(nPage)
	if ret ~= 1 then
		Pet_Client_Button02:SetCheck(0)
	end

end

function Pet_HuanLing_Page_Switch()
	
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1)
	
	Pet:Lua_OpenPetHuanLingUI()

end

function Pet_NeiDan_Page_Switch()
	
	if Player:GetData("IsOriginalJD") == 1 then
		return
	end
	
	if Player:GetData("Is2606S") == 1 then
		return
	end
	
	local nLevel = Player:GetData("LEVEL")
	if nLevel < 60 then
		PushDebugMessage("#{ZSND_230428_05}")
		Pet_Client_Button04:SetCheck(0)
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(3000) ~= 1 then
		PushDebugMessage("#{ZSND_230428_06}")
		Pet_Client_Button04:SetCheck(0)
		return
	end
	
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1)	
	Pet:LuaFnOpenPetNeiDan("self")
end

function Pet_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if ( bRet == 1 ) then
		this:Hide();
	end
end

function Pet_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()

end

function Pet_Refresh_Page_Button( nLevel)
	if 1 == 1 then
		return
	end
	
	--神鼎
	if ( nLevel < 15 ) then
		Pet_ShenDing:Disable()
		Pet_ShenDing_tips:Show()
	--	Pet_ShenDing:SetToolTip("#{RWYQ_150707_07}")
	else
		Pet_ShenDing:Enable()
		Pet_ShenDing_tips:Hide()
	end
	--子女
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 ) or InfantCount<=0 then
		Pet_Infant:Disable()
		Pet_Infant_tips:Show()
	--	Pet_Infant:SetToolTip("#{RWYQ_150707_01}")
	else
		Pet_Infant:Enable()
		Pet_Infant_tips:Hide()
	end
	--武魂
--	if ( nLevel < 65 ) then
--		Pet_Wuhun:Disable()
--		Pet_Wuhun_tips:Show()
	--	Pet_Wuhun:SetToolTip("#{RWYQ_150707_02}")
--	else
		Pet_Wuhun:Enable()
		Pet_Wuhun_tips:Hide()
--	end
	--修炼
	if ( nLevel < 70 ) then
		Pet_Xiulian:Disable()
		Pet_Xiulian_tips:Show()
	--	Pet_Xiulian:SetToolTip("#{RWYQ_150707_03}")
	else
		Pet_Xiulian:Enable()
		Pet_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		Pet_Miji:Disable()
		Pet_Miji_tips:Show()
	--	Pet_Miji:SetToolTip("#{RWYQ_150707_04}")
	else
		Pet_Miji:Enable()
		Pet_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		Pet_ZhenYuan:Disable()
		Pet_ZhenYuan_tips:Show()
	--	Pet_ZhenYuan:SetToolTip("#{RWYQ_150707_05}")
	else
		Pet_ZhenYuan:Enable()
		Pet_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		Pet_JueWei:Disable()
		Pet_JueWei_tips:Show()
	--	Pet_JueWei:SetToolTip("#{RWYQ_150707_08}")
	else
		Pet_JueWei:Enable()
		Pet_JueWei_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		Pet_JingMai:Disable()
		Pet_JingMai_tips:Show()
	--	Pet_JingMai:SetToolTip("#{RWYQ_150707_06}")
	else
		Pet_JingMai:Enable()
		Pet_JingMai_tips:Hide()
	end

	if ( nLevel < 85 ) then
		Pet_BaoJian:Disable()
		Pet_BaoJian_tips:Show()
	else
		Pet_BaoJian:Enable()
		Pet_BaoJian_tips:Hide()
	end

	--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		Pet_WuYi:Enable()
		Pet_WuYi_tips:Hide()
	else
		Pet_WuYi:Disable()
		Pet_WuYi_tips:Show()
	end
	Pet_RefreshWuYiTip()
	
	Pet_RefreshNeidanLianhuaTip()
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		Pet_ShenQi:Enable()
		Pet_ShenQi_tips:Hide()
	else
		Pet_ShenQi:Disable()
		Pet_ShenQi_tips:Show()
	end
	
	Pet_RefreshOtherInfoTip()
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		Pet_Armor:Enable()
		Pet_Armor_tips:Hide()
	else
		Pet_Armor:Disable()
		Pet_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		Pet_CangPin:Enable()
		Pet_CangPin_tips:Hide()
	else
		Pet_CangPin:Disable()
		Pet_CangPin_tips:Show()
	end
	
	Pet_Refresh_PetTip()
	
	Pet_RefreshCangPinTip()
end

function Pet_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

function Pet_ListBox_UnlockClicked()
	--开锁？
	-- 判断是否为安全时间
	if (tonumber(DataPool:GetLeftProtectTime()) > 0) then
		PushDebugMessage("#{JJTZ_090826_26}")
		return
	end
	--判断电话密保和二级密码保护
	if CheckPhoneMibaoAndMinorPassword() ~= 1 then	
		return
	end
	local nShouLanCnt = tonumber(Player:GetData("PET_EXTRANUM"))--兽栏空间
	if nShouLanCnt>=4 then
		PushDebugMessage("#{ZSYH_170111_96}")
		return
	end
	if g_nShouLan_ItemInfo[nShouLanCnt+1]==nil then return end;
	local packetpos = PlayerPackage:GetBagPosByItemIndex(tonumber(g_nShouLan_ItemInfo[nShouLanCnt+1].item))
	if packetpos == -1 then
		--无道具
		PushEvent("PET_SHOULAN_AUTOUP",nShouLanCnt,g_nShouLan_ItemInfo[nShouLanCnt+1].item,g_nShouLan_ItemInfo[nShouLanCnt+1].YB)
		return
	else
		PushEvent("PET_SHOULAN_AUTOUSE",nShouLanCnt,g_nShouLan_ItemInfo[nShouLanCnt+1].item)--,packetpos)
		return
	end

end

-- 九星神器DIY技能
function Pet_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Pet_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_Pet_PageButton[idx]:GetProperty("UnifiedXPosition");
			Pet_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		Pet_WuYi_Buttontips:Show()
	else
		Pet_WuYi_Buttontips:Hide()
	end
end

function Pet_RefreshNeidanLianhuaTip()

	Pet_Neidan_Lianhua_Mask:Hide() --默认不蒙红
	Pet_Neidan_Lianhua:Hide()

	if Player:GetData("IsOriginalJD") == 1 then
		return
	end
	if Player:GetData("Is2606S") == 1 then
		return
	end
	local g_LianhuaType = Pet_GetLianhuaType(PET_CURRENT_SELECT)
	if g_LianhuaType < 0 then

		--错误or没有珍兽
		Pet_Neidan_Lianhua:Hide()
	elseif g_LianhuaType == 0   then
		--不可炼化
		--蒙红
		Pet_Neidan_Lianhua_Mask:Show()
		Pet_Neidan_Lianhua:Show()

	elseif g_LianhuaType == 1 then
		--普通炼化
		Pet_Neidan_Lianhua:SetToolTip("#{ZSLH_230426_01}")
		Pet_Neidan_Lianhua:Show()
	elseif  g_LianhuaType == 2  then
		--贵重炼化
		local nNeidanLianhuaState = Pet_GetNeidanLianhuaState()  --根据md算的
		Pet_Neidan_Lianhua:Show()
		if nNeidanLianhuaState == 2 then	
			--可炼化期间 1天	
			Pet_Neidan_Lianhua:SetToolTip(ScriptGlobal_Format("#{ZSLH_230426_03}", tostring(1) ))
		else
			--不可炼化期间
			Pet_Neidan_Lianhua:SetToolTip(ScriptGlobal_Format("#{ZSLH_230426_03}", tostring(0) ))
			--蒙红
			Pet_Neidan_Lianhua_Mask:Show()
		end
	end
end
--获得炼化类型 0 = 不可炼化，1=只普通炼化，2=只贵重炼化
--只与珍兽本身相关4条，1，PetTypeAttr表里，2，宝宝和成年不能炼化，3，可携带等级，4，成长率够不够
function Pet_GetLianhuaType(petIdx)
	
	if petIdx == nil or petIdx < 0 then
		return -1 
	end
	--PetTypeAttr表里根据类型是否可以炼化
	local nflag = Pet : GetPetLianHuaFlag(petIdx) 	
	if (nflag ~= 1) then
		Pet_Neidan_Lianhua:SetToolTip("#{ZSLH_230426_02}")
		return 0 
	end

	--判断珍兽是不是珍兽宝宝 or成年
	local nType = Pet:GetPetType(petIdx)	
	if (nType ~= 1 ) then
		Pet_Neidan_Lianhua:SetToolTip("#{ZSLH_230426_89}")
		return 0
	end	
			

	--携带等级65级
	local nTakeLevel = Pet:GetTakeLevel(petIdx)
	local nLimitLvl = 65
	if nTakeLevel < nLimitLvl then
		Pet_Neidan_Lianhua:SetToolTip("#{ZSLH_230426_88}")
		return 0
	end
	
	--有没有鉴定过成长率
	local PetRate = Pet:GetGrowRate(petIdx)
	local PetCZL_Real = Pet:GetPetGrowLevel(petIdx,PetRate)
	if PetCZL_Real< 0 then	
		Pet_Neidan_Lianhua:SetToolTip("#{ZSLH_230426_90}")
		return 0
	end
	--成长率够不够
	local	nNeedGrowLevel	= NeidanLianhuaGetNeedGrowLvl(nTakeLevel)
	if nNeedGrowLevel >= PetRate then
		Pet_Neidan_Lianhua:SetToolTip("#{ZSLH_230426_87}")
		return  0
	end
	--是否贵重
	local nSavvy =  Pet:GetSavvy(petIdx)
	if nSavvy == nil then
		return 0
	end
	if nSavvy >= 7 then
		return 2
	end
	return 1 	
end
--**********************************
--获得需要的成长率
--**********************************
function NeidanLianhuaGetNeedGrowLvl(petTakeLevel)
	local nNeedGrowLevel = -1
	for i=1, table.getn(tabNeiDanLianHuaNeedGrowLevel) do
		if tabNeiDanLianHuaNeedGrowLevel[i].tl <= petTakeLevel then
			nNeedGrowLevel =  tabNeiDanLianHuaNeedGrowLevel[i].gl
		end	
	end
	return nNeedGrowLevel 
end

--获得珍兽内丹炼化的时间阶段
function Pet_GetNeidanLianhuaState()
	local serverTime = DataPool:GetCurrentServerTime()
	local nNeidanLianhuaShiJianChuo = DataPool:GetPlayerMission_DataRound(2782) --时间戳 服务器SetMD会通知客户端改数据
	--PushDebugMessage("nNeidanLianhuaShiJianChuo="..nNeidanLianhuaShiJianChuo)
	
	if nNeidanLianhuaShiJianChuo <= 0 then
		return 0 
	end
	local g_LianHuaNeiDanApplying =  3*24*3600 
	local g_LianHuaNeiDanApplied = 24*3600 
	local deltaTime = serverTime - nNeidanLianhuaShiJianChuo

	if deltaTime < g_LianHuaNeiDanApplying then
		return 1
	elseif deltaTime < g_LianHuaNeiDanApplied + g_LianHuaNeiDanApplying then
		return 2
	else
		return 3
	end
	return 0 
end
function Pet_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_Pet_PageButton[idx]:GetProperty("UnifiedXPosition");
			Pet_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then
		Pet_OtherInfo_ButtonTips:Show()
	else
		Pet_OtherInfo_ButtonTips:Hide()
	end
end

--内甲
function Pet_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function Pet_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", Pet_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function Pet_Refresh_PetTip()
	local bShowTip = DataPool:LuaFnHavePetNeiDanChipCanCompound()
	if bShowTip == 1 then
		Pet_Client_Button04tips:Show()
		Pet_Pet_Buttontips:Show()
	else
		Pet_Client_Button04tips:Hide()
		Pet_Pet_Buttontips:Hide()
	end
end

function Pet_Exp_LevelUpLock_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnPetSetExpLock" )
		Set_XSCRIPT_ScriptID(800105)
		Set_XSCRIPT_Parameter(0, PETNUM);	
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end

function Pet_RefreshCangPinTip()
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
			local newpos = g_PageButtonTipsPos[idx] --28 + g_Pet_PageButton[idx]:GetProperty("UnifiedXPosition");
			Pet_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		Pet_CangPin_Buttontips:Show()
	else
		Pet_CangPin_Buttontips:Hide()
	end
end


function Pet_ShowPage()

	for i = 1, table.getn(g_Pet_Page) do
		g_Pet_PageButton[i]:Hide()
		g_Pet_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	Pet_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_Pet_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_Pet_Page) do
			if i ~= nPageNumber then
				g_Pet_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_Pet_Page) do
		if Pet_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_Pet_PageButton[g_PageCount]:Show()
			g_Pet_PageButton[g_PageCount]:SetText(g_Pet_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if Pet_IsPageEnable(i) == 1 then
				g_Pet_PageButton[g_PageCount]:Enable()
				g_Pet_PageMask[g_PageCount]:Hide()
			else
				g_Pet_PageButton[g_PageCount]:Disable()
				g_Pet_PageMask[g_PageCount]:Show()
				if g_Pet_Page[i].Tip ~= "" then
					g_Pet_PageMask[g_PageCount]:SetToolTip(g_Pet_Page[i].Tip)
				end
			end
		end
	end
	
	Pet_RefreshWuYiTip()
	Pet_RefreshNeidanLianhuaTip()
	Pet_RefreshOtherInfoTip()
	Pet_Refresh_PetTip()	
	Pet_RefreshCangPinTip()
	
end

function Pet_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		Pet_SelfData_Switch()
	elseif idx == 3 then--珍兽
		--OtherInfo_Pet_Switch()
	elseif idx == 4 then--子女
		Pet_Infant_Switch()
	elseif idx == 5 then--武魂
		Pet_Wuhun_Switch()
	elseif idx == 6 then--修炼
		Pet_Xiulian_Switch()
	elseif idx == 7 then--秘籍
		Pet_Miji_Page_Switch()
	elseif idx == 8 then--真元
		Pet_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		Pet_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		Pet_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		Pet_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		Pet_OpenBaoJian()
	elseif idx == 13 then--武意
		Pet_OpenWuYi()
	elseif idx == 14 then--神器
		Pet_OpenShenQi()
	elseif idx == 15 then--星盘
		Pet_Armor_Page_Switch()
	elseif idx == 16 then--名物
		Pet_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		Pet_Other_Info_Page_Switch()
	end
end

function Pet_CheckPage(idx)
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

function Pet_IsPageEnable(idx)
	
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

function Pet_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


