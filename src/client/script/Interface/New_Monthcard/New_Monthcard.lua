--!!!reloadscript =New_Monthcard

local g_New_Monthcard_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_Monthcard_State	= 0		--月卡状态
local g_Monthcard_Duration = 0  --月卡剩余时间
local g_Monthcard_FreeMonthcardDuration = 0  --月卡剩余时间

local g_DailReward_State = 0	--每日奖励领取情况
local g_BoughtDailReward_State = 0	--月卡每日奖励领取情况
local g_BuyReward_State = 0		--购买奖励领取情况
local g_NewMonthcard_Reward_Item = 
	{
		[1] = { Itemid = 38006652,num = 1},	--金契馈赠礼
		[2] = { Itemid = 38006653,num = 1},	--120绑定元宝
		[3] = { Itemid = 38006654,num = 1},	--40绑定元宝

		DGItemid = 39924803,
		DGnum = 1,
	}
local g_StartYear,g_StartMonth,g_StartDay,g_EndYear,g_EndMonth,g_EndDay	--月卡服活动起止时间
local g_IsSocialServerTime = 0  --是否是社交服，如果是社交服则需要显示悬浮tips
local g_Need_YuanBao = 8888		--月卡价格

local g_check_btn = {}
local g_show_btn = {}
local g_check_text = {}
local g_check_img = {}
local g_CurShowIndex = 0

local g_WinImageStr = "set:CommonFrame36 image:Alternative"
local g_NotWinImageStr = "set:New_Monthcard1 image:New_MonthcardNo"


function New_Monthcard_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
	
	this:RegisterEvent("OPEN_FASHION_LOTTERY")
	this:RegisterEvent("REFRESH_FASHION_LOTTERY")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function New_Monthcard_OnLoad()
	g_New_Monthcard_Frame_UnifiedPosition = New_Monthcard_Frame:GetProperty("UnifiedPosition")
	
	g_check_btn[1] = {New_Monthcard_Icon1_Animate,New_Monthcard_Icon1_Mask}	--1未领取红点,2已领取		[1]购买奖励
	g_check_btn[2] = {New_Monthcard_Icon2_Animate,New_Monthcard_Icon2_Mask}	--1未领取红点,2已领取		[2]月卡日常奖励
	g_check_btn[3] = {New_Monthcard_Icon3_Animate,New_Monthcard_Icon3_Mask}	--1未领取红点,2已领取		[3]活动日常奖励
	
	g_show_btn[1] = New_Monthcard_Icon1
	g_show_btn[2] = New_Monthcard_Icon2
	g_show_btn[3] = New_Monthcard_Icon3
	
	g_check_img[1] = New_Monthcard_Image1	--显示月卡剩余天数图片

	g_check_text[1] = New_Monthcard_text1
	g_check_text[2] = New_Monthcard_text2
	g_check_text[3] = New_Monthcard_text3
	g_check_text[4] = New_Monthcard_text4
	g_check_text[5] = New_Monthcard_text6
	g_check_text[6] = New_Monthcard_text5	--月卡剩余天数

	g_check_text[6] = New_Monthcard_Info	--简介
	
end

function New_Monthcard_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 99890801 ) then
		g_Monthcard_State = Get_XParam_INT(0)		
		g_Monthcard_Duration = Get_XParam_INT(1)
		g_DailReward_State = Get_XParam_INT(2)
		g_BoughtDailReward_State = Get_XParam_INT(3)
		g_BuyReward_State = Get_XParam_INT(4)
		g_StartYear  = Get_XParam_INT(5)
		g_StartMonth =  Get_XParam_INT(6)
		g_StartDay  = Get_XParam_INT(7)
		g_EndYear = Get_XParam_INT(8)
		g_EndMonth  = Get_XParam_INT(9)
		g_EndDay  = Get_XParam_INT(10)
		g_Monthcard_FreeMonthcardDuration  = Get_XParam_INT(11)
		g_IsSocialServerTime = Get_XParam_INT(12)
		New_Monthcard_Update() 
		this:Show()
		return
	elseif (event == "ADJEST_UI_POS" ) then
		New_Monthcard_OnClose()
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		New_Monthcard_OnClose()
	end
end

function New_Monthcard_Update()
	New_Monthcard_Info:SetText(ScriptGlobal_Format("#{YKJY_231113_28}",
	tostring(g_StartYear),tostring(g_StartMonth),tostring(g_StartDay),
	tostring(g_EndYear),tostring(g_EndMonth),tostring(g_EndDay)))
	if Lua_IsPlayerFuBenJB() == 1 then
		New_Monthcard_text3:SetToolTip("#{JBGZ_260122_01}")
	else
		New_Monthcard_text3:SetToolTip("#{YKJY_231113_7}")
	end
	New_Monthcard_Image1:Hide()
	local isOpenDG = Lua_IsNewDGOpen()
	local isNewMCA = Lua_IsPlayerNewMonthcard()
	for i = 1, 3, 1 do
		local theAction = DataPool:CreateBindActionItemForShow(g_NewMonthcard_Reward_Item[i].Itemid, g_NewMonthcard_Reward_Item[i].num)
		if isNewMCA == 1 and i == 1 and isOpenDG == 1 then --是月卡服，是地宫开启时间，只是金契会换
			theAction = DataPool:CreateBindActionItemForShow(g_NewMonthcard_Reward_Item.DGItemid, g_NewMonthcard_Reward_Item.DGnum)
		end
		
		if theAction:GetID() ~= 0 then
			g_show_btn[i]:SetActionItem(theAction:GetID())
			g_show_btn[i]:Show()
		end
	end
	
	New_Monthcard_text4:Hide()
	if g_Monthcard_State==1 then 
		if (g_Monthcard_Duration - 3 )>= 0 then
			New_Monthcard_text4:Show()
			New_Monthcard_text4:SetText(ScriptGlobal_Format("#{YKJY_231113_29}",tostring(g_Monthcard_Duration-3)))
		end
		New_Monthcard_text5:SetText(ScriptGlobal_Format("#{YKJY_231113_9}",tostring(g_Monthcard_Duration)))
		if g_IsSocialServerTime ~= 0 then
			New_Monthcard_Image1:SetToolTip(ScriptGlobal_Format("#{RLYZ_20240516_61}",
			tostring(g_Monthcard_Duration-g_Monthcard_FreeMonthcardDuration),
			tostring(g_Monthcard_FreeMonthcardDuration)))
		else
			New_Monthcard_Image1:SetToolTip("")
		end
		New_Monthcard_Image1:Show()

	elseif g_Monthcard_State == 2 then
		New_Monthcard_text4:Show()
		New_Monthcard_text4:SetText("#{YKJY_231113_33}")
		New_Monthcard_text5:SetText(ScriptGlobal_Format("#{YKJY_231113_9}",tostring(g_Monthcard_Duration)))
		if g_IsSocialServerTime ~= 0 then
			New_Monthcard_Image1:SetToolTip(ScriptGlobal_Format("#{RLYZ_20240516_61}",
										tostring(g_Monthcard_Duration-g_Monthcard_FreeMonthcardDuration),
										tostring(g_Monthcard_FreeMonthcardDuration)))
		else
			New_Monthcard_Image1:SetToolTip("")
		end
		New_Monthcard_Image1:Show()

	elseif g_Monthcard_State == -1 then
		New_Monthcard_ReFresh_Btn:SetText("#{YKJY_231113_34}")
		New_Monthcard_Image1:SetToolTip("#{RLYZ_20240516_62}")
	else
		New_Monthcard_text5:Show()
		New_Monthcard_text5:SetText("#{YKJY_231113_10}")
		New_Monthcard_Image1:SetToolTip("#{RLYZ_20240516_62}")
	end
	--判断活动是否已经结束
	if (g_EndYear*10000+g_EndMonth*100+g_EndDay) < tonumber(DataPool:GetServerDayTime()) then
		New_Monthcard_text4:Show()
		New_Monthcard_text4:SetText("#{YKJY_231113_34}")
	end


	if g_BuyReward_State==1 and g_Monthcard_State>=1 then
		g_check_btn[1][2]:Show()
		g_check_btn[1][1]:Hide()
	else
		g_check_btn[1][1]:Hide()
		g_check_btn[1][2]:Hide()

		if g_Monthcard_State >= 1 then
			g_check_btn[1][1]:Show()
		end


	end
	if g_BoughtDailReward_State==1  and g_Monthcard_State>=1 then

		g_check_btn[2][2]:Show()
		g_check_btn[2][1]:Hide()
	else
		g_check_btn[2][1]:Hide()
		g_check_btn[2][2]:Hide()
		
		if g_Monthcard_State >= 1 then
			g_check_btn[2][1]:Show()
		end

	end
	if g_DailReward_State==1 then

		g_check_btn[3][2]:Show()
		g_check_btn[3][1]:Hide()
	else

		g_check_btn[3][1]:Show()
		g_check_btn[3][2]:Hide()
	end
end

function New_Monthcard_OnClose()	--关闭月卡购买界面
	if(IsWindowShow("New_Monthcard")) then
		CloseWindow("New_Monthcard", true)
	end
	
	this:Hide()
end

function New_Monthcard_GetFree()	--购买月卡
	Clear_XSCRIPT()
	Set_XSCRIPT_ScriptID(998908)
	Set_XSCRIPT_Function_Name("BuyNewMonthcard")
	Set_XSCRIPT_Parameter(0, 1)
	Set_XSCRIPT_Parameter(1, 0)
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	New_Monthcard_Update()
end

function New_Monthcard_Icon1_GetClick()	--领取购买奖励
	Clear_XSCRIPT()
	Set_XSCRIPT_ScriptID(998908)
	Set_XSCRIPT_Function_Name("GetBuyReward")
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	New_Monthcard_Update()
end
function New_Monthcard_Icon2_GetClick()	--领取购买每日奖励
	Clear_XSCRIPT()
	Set_XSCRIPT_ScriptID(998908)
	Set_XSCRIPT_Function_Name("GetNewMonthcardDarilyReward")
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	New_Monthcard_Update()
end
function New_Monthcard_Icon3_GetClick()	--领取每日奖励
	Clear_XSCRIPT()
	Set_XSCRIPT_ScriptID(998908)
	Set_XSCRIPT_Function_Name("GetDarilyReward")
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	New_Monthcard_Update()
end

function New_Monthcard_Description_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NPCTalk")
		Set_XSCRIPT_ScriptID(892721)
		Set_XSCRIPT_Parameter(0,3)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end