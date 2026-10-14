--TargetInfant2.lua
--*********************
--娃娃主界面
--*********************
local g_CameraHeight = 1;     --摄影机高度
local g_CameraDistance = 2;   --摄影机距离
local g_CameraPitch = 3;      --摄影机角度
local g_Max_CardType_Num = 7;

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
local TargetInfant2_Skill_Icon = {};
local TargetInfant2_Skill_Name_Text = {};
local TargetInfant2_Skill_Value_Text = {};

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

function TargetInfant2_PreLoad()
	this:RegisterEvent("OPEN_TARGET_INFANT_UI");

	this:RegisterEvent("OBJECT_CARED_EVENT",false);
end

function TargetInfant2_OnLoad()
	TargetInfant2_Skill_Icon[1] = TargetInfant2_SkillImage1
	TargetInfant2_Skill_Icon[2] = TargetInfant2_SkillImage2
	TargetInfant2_Skill_Icon[3] = TargetInfant2_SkillImage3
	TargetInfant2_Skill_Icon[4] = TargetInfant2_SkillImage4

	g_default_bk_image = TargetInfant2_SkillImage1:GetProperty("Image")

	TargetInfant2_Skill_Name_Text[1] = TargetInfant2_SkillNum1_text1
	TargetInfant2_Skill_Name_Text[2] = TargetInfant2_SkillNum2_text1
	TargetInfant2_Skill_Name_Text[3] = TargetInfant2_SkillNum3_text1
	TargetInfant2_Skill_Name_Text[4] = TargetInfant2_SkillNum4_text1

	TargetInfant2_Skill_Value_Text[1] = TargetInfant2_SkillNum1_text2
	TargetInfant2_Skill_Value_Text[2] = TargetInfant2_SkillNum2_text2
	TargetInfant2_Skill_Value_Text[3] = TargetInfant2_SkillNum3_text2
	TargetInfant2_Skill_Value_Text[4] = TargetInfant2_SkillNum4_text2

	g_Infant_HeroImage[1] = TargetInfant2_Hero_QiaofengImage
	g_Infant_HeroImage[2] = TargetInfant2_Hero_DuanyuImage
	g_Infant_HeroImage[3] = TargetInfant2_Hero_XuzhuImage
	g_Infant_HeroImage[4] = TargetInfant2_Hero_WangyuyanImage

	g_Infant_HeroFlash[1] = TargetInfant2_Hero_QiaofengFlash
	g_Infant_HeroFlash[2] = TargetInfant2_Hero_DuanyuFlash
	g_Infant_HeroFlash[3] = TargetInfant2_Hero_XuzhuFlash
	g_Infant_HeroFlash[4] = TargetInfant2_Hero_WangyuyanFlash

	g_Card_ShenBing = TargetInfant2_HeroInfo_Equip1
	g_Card_JinZhuang = TargetInfant2_HeroInfo_Equip2
	g_Card_LiangJu = TargetInfant2_HeroInfo_Equip3
	g_Card_WuJue = TargetInfant2_HeroInfo_Equip4
	g_Card_QingGong = TargetInfant2_HeroInfo_Equip5
	g_Card_MingShi = TargetInfant2_HeroInfo_Equip6
	g_Card_Dress = TargetInfant2_DressItem
end

function TargetInfant2_Close()
	-- 取消关心OBJ
	TargetInfant2_StopCareObject(g_objCared);
	this:Hide()
end

function TargetInfant2_OnShow()
	this:Show()
end

function TargetInfant2_OnEvent( event )
	if (event=="OPEN_TARGET_INFANT_UI") then
		g_CurCheckBox = 0  --默认显示分页一
		TargetInfant2_OnShow();
		TargetInfant2_OnUpdate();
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= g_objCared ) then
			return;
		end
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if(arg1 == "distance" or arg1=="destroy") then
			--取消关心
			TargetInfant2_Close()
		end
	end
end

function TargetInfant2_OnUpdate()
	TargetInfant2_UpdateModelInfo()

	--刷新选择那个的信息
	if g_CurCheckBox == 0 then
		TargetInfant2_DefaultWindow_FenYe1:SetCheck(1)
		TargetInfant2_DefaultWindow_FenYe2:SetCheck(0)
		TargetInfant2_UpdateSelInfantInfo()
	elseif g_CurCheckBox == 1 then
		TargetInfant2_DefaultWindow_FenYe1:SetCheck(0)
		TargetInfant2_DefaultWindow_FenYe2:SetCheck(1)
		TargetInfant2_UpdateHeroInfo()
	end

end
function TargetInfant2_UpdateModelInfo()

	--阶段
	local nStage = Infant:Target_GetStage()
	if g_StageName[nStage + 1] ~= nil then
		TargetInfant2_Proficient_Text:SetText(g_StageName[nStage + 1]);
	end
	TargetInfant2_Proficient_Text:SetText("");
	--模型
	TargetInfant2_FakeObject : SetFakeObject( "" );
	Infant:Target_SetInfantModel()
	TargetInfant2_FakeObject : SetFakeObject( "Target_Infant" );

	FakeObj_SetCamera( "Target_Infant", g_CameraHeight,0.5);
	FakeObj_SetCamera( "Target_Infant", g_CameraDistance,3);
	if nStage == 3 then
		FakeObj_SetCamera( "Target_Infant", g_CameraHeight,0.7);
		FakeObj_SetCamera( "Target_Infant", g_CameraDistance,4);
	end
end
function TargetInfant2_UpdateSelInfantInfo()
	TargetInfant2_DefaultWindow1:Show()
	TargetInfant2_DefaultWindow2:Hide()

	local szName = Infant:Target_GetInfantName();
	TargetInfant2_NameLace_Text:SetText(szName)
	--性别
	local nSex = Infant:Target_GetInfantSex();
	if g_SexName[nSex + 1] ~= nil then
		TargetInfant2_SexLace_Text:SetText(g_SexName[nSex + 1]);
	end
	---他爹
	TargetInfant2_FatherLace_Text:SetText(Infant:Target_GetInfantDadName());
	---他妈
	TargetInfant2_MotherLace_Text:SetText(Infant:Target_GetInfantMumName());
	---等级
	TargetInfant2_LevelLace_Text:SetText(tostring( Infant:Target_GetInfantLevel() ));
	---经验
	local defineInfantMaxLevel = Player:GetDefineInfantMaxLevel()
	if Infant:Target_GetInfantLevel() >= defineInfantMaxLevel then
		TargetInfant2_ExLace_Text:SetText("#{ZNJCS_130825_120}");
	else
		TargetInfant2_ExLace_Text:SetText(tostring( Infant:Target_GetInfantExp() ).."/"..tostring( Infant:Target_GetInfantCurMaxExp() ));
	end
	-- ---他爹 干的
	-- TargetInfant2_SecondFatherLace_Text:SetText(Infant:Target_GetInfantFFatherName());
	-- ---他妈 干的
	-- TargetInfant2_SencondMotherLace_Text:SetText(Infant:Target_GetInfantFMotherName());

	---诗
	TargetInfant2_SHILace_Text:SetText(tostring( Infant:Target_GetInfantAttr( 0) ).."/"..tostring( Infant:Target_GetInfantMaxAttr() ));
	---书
	TargetInfant2_SHULace_Text:SetText(tostring( Infant:Target_GetInfantAttr( 1) ).."/"..tostring( Infant:Target_GetInfantMaxAttr() ));
	---礼
	TargetInfant2_LILace_Text:SetText(tostring( Infant:Target_GetInfantAttr( 2) ).."/"..tostring( Infant:Target_GetInfantMaxAttr() ));
	---乐
	TargetInfant2_YUELace_Text:SetText(tostring( Infant:Target_GetInfantAttr( 3) ).."/"..tostring( Infant:Target_GetInfantMaxAttr() ));
	---射
	TargetInfant2_SHELace_Text:SetText(tostring( Infant:Target_GetInfantAttr( 4) ).."/"..tostring( Infant:Target_GetInfantMaxAttr() ));



	--技能
	local nSkillCount = Infant:GetMaxSkillNum()
	for i = 1, nSkillCount do
		local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:Target_GetSkillInfo( i - 1)
		if nSkillID == -1 then
			TargetInfant2_Skill_Icon[i]:SetToolTip("#{ZNJCS_130825_61}");
			TargetInfant2_Skill_Icon[i]:SetProperty("Image", g_default_bk_image)
			TargetInfant2_Skill_Name_Text[i]:SetText("")
			TargetInfant2_Skill_Value_Text[i]:SetText("")
		else
			if szIcon ~= nil then
				TargetInfant2_Skill_Icon[i]:SetToolTip("");
				TargetInfant2_Skill_Icon[i]:SetProperty("Image", szIcon)
				TargetInfant2_Skill_Name_Text[i]:SetText(szSkillName.."("..nSkillLevel.."#{WH_090729_12}"..")")
				TargetInfant2_Skill_Value_Text[i]:SetText("+"..nSkillEffect)
			end
		end
	end
	--综合素养
	local mainAttribute = Infant:Target_GetMainAttribute()
	TargetInfant2_MainAttributetext1_Text2:SetText(""..mainAttribute)
	--技能加成
	local maxMainAttribute = Infant:Target_GetInfantMaxAttr_MaxLevel()*5;
	local skillValue;
	if maxMainAttribute == 0 then
		skillValue = 0
	else
		skillValue = 100 + math.floor(mainAttribute/maxMainAttribute*100)
	end
	if skillValue > 200 then
		skillValue = 200
	end
	TargetInfant2_MainAttributeText2_Text2:SetText(""..skillValue.."%")
	
	local nMaxInfantCount = Infant:GetInfantMaxCount();
	local ActionDress = EnumAction(g_Max_CardType_Num*nMaxInfantCount + 6, "otherinfantcard")
	g_Card_Dress:SetActionItem(ActionDress:GetID())
end

function TargetInfant2_UpdateHeroInfo()
	TargetInfant2_DefaultWindow1:Hide()
	TargetInfant2_DefaultWindow2:Show()
	local nMaxInfantCount = Infant:GetInfantMaxCount();
	local heroType = Infant:Target_GetHeroType()
	if heroType <= 0 then
		 return;
	end
	TargetInfant2_Hero_Name_Text:SetText(g_Infant_HeroName[heroType])

	--卡牌装备位
	g_Card_ShenBing:SetActionItem(-1)
	g_Card_JinZhuang:SetActionItem(-1)
	g_Card_LiangJu:SetActionItem(-1)
	g_Card_MingShi:SetActionItem(-1)
	g_Card_WuJue:SetActionItem(-1)
	g_Card_QingGong:SetActionItem(-1)
	g_Card_Dress:SetActionItem(-1)

	local ActionShenBing = EnumAction(g_Max_CardType_Num*nMaxInfantCount + 0, "otherinfantcard")
	local ActionJinZhuang = EnumAction(g_Max_CardType_Num*nMaxInfantCount + 1, "otherinfantcard")
	local ActionQingGong = EnumAction(g_Max_CardType_Num*nMaxInfantCount + 2, "otherinfantcard")
	local ActionMingShi = EnumAction(g_Max_CardType_Num*nMaxInfantCount + 3, "otherinfantcard")
	local ActionWuJue = EnumAction(g_Max_CardType_Num*nMaxInfantCount + 4, "otherinfantcard")
	local ActionLiangJu = EnumAction(g_Max_CardType_Num*nMaxInfantCount + 5, "otherinfantcard")
	local ActionDress = EnumAction(g_Max_CardType_Num*nMaxInfantCount + 6, "otherinfantcard")
	
	g_Card_ShenBing:SetActionItem(ActionShenBing:GetID())
	g_Card_JinZhuang:SetActionItem(ActionJinZhuang:GetID())
	g_Card_LiangJu:SetActionItem(ActionLiangJu:GetID())
	g_Card_MingShi:SetActionItem(ActionMingShi:GetID())
	g_Card_WuJue:SetActionItem(ActionWuJue:GetID())
	g_Card_QingGong:SetActionItem(ActionQingGong:GetID())
	g_Card_Dress:SetActionItem(ActionDress:GetID())
	
	--体力
	local nCon_1 = Infant:Target_GetHeroValueFix(0, HeroCon)
	local nCon_2 = Infant:Target_GetInfantCardValueFix(0, HeroCon)

	TargetInfant2_HeroInfo_Tili_Vigor1:SetText("体力：+"..(nCon_1+nCon_2))
	TargetInfant2_HeroInfo_Tili_Vigor2:SetText("#H(+"..nCon_2..")")
	--命中
	local nHit_1 = Infant:Target_GetHeroValueFix(0, HeroHit)
	local nHit_2 = Infant:Target_GetInfantCardValueFix( 0,HeroHit)
	TargetInfant2_HeroInfo_Mingzhong_Vigor1:SetText("命中：+"..(nHit_1+nHit_2))
	TargetInfant2_HeroInfo_Mingzhong_Vigor2:SetText("#H(+".. nHit_2 ..")")
	--身法
	local nDex_1 = Infant:Target_GetHeroValueFix(0, HeroDex)
	local nDex_2 = Infant:Target_GetInfantCardValueFix(0, HeroDex)
	TargetInfant2_HeroInfo_Shenfa_Vigor1:SetText("身法：+"..(nDex_1+nDex_2))
	TargetInfant2_HeroInfo_Shenfa_Vigor2:SetText("#H(+"..nDex_2..")")
	--闪避
	local nMiss_1 = Infant:Target_GetHeroValueFix(0, HeroMiss)
	local nMiss_2 = Infant:Target_GetInfantCardValueFix(0, HeroMiss)
	TargetInfant2_HeroInfo_Shanbi_Vigor1:SetText("闪避：+"..(nMiss_1+nMiss_2))
	TargetInfant2_HeroInfo_Shanbi_Vigor2:SetText("#H(+"..nMiss_2..")")
	--会心
	local nCritical_1 = Infant:Target_GetHeroValueFix(0, HeroCritical)
	local nCritical_2 = Infant:Target_GetInfantCardValueFix(0, HeroCritical)
	TargetInfant2_HeroInfo_Huixin_Vigor1:SetText("会心攻击：+"..(nCritical_1+nCritical_2))
	TargetInfant2_HeroInfo_Huixin_Vigor2:SetText("#H(+"..nCritical_2..")")
	--冰攻
	local nIceAttack_1 = Infant:Target_GetHeroValueFix(0, HeroIceAttack)
	local nIceAttack_2 = Infant:Target_GetInfantCardValueFix(0, HeroIceAttack)
	TargetInfant2_HeroInfo_Bing_Vigor1:SetText("冰攻击：+"..(nIceAttack_1+nIceAttack_2))
	TargetInfant2_HeroInfo_Bing_Vigor2:SetText("#H(+"..nIceAttack_2..")")
	--火攻
	local nFireAttack_1 = Infant:Target_GetHeroValueFix(0, HeroFireAttack)
	local nFireAttack_2 = Infant:Target_GetInfantCardValueFix(0, HeroFireAttack)
	TargetInfant2_HeroInfo_Huo_Vigor1:SetText("火攻击：+"..(nFireAttack_1+nFireAttack_2))
	TargetInfant2_HeroInfo_Huo_Vigor2:SetText("#H(+"..nFireAttack_2..")")
	--玄攻
	local nXuanAttack_1 = Infant:Target_GetHeroValueFix(0, HeroXuanAttack)
	local nXuanAttack_2 = Infant:Target_GetInfantCardValueFix(0, HeroXuanAttack)
	TargetInfant2_HeroInfo_Xuan_Vigor1:SetText("玄攻击：+"..(nXuanAttack_1+nXuanAttack_2))
	TargetInfant2_HeroInfo_Xuan_Vigor2:SetText("#H(+"..nXuanAttack_2..")")
	--毒攻
	local nPoisonAttack_1 = Infant:Target_GetHeroValueFix(0, HeroPoisonAttack)
	local nPoisonAttack_2 = Infant:Target_GetInfantCardValueFix(0, HeroPoisonAttack)
	TargetInfant2_HeroInfo_Du_Vigor1:SetText("毒攻击：+"..(nPoisonAttack_1+nPoisonAttack_2))
	TargetInfant2_HeroInfo_Du_Vigor2:SetText("#H(+"..nPoisonAttack_2..")")


			--英雄剪影
	for i=1,4 do
		g_Infant_HeroImage[i]:Hide()
		g_Infant_HeroFlash[i]:Hide()
	end

	if Infant:Target_GetIsPerfectHero() == true then
		g_Infant_HeroFlash[heroType]:Show()
	else
		g_Infant_HeroImage[heroType]:Show()
	end
end
--
function TargetInfant2_SetCheckBox(index)
	if index == 1 then
		local heroType = Infant:Target_GetHeroType()
		local level = Infant:Target_GetInfantLevel()
		--未选择英雄类型或未到91级无法打开英雄信息页面
		if heroType <= 0 or level < 91 then
			PushDebugMessage("#{ETQWF_131106_34}")
			TargetInfant2_DefaultWindow_FenYe1:SetCheck(1)
			TargetInfant2_DefaultWindow_FenYe2:SetCheck(0)
			return
		end
	end

	g_CurCheckBox = index
	TargetInfant2_OnUpdate()

end
----------------------------------------------------------------------------------
--
-- 旋转珍兽模型（向左)
--
function TargetInfant2_Modle_TurnLeft(start)
	--向左旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		TargetInfant2_FakeObject:RotateBegin(-0.3);
	--向左旋转结束
	else
		TargetInfant2_FakeObject:RotateEnd();
	end
end

----------------------------------------------------------------------------------
--
--旋转珍兽模型（向右)
--
function TargetInfant2_Modle_TurnRight(start)
	--向右旋转开始
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		TargetInfant2_FakeObject:RotateBegin(0.3);
	--向右旋转结束
	else
		TargetInfant2_FakeObject:RotateEnd();
	end
end

function TargetInfant2_Set_MouseLeave()
	PushEvent("INFANT_SKILL_MOUSE_LEAVE_OTHER")
end

function TargetInfant2_Set_MouseEnter( index )
	local nSkillID, nSkillLevel, nSkillEffect, nSkillUpRate, szSkillName, szIcon, szTipsInfo = Infant:Target_GetSkillInfo( index)
	if nSkillID == -1 then
		return;
	end
	local SetX = TargetInfant2_Skill_Icon[index+1]:GetProperty("AbsoluteXPosition") + TargetInfant2_Skill_Window:GetProperty("AbsoluteXPosition") + TargetInfant2_DefaultWindow1:GetProperty("AbsoluteXPosition") + TargetInfant2_Frame_Client:GetProperty("AbsoluteXPosition") + TargetInfant2_Client:GetProperty("AbsoluteXPosition") + TargetInfant2_Frame:GetProperty("AbsoluteXPosition");
	local SetY = TargetInfant2_Skill_Icon[index+1]:GetProperty("AbsoluteYPosition") + TargetInfant2_Skill_Window:GetProperty("AbsoluteYPosition") + TargetInfant2_DefaultWindow1:GetProperty("AbsoluteYPosition") + TargetInfant2_Frame_Client:GetProperty("AbsoluteYPosition") + TargetInfant2_Client:GetProperty("AbsoluteYPosition") + TargetInfant2_Frame:GetProperty("AbsoluteYPosition");
	local SetWidth = TargetInfant2_Skill_Icon[index+1]:GetProperty("AbsoluteWidth")
	local SetHeight = TargetInfant2_Skill_Icon[index+1]:GetProperty("AbsoluteHeight")
	PushEvent("INFANT_SKILL_MOUSE_ENTER_TARGET",SetX,SetY,SetWidth,SetHeight,index)
end
--=========================================================
--开始关心OBJ
--在开始关心之前需要先确定这个界面是不是已经有“关心”的OBJ，
--如果有的话，先取消已经有的“关心”
--=========================================================
function TargetInfant2_BeginCareObject(objCaredId)

	if (type(objCaredId) == "number") then
		g_objCared = objCaredId;
		this:CareObject(g_objCared, 1, "TargetInfant2");
	else
		return;
	end

end

--=========================================================
--停止对某OBJ的关心
--=========================================================
function TargetInfant2_StopCareObject(objCaredId)

	if (type(objCaredId) == "number") then
		this:CareObject(objCaredId, 0, "TargetInfant2");
		g_objCared = -1;
	else
		return;
	end

end
