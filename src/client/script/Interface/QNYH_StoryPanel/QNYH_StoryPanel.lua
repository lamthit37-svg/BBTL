local QNYH_StoryPanel_UnifiedPosition = nil

function QNYH_StoryPanel_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
	this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
end

function QNYH_StoryPanel_OnLoad()

	QNYH_StoryPanel_UnifiedPosition = QNYH_StoryPanel_Frame:GetProperty("UnifiedPosition")
	QNYH_StoryPanel_DragTitle:SetText("#{QXPVE_250701_9}")
	QNYH_StoryPanel_Mini_PageHeader:SetText("#{QXPVE_250701_9}")
	QNYH_StoryPanel_Text:SetText("#{QXPVE_250701_10}")

end

function QNYH_StoryPanel_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 5123601 then
		QNYH_StoryPanel_big()
		this:Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		if GetSceneID() ~= 1038 then
			QNYH_StoryPanel_Hide()
		end

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		QNYH_StoryPanel_UnifiedPos()
	elseif (event == "ADJEST_UI_POS") then
		QNYH_StoryPanel_UnifiedPos()
	end
end

function QNYH_StoryPanel_small()
    QNYH_StoryPanel_Mini_Frame:Show()
	QNYH_StoryPanel_Client:Hide()
end


function QNYH_StoryPanel_big()
    QNYH_StoryPanel_Client:Show()
	QNYH_StoryPanel_Mini_Frame:Hide()
end

function QNYH_StoryPanel_Hide()
    this:Hide()
end

-- 界面默认位置
function QNYH_StoryPanel_UnifiedPos()
	if (QNYH_StoryPanel_UnifiedPosition ~= nil) then
		QNYH_StoryPanel_Frame:SetProperty("UnifiedPosition", QNYH_StoryPanel_UnifiedPosition)
	end
end
