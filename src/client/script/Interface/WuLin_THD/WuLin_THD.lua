-- 界面的默认相对位置
local g_WuLin_THD_Frame_UnifiedXPosition;
local g_WuLin_THD_Frame_UnifiedYPosition;

local g_WuLin_THD_Offsetx=0;
local g_WuLin_THD_Offsety=0;
local g_WuLin_THD_Long = 0
function WuLin_THD_PreLoad()
	this:RegisterEvent("UI_COMMAND");

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	
	this:RegisterEvent("SCENE_TRANSED",false)
end

function WuLin_THD_OnLoad()
	-- 保存界面的默认相对位置
	g_WuLin_THD_Frame_UnifiedXPosition	= WuLin_THD_Frame : GetProperty("UnifiedXPosition");
	g_WuLin_THD_Frame_UnifiedYPosition	= WuLin_THD_Frame : GetProperty("UnifiedYPosition");
	
	--local nLuoPanX	= WuLin_THD_BK : GetProperty("UnifiedXPosition");
	--local nLuoPanY	= WuLin_THD_BK : GetProperty("UnifiedYPosition");
	local pwidth, pheight = WuLin_THD_BK:GetWindowSize()
	local swidth, sheight = WuLin_THD_Point:GetWindowSize()
	g_WuLin_THD_Offsetx = pwidth/2 - swidth/2
	g_WuLin_THD_Offsety = pheight - sheight/2
	g_WuLin_THD_Long = sheight/2 + 50
	WuLin_THD_Animate:Hide()
	WuLin_THD_Animate2:Hide()

end

function WuLin_THD_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 88800401 ) and Get_XParam_INT(0) == 1 then	
		
		WuLin_THD_SetPoint(Get_XParam_INT(1),Get_XParam_INT(2),Get_XParam_INT(3),Get_XParam_INT(4))
		this:Show()

	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 88800401 ) and Get_XParam_INT(0) == 0 then		
		this:Hide()
	
	-- 游戏窗口尺寸发生了变化	
	elseif (event == "ADJEST_UI_POS" ) then
		WuLin_THD_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		WuLin_THD_On_ResetPos()
	
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		
	elseif ( event == "SCENE_TRANSED") then 
		this:Hide()
			
	end
end

--================================================
-- 关闭界面
--================================================
function WuLin_THD_Close()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function WuLin_THD_On_ResetPos()

	WuLin_THD_Frame : SetProperty("UnifiedXPosition", g_WuLin_THD_Frame_UnifiedXPosition);
	WuLin_THD_Frame : SetProperty("UnifiedYPosition", g_WuLin_THD_Frame_UnifiedYPosition);

end

function WuLin_THD_SetPoint(nHP, dis, nSelfCount,nLiRenOuCount)
	--PushDebugMessage(g_WuLin_THD_Offsetx)
	--PushDebugMessage(g_WuLin_THD_Offsety)
	local nABS_YYZ = math.abs(nHP)
	local nNewPosX = 0
	local nNewPosY = 0
	if nHP < 0 then
		nNewPosX = g_WuLin_THD_Offsetx - g_WuLin_THD_Long*math.sin(nABS_YYZ*math.pi/200)
		nNewPosY = g_WuLin_THD_Offsety - g_WuLin_THD_Long*math.cos(nABS_YYZ*math.pi/200)
	elseif nHP >= 0 then
		nNewPosX = g_WuLin_THD_Offsetx + g_WuLin_THD_Long*math.sin(nABS_YYZ*math.pi/200)
		nNewPosY = g_WuLin_THD_Offsety - g_WuLin_THD_Long*math.cos(nABS_YYZ*math.pi/200)
	end
	local szPosition = string.format("{{0,%s},{0,%s}}", nNewPosX, nNewPosY)
	WuLin_THD_Point:SetProperty("UnifiedPosition", szPosition )
	if dis < 15 and 10 <= dis then
		--WuLin_THD_Animate:replayEffect("UI_zaojia_A")
		WuLin_THD_Animate2:Show()
		WuLin_THD_Animate2:Play(true)
		WuLin_THD_Animate:Hide()
		WuLin_THD_Animate:Play(false)
	else 
		--WuLin_THD_Animate2:replayEffect("UI_zaojia_B")
		WuLin_THD_Animate:Show()
		WuLin_THD_Animate:Play(true)
		WuLin_THD_Animate2:Hide()
		WuLin_THD_Animate2:Play(false)
	end
	WuLin_THD_Text:SetText(ScriptGlobal_Format("#{BSJN_200327_185}",dis))
	WuLin_THD_Text:Show()
	if nSelfCount == 0 or nLiRenOuCount == 0 then
		WuLin_THD_Animate:Hide()
		WuLin_THD_Animate2:Hide()
		WuLin_THD_Animate:Play(false)
		WuLin_THD_Animate2:Play(false)
		WuLin_THD_Text:Hide()
	end
	WuLin_THD_LiftProgress:SetProgress(nSelfCount,100)
	WuLin_THD_RightProgress:SetProgress(nLiRenOuCount,100)
	WuLin_THD_LeftText:SetText(nSelfCount.."%")
	WuLin_THD_RightText:SetText(nLiRenOuCount.."%")
    local szPosition = string.format("x:%s y:%s", nNewPosX, nNewPosY)
	WuLin_THD_Point:SetProperty("AbsolutePosition", szPosition)
end

function WuLin_THD_OnHiden()
	
end
