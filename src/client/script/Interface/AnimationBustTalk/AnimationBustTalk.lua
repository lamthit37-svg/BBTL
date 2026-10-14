

local g_ui_group_ltr = {}
local g_ui_group_rtl = {}

function AnimationBustTalk_PreLoad()
	this:RegisterEvent("MOVIE_GAME_EVENT",true);
end

function AnimationBustTalk_OnLoad()
	g_ui_group_ltr = { AnimationBustTalk_Name, AnimationBustTalk_Info, AnimationBustTalk_Bust }
	g_ui_group_rtl = { AnimationBustTalk_Name1, AnimationBustTalk_Info1, AnimationBustTalk_Bust1 }
end

function AnimationBustTalk_OnEvent(event)
	if event == "MOVIE_GAME_EVENT" and arg1 == "MEvent_Game_UI_Talk" then
		local bShow,data = ClientMovie:ParseTalkParam(arg2)
		if bShow == 1 then
			AnimationBustTalk_Show(data)
			this:Show()
		else
			this:Hide()
		end
		
	end
end


function AnimationBustTalk_AutoHide()
	this:Hide()
end

function AnimationBustTalk_Show( data )
	local ui1,ui2
	if data.pos == 1 then
		ui1 = g_ui_group_ltr
		ui2 = g_ui_group_rtl
	else
		ui1 = g_ui_group_rtl
		ui2 = g_ui_group_ltr
	end
	for i, c in ipairs( ui2 ) do
		c:Hide()
	end
	for i, c in ipairs( ui1 ) do
		c:Show()
	end
	ui1[1]:SetText(data.Name)
	ui1[2]:SetText(data.Tips)
	ui1[2]:SetProperty("Image",data.Head)
	
	local nTimeout = data.Stay
	if nTimeout > 3000 then
		nTimeout = 3000
	end
	SetTimer("AnimationBustTalk","AnimationBustTalk_AutoHide()",nTimeout)
end

