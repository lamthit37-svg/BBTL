--安全验证界面-- Manda 2013-8-3

----------------------二级密码相关------------------
local g_CurrectOperate = 0;  --1为pk状态切换需要的输入窗口. 2为打开银行时候需要的输出窗口
local g_PKModeWant = 0;  --1为pk状态切换需要的输入窗口.
----------------------------------------------------

-----------------------电话密保相关-----------------
-- 保存LoginServer.txt文件中密保电话的数目
local MiBaoDhCount = 0
-- 保存LoginServer.txt文件中密保电话分区的数目
local GroupNum = 0
-- 界面显示的密保电话号码数目
local MiBaoPhoneCount = 6
-- 用于界面显示密保电话号码的控件数组
local MiBaoTextCtrl = {};
-- LoginServer.txt文件中全部密保电话索引的数组，但实际只从[0,GroupNum-1]中选出6组，每组1个。
local MiBaoGroupAndIndex = {};
-- 用于界面显示的6个密保电话号码数组
local PasswdProctectTels = {};
--用于保存密保电话区域名称
local MiBaoGroupArea = {};
--用于保存密保电话区域的权重
local MiBaoGroupWeight = {};

local g_LastLockTime = 0 --电话倒计时
--local g_LastLockTime_AppMibao = 0 --掌中宝倒计时
--local g_LastLockTime_HardWareMiBao  = 0 --贴身倒计时


--标记 使用的是贴身密保(掌中宝)
--用于掌中宝和硬件密保的公共界面

--local g_CurrentCheckTimes = 0
----------------------------------------------------


function SafeCenter_SafeCheck_PreLoad()
	this:RegisterEvent("OPEN_SAFECENTER_SAFECHECK");

	--硬件/贴身密报
	this:RegisterEvent("OPEN_SAFECENTER_HARDWARE");

	--验证电话密保
	this:RegisterEvent("OPEN_WINDOW");
	this:RegisterEvent("OPEN_DIANHUAMIBO_TIPS")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false);
	--this:RegisterEvent("CLEANUP_TIME_TICK");
	
	--二级密码验证
	this:RegisterEvent("MINORPASSWORD_OPEN_UNLOCK_PASSWORD_DLG")
	this:RegisterEvent("OPENINPUTPASSWORD_PKVERIFY")
	this:RegisterEvent("OPENINPUTPASSWORD_BANKVERIFY")

	--（硬件密保、掌中宝）UI进入CD
	this:RegisterEvent("FRESHLASTTICKTIME")
	-- 游戏界面尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false);
    -- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("APPCHECK_SUCCESS")
	this:RegisterEvent("APPCHECK_FAIL")
	this:RegisterEvent("APPCHECK_CLICK")
	   
end

function SafeCenter_SafeCheck_OnEvent(event)

	if ( event == "OPEN_SAFECENTER_SAFECHECK") then
		if( this:IsVisible() ) then
			return
		else
			SafeCenter_SafeCheck_Open()
		end

	--硬件密保
	elseif(event == "OPEN_SAFECENTER_HARDWARE") then
		SafeCenter_SafeCheck_OpenCheckHardMibaoFrame()

	--电话密保	
	elseif(event == "OPEN_WINDOW" ) then
		if( arg0 == "TelMibaoTishi") then
		SafeCenter_SafeCheck_OpenCheckPhoneMibaoFrame();
		end

	--打开电话密保验证框
	elseif(event == "OPEN_DIANHUAMIBO_TIPS" ) then
		SafeCenter_SafeCheck_OpenCheckPhoneMibaoFrame();

	--关闭电话密保框
	elseif (event == "HIDE_ON_SCENE_TRANSED")  then
		this:IsVisible()			
		SafeCenter_SafeCheck_TelMibaoTishi_Close();
	--elseif (event == "CLEANUP_TIME_TICK") then

	
	-- 打开二级密码解锁界面		
	elseif (event == "MINORPASSWORD_OPEN_UNLOCK_PASSWORD_DLG") then
		g_CurrectOperate = 0
		SafeCenter_SafeCheck_OpenCheckMinorPwdFrame()

	-- 打开二级密码解锁界面	
	elseif (event == "OPENINPUTPASSWORD_PKVERIFY") then
		g_PKModeWant = tonumber(arg0);
		g_CurrectOperate = 1
		SafeCenter_SafeCheck_OpenCheckMinorPwdFrame()

	-- 打开二级密码解锁界面
	elseif (event == "OPENINPUTPASSWORD_BANKVERIFY") then
		g_CurrectOperate = 2
		SafeCenter_SafeCheck_OpenCheckMinorPwdFrame()
		
	elseif(event == "FRESHLASTTICKTIME") then
		SafeCenter_SafeCheck_Mibao_CD_Begin()
	-- 游戏窗口尺寸发生了变化
	elseif (event == "ADJEST_UI_POS" ) then
	    SafeCenter_SafeCheck_Frame_On_ResetPos();

	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED" ) then
		SafeCenter_SafeCheck_Frame_On_ResetPos();
	elseif (event == "APPCHECK_SUCCESS" ) then
		SafeCenter_SafeCheck_Open()
	elseif (event == "APPCHECK_FAIL" ) then
		SafeCenter_SafeCheck_Frame6_ZZBCheckButton2_Text_StopWatch:SetProperty("Timer", "0");
		SafeCenter_SafeCheck_KuaiJieButton()		
	elseif (event == "APPCHECK_CLICK" ) then
		SafeCenter_SafeCheck_FastCheck_ClickOK()
	end

end

function SafeCenter_SafeCheck_OnLoad()
	-- 保存界面的默认相对位置
	g_SafeCenter_SafeCheck_Frame_UnifiedXPosition	= SafeCenter_SafeCheck_Frame : GetProperty("UnifiedXPosition");
	g_SafeCenter_SafeCheck_Frame_UnifiedYPosition	= SafeCenter_SafeCheck_Frame : GetProperty("UnifiedYPosition");


	--初始化6个电话密保控件
	MiBaoTextCtrl = {	SafeCenter_SafeCheck_Tel_Number1;
										SafeCenter_SafeCheck_Tel_Number2;
										SafeCenter_SafeCheck_Tel_Number3;
										SafeCenter_SafeCheck_Tel_Number4;
										SafeCenter_SafeCheck_Tel_Number5;
										SafeCenter_SafeCheck_Tel_Number6;
									}

	-- 设置密保电话数组索引和电话号码初始值
	SafeCenter_SafeCheck_TelMibaoTishi_ResetIndexAndTel();

end

--===============================================
-- 					界面切换
--===============================================

function SafeCenter_SafeCheck_OpenSafeScore()  --安全中心的起始界面(也就是安全评分界面)
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafeCheck_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeScore();
end

function SafeCenter_SafeCheck_OpenSafePattern() --安全模式界面
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafeCheck_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafePattern();
end

function SafeCenter_SafeCheck_OpenMobilePhone()  --手机验证界面
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafeCheck_Frame:GetProperty("UnifiedPosition"), 1);
      OpenMobilePhone();
end

function SafeCenter_SafeCheck_OpenSafeTime()  --安全时间界面
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafeCheck_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSafeTime();
end

function SafeCenter_SafeCheck_OpenAccountProtection()  --账号密保界面
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafeCheck_Frame:GetProperty("UnifiedPosition"), 1);
      OpenAccountProtection();
end

function SafeCenter_SafeCheck_OpenSecondPassword()  --二级密码
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafeCheck_Frame:GetProperty("UnifiedPosition"), 1);
      OpenSecondPassword();
end

function SafeCenter_SafeCheck_Open()  --安全验证

	if GameProduceLogin:IsWeGameClient() > 0 then
		return
	end

	if GameProduceLogin:IsWeGameClient() > 0 then
		SafeCenter_SafeCheck_WeGame_BackgroundRight_Frame:Show()
		SafeCenter_SafeCheck_BackgroundRight_Frame:Hide();
	else
		SafeCenter_SafeCheck_WeGame_BackgroundRight_Frame:Hide()
		SafeCenter_SafeCheck_BackgroundRight_Frame:Show();
	end
	  
	  SafeCenter_SafeCheck_CloseOthers()
	  SafeCenter_SafeCheck_Update();
      SafeCenter_SafeCheck_Update_ButtonSelectedAndFrame();
      SafeCenter_SafeCheck_MainButton_SafeCheck:SetProperty("Selected", "True");
	  SafeCenter_SafeCheck_MainButton_SafeCheck:SetProperty("RiseOnClick", "Flase");
	  SafeCenter_SafeCheck_StateOfSafeIsOk() --验证安全验证是否通过
	  this:Show();

end

function SafeCenter_SafeCheck_OpenLockUnlock()  --加锁解锁
      Variable:SetVariable("SelfUnionPos", SafeCenter_SafeCheck_Frame:GetProperty("UnifiedPosition"), 1);
      OpenLockUnlock();
end

----------------------------------------------

--按键更新、无论是否开着。关闭之前安全中心界面
function SafeCenter_SafeCheck_Update_ButtonSelectedAndFrame()

	 SafeCenter_SafeCheck_MainButton_SafeScore:SetProperty("Selected", "False");
	 SafeCenter_SafeCheck_MainButton_SafePattern:SetProperty("Selected", "False");
	 SafeCenter_SafeCheck_MainButton_MobilePhone:SetProperty("Selected", "False");
	 SafeCenter_SafeCheck_MainButton_SafeTime:SetProperty("Selected", "False");
	 SafeCenter_SafeCheck_MainButton_AccountProtection:SetProperty("Selected", "False");
	 SafeCenter_SafeCheck_MainButton_SecondPassword:SetProperty("Selected", "False");
	 SafeCenter_SafeCheck_MainButton_SafeCheck:SetProperty("Selected", "False");
	 SafeCenter_SafeCheck_MainButton_LockUnlock:SetProperty("Selected", "False");

end

--安全验证通过 :UI --》 Client进行判断 --》通过事件调用相应的响应事件
function SafeCenter_SafeCheck_StateOfSafeIsOk( )

	local isSetMinorPwd = IsMinorPwdSetup();  
	local isHaveAppProtected = IsAppWareProtectSetup()
	
	if CheckPlayerAccountSafety() == 1 then

		SafeCenter_SafeCheck_Frame6_DefaultWindowNoCheck:SetProperty("Visible" , "True" )
		SafeCenter_SafeCheck_Frame6_DefaultWindowZZB:SetProperty("Visible" , "False" )
		SafeCenter_SafeCheck_Frame6_DefaultWindow:SetProperty("Visible" , "False" )

		if( isSetMinorPwd ~= 1) and (isHaveAppProtected ~= 1) then
			SafeCenter_SafeCheck_Frame6_NoCheckButton1:SetText( "#{AQZX_130812_60}"  )
			SafeCenter_SafeCheck_Frame6_NoCheckButton2:SetText( "#{AQZX_130812_61}"  )

		elseif (isHaveAppProtected == 1)then
			SafeCenter_SafeCheck_Frame6_NoCheckButton1:SetText( "#{ZZB_131213_05}"  )
			SafeCenter_SafeCheck_Frame6_NoCheckButton2:SetText( "#{AQZX_130812_63}"  )					
			
		elseif( isSetMinorPwd == 1 ) then
			SafeCenter_SafeCheck_Frame6_NoCheckButton1:SetText( "#{AQZX_130812_83}"  )
			SafeCenter_SafeCheck_Frame6_NoCheckButton2:SetText( "#{AQZX_130812_63}"  )
		end

	end

end

function SafeCenter_SafeCheck_Close()

	Variable:SetVariable("SelfUnionPos", SafeCenter_SafeCheck_Frame:GetProperty("UnifiedPosition"), 1);
	SafeCenter_SafeCheck_TelMibaoTishi_ResetIndexAndTel();--TelPhoneInit
	this:Hide();

end

--===============================================
-- 				贴身密保、掌中宝
--===============================================
function SafeCenter_SafeCheck_OpenCheckHardMibaoFrame()

	SafeCenter_SafeCheck_CloseOthers()
	SafeCenter_SafeCheck_Update()

	local bHaveAppProtected = IsAppWareProtectSetup();
	
	SafeCenter_SafeCheck_Frame6_DefaultWindowZZB:SetProperty("Visible" , "True" )
	SafeCenter_SafeCheck_Frame6_DefaultWindow:SetProperty("Visible" , "False" )
	SafeCenter_SafeCheck_Frame6_DefaultWindowNoCheck:SetProperty("Visible" , "False" )
	
	SafeCenter_SafeCheck_Update_ButtonSelectedAndFrame();
	SafeCenter_SafeCheck_MainButton_SafeCheck:SetProperty("Selected", "True");
	SafeCenter_SafeCheck_MainButton_SafeCheck:SetProperty("RiseOnClick", "Flase");

	--只有掌中宝的情况
	if bHaveAppProtected == 1 then
		
		SafeCenter_SafeCheck_Frame6_ZZBCheckText:SetProperty("Visible", "True")
		SafeCenter_SafeCheck_Frame6_ZZBLace2:SetProperty("Visible", "True")
		SafeCenter_SafeCheck_Frame6_ZZBLace4:SetText("#{AQZX_130812_64}")
		SafeCenter_SafeCheck_Frame6_ZZBCheckText:SetText("")
		 SafeCenter_SafeCheck_KuaiJieButton()
	end

	this:Show()



end

--贴身 点击Ok
function SafeCenter_SafeCheck_HardMibaoCheck_OK_Click()

end

--掌中宝 点击Ok
function SafeCenter_SafeCheck_AppWare_OK_Click()

	local strAppWareMibaoPassword = SafeCenter_SafeCheck_Frame6_ZZBCheckText:GetText();

	local bHaveAppProtected = IsAppWareProtectSetup();
	

	local str = ""
	str = tostring(strAppWareMibaoPassword)

	local ret = string.len(str)

	--掌中 begin
	if(ret <= 0 ) then

		PushDebugMessage("#{ZZB_131213_14}")  	
		this:Hide()	
  		return
	end

	if(ret < 6 ) then
		PushDebugMessage("#{ZZB_131213_15}");
		this:Hide()
		return
	end

	if(bHaveAppProtected ~= 1 )	then
		PushDebugMessage("#{ZZB_131213_13}")
		this:Hide()
		return
	end
	--掌中 end

	AccountSafe:SendAppWareCheckMsg(str)

	this:Hide()

end

--掌中宝恢复
function SafeCenter_SafeCheck_AppWare_TimeReach()

	SafeCenter_SafeCheck_Frame6_ZZBCheckButton:Enable()
	SafeCenter_SafeCheck_ZZBTip_Text_Window:SetProperty("Visible", "False");
	SafeCenter_SafeCheck_Frame6_ZZBCheckButton2:Enable()

	--g_CurrentCheckTimes = 0
	--DataPool:SetCurrentCheckTimes(g_CurrentCheckTimes)
end
--密保 设置冷却
function SafeCenter_SafeCheck_Mibao_CD_Begin()

	local isHaveAppProtected = IsAppWareProtectSetup()

	if isHaveAppProtected == 1 then
		SafeCenter_SafeCheck_Frame6_ZZBCheckButton:SetProperty("Disabled", "True"); 
		SafeCenter_SafeCheck_ZZBTip_Text_Window:SetProperty("Visible", "True");
		SafeCenter_SafeCheck_SafeCheck_ZZBTip_Text_StopWatch:SetProperty("Timer",tostring(120));
		SafeCenter_SafeCheck_Frame6_ZZBCheckButton2:SetProperty("Disabled", "True"); 	
	end

end

--===============================================
-- 					电话密保
--===============================================
--验证电话密保
function SafeCenter_SafeCheck_OpenCheckPhoneMibaoFrame()

	-- 界面显示
	SafeCenter_SafeCheck_CloseOthers()
	SafeCenter_SafeCheck_Update()
  	Variable:SetVariable("SelfUnionPos", SafeCenter_SafeCheck_Frame:GetProperty("UnifiedPosition"), 1);
	this:Show()
	SafeCenter_SafeCheck_Frame6_Button4:SetProperty("Disabled", "False");	 --当冷却时间的时候，回复按钮到正常
	SafeCenter_SafeCheck_TelMibaoTip_Text_Window:SetProperty("Visible", "False");
	SafeCenter_SafeCheck_Update_ButtonSelectedAndFrame();
	SafeCenter_SafeCheck_MainButton_SafeCheck:SetProperty("Selected", "True");
	SafeCenter_SafeCheck_MainButton_SafeCheck:SetProperty("RiseOnClick", "Flase");
	SafeCenter_SafeCheck_Frame6_Button1:SetText( "#{AQZX_130812_76}"  )
	SafeCenter_SafeCheck_Frame6_Button2:SetText( "#{AQZX_130812_64}"  )
	SafeCenter_SafeCheck_Frame6_DefaultWindow2:SetProperty("Visible" , "True" )
	SafeCenter_SafeCheck_Frame6_DefaultWindow3:SetProperty("Visible" , "False" )

	--将掌中宝and贴身密保界面关掉
	SafeCenter_SafeCheck_Frame6_DefaultWindowZZB:SetProperty("Visible" , "False" )
	SafeCenter_SafeCheck_Frame6_DefaultWindowNoCheck:SetProperty("Visible" , "False" )
	SafeCenter_SafeCheck_Frame6_DefaultWindow:SetProperty("Visible" , "True" )	

	-- 代码逻辑
	local nNowTickCount = Exchange:GetTickCount();

	if(g_LastLockTime >0 and (nNowTickCount - g_LastLockTime) < 120*1000) then
			PushDebugMessage("#{DHMB_90417_7}");
			SafeCenter_SafeCheck_Frame6_Button4:SetProperty("Disabled", "True");	 --当冷却时间的时候，需要将验证按钮设置成灰色
			SafeCenter_SafeCheck_TelMibaoTip_Text_Window:SetProperty("Visible", "True");
			local odd_time = (120 * 1000 - nNowTickCount + g_LastLockTime)/1000
			SafeCenter_SafeCheck_StopTime2_Text:SetProperty("Timer",tostring(odd_time));
		return
	end


	-- 得到全部密保电话的数目
	MiBaoDhCount = GameProduceLogin:GetPasswdTelCount();

	--判断是否在LoginServer.txt里定义了电话密保号码。
	if (MiBaoDhCount > 0) then
		SafeCenter_SafeCheck_TelMibaoTishi_ResetIndexAndTel();
		this:Show();
		SafeCenter_SafeCheck_TelMibaoTishi_SetRandomTelNum();				-- 设置随机显示的电话密保号码
	else
		OpenWindow("TelMiBaoErrMsg");						-- 打开电话密保的错误提示界面
		this:Hide();
	end

end

-- 设置密保电话数组索引和电话号码初始值
function SafeCenter_SafeCheck_TelMibaoTishi_ResetIndexAndTel()

	-- 设置下面将要得到的密保电话字符串的初值
	for i=1,MiBaoPhoneCount do
		PasswdProctectTels[i] = ""
	end

	-- 初始化密保电话分组索引和具体索引
	for i=1,MiBaoPhoneCount do
		MiBaoGroupAndIndex[i]={}
		MiBaoGroupAndIndex[i].group = -1
		MiBaoGroupAndIndex[i].index = -1
	end

end

function SafeCenter_SafeCheck_TelMibaoTishi_Close( )
	-- body
	SafeCenter_SafeCheck_TelMibaoTishi_ResetIndexAndTel();
	SafeCenter_SafeCheck_StopTime2_Text:SetProperty("Timer",0);
	this:Hide();
end

-- 设置随机显示的电话密保号码(新规则)
function SafeCenter_SafeCheck_TelMibaoTishi_SetRandomTelNum()

	-- 设置密保电话数组索引和电话号码初始值
	SafeCenter_SafeCheck_TelMibaoTishi_ResetIndexAndTel();

	-- 得到电话地区分区的数目
	GroupNum = GameProduceLogin:GetPasswdTelLDCodeGroupCount();

	--密保电话区域权重总和
	local iWeightSum = 0;
	--用于保存区域权重不为零的有效区域
	local MiBaoValidArea = {};
	--有效区域的总数
	local ValidGroupNum = 0;

	-- 得到每个地区的权重
	for i = 0, GroupNum-1 do
		MiBaoGroupArea[i] = GameProduceLogin:GetPasswdTelAreaByGroupIndex(i);
		MiBaoGroupWeight[i] = GameProduceLogin:GetPasswdTelWeightByArea(MiBaoGroupArea[i])*100;    --乘以100
		if (MiBaoGroupWeight[i] >0) then
			MiBaoValidArea[ValidGroupNum] = i;
			ValidGroupNum = ValidGroupNum+1;
		end
		--得到所有地区权重总和
		iWeightSum = iWeightSum + MiBaoGroupWeight[i];
	end

	--如果权重总和为0
	if ( iWeightSum == 0) then
		this:Hide();
		OpenWindow("TelMiBaoErrMsg");						-- 打开电话密保的错误提示界面
		return;
	end

	--有效密保电话号码总数
	local ValidTelNum = 0;
	-- 得到每个有效地区电话号码的数目
	local ValidGroupSize = {};
	for i = 0, ValidGroupNum-1 do
		ValidGroupSize[i] = GameProduceLogin:GetPasswdTelCountByLDCodeGroupIndex(MiBaoValidArea[i]);
		for j = 0,ValidGroupSize[i]-1 do
			ValidTelNum = ValidTelNum + 1;
			MiBaoGroupAndIndex[ValidTelNum].group = MiBaoValidArea[i];
			MiBaoGroupAndIndex[ValidTelNum].index = j;
		end
	end

	-- 如果LoginServer.txt文件中配置了密保电话（如果没有配置密保，在调用该函数前已经做过了判断，所以不用考虑这种情况。）
	if( MiBaoDhCount > 0 ) then
		-- 如果有效密保电话的数目大于等于6个
		if( ValidTelNum >= MiBaoPhoneCount) then
			-- 得到每个地区电话号码的数目
			local iGroupSize = {};
			for i = 0, GroupNum-1 do
				iGroupSize[i] = GameProduceLogin:GetPasswdTelCountByLDCodeGroupIndex(i);
			end

			local iGetCount = 0;     --获得号码数目
			while (iGetCount < MiBaoPhoneCount) do
				--取第6个号码时，发现前5个号码都是同一地区，并且权重大于零的地区数量>=2个，则选择不同地区密保电话
				local bChangeArea = 0;
				if (iGetCount == MiBaoPhoneCount-1 and ValidGroupNum >= 2) then
					local index = 1;
					while (index < MiBaoPhoneCount) and ( MiBaoGroupAndIndex[index].group == MiBaoGroupAndIndex[1].group) do
						index = index + 1;
					end
					--如果前5个号码全是同一地区
					if (index == MiBaoPhoneCount) then
						bChangeArea = 1;
					end
				end

				--在[1,g_WeightSum]之间取一个随机数
				local num = math.random(1,iWeightSum);
				for j = 0,GroupNum-1 do
					if( num > SafeCenter_SafeCheck_TelMibaoTishi_AddWeight(j) and num <= SafeCenter_SafeCheck_TelMibaoTishi_AddWeight(j+1)) then
						iTmpGroupIdx = j;
					end
				end

				--取的第6个号码时如果还是同一地区，则返回重新取随机数
				if (bChangeArea == 1 and iTmpGroupIdx == MiBaoGroupAndIndex[1].group) then
					continue;
				end

				-- 在分区中取一个没有使用过的随机号码
				local iTmpIdx = math.random(0,iGroupSize[iTmpGroupIdx]-1);
				local bExitIdx = 0;
				for j = 1, iGetCount do
					if (MiBaoGroupAndIndex[j].group == iTmpGroupIdx) and (MiBaoGroupAndIndex[j].index == iTmpIdx) then
						bExitIdx = 1
						break
					end
				end

				if ( 1 ~= bExitIdx ) then
					iGetCount = iGetCount + 1
					-- 记录本次取得的分区索引及分区中的号码索引
					MiBaoGroupAndIndex[iGetCount].group = iTmpGroupIdx;
					MiBaoGroupAndIndex[iGetCount].index = iTmpIdx;
				end
			end

			-- 根据索引从全部密保电话中得到具体的号码并显示
			local strTel = ""
			for num = 1,MiBaoPhoneCount do
				strTel = GameProduceLogin:GetPasswdTelByGroupIndexAndIndex(MiBaoGroupAndIndex[num].group, MiBaoGroupAndIndex[num].index);
				PasswdProctectTels[num] = strTel;
				MiBaoTextCtrl[num] : SetText(PasswdProctectTels[num])
			end
		else
			-- 根据索引从全部有效密保电话中得到具体的号码并显示
			for i =1, ValidTelNum do
				local strTel = GameProduceLogin:GetPasswdTelByGroupIndexAndIndex(MiBaoGroupAndIndex[i].group, MiBaoGroupAndIndex[i].index);
				PasswdProctectTels[i] = strTel
				MiBaoTextCtrl[i] : SetText(PasswdProctectTels[i])
			end
		end
	end

	return
end

function SafeCenter_SafeCheck_TelMibaoTishi_AddWeight( index )

	local sum = 0;

	for i = 1,index do
		sum = sum + MiBaoGroupWeight[i-1];
	end

	return sum;

end

function SafeCenter_SafeCheck_TelMibaoTishi_TimeReach()

	SafeCenter_SafeCheck_Frame6_Button4:Enable();
	SafeCenter_SafeCheck_TelMibaoTip_Text_Window:SetProperty("Visible", "False");

end

function SafeCenter_SafeCheck_TelMibaoTishi_OnVerify(  )
	
		-- 检测安全时间
	if tonumber(DataPool:GetLeftProtectTime()) > 0 then
		PushDebugMessage("#{LSHZ_101008_17}")     	-- "安全时间内不能卸载休闲动作包"
		return
	end

	local nNowTickCount = Exchange:GetTickCount();
	g_LastLockTime = nNowTickCount;
	AskPhoneMibaoStatus();
	this:Hide();

end

--===============================================
-- 					二级密码
--===============================================
--验证二级密码
function SafeCenter_SafeCheck_OpenCheckMinorPwdFrame(  )

	-- 界面显示
	SafeCenter_SafeCheck_CloseOthers()
	SafeCenter_SafeCheck_Update()
	Variable:SetVariable("SelfUnionPos", SafeCenter_SafeCheck_Frame:GetProperty("UnifiedPosition"), 1);
	this:Show()
	SafeCenter_SafeCheck_Update_ButtonSelectedAndFrame();
	SafeCenter_SafeCheck_MainButton_SafeCheck:SetProperty("Selected", "True");
	SafeCenter_SafeCheck_MainButton_SafeCheck:SetProperty("RiseOnClick", "Flase");
	SafeCenter_SafeCheck_Frame6_Button1:SetText( "#{AQZX_130812_83}"  )
	SafeCenter_SafeCheck_Frame6_Button2:SetText( "#{AQZX_130812_64}"  )
	SafeCenter_SafeCheck_Frame6_Lace5_Text:SetText( "#{AQZX_130812_85}"  )
	SafeCenter_SafeCheck_Frame6_DefaultWindow2:SetProperty("Visible" , "False" )
	SafeCenter_SafeCheck_Frame6_DefaultWindow3:SetProperty("Visible" , "True" )
	SafeCenter_SafeCheck_PassWord2:SetText( "" );
	SafeCenter_SafeCheck_SoftKeyBoard_SoftKey:SetAimEditBox( "SafeCenter_SafeCheck_PassWord2" );
	--二级密码
	SafeCenter_SafeCheck_TextInfo3:SetProperty("Visible" , "False" )
	SafeCenter_SafeCheck_Button5:SetProperty("Disabled" , "False" )


	SafeCenter_SafeCheck_Frame6_DefaultWindowZZB:SetProperty("Visible" , "False" )
	SafeCenter_SafeCheck_Frame6_DefaultWindowNoCheck:SetProperty("Visible" , "False" )
	SafeCenter_SafeCheck_Frame6_DefaultWindow:SetProperty("Visible" , "True" )

	--二级密码验证次数     add by Manda 2014-1-6
	local TempTime = DataPool:GetServerDayTime()
	ServerDayTime = DataPool:DateTime2DayTime(TempTime)
	local nLastMinorPwdDayTime  = DataPool:GetMinorPwdCurrentDayTime()

	if ServerDayTime > nLastMinorPwdDayTime then
		DataPool:SetCurrentMinorPwdTimes(0)
	end

	local nCurrentMinorPwdTimes = DataPool:GetCurrentMinorPwdTimes()

	if nCurrentMinorPwdTimes == 5 then
		SafeCenter_SafeCheck_TextInfo3:SetProperty("Visible" , "True" )
		SafeCenter_SafeCheck_Button5:SetProperty("Disabled" , "True" )
	end

	
end

function SafeCenter_SafeCheck_Jiesuo_OnActive() 

	SafeCenter_SafeCheck_SoftKeyBoard_SoftKey:SetAimEditBox( "SafeCenter_SafeCheck_PassWord2" );

end

function SafeCenter_SafeCheck_OK_Click()

	if( 2 == g_CurrectOperate ) then
		local strPassword = SafeCenter_SafeCheck_PassWord2:GetText();
		local iLen = string.len(strPassword);
		if(iLen < 4) then
			ShowSystemTipInfo( "#{UITEXT_PWTOOSHORT}" )   --("密码不能少于4个字符！");
			return;
		end
		BankAcquireListWithPW( strPassword )
		SafeCenter_SafeCheck_Close()
		return
	end

	if( 1 == g_CurrectOperate ) then
		local strPassword = SafeCenter_SafeCheck_PassWord2:GetText();
		local iLen = string.len(strPassword);
		if(iLen < 4) then
			ShowSystemTipInfo( "#{UITEXT_PWTOOSHORT}" )   --("密码不能少于4个字符！");
			return;
		end
		Player:ChangePVPModeWithPassword( g_PKModeWant, strPassword )
	        -- 隐藏窗口.
		SafeCenter_SafeCheck_Close();
		return
	end

	local strPassword = SafeCenter_SafeCheck_PassWord2:GetText();
	local iLen = string.len(strPassword);
	if(iLen < 4) then

		ShowSystemTipInfo("#{UITEXT_PWTOOSHORT}")
		return
	end


	-- 解锁密码。
	UnLockMinorPassword(strPassword);
	-- 隐藏窗口.
	SafeCenter_SafeCheck_Close()

end

--更新主界面位置
function SafeCenter_SafeCheck_Frame_On_ResetPos()

	SafeCenter_SafeCheck_Frame : SetProperty("UnifiedXPosition", g_SafeCenter_SafeCheck_Frame_UnifiedXPosition);
	SafeCenter_SafeCheck_Frame : SetProperty("UnifiedYPosition", g_SafeCenter_SafeCheck_Frame_UnifiedYPosition);

end

--得到当前UI位置
function SafeCenter_SafeCheck_Update()
	-- body
	local selfUnionPos = Variable:GetVariable("SelfUnionPos");
	if(selfUnionPos ~= nil) then
		SafeCenter_SafeCheck_Frame:SetProperty("UnifiedPosition", selfUnionPos);
	end
end

--关闭安全中心其它界面
function SafeCenter_SafeCheck_CloseOthers()

	 CloseWindow("SafeCenter_SafeScore", true);
	 CloseWindow("SafeCenter_SafePattern", true);
	 CloseWindow("SafeCenter_MobilePhone", true);
	 CloseWindow("SafeCenter_SafeTime", true);
	 CloseWindow("SafeCenter_SecondPassword", true);
	 CloseWindow("SafeCenter_AccountProtection", true);
	 CloseWindow("SafeCenter_SafeCheck", true);
	 CloseWindow("SafeCenter_LockUnlock", true);

end


-- 超链 安全中心官网
function SafeCenter_SafeCheck_GW_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_GW"))
end

-- 超链 账号平台
function SafeCenter_SafeCheck_ZHPT_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_ZHPT"))
end

-- 超链 客服中心
function SafeCenter_SafeCheck_KFZX_Clicked()
	GameProduceLogin:OpenURL(GetWeblink("WEB_ANQUANZHONGXIN_KFZX"))
end

function SafeCenter_SafeCheck_FastCheck_Click()
	AppWareFastCheck()	
end

function SafeCenter_SafeCheck_FastCheck_ClickOK()
	SafeCenter_SafeCheck_Frame6_ZZBCheckButton2_Text_StopWatch:SetProperty("Timer", "60");
  SafeCenter_SafeCheck_KuaiJieButton()
	
end

function SafeCenter_SafeCheck_KuaiJieButton()
	local mlefttime = AppWareGetLeftCheckTime()
	local AppLeftTime = math.floor(mlefttime/1000)
	if AppLeftTime > 60 then
		AppLeftTime = 60
	end
	SafeCenter_SafeCheck_Frame6_ZZBLace6:Show()
	SafeCenter_SafeCheck_Frame6_ZZBCheckButton2:Show()
	SafeCenter_SafeCheck_Frame6_ZZBCheckButton2_Text_StopWatch:Show()
	SafeCenter_SafeCheck_Frame6_ZZBLace6_Info_Text:Show()
	if AppLeftTime <=0 then
		SafeCenter_SafeCheck_Frame6_ZZBCheckButton2:Enable()
		SafeCenter_SafeCheck_Frame6_ZZBCheckButton2:SetText("#{ANYZ_150601_02}")
		SafeCenter_SafeCheck_Frame6_ZZBLace6_Info_Text:SetText("")
		SafeCenter_SafeCheck_Frame6_ZZBCheckButton2_Text_StopWatch:SetProperty("Timer", "0");
	else
		SafeCenter_SafeCheck_Frame6_ZZBCheckButton2:Disable()
		SafeCenter_SafeCheck_Frame6_ZZBCheckButton2:SetText("#{ANYZ_150601_04}")
		SafeCenter_SafeCheck_Frame6_ZZBLace6_Info_Text:SetText("#{ANYZ_150601_05}")
		SafeCenter_SafeCheck_Frame6_ZZBCheckButton2_Text_StopWatch:SetProperty("Timer", tostring(AppLeftTime));
	end
end
