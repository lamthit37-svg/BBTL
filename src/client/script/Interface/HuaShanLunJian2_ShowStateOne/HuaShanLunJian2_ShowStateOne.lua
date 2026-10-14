-- 新比武（6v6）季后赛 原服预选赛战况UI
-- 关注NPC
local HuaShanLunJian2_ShowStateOne_CareObjId = -1
local HuaShanLunJian2_ShowStateOne_CareObjSvrId = -1
local HuaShanLunJian2_ShowStateOne_MAX_OBJ_DISTANCE = 5.0
-- 原服参赛战队数量
local HuaShanLunJian2_ShowStateOne_QualifyCount = 8
-- 当前选中的战队
local HuaShanLunJian2_ShowStateOne_CurSelectTeam = -1
-- 当前显示的战队列表
local HuaShanLunJian2_ShowStateOne_TeamList = nil
-- 默认位置
local HuaShanLunJian2_ShowStateOne_UnifiedPosition = nil

local HuaShanLunJian2_ShowStateOne_TeamType =
{
	orimatch = 1,
	tmatch = 2
} -- end HuaShanLunJian2_ShowStateOne_TeamType



function HuaShanLunJian2_ShowStateOne_PreLoad()
	this:RegisterEvent("XBWJHS_OPENORIMATCH", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func HuaShanLunJian2_ShowStateOne_PreLoad()

function HuaShanLunJian2_ShowStateOne_OnEvent(event)
	if (event == "XBWJHS_OPENORIMATCH") then
		HuaShanLunJian2_ShowStateOne_BeginCareObject(tonumber(arg0), tonumber(arg1))
		HuaShanLunJian2_ShowStateOne_QualifyCount = tonumber(arg2)
		HuaShanLunJian2_ShowStateOne_UpdateTeamList()
		HuaShanLunJian2_ShowStateOne_Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		HuaShanLunJian2_ShowStateOne_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		HuaShanLunJian2_ShowStateOne_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		HuaShanLunJian2_ShowStateOne_UnifiedPos()
	end
end -- end func HuaShanLunJian2_ShowStateOne_OnEvent()

function HuaShanLunJian2_ShowStateOne_OnLoad()
	HuaShanLunJian2_ShowStateOne_UnifiedPosition = HuaShanLunJian2_ShowStateOne_Frame:GetProperty("UnifiedPosition")
end -- end func HuaShanLunJian2_ShowStateOne_OnLoad()

-- 界面默认位置
function HuaShanLunJian2_ShowStateOne_UnifiedPos()
	if (HuaShanLunJian2_ShowStateOne_UnifiedPosition ~= nil) then
		HuaShanLunJian2_ShowStateOne_Frame:SetProperty("UnifiedPosition", HuaShanLunJian2_ShowStateOne_UnifiedPosition)
	end
end -- end func HuaShanLunJian2_ShowStateOne_UnifiedPos()

function HuaShanLunJian2_ShowStateOne_Show()
    this:Show()
end -- end func HuaShanLunJian2_ShowStateOne_Show()

function HuaShanLunJian2_ShowStateOne_Hide()
	HuaShanLunJian2_ShowStateOne_StopCareObject()
    this:Hide()
end -- end func HuaShanLunJian2_ShowStateOne_Hide()

-- 开启NPC关注
function HuaShanLunJian2_ShowStateOne_BeginCareObject(objSvrId, objId)
	HuaShanLunJian2_ShowStateOne_CareObjSvrId = objSvrId
	HuaShanLunJian2_ShowStateOne_CareObjId = objId
	if (HuaShanLunJian2_ShowStateOne_CareObjId >= 0) then
		this:CareObject(HuaShanLunJian2_ShowStateOne_CareObjId, 1, "HuaShanLunJian2_ShowStateOne")
	end
end -- end func HuaShanLunJian2_ShowStateOne_BeginCareObject()

-- 取消NPC关注
function HuaShanLunJian2_ShowStateOne_StopCareObject()
	if (HuaShanLunJian2_ShowStateOne_CareObjId >= 0) then
		this:CareObject(HuaShanLunJian2_ShowStateOne_CareObjId, 0, "HuaShanLunJian2_ShowStateOne")
		HuaShanLunJian2_ShowStateOne_CareObjId = -1
		HuaShanLunJian2_ShowStateOne_CareObjSvrId = -1
	end
end -- end func HuaShanLunJian2_ShowStateOne_StopCareObject()

--*************************************************************************************************
--*************************************************************************************************
--
--*************************************************************************************************
--*************************************************************************************************

-- 关闭按钮事件
function HuaShanLunJian2_ShowStateOne_CloseClicked()
    HuaShanLunJian2_ShowStateOne_Hide()
end -- end func HuaShanLunJian2_ShowStateOne_CloseClicked()

-- 详情按钮点击事件
function HuaShanLunJian2_ShowStateOne_TeamInfo_Clicked()
	if (HuaShanLunJian2_ShowStateOne_TeamList == nil) then
		return
	end
	if (HuaShanLunJian2_ShowStateOne_CurSelectTeam < 0) then
		return
	end

	local teamId = HuaShanLunJian2_ShowStateOne_TeamList[HuaShanLunJian2_ShowStateOne_CurSelectTeam]
	if (teamId == nil or teamId <= 0) then
		return
	end

	local svrObjId = HuaShanLunJian2_ShowStateOne_CareObjSvrId
	local objId = HuaShanLunJian2_ShowStateOne_CareObjId
	PushEvent("XBWJHS_OPENTEAMINFO", HuaShanLunJian2_ShowStateOne_TeamType.orimatch, teamId, svrObjId, objId)
end -- end func HuaShanLunJian2_ShowStateOne_TeamInfo_Clicked()

-- 战队列表点击事件
function HuaShanLunJian2_ShowStateOne_ListInfo_On_SelectionChanged()
	HuaShanLunJian2_ShowStateOne_CurSelectTeam = HuaShanLunJian2_ShowStateOne_ListInfo:GetSelectItem()
end -- end func HuaShanLunJian2_ShowStateOne_ListInfo_On_SelectionChanged()

--*************************************************************************************************
--*************************************************************************************************
--
--*************************************************************************************************
--*************************************************************************************************

function HuaShanLunJian2_ShowStateOne_UpdateTeamList()
	HuaShanLunJian2_ShowStateOne_TeamList = {}
	HuaShanLunJian2_ShowStateOne_CurSelectTeam = -1

	if (HuaShanLunJian2_ShowStateOne_QualifyCount <= 0) then
		HuaShanLunJian2_ShowStateOne_QualifyCount = 8
	end

	local teamType = HuaShanLunJian2_ShowStateOne_TeamType.orimatch
	HuaShanLunJian2_ShowStateOne_ListInfo:RemoveAllItem()
	local teamCount = 0
	for i=1, HuaShanLunJian2_ShowStateOne_QualifyCount, 1 do
		local teamId, worldId, teamIdx, memCount, totalLevelStar, totalVote, teamName, leaderName = XBWJHS:GetTeamDataByIndex(teamType, i-1)
		if (teamId ~= nil and teamId > 0) then
			-- 战队已获得参赛资格
			-- 战队id
			local teamNo = math.mod(teamId, 1000)
			local teamNoStr = string.format("%03d", teamNo)
			HuaShanLunJian2_ShowStateOne_ListInfo:AddNewItem(teamNoStr, 0, teamCount)
			-- 战队名称
			HuaShanLunJian2_ShowStateOne_ListInfo:AddNewItem(teamName, 1, teamCount)
			-- 队长
			HuaShanLunJian2_ShowStateOne_ListInfo:AddNewItem(leaderName, 2, teamCount)

			-- 战队出线状态
			local directPromote, votePromote, oriPromote = XBWJHS:GetTeamPromoteInfo(teamType, i-1)
			if (oriPromote ~= nil and oriPromote > 0) then
				if (oriPromote ~= nil and oriPromote > 0) then
					-- 战队已出线
					HuaShanLunJian2_ShowStateOne_ListInfo:AddNewItem("#{LLGZ_260330_60}", 3, teamCount)
				else
					HuaShanLunJian2_ShowStateOne_ListInfo:AddNewItem("", 3, teamCount)
				end
			else
				HuaShanLunJian2_ShowStateOne_ListInfo:AddNewItem("", 3, teamCount)
			end

			HuaShanLunJian2_ShowStateOne_TeamList[teamCount] = teamId
			teamCount = teamCount + 1
		end
	end -- end for

	if (teamCount > 0) then
		HuaShanLunJian2_ShowStateOne_CurSelectTeam = 0
		HuaShanLunJian2_ShowStateOne_ListInfo:SetSelectItem(0)
	end
end -- end func HuaShanLunJian2_ShowStateOne_UpdateTeamList()