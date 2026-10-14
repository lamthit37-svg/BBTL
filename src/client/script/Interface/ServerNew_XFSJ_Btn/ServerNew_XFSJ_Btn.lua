
local g_unifiedposistion
local g_scene_res_ids ={
	[1027] = 1,   --scenedefine
}
local g_EnterCloseUI = {
	"ActionSkill",
}

local g_ServerNew_XFSJ_Btn_CDTime = 2
local g_ServerNew_XFSJ_Btn_LastTime = 0

function ServerNew_XFSJ_Btn_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("PLAYER_LEAVE_WORLD", false)
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("SCENE_TRANSED",false);
	this:RegisterEvent("XFSJ_SHOWBTN",true);
end

function ServerNew_XFSJ_Btn_OnLoad()	
	g_unifiedposistion = ServerNew_XFSJ_Btn_Frame:GetProperty("UnifiedPosition")
end

function ServerNew_XFSJ_Btn_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 99971101 then
		local opType =  Get_XParam_INT( 0 )
		if opType == 1 then
			g_ServerNew_XFSJ_Btn_LastTime = 0
			ServerNew_XFSJ_Btn_CloseUI()
			--去请求（视同刷新换一批）
			DataPool:LuaFnAskNewXFSJHumanInfo(1)  --静默
			this:Show()
			
		else
			this:Hide()
		end
	elseif event == "XFSJ_SHOWBTN" then
		local opType =  tonumber(arg0)
		if opType == 1 then
			ServerNew_XFSJ_Btn_CloseUI()
			--去请求（视同刷新换一批）
			DataPool:LuaFnAskNewXFSJHumanInfo(1)  --静默
			this:Show()	
		else
			this:Hide()
		end
	elseif event == "PLAYER_LEAVE_WORLD" then
		this:Hide()
	elseif event == "ADJEST_UI_POS" then
		ServerNew_XFSJ_Btn_ResetPos()	
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		ServerNew_XFSJ_Btn_ResetPos()
	elseif event == "SCENE_TRANSED" then
		if not g_scene_res_ids[GetSceneID()] then
			this:Hide()
		end
	end
end

function ServerNew_XFSJ_Btn_ResetPos()
	ServerNew_XFSJ_Btn_Frame:SetProperty("UnifiedPosition", g_unifiedposistion)
end

function ServerNew_XFSJ_Btn_Clicked()
	if(IsWindowShow("ServerNew_XFSJ")) then
		CloseWindow("ServerNew_XFSJ", true)
		return 
	end
	
	--先看缓存里有没有数据，有的话直接去刷新显示，没有则去请求（视同刷新换一批）
	--local isCacheDataOK = DataPool:LuaFnGetXFSJHumanInfoValidCount()   --人数大于0
	--if isCacheDataOK > 0 then
		--使用本地缓存数据打开窗口
	--	PushEvent( "XFSJ_OPENMAIN", 0 ) 
	--	return 
	--end
	
	--按钮CD
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_ServerNew_XFSJ_Btn_LastTime < g_ServerNew_XFSJ_Btn_CDTime * 1000) then
		PushDebugMessage("#{XFSJ_250527_91}"); --当前操作过快，请稍后点击
		return
	end
	g_ServerNew_XFSJ_Btn_LastTime = curTime;

	--去请求（视同刷新换一批）
	DataPool:LuaFnAskNewXFSJHumanInfo(0)
	
--	Clear_XSCRIPT()
--		Set_XSCRIPT_Function_Name( "AskXFSJPlayerInfo" )
--		Set_XSCRIPT_ScriptID(999711)
--		Set_XSCRIPT_Parameter(0,0);   --opType 0 首次打开 1 刷新（换一批） 
--		Set_XSCRIPT_ParamCount(1)
--	Send_XSCRIPT()

end


function ServerNew_XFSJ_Btn_CloseUI()
	g_ServerNew_XFSJ_Btn_LastTime= 0			--抽奖按钮冷却时间计时
end
