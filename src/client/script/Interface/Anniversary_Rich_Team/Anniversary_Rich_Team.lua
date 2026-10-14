local g_Anniversary_Rich_Team_Frame_UnifiedPosition = nil 

local g_Anniversary_Rich_Team_List = {}
local g_Anniversary_Rich_Team_TargetId = -1
local g_Anniversary_Rich_Team_Type = -1
local g_Anniversary_Rich_Team_confirm = 0
function Anniversary_Rich_Team_PreLoad()

	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
	this:RegisterEvent("UI_COMMAND")

end 

-- Anniversary_Rich_Team_Client => TLBB_MainFrame0
-- Anniversary_Rich_Team_FrameBK => TLBB_Frame_Lace50
function Anniversary_Rich_Team_OnLoad()
	g_Anniversary_Rich_Team_Frame_UnifiedPosition = Anniversary_Rich_Team_Frame:GetProperty("UnifiedPosition");

	g_Anniversary_Rich_Team_List[1] = {pic=Anniversary_Rich_Team_List1_Pic,
										name = Anniversary_Rich_Team_List1_1,
										round = Anniversary_Rich_Team_List1_2}
	g_Anniversary_Rich_Team_List[2] = {pic=Anniversary_Rich_Team_List2_Pic,
										name = Anniversary_Rich_Team_List2_1,
										round = Anniversary_Rich_Team_List2_2}
	g_Anniversary_Rich_Team_List[3] = {pic=Anniversary_Rich_Team_List3_Pic,
										name = Anniversary_Rich_Team_List3_1,
										round = Anniversary_Rich_Team_List3_2}
	g_Anniversary_Rich_Team_List[4] = {pic=Anniversary_Rich_Team_List4_Pic,
										name = Anniversary_Rich_Team_List4_1,
										round = Anniversary_Rich_Team_List4_2}
	g_Anniversary_Rich_Team_List[5] = {pic=Anniversary_Rich_Team_List5_Pic,
										name = Anniversary_Rich_Team_List5_1,
										round = Anniversary_Rich_Team_List5_2}
	g_Anniversary_Rich_Team_List[6] = {pic=Anniversary_Rich_Team_List6_Pic,
										name = Anniversary_Rich_Team_List6_1,
										round = Anniversary_Rich_Team_List6_2}																																																
end

function Anniversary_Rich_Team_OnEvent(event)
	if(event == "ADJEST_UI_POS") then
		Anniversary_Rich_Team_On_ResetPos()
	elseif(event == "VIEW_RESOLUTION_CHANGED") then
		Anniversary_Rich_Team_On_ResetPos()
	elseif(event == "HIDE_ON_SCENE_TRANSED") then
		Anniversary_Rich_Team_On_Hide()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20230507 then
		Anniversary_Rich_Team_Init()
		this:Show()
	elseif event == "UI_COMMAND" and tonumber(arg0) == 20230510 then
		g_Anniversary_Rich_Team_confirm = 1
		this:Hide()
	end
end

function Anniversary_Rich_Team_BeginCareObject(objid)
	g_Object = objid
	this:CareObject(g_Object, 1, "Anniversary_Rich_Team");
end

function Anniversary_Rich_Team_On_ResetPos()
	Anniversary_Rich_Team_Frame:SetProperty("UnifiedPosition", g_Anniversary_Rich_Team_Frame_UnifiedPosition)
end

function Anniversary_Rich_Team_On_Hide()
	this:Hide()
end


function Anniversary_Rich_Team_Hide()
	--
end

function Anniversary_Rich_Team_CloseClicked()

end

function Anniversary_Rich_Team_Init()

	local index = 
	{
		[1] = {0,3},
		[2] = {1,4},
		[3] = {2,5},
		[4] = {3,6},
		[5] = {4,7},
		[6] = {5,8},
	}
	g_Anniversary_Rich_Team_confirm = 0
	local targetId = Get_XParam_INT(0)
	local membercount = Get_XParam_INT(1)
	local ntype = Get_XParam_INT(2)
	g_Anniversary_Rich_Team_TargetId = targetId
	g_Anniversary_Rich_Team_Type = ntype
	for i,v in ipairs(g_Anniversary_Rich_Team_List) do
		g_Anniversary_Rich_Team_List[i].name:SetText("")
		g_Anniversary_Rich_Team_List[i].round:SetText("")
		g_Anniversary_Rich_Team_List[i].pic:Hide()
	end

	if ntype == 1 then
		Anniversary_Rich_Team_TopFrame:SetText(ScriptGlobal_Format("#{ZNLSG_230215_349}",Get_XParam_STR(0)))
	elseif ntype == 2 then
		Anniversary_Rich_Team_TopFrame:SetText(ScriptGlobal_Format("#{ZNLSG_230215_355}",Get_XParam_STR(0)))
	end
	for i=1,membercount-1 do
		g_Anniversary_Rich_Team_List[i].pic:Show()
		local round = Get_XParam_INT(index[i][2])
		if round >= 1000 then --标识新人
			local str = ScriptGlobal_Format("#{ZNLSG_230215_376}", Get_XParam_STR(index[i][1]))
			g_Anniversary_Rich_Team_List[i].name:SetText(str)
			g_Anniversary_Rich_Team_List[i].round:SetText(round-1000)
		else
			g_Anniversary_Rich_Team_List[i].name:SetText(Get_XParam_STR(index[i][1]))
			g_Anniversary_Rich_Team_List[i].round:SetText(round)			
		end

	end
end


function Anniversary_Rich_Team_Accept_Clicked()
	if g_Anniversary_Rich_Team_confirm == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "TeamMemberConfim" )
			Set_XSCRIPT_ScriptID( 290400 )
			Set_XSCRIPT_Parameter(0, g_Anniversary_Rich_Team_TargetId)
			Set_XSCRIPT_Parameter(1, 1)
			Set_XSCRIPT_Parameter(2, g_Anniversary_Rich_Team_Type)
			Set_XSCRIPT_ParamCount( 3 )
		Send_XSCRIPT()
	else
		g_Anniversary_Rich_Team_confirm = 0
	end

	g_Anniversary_Rich_Team_confirm = 1
	this:Hide()
end

function Anniversary_Rich_Team_Cancel_Clicked()
	if g_Anniversary_Rich_Team_confirm == 0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "TeamMemberConfim" )
			Set_XSCRIPT_ScriptID( 290400 )
			Set_XSCRIPT_Parameter(0, g_Anniversary_Rich_Team_TargetId)
			Set_XSCRIPT_Parameter(1, 0)
			Set_XSCRIPT_Parameter(2, g_Anniversary_Rich_Team_Type)
			Set_XSCRIPT_ParamCount( 3 )
		Send_XSCRIPT()
	else
		g_Anniversary_Rich_Team_confirm = 0
	end
	g_Anniversary_Rich_Team_confirm = 1
	this:Hide()
end