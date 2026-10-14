local g_InCD = 0;


function SafeCenter_SafeMessage_PreLoad()
	this:RegisterEvent("OPEN_SAFECODE_PAGE");
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
end

function SafeCenter_SafeMessage_OnLoad()
end


function SafeCenter_SafeMessage_OnEvent(event)

	if ( event == "OPEN_SAFECODE_PAGE") then
		local errorcount = tonumber(arg0);
		if(errorcount == -1) then
			SafeCenter_SafeMessage_Close();
			return
		end
		
		local text = ScriptGlobal_Format("#{DXTZ_130812_02}", errorcount )
		SafeCenter_SafeMessage_Text:SetText(text)
		this:Show()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		SafeCenter_SafeMessage_Close();
	end
end


function SafeCenter_SafeMessage_OK_Clicked()
	if g_InCD == 0 then
		local strSafeCode = SafeCenter_SafeMessage_Time_Frame_Text2:GetText();
		local iLen = string.len(strSafeCode)
		if iLen ~= 6 then
			PushDebugMessage("#{DXTZ_130812_14}")
			SafeCenter_SafeMessage_Time_Frame_Text2:SetText("")
			return
		end
		LuaSendSafeCode(strSafeCode)
		SetTimer("SafeCenter_SafeMessage" , "SafeCenter_SafeMessage_Timer()",4000);
		g_InCD=1;
	else
		PushDebugMessage("#{DXTZ_130812_12}")
	end
	
	
end

function SafeCenter_SafeMessage_GetSafeCode()
	LuaAskSafeCode();
	SafeCenter_SafeMessage_Time_Frame_Text4:Show()
	SafeCenter_SafeMessage_Time_Frame_Text4:SetProperty("Timer",tostring(60*10));
	local text = ScriptGlobal_Format("#{DXTZ_130812_02}", 0 )
	SafeCenter_SafeMessage_Text:SetText(text)
	SafeCenter_SafeMessage_Time_Frame_Text3:Disable();
	
end

function SafeCenter_SafeMessage_Close()
	SafeCenter_SafeMessage_Time_Frame_Text2:SetText("")
	this:Hide();
end
function SafeCenter_SafeMessage_Active()

end

function SafeCenter_SafeMessage_Return()

end


function SafeCenter_SafeMessage_Change_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_RZSJ"))
end


function SafeCenter_SafeMessage_TimeOut()
	SafeCenter_SafeMessage_Time_Frame_Text3:Enable();
end

function SafeCenter_SafeMessage_Timer()
	g_InCD = 0;
	KillTimer("SafeCenter_SafeMessage_Timer()")
end


