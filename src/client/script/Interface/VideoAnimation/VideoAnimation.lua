-- !!!reloadscript =VideoAnimation
-- Game内通用播放mp4视频界面

local g_frame_unifiedposition
--**************UI相关内容的常量************************
local g_Timer_Tick_Time = 0.0		-- 计数器
local g_Timer_Tick_Delta = 0.5		-- 计时器每秒计时时间
local g_Timer_Out_Time = 10			-- 10秒视频还没有播放关闭界面
local g_Const_State_Loading 	= 1	-- 资源加载中
local g_Const_State_Loaded 		= 2 -- 资源加载完成
local g_Const_State_Playing 	= 3 -- 准备播放: 等待回调
local g_Const_State_Played		= 4 -- 视频播放中
local g_Const_State_Ended		= 5 -- 视频播放结束

local g_Play_Video_Info = {
	-- start_delay  0:加载完成立即播放 >0:界面显示等待x秒开始播放视频
	-- end_delay    0:播放完成回调结束 >0:视频播放结束等待x秒关闭界面
	-- {idx = 1, name = "2024Q3.mp4", start_delay = 0, end_delay=0},	--重播CG
	-- {idx = 2, name = "2024Q3.webm", start_delay = 2, end_delay=2},	--重播CG
	{idx = 3, name = "Qixi_Yure.mp4", start_delay = 0, end_delay=0},	-- 七夕预热活动
	{idx = 4, name = "QiXi_PVE_GE.mp4", start_delay = 0, end_delay=0},	-- 七夕副本1
	{idx = 5, name = "QiXi_PVE_BE.mp4", start_delay = 0, end_delay=0},	-- 七夕副本2
	
}

local g_Video_Load_State = 0		-- 1: loading中 2:已经开始播放
local g_Video_Index = 0
local g_Video_FileName = ""
local g_Video_Start_Delay = 0		-- 开始延迟的时间
local g_Video_End_Delay = 0			-- 结束延迟的时间
local g_Video_End_Time = 0.0		-- 
local g_Show_EndDebugMessage = 0
--***************UI相关内容的常量end************************

function VideoAnimation_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("GAME_PLAY_VIDEO")
	this:RegisterEvent("GAME_VIDEO_MSG")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("SCENE_TRANSED")
end

function VideoAnimation_OnLoad()
	g_frame_unifiedposition = VideoAnimation_Frame:GetProperty("UnifiedPosition")
end

function VideoAnimation_OnEvent(event)
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		VideoAnimation_ResetPos()
	elseif (event == "SCENE_TRANSED" or event == "HIDE_ON_SCENE_TRANSED") then
		if not this:IsVisible() or g_Video_Load_State == 0 then 
			return 
		end
		g_Show_EndDebugMessage = 0
		VideoAnimation_OnHide()
	elseif event == "GAME_PLAY_VIDEO" then
		VideoAnimation_LoadVideo(tonumber(arg0))
	elseif event == "GAME_VIDEO_MSG" then
		state = arg0
		-- PushDebugMessage("GAME_VIDEO_MSG:"..state..":"..tostring(g_Video_Load_State))
		if g_Video_Load_State == 0 then 
			return
		end
		if state == "loaded" then 
			VideoAnimation_OnVideoLoad()
		elseif state == "start" then 
			VideoAnimation_OnVideoStart()
		elseif state == "end" then 
			VideoAnimation_OnVideoEnd()
		end
	elseif event == "UI_COMMAND" and tonumber(arg0) == 26072201 then
		VideoAnimation_LoadVideo(Get_XParam_INT(0))
	end
end

function VideoAnimation_OnShow()
	VideoAnimation_Bk:Show()
	VideoAnimation_Subtitles:Show()
	SetTimer("VideoAnimation","VideoAnimation_OnTimer()", g_Timer_Tick_Delta*1000)
	-- 特写背景图
	g_Timer_Tick_Time = 0.0
	g_Video_Load_State = g_Const_State_Loading
	g_Show_EndDebugMessage = 1
	Lua_WebVideoPreLoad(g_Video_FileName,"30")
	-- DataPool:SetCanUseHotKey(0)
	this:Show()
end

function VideoAnimation_LoadVideo(idx)
	if g_Video_Load_State ~= 0 then 
		-- 防止重复加载
		return
	end
	g_Video_Index = 0
	for i, v in pairs(g_Play_Video_Info) do 
		if v.idx == idx then 
			g_Video_Index = idx
			g_Video_FileName = v.name
			g_Video_End_Delay = v.end_delay
			g_Video_Start_Delay = v.start_delay
			VideoAnimation_OnShow()
			return
		end
	end
	PushDebugMessage("VideoAnimation_LoadVideo: not found idx="..tostring(idx))
end

function VideoAnimation_OnTimer()
	g_Timer_Tick_Time = g_Timer_Tick_Time + g_Timer_Tick_Delta
	if g_Video_Load_State < g_Const_State_Played and g_Timer_Tick_Time >= g_Timer_Out_Time then
		VideoAnimation_OnHide()
	elseif g_Video_Load_State == g_Const_State_Ended and g_Timer_Tick_Time >= g_Video_End_Time then
		VideoAnimation_OnHide()
	elseif g_Video_Load_State == g_Const_State_Loaded and g_Timer_Tick_Time >= g_Video_Start_Delay then
		-- 开始播放时间到 且 预加载完成
		g_Video_Load_State = g_Const_State_Playing
		Lua_WebPlayVideo()
	end
end

function VideoAnimation_OnVideoLoad()
	g_Video_Load_State = g_Const_State_Loaded
	if g_Timer_Tick_Time >= g_Video_Start_Delay then
		g_Video_Load_State = g_Const_State_Playing
		Lua_WebPlayVideo()
	end
end

function VideoAnimation_OnVideoStart()
	g_Video_Load_State = g_Const_State_Played
	VideoAnimation_Bk:Hide()
	VideoAnimation_Subtitles:Hide()
end

function VideoAnimation_OnVideoEnd()
	if g_Video_End_Delay > 0.01 then 
		g_Video_End_Time = g_Timer_Tick_Time + g_Video_End_Delay
		g_Video_Load_State = g_Const_State_Ended
	else
		VideoAnimation_OnHide()
	end
end

function VideoAnimation_ResetPos()
	VideoAnimation_Frame:SetProperty("UnifiedPosition", g_frame_unifiedposition)
end
function VideoAnimation_SkipClick()
	VideoAnimation_OnHide()
end
function VideoAnimation_OnHide()
	if not this:IsVisible() or g_Video_Load_State == 0 then 
		return 
	end
	-- 结束回调
	if g_Video_Index == 3 then 
		 Clear_XSCRIPT()
		 	Set_XSCRIPT_Function_Name("OnMovieEnd")
		 	Set_XSCRIPT_ScriptID(900063)
		 	Set_XSCRIPT_ParamCount(0)
		 Send_XSCRIPT()
	end
	if g_Show_EndDebugMessage > 0 then 
		if g_Video_Load_State >= g_Const_State_Ended then 
			-- 视频结束后预留空白处理
		elseif g_Video_Load_State == g_Const_State_Played then 
			PushDebugMessage( "#{DHBF_260717_02}" )
		else
			PushDebugMessage( "#{DHBF_260717_01}" )
		end
	end
	-- DataPool:SetCanUseHotKey(1)
	KillTimer("VideoAnimation_OnTimer()")
	Lua_WebKillVideo()
	g_Video_Load_State = 0
	g_Timer_Tick_Time = 0.0
	g_Show_EndDebugMessage = 0
	this:Hide()
end
