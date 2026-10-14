local g_AnniversaryGiftShow_UnifiedPosition;
function AnniversaryGiftShow_PreLoad()
	this:RegisterEvent("UI_COMMAND");   
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面  
end

function AnniversaryGiftShow_OnLoad() 
	g_AnniversaryGiftShow_UnifiedPosition=AnniversaryGiftShow_Frame_BK:GetProperty("UnifiedPosition")
	
end

function AnniversaryGiftShow_OnEvent(event)
	if (event == "UI_COMMAND") then
		if(tonumber(arg0) == 89308301 ) then
			this:Show()
		end 
	end	   
	
	if (event == "ADJEST_UI_POS") then
		AnniversaryGiftShow_On_ResetPos()
		return
	end
	
	if (event == "VIEW_RESOLUTION_CHANGED") then
		AnniversaryGiftShow_On_ResetPos()
		return
	end

	if event == "VIEW_RESOLUTION_CHANGED" then 
		AnniversaryGiftShow_On_ResetPos()
		return
	end
	
	if event == "HIDE_ON_SCENE_TRANSED" then 
		AnniversaryGiftShow_OnHide()
		return
	end 

end

function AnniversaryGiftShow_On_ResetPos()
  	AnniversaryGiftShow_Frame_BK:SetProperty("UnifiedPosition", g_AnniversaryGiftShow_UnifiedPosition);
end

function AnniversaryGiftShow_OnHide() 
	this:Hide()
end

