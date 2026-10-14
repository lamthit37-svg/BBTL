-- 界面最小化

local g_unifiedposistion = nil
local g_select = 1
local g_unlock = 0
local g_targetId = -1

local g_lockselect = 1
function Frozen_PVPXuanRen_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function Frozen_PVPXuanRen_OnLoad()
	g_unifiedposistion = Frozen_PVPXuanRen_Frame:GetProperty("UnifiedPosition")
end

function Frozen_PVPXuanRen_OnEvent(event)

	if ( event == "UI_COMMAND" and tonumber(arg0) == 80030701 ) then
		Frozen_PVPXuanRen_OnShow()
	elseif ( event == "ADJEST_UI_POS" ) then
		Frozen_PVPXuanRen_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		Frozen_PVPXuanRen_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		Frozen_PVPXuanRen_CloseClicked()
	end

end

function Frozen_PVPXuanRen_OnShow()

	g_unlock = Get_XParam_INT(0)
	g_select = Get_XParam_INT(1)
	g_targetId = Get_XParam_INT(2)
	
	if g_unlock > 0 then
		Frozen_PVPXuanRen_Img_2BK:Hide()
	else
		Frozen_PVPXuanRen_Img_2BK:Show()
	end

	Frozen_PVPXuanRen_Img_1Btn:SetCheck(0)
	Frozen_PVPXuanRen_Img_2Btn:SetCheck(0)
	if g_select == g_lockselect then
		Frozen_PVPXuanRen_Img_2Btn:SetCheck(1)
	else
		Frozen_PVPXuanRen_Img_1Btn:SetCheck(1)
	end

	this:Show()

end

--================================================
-- 关闭
--================================================
function Frozen_PVPXuanRen_OnClose()
	this:Hide()
end

function Frozen_PVPXuanRen_Close()
	this:Hide()
end

--================================================
-- 关闭
--================================================
function Frozen_PVPXuanRen_CloseClicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function Frozen_PVPXuanRen_ResetPos()
	if g_unifiedposistion ~= nil then
		Frozen_PVPXuanRen_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
	end
end

function Frozen_PVPXuanRen_Img_1Btn_Click(index)
	if index == g_lockselect then
		if g_unlock < 1 then
			Frozen_PVPXuanRen_Img_1Btn:SetCheck(1)
			Frozen_PVPXuanRen_Img_2Btn:SetCheck(0)
			PushDebugMessage("#{BXDZ_240918_146}")
			return
		end
	end

	if g_select == index then
		Frozen_PVPXuanRen_Img_1Btn:SetCheck(0)
		Frozen_PVPXuanRen_Img_2Btn:SetCheck(0)
		if g_select == g_lockselect then
			Frozen_PVPXuanRen_Img_2Btn:SetCheck(1)
		else
			Frozen_PVPXuanRen_Img_1Btn:SetCheck(1)
		end
		PushDebugMessage("#{BXDZ_240918_328}")

		return
	end

	g_select = index

	Frozen_PVPXuanRen_Img_1Btn:SetCheck(0)
	Frozen_PVPXuanRen_Img_2Btn:SetCheck(0)
	if g_select == g_lockselect then
		Frozen_PVPXuanRen_Img_2Btn:SetCheck(1)
	else
		Frozen_PVPXuanRen_Img_1Btn:SetCheck(1)
	end
end

function Frozen_PVPXuanRen_OK()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("TryChangeDressConfirm")
		Set_XSCRIPT_ScriptID(800307)
		Set_XSCRIPT_Parameter(0, g_targetId)
		Set_XSCRIPT_Parameter(1, g_select)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

	this:Hide()
end
