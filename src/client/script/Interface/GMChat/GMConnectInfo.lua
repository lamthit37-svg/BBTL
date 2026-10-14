----------------------
-- GMConnectInfo ---
----------------------
local g_bGMConnectInfoInit = 0
local g_bError = 0
local g_bMini = 0
local g_nSortPos = 0
local g_GMConnectRetInfo =
{
	[1]  = {msg = "#{GMGJTX_111128_06}", error =1, show=1},
	[2]  = {msg = "#{GMGJTX_111128_07}", error =1, show=1},
	[3]  = {msg = "#{GMGJTX_111128_08}", error =1, show=1},
	[4]  = {msg = "#{GMGJTX_111128_05}", error =0, show=1},
	[5]  = {msg = "#{GMGJTX_111128_09}", error =0, show=1},
	[6]  = {msg = "#{GMGJTX_111128_09}", error =0, show=1},
	[7]  = {msg = "#{GMGJTX_111128_11}", error =0, show=1},
	[8]  = {msg = "#{GMGJTX_111128_12}", error =0, show=0},
	[9]  = {msg = "#{GMGJTX_111128_17}", error =1, show=0},
	[10] = {msg = "#{GMGJTX_111128_18}", error =1, show=0},
	[11] = {msg = "#{GMGJTX_111128_19}", error =1, show=0},
}

--===============================================
-- PreLoad()
--===============================================
function GMConnectInfo_PreLoad()

	this:RegisterEvent("GMCHAT_CONNECTINFO_OPEN");
	this:RegisterEvent("GMCHAT_CONNECTINFO_CLOSE");
	this:RegisterEvent("GMCHAT_CONNECTINFO_RET");
	this:RegisterEvent("GMCHAT_CONFIRM_CANCELCONNECT");
	
end

--===============================================
-- OnLoad()
--===============================================
function GMConnectInfo_OnLoad()

end

--===============================================
-- OnEvent()
--===============================================
function GMConnectInfo_OnEvent(event)

	if( event == "GMCHAT_CONNECTINFO_OPEN") then
		if (g_bGMConnectInfoInit == 0) then
			GMConnectInfo_Init()
			g_bGMConnectInfoInit = 1
		end
		g_bMini = 0
		g_bError = 0
		this:Show()
	elseif (event == "GMCHAT_CONNECTINFO_CLOSE" ) then
		g_bGMConnectInfoInit = 0
		g_bMini = 0
		g_nSortPos = 0
		this:Hide()
	elseif ( event == "GMCHAT_CONNECTINFO_RET" ) then
		GMConnectInfo_ConnectRet(tonumber(arg0) + 1, tonumber(arg1))
	elseif ( event == "GMCHAT_CONFIRM_CANCELCONNECT" ) then
		if g_bGMConnectInfoInit == 1 then
			DataPool:GMChat_Cancel()
		end
		g_bGMConnectInfoInit = 0
		g_bError = 0
		g_bMini = 0
		g_nSortPos = 0
		this:Hide()
	end
end

--===============================================
-- Retry_Clicked()
--===============================================
function GMConnectInfo_Retry_Clicked()

	g_bError = 0
	GMConnectInfo_Text:SetText("#{GMGJTX_111128_05}")      
	DataPool:GMChat_ReConnect()
	
	GMConnectInfo_OK:Hide()
	GMConnectInfo_Cancel:Show()
end

--===============================================
-- Cancel_Clicked()
--===============================================
function GMConnectInfo_Cancel_Clicked()
	
	DataPool:GMChat_ConfirmCancelConnect(0)
end

--===============================================
-- Init()
--===============================================
function GMConnectInfo_Init()

	GMConnectInfo_Text:SetText("#{GMGJTX_111128_05}")

	DataPool:GMChat_Connect()

	GMConnectInfo_OK:Hide()
	GMConnectInfo_Cancel:Show()
end


--===============================================
-- ConnectRet()
--===============================================
function GMConnectInfo_ConnectRet(nRet, nPos)
	
	local info = g_GMConnectRetInfo[nRet]
	if info == nil then
		return
	end
	
	if info.error == 1 then
		g_bError = 1
	end
	
	if info.show == 0 then
		return
	end
	
	if g_bGMConnectInfoInit == 0 then
		return
	end
	
	local msg = info.msg
	if nRet == 5 or nRet == 6 then

		if g_nSortPos == nPos then
			return
		end

		g_nSortPos = nPos
		msg = msg..nPos.."#{GMGJTX_111128_40}"
	end
	GMConnectInfo_Text:SetText(msg)

	GMConnectInfo_Cancel:Show()
	if info.error == 1 then
		GMConnectInfo_OK:Show()
	else
		GMConnectInfo_OK:Hide()
	end
	
	if (not this:IsVisible()) then
		PushEvent("UPDATE_MIN_WINDOW_GMCHAT", 1, 1)
	end
end
       
--===============================================
-- Mini_Clicked()                                  
--===============================================
function GMConnectInfo_Mini_Clicked()
	     
	g_bMini = 1
	this:Hide()
	DataPool:GMChat_MinConnectWnd()
end

--===============================================
-- IsConnected()                                  
--===============================================
function GMConnectInfo_IsConnected()
	     
	local nRet = 1
	
	if g_bError == 1 or g_bGMConnectInfoInit == 0 then
		nRet = 0
	end
	
	return nRet
end

--===============================================
-- IsShow()
--===============================================
function GMConnectInfo_IsShow()

	local nRet = 0
	
	if (g_bGMConnectInfoInit == 1 or g_bMini == 1) then
		nRet = 1
	end
	
	return nRet
end

--===============================================
-- IsConnectError()
--===============================================
function GMConnectInfo_IsConnectError()

	return g_bError
end