-- !!!reloadscript =MonthPVP_Skill
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

local g_MonthPVP_Skill_SkillItem = {};
local g_MonthPVP_Skill_Text1 = {};
local g_MonthPVP_Skill_Text2 = {};
local g_MonthPVP_Skill_Text3 = {};

local g_MonthPVP_Skill_StrTeamName =
{
	[1] = {str = "#{LLKC_240517_125}"},
	[2] = {str = "#{LLKC_240517_126}"},
	[3] = {str = "#{LLKC_240517_127}"},
}

--图片
local g_MonthPVP_Skill_SkillPIC1 = 
{
	[2] = {image = "set:Buff23 image:Buff23_1"},
	[3] = {image = "set:Buff23 image:Buff23_2"},
	[4] = {image = "set:Buff23 image:Buff23_3"},
	[5] = {image = "set:Buff23 image:Buff23_4"},
}
local g_MonthPVP_Skill_SkillPIC2 = 
{
	[2] = {image = "set:Buff23 image:Buff23_6"},
	[3] = {image = "set:Buff23 image:Buff23_7"},
	[4] = {image = "set:Buff23 image:Buff23_8"},
	[5] = {image = "set:Buff23 image:Buff23_9"},
}
local g_MonthPVP_Skill_SkillPIC3 = 
{
	[2] = {image = "set:Buff23 image:Buff23_11"},
	[3] = {image = "set:Buff23 image:Buff23_12"},
	[4] = {image = "set:Buff23 image:Buff23_13"},
	[5] = {image = "set:Buff23 image:Buff23_14"},
}
local g_MonthPVP_Skill_SkillPIC = 
{
	[1] = g_MonthPVP_Skill_SkillPIC1,
	[2] = g_MonthPVP_Skill_SkillPIC2,
	[3] = g_MonthPVP_Skill_SkillPIC3,
}

--字典
local g_MonthPVP_Skill_StrSkill1 =
{
	[2] = {name = "#{LLKC_240517_220}", str = "#{LLKC_240517_221}"},
	[3] = {name = "#{LLKC_240517_222}", str = "#{LLKC_240517_223}"},
	[4] = {name = "#{LLKC_240517_224}", str = "#{LLKC_240517_225}"},
	[5] = {name = "#{LLKC_240517_226}", str = "#{LLKC_240517_227}"},
}
local g_MonthPVP_Skill_StrSkill2 =
{
	[2] = {name = "#{LLKC_240517_228}", str = "#{LLKC_240517_229}"},
	[3] = {name = "#{LLKC_240517_230}", str = "#{LLKC_240517_231}"},
	[4] = {name = "#{LLKC_240517_232}", str = "#{LLKC_240517_233}"},
	[5] = {name = "#{LLKC_240517_234}", str = "#{LLKC_240517_235}"},
}
local g_MonthPVP_Skill_StrSkill3 =
{
	[2] = {name = "#{LLKC_240517_236}", str = "#{LLKC_240517_237}"},
	[3] = {name = "#{LLKC_240517_238}", str = "#{LLKC_240517_238}"},
	[4] = {name = "#{LLKC_240517_240}", str = "#{LLKC_240517_241}"},
	[5] = {name = "#{LLKC_240517_242}", str = "#{LLKC_240517_243}"},
}
local g_MonthPVP_Skill_StrSkill = 
{
	[1] = g_MonthPVP_Skill_StrSkill1,
	[2] = g_MonthPVP_Skill_StrSkill2,
	[3] = g_MonthPVP_Skill_StrSkill3,
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function MonthPVP_Skill_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function MonthPVP_Skill_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= MonthPVP_Skill_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= MonthPVP_Skill_Frame:GetProperty("UnifiedYPosition");

	-- 阵营技能图片
	g_MonthPVP_Skill_SkillItem[2] = MonthPVP_Skill_Level2_Item;
	g_MonthPVP_Skill_SkillItem[3] = MonthPVP_Skill_Level3_Item;
	g_MonthPVP_Skill_SkillItem[4] = MonthPVP_Skill_Level4_Item;
	g_MonthPVP_Skill_SkillItem[5] = MonthPVP_Skill_Level5_Item;

	--Level
	g_MonthPVP_Skill_Text1[2] = MonthPVP_Skill_Level2_Text1;
	g_MonthPVP_Skill_Text1[3] = MonthPVP_Skill_Level3_Text1;
	g_MonthPVP_Skill_Text1[4] = MonthPVP_Skill_Level4_Text1;
	g_MonthPVP_Skill_Text1[5] = MonthPVP_Skill_Level5_Text1;

	--Name
	g_MonthPVP_Skill_Text2[2] = MonthPVP_Skill_Level2_Text2;
	g_MonthPVP_Skill_Text2[3] = MonthPVP_Skill_Level3_Text2;
	g_MonthPVP_Skill_Text2[4] = MonthPVP_Skill_Level4_Text2;
	g_MonthPVP_Skill_Text2[5] = MonthPVP_Skill_Level5_Text2;

	--Skill
	g_MonthPVP_Skill_Text3[2] = MonthPVP_Skill_Level2_Text3;
	g_MonthPVP_Skill_Text3[3] = MonthPVP_Skill_Level3_Text3;
	g_MonthPVP_Skill_Text3[4] = MonthPVP_Skill_Level4_Text3;
	g_MonthPVP_Skill_Text3[5] = MonthPVP_Skill_Level5_Text3;

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function MonthPVP_Skill_ResetPos()
	MonthPVP_Skill_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	MonthPVP_Skill_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function MonthPVP_Skill_OnEvent(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 82003004) then

		local nTeam = Get_XParam_INT(0)
		local nLevel = Get_XParam_INT(1)

		MonthPVP_Skill_Show()
		if nTeam >=1 and nTeam <=3 then
			MonthPVP_Skill_Update(nTeam,nLevel)
		end
	elseif event=="HIDE_ON_SCENE_TRANSED" or event=="SCENE_TRANSED" or event=="PLAYER_LEAVE_WORLD" then
		MonthPVP_Skill_Hide()
	end

	if this:IsVisible() then
        if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
			MonthPVP_Skill_ResetPos()
        end
	end
end

--显示UI
function MonthPVP_Skill_Show()
	MonthPVP_Skill_ClearData()
	this:Show()
end

--隐藏UI
function MonthPVP_Skill_Hide()
	MonthPVP_Skill_ClearData()
	this:Hide()
end

--清除数据
function MonthPVP_Skill_ClearData()

end

--更新
function MonthPVP_Skill_Update(nTeam,nLevel)

	for i=2,5 do
		g_MonthPVP_Skill_SkillItem[i]:SetProperty("Image",g_MonthPVP_Skill_SkillPIC[nTeam][i].image)
		g_MonthPVP_Skill_Text1[i]:SetText(ScriptGlobal_Format("#{LLKC_240517_132}",i))
		g_MonthPVP_Skill_Text2[i]:SetText(g_MonthPVP_Skill_StrSkill[nTeam][i].name)
		g_MonthPVP_Skill_Text3[i]:SetText(g_MonthPVP_Skill_StrSkill[nTeam][i].str)
	end
end

function MonthPVP_Skill_Close()
	MonthPVP_Skill_Hide()
end