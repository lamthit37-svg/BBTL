--版本预热活动


local g_Yure2022Q2_Letter1_Frame_UnifiedPosition_Load

local g_UICOMMAND = 99810202

local g_Time = {20220721,20220728}

function Yure2022Q2_Letter1_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	--this:RegisterEvent("ADJEST_UI_POS",false)

end

function Yure2022Q2_Letter1_OnLoad()
	Yure2022Q2_Letter1_LoadControl()
	g_Yure2022Q2_Letter1_Frame_UnifiedPosition_Load = Yure2022Q2_Letter1_Frame:GetProperty("UnifiedPosition")
end
--=========
-- 装载控件
--=========
function Yure2022Q2_Letter1_LoadControl()

end
--=========
-- Event
--=========
function Yure2022Q2_Letter1_OnEvent(event)


	if (event == "UI_COMMAND" and tonumber(arg0) == g_UICOMMAND )  then 

		Yure2022Q2_Letter1_Open()


	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Yure2022Q2_Letter1_On_ResetPos()

	elseif event == "HIDE_ON_SCENE_TRANSED" then

		Yure2022Q2_Letter1_Closed()

	-- elseif event == "ADJEST_UI_POS" then

	-- 	Yure2022Q2_Letter1_On_AdjustPos()


	end

end


--=========
-- 重置
--=========
function Yure2022Q2_Letter1_On_ResetPos()

	Yure2022Q2_Letter1_Frame:SetProperty("UnifiedPosition", g_Yure2022Q2_Letter1_Frame_UnifiedPosition_Load)

end



--=========
-- 关闭
--=========
function Yure2022Q2_Letter1_Closed()
	this:Hide()
end

--=========
-- 打开
--=========
function Yure2022Q2_Letter1_Open()


	this:Show()
end

function Yure2022Q2_Letter1_GotoClick()
	local curDay = DataPool:GetServerDayTime()
	if curDay < g_Time[1] or curDay > g_Time[2] then
		PushDebugMessage("#{BBYRHD_220523_11}")
		return
	end
	local nLevel = Player:GetLevel()
	if nLevel < 30 then
		PushDebugMessage("#{BBYRHD_220523_02}")
		return
	end

	AutoRuntoTargetExWithName(220, 171,0, "名士乔峰")--tNpc.x, tNpc.z, tNpc.sceneId, tNpc.name
end