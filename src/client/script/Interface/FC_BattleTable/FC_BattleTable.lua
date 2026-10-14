-- !!!reloadscript =FC_BattleTable
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

local m_cambat4UI = {}
local m_cambat2UI = {}
local m_cambat1UI = {}
local m_cambatUI = {}
--预加载函数，可以而且只能在这里注册脚本关心的事件
function FC_BattleTable_PreLoad()
	this:RegisterEvent("ZJZDPVP_UIOP", true)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function FC_BattleTable_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= FC_BattleTable_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= FC_BattleTable_Frame:GetProperty("UnifiedYPosition");
	
	local beginIndex = 0
	for i = 1, 8 do
		m_cambat4UI[i] = {}
		m_cambat4UI[i]["NameUI"] = _G["FC_BattleTable_Name2"..i]
		m_cambat4UI[i]["SeverUI"] = _G["FC_BattleTable_Sever2"..i]
	end
	for i = 1, 4 do
		m_cambat2UI[i] = {}
		m_cambat2UI[i]["NameUI"] = _G["FC_BattleTable_Name3"..i]
		m_cambat2UI[i]["SeverUI"] = _G["FC_BattleTable_Sever3"..i]
	end
	for i = 1, 2 do
		m_cambat1UI[i] = {}
		m_cambat1UI[i]["NameUI"] = _G["FC_BattleTable_Name4"..i]
		m_cambat1UI[i]["SeverUI"] = _G["FC_BattleTable_Sever4"..i]
	end

	m_cambatUI["NameUI"] = FC_BattleTable_Name51
	m_cambatUI["SeverUI"] = FC_BattleTable_Name51_Sever
	-- m_cambatUI["AnimateUI"] = _G["FC_BattleTable_Name51Animate"]

	
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function FC_BattleTable_ResetPos()
	FC_BattleTable_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	FC_BattleTable_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function FC_BattleTable_OnEvent(event)
	if( event == "ZJZDPVP_UIOP" ) then--
		-- PushDebugMessage("111111111111111111")
		local opType = tonumber(arg0)
		if opType == 1 then
			if (this:IsVisible()) then
				FC_BattleTable_Update()
				return
			end
			FC_BattleTable_Show()
			FC_BattleTable_Update()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FC_BattleTable_Hide()
	elseif event == "ADJEST_UI_POS" then
		FC_BattleTable_ResetPos()
	end
end

--显示UI
function FC_BattleTable_Show()
	FC_BattleTable_ClearData()
	this:Show()
	
end
--隐藏UI
function FC_BattleTable_Hide()
	FC_BattleTable_ClearData()

	this:Hide()
end

--清除数据
function FC_BattleTable_ClearData()
end
--更新
function FC_BattleTable_Update()
	-- local aName,aZoneId,bName,bZoneId,victoryTeam = ZJZDPVPAct:Lua_GetZJZDPVPData(5)
	-- PushDebugMessage(aName.." "..bName)
	--第一批，直接用数据填充
	local beginIndex = 0
	local uiIndex = 1
	for i = 1, 4 do
		local aName,aZoneId,bName,bZoneId,victoryTeam = ZJZDPVPAct:Lua_GetZJZDPVPData(beginIndex)
		beginIndex  = beginIndex + 1
		-- PushDebugMessage(aZoneId.." "..bZoneId)
		if aName ~= "" and aZoneId ~=0 and aZoneId ~= -1 then
			--- 得到服务器名称
			m_cambat4UI[uiIndex].NameUI:SetText("#cfff263"..aName)
			m_cambat4UI[uiIndex].SeverUI:SetText("#cfff263"..DataPool:GetServerName( aZoneId ))
		else	
			m_cambat4UI[uiIndex].NameUI:SetText("#{DFXD_250326_112}")
			m_cambat4UI[uiIndex].SeverUI:SetText("")
		end
		uiIndex = uiIndex + 1
		if bName ~= "" and bZoneId ~=0 and bZoneId ~= -1 then
			--- 得到服务器名称
			m_cambat4UI[uiIndex].NameUI:SetText("#cfff263"..bName)
			m_cambat4UI[uiIndex].SeverUI:SetText("#cfff263"..DataPool:GetServerName( bZoneId ))
		else	
			m_cambat4UI[uiIndex].NameUI:SetText("#{DFXD_250326_112}")
			m_cambat4UI[uiIndex].SeverUI:SetText("")
		end
		uiIndex = uiIndex + 1
	end
	
	--下一个区块永远取上一个区块胜利的信息进行填充
	beginIndex = 0
	for i = 1, 4 do
		local strName, strServerName = FC_BattleTable_GetZJZDPVPDataVictory(beginIndex)
		m_cambat2UI[i].NameUI:SetText("#cfff263"..strName)
		m_cambat2UI[i].SeverUI:SetText("#cfff263"..strServerName)
		beginIndex  = beginIndex + 1
	end
	
	beginIndex = 4
	for i = 1, 2 do
		local strName, strServerName = FC_BattleTable_GetZJZDPVPDataVictory(beginIndex)
		m_cambat1UI[i].NameUI:SetText("#cfff263"..strName)
		m_cambat1UI[i].SeverUI:SetText("#cfff263"..strServerName)
		beginIndex  = beginIndex + 1
	end
	beginIndex = 6
	local strName, strServerName = FC_BattleTable_GetZJZDPVPDataVictory(beginIndex)
	m_cambatUI.NameUI:SetText("#c6a3906"..strName)
	m_cambatUI.SeverUI:SetText("#cfff263"..strServerName)
end
function FC_BattleTable_GetZJZDPVPDataVictory(index)
	local aName,aZoneId,bName,bZoneId,victoryTeam = ZJZDPVPAct:Lua_GetZJZDPVPData(index)
	if victoryTeam == 1 and aName ~= "" and aZoneId ~=0 and aZoneId ~= -1 then
		--- 得到服务器名称
		return aName, DataPool:GetServerName( aZoneId )
	elseif victoryTeam == 2 and bName ~= "" and bZoneId ~=0 and bZoneId ~= -1 then
		--- 得到服务器名称
		return bName, DataPool:GetServerName( bZoneId )
	end
	return "#{DFXD_250326_112}", ""
end
--##############点击事件##############
function FC_BattleTable_OpenAwardUI()
	PushEvent("ZJZDPVP_UIOP",10)
end
--####################################