-- 新比武（6v6）季后赛 战队详情UI
-- 关注NPC
local HuaShanLunJian2_TeamInfo_CareObjId = -1
local HuaShanLunJian2_TeamInfo_CareObjSvrId = -1
local HuaShanLunJian2_TeamInfo_MAX_OBJ_DISTANCE = 5.0
-- 默认位置
local HuaShanLunJian2_TeamInfo_UnifiedPosition = nil
-- 当前查看的战队类型
local HuaShanLunJian2_TeamInfo_TeamType = 0
-- 战队成员最大数量
local HuaShanLunJian2_TeamInfo_TeamMemberCount = 6



local HuaShanLunJian2_TeamInfo_MenPaiName =
{
	[0] = "#{XQ_MP_1}",    	--少林
	[1] = "#{XQ_MP_2}",    	--明教
	[2] = "#{XQ_MP_3}",    	--丐帮
	[3] = "#{XQ_MP_4}",    	--武当
	[4] = "#{XQ_MP_5}",    	--峨眉
	[5] = "#{XQ_MP_6}",    	--星宿
	[6] = "#{XQ_MP_7}",    	--天龙
	[7] = "#{XQ_MP_8}",    	--天山
	[8] = "#{XQ_MP_9}",    	--逍遥
	[9] = "#{LLGZ_260330_43}",	--无门派
	[10] = "#{XQ_MP_10}",	--慕容
	[11] = "#{XQ_MP_13}",  	--唐门
	[12] = "#{XQ_MP_14}",  	--鬼谷
	[13] = "#{XQ_MP_15}",  	--桃花岛
	[14] = "#{XQ_MP_16}", 	--绝情谷
	[15] = "#{GMGameInterface_Script_DataPool_Info_ERenGu}", -- 恶人谷
} -- end HuaShanLunJian2_TeamInfo_MenPaiName

local HuaShanLunJian2_TeamInfo_TeamPost =
{
	member = 0,
	deputy = 1,
	leader = 2,
} -- end HuaShanLunJian2_TeamInfo_TeamPost


function HuaShanLunJian2_TeamInfo_PreLoad()
	this:RegisterEvent("XBWJHS_OPENTEAMINFO", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end -- end func HuaShanLunJian2_TeamInfo_PreLoad()

function HuaShanLunJian2_TeamInfo_OnEvent(event)
	if (event == "XBWJHS_OPENTEAMINFO") then
		HuaShanLunJian2_TeamInfo_TeamType = tonumber(arg0)
		HuaShanLunJian2_TeamInfo_BeginCareObject(tonumber(arg2), tonumber(arg3))
		HuaShanLunJian2_TeamInfo_UpdateTeamInfo(tonumber(arg1))
		HuaShanLunJian2_TeamInfo_Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		HuaShanLunJian2_TeamInfo_Hide()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		HuaShanLunJian2_TeamInfo_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		HuaShanLunJian2_TeamInfo_UnifiedPos()
	end
end -- end func HuaShanLunJian2_TeamInfo_OnEvent()

function HuaShanLunJian2_TeamInfo_OnLoad()
	HuaShanLunJian2_TeamInfo_UnifiedPosition = HuaShanLunJian2_TeamInfo_Frame:GetProperty("UnifiedPosition")
end -- end func HuaShanLunJian2_TeamInfo_OnLoad()

-- 界面默认位置
function HuaShanLunJian2_TeamInfo_UnifiedPos()
	if (HuaShanLunJian2_TeamInfo_UnifiedPosition ~= nil) then
		HuaShanLunJian2_TeamInfo_Frame:SetProperty("UnifiedPosition", HuaShanLunJian2_TeamInfo_UnifiedPosition)
	end
end -- end func HuaShanLunJian2_TeamInfo_UnifiedPos()

function HuaShanLunJian2_TeamInfo_Show()
    this:Show()
end -- end func HuaShanLunJian2_TeamInfo_Show()

function HuaShanLunJian2_TeamInfo_Hide()
	HuaShanLunJian2_TeamInfo_StopCareObject()
    this:Hide()
end -- end func HuaShanLunJian2_TeamInfo_Hide()

-- 开启NPC关注
function HuaShanLunJian2_TeamInfo_BeginCareObject(objSvrId, objId)
	HuaShanLunJian2_TeamInfo_CareObjSvrId = objSvrId
	HuaShanLunJian2_TeamInfo_CareObjId = objId
	if (HuaShanLunJian2_TeamInfo_CareObjId >= 0) then
		this:CareObject(HuaShanLunJian2_TeamInfo_CareObjId, 1, "HuaShanLunJian2_TeamInfo")
	end
end -- end func HuaShanLunJian2_TeamInfo_BeginCareObject()

-- 取消NPC关注
function HuaShanLunJian2_TeamInfo_StopCareObject()
	if (HuaShanLunJian2_TeamInfo_CareObjId >= 0) then
		this:CareObject(HuaShanLunJian2_TeamInfo_CareObjId, 0, "HuaShanLunJian2_TeamInfo")
		HuaShanLunJian2_TeamInfo_CareObjId = -1
		HuaShanLunJian2_TeamInfo_CareObjSvrId = -1
	end
end -- end func HuaShanLunJian2_TeamInfo_StopCareObject()

--*************************************************************************************************
--*************************************************************************************************
--
--*************************************************************************************************
--*************************************************************************************************

-- 关闭按钮点击事件
function HuaShanLunJian2_TeamInfo_CloseClicked()
    HuaShanLunJian2_TeamInfo_Hide()
end -- end func HuaShanLunJian2_TeamInfo_CloseClicked()

-- 查看玩家资料按钮点击事件
function HuaShanLunJian2_TeamInfo_ViewInfo_Clicked()
	if (HuaShanLunJian2_TeamInfo_CurTeamIndex < 0) then
		return
	end
	if (HuaShanLunJian2_TeamInfo_CurMemberIndex < 0) then
		return
	end

	local teamIdx = HuaShanLunJian2_TeamInfo_CurTeamIndex
	local memIdx = HuaShanLunJian2_TeamInfo_CurMemberIndex

	local isValid, playerMenPai, playerLevel, playerPost, playernName = XBWJHS:GetTeamMemberDataByIndex(HuaShanLunJian2_TeamInfo_TeamType, teamIdx, memIdx)
	if (isValid == nil or isValid == 0) then
		return
	end

	if (Friend:IsPlayerIsFriend(playernName) == 1) then
		DataPool:ShowFriendInfo(playernName)
	else
		DataPool:ShowChatInfo(playernName)
	end
end -- end func HuaShanLunJian2_TeamInfo_ViewInfo_Clicked()

-- 设为私聊按钮点击事件
function HuaShanLunJian2_TeamInfo_PrivateChat_Clicked()
	if (HuaShanLunJian2_TeamInfo_CurTeamIndex < 0) then
		return
	end
	if (HuaShanLunJian2_TeamInfo_CurMemberIndex < 0) then
		return
	end

	local teamIdx = HuaShanLunJian2_TeamInfo_CurTeamIndex
	local memIdx = HuaShanLunJian2_TeamInfo_CurMemberIndex
	
	local isValid, playerMenPai, playerLevel, playerPost, playernName = XBWJHS:GetTeamMemberDataByIndex(HuaShanLunJian2_TeamInfo_TeamType, teamIdx, memIdx)
	if (isValid == nil or isValid == 0) then
		return
	end

	Talk:ContexMenuTalk(playernName)
end -- end func HuaShanLunJian2_TeamInfo_PrivateChat_Clicked()

--*************************************************************************************************
--*************************************************************************************************
--
--*************************************************************************************************
--*************************************************************************************************

-- 更新战队信息
function HuaShanLunJian2_TeamInfo_UpdateTeamInfo(tarTeamId)
	HuaShanLunJian2_TeamInfo_CurTeamIndex = -1
	HuaShanLunJian2_TeamInfo_CurMemberIndex = -1

	-- 先设置一下默认信息 以防找不到战队数据
	HuaShanLunJian2_TeamInfo_part1:SetText("")
	HuaShanLunJian2_TeamInfo_part2:SetText("")

	local teamId, worldId, teamIdx, memCount, totalLevelStar, totalVote, teamName, leaderName = XBWJHS:GetTeamDataByID(HuaShanLunJian2_TeamInfo_TeamType, tarTeamId)
	if (teamId == nil or teamId <= 0) then
		return
	end
	if (teamIdx < 0) then
		return
	end
	if (memCount <= 0) then
		return
	end

	-- 战队名称
	local serverName = DataPool:GetServerName(worldId)
	local fullTeamName = teamName
	if (serverName ~= nil) then
		fullTeamName = string.format("%s@%s", teamName, serverName)
	end
	local teamNameStr = ScriptGlobal_Format("#{LLGZ_260330_38}", fullTeamName)
	HuaShanLunJian2_TeamInfo_part1:SetText(teamNameStr)

	-- 战队人数
	local menCountStr = ScriptGlobal_Format("#{LLGZ_260330_39}", memCount)
	HuaShanLunJian2_TeamInfo_part2:SetText(menCountStr)

	-- 成员列表
	HuaShanLunJian2_TeamInfo_ListClient:Clear()
	for i=1, HuaShanLunJian2_TeamInfo_TeamMemberCount, 1 do
		local isValid, playerMenPai, playerLevel, playerPost, playernName = XBWJHS:GetTeamMemberDataByIndex(HuaShanLunJian2_TeamInfo_TeamType, teamIdx, i-1)
		if (isValid ~= nil and isValid > 0) then
			local bar = HuaShanLunJian2_TeamInfo_ListClient:AddChild("HuaShanLunJian2_TeamInfo_List_Frame")
			if (bar ~= nil) then
				-- 队长标记
				if (playerPost == HuaShanLunJian2_TeamInfo_TeamPost.leader) then
					bar:GetSubItem("HuaShanLunJian2_TeamInfo_List1_Pic"):SetProperty("Image", "set:Union1 image:Union_LeaderIcon_L")
				elseif (playerPost == HuaShanLunJian2_TeamInfo_TeamPost.deputy) then
					bar:GetSubItem("HuaShanLunJian2_TeamInfo_List1_Pic"):SetProperty("Image", "set:Union1 image:Union_MemberIcon_L")
				else
					bar:GetSubItem("HuaShanLunJian2_TeamInfo_List1_Pic"):SetProperty("Image", "")
				end
				-- 角色名
				bar:GetSubItem("HuaShanLunJian2_TeamInfo_List1_1"):SetText(playernName)
				-- 门派
				local menpaiStr = HuaShanLunJian2_TeamInfo_MenPaiName[playerMenPai]
				if (menpaiStr ~= nil) then
					bar:GetSubItem("HuaShanLunJian2_TeamInfo_List1_2"):SetText(menpaiStr)
				else
					bar:GetSubItem("HuaShanLunJian2_TeamInfo_List1_2"):SetText("")
				end
				-- 等级
				bar:GetSubItem("HuaShanLunJian2_TeamInfo_List1_3"):SetText(tostring(playerLevel))

				-- 点击事件
				bar:SetEvent("MouseLClick", string.format("HuaShanLunJian2_TeamInfo_MemClicked(%d, %d)", teamIdx, i-1))
			end
		end
	end -- end for
end -- end func HuaShanLunJian2_TeamInfo_UpdateTeamInfo()

-- 成员信息点击事件
function HuaShanLunJian2_TeamInfo_MemClicked(teamIdx, memIdx)
	HuaShanLunJian2_TeamInfo_CurTeamIndex = teamIdx
	HuaShanLunJian2_TeamInfo_CurMemberIndex = memIdx
end -- end func HuaShanLunJian2_TeamInfo_MemClicked()