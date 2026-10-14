-- 决战武林之巅 主界面

-- 保存UI默认位置
local WuLin_Peak_New_UnifiedPosition = nil

-- 服务器脚本id
local WuLin_Peak_New_ServerScriptId = 893429

-- 周最大挑战次数
local WuLin_Peak_New_MaxWeekCount = 20

-- 关注NPC
local WuLin_Peak_New_CareObjId = -1
local WuLin_Peak_New_CareObjSvrId = -1
local WuLin_Peak_New_MAX_OBJ_DISTANCE = 5.0

-- 各难度排行榜数量
local WuLin_Peak_New_StageInfo =
{
	[1] = 100,		-- 难度1
	[2] = 50,		-- 难度2
	[3] = 20,		-- 难度3
	[4] = 10,		-- 难度4
} -- end WuLin_Peak_New_StageInfo

-- 奖励类型
local WuLin_Peak_New_AwardType =
{
    award1 = 1,         -- 难度1奖励
    award2 = 2,         -- 难度2奖励
    award3 = 3,         -- 难度3奖励
    award4 = 4,         -- 难度4奖励
} -- end WuLin_Peak_New_AwardType

function WuLin_Peak_New_PreLoad()
	this:RegisterEvent("JZWLZD_OPEN_MAIN", true)
	this:RegisterEvent("JZWLZD_CLOSE_MAIN", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func WuLin_Peak_New_PreLoad()

function WuLin_Peak_New_OnLoad()
	WuLin_Peak_New_Initctrl()

	WuLin_Peak_New_UnifiedPosition = WuLin_Peak_New_Frame:GetProperty("UnifiedPosition")
end -- end func WuLin_Peak_New_OnLoad()

function WuLin_Peak_New_OnEvent(event)
	if (event == "JZWLZD_OPEN_MAIN") then
		WuLin_Peak_New_BeginCareObject(arg0, arg1)
		WuLin_Peak_New_Show()
		WuLin_Peak_New_Update(arg2, arg3, arg4, arg5)
	elseif (event == "JZWLZD_CLOSE_MAIN") then
		WuLin_Peak_New_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		WuLin_Peak_New_Hide()
	elseif (event == "OBJECT_CARED_EVENT") then
		-- 这个事件目前已经被干掉了
		-- 要调整关注距离直接去改代码吧 ObjectManager.cpp CObjectManager::Tick(VOID)
		if(tonumber(arg0) ~= WuLin_Peak_New_CareObjId) then
			return
		end

		-- 如果和NPC的距离大于一定距离或者被删除，自动关闭
		if((arg1 == "distance" and tonumber(arg2)>WuLin_Peak_New_MAX_OBJ_DISTANCE) or arg1=="destroy") then
			-- 关闭
			WuLin_Peak_New_Hide()
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_Peak_New_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		WuLin_Peak_New_UnifiedPos()
	end
end -- end func WuLin_Peak_New_OnEvent()

-- 界面默认位置
function WuLin_Peak_New_UnifiedPos()
	if (WuLin_Peak_New_UnifiedPosition ~= nil) then
		WuLin_Peak_New_Frame:SetProperty("UnifiedPosition", WuLin_Peak_New_UnifiedPosition)
	end
end -- end func WuLin_Peak_New_UnifiedPos()

-- 初始化界面UI控件 定义控件变量、添加按钮事件等
function WuLin_Peak_New_Initctrl()
	-- 添加奖励查看按钮事件
	if (WuLin_Peak_New_Award ~= nil) then
		WuLin_Peak_New_Award:SetEvent("Clicked", "WuLin_Peak_New_ShowAward()")
	end
end -- end func WuLin_Peak_New_Initctrl()

-- 打开界面
function WuLin_Peak_New_Show()
	this:Show()
end -- end func WuLin_Peak_New_Show()

-- 关闭界面
function WuLin_Peak_New_Hide()
	WuLin_Peak_New_StopCareObject(WuLin_Peak_New_CareObjId)
	this:Hide()
end -- end func WuLin_Peak_New_Hide()

-- 开启NPC关注
function WuLin_Peak_New_BeginCareObject(objSvrId, objId)
	WuLin_Peak_New_CareObjId = tonumber(objId)
	WuLin_Peak_New_CareObjSvrId = tonumber(objSvrId)
	if (WuLin_Peak_New_CareObjId >= 0) then
		this:CareObject(WuLin_Peak_New_CareObjId, 1, "WuLin_Peak_New")
	end
end -- end func WuLin_Peak_New_BeginCareObject()

-- 取消NPC关注
function WuLin_Peak_New_StopCareObject(objId)
	if (tonumber(objId) >= 0) then
		this:CareObject(objId, 0, "WuLin_Peak_New")
		WuLin_Peak_New_CareObjId = -1
		WuLin_Peak_New_CareObjSvrId = -1
	end
end -- end func WuLin_Peak_New_StopCareObject()

-- 关闭按钮 点击事件
function WuLin_Peak_New_Close()
	WuLin_Peak_New_Hide()
end -- end func WuLin_Peak_New_Close()

-- 排行榜 点击事件
function WuLin_Peak_New_TopList_Clicked(arg)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenRankList")
		Set_XSCRIPT_ScriptID(WuLin_Peak_New_ServerScriptId)
		Set_XSCRIPT_Parameter(0, WuLin_Peak_New_CareObjSvrId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	--WuLin_Peak_New_Hide()
end -- end func WuLin_Peak_New_TopList_Clicked()

-- 山海图鉴 点击事件
function WuLin_Peak_New_BossInfo_Clicked(arg)
	PushEvent("JZWLZD_OPEN_BOSSINFO", 1)
end -- end func WuLin_Peak_New_BossInfo_Clicked()

-- 挑战 点击事件
function WuLin_Peak_New_Challenge_Clicked(arg)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TryEnterScene")
		Set_XSCRIPT_ScriptID(WuLin_Peak_New_ServerScriptId)
		Set_XSCRIPT_Parameter(0, WuLin_Peak_New_CareObjSvrId)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

	--WuLin_Peak_New_Hide()
end -- end func WuLin_Peak_New_Challenge_Clicked()

-- 奖励查看 点击事件
function WuLin_Peak_New_ShowAward()
	-- 打开奖励查看UI
	PushEvent("JZWLZD_OPEN_SHOWAWARD")
end -- end func WuLin_Peak_New_ShowAward()

-- 更新UI
function WuLin_Peak_New_Update(openStage, weekCount, ranklistCount, enterCount)
	-- 当前开放难度
	local curOpenStage = tonumber(openStage)
	-- 当前是赛季第几周
	local weekCountInSeason = tonumber(weekCount)
	-- 当前开放难度排行榜上榜数量
	local openStageRankListCount = tonumber(ranklistCount)
	-- 本周进入次数
	local curWeekCount = tonumber(enterCount)
	-- 玩家在各难度排行榜上的排名
	local rank1, rank2, rank3, rank4 = JueZhanWuLinZhiDian:GetMyselfRank()

	local maxRankListCount = -1
	if (WuLin_Peak_New_StageInfo[curOpenStage] ~= nil) then
		maxRankListCount = WuLin_Peak_New_StageInfo[curOpenStage]
	end

	-- 开启条件提示
	if (weekCountInSeason <= 0) then
		-- 这种情况应该就不是在赛季内 不显示提示吧
		WuLin_Peak_New_Text_Info:Hide()
	elseif (weekCountInSeason >= 4) then
		-- 当前是第四周 即赛季最后一周
		WuLin_Peak_New_Text_Info:Show()
		WuLin_Peak_New_Text_Info:SetText("#{JZGSH_210222_12}")
		WuLin_Peak_New_Text_Info:SetToolTip("#{JZGSH_210222_12}")
	else
		if (maxRankListCount <= 0) then
			-- 开放难度不对 应该不是赛季内 不显示提示吧
			WuLin_Peak_New_Text_Info:Hide()
		else
			WuLin_Peak_New_Text_Info:Show()
			if (openStageRankListCount >= maxRankListCount) then
				-- 上榜队伍已达到开启下一难度的要求
				local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_08}", maxRankListCount, (curOpenStage + 1))
				WuLin_Peak_New_Text_Info:SetText(tipMsg)
				WuLin_Peak_New_Text_Info:SetToolTip(tipMsg)
			else
				-- 上榜队伍未达到开启下一难度的要求
				local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_10}", maxRankListCount, (curOpenStage + 1))
				WuLin_Peak_New_Text_Info:SetText(tipMsg)
				WuLin_Peak_New_Text_Info:SetToolTip(tipMsg)
			end
		end
	end

	-- 个人排名信息
	WuLin_Peak_New_Text1BK:Hide()
	WuLin_Peak_New_Text2BK:Hide()
	WuLin_Peak_New_Text3BK:Hide()
	WuLin_Peak_New_Text4BK:Hide()
	-- 难度1
	if (curOpenStage == 1) then
		WuLin_Peak_New_Text4BK:Show()
		if (rank1 > 0) then
			-- 有排名
			local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_16}", rank1, WuLin_Peak_New_StageInfo[1])
			WuLin_Peak_New_Text4:SetText(tipMsg)
			WuLin_Peak_New_Text4:SetToolTip(tipMsg)
		else
			-- 没有排名
			local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_14}", 1, WuLin_Peak_New_StageInfo[1])
			WuLin_Peak_New_Text4:SetText(tipMsg)
			WuLin_Peak_New_Text4:SetToolTip(tipMsg)
		end
	elseif (curOpenStage > 1) then
		WuLin_Peak_New_Text4BK:Show()
		if (rank1 > 0) then
			-- 有排名
			local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_16}", rank1, WuLin_Peak_New_StageInfo[1])
			WuLin_Peak_New_Text4:SetText(tipMsg)
			WuLin_Peak_New_Text4:SetToolTip(tipMsg)
		else
			-- 没有排名
			local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_18}", 1, WuLin_Peak_New_StageInfo[1])
			WuLin_Peak_New_Text4:SetText(tipMsg)
			WuLin_Peak_New_Text4:SetToolTip(tipMsg)
		end
	end
	-- 难度2
	if (curOpenStage == 2) then
		WuLin_Peak_New_Text3BK:Show()
		if (rank2 > 0) then
			-- 有排名
			local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_16}", rank2, WuLin_Peak_New_StageInfo[2])
			WuLin_Peak_New_Text3:SetText(tipMsg)
			WuLin_Peak_New_Text3:SetToolTip(tipMsg)
		else
			-- 没有排名
			local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_14}", 2, WuLin_Peak_New_StageInfo[2])
			WuLin_Peak_New_Text3:SetText(tipMsg)
			WuLin_Peak_New_Text3:SetToolTip(tipMsg)
		end
	elseif (curOpenStage > 2) then
		WuLin_Peak_New_Text3BK:Show()
		if (rank2 > 0) then
			-- 有排名
			local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_16}", rank2, WuLin_Peak_New_StageInfo[2])
			WuLin_Peak_New_Text3:SetText(tipMsg)
			WuLin_Peak_New_Text3:SetToolTip(tipMsg)
		else
			-- 没有排名
			local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_18}", 2, WuLin_Peak_New_StageInfo[2])
			WuLin_Peak_New_Text3:SetText(tipMsg)
			WuLin_Peak_New_Text3:SetToolTip(tipMsg)
		end
	end
	-- 难度3
	if (curOpenStage == 3) then
		WuLin_Peak_New_Text2BK:Show()
		if (rank3 > 0) then
			-- 有排名
			local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_16}", rank3, WuLin_Peak_New_StageInfo[3])
			WuLin_Peak_New_Text2:SetText(tipMsg)
			WuLin_Peak_New_Text2:SetToolTip(tipMsg)
		else
			-- 没有排名
			local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_14}", 3, WuLin_Peak_New_StageInfo[3])
			WuLin_Peak_New_Text2:SetText(tipMsg)
			WuLin_Peak_New_Text2:SetToolTip(tipMsg)
		end
	elseif (curOpenStage > 3) then
		WuLin_Peak_New_Text2BK:Show()
		if (rank3 > 0) then
			-- 有排名
			local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_16}", rank3, WuLin_Peak_New_StageInfo[3])
			WuLin_Peak_New_Text2:SetText(tipMsg)
			WuLin_Peak_New_Text2:SetToolTip(tipMsg)
		else
			-- 没有排名
			local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_18}", 3, WuLin_Peak_New_StageInfo[3])
			WuLin_Peak_New_Text2:SetText(tipMsg)
			WuLin_Peak_New_Text2:SetToolTip(tipMsg)
		end
	end
	-- 难度4
	if (curOpenStage >= 4) then
		WuLin_Peak_New_Text1BK:Show()
		if (rank4 > 0) then
			-- 有排名
			local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_16}", rank1, WuLin_Peak_New_StageInfo[4])
			WuLin_Peak_New_Text1:SetText(tipMsg)
			WuLin_Peak_New_Text1:SetToolTip(tipMsg)
		else
			-- 没有排名
			local tipMsg = ScriptGlobal_Format("#{JZGSH_210222_14}", 4, WuLin_Peak_New_StageInfo[4])
			WuLin_Peak_New_Text1:SetText(tipMsg)
			WuLin_Peak_New_Text1:SetToolTip(tipMsg)
		end
	end

	-- 进入次数提示
	if (curWeekCount < 0) then
		curWeekCount = 0
	end
	if (curWeekCount >= WuLin_Peak_New_MaxWeekCount) then
		local tipMsg = ScriptGlobal_Format("#{PTFB_191228_118}", 0, WuLin_Peak_New_MaxWeekCount)
		WuLin_Peak_New_ChallengeText:SetText(tipMsg)
	else
		local tipMsg = ScriptGlobal_Format("#{PTFB_191228_119}", WuLin_Peak_New_MaxWeekCount-curWeekCount, WuLin_Peak_New_MaxWeekCount)
		WuLin_Peak_New_ChallengeText:SetText(tipMsg)
	end
end -- end func WuLin_Peak_New_Update()