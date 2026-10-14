----------------------
-- GuiGu_YuGao_01 ---

--===============================================
-- PreLoad()
--===============================================
function GuiGu_YuGao_01_PreLoad()

	this:RegisterEvent("UI_COMMAND")
	
end

--===============================================
-- OnLoad()
--===============================================
function GuiGu_YuGao_01_OnLoad()
	
end

--===============================================
-- OnEvent()
--===============================================
function GuiGu_YuGao_01_OnEvent(event)
	if (event  == "UI_COMMAND") and (tonumber(arg0) == 2016101109) then
		this:Show()
	end
end


--===============================================
-- Close()
--===============================================
function GuiGu_YuGao_01_Close()

	return this:Hide()
end