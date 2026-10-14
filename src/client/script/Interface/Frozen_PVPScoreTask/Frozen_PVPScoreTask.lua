-- 界面最小化

local g_unifiedposistion = nil
local g_ui_list_progress = {}
local g_flag = {}
local g_missioninfo = {
	[1] = {flag=4, str="#{BXDZ_240918_361}",max=3,},
	[2] = {flag=3, str="#{BXDZ_240918_362}",max=10,},
	[3] = {flag=2, str="#{BXDZ_240918_363}",max=5,},
	[4] = {flag=1, str="#{BXDZ_240918_364}",max=5,},
}
local g_flagmax = 4
local g_mission_max = 2
function Frozen_PVPScoreTask_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("XRZPVP_BATTLERESULT_SHOW",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Frozen_PVPScoreTask_OnLoad()
	g_ui_list_progress = {
		Frozen_PVPScoreTask_Text1_2,
		Frozen_PVPScoreTask_Text2_2,
		Frozen_PVPScoreTask_Text3_2,
		Frozen_PVPScoreTask_Text4_2,
	}

	g_unifiedposistion = Frozen_PVPScoreTask_Frame:GetProperty("UnifiedPosition")
end

function Frozen_PVPScoreTask_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 80030605 ) then
		Frozen_PVPScoreTask_OnShow()
	elseif ( event == "ADJEST_UI_POS" ) then
		Frozen_PVPScoreTask_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		Frozen_PVPScoreTask_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		Frozen_PVPScoreTask_CloseClicked()
	elseif(event == "XRZPVP_BATTLERESULT_SHOW") then
		Frozen_PVPScoreTask_CloseClicked()
	end

end

function Frozen_PVPScoreTask_OnShow()

	g_flag = {}
	for i=1, g_flagmax do
		g_flag[i] = Get_XParam_INT(i-1)
	end
	local isShow = Get_XParam_INT(g_flagmax)

	local progress = 0
	for i=1, g_flagmax do
		local uiprogress = g_ui_list_progress[i]
		local data = g_missioninfo[i]
		if uiprogress ~= nil and data ~= nil then
			local num = g_flag[data.flag]
			if num ~= nil then
				if num >= data.max then
					num = data.max
					progress = progress + 1
				end
						
				local str = ScriptGlobal_Format("#{BXDZ_240918_357}", num, data.max)
				uiprogress:SetText(str)
			end
		end
	end

	if progress >= g_mission_max then
		progress = g_mission_max
	end

	local str = ScriptGlobal_Format("#{BXDZ_240918_358}", progress, g_mission_max)
	Frozen_PVPScoreTask_Text5:SetText(str)

	if isShow > 0 then
		Frozen_PVPScoreTask_Frame:SetForce()
		this:Show()
	end
end

--================================================
-- 关闭
--================================================
function Frozen_PVPScoreTask_OnClose()
	this:Hide()
end

function Frozen_PVPScoreTask_Mini()
	this:Hide()
end

--================================================
-- 关闭
--================================================
function Frozen_PVPScoreTask_CloseClicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_PVPScoreTask_ResetPos()
	if g_unifiedposistion ~= nil then
		Frozen_PVPScoreTask_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
	end
end