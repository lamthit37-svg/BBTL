----------------------
-- GMChat ---
----------------------
local g_bGMChatInit = 0
local g_nConnectState = 0
local g_nChatState = 8
local g_bMini = 0
local g_bError = 0
local g_nDefaultMark = 2
local g_ErrorMsg =
{
	[9] =  {msg = "#{GMGJTX_111128_17}", error =1},
	[10] = {msg = "#{GMGJTX_111128_18}", error =1},
	[11] = {msg = "#{GMGJTX_111128_19}", error =1},
}

--===============================================
-- PreLoad()
--===============================================
function GMChat_PreLoad()
	this:RegisterEvent("GMCHAT_CHATWND_OPEN");
	this:RegisterEvent("GMCHAT_CHATWND_MESSAGE");
	this:RegisterEvent("GMCHAT_CONFIRM_STOPCHAT");
	this:RegisterEvent("GMCHAT_CONNECTINFO_RET");
	this:RegisterEvent("GMCHAT_CONFIRM_CANCELCONNECT");
end

--===============================================
-- OnLoad()
--===============================================
function GMChat_OnLoad()

	GMChat_HistoryContent__auto_parent__:SetProperty("MouseLButtonHollow", "False")
	GMChat_HistoryContent__auto_parent__:SetProperty("MouseRButtonHollow", "False")
end

--===============================================
-- OnEvent()
--===============================================
function GMChat_OnEvent(event)

	if( event == "GMCHAT_CHATWND_OPEN" ) then
		GMChat_OnInit()
	elseif ( event == "GMCHAT_CHATWND_MESSAGE" ) then
		GMChat_OnSendMsg(arg0)
	elseif ( event == "GMCHAT_CONNECTINFO_RET" ) then
		GMChat_OnConnectStateChanged(tonumber(arg0) + 1)
	elseif ( event == "GMCHAT_CONFIRM_STOPCHAT" ) then
		GMChat_OnStopChat(tonumber(arg0))
	elseif ( event == "GMCHAT_CONFIRM_CANCELCONNECT" ) then
		GMChat_OnStopChat(g_nDefaultMark)
	end
end

--===============================================
-- Close_Clicke()
--===============================================
function GMChat_Close_Clicked()
	
	DataPool:GMChat_ConfirmStopChat(0)
end

--===============================================
-- Send_Clicked()
--===============================================
function GMChat_Send_Clicked()
	
	if GMChat_IsConnected() == 0 then
		GMChat_SendSystemMsg("#{GMGJTX_111128_13}")
		return
	end
	
	DataPool:GMChat_SendMsg(GMChat_Edit:GetText())
	GMChat_Edit:SetText("")
	
	KillTimer("GMChat_OnChatTimerWarning()");
	KillTimer("GMChat_OnChatTimerFinalWarning()");
	SetTimer("GMChat","GMChat_OnChatTimerWarning()", 300000)	--5分钟提示
end

--===============================================
-- Mini_Clicked()
--===============================================
function GMChat_Mini_Clicked()
	
	g_bMini = 1
	this:Hide()
	DataPool:GMChat_MinChatWnd()
end

--===============================================
-- OnInit()
--===============================================
function GMChat_OnInit()

	if (g_bGMChatInit == 0) then
		g_bGMChatInit = 1
		g_bError = 0
		GMChat_Edit:SetText("")
		GMChat_HistoryContent:RemoveAllChatString()
		GMChat_SendSystemMsg("#{GMGJTX_111128_12}")
	end
	
	KillTimer("GMChat_OnChatTimerWarning()");
	KillTimer("GMChat_OnChatTimerFinalWarning()");
	SetTimer("GMChat","GMChat_OnChatTimerWarning()", 300000)	--5分钟提示
	
	g_bMini = 0
	
	this:Show()
end

--===============================================
-- OnSendMsg()
--===============================================
function GMChat_OnSendMsg(msg)

	GMChat_HistoryContent:InsertChatString(msg)
	if (not this:IsVisible()) then
		PushEvent("UPDATE_MIN_WINDOW_GMCHAT", 2, 1)
	end
end

--===============================================
-- OnConnectStateChanged()
--===============================================
function GMChat_OnConnectStateChanged(nState)
	
	g_nConnectState = nState
	
	if g_bGMChatInit == 1 and g_nConnectState ~= g_nChatState then
		GMChat_OnConnectError()
		if (not this:IsVisible()) then
			PushEvent("UPDATE_MIN_WINDOW_GMCHAT", 2, 1)
		end
	end
end

--===============================================
-- OnStopChat()
--===============================================
function GMChat_OnStopChat(nMake)

	if g_bGMChatInit == 1 then
		DataPool:GMChat_StopChat(nMake)
	end
	
	g_bGMChatInit = 0
	g_bError = 0
	g_bMini = 0
	KillTimer("GMChat_OnChatTimerWarning()");
	KillTimer("GMChat_OnChatTimerFinalWarning()");
	this:Hide()
end

--===============================================
-- OnConnectError()
--===============================================
function GMChat_OnConnectError()
	
	if g_bError == 0 then
		local info = g_ErrorMsg[g_nConnectState]
		if info == nil then
			return
		end
		
		GMChat_SendSystemMsg(info.msg)
		g_bError = 1
	end
	
	KillTimer("GMChat_OnChatTimerWarning()");
	KillTimer("GMChat_OnChatTimerFinalWarning()");
end

--===============================================
-- OnChatTimerWarning()
--===============================================
function GMChat_OnChatTimerWarning()
	
	GMChat_SendSystemMsg("#{GMGJTX_111128_16}")
	KillTimer("GMChat_OnChatTimerWarning()");
	SetTimer("GMChat","GMChat_OnChatTimerFinalWarning()", 10000)	--10秒提示
end

--===============================================
-- OnChatTimerWarning()
--===============================================
function GMChat_OnChatTimerFinalWarning()
	
	GMChat_SendSystemMsg("#{GMGJTX_111128_17}")
	KillTimer("GMChat_OnChatTimerFinalWarning()");
	
	g_nConnectState = 9
	DataPool:GMChat_StopChat(2)
end


--===============================================
-- SendSystemMsg()
--===============================================
function GMChat_SendSystemMsg(msg)

	local time = DataPool:GetFormatTimeString()
	local sysmsg = "#cfff263系统 "..time.."#r#W"..msg
	GMChat_HistoryContent:InsertChatString(sysmsg)
end

--===============================================
-- IsConnected()
--===============================================
function GMChat_IsConnected()

	local nRet = 1
	
	if GMConnectInfo_IsConnectError() == 1 or g_bGMChatInit == 0 or g_nConnectState ~= g_nChatState or g_bError == 1 then
		nRet = 0
	end
	
	return nRet
end

--===============================================
-- IsShow()
--===============================================
function GMChat_IsShow()

	local nRet = 0
	
	if (g_bGMChatInit == 1 or g_bMini == 1) then
		nRet = 1
	end
	
	return nRet
end
