----------------------
-- GMMark ---
----------------------

local g_nConnectState = 0
local g_MarkBtn = {};

--===============================================
-- PreLoad()
--===============================================
function GMMark_PreLoad()
	this:RegisterEvent("GMCHAT_MARKWND_OPEN");
	this:RegisterEvent("GMCHAT_CONNECTINFO_RET");
end

--===============================================
-- OnLoad()
--===============================================
function GMMark_OnLoad()

	g_MarkBtn[1] = GMMark_Check_Option1
	g_MarkBtn[2] = GMMark_Check_Option2
	g_MarkBtn[3] = GMMark_Check_Option3
	g_MarkBtn[4] = GMMark_Check_Option4
end

--===============================================
-- OnEvent()
--===============================================
function GMMark_OnEvent(event)

	if( event == "GMCHAT_MARKWND_OPEN" ) then
		GMMark_OnInit()
	elseif ( event == "GMCHAT_CONNECTINFO_RET" ) then
		GMMark_OnConnectStateChanged(tonumber(arg0) + 1)
	end
end

--===============================================
-- OnInit()
--===============================================
function GMMark_OnInit()
	
	GMMark_Text:RemoveAllChatString()
	
	if g_nConnectState == 11 then
		GMMark_Text:InsertChatString("#{GMGJTX_111128_20}")
		GMMark_Cancel:Disable();
	elseif g_nConnectState == 9 or g_nConnectState == 10 then
		GMMark_Text:InsertChatString("#{GMGJTX_111128_20}")
		GMMark_Cancel:Disable();
	else
		GMMark_Text:InsertChatString("#{GMGJTX_111128_21}")
		GMMark_Cancel:Enable();
	end
	
	for i = 1, table.getn(g_MarkBtn) do
		g_MarkBtn[i]:SetCheck(0)
	end
	
	--默认为满意
	g_MarkBtn[2]:SetCheck(1)
	
	this:Show()
end

--===============================================
-- OnConnectStateChanged()
--===============================================
function GMMark_OnConnectStateChanged(nState)

	g_nConnectState = nState
end

--===============================================
-- MarkBtn_Clicked()
--===============================================
function GMMark_MarkBtn_Clicked(nIdx)
	
	for i = 1, table.getn(g_MarkBtn) do
		g_MarkBtn[i]:SetCheck(0)
	end
	
	g_MarkBtn[nIdx]:SetCheck(1)
end

--===============================================
-- OK_Clicked()
--===============================================
function GMMark_OK_Clicked()
	
	local nMark = 2
	for i = 1, table.getn(g_MarkBtn) do
		if g_MarkBtn[i]:GetCheck() == 1 then
			nMark = i
		end
	end
	
	DataPool:GMChat_ConfirmStopChat(1, nMark)
	PushDebugMessage("#{GMGJTX_111128_42}")
	
	this:Hide()
end

--===============================================
-- Cancel_Clicked()
--===============================================
function GMMark_Cancel_Clicked()
	
	this:Hide()
end