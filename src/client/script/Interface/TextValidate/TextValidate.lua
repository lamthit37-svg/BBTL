--当前窗口类型....
local g_TextValidate_UIType = -1;

local g_TextValidate_UITypes = {
	EXCHANGE	= 2,		--交易验证....
	LEVELUP_CHECK	= 3,--升级验证....
	ANTIVIOLENCE_CHECK = 4, --防暴力验证, czf add
	LOGIN_LETTER_CHECK = 5,--字母验证码
}

local g_TextValidate_UserLoginType = "";
local g_TextValidate_UserLoginRoleId = -1;
local g_TextValidate_UserLoginScene = -1;


function TextValidate_PreLoad()

	---------------------------------------------------------------
	--交易相关begin
	this:RegisterEvent("EXCHANGE_BOX_CLOSED",false);	--交易盒关闭的时候，要关掉这个框。
	this:RegisterEvent("EXCHANGE_THISBOX_INVALID",false);	--交易时此对话框已经无效
	this:RegisterEvent("ACCEPT_EXCHANGE_CODE_VALIDATE",true);	--交易验证码的消息	
	this:RegisterEvent("EXCHANGE_IF_CODE_VALIDATE",false);	--交易验证码是否通过
	--交易相关end
	---------------------------------------------------------------

	--升级验证....
	this:RegisterEvent("SHOW_LEVELUP_CODE_VALIDATE",true);	--打开并更新本图形验证界面....
	this:RegisterEvent("LEVELUP_CODE_RET",false);	--服务端返回验证是否通过....

	--add by czf 防暴力2010-7
	this:RegisterEvent("SHOW_ANTIVIOLENT_CODE_VALIDATE",true);	--打开并更新防暴力的图形验证界面....
	this:RegisterEvent("ANTIVIOLENT_CODE_RET",false);	--服务端返回验证是否通过....
	this:RegisterEvent("CLOSE_TEXTVALIDATE",false);	--关闭图形验证框
	--add end

end

function TextValidate_OnLoad()

end

function TextValidate_OnEvent(event)

	if ( event == "SHOW_LEVELUP_CODE_VALIDATE" ) then	--打开并更新本图形验证界面....

		g_TextValidate_UIType = g_TextValidate_UITypes.LEVELUP_CHECK

		--更新图形验证信息....
		--这个接口是给选择类的图形验证用的....这个输入类的图形验证界面也套用这个接口....
		--5个参数分别是5个控件的名字....参数1是图形控件的名字..参数2~5是答案控件的名字....
		--调用后会刷新验证图片到图形控件....并刷新4个答案到4个答案控件的Text属性....
		DataPool:UpdateCaptchaData("TextValidate_Image", "TextValidate_NotUse", "TextValidate_NotUse", "TextValidate_NotUse", "TextValidate_NotUse", 2 );

		TextValidate_Input:SetText("");

		--如果是首次打开窗口(不是刷新图片)....
		if not this:IsVisible() then
			TextValidate_Frame:SetProperty("AlwaysOnTop", "True");
			TextValidate_WarningText:SetText("#{Create_Role_Code_Info}");
			TextValidate_Accept:SetProperty("Disabled", "False");
			TextValidate_ChangePic:SetProperty("Disabled", "False");
			TextValidate_Close:SetProperty("Disabled", "False");
			TextValidate_Input:SetProperty("DefaultEditBox", "True");
			this:Show();
		end

		--每次刷新窗口都随机窗口位置....
		TextValidate_RandomWindowPos()

	elseif event == "LEVELUP_CODE_RET" then	--服务端返回验证是否通过....

		if g_TextValidate_UIType ~= g_TextValidate_UITypes.LEVELUP_CHECK then
			return
		end

		if arg0 == "no" then
			--验证失败
			TextValidate_WarningText:SetText("#{Create_Role_Code_Failed}");
		elseif arg0 == "yes" then
			--验证成功....则关闭界面....
			TextValidate_WarningText:SetText("#{Create_Role_Code_Successed}");
			TextValidate_ChangePic:SetProperty("Disabled", "True");
			TextValidate_StopWatch2:SetProperty("Timer", "1");
		end

	end

	---------------------------------------------------------------
	--交易相关begin
	if  event == "ACCEPT_EXCHANGE_CODE_VALIDATE" then  --交易图形验证，代码在这里有重复，主要是方便合并文件
		g_TextValidate_UIType = g_TextValidate_UITypes.EXCHANGE;
		DataPool:UpdateCaptchaData("TextValidate_Image", "TextValidate_NotUse", "TextValidate_NotUse", "TextValidate_NotUse", "TextValidate_NotUse", 2 );

		TextValidate_Input:SetText("");

		--如果不是刷新图片
		if not this:IsVisible() then
			TextValidate_Frame:SetProperty("AlwaysOnTop", "True");
			TextValidate_WarningText:SetText("#{Create_Role_Code_Info}");	--文字就用以前那个
			TextValidate_Accept:SetProperty("Disabled", "False");
			TextValidate_ChangePic:SetProperty("Disabled", "False");
			TextValidate_Close:SetProperty("Disabled", "False");
			TextValidate_Input:SetProperty("DefaultEditBox", "True");
			this:Show();
		end	
		--每次刷新窗口都随机窗口位置....
		TextValidate_RandomWindowPos()
	end
	if  event == "EXCHANGE_THISBOX_INVALID" or event == "EXCHANGE_BOX_CLOSED" then 
		if this:IsVisible() and g_TextValidate_UIType == g_TextValidate_UITypes.EXCHANGE then	--对于交易来说，这里必须加g_TextValidate_UIType的判断
			--PushDebugMessage("Hide1")
			this : Hide();
		end
	end
	if event == "EXCHANGE_IF_CODE_VALIDATE" then	--服务端返回验证是否通过....

		if g_TextValidate_UIType ~= g_TextValidate_UITypes.EXCHANGE then
			return
		end

		if arg0 == "no" then
			--验证失败
			TextValidate_WarningText:SetText("#{Create_Role_Code_Failed}");
		elseif arg0 == "yes" then
			--验证成功....则关闭界面....
			TextValidate_WarningText:SetText("#{Create_Role_Code_Successed}");
			TextValidate_ChangePic:SetProperty("Disabled", "True");
			TextValidate_StopWatch2:SetProperty("Timer", "1");
				
			--角色当前是否要将金钱、珍兽或道具交易给其他玩家 [7/25/2013 shh][TT]
			local isExist = Exchange:IsSendSelfToDest();
			if isExist == 1 then	--有物品一定验证
				if CheckPhoneMibaoAndMinorPassword() == 0 then	--有物品就需要验证
					--验证没通过则取消交易
					Exchange_Cancel()
					return
				end
			else 									--没有物品
				if GetAuthorizedSafeFlag() == 0 and CheckPhoneMibaoAndMinorPassword() == 0 then	--非授权安全模式下需要验证
					--验证没通过则取消交易
					Exchange_Cancel()
					return
				end
			end
			
			Exchange:AcceptExchange();
		end

	end
	--交易相关end
	---------------------------------------------------------------

	--===================================================
	-------------------------add by czf 防暴力功能 2010-7-----------------------------
	if ( event == "SHOW_ANTIVIOLENT_CODE_VALIDATE" ) then	--打开并更新本图形验证界面....

		g_TextValidate_UIType = g_TextValidate_UITypes.ANTIVIOLENCE_CHECK

		--更新图形验证信息....
		--这个接口是给选择类的图形验证用的....这个输入类的图形验证界面也套用这个接口....
		--5个参数分别是5个控件的名字....参数1是图形控件的名字..参数2~5是答案控件的名字....
		--调用后会刷新验证图片到图形控件....并刷新4个答案到4个答案控件的Text属性....
		DataPool:UpdateCaptchaData("TextValidate_Image", "TextValidate_NotUse", "TextValidate_NotUse", "TextValidate_NotUse", "TextValidate_NotUse", 2 );

		TextValidate_Input:SetText("");

		--如果是首次打开窗口(不是刷新图片)....
		if not this:IsVisible() then
			TextValidate_Frame:SetProperty("AlwaysOnTop", "True");
			TextValidate_WarningText:SetText("#{Create_Role_Code_Info}");
			TextValidate_Accept:SetProperty("Disabled", "False");
			TextValidate_ChangePic:SetProperty("Disabled", "False");
			TextValidate_Close:SetProperty("Disabled", "False");
			TextValidate_Input:SetProperty("DefaultEditBox", "True");
			this:Show();
			DataPool:CloseSystemInfoWindow(); --czf 关闭系统信息界面
		end
		--每次刷新窗口都随机窗口位置....
		TextValidate_RandomWindowPos()
		--this:Show();

	elseif event == "ANTIVIOLENT_CODE_RET" then	--服务端返回验证是否通过....

		if g_TextValidate_UIType ~= g_TextValidate_UITypes.ANTIVIOLENCE_CHECK then
			return
		end

		if arg0 == "no" then
			--验证失败
			TextValidate_WarningText:SetText("#{Create_Role_Code_Failed}");
		elseif arg0 == "yes" then
			--验证成功....则关闭界面....
			TextValidate_WarningText:SetText("#{Create_Role_Code_Successed}");
			TextValidate_ChangePic:SetProperty("Disabled", "True");
			TextValidate_StopWatch2:SetProperty("Timer", "-1"); 
			this:Hide(); -- czf
		end
	elseif event == "CLOSE_TEXTVALIDATE" then
		if this:IsVisible() then
			this:Hide();
		end
	end
	----------------------add end------------------------------
	--===================================================
	
end

function TextValidate_BtnCommitClick()
		
	--发送玩家输入的字符串给服务端....
	local strInput = TextValidate_Input:GetText();
	if( strInput == "" ) then
		TextValidate_WarningText:SetText("#{Create_Role_Code_Failed}");
		return;
	end
	if g_TextValidate_UIType == g_TextValidate_UITypes.CREATE_ROLE then
		DataPool:SendCreateCharCode( strInput )
	elseif g_TextValidate_UIType == g_TextValidate_UITypes.LOGIN_CHECK then
		strInput=string.upper(strInput)
		DataPool:SendLoginCode( strInput )
	elseif (g_TextValidate_UIType == g_TextValidate_UITypes.EXCHANGE)then	
		 Exchange:SendExchangeCheckCode( strInput )
	elseif g_TextValidate_UIType == g_TextValidate_UITypes.LEVELUP_CHECK then
		AnswerLevelUpCode( strInput )
	elseif g_TextValidate_UIType == g_TextValidate_UITypes.ANTIVIOLENCE_CHECK then --czf add
		DataPool:SendAntiViolentCode( strInput )
	end
	TextValidate_DisableWindowSomeTime();

end

function TextValidate_BtnCloseClick()
	if (g_TextValidate_UIType == g_TextValidate_UITypes.EXCHANGE)then	
		 Exchange:SendEnableAcceptBtn();
	elseif (g_TextValidate_UIType == g_TextValidate_UITypes.ANTIVIOLENCE_CHECK)then
		DataPool:DisconnectLoginServer(); --czf 断开与login的socket连接
	end
	--PushDebugMessage("Hide2")
	this:Hide();
end

function TextValidate_BtnChangePicClick()
	--向Login请求新的图形验证信息....
	if g_TextValidate_UIType == g_TextValidate_UITypes.CREATE_ROLE then
		DataPool:AskCreateCharCode();
	elseif g_TextValidate_UIType == g_TextValidate_UITypes.LOGIN_CHECK then
		DataPool:AskLoginCode();
	elseif (g_TextValidate_UIType == g_TextValidate_UITypes.EXCHANGE)then
		Exchange:AskExchangeCheckCode();
	elseif g_TextValidate_UIType == g_TextValidate_UITypes.LEVELUP_CHECK then
		AskNewLevelUpCode();
	elseif g_TextValidate_UIType == g_TextValidate_UITypes.ANTIVIOLENCE_CHECK then --czf add
		DataPool:AskAntiViolentCode();
	end
	TextValidate_DisableWindowSomeTime();
end


--禁用窗口一段时间....防止不断向Login请求图片....
function TextValidate_DisableWindowSomeTime()
	TextValidate_Accept:SetProperty("Disabled", "True");
	TextValidate_ChangePic:SetProperty("Disabled", "True");
	TextValidate_Close:SetProperty("Disabled", "True");
	TextValidate_StopWatch1:SetProperty("Timer", "3");
end

function TextValidate_TimeReach1()
	TextValidate_Accept:SetProperty("Disabled", "False");
	TextValidate_ChangePic:SetProperty("Disabled", "False");
	TextValidate_Close:SetProperty("Disabled", "False");
	TextValidate_StopWatch1:SetProperty("Timer", "-1");
end

function TextValidate_TimeReach2()

	TextValidate_StopWatch2:SetProperty("Timer", "-1");
	TextValidate_Input:SetProperty("DefaultEditBox", "False");
	--PushDebugMessage("Hide3")
	this:Hide();

	if(g_TextValidate_UIType == g_TextValidate_UITypes.CREATE_ROLE)then		

		GameProduceLogin:ChangeToCreateRoleDlgFromSelectRole();

	elseif g_TextValidate_UIType == g_TextValidate_UITypes.LOGIN_CHECK then

		--根据之前缓存的玩家登录选择自动进入游戏....
		if g_TextValidate_UserLoginType == "NormalLogin" then
			GameProduceLogin:SendEnterGameMsg(g_TextValidate_UserLoginRoleId)
		end

		g_TextValidate_UserLoginType = "";
		g_TextValidate_UserLoginRoleId = -1;
		g_TextValidate_UserLoginScene = -1;

	elseif g_TextValidate_UIType == g_TextValidate_UITypes.LEVELUP_CHECK then

		AskLevelUpAfterValidate();

	end

end

--**********************************
--随机窗口位置
--**********************************
function TextValidate_RandomWindowPos()

	local x = -95
	local y = 44
	x = x + math.random(-160,160)
	y = y + math.random(-160,160)
	TextValidate_Frame:SetProperty("UnifiedXPosition", "{0.4,"..x.."}")
	TextValidate_Frame:SetProperty("UnifiedYPosition", "{0.2,"..y.."}")

end

---------------------------------------------------------------
-- New begin
function TextValidate_Frame_Hidden()
	TextValidate_Input:SetProperty("DefaultEditBox", "False");
	TextValidate_StopWatch2:SetProperty("Timer", "-1");
	TextValidate_StopWatch1:SetProperty("Timer", "-1");
end
-- New end
---------------------------------------------------------------

function TextValidate_Input_TextAccepted()
	TextValidate_BtnCommitClick()
end