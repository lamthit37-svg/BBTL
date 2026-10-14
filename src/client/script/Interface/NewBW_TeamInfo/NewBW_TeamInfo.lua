-- NewBW_TeamInfo

local NewBW_TeamInfo_UndefinedPos = nil
local NewBW_TeamInfo_SelectTeamIndex = -1
local NewBW_TeamInfo_MemberCount = 0
local NewBW_TeamInfo_TransName = 0			-- 转换名字
local g_NewBW_TeamInfo_CareObjId = -1

local NewBW_TeamInfo_MenPaiName =
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
	[9] = "无门派",	--无门派
	[10] = "#{XQ_MP_10}",		
	[11] = "#{XQ_MP_13}",	
	[12] = "#{XMPGG_160524_02}",	
	[13] = "#{SCGZ_180816_119}",	
	[14] = "#{XMPHM_210604_01}",	
	[15] = "#{GMGameInterface_Script_DataPool_Info_ERenGu}",		--恶人谷
} 

local NewBW_TeamInfo_TeamPost =
{
	[0] = {show = 0, icon = "",},										-- 成员
	[1] = {show = 1, icon = "set:Union1 image:Union_MemberIcon_L",},	-- 副队长
	[2] = {show = 1, icon = "set:Union1 image:Union_LeaderIcon_L",},	-- 队长
}

local NewBW_TeamInfo_DuanWeiStr =
{
	[1] = "#{SJPM_241125_28}",
	[2] = "#{SJPM_241125_29}",
	[3] = "#{SJPM_241125_30}",
	[4] = "#{SJPM_241125_31}",
	[5] = "#{SJPM_241125_32}",
	[6] = "#{SJPM_241125_33}",
} 

local NewBW_TeamInfo_DuanWei2Str =
{
	[1] = "#{BWDH_180804_141}",
	[2] = "#{BWDH_180804_140}",
	[3] = "#{BWDH_180804_139}",
	[4] = "#{BWDH_180804_138}",
	[5] = "#{BWDH_180804_137}",
}


function NewBW_TeamInfo_PreLoad()
	this:RegisterEvent("XBW_TEAMRANK_OPENTEAMUI")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end 

function NewBW_TeamInfo_OnEvent(event)
	if( event == "ADJEST_UI_POS" ) then
		NewBW_TeamInfo_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		NewBW_TeamInfo_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED")	 then
		NewBW_TeamInfo_CloseClicked()
	elseif(event == "XBW_TEAMRANK_OPENTEAMUI") then
		NewBW_TeamInfo_OnShow(tonumber(arg0), tonumber(arg1))
	end
end

function NewBW_TeamInfo_OnLoad()
	-- 保存界面的默认相对位置
	NewBW_TeamInfo_UndefinedPos = NewBW_TeamInfo_Frame:GetProperty("UnifiedPosition")
end 

function NewBW_TeamInfo_ResetPos()
	NewBW_TeamInfo_Frame:SetProperty("UnifiedPosition", NewBW_TeamInfo_UndefinedPos)
end

function NewBW_TeamInfo_OnShow(idx, targetId)
	g_NewBW_TeamInfo_CareObjId = DataPool:GetNPCIDByServerID(targetId)
    if (g_NewBW_TeamInfo_CareObjId >= 0) then
		this:CareObject(g_NewBW_TeamInfo_CareObjId, 1, "NewBW_TeamInfo")
	end
	-- 先初始化一下
	NewBW_TeamInfo_InitUIData(idx, 1)
	-- 填充战队信息
	if 1 == NewBW_TeamInfo_InitMemberListData() then
		this:Show()
	end
	NewBW_TeamInfo_Frame:SetForce()
end

--初始化控件数据
function NewBW_TeamInfo_InitUIData(idx, trans)

	NewBW_TeamInfo_part1:SetText(ScriptGlobal_Format("#{SJPM_241125_19}",""))
	NewBW_TeamInfo_part2:SetText(ScriptGlobal_Format("#{SJPM_241125_20}", 0))

	NewBW_TeamInfo_SelectTeamIndex = idx
	NewBW_TeamInfo_TransName = trans


	NewBW_TeamInfo_ListClient:Clear()
end

function NewBW_TeamInfo_InitMemberListData()

	local data = NewXBW:GetRankTeamInfo(NewBW_TeamInfo_SelectTeamIndex-1)
	if data == nil or type(data) ~= "table" then
		return -1
	end
	
	local zoneid = data.worldid
	local teamname = data.name
	local memcnt = data.count
	
	local szteamname = ScriptGlobal_Format("#{SJPM_241125_19}", NewBW_TeamInfo_TransformName(teamname, zoneid))
	NewBW_TeamInfo_part1:SetText(szteamname)
	

	local szMemCnt = ScriptGlobal_Format("#{SJPM_241125_20}", memcnt)
	NewBW_TeamInfo_part2:SetText(szMemCnt)

	NewBW_TeamInfo_MemberCount = 0
	local memmax = NewXBW:GetTeamMemberCountMax()

	local templist = {}
	for i=1, memmax, 1 do
		table.insert( templist, {} )
		local data = NewXBW:GetRankMemberInfo(NewBW_TeamInfo_SelectTeamIndex-1, i-1)
		if data ~= nil and type(data) == "table" then
			templist[i].nIndex = i
			templist[i].post = data.post
			NewBW_TeamInfo_MemberCount = NewBW_TeamInfo_MemberCount + 1
		else
			templist[i].nIndex = i
			templist[i].post = -1			
		end
	end
	-- 排序
	table.sort(templist, function(a, b)
			return a.post > b.post
		end)
		
	for i=1, memmax, 1 do
		NewBW_TeamInfo_AddMemberItem(NewBW_TeamInfo_SelectTeamIndex, templist[i].nIndex, zoneid)
	end -- end for

	return 1
end

-- 增加一个成员
function NewBW_TeamInfo_AddMemberItem(teamidx, index, zoneid)
	local data = NewXBW:GetRankMemberInfo(teamidx-1, index-1)
	if data == nil or type(data) ~= "table" then
		return -1
	end

	local level = data.level
	local menpai = data.menpai
	local post = data.post
	local duanwei1 = data.dw1
	local duanwei2 = data.dw2
	local dunawei3 = data.dw3
	local name = data.name

	local bar = NewBW_TeamInfo_ListClient:AddChild("NewBW_TeamInfo_List_Frame")
	if not bar then
		return
	end
	-- 成员加上
	--NewBW_TeamInfo_MemberCount = NewBW_TeamInfo_MemberCount + 1

	-- 名字
	bar:GetSubItem("NewBW_TeamInfo_List1_1"):SetText("#cfff263"..NewBW_TeamInfo_TransformName(name, zoneid))
	
	local leaderButton = bar:GetSubItem("NewBW_TeamInfo_List1_Pic")
	local postdata = NewBW_TeamInfo_TeamPost[post]
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
	
	if (NewBW_TeamInfo_MenPaiName[menpai] ~= nil) then
		bar:GetSubItem("NewBW_TeamInfo_List1_2"):SetText("#cfff263"..NewBW_TeamInfo_MenPaiName[menpai])
	else
		bar:GetSubItem("NewBW_TeamInfo_List1_2"):SetText("")
	end

	if level > 0 then
		bar:GetSubItem("NewBW_TeamInfo_List1_3"):SetText("#cfff263"..tostring(level))
	else
		bar:GetSubItem("NewBW_TeamInfo_List1_3"):SetText("")
	end
	bar:GetSubItem("NewBW_TeamInfo_List1_4"):SetText("")
	if (duanwei1 > 0) then
		if (duanwei1 >= 6) then
			local duanweiStr = NewBW_TeamInfo_DuanWeiStr[duanwei1]
			if (duanweiStr ~= nil) then
				bar:GetSubItem("NewBW_TeamInfo_List1_4"):SetText(duanweiStr .. dunawei3 .. "#{SJPM_241125_35}")
			end
		else
			-- 非神剑段位 显示段位·阶数
			local duanweiStr = NewBW_TeamInfo_DuanWeiStr[duanwei1]
			local jieshuStr = NewBW_TeamInfo_DuanWei2Str[duanwei2]
			if (duanweiStr ~= nil and jieshuStr ~= nil) then
				bar:GetSubItem("NewBW_TeamInfo_List1_4"):SetText(duanweiStr .. jieshuStr .. "#{SJPM_241125_34}")
			end
		end
	end

end

-- 关闭按钮事件
function NewBW_TeamInfo_CloseClicked()
	if (g_NewBW_TeamInfo_CareObjId >= 0) then
		this:CareObject(g_NewBW_TeamInfo_CareObjId, 0, "NewBW_TeamInfo")
		g_NewBW_TeamInfo_CareObjId = -1
	end
	
	this:Hide()
end 

function NewBW_TeamInfo_TransformName(name, zoneid)
	if zoneid < 0 then
		return name
	end

	local retname = name
	if NewBW_TeamInfo_TransName > 0 then
		local selfzoneid = DataPool:GetSelfZoneWorldID()
		if selfzoneid ~= zoneid then
			local serverName = DataPool:GetServerName( zoneid )
			retname = name.."@"..tostring(serverName)
		end
	end

	return retname
end
