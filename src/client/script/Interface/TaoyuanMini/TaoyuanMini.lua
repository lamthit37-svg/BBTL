
local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

local g_TitleText = { "#{JBLC_150528_308}" , "#{JBLC_150528_313}" ,"#{JBLC_150528_318}"}

function TaoyuanMini_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("SWEAR_DUNGEON_UI_SHOW")

	this:RegisterEvent("SWEAR_DUNGEON_UI_MINI_SHOW")
	
	this:RegisterEvent("SWEAR_DUNGEON_UI_MSG")

end

function TaoyuanMini_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= TaoyuanMini_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= TaoyuanMini_Frame:GetProperty("UnifiedYPosition");

end

function TaoyuanMini_OnEvent(event)
	
	if( event == "ADJEST_UI_POS" ) then
		TaoyuanMini_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		TaoyuanMini_ResetPos()
	elseif( event == "SWEAR_DUNGEON_UI_MSG" ) then
		TaoyuanMini_UpdateText(tonumber(arg0) ,tonumber(arg1) ,tonumber(arg2) ,tonumber(arg3) )
	elseif( event == "SWEAR_DUNGEON_UI_MINI_SHOW" ) then
		if tonumber(arg0) == 0 then
			this:Hide()
		elseif tonumber(arg0) == 1 then
			this:Show()
		end
	end
end

function TaoyuanMini_UpdateText(nStage , nObj_1 , nObj_2 , nObj_3)
	
	TaoyuanMini_Reset()	
	
	if nStage < 0 or nStage > 2 then
		return
	end
	
	TaoyuanMini_PageHeader:SetText( g_TitleText[ nStage + 1 ] )

end

function TaoyuanMini_Reset()

	TaoyuanMini_PageHeader:SetText("")

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function TaoyuanMini_ResetPos()
	TaoyuanMini_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	TaoyuanMini_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
--================================================

function TaoyuanMini_OnShowNormalUI()
	this:Hide()
	Lua_ToggleSwearDungeonUI(1)
end
