--扫雷小界面
-- !!!reloadscript =Minesweeper_Mini
local m_Frame_UnifiedXPosition
local m_Frame_UnifiedYPosition

--预加载函数，可以而且只能在这里注册脚本关心的事件
function Minesweeper_Mini_PreLoad()
	this:RegisterEvent("GUILDSAOLEI_OP")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

--加载窗口的时候调用的函数，加载窗口时调用一次
function Minesweeper_Mini_OnLoad()
	-- 保存界面的默认相对位置
	m_Frame_UnifiedXPosition	= Minesweeper_Mini_Frame:GetProperty("UnifiedXPosition");
	m_Frame_UnifiedYPosition	= Minesweeper_Mini_Frame:GetProperty("UnifiedYPosition");
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Minesweeper_Mini_ResetPos()
	Minesweeper_Mini_Frame:SetProperty("UnifiedXPosition", m_Frame_UnifiedXPosition);
	Minesweeper_Mini_Frame:SetProperty("UnifiedYPosition", m_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function Minesweeper_Mini_OnEvent(event)
	if (event == "GUILDSAOLEI_OP") then
		local opType = tonumber(arg0)
		if opType == 1 then--进入场景要显示界面
			if (this:IsVisible()) then
				return
			end
			-- Minesweeper_Mini_Show()
		elseif opType == 1001 then --关闭大界面 打开小界面
			if (this:IsVisible()) then
				return
			end
			Minesweeper_Mini_Show()
		end
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		local sceneLogicID = GetSceneID()
		if sceneLogicID == 839 then
			return
		end
		Minesweeper_Mini_Hide()
	elseif event == "ADJEST_UI_POS" then
		Minesweeper_Mini_ResetPos()
	end
end

--显示UI
function Minesweeper_Mini_Show()
	Minesweeper_Mini_ClearData()
	this:Show()
	
end
--隐藏UI
function Minesweeper_Mini_Hide()
	Minesweeper_Mini_ClearData()

	this:Hide()
end

--清除数据
function Minesweeper_Mini_ClearData()
end
--更新
function Minesweeper_Mini_Update()
end
--##############点击事件##############
function Minesweeper_Mini_CloseWindow()
	PushEvent("GUILDSAOLEI_OP", 1000)
	Minesweeper_Mini_Hide()
end
--####################################