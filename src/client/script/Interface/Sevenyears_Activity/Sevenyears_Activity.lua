
--周年应景 降鸿福
local g_Sevenyears_Activity_Frame_UnifiedPosition
local g_Sevenyears_Activity_OpenBoxTimes

local g_Sevenyears_Activity_OpenBoxTimesTable = {
	[0] = {
		[1] = {requireNum =50 , rewardNum =1 ,},
		[2] = {requireNum =150, rewardNum =3 ,},
		[3] = {requireNum =450, rewardNum =5 ,},
	},
	[1] = {
		[1] = {requireNum =1  , rewardNum =1 ,},
		[2] = {requireNum =50 , rewardNum =3 ,},
		[3] = {requireNum =150, rewardNum =5 ,},
	},
}

function Sevenyears_Activity_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("TODAY_ACTIVE_POINT",false)
	
end

function Sevenyears_Activity_OnLoad()
	g_Sevenyears_Activity_Frame_UnifiedPosition = Sevenyears_Activity_Frame_BK:GetProperty("UnifiedPosition")

end

function Sevenyears_Activity_OnEvent(event)
	if(event == "UI_COMMAND" and tonumber(arg0) == 2023030901) then
		g_Sevenyears_Activity_OpenBoxTimes = Get_XParam_INT(0) --回头改成消耗次数 根据活跃值给的次数减去该值为最终值
		-- PushDebugMessage("g_Sevenyears_Activity_OpenBoxTimes:"..tostring(g_Sevenyears_Activity_OpenBoxTimes))
		if Get_XParam_INT(1) ~= nil and Get_XParam_INT(1) == 1 then
			Sevenyears_Activity_Refresh()
		else
			if this:IsVisible() then
				Sevenyears_Activity_Refresh()
			else
				this:Show()
				Sevenyears_Activity_Refresh()
			end
		end
	elseif ( event == "TODAY_ACTIVE_POINT" ) then
		Sevenyears_Activity_Refresh()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Sevenyears_Activity_On_ResetPos()
	elseif event == "OPEN_ANNIVERSARY_BEFORE" then
		this:Hide()
	elseif event == "ADJEST_UI_POS" then
		Sevenyears_Activity_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		this:Hide()
	end
	
end

function Sevenyears_Activity_Refresh()

	local kjtype   = KaJi:LuaFnGetKaJiType(67)
	if kjtype == 0 then
		Sevenyears_Activity_Text:SetText("#{TJHF_230228_06}")
	elseif kjtype == 1 then
		Sevenyears_Activity_Text:SetText("#{TJHF_230228_07}")
	end
	--活跃
	local nTodayActivePoint = Player:GetData("TODAYACTIVEPOINT")
	if nTodayActivePoint == nil then
		nTodayActivePoint = 0
	end

	local openTimesTable =  g_Sevenyears_Activity_OpenBoxTimesTable[kjtype]
	if openTimesTable == nil then
		return
	end
	local openTimes = 0
	for i = 1,table.getn(openTimesTable) do
		if nTodayActivePoint >= openTimesTable[i].requireNum then
			openTimes = openTimesTable[i].rewardNum
		end
	end

	local finalTimes = openTimes - g_Sevenyears_Activity_OpenBoxTimes
	if finalTimes<0 then
		finalTimes = 0
	end
	Sevenyears_Activity_Text2:SetText(ScriptGlobal_Format("#{TJHF_230228_08}", nTodayActivePoint))  
	Sevenyears_Activity_Text3:SetText(ScriptGlobal_Format("#{TJHF_230228_09}", finalTimes))
	
end

--帮助问号点击
function Sevenyears_Activity_ShowHelp()
	PushEvent("CCSHOP_HELP", 188)
end

function Sevenyears_Activity_On_ResetPos()
	Sevenyears_Activity_Frame_BK:SetProperty("UnifiedPosition", g_Sevenyears_Activity_Frame_UnifiedPosition)
end

function Sevenyears_Activity_OnHide()
	
end

function Sevenyears_Activity_Hide()
	this:Hide()
end
