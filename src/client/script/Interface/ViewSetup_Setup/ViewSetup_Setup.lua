
local g_ViewSetup_Setup_Frame_UnifiedPosition;

--===============================================
-- OnLoad()
--===============================================
function ViewSetup_Setup_PreLoad()

	this:RegisterEvent("OPEN_OPTIMIZE")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function ViewSetup_Setup_OnLoad()
	g_ViewSetup_Setup_Frame_UnifiedPosition = ViewSetup_Setup_Frame:GetProperty("UnifiedPosition");
end

--===============================================
-- OnEvent()
--===============================================
function ViewSetup_Setup_OnEvent(event)

	if ( event == "OPEN_OPTIMIZE" ) then
		this:Show();

	elseif (event == "ADJEST_UI_POS" ) then
		ViewSetup_Setup_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ViewSetup_Setup_Frame_On_ResetPos()
	end
end

--显示设置 nIndex 1速度优先 2均衡设置
function ViewSetup_Setup_ClickViewSetup(nIndex)

	PushEvent("CHANGE_VIEW_SETUP_QUALITY", nIndex)
	--更新操作
	SystemSetup:OptimizeConfirm()
	SystemSetup:Lua_ViewSetupToFile()
end

--关闭天空视角
function ViewSetup_Setup_CloseSkyEye()

	local str = "tksj";	
	SystemSetup:View_SetData(str, 0);
	SystemSetup:OptimizeConfirm()
	SystemSetup:Lua_ViewSetupToFile()
end

--分辨率 nIndex 1-1024*768 2-800*600
function ViewSetup_Setup_ScreenSize(nIndex)
	local str = "qpms"
	--全屏模式的话,要先改为非全屏
	local bFullScreen = tonumber(SystemSetup:View_GetData(str))

	if bFullScreen ~= 0 then
		SystemSetup:View_SetData(str, 0);
	end

	if nIndex == 1 then
		Variable:SetVariable("View_Resoution", "", 0);
		Variable:SetVariable("View_Resoution", "1024,768", 0);
	else
		Variable:SetVariable("View_Resoution", "", 0);
		Variable:SetVariable("View_Resoution", "800,600", 0);
	end

	SystemSetup:OptimizeConfirm()
	SystemSetup:Lua_ViewSetupToFile()
end

function ViewSetup_Setup_Frame_On_ResetPos()
	ViewSetup_Setup_Frame:SetProperty("UnifiedPosition", g_ViewSetup_Setup_Frame_UnifiedPosition);
end
