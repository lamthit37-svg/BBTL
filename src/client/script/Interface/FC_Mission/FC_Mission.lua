-- zjzdzhankuang


-- 保存UI默认位置
local FC_Mission_Frame_UnifiedPosition = nil

local g_RoundText = {
	[1] = "#{DFXD_250326_28}",
	[2] = "#{DFXD_250326_29}",
	[3] = "#{DFXD_250326_30}",
	[4] = "#{DFXD_250326_31}",
	[5] = "#{DFXD_250326_32}",
}

local g_RoundSucText = {
	[1] = "#{DFXD_250326_127}",
	[2] = "#{DFXD_250326_128}",
	[3] = "#{DFXD_250326_129}",
	[4] = "#{DFXD_250326_130}",
}

local g_RoundPreText = {
	[1] = "#{DFXD_250326_123}",
	[2] = "#{DFXD_250326_132}",
	[3] = "#{DFXD_250326_132}",
	[4] = "#{DFXD_250326_132}",
	[5] = "#{DFXD_250326_132}",
}

local g_StateText = {
	[1] = "#{DFXD_250326_33}",
	[2] = "#{DFXD_250326_33}",
	[3] = "#{DFXD_250326_33}",
	[4] = "#{DFXD_250326_33}",
}

function FC_Mission_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")

end -- end func FC_Mission_Frame_PreLoad()

function FC_Mission_OnLoad()
    FC_Mission_Frame_UnifiedPosition = FC_Mission_Frame:GetProperty("UnifiedPosition")
	
	
	
end -- end func FC_Mission_Frame_OnLoad()

function FC_Mission_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        FC_Mission_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        FC_Mission_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        FC_Mission_Frame_UnifiedPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331170002) then	--服务端传数据
	
		local str = Get_XParam_STR(0)
		local nLeaveTime = Get_XParam_INT(0)	
		local nRound = Get_XParam_INT(1)
		local nSceneState = Get_XParam_INT(2)
		local nResult = Get_XParam_INT(3)
		FC_Misson_Explain_Text:SetText(str)
		if nSceneState == 2 then
			if nResult == 0 then
				if g_RoundText[nRound] ~= nil then
					FC_Mission_Text_1_Num:SetText(g_RoundText[nRound])
				end
			else
				if g_RoundSucText[nRound] ~= nil then
					if nResult == 1 then	
						FC_Mission_Text_1_Num:SetText("#{DFXD_250326_87}")
					else
						FC_Mission_Text_1_Num:SetText(g_RoundSucText[nRound])
					end
				end
			end
		elseif nSceneState == 1  then
			if g_RoundPreText[nRound] ~= nil then
				FC_Mission_Text_1_Num:SetText(g_RoundPreText[nRound])
			end
		elseif nSceneState == 3 then
			if g_RoundPreText[nRound] ~= nil then
				FC_Mission_Text_1_Num:SetText("#{DFXD_250326_131}")
			end
		end
		
		if g_StateText[nSceneState] ~= nil then
			FC_Mission_Text_2:SetText(g_StateText[nSceneState])
		end
		
		FC_Mission_Text_2_Num:SetProperty("Timer", nLeaveTime)
		
		this:Show()
	end
end -- end func FC_Mission_Frame_OnEvent()




-- 界面默认位置
function FC_Mission_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (FC_Mission_Frame_UnifiedPosition ~= nil) then
            FC_Mission_Frame:SetProperty("UnifiedPosition", FC_Mission_Frame_UnifiedPosition)
        end
    end
end -- end func FC_Mission_Frame_UnifiedPos()

function FC_Mission_Frame_Hide()
    this:Hide()
end -- end func FC_Mission_Frame_Hide()

-- 退出按钮点击事件
function FC_Mission_Frame_Info_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenCombatInfoUI")
		Set_XSCRIPT_ScriptID(820061)
		Set_XSCRIPT_Parameter(0, -1)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end  -- end func FC_Mission_Frame_Exit_Clicked()

function FC_Mission_Help_Clicked()
  
end -- end func FC_Mission_Frame_Help()

