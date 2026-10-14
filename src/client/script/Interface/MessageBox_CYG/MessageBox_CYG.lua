local g_CYG_iYesNoType = -1
local Changyige_password;
local Changyige_money;

--===============================================
-- PreLoad
--===============================================
function MessageBox_CYG_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("CHANGYIGE_LOGIN_CONFIRM") --畅易阁角色进入游戏二次确认对话框
	this:RegisterEvent("CHANGYIGE_LOGIN_DEL_CONFIRM") --弹出畅易阁删除角色二次确认对话框
	--this:RegisterEvent("CHANGYIGE_CHECK_CONFIRM")  --进行验证二次确认

end

--===============================================
-- OnLoad
--===============================================
function MessageBox_CYG_OnLoad()
	MessageBox_CYG_Info:SetText("")
	MessageBox_CYG_Button:Hide()
	MessageBox_CYG_Login:Hide()
	MessageBox_CYG_OKey:Hide()

end
--===============================================
-- OnEvent
--===============================================
function MessageBox_CYG_OnEvent(event)
	if (event == "UI_COMMAND") and (arg0 == "201306051") then
		local result = Get_XParam_INT(0)
		if result == 1 then --身份证与账号匹配但未绑定手机
			g_iYesNoType = 1
			MessageBox_CYG_Info:SetText("#{CYG_130527_91}")
			MessageBox_CYG_OK:Show()
			MessageBox_CYG_OKey:Hide()
			MessageBox_CYG_Button:Show()
			MessageBox_CYG_Login:Hide()
			MessageBox_CYG_UpdateRect(-162,-100,117,324)
			this:Show()
			MessageBox_CYG_CloseDaoJiShi()
		elseif result == 2 then --身份证与账号不匹配但已绑定手机(没有网络连接，所以不显示连接按钮)
			g_iYesNoType = 2
			MessageBox_CYG_Info:SetText("#{CYG_130527_94}")
			MessageBox_CYG_OK:Show()
			MessageBox_CYG_OKey:Hide()
			MessageBox_CYG_Button:Hide()
			MessageBox_CYG_Login:Hide()
			MessageBox_CYG_UpdateRect(-162,-100,117,324)
			this:Show()
			MessageBox_CYG_CloseDaoJiShi()
		elseif result == 3 then --身份证与账号不匹配且未绑定手机
			g_iYesNoType = 3
			MessageBox_CYG_Info:SetText("#{CYG_130527_95}")
			MessageBox_CYG_OK:Show()
			MessageBox_CYG_OKey:Hide()
			MessageBox_CYG_Button:Show()
			MessageBox_CYG_Login:Hide()
			MessageBox_CYG_UpdateRect(-162,-100,180,350)
			this:Show()
			MessageBox_CYG_CloseDaoJiShi()
		elseif result == 4 then --账号不存在
			g_iYesNoType = 2
			MessageBox_CYG_Info:SetText("#{CYG_130527_113}")
			MessageBox_CYG_OK:Show()
			MessageBox_CYG_OKey:Hide()
			MessageBox_CYG_Button:Hide()
			MessageBox_CYG_Login:Hide()
			MessageBox_CYG_UpdateRect(-189,-100,90,324)
			this:Show()
			MessageBox_CYG_CloseDaoJiShi()
		elseif result == 5 then --其它错误
			g_iYesNoType = 2
			MessageBox_CYG_Info:SetText("#{CYG_130527_112}")
			MessageBox_CYG_OK:Show()
			MessageBox_CYG_OKey:Hide()
			MessageBox_CYG_Button:Hide()
			MessageBox_CYG_Login:Hide()
			MessageBox_CYG_UpdateRect(-189,-100,90,324)
			this:Show()
			MessageBox_CYG_CloseDaoJiShi()
		elseif result == 6 then --角色交易验证功能关闭
			g_iYesNoType = 2
			MessageBox_CYG_Info:SetText("#{CYG_130527_114}")
			MessageBox_CYG_OK:Show()
			MessageBox_CYG_OKey:Hide()
			MessageBox_CYG_Button:Hide()
			MessageBox_CYG_Login:Hide()
			MessageBox_CYG_UpdateRect(-189,-100,90,324)
			this:Show()
			MessageBox_CYG_CloseDaoJiShi()
		elseif result == 8 then --身份证与账号不匹配且未绑定手机（认证手机服务关闭的情况）与3对应
			g_iYesNoType = 2
			MessageBox_CYG_Info:SetText("#{CYG_130527_130}")
			MessageBox_CYG_OK:Show()
			MessageBox_CYG_OKey:Hide()
			MessageBox_CYG_Button:Hide()
			MessageBox_CYG_Login:Hide()
			MessageBox_CYG_UpdateRect(-189,-100,90,324)
			this:Show()
			MessageBox_CYG_CloseDaoJiShi()
		elseif result == 10 then --您所输入的验证码，与您收到的短信验证码不匹配，本次验证未能通过
			g_iYesNoType = 2
			MessageBox_CYG_Info:SetText("#{CYG_230524_09}")
			MessageBox_CYG_OK:Show()
			MessageBox_CYG_OKey:Hide()
			MessageBox_CYG_Button:Hide()
			MessageBox_CYG_Login:Hide()
			MessageBox_CYG_UpdateRect(-189,-100,90,324)
			this:Show()
			MessageBox_CYG_CloseDaoJiShi()
		end
	elseif (event == "CHANGYIGE_LOGIN_CONFIRM") then
		g_iYesNoType = 4
		if GameProduceLogin:IsWeGameClient() > 0 then
			MessageBox_CYG_Info:SetText("#{CYG_230524_27}")--wegame端的提示字典
		else
			MessageBox_CYG_Info:SetText("#{CYG_130527_97}")
		end
		MessageBox_CYG_OK:Show()
		MessageBox_CYG_OKey:Hide()
		MessageBox_CYG_Button:Hide()
		MessageBox_CYG_Login:Show()
		MessageBox_CYG_UpdateRect(-234,-100,153,468)
		this:Show()
		MessageBox_CYG_CloseDaoJiShi()
	elseif (event == "CHANGYIGE_LOGIN_DEL_CONFIRM") then
		g_iYesNoType = 5
		MessageBox_CYG_Info:SetText("#{CYG_130527_98}")
		MessageBox_CYG_OK:Show()
		MessageBox_CYG_OKey:Hide()
		MessageBox_CYG_Button:Hide()
		MessageBox_CYG_Login:Show()
		MessageBox_CYG_UpdateRect(-189,-100,90,324)
		this:Show()
		MessageBox_CYG_CloseDaoJiShi()

	end
	
	if (event == "CHANGYIGE_CHECK_CONFIRM") then
		g_iYesNoType = 6
		Changyige_password = tostring(arg0)
		local Changyige_charname = tostring(arg1)
		Changyige_money = tostring(arg2)
		local strCYG = ScriptGlobal_Format("#{CYG_130527_87}", Changyige_charname, Changyige_money)
		MessageBox_CYG_Info:SetText(strCYG)
		MessageBox_CYG_OK:Show()
		MessageBox_CYG_OKey:Show()
		MessageBox_CYG_Button:Hide()
		MessageBox_CYG_Login:Hide()
		MessageBox_CYG_UpdateRect(-234, -150, 280, 468)

		this:Show();
		MessageBox_CYG_CloseDaoJiShi()
	end
end

function  MessageBox_CYG_UpdateRect(nXPos,nYPos,nHeight,nWidth)
	--local nWidth, nHeight = MessageBox_CYG_Info:GetWindowSize();
	--local nTitleHeight = 23;
	--local nBottomHeight = 25;
	--local nWindowHeight = nTitleHeight + nBottomHeight + nHeight;
	--MessageBox_CYG_Frame:SetProperty( "AbsoluteHeight", tostring( nWindowHeight ) );
	MessageBox_CYG_Frame:SetProperty("UnifiedPosition","{{0.500000,"..tostring(nXPos).."},{0.500000,"..tostring(nYPos).."}}")
	MessageBox_CYG_Frame:SetProperty("AbsoluteHeight", nHeight)
	MessageBox_CYG_Frame:SetProperty("AbsoluteWidth", nWidth)
end

--长按钮
function MessageBox_CYG_Button_Clicked() 
	if (g_iYesNoType == 1) or (g_iYesNoType == 3) then
		GameProduceLogin:OpenURL(GetWeblink("WEB_CYOU_INDEX")) --账号管理中心网站链接--http://account.changyou.com/lndex.jsp
	end
end

--登陆畅易阁按钮
function MessageBox_CYG_Login_Button_Clicked() 
	if g_iYesNoType == 4 then --畅易阁角色进入游戏二次确认对话框
		if GameProduceLogin:IsWeGameClient() > 0 then
			GameProduceLogin:OpenURL(GetWeblink("WEB_CYGJY")) --wg畅易阁网站链接
		else
			GameProduceLogin:OpenURL(GetWeblink("WEB_CHANGYIGE")) --畅易阁网站链接
		end
	elseif g_iYesNoType == 5 then --弹出畅易阁删除角色二次确认对话框
		GameProduceLogin:OpenURL(GetWeblink("WEB_CHANGYIGE")) --畅易阁网站链接
	end
	
end

--关闭
function MessageBox_CYG_OK_Clicked()	
	this:Hide()
end

--确定
function MessageBox_CYG_OKey_Clicked()
	if g_iYesNoType == 6 then
		CachedTarget:GetChangyigeCheckMsg(Changyige_password,Changyige_money)
		PushEvent( "CHANGYIGE_CHECK_WAITE" )
	end
	this:Hide()
end

function MessageBox_CYG_CloseDaoJiShi()
	if(IsWindowShow("ChangyigeZigeCheck")) then
		CloseWindow("ChangyigeZigeCheck", true);
	end
end

