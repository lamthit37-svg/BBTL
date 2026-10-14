-- HappyETJ_HD1.lua

local g_HappyETJ_HD1_Frame_UnifiedPosition;

local g_Curgoal =0;

local g_CurScroce =0;

local g_NpcId =-1;

local g_nCount = 0

--0:未开时；1：开始前倒计时；2：进行中；3结束
local g_State = 0

local g_Goal = {100,240,300}

local objCared = -1

local MAX_OBJ_DISTANCE = 6.0;

local g_BallonType = 0

local g_BallonTips ={"#{ETJHD_180503_9}","#{ETJHD_180503_8}","#{ETJHD_180503_7}"}

local g_ButtonLastTime = 0;
local g_ButtonCDTime = 0.1


function HappyETJ_HD1_PreLoad()
	this : RegisterEvent( "UI_COMMAND",true )
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("SCENE_TRANSED",true);
end

function HappyETJ_HD1_OnLoad()
	HappyETJ_HD1_Clear()
	    g_HappyETJ_HD1_Frame_UnifiedPosition=HappyETJ_HD1_FrameNULL:GetProperty("UnifiedPosition");
end

function HappyETJ_HD1_OnEvent(event)

	if event == "UI_COMMAND" and tonumber( arg0 ) == 8928001 then	-- 打开界面
		local nFlag = Get_XParam_INT( 0 );
		if nFlag == 0 then
		--	if this : IsVisible() then
				HappyETJ_HD1_Close()
				return
		--	end
		end
		g_NpcId = Get_XParam_INT( 1 );

		local nIndex = Get_XParam_INT( 2 );
		g_BallonType = nIndex

		g_Curgoal = g_Goal[nIndex];

        objCared = -1;
	--	objCared = DataPool : GetNPCIDByServerID(g_NpcId);

	--	if objCared == -1 then
	--		return
	--	end

	--	HappyETJ_HD1_BeginCareObject(objCared)

		HappyETJ_HD1_Open()
		return
	end

	if event == "SCENE_TRANSED" then
		if this:IsVisible()  then
			HappyETJ_HD1_Close()
		end
		return
	end

	if event == "UI_COMMAND" and tonumber( arg0 ) == 8928002 then	-- 吹气球
		if this : IsVisible() then
			local nScore = Get_XParam_INT( 0 );
			HappyETJ_HD1_Refresh_Score(nScore)

		end
		return
	end

	if event == "UI_COMMAND" and tonumber( arg0 ) == 8928003 then	-- 结束
		if this : IsVisible()  then
			local isSuccess = Get_XParam_INT( 0 );
			HappyETJ_HD1_Finish(isSuccess)
		end
		return
	end

	if (event == "ADJEST_UI_POS" ) then
		HappyETJ_HD1_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		HappyETJ_HD1_Frame_On_ResetPos()

	end


end

function HappyETJ_HD1_Open()
--开启计时器
	KillTimer("HappyETJ_HD1_TimerProc()")
	SetTimer("HappyETJ_HD1","HappyETJ_HD1_TimerProc()", 1000)
	g_nCount =0
--显示爆破目标
	local Num1 = math.floor(g_Curgoal/100)
	local temp = math.mod(g_Curgoal, 100)
	local Num2 = math.floor( temp/10)
	local Num3 = math.mod(g_Curgoal, 10)

	HappyETJ_HD1_Goal_picture1:SetProperty("Image", "set:Sign image:Signorange_"..Num1)
	HappyETJ_HD1_Goal_picture2:SetProperty("Image", "set:Sign image:Signorange_"..Num2)
	HappyETJ_HD1_Goal_picture3:SetProperty("Image", "set:Sign image:Signorange_"..Num3)
--当前次数
	HappyETJ_HD1_Score_picture1:SetProperty("Image", "set:Sign image:Signorange_"..0)
	HappyETJ_HD1_Score_picture2:SetProperty("Image", "set:Sign image:Signorange_"..0)
	HappyETJ_HD1_Score_picture3:SetProperty("Image", "set:Sign image:Signorange_"..0)
--动画相关设置，显示开始倒计时
	HappyETJ_HD1_Times_Begin:Show()
	HappyETJ_HD1_Times_Victory:Hide()
	HappyETJ_HD1_Times_Failure:Hide()
	HappyETJ_HD1_Times_Push:Show()
	HappyETJ_HD1_Times_Begin:Play(true)
--设置当前状态为开始倒计时
	g_State = 1
	HappyETJ_HD1_StateText:Show()
	HappyETJ_HD1_CountDownText:Hide()
	HappyETJ_HD1_StateText:SetText("#{ETJHD_180503_1}")
	HappyETJ_HD1_Explain:SetText("#{ETJHD_180503_10}")

	if g_BallonType>=1 and g_BallonType<=3 then

		HappyETJ_HD1_PlayTitle:SetText(g_BallonTips[g_BallonType])
	end

	HappyETJ_HD1_Drum:Disable()

	this:Show()
end

function HappyETJ_HD1_TimerProc()
	--计时器每秒一次，更新状态
	g_nCount = g_nCount+1
	if g_nCount == 3 and g_State == 1 then --开始倒计时结束
		HappyETJ_HD1_Times_Begin:Play(false)
		HappyETJ_HD1_Times_Begin:Hide()
		HappyETJ_HD1_Times_Push:Show()
		HappyETJ_HD1_Times_Push:Play(true)
		g_State =2
		local Str = ScriptGlobal_Format("#{ETJHD_180503_6}", 10)
		HappyETJ_HD1_StateText:Hide()
		HappyETJ_HD1_CountDownText:Show()
		HappyETJ_HD1_CountDownText:SetText(Str)
		HappyETJ_HD1_Drum:Enable()
	end
	if g_State == 2 then --进行中
		local nLeftTime = 13-g_nCount
		if nLeftTime < 0 then
			nLeftTime = 0
		end
		local Str = ScriptGlobal_Format("#{ETJHD_180503_6}", nLeftTime)
		HappyETJ_HD1_CountDownText:SetText(Str)
	end
	if g_nCount >= 13 and g_State == 2 then
		HappyETJ_HD1_Drum:Disable()
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnTeamFinish" )
			Set_XSCRIPT_ScriptID( 892800 )
			Set_XSCRIPT_Parameter( 0, g_NpcId )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	end
	if g_nCount >= 7 and g_State == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnTeamFinish" )
			Set_XSCRIPT_ScriptID( 892800 )
			Set_XSCRIPT_Parameter( 0, g_NpcId )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	end
	if g_nCount >= 30  then
		HappyETJ_HD1_Close()
	end
end
--服务器返回，开始结算
function HappyETJ_HD1_Finish(isSuccess)
	g_State = 3
	g_nCount = 0
	HappyETJ_HD1_Drum:Disable()
	HappyETJ_HD1_Times_Push:Hide()
	if isSuccess == 1 then --成功
		HappyETJ_HD1_Times_Victory:Show()
		HappyETJ_HD1_Times_Failure:Hide()
		HappyETJ_HD1_Times_Victory:Play(true)
		HappyETJ_HD1_Explain:SetText("#{ETJHD_180503_15}")
	end
	if isSuccess == 0 then --失败
		HappyETJ_HD1_Times_Victory:Hide()
		HappyETJ_HD1_Times_Failure:Show()
		HappyETJ_HD1_Times_Failure:Play(true)
		HappyETJ_HD1_Explain:SetText("#{ETJHD_180503_16}")
	end
end

function HappyETJ_HD1_Refresh_Score(nScore)
	local Num1 = math.floor(nScore/100)
	local temp = math.mod(nScore, 100)
	local Num2 = math.floor(temp/10)
	local Num3 = math.mod(nScore, 10)
	HappyETJ_HD1_Score_picture1:SetProperty("Image", "set:Sign image:Signorange_"..Num1)
	HappyETJ_HD1_Score_picture2:SetProperty("Image", "set:Sign image:Signorange_"..Num2)
	HappyETJ_HD1_Score_picture3:SetProperty("Image", "set:Sign image:Signorange_"..Num3)
	if nScore >= g_Curgoal then
		--提前达到目标，结束
		HappyETJ_HD1_Drum:Disable()
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnTeamFinish" )
			Set_XSCRIPT_ScriptID( 892800 )
			Set_XSCRIPT_Parameter( 0, g_NpcId )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	end
end


function HappyETJ_HD1_Clear()
	g_Curgoal =0;
	g_CurScroce =0;
	g_NpcId =-1;
	g_nCount = 0
end


function HappyETJ_HD1_Drum_Clicked()
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then
   	--PushDebugMessage("#{ZYPT_081127_2}"); --不可连续点击，请稍等片刻后再点击
		return
	end
	g_ButtonLastTime = curTime;
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnTeamBlowBalloon" )
		Set_XSCRIPT_ScriptID( 892800 )
		Set_XSCRIPT_Parameter( 0, g_NpcId )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

function HappyETJ_HD1_Frame_On_ResetPos()
  HappyETJ_HD1_FrameNULL:SetProperty("UnifiedPosition", g_HappyETJ_HD1_Frame_UnifiedPosition);
end

function HappyETJ_HD1_Close()
	KillTimer("HappyETJ_HD1_TimerProc()")
--	HappyETJ_HD1_StopCareObject()
	this:Hide()
end

--=========================================================
--开始关心NPC
--=========================================================
function HappyETJ_HD1_BeginCareObject(objCaredId)
	if objCared ~= -1 then
		this:CareObject(objCaredId, 0, "HappyETJ_HD1");
	end
	objCared = objCaredId
	this:CareObject(objCared, 1, "HappyETJ_HD1")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function HappyETJ_HD1_StopCareObject()
	if objCared ~= -1 then
		this:CareObject(objCared, 0, "HappyETJ_HD1");
		objCared = -1;
	end
end
