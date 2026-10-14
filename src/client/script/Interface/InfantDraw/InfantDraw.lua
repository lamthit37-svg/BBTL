local g_Frame_UnifiedXPosition;
local g_Frame_UnifiedYPosition;

local g_bagId = -1;
local g_curImage = 0;
local g_level = -1
local g_posnum = -1

function InfantDraw_PreLoad()
	this:RegisterEvent("UI_COMMAND");
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function InfantDraw_OnEvent(event)
	if event == "UI_COMMAND"  and tonumber(arg0) == 890517 then
		g_level = Get_XParam_INT(0)
		g_posnum = Get_XParam_INT(1)
		InfantDraw_OnShown()
	elseif( event == "ADJEST_UI_POS" ) then
		InfantDraw_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		InfantDraw_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
	end
end
function InfantDraw_OnLoad()
	-- 保存界面的默认相对位置
	g_Frame_UnifiedXPosition	= InfantDraw_Frame:GetProperty("UnifiedXPosition");
	g_Frame_UnifiedYPosition	= InfantDraw_Frame:GetProperty("UnifiedYPosition");
		
end

function InfantDraw_OnShown()
	-- if g_bagId >=0 then
	-- 	LifeAbility : Lock_Packet_Item(g_bagId,0);
	-- end
	--10s自动关闭
	SetTimer("InfantDraw", "InfantDraw_OnHiden()", 10000)
	-- g_bagId = Get_XParam_INT(0);
	-- LifeAbility : Lock_Packet_Item(g_bagId,1);
	g_curImage = 0;
	if g_level == 1 then
		if g_posnum == 1 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_01 image:InfantImage_01_01")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_266}")
		elseif g_posnum == 2 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_01 image:InfantImage_01_02")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_266}")
		elseif g_posnum == 3 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_02 image:InfantImage_02_01")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_266}")
		elseif g_posnum == 4 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_02 image:InfantImage_02_02")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_267}")
		elseif g_posnum == 5 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_03 image:InfantImage_03_01")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_267}")
		elseif g_posnum == 6 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_03 image:InfantImage_03_02")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_267}")
		end
	elseif g_level == 2 then
		if g_posnum == 1 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_04 image:InfantImage_04_01")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_265}")
		elseif g_posnum == 2 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_04 image:InfantImage_04_02")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_265}")
		elseif g_posnum == 3 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_05 image:InfantImage_05_01")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_265}")
		elseif g_posnum == 4 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_05 image:InfantImage_05_02")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_268}")
		elseif g_posnum == 5 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_06 image:InfantImage_06_01")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_268}")
		elseif g_posnum == 6 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_06 image:InfantImage_06_02")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_268}")
		end	
	elseif g_level == 3 then
		if g_posnum == 1 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_07 image:InfantImage_07_01")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_270}")
		elseif g_posnum == 2 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_07 image:InfantImage_07_02")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_270}")
		elseif g_posnum == 3 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_08 image:InfantImage_08_01")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_270}")
		elseif g_posnum == 4 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_08 image:InfantImage_08_02")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_269}")
		elseif g_posnum == 5 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_09 image:InfantImage_09_01")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_269}")
		elseif g_posnum == 6 then
			InfantDraw_Image:SetProperty("Image", "set:InfantImage_09 image:InfantImage_09_02")
			InfantDraw_DragTitle:SetText("#{SXPY_130826_269}")
		end	
	end
	--InfantDraw_Image:SetProperty("Image", "set:InfantImage_01_01 image:InfantImage_01_01")
	--InfantDraw_DragTitle:SetText("#{ZXRW_230530_352}")
	this:Show();
end

--================================================
-- 界面的默认相对位置
--================================================
function InfantDraw_ResetPos()
	InfantDraw_Frame:SetProperty("UnifiedXPosition", g_Frame_UnifiedXPosition);
	InfantDraw_Frame:SetProperty("UnifiedYPosition", g_Frame_UnifiedYPosition);
end

function InfantDraw_OnHiden()
	-- LifeAbility : Lock_Packet_Item(g_bagId,0)
	KillTimer("InfantDraw_OnHiden()")
	PushDebugMessage("#{SXPY_130826_92}")
	this:Hide();
end