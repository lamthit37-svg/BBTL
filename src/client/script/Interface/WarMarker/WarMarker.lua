-- 选人界面
local g_unifiedposistion
local g_select = 0
local g_type = 0
local g_sceneId = -1

local g_ui_list = {}
local g_op_type = {
	[1] = {
		opBegin = 1,
		opEnd = 4,
	},
	[2] = {
		opBegin = 1,
		opEnd = 4,
	},
}

local g_CommanderLevel =
{
    invaild = 0,
    raid = 1,
	guild = 2,
	all = 3,
}
local g_commander_type =
{
    raid = 1,
    guild = 2,
}

local g_ui_command = 99969901
local g_ui_commandsec = 99969902
local g_objCared = -1
function WarMarker_PreLoad()
	this:RegisterEvent("COMMANDERFLAG_SHOW")
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("COMMANDERFLAG_ADD",false)
	this:RegisterEvent("COMMANDERFLAG_CLOSE",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function WarMarker_OnLoad()

	g_ui_list = {
		WarMarker_Client_2,
		WarMarker_Client_3,
		WarMarker_Client_1,
	}

	-- 保存界面的默认相对位置
	g_unifiedposistion = WarMarker_Frame:GetProperty("UnifiedPosition")
end

function WarMarker_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == g_ui_command then		
		g_objCared = Get_XParam_INT( 0 )
		Guild:AskGuildCommanderMemberInfo()
	elseif event == "UI_COMMAND" and tonumber(arg0) == g_ui_commandsec then
		WarMarker_RaidCommanderOpSuccess()
	elseif (event == "COMMANDERFLAG_SHOW") then
		WarMarker_OnShow(tonumber(arg0))
	elseif (event == "COMMANDERFLAG_CLOSE") then
		WarMarker_CloseClicked()
	elseif ( event == "ADJEST_UI_POS" ) then
		WarMarker_ResetPos()
	elseif ( event == "VIEW_RESOLUTION_CHANGED" ) then
		WarMarker_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED")	 then
		WarMarker_CloseClicked()
	elseif(event == "COMMANDERFLAG_ADD") then
		WarMarker_AddCommanderFlag(tonumber(arg0), tonumber(arg1), tonumber(arg2))
	end
end

function WarMarker_OnShow(selectScnId)
	local level = CommanderFlag:GetCommanderLevel()
	if level <= 0 then
		this:Hide()
		return
	end

	-- 如果只是团队标记，只能在当前场景生效
	if level == g_CommanderLevel.raid then
		local curSceneID = GetSceneID()
		if selectScnId ~= curSceneID then
			this:Hide()
			return
		end
	end
	if g_objCared >= 0 then
		local npcClientId = DataPool : GetNPCIDByServerID( g_objCared )
		if npcClientId ~= -1 then
			this:CareObject( npcClientId, 1, "WarMarker" )
		end
	end
	g_sceneId = selectScnId

	for _, ui in (g_ui_list or {}) do
		ui:Hide()
	end

	local uiIndex = level
	if level == g_CommanderLevel.all then
		local curSceneID = GetSceneID()
		if selectScnId ~= curSceneID then
			level = g_CommanderLevel.guild
		end
	end

	local clientUI = g_ui_list[level]
	if clientUI ~= nil then
		clientUI:Show()
	end
	
	this:Show()

	WarMarker_Frame:SetForce()
end

function WarMarker_Click(flagType, index)

	local opData = g_op_type[flagType]
	if opData == nil then
		return
	end
	if index < opData.opBegin or index > opData.opEnd then
		return
	end

	local isAdd = CommanderFlag:IsEnterAddFlag()
	if isAdd > 0 then
		--return
	end

	if flagType == g_commander_type.raid then
		local curSceneID = GetSceneID()
		if g_sceneId ~= curSceneID then
			PushDebugMessage("团队标识只能在当前场景插，缺字典")
			return
		end
	end


	g_select = index
	g_type = flagType

	-- 激活进入操作状态
	CommanderFlag:EnterAddFlag()

	--PushDebugMessage("flagType="..flagType.." index="..index)
end

function WarMarker_AddCommanderFlag(sceneId, posX, posZ)
	local index = g_select
	local flagType = g_type
	local opData = g_op_type[flagType]
	if opData == nil then
		return
	end
	if index < opData.opBegin or index > opData.opEnd then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnPlayerTryAddCommanderFlag")
		Set_XSCRIPT_ScriptID(999699)
		Set_XSCRIPT_Parameter(0, flagType)
		Set_XSCRIPT_Parameter(1, index)
		Set_XSCRIPT_Parameter(2, sceneId)
		Set_XSCRIPT_Parameter(3, posX)
		Set_XSCRIPT_Parameter(4, posZ)
		Set_XSCRIPT_ParamCount(5)
	Send_XSCRIPT()
end

function WarMarker_Cancel_Click(flagType, index)
	local opData = g_op_type[flagType]
	if opData == nil then
		return
	end
	if index < opData.opBegin or index > opData.opEnd then
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OnPlayerTryCancelCommanderFlag")
		Set_XSCRIPT_ScriptID(999699)
		Set_XSCRIPT_Parameter(0, flagType)
		Set_XSCRIPT_Parameter(1, index)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()

	CommanderFlag:LeaveAddFlag()
end

--================================================
-- 关闭
--================================================
function WarMarker_RaidCommanderOpSuccess()
end

--================================================
-- 关闭
--================================================
function WarMarker_CloseClicked()
	this:Hide()
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function WarMarker_ResetPos()
	WarMarker_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function WarMarker_OnHide()
	g_select = 0
	g_type = 0
	selectScnId = -1
	CommanderFlag:LeaveAddFlag()
	if g_objCared >= 0 then
		local npcClientId = DataPool : GetNPCIDByServerID( g_objCared )
		if npcClientId ~= -1 then
			this : CareObject( npcClientId, 0, "WarMarker")
		end
		g_objCared = -1
	end
end