-- 新6v6 战队信息查看

local g_UndefinedPos = nil
local g_SelectIndex = -1
local g_SelectDataIndex = -1
local g_SelectTeamIndex = -1
local g_MemberCount = 0
local g_TransName = 0			-- 转换名字
local g_ShenJianDuanWei = 6		-- 神剑段位id

local g_BarList = {}
local g_TeamPost =
{
	[0] = {show = 0, icon = "",},										-- 成员
	[1] = {show = 1, icon = "set:Union1 image:Union_MemberIcon_L",},	-- 副队长
	[2] = {show = 1, icon = "set:Union1 image:Union_LeaderIcon_L",},	-- 队长
} -- end g_TeamPost

local g_DuanWei1Str =
{
	[1] = "#{BWDH_180804_131}",
	[2] = "#{BWDH_180804_132}",
	[3] = "#{BWDH_180804_133}",
	[4] = "#{BWDH_180804_134}",
	[5] = "#{BWDH_180804_135}",
	[6] = "#{BWDH_180804_136}",
} -- end g_DuanWei1Str

local g_DuanWei2Str =
{
	[1] = "#{BWDH_180804_153}",
	[2] = "#{BWDH_180804_152}",
	[3] = "#{BWDH_180804_151}",
	[4] = "#{BWDH_180804_150}",
	[5] = "#{BWDH_180804_149}",
} -- end g_DuanWei2Str



function BW_TeamInfo_PreLoad()
	this:RegisterEvent("XBW_VIEWTEAMINFO_SHOW")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end -- end func BW_TeamInfo_PreLoad()

function BW_TeamInfo_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		BW_TeamInfo_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		BW_TeamInfo_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED")	 then
		BW_TeamInfo_CloseClicked()
	elseif(event == "XBW_VIEWTEAMINFO_SHOW") then
		BW_TeamInfo_OnShow(tonumber(arg0), tonumber(arg1))
	end
end -- end func BW_TeamInfo_OnEvent()

function BW_TeamInfo_OnLoad()
	-- 保存界面的默认相对位置
	g_UndefinedPos = BW_TeamInfo_Frame:GetProperty("UnifiedPosition")
end -- end func BW_TeamInfo_OnLoad()

function BW_TeamInfo_ResetPos()
	BW_TeamInfo_Frame:SetProperty("UnifiedPosition", g_UndefinedPos)
end -- end func BW_TeamInfo_ResetPos()

--初始化控件数据
function BW_TeamInfo_InitUIData(idx, trans)

	BW_TeamInfo_part1Num:SetText("")
	local text = ScriptGlobal_Format("#{BWDH_241114_185}", 0)
	BW_TeamInfo_part2Num:SetText(text)

	g_SelectIndex = -1
	g_SelectDataIndex = -1
	g_SelectTeamIndex = idx
	g_TransName = trans

	-- g_BarList
	for i = 1, table.getn(g_BarList) do 
		if g_BarList[i] ~= nil then
			g_BarList[i] = nil
		end
	end
	
	BW_TeamInfo_ListClient:Clear()
end -- end func BW_TeamInfo_InitUIData()

-- 关闭按钮事件
function BW_TeamInfo_CloseClicked()
	this:Hide()
end -- end func BW_TeamInfo_CloseClicked()

-- 设为私聊按钮事件
function BW_TeamInfo_PrivateChat_Clicked()
	if g_SelectDataIndex < 0 then
		return
	end

	local level, menpai, post, duanwei1, duanwei2, dunawei3, name = NewXBW:GetViewTeamMemberInfo(g_SelectTeamIndex, g_SelectDataIndex-1)
	if post == nil or level <= 0 then
		return --没有数据
	end

	
	Talk:ContexMenuTalk(name)
end -- end func BW_TeamInfo_PrivateChat_Clicked()

-- 查看资料按钮事件
function BW_TeamInfo_ViewInfo_Clicked()
	if g_SelectDataIndex < 0 then
		return
	end

	local level, menpai, post, duanwei1, duanwei2, dunawei3, name = NewXBW:GetViewTeamMemberInfo(g_SelectTeamIndex, g_SelectDataIndex-1)
	if post == nil or level <= 0 then
		return --没有数据
	end
	
	if Friend:IsPlayerIsFriend(name) == 1  then
		DataPool:ShowFriendInfo(name)
	else
		DataPool:ShowChatInfo(name)
	end
end -- end func BW_TeamInfo_ViewInfo_Clicked()

-- 成员列表点击事件
function BW_TeamInfo_Clicked(index, dataidx)

	local bar = g_BarList[index]
	if not bar then
    	return
	end
	
	g_SelectIndex = index
	g_SelectDataIndex = dataidx

	if g_SelectIndex >= 0 then
		BW_TeamInfo_ViewInfo:Enable()
    	BW_TeamInfo_PrivateChat:Enable()
	end
end -- end func BW_TeamInfo_Clicked()

function BW_TeamInfo_TransformName(name, zoneid)
	if zoneid < 0 then
		return name
	end

	local retname = name
	if g_TransName > 0 then
		local selfzoneid = DataPool:GetSelfZoneWorldID()
		if selfzoneid ~= zoneid then
			local serverName = DataPool:GetServerName( zoneid )
			retname = name.."@"..tostring(serverName)
		end
	end

	return retname
end -- end func BW_TeamInfo_TransformName()

function BW_TeamInfo_OnShow(idx, trans)
	-- local debugMsg = string.format("debug, TeamInfo, %d, %d", idx, trans)
	-- PushDebugMessage(debugMsg)

	-- 先初始化一下
	BW_TeamInfo_InitUIData(idx, trans)
	-- 填充战队信息
	if 1 == BW_TeamInfo_InitMemberListData() then
		this:Show()
	end
end -- end func BW_TeamInfo_OnShow()

function BW_TeamInfo_InitMemberListData()
	local teamid, memcnt, zoneid, teamname, teamleadername = NewXBW:GetTeamListInfo(g_SelectTeamIndex)
	if teamid == nil or teamid < 0 then
		return -1
	end

	local szteamname = ScriptGlobal_Format("#{BWDH_241114_183}", BW_TeamInfo_TransformName(teamname, zoneid))
	BW_TeamInfo_part1Num:SetText(szteamname)
	

	local szMemTips = ScriptGlobal_Format("#{BWDH_241114_185}", memcnt)
	BW_TeamInfo_part2Num:SetText(szMemTips)

	g_MemberCount = 0
	local memmax = NewXBW:GetTeamMemberCountMax()
	for i=1, memmax, 1 do
		BW_TeamInfo_AddMemberItem(g_SelectTeamIndex, i, zoneid)
	end -- end for

	--控制显示操作按钮
	if g_SelectIndex < 0 then
		BW_TeamInfo_ViewInfo:Disable()
    	BW_TeamInfo_PrivateChat:Disable()
	end

	return 1
end -- end func BW_TeamInfo_InitMemberListData()

-- 增加一个成员
function BW_TeamInfo_AddMemberItem(teamidx, index, zoneid)
	local level, menpai, post, duanwei1, duanwei2, dunawei3, name = NewXBW:GetViewTeamMemberInfo(teamidx, index-1)
	if post == nil or level <= 0 then
		return -- 没有数据
	end
	
	local bar = BW_TeamInfo_ListClient:AddChild("BW_TeamInfo_List_Frame")
	if not bar then
    	return
	end
	-- 成员加上
	g_MemberCount = g_MemberCount + 1

	-- 名字
	bar:GetSubItem("BW_TeamInfo_List1_1"):SetText("#cfff263" .. BW_TeamInfo_TransformName(name, zoneid))
	
	local leaderButton = bar:GetSubItem("BW_TeamInfo_List1_Pic")
	local postdata = g_TeamPost[post]
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
	
	local menpaiName = GetMenpaiByID(menpai)
	if (menpaiName ~= "") then
		bar:GetSubItem("BW_TeamInfo_List1_2"):SetText("#cfff263" .. menpaiName)
	else
		bar:GetSubItem("BW_TeamInfo_List1_2"):SetText("")
	end
	bar:GetSubItem("BW_TeamInfo_List1_3"):SetText("#cfff263" .. tostring(level))

	bar:GetSubItem("BW_TeamInfo_List1_4"):SetText("")
	if (duanwei1 > 0) then
		if (duanwei1 >= g_ShenJianDuanWei) then
			-- 神剑段位 显示神剑·星数	
			local duanweiStr = g_DuanWei1Str[duanwei1]
			if (duanweiStr ~= nil) then
				local xingjieStr = ScriptGlobal_Format("#{BWDH_241114_200}", dunawei3)
				local str = "#cfff263" .. duanweiStr .. xingjieStr
				bar:GetSubItem("BW_TeamInfo_List1_4"):SetText(str)
			end
		else
			-- 非神剑段位 显示段位·阶数
			local duanweiStr = g_DuanWei1Str[duanwei1]
			local jieshuStr = g_DuanWei2Str[duanwei2]
			if (duanweiStr ~= nil and jieshuStr ~= nil) then
				local dwText = ScriptGlobal_Format("#{BWDH_241114_201}", duanweiStr, jieshuStr)
				bar:GetSubItem("BW_TeamInfo_List1_4"):SetText(dwText)
			end
		end
	end
	
	bar:SetEvent("MouseLClick", string.format("BW_TeamInfo_Clicked(%d, %d)", g_MemberCount, index))
	
	g_BarList[g_MemberCount] = bar
end -- end func BW_TeamInfo_AddMemberItem()
