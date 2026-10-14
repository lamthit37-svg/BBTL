g_AntiRobot_VERSION = 1    --请修改此文件后， 在game和此处修改版本， 防止错误运行。  这个优先级很高的， 类似于提示多个示例运行.



-- 20100524 hjj beg
-- 注意下面两个， 从CDataPool::Captcha_GetData()里面给保存过来， 因为
-- CDataPool的时效性是立刻的， 而在反外挂答题的过程中可能很久才点确定，这时可能其他的验证信息过来了~（可能是跑商交易等数字的， 跟这个无关）
-- 所以在这里暂存一份。
local g_nEnumEncType = 
{
	WGET_NONE = 0,
	WGET_SERVERKEY0 = 1,
	WGET_SERVERKEY1 = 2,
	--可在此扩展

	WGET_MAXNUMBER = 3,
}

local g_nEncryptType = 0;
local g_nServerKey = 0;	
-- 20100524 hjj end

local g_nUselSeld = -1;
local g_AnswerButton = {}
local g_AntiRobot_Frame_UnifiedPosition;
function AntiRobot_PreLoad()
	this:RegisterEvent("CAPTCHA_ACTIVE",true);
		-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("ADJEST_UI_POS",false)
	-- 游戏分辨率发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
end

function AntiRobot_OnLoad()
	math.randomseed(os.time());
	
	g_AnswerButton[0] = AntiRobot_Answer1_Check;
	g_AnswerButton[1] = AntiRobot_Answer2_Check;
	g_AnswerButton[2] = AntiRobot_Answer3_Check;
	g_AnswerButton[3] = AntiRobot_Answer4_Check;
	g_AntiRobot_Frame_UnifiedPosition=AntiRobot_Frame:GetProperty("UnifiedPosition");

end

function AntiRobot_OnEvent(event)
	if ( event == "CAPTCHA_ACTIVE" ) then
	  g_nEncryptType = tonumber( arg0 )
	  g_nServerKey = tonumber( arg1 )

	  if (g_nEncryptType < 0) then
	  	FPU:Set53bitControlWord();
	  	g_nEncryptType = 4294967296 + g_nEncryptType;
	  	FPU:RestoreLastSetControlWord();
		end

	  if (g_nServerKey < 0) then
	  	FPU:Set53bitControlWord();
	  	g_nServerKey = 4294967296 + g_nServerKey;
	  	FPU:RestoreLastSetControlWord();
		end
	    	
		g_nUselSeld = -1;
		DataPool:UpdateCaptchaData("AntiRobot_Image", "AntiRobot_Answer1", "AntiRobot_Answer2", "AntiRobot_Answer3", "AntiRobot_Answer4", 1 );
		AntiRobot_Frame:SetProperty("AlwaysOnTop", "True");
		AntiRobot_StopWatch:SetProperty("Timer", "60");
		AntiRobot_Accept:SetProperty("Disabled", "True");

		g_AnswerButton[0]:SetProperty("Selected", "False");
		g_AnswerButton[1]:SetProperty("Selected", "False");
		g_AnswerButton[2]:SetProperty("Selected", "False");
		g_AnswerButton[3]:SetProperty("Selected", "False");

		--计算随即位置，左上角或者右下角
		local x_Left=math.random()/4.0;
		local y_Top=math.random()/4.0;
		

		AntiRobot_Frame:SetProperty("UnifiedPosition", "{{" .. x_Left .. ", 0.0},{" ..  y_Top .. ", 0.0}}");
		
		this:Show();
	end
	
		-- 游戏窗口尺寸发生了变化
	if (event == "ADJEST_UI_POS" ) then
		AntiRobot_Frame_On_ResetPos()
	-- 游戏分辨率发生了变化
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		AntiRobot_Frame_On_ResetPos()
	end
end

function AntiRobot_SelAnswer(selIndex)
	if(selIndex<0 or selIndex>=4) then 
		return;
	end
	
	g_AnswerButton[selIndex]:SetProperty("Selected", "True");
	g_nUselSeld = selIndex;
	
	AntiRobot_Accept:SetProperty("Disabled", "False");
end


function AntiRobot_OnClose()
	AntiRobot_StopWatch:SetProperty("Timer", "-1");
end

function AntiRobot_TimeReach()
  --时间到了， 如果选了答案就帮你回答吧~ 无论如何， 都不会提示"切场景xxx", 并且一定会关闭
	if(g_nUselSeld>=0 and g_nUselSeld < 4) then
		AntiRobot_OnCommit(1)
	end
	this:Hide();
end

--================================================
-- 恢复界面的默认相对位置
--================================================
function AntiRobot_Frame_On_ResetPos()
  AntiRobot_Frame:SetProperty("UnifiedPosition", g_AntiRobot_Frame_UnifiedPosition);
end


--================================================
-- 新增的内容
--================================================
function AntiRobot_OnCommit(isAutoCommit)
	local nSelIndex = g_nUselSeld;
	local nSelIndex2 = 0; --just init 0 first
	
	--if ( math.mod(g_nEncryptType, g_nEnumEncType.WGET_MAXNUMBER) == g_nEnumEncType.WGET_SERVERKEY0) then
	--	nSelIndex, nSelIndex2 = AntiRobot_DoEncryptBuffer_ServerKey0(g_nServerKey, nSelIndex);
	--end
	local ret = DataPool:SelCaptchaAnswer(nSelIndex, nSelIndex2, g_nEncryptType, g_nServerKey);
	
	if isAutoCommit==1 or ret == 0 then
		this:Hide()
	else
		PushDebugMessage("#{GJJC_100528_1}")
	end	
end

function AntiRobot_Xor(nVal1, nVal2)

	local ret = 0;
	for i=31, 0, -1 do
		local bit1 = math.mod ( math.floor(nVal1 / (math.pow(2, i))) , 2);
		local bit2 = math.mod ( math.floor(nVal2 / (math.pow(2, i))) , 2);
		if (bit1 == bit2) then
			-- is 0, 1xor1 or 0xor0
			ret = ret * 2;
		else
			-- is 1, 1xor0 or 0xor1
			ret = ret * 2 + 1;
		end
	end
	
	return ret;	
end

local pow2_x =
{
	[0] = math.pow(2,0), [1] = math.pow(2,1), [2] = math.pow(2,2), [3] = math.pow(2,3),
 	[4] = math.pow(2,4), [5] = math.pow(2,5), [6] = math.pow(2,6), [7] = math.pow(2,7),
 	[8] = math.pow(2,8), [9] = math.pow(2,9), [10]= math.pow(2,10),[11]= math.pow(2,11),
 	[12]= math.pow(2,12),[13]= math.pow(2,13),[14]= math.pow(2,14),[15]= math.pow(2,15),
 	[16]= math.pow(2,16),[17]= math.pow(2,17),[18]= math.pow(2,18),[19]= math.pow(2,19),
 	[20]= math.pow(2,20),[21]= math.pow(2,21),[22]= math.pow(2,22),[23]= math.pow(2,23),
 	[24]= math.pow(2,24),[25]= math.pow(2,25),[26]= math.pow(2,26),[27]= math.pow(2,27),
 	[28]= math.pow(2,28),[29]= math.pow(2,29),[30]= math.pow(2,30),[31]= math.pow(2,31),
}

