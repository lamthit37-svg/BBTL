local COMMON_BUTTONS = {};
--local COMMON_LEVEL = {};
local COMMON_INDEX = {};
local Current = 1;
local COMMON_BUTTONS_NUM = 20;
local Current_Page = 0;

local g_NeedTipText = -1
local g_NeedTipID = -1
-- 界面的默认相对位置
local g_CommonSkill_Frame_UnifiedXPosition;
local g_CommonSkill_Frame_UnifiedYPosition;

local g_commonskill_zdzdskill = {
	_start = 4742,
	_end = 4746,
}

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_CommonSkill_Page = {
	[1] = {Text = "#e010101#Y".."#{INTERFACE_XML_494}",	NeedCheck = 0, Tip = ""},
	[2] = {Text = "#e010101".."#{INTERFACE_XML_448}",	NeedCheck = 0, Tip = ""},
	[3] = {Text = "#e010101".."#{JBGXW_150526_215}",	NeedCheck = 0, Tip = ""},
	[4] = {Text = "#e010101".."#{INTERFACE_XML_635}",	NeedCheck = 0, Tip = ""},
	[5] = {Text = "#e010101".."#{ZDZD_200724_08}",		NeedCheck = 0, Tip = ""},
	[6] = {Text = "#e010101".."#{ZMTF_230628_20}",		NeedCheck = 0, Tip = ""},
}
local g_CommonSkill_PageButton = {}
local g_CommonSkill_PageOrder = {}
local g_PageTipsPos = {}

function CommonSkill_PreLoad()
	this:RegisterEvent("TOGLE_LIFE_PAGE",false);
	this:RegisterEvent("TOGLE_SKILL_BOOK",false);
	this:RegisterEvent("TOGLE_COMMONSKILL_PAGE",true);
	this:RegisterEvent("SKILL_UPDATE",false);
	this:RegisterEvent("CLOSE_SKILL_BOOK",false);

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("NOTIFY_POP_UITIP",false)
	this:RegisterEvent("UI_COMMAND", true)
end
	
function CommonSkill_OnLoad()
	COMMON_BUTTONS[1] = CommonSkill_Skill1;
	COMMON_BUTTONS[2] = CommonSkill_Skill2;
	COMMON_BUTTONS[3] = CommonSkill_Skill3;
	COMMON_BUTTONS[4] = CommonSkill_Skill4;
	COMMON_BUTTONS[5] = CommonSkill_Skill5;
	COMMON_BUTTONS[6] = CommonSkill_Skill6;
	COMMON_BUTTONS[7] = CommonSkill_Skill7;
	COMMON_BUTTONS[8] = CommonSkill_Skill8;
	COMMON_BUTTONS[9] = CommonSkill_Skill9;
	COMMON_BUTTONS[10] = CommonSkill_Skill10;
	COMMON_BUTTONS[11] = CommonSkill_Skill11;
	COMMON_BUTTONS[12] = CommonSkill_Skill12;
	COMMON_BUTTONS[13] = CommonSkill_Skill13;
	COMMON_BUTTONS[14] = CommonSkill_Skill14;
	COMMON_BUTTONS[15] = CommonSkill_Skill15;
	COMMON_BUTTONS[16] = CommonSkill_Skill16;
	COMMON_BUTTONS[17] = CommonSkill_Skill17;
	COMMON_BUTTONS[18] = CommonSkill_Skill18;
	COMMON_BUTTONS[19] = CommonSkill_Skill19;
	COMMON_BUTTONS[20] = CommonSkill_Skill20;
	
--	COMMON_LEVEL[1] = CommonSkill_Skill1_Text;
--	COMMON_LEVEL[2] = CommonSkill_Skill2_Text;
--	COMMON_LEVEL[3] = CommonSkill_Skill3_Text;
--	COMMON_LEVEL[4] = CommonSkill_Skill4_Text;
--	COMMON_LEVEL[5] = CommonSkill_Skill5_Text;
--	COMMON_LEVEL[6] = CommonSkill_Skill6_Text;
--	COMMON_LEVEL[7] = CommonSkill_Skill7_Text;
--	COMMON_LEVEL[8] = CommonSkill_Skill8_Text;
--	COMMON_LEVEL[9] = CommonSkill_Skill9_Text;
--	COMMON_LEVEL[10] = CommonSkill_Skill10_Text;
--	COMMON_LEVEL[11] = CommonSkill_Skill11_Text;
--	COMMON_LEVEL[12] = CommonSkill_Skill12_Text;
--	COMMON_LEVEL[13] = CommonSkill_Skill13_Text;
--	COMMON_LEVEL[14] = CommonSkill_Skill14_Text;
--	COMMON_LEVEL[15] = CommonSkill_Skill15_Text;
--	COMMON_LEVEL[16] = CommonSkill_Skill16_Text;
--	COMMON_LEVEL[17] = CommonSkill_Skill17_Text;
--	COMMON_LEVEL[18] = CommonSkill_Skill18_Text;
--	COMMON_LEVEL[19] = CommonSkill_Skill19_Text;
--	COMMON_LEVEL[20] = CommonSkill_Skill20_Text;

	for i=1,20 do
		COMMON_INDEX[i] = -1;
--		COMMON_LEVEL[i] :SetText("");
	end;
	
	--CommonSkill_SetTabColor();

	-- 保存界面的默认相对位置
	g_CommonSkill_Frame_UnifiedXPosition	= CommonSkill_Frame : GetProperty("UnifiedXPosition");
	g_CommonSkill_Frame_UnifiedYPosition	= CommonSkill_Frame : GetProperty("UnifiedYPosition");

	g_CommonSkill_PageButton[1] = CommonSkill_CommonlySkill
	g_CommonSkill_PageButton[2] = CommonSkill_ActionSkill
	g_CommonSkill_PageButton[3] = CommonSkill_ZhenfaSkill
	g_CommonSkill_PageButton[4] = CommonSkill_LifeSkill
	g_CommonSkill_PageButton[5] = CommonSkill_AutoAttack
	g_CommonSkill_PageButton[6] = CommonSkill_ZongMenSkill
		
	g_PageTipsPos[1] = "{0.000000,28.000000}" 
	g_PageTipsPos[2] = "{0.000000,64.000000}" 
	g_PageTipsPos[3] = "{0.000000,100.000000}"
	g_PageTipsPos[4] = "{0.000000,136.000000}"
	g_PageTipsPos[5] = "{0.000000,172.000000}"
	g_PageTipsPos[6] = "{0.000000,208.000000}"
	
end

function CommonSkill_OnEvent(event)

	if ( event == "TOGLE_COMMONSKILL_PAGE" ) then
		local selfUnionPos = Variable:GetVariable("SkillUnionPos");
		if(selfUnionPos ~= nil) then
			CommonSkill_Frame:SetProperty("UnifiedPosition", selfUnionPos);
		end
		CommonSkill_Open();
		CommonSkill_Update();
		CommonSkill_ShowPage()
		return;
	elseif ( event == "SKILL_UPDATE" and this:IsVisible() ) then
		CommonSkill_Update();
	elseif ( event == "TOGLE_SKILL_BOOK" ) then
		CommonSkill_Close();
	elseif ( event == "TOGLE_LIFE_PAGE" ) then
		CommonSkill_Close();
	elseif ( event == "CLOSE_SKILL_BOOK" ) then
		CommonSkill_Close();
	end

	-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		CommonSkill_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置	
		CommonSkill_Frame_On_ResetPos()
	elseif (event == "NOTIFY_POP_UITIP" and arg0 == "CommonSkill") then
        g_NeedTipText = tonumber(arg1)
        g_NeedTipID = tonumber(arg2)
        if not this:IsVisible() then
            return
        end

		CommonSkill_FreshManGuide(1,g_NeedTipText,g_NeedTipID)
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998633007) then	--服务端传数据
	
		local bIsShowHotPoint = Get_XParam_INT(0)	
		if bIsShowHotPoint == 1 then
			CommonSkill_ZongMenSkill_Tips:Show()	
		else
			CommonSkill_ZongMenSkill_Tips:Hide()		
		end
		
	end

end

function CommonSkill_OnShown()
	CommonSkill_Update();
end

function CommonSkill_Update()


	CommonSkill_Target_Skill_Name : SetText("");
	CommonSkill_Target_Skill_Explain : SetText("");
	CommonSkill_Target_Skill:SetActionItem(-1);
	CommonSkill_ActionSkill : SetCheck(0);
	CommonSkill_LifeSkill : SetCheck(0);
	CommonSkill_CommonlySkill : SetCheck(1);

	if Current_Page == 0 then
		CommonSkill_PageUp : Disable();
	else
		CommonSkill_PageUp : Enable();
	end
	
--	local nLifeAbilityCount = GetActionNum("life");
--	local i=1;

--	while i <= nLifeAbilityCount do
--		local theAction = EnumAction(i-1, "life");

--		if theAction:GetID() ~= 0 then
--			LIFE_BUTTONS[i]:SetActionItem(theAction:GetID());
--			LIFE_INDEX[i] = theAction:GetID();

--			local lifeid =	LifeAbility : GetLifeAbility_Number(LIFE_INDEX[i]);
--			local life_level= Player:GetAbilityInfo(lifeid,"level");
--			LIFE_LEVEL[i] : SetText(life_level);
--		end
--		i = i+1;
--	end
	
	local nSumSkill = GetActionNum("skill");
	local nCommonIndex = 1;
	
	for i=1, COMMON_BUTTONS_NUM do
		COMMON_BUTTONS[i]:SetActionItem(-1);
		COMMON_INDEX[i] = -1;
	end
	local Begin_Index = 0;
	local nSumCommonSkill = 0;
	if(Current_Page==0)then
		nCommonIndex = 3;
		local thePetFight = Pet:GetPetFightAction();
		local thePetRelex = Pet:GetPetRelaxAction();
		if(thePetFight:GetID() and thePetRelex:GetID())then
			COMMON_BUTTONS[1]:SetActionItem(thePetFight:GetID());
			COMMON_BUTTONS[2]:SetActionItem(thePetRelex:GetID());
			COMMON_INDEX[1] = thePetFight:GetID();
			COMMON_INDEX[2] = thePetRelex:GetID();
		end
		nCommonIndex = 5;
		local thePetPossession = Pet:GetPetPossessionAction()
		local thePetRestore = Pet:GetPetRestoreAction()
		if (thePetPossession:GetID() and thePetRestore:GetID()) then
			COMMON_BUTTONS[3]:SetActionItem(thePetPossession:GetID())
			COMMON_BUTTONS[4]:SetActionItem(thePetRestore:GetID())
			COMMON_INDEX[3] = thePetPossession:GetID()
			COMMON_INDEX[4] = thePetRestore:GetID()
		end
	end
	for i=1, nSumSkill do
		theAction = EnumAction(i-1, "skill");
		if theAction:GetOwnerXinfa() == -9999 then			
			if (CommonSkill_IsZhenFaSkill(theAction:GetDefineID()) == 0 and (theAction:GetDefineID() < 2500 or theAction:GetDefineID() > 2547) and (theAction:GetDefineID() < 3566 or theAction:GetDefineID() > 3577) and (theAction:GetDefineID() < 3588 or theAction:GetDefineID() > 3590) --加一层判断，不显示武林秘籍
			and (theAction:GetDefineID() < 4533 or theAction:GetDefineID() > 4536) and (theAction:GetDefineID() < 4528 or theAction:GetDefineID() > 4529) --加一层判断，不显丛刃相关技能 
			and ((theAction:GetDefineID() < g_commonskill_zdzdskill._start ) or (theAction:GetDefineID() > g_commonskill_zdzdskill._end ) ) and CommonSkill_IsZongMenSkill(theAction:GetDefineID()) == 0
				 and IsLMSJSecond(theAction:GetDefineID()) == 0 and IsJYJYSecond(theAction:GetDefineID()) == 0 and IsWJQFSecond(theAction:GetDefineID()) == 0) then
			nSumCommonSkill = nSumCommonSkill + 1;
			if(Current_Page==0) then
				if(nSumCommonSkill == 1)then
					Begin_Index = i;
				end
			else
				--modify by guochenshu 2010-09-08 增加了两个附体技能 要向后再移两个位置
				if nSumCommonSkill == Current_Page*COMMON_BUTTONS_NUM+1-4  then
					Begin_Index = i;
					end	
				end	
			end
	
		end
	end
	
	

	
	--PushDebugMessage("sumcommon:"..tostring(nSumCommonSkill)..",index:"..tostring(Begin_Index)..",page:"..tostring(Current_Page)..",sumskill:"..tostring(nSumSkill))
	
	--bug30290，alan，2007-12-26
	--前面的代码在普通技能第一页添加了珍兽出战与珍兽休息两个技能，这样相当于普通技能的总数实际上多了2个
	--在判断是否允许翻页按钮时也需要考虑这多出来的2个技能
	--if (Current_Page+1)*COMMON_BUTTONS_NUM <= nSumCommonSkill then
	--modify by guochenshu 2010-09-08 增加了两个附体技能 要向后再移两个位置
	if (Current_Page+1)*COMMON_BUTTONS_NUM < nSumCommonSkill+4 then
		CommonSkill_PageDown : Enable();
	else
		CommonSkill_PageDown : Disable();
	end
	

	--1+Current_Page*COMMON_BUTTONS_NUM
	if Begin_Index~=0 then
		for i=Begin_Index, nSumSkill do
			theAction = EnumAction(i-1, "skill");
			if theAction:GetOwnerXinfa() == -9999 then
				if (CommonSkill_IsZhenFaSkill(theAction:GetDefineID()) == 0 and (theAction:GetDefineID() < 2500 or theAction:GetDefineID() > 2547) and (theAction:GetDefineID() < 3566 or theAction:GetDefineID() > 3577) and (theAction:GetDefineID() < 3588 or theAction:GetDefineID() > 3590) --加一层判断，不显示武林秘籍
				and (theAction:GetDefineID() < 4533 or theAction:GetDefineID() > 4536) and (theAction:GetDefineID() < 4528 or theAction:GetDefineID() > 4529)	--加一层判断，不显丛刃相关技能 
				and ((theAction:GetDefineID() < g_commonskill_zdzdskill._start ) or (theAction:GetDefineID() > g_commonskill_zdzdskill._end ) ) and CommonSkill_IsZongMenSkill(theAction:GetDefineID()) == 0
					 and IsLMSJSecond(theAction:GetDefineID()) == 0 and IsJYJYSecond(theAction:GetDefineID()) == 0 and IsWJQFSecond(theAction:GetDefineID()) == 0) then
				COMMON_BUTTONS[nCommonIndex]:SetActionItem(theAction:GetID());
				COMMON_INDEX[nCommonIndex] = theAction:GetID();
				local nCommonId = LifeAbility : GetLifeAbility_Number(COMMON_INDEX[nCommonIndex]);
				
				if(Player:GetSkillInfo(nCommonId,"learn")) then
					COMMON_BUTTONS[nCommonIndex] : Enable();
				else
					COMMON_BUTTONS[nCommonIndex] : Disable();
				end
				
				nCommonIndex = nCommonIndex+1;
	
				if nCommonIndex > COMMON_BUTTONS_NUM then
					break;
					end
				end
			end
		end
	end
	
	if(COMMON_INDEX[Current] ~= -1) then
		CommonSkill_Buttons_Clicked(Current);
	end;
	
end

function CommonSkill_IsZongMenSkill(nID)
	local skillid = {5194,5195,5196,5197,5198,5199}
	for i=1,6 do
		if(nID == skillid[i]) then
			return 1
		end
	end
	return 0
end

function CommonSkill_IsZhenFaSkill(nID)
	local skillid = {3229,3250,3251,3252}
	for i=1,4 do
		if(nID == skillid[i]) then
			return 1
		end
	end
	return 0
end

function CommonSkill_Buttons_Clicked(nIndex)

	if( COMMON_INDEX[nIndex] == -1) then
		return;
	end;

	COMMON_BUTTONS[Current]:SetPushed(0);
	

--	if( Current == nIndex) then
--		return;
--	end;

	Current = nIndex;
	COMMON_BUTTONS[Current]:SetPushed(1);
	if(Current_Page==0 and (nIndex == 1 or nIndex == 2 or nIndex == 3 or nIndex == 4))then
		local strName = "";
		local strExplan ="";
		local thisAction;
		if(nIndex ==1 )then
			thisAction = Pet:GetPetFightAction();
			strExplan = "#{Action_Pet_Fight_Exp}"; --"#c54FF00（拖至快捷栏中使用）#r#cFFFFFF运气时间：2.5秒#r召唤当前选择的珍兽出战，需要珍兽快乐在60以上。"
		elseif (nIndex == 2) then
			thisAction = Pet:GetPetRelaxAction();
			strExplan = "#{Action_Pet_Relex_Exp}";--"#c54FF00（拖至快捷栏中使用）#r#cFFFFFF运气时间：2.5秒#r召唤当前选择的珍兽出战，需要珍兽快乐在60以上。"
		elseif (nIndex == 3) then
			thisAction = Pet:GetPetPossessionAction()
			strExplan = "#{ZSHT_BC_1008_13}"
		elseif (nIndex == 4) then
			thisAction = Pet:GetPetRestoreAction()
			strExplan = "#{ZSHT_BC_1008_14}"
		end
		strName = thisAction:GetName();
		CommonSkill_Target_Skill_Name : SetText( strName );
		CommonSkill_Target_Skill_Explain : SetText( strExplan);

	else
		local commonid =	LifeAbility : GetLifeAbility_Number(COMMON_INDEX[nIndex]);
		local strName = Player:GetSkillInfo(commonid,"name");
		CommonSkill_Target_Skill_Name : SetText( strName );
	
		strName = Player:GetSkillInfo(commonid,"explain");
		strName2 = Player:GetSkillInfo(commonid,"skilldata");
		CommonSkill_Target_Skill_Explain : SetText( strName.."\n"..strName2 );
	end



	
	CommonSkill_Target_Skill:SetActionItem(COMMON_INDEX[nIndex]);

	if(Player:GetSkillInfo(commonid,"passivity") == 0) then
		CommonSkill_Use : Show();
--	else
--		CommonSkill_OnClose();
	end
	
end

function CommonSkill_Button_Clicked()

	if (Current ~= -1 and COMMON_INDEX[Current] ~= -1) then	
		if(Current_Page==0 and (Current ==1 or Current ==2 or Current == 3 or Current == 4))then
			local thisAction;
			if(Current ==1 )then
				thisAction = Pet:GetPetFightAction();
			elseif (Current == 2) then
				thisAction = Pet:GetPetRelaxAction();
			elseif (Current == 3) then
				thisAction = Pet:GetPetPossessionAction()
			elseif (Current == 4) then
				thisAction = Pet:GetPetRestoreAction()
			end
			if(thisAction:GetID()~=0)then
				CommonSkill_Target_Skill:DoAction();
			end
		else
			local commonid =	LifeAbility : GetLifeAbility_Number(COMMON_INDEX[Current]);
		
			if(Player:GetSkillInfo(commonid,"passivity") == 0) then
				CommonSkill_Target_Skill:DoAction();
			end
		end

	end
		
end

function CommonSkill_Action_Page_Switch(nPageNumber)
	
	local menpai = Player:GetData("MEMPAI");
	if(menpai == 9) then
		if g_CommonSkill_PageButton[nPageNumber] ~= nil then
			g_CommonSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		CommonSkill_ClearPage()
		PushDebugMessage("你还没有拜入门派。");
		return; 
	end;
	
	if "CommonSkill" == GetFreshManGuideOwner() then
        CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
		PushEvent("OPEN_FRESHMAN_NEWNPCCHAT",8)
    end
	OpenSkillBook();
	CommonSkill_OnClose();
	
end

function CommonSkill_Zhenfa_Page_Switch()
	OpenZhenfaFream();
	CommonSkill_OnClose();

end

function CommonSkill_Life_Page_Switch()
	OpenLifePage();
	CommonSkill_OnClose();

end

function CommonSkill_AutoAttack_Page_Switch(nPageNumber)
	local myLevel = Player:GetData("LEVEL")
	local nMenpai = Player:GetData("MEMPAI")
	local nCanShow = 1
	if myLevel >= 50 and nMenpai ~= 9 then
		PushEvent("TRIGGER_ZIDONGZHANDOU","config")
		DataPool:Lua_SetLastSkill_UI(6)
		CommonSkill_OnClose()
	elseif myLevel < 50 then
		PushDebugMessage("#{ZDZD_200724_62}")
		nCanShow = 0
	else
		PushDebugMessage("#{ZDZD_200724_63}")
		nCanShow = 0
	end
	if nCanShow == 0 then
		if g_CommonSkill_PageButton[nPageNumber] ~= nil then
			g_CommonSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		CommonSkill_ClearPage()
	end
end

function CommonSkill_ZongMen_Page_Switch(nPageNumber)
	if DataPool:Lua_CheckOpenTalent() == 1 then
		ToggleTalentPage()
		CommonSkill_OnClose()
	else
		if g_CommonSkill_PageButton[nPageNumber] ~= nil then
			g_CommonSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		CommonSkill_ClearPage()
	end
end

function CommonSkill_SetTabColor()
	

	local selColor = "#e010101#Y";
	local noselColor = "#e010101";
	local tab = {
								[0] = CommonSkill_CommonlySkill,
								CommonSkill_ActionSkill,
								CommonSkill_LifeSkill,
								CommonSkill_ZhenfaSkill,
								CommonSkill_AutoAttack,
								CommonSkill_ZongMenSkill,
							};

	local TAB_TEXT = {
		[0] = "普通",
		"门派",
		"生活",
		"#{JBGXW_150526_215}",
		"#{ZDZD_200724_08}",
		"#{ZMTF_230628_20}",
	};
	
	tab[0]:SetText(selColor..TAB_TEXT[0]);
	tab[1]:SetText(noselColor..TAB_TEXT[1]);
	tab[2]:SetText(noselColor..TAB_TEXT[2]);
	tab[3]:SetText(noselColor..TAB_TEXT[3]);
	tab[4]:SetText(noselColor..TAB_TEXT[4]);
	tab[5]:SetText(noselColor..TAB_TEXT[5]);
end

function CommonSkill_Page(nPage)
	
	Current_Page = Current_Page + nPage;

	CommonSkill_Update();

end

function CommonSkill_ShowPage()

	for i = 1, table.getn(g_CommonSkill_PageButton) do
		g_CommonSkill_PageButton[i]:Hide()
	end
	local nPageNumber = tonumber(Variable:GetVariable("SkillPageNumber"));
	CommonSkill_ClearPage()
	
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_CommonSkill_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_CommonSkill_PageButton) do
			if i ~= nPageNumber then
				g_CommonSkill_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_CommonSkill_PageOrder = {}
	local g_commonskill_PageCount = 0
	
	for i = 1, table.getn(g_CommonSkill_PageButton) do
		if CommonSkill_CheckPage(i) == 1 then
			g_commonskill_PageCount = g_commonskill_PageCount + 1
			g_CommonSkill_PageButton[g_commonskill_PageCount]:Show()
			g_CommonSkill_PageButton[g_commonskill_PageCount]:SetText(g_CommonSkill_Page[i].Text)	
			g_CommonSkill_PageOrder[g_commonskill_PageCount] = i
		end
	end
	
	for idx = 1, table.getn(g_CommonSkill_PageOrder) do
		if g_CommonSkill_PageOrder[idx] == 6 and g_PageTipsPos[idx] then -- 其他
			local newpos = g_PageTipsPos[idx]
			CommonSkill_ZongMenSkill_Tips:SetProperty("UnifiedXPosition", newpos);
		end
	end
		
end

function CommonSkill_OnPageClicked(idx)

	Variable:SetVariable("SkillPageNumber", tostring(idx), 1);
	idx = g_CommonSkill_PageOrder[idx]
	local nPageNumber = tonumber(Variable:GetVariable("SkillPageNumber"));
	
	if idx == 1 then--普通
		CommonSkill_ClearPage()
	elseif idx == 2 then--门派
		CommonSkill_Action_Page_Switch(nPageNumber)
	elseif idx == 3 then--阵法
		CommonSkill_Zhenfa_Page_Switch()
	elseif idx == 4 then--生活
		CommonSkill_Life_Page_Switch()
	elseif idx == 5 then--战斗
		CommonSkill_AutoAttack_Page_Switch(nPageNumber)
	elseif idx == 6 then --绝学
		CommonSkill_ZongMen_Page_Switch(nPageNumber)
	end
end

function CommonSkill_CheckPage(idx)
	if idx == 1 then--普通
		return 1
	elseif idx == 2 then--门派
		return 1
	elseif idx == 3 then--阵法
		if Player:GetData("Is2606S") == 1 then
			return 0
		end
		return 1
	elseif idx == 4 then--生活
		return 1
	elseif idx == 5 then--战斗
		return 1
	elseif idx == 6 then--绝学
		return 1
	end
	return 0
end

function CommonSkill_ClearPage()
	Variable:SetVariable("SkillPageNumber", tostring(0), 1)
end

function CommonSkill_OnClose()
	Variable:SetVariable("SkillUnionPos", CommonSkill_Frame:GetProperty("UnifiedPosition"), 1);
	CommonSkill_Close();
end



function CommonSkill_Open()
	if TLCJ:IsInTLCJScene() > 0 then
		PushDebugMessage("#{TLCJ_20240709_69}")
		return 
	end
	this:Show();
end
function CommonSkill_Close()
    if "CommonSkill" == GetFreshManGuideOwner() then
        CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
    end
	this:Hide();
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function CommonSkill_Frame_On_ResetPos()

	CommonSkill_Frame : SetProperty("UnifiedXPosition", g_CommonSkill_Frame_UnifiedXPosition);
	CommonSkill_Frame : SetProperty("UnifiedYPosition", g_CommonSkill_Frame_UnifiedYPosition);

end

function CommonSkill_FreshManGuide(nType, nTextID, nPosID)
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
    local nPosX = tonumber(CommonSkill_Frame:GetProperty("AbsoluteXPosition"))
    local nPosY = tonumber(CommonSkill_Frame:GetProperty("AbsoluteYPosition"))	
	
	if 1 == nPosID then
		fX = tonumber(CommonSkill_ActionSkill:GetProperty("AbsoluteXPosition"))
		fY = tonumber(CommonSkill_ActionSkill:GetProperty("AbsoluteYPosition"))
		local fH = tonumber(CommonSkill_ActionSkill:GetProperty("AbsoluteHeight"))
		local fW = tonumber(CommonSkill_ActionSkill:GetProperty("AbsoluteWidth"))
		fX = math.floor(tonumber(fX + nPosX + fW) - 10)
		fY = math.floor(tonumber(fY + nPosY + (fH)) + 270)
		if(SystemSetup:IsClassic() == 0) then  --尼玛，唯美字体改了导致位置变了
			fX = fX+ 40
		end
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 24, 1, "CommonSkill")
	end
	
end
