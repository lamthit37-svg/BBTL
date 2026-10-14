local Kfs_AttrEx_Text = {}
local Kfs_AttrEx_Value = {}
local KFS_ATTREX_MAX_NUM = 10
local Kfs_Base_Original_Text = {}
local Kfs_Base_Original_Value = {}
local Kfs_Base_Text = {}
local Kfs_Base_Value = {}
local Kfs_Skills = {}
local Kfs_Magic

local Kfs_Magic_Image = {}
local Kfs_Skill_ID = {}
--风、地、水、火
local Kfs_Magic_tips = {"#{WH_090817_04}" , "#{WH_090817_05}","#{WH_090817_06}","#{WH_090817_07}","#{WH_090817_08}"}
--力量、灵气、体力、身法、平衡
local Kfs_Att_tips = {"#{WH_xml_XX(53)}" , "#{WH_xml_XX(52)}" , "#{WH_xml_XX(54)}"  , "#{WH_xml_XX(60)}" , "#{WH_xml_XX(01)}"}

local Kfs_AttrEx_Mask_L = {}
local	Kfs_AttrEx_Mask_R	=	{}

-- 界面的默认相对位置
local g_Wuhun_Frame_UnifiedXPosition;
local g_Wuhun_Frame_UnifiedYPosition;

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_Wuhun_Page = {
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

local g_Wuhun_PageButton = {}
local g_Wuhun_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

function Wuhun_PreLoad()
	--open or close this window
	this:RegisterEvent("TOGGLE_WUHUN_PAGE");
	--player quit game
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	--update equip
	this:RegisterEvent("REFRESH_EQUIP");
    this:RegisterEvent("GEM_CONTAINER_REFRESH");

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK");		--升级

	this:RegisterEvent("TOGGLE_UPDATE_INFANT"); --子女有变化 刷新按钮状态

	this:RegisterEvent("FINISH_MISSION");
	this:RegisterEvent("MARTIAL_UPDATE",false)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)
end

function Wuhun_OnLoad()
	--AttrEx text
	Kfs_AttrEx_Mask_L[1] = Wuhun_Property1_Text
	Kfs_AttrEx_Mask_L[2] = Wuhun_Property2_Text
	Kfs_AttrEx_Mask_L[3] = Wuhun_Property3_Text
	Kfs_AttrEx_Mask_L[4] = Wuhun_Property4_Text
	Kfs_AttrEx_Mask_L[5] = Wuhun_Property5_Text
	Kfs_AttrEx_Mask_L[6] = Wuhun_Property6_Text
	Kfs_AttrEx_Mask_L[7] = Wuhun_Property7_Text
	Kfs_AttrEx_Mask_L[8] = Wuhun_Property8_Text
	Kfs_AttrEx_Mask_L[9] = Wuhun_Property9_Text
	Kfs_AttrEx_Mask_L[10] = Wuhun_Property10_Text
	--AttrEx value
	Kfs_AttrEx_Mask_R[1] = Wuhun_Property1
	Kfs_AttrEx_Mask_R[2] = Wuhun_Property2
	Kfs_AttrEx_Mask_R[3] = Wuhun_Property3
	Kfs_AttrEx_Mask_R[4] = Wuhun_Property4
	Kfs_AttrEx_Mask_R[5] = Wuhun_Property5
	Kfs_AttrEx_Mask_R[6] = Wuhun_Property6
	Kfs_AttrEx_Mask_R[7] = Wuhun_Property7
	Kfs_AttrEx_Mask_R[8] = Wuhun_Property8
	Kfs_AttrEx_Mask_R[9] = Wuhun_Property9
	Kfs_AttrEx_Mask_R[10] = Wuhun_Property10

	Kfs_AttrEx_Text[1] = Wuhun_Property1_Text_UnVisible;
	Kfs_AttrEx_Text[2] = Wuhun_Property2_Text_UnVisible;
	Kfs_AttrEx_Text[3] = Wuhun_Property3_Text_UnVisible;
	Kfs_AttrEx_Text[4] = Wuhun_Property4_Text_UnVisible;
	Kfs_AttrEx_Text[5] = Wuhun_Property5_Text_UnVisible;
	Kfs_AttrEx_Text[6] = Wuhun_Property6_Text_UnVisible;
	Kfs_AttrEx_Text[7] = Wuhun_Property7_Text_UnVisible;
	Kfs_AttrEx_Text[8] = Wuhun_Property8_Text_UnVisible;
	Kfs_AttrEx_Text[9] = Wuhun_Property9_Text_UnVisible;
	Kfs_AttrEx_Text[10] = Wuhun_Property10_Text_UnVisible;

	Kfs_AttrEx_Value[1] = Wuhun_Property1_UnVisible;
	Kfs_AttrEx_Value[2] = Wuhun_Property2_UnVisible;
	Kfs_AttrEx_Value[3] = Wuhun_Property3_UnVisible;
	Kfs_AttrEx_Value[4] = Wuhun_Property4_UnVisible;
	Kfs_AttrEx_Value[5] = Wuhun_Property5_UnVisible;
	Kfs_AttrEx_Value[6] = Wuhun_Property6_UnVisible;
	Kfs_AttrEx_Value[7] = Wuhun_Property7_UnVisible;
	Kfs_AttrEx_Value[8] = Wuhun_Property8_UnVisible;
	Kfs_AttrEx_Value[9] = Wuhun_Property9_UnVisible;
	Kfs_AttrEx_Value[10] = Wuhun_Property10_UnVisible;
	--Original five text
	Kfs_Base_Original_Text[1] = Wuhun_OriginalStr_Text
	Kfs_Base_Original_Text[2] = Wuhun_OriginalNimbus_Text
	Kfs_Base_Original_Text[3] = Wuhun_OriginalPhysicalStrength_Text
	Kfs_Base_Original_Text[4] = Wuhun_OriginalStability_Text
	Kfs_Base_Original_Text[5] = Wuhun_OriginalFootwork_Text
	--Original five value
	Kfs_Base_Value[1] = Wuhun_OriginalStr
	Kfs_Base_Value[2] = Wuhun_OriginalNimbus
	Kfs_Base_Value[3] = Wuhun_OriginalPhysicalStrength
	Kfs_Base_Value[4] = Wuhun_OriginalStability
	Kfs_Base_Value[5] = Wuhun_OriginalDexterity
	--five text
	Kfs_Base_Text[1] = Wuhun_Str_Text
	Kfs_Base_Text[2] = Wuhun_Nimbus_Text
	Kfs_Base_Text[3] = Wuhun_PhysicalStrength_Text
	Kfs_Base_Text[4] = Wuhun_Stability_Text
	Kfs_Base_Text[5] = Wuhun_Footwork_Text
	--five value
	Kfs_Base_Original_Value[1] = Wuhun_Str
	Kfs_Base_Original_Value[2] = Wuhun_Nimbus
	Kfs_Base_Original_Value[3] = Wuhun_PhysicalStrength
	Kfs_Base_Original_Value[4] = Wuhun_Stability
	Kfs_Base_Original_Value[5] = Wuhun_Dexterity
	--skills
	Kfs_Skills[1] = Wuhun_Skill2
	Kfs_Skills[2] = Wuhun_Skill3
	Kfs_Skills[3] = Wuhun_Skill4
	--magic
	Kfs_Magic = Wuhun_Skill1
	--magic image

	Kfs_Magic_Image[1] = "set:Wuhun4 image:Wuhun4_2"
	Kfs_Magic_Image[2] = "set:Wuhun4 image:Wuhun4_1"
	Kfs_Magic_Image[3] = "set:Wuhun4 image:Wuhun4_4"
	Kfs_Magic_Image[4] = "set:Wuhun4 image:Wuhun4_3"

    Wuhun_BaoShiCheck_tips : Hide()

	-- 保存界面的默认相对位置
	g_Wuhun_Frame_UnifiedXPosition	= Wuhun_Frame : GetProperty("UnifiedXPosition");
	g_Wuhun_Frame_UnifiedYPosition	= Wuhun_Frame : GetProperty("UnifiedYPosition");

	g_Wuhun_PageButton[1] = Wuhun_SelfEquip
	g_Wuhun_PageButton[2] = Wuhun_SelfData
	g_Wuhun_PageButton[3] = Wuhun_Pet
	g_Wuhun_PageButton[4] = Wuhun_Infant
	g_Wuhun_PageButton[5] = Wuhun_Wuhun
	g_Wuhun_PageButton[6] = Wuhun_Xiulian
	g_Wuhun_PageButton[7] = Wuhun_Miji
	g_Wuhun_PageButton[8] = Wuhun_ZhenYuan
	g_Wuhun_PageButton[9] = Wuhun_JingMai
	g_Wuhun_PageButton[10] = Wuhun_ShenDing
	g_Wuhun_PageButton[11] = Wuhun_JueWei
	g_Wuhun_PageButton[12] = Wuhun_BaoJian
	g_Wuhun_PageButton[13] = Wuhun_WuYi
	g_Wuhun_PageButton[14] = Wuhun_ShenQi
	g_Wuhun_PageButton[15] = Wuhun_Armor
	g_Wuhun_PageButton[16] = Wuhun_CangPin
	g_Wuhun_PageButton[17] = Wuhun_OtherInfo
	
	g_Wuhun_PageMask[1] = Wuhun_SelfEquip_tips
	g_Wuhun_PageMask[2] = Wuhun_SelfData_tips
	g_Wuhun_PageMask[3] = Wuhun_Pet_tips
	g_Wuhun_PageMask[4] = Wuhun_Infant_tips
	g_Wuhun_PageMask[5] = Wuhun_Wuhun_tips
	g_Wuhun_PageMask[6] = Wuhun_Xiulian_tips
	g_Wuhun_PageMask[7] = Wuhun_Miji_tips
	g_Wuhun_PageMask[8] = Wuhun_ZhenYuan_tips
	g_Wuhun_PageMask[9] = Wuhun_JingMai_tips
	g_Wuhun_PageMask[10] = Wuhun_ShenDing_tips
	g_Wuhun_PageMask[11] = Wuhun_JueWei_tips
	g_Wuhun_PageMask[12] = Wuhun_BaoJian_tips
	g_Wuhun_PageMask[13] = Wuhun_WuYi_tips
	g_Wuhun_PageMask[14] = Wuhun_ShenQi_tips
	g_Wuhun_PageMask[15] = Wuhun_Armor_tips
	g_Wuhun_PageMask[16] = Wuhun_CangPin_tips
	g_Wuhun_PageMask[17] = Wuhun_OtherInfo_tips
	
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

function Wuhun_OnEvent(event)

	if ( event == "UPDATE_WILLGET_MISSION_TRACK" ) or (event=="TOGGLE_UPDATE_INFANT")  or (event == "FINISH_MISSION") then
		local nLevel =Player:GetLevel()
		Wuhun_Refresh_Page_Button(nLevel)
		Wuhun_ShowPage()
	end

	if( event == "HIDE_ON_SCENE_TRANSED") then

		this:Hide();
		return;

	elseif( event == "TOGGLE_WUHUN_PAGE") then

		if(this:IsVisible()) then
			this:Hide();
			return;
		end
		Wuhun_Update()
		this:Show();
		local nLevel =Player:GetLevel()
		Wuhun_Refresh_Page_Button(nLevel)
		Wuhun_ShowPage()

	elseif( event == "REFRESH_EQUIP" and this:IsVisible() ) then
		Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1);
		Wuhun_Update()
    elseif ( event == "GEM_CONTAINER_REFRESH" ) then
		Wuhun_Update()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		Wuhun_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		Wuhun_Frame_On_ResetPos()
	elseif (event == "MARTIAL_UPDATE" or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		Wuhun_RefreshWuYiTip()
	end

	if event == "UPDATE_TOY_TIP" then
		Wuhun_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		Wuhun_RefreshCangPinTip()
	end

end

function Wuhun_OnShowClick()
	local bc = Wuhun_Show:GetCheck()
	if bc == 1 then
		SystemSetup:SetShowWuhunObj(0)
	else
		SystemSetup:SetShowWuhunObj(1)
	end
end

--Update
function Wuhun_Update()
	local bc = SystemSetup:GetShowWuhunObj()
	if bc == 1 then
		Wuhun_Show:SetCheck(0)
	else
		Wuhun_Show:SetCheck(1)
	end
	--Tab
	Wuhun_Wuhun:SetCheck(1)
	--Pos
	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		Wuhun_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end
	--Title
	Wuhun_PageHeader:SetText("#gFF0FA0#{WH_xml_XX(95)}")

	local data = DataPool:GetKfsData("NAME")
	Kfs_Skills[1]:SetToolTip("")
	Kfs_Skills[2]:SetToolTip("")
	Kfs_Skills[3]:SetToolTip("")

	if data ~= nil then
		Wuhun_PageHeader:SetText("#gFF0FA0"..tostring(data))
		Kfs_Skills[1]:SetToolTip("#{WU_090908_02}")
		Kfs_Skills[2]:SetToolTip("#{WU_090908_03}")
		Kfs_Skills[3]:SetToolTip("#{WU_090908_04}")
	end

	--ICON
	Wuhun_Equip_Mask:Hide()

	Wuhun_Equip:SetActionItem(-1)

	local ActionKFS = EnumAction(18,"equip")
	Wuhun_Equip:SetActionItem(ActionKFS:GetID());
	if ActionKFS:IsLevelEnoughEquip() == 0 then
		Wuhun_Equip_Mask:Show()
	end
	--Model
	Wuhun_FakeObject:SetFakeObject( "" );
	DataPool:KFS_UpdateKFSModel()
	Wuhun_FakeObject:SetFakeObject("My_Wuhun");

	--NeedLv
	Wuhun_NeedLevel_Text:SetText("")

	data = DataPool:GetKfsData("NEEDLEVEL")
	if data ~= nil then
		Wuhun_NeedLevel_Text:SetText(tostring(data))
	end

	--Lv
	Wuhun_Level_Text:SetText("")
	data = DataPool:GetKfsData("LEVEL")
	if data ~= nil then
		Wuhun_Level_Text:SetText(tostring(data))
	end

	--ExtraLevel
	Wuhun_ExtraLevel_Text:SetText("")
	data = DataPool:GetKfsData("EXTRALEVEL")
	if data ~= nil then
		Wuhun_ExtraLevel_Text:SetText(tostring(data))
	end

	--AttactType
	Wuhun_Type:SetText("")

	data = DataPool:GetKfsData("ATTACT")
	if data ~= nil and data < 5 and data >= 0 then
		Wuhun_Type:SetText(Kfs_Att_tips[data + 1])
	end

	--Life
	Wuhun_Life_Text2:SetText("")

	data = DataPool:GetKfsData("LIFE")
	local maxLife = DataPool:GetKfsData("MAXLIFE")
	if data ~= nil then
		Wuhun_Life_Text2:SetText(tostring(data).."/"..tostring(maxLife))

		if data < 16 then
			Wuhun_Equip_Mask:Show()
		end
	end

	--Exp
	Wuhun_Exp:SetText("#{WH_xml_XX(76)}")

	data = DataPool:GetKfsData("EXP")
	local needexp = DataPool:GetKfsData("NEEDEXP")
	if data ~= nil then
		Wuhun_Exp:SetText("#{WH_xml_XX(76)}"..tostring(data).."/"..tostring(needexp))
	end

	--GrowRate
	Wuhun_Growth1:SetText("")
	Wuhun_Growth1:SetToolTip("")
	Wuhun_Growth:SetText("")
	Wuhun_Growth:SetToolTip("")
	local grade = DataPool:GetKfsData("Grade")
	data =DataPool:GetKfsData("GROW")
	if data ~= nil and grade ~= nil then
		Wuhun_Growth1:SetText("#{WH_xml_XX(93)}")
		Wuhun_Growth1:SetToolTip("#{WH_090729_43}")
	  if grade == 0 then
			Wuhun_Growth:SetText("#G#{ZSKSSJ_PT}"..tostring(data))
	  elseif grade == 1 then
			 Wuhun_Growth:SetText("#G#{ZSKSSJ_YX}"..tostring(data))
	  elseif grade == 2 then
	   		Wuhun_Growth:SetText("#G#{ZSKSSJ_JC}"..tostring(data))
	  elseif grade == 3 then
	  		Wuhun_Growth:SetText("#G#{ZSKSSJ_ZY}"..tostring(data))
	  elseif grade == 4 then
	  		Wuhun_Growth:SetText("#G#{ZSKSSJ_WM}"..tostring(data))
	  end
	end

	--AttrEx
	local slot = DataPool:GetKfsData("SLOT")
	for i=1,KFS_ATTREX_MAX_NUM do

		Kfs_AttrEx_Text[i]:SetText("")
		Kfs_AttrEx_Value[i]:SetText("")

		if slot ~= nil and i <= slot then
			Kfs_AttrEx_Text[i]:Show()
			Kfs_AttrEx_Value[i]:Show()
		else
			Kfs_AttrEx_Text[i]:Hide()
			Kfs_AttrEx_Value[i]:Hide()
		end

		local iText , iValue = DataPool:GetKfsFixAttrEx(i - 1)
		if iText ~= nil and iText ~= "" and iValue ~= nil and iValue > 0  then
			Kfs_AttrEx_Text[i]:SetText(iText)
			Kfs_AttrEx_Value[i]:SetText("+"..tostring(iValue))
		end
	end

	--BaseAttr
	for i=1,5 do
		Kfs_Base_Original_Value[i]:SetText("")
		Kfs_Base_Value[i]:SetText("")

		data = DataPool:GetKfsBase(i - 1)
		if data ~= nil then
			Kfs_Base_Original_Value[i]:SetText("+"..tostring(data))
		end

		data = DataPool:GetFixKfsBase(i - 1)
		if data ~= nil then
			Kfs_Base_Value[i]:SetText("+"..tostring(data))
		end
	end

	--SKills
	Kfs_Skills[1]:SetActionItem(-1)
	Kfs_Skills[2]:SetActionItem(-1)
	Kfs_Skills[3]:SetActionItem(-1)

	local nSumSkill = GetActionNum("skill");
	Kfs_Skill_ID = {}
	for i=1,3 do
		local skillID = DataPool:GetKfsSkill( i - 1)
		if skillID ~= nil and skillID > 0 then
			Kfs_Skill_ID[i] = skillID
		else
			Kfs_Skill_ID[i] = -1
		end
	end

	for i=1, nSumSkill do
		theAction = EnumAction(i-1, "skill");
		if theAction:GetOwnerXinfa() == -8888 then
			if theAction:GetDefineID() == Kfs_Skill_ID[1] then
				Kfs_Skills[1]:SetActionItem(theAction:GetID());

			elseif theAction:GetDefineID() == Kfs_Skill_ID[2] then
				Kfs_Skills[2]:SetActionItem(theAction:GetID());

			elseif theAction:GetDefineID() == Kfs_Skill_ID[3] then
				Kfs_Skills[3]:SetActionItem(theAction:GetID());
			end
		end
	end

	--Magic
	Kfs_Magic:SetProperty("NormalImage" ,"" )
	Kfs_Magic:SetToolTip("")
	data = DataPool:GetKfsData("MAGIC")
	if data ~= nil and data < 5 and data >= 0 then
		Kfs_Magic:SetProperty("Empty", "False")
		if data > 0 then
			Kfs_Magic:SetProperty("NormalImage" , Kfs_Magic_Image[data] )
		end
		Kfs_Magic:SetToolTip(Kfs_Magic_tips[data+1])

	end

    --- 更新一键换宝石显示
    Wuhun_UpdateGemContainer( )
end

--kfs equippoint clicked event
function Wuhun_Equip_Clicked( buttonIn )
	local button = tonumber( buttonIn );
	if( button == 1 ) then
		Wuhun_Equip:DoAction();
	else
		Wuhun_Equip:DoSubAction();
	end

end

--model turn left
function Wuhun_Model_TurnLeft(start)
	--start
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Wuhun_FakeObject:RotateBegin(-0.3);
	--stop
	else
		Wuhun_FakeObject:RotateEnd();
	end
end

--model turn right
function Wuhun_Model_TurnRight(start)
	--start
	if(start == 1 and CEArg:GetValue("MouseButton")=="LeftButton") then
		Wuhun_FakeObject:RotateBegin(0.3);
	--stop
	else
		Wuhun_FakeObject:RotateEnd();
	end
end

--kfs hidden event
function Wuhun_OnHiden()
	Wuhun_FakeObject:SetFakeObject("");
end

--player's other info
function Wuhun_OtherInfo_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1);
	OtherInfoPage();
end

--神木王鼎
function Wuhun_ShenDing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenShenDingPage();
	if nRet == 1 then
		Wuhun_Wuhun:SetCheck(0)
	else
		Wuhun_ShenDing:SetCheck(0)
	end
end

--player's ride
function Wuhun_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1);
	OpenRidePage();
end

--player's pet
function Wuhun_Pet_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1);
	TogglePetPage();
end

--player's info
function Wuhun_SelfData_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("self");
end

--player's equip
function Wuhun_SelfEquip_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1);
	OpenEquip(1);
end

--xiu lian
function Wuhun_Xiulian_Page_Switch()
    local nLevel = Player:GetData("LEVEL")
	if(nLevel >= 70) then
		Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1);
		XiuLianPage();
	else
	    Wuhun_Xiulian:SetCheck(0)
	    PushDebugMessage("#{XL_090707_62}")
	end
end

function Wuhun_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenJingMaiPage();
	if nRet == 1 then
		Wuhun_Wuhun:SetCheck(0)
	else
		Wuhun_JingMai:SetCheck(0)
	end
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Wuhun_Frame_On_ResetPos()

	Wuhun_Frame : SetProperty("UnifiedXPosition", g_Wuhun_Frame_UnifiedXPosition);
	Wuhun_Frame : SetProperty("UnifiedYPosition", g_Wuhun_Frame_UnifiedYPosition);

end

function Wuhun_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	if bRet == 1 then
		this:Hide()
	end
end

--- 更新一键换宝石显示
function Wuhun_UpdateGemContainer( )

    --- 当玩家未学会万宝随身互换时，装备位宝石查看按钮为灰态
    local gemSwitchSkillID = 278

	if( Player:GetSkillInfo( gemSwitchSkillID, "learn") ) then
        Wuhun_BaoShiCheck_tips : Hide()
	else
        Wuhun_BaoShiCheck      : Hide()
        Wuhun_BaoShiCheckGreen : Hide()
        Wuhun_BaoShiCheck_tips : Show()
        return
	end

    local ret = Wuhun_Can_SwitchGem(14, 18)
    if ret == 1 then
        --- 正常态：玩家学会万宝随身互换，装备位上存在装备且所有装备位上的宝石都可以进行互换时
        Wuhun_BaoShiCheckGreen : Enable()
        Wuhun_BaoShiCheckGreen : Show()
        Wuhun_BaoShiCheckGreen : SetToolTip( "#{WBSS_120727_44}" )
        Wuhun_BaoShiCheck      : Hide()
    else
        --- 异常态：玩家学会万宝随身互换，装备位上不存在装备或非所有装备位上的宝石都可以进行互换时
        Wuhun_BaoShiCheck       : Enable()
        Wuhun_BaoShiCheck       : Show()
        Wuhun_BaoShiCheck       : SetToolTip( "#{WBSS_120727_44}" )
        Wuhun_BaoShiCheckGreen  : Hide()
    end
end

function Wuhun_BaoShiCheck_Clicked( btnIndex )
     if btnIndex < 0 or btnIndex > 17 then
        return
    end
	PushEvent( "GEM_CONTAINER_CHECK", btnIndex, 0 )

end

function Wuhun_Can_SwitchGem(gem_con_index, equip_point)
    --- 得到装备上的宝石
    local equipTypeList = {}
    local isHaveEquip, gemIndex1, gemIndex2, gemIndex3, gemIndex4 = LifeAbility : SplitWearedEquipGem(equip_point)
    local gemIndexList  = {}
    gemIndexList[1] = gemIndex1
    gemIndexList[2] = gemIndex2
    gemIndexList[3] = gemIndex3
    gemIndexList[4] = gemIndex4
    if isHaveEquip == 1 then
        for i = 1, 4 do
            if gemIndexList[i] > 0 then
                equipTypeList[i] = SelfEquip_GetGemTypeByIndex( gemIndexList[i] )
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
    LifeAbility : GemContainer_Update()
    for i = 1, 4 do
        local nItemID, tmpGemType
        nItemID, _, tmpGemType = LifeAbility : GetGemContainer_Gem(gem_con_index, i - 1 )
        if nItemID ~= -1 then
            gemConTypeList[i] = tmpGemType
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
function Wuhun_GetGemTypeByIndex( itemTblIdx )
    if itemTblIdx == nil or itemTblIdx <= 0 then
        return -1
    end

    local tmpValue = math.mod( itemTblIdx, 100000 )
    local itemType = math.floor( tmpValue / 1000 )
    return itemType
end

function Wuhun_Miji_Page_Switch()
	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenMijiPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Wuhun_Infant_Switch()
	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:ToggleInfantPage();
	if bRet == 1 then
		this:Hide()
	end
end

function Wuhun_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if ( bRet == 1 ) then
		this:Hide();
	end
end

function Wuhun_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()

end


function Wuhun_Refresh_Page_Button( nLevel)

	if 1 == 1 then
		return
	end
	
	--神鼎
	if ( nLevel < 15 ) then
		Wuhun_ShenDing:Disable()
		Wuhun_ShenDing_tips:Show()
	--	Wuhun_ShenDing:SetToolTip("#{RWYQ_150707_07}")
	else
		Wuhun_ShenDing:Enable()
		Wuhun_ShenDing_tips:Hide()
	end
	--子女
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 ) or InfantCount<=0 then
		Wuhun_Infant:Disable()
		Wuhun_Infant_tips:Show()
	--	Wuhun_Infant:SetToolTip("#{RWYQ_150707_01}")
	else
		Wuhun_Infant:Enable()
		Wuhun_Infant_tips:Hide()
	end
	--武魂
--	if ( nLevel < 65 ) then
--		Wuhun_Wuhun:Disable()
--		Wuhun_Wuhun_tips:Show()
--		Infant_Wuhun:SetToolTip("#{RWYQ_150707_02}")
--	else
		Wuhun_Wuhun:Enable()
		Wuhun_Wuhun_tips:Hide()
--	end
	--修炼
	if ( nLevel < 70 ) then
		Wuhun_Xiulian:Disable()
		Wuhun_Xiulian_tips:Show()
	--	Wuhun_Xiulian:SetToolTip("#{RWYQ_150707_03}")
	else
		Wuhun_Xiulian:Enable()
		Wuhun_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		Wuhun_Miji:Disable()
		Wuhun_Miji_tips:Show()
	--	Wuhun_Miji:SetToolTip("#{RWYQ_150707_04}")
	else
		Wuhun_Miji:Enable()
		Wuhun_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		Wuhun_ZhenYuan:Disable()
		Wuhun_ZhenYuan_tips:Show()
	--	Wuhun_ZhenYuan:SetToolTip("#{RWYQ_150707_05}")
	else
		Wuhun_ZhenYuan:Enable()
		Wuhun_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		Wuhun_JueWei:Disable()
		Wuhun_JueWei_tips:Show()
	--	Wuhun_JueWei:SetToolTip("#{RWYQ_150707_08}")
	else
		Wuhun_JueWei:Enable()
		Wuhun_JueWei_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		Wuhun_JingMai:Disable()
		Wuhun_JingMai_tips:Show()
	--	Wuhun_JingMai:SetToolTip("#{RWYQ_150707_06}")
	else
		Wuhun_JingMai:Enable()
		Wuhun_JingMai_tips:Hide()
	end

	if ( nLevel < 85 ) then
		Wuhun_BaoJian:Disable()
		Wuhun_BaoJian_tips:Show()
	else
		Wuhun_BaoJian:Enable()
		Wuhun_BaoJian_tips:Hide()
	end
	
	--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		Wuhun_WuYi:Enable()
		Wuhun_WuYi_tips:Hide()
	else
		Wuhun_WuYi:Disable()
		Wuhun_WuYi_tips:Show()
	end
	Wuhun_RefreshWuYiTip()
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		Wuhun_ShenQi:Enable()
		Wuhun_ShenQi_tips:Hide()
	else
		Wuhun_ShenQi:Disable()
		Wuhun_ShenQi_tips:Show()
	end
	Wuhun_RefreshOtherInfoTip()
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		Wuhun_Armor:Enable()
		Wuhun_Armor_tips:Hide()
	else
		Wuhun_Armor:Disable()
		Wuhun_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		Wuhun_CangPin:Enable()
		Wuhun_CangPin_tips:Hide()
	else
		Wuhun_CangPin:Disable()
		Wuhun_CangPin_tips:Show()
	end
	
	Wuhun_RefreshCangPinTip()
end

function Wuhun_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

-- 九星神器DIY技能
function Wuhun_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Wuhun_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_Wuhun_PageButton[idx]:GetProperty("UnifiedXPosition");
			Wuhun_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		Wuhun_WuYi_Buttontips:Show()
	else
		Wuhun_WuYi_Buttontips:Hide()
	end
end

function Wuhun_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_Wuhun_PageButton[idx]:GetProperty("UnifiedXPosition");
			Wuhun_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then
		Wuhun_OtherInfo_ButtonTips:Show()
	else
		Wuhun_OtherInfo_ButtonTips:Hide()
	end
end

--内甲
function Wuhun_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function Wuhun_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", Wuhun_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function Wuhun_RefreshCangPinTip()
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
			local newpos = g_PageButtonTipsPos[idx] --28 + g_Wuhun_PageButton[idx]:GetProperty("UnifiedXPosition");
			Wuhun_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		Wuhun_CangPin_Buttontips:Show()
	else
		Wuhun_CangPin_Buttontips:Hide()
	end
end


function Wuhun_ShowPage()

	for i = 1, table.getn(g_Wuhun_Page) do
		g_Wuhun_PageButton[i]:Hide()
		g_Wuhun_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	Wuhun_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_Wuhun_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_Wuhun_Page) do
			if i ~= nPageNumber then
				g_Wuhun_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_Wuhun_Page) do
		if Wuhun_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_Wuhun_PageButton[g_PageCount]:Show()
			g_Wuhun_PageButton[g_PageCount]:SetText(g_Wuhun_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if Wuhun_IsPageEnable(i) == 1 then
				g_Wuhun_PageButton[g_PageCount]:Enable()
				g_Wuhun_PageMask[g_PageCount]:Hide()
			else
				g_Wuhun_PageButton[g_PageCount]:Disable()
				g_Wuhun_PageMask[g_PageCount]:Show()
				if g_Wuhun_Page[i].Tip ~= "" then
					g_Wuhun_PageMask[g_PageCount]:SetToolTip(g_Wuhun_Page[i].Tip)
				end
			end
		end
	end
	
	Wuhun_RefreshWuYiTip()
	Wuhun_RefreshOtherInfoTip()
	Wuhun_RefreshCangPinTip()
	
end

function Wuhun_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		Wuhun_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		Wuhun_SelfData_Page_Switch()
	elseif idx == 3 then--珍兽
		Wuhun_Pet_Page_Switch()
	elseif idx == 4 then--子女
		Wuhun_Infant_Switch()
	elseif idx == 5 then--武魂
		--SelfData_Wuhun_Switch()
	elseif idx == 6 then--修炼
		Wuhun_Xiulian_Page_Switch()
	elseif idx == 7 then--秘籍
		Wuhun_Miji_Page_Switch()
	elseif idx == 8 then--真元
		Wuhun_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		Wuhun_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		Wuhun_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		Wuhun_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		Wuhun_OpenBaoJian()
	elseif idx == 13 then--武意
		Wuhun_OpenWuYi()
	elseif idx == 14 then--神器
		Wuhun_OpenShenQi()
	elseif idx == 15 then--星盘
		Wuhun_Armor_Page_Switch()
	elseif idx == 16 then--名物
		Wuhun_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		Wuhun_OtherInfo_Page_Switch()
	end
end

function Wuhun_CheckPage(idx)
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

function Wuhun_IsPageEnable(idx)
	
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

function Wuhun_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


