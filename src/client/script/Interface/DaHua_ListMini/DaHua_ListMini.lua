--!!!reloadscript =DaHua_ListMini
local g_unifiedposistion
local g_DaHua_ListMini_SceneId = 0
local g_DaHua_ListMini_opType = {
	close = 1000,					-- 关闭UI
}

local g_scene_res_ids={[1040]=1}


local g_curState = 0
local g_UI_items = {}
local g_FabaoNum = 2
local g_Fabao = {
	{item=39925014,cooldownId = 272},
	{item=39925015,cooldownId = 273}
}

function DaHua_ListMini_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("SCENE_TRANSED",false);
end

function DaHua_ListMini_OnLoad()	
	g_unifiedposistion = DaHua_ListMini_Frame:GetProperty("UnifiedPosition")
	g_UI_items.actionBtn = {
		DaHua_ListMini_Pair2_Icon1,DaHua_ListMini_Pair2_Icon2
	}

end

function DaHua_ListMini_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 05112801 then
		local opType =  Get_XParam_INT( 0 )
		if opType == g_DaHua_ListMini_opType.close then
			this:Hide()
		elseif opType == 1 then
			g_curState = Get_XParam_INT( 1 )
			DaHua_ListMini_Show()
		end
	elseif event == "PLAYER_LEAVE_WORLD" then
		this:Hide()
	elseif event == "ADJEST_UI_POS" then
		DaHua_ListMini_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		DaHua_ListMini_ResetPos()
	elseif event == "SCENE_TRANSED" then
		if not g_scene_res_ids[GetSceneID()] then
			this:Hide()
		end
	end
end

function DaHua_ListMini_ResetPos()
	DaHua_ListMini_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function DaHua_ListMini_Open()
	PushEvent("REFRESH_QIXIPVEWAR_SCORE",1)
end

function DaHua_ListMini_Leave()
	-- PushEvent("REFRESH_QIXIPVEWAR_SCORE",1000)
	if  not g_scene_res_ids[GetSceneID()] then 
		PushDebugMessage("#{QXPVE_240522_25}")
		return 
	end
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name( "ClientAskLeave" )
	Set_XSCRIPT_ScriptID(051128)
	Set_XSCRIPT_Parameter(0,0)
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function DaHua_ListMini_Show()
	this:Show()
	for i=1,g_FabaoNum do
		local info = g_Fabao[i]
		if info then
			local actionItem = Lua_CreateCoolDownItemForShow(info.item,info.cooldownId,1)
			if actionItem and actionItem:GetID()~=0 then 
				g_UI_items.actionBtn[i]:SetActionItem(actionItem:GetID())
			end
		end
	end
end

function DaHua_ListMini_DoAction(index)
	if  not g_scene_res_ids[GetSceneID()] then 
		return 
	end
	if index < 1 or index > g_FabaoNum then
		return
	end
	local actionId = g_UI_items.actionBtn[index]:GetActionItem()
	if actionId < 1 then
		--入场要是没创建成功 就在这再创一次
		DaHua_ListMini_Show()
		return
	end
	if Lua_CheckActionItemCoolDown(actionId) ~= 1 then
		PushDebugMessage("#{DZSY_250611_125}")
		return
	end
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name( "ClientUseFaBao" )
	Set_XSCRIPT_ScriptID(051128)
	Set_XSCRIPT_Parameter(0,index)
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

