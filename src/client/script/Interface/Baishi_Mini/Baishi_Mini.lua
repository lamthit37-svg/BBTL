
local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

local g_TitleText_Master = { "#{BSYH_150519_149}" , "#{BSYH_150519_153}" ,"#{BSYH_150519_157}" ,"#{BSYH_150519_166}" ,"#{BSYH_150519_172}"}
local g_TitleText_Recruit = { "#{BSYH_150519_149}" , "#{BSYH_150519_153}" ,"#{BSYH_150519_164}" ,"#{BSYH_150519_169}" ,"#{BSYH_150519_175}"}

function Baishi_Mini_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 切换场景
	this:RegisterEvent("SCENE_TRANSED",true)

	this:RegisterEvent("RECRUIT_DUNGEON_UI_SHOW")

	this:RegisterEvent("RECRUIT_DUNGEON_UI_MINI_SHOW")
	
	this:RegisterEvent("RECRUIT_DUNGEON_UI_MSG")
	
	

end

function Baishi_Mini_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Baishi_Mini_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Baishi_Mini_Frame:GetProperty("UnifiedYPosition");

end

function Baishi_Mini_OnEvent(event)
	
	if( event == "ADJEST_UI_POS" ) then
		Baishi_Mini_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		Baishi_Mini_ResetPos()

	elseif( event == "RECRUIT_DUNGEON_UI_MINI_SHOW" ) then
		if tonumber(arg0) == 0 then
			this:Hide()
		elseif tonumber(arg0) == 1 then
			this:Show()
		end
	elseif( event == "RECRUIT_DUNGEON_UI_SHOW" ) then
		if tonumber(arg0) == 1 then
			if tonumber(arg1) ~= 0 then
				Baishi_Mini_StopWatch:SetProperty("Timer", tostring( tonumber(arg1) / 1000 ) )
			end
		end
	elseif( event == "RECRUIT_DUNGEON_UI_MSG" ) then
		Baishi_Mini_UpdateText(tonumber(arg0) ,tonumber(arg1) ,tonumber(arg2) )
	elseif event == "SCENE_TRANSED" then
		local sceneid = GetSceneID()
		if sceneid and sceneid ~= 659 then
			this:Hide()
		end
	end
end

function Baishi_Mini_UpdateText(bWho , nStage , nSubStage)
	
	Baishi_Mini_Reset()	
	
	if nStage < 0 or nStage > 4 then
		return
	end
	
	if bWho == 0 then				--师傅的信息
	
		Baishi_Mini_DragTitle:SetText(g_TitleText_Master[ nStage + 1 ] )
	
	elseif bWho == 1 then			--新徒弟的信息
	
		Baishi_Mini_DragTitle:SetText(g_TitleText_Recruit[ nStage + 1 ] )

	end

end

function Baishi_Mini_Reset()

	Baishi_Mini_DragTitle:SetText("")

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Baishi_Mini_ResetPos()
	Baishi_Mini_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Baishi_Mini_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
--================================================

function Baishi_Mini_OnShowNormalUI()
	this:Hide()
	Lua_ToggleRecruitDungeonUI(1)
end
