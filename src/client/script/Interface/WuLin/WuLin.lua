-- 武林之巅 挑战层数选择界面

-- 保存UI默认位置
local WuLin_UnifiedPosition = nil

-- 界面控件
-- 队长选择相关
local WuLin_ctrlFrmRF1LeaderChoose = nil				-- 队长 选择层数窗口
local WuLin_ctrlTxtRF1LeaderStageRange = nil			-- 队长 可选层数范围
local WuLin_ctrlTxtRF1LeaderStageChoose = nil			-- 队长 请选择挑战层数
local WuLin_ctrlListRF1LeaderStageList = nil			-- 队长 可选择层数列表
local WuLin_ctrlBtnRF1LeaderChoose = nil				-- 队长 确定
local WuLin_ctrlBtnRF1LeaderAbandon = nil				-- 队长 放弃
-- 队长确认后相关
local WuLin_ctrlFrmRF4LeaderConfirm = nil				-- 队长 队长层数选择确认后窗口
local WuLin_ctrlTxtRF4LeaderStageRange = nil			-- 队长 可选层数范围
local WuLin_ctrlTxtRF4LeaderStage = nil					-- 队长 队长选择的挑战层数
local WuLin_ctrlTxtRF4LeaderConfirmInfo = nil			-- 队长 队伍成员确认情况
local WuLin_ctrlBtnRF4LeaderChoose = nil				-- 队长 确定
local WuLin_ctrlBtnRF4LeaderAbandon = nil				-- 队长 放弃
-- 队员等队长选择相关
local WuLin_ctrlFrmRF3MemberWait = nil					-- 队员 等待队长选择窗口
local WuLin_ctrlTxtRF3MemberStageRange = nil			-- 队员 可选层数范围
local WuLin_ctrlTxtRF3MemberStage = nil					-- 队员 队长选择的层数
local WuLin_ctrlBtnRF3MemberChoose = nil				-- 队员 确定
local WuLin_ctrlBtnRF3MemberAbandon = nil				-- 队员 放弃
-- 队员确认相关
local WuLin_ctrlFrmRF2MemberConfirm = nil				-- 队员 队员确认窗口
local WuLin_ctrlTxtRF2MemberStageRange = nil			-- 队员 可选层数范围
local WuLin_ctrlTxtRF2MemberStage = nil					-- 队员 队长选择的挑战层数
local WuLin_ctrlTxtRF2MemberConfirmInfo = nil			-- 队员 队伍成员确认情况
local WuLin_ctrlBtnRF2MemberChoose = nil				-- 队员 确定
local WuLin_ctrlBtnRF2MemberAbandon = nil				-- 队员 放弃
-- 队伍成员列表
local WuLin_ctrlWndLF = nil
local WuLin_ctrlWndLFCaptain = nil
-- 周奖励选择按钮
local WuLin_ctrlBtnWeekAward = nil
local WuLin_ctrlBtnWeekAwardNull = nil
-- 周奖励次数
local WuLin_ctrlTxtRFWeekAwardCount = nil
-- 周参与次数
local WuLin_CtrlTxtRFWeekCount = nil
-- 双倍活动提示
local WuLin_ctrlTxtDoubleTip = nil

-- 最大挑战层数
local WuLin_MaxStage = 100
-- 每周最大参与次数
local WuLin_MaxWeekCount = 20

-- 关注NPC
local WuLin_CareObjId = -1
local WuLin_CareObjSvrId = -1
local WuLin_MAX_OBJ_DISTANCE = 5.0

-- 计时器ID
local WuLin_TimerID = -1

local WuLin_HideFlag = 0
local WuLin_WeekAward_CheckState = 0

-- 门派名称表
local MenPaiName =
{
	[0] = "#{GMGameInterface_Script_DataPool_Info_ShaoLin}",
	[1] = "#{GMGameInterface_Script_DataPool_Info_Mingjiao}",
	[2] = "#{GMGameInterface_Script_DataPool_Info_GaiBang}",
	[3] = "#{GMGameInterface_Script_DataPool_Info_WuDang}",
	[4] = "#{GMGameInterface_Script_DataPool_Info_EMei}",
	[5] = "#{GMGameInterface_Script_DataPool_Info_XingXiu}",
	[6] = "#{GMGameInterface_Script_DataPool_Info_DaLi}",
	[7] = "#{GMGameInterface_Script_DataPool_Info_TianShan}",
	[8] = "#{GMGameInterface_Script_DataPool_Info_XiaoYao}",
	[9] = "#{GMGameInterface_Script_DataPool_Info_WuMenPai}",
	[10] = "#{GMGameInterface_Script_DataPool_Info_GuSu}",
	[11] = "#{XMPTM_130123_02}",
	[12] = "#{XMPGG_160524_02}", 
	[13] = "#{XQ_MP_15}",
	[14] = "#{XMPHM_210604_01}",
	[15] = "#{GMGameInterface_Script_DataPool_Info_ERenGu}",--menpai15 mptodo
} -- end MenPaiName

--多倍历练时间
local g_DuoBeiLiLian_StartTime = 20260813
local g_DuoBeiLiLian_EndTime = 20260912

local g_DuoBeiLiLian_TimeList = {
	[1] = {BeginTime=20260817, tips="#{DBLL_200628_37}"},
	[2] = {BeginTime=20260824, tips="#{DBLL_200628_61}"},
	[3] = {BeginTime=20260831, tips="#{DBLL_200628_62}"},
	[4] = {BeginTime=20260907, tips="#{DBLL_200628_63}"},
	--[5] = {BeginTime=20201207, tips="#{DBLL_200628_69}"},
}

function WuLin_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("WLZD_OPEN_CHOOSESTAGE", true)
	this:RegisterEvent("WLZD_OPEN_CONFIRMSTAGE", true)
	this:RegisterEvent("WLZD_CLOSE_ALL", true)
	this:RegisterEvent("TEAM_MEMBER_LEAVE", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("WLZD_MEMBERCONFIRM", true)
	this:RegisterEvent("WLZD_LEADERABORT", true)
	this:RegisterEvent("WLZD_MEMBERABORT", true)
	this:RegisterEvent("WLZD_CONFIRMCOUNT", true)
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func WuLin_PreLoad()

function WuLin_OnLoad()
	WuLin_InitCtrl()

	WuLin_HideFlag = 0
	WuLin_WeekAward_CheckState = 0
	WuLin_UnifiedPosition = WuLin_Frame:GetProperty("UnifiedPosition")
end -- end func WuLin_OnLoad()

function WuLin_OnEvent(event)
	if (event == "WLZD_OPEN_CHOOSESTAGE") then
		WuLin_BeginCareObject(arg0, arg1)
		WuLin_Show()
		WuLin_Show_TeamMemberList()
		if (WuLin_ctrlBtnWeekAward ~= nil) then
			if (WuLin_ctrlBtnWeekAward:IsVisible()) then
				--if (WuLin_WeekAward_CheckState == 1) then
				local awardCount = WuLinZhiDian:GetAvalibleAwardCount()
				if (awardCount >= 1) then
					WuLin_ctrlBtnWeekAward:SetCheck(1)
					WuLin_WeekAward_CheckState = 1
				else
					WuLin_ctrlBtnWeekAward:SetCheck(0)
					WuLin_WeekAward_CheckState = 0
				end
				WuLin_WeekAward_Clicked()
			end
		end
		-- 检查是否队长 只有队长才打开挑战层数选择界面
		if (WuLinZhiDian:IsTeamLeader() == 1) then
			WuLin_Show_LeaderChoose()
		else
			WuLin_Show_MemberWait()
		end
	elseif (event == "WLZD_OPEN_CONFIRMSTAGE") then
		WuLin_Show()
		local isLeader = WuLinZhiDian:IsTeamLeader()
		-- 检查是否队长 
		if (isLeader == 1) then
			-- 队长 把界面刷能队长第二阶段的界面
			WuLin_Show_LeaderConfirmed()
		elseif (isLeader == 0) then
			-- 队员 把界面刷成队员确认界面
			WuLin_Show_MemberConfirm()
		else
			-- 这里应该是队伍信息没同步下来 按说不应该
		end
	elseif (event == "WLZD_CLOSE_ALL") then
		WuLin_Hide()
		--SetTimer("WuLin", "WuLin_Hide()", 500)
	elseif (event == "TEAM_MEMBER_LEAVE") then
		WuLin_Hide()
	elseif (event == "WLZD_MEMBERCONFIRM") then
		WuLin_TeamMemberConfirm(arg0, arg1)
	elseif (event == "WLZD_LEADERABORT") then
		WuLin_TeamMemberAbort(arg0, arg1)
	elseif (event == "WLZD_MEMBERABORT") then
		WuLin_TeamMemberAbort(arg0, arg1)
	elseif (event == "WLZD_CONFIRMCOUNT") then
		--WuLin_UpdateConfirmCount(arg0, arg1)
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		WuLin_Hide()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= WuLin_CareObjId) then
			return;
		end

		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if((arg1 == "distance" and tonumber(arg2)>WuLin_MAX_OBJ_DISTANCE) or arg1=="destroy") then
			--取消关心
			WuLin_Hide()
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		WuLin_UnifiedPos()
	end
end -- end func WuLin_OnEvent()

-- 界面默认位置
function WuLin_UnifiedPos()
	if (WuLin_UnifiedPosition ~= nil) then
		WuLin_Frame:SetProperty("UnifiedPosition", WuLin_UnifiedPosition)
	end
end -- end func WuLin_UnifiedPos()

-- 初始化界面UI控件 定义控件变量、添加按钮事件等
function WuLin_InitCtrl()
	-- 队伍成员列表
	WuLin_InitTeamInfoCtrl()

	-- 队长选择相关
	WuLin_ctrlFrmRF1LeaderChoose = WuLin_Right_Info1
	WuLin_ctrlTxtRF1LeaderStageRange = WuLin_Right_Info1Text1
	WuLin_ctrlListRF1LeaderStageList = WuLin_Right_Info1_Choice
	WuLin_ctrlBtnRF1LeaderChoose = WuLin_Right_Info1_Choose
	WuLin_ctrlBtnRF1LeaderAbandon = WuLin_Right_Info1_Waive
	-- 确定按钮
	if (WuLin_ctrlBtnRF1LeaderChoose ~= nil) then
		WuLin_ctrlBtnRF1LeaderChoose:SetEvent("Clicked", "WuLin_Leader_OnChooseStageConfirm()")
	end
	-- 放弃
	if (WuLin_ctrlBtnRF1LeaderAbandon ~= nil) then
		WuLin_ctrlBtnRF1LeaderAbandon:SetEvent("Clicked", "WuLin_Leader_OnAbandon()")
	end

	-- 队长确认后相关
	WuLin_ctrlFrmRF4LeaderConfirm = WuLin_Right_Info4
	WuLin_ctrlTxtRF4LeaderStageRange = WuLin_Right_Info4Text1
	WuLin_ctrlTxtRF4LeaderStage = WuLin_Right_Info4Text3
	WuLin_ctrlTxtRF4LeaderConfirmInfo = WuLin_Right_Info4Text4
	WuLin_ctrlBtnRF4LeaderChoose = WuLin_Right_Info4_Choose
	WuLin_ctrlBtnRF4LeaderAbandon = WuLin_Right_Info4_Waive
	-- 这里逻辑上不需要确定按钮事件
	-- 放弃按钮
	if (WuLin_ctrlBtnRF4LeaderAbandon ~= nil) then
		WuLin_ctrlBtnRF4LeaderAbandon:SetEvent("Clicked", "WuLin_Leader_OnAbandon()")
	end

	-- 队员等队长选择相关
	WuLin_ctrlFrmRF3MemberWait = WuLin_Right_Info3
	WuLin_ctrlTxtRF3MemberStageRange = WuLin_Right_Info3Text1
	WuLin_ctrlTxtRF3MemberStage = WuLin_Right_Info3Text3
	WuLin_ctrlBtnRF3MemberChoose = WuLin_Right_Info3_Choose
	WuLin_ctrlBtnRF3MemberAbandon = WuLin_Right_Info3_Waive
	-- 这里按说不应该有按钮事件 队长还没选队员就放弃后续会有问题 暂时不加事件了
	-- 策划说这个地方可以放弃 把放弃事件加回来吧
	WuLin_ctrlBtnRF3MemberAbandon:SetEvent("Clicked", "WuLin_Member_OnAbandon()")

	-- 队员确认相关
	WuLin_ctrlFrmRF2MemberConfirm = WuLin_Right_Info2
	WuLin_ctrlTxtRF2MemberStageRange = WuLin_Right_Info2Text2
	WuLin_ctrlTxtRF2MemberStage = WuLin_Right_Info2Text4
	WuLin_ctrlTxtRF2MemberConfirmInfo = WuLin_Right_Info2Text5
	WuLin_ctrlBtnRF2MemberChoose = WuLin_Right_Info2_Choose
	WuLin_ctrlBtnRF2MemberAbandon = WuLin_Right_Info2_Waive
	-- 确认按钮
	if (WuLin_ctrlBtnRF2MemberChoose ~= nil) then
		WuLin_ctrlBtnRF2MemberChoose:SetEvent("Clicked", "WuLin_Member_OnChooseStageConfirm()")
	end
	-- 放弃按钮
	if (WuLin_ctrlBtnRF2MemberAbandon ~= nil) then
		WuLin_ctrlBtnRF2MemberAbandon:SetEvent("Clicked", "WuLin_Member_OnAbandon()")
	end

	-- 周奖励
	WuLin_ctrlBtnWeekAward = WuLin_Right_Mode
	WuLin_ctrlBtnWeekAwardNull = WuLin_Right_ModeNull
	WuLin_ctrlTxtRFWeekAwardCount = WuLin_Right_Text

	WuLin_CtrlTxtRFWeekCount = WuLin_Right_Text2

	-- 双倍奖励
	WuLin_ctrlTxtDoubleTip = WuLin_Right_Text1
end -- end func WuLin_InitCtrl()

-- 初始化队伍成员列表控件
function WuLin_InitTeamInfoCtrl()
	-- 队伍成员列表
	WuLin_ctrlWndLFCaptain = WuLin_Player1_Captain
	WuLin_ctrlWndLF = {}
	WuLin_ctrlWndLF[1] = {}
	WuLin_ctrlWndLF[1].frame = WuLin_Player1ClientBK
	WuLin_ctrlWndLF[1].headbk = WuLin_Player1HeadBK
	WuLin_ctrlWndLF[1].head = WuLin_Player1Head
	WuLin_ctrlWndLF[1].namebk = WuLin_Player1NameBK
	WuLin_ctrlWndLF[1].name = WuLin_Player1Name
	WuLin_ctrlWndLF[1].menpaibk = WuLin_Player1MenPaiBK
	WuLin_ctrlWndLF[1].menpai = WuLin_Player1MenPai
	WuLin_ctrlWndLF[1].stagebk = WuLin_Player1NumBK
	WuLin_ctrlWndLF[1].stage = WuLin_Player1Num
	WuLin_ctrlWndLF[1].confirm = WuLin_Player1_Choose
	WuLin_ctrlWndLF[1].clientdis = nil
	WuLin_ctrlWndLF[2] = {}
	WuLin_ctrlWndLF[2].frame = WuLin_Player2ClientBK
	WuLin_ctrlWndLF[2].headbk = WuLin_Player2HeadBK
	WuLin_ctrlWndLF[2].head = WuLin_Player2Head
	WuLin_ctrlWndLF[2].namebk = WuLin_Player2NameBK
	WuLin_ctrlWndLF[2].name = WuLin_Player2Name
	WuLin_ctrlWndLF[2].menpaibk = WuLin_Player2MenPaiBK
	WuLin_ctrlWndLF[2].menpai = WuLin_Player2MenPai
	WuLin_ctrlWndLF[2].stagebk = WuLin_Player2NumBK
	WuLin_ctrlWndLF[2].stage = WuLin_Player2Num
	WuLin_ctrlWndLF[2].confirm = WuLin_Player2_Choose
	WuLin_ctrlWndLF[2].clientdis = nil
	WuLin_ctrlWndLF[3] = {}
	WuLin_ctrlWndLF[3].frame = WuLin_Player3ClientBK
	WuLin_ctrlWndLF[3].headbk = WuLin_Player3HeadBK
	WuLin_ctrlWndLF[3].head = WuLin_Player3Head
	WuLin_ctrlWndLF[3].namebk = WuLin_Player3NameBK
	WuLin_ctrlWndLF[3].name = WuLin_Player3Name
	WuLin_ctrlWndLF[3].menpaibk = WuLin_Player3MenPaiBK
	WuLin_ctrlWndLF[3].menpai = WuLin_Player3MenPai
	WuLin_ctrlWndLF[3].stagebk = WuLin_Player3NumBK
	WuLin_ctrlWndLF[3].stage = WuLin_Player3Num
	WuLin_ctrlWndLF[3].confirm = WuLin_Player3_Choose
	WuLin_ctrlWndLF[3].clientdis = nil
	WuLin_ctrlWndLF[4] = {}
	WuLin_ctrlWndLF[4].frame = WuLin_Player4ClientBK
	WuLin_ctrlWndLF[4].headbk = WuLin_Player4HeadBK
	WuLin_ctrlWndLF[4].head = WuLin_Player4Head
	WuLin_ctrlWndLF[4].namebk = WuLin_Player4NameBK
	WuLin_ctrlWndLF[4].name = WuLin_Player4Name
	WuLin_ctrlWndLF[4].menpaibk = WuLin_Player4MenPaiBK
	WuLin_ctrlWndLF[4].menpai = WuLin_Player4MenPai
	WuLin_ctrlWndLF[4].stagebk = WuLin_Player4NumBK
	WuLin_ctrlWndLF[4].stage = WuLin_Player4Num
	WuLin_ctrlWndLF[4].confirm = WuLin_Player4_Choose
	WuLin_ctrlWndLF[4].clientdis = WuLin_Player4ClientDis
	WuLin_ctrlWndLF[5] = {}
	WuLin_ctrlWndLF[5].frame = WuLin_Player5ClientBK
	WuLin_ctrlWndLF[5].headbk = WuLin_Player5HeadBK
	WuLin_ctrlWndLF[5].head = WuLin_Player5Head
	WuLin_ctrlWndLF[5].namebk = WuLin_Player5NameBK
	WuLin_ctrlWndLF[5].name = WuLin_Player5Name
	WuLin_ctrlWndLF[5].menpaibk = WuLin_Player5MenPaiBK
	WuLin_ctrlWndLF[5].menpai = WuLin_Player5MenPai
	WuLin_ctrlWndLF[5].stagebk = WuLin_Player5NumBK
	WuLin_ctrlWndLF[5].stage = WuLin_Player5Num
	WuLin_ctrlWndLF[5].confirm = WuLin_Player5_Choose
	WuLin_ctrlWndLF[5].clientdis = WuLin_Player5ClientDis
	WuLin_ctrlWndLF[6] = {}
	WuLin_ctrlWndLF[6].frame = WuLin_Player6ClientBK
	WuLin_ctrlWndLF[6].headbk = WuLin_Player6HeadBK
	WuLin_ctrlWndLF[6].head = WuLin_Player6Head
	WuLin_ctrlWndLF[6].namebk = WuLin_Player6NameBK
	WuLin_ctrlWndLF[6].name = WuLin_Player6Name
	WuLin_ctrlWndLF[6].menpaibk = WuLin_Player6MenPaiBK
	WuLin_ctrlWndLF[6].menpai = WuLin_Player6MenPai
	WuLin_ctrlWndLF[6].stagebk = WuLin_Player6NumBK
	WuLin_ctrlWndLF[6].stage = WuLin_Player6Num
	WuLin_ctrlWndLF[6].confirm = WuLin_Player6_Choose
	WuLin_ctrlWndLF[6].clientdis = WuLin_Player6ClientDis
end -- end func WuLin_InitTeamInfoCtrl()

function WuLin_OnHidden()
	if (WuLin_HideFlag == 0) then
		if (WuLinZhiDian:IsTeamLeader() == 1) then
			-- 队长
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("LeaderAbort")
				Set_XSCRIPT_ScriptID(893398)
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()
		else
			-- 队员
			if (WuLin_ctrlBtnRF2MemberChoose ~= nil) then
				WuLin_ctrlBtnRF2MemberChoose:Disable()
			end
			if (WuLin_ctrlBtnRF2MemberAbandon ~= nil) then
				WuLin_ctrlBtnRF2MemberAbandon:Disable()
			end
		
			Clear_XSCRIPT()
				Set_XSCRIPT_Function_Name("MemberAbort")
				Set_XSCRIPT_ScriptID(893398)
				Set_XSCRIPT_ParamCount(0)
			Send_XSCRIPT()
		end
	end

	if (WuLin_TimerID >= 0) then
		KillTimer(WuLin_TimerID)
		WuLin_TimerID = -1
	end
end -- end func WuLin_OnHidden()

-- 打开界面
function WuLin_Show()
	WuLin_HideFlag = 0
	if (WuLin_TimerID >= 0) then
		KillTimer(WuLin_TimerID)
		WuLin_TimerID = -1
	end
	KillTimer("WuLin_Hide()")
	this:Show()
	if (WuLinZhiDian:IsDoubleAwardTime() > 0) then
		-- 双倍活动期间
		WuLin_ctrlTxtDoubleTip:Show()
	else
		WuLin_ctrlTxtDoubleTip:Hide()
	end
	--多倍历练
	local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay >= g_DuoBeiLiLian_StartTime and curDay <= g_DuoBeiLiLian_EndTime then
		local tips = ""
		for i = 1, table.getn(g_DuoBeiLiLian_TimeList) do
			if curDay >= g_DuoBeiLiLian_TimeList[i].BeginTime then
				tips = g_DuoBeiLiLian_TimeList[i].tips
			end
		end
		WuLin_ctrlTxtDoubleTip:Show()
		WuLin_ctrlTxtDoubleTip:SetText(tips)
	else
		WuLin_ctrlTxtDoubleTip:Hide()
	end
	if (WuLin_ctrlTxtRFWeekAwardCount ~= nil) then
		local awardCount = WuLinZhiDian:GetAvalibleAwardCount()
		if (awardCount <= 0) then
			awardCount = 0
			if (WuLin_ctrlBtnWeekAward ~= nil) then
				if (WuLin_ctrlBtnWeekAward:IsVisible()) then
					WuLin_WeekAward_CheckState = 0
					WuLin_ctrlBtnWeekAward:SetCheck(0)
					WuLin_WeekAward_Clicked()
					WuLin_ctrlBtnWeekAward:Hide()
				end
			end
			if (WuLin_ctrlBtnWeekAwardNull ~= nil) then
				WuLin_ctrlBtnWeekAwardNull:Show()
			end

			local text = ScriptGlobal_Format("#{PTFB_191228_443}", awardCount)
			WuLin_ctrlTxtRFWeekAwardCount:SetText(text)
		else
			if (WuLin_ctrlBtnWeekAward ~= nil) then
				WuLin_ctrlBtnWeekAward:Show()
			end
			if (WuLin_ctrlBtnWeekAwardNull ~= nil) then
				WuLin_ctrlBtnWeekAwardNull:Hide()
			end

			local text = ScriptGlobal_Format("#{PTFB_191228_229}", awardCount)
			WuLin_ctrlTxtRFWeekAwardCount:SetText(text)
		end
	end

	-- 优化需求 挑战次数被去掉了
	-- if (WuLin_CtrlTxtRFWeekCount ~= nil) then
	-- 	local weekCount = WuLinZhiDian:GetCurWeekCount()
	-- 	local leftCount = WuLin_MaxWeekCount - weekCount
	-- 	if (leftCount < 0) then
	-- 		leftCount = 0
	-- 	end
	-- 	local text = ScriptGlobal_Format("#{PTFB_191228_201}", leftCount, WuLin_MaxWeekCount)
	-- 	WuLin_CtrlTxtRFWeekCount:SetText(text)
	-- end
end -- end WuLin_Show()

-- 关闭界面
function WuLin_Hide()
	WuLin_HideFlag = 1
	if (WuLin_TimerID >= 0) then
		KillTimer(WuLin_TimerID)
		WuLin_TimerID = -1
	end
	WuLin_StopCareObject(WuLin_CareObjId)
	CloseMessageBoxCommon()
	this:Hide()
end -- end func WuLin_Hide()

-- 设置队员信息
function WuLin_Show_TeamMemberList()
	-- 设置队员信息
	if (WuLin_ctrlWndLF ~= nil) then
		for i = 1, 6, 1 do
			local ret, head, stage, menpai, leaderflag, name = WuLinZhiDian:GetTeamMemberInfo(i-1)
			if (tonumber(ret) > 0) then
				if (WuLin_ctrlWndLF[i] ~= nil) then
					if (tonumber(stage) >= 0) then
						WuLin_ctrlWndLF[i].frame:Show()
						WuLin_ctrlWndLF[i].headbk:Show()
						WuLin_ctrlWndLF[i].namebk:Show()
						WuLin_ctrlWndLF[i].menpaibk:Show()
						WuLin_ctrlWndLF[i].stagebk:Show()
						WuLin_ctrlWndLF[i].head:Show()
						WuLin_ctrlWndLF[i].name:Show()
						WuLin_ctrlWndLF[i].menpai:Show()
						WuLin_ctrlWndLF[i].stage:Show()
						WuLin_ctrlWndLF[i].confirm:Show()
						if (WuLin_ctrlWndLF[i].clientdis ~= nil) then
							WuLin_ctrlWndLF[i].clientdis:Hide()
						end

						WuLin_ctrlWndLF[i].head:SetProperty("Image", head)
						WuLin_ctrlWndLF[i].name:SetText("#L" .. name)
						if (MenPaiName[tonumber(menpai)] ~= nil) then
							WuLin_ctrlWndLF[i].menpai:SetText("#L" .. MenPaiName[tonumber(menpai)])
						else
							--WuLin_ctrlWndLF[i].menpai:SetText(MenPaiName[9])
						end
						local stageText = ScriptGlobal_Format("#{PTFB_191228_252}", stage)
						WuLin_ctrlWndLF[i].stage:SetText(stageText)
						-- if (WuLinZhiDian:IsTeamLeader() == 1) then
						-- 	if (leaderflag == 1) then
						-- 		WuLin_ctrlWndLF[i].confirm:SetProperty("Image", "set:GuanShanHai13 image:dengdai")
						-- 	else
						-- 		WuLin_ctrlWndLF[i].confirm:SetProperty("Image", "")
						-- 	end
						-- else
						-- 	--WuLin_ctrlWndLF[i].confirm:SetProperty("Image", "set:GuanShanHai13 image:dengdai")
						-- 	WuLin_ctrlWndLF[i].confirm:SetProperty("Image", "")
						-- end
						if (leaderflag == 1) then
							WuLin_ctrlWndLF[i].confirm:SetProperty("Image", "set:GuanShanHai13 image:dengdai")
						else
							WuLin_ctrlWndLF[i].confirm:SetProperty("Image", "")
						end
					else
						--WuLin_ctrlWndLF[i].frame:Hide()
						WuLin_ctrlWndLF[i].headbk:Hide()
						WuLin_ctrlWndLF[i].namebk:Hide()
						WuLin_ctrlWndLF[i].menpaibk:Hide()
						WuLin_ctrlWndLF[i].stagebk:Hide()
						WuLin_ctrlWndLF[i].head:Hide()
						WuLin_ctrlWndLF[i].name:Hide()
						WuLin_ctrlWndLF[i].menpai:Hide()
						WuLin_ctrlWndLF[i].stage:Hide()
						WuLin_ctrlWndLF[i].confirm:Hide()
						if (WuLin_ctrlWndLF[i].clientdis ~= nil) then
							WuLin_ctrlWndLF[i].clientdis:Show()
						end
					end
				end
			else
				if (WuLin_ctrlWndLF[i] ~= nil) then
					--WuLin_ctrlWndLF[i].frame:Hide()
					WuLin_ctrlWndLF[i].headbk:Hide()
					WuLin_ctrlWndLF[i].namebk:Hide()
					WuLin_ctrlWndLF[i].menpaibk:Hide()
					WuLin_ctrlWndLF[i].stagebk:Hide()
					WuLin_ctrlWndLF[i].head:Hide()
					WuLin_ctrlWndLF[i].name:Hide()
					WuLin_ctrlWndLF[i].menpai:Hide()
					WuLin_ctrlWndLF[i].stage:Hide()
					WuLin_ctrlWndLF[i].confirm:Hide()
					if (WuLin_ctrlWndLF[i].clientdis ~= nil) then
						WuLin_ctrlWndLF[i].clientdis:Show()
					end
				end
			end
		end -- end for
	end
end -- end func WuLin_Show_TeamMemberList()

-- 开启队长选择界面
function WuLin_Show_LeaderChoose()
	WuLin_Hide_LeaderConfirmed()
	WuLin_Hide_MemberWait()
	WuLin_Hide_MemberConfirm()

	if (WuLin_ctrlFrmRF1LeaderChoose ~= nil) then
		WuLin_ctrlFrmRF1LeaderChoose:Show()
	end
	if (WuLin_ctrlTxtRF1LeaderStageRange ~= nil) then
		WuLin_ctrlTxtRF1LeaderStageRange:Show()
	end
	if (WuLin_ctrlListRF1LeaderStageList ~= nil) then
		WuLin_ctrlListRF1LeaderStageList:Show()
	end
	if (WuLin_ctrlBtnRF1LeaderChoose ~= nil) then
		WuLin_ctrlBtnRF1LeaderChoose:Show()
		WuLin_ctrlBtnRF1LeaderChoose:Enable()
	end
	if (WuLin_ctrlBtnRF1LeaderAbandon ~= nil) then
		WuLin_ctrlBtnRF1LeaderAbandon:Show()
		WuLin_ctrlBtnRF1LeaderAbandon:Enable()
	end

	-- 获取队伍玩家平均层数
	local maxStage = 1
	local avgStage = tonumber(WuLinZhiDian:GetAverageStage())
	if (avgStage >= 0) then
		maxStage = avgStage + 1
	end
	if (maxStage > WuLin_MaxStage) then
		maxStage = WuLin_MaxStage
	end

	-- 可选择曾是范围提示
	local stageRangeTip = ""
	if (maxStage > 1) then
		stageRangeTip = ScriptGlobal_Format("#{PTFB_191228_39}", maxStage)
	else
		stageRangeTip = "#{PTFB_191228_63}"
	end
	if (WuLin_ctrlTxtRF1LeaderStageRange ~= nil) then
		WuLin_ctrlTxtRF1LeaderStageRange:SetText(stageRangeTip)
	end

	-- 设置可选择层数
	if (WuLin_ctrlListRF1LeaderStageList ~= nil) then
		WuLin_ctrlListRF1LeaderStageList:ResetList()
		for i = 1, maxStage, 1 do
			WuLin_ctrlListRF1LeaderStageList:AddTextItem(tostring(i), i-1)
		end -- end for
		WuLin_ctrlListRF1LeaderStageList:SetCurrentSelect(maxStage-1)
	end
end -- end func WuLin_Show_LeaderChoose()

-- 关闭队长选择界面
function WuLin_Hide_LeaderChoose()
	if (WuLin_ctrlFrmRF1LeaderChoose ~= nil) then
		WuLin_ctrlFrmRF1LeaderChoose:Hide()
	end
	if (WuLin_ctrlTxtRF1LeaderStageRange ~= nil) then
		WuLin_ctrlTxtRF1LeaderStageRange:Hide()
	end
	if (WuLin_ctrlListRF1LeaderStageList ~= nil) then
		WuLin_ctrlListRF1LeaderStageList:Hide()
	end
	if (WuLin_ctrlBtnRF1LeaderChoose ~= nil) then
		WuLin_ctrlBtnRF1LeaderChoose:Hide()
	end
	if (WuLin_ctrlBtnRF1LeaderAbandon ~= nil) then
		WuLin_ctrlBtnRF1LeaderAbandon:Hide()
	end
end -- end func WuLin_Hide_LeaderChoose()

-- 开启队长确认后界面
function WuLin_Show_LeaderConfirmed()
	WuLin_Hide_LeaderChoose()
	WuLin_Hide_MemberWait()
	WuLin_Hide_MemberConfirm()

	-- 设置队员确认信息
	if (WuLin_ctrlWndLF ~= nil) then
		for i = 1, 6, 1 do
			local ret, head, stage, menpai, leaderflag, name = WuLinZhiDian:GetTeamMemberInfo(i-1)
			if (ret > 0) then
				if (WuLin_ctrlWndLF[i] ~= nil) then
					if (stage >= 0) then
						if (tonumber(leaderflag) < 1) then
							WuLin_ctrlWndLF[i].confirm:SetProperty("Image", "set:GuanShanHai13 image:dengdai")
						end
					end
				end
			end
		end -- end for
	end

	if (WuLin_ctrlFrmRF4LeaderConfirm ~= nil) then
		WuLin_ctrlFrmRF4LeaderConfirm:Show()
	end
	if (WuLin_ctrlTxtRF4LeaderStageRange ~= nil) then
		WuLin_ctrlTxtRF4LeaderStageRange:Show()
	end
	if (WuLin_ctrlTxtRF4LeaderStage ~= nil) then
		WuLin_ctrlTxtRF4LeaderStage:Show()
	end
	if (WuLin_ctrlTxtRF4LeaderConfirmInfo ~= nil) then
		WuLin_ctrlTxtRF4LeaderConfirmInfo:Show()
	end
	if (WuLin_ctrlBtnRF4LeaderChoose ~= nil) then
		WuLin_ctrlBtnRF4LeaderChoose:Show()
		WuLin_ctrlBtnRF4LeaderChoose:Disable()
	end
	if (WuLin_ctrlBtnRF4LeaderAbandon ~= nil) then
		WuLin_ctrlBtnRF4LeaderAbandon:Show()
		WuLin_ctrlBtnRF4LeaderAbandon:Enable()
	end

	-- 获取队伍玩家平均层数
	local maxStage = 1
	local avgStage = tonumber(WuLinZhiDian:GetAverageStage())
	if (avgStage >= 0) then
		maxStage = avgStage + 1
	end
	if (maxStage > WuLin_MaxStage) then
		maxStage = WuLin_MaxStage
	end

	-- 设置层数选择范围提示
	local stageRangeTip = ""
	if (maxStage > 1) then
		stageRangeTip = ScriptGlobal_Format("#{PTFB_191228_39}", maxStage)
	else
		stageRangeTip = "#{PTFB_191228_63}"
	end
	if (WuLin_ctrlTxtRF4LeaderStageRange ~= nil) then
		WuLin_ctrlTxtRF4LeaderStageRange:SetText(stageRangeTip)
	end

	-- 获取队长选择的层数
	local choseStage = tonumber(WuLinZhiDian:GetChooseStage())
	local choseStageTip = ScriptGlobal_Format("#{PTFB_191228_58}", choseStage)
	-- 设置队长选择层数提示
	if (WuLin_ctrlTxtRF4LeaderStage ~= nil) then
		WuLin_ctrlTxtRF4LeaderStage:SetText(choseStageTip)
	end
end -- end func WuLin_Show_LeaderConfirmed()

-- 关闭队长确认后界面
function WuLin_Hide_LeaderConfirmed()
	if (WuLin_ctrlFrmRF4LeaderConfirm ~= nil) then
		WuLin_ctrlFrmRF4LeaderConfirm:Hide()
	end
	if (WuLin_ctrlTxtRF4LeaderStageRange ~= nil) then
		WuLin_ctrlTxtRF4LeaderStageRange:Hide()
	end
	if (WuLin_ctrlTxtRF4LeaderStage ~= nil) then
		WuLin_ctrlTxtRF4LeaderStage:Hide()
	end
	if (WuLin_ctrlTxtRF4LeaderConfirmInfo ~= nil) then
		WuLin_ctrlTxtRF4LeaderConfirmInfo:Hide()
	end
	if (WuLin_ctrlBtnRF4LeaderChoose ~= nil) then
		WuLin_ctrlBtnRF4LeaderChoose:Hide()
	end
	if (WuLin_ctrlBtnRF4LeaderAbandon ~= nil) then
		WuLin_ctrlBtnRF4LeaderAbandon:Hide()
	end
end -- end func WuLin_Hide_LeaderConfirmed()

-- 开启队员等待队长选择界面
function WuLin_Show_MemberWait()
	WuLin_Hide_LeaderChoose()
	WuLin_Hide_LeaderConfirmed()
	WuLin_Hide_MemberConfirm()

	if (WuLin_ctrlFrmRF3MemberWait ~= nil) then
		WuLin_ctrlFrmRF3MemberWait:Show()
	end
	if (WuLin_ctrlTxtRF3MemberStageRange ~= nil) then
		WuLin_ctrlTxtRF3MemberStageRange:Show()
	end
	if (WuLin_ctrlTxtRF3MemberStage ~= nil) then
		WuLin_ctrlTxtRF3MemberStage:Show()
	end
	if (WuLin_ctrlBtnRF3MemberChoose ~= nil) then
		WuLin_ctrlBtnRF3MemberChoose:Show()
		WuLin_ctrlBtnRF3MemberChoose:Disable()
	end
	if (WuLin_ctrlBtnRF3MemberAbandon ~= nil) then
		WuLin_ctrlBtnRF3MemberAbandon:Show()
		WuLin_ctrlBtnRF3MemberAbandon:Enable()
	end

	-- 获取队伍玩家平均层数
	local maxStage = 1
	local avgStage = tonumber(WuLinZhiDian:GetAverageStage())
	if (avgStage >= 0) then
		maxStage = avgStage + 1
	end
	if (maxStage > WuLin_MaxStage) then
		maxStage = WuLin_MaxStage
	end

	-- 可选择曾是范围提示
	local stageRangeTip = ""
	if (maxStage > 1) then
		stageRangeTip = ScriptGlobal_Format("#{PTFB_191228_39}", maxStage)
	else
		stageRangeTip = "#{PTFB_191228_63}"
	end
	if (WuLin_ctrlTxtRF3MemberStageRange ~= nil) then
		WuLin_ctrlTxtRF3MemberStageRange:SetText(stageRangeTip)
	end

	-- 设置队长选择的层数
	if (WuLin_ctrlTxtRF3MemberStage ~= nil) then
		WuLin_ctrlTxtRF3MemberStage:SetText("#{PTFB_191228_208}")
	end
end -- end func WuLin_Show_MemberWait()

-- 关闭队员等待队长选择界面
function WuLin_Hide_MemberWait()
	if (WuLin_ctrlFrmRF3MemberWait ~= nil) then
		WuLin_ctrlFrmRF3MemberWait:Hide()
	end
	if (WuLin_ctrlTxtRF3MemberStageRange ~= nil) then
		WuLin_ctrlTxtRF3MemberStageRange:Hide()
	end
	if (WuLin_ctrlTxtRF3MemberStage ~= nil) then
		WuLin_ctrlTxtRF3MemberStage:Hide()
	end
	if (WuLin_ctrlBtnRF3MemberChoose ~= nil) then
		WuLin_ctrlBtnRF3MemberChoose:Hide()
	end
	if (WuLin_ctrlBtnRF3MemberAbandon ~= nil) then
		WuLin_ctrlBtnRF3MemberAbandon:Hide()
	end
end -- end func WuLin_Hide_MemberWait()

-- 开启队员确认界面
function WuLin_Show_MemberConfirm()
	WuLin_Hide_LeaderChoose()
	WuLin_Hide_LeaderConfirmed()
	WuLin_Hide_MemberWait()

	-- 设置队员确认信息
	if (WuLin_ctrlWndLF ~= nil) then
		for i = 1, 6, 1 do
			local ret, head, stage, menpai, leaderflag, name = WuLinZhiDian:GetTeamMemberInfo(i-1)
			if (ret > 0) then
				if (WuLin_ctrlWndLF[i] ~= nil) then
					if (stage >= 0) then
						if (tonumber(leaderflag) < 1) then
							WuLin_ctrlWndLF[i].confirm:SetProperty("Image", "set:GuanShanHai13 image:dengdai")
						end
					end
				end
			end
		end -- end for
	end

	if (WuLin_ctrlFrmRF2MemberConfirm ~= nil) then
		WuLin_ctrlFrmRF2MemberConfirm:Show()
	end
	if (WuLin_ctrlTxtRF2MemberStageRange ~= nil) then
		WuLin_ctrlTxtRF2MemberStageRange:Show()
	end
	if (WuLin_ctrlTxtRF2MemberStage ~= nil) then
		WuLin_ctrlTxtRF2MemberStage:Show()
	end
	-- if (WuLin_ctrlTxtRF2MemberConfirmInfo ~= nil) then
	-- 	WuLin_ctrlTxtRF2MemberConfirmInfo:Show()
	-- end
	if (WuLin_ctrlBtnRF2MemberChoose ~= nil) then
		WuLin_ctrlBtnRF2MemberChoose:Show()
		WuLin_ctrlBtnRF2MemberChoose:Enable()
	end
	if (WuLin_ctrlBtnRF2MemberAbandon ~= nil) then
		WuLin_ctrlBtnRF2MemberAbandon:Show()
		WuLin_ctrlBtnRF2MemberAbandon:Enable()
	end

	-- 获取队伍玩家平均层数
	local maxStage = 1
	local avgStage = tonumber(WuLinZhiDian:GetAverageStage())
	if (avgStage >= 0) then
		maxStage = avgStage + 1
	end
	if (maxStage > WuLin_MaxStage) then
		maxStage = WuLin_MaxStage
	end

	-- 设置层数选择范围提示
	local stageRangeTip = ""
	if (maxStage > 1) then
		stageRangeTip = ScriptGlobal_Format("#{PTFB_191228_39}", maxStage)
	else
		stageRangeTip = "#{PTFB_191228_63}"
	end
	if (WuLin_ctrlTxtRF2MemberStageRange ~= nil) then
		WuLin_ctrlTxtRF2MemberStageRange:SetText(stageRangeTip)
	end

	-- 获取队长选择的层数
	local choseStage = tonumber(WuLinZhiDian:GetChooseStage())
	local choseStageTip = ScriptGlobal_Format("#{PTFB_191228_58}", choseStage)
	-- 设置队长选择层数提示
	if (WuLin_ctrlTxtRF2MemberStage ~= nil) then
		WuLin_ctrlTxtRF2MemberStage:SetText(choseStageTip)
	end
end -- end func WuLin_Show_MemberConfirm()

-- 关闭队员确认界面
function WuLin_Hide_MemberConfirm()
	if (WuLin_ctrlFrmRF2MemberConfirm ~= nil) then
		WuLin_ctrlFrmRF2MemberConfirm:Hide()
	end
	if (WuLin_ctrlTxtRF2MemberStageRange ~= nil) then
		WuLin_ctrlTxtRF2MemberStageRange:Hide()
	end
	if (WuLin_ctrlTxtRF2MemberStage ~= nil) then
		WuLin_ctrlTxtRF2MemberStage:Hide()
	end
	if (WuLin_ctrlTxtRF2MemberConfirmInfo ~= nil) then
		WuLin_ctrlTxtRF2MemberConfirmInfo:Hide()
	end
	if (WuLin_ctrlBtnRF2MemberChoose ~= nil) then
		WuLin_ctrlBtnRF2MemberChoose:Hide()
	end
	if (WuLin_ctrlBtnRF2MemberAbandon ~= nil) then
		WuLin_ctrlBtnRF2MemberAbandon:Hide()
	end
end -- end func WuLin_Hide_MemberConfirm()



--*************************************************************************************************
--*************************************************************************************************
-- 关闭按钮事件
function WuLin_Close()
	if (WuLinZhiDian:IsTeamLeader() == 1) then
		-- 队长
		WuLin_Leader_OnAbandon()
	else
		-- 队员
		WuLin_Member_OnAbandon()
	end
end -- end func WuLin_Close()

-- 队伍成员确认事件
function WuLin_TeamMemberConfirm(index, isMySelf)
	local wndIndex =  (tonumber(index) + 1)
	if (WuLin_ctrlWndLF[wndIndex] ~= nil) then
		WuLin_ctrlWndLF[wndIndex].confirm:SetProperty("Image", "set:GuanShanHai13 image:queding")
	end

	-- 队员确认界面确认、放弃按钮失效
	if (WuLin_ctrlBtnRF2MemberChoose ~= nil and tonumber(isMySelf) == 1) then
		WuLin_ctrlBtnRF2MemberChoose:Disable()
	end
	-- if (WuLin_ctrlBtnRF2MemberAbandon ~= nil and tonumber(isMySelf) == 1) then
	-- 	WuLin_ctrlBtnRF2MemberAbandon:Disable()
	-- end

	if (tonumber(isMySelf) == 1) then
		if (WuLinZhiDian:IsTeamLeader() == 1) then
			if (WuLin_ctrlTxtRF4LeaderConfirmInfo ~= nil) then
				WuLin_ctrlTxtRF4LeaderConfirmInfo:Show()
				WuLin_ctrlTxtRF4LeaderConfirmInfo:SetText("#{PTFB_191228_211}")
			end
		else
			if (WuLin_ctrlTxtRF2MemberConfirmInfo ~= nil) then
				WuLin_ctrlTxtRF2MemberConfirmInfo:Show()
				WuLin_ctrlTxtRF2MemberConfirmInfo:SetText("#{PTFB_191228_212}")
			end
		end
	end
end -- end func WuLin_TeamMemberConfirm()

-- 队伍成员放弃事件
function WuLin_TeamMemberAbort(index, isMySelf)
	local wndIndex =  (tonumber(index) + 1)
	if (WuLin_ctrlWndLF[wndIndex] ~= nil) then
		WuLin_ctrlWndLF[wndIndex].confirm:SetProperty("Image", "set:GuanShanHai13 image:jujue")
	end

	-- 设置事件 3秒后关闭窗口
	if (WuLin_TimerID < 0) then
		WuLin_TimerID = SetTimer("WuLin", "WuLin_Hide()", 3000)
	end
end -- end func WuLin_TeamMemberAbort()

-- 更新成员确认人数
function WuLin_UpdateConfirmCount(totalCount, confirmCount)
	local msg = nil
	if (tonumber(totalCount) == tonumber(confirmCount)) then
		-- 所有成员均已确认
		msg = ScriptGlobal_Format("#{PTFB_191228_60}", confirmCount, totalCount)
	else
		-- 还有人未确认
		msg = ScriptGlobal_Format("#{PTFB_191228_59}", confirmCount, totalCount)
	end

	if (WuLinZhiDian:IsTeamLeader() == 1) then
		if (WuLin_ctrlTxtRF4LeaderConfirmInfo ~= nil) then
			--WuLin_ctrlTxtRF4LeaderConfirmInfo:SetText(msg)
			WuLin_ctrlTxtRF4LeaderConfirmInfo:SetText("#{PTFB_191228_211}")
		end
	else
		if (WuLin_ctrlTxtRF2MemberConfirmInfo ~= nil) then
			WuLin_ctrlTxtRF2MemberConfirmInfo:SetText("#{PTFB_191228_212}")
		end
	end
end -- end func WuLin_UpdateConfirmCount()


--*************************************************************************************************
-- 队长确认、放弃相关
--*************************************************************************************************
-- 队长选择挑战层数确定事件
function WuLin_Leader_OnChooseStageConfirm()
	local maxStage = 1
	-- 获取队伍玩家平均层数
	local avgStage = tonumber(WuLinZhiDian:GetAverageStage())
	if (avgStage >= 0) then
		maxStage = avgStage + 1
	end
	if (maxStage > WuLin_MaxStage) then
		maxStage = WuLin_MaxStage
	end

	-- 获取当前选择的挑战层数
	local str, index = WuLin_ctrlListRF1LeaderStageList:GetCurrentSelect()
	local choseStage = tonumber(str)
	if (choseStage <= 0) then
		choseStage = 1
	end
	if (choseStage > maxStage) then
		choseStage = maxStage
	end

	-- 设置选择的挑战层数
	WuLinZhiDian:SetChooseStage(choseStage)

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("LeaderChooseConfirmCheck")
		Set_XSCRIPT_ScriptID(893398)
		Set_XSCRIPT_Parameter(0, choseStage)
		Set_XSCRIPT_Parameter(1, WuLin_CareObjSvrId)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end -- end func WuLin_Leader_OnChooseStageConfirm()

-- 队长放弃按钮事件
function WuLin_Leader_OnAbandon()
	-- 优化需求 放弃时取消二次确认
	--MessageBoxCommon("", "#{PTFB_191228_35}", "WuLin", "LeaderAbandonConfirm()", "LeaderAbandonCancel()")

	WuLin_LeaderAbandonConfirm()
end -- end func WuLin_Leader_OnAbandon()

-- 队长放弃 确认
function WuLin_LeaderAbandonConfirm()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("LeaderAbort")
		Set_XSCRIPT_ScriptID(893398)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

	WuLin_Hide()
end -- end func WuLin_AbandonConfirm()

-- 队长放弃 取消
function WuLin_LeaderAbandonCancel()
end -- end func WuLin_AbandonCancel()



--*************************************************************************************************
-- 队员确认、放弃相关
--*************************************************************************************************
-- 队员确认按钮事件
function WuLin_Member_OnChooseStageConfirm()
	-- if (WuLin_ctrlBtnRF2MemberChoose ~= nil) then
	-- 	WuLin_ctrlBtnRF2MemberChoose:Disable()
	-- end
	-- if (WuLin_ctrlBtnRF2MemberAbandon ~= nil) then
	-- 	WuLin_ctrlBtnRF2MemberAbandon:Disable()
	-- end

	-- 获取队长选择的挑战层数
	local curChooseStage = tonumber(WuLinZhiDian:GetChooseStage())
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MemberChooseConfirmCheck")
		Set_XSCRIPT_ScriptID(893398)
		Set_XSCRIPT_Parameter(0, curChooseStage)
		Set_XSCRIPT_Parameter(1, WuLin_CareObjSvrId)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end -- end func WuLin_Member_OnChooseStageConfirm()

-- 队员放弃按钮事件
function WuLin_Member_OnAbandon()
	-- 优化需求 放弃时取消二次确认
	--MessageBoxCommon("", "#{PTFB_191228_195}", "WuLin", "MemberAbandonConfirm()", "MemberAbandonCancel()")

	WuLin_MemberAbandonConfirm()
end -- end func WuLin_Member_OnAbandon()

-- 队员放弃 确认
function WuLin_MemberAbandonConfirm()
	if (WuLin_ctrlBtnRF2MemberChoose ~= nil) then
		WuLin_ctrlBtnRF2MemberChoose:Disable()
	end
	if (WuLin_ctrlBtnRF2MemberAbandon ~= nil) then
		WuLin_ctrlBtnRF2MemberAbandon:Disable()
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MemberAbort")
		Set_XSCRIPT_ScriptID(893398)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()

	WuLin_Hide()
end -- end func WuLin_MemberAbandonConfirm()

-- 队员放弃 取消
function WuLin_MemberAbandonCancel()
end -- end func WuLin_MemberAbandonCancel()



--*************************************************************************************************
-- 本周次数奖励选择事件
--*************************************************************************************************
function WuLin_WeekAward_Clicked()
	local check = WuLin_ctrlBtnWeekAward:GetCheck()
	if (check > 0) then
		-- 选中
		WuLin_WeekAward_CheckState = 1
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("WeekAwardActive")
			Set_XSCRIPT_ScriptID(893398)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	else
		-- 未选中
		WuLin_WeekAward_CheckState = 0
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("WeekAwardCancelActive")
			Set_XSCRIPT_ScriptID(893398)
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	end
end -- end func WuLin_WeekAward_Clicked()

function WuLin_WeekAwardDisable_Clicked()
	PushDebugMessage("#{PTFB_191228_431}")
end -- end func WuLin_WeekAwardDisable_Clicked()



--*************************************************************************************************
-- NPC关注相关
--*************************************************************************************************
-- 开启NPC关注
function WuLin_BeginCareObject(objSvrId, objId)
	WuLin_CareObjId = tonumber(objId)
	WuLin_CareObjSvrId = tonumber(objSvrId)
	if (WuLin_CareObjId >= 0) then
		this:CareObject(WuLin_CareObjId, 1, "WuLin")
	end
end -- end func WuLin_BeginCareObject()

-- 取消NPC关注
function WuLin_StopCareObject(objId)
	if (tonumber(objId) >= 0) then
		this:CareObject(objId, 0, "WuLin")
		WuLin_CareObjId = -1
		WuLin_CareObjSvrId = -1
	end
end -- end func WuLin_StopCareObject()