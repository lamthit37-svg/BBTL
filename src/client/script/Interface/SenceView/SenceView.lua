--******************************
--场景摄像机推进界面
--******************************
local g_text ="        "
local g_SenceView_UnifiedPosition
local g_IsNoEsc = 0
function SenceView_PreLoad()
	this:RegisterEvent("SENECE_VIEW")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("UI_COMMAND")--借用下这个干点事情，不想写新的消息包了
end

function SenceView_OnLoad()
	SenceView_Text:Hide()
	g_SenceView_UnifiedPosition	= SenceView:GetProperty("UnifiedPosition");
end

function SenceView_OnEvent(event)
	if( event == "SENECE_VIEW" and tonumber(arg0) == 1 ) then
		this:Show()
		SenceView_Text:SetText("")
		if g_IsNoEsc == 0 then
			SenceView_Text:SetText(g_text.."#{SXJTJ_110705_03}".."#r".."#{SXJTJ_110705_04}")
		end
		local bEnableBG = Variable:GetVariable("EnableBGSound") == "1";
		if bEnableBG then
			Variable:SetVariable("EnableBGSound", (true and "1") or "0", 0)
		end
	elseif (event == "SENECE_VIEW" and tonumber(arg0) == 0) then
		g_IsNoEsc = 0
		ChangeMain()
	elseif (event == "SENECE_VIEW" and tonumber(arg0) == 2) then
		g_IsNoEsc = 0
		this:Hide()
	elseif (event == "SENECE_VIEW" and tonumber(arg0) == 3) then
		SenceView_Text:Show()
	elseif (event == "SENECE_VIEW" and tonumber(arg0) == 4) then
		SenceView_Text:Hide()
	elseif (event == "ADJEST_UI_POS" ) then
		SenceView_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then	
		SenceView_ResetPos()
	elseif (event == "UI_COMMAND" and tonumber(arg0) == 20110831) then
		--播放该场景镜头轨迹
		g_IsNoEsc = 1
		PlayerCameraTrack()
	end
end

function SenceView_ResetPos()
	SenceView:SetProperty("UnifiedPosition", g_SenceView_UnifiedPosition)
end