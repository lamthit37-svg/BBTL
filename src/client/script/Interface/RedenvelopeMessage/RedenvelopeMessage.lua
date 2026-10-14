local m_NormalButton
local m_RareButton

function RedenvelopeMessage_PreLoad()
	this:RegisterEvent("TOGGLE_GUILD_GIFT_BUTTON")
end

function RedenvelopeMessage_OnLoad()
	m_NormalButton = RedenvelopeMessage_Button_Action1_Mask
	m_RareButton = RedenvelopeMessage_Button_Action2_Mask
	
	m_NormalButton:Hide()
	m_NormalButton:PlayWarning(0)
	m_RareButton:Hide()
	m_RareButton:PlayWarning(0)
	
end

function RedenvelopeMessage_OnEvent(event)

	if event == "TOGGLE_GUILD_GIFT_BUTTON" then
		if tonumber(arg0) == 0 then
			local hide_type = tonumber(arg1)
			RedenvelopeMessage_HideButton(hide_type)	
		else
			local button_type = tonumber(arg1)
			RedenvelopeMessage_Show( button_type  )	
		end
	end

end

function RedenvelopeMessage_Show(button_type)
	
	if button_type == 0 then
		m_NormalButton:Show()
		m_NormalButton:PlayWarning(1)
	--	SetTimer("RedenvelopeMessage","RedenvelopeMessage_CountDownNormal()", 60000)
		RedenvelopeMessage_Button_Action1_Watch:SetProperty("Timer","60")
	else
		m_RareButton:Show()
		m_RareButton:PlayWarning(1)
	--	SetTimer("RedenvelopeMessage","RedenvelopeMessage_CountDownRare()", 60000)
		
		RedenvelopeMessage_Button_Action2_Watch:SetProperty("Timer","60")
	end
	
	if not this:IsVisible() then
		this:Show()
	end
	
end

function RedenvelopeMessage_HideButton(hide_type)
	
	if hide_type == 0 then
		m_NormalButton:Hide()
		m_NormalButton:PlayWarning(0)
	else
		m_RareButton:Hide()
		m_RareButton:PlayWarning(0)
	end
	
	if not m_NormalButton:IsVisible() and not m_RareButton:IsVisible() then
		this:Hide()
	end
	
end

function RedenvelopeMessage_ButtonOnClicked(button_type)
	Guild:TakeGift(button_type)
end

function RedenvelopeMessage_CountDownNormal()
--	RedenvelopeMessage_HideButton(0)
--	KillTimer("RedenvelopeMessage_CountDownNormal()")
end

function RedenvelopeMessage_CountDownRare()
--	RedenvelopeMessage_HideButton(1)
--	KillTimer("RedenvelopeMessage_CountDownRare()")
end

