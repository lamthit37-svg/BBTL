--!!!reloadscript =Chengzhan_TopList

local g_Chengzhan_TopList_Frame_UnifiedXPosition
local g_Chengzhan_TopList_Frame_UnifiedYPosition


local m_UICheckButton = nil

local m_curGroup = 3


local m_nSeasonBegin = 0
local m_nSeasonEnd = 0
local m_nAwardBegin = 0
local m_nAwardEnd = 0


local m_CITYWAR_RANK_PreNUM = 50

--预加载函数，可以而且只能在这里注册脚本关心的事件
function Chengzhan_TopList_PreLoad()
	this:RegisterEvent("CITYWAR_RANK_OP");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Chengzhan_TopList_OnLoad()
	-- 保存界面的默认相对位置
	g_Chengzhan_TopList_Frame_UnifiedXPosition	= Chengzhan_TopList_Frame:GetProperty("UnifiedXPosition");
	g_Chengzhan_TopList_Frame_UnifiedYPosition	= Chengzhan_TopList_Frame:GetProperty("UnifiedYPosition");

	m_UICheckButton = {}
	m_UICheckButton[1] = Chengzhan_TopList_Check1
	m_UICheckButton[2] = Chengzhan_TopList_Check2
	m_UICheckButton[3] = Chengzhan_TopList_Check3
	m_UICheckButton[4] = Chengzhan_TopList_Check4
	m_UICheckButton[5] = nil
	m_UICheckButton[6] = Chengzhan_TopList_Check5
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Chengzhan_TopList_ResetPos()
	Chengzhan_TopList_Frame:SetProperty("UnifiedXPosition", g_Chengzhan_TopList_Frame_UnifiedXPosition);
	Chengzhan_TopList_Frame:SetProperty("UnifiedYPosition", g_Chengzhan_TopList_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Chengzhan_TopList_OnEvent(event)
	if event == "CITYWAR_RANK_OP" then
		local opType = tonumber(arg0)
		if opType == 1 then
			local nGroup = tonumber(arg1)
			m_nSeasonBegin = tonumber(arg2)
			m_nSeasonEnd = tonumber(arg3)
			m_nAwardBegin = tonumber(arg4)
			m_nAwardEnd = tonumber(arg5)
			m_curGroup = nGroup
			if (this:IsVisible()) then
				Chengzhan_TopList_Update()
				return
			end
		end
		--打开界面
		Chengzhan_TopList_Show()
		Chengzhan_TopList_Update()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Chengzhan_TopList_OnHide()
	elseif event == "ADJEST_UI_POS" then
		Chengzhan_TopList_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Chengzhan_TopList_ResetPos()
	end
end

--显示UI
function Chengzhan_TopList_Show()
	this:Show()
end
--隐藏UI
function Chengzhan_TopList_OnHide()
	this:Hide()
end

function Chengzhan_TopList_Update()
	Chengzhan_TopList_ListInfo:Clear()

	local curDay = DataPool:GetServerDayTime()
	if curDay >= m_nAwardBegin and curDay <= m_nAwardEnd then
		Chengzhan_TopList_TimeText:SetText(ScriptGlobal_Format("#{CZPH_250430_57}", Chengzhan_DateToStr( m_nAwardBegin ),  Chengzhan_DateToStr( m_nAwardEnd )) )
	else
		if curDay >= m_nSeasonBegin and curDay <= m_nSeasonEnd then	
			Chengzhan_TopList_TimeText:SetText(ScriptGlobal_Format("#{CZPH_250430_56}", Chengzhan_DateToStr( m_nSeasonBegin ),  Chengzhan_DateToStr( m_nSeasonEnd )) )
		else
			Chengzhan_TopList_TimeText:SetText("")
		end 
	end
	local IsValid, GuildID, GuildName, ZoneID, LuoCount, JunCount, ChaoCount, QiCount, Score = TCWL:LuaGetMyCityWarRankData()
	if IsValid == 1 then	
		Chengzhan_TopList_MyAItemText1:SetText(GuildName)
		Chengzhan_TopList_MyAItemText2:SetText(DataPool:GetServerName( ZoneID ))
		Chengzhan_TopList_MyAItemText3:SetText(LuoCount)
		Chengzhan_TopList_MyAItemText4:SetText(JunCount)
		Chengzhan_TopList_MyAItemText5:SetText(ChaoCount)
		-- Chengzhan_TopList_MyAItemText6:SetText(QiCount)
		Chengzhan_TopList_MyAItemText7:SetText(Score)
		Chengzhan_TopList_MyAItemText8:SetText("#{CZPH_250430_13}")
	else
		Chengzhan_TopList_MyAItemText1:SetText("")
		Chengzhan_TopList_MyAItemText2:SetText("")
		Chengzhan_TopList_MyAItemText3:SetText("")
		Chengzhan_TopList_MyAItemText4:SetText("")
		Chengzhan_TopList_MyAItemText5:SetText("")
		-- Chengzhan_TopList_MyAItemText6:SetText("")
		Chengzhan_TopList_MyAItemText7:SetText("")
		Chengzhan_TopList_MyAItemText8:SetText("")
	end

	local guildID, _ = DataPool:GetGuildClanID()
    local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	for i = 1, m_CITYWAR_RANK_PreNUM do
		local index = i - 1
		local IsValid, GuildID, GuildName, ZoneID, LuoCount, JunCount, ChaoCount, QiCount, Score = TCWL:LuaGetCityWarRankData(m_curGroup, index)
		-- PushDebugMessage(GuildID.." "..GuildName)
		if IsValid == 1 and guildID == GuildID and selfZoneWorldID == ZoneID then
			Chengzhan_TopList_MyAItemText1:SetText(GuildName)
			Chengzhan_TopList_MyAItemText2:SetText(DataPool:GetServerName( ZoneID ))
			Chengzhan_TopList_MyAItemText3:SetText(LuoCount)
			Chengzhan_TopList_MyAItemText4:SetText(JunCount)
			Chengzhan_TopList_MyAItemText5:SetText(ChaoCount)
			-- Chengzhan_TopList_MyAItemText6:SetText(QiCount)
			Chengzhan_TopList_MyAItemText7:SetText(Score)
			Chengzhan_TopList_MyAItemText8:SetText(i)
			
		end
		local bar = Chengzhan_TopList_ListInfo:AddChild("Chengzhan_TopList_AItem")
		if not bar then
			return
		end
		if IsValid == 1 then
			bar:GetSubItem("Chengzhan_TopList_AItemText1"):SetText(GuildName)
			bar:GetSubItem("Chengzhan_TopList_AItemText2"):SetText(DataPool:GetServerName( ZoneID ))
			bar:GetSubItem("Chengzhan_TopList_AItemText3"):SetText(LuoCount)
			bar:GetSubItem("Chengzhan_TopList_AItemText4"):SetText(JunCount)
			bar:GetSubItem("Chengzhan_TopList_AItemText5"):SetText(ChaoCount)
			-- bar:GetSubItem("Chengzhan_TopList_AItemText6"):SetText(QiCount)
			bar:GetSubItem("Chengzhan_TopList_AItemText7"):SetText(Score)
			bar:GetSubItem("Chengzhan_TopList_AItemText8"):SetText(i)
		else
			bar:GetSubItem("Chengzhan_TopList_AItemText1"):SetText("#{CZPH_250430_14}")
			bar:GetSubItem("Chengzhan_TopList_AItemText2"):SetText("")
			bar:GetSubItem("Chengzhan_TopList_AItemText3"):SetText("")
			bar:GetSubItem("Chengzhan_TopList_AItemText4"):SetText("")
			bar:GetSubItem("Chengzhan_TopList_AItemText5"):SetText("")
			-- bar:GetSubItem("Chengzhan_TopList_AItemText6"):SetText("")
			bar:GetSubItem("Chengzhan_TopList_AItemText7"):SetText("")
			bar:GetSubItem("Chengzhan_TopList_AItemText8"):SetText("")
		end
	end
	Chengzhan_TopList_SetButtonState()
end
function Chengzhan_TopList_SetButtonState()
	for i = 1, table.getn(m_UICheckButton) do
		if nil ~= m_UICheckButton[i] then
			if i == m_curGroup then
				m_UICheckButton[i]:Disable()
				m_UICheckButton[i]:SetCheck(1)
			else
				m_UICheckButton[i]:Enable()
				m_UICheckButton[i]:SetCheck(0)
			end
		end
	end
end

function Chengzhan_TopList_OnClose()
	Chengzhan_TopList_OnHide()
end
function Chengzhan_TopListCheck_Click(nGroup)
	if m_curGroup == nGroup then
		return
	end
	m_curGroup = nGroup
	Chengzhan_TopList_Update()
end

function Chengzhan_DateToStr( date )
	local year = math.floor(date/10000)
	local month = math.floor(math.mod(date, 10000)/100)
	local day = math.mod(date, 100)
	local str = ScriptGlobal_Format("#{CZPH_250430_58}", year, month, day)
	return str
end