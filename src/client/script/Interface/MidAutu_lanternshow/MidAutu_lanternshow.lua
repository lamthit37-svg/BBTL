-- 中秋祈福二维码界面

local g_MidAutu_lanternshow_Frame_UnifiedPosition

local g_CurSelectSubObj = {-1, -1, -1}
local g_CurStatus = -1
local g_SerialNumber = ""
local g_nCount = 0

local g_MidAutu_lanternshow_ImageBK1 = {
	[1] = "set:MidAutu7 image:TuZideng",
	[2] = "set:MidAutu5 image:LianHuadeng",
	[3] = "set:MidAutu5 image:Gongdeng",
}
local g_MidAutu_lanternshow_ImageBK2_1 = {
	[1]	= "set:MidAutu5 image:Shiju8",
	[2] = "set:MidAutu3 image:Shiju3",
	[3] = "set:MidAutu5 image:Shiju6",
}
local g_MidAutu_lanternshow_ImageBK2_2 = {
	[1] = "set:MidAutu5 image:Shiju4",
	[2] = "set:MidAutu5 image:Shiju7",
	[3] = "set:MidAutu3 image:Shiju2",
}

local g_MidAutu_lanternshow_ImageBK2_3 = {
	[1] = "set:MidAutu5 image:Shiju9",
	[2] = "set:MidAutu5 image:Shiju5",
	[3] = "set:MidAutu3 image:Shiju1",
}

local g_MidAutu_lanternshow_Effect = {
	[1] = "UI_zhongqiuhuadeng_guihua",
	[2] = "UI_zhongqiuhuadeng_hudie",
	[3] = "UI_zhongqiuhuadeng_qianzhihe"
}

function MidAutu_lanternshow_PreLoad()
    this:RegisterEvent("UI_COMMAND");

	this:RegisterEvent("SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	
end

function MidAutu_lanternshow_OnLoad()
    g_MidAutu_lanternshow_Frame_UnifiedPosition = MidAutu_lanternshow_Frame:GetProperty("UnifiedPosition")
	
end

function MidAutu_lanternshow_OnEvent(event)

	if ( event == "SCENE_TRANSED" ) then
		MidAutu_lanternshow_OnClosed()

	elseif (event == "ADJEST_UI_POS" ) then
		MidAutu_lanternshow_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		MidAutu_lanternshow_On_ResetPos()
	
	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89316102) then
		local showflag = Get_XParam_INT( 0 )
		g_CurStatus = 1 --连接中
		g_CurSelectSubObj[1] = Get_XParam_INT( 1 )
		g_CurSelectSubObj[2] = Get_XParam_INT( 2 )
		g_CurSelectSubObj[3] = Get_XParam_INT( 3 )
		MidAutu_lanternshow_Update()
   	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89316104 and this:IsVisible() ) then
		g_CurStatus = 2   --成功
		g_SerialNumber = Get_XParam_STR(0)
		MidAutu_lanternshow_Update()
   	elseif (event == "UI_COMMAND" and tonumber( arg0 ) == 89316105 and this:IsVisible() ) then
		g_SerialNumber = ""
		g_CurStatus = 3   --失败
		MidAutu_lanternshow_Update()
	end

end

function MidAutu_lanternshow_Update()
	
	MidAutu_lanternshow_Erweima:SetProperty("Image", "")
	if g_CurStatus == 1 then
		MidAutu_lanternshow_Again:Hide()
		--开启计时器
		g_nCount = 0
		KillTimer("MidAutu_lanternshow_TimerProc()")
		SetTimer("MidAutu_lanternshow","MidAutu_lanternshow_TimerProc()", 1000)
	elseif g_CurStatus == 2 then
		KillTimer("MidAutu_lanternshow_TimerProc()")
		MidAutu_lanternshow_Again:Hide()
		DataPool:GenQRCode("MidAutu_lanternshow_Erweima", g_SerialNumber)
		MidAutu_lanternshow_Info:SetText("")
	elseif g_CurStatus == 3 then
		KillTimer("MidAutu_lanternshow_TimerProc()")
		MidAutu_lanternshow_Again:Show()
		MidAutu_lanternshow_Info:SetText("#{ZQQF_190724_43}")
	end
	
	for i = 1, 3 do			
		if g_CurSelectSubObj[i] < 1 or g_CurSelectSubObj[i] > 3 then
			g_CurSelectSubObj[i] = 1
		end
	end
	MidAutu_lanternshow_ImageBkC:SetProperty("Image", g_MidAutu_lanternshow_ImageBK1[g_CurSelectSubObj[1]])
	MidAutu_lanternshow_ImageBkB:replayEffect(g_MidAutu_lanternshow_Effect[g_CurSelectSubObj[2]])
	local index = g_CurSelectSubObj[3]
	if g_CurSelectSubObj[1] == 1 then
		MidAutu_lanternshow_ImageBkD:SetProperty("Image", g_MidAutu_lanternshow_ImageBK2_1[index])
	elseif g_CurSelectSubObj[1] == 2 then	
		MidAutu_lanternshow_ImageBkD:SetProperty("Image", g_MidAutu_lanternshow_ImageBK2_2[index])
	elseif g_CurSelectSubObj[1] == 3 then	
		MidAutu_lanternshow_ImageBkD:SetProperty("Image", g_MidAutu_lanternshow_ImageBK2_3[index])
	end
	this:Show()
end

function MidAutu_lanternshow_TimerProc()
	--计时器每秒一次，更新状态
	local nLeftTime = 20 - g_nCount
	if nLeftTime == 0 then
		MidAutu_lanternshow_Info:SetText("#{ZQQF_190724_45}")
		MidAutu_lanternshow_Again:Show()
		PushDebugMessage("#{ZQQF_190724_46}")
		KillTimer("MidAutu_lanternshow_TimerProc()")
		return
	end
	
	local str = ScriptGlobal_Format("#{ZQQF_190724_41}", nLeftTime)
	MidAutu_lanternshow_Info:SetText(str)
	
	g_nCount = g_nCount+1
end
--刷新
function MidAutu_lanternshow_Refresh_Clicked()

	--Clear_XSCRIPT()
	--	Set_XSCRIPT_Function_Name( "CheckQRCode" )
	--	Set_XSCRIPT_ScriptID( 893161 )
	--	Set_XSCRIPT_ParamCount(0)
	--Send_XSCRIPT()
end


function MidAutu_lanternshow_OnClosed()
	g_CurStatus = -1
	g_SerialNumber = ""
	g_nCount = 0
	KillTimer("MidAutu_lanternshow_TimerProc()")
	this:Hide()
end

function MidAutu_lanternshow_On_ResetPos()
    MidAutu_lanternshow_Frame:SetProperty("UnifiedPosition", g_MidAutu_lanternshow_Frame_UnifiedPosition)
end
