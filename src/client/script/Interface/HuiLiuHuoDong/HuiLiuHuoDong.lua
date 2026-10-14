--HuiLiuHuoDong.lua

local g_Frame_UnifiedPosition;
local g_HuiLiuHuoDong_FenYeBtn={};
local g_HuiLiuHuoDong_Pages={};
local g_HuiLiuHuoDong_LoginDays = 0;
local g_HuiLiuHuoDong_UI_RedPoint = 0;
local g_HuiLiuHuoDong_Ctrl_RedPoint={};
local g_HuiLiuHuoDong_PageIndex=0;

-- 荣归好礼
local g_HuiLiuHuoDong_RGHL_ActBtn={};
local g_HuiLiuHuoDong_RGHL_BtnGet={};
local g_HuiLiuHuoDong_RGHL_BtnImage={};
local g_HuiLiuHuoDong_RGHL_BtnState = { 1, 1, 1 };
local g_HuiLiuHuoDong_RGHL_RequestText={};
local g_HuiLiuHuoDong_RGHL_MisNameText={};

-- 登录领奖
local g_HuiLiuHuoDong_DLLJ_ActBtn={};
local g_HuiLiuHuoDong_DLLJ_BtnGet={};
local g_HuiLiuHuoDong_DLLJ_BtnImage={};
local g_HuiLiuHuoDong_DLLJ_BtnState = { 1, 1 };
local g_HuiLiuHuoDong_DLLJ_RedPoint={};

local g_HuiLiuHuoDong_DLLJ_GiftBtn = {}
local g_HuiLiuHuoDong_DLLJ_GiftAni = {}
local g_HuiLiuHuoDong_DLLJ_GiftEmpty = {}
local g_HuiLiuHuoDong_DLLJ_GiftText = {}
local g_HuiLiuHuoDong_DLLJ_GiftState = { 1, 1, 1, 1 };
local g_HuiLiuHuoDong_DLLJ_Days = {1, 3, 5, 7};

-- 限时放送
local g_HuiLiuHuoDong_XSFS_ActBtn={};
local g_HuiLiuHuoDong_XSFS_Button={};
local g_HuiLiuHuoDong_XSFS_Name={};
local g_HuiLiuHuoDong_XSFS_Price={};
local g_HuiLiuHuoDong_XSFS_Rate={};
local g_HuiLiuHuoDong_XSFS_Mask={};
local g_HuiLiuHuoDong_XSFS_BonusText={};
local g_HuiLiuHuoDong_XSFS_BuyFlag = { 1, 1, 1 };
local g_HuiLiuHuoDong_XSFS_ItemId = {};
local g_HuiLiuHuoDong_XSFS_BuyTime=0;

local g_HuiLiuHuoDong_LevelImage = {
	[1] = "set:JieBan6 image:jie1", -- 1级
	[2] = "set:JieBan6 image:jie2", -- 2级
	[3] = "set:JieBan6 image:jie3", -- 3级
	[4] = "set:JieBan6 image:jie4", -- 4级
	[5] = "set:JieBan6 image:jie5", -- 5级
	[6] = "set:JieBan6 image:jie6", -- 6级
}


--回流手册

local g_HuiLiuHuoDong_ShouCeProgress = 0;

local g_HuiLiuHuoDong_ShouCeProgressItem = {};
local g_HuiLiuHuoDong_ShouCeProgressItemMask = {};
local g_HuiLiuHuoDong_ShouCeProgressItemRedPoint = {};

local g_HuiLiuHuoDong_ShouCeProgress_Award = 
{
	["ZhuMeng"] = 0;
	["RongGui"] = 0;
	["BangGong"] = 0;
	["GongZi"] = 0;
	["YuanBao"] = 0;
	["Item1ID"] = -1;
	["Item1Num"] = 0;
	["Item2ID"] = -1;
	["Item2Num"] = 0;
}
local g_HuiLiuHuoDong_ShouCeProgress_needProgress = {}
local g_HuiLiuHuoDong_ShouCeProgress_giftFlag = {}


local g_HuiLiuHuoDong_ShouCeProgressItemTip ={
	[1] = "#{JBHL_220120_55}",
	[2] = "#{JBHL_220120_56}",
	[3] = "#{JBHL_220120_57}",
	[4] = "#{JBHL_220120_58}",
}


local g_HuiLiuHuoDong_ShouCeMissionList ={}

--筑梦
local g_HuiLiuHuoDong_ZM_ActBtn = {}
local g_HuiLiuHuoDong_ZM_ActName = {}
local g_HuiLiuHuoDong_ZM_DaibiText = {}
local g_HuiLiuHuoDong_ZM_ItemMask = {}
local g_HuiLiuHuoDong_ZM_SelectItem = 0

local g_HuiLiuHuoDong_ZM_Status = 0
local g_HuiLiuHuoDong_ZM_SelectIndex = 0
local g_HuiLiuHuoDong_ZM_Daibi = 0
local g_HuiLiuHuoDong_HuiliuLevel = 0
local g_HuiLiuHuoDong_lefttime = 0
local g_HuiLiuHuoDong_ZM_Item = {
	[1] = {item2 = 10126586, num = 1, cnt = 120},
	[2] = {item2 = 10126438, num = 1, cnt = 120},
	[3] = {item2 = 10101059, num = 1, cnt = 120},
	[4] = {item2 = 10102658, num = 1, cnt = 120},
	[5] = {item2 = 38001553, num = 60, cnt = 120},
	[6] = {item2 = 38000571, num = 20, cnt = 120},
}

function HuiLiuHuoDong_PreLoad()
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("UPDATE_REDPOINT_IN_UI")	
	this:RegisterEvent("HUILIU_HLSCOPEN")	
end

function HuiLiuHuoDong_OnLoad()

	-- 分页按钮
	g_HuiLiuHuoDong_FenYeBtn[1] = HuiLiuHuoDong_RGHL_Btn;
	g_HuiLiuHuoDong_FenYeBtn[2] = HuiLiuHuoDong_DLLJ_Btn;
	g_HuiLiuHuoDong_FenYeBtn[3] = HuiLiuHuoDong_XSFS_Btn;
	g_HuiLiuHuoDong_FenYeBtn[4] = HuiLiuHuoDong_SBJX_Btn;
	g_HuiLiuHuoDong_FenYeBtn[5] = HuiLiuHuoDong_ZM_Btn;
	g_HuiLiuHuoDong_FenYeBtn[6] = HuiLiuHuoDong_HLSC_Btn;
	
	g_HuiLiuHuoDong_Pages[1] = HuiLiuHuoDong_RongGui;
	g_HuiLiuHuoDong_Pages[2] = HuiLiuHuoDong_DengLuLingJiang;
	g_HuiLiuHuoDong_Pages[3] = HuiLiuHuoDong_XianShiFangSong;
	g_HuiLiuHuoDong_Pages[4] = HuiLiuHuoDong_DoubleSurprise;
	g_HuiLiuHuoDong_Pages[5] = HuiLiuHuoDong_ZhuMeng;
	g_HuiLiuHuoDong_Pages[6] = HuiLiuHuoDong_HuiLiu;

	g_HuiLiuHuoDong_Ctrl_RedPoint[1] = HuiLiuHuoDong_Left_Buttontab01_Tips
	g_HuiLiuHuoDong_Ctrl_RedPoint[2] = HuiLiuHuoDong_Left_Buttontab03_Tips
	g_HuiLiuHuoDong_Ctrl_RedPoint[3] = HuiLiuHuoDong_Left_Buttontab04_Tips

	-- 荣归好礼
	g_HuiLiuHuoDong_RGHL_ActBtn[1] = HuiLiuHuoDong_1Icon;
	g_HuiLiuHuoDong_RGHL_ActBtn[2] = HuiLiuHuoDong_2Icon;
	g_HuiLiuHuoDong_RGHL_ActBtn[3] = HuiLiuHuoDong_3Icon;
	
	g_HuiLiuHuoDong_RGHL_BtnGet[1] = HuiLiuHuoDong_GetBtn; 
	g_HuiLiuHuoDong_RGHL_BtnGet[2] = HuiLiuHuoDong_GetBtn2;
	g_HuiLiuHuoDong_RGHL_BtnGet[3] = HuiLiuHuoDong_GetBtn3;
	
	g_HuiLiuHuoDong_RGHL_BtnImage[1] = HuiLiuHuoDong_ReceivedBtn; 
	g_HuiLiuHuoDong_RGHL_BtnImage[2] = HuiLiuHuoDong_ReceivedBtn2;
	g_HuiLiuHuoDong_RGHL_BtnImage[3] = HuiLiuHuoDong_ReceivedBtn3;
	
	g_HuiLiuHuoDong_RGHL_RequestText[1] = HuiLiuHuoDong_GetRequest_1; 
	g_HuiLiuHuoDong_RGHL_RequestText[2] = HuiLiuHuoDong_GetRequest_2;
	g_HuiLiuHuoDong_RGHL_RequestText[3] = HuiLiuHuoDong_GetRequest_3;
	
	g_HuiLiuHuoDong_RGHL_MisNameText[1] = HuiLiuHuoDong_Mission1Name; 
	g_HuiLiuHuoDong_RGHL_MisNameText[2] = HuiLiuHuoDong_Mission2Name;
	g_HuiLiuHuoDong_RGHL_MisNameText[3] = HuiLiuHuoDong_Mission3Name;
		
	-- 登录领奖
	g_HuiLiuHuoDong_DLLJ_ActBtn[1] = HuiLiuHuoDong_DengLuLingJiang_PartA_Item1_Icon;
	g_HuiLiuHuoDong_DLLJ_ActBtn[2] = HuiLiuHuoDong_DengLuLingJiang_PartA_Item2_Icon;	
	g_HuiLiuHuoDong_DLLJ_BtnGet[1] = HuiLiuHuoDong_DengLuLingJiang_PartA_Item1_GetBtn;
	g_HuiLiuHuoDong_DLLJ_BtnGet[2] = HuiLiuHuoDong_DengLuLingJiang_PartA_Item2_GetBtn2;	
	g_HuiLiuHuoDong_DLLJ_BtnImage[1] = HuiLiuHuoDong_DengLuLingJiang_PartA_Item1_ReceivedBtn;
	g_HuiLiuHuoDong_DLLJ_BtnImage[2] = HuiLiuHuoDong_DengLuLingJiang_PartA_Item2_ReceivedBtn2;
	
	g_HuiLiuHuoDong_DLLJ_GiftBtn[1] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item1;
	g_HuiLiuHuoDong_DLLJ_GiftBtn[2] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item2;
	g_HuiLiuHuoDong_DLLJ_GiftBtn[3] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item3;
	g_HuiLiuHuoDong_DLLJ_GiftBtn[4] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item4;	
	g_HuiLiuHuoDong_DLLJ_GiftAni[1] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item1_Ani;
	g_HuiLiuHuoDong_DLLJ_GiftAni[2] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item2_Ani;
	g_HuiLiuHuoDong_DLLJ_GiftAni[3] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item3_Ani;
	g_HuiLiuHuoDong_DLLJ_GiftAni[4] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item4_Ani;	
	g_HuiLiuHuoDong_DLLJ_GiftEmpty[1] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item1_Empty;
	g_HuiLiuHuoDong_DLLJ_GiftEmpty[2] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item2_Empty;
	g_HuiLiuHuoDong_DLLJ_GiftEmpty[3] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item3_Empty;
	g_HuiLiuHuoDong_DLLJ_GiftEmpty[4] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item4_Empty;
	g_HuiLiuHuoDong_DLLJ_GiftText[1] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item1_Text;
	g_HuiLiuHuoDong_DLLJ_GiftText[2] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item2_Text;
	g_HuiLiuHuoDong_DLLJ_GiftText[3] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item3_Text;
	g_HuiLiuHuoDong_DLLJ_GiftText[4] = HuiLiuHuoDong_DengLuLingJiang_PartB_Item4_Text;
	g_HuiLiuHuoDong_DLLJ_RedPoint[1] = HuiLiuHuoDong_Btn_RedDot1;
	g_HuiLiuHuoDong_DLLJ_RedPoint[2] = HuiLiuHuoDong_Btn_RedDot2;
	g_HuiLiuHuoDong_DLLJ_RedPoint[3] = HuiLiuHuoDong_Btn_RedDot3;
	g_HuiLiuHuoDong_DLLJ_RedPoint[4] = HuiLiuHuoDong_Btn_RedDot4;
		
	-- 限时放送
	g_HuiLiuHuoDong_XSFS_ActBtn[1] = HuiLiuHuoDong_XianShiFangSong_Item1_Icon;
	g_HuiLiuHuoDong_XSFS_ActBtn[2] = HuiLiuHuoDong_XianShiFangSong_Item2_Icon;
	g_HuiLiuHuoDong_XSFS_ActBtn[3] = HuiLiuHuoDong_XianShiFangSong_Item3_Icon;
	
	g_HuiLiuHuoDong_XSFS_Button[1] = HuiLiuHuoDong_XianShiFangSong_Item1_Btn;
	g_HuiLiuHuoDong_XSFS_Button[2] = HuiLiuHuoDong_XianShiFangSong_Item2_Btn;
	g_HuiLiuHuoDong_XSFS_Button[3] = HuiLiuHuoDong_XianShiFangSong_Item_Btn;	
	
	g_HuiLiuHuoDong_XSFS_Name[1] = HuiLiuHuoDong_XianShiFangSong_Item1_Text1;
	g_HuiLiuHuoDong_XSFS_Name[2] = HuiLiuHuoDong_XianShiFangSong_Item2_Text1;
	g_HuiLiuHuoDong_XSFS_Name[3] = HuiLiuHuoDong_XianShiFangSong_Item3_Text1;	
	
	g_HuiLiuHuoDong_XSFS_Price[1] = HuiLiuHuoDong_XianShiFangSong_Item1_Text2;
	g_HuiLiuHuoDong_XSFS_Price[2] = HuiLiuHuoDong_XianShiFangSong_Item2_Text2;
	g_HuiLiuHuoDong_XSFS_Price[3] = HuiLiuHuoDong_XianShiFangSong_Item3_Text2;	
	
	g_HuiLiuHuoDong_XSFS_Mask[1] = HuiLiuHuoDong_XianShiFangSong_Item1_Icon_Mask;
	g_HuiLiuHuoDong_XSFS_Mask[2] = HuiLiuHuoDong_XianShiFangSong_Item2_Icon_Mask;
	g_HuiLiuHuoDong_XSFS_Mask[3] = HuiLiuHuoDong_XianShiFangSong_Item3_Icon_Mask;	
	
	g_HuiLiuHuoDong_XSFS_Rate[1] = HuiLiuHuoDong_XianShiFangSong_Item1_Discount_text;
	g_HuiLiuHuoDong_XSFS_Rate[2] = HuiLiuHuoDong_XianShiFangSong_Item2_Discount_text;
	g_HuiLiuHuoDong_XSFS_Rate[3] = HuiLiuHuoDong_XianShiFangSong_Item3_Discount_text;
	
	g_HuiLiuHuoDong_XSFS_BonusText[1] = HuiLiuHuoDong_XianShiFangSong_Item1_Btn_text;
	g_HuiLiuHuoDong_XSFS_BonusText[2] = HuiLiuHuoDong_XianShiFangSong_Item2_Btn_text;
	g_HuiLiuHuoDong_XSFS_BonusText[3] = HuiLiuHuoDong_XianShiFangSong_Item3_Btn_text;
	
	--回流手册
	--进度奖励物品
	g_HuiLiuHuoDong_ShouCeProgressItem[1] = HuiLiuHuoDong_HuiLiu_Jindu_Item1;
	g_HuiLiuHuoDong_ShouCeProgressItem[2] = HuiLiuHuoDong_HuiLiu_Jindu_Item2;
	g_HuiLiuHuoDong_ShouCeProgressItem[3] = HuiLiuHuoDong_HuiLiu_Jindu_Item3;
	g_HuiLiuHuoDong_ShouCeProgressItem[4] = HuiLiuHuoDong_HuiLiu_Jindu_Item4;
	--进度奖励物品领取蒙版
	g_HuiLiuHuoDong_ShouCeProgressItemMask[1] = HuiLiuHuoDong_HuiLiu_Jindu_Item1_Mask;
	g_HuiLiuHuoDong_ShouCeProgressItemMask[2] = HuiLiuHuoDong_HuiLiu_Jindu_Item2_Mask;
	g_HuiLiuHuoDong_ShouCeProgressItemMask[3] = HuiLiuHuoDong_HuiLiu_Jindu_Item3_Mask;
	g_HuiLiuHuoDong_ShouCeProgressItemMask[4] = HuiLiuHuoDong_HuiLiu_Jindu_Item4_Mask;
	--进度奖励物品红点
	g_HuiLiuHuoDong_ShouCeProgressItemRedPoint[1] = HuiLiuHuoDong_HuiLiu_Jindu_Item1_Tips;
	g_HuiLiuHuoDong_ShouCeProgressItemRedPoint[2] = HuiLiuHuoDong_HuiLiu_Jindu_Item2_Tips;
	g_HuiLiuHuoDong_ShouCeProgressItemRedPoint[3] = HuiLiuHuoDong_HuiLiu_Jindu_Item3_Tips;
	g_HuiLiuHuoDong_ShouCeProgressItemRedPoint[4] = HuiLiuHuoDong_HuiLiu_Jindu_Item4_Tips;

	
	--筑梦
	g_HuiLiuHuoDong_ZM_ActBtn[1] = HuiLiuHuoDong_Item1
	g_HuiLiuHuoDong_ZM_ActBtn[2] = HuiLiuHuoDong_Item2
	g_HuiLiuHuoDong_ZM_ActBtn[3] = HuiLiuHuoDong_Item3
	g_HuiLiuHuoDong_ZM_ActBtn[4] = HuiLiuHuoDong_Item4
	g_HuiLiuHuoDong_ZM_ActBtn[5] = HuiLiuHuoDong_Item5
	g_HuiLiuHuoDong_ZM_ActBtn[6] = HuiLiuHuoDong_Item6
	
	g_HuiLiuHuoDong_ZM_ActName[1] = HuiLiuHuoDong_Item1_Text
	g_HuiLiuHuoDong_ZM_ActName[2] = HuiLiuHuoDong_Item2_Text
	g_HuiLiuHuoDong_ZM_ActName[3] = HuiLiuHuoDong_Item3_Text
	g_HuiLiuHuoDong_ZM_ActName[4] = HuiLiuHuoDong_Item4_Text
	g_HuiLiuHuoDong_ZM_ActName[5] = HuiLiuHuoDong_Item5_Text
	g_HuiLiuHuoDong_ZM_ActName[6] = HuiLiuHuoDong_Item6_Text
	
	--g_HuiLiuHuoDong_ZM_DaibiText[1] = HuiLiuHuoDong_Item1_info
	--g_HuiLiuHuoDong_ZM_DaibiText[2] = HuiLiuHuoDong_Item2_info
	--g_HuiLiuHuoDong_ZM_DaibiText[3] = HuiLiuHuoDong_Item3_info
	--g_HuiLiuHuoDong_ZM_DaibiText[4] = HuiLiuHuoDong_Item4_info
	--g_HuiLiuHuoDong_ZM_DaibiText[5] = HuiLiuHuoDong_Item5_info
	--g_HuiLiuHuoDong_ZM_DaibiText[6] = HuiLiuHuoDong_Item6_info
	
	g_HuiLiuHuoDong_ZM_ItemMask[1] = HuiLiuHuoDong_Item1_Mask
	g_HuiLiuHuoDong_ZM_ItemMask[2] = HuiLiuHuoDong_Item2_Mask
	g_HuiLiuHuoDong_ZM_ItemMask[3] = HuiLiuHuoDong_Item3_Mask
	g_HuiLiuHuoDong_ZM_ItemMask[4] = HuiLiuHuoDong_Item4_Mask
	g_HuiLiuHuoDong_ZM_ItemMask[5] = HuiLiuHuoDong_Item5_Mask
	g_HuiLiuHuoDong_ZM_ItemMask[6] = HuiLiuHuoDong_Item6_Mask
	
	g_Frame_UnifiedPosition = HuiLiuHuoDong:GetProperty("UnifiedPosition") 
end

function HuiLiuHuoDong_OnEvent(event)

	--显示荣归大礼界面
	if event == "UI_COMMAND" then
		
		-- 荣归好礼
		if tonumber(arg0) == 80811201 then
			local bShow = Get_XParam_INT(0);
			if bShow <= 0 and (this:IsVisible()~=true or g_HuiLiuHuoDong_PageIndex ~= 1) then
				return
			end
						
			local nLeftTime = Get_XParam_INT(1);
			local nVipGiftItemID = Get_XParam_INT(2);
			local nGiftData = Get_XParam_INT(3);
			g_HuiLiuHuoDong_RGHL_BtnState[1] = math.mod( nGiftData, 10);
			g_HuiLiuHuoDong_RGHL_BtnState[2] = math.mod( math.floor(nGiftData/10), 10);
			g_HuiLiuHuoDong_RGHL_BtnState[3] = math.mod( math.floor(nGiftData/100), 10);
			
			local nShowSBJX = Get_XParam_INT(4);	
			g_HuiLiuHuoDong_UI_RedPoint = Get_XParam_INT(5)
			local nHLLevel = Get_XParam_INT(6);			
			HuiLiuHuoDong_ShowContent( 1, nLeftTime, nHLLevel, 0, 0, nShowSBJX );
			HuiLiuHuoDong_ShowPage_RongGui( nVipGiftItemID )
			
			HuiLiuHuoDong_UpdateRedPointInUI();
			
			HuiLiuHuoDong_ResetPos( bShow )
			this:Show();
			
		-- 登录领奖
		elseif tonumber(arg0) == 80811202 then
			local bShow = Get_XParam_INT(0);
			if bShow <= 0 and (this:IsVisible()~=true or g_HuiLiuHuoDong_PageIndex ~= 2) then
				return
			end
		
			local nLeftTime = Get_XParam_INT(1);
			g_HuiLiuHuoDong_LoginDays = Get_XParam_INT(2);			
			g_HuiLiuHuoDong_DLLJ_BtnState[1] = Get_XParam_INT(3);
			g_HuiLiuHuoDong_DLLJ_BtnState[2] = Get_XParam_INT(4);
			
			local nGiftData = Get_XParam_INT(5);
			g_HuiLiuHuoDong_DLLJ_GiftState[1] = math.mod( nGiftData, 10);
			g_HuiLiuHuoDong_DLLJ_GiftState[2] = math.mod( math.floor(nGiftData/10), 10);
			g_HuiLiuHuoDong_DLLJ_GiftState[3] = math.mod( math.floor(nGiftData/100), 10);
			g_HuiLiuHuoDong_DLLJ_GiftState[4] = math.mod( math.floor(nGiftData/1000), 10);

			local nShowSBJX = Get_XParam_INT(6);			
			g_HuiLiuHuoDong_UI_RedPoint = Get_XParam_INT(7)
			local nHLLevel = Get_XParam_INT(8);			
			HuiLiuHuoDong_ShowContent( 2, nLeftTime, nHLLevel, 0, g_HuiLiuHuoDong_LoginDays, nShowSBJX );
			HuiLiuHuoDong_ShowPage_LingJiang( nHLLevel )
			HuiLiuHuoDong_UpdateRedPointInUI();
			
			HuiLiuHuoDong_ResetPos( bShow )
			this:Show();
			
		-- 限时放送
		elseif tonumber(arg0) == 80811203 then
			local bShow = Get_XParam_INT(0);
			if bShow <= 0 and (this:IsVisible()~=true or g_HuiLiuHuoDong_PageIndex ~= 3) then
				return
			end
		
			g_HuiLiuHuoDong_XSFS_BuyTime = Get_XParam_INT(1);
			local nBuyData = Get_XParam_INT(2);
			g_HuiLiuHuoDong_XSFS_BuyFlag[1] = math.mod( math.floor(nBuyData/100), 10);
			g_HuiLiuHuoDong_XSFS_BuyFlag[2] = math.mod( math.floor(nBuyData/10), 10);
			g_HuiLiuHuoDong_XSFS_BuyFlag[3] = math.mod( nBuyData, 10);
			
			local nhlLevel	= Get_XParam_INT(3);
			local nTime			= Get_XParam_INT(4);			
			local nShowSBJX = Get_XParam_INT(5);
			g_HuiLiuHuoDong_UI_RedPoint = Get_XParam_INT(6)
			local nLeftTime = Get_XParam_INT(7);
			HuiLiuHuoDong_ShowContent( 3, nLeftTime, nhlLevel, g_HuiLiuHuoDong_XSFS_BuyTime, 0, nShowSBJX );
			HuiLiuHuoDong_ShowPage_FangSong( nhlLevel, nTime )
			HuiLiuHuoDong_UpdateRedPointInUI();
			
			HuiLiuHuoDong_ResetPos( bShow )
			this:Show();
			
		-- 双倍惊喜
		elseif tonumber(arg0) == 80811204 then
		
			local bShow = Get_XParam_INT(0);
			if bShow <= 0 and (this:IsVisible()~=true or g_HuiLiuHuoDong_PageIndex ~= 4) then
				return
			end
		
			local nLeftTime = Get_XParam_INT(1);
			g_HuiLiuHuoDong_UI_RedPoint = Get_XParam_INT(2)
			local nhlLevel	= Get_XParam_INT(3);
			HuiLiuHuoDong_ShowContent( 4, nLeftTime, nhlLevel, 0, 0, 1 );
			HuiLiuHuoDong_ShowPage_JingXi()
			HuiLiuHuoDong_UpdateRedPointInUI();
			
			HuiLiuHuoDong_ResetPos( bShow )
			this:Show();

		--回流手册 进度奖励领取后刷新
		elseif tonumber(arg0) == 80811216 then
			HuiLiuHuoDong_ShowPage_HuiLiuShouCe_SetItem(Get_XParam_INT(0))
		--回流手册 进度代币领取后刷新
		elseif tonumber(arg0) == 80811226 then
			HuiLiuHuoDong_ShowPage_HuiLiuShouCe_UpdateMissionList(Get_XParam_INT(0),Get_XParam_INT(1),Get_XParam_INT(2))
		elseif tonumber(arg0) == 80811227 then
			HuiLiuHuoDong_HuiLiuShouCe_UpdateMissionList_Maidian(Get_XParam_INT(0),Get_XParam_INT(1))
		-- 领奖，显示动画
		elseif tonumber(arg0) == 80811207 then
			
			local nEnable = Get_XParam_INT(0);
			local nIndex = Get_XParam_INT(1);
			HuiLiuHuoDong_DLLJ_PlayAni(nEnable, nIndex)
			
		elseif tonumber(arg0) == 89319510 and this:IsVisible() then
			--红点
			g_HuiLiuHuoDong_UI_RedPoint = Get_XParam_INT(0)*1000+Get_XParam_INT(1)*100+Get_XParam_INT(2)*10+Get_XParam_INT(3);
			--刷新红点
			HuiLiuHuoDong_UpdateRedPointInUI()
		-- 筑梦
		elseif tonumber(arg0) == 88896501 then
		
			local bShow = Get_XParam_INT(0);
			if bShow <= 0 and (this:IsVisible()~=true or g_HuiLiuHuoDong_PageIndex ~= 5) then
				return
			end
			
			if bShow == 1 then
				g_HuiLiuHuoDong_UI_RedPoint = Get_XParam_INT(1)
				g_HuiLiuHuoDong_HuiliuLevel	= Get_XParam_INT(2);
				g_HuiLiuHuoDong_ZM_Status = Get_XParam_INT(3)
				g_HuiLiuHuoDong_ZM_SelectIndex = Get_XParam_INT(4)
				g_HuiLiuHuoDong_ZM_Daibi = Get_XParam_INT(5)
				g_HuiLiuHuoDong_lefttime = Get_XParam_INT(6);
				
				HuiLiuHuoDong_ShowContent( 5, g_HuiLiuHuoDong_lefttime, g_HuiLiuHuoDong_HuiliuLevel, 0, 0, 1 );
			elseif bShow == 2 then
				g_HuiLiuHuoDong_ZM_Status = Get_XParam_INT(1)
				g_HuiLiuHuoDong_ZM_SelectIndex = Get_XParam_INT(2)
			end

			HuiLiuHuoDong_ShowPage_ZhuMeng()
			HuiLiuHuoDong_UpdateRedPointInUI();
			
			HuiLiuHuoDong_ResetPos( bShow )
			this:Show();
		end	
		
	end

	--打开回流手册界面消息 也负责埋点后的界面刷新
	if event == "HUILIU_HLSCOPEN"then
		HuiLiuHuoDong_ShowPage_HuiLiuShouCe()
		HuiLiuHuoDong_UpdateRedPointInUI()
		return
	end
	
	if event == "UPDATE_REDPOINT_IN_UI" and this:IsVisible() then
		HuiLiuHuoDong_UpdateRedPointInUI()	
		return
	end
	
	if event == "VIEW_RESOLUTION_CHANGED" then
		HuiLiuHuoDong_On_ResetPos();
		return
	end
	
	if event == "ADJEST_UI_POS" then
		HuiLiuHuoDong_On_ResetPos();
		return
	end
	
	if ( event == "SCENE_TRANSED" ) then
		HuiLiuHuoDong_OnClosed()
		return
	end
	
end

--刷新荣归大礼界面
function HuiLiuHuoDong_ShowPage_RongGui( nVipGiftItemID )

	HuiLiuHuoDong_FenYeBtnClick( 1 );
	
	local nGiftItemId={ 39921014, 39921015, nVipGiftItemID};	
	local szMisName={ "#{JBHL_190803_376}", "#{JBHL_190803_375}", "#{JBHL_190803_374}" };	
	for i=1, 3 do
		--显示图标
		local theAction = DataPool:CreateActionItemForShow(nGiftItemId[i], 1)
		if theAction:GetID() ~= 0 then	
			g_HuiLiuHuoDong_RGHL_ActBtn[i]:SetActionItem(theAction:GetID())
			g_HuiLiuHuoDong_RGHL_MisNameText[i]:SetText( szMisName[i] );
		end
			
		if g_HuiLiuHuoDong_RGHL_BtnState[i] == 0 then	--已领取
			g_HuiLiuHuoDong_RGHL_BtnGet[i]:Hide();
			g_HuiLiuHuoDong_RGHL_BtnImage[i]:Show();			
			g_HuiLiuHuoDong_RGHL_RequestText[i]:Hide();
		elseif g_HuiLiuHuoDong_RGHL_BtnState[i] == 1 then	--可领取
			g_HuiLiuHuoDong_RGHL_BtnGet[i]:Show();
			g_HuiLiuHuoDong_RGHL_BtnImage[i]:Hide();
			g_HuiLiuHuoDong_RGHL_BtnGet[i]:Enable();
			g_HuiLiuHuoDong_RGHL_RequestText[i]:Hide();
		else  -- 未领取，但不可领取
			g_HuiLiuHuoDong_RGHL_BtnGet[i]:Show();
			g_HuiLiuHuoDong_RGHL_BtnImage[i]:Hide();
			g_HuiLiuHuoDong_RGHL_BtnGet[i]:Disable();
			g_HuiLiuHuoDong_RGHL_RequestText[i]:Show();
		end		
	end
	
end

-- 显示 登录领奖 界面
function HuiLiuHuoDong_ShowPage_LingJiang( nHLLevel )

	HuiLiuHuoDong_FenYeBtnClick( 2 );
	
	HuiLiuHuoDong_DengLuLingJiang_PartA_Text:Hide();
		
	local lstItemId = {39921016, 39921017};
	if Player:GetData("Is2606S") == 1 then
		lstItemId = {39921016, 30008027};
		HuiLiuHuoDong_DengLuLingJiang_PartA_Item2_Name:SetText("#{QXFXG_260703_5}")
	else
		HuiLiuHuoDong_DengLuLingJiang_PartA_Item2_Name:SetText("#{JBHL_190803_380}")
	end
	for i=1, 2 do
		--显示图标
		local theAction = DataPool:CreateActionItemForShow(lstItemId[i], 1)
		if theAction:GetID() ~= 0 then	
			g_HuiLiuHuoDong_DLLJ_ActBtn[i]:SetActionItem(theAction:GetID())
		end
		
		if g_HuiLiuHuoDong_DLLJ_BtnState[i] == 1 then	--可领取
			g_HuiLiuHuoDong_DLLJ_BtnGet[i]:Show();
			g_HuiLiuHuoDong_DLLJ_BtnImage[i]:Hide();
			g_HuiLiuHuoDong_DLLJ_BtnGet[i]:Enable();
		elseif g_HuiLiuHuoDong_DLLJ_BtnState[i] == 0 then	--已领取
			g_HuiLiuHuoDong_DLLJ_BtnGet[i]:Hide();
			g_HuiLiuHuoDong_DLLJ_BtnImage[i]:Show();
		else -- 未领取，但不可领取
			g_HuiLiuHuoDong_DLLJ_BtnGet[i]:Show();
			g_HuiLiuHuoDong_DLLJ_BtnImage[i]:Hide();
			g_HuiLiuHuoDong_DLLJ_BtnGet[i]:Disable();
			if i == 2 then
				HuiLiuHuoDong_DengLuLingJiang_PartA_Text:Show();
			end
		end		
				
	end	
	
	local szListTooltip = {
		[1] = {"#{JBHL_220120_94}", "#{JBHL_220120_95}", "#{JBHL_220120_96}", "#{JBHL_220120_97}"},
		[2] = {"#{JBHL_220120_98}", "#{JBHL_220120_99}", "#{JBHL_220120_100}", "#{JBHL_220120_101}"},
		[3] = {"#{JBHL_220120_102}", "#{JBHL_220120_103}", "#{JBHL_220120_104}", "#{JBHL_220120_105}"},
		[4] = {"#{JBHL_220120_106}", "#{JBHL_220120_107}", "#{JBHL_220120_108}", "#{JBHL_220120_109}"},
		[5] = {"#{JBHL_220120_83}", "#{JBHL_220120_84}", "#{JBHL_220120_85}", "#{JBHL_220120_109}"},
		[6] = {"#{JBHL_220120_86}", "#{JBHL_220120_87}", "#{JBHL_220120_88}", "#{JBHL_220120_109}"},
	};
	
	local szListTooltipOriJD = {
		[1] = {"#{JBHL_220120_94}", "#{SJF_260226_01}", "#{SJF_260226_02}", "#{SJF_260226_03}"},
		[2] = {"#{JBHL_220120_98}", "#{SJF_260226_04}", "#{SJF_260226_05}", "#{SJF_260226_06}"},
		[3] = {"#{JBHL_220120_102}", "#{SJF_260226_07}", "#{SJF_260226_08}", "#{SJF_260226_09}"},
		[4] = {"#{JBHL_220120_106}", "#{SJF_260226_10}", "#{SJF_260226_11}", "#{SJF_260226_12}"},
		[5] = {"#{JBHL_220120_83}", "#{SJF_260226_13}", "#{SJF_260226_14}", "#{SJF_260226_15}"},
		[6] = {"#{JBHL_220120_86}", "#{SJF_260226_16}", "#{SJF_260226_17}", "#{SJF_260226_18}"},
	};
	
	local szListTooltip2606S = {
		[1] = {"#{JBHL_220120_94}", "#{QXF_260623_38}", "#{QXF_260623_39}", "#{QXF_260623_40}"},
		[2] = {"#{JBHL_220120_98}", "#{QXF_260623_41}", "#{QXF_260623_42}", "#{QXF_260623_43}"},
		[3] = {"#{JBHL_220120_102}", "#{QXF_260623_44}", "#{QXF_260623_45}", "#{QXF_260623_46}"},
		[4] = {"#{JBHL_220120_106}", "#{QXF_260623_47}", "#{QXF_260623_48}", "#{QXF_260623_49}"},
		[5] = {"#{JBHL_220120_83}", "#{QXF_260623_50}", "#{QXF_260623_51}", "#{QXF_260623_52}"},
		[6] = {"#{JBHL_220120_86}", "#{QXF_260623_53}", "#{QXF_260623_54}", "#{QXF_260623_55}"},
	};
	
	local gListTooltip=nil
	local bIsOriJD = Player:GetData("IsOriginalJD")
	if bIsOriJD == 1 then
		gListTooltip = szListTooltipOriJD[nHLLevel]
	elseif Player:GetData("Is2606S") == 1 then
		gListTooltip = szListTooltip2606S[nHLLevel]
	else
		gListTooltip = szListTooltip[nHLLevel]
	end
	
	for i=1, 4 do
		g_HuiLiuHuoDong_DLLJ_GiftText[i]:SetText( ScriptGlobal_Format("#{JBHL_190803_326}", g_HuiLiuHuoDong_DLLJ_Days[i] ) );
		if g_HuiLiuHuoDong_DLLJ_Days[i] <= g_HuiLiuHuoDong_LoginDays then
			if g_HuiLiuHuoDong_DLLJ_GiftState[i] == 1 then
				g_HuiLiuHuoDong_DLLJ_GiftBtn[i]:Show()
				g_HuiLiuHuoDong_DLLJ_GiftEmpty[i]:Hide()
				g_HuiLiuHuoDong_DLLJ_GiftAni[i]:Hide()
				g_HuiLiuHuoDong_DLLJ_RedPoint[i]:Show()
			else
				g_HuiLiuHuoDong_DLLJ_GiftBtn[i]:Hide()
				g_HuiLiuHuoDong_DLLJ_GiftEmpty[i]:Show()
				g_HuiLiuHuoDong_DLLJ_GiftAni[i]:Hide()
				g_HuiLiuHuoDong_DLLJ_RedPoint[i]:Hide()
			end
		else
			g_HuiLiuHuoDong_DLLJ_GiftEmpty[i]:Hide()
			g_HuiLiuHuoDong_DLLJ_GiftBtn[i]:Show()
			g_HuiLiuHuoDong_DLLJ_GiftAni[i]:Hide()
			g_HuiLiuHuoDong_DLLJ_RedPoint[i]:Hide()
		end
				
		if gListTooltip ~= nil then
			g_HuiLiuHuoDong_DLLJ_GiftBtn[i]:SetToolTip( gListTooltip[i] );
		end

	end
	
end

-- 显示 限时放送 界面
function HuiLiuHuoDong_ShowPage_FangSong( nhlLevel, nTime )
	
	HuiLiuHuoDong_FenYeBtnClick( 3 );
	g_HuiLiuHuoDong_XSFS_ItemId = {};
		
	for i=1, 3 do
		local nItemId, nShowItemId, nCount, nRawPrice, nPrice, nBonusCount = GetHuiLiu2022ShopItem( nhlLevel, nTime, i-1 );
		if nItemId == nil and nShowItemId == nil and nBonusCount == nil and nCount <= 0 then
			break;
		end
		
		g_HuiLiuHuoDong_XSFS_ItemId[i] = nItemId;
	
		--显示图标
		local theAction = DataPool:CreateActionItemForShow(nShowItemId, nCount)
		if theAction:GetID() ~= 0 then	
			g_HuiLiuHuoDong_XSFS_ActBtn[i]:SetActionItem(theAction:GetID())
			
			-- 道具名
			g_HuiLiuHuoDong_XSFS_Name[i]:SetText( ScriptGlobal_Format("#{JBHL_190803_418}", theAction:GetName() ) );
		end
		
		local nRateH = math.floor( nPrice*10 / nRawPrice );
		local nRateL = math.floor( math.mod(nPrice*10, nRawPrice)*10 / nRawPrice );
		g_HuiLiuHuoDong_XSFS_Rate[i]:SetText( ScriptGlobal_Format("#{JBHL_190803_353}", nRateH, nRateL ) );
		
		--可购买
		g_HuiLiuHuoDong_XSFS_Button[i]:SetText( ScriptGlobal_Format("#{JBHL_190803_354}", nPrice ) );
		if g_HuiLiuHuoDong_XSFS_BuyFlag[i] == 0 then	
			g_HuiLiuHuoDong_XSFS_Button[i]:Enable();
			g_HuiLiuHuoDong_XSFS_Mask[i]:Hide();
		else
			g_HuiLiuHuoDong_XSFS_Button[i]:Disable();
			g_HuiLiuHuoDong_XSFS_Mask[i]:Show();
		end		
				
		-- 原价
		g_HuiLiuHuoDong_XSFS_Price[i]:SetText( ScriptGlobal_Format("#{JBHL_190803_419}", nRawPrice ) );
		
		-- 返代币
		if nBonusCount > 0 then
			g_HuiLiuHuoDong_XSFS_BonusText[i]:SetText( ScriptGlobal_Format("#{JBHL_220120_68}", nBonusCount ) );
			g_HuiLiuHuoDong_XSFS_BonusText[i]:Show();
		else
			g_HuiLiuHuoDong_XSFS_BonusText[i]:Hide();
		end
		
	end	
	
end

-- 显示 双倍惊喜 界面
function HuiLiuHuoDong_ShowPage_JingXi()
	
	HuiLiuHuoDong_FenYeBtnClick( 4 );
	
end


-- 回流手册 显示 界面
function HuiLiuHuoDong_ShowPage_HuiLiuShouCe()

	--获取 获取回流等级
	local nHuiLiuLevel = Lua_GetHuiLiu2022_ShouCeHuiLiuLevel()

	--右下方文字显示
	HuiLiuHuoDong_TimeLeft_Text1:Show();
	HuiLiuHuoDong_TimeLeft_Text2:Show();
	HuiLiuHuoDong_BuyLeftTime_Text1:Hide();
	HuiLiuHuoDong_BuyLeftTime_Text2:Hide();
	HuiLiuHuoDong_AccumulativeDays:Hide();
	HuiLiuHuoDong_TimeLeft_Text3:Hide();
	-- 说明
	g_HuiLiuHuoDong_PageIndex = 6;
	HuiLiuHuoDong_PageInfo:SetText("#{JBHL_220120_43}");
	HuiLiuHuoDong_PageInfo_Help:Show();
	HuiLiuHuoDong_FenYeBtnClick( 6 );

	HuiLiuHuoDong_HuiLiuShouCe_UpdateMissionList() --刷新任务列表

	--获取 当前奖励进度
	g_HuiLiuHuoDong_ShouCeProgress = Lua_GetHuiLiu2022_ShouCeProgress()
	--设置进度奖励道具 
	--g_HuiLiuHuoDong_ShouCeProgress_item[1],g_HuiLiuHuoDong_ShouCeProgress_item[2],g_HuiLiuHuoDong_ShouCeProgress_item[3],g_HuiLiuHuoDong_ShouCeProgress_item[4],g_HuiLiuHuoDong_ShouCeProgress_needProgress[1],g_HuiLiuHuoDong_ShouCeProgress_needProgress[2],g_HuiLiuHuoDong_ShouCeProgress_needProgress[3],g_HuiLiuHuoDong_ShouCeProgress_needProgress[4] = Lua_GetHuiLiu2022_ShouCeGiftTbl(nHuiLiuLevel)
	g_HuiLiuHuoDong_ShouCeProgress_giftFlag[1],g_HuiLiuHuoDong_ShouCeProgress_giftFlag[2],g_HuiLiuHuoDong_ShouCeProgress_giftFlag[3],g_HuiLiuHuoDong_ShouCeProgress_giftFlag[4] = Lua_GetHuiLiu2022_ShouCeGiftFlag()
	
	for i = 1, 4 do
		g_HuiLiuHuoDong_ShouCeProgress_needProgress[i],g_HuiLiuHuoDong_ShouCeProgress_Award["ZhuMeng"],g_HuiLiuHuoDong_ShouCeProgress_Award["RongGui"],g_HuiLiuHuoDong_ShouCeProgress_Award["BangGong"],g_HuiLiuHuoDong_ShouCeProgress_Award["GongZi"],g_HuiLiuHuoDong_ShouCeProgress_Award["YuanBao"],g_HuiLiuHuoDong_ShouCeProgress_Award["Item1ID"],g_HuiLiuHuoDong_ShouCeProgress_Award["Item1Num"],g_HuiLiuHuoDong_ShouCeProgress_Award["Item2ID"],g_HuiLiuHuoDong_ShouCeProgress_Award["Item2Num"] = Lua_GetHuiLiu2022_ShouCeGiftTbl(nHuiLiuLevel,i)
		local str_ZhuMeng = ""
		local str_RongGui = ""
		local str_BangGong = ""
		local str_GongZi = ""
		local str_YuanBao = ""
		local str_Item1 = ""
		local str_Item2 = ""
	
		local bFront = 0

		--筑梦币
		if(g_HuiLiuHuoDong_ShouCeProgress_Award["ZhuMeng"] > 0)then
			str_ZhuMeng = "#G"..tostring(g_HuiLiuHuoDong_ShouCeProgress_Award["ZhuMeng"]).."#Y个#G#{JBHL_220120_78}#Y"
			bFront = 1
		end
		--荣归令
		if(g_HuiLiuHuoDong_ShouCeProgress_Award["RongGui"] > 0)then
			if(bFront == 1)then
				str_RongGui = str_RongGui.."、"
			end
			str_RongGui = str_RongGui.."#G"..tostring(g_HuiLiuHuoDong_ShouCeProgress_Award["RongGui"]).."#Y个#G#{JBHL_220120_79}#Y"
			bFront = 1
		end
		--帮贡
		if(g_HuiLiuHuoDong_ShouCeProgress_Award["BangGong"] > 0)then
			if(bFront == 1)then
				str_BangGong = str_BangGong.."、"
			end
			str_BangGong = str_BangGong.."#G"..tostring(g_HuiLiuHuoDong_ShouCeProgress_Award["BangGong"]).."#G#{JBHL_220120_80}#Y"
			bFront = 1
		end
		--工资
		if(g_HuiLiuHuoDong_ShouCeProgress_Award["GongZi"] > 0)then
			if(bFront == 1)then
				str_GongZi = str_GongZi.."、"
			end
			str_GongZi = str_GongZi.."#G"..tostring(g_HuiLiuHuoDong_ShouCeProgress_Award["GongZi"]).."#G#{JBHL_220120_81}#Y"
			bFront = 1
		end
		--绑元
		if(g_HuiLiuHuoDong_ShouCeProgress_Award["YuanBao"] > 0)then
			if(bFront == 1)then
				str_YuanBao = str_YuanBao.."、"
			end
			str_YuanBao = str_YuanBao.."#G"..tostring(g_HuiLiuHuoDong_ShouCeProgress_Award["YuanBao"]).."#G#{JBHL_220120_82}#Y"
			bFront = 1
		end
		--物品
		if(g_HuiLiuHuoDong_ShouCeProgress_Award["Item1ID"] ~= -1 and g_HuiLiuHuoDong_ShouCeProgress_Award["Item1Num"] > 0)then
			if(bFront == 1)then
				str_Item1 = str_Item1.."、"
			end
			bFront = 1
			str_Item1 = str_Item1.."#G"..tostring(g_HuiLiuHuoDong_ShouCeProgress_Award["Item1Num"]).."#Y个#G"..DataPool:Lua_GetItemNameByIndex( g_HuiLiuHuoDong_ShouCeProgress_Award["Item1ID"]).."#Y" 
		end
		if(g_HuiLiuHuoDong_ShouCeProgress_Award["Item2ID"] ~= -1 and g_HuiLiuHuoDong_ShouCeProgress_Award["Item2Num"] > 0)then
			if(bFront == 1)then
				str_Item2 = str_Item2.."、"
			end
			str_Item2 = str_Item2.."#G"..tostring(g_HuiLiuHuoDong_ShouCeProgress_Award["Item2Num"]).."#Y个#G"..DataPool:Lua_GetItemNameByIndex( g_HuiLiuHuoDong_ShouCeProgress_Award["Item2ID"] ).."#Y"
		end
		
		g_HuiLiuHuoDong_ShouCeProgressItem[i]:SetToolTip( ScriptGlobal_Format(g_HuiLiuHuoDong_ShouCeProgressItemTip[i], g_HuiLiuHuoDong_ShouCeProgress_needProgress[i] )..str_ZhuMeng..str_RongGui..str_BangGong..str_GongZi..str_YuanBao..str_Item1..str_Item2.."。" );
		if(g_HuiLiuHuoDong_ShouCeProgress_giftFlag[i] == false) and (g_HuiLiuHuoDong_ShouCeProgress_needProgress[i] <= g_HuiLiuHuoDong_ShouCeProgress)then
			g_HuiLiuHuoDong_ShouCeProgressItemMask[i]:Hide();
			g_HuiLiuHuoDong_ShouCeProgressItemRedPoint[i]:Show();
		elseif(g_HuiLiuHuoDong_ShouCeProgress_giftFlag[i] == true)then
			g_HuiLiuHuoDong_ShouCeProgressItemMask[i]:Show();
			g_HuiLiuHuoDong_ShouCeProgressItemRedPoint[i]:Hide();
		else 
			g_HuiLiuHuoDong_ShouCeProgressItemMask[i]:Hide();
			g_HuiLiuHuoDong_ShouCeProgressItemRedPoint[i]:Hide();
		end
	end

	HuiLiuHuoDong_HuiLiu_RightProgress:SetProgress(g_HuiLiuHuoDong_ShouCeProgress, g_HuiLiuHuoDong_ShouCeProgress_needProgress[4]);
	HuiLiuHuoDong_HuiLiu_Jindu_Text:SetText(ScriptGlobal_Format("#{JBHL_220120_54}",g_HuiLiuHuoDong_ShouCeProgress,g_HuiLiuHuoDong_ShouCeProgress_needProgress[4]));
	HuiLiuHuoDong_HuiLiu_Jindu:SetToolTip("#{JBHL_220120_53}") --进度条悬浮tip

	
end
--回流手册 刷新任务列表 埋点后刷新
function HuiLiuHuoDong_HuiLiuShouCe_UpdateMissionList_Maidian(MissionIndex,nValue)

	Lua_SetHuiLiu2022_ShouCeMissonFlag(MissionIndex,nValue)

	HuiLiuHuoDong_HuiLiuShouCe_UpdateMissionList()

end

--回流手册 刷新任务列表
function HuiLiuHuoDong_HuiLiuShouCe_UpdateMissionList()

	--获取 获取回流等级
	local nHuiLiuLevel = Lua_GetHuiLiu2022_ShouCeHuiLiuLevel()

	--清空任务列表
	HuiLiuHuoDong_HuiLiu_ListInfo:Clear()

	--读表 获取Mission表的行数
	local nMissionLineCount = Lua_GetHuiLiu2022_ShouCeMissionTblLine()

	local ShouCeMissionList_GotGift_len = 0
	local ShouCeMissionList_CanGift_len = 0
	local ShouCeMissionList_CantGift_len = 0
	local ShouCeMissionList_GotGift = {}--已经领取了代币的任务
	local ShouCeMissionList_CanGift = {}--能领代币但没领的任务
	local ShouCeMissionList_CantGift = {}--不能领代币的任务

	--读表 设界面 
	for i = 0, nMissionLineCount - 1 do

		--根据任务标记获得显示状态 
		--nMissionHuiLiuLevel 任务需要回流等级
		--sIcon 任务图标
		--sInfo 任务介绍
		--nGiveProgress 完成给的代币数
		--nNeedProgress 总共需要完成的次数
		--nIfGo 判断是传送还是醒目提醒
		--sTip 传送坐标或者醒目提醒
		local nMissionHuiLiuLevel,sIcon,sInfo,nGiveProgress,nNeedProgress,nIfGo,sTip,nMissionIndex,nMissionSubIndex,nGiveZhuMeng = Lua_GetHuiLiu2022_ShouCeMissionTbl(i)
		if(nHuiLiuLevel == nMissionHuiLiuLevel)then
			--获取 当前任务进度
			local nMissionProgress = Lua_GetHuiLiu2022_ShouCeMissonFlag(nMissionIndex)
			--获取 当前进度代币是否领取
			local nMissionGift = Lua_GetHuiLiu2022_ShouCeMissonGiftFlag(nMissionSubIndex)

			if(nMissionGift == 1) then--已经领取了进度代币
				ShouCeMissionList_GotGift[ShouCeMissionList_GotGift_len] = {sIcon,sInfo,nGiveProgress,nNeedProgress,nIfGo,sTip,nMissionIndex,nMissionSubIndex,nMissionProgress,nGiveZhuMeng}
				ShouCeMissionList_GotGift_len = ShouCeMissionList_GotGift_len + 1
			elseif (nMissionGift == 0) and (nMissionProgress >= nNeedProgress) then--能领进度代币，但是没领
				ShouCeMissionList_CanGift[ShouCeMissionList_CanGift_len] = {sIcon,sInfo,nGiveProgress,nNeedProgress,nIfGo,sTip,nMissionIndex,nMissionSubIndex,nMissionProgress,nGiveZhuMeng}
				ShouCeMissionList_CanGift_len = ShouCeMissionList_CanGift_len + 1
			elseif (nMissionGift == 0) and (nMissionProgress < nNeedProgress) then--不能领代币
				ShouCeMissionList_CantGift[ShouCeMissionList_CantGift_len] = {sIcon,sInfo,nGiveProgress,nNeedProgress,nIfGo,sTip,nMissionIndex,nMissionSubIndex,nMissionProgress,nGiveZhuMeng}
				ShouCeMissionList_CantGift_len = ShouCeMissionList_CantGift_len + 1
			end
		end
	end
	
	--能领未领取的任务
	for i = 0, ShouCeMissionList_CanGift_len - 1 do
		local Mis =  HuiLiuHuoDong_HuiLiu_ListInfo:AddChild("HuiLiuHuoDong_HuiLiu_Info1")	
		g_HuiLiuHuoDong_ShouCeMissionList[ShouCeMissionList_CanGift[i][8]] = Mis
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Item1"):Show() --任务图标
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Item1"):SetProperty("Image", ShouCeMissionList_CanGift[i][1])--sIcon
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text"):Show() --任务介绍
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text"):SetText(ScriptGlobal_Format("#{JBHL_220120_44}", ShouCeMissionList_CanGift[i][2] ))--sInfo
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text2"):Show() --当前进度
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text2"):SetText(ScriptGlobal_Format("#{JBHL_220120_45}", ShouCeMissionList_CanGift[i][9] , ShouCeMissionList_CanGift[i][4] ))--nMissionProgress , nNeedProgress
		if(ShouCeMissionList_CanGift[i][10] > 0)then
			Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text3"):Show() --给代币数
			Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text3"):SetText(ScriptGlobal_Format("#{JBHL_220120_46}", ShouCeMissionList_CanGift[i][10] ))--nGiveProgress
		else
			Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text3"):Hide() --给代币数
		end
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn"):Show()	--前进按钮
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn_Mask"):Hide()	--前进按钮蒙版
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn_Tips"):Hide()	--红点隐藏
		
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn"):SetText("#{JBHL_220120_48}")--前进按钮变成领取
		--Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Item1_Mask"):Hide()--任务图标隐藏蒙版
		Mis:SetSubItemEvent("HuiLiuHuoDong_HuiLiu_Info1_Btn", "Clicked", "HuiLiuHuoDong_HuiLiuShouCe_GiveProgress("..ShouCeMissionList_CanGift[i][8]..")")--前进按钮点击设为
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn_Tips"):Show()--红点显示
	end
	--不能领的任务
	for i = 0, ShouCeMissionList_CantGift_len - 1 do
		local Mis =  HuiLiuHuoDong_HuiLiu_ListInfo:AddChild("HuiLiuHuoDong_HuiLiu_Info1")	
		g_HuiLiuHuoDong_ShouCeMissionList[ShouCeMissionList_CantGift[i][8]] = Mis
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Item1"):Show() --任务图标
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Item1"):SetProperty("Image", ShouCeMissionList_CantGift[i][1])--sIcon
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text"):Show() --任务介绍
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text"):SetText(ScriptGlobal_Format("#{JBHL_220120_44}", ShouCeMissionList_CantGift[i][2] ))--sInfo
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text2"):Show() --当前进度
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text2"):SetText(ScriptGlobal_Format("#{JBHL_220120_45}", ShouCeMissionList_CantGift[i][9] , ShouCeMissionList_CantGift[i][4] ))--nMissionProgress , nNeedProgress
		if(ShouCeMissionList_CantGift[i][10] > 0)then
			Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text3"):Show() --给代币数
			Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text3"):SetText(ScriptGlobal_Format("#{JBHL_220120_46}", ShouCeMissionList_CantGift[i][10] ))--nGiveProgress
		else
			Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text3"):Hide() --给代币数
		end
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn"):Show()	--前进按钮
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn_Mask"):Hide()	--前进按钮蒙版
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn_Tips"):Hide()	--红点隐藏
		
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn"):SetText("#{JBHL_220120_47}")--前进按钮变成前往
		--Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Item1_Mask"):Hide()--任务图标隐藏蒙版
		if(ShouCeMissionList_CantGift[i][5] == 0)then --nIfGo
			Mis:SetSubItemEvent("HuiLiuHuoDong_HuiLiu_Info1_Btn", "Clicked", "HuiLiuHuoDong_HuiLiuShouCe_NotifyTip('"..ShouCeMissionList_CantGift[i][6].."')")--sTip
		end
		if(ShouCeMissionList_CantGift[i][5] == 1)then
			Mis:SetSubItemEvent("HuiLiuHuoDong_HuiLiu_Info1_Btn", "Clicked", "HuiLiuHuoDong_HuiLiuShouCe_transfer("..ShouCeMissionList_CantGift[i][8]..")")--nMissionSubIndex
		end
	end
	--已经领取的任务
	for i = 0, ShouCeMissionList_GotGift_len - 1 do
		local Mis =  HuiLiuHuoDong_HuiLiu_ListInfo:AddChild("HuiLiuHuoDong_HuiLiu_Info1")	
		g_HuiLiuHuoDong_ShouCeMissionList[ShouCeMissionList_GotGift[i][8]] = Mis
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Item1"):Show() --任务图标
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Item1"):SetProperty("Image", ShouCeMissionList_GotGift[i][1])--sIcon
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text"):Show() --任务介绍
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text"):SetText(ScriptGlobal_Format("#{JBHL_220120_44}", ShouCeMissionList_GotGift[i][2] ))--sInfo
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text2"):Show() --当前进度
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text2"):SetText(ScriptGlobal_Format("#{JBHL_220120_45}", ShouCeMissionList_GotGift[i][9] , ShouCeMissionList_GotGift[i][4] ))--nMissionProgress , nNeedProgress
		if(ShouCeMissionList_GotGift[i][10] > 0)then
			Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text3"):Show() --给代币数
			Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text3"):SetText(ScriptGlobal_Format("#{JBHL_220120_46}", ShouCeMissionList_GotGift[i][10] ))--nGiveProgress
		else
			Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Text3"):Hide() --给代币数
		end
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn"):Show()	--前进按钮
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn_Mask"):Hide()	--前进按钮蒙版
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn_Tips"):Hide()	--红点隐藏
		
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn"):Hide()--前进按钮变成已领取
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn_Mask"):Show()	--前进按钮蒙版
		--Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Item1_Mask"):Show()--任务图标加蒙版
		Mis:SetSubItemEvent("HuiLiuHuoDong_HuiLiu_Info1_Btn", "Clicked", "HuiLiuHuoDong_HuiLiuShouCe_NotifyTip('#{JBHL_220120_60}')")--前进按钮点击设为 醒目提示 已经领取过代币 JBHL_220120_60
	end


end

-- 回流手册 设置进度奖励道具已领取蒙版
function HuiLiuHuoDong_ShowPage_HuiLiuShouCe_SetItem(nIndex)
	Lua_SetHuiLiu2022_ShouCeGiftFlag(nIndex)
	g_HuiLiuHuoDong_ShouCeProgressItemMask[nIndex]:Show();
	g_HuiLiuHuoDong_ShouCeProgressItemRedPoint[nIndex]:Hide();
end

-- 回流手册 刷新任务列表
function HuiLiuHuoDong_ShowPage_HuiLiuShouCe_UpdateMissionList(nMissionSubIndex,nProgressValueAdd,needProgress)

	--获取 获取回流等级
	local nHuiLiuLevel = Lua_GetHuiLiu2022_ShouCeHuiLiuLevel()
	if nHuiLiuLevel < 1 then --外挂发包 没有打开界面，未能获取到ShouCeHuiLiuLevel
		return 
	end

	--已领取进度设置 这里加是因为客户端只有打开界面时被下发数据
	Lua_SetHuiLiu2022_ShouCeMissonGiftFlag(nMissionSubIndex,1)
	
	local Mis = g_HuiLiuHuoDong_ShouCeMissionList[nMissionSubIndex]
	if Mis ~= nil then
		--前进按钮变成已领取
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn"):Hide()
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn_Mask"):Show()	--前进按钮蒙版
		--任务图标加蒙版
		--Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Item1_Mask"):Show()
		--前进按钮点击设为 醒目提示 已经领取过代币 JBHL_220120_60
		Mis:SetSubItemEvent("HuiLiuHuoDong_HuiLiu_Info1_Btn", "Clicked", "HuiLiuHuoDong_HuiLiuShouCe_NotifyTip('#{JBHL_220120_60}')")
		--红点设置
		Mis:GetSubItem("HuiLiuHuoDong_HuiLiu_Info1_Btn_Tips"):Hide()
	end
	--获取 当前奖励进度
	g_HuiLiuHuoDong_ShouCeProgress = nProgressValueAdd + g_HuiLiuHuoDong_ShouCeProgress
	HuiLiuHuoDong_HuiLiu_RightProgress:SetProgress(g_HuiLiuHuoDong_ShouCeProgress, needProgress);
	HuiLiuHuoDong_HuiLiu_Jindu_Text:SetText(ScriptGlobal_Format("#{JBHL_220120_54}",g_HuiLiuHuoDong_ShouCeProgress,needProgress));

	g_HuiLiuHuoDong_ShouCeProgress_giftFlag[1],g_HuiLiuHuoDong_ShouCeProgress_giftFlag[2],g_HuiLiuHuoDong_ShouCeProgress_giftFlag[3],g_HuiLiuHuoDong_ShouCeProgress_giftFlag[4] = Lua_GetHuiLiu2022_ShouCeGiftFlag()
	--刷新底下进度奖励
	for i = 1, 4 do
		g_HuiLiuHuoDong_ShouCeProgress_needProgress[i],g_HuiLiuHuoDong_ShouCeProgress_Award["ZhuMeng"],g_HuiLiuHuoDong_ShouCeProgress_Award["RongGui"],g_HuiLiuHuoDong_ShouCeProgress_Award["BangGong"],g_HuiLiuHuoDong_ShouCeProgress_Award["GongZi"],g_HuiLiuHuoDong_ShouCeProgress_Award["YuanBao"],g_HuiLiuHuoDong_ShouCeProgress_Award["Item1ID"],g_HuiLiuHuoDong_ShouCeProgress_Award["Item1Num"],g_HuiLiuHuoDong_ShouCeProgress_Award["Item2ID"],g_HuiLiuHuoDong_ShouCeProgress_Award["Item2Num"] = Lua_GetHuiLiu2022_ShouCeGiftTbl(nHuiLiuLevel,i)
		
		if(g_HuiLiuHuoDong_ShouCeProgress_giftFlag[i] == false) and ( g_HuiLiuHuoDong_ShouCeProgress_needProgress[i] ~= nil and g_HuiLiuHuoDong_ShouCeProgress_needProgress[i] <= g_HuiLiuHuoDong_ShouCeProgress)then
			g_HuiLiuHuoDong_ShouCeProgressItemMask[i]:Hide();
			g_HuiLiuHuoDong_ShouCeProgressItemRedPoint[i]:Show();
		elseif(g_HuiLiuHuoDong_ShouCeProgress_giftFlag[i] == true)then
			g_HuiLiuHuoDong_ShouCeProgressItemMask[i]:Show();
			g_HuiLiuHuoDong_ShouCeProgressItemRedPoint[i]:Hide();
		else 
			g_HuiLiuHuoDong_ShouCeProgressItemMask[i]:Hide();
			g_HuiLiuHuoDong_ShouCeProgressItemRedPoint[i]:Hide();
		end
	end
end


-- 回流手册 获取进度代币
function HuiLiuHuoDong_HuiLiuShouCe_GiveProgress(nMissionSubIndex)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "HuiLiuShouCe_GetProgress" )
		Set_XSCRIPT_ScriptID( 808112 )
		Set_XSCRIPT_Parameter( 0, nMissionSubIndex )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

-- 回流手册 任务前往按钮 按下事件 醒目提示
function HuiLiuHuoDong_HuiLiuShouCe_NotifyTip(msg)
	PushDebugMessage(msg);
end

-- 回流手册 任务前往按钮 按下事件 位移传送
function HuiLiuHuoDong_HuiLiuShouCe_transfer(nMissionSubIndex)
	local Scene,PosX,PosY,Name = Lua_GetHuiLiu2022_ShouCeNpcPosInfo(nMissionSubIndex)

	if "无" ~= Name then
		AutoRuntoTargetExWithName(PosX, PosY, Scene, tostring(Name))
	else
		AutoRunToTargetEx(PosX, PosY, Scene)
	end
end

-- 回流手册 进度奖励 按下
function HuiLiuHuoDong_HuiLiuShouCe_ProgressItemClick(nIndex)
	
	if (g_HuiLiuHuoDong_ShouCeProgress < g_HuiLiuHuoDong_ShouCeProgress_needProgress[nIndex]) then
		PushDebugMessage("#{JBHL_220120_65}");
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "HuiLiuShouCe_GetGift" )
		Set_XSCRIPT_ScriptID( 808112 )
		Set_XSCRIPT_Parameter( 0, nIndex )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function HuiLiuHuoDong_FenYeBtnClick( index )
	if index == nil or index <= 0 or index > 6 then
		return
	end
		
	for i=1, 6 do
		if g_HuiLiuHuoDong_Pages[i] ~= nil then
			g_HuiLiuHuoDong_Pages[i]:Hide();
		end
		if g_HuiLiuHuoDong_FenYeBtn[i] ~= nil then
			g_HuiLiuHuoDong_FenYeBtn[i]:SetCheck(0);
		end
	end
	
	if g_HuiLiuHuoDong_Pages[index] ~= nil then
		g_HuiLiuHuoDong_Pages[index]:Show();
	end
	if g_HuiLiuHuoDong_FenYeBtn[index] ~= nil then
		g_HuiLiuHuoDong_FenYeBtn[index]:SetCheck(1);
	end
end

function HuiLiuHuoDong_ShowContent( index, nLeftTime, nHLLevel, nBuyTime, nLoginDays, nShowSBJX )

	HuiLiuHuoDong_TimeLeft_Text1:Hide();
	HuiLiuHuoDong_TimeLeft_Text2:Hide();
	HuiLiuHuoDong_BuyLeftTime_Text1:Hide();
	HuiLiuHuoDong_BuyLeftTime_Text2:Hide();
	HuiLiuHuoDong_AccumulativeDays:Hide();
	HuiLiuHuoDong_TimeLeft_Text3:Hide();
		
	-- 帮助按钮	
	g_HuiLiuHuoDong_PageIndex = index;
	HuiLiuHuoDong_PageInfo_Help:Show();
	
	-- 说明
	local lstDict={"#{JBHL_190803_372}", "#{JBHL_190803_378}", "#{JBHL_190803_381}", "#{JBHL_190803_392}","#{JBHL_190803_15}","#{JBHL_190803_42}"}; 
	if Player:GetData("Is2606S") == 1 then
		lstDict={"#{JBHL_190803_372}", "#{QXFXG_260703_3}", "#{JBHL_190803_381}", "#{JBHL_190803_392}","#{JBHL_190803_15}","#{JBHL_190803_42}"}; 
	end
	if lstDict[index] ~= nil then
		HuiLiuHuoDong_PageInfo:SetText( lstDict[index] );
	end
			
	-- 回流特权剩余时间
	if index == 1 or index == 2 or index == 3 or index == 4 or index == 5 or index == 6 then
		nLeftTime = tonumber(nLeftTime);
		if nLeftTime > 0 then
			local nDay = math.floor(nLeftTime / (3600 * 24));
			local nHour = math.ceil( math.mod( nLeftTime, 3600*24)/ 3600 )
		
			HuiLiuHuoDong_TimeLeft_Text2:SetText( ScriptGlobal_Format("#{JBHL_190803_288}", nDay, nHour) );
			HuiLiuHuoDong_TimeLeft_Text1:Show();
			HuiLiuHuoDong_TimeLeft_Text2:Show();
		end
	
		-- 图片	
		if g_HuiLiuHuoDong_LevelImage[nHLLevel] ~= nil then
			HuiLiuHuoDong_TimeLeft_but:SetProperty("Image", g_HuiLiuHuoDong_LevelImage[nHLLevel])
		end
		HuiLiuHuoDong_TimeLeft_but:SetToolTip( ScriptGlobal_Format("#{JBHL_190803_417}", nHLLevel) );
	end
		
	-- 剩余购买时间
	if index == 3 then
		nBuyTime = tonumber(nBuyTime)
		if nBuyTime > 0 then
			local nBuyTime = tonumber(g_HuiLiuHuoDong_XSFS_BuyTime)
			local nDay = math.floor(nBuyTime / (3600 * 24));
			local nHour = math.ceil( math.mod( nBuyTime, 3600*24)/ 3600 )
			HuiLiuHuoDong_BuyLeftTime_Text2:SetText( ScriptGlobal_Format("#{JBHL_190803_298}", nDay, nHour ) );
		
			HuiLiuHuoDong_BuyLeftTime_Text1:Show();
			HuiLiuHuoDong_BuyLeftTime_Text2:Show();
		end
	end
	
	-- 累计登录天数
	if index == 2 then
		nLoginDays = tonumber(nLoginDays)
		if nLoginDays > 0 then
			HuiLiuHuoDong_AccumulativeDays:SetText( ScriptGlobal_Format("#{JBHL_190803_327}", nLoginDays) );
			HuiLiuHuoDong_AccumulativeDays:Show();
		end
	end
	
	--
	if index == 4 then
		HuiLiuHuoDong_TimeLeft_Text3:Show();
	end
		
	-- 双倍惊喜
	if nShowSBJX > 0 then
		HuiLiuHuoDong_SBJX_Btn:Show();
	else
		HuiLiuHuoDong_SBJX_Btn:Hide();
	end
	
	--筑梦按钮
	if nHLLevel >= 5 and nHLLevel <= 6 then
		HuiLiuHuoDong_ZM_Btn:Show()
	else
		HuiLiuHuoDong_ZM_Btn:Hide()
	end

end

function HuiLiuHuoDong_DLLJ_PlayAni(nEnable, nIndex)
	if nEnable == 0 then
		return
	end

	g_HuiLiuHuoDong_DLLJ_GiftAni[nIndex]:Show()
	g_HuiLiuHuoDong_DLLJ_RedPoint[nIndex]:Hide()
	g_HuiLiuHuoDong_DLLJ_GiftAni[nIndex]:SetProperty("Animate", "WeekHuoyuehaoli_open_Flash");
	SetTimer("HuiLiuHuoDong","HuiLiuHuoDong_DLLJ_TimeReach()",1000)

end

function HuiLiuHuoDong_DLLJ_TimeReach()
	KillTimer("HuiLiuHuoDong_DLLJ_TimeReach()");
	
	for i = 1, 4 do
		local nVisb = g_HuiLiuHuoDong_DLLJ_GiftAni[i]:IsVisible()
		if nVisb then
			g_HuiLiuHuoDong_DLLJ_GiftBtn[i]:Hide()
			g_HuiLiuHuoDong_DLLJ_GiftEmpty[i]:Show()
			g_HuiLiuHuoDong_DLLJ_RedPoint[i]:Hide()
		end
	end
end

function HuiLiuHuoDong_DLLJ_NoItemClick( index )
end

-- 刷新小红点
function HuiLiuHuoDong_UpdateRedPointInUI()

	HuiLiuHuoDong_Left_Buttontab01:SetProperty("Selected", "False")
	HuiLiuHuoDong_Left_Buttontab03:SetProperty("Selected", "False")
	HuiLiuHuoDong_Left_Buttontab04:SetProperty("Selected", "True")
	
	if DataPool:Lua_IsRedPointInUIShow( 22 ) == 1 then
		HuiLiuHuoDong_RGHL_Btn_RedDot:Show()
	else
		HuiLiuHuoDong_RGHL_Btn_RedDot:Hide()
	end
	
	if DataPool:Lua_IsRedPointInUIShow( 23 ) == 1 then
		HuiLiuHuoDong_DLLJ_Btn_RedDot:Show()
	else
		HuiLiuHuoDong_DLLJ_Btn_RedDot:Hide()
	end
	
	if DataPool:Lua_IsRedPointInUIShow( 24 ) == 1 then
		HuiLiuHuoDong_XSFS_Btn_RedDot:Show()
	else
		HuiLiuHuoDong_XSFS_Btn_RedDot:Hide()
	end
	
	if DataPool:Lua_IsRedPointInUIShow( 25 ) == 1 then
		HuiLiuHuoDong_SBJX_Btn_RedDot:Show()
	else
		HuiLiuHuoDong_SBJX_Btn_RedDot:Hide()
	end

	if DataPool:Lua_IsRedPointInUIShow( 36 ) == 1 then
		HuiLiuHuoDong_HLSC_Btn_RedDot:Show()
	else
		HuiLiuHuoDong_HLSC_Btn_RedDot:Hide()
	end
	
	local lstPow = { 1000, 100,  1 };
	for i=1, 3 do
		local nIsShow = math.mod( math.floor(g_HuiLiuHuoDong_UI_RedPoint/lstPow[i]), 10);
		if nIsShow > 0 then
			g_HuiLiuHuoDong_Ctrl_RedPoint[i]:Show();
		else
			g_HuiLiuHuoDong_Ctrl_RedPoint[i]:Hide();
		end
	end
	
end

--荣归大礼界面领取按钮
function HuiLiuHuoDong_RGHL_GetPrize( index )

	if index < 1 or index > 3 then
		return
	end
	
	if g_HuiLiuHuoDong_RGHL_BtnState[index] ~= 1 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetOldFriendBonus" )
		Set_XSCRIPT_ScriptID( 808112 )
		Set_XSCRIPT_Parameter( 0, index )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
				
end

--领取每日登录的奖励
function HuiLiuHuoDong_DLLJ_GetPrize( index )

	if index < 1 or index > 2 then
		return
	end
	
	if g_HuiLiuHuoDong_DLLJ_BtnState[index] ~= 1 then
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetOldFriendBonus" )
		Set_XSCRIPT_ScriptID( 808112 )
		Set_XSCRIPT_Parameter( 0, index+3 )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
				
end

-- 领取登录天数的奖励
function HuiLiuHuoDong_GetGiftItemPrize( index )
	if index < 1 or index > 4 then
		return
	end
	
	-- 检查是否领取过
	if g_HuiLiuHuoDong_DLLJ_GiftState[index] ~= 1 then
		PushDebugMessage("#{JBHL_190803_347}");
		return
	end
	
	-- 检查天数
	if g_HuiLiuHuoDong_DLLJ_Days[index] == nil or g_HuiLiuHuoDong_DLLJ_Days[index] > g_HuiLiuHuoDong_LoginDays then
		PushDebugMessage("#{JBHL_190803_348}");
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetRefluencePrivilegeGift" )
		Set_XSCRIPT_ScriptID( 808112 )
		Set_XSCRIPT_Parameter( 0, index )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--限时放送领取
function HuiLiuHuoDong_XSFS_GetPrize( index )

	if index < 1 or index > 3 or g_HuiLiuHuoDong_XSFS_ItemId[index] == nil then
		return
	end
	
	-- 检查是否领取过
	if g_HuiLiuHuoDong_XSFS_BuyFlag[index] > 0 then
		PushDebugMessage("#{JBHL_190803_347}");
		return
	end
		
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "BuyFangSongItem" )
		Set_XSCRIPT_ScriptID( 808112 )
		Set_XSCRIPT_Parameter( 0, index )
		Set_XSCRIPT_Parameter( 1, g_HuiLiuHuoDong_XSFS_ItemId[index] )
		Set_XSCRIPT_Parameter( 2, 0 )
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
		
end

function HuiLiuHuoDong_OnHiden()

	KillTimer("HuiLiuHuoDong_DLLJ_TimeReach()");
	
end

function HuiLiuHuoDong_OnClosed()
	
	this:Hide();
	
end

function HuiLiuHuoDong_ResetPos( bReset )
	if bReset <= 0 then
		return
	end
	
	local CurUIPos = Variable:GetVariable("JieBanUIPos")
	if( CurUIPos ~= nil) then
	    HuiLiuHuoDong:SetProperty("UnifiedPosition", CurUIPos )
	end
	
end

function HuiLiuHuoDong_On_ResetPos()
  HuiLiuHuoDong:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--页面切换 1、结伴任务 2、商店 3、回流任务 
function HuiLiuHuoDong_Project_Clicked(index)
	if index == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenJiebanMission" )
			Set_XSCRIPT_ScriptID( 893195 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif index == 2 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenHuiliuMission" )
			Set_XSCRIPT_ScriptID( 893229 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
	elseif index == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OpenJiebanShop" )
			Set_XSCRIPT_ScriptID( 893196 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	elseif index == 4 then
		return
	end
	
	Variable:SetVariable("JieBanUIPos", HuiLiuHuoDong:GetProperty("UnifiedPosition"), 1)
end

--页面切换： 1、荣归好礼，2、登录领奖，3，限时放送，4、双倍惊喜
function HuiLiuHuoDong_FenYe_OnClick( index )
	
	if index == 1 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowHuiGuiUIRongGui")
			Set_XSCRIPT_ScriptID(808112)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()

	elseif index == 2 then
		
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowHuiGuiUILingJiang")
			Set_XSCRIPT_ScriptID(808112)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		
	elseif index == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowHuiGuiUIXianShiFangSong")
			Set_XSCRIPT_ScriptID(808112)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		
	elseif index == 4 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowHuiGuiUIJingXi")
			Set_XSCRIPT_ScriptID(808112)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	
	elseif index == 5 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowHuiGuiUIZhumeng")
			Set_XSCRIPT_ScriptID(888965)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	elseif index == 6 then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("ShowHuiGuiUIHuiLiuShouCe")
			Set_XSCRIPT_ScriptID(808112)
			Set_XSCRIPT_Parameter(0,1)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
		
	Variable:SetVariable("JieBanUIPos", HuiLiuHuoDong:GetProperty("UnifiedPosition"), 1)
	
end

function HuiLiuHuoDong_Description_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnShowHelp")
		Set_XSCRIPT_ScriptID(808112)
		Set_XSCRIPT_Parameter(0, g_HuiLiuHuoDong_PageIndex) --1: JBHL_190803_373    2:JBHL_190803_377
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end


-- 显示 筑梦 界面
function HuiLiuHuoDong_ShowPage_ZhuMeng()
	
	HuiLiuHuoDong_FenYeBtnClick( 5 );
	
	local nHuiliuLevel = g_HuiLiuHuoDong_HuiliuLevel
	if g_HuiLiuHuoDong_ZM_Status == 0 then
		HuiLiuHuoDong_ZhuMeng_ZhuMeng:Show()
		HuiLiuHuoDong_ZhuRu:Hide()
		if nHuiliuLevel >=5 and nHuiliuLevel <= 6 then
			for i = 1, 6 do
				local nShowItemId = g_HuiLiuHuoDong_ZM_Item[i].item2
				local nCount = g_HuiLiuHuoDong_ZM_Item[i].num
				local nDaibi = g_HuiLiuHuoDong_ZM_Item[i].cnt
				--显示图标
				local theAction = DataPool:CreateActionItemForShow(nShowItemId, nCount)
				if theAction:GetID() ~= 0 then	
					g_HuiLiuHuoDong_ZM_ActBtn[i]:SetActionItem(theAction:GetID())
					-- 道具名
					g_HuiLiuHuoDong_ZM_ActName[i]:SetText( ScriptGlobal_Format("#{JBHL_220120_16}", theAction:GetName() ) );
					--代币数
					--g_HuiLiuHuoDong_ZM_DaibiText[i]:SetText( ScriptGlobal_Format("#{JBHL_220120_17}", nDaibi ) );
				end
				if g_HuiLiuHuoDong_ZM_SelectItem == 0 then
					HuiLiuHuoDong_Zhumeng_Select(0)
				end
			end
		end
	elseif g_HuiLiuHuoDong_ZM_Status >= 1 then
		HuiLiuHuoDong_ZhuMeng_ZhuMeng:Hide()
		HuiLiuHuoDong_ZhuRu:Show()
		local nIndex = g_HuiLiuHuoDong_ZM_SelectIndex
		if nIndex < 1 or nIndex > 6 then
			return
		end
		if nHuiliuLevel >=5 and nHuiliuLevel <= 6 then
			local nShowItemId = g_HuiLiuHuoDong_ZM_Item[nIndex].item2
			local nCount = g_HuiLiuHuoDong_ZM_Item[nIndex].num
			local nNeedDaibi = g_HuiLiuHuoDong_ZM_Item[nIndex].cnt
			local curDaibi = g_HuiLiuHuoDong_ZM_Daibi
			--显示图标
			local theAction = DataPool:CreateActionItemForShow(nShowItemId, nCount)
			if theAction:GetID() ~= 0 then	
				HuiLiuHuoDong_ZhuRu_Item1:SetActionItem(theAction:GetID())
				-- 道具名
				HuiLiuHuoDong_ZhuRu_Info1_Text:SetText( ScriptGlobal_Format("#{JBHL_220120_16}", theAction:GetName() ) );
				--代币数
				HuiLiuHuoDong_ZhuRu_Jindu:SetText( ScriptGlobal_Format("#{JBHL_220120_31}", curDaibi,  nNeedDaibi) );
			end		
			
			if g_HuiLiuHuoDong_ZM_Status == 2 then--已领取
				HuiLiuHuoDong_ZhuRu_Info1_Btn:Disable()
				HuiLiuHuoDong_ZhuRu_Info1_Btn:SetText("已领取")
				HuiLiuHuoDong_ZhuRu_Jindu:SetText( ScriptGlobal_Format("#{JBHL_220120_31}", nNeedDaibi,  nNeedDaibi) );
				HuiLiuHuoDong_ZhuRu_RightProgress:SetProgress(nNeedDaibi, nNeedDaibi)
			else
				HuiLiuHuoDong_ZhuRu_Info1_Btn:Enable()
				HuiLiuHuoDong_ZhuRu_Info1_Btn:SetText("领取")
				HuiLiuHuoDong_ZhuRu_RightProgress:SetProgress(curDaibi, nNeedDaibi)
				
				local nDay = math.floor(g_HuiLiuHuoDong_lefttime / (3600 * 24));
				local huiliudays = 14-nDay
				if huiliudays >= 1 and huiliudays <= 4 then
					HuiLiuHuoDong_ZhuRu_Info1_Btn:SetToolTip("#{JBHL_220120_89}")
				else
					HuiLiuHuoDong_ZhuRu_Info1_Btn:SetToolTip("#{JBHL_220120_32}")
				end
			end
			
		end
	end

end

function HuiLiuHuoDong_Zhumeng_Select(nIndex)
	if nIndex >= 1 and nIndex <= 6 then
		g_HuiLiuHuoDong_ZM_SelectItem = nIndex
	end
	for i = 1, 6 do
		if i == nIndex then
			g_HuiLiuHuoDong_ZM_ItemMask[i]:Show()
		else
			g_HuiLiuHuoDong_ZM_ItemMask[i]:Hide()
		end
	end
end
function HuiLiuHuoDong_StartZhumeng_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("StartZhumeng")
		Set_XSCRIPT_ScriptID(888965)
		Set_XSCRIPT_Parameter(0, g_HuiLiuHuoDong_ZM_SelectItem) 
		Set_XSCRIPT_Parameter(1, 0) 
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end

function HuiLiuHuoDong_GetZhumeng_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetZhumengReward")
		Set_XSCRIPT_ScriptID(888965)
		Set_XSCRIPT_Parameter(0, 0) 
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end