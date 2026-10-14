--版本预热活动


local g_Yure2022Q2_Letter2_Frame_UnifiedPosition_Load

local g_UICOMMAND = 99810203

local g_Time = {20220729,20220810}

--local g_ShowGoto = 1

function Yure2022Q2_Letter2_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	--this:RegisterEvent("ADJEST_UI_POS",false)

end

function Yure2022Q2_Letter2_OnLoad()
	Yure2022Q2_Letter2_LoadControl()
	g_Yure2022Q2_Letter2_Frame_UnifiedPosition_Load = Yure2022Q2_Letter2_Frame:GetProperty("UnifiedPosition")
end
--=========
-- 装载控件
--=========
function Yure2022Q2_Letter2_LoadControl()

end
--=========
-- Event
--=========
function Yure2022Q2_Letter2_OnEvent(event)


	if (event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND )  then 
		-- local haveMission = Get_XParam_INT(0)
		-- local doneMission = Get_XParam_INT(1)
		-- if haveMission > 0 or doneMission > 0 then
		-- 	g_ShowGoto = 0
		-- else
		-- 	g_ShowGoto = 1
		-- end
		Yure2022Q2_Letter2_Open()


	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Yure2022Q2_Letter2_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		Yure2022Q2_Letter2_Closed()

	-- elseif event == "ADJEST_UI_POS" then

	-- 	Yure2022Q2_Letter2_On_AdjustPos()


	end

end


--=========
-- 重置
--=========
function Yure2022Q2_Letter2_On_ResetPos()

	Yure2022Q2_Letter2_Frame:SetProperty("UnifiedPosition", g_Yure2022Q2_Letter2_Frame_UnifiedPosition_Load)

end



--=========
-- 关闭
--=========
function Yure2022Q2_Letter2_Closed()
	this:Hide()
end

--=========
-- 打开
--=========
function Yure2022Q2_Letter2_Open()	
	-- if g_ShowGoto == 1 then
	-- 	Yure2022Q2_Letter2_Goto:Show()
	-- else
	-- 	Yure2022Q2_Letter2_Goto:Hide()
	-- end
	this:Show()
end

function Yure2022Q2_Letter2_GotoClick()
	local curDay = DataPool:GetServerDayTime()
	if curDay < g_Time[1] or curDay > g_Time[2] then
		PushDebugMessage("#{BBYRHD_220523_11}")
		return
	end
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{BBYRHD_220523_12}")
		return
	end

	AutoRuntoTargetExWithName(172, 232,0, "杨文广")--tNpc.x, tNpc.z, tNpc.sceneId, tNpc.name

end 
