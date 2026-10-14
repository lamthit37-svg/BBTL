--- !!!reloadscript =SpringFestival_HuanWuDuiHuan
local g_Frame_UnifiedPosition

local g_HuanWuDuiHuan_UIMAX = 36

local g_HuanWuDuiHuan_BeginDay = 20260224
local g_HuanWuDuiHuan_EndDay = 20260315

local g_HuanWuDuiHuan_LimitLevel = 30

local g_HuanWuDuiHuan_AwardButton = {}
local g_HuanWuDuiHuan_AwardButtonTip = {}
local g_HuanWuDuiHuan_AwardButtonText = {}
local g_HuanWuDuiHuan_ActivityGo = {}
local g_HuanWuDuiHuan_ActivityFinish = {}
local g_HuanWuDuiHuan_AlreadyImg = {}


local g_HuanWuDuiHuan_Detail = {

	{Progress = 9  ,ShowGiftID = 30008130, ShowText = "#{YHSQ_210105_31}" , ButtonTipBKL = "#{YHSQ_210105_10}",  ButtonTipKL = "#{YHSQ_210105_11}" },
	{Progress = 18 ,ShowGiftID = 38000992, ShowText = "#{YHSQ_210105_32}", ButtonTipBKL = "#{YHSQ_210105_12}",  ButtonTipKL = "#{YHSQ_210105_13}" },
	{Progress = 27 ,ShowGiftID = 38008072, ShowText = "#{YHSQ_210105_33}", ButtonTipBKL = "#{YHSQ_210105_14}",  ButtonTipKL = "#{YHSQ_210105_15}" },
	{Progress = 36 ,ShowGiftID = 38004811, ShowText = "#{YHSQ_210105_34}", ButtonTipBKL = "#{YHSQ_210105_16}",  ButtonTipKL = "#{YHSQ_210105_17}" },
}
local g_HuanWuDuiHuan_KaJiDetail = {

	{Progress = 9  ,ShowGiftID = 30008130, ShowText = "#{YHSQ_210105_31}" , ButtonTipBKL = "#{YHSQ_210105_10}",  ButtonTipKL = "#{YHSQ_210105_11}" },
	{Progress = 18 ,ShowGiftID = 38000992, ShowText = "#{YHSQ_210105_32}", ButtonTipBKL = "#{YHSQ_210105_12}",  ButtonTipKL = "#{YHSQ_210105_13}" },
	{Progress = 27 ,ShowGiftID = 38008072, ShowText = "#{YHSQ_210105_33}", ButtonTipBKL = "#{YHSQ_210105_36}",  ButtonTipKL = "#{YHSQ_210105_37}" },
	{Progress = 36 ,ShowGiftID = 38008073, ShowText = "#{YHSQ_210105_34}", ButtonTipBKL = "#{YHSQ_210105_41}",  ButtonTipKL = "#{YHSQ_210105_42}" },
}
local g_HuanWuDuiHuan_DZDDetail = {

	{Progress = 9  ,ShowGiftID = 30008130, ShowText = "#{YHSQ_210105_31}" , ButtonTipBKL = "#{YHSQ_210105_10}",  ButtonTipKL = "#{YHSQ_210105_11}" },
	{Progress = 18 ,ShowGiftID = 38000992, ShowText = "#{YHSQ_210105_32}", ButtonTipBKL = "#{YHSQ_210105_12}",  ButtonTipKL = "#{YHSQ_210105_13}" },
	{Progress = 27 ,ShowGiftID = 38008072, ShowText = "#{YHSQ_210105_33}", ButtonTipBKL = "#{YHSQ_210105_14}",  ButtonTipKL = "#{YHSQ_210105_15}" },
	{Progress = 36 ,ShowGiftID = 20700055, ShowText = "#{YHSQ_210105_34}", ButtonTipBKL = "#{YHSQ_210105_39}",  ButtonTipKL = "#{YHSQ_210105_40}" },
}

--=========
-- PreLoad
--=========
function SpringFestival_HuanWuDuiHuan_PreLoad()
	
	this:RegisterEvent("UI_COMMAND", true)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)

end

--=========
-- OnLoad
--=========
function SpringFestival_HuanWuDuiHuan_OnLoad()

	g_Frame_UnifiedPosition = SpringFestival_HuanWuDuiHuan_Frame:GetProperty("UnifiedPosition") 
	
	g_HuanWuDuiHuan_AwardButton[1] = SpringFestival_HuanWuDuiHuan_RewardIcon1
	g_HuanWuDuiHuan_AwardButton[2] = SpringFestival_HuanWuDuiHuan_RewardIcon2
	g_HuanWuDuiHuan_AwardButton[3] = SpringFestival_HuanWuDuiHuan_RewardIcon3
	g_HuanWuDuiHuan_AwardButton[4] = SpringFestival_HuanWuDuiHuan_RewardIcon4
	
	g_HuanWuDuiHuan_AwardButtonTip[1] = SpringFestival_HuanWuDuiHuan_RewardTips1
	g_HuanWuDuiHuan_AwardButtonTip[2] = SpringFestival_HuanWuDuiHuan_RewardTips2
	g_HuanWuDuiHuan_AwardButtonTip[3] = SpringFestival_HuanWuDuiHuan_RewardTips3
	g_HuanWuDuiHuan_AwardButtonTip[4] = SpringFestival_HuanWuDuiHuan_RewardTips4
	
	g_HuanWuDuiHuan_AwardButtonText[1] = SpringFestival_HuanWuDuiHuan_RewardText1
	g_HuanWuDuiHuan_AwardButtonText[2] = SpringFestival_HuanWuDuiHuan_RewardText2
	g_HuanWuDuiHuan_AwardButtonText[3] = SpringFestival_HuanWuDuiHuan_RewardText3
	g_HuanWuDuiHuan_AwardButtonText[4] = SpringFestival_HuanWuDuiHuan_RewardText4
				
	g_HuanWuDuiHuan_ActivityGo[1] = SpringFestival_HuanWuDuiHuan_AButton1
	g_HuanWuDuiHuan_ActivityGo[2] = SpringFestival_HuanWuDuiHuan_AButton2
	g_HuanWuDuiHuan_ActivityGo[3] = SpringFestival_HuanWuDuiHuan_AButton3
	
	g_HuanWuDuiHuan_ActivityFinish[1] = SpringFestival_HuanWuDuiHuan_Activity1Finish
	g_HuanWuDuiHuan_ActivityFinish[2] = SpringFestival_HuanWuDuiHuan_Activity2Finish
	g_HuanWuDuiHuan_ActivityFinish[3] = SpringFestival_HuanWuDuiHuan_Activity3Finish
	
	g_HuanWuDuiHuan_AlreadyImg[1] = SpringFestival_HuanWuDuiHuan_RewardGot1
	g_HuanWuDuiHuan_AlreadyImg[2] = SpringFestival_HuanWuDuiHuan_RewardGot2
	g_HuanWuDuiHuan_AlreadyImg[3] = SpringFestival_HuanWuDuiHuan_RewardGot3
	g_HuanWuDuiHuan_AlreadyImg[4] = SpringFestival_HuanWuDuiHuan_RewardGot4

end

--=========
-- OnEvent
--=========
function SpringFestival_HuanWuDuiHuan_OnEvent(event)

	if event == "UI_COMMAND" and tonumber(arg0) == 88834501 then
		local curState = Get_XParam_INT(0)    --是否领取过阶段奖
		local A1State = Get_XParam_INT(1)     --活动当日是否完成
		local A2State = Get_XParam_INT(2)     --活动当日是否完成
		local A3State = Get_XParam_INT(3)     --活动当日是否完成
		if curState ~= nil then
			SpringFestival_HuanWuDuiHuan_Update(curState,A1State,A2State,A3State)
			this:Show()
		else		
			this:Hide()
		end		
	elseif event == "VIEW_RESOLUTION_CHANGED" then
		SpringFestival_HuanWuDuiHuan_OnResetPos()
				
	elseif event == "ADJEST_UI_POS" then
		SpringFestival_HuanWuDuiHuan_OnResetPos()
			
	elseif ( event == "HIDE_ON_SCENE_TRANSED" ) then
		SpringFestival_HuanWuDuiHuan_OnHiden()
		
	end

end


--==================
-- 是否处于活动期间
--==================
function SpringFestival_HuanWuDuiHuan_IsRightTime()
	local curDay = tonumber(DataPool:GetServerDayTime())
	if curDay >= g_HuanWuDuiHuan_BeginDay and curDay <= g_HuanWuDuiHuan_EndDay then
		return 1
	end
	return 0
end

--=========
-- 打开
--=========
function SpringFestival_HuanWuDuiHuan_Update( allMD, A1State, A2State, A3State )	

	local curProgress = math.floor(allMD/10000)
	local restMD = math.mod(allMD,10000)
	
	-- 设进度条
	SpringFestival_HuanWuDuiHuan_Huoyue:SetProgress(tonumber(curProgress), g_HuanWuDuiHuan_UIMAX)	
	--local progressstr = string.format( "%d/36",tonumber(curProgress) )
	local progressstr = ScriptGlobal_Format("#{YHSQ_210105_35}",curProgress)
	SpringFestival_HuanWuDuiHuan_Husoyue_Text:SetText(progressstr)
	

	
	local curState = {}
	curState[1] = math.mod( restMD, 10);
	curState[2] = math.mod( math.floor(restMD/10), 10)
	curState[3] = math.mod( math.floor(restMD/100), 10)
	curState[4] = math.mod( math.floor(restMD/1000), 10)
	local detail
	if Player:GetData("IsOriginalJD") == 1 then
		detail = g_HuanWuDuiHuan_DZDDetail
		SpringFestival_HuanWuDuiHuan_Info:SetText("#{YHSQ_210105_09}")
	else
		if KaJi:LuaFnIsKaJiServer() == 1 then
			detail = g_HuanWuDuiHuan_KaJiDetail
			SpringFestival_HuanWuDuiHuan_Info:SetText("#{YHSQ_210105_38}")
		else
			detail = g_HuanWuDuiHuan_Detail
			SpringFestival_HuanWuDuiHuan_Info:SetText("#{YHSQ_210105_09}")
		end
	end
	
	for i=1, 4 do
		--显示图标
		---local theAction = DataPool:CreateActionItemForShow(g_HuanWuDuiHuan_Detail[i].ShowGiftID, 1)
		---if theAction:GetID() ~= 0 then	
		---	g_HuanWuDuiHuan_AwardButton[i]:SetActionItem(theAction:GetID())
		---end
			
		if curState[i] == 1 then	--已领取
			g_HuanWuDuiHuan_AwardButtonTip[i]:Hide()
			g_HuanWuDuiHuan_AlreadyImg[i]:Show()
			g_HuanWuDuiHuan_AwardButton[i]:SetToolTip(detail[i].ButtonTipKL)
			--g_HuanWuDuiHuan_AwardButton[i] 换已领取图？
		elseif curProgress >= detail[i].Progress then	--可领取
			g_HuanWuDuiHuan_AwardButtonTip[i]:Show()
			g_HuanWuDuiHuan_AlreadyImg[i]:Hide()
			g_HuanWuDuiHuan_AwardButton[i]:SetToolTip(detail[i].ButtonTipKL)
		else  -- 未领取，但不可领取
			g_HuanWuDuiHuan_AwardButtonTip[i]:Hide()
			g_HuanWuDuiHuan_AlreadyImg[i]:Hide()
			g_HuanWuDuiHuan_AwardButton[i]:SetToolTip(detail[i].ButtonTipBKL)	
		end
		g_HuanWuDuiHuan_AwardButtonText[i]:SetText(detail[i].ShowText)	
	
	end
	local activityState = {}
	activityState[1] = A1State
	activityState[2] = A2State
	activityState[3] = A3State
	for i=1, 3 do
		if activityState[i] == 0 then	--未完成
			g_HuanWuDuiHuan_ActivityFinish[i]:Hide()
			g_HuanWuDuiHuan_ActivityGo[i]:Show()
		else  --已完成
			g_HuanWuDuiHuan_ActivityFinish[i]:Show()
			g_HuanWuDuiHuan_ActivityGo[i]:Hide()
		end		
	end	

	this:Show()
	
end

--=========
-- 关闭
--=========
function SpringFestival_HuanWuDuiHuan_OnHiden()

	this:Hide()

end

--=========
-- 关闭
--=========
function SpringFestival_HuanWuDuiHuan_Close()

	this:Hide()

end


--=========
-- 重置
--=========
function SpringFestival_HuanWuDuiHuan_OnResetPos()

	SpringFestival_HuanWuDuiHuan_Frame:SetProperty("UnifiedPosition", g_Frame_UnifiedPosition)
	
end

--==========
-- 三仙归位
--==========
function SpringFestival_HuanWuDuiHuan_GotoA3()

	local nLevel = Player:GetLevel()
	if nLevel < g_HuanWuDuiHuan_LimitLevel then
		PushDebugMessage("#{YHSQ_210105_06}")
		return
	end

	local isRightTime = SpringFestival_HuanWuDuiHuan_IsRightTime()
	if isRightTime <= 0 then
		PushDebugMessage("#{YHSQ_210105_07}")
		return
	end
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGotoDispatchNPC" );
		Set_XSCRIPT_ScriptID( 892980 );	
		Set_XSCRIPT_ParamCount( 0 );
	Send_XSCRIPT()
	
	--PushDebugMessage("#{YHSQ_210105_27}")    --正在前往洛阳（292,350）张守快处，参与三仙归位活动。

	SpringFestival_HuanWuDuiHuan_OnHiden()
end

--==========
-- 神射竞春
--==========
function SpringFestival_HuanWuDuiHuan_GotoA2()

	local nLevel = Player:GetLevel()
	if nLevel < g_HuanWuDuiHuan_LimitLevel then
		PushDebugMessage("#{YHSQ_210105_06}")
		return
	end

	local isRightTime = SpringFestival_HuanWuDuiHuan_IsRightTime()
	if isRightTime <= 0 then
		PushDebugMessage("#{YHSQ_210105_07}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GoToNPC" );
		Set_XSCRIPT_ScriptID( 893021 );	
		Set_XSCRIPT_ParamCount( 0 );
	Send_XSCRIPT()
	
--	Clear_XSCRIPT()
--		Set_XSCRIPT_Function_Name( "UpdateTheRedPoint" )
--		Set_XSCRIPT_ScriptID( 892985 )
--		Set_XSCRIPT_Parameter(0, 893021)
--		Set_XSCRIPT_ParamCount(1)
--	Send_XSCRIPT()
	
	PushDebugMessage("#{YHSQ_210105_24}")    --正在前往洛阳（299,350）洛神箭处，参与神射竞春活动。
	SpringFestival_HuanWuDuiHuan_OnHiden()

end

--==========
-- 花灯隐语
--==========
function SpringFestival_HuanWuDuiHuan_GotoA1()


	local nLevel = Player:GetLevel()
	if nLevel < g_HuanWuDuiHuan_LimitLevel then
		PushDebugMessage("#{YHSQ_210105_06}")
		return
	end

	local isRightTime = SpringFestival_HuanWuDuiHuan_IsRightTime()
	if isRightTime <= 0 then
		PushDebugMessage("#{YHSQ_210105_07}")
		return
	end
	
	AutoRuntoTargetExWithName(274, 341, 0, "蔡弥")
--	Clear_XSCRIPT()
--		Set_XSCRIPT_Function_Name( "UpdateRedPoint" );
--		Set_XSCRIPT_ScriptID( 892384 );	
--		Set_XSCRIPT_Parameter(0, 1)
--		Set_XSCRIPT_ParamCount( 1 );
--	Send_XSCRIPT()			
	
	PushDebugMessage("#{YHSQ_210105_30}")   --正在前往洛阳（274,341）蔡弥处，参与花灯隐语活动。YHSQ_210105_30
	
	SpringFestival_HuanWuDuiHuan_OnHiden()
	
end


--==========
-- 神射竞春
--==========
function SpringFestival_HuanWuDuiHuan_GetAward(index)

	local nLevel = Player:GetLevel()
	if nLevel < g_HuanWuDuiHuan_LimitLevel then
		PushDebugMessage("#{YHSQ_210105_06}")
		return
	end

	local isRightTime = SpringFestival_HuanWuDuiHuan_IsRightTime()
	if isRightTime <= 0 then
		PushDebugMessage("#{YHSQ_210105_07}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "GetHuanWuAward" );
		Set_XSCRIPT_ScriptID( 888345 );	
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_ParamCount( 1 );
	Send_XSCRIPT()	

end