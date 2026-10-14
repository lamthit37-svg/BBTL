--FengYun_StoryGift.lua
local g_FengYun_StoryGift_UnifiedXPosition
local g_FengYun_StoryGift_UnifiedYPosition
local g_FengYun_StoryGift_MaxProgress = 20
local g_FengYun_StoryGift_MaxGift = 8
local g_FengYun_StoryGift_GiftTable =
{
	[1] = { needpro = 2, isGet = 0, },
	[2] = { needpro = 4, isGet = 0, },
	[3] = { needpro = 7, isGet = 0, },
	[4] = { needpro = 10, isGet = 0, },
	[5] = { needpro = 12, isGet = 0, },
	[6] = { needpro = 14, isGet = 0, },
	[7] = { needpro = 17, isGet = 0, },
	[8] = { needpro = 20, isGet = 0, },
}
local g_FengYun_StoryGift_Gift = {}
local g_FengYun_StoryGift_GiftLock = {}
local g_FengYun_StoryGift_GiftTips = {}
local g_FengYun_StoryGift_GiftGot = {}
local g_FengYun_StoryGift_GiftText = {}

local g_FengYun_StoryGift_ToolTips = {
	[0] = --正式服
	{
		[1] = "#{FYWS_260107_20}",
		[2] = "#{FYWS_260107_21}",
		[3] = "#{FYWS_260107_22}",
		[4] = "#{FYWS_260107_23}",
		[5] = "#{FYWS_260107_24}",
		[6] = "#{FYWS_260107_155}",
		[7] = "#{FYWS_260107_156}",
		[8] = "#{FYWS_260107_157}",
	},
	[1] = --卡级服
	{
		[1] = "#{FYWS_260107_25}",
		[2] = "#{FYWS_260107_26}",
		[3] = "#{FYWS_260107_27}",
		[4] = "#{FYWS_260107_28}",
		[5] = "#{FYWS_260107_29}",
		[6] = "#{FYWS_260107_155}",
		[7] = "#{FYWS_260107_156}",
		[8] = "#{FYWS_260107_157}",
	},
	[2] = --典中典
	{
		[1] = "#{FYWS_260107_30}",
		[2] = "#{FYWS_260107_31}",
		[3] = "#{FYWS_260107_32}",
		[4] = "#{FYWS_260107_33}",
		[5] = "#{FYWS_260107_34}",
		[6] = "#{FYWS_260107_155}",
		[7] = "#{FYWS_260107_156}",
		[8] = "#{FYWS_260107_157}",
	},
}

local g_FengYun_StoryGift_NowStage = 1
local g_FengYun_StoryGift_SvrType = 0
local g_FengYun_StoryGift_Progress = 0
local g_FengYun_StoryGift_IsFromItem = 0

function FengYun_StoryGift_PreLoad()
	--第二个参数表示界面隐藏时是否响应事件 默认为true
	this:RegisterEvent("UI_COMMAND");
	this:RegisterEvent("ADJEST_UI_POS", false)
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED", false)
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED", false);
	this:RegisterEvent("SCENE_TRANSED", false)
end

function FengYun_StoryGift_OnLoad()
	-- 保存界面的默认相对位置
	g_FengYun_StoryGift_UnifiedXPosition = FengYun_StoryGift_Frame:GetProperty("UnifiedXPosition");
	g_FengYun_StoryGift_UnifiedYPosition = FengYun_StoryGift_Frame:GetProperty("UnifiedYPosition");

	g_FengYun_StoryGift_Gift[1] = FengYun_StoryGift_Item1_Gift
	g_FengYun_StoryGift_Gift[2] = FengYun_StoryGift_Item2_Gift
	g_FengYun_StoryGift_Gift[3] = FengYun_StoryGift_Item3_Gift
	g_FengYun_StoryGift_Gift[4] = FengYun_StoryGift_Item4_Gift
	g_FengYun_StoryGift_Gift[5] = FengYun_StoryGift_Item5_Gift
	g_FengYun_StoryGift_Gift[6] = FengYun_StoryGift_Item6_Gift
	g_FengYun_StoryGift_Gift[7] = FengYun_StoryGift_Item7_Gift
	g_FengYun_StoryGift_Gift[8] = FengYun_StoryGift_Item8_Gift

	g_FengYun_StoryGift_GiftLock[1] = FengYun_StoryGift_Item1_Gift_Lock
	g_FengYun_StoryGift_GiftLock[2] = FengYun_StoryGift_Item2_Gift_Lock
	g_FengYun_StoryGift_GiftLock[3] = FengYun_StoryGift_Item3_Gift_Lock
	g_FengYun_StoryGift_GiftLock[4] = FengYun_StoryGift_Item4_Gift_Lock
	g_FengYun_StoryGift_GiftLock[5] = FengYun_StoryGift_Item5_Gift_Lock
	g_FengYun_StoryGift_GiftLock[6] = FengYun_StoryGift_Item6_Gift_Lock
	g_FengYun_StoryGift_GiftLock[7] = FengYun_StoryGift_Item7_Gift_Lock
	g_FengYun_StoryGift_GiftLock[8] = FengYun_StoryGift_Item8_Gift_Lock

	g_FengYun_StoryGift_GiftTips[1] = FengYun_StoryGift_Item1_Gift_Tips
	g_FengYun_StoryGift_GiftTips[2] = FengYun_StoryGift_Item2_Gift_Tips
	g_FengYun_StoryGift_GiftTips[3] = FengYun_StoryGift_Item3_Gift_Tips
	g_FengYun_StoryGift_GiftTips[4] = FengYun_StoryGift_Item4_Gift_Tips
	g_FengYun_StoryGift_GiftTips[5] = FengYun_StoryGift_Item5_Gift_Tips
	g_FengYun_StoryGift_GiftTips[6] = FengYun_StoryGift_Item6_Gift_Tips
	g_FengYun_StoryGift_GiftTips[7] = FengYun_StoryGift_Item7_Gift_Tips
	g_FengYun_StoryGift_GiftTips[8] = FengYun_StoryGift_Item8_Gift_Tips

	g_FengYun_StoryGift_GiftGot[1] = FengYun_StoryGift_Item1_Gift_Got
	g_FengYun_StoryGift_GiftGot[2] = FengYun_StoryGift_Item2_Gift_Got
	g_FengYun_StoryGift_GiftGot[3] = FengYun_StoryGift_Item3_Gift_Got
	g_FengYun_StoryGift_GiftGot[4] = FengYun_StoryGift_Item4_Gift_Got
	g_FengYun_StoryGift_GiftGot[5] = FengYun_StoryGift_Item5_Gift_Got
	g_FengYun_StoryGift_GiftGot[6] = FengYun_StoryGift_Item6_Gift_Got
	g_FengYun_StoryGift_GiftGot[7] = FengYun_StoryGift_Item7_Gift_Got
	g_FengYun_StoryGift_GiftGot[8] = FengYun_StoryGift_Item8_Gift_Got

	g_FengYun_StoryGift_GiftText[1] = FengYun_StoryGift_Item1BK_text1
	g_FengYun_StoryGift_GiftText[2] = FengYun_StoryGift_Item2BK_text1
	g_FengYun_StoryGift_GiftText[3] = FengYun_StoryGift_Item3BK_text1
	g_FengYun_StoryGift_GiftText[4] = FengYun_StoryGift_Item4BK_text1
	g_FengYun_StoryGift_GiftText[5] = FengYun_StoryGift_Item5BK_text1
	g_FengYun_StoryGift_GiftText[6] = FengYun_StoryGift_Item6BK_text1
	g_FengYun_StoryGift_GiftText[7] = FengYun_StoryGift_Item7BK_text1
	g_FengYun_StoryGift_GiftText[8] = FengYun_StoryGift_Item8BK_text1

	for i = 1, g_FengYun_StoryGift_MaxGift, 1 do
		g_FengYun_StoryGift_Gift[i]:Hide()
		g_FengYun_StoryGift_GiftLock[i]:Hide()
		g_FengYun_StoryGift_GiftGot[i]:Hide()
		g_FengYun_StoryGift_GiftTips[i]:Hide()
		local text = ScriptGlobal_Format("#{FYWS_260107_19}", tostring(g_FengYun_StoryGift_GiftTable[i].needpro))
		g_FengYun_StoryGift_GiftText[i]:SetText(text)
	end
end

function FengYun_StoryGift_OnEvent(event)
	if (event == "UI_COMMAND" and tonumber(arg0) == 30015201) then
		local nFuncType = Get_XParam_INT(0)
		if nFuncType == 1 then
			FengYun_StoryGift_Initial()
			g_FengYun_StoryGift_NowStage = Get_XParam_INT(1)
			g_FengYun_StoryGift_SvrType = Get_XParam_INT(2)
			g_FengYun_StoryGift_Progress = Get_XParam_INT(3)
			g_FengYun_StoryGift_GiftTable[1].isGet = Get_XParam_INT(4)
			g_FengYun_StoryGift_GiftTable[2].isGet = Get_XParam_INT(5)
			g_FengYun_StoryGift_GiftTable[3].isGet = Get_XParam_INT(6)
			g_FengYun_StoryGift_GiftTable[4].isGet = Get_XParam_INT(7)
			g_FengYun_StoryGift_GiftTable[5].isGet = Get_XParam_INT(8)
			g_FengYun_StoryGift_GiftTable[6].isGet = Get_XParam_INT(9)
			g_FengYun_StoryGift_GiftTable[7].isGet = Get_XParam_INT(10)
			g_FengYun_StoryGift_GiftTable[8].isGet = Get_XParam_INT(11)
			g_FengYun_StoryGift_IsFromItem = 0
			FengYun_StoryGift_Update()
			this:Show()
		elseif nFuncType == 8 then
			FengYun_StoryGift_Initial()
			g_FengYun_StoryGift_IsFromItem = 1
			FengYun_StoryGift_Update()
			this:Show()
		end
	elseif (event == "ADJEST_UI_POS") then
		FengYun_StoryGift_On_ResetPos()
	elseif (event == "VIEW_RESOLUTION_CHANGED") then
		FengYun_StoryGift_On_ResetPos()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		FengYun_StoryGift_Close()
	elseif (event == "SCENE_TRANSED") then
		FengYun_StoryGift_Close()
	end
end

function FengYun_StoryGift_Update()
	if g_FengYun_StoryGift_IsFromItem == 1 then
		FengYun_StoryGift_ItemControl(0) --控件隐藏
		FengYun_StoryGift_Client_Page1BK:SetProperty("Image", "set:FengYun_Story13 image:FengYun_StoryGift_BK2")
		FengYun_StoryGift_Item1:Show()
		FengYun_StoryGift_Item2:Show()
		FengYun_StoryGift_Item1:SetToolTip("")
		FengYun_StoryGift_Item2:SetToolTip("")
	else
		FengYun_StoryGift_Item1:SetToolTip("#{FYWS_260107_15}")
		FengYun_StoryGift_Item2:SetToolTip("#{FYWS_260107_17}")
		FengYun_StoryGift_ItemControl(1) --控件显示
		local infoStr = "#{FYWS_260107_09}"
		if g_FengYun_StoryGift_SvrType == 1 then
			infoStr = "#{FYWS_260107_10}"
		end
		FengYun_StoryGift_Info:SetText(infoStr)
		if g_FengYun_StoryGift_Progress < 0 then
			g_FengYun_StoryGift_Progress = 0
		elseif g_FengYun_StoryGift_Progress > g_FengYun_StoryGift_MaxProgress then
			g_FengYun_StoryGift_Progress = g_FengYun_StoryGift_MaxProgress
		end
		local text1 = "#{FYWS_260107_18}"
		FengYun_StoryGift_text1:SetText(text1)
		local text2 = ScriptGlobal_Format("#{FYWS_260107_19}", tostring(g_FengYun_StoryGift_Progress))
		FengYun_StoryGift_text2:SetText(text2)
		for i = 1, g_FengYun_StoryGift_MaxGift, 1 do
			--悬浮提示
			g_FengYun_StoryGift_Gift[i]:SetToolTip(g_FengYun_StoryGift_ToolTips[g_FengYun_StoryGift_SvrType][i])
			g_FengYun_StoryGift_GiftLock[i]:SetToolTip(g_FengYun_StoryGift_ToolTips[g_FengYun_StoryGift_SvrType][i])
			g_FengYun_StoryGift_GiftGot[i]:SetToolTip(g_FengYun_StoryGift_ToolTips[g_FengYun_StoryGift_SvrType][i])
			g_FengYun_StoryGift_GiftTips[i]:Hide()
			--显隐
			if g_FengYun_StoryGift_Progress < g_FengYun_StoryGift_GiftTable[i].needpro then
				g_FengYun_StoryGift_Gift[i]:Hide()
				g_FengYun_StoryGift_GiftLock[i]:Show()
				g_FengYun_StoryGift_GiftGot[i]:Hide()
			elseif g_FengYun_StoryGift_Progress >= g_FengYun_StoryGift_GiftTable[i].needpro then
				if g_FengYun_StoryGift_GiftTable[i].isGet == 0 then
					g_FengYun_StoryGift_Gift[i]:Show()
					g_FengYun_StoryGift_GiftLock[i]:Hide()
					g_FengYun_StoryGift_GiftGot[i]:Hide()
					--有可领取的 显示红点
					g_FengYun_StoryGift_GiftTips[i]:Show()
				else
					g_FengYun_StoryGift_Gift[i]:Hide()
					g_FengYun_StoryGift_GiftLock[i]:Hide()
					g_FengYun_StoryGift_GiftGot[i]:Show()
				end
			end
		end
		FengYun_StoryGift_Progress2:SetProgress(g_FengYun_StoryGift_Progress, 20)
		if g_FengYun_StoryGift_NowStage == 1 then
			FengYun_StoryGift_Item1:Show()
			FengYun_StoryGift_Item2:Hide()
			FengYun_StoryGift_Client_Page1BK:SetProperty("Image", "set:FengYun_StoryGift1 image:FengYun_StoryGift_BK1")
		elseif g_FengYun_StoryGift_NowStage == 2 then
			FengYun_StoryGift_Item1:Show()
			FengYun_StoryGift_Item2:Show()
			FengYun_StoryGift_Client_Page1BK:SetProperty("Image", "set:FengYun_Story13 image:FengYun_StoryGift_BK2")
		else
			FengYun_StoryGift_Item1:Hide()
			FengYun_StoryGift_Item2:Hide()
			FengYun_StoryGift_Client_Page1BK:SetProperty("Image", "set:FengYun_StoryGift1 image:FengYun_StoryGift_BK1")
		end
	end
end

--onhidden closebtn
function FengYun_StoryGift_Close()
	this:Hide()
	FengYun_StoryGift_Initial()
end

function FengYun_StoryGift_Initial()
	--初始化
	g_FengYun_StoryGift_NowStage = 1
	g_FengYun_StoryGift_SvrType = 0
	g_FengYun_StoryGift_Progress = 0
	g_FengYun_StoryGift_IsFromItem = 0
	for i = 1, g_FengYun_StoryGift_MaxGift, 1 do
		g_FengYun_StoryGift_GiftTable[i].isGet = 0
	end
end

function FengYun_StoryGift_ItemControl(isShow)
	if isShow == 0 then
		FengYun_StoryGift_InfoBK:Hide()
		FengYun_StoryGift_Item1BK:Hide()
		FengYun_StoryGift_Item1BK_text1:Hide()
		FengYun_StoryGift_Item2BK:Hide()
		FengYun_StoryGift_Item2BK_text1:Hide()
		FengYun_StoryGift_Item3BK:Hide()
		FengYun_StoryGift_Item3BK_text1:Hide()
		FengYun_StoryGift_Item4BK:Hide()
		FengYun_StoryGift_Item4BK_text1:Hide()
		FengYun_StoryGift_Item5BK:Hide()
		FengYun_StoryGift_Item5BK_text1:Hide()
		FengYun_StoryGift_Item6BK:Hide()
		FengYun_StoryGift_Item6BK_text1:Hide()
		FengYun_StoryGift_Item7BK:Hide()
		FengYun_StoryGift_Item7BK_text1:Hide()
		FengYun_StoryGift_Item8BK:Hide()
		FengYun_StoryGift_Item8BK_text1:Hide()
		FengYun_StoryGift_ProgressBK:Hide()
		FengYun_StoryGift_text1:Hide()
		FengYun_StoryGift_text2:Hide()
		FengYun_StoryGift_Client_Page2BK:Hide()
	else
		FengYun_StoryGift_InfoBK:Show()
		FengYun_StoryGift_Item1BK:Show()
		FengYun_StoryGift_Item1BK_text1:Show()
		FengYun_StoryGift_Item2BK:Show()
		FengYun_StoryGift_Item2BK_text1:Show()
		FengYun_StoryGift_Item3BK:Show()
		FengYun_StoryGift_Item3BK_text1:Show()
		FengYun_StoryGift_Item4BK:Show()
		FengYun_StoryGift_Item4BK_text1:Show()
		FengYun_StoryGift_Item5BK:Show()
		FengYun_StoryGift_Item5BK_text1:Show()
		FengYun_StoryGift_Item6BK:Show()
		FengYun_StoryGift_Item6BK_text1:Show()
		FengYun_StoryGift_Item7BK:Show()
		FengYun_StoryGift_Item7BK_text1:Show()
		FengYun_StoryGift_Item8BK:Show()
		FengYun_StoryGift_Item8BK_text1:Show()
		FengYun_StoryGift_ProgressBK:Show()
		FengYun_StoryGift_text1:Show()
		FengYun_StoryGift_text2:Show()
		FengYun_StoryGift_Client_Page2BK:Show()
	end
end

--story
function FengYun_StoryGift_Click(index)
	if index < 1 or index > 2 then
		return
	end
	if g_FengYun_StoryGift_IsFromItem == 1 then
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenStoryItem")
		Set_XSCRIPT_ScriptID(300152)
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	else
		Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("OpenStoryDetailUI")
		Set_XSCRIPT_ScriptID(300152)
		Set_XSCRIPT_Parameter(0, index)
		Set_XSCRIPT_ParamCount(1)
		Send_XSCRIPT()
	end
end

--reward
function FengYun_StoryGift_Item_GetGift(index)
	if g_FengYun_StoryGift_IsFromItem == 1 then
		return
	end
	if index < 1 or index > g_FengYun_StoryGift_MaxGift then
		return
	end
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("GetCumulativeReward")
	Set_XSCRIPT_ScriptID(300152)
	Set_XSCRIPT_Parameter(0, index)
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

--help
function FengYun_StoryGift_Description_Clicked()
	Clear_XSCRIPT()
	Set_XSCRIPT_Function_Name("HelpMsg")
	Set_XSCRIPT_ScriptID(300152)
	Set_XSCRIPT_Parameter(0, 1)
	Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()
end

function FengYun_StoryGift_On_ResetPos()
	FengYun_StoryGift_Frame:SetProperty("UnifiedXPosition", g_FengYun_StoryGift_UnifiedXPosition)
	FengYun_StoryGift_Frame:SetProperty("UnifiedYPosition", g_FengYun_StoryGift_UnifiedYPosition)
end
