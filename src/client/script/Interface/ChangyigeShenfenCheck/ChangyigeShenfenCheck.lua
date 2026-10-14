
local g_CYG_Frame_UnifiedXPosition;
local g_CYG_Frame_UnifiedYPosition;
local g_CYG_theNPC = -1	-- 功能 NPC
local g_changyigeshenfencheck_type = 1
local g_changyigeshenfencheck_phonebind = 1
local g_changyigeshenfencheck_phonenum = 1
local g_changyigeshenfencheck_timeCount = 60 --1分钟倒计时用

--===============================================
-- PreLoad
--===============================================
function ChangyigeShenfenCheck_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("OBJECT_CARED_EVENT",false)		-- 关心 NPC 的存在和范围
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

--===============================================
-- OnLoad
--===============================================
function ChangyigeShenfenCheck_OnLoad()
	g_CYG_Frame_UnifiedXPosition	= ChangyigeShenfenCheck_Frame:GetProperty("UnifiedXPosition");
	g_CYG_Frame_UnifiedYPosition	= ChangyigeShenfenCheck_Frame:GetProperty("UnifiedYPosition");
end

function ChangyigeShenfenCheck_OnActive_MY()
	ShenfenCheck_SoftKey:SetSFZAimEditBox( "ChangyigeShenfenCheck_MoneyCount" );
	PhoneCheck_SoftKey:SetPhoneAimEditBox( "ChangyigeShenfenCheck_MoneyCount" );
end

function ChangyigeShenfenCheck_OnActive_PW()
	ShenfenCheck_SoftKey:SetSFZAimEditBox( "ChangyigeShenfenCheck_PasswordText" );
	PhoneCheck_SoftKey:SetPhoneAimEditBox( "ChangyigeShenfenCheck_SafeMessage_Text" );
end

--===============================================
-- OnEvent
--===============================================
function ChangyigeShenfenCheck_OnEvent(event)
	if (event == "UI_COMMAND") and (arg0 == "20130506") then
		local npcObjId = Get_XParam_INT(0)
		local OpenStatus = Get_XParam_INT(1)
		g_changyigeshenfencheck_type = Get_XParam_INT(2)
		g_changyigeshenfencheck_phonebind = Get_XParam_INT(3)
		g_changyigeshenfencheck_phonenum = Get_XParam_STR(0)
		g_CYG_theNPC = DataPool:GetNPCIDByServerID(npcObjId)
		if g_CYG_theNPC == -1 then
			--PushDebugMessage("server传过来的数据有问题。")
			return
		end

		if OpenStatus == 1 then
			ChangyigeShenfenCheck_Info:SetText("#{CYG_130527_75}")
		else 
			ChangyigeShenfenCheck_Info:SetText("#{CYG_130527_129}")
		end

		ChangyigeShenfenCheck_BeginCareObject(g_CYG_theNPC)
		ChangyigeShenfenCheck_MoneyCount:SetText("100");
		ChangyigeShenfenCheck_MoneyCount:SetProperty("DefaultEditBox", "True");
		ChangyigeShenfenCheck_MoneyCount:SetSelected( 0, -1 );
		ChangyigeShenfenCheck_PasswordText:SetText("")
		ChangyigeShenfenCheck_SafeMessage_Text:SetText("")
		ChangyigeShenfenCheck_SafeMessage : SetText("#{CYG_230524_04}");
		ShenfenCheck_SoftKey:SetSFZAimEditBox( "ChangyigeShenfenCheck_MoneyCount" );
		PhoneCheck_SoftKey:SetPhoneAimEditBox( "ChangyigeShenfenCheck_MoneyCount" );
		ChangyigeShenfenCheck_ID2:Hide()
		ChangyigeShenfenCheck_ID3:Hide()
		ChangyigeShenfenCheck_SoftKey_Client:Hide()
		ShenfenCheck_SoftKey:Hide()
		PhoneCheck_SoftKey:Hide()
		--小底图 和 进行验证按钮 在未绑定手机状态下 会关闭，其他时候就打开 做一次show。
		ChangyigeShenfenCheck_Blank:Show()
		ChangyigeShenfenCheck_ButtonCheck:Show()
		if g_changyigeshenfencheck_type == 1 then --身份证
			ChangyigeShenfenCheck_Price:Show()
			ChangyigeShenfenCheck_ID:Show()
			ChangyigeShenfenCheck_ID2:Hide()
			ChangyigeShenfenCheck_ID3:Hide()
			ChangyigeShenfenCheck_SoftKey_Client:Show()
			ShenfenCheck_SoftKey:Show()
		elseif g_changyigeshenfencheck_type == 2 then --短信认证结果

		elseif g_changyigeshenfencheck_type == 3 then -- 请求手机绑定状态
			ChangyigeShenfenCheck_Info:SetText("#{CYG_230524_01}")
			if g_changyigeshenfencheck_phonebind == 1 then--已绑定手机 显示 短信验证码界面
				ChangyigeShenfenCheck_Price:Show()
				ChangyigeShenfenCheck_ID:Hide()
				ChangyigeShenfenCheck_ID2:Show()
				ChangyigeShenfenCheck_ID3:Hide()
				local newphonenum = string.gsub(g_changyigeshenfencheck_phonenum, "(%d%d%d)(%d%d%d%d)(%d%d%d%d)", "%1****%3")
				ChangyigeShenfenCheck_PhoneNumber:Show()
				ChangyigeShenfenCheck_PhoneNumber_Text:SetText(newphonenum)
				ChangyigeShenfenCheck_SoftKey_Client:Show()
				PhoneCheck_SoftKey:Show()

			else
				--未绑定手机 显示 认证绑定手机界面 
				ChangyigeShenfenCheck_Price:Hide()
				ChangyigeShenfenCheck_ID:Hide()
				ChangyigeShenfenCheck_ID2:Hide()
				ChangyigeShenfenCheck_ID3:Show()
				--关闭两个软键盘
				ChangyigeShenfenCheck_ButtonCheck:Hide()
				ChangyigeShenfenCheck_Blank:Hide()
			end
		end
		
		this:Show()
		
		if(IsWindowShow("ChangyigeZigeCheck")) then
		  CloseWindow("ChangyigeZigeCheck", true);
		end
	elseif (event == "OBJECT_CARED_EVENT" and this:IsVisible()) then
		if (tonumber(arg0) ~= g_CYG_theNPC) then
			return
		end
		
		--如果和NPC的距离大于一定距离或者被删除，自动关闭
		if (arg1 == "distance" and tonumber(arg2) > MAX_OBJ_DISTANCE or arg1 == "destroy") then
			ChangyigeShenfenCheck_TestExit()
		end
	elseif( event == "ADJEST_UI_POS" ) then
		ChangyigeShenfenCheck_ResetPos()

	elseif( event == "VIEW_RESOLUTION_CHANGED" ) then
		ChangyigeShenfenCheck_ResetPos()
	end
end

function ChangyigeShenfenCheck_TestExit()
	ChangyigeShenfenCheck_MoneyCount:SetText( "100" )
	ChangyigeShenfenCheck_MoneyCount:SetProperty("DefaultEditBox", "True");
	ChangyigeShenfenCheck_MoneyCount:SetSelected( 0, -1 );
	ChangyigeShenfenCheck_PasswordText:SetText( "" )
	ChangyigeShenfenCheck_SafeMessage_Text:SetText( "" )
	--如果在cd途中关闭界面了 初始化 获取短信验证码按钮的cd部分
	KillTimer("ChangyigeShenfenCheck_request_message_timer()")
	ChangyigeShenfenCheck_SafeMessage : Enable();
	ChangyigeShenfenCheck_SafeMessage : SetText("#{CYG_230524_04}");
	g_changyigeshenfencheck_timeCount = 60
	this:Hide()
end

function ChangyigeShenfenCheck_Test()
	if g_changyigeshenfencheck_type == 1 then
		local money = ChangyigeShenfenCheck_MoneyCount:GetText()
		local password = ChangyigeShenfenCheck_PasswordText:GetText()
		if money == "" then --判断出售价格输入框中是否已输入内容
			PushDebugMessage("#{CYG_130527_81}")
			return
		end
		local nMoney = tonumber(money)
		if nMoney < 100 or nMoney > 9999999 then
			PushDebugMessage("#{CYG_130527_83}")
			return
		end
		if password ~= nil and password == "" then --判断出售价格输入框中是否已输入内容
			PushDebugMessage("#{CYG_130527_84}")
			return
		end
		
		if password ~= nil and string.len(password) ~= 8 then
			ChangyigeShenfenCheck_PasswordText:SetText("")
			PushDebugMessage("#{CYG_130527_85}")
			return
		end
		local iChar = 0
		for i =1 ,string.len(password) do
			iChar = string.byte(password,i)
			if (iChar >= 48 and iChar <=57 ) or (iChar >=65 and iChar <= 90) or (iChar >= 97 and iChar <= 122) then
			else
				PushDebugMessage("#{CYG_130527_86}")
				return
			end
		end
		iChar = 0
		local nCount = 0
		for i =1 ,string.len(password) do
			iChar = string.byte(password,i)
			if (iChar >=65 and iChar <= 90) or (iChar >= 97 and iChar <= 122) then
				nCount =nCount + 1			
			end
		end
		if nCount == 8 then
			PushDebugMessage("#{CYG_130527_86}")
			return
		end
		local charName = Player:GetName()
		PushEvent( "CHANGYIGE_CHECK_CONFIRM", tostring(password), tostring(charName), tonumber(money),tonumber(g_changyigeshenfencheck_type) )--这个type是1
		this:Hide()	
	elseif g_changyigeshenfencheck_type == 3 then
		if g_changyigeshenfencheck_phonebind == 1 then
			local money = ChangyigeShenfenCheck_MoneyCount:GetText()
			                 
			local password = ChangyigeShenfenCheck_SafeMessage_Text:GetText()
			if money == "" then --判断出售价格输入框中是否已输入内容
				PushDebugMessage("#{CYG_130527_81}")
				return
			end
			local nMoney = tonumber(money)
			if nMoney < 100 or nMoney > 9999999 then
				PushDebugMessage("#{CYG_130527_83}")
				return
			end
			if password ~= nil and password == "" then --判断出售价格输入框中是否已输入内容
				PushDebugMessage("#{CYG_230524_06}")
				return
			end
			
			if password ~= nil and string.len(password) ~= 6 then
				ChangyigeShenfenCheck_SafeMessage_Text:SetText("")
				PushDebugMessage("#{CYG_230524_07}")
				return
			end
			local iChar = 0
			for i =1 ,string.len(password) do
				iChar = string.byte(password,i)
				if (iChar >= 48 and iChar <=57 ) or (iChar >=65 and iChar <= 90) or (iChar >= 97 and iChar <= 122) then
				else
					PushDebugMessage("#{CYG_230524_08}")
					return
				end
			end
			iChar = 0
			local nCount = 0
			for i =1 ,string.len(password) do
				iChar = string.byte(password,i)
				if (iChar >=65 and iChar <= 90) or (iChar >= 97 and iChar <= 122) then
					nCount =nCount + 1			
				end
			end
			if nCount == 8 then
				PushDebugMessage("#{CYG_230524_08}")
				return
			end
			local charName = Player:GetName()
			PushEvent( "CHANGYIGE_CHECK_CONFIRM", tostring(password), tostring(charName), tonumber(money),2,tonumber(g_changyigeshenfencheck_phonebind),g_changyigeshenfencheck_phonenum)--这个type是2
			this:Hide()	

		end
	end

end

function ChangyigeShenfenCheck_ResetPos()
	ChangyigeShenfenCheck_Frame:SetProperty("UnifiedXPosition", g_CYG_Frame_UnifiedXPosition);
	ChangyigeShenfenCheck_Frame:SetProperty("UnifiedYPosition", g_CYG_Frame_UnifiedYPosition);

end

--=========================================================
--开始关心NPC，
--在开始关心之前需要先确定这个界面是不是已经有“关心”的NPC，
--如果有的话，先取消已经有的“关心”
--=========================================================
function ChangyigeShenfenCheck_BeginCareObject()
	this:CareObject(g_CYG_theNPC, 1, "ChangyigeShenfenCheck")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function ChangyigeShenfenCheck_StopCareObject()
	this:CareObject(g_CYG_theNPC, 0, "ChangyigeShenfenCheck")
	g_CYG_theNPC = -1
end

function ChangyigeShenfenCheck_Count_Change()
	local str = ChangyigeShenfenCheck_MoneyCount : GetText();
	local strNumber = 0;	
	
	if ( str == nil ) then
		return;
	elseif( str == "" ) then
		strNumber = 1;
	else
		strNumber = tonumber( str );
	end
	str = tostring( strNumber );
	ChangyigeShenfenCheck_MoneyCount:SetTextOriginal( str );
end

function ChangyigeShenfenCheck_request_Message()
	--执行逻辑
	local money = ChangyigeShenfenCheck_MoneyCount:GetText()
	if money == "" then --判断出售价格输入框中是否已输入内容
		PushDebugMessage("#{CYG_130527_81}")
		return
	end
	local nMoney = tonumber(money)
	if nMoney < 100 or nMoney > 9999999 then
		PushDebugMessage("#{CYG_130527_83}")
		return
	end
	--醒目提示
	PushDebugMessage("#{CYG_230524_24}")
	local charName = Player:GetName()
	--获取验证码
	CachedTarget:GetChangyigeCheckMsg("",nMoney,4,g_changyigeshenfencheck_phonebind,g_changyigeshenfencheck_phonenum)
	--上按钮界面CD
	ChangyigeShenfenCheck_SafeMessage : Disable();
	g_changyigeshenfencheck_timeCount = 60
	local str = ScriptGlobal_Format("#{CYG_230524_25}", tostring(g_changyigeshenfencheck_timeCount))
	ChangyigeShenfenCheck_SafeMessage : SetText(str);
	SetTimer("ChangyigeShenfenCheck","ChangyigeShenfenCheck_request_message_timer()", 1000)--每一秒走一次 做倒计时
end

function ChangyigeShenfenCheck_GotoBindMobilePhone()
	--出醒目提示
	PushDebugMessage("#{CYG_230524_15}")
	--关闭此验证界面
	ChangyigeShenfenCheck_TestExit()
	--url
	GameProduceLogin:OpenURL(GetWeblink("WEB_WEGAME_SJRZ"))
end

function ChangyigeShenfenCheck_request_message_timer()
	--时间没到
	g_changyigeshenfencheck_timeCount = g_changyigeshenfencheck_timeCount - 1
	if g_changyigeshenfencheck_timeCount > 0 then--时间没到
		local str = ScriptGlobal_Format("#{CYG_230524_25}", tostring(g_changyigeshenfencheck_timeCount))
		ChangyigeShenfenCheck_SafeMessage : SetText(str);
	else
		--时间到了
		KillTimer("ChangyigeShenfenCheck_request_message_timer()")
		ChangyigeShenfenCheck_SafeMessage : Enable();
		ChangyigeShenfenCheck_SafeMessage : SetText("#{CYG_230524_04}");
		g_changyigeshenfencheck_timeCount = 60
	end
end