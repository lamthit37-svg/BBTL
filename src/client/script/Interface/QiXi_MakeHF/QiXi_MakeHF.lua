
----------------------------------------------------------------------------------------
-- 
----------------------------------------------------------------------------------------
local g_picNum = {
	"set:Sign image:Signorange_0",
	"set:Sign image:Signorange_1",
	"set:Sign image:Signorange_2",
	"set:Sign image:Signorange_3",
	"set:Sign image:Signorange_4",
	"set:Sign image:Signorange_5",
	"set:Sign image:Signorange_6",
	"set:Sign image:Signorange_7",
	"set:Sign image:Signorange_8",
	"set:Sign image:Signorange_9",
}
function UIGlobal_SetNum(realNum, tabUI)
	local num = realNum;
	for i, v in pairs(tabUI or {}) do 
		local one = math.mod(num, 10);
		v:SetProperty("Image", g_picNum[one+1])
		num = math.floor(num/10);
	end
end


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
local g_Frame_UnifiedPosition;
local g_UIBird_UnifiedPosition;
local g_AwardFlag = 0 			--今日是否领过奖
local g_MaxPassNum = 0 			--今日最高通过关卡
local g_RandomKey = 0 			--当前玩法的服务器Key
local g_nHHQN = 0 				--画好情浓
local g_nQQXH = 0 				--鹊桥相会
local g_ClickCanUp = false
local g_ClickNum = 0
local g_PassNum = 0
local g_TimerCount = 0
local g_tab_AllControl = {}
local g_tab_StageInfo = {}
local g_tab_RemainNum = {}
local g_Tween_Index = 0;
local g_Show_Index = 0;
local g_Cube_Index = 0

--预加载函数，可以而且只能在这里注册脚本关心的事件
function QiXi_MakeHF_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("FLAPPY_BIRD_PASS",false)
	this:RegisterEvent("FLAPPY_BIRD_FAIL",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function QiXi_MakeHF_OnLoad()
	g_Frame_UnifiedPosition = QiXi_MakeHF_Frame:GetProperty("UnifiedPosition")
	g_UIBird_UnifiedPosition = QiXi_MakeHF_Main:GetProperty("UnifiedPosition")

	local from_to_info = "curve:Liner mode:Loop duration:8.57 startx:0 starty:0 endx:-600 endy:0"
	QiXi_MakeHF_RowPic:Tween_SetInfo("Position", from_to_info)

	g_tab_AllControl = {
		{ QiXi_MakeHF_Level1_1, QiXi_MakeHF_Level1_1_Image1, QiXi_MakeHF_Level1_1_Image2, QiXi_MakeHF_Level1_1_Image3 },
		{ QiXi_MakeHF_Level1_2, QiXi_MakeHF_Level1_2_Image1, QiXi_MakeHF_Level1_2_Image2, QiXi_MakeHF_Level1_2_Image3 },
		{ QiXi_MakeHF_Level1_3, QiXi_MakeHF_Level1_3_Image1, QiXi_MakeHF_Level1_3_Image2, QiXi_MakeHF_Level1_3_Image3 },
		{ QiXi_MakeHF_Level1_4, QiXi_MakeHF_Level1_4_Image1, QiXi_MakeHF_Level1_4_Image2, QiXi_MakeHF_Level1_4_Image3 },
		{ QiXi_MakeHF_Level1_5, QiXi_MakeHF_Level1_5_Image1, QiXi_MakeHF_Level1_5_Image2, QiXi_MakeHF_Level1_5_Image3 },
		{ QiXi_MakeHF_Level1_6, QiXi_MakeHF_Level1_6_Image1, QiXi_MakeHF_Level1_6_Image2, QiXi_MakeHF_Level1_6_Image3 },
		{ QiXi_MakeHF_Level2_1, QiXi_MakeHF_Level2_1_Image1, QiXi_MakeHF_Level2_1_Image2, QiXi_MakeHF_Level2_1_Image3 },
		{ QiXi_MakeHF_Level2_2, QiXi_MakeHF_Level2_2_Image1, QiXi_MakeHF_Level2_2_Image2, QiXi_MakeHF_Level2_2_Image3 },
		{ QiXi_MakeHF_Level2_3, QiXi_MakeHF_Level2_3_Image1, QiXi_MakeHF_Level2_3_Image2, QiXi_MakeHF_Level2_3_Image3 },
		{ QiXi_MakeHF_Level2_4, QiXi_MakeHF_Level2_4_Image1, QiXi_MakeHF_Level2_4_Image2, QiXi_MakeHF_Level2_4_Image3 },
		{ QiXi_MakeHF_Level2_5, QiXi_MakeHF_Level2_5_Image1, QiXi_MakeHF_Level2_5_Image2, QiXi_MakeHF_Level2_5_Image3 },
		{ QiXi_MakeHF_Level2_6, QiXi_MakeHF_Level2_6_Image1, QiXi_MakeHF_Level2_6_Image2, QiXi_MakeHF_Level2_6_Image3 },
		{ QiXi_MakeHF_Level3_1, QiXi_MakeHF_Level3_1_Image1, QiXi_MakeHF_Level3_1_Image2, QiXi_MakeHF_Level3_1_Image3 },
		{ QiXi_MakeHF_Level3_2, QiXi_MakeHF_Level3_2_Image1, QiXi_MakeHF_Level3_2_Image2, QiXi_MakeHF_Level3_2_Image3 },
		{ QiXi_MakeHF_Level3_3, QiXi_MakeHF_Level3_3_Image1, QiXi_MakeHF_Level3_3_Image2, QiXi_MakeHF_Level3_3_Image3 },
		{ QiXi_MakeHF_Level3_4, QiXi_MakeHF_Level3_4_Image1, QiXi_MakeHF_Level3_4_Image2, QiXi_MakeHF_Level3_4_Image3 },
		{ QiXi_MakeHF_Level3_5, QiXi_MakeHF_Level3_5_Image1, QiXi_MakeHF_Level3_5_Image2, QiXi_MakeHF_Level3_5_Image3 },
		{ QiXi_MakeHF_Level3_6, QiXi_MakeHF_Level3_6_Image1, QiXi_MakeHF_Level3_6_Image2, QiXi_MakeHF_Level3_6_Image3 },
	}
	for i, v in pairs(g_tab_AllControl) do 
		v[1]:SetProperty("UnifiedPosition", "{{1.000000,0.000000},{0.000000,0.000000}}")
		v[1]:Tween_SetInfo("Position", "curve:Liner mode:Once duration:10 startx:0 starty:0 endx:-700 endy:0")
	end
	QiXi_MakeHF_TipsBK:Hide()
	QiXi_MakeHF_TipsText:Hide()
end

--响应事件的函数，当注册的事件发生时会调用的函数
function QiXi_MakeHF_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		QiXi_MakeHF_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89312601 ) then
		local nCareNpcID = Get_XParam_INT( 0 )
		g_AwardFlag = Get_XParam_INT( 1 )
		g_MaxPassNum = Get_XParam_INT( 2 )
		g_nHHQN = Get_XParam_INT( 3 )
		g_nQQXH = Get_XParam_INT( 4 )
		if nCareNpcID ~= 0 then 
			local Care_OBJ = Target:GetServerId2ClientId( tonumber( nCareNpcID ) );
			this:CareObject(Care_OBJ, 1, "QiXi_MakeHF");
		end

		QiXi_MakeHF_ShowOnce()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89312602 ) then
		g_AwardFlag = Get_XParam_INT( 0 )
		g_MaxPassNum = Get_XParam_INT( 1 )
		g_RandomKey = Get_XParam_INT( 2 )
		QiXi_MakeHF_BtnStart:Hide();
		QiXi_MakeHF_TipsBK:Hide()
		QiXi_MakeHF_RowPic:Tween_Play("Position", true, false)
		QiXi_MakeHF_CountDown_Animate:Play(true)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89312603 ) then
		g_AwardFlag = Get_XParam_INT( 0 )
		g_MaxPassNum = Get_XParam_INT( 1 )
		QiXi_MakeHF_InitFinish();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89312604 ) then
		this:Hide()
	elseif ( event == "FLAPPY_BIRD_PASS") then 
		QiXi_MakeHF_PassOne()
	elseif ( event == "FLAPPY_BIRD_FAIL") then 
		if g_PassNum < 5 then 
			QiXi_MakeHF_InitFinish()
			QiXi_MakeHF_RealStop()
		else
			QiXi_MakeHF_GameSuccess()
		end

	end
end

--以下是用户自定义的函数
function QiXi_MakeHF_OnHide()
	QiXi_MakeHF_RealStop()
end
function QiXi_MakeHF_CloseWnd()
	this:Hide()
end
function QiXi_MakeHF_ShowOnce()
	if this:IsVisible() then return end
	Lua_FlappyBird_Init("QiXi_MakeHF_Main")
	QiXi_MakeHF_Init()
	this:Show()
end
function QiXi_MakeHF_Init()
	QiXi_MakeHF_BtnStart:Show()
	QiXi_MakeHF_TipsBK:Hide()
	QiXi_MakeHF_TipsText1:Hide()
	QiXi_MakeHF_TipsText2:Hide()
	-- if g_nQQXH == 2 then 
		-- QiXi_MakeHF_TipsText1:SetText("#{QXHF_190620_164}")
	-- else
		-- QiXi_MakeHF_TipsText1:SetText("#{QXHF_190620_165}")
	-- end
	-- if g_nHHQN == 1 then 
		-- QiXi_MakeHF_TipsText2:SetText("#{QXHF_190620_166}")
	-- else
		-- QiXi_MakeHF_TipsText2:SetText("#{QXHF_190620_167}")
	-- end

	QiXi_MakeHF_TipsText:Hide()
	QiXi_MakeHF_HelpText:Hide()
	QiXi_MakeHF_Finish:Hide()
	Lua_FlappyBird_MoveUpdate(false, 0, 0, 0);
	QiXi_MakeHF_CountDown_Animate:Play(false)
	QiXi_MakeHF_Guide_Animate:Play(false)
	QiXi_MakeHF_Main:SetProperty("UnifiedPosition", g_UIBird_UnifiedPosition)
	g_tab_StageInfo = {};
	g_tab_RemainNum = {};
	for i, v in pairs(g_tab_AllControl) do 
		table.insert(g_tab_RemainNum, i);
		v[1]:Tween_Stop("Position")
		v[1]:SetProperty("UnifiedPosition", "{{1.000000,0.000000},{0.000000,0.000000}}")
	end
	g_ClickCanUp = false
	QiXi_MakeHF_MainControl:Hide()
	g_ClickNum = 0
	g_Tween_Index = 0
	g_Show_Index = 0
	g_Cube_Index = 0
	g_TimerCount = 0

	g_PassNum = 0
	UIGlobal_SetNum(g_PassNum, {QiXi_MakeHF_Score_Pic2, QiXi_MakeHF_Score_Pic1})
end
function QiXi_MakeHF_InitFinish()
	QiXi_MakeHF_Finish:Show()
	if g_AwardFlag == 1 then 
		QiXi_MakeHF_Finish_Text:SetText("#{QXHF_190620_58}")
	elseif g_MaxPassNum >= 10 then 
		QiXi_MakeHF_Finish_Text:SetText(ScriptGlobal_Format("#{QXHF_190620_125}", g_MaxPassNum))
	elseif g_MaxPassNum >= 5 then 
		QiXi_MakeHF_Finish_Text:SetText("#{QXHF_190620_126}")
	else
		QiXi_MakeHF_Finish_Text:SetText("#{QXHF_190620_52}")
	end
end
function QiXi_MakeHF_PassOne()
	g_PassNum = g_PassNum + 1
	UIGlobal_SetNum(g_PassNum, {QiXi_MakeHF_Score_Pic2, QiXi_MakeHF_Score_Pic1})
	local tabInfo = g_tab_StageInfo[g_PassNum]
	if not tabInfo then 
		PushDebugMessage("ERROR:QiXi_MakeHF_PassOne:StageInfo is nil:g_PassNum="..(g_PassNum or "nil"))
		return
	end
	g_tab_AllControl[tabInfo.nControlIndex][3]:Show();
	if g_PassNum >= 100 then 
		QiXi_MakeHF_GameSuccess()
		return
	end
	QiXi_MakeHF_NextCube()
end
function QiXi_MakeHF_StartClick()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGameStart" )
		Set_XSCRIPT_ScriptID( 893126 )
		Set_XSCRIPT_ParamCount( 0 )
	Send_XSCRIPT()
end
function QiXi_MakeHF_OnAnimStartEnd()
	g_ClickCanUp = true
	QiXi_MakeHF_MainControl:Show()
	QiXi_MakeHF_Guide_Animate:Play(true)
	QiXi_MakeHF_TipsText:Hide()
	QiXi_MakeHF_HelpText:Show()
end
function QiXi_MakeHF_OnTweenEnd()
	g_Tween_Index = g_Tween_Index + 1
	local tabInfo = g_tab_StageInfo[g_Tween_Index]
	if not tabInfo then 
		PushDebugMessage("ERROR:QiXi_MakeHF_OnTweenEnd:StageInfo is nil:g_Tween_Index="..(g_Tween_Index or "nil"))
		return
	end
	table.insert(g_tab_RemainNum, tabInfo.nControlIndex)
end
function QiXi_MakeHF_RealStart()
	--设置初速度和加速度
	QiXi_MakeHF_Guide_Animate:Play(false)
	Lua_FlappyBird_MoveUpdate(false, 16, -3.8, g_RandomKey);
	QiXi_MakeHF_NextShow()
	QiXi_MakeHF_NextCube()
	SetTimer("QiXi_MakeHF","QiXi_MakeHF_TimerProc()", 100)
end
function QiXi_MakeHF_RealStop()
	g_ClickCanUp = false
	QiXi_MakeHF_MainControl:Hide()
	KillTimer("QiXi_MakeHF_TimerProc()")
	QiXi_MakeHF_RowPic:Tween_Stop("Position")
	for i, v in pairs(g_tab_StageInfo) do 
		g_tab_AllControl[v.nControlIndex][1]:Tween_Stop("Position")
	end
end
function QiXi_MakeHF_NextCube()
	g_Cube_Index = g_Cube_Index + 1
	local tabInfo = g_tab_StageInfo[g_Cube_Index]
	if not tabInfo then 
		PushDebugMessage("QiXi_MakeHF_NextCube:StageInfo is nil:g_Cube_Index="..(g_Cube_Index or "nil"))
		return
	end
	local cubeName = g_tab_AllControl[tabInfo.nControlIndex][1]:GetName()
	local cubePos = g_tab_AllControl[tabInfo.nControlIndex][2]:GetProperty("AbsoluteYPosition")
	local cubeTopPos = g_tab_AllControl[tabInfo.nControlIndex][4]:GetProperty("AbsoluteYPosition") + cubePos
	local cubeHeight = g_tab_AllControl[tabInfo.nControlIndex][4]:GetProperty("AbsoluteHeight")
	Lua_FlappyBird_SetCube(cubeName, cubeTopPos, cubeTopPos+cubeHeight)
end
function QiXi_MakeHF_NextShow()
	g_Show_Index = g_Show_Index + 1
	local nMax = table.getn(g_tab_RemainNum);
	local nRandomIndex = math.random(1, nMax);
	local nRandomHeight = math.random(20, 120);
	local nRandomLength = math.random(22, 26);
	local tabInfo = {}
	tabInfo.nControlIndex = g_tab_RemainNum[nRandomIndex];
	tabInfo.nRandomHeight = nRandomHeight;
	tabInfo.nRandomLength = nRandomLength;
	table.insert(g_tab_StageInfo, tabInfo)

	table.remove(g_tab_RemainNum, nRandomIndex)

	g_tab_AllControl[tabInfo.nControlIndex][3]:Hide()
	g_tab_AllControl[tabInfo.nControlIndex][2]:SetProperty("UnifiedPosition", string.format("{{0.000000,0.000000},{0.000000,-%s.000000}}", nRandomHeight))
	g_tab_AllControl[tabInfo.nControlIndex][1]:Tween_Play("Position", true, true)
end
function QiXi_MakeHF_TimerProc()
	g_TimerCount = g_TimerCount + 1
	local tabInfo = g_tab_StageInfo[g_Show_Index]
	if not tabInfo then 
		PushDebugMessage("QiXi_MakeHF_TimerProc:StageInfo is nil:g_Show_Index="..(g_Show_Index or "nil"))
		return
	end
	if g_TimerCount > tabInfo.nRandomLength then 
		g_TimerCount = 0
		QiXi_MakeHF_NextShow()
	end
end
function QiXi_MakeHF_ClickClickUp()
	if not g_ClickCanUp then 
		PushDebugMessage("#{QXHF_190620_50}")
		return 
	end
	if g_ClickNum == 0 then 
		g_ClickNum = 1
		QiXi_MakeHF_RealStart()
	end
	Lua_FlappyBird_MoveUpdate(true)
end
function QiXi_MakeHF_GameSuccess()
	if not g_ClickCanUp then return end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GameSuccess" )
		Set_XSCRIPT_ScriptID( 893126 )
		Set_XSCRIPT_Parameter( 0, g_PassNum )
		Set_XSCRIPT_Parameter( 1, Helper:Encode_GetResult() )
		Set_XSCRIPT_ParamCount( 2 )
	Send_XSCRIPT()
	QiXi_MakeHF_RealStop()
end

function QiXi_MakeHF_StartAgain()
	QiXi_MakeHF_Init()
	QiXi_MakeHF_BtnStart:Hide()
	QiXi_MakeHF_TipsBK:Hide()
	QiXi_MakeHF_TipsText:Hide()
	QiXi_MakeHF_HelpText:Show()
	QiXi_MakeHF_StartClick()
end

function QiXi_MakeHF_HelpClick()
	PushEvent( "OPEN_HUODONGTEXT_HELP", "QiXi_MakeHF", "#{QXHF_190620_45}" )
end