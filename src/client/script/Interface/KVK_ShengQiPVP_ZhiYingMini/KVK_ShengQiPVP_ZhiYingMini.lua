
local g_Frame_UnifiedPosition;

local g_YaoTaStr =
{
	[1] = "#{JXPVP_170814_110}",
	[2] = "#{JXPVP_170814_111}",
	[3] = "#{JXPVP_170814_112}",
	[4] = "#{JXPVP_170814_113}",
	[5] = "#{JXPVP_170814_114}",
	[6] = "#{JXPVP_170814_115}",
	[7] = "#{JXPVP_170814_116}",
	[8] = "#{JXPVP_170814_117}",
	[9] = "#{JXPVP_170814_118}",
};


function KVK_ShengQiPVP_ZhiYingMini_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	
	this:RegisterEvent("SHENQIPVP_ZHIYIN_OPNE")	
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	
end

--=========
--OnLoad
--=========
function KVK_ShengQiPVP_ZhiYingMini_OnLoad()
	
	g_Frame_UnifiedPosition = KVK_ShengQiPVP_ZhiYingMini_Frame:GetProperty("UnifiedPosition")
	
end
--=========
--OnEvent
--=========
function KVK_ShengQiPVP_ZhiYingMini_OnEvent(event)
	
	if event == "UI_COMMAND" and tonumber(arg0) == 20170926 then
		this:Show()
		return
	elseif ( event == "HIDE_ON_SCENE_TRANSED") then
		this:Hide()
		return		
	elseif ( event == "SHENQIPVP_ZHIYIN_OPNE") then			
		if tonumber(arg0) == 0 then
			local nType = tonumber(arg1)
			local nCeng = tonumber(arg2)
			if nType == 0 then
				KVK_ShengQiPVP_ZhiYingMini_PageHeader:SetText(g_YaoTaStr[nCeng]) 
			else
				KVK_ShengQiPVP_ZhiYingMini_PageHeader:SetText("#{JXPVP_170814_105}") 
			end
			
			this:Show()
		else
			this:Hide()
		end		
	elseif (event == "ADJEST_UI_POS" ) then
		KVK_ShengQiPVP_ZhiYingMini_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		KVK_ShengQiPVP_ZhiYingMini_ResetPos()			
	end
	
end


function KVK_ShengQiPVP_ZhiYingMini_Cliecked()
	PushEvent("SHENQIPVP_ZHIYIN_OPNE",  1 )
end

function KVK_ShengQiPVP_ZhiYingMini_ResetPos()
	KVK_ShengQiPVP_ZhiYingMini_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition);
end
