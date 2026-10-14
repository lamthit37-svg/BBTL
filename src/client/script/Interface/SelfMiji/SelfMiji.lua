local g_COMBO_BOOK = {}
local g_COMBO_BOOK_TEXT = {}
local g_SKILL_ACTION = {}
local g_Rate_Skill = {}
local g_BOOK_NAME = {}
local g_BOOK_EMPTY_TEST = {}
local g_LEVELUP_BUTTON = {}
local g_DELETE_BUTTON = {}
local g_LEVELUP_TIPS={}
local g_DELETE_TIPS={}
local g_delete_index = -1
local g_Last_selectAction = -1 --记录客户端最后一次选择
local g_First_valid = 0
local g_bFirstLogin_Combo = 1
local g_old_xiuweiLevel = nil

local g_AutoClick_BtnFlag = -1 -- 记录当前鼠标左键是在哪个按钮按下
local g_AutoClickTimer_Step = 300		-- 多少时间(毫秒)模拟一次 Click 操作
local g_AutoClick_Going = -1  --标志是否开始自动点击操作
local g_AutoClick_FunList = {}

local g_Mission_JuShiMiJiZhenWuXue = 1652		-- 绝世秘籍真武学
local g_Mission_YiQiHeChengXianShenShou = 1653	-- 一气呵成显身手
local g_Mission_XuMiDaZhenJieZhouTian = 1654	-- 虚空大阵解虚空
local g_Mission_XinlingShenHuiTuoFanTai = 1655	-- 心领神会脱凡胎

local g_SelfMiji_Frame_UnifiedPosition = nil;

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_SelfMiji_Page = {
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

local g_SelfMiji_PageButton = {}
local g_SelfMiji_PageMask = {}
local g_PageCount = 0
local g_PageOrder = {}
local g_PageButtonTipsPos = {}

function SelfMiji_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("OPEN_MIJI_PAGE");
	this:RegisterEvent("OPERATION_COMBO_BOOK");
	this:RegisterEvent("UPDATA_MIJI");
	this:RegisterEvent("ADJEST_UI_POS",false);
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false);
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("DELETE_COMBOBOOK_SENDMSG");
	-- 返回登陆界面
	this:RegisterEvent("QUEST_SERVER_LOGIN")
	this:RegisterEvent("OPEN_UP_BAR_2")
	this:RegisterEvent("GAMELOGIN_SELECTCHARACTER");
	this:RegisterEvent("UPDATE_WILLGET_MISSION_TRACK");		--升级
	this:RegisterEvent("TOGGLE_UPDATE_INFANT"); --子女有变化 刷新按钮状态
	this:RegisterEvent("FINISH_MISSION");
	this:RegisterEvent("MARTIAL_UPDATE",false)
	this:RegisterEvent("MARTIAL_HIDE_ZHAOHUI_TIP",false)
	this:RegisterEvent("UPDATE_TOY_TIP", false)
	this:RegisterEvent("CANGPIN_UPDATE", false)
end

function SelfMiji_OnLoad()
	g_delete_index = -1
	g_AutoClick_BtnFlag = -1
	g_AutoClick_FunList[1] = SelfMiji_
    g_SelfMiji_Frame_UnifiedPosition = SelfMiji_Frame:GetProperty("UnifiedPosition")
	g_COMBO_BOOK[1] = SelfMiji_Miji1_Skill
	g_COMBO_BOOK[2] = SelfMiji_Miji2_Skill
	g_COMBO_BOOK[3] = SelfMiji_Miji3_Skill


	g_COMBO_BOOK_TEXT[1] =SelfMiji_Miji1_level
	g_COMBO_BOOK_TEXT[2] =SelfMiji_Miji2_level
	g_COMBO_BOOK_TEXT[3] =SelfMiji_Miji3_level


	g_SKILL_ACTION[1] =SelfMiji_InfoFrame_Icon1
	g_SKILL_ACTION[2] =SelfMiji_InfoFrame_Icon2
	g_SKILL_ACTION[3] =SelfMiji_InfoFrame_Icon3

	g_BOOK_NAME[1] = SelfMiji_Miji1_name
	g_BOOK_NAME[2] = SelfMiji_Miji2_name
	g_BOOK_NAME[3] = SelfMiji_Miji3_name
	g_BOOK_EMPTY_TEST[1] = SelfMiji_Miji1_text
	g_BOOK_EMPTY_TEST[2] = SelfMiji_Miji2_text
	g_BOOK_EMPTY_TEST[3] = SelfMiji_Miji3_text
	g_LEVELUP_BUTTON[1] = SelfMiji_Miji1_up
	g_LEVELUP_BUTTON[2] = SelfMiji_Miji2_up
	g_LEVELUP_BUTTON[3] = SelfMiji_Miji3_up
	g_DELETE_BUTTON[1] = SelfMiji_Miji1_del
	g_DELETE_BUTTON[2] = SelfMiji_Miji2_del
	g_DELETE_BUTTON[3] = SelfMiji_Miji3_del
	g_LEVELUP_TIPS[1] =SelfMiji_Miji1_up_tips
	g_LEVELUP_TIPS[2] =SelfMiji_Miji2_up_tips
	g_LEVELUP_TIPS[3] =SelfMiji_Miji3_up_tips
	g_DELETE_TIPS[1] = SelfMiji_Miji1_del_tips
	g_DELETE_TIPS[2] = SelfMiji_Miji2_del_tips
	g_DELETE_TIPS[3] = SelfMiji_Miji3_del_tips
	g_Rate_Skill[1]   =SelfMiji_InfoFrame_pro1to2
	g_Rate_Skill[2]	  =SelfMiji_InfoFrame_pro2to3

	g_SelfMiji_PageButton[1] = SelfMiji_SelfEquip
	g_SelfMiji_PageButton[2] = SelfMiji_SelfData
	g_SelfMiji_PageButton[3] = SelfMiji_Pet
	g_SelfMiji_PageButton[4] = SelfMiji_Infant
	g_SelfMiji_PageButton[5] = SelfMiji_Wuhun
	g_SelfMiji_PageButton[6] = SelfMiji_Xiulian
	g_SelfMiji_PageButton[7] = SelfMiji_Miji
	g_SelfMiji_PageButton[8] = SelfMiji_ZhenYuan
	g_SelfMiji_PageButton[9] = SelfMiji_JingMai
	g_SelfMiji_PageButton[10] = SelfMiji_ShenDing
	g_SelfMiji_PageButton[11] = SelfMiji_JueWei
	g_SelfMiji_PageButton[12] = SelfMiji_BaoJian
	g_SelfMiji_PageButton[13] = SelfMiji_WuYi
	g_SelfMiji_PageButton[14] = SelfMiji_ShenQi
	g_SelfMiji_PageButton[15] = SelfMiji_Armor
	g_SelfMiji_PageButton[16] = SelfMiji_CangPin
	g_SelfMiji_PageButton[17] = SelfMiji_OtherInfo
	
	g_SelfMiji_PageMask[1] = SelfMiji_SelfEquip_tips
	g_SelfMiji_PageMask[2] = SelfMiji_SelfData_tips
	g_SelfMiji_PageMask[3] = SelfMiji_Pet_tips
	g_SelfMiji_PageMask[4] = SelfMiji_Infant_tips
	g_SelfMiji_PageMask[5] = SelfMiji_Wuhun_tips
	g_SelfMiji_PageMask[6] = SelfMiji_Xiulian_tips
	g_SelfMiji_PageMask[7] = SelfMiji_Miji_tips
	g_SelfMiji_PageMask[8] = SelfMiji_ZhenYuan_tips
	g_SelfMiji_PageMask[9] = SelfMiji_JingMai_tips
	g_SelfMiji_PageMask[10] = SelfMiji_ShenDing_tips
	g_SelfMiji_PageMask[11] = SelfMiji_JueWei_tips
	g_SelfMiji_PageMask[12] = SelfMiji_BaoJian_tips
	g_SelfMiji_PageMask[13] = SelfMiji_WuYi_tips
	g_SelfMiji_PageMask[14] = SelfMiji_ShenQi_tips
	g_SelfMiji_PageMask[15] = SelfMiji_Armor_tips
	g_SelfMiji_PageMask[16] = SelfMiji_CangPin_tips
	g_SelfMiji_PageMask[17] = SelfMiji_OtherInfo_tips
	
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


function SelfMiji_OnEvent(event)

	if ( event == "UPDATE_WILLGET_MISSION_TRACK" ) or (event=="TOGGLE_UPDATE_INFANT")  or (event == "FINISH_MISSION") then
		local nLevel =Player:GetLevel()
		SelfMiji_Refresh_Page_Button(nLevel)
		SelfMiji_ShowPage()
	end

	if( event == "UI_COMMAND" and tonumber( arg0 ) == 2013022101 ) then

		local nType = Get_XParam_INT(0);	-- nType=1: 刷新动态Tip nType=2: 打开武林秘籍UI
		if ( nType == 1 ) then

			CloseFreshManGuide();	-- 先关闭动态Tip引导
			SelfMiji_UIGuide( 1 );	-- 再刷新Tips引导, 1:初次打开, 需要打开动态Tip -1:如果动态Tip已经自动关闭, 就不再重新打开

		elseif ( nType == 2 ) then

			OpenMijiPage();	-- 打开UI

		end
	elseif( event == "UI_COMMAND" and tonumber( arg0 ) == 20130319 ) then
		OpenMijiPage();	-- 打开UI
	elseif( event == "UI_COMMAND" and tonumber( arg0 ) == 20130402 ) then
		local bookindex =  Get_XParam_INT(0)
		if bookindex ~= nil and bookindex >= 0 and bookindex < 3 then
			PushEvent("DELETE_COMBOBOOK_CONFIRM",bookindex);
		end

	elseif(event == "OPEN_MIJI_PAGE") then
		SelfMiji_CleanAll()
		SelfMiji_SetTabState()
		for i = 1, 3 do
			local theAction = EnumAction(i - 1, "combobook")
			if (theAction:GetID() ~= 0 ) then
				g_COMBO_BOOK[i] : SetActionItem(theAction:GetID())
				g_LEVELUP_BUTTON[i]:SetProperty("Disabled", "False");
				g_DELETE_BUTTON[i]:SetProperty("Disabled", "False");
				SelfMiji_Updata_Book(i-1);
				if(g_First_valid == 0) then
					g_First_valid = i;
				end
			else
				g_BOOK_EMPTY_TEST[i]:SetText("#{WLMJ_130121_12}")
				g_LEVELUP_BUTTON[i]:SetProperty("Disabled", "True");
				g_LEVELUP_TIPS[i]:SetToolTip("#{WLMJ_130121_21}");
				g_DELETE_BUTTON[i]:SetProperty("Disabled", "True");
				g_DELETE_TIPS[i]:SetToolTip("#{WLMJ_130121_25}");
			end
		end
		SelfMiji_InfoFrame_detailtext:ClearAllElement()
		SelfMiji_InfoFrame_detailtext:AddTextElement("#{WLMJ_130121_20}")
		local LastSelectAction = EnumAction(g_Last_selectAction, "combobook")
		if(g_Last_selectAction >= 0 and LastSelectAction:GetID() ~= 0) then
			SelfMiji_Updata_Book(g_Last_selectAction)
		elseif( g_First_valid > 0) then
			g_Last_selectAction = g_First_valid - 1
			SelfMiji_Updata_Book(g_First_valid - 1)
		end
		local xiuweivalue =  Player : GetData( "XIUWEI" );
		local tilte,level = SelfMiji_GetXiuWeiLevel(xiuweivalue)
		local nextlevelneed = GetXiuweiNextNeed(xiuweivalue)
		local str_Temp_tips = ScriptGlobal_Format("#{WLMJ_130121_36}", xiuweivalue ,nextlevelneed)
		if level == 10 then
			SelfMiji_textFrame_xiuwei_text:SetToolTip("#{WLMJ_130121_78}")
		else
			SelfMiji_textFrame_xiuwei_text:SetToolTip(str_Temp_tips)
		end
		SelfMiji_OnOpen()
		this:Show();
		-- 秘籍引导
		SelfMiji_UIGuide( 1 )
		local nLevel =Player:GetLevel()
		SelfMiji_Refresh_Page_Button(nLevel)
		SelfMiji_ShowPage()
	elseif(event == "OPERATION_COMBO_BOOK") then
		SelfMiji_InfoFrame_detailtext:ClearAllElement()
		local bookIndex = tonumber(arg0)
		if(bookIndex ~= nil and bookIndex ~= -1) then
			local theAction = EnumAction(bookIndex, "combobook")
			if(theAction:GetID() ~= 0) then
				g_BOOK_EMPTY_TEST[bookIndex+1]:SetText("")
				g_LEVELUP_BUTTON[bookIndex+1]:SetProperty("Disabled", "False");
				g_DELETE_BUTTON[bookIndex+1]:SetProperty("Disabled", "False");
				SelfMiji_UpdataSkill(bookIndex);
				SelfMiji_InfoFrame_detailtext:ClearAllElement()
				local bookdesc = Player:GetComboBookInfo(bookIndex, "bookdesc");
				SelfMiji_InfoFrame_detailtext:AddTextElement(bookdesc)
			else
				SelfMiji_InfoFrame_detailtext:ClearAllElement()
				SelfMiji_InfoFrame_detailtext:AddTextElement("#{WLMJ_130121_20}")
			end
			SelfMiji_Updata_All_BookLevel();
		elseif ( bookIndex ~= nil) then
			SelfMiji_Updata_All_BookLevel();

		end
	elseif(event == "UPDATA_MIJI") then
		local lilianvalue =  Player : GetData( "LILIAN" );
		local xiuweivalue =  Player : GetData( "XIUWEI" );
		local tilte,level = SelfMiji_GetXiuWeiLevel(xiuweivalue)
		if(lilianvalue > 999999 ) then--当武学心得打怪能获得的上限时要变红……
			lilianvalue = "#cff0000"..lilianvalue
		end
		local str_Temp_lilian = ScriptGlobal_Format("#{WLMJ_130121_14}", lilianvalue )
		local str_Temp_xiuwei = ScriptGlobal_Format("#{WLMJ_130121_15}",tilte, xiuweivalue )
		SelfMiji_textFrame_lilian_text:SetText(str_Temp_lilian)
		SelfMiji_textFrame_xiuwei_text:SetText(str_Temp_xiuwei)
		SelfMiji_Updata_All_BookLevel(); --更新书
		if(g_Last_selectAction >= 0) then
			SelfMiji_Updata_BookLevel(g_Last_selectAction)
		end
		if g_old_xiuweiLevel == nil then
			g_old_xiuweiLevel = level
		elseif g_old_xiuweiLevel < level then
			--local tips = ScriptGlobal_Format("#{WLMJ_130121_76}", tilte )
			--PushDebugMessage(tips)
			g_old_xiuweiLevel = level
		else
			g_old_xiuweiLevel = level
		end
		--更新一下tips
		local xiuweivalue =  Player : GetData( "XIUWEI" );
		local nextlevelneed = GetXiuweiNextNeed(xiuweivalue)
		local str_Temp_tips = ScriptGlobal_Format("#{WLMJ_130121_36}", xiuweivalue, nextlevelneed )
		if level == 10 then
			SelfMiji_textFrame_xiuwei_text:SetToolTip("#{WLMJ_130121_78}")
		else
			SelfMiji_textFrame_xiuwei_text:SetToolTip(str_Temp_tips)
		end
	elseif(event == "ADJEST_UI_POS") then
		SelfMiji_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		SelfMiji_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		SelfMiji_Close()
	elseif(event == "DELETE_COMBOBOOK_SENDMSG") then
		SelfMiji_AskDeleteBook(g_delete_index)
	elseif(event == "QUEST_SERVER_LOGIN") then

	elseif(event == "OPEN_UP_BAR_2") then
		if( g_bFirstLogin_Combo == 1 ) then
			for i=0, 2 do
				local skill1, skill2, skill3 = Player:GetComboBookInfo(i, "comboskill");
				if( skill1 ~= nil and skill1 > 0 ) then
					ActiveComboSkillToMainmenuBar(skill2,skill1,0);
					ActiveComboSkillToMainmenuBar(skill3,skill1,0);
				end
			end
			g_bFirstLogin_Combo = 0;
		end
	elseif(event == "GAMELOGIN_SELECTCHARACTER") then
		g_Last_selectAction = -1;
		g_bFirstLogin_Combo = 1;
		g_old_xiuweiLevel = nil;
	elseif(event == "MARTIAL_UPDATE" or event == "MARTIAL_HIDE_ZHAOHUI_TIP") then
		SelfMiji_RefreshWuYiTip()
	end

	if event == "UPDATE_TOY_TIP" then
		SelfMiji_RefreshOtherInfoTip()
	end
	
	if event == "CANGPIN_UPDATE" then
		SelfMiji_RefreshCangPinTip()
	end

end
function SelfMiji_GetXiuWeiLevel(xiuweivalue)
	if xiuweivalue < 0 then
		return "#{WLMJ_130121_59}",0
	elseif xiuweivalue >= 0 and xiuweivalue < 200000 then
		return "#{WLMJ_130121_59}",0
	elseif xiuweivalue >= 200000 and xiuweivalue < 500000 then
		return "#{WLMJ_130121_60}",1
	elseif xiuweivalue >= 500000 and xiuweivalue < 800000 then
		return "#{WLMJ_130121_61}",2
	elseif xiuweivalue >= 800000 and xiuweivalue < 1200000 then
		return "#{WLMJ_130121_62}",3
	elseif xiuweivalue >= 1200000 and xiuweivalue < 1600000 then
		return "#{WLMJ_130121_63}",4
	elseif xiuweivalue >= 1600000 and xiuweivalue < 2000000 then
		return "#{WLMJ_130121_64}",5
	elseif xiuweivalue >= 2000000 and xiuweivalue < 2400000 then
		return "#{WLMJ_130121_65}",6
	elseif xiuweivalue >= 2400000 and xiuweivalue < 2900000 then
		return "#{WLMJ_130121_66}",7
	elseif xiuweivalue >= 2900000 and xiuweivalue < 3400000 then
		return "#{WLMJ_130121_67}",8
	elseif xiuweivalue >= 3400000 and xiuweivalue < 3900000 then
		return "#{WLMJ_130121_68}",9
	elseif xiuweivalue >= 3900000 and xiuweivalue < 4400000 then
		return "#{WLMJ_130121_69}",10
	else
		return "#{WLMJ_130121_69}",10
	end
end
function SelfMiji_CleanAll()
	for i=1,3 do
		g_COMBO_BOOK[i]:SetActionItem(-1);
		g_COMBO_BOOK_TEXT[i]:SetText("")
		g_SKILL_ACTION[i]:SetActionItem(-1)
		g_BOOK_NAME[i]:SetText("")
		g_BOOK_EMPTY_TEST[i]:SetText("")
	end
	g_Rate_Skill[1]:SetText("#{WLMJ_130121_19}".."#{WLMJ_130121_29}")
	g_Rate_Skill[2]:SetText("#{WLMJ_130121_19}".."#{WLMJ_130121_29}")
	g_Rate_Skill[1]:SetToolTip("#{WLMJ_130121_30}")
	g_Rate_Skill[2]:SetToolTip("#{WLMJ_130121_34}")
	g_First_valid = 0;
end

function SelfMiji_AskDeleteBook(Index)
	for i=1,3 do
		g_SKILL_ACTION[i]:SetActionItem(-1);
	end
	g_COMBO_BOOK_TEXT[Index+1]:SetText("")
	g_BOOK_NAME[Index+1]:SetText("")
	g_BOOK_EMPTY_TEST[Index+1]:SetText("#{WLMJ_130121_12}")
	g_LEVELUP_BUTTON[Index+1]:SetProperty("Disabled", "True");
	g_LEVELUP_TIPS[Index+1]:SetToolTip("#{WLMJ_130121_21}");
	g_DELETE_BUTTON[Index+1]:SetProperty("Disabled", "True");
	g_DELETE_TIPS[Index+1]:SetToolTip("#{WLMJ_130121_25}");
	g_Rate_Skill[1]:SetText("#{WLMJ_130121_19}".."#{WLMJ_130121_29}")
	g_Rate_Skill[2]:SetText("#{WLMJ_130121_19}".."#{WLMJ_130121_29}")
	g_Rate_Skill[1]:SetToolTip("#{WLMJ_130121_30}")
	g_Rate_Skill[2]:SetToolTip("#{WLMJ_130121_34}")
	--!!!!
	g_Last_selectAction = Index  --记录最后一次选择
	AskDelComboBook(Index);
end


--***************************************************
-- 清空鼠标长按标记
--***************************************************
function SelfMiji_AutoClick_Clear(Index)
	Index = tonumber(Index)
	if (Index == g_AutoClick_BtnFlag) then
		g_AutoClick_BtnFlag = -1
	end
end

function SelfMiji_AutoClick_SetTimer(Index)
	Index = tonumber(Index)
	g_AutoClick_Going = -1
	g_AutoClick_BtnFlag = Index
end

function SelfMiji_ResetPos()
	SelfMiji_Frame:SetProperty("UnifiedPosition",g_SelfMiji_Frame_UnifiedPosition)
end
function SelfMiji_del_Clicked(Index)
	
	if Player:GetData("IsOriginalJD") == 1 then
		g_delete_index = Index;
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("CheckDeleteBook");
			Set_XSCRIPT_ScriptID(890099);
			Set_XSCRIPT_Parameter(0,Index);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();
		return
	end
	
	if (DataPool : Lua_IsMissionHaveDone( g_Mission_XinlingShenHuiTuoFanTai )) > 0  then
	g_delete_index = Index;
	Clear_XSCRIPT();
		Set_XSCRIPT_Function_Name("CheckDeleteBook");
		Set_XSCRIPT_ScriptID(890099);
		Set_XSCRIPT_Parameter(0,Index);
		Set_XSCRIPT_ParamCount(1);
	Send_XSCRIPT();
	--
	else
		PushDebugMessage("#{WLMJ_130121_49}")
	end

end

function SelfMiji_Updata_All_Book()
	for i =1, 3 do
		SelfMiji_Updata_Book(i-1);
	end
end

function SelfMiji_Updata_All_BookLevel()
	for i =1, 3 do
		SelfMiji_Updata_BookLevel(i-1);
	end
end


--只更新书的等级，不更新技能图标
function SelfMiji_Updata_BookLevel(Index)
			local theAction = EnumAction(Index, "combobook")
			if (theAction:GetID() ~= 0 ) then
				g_COMBO_BOOK[Index+1] : SetActionItem(theAction:GetID())
				local nSumSkill = GetActionNum("skill");
				local nLevel = Player:GetComboBookInfo(Index, "level");
				local skill1, skill2, skill3 = Player:GetComboBookInfo(Index, "comboskill");
				local rate1, rate2 = Player:GetComboBookInfo(Index, "rate");
				local bookname = Player:GetComboBookInfo(Index, "bookname");
				local bookitemid = Player:GetComboBookInfo(Index, "bookitemId");
				g_BOOK_NAME[Index+1]:SetText("#cfff263"..bookname)
				local boookdesc = Player:GetComboBookInfo(Index, "bookdesc");
				g_COMBO_BOOK_TEXT[Index+1]:SetText("#{WLMJ_130121_13}"..nLevel)
				local lilianvalue =  Player : GetData( "LILIAN" );
				local levelupneed =  Player : GetComboBookInfo(Index, "nextlevelexp");
				local nextlevelallxiuwei = Player : GetComboBookInfo(Index, "allxiuwei");
				--设置升级按钮
				if(lilianvalue >= levelupneed) then
					g_LEVELUP_BUTTON[Index+1]:SetProperty("Disabled", "False");
					local strtemp = ScriptGlobal_Format("#{WLMJ_130121_23}", levelupneed,levelupneed) --按钮亮的时候要用自己的tips= =
					g_LEVELUP_BUTTON[Index+1]:SetToolTip(strtemp)
				else
					g_LEVELUP_BUTTON[Index+1]:SetProperty("Disabled", "True");
					local strtemp = ScriptGlobal_Format("#{WLMJ_130121_24}", levelupneed, levelupneed) --不能升级的tips
					g_LEVELUP_TIPS[Index+1]:SetToolTip(strtemp)
				end
				if( nLevel == 99 ) then
					g_LEVELUP_BUTTON[Index+1]:SetProperty("Disabled", "True");  --满级就不亮了
					g_LEVELUP_TIPS[Index+1]:SetToolTip("#{WLMJ_130121_22}")
				end
				g_DELETE_BUTTON[Index+1]:SetProperty("Disabled", "False");
				if (bookitemid ~= 30311205 and bookitemid ~= 30311210) then
					g_DELETE_BUTTON[Index+1]:SetToolTip("#{WLMJ_130121_26}");
				else
					g_DELETE_BUTTON[Index+1]:SetToolTip("#{WLMJ_130121_26}".."#{WLMJ_130121_77}");
				end
				local nextrate1, nextrage2 = Player : GetComboBookInfo(Index, "nextlevelrate");
				local nextrate1str = string.format("%d",nextrate1/100);
				local nextrate2str = string.format("%d",nextrage2/100);
				local rate1tips = ScriptGlobal_Format("#{WLMJ_130121_32}", bookname, nextrate1str)
				local rate2tips = ScriptGlobal_Format("#{WLMJ_130121_35}", bookname, nextrate2str)
				g_Rate_Skill[1]:SetToolTip(rate1tips)
				g_Rate_Skill[2]:SetToolTip(rate2tips)
				if( nLevel == 99 ) then
					local ratetips = ScriptGlobal_Format("#{WLMJ_130121_33}", bookname)
					g_Rate_Skill[1]:SetToolTip(ratetips)
					g_Rate_Skill[2]:SetToolTip(ratetips)
				end
				SelfMiji_SetSelectState()
			end
end

function SelfMiji_SetSelectState()
	for i=1, 3 do
		if( i == g_Last_selectAction+1) then
			g_COMBO_BOOK[i]:SetPushed(1)
		else
			g_COMBO_BOOK[i]:SetPushed(0)
		end
	end
end
function SelfMiji_Updata_Book(Index)
			SelfMiji_InfoFrame_detailtext:ClearAllElement()
			local theAction = EnumAction(Index, "combobook")
			if (theAction:GetID() ~= 0 ) then
				g_COMBO_BOOK[Index+1] : SetActionItem(theAction:GetID())
				local nSumSkill = GetActionNum("skill");
				local nLevel = Player:GetComboBookInfo(Index, "level");
				local skill1, skill2, skill3 = Player:GetComboBookInfo(Index, "comboskill");
				local rate1, rate2 = Player:GetComboBookInfo(Index, "rate");
				local bookitemid = Player:GetComboBookInfo(Index, "bookitemId");
				for i = 1, nSumSkill do
					local thetempAction = EnumAction(i, "skill");
					local temp = thetempAction:GetID();
					local nCommonId = LifeAbility : GetLifeAbility_Number(temp);
					if nCommonId ~=nil and nCommonId > 0 then
						if nCommonId == skill1 then
							SelfMiji_InfoFrame_Icon1 : SetActionItem(thetempAction : GetID())
						end
						if nCommonId == skill2 then
							SelfMiji_InfoFrame_Icon2 : SetActionItem(thetempAction : GetID())
						end
						if nCommonId == skill3 then
							SelfMiji_InfoFrame_Icon3 : SetActionItem(thetempAction : GetID())
						end
					end
				end
				local lilianvalue =  Player : GetData( "LILIAN" );
				local levelupneed =  Player : GetComboBookInfo(Index, "nextlevelexp");
				local nextlevelallxiuwei = Player : GetComboBookInfo(Index, "allxiuwei");
				--设置升级按钮
				if(lilianvalue >= levelupneed) then
					g_LEVELUP_BUTTON[Index+1]:SetProperty("Disabled", "False");
					local strtemp = ScriptGlobal_Format("#{WLMJ_130121_23}", levelupneed,levelupneed) --按钮亮的时候要用自己的tips= =
					g_LEVELUP_BUTTON[Index+1]:SetToolTip(strtemp)
				else
					g_LEVELUP_BUTTON[Index+1]:SetProperty("Disabled", "True");
					local strtemp = ScriptGlobal_Format("#{WLMJ_130121_24}", levelupneed,levelupneed) --不能升级的tips
					g_LEVELUP_TIPS[Index+1]:SetToolTip(strtemp)
				end
				if( nLevel == 99 ) then
					g_LEVELUP_BUTTON[Index+1]:SetProperty("Disabled", "True");  --满级就不亮了
					g_LEVELUP_TIPS[Index+1]:SetToolTip("#{WLMJ_130121_22}")
				end
				g_DELETE_BUTTON[Index+1]:SetProperty("Disabled", "False");
				if (bookitemid ~= 30311205 and bookitemid ~= 30311210) then
					g_DELETE_BUTTON[Index+1]:SetToolTip("#{WLMJ_130121_26}");
				else
					g_DELETE_BUTTON[Index+1]:SetToolTip("#{WLMJ_130121_26}".."#{WLMJ_130121_77}");
				end
				local bookname = Player:GetComboBookInfo(Index, "bookname");
				g_BOOK_NAME[Index+1]:SetText("#cfff263"..bookname)
				local boookdesc = Player:GetComboBookInfo(Index, "bookdesc");
				SelfMiji_InfoFrame_detailtext:AddTextElement(boookdesc);
				local rate1str = string.format("%d",rate1/100);
				local rate2str = string.format("%d",rate2/100);
				g_Rate_Skill[1]:SetText("#{WLMJ_130121_19}"..rate1str.."%")
				g_Rate_Skill[2]:SetText("#{WLMJ_130121_19}"..rate2str.."%")

				g_COMBO_BOOK_TEXT[Index+1]:SetText("#{WLMJ_130121_13}"..nLevel)
				local nextrate1, nextrage2 = Player : GetComboBookInfo(Index, "nextlevelrate");
				local nextrate1str = string.format("%d",nextrate1/100);
				local nextrate2str = string.format("%d",nextrage2/100);
				local rate1tips = ScriptGlobal_Format("#{WLMJ_130121_32}", bookname, nextrate1str)
				local rate2tips = ScriptGlobal_Format("#{WLMJ_130121_35}", bookname, nextrate2str)
				g_Rate_Skill[1]:SetToolTip(rate1tips)
				g_Rate_Skill[2]:SetToolTip(rate2tips)
				if( nLevel == 99 ) then
					local ratetips = ScriptGlobal_Format("#{WLMJ_130121_33}", bookname)
					g_Rate_Skill[1]:SetToolTip(ratetips)
					g_Rate_Skill[2]:SetToolTip(ratetips)
				end
				SelfMiji_SetSelectState()
			else
				SelfMiji_InfoFrame_detailtext:AddTextElement("#{WLMJ_130121_20}")
				SelfMiji_InfoFrame_Icon1 : SetActionItem(-1)
				SelfMiji_InfoFrame_Icon2 : SetActionItem(-1)
				SelfMiji_InfoFrame_Icon3 : SetActionItem(-1)
				g_Rate_Skill[1]:SetText("#{WLMJ_130121_19}".."#{WLMJ_130121_29}")
				g_Rate_Skill[2]:SetText("#{WLMJ_130121_19}".."#{WLMJ_130121_29}")
				g_Rate_Skill[1]:SetToolTip("#{WLMJ_130121_30}")
				g_Rate_Skill[2]:SetToolTip("#{WLMJ_130121_34}")
			end
end
function SelfMiji_Book_Clicked(Index)
	local theAction = EnumAction(Index, "combobook")
	if(theAction ~= nil and theAction:GetID() > 0 ) then
		g_Last_selectAction = Index  --记录最后一次选择
		SelfMiji_Updata_Book(Index)
	end
end

function SelfMiji_UpdataSkill(Index)
	local nSumSkill = GetActionNum("skill");
	local skill1, skill2, skill3 = Player:GetComboBookInfo(Index, "comboskill");
	local rate1, rate2 = Player:GetComboBookInfo(Index, "rate");
	for i = 1, nSumSkill do
		local thetempAction = EnumAction(i, "skill");
		local temp = thetempAction:GetID();
		local nCommonId = LifeAbility : GetLifeAbility_Number(temp);
		if nCommonId ~=nil and nCommonId > 0 then
			if nCommonId == skill1 then
				SelfMiji_InfoFrame_Icon1 : SetActionItem(thetempAction : GetID())
			end
			if nCommonId == skill2 then
				SelfMiji_InfoFrame_Icon2 : SetActionItem(thetempAction : GetID())
			end
			if nCommonId == skill3 then
				SelfMiji_InfoFrame_Icon3 : SetActionItem(thetempAction : GetID())
			end
		end
	end
	local rate1, rate2 = Player:GetComboBookInfo(Index, "rate");
	local rate1str = string.format("%d",rate1/100);
	local rate2str = string.format("%d",rate2/100);
	g_Rate_Skill[1]:SetText("#{WLMJ_130121_19}"..rate1str.."%")
	g_Rate_Skill[2]:SetText("#{WLMJ_130121_19}"..rate2str.."%")
end

function SelfMiji_levelup_Clicked(Index)
	g_Last_selectAction = Index  --记录最后一次选择
	SelfMiji_AutoClick_Clear(Index);
	AskLevelupComboBook(Index);
end

function SelfMiji_SelfEquip_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1);

	OpenEquip(1);
	SelfMiji_Close()
end

function SelfMiji_SelfData_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1);
	SystemSetup:OpenPrivatePage("self");
	SelfMiji_Close()
end

function SelfMiji_Pet_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1);

	TogglePetPage();
	SelfMiji_Close()
end

function SelfMiji_Wuhun_Switch()
	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1);
	ToggleWuhunPage();
	SelfMiji_Close()
end

function SelfMiji_Xiulian_Switch()
	nLevel = Player:GetData("LEVEL")
	if(nLevel >= 70) then
		Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1);
		XiuLianPage();
		SelfMiji_Close()
	else
	    SelfMiji_Xiulian : SetCheck(0)
	    PushDebugMessage("#{XL_090707_62}")
	end
end

function SelfMiji_ZhenYuan_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Pneuma:ToggleZhenYuanPage();
	if bRet == 1 then
		SelfMiji_Close()
	end
end

function SelfMiji_JingMai_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1);
	local nRet = OpenJingMaiPage();
	if nRet == 1 then
		SelfMiji_ZhenYuan:SetCheck(0)
		SelfMiji_Close()
	else
		SelfMiji_ZhenYuan:SetCheck(0)
	end
end

--神木王鼎
function SelfMiji_ShenDing_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenShenDingPage();
	if bRet == 1 then
		SelfMiji_Close()
	end
end

function SelfMiji_Ride_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1);
	OpenRidePage();
	SelfMiji_Close()
end

function SelfMiji_OtherInfo_Page_Switch()
	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1);

	OtherInfoPage();
	SelfMiji_Close()
end

function SelfMiji_OnHide()
	SelfMiji_OnClose()
	CloseFreshManGuide();
end

function SelfMiji_Close()
	SelfMiji_OnClose()
	this:Hide()
	SelfMiji_UIGuide( 1 )
end

function SelfMiji_SetTabState()
	SelfMiji_SelfEquip:SetCheck(0)
	SelfMiji_SelfData:SetCheck(0)
	SelfMiji_Pet:SetCheck(0)
	SelfMiji_Wuhun:SetCheck(0)
	SelfMiji_Xiulian:SetCheck(0)
	SelfMiji_Miji:SetCheck(1)
	SelfMiji_ZhenYuan:SetCheck(0)
	SelfMiji_JingMai:SetCheck(0)
	SelfMiji_Ride:SetCheck(0)
	SelfMiji_OtherInfo:SetCheck(0)


end

-- 这个函数需要XML里边注册事件
function SelfMiji_OnMoved()
	SelfMiji_UIGuide( -1 );	-- 刷新动态Tip位置
end

-- UI引导部分, 不同的阶段, 就有不同的引导Tip
function SelfMiji_UIGuide( state )

	-- 如果窗口处于未打开状态, 就不用刷新Tip了
	if ( IsWindowShow( "SelfMiji" ) == false ) and "SelfMiji" == GetFreshManGuideOwner() then
		CloseFreshManGuide();	-- 关闭动态Tip引导
		return
	end
	-- 如果动态Tip已经关闭, 就不重新显示了.
	if ( state == -1 and IsWindowShow( "FreshManGuide" ) == false ) then
		return
	end

	-- 绝世秘籍真武学
	if ( DataPool : Lua_IsHaveMission( g_Mission_JuShiMiJiZhenWuXue ) > 0 ) then

		local misIndex = DataPool : GetPlayerMissionIndexByID( g_Mission_JuShiMiJiZhenWuXue );
		if ( misIndex < 0 or misIndex >= 20 ) then
			return
		end
		local nFinishedFlag = DataPool : GetPlayerMission_Variable( misIndex, 0 );	-- 是否完成
		if ( nFinishedFlag ~= 1 ) then
			-- 打开背包道具栏
			if( IsWindowShow("Packet") == false ) then
				ToggleContainer()
			end
			-- 动态Tip1
			local fx, fy = this : GetChildOffset( "SelfMiji" );
			fx = fx + SelfMiji_MijiFrame : GetProperty( "AbsoluteWidth" ) / 2 - 50;
			fy = fy + 60;
			OpenFreshManGuide( 1, 43, fx, fy, "SelfMiji", "northwest" );	-- FreshManGuide.lua中配置
		else
			-- 动态Tip2
			local fx, fy = this : GetChildOffset( "SelfMiji" );
			fx = fx + SelfMiji_MijiFrame : GetProperty( "AbsoluteWidth" ) / 2 - 50;
			fy = fy + 60;
			OpenFreshManGuide( 1, 44, fx, fy, "SelfMiji", "northwest" );	-- FreshManGuide.lua中配置
		end

	-- 一气呵成显身手
	elseif ( DataPool : Lua_IsHaveMission( g_Mission_YiQiHeChengXianShenShou ) > 0 ) then

		local misIndex = DataPool : GetPlayerMissionIndexByID( g_Mission_YiQiHeChengXianShenShou );
		if ( misIndex < 0 or misIndex >= 20 ) then
			return
		end

		-- 判断武林秘籍技能是否在技能快捷栏上
		local bHave = 0;
		for	i = 0, 79 do
			local nSkillID = ActionSystem:GetDefineID( i );
			if( nSkillID ~= -1 and nSkillID >= 2500 and nSkillID <= 2600 ) then
				local nTemp = math.mod( nSkillID, 2500 );
				local nLevel = math.mod( nTemp, 3 );
				if ( nLevel ~= 0 ) then
					return
				end
				bHave = 1;
				break
			end
		end

		if ( bHave ~= 1 ) then
			-- 弹出武林秘籍UI, 开启界面引导
			OpenMijiPage();	-- 打开UI
			-- 动态Tip
			local fx, fy = this : GetChildOffset( "SelfMiji" );
			fx = fx + SelfMiji_MijiFrame : GetProperty( "AbsoluteWidth" ) - 110;
			fy = fy + SelfMiji_MijiFrame : GetProperty( "AbsoluteHeight" ) / 2 + 160;
			OpenFreshManGuide( 1, 45, fx, fy, "SelfMiji", "northwest" );	-- FreshManGuide.lua中配置
			return
		end

	-- 心领神会脱凡胎
	elseif ( DataPool : Lua_IsHaveMission( g_Mission_XinlingShenHuiTuoFanTai ) > 0 ) then

		local misIndex = DataPool : GetPlayerMissionIndexByID( g_Mission_XinlingShenHuiTuoFanTai );
		local nFinishedFlag = DataPool : GetPlayerMission_Variable( misIndex, 0 );
		-- 任务条件没有达成
		if ( nFinishedFlag ~= 1 ) then
			-- 动态Tip1
			local fx, fy = this : GetChildOffset( "SelfMiji" );
			fx = fx + SelfMiji_MijiFrame : GetProperty( "AbsoluteWidth" ) - 10;
			fy = fy + 50;
			OpenFreshManGuide( 1, 47, fx, fy, "SelfMiji", "northwest" );	-- FreshManGuide.lua中配置
			return
		-- 若成功提升了领悟境界
		elseif ( nFinishedFlag == 1 ) then
			-- 动态Tip2
			local fx, fy = this : GetChildOffset( "SelfMiji" );
			fx = fx + SelfMiji_MijiFrame : GetProperty( "AbsoluteWidth" ) + 190;
			fy = fy + SelfMiji_MijiFrame : GetProperty( "AbsoluteHeight" ) + 150;
			OpenFreshManGuide( 1, 48, fx, fy, "SelfMiji", "northwest" );	-- FreshManGuide.lua中配置
		end

	elseif( DataPool : Lua_IsMissionHaveDone( g_Mission_XinlingShenHuiTuoFanTai ) > 0 ) then

		return

	-- 虚空大阵解虚空
	elseif ( DataPool : Lua_IsMissionHaveDone( g_Mission_XuMiDaZhenJieZhouTian ) > 0 ) then

		-- 动态Tip
		local fx, fy = this : GetChildOffset( "SelfMiji" );
		fx = fx + SelfMiji_MijiFrame : GetProperty( "AbsoluteWidth" ) / 2 - 30;
		fy = fy + SelfMiji_MijiFrame : GetProperty( "AbsoluteHeight" ) + 150;
		OpenFreshManGuide( 1, 46, fx, fy, "SelfMiji", "northwest" );		-- FreshManGuide.lua中配置
		return

	end

end

function SelfMiji_OnOpen()
	g_AutoClick_Going = -1
	g_AutoClick_BtnFlag = -1
	SetTimer("SelfMiji", "SelfMiji_AutoClick_Timer()", g_AutoClickTimer_Step)
end

function SelfMiji_OnClose()
	g_AutoClick_Going = -1
	g_AutoClick_BtnFlag = -1
	KillTimer("SelfMiji_AutoClick_Timer()")
end

--***************************************************
-- 定时器回调函数
--    实现慢启动, 以后可以考虑加速(必要性不大)
--***************************************************
function SelfMiji_AutoClick_Timer()

	if (g_AutoClick_BtnFlag ~= -1) then
		-- 第一次LButton后经过X个Timer才算开始, 也就是说是 g_AutoClickTimer_Step * X 的时候开始进行自动加, 这样为了防止本来要点击一下的结果点了好多下
		if (g_AutoClick_Going < 3) then
			g_AutoClick_Going = g_AutoClick_Going + 1

		else
			g_Last_selectAction = g_AutoClick_BtnFlag  --记录最后一次选择
			AskLevelupComboBook(g_AutoClick_BtnFlag)
		end
	end
end

function SelfMiji_Infant_Switch()
	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = Infant:ToggleInfantPage();
	if bRet == 1 then
		SelfMiji_Close()
	end
end

function SelfMiji_JueWei_Page_Switch()
	-- 等级限制
	if ( Player:GetLevel() < 85 ) then
		PushDebugMessage( "#{JXJW_140822_20}" );
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1);
	local bRet = OpenJunXianPage();
	if ( bRet == 1 ) then
		this:Hide();
	end
end

function SelfMiji_OpenBaoJian()

	local nLevel =Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{ZZZB_150811_114}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1)
	Lua_OpenFiveElementsPage()

end

function SelfMiji_Refresh_Page_Button( nLevel)

	if 1 == 1 then
		return
	end
	
	--神鼎
	if ( nLevel < 15 ) then
		SelfMiji_ShenDing:Disable()
		SelfMiji_ShenDing_tips:Show()
	--	SelfMiji_ShenDing:SetToolTip("#{RWYQ_150707_07}")
	else
		SelfMiji_ShenDing:Enable()
		SelfMiji_ShenDing_tips:Hide()
	end
	--子女
	local InfantCount = Infant:GetInfantCount();
	if ( nLevel < 50 ) or InfantCount<=0 then
		SelfMiji_Infant:Disable()
		SelfMiji_Infant_tips:Show()
	--	SelfMiji_Infant:SetToolTip("#{RWYQ_150707_01}")
	else
		SelfMiji_Infant:Enable()
		SelfMiji_Infant_tips:Hide()
	end
	--武魂
--	if ( nLevel < 65 ) then
--		SelfMiji_Wuhun:Disable()
--		SelfMiji_Wuhun_tips:Show()
	--	SelfMiji_Wuhun:SetToolTip("#{RWYQ_150707_02}")
--	else
		SelfMiji_Wuhun:Enable()
		SelfMiji_Wuhun_tips:Hide()
--	end
	--修炼
	if ( nLevel < 70 ) then
		SelfMiji_Xiulian:Disable()
		SelfMiji_Xiulian_tips:Show()
	--	SelfMiji_Xiulian:SetToolTip("#{RWYQ_150707_03}")
	else
		SelfMiji_Xiulian:Enable()
		SelfMiji_Xiulian_tips:Hide()
	end
	--秘籍
	local ret=DataPool:Lua_IsMissionHaveDone(1651)
	if ( nLevel < 75 ) or ret==0 then
		SelfMiji_Miji:Disable()
		SelfMiji_Miji_tips:Show()
--		SelfMiji_Miji:SetToolTip("#{RWYQ_150707_04}")
	else
		SelfMiji_Miji:Enable()
		SelfMiji_Miji_tips:Hide()
	end
	--真元
	local ret=DataPool:Lua_IsMissionHaveDone(1600)
	if ( nLevel < 80 ) or ret==0 then
		SelfMiji_ZhenYuan:Disable()
		SelfMiji_ZhenYuan_tips:Show()
	--	SelfMiji_ZhenYuan:SetToolTip("#{RWYQ_150707_05}")
	else
		SelfMiji_ZhenYuan:Enable()
		SelfMiji_ZhenYuan_tips:Hide()
	end
	--侠印
	if ( nLevel < 85 ) then
		SelfMiji_JueWei:Disable()
		SelfMiji_JueWei_tips:Show()
	--	SelfMiji_JueWei:SetToolTip("#{RWYQ_150707_08}")
	else
		SelfMiji_JueWei:Enable()
		SelfMiji_JueWei_tips:Hide()
	end
	--经脉
	local ret=DataPool:Lua_IsMissionHaveDone(1554)
	if ( nLevel < 90 ) or ret==0  then
		SelfMiji_JingMai:Disable()
		SelfMiji_JingMai_tips:Show()
	--	SelfMiji_JingMai:SetToolTip("#{RWYQ_150707_06}")
	else
		SelfMiji_JingMai:Enable()
		SelfMiji_JingMai_tips:Hide()
	end

	if ( nLevel < 85 ) then
		SelfMiji_BaoJian:Disable()
		SelfMiji_BaoJian_tips:Show()
	else
		SelfMiji_BaoJian:Enable()
		SelfMiji_BaoJian_tips:Hide()
	end

		--武意
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nLevel >= 85) then
		SelfMiji_WuYi:Enable()
		SelfMiji_WuYi_tips:Hide()
	else
		SelfMiji_WuYi:Disable()
		SelfMiji_WuYi_tips:Show()
	end
	SelfMiji_RefreshWuYiTip()
	--九星神器DIY技能
	if(DataPool:Lua_IsMissionHaveDone(1950) == 1) then
		SelfMiji_ShenQi:Enable()
		SelfMiji_ShenQi_tips:Hide()
	else
		SelfMiji_ShenQi:Disable()
		SelfMiji_ShenQi_tips:Show()
	end
	SelfMiji_RefreshOtherInfoTip()
	
	if nLevel >= 85 and DataPool:Lua_IsMissionHaveDone(1564) == 1 then
		SelfMiji_Armor:Enable()
		SelfMiji_Armor_tips:Hide()
	else
		SelfMiji_Armor:Disable()
		SelfMiji_Armor_tips:Show()
	end
	
	if nLevel >= 30 then
		SelfMiji_CangPin:Enable()
		SelfMiji_CangPin_tips:Hide()
	else
		SelfMiji_CangPin:Disable()
		SelfMiji_CangPin_tips:Show()
	end
	
	SelfMiji_RefreshCangPinTip()
end

function SelfMiji_OpenWuYi()
	local nLevel =Player:GetLevel()
	if(MaritialSys:HasFinishWuYiMisson() ~= 1 or nLevel < 85) then
		PushDebugMessage("尚未开启武意系统")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1);
	PushEvent("MARTIAL_SHOWWUYI")
end

-- 九星神器DIY技能
function SelfMiji_OpenShenQi()
	local nLevel =Player:GetLevel()
	if(DataPool:Lua_IsMissionHaveDone(1950) ~= 1) then
		PushDebugMessage("#{JXSQ_170804_85}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1);
	--PushEvent("SUPERWEAPONDIYSKILL_OPENUI")	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("SuperWeaponDIYSkill_OpenUI")
		Set_XSCRIPT_ScriptID(892471)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function SelfMiji_RefreshWuYiTip()
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 13 and g_PageButtonTipsPos[idx] then -- 武意
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfMiji_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfMiji_WuYi_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	local nMonsterNum,nReward = MaritialSys:GetLastDayMonster()
	local nLastTip = MaritialSys:GetLastDayMonsterTip()
	if(MaritialSys:HasFinishWuYiMisson() == 1 and nMonsterNum > 0 and nLastTip == 1) then
		SelfMiji_WuYi_Buttontips:Show()
	else
		SelfMiji_WuYi_Buttontips:Hide()
	end
end

function SelfMiji_RefreshOtherInfoTip()
	local flag = 0
	if Exterior:LuaFnIsHaveToyShowTip() == 1 then
		flag = 1
	end
	
	for idx = 1, table.getn(g_PageOrder) do
		if g_PageOrder[idx] == 17 and g_PageButtonTipsPos[idx] then -- 其他
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfMiji_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfMiji_OtherInfo_ButtonTips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if flag == 1 then
		SelfMiji_OtherInfo_ButtonTips:Show()
	else
		SelfMiji_OtherInfo_ButtonTips:Hide()
	end
end

--内甲
function SelfMiji_Armor_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 85 then
		PushDebugMessage("#{NJBZ_220816_13}")
		return
	end
	
	if DataPool:Lua_IsMissionHaveDone(1564) ~= 1 then
		PushDebugMessage("#{NJBZ_220816_14}")
		return
	end

	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenUnderArmour("self")
end

function SelfMiji_CangPin_Page_Switch()
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{CPSJ_260112_3}")
		return
	end
	Variable:SetVariable("SelfUnionPos", SelfMiji_Frame:GetProperty("UnifiedPosition"), 1)
	LuaFnOpenCangPin(3)
end

function SelfMiji_RefreshCangPinTip()
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
			local newpos = g_PageButtonTipsPos[idx] --28 + g_SelfMiji_PageButton[idx]:GetProperty("UnifiedXPosition");
			SelfMiji_CangPin_Buttontips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
	if bHaveChipToMelt == 1 or bTip == 1 then
		SelfMiji_CangPin_Buttontips:Show()
	else
		SelfMiji_CangPin_Buttontips:Hide()
	end
end


function SelfMiji_ShowPage()

	for i = 1, table.getn(g_SelfMiji_Page) do
		g_SelfMiji_PageButton[i]:Hide()
		g_SelfMiji_PageMask[i]:Hide()
	end
	
	local nPageNumber = tonumber(Variable:GetVariable("PageNumber"));
	SelfMiji_ClearPage()
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_SelfMiji_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_SelfMiji_Page) do
			if i ~= nPageNumber then
				g_SelfMiji_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_PageOrder = {}
	g_PageCount = 0
	for i = 1, table.getn(g_SelfMiji_Page) do
		if SelfMiji_CheckPage(i) == 1 then
			g_PageCount = g_PageCount + 1
			g_SelfMiji_PageButton[g_PageCount]:Show()
			g_SelfMiji_PageButton[g_PageCount]:SetText(g_SelfMiji_Page[i].Text)	
			g_PageOrder[g_PageCount] = i
			
			if SelfMiji_IsPageEnable(i) == 1 then
				g_SelfMiji_PageButton[g_PageCount]:Enable()
				g_SelfMiji_PageMask[g_PageCount]:Hide()
			else
				g_SelfMiji_PageButton[g_PageCount]:Disable()
				g_SelfMiji_PageMask[g_PageCount]:Show()
				if g_SelfMiji_Page[i].Tip ~= "" then
					g_SelfMiji_PageMask[g_PageCount]:SetToolTip(g_SelfMiji_Page[i].Tip)
				end
			end
		end
	end
	
	SelfMiji_RefreshWuYiTip()
	SelfMiji_RefreshOtherInfoTip()
	SelfMiji_RefreshCangPinTip()
	
end

function SelfMiji_OnPageClicked(idx)
	Variable:SetVariable("PageNumber", tostring(idx), 1);
	idx = g_PageOrder[idx]
	if idx == 1 then--装备
		SelfMiji_SelfEquip_Page_Switch();
	elseif idx == 2 then--资料
		SelfMiji_SelfData_Page_Switch()
	elseif idx == 3 then--珍兽
		SelfMiji_Pet_Page_Switch()
	elseif idx == 4 then--子女
		SelfMiji_Infant_Switch()
	elseif idx == 5 then--武魂
		SelfMiji_Wuhun_Switch()
	elseif idx == 6 then--修炼
		SelfMiji_Xiulian_Switch()
	elseif idx == 7 then--秘籍
		--SelfData_Miji_Page_Switch()
	elseif idx == 8 then--真元
		SelfMiji_ZhenYuan_Page_Switch()
	elseif idx == 9 then--经脉
		SelfMiji_JingMai_Page_Switch()
	elseif idx == 10 then--神鼎
		SelfMiji_ShenDing_Page_Switch()
	elseif idx == 11 then--侠印
		SelfMiji_JueWei_Page_Switch()
	elseif idx == 12 then--宝鉴
		SelfMiji_OpenBaoJian()
	elseif idx == 13 then--武意
		SelfMiji_OpenWuYi()
	elseif idx == 14 then--神器
		SelfMiji_OpenShenQi()
	elseif idx == 15 then--星盘
		SelfMiji_Armor_Page_Switch()
	elseif idx == 16 then--名物
		SelfMiji_CangPin_Page_Switch()
	elseif idx == 17 then--其他
		SelfMiji_OtherInfo_Page_Switch()
	end
end

function SelfMiji_CheckPage(idx)
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

function SelfMiji_IsPageEnable(idx)
	
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

function SelfMiji_ClearPage()
	Variable:SetVariable("PageNumber", tostring(0), 1)
end


