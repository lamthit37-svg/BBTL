-- 战队信息查看
local g_unifiedposistion
local g_BarList = {}
local g_SelectIndex = -1
local g_selectdataidx = -1
local g_selectTeamIdx = -1
local g_memcount = 0
local g_trasname = 0			-- 转换名字
local g_MenPaiNameList =
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
	[9] = "",         	--无门派
	[10] = "#{XQ_MP_10}",	--慕容
	[11] = "#{XQ_MP_13}",  	--唐门
	[12] = "#{XQ_MP_14}",  	--鬼谷
    [13] = "#{XQ_MP_15}",  	--桃花岛
	[14] = "#{XQ_MP_16}", 	--绝情谷
	[15] = "#{GMGameInterface_Script_DataPool_Info_ERenGu}", 	--menpai15 mptodo
}

local g_teampost = {
	[0] = {show = 0, icon = "",},									-- 成员
	[1] = {show = 1, icon = "set:Union1 image:Union_MemberIcon_L",},-- 副队长
	[2] = {show = 1, icon = "set:Union1 image:Union_LeaderIcon_L",},-- 副队长
}

function ZBS_TeamInfo_PreLoad()
	this:RegisterEvent("ZBS_VIEWTEAMINFO_SHOW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function ZBS_TeamInfo_OnLoad()
	-- 保存界面的默认相对位置
	g_unifiedposistion = ZBS_TeamInfo_Frame:GetProperty("UnifiedPosition")
end

function ZBS_TeamInfo_OnEvent(event)

	if( event == "ADJEST_UI_POS" ) then
		ZBS_TeamInfo_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		ZBS_TeamInfo_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED")	 then
		ZBS_TeamInfo_CloseClicked()
	elseif(event == "ZBS_VIEWTEAMINFO_SHOW") then
		ZBS_TeamInfo_OnShow(tonumber(arg0), tonumber(arg1))
	end

end

function ZBS_TeamInfo_OnShow(idx, trans)
	--先初始化一下
	ZBS_TeamInfo_InitUIData(idx, trans)
	--填充战队信息
	if 1 == ZBS_TeamInfo_InitMemberListData() then
		this:Show()
	end
end

--初始化控件数据
function ZBS_TeamInfo_InitUIData(idx, trans)

	ZBS_TeamInfo_part1:SetText("")
	local text = ScriptGlobal_Format("#{WCBZ_180128_515}", 0 )
	ZBS_TeamInfo_part2:SetText(text)

	g_SelectIndex = -1
	g_selectdataidx = -1
	g_selectTeamIdx = idx
	g_trasname = trans

	--g_BarList
	for i = 1, table.getn(g_BarList) do 
		if g_BarList[i] ~= nil then
			g_BarList[i] = nil
		end
	end
	
	ZBS_TeamInfo_ListClient:Clear()
end

--!!!reloadscript =ZBS_TeamInfo
function ZBS_TeamInfo_InitMemberListData()

	local teamid, teamname, teamleadername, memcnt, zoneid, totalScore = ZBS:GetTeamListInfo(g_selectTeamIdx)
	if teamid == nil or teamid < 0 then
		return -1
	end

	
	local szteamname = ScriptGlobal_Format("#{WCBZ_180128_514}", ZBS_TeamInfo_TransformName(teamname, zoneid) )
	ZBS_TeamInfo_part1:SetText( szteamname )
	

	local szMemTips = ScriptGlobal_Format("#{WCBZ_180128_515}", memcnt )
	ZBS_TeamInfo_part2:SetText(szMemTips)

	g_memcount = 0
	local memmax = ZBS:GetTeamMemberCountMax()
	for i=1, memmax do
		ZBS_TeamInfo_AddMemberItem( g_selectTeamIdx, i, zoneid )
	end

	--控制显示操作按钮
	if g_SelectIndex < 0 then
		ZBS_TeamInfo_Look:Disable()
    	ZBS_TeamInfo_Talk:Disable()
	end

	return 1
end

--增加一个成员
function ZBS_TeamInfo_AddMemberItem( teamidx, index, zoneid )
	local level, menpai, post, score, name = ZBS:GetViewTeamInfo(teamidx, index-1)
	if post == nil or level <= 0 then
		return --没有数据
	end
	
	local bar = ZBS_TeamInfo_ListClient:AddChild("ZBS_TeamInfo_List_Frame")
	if not bar then
    	return
	end
	-- 成员加上
	g_memcount = g_memcount + 1

	--名字
	bar:GetSubItem("ZBS_TeamInfo_List1_1"):SetText(ZBS_TeamInfo_TransformName(name, zoneid))
	
	local leaderButton = bar:GetSubItem("ZBS_TeamInfo_List1_Pic")
	local postdata = g_teampost[post]
	if postdata == nil then
		leaderButton:Hide()
	else
		if postdata.show > 0 then
			leaderButton:SetProperty("Image", postdata.icon)
			leaderButton:Show()
		else
			leaderButton:Hide()
		end
	end
			
	bar:GetSubItem("ZBS_TeamInfo_List1_2"):SetText(g_MenPaiNameList[menpai])
	bar:GetSubItem("ZBS_TeamInfo_List1_3"):SetText(tostring(level))
	bar:GetSubItem("ZBS_TeamInfo_List1_4"):SetText(tostring(score))
	
	bar:SetEvent("MouseLClick", string.format("ZBS_TeamInfo_Clicked(%d, %d)", g_memcount, index))
	
	g_BarList[g_memcount] = bar
end

function ZBS_TeamInfo_Clicked(index, dataidx)

	local bar = g_BarList[index]
	if not bar then
    	return
	end
	
	g_SelectIndex = index
	g_selectdataidx = dataidx

	if g_SelectIndex >= 0 then
		ZBS_TeamInfo_Look:Enable()
    	ZBS_TeamInfo_Talk:Enable()
	end
end

function ZBS_TeamInfo_PrivateChat_Clicked()
	if g_selectdataidx < 0 then
		return
	end

	local level, menpai, post, score, name = ZBS:GetViewTeamInfo(g_selectTeamIdx, g_selectdataidx-1)
	if post == nil or level <= 0 then
		return --没有数据
	end

	
	Talk:ContexMenuTalk(name)
end

function ZBS_TeamInfo_ViewInfo_Clicked()
	if g_selectdataidx < 0 then
		return
	end

	local level, menpai, post, score, name = ZBS:GetViewTeamInfo(g_selectTeamIdx, g_selectdataidx-1)
	if post == nil or level <= 0 then
		return --没有数据
	end
	
	if Friend:IsPlayerIsFriend(name) == 1  then
		DataPool:ShowFriendInfo(name)
	else
		DataPool:ShowChatInfo(name)
	end
end

function ZBS_TeamInfo_TransformName(name, zoneid)
	if zoneid < 0 then
		return name
	end

	local retname = name
	if g_trasname > 0 then
		local selfzoneid = DataPool:GetSelfZoneWorldID()
		if selfzoneid ~= zoneid then
			local serverName = DataPool:GetServerName( zoneid )
			retname = name.."@"..tostring(serverName)
		end
	end

	return retname
end

--================================================
--关闭
--================================================
function ZBS_TeamInfo_CloseClicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ZBS_TeamInfo_ResetPos()
	ZBS_TeamInfo_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

