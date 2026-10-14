local Current_Xinfa_Name,Current_Xinfa_Level;

local Current_Xinfa = 1;
local Current_Skill = -1;
local Current_Nuqi = -1;

--local XINFA_LEVEL = {};
local XINFA_INDEX = {};
local XINFA_BUTTONS_NUM = 8;
local XINFA_BUTTONS = {};

local SKILL_INDEX = {};
local SKILL_BUTTONS_NUM = 5;
local SKILL_BUTTONS = {};

local g_CurGuide = -1;
--local NUQI_INDEX = {};
--local NUQI_BUTTONS_NUM = 3;
--local NUQI_BUTTONS = {};

--门派主属性表
local MenPai_MainAttr = {
[1] = {image = "set:UIIcons image:Ice_Repellency_Normal", Tooltip = "MPZSX_20071221_11" },
[2] = {image = "set:UIIcons image:Fire_Repellency_Normal", Tooltip = "MPZSX_20071221_12" },
[3] = {image = "set:UIIcons image:Thunder_Repellency_Normal", Tooltip = "MPZSX_20071221_13" },
[4] = {image = "set:UIIcons image:Poison_Repellency_Normal", Tooltip = "MPZSX_20071221_14" } };

local MenPai_UsedAttr = {
[0] = {image = "set:Menpaishuxing image:Shuxing_Dark", Tooltip = "MPZSX_20071221_13", },			--少林
[1] = {image = "set:Menpaishuxing image:Shuxing_Fire", Tooltip = "MPZSX_20071221_12",},				--明教
[2] = {image = "set:Menpaishuxing image:Shuxing_PoisonFire", Tooltip = "MPZSX_20071221_15",},		--丐帮
[3] = {image = "set:Menpaishuxing image:Shuxing_DarkIce", Tooltip = "MPZSX_20071221_16",},			--武当
[4] = {image = "set:Menpaishuxing image:Shuxing_IceDark", Tooltip = "MPZSX_20071221_17",},			--峨嵋
[5] = {image = "set:Menpaishuxing image:Shuxing_Poison", Tooltip = "MPZSX_20071221_14",},			--星宿
[6] = {image = "set:Menpaishuxing image:Shuxing_FIPD", Tooltip = "MPZSX_20071221_18",},				--天龙
[7] = {image = "set:Menpaishuxing image:Shuxing_Ice", Tooltip = "MPZSX_20071221_11",},				--天山
[8] = {image = "set:Menpaishuxing image:Shuxing_FirePoison", Tooltip = "MPZSX_20071221_19",},		--逍遥
[9] = {image = "", Tooltip = "无门派",},															--无门派
[10]= {image = "set:Menpaishuxing image:Shuxing_Dark", Tooltip = "MPZSX_20071221_13", },			--慕容
[11]= {image = "set:Menpaishuxing image:Shuxing_DarkPoison", Tooltip = "XMPTM_130123_36",},				--唐门
[12]= {image = "set:Menpaishuxing image:Shuxing_DarkFire", Tooltip = "XMPGG_160524_01",},				--鬼谷
[13]= {image = "set:Menpaishuxing image:Shuxing_KunLun", Tooltip = "THDXG_190705_02",},				--桃花岛
[14]= {image = "set:Menpaishuxing image:Shuxing_CongRen", Tooltip = "XMPHM_210604_25",},				--从刃
[15]= {image = "set:Menpaishuxing image:Shuxing_PoisonIce", Tooltip = "XMPHM_210604_38",},				--menpai15
};

local g_MenPaiCount = 15;--menpai15 mptodo
-- 界面的默认相对位置
local g_ActionSkill_Frame_UnifiedXPosition;
local g_ActionSkill_Frame_UnifiedYPosition;

local g_actionskill_zdzdskill = {
	_start = 4742,
	_end = 4746,
}

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_ActionSkill_Page = {
	[1] = {Text = "#e010101".."#{INTERFACE_XML_494}",	NeedCheck = 0, Tip = ""},
	[2] = {Text = "#e010101#Y".."#{INTERFACE_XML_448}",	NeedCheck = 0, Tip = ""},
	[3] = {Text = "#e010101".."#{JBGXW_150526_215}",	NeedCheck = 0, Tip = ""},
	[4] = {Text = "#e010101".."#{INTERFACE_XML_635}",	NeedCheck = 0, Tip = ""},
	[5] = {Text = "#e010101".."#{ZDZD_200724_08}",		NeedCheck = 0, Tip = ""},
	[6] = {Text = "#e010101".."#{ZMTF_230628_20}",		NeedCheck = 0, Tip = ""},
}
local g_ActionSkill_PageButton = {}
local g_ActionSkill_PageOrder = {}
local g_PageTipsPos = {}

function ActionSkill_PreLoad()
	this:RegisterEvent("TOGLE_SKILL_BOOK",true);
	this:RegisterEvent("TOGLE_COMMONSKILL_PAGE",false);
	this:RegisterEvent("TOGLE_LIFE_PAGE",false);
	this:RegisterEvent("SKILL_UPDATE",false);
	this:RegisterEvent("CLOSE_SKILL_BOOK",false);
	this:RegisterEvent("EQUIPGEM_XIULIAN_SCORE_CHANGE",false);

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("NOTIFY_POP_UITIP",false)
	this:RegisterEvent("UI_COMMAND", true)

end

function ActionSkill_OnLoad()
	XINFA_BUTTONS[1] = ActionSkill_Xinfa1;
	XINFA_BUTTONS[2] = ActionSkill_Xinfa2;
	XINFA_BUTTONS[3] = ActionSkill_Xinfa3;
	XINFA_BUTTONS[4] = ActionSkill_Xinfa4;
	XINFA_BUTTONS[5] = ActionSkill_Xinfa5;
	XINFA_BUTTONS[6] = ActionSkill_Xinfa6;
	XINFA_BUTTONS[7] = ActionSkill_Xinfa7;
	XINFA_BUTTONS[8] = ActionSkill_Xinfa8;

	SKILL_BUTTONS[1] = ActionSkill_Zhaoshi1;
	SKILL_BUTTONS[2] = ActionSkill_Zhaoshi2;
	SKILL_BUTTONS[3] = ActionSkill_Zhaoshi3;
	SKILL_BUTTONS[4] = ActionSkill_Zhaoshi4;
	SKILL_BUTTONS[5] = ActionSkill_Zhaoshi5;

--	NUQI_BUTTONS[1] = ActionSkill_Nuqi1;
--	NUQI_BUTTONS[2] = ActionSkill_Nuqi2;
--	NUQI_BUTTONS[3] = ActionSkill_Nuqi3;

--	XINFA_LEVEL[1] = ActionSkill_Xinfa1_Level;
--	XINFA_LEVEL[2] = ActionSkill_Xinfa2_Level;
--	XINFA_LEVEL[3] = ActionSkill_Xinfa3_Level;
--	XINFA_LEVEL[4] = ActionSkill_Xinfa4_Level;
--	XINFA_LEVEL[5] = ActionSkill_Xinfa5_Level;
--	XINFA_LEVEL[6] = ActionSkill_Xinfa6_Level;
	--ActionSkill_SetTabColor();

	-- 保存界面的默认相对位置
	g_ActionSkill_Frame_UnifiedXPosition	= ActionSkill_Frame : GetProperty("UnifiedXPosition");
	g_ActionSkill_Frame_UnifiedYPosition	= ActionSkill_Frame : GetProperty("UnifiedYPosition");

	g_ActionSkill_PageButton[1] = ActionSkill_CommonlySkill
	g_ActionSkill_PageButton[2] = ActionSkill_ActionSkill
	g_ActionSkill_PageButton[3] = ActionSkill_ZhenfaSkill
	g_ActionSkill_PageButton[4] = ActionSkill_LifeSkill
	g_ActionSkill_PageButton[5] = ActionSkill_AutoAttack
	g_ActionSkill_PageButton[6] = ActionSkill_ZongMenSkill
	
	g_PageTipsPos[1] = "{0.000000,28.000000}" 
	g_PageTipsPos[2] = "{0.000000,64.000000}" 
	g_PageTipsPos[3] = "{0.000000,100.000000}"
	g_PageTipsPos[4] = "{0.000000,136.000000}"
	g_PageTipsPos[5] = "{0.000000,172.000000}"
	g_PageTipsPos[6] = "{0.000000,208.000000}"
	
end
-- OnEvent
function ActionSkill_OnEvent(event)

	if ( event == "TOGLE_SKILL_BOOK" ) then
			local selfUnionPos = Variable:GetVariable("SkillUnionPos");
			if(selfUnionPos ~= nil) then
				ActionSkill_Frame:SetProperty("UnifiedPosition", selfUnionPos);
			end
			ActionSkill_Open();
			ActionSkill_Update();
			ActionSkill_ShowPage()
	elseif( event == "SKILL_UPDATE" and this:IsVisible()) then
		ActionSkill_Update();
	elseif ( event == "TOGLE_LIFE_PAGE" ) then
		ActionSkill_Close();
	elseif ( event == "TOGLE_COMMONSKILL_PAGE" ) then
		ActionSkill_Close();
	elseif ( event == "CLOSE_SKILL_BOOK" ) then
		
		ActionSkill_Close();
	elseif( event == "ACTION_UPDATE" ) then
		ActionSkill_NewSkillStudy();

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		ActionSkill_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置
		ActionSkill_Frame_On_ResetPos()
	elseif (event == "NOTIFY_POP_UITIP") then
        if "ActionSkill" == arg0 and this:IsVisible() and Player:GetData("LEVEL") <= 20 then
            ActionSkill_FreshManGuide(1, tonumber(arg1), tonumber(arg2))
        end	
	elseif (event == "EQUIPGEM_XIULIAN_SCORE_CHANGE") then
		if this:IsVisible() then
			ActionSkill_ShowGemScore()
		end
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998633007) then	--服务端传数据
	
		local bIsShowHotPoint = Get_XParam_INT(0)	
		if bIsShowHotPoint == 1 then
			ActionSkill_ZongMenSkill_Tips:Show()	
		else
			ActionSkill_ZongMenSkill_Tips:Hide()		
		end
		
	end
end
--学会了新技能了
function ActionSkill_NewSkillStudy()
	for i=1,6 do
		XINFA_BUTTONS[i]:SetNewFlash();
	end
	for i=1,5 do
		SKILL_BUTTONS[i]:SetNewFlash();
	end
end

function ActionSkill_OnShown()
	ActionSkill_Update();
end

function ActionSkill_Clear()
	Current_Xinfa = -1;

	for i=1, XINFA_BUTTONS_NUM do
		XINFA_BUTTONS[i]:SetActionItem(-1);
		XINFA_INDEX[i] = -1;
--		XINFA_LEVEL[i] : SetText("");
	end

--	for i=1, NUQI_BUTTONS_NUM do
--		NUQI_BUTTONS[i]:SetActionItem(-1);
--		NUQI_INDEX[i] = -1;
--	end

	for i=1, SKILL_BUTTONS_NUM do
		SKILL_BUTTONS[i]:SetActionItem(-1);
		SKILL_INDEX[i] = -1;
	end

end

function ActionSkill_Update()

	local i;
	--ActionSkill_Xinfa_Frame : Hide();
	--ActionSkill_Zhaoshi_Frame : Hide();
	ActionSkill_Use : Hide();
	ActionSkill_Explain : SetText("");
	ActionSkill_Name : SetText("");
	ActionSkill_LifeSkill : SetCheck(0);
	ActionSkill_CommonlySkill : SetCheck(0);
	ActionSkill_ActionSkill : SetCheck(1);
	ActionSkill_XinfaNotice : SetText("#{DBXF_XML_1}" .. Player:GetData("XINFASCORE"));
	ActionSkill_XiulianNotice : SetText("#{DBXF_XML_2}" .. Player:GetData("XIULIANSCORE"));
	ActionSkill_ShowGemScore()
	
--显示心法
	for i=1, XINFA_BUTTONS_NUM do
		local theAction = EnumAction(i-1, "xinfa");

		if theAction:GetID() ~= 0 then
			XINFA_BUTTONS[i]:SetActionItem(theAction:GetID());


			XINFA_INDEX[i] = theAction:GetID();
			local nXinfaId = LifeAbility : GetLifeAbility_Number(XINFA_INDEX[i]);
			local nXinfa_level = Player:GetXinfaInfo(nXinfaId,"level");

			local str = "BotRight "..tostring(nXinfa_level);

			--XINFA_BUTTONS[i]:SetProperty("CornerChar",str);


		else
			XINFA_BUTTONS[i]:SetActionItem(-1);
			XINFA_INDEX[i] = -1;
--			XINFA_LEVEL[i] : SetText("没有");
		end
	end


	if(Current_Xinfa ~= -1 and XINFA_BUTTONS[Current_Xinfa] ~= -1) then
		ActionSkill_Update_Cliecked(Current_Xinfa,1);
	elseif(Current_Skill ~= -1 and SKILL_BUTTONS[Current_Skill] ~= -1) then
		ActionSkill_Update_Cliecked(Current_Skill,2);
	end
	ActionSkill_UpdateMenPaiText();		--更新显示文字，如果玩家改变了门派
end

function ActionSkill_Update_Cliecked(nIndex, Actiontype)
	local i;
	local theAction;
	local strName,strName2;

	if(Actiontype == 1) then

		if(XINFA_INDEX[nIndex] == -1) then
			return;
		end;

		--ActionSkill_Zhaoshi_Frame:Hide();
		ActionSkill_ZhaoshiTarget:Hide();
		--ActionSkill_Xinfa_Frame:Show();
		ActionSkill_XinfaTarget:Show();
		ActionSkill_Use : Hide();

		ActionSkill_XinfaTarget:SetActionItem(XINFA_INDEX[nIndex]);

		local nXinfaId = LifeAbility : GetLifeAbility_Number(XINFA_INDEX[nIndex]);

		strName = Player:GetXinfaInfo(nXinfaId,"name");
		Current_Xinfa_Name = strName;
	 	strName2= Player:GetXinfaInfo(nXinfaId,"level");
	 	Current_Xinfa_Level = strName2;

		ActionSkill_Name : SetText( strName .."\n" .. "心法等级:" .. strName2);
		ActionSkill_Name : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
		ActionSkill_Name : SetProperty("VertFormatting","VertCentred")
		ActionSkill_XinfaTarget : Enable();
--		XINFA_LEVEL[nIndex] : SetText(tostring(strName2));

--add:lby2015 start
	--PushDebugMessage("1111111")
--获得现在的心法等级
	local nXinfaLevel = GetXinfaLevel( nXinfaId );
--获得升级心法需要的金钱
	local nMoneyNow,nGold,nSilverCoin,nCopperCoin = GetUplevelXinfaSpendMoney(nXinfaId,nXinfaLevel + 1);
	--获得升级心法需要的经验
	local nExp = GetUplevelXinfaSpendExp(nXinfaId,nXinfaLevel + 1);
	local nPlayerLevel = Player:GetData("LEVEL");
	--PushDebugMessage(nPlayerLevel);

	if nMoneyNow < 0 then
		nMoneyNow = 0
	end

	if nExp < 0 then
		nExp = 0
	end
	local strExp = "#{XFXL_151203_05}"..nExp
	local defineHumanMaxLevel = Player:GetDefineHumanMaxLevel()
	if(nXinfaLevel == defineHumanMaxLevel and nIndex < 8 or nXinfaLevel == 300) then
		 strExp = "#{XFXL_151203_05}".."#{XFXL_151203_07}"
		 nMoneyNow = 0
		  --PushDebugMessage("333")
	end
	
	
	ActionSkill_LearnExp : SetText(strExp)
	
	if(nXinfaLevel == defineHumanMaxLevel and nIndex < 8 or nXinfaLevel == 300) then
		ActionSkill_LearnDemand_Jiaozi:Hide()
		ActionSkill_LearnDemand_Jiaozi_Text:SetText("#{XFXL_151203_06}".."#{XFXL_151203_07}")
	else
		ActionSkill_LearnDemand_Jiaozi_Text:SetText("#{XFXL_151203_06}")
		ActionSkill_LearnDemand_Jiaozi:Show()
		ActionSkill_LearnDemand_Jiaozi:SetProperty("MoneyNumber", tostring(nMoneyNow));
		ActionSkill_LearnDemand_Jiaozi_Text:SetText("#{XFXL_151203_06}")
	end
	;
	
--add:lby2015 end


	 	strName = Player:GetXinfaInfo(nXinfaId,"explain");
	 	ActionSkill_Explain : SetText(strName);

		for i=1, XINFA_BUTTONS_NUM do
			local theAction = EnumAction(i-1, "xinfa");

			if theAction:GetID() ~= 0 then
				XINFA_BUTTONS[i]:SetActionItem(theAction:GetID());
				XINFA_INDEX[i] = theAction:GetID();
				local nXinfaId = LifeAbility : GetLifeAbility_Number(XINFA_INDEX[i]);
				local nXinfa_level = Player:GetXinfaInfo(nXinfaId,"level");

--				XINFA_LEVEL[i] : SetText(tostring(nXinfa_level));
--				XINFA_LEVEL[i] : Show();

			else
				XINFA_BUTTONS[i]:SetActionItem(-1);
				XINFA_INDEX[i] = -1;
--				XINFA_LEVEL[i] : SetText("没有");
			end
		end

		for i=1, SKILL_BUTTONS_NUM do
			SKILL_BUTTONS[i]:SetActionItem(-1);
			SKILL_INDEX[i] = -1;
		end

		local nSumSkill = GetActionNum("skill");
		local nSkillIndex = 1;
		for i=1, nSumSkill do
			theAction = EnumAction(i-1, "skill");
			local defid = theAction:GetDefineID()
			if ((defid < 4533 or defid > 4536) and (defid < 4528 or defid > 4529) and (defid < g_actionskill_zdzdskill._start or defid > g_actionskill_zdzdskill._end) 
				and (defid < 5189 or defid > 5193) and IsLMSJSecond(defid) == 0 and IsJYJYSecond(defid) == 0 and IsWJQFSecond(defid) == 0) then	--加一层判断，不显丛刃相关技能 
				if theAction:GetOwnerXinfa() == XINFA_INDEX[nIndex] then
					SKILL_BUTTONS[nSkillIndex]:SetActionItem(theAction:GetID());
					SKILL_INDEX[nSkillIndex] = theAction:GetID();
					nSkillIndex = nSkillIndex+1;
				end
			end
		end

		if(Current_Xinfa ~= -1) then
			XINFA_BUTTONS[Current_Xinfa] : SetPushed(0);
		elseif(Current_Skill ~= -1) then
			SKILL_BUTTONS[Current_Skill] : SetPushed(0);
		elseif(Current_Nuqi ~= -1) then
			NUQI_BUTTONS[Current_Nuqi] : SetPushed(0);
		end;

		Current_Xinfa = nIndex;
		Current_Skill = -1;
		Current_Nuqi = -1;

		XINFA_BUTTONS[Current_Xinfa]:SetPushed(1);

		--标记
	elseif(Actiontype == 2) then

		if(SKILL_INDEX[nIndex] == -1) then
			return;
		end;

		if(Current_Skill ~= -1) then
			SKILL_BUTTONS[Current_Skill] : SetPushed(0);
		end

		Current_Skill = nIndex;
--		Current_Xinfa = -1;
		Current_Nuqi = -1;

		SKILL_BUTTONS[Current_Skill]:SetPushed(1);

		--ActionSkill_Xinfa_Frame:Hide();
		ActionSkill_XinfaTarget:Hide();
		--ActionSkill_Zhaoshi_Frame:Show();
		ActionSkill_ZhaoshiTarget:Show();

		ActionSkill_ZhaoshiTarget:SetActionItem(SKILL_INDEX[nIndex]);
		local nSkillId = LifeAbility : GetLifeAbility_Number(SKILL_INDEX[nIndex]);

		if( Player:GetSkillInfo(nSkillId,"passivity") == 1) then
	 		ActionSkill_Use : Hide();
	 	else
		 	ActionSkill_Use : Show();
		end

		strName = Player:GetSkillInfo(nSkillId,"name");

	 	if( Player:GetSkillInfo(nSkillId,"learn") ) then
--	 		strName2 = "已经学会";
	 		ActionSkill_Name : SetProperty("TextColours","tl:FFEFEFEF tr:FFEFEFEF bl:FFEFEFEF br:FFEFEFEF");
	 		ActionSkill_Name : SetProperty("VertFormatting","TopAligned")
	 		ActionSkill_ZhaoshiTarget : Enable();
	 	else
--		 	strName2 = "尚未学会";
		 	ActionSkill_Name : SetProperty("TextColours","tl:FFFF0000 tr:FFFF0000 bl:FFFF0000 br:FFFF0000");
		 	ActionSkill_Name : SetProperty("VertFormatting","TopAligned")
		 	ActionSkill_ZhaoshiTarget : Disable();
		end

		if nil ~= strName then
--			ActionSkill_Name : SetText( strName .."\n" .. "" .. Current_Xinfa_Name .. "  " .. Current_Xinfa_Level .. "级");
--小二说改的，杨耀做证。
			ActionSkill_Name : SetText( strName );

	 	end
	 	strName = Player:GetSkillInfo(nSkillId,"explain");
	 	strName2 = Player:GetSkillInfo(nSkillId,"skilldata");
	 	if nil~=strName or nil~=strName2 then
	 		ActionSkill_Explain : SetText(strName.."\n"..strName2);
	 	end

	elseif(Actiontype == 3) then

		if(NUQI_INDEX[nIndex] == -1) then
			return;
		end;

		if(Current_Xinfa ~= -1) then
			XINFA_BUTTONS[Current_Xinfa] : SetPushed(0);
		elseif(Current_Skill ~= -1) then
			SKILL_BUTTONS[Current_Skill] : SetPushed(0);
		elseif(Current_Nuqi ~= -1) then
			NUQI_BUTTONS[Current_Nuqi] : SetPushed(0);
		end;

		Current_Nuqi = nIndex;
		Current_Xinfa = -1;
		Current_Skill = -1;

		NUQI_BUTTONS[Current_Nuqi]:SetPushed(1);

		--ActionSkill_Xinfa_Frame:Hide();
		ActionSkill_XinfaTarget:Hide();
		--ActionSkill_Zhaoshi_Frame:Show();
		ActionSkill_ZhaoshiTarget:Show();

		ActionSkill_ZhaoshiTarget:SetActionItem(NUQI_INDEX[nIndex]);
		local nNuqiId = LifeAbility : GetLifeAbility_Number(NUQI_INDEX[nIndex]);

		if( Player:GetSkillInfo(nSkillId,"passivity") == 1) then
	 		ActionSkill_Use : Hide();
	 	else
		 	ActionSkill_Use : Show();
		end

		strName = Player:GetSkillInfo(nNuqiId,"name");

	 	if( Player:GetSkillInfo(nNuqiId,"learn") ) then
--	 		strName2 = "已经学会";
	 		ActionSkill_Name : SetProperty("TextColor","FFEFEFEF");
	 		ActionSkill_ZhaoshiTarget : Enable();
	 	else
--		 	strName2 = "尚未学会";
		 	ActionSkiActionSkill_Name : SetProperty("TextColor","FFFF0000");
		 	ActionSkill_ZhaoshiTarget : Disable();
		end

	 	ActionSkill_Name : SetText( strName .."\n" .. "怒气技能");

	 	strName = Player:GetSkillInfo(nNuqiId,"explain");
	 	strName2 = Player:GetSkillInfo(nNuqiId,"skilldata");
	 	ActionSkill_Explain : SetText(strName.."\n"..strName2);
	end

end

function ActionSkill_Button_Clicked()

--	if (Current_Skill ~= -1) or (Current_Nuqi ~= -1) then
	if (Current_Skill ~= -1) then
		ActionSkill_ZhaoshiTarget:DoAction();
	end

end

--function Skill_Page_Switch()
--	OpenLifePage();
--	ActionSkill_Close();
--	ActionSkill_LifeSkill : SetCheck(0);
--	ActionSkill_ActionSkill : SetCheck(1);
--end

function ActionSkill_Common_Page_Switch()
	OpenCommonSkillPage();
	ActionSkill_OnClose();
	
end

function ActionSkill_Life_Page_Switch()
	OpenLifePage();
	ActionSkill_OnClose();

end

function ActionSkill_Zhenfa_Page_Switch()
	OpenZhenfaFream();
	ActionSkill_OnClose();

end



function ActionSkill_AutoAttack_Page_Switch(nPageNumber)
	local myLevel = Player:GetData("LEVEL")
	local nMenpai = Player:GetData("MEMPAI")
	local nCanShow = 1
	if myLevel >= 50 and nMenpai ~= 9 then
		PushEvent("TRIGGER_ZIDONGZHANDOU","config")
		DataPool:Lua_SetLastSkill_UI(6)
		ActionSkill_OnClose()
	elseif myLevel < 50 then
		PushDebugMessage("#{ZDZD_200724_62}")
		nCanShow = 0
	else
		PushDebugMessage("#{ZDZD_200724_63}")
		nCanShow = 0
	end
	if nCanShow == 0 then
		if g_ActionSkill_PageButton[nPageNumber] ~= nil then
			g_ActionSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		ActionSkill_ClearPage()
	end
end

function ActionSkill_ZongMen_Page_Switch(nPageNumber)
	if DataPool:Lua_CheckOpenTalent() == 1 then
		ToggleTalentPage()
		ActionSkill_OnClose();
	else
		if g_ActionSkill_PageButton[nPageNumber] ~= nil then
			g_ActionSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		ActionSkill_ClearPage()
	end
end

function ActionSkill_SetTabColor()


	local selColor = "#e010101#Y";
	local noselColor = "#e010101";
	local tab = {
								[0] = ActionSkill_CommonlySkill,
								ActionSkill_ActionSkill,
								ActionSkill_LifeSkill,
								ActionSkill_ZhenfaSkill,
								ActionSkill_AutoAttack,
								ActionSkill_ZongMenSkill,
							};

	local TAB_TEXT = {
		[0] = "普通",
		"门派",
		"生活",
		"#{JBGXW_150526_215}",
		"#{ZDZD_200724_08}",
		"#{ZMTF_230628_20}",
	};

	tab[0]:SetText(noselColor..TAB_TEXT[0]);
	tab[1]:SetText(selColor..TAB_TEXT[1]);
	tab[2]:SetText(noselColor..TAB_TEXT[2]);
	tab[3]:SetText(noselColor..TAB_TEXT[3]);
	tab[4]:SetText(noselColor..TAB_TEXT[4]);
	tab[5]:SetText(noselColor..TAB_TEXT[5]);
end

function ActionSkill_ShowPage()

	for i = 1, table.getn(g_ActionSkill_PageButton) do
		g_ActionSkill_PageButton[i]:Hide()
	end
	local nPageNumber = tonumber(Variable:GetVariable("SkillPageNumber"));
	ActionSkill_ClearPage()
	
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_ActionSkill_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_ActionSkill_PageButton) do
			if i ~= nPageNumber then
				g_ActionSkill_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_ActionSkill_PageOrder = {}
	local g_ActionSkill_PageCount = 0
	
	for i = 1, table.getn(g_ActionSkill_PageButton) do
		if ActionSkill_CheckPage(i) == 1 then
			g_ActionSkill_PageCount = g_ActionSkill_PageCount + 1
			g_ActionSkill_PageButton[g_ActionSkill_PageCount]:Show()
			g_ActionSkill_PageButton[g_ActionSkill_PageCount]:SetText(g_ActionSkill_Page[i].Text)	
			g_ActionSkill_PageOrder[g_ActionSkill_PageCount] = i
		end
	end
	
	for idx = 1, table.getn(g_ActionSkill_PageOrder) do
		if g_ActionSkill_PageOrder[idx] == 6 and g_PageTipsPos[idx] then -- 其他
			local newpos = g_PageTipsPos[idx]
			ActionSkill_ZongMenSkill_Tips:SetProperty("UnifiedXPosition", newpos);
		end
	end
	
end

function ActionSkill_OnPageClicked(idx)

	Variable:SetVariable("SkillPageNumber", tostring(idx), 1);
	idx = g_ActionSkill_PageOrder[idx]
	local nPageNumber = tonumber(Variable:GetVariable("SkillPageNumber"));
	
	if idx == 1 then--普通
		ActionSkill_Common_Page_Switch()
	elseif idx == 2 then--门派
		ActionSkill_ClearPage()
	elseif idx == 3 then--阵法
		ActionSkill_Zhenfa_Page_Switch()
	elseif idx == 4 then--生活
		ActionSkill_Life_Page_Switch()
	elseif idx == 5 then--战斗
		ActionSkill_AutoAttack_Page_Switch(nPageNumber)
	elseif idx == 6 then --绝学
		ActionSkill_ZongMen_Page_Switch(nPageNumber)
	end
end

function ActionSkill_CheckPage(idx)
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

function ActionSkill_ClearPage()
	Variable:SetVariable("SkillPageNumber", tostring(0), 1)
end

function ActionSkill_OnClose()
	Variable:SetVariable("SkillUnionPos", ActionSkill_Frame:GetProperty("UnifiedPosition"), 1);
	ActionSkill_Close();
end

function ActionSkill_ClearStaticImage()
	ActionSkill_MenPai_ICON : SetProperty("Tooltip", "");
	ActionSkill_MenPai_ICON : SetProperty("Image","");
end

function ActionSkill_UpdateMenPaiText()
	local menpaiID = Player : GetData("MEMPAI");		--获取玩家门派ID
	if menpaiID ~= nil and menpaiID >=0 and menpaiID <=g_MenPaiCount then
		if (menpaiID == 9) then
			ActionSkill_ClearStaticImage();
			ActionSkill_MenPai_Attr_Intro : SetText(""); --一般来说这里不会被调到
			return;
		end
		local	str = GetDictionaryString( "MPZSX_20071221_0" .. (menpaiID +1) );
		ActionSkill_MenPai_Attr_Intro : SetText("#Y" .. str);
		--ActionSkill_ClearStaticImage();

		ActionSkill_MenPai_ICON : SetToolTip(GetDictionaryString(MenPai_UsedAttr[menpaiID].Tooltip));
		ActionSkill_MenPai_ICON : SetProperty("Image",MenPai_UsedAttr[menpaiID].image);
	end
end

function ActionSkill_ShowGemScore()
	local nGemScore = Player:GetData("EQUIPGEMXIULIANSCORE");
	local nGemScoreNextLevel = 0
	local nGemScoreLevel = 0
	local nGemEffect = "0"
	local nGemEffectNextLevel = "0"
	if nGemScore < 960 then
		nGemScoreLevel = 0
		nGemScoreNextLevel = 960
		nGemEffect = "0"
		nGemEffectNextLevel = "2"
	elseif nGemScore < 1280 then
		nGemScoreLevel = 1
		nGemScoreNextLevel = 1280
		nGemEffect = "2"
		nGemEffectNextLevel = "4"
	elseif nGemScore < 1920 then
		nGemScoreLevel = 2
		nGemScoreNextLevel = 1920
		nGemEffect = "4"
		nGemEffectNextLevel = "7"
	elseif nGemScore < 3200 then
		nGemScoreLevel = 3
		nGemScoreNextLevel = 3200
		nGemEffect = "7"
		nGemEffectNextLevel = "10"
	else
		nGemScoreLevel = 4
		nGemScoreNextLevel = 5120
		nGemEffect = "10"
		nGemEffectNextLevel = "10"
	end
	ActionSkill_shuzhi02:SetText("#cfff263"..tostring(nGemScore).."/"..tostring(nGemScoreNextLevel))
	ActionSkill_shuzhi01:SetText("#cfff263"..tostring(nGemScoreLevel))
	nGemEffectStr = ScriptGlobal_Format("#{BSZJPF_130311_10}",nGemEffect,nGemEffect)
	ActionSkill_EffectNotice:SetText(nGemEffectStr)
	
	ActionSkill_shuzhi02:SetToolTip("#{BSZJPF_130311_11}");
	if nGemScoreLevel < 3 then
		local strTemp = ScriptGlobal_Format("#{BSZJPF_130311_12}",tostring(nGemScoreNextLevel - nGemScore))
		ActionSkill_GemXiulianLevel:SetToolTip(strTemp)
		ActionSkill_shuzhi01:SetToolTip(strTemp)
		strTemp = ScriptGlobal_Format("#{BSZJPF_130311_14}",nGemEffectNextLevel,nGemEffectNextLevel)
		ActionSkill_EffectNotice:SetToolTip(strTemp)
	else
		ActionSkill_GemXiulianLevel:SetToolTip("#{BSZJPF_130311_13}")
		ActionSkill_shuzhi01:SetToolTip("#{BSZJPF_130311_13}")
		local strTemp = ScriptGlobal_Format("#{BSZJPF_130311_15}",nGemEffect,nGemEffect)
		ActionSkill_EffectNotice:SetToolTip(strTemp)
	end
end

function ActionSkill_Open()
	--ActionSkill_UpdateMenPaiText();
	this:Show();
end
function ActionSkill_Close()
	this:Hide();
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ActionSkill_Frame_On_ResetPos()

	ActionSkill_Frame : SetProperty("UnifiedXPosition", g_ActionSkill_Frame_UnifiedXPosition);
	ActionSkill_Frame : SetProperty("UnifiedYPosition", g_ActionSkill_Frame_UnifiedYPosition);

end

function ActionSkill_FreshManGuide(nType, nTextID, nPosID)
    if nType ~= 1 and      --1 is reset and open
        nType ~= 2 then    --2 is modify
        return
    end
	
	local fX = 0
	local fY = 0
	fX, fY = this:GetChildOffset("ActionSkill_Xinfa_BK")
	local fH = tonumber(ActionSkill_Xinfa_BK:GetProperty("AbsoluteHeight"))
	local fW = tonumber(ActionSkill_Xinfa_BK:GetProperty("AbsoluteWidth"))
	local PosX = tonumber(ActionSkill_Frame:GetProperty("AbsoluteXPosition"))
	local PosY = tonumber(ActionSkill_Frame:GetProperty("AbsoluteYPosition"))		
	
	if 1 == nPosID then	
		fX = math.floor(tonumber(fX + PosX + fW / 2  ))
        fY = math.floor(tonumber(fY + PosY + fH ))
		--fY = fY+178
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 25, 0, "ActionSkill")
	elseif 2 == nPosID then
		fX = math.floor(tonumber(fX + PosX + fW / 2 -45))
        fY = math.floor(tonumber(fY + PosY + fH +45))
		if(SystemSetup:IsClassic() == 0) then  --尼玛，唯美字体改了导致位置变了
			fY = fY+ 10
		end
		OpenFreshManGuideNew(nType, fX, fY, fW, fH, 26, 0, "ActionSkill")	
	end
	
	g_CurGuide = nPosID
end

function ActionSkill_OnMoved()
	if "ActionSkill" == GetFreshManGuideOwner() then --当本界面show并且引导ui指向本界面,才需要响应
		ActionSkill_FreshManGuide(2,-1,g_CurGuide)
	end
end

function ActionSkill_OnHidden()
    if "ActionSkill" == GetFreshManGuideOwner() then
		PushEvent("CLOSE_NEWNPCCHAT")
        CloseFreshManGuide()      --当引导ui指向本界面,才需要响应
    end
end
