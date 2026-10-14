
local g_Frame_UnifiedXPosition
local g_Frame_UnifiedYPosition

local g_TitleText = { "#{JBLC_150528_308}" , "#{JBLC_150528_313}" ,"#{JBLC_150528_318}"}

local g_MainText = { "#{JBLC_150528_309}" , "#{JBLC_150528_314}" ,"#{JBLC_150528_316}"}

local g_SubObjectText = { 
	[ 1 ] = {"#{JBLC_150528_310}" , "#{JBLC_150528_311}" ,"#{JBLC_150528_312}"},
	[ 2 ] = "#{JBLC_150528_315}" ,
	[ 3 ] = "#{JBLC_150528_317}",
	
}

local g_StageImage = {
	[ 1 ] = "set:hdrc_16 image:hdrc_16_3" , 
	[ 2 ] = "set:hdrc_16 image:hdrc_16_4" , 
	[ 3 ] = "set:hdrc_16 image:hdrc_16_5" , 

}

function Taoyuan_PreLoad()
	
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)

	this:RegisterEvent("SWEAR_DUNGEON_UI_SHOW")

	this:RegisterEvent("SWEAR_DUNGEON_UI_MINI_SHOW")
	
	this:RegisterEvent("UI_COMMAND")
	
	this:RegisterEvent("SWEAR_DUNGEON_UI_MSG")
	
end

function Taoyuan_OnLoad()

	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= Taoyuan_Frame:GetProperty("UnifiedXPosition")
	g_Frame_UnifiedYPosition	= Taoyuan_Frame:GetProperty("UnifiedYPosition")
end

function Taoyuan_OnEvent(event)
	
	if( event == "ADJEST_UI_POS" ) then
		Taoyuan_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		Taoyuan_ResetPos()
	elseif( event == "SWEAR_DUNGEON_UI_SHOW" ) then
		if tonumber(arg0) == 0 then
			this:Hide()
		elseif tonumber(arg0) == 1 then
			this:Show()
		end
	elseif( event == "SWEAR_DUNGEON_UI_MSG" ) then
		Taoyuan_UpdateText(tonumber(arg0) ,tonumber(arg1) ,tonumber(arg2) ,tonumber(arg3) )
	end
end

function Taoyuan_UpdateText(nStage , nObj_1 , nObj_2 , nObj_3)
	
	Taoyuan_Reset()	
	
	if nStage < 0 or nStage > 2 then
		return
	end
	
	Taoyuan_PageHeader:SetText( g_TitleText[ nStage + 1 ] )
	
	Taoyuan_ImageInfo1:SetText( g_MainText[ nStage + 1 ] )
	
	Taoyuan_Image:SetProperty("Image" , g_StageImage[ nStage + 1 ])
	
	if nStage == 0 then

		Taoyuan_ImageInfo2:SetText( g_SubObjectText[ 1 ][ 1 ] )
		Taoyuan_ImageText2:SetText("#cfff263"..tostring(nObj_1).."/1")

		Taoyuan_ImageInfo3:SetText( g_SubObjectText[ 1 ][ 2 ]  )
		Taoyuan_ImageText3:SetText("#cfff263"..tostring(nObj_2).."/1")

		Taoyuan_ImageInfo4:SetText( g_SubObjectText[ 1 ][ 3 ] )
		Taoyuan_ImageText4:SetText("#cfff263"..tostring(nObj_3).."/1")
	end
	
	if nStage == 1 then
	
		Taoyuan_ImageInfo2:SetText(g_SubObjectText[ 2 ] )
		Taoyuan_ImageText2:SetText("#cfff263".."0/1")

	end
	
	if nStage == 2 then
	
		Taoyuan_ImageInfo2:SetText(g_SubObjectText[ 3 ] )
		Taoyuan_ImageText2:SetText("#cfff263".."0/1")

	end

end

function Taoyuan_Reset()
	
	Taoyuan_PageHeader:SetText("")
	Taoyuan_ImageInfo1:SetText("")
	Taoyuan_ImageInfo2:SetText("")
	Taoyuan_ImageInfo3:SetText("")
	Taoyuan_ImageInfo4:SetText("")
	
	Taoyuan_ImageText2:SetText("")
	Taoyuan_ImageText3:SetText("")
	Taoyuan_ImageText4:SetText("")
	
	Taoyuan_Image:SetProperty("Image" , "")
end
--================================================
-- 恢复界面的默认相对位置
--================================================
function Taoyuan_ResetPos()
	Taoyuan_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	Taoyuan_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end
--================================================
function Taoyuan_OnShowMiniUI()
	this:Hide()
	Lua_ToggleSwearDungeonMiniUI(1)
end
