-- 中秋活动-千里共婵娟

local g_ZhongQiuRabbit_Frame_UnifiedPosition;

local g_ZhongQiuRabbit_PastWalkNum = -1
local g_ZhongQiuRabbit_LeftWalkNum = -1
local g_ZhongQiuRabbit_BanyuePrice = -1
local g_ZhongQiuRabbit_ManyuePrice = -1
local g_ZhongQiuRabbit_ManyueNum = -1
local g_ZhongQiuRabbit_HuoliNum = -1
local g_ZhongQiuRabbit_WalkTime = -1
local g_ZhongQiuRabbit_CurrentPos = -1
local g_ZhongQiuRabbit_AwardIndex = {}
local g_ZhongQiuRabbit_HistoryPos = {}
local g_ZhongQiuRabbit_JumpType = 0

local g_ZhongQiuRabbit_Button = {}
local g_ZhongQiuRabbit_ItemIcon = {}
local g_ZhongQiuRabbit_ManyueIcon = {}
local g_ZhongQiuRabbit_16ItemUI = {}
local g_ZhongQiuRabbit_11ManyueUI = {}
local g_ZhongQiuRabbit_3JumpButtonUI = {}
local g_ZhongQiuRabbit_3JumpButtonUIMask = {}
local g_ZhongQiuRabbit_PastWalkNum_Text
local g_ZhongQiuRabbit_LeftWalkNum_Text
local g_ZhongQiuRabbit_BanyuePrice_Tips
local g_ZhongQiuRabbit_BanyuePrice_Mask
local g_ZhongQiuRabbit_ManyuePrice_Tips
local g_ZhongQiuRabbit_ManyuePrice_Mask
local g_ZhongQiuRabbit_ManyueNum_Text
local g_ZhongQiuRabbit_HuoliNum_Text
local g_ZhongQiuRabbit_WalkTime_Text
local g_ZhongQiuRabbit_WalkStep_Text
local g_ZhongQiuRabbit_WalkStep_Client
local g_ZhongQiuRabbit_ExtraState
local g_ZhongQiuRabbit_OutTimeState
local g_ZhongQiuRabbit_TempState

local g_ZhongQiuTemp_JumpType = -1
local g_ZhongQiuTemp_StepNum = -1
local g_ZhongQiuTemp_StepAddNum = -1
local g_ZhongQiuTemp_CurrentPos = -1
local g_ZhongQiuTemp_DestPos = -1
local g_ZhongQiuTemp_AwardItemId = -1
local g_ZhongQiuTemp_ResetStart = false
local g_ZhongQiuTemp_ResetStartNum = -1
local g_ZhongQiuTemp_UpdateJumpUI = true

local g_ZhongQiuTemp_SvrType = 0
local g_ZhongQiuRabbit_AwardPool = {
	[0] = {
		{ nindex = 01, itemId = 39920574, num = 3},
		{ nindex = 02, itemId = 39920397, num = 1},
		{ nindex = 03, itemId = 39920329, num = 1},
		{ nindex = 04, itemId = 39923513, num = 1}, --礼盒 固定不随机
		{ nindex = 05, itemId = 39920298, num = 1},
		{ nindex = 06, itemId = 39920946, num = 10},
		{ nindex = 07, itemId = 39920334, num = 1},
		{ nindex = 08, itemId = 39923513, num = 1}, --礼盒 固定不随机
		{ nindex = 09, itemId = 39920163, num = 10},
		{ nindex = 10, itemId = 39920181, num = 1},
		{ nindex = 11, itemId = 39921516, num = 1},
		{ nindex = 12, itemId = 39923513, num = 1}, --礼盒 固定不随机
		{ nindex = 13, itemId = 39921051, num = 1},
		{ nindex = 14, itemId = 39920396, num = 1},
		{ nindex = 15, itemId = 39920162, num = 5},
		{ nindex = 16, itemId = 39923513, num = 1}, --礼盒 固定不随机
		--半月、满月奖励------------------------------------------------
		{ nindex = 17, itemId = 39923513, num = 1},
		{ nindex = 18, itemId = 39923466, num = 1},
	},
	[1] = {
		{ nindex = 01, itemId = 39920574, num = 3},
		{ nindex = 02, itemId = 39920397, num = 1},
		{ nindex = 03, itemId = 39920329, num = 1},
		{ nindex = 04, itemId = 39923971, num = 1}, --礼盒 固定不随机
		{ nindex = 05, itemId = 39921141, num = 2},
		{ nindex = 06, itemId = 39920267, num = 2},
		{ nindex = 07, itemId = 39920334, num = 1},
		{ nindex = 08, itemId = 39923971, num = 1}, --礼盒 固定不随机
		{ nindex = 09, itemId = 39920332, num = 1},
		{ nindex = 10, itemId = 39920181, num = 1},
		{ nindex = 11, itemId = 39920842, num = 5},
		{ nindex = 12, itemId = 39923971, num = 1}, --礼盒 固定不随机
		{ nindex = 13, itemId = 39921051, num = 1},
		{ nindex = 14, itemId = 39920396, num = 1},
		{ nindex = 15, itemId = 39923970, num = 1},
		{ nindex = 16, itemId = 39923971, num = 1}, --礼盒 固定不随机
		--半月、满月奖励------------------------------------------------
		{ nindex = 17, itemId = 39923971, num = 1},
		{ nindex = 18, itemId = 39923466, num = 1},
	},
}

local g_ZhongQiuRabbit_ExStateInfo = {
	{szImage = "set:MidAutu12 image:guaxiang_03", szTips = "#{QLGCJ_190801_07}"},
	{szImage = "set:MidAutu12 image:guaxiang_03", szTips = "#{QLGCJ_190801_08}"},
	{szImage = "set:MidAutu12 image:guaxiang_03", szTips = "#{QLGCJ_190801_09}"},
	{szImage = "set:MidAutu12 image:guaxiang_04", szTips = "#{QLGCJ_190801_10}"},
	{szImage = "set:MidAutu12 image:guaxiang_04", szTips = "#{QLGCJ_190801_11}"},
	{szImage = "set:MidAutu12 image:guaxiang_04", szTips = "#{QLGCJ_190801_12}"},
	{szImage = "set:MidAutu12 image:guaxiang_02", szTips = "#{QLGCJ_190801_13}"},
	{szImage = "set:MidAutu12 image:guaxiang_02", szTips = "#{QLGCJ_190801_14}"},
	{szImage = "set:MidAutu12 image:guaxiang_02", szTips = "#{QLGCJ_190801_15}"},
}
--**********************************
-- PRELOAD
--**********************************
function ZhongQiuRabbit_PreLoad()
	this:RegisterEvent("OPEN_ZHONGQIURABBIT_UI");		-- 打开UI
	this:RegisterEvent("UI_COMMAND")			-- 界面
	this:RegisterEvent("ADJEST_UI_POS",false)				-- 游戏窗口尺寸发生了变化
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)	-- 游戏分辨率发生了变化

end

--**********************************
-- OnLoad
--**********************************
function ZhongQiuRabbit_OnLoad()
	g_ZhongQiuRabbit_Frame_UnifiedPosition = ZhongQiuRabbit_FrameNULL:GetProperty("UnifiedPosition")
	g_ZhongQiuRabbit_PastWalkNum_Text = ZhongQiuRabbit_AcquireText
	g_ZhongQiuRabbit_LeftWalkNum_Text = ZhongQiuRabbit_SurplusText
	g_ZhongQiuRabbit_ManyueNum_Text = ZhongQiuRabbit_MoonText
	g_ZhongQiuRabbit_HuoliNum_Text = ZhongQiuRabbit_RabbitText
	g_ZhongQiuRabbit_WalkTime_Text = ZhongQiuRabbit_TimeUpText
	g_ZhongQiuRabbit_WalkStep_Text = ZhongQiuRabbit_StepText
	g_ZhongQiuRabbit_WalkStep_Client = ZhongQiuRabbit_StepTextClient
	g_ZhongQiuRabbit_BanyuePrice_Item = ZhongQiuRabbit_Reward1_one
	g_ZhongQiuRabbit_BanyuePrice_Tips = ZhongQiuRabbit_Reward1_ButtonTip
	g_ZhongQiuRabbit_BanyuePrice_Mask = ZhongQiuRabbit_Reward1_oneMark
	g_ZhongQiuRabbit_ManyuePrice_Item = ZhongQiuRabbit_Reward2_one
	g_ZhongQiuRabbit_ManyuePrice_Tips = ZhongQiuRabbit_Reward2_ButtonTip
	g_ZhongQiuRabbit_ManyuePrice_Mask = ZhongQiuRabbit_Reward2_oneMark

	g_ZhongQiuRabbit_16ItemUI = {
		{ item = ZhongQiuRabbit_Cube1_Item, hisMask = ZhongQiuRabbit_Cube1_ItemMark, rabbitUI = ZhongQiuRabbit_Cube1_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube1_JumpAnimate, animateUI = ZhongQiuRabbit_Cube1_Animate, itemMask = nil},
		{ item = ZhongQiuRabbit_Cube2_Item, hisMask = ZhongQiuRabbit_Cube2_ItemMark, rabbitUI = ZhongQiuRabbit_Cube2_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube2_JumpAnimate, animateUI = ZhongQiuRabbit_Cube2_Animate, itemMask = nil},
		{ item = ZhongQiuRabbit_Cube3_Item, hisMask = ZhongQiuRabbit_Cube3_ItemMark, rabbitUI = ZhongQiuRabbit_Cube3_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube3_JumpAnimate, animateUI = ZhongQiuRabbit_Cube3_Animate, itemMask = nil},
		{ item = ZhongQiuRabbit_Cube4_Item, hisMask = ZhongQiuRabbit_Cube4_ItemMark, rabbitUI = ZhongQiuRabbit_Cube4_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube4_JumpAnimate, animateUI = ZhongQiuRabbit_Cube4_Animate, itemMask = nil},
		{ item = ZhongQiuRabbit_Cube5_Item, hisMask = ZhongQiuRabbit_Cube5_ItemMark, rabbitUI = ZhongQiuRabbit_Cube5_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube5_JumpAnimate, animateUI = ZhongQiuRabbit_Cube5_Animate, itemMask = nil},
		{ item = ZhongQiuRabbit_Cube6_Item, hisMask = ZhongQiuRabbit_Cube6_ItemMark, rabbitUI = ZhongQiuRabbit_Cube6_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube6_JumpAnimate, animateUI = ZhongQiuRabbit_Cube6_Animate, itemMask = nil},
		{ item = ZhongQiuRabbit_Cube7_Item, hisMask = ZhongQiuRabbit_Cube7_ItemMark, rabbitUI = ZhongQiuRabbit_Cube7_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube7_JumpAnimate, animateUI = ZhongQiuRabbit_Cube7_Animate, itemMask = nil},
		{ item = ZhongQiuRabbit_Cube8_Item, hisMask = ZhongQiuRabbit_Cube8_ItemMark, rabbitUI = ZhongQiuRabbit_Cube8_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube8_JumpAnimate, animateUI = ZhongQiuRabbit_Cube8_Animate, itemMask = nil},
		{ item = ZhongQiuRabbit_Cube9_Item, hisMask = ZhongQiuRabbit_Cube9_ItemMark, rabbitUI = ZhongQiuRabbit_Cube9_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube9_JumpAnimate, animateUI = ZhongQiuRabbit_Cube9_Animate, itemMask = nil},
		{ item = ZhongQiuRabbit_Cube10_Item, hisMask = ZhongQiuRabbit_Cube10_ItemMark, rabbitUI = ZhongQiuRabbit_Cube10_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube10_JumpAnimate, animateUI = ZhongQiuRabbit_Cube10_Animate, itemMask = nil},
		{ item = ZhongQiuRabbit_Cube11_Item, hisMask = ZhongQiuRabbit_Cube11_ItemMark, rabbitUI = ZhongQiuRabbit_Cube11_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube11_JumpAnimate, animateUI = ZhongQiuRabbit_Cube11_Animate, itemMask = nil},
		{ item = ZhongQiuRabbit_Cube12_Item, hisMask = ZhongQiuRabbit_Cube12_ItemMark, rabbitUI = ZhongQiuRabbit_Cube12_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube12_JumpAnimate, animateUI = ZhongQiuRabbit_Cube12_Animate, itemMask = nil},
		{ item = ZhongQiuRabbit_Cube13_Item, hisMask = ZhongQiuRabbit_Cube13_ItemMark, rabbitUI = ZhongQiuRabbit_Cube13_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube13_JumpAnimate, animateUI = ZhongQiuRabbit_Cube13_Animate, itemMask = nil},
		{ item = ZhongQiuRabbit_Cube14_Item, hisMask = ZhongQiuRabbit_Cube14_ItemMark, rabbitUI = ZhongQiuRabbit_Cube14_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube14_JumpAnimate, animateUI = ZhongQiuRabbit_Cube14_Animate, itemMask = nil},
		{ item = ZhongQiuRabbit_Cube15_Item, hisMask = ZhongQiuRabbit_Cube15_ItemMark, rabbitUI = ZhongQiuRabbit_Cube15_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube15_JumpAnimate, animateUI = ZhongQiuRabbit_Cube15_Animate, itemMask = nil},
		{ item = ZhongQiuRabbit_Cube16_Item, hisMask = ZhongQiuRabbit_Cube16_ItemMark, rabbitUI = ZhongQiuRabbit_Cube16_Rabbit, animateRabbitUI = ZhongQiuRabbit_Cube16_JumpAnimate, animateUI = ZhongQiuRabbit_Cube16_Animate, itemMask = nil},
	}
	g_ZhongQiuRabbit_11ManyueUI = {
		ZhongQiuRabbit_Moon1,
		ZhongQiuRabbit_Moon2,
		ZhongQiuRabbit_Moon3,
		ZhongQiuRabbit_Moon4,
		ZhongQiuRabbit_Moon5,
		ZhongQiuRabbit_Moon6,
		ZhongQiuRabbit_Moon7,
		ZhongQiuRabbit_Moon8,
	}
	-- 索引1：普通跳  2：置换跳  3：遥控跳
	g_ZhongQiuRabbit_3JumpButtonUI = {
		ZhongQiuRabbit_JumpButton3,
		ZhongQiuRabbit_JumpButton1,
		ZhongQiuRabbit_JumpButton2,
		ZhongQiuRabbit_Jump,
	}
	g_ZhongQiuRabbit_3JumpButtonUIMask = {
		ZhongQiuRabbit_JumpButton3_Mark,
		ZhongQiuRabbit_JumpButton1_Mark,
		ZhongQiuRabbit_JumpButton2_Mark,
	}
end

--**********************************
-- OnEvent
--**********************************
function ZhongQiuRabbit_OnEvent( event )
	if (event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED") then
		ZhongQiuRabbit_On_ResetPos()
	elseif ( event == "UI_COMMAND" and tonumber(arg0) == 89290404 ) then
		-- 取参数
		local bForceOpen = Get_XParam_INT( 0 );
		g_ZhongQiuRabbit_PastWalkNum = Get_XParam_INT( 1 );
		g_ZhongQiuRabbit_LeftWalkNum = Get_XParam_INT( 2 );
		g_ZhongQiuRabbit_BanyuePrice = Get_XParam_INT( 3 );
		g_ZhongQiuRabbit_ManyuePrice = Get_XParam_INT( 4 );
		g_ZhongQiuRabbit_ManyueNum = Get_XParam_INT( 5 );
		g_ZhongQiuRabbit_HuoliNum = Get_XParam_INT( 6 );
		g_ZhongQiuRabbit_CurrentPos = Get_XParam_INT( 7 );
		g_ZhongQiuRabbit_WalkTime = Get_XParam_INT( 8 );
		-- local nAwardIndex4 = Get_XParam_INT( 9 );
		-- local nAwardIndex8 = Get_XParam_INT( 10 );
		-- local nAwardIndex12 = Get_XParam_INT( 11 );
		-- local nAwardIndex16 = Get_XParam_INT( 12 );
		local nStoryPosFlag = Get_XParam_INT( 9 );
		g_ZhongQiuRabbit_ExtraState = Get_XParam_INT( 10 );
		g_ZhongQiuRabbit_OutTimeState = Get_XParam_INT( 11 );
		g_ZhongQiuTemp_SvrType = KaJi:LuaFnGetKaJiType(103)
		ZhongQiuRabbit_InitAwardIndex(nAwardIndex4, nAwardIndex8, nAwardIndex12, nAwardIndex16)

		for startIndex =1, 16 do 
			local result, value = GetBitValueInUINT(nStoryPosFlag, startIndex, 1)
			g_ZhongQiuRabbit_HistoryPos[startIndex] =value
		end
		if bForceOpen == 1 and ( not this:IsVisible()) then 
			g_ZhongQiuRabbit_JumpType = 0;
			ZhongQiuRabbit_ActionItemInit()
			this:Show()
			g_ZhongQiuRabbit_WalkStep_Client:Hide()
			g_ZhongQiuRabbit_WalkStep_Text:Hide()
		end
		for i, v in pairs(g_ZhongQiuRabbit_16ItemUI) do 
			v.animateUI:Play(false)
			v.animateRabbitUI:Play(false)
		end
		-- 更新数据
		ZhongQiuRabbit_UpdateData();
	elseif ( event == "UI_COMMAND" and tonumber( arg0 ) == 89290405 ) then
		if not this:IsVisible() then return end
		g_ZhongQiuTemp_JumpType = Get_XParam_INT( 0 );
		g_ZhongQiuTemp_StepNum = Get_XParam_INT( 1 );
		g_ZhongQiuTemp_DestPos = Get_XParam_INT( 2 );
		g_ZhongQiuTemp_AwardItemId = Get_XParam_INT( 3 );
		g_ZhongQiuRabbit_ManyueNum = Get_XParam_INT( 4 );
		g_ZhongQiuRabbit_HuoliNum = Get_XParam_INT( 5 );
		g_ZhongQiuRabbit_LeftWalkNum = Get_XParam_INT( 6 );
		g_ZhongQiuRabbit_ExtraState = Get_XParam_INT( 7 );
		g_ZhongQiuRabbit_TempState = Get_XParam_INT( 8 );
		ZhongQiuRabbit_UpdateDataNoPos()
		g_ZhongQiuTemp_CurrentPos = g_ZhongQiuRabbit_CurrentPos;
		ZhongQiuRabbit_UIRabbitStartJump()
	end

end

--**********************************
-- 更新Data
--**********************************
function ZhongQiuRabbit_ActionItemInit()
	DataPool:Lua_ClearZhQiuRabbitActionItem();
	for i, v in pairs(g_ZhongQiuRabbit_AwardPool[g_ZhongQiuTemp_SvrType]) do 
		DataPool:Lua_SetZhQiuRabbitActionItem( i-1, v.itemId, v.num );
	end
	DataPool:Lua_UpdateZhQiuRabbitActionItem();
	local nIndex = table.getn(g_ZhongQiuRabbit_AwardPool[g_ZhongQiuTemp_SvrType]);
	local theAction1 = EnumAction( nIndex-1, "zhqiurabbit_item");
	g_ZhongQiuRabbit_ManyuePrice_Item:SetActionItem( theAction1:GetID() )
	local theAction2 = EnumAction( nIndex-2, "zhqiurabbit_item");
	g_ZhongQiuRabbit_BanyuePrice_Item:SetActionItem( theAction2:GetID() )
end
function ZhongQiuRabbit_UpdateData()
	if not this:IsVisible() then return end
	-- local strInfo = string.format("PastWalkNum:%s, LeftWalkNum:%s, BanyuePrice:%s, ManyuePrice:%s, ManyueNum:%s, HuoliNum:%s, WalkTime:%s", 
	-- 	g_ZhongQiuRabbit_PastWalkNum, g_ZhongQiuRabbit_LeftWalkNum, g_ZhongQiuRabbit_BanyuePrice, g_ZhongQiuRabbit_ManyuePrice, g_ZhongQiuRabbit_ManyueNum, g_ZhongQiuRabbit_HuoliNum, g_ZhongQiuRabbit_WalkTime)
	-- PushDebugMessage(strInfo)
	
	ZhongQiuRabbit_UpdateDataNoPos();
	-- 在线时间：%s
	if g_ZhongQiuRabbit_WalkTime == 0 then 
		g_ZhongQiuRabbit_WalkTime_Text:Hide()
		ZhongQiuRabbit_TimeText:SetText("#{QLGCJ_180810_25}")
	else 
		g_ZhongQiuRabbit_WalkTime_Text:Show()
		ZhongQiuRabbit_TimeText:SetText("#{QLGCJ_180810_23}")
		g_ZhongQiuRabbit_WalkTime_Text:SetProperty("Timer", tostring(g_ZhongQiuRabbit_WalkTime))
	end
	-- 历史奖励位置对勾
	if g_ZhongQiuRabbit_CurrentPos == 0 then 
		ZhongQiuRabbit_Start:Show()
	end
	for i, v in pairs(g_ZhongQiuRabbit_16ItemUI) do 
		if g_ZhongQiuRabbit_HistoryPos[i] == 1 then 
			v.hisMask:Show()
			if v.itemMask then v.itemMask:Hide() end
		else 
			v.hisMask:Hide()
			if v.itemMask then v.itemMask:Show() end
		end
		if g_ZhongQiuRabbit_CurrentPos == i then 
			v.rabbitUI:Show()
			ZhongQiuRabbit_Start:Hide()
		else
			v.rabbitUI:Hide()
		end
	end
	-- 额外增益状态
	ZhongQiuRabbit_UpdateExtraState()
	-- 卡级服和原服萝卜tips
	if g_ZhongQiuTemp_SvrType > 0 then 
		ZhongQiuRabbit_Cost_RabbitBK:SetToolTip("#{QLGCJ_220802_04}")
	else
		ZhongQiuRabbit_Cost_RabbitBK:SetToolTip("#{QLGCJ_180810_17}")
	end
end
-- 额外增益状态
function ZhongQiuRabbit_UpdateExtraState()
	local nState = g_ZhongQiuRabbit_ExtraState;
	if g_ZhongQiuRabbit_OutTimeState == 1 then 
		nState = 0
	end
	if g_ZhongQiuRabbit_ExtraState == 0 then 
		ZhongQiuRabbit_LotText:SetText("#{QLGCJ_190801_05}")
		ZhongQiuRabbit_Lot_ItemClient:Hide()
		ZhongQiuRabbit_Lot_Client:SetToolTip("");
	else
		ZhongQiuRabbit_LotText:SetText("#{QLGCJ_190801_06}")
		ZhongQiuRabbit_Lot_ItemClient:Show()
		local tabInfo = g_ZhongQiuRabbit_ExStateInfo[g_ZhongQiuRabbit_ExtraState] or g_ZhongQiuRabbit_ExStateInfo[1]
		ZhongQiuRabbit_Lot_Item:SetProperty("Image", tabInfo.szImage)
		ZhongQiuRabbit_Lot_Client:SetToolTip(tabInfo.szTips);
	end
	-- 	寻星按钮消耗文字
	if nState == 1 then 
		ZhongQiuRabbit_JumpCost1:SetText(ScriptGlobal_Format("#{QLGCJ_190801_16}", 300))
	elseif nState == 4 then 
		ZhongQiuRabbit_JumpCost1:SetText(ScriptGlobal_Format("#{QLGCJ_190801_16}", 150))
	elseif nState == 8 then 
		ZhongQiuRabbit_JumpCost1:SetText("#{QLGCJ_190801_17}")
	else
		ZhongQiuRabbit_JumpCost1:SetText(ScriptGlobal_Format("#{QLGCJ_190801_16}", 450))
	end
	-- 	逐月按钮消耗文字
	if nState == 2 then 
		ZhongQiuRabbit_JumpCost2:SetText(ScriptGlobal_Format("#{QLGCJ_190801_16}", 300))
	elseif nState == 5 then 
		ZhongQiuRabbit_JumpCost2:SetText(ScriptGlobal_Format("#{QLGCJ_190801_16}", 150))
	elseif nState == 9 then 
		ZhongQiuRabbit_JumpCost2:SetText("#{QLGCJ_190801_17}")
	else
		ZhongQiuRabbit_JumpCost2:SetText(ScriptGlobal_Format("#{QLGCJ_190801_16}", 450))
	end

	if g_ZhongQiuRabbit_OutTimeState == 0 then 
		ZhongQiuRabbit_Lot_ItemMark:Hide()
	else
		ZhongQiuRabbit_Lot_ItemMark:Show()
	end
end

function ZhongQiuRabbit_InitAwardIndex(nAwardIndex4, nAwardIndex8, nAwardIndex12, nAwardIndex16)
	for startIndex =1, 16 do 
		g_ZhongQiuRabbit_AwardIndex[startIndex] = startIndex
	end

	-- local startIndex = 0
	-- for startIndex =1, 4 do 
	-- 	local result, value = GetBitValueInUINT(nAwardIndex4, (startIndex-1)*8, 8)
	-- 	g_ZhongQiuRabbit_AwardIndex[startIndex] = value
	-- end
	-- for startIndex =5, 8 do 
	-- 	local result, value = GetBitValueInUINT(nAwardIndex8, (startIndex-5)*8, 8)
	-- 	g_ZhongQiuRabbit_AwardIndex[startIndex] = value
	-- end
	-- for startIndex =9, 12 do 
	-- 	local result, value = GetBitValueInUINT(nAwardIndex12, (startIndex-9)*8, 8)
	-- 	g_ZhongQiuRabbit_AwardIndex[startIndex] = value
	-- end
	-- for startIndex =13,16 do 
	-- 	local result, value = GetBitValueInUINT(nAwardIndex16, (startIndex-13)*8, 8)
	-- 	g_ZhongQiuRabbit_AwardIndex[startIndex] = value
	-- end

	-- local awardstr = ""
	-- for i, v in pairs(g_ZhongQiuRabbit_AwardIndex) do 
	-- 	awardstr = awardstr..i..":["..v.."]-"
	-- end
	-- local strInfo = string.format("nAwardIndex4:%s, nAwardIndex8:%s, nAwardIndex12:%s, nAwardIndex16:%s, nStoryPosFlag:%s, CurrentPos:%s", 
	-- 	nAwardIndex4, nAwardIndex8 or "nil", nAwardIndex12 or "nil", nAwardIndex16 or "nil", nStoryPosFlag or "nil", g_ZhongQiuRabbit_CurrentPos or "nil")
	-- PushDebugMessage(strInfo)
	-- PushDebugMessage("AwardIndex:"..awardstr)
end
function ZhongQiuRabbit_UpdateDataNoPos()
	ZhongQiuRabbit_UpdateJumpMask()
	-- 今日获得前进次数 %s/%s
	-- g_ZhongQiuRabbit_PastWalkNum_Text:SetText( ScriptGlobal_Format("#{QLGCJ_180810_21}", g_ZhongQiuRabbit_PastWalkNum, 4))
	-- 今日剩余前进次数 %s
	g_ZhongQiuRabbit_LeftWalkNum_Text:SetText(ScriptGlobal_Format("#{QLGCJ_180810_94}", g_ZhongQiuRabbit_LeftWalkNum))
	-- 玉兔活力值：%s
	g_ZhongQiuRabbit_HuoliNum_Text:SetText(ScriptGlobal_Format("#{QLGCJ_180810_108}", g_ZhongQiuRabbit_HuoliNum))
	-- 满月值：%s  满月值图片
	g_ZhongQiuRabbit_ManyueNum_Text:SetText(ScriptGlobal_Format("#{QLGCJ_180810_9}", g_ZhongQiuRabbit_ManyueNum))
	for i,v in pairs(g_ZhongQiuRabbit_11ManyueUI) do 
		if i == g_ZhongQiuRabbit_ManyueNum then 
			v:Show()
		else
			v:Hide()
		end
	end
	-- 弦月奖励
	if g_ZhongQiuRabbit_ManyueNum < 4 then
		g_ZhongQiuRabbit_BanyuePrice_Tips:Hide()
		g_ZhongQiuRabbit_BanyuePrice_Mask:Hide()
	elseif g_ZhongQiuRabbit_BanyuePrice == 1 then 
		g_ZhongQiuRabbit_BanyuePrice_Tips:Hide()
		g_ZhongQiuRabbit_BanyuePrice_Mask:Show()
	else
		g_ZhongQiuRabbit_BanyuePrice_Tips:Show()
		g_ZhongQiuRabbit_BanyuePrice_Mask:Hide()
	end
	-- 满月奖励
	if g_ZhongQiuRabbit_ManyueNum < 8 then
		g_ZhongQiuRabbit_ManyuePrice_Tips:Hide()
		g_ZhongQiuRabbit_ManyuePrice_Mask:Hide()
	elseif g_ZhongQiuRabbit_ManyuePrice == 1 then 
		g_ZhongQiuRabbit_ManyuePrice_Tips:Hide()
		g_ZhongQiuRabbit_ManyuePrice_Mask:Show()
	else
		g_ZhongQiuRabbit_ManyuePrice_Tips:Show()
		g_ZhongQiuRabbit_ManyuePrice_Mask:Hide()
	end
	-- 物品更新
	for i, v in pairs(g_ZhongQiuRabbit_16ItemUI) do 
		local tabAction = EnumAction( g_ZhongQiuRabbit_AwardIndex[i]-1, "zhqiurabbit_item");
		v.item:SetActionItem( tabAction:GetID() )
	end
end

function ZhongQiuRabbit_UIRabbitStartJump()
	-- PushDebugMessage("ZhongQiuRabbit_UIRabbitStartJump")
	for i, v in pairs(g_ZhongQiuRabbit_3JumpButtonUI) do
		v:Disable()
	end
	for i, v in pairs(g_ZhongQiuRabbit_16ItemUI) do 
		v.animateRabbitUI:Play(false)
	end
	-- g_ZhongQiuRabbit_WalkStep_Client:Show()
	-- g_ZhongQiuRabbit_WalkStep_Text:Show()
	-- g_ZhongQiuRabbit_WalkStep_Text:SetText( ScriptGlobal_Format("#{QLGCJ_180810_44}", g_ZhongQiuTemp_StepNum) )
	g_ZhongQiuTemp_StepAddNum = 0

	-- SetTimer("ZhongQiuRabbit","ZhongQiuRabbit_OnTimerJumpEvent()", 1000)
	ZhongQiuRabbit_AnimateRabbitStart();
end

function ZhongQiuRabbit_OnTimerJumpEvent()
	if g_ZhongQiuTemp_ResetStart == true then
		g_ZhongQiuTemp_ResetStartNum = g_ZhongQiuTemp_ResetStartNum + 1
		if g_ZhongQiuTemp_ResetStartNum >=3 then 
			KillTimer("ZhongQiuRabbit_OnTimerJumpEvent()")
			ZhongQiuRabbit_UIRabbitJumpEndReset()
			g_ZhongQiuRabbit_16ItemUI[16].rabbitUI:Hide();
			ZhongQiuRabbit_Start:Show()
			for i, v in pairs(g_ZhongQiuRabbit_16ItemUI) do 
				v.hisMask:Hide()
				if v.itemMask then v.itemMask:Show() end
				g_ZhongQiuRabbit_AwardIndex[i] = i;
				local tabAction = EnumAction( g_ZhongQiuRabbit_AwardIndex[i]-1, "zhqiurabbit_item");
				v.item:SetActionItem( tabAction:GetID() )
				v.animateUI:Play(true)
			end
			g_ZhongQiuRabbit_CurrentPos = 0;
			ZhongQiuRabbit_UpdateDataNoPos()
			-- g_ZhongQiuRabbit_WalkStep_Client:Show()
			-- g_ZhongQiuRabbit_WalkStep_Text:Show()
			-- g_ZhongQiuRabbit_WalkStep_Text:SetText( "#{QLGCJ_180810_61}" )
			PushDebugMessage("#{QLGCJ_180810_62}")
		end
	else
		g_ZhongQiuTemp_UpdateJumpUI = g_ZhongQiuTemp_CurrentPos==g_ZhongQiuRabbit_CurrentPos
		ZhongQiuRabbit_UIRabbitNextJump()
	end
end
-- bUpdateRabbitUI是为了容错， 当UI兔子前进过程中，关闭再打开界面
-- 会重置g_ZhongQiuRabbit_CurrentPos UI兔子更新位置出错， 
-- 此时按钮要继续Disable， 等待时间Enable按钮
function ZhongQiuRabbit_UIRabbitNextJump()
	if g_ZhongQiuTemp_UpdateJumpUI then 
		local oldPos = g_ZhongQiuRabbit_CurrentPos + g_ZhongQiuTemp_StepAddNum;
		if oldPos == 0 then 
			ZhongQiuRabbit_Start:Hide()
		else
			g_ZhongQiuRabbit_16ItemUI[oldPos].rabbitUI:Hide()
		end
	end
	g_ZhongQiuTemp_StepAddNum = g_ZhongQiuTemp_StepAddNum + 1
	if g_ZhongQiuTemp_UpdateJumpUI then 
		local targetPos = g_ZhongQiuRabbit_CurrentPos + g_ZhongQiuTemp_StepAddNum;
		g_ZhongQiuRabbit_16ItemUI[targetPos].rabbitUI:Show()
	end
	if g_ZhongQiuTemp_StepAddNum >= g_ZhongQiuTemp_StepNum then 
		ZhongQiuRabbit_UIRabbitEndJump()
		if g_ZhongQiuTemp_DestPos == 16 then 
			g_ZhongQiuTemp_ResetStart = true
			g_ZhongQiuTemp_ResetStartNum = 0
		else
			KillTimer("ZhongQiuRabbit_OnTimerJumpReset()")
			ZhongQiuRabbit_UIRabbitJumpEndReset()
		end
	end
end

function ZhongQiuRabbit_UIRabbitJumpEndReset()
	g_ZhongQiuRabbit_JumpType = 0
	ZhongQiuRabbit_UpdateJumpMask()
	for i, v in pairs(g_ZhongQiuRabbit_3JumpButtonUI) do
		v:Enable()
	end
	-- g_ZhongQiuRabbit_WalkStep_Client:Hide()
	-- g_ZhongQiuRabbit_WalkStep_Text:Hide()
	g_ZhongQiuTemp_ResetStart = false
	g_ZhongQiuTemp_ResetStartNum = -1
	g_ZhongQiuTemp_CurrentPos = 1
end

function ZhongQiuRabbit_UIRabbitEndJump()
	if g_ZhongQiuTemp_UpdateJumpUI then
		g_ZhongQiuRabbit_CurrentPos = g_ZhongQiuTemp_DestPos
		g_ZhongQiuRabbit_16ItemUI[g_ZhongQiuRabbit_CurrentPos].hisMask:Show();
		if g_ZhongQiuRabbit_16ItemUI[g_ZhongQiuRabbit_CurrentPos].itemMask then 
			g_ZhongQiuRabbit_16ItemUI[g_ZhongQiuRabbit_CurrentPos].itemMask:Hide()
		end
		g_ZhongQiuRabbit_16ItemUI[g_ZhongQiuRabbit_CurrentPos].animateUI:Play(true)
		local nAwardIndex = g_ZhongQiuRabbit_AwardIndex[g_ZhongQiuRabbit_CurrentPos]-1;
		local theAction = EnumAction( nAwardIndex, "zhqiurabbit_item");
		PushDebugMessage(ScriptGlobal_Format("#{QLGCJ_180810_45}", g_ZhongQiuRabbit_AwardPool[g_ZhongQiuTemp_SvrType][nAwardIndex+1].num, theAction:GetName()))
	end
end
--**********************************
-- 更新animateRabbitUI序列帧动画
--**********************************
function ZhongQiuRabbit_AnimateRabbitStart()
	SetTimer("ZhongQiuRabbit","ZhongQiuRabbit_OnTimerJumpReset2()", 8200)
	local oldPos = g_ZhongQiuRabbit_CurrentPos + g_ZhongQiuTemp_StepAddNum;
	if oldPos == 0 then 
		ZhongQiuRabbit_Start:Hide()
	else
		g_ZhongQiuRabbit_16ItemUI[oldPos].rabbitUI:Hide()
	end
	if g_ZhongQiuTemp_JumpType == 3 then 
		g_ZhongQiuTemp_StepAddNum = g_ZhongQiuTemp_StepNum
		local jumpIndex = g_ZhongQiuRabbit_CurrentPos + g_ZhongQiuTemp_StepNum
		if jumpIndex <1 or jumpIndex >16 then 
			Lua_TDU_Log("Error:ZhongQiuRabbit_AnimateRabbitStart00:"..g_ZhongQiuRabbit_CurrentPos..":"..g_ZhongQiuTemp_StepNum..":"..g_ZhongQiuTemp_DestPos);	
		end
		g_ZhongQiuRabbit_16ItemUI[jumpIndex].animateRabbitUI:Play(true)
	else
		g_ZhongQiuTemp_StepAddNum = g_ZhongQiuTemp_StepAddNum + 1
		local jumpIndex = oldPos+1
		if jumpIndex <1 or jumpIndex >16 then 
			Lua_TDU_Log("Error:ZhongQiuRabbit_AnimateRabbitStart11:"..g_ZhongQiuRabbit_CurrentPos..":"..g_ZhongQiuTemp_StepNum..":"..g_ZhongQiuTemp_DestPos);
		end
		g_ZhongQiuRabbit_16ItemUI[jumpIndex].animateRabbitUI:Play(true)
	end
end

function ZhongQiuRabbit_AnimateRabbitNext()
	if g_ZhongQiuTemp_StepAddNum >= g_ZhongQiuTemp_StepNum then 
		ZhongQiuRabbit_AnimateRabbitEnd()
		KillTimer("ZhongQiuRabbit_OnTimerJumpReset2()")
		if g_ZhongQiuTemp_DestPos == 16 then 
			SetTimer("ZhongQiuRabbit","ZhongQiuRabbit_OnTimerJumpReset()", 1000)
		else
			ZhongQiuRabbit_UIRabbitJumpEndReset()
		end
		return
	end
	g_ZhongQiuTemp_StepAddNum = g_ZhongQiuTemp_StepAddNum + 1
	local targetPos = g_ZhongQiuRabbit_CurrentPos + g_ZhongQiuTemp_StepAddNum;
	if targetPos == 17 then 
		for i, v in pairs(g_ZhongQiuRabbit_16ItemUI) do 
			v.hisMask:Hide();
		end
	end
	if targetPos > 16 then
		targetPos = targetPos - 16
	end
	g_ZhongQiuRabbit_16ItemUI[targetPos].animateRabbitUI:Play(true)
end

function ZhongQiuRabbit_AnimateRabbitEnd()
	g_ZhongQiuRabbit_CurrentPos = g_ZhongQiuTemp_DestPos
	g_ZhongQiuRabbit_16ItemUI[g_ZhongQiuRabbit_CurrentPos].hisMask:Show();
	if g_ZhongQiuRabbit_16ItemUI[g_ZhongQiuRabbit_CurrentPos].itemMask then 
		g_ZhongQiuRabbit_16ItemUI[g_ZhongQiuRabbit_CurrentPos].itemMask:Hide()
	end
	g_ZhongQiuRabbit_16ItemUI[g_ZhongQiuRabbit_CurrentPos].animateUI:Play(true)
	g_ZhongQiuRabbit_16ItemUI[g_ZhongQiuRabbit_CurrentPos].rabbitUI:Show();
	local nAwardIndex = g_ZhongQiuRabbit_AwardIndex[g_ZhongQiuRabbit_CurrentPos]-1;
	local theAction = EnumAction( nAwardIndex, "zhqiurabbit_item");
	local nAwardItemNum = g_ZhongQiuRabbit_AwardPool[g_ZhongQiuTemp_SvrType][nAwardIndex+1].num;
	if g_ZhongQiuTemp_JumpType == 2 then 
		if g_ZhongQiuRabbit_TempState == 3 then 
			PushDebugMessage(ScriptGlobal_Format("#{QLGCJ_190801_18}", g_ZhongQiuRabbit_AwardPool[g_ZhongQiuTemp_SvrType][nAwardIndex+1].num*2, theAction:GetName(), 1))
		elseif g_ZhongQiuRabbit_TempState == 6 then 
			PushDebugMessage(ScriptGlobal_Format("#{QLGCJ_190801_18}", g_ZhongQiuRabbit_AwardPool[g_ZhongQiuTemp_SvrType][nAwardIndex+1].num*2, theAction:GetName(), 2))
		else
			PushDebugMessage(ScriptGlobal_Format("#{QLGCJ_180810_112}", nAwardItemNum, theAction:GetName()))
		end
	else
		if g_ZhongQiuRabbit_TempState == 3 then 
			PushDebugMessage(ScriptGlobal_Format("#{QLGCJ_190801_18}", g_ZhongQiuRabbit_AwardPool[g_ZhongQiuTemp_SvrType][nAwardIndex+1].num, theAction:GetName(), 1))
		elseif g_ZhongQiuRabbit_TempState == 6 then 
			PushDebugMessage(ScriptGlobal_Format("#{QLGCJ_190801_18}", g_ZhongQiuRabbit_AwardPool[g_ZhongQiuTemp_SvrType][nAwardIndex+1].num, theAction:GetName(), 2))
		else
			PushDebugMessage(ScriptGlobal_Format("#{QLGCJ_180810_45}", g_ZhongQiuRabbit_AwardPool[g_ZhongQiuTemp_SvrType][nAwardIndex+1].num, theAction:GetName()))
		end
	end

	if g_ZhongQiuRabbit_TempState ~= 0 then 
		g_ZhongQiuRabbit_OutTimeState = 1
		ZhongQiuRabbit_UpdateExtraState();
	end
end
-- 用于序列帧过程中关闭界面-再打开按钮状态容错
function ZhongQiuRabbit_OnTimerJumpReset2()
	--PushDebugMessage("ZhongQiuRabbit_OnTimerJumpReset2")
	KillTimer("ZhongQiuRabbit_OnTimerJumpReset2()")
	ZhongQiuRabbit_UIRabbitJumpEndReset()
end

function ZhongQiuRabbit_OnTimerJumpReset()
	--PushDebugMessage("ZhongQiuRabbit_OnTimerJumpReset")
	KillTimer("ZhongQiuRabbit_OnTimerJumpReset()")
	g_ZhongQiuRabbit_CurrentPos = 0;
	ZhongQiuRabbit_UIRabbitJumpEndReset()
	g_ZhongQiuRabbit_16ItemUI[16].rabbitUI:Hide();
	ZhongQiuRabbit_Start:Show()
	for i, v in pairs(g_ZhongQiuRabbit_16ItemUI) do 
		v.hisMask:Hide()
		if v.itemMask then v.itemMask:Show() end
		g_ZhongQiuRabbit_AwardIndex[i] = i;
		local tabAction = EnumAction( g_ZhongQiuRabbit_AwardIndex[i]-1, "zhqiurabbit_item");
		v.item:SetActionItem( tabAction:GetID() )
		-- v.animateUI:Play(true)
	end
	ZhongQiuRabbit_UpdateDataNoPos()
	-- g_ZhongQiuRabbit_WalkStep_Client:Show()
	-- g_ZhongQiuRabbit_WalkStep_Text:Show()
	-- g_ZhongQiuRabbit_WalkStep_Text:SetText( "#{QLGCJ_180810_61}" )
	PushDebugMessage("#{QLGCJ_180810_62}")

end
--**********************************
-- 玩法button处理
--**********************************
function ZhongQiuRabbit_UpdateJumpMask()
	for i, v in pairs(g_ZhongQiuRabbit_3JumpButtonUIMask) do 
		v:Hide();
	end
	if g_ZhongQiuRabbit_3JumpButtonUIMask[g_ZhongQiuRabbit_JumpType] then 
		g_ZhongQiuRabbit_3JumpButtonUIMask[g_ZhongQiuRabbit_JumpType]:Show()
	end
end
function ZhongQiuRabbit_Button_FinalClick()
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnExcuteJump" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 892904 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, g_ZhongQiuRabbit_JumpType );					-- 参数一:类型
		Set_XSCRIPT_Parameter( 1, 0 );						-- 参数一：是否确认
		Set_XSCRIPT_ParamCount( 2 );						-- 参数个数
	Send_XSCRIPT()
end
function ZhongQiuRabbit_Button_Click(ntype)
	g_ZhongQiuRabbit_JumpType = ntype
	ZhongQiuRabbit_UpdateJumpMask()
end
function ZhongQiuRabbit_ButtonHelpWnd_Click()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnOpenZhQiuRabbitHelp" )
		Set_XSCRIPT_ScriptID( 892904 )
	Send_XSCRIPT()
end
function ZhongQiuRabbit_ManyuePrice_Click(ntype)
	-- PushDebugMessage("ZhongQiuRabbit_ManyuePrice_Click:"..(ntype or "nil"))
	-- 执行脚本
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "OnGetManyueNumGift" ); 		-- 脚本号
		Set_XSCRIPT_ScriptID( 892904 );						-- 脚本编号
		Set_XSCRIPT_Parameter( 0, ntype );		-- 参数一
		Set_XSCRIPT_ParamCount( 1 );						-- 参数个数
	Send_XSCRIPT()
end

function ZhongQiuRabbit_ButtonTips()
	if g_ZhongQiuTemp_SvrType > 0 then 
		PushEvent( "OPEN_HUODONGTEXT_HELP", 1, "#{QLGCJ_220802_01}" )
	else
		PushEvent( "OPEN_HUODONGTEXT_HELP", 1, "#{QLGCJ_180810_37}" )
	end
end

function ZhongQiuRabbit_On_ResetPos()
	ZhongQiuRabbit_FrameNULL:SetProperty("UnifiedPosition", g_ZhongQiuRabbit_Frame_UnifiedPosition)
end

function ZhongQiuRabbit_CloseHelp()
	if(IsWindowShow("ZhongQiuRabbit2")) then
		CloseWindow("ZhongQiuRabbit2", true)
		return
	end
end