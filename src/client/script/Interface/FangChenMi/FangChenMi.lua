FangChenMi_Status = {}
FangChenMi_Status[1]  = {tip = "#{FCM1_90408_1}", enable = 0} --I阶段添实名
FangChenMi_Status[2]  = {tip = "#{FCM1_90408_2}", enable = 1} --I阶段未添实名
FangChenMi_Status[3]  = {tip = "#{FCM2_90408_1}", enable = 0} --II阶段小于18
FangChenMi_Status[4]  = {tip = "#{FCM2_90408_3}", enable = 1} --II阶段未添实名
FangChenMi_Status[5]  = {tip = "#{FCM2_90408_2}", enable = 0} --II阶段初步认定大于18
FangChenMi_Status[6]  = {tip = "#{FCM2_90408_2}", enable = 0} --II填写了实名
FangChenMi_Status[7]  = {tip = "#{FCM3_90408_4}", enable = 0} --III阶段小于18
FangChenMi_Status[8]  = {tip = "#{FCM3_90408_5}", enable = 1} --III阶段未添实名
FangChenMi_Status[9]  = {tip = "#{FCM3_90408_2}", enable = 0} --III阶段初步认定大于18
FangChenMi_Status[10]  = {tip = "#{FCM3_90408_3}", enable = 0} --III阶段审核认定大于18
FangChenMi_Status[11] = {tip = "#{FCM3_90408_1}", enable = 0} --III阶段审核认定无效实名
FangChenMi_Status[12]  = {tip = "#{FCM3_90408_1}", enable = 0} --III阶段填写了实名

function FangChenMi_PreLoad()
	this:RegisterEvent("OPEN_FANGCHENGMI_DLG",true);
	this:RegisterEvent("GAMELOGIN_OPEN_COUNT_INPUT",false);
	this:RegisterEvent("NET_HAS_CLOSED",false);
	this:RegisterEvent("CONFIRM_FANGCHENMI",false);
end

function FangChenMi_OnLoad()
end

-- OnEvent
function FangChenMi_OnEvent(event)
	if( event == "OPEN_FANGCHENGMI_DLG" ) then
		local haveMibao = tonumber(arg0);
		local haveShiming = tonumber(arg1);
		--PushDebugMessage("haveMibao=".. haveMibao)
		--czf modify 2010-7
		--=====================================
			-- 这样客户端界面根据safeLevel的值来判断绑定了什么，0 —— 4 是个完备集
			-- (0) 0 ：什么都没绑定
			-- (1) 1：密保卡  ASF_BIND_MIBAOKA 占INT的0号位 ——  2^0 == 1
			-- (2) 2：电话密保  ASF_BIND_PHONE_MIBAO 占INT的1号位 —— 2^1 == 2
			-- (3) 4：硬件密保（贴身密保）ASF_BIND_HARDWARE_MIBAO 占INT的2号位 —— 2^2 == 4

			-- (4) 3：=1+2，密保卡、电话密保
			-- (5) 5：=1+4，密保卡、硬件密保
			-- (6) 6：=2+4，电话密保、硬件密保
			-- (7) 7：=1+2=4，密保卡、电话密保、硬件密保
		--=========================================
		if(haveMibao == 1)then
			--您已使用了密保卡绑定服务。请妥善保管好你的密保卡，祝你游戏愉快。
			FangChenMi_MiBaoKa_Text : SetText("#{DHMB_0711_08}");
			FangChenMi_MiBaoKa : Disable()
		elseif(haveMibao == 8) then
			--仅开通了常有助手
			FangChenMi_MiBaoKa_Text : SetText("#{ZZB_131213_28}");
			FangChenMi_MiBaoKa	: Enable()
		elseif(haveMibao == 9 ) then
			FangChenMi_MiBaoKa_Text : SetText("#{ZZB_131213_28}");
			FangChenMi_MiBaoKa	: Disable()
		else
			--您的账号尚未开通免费的电话密保绑定功能。为避免您的账号被盗或游戏财产被恶意侵占等意外情况的发生，强烈建议您登陆sde.sohu.game.com开通电话密保绑定服务。电话密保绑定与密保卡绑定不能同时使用，建议您使用电话密保的同时使用电脑绑定，提高账号安全系数。
			FangChenMi_MiBaoKa_Text : SetText("#{YJMB_090116_015}");
			FangChenMi_MiBaoKa	: Enable()
		end
		--czf modify end
		--=========================================
		
--		if(haveShiming == 1)then
--			--您的帐号已填写用户真实姓名与身份证号码信息，祝您游戏愉快。
--			FangChenMi_Info_Text : SetText("#{Interface_FangChenMi_txt8}");
--			FangChenMi_Info	: Disable()
--		else
--			--注意！您的帐号尚未填写用户真实姓名与身份证号码信息，有可能会被纳入#cff0000防沉迷系统#Y而#cff0000无法正常获得游戏收益#Y。为了确保您能正常进行游戏，我们强烈建议您登录天龙八部官方网站填写您的用户真实姓名与身份证号码信息。
--			FangChenMi_Info_Text : SetText("#{Interface_FangChenMi_txt7}");
--			FangChenMi_Info	: Enable()
--		end
--		
--		-- 紧急修改，由于外网还没有开通此项服务，先关闭 刘盾 2008.7.30
--		--FangChenMi_MiBaoKa : Disable()
		FangChenMi_Info_Text : SetText(FangChenMi_Status[haveShiming].tip);
		if (FangChenMi_Status[haveShiming].enable == 1) then
			FangChenMi_Info	: Enable();
		else
		  FangChenMi_Info	: Disable();
		end
		
		-- 紧急修改，由于外网还没有开通此项服务，先关闭 刘盾 2008.7.30
		--FangChenMi_MiBaoKa : Disable()
		
		this : Show();
	elseif( event == "GAMELOGIN_OPEN_COUNT_INPUT" ) then
		this : Hide();
	elseif( event == "NET_HAS_CLOSED" ) then
		this : Hide();
	elseif (event == "CONFIRM_FANGCHENMI") then
	    FangChenMi_Accept_Clicked();
	end
end

--同意
function FangChenMi_Accept_Clicked()
	SendSafeSignMsg();
	this : Hide();
end

--去密报卡网站
function FangChenMi_MiBaoKa_Clicked()
	if(Variable:GetVariable("System_CodePage") == "1258") then
		--do nothing
	else
		GameProduceLogin:OpenURL(GetWeblink("WEB_MIBAO_TL"))
	end
end

--去实名认证网站
function FangChenMi_Info_Clicked()
	if(Variable:GetVariable("System_CodePage") == "1258") then
		--do nothing
	else
    GameProduceLogin:OpenURL(GetWeblink("WEB_FANGCHENMI"))
	end
end

function FangChenMi_Close_Clicked()
	-- Do Nothing
end

function FangChenMi_SetMibaokaText()
	local PasswdProctectTels = {"",""}
	local strStart = "#{DHMB_081014_002_1}"
	local strCat = "#{WENZI_HUO}"
	local strEnd = "#{DHMB_081014_002_2}"
	local strTmp = strStart
	local strMid = ""
	local i = 0
	
	-- 从配置文件里随机取3个电话
	--math.randomseed(os.time() + 2);
	math.random(0,100);math.random(0,100)
	local arrIdx = {-1,-1,-1};
	local MAX_TEL_SHOWCOUNT = 3
	local MiBaoDhCount = 0
	local iGetCount = 0
	MiBaoDhCount = GameProduceLogin:GetPasswdTelCount();
	if( MiBaoDhCount <= 0 or MiBaoDhCount > 5000 ) then
		return; --密保电话数量有问题直接用原来的电话
	end
	while (iGetCount < MiBaoDhCount and iGetCount < MAX_TEL_SHOWCOUNT) do
		local iTmpIdx = math.random(0,MiBaoDhCount-1);
		local bExitIdx = 0;
		for i = 1, iGetCount do
			if (arrIdx[i] == iTmpIdx) then
				bExitIdx = 1;
				break;
			end;
		end;
		if ( 1 ~= bExitIdx ) then
		    iGetCount = iGetCount + 1;
			arrIdx[iGetCount] = iTmpIdx;
		end;
	end;
	
	if (MiBaoDhCount > MAX_TEL_SHOWCOUNT) then --考虑到提示框大小， 密保电话数量限定为3个
		MiBaoDhCount = MAX_TEL_SHOWCOUNT
	end
	
	for i=1,MiBaoDhCount do
		--local strTel = GameProduceLogin:GetPasswdTelByIndex(i - 1);
		local strTel = GameProduceLogin:GetPasswdTelByIndex(arrIdx[i]);
		PasswdProctectTels[i] = strTel;
	end
	
	for i=1,MiBaoDhCount do
		if ( MiBaoDhCount > 1 and i < MiBaoDhCount) then
			strMid = PasswdProctectTels[i]..","
		elseif ( i == MiBaoDhCount ) then
			strMid = strCat.. PasswdProctectTels[i];
	    else
	        strMid = PasswdProctectTels[i];
		end	
		strTmp = strTmp..strMid;	
	end
	strTmp = strTmp..strEnd
	FangChenMi_MiBaoKa_Text : SetText(strTmp);
end




function FangChenMi_Changyoujia_Clicked()
	if(Variable:GetVariable("System_CodePage") == "1258") then
		--do nothing
	else
		GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_ZZB"))
	end
end


