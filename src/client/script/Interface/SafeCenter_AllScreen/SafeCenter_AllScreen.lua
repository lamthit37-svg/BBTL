--全屏透明遮掩界面--

function SafeCenter_AllScreen_PreLoad()

	this:RegisterEvent("OPEN_SAFECENTER_ALLSCREEN")

	this:RegisterEvent("CLOSE_SAFECENTER_ALLSCREEN")
end	
function SafeCenter_AllScreen_OnLoad()
end

function SafeCenter_AllScreen_OnEvent(event)
	if ( event == "OPEN_SAFECENTER_ALLSCREEN") then
		
		if( this:IsVisible() ) then
			return
		else
			
			this:Show()
		end
	elseif(event == "CLOSE_SAFECENTER_ALLSCREEN") then
		this:Hide()
	end
end	