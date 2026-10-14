--TargetInfant.lua
--*********************
--娃娃主界面
--*********************
local g_CameraHeight = 1;     --摄影机高度
local g_CameraDistance = 2;   --摄影机距离
local g_CameraPitch = 3;      --摄影机角度

local g_CurSelInfantIndex = 0;
local g_MaxInfantCount = 0;

local g_default_bk_image = ""
local g_objCared = -1

local g_CurCheckBox = 0; --0为基本信息，1为英雄信息

local g_SexName = {"#{XY_0110_63}", "#{XY_0110_62}"}; --女 男
local g_StageName = {
	"#{ZNJCS_130825_112}",
	"#{ZNJCS_130825_113}",
	"#{ZNJCS_130825_114}",
	"#{ZNJCS_130825_115}"
};
local TargetInfant_Skill_Icon = {};
local TargetInfant_Skill_Name_Text = {};
local TargetInfant_Skill_Value_Text = {};

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
local g_TargetInfant_Page = {
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

function TargetInfant_PreLoad()
	this:RegisterEvent("TOGGLE_OPENT_INFANT_OTHER");
	this:RegisterEvent("TOGGLE_UPDATE_INFANT_OTHER");

	this:RegisterEvent("OBJECT_CARED_EVENT",false);
end

function TargetInfant_OnLoad()
	g_MaxInfantCount = Infant:GetInfantMaxCount()
	TargetInfant_Skill_Icon[1] = TargetInfant_SkillImage1
	TargetInfant_Skill_Icon[2] = TargetInfant_SkillImage2
	TargetInfant_Skill_Icon[3] = TargetInfant_SkillImage3
	TargetInfant_Skill_Icon[4] = TargetInfant_SkillImage4

	g_default_bk_image = TargetInfant_SkillImage1:GetProperty("Image")

	TargetInfant_Skill_Name_Text[1] = TargetInfant_SkillNum1_text1
	TargetInfant_Skill_Name_Text[2] = TargetInfant_SkillNum2_text1
	TargetInfant_Skill_Name_Text[3] = TargetInfant_SkillNum3_text1
	TargetInfant_Skill_Name_Text[4] = TargetInfant_SkillNum4_text1

	TargetInfant_Skill_Value_Text[1] = TargetInfant_SkillNum1_text2
	TargetInfant_Skill_Value_Text[2] = TargetInfant_SkillNum2_text2
	TargetInfant_Skill_Value_Text[3] = TargetInfant_SkillNum3_text2
	TargetInfant_Skill_Value_Text[4] = TargetInfant_SkillNum4_text2

	g_Infant_HeroImage[1] = TargetInfant_Hero_QiaofengImage
	g_Infant_HeroImage[2] = TargetInfant_Hero_DuanyuImage
	g_Infant_HeroImage[3] = TargetInfant_Hero_XuzhuImage
	g_Infant_HeroImage[4] = TargetInfant_Hero_WangyuyanImage

	g_Infant_HeroFlash[1] = TargetInfant_Hero_QiaofengFlash
	g_Infant_HeroFlash[2] = TargetInfant_Hero_DuanyuFlash
	g_Infant_HeroFlash[3] = TargetInfant_Hero_XuzhuFlash
	g_Infant_HeroFlash[4] = TargetInfant_Hero_WangyuyanFlash

	g_Card_ShenBing = TargetInfant_HeroInfo_Equip1
	g_Card_JinZhuang = TargetInfant_HeroInfo_Equip2
	g_Card_LiangJu = TargetInfant_HeroInfo_Equip3
	g_Card_WuJue = TargetInfant_HeroInfo_Equip4
	g_Card_QingGong = TargetInfant_HeroInfo_Equip5
	g_Card_MingShi = TargetInfant_HeroInfo_Equip6
	g_Card_Dress = TargetInfant_DressItem
	
	g_TargetPageButton[1] = TargetInfant_SelfEquip
	g_TargetPageButton[2] = TargetInfant_SelfData
	g_TargetPageButton[3] = TargetInfant_Pet
	g_TargetPageButton[4] = TargetInfant_infant
	g_TargetPageButton[5] = TargetInfant_Wuhun
	g_TargetPageButton[6] = TargetInfant_Miji
	g_TargetPageButton[7] = TargetInfant_ZhenYuan
	g_TargetPageButton[8] = TargetInfant_JingMai
	g_TargetPageButton[9] = TargetInfant_ShenDing
	g_TargetPageButton[10] = TargetInfant_JueWei
	g_TargetPageButton[11] = TargetInfant_BaoJian
	g_TargetPageButton[12] = TargetInfant_WuYi
	g_TargetPageButton[13] = TargetInfant_ShenQi
	g_TargetPageButton[14] = TargetInfant_Armor
	g_TargetPageButton[15] = TargetInfant_CangPin
	
end

function TargetInfant_Close()
	-- 取消关心OBJ
	TargetInfant_StopCareObject(g_objCared);
	this:Hide()
end

function TargetInfant_OnShow()
	TargetInfant_infant:SetCheck(1)
	this:Show()
end

function TargetInfant_OnEvent( event )
	if (event=="TOGGLE_OPENT_INFANT_OTHER") then
		local selfUnionPos = Variable:GetVariable("OtherUnionPos");
		if(selfUnionPos ~= nil) then
			g_CurCheckBox = 0  --默认显示分页一
			TargetInfant_Frame:SetProperty("UnifiedPosition", selfUnionPos);
			TargetInfant_OnShow();
			TargetInfant_OnUpdate();
		end
	elseif (event=="TOGGLE_UPDATE_INFANT_OTHER") then

		g_objCared = CachedTarget:GetData("NPCID", 1)
		if (type(g_objCared) ~="number") then
			return
		end
		--开始关心OBJ
		TargetInfant_BeginCareObject(g_objCared);
		TargetInfant_OnUpdate();
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_objCared ) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" or arg1=="destroy") then
			--取消关心
			TargetInfant_Close()
		end
	end
end

function TargetInfant_OnUpdate()
	--二期开发中可以在这儿填充娃娃列表，然后默认选中一个
	TargetInfant_UpdateModelInfo()
	--刷新选择那个的信息
	if g_CurCheckBox == 0 then
		TargetInfant_DefaultWindow_FenYe1:SetCheck(1)
		TargetInfant_DefaultWindow_FenYe2:SetCheck(0)
		TargetInfant_UpdateSelInfantInfo()
	elseif g_CurCheckBox == 1 then
		TargetInfant_DefaultWindow_FenYe1:SetCheck(0)
		TargetInfant_DefaultWindow_FenYe2:SetCheck(1)
		TargetInfant_UpdateHeroInfo()
	end

	TargetInfant_ShowPage()
end
function TargetInfant_UpdateModelInfo()

	local InfantCount = Infant:Other_GetInfantCount();
	if InfantCount <= 0 or g_CurSelInfantIndex < 0 or g_CurSelInfantIndex >= g_MaxInfantCount then
		--阶段
		TargetInfant_Proficient_Text:SetText("");
		--模型
		TargetInfant_FakeObject:RotateEnd();
		TargetInfant_FakeObject : SetFakeObject( "" );
	elseif g_CurSelInfantIndex >= 0 and g_CurSelInfantIndex < InfantCount then
		--阶段
		local nStage = Infant:Other_GetStage(g_CurSelInfantIndex)
		if g_StageName[nStage + 1] ~= nil then
			TargetInfant_Proficient_Text:SetText(g_StageName[nStage + 1]);
		end
		TargetInfant_Proficient_Text:SetText("");
		--模型
		TargetInfant_FakeObject : SetFakeObject( "" );
		Infant:Other_SetInfantModel(g_CurSelInfantIndex)
		TargetInfant_FakeObject : SetFakeObject( "Other_Infant" );

		FakeObj_SetCamera( "Other_Infant", g_CameraHeight,0.5);
		FakeObj_SetCamera( "Other_Infant", g_CameraDistance,3);
		if nStage == 3 then
			FakeObj_SetCamera( "Other_Infant", g_CameraHeight,0.7);
			FakeObj_SetCamera( "Other_Infant", g_CameraDistance,4);
		end
	end
end
function TargetInfant_UpdateSelInfantInfo()
	TargetInfant_DefaultWindow1:Show()
	TargetInfant_DefaultWindow2:Hide()
	g_Card_Dress:SetActionItem(-1)
	local InfantCount = Infant:Other_GetInfantCount();
	if InfantCount <= 0 or g_CurSelInfantIndex < 0 or g_CurSelInfantIndex >= g_MaxInfantCount then
		TargetInfant_NameLace_Text:SetText("")
		--性别
		TargetInfant_SexLace_Text:SetText("");
		---他爹
		TargetInfant_FatherLace_Text:SetText("");
		---他妈
		TargetInfant_MotherLace_Text:SetText("");
		--等级
		TargetInfant_LevelLace_Text:SetText("");
		--经验
		TargetInfant_ExLace_Text:SetText("0/0");
		-- ---他爹 干的
		-- TargetInfant_SecondFatherLace_Text:SetText("");
		-- ---他妈 干的
		-- TargetInfant_SencondMotherLace_Text:SetText("");
		--诗
		TargetInfant_SHILace_Text:SetText("");
		--书
		TargetInfant_SHULace_Text:SetText("");
		--礼
		TargetInfant_LILace_Text:SetText("");
		--乐
		TargetInfant_YUELace_Text:SetText("");
		--射
		TargetInfant_SHELace_Text:SetText("");


		--技能
		local nSkillCount = Infant:GetMaxSkillNum()
		for i = 1, nSkillCount do
			TargetInfant_Skill_Icon[i]:SetToolTip("#{ZNJCS_130825_61}");
			TargetInfant_Skill_Icon[i]:SetProperty("Image", g_default_bk_image)
			TargetInfant_Skill_Name_Text[i]:SetText("")
			TargetInfant_Skill_Value_Text[i]:SetText("")
		end
		--综合素养
		TargetInfant_MainAttributetext1_Text2:SetText("");
		TargetInfant_MainAttributeText2_Text2:SetText("");
		

	elseif g_CurSelInfantIndex >= 0 and g_CurSelInfantIndex < InfantCount then
		local szName = Infant:Other_GetInfantName(g_CurSelInfantIndex);
		TargetInfant_NameLace_Text:SetText(szName)
		--性别
		local nSex = Infant:Other_GetInfantSex(g_CurSelInfantIndex);
		if g_SexName[nSex + 1] ~= nil then
			TargetInfant_SexLace_Text:SetText(g_SexName[nSex + 1]);
		end
		---他爹
		TargetInfant_FatherLace_Text:SetText(Infant:Other_GetInfantDadName(g_CurSelInfantIndex));
		---他妈
		TargetInfant_MotherLace_Text:SetText(Infant:Other_GetInfantMumName(g_CurSelInfantIndex));
		---等级
		TargetInfant_LevelLace_Text:SetText(tostring( Infant:Other_GetInfantLevel(g_CurSelInfantIndex) ));
		---经验
		local defineInfantMaxLevel = Player:GetDefineInfantMaxLevel()
		if Infant:Other_GetInfantLevel(g_CurSelInfantIndex) >= defineInfantMaxLevel then
			TargetInfant_ExLace_Text:SetText("#{ZNJCS_130825_120}");
		else
			TargetInfant_ExLace_Text:SetText(tostring( Infant:Other_GetInfantExp(g_CurSelInfantIndex) ).."/"..tostring( Infant:Other_GetInfantCurMaxExp(g_CurSelInfantIndex) ));
		end
		-- ---他爹 干的
		-- TargetInfant_SecondFatherLace_Text:SetText(Infant:Other_GetInfantFFatherName(g_CurSelInfantIndex));
		-- ---他妈 干的
		-- TargetInfant_SencondMotherLace_Text:SetText(Infant:Other_GetInfantFMotherName(g_CurSelInfantIndex));

		---诗
		TargetInfant_SHILace_Text:SetText(tostring( Infant:Other_GetInfantAttr(g_CurSelInfantIndex, 0) ).."/"..tostring( Infant:Other_GetInfantMaxAttr(g_CurSelInfantIndex) ));
		---书
		TargetInfant_SHULace_Text:SetText(tostring( Infant:Other_GetInfantAttr(g_CurSelInfantIndex, 1) ).."/"..tostring( Infant:Other_GetInfantMaxAttr(g_CurSelInfantIndex) ));
		---礼
		TargetInfant_LILace_Text:SetText(tostring( Infant:Other_GetInfantAttr(g_CurSelInfantIndex, 2) ).."/"..tostring( Infant:Other_GetInfantMaxAttr(g_CurSelInfantIndex) ));
		---乐
		TargetInfant_YUELace_Text:SetText(tostring( Infant:Other_GetInfantAttr(g_CurSelInfantIndex, 3) ).."/"..tostring( Infant:Other_GetInfantMaxAttr(g_CurSelInfantIndex) ));
		---射
		TargetInfant_SHELace_Text:SetText(tostring( Infant:Other_GetInfantAttr(g_CurSelInfantIndex, 4) ).."/"..tostring( Infant:Other_GetInfantMaxAttr(g_CurSelInfantIndex) ));



		--技能
		local nSkillCount = Infant:GetMaxSkillNum()
		for i = 1, nSkillCount do
			local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:Other_GetSkillInfo(g_CurSelInfantIndex, i - 1)
			if nSkillID == -1 then
				TargetInfant_Skill_Icon[i]:SetToolTip("#{ZNJCS_130825_61}");
				TargetInfant_Skill_Icon[i]:SetProperty("Image", g_default_bk_image)
				TargetInfant_Skill_Name_Text[i]:SetText("")
				TargetInfant_Skill_Value_Text[i]:SetText("")
			else
				if szIcon ~= nil then
					TargetInfant_Skill_Icon[i]:SetToolTip("");
					TargetInfant_Skill_Icon[i]:SetProperty("Image", szIcon)
					TargetInfant_Skill_Name_Text[i]:SetText(szSkillName.."("..nSkillLevel.."#{WH_090729_12}"..")")
					TargetInfant_Skill_Value_Text[i]:SetText("+"..nSkillEffect)
				end
			end
		end
		--综合素养
		local mainAttribute = Infant:Other_GetMainAttribute(g_CurSelInfantIndex)
		TargetInfant_MainAttributetext1_Text2:SetText(""..mainAttribute)
		--技能加成
		local maxMainAttribute = Infant:Other_GetInfantMaxAttr_MaxLevel(g_CurSelInfantIndex)*5;
		local skillValue;
		if maxMainAttribute == 0 then
			skillValue = 0
		else
			skillValue = 100 + math.floor(mainAttribute/maxMainAttribute*100)
		end
		if skillValue > 200 then
			skillValue = 200
		end
		TargetInfant_MainAttributeText2_Text2:SetText(""..skillValue.."%")
		
		local ActionDress = EnumAction(6, "otherinfantcard")
		g_Card_Dress:SetActionItem(ActionDress:GetID())
		
	end
end

function TargetInfant_UpdateHeroInfo()
	TargetInfant_DefaultWindow1:Hide()
	TargetInfant_DefaultWindow2:Show()
	local InfantCount = Infant:Other_GetInfantCount();
	if InfantCount <= 0 or g_CurSelInfantIndex < 0 or g_CurSelInfantIndex >= g_MaxInfantCount then
		TargetInfant_Hero_Name_Text:SetText("")
		--英雄等级和经验先空出来
		--卡牌装备位
		g_Card_ShenBing:SetActionItem(-1)
		g_Card_JinZhuang:SetActionItem(-1)
		g_Card_LiangJu:SetActionItem(-1)
		g_Card_MingShi:SetActionItem(-1)
		g_Card_WuJue:SetActionItem(-1)
		g_Card_QingGong:SetActionItem(-1)
		g_Card_Dress:SetActionItem(-1)
		
		--基础属性加成
		TargetInfant_HeroInfo_Tili_Vigor1:SetText("+0")
		TargetInfant_HeroInfo_Tili_Vigor2:SetText("+0")

		TargetInfant_HeroInfo_Mingzhong_Vigor1:SetText("+0")
		TargetInfant_HeroInfo_Mingzhong_Vigor2:SetText("+0")

		TargetInfant_HeroInfo_Shenfa_Vigor1:SetText("+0")
		TargetInfant_HeroInfo_Shenfa_Vigor2:SetText("+0")

		TargetInfant_HeroInfo_Shanbi_Vigor1:SetText("+0")
		TargetInfant_HeroInfo_Shanbi_Vigor2:SetText("+0")

		TargetInfant_HeroInfo_Huixin_Vigor1:SetText("+0")
		TargetInfant_HeroInfo_Huixin_Vigor2:SetText("+0+0")
		--基础攻击加成
		TargetInfant_HeroInfo_Bing_Vigor1:SetText("+0")
		TargetInfant_HeroInfo_Bing_Vigor2:SetText("+0")

		TargetInfant_HeroInfo_Huo_Vigor1:SetText("+0")
		TargetInfant_HeroInfo_Huo_Vigor2:SetText("+0")

		TargetInfant_HeroInfo_Xuan_Vigor1:SetText("+0")
		TargetInfant_HeroInfo_Xuan_Vigor2:SetText("+0")

		TargetInfant_HeroInfo_Du_Vigor1:SetText("+0")
		TargetInfant_HeroInfo_Du_Vigor2:SetText("+0")
	elseif g_CurSelInfantIndex >= 0 and g_CurSelInfantIndex < InfantCount then

		local heroType = Infant:Other_GetHeroType(g_CurSelInfantIndex)
		if heroType <= 0 then
			 return;
		end
		TargetInfant_Hero_Name_Text:SetText(g_Infant_HeroName[heroType])

		--卡牌装备位
		g_Card_ShenBing:SetActionItem(-1)
		g_Card_JinZhuang:SetActionItem(-1)
		g_Card_LiangJu:SetActionItem(-1)
		g_Card_MingShi:SetActionItem(-1)
		g_Card_WuJue:SetActionItem(-1)
		g_Card_QingGong:SetActionItem(-1)
		g_Card_Dress:SetActionItem(-1)
		
		local ActionShenBing = EnumAction(0, "otherinfantcard")
		local ActionJinZhuang = EnumAction(1, "otherinfantcard")
		local ActionQingGong = EnumAction(2, "otherinfantcard")
		local ActionMingShi = EnumAction(3, "otherinfantcard")
		local ActionWuJue = EnumAction(4, "otherinfantcard")
		local ActionLiangJu = EnumAction(5, "otherinfantcard")
		local ActionDress = EnumAction(6, "otherinfantcard")
		
		g_Card_ShenBing:SetActionItem(ActionShenBing:GetID())
		g_Card_JinZhuang:SetActionItem(ActionJinZhuang:GetID())
		g_Card_LiangJu:SetActionItem(ActionLiangJu:GetID())
		g_Card_MingShi:SetActionItem(ActionMingShi:GetID())
		g_Card_WuJue:SetActionItem(ActionWuJue:GetID())
		g_Card_QingGong:SetActionItem(ActionQingGong:GetID())
		g_Card_Dress:SetActionItem(ActionDress:GetID())
		
		--体力
		local nCon_1 = Infant:Other_GetHeroValueFix(g_CurSelInfantIndex, HeroCon)
		local nCon_2 = Infant:Other_GetInfantCardValueFix(g_CurSelInfantIndex, HeroCon)

		TargetInfant_HeroInfo_Tili_Vigor1:SetText("体力：+"..(nCon_1+nCon_2))
		TargetInfant_HeroInfo_Tili_Vigor2:SetText("#H(+"..nCon_2..")")
		--命中
		local nHit_1 = Infant:Other_GetHeroValueFix(g_CurSelInfantIndex, HeroHit)
		local nHit_2 = Infant:Other_GetInfantCardValueFix(g_CurSelInfantIndex, HeroHit)
		TargetInfant_HeroInfo_Mingzhong_Vigor1:SetText("命中：+"..(nHit_1+nHit_2))
		TargetInfant_HeroInfo_Mingzhong_Vigor2:SetText("#H(+".. nHit_2 ..")")
		--身法
		local nDex_1 = Infant:Other_GetHeroValueFix(g_CurSelInfantIndex, HeroDex)
		local nDex_2 = Infant:Other_GetInfantCardValueFix(g_CurSelInfantIndex, HeroDex)
		TargetInfant_HeroInfo_Shenfa_Vigor1:SetText("身法：+"..(nDex_1+nDex_2))
		TargetInfant_HeroInfo_Shenfa_Vigor2:SetText("#H(+"..nDex_2..")")
		--闪避
		local nMiss_1 = Infant:Other_GetHeroValueFix(g_CurSelInfantIndex, HeroMiss)
		local nMiss_2 = Infant:Other_GetInfantCardValueFix(g_CurSelInfantIndex, HeroMiss)
		TargetInfant_HeroInfo_Shanbi_Vigor1:SetText("闪避：+"..(nMiss_1+nMiss_2))
		TargetInfant_HeroInfo_Shanbi_Vigor2:SetText("#H(+"..nMiss_2..")")
		--会心
		local nCritical_1 = Infant:Other_GetHeroValueFix(g_CurSelInfantIndex, HeroCritical)
		local nCritical_2 = Infant:Other_GetInfantCardValueFix(g_CurSelInfantIndex, HeroCritical)
		TargetInfant_HeroInfo_Huixin_Vigor1:SetText("会心攻击：+"..(nCritical_1+nCritical_2))
		TargetInfant_HeroInfo_Huixin_Vigor2:SetText("#H(+"..nCritical_2..")")
		--冰攻
		local nIceAttack_1 = Infant:Other_GetHeroValueFix(g_CurSelInfantIndex, HeroIceAttack)
		local nIceAttack_2 = Infant:Other_GetInfantCardValueFix(g_CurSelInfantIndex, HeroIceAttack)
		TargetInfant_HeroInfo_Bing_Vigor1:SetText("冰攻击：+"..(nIceAttack_1+nIceAttack_2))
		TargetInfant_HeroInfo_Bing_Vigor2:SetText("#H(+"..nIceAttack_2..")")
		--火攻
		local nFireAttack_1 = Infant:Other_GetHeroValueFix(g_CurSelInfantIndex, HeroFireAttack)
		local nFireAttack_2 = Infant:Other_GetInfantCardValueFix(g_CurSelInfantIndex, HeroFireAttack)
		TargetInfant_HeroInfo_Huo_Vigor1:SetText("火攻击：+"..(nFireAttack_1+nFireAttack_2))
		TargetInfant_HeroInfo_Huo_Vigor2:SetText("#H(+"..nFireAttack_2..")")
		--玄攻
		local nXuanAttack_1 = Infant:Other_GetHeroValueFix(g_CurSelInfantIndex, HeroXuanAttack)
		local nXuanAttack_2 = Infant:Other_GetInfantCardValueFix(g_CurSelInfantIndex, HeroXuanAttack)
		TargetInfant_HeroInfo_Xuan_Vigor1:SetText("玄攻击：+"..(nXuanAttack_1+nXuanAttack_2))
		TargetInfant_HeroInfo_Xuan_Vigor2:SetText("#H(+"..nXuanAttack_2..")")
		--毒攻
		local nPoisonAttack_1 = Infant:Other_GetHeroValueFix(g_CurSelInfantIndex, HeroPoisonAttack)
		local nPoisonAttack_2 = Infant:Other_GetInfantCardValueFix(g_CurSelInfantIndex, HeroPoisonAttack)
		TargetInfant_HeroInfo_Du_Vigor1:SetText("毒攻击：+"..(nPoisonAttack_1+nPoisonAttack_2))
		TargetInfant_HeroInfo_Du_Vigor2:SetText("#H(+"..nPoisonAttack_2..")")

		--英雄剪影
		for i=1,4 do
			g_Infant_HeroImage[i]:Hide()
			g_Infant_HeroFlash[i]:Hide()
		end

		if Infant:Other_GetIsPerfectHero(g_CurSelInfantIndex) == true then
			g_Infant_HeroFlash[heroType]:Show()
		else
			g_Infant_HeroImage[heroType]:Show()
		end
	end
end
--
function TargetInfant_SetCheckBox(index)
	if index == 1 then
		local count = Infant:Other_GetInfantCount()
		--查看的玩家并没有孩子时，给出提示
		if count <=0 then
			PushDebugMessage("#{ZNJCS_130825_148}")
			TargetInfant_DefaultWindow_FenYe1:SetCheck(1)
			TargetInfant_DefaultWindow_FenYe2:SetCheck(0)
			return
		end

		local heroType = Infant:Other_GetHeroType(g_CurSelInfantIndex)
		local level = Infant:Other_GetInfantLevel(g_CurSelInfantIndex)
		--未选择英雄类型或未到91级无法打开英雄信息页面
		if heroType <= 0 or level < 91 then
			PushDebugMessage("#{ETQWF_131106_34}")
			TargetInfant_DefaultWindow_FenYe1:SetCheck(1)
			TargetInfant_DefaultWindow_FenYe2:SetCheck(0)
			return
		end
	end

	g_CurCheckBox = index
	TargetInfant_OnUpdate()

end
----------------------------------------------------------------------------------
--
-- 旋转珍兽模型（向左)
--
function TargetInfant_Modle_TurnLeft(start)
	--向左旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		TargetInfant_FakeObject:RotateBegin(-0.3);
	--向左旋转结束
	else
		TargetInfant_FakeObject:RotateEnd();
	end
end

----------------------------------------------------------------------------------
--
--旋转珍兽模型（向右)
--
function TargetInfant_Modle_TurnRight(start)
	--向右旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		TargetInfant_FakeObject:RotateBegin(0.3);
	--向右旋转结束
	else
		TargetInfant_FakeObject:RotateEnd();
	end
end

function TargetInfant_Set_MouseLeave()
	PushEvent("INFANT_SKILL_MOUSE_LEAVE_OTHER")
end

function TargetInfant_Set_MouseEnter( index )
	local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:Other_GetSkillInfo(g_CurSelInfantIndex, index)
	if nSkillID == -1 then
		return;
	end
	local SetX = TargetInfant_Skill_Icon[index+1]:GetProperty("AbsoluteXPosition") + TargetInfant_DefaultWindow1:GetProperty("AbsoluteXPosition") + TargetInfant_Skill_Window:GetProperty("AbsoluteXPosition") + TargetInfant_Frame_Client:GetProperty("AbsoluteXPosition") + TargetInfant_Client:GetProperty("AbsoluteXPosition") + TargetInfant_Frame:GetProperty("AbsoluteXPosition");
	local SetY = TargetInfant_Skill_Icon[index+1]:GetProperty("AbsoluteYPosition") + TargetInfant_DefaultWindow1:GetProperty("AbsoluteYPosition") + TargetInfant_Skill_Window:GetProperty("AbsoluteYPosition") + TargetInfant_Frame_Client:GetProperty("AbsoluteYPosition") + TargetInfant_Client:GetProperty("AbsoluteYPosition") + TargetInfant_Frame:GetProperty("AbsoluteYPosition");
	local SetWidth = TargetInfant_Skill_Icon[index+1]:GetProperty("AbsoluteWidth")
	local SetHeight = TargetInfant_Skill_Icon[index+1]:GetProperty("AbsoluteHeight")
	PushEvent("INFANT_SKILL_MOUSE_ENTER_OTHER",SetX,SetY,SetWidth,SetHeight,g_CurSelInfantIndex,index)
end


--***************************************************************
--装备
function TargetInfant_SelfEquip_Switch()
	Variable:SetVariable("OtherUnionPos", TargetInfant_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenEquipFrame("other");
	TargetInfant_Close()
end

-- 资料
--
function TargetInfant_SelfData_Switch()
	Variable:SetVariable("OtherUnionPos", TargetInfant_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("other")
	TargetInfant_Close()
end

--
-- 珍兽
--
function TargetInfant_Pet_Switch()
	Variable:SetVariable("OtherUnionPos", TargetInfant_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPetFrame("other");
	TargetInfant_Close()
end

--武魂

function TargetInfant_Wuhun_Switch()
	Variable:SetVariable("OtherUnionPos", TargetInfant_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherWuhun();
	TargetInfant_Close()
end

--秘籍
function TargetInfant_Miji_Switch()
	Variable:SetVariable("OtherUnionPos", TargetInfant_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherMiji();
	this:Hide()
end

function TargetInfant_ZhenYuan_Switch()
	Variable:SetVariable("OtherUnionPos", TargetInfant_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleTargetZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end

--经脉
function TargetInfant_JingMai_Switch()
	Variable:SetVariable("OtherUnionPos", TargetInfant_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherJingMai();
	TargetInfant_Close()
end

--神木王鼎
function TargetInfant_TargetShenDing_Switch()
	Variable:SetVariable("OtherUnionPos", TargetInfant_Frame:GetProperty("UnifiedPosition"), 1);
	local nLevel = CachedTarget:GetData("LEVEL",1);
	if nLevel == nil or tonumber(nLevel) < 15 then
		PushDebugMessage( "#{XLDL_140606_63}" );
	else
		local bRet = SystemSetup:OpenOtherShenDing();
		if bRet == 1 then
			TargetInfant_Close()
		end
	end	
	
end

--
-- 骑乘
--
function TargetInfant_Ride_Switch()
	Variable:SetVariable("OtherUnionPos", TargetInfant_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenRidePage("other");
	TargetInfant_Close()
end
--=========================================================
--开始关心OBJ
--在开始关心之前需要先确定这个界面是不是已经有“关心”的OBJ，
--如果有的话，先取消已经有的“关心”
--=========================================================
function TargetInfant_BeginCareObject(objCaredId)

	if (type(objCaredId) == "number") then
		g_objCared = objCaredId;
		this:CareObject(g_objCared, 1, "TargetInfant");
	else
		return;
	end

end

--=========================================================
--停止对某OBJ的关心
--=========================================================
function TargetInfant_StopCareObject(objCaredId)

	if (type(objCaredId) == "number") then
		this:CareObject(objCaredId, 0, "TargetInfant");
		g_objCared = -1;
	else
		return;
	end

end

function TargetInfant_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetInfant_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetInfant_OpenBaoJian()
	Variable:SetVariable("OtherUnionPos", TargetInfant_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
end

function TargetInfant_OpenWuYi()
	Variable:SetVariable("OtherUnionPos", TargetInfant_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

function TargetInfant_OpenShenQi()
	Variable:SetVariable("OtherUnionPos", TargetInfant_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

function TargetInfant_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetInfant_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

function TargetInfant_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetInfant_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end


function TargetInfant_ShowPage()

	for i = 1, table.getn(g_TargetInfant_Page) do
		g_TargetPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	TargetInfant_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_TargetPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_TargetInfant_Page) do
			if i ~= nOtherPageNumber then
				g_TargetPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_TargetPageOrder = {}
	g_TargetPageCount = 0
	for i = 1, table.getn(g_TargetInfant_Page) do
		if TargetInfant_CheckPage(i) == 1 then
			g_TargetPageCount = g_TargetPageCount + 1
			g_TargetPageButton[g_TargetPageCount]:Show()
			g_TargetPageButton[g_TargetPageCount]:SetText(g_TargetInfant_Page[i].Text)	
			g_TargetPageOrder[g_TargetPageCount] = i
		end
	end
	
end

function TargetInfant_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_TargetPageOrder[idx]
	
	if idx == 1 then--装备
		TargetInfant_SelfEquip_Switch();
	elseif idx == 2 then--资料
		TargetInfant_SelfData_Switch()
	elseif idx == 3 then--珍兽
		TargetInfant_Pet_Switch()
	elseif idx == 4 then--子女
		--TargetWuhun_TargetInfant_Down()
	elseif idx == 5 then--武魂
		TargetInfant_Wuhun_Switch()
	elseif idx == 6 then--秘籍
		TargetInfant_Miji_Switch()
	elseif idx == 7 then--真元
		TargetInfant_ZhenYuan_Switch()
	elseif idx == 8 then--经脉
		TargetInfant_JingMai_Switch()
	elseif idx == 9 then--神鼎
		TargetInfant_TargetShenDing_Switch()
	elseif idx == 10 then--侠印
		TargetInfant_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		TargetInfant_OpenBaoJian()
	elseif idx == 12 then--武意
		TargetInfant_OpenWuYi()
	elseif idx == 13 then--神器
		TargetInfant_OpenShenQi()
	elseif idx == 14 then--星盘
		TargetInfant_Armor_Page_Switch()
	elseif idx == 15 then--名物
		TargetInfant_CangPin_Page_Switch()
	end
end

function TargetInfant_CheckPage(idx)
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

function TargetInfant_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end


