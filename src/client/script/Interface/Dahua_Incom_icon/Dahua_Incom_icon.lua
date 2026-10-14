--=========
-- PreLoad()
--=========
function Dahua_Incom_icon_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)--打开or刷新界面 
	this:RegisterEvent("OPEN_DAHUA_MINITIPS",true) 
end

--=========
-- OnLoad()
--=========
function Dahua_Incom_icon_OnLoad() 
	--g_Dahua_Incom_iconFrame_UnifiedPosition = Dahua_Incom_icon_Frame:GetProperty("UnifiedPosition") 
end

--=========
-- Event
--=========
function Dahua_Incom_icon_OnEvent(event)

    if ( event == "OPEN_DAHUA_MINITIPS" ) then  
		local IsShowButton = tonumber(arg0)
		local IsShowTips = tonumber(arg1) 
		if IsShowButton == 1 then
			this:Show()
		else
            this:Hide()
            return
		end
		if IsShowTips == 1 then
            Dahua_Incom_icon_Tips:Show()
            Dahua_Incom_icon_Animate:Show()
		else
			Dahua_Incom_icon_Tips:Hide()
			Dahua_Incom_icon_Animate:Hide()
        end
    elseif ( event == "UI_COMMAND" and tonumber(arg0) == 50100203) then
		local IsShowButton = Get_XParam_INT(0)
		local IsShowTips = Get_XParam_INT(1) 
		if IsShowButton == 1 then
			this:Show()
		else
            this:Hide()
            return
		end
		if IsShowTips == 1 then
            Dahua_Incom_icon_Tips:Show() 
            Dahua_Incom_icon_Animate:Show()
		else
			Dahua_Incom_icon_Tips:Hide()
            Dahua_Incom_icon_Animate:Hide()
		end        		 
	end

end

function Dahua_Incom_icon_Close()   
end

--=========
-- 重置
--=========
function Dahua_Incom_icon_On_ResetPos()

	--Dahua_Incom_icon_Frame:SetProperty("UnifiedPosition", g_Dahua_Incom_iconFrame_UnifiedPosition)

end

function Dahua_Incom_BtnClk() 
	if IsInHell() == 1 then
		PushDebugMessage("#{WHTJ_240117_04}")	--当前场景无法进行此操作
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenChouJiang")
		Set_XSCRIPT_ScriptID( 501002 ) 
		Set_XSCRIPT_ParamCount( 0 ); 
	Send_XSCRIPT() 
end