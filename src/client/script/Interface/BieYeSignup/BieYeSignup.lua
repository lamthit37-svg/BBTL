
local g_styleBtns = {}
local g_edgeBtns = {}

local g_select = -1
local g_ServerTargetId = -1
local g_CaredObjectId = -1

function BieYeSignup_PreLoad()
	this:RegisterEvent("UI_COMMAND")
end
	
function BieYeSignup_OnLoad()
	for i = 1,4 do
		g_styleBtns[i] = _G["BieYeSignup_NeedItem"..i]
		g_edgeBtns[i] = _G["BieYeSignup_NeedItem"..i.."_SelectButton"]
	end
end										


function BieYeSignup_OnEvent(event)
	if event  == "UI_COMMAND" and tonumber(arg0) == 89187701 then
		BieYeSignup_BeginCareObject(Get_XParam_INT(0))
		BieYeSignup_Show()
	end
end

function BieYeSignup_BeginCareObject( serverId )
	BieYeSignup_StopCareObject()
	local clientId = DataPool:GetNPCIDByServerID(serverId)
	if clientId == -1 then
		return 0
	end
	this:CareObject( clientId, 1, "BieYeSignup" )
	g_ServerTargetId = serverId
	g_CaredObjectId = clientId
end

function BieYeSignup_StopCareObject()
	if g_CaredObjectId ~= -1 then
		this:CareObject(g_CaredObjectId, 0, "BieYeSignup")
		g_CaredObjectId = -1
	end
	g_ServerTargetId = -1
end

function BieYeSignup_OnHide()
	for i=1, table.getn(g_edgeBtns) do
		g_edgeBtns[i]:SetCheck(0)
	end
	g_select = -1
	BieYeSignup_StopCareObject()
end

function BieYeSignup_OnClose()
	this:Hide()
end

function BieYeSignup_Show()
	this:Show()
end

function BieYeSignup_Ok()
	if g_select < 1 or g_select > 4 then
		PushDebugMessage("#{BYRACE_170214_36}")
		return
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ClientSignUp")
		Set_XSCRIPT_ScriptID(891877)
		Set_XSCRIPT_Parameter(0, g_ServerTargetId)
		Set_XSCRIPT_Parameter(1, g_select)
		Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	BieYeSignup_OnClose()
end

function BieYeSignup_OnSelect(n)
	for i=1, table.getn(g_edgeBtns) do
		g_edgeBtns[i]:SetCheck(0)
	end
	g_edgeBtns[n]:SetCheck(1)
	g_select = n
end
