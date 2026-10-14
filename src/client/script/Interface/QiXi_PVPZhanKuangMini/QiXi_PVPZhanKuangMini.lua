-- 保存UI默认位置
local QiXi_PVPZhanKuangMini_Frame_UnifiedPosition = nil

function QiXi_PVPZhanKuangMini_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("QXPVP_SMALL",true)     -- 窗口分辨率发生变化

end -- end func QiXi_PVPZhanKuangMini_Frame_PreLoad()

function QiXi_PVPZhanKuangMini_OnLoad()
    QiXi_PVPZhanKuangMini_Frame_UnifiedPosition = QiXi_PVPZhanKuangMini_Frame:GetProperty("UnifiedPosition")
end -- end func QiXi_PVPZhanKuangMini_Frame_OnLoad()

function QiXi_PVPZhanKuangMini_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        QiXi_PVPZhanKuangMini_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        QiXi_PVPZhanKuangMini_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        QiXi_PVPZhanKuangMini_Frame_UnifiedPos()
		
	elseif (event == "QXPVP_SMALL") then
		this:Show()
	end
end -- end func QiXi_PVPZhanKuangMini_Frame_OnEvent()

-- 界面默认位置
function QiXi_PVPZhanKuangMini_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (QiXi_PVPZhanKuangMini_Frame_UnifiedPosition ~= nil) then
            QiXi_PVPZhanKuangMini_Frame:SetProperty("UnifiedPosition", QiXi_PVPZhanKuangMini_Frame_UnifiedPosition)
        end
    end
end -- end func QiXi_PVPZhanKuangMini_Frame_UnifiedPos()

function QiXi_PVPZhanKuangMini_Frame_Hide()
    this:Hide()
end -- end func QiXi_PVPZhanKuangMini_Frame_Hide()



function QiXi_PVPZhanKuangMini_Open()
	
	QiXi_PVPZhanKuangMini_Frame_Hide()
	PushEvent("QXPVP_BIG")
   
end -- end func QiXi_PVPZhanKuangMini_Open()

