--2019 元宵节活动-扣碗猜球活动
local g_CaiQiu_Frame_UnifiedPosition;
local g_CaiQiu_target;
local g_CaiQiu_OBJ;

local g_CaiQiu_Path_1_2 = {
	{time = 0, value = {-150,0,0}, inSlope={75,-80,0}, outSlope = {75,-80,0} },
	{time = 1, value = {-75,-80,0}, inSlope={75,0,0}, outSlope = {75,0,0} },
	{time = 2, value = {0,0,0}, inSlope={75,80,0}, outSlope = {75,80,0} },
}
local g_CaiQiu_Path_1_3 = {
	{time = 0, value = {-150,0,0}, inSlope={150,-80,0}, outSlope = {150,-80,0} },
	{time = 1, value = {0,-80,0}, inSlope={150,0,0}, outSlope = {150,0,0} },
	{time = 2, value = {150,0,0}, inSlope={150,80,0}, outSlope = {150,80,0} },
}
local g_CaiQiu_Path_2_1= {
	{time = 0, value = {0,0,0}, inSlope={-75,80,0}, outSlope = {-75,80,0} },
	{time = 1, value = {-75,80,0}, inSlope={-75,0,0}, outSlope = {-75,0,0} },
	{time = 2, value = {-150,0,0}, inSlope={-75,-80,0}, outSlope = {-75,-80,0} },
}
local g_CaiQiu_Path_2_3 = {
	{time = 0, value = {0,0,0}, inSlope={75,-80,0}, outSlope = {75,-80,0} },
	{time = 1, value = {75,-80,0}, inSlope={75,0,0}, outSlope = {75,0,0} },
	{time = 2, value = {150,0,0}, inSlope={75,80,0}, outSlope = {75,80,0} },
}
local g_CaiQiu_Path_3_1 = {
	{time = 0, value = {150,0,0}, inSlope={-150,80,0}, outSlope = {-150,80,0} },
	{time = 1, value = {0,80,0}, inSlope={-150,0,0}, outSlope = {-150,0,0} },
	{time = 2, value = {-150,0,0}, inSlope={-150,-80,0}, outSlope = {-150,-80,0} },
}
local g_CaiQiu_Path_3_2 = {
	{time = 0, value = {150,0,0}, inSlope={-75,80,0}, outSlope = {-75,80,0} },
	{time = 1, value = {75,80,0}, inSlope={-75,0,0}, outSlope = {-75,0,0} },
	{time = 2, value = {0,0,0}, inSlope={-75,-80,0}, outSlope = {-75,-80,0} },
}

local tabMoveUI = nil;
local tabAnimationUI = nil;
local tabAnimation_WuUI = nil;
local tabMaskWanUI = nil;
local tabQiuUI = nil;
local tabJianTouUI = nil;
local g_CurIndex = 0
local g_ResultIndex = 0
local g_RandomIndex = 0


local tabLoopNum = {
	[0] = {loopNum = 2, onceTime = 0.5, waitTime = 200},
	[1] = {loopNum = 4, onceTime = 0.4, waitTime = 200},
	[2] = {loopNum = 6, onceTime = 0.3, waitTime = 200},
	[3] = {loopNum = 8, onceTime = 0.25, waitTime = 260},
	[4] = {loopNum = 10, onceTime = 0.2, waitTime = 260},
	[5] = {loopNum = 12, onceTime = 0.18, waitTime = 260},
	[6] = {loopNum = 13, onceTime = 0.18, waitTime = 250},
	[7] = {loopNum = 14, onceTime = 0.18, waitTime = 240},
	[8] = {loopNum = 15, onceTime = 0.18, waitTime = 230},
	[9] = {loopNum = 16, onceTime = 0.18, waitTime = 220},
	[10] = {loopNum = 18, onceTime = 0.16, waitTime = 260},
	[11] = {loopNum = 19, onceTime = 0.16, waitTime = 250},
	[12] = {loopNum = 20, onceTime = 0.16, waitTime = 240},
	[13] = {loopNum = 21, onceTime = 0.16, waitTime = 230},
	[14] = {loopNum = 22, onceTime = 0.16, waitTime = 220},
	[15] = {loopNum = 24, onceTime = 0.14, waitTime = 260},
	[16] = {loopNum = 25, onceTime = 0.14, waitTime = 250},
	[17] = {loopNum = 26, onceTime = 0.14, waitTime = 240},
	[18] = {loopNum = 27, onceTime = 0.14, waitTime = 230},
	[19] = {loopNum = 28, onceTime = 0.14, waitTime = 220},
	[20] = {loopNum = 28, onceTime = 0.14, waitTime = 220},
}
local g_MaxLoopNum = table.getn(tabLoopNum);
local tabLoopAllCon = {
	{1,2},--{1,2,3},
	{1,3},--{1,3,2},
	{2,3},
};
local g_LoopAllConNum = table.getn(tabLoopAllCon)
local g_tabLoopOpera = {};
local g_LoopIndex = 0
local g_LoopMaxIndex = 0
local g_LoopTime = 0
local g_IsReadyClick = false

function CaiQiu_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function CaiQiu_OnLoad()
	g_CaiQiu_Frame_UnifiedPosition = CaiQiu_FrameNULL:GetProperty("UnifiedPosition")

	CaiQiu_Page2_Icon:Tween_AddCurveVec3("CaiQiu_1_2", g_CaiQiu_Path_1_2, true)
	CaiQiu_Page2_Icon:Tween_AddCurveVec3("CaiQiu_1_3", g_CaiQiu_Path_1_3, true)
	CaiQiu_Page2_Icon:Tween_AddCurveVec3("CaiQiu_2_1", g_CaiQiu_Path_2_1, true)
	CaiQiu_Page2_Icon:Tween_AddCurveVec3("CaiQiu_2_3", g_CaiQiu_Path_2_3, true)
	CaiQiu_Page2_Icon:Tween_AddCurveVec3("CaiQiu_3_1", g_CaiQiu_Path_3_1, true)
	CaiQiu_Page2_Icon:Tween_AddCurveVec3("CaiQiu_3_2", g_CaiQiu_Path_3_2, true)

	tabMoveUI = {CaiQiu_Page1_Icon,CaiQiu_Page2_Icon,CaiQiu_Page3_Icon}
	tabAnimationUI = {CaiQiu_Page1_Animate,CaiQiu_Page2_Animate,CaiQiu_Page3_Animate}
	tabAnimation_WuUI = {CaiQiu_Page1_Animate1,CaiQiu_Page2_Animate1,CaiQiu_Page3_Animate1}
	tabMaskWanUI = {CaiQiu_Page1_Mark, CaiQiu_Page2_Mark, CaiQiu_Page3_Mark}
	tabQiuUI = {CaiQiu_Page1_Zhu, CaiQiu_Page2_Zhu, CaiQiu_Page3_Zhu}
	tabJianTouUI = {CaiQiu_Page1_Animate2, CaiQiu_Page2_Animate2, CaiQiu_Page3_Animate2}
	for i = 1, 3 do 
		tabAnimationUI[i]:Play(false);
		tabAnimation_WuUI[i]:Play(false);
		tabQiuUI[i]:Hide()
		tabJianTouUI[i]:Play(false);
	end
	CaiQiu_Page_Animate_XuanDui:Play(false)
	CaiQiu_Page_Animate_XuanCuo:Play(false)
	CaiQiu_Page_Animate_XuanDui_BK:Hide();
	CaiQiu_Page_Animate_XuanCuo_BK:Hide();

end

function CaiQiu_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		CaiQiu_FrameNULL:SetProperty("UnifiedPosition", g_CaiQiu_Frame_UnifiedPosition)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89298001 ) then
		if not this:IsVisible() then
			this:Show();
		end
		g_CaiQiu_target = Get_XParam_INT(0)
		g_CurIndex = Get_XParam_INT(1)
		g_ResultIndex = Get_XParam_INT(2)
		if g_CaiQiu_target ~= 0 then 
			g_CaiQiu_OBJ = Target:GetServerId2ClientId( tonumber( g_CaiQiu_target ) );
			this:CareObject(g_CaiQiu_OBJ, 1, "CaiQiu");
		end
		CaiQiu_TishiText("")
		CaiQiu_OnShowInit();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89298002 ) then
		CaiQiu_ResetBtnAnim()
		-- 点击开始游戏-反馈
		g_RandomIndex = Get_XParam_INT(0)
		CaiQiu_BtnStart:Hide();
		tabAnimationUI[g_RandomIndex]:Play(true)
		tabJianTouUI[g_RandomIndex]:Play(true)
		tabMaskWanUI[g_RandomIndex]:Hide()
		CaiQiu_TishiText("#{KWCQ_181201_41}")
		CaiQiu_BtnReady:Show();
		CaiQiu_Btn_Continue:Hide();
		CaiQiu_Btn_Continue2:Hide();
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89298003 ) then
		CaiQiu_ResetBtnAnim()
		-- 点击准备好了-反馈
		g_RandomIndex = Get_XParam_INT(0)
		tabAnimationUI[g_RandomIndex]:Play(false)
		tabQiuUI[g_RandomIndex]:Hide();
		tabJianTouUI[g_RandomIndex]:Play(false)
		tabMaskWanUI[g_RandomIndex]:Show();
		CaiQiu_BtnReady:Hide();
		g_IsReadyClick = true;
		CaiQiu_StartChangeWan()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89298004 ) then
		CaiQiu_ResetBtnAnim()
		-- 动画结束 选择某一碗-反馈
		local bResult = Get_XParam_INT(0)
		g_CurIndex = Get_XParam_INT(1)
		local ChooseIndex = Get_XParam_INT(2)
		local CorrectIndex = Get_XParam_INT(3)
		for i, v in pairs(tabJianTouUI) do 
			v:Play(false)
		end
		if bResult == 1 then 
			CaiQiu_Page_Animate_XuanDui:Play(true)
			tabAnimationUI[ChooseIndex]:Play(true)
			tabMaskWanUI[ChooseIndex]:Hide();
			CaiQiu_TishiText("#{KWCQ_181201_23}")
		else
			CaiQiu_Page_Animate_XuanCuo:Play(true)
			tabAnimation_WuUI[ChooseIndex]:Play(true)
			tabMaskWanUI[ChooseIndex]:Hide()
			tabAnimationUI[CorrectIndex]:Play(true)
			tabMaskWanUI[CorrectIndex]:Hide()
			CaiQiu_TishiText("#{KWCQ_181201_24}")
		end
		g_IsReadyClick = false;
		CaiQiu_BtnReady:Hide();
		if bResult == 1 and g_CurIndex < g_MaxLoopNum then 
			CaiQiu_Btn_Continue2:Show();
		else
			CaiQiu_Btn_Continue:Show();
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89298006 ) then
		AutoRunToTargetEx(292,350,0)
		SetAutoRunTargetNPCName( "张守快" )
		PushEvent( "CLOSE_SPRINGFES_GUIDE" )
	end
end

function CaiQiu_SetGuanText()
	local nShowIndex = g_CurIndex;
	if nShowIndex < g_MaxLoopNum then 
		nShowIndex = nShowIndex + 1
	end
	CaiQiu_Accumulate_Text:SetText(ScriptGlobal_Format("#{KWCQ_181201_9}", nShowIndex))
end

function CaiQiu_TishiText( szText )
	if not szText or szText == "" then 
		CaiQiu_TiShi_TextBK:Hide()
	else
		CaiQiu_TiShi_TextBK:Show()
		CaiQiu_TiShi_Text:SetText(szText)
	end
end

function CaiQiu_ResetBtnAnim()
	CaiQiu_Page_Animate_XuanDui:Play(false)
	CaiQiu_Page_Animate_XuanCuo:Play(false)
	CaiQiu_Page_Animate_XuanDui_BK:Hide();
	CaiQiu_Page_Animate_XuanCuo_BK:Hide();
	for i=1,3 do 
		tabAnimationUI[i]:Play(false)
		tabQiuUI[i]:Hide()
		tabJianTouUI[i]:Play(false)
		tabMaskWanUI[i]:Show()
	end
end

function CaiQiu_OnShowInit()
	CaiQiu_SetGuanText();
	if(IsWindowShow("Quest")) then
		CloseWindow("Quest", true);
	end
	CaiQiu_Page_Animate_XuanDui:Play(false)
	CaiQiu_Page_Animate_XuanCuo:Play(false)
	CaiQiu_Page_Animate_XuanDui_BK:Hide();
	CaiQiu_Page_Animate_XuanCuo_BK:Hide();
	for i=1,3 do 
		tabAnimationUI[i]:Play(false)
		tabQiuUI[i]:Hide()
		tabJianTouUI[i]:Play(false)
		tabMaskWanUI[i]:Show()
	end
	if g_ResultIndex == 0 then 
		CaiQiu_BtnStart:Show();
		CaiQiu_BtnReady:Hide();
		CaiQiu_Btn_Continue:Hide();
		CaiQiu_Btn_Continue2:Hide();
	else
		CaiQiu_TishiText("#{KWCQ_181201_15}")
		g_IsReadyClick = true;
		CaiQiu_BtnStart:Hide();
		CaiQiu_BtnReady:Hide();
		CaiQiu_Btn_Continue:Hide();
		CaiQiu_Btn_Continue2:Hide();
	end
end

function CaiQiu_OnHiden()
	this:Hide()
end

function CaiQiu_Choose_Clicked(nIndex)
	if not g_IsReadyClick then return end
	if g_LoopIndex ~= 0 then return end
	-- PushDebugMessage("CaiQiu_Choose_Clicked"..nIndex..(g_LoopIndex or "nil"))
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnRequestResult" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 892980 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 3 );						-- 参数一:类型
		Set_XSCRIPT_Parameter( 1, nIndex );					-- 参数二:类型
		Set_XSCRIPT_ParamCount( 2 );						-- 参数个数
	Send_XSCRIPT()
end

function CaiQiu_ChangeTwoIndex(fromIndex, toIndex)
	local old_from = tabMoveUI[fromIndex];
	local old_to = tabMoveUI[toIndex];
	tabMoveUI[fromIndex] = old_to;
	tabMoveUI[toIndex] = old_from;
	local from_to = string.format("curve:CaiQiu_%s_%s mode:Once duration:1 startx:0 starty:0 endx:0 endy:0", fromIndex, toIndex)
	local to_from = string.format("curve:CaiQiu_%s_%s mode:Once duration:1 startx:0 starty:0 endx:0 endy:0", toIndex, fromIndex)
	old_from:Tween_SetInfo("PositionVec3", from_to)
	old_to:Tween_SetInfo("PositionVec3", to_from)
	old_from:Tween_Play("PositionVec3", true, true)
	old_to:Tween_Play("PositionVec3", true, true)

end
function CaiQiu_OnBtnStart()
	CaiQiu_TishiText("")
	for i=1,3 do 
		tabAnimation_WuUI[i]:Play(false)
		tabAnimationUI[i]:Play(false)
		tabQiuUI[i]:Hide()
		tabJianTouUI[i]:Play(false)
		tabMaskWanUI[i]:Show()
	end
	CaiQiu_Page_Animate_XuanDui:Play(false)
	CaiQiu_Page_Animate_XuanCuo:Play(false)
	CaiQiu_Page_Animate_XuanDui_BK:Hide();
	CaiQiu_Page_Animate_XuanCuo_BK:Hide();
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnRequestResult" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 892980 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 1 );						-- 参数一:类型
		Set_XSCRIPT_Parameter( 1, 0 );						-- 参数一:类型
		Set_XSCRIPT_ParamCount( 2 );						-- 参数个数
	Send_XSCRIPT()

end

function CaiQiu_OnBtnReady()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnRequestResult" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 892980 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 2 );						-- 参数一:类型
		Set_XSCRIPT_Parameter( 1, 0 );						-- 参数一:类型
		Set_XSCRIPT_ParamCount( 2 );						-- 参数个数
	Send_XSCRIPT()
end

function CaiQiu_OnBtnContinue()
	CaiQiu_SetGuanText()
	CaiQiu_OnBtnStart()
end

function CaiQiu_OnBtnAward()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnDayFinalAward" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 892980 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, 0 );						-- 参数一:类型
		Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
	Send_XSCRIPT()
end

function CaiQiu_StartChangeWan()
	local loopNum = 0;
	g_tabLoopOpera = {}
	while(loopNum < tabLoopNum[g_CurIndex].loopNum) do
		table.insert(g_tabLoopOpera, math.random(1,g_LoopAllConNum))
		loopNum = loopNum + 1
	end
	CaiQiu_TishiText("");
	g_LoopIndex = 1;
	g_LoopMaxIndex = loopNum;
	g_LoopTime = tabLoopNum[g_CurIndex].onceTime
	KillTimer("CaiQiu_LoopChangeWan()")
	SetTimer("CaiQiu","CaiQiu_LoopChangeWan()", g_LoopTime*1000+tabLoopNum[g_CurIndex].waitTime)
	CaiQiu_LoopChangeWan()
end

function CaiQiu_LoopChangeWan()
	-- PushDebugMessage("CaiQiu_LoopChangeWan:"..g_LoopIndex)
	if g_LoopIndex == 0 then return end
	local fromIndex = 0
	local toIndex = 0
	local from_to_info;
	local nNum = 0
	local tabTempUI = {}
	for i = 1,3 do 
		tabTempUI[i] = tabMoveUI[i]
	end
	local tabOneLoop = tabLoopAllCon[g_tabLoopOpera[g_LoopIndex]] or {}
	for i, v in pairs(tabOneLoop) do 
		nNum = nNum + 1
		fromIndex = v;
		toIndex = tabOneLoop[i+1] or tabOneLoop[1];
		from_to_info = string.format("curve:CaiQiu_%s_%s mode:Once duration:%s startx:0 starty:0 endx:0 endy:0", fromIndex, toIndex, g_LoopTime)
		tabMoveUI[fromIndex]:Tween_SetInfo("PositionVec3", from_to_info)
		tabMoveUI[fromIndex]:Tween_Play("PositionVec3", true, true)
	end
	for i = 2, nNum do 
		tabMoveUI[tabOneLoop[i]] = tabTempUI[tabOneLoop[i-1]]
	end
	tabMoveUI[tabOneLoop[1]] = tabTempUI[tabOneLoop[nNum]]

	g_LoopIndex = g_LoopIndex + 1
	if g_LoopIndex > g_LoopMaxIndex then 
		CaiQiu_EndChangeWan();
	end
end

function CaiQiu_EndChangeWan()
	-- PushDebugMessage("CaiQiu_EndChangeWan:"..g_LoopIndex)
	KillTimer("CaiQiu_LoopChangeWan()")
	SetTimer("CaiQiu","CaiQiu_RealEndChangeWan()", g_LoopTime*1000)
end

function CaiQiu_RealEndChangeWan( ... )
	KillTimer("CaiQiu_RealEndChangeWan()")
	g_LoopIndex = 0
	CaiQiu_TishiText("#{KWCQ_181201_15}")
	for i, v in pairs(tabJianTouUI) do 
		v:Play(true);
	end
end

function CaiQiu_You_AnimateEnd(nIndex)
	tabQiuUI[nIndex]:Show()
	tabQiuUI[nIndex]:SetProperty("Image", "set:caiyuanbao_2 image:Wan_you8");
end

function CaiQiu_Wu_AnimateEnd(nIndex)
	tabQiuUI[nIndex]:Show()
	tabQiuUI[nIndex]:SetProperty("Image", "set:caiyuanbao_1 image:Wan_wu3");
end

function CaiQiu_XuanDui_AnimateEnd()
	CaiQiu_Page_Animate_XuanDui_BK:Show();
end

function CaiQiu_XuanCuo_AnimateEnd()
	CaiQiu_Page_Animate_XuanCuo_BK:Show();
end