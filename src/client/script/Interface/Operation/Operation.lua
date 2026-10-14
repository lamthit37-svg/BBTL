--===============================================
-- OnLoad()
--===============================================
function Operation_PreLoad()

	this:RegisterEvent("TOGLE_SYSTEMFRAME",true);
	this:RegisterEvent("TOGLE_GAMESETUP",false);
	this:RegisterEvent("TOGLE_SOUNDSETUP",false);
	this:RegisterEvent("TOGLE_VIEWSETUP",false);
	this:RegisterEvent("RELIVE_SHOW",false);
	this:RegisterEvent("RELIVE_HIDE",false);
	this:RegisterEvent("TOGLE_INPUTSETUP",false);
	this:RegisterEvent("TOGLE_CONTROLMODE",false)

	--TiuSong - 唯美版配置
	this:RegisterEvent("TOGLE_VIEWSETUP_WM",false);
	this:RegisterEvent("TOGLE_INPUTSETUP_WM",false)
end

function Operation_Ret2SelServer_Clicked()
	ReturnServerLogin() -- by cys
	--EnterQuitWait(1);
	Operation_Close();
	--AskRet2SelServer();
end;

function Operation_OnLoad()
	if SystemSetup:IsClassic() == 1 then
		Operation_Exchange:SetText("#{SDQH_130730_1}")
	else
		Operation_Exchange:SetText("#{SDQH_130730_2}")
	end
end

--===============================================
-- OnEvent()
--===============================================
function Operation_OnEvent(event)

	if ( event == "TOGLE_SYSTEMFRAME" ) then
		if( this:IsVisible()  ) then
			Operation_Close();
		else
			Operation_Open();
		end
	elseif(event == "TOGLE_GAMESETUP" ) then

		Operation_Close();
	elseif(event == "TOGLE_SOUNDSETUP" ) then

		Operation_Close();
	elseif(event == "TOGLE_VIEWSETUP" ) then
		Operation_Close();
	elseif(event == "TOGLE_VIEWSETUP_WM") then
		Operation_Close();
	elseif(event == "TOGLE_INPUTSETUP" ) then
		Operation_Close();
	elseif(event == "TOGLE_INPUTSETUP_WM") then
		Operation_Close()

	elseif(event == "TOGLE_CONTROLMODE") then
		Operation_Close()

	elseif(event == "RELIVE_SHOW") then
		if GameProduceLogin:IsWeGameServer() > 0 then
			Operation_WeGame_Help:Disable();
			Operation_WeGame_System:Disable();
			Operation_WeGame_2Menu:Disable();
		else
			Operation_Help:Disable();
			Operation_System:Disable();
			Operation_2Menu:Disable();
		end
	elseif(event == "RELIVE_HIDE") then
		if GameProduceLogin:IsWeGameServer() > 0 then
			Operation_WeGame_Help:Enable();
			Operation_WeGame_System:Enable();
			Operation_WeGame_2Menu:Enable();
		else
			Operation_Help:Enable();
			Operation_System:Enable();
			Operation_2Menu:Enable();
		end
	end

end

--===============================================
-- 官方论坛
--===============================================
function Operation_BBS_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_TLLUNTAN"))
end

--===============================================
-- 视频设置
--===============================================
function Operation_System_Clicked()
	SystemSetup:ViewSetup();
end
--===============================================
-- 声音设置
--===============================================
function Operation_Sound_Clicked()
	SystemSetup:SoundSetup();
end
--===============================================
-- 界面设置
--===============================================
function Operation_UI_Clicked()
	SystemSetup:UISetup();
end
--===============================================
-- 按键设置
--===============================================
function Operation_Input_Clicked()
	SystemSetup:InputSetup();
end

--===============================================
-- 游戏性设置
--===============================================
function Operation_Game_Clicked()
	SystemSetup:GameSetup();
end

--===============================================
-- 退出游戏
--===============================================
function Operation_QuitGame_Clicked()
	QuitApplication("quest");
	Operation_Close();
end


function Operation_Close()
	this:Hide();
end

function Operation_Open()
	if GameProduceLogin:IsWeGameServer() > 0 then
		Operation_WeGame_Client:Show();
		Operation_Frame_Client:Hide()
	else
		Operation_WeGame_Client:Hide();
		Operation_Frame_Client:Show()
	end
	this:Show();
end

function Operation_OnHidden()
end
--===============================================
-- 切换客户端
--===============================================
function Operation_ChangeClient_Clicked()
    local nRet = GetChangeClientType()
	if nRet > 4 or nRet < 1 then
		return
	end
	PushEvent("CHANGE_CLIENT_CONFIRM",nRet)
	--统计
	if SystemSetup:IsClassic() == 1 then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "SendChangeClientLog" )
		Set_XSCRIPT_ScriptID( 888888 )
		Set_XSCRIPT_Parameter(0,1);
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	else
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "SendChangeClientLog" )
		Set_XSCRIPT_ScriptID( 888888 )
		Set_XSCRIPT_Parameter(0,2);
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
end