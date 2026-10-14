-- 新比武（6v6）季后赛 战队查看以及投票UI
-- 关注NPC
local HuaShanLunJian2_CreatTeamList_CareObjId = -1
local HuaShanLunJian2_CreatTeamList_CareObjSvrId = -1
local HuaShanLunJian2_CreatTeamList_MAX_OBJ_DISTANCE = 5.0
-- 当前选中的战队
local HuaShanLunJian2_CreatTeamList_CurSelectTeam = -1
-- 当前显示的战队列表
local HuaShanLunJian2_CreatTeamList_TeamList = nil
-- 默认位置
local HuaShanLunJian2_CreatTeamList_UnifiedPosition = nil

local HuaShanLunJian2_CreatTeamList_TeamType =
{
	orimatch = 1,
	tmatch = 2
} -- end HuaShanLunJian2_CreatTeamList_TeamType

function HuaShanLunJian2_CreatTeamList_PreLoad()
	this:RegisterEvent("XBWJHS_OPENTEAMLIST", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func HuaShanLunJian2_CreatTeamList_PreLoad()

function HuaShanLunJian2_CreatTeamList_OnEvent(event)
	if (event == "XBWJHS_OPENTEAMLIST") then
		HuaShanLunJian2_CreatTeamList_BeginCareObject(tonumber(arg0), tonumber(arg1))
		HuaShanLunJian2_CreatTeamList_UpdateTeamList(tonumber(arg2))
		HuaShanLunJian2_CreatTeamList_Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		HuaShanLunJian2_CreatTeamList_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		HuaShanLunJian2_CreatTeamList_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		HuaShanLunJian2_CreatTeamList_UnifiedPos()
	end
end -- end func HuaShanLunJian2_CreatTeamList_OnEvent()

function HuaShanLunJian2_CreatTeamList_OnLoad()
	HuaShanLunJian2_CreatTeamList_UnifiedPosition = HuaShanLunJian2_CreatTeamList_Frame:GetProperty("UnifiedPosition")
end -- end func HuaShanLunJian2_CreatTeamList_OnLoad()

-- 界面默认位置
function HuaShanLunJian2_CreatTeamList_UnifiedPos()
	if (HuaShanLunJian2_CreatTeamList_UnifiedPosition ~= nil) then
		HuaShanLunJian2_CreatTeamList_Frame:SetProperty("UnifiedPosition", HuaShanLunJian2_CreatTeamList_UnifiedPosition)
	end
end -- end func HuaShanLunJian2_CreatTeamList_UnifiedPos()

function HuaShanLunJian2_CreatTeamList_Show()
    this:Show()
end -- end func HuaShanLunJian2_CreatTeamList_Show()

function HuaShanLunJian2_CreatTeamList_Hide()
	HuaShanLunJian2_CreatTeamList_StopCareObject()
    this:Hide()
end -- end func HuaShanLunJian2_CreatTeamList_Hide()

-- 开启NPC关注
function HuaShanLunJian2_CreatTeamList_BeginCareObject(objSvrId, objId)
	HuaShanLunJian2_CreatTeamList_CareObjSvrId = objSvrId
	HuaShanLunJian2_CreatTeamList_CareObjId = objId
	if (HuaShanLunJian2_CreatTeamList_CareObjId >= 0) then
		this:CareObject(HuaShanLunJian2_CreatTeamList_CareObjId, 1, "HuaShanLunJian2_CreatTeamList")
	end
end -- end func HuaShanLunJian2_CreatTeamList_BeginCareObject()

-- 取消NPC关注
function HuaShanLunJian2_CreatTeamList_StopCareObject()
	if (HuaShanLunJian2_CreatTeamList_CareObjId >= 0) then
		this:CareObject(HuaShanLunJian2_CreatTeamList_CareObjId, 0, "HuaShanLunJian2_CreatTeamList")
		HuaShanLunJian2_CreatTeamList_CareObjId = -1
		HuaShanLunJian2_CreatTeamList_CareObjSvrId = -1
	end
end -- end func HuaShanLunJian2_CreatTeamList_StopCareObject()

--*************************************************************************************************
--*************************************************************************************************
--
--*************************************************************************************************
--*************************************************************************************************

-- 关闭按钮事件
function HuaShanLunJian2_CreatTeamList_CloseClicked()
    HuaShanLunJian2_CreatTeamList_Hide()
end -- end func HuaShanLunJian2_CreatTeamList_CloseClicked()

-- 说明帮助按钮事件
function HuaShanLunJian2_CreatTeamList_ExplainText_Help_Clicked()
end -- end func HuaShanLunJian2_CreatTeamList_ExplainText_Help_Clicked()

-- 查看战队详情按钮事件
function HuaShanLunJian2_CreatTeamList_TeamInfo_Clicked()
	if (HuaShanLunJian2_CreatTeamList_TeamList == nil) then
		return
	end
	if (HuaShanLunJian2_CreatTeamList_CurSelectTeam < 0) then
		return
	end

	local teamId = HuaShanLunJian2_CreatTeamList_TeamList[HuaShanLunJian2_CreatTeamList_CurSelectTeam]
	if (teamId == nil or teamId <= 0) then
		return
	end

	local svrObjId = HuaShanLunJian2_CreatTeamList_CareObjSvrId
	local objId = HuaShanLunJian2_CreatTeamList_CareObjId
	PushEvent("XBWJHS_OPENTEAMINFO", HuaShanLunJian2_CreatTeamList_TeamType.orimatch, teamId, svrObjId, objId)
end -- end func HuaShanLunJian2_CreatTeamList_TeamInfo_Clicked()

-- 投票按钮事件
function HuaShanLunJian2_CreatTeamList_TeamInfo_Clicked2()
	if (HuaShanLunJian2_CreatTeamList_CurSelectTeam < 0) then
		PushDebugMessage("#{LLGZ_260330_49}")
		return
	end

	local teamId = HuaShanLunJian2_CreatTeamList_TeamList[HuaShanLunJian2_CreatTeamList_CurSelectTeam]
	if (teamId == nil or teamId <= 0) then
		PushDebugMessage("#{LLGZ_260330_49}")
		return
	end

	Clear_XSCRIPT()
        Set_XSCRIPT_ScriptID(892003)
		Set_XSCRIPT_Function_Name("CCallBack_VoteForTeam")
		Set_XSCRIPT_Parameter(0, HuaShanLunJian2_CreatTeamList_CareObjSvrId)
        Set_XSCRIPT_Parameter(1, teamId)
        Set_XSCRIPT_ParamCount(2)
    Send_XSCRIPT()
end -- end func HuaShanLunJian2_CreatTeamList_TeamInfo_Clicked2()

-- 战队列表点击事件
function HuaShanLunJian2_CreatTeamList_ListInfo_On_SelectionChanged()
	HuaShanLunJian2_CreatTeamList_CurSelectTeam = HuaShanLunJian2_CreatTeamList_ListInfo:GetSelectItem()
	HuaShanLunJian2_CreatTeamList_TeamVote:SetText("#{LLGZ_260330_46}")
	HuaShanLunJian2_CreatTeamList_TeamVote:Enable()
end -- end func HuaShanLunJian2_CreatTeamList_ListInfo_On_SelectionChanged()

--*************************************************************************************************
--*************************************************************************************************
--
--*************************************************************************************************
--*************************************************************************************************

-- 更新战队列表
function HuaShanLunJian2_CreatTeamList_UpdateTeamList(isInVote)
	HuaShanLunJian2_CreatTeamList_TeamList = {}
	HuaShanLunJian2_CreatTeamList_CurSelectTeam = -1
	HuaShanLunJian2_CreatTeamList_TeamVote:SetText("#{LLGZ_260330_147}")
	HuaShanLunJian2_CreatTeamList_TeamVote:Disable()

	local teamType = HuaShanLunJian2_CreatTeamList_TeamType.orimatch
	HuaShanLunJian2_CreatTeamList_ListInfo:RemoveAllItem()
	local maxTeamCount = XBWJHS:GetTeamMaxCount(teamType)
	local teamCount = 0
	for i=1, maxTeamCount, 1 do
		local teamId, worldId, teamIdx, memCount, totalLevelStar, totalVote, teamName, leaderName = XBWJHS:GetTeamDataByIndex(teamType, i-1)
		if (teamId ~= nil and teamId > 0) then
			local promoteFlag = 0
			local directPromote, votePromote, oriPromote = XBWJHS:GetTeamPromoteInfo(teamType, i-1)
			if (directPromote ~= nil and votePromote ~= nil and oriPromote ~= nil) then
				if (directPromote > 0 or votePromote > 0 or oriPromote > 0) then
					promoteFlag = 1
				end
			end
			if (isInVote > 0 or promoteFlag > 0) then
				-- 战队id
				local teamNo = math.mod(teamId, 1000)
				local teamNoStr = string.format("%03d", teamNo)
				HuaShanLunJian2_CreatTeamList_ListInfo:AddNewItem(teamNoStr, 0, teamCount)
				-- 战队名称
				HuaShanLunJian2_CreatTeamList_ListInfo:AddNewItem(teamName, 1, teamCount)
				-- 队长
				HuaShanLunJian2_CreatTeamList_ListInfo:AddNewItem(leaderName, 2, teamCount)
				-- 人数
				local cntMsg = ScriptGlobal_Format("#{LLGZ_260330_31}", memCount)
				HuaShanLunJian2_CreatTeamList_ListInfo:AddNewItem(cntMsg, 3, teamCount)
				-- 霸剑星数
				HuaShanLunJian2_CreatTeamList_ListInfo:AddNewItem(tostring(totalLevelStar), 4, teamCount)
				-- 票数/出线状态
				if (promoteFlag > 0) then
					-- 已出线
					HuaShanLunJian2_CreatTeamList_ListInfo:AddNewItem("#{LLGZ_260330_32}", 5, teamCount)
				else
					-- 投票数
					HuaShanLunJian2_CreatTeamList_ListInfo:AddNewItem(tostring(totalVote), 5, teamCount)
				end

				HuaShanLunJian2_CreatTeamList_TeamList[teamCount] = teamId
				teamCount = teamCount + 1
			end
		end
	end -- end for

	if (teamCount > 0) then
		HuaShanLunJian2_CreatTeamList_ListInfo:SetSelectItem(-1)
	end
end -- end func HuaShanLunJian2_CreatTeamList_UpdateTeamList()