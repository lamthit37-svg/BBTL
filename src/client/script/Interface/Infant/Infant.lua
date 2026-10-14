--Infant.lua
--*********************
--娃娃主界面
--*********************
local g_CameraHeight = 1;     --摄影机高度
local g_CameraDistance = 2;   --摄影机距离
local g_CameraPitch = 3;      --摄影机角度

local g_CurSelInfantIndex = 0;
local g_MaxInfantCount = 0;

local g_ButtonCDTime = 5; --按钮冷却时间
local g_ButtonLastTime = 0;

local g_CurCheckBox = 0   --右侧分页 0为基础信息（默认） 1为英雄信息
--各属性索引
local 	HeroPoisonAttack = 0
local	HeroXuanAttack = 1
local	HeroFireAttack = 2
local	HeroIceAttack = 3
local	HeroCon = 4
local	HeroDex = 5
local	HeroMiss = 6
local	HeroCritical = 7
local	HeroHit = 8

local g_ui_open_flag = 0

local g_default_bk_image = ""

local g_SexName = {"#{XY_0110_63}", "#{XY_0110_62}"}; --女 男
local g_StageName = {
	"#{ZNJCS_130825_112}",
	"#{ZNJCS_130825_113}",
	"#{ZNJCS_130825_114}",
	"#{ZNJCS_130825_115}"
};

local g_LevelToolTip = {
	"#{ZNJCS_130825_121}",
	"#{ZNJCS_130825_122}",
	"#{ZNJCS_130825_123}",
	"#{ZNJCS_130825_124}"
};

local g_TreatBadStatusAction_btn = {
	"#{ZNJCS_130825_36}",
	"#{ZNJCS_130825_38}",
	"#{ZNJCS_130825_40}",
	"#{ZNJCS_130825_42}"
}
local g_TreatBadStatusAction_tips = {
	"#{ZNJCS_130825_37}",
	"#{ZNJCS_130825_39}",
	"#{ZNJCS_130825_41}",
	"#{ZNJCS_130825_43}"
}
local g_TreatBadStatusAction_playtext = {
	"#{ZNJCS_130825_45}",
	"#{ZNJCS_130825_46}",
	"#{ZNJCS_130825_47}",
	"#{ZNJCS_130825_48}"
}

--解除特殊状态音效
-- local g_TreatBadStatusAction_playsound = {
-- 	[1] = {
-- 			[0] = {[0] = 2148, [1] = 2137},
-- 			[1] = {[0] = 2148, [1] = 2137},
-- 			[2] = {[0] = 2170, [1] = 2159},
-- 			[3] = {[0] = 2170, [1] = 2159},
-- 		},
-- 	[2] = {
-- 			[0] = {[0] = 2149, [1] = 2138},
-- 			[1] = {[0] = 2149, [1] = 2138},
-- 			[2] = {[0] = 2171, [1] = 2160},
-- 			[3] = {[0] = 2171, [1] = 2160},
-- 		},
-- 	[3] = {
-- 			[0] = {[0] = 2150, [1] = 2139},
-- 			[1] = {[0] = 2150, [1] = 2139},
-- 			[2] = {[0] = 2172, [1] = 2161},
-- 			[3] = {[0] = 2172, [1] = 2161},
-- 		},
-- 	[4] = {
-- 			[0] = {[0] = 2151, [1] = 2140},
-- 			[1] = {[0] = 2151, [1] = 2140},
-- 			[2] = {[0] = 2173, [1] = 2162},
-- 			[3] = {[0] = 2173, [1] = 2162},
-- 		},
-- }

--特殊状态音效
-- local g_BadStatusAction_playsound = {
-- 	[1] = {
-- 			[1] = {[0] = 2152, [1] = 2141},
-- 			[2] = {[0] = 2174, [1] = 2163},
-- 		},
-- 	[2] = {
-- 			[1] = {[0] = 2153, [1] = 2142},
-- 			[2] = {[0] = 2175, [1] = 2164},
-- 		},
-- 	[3] = {
-- 			[1] = {[0] = 2154, [1] = 2143},
-- 			[2] = {[0] = 2176, [1] = 2165},
-- 		},
-- 	[4] = {
-- 			[1] = {[0] = 2155, [1] = 2144},
-- 			[2] = {[0] = 2177, [1] = 2166},
-- 		},
-- }

local g_BanterInfant_playtext = {
	{"#{ZNJCS_130825_52}","#{ZNJCS_130825_53}","#{ZNJCS_130825_54}"},
	{"#{ZNJCS_130825_55}","#{ZNJCS_130825_56}","#{ZNJCS_130825_57}"},
	{"#{ZNJCS_130825_58}","#{ZNJCS_130825_59}","#{ZNJCS_130825_60}"},
}
--浅层 交互音效
-- local g_BanterInfant_playsound = {
-- 	[1] = {
-- 			[0] = {[0] = 2156, [1] = 2145},
-- 			[1] = {[0] = 2156, [1] = 2145},
-- 			[2] = {[0] = 2178, [1] = 2167},
-- 			[3] = {[0] = 2178, [1] = 2167},
-- 		},
-- 	[2] = {
-- 			[0] = {[0] = 2157, [1] = 2146},
-- 			[1] = {[0] = 2157, [1] = 2146},
-- 			[2] = {[0] = 2179, [1] = 2168},
-- 			[3] = {[0] = 2179, [1] = 2168},
-- 		},
-- 	[3] = {
-- 			[0] = {[0] = 2158, [1] = 2147},
-- 			[1] = {[0] = 2158, [1] = 2147},
-- 			[2] = {[0] = 2180, [1] = 2169},
-- 			[3] = {[0] = 2180, [1] = 2169},
-- 		},
-- }
local g_HealthTypeToolTip = {
	"#{ZNJCS_130825_32}",
	"#{ZNJCS_130825_33}",
	"#{ZNJCS_130825_34}",
	"#{ZNJCS_130825_35}",
}


local g_HealthTypeImage = {
	"set:UIIcons image:UI_InfantSP_Ill",
	"set:UIIcons image:UI_InfantSP_Dirty",
	"set:UIIcons image:UI_InfantSP_Hungry",
	"set:UIIcons image:UI_InfantSP_Thirsty",
}
local Infant_Skill_Icon = {};
local Infant_Skill_Name_Text = {};
local Infant_Skill_Value_Text = {};


-----------------------------
--卡牌装备按钮
local g_Card_ShenBing ;
local g_Card_JinZhuang;
local g_Card_LiangJu;
local g_Card_MingShi;
local g_Card_WuJue;
local g_Card_QingGong;
local g_Card_Dress;
-----------------------------

local g_Infant_HeroName =
{
	[1] = "乔峰",
	[2] = "段誉",
	[3] = "虚竹",
	[4] = "王语嫣",
}

local g_Infant_HeroImage = {}
local g_Infant_HeroFlash = {}

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_Infant_Page = {
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

local g_Infant_PageButton = {}
local g_Infant_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

function Infant_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("TOGGLE_OPENT_INFANT");
	this:RegisterEvent("TOGGLE_UPDATE_INFANT");
	this:RegisterEvent("INFANT_BANTERED");
	this:RegisterEvent("INFANT_CURE_BADSTATURS");
	this:RegisterEvent("UPDATE_INFANT_CARD")
	this:RegisterEvent("UPDATE_FAKE_OBJECT")
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK");		--升级
	this:RegisterEvent("FINISH_MISSION");
	this:RegisterEvent("SHOW_INFANTSKILL_INFO");	--打开子女装帧技能界面
	this:RegisterEvent("MARTIAL_UPDATE",false)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)
	-- 退出游戏
	this:RegisterEvent("QUEST_QUIT_GAME",true)
	-- 返回登陆界面
	this:RegisterEvent("QUEST_SERVER_LOGIN",true)
end

function Infant_OnLoad()
	g_MaxInfantCount = Infant:GetInfantMaxCount()
	Infant_Skill_Icon[1] = Infant_SkillImage1
	Infant_Skill_Icon[2] = Infant_SkillImage2
	Infant_Skill_Icon[3] = Infant_SkillImage3
	Infant_Skill_Icon[4] = Infant_SkillImage4

	g_default_bk_image = Infant_SkillImage1:GetProperty("Image")

	Infant_Skill_Name_Text[1] = Infant_SkillNum1_text1
	Infant_Skill_Name_Text[2] = Infant_SkillNum2_text1
	Infant_Skill_Name_Text[3] = Infant_SkillNum3_text1
	Infant_Skill_Name_Text[4] = Infant_SkillNum4_text1

	Infant_Skill_Value_Text[1] = Infant_SkillNum1_text2
	Infant_Skill_Value_Text[2] = Infant_SkillNum2_text2
	Infant_Skill_Value_Text[3] = Infant_SkillNum3_text2
	Infant_Skill_Value_Text[4] = Infant_SkillNum4_text2

	g_Infant_HeroImage[1] = Infant_Hero_QiaofengImage
	g_Infant_HeroImage[2] = Infant_Hero_DuanyuImage
	g_Infant_HeroImage[3] = Infant_Hero_XuzhuImage
	g_Infant_HeroImage[4] = Infant_Hero_WangyuyanImage

	g_Infant_HeroFlash[1] = Infant_Hero_QiaofengFlash
	g_Infant_HeroFlash[2] = Infant_Hero_DuanyuFlash
	g_Infant_HeroFlash[3] = Infant_Hero_XuzhuFlash
	g_Infant_HeroFlash[4] = Infant_Hero_WangyuyanFlash

	g_Card_ShenBing = Infant_HeroInfo_Equip1
	g_Card_JinZhuang = Infant_HeroInfo_Equip2
	g_Card_LiangJu = Infant_HeroInfo_Equip3
	g_Card_WuJue = Infant_HeroInfo_Equip4
	g_Card_QingGong = Infant_HeroInfo_Equip5
	g_Card_MingShi = Infant_HeroInfo_Equip6
	g_Card_Dress = Infant_DressItem
				
	g_Infant_PageButton[1] = Infant_SelfEquip
	g_Infant_PageButton[2] = Infant_SelfData
	g_Infant_PageButton[3] = Infant_Pet
	g_Infant_PageButton[4] = Infant_infant
	g_Infant_PageButton[5] = Infant_Wuhun
	g_Infant_PageButton[6] = Infant_Xiulian
	g_Infant_PageButton[7] = Infant_Miji
	g_Infant_PageButton[8] = Infant_ZhenYuan
	g_Infant_PageButton[9] = Infant_JingMai
	g_Infant_PageButton[10] = Infant_ShenDing
	g_Infant_PageButton[11] = Infant_JueWei
	g_Infant_PageButton[12] = Infant_BaoJian
	g_Infant_PageButton[13] = Infant_WuYi
	g_Infant_PageButton[14] = Infant_ShenQi
	g_Infant_PageButton[15] = Infant_Armor
	g_Infant_PageButton[16] = Infant_CangPin
	g_Infant_PageButton[17] = Infant_OtherInfo
	
	g_Infant_PageMask[1] = Infant_SelfEquip_tips
	g_Infant_PageMask[2] = Infant_SelfData_tips
	g_Infant_PageMask[3] = Infant_Pet_tips
	g_Infant_PageMask[4] = Infant_infant_tips
	g_Infant_PageMask[5] = Infant_Wuhun_tips
	g_Infant_PageMask[6] = Infant_Xiulian_tips
	g_Infant_PageMask[7] = Infant_Miji_tips
	g_Infant_PageMask[8] = Infant_ZhenYuan_tips
	g_Infant_PageMask[9] = Infant_JingMai_tips
	g_Infant_PageMask[10] = Infant_ShenDing_tips
	g_Infant_PageMask[11] = Infant_JueWei_tips
	g_Infant_PageMask[12] = Infant_BaoJian_tips
	g_Infant_PageMask[13] = Infant_WuYi_tips
	g_Infant_PageMask[14] = Infant_ShenQi_tips
	g_Infant_PageMask[15] = Infant_Armor_tips
	g_Infant_PageMask[16] = Infant_CangPin_tips
	g_Infant_PageMask[17] = Infant_OtherInfo_tips
	
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

function Infant_Close()
	this:Hide()
	KillFuncAllTimer("Infant_Mood_OnHiden()")
	KillFuncAllTimer("Infant_RelaxAction()")
end

function Infant_OnShow()
	local InfantCount = Infant:GetInfantCount();
	if InfantCount <= 0 then
		return 0
	end
	Infant_infant:SetCheck(1)
	g_CurCheckBox = 0;
	this:Show()
	SetTimer("Infant", "Infant_RelaxAction()", 10000)
end

function Infant_OnEvent( event )
	if ( event == "UPDATE_WILLGET_MISSION_TRACK" ) or (event == "FINISH_MISSION") then
		local nLevel =Player:GetLevel()
		Infant_Refresh_Page_Button(nLevel)
		Infant_ShowPage()
	end
	if (event=="TOGGLE_OPENT_INFANT") then
		local selfUnionPos = Variable:GetVariable("SelfUnionPos");
		g_ui_open_flag = 1
		if(selfUnionPos ~= nil) then
			Infant_Frame:SetProperty("UnifiedPosition", selfUnionPos);
			Infant_OnShow();
			Infant_OnUpdate(0);
		end
		--装备卡牌成功之后，显示英雄信息界面
		if arg0 == "1" then
			Infant_SetCheckBox(1)
		end
		g_ui_open_flag = 0
		local nLevel =Player:GetLevel()
		Infant_Refresh_Page_Button(nLevel)
		Infant_ShowPage()
	elseif event == "UPDATE_FAKE_OBJECT" and tostring(arg0) == "My_Infant" then
		if this:IsVisible() then
			Infant_OnUpdate(1)
		end
	elseif (event=="TOGGLE_UPDATE_INFANT") then
		Infant_OnUpdate(1);
		local nLevel =Player:GetLevel()
		Infant_Refresh_Page_Button(nLevel)
		Infant_ShowPage()
	elseif (event=="UPDATE_INFANT_CARD") then
		Infant_OnUpdate(0);
	elseif (event == "UI_COMMAND") and (tonumber(arg0) == 890196 or tonumber(arg0) == 890197) then
		Infant_OnShow()
	elseif (event=="INFANT_BANTERED") then
		Infant_Bantered(tonumber(arg0), tonumber(arg1))
	elseif (event=="INFANT_CURE_BADSTATURS") then
		Infant_HealthyButton_Clicked(tonumber(arg1))
--~ 		Infant_Cure_BadStatus(tonumber(arg0), tonumber(arg1))
	elseif( event == "HIDE_ON_SCENE_TRANSED") or ( event == "QUEST_QUIT_GAME") or ( event == "QUEST_SERVER_LOGIN") then
		Infant_Close()
	elseif (event == "UI_COMMAND") and (tonumber(arg0) == 890878) then --	武林风云录引导任务
		Infant_UpdateHeroInfo()
		Infant_OnShow()
		Infant_SetCheckBox(1)
	elseif (event == "SHOW_INFANTSKILL_INFO") then
		Infant_OnShow()
		Infant_SetCheckBox(2)
	elseif(event == "MARTIAL_UPDATE" or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		Infant_RefreshWuYiTip()
	end
	
	if event == "UPDATE_TOY_TIP" then
		Infant_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		Infant_RefreshCangPinTip()
	end
end
--index为0,代表左右两侧界面都进行刷新
--index为1,代表当右侧为英雄信息界面时，只有左侧界面都进行刷新
function Infant_OnUpdate(index)
	--二期开发中可以在这儿填充娃娃列表，然后默认选中一个
	Infant_UpdateCallUpButtion()
	Infant_UpdateModelInfo()
	Infant_UpdateDressInfo()
	--刷新选择那个的信息
	if g_CurCheckBox == 0 then
		Infant_DefaultWindow_FenYe1:SetCheck(1)
		Infant_DefaultWindow_FenYe2:SetCheck(0)
		Infant_UpdateSelInfantInfo()
	elseif g_CurCheckBox == 1 then
		Infant_DefaultWindow_FenYe1:SetCheck(0)
		Infant_DefaultWindow_FenYe2:SetCheck(1)
		if index ~= 1 then
			Infant_UpdateHeroInfo()
		end
	end

end
function Infant_UpdateCallUpButtion()
	local InfantCount = Infant:GetInfantCount();
	if InfantCount <= 0 or g_CurSelInfantIndex < 0 or g_CurSelInfantIndex >= g_MaxInfantCount then
		--招出孩子按钮
		Infant_MainAttributeButton:Disable()
		Infant_MainAttributeButton_Tips:Show();
	elseif g_CurSelInfantIndex >= 0 and g_CurSelInfantIndex < InfantCount then
		--阶段
		local nStage = Infant:GetStage(g_CurSelInfantIndex)
		if nStage >= 3 then
			Infant_MainAttributeButton:Enable()
			Infant_MainAttributeButton_Tips:Hide();
		else
			Infant_MainAttributeButton:Disable()
			Infant_MainAttributeButton_Tips:Show();
		end
		if Infant : GetIsFighting(g_CurSelInfantIndex) then
		--孩子处于招出状态
			Infant_MainAttributeButton:SetText("#{ETQWF_131106_33}");
			Infant_MainAttributeButton:SetToolTip("#{ZNJCS_130825_25}");
		else
		--孩子处于收回状态
			Infant_MainAttributeButton:SetText("#{ETQWF_131106_32}");
			Infant_MainAttributeButton:SetToolTip("#{ZNJCS_130825_24}");
		end
	end
end
--刷新基础信息页面
function Infant_UpdateSelInfantInfo()
	--隐藏英雄信息页面
	Infant_DefaultWindow1:Show()
	Infant_DefaultWindow2:Hide()

	local InfantCount = Infant:GetInfantCount();
	if InfantCount <= 0 or g_CurSelInfantIndex < 0 or g_CurSelInfantIndex >= g_MaxInfantCount then
		Infant_NameEditBox:SetText("")
		Infant_NameEditBox:Disable();
		Infant_ChangeNameButton:Disable();
		--性别
		Infant_SexLace_Text:SetText("");
		---他爹
		Infant_FatherLace_Text:SetText("");
		---他妈
		Infant_MotherLace_Text:SetText("");
		--等级
		Infant_LevelLace_Text:SetText("");
		--经验
		Infant_ExLace_Text:SetText("0/0");
		-- ---他爹 干的
		-- Infant_SecondFatherLace_Text:SetText("");
		-- ---他妈 干的
		-- Infant_SencondMotherLace_Text:SetText("");
		--诗
		Infant_SHILace_Text:SetText("");
		--书
		Infant_SHULace_Text:SetText("");
		--礼
		Infant_LILace_Text:SetText("");
		--乐
		Infant_YUELace_Text:SetText("");
		--射
		Infant_SHELace_Text:SetText("");

		-- Infant_HealthyType:SetProperty("Image"， "set:UIIcons image:PetFood_Type")

		--技能
		local nSkillCount = Infant:GetMaxSkillNum()
		for i = 1, nSkillCount do
			Infant_Skill_Icon[i]:SetToolTip("#{ZNJCS_130825_61}");
			Infant_Skill_Icon[i]:SetProperty("Image", g_default_bk_image)
			Infant_Skill_Name_Text[i]:SetText("")
			Infant_Skill_Value_Text[i]:SetText("")
		end
		--综合素养
		Infant_MainAttributetext1_Text2:SetText("")
		Infant_MainAttributeText2_Text2:SetText("")

	elseif g_CurSelInfantIndex >= 0 and g_CurSelInfantIndex < InfantCount then
		local szName = Infant:GetInfantName(g_CurSelInfantIndex);
		Infant_NameEditBox:SetText(szName)
		Infant_NameEditBox:Enable();
		Infant_ChangeNameButton:Enable();
		--性别
		local nSex = Infant:GetInfantSex(g_CurSelInfantIndex);
		if g_SexName[nSex + 1] ~= nil then
			Infant_SexLace_Text:SetText(g_SexName[nSex + 1]);
		end
		---他爹
		Infant_FatherLace_Text:SetText(Infant:GetInfantDadName(g_CurSelInfantIndex));
		---他妈
		Infant_MotherLace_Text:SetText(Infant:GetInfantMumName(g_CurSelInfantIndex));
		---等级
		Infant_LevelLace_Text:SetText(tostring( Infant:GetInfantLevel(g_CurSelInfantIndex) ));
		---经验
		---满级情况下显示"已满级"
		local defineInfantMaxLevel = Player:GetDefineInfantMaxLevel()
		if Infant:GetInfantLevel(g_CurSelInfantIndex) >=defineInfantMaxLevel then
			Infant_ExLace_Text:SetText("#{ZNJCS_130825_120}")
		else
			Infant_ExLace_Text:SetText(tostring( Infant:GetInfantExp(g_CurSelInfantIndex) ).."/"..tostring( Infant:GetInfantCurMaxExp(g_CurSelInfantIndex) ));
		end
		-- ---他爹 干的
		-- Infant_SecondFatherLace_Text:SetText(Infant:GetInfantFFatherName(g_CurSelInfantIndex));
		-- ---他妈 干的
		-- Infant_SencondMotherLace_Text:SetText(Infant:GetInfantFMotherName(g_CurSelInfantIndex));

		---诗
		Infant_SHILace_Text:SetText(tostring( Infant:GetInfantAttr(g_CurSelInfantIndex, 0) ).."/"..tostring( Infant:GetInfantMaxAttr(g_CurSelInfantIndex) ));
		---书
		Infant_SHULace_Text:SetText(tostring( Infant:GetInfantAttr(g_CurSelInfantIndex, 1) ).."/"..tostring( Infant:GetInfantMaxAttr(g_CurSelInfantIndex) ));
		---礼
		Infant_LILace_Text:SetText(tostring( Infant:GetInfantAttr(g_CurSelInfantIndex, 2) ).."/"..tostring( Infant:GetInfantMaxAttr(g_CurSelInfantIndex) ));
		---乐
		Infant_YUELace_Text:SetText(tostring( Infant:GetInfantAttr(g_CurSelInfantIndex, 3) ).."/"..tostring( Infant:GetInfantMaxAttr(g_CurSelInfantIndex) ));
		---射
		Infant_SHELace_Text:SetText(tostring( Infant:GetInfantAttr(g_CurSelInfantIndex, 4) ).."/"..tostring( Infant:GetInfantMaxAttr(g_CurSelInfantIndex) ));

		--阶段
		local nStage = Infant:GetStage(g_CurSelInfantIndex)

		if nStage >= 1 then
			Infant_SkillNum1_text:Hide();
			-- Infant_SkillNum2_text:Hide();
			-- Infant_SkillNum3_text:Hide();
			-- Infant_SkillNum4_text:Hide();
		end


		--等级tooltip
		Infant_LevelLace_Text:SetToolTip(g_LevelToolTip[nStage+1])
		Infant_LevelText:SetToolTip(g_LevelToolTip[nStage+1])
		--技能
		local nSkillCount = Infant:GetMaxSkillNum()
		for i = 1, nSkillCount do
			local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:GetInfantSkillInfo(g_CurSelInfantIndex, i - 1)
			if nSkillID == -1 then
				Infant_Skill_Icon[i]:SetToolTip("#{ZNJCS_130825_61}");
				Infant_Skill_Icon[i]:SetProperty("Image", g_default_bk_image)
				Infant_Skill_Name_Text[i]:SetText("")
				Infant_Skill_Value_Text[i]:SetText("")
				Infant_Skill_Name_Text[i]:SetToolTip("")
				Infant_Skill_Value_Text[i]:SetToolTip("")
			else
				if szIcon ~= nil then
					Infant_Skill_Icon[i]:SetToolTip("");
					Infant_Skill_Icon[i]:SetProperty("Image", szIcon)
					Infant_Skill_Name_Text[i]:SetText(szSkillName.."("..nSkillLevel.."#{WH_090729_12}"..")")
					Infant_Skill_Value_Text[i]:SetText("+"..nSkillEffect)
					Infant_Skill_Name_Text[i]:SetToolTip("#{ZNJCS_130825_127}")
					Infant_Skill_Value_Text[i]:SetToolTip("#{ZNJCS_130825_128}")
				end
			end
		end
		--综合素养
		local mainAttribute = Infant:GetMainAttribute(g_CurSelInfantIndex)
		Infant_MainAttributetext1_Text2:SetText(""..mainAttribute)
		--技能加成
		local maxMainAttribute = Infant:GetInfantMaxAttr_MaxLevel(g_CurSelInfantIndex)*5;
		local skillValue;
		if maxMainAttribute == 0 then
			skillValue = 0
		else
			skillValue = 100 + math.floor(mainAttribute/maxMainAttribute*100)
		end
		if skillValue > 200 then
			skillValue = 200
		end
		Infant_MainAttributeText2_Text2:SetText(""..skillValue.."%")


	end
end
function Infant_UpdateModelInfo()
	local InfantCount = Infant:GetInfantCount();
	if InfantCount <= 0 or g_CurSelInfantIndex < 0 or g_CurSelInfantIndex >= g_MaxInfantCount then
		--阶段
		Infant_Proficient_Text:SetText("");

		--健康值
--~ 		Infant_HealthyNum:SetText("");

		--特殊状态
--~ 		Infant_HealthyType:SetToolTip("")
		--模型
		Infant_FakeObject:RotateEnd();
		Infant_FakeObject : SetFakeObject( "" );
--~ 		Infant_HealthyButton:Hide();
	elseif g_CurSelInfantIndex >= 0 and g_CurSelInfantIndex < InfantCount then
		--阶段
		local nStage = Infant:GetStage(g_CurSelInfantIndex)
		if g_StageName[nStage + 1] ~= nil then
			Infant_Proficient_Text:SetText(g_StageName[nStage + 1]);
		end
		--健康值
--~ 		local health = Infant:GetHealthValue(g_CurSelInfantIndex)
--~ 		Infant_HealthyNum:SetText(Infant:GetHealthValue(g_CurSelInfantIndex));
		--特殊交互
		local badStatus = 0--Infant:GetStatus(g_CurSelInfantIndex)
		if badStatus == 0 then
--~ 			Infant_HealthyButton:Hide();
--~ 			Infant_HealthyType:Hide();
		else
			Infant_HealthyButton:Show();
			if g_TreatBadStatusAction_btn[badStatus] ~= nil then
--~ 				Infant_HealthyButton:SetText(g_TreatBadStatusAction_btn[badStatus]);
			end
			if g_TreatBadStatusAction_tips[badStatus] ~= nil then
--~ 				Infant_HealthyButton:SetToolTip(g_TreatBadStatusAction_tips[badStatus]);
			end
--~ 			Infant_HealthyType:Show();
			if g_HealthTypeToolTip[badStatus] ~= nil then
--~ 				Infant_HealthyType:SetToolTip(g_HealthTypeToolTip[badStatus]);
			end
			if g_HealthTypeImage[badStatus] ~= nil then
--~ 				Infant_HealthyType:SetProperty("Image", g_HealthTypeImage[badStatus]);
			end
		end

		--模型
		Infant_FakeObject : SetFakeObject( "" );
		Infant:SetInfantModel(g_CurSelInfantIndex)
		Infant_FakeObject : SetFakeObject( "My_Infant" )


		FakeObj_SetCamera( "My_Infant", g_CameraHeight,0.5);
		FakeObj_SetCamera( "My_Infant", g_CameraDistance,3);
		if nStage == 3 then
			FakeObj_SetCamera( "My_Infant", g_CameraHeight,0.7);
			FakeObj_SetCamera( "My_Infant", g_CameraDistance,4);
		end
		FakeObj_RestoreCamera( "My_Infant" )

		if nStage == 3 and g_ui_open_flag == 1 then
			Infant_RelaxAction()
		end
	end

end

function Infant_UpdateDressInfo()

	local IsDisplay = Infant:GetShowHeroCheck()
	Infant_Hero_Facade_Clicked(IsDisplay)

	local InfantCount = Infant:GetInfantCount();
	local heroType = Infant:GetHeroType(g_CurSelInfantIndex)
	if InfantCount <= 0 or g_CurSelInfantIndex < 0 or g_CurSelInfantIndex >= g_MaxInfantCount then
		return
	else
		g_Card_Dress:SetActionItem(-1)
		local ActionDress = EnumAction(6, "infantcard" )
		g_Card_Dress:SetActionItem(ActionDress:GetID())
		--Infant:SetInfantNewModel(0)
		PushEvent("UI_COMMAND", 201411211)
	end
end

--刷新英雄信息页面
function Infant_UpdateHeroInfo()
	--隐藏基础信息页面
	Infant_DefaultWindow1:Hide()
	Infant_DefaultWindow2:Show()

	local InfantCount = Infant:GetInfantCount();
	local heroType = Infant:GetHeroType(g_CurSelInfantIndex)
	if InfantCount <= 0 or g_CurSelInfantIndex < 0 or g_CurSelInfantIndex >= g_MaxInfantCount or heroType <= 0 or heroType >4 then
		Infant_Hero_Name_Text:SetText("")
		-- Infant_Hero_Level_Text:SetText("")
		-- Infant_Hero_Score_Text:SetText("")
		--卡牌装备位
		g_Card_ShenBing:SetActionItem(-1)
		g_Card_JinZhuang:SetActionItem(-1)
		g_Card_LiangJu:SetActionItem(-1)
		g_Card_MingShi:SetActionItem(-1)
		g_Card_WuJue:SetActionItem(-1)
		g_Card_QingGong:SetActionItem(-1)
		g_Card_Dress:SetActionItem(-1)
		--基础属性加成
		Infant_HeroInfo_Tili_Vigor1:SetText("+0")
		Infant_HeroInfo_Tili_Vigor2:SetText("+0")

		Infant_HeroInfo_Mingzhong_Vigor1:SetText("+0")
		Infant_HeroInfo_Mingzhong_Vigor2:SetText("+0")

		Infant_HeroInfo_Shenfa_Vigor1:SetText("+0")
		Infant_HeroInfo_Shenfa_Vigor2:SetText("+0")

		Infant_HeroInfo_Shanbi_Vigor1:SetText("+0")
		Infant_HeroInfo_Shanbi_Vigor2:SetText("+0")

		Infant_HeroInfo_Huixin_Vigor1:SetText("+0")
		Infant_HeroInfo_Huixin_Vigor2:SetText("+0")

		--属性攻击加成
		Infant_HeroInfo_Bing_Vigor1:SetText("+0")
		Infant_HeroInfo_Bing_Vigor2:SetText("+0")

		Infant_HeroInfo_Huo_Vigor1:SetText("+0")
		Infant_HeroInfo_Huo_Vigor2:SetText("+0")

		Infant_HeroInfo_Xuan_Vigor1:SetText("+0")
		Infant_HeroInfo_Xuan_Vigor2:SetText("+0")

		Infant_HeroInfo_Du_Vigor1:SetText("+0")
		Infant_HeroInfo_Du_Vigor2:SetText("+0")
	else
		if heroType	> 0 and heroType < 5 then
			Infant_Hero_Name_Text:SetText(g_Infant_HeroName[heroType])
		end
		-- local heroLevel = Infant:GetHeroLevel(g_CurSelInfantIndex)
		-- Infant_Hero_Level_Text:SetText(tostring(heroLevel))

		-- local heroExp = Infant:GetHeroExp(g_CurSelInfantIndex)
		-- local maxExp = Infant:GetCurMaxHeroExp(g_CurSelInfantIndex)

		-- if heroLevel >= 29 then
		-- 	Infant_Hero_Score_Text:SetText("侠情等级已达最高级")
		-- else
		-- 	Infant_Hero_Score_Text:SetText(heroExp.."/"..maxExp)
		-- end
		--卡牌装备位
		g_Card_ShenBing:SetActionItem(-1)
		g_Card_JinZhuang:SetActionItem(-1)
		g_Card_LiangJu:SetActionItem(-1)
		g_Card_MingShi:SetActionItem(-1)
		g_Card_WuJue:SetActionItem(-1)
		g_Card_QingGong:SetActionItem(-1)
		g_Card_Dress:SetActionItem(-1)

		local ActionShenBing = EnumAction(0, "infantcard")
		local ActionJinZhuang = EnumAction(1, "infantcard")
		local ActionQingGong = EnumAction(2, "infantcard")
		local ActionMingShi= EnumAction(3, "infantcard")
		local ActionWuJue = EnumAction(4, "infantcard")
		local ActionLiangJu= EnumAction(5, "infantcard")
		local ActionDress = EnumAction(6, "infantcard" )

		g_Card_ShenBing:SetActionItem(ActionShenBing:GetID())
		g_Card_JinZhuang:SetActionItem(ActionJinZhuang:GetID())
		g_Card_LiangJu:SetActionItem(ActionLiangJu:GetID())
		g_Card_MingShi:SetActionItem(ActionMingShi:GetID())
		g_Card_WuJue:SetActionItem(ActionWuJue:GetID())
		g_Card_QingGong:SetActionItem(ActionQingGong:GetID())
		g_Card_Dress:SetActionItem(ActionDress:GetID())
		--体力
		local nCon_1 = Infant:GetHeroValueFix(g_CurSelInfantIndex, HeroCon)
		local nCon_2 = Infant:GetInfantCardValueFix(g_CurSelInfantIndex, HeroCon)

		if nCon_1 ~= nil and nCon_2 ~= nil then
			Infant_HeroInfo_Tili_Vigor1:SetText("体力：+"..(nCon_1+nCon_2))
			Infant_HeroInfo_Tili_Vigor2:SetText("#H(+"..nCon_2..")")
		end
		--命中
		local nHit_1 = Infant:GetHeroValueFix(g_CurSelInfantIndex, HeroHit)
		local nHit_2 = Infant:GetInfantCardValueFix(g_CurSelInfantIndex, HeroHit)
		if nHit_1 ~= nil and nHit_2 ~= nil then
			Infant_HeroInfo_Mingzhong_Vigor1:SetText("命中：+"..(nHit_1+nHit_2))
			Infant_HeroInfo_Mingzhong_Vigor2:SetText("#H(+".. nHit_2 ..")")
		end
		--身法
		local nDex_1 = Infant:GetHeroValueFix(g_CurSelInfantIndex, HeroDex)
		local nDex_2 = Infant:GetInfantCardValueFix(g_CurSelInfantIndex, HeroDex)
		if nHit_1 ~= nil and nHit_2 ~= nil then
			Infant_HeroInfo_Shenfa_Vigor1:SetText("身法：+"..(nDex_1+nDex_2))
			Infant_HeroInfo_Shenfa_Vigor2:SetText("#H(+"..nDex_2..")")
		end
		--闪避
		local nMiss_1 = Infant:GetHeroValueFix(g_CurSelInfantIndex, HeroMiss)
		local nMiss_2 = Infant:GetInfantCardValueFix(g_CurSelInfantIndex, HeroMiss)
		if nMiss_1 ~= nil and nMiss_2 ~= nil then
			Infant_HeroInfo_Shanbi_Vigor1:SetText("闪避：+"..(nMiss_1+nMiss_2))
			Infant_HeroInfo_Shanbi_Vigor2:SetText("#H(+"..nMiss_2..")")
		end
		--会心
		local nCritical_1 = Infant:GetHeroValueFix(g_CurSelInfantIndex, HeroCritical)
		local nCritical_2 = Infant:GetInfantCardValueFix(g_CurSelInfantIndex, HeroCritical)
		if nCritical_1 ~= nil and nCritical_2 ~= nil then
			Infant_HeroInfo_Huixin_Vigor1:SetText("会心攻击：+"..(nCritical_1+nCritical_2))
			Infant_HeroInfo_Huixin_Vigor2:SetText("#H(+"..nCritical_2..")")
		end
		--冰攻
		local nIceAttack_1 = Infant:GetHeroValueFix(g_CurSelInfantIndex, HeroIceAttack)
		local nIceAttack_2 = Infant:GetInfantCardValueFix(g_CurSelInfantIndex, HeroIceAttack)
		if nIceAttack_1 ~= nil and nIceAttack_2 ~= nil then
			Infant_HeroInfo_Bing_Vigor1:SetText("冰攻击：+"..(nIceAttack_1+nIceAttack_2))
			Infant_HeroInfo_Bing_Vigor2:SetText("#H(+"..nIceAttack_2..")")
		end
		--火攻
		local nFireAttack_1 = Infant:GetHeroValueFix(g_CurSelInfantIndex, HeroFireAttack)
		local nFireAttack_2 = Infant:GetInfantCardValueFix(g_CurSelInfantIndex, HeroFireAttack)
		if nFireAttack_1 ~= nil and nFireAttack_2 ~= nil then
			Infant_HeroInfo_Huo_Vigor1:SetText("火攻击：+"..(nFireAttack_1+nFireAttack_2))
			Infant_HeroInfo_Huo_Vigor2:SetText("#H(+"..nFireAttack_2..")")
		end
		--玄攻
		local nXuanAttack_1 = Infant:GetHeroValueFix(g_CurSelInfantIndex, HeroXuanAttack)
		local nXuanAttack_2 = Infant:GetInfantCardValueFix(g_CurSelInfantIndex, HeroXuanAttack)
		if nXuanAttack_1 ~= nil and nXuanAttack_2 ~= nil then
			Infant_HeroInfo_Xuan_Vigor1:SetText("玄攻击：+"..(nXuanAttack_1+nXuanAttack_2))
			Infant_HeroInfo_Xuan_Vigor2:SetText("#H(+"..nXuanAttack_2..")")
		end
		--毒攻
		local nPoisonAttack_1 = Infant:GetHeroValueFix(g_CurSelInfantIndex, HeroPoisonAttack)
		local nPoisonAttack_2 = Infant:GetInfantCardValueFix(g_CurSelInfantIndex, HeroPoisonAttack)
		if nPoisonAttack_1 ~= nil and nPoisonAttack_2 ~= nil then
			Infant_HeroInfo_Du_Vigor1:SetText("毒攻击：+"..(nPoisonAttack_1+nPoisonAttack_2))
			Infant_HeroInfo_Du_Vigor2:SetText("#H(+"..nPoisonAttack_2..")")
		end

		--英雄剪影
		for i=1,4 do
			g_Infant_HeroImage[i]:Hide()
			g_Infant_HeroFlash[i]:Hide()
		end

		if heroType	> 0 and heroType < 5 then
			if Infant:GetIsPerfectHero(g_CurSelInfantIndex) == true then
				g_Infant_HeroFlash[heroType]:Show()
			else
				g_Infant_HeroImage[heroType]:Show()
			end
		end

	end
end

function Infant_SetCheckBox( index )
	if index == 1 then
		local heroType = Infant:GetHeroType(g_CurSelInfantIndex)
		local level = Infant:GetInfantLevel(g_CurSelInfantIndex)
		--未选择英雄类型或未到91级无法打开英雄信息页面
		if heroType <= 0 or level < 91 then
			PushDebugMessage("#{YXPY_20131118_48}")
			PushDebugMessage("#{YXPY_20131118_49}")
			return
		end
	end

	g_CurCheckBox = index
	Infant_OnUpdate(0)
end
--点击卡牌事件
--index为装备位置0-5
--clicktype为点击类型0为右键，1为左键
function Infant_Card_Clicked( index, clicktype )

	local nIndex = tonumber(index)
	local button = tonumber(clicktype)

	if nIndex == 0 then
		if button == 0 then
			g_Card_ShenBing:DoSubAction()
		elseif button == 1 then
			g_Card_ShenBing:DoAction()
		end
	elseif nIndex == 1 then
		if button == 0 then
			g_Card_JinZhuang:DoSubAction()
		elseif button == 1 then
			g_Card_JinZhuang:DoAction()
		end
	elseif nIndex == 2 then
		if button == 0 then
			g_Card_LiangJu:DoSubAction()
		elseif button == 1 then
			g_Card_LiangJu:DoAction()
		end
	elseif nIndex == 3 then
		if button == 0 then
			g_Card_WuJue:DoSubAction()
		elseif button == 1 then
			g_Card_WuJue:DoAction()
		end
	elseif nIndex == 4 then
		if button == 0 then
			g_Card_QingGong:DoSubAction()
		elseif button == 1 then
			g_Card_QingGong:DoAction()
		end
	elseif nIndex == 5 then
		if button == 0 then
			g_Card_MingShi:DoSubAction()
		elseif button == 1 then
			g_Card_MingShi:DoAction()
		end
	elseif nIndex == 6 then
		if button == 0 then
			g_Card_Dress:DoSubAction()
		elseif button == 1 then
			g_Card_Dress:DoAction()
		end
	end
end
----------------------------------------------------------------------------------
--
-- 旋转珍兽模型（向左)
--
function Infant_Modle_TurnLeft(start)
	--向左旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Infant_FakeObject:RotateBegin(-0.3);
	--向左旋转结束
	else
		Infant_FakeObject:RotateEnd();
	end
end

----------------------------------------------------------------------------------
--
--旋转珍兽模型（向右)
--
function Infant_Modle_TurnRight(start)
	--向右旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Infant_FakeObject:RotateBegin(0.3);
	--向右旋转结束
	else
		Infant_FakeObject:RotateEnd();
	end
end

function Infant_Change_Name_Clicked()
	local guid_H = -1;
	local guid_L = -1;
	guid_H, guid_L = Infant:GetInfantGUID(g_CurSelInfantIndex);
	if guid_H == -1 and guid_L == -1 then
		return
	end
	local newName = Infant_NameEditBox:GetText();
	if newName == "" then
		PushDebugMessage("#{GMT_20100811_5}")
		return;
	end
	if newName == Infant:GetInfantName(g_CurSelInfantIndex) then
		return;
	end
	if Infant:CheckNameString(newName) ~= 1 then
		return;
	end
	Infant:ChangeInfantName(g_CurSelInfantIndex, newName);
end

function Infant_Action_Bantered_Clicked(index)
	Infant_Bantered(g_CurSelInfantIndex, index)
end

function Infant_Bantered(infantIdx, actIndex)
	--5s冷却时间
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then
 	 	PushDebugMessage("#{ZNJCS_130825_126}"); --不可连续点击，请稍等片刻后再点击
   		return;
   	end
   	g_ButtonLastTime = curTime;
	Infant:ChangeAction_Bantered(infantIdx, actIndex)
	--文字反馈区显示及音效
	local rand = math.random(1,3)
	local nSex = Infant:GetInfantSex(infantIdx)
	local nStage = Infant:GetStage(infantIdx)
	Infant_Mood:SetText(g_BanterInfant_playtext[actIndex+1][rand]);
	-- Sound:PlaySound(tonumber(g_BanterInfant_playsound[actIndex+1][nStage][nSex]),false)
	Infant_Mood:Show();
	KillTimer("Infant_Mood_OnHiden()")
	SetTimer("Infant", "Infant_Mood_OnHiden()", 10000)
	KillTimer("Infant_RelaxAction()")
	SetTimer("Infant", "Infant_RelaxAction()", 10000)
end

function Infant_HealthyButton_Clicked(index)
	--5s冷却时间
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then
 	 	PushDebugMessage("#{ZNJCS_130825_126}"); --不可连续点击，请稍等片刻后再点击
   		return;
   	end
   	g_ButtonLastTime = curTime;
	Infant_Cure_BadStatus(g_CurSelInfantIndex,index)
end

function Infant_Cure_BadStatus(infantIdx,index)
	local InfantCount = Infant:GetInfantCount();
	if InfantCount <= 0 or infantIdx < 0 or infantIdx >= g_MaxInfantCount then
		return
	end
	local guid_H = -1;
	local guid_L = -1;
	guid_H, guid_L = Infant:GetInfantGUID(infantIdx);
	if guid_H == -1 and guid_L == -1 then
		return
	end
	local infantStatus = 0--Infant:GetStatus(infantIdx)
	local nSex = Infant:GetInfantSex(infantIdx)
	local nStage = Infant:GetStage(infantIdx)
	Infant:ChangeAction_OutBadStatus(infantIdx, index) --播放动作
	Infant_Mood:SetText(g_TreatBadStatusAction_playtext[index]) --文字反馈
	Infant_Mood:Show()
	-- Sound:PlaySound(tonumber(g_TreatBadStatusAction_playsound[infantStatus][nStage][nSex]),false)
	KillTimer("Infant_Mood_OnHiden()")
	SetTimer("Infant", "Infant_Mood_OnHiden()", 10000) --定时10s关闭
--~ 	Clear_XSCRIPT();
--~ 		Set_XSCRIPT_Function_Name("InfantTreatBadStatus");
--~ 		Set_XSCRIPT_ScriptID(890600);
--~ 		Set_XSCRIPT_Parameter(0,guid_H);
--~ 		Set_XSCRIPT_Parameter(1,guid_L);
--~ 		Set_XSCRIPT_ParamCount(2);
--~ 	Send_XSCRIPT();
	KillTimer("Infant_RelaxAction()")
	SetTimer("Infant", "Infant_RelaxAction()", 10000)
end

function Infant_Set_MouseLeave()
	PushEvent("INFANT_SKILL_MOUSE_LEAVE")
end

function Infant_Set_MouseEnter( index )
	local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:GetInfantSkillInfo(g_CurSelInfantIndex, index)
	if nSkillID == -1 then
		return;
	end
	local SetX = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteXPosition") + Infant_Skill_Window:GetProperty("AbsoluteXPosition") + Infant_DefaultWindow1:GetProperty("AbsoluteXPosition") + Infant_Frame_Client:GetProperty("AbsoluteXPosition") + Infant_Client:GetProperty("AbsoluteXPosition") + Infant_Frame:GetProperty("AbsoluteXPosition");
	local SetY = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteYPosition") + Infant_Skill_Window:GetProperty("AbsoluteYPosition") + Infant_DefaultWindow1:GetProperty("AbsoluteYPosition") + Infant_Frame_Client:GetProperty("AbsoluteYPosition") + Infant_Client:GetProperty("AbsoluteYPosition") + Infant_Frame:GetProperty("AbsoluteYPosition");
	local SetWidth = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteWidth")
	local SetHeight = Infant_Skill_Icon[index+1]:GetProperty("AbsoluteHeight")
	PushEvent("INFANT_SKILL_MOUSE_ENTER",SetX,SetY,SetWidth,SetHeight,g_CurSelInfantIndex,index)
end

function Infant_SelfEquip_Switch()
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenEquip(1);
	if bRet == 1 then
		this:Hide()
	end
end

function Infant_SelfData_Switch()
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = SystemSetup:OpenPrivatePage("self");
	if bRet == 1 then
		this:Hide()
	end
end

function Infant_SelfData_Switch()
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = SystemSetup:OpenPrivatePage("self");
	if bRet == 1 then
		this:Hide()
	end
end

function Infant_Pet_Switch()
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = TogglePetPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Infant_Wuhun_Switch()
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = ToggleWuhunPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Infant_Xiulian_Switch()
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = XiuLianPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Infant_Miji_Switch()
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenMijiPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Infant_ZhenYuan_Switch()
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Infant_JingMai_Switch()
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJingMaiPage();
	if bRet == 1 then
		this:Hide()
	end
end

--神木王鼎
function Infant_ShenDing_Switch()
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenShenDingPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Infant_Ride_Switch()
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenRidePage();
	if bRet == 1 then
		this:Hide()
	end
end

function Infant_OtherInfo_Switch()
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OtherInfoPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Infant_Mood_OnHiden( )
	KillTimer("Infant_Mood_OnHiden()")
	Infant_Mood:Hide()
end

function Infant_RelaxAction()
	KillTimer("Infant_RelaxAction()")

	local badStatus = 0--Infant:GetStatus(g_CurSelInfantIndex)
	if badStatus == 0 then
		local rand = math.mod(math.random(1,100), 2)
		Infant:ChangeAction_Relax(g_CurSelInfantIndex, rand)

	end
	SetTimer("Infant", "Infant_RelaxAction()", 10000)
end
--招出孩子
function Infant_CallUp_Clicked()
	if Infant : GetIsFighting(g_CurSelInfantIndex) then
		Infant:ReCall_Up(g_CurSelInfantIndex);
	else
		Infant:Call_Up(g_CurSelInfantIndex);
	end
	--Infant_MainAttributeButton:Disable()
end

function Infant_Hero_Facade_Clicked(mode)
	if mode == 1 then
		Infant_ChoiseHero_Button:SetCheck(1)
		Infant_ChoiseDress_Button:SetCheck(0)
	elseif mode == 0 then
		Infant_ChoiseHero_Button:SetCheck(0)
		Infant_ChoiseDress_Button:SetCheck(1)
	end
	if mode ~= Infant:GetShowHeroCheck() then
		Infant:SetShowHeroCheck(mode)
	end
end

function Infant_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if ( bRet == 1 ) then
		this:Hide();
	end
end

function Infant_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()
	this:Hide()

end

function Infant_Refresh_Page_Button( nLevel)

	if 1 == 1 then
		return
	end
	
	--神鼎
	if ( nLevel < 15 ) then
		Infant_ShenDing:Disable()
		Infant_ShenDing_tips:Show()
	--	Infant_ShenDing:SetToolTip("#{RWYQ_150707_07}")
	else
		Infant_ShenDing:Enable()
		Infant_ShenDing_tips:Hide()
	end
	--子女2
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 ) then--or InfantCount <= 0 then
		Infant_infant:Disable()
		Infant_infant_tips:Show()
--		Infant_infant:SetToolTip("#{RWYQ_150707_01}")
	else
		Infant_infant:Enable()
		Infant_infant_tips:Hide()
	end
	--武魂
--	if ( nLevel < 65 ) then
--		Infant_Wuhun:Disable()
--		Infant_Wuhun_tips:Show()
	--	Infant_Wuhun:SetToolTip("#{RWYQ_150707_02}")
--	else
		Infant_Wuhun:Enable()
		Infant_Wuhun_tips:Hide()
--	end
	--修炼
	if ( nLevel < 70 ) then
		Infant_Xiulian:Disable()
		Infant_Xiulian_tips:Show()
	--	Infant_Xiulian:SetToolTip("#{RWYQ_150707_03}")
	else
		Infant_Xiulian:Enable()
		Infant_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		Infant_Miji:Disable()
		Infant_Miji_tips:Show()
	--	Infant_Miji:SetToolTip("#{RWYQ_150707_04}")
	else
		Infant_Miji:Enable()
		Infant_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		Infant_ZhenYuan:Disable()
		Infant_ZhenYuan_tips:Show()
	--	Infant_ZhenYuan:SetToolTip("#{RWYQ_150707_05}")
	else
		Infant_ZhenYuan:Enable()
		Infant_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		Infant_JueWei:Disable()
		Infant_JueWei_tips:Show()
	--	Infant_JueWei:SetToolTip("#{RWYQ_150707_08}")
	else
		Infant_JueWei:Enable()
		Infant_JueWei_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		Infant_JingMai:Disable()
		Infant_JingMai_tips:Show()
	--	Infant_JingMai:SetToolTip("#{RWYQ_150707_06}")
	else
		Infant_JingMai:Enable()
		Infant_JingMai_tips:Hide()
	end

	if ( nLevel < 85 ) then
		Infant_BaoJian:Disable()
		Infant_BaoJian_tips:Show()
	else
		Infant_BaoJian:Enable()
		Infant_BaoJian_tips:Hide()
	end
	--武意
	Infant_RefreshWuYiTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		Infant_WuYi:Enable()
		Infant_WuYi_tips:Hide()
	else
		Infant_WuYi:Disable()
		Infant_WuYi_tips:Show()
	end
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		Infant_ShenQi:Enable()
		Infant_ShenQi_tips:Hide()
	else
		Infant_ShenQi:Disable()
		Infant_ShenQi_tips:Show()
	end
	Infant_RefreshOtherInfoTip()
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		Infant_Armor:Enable()
		Infant_Armor_tips:Hide()
	else
		Infant_Armor:Disable()
		Infant_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		Infant_CangPin:Enable()
		Infant_CangPin_tips:Hide()
	else
		Infant_CangPin:Disable()
		Infant_CangPin_tips:Show()
	end
	
	Infant_RefreshCangPinTip()
end

function Infant_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

-- 九星神器DIY技能
function Infant_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Infant_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_Infant_PageButton[idx]:GetProperty("UnifiedXPosition");
			Infant_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		Infant_WuYi_Buttontips:Show()
	else
		Infant_WuYi_Buttontips:Hide()
	end
end

function Infant_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_Infant_PageButton[idx]:GetProperty("UnifiedXPosition");
			Infant_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then
		Infant_OtherInfo_ButtonTips:Show()
	else
		Infant_OtherInfo_ButtonTips:Hide()
	end
end

--内甲
function Infant_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function Infant_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", Infant_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function Infant_RefreshCangPinTip()
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
			local newpos = g_PageButtonTipsPos[idx] --28 + g_Infant_PageButton[idx]:GetProperty("UnifiedXPosition");
			Infant_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		Infant_CangPin_Buttontips:Show()
	else
		Infant_CangPin_Buttontips:Hide()
	end
end


function Infant_ShowPage()

	for i = 1, table.getn(g_Infant_Page) do
		g_Infant_PageButton[i]:Hide()
		g_Infant_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	Infant_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_Infant_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_Infant_Page) do
			if i ~= nPageNumber then
				g_Infant_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_Infant_Page) do
		if Infant_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_Infant_PageButton[g_PageCount]:Show()
			g_Infant_PageButton[g_PageCount]:SetText(g_Infant_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if Infant_IsPageEnable(i) == 1 then
				g_Infant_PageButton[g_PageCount]:Enable()
				g_Infant_PageMask[g_PageCount]:Hide()
			else
				g_Infant_PageButton[g_PageCount]:Disable()
				g_Infant_PageMask[g_PageCount]:Show()
				if g_Infant_Page[i].Tip ~= "" then
					g_Infant_PageMask[g_PageCount]:SetToolTip(g_Infant_Page[i].Tip)
				end
			end
		end
	end
	
	Infant_RefreshWuYiTip()
	Infant_RefreshOtherInfoTip()
	Infant_RefreshCangPinTip()
	
end

function Infant_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		Infant_SelfEquip_Switch();
	elseif idx == 2 then--资料
		Infant_SelfData_Switch()
	elseif idx == 3 then--珍兽
		Infant_Pet_Switch()
	elseif idx == 4 then--子女
		--SelfData_Infant_Switch()
	elseif idx == 5 then--武魂
		Infant_Wuhun_Switch()
	elseif idx == 6 then--修炼
		Infant_Xiulian_Switch()
	elseif idx == 7 then--秘籍
		Infant_Miji_Switch()
	elseif idx == 8 then--真元
		Infant_ZhenYuan_Switch()
	elseif idx == 9 then--经脉
		Infant_JingMai_Switch()
	elseif idx == 10 then--神鼎
		Infant_ShenDing_Switch()
	elseif idx == 11 then--侠印
		Infant_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		Infant_OpenBaoJian()
	elseif idx == 13 then--武意
		Infant_OpenWuYi()
	elseif idx == 14 then--神器
		Infant_OpenShenQi()
	elseif idx == 15 then--星盘
		Infant_Armor_Page_Switch()
	elseif idx == 16 then--名物
		Infant_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		Infant_OtherInfo_Switch()
	end
end

function Infant_CheckPage(idx)
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

function Infant_IsPageEnable(idx)
	
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

function Infant_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end



