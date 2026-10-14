local g_Dahua_Incom_PreviewFrame_UnifiedPosition   
--=========
-- PreLoad()
--=========
function Dahua_Incom_Preview_PreLoad()
	this:RegisterEvent("OPEN_DAHUA_PREVIEW", true)--打开or刷新界面
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false) 
end

--=========
-- OnLoad()
--=========
function Dahua_Incom_Preview_OnLoad() 
	g_Dahua_Incom_PreviewFrame_UnifiedPosition = Dahua_Incom_Preview_Frame:GetProperty("UnifiedPosition") 
end

--=========
-- Event
--=========
function Dahua_Incom_Preview_OnEvent(event)

    if(event == "OPEN_DAHUA_PREVIEW") then	 
        if not this:IsVisible() then 
            this:Hide()
        end
		local idx = tonumber(arg0)  
		Dahua_Incom_Preview_Image:SetProperty("Image", tostring(arg1))
		this:Show()
	elseif event == "HIDE_ON_SCENE_TRANSED" then

		Dahua_Incom_Preview_Close()

	elseif event == "VIEW_RESOLUTION_CHANGED" then
	
		Dahua_Incom_Preview_On_ResetPos()

	elseif event == "ADJEST_UI_POS" then

        Dahua_Incom_Preview_On_ResetPos()
        		 
	end

end

function Dahua_Incom_Preview_Close()  
	this:Hide()
end

--=========
-- 重置
--=========
function Dahua_Incom_Preview_On_ResetPos()

	Dahua_Incom_Preview_Frame:SetProperty("UnifiedPosition", g_Dahua_Incom_PreviewFrame_UnifiedPosition)

end
  