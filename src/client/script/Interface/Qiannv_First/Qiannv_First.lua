--Qiannv_First.lua
local Qiannv_First_UnifiedPosition


function Qiannv_First_PreLoad()
	--第二个参数表示界面关闭时是否响应事件 默认为TRUE
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("ON_SCENE_TRANSING", false)
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
end

function Qiannv_First_OnLoad()
	Qiannv_First_UnifiedPosition = Qiannv_First:GetProperty("UnifiedPosition")
end

function Qiannv_First_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 30014101) then
		Qiannv_First_Mini:Hide()
		Qiannv_First_Big:Show()
		this:Show()
	elseif event == "ON_SCENE_TRANSING" then --客户端开始切换场景
		this:Hide()
	elseif event == "PLAYER_LEAVE_WORLD" then
		this:Hide()
	elseif (event == "ADJEST_UI_POS") then
		Qiannv_First_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Qiannv_First_On_ResetPos()
	end
end

--最小化按钮
function Qiannv_First_OpenMini()
	Qiannv_First_Mini:Show()
	Qiannv_First_Big:Hide()
end

--最大化按钮
function Qiannv_First_Mini_OnShowNormalUI()
	Qiannv_First_Mini:Hide()
	Qiannv_First_Big:Show()
end

--关闭
function Qiannv_First_OnClose()
	this:Hide()
end

function Qiannv_First_On_ResetPos()
	Qiannv_First:SetProperty("UnifiedPosition", Qiannv_First_UnifiedPosition)
end
