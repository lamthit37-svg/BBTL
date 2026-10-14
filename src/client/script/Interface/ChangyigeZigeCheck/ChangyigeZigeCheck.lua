--===============================================
-- PreLoad
--=============================================
function ChangyigeZigeCheck_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("CHANGYIGE_CHECK_WAITE")
end

--===============================================
-- OnLoad
--===============================================
function ChangyigeZigeCheck_OnLoad()
	ChangyigeZigeCheck_Text:SetText("")	
end

--===============================================
-- OnEvent
--===============================================
function ChangyigeZigeCheck_OnEvent(event)
	if (event == "UI_COMMAND") and (arg0 == "201305023") then  --我要出售角色倒计时
		ChangyigeZigeCheck_Time:SetProperty("Timer", tostring(60))
		ChangyigeZigeCheck_Time:Show()
		ChangyigeZigeCheck_Text:SetText("#{CYG_130527_65}")	
		this:Show()
	end
	if 	event == "CHANGYIGE_CHECK_WAITE" then  --身份验证倒计时
		ChangyigeZigeCheck_Time:SetProperty("Timer", tostring(60))
		ChangyigeZigeCheck_Time:Show()
		ChangyigeZigeCheck_Text:SetText("#{CYG_130527_89}")	
		this:Show()
	end	
end

function ChangyigeZigeCheck_TimeOut()
	ChangyigeZigeCheck_Time:Hide()
	this:Hide()
	PushDebugMessage("#{CYG_130527_64}") --S改字典
end