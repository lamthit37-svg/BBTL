
local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition
local g_ShowUI = 0

local g_TitleText_Master = { "#{BSYH_150519_149}" , "#{BSYH_150519_153}" ,"#{BSYH_150519_157}" ,"#{BSYH_150519_166}" ,"#{BSYH_150519_172}"}
local g_TitleText_Recruit = { "#{BSYH_150519_149}" , "#{BSYH_150519_153}" ,"#{BSYH_150519_164}" ,"#{BSYH_150519_169}" ,"#{BSYH_150519_175}"}

local g_StageText_Master = { "#{BSYH_150519_150}" , "#{BSYH_150519_154}" ,"#{BSYH_150519_158}" ,"#{BSYH_150519_167}" ,"#{BSYH_150519_173}"}
local g_StageText_Recruit = { "#{BSYH_150519_152}" , "#{BSYH_150519_156}" ,"#{BSYH_150519_165}" ,"#{BSYH_150519_170}" ,"#{BSYH_150519_176}"}

local g_SubStageText_Master = { 
	[ 1 ] = "#{BSYH_150519_151}" , 
	[ 2 ] = "#{BSYH_150519_155}" ,
	[ 3 ] = {"#{BSYH_150519_159}" ,"#{BSYH_150519_160}" ,"#{BSYH_150519_161}" ,"#{BSYH_150519_162}" ,"#{BSYH_150519_163}" },
	[ 4 ] = "#{BSYH_150519_168}" ,
	[ 5 ] = "#{BSYH_150519_174}"
	
}
local g_SubStageText_Recruit = { 
	[ 1 ] = "#{BSYH_150519_151}" , 
	[ 2 ] = "#{BSYH_150519_155}" ,
	[ 3 ] = {"#{BSYH_150519_159}" ,"#{BSYH_150519_160}" ,"#{BSYH_150519_161}" ,"#{BSYH_150519_162}" ,"#{BSYH_150519_163}" },
	[ 4 ] = "#{BSYH_150519_171}" ,
	[ 5 ] = "#{BSYH_150519_177}"

}

local g_StageImage = {
	[ 1 ] = "set:Baishi image:Baishi_0" , 
	[ 2 ] = "set:Baishi1 image:Baishi_1",
	[ 3 ] = "set:Baishi2 image:Baishi_2",
	[ 4 ] = "set:Baishi3 image:Baishi_3" ,
	[ 5 ] = "set:Baishi4 image:Baishi_4"

}

local g_SubStageTextCtrl = {}

function Baishi_PreLoad()
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	-- 切换场景
	this:RegisterEvent("SCENE_TRANSED",true)

	this:RegisterEvent("RECRUIT_DUNGEON_UI_SHOW")

	this:RegisterEvent("RECRUIT_DUNGEON_UI_MINI_SHOW")
	
	this:RegisterEvent("UI_COMMAND")
	
	this:RegisterEvent("RECRUIT_DUNGEON_UI_MSG")
	
end

function Baishi_OnLoad()

	g_SubStageTextCtrl[ 1 ] = Baishi_Teacher_Text2_1
	g_SubStageTextCtrl[ 2 ] = Baishi_Teacher_Text2_2
	g_SubStageTextCtrl[ 3 ] = Baishi_Teacher_Text2_3
	g_SubStageTextCtrl[ 4 ] = Baishi_Teacher_Text2_4
	g_SubStageTextCtrl[ 5 ] = Baishi_Teacher_Text2_5
	
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Baishi_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= Baishi_Frame:GetProperty("UnifiedYPosition");
end

function Baishi_OnEvent(event)
	
	if( event == "ADJEST_UI_POS" ) then
		Baishi_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		Baishi_ResetPos()
		
	elseif( event == "RECRUIT_DUNGEON_UI_SHOW" ) then
		if tonumber(arg0) == 0 then
			this:Hide()
		elseif tonumber(arg0) == 1 then
			if tonumber(arg1) ~= 0 then
				Baishi_Teacher_StopWatch:SetProperty("Timer", tostring( tonumber(arg1) / 1000 ) )
			end
			this:Show()
		end
	elseif( event == "RECRUIT_DUNGEON_UI_MSG" ) then
		Baishi_UpdateText(tonumber(arg0) ,tonumber(arg1) ,tonumber(arg2) )
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20150512 ) then
		g_ShowUI = 1
	elseif event == "SCENE_TRANSED" then
		local sceneid = GetSceneID()
		if sceneid and sceneid ~= 659 then
			this:Hide()
		end
	end
end

function Baishi_UpdateText(bWho , nStage , nSubStage)
	
	Baishi_Reset()	
	
	if nStage < 0 or nStage > 4 then
		return
	end
	
	if nStage == 2 and (nSubStage < 1 or nSubStage > 5) then
		return
	end
	
	
	if bWho == 0 then				--师傅的信息
	
		Baishi_Teacher_DragTitle:SetText(g_TitleText_Master[ nStage + 1 ] )
		Baishi_Teacher_Text:SetText(g_StageText_Master[ nStage + 1 ] )
		
		Baishi_Teacher_Image:SetProperty("Image" , g_StageImage[ nStage + 1 ])
		if nStage == 2 then
			
			for i = 1 , 5 do
				if i < nSubStage then
					local strText = ScriptGlobal_Format(g_SubStageText_Master[ 3 ][ i ] , 1)
					g_SubStageTextCtrl[ i ] :SetText(strText)
				else
					local strText = ScriptGlobal_Format(g_SubStageText_Master[ 3 ][ i ] , 0)
					g_SubStageTextCtrl[ i ] :SetText(strText)
				end
			end
		
		elseif nStage == 4 then
			if nSubStage > 0 then
				local strText = ScriptGlobal_Format(g_SubStageText_Master[ nStage + 1 ] , 1)
				g_SubStageTextCtrl[ 1 ] :SetText(strText)
			else
				local strText = ScriptGlobal_Format(g_SubStageText_Master[ nStage + 1 ] , 0)
				g_SubStageTextCtrl[ 1 ] :SetText(strText)
			end
			g_SubStageTextCtrl[ 2 ] :SetText("#{BSYH_150519_256}")
		else
			local strText = ScriptGlobal_Format(g_SubStageText_Master[ nStage + 1 ] , 0)
			g_SubStageTextCtrl[ 1 ] :SetText(strText)
		end
	
	
	elseif bWho == 1 then			--新徒弟的信息
	
		Baishi_Teacher_DragTitle:SetText(g_TitleText_Recruit[ nStage + 1 ] )
		Baishi_Teacher_Text:SetText(g_StageText_Recruit[ nStage + 1 ] )
		
		Baishi_Teacher_Image:SetProperty("Image" , g_StageImage[ nStage + 1 ])
		
		if nStage == 2 then
			
			for i = 1 , 5 do
				if i < nSubStage then
					local strText = ScriptGlobal_Format(g_SubStageText_Recruit[ 3 ][ i ] , 1)
					g_SubStageTextCtrl[ i ] :SetText(strText)
				else
					local strText = ScriptGlobal_Format(g_SubStageText_Recruit[ 3 ][ i ] , 0)
					g_SubStageTextCtrl[ i ] :SetText(strText)
				end
			end
		
		elseif nStage == 4 then
			if nSubStage > 0 then
				local strText = ScriptGlobal_Format(g_SubStageText_Recruit[ nStage + 1 ] , 1)
				g_SubStageTextCtrl[ 1 ] :SetText(strText)
			else
				local strText = ScriptGlobal_Format(g_SubStageText_Recruit[ nStage + 1 ] , 0)
				g_SubStageTextCtrl[ 1 ] :SetText(strText)
			end
			g_SubStageTextCtrl[ 2 ] :SetText("#{BSYH_150519_256}")
		else
			local strText = ScriptGlobal_Format(g_SubStageText_Recruit[ nStage + 1 ] , 0)
			g_SubStageTextCtrl[ 1 ] :SetText(strText)
		end

	end

end

function Baishi_Reset()
	
	Baishi_Teacher_StopWatchText:SetText("#{BSYH_150519_297}")
	Baishi_Teacher_DragTitle:SetText("")
	Baishi_Teacher_Text:SetText("")
	for i = 1 , 5 do
		g_SubStageTextCtrl[ i ] :SetText("")
	end
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function Baishi_ResetPos()
	Baishi_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Baishi_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
--================================================
function Baishi_OnShowMiniUI()
	this:Hide()
	Lua_ToggleRecruitDungeonMiniUI(1)
end
