----------------------------------------------
-- 【2017Q3】九星神器升星设计
-- 神器DIY技能效果玩法规则
-- 新神器技能效果配置界面
-- ****搜索关键字： 神器DIY技能 DIYSkill
-- !!!reloadscript =OtherSuperWeapon9_DIYSkill
----------------------------------------------

-- 窗口位置
local g_OtherSuperWeapon9_DIYSkill_UnifiedPosition

-- 神器
local g_OtherSuperWeapon9_DIYSkill_WeaponText
local g_OtherSuperWeapon9_DIYSkill_WeaponSlot
local g_OtherSuperWeapon9_DIYSkill_WeaponIndex = -1
local g_OtherSuperWeapon9_DIYSkill_WeaponMask

-- 技能
local g_OtherSuperWeapon9_DIYSkill_SkillSlot
local g_OtherSuperWeapon9_DIYSkill_SkillMask
local g_OtherSuperWeapon9_DIYSkill_SkillText

-- 插槽
local g_OtherSuperWeapon9_DIYSkill_SlotNum = 3
local g_OtherSuperWeapon9_DIYSkill_SlotLevelLimit = 10
local g_OtherSuperWeapon9_DIYSkill_SlotButton = {}
local g_OtherSuperWeapon9_DIYSkill_SlotImage = {}
local g_OtherSuperWeapon9_DIYSkill_SlotLevel = {}
--local g_OtherSuperWeapon9_DIYSkill_SlotSkill = {}
local g_OtherSuperWeapon9_DIYSkill_SlotLock = {}
local g_OtherSuperWeapon9_DIYSkill_SlotSelect = {}

-- 效果页面
local g_OtherSuperWeapon9_DIYSkill_ImpactTitle
local g_OtherSuperWeapon9_DIYSkill_ImpactName
local g_OtherSuperWeapon9_DIYSkill_ImpactIntro
--local g_OtherSuperWeapon9_DIYSkill_ImpactCost
local g_OtherSuperWeapon9_DIYSkill_ImpactBK = {}

-- 具体效果
local g_OtherSuperWeapon9_DIYSkill_ImpactNum = 4
local g_OtherSuperWeapon9_DIYSkill_ImpactIcon = {}
local g_OtherSuperWeapon9_DIYSkill_ImpactAnimate = {}
local g_OtherSuperWeapon9_DIYSkill_ImpactMask={}
-- 当前效果列表的具体数值
local g_OtherSuperWeapon9_DIYSkill_ImpactId = {0,0,0,0}

-- 目前只开放12个
--local g_OtherSuperWeapon9_DIYSkill_ImpactMF = {1835,1836,1837,1838,1839,1840,1841,1842,1843,1844,1845,1846,1847,1848,1849}
local g_OtherSuperWeapon9_DIYSkill_ImpactMFBegin = 1835

-- 效果页面用
local g_OtherSuperWeapon9_DIYSkill_SlotIndex = 0 
local g_OtherSuperWeapon9_DIYSkill_ImpactIndex = 0
local g_OtherSuperWeapon9_DIYSkill_EmbedImpactId = 0

-- 远离npc关闭
local MAX_OBJ_DISTANCE = 3.0
local g_ObjCared = -1
local g_TargetServerID = -1

-- 显示数据
local g_OtherSuperWeapon9_DIYSkill_Data = 
{
	[1] = { itemId = 38002040, bindId = 38002041, nameText = "#{JXSQ_170804_67}", lockText = "#{JXSQ_170804_70}", title = "#{JXSQ_170804_92}", costText = "#{JXSQ_170804_98}", itemText = "#{JXSQ_170804_102}", itemTip = "#{JXSQ_170829_219}", },
	[2] = { itemId = 38002042, bindId = 38002043, nameText = "#{JXSQ_170804_68}", lockText = "#{JXSQ_170804_71}", title = "#{JXSQ_170804_93}", costText = "#{JXSQ_170804_99}", itemText = "#{JXSQ_170804_103}", itemTip = "#{JXSQ_170829_220}", },
	[3] = { itemId = 38002044, bindId = 38002045, nameText = "#{JXSQ_170804_69}", lockText = "#{JXSQ_170804_72}", title = "#{JXSQ_170804_94}", costText = "#{JXSQ_170804_100}", itemText = "#{JXSQ_170804_104}", itemTip = "#{JXSQ_170829_221}", },
}

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_OtherSuperWeapon9_DIYSkill_Page = {
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

--**********************************
-- 神器DIY技能--PreLoad
--**********************************
function OtherSuperWeapon9_DIYSkill_PreLoad()

	this:RegisterEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI");--打开界面
	this:RegisterEvent("OTHERPLAYER_UPDATE_EQUIP");
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);	--	窗口大小变换
	
end

--**********************************
-- 神器DIY技能--OnLoad
--**********************************
function OtherSuperWeapon9_DIYSkill_OnLoad()

	-- 主页面
	-- [物品描述]
	g_OtherSuperWeapon9_DIYSkill_WeaponText = OtherSuperWeapon9_DIYSkill_MainFrame_Text1
	-- [背包物品]
	g_OtherSuperWeapon9_DIYSkill_WeaponSlot = OtherSuperWeapon9_DIYSkill_MainFrame_Item
	-- [物品栏]
	g_OtherSuperWeapon9_DIYSkill_WeaponMask = OtherSuperWeapon9_DIYSkill_MainFrame_Item_Mask
	-- [技能栏]
	g_OtherSuperWeapon9_DIYSkill_SkillSlot = OtherSuperWeapon9_DIYSkill_MainFrame_Skill
	-- [技能栏蒙红]
	g_OtherSuperWeapon9_DIYSkill_SkillMask = OtherSuperWeapon9_DIYSkill_MainFrame_Skill_Feng
	-- [技能描述]
	g_OtherSuperWeapon9_DIYSkill_SkillText = OtherSuperWeapon9_DIYSkill_MainFrame_Skill_text
	-- [插槽图标]
	g_OtherSuperWeapon9_DIYSkill_SlotButton[1] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot1_Skill
	g_OtherSuperWeapon9_DIYSkill_SlotButton[2] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot2_Skill
	g_OtherSuperWeapon9_DIYSkill_SlotButton[3] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot3_Skill	
	-- [插槽未解锁图片]
	g_OtherSuperWeapon9_DIYSkill_SlotImage[1] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot1_SkillLocked
	g_OtherSuperWeapon9_DIYSkill_SlotImage[2] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot2_SkillLocked
	g_OtherSuperWeapon9_DIYSkill_SlotImage[3] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot3_SkillLocked	
	-- [插槽等级]
	g_OtherSuperWeapon9_DIYSkill_SlotLevel[1] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot1_Level
	g_OtherSuperWeapon9_DIYSkill_SlotLevel[2] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot2_Level
	g_OtherSuperWeapon9_DIYSkill_SlotLevel[3] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot3_Level	
	-- [插槽镶嵌技能名称]
	--g_OtherSuperWeapon9_DIYSkill_SlotSkill[1] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot1_SkillName
	--g_OtherSuperWeapon9_DIYSkill_SlotSkill[2] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot2_SkillName
	--g_OtherSuperWeapon9_DIYSkill_SlotSkill[3] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot3_SkillName	
	-- [插槽未解锁文字]
	g_OtherSuperWeapon9_DIYSkill_SlotLock[1] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot1_Locked
	g_OtherSuperWeapon9_DIYSkill_SlotLock[2] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot2_Locked
	g_OtherSuperWeapon9_DIYSkill_SlotLock[3] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot3_Locked
	-- [插槽选中框]
	g_OtherSuperWeapon9_DIYSkill_SlotSelect[1] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot1_Selected
	g_OtherSuperWeapon9_DIYSkill_SlotSelect[2] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot2_Selected
	g_OtherSuperWeapon9_DIYSkill_SlotSelect[3] = OtherSuperWeapon9_DIYSkill_MainFrame_Slot3_Selected
	
	-- 效果页面
	-- [标题]
	g_OtherSuperWeapon9_DIYSkill_ImpactTitle = OtherSuperWeapon9_DIYSkill_SkillFrame_title
	-- [效果名称]
	g_OtherSuperWeapon9_DIYSkill_ImpactName = OtherSuperWeapon9_DIYSkill_SkillFrame_Name
	-- [效果描述]
	g_OtherSuperWeapon9_DIYSkill_ImpactIntro = OtherSuperWeapon9_DIYSkill_SkillFrame_Intro
	-- [效果消耗]
	--g_OtherSuperWeapon9_DIYSkill_ImpactCost = OtherSuperWeapon9_DIYSkill_SkillFrame_Text
	
	-- [效果背景图]
	g_OtherSuperWeapon9_DIYSkill_ImpactBK = 
	{
		OtherSuperWeapon9_DIYSkill_SkillFrame1_BK, OtherSuperWeapon9_DIYSkill_SkillFrame2_BK, OtherSuperWeapon9_DIYSkill_SkillFrame3_BK,
	}
	-- [效果图标]
	g_OtherSuperWeapon9_DIYSkill_ImpactIcon =
	{
		{OtherSuperWeapon9_DIYSkill_SkillFrame1_Skill1_icon,OtherSuperWeapon9_DIYSkill_SkillFrame1_Skill2_icon,OtherSuperWeapon9_DIYSkill_SkillFrame1_Skill3_icon,OtherSuperWeapon9_DIYSkill_SkillFrame1_Skill4_icon},
		{OtherSuperWeapon9_DIYSkill_SkillFrame2_Skill1_icon,OtherSuperWeapon9_DIYSkill_SkillFrame2_Skill2_icon,OtherSuperWeapon9_DIYSkill_SkillFrame2_Skill3_icon,OtherSuperWeapon9_DIYSkill_SkillFrame2_Skill4_icon},
		{OtherSuperWeapon9_DIYSkill_SkillFrame3_Skill1_icon,OtherSuperWeapon9_DIYSkill_SkillFrame3_Skill2_icon,OtherSuperWeapon9_DIYSkill_SkillFrame3_Skill3_icon,OtherSuperWeapon9_DIYSkill_SkillFrame3_Skill4_icon},
	}	
	-- [效果选中框]
	g_OtherSuperWeapon9_DIYSkill_ImpactAnimate =
	{
		{OtherSuperWeapon9_DIYSkill_SkillFrame1_Skill1_iconAnimate,OtherSuperWeapon9_DIYSkill_SkillFrame1_Skill2_iconAnimate,OtherSuperWeapon9_DIYSkill_SkillFrame1_Skill3_iconAnimate,OtherSuperWeapon9_DIYSkill_SkillFrame1_Skill4_iconAnimate},
		{OtherSuperWeapon9_DIYSkill_SkillFrame2_Skill1_iconAnimate,OtherSuperWeapon9_DIYSkill_SkillFrame2_Skill2_iconAnimate,OtherSuperWeapon9_DIYSkill_SkillFrame2_Skill3_iconAnimate,OtherSuperWeapon9_DIYSkill_SkillFrame2_Skill4_iconAnimate},
		{OtherSuperWeapon9_DIYSkill_SkillFrame3_Skill1_iconAnimate,OtherSuperWeapon9_DIYSkill_SkillFrame3_Skill2_iconAnimate,OtherSuperWeapon9_DIYSkill_SkillFrame3_Skill3_iconAnimate,OtherSuperWeapon9_DIYSkill_SkillFrame3_Skill4_iconAnimate},
	}
	-- [效果蒙红]
	g_OtherSuperWeapon9_DIYSkill_ImpactMask =
	{
		{OtherSuperWeapon9_DIYSkill_SkillFrame1_Skill1_iconMask,OtherSuperWeapon9_DIYSkill_SkillFrame1_Skill2_iconMask,OtherSuperWeapon9_DIYSkill_SkillFrame1_Skill3_iconMask,OtherSuperWeapon9_DIYSkill_SkillFrame1_Skill4_iconMask},
		{OtherSuperWeapon9_DIYSkill_SkillFrame2_Skill1_iconMask,OtherSuperWeapon9_DIYSkill_SkillFrame2_Skill2_iconMask,OtherSuperWeapon9_DIYSkill_SkillFrame2_Skill3_iconMask,OtherSuperWeapon9_DIYSkill_SkillFrame2_Skill4_iconMask},
		{OtherSuperWeapon9_DIYSkill_SkillFrame3_Skill1_iconMask,OtherSuperWeapon9_DIYSkill_SkillFrame3_Skill2_iconMask,OtherSuperWeapon9_DIYSkill_SkillFrame3_Skill3_iconMask,OtherSuperWeapon9_DIYSkill_SkillFrame3_Skill4_iconMask},
	}
	
	g_OtherSuperWeapon9_DIYSkill_UnifiedPosition = OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition");
	
	g_OtherPageButton[1] = OtherSuperWeapon9_DIYSkill_SelfEquip
	g_OtherPageButton[2] = OtherSuperWeapon9_DIYSkill_TargetData
	g_OtherPageButton[3] = OtherSuperWeapon9_DIYSkill_Pet
	g_OtherPageButton[4] = OtherSuperWeapon9_DIYSkill_TargetInfant
	g_OtherPageButton[5] = OtherSuperWeapon9_DIYSkill_TargetWuhun
	g_OtherPageButton[6] = OtherSuperWeapon9_DIYSkill_Miji
	g_OtherPageButton[7] = OtherSuperWeapon9_DIYSkill_ZhenYuan
	g_OtherPageButton[8] = OtherSuperWeapon9_DIYSkill_JingMai
	g_OtherPageButton[9] = OtherSuperWeapon9_DIYSkill_ShenDing
	g_OtherPageButton[10] = OtherSuperWeapon9_DIYSkill_JueWei
	g_OtherPageButton[11] = OtherSuperWeapon9_DIYSkill_BaoJian
	g_OtherPageButton[12] = OtherSuperWeapon9_DIYSkill_WuYi
	g_OtherPageButton[13] = OtherSuperWeapon9_DIYSkill_ShenQi
	g_OtherPageButton[14] = OtherSuperWeapon9_DIYSkill_Armor
	g_OtherPageButton[15] = OtherSuperWeapon9_DIYSkill_CangPin
	
end

--**********************************
-- 神器DIY技能--OnEvent
--**********************************
function OtherSuperWeapon9_DIYSkill_OnEvent(event)

	local objCared = DataPool:GetCurDialogNpcId();
	
	-- 打开界面
	if event == "OTHERSUPERWEAPONDIYSKILL_OPENUI" then
	
		OtherSuperWeapon9_DIYSkill_OpenUI()

	-- 刷新装备的神器
	elseif event == "OTHERPLAYER_UPDATE_EQUIP" then
	
		if this:IsVisible() then
		
			-- 放入装备更新
			OtherSuperWeapon9_DIYSkill_MainUpdataWeapon()
			
			-- 更新技能效果页面
			if g_OtherSuperWeapon9_DIYSkill_SlotIndex > 0 then
				OtherSuperWeapon9_DIYSkill_SkillUpdate()
			else
				-- 默认显示技能效果A
				OtherSuperWeapon9_DIYSkill_MainButtonSkill(1)				
			end
			
		end

	elseif event == "ADJEST_UI_POS" then

		OtherSuperWeapon9_DIYSkill_ResetWindowPos();
	
	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		OtherSuperWeapon9_DIYSkill_ResetWindowPos()
	
	end

end

--**********************************
-- 神器DIY技能--打开界面
--**********************************
function OtherSuperWeapon9_DIYSkill_OpenUI()

	local obj_id = CachedTarget:GetData("NPCID", 1)
	if (type(obj_id) ~="number") then
		PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
		return
	end
	this:CareObject(obj_id , 1)

	OtherSuperWeapon9_DIYSkill_ShowPage()
	
 	-- 显示界面
	this:Show()
	
	-- 界面重置
	OtherSuperWeapon9_DIYSkill_MainReset()
	
	-- 更新神器	
	OtherSuperWeapon9_DIYSkill_MainUpdataWeapon()
	
	-- 默认显示技能效果A
	OtherSuperWeapon9_DIYSkill_MainButtonSkill(1)
	
	-- 页签选中神器
	local OtherUnionPos = Variable:GetVariable( "OtherUnionPos" );
	OtherSuperWeapon9_DIYSkill_Frame:SetProperty( "UnifiedPosition", OtherUnionPos );
	g_OtherSuperWeapon9_DIYSkill_UnifiedPosition = OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition");
	OtherSuperWeapon9_DIYSkill_ShenQi:SetCheck(1)
	 
end

--**********************************
-- 神器DIY技能--重置位置
--**********************************
function OtherSuperWeapon9_DIYSkill_ResetWindowPos()

	 OtherSuperWeapon9_DIYSkill_Frame:SetProperty("UnifiedPosition", g_OtherSuperWeapon9_DIYSkill_UnifiedPosition);
	 
end

--**********************************
-- 神器DIY技能--主界面清空
--**********************************
function OtherSuperWeapon9_DIYSkill_MainReset()

	-- 神器清空
	OtherSuperWeapon9_DIYSkill_MainResumeWeapon()
	
	-- 技能清空
	OtherSuperWeapon9_DIYSkill_MainResumeSkill()
	
	-- 插槽清空
	g_OtherSuperWeapon9_DIYSkill_SlotIndex = 0
	for nIndex=1, g_OtherSuperWeapon9_DIYSkill_SlotNum do
		OtherSuperWeapon9_DIYSkill_MainResumeSlot(nIndex)
		-- 选中清空
		g_OtherSuperWeapon9_DIYSkill_SlotSelect[nIndex]:Hide()
	end
	
end

--**********************************
-- 神器DIY技能--武器清空
--**********************************
function OtherSuperWeapon9_DIYSkill_MainResumeWeapon()

	if g_OtherSuperWeapon9_DIYSkill_WeaponIndex >= 0 then
	
		--LifeAbility : Lock_Packet_Item(g_OtherSuperWeapon9_DIYSkill_WeaponIndex, 0)
		-- 物品描述
		g_OtherSuperWeapon9_DIYSkill_WeaponText:SetText("#{JXSQ_170829_234}")
		-- 道具栏
		g_OtherSuperWeapon9_DIYSkill_WeaponSlot:SetActionItem(-1)
		--g_OtherSuperWeapon9_DIYSkill_WeaponSlot:SetProperty("NormalImage", "")
		--g_OtherSuperWeapon9_DIYSkill_WeaponSlot:SetToolTip("#{JXSQ_170829_222}")
		g_OtherSuperWeapon9_DIYSkill_WeaponIndex = -1;
		-- 蒙红
		g_OtherSuperWeapon9_DIYSkill_WeaponMask:Show()
		
	end
	
end

--**********************************
-- 神器DIY技能--技能清空
--**********************************
function OtherSuperWeapon9_DIYSkill_MainResumeSkill()

	g_OtherSuperWeapon9_DIYSkill_SkillSlot:SetActionItem(-1)
	g_OtherSuperWeapon9_DIYSkill_SkillMask:Show()
	g_OtherSuperWeapon9_DIYSkill_SkillText:SetText("#{JXSQ_170829_241}")
	
end

--**********************************
-- 神器DIY技能--插槽清空
--**********************************
function OtherSuperWeapon9_DIYSkill_MainResumeSlot(nIndex)

	if nIndex == nil or nIndex <= 0 or nIndex > g_OtherSuperWeapon9_DIYSkill_SlotNum then
		return
	end
	
	-- 等级信息隐藏
	g_OtherSuperWeapon9_DIYSkill_SlotLevel[nIndex]:Hide()
	-- 名称信息隐藏
	--g_OtherSuperWeapon9_DIYSkill_SlotSkill[nIndex]:Hide()
	-- 技能效果框
	g_OtherSuperWeapon9_DIYSkill_SlotButton[nIndex]:SetProperty("NormalImage", "")
	g_OtherSuperWeapon9_DIYSkill_SlotButton[nIndex]:SetToolTip("")
	
	-- 插槽未解锁
	g_OtherSuperWeapon9_DIYSkill_SlotImage[nIndex]:Show()
	-- 显示解锁信息
	g_OtherSuperWeapon9_DIYSkill_SlotLock[nIndex]:Show()
	if g_OtherSuperWeapon9_DIYSkill_WeaponIndex < 0 then
		g_OtherSuperWeapon9_DIYSkill_SlotLock[nIndex]:SetText("#{JXSQ_170829_241}")
	elseif CachedTarget:CheckSuperWeaponDIYSkillData() ~= 1 then
		g_OtherSuperWeapon9_DIYSkill_SlotLock[nIndex]:SetText("#{JXSQ_170829_240}")
	else
		g_OtherSuperWeapon9_DIYSkill_SlotLock[nIndex]:SetText(g_OtherSuperWeapon9_DIYSkill_Data[nIndex].lockText)
	end
		
end
	
--**********************************
-- 神器DIY技能--关闭
--**********************************
function OtherSuperWeapon9_DIYSkill_MainButtonClose()

	-- 主页面清空
	OtherSuperWeapon9_DIYSkill_MainReset()
	-- 效果页面清空
	OtherSuperWeapon9_DIYSkill_SkillReset()
	
	-- 取消关注
	--this:CareObject(g_ObjCared, 0, "OtherSuperWeapon9_DIYSkill");
	--g_ObjCared = -1;
	--g_TargetServerID = -1;
	
	-- 隐藏界面
	--this:Hide()
	
end
	
--**********************************
-- 神器DIY技能--未放入神器默认状态
--**********************************
function OtherSuperWeapon9_DIYSkill_MouseRClick()

	-- 主页面清空
	OtherSuperWeapon9_DIYSkill_MainReset()

	-- 默认显示技能效果A
	OtherSuperWeapon9_DIYSkill_MainButtonSkill(1)
	
end

--**********************************
-- 神器DIY技能--更新神器插槽
--**********************************
function OtherSuperWeapon9_DIYSkill_MainUpdataWeapon(itemIdx)
	
	--local theAction = EnumAction(itemIdx, "packageitem");
	local theAction	= EnumAction(0, "targetequip");
	if theAction:GetID() ~= 0 then
	
		-- 当前装备是否102级八星突破神器或者九星神器
		--if CachedTarget:CheckSuperWeaponDIYSkillData() ~= 1 then
			-- 界面重置
			--OtherSuperWeapon9_DIYSkill_MouseRClick()			
			--return
		--end
		
		if g_OtherSuperWeapon9_DIYSkill_WeaponIndex >= 0 then
			--LifeAbility : Lock_Packet_Item(g_OtherSuperWeapon9_DIYSkill_WeaponIndex,0);
		end

		--local nEquipIndex = theAction:GetDefineID()
		--local icon =  tostring(LifeAbility : Get_Item_Icon_NameByDataIndex(nEquipIndex))
		--g_OtherSuperWeapon9_DIYSkill_WeaponSlot:SetProperty("NormalImage", icon)
		--g_OtherSuperWeapon9_DIYSkill_WeaponSlot:SetToolTip("#{JXSQ_170829_218}")
		g_OtherSuperWeapon9_DIYSkill_WeaponSlot:SetActionItem(theAction:GetID());
		--LifeAbility : Lock_Packet_Item(itemIdx,1);
		--g_OtherSuperWeapon9_DIYSkill_WeaponIndex = itemIdx
		g_OtherSuperWeapon9_DIYSkill_WeaponIndex = 0
		-- 九星
		if CachedTarget:CheckSuperWeapon9() == 1 then
			-- 物品描述
			local EquipName,nByQual = CachedTarget:GetSuperWeaponNameAndQual(0)
			if EquipName ~= nil then
				g_OtherSuperWeapon9_DIYSkill_WeaponText:SetText(ScriptGlobal_Format("#{JXSQ_170829_237}", EquipName))
			end
			-- 蒙红
			g_OtherSuperWeapon9_DIYSkill_WeaponMask:Hide()
		-- 八星突破
		elseif CachedTarget:CheckSuperWeaponTopo() == 1 then
			-- 物品描述
			local EquipName,nByQual = CachedTarget:GetSuperWeaponNameAndQual(0)
			if EquipName ~= nil and nByQual>100 then
				local nFit = math.mod(nByQual,100)
				if nFit>=1 and nFit<=20 then
					g_OtherSuperWeapon9_DIYSkill_WeaponText:SetText(ScriptGlobal_Format("#{JXSQ_170829_236}", EquipName, nFit))
				end
			end
			-- 蒙红
			g_OtherSuperWeapon9_DIYSkill_WeaponMask:Hide()
		-- 非神器
		else
			-- 物品描述
			g_OtherSuperWeapon9_DIYSkill_WeaponText:SetText("#{JXSQ_170829_235}")
			-- 蒙红
			g_OtherSuperWeapon9_DIYSkill_WeaponMask:Show()
		end
		
		-- 更新技能
		--OtherSuperWeapon9_DIYSkill_MainUpdateSkill()
		OtherSuperWeapon9_DIYSkill_MainUpdateSkill(theAction:GetItemID())
		
		-- 更新插槽
		OtherSuperWeapon9_DIYSkill_MainUpdateSlots()
		
	else
		
		-- 界面重置
		OtherSuperWeapon9_DIYSkill_MouseRClick()
		
	end	
	
end

--**********************************
-- 神器DIY技能--更新主动技能插槽
--**********************************
function OtherSuperWeapon9_DIYSkill_MainUpdateSkill(itemID)

	-- 技能清空
	OtherSuperWeapon9_DIYSkill_MainResumeSkill()
	
	-- 未装入神器
	if g_OtherSuperWeapon9_DIYSkill_WeaponIndex < 0 then
		return
	end	
	if itemID == nil or itemID < 0 then
		return
	end
	
	-- 如果有武器则显示默认技能说明
	g_OtherSuperWeapon9_DIYSkill_SkillText:SetText("#{JXSQ_170829_240}")

	--未激活主动技能
	local nSkillId = CachedTarget:GetSuperWeaponDIYSkillData("SKILLID")
	if nSkillId == nil or nSkillId <= 0 then
		return
	end
	
	-- 获得神器技能
	local theActionSkill = EnumAction(itemID , "superweapondiyskill");
	if theActionSkill:GetID() ~= 0 and nSkillId == theActionSkill:GetDefineID() then
		g_OtherSuperWeapon9_DIYSkill_SkillSlot:SetActionItem(theActionSkill:GetID());
		g_OtherSuperWeapon9_DIYSkill_SkillMask:Hide()
		-- 技能说明
		g_OtherSuperWeapon9_DIYSkill_SkillText:SetText("#{JXSQ_170829_239}")

--		-- 根据插槽1是否解锁决定客户端是否可以使用技能--特写
--		local slotLevel = CachedTarget:GetSuperWeaponDIYSkillData("SLOTLEVEL",1)
--		if slotLevel ~= nil and slotLevel > 0 then
--			-- 技能可用
--			g_OtherSuperWeapon9_DIYSkill_SkillMask:Hide()
--		else
--			-- 技能不可用
--			g_OtherSuperWeapon9_DIYSkill_SkillMask:Show()
--		end
	end

end

--**********************************
-- 神器DIY技能--更新主动技能插槽
--**********************************
function OtherSuperWeapon9_DIYSkill_MainUpdateSlots()
	-- 插槽清空
	--g_OtherSuperWeapon9_DIYSkill_SlotIndex = 0
	for nIndex=1, g_OtherSuperWeapon9_DIYSkill_SlotNum do		
		OtherSuperWeapon9_DIYSkill_MainResumeSlot(nIndex)
	end
		
	-- 未装入神器
	if g_OtherSuperWeapon9_DIYSkill_WeaponIndex < 0 then
		return
	end
	
	-- 更新插槽
	for nIndex=1, g_OtherSuperWeapon9_DIYSkill_SlotNum do			
		OtherSuperWeapon9_DIYSkill_MainUpdateSlot(nIndex)
	end
	
end

--**********************************
-- 神器DIY技能--更新主动技能插槽
--**********************************
function OtherSuperWeapon9_DIYSkill_MainUpdateSlot(nIndex)

	-- 未放入神器
	if g_OtherSuperWeapon9_DIYSkill_WeaponIndex < 0 then
		return
	end
	
	-- 参数不对
	if nIndex == nil or nIndex <= 0 or nIndex > g_OtherSuperWeapon9_DIYSkill_SlotNum then
		return
	end
	
	-- 获得当前插槽的等级
	local slotLevel = CachedTarget:GetSuperWeaponDIYSkillData("SLOTLEVEL",nIndex)
	if slotLevel == nil or slotLevel < 0 then
		return
	end
	
	-- 未解锁
	if slotLevel == 0 then
		return
	end
	
	-- 下面是已解锁的显示~~~

	-- 插槽解锁
	g_OtherSuperWeapon9_DIYSkill_SlotImage[nIndex]:Hide()
	
	-- 隐藏解锁信息
	g_OtherSuperWeapon9_DIYSkill_SlotLock[nIndex]:Hide()	
	
	-- 等级信息显示
	g_OtherSuperWeapon9_DIYSkill_SlotLevel[nIndex]:Show()
	g_OtherSuperWeapon9_DIYSkill_SlotLevel[nIndex]:SetText(ScriptGlobal_Format("#{JXSQ_170804_73}", slotLevel))
	
	-- 名称信息显示
	--g_OtherSuperWeapon9_DIYSkill_SlotSkill[nIndex]:SetText("")
	
	-- 技能效果显示
	g_OtherSuperWeapon9_DIYSkill_SlotButton[nIndex]:SetProperty("NormalImage", "")
	local tip = ScriptGlobal_Format("#{JXSQ_170804_74}", g_OtherSuperWeapon9_DIYSkill_Data[nIndex].nameText)
	g_OtherSuperWeapon9_DIYSkill_SlotButton[nIndex]:SetToolTip("")
	
	-- 获得当前插槽技能
	local impactIndex = CachedTarget:GetSuperWeaponDIYSkillData("IMPACTINDEX",nIndex)
	if impactIndex == nil or impactIndex <= 0 then
		return
	end	
	local slotType, nCostNum, nSkillId = DataPool:GetSuperWeaponDIYSkillActiveData(impactIndex)
	if nCostNum == nil or nCostNum < 0 or nSkillId == nil or nSkillId <= 0 then
		return
	end	
	
	-- 名称信息显示
	--g_OtherSuperWeapon9_DIYSkill_SlotSkill[nIndex]:Show()
	--local bRet,skillName = DataPool:GetSkillName(nSkillId)
	--if bRet == 1 then
		-- 判断技能效果激活状态
		--local bActive = 1--CachedTarget:GetTargetSuperWeaponDIYSkillActive(impactIndex-1)
		--if bActive == nil or bActive ~= 1 then
		--	g_OtherSuperWeapon9_DIYSkill_SlotSkill[nIndex]:SetText(""..skillName.."#{JXSQ_170828_199}")
		--else
			--g_OtherSuperWeapon9_DIYSkill_SlotSkill[nIndex]:SetText(skillName)
		--end
	--end
	
	-- 技能效果框
	local bRet1,skillName = DataPool:GetSkillName(nSkillId)
	local bRet,iconName = DataPool:GetSkillIconName(nSkillId)
	if bRet == 1 and bRet1 == 1 then
		local curIcon = GetIconFullName(iconName)
		g_OtherSuperWeapon9_DIYSkill_SlotButton[nIndex]:SetProperty("NormalImage", curIcon)
		local bRetDesc,strDesc = DataPool:GetSuperWeaponDIYSkillDesc(nSkillId, slotLevel)
		if bRetDesc == 1 then		
			g_OtherSuperWeapon9_DIYSkill_SlotButton[nIndex]:SetToolTip(skillName.."#r"..strDesc)
		end
	end
	
end

--**********************************
-- 神器DIY技能--插槽选中
--**********************************
function OtherSuperWeapon9_DIYSkill_MainButtonSkill(nIndex)

	if nIndex == nil or nIndex <= 0 or nIndex > g_OtherSuperWeapon9_DIYSkill_SlotNum then
		return
	end
	
	-- 重复点击同一个插槽则不再刷新，如果想重刷可以把g_OtherSuperWeapon9_DIYSkill_SlotIndex重置
	if g_OtherSuperWeapon9_DIYSkill_SlotIndex == nIndex then
		return			 
	end
	
	-- 删除上次选中状态
	if g_OtherSuperWeapon9_DIYSkill_SlotIndex > 0 and g_OtherSuperWeapon9_DIYSkill_SlotIndex <= g_OtherSuperWeapon9_DIYSkill_SlotNum then
		g_OtherSuperWeapon9_DIYSkill_SlotSelect[g_OtherSuperWeapon9_DIYSkill_SlotIndex]:Hide()
	end
	
	-- 记录当前选中的插槽
	g_OtherSuperWeapon9_DIYSkill_SlotIndex = nIndex
	g_OtherSuperWeapon9_DIYSkill_SlotSelect[g_OtherSuperWeapon9_DIYSkill_SlotIndex]:Show()
	
	-- 刷新界面内容
	g_OtherSuperWeapon9_DIYSkill_ImpactIndex = 0--切换技能效果页时要清除选中项
	OtherSuperWeapon9_DIYSkill_SkillUpdate()

end

--**********************************
-- 神器DIY技能--具体效果页面--清空
--**********************************
function OtherSuperWeapon9_DIYSkill_SkillReset()

	-- 标题
	g_OtherSuperWeapon9_DIYSkill_ImpactTitle:SetText("")	
	-- 效果名称
	g_OtherSuperWeapon9_DIYSkill_ImpactName:SetText("")
	-- 效果描述
	g_OtherSuperWeapon9_DIYSkill_ImpactIntro:SetText("")
	-- 效果消耗
	--g_OtherSuperWeapon9_DIYSkill_ImpactCost:SetText("")
	
	-- 效果图标背景
	for nSlotIndex=1, g_OtherSuperWeapon9_DIYSkill_SlotNum do
		g_OtherSuperWeapon9_DIYSkill_ImpactBK[nSlotIndex]:Hide()
	end
	
	-- 效果列表数值
	for nIndex=1, g_OtherSuperWeapon9_DIYSkill_ImpactNum do	
		g_OtherSuperWeapon9_DIYSkill_ImpactId[nIndex] = 0		
	end
	
	-- 变量
	g_OtherSuperWeapon9_DIYSkill_SlotIndex = 0 
	g_OtherSuperWeapon9_DIYSkill_ImpactIndex = 0
	g_OtherSuperWeapon9_DIYSkill_EmbedImpactId = 0
	
end

--**********************************
-- 神器DIY技能--具体效果页面--效果清空
--**********************************
function OtherSuperWeapon9_DIYSkill_SkillResumeImpact(nIndex)

	if g_OtherSuperWeapon9_DIYSkill_SlotIndex <= 0 or g_OtherSuperWeapon9_DIYSkill_SlotIndex > g_OtherSuperWeapon9_DIYSkill_SlotNum then
		return
	end
		
	if nIndex == nil or nIndex <= 0 or nIndex > g_OtherSuperWeapon9_DIYSkill_ImpactNum then
		return 
	end
	
	-- 效果
	g_OtherSuperWeapon9_DIYSkill_ImpactIcon[g_OtherSuperWeapon9_DIYSkill_SlotIndex][nIndex]:SetProperty("NormalImage", "")
	g_OtherSuperWeapon9_DIYSkill_ImpactIcon[g_OtherSuperWeapon9_DIYSkill_SlotIndex][nIndex]:SetToolTip("")
	g_OtherSuperWeapon9_DIYSkill_ImpactAnimate[g_OtherSuperWeapon9_DIYSkill_SlotIndex][nIndex]:Hide()
	g_OtherSuperWeapon9_DIYSkill_ImpactMask[g_OtherSuperWeapon9_DIYSkill_SlotIndex][nIndex]:Hide()

end

--**********************************
-- 神器DIY技能--具体效果页面--更新
--**********************************
function OtherSuperWeapon9_DIYSkill_SkillUpdate()

	if g_OtherSuperWeapon9_DIYSkill_SlotIndex <= 0 or g_OtherSuperWeapon9_DIYSkill_SlotIndex > g_OtherSuperWeapon9_DIYSkill_SlotNum then
		return
	end
	
	-- 标题
	g_OtherSuperWeapon9_DIYSkill_ImpactTitle:SetText(g_OtherSuperWeapon9_DIYSkill_Data[g_OtherSuperWeapon9_DIYSkill_SlotIndex].title)
	
	-- 隐藏背景图
	for nSlotIndex=1, g_OtherSuperWeapon9_DIYSkill_SlotNum do	
		g_OtherSuperWeapon9_DIYSkill_ImpactBK[nSlotIndex]:Hide()
	end	
	 
	-- 效果框清空
	g_OtherSuperWeapon9_DIYSkill_ImpactBK[g_OtherSuperWeapon9_DIYSkill_SlotIndex]:Show()
	for nIndex=1, g_OtherSuperWeapon9_DIYSkill_ImpactNum do
		OtherSuperWeapon9_DIYSkill_SkillResumeImpact(nIndex)		
		g_OtherSuperWeapon9_DIYSkill_ImpactId[nIndex] = 0
	end
	
	-- 获得插槽等级，控制具体效果数值显示
	local slotLevel = 0
	if g_OtherSuperWeapon9_DIYSkill_WeaponIndex >= 0 then
		slotLevel = CachedTarget:GetSuperWeaponDIYSkillData("SLOTLEVEL",g_OtherSuperWeapon9_DIYSkill_SlotIndex)
	end
	if slotLevel == nil or slotLevel <= 0 then
		slotLevel = 1
	end
	
	-- 显示所有的效果
	local curIndex = 1
	for nId = 1, g_OtherSuperWeapon9_DIYSkill_ImpactNum * g_OtherSuperWeapon9_DIYSkill_SlotNum do	
		-- 获得激活数据
		local slotType, nCostNum, nSkillId = DataPool:GetSuperWeaponDIYSkillActiveData(nId)
		--同一类型的则显示
		if slotType ~= nil and slotType > 0 and slotType == g_OtherSuperWeapon9_DIYSkill_SlotIndex then
		
			-- 效果图标
			local bRet,iconName = DataPool:GetSkillIconName(nSkillId)
			if bRet == 1 then
				local curIcon = GetIconFullName(iconName)
				g_OtherSuperWeapon9_DIYSkill_ImpactIcon[g_OtherSuperWeapon9_DIYSkill_SlotIndex][curIndex]:SetProperty("NormalImage",curIcon)
			else
				g_OtherSuperWeapon9_DIYSkill_ImpactIcon[g_OtherSuperWeapon9_DIYSkill_SlotIndex][curIndex]:SetProperty("NormalImage", "")
			end		
			-- 效果图标tips
			local bRet,skillName = DataPool:GetSkillName(nSkillId)
			--local bRet,skillDesc = DataPool:GetSuperWeaponDIYSkillDesc(nSkillId, slotLevel)
			if bRet == 1 then
				g_OtherSuperWeapon9_DIYSkill_ImpactIcon[g_OtherSuperWeapon9_DIYSkill_SlotIndex][curIndex]:SetToolTip(skillName)
			else
				g_OtherSuperWeapon9_DIYSkill_ImpactIcon[g_OtherSuperWeapon9_DIYSkill_SlotIndex][curIndex]:SetToolTip("")
			end			
			-- 效果蒙红
			--local bActive = 1-- CachedTarget:GetTargetSuperWeaponDIYSkillActive(nId-1)
			--if bActive == 1 then--已激活什么都不显示
			--	g_OtherSuperWeapon9_DIYSkill_ImpactMask[g_OtherSuperWeapon9_DIYSkill_SlotIndex][curIndex]:Hide()
			--else--未激活则需要显示
			--	g_OtherSuperWeapon9_DIYSkill_ImpactMask[g_OtherSuperWeapon9_DIYSkill_SlotIndex][curIndex]:Show()
			--end	
							
			-- 记录效果id
			g_OtherSuperWeapon9_DIYSkill_ImpactId[curIndex] = nId
			curIndex = curIndex + 1

		end
	end
	
	-- 设置默认选中
	g_OtherSuperWeapon9_DIYSkill_EmbedImpactId = 0
	local nImpactId = CachedTarget:GetSuperWeaponDIYSkillData("IMPACTINDEX",g_OtherSuperWeapon9_DIYSkill_SlotIndex)
	if nImpactId ~= nil and nImpactId > 0 then
		-- 选中镶嵌的内容
		for i=1, g_OtherSuperWeapon9_DIYSkill_ImpactNum do
			if g_OtherSuperWeapon9_DIYSkill_ImpactId[i] == nImpactId then
				-- 记录镶嵌数据
				g_OtherSuperWeapon9_DIYSkill_EmbedImpactId = nImpactId
				-- 显示使用中图标
				g_OtherSuperWeapon9_DIYSkill_ImpactMask[g_OtherSuperWeapon9_DIYSkill_SlotIndex][i]:Show()
				-- 设置当前选中项
				if g_OtherSuperWeapon9_DIYSkill_ImpactIndex <= 0 or g_OtherSuperWeapon9_DIYSkill_ImpactIndex > g_OtherSuperWeapon9_DIYSkill_ImpactNum then
					g_OtherSuperWeapon9_DIYSkill_ImpactIndex = i
				end
				break
			end
		end
	end
	
	-- 不存在使用中，则默认选中第一个
	if g_OtherSuperWeapon9_DIYSkill_ImpactIndex <= 0 or g_OtherSuperWeapon9_DIYSkill_ImpactIndex > g_OtherSuperWeapon9_DIYSkill_ImpactNum then
		g_OtherSuperWeapon9_DIYSkill_ImpactIndex = 1
	end
	if g_OtherSuperWeapon9_DIYSkill_ImpactId[g_OtherSuperWeapon9_DIYSkill_ImpactIndex] > 0 then
		g_OtherSuperWeapon9_DIYSkill_ImpactAnimate[g_OtherSuperWeapon9_DIYSkill_SlotIndex][g_OtherSuperWeapon9_DIYSkill_ImpactIndex]:Show()
	end
	
	-- 更新当前选中效果具体信息
	OtherSuperWeapon9_DIYSkill_SkillUpdateInfo()
		
end

--**********************************
-- 神器DIY技能--具体效果页面--更新当前选中效果具体信息
--**********************************
function OtherSuperWeapon9_DIYSkill_SkillUpdateInfo()

	-- 效果名称
	g_OtherSuperWeapon9_DIYSkill_ImpactName:SetText("")
	-- 效果描述
	g_OtherSuperWeapon9_DIYSkill_ImpactIntro:SetText("")
	-- 效果消耗
	--g_OtherSuperWeapon9_DIYSkill_ImpactCost:SetText("")

	-- 当前选项
	if g_OtherSuperWeapon9_DIYSkill_SlotIndex <= 0 or g_OtherSuperWeapon9_DIYSkill_SlotIndex > g_OtherSuperWeapon9_DIYSkill_SlotNum then
		return
	end
	if g_OtherSuperWeapon9_DIYSkill_ImpactIndex <= 0 or g_OtherSuperWeapon9_DIYSkill_ImpactIndex > g_OtherSuperWeapon9_DIYSkill_ImpactNum then
		return
	end
	
	-- 选中效果id
	local nImpactId = g_OtherSuperWeapon9_DIYSkill_ImpactId[g_OtherSuperWeapon9_DIYSkill_ImpactIndex]
	if nImpactId == nil or nImpactId <= 0 then
		return
	end
	
	-- 获得激活数据
	local slotType, nCostNum, nSkillId = DataPool:GetSuperWeaponDIYSkillActiveData(nImpactId)
	if slotType == nil or slotType <= 0 or slotType ~= g_OtherSuperWeapon9_DIYSkill_SlotIndex then
		return
	end	
	
	-- 获得插槽等级，控制具体效果数值显示
	local slotLevel = 0
	if g_OtherSuperWeapon9_DIYSkill_WeaponIndex >= 0 then
		slotLevel = CachedTarget:GetSuperWeaponDIYSkillData("SLOTLEVEL",g_OtherSuperWeapon9_DIYSkill_SlotIndex)
	end
	if slotLevel == nil or slotLevel <= 0 then
		slotLevel = 1
	end
	
	-- 名称
	local bRet,skillName = DataPool:GetSkillName(nSkillId)
	if bRet == 1 then
		g_OtherSuperWeapon9_DIYSkill_ImpactName:SetText(ScriptGlobal_Format("#{JXSQ_170829_210}", skillName))
	else
		g_OtherSuperWeapon9_DIYSkill_ImpactName:SetText("")
	end

	-- 描述
	local bRet,skillDesc = DataPool:GetSuperWeaponDIYSkillDesc(nSkillId, slotLevel)
	if bRet == 1 then
		g_OtherSuperWeapon9_DIYSkill_ImpactIntro:SetText(ScriptGlobal_Format("#{JXSQ_170829_211}", skillDesc))
	else
		g_OtherSuperWeapon9_DIYSkill_ImpactIntro:SetText("")
	end
	
	-- 所需道具
	--local bActive = 1-- CachedTarget:GetTargetSuperWeaponDIYSkillActive(nImpactId-1)
	--if bActive == 1 then--已激活什么都不显示
	--	g_OtherSuperWeapon9_DIYSkill_ImpactCost:SetText("")
	--else--未激活则需要显示激活消耗
	--	local costNum = ScriptGlobal_Format(g_OtherSuperWeapon9_DIYSkill_Data[g_OtherSuperWeapon9_DIYSkill_SlotIndex].costText, nCostNum)
	--	g_OtherSuperWeapon9_DIYSkill_ImpactCost:SetText(costNum)
	--end	
	
	-- 镶嵌的效果显示使用中
	--if nImpactId == g_OtherSuperWeapon9_DIYSkill_EmbedImpactId then
	--	g_OtherSuperWeapon9_DIYSkill_ImpactCost:SetText("#{JXSQ_170804_101}")
	--end

end

--**********************************
-- 神器DIY技能--具体效果页面--选中一项
--**********************************
function OtherSuperWeapon9_DIYSkill_SkillButtonSelect(nIndex)

	if g_OtherSuperWeapon9_DIYSkill_SlotIndex <= 0 or g_OtherSuperWeapon9_DIYSkill_SlotIndex > g_OtherSuperWeapon9_DIYSkill_SlotNum then
		return
	end
	if nIndex == nil or nIndex <= 0 or nIndex > g_OtherSuperWeapon9_DIYSkill_ImpactNum then
		return 
	end
	
	-- 与上次选择相同
	--if g_OtherSuperWeapon9_DIYSkill_ImpactIndex == nIndex then
	--	return
	--end
	
	-- 删除上次状态
	if g_OtherSuperWeapon9_DIYSkill_ImpactIndex > 0 and g_OtherSuperWeapon9_DIYSkill_ImpactIndex <= g_OtherSuperWeapon9_DIYSkill_ImpactNum then
		g_OtherSuperWeapon9_DIYSkill_ImpactAnimate[g_OtherSuperWeapon9_DIYSkill_SlotIndex][g_OtherSuperWeapon9_DIYSkill_ImpactIndex]:Hide()
	end

	-- 记录选项
	g_OtherSuperWeapon9_DIYSkill_ImpactIndex = nIndex
	
	-- 设置本次状态
	if g_OtherSuperWeapon9_DIYSkill_ImpactId[g_OtherSuperWeapon9_DIYSkill_ImpactIndex] > 0 then
		g_OtherSuperWeapon9_DIYSkill_ImpactAnimate[g_OtherSuperWeapon9_DIYSkill_SlotIndex][g_OtherSuperWeapon9_DIYSkill_ImpactIndex]:Show()
	end
	
	-- 更新当前选中效果具体信息
	OtherSuperWeapon9_DIYSkill_SkillUpdateInfo()
	
end

-- 关闭
function OtherSuperWeapon9_DIYSkill_CloseFunction()
	this:Hide()
end

--装备
function OtherSuperWeapon9_DIYSkill_SelfEquip_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenEquipFrame( "other" );
	OtherSuperWeapon9_DIYSkill_CloseFunction();
end

--资料
function OtherSuperWeapon9_DIYSkill_SelfData_Switch()
	Variable:SetVariable("OtherUnionPos", OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("other")
	OtherSuperWeapon9_DIYSkill_CloseFunction();
end

--珍兽
function OtherSuperWeapon9_DIYSkill_Pet_Switch()
	Variable:SetVariable("OtherUnionPos", OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPetFrame("other");
	OtherSuperWeapon9_DIYSkill_CloseFunction();
end

--子女
function OtherSuperWeapon9_DIYSkill_Infant_Switch()
	Variable:SetVariable("OtherUnionPos", OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:Other_ToggleInfantPage();
	if bRet == 1 then
		OtherSuperWeapon9_DIYSkill_CloseFunction();
	end
end

--武魂
function OtherSuperWeapon9_DIYSkill_Wuhun_Switch()
	Variable:SetVariable("OtherUnionPos", OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherWuhun();
	OtherSuperWeapon9_DIYSkill_CloseFunction();
end

--秘籍
function OtherSuperWeapon9_DIYSkill_Miji_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherMiji();
	OtherSuperWeapon9_DIYSkill_CloseFunction();
end

--真元
function OtherSuperWeapon9_DIYSkill_ZhenYuan_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleTargetZhenYuanPage();
	if bRet == 1 then
		OtherSuperWeapon9_DIYSkill_CloseFunction();
	end
end

--经脉
function OtherSuperWeapon9_DIYSkill_JingMai_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherJingMai();
end

--神鼎
function OtherSuperWeapon9_DIYSkill_ShenDing_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = SystemSetup:OpenOtherShenDing();
	if bRet == 1 then
		OtherSuperWeapon9_DIYSkill_CloseFunction()
	end
end

function OtherSuperWeapon9_DIYSkill_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage();
	if ( bRet == 1 ) then
		OtherSuperWeapon9_DIYSkill_CloseFunction()
	end
end

function OtherSuperWeapon9_DIYSkill_OpenBaoJian()
	Variable:SetVariable("OtherUnionPos", OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
	OtherSuperWeapon9_DIYSkill_CloseFunction();
end

function OtherSuperWeapon9_DIYSkill_OpenWuYi()
	Variable:SetVariable("OtherUnionPos", OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	OtherSuperWeapon9_DIYSkill_CloseFunction();
end

function OtherSuperWeapon9_DIYSkill_OpenShenQi()
end

--骑乘
function OtherSuperWeapon9_DIYSkill_Ride_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenRidePage("other");
	OtherSuperWeapon9_DIYSkill_CloseFunction();
end

function OtherSuperWeapon9_DIYSkill_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

function OtherSuperWeapon9_DIYSkill_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", OtherSuperWeapon9_DIYSkill_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end


function OtherSuperWeapon9_DIYSkill_ShowPage()

	for i = 1, table.getn(g_OtherSuperWeapon9_DIYSkill_Page) do
		g_OtherPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	OtherSuperWeapon9_DIYSkill_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_OtherPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_OtherSuperWeapon9_DIYSkill_Page) do
			if i ~= nOtherPageNumber then
				g_OtherPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_OtherPageOrder = {}
	g_OtherPageCount = 0
	for i = 1, table.getn(g_OtherSuperWeapon9_DIYSkill_Page) do
		if OtherSuperWeapon9_DIYSkill_CheckPage(i) == 1 then
			g_OtherPageCount = g_OtherPageCount + 1
			g_OtherPageButton[g_OtherPageCount]:Show()
			g_OtherPageButton[g_OtherPageCount]:SetText(g_OtherSuperWeapon9_DIYSkill_Page[i].Text)	
			g_OtherPageOrder[g_OtherPageCount] = i
		end
	end
	
end

function OtherSuperWeapon9_DIYSkill_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_OtherPageOrder[idx]
	
	if idx == 1 then--装备
		OtherSuperWeapon9_DIYSkill_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		OtherSuperWeapon9_DIYSkill_SelfData_Switch()
	elseif idx == 3 then--珍兽
		OtherSuperWeapon9_DIYSkill_Pet_Switch()
	elseif idx == 4 then--子女
		OtherSuperWeapon9_DIYSkill_Infant_Switch()
	elseif idx == 5 then--武魂
		OtherSuperWeapon9_DIYSkill_Wuhun_Switch()
	elseif idx == 6 then--秘籍
		OtherSuperWeapon9_DIYSkill_Miji_Page_Switch()
	elseif idx == 7 then--真元
		OtherSuperWeapon9_DIYSkill_ZhenYuan_Page_Switch()
	elseif idx == 8 then--经脉
		OtherSuperWeapon9_DIYSkill_JingMai_Page_Switch()
	elseif idx == 9 then--神鼎
		OtherSuperWeapon9_DIYSkill_ShenDing_Page_Switch()
	elseif idx == 10 then--侠印
		OtherSuperWeapon9_DIYSkill_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		OtherSuperWeapon9_DIYSkill_OpenBaoJian()
	elseif idx == 12 then--武意
		OtherSuperWeapon9_DIYSkill_OpenWuYi()
	elseif idx == 13 then--神器
		OtherSuperWeapon9_DIYSkill_OpenShenQi()
	elseif idx == 14 then--星盘
		OtherSuperWeapon9_DIYSkill_Armor_Page_Switch()
	elseif idx == 15 then--名物
		OtherSuperWeapon9_DIYSkill_CangPin_Page_Switch()
	end
end

function OtherSuperWeapon9_DIYSkill_CheckPage(idx)
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

function OtherSuperWeapon9_DIYSkill_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end


