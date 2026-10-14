local LIFE_BUTTONS = {};
local LIFE_INDEX = {};
local LIFE_LEVEL = {};
local Current = 1;
local IsHave26Ability = 0;
local Max_SkillExp = {};
local Current_Page = 0;
local MaxValidID = 0;
local LIFE_BUTTONS_NUM = 20;
local All_SkillID ={};

-- 界面的默认相对位置
local g_LifeSkill_Frame_UnifiedXPosition;
local g_LifeSkill_Frame_UnifiedYPosition;

local g_LifeSkill_Target_Skill_Y_Pos        = { Classic = "{0.000000,6.000000}", 		vmei = "{0.000000,0.000000}",}    --- 生活技能中间图标的Y坐标
local g_LifeSkill_Target_Skill_Y_Pos_ZJ     = { Classic = "{0.000000,16.000000}", 	vmei = "{0.000000,9.000000}", }   --- 有专精时生活技能中间图标的Y坐标
local g_LifeSkill_Next1_Y_Pos               = { Classic = "{0.600000,-75.400002}",	vmei = "{0.000000,11.000000}", }   --- 制作按钮的Y坐标
local g_LifeSkill_Next1_Y_Pos_ZJ            = { Classic = "{0.600000,-65.400002}",	vmei = "{0.000000,20.000000}", }   --- 有专精时制作按钮的Y坐标
local g_LifeSkill_Target_Explain_Y_Pos      = { Classic = "{1.000000,-102.000000}",	vmei = "{1.000000,-109.000000}", }    --- 生活技能说明的Y坐标
local g_LifeSkill_Target_Explain_Y_Pos_ZJ   = { Classic = "{1.000000,-80.000000}",	vmei = "{1.000000,-89.000000}", }   --- 有专精时生活技能说明的Y坐标
local g_LifeSkill_Target_Explain_Height     = { Classic = 102, vmei = 105 }                   --- 技能说明的高度
local g_LifeSkill_Target_Explain_Height_ZJ  = { Classic = 80, vmei = 85 }                        --- 有专精时技能说明的高度

--统一化下页签显示隐藏 目前固定顺序 新增改序号 每个页签都需要添加
local g_LifeSkill_Page = {
	[1] = {Text = "#e010101".."#{INTERFACE_XML_494}",	NeedCheck = 0, Tip = ""},
	[2] = {Text = "#e010101".."#{INTERFACE_XML_448}",	NeedCheck = 0, Tip = ""},
	[3] = {Text = "#e010101".."#{JBGXW_150526_215}",	NeedCheck = 0, Tip = ""},
	[4] = {Text = "#e010101#Y".."#{INTERFACE_XML_635}",	NeedCheck = 0, Tip = ""},
	[5] = {Text = "#e010101".."#{ZDZD_200724_08}",		NeedCheck = 0, Tip = ""},
	[6] = {Text = "#e010101".."#{ZMTF_230628_20}",		NeedCheck = 0, Tip = ""},
}
local g_LifeSkill_PageButton = {}
local g_LifeSkill_PageOrder = {}
local g_PageTipsPos = {}

function LifeSkill_PreLoad()
	this:RegisterEvent("TOGLE_LIFE_PAGE",true);
	this:RegisterEvent("TOGLE_SKILL_BOOK",false);
	this:RegisterEvent("TOGLE_COMMONSKILL_PAGE",false);
	this:RegisterEvent("UPDATE_LIFESKILL_PAGE",false);
	this:RegisterEvent("CLOSE_SKILL_BOOK",false);
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND", true)

end

function LifeSkill_OnLoad()
	LIFE_BUTTONS[1] = LifeSkill_Skill1;
	LIFE_BUTTONS[2] = LifeSkill_Skill2;
	LIFE_BUTTONS[3] = LifeSkill_Skill3;
	LIFE_BUTTONS[4] = LifeSkill_Skill4;
	LIFE_BUTTONS[5] = LifeSkill_Skill5;
	LIFE_BUTTONS[6] = LifeSkill_Skill6;
	LIFE_BUTTONS[7] = LifeSkill_Skill7;
	LIFE_BUTTONS[8] = LifeSkill_Skill8;
	LIFE_BUTTONS[9] = LifeSkill_Skill9;
	LIFE_BUTTONS[10] = LifeSkill_Skill10;
	LIFE_BUTTONS[11] = LifeSkill_Skill11;
	LIFE_BUTTONS[12] = LifeSkill_Skill12;
	LIFE_BUTTONS[13] = LifeSkill_Skill13;
	LIFE_BUTTONS[14] = LifeSkill_Skill14;
	LIFE_BUTTONS[15] = LifeSkill_Skill15;
	LIFE_BUTTONS[16] = LifeSkill_Skill16;
	LIFE_BUTTONS[17] = LifeSkill_Skill17;
	LIFE_BUTTONS[18] = LifeSkill_Skill18;
	LIFE_BUTTONS[19] = LifeSkill_Skill19;
	LIFE_BUTTONS[20] = LifeSkill_Skill20;
	
--	LIFE_LEVEL[1] = LifeSkill_Skill1_Text;
--	LIFE_LEVEL[2] = LifeSkill_Skill2_Text;
--	LIFE_LEVEL[3] = LifeSkill_Skill3_Text;
--	LIFE_LEVEL[4] = LifeSkill_Skill4_Text;
--	LIFE_LEVEL[5] = LifeSkill_Skill5_Text;
--	LIFE_LEVEL[6] = LifeSkill_Skill6_Text;
--	LIFE_LEVEL[7] = LifeSkill_Skill7_Text;
--	LIFE_LEVEL[8] = LifeSkill_Skill8_Text;
--	LIFE_LEVEL[9] = LifeSkill_Skill9_Text;
--	LIFE_LEVEL[10] = LifeSkill_Skill10_Text;
--	LIFE_LEVEL[11] = LifeSkill_Skill11_Text;
--	LIFE_LEVEL[12] = LifeSkill_Skill12_Text;
--	LIFE_LEVEL[13] = LifeSkill_Skill13_Text;
--	LIFE_LEVEL[14] = LifeSkill_Skill14_Text;
--	LIFE_LEVEL[15] = LifeSkill_Skill15_Text;
--	LIFE_LEVEL[16] = LifeSkill_Skill16_Text;
--	LIFE_LEVEL[17] = LifeSkill_Skill17_Text;
--	LIFE_LEVEL[18] = LifeSkill_Skill18_Text;
--	LIFE_LEVEL[19] = LifeSkill_Skill19_Text;
--	LIFE_LEVEL[20] = LifeSkill_Skill20_Text;
	
	
	Max_SkillExp[1] = 10
	Max_SkillExp[2] = 30
	Max_SkillExp[3] = 60
	Max_SkillExp[4] = 100
	Max_SkillExp[5] = 150
	Max_SkillExp[6] = 210
	Max_SkillExp[7] = 280
	Max_SkillExp[8] = 360
	Max_SkillExp[9] = 450
	Max_SkillExp[10] = 5500
	Max_SkillExp[11] = 5500
	Max_SkillExp[12] = 5500
	for i=1,20 do
		LIFE_INDEX[i] = -1;
--		LIFE_LEVEL[i] :SetText("");
	end;
	
	--LifeSkill_SetTabColor();

	-- 保存界面的默认相对位置
	g_LifeSkill_Frame_UnifiedXPosition	= LifeSkill_Frame : GetProperty("UnifiedXPosition");
	g_LifeSkill_Frame_UnifiedYPosition	= LifeSkill_Frame : GetProperty("UnifiedYPosition");

	g_LifeSkill_PageButton[1] = LifeSkill_CommonlySkill
	g_LifeSkill_PageButton[2] = LifeSkill_ActionSkill
	g_LifeSkill_PageButton[3] = LifeSkill_ZhenfaSkill
	g_LifeSkill_PageButton[4] = LifeSkill_LifeSkill
	g_LifeSkill_PageButton[5] = LifeSkill_AutoAttack
	g_LifeSkill_PageButton[6] = LifeSkill_ZongMenSkill
	
	g_PageTipsPos[1] = "{0.000000,28.000000}" 
	g_PageTipsPos[2] = "{0.000000,64.000000}" 
	g_PageTipsPos[3] = "{0.000000,100.000000}"
	g_PageTipsPos[4] = "{0.000000,136.000000}"
	g_PageTipsPos[5] = "{0.000000,172.000000}"
	g_PageTipsPos[6] = "{0.000000,208.000000}"
	
end

function LifeSkill_OnEvent(event)
	if ( event == "TOGLE_LIFE_PAGE" ) then
		local selfUnionPos = Variable:GetVariable("SkillUnionPos");
		if(selfUnionPos ~= nil) then
			LifeSkill_Frame:SetProperty("UnifiedPosition", selfUnionPos);
		end
		Life_Skill_Open();
		LifeSkill_Update();
		LifeSkill_ShowPage()
		return;
	elseif ( event == "UPDATE_LIFESKILL_PAGE" and this:IsVisible() ) then
		LifeSkill_Update();
	elseif ( event == "TOGLE_SKILL_BOOK" ) then
		Life_Skill_Close();
	elseif ( event == "TOGLE_COMMONSKILL_PAGE" ) then
		Life_Skill_Close();
	elseif ( event == "CLOSE_SKILL_BOOK" ) then
		Life_Skill_Close();

	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		-- 更新背包界面位置
		LifeSkill_Frame_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		-- 更新背包界面位置	
		LifeSkill_Frame_On_ResetPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 998633007) then	--服务端传数据
	
		local bIsShowHotPoint = Get_XParam_INT(0)	
		if bIsShowHotPoint == 1 then
			LifeSkill_ZongMenSkill_Tips:Show()	
		else
			LifeSkill_ZongMenSkill_Tips:Hide()		
		end

	end

end

function LifeSkill_OnShown()
	LifeSkill_Update();
end

function LifeSkill_Update()
	LifeSkill_Next1 : Hide();
--	LifeSkill_Next2 : Hide();
--	LifeSkill_Next3 : Hide();
	LifeSkill_Target_Skill_Name : SetText("");
	--added by guochenshu 2010-08-18
	LifeSkill_Target_Skill_Level : SetText("");
	LifeSkill_Target_Skill_Explain : SetText("");
	LifeSkill_Target_Skill_Sleight:SetText( "" );
	LifeSkill_Target_Skill:SetActionItem(-1);
	LifeSkill_ActionSkill : SetCheck(0);
	LifeSkill_CommonlySkill : SetCheck(0);
	LifeSkill_LifeSkill : SetCheck(1);
    LifeSkill_Target_Skill_Sleight1:SetText("")

	local nLifeAbilityCount = GetActionNum("life");
	local maxValidID = 1;
	for index = 0, nLifeAbilityCount do
		local theAction = EnumAction(index, "life");
		if theAction:GetID() ~= 0 then
			if theAction:GetDefineID() ~= 26 and theAction:GetDefineID() ~= 38 and theAction:GetDefineID() ~= 50 
			   and theAction:GetDefineID() ~= 51 and theAction:GetDefineID() ~= 54 and theAction:GetDefineID() ~= 55 and theAction:GetDefineID() ~= 62 then
				All_SkillID[ maxValidID ] = theAction:GetID();
				maxValidID = maxValidID + 1;
			end
		end
	end
	--得到当前最多可显示的id数量
	MaxValidID = maxValidID - 1;
	
	--如果当前为第一页，上翻按钮灰掉	
	if Current_Page == 0 then
		LifeSkill_UPdata1 : Disable();
	else
		LifeSkill_UPdata1 : Enable();
	end
		
	local curMaxNumber = 0;
	if( ( Current_Page + 1 ) * LIFE_BUTTONS_NUM <= MaxValidID ) then
		curMaxNumber = ( Current_Page + 1 ) * LIFE_BUTTONS_NUM;
		LifeSkill_UPdata2 : Enable();
	else
		curMaxNumber = MaxValidID;
		LifeSkill_UPdata2 : Disable();
	end
	
	for i=1, LIFE_BUTTONS_NUM do
		LIFE_BUTTONS[i]:SetActionItem(-1);
		LIFE_INDEX[i] = -1;
	end
	
	local Begin_Index = Current_Page * LIFE_BUTTONS_NUM + 1;

	i = 1;
	for idx=Begin_Index,curMaxNumber do

		LIFE_BUTTONS[i]:SetActionItem( All_SkillID[idx] );
		LIFE_INDEX[i] = All_SkillID[idx];
		i = i + 1;
	end
	
	if(LIFE_INDEX[Current] ~= -1) then
		LifeSkill_Buttons_Clicked(Current);
	end

end


function LifeSkill_Buttons_Clicked(nIndex)

	if( LIFE_INDEX[nIndex] == -1) then
		return;
	end;

	LIFE_BUTTONS[Current]:SetPushed(0);
	local lifeid =	LifeAbility : GetLifeAbility_Number(LIFE_INDEX[nIndex]);

--	if( Current == nIndex) then
--		return;
--	end;

	Current = nIndex;
	LIFE_BUTTONS[Current]:SetPushed(1);
	local popup = Player:GetAbilityInfo(lifeid,"popup");
	if(tonumber(popup) == 2) then
		LifeSkill_Next1 : Show();
		LifeSkill_Next1 : SetText("镶嵌")
--		LifeSkill_Next2 : Show();
--		LifeSkill_Next3 : Hide();
	elseif ( popup == 1 ) then
		LifeSkill_Next1 : Show();
		LifeSkill_Next1 : SetText("制作")
--		LifeSkill_Next2 : Hide();
--		LifeSkill_Next3 : Hide();
	else
		LifeSkill_Next1 : Hide();
--		LifeSkill_Next2 : Hide();
--		LifeSkill_Next3 : Hide();
	end
	
	local strName = Player:GetAbilityInfo(lifeid,"name");
 	local strName2= Player:GetAbilityInfo(lifeid,"level");
 	local level = tonumber(strName2);
	LifeSkill_Target_Skill_Name : SetText( strName );
	LifeSkill_Target_Skill_Level : SetText("等级:" .. strName2);
	
	strName = Player:GetAbilityInfo(lifeid,"explain");
	LifeSkill_Target_Skill_Explain : SetText( strName );
	
	local max_exp;
	if level > 12 or level < 1 then
		max_exp = "∞"
	else
--		max_exp = Max_SkillExp[level]
		max_exp = LifeAbility : GetLifeAbility_LimitExp(lifeid,level);
	end
	
	strName = Player:GetAbilityInfo(lifeid,"skillexp");
	LifeSkill_Target_Skill_Sleight:SetText( "熟练度:"..strName.."/"..max_exp);

	LifeSkill_Target_Skill:SetActionItem( LIFE_INDEX[nIndex] );
--杨耀的设计，刘铁说不要，所以注释以下代码
--	LifeAbility : Update_Synthesize(lifeid);
--------------------------------------------

    --- 显示生活专精值
    LifeSkill_Display_Zhuanjing( lifeid )
end

function LifeSkill_Display_Zhuanjing( lifeID )
    local zhuanjingValue = Player:GetAbilityInfo( lifeID,"zhuanjing")
    --- 如果不是烹饪和制药技能
    if lifeID ~= 1 and lifeID ~= 2 then
        LifeSkill_Target_Skill_Sleight1:SetText("")
        LifeSkill_Target_Skill_Sleight1:SetToolTip("")
        LifeSkill_Target_Skill_Sleight1:Hide()
        --- 设置其他控件的位置  
        if 1 == SystemSetup:IsClassic() then
        	LifeSkill_Target_Skill0:SetProperty("UnifiedYPosition",             g_LifeSkill_Target_Skill_Y_Pos.Classic )
        	LifeSkill_Next0:SetProperty("UnifiedYPosition",                     g_LifeSkill_Next1_Y_Pos.Classic )
        	LifeSkill_Target_Skill_Explain_Bk0:SetProperty("UnifiedYPosition",  g_LifeSkill_Target_Explain_Y_Pos.Classic )
        	LifeSkill_Target_Skill_Explain_Bk0:SetProperty("AbsoluteHeight",    tostring(g_LifeSkill_Target_Explain_Height.Classic) )
        else
        	LifeSkill_Target_Skill0:SetProperty("UnifiedYPosition",             g_LifeSkill_Target_Skill_Y_Pos.vmei )
        	LifeSkill_Next0:SetProperty("UnifiedYPosition",                     g_LifeSkill_Next1_Y_Pos.vmei )
        	LifeSkill_Target_Skill_Explain_Bk0:SetProperty("UnifiedYPosition",  g_LifeSkill_Target_Explain_Y_Pos.vmei )
        	LifeSkill_Target_Skill_Explain_Bk0:SetProperty("AbsoluteHeight",    tostring(g_LifeSkill_Target_Explain_Height.vmei) )
        end
    else
        --- 没有专精值
        if zhuanjingValue == nil or zhuanjingValue <= 0 or zhuanjingValue > 1000 then
            LifeSkill_Sleight1_SetToolTip( lifeID, 0 )
            LifeSkill_Target_Skill_Sleight1:SetText( "#{SHJNZJ_110907_70}".."#{SHJNZJ_110907_81}" )
        --- 有生活专精值
        else
            LifeSkill_Sleight1_SetToolTip( lifeID, 1 )
            LifeSkill_Target_Skill_Sleight1:SetText("#{SHJNZJ_110907_70}"..zhuanjingValue.."/1000")
        end

        LifeSkill_Target_Skill_Sleight1:Show()
        --- 设置其他控件的位置
        if 1 == SystemSetup:IsClassic() then
        	LifeSkill_Target_Skill0:SetProperty("UnifiedYPosition",             g_LifeSkill_Target_Skill_Y_Pos_ZJ.Classic )
        	LifeSkill_Next0:SetProperty("UnifiedYPosition",                     g_LifeSkill_Next1_Y_Pos_ZJ.Classic )
        	LifeSkill_Target_Skill_Explain_Bk0:SetProperty("UnifiedYPosition",  g_LifeSkill_Target_Explain_Y_Pos_ZJ.Classic )
        	LifeSkill_Target_Skill_Explain_Bk0:SetProperty("AbsoluteHeight",    tostring(g_LifeSkill_Target_Explain_Height_ZJ.Classic) )
        else
          LifeSkill_Target_Skill0:SetProperty("UnifiedYPosition",             g_LifeSkill_Target_Skill_Y_Pos_ZJ.vmei )
        	LifeSkill_Next0:SetProperty("UnifiedYPosition",                     g_LifeSkill_Next1_Y_Pos_ZJ.vmei )
        	LifeSkill_Target_Skill_Explain_Bk0:SetProperty("UnifiedYPosition",  g_LifeSkill_Target_Explain_Y_Pos_ZJ.vmei )
        	LifeSkill_Target_Skill_Explain_Bk0:SetProperty("AbsoluteHeight",    tostring(g_LifeSkill_Target_Explain_Height_ZJ.vmei) )
        end

    end
end

function LifeSkill_Sleight1_SetToolTip( LifeID, type )
    local toolTip = ""
    --- 烹饪
    if LifeID == 1 then
        if type == 0 then
            toolTip = "#{SHJNZJ_110907_80}"
        else
            toolTip = "#{SHJNZJ_110907_59}"
        end
    --- 制药
    elseif LifeID == 2 then
        if type == 0 then
            toolTip = "#{SHJNZJ_110907_79}"
        else
            toolTip = "#{SHJNZJ_110907_30}"
        end
    end

    LifeSkill_Target_Skill_Sleight1:SetToolTip( toolTip )
end

function LifeSkill_Synthesize_Clicked()
	
	if Current ~= -1  then
		LifeSkill_Target_Skill:DoAction();
	end
		
end

--function Life_Page_Switch()
--	OpenSkillBook();
--	Life_Skill_Close();
--	LifeSkill_ActionSkill : SetCheck(0);
--	LifeSkill_LifeSkill : SetCheck(1);
--end

function LifeSkill_Compose_Gem_Clicked(arg)
	LifeAbility : Open_Compose_Gem_Page(arg);
end

function LifeSkill_Action_Page_Switch(nPageNumber)
	local menpai = Player:GetData("MEMPAI");
	if(menpai == 9) then 
		if g_LifeSkill_PageButton[nPageNumber] ~= nil then
			g_LifeSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		LifeSkill_ClearPage()
		PushDebugMessage("你还没有拜入门派。");
		return; 
	end;
	OpenSkillBook();
	Life_Skill_Close();

end

function LifeSkill_Zhenfa_Page_Switch()
	OpenZhenfaFream();
	Life_Skill_Close();

end

function LifeSkill_Common_Page_Switch()
	OpenCommonSkillPage();
	Life_Skill_Close();

end

function LifeSkill_AutoAttack_Page_Switch(nPageNumber)
	local myLevel = Player:GetData("LEVEL")
	local nMenpai = Player:GetData("MEMPAI")
	local nCanShow = 1
	if myLevel >= 50 and nMenpai ~= 9 then
		PushEvent("TRIGGER_ZIDONGZHANDOU","config")
		DataPool:Lua_SetLastSkill_UI(6)
		Life_Skill_Close()
	elseif myLevel < 50 then
		PushDebugMessage("#{ZDZD_200724_62}")
		nCanShow = 0
	else
		PushDebugMessage("#{ZDZD_200724_63}")
		nCanShow = 0
	end
	if nCanShow == 0 then
		if g_LifeSkill_PageButton[nPageNumber] ~= nil then
			g_LifeSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		LifeSkill_ClearPage()
	end
end

function LifeSkill_ZongMen_Page_Switch(nPageNumber)
	if DataPool:Lua_CheckOpenTalent() == 1 then
		ToggleTalentPage()
		Life_Skill_Close();
	else
		if g_LifeSkill_PageButton[nPageNumber] ~= nil then
			g_LifeSkill_PageButton[nPageNumber]:SetCheck(0)
		end
		LifeSkill_ClearPage()
	end
end

function Life_Skill_Close()
	Variable:SetVariable("SkillUnionPos", LifeSkill_Frame:GetProperty("UnifiedPosition"), 1);
	this:Hide();
end

function LifeSkill_SetTabColor()
	

	local selColor = "#e010101#Y";
	local noselColor = "#e010101";
	local tab = {
								[0] = LifeSkill_CommonlySkill,
								LifeSkill_ActionSkill,
								LifeSkill_LifeSkill,
								LifeSkill_ZhenfaSkill,
								LifeSkill_AutoAttack,
								LifeSkill_ZongMenSkill,
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
	tab[1]:SetText(noselColor..TAB_TEXT[1]);
	tab[2]:SetText(selColor..TAB_TEXT[2]);
	tab[3]:SetText(noselColor..TAB_TEXT[3]);
	tab[4]:SetText(noselColor..TAB_TEXT[4]);
	tab[5]:SetText(noselColor..TAB_TEXT[5]);
end

function LifeSkill_ShowPage()

	for i = 1, table.getn(g_LifeSkill_PageButton) do
		g_LifeSkill_PageButton[i]:Hide()
	end
	local nPageNumber = tonumber(Variable:GetVariable("SkillPageNumber"));
	LifeSkill_ClearPage()
	
	if nPageNumber ~= nil and nPageNumber ~= 0 then
		g_LifeSkill_PageButton[nPageNumber]:SetCheck(1)
		for i = 1, table.getn(g_LifeSkill_PageButton) do
			if i ~= nPageNumber then
				g_LifeSkill_PageButton[i]:SetCheck(0)
			end
		end
	end
	
	g_LifeSkill_PageOrder = {}
	local g_LifeSkill_PageCount = 0
	
	for i = 1, table.getn(g_LifeSkill_PageButton) do
		if LifeSkill_CheckPage(i) == 1 then
			g_LifeSkill_PageCount = g_LifeSkill_PageCount + 1
			g_LifeSkill_PageButton[g_LifeSkill_PageCount]:Show()
			g_LifeSkill_PageButton[g_LifeSkill_PageCount]:SetText(g_LifeSkill_Page[i].Text)	
			g_LifeSkill_PageOrder[g_LifeSkill_PageCount] = i
		end
	end
	
	for idx = 1, table.getn(g_LifeSkill_PageOrder) do
		if g_LifeSkill_PageOrder[idx] == 6 and g_PageTipsPos[idx] then -- 其他
			local newpos = g_PageTipsPos[idx]
			LifeSkill_ZongMenSkill_Tips:SetProperty("UnifiedXPosition", newpos);
		end
	end
		
end

function LifeSkill_OnPageClicked(idx)

	Variable:SetVariable("SkillPageNumber", tostring(idx), 1);
	idx = g_LifeSkill_PageOrder[idx]
	local nPageNumber = tonumber(Variable:GetVariable("SkillPageNumber"));
	
	if idx == 1 then--普通
		LifeSkill_Common_Page_Switch()
	elseif idx == 2 then--门派
		LifeSkill_Action_Page_Switch(nPageNumber)
	elseif idx == 3 then--阵法
		LifeSkill_Zhenfa_Page_Switch()
	elseif idx == 4 then--生活
		LifeSkill_ClearPage()
	elseif idx == 5 then--战斗
		LifeSkill_AutoAttack_Page_Switch(nPageNumber)
	elseif idx == 6 then --绝学
		LifeSkill_ZongMen_Page_Switch(nPageNumber)
	end
end

function LifeSkill_CheckPage(idx)
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

function LifeSkill_ClearPage()
	Variable:SetVariable("SkillPageNumber", tostring(0), 1)
end


function Life_Skill_Open()
	this:Show();
end

function LifeSkill_Page(nPage)
	
	Current_Page = Current_Page + nPage;

	LifeSkill_Update();

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function LifeSkill_Frame_On_ResetPos()

	LifeSkill_Frame : SetProperty("UnifiedXPosition", g_LifeSkill_Frame_UnifiedXPosition);
	LifeSkill_Frame : SetProperty("UnifiedYPosition", g_LifeSkill_Frame_UnifiedYPosition);

end
