-- bxjgecaoinfodie


-- 保存UI默认位置
local Frozen_GeCao_Fail_Frame_UnifiedPosition = nil



function Frozen_GeCao_Fail_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")

end -- end func Frozen_GeCao_Fail_Frame_PreLoad()

function Frozen_GeCao_Fail_OnLoad()
    Frozen_GeCao_Fail_Frame_UnifiedPosition = Frozen_GeCao_Fail_Frame:GetProperty("UnifiedPosition")
	
	
	
end -- end func Frozen_GeCao_Fail_Frame_OnLoad()

function Frozen_GeCao_Fail_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        Frozen_GeCao_Fail_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        Frozen_GeCao_Fail_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        Frozen_GeCao_Fail_Frame_UnifiedPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331141006) then	--服务端传数据
	
		local str = Get_XParam_STR(0)	
		Frozen_GeCao_Fail_Info:SetText(str)
		
		this:Show()
	end
end -- end func Frozen_GeCao_Fail_Frame_OnEvent()




-- 界面默认位置
function Frozen_GeCao_Fail_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (Frozen_GeCao_Fail_Frame_UnifiedPosition ~= nil) then
            Frozen_GeCao_Fail_Frame:SetProperty("UnifiedPosition", Frozen_GeCao_Fail_Frame_UnifiedPosition)
        end
    end
end -- end func Frozen_GeCao_Fail_Frame_UnifiedPos()

function Frozen_GeCao_Fail_Frame_Hide()
    this:Hide()
end -- end func Frozen_GeCao_Fail_Frame_Hide()

-- 关闭按钮点击事件
function Frozen_GeCao_Fail_Frame_Close_Clicked()
	Frozen_GeCao_Fail_Frame_Hide()
end  -- end func Frozen_GeCao_Fail_Frame_Close_Clicked()

function Frozen_GeCao_Fail_Help_Clicked()
    PushEvent("CCSHOP_HELP", 223)
end -- end func Frozen_GeCao_Fail_Frame_Help()

