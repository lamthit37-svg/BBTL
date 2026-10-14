-- zjzdduizhan


-- 保存UI默认位置
local FC_GameInfo_Frame_UnifiedPosition = nil

local g_RoundImage = {
	[1] = "set:FC_Battle image:Battle_BK_32",
	[2] = "set:FC_Battle image:Battle_BK_16",
	[3] = "set:FC_Battle image:Battle_BK_8",
	[4] = "set:FC_Battle image:Battle_BK_2",
	[5] = "set:FC_Battle image:Battle_BK_1",
}


function FC_GameInfo_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")

end -- end func FC_GameInfo_Frame_PreLoad()

function FC_GameInfo_OnLoad()
    FC_GameInfo_Frame_UnifiedPosition = FC_GameInfo_Frame:GetProperty("UnifiedPosition")
	
	
	
end -- end func FC_GameInfo_Frame_OnLoad()

function FC_GameInfo_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        FC_GameInfo_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        FC_GameInfo_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        FC_GameInfo_Frame_UnifiedPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331170003) then	--服务端传数据
	
		local strSelfName = Get_XParam_STR(0)
		local strOppoName = Get_XParam_STR(1)
		local nRound = Get_XParam_INT(0)	
		
		FC_GameInfo_Left_Text:SetText(strSelfName)
		FC_GameInfo_Right_Text:SetText(strOppoName)
		if g_RoundImage[nRound] ~= nil then
			FC_GameInfo_Frame_BK:SetProperty("Image", g_RoundImage[nRound])
		end
		
		this:Show()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331170004) then	--服务端传数据
	
		
		
		this:Hide()
	end
end -- end func FC_GameInfo_Frame_OnEvent()




-- 界面默认位置
function FC_GameInfo_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (FC_GameInfo_Frame_UnifiedPosition ~= nil) then
            FC_GameInfo_Frame:SetProperty("UnifiedPosition", FC_GameInfo_Frame_UnifiedPosition)
        end
    end
end -- end func FC_GameInfo_Frame_UnifiedPos()

function FC_GameInfo_Frame_Hide()
    this:Hide()
end -- end func FC_GameInfo_Frame_Hide()

-- 退出按钮点击事件
function FC_GameInfo_Frame_Info_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Exit")
		Set_XSCRIPT_ScriptID(331170)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end  -- end func FC_GameInfo_Frame_Exit_Clicked()

function FC_GameInfo_Help_Clicked()
  
end -- end func FC_GameInfo_Frame_Help()

function FC_GameInfo_OnHide()
  
end -- end func FC_GameInfo_Frame_Help()

