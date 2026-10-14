-- bxjgecaoinfodie


-- 保存UI默认位置
local Frozen_Dance_Result2_Frame_UnifiedPosition = nil



function Frozen_Dance_Result2_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")

end -- end func Frozen_Dance_Result2_Frame_PreLoad()

function Frozen_Dance_Result2_OnLoad()
    Frozen_Dance_Result2_Frame_UnifiedPosition = Frozen_Dance_Result2_Frame:GetProperty("UnifiedPosition")
	
	
	
end -- end func Frozen_Dance_Result2_Frame_OnLoad()

function Frozen_Dance_Result2_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        Frozen_Dance_Result2_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        Frozen_Dance_Result2_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        Frozen_Dance_Result2_Frame_UnifiedPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331180009) then	--服务端传数据
	
		local str = Get_XParam_STR(0)	
		local index = Get_XParam_INT(0)
		--Frozen_Dance_Result2_Info:SetText(str)
		if index == 1 then
			Frozen_Dance_Result2_InfoBK:SetProperty("Image", "set:Frozen_Dance2 image:Frozen_Dance2_TouBK")
		elseif index == 2 then
			Frozen_Dance_Result2_InfoBK:SetProperty("Image", "set:Frozen_Dance2 image:Frozen_Dance2_ZhuaBK")
		elseif index == 3 then
			Frozen_Dance_Result2_InfoBK:SetProperty("Image", "set:Frozen_Dance2 image:Frozen_Dance2_PingBK")
		end
		this:Show()
	end
end -- end func Frozen_Dance_Result2_Frame_OnEvent()




-- 界面默认位置
function Frozen_Dance_Result2_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (Frozen_Dance_Result2_Frame_UnifiedPosition ~= nil) then
            Frozen_Dance_Result2_Frame:SetProperty("UnifiedPosition", Frozen_Dance_Result2_Frame_UnifiedPosition)
        end
    end
end -- end func Frozen_Dance_Result2_Frame_UnifiedPos()

function Frozen_Dance_Result2_Frame_Hide()
    this:Hide()
end -- end func Frozen_Dance_Result2_Frame_Hide()

-- 关闭按钮点击事件
function Frozen_Dance_Result2_Frame_Close_Clicked()
	Frozen_Dance_Result2_Frame_Hide()
end  -- end func Frozen_Dance_Result2_Frame_Close_Clicked()

function Frozen_Dance_Result2_Help_Clicked()
    PushEvent("CCSHOP_HELP", 32)
end -- end func Frozen_Dance_Result2_Frame_Help()

