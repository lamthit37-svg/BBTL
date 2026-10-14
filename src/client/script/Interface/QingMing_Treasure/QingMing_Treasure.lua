local g_QingMing_Treasure_UnifiedPosition;
local g_QingMing_Treasure_IsInLimitDis;
local g_QingMing_Treasure_NowDistance;
local g_QingMing_Treasure_TargetPosx;
local g_QingMing_Treasure_TargetPosy;
local g_QingMing_Treasure_Offsetx;
local g_QingMing_Treasure_Offsety;

function QingMing_Treasure_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UPDATE_MAP",false)
	this:RegisterEvent("SCENE_TRANSED",false)
end

function QingMing_Treasure_OnLoad()
	g_QingMing_Treasure_UnifiedPosition = QingMing_Treasure_Frame:GetProperty("UnifiedPosition")
	local pwidth, pheight = QingMing_Treasure_Client:GetWindowSize()
	local swidth, sheight = QingMing_Treasure_Point:GetWindowSize()
	g_QingMing_Treasure_Offsetx = pwidth/2 - swidth/2
	g_QingMing_Treasure_Offsety = pheight/2 - sheight/2
	QingMing_Treasure_FrameBK_Arrival:Play(false)
	-- QingMing_Treasure_Point:Hide()
end

function QingMing_Treasure_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		QingMing_Treasure_Frame:SetProperty("UnifiedPosition", g_QingMing_Treasure_UnifiedPosition)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89304501 ) then
		this:Show()
		g_QingMing_Treasure_IsInLimitDis = false;
		QingMing_Treasure_FrameBK_Arrival:Play(false)
		QingMing_Treasure_Point:Play(true)
		local targetIndex = Get_XParam_INT( 0 );
		g_QingMing_Treasure_TargetPosx = Get_XParam_INT( 1 );
		g_QingMing_Treasure_TargetPosy = Get_XParam_INT( 2 );
		-- QingMing_Treasure_CalInfo:SetTargetPos(targetPosx, targetPosy)
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89304502 ) then
		-- 执行脚本
		local nVisible = 1;
		if not this:IsVisible() then nVisible = 0 end
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnCheckUIOpen" ); 		-- 脚本号
			Set_XSCRIPT_ScriptID( 893045 );						-- 脚本编号
			Set_XSCRIPT_Parameter( 0, nVisible );				-- 参数一:类型
			Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
		Send_XSCRIPT()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89304503 ) then
		this:Hide()
	elseif ( event == "SCENE_TRANSED") then 
		this:Hide()
	elseif ( event == "UPDATE_MAP") then 
		QingMing_Treasure_Update()
	end
end

function QingMing_Treasure_OnHiden()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnUIClose" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 893045 );						-- 脚本编号
		Set_XSCRIPT_ParamCount( 0 );						-- 参数个数
	Send_XSCRIPT()
end
function QingMing_Treasure_GetDistance()
	local myPosx, myPosz, _ = Target:GetMyPos()
	local cameraDir = GetCameraDir();
	local deltax = myPosx - g_QingMing_Treasure_TargetPosx
	local deltay = myPosz - g_QingMing_Treasure_TargetPosy
	if deltax == 0 then deltax = 1 end
	local offsetDir = math.atan(deltay/deltax);
	if deltax < 0 then 
		offsetDir = offsetDir + math.pi;
	end
	local distance = math.floor(math.sqrt(deltax*deltax+deltay*deltay));
	local radis = g_QingMing_Treasure_Offsety - 2
	QingMing_Treasure_Point:SetProperty("UnifiedPosition", string.format("{{0,%s},{0,%s}}", g_QingMing_Treasure_Offsetx-2+radis*math.cos(offsetDir+cameraDir), g_QingMing_Treasure_Offsety-4+radis*math.sin(offsetDir+cameraDir)))
	return distance
end

function QingMing_Treasure_Update()
	if( this:IsVisible() ) then
		g_QingMing_Treasure_NowDistance = QingMing_Treasure_GetDistance()
		if g_QingMing_Treasure_NowDistance >= 5 then 
			QingMing_Treasure_Distance:SetText(ScriptGlobal_Format("#{QMXB_19026_11}", g_QingMing_Treasure_NowDistance))
			if true == g_QingMing_Treasure_IsInLimitDis then 
				g_QingMing_Treasure_IsInLimitDis = false
				QingMing_Treasure_FrameBK_Arrival:Play(false)
				QingMing_Treasure_Point:Play(true)
				PushEvent( "OPEN_HUODONGTEXT_HELP", 2, "")
			end
		else
			if false == g_QingMing_Treasure_IsInLimitDis then
				g_QingMing_Treasure_IsInLimitDis = true
				QingMing_Treasure_Distance:SetText("#{QMXB_19026_12}")
				QingMing_Treasure_FrameBK_Arrival:Play(true)
				QingMing_Treasure_Point:Play(false)
				PushEvent( "OPEN_HUODONGTEXT_HELP", 2, "#{QMXB_19026_41}")
			end
		end
	end
end
