--DaHua_StoryLine1_LuoPan.lua

-- 界面的默认相对位置
local g_DaHua_StoryLine1_LuoPan_UnifiedXPosition;
local g_DaHua_StoryLine1_LuoPan_UnifiedYPosition;

local g_DaHua_StoryLine1_LuoPan_SelectedClueIndex=-1;	-- 当前线索位置
local g_DaHua_StoryLine1_LuoPan_SelectedClueID=-1;	-- 当前线索ID
local g_DaHua_StoryLine1_LuoPan_PosX=-1;
local g_DaHua_StoryLine1_LuoPan_PosZ=-1;
local g_DaHua_StoryLine1_LuoPan_MaxDist=5;
local g_DaHua_StoryLine1_LuoPan_isInArea=false;	-- 是否在目标区域
local g_DaHua_StoryLine1_LuoPan_Offsetx=0;
local g_DaHua_StoryLine1_LuoPan_Offsety=0;

function DaHua_StoryLine1_LuoPan_PreLoad()
	this:RegisterEvent("UI_COMMAND");

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)

	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
	--离开场景，自动关闭
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	
	this:RegisterEvent("UPDATE_MAP",false)
	this:RegisterEvent("SCENE_TRANSED",false)
end

function DaHua_StoryLine1_LuoPan_OnLoad()
	-- 保存界面的默认相对位置
	g_DaHua_StoryLine1_LuoPan_UnifiedXPosition	= DaHua_StoryLine1_LuoPan_Frame : GetProperty("UnifiedXPosition");
	g_DaHua_StoryLine1_LuoPan_UnifiedYPosition	= DaHua_StoryLine1_LuoPan_Frame : GetProperty("UnifiedYPosition");
	
	local nLuoPanX	= DaHua_StoryLine1_LuoPan_FrameButBk : GetProperty("AbsoluteXPosition");
	local nLuoPanY	= DaHua_StoryLine1_LuoPan_FrameButBk : GetProperty("AbsoluteYPosition");
	local pwidth, pheight = DaHua_StoryLine1_LuoPan_FrameButBk:GetWindowSize()	
	local swidth, sheight = DaHua_StoryLine1_LuoPan_Point:GetWindowSize()
	g_DaHua_StoryLine1_LuoPan_Offsetx = nLuoPanX + pwidth/2 - swidth/2 - 6
	g_DaHua_StoryLine1_LuoPan_Offsety = nLuoPanY + pheight/2 - sheight/2 - 12
		
	DaHua_StoryLine1_LuoPan_FrameBK_Arrival:Play(false)
	DaHua_StoryLine1_LuoPan_Distance:Hide()
end

function DaHua_StoryLine1_LuoPan_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 99912201 ) then
		
		local nFuncType = Get_XParam_INT(0);
		if nFuncType == 1 then
			
			local nClueIndex = Get_XParam_INT(1);
			local nClueId = Get_XParam_INT(2);
			local nPosX = Get_XParam_INT(3);
			local nPosZ = Get_XParam_INT(4);
			if nClueIndex == nil then
				nClueIndex = -1;
			end
			DaHua_StoryLine1_LuoPan_OnUpdateClue( nClueIndex, nClueId, nPosX, nPosZ )
					
			this:Show()
		elseif nFuncType == 2 then
			DaHua_StoryLine1_LuoPan_Close()
		end
						
	-- 游戏窗口尺寸发生了变化	
	elseif (event == "ADJEST_UI_POS" ) then
		DaHua_StoryLine1_LuoPan_On_ResetPos()

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		DaHua_StoryLine1_LuoPan_On_ResetPos()
	
	elseif( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
		
	elseif ( event == "SCENE_TRANSED") then 
		this:Hide()
	elseif ( event == "UPDATE_MAP") then 
		if( this:IsVisible() ) then
			DaHua_StoryLine1_LuoPan_Update()
		end
		
	end
end

function DaHua_StoryLine1_LuoPan_OnUpdateClue( nClueIndex, nClueId, nPosX, nPosZ )
	--local nClueId2, szClueName, szClueDesc, nClueQual, nClueFuncType, nClueValidType, nClueValidTime = GuiShiUI:LuaFnGetXianSuoDataFromTable( nClueId );
	
	g_DaHua_StoryLine1_LuoPan_SelectedClueIndex = nClueIndex;
	g_DaHua_StoryLine1_LuoPan_SelectedClueID = nClueId;
	g_DaHua_StoryLine1_LuoPan_PosX = nPosX;
	g_DaHua_StoryLine1_LuoPan_PosZ = nPosZ;
	
	g_DaHua_StoryLine1_LuoPan_isInArea = false;
	DaHua_StoryLine1_LuoPan_FrameBK_Arrival:Play(false)
end

function DaHua_StoryLine1_LuoPan_Update()
	if( this:IsVisible() ) then
------
	local selfX,selfZ = Player:GetPos();
		
	local cameraDir = GetCameraDir();
	local deltax = selfX - g_DaHua_StoryLine1_LuoPan_PosX
	local deltay = selfZ - g_DaHua_StoryLine1_LuoPan_PosZ
	if deltax == 0 then deltax = 1 end
	local offsetDir = math.atan(deltay/deltax);
	if deltax < 0 then 
		offsetDir = offsetDir + math.pi;
	end
	local distance = math.floor(math.sqrt(deltax*deltax+deltay*deltay));
	
	local radis = 50

	
------	
	
		--local distance = DaHua_StoryLine1_LuoPan_GetDistance()
		if distance >= g_DaHua_StoryLine1_LuoPan_MaxDist then
			local szDist = ScriptGlobal_Format("#{DHJDY_240521_66}", distance);
			DaHua_StoryLine1_LuoPan_Distance:SetText( szDist )
			DaHua_StoryLine1_LuoPan_Distance:Show()

			if true == g_DaHua_StoryLine1_LuoPan_isInArea then 
				g_DaHua_StoryLine1_LuoPan_isInArea = false
				DaHua_StoryLine1_LuoPan_FrameBK_Arrival:Play(false)
			end
			local szPosition = string.format("{{0,%s},{0,%s}}", g_DaHua_StoryLine1_LuoPan_Offsetx+radis*math.cos(offsetDir+cameraDir), 
			g_DaHua_StoryLine1_LuoPan_Offsety+radis*math.sin(offsetDir+cameraDir))			
			DaHua_StoryLine1_LuoPan_Point:SetProperty("UnifiedPosition", szPosition )
		else
			if false == g_DaHua_StoryLine1_LuoPan_isInArea then 
				g_DaHua_StoryLine1_LuoPan_isInArea = true
				
				DaHua_StoryLine1_LuoPan_Distance:SetText( "#{DHJDY_240521_67}" )
				DaHua_StoryLine1_LuoPan_FrameBK_Arrival:Play(true)
				DaHua_StoryLine1_LuoPan_Distance:Show()
			end
			local szPosition = string.format("{{0,%s},{0,%s}}", g_DaHua_StoryLine1_LuoPan_Offsetx, g_DaHua_StoryLine1_LuoPan_Offsety)				
			DaHua_StoryLine1_LuoPan_Point:SetProperty("UnifiedPosition", szPosition )
		end
		
	end
end

function DaHua_StoryLine1_LuoPan_GetDistance()
	local selfX,selfZ = Player:GetPos();
		
	local cameraDir = GetCameraDir();
	local deltax = selfX - g_DaHua_StoryLine1_LuoPan_PosX
	local deltay = selfZ - g_DaHua_StoryLine1_LuoPan_PosZ
	if deltax == 0 then deltax = 1 end
	local offsetDir = math.atan(deltay/deltax);
	if deltax < 0 then 
		offsetDir = offsetDir + math.pi;
	end
	local distance = math.floor(math.sqrt(deltax*deltax+deltay*deltay));
	
	local radis = 50
	local szPosition = string.format("{{0,%s},{0,%s}}", g_DaHua_StoryLine1_LuoPan_Offsetx+radis*math.cos(offsetDir+cameraDir), 
		g_DaHua_StoryLine1_LuoPan_Offsety+radis*math.sin(offsetDir+cameraDir))
	DaHua_StoryLine1_LuoPan_Point:SetProperty("UnifiedPosition", szPosition )
	return distance	
end

-- 挖掘
function DaHua_StoryLine1_LuoPan_OnChuTu()

	-- 1.30级
	-- if Player:GetLevel() < 30 then
		-- PushDebugMessage("#{GSCX_190727_10}")
		-- return
	-- end
		
	-- -- 2.选择线索
	-- if g_DaHua_StoryLine1_LuoPan_SelectedClueID <= 0 then
		-- PushDebugMessage("#{GSCX_190727_12}")
		-- return
	-- end
	
	-- -- 3.坐标
	-- if DaHua_StoryLine1_LuoPan_GetDistance() > g_DaHua_StoryLine1_LuoPan_MaxDist then
		-- local szText = ScriptGlobal_Format( "#{GSCX_190727_11}", g_DaHua_StoryLine1_LuoPan_PosX, g_DaHua_StoryLine1_LuoPan_PosZ )
		-- PushDebugMessage( szText )
		-- return
	-- end

	-- Clear_XSCRIPT()
		-- Set_XSCRIPT_Function_Name( "OnClientChuTu" )
		-- Set_XSCRIPT_ScriptID( 402083 )
		-- Set_XSCRIPT_Parameter( 0, g_DaHua_StoryLine1_LuoPan_SelectedClueIndex )   --线索位置
		-- Set_XSCRIPT_Parameter( 1, g_DaHua_StoryLine1_LuoPan_SelectedClueID )   --线索
		-- Set_XSCRIPT_Parameter( 2, 0 )				 --确认：0不确认，1已二次确认
		-- Set_XSCRIPT_ParamCount(3)
	-- Send_XSCRIPT()
end

function DaHua_StoryLine1_LuoPan_OnHiden()
end

--================================================
-- 关闭界面
--================================================
function DaHua_StoryLine1_LuoPan_Close()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function DaHua_StoryLine1_LuoPan_On_ResetPos()

	DaHua_StoryLine1_LuoPan_Frame : SetProperty("UnifiedXPosition", g_DaHua_StoryLine1_LuoPan_UnifiedXPosition);
	DaHua_StoryLine1_LuoPan_Frame : SetProperty("UnifiedYPosition", g_DaHua_StoryLine1_LuoPan_UnifiedYPosition);

end

