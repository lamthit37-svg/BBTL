-- !!!reloadscript =MonthPVP_Score
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

-- 界面控件
local g_MonthPVP_Score_TeamPic   = {};
local g_MonthPVP_Score_TeamName  = {};
local g_MonthPVP_Score_TeamScore = {};
local g_MonthPVP_Score_SkillItem = {};
local g_MonthPVP_Score_SkillLock = {};

--阵营图片
local g_MonthPVP_Score_BelongPIC = 
{
	[1] = {image = "set:DaHua_PVP image:DaHua_PVP_BaiBK"}, --白晶晶
	[2] = {image = "set:DaHua_PVP image:DaHua_PVP_ZiBK"},	 --紫霞
	[3] = {image = "set:DaHua_PVP image:DaHua_PVP_NiuBK"}, --牛夫人
}

local g_MonthPVP_Score_StrTeamName =
{
	[1] = {str = "#{LLKC_240517_125}"},
	[2] = {str = "#{LLKC_240517_126}"},
	[3] = {str = "#{LLKC_240517_127}"},
}

local g_MonthPVP_Score_StrCAR =
{
	[1] = {str = "#{LLKC_240517_121}"}, --速速争夺 4
	[2] = {str = "#{LLKC_240517_203}"}, --即将激活 5 6
	[3] = {str = "#{LLKC_240517_248}"}, --带阵营 运输阶段 7
	[4] = {str = "#{LLKC_240517_204}"}, --请等待FARM阶段 8 9
}

--图片
local g_MonthPVP_Score_SkillPIC1 = 
{
	[2] = {image = "set:HuodongSkill_2 image:HuodongSkill_2_12"},
	[3] = {image = "set:HuodongSkill_2 image:HuodongSkill_2_11"},
	[4] = {image = "set:HuodongSkill_2 image:HuodongSkill_2_10"},
	[5] = {image = "set:HuodongSkill_2 image:HuodongSkill_2_9"},
}
local g_MonthPVP_Score_SkillPIC2 = 
{
	[2] = {image = "set:HuodongSkill_2 image:HuodongSkill_2_12"},
	[3] = {image = "set:HuodongSkill_2 image:HuodongSkill_2_13"},
	[4] = {image = "set:HuodongSkill_2 image:HuodongSkill_2_10"},
	[5] = {image = "set:HuodongSkill_2 image:HuodongSkill_2_6"},
}
local g_MonthPVP_Score_SkillPIC3 = 
{
	[2] = {image = "set:HuodongSkill_2 image:HuodongSkill_2_12"},
	[3] = {image = "set:HuodongSkill_2 image:HuodongSkill_2_7"},
	[4] = {image = "set:HuodongSkill_2 image:HuodongSkill_2_10"},
	[5] = {image = "set:HuodongSkill_2 image:HuodongSkill_2_8"},
}
local g_MonthPVP_Score_SkillPIC = 
{
	[1] = g_MonthPVP_Score_SkillPIC1,
	[2] = g_MonthPVP_Score_SkillPIC2,
	[3] = g_MonthPVP_Score_SkillPIC3,
}

--字典
local g_MonthPVP_Score_StrSkill1 =
{
	[2] = {name = "#{LLKC_240517_220}", str = "#{LLKC_240517_221}"},
	[3] = {name = "#{LLKC_240517_222}", str = "#{LLKC_240517_223}"},
	[4] = {name = "#{LLKC_240517_224}", str = "#{LLKC_240517_225}"},
	[5] = {name = "#{LLKC_240517_226}", str = "#{LLKC_240517_227}"},
}
local g_MonthPVP_Score_StrSkill2 =
{
	[2] = {name = "#{LLKC_240517_228}", str = "#{LLKC_240517_229}"},
	[3] = {name = "#{LLKC_240517_230}", str = "#{LLKC_240517_231}"},
	[4] = {name = "#{LLKC_240517_232}", str = "#{LLKC_240517_233}"},
	[5] = {name = "#{LLKC_240517_234}", str = "#{LLKC_240517_235}"},
}
local g_MonthPVP_Score_StrSkill3 =
{
	[2] = {name = "#{LLKC_240517_236}", str = "#{LLKC_240517_237}"},
	[3] = {name = "#{LLKC_240517_238}", str = "#{LLKC_240517_239}"},
	[4] = {name = "#{LLKC_240517_240}", str = "#{LLKC_240517_241}"},
	[5] = {name = "#{LLKC_240517_242}", str = "#{LLKC_240517_243}"},
}
local g_MonthPVP_Score_StrSkill = 
{
	[1] = g_MonthPVP_Score_StrSkill1,
	[2] = g_MonthPVP_Score_StrSkill2,
	[3] = g_MonthPVP_Score_StrSkill3,
}

local g_MonthPVP_Score_NeedExp = 
{
	[1] = 150,
	[2] = 300,
	[3] = 400,
	[4] = 700,
	[5] = 700,
}

local g_MonthPVP_Score_MaxGame = 3

local g_MonthPVP_Score_StepWaitFight	 = 4	--副本阶段4  等待抢夺车辆
local g_MonthPVP_Score_StepWaitGo	 	 = 5	--副本阶段5  抢夺成功,创建对应阵营车辆
local g_MonthPVP_Score_StepGoTo		 = 6	--副本阶段6  等待对应阵营车辆出发
local g_MonthPVP_Score_StepWaitKill 	 = 7	--副本阶段7  等待车辆到达目的地或被击杀
local g_MonthPVP_Score_StepReWait	 	 = 8	--副本阶段8  重新创建车辆 等待
local g_MonthPVP_Score_StepReCteate	 = 9	--副本阶段9  重新创建车辆 计时

--预加载函数，可以而且只能在这里注册脚本关心的事件
function MonthPVP_Score_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("SCENE_TRANSED");
	this:RegisterEvent("PLAYER_LEAVE_WORLD");

	this:RegisterEvent("OPEN_WINDOW");
	this:RegisterEvent("CLOSE_WINDOW");
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function MonthPVP_Score_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= MonthPVP_Score_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= MonthPVP_Score_Frame:GetProperty("UnifiedYPosition");

	-- 阵营图片
	g_MonthPVP_Score_TeamPic[1] = MonthPVP_Score_Camp1_My;
	g_MonthPVP_Score_TeamPic[2] = MonthPVP_Score_Camp2_My;
	g_MonthPVP_Score_TeamPic[3] = MonthPVP_Score_Camp3_My;

	-- 阵营名
	g_MonthPVP_Score_TeamName[1] = MonthPVP_Score_Camp1_Text1;
	g_MonthPVP_Score_TeamName[2] = MonthPVP_Score_Camp2_Text1;
	g_MonthPVP_Score_TeamName[3] = MonthPVP_Score_Camp3_Text1;

	-- 阵营 分数
	g_MonthPVP_Score_TeamScore[1] = MonthPVP_Score_Camp1_Text2;
	g_MonthPVP_Score_TeamScore[2] = MonthPVP_Score_Camp2_Text2;
	g_MonthPVP_Score_TeamScore[3] = MonthPVP_Score_Camp3_Text2;

	-- 阵营技能图片
	g_MonthPVP_Score_SkillItem[1] = MonthPVP_Score_MyCamp_SkillItem1;
	g_MonthPVP_Score_SkillItem[2] = MonthPVP_Score_MyCamp_SkillItem2;
	g_MonthPVP_Score_SkillItem[3] = MonthPVP_Score_MyCamp_SkillItem3;
	g_MonthPVP_Score_SkillItem[4] = MonthPVP_Score_MyCamp_SkillItem4;

	-- 阵营技能图片
	g_MonthPVP_Score_SkillLock[1] = MonthPVP_Score_MyCamp_SkillItem1Lock;
	g_MonthPVP_Score_SkillLock[2] = MonthPVP_Score_MyCamp_SkillItem2Lock;
	g_MonthPVP_Score_SkillLock[3] = MonthPVP_Score_MyCamp_SkillItem3Lock;
	g_MonthPVP_Score_SkillLock[4] = MonthPVP_Score_MyCamp_SkillItem4Lock;

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function MonthPVP_Score_ResetPos()
	MonthPVP_Score_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	MonthPVP_Score_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function MonthPVP_Score_OnEvent(event)
	if( event == "UI_COMMAND" and tonumber(arg0) == 82003002) then
		local nParamSTR0 = Get_XParam_STR(0)
		local nTeam = 
		{
			[1] = {nRanking=0,nScore=0},
			[2] = {nRanking=0,nScore=0},
			[3] = {nRanking=0,nScore=0},
		}
		for i=0,2 do --0,1 2,3 4,5
			nTeam[i+1].nRanking = Get_XParam_INT(2*i)
			nTeam[i+1].nScore = Get_XParam_INT(2*i+1)
		end

		--共用数据
		local nLevel = Get_XParam_INT(6)
		local nExp = Get_XParam_INT(7)
		local nBelong = Get_XParam_INT(8)
		local nGameNum = Get_XParam_INT(9)
		local nPLAYERSCORE = 0 --个人积分	

		--差异数据
		local nDiffParam = 
		{
			[1] = {nChoice	 = -1}, --nParamSTR0
			[2] = {nParamINT = -1}, --nFarmTime nStep
			[3] = {nParamINT = -1}, --nCampID
			[4] = {nParamINT = -1}, --nHpMax
		}

		if nParamSTR0 == "FARM" then
			nDiffParam[1].nChoice = 1
			nDiffParam[2].nParamINT = Get_XParam_INT(10) --nFarmTime
			nDiffParam[3].nParamINT = Get_XParam_INT(11) --月光碎片
			nPLAYERSCORE = Get_XParam_INT(12) --个人积分
		elseif nParamSTR0 == "CAR" then
			nDiffParam[1].nChoice = 2
			nDiffParam[2].nParamINT = Get_XParam_INT(10) --nStep
			nDiffParam[3].nParamINT = Get_XParam_INT(11) --nCampID
			nDiffParam[4].nParamINT = Get_XParam_INT(12) --nHpMax
			nPLAYERSCORE = Get_XParam_INT(13) --个人积分
		end

		if (this:IsVisible()) then
			MonthPVP_Score_Update(nTeam,nLevel,nExp,nBelong,nGameNum,nDiffParam,nPLAYERSCORE)
			return
		end

		if (IsWindowShow("MonthPVP_ScoreMini")) then
			return
		else
			MonthPVP_Score_Show()
			MonthPVP_Score_Update(nTeam,nLevel,nExp,nBelong,nGameNum,nDiffParam,nPLAYERSCORE)
		end
	elseif(event == "UI_COMMAND" and tonumber(arg0) == 82003003) then
		MonthPVP_Score_Hide()
		if IsWindowShow("MonthPVP_ScoreMini") == true then
			CloseWindow("MonthPVP_ScoreMini", true)
		end
	elseif(event == "OPEN_WINDOW") then
		if( arg0 == " MonthPVP_Score") then
			MonthPVP_Score_Show()
		end
	elseif(event == "CLOSE_WINDOW") then
		if( arg0 == "MonthPVP_Score") then
			MonthPVP_Score_Hide()
		end		
	elseif event=="HIDE_ON_SCENE_TRANSED" or event=="SCENE_TRANSED" or event=="PLAYER_LEAVE_WORLD" then
		MonthPVP_Score_Hide()
	end

	if this:IsVisible() then
        if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
			MonthPVP_Score_ResetPos()
        end
	end
end

--显示UI
function MonthPVP_Score_Show()
	MonthPVP_Score_ClearData()
	if IsWindowShow("MonthPVP_ScoreMini") == true then
		CloseWindow("MonthPVP_ScoreMini", true)
	end
	this:Show()
end

--隐藏UI
function MonthPVP_Score_Hide()
	MonthPVP_Score_ClearData()
	this:Hide()
end

--MiniUI
function MonthPVP_Score_Mini()
	OpenWindow("MonthPVP_ScoreMini")
	MonthPVP_Score_ClearData()
	this:Hide()
end

--清除数据
function MonthPVP_Score_ClearData()

end

--更新
function MonthPVP_Score_Update(nTeam,nLevel,nExp,nBelong,nGameNum,nDiffParam,nPLAYERSCORE)
	--更新阵营Exp
	MonthPVP_Score_ShowTeamExp(nBelong,nLevel,nExp)
	--更新阵营分数
	MonthPVP_Score_ShowTeamRank(nTeam,nBelong)
	--更新阵营Step
	MonthPVP_Score_ShowTeamStep(nDiffParam,nGameNum)

	MonthPVP_Score_MyCamp:SetProperty("Image",g_MonthPVP_Score_BelongPIC[nBelong].image)

	MonthPVP_Score_Text:SetText(ScriptGlobal_Format("#{LLKC_240517_315}",nPLAYERSCORE))
end

--更新阵营Exp
function MonthPVP_Score_ShowTeamExp(nBelong,nLevel,nExp)
	--Name
	--MonthPVP_Score_MyCamp_Title:SetText(g_MonthPVP_Score_StrTeamName[nBelong].str)
	--Level
	MonthPVP_Score_MyCamp_Level:SetText(ScriptGlobal_Format("#{LLKC_240517_196}",nLevel))
	--Exp
	if nLevel == 5 then
		MonthPVP_Score_MyCamp_ExpText:SetText(ScriptGlobal_Format("#{LLKC_240517_200}",g_MonthPVP_Score_NeedExp[nLevel],g_MonthPVP_Score_NeedExp[nLevel]))
		--MonthPVP_Score_MyCamp_Exp:SetProgress(100,100)
	else
		MonthPVP_Score_MyCamp_ExpText:SetText(ScriptGlobal_Format("#{LLKC_240517_200}",nExp,g_MonthPVP_Score_NeedExp[nLevel]))
		--MonthPVP_Score_MyCamp_Exp:SetProgress(nExp,g_MonthPVP_Score_NeedExp[nLevel])
	end
	

	--技能图片
	for i=1,4 do
		local j = i+1
		if nLevel >= j then
			g_MonthPVP_Score_SkillItem[i]:SetToolTip(g_MonthPVP_Score_StrSkill[nBelong][j].name)
			g_MonthPVP_Score_SkillLock[i]:Hide()
		else
			g_MonthPVP_Score_SkillLock[i]:SetProperty("Image","set:NewExterior3 image:NewExterior_jiaobiao_suo_di")
			g_MonthPVP_Score_SkillLock[i]:SetToolTip(g_MonthPVP_Score_StrSkill[nBelong][j].str)
			g_MonthPVP_Score_SkillLock[i]:Show()
		end
		g_MonthPVP_Score_SkillItem[i]:SetProperty("Image",g_MonthPVP_Score_SkillPIC[nBelong][j].image)
		g_MonthPVP_Score_SkillItem[i]:Show()
	end

end

--更新阵营分数
function MonthPVP_Score_ShowTeamRank(nTeam,nBelong)
	for i=1,3 do
		g_MonthPVP_Score_TeamName[i]:SetText(g_MonthPVP_Score_StrTeamName[nTeam[i].nRanking].str)
		g_MonthPVP_Score_TeamScore[i]:SetText(ScriptGlobal_Format("#{LLKC_240517_120}",nTeam[i].nScore))
		if nTeam[i].nRanking == nBelong then
			g_MonthPVP_Score_TeamPic[i]:Show()
		else
			g_MonthPVP_Score_TeamPic[i]:Hide()
		end
	end
end

--更新阵营Step
function MonthPVP_Score_ShowTeamStep(nDiffParam,nGameNum)

	if nDiffParam[1].nChoice == 1 then
		MonthPVP_Score_Farm:Show()
		MonthPVP_Score_FarmTimer(nDiffParam[2].nParamINT)
		MonthPVP_Score_Farm_Lunci:SetText(ScriptGlobal_Format("#{LLKC_240517_123}",g_MonthPVP_Score_MaxGame-nGameNum+1))
		MonthPVP_Score_Farm_Text:SetText(ScriptGlobal_Format("#{LLKC_240517_292}",nDiffParam[3].nParamINT))

		MonthPVP_Score_Car:Hide()
	elseif nDiffParam[1].nChoice == 2 then
		MonthPVP_Score_Car:Show()
		local nWhich = 1
		if nDiffParam[2].nParamINT == g_MonthPVP_Score_StepWaitFight then
			nWhich = 1
		elseif nDiffParam[2].nParamINT == g_MonthPVP_Score_StepWaitGo or nDiffParam[2].nParamINT == g_MonthPVP_Score_StepGoTo then
			nWhich = 2
		elseif nDiffParam[2].nParamINT == g_MonthPVP_Score_StepWaitKill then
			nWhich = 3
		elseif nDiffParam[2].nParamINT == g_MonthPVP_Score_StepReWait or nDiffParam[2].nParamINT == g_MonthPVP_Score_StepReCteate then
			nWhich = 4
		end

		if nWhich == 3 then
			MonthPVP_Score_Car_Text:SetText(ScriptGlobal_Format(g_MonthPVP_Score_StrCAR[nWhich].str,g_MonthPVP_Score_StrTeamName[nDiffParam[3].nParamINT].str))
			MonthPVP_Score_Car_HP:SetText(ScriptGlobal_Format("#{LLKC_240517_202}",nDiffParam[4].nParamINT))
			MonthPVP_Score_Car_HP:Show()
		else
			MonthPVP_Score_Car_Text:SetText(g_MonthPVP_Score_StrCAR[nWhich].str)
			MonthPVP_Score_Car_HP:Hide()
		end
		MonthPVP_Score_Car_Lunci:SetText(ScriptGlobal_Format("#{LLKC_240517_123}",g_MonthPVP_Score_MaxGame-nGameNum+1))
		
		MonthPVP_Score_Farm:Hide()
	else
		return
	end

end

function MonthPVP_Score_FarmTimer(countTime)

	if countTime < 0 then
		countTime = 0
	end

	local minuteTime = math.floor(countTime/60)
	local secTime = math.mod(countTime,60)

	local strMinute = tostring(minuteTime)
	if minuteTime < 10 then
		strMinute = "0"..tostring(minuteTime)
	end
	
	local strSec = tostring(secTime)
	if secTime < 10 then
		strSec = "0"..tostring(secTime)
	end
	
    --#cfff263副本攻略时间：#G%s0：%s1#cfff263
    MonthPVP_Score_Farm_Time:SetText(ScriptGlobal_Format("#{LLKC_240517_206}",strMinute,strSec))

end

function MonthPVP_Score_Help()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ScoreHelp" )
		Set_XSCRIPT_ScriptID( 820030 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function MonthPVP_Score_TopList()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "ScoreTopList" )
		Set_XSCRIPT_ScriptID( 820030 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end