-- HappyETJ_HD2.lua

local g_HappyETJ_HD2_Frame_UnifiedPosition;

local g_CurScroce =0;

local g_NpcId =-1;

local g_nCount = 0

--0:未开时；1：开始前倒计时；2：进行中；3结束
local g_State = 0


local objCared = -1

local g_ButtonLastTime = 0;
local g_ButtonCDTime = 0.1


function HappyETJ_HD2_PreLoad()
	this : RegisterEvent( "UI_COMMAND",true )
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("SCENE_TRANSED",true);
end

function HappyETJ_HD2_OnLoad()
	HappyETJ_HD2_Clear()
	    g_HappyETJ_HD2_Frame_UnifiedPosition=HappyETJ_HD2_FrameNULL:GetProperty("UnifiedPosition");
end

function HappyETJ_HD2_OnEvent(event)


	if event == "UI_COMMAND" and tonumber( arg0 ) == 8928004 then	-- 打开界面
		local nFlag = Get_XParam_INT( 0 );

		if nFlag == 0 then
		--	if this:IsVisible() then
				HappyETJ_HD2_Close()
				return
		--	end
		end
		g_NpcId = Get_XParam_INT( 1 );

    --    objCared = -1;
	--	objCared = DataPool : GetNPCIDByServerID(g_NpcId);

	--	if objCared == -1 then
	--		return
	--	end

	--	HappyETJ_HD2_BeginCareObject(objCared)

		HappyETJ_HD2_Open()

		return
	end

	if event == "SCENE_TRANSED" then
		if this:IsVisible()  then
			HappyETJ_HD2_Close()
		end
		return
	end


	if event == "UI_COMMAND" and tonumber( arg0 ) == 8928005 then	-- 吹气球
		if this : IsVisible() then
			local nScore = Get_XParam_INT( 0 );
			g_CurScroce = nScore
			HappyETJ_HD2_Refresh_Score(nScore)

		end
		return
	end

	if event == "UI_COMMAND" and tonumber( arg0 ) == 8928006 then	-- 结束
		if this : IsVisible()  then
			local isSuccess = Get_XParam_INT( 0 );
			local sumcount = Get_XParam_INT( 1 );
			HappyETJ_HD2_Finish(isSuccess,sumcount)
		end
		return
	end

	if (event == "ADJEST_UI_POS" ) then
		HappyETJ_HD2_Frame_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		HappyETJ_HD2_Frame_On_ResetPos()
	end


end

function HappyETJ_HD2_Open()
	--开启计时器
	KillTimer("HappyETJ_HD2_TimerProc()")
	SetTimer("HappyETJ_HD2","HappyETJ_HD2_TimerProc()", 1000)
	g_nCount =0

--当前次数
	HappyETJ_HD2_Score_picture1:SetProperty("Image", "set:Sign image:Signorange_"..0)
	HappyETJ_HD2_Score_picture2:SetProperty("Image", "set:Sign image:Signorange_"..0)
	HappyETJ_HD2_Score_picture3:SetProperty("Image", "set:Sign image:Signorange_"..0)
--动画相关设置，显示开始倒计时
	HappyETJ_HD2_Times_Begin:Show()
	HappyETJ_HD2_Times_Finish:Hide()
	HappyETJ_HD2_Times_Push:Show()
	HappyETJ_HD2_Times_Finish_textLace:Hide()
	HappyETJ_HD2_Times_Begin:Play(true)
--设置当前状态为开始倒计时
	g_State = 1
	HappyETJ_HD2_StateText:Show()
	HappyETJ_HD2_CountDownText:Hide()
	HappyETJ_HD2_StateText:SetText("#{ETJHD_180503_26}")

	HappyETJ_HD2_Explain:SetText("#{ETJHD_180503_31}")

	HappyETJ_HD2_Drum:Disable()


	this:Show()
end

function HappyETJ_HD2_TimerProc()
	--计时器每秒一次，更新状态
	g_nCount = g_nCount+1
	if g_nCount == 3 and g_State == 1 then --开始倒计时结束
		HappyETJ_HD2_Times_Begin:Play(false)
		HappyETJ_HD2_Times_Begin:Hide()
		HappyETJ_HD2_Times_Push:Show()
		HappyETJ_HD2_Times_Push:Play(true)
		g_State =2
		local Str = ScriptGlobal_Format("#{ETJHD_180503_6}", 10)
		HappyETJ_HD2_StateText:Hide()
		HappyETJ_HD2_CountDownText:Show()
		HappyETJ_HD2_CountDownText:SetText(Str)
		HappyETJ_HD2_Drum:Enable()
	end
	if g_State == 2 then --进行中
		local nLeftTime = 13-g_nCount
		if nLeftTime < 0 then
			nLeftTime = 0
		end
		local Str = ScriptGlobal_Format("#{ETJHD_180503_6}", nLeftTime)
		HappyETJ_HD2_CountDownText:SetText(Str)
	end
	if g_nCount >= 13 and g_State == 2 then
		HappyETJ_HD2_Drum:Disable()
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnSingleFinish" )
			Set_XSCRIPT_ScriptID( 892800 )
			Set_XSCRIPT_Parameter( 0, g_NpcId )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	end
	if g_nCount >= 7 and g_State == 3 then
		Clear_XSCRIPT()
			Set_XSCRIPT_Function_Name( "OnSingleFinish" )
			Set_XSCRIPT_ScriptID( 892800 )
			Set_XSCRIPT_Parameter( 0, g_NpcId )
			Set_XSCRIPT_ParamCount( 1 )
		Send_XSCRIPT()
	end
	if g_nCount >= 30  then
		HappyETJ_HD2_Close()
	end
end

 --  -1无效，0未进榜，1 进榜，2已经领过第一名奖励
function HappyETJ_HD2_Finish(isSuccess,sumcount)
	g_State = 3
	g_nCount = 0
	HappyETJ_HD2_Times_Push:Hide()
	HappyETJ_HD2_Times_Finish:Show()
	HappyETJ_HD2_Times_Finish:Play(true)
	HappyETJ_HD2_Times_Finish_textLace:Show()

	if isSuccess == -1 then --无效
		HappyETJ_HD2_Times_Finish_text:SetText("#{ETJHD_180503_231}")
	end

	if isSuccess == 0 then --没有进榜
		local Str = ScriptGlobal_Format("#{ETJHD_180503_34}", sumcount)
		HappyETJ_HD2_Times_Finish_text:SetText(Str)
		HappyETJ_HD2_Explain:SetText("#{ETJHD_180503_37}")
	end

	if isSuccess == 1 then --进榜
		local Str = ScriptGlobal_Format("#{ETJHD_180503_33}", sumcount)
		HappyETJ_HD2_Times_Finish_text:SetText(Str)
		HappyETJ_HD2_Explain:SetText("#{ETJHD_180503_36}")
	end

	if isSuccess == 2 then --得过第一名
		HappyETJ_HD2_Times_Finish_text:SetText("#{ETJHD_180503_230}")
		HappyETJ_HD2_Explain:SetText("#{ETJHD_180503_232}")
	end

	if isSuccess == 3 then --得过第一名又刷新了历史最高
		HappyETJ_HD2_Times_Finish_text:SetText("#{ETJHD_180516_8}")
		HappyETJ_HD2_Explain:SetText("#{ETJHD_180503_232}")
	end

	if isSuccess == 4 then --进榜，又刷新了历史最高
		local Str = ScriptGlobal_Format("#{ETJHD_180516_9}", sumcount)
		HappyETJ_HD2_Times_Finish_text:SetText(Str)
		HappyETJ_HD2_Explain:SetText("#{ETJHD_180503_36}")
	end

end

function HappyETJ_HD2_Refresh_Score(nScore)
	local Num1 = math.floor(nScore/100)
	local temp = math.mod(nScore, 100)
	local Num2 = math.floor(temp/10)
	local Num3 = math.mod(nScore, 10)
	HappyETJ_HD2_Score_picture1:SetProperty("Image", "set:Sign image:Signorange_"..Num1)
	HappyETJ_HD2_Score_picture2:SetProperty("Image", "set:Sign image:Signorange_"..Num2)
	HappyETJ_HD2_Score_picture3:SetProperty("Image", "set:Sign image:Signorange_"..Num3)
end


function HappyETJ_HD2_Clear()
	g_CurScroce =0;
	g_NpcId =-1;
	g_nCount = 0
end

function HappyETJ_HD2_Drum_Clicked()
	local curTime = OSAPI:GetTickCount();
	if ( curTime - g_ButtonLastTime < g_ButtonCDTime * 1000) then
   	--PushDebugMessage("#{ZYPT_081127_2}"); --不可连续点击，请稍等片刻后再点击
		return
	end
	g_ButtonLastTime = curTime;
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnSingleBlowBalloon" )
		Set_XSCRIPT_ScriptID( 892800 )
		Set_XSCRIPT_Parameter( 0, g_NpcId )
		Set_XSCRIPT_ParamCount( 1 )
	Send_XSCRIPT()
end

function HappyETJ_HD2_Close()
	KillTimer("HappyETJ_HD2_TimerProc()")
--	HappyETJ_HD2_StopCareObject()
	this:Hide()
end

function HappyETJ_HD2_Frame_On_ResetPos()
  HappyETJ_HD2_FrameNULL:SetProperty("UnifiedPosition", g_HappyETJ_HD2_Frame_UnifiedPosition);
end

--=========================================================
--开始关心NPC
--=========================================================
function HappyETJ_HD2_BeginCareObject(objCaredId)
	if objCared ~= -1 then
		this:CareObject(objCaredId, 0, "HappyETJ_HD2");
	end
	objCared = objCaredId
	this:CareObject(objCared, 1, "HappyETJ_HD2")
end

--=========================================================
--停止对某NPC的关心
--=========================================================
function HappyETJ_HD2_StopCareObject()
	if objCared ~= -1 then
		this:CareObject(objCared, 0, "HappyETJ_HD2");
		objCared = -1;
	end
end
