
local Signin_Frame_UnifiedPosition;
local g_StartTime = 20240916
local g_EndTime = 20240929
local g_ShowBuyTime = 20240930
local g_LimitLV = 30
local g_Safetime = 5000
local g_NeedCoins = 1
local g_MAXDraw = 28
local g_lottery = {round = 3, minSpeed = 50, decay = 5}
local g_Reward_Nomal = 
{
	[1] = {itemId = 39923516, num = 1, times = 2, },
	[2] = {itemId = 39923517, num = 1, times = 4, },
	[3] = {itemId = 39923518, num = 1, times = 6,},
	[4] = {itemId = 39923519, num = 1, times = 8,},
	[5] = {itemId = 39923520, num = 1, times = 10,},
}
local g_PoolItemList_Nomal = 
{
	[1] = {itemId = 20700055, num = 10,},
	[2] = {itemId = 38000380, num = 1,},
	[3] = {itemId = 38004358, num = 2,},
	[4] = {itemId = 38004805, num = 10,},
	[5] = {itemId = 38002041, num = 10,},
	[6] = {itemId = 20800033, num = 5,},
	[7] = {itemId = 38000571, num = 3,},
	[8] = {itemId = 50418004, num = 1,},
}
local g_Reward_KJ = 
{
	[1] = {itemId = 39923965, num = 1, times = 2, },
	[2] = {itemId = 39923966, num = 1, times = 4, },
	[3] = {itemId = 39923967, num = 1, times = 6,},
	[4] = {itemId = 39923968, num = 1, times = 8,},
	[5] = {itemId = 39923969, num = 1, times = 10,},
}
local g_PoolItemList_KJ = 
{
	[1] = {itemId = 38000992, num = 1,},
	[2] = {itemId = 38001595, num = 2,},
	[3] = {itemId = 38000443, num = 1,},
	[4] = {itemId = 38000658, num = 1,},
	[5] = {itemId = 38000807, num = 2,},
	[6] = {itemId = 38000656, num = 2,},
	[7] = {itemId = 38000571, num = 3,},
	[8] = {itemId = 50418004, num = 1,},
}
local g_ActionButton = {}
local g_RewardButton = {}
local g_RewardOK = {}
local g_RewardAnimate = {}
local g_LastClickTime = 0
local g_Received = {}
local g_RewardDrawAni = {}
local g_DrawTimes = 0
local g_CoinTotal = 0
local g_Result = 0
local g_Text = ""
local g_LastClickTime = 0
local g_Step = 0
local g_Round = 0
local g_RewardText = {}
local g_Reward = {}
local g_PoolItemList = {}
--=========================================================
-- 注册窗口关心的所有事件
--=========================================================
function Signin_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("OBJECT_CARED_EVENT", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent( "HIDE_ON_SCENE_TRANSED" , false);		-- 离开场景
end

--=========================================================
-- 载入初始化
--=========================================================
function Signin_OnLoad()
	
	g_ActionButton[1] = Signin_RewardL_Lace1Item
	g_ActionButton[2] = Signin_RewardL_Lace2Item
	g_ActionButton[3] = Signin_RewardL_Lace3Item
	g_ActionButton[4] = Signin_RewardL_Lace4Item
	g_ActionButton[5] = Signin_RewardL_Lace5Item
	g_ActionButton[6] = Signin_RewardL_Lace6Item
	g_ActionButton[7] = Signin_RewardL_Lace7Item
	g_ActionButton[8] = Signin_RewardL_Lace8Item

	g_RewardButton[1] = Signin_Button1
	g_RewardButton[2] = Signin_Button2
	g_RewardButton[3] = Signin_Button3
	g_RewardButton[4] = Signin_Button4
	g_RewardButton[5] = Signin_Button5

	g_RewardAnimate[1] = Signin_Animate1
	g_RewardAnimate[2] = Signin_Animate2
	g_RewardAnimate[3] = Signin_Animate3
	g_RewardAnimate[4] = Signin_Animate4
	g_RewardAnimate[5] = Signin_Animate5

	g_RewardOK[1] = Signin_Get1
	g_RewardOK[2] = Signin_Get2
	g_RewardOK[3] = Signin_Get3
	g_RewardOK[4] = Signin_Get4
	g_RewardOK[5] = Signin_Get5

	g_RewardText[1] = Signin_Text1
	g_RewardText[2] = Signin_Text2
	g_RewardText[3] = Signin_Text3
	g_RewardText[4] = Signin_Text4
	g_RewardText[5] = Signin_Text5

	g_RewardDrawAni[1] = Signin_RewardL_Lace1ItemAnimate
	g_RewardDrawAni[2] = Signin_RewardL_Lace2ItemAnimate
	g_RewardDrawAni[3] = Signin_RewardL_Lace3ItemAnimate
	g_RewardDrawAni[4] = Signin_RewardL_Lace4ItemAnimate
	g_RewardDrawAni[5] = Signin_RewardL_Lace5ItemAnimate
	g_RewardDrawAni[6] = Signin_RewardL_Lace6ItemAnimate
	g_RewardDrawAni[7] = Signin_RewardL_Lace7ItemAnimate
	g_RewardDrawAni[8] = Signin_RewardL_Lace8ItemAnimate

	Signin_Frame_UnifiedPosition = Signin_FrameNULL:GetProperty("UnifiedPosition");
end

--=========================================================
-- 事件处理
--=========================================================
function Signin_OnEvent(event)

	if (event == "UI_COMMAND" and tonumber(arg0) == 88872301) then 
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(102) > 0 then  --卡级
			g_Reward = g_Reward_KJ
			g_PoolItemList = g_PoolItemList_KJ
		else
			g_Reward = g_Reward_Nomal
			g_PoolItemList = g_PoolItemList_Nomal
		end

		local opt = Get_XParam_INT(0)
		if opt == 1 then
			Signin_Clear()
			g_CoinTotal = Get_XParam_INT(1)
			g_DrawTimes = Get_XParam_INT(2)
			for i = 1, 5 do
				g_Received[i] = Get_XParam_INT(i + 2)
			end
			Signin_ShowFrame()
			this:Show()
		elseif opt == 2 then
			if(not this:IsVisible()) then
    			return
    		end
    		g_CoinTotal = Get_XParam_INT(1)
			g_DrawTimes = Get_XParam_INT(2)
			for i = 1, 5 do
				g_Received[i] = Get_XParam_INT(i + 2)
			end
			Signin_ShowFrame()

    	elseif opt == 3 then
    		if(not this:IsVisible()) then
    			return
    		end
    		g_CoinTotal = Get_XParam_INT(1)
			g_DrawTimes = Get_XParam_INT(2)
    		g_Result = Get_XParam_INT(3)
    		g_Text = Get_XParam_STR(0)
    		local tipstr = ScriptGlobal_Format("#{CQD_210806_74}", tostring(g_DrawTimes))
			Signin_Reward_NumberNow:SetText(tipstr)
			tipstr = ScriptGlobal_Format("#{CQD_210806_20}", tostring(g_CoinTotal))
			Signin_Reward_Number:SetText(tipstr)
			if g_CoinTotal >= g_NeedCoins and g_DrawTimes < g_MAXDraw then
				Signin_RewardButton_Animate:Show()
			else
				Signin_RewardButton_Animate:Hide()
			end
			for i = 1, 5 do
				if g_DrawTimes >= g_Reward[i].times and g_Received[i] < 1 then
					g_RewardAnimate[i]:Show()
				else
					g_RewardAnimate[i]:Hide()
				end
			end
    		Signin_Start()
    	elseif opt == 4 then
    		if(not this:IsVisible()) then
    			return
    		end
    		g_CoinTotal = Get_XParam_INT(1)
    		local tipstr = ScriptGlobal_Format("#{CQD_210806_20}", tostring(g_CoinTotal))
    		Signin_Reward_Number:SetText(tipstr)
    		if g_CoinTotal >= g_NeedCoins and g_DrawTimes < g_MAXDraw then
				Signin_RewardButton_Animate:Show()
			else
				Signin_RewardButton_Animate:Hide()
			end
		end
	elseif (event == "ADJEST_UI_POS" ) then
		Signin_On_ResetPos()

	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		Signin_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		Signin_OnHiden()
	end
end

function Signin_Clear()
	g_LastClickTime = 0
	g_DrawTimes = 0
	g_CoinTotal = 0
	g_Result = 0
	g_Text = ""
	g_Step = 0
	g_Round = 0
	for i = 1, 5 do
		g_RewardButton[i]:SetActionItem(-1)
		g_RewardAnimate[i]:Hide()
		g_RewardOK[i]:Hide()
		g_Received[i] = 0
	end
	for i = 1, 8 do
		g_ActionButton[i]:SetActionItem(-1)
		g_RewardDrawAni[i]:Hide()
	end
	Signin_RewardButton_Animate:Hide()
	Signin_Reward_Buy_Btn:Hide()
end

--=========================================================
-- 界面控件数据
--=========================================================
function Signin_ShowFrame()

	for i = 1, 8 do
		local itemAction = DataPool:CreateBindActionItemForShow(g_PoolItemList[i].itemId, g_PoolItemList[i].num)
		if itemAction:GetID() ~= 0 then
			g_ActionButton[i]:SetActionItem( itemAction:GetID() );
		else
			g_ActionButton[i]:SetActionItem( -1 );
		end
	end
	
	for i = 1, 5 do
		local itemAction = DataPool:CreateBindActionItemForShow(g_Reward[i].itemId, g_Reward[i].num)
		if itemAction:GetID() ~= 0 then
			g_RewardButton[i]:SetActionItem( itemAction:GetID() );
		else
			g_RewardButton[i]:SetActionItem( -1 );
		end

		g_RewardText[i]:SetText(ScriptGlobal_Format("#{CQD_210806_32}", tostring(g_Reward[i].times)))

		if g_DrawTimes >= g_Reward[i].times and g_Received[i] < 1 then
			g_RewardAnimate[i]:Show()
		else
			g_RewardAnimate[i]:Hide()
		end

		if g_Received[i] == 1 then
			g_RewardOK[i]:Show()
		end
	end
	if g_CoinTotal >= g_NeedCoins and g_DrawTimes < g_MAXDraw then
		Signin_RewardButton_Animate:Show()
	else
		Signin_RewardButton_Animate:Hide()
	end
	local tipstr = ScriptGlobal_Format("#{CQD_210806_74}", tostring(g_DrawTimes))
	Signin_Reward_NumberNow:SetText(tipstr)
	tipstr = ScriptGlobal_Format("#{CQD_210806_20}", tostring(g_CoinTotal))
	Signin_Reward_Number:SetText(tipstr)

	local nCurDay = tonumber(DataPool:GetServerDayTime());
	if nCurDay >= g_ShowBuyTime and nCurDay <= g_EndTime then
		local nBuyNum = g_Reward[5].times - g_CoinTotal - g_DrawTimes 
		if nBuyNum < 0 then
			nBuyNum = 0
		end
		Signin_Reward_Buy_Btn:Show()
		Signin_Reward_Buy_Btn:SetToolTip(ScriptGlobal_Format("#{CQD_220802_08}", tostring(nBuyNum)))
	else
		Signin_Reward_Buy_Btn:Hide()
	end
end


--=========================================================
-- 关闭界面
--=========================================================
function Signin_OnHiden()
	KillTimer("Signin_Tick()")
	KillTimer("Signin_ShowResult()")
	Signin_Clear()
	Signin_FlashRedPoint()
	this:Hide()
end

function Signin_FlashRedPoint()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("ShowButtonTips")
		Set_XSCRIPT_ScriptID(790015)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Signin_On_ResetPos()
  	Signin_FrameNULL:SetProperty("UnifiedPosition", Signin_Frame_UnifiedPosition);
end

function Signin_OnRewardClick(idx)
	
	if idx < 1 or idx > 5 then
		return 
	end

	local nCurDay = tonumber(DataPool:GetServerDayTime());
	if nCurDay < g_StartTime or nCurDay > g_EndTime then
		PushDebugMessage("#{CQD_210806_33}")
		return 
	end

	local nLevel = Player:GetData("LEVEL")
	if nLevel < g_LimitLV  then
		PushDebugMessage("#{CQD_210806_34}")
		return
	end

	if g_DrawTimes < g_Reward[idx].times then
		PushDebugMessage(ScriptGlobal_Format("#{CQD_210806_44}", tostring(g_Reward[idx].times)))
		return
	end

	if g_Received[idx] == 1 then
		PushDebugMessage("#{CQD_210806_45}")
		return
	end

	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("GetReward")
		Set_XSCRIPT_ScriptID(888723)
		Set_XSCRIPT_Parameter(0, idx)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()

end

function Signin_ShowHelp(idx)
	if idx == 1 then
		PushEvent("LONGSIGNIN_OPEN_HELP")
	end
end

function Signin_StartDraw()
	--领奖角色等级是否大于等于30级
	if Player:GetLevel() < 30 then
		PushDebugMessage("#{CQD_210806_34}")
		return
	end
	--当前服务器时间是否处于活动时间
	local curTime2Day = tonumber(DataPool:GetServerDayTime())
	if curTime2Day < g_StartTime or curTime2Day > g_EndTime then
		PushDebugMessage("#{CQD_210806_33}")
		return 
	end
	--判断是否处于兑换CD中
	local curTime = OSAPI:GetTickCount();
	if curTime - g_LastClickTime < g_Safetime then
		PushDebugMessage("#{CQD_210806_66}")
		return
	end
	g_LastClickTime = curTime

	for i = 1, 8 do
		g_RewardDrawAni[i]:Hide()
	end
	KillTimer("Signin_Tick()")
	KillTimer("Signin_ShowResult()")
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("StartDraw")
		Set_XSCRIPT_ScriptID(888723)
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
end

function Signin_Start()
	if(IsWindowShow("Packet")) then
		CloseWindow("Packet", true)
	end

	g_RewardDrawAni[1]:Show()
	g_Step = 1
	g_Round = 1
	SetTimer("Signin","Signin_Tick()", g_lottery.minSpeed)
end

function Signin_Tick()
	KillTimer("Signin_Tick()")
	if g_Step <= 0 or g_Step > 8 then
		return
	end
	g_RewardDrawAni[g_Step]:Hide()
	if g_Step < 8 and g_Round < g_lottery.round then
		g_Step = g_Step + 1
	elseif g_Step >= 8 and g_Round < g_lottery.round then
		g_Step = 1
		g_Round = g_Round + 1
	elseif g_Round == g_lottery.round and g_Step < g_Result then
		g_Step = g_Step + 1
	elseif g_Round == g_lottery.round and g_Step == g_Result then
		g_RewardDrawAni[g_Step]:Show()
		Signin_End()
		return
	else

	end
	g_RewardDrawAni[g_Step]:Show()
	SetTimer("Signin","Signin_Tick()", g_lottery.minSpeed + g_lottery.decay * (g_Step + 8 * g_Round))
end

function Signin_End()
	SetTimer("Signin","Signin_ShowResult()", 2000)
	--KillTimer("DuanWu_Boat_End()")
	--Clear_XSCRIPT()
		--Set_XSCRIPT_Function_Name("GongGao")
		--Set_XSCRIPT_ScriptID(505087)
		--Set_XSCRIPT_Parameter(0,g_Bonus)
		--Set_XSCRIPT_ParamCount(1)
	--Send_XSCRIPT()
	PushDebugMessage(g_Text)
	
	g_Round = 0
	g_Result = 0
	g_Text = ""
end

function Signin_ShowResult()
	KillTimer("Signin_ShowResult()")
	g_RewardDrawAni[g_Step]:Hide()
	g_Step = 0
end

function Signin_OpenBuy()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OpenBuy" )
		Set_XSCRIPT_ScriptID( 888723 )
		Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()	
end