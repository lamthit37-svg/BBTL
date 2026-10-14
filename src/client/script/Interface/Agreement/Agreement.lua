
local g_fullPath = "..\\Helper\\license-game.txt"
local g_Text = "no license..."
local g_fullPath_Privacy="..\\Helper\\license-privacy.txt"
local g_Text_Privacy = "no license..."

--===============================================
-- PreLoad()
--===============================================
function Agreement_PreLoad()

	this:RegisterEvent("OPEN_AGREEMENT_DLG",true);
	this:RegisterEvent("NET_HAS_CLOSED",false);
end

--===============================================
-- OnLoad()
--===============================================
function Agreement_OnLoad()
		local f = io.open(g_fullPath,"rb");
		if(f)then
			g_Text = f : read("*all");
		end
		if(f)then
			f : close();
			f = nil;
		end
		
		-- 隐私协议
		local fprivacy = io.open(g_fullPath_Privacy,"rb");
		if(fprivacy)then
			g_Text_Privacy = fprivacy : read("*all");
		end
		if(fprivacy)then
			fprivacy : close();
			fprivacy = nil;
		end
end

--===============================================
-- OnEvent()
--===============================================
function Agreement_OnEvent(event)
	if(event == "OPEN_AGREEMENT_DLG") then
		CloseWindow( "SoftKeyBoard" );
		Agreement_Button_Accept : Disable();
		Agreement_Button_Continue : Enable();
		Agreement_User_ShowText();
		Agreement_User_Bind : SetCheck(0);
		Agreement_Privacy_Bind : SetCheck(0);
		
		Agreement_User_Text:SetText("#{YSXY_211110_01}")
		Agreement_Privacy_Text:SetText("#{YSXY_211110_02}")
		
		if(not this:IsVisible() ) then
			this:Show()
		end
	end
	if( event == "NET_HAS_CLOSED" ) then
		this : Hide();
	end
end

function Agreement_Accept()
	GameProduceLogin:AgreeProtocol();
	this : Hide();
end

function Agreement_Cancel()
	GameProduceLogin:ReturnToAccountDlg();
	this : Hide();
	if GameProduceLogin:IsWeGameClient() > 0 then
		return
	end	
	OpenWindow( "SoftKeyBoard" );
	SetSoftKeyAim( "LogOn_PassWord" );	
end

function Agreement_User_SetCheck()

	local bUserChk = Agreement_User_Bind : GetCheck();
	local bPrivacyChk = Agreement_Privacy_Bind : GetCheck();
	if bUserChk > 0 and bPrivacyChk > 0 then
		Agreement_Button_Accept : Enable();
	else
		Agreement_Button_Accept : Disable();
	end
	
	if bUserChk > 0 then
		Agreement_User_ShowText()
	end
	
end

function Agreement_User_ShowText()
	Agreement_Text : SetText(" ");
	Agreement_Text : SetText(g_Text);
end

function Agreement_Privacy_SetCheck()
	local bUserChk = Agreement_User_Bind : GetCheck();
	local bPrivacyChk = Agreement_Privacy_Bind : GetCheck();
	if bUserChk > 0 and bPrivacyChk > 0 then
		Agreement_Button_Accept : Enable();
	else
		Agreement_Button_Accept : Disable();
	end
	
	if bPrivacyChk > 0 then
		Agreement_Privacy_ShowText()
	end
	
end

function Agreement_Privacy_ShowText()
	Agreement_Text : SetText(" ");
	Agreement_Text : SetText(g_Text_Privacy);
end

function Agreement_User_MouseEnter()
	Agreement_User_Text:SetText("#{YSXY_211110_08}")
end

function Agreement_User_MouseLeave()
	Agreement_User_Text:SetText("#{YSXY_211110_01}")
end

function Agreement_Privacy_MouseEnter()
	Agreement_Privacy_Text:SetText("#{YSXY_211110_09}")
end

function Agreement_Privacy_MouseLeave()
	Agreement_Privacy_Text:SetText("#{YSXY_211110_02}")
end
