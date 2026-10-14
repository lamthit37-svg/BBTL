
local g_JieBaiZF_Skill = {}
local g_JieBaiZF_SkillAction = {}
function JieBaiZF_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("SKILL_UPDATE");
end

function JieBaiZF_OnLoad()
	g_JieBaiZF_Skill[1] = 3229
	g_JieBaiZF_Skill[2] = 3230
	g_JieBaiZF_Skill[3] = 3231
	g_JieBaiZF_Skill[4] = 3232
	g_JieBaiZF_Skill[5] = 3233
	
	g_JieBaiZF_SkillAction[1] = JieBaiZF_BK1_Zhen01_Skill1
	g_JieBaiZF_SkillAction[2] = JieBaiZF_BK1_Zhen02_Skill1
	g_JieBaiZF_SkillAction[3] = JieBaiZF_BK1_Zhen03_Skill1
	g_JieBaiZF_SkillAction[4] = JieBaiZF_BK1_Zhen04_Skill1
	g_JieBaiZF_SkillAction[5] = JieBaiZF_BK1_Zhen05_Skill1
	
	
end

function JieBaiZF_OnEvent(event)

	if (event == "UI_COMMAND") then
		JieBaiZF_UpdataSkill()
		this:Show()
	elseif (event == "SKILL_UPDATE") then
		JieBaiZF_UpdataSkill()
	end
end


function JieBaiZF_QueryLevelup(index)
	tonumber(index)
	PushDebugMessage("index="..index)
		Clear_XSCRIPT();
			Set_XSCRIPT_Function_Name("QueryLevel");
			Set_XSCRIPT_ScriptID(891115);
			Set_XSCRIPT_Parameter(0,index);
			Set_XSCRIPT_ParamCount(1);
		Send_XSCRIPT();	
end

function JieBaiZF_UpdataSkill()
	local nSumSkill = GetActionNum("skill");
	for i = 1, nSumSkill do
		local thetempAction = EnumAction(i, "skill");
		local temp = thetempAction:GetID();
		local nCommonId = LifeAbility : GetLifeAbility_Number(temp);
		if nCommonId ~=nil and nCommonId > 0 then
		
			for i = 1, 5 do
				if g_JieBaiZF_Skill[i] == nCommonId then
					g_JieBaiZF_SkillAction[i] : SetActionItem(thetempAction : GetID())
				end
			end			
		end
	end
end