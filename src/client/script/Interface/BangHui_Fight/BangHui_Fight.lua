--帮会属地争夺-排行榜(客户端)

--//
--控件列表
local m_Controls = {} 				--控件列表

local g_Frame_UnifiedPosition
local g_targetID = -1
local g_objCared = -1
local MAX_OBJ_DISTANCE = 3.0


function BangHui_Fight_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("OBJECT_CARED_EVENT",false)
	this:RegisterEvent("OPEN_BANGHUI_FIGHT_UI")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function BangHui_Fight_OnLoad()
	m_Controls = {
		m_FightTitle = BangHui_Fight_PageHeader,
		m_FightText = BangHui_Fight_Text,
		m_CapacityText = BangHui_Fight_Capacity_Income,
		m_FightInfoList = BangHui_FightInfo_list,
		m_TimeText = BangHui_Fight_Info_Timetext,
		m_TeamInfoButton = BangHui_Fight_Info_TeamInfo,
		m_Frame = BangHui_Fight_Frame,
	}
	
	g_Frame_UnifiedPosition=m_Controls.m_Frame:GetProperty("UnifiedPosition")
end

function BangHui_Fight_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 891070 ) then
		local operate = Get_XParam_INT(0)	
		if operate == 1 then
			--打开排行榜
			g_targetID = Get_XParam_INT(1)
			g_objCared = DataPool : GetNPCIDByServerID(g_targetID)
			if g_objCared == -1 then
				PushDebugMessage("server传过来的数据有问题。")
				return
			end
			--BangHui_Fight_Open()
		end
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		BangHui_Fight_Frame_On_ResetPos()
		BangHui_Fight_Open()
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if(tonumber(arg0) ~= g_objCared) then
			return
		end
		if(arg1 == "distance" and tonumber(arg2)>MAX_OBJ_DISTANCE or arg1=="destroy") then
			BangHui_Fight_Close()
		end
	elseif (event == "OPEN_BANGHUI_FIGHT_UI") then
		BangHui_Fight_Open()
		this:Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then 
		this:Hide()
	end
end

function BangHui_Fight_Open()
	if g_objCared ~= -1 then
		this:CareObject(g_objCared, 0, "BangHui_Fight")
		this:CareObject(g_objCared, 1, "BangHui_Fight")
	else
		return
	end
	
	
	--
	m_Controls.m_FightTitle:SetText("#{BHSDZ_150310_42}")
	--群雄封赏报名
	m_Controls.m_FightText:SetText("#{BHSDZ_150310_43}")
	--每周日15点10分至30分期间...
	local msgText = ""
	local GangInd = GangT:GetSelfGuildOnGangTerritoryInd()
	--PushDebugMessage("GangInd=".. GangInd)
	local totalZhanli = 0
	if GangInd ~= -1 then
		totalZhanli = GangT:GetGangTerritoryInfo(GangInd, "ZhanLi")
	end
	local myGuildName = ""
	myGuildName = Guild:GetMyGuildInfo("Name")
	if myGuildName ~= nil and myGuildName ~= "" then
		if totalZhanli > 0 then
			msgText = ScriptGlobal_Format("#{BHSDZ_150310_44}",totalZhanli)
			--"您当前帮会已经成功报名参战，报名参战成员总战斗力为XXX"
		else
			msgText = "#{BHSDZ_150310_45}"
			--您当前帮会尚未成功报名参战！
		end
	else
		msgText = "#{BHSDZ_150310_233}"
		--您尚未拥有帮会，无法报名
	end
	
	m_Controls.m_CapacityText:SetText(msgText)
	
	--
	local hourLeft = GangT:GetGangTVoteLeftHour()
	local minuteLeft = GangT:GetGangTVoteLeftMinute()
	local secondLeft = GangT:GetGangTVoteLeftSecond()
	
	if hourLeft ~= nil and minuteLeft ~= nil and secondLeft ~= nil then
		if hourLeft == 0 and minuteLeft == 0 and secondLeft == 0 then
			m_Controls.m_TimeText:SetText("#{BHSDZ_150310_51}")
			--当前不是报名时间，请在每周日X点~Y前来报名
		elseif hourLeft > 0 then
			--local msg = SriptGlobal_Format("#{BHSDZ_150310_50}",hourLeft)
			m_Controls.m_TimeText:SetText("#{BHSDZ_150310_50}" .. "#G" .. hourLeft .. "小时")
		elseif minuteLeft > 1 then
			--local msg = SriptGlobal_Format("#{BHSDZ_150310_50}",minuteLeft)
			m_Controls.m_TimeText:SetText("#{BHSDZ_150310_50}" .. "#G" .. minuteLeft .. "分钟")
		else
			m_Controls.m_TimeText:SetText("#{BHSDZ_150310_50}" .. "#G不足一分钟")
		end
		
		--距离本周报名结束时间：XXXX
	end
	
	m_Controls.m_TeamInfoButton:SetText("#{BHSDZ_150310_52}")
	--报名队伍信息查看
	
	m_Controls.m_FightInfoList:RemoveAllItem()
	--获取排行榜数据数量
	local m_GangTCount = GangT:GetGangTerritoryNum()
	--PushDebugMessage("m_GangTCount=".. m_GangTCount)
	
	for ind = 1, m_GangTCount do
		local rankID = GangT:GetGangTerritoryInfo(ind - 1, "RankID")
		local guidlID = GangT:GetGangTerritoryInfo(ind - 1, "GuildID")
		local guidlName = GangT:GetGangTerritoryInfo(ind - 1, "GuildName")
		local zhanliValue = GangT:GetGangTerritoryInfo(ind - 1, "ZhanLi")
		m_Controls.m_FightInfoList:AddNewItem("#cfff263" .. tostring(rankID + 1), 0 , ind - 1)
		m_Controls.m_FightInfoList:AddNewItem("#cfff263" .. guidlName, 1 , ind - 1)
		m_Controls.m_FightInfoList:AddNewItem("#cfff263" .. tostring(zhanliValue), 2 , ind - 1)
	end
	
	if m_GangTCount < 8 then
		for leftind = m_GangTCount + 1, 8 do
			m_Controls.m_FightInfoList:AddNewItem("#cfff263" .. leftind, 0 , leftind - 1)
			m_Controls.m_FightInfoList:AddNewItem("#cfff263" .. "#{BHSDZ_150310_48}", 1 , leftind - 1)
			m_Controls.m_FightInfoList:AddNewItem("#cfff263" .. 0, 2 , leftind - 1)
		end
	end
	
	--this:Show()
end

function BangHui_Fight_Close()
	if g_objCared ~= -1 then
		this:CareObject(g_objCared, 0, "BangHui_Fight")
		g_objCared = -1
	end
	this:Hide()
end

function BangHui_Fight_Frame_On_ResetPos()
	 m_Controls.m_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
end

--回调函数-关闭
function BangHui_Fight_OnClosed()
	BangHui_Fight_Close()
end

--回调函数-队伍查看
function BangHui_Fight_OnTeamInfoLook()
	local listIndex = m_Controls.m_FightInfoList:GetSelectItem()
	--获取队伍具体信息查看之
	--PushDebugMessage("具体信息查看！！！")
	if listIndex == -1 or listIndex == nil then
		PushDebugMessage("#{BHSDZ_150310_225}")
		return
	end
	
	local m_GangTCount = GangT:GetGangTerritoryNum()
	if listIndex >= m_GangTCount then
		PushDebugMessage("#{BHSDZ_150310_225}")
		return
	end
	PushEvent("OPEN_BANGHUI_TEAMVIEW_UI",g_targetID,listIndex)
end