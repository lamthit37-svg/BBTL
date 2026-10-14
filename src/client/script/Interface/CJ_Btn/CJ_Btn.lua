
local g_unifiedposistion
local g_scene_res_ids ={
	[992] = 1,
	[1015] = 1,
}
local g_EnterCloseUI = {
	"ActionSkill",
	"CommonSkill",
	"ZhenfaSkill",
	"LifeSkill",
	"AutoAttackSkill",
	"ZongMenSkill",
}
function CJ_Btn_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("SCENE_TRANSED",false);
end

function CJ_Btn_OnLoad()	
	g_unifiedposistion = CJ_Btn_Frame:GetProperty("UnifiedPosition")
end

function CJ_Btn_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 99932105 then
		local opType =  Get_XParam_INT( 0 )
		this:Show()
		CJ_Btn_CloseUI()
	elseif event == "PLAYER_LEAVE_WORLD" then
		this:Hide()
	elseif event == "ADJEST_UI_POS" then
		CJ_Btn_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		CJ_Btn_ResetPos()
	elseif event == "SCENE_TRANSED" then
		if not g_scene_res_ids[GetSceneID()] then
			this:Hide()
		end
	end
end

function CJ_Btn_ResetPos()
	CJ_Btn_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function CJ_Btn_ZhengHeButton_Clicked()
	if(IsWindowShow("CJ_Backpack")) then
		CloseWindow("CJ_Backpack", true)
		return 
	end
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenPlayerInfo" )
		Set_XSCRIPT_ScriptID(999340)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function CJ_Btn_DaoJuBtn_Clicked()
	if(IsWindowShow("CJ_DaoJuBag")) then
		CloseWindow("CJ_DaoJuBag", true)
		return 
	end
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name( "OpenItemBag" )
		Set_XSCRIPT_ScriptID(999340)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function CJ_Btn_CloseUI()
	for  i,windowName in pairs(g_EnterCloseUI) do
		if(IsWindowShow(windowName)) then
			CloseWindow(windowName, true)
		end
	end
end
