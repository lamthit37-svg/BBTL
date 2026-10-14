-- 2020q4汴京氛围界面

local g_Frame_UnifiedPosition

--=========
-- PreLoad
--=========
function SpringFestival_BianJing_chess_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad
--=========
function SpringFestival_BianJing_chess_OnLoad()

	g_Frame_UnifiedPosition = SpringFestival_BianJing_chess_Frame:GetProperty("UnifiedPosition") 
	
end

--=========
-- OnEvent
--=========
function SpringFestival_BianJing_chess_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 80604501 then

		SpringFestival_BianJing_chess_Update()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		SpringFestival_BianJing_chess_On_ResetPos()
		
	elseif event == "ADJEST_UI_POS" then
	
		SpringFestival_BianJing_chess_On_ResetPos()

	end

end

--=========
-- 重置
--=========
function SpringFestival_BianJing_chess_On_ResetPos()

	SpringFestival_BianJing_chess_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--=========
-- 打开
--=========
function SpringFestival_BianJing_chess_Update()

	-- 显示
	this:Show()
	
end

--=========
-- 关闭
--=========
function SpringFestival_BianJing_chess_CloseClicked()
	this:Hide()
end

--=========
-- 隐藏
--=========
function SpringFestival_BianJing_chess_OnHidden()

end



