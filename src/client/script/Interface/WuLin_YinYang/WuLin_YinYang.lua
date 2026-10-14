-- 界面的默认相对位置
local g_WuLin_YinYang_Frame_UnifiedXPosition;
local g_WuLin_YinYang_Frame_UnifiedYPosition;

local g_WuLin_YinYang_Offsetx=0;
local g_WuLin_YinYang_Offsety=0;
local g_WuLin_YinYang_Long = 0
local g_WuLin_YinYang_Time = 0;
function WuLin_YinYang_PreLoad()
	this:RegisterEvent("UI_COMMAND");

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	
	this:RegisterEvent("SCENE_TRANSED",false)
end

function WuLin_YinYang_OnLoad()
	-- 保存界面的默认相对位置
	g_WuLin_YinYang_Frame_UnifiedXPosition	= WuLin_YinYang_Frame : GetProperty("UnifiedXPosition");
	g_WuLin_YinYang_Frame_UnifiedYPosition	= WuLin_YinYang_Frame : GetProperty("UnifiedYPosition");
	
	--local nLuoPanX	= WuLin_YinYang_BK : GetProperty("UnifiedXPosition");
	--local nLuoPanY	= WuLin_YinYang_BK : GetProperty("UnifiedYPosition");
	local pwidth, pheight = WuLin_YinYang_BK:GetWindowSize()
	local swidth, sheight = WuLin_YinYang_Point:GetWindowSize()
	g_WuLin_YinYang_Offsetx = pwidth/2 - swidth/2 
	g_WuLin_YinYang_Offsety = pheight/2 - sheight/2
	g_WuLin_YinYang_Long = 61
	g_WuLin_YinYang_Time = 0
	WuLin_YinYang_FrameBk1:Hide()
	WuLin_YinYang_FrameBk2:Hide()
	WuLin_YinYang_FrameBk3:Hide()
	WuLin_YinYang_FrameBk4:Hide()
	WuLin_YinYang_FrameBk5:Hide()
end

function WuLin_YinYang_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88800801 ) and Get_XParam_INT(0) == 1 then	
		g_WuLin_YinYang_Time = 5
		WuLin_YinYang_SetPoint(0)
		this:Show()
		
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88800802 ) then
		if Get_XParam_INT(0) == 1 then
			g_WuLin_YinYang_Time = 5 - math.floor(tonumber(Get_XParam_INT(2)/60))
			WuLin_YinYang_SetPoint(Get_XParam_INT(1))
			this:Show()
		end
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88800801 ) and Get_XParam_INT(0) == 0 then		
		this:Hide()
	
	-- 游戏窗口尺寸发生了变化	
	elseif (event == "ADJEST_UI_POS" ) then
		WuLin_YinYang_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_YinYang_On_ResetPos()
	
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		
	elseif ( event == "SCENE_TRANSED") then 
		this:Hide()
			
	end
end

--================================================
-- 关闭界面
--================================================
function WuLin_YinYang_Close()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function WuLin_YinYang_On_ResetPos()

	WuLin_YinYang_Frame : SetProperty("UnifiedXPosition", g_WuLin_YinYang_Frame_UnifiedXPosition);
	WuLin_YinYang_Frame : SetProperty("UnifiedYPosition", g_WuLin_YinYang_Frame_UnifiedYPosition);

end

function WuLin_YinYang_SetPoint(nYYZ)
	--PushDebugMessage(g_WuLin_YinYang_Offsetx)
	--PushDebugMessage(g_WuLin_YinYang_Offsety)
	local nABS_YYZ = math.abs(nYYZ)

	if g_WuLin_YinYang_Time >= 5 then
		WuLin_YinYang_FrameBk5:Show()
		WuLin_YinYang_FrameBk1:Hide()
		WuLin_YinYang_FrameBk2:Hide()
		WuLin_YinYang_FrameBk3:Hide()
		WuLin_YinYang_FrameBk4:Hide()
	elseif g_WuLin_YinYang_Time >= 4 then
		WuLin_YinYang_FrameBk4:Show()
		WuLin_YinYang_FrameBk1:Hide()
		WuLin_YinYang_FrameBk2:Hide()
		WuLin_YinYang_FrameBk3:Hide()
		--WuLin_YinYang_FrameBk4:Hide()
		WuLin_YinYang_FrameBk5:Hide()
	elseif g_WuLin_YinYang_Time >= 3 then
		WuLin_YinYang_FrameBk3:Show()
		WuLin_YinYang_FrameBk1:Hide()
		WuLin_YinYang_FrameBk2:Hide()
		--WuLin_YinYang_FrameBk3:Hide()
		WuLin_YinYang_FrameBk4:Hide()
		WuLin_YinYang_FrameBk5:Hide()
	elseif g_WuLin_YinYang_Time >= 2 then
		WuLin_YinYang_FrameBk2:Show()
		WuLin_YinYang_FrameBk1:Hide()
		--WuLin_YinYang_FrameBk2:Hide()
		WuLin_YinYang_FrameBk3:Hide()
		WuLin_YinYang_FrameBk4:Hide()
		WuLin_YinYang_FrameBk5:Hide()
	elseif g_WuLin_YinYang_Time >= 1 then
		WuLin_YinYang_FrameBk1:Show()
		--WuLin_YinYang_FrameBk1:Hide()
		WuLin_YinYang_FrameBk2:Hide()
		WuLin_YinYang_FrameBk3:Hide()
		WuLin_YinYang_FrameBk4:Hide()
		WuLin_YinYang_FrameBk5:Hide()
	end
	local swidth, sheight = WuLin_YinYang_Point:GetWindowSize()
	local nNewPosX = 0
	local nNewPosY = 0
	if nYYZ < 0 then
		nNewPosX = g_WuLin_YinYang_Offsetx - g_WuLin_YinYang_Long*math.sin(nABS_YYZ*math.pi/200) 
		nNewPosY = g_WuLin_YinYang_Offsety - g_WuLin_YinYang_Long*math.cos(nABS_YYZ*math.pi/200) 
	elseif nYYZ >= 0 then
		nNewPosX = g_WuLin_YinYang_Offsetx + g_WuLin_YinYang_Long*math.sin(nABS_YYZ*math.pi/200) 
		nNewPosY = g_WuLin_YinYang_Offsety - g_WuLin_YinYang_Long*math.cos(nABS_YYZ*math.pi/200) 
	end
	local szPosition = string.format("{{0,%s},{0,%s}}", nNewPosX, nNewPosY)
	WuLin_YinYang_Point:SetProperty("UnifiedPosition", szPosition )
	-- local szPosition = string.format("x:%s y:%s", nNewPosX, nNewPosY)
	-- WuLin_YinYang_Point:SetProperty("AbsolutePosition", szPosition)
end

function WuLin_YinYang_OnHiden()
	
end
