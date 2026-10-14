
--local g_fullPath = "..\\Helper\\license-game-cyg.txt"
local g_Text = "#{CYG_130527_87}"
local g_fullPath_Privacy="..\\Helper\\license-game-cyg.txt"
local g_Text_Privacy = "no license..."

local g_Agreement2_Changyige_password;
local g_Agreement2_Changyige_money;
local g_Agreement2_Changyige_type;
local g_Agreement2_Changyige_bind;
local g_Agreement2_Changyige_phonenum;
--===============================================
-- PreLoad()
--===============================================
function Agreement2_PreLoad()

	this:RegisterEvent("CHANGYIGE_CHECK_CONFIRM");
end

--===============================================
-- OnLoad()
--===============================================
function Agreement2_OnLoad()
		-- local f = io.open(g_fullPath,"rb");
		-- if(f)then
		-- 	g_Text = f : read("*all");
		-- end
		-- if(f)then
		-- 	f : close();
		-- 	f = nil;
		-- end
		
		-- 隐私协议
		local fprivacy = io.open(g_fullPath_Privacy,"rb");
		if(fprivacy)then
			g_Text_Privacy = fprivacy : read("*all");
		end
		if(fprivacy)then
			fprivacy : close();
			fprivacy = nil;
		end

		--注意事项初始化
		g_Text = ScriptGlobal_Format("#{CYG_130527_87}","角色名称","角色价格")
end

--===============================================
-- OnEvent()
--===============================================
function Agreement2_OnEvent(event)
	if (event == "CHANGYIGE_CHECK_CONFIRM") then
		g_Agreement2_Changyige_password = tostring(arg0)
		local Changyige_charname = tostring(arg1)
		g_Agreement2_Changyige_money = tostring(arg2)
		g_Agreement2_Changyige_type = arg3
		g_Agreement2_Changyige_bind = arg4
		g_Agreement2_Changyige_phonenum = tostring(arg5)
		Agreement2_Privacy_CloseDaoJiShi()
		Agreement2_Button_Accept:Disable();
		Agreement2_Button_Continue:Enable();

		g_Text = ScriptGlobal_Format("#{CYG_130527_87}", Changyige_charname, g_Agreement2_Changyige_money) --先填入数值 再showtext
		Agreement2_User_ShowText();

		Agreement2_User_Bind:SetCheck(0);
		Agreement2_Privacy_Bind:SetCheck(0);

		Agreement2_User_Text:SetText("#{CYG_230524_20}")
		Agreement2_Privacy_Text:SetText("#{CYG_230524_21}")

		if (not this:IsVisible()) then
			this:Show()
		end
	end
	-- if( event == "NET_HAS_CLOSED" ) then
	-- 	this : Hide();
	-- end
end

function Agreement2_Accept()
	CachedTarget:GetChangyigeCheckMsg(g_Agreement2_Changyige_password,g_Agreement2_Changyige_money,g_Agreement2_Changyige_type,g_Agreement2_Changyige_bind,g_Agreement2_Changyige_phonenum)
	PushEvent( "CHANGYIGE_CHECK_WAITE" )
	this : Hide();
end

function Agreement2_Cancel()
	this : Hide();	
end

function Agreement2_User_SetCheck()

	local bUserChk = Agreement2_User_Bind : GetCheck();
	local bPrivacyChk = Agreement2_Privacy_Bind : GetCheck();
	if bUserChk > 0 and bPrivacyChk > 0 then
		Agreement2_Button_Accept : Enable();
	else
		Agreement2_Button_Accept : Disable();
	end
	
	if bUserChk > 0 then
		Agreement2_User_ShowText()
	end
	
end

function Agreement2_User_ShowText()
	Agreement2_Text : SetText(" ");
	Agreement2_Text : SetText(g_Text);
end

function Agreement2_Privacy_SetCheck()
	local bUserChk = Agreement2_User_Bind : GetCheck();
	local bPrivacyChk = Agreement2_Privacy_Bind : GetCheck();
	if bUserChk > 0 and bPrivacyChk > 0 then
		Agreement2_Button_Accept : Enable();
	else
		Agreement2_Button_Accept : Disable();
	end
	
	if bPrivacyChk > 0 then
		Agreement2_Privacy_ShowText()
	end
	
end

function Agreement2_Privacy_ShowText()
	Agreement2_Text : SetText(" ");
	Agreement2_Text : SetText(g_Text_Privacy);
end

function Agreement2_User_MouseEnter()
	Agreement2_User_Text:SetText("#{CYG_230524_20}")--颜色不同
end

function Agreement2_User_MouseLeave()
	Agreement2_User_Text:SetText("#{CYG_230524_20}")--颜色不同
end

function Agreement2_Privacy_MouseEnter()
	Agreement2_Privacy_Text:SetText("#{CYG_230524_21}")
end

function Agreement2_Privacy_MouseLeave()
	Agreement2_Privacy_Text:SetText("#{CYG_230524_21}")
end


function Agreement2_Privacy_CloseDaoJiShi()
	if(IsWindowShow("ChangyigeZigeCheck")) then
		CloseWindow("ChangyigeZigeCheck", true);
	end
end
