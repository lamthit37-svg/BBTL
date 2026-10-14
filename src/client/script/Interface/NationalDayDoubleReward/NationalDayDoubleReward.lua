local g_NationalDayDoubleReward_UnifiedPosition = nil 
function NationalDayDoubleReward_PreLoad()

	this:RegisterEvent("UI_COMMAND", true)	
	--this:RegisterEvent("OPEN_DOUBLEEXP_TEXT",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end


function NationalDayDoubleReward_OnLoad()
	g_NationalDayDoubleReward_UnifiedPosition = NationalDayDoubleReward_FrameNULL:GetProperty("UnifiedPosition")

end



function NationalDayDoubleReward_Close()
	this:Hide()

end


function NationalDayDoubleReward_ResetPos()
	NationalDayDoubleReward_FrameNULL:SetProperty("UnifiedPosition", g_NationalDayDoubleReward_UnifiedPosition)
end

function NationalDayDoubleReward_OnEvent(event)


	--if event == "OPEN_DOUBLEEXP_TEXT" then
		--this:Show()
	if event == "UI_COMMAND" and tonumber(arg0) == 89316711 then
		this:Show()
		local kajiType = KaJi:LuaFnGetKaJiType(108)
		if kajiType == 1 then
			NationalDayDoubleReward_Text1:SetText( "#{GQSB_220914_01}" )
		else
			NationalDayDoubleReward_Text1:SetText( "#{GQSB_200728_04}" )
		end
	elseif(event == "ADJEST_UI_POS") then
		NationalDayDoubleReward_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		NationalDayDoubleReward_ResetPos()	
	end
end
