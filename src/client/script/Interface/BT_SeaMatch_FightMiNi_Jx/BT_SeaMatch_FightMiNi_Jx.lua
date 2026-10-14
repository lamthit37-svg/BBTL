--试剑天下最小化
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

--预加载函数，可以而且只能在这里注册脚本关心的事件
function BT_SeaMatch_FightMiNi_Jx_PreLoad()
	this:RegisterEvent("DFS_FIGHTUI_OP")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("DFS_JIESUAN", false)
	this:RegisterEvent("DFS_CLOSEUI", false)
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function BT_SeaMatch_FightMiNi_Jx_ResetPos()
	BT_SeaMatch_FightMiNi_Jx_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	BT_SeaMatch_FightMiNi_Jx_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function BT_SeaMatch_FightMiNi_Jx_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= BT_SeaMatch_FightMiNi_Jx_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedXPosition	= BT_SeaMatch_FightMiNi_Jx_Frame:GetProperty("UnifiedYPosition");
end


--响应事件的函数，当注册的事件发生时会调用的函数
function BT_SeaMatch_FightMiNi_Jx_OnEvent(event)
	-- PushDebugMessage(event)
	if event == "DFS_FIGHTUI_OP" then
		local  opType = tonumber(arg0)
		if opType == 8 then --打开界面
			if (this:IsVisible()) then
				BT_SeaMatch_FightMiNi_Jx_Update()
				return
			end
			BT_SeaMatch_FightMiNi_Jx_Show()
			BT_SeaMatch_FightMiNi_Jx_Update()
		elseif opType == 7 then --关闭界面
			BT_SeaMatch_FightMiNi_Jx_Hide()
		end
	elseif (event == "DFS_JIESUAN") then
		BT_SeaMatch_FightMiNi_Jx_Hide()
	elseif (event == "DFS_CLOSEUI") then
		BT_SeaMatch_FightMiNi_Jx_Hide()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		BT_SeaMatch_FightMiNi_Jx_Hide()
	elseif event == "ADJEST_UI_POS" then
		BT_SeaMatch_FightMiNi_Jx_ResetPos()
	end
end

--显示UI
function BT_SeaMatch_FightMiNi_Jx_Show()
	BT_SeaMatch_FightMiNi_Jx_ClearData()

	this:Show()
	
end
--隐藏UI
function BT_SeaMatch_FightMiNi_Jx_Hide()
	BT_SeaMatch_FightMiNi_Jx_ClearData()

	this:Hide()
end

--清除数据
function BT_SeaMatch_FightMiNi_Jx_ClearData()
	
end
--更新
function BT_SeaMatch_FightMiNi_Jx_Update()
	local teamAName, teamBName = DFS:LuaFnGetDfsTeamName()
	if "" == teamAName or "" == teamBName then
		BT_SeaMatch_FightMiNi_Jx_Hide()
		return
	end
end

--##############点击事件##############
function BT_SeaMatch_FightMiNi_Jx_OnShowNormalUI()
	PushEvent("DFS_FIGHTUI_OP", 7)
end
--####################################