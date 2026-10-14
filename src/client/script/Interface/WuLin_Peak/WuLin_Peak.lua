-- 武林之巅 主界面

-- 保存UI默认位置
local WuLin_Peak_UnifiedPosition = nil

-- 周最大挑战次数
local WuLin_Peak_MaxWeekCount = 20

-- 关注NPC
local WuLin_Peak_CareObjId = -1
local WuLin_Peak_CareObjSvrId = -1
local WuLin_Peak_MAX_OBJ_DISTANCE = 5.0

local WuLin_Peak_StagePosList = {}

function WuLin_Peak_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("WLZD_OPEN_MAIN", true)
	this:RegisterEvent("WLZD_UPDATE_MAIN", true)
	this:RegisterEvent("WLZD_CLOSE_ALL", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func WuLin_Peak_PreLoad()

function WuLin_Peak_OnLoad()
	WuLin_Peak_Initctrl()

	WuLin_Peak_UnifiedPosition = WuLin_Peak_Frame:GetProperty("UnifiedPosition")
end -- end func WuLin_Peak_OnLoad()

function WuLin_Peak_OnEvent(event)
	if (event == "WLZD_OPEN_MAIN") then
		WuLin_Peak_BeginCareObject(arg0, arg1)
		WuLin_Peak_Show(arg2, arg3, arg4, arg5)
	elseif (event == "WLZD_UPDATE_MAIN") then
		WuLin_Peak_Update(tonumber(arg0))
	elseif (event == "WLZD_CLOSE_ALL") then
		WuLin_Peak_Hide()
		--SetTimer("WuLin_Peak", "WuLin_Peak_Hide()", 500)
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		WuLin_Peak_Hide()
	elseif (event == "OBJECT_CARED_EVENT") then
		if(tonumber(arg0) ~= WuLin_Peak_CareObjId) then
			return;
		end

		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if((arg1 == "distance" and tonumber(arg2)>WuLin_Peak_MAX_OBJ_DISTANCE) or arg1=="destroy") then
			--取消关心
			WuLin_Peak_Hide()
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_Peak_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		WuLin_Peak_UnifiedPos()
	end
end -- end func WuLin_Peak_OnEvent()

-- 界面默认位置
function WuLin_Peak_UnifiedPos()
	if (WuLin_Peak_UnifiedPosition ~= nil) then
		WuLin_Peak_Frame:SetProperty("UnifiedPosition", WuLin_Peak_UnifiedPosition)
	end
end -- end func WuLin_Peak_UnifiedPos()

-- 初始化界面UI控件 定义控件变量、添加按钮事件等
function WuLin_Peak_Initctrl()
	-- 首通奖励领奖按钮
	if (WuLin_Peak_Award ~= nil) then
		WuLin_Peak_Award:SetEvent("Clicked", "WuLin_Peak_StageAward()")
	end
	-- 查看周奖励按钮
	if (WuLin_Peak_Award2 ~= nil) then
		WuLin_Peak_Award2:SetEvent("Clicked", "WuLin_Peak_WeekAward()")
	end
	-- 排行榜按钮
	if (WuLin_Peak_TopList ~= nil) then
		WuLin_Peak_TopList:SetEvent("Clicked", "WuLin_Peak_RankList()")
	end
	-- 攻略按钮
	if (WuLin_Peak_BossInfo ~= nil) then
		WuLin_Peak_BossInfo:SetEvent("Clicked", "WuLin_Peak_ShowBossInfo()")
	end
	-- 挑战
	if (WuLin_Peak_Challenge ~= nil) then
		WuLin_Peak_Challenge:SetEvent("Clicked", "WuLin_Peak_EnterScene()")
	end
	-- 层数位置
	if (WuLin_Peak_StagePosList == nil) then
		WuLin_Peak_StagePosList = {}
	end
	WuLin_Peak_StagePosList[0] = WuLin_Peak_Go
	WuLin_Peak_StagePosList[1] = WuLin_Peak_Go1
	WuLin_Peak_StagePosList[2] = WuLin_Peak_Go2
	WuLin_Peak_StagePosList[3] = WuLin_Peak_Go3
	WuLin_Peak_StagePosList[4] = WuLin_Peak_Go4
	WuLin_Peak_StagePosList[5] = WuLin_Peak_Go5
	WuLin_Peak_StagePosList[6] = WuLin_Peak_Go6
	WuLin_Peak_StagePosList[7] = WuLin_Peak_Go7
	WuLin_Peak_StagePosList[8] = WuLin_Peak_Go8
	WuLin_Peak_StagePosList[9] = WuLin_Peak_Go9
	WuLin_Peak_StagePosList[10] = WuLin_Peak_Go10
end -- end func WuLin_Peak_Initctrl()

-- 打开界面
function WuLin_Peak_Show(curWeekMaxStage, curWeekCount, stageAwardCount, maxStage)
	this:Show()

	local weekMaxStage = tonumber(curWeekMaxStage)
	local weekCount = tonumber(curWeekCount)
	local awardCount = tonumber(stageAwardCount)

	for i=0, 10, 1 do
		if (WuLin_Peak_StagePosList[i] ~= nil) then
			WuLin_Peak_StagePosList[i]:SetToolTip("")
			WuLin_Peak_StagePosList[i]:Hide()
		end
	end

	-- 首通奖励小红点
	if (awardCount > 0) then
		WuLin_Peak_Awardtips:Show()
	else
		WuLin_Peak_Awardtips:Hide()
	end

	local remainsCount = WuLin_Peak_MaxWeekCount - weekCount
	if (remainsCount < 0) then
		remainsCount = 0
	elseif (remainsCount > WuLin_Peak_MaxWeekCount) then
		remainsCount = WuLin_Peak_MaxWeekCount
	end

	local weekMaxStageText = ScriptGlobal_Format("#{PTFB_191228_197}", weekMaxStage)
	local maxStageText = ScriptGlobal_Format("#{PTFB_191228_330}", maxStage)
	local weekCountText = ""
	if (weekCount < WuLin_Peak_MaxWeekCount) then
		weekCountText = ScriptGlobal_Format("#{PTFB_191228_119}", remainsCount, WuLin_Peak_MaxWeekCount)
	else
		weekCountText = ScriptGlobal_Format("#{PTFB_191228_118}", remainsCount, WuLin_Peak_MaxWeekCount)
	end

	-- 本周最高通关层数
	WuLin_Peak_Text1:SetText(weekMaxStageText)
	-- 历史最大层数
	WuLin_Peak_Text2:SetText(maxStageText)
	-- 本周剩余挑战次数
	WuLin_Peak_ChallengeText:SetText(weekCountText)

	-- 层数位置
	local stageIndex = math.floor(weekMaxStage / 10)
	if (stageIndex < 0) then
		stageIndex = 0
	elseif (stageIndex > 10) then
		stageIndex = 10
	end
	if (WuLin_Peak_StagePosList[stageIndex] ~= nil) then
		WuLin_Peak_StagePosList[stageIndex]:Show()
		local tipText = ScriptGlobal_Format("#{PTFB_191228_430}", weekMaxStage)
		WuLin_Peak_StagePosList[stageIndex]:SetToolTip(tipText)
	end
end -- end func WuLin_Peak_Show()

-- 关闭界面
function WuLin_Peak_Hide()
	WuLin_Peak_StopCareObject(WuLin_Peak_CareObjId)
	this:Hide()
end -- end func WuLin_Peak_Hide()

-- 首通奖励领奖按钮事件
function WuLin_Peak_StageAward()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenStageCompleteAward")
		Set_XSCRIPT_ScriptID(893398)
		Set_XSCRIPT_Parameter(0, WuLin_Peak_CareObjSvrId)
		Set_XSCRIPT_Parameter(1, 0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end -- end func WuLin_Peak_StageAward()

-- 查看周奖励按钮事件
function WuLin_Peak_WeekAward()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenWeekAward")
		Set_XSCRIPT_ScriptID(893398)
		Set_XSCRIPT_Parameter(0, WuLin_Peak_CareObjSvrId)
		Set_XSCRIPT_Parameter(1, 0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end -- end func WuLin_Peak_WeekAward()

-- 排行榜按钮事件
function WuLin_Peak_RankList()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenRankList")
		Set_XSCRIPT_ScriptID(893398)
		Set_XSCRIPT_Parameter(0, WuLin_Peak_CareObjSvrId)
		Set_XSCRIPT_Parameter(1, 0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end -- end func WuLin_Peak_RankList()

-- 挑战按钮事件
function WuLin_Peak_EnterScene()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TryEnterScene")
		Set_XSCRIPT_ScriptID(893398)
		Set_XSCRIPT_Parameter(0, WuLin_Peak_CareObjSvrId)
		Set_XSCRIPT_Parameter(1, 0)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
end -- end func WuLin_Peak_EnterScene()

-- 更新UI
function WuLin_Peak_Update(flag)
	if (flag == 1) then
		-- 取消首通奖励小红点显示
		if (WuLin_Peak_Awardtips ~= nil) then
			WuLin_Peak_Awardtips:Hide()
		end
	end
end -- end func WuLin_Peak_Update()

-- 攻略
function WuLin_Peak_ShowBossInfo()
	PushEvent("WLZD_OPEN_BOSSINFO", 1)
end -- end func WuLin_Peak_ShowBossInfo()

-- 关闭按钮
function WuLin_Peak_Close()
	WuLin_Peak_Hide()
end -- end func WuLin_Peak_Close()

-- 开启NPC关注
function WuLin_Peak_BeginCareObject(objSvrId, objId)
	WuLin_Peak_CareObjId = tonumber(objId)
	WuLin_Peak_CareObjSvrId = tonumber(objSvrId)
	if (WuLin_Peak_CareObjId >= 0) then
		this:CareObject(WuLin_Peak_CareObjId, 1, "WuLin_Peak")
	end
end -- end func WuLin_Peak_BeginCareObject()

-- 取消NPC关注
function WuLin_Peak_StopCareObject(objId)
	if (tonumber(objId) >= 0) then
		this:CareObject(objId, 0, "WuLin_Peak")
		WuLin_Peak_CareObjId = -1
		WuLin_Peak_CareObjSvrId = -1
	end
end -- end func WuLin_Peak_StopCareObject()