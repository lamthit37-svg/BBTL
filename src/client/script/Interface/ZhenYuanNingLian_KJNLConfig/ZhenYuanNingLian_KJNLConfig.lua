--**************************
--真元快捷一键凝炼选项
--**************************
local g_QuikNiangLian_JC={
250,500,2500,5000
}
local g_QuikNiangLian_Sel=1
local g_QuikNiangLian_Sav=1

local g_ZYNL_KJNL_Frame_UnifiedPosition
local ZYNL_CHECKBTN={}
local g_targetId=-1
--===============================================
-- OnLoad()
--===============================================
function ZhenYuanNingLian_KJNLConfig_PreLoad()
	this:RegisterEvent("OPEN_ONE_PARAM_WINDOW")
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--===============================================
-- OnLoad()
--===============================================
function ZhenYuanNingLian_KJNLConfig_OnLoad()
	g_ZYNL_KJNL_Frame_UnifiedPosition=ZhenYuanNingLian_KJNLConfig_Frame:GetProperty("UnifiedPosition");
	ZYNL_CHECKBTN={
	ZhenYuanNingLian_ConfigClient1_QR1,ZhenYuanNingLian_ConfigClient1_QR2,ZhenYuanNingLian_ConfigClient1_QR3
	}
end

--===============================================
-- OnEvent()
--===============================================
function ZhenYuanNingLian_KJNLConfig_OnEvent(event)
	if (event == "OPEN_ONE_PARAM_WINDOW" and tostring(arg0)=="ZhenYuanNingLian_KJNLConfig") then
		g_targetId=tonumber(arg1)
		if g_targetId == -1 then
			return
		end
		if this:IsVisible() then
			this:Hide()
		else
			ZhenYuanNingLian_KJNLConfig_Update()
			ZYNL_KJNLConfig_BeginCareObject()
			this:Show()
		end
	elseif (event == "ADJEST_UI_POS" ) then
		ZhenYuanNingLian_KJNLConfig_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		ZhenYuanNingLian_KJNLConfig_ResetPos()
	end
end

function ZhenYuanNingLian_KJNLConfig_ResetPos()
	ZhenYuanNingLian_KJNLConfig_Frame:SetProperty("UnifiedPosition", g_ZYNL_KJNL_Frame_UnifiedPosition);
end
function ZhenYuanNingLian_KJNLConfig_Update()
	for i=1,3 do
		if i==g_QuikNiangLian_Sav then
			ZYNL_CHECKBTN[i]:SetCheck(1)
		else
			ZYNL_CHECKBTN[i]:SetCheck(0)
		end
	end
end

function ZhenYuanNingLian_KJNLConfig_OKClk()
	OpenOneParamWindow("ZhenYuanNingLian",g_QuikNiangLian_Sel)
	g_QuikNiangLian_Sav=g_QuikNiangLian_Sel
	ZYNL_KJNLConfig_StopCareObject()
	this:Hide()
end

function ZhenYuanNingLian_KJNLConfig_CloseClk()
	ZYNL_KJNLConfig_StopCareObject()
	this:Hide()
end

function ZYNL_KJNLConfig_SetCheck(selIndex)
	if (g_QuikNiangLian_JC[selIndex]~=nil) then
		g_QuikNiangLian_Sel=selIndex
	end
end

function ZYNL_KJNLConfig_BeginCareObject()
	this:CareObject(g_targetId, 1, "ZhenYuanNingLian_KJNLConfig")
end

function ZYNL_KJNLConfig_StopCareObject()
	this:CareObject(g_targetId, 0, "ZhenYuanNingLian_KJNLConfig")
end
