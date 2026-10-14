local g_Soujijunxu_Treasure_UnifiedPosition;
local g_Soujijunxu_Treasure_IsInLimitDis;
local g_Soujijunxu_Treasure_NowDistance;
local g_Soujijunxu_Treasure_TargetPosx;
local g_Soujijunxu_Treasure_TargetPosy;
local g_Soujijunxu_Treasure_Offsetx;
local g_Soujijunxu_Treasure_Offsety;

function Soujijunxu_Treasure_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UPDATE_MAP",false)
	this:RegisterEvent("SCENE_TRANSED",false)
end

function Soujijunxu_Treasure_OnLoad()
	g_Soujijunxu_Treasure_UnifiedPosition = Soujijunxu_Treasure_Frame:GetProperty("UnifiedPosition")
	local pwidth, pheight = Soujijunxu_Treasure_Client:GetWindowSize()
	local swidth, sheight = Soujijunxu_Treasure_Point:GetWindowSize()
	g_Soujijunxu_Treasure_Offsetx = pwidth/2 - swidth/2
	g_Soujijunxu_Treasure_Offsety = pheight/2 - sheight/2
	Soujijunxu_Treasure_FrameBK_Arrival:Play(false)
	-- Soujijunxu_Treasure_Point:Hide()
end

function Soujijunxu_Treasure_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		Soujijunxu_Treasure_Frame:SetProperty("UnifiedPosition", g_Soujijunxu_Treasure_UnifiedPosition)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99823601 ) then
		this:Show()
		g_Soujijunxu_Treasure_IsInLimitDis = false;
		Soujijunxu_Treasure_FrameBK_Arrival:Play(false)
		Soujijunxu_Treasure_Point:Play(true)
		local targetIndex = Get_XParam_INT( 0 );
		g_Soujijunxu_Treasure_TargetPosx = Get_XParam_INT( 1 );
		g_Soujijunxu_Treasure_TargetPosy = Get_XParam_INT( 2 );
		-- Soujijunxu_Treasure_CalInfo:SetTargetPos(targetPosx, targetPosy)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99823602 ) then
		local nVisible = 1;
		if not this:IsVisible() then nVisible = 0 end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnCheckUIOpen" );
			Set_XSCRIPT_ScriptID( 998236 );
			Set_XSCRIPT_Parameter( 0, nVisible );
			Set_XSCRIPT_ParamCount( 1 );
		Send_XSCRIPT()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 99823603 ) then
		this:Hide()
	elseif ( event == "SCENE_TRANSED") then
		this:Hide()
	elseif ( event == "UPDATE_MAP") then
		Soujijunxu_Treasure_Update()
	end
end

function Soujijunxu_Treasure_OnHiden()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnUIClose" );
		Set_XSCRIPT_ScriptID( 998236 );
		Set_XSCRIPT_ParamCount( 0 );
	Send_XSCRIPT()
end
function Soujijunxu_Treasure_GetDistance()
	local myPosx, myPosz, _ = Target:GetMyPos()
	local cameraDir = GetCameraDir();
	local deltax = myPosx - g_Soujijunxu_Treasure_TargetPosx
	local deltay = myPosz - g_Soujijunxu_Treasure_TargetPosy
	if deltax == 0 then deltax = 1 end
	local offsetDir = math.atan(deltay/deltax);
	if deltax < 0 then
		offsetDir = offsetDir + math.pi;
	end
	local distance = math.floor(math.sqrt(deltax*deltax+deltay*deltay));
	local radis = g_Soujijunxu_Treasure_Offsety - 2
	Soujijunxu_Treasure_Point:SetProperty("UnifiedPosition", string.format("{{0,%s},{0,%s}}", g_Soujijunxu_Treasure_Offsetx-2+radis*math.cos(offsetDir+cameraDir), g_Soujijunxu_Treasure_Offsety-4+radis*math.sin(offsetDir+cameraDir)))
	return distance
end

function Soujijunxu_Treasure_Update()
	if( this:IsVisible() ) then
		g_Soujijunxu_Treasure_NowDistance = Soujijunxu_Treasure_GetDistance()
		if g_Soujijunxu_Treasure_NowDistance >= 5 then
			Soujijunxu_Treasure_Distance:SetText(ScriptGlobal_Format("#{SJJX_220811_26}", g_Soujijunxu_Treasure_NowDistance))
			if true == g_Soujijunxu_Treasure_IsInLimitDis then
				g_Soujijunxu_Treasure_IsInLimitDis = false
				Soujijunxu_Treasure_FrameBK_Arrival:Play(false)
				Soujijunxu_Treasure_Point:Play(true)
			--	PushEvent( "OPEN_HUODONGTEXT_HELP", 2, "")
			end
		else
			if false == g_Soujijunxu_Treasure_IsInLimitDis then
				g_Soujijunxu_Treasure_IsInLimitDis = true
				Soujijunxu_Treasure_Distance:SetText("#{SJJX_220811_27}")
				Soujijunxu_Treasure_FrameBK_Arrival:Play(true)
				Soujijunxu_Treasure_Point:Play(false)
			--	PushEvent( "OPEN_HUODONGTEXT_HELP", 2, "#{QMXB_19026_41}")
			end
		end
	end
end
