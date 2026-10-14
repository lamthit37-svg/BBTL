-- 新比武（6v6）季后赛 赛程查看UI
-- 关注NPC
local HuaShanLunJian2_BattleTable_CareObjId = -1
local HuaShanLunJian2_BattleTable_CareObjSvrId = -1
local HuaShanLunJian2_BattleTable_MAX_OBJ_DISTANCE = 5.0
local HuaShanLunJian2_BattleTable_UnifiedPosition = nil
-- 战队控件列表
local HuaShanLunJian2_BattleTable_GroupBattleCtrlList = nil
local HuaShanLunJian2_BattleTable_FinalBattleCtrlList = nil
-- 当前显示的战队列表
local HuaShanLunJian2_BattleTable_TeamList = nil
-- 战队对照表
local HuaShanLunJian2_BattleTable_TeamIDTable = nil
-- 当前展示的比赛类型（小组赛还是总决赛）
local HuaShanLunJian2_BattleTable_CurPageType = 1
-- 当前展示名字类型（战队名还是服务器名）
local HuaShanLunJian2_BattleTable_CurNameType = 1
-- 当前选中的战队
local HuaShanLunJian2_BattleTable_CurSelectTeamID = 0
-- 当前选中的分组
local HuaShanLunJian2_BattleTable_CurSelectGroup = 1
-- 比赛轮数
local HuaShanLunJian2_BattleTable_GroupRoundCount = 5
local HuaShanLunJian2_BattleTable_TotalRoundCount = 8
local HuaShanLunJian2_BattleTable_Group = 1

local HuaShanLunJian2_BattleTable_TeamType =
{
	orimatch = 1,
	tmatch = 2
} -- end HuaShanLunJian2_BattleTable_TeamType

local HuaShanLunJian2_BattleTable_PageType =
{
	group = 1,		-- 小组赛分页
	final = 2,		-- 决赛分页
} -- end HuaShanLunJian2_BattleTable_PageType

local HuaShanLunJian2_BattleTable_NameType =
{
	team = 1,		-- 战队名
	world = 2,		-- 服务器名
} -- end HuaShanLunJian2_BattleTable_NameType

local HuaShanLunJian2_BattleTable_Result =
{
	lose = 1,
	win = 2,
} -- end HuaShanLunJian2_BattleTable_Result

local HuaShanLunJian2_BattleTable_GroupID =
{
	group_begin = 1,
	group1 = 1,
	group2 = 2,
	group3 = 3,
	group4 = 4,
	group5 = 5,
	group6 = 6,
	group7 = 7,
	group8 = 8,
	groupo_end = 8,
} -- end func HuaShanLunJian2_BattleTable_GroupID

function HuaShanLunJian2_BattleTable_PreLoad()
	this:RegisterEvent("XBWJHS_OPENTMATCH", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func HuaShanLunJian2_BattleTable_PreLoad()

function HuaShanLunJian2_BattleTable_OnEvent(event)
	if (event == "XBWJHS_OPENTMATCH") then
		HuaShanLunJian2_BattleTable_BeginCareObject(tonumber(arg0), tonumber(arg1))
		HuaShanLunJian2_BattleTable_CurNameType = HuaShanLunJian2_BattleTable_NameType.team
		local finalFlag = tonumber(arg2)
		if (finalFlag > 0) then
			HuaShanLunJian2_BattleTable_UpdateFinalBattleInfo()
		else
			HuaShanLunJian2_BattleTable_CurSelectGroup = 1
			HuaShanLunJian2_BattleTable_UpdateGroupBattleInfo()
		end
		HuaShanLunJian2_BattleTable_Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		HuaShanLunJian2_BattleTable_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		HuaShanLunJian2_BattleTable_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		HuaShanLunJian2_BattleTable_UnifiedPos()
	end
end -- end func HuaShanLunJian2_BattleTable_OnEvent()

function HuaShanLunJian2_BattleTable_OnLoad()
	HuaShanLunJian2_BattleTable_InitMatchCtrl()
	HuaShanLunJian2_BattleTable_UnifiedPosition = HuaShanLunJian2_BattleTable_Frame:GetProperty("UnifiedPosition")
end -- end func HuaShanLunJian2_BattleTable_OnLoad()

-- 界面默认位置
function HuaShanLunJian2_BattleTable_UnifiedPos()
	if (HuaShanLunJian2_BattleTable_UnifiedPosition ~= nil) then
		HuaShanLunJian2_BattleTable_Frame:SetProperty("UnifiedPosition", HuaShanLunJian2_BattleTable_UnifiedPosition)
	end
end -- end func HuaShanLunJian2_BattleTable_UnifiedPos()

function HuaShanLunJian2_BattleTable_Show()
    this:Show()
end -- end func HuaShanLunJian2_BattleTable_Show()

function HuaShanLunJian2_BattleTable_Hide()
	HuaShanLunJian2_BattleTable_StopCareObject()
    this:Hide()
end -- end func HuaShanLunJian2_BattleTable_Hide()

-- 开启NPC关注
function HuaShanLunJian2_BattleTable_BeginCareObject(objSvrId, objId)
	HuaShanLunJian2_BattleTable_CareObjSvrId = objSvrId
	HuaShanLunJian2_BattleTable_CareObjId = objId
	if (HuaShanLunJian2_BattleTable_CareObjId >= 0) then
		this:CareObject(HuaShanLunJian2_BattleTable_CareObjId, 1, "HuaShanLunJian2_BattleTable")
	end
end -- end func HuaShanLunJian2_BattleTable_BeginCareObject()

-- 取消NPC关注
function HuaShanLunJian2_BattleTable_StopCareObject()
	if (HuaShanLunJian2_BattleTable_CareObjId >= 0) then
		this:CareObject(HuaShanLunJian2_BattleTable_CareObjId, 0, "HuaShanLunJian2_BattleTable")
		HuaShanLunJian2_BattleTable_CareObjId = -1
		HuaShanLunJian2_BattleTable_CareObjSvrId = -1
	end
end -- end func HuaShanLunJian2_BattleTable_StopCareObject()

--*************************************************************************************************
--*************************************************************************************************
--
--*************************************************************************************************
--*************************************************************************************************

-- OnHidden事件
function HuaShanLunJian2_BattleTable_Clicked()
end -- end func HuaShanLunJian2_BattleTable_Clicked()

-- 关闭按钮事件
function HuaShanLunJian2_BattleTable_Close()
    HuaShanLunJian2_BattleTable_Hide()
end -- end func HuaShanLunJian2_BattleTable_Close()

-- 分页页签点击事件
function HuaShanLunJian2_BattleTable_CheckBox(idx)
	if (idx == nil) then
		return
	end

	if (idx == 1) then
		HuaShanLunJian2_BattleTable_UpdateGroupBattleInfo()
	elseif (idx == 2) then
		HuaShanLunJian2_BattleTable_UpdateFinalBattleInfo()
	end
end -- end func HuaShanLunJian2_BattleTable_CheckBox()

-- 小组分组页签点击事件
function HuaShanLunJian2_BattleTable_ZoneIDClicked(idx)
	if (idx == nil) then
		return
	end

	HuaShanLunJian2_BattleTable_CurSelectGroup = idx
	HuaShanLunJian2_BattleTable_UpdateGroupBattleInfo()
end -- end func HuaShanLunJian2_BattleTable_ZoneIDClicked()

-- 战队控件点击事件（小组赛）
function HuaShanLunJian2_BattleTable_Client1_Name_Clicked(arg)
	if (arg == nil or arg <= 0) then
		return
	end
	if (HuaShanLunJian2_BattleTable_TeamIDTable == nil) then
		return
	end

	-- 处理选中特效
	local ctrlList = HuaShanLunJian2_BattleTable_GroupBattleCtrlList
	if (ctrlList == nil) then
		return
	end
	for i=1, table.getn(ctrlList), 1 do
		local roundCtrlList = ctrlList[i]
		if (roundCtrlList ~= nil) then
			for j=1, table.getn(roundCtrlList), 1 do
				if (roundCtrlList[j] ~= nil) then
					if (roundCtrlList[j].arg == arg) then
						roundCtrlList[j].ani:Show()
					else
						roundCtrlList[j].ani:Hide()
					end
				end
			end -- end for
		end
	end -- end for

	HuaShanLunJian2_BattleTable_CurSelectTeamID = HuaShanLunJian2_BattleTable_TeamIDTable[arg]
	if (HuaShanLunJian2_BattleTable_CurSelectTeamID == nil or HuaShanLunJian2_BattleTable_CurSelectTeamID <= 0) then
		return
	end

	local svrObjId = HuaShanLunJian2_BattleTable_CareObjSvrId
	local objId = HuaShanLunJian2_BattleTable_CareObjId
	PushEvent("XBWJHS_OPENTEAMINFO", HuaShanLunJian2_BattleTable_TeamType.tmatch, HuaShanLunJian2_BattleTable_CurSelectTeamID, svrObjId, objId)
end -- end func HuaShanLunJian2_BattleTable_GroupTeamClick()

-- 战队控件点击事件（决赛）
function HuaShanLunJian2_BattleTable_Client2_Name_Clicked(arg)
	if (arg == nil or arg <= 0) then
		return
	end
	if (HuaShanLunJian2_BattleTable_TeamIDTable == nil) then
		return
	end

	-- 处理选中特效
	local ctrlList = HuaShanLunJian2_BattleTable_FinalBattleCtrlList
	if (ctrlList == nil) then
		return
	end
	for i=1, table.getn(ctrlList), 1 do
		local roundCtrlList = ctrlList[i]
		if (roundCtrlList ~= nil) then
			for j=1, table.getn(roundCtrlList), 1 do
				if (roundCtrlList[j] ~= nil) then
					if (roundCtrlList[j].arg == arg) then
						roundCtrlList[j].ani:Show()
					else
						roundCtrlList[j].ani:Hide()
					end
				end
			end -- end for
		end
	end -- end for

	HuaShanLunJian2_BattleTable_CurSelectTeamID = HuaShanLunJian2_BattleTable_TeamIDTable[arg]
	if (HuaShanLunJian2_BattleTable_CurSelectTeamID == nil or HuaShanLunJian2_BattleTable_CurSelectTeamID <= 0) then
		return
	end

	local svrObjId = HuaShanLunJian2_BattleTable_CareObjSvrId
	local objId = HuaShanLunJian2_BattleTable_CareObjId
	PushEvent("XBWJHS_OPENTEAMINFO", HuaShanLunJian2_BattleTable_TeamType.tmatch, HuaShanLunJian2_BattleTable_CurSelectTeamID, svrObjId, objId)
end -- end func HuaShanLunJian2_BattleTable_FinalTeamClick()

-- 切换战队名和服务器名
function HuaShanLunJian2_BattleTable_Prize_Click()
	if (HuaShanLunJian2_BattleTable_CurNameType == HuaShanLunJian2_BattleTable_NameType.team) then
		-- 当前展示的是战队名 切换成服务器名
		HuaShanLunJian2_BattleTable_CurNameType = HuaShanLunJian2_BattleTable_NameType.world
	else
		-- 当前展示的是服务器名 切换成战队名
		HuaShanLunJian2_BattleTable_CurNameType = HuaShanLunJian2_BattleTable_NameType.team
	end

	if (HuaShanLunJian2_BattleTable_CurPageType == HuaShanLunJian2_BattleTable_PageType.group) then
		-- 小组赛
		HuaShanLunJian2_BattleTable_UpdateGroupBattleInfo()
	else
		-- 总决赛
		HuaShanLunJian2_BattleTable_UpdateFinalBattleInfo()
	end
end -- end func HuaShanLunJian2_BattleTable_Prize_Click()
--*************************************************************************************************
--
--*************************************************************************************************

function HuaShanLunJian2_BattleTable_InitMatchCtrl()
	-- 小组赛队伍
	if (HuaShanLunJian2_BattleTable_GroupBattleCtrlList == nil) then
		HuaShanLunJian2_BattleTable_GroupBattleCtrlList = {}
	end
	-- 小组赛 第一轮参赛队伍
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][1] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][1].btn = HuaShanLunJian2_BattleTable_Name1BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][1].txt = HuaShanLunJian2_BattleTable_Name1
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][1].ani = HuaShanLunJian2_BattleTable_Name1Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][1].my = HuaShanLunJian2_BattleTable_Name1_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][1].arg = 1
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][2] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][2].btn = HuaShanLunJian2_BattleTable_Name2BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][2].txt = HuaShanLunJian2_BattleTable_Name2
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][2].ani = HuaShanLunJian2_BattleTable_Name2Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][2].my = HuaShanLunJian2_BattleTable_Name2_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][2].arg = 2
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][3] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][3].btn = HuaShanLunJian2_BattleTable_Name3BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][3].txt = HuaShanLunJian2_BattleTable_Name3
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][3].ani = HuaShanLunJian2_BattleTable_Name3Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][3].my = HuaShanLunJian2_BattleTable_Name3_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][3].arg = 3
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][4] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][4].btn = HuaShanLunJian2_BattleTable_Name4BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][4].txt = HuaShanLunJian2_BattleTable_Name4
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][4].ani = HuaShanLunJian2_BattleTable_Name4Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][4].my = HuaShanLunJian2_BattleTable_Name4_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][4].arg = 4
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][5] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][5].btn = HuaShanLunJian2_BattleTable_Name5BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][5].txt = HuaShanLunJian2_BattleTable_Name5
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][5].ani = HuaShanLunJian2_BattleTable_Name5Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][5].my = HuaShanLunJian2_BattleTable_Name5_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][5].arg = 5
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][6] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][6].btn = HuaShanLunJian2_BattleTable_Name6BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][6].txt = HuaShanLunJian2_BattleTable_Name6
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][6].ani = HuaShanLunJian2_BattleTable_Name6Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][6].my = HuaShanLunJian2_BattleTable_Name6_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][6].arg = 6
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][7] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][7].btn = HuaShanLunJian2_BattleTable_Name7BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][7].txt = HuaShanLunJian2_BattleTable_Name7
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][7].ani = HuaShanLunJian2_BattleTable_Name7Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][7].my = HuaShanLunJian2_BattleTable_Name7_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][7].arg = 7
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][8] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][8].btn = HuaShanLunJian2_BattleTable_Name8BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][8].txt = HuaShanLunJian2_BattleTable_Name8
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][8].ani = HuaShanLunJian2_BattleTable_Name8Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][8].my = HuaShanLunJian2_BattleTable_Name8_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][8].arg = 8
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][9] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][9].btn = HuaShanLunJian2_BattleTable_Name9BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][9].txt = HuaShanLunJian2_BattleTable_Name9
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][9].ani = HuaShanLunJian2_BattleTable_Name9Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][9].my = HuaShanLunJian2_BattleTable_Name9_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][9].arg = 9
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][10] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][10].btn = HuaShanLunJian2_BattleTable_Name10BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][10].txt = HuaShanLunJian2_BattleTable_Name10
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][10].ani = HuaShanLunJian2_BattleTable_Name10Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][10].my = HuaShanLunJian2_BattleTable_Name10_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][10].arg = 10
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][11] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][11].btn = HuaShanLunJian2_BattleTable_Name11BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][11].txt = HuaShanLunJian2_BattleTable_Name11
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][11].ani = HuaShanLunJian2_BattleTable_Name11Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][11].my = HuaShanLunJian2_BattleTable_Name11_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][11].arg = 11
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][12] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][12].btn = HuaShanLunJian2_BattleTable_Name12BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][12].txt = HuaShanLunJian2_BattleTable_Name12
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][12].ani = HuaShanLunJian2_BattleTable_Name12Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][12].my = HuaShanLunJian2_BattleTable_Name12_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][12].arg = 12
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][13] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][13].btn = HuaShanLunJian2_BattleTable_Name13BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][13].txt = HuaShanLunJian2_BattleTable_Name13
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][13].ani = HuaShanLunJian2_BattleTable_Name13Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][13].my = HuaShanLunJian2_BattleTable_Name13_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][13].arg = 13
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][14] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][14].btn = HuaShanLunJian2_BattleTable_Name14BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][14].txt = HuaShanLunJian2_BattleTable_Name14
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][14].ani = HuaShanLunJian2_BattleTable_Name14Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][14].my = HuaShanLunJian2_BattleTable_Name14_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][14].arg = 14
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][15] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][15].btn = HuaShanLunJian2_BattleTable_Name15BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][15].txt = HuaShanLunJian2_BattleTable_Name15
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][15].ani = HuaShanLunJian2_BattleTable_Name15Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][15].my = HuaShanLunJian2_BattleTable_Name15_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][15].arg = 15
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][16] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][16].btn = HuaShanLunJian2_BattleTable_Name16BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][16].txt = HuaShanLunJian2_BattleTable_Name16
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][16].ani = HuaShanLunJian2_BattleTable_Name16Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][16].my = HuaShanLunJian2_BattleTable_Name16_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][16].arg = 16
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][17] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][17].btn = HuaShanLunJian2_BattleTable_Name17BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][17].txt = HuaShanLunJian2_BattleTable_Name17
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][17].ani = HuaShanLunJian2_BattleTable_Name17Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][17].my = HuaShanLunJian2_BattleTable_Name17_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][17].arg = 17
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][18] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][18].btn = HuaShanLunJian2_BattleTable_Name18BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][18].txt = HuaShanLunJian2_BattleTable_Name18
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][18].ani = HuaShanLunJian2_BattleTable_Name18Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][18].my = HuaShanLunJian2_BattleTable_Name18_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][18].arg = 18
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][19] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][19].btn = HuaShanLunJian2_BattleTable_Name19BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][19].txt = HuaShanLunJian2_BattleTable_Name19
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][19].ani = HuaShanLunJian2_BattleTable_Name19Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][19].my = HuaShanLunJian2_BattleTable_Name19_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][19].arg = 19
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][20] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][20].btn = HuaShanLunJian2_BattleTable_Name20BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][20].txt = HuaShanLunJian2_BattleTable_Name20
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][20].ani = HuaShanLunJian2_BattleTable_Name20Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][20].my = HuaShanLunJian2_BattleTable_Name20_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][20].arg = 20
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][21] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][21].btn = HuaShanLunJian2_BattleTable_Name21BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][21].txt = HuaShanLunJian2_BattleTable_Name21
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][21].ani = HuaShanLunJian2_BattleTable_Name21Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][21].my = HuaShanLunJian2_BattleTable_Name21_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][21].arg = 21
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][22] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][22].btn = HuaShanLunJian2_BattleTable_Name22BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][22].txt = HuaShanLunJian2_BattleTable_Name22
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][22].ani = HuaShanLunJian2_BattleTable_Name22Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][22].my = HuaShanLunJian2_BattleTable_Name22_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][22].arg = 22
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][23] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][23].btn = HuaShanLunJian2_BattleTable_Name23BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][23].txt = HuaShanLunJian2_BattleTable_Name23
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][23].ani = HuaShanLunJian2_BattleTable_Name23Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][23].my = HuaShanLunJian2_BattleTable_Name23_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][23].arg = 23
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][24] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][24].btn = HuaShanLunJian2_BattleTable_Name24BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][24].txt = HuaShanLunJian2_BattleTable_Name24
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][24].ani = HuaShanLunJian2_BattleTable_Name24Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][24].my = HuaShanLunJian2_BattleTable_Name24_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][24].arg = 24
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][25] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][25].btn = HuaShanLunJian2_BattleTable_Name25BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][25].txt = HuaShanLunJian2_BattleTable_Name25
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][25].ani = HuaShanLunJian2_BattleTable_Name25Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][25].my = HuaShanLunJian2_BattleTable_Name25_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][25].arg = 25
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][26] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][26].btn = HuaShanLunJian2_BattleTable_Name26BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][26].txt = HuaShanLunJian2_BattleTable_Name26
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][26].ani = HuaShanLunJian2_BattleTable_Name26Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][26].my = HuaShanLunJian2_BattleTable_Name26_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][26].arg = 26
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][27] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][27].btn = HuaShanLunJian2_BattleTable_Name27BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][27].txt = HuaShanLunJian2_BattleTable_Name27
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][27].ani = HuaShanLunJian2_BattleTable_Name27Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][27].my = HuaShanLunJian2_BattleTable_Name27_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][27].arg = 27
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][28] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][28].btn = HuaShanLunJian2_BattleTable_Name28BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][28].txt = HuaShanLunJian2_BattleTable_Name28
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][28].ani = HuaShanLunJian2_BattleTable_Name28Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][28].my = HuaShanLunJian2_BattleTable_Name28_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][28].arg = 28
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][29] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][29].btn = HuaShanLunJian2_BattleTable_Name29BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][29].txt = HuaShanLunJian2_BattleTable_Name29
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][29].ani = HuaShanLunJian2_BattleTable_Name29Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][29].my = HuaShanLunJian2_BattleTable_Name29_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][29].arg = 29
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][30] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][30].btn = HuaShanLunJian2_BattleTable_Name30BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][30].txt = HuaShanLunJian2_BattleTable_Name30
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][30].ani = HuaShanLunJian2_BattleTable_Name30Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][30].my = HuaShanLunJian2_BattleTable_Name30_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][30].arg = 30
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][31] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][31].btn = HuaShanLunJian2_BattleTable_Name31BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][31].txt = HuaShanLunJian2_BattleTable_Name31
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][31].ani = HuaShanLunJian2_BattleTable_Name31Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][31].my = HuaShanLunJian2_BattleTable_Name31_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][31].arg = 31
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][32] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][32].btn = HuaShanLunJian2_BattleTable_Name32BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][32].txt = HuaShanLunJian2_BattleTable_Name32
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][32].ani = HuaShanLunJian2_BattleTable_Name32Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][32].my = HuaShanLunJian2_BattleTable_Name32_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[1][32].arg = 32
	-- 小组赛 第二轮参赛队伍
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][1] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][1].btn = HuaShanLunJian2_BattleTable_Name33BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][1].txt = HuaShanLunJian2_BattleTable_Name33
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][1].ani = HuaShanLunJian2_BattleTable_Name33Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][1].my = HuaShanLunJian2_BattleTable_Name33_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][1].arg = 33
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][2] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][2].btn = HuaShanLunJian2_BattleTable_Name34BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][2].txt = HuaShanLunJian2_BattleTable_Name34
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][2].ani = HuaShanLunJian2_BattleTable_Name34Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][2].my = HuaShanLunJian2_BattleTable_Name34_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][2].arg = 34
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][3] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][3].btn = HuaShanLunJian2_BattleTable_Name35BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][3].txt = HuaShanLunJian2_BattleTable_Name35
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][3].ani = HuaShanLunJian2_BattleTable_Name35Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][3].my = HuaShanLunJian2_BattleTable_Name35_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][3].arg = 35
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][4] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][4].btn = HuaShanLunJian2_BattleTable_Name36BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][4].txt = HuaShanLunJian2_BattleTable_Name36
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][4].ani = HuaShanLunJian2_BattleTable_Name36Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][4].my = HuaShanLunJian2_BattleTable_Name36_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][4].arg = 36
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][5] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][5].btn = HuaShanLunJian2_BattleTable_Name37BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][5].txt = HuaShanLunJian2_BattleTable_Name37
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][5].ani = HuaShanLunJian2_BattleTable_Name37Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][5].my = HuaShanLunJian2_BattleTable_Name37_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][5].arg = 37
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][6] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][6].btn = HuaShanLunJian2_BattleTable_Name38BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][6].txt = HuaShanLunJian2_BattleTable_Name38
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][6].ani = HuaShanLunJian2_BattleTable_Name38Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][6].my = HuaShanLunJian2_BattleTable_Name38_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][6].arg = 38
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][7] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][7].btn = HuaShanLunJian2_BattleTable_Name39BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][7].txt = HuaShanLunJian2_BattleTable_Name39
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][7].ani = HuaShanLunJian2_BattleTable_Name39Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][7].my = HuaShanLunJian2_BattleTable_Name39_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][7].arg = 39
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][8] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][8].btn = HuaShanLunJian2_BattleTable_Name40BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][8].txt = HuaShanLunJian2_BattleTable_Name40
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][8].ani = HuaShanLunJian2_BattleTable_Name40Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][8].my = HuaShanLunJian2_BattleTable_Name40_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][8].arg = 40
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][9] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][9].btn = HuaShanLunJian2_BattleTable_Name41BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][9].txt = HuaShanLunJian2_BattleTable_Name41
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][9].ani = HuaShanLunJian2_BattleTable_Name41Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][9].my = HuaShanLunJian2_BattleTable_Name41_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][9].arg = 41
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][10] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][10].btn = HuaShanLunJian2_BattleTable_Name42BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][10].txt = HuaShanLunJian2_BattleTable_Name42
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][10].ani = HuaShanLunJian2_BattleTable_Name42Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][10].my = HuaShanLunJian2_BattleTable_Name42_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][10].arg = 42
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][11] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][11].btn = HuaShanLunJian2_BattleTable_Name43BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][11].txt = HuaShanLunJian2_BattleTable_Name43
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][11].ani = HuaShanLunJian2_BattleTable_Name43Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][11].my = HuaShanLunJian2_BattleTable_Name43_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][11].arg = 43
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][12] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][12].btn = HuaShanLunJian2_BattleTable_Name44BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][12].txt = HuaShanLunJian2_BattleTable_Name44
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][12].ani = HuaShanLunJian2_BattleTable_Name44Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][12].my = HuaShanLunJian2_BattleTable_Name44_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][12].arg = 44
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][13] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][13].btn = HuaShanLunJian2_BattleTable_Name45BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][13].txt = HuaShanLunJian2_BattleTable_Name45
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][13].ani = HuaShanLunJian2_BattleTable_Name45Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][13].my = HuaShanLunJian2_BattleTable_Name45_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][13].arg = 45
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][14] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][14].btn = HuaShanLunJian2_BattleTable_Name46BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][14].txt = HuaShanLunJian2_BattleTable_Name46
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][14].ani = HuaShanLunJian2_BattleTable_Name46Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][14].my = HuaShanLunJian2_BattleTable_Name46_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][14].arg = 46
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][15] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][15].btn = HuaShanLunJian2_BattleTable_Name47BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][15].txt = HuaShanLunJian2_BattleTable_Name47
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][15].ani = HuaShanLunJian2_BattleTable_Name47Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][15].my = HuaShanLunJian2_BattleTable_Name47_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][15].arg = 47
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][16] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][16].btn = HuaShanLunJian2_BattleTable_Name48BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][16].txt = HuaShanLunJian2_BattleTable_Name48
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][16].ani = HuaShanLunJian2_BattleTable_Name48Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][16].my = HuaShanLunJian2_BattleTable_Name48_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[2][16].arg = 48
	-- 小组赛 第三轮参赛队伍
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][1] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][1].btn = HuaShanLunJian2_BattleTable_Name49BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][1].txt = HuaShanLunJian2_BattleTable_Name49
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][1].ani = HuaShanLunJian2_BattleTable_Name49Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][1].my = HuaShanLunJian2_BattleTable_Name49_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][1].arg = 49
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][2] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][2].btn = HuaShanLunJian2_BattleTable_Name50BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][2].txt = HuaShanLunJian2_BattleTable_Name50
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][2].ani = HuaShanLunJian2_BattleTable_Name50Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][2].my = HuaShanLunJian2_BattleTable_Name50_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][2].arg = 50
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][3] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][3].btn = HuaShanLunJian2_BattleTable_Name51BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][3].txt = HuaShanLunJian2_BattleTable_Name51
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][3].ani = HuaShanLunJian2_BattleTable_Name51Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][3].my = HuaShanLunJian2_BattleTable_Name51_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][3].arg = 51
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][4] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][4].btn = HuaShanLunJian2_BattleTable_Name52BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][4].txt = HuaShanLunJian2_BattleTable_Name52
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][4].ani = HuaShanLunJian2_BattleTable_Name52Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][4].my = HuaShanLunJian2_BattleTable_Name52_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][4].arg = 52
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][5] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][5].btn = HuaShanLunJian2_BattleTable_Name53BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][5].txt = HuaShanLunJian2_BattleTable_Name53
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][5].ani = HuaShanLunJian2_BattleTable_Name53Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][5].my = HuaShanLunJian2_BattleTable_Name53_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][5].arg = 53
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][6] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][6].btn = HuaShanLunJian2_BattleTable_Name54BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][6].txt = HuaShanLunJian2_BattleTable_Name54
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][6].ani = HuaShanLunJian2_BattleTable_Name54Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][6].my = HuaShanLunJian2_BattleTable_Name54_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][6].arg = 54
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][7] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][7].btn = HuaShanLunJian2_BattleTable_Name55BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][7].txt = HuaShanLunJian2_BattleTable_Name55
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][7].ani = HuaShanLunJian2_BattleTable_Name55Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][7].my = HuaShanLunJian2_BattleTable_Name55_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][7].arg = 55
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][8] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][8].btn = HuaShanLunJian2_BattleTable_Name56BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][8].txt = HuaShanLunJian2_BattleTable_Name56
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][8].ani = HuaShanLunJian2_BattleTable_Name56Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][8].my = HuaShanLunJian2_BattleTable_Name56_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[3][8].arg = 56
	-- 小组赛 第四轮参赛队伍
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][1] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][1].btn = HuaShanLunJian2_BattleTable_Name57BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][1].txt = HuaShanLunJian2_BattleTable_Name57
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][1].ani = HuaShanLunJian2_BattleTable_Name57Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][1].my = HuaShanLunJian2_BattleTable_Name57_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][1].arg = 57
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][2] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][2].btn = HuaShanLunJian2_BattleTable_Name58BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][2].txt = HuaShanLunJian2_BattleTable_Name58
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][2].ani = HuaShanLunJian2_BattleTable_Name58Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][2].my = HuaShanLunJian2_BattleTable_Name58_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][2].arg = 58
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][3] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][3].btn = HuaShanLunJian2_BattleTable_Name59BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][3].txt = HuaShanLunJian2_BattleTable_Name59
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][3].ani = HuaShanLunJian2_BattleTable_Name59Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][3].my = HuaShanLunJian2_BattleTable_Name59_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][3].arg = 59
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][4] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][4].btn = HuaShanLunJian2_BattleTable_Name60BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][4].txt = HuaShanLunJian2_BattleTable_Name60
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][4].ani = HuaShanLunJian2_BattleTable_Name60Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][4].my = HuaShanLunJian2_BattleTable_Name60_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[4][4].arg = 60
	-- 小组赛 第五轮参赛队伍
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[5] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[5][1] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[5][1].btn = HuaShanLunJian2_BattleTable_Name61BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[5][1].txt = HuaShanLunJian2_BattleTable_Name61
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[5][1].ani = HuaShanLunJian2_BattleTable_Name61Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[5][1].my = HuaShanLunJian2_BattleTable_Name61_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[5][1].arg = 61
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[5][2] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[5][2].btn = HuaShanLunJian2_BattleTable_Name62BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[5][2].txt = HuaShanLunJian2_BattleTable_Name62
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[5][2].ani = HuaShanLunJian2_BattleTable_Name62Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[5][2].my = HuaShanLunJian2_BattleTable_Name62_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[5][2].arg = 62
	-- 小组赛 胜出战队
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[6] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[6][1] = {}
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[6][1].btn = HuaShanLunJian2_BattleTable_Table63BK
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[6][1].txt = HuaShanLunJian2_BattleTable_Name63
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[6][1].ani = HuaShanLunJian2_BattleTable_Name63Animate
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[6][1].my = HuaShanLunJian2_BattleTable_Name63_My
	HuaShanLunJian2_BattleTable_GroupBattleCtrlList[6][1].arg = 63

	-- 小组赛 队伍连线
	if (HuaShanLunJian2_BattleTable_GroupBattleLineList == nil) then
		HuaShanLunJian2_BattleTable_GroupBattleLineList = {}
	end
	-- 小组赛 第一轮胜出队伍连线
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1] = {}
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][1] = HuaShanLunJian2_BattleTable_Line1
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][2] = HuaShanLunJian2_BattleTable_Line2
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][3] = HuaShanLunJian2_BattleTable_Line3
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][4] = HuaShanLunJian2_BattleTable_Line4
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][5] = HuaShanLunJian2_BattleTable_Line5
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][6] = HuaShanLunJian2_BattleTable_Line6
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][7] = HuaShanLunJian2_BattleTable_Line7
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][8] = HuaShanLunJian2_BattleTable_Line8
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][9] = HuaShanLunJian2_BattleTable_Line9
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][10] = HuaShanLunJian2_BattleTable_Line10
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][11] = HuaShanLunJian2_BattleTable_Line11
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][12] = HuaShanLunJian2_BattleTable_Line12
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][13] = HuaShanLunJian2_BattleTable_Line13
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][14] = HuaShanLunJian2_BattleTable_Line14
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][15] = HuaShanLunJian2_BattleTable_Line15
	HuaShanLunJian2_BattleTable_GroupBattleLineList[1][16] = HuaShanLunJian2_BattleTable_Line16
	-- 小组赛 第二轮胜出队伍连线
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2] = {}
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][1] = HuaShanLunJian2_BattleTable_Line17
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][2] = HuaShanLunJian2_BattleTable_Line18
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][3] = HuaShanLunJian2_BattleTable_Line19
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][4] = HuaShanLunJian2_BattleTable_Line20
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][5] = HuaShanLunJian2_BattleTable_Line21
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][6] = HuaShanLunJian2_BattleTable_Line22
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][7] = HuaShanLunJian2_BattleTable_Line23
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][8] = HuaShanLunJian2_BattleTable_Line24
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][9] = HuaShanLunJian2_BattleTable_Line25
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][10] = HuaShanLunJian2_BattleTable_Line26
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][11] = HuaShanLunJian2_BattleTable_Line27
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][12] = HuaShanLunJian2_BattleTable_Line28
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][13] = HuaShanLunJian2_BattleTable_Line29
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][14] = HuaShanLunJian2_BattleTable_Line30
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][15] = HuaShanLunJian2_BattleTable_Line31
	HuaShanLunJian2_BattleTable_GroupBattleLineList[2][16] = HuaShanLunJian2_BattleTable_Line32
	-- 小组赛 第三轮胜出队伍连线
	HuaShanLunJian2_BattleTable_GroupBattleLineList[3] = {}
	HuaShanLunJian2_BattleTable_GroupBattleLineList[3][1] = HuaShanLunJian2_BattleTable_Line33
	HuaShanLunJian2_BattleTable_GroupBattleLineList[3][2] = HuaShanLunJian2_BattleTable_Line34
	HuaShanLunJian2_BattleTable_GroupBattleLineList[3][3] = HuaShanLunJian2_BattleTable_Line35
	HuaShanLunJian2_BattleTable_GroupBattleLineList[3][4] = HuaShanLunJian2_BattleTable_Line36
	HuaShanLunJian2_BattleTable_GroupBattleLineList[3][5] = HuaShanLunJian2_BattleTable_Line37
	HuaShanLunJian2_BattleTable_GroupBattleLineList[3][6] = HuaShanLunJian2_BattleTable_Line38
	HuaShanLunJian2_BattleTable_GroupBattleLineList[3][7] = HuaShanLunJian2_BattleTable_Line39
	HuaShanLunJian2_BattleTable_GroupBattleLineList[3][8] = HuaShanLunJian2_BattleTable_Line40
	-- 小组赛 第四轮胜出队伍连线
	HuaShanLunJian2_BattleTable_GroupBattleLineList[4] = {}
	HuaShanLunJian2_BattleTable_GroupBattleLineList[4][1] = HuaShanLunJian2_BattleTable_Line41
	HuaShanLunJian2_BattleTable_GroupBattleLineList[4][2] = HuaShanLunJian2_BattleTable_Line42
	HuaShanLunJian2_BattleTable_GroupBattleLineList[4][3] = HuaShanLunJian2_BattleTable_Line43
	HuaShanLunJian2_BattleTable_GroupBattleLineList[4][4] = HuaShanLunJian2_BattleTable_Line44

	-- 决赛队伍
	if (HuaShanLunJian2_BattleTable_FinalBattleCtrlList == nil) then
		HuaShanLunJian2_BattleTable_FinalBattleCtrlList = {}
	end
	-- 决赛 第一轮参赛队伍
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][1] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][1].btn = HuaShanLunJian2_BattleTable_Final_Name1BK
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][1].txt = HuaShanLunJian2_BattleTable_Final_Name1
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][1].ani = HuaShanLunJian2_BattleTable_Final_Name1Animate
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][1].my = HuaShanLunJian2_BattleTable_Final_Name1_My
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][1].arg = 1
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][2] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][2].btn = HuaShanLunJian2_BattleTable_Final_Name2BK
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][2].txt = HuaShanLunJian2_BattleTable_Final_Name2
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][2].ani = HuaShanLunJian2_BattleTable_Final_Name2Animate
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][2].my = HuaShanLunJian2_BattleTable_Final_Name2_My
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][2].arg = 2
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][3] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][3].btn = HuaShanLunJian2_BattleTable_Final_Name3BK
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][3].txt = HuaShanLunJian2_BattleTable_Final_Name3
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][3].ani = HuaShanLunJian2_BattleTable_Final_Name3Animate
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][3].my = HuaShanLunJian2_BattleTable_Final_Name3_My
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][3].arg = 3
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][4] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][4].btn = HuaShanLunJian2_BattleTable_Final_Name4BK
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][4].txt = HuaShanLunJian2_BattleTable_Final_Name4
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][4].ani = HuaShanLunJian2_BattleTable_Final_Name4Animate
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][4].my = HuaShanLunJian2_BattleTable_Final_Name4_My
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][4].arg = 4
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][5] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][5].btn = HuaShanLunJian2_BattleTable_Final_Name5BK
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][5].txt = HuaShanLunJian2_BattleTable_Final_Name5
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][5].ani = HuaShanLunJian2_BattleTable_Final_Name5Animate
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][5].my = HuaShanLunJian2_BattleTable_Final_Name5_My
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][5].arg = 5
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][6] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][6].btn = HuaShanLunJian2_BattleTable_Final_Name6BK
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][6].txt = HuaShanLunJian2_BattleTable_Final_Name6
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][6].ani = HuaShanLunJian2_BattleTable_Final_Name6Animate
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][6].my = HuaShanLunJian2_BattleTable_Final_Name6_My
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][6].arg = 6
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][7] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][7].btn = HuaShanLunJian2_BattleTable_Final_Name7BK
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][7].txt = HuaShanLunJian2_BattleTable_Final_Name7
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][7].ani = HuaShanLunJian2_BattleTable_Final_Name7Animate
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][7].my = HuaShanLunJian2_BattleTable_Final_Name7_My
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][7].arg = 7
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][8] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][8].btn = HuaShanLunJian2_BattleTable_Final_Name8BK
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][8].txt = HuaShanLunJian2_BattleTable_Final_Name8
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][8].ani = HuaShanLunJian2_BattleTable_Final_Name8Animate
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][8].my = HuaShanLunJian2_BattleTable_Final_Name8_My
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[1][8].arg = 8
	-- 决赛 第二轮参赛队伍
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][1] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][1].btn = HuaShanLunJian2_BattleTable_Final_Name9BK
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][1].txt = HuaShanLunJian2_BattleTable_Final_Name9
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][1].ani = HuaShanLunJian2_BattleTable_Final_Name9Animate
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][1].my = HuaShanLunJian2_BattleTable_Final_Name9_My
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][1].arg = 9
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][2] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][2].btn = HuaShanLunJian2_BattleTable_Final_Name10BK
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][2].txt = HuaShanLunJian2_BattleTable_Final_Name10
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][2].ani = HuaShanLunJian2_BattleTable_Final_Name10Animate
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][2].my = HuaShanLunJian2_BattleTable_Final_Name10_My
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][2].arg = 10
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][3] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][3].btn = HuaShanLunJian2_BattleTable_Final_Name11BK
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][3].txt = HuaShanLunJian2_BattleTable_Final_Name11
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][3].ani = HuaShanLunJian2_BattleTable_Final_Name11Animate
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][3].my = HuaShanLunJian2_BattleTable_Final_Name11_My
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][3].arg = 11
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][4] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][4].btn = HuaShanLunJian2_BattleTable_Final_Name12BK
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][4].txt = HuaShanLunJian2_BattleTable_Final_Name12
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][4].ani = HuaShanLunJian2_BattleTable_Final_Name12Animate
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][4].my = HuaShanLunJian2_BattleTable_Final_Name12_My
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[2][4].arg = 12
	-- 决赛 第三轮参赛队伍
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[3] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[3][1] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[3][1].btn = HuaShanLunJian2_BattleTable_Final_Name13BK
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[3][1].txt = HuaShanLunJian2_BattleTable_Final_Name13
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[3][1].ani = HuaShanLunJian2_BattleTable_Final_Name13Animate
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[3][1].my = HuaShanLunJian2_BattleTable_Final_Name13_My
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[3][1].arg = 13
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[3][2] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[3][2].btn = HuaShanLunJian2_BattleTable_Final_Name14BK
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[3][2].txt = HuaShanLunJian2_BattleTable_Final_Name14
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[3][2].ani = HuaShanLunJian2_BattleTable_Final_Name14Animate
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[3][2].my = HuaShanLunJian2_BattleTable_Final_Name14_My
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[3][2].arg = 14
	-- 决赛 胜出战队
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[4] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[4][1] = {}
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[4][1].btn = HuaShanLunJian2_BattleTable_Final_Table15BK
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[4][1].txt = HuaShanLunJian2_BattleTable_Final_Name15
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[4][1].ani = HuaShanLunJian2_BattleTable_Final_Name15Animate
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[4][1].my = HuaShanLunJian2_BattleTable_Final_Name15_My
	HuaShanLunJian2_BattleTable_FinalBattleCtrlList[4][1].arg = 15

	-- 决赛 队伍连线
	if (HuaShanLunJian2_BattleTable_FinalBattleLineList == nil) then
		HuaShanLunJian2_BattleTable_FinalBattleLineList = {}
	end
	-- 决赛 第一轮胜出队伍连线
	HuaShanLunJian2_BattleTable_FinalBattleLineList[1] = {}
	HuaShanLunJian2_BattleTable_FinalBattleLineList[1][1] = HuaShanLunJian2_BattleTable_Final_Line17
	HuaShanLunJian2_BattleTable_FinalBattleLineList[1][2] = HuaShanLunJian2_BattleTable_Final_Line18
	HuaShanLunJian2_BattleTable_FinalBattleLineList[1][3] = HuaShanLunJian2_BattleTable_Final_Line19
	HuaShanLunJian2_BattleTable_FinalBattleLineList[1][4] = HuaShanLunJian2_BattleTable_Final_Line20
	HuaShanLunJian2_BattleTable_FinalBattleLineList[1][5] = HuaShanLunJian2_BattleTable_Final_Line21
	HuaShanLunJian2_BattleTable_FinalBattleLineList[1][6] = HuaShanLunJian2_BattleTable_Final_Line22
	HuaShanLunJian2_BattleTable_FinalBattleLineList[1][7] = HuaShanLunJian2_BattleTable_Final_Line23
	HuaShanLunJian2_BattleTable_FinalBattleLineList[1][8] = HuaShanLunJian2_BattleTable_Final_Line24
	-- 决赛 第二轮胜出队伍连线
	HuaShanLunJian2_BattleTable_FinalBattleLineList[2] = {}
	HuaShanLunJian2_BattleTable_FinalBattleLineList[2][1] = HuaShanLunJian2_BattleTable_Final_Line25
	HuaShanLunJian2_BattleTable_FinalBattleLineList[2][2] = HuaShanLunJian2_BattleTable_Final_Line26
	HuaShanLunJian2_BattleTable_FinalBattleLineList[2][3] = HuaShanLunJian2_BattleTable_Final_Line27
	HuaShanLunJian2_BattleTable_FinalBattleLineList[2][4] = HuaShanLunJian2_BattleTable_Final_Line28
	-- 决赛 第三轮胜出队伍连线
	HuaShanLunJian2_BattleTable_FinalBattleLineList[3] = {}
	HuaShanLunJian2_BattleTable_FinalBattleLineList[3][1] = HuaShanLunJian2_BattleTable_Final_Line29
	HuaShanLunJian2_BattleTable_FinalBattleLineList[3][2] = HuaShanLunJian2_BattleTable_Final_Line30
end -- end func HuaShanLunJian2_BattleTable_InitMatchCtrl()

-- 刷新小组赛赛况
function HuaShanLunJian2_BattleTable_UpdateGroupBattleInfo()
	HuaShanLunJian2_BattleTable_Client1:Show()
	HuaShanLunJian2_BattleTable_CheckBox1:SetCheck(1)
	HuaShanLunJian2_BattleTable_Client2:Hide()
	HuaShanLunJian2_BattleTable_CheckBox2:SetCheck(0)

	local curGroupId = HuaShanLunJian2_BattleTable_CurSelectGroup
	if (curGroupId == nil) then
		curGroupId = HuaShanLunJian2_BattleTable_GroupID.group1
		HuaShanLunJian2_BattleTable_CurSelectGroup = HuaShanLunJian2_BattleTable_GroupID.group1
	elseif (curGroupId < HuaShanLunJian2_BattleTable_GroupID.group_begin or
			curGroupId > HuaShanLunJian2_BattleTable_GroupID.groupo_end) then
		curGroupId = HuaShanLunJian2_BattleTable_GroupID.group1
		HuaShanLunJian2_BattleTable_CurSelectGroup = HuaShanLunJian2_BattleTable_GroupID.group1
	end

	HuaShanLunJian2_BattleTable_CurPageType = HuaShanLunJian2_BattleTable_PageType.group
	
	local teamType = HuaShanLunJian2_BattleTable_TeamType.tmatch

	local ctrlList = HuaShanLunJian2_BattleTable_GroupBattleCtrlList
	if (ctrlList == nil) then
		return
	end
	local lineList = HuaShanLunJian2_BattleTable_GroupBattleLineList
	if (lineList == nil) then
		return
	end

	HuaShanLunJian2_BattleTable_TeamIDTable = {}
	HuaShanLunJian2_BattleTable_CurSelectTeamID = 0

	HuaShanLunJian2_BattleTable_Client1:Show()
	HuaShanLunJian2_BattleTable_Client2:Hide()

	local myWorldId = Player:GetData("ZONEWORLDID") 

	-- 先重置一下小组战队控件显示
	for i=1, table.getn(ctrlList), 1 do
		local roundCtrlList = ctrlList[i]
		if (roundCtrlList ~= nil) then
			for j=1, table.getn(roundCtrlList), 1 do
				if (roundCtrlList[j] ~= nil) then
					roundCtrlList[j].txt:SetText("")
					roundCtrlList[j].ani:Hide()
					roundCtrlList[j].my:Hide()
				end
			end -- end for
		end
	end -- end for

	-- 重置战队连线 所有连线置灰
	for i=1, table.getn(lineList), 1 do
		local roundLineList = lineList[i]
		if (roundLineList ~= nil) then
			for j=1, table.getn(roundLineList), 1 do
				if (roundLineList[j] ~= nil) then
					roundLineList[j]:Hide()
				end
			end -- end for
		end
	end -- end for

	local maxTeamCount = XBWJHS:GetTeamMaxCount(teamType)
	for i=1, maxTeamCount, 1 do
		local teamId, worldId, teamIdx, memCount, totalLevelStar, totalVote, teamName, leaderName = XBWJHS:GetTeamDataByIndex(teamType, i-1)
		if (teamId ~= nil and teamId > 0) then
			local matchZoneId, matchIndex, matchRound, matchResult = XBWJHS:GetTeamMatchInfo(teamType, teamIdx)
			if (matchZoneId ~= nil and matchZoneId > 0 and matchZoneId == curGroupId) then
				if (matchRound <= 0) then
					-- 应该是还没开始打比赛呢
					if (ctrlList[1] ~= nil and ctrlList[1][matchIndex] ~= nil) then
						if (worldId > 0 and worldId == myWorldId) then
							ctrlList[1][matchIndex].my:Show()
						else
							ctrlList[1][matchIndex].my:Hide()
						end
						if (HuaShanLunJian2_BattleTable_CurNameType == HuaShanLunJian2_BattleTable_NameType.team) then
							-- 展示战队名
							ctrlList[1][matchIndex].txt:SetText(teamName)
						else
							-- 展示服务器名
							local serverName = DataPool:GetServerName(worldId)
							ctrlList[1][matchIndex].txt:SetText(serverName)
						end
						local ctrlArg = ctrlList[1][matchIndex].arg
						HuaShanLunJian2_BattleTable_TeamIDTable[ctrlArg] = teamId
					end
				else
					-- 至少已经打了一轮比赛了
					local roundTemp = 0
					local indexTemp = 0
					local offset = 0
					local lineIndexTemp = 0
					local lineOffset = 0
					for j=1, matchRound, 1 do
						-- 玩家有可能小组赛已经打完了还来查看小组赛的赛况 所以这里判断到小组赛后一轮
						if (j <= HuaShanLunJian2_BattleTable_GroupRoundCount) then
							roundTemp = j
							offset = offset * 2
							if (offset <= 0) then
								offset = 1
							end
							indexTemp = math.ceil(matchIndex / offset)

							if (ctrlList[roundTemp] ~= nil and ctrlList[roundTemp][indexTemp] ~= nil) then
								if (worldId > 0 and worldId == myWorldId) then
									ctrlList[roundTemp][indexTemp].my:Show()
								else
									ctrlList[roundTemp][indexTemp].my:Hide()
								end
								if (HuaShanLunJian2_BattleTable_CurNameType == HuaShanLunJian2_BattleTable_NameType.team) then
									-- 展示战队名
									ctrlList[roundTemp][indexTemp].txt:SetText(teamName)
								else
									-- 展示服务器名
									local serverName = DataPool:GetServerName(worldId)
									ctrlList[roundTemp][indexTemp].txt:SetText(serverName)
								end
								local ctrlArg = ctrlList[roundTemp][indexTemp].arg
								HuaShanLunJian2_BattleTable_TeamIDTable[ctrlArg] = teamId
							end

							-- 战队连线 因为第一轮是没有连线的 所以这里要从第二轮开始
							if (roundTemp > 1) then
								if (roundTemp == 2) then
									-- 因为第一轮出线的两个队伍共用一根连线 所以第二轮需要特殊处理
									lineOffset = 2
								else
									lineOffset = lineOffset * 2
								end
								if (lineOffset <= 0) then
									lineOffset = 1
								end

								lineIndexTemp = math.ceil(matchIndex / lineOffset)
								if (lineList[roundTemp-1] ~= nil and lineList[roundTemp-1][lineIndexTemp] ~= nil) then
									lineList[roundTemp-1][lineIndexTemp]:Show()
								end
								-- if roundTemp == table.getn(lineList) then
								-- 	if matchResult ~= nil and matchResult == HuaShanLunJian2_BattleTable_Result.win then
								-- 		lineOffset = lineOffset * 2
								-- 		if (lineOffset <= 0) then
								-- 			lineOffset = 1
								-- 		end
								-- 		lineIndexTemp = math.ceil(matchZoneId / lineOffset)
								-- 		if (lineList[roundTemp] ~= nil and lineList[roundTemp][lineIndexTemp] ~= nil) then
								-- 			lineList[roundTemp][lineIndexTemp]:Show()
								-- 		end
								-- 	end
								-- end

								if (roundTemp == 2) then
									-- 因为第一轮出线的两个队伍共用一根连线 所以第二轮需要特殊处理
									-- 第二轮处理完之后要把偏移设置成1
									lineOffset = 1
								end
							end
						else
							break
						end
					end -- end for

					-- 也许下一轮比赛还没开打 所以这里需要检查一下当前轮次的胜负 获胜的队伍填到下一轮比赛队上
					if (matchResult ~= nil and matchResult == HuaShanLunJian2_BattleTable_Result.win) then
						-- 上一轮比赛获胜了
						if (roundTemp <= HuaShanLunJian2_BattleTable_GroupRoundCount) then
							roundTemp = roundTemp + 1
							offset = offset * 2
							if (offset <= 0) then
								offset = 1
							end
							indexTemp = math.ceil(matchIndex / offset)

							if (ctrlList[roundTemp] ~= nil and ctrlList[roundTemp][indexTemp] ~= nil) then
								if (worldId > 0 and worldId == myWorldId) then
									ctrlList[roundTemp][indexTemp].my:Show()
								else
									ctrlList[roundTemp][indexTemp].my:Hide()
								end
								if (HuaShanLunJian2_BattleTable_CurNameType == HuaShanLunJian2_BattleTable_NameType.team) then
									-- 展示战队名
									ctrlList[roundTemp][indexTemp].txt:SetText(teamName)
								else
									-- 展示服务器名
									local serverName = DataPool:GetServerName(worldId)
									ctrlList[roundTemp][indexTemp].txt:SetText(serverName)
								end
								local ctrlArg = ctrlList[roundTemp][indexTemp].arg
								HuaShanLunJian2_BattleTable_TeamIDTable[ctrlArg] = teamId
							end

							-- 连线
							if (roundTemp == 2) then
								-- 因为第一轮出线的两个队伍共用一根连线 所以第二轮需要特殊处理
								lineOffset = 2
							else
								lineOffset = lineOffset * 2
							end
							if (lineOffset <= 0) then
								lineOffset = 1
							end
							lineIndexTemp = math.ceil(matchIndex / lineOffset)
							if (lineList[roundTemp-1] ~= nil and lineList[roundTemp-1][lineIndexTemp] ~= nil) then
								lineList[roundTemp-1][lineIndexTemp]:Show()
							end

							if (roundTemp == 2) then
								-- 因为第一轮出线的两个队伍共用一根连线 所以第二轮需要特殊处理
								-- 第二轮处理完之后要把偏移设置成1
								lineOffset = 1
							end
						end
					end
				end
			end
		end
	end -- end for

	if (HuaShanLunJian2_BattleTable_CurNameType == HuaShanLunJian2_BattleTable_NameType.team) then
		-- 当期展示的是战队名
		HuaShanLunJian2_BattleTable_TeamInfo:SetText("#{LLGZ_260330_212}")
	else
		-- 当前展示的是服务器名
		HuaShanLunJian2_BattleTable_TeamInfo:SetText("#{LLGZ_260330_213}")
	end
end -- end func HuaShanLunJian2_BattleTable_UpdateGroupBattleInfo()

-- 刷新决赛赛况
function HuaShanLunJian2_BattleTable_UpdateFinalBattleInfo()
	HuaShanLunJian2_BattleTable_Client1:Hide()
	HuaShanLunJian2_BattleTable_CheckBox1:SetCheck(0)
	HuaShanLunJian2_BattleTable_Client2:Show()
	HuaShanLunJian2_BattleTable_CheckBox2:SetCheck(1)

	HuaShanLunJian2_BattleTable_CurPageType = HuaShanLunJian2_BattleTable_PageType.final
	local teamType = HuaShanLunJian2_BattleTable_TeamType.tmatch

	local ctrlList = HuaShanLunJian2_BattleTable_FinalBattleCtrlList
	if (ctrlList == nil) then
		return
	end
	local lineList = HuaShanLunJian2_BattleTable_FinalBattleLineList
	if (lineList == nil) then
		return
	end

	HuaShanLunJian2_BattleTable_TeamIDTable = {}
	HuaShanLunJian2_BattleTable_CurSelectTeamID = 0

	HuaShanLunJian2_BattleTable_Client1:Hide()
	HuaShanLunJian2_BattleTable_Client2:Show()

	local myWorldId = Player:GetData("ZONEWORLDID") 

	-- 先重置一下小组战队控件显示
	for i=1, table.getn(ctrlList), 1 do
		local roundCtrlList = ctrlList[i]
		if (roundCtrlList ~= nil) then
			for j=1, table.getn(roundCtrlList), 1 do
				if (roundCtrlList[j] ~= nil) then
					roundCtrlList[j].txt:SetText("")
					roundCtrlList[j].ani:Hide()
					roundCtrlList[j].my:Hide()
				end
			end -- end for
		end
	end -- end for

	-- 重置战队连线 所有连线置灰
	for i=1, table.getn(lineList), 1 do
		local roundLineList = lineList[i]
		if (roundLineList ~= nil) then
			for j=1, table.getn(roundLineList), 1 do
				if (roundLineList[j] ~= nil) then
					roundLineList[j]:Hide()
				end
			end -- end for
		end
	end -- end for

	local maxTeamCount = XBWJHS:GetTeamMaxCount(teamType)
	for i=1, maxTeamCount, 1 do
		local teamId, worldId, teamIdx, memCount, totalLevelStar, totalVote, teamName, leaderName = XBWJHS:GetTeamDataByIndex(teamType, i-1)
		if (teamId ~= nil and teamId > 0) then
			local matchZoneId, matchIndex, matchRound, matchResult = XBWJHS:GetTeamMatchInfo(teamType, teamIdx)
			-- 这里需要判断>= 因为可能小组赛刚刚打完 决赛还没开始 所以需要显示小组赛出线的战队
			if (matchZoneId ~= nil and matchZoneId > 0 and matchRound >= HuaShanLunJian2_BattleTable_GroupRoundCount) then
				if (matchRound == HuaShanLunJian2_BattleTable_GroupRoundCount) then
					-- 可能是小组赛刚刚出线的队伍 决赛阶段还没开始打
					if (matchResult ~= nil and matchResult == HuaShanLunJian2_BattleTable_Result.win) then
						-- 这是小组赛刚刚出线的战队
						if (ctrlList[1] ~= nil and ctrlList[1][matchZoneId] ~= nil) then
							if (worldId > 0 and worldId == myWorldId) then
								ctrlList[1][matchZoneId].my:Show()
							else
								ctrlList[1][matchZoneId].my:Hide()
							end
							if (HuaShanLunJian2_BattleTable_CurNameType == HuaShanLunJian2_BattleTable_NameType.team) then
								-- 展示战队名
								ctrlList[1][matchZoneId].txt:SetText(teamName)
							else
								-- 展示服务器名
								local serverName = DataPool:GetServerName(worldId)
								ctrlList[1][matchZoneId].txt:SetText(serverName)
							end
							local ctrlArg = ctrlList[1][matchZoneId].arg
							HuaShanLunJian2_BattleTable_TeamIDTable[ctrlArg] = teamId
						end
					end
				else
					-- 决赛阶段至少已经打了一轮了
					local roundTemp = 0
					local indexTemp = 0
					local offset = 0
					local lineIndexTemp = 0
					local lineOffset = 0
					for j=1, (matchRound - HuaShanLunJian2_BattleTable_GroupRoundCount), 1 do
						roundTemp = j
						offset = offset * 2
						if (offset <= 0) then
							offset = 1
						end
						indexTemp = math.ceil(matchZoneId / offset)

						if (ctrlList[roundTemp] ~= nil and ctrlList[roundTemp][indexTemp] ~= nil) then
							if (worldId > 0 and worldId == myWorldId) then
								ctrlList[roundTemp][indexTemp].my:Show()
							else
								ctrlList[roundTemp][indexTemp].my:Hide()
							end
							if (HuaShanLunJian2_BattleTable_CurNameType == HuaShanLunJian2_BattleTable_NameType.team) then
								-- 展示战队名
								ctrlList[roundTemp][indexTemp].txt:SetText(teamName)
							else
								-- 展示服务器名
								local serverName = DataPool:GetServerName(worldId)
								ctrlList[roundTemp][indexTemp].txt:SetText(serverName)
							end
							local ctrlArg = ctrlList[roundTemp][indexTemp].arg
							HuaShanLunJian2_BattleTable_TeamIDTable[ctrlArg] = teamId
						end

						-- 战队连线 因为决赛第一轮是没有连线的 所以这里要从决赛第二轮开始
						if (roundTemp > 1) then
							lineOffset = lineOffset * 2
							if (lineOffset <= 0) then
								lineOffset = 1
							end
							lineIndexTemp = math.ceil(matchZoneId / lineOffset)

							if (lineList[roundTemp-1] ~= nil and lineList[roundTemp-1][lineIndexTemp] ~= nil) then
								lineList[roundTemp-1][lineIndexTemp]:Show()
							end
							-- if roundTemp == table.getn(lineList) then
							-- 	if matchResult ~= nil and matchResult == HuaShanLunJian2_BattleTable_Result.win then
							-- 		lineOffset = lineOffset * 2
							-- 		if (lineOffset <= 0) then
							-- 			lineOffset = 1
							-- 		end
							-- 		lineIndexTemp = math.ceil(matchZoneId / lineOffset)
							-- 		if (lineList[roundTemp] ~= nil and lineList[roundTemp][lineIndexTemp] ~= nil) then
							-- 			lineList[roundTemp][lineIndexTemp]:Show()
							-- 		end
							-- 	end
							-- end
						end
					end -- end for

					-- 也许下一轮比赛还没开打 所以这里需要检查一下当前轮次的胜负 获胜的队伍填到下一轮比赛队上
					if (matchResult ~= nil and matchResult == HuaShanLunJian2_BattleTable_Result.win) then
						-- 上一轮比赛获胜了
						if (roundTemp <= HuaShanLunJian2_BattleTable_TotalRoundCount) then
							roundTemp = roundTemp + 1
							offset = offset * 2
							if (offset <= 0) then
								offset = 1
							end
							indexTemp = math.ceil(matchZoneId / offset)

							if (ctrlList[roundTemp] ~= nil and ctrlList[roundTemp][indexTemp] ~= nil) then
								if (worldId > 0 and worldId == myWorldId) then
									ctrlList[roundTemp][indexTemp].my:Show()
								else
									ctrlList[roundTemp][indexTemp].my:Hide()
								end
								if (HuaShanLunJian2_BattleTable_CurNameType == HuaShanLunJian2_BattleTable_NameType.team) then
									-- 展示战队名
									ctrlList[roundTemp][indexTemp].txt:SetText(teamName)
								else
									-- 展示服务器名
									local serverName = DataPool:GetServerName(worldId)
									ctrlList[roundTemp][indexTemp].txt:SetText(serverName)
								end
								local ctrlArg = ctrlList[roundTemp][indexTemp].arg
								HuaShanLunJian2_BattleTable_TeamIDTable[ctrlArg] = teamId
							end

							-- 连线
							lineOffset = lineOffset * 2
							if (lineOffset <= 0) then
								lineOffset = 1
							end
							lineIndexTemp = math.ceil(matchZoneId / lineOffset)
							if (lineList[roundTemp-1] ~= nil and lineList[roundTemp-1][lineIndexTemp] ~= nil) then
								lineList[roundTemp-1][lineIndexTemp]:Show()
							end
						end
					end
				end
			end
		end
	end -- end for

	if (HuaShanLunJian2_BattleTable_CurNameType == HuaShanLunJian2_BattleTable_NameType.team) then
		-- 当期展示的是战队名
		HuaShanLunJian2_BattleTable_Final_TeamInfo:SetText("#{LLGZ_260330_212}")
	else
		-- 当前展示的是服务器名
		HuaShanLunJian2_BattleTable_Final_TeamInfo:SetText("#{LLGZ_260330_213}")
	end
end -- end func HuaShanLunJian2_BattleTable_UpdateFinalBattleInfo()