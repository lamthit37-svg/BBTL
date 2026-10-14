-- 决战武林之巅 难度选择界面

-- 保存UI默认位置
local WuLin_Difficulty_UnifiedPosition = nil

-- 服务器脚本id
local WuLin_Difficulty_ServerScriptId = 893429

-- 关注NPC
local WuLin_Difficulty_CareObjId = -1
local WuLin_Difficulty_CareObjSvrId = -1
local WuLin_Difficulty_MAX_OBJ_DISTANCE = 5.0

local WuLin_Difficulty_Max_AssistCount = 3	-- 最大助战次数
local WuLin_Difficulty_MemberCount = 0		-- 队伍成员数量
local WuLin_Difficulty_AssistCount = 0		-- 已用助战次数
local WuLin_Difficulty_MaxValidStage = 0	-- 队伍当前挑战战成功的最小有效难度

local WuLin_Difficulty_HideFlag = 0

-- 计时器ID
local WuLin_Difficulty_TimerID = -1
-- 取消关闭UI定时时间（毫秒）
local WuLin_Difficulty_CloseTime = 3000

-- 门派名称表
local WuLin_Difficulty_MenPaiName =
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
	[14] = "#{JZGSH_210222_258}",
	[15] = "#{GMGameInterface_Script_DataPool_Info_ERenGu}",--menpai15 mptodo
} -- end WuLin_Difficulty_MenPaiName

-- 玩家选择状态
local WuLin_Difficulty_State =
{
	waiting = 0,		-- 等待确认
	confirm = 1,		-- 已确认
	abort = 2,			-- 已拒绝
} -- end WuLin_Difficulty_State

-- 界面控件
-- 队长选择相关
local WuLin_Difficulty_ctrlWndLeaderChoose = nil				-- 队长 选择层数窗口
local WuLin_Difficulty_ctrlTxtLeaderChooseRange = nil			-- 队长 可选层数范围
local WuLin_Difficulty_ctrlTxtLeaderChooseStage = nil			-- 队长 请选择挑战层数
local WuLin_Difficulty_ctrlListLeaderChooseStageList = nil		-- 队长 可选择层数列表
local WuLin_Difficulty_ctrlBtnLeaderChooseConfirm = nil			-- 队长 确定
local WuLin_Difficulty_ctrlBtnLeaderChooseAbort = nil			-- 队长 放弃
-- 队长选择后等待
local WuLin_Difficulty_ctrlWndLeaderWait = nil					-- 队长 队长层数选择后等待窗口
local WuLin_Difficulty_ctrlTxtLeaderWaitRange = nil				-- 队长 可选层数范围
local WuLin_Difficulty_ctrlTxtLeaderWaitStage = nil				-- 队长 层数选择
local WuLin_Difficulty_ctrlTxtLeaderWaitChose = nil				-- 队长 选择的层数
local WuLin_Difficulty_ctrlTxtLeaderWaiMemberInfo = nil			-- 队长 队伍成员确认情况
local WuLin_Difficulty_ctrlBtnLeaderWaitConfirm = nil			-- 队长 确定
local WuLin_Difficulty_ctrlBtnLeaderWaitAbort = nil				-- 队长 放弃
-- 队员等待 队员等待队长选择
local WuLin_Difficulty_ctrlWndMemberWait = nil					-- 队员 等待队长选择窗口
local WuLin_Difficulty_ctrlTxtMemberWaitRange = nil				-- 队员 可选层数范围
local WuLin_Difficulty_ctrlTxtMemberWaitStage = nil				-- 队员 层数选择
local WuLin_Difficulty_ctrlTxtMemberWaitChose = nil				-- 队员 队长选择的层数
local WuLin_Difficulty_ctrlBtnMemberWaitConfirm = nil			-- 队员 确定
local WuLin_Difficulty_ctrlBtnMemberWaitAbort = nil				-- 队员 放弃
-- 队员选择
local WuLin_Difficulty_ctrlWndMemberChoose = nil				-- 队员 队员确认窗口
local WuLin_Difficulty_ctrlTxtMemberChooseRange = nil			-- 队员 可选层数范围
local WuLin_Difficulty_ctrlTxtMemberChooseStage = nil			-- 队员 层数选择
local WuLin_Difficulty_ctrlTxtMemberChooseChose = nil			-- 队员 队长选择的层数
local WuLin_Difficulty_ctrlBtnMemberChooseConfirm = nil			-- 队员 确定
local WuLin_Difficulty_ctrlBtnMemberChooseAbort = nil			-- 队员 放弃
-- 队伍成员
local WuLin_Difficulty_ctrlWndLFLeader = nil
local WuLin_Difficulty_ctrlWndLF = nil
-- 助战
local WuLin_Difficulty_ctrlAssistBK = nil
local WuLin_Difficulty_ctrlAssist = nil
local WuLin_Difficulty_ctrlAssistTxt = nil
local WuLin_Difficulty_ctrlAssistTip = nil
local WuLin_Difficulty_ctrlAssistTipTxt = nil



-- 初始化界面UI控件 定义控件变量、添加按钮事件等
function WuLin_Difficulty_InitCtrl()
	-- 队伍成员列表
	WuLin_Difficulty_InitTeamInfoCtrl()

	-- 队长选择相关
	WuLin_Difficulty_ctrlWndLeaderChoose = WuLin_Difficulty_Right_Cap_Confirm						-- 队长 选择层数窗口
	WuLin_Difficulty_ctrlTxtLeaderChooseRange = WuLin_Difficulty_Right_Cap_ConfirmText1				-- 队长 可选层数范围
	WuLin_Difficulty_ctrlTxtLeaderChooseStage = WuLin_Difficulty_Right_Cap_ConfirmText2				-- 队长 请选择挑战层数
	WuLin_Difficulty_ctrlListLeaderChooseStageList = WuLin_Difficulty_Right_Cap_Confirm_Choice		-- 队长 可选择层数列表
	WuLin_Difficulty_ctrlBtnLeaderChooseConfirm = WuLin_Difficulty_Right_Cap_Confirm_Choose			-- 队长 确定
	WuLin_Difficulty_ctrlBtnLeaderChooseAbort = WuLin_Difficulty_Right_Cap_Confirm_Waive			-- 队长 放弃
	if (WuLin_Difficulty_ctrlBtnLeaderChooseConfirm ~= nil) then
		WuLin_Difficulty_ctrlBtnLeaderChooseConfirm:SetEvent("Clicked", "WuLin_Difficulty_LeaderChoose_Confirm_Cliecked()")
	end
	if (WuLin_Difficulty_ctrlBtnLeaderChooseAbort ~= nil) then
		WuLin_Difficulty_ctrlBtnLeaderChooseAbort:SetEvent("Clicked", "WuLin_Difficulty_LeaderChoose_Abort_Cliecked()")
	end

	-- 队长选择后等待
	WuLin_Difficulty_ctrlWndLeaderWait = WuLin_Difficulty_Right_Cap_Idle							-- 队长 队长层数选择后等待窗口
	WuLin_Difficulty_ctrlTxtLeaderWaitRange = WuLin_Difficulty_Right_Cap_IdleText2					-- 队长 可选层数范围
	WuLin_Difficulty_ctrlTxtLeaderWaitStage = WuLin_Difficulty_Right_Cap_IdleText3					-- 队长 队长选择的挑战层数
	WuLin_Difficulty_ctrlTxtLeaderWaitChose = WuLin_Difficulty_Right_Cap_IdleText4					-- 队长 选择的层数
	WuLin_Difficulty_ctrlTxtLeaderWaiMemberInfo = WuLin_Difficulty_Right_Cap_IdleText5				-- 队长 队伍成员确认情况
	WuLin_Difficulty_ctrlBtnLeaderWaitConfirm = WuLin_Difficulty_Right_Cap_Idle_Choose				-- 队长 确定
	WuLin_Difficulty_ctrlBtnLeaderWaitAbort = WuLin_Difficulty_Right_Cap_Idle_Waive				-- 队长 放弃
	if (WuLin_Difficulty_ctrlBtnLeaderWaitConfirm ~= nil) then
		WuLin_Difficulty_ctrlBtnLeaderWaitConfirm:SetEvent("Clicked", "WuLin_Difficulty_LeaderWait_Confirm_Cliecked()")
	end
	if (WuLin_Difficulty_ctrlBtnLeaderWaitAbort ~= nil) then
		WuLin_Difficulty_ctrlBtnLeaderWaitAbort:SetEvent("Clicked", "WuLin_Difficulty_LeaderWait_Abort_Cliecked()")
	end

	-- 队员等待 队员等待队长选择
	WuLin_Difficulty_ctrlWndMemberWait = WuLin_Difficulty_Right_Mem_Idle							-- 队员 等待队长选择窗口
	WuLin_Difficulty_ctrlTxtMemberWaitRange = WuLin_Difficulty_Right_Mem_IdleText1					-- 队员 可选层数范围
	WuLin_Difficulty_ctrlTxtMemberWaitStage = WuLin_Difficulty_Right_Mem_IdleText2					-- 队员 层数选择
	WuLin_Difficulty_ctrlTxtMemberWaitChose = WuLin_Difficulty_Right_Mem_IdleText3					-- 队员 队长选择的层数
	WuLin_Difficulty_ctrlBtnMemberWaitConfirm = WuLin_Difficulty_Right_Mem_Idle_Choose				-- 队员 确定
	WuLin_Difficulty_ctrlBtnMemberWaitAbort = WuLin_Difficulty_Right_Mem_Idle_Waive				-- 队员 放弃
	if (WuLin_Difficulty_ctrlBtnMemberWaitConfirm ~= nil) then
		WuLin_Difficulty_ctrlBtnMemberWaitConfirm:SetEvent("Clicked", "WuLin_Difficulty_MemberWait_Confirm_Cliecked()")
	end
	if (WuLin_Difficulty_ctrlBtnMemberWaitAbort ~= nil) then
		WuLin_Difficulty_ctrlBtnMemberWaitAbort:SetEvent("Clicked", "WuLin_Difficulty_MemberWait_Abort_Cliecked()")
	end

	-- 队员选择
	WuLin_Difficulty_ctrlWndMemberChoose = WuLin_Difficulty_Right_Mem_Confirm						-- 队员 队员确认窗口
	WuLin_Difficulty_ctrlTxtMemberChooseRange = WuLin_Difficulty_Right_Mem_ConfirmText1				-- 队员 可选层数范围
	WuLin_Difficulty_ctrlTxtMemberChooseStage = WuLin_Difficulty_Right_Mem_ConfirmText2				-- 队员 层数选择
	WuLin_Difficulty_ctrlTxtMemberChooseChose = WuLin_Difficulty_Right_Mem_ConfirmText3				-- 队员 队长选择的层数
	WuLin_Difficulty_ctrlBtnMemberChooseConfirm = WuLin_Difficulty_Right_Mem_Confirm_Choose			-- 队员 确定
	WuLin_Difficulty_ctrlBtnMemberChooseAbort = WuLin_Difficulty_Right_Mem_Confirm_Waive			-- 队员 放弃
	if (WuLin_Difficulty_ctrlBtnMemberChooseConfirm ~= nil) then
		WuLin_Difficulty_ctrlBtnMemberChooseConfirm:SetEvent("Clicked", "WuLin_Difficulty_MemberChoose_Confirm_Cliecked()")
	end
	if (WuLin_Difficulty_ctrlBtnMemberChooseAbort ~= nil) then
		WuLin_Difficulty_ctrlBtnMemberChooseAbort:SetEvent("Clicked", "WuLin_Difficulty_MemberChoose_Abort_Cliecked()")
	end

	-- 助战
	WuLin_Difficulty_ctrlAssistBK = WuLin_Difficulty_Right_ModeBK
	WuLin_Difficulty_ctrlAssist = WuLin_Difficulty_Right_Mode
	WuLin_Difficulty_ctrlAssistTxt = WuLin_Difficulty_Right_Text
	WuLin_Difficulty_ctrlAssistTip = WuLin_Difficulty_Right_Text2BK
	WuLin_Difficulty_ctrlAssistTipTxt = WuLin_Difficulty_Right_Text2
end -- end func WuLin_Difficulty_InitCtrl()

-- 初始化队伍成员列表控件
function WuLin_Difficulty_InitTeamInfoCtrl()
	-- 队伍成员列表
	WuLin_Difficulty_ctrlWndLFLeader = WuLin_Difficulty_Player1_Leader
	WuLin_Difficulty_ctrlWndLF = {}
	WuLin_Difficulty_ctrlWndLF[1] = {}
	WuLin_Difficulty_ctrlWndLF[1].frame = WuLin_Difficulty_Player1ClientBK
	WuLin_Difficulty_ctrlWndLF[1].headbk = WuLin_Difficulty_Player1HeadBK
	WuLin_Difficulty_ctrlWndLF[1].head = WuLin_Difficulty_Player1Head
	WuLin_Difficulty_ctrlWndLF[1].namebk = WuLin_Difficulty_Player1NameBK
	WuLin_Difficulty_ctrlWndLF[1].name = WuLin_Difficulty_Player1Name
	WuLin_Difficulty_ctrlWndLF[1].menpaibk = WuLin_Difficulty_Player1MenPaiBK
	WuLin_Difficulty_ctrlWndLF[1].menpai = WuLin_Difficulty_Player1MenPai
	WuLin_Difficulty_ctrlWndLF[1].stagebk = WuLin_Difficulty_Player1NumBK
	WuLin_Difficulty_ctrlWndLF[1].stage = WuLin_Difficulty_Player1Num
	WuLin_Difficulty_ctrlWndLF[1].confirm = WuLin_Difficulty_Player1_Choose
	WuLin_Difficulty_ctrlWndLF[1].clientdis = nil
	WuLin_Difficulty_ctrlWndLF[2] = {}
	WuLin_Difficulty_ctrlWndLF[2].frame = WuLin_Difficulty_Player2ClientBK
	WuLin_Difficulty_ctrlWndLF[2].headbk = WuLin_Difficulty_Player2HeadBK
	WuLin_Difficulty_ctrlWndLF[2].head = WuLin_Difficulty_Player2Head
	WuLin_Difficulty_ctrlWndLF[2].namebk = WuLin_Difficulty_Player2NameBK
	WuLin_Difficulty_ctrlWndLF[2].name = WuLin_Difficulty_Player2Name
	WuLin_Difficulty_ctrlWndLF[2].menpaibk = WuLin_Difficulty_Player2MenPaiBK
	WuLin_Difficulty_ctrlWndLF[2].menpai = WuLin_Difficulty_Player2MenPai
	WuLin_Difficulty_ctrlWndLF[2].stagebk = WuLin_Difficulty_Player2NumBK
	WuLin_Difficulty_ctrlWndLF[2].stage = WuLin_Difficulty_Player2Num
	WuLin_Difficulty_ctrlWndLF[2].confirm = WuLin_Difficulty_Player2_Choose
	WuLin_Difficulty_ctrlWndLF[2].clientdis = nil
	WuLin_Difficulty_ctrlWndLF[3] = {}
	WuLin_Difficulty_ctrlWndLF[3].frame = WuLin_Difficulty_Player3ClientBK
	WuLin_Difficulty_ctrlWndLF[3].headbk = WuLin_Difficulty_Player3HeadBK
	WuLin_Difficulty_ctrlWndLF[3].head = WuLin_Difficulty_Player3Head
	WuLin_Difficulty_ctrlWndLF[3].namebk = WuLin_Difficulty_Player3NameBK
	WuLin_Difficulty_ctrlWndLF[3].name = WuLin_Difficulty_Player3Name
	WuLin_Difficulty_ctrlWndLF[3].menpaibk = WuLin_Difficulty_Player3MenPaiBK
	WuLin_Difficulty_ctrlWndLF[3].menpai = WuLin_Difficulty_Player3MenPai
	WuLin_Difficulty_ctrlWndLF[3].stagebk = WuLin_Difficulty_Player3NumBK
	WuLin_Difficulty_ctrlWndLF[3].stage = WuLin_Difficulty_Player3Num
	WuLin_Difficulty_ctrlWndLF[3].confirm = WuLin_Difficulty_Player3_Choose
	WuLin_Difficulty_ctrlWndLF[3].clientdis = nil
	WuLin_Difficulty_ctrlWndLF[4] = {}
	WuLin_Difficulty_ctrlWndLF[4].frame = WuLin_Difficulty_Player4ClientBK
	WuLin_Difficulty_ctrlWndLF[4].headbk = WuLin_Difficulty_Player4HeadBK
	WuLin_Difficulty_ctrlWndLF[4].head = WuLin_Difficulty_Player4Head
	WuLin_Difficulty_ctrlWndLF[4].namebk = WuLin_Difficulty_Player4NameBK
	WuLin_Difficulty_ctrlWndLF[4].name = WuLin_Difficulty_Player4Name
	WuLin_Difficulty_ctrlWndLF[4].menpaibk = WuLin_Difficulty_Player4MenPaiBK
	WuLin_Difficulty_ctrlWndLF[4].menpai = WuLin_Difficulty_Player4MenPai
	WuLin_Difficulty_ctrlWndLF[4].stagebk = WuLin_Difficulty_Player4NumBK
	WuLin_Difficulty_ctrlWndLF[4].stage = WuLin_Difficulty_Player4Num
	WuLin_Difficulty_ctrlWndLF[4].confirm = WuLin_Difficulty_Player4_Choose
	WuLin_Difficulty_ctrlWndLF[4].clientdis = WuLin_Difficulty_Player4ClientDis
	WuLin_Difficulty_ctrlWndLF[5] = {}
	WuLin_Difficulty_ctrlWndLF[5].frame = WuLin_Difficulty_Player5ClientBK
	WuLin_Difficulty_ctrlWndLF[5].headbk = WuLin_Difficulty_Player5HeadBK
	WuLin_Difficulty_ctrlWndLF[5].head = WuLin_Difficulty_Player5Head
	WuLin_Difficulty_ctrlWndLF[5].namebk = WuLin_Difficulty_Player5NameBK
	WuLin_Difficulty_ctrlWndLF[5].name = WuLin_Difficulty_Player5Name
	WuLin_Difficulty_ctrlWndLF[5].menpaibk = WuLin_Difficulty_Player5MenPaiBK
	WuLin_Difficulty_ctrlWndLF[5].menpai = WuLin_Difficulty_Player5MenPai
	WuLin_Difficulty_ctrlWndLF[5].stagebk = WuLin_Difficulty_Player5NumBK
	WuLin_Difficulty_ctrlWndLF[5].stage = WuLin_Difficulty_Player5Num
	WuLin_Difficulty_ctrlWndLF[5].confirm = WuLin_Difficulty_Player5_Choose
	WuLin_Difficulty_ctrlWndLF[5].clientdis = WuLin_Difficulty_Player5ClientDis
	WuLin_Difficulty_ctrlWndLF[6] = {}
	WuLin_Difficulty_ctrlWndLF[6].frame = WuLin_Difficulty_Player6ClientBK
	WuLin_Difficulty_ctrlWndLF[6].headbk = WuLin_Difficulty_Player6HeadBK
	WuLin_Difficulty_ctrlWndLF[6].head = WuLin_Difficulty_Player6Head
	WuLin_Difficulty_ctrlWndLF[6].namebk = WuLin_Difficulty_Player6NameBK
	WuLin_Difficulty_ctrlWndLF[6].name = WuLin_Difficulty_Player6Name
	WuLin_Difficulty_ctrlWndLF[6].menpaibk = WuLin_Difficulty_Player6MenPaiBK
	WuLin_Difficulty_ctrlWndLF[6].menpai = WuLin_Difficulty_Player6MenPai
	WuLin_Difficulty_ctrlWndLF[6].stagebk = WuLin_Difficulty_Player6NumBK
	WuLin_Difficulty_ctrlWndLF[6].stage = WuLin_Difficulty_Player6Num
	WuLin_Difficulty_ctrlWndLF[6].confirm = WuLin_Difficulty_Player6_Choose
	WuLin_Difficulty_ctrlWndLF[6].clientdis = WuLin_Difficulty_Player6ClientDis
end -- end func WuLin_Difficulty_InitTeamInfoCtrl()

function WuLin_Difficulty_PreLoad()
	this:RegisterEvent("JZWLZD_OPEN_CHOOSE", true)
	this:RegisterEvent("JZWLZD_TEAMCHANGED", true)
	this:RegisterEvent("JZWLZD_LEADERCONFIRM", true)
	this:RegisterEvent("JZWLZD_LEADERABORT", true)
	this:RegisterEvent("JZWLZD_MEMBERCONFIRM", true)
	this:RegisterEvent("JZWLZD_MEMBERABORT", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func WuLin_Difficulty_PreLoad()

function WuLin_Difficulty_OnLoad()
	-- 初始化控件
	WuLin_Difficulty_InitCtrl()

	WuLin_Difficulty_UnifiedPosition = WuLin_Difficulty_Frame:GetProperty("UnifiedPosition")

	WuLin_Difficulty_HideFlag = 0
end -- end func WuLin_Difficulty_OnLoad()

function WuLin_Difficulty_OnEvent(event)
	if (event == "JZWLZD_OPEN_CHOOSE") then
		WuLin_Difficulty_MemberCount = tonumber(arg2)
		WuLin_Difficulty_AssistCount = tonumber(arg3)
		WuLin_Difficulty_MaxValidStage = tonumber(arg4)

		-- 设置NPC关注
		WuLin_Difficulty_BeginCareObject(arg0, arg1)
		
		-- 显示UI、队员列表
		WuLin_Difficulty_Show()

		-- 对战打开选择界面 其他人打开等待界面
		if (JueZhanWuLinZhiDian:IsTeamLeader() > 0) then
			WuLin_Difficulty_ShowLeaderChoose(WuLin_Difficulty_AssistCount, WuLin_Difficulty_MaxValidStage)
		else
			WuLin_Difficulty_ShowMemberWaitLeader(WuLin_Difficulty_AssistCount, WuLin_Difficulty_MaxValidStage)
		end

		-- 关闭主UI
		PushEvent("JZWLZD_CLOSE_MAIN")
	elseif (event == "JZWLZD_TEAMCHANGED") then
		-- 队伍发生变化
		if (this:IsVisible()) then
			WuLin_Difficulty_TeamChanged()
		end
	elseif (event == "JZWLZD_LEADERCONFIRM") then
		-- 服务器结果返回 队长确认
		WuLin_Difficulty_Event_LeaderConfirm(tonumber(arg0), tonumber(arg1), tonumber(arg2), tonumber(arg3))
	elseif (event == "JZWLZD_LEADERABORT") then
		-- 服务器结果返回 队长放弃
		WuLin_Difficulty_Event_LeaderAbort(tonumber(arg0), tonumber(arg1))
	elseif (event == "JZWLZD_MEMBERCONFIRM") then
		-- 服务器结果返回 队员确认
		WuLin_Difficulty_Event_MemberConfirm(tonumber(arg0), tonumber(arg1), tonumber(arg2), tonumber(arg3))
	elseif (event == "JZWLZD_MEMBERABORT") then
		-- 服务器结果返回 队员放弃
		WuLin_Difficulty_Event_MemberAbort(tonumber(arg0), tonumber(arg1))
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		WuLin_Difficulty_Hide()
	elseif (event == "OBJECT_CARED_EVENT") then
		-- 这个事件目前已经被干掉了
		-- 要调整关注距离直接去改代码吧 ObjectManager.cpp CObjectManager::Tick(VOID)
		if(tonumber(arg0) ~= WuLin_Difficulty_CareObjId) then
			return
		end

		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if((arg1 == "distance" and tonumber(arg2)>WuLin_Difficulty_MAX_OBJ_DISTANCE) or arg1=="destroy") then
			WuLin_Difficulty_Hide()
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_Difficulty_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		WuLin_Difficulty_UnifiedPos()
	end
end -- end func WuLin_Difficulty_OnEvent()

-- 界面默认位置
function WuLin_Difficulty_UnifiedPos()
	if (WuLin_Difficulty_UnifiedPosition ~= nil) then
		WuLin_Difficulty_Frame:SetProperty("UnifiedPosition", WuLin_Difficulty_UnifiedPosition)
	end
end -- end func WuLin_Difficulty_UnifiedPos()

-- 开启NPC关注
function WuLin_Difficulty_BeginCareObject(objSvrId, objId)
	WuLin_Difficulty_CareObjId = tonumber(objId)
	WuLin_Difficulty_CareObjSvrId = tonumber(objSvrId)
	if (WuLin_Difficulty_CareObjId >= 0) then
		this:CareObject(WuLin_Difficulty_CareObjId, 1, "WuLin_Difficulty")
	end
end -- end func WuLin_Difficulty_BeginCareObject()

-- 取消NPC关注
function WuLin_Difficulty_StopCareObject()
	if (WuLin_Difficulty_CareObjId >= 0) then
		this:CareObject(WuLin_Difficulty_CareObjId, 0, "WuLin_Difficulty")
	end

	WuLin_Difficulty_CareObjId = -1
	WuLin_Difficulty_CareObjSvrId = -1
end -- end func WuLin_Difficulty_StopCareObject()

-- 开启界面
function WuLin_Difficulty_Show()
	if (WuLin_Difficulty_TimerID >= 0) then
		KillTimer(WuLin_Difficulty_TimerID)
		WuLin_Difficulty_TimerID = -1
	end

	this:Show()
	WuLin_Difficulty_HideFlag = 0
	WuLin_Difficulty_ShowMemberList()
end -- end func WuLin_Difficulty_Show()

-- 关闭界面
function WuLin_Difficulty_Hide()
	WuLin_Difficulty_HideFlag = 1

	WuLin_Difficulty_MemberCount = 0
	WuLin_Difficulty_AssistCount = 0
	WuLin_Difficulty_MaxValidStage = 0

	if (WuLin_Difficulty_TimerID >= 0) then
		KillTimer(WuLin_Difficulty_TimerID)
		WuLin_Difficulty_TimerID = -1
	end

	WuLin_Difficulty_StopCareObject()
	this:Hide()
end -- end func WuLin_Difficulty_Hide()

-- 关闭按钮事件
function WuLin_Difficulty_Close()
	WuLin_Difficulty_HideFlag = 1
	if (JueZhanWuLinZhiDian:IsTeamLeader() > 0) then
		WuLin_Difficulty_Call_LeaderAbort(0)
	else
		WuLin_Difficulty_Call_MemberAbort(0)
	end

	WuLin_Difficulty_Hide()
end -- end func WuLin_Difficulty_Close()

-- 关闭事件
function WuLin_Difficulty_OnHidden()
	if (WuLin_Difficulty_HideFlag <= 0) then
		if (JueZhanWuLinZhiDian:IsTeamLeader() > 0) then
			WuLin_Difficulty_Call_LeaderAbort(0)
		else
			WuLin_Difficulty_Call_MemberAbort(0)
		end
	end
end -- end func WuLin_Difficulty_OnHidden()

-- 队伍变化
function WuLin_Difficulty_TeamChanged()
	if (JueZhanWuLinZhiDian:IsTeamLeader() > 0) then
		WuLin_Difficulty_Call_LeaderAbort(1)
	else
		WuLin_Difficulty_Call_MemberAbort(1)
	end
end -- end func WuLin_Difficulty_TeamChanged()

-- 刷新队员显示列表
function WuLin_Difficulty_ShowMemberList()
	if (WuLin_Difficulty_ctrlWndLF == nil) then
		return -1
	end

	for i = 1, 6, 1 do
		local ret, head, stage, menpai, zoneWorldId, leaderflag, name, state = JueZhanWuLinZhiDian:GetTeamMemberInfo(i-1)
		if (tonumber(ret) > 0) then
			if (WuLin_Difficulty_ctrlWndLF[i] ~= nil) then
				if (tonumber(menpai) >= 0) then
					WuLin_Difficulty_ctrlWndLF[i].headbk:Show()
					WuLin_Difficulty_ctrlWndLF[i].namebk:Show()
					WuLin_Difficulty_ctrlWndLF[i].menpaibk:Show()
					WuLin_Difficulty_ctrlWndLF[i].stagebk:Show()
					WuLin_Difficulty_ctrlWndLF[i].head:Show()
					WuLin_Difficulty_ctrlWndLF[i].name:Show()
					WuLin_Difficulty_ctrlWndLF[i].menpai:Show()
					WuLin_Difficulty_ctrlWndLF[i].stage:Show()
					WuLin_Difficulty_ctrlWndLF[i].confirm:Show()
					if (WuLin_Difficulty_ctrlWndLF[i].clientdis ~= nil) then
						WuLin_Difficulty_ctrlWndLF[i].clientdis:Hide()
					end

					-- 头像
					WuLin_Difficulty_ctrlWndLF[i].head:SetProperty("Image", head)
					-- 名字
					WuLin_Difficulty_ctrlWndLF[i].name:SetText("#L" .. name)
					-- 门派
					if (WuLin_Difficulty_MenPaiName[tonumber(menpai)] ~= nil) then
						WuLin_Difficulty_ctrlWndLF[i].menpai:SetText("#L" .. WuLin_Difficulty_MenPaiName[tonumber(menpai)])
					end
					-- 层数
					local stageText = ScriptGlobal_Format("#{JZGSH_210222_37}", stage)
					WuLin_Difficulty_ctrlWndLF[i].stage:SetText(stageText)
					-- 选择状态
					if (leaderflag == 1) then
						WuLin_Difficulty_ctrlWndLF[i].confirm:SetProperty("Image", "set:GuanShanHai13 image:dengdai")
					else
						WuLin_Difficulty_ctrlWndLF[i].confirm:SetProperty("Image", "")
					end
				else
					WuLin_Difficulty_ctrlWndLF[i].headbk:Hide()
					WuLin_Difficulty_ctrlWndLF[i].namebk:Hide()
					WuLin_Difficulty_ctrlWndLF[i].menpaibk:Hide()
					WuLin_Difficulty_ctrlWndLF[i].stagebk:Hide()
					WuLin_Difficulty_ctrlWndLF[i].head:Hide()
					WuLin_Difficulty_ctrlWndLF[i].name:Hide()
					WuLin_Difficulty_ctrlWndLF[i].menpai:Hide()
					WuLin_Difficulty_ctrlWndLF[i].stage:Hide()
					WuLin_Difficulty_ctrlWndLF[i].confirm:Hide()
					if (WuLin_Difficulty_ctrlWndLF[i].clientdis ~= nil) then
						WuLin_Difficulty_ctrlWndLF[i].clientdis:Show()
					end
				end
			end
		else
			if (WuLin_Difficulty_ctrlWndLF[i] ~= nil) then
				WuLin_Difficulty_ctrlWndLF[i].headbk:Hide()
				WuLin_Difficulty_ctrlWndLF[i].namebk:Hide()
				WuLin_Difficulty_ctrlWndLF[i].menpaibk:Hide()
				WuLin_Difficulty_ctrlWndLF[i].stagebk:Hide()
				WuLin_Difficulty_ctrlWndLF[i].head:Hide()
				WuLin_Difficulty_ctrlWndLF[i].name:Hide()
				WuLin_Difficulty_ctrlWndLF[i].menpai:Hide()
				WuLin_Difficulty_ctrlWndLF[i].stage:Hide()
				WuLin_Difficulty_ctrlWndLF[i].confirm:Hide()
				if (WuLin_Difficulty_ctrlWndLF[i].clientdis ~= nil) then
					WuLin_Difficulty_ctrlWndLF[i].clientdis:Show()
				end
			end
		end
	end -- end for

	return 1
end -- end func WuLin_Difficulty_ShowMemberList()

-- 更新等待、确认图标
function WuLin_Difficulty_UpdateConfirmIcon()
	if (WuLin_Difficulty_ctrlWndLF == nil) then
		return -1
	end

	local _, _, _, _, _, _, _, leaderState = JueZhanWuLinZhiDian:GetTeamLeaderInfo()

	for i = 1, 6, 1 do
		local ret, head, stage, menpai, zoneWorldId, leaderflag, name, state = JueZhanWuLinZhiDian:GetTeamMemberInfo(i-1)
		if (tonumber(ret) > 0) then
			if (WuLin_Difficulty_ctrlWndLF[i] ~= nil) then
				if (tonumber(menpai) >= 0) then
					local icomImage = ""
					if (state == WuLin_Difficulty_State.confirm) then
						icomImage = "set:GuanShanHai13 image:queding"
					elseif (state == WuLin_Difficulty_State.abort) then
						icomImage = "set:GuanShanHai13 image:jujue"
					elseif (state == WuLin_Difficulty_State.waiting) then
						-- if (leaderflag > 0) then
						-- 	icomImage = "set:GuanShanHai13 image:dengdai"
						-- end
						if (leaderflag > 0 or (leaderState ~= nil and leaderState == WuLin_Difficulty_State.confirm)) then
							-- 只有队长确认以后才显示等待 没确实的时候啥也不显示
							icomImage = "set:GuanShanHai13 image:dengdai"
						end
					end

					-- 确认图标
					if (WuLin_Difficulty_ctrlWndLF ~= nil and WuLin_Difficulty_ctrlWndLF[i] ~= nil) then
						WuLin_Difficulty_ctrlWndLF[i].confirm:SetProperty("Image", icomImage)
					end
				end
			end
		end
	end -- end for
end -- end func WuLin_Difficulty_UpdateConfirmIcon()

-- 显示队长选择界面
function WuLin_Difficulty_ShowLeaderChoose(assistCount, maxStage)
	WuLin_Difficulty_HideLeaderWaiting()
	WuLin_Difficulty_HideMemberChoose()
	WuLin_Difficulty_HideMemberWaiting()

	if (WuLin_Difficulty_ctrlWndLeaderChoose ~= nil) then
		WuLin_Difficulty_ctrlWndLeaderChoose:Show()
	end

	-- 难度范围
	if (WuLin_Difficulty_ctrlTxtLeaderChooseRange ~= nil) then
		local msg = nil
		if (maxStage > 1) then
			msg = ScriptGlobal_Format("#{JZGSH_210222_40}", maxStage)
		else
			msg = "#{JZGSH_210222_41}"
		end
		WuLin_Difficulty_ctrlTxtLeaderChooseRange:SetText(msg)
		WuLin_Difficulty_ctrlTxtLeaderChooseRange:Show()
	end

	-- 可选择难度
	if (WuLin_Difficulty_ctrlTxtLeaderChooseStage ~= nil) then
		WuLin_Difficulty_ctrlTxtLeaderChooseStage:SetText("#{JZGSH_210222_42}")
		WuLin_Difficulty_ctrlTxtLeaderChooseStage:Show()
	end

	-- 可选择难度列表
	if (WuLin_Difficulty_ctrlListLeaderChooseStageList ~= nil) then
		WuLin_Difficulty_ctrlListLeaderChooseStageList:Show()
		-- 设置可选择层数
		WuLin_Difficulty_ctrlListLeaderChooseStageList:ResetList()
		for i = 1, maxStage, 1 do
			WuLin_Difficulty_ctrlListLeaderChooseStageList:AddTextItem(tostring(i), i-1)
		end -- end for
		WuLin_Difficulty_ctrlListLeaderChooseStageList:SetCurrentSelect(maxStage-1)
	end

	-- 确认按钮
	if (WuLin_Difficulty_ctrlBtnLeaderChooseConfirm ~= nil) then
		WuLin_Difficulty_ctrlBtnLeaderChooseConfirm:Show()
		WuLin_Difficulty_ctrlBtnLeaderChooseConfirm:Enable()
	end

	-- 放弃按钮
	if (WuLin_Difficulty_ctrlBtnLeaderChooseAbort ~= nil) then
		WuLin_Difficulty_ctrlBtnLeaderChooseAbort:Show()
		WuLin_Difficulty_ctrlBtnLeaderChooseAbort:Enable()
	end

	-- -- 助战
	-- WuLin_Difficulty_ctrlAssistBK:Show()
	-- if (assistCount >= WuLin_Difficulty_Max_AssistCount) then
	-- 	-- 助战按钮
	-- 	WuLin_Difficulty_ctrlAssist:SetCheck(0)
	-- 	WuLin_Difficulty_ctrlAssist:Disable()

	-- 	-- 助战次数提示
	-- 	WuLin_Difficulty_ctrlAssistTip:Show()
	-- 	WuLin_Difficulty_ctrlAssistTipTxt:Show()
	-- 	WuLin_Difficulty_ctrlAssistTipTxt:SetText("#{JZGSH_210222_44}")
	-- else
	-- 	-- 助战按钮
	-- 	WuLin_Difficulty_ctrlAssist:SetCheck(0)
	-- 	WuLin_Difficulty_ctrlAssist:Enable()

	-- 	-- 助战次数提示
	-- 	WuLin_Difficulty_ctrlAssistTip:Show()
	-- 	WuLin_Difficulty_ctrlAssistTipTxt:Show()
	-- 	local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_43}", (WuLin_Difficulty_Max_AssistCount - assistCount))
	-- 	WuLin_Difficulty_ctrlAssistTipTxt:SetText(tipMsg)
	-- end
end -- end func WuLin_Difficulty_ShowLeaderChoose()

-- 显示队长等待界面
function WuLin_Difficulty_ShowLeaderWaiting(teamMemberIndex, choseStage, maxStage, assist)
	WuLin_Difficulty_HideLeaderChoose()
	WuLin_Difficulty_HideMemberChoose()
	WuLin_Difficulty_HideMemberWaiting()

	if (WuLin_Difficulty_ctrlWndLeaderWait ~= nil) then
		WuLin_Difficulty_ctrlWndLeaderWait:Show()
	end

	-- 难度范围
	if (WuLin_Difficulty_ctrlTxtLeaderWaitRange ~= nil) then
		local msg = nil
		if (maxStage > 1) then
			msg = ScriptGlobal_Format("#{JZGSH_210222_40}", maxStage)
		else
			msg = "#{JZGSH_210222_41}"
		end
		WuLin_Difficulty_ctrlTxtLeaderWaitRange:SetText(msg)
		WuLin_Difficulty_ctrlTxtLeaderWaitRange:Show()
	end

	-- 可选择难度
	if (WuLin_Difficulty_ctrlTxtLeaderWaitStage ~= nil) then
		WuLin_Difficulty_ctrlTxtLeaderChooseStage:SetText("#{JZGSH_210222_46}")
		WuLin_Difficulty_ctrlTxtLeaderWaitStage:Show()
	end

	-- 队长选择的难度
	if (WuLin_Difficulty_ctrlTxtLeaderWaitChose ~= nil) then
		local msg = ScriptGlobal_Format("#{JZGSH_210222_50}", choseStage)
		WuLin_Difficulty_ctrlTxtLeaderWaitChose:SetText(msg)
		WuLin_Difficulty_ctrlTxtLeaderWaitChose:Show()
	end

	-- 等待队员选择
	if (WuLin_Difficulty_ctrlTxtLeaderWaiMemberInfo ~= nil) then
		WuLin_Difficulty_ctrlTxtLeaderWaiMemberInfo:SetText("#{JZGSH_210222_51}")
		WuLin_Difficulty_ctrlTxtLeaderWaiMemberInfo:Show()
	end

	-- 确定按钮
	if (WuLin_Difficulty_ctrlBtnLeaderWaitConfirm ~= nil) then
		WuLin_Difficulty_ctrlBtnLeaderWaitConfirm:Show()
		WuLin_Difficulty_ctrlBtnLeaderWaitConfirm:Disable()
	end

	-- 放弃按钮
	if (WuLin_Difficulty_ctrlBtnLeaderWaitAbort ~= nil) then
		WuLin_Difficulty_ctrlBtnLeaderWaitAbort:Show()
		WuLin_Difficulty_ctrlBtnLeaderWaitAbort:Enable()
	end

	-- -- 助战
	-- WuLin_Difficulty_ctrlAssistBK:Show()
	-- if (WuLin_Difficulty_AssistCount >= WuLin_Difficulty_Max_AssistCount) then
	-- 	if (assist > 0) then
	-- 		WuLin_Difficulty_ctrlAssist:SetCheck(1)
	-- 		WuLin_Difficulty_ctrlAssist:Disable()
	-- 	else
	-- 		WuLin_Difficulty_ctrlAssist:SetCheck(0)
	-- 		WuLin_Difficulty_ctrlAssist:Disable()
	-- 	end

	-- 	-- 助战次数提示
	-- 	WuLin_Difficulty_ctrlAssistTip:Show()
	-- 	WuLin_Difficulty_ctrlAssistTipTxt:Show()
	-- 	WuLin_Difficulty_ctrlAssistTipTxt:SetText("#{JZGSH_210222_44}")
	-- else
	-- 	if (assist > 0) then
	-- 		WuLin_Difficulty_ctrlAssist:SetCheck(1)
	-- 		WuLin_Difficulty_ctrlAssist:Disable()
	-- 	else
	-- 		WuLin_Difficulty_ctrlAssist:SetCheck(0)
	-- 		WuLin_Difficulty_ctrlAssist:Disable()
	-- 	end

	-- 	-- 助战次数提示
	-- 	WuLin_Difficulty_ctrlAssistTip:Show()
	-- 	WuLin_Difficulty_ctrlAssistTipTxt:Show()
	-- 	local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_43}", (WuLin_Difficulty_Max_AssistCount - WuLin_Difficulty_AssistCount))
	-- 	WuLin_Difficulty_ctrlAssistTipTxt:SetText(tipMsg)
	-- end
end -- end func WuLin_Difficulty_ShowLeaderWaiting()

-- 显示队员等待界面 等待队长选择
function WuLin_Difficulty_ShowMemberWaitLeader(assistCount, maxStage)
	WuLin_Difficulty_HideLeaderChoose()
	WuLin_Difficulty_HideLeaderWaiting()
	WuLin_Difficulty_HideMemberChoose()

	if (WuLin_Difficulty_ctrlWndMemberWait ~= nil) then
		WuLin_Difficulty_ctrlWndMemberWait:Show()
	end

	-- 可选择难度范围
	if (WuLin_Difficulty_ctrlTxtMemberWaitRange ~= nil) then
		local msg = nil
		if (maxStage > 1) then
			msg = ScriptGlobal_Format("#{JZGSH_210222_40}", maxStage)
		else
			msg = "#{JZGSH_210222_41}"
		end
		WuLin_Difficulty_ctrlTxtMemberWaitRange:SetText(msg)
		WuLin_Difficulty_ctrlTxtMemberWaitRange:Show()
	end

	-- 选择难度
	if (WuLin_Difficulty_ctrlTxtMemberWaitStage ~= nil) then
		WuLin_Difficulty_ctrlTxtMemberWaitStage:SetText("#{JZGSH_210222_46}")
		WuLin_Difficulty_ctrlTxtMemberWaitStage:Show()
	end

	-- 等待队长选择
	if (WuLin_Difficulty_ctrlTxtMemberWaitChose ~= nil) then
		WuLin_Difficulty_ctrlTxtMemberWaitChose:SetText("#{JZGSH_210222_47}")
		WuLin_Difficulty_ctrlTxtMemberWaitChose:Show()
	end

	-- 确定按钮
	if (WuLin_Difficulty_ctrlBtnMemberWaitConfirm ~= nil) then
		WuLin_Difficulty_ctrlBtnMemberWaitConfirm:Show()
		WuLin_Difficulty_ctrlBtnMemberWaitConfirm:Disable()
	end

	-- 放弃按钮
	if (WuLin_Difficulty_ctrlBtnMemberWaitAbort ~= nil) then
		WuLin_Difficulty_ctrlBtnMemberWaitAbort:Show()
		WuLin_Difficulty_ctrlBtnMemberWaitAbort:Enable()
	end

	-- -- 助战
	-- -- 队员不能选助战 只有队长能选 队员界面disable掉助战按钮
	-- WuLin_Difficulty_ctrlAssistBK:Hide()
	-- WuLin_Difficulty_ctrlAssistTip:Hide()
end -- end func WuLin_Difficulty_ShowMemberWaitLeader()

-- 显示队员等待界面 等待其他队员确认
function WuLin_Difficulty_ShowMemberWaitOther(teamMemberIndex, choseStage, maxStage, assist)
	WuLin_Difficulty_HideLeaderChoose()
	WuLin_Difficulty_HideLeaderWaiting()
	WuLin_Difficulty_HideMemberChoose()

	if (WuLin_Difficulty_ctrlWndMemberWait ~= nil) then
		WuLin_Difficulty_ctrlWndMemberWait:Show()
	end

	-- 可选择难度范围
	if (WuLin_Difficulty_ctrlTxtMemberWaitRange ~= nil) then
		local msg = nil
		if (maxStage > 1) then
			msg = ScriptGlobal_Format("#{JZGSH_210222_40}", maxStage)
		else
			msg = "#{JZGSH_210222_41}"
		end
		WuLin_Difficulty_ctrlTxtMemberWaitRange:SetText(msg)
		WuLin_Difficulty_ctrlTxtMemberWaitRange:Show()
	end

	-- 选择难度
	if (WuLin_Difficulty_ctrlTxtMemberWaitStage ~= nil) then
		WuLin_Difficulty_ctrlTxtMemberWaitStage:SetText("#{JZGSH_210222_46}")
		WuLin_Difficulty_ctrlTxtMemberWaitStage:Show()
	end

	-- 等待队长选择
	if (WuLin_Difficulty_ctrlTxtMemberWaitChose ~= nil) then
		local msg = ScriptGlobal_Format("#{JZGSH_210222_50}", choseStage)
		WuLin_Difficulty_ctrlTxtMemberWaitChose:SetText(msg)
		WuLin_Difficulty_ctrlTxtMemberWaitChose:Show()
	end

	-- 确定按钮
	if (WuLin_Difficulty_ctrlBtnMemberWaitConfirm ~= nil) then
		WuLin_Difficulty_ctrlBtnMemberWaitConfirm:Show()
		if (JueZhanWuLinZhiDian:GetMyselfTeamMemberIndex() == teamMemberIndex) then
			WuLin_Difficulty_ctrlBtnMemberWaitConfirm:Disable()
		end
	end

	-- 放弃按钮
	if (WuLin_Difficulty_ctrlBtnMemberWaitAbort ~= nil) then
		WuLin_Difficulty_ctrlBtnMemberWaitAbort:Show()
		WuLin_Difficulty_ctrlBtnMemberWaitAbort:Enable()
	end

	-- -- 助战
	-- -- 只显示队长助战选择状态 队员自己不能选择助战 所以必须disable掉
	-- WuLin_Difficulty_ctrlAssistBK:Show()
	-- if (assist > 0) then
	-- 	WuLin_Difficulty_ctrlAssist:SetCheck(1)
	-- else
	-- 	WuLin_Difficulty_ctrlAssist:SetCheck(0)
	-- end
	-- WuLin_Difficulty_ctrlAssist:Disable()
	-- WuLin_Difficulty_ctrlAssistTip:Hide()
end -- end func WuLin_Difficulty_ShowMemberWaitOther()

-- 显示队员选择界面
function WuLin_Difficulty_ShowMemberChoose(teamMemberIndex, choseStage, maxStage, assist)
	WuLin_Difficulty_HideLeaderChoose()
	WuLin_Difficulty_HideLeaderWaiting()
	WuLin_Difficulty_HideMemberWaiting()

	if (WuLin_Difficulty_ctrlWndMemberChoose ~= nil) then
		WuLin_Difficulty_ctrlWndMemberChoose:Show()
	end

	-- 可选择难度范围
	if (WuLin_Difficulty_ctrlTxtMemberChooseRange ~= nil) then
		local msg = nil
		if (maxStage > 1) then
			msg = ScriptGlobal_Format("#{JZGSH_210222_40}", maxStage)
		else
			msg = "#{JZGSH_210222_41}"
		end
		WuLin_Difficulty_ctrlTxtMemberChooseRange:SetText(msg)
		WuLin_Difficulty_ctrlTxtMemberChooseRange:Show()
	end

	-- 选择难度
	if (WuLin_Difficulty_ctrlTxtMemberChooseStage ~= nil) then
		WuLin_Difficulty_ctrlTxtMemberChooseStage:SetText("#{JZGSH_210222_46}")
		WuLin_Difficulty_ctrlTxtMemberChooseStage:Show()
	end

	-- 队长选择的难度
	if (WuLin_Difficulty_ctrlTxtMemberChooseChose ~= nil) then
		local msg = ScriptGlobal_Format("#{JZGSH_210222_50}", choseStage)
		WuLin_Difficulty_ctrlTxtMemberChooseChose:SetText(msg)
		WuLin_Difficulty_ctrlTxtMemberChooseChose:Show()
	end

	-- 确定按钮
	if (WuLin_Difficulty_ctrlBtnMemberChooseConfirm ~= nil) then
		WuLin_Difficulty_ctrlBtnMemberChooseConfirm:Show()
		WuLin_Difficulty_ctrlBtnMemberChooseConfirm:Enable()
	end

	-- 放弃按钮
	if (WuLin_Difficulty_ctrlBtnMemberChooseAbort ~= nil) then
		WuLin_Difficulty_ctrlBtnMemberChooseAbort:Show()
		WuLin_Difficulty_ctrlBtnMemberChooseAbort:Enable()
	end

	-- -- 助战
	-- -- 只显示队长助战选择状态 队员自己不能选择助战 所以必须disable掉
	-- WuLin_Difficulty_ctrlAssistBK:Show()
	-- if (assist > 0) then
	-- 	WuLin_Difficulty_ctrlAssist:SetCheck(1)
	-- else
	-- 	WuLin_Difficulty_ctrlAssist:SetCheck(0)
	-- end
	-- WuLin_Difficulty_ctrlAssist:Disable()
	-- WuLin_Difficulty_ctrlAssistTip:Hide()
end -- end func WuLin_Difficulty_ShowMemberChoose()

-- 关闭队长选择界面
function WuLin_Difficulty_HideLeaderChoose()
	if (WuLin_Difficulty_ctrlTxtLeaderChooseRange ~= nil) then
		WuLin_Difficulty_ctrlTxtLeaderChooseRange:Hide()
	end

	if (WuLin_Difficulty_ctrlTxtLeaderChooseStage ~= nil) then
		WuLin_Difficulty_ctrlTxtLeaderChooseStage:Hide()
	end

	if (WuLin_Difficulty_ctrlListLeaderChooseStageList ~= nil) then
		WuLin_Difficulty_ctrlListLeaderChooseStageList:Hide()
	end

	if (WuLin_Difficulty_ctrlBtnLeaderChooseConfirm ~= nil) then
		WuLin_Difficulty_ctrlBtnLeaderChooseConfirm:Hide()
	end

	if (WuLin_Difficulty_ctrlBtnLeaderChooseAbort ~= nil) then
		WuLin_Difficulty_ctrlBtnLeaderChooseAbort:Hide()
	end

	if (WuLin_Difficulty_ctrlWndLeaderChoose ~= nil) then
		WuLin_Difficulty_ctrlWndLeaderChoose:Hide()
	end
end -- end func WuLin_Difficulty_HideLeaderChoose()

-- 关闭队长等待界面
function WuLin_Difficulty_HideLeaderWaiting()
	if (WuLin_Difficulty_ctrlTxtLeaderWaitRange ~= nil) then
		WuLin_Difficulty_ctrlTxtLeaderWaitRange:Hide()
	end

	if (WuLin_Difficulty_ctrlTxtLeaderWaitStage ~= nil) then
		WuLin_Difficulty_ctrlTxtLeaderWaitStage:Hide()
	end

	if (WuLin_Difficulty_ctrlTxtLeaderWaitChose ~= nil) then
		WuLin_Difficulty_ctrlTxtLeaderWaitChose:Hide()
	end

	if (WuLin_Difficulty_ctrlTxtLeaderWaiMemberInfo ~= nil) then
		WuLin_Difficulty_ctrlTxtLeaderWaiMemberInfo:Hide()
	end

	if (WuLin_Difficulty_ctrlBtnLeaderWaitConfirm ~= nil) then
		WuLin_Difficulty_ctrlBtnLeaderWaitConfirm:Hide()
	end

	if (WuLin_Difficulty_ctrlBtnLeaderWaitAbort ~= nil) then
		WuLin_Difficulty_ctrlBtnLeaderWaitAbort:Hide()
	end

	if (WuLin_Difficulty_ctrlWndLeaderWait ~= nil) then
		WuLin_Difficulty_ctrlWndLeaderWait:Hide()
	end
end -- end func WuLin_Difficulty_HideLeaderWaiting()

-- 关闭队员等待界面
function WuLin_Difficulty_HideMemberWaiting()
	if (WuLin_Difficulty_ctrlTxtMemberWaitRange ~= nil) then
		WuLin_Difficulty_ctrlTxtMemberWaitRange:Hide()
	end

	if (WuLin_Difficulty_ctrlTxtMemberWaitStage ~= nil) then
		WuLin_Difficulty_ctrlTxtMemberWaitStage:Hide()
	end

	if (WuLin_Difficulty_ctrlTxtMemberWaitChose ~= nil) then
		WuLin_Difficulty_ctrlTxtMemberWaitChose:Hide()
	end

	if (WuLin_Difficulty_ctrlBtnMemberWaitConfirm ~= nil) then
		WuLin_Difficulty_ctrlBtnMemberWaitConfirm:Hide()
	end

	if (WuLin_Difficulty_ctrlBtnMemberWaitAbort ~= nil) then
		WuLin_Difficulty_ctrlBtnMemberWaitAbort:Hide()
	end

	if (WuLin_Difficulty_ctrlWndMemberWait ~= nil) then
		WuLin_Difficulty_ctrlWndMemberWait:Hide()
	end
end -- end func WuLin_Difficulty_HideMemberWaiting()

-- 关闭队员选择界面
function WuLin_Difficulty_HideMemberChoose()
	if (WuLin_Difficulty_ctrlTxtMemberChooseRange ~= nil) then
		WuLin_Difficulty_ctrlTxtMemberChooseRange:Hide()
	end

	if (WuLin_Difficulty_ctrlTxtMemberChooseStage ~= nil) then
		WuLin_Difficulty_ctrlTxtMemberChooseStage:Hide()
	end

	if (WuLin_Difficulty_ctrlTxtMemberChooseChose ~= nil) then
		WuLin_Difficulty_ctrlTxtMemberChooseChose:Hide()
	end

	if (WuLin_Difficulty_ctrlBtnMemberChooseConfirm ~= nil) then
		WuLin_Difficulty_ctrlBtnMemberChooseConfirm:Hide()
	end

	if (WuLin_Difficulty_ctrlBtnMemberChooseAbort ~= nil) then
		WuLin_Difficulty_ctrlBtnMemberChooseAbort:Hide()
	end

	if (WuLin_Difficulty_ctrlWndMemberChoose ~= nil) then
		WuLin_Difficulty_ctrlWndMemberChoose:Hide()
	end
end -- end func WuLin_Difficulty_HideMemberChoose()

-- 队长选择 确认
function WuLin_Difficulty_LeaderChoose_Confirm_Cliecked()
	WuLin_Difficulty_Call_LeaderConfirm()

	WuLin_Difficulty_ctrlBtnLeaderChooseConfirm:Disable()
end -- end func WuLin_Difficulty_LeaderChoose_Confirm_Cliecked()

-- 对长选择 放弃
function WuLin_Difficulty_LeaderChoose_Abort_Cliecked()
	WuLin_Difficulty_Call_LeaderAbort(0)

	WuLin_Difficulty_ctrlBtnLeaderChooseConfirm:Disable()
	WuLin_Difficulty_ctrlBtnLeaderChooseAbort:Disable()
end -- end func WuLin_Difficulty_LeaderChoose_Abort_Cliecked()

-- 队长等待 确认
function WuLin_Difficulty_LeaderWait_Confirm_Cliecked()
end -- end func WuLin_Difficulty_LeaderWait_Confirm_Cliecked()

-- 队长等待 放弃
function WuLin_Difficulty_LeaderWait_Abort_Cliecked()
	WuLin_Difficulty_Call_LeaderAbort(0)

	WuLin_Difficulty_ctrlBtnLeaderWaitConfirm:Disable()
	WuLin_Difficulty_ctrlBtnLeaderWaitAbort:Disable()
end -- end func WuLin_Difficulty_LeaderWait_Abort_Cliecked()

-- 队员选择 确认
function WuLin_Difficulty_MemberChoose_Confirm_Cliecked()
	WuLin_Difficulty_Call_MemberConfirm()

	WuLin_Difficulty_ctrlBtnMemberChooseConfirm:Disable()
end -- end func WuLin_Difficulty_MemberChoose_Confirm_Cliecked()

-- 队员选择 放弃
function WuLin_Difficulty_MemberChoose_Abort_Cliecked()
	WuLin_Difficulty_Call_MemberAbort(0)

	WuLin_Difficulty_ctrlBtnMemberChooseConfirm:Disable()
	WuLin_Difficulty_ctrlBtnMemberChooseAbort:Disable()
end -- end func WuLin_Difficulty_MemberChoose_Abort_Cliecked()

-- 队员等待 确认
function WuLin_Difficulty_MemberWait_Confirm_Cliecked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MemberConfirm")
		Set_XSCRIPT_ScriptID(WuLin_Difficulty_ServerScriptId)
		Set_XSCRIPT_Parameter(0, WuLin_Difficulty_CareObjSvrId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end -- end func WuLin_Difficulty_MemberWait_Confirm_Cliecked()

-- 队员等待 放弃
function WuLin_Difficulty_MemberWait_Abort_Cliecked()
	WuLin_Difficulty_Call_MemberAbort(0)

	WuLin_Difficulty_ctrlBtnMemberWaitConfirm:Disable()
	WuLin_Difficulty_ctrlBtnMemberWaitAbort:Disable()
end -- end func WuLin_Difficulty_MemberWait_Abort_Cliecked()

-- 选择助战
function WuLin_Difficulty_WeekAward_Clicked()
end -- end func WuLin_Difficulty_WeekAward_Clicked()

-- 队长确认
function WuLin_Difficulty_Call_LeaderConfirm()
	-- 选择层数（难度）
	-- 获取当前选择的挑战层数
	local str, index = WuLin_Difficulty_ctrlListLeaderChooseStageList:GetCurrentSelect()
	local choseStage = tonumber(str)
	if (choseStage <= 0) then
		choseStage = 1
	end

	-- 是否使用助战
	--local assist = WuLin_Difficulty_ctrlAssist:GetCheck()
	local assist = 0

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("LeaderConfirm")
		Set_XSCRIPT_ScriptID(WuLin_Difficulty_ServerScriptId)
		Set_XSCRIPT_Parameter(0, WuLin_Difficulty_CareObjSvrId)
		Set_XSCRIPT_Parameter(1, choseStage)
		Set_XSCRIPT_Parameter(2, assist)
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()
end -- end func WuLin_Difficulty_Call_LeaderConfirm()

-- 服务器结果返回 队长确认
function WuLin_Difficulty_Event_LeaderConfirm(teamMemberIndex, choseStage, maxStage, assist)
	-- -- 确认图标
	-- if (WuLin_Difficulty_ctrlWndLF ~= nil and WuLin_Difficulty_ctrlWndLF[teamMemberIndex+1] ~= nil) then
	-- 	WuLin_Difficulty_ctrlWndLF[teamMemberIndex+1].confirm:SetProperty("Image", "set:GuanShanHai13 image:queding")
	-- end
	-- 刷新确认、等待、放弃图标
	WuLin_Difficulty_UpdateConfirmIcon()

	if (JueZhanWuLinZhiDian:IsTeamLeader() > 0) then
		-- 队长 切换到队长等待界面
		WuLin_Difficulty_ShowLeaderWaiting(teamMemberIndex, choseStage, maxStage, assist)
	else
		-- 队员 切换到队员选择界面
		WuLin_Difficulty_ShowMemberChoose(teamMemberIndex, choseStage, maxStage, assist)
	end
end -- end func WuLin_Difficulty_Event_LeaderConfirm()

-- 队长放弃
function WuLin_Difficulty_Call_LeaderAbort(isTeamChanged)
	local teamChange = 0
	if (isTeamChanged ~= nil and isTeamChanged > 0) then
		teamChange = isTeamChanged
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("LeaderAbort")
		Set_XSCRIPT_ScriptID(WuLin_Difficulty_ServerScriptId)
		Set_XSCRIPT_Parameter(0, teamChange)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end -- end func WuLin_Difficulty_Call_LeaderAbort()

-- 服务器结果返回 队长放弃
function WuLin_Difficulty_Event_LeaderAbort(teamMemberIndex, isTeamChanged)
	if (teamMemberIndex < 0) then
		return -1
	end

	local ret, head, stage, menpai, zoneWorldId, leaderflag, name, state = JueZhanWuLinZhiDian:GetTeamMemberInfo(teamMemberIndex)
	-- 提示
	if (isTeamChanged <= 0 and tonumber(ret) > 0 and name ~= nil) then
		local tipMsg = ScriptGlobal_Format("#{PTFB_191228_38}", name)
		PushDebugMessage(tipMsg)
	end

	-- -- 放弃图标
	-- if (WuLin_Difficulty_ctrlWndLF ~= nil and WuLin_Difficulty_ctrlWndLF[teamMemberIndex+1] ~= nil) then
	-- 	WuLin_Difficulty_ctrlWndLF[teamMemberIndex+1].confirm:SetProperty("Image", "set:GuanShanHai13 image:jujue")
	-- end
	if (isTeamChanged <= 0) then
		-- 刷新确认、等待、放弃图标
		WuLin_Difficulty_UpdateConfirmIcon()
	end

	-- 设置事件 3秒后关闭窗口
	if (WuLin_Difficulty_TimerID < 0) then
		WuLin_Difficulty_TimerID = SetTimer("WuLin_Difficulty", "WuLin_Difficulty_Hide()", WuLin_Difficulty_CloseTime)
	end

	return 1
end -- end func WuLin_Difficulty_Event_LeaderAbort()

-- 队员确认
function WuLin_Difficulty_Call_MemberConfirm()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MemberConfirm")
		Set_XSCRIPT_ScriptID(WuLin_Difficulty_ServerScriptId)
		Set_XSCRIPT_Parameter(0, WuLin_Difficulty_CareObjSvrId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end -- end func WuLin_Difficulty_Call_MemberConfirm()

-- 服务器结果返回 队员确认
function WuLin_Difficulty_Event_MemberConfirm(teamMemberIndex, choseStage, maxStage, assist)
	-- -- 显示队员确认图标
	-- if (WuLin_Difficulty_ctrlWndLF ~= nil and WuLin_Difficulty_ctrlWndLF[teamMemberIndex+1] ~= nil) then
	-- 	WuLin_Difficulty_ctrlWndLF[teamMemberIndex+1].confirm:SetProperty("Image", "set:GuanShanHai13 image:queding")
	-- end
	-- 刷新确认、等待、放弃图标
	WuLin_Difficulty_UpdateConfirmIcon()

	-- 队员 切换到等待其他队员选择界面
	if (JueZhanWuLinZhiDian:GetMyselfTeamMemberIndex() == teamMemberIndex) then
		WuLin_Difficulty_ShowMemberWaitOther(teamMemberIndex, choseStage, maxStage, assist)
	end
end -- end func WuLin_Difficulty_Event_MemberConfirm()

-- 队员放弃
function WuLin_Difficulty_Call_MemberAbort(isTeamChanged)
	local teamChange = 0
	if (isTeamChanged ~= nil and isTeamChanged > 0) then
		teamChange = isTeamChanged
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("MemberAbort")
		Set_XSCRIPT_ScriptID(WuLin_Difficulty_ServerScriptId)
		Set_XSCRIPT_Parameter(0, teamChange)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end -- end func WuLin_Difficulty_Call_MemberAbort()

-- 服务器结果返回 队员放弃
function WuLin_Difficulty_Event_MemberAbort(teamMemberIndex, isTeamChanged)
	if (teamMemberIndex < 0) then
		return -1
	end

	local ret, head, stage, menpai, zoneWorldId, leaderflag, name, state = JueZhanWuLinZhiDian:GetTeamMemberInfo(teamMemberIndex)
	-- 提示
	if (isTeamChanged <= 0 and tonumber(ret) > 0 and name ~= nil) then
		local tipMsg = ScriptGlobal_Format("#{PTFB_191228_38}", name)
		PushDebugMessage(tipMsg)
	end

	-- -- 放弃图标
	-- if (WuLin_Difficulty_ctrlWndLF ~= nil and WuLin_Difficulty_ctrlWndLF[teamMemberIndex+1] ~= nil) then
	-- 	WuLin_Difficulty_ctrlWndLF[teamMemberIndex+1].confirm:SetProperty("Image", "set:GuanShanHai13 image:jujue")
	-- end
	if (isTeamChanged <= 0) then
		-- 刷新确认、等待、放弃图标
		WuLin_Difficulty_UpdateConfirmIcon()
	end

	-- 设置事件 3秒后关闭窗口
	if (WuLin_Difficulty_TimerID < 0) then
		WuLin_Difficulty_TimerID = SetTimer("WuLin_Difficulty", "WuLin_Difficulty_Hide()", WuLin_Difficulty_CloseTime)
	end

	return 1
end -- end func WuLin_Difficulty_Event_MemberAbort()