----------------------------------------------
-- 【2017Q3】九星神器升星设计
-- 神器DIY技能效果玩法规则
-- 新神器技能效果配置界面
-- ****搜索关键字： 神器DIY技能 DIYSkill
-- !!!reloadscript =SuperWeapon9_DIYSkill
----------------------------------------------

-- 窗口位置
local g_SuperWeapon9_DIYSkill_UnifiedPosition

-- 神器
local g_SuperWeapon9_DIYSkill_WeaponText
local g_SuperWeapon9_DIYSkill_WeaponSlot
local g_SuperWeapon9_DIYSkill_WeaponIndex = -1
local g_SuperWeapon9_DIYSkill_WeaponMask

-- 技能
local g_SuperWeapon9_DIYSkill_SkillSlot
local g_SuperWeapon9_DIYSkill_SkillMask
local g_SuperWeapon9_DIYSkill_SkillText

-- 插槽
local g_SuperWeapon9_DIYSkill_SlotNum = 3
local g_SuperWeapon9_DIYSkill_SlotLevelLimit = 10
local g_SuperWeapon9_DIYSkill_SlotButton = {}
local g_SuperWeapon9_DIYSkill_SlotImage = {}
local g_SuperWeapon9_DIYSkill_SlotLevel = {}
--local g_SuperWeapon9_DIYSkill_SlotSkill = {}
local g_SuperWeapon9_DIYSkill_SlotLock = {}
local g_SuperWeapon9_DIYSkill_SlotLevelup = {}
local g_SuperWeapon9_DIYSkill_SlotSelect = {}
local g_SuperWeapon9_DIYSkill_ImpactItem = {}

-- 效果页面
local g_SuperWeapon9_DIYSkill_ImpactTitle
local g_SuperWeapon9_DIYSkill_ImpactButton
local g_SuperWeapon9_DIYSkill_ImpactName
local g_SuperWeapon9_DIYSkill_ImpactIntro
--local g_SuperWeapon9_DIYSkill_ImpactCost
local g_SuperWeapon9_DIYSkill_ImpactBK = {}

-- 具体效果
local g_SuperWeapon9_DIYSkill_ImpactNum = 4
local g_SuperWeapon9_DIYSkill_ImpactIcon = {}
local g_SuperWeapon9_DIYSkill_ImpactAnimate = {}
local g_SuperWeapon9_DIYSkill_ImpactMask={}
-- 当前效果列表的具体数值
local g_SuperWeapon9_DIYSkill_ImpactId = {0,0,0,0}

-- 目前只开放12个
--local g_SuperWeapon9_DIYSkill_ImpactMF = {1835,1836,1837,1838,1839,1840,1841,1842,1843,1844,1845,1846,1847,1848,1849}
local g_SuperWeapon9_DIYSkill_ImpactMFBegin = 1835

-- 效果页面用
local g_SuperWeapon9_DIYSkill_SlotIndex = 0 
local g_SuperWeapon9_DIYSkill_ImpactIndex = 0
local g_SuperWeapon9_DIYSkill_EmbedImpactId = 0

-- 远离npc关闭
local MAX_OBJ_DISTANCE = 3.0
local g_ObjCared = -1
local g_TargetServerID = -1

-- 显示数据
local g_SuperWeapon9_DIYSkill_Data = 
{
	[1] = { itemId = 38002040, bindId = 38002041, nameText = "#{JXSQ_170804_67}", lockText = "#{JXSQ_170804_70}", title = "#{JXSQ_170804_92}", costText = "#{JXSQ_170804_98}", itemText = "#{JXSQ_170804_102}", itemTextRed = "#{JXSQ_170829_265}", itemTip = "#{JXSQ_170829_219}", levelTip = "#{JXSQ_170829_207}", },
	[2] = { itemId = 38002042, bindId = 38002043, nameText = "#{JXSQ_170804_68}", lockText = "#{JXSQ_170804_71}", title = "#{JXSQ_170804_93}", costText = "#{JXSQ_170804_99}", itemText = "#{JXSQ_170804_103}", itemTextRed = "#{JXSQ_170829_266}", itemTip = "#{JXSQ_170829_220}", levelTip = "#{JXSQ_170829_247}", },
	[3] = { itemId = 38002044, bindId = 38002045, nameText = "#{JXSQ_170804_69}", lockText = "#{JXSQ_170804_72}", title = "#{JXSQ_170804_94}", costText = "#{JXSQ_170804_100}", itemText = "#{JXSQ_170804_104}", itemTextRed = "#{JXSQ_170829_267}", itemTip = "#{JXSQ_170829_221}", levelTip = "#{JXSQ_170829_248}", },
}

-- 镶嵌按钮cd
local g_SuperWeapon9_DIYSkill_Cooldown = 3*1000		--3s按钮冷却
local g_SuperWeapon9_DIYSkill_InCooldown = 0			--是否在冷却

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_SuperWeapon9_DIYSkill_Page = {
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

local g_SuperWeapon9_DIYSkill_PageButton = {}
local g_SuperWeapon9_DIYSkill_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

--**********************************
-- 神器DIY技能--PreLoad
--**********************************
function SuperWeapon9_DIYSkill_PreLoad()

	this:RegisterEvent("UI_COMMAND");
	--this:RegisterEvent("SUPERWEAPONDIYSKILL_OPENUI");--打开界面
	--this:RegisterEvent("SUPERWEAPONDIYSKILL_PUTWEAPON");--放入
	--this:RegisterEvent("SUPERWEAPON9_DRAGEND");--挪出
	this:RegisterEvent("PACKAGE_ITEM_CHANGED_EX",false)--道具更新
  this:RegisterEvent("REFRESH_EQUIP");--装备更新
	--this:RegisterEvent("OBJECT_CARED_EVENT",false);
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);	--	窗口大小变换
	this:RegisterEvent("9START_TUO_SKILL")     --【九星神器引导任务】任务5
	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK");		--升级
	this:RegisterEvent("TOGGLE_UPDATE_INFANT"); --子女有变化 刷新按钮状态
	this:RegisterEvent("FINISH_MISSION");
	this:RegisterEvent("MARTIAL_UPDATE",false)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)
end

--**********************************
-- 神器DIY技能--OnLoad
--**********************************
function SuperWeapon9_DIYSkill_OnLoad()

	-- 主页面
	-- [物品描述]
	g_SuperWeapon9_DIYSkill_WeaponText = SuperWeapon9_DIYSkill_MainFrame_Text1
	-- [背包物品]
	g_SuperWeapon9_DIYSkill_WeaponSlot = SuperWeapon9_DIYSkill_MainFrame_Item
	-- [物品栏]
	g_SuperWeapon9_DIYSkill_WeaponMask = SuperWeapon9_DIYSkill_MainFrame_Item_Mask
	-- [技能栏]
	g_SuperWeapon9_DIYSkill_SkillSlot = SuperWeapon9_DIYSkill_MainFrame_Skill
	-- [技能栏蒙红]
	g_SuperWeapon9_DIYSkill_SkillMask = SuperWeapon9_DIYSkill_MainFrame_Skill_Feng
	-- [技能描述]
	g_SuperWeapon9_DIYSkill_SkillText = SuperWeapon9_DIYSkill_MainFrame_Skill_text
	-- [插槽图标]
	g_SuperWeapon9_DIYSkill_SlotButton[1] = SuperWeapon9_DIYSkill_MainFrame_Slot1_Skill
	g_SuperWeapon9_DIYSkill_SlotButton[2] = SuperWeapon9_DIYSkill_MainFrame_Slot2_Skill
	g_SuperWeapon9_DIYSkill_SlotButton[3] = SuperWeapon9_DIYSkill_MainFrame_Slot3_Skill	
	-- [插槽未解锁图片]
	g_SuperWeapon9_DIYSkill_SlotImage[1] = SuperWeapon9_DIYSkill_MainFrame_Slot1_SkillLocked
	g_SuperWeapon9_DIYSkill_SlotImage[2] = SuperWeapon9_DIYSkill_MainFrame_Slot2_SkillLocked
	g_SuperWeapon9_DIYSkill_SlotImage[3] = SuperWeapon9_DIYSkill_MainFrame_Slot3_SkillLocked	
	-- [插槽等级]
	g_SuperWeapon9_DIYSkill_SlotLevel[1] = SuperWeapon9_DIYSkill_MainFrame_Slot1_Level
	g_SuperWeapon9_DIYSkill_SlotLevel[2] = SuperWeapon9_DIYSkill_MainFrame_Slot2_Level
	g_SuperWeapon9_DIYSkill_SlotLevel[3] = SuperWeapon9_DIYSkill_MainFrame_Slot3_Level	
	-- [插槽镶嵌技能名称]
	--g_SuperWeapon9_DIYSkill_SlotSkill[1] = SuperWeapon9_DIYSkill_MainFrame_Slot1_SkillName
	--g_SuperWeapon9_DIYSkill_SlotSkill[2] = SuperWeapon9_DIYSkill_MainFrame_Slot2_SkillName
	--g_SuperWeapon9_DIYSkill_SlotSkill[3] = SuperWeapon9_DIYSkill_MainFrame_Slot3_SkillName	
	-- [插槽未解锁文字]
	g_SuperWeapon9_DIYSkill_SlotLock[1] = SuperWeapon9_DIYSkill_MainFrame_Slot1_Locked
	g_SuperWeapon9_DIYSkill_SlotLock[2] = SuperWeapon9_DIYSkill_MainFrame_Slot2_Locked
	g_SuperWeapon9_DIYSkill_SlotLock[3] = SuperWeapon9_DIYSkill_MainFrame_Slot3_Locked
	-- [插槽升级按钮]
	g_SuperWeapon9_DIYSkill_SlotLevelup[1] = SuperWeapon9_DIYSkill_MainFrame_Slot1_LevelUp
	g_SuperWeapon9_DIYSkill_SlotLevelup[2] = SuperWeapon9_DIYSkill_MainFrame_Slot2_LevelUp
	g_SuperWeapon9_DIYSkill_SlotLevelup[3] = SuperWeapon9_DIYSkill_MainFrame_Slot3_LevelUp
	-- [插槽选中框]
	g_SuperWeapon9_DIYSkill_SlotSelect[1] = SuperWeapon9_DIYSkill_MainFrame_Slot1_Selected
	g_SuperWeapon9_DIYSkill_SlotSelect[2] = SuperWeapon9_DIYSkill_MainFrame_Slot2_Selected
	g_SuperWeapon9_DIYSkill_SlotSelect[3] = SuperWeapon9_DIYSkill_MainFrame_Slot3_Selected
	-- [道具数量]
	g_SuperWeapon9_DIYSkill_ImpactItem[1] = SuperWeapon9_DIYSkill_SkillFrame_HaveItem1
	g_SuperWeapon9_DIYSkill_ImpactItem[2] = SuperWeapon9_DIYSkill_SkillFrame_HaveItem2
	g_SuperWeapon9_DIYSkill_ImpactItem[3] = SuperWeapon9_DIYSkill_SkillFrame_HaveItem3
	
	-- 效果页面
	-- [标题]
	g_SuperWeapon9_DIYSkill_ImpactTitle = SuperWeapon9_DIYSkill_SkillFrame_title
	-- [确认按钮]
	g_SuperWeapon9_DIYSkill_ImpactButton = SuperWeapon9_DIYSkill_SkillFrame_buy	
	-- [效果名称]
	g_SuperWeapon9_DIYSkill_ImpactName = SuperWeapon9_DIYSkill_SkillFrame_Name
	-- [效果描述]
	g_SuperWeapon9_DIYSkill_ImpactIntro = SuperWeapon9_DIYSkill_SkillFrame_Intro
	-- [效果消耗]
	--g_SuperWeapon9_DIYSkill_ImpactCost = SuperWeapon9_DIYSkill_SkillFrame_Text
	
	-- [效果背景图]
	g_SuperWeapon9_DIYSkill_ImpactBK = 
	{
		SuperWeapon9_DIYSkill_SkillFrame1_BK, SuperWeapon9_DIYSkill_SkillFrame2_BK, SuperWeapon9_DIYSkill_SkillFrame3_BK,
	}
	-- [效果图标]
	g_SuperWeapon9_DIYSkill_ImpactIcon =
	{
		{SuperWeapon9_DIYSkill_SkillFrame1_Skill1_icon,SuperWeapon9_DIYSkill_SkillFrame1_Skill2_icon,SuperWeapon9_DIYSkill_SkillFrame1_Skill3_icon,SuperWeapon9_DIYSkill_SkillFrame1_Skill4_icon},
		{SuperWeapon9_DIYSkill_SkillFrame2_Skill1_icon,SuperWeapon9_DIYSkill_SkillFrame2_Skill2_icon,SuperWeapon9_DIYSkill_SkillFrame2_Skill3_icon,SuperWeapon9_DIYSkill_SkillFrame2_Skill4_icon},
		{SuperWeapon9_DIYSkill_SkillFrame3_Skill1_icon,SuperWeapon9_DIYSkill_SkillFrame3_Skill2_icon,SuperWeapon9_DIYSkill_SkillFrame3_Skill3_icon,SuperWeapon9_DIYSkill_SkillFrame3_Skill4_icon},
	}	
	-- [效果选中框]
	g_SuperWeapon9_DIYSkill_ImpactAnimate =
	{
		{SuperWeapon9_DIYSkill_SkillFrame1_Skill1_iconAnimate,SuperWeapon9_DIYSkill_SkillFrame1_Skill2_iconAnimate,SuperWeapon9_DIYSkill_SkillFrame1_Skill3_iconAnimate,SuperWeapon9_DIYSkill_SkillFrame1_Skill4_iconAnimate},
		{SuperWeapon9_DIYSkill_SkillFrame2_Skill1_iconAnimate,SuperWeapon9_DIYSkill_SkillFrame2_Skill2_iconAnimate,SuperWeapon9_DIYSkill_SkillFrame2_Skill3_iconAnimate,SuperWeapon9_DIYSkill_SkillFrame2_Skill4_iconAnimate},
		{SuperWeapon9_DIYSkill_SkillFrame3_Skill1_iconAnimate,SuperWeapon9_DIYSkill_SkillFrame3_Skill2_iconAnimate,SuperWeapon9_DIYSkill_SkillFrame3_Skill3_iconAnimate,SuperWeapon9_DIYSkill_SkillFrame3_Skill4_iconAnimate},
	}
	-- [效果蒙红]
	g_SuperWeapon9_DIYSkill_ImpactMask =
	{
		{SuperWeapon9_DIYSkill_SkillFrame1_Skill1_iconMask,SuperWeapon9_DIYSkill_SkillFrame1_Skill2_iconMask,SuperWeapon9_DIYSkill_SkillFrame1_Skill3_iconMask,SuperWeapon9_DIYSkill_SkillFrame1_Skill4_iconMask},
		{SuperWeapon9_DIYSkill_SkillFrame2_Skill1_iconMask,SuperWeapon9_DIYSkill_SkillFrame2_Skill2_iconMask,SuperWeapon9_DIYSkill_SkillFrame2_Skill3_iconMask,SuperWeapon9_DIYSkill_SkillFrame2_Skill4_iconMask},
		{SuperWeapon9_DIYSkill_SkillFrame3_Skill1_iconMask,SuperWeapon9_DIYSkill_SkillFrame3_Skill2_iconMask,SuperWeapon9_DIYSkill_SkillFrame3_Skill3_iconMask,SuperWeapon9_DIYSkill_SkillFrame3_Skill4_iconMask},
	}
	
	g_SuperWeapon9_DIYSkill_UnifiedPosition = SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition");
	
	g_SuperWeapon9_DIYSkill_PageButton[1] = SuperWeapon9_DIYSkill_SelfEquip
	g_SuperWeapon9_DIYSkill_PageButton[2] = SuperWeapon9_DIYSkill_SelfData
	g_SuperWeapon9_DIYSkill_PageButton[3] = SuperWeapon9_DIYSkill_Pet
	g_SuperWeapon9_DIYSkill_PageButton[4] = SuperWeapon9_DIYSkill_Infant
	g_SuperWeapon9_DIYSkill_PageButton[5] = SuperWeapon9_DIYSkill_Wuhun
	g_SuperWeapon9_DIYSkill_PageButton[6] = SuperWeapon9_DIYSkill_Xiulian
	g_SuperWeapon9_DIYSkill_PageButton[7] = SuperWeapon9_DIYSkill_Miji
	g_SuperWeapon9_DIYSkill_PageButton[8] = SuperWeapon9_DIYSkill_ZhenYuan
	g_SuperWeapon9_DIYSkill_PageButton[9] = SuperWeapon9_DIYSkill_JingMai
	g_SuperWeapon9_DIYSkill_PageButton[10] = SuperWeapon9_DIYSkill_ShenDing
	g_SuperWeapon9_DIYSkill_PageButton[11] = SuperWeapon9_DIYSkill_JueWei
	g_SuperWeapon9_DIYSkill_PageButton[12] = SuperWeapon9_DIYSkill_BaoJian
	g_SuperWeapon9_DIYSkill_PageButton[13] = SuperWeapon9_DIYSkill_WuYi
	g_SuperWeapon9_DIYSkill_PageButton[14] = SuperWeapon9_DIYSkill_ShenQi
	g_SuperWeapon9_DIYSkill_PageButton[15] = SuperWeapon9_DIYSkill_Armor
	g_SuperWeapon9_DIYSkill_PageButton[16] = SuperWeapon9_DIYSkill_CangPin
	g_SuperWeapon9_DIYSkill_PageButton[17] = SuperWeapon9_DIYSkill_OtherInfo
	
	g_SuperWeapon9_DIYSkill_PageMask[1] = SuperWeapon9_DIYSkill_SelfEquip_tips
	g_SuperWeapon9_DIYSkill_PageMask[2] = SuperWeapon9_DIYSkill_SelfData_tips
	g_SuperWeapon9_DIYSkill_PageMask[3] = SuperWeapon9_DIYSkill_Pet_tips
	g_SuperWeapon9_DIYSkill_PageMask[4] = SuperWeapon9_DIYSkill_Infant_tips
	g_SuperWeapon9_DIYSkill_PageMask[5] = SuperWeapon9_DIYSkill_Wuhun_tips
	g_SuperWeapon9_DIYSkill_PageMask[6] = SuperWeapon9_DIYSkill_Xiulian_tips
	g_SuperWeapon9_DIYSkill_PageMask[7] = SuperWeapon9_DIYSkill_Miji_tips
	g_SuperWeapon9_DIYSkill_PageMask[8] = SuperWeapon9_DIYSkill_ZhenYuan_tips
	g_SuperWeapon9_DIYSkill_PageMask[9] = SuperWeapon9_DIYSkill_JingMai_tips
	g_SuperWeapon9_DIYSkill_PageMask[10] = SuperWeapon9_DIYSkill_ShenDing_tips
	g_SuperWeapon9_DIYSkill_PageMask[11] = SuperWeapon9_DIYSkill_JueWei_tips
	g_SuperWeapon9_DIYSkill_PageMask[12] = SuperWeapon9_DIYSkill_BaoJian_tips
	g_SuperWeapon9_DIYSkill_PageMask[13] = SuperWeapon9_DIYSkill_WuYi_tips
	g_SuperWeapon9_DIYSkill_PageMask[14] = SuperWeapon9_DIYSkill_ShenQi_tips
	g_SuperWeapon9_DIYSkill_PageMask[15] = SuperWeapon9_DIYSkill_Armor_tips
	g_SuperWeapon9_DIYSkill_PageMask[16] = SuperWeapon9_DIYSkill_CangPin_tips
	g_SuperWeapon9_DIYSkill_PageMask[17] = SuperWeapon9_DIYSkill_OtherInfo_tips
	
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

--**********************************
-- 神器DIY技能--OnEvent
--**********************************
function SuperWeapon9_DIYSkill_OnEvent(event)

	local objCared = DataPool:GetCurDialogNpcId();
	
	if event == "UI_COMMAND" then

		-- 打开界面
		if tonumber(arg0) == 89247101 then

			-- 关注npc
			--g_TargetServerID = Get_XParam_INT(0);
			--g_ObjCared = objCared
			--this:CareObject(objCared, 1, "SuperWeapon9_DIYSkill");
			
			SuperWeapon9_DIYSkill_OpenUI()
				
		-- 更新界面
		elseif tonumber(arg0) == 89247103 and this:IsVisible() then
		
			-- 更新类型
			if Get_XParam_INT(0) == 1 or  Get_XParam_INT(0) == 2 then							
				-- 更新技能效果页面
				if g_SuperWeapon9_DIYSkill_SlotIndex > 0 then				
					SuperWeapon9_DIYSkill_SkillUpdate()					
				end
			end	
			if DataPool:IsSuperWeapon9() == 1 or DataPool:IsSuperWeaponTopo() == 1 then
				--【九星神器引导任务】任务5 第3、4、5个tips显示
				if DataPool:Lua_IsHaveMission(1953) > 0 then
					local misIndex = DataPool:GetPlayerMissionIndexByID(1953)
					local Have_XiangQian = 0
					if DataPool:GetPlayerMission_Variable(misIndex, 1) == 1 then
						Have_XiangQian = 1
					end	
					local Have_TuoZhuai = 0
					if DataPool:GetPlayerMission_Variable(misIndex, 2) == 1 then
						Have_TuoZhuai = 1
					end			
					CloseFreshManGuide()
					--已激活，未镶嵌				
					if Have_XiangQian == 0 then
						local fX, fY = this:GetChildOffset("SuperWeapon9_DIYSkill_SkillFrame_buy")			
						OpenFreshManGuide(1, 177, fX+60, fY+60, "SuperWeapon9_DIYSkill", "southeast")
						SuperWeapon9_DIYSkill_MainFrame_Item_Animate:Play(false)
						SuperWeapon9_DIYSkill_MainFrame_Slot1_Animate:Play(false)
						SuperWeapon9_DIYSkill_SkillFrame_buy_Animate:Play(true)				
					--已激活，已镶嵌
					elseif Have_TuoZhuai == 0 then
						local fX, fY = this:GetChildOffset("SuperWeapon9_DIYSkill_MainFrame_Skill")			
						OpenFreshManGuide(1, 178, fX+48, fY, "SuperWeapon9_DIYSkill", "northeast")
						SuperWeapon9_DIYSkill_MainFrame_Item_Animate:Play(false)
						SuperWeapon9_DIYSkill_MainFrame_Slot1_Animate:Play(false)
						SuperWeapon9_DIYSkill_SkillFrame_buy_Animate:Play(false)
						SuperWeapon9_DIYSkill_MainFrame_Skill_Animate:Play(true)
					end
					
				end
			end
		end
		
	-- 打开界面
	--elseif event == "SUPERWEAPONDIYSKILL_OPENUI" then
	
		--SuperWeapon9_DIYSkill_OpenUI()
	
	-- 放入神器：右键或拖拽
	elseif event == "SUPERWEAPONDIYSKILL_PUTWEAPON" then
	
		if arg0 ~= nil then
			-- 更新神器	
			SuperWeapon9_DIYSkill_MainUpdataWeapon(tonumber(arg0))
			
			-- 默认显示技能效果A
			SuperWeapon9_DIYSkill_MainButtonSkill(1)
		end

	-- 神器拖出界面
	elseif event=="SUPERWEAPON9_DRAGEND" and this:IsVisible() then
	
		if arg0 ~= nil and tonumber(arg0)==21 then
			-- 界面重置
			SuperWeapon9_DIYSkill_MouseRClick()
		end
		
	-- 刷新装备的神器
	elseif event == "REFRESH_EQUIP" then
	
		if this:IsVisible() then
		
			-- 放入装备更新
			SuperWeapon9_DIYSkill_MainUpdataWeapon()
			
			-- 更新技能效果页面
			if g_SuperWeapon9_DIYSkill_SlotIndex > 0 then
				SuperWeapon9_DIYSkill_SkillUpdate()
			else
				-- 默认显示技能效果A
				SuperWeapon9_DIYSkill_MainButtonSkill(1)				
			end
			
		end
	
	-- 道具更新
	elseif event == "PACKAGE_ITEM_CHANGED_EX" and this:IsVisible() then
	
		-- 更新神器
		--if arg0 ~= nil and tonumber(arg0) == g_SuperWeapon9_DIYSkill_WeaponIndex then
		--	if g_SuperWeapon9_DIYSkill_SlotIndex > 0 then
		--		-- 更新神器插槽
		--		SuperWeapon9_DIYSkill_MainUpdateSlot(g_SuperWeapon9_DIYSkill_SlotIndex)
		--		-- 更新技能效果页面
		--		SuperWeapon9_DIYSkill_SkillUpdate()
		--	end
		--else	
			-- 更新道具数量
			--if g_SuperWeapon9_DIYSkill_SlotIndex > 0 then			
				SuperWeapon9_DIYSkill_MainUpdateItem()
			--end
		--end
		
	--elseif event == "OBJECT_CARED_EVENT" then

		--if(g_ObjCared ~= objCared) then
		--	return
		--end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		--if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
		--	this:Hide()
		--end

	elseif event == "ADJEST_UI_POS" then

		SuperWeapon9_DIYSkill_ResetWindowPos();
	
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SuperWeapon9_DIYSkill_ResetWindowPos()
	
	-- 更新页签tips
	elseif ( event == "UPDATE_WILLGET_MISSION_TRACK" ) or (event=="TOGGLE_UPDATE_INFANT")  or (event == "FINISH_MISSION") then

		local nLevel =Player:GetLevel()
		SuperWeapon9_DIYSkill_Refresh_Page_Button(nLevel)
		SuperWeapon9_DIYSkill_ShowPage()
		
	--【九星神器引导任务】任务5 第5个Tips关闭
	elseif event == "9START_TUO_SKILL" then 
		if DataPool:Lua_IsHaveMission(1953) > 0 then
			local misIndex = DataPool:GetPlayerMissionIndexByID(1953)
			if DataPool:GetPlayerMission_Variable(misIndex, 3) == 0 then
				CloseFreshManGuide()
				PushDebugMessage("#{JXYD_200916_106}")
				Clear_XSCRIPT()
					Set_XSCRIPT_Function_Name( "SetMissionParam" )
					Set_XSCRIPT_ScriptID(888240) --别忘了：AllowableScriptFunc.txt中加上这个接口和脚本号
					Set_XSCRIPT_ParamCount(0)
				Send_XSCRIPT()					
			end
		end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "SetMF" )
			Set_XSCRIPT_ScriptID(888240) --别忘了：AllowableScriptFunc.txt中加上这个接口和脚本号
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()		
	elseif(event == "MARTIAL_UPDATE" or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		SuperWeapon9_DIYSkill_RefreshWuYiTip()
	end

	if event == "UPDATE_TOY_TIP" then
		SuperWeapon9_DIYSkill_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		SuperWeapon9_DIYSkill_RefreshCangPinTip()
	end
end

--**********************************
-- 神器DIY技能--打开界面
--**********************************
function SuperWeapon9_DIYSkill_OpenUI()

 	-- 显示界面
	this:Show()
	
	-- 界面重置
	SuperWeapon9_DIYSkill_MainReset()
	
	-- 更新神器	
	SuperWeapon9_DIYSkill_MainUpdataWeapon()
	
	-- 显示道具数量
	SuperWeapon9_DIYSkill_MainUpdateItem()
	
	-- 默认显示技能效果A
	SuperWeapon9_DIYSkill_MainButtonSkill(1)
	
	-- 页签选中神器
	local nUIPos = Variable:GetVariable( "SelfUnionPos" );
	SuperWeapon9_DIYSkill_Frame:SetProperty( "UnifiedPosition", nUIPos );
	g_SuperWeapon9_DIYSkill_UnifiedPosition = SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition");
	SuperWeapon9_DIYSkill_ShenQi:SetCheck(1)

	-- 更新页签tips	
	local nLevel =Player:GetLevel()
	SuperWeapon9_DIYSkill_Refresh_Page_Button(nLevel)
	SuperWeapon9_DIYSkill_ShowPage()
	 
end

--**********************************
-- 神器DIY技能--重置位置
--**********************************
function SuperWeapon9_DIYSkill_ResetWindowPos()

	 SuperWeapon9_DIYSkill_Frame:SetProperty("UnifiedPosition", g_SuperWeapon9_DIYSkill_UnifiedPosition);
	 
end

--**********************************
-- 神器DIY技能--主界面清空
--**********************************
function SuperWeapon9_DIYSkill_MainReset()

	-- 神器清空
	SuperWeapon9_DIYSkill_MainResumeWeapon()
	
	-- 技能清空
	SuperWeapon9_DIYSkill_MainResumeSkill()
	
	-- 插槽清空
	g_SuperWeapon9_DIYSkill_SlotIndex = 0
	for nIndex=1, g_SuperWeapon9_DIYSkill_SlotNum do
		SuperWeapon9_DIYSkill_MainResumeSlot(nIndex)
		-- 选中清空
		g_SuperWeapon9_DIYSkill_SlotSelect[nIndex]:Hide()
	end
	
end

--**********************************
-- 神器DIY技能--武器清空
--**********************************
function SuperWeapon9_DIYSkill_MainResumeWeapon()

	--if g_SuperWeapon9_DIYSkill_WeaponIndex >= 0 then
	
		--LifeAbility : Lock_Packet_Item(g_SuperWeapon9_DIYSkill_WeaponIndex, 0)
		-- 物品描述
		g_SuperWeapon9_DIYSkill_WeaponText:SetText("#{JXSQ_170829_234}")
		-- 道具栏
		g_SuperWeapon9_DIYSkill_WeaponSlot:SetActionItem(-1)
		--g_SuperWeapon9_DIYSkill_WeaponSlot:SetProperty("NormalImage", "")
		--g_SuperWeapon9_DIYSkill_WeaponSlot:SetToolTip("#JXSQ_170829_222}")
		g_SuperWeapon9_DIYSkill_WeaponIndex = -1;
		-- 蒙红
		g_SuperWeapon9_DIYSkill_WeaponMask:Show()
		
	--end
	
end

--**********************************
-- 神器DIY技能--技能清空
--**********************************
function SuperWeapon9_DIYSkill_MainResumeSkill()

	g_SuperWeapon9_DIYSkill_SkillSlot:SetActionItem(-1)
	g_SuperWeapon9_DIYSkill_SkillMask:Show()
	g_SuperWeapon9_DIYSkill_SkillText:SetText("#{JXSQ_170829_241}")
	
end

--**********************************
-- 神器DIY技能--插槽清空
--**********************************
function SuperWeapon9_DIYSkill_MainResumeSlot(nIndex)

	if nIndex == nil or nIndex <= 0 or nIndex > g_SuperWeapon9_DIYSkill_SlotNum then
		return
	end
	
	-- 等级信息隐藏
	g_SuperWeapon9_DIYSkill_SlotLevel[nIndex]:Hide()
	-- 名称信息隐藏
	--g_SuperWeapon9_DIYSkill_SlotSkill[nIndex]:Hide()
	-- 技能效果框
	g_SuperWeapon9_DIYSkill_SlotButton[nIndex]:SetProperty("NormalImage", "")
	g_SuperWeapon9_DIYSkill_SlotButton[nIndex]:SetToolTip("")
	
	-- 插槽未解锁
	g_SuperWeapon9_DIYSkill_SlotImage[nIndex]:Show()
	-- 显示解锁信息
	g_SuperWeapon9_DIYSkill_SlotLock[nIndex]:Show()
	if g_SuperWeapon9_DIYSkill_WeaponIndex < 0 then
		g_SuperWeapon9_DIYSkill_SlotLock[nIndex]:SetText("#{JXSQ_170829_241}")
	elseif DataPool:IsSuperWeapon9() ~= 1 and DataPool:IsSuperWeaponTopo() ~= 1 then
		g_SuperWeapon9_DIYSkill_SlotLock[nIndex]:SetText("#{JXSQ_170829_240}")
	else
		g_SuperWeapon9_DIYSkill_SlotLock[nIndex]:SetText(g_SuperWeapon9_DIYSkill_Data[nIndex].lockText)
	end
	-- 升级按钮禁用
	g_SuperWeapon9_DIYSkill_SlotLevelup[nIndex]:Disable()
	
end
	
--**********************************
-- 神器DIY技能--关闭
--**********************************
function SuperWeapon9_DIYSkill_MainButtonClose()

	-- 主页面清空
	SuperWeapon9_DIYSkill_MainReset()
	-- 效果页面清空
	SuperWeapon9_DIYSkill_SkillReset()
	
	-- 取消关注
	--this:CareObject(g_ObjCared, 0, "SuperWeapon9_DIYSkill");
	--g_ObjCared = -1;
	--g_TargetServerID = -1;
	
	CloseFreshManGuide() --【九星神器引导任务】任务5
	
	-- 隐藏界面
	--this:Hide()
	
end
	
--**********************************
-- 神器DIY技能--未放入神器默认状态
--**********************************
function SuperWeapon9_DIYSkill_MouseRClick()

	-- 主页面清空
	SuperWeapon9_DIYSkill_MainReset()

	-- 默认显示技能效果A
	SuperWeapon9_DIYSkill_MainButtonSkill(1)
	
end

--**********************************
-- 神器DIY技能--更新神器插槽
--**********************************
function SuperWeapon9_DIYSkill_MainUpdataWeapon(itemIdx)
	
	--【九星神器引导任务】任务5 先把高亮都关掉
	SuperWeapon9_DIYSkill_MainFrame_Item_Animate:Play(false)
	SuperWeapon9_DIYSkill_MainFrame_Slot1_Animate:Play(false)
	SuperWeapon9_DIYSkill_SkillFrame_Skill1_Animate:Play(false)
	SuperWeapon9_DIYSkill_SkillFrame_buy_Animate:Play(false)
	SuperWeapon9_DIYSkill_MainFrame_Skill_Animate:Play(false)
	
	--【九星神器引导任务】任务7
	SuperWeapon9_DIYSkill_MainFrame_Slot1_LevelUp_Animate:Play(false) --test
	
	--local theAction = EnumAction(itemIdx, "packageitem");
	local theAction	= EnumAction(0, "equip");
	if theAction:GetID() ~= 0 then
	
		-- 当前装备是否102级八星突破神器或者九星神器
		if DataPool:IsSuperWeapon9() ~= 1 and DataPool:IsSuperWeaponTopo() ~= 1 then
			-- 界面重置
			--SuperWeapon9_DIYSkill_MouseRClick()
			-- 醒目提示
			--PushDebugMessage("#{JXSQ_170804_83}")	--102级八星神器和九星神器可进行技能配置
			--【九星神器引导任务】任务5 第1个tips显示：没有装备，就弹这个
			if DataPool:Lua_IsHaveMission(1953) > 0 then	
				CloseFreshManGuide()
				local fX, fY = this:GetChildOffset("SuperWeapon9_DIYSkill_MainFrame_Item")			
				OpenFreshManGuide(1, 174, fX+48, fY, "SuperWeapon9_DIYSkill", "northeast")
				SuperWeapon9_DIYSkill_MainFrame_Item_Animate:Play(true)
			end
			
			--【九星神器引导任务】任务7 第1个tips显示：没有装备，就弹这个
			if DataPool:Lua_IsHaveMission(1954) > 0 then
				local misIndex = DataPool:GetPlayerMissionIndexByID(1954)
				local Finish = DataPool:GetPlayerMission_Variable(misIndex, 0)
				if Finish ~= 1 then
					CloseFreshManGuide()
					local fX, fY = this:GetChildOffset("SuperWeapon9_DIYSkill_MainFrame_Item")			
					OpenFreshManGuide(1, 174, fX+48, fY, "SuperWeapon9_DIYSkill", "northeast")
					SuperWeapon9_DIYSkill_MainFrame_Item_Animate:Play(true)
				end
			end			
			
			--return
		end
		
		if g_SuperWeapon9_DIYSkill_WeaponIndex >= 0 then
			--LifeAbility : Lock_Packet_Item(g_SuperWeapon9_DIYSkill_WeaponIndex,0);
		end

		--local nEquipIndex = theAction:GetDefineID()
		--local icon =  tostring(LifeAbility : Get_Item_Icon_NameByDataIndex(nEquipIndex))
		--g_SuperWeapon9_DIYSkill_WeaponSlot:SetProperty("NormalImage", icon)
		--g_SuperWeapon9_DIYSkill_WeaponSlot:SetToolTip("#{JXSQ_170829_218}")
		g_SuperWeapon9_DIYSkill_WeaponSlot:SetActionItem(theAction:GetID());
		--LifeAbility : Lock_Packet_Item(itemIdx,1);
		--g_SuperWeapon9_DIYSkill_WeaponIndex = itemIdx
		g_SuperWeapon9_DIYSkill_WeaponIndex = 0
		-- 九星
		if DataPool:IsSuperWeapon9() == 1 then
			-- 物品描述
			local EquipName = PlayerPackage:GetEquipBagItemName(0)
			g_SuperWeapon9_DIYSkill_WeaponText:SetText(ScriptGlobal_Format("#{JXSQ_170829_237}", EquipName))
			-- 蒙红
			g_SuperWeapon9_DIYSkill_WeaponMask:Hide()
		-- 八星突破
		elseif DataPool:IsSuperWeaponTopo() == 1 then
			-- 物品描述
			local EquipName = PlayerPackage:GetEquipBagItemName(0)
			local nByQual = tonumber(PlayerPackage:GetEquipSuperWeaponQual(0))
			if nByQual>100 then
				local nFit = math.mod(nByQual,100)
				if nFit>=1 and nFit<=20 then
					g_SuperWeapon9_DIYSkill_WeaponText:SetText(ScriptGlobal_Format("#{JXSQ_170829_236}", EquipName, nFit))
				end
			end
			-- 蒙红
			g_SuperWeapon9_DIYSkill_WeaponMask:Hide()
		-- 非神器
		else
			-- 物品描述
			g_SuperWeapon9_DIYSkill_WeaponText:SetText("#{JXSQ_170829_235}")
			-- 蒙红
			g_SuperWeapon9_DIYSkill_WeaponMask:Show()
		end
		
		-- 更新技能
		SuperWeapon9_DIYSkill_MainUpdateSkill()
		--SuperWeapon9_DIYSkill_MainUpdateSkill(theAction:GetItemID())
		
		-- 更新插槽
		SuperWeapon9_DIYSkill_MainUpdateSlots()
		
		if DataPool:IsSuperWeapon9() == 1 or DataPool:IsSuperWeaponTopo() == 1 then
			--【九星神器引导任务】任务5 第3、4、5个tips显示
			if DataPool:Lua_IsHaveMission(1953) > 0 then
				local misIndex = DataPool:GetPlayerMissionIndexByID(1953)
				local Have_XiangQian = 0
				if DataPool:GetPlayerMission_Variable(misIndex, 1) == 1 then
					Have_XiangQian = 1
				end	
				local Have_TuoZhuai = 0
				if DataPool:GetPlayerMission_Variable(misIndex, 2) == 1 then
					Have_TuoZhuai = 1
				end			
				CloseFreshManGuide()
				--已激活，未镶嵌				
				if Have_XiangQian == 0 then
					local fX, fY = this:GetChildOffset("SuperWeapon9_DIYSkill_SkillFrame_buy")			
					OpenFreshManGuide(1, 177, fX+60, fY+60, "SuperWeapon9_DIYSkill", "southeast")
					SuperWeapon9_DIYSkill_MainFrame_Item_Animate:Play(false)
					SuperWeapon9_DIYSkill_MainFrame_Slot1_Animate:Play(false)
					SuperWeapon9_DIYSkill_SkillFrame_buy_Animate:Play(true)				
				--已激活，已镶嵌
				elseif Have_TuoZhuai == 0 then
					local fX, fY = this:GetChildOffset("SuperWeapon9_DIYSkill_MainFrame_Skill")			
					OpenFreshManGuide(1, 178, fX+48, fY, "SuperWeapon9_DIYSkill", "northeast")
					SuperWeapon9_DIYSkill_MainFrame_Item_Animate:Play(false)
					SuperWeapon9_DIYSkill_MainFrame_Slot1_Animate:Play(false)
					SuperWeapon9_DIYSkill_SkillFrame_buy_Animate:Play(false)
					SuperWeapon9_DIYSkill_MainFrame_Skill_Animate:Play(true)
				end
			end
			

			--【九星神器引导任务】任务7 Tips2显示
			if DataPool:Lua_IsHaveMission(1954) > 0 then
				local misIndex = DataPool:GetPlayerMissionIndexByID(1954)
				local Finish = DataPool:GetPlayerMission_Variable(misIndex, 0)
				if Finish ~= 1 then
					CloseFreshManGuide()
					local fX, fY = this:GetChildOffset("SuperWeapon9_DIYSkill_MainFrame_Slot1_LevelUp")			
					OpenFreshManGuide(1, 179, fX+20, fY, "SuperWeapon9_DIYSkill", "northeast")
					SuperWeapon9_DIYSkill_MainFrame_Item_Animate:Play(false)
					SuperWeapon9_DIYSkill_MainFrame_Slot1_LevelUp_Animate:Play(true) --test
				end
			end		
		end
	else
		
		-- 界面重置
		SuperWeapon9_DIYSkill_MouseRClick()
		-- 醒目提示
		--PushDebugMessage("#{JXSQ_170804_83}")	--102级八星神器和九星神器可进行技能配置

		--【九星神器引导任务】任务5 第1个tips显示：没有装备，就弹这个
		if DataPool:Lua_IsHaveMission(1953) > 0 then
			local misIndex = DataPool:GetPlayerMissionIndexByID(1953)
			local Finish = DataPool:GetPlayerMission_Variable(misIndex, 0)
			if Finish ~= 1 then
				CloseFreshManGuide()
				local fX, fY = this:GetChildOffset("SuperWeapon9_DIYSkill_MainFrame_Item")			
				OpenFreshManGuide(1, 174, fX+48, fY, "SuperWeapon9_DIYSkill", "northeast")
				SuperWeapon9_DIYSkill_MainFrame_Item_Animate:Play(true)
			end
		end	
		--【九星神器引导任务】任务7 第1个tips显示：没有装备，就弹这个
		if DataPool:Lua_IsHaveMission(1954) > 0 then	
			local misIndex = DataPool:GetPlayerMissionIndexByID(1954)
			local Finish = DataPool:GetPlayerMission_Variable(misIndex, 0)
			if Finish ~= 1 then
				CloseFreshManGuide()
				local fX, fY = this:GetChildOffset("SuperWeapon9_DIYSkill_MainFrame_Item")			
				OpenFreshManGuide(1, 174, fX+48, fY, "SuperWeapon9_DIYSkill", "northeast")
				SuperWeapon9_DIYSkill_MainFrame_Item_Animate:Play(true)
			end
		end			
	end	
	
end

--**********************************
-- 神器DIY技能--更新主动技能插槽
--**********************************
function SuperWeapon9_DIYSkill_MainUpdateSkill(itemID)

	-- 技能清空
	SuperWeapon9_DIYSkill_MainResumeSkill()
	
	-- 未装入神器
	if g_SuperWeapon9_DIYSkill_WeaponIndex < 0 then
		return
	end	
	--if itemID == nil or itemID < 0 then
	--	return
	--end

	-- 如果有武器则显示默认技能说明
	g_SuperWeapon9_DIYSkill_SkillText:SetText("#{JXSQ_170829_240}")
	
	--未激活主动技能
	local nSkillId = DataPool:GetSuperWeaponDIYSkillId()
	if nSkillId == nil or nSkillId <= 0 then
		return
	end
	
	-- 设置主动技能框
	local nSumSkill = GetActionNum("skill");
	for i=1, nSumSkill do
		theAction = EnumAction(i-1, "skill");
		if theAction:GetDefineID() == nSkillId then
			g_SuperWeapon9_DIYSkill_SkillSlot:SetActionItem(theAction:GetID());
			g_SuperWeapon9_DIYSkill_SkillMask:Hide()
			-- 技能说明
			g_SuperWeapon9_DIYSkill_SkillText:SetText("#{JXSQ_170829_239}")

--			-- 根据插槽1是否解锁决定客户端是否可以拖拽技能--特写
--			local slotLevel = DataPool:GetSuperWeaponDIYSkillSlotLevel(1)
--			if slotLevel ~= nil and slotLevel > 0 then
--				-- 激活可以拖拽
--				g_SuperWeapon9_DIYSkill_SkillSlot:SetProperty("DraggingEnabled","True")
--				g_SuperWeapon9_DIYSkill_SkillMask:Hide()
--			else
--				-- 默认蒙红 不允许拖拽
--				g_SuperWeapon9_DIYSkill_SkillSlot:SetProperty("DraggingEnabled","False")
--				g_SuperWeapon9_DIYSkill_SkillMask:Show()
--			end
		end
	end
	
	-- 获得神器技能
	--local theActionSkill = EnumAction(itemID , "superweapondiyskill");
	--if theActionSkill:GetID() ~= 0 and nSkillId == theActionSkill:GetDefineID() then
	--	g_SuperWeapon9_DIYSkill_SkillSlot:SetActionItem(theActionSkill:GetID());
	--	-- 根据插槽1是否解锁决定客户端是否可以使用技能--特写
	--	local slotLevel = DataPool:GetSuperWeaponDIYSkillSlotLevel(1)
	--	if slotLevel ~= nil and slotLevel > 0 then
	--		-- 技能可用
	--		g_SuperWeapon9_DIYSkill_SkillMask:Hide()
	--	else
	--		-- 技能不可用
	--		g_SuperWeapon9_DIYSkill_SkillMask:Show()
	--	end
	--end

end

--**********************************
-- 神器DIY技能--更新主动技能插槽
--**********************************
function SuperWeapon9_DIYSkill_MainUpdateSlots()
	-- 插槽清空
	--g_SuperWeapon9_DIYSkill_SlotIndex = 0
	for nIndex=1, g_SuperWeapon9_DIYSkill_SlotNum do		
		SuperWeapon9_DIYSkill_MainResumeSlot(nIndex)
	end
		
	-- 未装入神器
	if g_SuperWeapon9_DIYSkill_WeaponIndex < 0 then
		return
	end
	
	-- 更新插槽
	for nIndex=1, g_SuperWeapon9_DIYSkill_SlotNum do			
		SuperWeapon9_DIYSkill_MainUpdateSlot(nIndex)
	end
	
end

--**********************************
-- 神器DIY技能--更新主动技能插槽
--**********************************
function SuperWeapon9_DIYSkill_MainUpdateSlot(nIndex)

	-- 未放入神器
	if g_SuperWeapon9_DIYSkill_WeaponIndex < 0 then
		return
	end
	
	-- 参数不对
	if nIndex == nil or nIndex <= 0 or nIndex > g_SuperWeapon9_DIYSkill_SlotNum then
		return
	end
	
	-- 获得当前插槽的等级
	local slotLevel = DataPool:GetSuperWeaponDIYSkillSlotLevel(nIndex)
	if slotLevel == nil or slotLevel < 0 then
		return
	end
	
	-- 未解锁
	if slotLevel == 0 then
		return
	end
	
	-- 下面是已解锁的显示~~~
	
	-- 升级按钮启用
	g_SuperWeapon9_DIYSkill_SlotLevelup[nIndex]:Enable()
	if slotLevel >= g_SuperWeapon9_DIYSkill_SlotLevelLimit then--已满级
		g_SuperWeapon9_DIYSkill_SlotLevelup[nIndex]:SetToolTip("#{JXSQ_170829_208}")
	else
		local nCostNum, nCostMoney = DataPool:GetSuperWeaponDIYSkillLevelupData(slotLevel, nIndex)
		if nCostNum ~= nil and nCostNum > 0 then
			local nItemId = g_SuperWeapon9_DIYSkill_Data[nIndex].itemId
			local itemName = PlayerPackage:GetItemName(nItemId)
			g_SuperWeapon9_DIYSkill_SlotLevelup[nIndex]:SetToolTip(ScriptGlobal_Format(g_SuperWeapon9_DIYSkill_Data[nIndex].levelTip, nCostNum))
		else
			g_SuperWeapon9_DIYSkill_SlotLevelup[nIndex]:SetToolTip("")
		end
	end

	-- 插槽解锁
	g_SuperWeapon9_DIYSkill_SlotImage[nIndex]:Hide()
	
	-- 隐藏解锁信息
	g_SuperWeapon9_DIYSkill_SlotLock[nIndex]:Hide()	
	
	-- 等级信息显示
	g_SuperWeapon9_DIYSkill_SlotLevel[nIndex]:Show()
	g_SuperWeapon9_DIYSkill_SlotLevel[nIndex]:SetText(ScriptGlobal_Format("#{JXSQ_170804_73}", slotLevel))
	
	-- 名称信息显示
	--g_SuperWeapon9_DIYSkill_SlotSkill[nIndex]:SetText("")
	
	-- 技能效果显示
	g_SuperWeapon9_DIYSkill_SlotButton[nIndex]:SetProperty("NormalImage", "")
	local tip = ScriptGlobal_Format("#{JXSQ_170804_74}", g_SuperWeapon9_DIYSkill_Data[nIndex].nameText)
	g_SuperWeapon9_DIYSkill_SlotButton[nIndex]:SetToolTip(tip)
	
	-- 获得当前插槽技能
	local impactIndex = DataPool:GetSuperWeaponDIYSkillImpactIndex(nIndex)
	if impactIndex == nil or impactIndex <= 0 then
		return
	end	
	local slotType, nCostNum, nSkillId = DataPool:GetSuperWeaponDIYSkillActiveData(impactIndex)
	if nCostNum == nil or nCostNum < 0 or nSkillId == nil or nSkillId <= 0 then
		return
	end	
	
	-- 名称信息显示
	--g_SuperWeapon9_DIYSkill_SlotSkill[nIndex]:Show()
	--local bRet,skillName = DataPool:GetSkillName(nSkillId)
	--if bRet == 1 then
		-- 判断技能效果激活状态
		--local bActive = 1--Pneuma:GetMF(g_SuperWeapon9_DIYSkill_ImpactMFBegin+impactIndex-1)
		--if bActive == nil or bActive ~= 1 then
		--	g_SuperWeapon9_DIYSkill_SlotSkill[nIndex]:SetText(""..skillName.."#{JXSQ_170828_199}")
		--else
			--g_SuperWeapon9_DIYSkill_SlotSkill[nIndex]:SetText(skillName)
		--end
	--end
	
	-- 技能效果框
	local bRet1,skillName = DataPool:GetSkillName(nSkillId)
	local bRet,iconName = DataPool:GetSkillIconName(nSkillId)
	if bRet == 1 and bRet1 == 1 then
		local curIcon = GetIconFullName(iconName)
		g_SuperWeapon9_DIYSkill_SlotButton[nIndex]:SetProperty("NormalImage", curIcon)
		local bRetDesc,strDesc = DataPool:GetSuperWeaponDIYSkillDesc(nSkillId, slotLevel)
		if bRetDesc == 1 then		
			g_SuperWeapon9_DIYSkill_SlotButton[nIndex]:SetToolTip(skillName.."#r"..strDesc)
		end
	end
	
end

--**********************************
-- 神器DIY技能--更新道具数量
--**********************************
function SuperWeapon9_DIYSkill_MainUpdateItem()
		
	for nIndex=1,g_SuperWeapon9_DIYSkill_SlotNum do
		
		-- 拥有道具
		local itemId = g_SuperWeapon9_DIYSkill_Data[nIndex].itemId
		local bindId = g_SuperWeapon9_DIYSkill_Data[nIndex].bindId
		local itemNum = PlayerPackage:CountAvailableItemByIDTable(itemId)
		local bindNum = PlayerPackage:CountAvailableItemByIDTable(bindId)
		local strNum = ScriptGlobal_Format(g_SuperWeapon9_DIYSkill_Data[nIndex].itemText, itemNum+bindNum)
		g_SuperWeapon9_DIYSkill_ImpactItem[nIndex]:SetText(strNum)
		g_SuperWeapon9_DIYSkill_ImpactItem[nIndex]:SetToolTip(g_SuperWeapon9_DIYSkill_Data[nIndex].itemTip)
		
		-- 道具数量不足时显示红色
		local slotLevel = DataPool:GetSuperWeaponDIYSkillSlotLevel(nIndex)
		if slotLevel == nil or slotLevel <= 0 then
			local strNumRed = ScriptGlobal_Format(g_SuperWeapon9_DIYSkill_Data[nIndex].itemTextRed, itemNum+bindNum)
			g_SuperWeapon9_DIYSkill_ImpactItem[nIndex]:SetText(strNumRed)
		elseif slotLevel > 0 and slotLevel < g_SuperWeapon9_DIYSkill_SlotLevelLimit then
			local nCostNum, nCostMoney = DataPool:GetSuperWeaponDIYSkillLevelupData(slotLevel, nIndex)
			if nCostNum ~= nil and nCostNum > 0 and nCostNum > itemNum+bindNum then
				local strNumRed = ScriptGlobal_Format(g_SuperWeapon9_DIYSkill_Data[nIndex].itemTextRed, itemNum+bindNum)
				g_SuperWeapon9_DIYSkill_ImpactItem[nIndex]:SetText(strNumRed)
			end
		end		

	end
	
end

--**********************************
-- 神器DIY技能--插槽升级
--**********************************
function SuperWeapon9_DIYSkill_MainButtonLevelUp(nIndex)

	if nIndex == nil or nIndex <= 0 or nIndex > g_SuperWeapon9_DIYSkill_SlotNum then
		return
	end
	
	-- 未放入神器
	if g_SuperWeapon9_DIYSkill_WeaponIndex < 0 then
		PushDebugMessage("#{JXSQ_170804_86}")
		return
	end	
	
	-- 打开升级界面同时刷新右侧技能效果列表
	if g_SuperWeapon9_DIYSkill_SlotIndex ~= nIndex then
		SuperWeapon9_DIYSkill_MainButtonSkill( nIndex )
	end
	
	-- 插槽升级
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_LevelupSlot")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_Parameter(0, g_TargetServerID)
		Set_XSCRIPT_Parameter(1, g_SuperWeapon9_DIYSkill_WeaponIndex)
		Set_XSCRIPT_Parameter(2, nIndex)
		Set_XSCRIPT_Parameter(3, 0)
		Set_XSCRIPT_ParamCount(4)
	Send_XSCRIPT()
	
	--【九星神器引导任务】任务7 Tips2显示
	if DataPool:Lua_IsHaveMission(1954) > 0 then
		CloseFreshManGuide()		
	end		
end

--**********************************
-- 神器DIY技能--插槽选中
--**********************************
function SuperWeapon9_DIYSkill_MainButtonSkill(nIndex)

	--【九星神器引导任务】任务5 先把高亮都关掉
	-- SuperWeapon9_DIYSkill_MainFrame_Item_Animate:Play(false)
	-- SuperWeapon9_DIYSkill_MainFrame_Slot1_Animate:Play(false)
	-- SuperWeapon9_DIYSkill_SkillFrame_Skill1_Animate:Play(false)
	-- SuperWeapon9_DIYSkill_SkillFrame_buy_Animate:Play(false)
	-- SuperWeapon9_DIYSkill_MainFrame_Skill_Animate:Play(false)
	
	if nIndex == nil or nIndex <= 0 or nIndex > g_SuperWeapon9_DIYSkill_SlotNum then
		return
	end
	
	-- 重复点击同一个插槽则不再刷新，如果想重刷可以把g_SuperWeapon9_DIYSkill_SlotIndex重置
	if g_SuperWeapon9_DIYSkill_SlotIndex == nIndex then
		return			 
	end
	
	-- 删除上次选中状态
	if g_SuperWeapon9_DIYSkill_SlotIndex > 0 and g_SuperWeapon9_DIYSkill_SlotIndex <= g_SuperWeapon9_DIYSkill_SlotNum then
		g_SuperWeapon9_DIYSkill_SlotSelect[g_SuperWeapon9_DIYSkill_SlotIndex]:Hide()
	end
	
	-- 记录当前选中的插槽
	g_SuperWeapon9_DIYSkill_SlotIndex = nIndex
	g_SuperWeapon9_DIYSkill_SlotSelect[g_SuperWeapon9_DIYSkill_SlotIndex]:Show()
	
	-- 刷新界面内容
	g_SuperWeapon9_DIYSkill_ImpactIndex = 0--切换技能效果页时要清除选中项
	SuperWeapon9_DIYSkill_SkillUpdate()
	
	--【九星神器引导任务】任务5 第1、2、3、4、5个tips显示
	if DataPool:Lua_IsHaveMission(1953) > 0 then
		local misIndex = DataPool:GetPlayerMissionIndexByID(1953)
		local Finish = DataPool:GetPlayerMission_Variable(misIndex, 0)
		if Finish ~= 1 then
		
			if DataPool:IsSuperWeapon9() ~= 1 and DataPool:IsSuperWeaponTopo() ~= 1 then
				if DataPool:Lua_IsHaveMission(1953) > 0 then	
					CloseFreshManGuide()
					local fX, fY = this:GetChildOffset("SuperWeapon9_DIYSkill_MainFrame_Item")			
					OpenFreshManGuide(1, 174, fX+48, fY, "SuperWeapon9_DIYSkill", "northeast")
					SuperWeapon9_DIYSkill_MainFrame_Item_Animate:Play(true)
				end	
			else
				if nIndex ~= 1 then
					CloseFreshManGuide()
					local fX, fY = this:GetChildOffset("SuperWeapon9_DIYSkill_MainFrame_Slot1_Skill")			
					OpenFreshManGuide(1, 175, fX+24, fY, "SuperWeapon9_DIYSkill", "northeast")
					SuperWeapon9_DIYSkill_MainFrame_Item_Animate:Play(false)
					SuperWeapon9_DIYSkill_MainFrame_Slot1_Animate:Play(true)
					SuperWeapon9_DIYSkill_SkillFrame_buy_Animate:Play(false)
					PushDebugMessage("#{JXYD_200916_102}")
				else
					if DataPool:Lua_IsHaveMission(1953) > 0 then	
						local misIndex = DataPool:GetPlayerMissionIndexByID(1953)
						local Have_XiangQian = 0
						if DataPool:GetPlayerMission_Variable(misIndex, 1) == 1 then
							Have_XiangQian = 1
						end	
						local Have_TuoZhuai = 0
						if DataPool:GetPlayerMission_Variable(misIndex, 2) == 1 then
							Have_TuoZhuai = 1
						end			
						CloseFreshManGuide()
						--已激活，未镶嵌				
						if Have_XiangQian == 0 then
							local fX, fY = this:GetChildOffset("SuperWeapon9_DIYSkill_SkillFrame_buy")			
							OpenFreshManGuide(1, 177, fX+60, fY+60, "SuperWeapon9_DIYSkill", "southeast")
							SuperWeapon9_DIYSkill_MainFrame_Item_Animate:Play(false)
							SuperWeapon9_DIYSkill_MainFrame_Slot1_Animate:Play(false)
							SuperWeapon9_DIYSkill_SkillFrame_buy_Animate:Play(true)				
						--已激活，已镶嵌
						elseif Have_TuoZhuai == 0 then
							local fX, fY = this:GetChildOffset("SuperWeapon9_DIYSkill_MainFrame_Skill")			
							OpenFreshManGuide(1, 178, fX+48, fY, "SuperWeapon9_DIYSkill", "northeast")
							SuperWeapon9_DIYSkill_MainFrame_Item_Animate:Play(false)
							SuperWeapon9_DIYSkill_MainFrame_Slot1_Animate:Play(false)
							SuperWeapon9_DIYSkill_SkillFrame_buy_Animate:Play(false)
							SuperWeapon9_DIYSkill_MainFrame_Skill_Animate:Play(true)
						end
					end
				end				
			end
		end			
	end			

end

--**********************************
-- 神器DIY技能--具体效果页面--清空
--**********************************
function SuperWeapon9_DIYSkill_SkillReset()

	-- 标题
	g_SuperWeapon9_DIYSkill_ImpactTitle:SetText("")	

	-- 确认按钮
	--g_SuperWeapon9_DIYSkill_ImpactButton:SetText("")
	--g_SuperWeapon9_DIYSkill_ImpactButton:SetToolTip("")
	
	-- 效果名称
	g_SuperWeapon9_DIYSkill_ImpactName:SetText("")
	-- 效果描述
	g_SuperWeapon9_DIYSkill_ImpactIntro:SetText("")
	-- 效果消耗
	--g_SuperWeapon9_DIYSkill_ImpactCost:SetText("")
	
	-- 效果图标背景
	for nSlotIndex=1, g_SuperWeapon9_DIYSkill_SlotNum do
		g_SuperWeapon9_DIYSkill_ImpactBK[nSlotIndex]:Hide()
	end
	
	-- 效果列表数值
	for nIndex=1, g_SuperWeapon9_DIYSkill_ImpactNum do	
		g_SuperWeapon9_DIYSkill_ImpactId[nIndex] = 0		
	end
	
	-- 变量
	g_SuperWeapon9_DIYSkill_SlotIndex = 0 
	g_SuperWeapon9_DIYSkill_ImpactIndex = 0
	g_SuperWeapon9_DIYSkill_EmbedImpactId = 0
	
end

--**********************************
-- 神器DIY技能--具体效果页面--效果清空
--**********************************
function SuperWeapon9_DIYSkill_SkillResumeImpact(nIndex)

	if g_SuperWeapon9_DIYSkill_SlotIndex <= 0 or g_SuperWeapon9_DIYSkill_SlotIndex > g_SuperWeapon9_DIYSkill_SlotNum then
		return
	end
		
	if nIndex == nil or nIndex <= 0 or nIndex > g_SuperWeapon9_DIYSkill_ImpactNum then
		return 
	end
	
	-- 效果
	g_SuperWeapon9_DIYSkill_ImpactIcon[g_SuperWeapon9_DIYSkill_SlotIndex][nIndex]:SetProperty("NormalImage", "")
	g_SuperWeapon9_DIYSkill_ImpactIcon[g_SuperWeapon9_DIYSkill_SlotIndex][nIndex]:SetToolTip("")
	g_SuperWeapon9_DIYSkill_ImpactAnimate[g_SuperWeapon9_DIYSkill_SlotIndex][nIndex]:Hide()
	g_SuperWeapon9_DIYSkill_ImpactMask[g_SuperWeapon9_DIYSkill_SlotIndex][nIndex]:Hide()

end

--**********************************
-- 神器DIY技能--具体效果页面--更新
--**********************************
function SuperWeapon9_DIYSkill_SkillUpdate()

	if g_SuperWeapon9_DIYSkill_SlotIndex <= 0 or g_SuperWeapon9_DIYSkill_SlotIndex > g_SuperWeapon9_DIYSkill_SlotNum then
		return
	end
	
	-- 标题
	g_SuperWeapon9_DIYSkill_ImpactTitle:SetText(g_SuperWeapon9_DIYSkill_Data[g_SuperWeapon9_DIYSkill_SlotIndex].title)

	-- 隐藏背景图
	for nSlotIndex=1, g_SuperWeapon9_DIYSkill_SlotNum do	
		g_SuperWeapon9_DIYSkill_ImpactBK[nSlotIndex]:Hide()
	end	
	 
	-- 效果框清空
	g_SuperWeapon9_DIYSkill_ImpactBK[g_SuperWeapon9_DIYSkill_SlotIndex]:Show()
	for nIndex=1, g_SuperWeapon9_DIYSkill_ImpactNum do
		SuperWeapon9_DIYSkill_SkillResumeImpact(nIndex)		
		g_SuperWeapon9_DIYSkill_ImpactId[nIndex] = 0
	end
	
	-- 获得插槽等级，控制具体效果数值显示
	local slotLevel = 0
	if g_SuperWeapon9_DIYSkill_WeaponIndex >= 0 then
		slotLevel = DataPool:GetSuperWeaponDIYSkillSlotLevel(g_SuperWeapon9_DIYSkill_SlotIndex)
	end
	if slotLevel == nil or slotLevel <= 0 then
		slotLevel = 1
	end
	
	-- 显示所有的效果
	local curIndex = 1
	for nId = 1, g_SuperWeapon9_DIYSkill_ImpactNum * g_SuperWeapon9_DIYSkill_SlotNum do	
		-- 获得激活数据
		local slotType, nCostNum, nSkillId = DataPool:GetSuperWeaponDIYSkillActiveData(nId)
		--同一类型的则显示
		if slotType ~= nil and slotType > 0 and slotType == g_SuperWeapon9_DIYSkill_SlotIndex then
		
			-- 效果图标
			local bRet,iconName = DataPool:GetSkillIconName(nSkillId)
			if bRet == 1 then
				local curIcon = GetIconFullName(iconName)
				g_SuperWeapon9_DIYSkill_ImpactIcon[g_SuperWeapon9_DIYSkill_SlotIndex][curIndex]:SetProperty("NormalImage",curIcon)
			else
				g_SuperWeapon9_DIYSkill_ImpactIcon[g_SuperWeapon9_DIYSkill_SlotIndex][curIndex]:SetProperty("NormalImage", "")
			end		
			-- 效果图标tips
			local bRet,skillName = DataPool:GetSkillName(nSkillId)
			--local bRet,skillDesc = DataPool:GetSuperWeaponDIYSkillDesc(nSkillId, slotLevel)
			if bRet == 1 then
				g_SuperWeapon9_DIYSkill_ImpactIcon[g_SuperWeapon9_DIYSkill_SlotIndex][curIndex]:SetToolTip(skillName)
			else
				g_SuperWeapon9_DIYSkill_ImpactIcon[g_SuperWeapon9_DIYSkill_SlotIndex][curIndex]:SetToolTip("")
			end			
			-- 效果蒙红
			--local bActive = 1--Pneuma:GetMF(g_SuperWeapon9_DIYSkill_ImpactMFBegin+nId-1)
			--if bActive == 1 then--已激活什么都不显示
			--	g_SuperWeapon9_DIYSkill_ImpactMask[g_SuperWeapon9_DIYSkill_SlotIndex][curIndex]:Hide()
			--else--未激活则需要显示
			--	g_SuperWeapon9_DIYSkill_ImpactMask[g_SuperWeapon9_DIYSkill_SlotIndex][curIndex]:Show()
			--end	
							
			-- 记录效果id
			g_SuperWeapon9_DIYSkill_ImpactId[curIndex] = nId
			curIndex = curIndex + 1

		end
	end
	
	-- 设置默认选中
	g_SuperWeapon9_DIYSkill_EmbedImpactId = 0
	local nImpactId = DataPool:GetSuperWeaponDIYSkillImpactIndex(g_SuperWeapon9_DIYSkill_SlotIndex)
	if nImpactId ~= nil and nImpactId > 0 then
		-- 选中镶嵌的内容
		for i=1, g_SuperWeapon9_DIYSkill_ImpactNum do
			if g_SuperWeapon9_DIYSkill_ImpactId[i] == nImpactId then
				-- 记录镶嵌数据
				g_SuperWeapon9_DIYSkill_EmbedImpactId = nImpactId
				-- 显示使用中图标
				g_SuperWeapon9_DIYSkill_ImpactMask[g_SuperWeapon9_DIYSkill_SlotIndex][i]:Show()
				-- 设置当前选中项
				if g_SuperWeapon9_DIYSkill_ImpactIndex <= 0 or g_SuperWeapon9_DIYSkill_ImpactIndex > g_SuperWeapon9_DIYSkill_ImpactNum then
					g_SuperWeapon9_DIYSkill_ImpactIndex = i
				end
				break
			end
		end
	end
	
	-- 不存在使用中，则默认选中第一个
	if g_SuperWeapon9_DIYSkill_ImpactIndex <= 0 or g_SuperWeapon9_DIYSkill_ImpactIndex > g_SuperWeapon9_DIYSkill_ImpactNum then
		g_SuperWeapon9_DIYSkill_ImpactIndex = 1
	end
	if g_SuperWeapon9_DIYSkill_ImpactId[g_SuperWeapon9_DIYSkill_ImpactIndex] > 0 then
		g_SuperWeapon9_DIYSkill_ImpactAnimate[g_SuperWeapon9_DIYSkill_SlotIndex][g_SuperWeapon9_DIYSkill_ImpactIndex]:Show()
	end
	
	-- 更新当前选中效果具体信息
	SuperWeapon9_DIYSkill_SkillUpdateInfo()
	
	-- 更新确认按钮状态
	--SuperWeapon9_DIYSkill_SkillUpdateButton()
	
end

--**********************************
-- 神器DIY技能--具体效果页面--更新当前选中效果具体信息
--**********************************
function SuperWeapon9_DIYSkill_SkillUpdateInfo()

	-- 效果名称
	g_SuperWeapon9_DIYSkill_ImpactName:SetText("")
	-- 效果描述
	g_SuperWeapon9_DIYSkill_ImpactIntro:SetText("")
	-- 效果消耗
	--g_SuperWeapon9_DIYSkill_ImpactCost:SetText("")

	-- 当前选项
	if g_SuperWeapon9_DIYSkill_SlotIndex <= 0 or g_SuperWeapon9_DIYSkill_SlotIndex > g_SuperWeapon9_DIYSkill_SlotNum then
		return
	end
	if g_SuperWeapon9_DIYSkill_ImpactIndex <= 0 or g_SuperWeapon9_DIYSkill_ImpactIndex > g_SuperWeapon9_DIYSkill_ImpactNum then
		return
	end
	
	-- 选中效果id
	local nImpactId = g_SuperWeapon9_DIYSkill_ImpactId[g_SuperWeapon9_DIYSkill_ImpactIndex]
	if nImpactId == nil or nImpactId <= 0 then
		return
	end
	
	-- 获得激活数据
	local slotType, nCostNum, nSkillId = DataPool:GetSuperWeaponDIYSkillActiveData(nImpactId)
	if slotType == nil or slotType <= 0 or slotType ~= g_SuperWeapon9_DIYSkill_SlotIndex then
		return
	end	
	
	-- 获得插槽等级，控制具体效果数值显示
	local slotLevel = 0
	if g_SuperWeapon9_DIYSkill_WeaponIndex >= 0 then
		slotLevel = DataPool:GetSuperWeaponDIYSkillSlotLevel(g_SuperWeapon9_DIYSkill_SlotIndex)
	end
	if slotLevel == nil or slotLevel <= 0 then
		slotLevel = 1
	end
	
	-- 名称
	local bRet,skillName = DataPool:GetSkillName(nSkillId)
	if bRet == 1 then
		g_SuperWeapon9_DIYSkill_ImpactName:SetText(ScriptGlobal_Format("#{JXSQ_170829_210}", skillName))
	else
		g_SuperWeapon9_DIYSkill_ImpactName:SetText("")
	end

	-- 描述
	local bRet,skillDesc = DataPool:GetSuperWeaponDIYSkillDesc(nSkillId, slotLevel)
	if bRet == 1 then
		g_SuperWeapon9_DIYSkill_ImpactIntro:SetText(ScriptGlobal_Format("#{JXSQ_170829_211}", skillDesc))
	else
		g_SuperWeapon9_DIYSkill_ImpactIntro:SetText("")
	end
	
	-- 所需道具
	--local bActive = 1--Pneuma:GetMF(g_SuperWeapon9_DIYSkill_ImpactMFBegin+nImpactId-1)
	--if bActive == 1 then--已激活什么都不显示
	--	g_SuperWeapon9_DIYSkill_ImpactCost:SetText("")
	--else--未激活则需要显示激活消耗
	--	local costNum = ScriptGlobal_Format(g_SuperWeapon9_DIYSkill_Data[g_SuperWeapon9_DIYSkill_SlotIndex].costText, nCostNum)
	--	g_SuperWeapon9_DIYSkill_ImpactCost:SetText(costNum)
	--end	
	
	-- 镶嵌的效果显示使用中
	--if nImpactId == g_SuperWeapon9_DIYSkill_EmbedImpactId then
	--	g_SuperWeapon9_DIYSkill_ImpactCost:SetText("#{JXSQ_170804_101}")
	--end

end

--**********************************
-- 神器DIY技能--具体效果页面--按钮名字和tips更新
--**********************************
function SuperWeapon9_DIYSkill_SkillUpdateButton()

	-- 默认显示为激活
	g_SuperWeapon9_DIYSkill_ImpactButton:SetText("#{JXSQ_170804_107}")
	g_SuperWeapon9_DIYSkill_ImpactButton:SetToolTip("")
	
	-- 当前选项
	if g_SuperWeapon9_DIYSkill_SlotIndex <= 0 or g_SuperWeapon9_DIYSkill_SlotIndex > g_SuperWeapon9_DIYSkill_SlotNum then
		return
	end
	if g_SuperWeapon9_DIYSkill_ImpactIndex <= 0 or g_SuperWeapon9_DIYSkill_ImpactIndex > g_SuperWeapon9_DIYSkill_ImpactNum then
		return 
	end
	
	-- 选中效果id
	local nImpactId = g_SuperWeapon9_DIYSkill_ImpactId[g_SuperWeapon9_DIYSkill_ImpactIndex]
	if nImpactId == nil or nImpactId <= 0 then
		return
	end
	
	-- 判断激活状态
	local bActive = 1--Pneuma:GetMF(g_SuperWeapon9_DIYSkill_ImpactMFBegin+nImpactId-1)
	if bActive == nil or bActive ~= 1 then
		return
	end
	
	-- 已激活未镶嵌
	if g_SuperWeapon9_DIYSkill_WeaponIndex < 0 or g_SuperWeapon9_DIYSkill_EmbedImpactId <= 0 or g_SuperWeapon9_DIYSkill_EmbedImpactId ~= nImpactId then
		-- 显示镶嵌
		g_SuperWeapon9_DIYSkill_ImpactButton:SetText("#{JXSQ_170804_108}")
		g_SuperWeapon9_DIYSkill_ImpactButton:SetToolTip("#{JXSQ_170804_109}")
	-- 已经镶嵌
	else
		-- 显示卸下
		g_SuperWeapon9_DIYSkill_ImpactButton:SetText("#{JXSQ_170804_118}")
		g_SuperWeapon9_DIYSkill_ImpactButton:SetToolTip("#{JXSQ_170804_119}")
	end		

end
			
--**********************************
-- 神器DIY技能--具体效果页面--选中一项
--**********************************
function SuperWeapon9_DIYSkill_SkillButtonSelect(nIndex)

	if g_SuperWeapon9_DIYSkill_SlotIndex <= 0 or g_SuperWeapon9_DIYSkill_SlotIndex > g_SuperWeapon9_DIYSkill_SlotNum then
		return
	end
	if nIndex == nil or nIndex <= 0 or nIndex > g_SuperWeapon9_DIYSkill_ImpactNum then
		return 
	end
	
	-- 与上次选择相同
	--if g_SuperWeapon9_DIYSkill_ImpactIndex == nIndex then
	--	return
	--end
	
	-- 删除上次状态
	if g_SuperWeapon9_DIYSkill_ImpactIndex > 0 and g_SuperWeapon9_DIYSkill_ImpactIndex <= g_SuperWeapon9_DIYSkill_ImpactNum then
		g_SuperWeapon9_DIYSkill_ImpactAnimate[g_SuperWeapon9_DIYSkill_SlotIndex][g_SuperWeapon9_DIYSkill_ImpactIndex]:Hide()
	end

	-- 记录选项
	g_SuperWeapon9_DIYSkill_ImpactIndex = nIndex
	
	-- 设置本次状态
	if g_SuperWeapon9_DIYSkill_ImpactId[g_SuperWeapon9_DIYSkill_ImpactIndex] > 0 then
		g_SuperWeapon9_DIYSkill_ImpactAnimate[g_SuperWeapon9_DIYSkill_SlotIndex][g_SuperWeapon9_DIYSkill_ImpactIndex]:Show()
	end
	
	-- 更新当前选中效果具体信息
	SuperWeapon9_DIYSkill_SkillUpdateInfo()

	-- 更新按钮状态
	--SuperWeapon9_DIYSkill_SkillUpdateButton()
	
end

--**********************************
-- 神器DIY技能--具体效果页面--激活/镶嵌/卸下
--**********************************
function SuperWeapon9_DIYSkill_SkillButtonEmbed()
	
	--	未选中
	if g_SuperWeapon9_DIYSkill_SlotIndex <= 0 or g_SuperWeapon9_DIYSkill_SlotIndex > g_SuperWeapon9_DIYSkill_SlotNum then
		return
	end
	if g_SuperWeapon9_DIYSkill_ImpactIndex <= 0 or g_SuperWeapon9_DIYSkill_ImpactIndex > g_SuperWeapon9_DIYSkill_ImpactNum then
		return 
	end
	
	-- 选中无效
	local nImpactId = g_SuperWeapon9_DIYSkill_ImpactId[g_SuperWeapon9_DIYSkill_ImpactIndex]
	if nImpactId == nil or nImpactId <= 0 then
		return
	end
	
	-- 是否激活
	--local bActive = 1--Pneuma:GetMF(g_SuperWeapon9_DIYSkill_ImpactMFBegin+nImpactId-1)
	--if bActive == nil or bActive ~= 1 then
	--	-- 未激活
	--	Clear_XSCRIPT()
	--		Set_XSCRIPT_Function_Name( "SuperWeaponDIYSkill_AddImpact" )
	--		Set_XSCRIPT_ScriptID(892471)
	--		Set_XSCRIPT_Parameter(0,g_TargetServerID)
	--		Set_XSCRIPT_Parameter(1,g_SuperWeapon9_DIYSkill_WeaponIndex)
	--		Set_XSCRIPT_Parameter(2,g_SuperWeapon9_DIYSkill_SlotIndex)
	--		Set_XSCRIPT_Parameter(3,nImpactId)
	--		Set_XSCRIPT_Parameter(4,0)
	--		Set_XSCRIPT_ParamCount(5)
	--	Send_XSCRIPT()			
	--else
		-- 是否镶嵌
		--if g_SuperWeapon9_DIYSkill_EmbedImpactId == nImpactId then
		--	-- 卸下
		--	Clear_XSCRIPT()
		--		Set_XSCRIPT_Function_Name( "SuperWeaponDIYSkill_ResolveSlot" )
		--		Set_XSCRIPT_ScriptID(892471)
		--		Set_XSCRIPT_Parameter(0,g_TargetServerID)
		--		Set_XSCRIPT_Parameter(1,g_SuperWeapon9_DIYSkill_WeaponIndex)
		--		Set_XSCRIPT_Parameter(2,g_SuperWeapon9_DIYSkill_SlotIndex)
		--		Set_XSCRIPT_Parameter(3,nImpactId)
		--		Set_XSCRIPT_ParamCount(4)
		--	Send_XSCRIPT()				
		--else
			--判断冷却时间
			if g_SuperWeapon9_DIYSkill_InCooldown == 0 then--冷却时间已到
				-- 镶嵌
				Clear_XSCRIPT()
					Set_XSCRIPT_Function_Name( "SuperWeaponDIYSkill_EmbedSlot" )
					Set_XSCRIPT_ScriptID(892471)
					Set_XSCRIPT_Parameter(0,g_TargetServerID)
					Set_XSCRIPT_Parameter(1,g_SuperWeapon9_DIYSkill_WeaponIndex)
					Set_XSCRIPT_Parameter(2,g_SuperWeapon9_DIYSkill_SlotIndex)
					Set_XSCRIPT_Parameter(3,nImpactId)
					Set_XSCRIPT_Parameter(4,0)
					Set_XSCRIPT_ParamCount(5)
				Send_XSCRIPT()
				--设置冷却时间
				g_SuperWeapon9_DIYSkill_InCooldown = 1
				SetTimer("SuperWeapon9_DIYSkill", "SuperWeapon9_DIYSkill_g_Cooldown()",g_SuperWeapon9_DIYSkill_Cooldown)
			else--冷却时间未到
				PushDebugMessage("#{XLDL_140606_99}")
			end
			
		--end
		
	--end
	
end

--===============================================
-- 冷却计时结束()
--===============================================
function SuperWeapon9_DIYSkill_g_Cooldown()
	g_SuperWeapon9_DIYSkill_InCooldown = 0
	KillTimer("SuperWeapon9_DIYSkill_g_Cooldown()")
end

--【九星神器引导任务】任务5:tips随界面移动而移动
function SuperWeapon9_DIYSkill_OnMoved()
   if "SuperWeapon9_DIYSkill" == GetFreshManGuideOwner() then --当本界面show并且引导ui指向本界面,才需要响应
        OpenFreshManGuide(2, -1, -1, -1)
   end
end

function SuperWeapon9_DIYSkill_Refresh_Page_Button( nLevel )

	if 1 == 1 then
		return
	end
	
	--神鼎
	if ( nLevel < 15 ) then
		SuperWeapon9_DIYSkill_ShenDing:Disable()
		SuperWeapon9_DIYSkill_ShenDing_tips:Show()
	--	SuperWeapon9_DIYSkill_ShenDing_tips:SetToolTip("#{RWYQ_150707_07}")
	else
		SuperWeapon9_DIYSkill_ShenDing:Enable()
		SuperWeapon9_DIYSkill_ShenDing_tips:Hide()
	end
	--子女
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 ) or InfantCount<=0 then
		SuperWeapon9_DIYSkill_Infant:Disable()
		SuperWeapon9_DIYSkill_Infant_tips:Show()
	--	SuperWeapon9_DIYSkill_Infant_tips:SetToolTip("#{RWYQ_150707_01}")
	else
		SuperWeapon9_DIYSkill_Infant:Enable()
		SuperWeapon9_DIYSkill_Infant_tips:Hide()
	end
	--武魂
--	if ( nLevel < 65 ) then
--		SuperWeapon9_DIYSkill_Wuhun:Disable()
--		SuperWeapon9_DIYSkill_Wuhun_tips:Show()
	--	SuperWeapon9_DIYSkill_Wuhun_tips:SetToolTip("#{RWYQ_150707_02}")
--	else
		SuperWeapon9_DIYSkill_Wuhun:Enable()
		SuperWeapon9_DIYSkill_Wuhun_tips:Hide()
--	end
	--修炼
	if ( nLevel < 70 ) then
		SuperWeapon9_DIYSkill_Xiulian:Disable()
		SuperWeapon9_DIYSkill_Xiulian_tips:Show()
	--	SuperWeapon9_DIYSkill_Xiulian_tips:SetToolTip("#{RWYQ_150707_03}")
	else
		SuperWeapon9_DIYSkill_Xiulian:Enable()
		SuperWeapon9_DIYSkill_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		SuperWeapon9_DIYSkill_Miji:Disable()
		SuperWeapon9_DIYSkill_Miji_tips:Show()
	--	SuperWeapon9_DIYSkill_Miji_tips:SetToolTip("#{RWYQ_150707_04}")
	else
		SuperWeapon9_DIYSkill_Miji:Enable()
		SuperWeapon9_DIYSkill_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		SuperWeapon9_DIYSkill_ZhenYuan:Disable()
		SuperWeapon9_DIYSkill_ZhenYuan_tips:Show()
	--	SuperWeapon9_DIYSkill_ZhenYuan_tips:SetToolTip("#{RWYQ_150707_05}")
	else
		SuperWeapon9_DIYSkill_ZhenYuan:Enable()
		SuperWeapon9_DIYSkill_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		SuperWeapon9_DIYSkill_JueWei:Disable()
		SuperWeapon9_DIYSkill_JueWei_tips:Show()
	--	SuperWeapon9_DIYSkill_JueWei_tips:SetToolTip("#{RWYQ_150707_08}")
	else
		SuperWeapon9_DIYSkill_JueWei:Enable()
		SuperWeapon9_DIYSkill_JueWei_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		SuperWeapon9_DIYSkill_JingMai:Disable()
		SuperWeapon9_DIYSkill_JingMai_tips:Show()
	--	SuperWeapon9_DIYSkill_JingMai_tips:SetToolTip("#{RWYQ_150707_06}")
	else
		SuperWeapon9_DIYSkill_JingMai:Enable()
		SuperWeapon9_DIYSkill_JingMai_tips:Hide()
	end

	if ( nLevel < 85 ) then
		SuperWeapon9_DIYSkill_BaoJian:Disable()
		SuperWeapon9_DIYSkill_BaoJian_tips:Show()
	else
		SuperWeapon9_DIYSkill_BaoJian:Enable()
		SuperWeapon9_DIYSkill_BaoJian_tips:Hide()
	end
	--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		SuperWeapon9_DIYSkill_WuYi:Enable()
		SuperWeapon9_DIYSkill_WuYi_tips:Hide()
	else
		SuperWeapon9_DIYSkill_WuYi:Disable()
		SuperWeapon9_DIYSkill_WuYi_tips:Show()
	end
	SuperWeapon9_DIYSkill_RefreshWuYiTip()
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		SuperWeapon9_DIYSkill_ShenQi:Enable()
		SuperWeapon9_DIYSkill_ShenQi_tips:Hide()
	else
		SuperWeapon9_DIYSkill_ShenQi:Disable()
		SuperWeapon9_DIYSkill_ShenQi_tips:Show()
	end
	SuperWeapon9_DIYSkill_RefreshOtherInfoTip()
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		SuperWeapon9_DIYSkill_Armor:Enable()
		SuperWeapon9_DIYSkill_Armor_tips:Hide()
	else
		SuperWeapon9_DIYSkill_Armor:Disable()
		SuperWeapon9_DIYSkill_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		SuperWeapon9_DIYSkill_CangPin:Enable()
		SuperWeapon9_DIYSkill_CangPin_tips:Hide()
	else
		SuperWeapon9_DIYSkill_CangPin:Disable()
		SuperWeapon9_DIYSkill_CangPin_tips:Show()
	end
	
	SuperWeapon9_DIYSkill_RefreshCangPinTip()
end

-- 关闭
function SuperWeapon9_DIYSkill_CloseFunction()
	this:Hide()
end

--装备
function SuperWeapon9_DIYSkill_SelfEquip_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);

	OpenEquip(1);
	SuperWeapon9_DIYSkill_CloseFunction();
end

--资料
function SuperWeapon9_DIYSkill_SelfData_Switch()
	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("self");
	SuperWeapon9_DIYSkill_CloseFunction();
end

--珍兽
function SuperWeapon9_DIYSkill_Pet_Switch()
	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	TogglePetPage();
	SuperWeapon9_DIYSkill_CloseFunction();
end

--子女
function SuperWeapon9_DIYSkill_Infant_Switch()
	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:ToggleInfantPage();
	if bRet == 1 then
		SuperWeapon9_DIYSkill_CloseFunction();
	end
end

--武魂
function SuperWeapon9_DIYSkill_Wuhun_Switch()
	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	ToggleWuhunPage();
	SuperWeapon9_DIYSkill_CloseFunction();
end

--修炼
function SuperWeapon9_DIYSkill_Xiulian_Switch()
	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = XiuLianPage();
	if bRet == 1 then
		SuperWeapon9_DIYSkill_CloseFunction();
	end
end

--秘籍
function SuperWeapon9_DIYSkill_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenMijiPage();
	if bRet == 1 then
		SuperWeapon9_DIYSkill_CloseFunction();
	end
end

--真元
function SuperWeapon9_DIYSkill_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	if bRet == 1 then
		SuperWeapon9_DIYSkill_CloseFunction();
	end
end

--经脉
function SuperWeapon9_DIYSkill_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenJingMaiPage();
	if nRet == 1 then
		SuperWeapon9_DIYSkill_CloseFunction();
	end
end

--神鼎
function SuperWeapon9_DIYSkill_ShenDing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenShenDingPage();
	if bRet == 1 then
		SuperWeapon9_DIYSkill_CloseFunction();
	end
end

function SuperWeapon9_DIYSkill_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if ( bRet == 1 ) then
		SuperWeapon9_DIYSkill_CloseFunction()
	end
end

function SuperWeapon9_DIYSkill_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()
	SuperWeapon9_DIYSkill_CloseFunction();
end

function SuperWeapon9_DIYSkill_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
	SuperWeapon9_DIYSkill_CloseFunction();
end

function SuperWeapon9_DIYSkill_OpenShenQi()
end

--骑乘
function SuperWeapon9_DIYSkill_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);

	OpenRidePage();
	SuperWeapon9_DIYSkill_CloseFunction();
end

--其他
function SuperWeapon9_DIYSkill_Other_Info_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);

	OtherInfoPage();
	SuperWeapon9_DIYSkill_CloseFunction();
end

function SuperWeapon9_DIYSkill_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SuperWeapon9_DIYSkill_PageButton[idx]:GetProperty("UnifiedXPosition");
			SuperWeapon9_DIYSkill_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		SuperWeapon9_DIYSkill_Buttontips:Show()
	else
		SuperWeapon9_DIYSkill_Buttontips:Hide()
	end
end

function SuperWeapon9_DIYSkill_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SuperWeapon9_DIYSkill_PageButton[idx]:GetProperty("UnifiedXPosition");
			SuperWeapon9_DIYSkill_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then
		SuperWeapon9_DIYSkill_OtherInfo_ButtonTips:Show()
	else
		SuperWeapon9_DIYSkill_OtherInfo_ButtonTips:Hide()
	end
end

--内甲
function SuperWeapon9_DIYSkill_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function SuperWeapon9_DIYSkill_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function SuperWeapon9_DIYSkill_RefreshCangPinTip()
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
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SuperWeapon9_DIYSkill_PageButton[idx]:GetProperty("UnifiedXPosition");
			SuperWeapon9_DIYSkill_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		SuperWeapon9_DIYSkill_CangPin_Buttontips:Show()
	else
		SuperWeapon9_DIYSkill_CangPin_Buttontips:Hide()
	end
end


function SuperWeapon9_DIYSkill_ShowPage()

	for i = 1, table.getn(g_SuperWeapon9_DIYSkill_Page) do
		g_SuperWeapon9_DIYSkill_PageButton[i]:Hide()
		g_SuperWeapon9_DIYSkill_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	SuperWeapon9_DIYSkill_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_SuperWeapon9_DIYSkill_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_SuperWeapon9_DIYSkill_Page) do
			if i ~= nPageNumber then
				g_SuperWeapon9_DIYSkill_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_SuperWeapon9_DIYSkill_Page) do
		if SuperWeapon9_DIYSkill_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_SuperWeapon9_DIYSkill_PageButton[g_PageCount]:Show()
			g_SuperWeapon9_DIYSkill_PageButton[g_PageCount]:SetText(g_SuperWeapon9_DIYSkill_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if SuperWeapon9_DIYSkill_IsPageEnable(i) == 1 then
				g_SuperWeapon9_DIYSkill_PageButton[g_PageCount]:Enable()
				g_SuperWeapon9_DIYSkill_PageMask[g_PageCount]:Hide()
			else
				g_SuperWeapon9_DIYSkill_PageButton[g_PageCount]:Disable()
				g_SuperWeapon9_DIYSkill_PageMask[g_PageCount]:Show()
				if g_SuperWeapon9_DIYSkill_Page[i].Tip ~= "" then
					g_SuperWeapon9_DIYSkill_PageMask[g_PageCount]:SetToolTip(g_SuperWeapon9_DIYSkill_Page[i].Tip)
				end
			end
		end
	end
	
	SuperWeapon9_DIYSkill_RefreshWuYiTip()
	SuperWeapon9_DIYSkill_RefreshOtherInfoTip()
	SuperWeapon9_DIYSkill_RefreshCangPinTip()
	
end

function SuperWeapon9_DIYSkill_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		SuperWeapon9_DIYSkill_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		SuperWeapon9_DIYSkill_SelfData_Switch()
	elseif idx == 3 then--珍兽
		SuperWeapon9_DIYSkill_Pet_Switch()
	elseif idx == 4 then--子女
		SuperWeapon9_DIYSkill_Infant_Switch()
	elseif idx == 5 then--武魂
		SuperWeapon9_DIYSkill_Wuhun_Switch()
	elseif idx == 6 then--修炼
		SuperWeapon9_DIYSkill_Xiulian_Switch()
	elseif idx == 7 then--秘籍
		SuperWeapon9_DIYSkill_Miji_Page_Switch()
	elseif idx == 8 then--真元
		SuperWeapon9_DIYSkill_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		SuperWeapon9_DIYSkill_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		SuperWeapon9_DIYSkill_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		SuperWeapon9_DIYSkill_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		SuperWeapon9_DIYSkill_OpenBaoJian()
	elseif idx == 13 then--武意
		SuperWeapon9_DIYSkill_OpenWuYi()
	elseif idx == 14 then--神器
		SuperWeapon9_DIYSkill_OpenShenQi()
	elseif idx == 15 then--星盘
		SuperWeapon9_DIYSkill_Armor_Page_Switch()
	elseif idx == 16 then--名物
		SuperWeapon9_DIYSkill_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		SuperWeapon9_DIYSkill_Other_Info_Page_Switch()
	end
end

function SuperWeapon9_DIYSkill_CheckPage(idx)
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

function SuperWeapon9_DIYSkill_IsPageEnable(idx)
	
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

function SuperWeapon9_DIYSkill_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


