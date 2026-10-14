--登录超时脚本

function LoginOverTime_PreLoad()
	this:RegisterEvent("LOGIN_OVER_TIME");
end

function LoginOverTime_OnLoad()

end

function LoginOverTime_OnEvent(event)
	if( event == "LOGIN_OVER_TIME" ) then
		LoginOverTime_InfoWindow:SetText("#{JSCJYH_121224_14}")
		this:Show()
	end
end

function LoginOverTime_Bn1Click()
	ChangeToAccountInputDlgForLoginOverTime()
	if(IsWindowShow("MessageBox_CYG")) then
		CloseWindow("MessageBox_CYG", true);
	end
	this:Hide()
end
