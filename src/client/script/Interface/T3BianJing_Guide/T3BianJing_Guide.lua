-- 新天外引导任务

local g_frame_unifiedposition

--**************UI相关内容的常量************************
local g_scenetype_bianjing = 4511
local g_ui_commonid = 88824701
local g_tick = 0.0				-- 计数器
local g_tick_time = 1.0			-- 计时器每秒计时时间
local g_wait_time = 4.0			-- 等待时间
local g_start_time = 1.0		-- 开始预加载的时间
local g_alpha_time = 15.0		-- 遮挡图显隐时间
local g_movie_perload = 0		-- 是否已经预加载
local from_to_alpha = string.format("curve:Liner mode:Once duration:%s startx:1 starty:0 endx:0 endy:0",g_alpha_time)

-- 是否需要显示UI
local g_need_show = 0
--***************UI相关内容的常量end************************
local function cleanup()
	g_tick = 0.0
	g_movie_perload = 0
	g_need_show = 0
end
function T3BianJing_Guide_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("SCENE_TRANSED")
end

function T3BianJing_Guide_OnLoad()
	g_frame_unifiedposition = T3BianJing_Guide_Frame:GetProperty("UnifiedPosition")
end

function T3BianJing_Guide_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == g_ui_commonid then
		--T3BianJing_Guide_OnShow()
		g_need_show = 1
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		T3BianJing_Guide_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		T3BianJing_Guide_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		local sceneid = GetSceneServerID()
		local scenetype = DataPool:GetT300SceneIDManagerTSceneTypeID(sceneid)
		if scenetype ~= g_scenetype_bianjing then
			if this:IsVisible() then
				T3BianJing_Guide_Hide()
			end
		else
			if this:IsVisible() then
			-- 主动屏蔽热键
				DataPool:SetCanUseHotKey(0)
			end
		end
	elseif event == "SCENE_TRANSED" then
		T3BianJing_Guide_OnScene_Transed()
	end
end

function T3BianJing_Guide_OnScene_Transed()
	-- 2020.10.06
	-- 这个地方非常不友好，有其他功能在切换界面的时候设置了可以点击，
	-- 并且多UI事件在设置，如果后面有其他功能仍然去设置成可快捷键，就会导致该功能异常
	if this:IsVisible() then
		DataPool:SetCanUseHotKey(0)
		SetAutoRunTargetNPCName("")
		ChangeStopState()
	else
		if g_need_show > 0 then
			local sceneid = GetSceneServerID()
			local scenetype = DataPool:GetT300SceneIDManagerTSceneTypeID(sceneid)
			if scenetype == g_scenetype_bianjing then
				DataPool:SetCanUseHotKey(0)
				SetAutoRunTargetNPCName("")
				ChangeStopState()
				T3BianJing_Guide_OnShow()
			end
		end
	end
end

function T3BianJing_Guide_OnShow()
	cleanup()
	SetTimer("T3BianJing_Guide","T3BianJing_Guide_OnTimer()", g_tick_time*1000)


	--T3BianJing_Guide_Client:Tween_Reset("Alpha",true)
	--T3BianJing_Guide_Client:Tween_SetInfo("Alpha", from_to_alpha)
	--T3BianJing_Guide_Client:Tween_Play("Alpha", true, true)
	T3BianJing_Guide_Client:Show()

	this:Show()
end

function T3BianJing_Guide_OnTimer()
	g_tick = g_tick + g_tick_time
	if g_tick >= g_wait_time then
		-- 播放动画，顺便关闭界面
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name("OnMovieEnd")
			Set_XSCRIPT_ScriptID(888247)
			Set_XSCRIPT_Parameter(0, 2)
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
		Lua_WebPlayVideo()
		T3BianJing_Guide_Hide()
	elseif g_tick >= g_start_time then
		-- 开始预加载
		if g_movie_perload < 1 then
			g_movie_perload = 1
			Lua_WebVideoPreLoad("2020BJvideo.mp4","30")
		end
	end
	
end

function T3BianJing_Guide_ResetPos()
	T3BianJing_Guide_Frame:SetProperty("UnifiedPosition", g_frame_unifiedposition)
end

function T3BianJing_Guide_Hide()
	DataPool:SetCanUseHotKey(1)
	KillTimer("T3BianJing_Guide_OnTimer()")
	cleanup()
	this:Hide()
end