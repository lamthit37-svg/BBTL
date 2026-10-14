local g_bInitedLoginID = 0;

local currentSoftKeyAim = 0;
local LastSoftKeyAimAfterHardware = 0;

local logonTailType=0
-- 登陆邮件名列表
local TailName ={
		[0] = "@changyou.com",
		"@game.sohu.com",
		"@Sohu.com",
		"@chinaren.com",
		"@sogou.com",
		"@17173.com",
		"手机号码登录",
		"输入其他账号后缀",
		"无后缀账号登录",
		}

local AutoTailName = {
		"",
		"@qq.com",
		"@163.com",
		"@126.com",
		"@sina.com",
		"@yahoo.com",
		"@game.sohu.com",
		"@changyou.com",
}

local g_bLogOnMode;

local PhoneCode ={
	"#{DHMB_080917_001}",
	"#{DHMB_080917_002}",
	"#{DHMB_080917_003}"
}

local PhoneCount = 3

local PhoneIndex = {-1,-1,-1,-1,-1}

local MiBaoDhCount = 0
local PasswdProctectTels = {"", "", "", "", ""}

local g_AccountType = 1
local g_zoneworldid = 0
local g_temp_AccountType =1

-- 注册PreLoad事件
function LoginLogOn_PreLoad()

	-- 打开界面
	this:RegisterEvent("GAMELOGIN_OPEN_COUNT_INPUT",true);

	-- 关闭界面
	this:RegisterEvent("GAMELOGIN_CLOSE_COUNT_INPUT",false);

	-- 进入游戏后清空帐号
	this:RegisterEvent("GAMELOGIN_CLEAR_ACCOUNT",true);

	this:RegisterEvent("LOGIN_MIBAO",true);

	-- 通知客户端显示密保提示
	this:RegisterEvent("GAMELOGIN_NOTIFY_PASSWDTEL_OPENED",true);

	this:RegisterEvent("MAILLIST_CLICKED",false);
	this:RegisterEvent("LOGIN_NO_MIBAO_CLOSE",false); 

	this:RegisterEvent( "CAPLOCK_CHANGED", false )
--	this:RegisterEvent("LOGIN_TYPE_COLLECTION")


end

-- 注册onLoad事件
function LoginLogOn_OnLoad()

		-- 随机队列设置初值
		for i=1,PhoneCount do
			PhoneIndex[i] = -1
		end

	-- 生成邮箱帐号的下拉列表
  local TailCount = 9
	local i = 0;

	for i = 0, TailCount-1 do
		LogOn_Region:ComboBoxAddItem( TailName[ i ], i );
	end
	----选择上一次登录的账号后缀dengxx
	local nMailIndex = Variable:GetVariable("Account_MailIndex")
	if nMailIndex == nil or nMailIndex == "-1" then
		nMailIndex = 0
		Variable:SetVariable("Account_MailIndex_AlterFlag", "1", 0);
	--上面属于没有登陆过、或者重新装客户端的情况
	else
		local nAlterFlag = Variable:GetVariable("Account_MailIndex_AlterFlag")
		--这种情况下需要调整，其他无必要；但玩家手动删除这个标记，那是没有办法
		if nAlterFlag == nil or nAlterFlag == "-1" then

			if tonumber(nMailIndex) == 0 then
				nMailIndex = "1"
				Variable:SetVariable("Account_MailIndex", tostring(nMailIndex), 0);
				Variable:SetVariable("Account_MailIndex_AlterFlag", "1", 0);
			elseif tonumber(nMailIndex) == 1 then
				nMailIndex = "0"
				Variable:SetVariable("Account_MailIndex", tostring(nMailIndex), 0);
				Variable:SetVariable("Account_MailIndex_AlterFlag", "1", 0);
			elseif tonumber(nMailIndex) == 6 then
				nMailIndex = "7"
				Variable:SetVariable("Account_MailIndex", tostring(nMailIndex), 0);
				Variable:SetVariable("Account_MailIndex_AlterFlag", "1", 0);
			else	
				Variable:SetVariable("Account_MailIndex_AlterFlag", "1", 0);
			end

		end
	end
	LogOn_Region:SetCurrentSelect(tonumber(nMailIndex))

	--下面的东西暂时保留
	local preLogonType = Variable:GetVariable("Account_LogonType")

	--之前第一次的时候，没有这个变量，返回nil；此时还是维持最初的type=1
	if preLogonType == nil or preLogonType == "-1" then
		preLogonType = "1"
	end

	g_AccountType = tonumber(preLogonType)

	--下面的东西暂时保留
	if tonumber(nMailIndex) == 7 then
		g_AccountType = 2
	end

	--LogOn_Region:SetCurrentSelect(0);
	logonTailType=0
	----------------------------------------

	MiBaoTips_InfoWindow:SetText("#{DHMB_90417_1}");

	--电话密保放在游戏中了，所以下面的就跳过去了，houzhifang 090417

	LogOn_TraditionLogon:SetToolTip("#{DLYH_121213_02}")
	LogOn_OwnDefineLogon:SetToolTip("#{DLYH_121213_03}")
	-- 081014 start /* 如果有文件配置密保，则读配置 */
	-- 从配置文件里随机取3个电话
	--math.randomseed(os.time() + 250);
--	math.random(0,100);math.random(0,100)
--	local arrIdx = {-1,-1,-1};
--	local MAX_TEL_SHOWCOUNT = 3
--	local iGetCount = 0
--	MiBaoDhCount = GameProduceLogin:GetPasswdTelCount();
--	if( MiBaoDhCount > 0 and MiBaoDhCount < 5000 ) then
--		while (iGetCount < MiBaoDhCount and iGetCount < MAX_TEL_SHOWCOUNT) do
--			local iTmpIdx = math.random(0,MiBaoDhCount-1);
--			local bExitIdx = 0;
--			for i = 1, iGetCount do
--				if (arrIdx[i] == iTmpIdx) then
--					bExitIdx = 1;
--					break;
--				end;
--			end;
--			if ( 1 ~= bExitIdx ) then
--				iGetCount = iGetCount + 1;
--				arrIdx[iGetCount] = iTmpIdx;
--			end;
--		end;
--		if (MiBaoDhCount > MAX_TEL_SHOWCOUNT) then --考虑到提示框大小， 密保电话数量限定为3个
--			MiBaoDhCount = MAX_TEL_SHOWCOUNT
--	end
--
--		for i=1,MiBaoDhCount do
--			local strTel = GameProduceLogin:GetPasswdTelByIndex(arrIdx[i]);
--			PasswdProctectTels[i] = strTel;
--				end
--
--		local str = "#{DHMB_080917_004}".."#r"
	--	local str1=""
--		for i=1,MiBaoDhCount do
--			local strTel = GameProduceLogin:GetPasswdTelByIndex(arrIdx[i]);
--			PasswdProctectTels[i] = strTel;
--			--str1 = str1..strTel.."  "; -- 索引下标起始和c++里不一样
--		end
--
--		 --dengxx
 --   for i=1,MiBaoDhCount-1 do
--		  str1 = str1..PasswdProctectTels[i].." ";
--	  end
--	  str1 = str1..PasswdProctectTels[MiBaoDhCount];
	--  str1 = str1.."#r".."#{DHMB_090205_1}";
--		MiBaoTips_InfoWindow:SetText(str..str1);
--		LogOn_MibaoSetToolTip()
--		return;
--	end
	-- 081014 end /**/

--	local iNum1 =math.random(1,3); --第一个随机数总是1，加这个增加随机性
--	for i=1,PhoneCount do
--		bFlag = 0
--		while bFlag == 0 do
--			local iNum =math.random(1,3);
--			if 0 == RandNumExist(iNum) then
--				PhoneIndex[i] = iNum
--				bFlag = 1
--			end
--		end
--	end

--	local str = "#{DHMB_080917_004}".."#r"
--	local str1=""
	--dengxx  显示空间太小，需要少砍掉一个空格
--	for i=1,PhoneCount-1 do
--		str1 = str1..PhoneCode[PhoneIndex[i]].." ";
--	end
--	str1 = str1..PhoneCode[PhoneIndex[PhoneCount]];
--	str1 = str1.."#r".."#{DHMB_090205_1}";
--	MiBaoTips_InfoWindow:SetText(str..str1);
end

function RandNumExist(iNum)
	for i=1,PhoneCount do
		if PhoneIndex[i] ==iNum then
			return 1
		end
	end
	return 0
end

-- OnEvent

function LoginLogOn_OnEvent(event)

	if event == "CAPLOCK_CHANGED" then
		LogOn_UpdateCaplockTips()
		return
	end

	-- 打开帐号输入界面
 	if( event == "GAMELOGIN_OPEN_COUNT_INPUT" ) then
 		if GameProduceLogin:IsWeGameClient() > 0 then
 			LogOn_UpdateCaplockTips()
 			LogOn_Input_Background_Frame:Hide();
 			LogOn_RequisitionID:Hide();
 			LogOn_payment:Hide();
 			LogOn_Wegame_Frame:Show();
 			LogOn_LogOnGame_Wegame_ID_Text:SetText( GameProduceLogin:GetWeGameRailID() ); 			
 			local strHostName = GameProduceLogin:GetSelectLoginServer();
			SeverSituation_InfoWindow:SetText(ScriptGlobal_Format("#{FWQWL_201130_03}", strHostName ))
 			this:Show();
 			return
 		else
 			LogOn_Wegame_Frame:Hide();
 		end
 		
 		LogOn_Input_NoticeText:Hide();
		LogOn_Input_Background_SubFrame:Show();
		local bGameMiBao = Variable:GetVariable("Game_MiBao")
	  if bGameMiBao == nil or bGameMiBao == "" then
		   bGameMiBao = 0
	  end

	  local iGameMiBao = tonumber(bGameMiBao)
	  if iGameMiBao == 0 then
	  	LogOn_PassWord_Protect_Check:SetCheck(0)

		PassWordProtectCheckClicked()

	  elseif iGameMiBao == 1 then
	  	LogOn_PassWord_Protect_Check:SetCheck(1)
	  	PassWordProtectCheckClicked();
		else


		end
		g_zoneworldid = GameProduceLogin:GetZoneWorldid()
		OtherLogon_Frame_ElseLogon:Hide();
		OtherLogon_NewLogon:Hide();
		--LogOn_Phone_Protect_Check:SetCheck(0)

		-- 紧急修改，由于外网还没有开通此项服务，先关闭 刘盾 2008.7.30
		--LogOn_Phone_Protect_Check:Disable()
		--LogOn_Phone:Disable()

		LogOn_UpdateCaplockTips()

		this:Show();

		g_bLogOnMode = 0;
		LogOn_Initilize();
		--OpenWindow( "SoftKeyBoard" );

		-- 55928 根据测试意见，将默认的软键盘输入焦点从密码框改到账号输入框
		--SetSoftKeyAim( "LogOn_PassWord" );
		if g_AccountType == 1 then
			SetSoftKeyAim( "LogOn_ID" );
		elseif g_AccountType == 2 then
			SetSoftKeyAim( "LogOn_MailID" );
		end
		
		local strHostName = GameProduceLogin:GetSelectLoginServer();
		SeverSituation_InfoWindow:SetText(ScriptGlobal_Format("#{FWQWL_201130_03}", strHostName ))
			
		return;
	end


	-- 关闭帐号输入界面
	if( event == "GAMELOGIN_CLOSE_COUNT_INPUT") then

		-- 清空密码.
		LogOn_PassWord:SetText("");
		LogOn_ID:SetText("");
		LogOn_MailID:SetText("");

		CloseWindow( "SoftKeyBoard" );
		this:Hide();
		return;
	end

	-- 进入游戏后清空帐号
	if( event == "GAMELOGIN_CLEAR_ACCOUNT") then

		-- 清空密码.
		LogOn_PassWord:SetText("");
		LogOn_ID:SetText("");
		LogOn_MailID:SetText("");

		CloseWindow( "SoftKeyBoard" );
		this:Hide();
		return;
	end

	if(event == "LOGIN_MIBAO" and arg0 == "softkey") then
		if( g_bLogOnMode == 1 ) then
			return;
		end
		if( currentSoftKeyAim == 1 ) then
			LogOn_LogonPassWord_Active();
		else
			if g_AccountType == 1 then
				LogOn_LogonID_Active();
			elseif g_AccountType == 2 then
				LogOn_LogonMailID_Active()
			end
		end
		return;
	end

	if(event == "GAMELOGIN_NOTIFY_PASSWDTEL_OPENED") then
		LogOn_MibaoShowSystemInfo();
	end

	if (event == "MAILLIST_CLICKED") then
		local txt = LogOn_MailID:GetText()
		logonTailType=tonumber(arg0)
		LogOn_MailID:SetText(txt..AutoTailName[tonumber(arg0)])
		LogOn_MailID:SetProperty("CaratIndex" , 999) ;

	end

	if(event == "LOGIN_NO_MIBAO_CLOSE") then

		LogOn_PassWord_Protect_Check:SetCheck(0);


	end

	--if(event == "LOGIN_TYPE_COLLECTION") then

	--	local strPostFix = ""
	--	if g_AccountType == 1 then
	--		strPostFix, _ = LogOn_Region:GetCurrentSelect();
	--	else
	--		strPostFix = ""
	--	end
	--	Player:ReportLoginTypeMsg(tostring(g_AccountType),tostring(strPostFix))
	--end
end

function LogOn_Initilize()

	-- 用于判断是否开启二维码登录 wangbin 2014-06-06 
	LogOn_TraditionLogon:Show();
	LogOn_Input_Background_FrameImage:Show();
	LogOn_OwnDefineLogon:Show();
	LogOn_ErweimaLogon:Show();
	OldLogOn_Input_Background_FrameImage:Hide();
	OldLogOn_TraditionLogon:Hide();
	OldLogOn_OwnDefineLogon:Hide();
	
	LogOn_ID:Enable();
	LogOn_MailID:Enable();
	LogOn_ID:SetText("");
	LogOn_MailID:SetText("");
	LogOn_TiShi:Hide()
	if g_AccountType == 1 then
		g_AccountType = 0
		LogOn_TraditionLogon_MouseDown()
		LogOn_TraditionLogon:SetCheck(1)
		LogOn_LogonID_Active();
	elseif g_AccountType == 2 then
		g_AccountType = 0
		LogOn_OwnDefineLogon_MouseDown()
		LogOn_OwnDefineLogon:SetCheck(1)
		LogOn_LogonMailID_Active()
	end

	LogOn_PassWord:Enable();
	LogOn_PassWord:SetText("");


end
----------------------------------------------------------------------------------------------------------
--
-- 退到服务器选择界面
--
function LogOn_ExitToSelectServer()
	-- 退到服务器选择界面

	GameProduceLogin:ExitToSelectServer();
end


----------------------------------------------------------------------------------------------------------
--
-- 验证用户名和密码
--
function LogOn_CheckAccount()

	if GameProduceLogin:IsWeGameClient() > 0 then
		GameProduceLogin:LoginWeGameAccount();
		return
	end	
	
	if g_AccountType == 1 then
		-- 退到服务器选择界面
		local strName = LogOn_ID:GetText();
		local strPassword = LogOn_PassWord:GetText();
		local strTail, nIndex = LogOn_Region:GetCurrentSelect();
		local bMiBao = 0;
		local bUseHardwareMiBao = 0;
		local strHardwarePWD = "";
		if(Variable:GetVariable("System_CodePage") == "1258") then
			-- Dummy
		else
			bMiBao = LogOn_PassWord_Protect_Check:GetCheck();

		end

		if( strTail == tostring( "-1" ) ) then
				strTail = "";
		end

		strTail = LogOn_Region:GetText();    --暂时修改,因为GetCurrentSelect的bug,导致在某些操作的时候不能正确取得当前的选择,而界面底层正在修改中,暂时用此函数解决用户名后缀为空的问题BugID:15422

		if(Variable:GetVariable("System_CodePage") == "1258") then
			strTail = "";
		end

		if( strName =="" ) then
			return;
		end
		if( strPassword == "" ) then
			return;
		end

		if nIndex and nIndex == -1 then
			nIndex = 0
		end
		Variable:SetVariable("Account_MailIndex", tostring(nIndex), 0);


		--如果是手机那东西；清理后缀
		if nIndex == 6 or nIndex == 8 then
			strTail = "";
		end

		GameProduceLogin:CheckAccount(strTail, bMiBao, bUseHardwareMiBao,strHardwarePWD , 1);


		if(bMiBao == 0) then
			--帐号密码editbox失去输入焦点
			LogOn_Frame_OnHiden();
		end

	elseif g_AccountType == 2 then
		-- 退到服务器选择界面
		local strName = LogOn_MailID:GetText();
		local strPassword = LogOn_PassWord:GetText();
		local bMiBao = 0;
		local bUseHardwareMiBao = 0;
		local strHardwarePWD = "";
		if(Variable:GetVariable("System_CodePage") == "1258") then
			-- Dummy
		else
			bMiBao = LogOn_PassWord_Protect_Check:GetCheck();

		end

		if( strName =="" ) then
			return;
		end
		if( strPassword == "" ) then
			return;
		end


		GameProduceLogin:CheckAccount("", bMiBao, bUseHardwareMiBao,strHardwarePWD,2);

		if(bMiBao == 0) then
			--帐号密码editbox失去输入焦点
			LogOn_Frame_OnHiden();
		end
	end

	--无论何种方式登录，这个值都需要记录
	Variable:SetVariable("Account_LogonType", tostring(g_AccountType), 0);
end

--申请帐号
function LogOn_AccountReg()
    GameProduceLogin:StartAccountReg()
end
----------------------------------------------------------------------------------------------------------
--
-- id输入框失去焦点
--
function Logon_ID_TabPressed()

	if( g_bLogOnMode == 0 ) then
		LogOn_LogonPassWord_Active();
	end

end

function Logon_MailID_TabPressed()

	if( g_bLogOnMode == 0 ) then
		LogOn_LogonPassWord_Active();
	end

end

function Logon_LogOn_ID_Return()
	if g_AccountType == 1 then
		if(this:IsVisible() and (not IsWindowShow("LoginSelectServerQuest")) and (not IsWindowShow("FangChenMiRefuse"))) then
			LogOn_LogonPassWord_Active();
		end
	end
end

function Logon_LogOn_MailID_Return()
	if g_AccountType == 2 then
		if(this:IsVisible() and (not IsWindowShow("LoginSelectServerQuest")) and (not IsWindowShow("FangChenMiRefuse"))) then
			LogOn_LogonPassWord_Active();
		end
	end
end

----------------------------------------------------------------------------------------------------------
--
-- 密码输入框失去焦点
--
function Logon_Password_TabPressed()
	if( g_bLogOnMode == 0 ) then

		if g_AccountType == 1 then
			LogOn_LogonID_Active();
		elseif g_AccountType == 2 then
			LogOn_LogonMailID_Active()
		end
	end

end

function Logon_Password_Return()

	if(this:IsVisible() and (not IsWindowShow("LoginSelectServerQuest")) and (not IsWindowShow("FangChenMiRefuse"))) then
		LogOn_CheckAccount();
	end
end

--------------------------------------------------------------------------------
-------------------------- -- -- 帐号输入
function LogOn_ID_MouseEnter()

	LogOn_Info:SetText("#{DLJM_XML_44}");     --帐号  to  账号

end

----------------------------------------------------------------------------------------------------------
--
-- 密码输入框失去焦点
--
function LogOn_MouseLeave()

	LogOn_Info:SetText("");

end


function LogOn_PassWord_MouseEnter()

	LogOn_Info:SetText("#{DLJM_XML_45}");
end;

------------------------------------------------------------------------------------------------------
--
-- 账号后缀选择框
--
function LogOn_Region_MouseEnter()

	LogOn_Info:SetText("#{DLYH_091208_1}");

end;

------------------------------------------------------------------------------------------------------
--
-- 模拟键盘
--
function LogOn_KeyBoard()
	if GameProduceLogin:IsWeGameClient() > 0 then
		return
	end	
	
	ToggleWindow( "SoftKeyBoard" );
	SetSoftKeyAim( "LogOn_PassWord" );
end


function LogOn_Keyboard_MouseEnter()

	LogOn_Info:SetText("#{DLJM_XML_43}");  --帐号  to  账号

end


function LogOn_LogOnGame_MouseEnter()

	LogOn_Info:SetText("点击登入游戏");
end;

function LogOn_Payment_MouseEnter()

	LogOn_Info:SetText("为您的账号充值");  --帐号  to  账号
end

function LogOn_RequisitionID_MouseEnter()

	LogOn_Info:SetText("申请一个新账号");	--帐号  to  账号
end;

function LogOn_Author_MouseEnter()

	LogOn_Info:SetText("查看游戏开发团队信息");
end;

function LogOn_Last_MouseEnter()

	LogOn_Info:SetText("返回服务器选择列表");
end;

function LogOn_LogonID_Active()

	SetSoftKeyAim( "LogOn_ID" );
	LogOn_ID:SetProperty("DefaultEditBox", "True");
	LogOn_MailID:SetProperty("DefaultEditBox", "False");
	LogOn_PassWord:SetProperty("DefaultEditBox", "False");

	currentSoftKeyAim = 0;
	LastSoftKeyAimAfterHardware = currentSoftKeyAim;

	LogOn_UpdateCaplockTips()

end

function LogOn_LogonMailID_Active()

	SetSoftKeyAim( "LogOn_MailID" );
	LogOn_ID:SetProperty("DefaultEditBox", "False");
	LogOn_MailID:SetProperty("DefaultEditBox", "True");
	LogOn_PassWord:SetProperty("DefaultEditBox", "False");

	currentSoftKeyAim = 0;
	LastSoftKeyAimAfterHardware = currentSoftKeyAim;

	LogOn_UpdateCaplockTips()
end

function LogOn_LogonID_Deactive()

end

function LogOn_LogonMailID_TextChanged()
	local xPos1 = LogOn_Input_Background_Frame:GetProperty("AbsoluteXPosition")
	local yPos1 = LogOn_Input_Background_Frame:GetProperty("AbsoluteYPosition")

	local xPos2 = LogOn_MailID:GetProperty("AbsoluteXPosition")
	local yPos2 = LogOn_MailID:GetProperty("AbsoluteYPosition")

	local xPos3 = LogOn_Input_Background_SubFrame:GetProperty("AbsoluteXPosition")
	local yPos3 = LogOn_Input_Background_SubFrame:GetProperty("AbsoluteYPosition")

	local yHeigth = LogOn_MailID:GetProperty("AbsoluteHeight")

	local desPosx = xPos1 + xPos2 + xPos3
	local desPosy = yPos1 + yPos2 + yPos3 + yHeigth

	local strName = LogOn_MailID:GetText();
	local i = string.find(strName , "@")
	if i == nil and logonTailType~=1 then
		ShowDropMailList(strName , desPosx , desPosy )
	else
		ShowDropMailList("" , desPosx , desPosy )
	end
	logonTailType=0
end

function LogOn_LogonPassWord_Active()
	SetSoftKeyAim( "LogOn_PassWord" );
	LogOn_PassWord:SetProperty("DefaultEditBox", "True");
	LogOn_ID:SetProperty("DefaultEditBox", "False");
	LogOn_MailID:SetProperty("DefaultEditBox", "False");

	currentSoftKeyAim = 1;
	LastSoftKeyAimAfterHardware = currentSoftKeyAim;

	LogOn_UpdateCaplockTips()
end


function LogOn_Frame_OnHiden()
	LogOn_ID:SetProperty("DefaultEditBox", "False");
	LogOn_MailID:SetProperty("DefaultEditBox", "False");
	LogOn_PassWord:SetProperty("DefaultEditBox", "False");
end

function Logon_LogOn_Soft_Return()
	if( g_bLogOnMode == 1 ) then
		return;
	end
	if( currentSoftKeyAim == 1 ) then
		if g_AccountType == 1 then
			LogOn_LogonID_Active();
		elseif g_AccountType == 2 then
			LogOn_LogonMailID_Active()
		end
	else
		LogOn_LogonPassWord_Active();
	end

end

function Logon_LostPassWord()

	--Helper:GotoHelper("VedioCommonII" );
 		GameProduceLogin:OpenURL(GetWeblink("WEB_FORGOTPASSWORD"))
end

function LogOn_AccountChongZhi()

	if(Variable:GetVariable("System_CodePage") == "1258") then
    	GameProduceLogin:OpenURL(GetWeblink("WEB_LOGON_VN"))
	else
    	GameProduceLogin:OpenURL(GetWeblink("WEB_LOGON_MAIN"))
	end

end

function LogOn_Show_MibaoPage()
	--暂时越南版和中文版都指向同样的页面，越南版的同学有需要自己改
	if(Variable:GetVariable("System_CodePage") == "1258") then
    GameProduceLogin:OpenURL(GetWeblink("WEB_MIBAO"))
	else
    GameProduceLogin:OpenURL(GetWeblink("WEB_MIBAO"))
	end
end


function PassWordProtectCheckClicked()


	--local pwCheck = LogOn_PassWord_Protect_Check:GetCheck();
	--local phCheck = LogOn_Phone_Protect_Check:GetCheck();
	--if( pwCheck == 1 and phCheck == 1 ) then

	--	LogOn_PassWord_Protect_Check:SetCheck(1)
	--	LogOn_Phone_Protect_Check:SetCheck(0)

	--elseif( pwCheck == 1 and phCheck == 0 ) then

	--	LogOn_PassWord_Protect_Check:SetCheck(1)
	--	LogOn_Phone_Protect_Check:SetCheck(0)

	--elseif( pwCheck == 0 and phCheck == 1 ) then

	--	LogOn_PassWord_Protect_Check:SetCheck(1)
	--	LogOn_Phone_Protect_Check:SetCheck(0)

	--elseif( pwCheck == 0 and phCheck == 0 ) then

	--	LogOn_PassWord_Protect_Check:SetCheck(0)
	--	LogOn_Phone_Protect_Check:SetCheck(0)
	--end

	local pwCheck = LogOn_PassWord_Protect_Check:GetCheck();
	--local phCheck = LogOn_Phone_Protect_Check:GetCheck();


	if (pwCheck == 1) then
		-- LogOn_Phone_Protect_Check:SetCheck(0);

		if( LastSoftKeyAimAfterHardware ~= currentSoftKeyAim ) then
			if (LastSoftKeyAimAfterHardware == 1) then
				LogOn_LogonPassWord_Active();
			else
				if g_AccountType == 1 then
					LogOn_LogonID_Active();
				elseif g_AccountType == 2 then
					LogOn_LogonMailID_Active()
				end
			end
		end
	end
end

function LogOn_MibaoSetToolTip()
	local strStart = "#{DHMB_081014_001_1}"
	local strCat = "#{WENZI_HUO}"
	local strEnd = "#{DHMB_081014_001_2}"
	local strTmp = strStart
	local strMid = ""
	local i = 0
	for i=1,MiBaoDhCount do
		if ( MiBaoDhCount > 1 and i < MiBaoDhCount) then
			strMid = PasswdProctectTels[i]..","
		elseif ( i == MiBaoDhCount and i ~= 1) then
			strMid = strCat.. PasswdProctectTels[i];
	    else
	        strMid = PasswdProctectTels[i];
		end
		strTmp = strTmp..strMid;

	end
	strTmp = strTmp..strEnd
	-- LogOn_Phone_Protect_Text:SetProperty("Tooltip", strTmp); --这个不能转义
	--LogOn_Phone_Protect_Text:SetToolTip(strTmp);
end

function LogOn_MibaoShowSystemInfo()
	local strStart = "#{DHMB_081014_003_1}"
	local strCat = "#{WENZI_HUO}"
	local strEnd = "#{DHMB_081014_003_2}"
	local strTmp = strStart
	local strMid = ""
	local i = 0
	for i=1,MiBaoDhCount do
		if ( MiBaoDhCount > 1 and i < MiBaoDhCount) then
			strMid = PasswdProctectTels[i]..","
		elseif ( i == MiBaoDhCount and i ~= 1) then
			strMid = strCat.. PasswdProctectTels[i];
	    else
	        strMid = PasswdProctectTels[i];
		end
		strTmp = strTmp..strMid;

	end
	strTmp = strTmp..strEnd
	GameProduceLogin:GameLoginShowSystemInfo(strTmp);
end

function LogOn_TraditionLogon_MouseDown()
	if GameProduceLogin:IsWeGameClient() > 0 then
		return
	end	
	if g_AccountType == 1 then
		return
	end
	g_AccountType = 1

	LogOn_OwnDefineLogon:SetCheck(0)
	LogOn_MailID:Hide()

	if SystemSetup:IsClassic() == 1 then
		LogOn_MailID_Text:Hide()
		LogOn_ID_Text:Show()
		LogOn_Region_Text:Show()
	end

	LogOn_ID:Show()
	LogOn_Region:Show()

	LogOn_ID:SetText("")
	--LogOn_ID:SetText( LogOn_MailID:GetText() )

	LogOn_LogonID_Active()
	LogOn_PassWord:SetText("");


	local strTail, nIndex = LogOn_Region:GetCurrentSelect();
	if nIndex == 7 then
		LogOn_Region:SetCurrentSelect(0);
	end

	OtherLogon_Frame_ElseLogon:Hide();
	OtherLogon_NewLogon:Hide();
	LogOn_TiShi:Hide()
end

function LogOn_OwnDefineLogon_MouseDown()
	if g_AccountType == 3 then
		return
	end
	if g_AccountType == 2 then
		return
	end
	g_AccountType = 2

	LogOn_TraditionLogon:SetCheck(0)
	LogOn_ID:Hide()
	LogOn_Region:Hide()
	if SystemSetup:IsClassic() == 1 then
		LogOn_ID_Text:Hide()
		LogOn_Region_Text:Hide()
		LogOn_MailID_Text:Show()
	end
	LogOn_MailID:Show()
	LogOn_MailID:SetText("")
	--LogOn_MailID:SetText( LogOn_ID:GetText() )


	LogOn_LogonMailID_Active()
	LogOn_PassWord:SetText("");

	OtherLogon_Frame_ElseLogon:Hide();
	OtherLogon_NewLogon:Hide();
	LogOn_TiShi:Show()
end

function LogOn_Region_Accept()
	local strTail, nIndex = LogOn_Region:GetCurrentSelect();
	if nIndex == 7 then
		LogOn_OwnDefineLogon:SetCheck(1)
		LogOn_OwnDefineLogon_MouseDown()
	end
end

function LogOn_TiShi_Clicked()

	LogOn_TraditionLogon_MouseDown()
	LogOn_TraditionLogon:SetCheck(1)
	LogOn_LogonID_Active();

end

--打开二维码登录界面 wangbin 2014-06-03
function LogOn_ErweimaLogon_MouseDown()
	LogOn_TraditionLogon_MouseDown()
	LogOn_TraditionLogon:SetCheck(1)
	LogOn_LogonID_Active();
	GameProduceLogin:StartQRCode()
	LogOn_PassWord:SetText("");
	LogOn_ID:SetText("");
	LogOn_MailID:SetText("");
end

function LogOn_KillCaplockTips()
	LogOn_CapsLock1:Hide()
	LogOn_CapsLock2:Hide()
end

function LogOn_UpdateCaplockTips()
	LogOn_KillCaplockTips()
	if GameProduceLogin:IsWeGameClient() > 0 then
		return
	end
	if GetCaplockStatus() ~= 1 then
		return
	end
	if GetActiveInput() == "LogOn_PassWord" then
		LogOn_CapsLock2:Show()
	elseif GetActiveInput() == "LogOn_ID" or GetActiveInput() == "LogOn_MailID" then
		LogOn_CapsLock1:Show()
	end
end
