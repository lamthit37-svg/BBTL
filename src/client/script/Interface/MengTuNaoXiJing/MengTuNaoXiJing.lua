
local g_MengTuNaoXiJing_UnifiedPosition
local g_MengTuNaoXiJing_Offsetx
local g_MengTuNaoXiJing_Offsety
local g_MengTuNaoXiJing_TargetPosx
local g_MengTuNaoXiJing_TargetPosy
local g_MengTuNaoXiJing_NowDistance
local g_MengTuNaoXiJing_MonsterObjId

function MengTuNaoXiJing_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UPDATE_MAP",false)
	this:RegisterEvent("SCENE_TRANSED",false)
end

function MengTuNaoXiJing_OnLoad()
	g_MengTuNaoXiJing_UnifiedPosition = MengTuNaoXiJing_LuoPan_Frame:GetProperty("UnifiedPosition")
	local pwidth, pheight = MengTuNaoXiJing_LuoPan_Client:GetWindowSize()
	local swidth, sheight = MengTuNaoXiJing_Point_Ani:GetWindowSize()
	g_MengTuNaoXiJing_Offsetx = pwidth/2 - swidth/2
	g_MengTuNaoXiJing_Offsety = pheight/2 - sheight/2
	MengTuNaoXiJing_LuoPan_Ani:Play(false)
end

function MengTuNaoXiJing_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		MengTuNaoXiJing_LuoPan_Frame:SetProperty("UnifiedPosition", g_MengTuNaoXiJing_UnifiedPosition)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2022120601 ) then
		this:Show()
		MengTuNaoXiJing_LuoPan_Ani:Play(false)
		MengTuNaoXiJing_Point_Ani:Play(true)
		g_MengTuNaoXiJing_TargetPosx = Get_XParam_INT( 0 )
		g_MengTuNaoXiJing_TargetPosy = Get_XParam_INT( 1 )
		g_MengTuNaoXiJing_MonsterObjId = Get_XParam_INT( 2 )
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 2022120602 ) then
		this:Hide()
	elseif ( event == "SCENE_TRANSED") then
		this:Hide()
	elseif ( event == "UPDATE_MAP") then
		MengTuNaoXiJing_Update()
	end
end

function MengTuNaoXiJing_GetDistance()
	local myPosx, myPosz, _ = Target:GetMyPos()
	-- local myPosx, myPosz = Target:GetMonsterPos(g_MengTuNaoXiJing_MonsterObjId)
	local cameraDir = GetCameraDir()
	-- PushDebugMessage("g_MengTuNaoXiJing_MonsterObjId ="..g_MengTuNaoXiJing_MonsterObjId)
	-- PushDebugMessage("myPosx ="..myPosx)
	-- PushDebugMessage("myPosz ="..myPosz)
	local deltax = myPosx - g_MengTuNaoXiJing_TargetPosx
	local deltay = myPosz - g_MengTuNaoXiJing_TargetPosy
	if deltax == 0 then deltax = 1 end
	local offsetDir = math.atan(deltay/deltax);
	if deltax < 0 then
		offsetDir = offsetDir + math.pi;
	end
	local distance = math.floor(math.sqrt(deltax*deltax+deltay*deltay));
	local radis = g_MengTuNaoXiJing_Offsety - 2
	MengTuNaoXiJing_Point_Ani:SetProperty("UnifiedPosition", string.format("{{0,%s},{0,%s}}", g_MengTuNaoXiJing_Offsetx-2+radis*math.cos(offsetDir+cameraDir), g_MengTuNaoXiJing_Offsety-4+radis*math.sin(offsetDir+cameraDir)))
	return distance
end

function MengTuNaoXiJing_Update()
	if( this:IsVisible() ) then
		g_MengTuNaoXiJing_NowDistance = MengTuNaoXiJing_GetDistance()
		MengTuNaoXiJing_Text:SetText(ScriptGlobal_Format("#{YTZ_20221107_136}", g_MengTuNaoXiJing_NowDistance))

	end

end

function MengTuNaoXiJing_LuoPan_OnHiden()
	
end

