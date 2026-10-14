
--!!!reloadscript =LuckyBag_Qifu

local g_CurRed = 0
local g_CurGreen = 0
local g_CurBlue = 0
local g_CurAlpha = 255

local g_BnBK = {}
local g_BnItem = {}
local g_BnFlash = {}

local g_BKImage = {
	"set:LuckyBag_Qifu0 image:Action_Tong",		--铜
	"set:LuckyBag_Qifu0 image:Action_Yin",		--银
	"set:LuckyBag_Qifu1 image:Action_Jin",		--金
	"set:LuckyBag_Qifu0 image:Action_Tie",		--铁
}

local g_HaveTokens = 0


local g_CurPushed = 0
local g_Lightindex = 1

local g_SumStep = 0
local g_MaxStep = 0
local g_valid_Bn = {}

local g_NeedTokens = { 50 ,80 ,120 ,120 }
local IndexMapping = {
[1]	=	2	,
[2]	=	3	,
[3]	=	11	,
[4]	=	9	,
[5]	=	27	,
[6]	=	24	,
[7]	=	25	,
[8]	=	17	,
[9]	=	30	,
[10]	=	10	,
[11]	=	5	,
[12]	=	16	,
[13]	=	18	,
[14]	=	14	,
[15]	=	19	,
[16]	=	6	,
[17]	=	22	,
[18]	=	21	,
[19]	=	26	,
[20]	=	23	,
[21]	=	13	,
[22]	=	28	,
[23]	=	15	,
[24]	=	8	,
[25]	=	20	,
[26]	=	29	,
[27]	=	4	,
[28]	=	1	,
[29]	=	12	,
[30]	=	7	,

}

local g_BonusIndexForShow = -1

local g_Ori_UnifiedPosition = ""

function LuckyBag_Qifu_PreLoad()
	this:RegisterEvent("UI_COMMAND", true)	
	this:RegisterEvent("RECIVE_ZNQ_FUDAIINFO",true)
	this:RegisterEvent("ADJEST_UI_POS",false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED",false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)
end

function LuckyBag_Qifu_OnLoad()
	
	g_Ori_UnifiedPosition = LuckyBag_Qifu_Frame:GetProperty("UnifiedPosition")
	
	g_BnItem[1] = LuckyBag_Qifu_Bk1_Item1
	g_BnItem[2] = LuckyBag_Qifu_Bk1_Item2
	g_BnItem[3] = LuckyBag_Qifu_Bk1_Item3
	g_BnItem[4] = LuckyBag_Qifu_Bk1_Item4
	g_BnItem[5] = LuckyBag_Qifu_Bk1_Item5
	g_BnItem[6] = LuckyBag_Qifu_Bk1_Item6
	g_BnItem[7] = LuckyBag_Qifu_Bk1_Item7
	g_BnItem[8] = LuckyBag_Qifu_Bk1_Item8
	g_BnItem[9] = LuckyBag_Qifu_Bk1_Item9
	g_BnItem[10] = LuckyBag_Qifu_Bk1_Item10
	g_BnItem[11] = LuckyBag_Qifu_Bk2_Item1
	g_BnItem[12] = LuckyBag_Qifu_Bk2_Item2
	g_BnItem[13] = LuckyBag_Qifu_Bk2_Item3
	g_BnItem[14] = LuckyBag_Qifu_Bk2_Item4
	g_BnItem[15] = LuckyBag_Qifu_Bk2_Item5
	g_BnItem[16] = LuckyBag_Qifu_Bk2_Item6
	g_BnItem[17] = LuckyBag_Qifu_Bk2_Item7
	g_BnItem[18] = LuckyBag_Qifu_Bk2_Item8
	g_BnItem[19] = LuckyBag_Qifu_Bk2_Item9
	g_BnItem[20] = LuckyBag_Qifu_Bk2_Item10
	g_BnItem[21] = LuckyBag_Qifu_Bk3_Item1
	g_BnItem[22] = LuckyBag_Qifu_Bk3_Item2
	g_BnItem[23] = LuckyBag_Qifu_Bk3_Item3
	g_BnItem[24] = LuckyBag_Qifu_Bk3_Item4
	g_BnItem[25] = LuckyBag_Qifu_Bk3_Item5
	g_BnItem[26] = LuckyBag_Qifu_Bk3_Item6
	g_BnItem[27] = LuckyBag_Qifu_Bk3_Item7
	g_BnItem[28] = LuckyBag_Qifu_Bk3_Item8
	g_BnItem[29] = LuckyBag_Qifu_Bk3_Item9
	g_BnItem[30] = LuckyBag_Qifu_Bk3_Item10
	
	g_BnFlash[1] = LuckyBag_Qifu_Bk1_Item1_Animate
	g_BnFlash[2] = LuckyBag_Qifu_Bk1_Item2_Animate
	g_BnFlash[3] = LuckyBag_Qifu_Bk1_Item3_Animate
	g_BnFlash[4] = LuckyBag_Qifu_Bk1_Item4_Animate
	g_BnFlash[5] = LuckyBag_Qifu_Bk1_Item5_Animate
	g_BnFlash[6] = LuckyBag_Qifu_Bk1_Item6_Animate
	g_BnFlash[7] = LuckyBag_Qifu_Bk1_Item7_Animate
	g_BnFlash[8] = LuckyBag_Qifu_Bk1_Item8_Animate
	g_BnFlash[9] = LuckyBag_Qifu_Bk1_Item9_Animate
	g_BnFlash[10] = LuckyBag_Qifu_Bk1_Item10_Animate
	g_BnFlash[11] = LuckyBag_Qifu_Bk2_Item1_Animate
	g_BnFlash[12] = LuckyBag_Qifu_Bk2_Item2_Animate
	g_BnFlash[13] = LuckyBag_Qifu_Bk2_Item3_Animate
	g_BnFlash[14] = LuckyBag_Qifu_Bk2_Item4_Animate
	g_BnFlash[15] = LuckyBag_Qifu_Bk2_Item5_Animate
	g_BnFlash[16] = LuckyBag_Qifu_Bk2_Item6_Animate
	g_BnFlash[17] = LuckyBag_Qifu_Bk2_Item7_Animate
	g_BnFlash[18] = LuckyBag_Qifu_Bk2_Item8_Animate
	g_BnFlash[19] = LuckyBag_Qifu_Bk2_Item9_Animate
	g_BnFlash[20] = LuckyBag_Qifu_Bk2_Item10_Animate
	g_BnFlash[21] = LuckyBag_Qifu_Bk3_Item1_Animate
	g_BnFlash[22] = LuckyBag_Qifu_Bk3_Item2_Animate
	g_BnFlash[23] = LuckyBag_Qifu_Bk3_Item3_Animate
	g_BnFlash[24] = LuckyBag_Qifu_Bk3_Item4_Animate
	g_BnFlash[25] = LuckyBag_Qifu_Bk3_Item5_Animate
	g_BnFlash[26] = LuckyBag_Qifu_Bk3_Item6_Animate
	g_BnFlash[27] = LuckyBag_Qifu_Bk3_Item7_Animate
	g_BnFlash[28] = LuckyBag_Qifu_Bk3_Item8_Animate
	g_BnFlash[29] = LuckyBag_Qifu_Bk3_Item9_Animate
	g_BnFlash[30] = LuckyBag_Qifu_Bk3_Item10_Animate
	
	g_BnBK[1] = LuckyBag_Qifu_Bk1_Item1BK
	g_BnBK[2] = LuckyBag_Qifu_Bk1_Item2BK
	g_BnBK[3] = LuckyBag_Qifu_Bk1_Item3BK
	g_BnBK[4] = LuckyBag_Qifu_Bk1_Item4BK
	g_BnBK[5] = LuckyBag_Qifu_Bk1_Item5BK
	g_BnBK[6] = LuckyBag_Qifu_Bk1_Item6BK
	g_BnBK[7] = LuckyBag_Qifu_Bk1_Item7BK
	g_BnBK[8] = LuckyBag_Qifu_Bk1_Item8BK
	g_BnBK[9] = LuckyBag_Qifu_Bk1_Item9BK
	g_BnBK[10] = LuckyBag_Qifu_Bk1_Item10BK
	g_BnBK[11] = LuckyBag_Qifu_Bk2_Item1BK
	g_BnBK[12] = LuckyBag_Qifu_Bk2_Item2BK
	g_BnBK[13] = LuckyBag_Qifu_Bk2_Item3BK
	g_BnBK[14] = LuckyBag_Qifu_Bk2_Item4BK
	g_BnBK[15] = LuckyBag_Qifu_Bk2_Item5BK
	g_BnBK[16] = LuckyBag_Qifu_Bk2_Item6BK
	g_BnBK[17] = LuckyBag_Qifu_Bk2_Item7BK
	g_BnBK[18] = LuckyBag_Qifu_Bk2_Item8BK
	g_BnBK[19] = LuckyBag_Qifu_Bk2_Item9BK
	g_BnBK[20] = LuckyBag_Qifu_Bk2_Item10BK
	g_BnBK[21] = LuckyBag_Qifu_Bk3_Item1BK
	g_BnBK[22] = LuckyBag_Qifu_Bk3_Item2BK
	g_BnBK[23] = LuckyBag_Qifu_Bk3_Item3BK
	g_BnBK[24] = LuckyBag_Qifu_Bk3_Item4BK
	g_BnBK[25] = LuckyBag_Qifu_Bk3_Item5BK
	g_BnBK[26] = LuckyBag_Qifu_Bk3_Item6BK
	g_BnBK[27] = LuckyBag_Qifu_Bk3_Item7BK
	g_BnBK[28] = LuckyBag_Qifu_Bk3_Item8BK
	g_BnBK[29] = LuckyBag_Qifu_Bk3_Item9BK
	g_BnBK[30] = LuckyBag_Qifu_Bk3_Item10BK

end

function LuckyBag_Qifu_OnEvent(event)

	if event == "RECIVE_ZNQ_FUDAIINFO" and tonumber(arg0) == 1 then
		LuckyBag_Qifu_Button:Enable()
		if KaJi:LuaFnIsKaJiServer() == 1 and KaJi:LuaFnGetKaJiType(56) > 0 then  --卡级
			LuckyBag_Qifu_Image:SetToolTip("#{HDSW_220118_01}")
			LuckyBag_Qifu_HaveText:SetToolTip("#{HDSW_220118_01}")
		else
			LuckyBag_Qifu_Image:SetToolTip("#{HDSW_190322_31}")
			LuckyBag_Qifu_HaveText:SetToolTip("#{HDSW_190322_31}")
		end

		this:Show()
		LuckyBag_Qifu_Bag_Frame:Hide()
		LuckyBag_Qifu_Frame_Client:Show()
		LuckyBag_Qifu_UpdateBonus()
	end
	
	--抽奖结果
	if event == "UI_COMMAND" and tonumber(arg0) == 44000001 then
		if this:IsVisible()	then			
			local bonus_idx = Get_XParam_INT(0)	
			LuckyBag_Qifu_ShowBonus(bonus_idx)
		end
		return
	end
	
	--祈福令变化
	if event == "UI_COMMAND" and tonumber(arg0) == 44000002 then
		if this:IsVisible()	then			
			g_HaveTokens = Get_XParam_INT(0)
			LuckyBag_Qifu_UpdateTokensText()
		end
		return
	end
	
	if event == "ADJEST_UI_POS" or event == "VIEW_RESOLUTION_CHANGED" then
		LuckyBag_Qifu_Frame:SetProperty("UnifiedPosition", g_Ori_UnifiedPosition)
	end
	
	if(event == "HIDE_ON_SCENE_TRANSED") then
		LuckyBag_Qifu_CloseClick()
	end
	
	
end

function LuckyBag_Qifu_UpdateBonus()
	
	for i = 1 , 30 do
		g_BnFlash[i]:Play(false)
		g_BnItem[i]:Enable()
		g_BnItem[i]:SetActionItem(-1)
		g_BnItem[i]:SetPushed(0)
	end	
	
	for i = 1 , 30 do
		
		local index = IndexMapping[i]
		local bonus_id = Lua_GetMyZNQItem(i - 1)
		
		if bonus_id >= 0 then
			
			local pool_id,item_id , item_count = Lua_GetZNQfudaiInfoByBonusId(bonus_id)
			local actionBonus = DataPool:CreateActionItemForShow(item_id,item_count)
			
			if pool_id >= 1 and pool_id <= 4 then
				g_BnBK[index]:SetProperty("Image" , g_BKImage[pool_id])
			else
				g_BnBK[index]:SetProperty("Image" , g_BKImage[4])
			end
			
			if actionBonus:GetID() ~= 0 then
				g_BnItem[index]:SetActionItem(actionBonus:GetID())	
			end
			
			if Lua_IsZNQBonusSelected(i - 1) == 1 then
				g_BnItem[index]:Disable()
			end
			
			if index == g_CurPushed then
				g_BnItem[index]:SetPushed(1)
			end
		
		end
	end
	
end

function LuckyBag_Qifu_ClickBuy()
	Lua_ToggleZNQBugTokens(1)
end

function LuckyBag_Qifu_ClickDo()
	
	LuckyBag_Qifu_Button:Disable()
	
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name( "QiFu" )
		Set_XSCRIPT_ScriptID( 440000 )
		Set_XSCRIPT_ParamCount(0 )
	Send_XSCRIPT()
	
	
	
end

function LuckyBag_Qifu_ClickHelp()
	PushEvent("ZNQ_DRAW_HELP")
end

function LuckyBag_Qifu_CloseClick()
	this:Hide()
end

function LuckyBag_Qifu_OnHidden()
	for i = 1 , 30 do
		g_BnItem[i]:SetActionItem(-1)
	end
	
	KillTimer("LuckyBag_Qifu_LotteryTick()")
	KillTimer("LuckyBag_Qifu_LotteryTick()2")
	CloseWindow("LuckyBag_Sure",true)
end

function LuckyBag_Qifu_ShowBonus(bonus_idx)
	
	if bonus_idx >= 0 and bonus_idx < 30 then
		g_BonusIndexForShow = bonus_idx
		action_index = IndexMapping[bonus_idx + 1]
		LuckyBag_Qifu_LotteryStart(action_index)
	
	else
		LuckyBag_Qifu_Button:Enable()
	end
	
end

function LuckyBag_Qifu_UpdateTokensText()

	local strTemp = ScriptGlobal_Format( "#{HDSW_190322_25}", tostring(g_HaveTokens) )
	LuckyBag_Qifu_HaveText:SetText(strTemp)
	
	local iSelCount = Lua_GetZNQBonusSelectedCount()
	if iSelCount >= 30 then		
		LuckyBag_Qifu_NeedText:SetText("#{HDSW_190322_34}")
	else
		local iIndex = math.floor(iSelCount / 10) + 1
		if g_HaveTokens < g_NeedTokens[iIndex] then
			local strTemp = ScriptGlobal_Format( "#{HDSW_190322_35}", tostring(g_NeedTokens[iIndex]) )
			LuckyBag_Qifu_NeedText:SetText(strTemp)
		else
			local strTemp = ScriptGlobal_Format( "#{HDSW_190322_5}", tostring(g_NeedTokens[iIndex]) )
			LuckyBag_Qifu_NeedText:SetText(strTemp)
		end
		
	end
end

function LuckyBag_Qifu_LotteryStart( end_index )
	
	local valid_count = 0
	
	g_valid_Bn = {}
	
	for i = 1 , 30 do	
		if Lua_IsZNQBonusSelected(i - 1) ~= 1 then
			valid_count = valid_count + 1
			g_valid_Bn[valid_count] = IndexMapping[i]
		end
	end
	
	valid_count = valid_count + 1
	g_valid_Bn[valid_count] = end_index
	
	if valid_count > 1 then
		g_MaxStep = math.floor(2.5 * valid_count)
	else
		g_MaxStep = 1
	end
	
	if g_CurPushed and g_CurPushed > 0 then
		g_BnItem[g_CurPushed]:SetPushed(0)
		g_BnFlash[g_CurPushed]:Play(false)
	end
	
	g_SumStep = 0
	g_Lightindex = g_CurPushed
	
	--PushDebugMessage(tostring(table.getn(g_valid_Bn))..":"..tostring(g_MaxStep))
	
	KillTimer("LuckyBag_Qifu_LotteryTick()")
	SetTimer("LuckyBag_Qifu","LuckyBag_Qifu_LotteryTick()", 120 - valid_count * 2 )
	
end

function LuckyBag_Qifu_LotteryTick()

	local rnd_value = math.random(1 , table.getn(g_valid_Bn) )
	
	local lightnow = g_valid_Bn[rnd_value]
	

	g_SumStep = g_SumStep + 1
--	PushDebugMessage(tostring(g_SumStep)..":"..tostring(g_MaxStep))
	if g_SumStep >= g_MaxStep then
		
		local last_index = IndexMapping[g_BonusIndexForShow + 1]
		
		KillTimer("LuckyBag_Qifu_LotteryTick()")
		
		SetTimer("LuckyBag_Qifu","LuckyBag_Qifu_LotteryTick2()", 1200 )

		g_CurPushed = last_index
		
		if g_CurPushed and g_CurPushed > 0 then  
			g_BnFlash[g_CurPushed]:SetProperty("Animate","Qifu_Flash1")
			g_BnFlash[g_CurPushed]:Play(true)
		end
	else
		g_BnFlash[lightnow]:SetProperty("Animate","Qifu_Flash")
		g_BnFlash[lightnow]:Play(true)
		g_Lightindex = lightnow		
	end

end

function LuckyBag_Qifu_LotteryTick2()
	
	KillTimer("LuckyBag_Qifu_LotteryTick2()")
	
	LuckyBag_Qifu_Button:Enable()
	
	LuckyBag_Qifu_UpdateBonus()
	
	LuckyBag_Qifu_BonusPopUp(g_BonusIndexForShow)
	
	g_BonusIndexForShow = -1
end

function LuckyBag_Qifu_BonusPopUp(iBonusIndex)
	
	LuckyBag_Qifu_Frame_Client:Hide()
	LuckyBag_Qifu_Bag_Frame:Show()
	
	LuckyBag_Qifu_Bag_Item:SetActionItem(-1)
	
	if iBonusIndex >= 0 and iBonusIndex < 30 then
		
		local bonus_id = Lua_GetMyZNQItem(iBonusIndex)
		
		if bonus_id >= 0 then
			
			local _,item_id , item_count = Lua_GetZNQfudaiInfoByBonusId(bonus_id)
			local actionBonus = DataPool:CreateActionItemForShow(item_id,item_count)

			if actionBonus:GetID() ~= 0 then
				LuckyBag_Qifu_Bag_Item:SetActionItem(actionBonus:GetID())	
			end
			
			local item_name = DataPool:Lua_GetItemNameByIndex(item_id)
			local strTemp = ScriptGlobal_Format("#{HDSW_190322_29}",tostring(item_count),tostring(item_name))
			PushDebugMessage(strTemp)
		
		end
		
		LuckyBag_Qifu_Bag_Item_Animate:Play(true)
	end
end

function LuckyBag_Qifu_ClickClose()
	LuckyBag_Qifu_Bag_Frame:Hide()
	LuckyBag_Qifu_Frame_Client:Show()
end
