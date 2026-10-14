--!!!reloadscript =NewBangHui_FightGroup_List

local m_Frame_UnifiedPosition


local m_UICheckButton = nil

local m_curGroup = 3


local m_nSeasonBegin = 0
local m_nSeasonEnd = 0
local m_nAwardBegin = 0
local m_nAwardEnd = 0

local m_CITYWAR_RANK_PreNUM = 50

local m_zhanTuanData = 
{
	"#{ZTXT_260511_53}",
	"#{ZTXT_260511_54}",
	"#{ZTXT_260511_55}",
	"#{ZTXT_260511_56}",
	"#{ZTXT_260511_57}",
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function NewBangHui_FightGroup_List_PreLoad()
	this:RegisterEvent("CITYWAR_ZHANTUAN_RANK_OP");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function NewBangHui_FightGroup_List_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedPosition	= NewBangHui_FightGroup_List_Frame:GetProperty("UnifiedPosition");

	m_UICheckButton = {}
	m_UICheckButton[1] = NewBangHui_FightGroup_List_Check2
	m_UICheckButton[2] = NewBangHui_FightGroup_List_Check3
	m_UICheckButton[3] = NewBangHui_FightGroup_List_Check1
	m_UICheckButton[4] = NewBangHui_FightGroup_List_Check4
	m_UICheckButton[5] = nil
	m_UICheckButton[6] = NewBangHui_FightGroup_List_Check5
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function NewBangHui_FightGroup_List_ResetPos()
	NewBangHui_FightGroup_List_Frame:SetProperty("UnifiedPosition", m_Frame_UnifiedPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function NewBangHui_FightGroup_List_OnEvent(event)
	if event == "CITYWAR_ZHANTUAN_RANK_OP" then
		local opType = tonumber(arg0)
		if opType == 1 then
			local nGroup = tonumber(arg1)
			m_nSeasonBegin = tonumber(arg2)
			m_nSeasonEnd = tonumber(arg3)
			m_nAwardBegin = tonumber(arg4)
			m_nAwardEnd = tonumber(arg5)
			m_curGroup = nGroup
			if (this:IsVisible()) then
				NewBangHui_FightGroup_List_Update()
				return
			end
		end
		--打开界面
		NewBangHui_FightGroup_List_Show()
		NewBangHui_FightGroup_List_Update()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		NewBangHui_FightGroup_List_OnHide()
	elseif event == "ADJEST_UI_POS" then
		NewBangHui_FightGroup_List_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		NewBangHui_FightGroup_List_ResetPos()
	end
end

--显示UI
function NewBangHui_FightGroup_List_Show()
	this:Show()
end
--隐藏UI
function NewBangHui_FightGroup_List_OnHide()
	this:Hide()
end

function NewBangHui_FightGroup_List_Update()
	NewBangHui_FightGroup_List_List:Clear()

	-- local curDay = DataPool:GetServerDayTime()
	-- if curDay >= m_nAwardBegin and curDay <= m_nAwardEnd then
		NewBangHui_FightGroup_List_TimeText:SetText(ScriptGlobal_Format("#{ZTXT_260511_102}", Chengzhan_DateToStr( m_nSeasonBegin ),  Chengzhan_DateToStr( m_nSeasonEnd )) )
	-- else
	-- 	if curDay >= m_nSeasonBegin and curDay <= m_nSeasonEnd then	
	-- 		NewBangHui_FightGroup_List_TimeText:SetText(ScriptGlobal_Format("#{CZPH_250430_56}", Chengzhan_DateToStr( m_nSeasonBegin ),  Chengzhan_DateToStr( m_nSeasonEnd )) )
	-- 	else
	-- 		NewBangHui_FightGroup_List_TimeText:SetText("")
	-- 	end 
	-- end

	local guildID, _ = DataPool:GetGuildClanID()
    local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	for i = 1, m_CITYWAR_RANK_PreNUM do
		local IsValid, GuildID, GuildName, ZoneID, ZhanTuanID, ZhanTuanScore = GuildZhanTuanUI:LuaFnGetCityWarZhanTuanRankData(m_curGroup, i-1)
		-- PushDebugMessage(GuildID.." "..GuildName.." "..ZhanTuanID)
		-- ZhanTuanID = 1
		if IsValid == 1 and nil ~= m_zhanTuanData[ZhanTuanID] then
			local bar = NewBangHui_FightGroup_List_List:AddChild("NewBangHui_FightGroup_List_ItemCommon")
			if not bar then
				return
			end
			-- PushDebugMessage(m_zhanTuanData[ZhanTuanID])
			local zhanTuanName = GuildName --..m_zhanTuanData[ZhanTuanID]
			bar:GetSubItem("NewBangHui_FightGroup_List_ItemText1"):SetText(zhanTuanName)
			bar:GetSubItem("NewBangHui_FightGroup_List_ItemText2"):SetText(DataPool:GetServerName( ZoneID ))
			bar:GetSubItem("NewBangHui_FightGroup_List_ItemText3"):SetText(ZhanTuanScore)
			bar:GetSubItem("NewBangHui_FightGroup_List_ItemText4"):SetText(i)
		end
	end
	NewBangHui_FightGroup_List_SetButtonState()
end
function NewBangHui_FightGroup_List_SetButtonState()
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

function NewBangHui_FightGroup_List_OnClose()
	NewBangHui_FightGroup_List_OnHide()
end
function NewBangHui_FightGroup_ListCheck_Clicked(nGroup)
	if m_curGroup == nGroup then
		return
	end
	m_curGroup = nGroup
	NewBangHui_FightGroup_List_Update()
end

function Chengzhan_DateToStr( date )
	local year = math.floor(date/10000)
	local month = math.floor(math.mod(date, 10000)/100)
	local day = math.mod(date, 100)
	local str = ScriptGlobal_Format("#{ZTXT_260511_110}", year, month, day)
	return str
end