--===============================================
-- OnLoad()
--===============================================
function PKWarning_PreLoad()
    this:RegisterEvent("OPENWND_PKWARNING",true)
    this:RegisterEvent("CLOSEWND_PKWARNING",false)
end

--===============================================
-- OnLoad()
--===============================================
function PKWarning_OnLoad()    
end

--===============================================
-- OnEvent()
--===============================================
function PKWarning_OnEvent(event)



    if ( event == "OPENWND_PKWARNING" ) then
		this:Show()
	end
    
    if ( event == "CLOSEWND_PKWARNING" ) then
       this:Hide()
    end
         
end