
local TargetKfs_AttrEx_Text = {}
local TargetKfs_AttrEx_Value = {}
local TargetKfs_ATTREX_MAX_NUM = 10
local TargetKfs_Base_Original_Text = {}
local TargetKfs_Base_Original_Value = {}
local TargetKfs_Base_Text = {}
local TargetKfs_Base_Value = {}
local TargetKfs_Skills = {}
local TargetKfs_Magic

local TargetKfs_Magic_Image = {}
local TargetKfs_Skill_ID = {}
--风、地、水、火
local TargetKfs_Magic_tips = {"#{WH_090817_04}" , "#{WH_090817_05}","#{WH_090817_06}","#{WH_090817_07}","#{WH_090817_08}"}
--力量、灵气、体力、身法、平衡
local TargetKfs_Att_tips = {"#{WH_xml_XX(53)}" , "#{WH_xml_XX(52)}" , "#{WH_xml_XX(54)}"  , "#{WH_xml_XX(60)}" , "#{WH_xml_XX(01)}"}

local TargetKfs_AttrEx_Mask_L = {}
local	TargetKfs_AttrEx_Mask_R	=	{}

local g_TargetWuhun_Gem_Check_Buttons_red   --- 不能进行一键换宝石
local g_TargetWuhun_Gem_Check_Buttons_green --- 可以进行一键换宝石


local g_TargetWuhun_Frame_UnifiedPosition;

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_TargetWuhun_Page = {
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

function TargetWuhun_PreLoad()
	--open or close this window
	this:RegisterEvent("OPEN_OTHERPLAYER_WUHUN");
	--player quit game
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	--update equip
	this:RegisterEvent("OTHERPLAYER_UPDATE_EQUIP");

	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function TargetWuhun_OnLoad()
	--AttrEx text
	TargetKfs_AttrEx_Mask_L[1] = TargetWuhun_Property1_Text
	TargetKfs_AttrEx_Mask_L[2] = TargetWuhun_Property2_Text
	TargetKfs_AttrEx_Mask_L[3] = TargetWuhun_Property3_Text
	TargetKfs_AttrEx_Mask_L[4] = TargetWuhun_Property4_Text
	TargetKfs_AttrEx_Mask_L[5] = TargetWuhun_Property5_Text
	TargetKfs_AttrEx_Mask_L[6] = TargetWuhun_Property6_Text
	TargetKfs_AttrEx_Mask_L[7] = TargetWuhun_Property7_Text
	TargetKfs_AttrEx_Mask_L[8] = TargetWuhun_Property8_Text
	TargetKfs_AttrEx_Mask_L[9] = TargetWuhun_Property9_Text
	TargetKfs_AttrEx_Mask_L[10] = TargetWuhun_Property10_Text
	--AttrEx value
	TargetKfs_AttrEx_Mask_R[1] = TargetWuhun_Property1
	TargetKfs_AttrEx_Mask_R[2] = TargetWuhun_Property2
	TargetKfs_AttrEx_Mask_R[3] = TargetWuhun_Property3
	TargetKfs_AttrEx_Mask_R[4] = TargetWuhun_Property4
	TargetKfs_AttrEx_Mask_R[5] = TargetWuhun_Property5
	TargetKfs_AttrEx_Mask_R[6] = TargetWuhun_Property6
	TargetKfs_AttrEx_Mask_R[7] = TargetWuhun_Property7
	TargetKfs_AttrEx_Mask_R[8] = TargetWuhun_Property8
	TargetKfs_AttrEx_Mask_R[9] = TargetWuhun_Property9
	TargetKfs_AttrEx_Mask_R[10] = TargetWuhun_Property10

	TargetKfs_AttrEx_Text[1] = TargetWuhun_Property1_Text_UnVisible;
	TargetKfs_AttrEx_Text[2] = TargetWuhun_Property2_Text_UnVisible;
	TargetKfs_AttrEx_Text[3] = TargetWuhun_Property3_Text_UnVisible;
	TargetKfs_AttrEx_Text[4] = TargetWuhun_Property4_Text_UnVisible;
	TargetKfs_AttrEx_Text[5] = TargetWuhun_Property5_Text_UnVisible;
	TargetKfs_AttrEx_Text[6] = TargetWuhun_Property6_Text_UnVisible;
	TargetKfs_AttrEx_Text[7] = TargetWuhun_Property7_Text_UnVisible;
	TargetKfs_AttrEx_Text[8] = TargetWuhun_Property8_Text_UnVisible;
	TargetKfs_AttrEx_Text[9] = TargetWuhun_Property9_Text_UnVisible;
	TargetKfs_AttrEx_Text[10] = TargetWuhun_Property10_Text_UnVisible;

	TargetKfs_AttrEx_Value[1] = TargetWuhun_Property1_UnVisible;
	TargetKfs_AttrEx_Value[2] = TargetWuhun_Property2_UnVisible;
	TargetKfs_AttrEx_Value[3] = TargetWuhun_Property3_UnVisible;
	TargetKfs_AttrEx_Value[4] = TargetWuhun_Property4_UnVisible;
	TargetKfs_AttrEx_Value[5] = TargetWuhun_Property5_UnVisible;
	TargetKfs_AttrEx_Value[6] = TargetWuhun_Property6_UnVisible;
	TargetKfs_AttrEx_Value[7] = TargetWuhun_Property7_UnVisible;
	TargetKfs_AttrEx_Value[8] = TargetWuhun_Property8_UnVisible;
	TargetKfs_AttrEx_Value[9] = TargetWuhun_Property9_UnVisible;
	TargetKfs_AttrEx_Value[10] = TargetWuhun_Property10_UnVisible;
	--Original five text
	TargetKfs_Base_Original_Text[1] = TargetWuhun_OriginalStr_Text
	TargetKfs_Base_Original_Text[2] = TargetWuhun_OriginalNimbus_Text
	TargetKfs_Base_Original_Text[3] = TargetWuhun_OriginalPhysicalStrength_Text
	TargetKfs_Base_Original_Text[4] = TargetWuhun_OriginalStability_Text
	TargetKfs_Base_Original_Text[5] = TargetWuhun_OriginalFootwork_Text
	--Original five value
	TargetKfs_Base_Value[1] = TargetWuhun_OriginalStr
	TargetKfs_Base_Value[2] = TargetWuhun_OriginalNimbus
	TargetKfs_Base_Value[3] = TargetWuhun_OriginalPhysicalStrength
	TargetKfs_Base_Value[4] = TargetWuhun_OriginalStability
	TargetKfs_Base_Value[5] = TargetWuhun_OriginalDexterity
	--five text
	TargetKfs_Base_Text[1] = TargetWuhun_Str_Text
	TargetKfs_Base_Text[2] = TargetWuhun_Nimbus_Text
	TargetKfs_Base_Text[3] = TargetWuhun_PhysicalStrength_Text
	TargetKfs_Base_Text[4] = TargetWuhun_Stability_Text
	TargetKfs_Base_Text[5] = TargetWuhun_Footwork_Text
	--five value
	TargetKfs_Base_Original_Value[1] = TargetWuhun_Str
	TargetKfs_Base_Original_Value[2] = TargetWuhun_Nimbus
	TargetKfs_Base_Original_Value[3] = TargetWuhun_PhysicalStrength
	TargetKfs_Base_Original_Value[4] = TargetWuhun_Stability
	TargetKfs_Base_Original_Value[5] = TargetWuhun_Dexterity
	--skills
	TargetKfs_Skills[1] = TargetWuhun_Skill2
	TargetKfs_Skills[2] = TargetWuhun_Skill3
	TargetKfs_Skills[3] = TargetWuhun_Skill4
	--magic
	TargetKfs_Magic = TargetWuhun_Skill1
	--magic image

	TargetKfs_Magic_Image[1] = "set:Wuhun4 image:Wuhun4_2"
	TargetKfs_Magic_Image[2] = "set:Wuhun4 image:Wuhun4_1"
	TargetKfs_Magic_Image[3] = "set:Wuhun4 image:Wuhun4_4"
	TargetKfs_Magic_Image[4] = "set:Wuhun4 image:Wuhun4_3"

    g_TargetWuhun_Gem_Check_Buttons_red   = TargetWuhun_BaoShiCheck
    g_TargetWuhun_Gem_Check_Buttons_green = TargetWuhun_BaoShiCheckGreen
    TargetWuhun_BaoShiCheck_tips : Hide()

	g_TargetWuhun_Frame_UnifiedPosition=TargetWuhun_Frame:GetProperty("UnifiedPosition");

	g_TargetPageButton[1] = TargetWuhun_OtherEquip
	g_TargetPageButton[2] = TargetWuhun_OtherData
	g_TargetPageButton[3] = TargetWuhun_OtherPet
	g_TargetPageButton[4] = TargetWuhun_TargetInfant
	g_TargetPageButton[5] = TargetWuhun_TargetWuhun
	g_TargetPageButton[6] = TargetWuhun_Miji
	g_TargetPageButton[7] = TargetWuhun_ZhenYuan
	g_TargetPageButton[8] = TargetWuhun_JingMai
	g_TargetPageButton[9] = TargetWuhun_ShenDing
	g_TargetPageButton[10] = TargetWuhun_JueWei
	g_TargetPageButton[11] = TargetWuhun_BaoJian
	g_TargetPageButton[12] = TargetWuhun_WuYi
	g_TargetPageButton[13] = TargetWuhun_ShenQi
	g_TargetPageButton[14] = TargetWuhun_Armor
	g_TargetPageButton[15] = TargetWuhun_CangPin
	
end

function TargetWuhun_OnEvent(event)

	if( event == "HIDE_ON_SCENE_TRANSED") then

		this:Hide();
		return;

	elseif( event == "OPEN_OTHERPLAYER_WUHUN") then

		if (not CachedTarget:IsPresent(1)) then
			return;
		end

		if (not CachedTarget:CanGetTargetEquip()) then
			PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
			return
		end

		g_objCared = CachedTarget:GetData("NPCID", 1)
		if (type(g_objCared) ~="number") then
			PushDebugMessage ("#{JSCK_90507_1}")				-- 距离该玩家太远，无法查看资料。
			return
		end

		this:CareObject(g_objCared , 1)

		TargetWuhun_Update();
		
		TargetWuhun_ShowPage()

		this:Show();

	elseif( event == "OTHERPLAYER_UPDATE_EQUIP" and this:IsVisible() ) then
		Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1);
		TargetWuhun_Update()

	elseif (event == "ADJEST_UI_POS" ) then
		TargetWuhun_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TargetWuhun_Frame_On_ResetPos()
	end
end

--Update
function TargetWuhun_Update()
	--Tab
	TargetWuhun_TargetWuhun:SetCheck(1)
	TargetWuhun_Equip_Mask:Hide()
	--Pos
	local otherUnionPos = Variable:GetVariable("OtherUnionPos");
	if(otherUnionPos ~= nil) then
		TargetWuhun_Frame:SetProperty("UnifiedPosition", otherUnionPos);
	end
	--Title
	TargetWuhun_PageHeader:SetText("#gFF0FA0#{WH_xml_XX(95)}")

	local data = CachedTarget:GetKfsData("NAME")
	if data ~= nil then
		TargetWuhun_PageHeader:SetText("#gFF0FA0"..tostring(data))
	end

	--ICON
	TargetWuhun_Equip:SetActionItem(-1)
	local ActionKFS = EnumAction(18, "targetequip")
	TargetWuhun_Equip:SetActionItem(ActionKFS:GetID());
	--Model
	TargetWuhun_FakeObject:SetFakeObject("");
	CachedTarget:UpdateOtherKFSModel();
	TargetWuhun_FakeObject:SetFakeObject("Other_Wuhun");

	--NeedLv
	TargetWuhun_NeedLevel_Text:SetText("")

	data = CachedTarget:GetKfsData("NEEDLEVEL")
	if data ~= nil then
		TargetWuhun_NeedLevel_Text:SetText(tostring(data))
	end

	--Lv
	TargetWuhun_Level_Text:SetText("")

	data = CachedTarget:GetKfsData("LEVEL")
	if data ~= nil then
		TargetWuhun_Level_Text:SetText(tostring(data))
	end

	--ExtraLevel
	TargetWuhun_ExtraLevel_Text:SetText("")
	data = CachedTarget:GetKfsData("EXTRALEVEL")
	if data ~= nil then
		TargetWuhun_ExtraLevel_Text:SetText(tostring(data))
	end

	--AttactType
	TargetWuhun_Type:SetText("")

	data = CachedTarget:GetKfsData("ATTACT")
	if data ~= nil and data < 5 and data >= 0 then
		TargetWuhun_Type:SetText(TargetKfs_Att_tips[data + 1])
	end

	--Life
	TargetWuhun_Life_Text2:SetText("")

	data = CachedTarget:GetKfsData("LIFE")
	local maxLife = CachedTarget:GetKfsData("MAXLIFE")
	if data ~= nil then
		TargetWuhun_Life_Text2:SetText(tostring(data).."/"..tostring(maxLife))
	end

	--Exp
	TargetWuhun_Exp:SetText("#{WH_xml_XX(76)}")

	data = CachedTarget:GetKfsData("EXP")
	local needexp = CachedTarget:GetKfsData("NEEDEXP")
	if data ~= nil then
		TargetWuhun_Exp:SetText("#{WH_xml_XX(76)}"..tostring(data).."/"..tostring(needexp))
	end

	--GrowRate
	TargetWuhun_Growth1:SetText("")
	TargetWuhun_Growth1:SetToolTip("")
	TargetWuhun_Growth:SetText("")
	TargetWuhun_Growth:SetToolTip("")
	local grade = CachedTarget:GetKfsData("Grade")
	data = CachedTarget:GetKfsData("GROW")
	if data ~= nil and grade ~= nil then
		TargetWuhun_Growth1:SetText("#{WH_xml_XX(93)}")
		TargetWuhun_Growth1:SetToolTip("#{WH_090729_43}")
	  if grade == 0 then
			TargetWuhun_Growth:SetText("#G#{ZSKSSJ_PT}"..tostring(data))
	  elseif grade  == 1 then
			 TargetWuhun_Growth:SetText("#G#{ZSKSSJ_YX}"..tostring(data))
	  elseif grade == 2 then
	   		TargetWuhun_Growth:SetText("#G#{ZSKSSJ_JC}"..tostring(data))
	  elseif grade == 3 then
	  		TargetWuhun_Growth:SetText("#G#{ZSKSSJ_ZY}"..tostring(data))
	  elseif grade == 4 then
	  		TargetWuhun_Growth:SetText("#G#{ZSKSSJ_WM}"..tostring(data))
	  end
	end

	--AttrEx
	local slot = CachedTarget:GetKfsData("SLOT")
	for i=1,TargetKfs_ATTREX_MAX_NUM do

		TargetKfs_AttrEx_Text[i]:SetText("")
		TargetKfs_AttrEx_Value[i]:SetText("")

		if slot ~= nil and i <= slot then
			TargetKfs_AttrEx_Text[i]:Show()
			TargetKfs_AttrEx_Value[i]:Show()
		else
			TargetKfs_AttrEx_Text[i]:Hide()
			TargetKfs_AttrEx_Value[i]:Hide()
		end

		local iText , iValue = CachedTarget:GetKfsFixAttrEx(i - 1)
		if iText ~= nil and iText ~= "" and iValue ~= nil and iValue > 0  then
			TargetKfs_AttrEx_Text[i]:SetText(iText)
			TargetKfs_AttrEx_Value[i]:SetText("+"..tostring(iValue))
		end
	end

	--BaseAttr
	for i=1,5 do
		TargetKfs_Base_Original_Value[i]:SetText("")
		TargetKfs_Base_Value[i]:SetText("")

		data = CachedTarget:GetKfsBase(i - 1)
		if data ~= nil then
			TargetKfs_Base_Original_Value[i]:SetText("+"..tostring(data))
		end

		data = CachedTarget:GetFixKfsBase(i - 1)
		if data ~= nil then
			TargetKfs_Base_Value[i]:SetText("+"..tostring(data))
		end
	end

	--SKills
	TargetKfs_Skills[1]:SetActionItem(-1)
	TargetKfs_Skills[2]:SetActionItem(-1)
	TargetKfs_Skills[3]:SetActionItem(-1)

	local kfsID = -1
	if ActionKFS:GetID() ~= 0 then
		kfsID = ActionKFS:GetItemID();
	end

	for i=1, 3 do
		local theAction = EnumAction(kfsID * 3 + i -1 , "kfsskill");
		if theAction:GetID() ~= 0 then
			TargetKfs_Skills[i]:SetActionItem(theAction:GetID());
		end
	end

--	local nSumSkill = GetActionNum("skill");
--	TargetKfs_Skill_ID = {}
--	for i=1,3 do
--		local skillID = DataPool:GetKfsSkill( i - 1)
--		if skillID ~= nil and skillID > 0 then
--			TargetKfs_Skill_ID[i] = skillID
--		else
--			TargetKfs_Skill_ID[i] = -1
--		end
--	end

--	for i=1, nSumSkill do
--		theAction = EnumAction(i-1, "skill");
--		if theAction:GetOwnerXinfa() == -8888 then
--			if theAction:GetDefineID() == TargetKfs_Skill_ID[1] then
--				TargetKfs_Skills[1]:SetActionItem(theAction:GetID());
--
--			elseif theAction:GetDefineID() == TargetKfs_Skill_ID[2] then
--				TargetKfs_Skills[2]:SetActionItem(theAction:GetID());
--
--			elseif theAction:GetDefineID() == TargetKfs_Skill_ID[3] then
--				TargetKfs_Skills[3]:SetActionItem(theAction:GetID());
--			end
--		end
--	end

	--Magic
	TargetKfs_Magic:SetProperty("NormalImage" ,"" )
	TargetKfs_Magic:SetToolTip("")
	data = CachedTarget:GetKfsData("MAGIC")
	if data ~= nil and data < 5 and data >= 0 then
		TargetKfs_Magic:SetProperty("Empty", "False")
		if data > 0 then
			TargetKfs_Magic:SetProperty("NormalImage" , TargetKfs_Magic_Image[data] )
		end
		TargetKfs_Magic:SetToolTip(TargetKfs_Magic_tips[data + 1])
	end

    --- 显示人身上的宝石装备位
    TargetWuhun_UpdateGemContainer( )
end

--model turn left
function TargetWuhun_Model_TurnLeft(start)
	--start
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		TargetWuhun_FakeObject:RotateBegin(-0.3);
	--stop
	else
		TargetWuhun_FakeObject:RotateEnd();
	end
end

--model turn right
function TargetWuhun_Model_TurnRight(start)
	--start
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		TargetWuhun_FakeObject:RotateBegin(0.3);
	--stop
	else
		TargetWuhun_FakeObject:RotateEnd();
	end
end

--kfs hidden event
function TargetWuhun_OnHiden()
	TargetWuhun_FakeObject:SetFakeObject("");

    --- 关闭一键换宝石查看界面
    --- 这里复用下下面这个Event，3 表示关闭TargetEquipBaoshiCheck界面
    PushEvent( "GEM_CONTAINER_CHECK", 1, 3 )
end



--============================================================================================================
-- 打开玩家信息界面
function TargetWuhun_OtherData_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("other")
end
-- 打开玩家装备UI
function TargetWuhun_OtherEquip_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenEquipFrame("other");
end
-- 打开玩家宠物UI
function TargetWuhun_OtherPet_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPetFrame("other");
end

--神木王鼎
function TargetWuhun_TargetShenDing_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1);
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

--打开玩家骑乘UI
function TargetWuhun_OtherRide_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenRidePage("other");
end

--经脉
function TargetWuhun_OtherJingMai_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherJingMai();
end

--秘籍
function TargetWuhun_TargetMiji_Down()
	Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenOtherMiji();
	this:Hide()
end

function TargetWuhun_Frame_On_ResetPos()
  TargetWuhun_Frame:SetProperty("UnifiedPosition", g_TargetWuhun_Frame_UnifiedPosition);
end

function TargetWuhun_ZhenYuan_Down()
	Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleTargetZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end

local g_TargetWuhun_TypeList =
{
	[1]  = { name="#{WBSS_120727_34}", gemConIndex=0,  equipIndex=0,  },    --- 武器
	[2]  = { name="#{WBSS_120727_26}", gemConIndex=11, equipIndex=14, },    --- 护腕
	[3]  = { name="#{WBSS_120727_30}", gemConIndex=6,  equipIndex=6,  },    --- 戒指（上）
	[4]  = { name="#{WBSS_120727_31}", gemConIndex=8,  equipIndex=11, },    --- 戒指（下）
	[5]  = { name="#{WBSS_120727_32}", gemConIndex=9,  equipIndex=12, },    --- 护符（上）
	[6]  = { name="#{WBSS_120727_33}", gemConIndex=10, equipIndex=13, },    --- 护符（下）
	[7]  = { name="#{WBSS_120727_35}", gemConIndex=2,  equipIndex=2,  },    --- 衣服
	[8]  = { name="#{WBSS_120727_24}", gemConIndex=1,  equipIndex=1,  },    --- 帽子
	[9]  = { name="#{WBSS_120727_25}", gemConIndex=12, equipIndex=15, },    --- 肩膀
	[10] = { name="#{WBSS_120727_27}", gemConIndex=3,  equipIndex=3,  },    --- 手套
	[11] = { name="#{WBSS_120727_28}", gemConIndex=5,  equipIndex=5,  },    --- 腰带
	[12] = { name="#{WBSS_120727_29}", gemConIndex=4,  equipIndex=4,  },    --- 鞋子
	[13] = { name="#{WBSS_120727_36}", gemConIndex=7,  equipIndex=7,  },    --- 项链
	[14] = { name="#{WBSS_120727_37}", gemConIndex=13, equipIndex=17, },    --- 暗器
	[15] = { name="#{WBSS_120727_39}", gemConIndex=15, equipIndex=19, },    --- 龙纹
	[16] = { name="#{WBSS_120727_38}", gemConIndex=14, equipIndex=18, },    --- 武魂
}

--- 显示人身上的宝石装备位
function TargetWuhun_UpdateGemContainer( )

    --- 当玩家未学会万宝随身互换时，装备位宝石查看按钮为灰态
--    local gemSwitchSkillID = 278
--	if( Player:GetSkillInfo( gemSwitchSkillID, "learn") ) then
--	else
--        g_TargetWuhun_Gem_Check_Buttons_red   : Hide()
--        g_TargetWuhun_Gem_Check_Buttons_green : Hide()
--        return
--	end

    local ret = TargetWuhun_Can_SwitchGem( 16 )
    if ret == 1 then
        --- 正常态：玩家学会万宝随身互换，装备位上存在装备且所有装备位上的宝石都可以进行互换时
        g_TargetWuhun_Gem_Check_Buttons_green : Enable()
        g_TargetWuhun_Gem_Check_Buttons_green : Show()
        g_TargetWuhun_Gem_Check_Buttons_green : SetToolTip( "#{WBSS_120727_44}" )
        g_TargetWuhun_Gem_Check_Buttons_red   : Hide()
    else
        --- 异常态：玩家学会万宝随身互换，装备位上不存在装备或非所有装备位上的宝石都可以进行互换时
        g_TargetWuhun_Gem_Check_Buttons_red   : Enable()
        g_TargetWuhun_Gem_Check_Buttons_red   : Show()
        g_TargetWuhun_Gem_Check_Buttons_red   : SetToolTip( "#{WBSS_120727_44}" )
        g_TargetWuhun_Gem_Check_Buttons_green : Hide()
    end

end

function TargetWuhun_Can_SwitchGem( curSel )
    local equipPoint = g_TargetWuhun_TypeList[curSel].equipIndex
    local gemConPos  = g_TargetWuhun_TypeList[curSel].gemConIndex

    --- 得到装备上的宝石
    local equipIndex, gemHole, equipGem1, equipGem2, equipGem3, equipGem4 = LifeAbility : Get_OtherPlayerEquip_GemInfo( equipPoint )
    local equipTypeList = {}
    local gemIndexList  = {}
    gemIndexList[1] = equipGem1
    gemIndexList[2] = equipGem2
    gemIndexList[3] = equipGem3
    gemIndexList[4] = equipGem4
    if equipIndex ~= -1 then
        for i = 1, 4 do
            if gemIndexList[i] > 0 then
                equipTypeList[i] = TargetWuhun_GetGemTypeByIndex( gemIndexList[i] )
            else
                equipTypeList[i] = -1
            end
        end
    else
        --- 没有装备
        return 0
    end

    --- 其次得到装备位上的宝石类型
    local gemConTypeList  = { }
    local bHaveGemCon     = 0       --- 装备位上是否有宝石
    local conGem1, conGem2, conGem3, conGem4 = LifeAbility : Get_OtherPlayerEquip_GemContainerInfo( gemConPos )
    gemConTypeList[1] = conGem1
    gemConTypeList[2] = conGem2
    gemConTypeList[3] = conGem3
    gemConTypeList[4] = conGem4
    for i = 1, 4 do
        if gemConTypeList[i] > 0 then
            gemConTypeList[i] = TargetWuhun_GetGemTypeByIndex( gemConTypeList[i] )
            bHaveGemCon       = 1
        else
            gemConTypeList[i] = -1
        end
    end

    if bHaveGemCon == 0 then
        return 0
    end

    --- 判断装备位上的所有宝石对应的当前装备上的孔位是否都存在宝石
    for i = 1, 4 do
        --- 如果装备位上有宝石
        if gemConTypeList[i] > 0 then
            -- 判断装备位上的所有宝石对应的当前装备上的孔位是否都存在宝石
            if equipTypeList[i] <= 0 then
                return 0
            end
            equipTypeList[i] = gemConTypeList[i]
        end
    end

    --- 判断互换后，当前装备前三孔是否会出现同类型宝石
    if equipTypeList[1] > 0 then
        if ( equipTypeList[1] == equipTypeList[2] ) or ( equipTypeList[1] == equipTypeList[3] ) then
            return 0
        end
    end

    if equipTypeList[2] > 0 then
        if ( equipTypeList[1] == equipTypeList[2] ) or ( equipTypeList[2] == equipTypeList[3] ) then
            return 0
        end
    end

    if equipTypeList[3] > 0 then
        if ( equipTypeList[1] == equipTypeList[3] ) or ( equipTypeList[2] == equipTypeList[3] ) then
            return 0
        end
    end

    return 1
end

--- 根据物品序列号来获得物品的类型
function TargetWuhun_GetGemTypeByIndex( itemTblIdx )
    if itemTblIdx == nil or itemTblIdx <= 0 then
        return -1
    end

    local tmpValue = math.mod( itemTblIdx, 100000 )
    local itemType = math.floor( tmpValue / 1000 )
    return itemType
end

function TargetWuhun_BaoShiCheck_Clicked( btnIndex )
    if btnIndex < 0 or btnIndex > 16 then
        return
    end
    PushEvent( "GEM_CONTAINER_CHECK", btnIndex, 1 )
end

function TargetWuhun_TargetInfant_Down()
	Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:Other_ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetWuhun_JueWei_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenOtherJunXianPage();
	if bRet == 1 then
		this:Hide()
	end
end

function TargetWuhun_OpenBaoJian()
	Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenOtherFiveElementsPage()
end

function TargetWuhun_OpenWuYi()
	Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("TOGLE_OTHERMARTIAL_PAGE")
	this:Hide()
end

function TargetWuhun_OpenShenQi()
	Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1)
	PushEvent("OTHERSUPERWEAPONDIYSKILL_OPENUI")
	this:Hide()
end

function TargetWuhun_Armor_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("other")
end

function TargetWuhun_CangPin_Page_Switch()
	Variable:SetVariable("OtherUnionPos", TargetWuhun_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenOtherCangPin()
end

function TargetWuhun_ShowPage()

	for i = 1, table.getn(g_TargetWuhun_Page) do
		g_TargetPageButton[i]:Hide()
	end
	
	local nOtherPageNumber = tonumber(Variable:GetVariable("OtherPageNumber"));
	TargetWuhun_ClearPage()
	
	if nOtherPageNumber ~= nil and nOtherPageNumber ~= 0 then
		g_TargetPageButton[nOtherPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_TargetWuhun_Page) do
			if i ~= nOtherPageNumber then
				g_TargetPageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_TargetPageOrder = {}
	g_TargetPageCount = 0
	for i = 1, table.getn(g_TargetWuhun_Page) do
		if TargetWuhun_CheckPage(i) == 1 then
			g_TargetPageCount = g_TargetPageCount + 1
			g_TargetPageButton[g_TargetPageCount]:Show()
			g_TargetPageButton[g_TargetPageCount]:SetText(g_TargetWuhun_Page[i].Text)	
			g_TargetPageOrder[g_TargetPageCount] = i
		end
	end
	
end

function TargetWuhun_OnPageClicked(idx)

	Variable:SetVariable("OtherPageNumber", tostring(idx), 1);
	idx = g_TargetPageOrder[idx]
	
	if idx == 1 then--装备
		TargetWuhun_OtherEquip_Page_Switch();
	elseif idx == 2 then--资料
		TargetWuhun_OtherData_Page_Switch()
	elseif idx == 3 then--珍兽
		TargetWuhun_OtherPet_Page_Switch()
	elseif idx == 4 then--子女
		TargetWuhun_TargetInfant_Down()
	elseif idx == 5 then--武魂
		--TargetZhenYuan_TargetWuhun_Down()
	elseif idx == 6 then--秘籍
		TargetWuhun_TargetMiji_Down()
	elseif idx == 7 then--真元
		TargetWuhun_ZhenYuan_Down()
	elseif idx == 8 then--经脉
		TargetWuhun_OtherJingMai_Page_Switch()
	elseif idx == 9 then--神鼎
		TargetWuhun_TargetShenDing_Page_Switch()
	elseif idx == 10 then--侠印
		TargetWuhun_JueWei_Page_Switch()
	elseif idx == 11 then--宝鉴
		TargetWuhun_OpenBaoJian()
	elseif idx == 12 then--武意
		TargetWuhun_OpenWuYi()
	elseif idx == 13 then--神器
		TargetWuhun_OpenShenQi()
	elseif idx == 14 then--星盘
		TargetWuhun_Armor_Page_Switch()
	elseif idx == 15 then--名物
		TargetWuhun_CangPin_Page_Switch()
	end
end

function TargetWuhun_CheckPage(idx)
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

function TargetWuhun_ClearPage()
	Variable:SetVariable("OtherPageNumber", tostring(0), 1)
end


