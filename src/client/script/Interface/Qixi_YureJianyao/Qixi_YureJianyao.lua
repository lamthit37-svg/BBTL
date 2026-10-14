
local g_Qixi_YureJianyao_Frame_UnifiedPosition

function Qixi_YureJianyao_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
	this:RegisterEvent("ADJEST_UI_POS",false)
end

function Qixi_YureJianyao_OnLoad()
	g_Qixi_YureJianyao_Frame_UnifiedPosition = Qixi_YureJianyao_Frame:GetProperty("UnifiedPosition")
end

function Qixi_YureJianyao_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 2026062203 then
		local isOpen = Get_XParam_INT(0)
		if isOpen == 1 then
			this:Show()
			-- Qixi_YureJianyao_Animate:Play(false)
			-- Qixi_YureJianyao_Animate:Hide()
		else
			this:Hide()
			-- KillTimer("Qixi_YureJianyao_Success()")
			-- Qixi_YureJianyao_Animate:Show()
			-- Qixi_YureJianyao_Animate:Play(true)
			-- SetTimer("Qixi_YureJianyao","Qixi_YureJianyao_Success()", 3000)
		end	
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		Qixi_YureJianyao_On_ResetPos()
	elseif event == "ADJEST_UI_POS" then
		Qixi_YureJianyao_On_ResetPos()
	elseif event == "HIDE_ON_SCENE_TRANSED" then
		Qixi_YureJianyao_Close()
	end
end

-- function Qixi_YureJianyao_Success()
-- 	KillTimer("Qixi_YureJianyao_Success()")
-- 	Qixi_YureJianyao_Animate:Play(false)
-- 	Qixi_YureJianyao_Animate:Hide()
-- 	this:Hide()
-- end


function Qixi_YureJianyao_On_ResetPos()
	Qixi_YureJianyao_Frame:SetProperty("UnifiedPosition", g_Qixi_YureJianyao_Frame_UnifiedPosition)
end

function Qixi_YureJianyao_OnHidden()
	--KillTimer("Qixi_YureJianyao_Success()")
end

function Qixi_YureJianyao_Close()
end

