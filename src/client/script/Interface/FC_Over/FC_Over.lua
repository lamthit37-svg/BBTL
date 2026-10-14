-- zjzdresult


-- 保存UI默认位置
local FC_Over_Frame_UnifiedPosition = nil



function FC_Over_PreLoad()
  
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)     -- 窗口分辨率发生变化
    this:RegisterEvent("ADJEST_UI_POS",false)               -- 窗口尺寸发生变化
	this:RegisterEvent("UI_COMMAND")

end -- end func FC_Over_Frame_PreLoad()

function FC_Over_OnLoad()
    FC_Over_Frame_UnifiedPosition = FC_Over_Frame:GetProperty("UnifiedPosition")
	
	
	
end -- end func FC_Over_Frame_OnLoad()

function FC_Over_OnEvent(event)
	if (event == "HIDE_ON_SCENE_TRANSED") then
        FC_Over_Frame_Hide()
    elseif (event == "VIEW_RESOLUTION_CHANGED") then
        FC_Over_Frame_UnifiedPos()
    elseif (event == "ADJEST_UI_POS") then
        FC_Over_Frame_UnifiedPos()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331170001) then	--服务端传数据
	
		local str = Get_XParam_STR(0)
		local bSuc = Get_XParam_INT(0)
		local nRound = Get_XParam_INT(1)
		FC_Over_AwardBK_Text:SetText(str)
		if nRound ~= 5 then
			if bSuc == 1 then --输了
				FC_Over_AwardBK_ExitBtn:Show()
				FC_Over_AwardBK_Fail:Show()
				FC_Over_AwardBK_YesBtn:Hide()
				FC_Over_AwardBK_Win:Hide()
			else
				FC_Over_AwardBK_ExitBtn:Hide()
				FC_Over_AwardBK_Fail:Hide()
				FC_Over_AwardBK_YesBtn:Show()
				FC_Over_AwardBK_Win:Show()
			end
			FC_Over_AwardBK_No1:Hide()
			FC_Over_AwardBK_No2:Hide()
		else
			if bSuc == 1 then --输了
				FC_Over_AwardBK_ExitBtn:Show()
				FC_Over_AwardBK_No2:Show()
				FC_Over_AwardBK_YesBtn:Hide()
				FC_Over_AwardBK_No1:Hide()
			else
				FC_Over_AwardBK_ExitBtn:Hide()
				FC_Over_AwardBK_No2:Hide()
				FC_Over_AwardBK_YesBtn:Show()
				FC_Over_AwardBK_No1:Show()
			end
			FC_Over_AwardBK_Fail:Hide()
			FC_Over_AwardBK_Win:Hide()
		end
		
		
		this:Show()
	elseif event == "UI_COMMAND" and (tonumber(arg0) == 331170005) then	--服务端传数据
		this:Hide()
	end
end -- end func FC_Over_Frame_OnEvent()




-- 界面默认位置
function FC_Over_Frame_UnifiedPos()
    if (this:IsVisible()) then
        if (FC_Over_Frame_UnifiedPosition ~= nil) then
            FC_Over_Frame:SetProperty("UnifiedPosition", FC_Over_Frame_UnifiedPosition)
        end
    end
end -- end func FC_Over_Frame_UnifiedPos()

function FC_Over_Frame_Hide()
    this:Hide()
end -- end func FC_Over_Frame_Hide()

-- 关闭按钮点击事件
function FC_Over_Frame_Close_Clicked()
	FC_Over_Frame_Hide()
end  -- end func FC_Over_Frame_Close_Clicked()

-- 退出按钮点击事件
function FC_Over_Frame_Exit_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("Exit")
		Set_XSCRIPT_ScriptID(331170)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end  -- end func FC_Over_Frame_Exit_Clicked()

function FC_Over_Help_Clicked()
  
end -- end func FC_Over_Frame_Help()

