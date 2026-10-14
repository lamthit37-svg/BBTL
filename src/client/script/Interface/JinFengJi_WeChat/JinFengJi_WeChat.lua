local g_Frame_UnifiedPosition


--=========
-- PreLoad()
--=========
function JinFengJi_WeChat_PreLoad()

	this:RegisterEvent("2020JQ_YUNYING", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)

end

--=========
-- OnLoad()
--=========
function JinFengJi_WeChat_OnLoad()

	
	g_Frame_UnifiedPosition = JinFengJi_WeChat_Frame:GetProperty("UnifiedPosition")

end

--=========
-- Event
--=========
function JinFengJi_WeChat_OnEvent(event)

	if(event == "2020JQ_YUNYING") then
	
		JinFengJi_WeChat_Open()
		
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		JinFengJi_WeChat_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		JinFengJi_WeChat_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

		JinFengJi_WeChat_On_ResetPos()


	end

end

function JinFengJi_WeChat_Close()
	this:Hide()
end

--=========
-- 重置
--=========
function JinFengJi_WeChat_On_ResetPos()

	JinFengJi_WeChat_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)

end





--=========
-- 问号帮助
--=========
function JinFengJi_WeChat_Help_Clicked()
	
end




--=========
-- 填充活动奖励界面
--=========
function JinFengJi_WeChat_Open()

	this:Show()
end