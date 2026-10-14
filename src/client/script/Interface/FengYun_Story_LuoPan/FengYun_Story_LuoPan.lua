--FengYun_Story_LuoPan.lua
local g_FengYun_Story_LuoPan_UnifiedXPosition;
local g_FengYun_Story_LuoPan_UnifiedYPosition;
local g_FengYun_Story_LuoPan_PosX = -1;
local g_FengYun_Story_LuoPan_PosZ = -1;
local g_FengYun_Story_LuoPan_MaxDist = 5;
local g_FengYun_Story_LuoPan_isInArea = false; -- 是否在目标区域
local g_FengYun_Story_LuoPan_Offsetx = 0;
local g_FengYun_Story_LuoPan_Offsety = 0;

function FengYun_Story_LuoPan_PreLoad()
	--第二个参数表示界面隐藏时是否响应事件 默认为true
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false);
	this:RegisterEvent("UPDATE_MAP", false)
	this:RegisterEvent("SCENE_TRANSED", false)
end

function FengYun_Story_LuoPan_OnLoad()
	-- 保存界面的默认相对位置
	g_FengYun_Story_LuoPan_UnifiedXPosition = FengYun_Story_LuoPan_Frame:GetProperty("UnifiedXPosition");
	g_FengYun_Story_LuoPan_UnifiedYPosition = FengYun_Story_LuoPan_Frame:GetProperty("UnifiedYPosition");
	local nLuoPanX = FengYun_Story_LuoPan_FrameButBk:GetProperty("AbsoluteXPosition");
	local nLuoPanY = FengYun_Story_LuoPan_FrameButBk:GetProperty("AbsoluteYPosition");
	local pwidth, pheight = FengYun_Story_LuoPan_FrameButBk:GetWindowSize()
	local swidth, sheight = FengYun_Story_LuoPan_Point:GetWindowSize()
	g_FengYun_Story_LuoPan_Offsetx = nLuoPanX + pwidth / 2 - swidth / 2 - 6
	g_FengYun_Story_LuoPan_Offsety = nLuoPanY + pheight / 2 - sheight / 2 - 12
	FengYun_Story_LuoPan_FrameBK_Arrival:Play(false)
	FengYun_Story_LuoPan_Distance:Hide()
end

function FengYun_Story_LuoPan_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 30015202) then
		local nFuncType = Get_XParam_INT(0);
		if nFuncType == 3 then
			local nPosX = Get_XParam_INT(1);
			local nPosZ = Get_XParam_INT(2);
			FengYun_Story_LuoPan_OnUpdateClue(nPosX, nPosZ)
			this:Show()
		elseif nFuncType == 4 then
			-- 执行脚本
			local nVisible = 1;
			if not this:IsVisible() then nVisible = 0 end
			Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("SetFindPeopleUIisShow")
			Set_XSCRIPT_ScriptID(300152)
			Set_XSCRIPT_Parameter(0, nVisible)
			Set_XSCRIPT_ParamCount(1)
			Send_XSCRIPT()
		elseif nFuncType == 5 then
			FengYun_Story_LuoPan_Close()
		end
	elseif (event == "ADJEST_UI_POS") then
		FengYun_Story_LuoPan_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FengYun_Story_LuoPan_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide();
	elseif (event == "SCENE_TRANSED") then
		this:Hide()
	elseif (event == "UPDATE_MAP") then
		if (this:IsVisible()) then
			FengYun_Story_LuoPan_Update()
		end
	end
end

function FengYun_Story_LuoPan_OnUpdateClue(nPosX, nPosZ)
	g_FengYun_Story_LuoPan_PosX = nPosX;
	g_FengYun_Story_LuoPan_PosZ = nPosZ;
	g_FengYun_Story_LuoPan_isInArea = false;
	FengYun_Story_LuoPan_FrameBK_Arrival:Play(false)
end

function FengYun_Story_LuoPan_Update()
	if (this:IsVisible()) then
		local selfX, selfZ = Player:GetPos();
		local cameraDir = GetCameraDir();
		local deltax = selfX - g_FengYun_Story_LuoPan_PosX
		local deltay = selfZ - g_FengYun_Story_LuoPan_PosZ
		if deltax == 0 then deltax = 1 end
		local offsetDir = math.atan(deltay / deltax);
		if deltax < 0 then
			offsetDir = offsetDir + math.pi;
		end
		local distance = math.floor(math.sqrt(deltax * deltax + deltay * deltay));
		local radis = 50
		if distance >= g_FengYun_Story_LuoPan_MaxDist then
			local szDist = ScriptGlobal_Format("#{FYWS_260107_49}", distance); --XX米
			FengYun_Story_LuoPan_Distance:SetText(szDist)
			FengYun_Story_LuoPan_Distance:Show()
			if true == g_FengYun_Story_LuoPan_isInArea then
				g_FengYun_Story_LuoPan_isInArea = false
				FengYun_Story_LuoPan_FrameBK_Arrival:Play(false)
				--关闭对话框
				PushEvent("UI_COMMAND", 1000)
			end
			local szPosition = string.format("{{0,%s},{0,%s}}", g_FengYun_Story_LuoPan_Offsetx +
				radis * math.cos(offsetDir + cameraDir),
				g_FengYun_Story_LuoPan_Offsety + radis * math.sin(offsetDir + cameraDir))
			FengYun_Story_LuoPan_Point:SetProperty("UnifiedPosition", szPosition)
		else
			if false == g_FengYun_Story_LuoPan_isInArea then
				g_FengYun_Story_LuoPan_isInArea = true

				FengYun_Story_LuoPan_Distance:SetText("#{FYWS_260107_50}") --已到达
				FengYun_Story_LuoPan_FrameBK_Arrival:Play(true)
				FengYun_Story_LuoPan_Distance:Show()
				--显示对话框
				PushEvent("QUEST_HELP_MSG", "#{FYWS_260107_48}")
			end
			local szPosition = string.format("{{0,%s},{0,%s}}", g_FengYun_Story_LuoPan_Offsetx, g_FengYun_Story_LuoPan_Offsety)
			FengYun_Story_LuoPan_Point:SetProperty("UnifiedPosition", szPosition)
		end
	end
end

function FengYun_Story_LuoPan_GetDistance()
	local selfX, selfZ = Player:GetPos();
	local cameraDir = GetCameraDir();
	local deltax = selfX - g_FengYun_Story_LuoPan_PosX
	local deltay = selfZ - g_FengYun_Story_LuoPan_PosZ
	if deltax == 0 then deltax = 1 end
	local offsetDir = math.atan(deltay / deltax);
	if deltax < 0 then
		offsetDir = offsetDir + math.pi;
	end
	local distance = math.floor(math.sqrt(deltax * deltax + deltay * deltay));

	local radis = 50
	local szPosition = string.format("{{0,%s},{0,%s}}", g_FengYun_Story_LuoPan_Offsetx + radis *
		math.cos(offsetDir + cameraDir),
		g_FengYun_Story_LuoPan_Offsety + radis * math.sin(offsetDir + cameraDir))
	FengYun_Story_LuoPan_Point:SetProperty("UnifiedPosition", szPosition)
	return distance
end

function FengYun_Story_LuoPan_OnHiden()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("SetFindPeopleUIisShow")
	Set_XSCRIPT_ScriptID(300152)
	Set_XSCRIPT_Parameter(0, 0)
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function FengYun_Story_LuoPan_Close()
	this:Hide()
end

function FengYun_Story_LuoPan_On_ResetPos()
	FengYun_Story_LuoPan_Frame:SetProperty("UnifiedXPosition", g_FengYun_Story_LuoPan_UnifiedXPosition);
	FengYun_Story_LuoPan_Frame:SetProperty("UnifiedYPosition", g_FengYun_Story_LuoPan_UnifiedYPosition);
end
