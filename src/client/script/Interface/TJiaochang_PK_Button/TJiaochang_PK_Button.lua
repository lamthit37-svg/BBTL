--校场 休息室 寻找对手
--!!!reloadscript =TJiaochang_PK_Button
local g_Frame_UnifiedPosition;


--加载界面
function TJiaochang_PK_Button_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)				-- 界面 
	
	this:RegisterEvent("ON_SCENE_TRANS", false)
	this:RegisterEvent("ON_SERVER_TRANS",false)

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end


function TJiaochang_PK_Button_OnLoad()
	g_Frame_UnifiedPosition = TJiaochang_PK_Button_Frame:GetProperty("UnifiedPosition")
end

-- OnEvent
function TJiaochang_PK_Button_OnEvent(event)
	--
	if( event == "UI_COMMAND" and tonumber( arg0 ) == 99984701 ) then
		TJiaochang_PK_Button_Show()

	elseif ( event == "ON_SCENE_TRANS" or event == "ON_SERVER_TRANS" ) then
		TJiaochang_PK_Button_CloseWindow()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
		TJiaochang_PK_Button_OnResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		TJiaochang_PK_Button_OnResetPos()
	end
end

function TJiaochang_PK_Button_Init()
end


function TJiaochang_PK_Button_Show()
	TJiaochang_PK_Button_Init()
	this:Show()
end


function TJiaochang_PK_Button_OnClick()
	--打开界面
	if(IsWindowShow("TJiaochang_PK_List2")) then
		CloseWindow("TJiaochang_PK_List2", true)
	else
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnSeekRoomMember" )
			Set_XSCRIPT_ScriptID( 999847 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()	
	end 
end

function TJiaochang_PK_Button_CloseWindow()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function TJiaochang_PK_Button_OnResetPos()
  TJiaochang_PK_Button_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition);
end

