-- 总决赛GM比赛操作界面
--
local g_unifiedposistion
local g_ui_command_id	= 99857801
local g_op_script_id	= 998578

function ZBS_ZJSGMMatch_PreLoad()

	this:RegisterEvent("UI_COMMAND",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function ZBS_ZJSGMMatch_OnLoad()
	-- 保存界面的默认相对位置
	g_unifiedposistion	= ZBS_ZJSGMMatch_Frame:GetProperty("UnifiedPosition")

	ZBS_ZJSGMMatch_InitData()
end

function ZBS_ZJSGMMatch_OnEvent(event)
	if (event == "UI_COMMAND") and tonumber(arg0) == g_ui_command_id then
		ZBS_ZJSGMMatch_OnShow()
	elseif( event == "ADJEST_UI_POS" ) then
		ZBS_ZJSGMMatch_ResetPos()
	elseif( event == "VIEW_RESOLUTION_CHANGED") then
		ZBS_ZJSGMMatch_ResetPos()
	elseif( event == "HIDE_ON_SCENE_TRANSED" ) then
		this:Hide()
	end
end

function ZBS_ZJSGMMatch_InitData()
	ZBS_ZJSGMMatch_Input1:SetText("")
	ZBS_ZJSGMMatch_Input2:SetText("")
	ZBS_ZJSGMMatch_select:ResetList();
	ZBS_ZJSGMMatch_select:AddTextItem("", 0)
	ZBS_ZJSGMMatch_select:AddTextItem("#{ZBS_230606_61}", 1)
	ZBS_ZJSGMMatch_select:AddTextItem("#{ZBS_230606_62}", 2)
	ZBS_ZJSGMMatch_select:AddTextItem("#{ZBS_230606_63}", 3)
	ZBS_ZJSGMMatch_select:AddTextItem("#{ZBS_230606_64}", 4)
	ZBS_ZJSGMMatch_select:AddTextItem("#{ZBS_230606_65}", 5)
	ZBS_ZJSGMMatch_select:AddTextItem("#{ZBS_230606_66}", 6)
	ZBS_ZJSGMMatch_select:AddTextItem("#{ZBS_230606_67}", 7)
	ZBS_ZJSGMMatch_select:AddTextItem("#{ZBS_230606_68}", 8)
	ZBS_ZJSGMMatch_select:SetCurrentSelect(0)
	ZBS_ZJSGMMatch_Input1:SetProperty("DefaultEditBox", "True")
end

function ZBS_ZJSGMMatch_OnShow()
	ZBS_ZJSGMMatch_InitData()
	this:Show()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function ZBS_ZJSGMMatch_ResetPos()
	ZBS_ZJSGMMatch_Frame:SetProperty("UnifiedPosition",g_unifiedposistion)
end

function ZBS_ZJSGMMatch_Submit_Clicked()

	local nTeamA_ID = ZBS_ZJSGMMatch_Input1:GetText()
	local nTeamB_ID = ZBS_ZJSGMMatch_Input2:GetText()

	if nTeamA_ID == nil or nTeamB_ID == nil or nTeamA_ID == "" or nTeamB_ID == "" then
		PushDebugMessage("#{DFSZ_220905_15}")
		return
	end

	if tonumber(nTeamA_ID) == nil or tonumber(nTeamB_ID) == nil then
		PushDebugMessage("#{DFSZ_220905_16}")
		return
	end

	local __txt, idx = ZBS_ZJSGMMatch_select:GetCurrentSelect()
	if idx <= 0 then
		PushDebugMessage("#{DFSZ_220905_17}")
		return
	end

	--比赛场地、双方战队ID
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnSelectTwoTeamsToBattleField")
		Set_XSCRIPT_ScriptID(g_op_script_id)
		Set_XSCRIPT_Parameter(0,tonumber(nTeamA_ID))
		Set_XSCRIPT_Parameter(1,tonumber(nTeamB_ID))
		Set_XSCRIPT_Parameter(2,tonumber(idx))
		Set_XSCRIPT_ParamCount(3)
	Send_XSCRIPT()

	this:Hide()
end

function ZBS_ZJSGMMatch_Cancel_Clicked()
	ZBS_ZJSGMMatch_Input1:SetProperty("DefaultEditBox", "False")
	this:Hide()
end
