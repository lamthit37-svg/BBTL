-- 每日一卦

local g_MidAutu_Lucky_Frame_UnifiedPosition

local g_IsGetHuadeng = -1
local g_CurSelectPos = -1
local g_CurGuaIndex = -1
local g_CurGuaId = -1
local g_MidAutu_Lucky_Pos_Button = {}
local g_MidAutu_Lucky_GuaTips = {
	[1] = "#{ZQQF_190724_118}",
	[2] = "#{ZQQF_190724_119}",
	[3] = "#{ZQQF_190724_120}",
	[4] = "#{ZQQF_190724_121}",
	[5] = "#{ZQQF_190724_122}",
	[6] = "#{ZQQF_190724_123}",
	[7] = "#{ZQQF_190724_124}",
	[8] = "#{ZQQF_190724_125}",
	[9] = "#{ZQQF_190724_126}",
}

local g_ScenePosList = {
	[1] = {sceneid = 164, posX = 57,  posY = 66, place = "香樟林"},
	[2] = {sceneid = 164, posX = 154, posY = 78, place = "曲院风荷"},
	[3] = {sceneid = 164, posX = 273, posY = 110, place = "白堤"},
	[4] = {sceneid = 164, posX = 209, posY = 152, place = "三潭印月"},
	[5] = {sceneid = 164, posX = 54,  posY = 204, place = "茶山"},
	
}

local g_MidAutu_Lucky_Image = {
	[1] = "set:MidAutu12 image:guaxiang_03",
	[2] = "set:MidAutu12 image:guaxiang_04",
	[3] = "set:MidAutu12 image:guaxiang_02",
}
function MidAutu_Lucky_PreLoad()
    this:RegisterEvent("UI_COMMAND");

	this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function MidAutu_Lucky_OnLoad()
    g_MidAutu_Lucky_Frame_UnifiedPosition = MidAutu_Lucky_Frame:GetProperty("UnifiedPosition")
	
	g_MidAutu_Lucky_Pos_Button[1] = MidAutu_Lucky_ButtonA
	g_MidAutu_Lucky_Pos_Button[2] = MidAutu_Lucky_ButtonB
	g_MidAutu_Lucky_Pos_Button[3] = MidAutu_Lucky_ButtonC
	g_MidAutu_Lucky_Pos_Button[4] = MidAutu_Lucky_ButtonD
	g_MidAutu_Lucky_Pos_Button[5] = MidAutu_Lucky_ButtonE
end

function MidAutu_Lucky_OnEvent(event)

	if ( event == "SCENE_TRANSED" ) then
		MidAutu_Lucky_OnClosed()

	elseif (event == "ADJEST_UI_POS" ) then
		MidAutu_Lucky_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		MidAutu_Lucky_On_ResetPos()
	
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89316201) then
		g_IsGetHuadeng = Get_XParam_INT( 0 )
		g_CurGuaIndex = Get_XParam_INT(1)
		g_CurGuaId = Get_XParam_INT(2)
		MidAutu_Lucky_Update()
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89316202) then
		local index = Get_XParam_INT( 0 )
		MidAutu_Lucky_Auto(index)
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89316203) then
		local index = Get_XParam_INT( 0 )
		MidAutu_Lucky_Pos_Select(index)
	end
end

function MidAutu_Lucky_Update()
	
	for i = 1, 5 do
		g_MidAutu_Lucky_Pos_Button[i]:SetProperty("Selected", "False")
	end
	
	if g_IsGetHuadeng == 1 then
		MidAutu_Lucky_Go:Show()
		MidAutu_Lucky_Get:Hide()
	else
		MidAutu_Lucky_Go:Hide()
		MidAutu_Lucky_Get:Show()
	end
	
	if g_CurGuaIndex ~= "" and g_CurGuaIndex>=1 and g_CurGuaIndex<=3 then
		MidAutu_Lucky_Image:SetProperty("Image",g_MidAutu_Lucky_Image[g_CurGuaIndex])
		MidAutu_Lucky_Text1:SetText("#{ZQQF_190724_116}")
		MidAutu_Lucky_Image:SetToolTip(g_MidAutu_Lucky_GuaTips[g_CurGuaId])
		MidAutu_Lucky_Image:Show()
	else
		MidAutu_Lucky_Text1:SetText("#{ZQQF_190724_62}")
		MidAutu_Lucky_Image:Hide()
	end
	
	this:Show()
end

function MidAutu_Lucky_Pos_Select(index)
	if index == 0 then
		for i = 1, 5 do
			g_MidAutu_Lucky_Pos_Button[i]:SetProperty("Selected", "False")
		end
		return
	end
	
	if index < 1 or index > 5 then
		return
	end
	
	for i = 1, 5 do	
		if index == i then	
			g_MidAutu_Lucky_Pos_Button[i]:SetProperty("Selected", "True")
		else
			g_MidAutu_Lucky_Pos_Button[i]:SetProperty("Selected", "False")
		end
	end
	g_CurSelectPos = index	
end

function MidAutu_Lucky_Pos_Clicked(index)
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "PosSelect" )
		Set_XSCRIPT_ScriptID( 893162 )
		Set_XSCRIPT_Parameter( 0, index )
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()		
end

function MidAutu_Lucky_Go_Click()
	if g_IsGetHuadeng ==0 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GoToGet" )
			Set_XSCRIPT_ScriptID( 893162 )
			Set_XSCRIPT_ParamCount(0)
		Send_XSCRIPT()
	elseif g_IsGetHuadeng == 1 then	
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "GoToUse" )
			Set_XSCRIPT_ScriptID( 893162 )
			Set_XSCRIPT_Parameter( 0, g_CurSelectPos )
			Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
end

function MidAutu_Lucky_Auto(index)
	if index == 0 then  --NPC
		AutoRunToTargetEx(280,183,164)
		SetAutoRunTargetNPCName("苏轼")
	elseif index >= 1 and index <= 5 then
		local PosX = g_ScenePosList[index].posX
		local PosZ = g_ScenePosList[index].posY
		local sceneid = g_ScenePosList[index].sceneid
		local place = g_ScenePosList[index].place
		AutoRunToTargetEx(PosX,PosZ,sceneid)
		local msg = ScriptGlobal_Format("#{ZQQF_190724_61}", place, PosX, PosZ)
		PushDebugMessage(msg)
	end
end

function MidAutu_Lucky_Client_HelpClicked()
	PushEvent( "OPEN_HUODONGTEXT_HELP", 1287, "#{ZQQF_190724_25}")
end

function MidAutu_Lucky_OnClosed()
	g_IsGetHuadeng = -1
	g_CurSelectPos = -1
	this:Hide()
end

function MidAutu_Lucky_On_ResetPos()
    MidAutu_Lucky_Frame:SetProperty("UnifiedPosition", g_MidAutu_Lucky_Frame_UnifiedPosition)
end
