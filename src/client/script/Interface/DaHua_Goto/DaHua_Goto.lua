local g_DaHua_Goto_Frame_UnifiedXPosition
local g_DaHua_Goto_Frame_UnifiedYPosition


local g_Rand_MainCity =
{
	[1] = {PosX = 142, PosZ = 82, Scene = 976, Name = "牛虹虹"}, --翠屏山
	[2] = {PosX = 163, PosZ = 150, Scene = 977, Name = "孙小武"}, --水帘洞
	[3] = {PosX = 123, PosZ = 152, Scene = 978, Name = "李天军"}, --shiji
}

local g_UI_Info = {
	[1] = {title="#{QXPVE_240522_7}",info="#{QXPVE_240522_8}",tips="#{QXPVE_240522_127}"},
	[2] = {title="#{QXPVE_240522_133}",info="#{QXPVE_240522_9}",tips="#{QXPVE_240522_128}"},
	[3] = {title="#{QXPVE_240522_134}",info="#{QXPVE_240522_10}",tips="#{QXPVE_240522_129}"},
}

local g_StageImage = {
	[1] = "set:DaHua_PvE image:DaHua_PVE",
	[2] = "set:DaHua_PvE image:DaHua_PVE2",
	[3] = "set:DaHua_PvE2 image:DaHua_PVE3",
}

--预加载函数，可以而且只能在这里注册脚本关心的事件
function DaHua_Goto_PreLoad()
	this:RegisterEvent("UI_COMMAND");
	-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

--加载窗口的时候调用的函数，加载窗口时调用一次
function DaHua_Goto_OnLoad()
	-- 保存界面的默认相对位置
	g_DaHua_Goto_Frame_UnifiedXPosition	= DaHua_Goto_Frame_BK:GetProperty("UnifiedXPosition");
	g_DaHua_Goto_Frame_UnifiedYPosition	= DaHua_Goto_Frame_BK:GetProperty("UnifiedYPosition");

end

--================================================
-- 恢复界面的默认相对位置
--================================================
function DaHua_Goto_ResetPos()
	DaHua_Goto_Frame_BK:SetProperty("UnifiedXPosition", g_DaHua_Goto_Frame_UnifiedXPosition);
	DaHua_Goto_Frame_BK:SetProperty("UnifiedYPosition", g_DaHua_Goto_Frame_UnifiedYPosition);
end


--响应事件的函数，当注册的事件发生时会调用的函数
function DaHua_Goto_OnEvent(event)
	if event == "UI_COMMAND" and tonumber(arg0) == 05112804 then
		local opType =  Get_XParam_INT( 0 )
		if opType == 10 then
			--前往寻路
			local stage = Get_XParam_INT( 1 )
			if g_Rand_MainCity[stage] then
			--	PushDebugMessage(ScriptGlobal_Format("#{QXPVE_240522_14}",g_Rand_MainCity[stage].Name))
				AutoRuntoTargetExWithName(g_Rand_MainCity[stage].PosX,g_Rand_MainCity[stage].PosZ,g_Rand_MainCity[stage].Scene,g_Rand_MainCity[stage].Name)
			end
			DaHua_Goto_OnHide()
		elseif opType == 1 then
			local stage = Get_XParam_INT( 1 )
			DaHua_Goto_Show(stage)
		end
		
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		DaHua_Goto_OnHide()
	elseif event == "ADJEST_UI_POS" then
		DaHua_Goto_ResetPos()
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		DaHua_Goto_ResetPos()
	end
end

--显示UI
function DaHua_Goto_Show(stage)
	if g_UI_Info[stage] then
		DaHua_Goto_DragTitle:SetText(g_UI_Info[stage].title)
		DaHua_Goto_Text:SetText(g_UI_Info[stage].info)
		DaHua_Goto_GoBtn:SetToolTip(ScriptGlobal_Format("#{QXPVE_240522_11}",g_UI_Info[stage].tips))
		DaHua_Goto_BKPic:SetProperty("Image",g_StageImage[stage] )
		this:Show()
	else
		PushDebugMessage("#{QXPVE_240522_13}")
	end
end

--隐藏UI
function DaHua_Goto_OnHide()
	this:Hide()
end

--关闭界面
function DaHua_Goto_Hide()
	this:Hide()
end


function DaHua_Goto_ShowHelp()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("UIHelp")
		Set_XSCRIPT_ScriptID(051128)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function DaHua_Goto_Goto()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("UIGOTO")
		Set_XSCRIPT_ScriptID(051128)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end


