-- 界面的默认相对位置
local g_DaHua_Tips_Frame_UnifiedXPosition;
local g_DaHua_Tips_Frame_UnifiedYPosition;
local g_UICOMMAND = 05112802

local g_Timer = 0

function DaHua_Tips_PreLoad()
	this:RegisterEvent("UI_COMMAND");

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	
	this:RegisterEvent("SCENE_TRANSED",false)
end

function DaHua_Tips_OnLoad()
	-- 保存界面的默认相对位置
	g_DaHua_Tips_Frame_UnifiedXPosition	= DaHua_Tips_Frame : GetProperty("UnifiedXPosition");
	g_DaHua_Tips_Frame_UnifiedYPosition	= DaHua_Tips_Frame : GetProperty("UnifiedYPosition");
end

function DaHua_Tips_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND ) then	
		
		local msg = Get_XParam_STR(0)
		local showtime = Get_XParam_INT(0)
		if g_Timer > 0 then
			KillTimer("DaHua_Tips_Timer()")
		end
		DaHua_Tips_Updata(msg, showtime)
		this:Show()
		
	
	-- 游戏窗口尺寸发生了变化	
	elseif (event == "ADJEST_UI_POS" ) then
		DaHua_Tips_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DaHua_Tips_On_ResetPos()
	
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		
	elseif ( event == "SCENE_TRANSED") then 
		this:Hide()
			
	end
end

--================================================
-- 关闭界面
--================================================
function DaHua_Tips_Close()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function DaHua_Tips_On_ResetPos()

	DaHua_Tips_Frame : SetProperty("UnifiedXPosition", g_DaHua_Tips_Frame_UnifiedXPosition);
	DaHua_Tips_Frame : SetProperty("UnifiedYPosition", g_DaHua_Tips_Frame_UnifiedYPosition);

end

function DaHua_Tips_Updata(msg, showtime)
	g_Timer = showtime
	SetTimer("DaHua_Tips","DaHua_Tips_Timer()", 1*1000)
	DaHua_Tips_Text:SetText(msg)
end

function DaHua_Tips_OnHiden()
	this:Hide()
end

function DaHua_Tips_Timer()
	g_Timer = g_Timer - 1 
	if g_Timer == 0 then
		KillTimer("DaHua_Tips_Timer()")
		this:Hide()
	end
end
