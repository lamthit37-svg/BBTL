--!!!reloadscript =Chengzhan_ZhanTuan_TopList

local g_Chengzhan_ZhanTuan_TopList_Frame_UnifiedXPosition
local g_Chengzhan_ZhanTuan_TopList_Frame_UnifiedYPosition

local m_CITYWAR_RANK_PreNUM = 10

local m_zhanTuanData = 
{
	"#{ZTXT_260511_53}",
	"#{ZTXT_260511_54}",
	"#{ZTXT_260511_55}",
	"#{ZTXT_260511_56}",
	"#{ZTXT_260511_57}",
}

local m_zhanTuanUI = {}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function Chengzhan_ZhanTuan_TopList_PreLoad()
	this:RegisterEvent("GUILD_ZHANTUAN_RANK_OP");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Chengzhan_ZhanTuan_TopList_OnLoad()
	-- 保存界面的默认相对位置
	g_Chengzhan_ZhanTuan_TopList_Frame_UnifiedXPosition	= Chengzhan_ZhanTuan_TopList_Frame:GetProperty("UnifiedXPosition");
	g_Chengzhan_ZhanTuan_TopList_Frame_UnifiedYPosition	= Chengzhan_ZhanTuan_TopList_Frame:GetProperty("UnifiedYPosition");

	for i = 1, 5 do
		m_zhanTuanUI[i] = {}
		m_zhanTuanUI[i].MainItem = _G["Chengzhan_ZhanTuan_TopList_AItem"..i]
		m_zhanTuanUI[i].Rank = _G["Chengzhan_ZhanTuan_TopList_AItem"..i.."Text1"]
		m_zhanTuanUI[i].Name = _G["Chengzhan_ZhanTuan_TopList_AItem"..i.."Text2"]
		m_zhanTuanUI[i].Equip = _G["Chengzhan_ZhanTuan_TopList_AItem"..i.."Text3"]
	end

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Chengzhan_ZhanTuan_TopList_ResetPos()
	Chengzhan_ZhanTuan_TopList_Frame:SetProperty("UnifiedXPosition", g_Chengzhan_ZhanTuan_TopList_Frame_UnifiedXPosition);
	Chengzhan_ZhanTuan_TopList_Frame:SetProperty("UnifiedYPosition", g_Chengzhan_ZhanTuan_TopList_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Chengzhan_ZhanTuan_TopList_OnEvent(event)
	if event == "GUILD_ZHANTUAN_RANK_OP" then
		local opType = tonumber(arg0)
		if opType == 1 then
			if (this:IsVisible()) then
				Chengzhan_ZhanTuan_TopList_Update()
				return
			end
		end
		--打开界面
		Chengzhan_ZhanTuan_TopList_Show()
		Chengzhan_ZhanTuan_TopList_Update()
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Chengzhan_ZhanTuan_TopList_OnHide()
	elseif event == "ADJEST_UI_POS" then
		Chengzhan_ZhanTuan_TopList_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Chengzhan_ZhanTuan_TopList_ResetPos()
	end
end

--显示UI
function Chengzhan_ZhanTuan_TopList_Show()
	this:Show()
end
--隐藏UI
function Chengzhan_ZhanTuan_TopList_OnHide()
	this:Hide()
end

function Chengzhan_ZhanTuan_TopList_Update()

	for i = 1, table.getn(m_zhanTuanUI) do
		m_zhanTuanUI[i].MainItem:Hide()
	end

	local guildID, _ = DataPool:GetGuildClanID()
    local selfZoneWorldID = DataPool:GetSelfZoneWorldID()
	local length = GuildZhanTuanUI:LuaFnGetGuildZhanTuanRankDataLength()
	-- PushDebugMessage(length)
	local validNum = 0
	for i = 1, length do
		-- PushDebugMessage(i)
		local ZoneID, GuildName, ZhanTuanID, ZhanTuanScore = GuildZhanTuanUI:LuaFnGetGuildZhanTuanRankData(i-1)
		-- ZhanTuanID = 1
		if nil ~= ZoneID and nil ~= m_zhanTuanData[ZhanTuanID] then--
			-- PushDebugMessage(m_zhanTuanData[ZhanTuanID])
			local zhanTuanName = GuildName..m_zhanTuanData[ZhanTuanID]
			validNum = validNum + 1
			if nil ~= m_zhanTuanUI[validNum] then
				m_zhanTuanUI[validNum].MainItem:Show()
				m_zhanTuanUI[validNum].Rank:SetText(i)
				m_zhanTuanUI[validNum].Name:SetText(zhanTuanName)
				m_zhanTuanUI[validNum].Equip:SetText(ZhanTuanScore)
			end
		end
	end
end

function Chengzhan_ZhanTuan_TopList_OnClose()
	Chengzhan_ZhanTuan_TopList_OnHide()
end
