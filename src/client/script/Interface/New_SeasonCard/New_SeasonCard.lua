--!!!reloadscript =New_SeasonCard

local g_New_SeasonCard_Frame_UnifiedPosition = ""
local m_ObjServerId = -1

local g_SeasonCard_State	= 0		--月卡状态
local g_SeasonCard_Duration = 0  --月卡剩余时间
local g_SeasonCard_FreeSeasonCardDuration = 0  --月卡剩余时间

local g_DailReward_State = 0	--每日奖励领取情况
local g_BoughtDailReward_State = 0	--月卡每日奖励领取情况
local g_BuyReward_State = 0		--购买奖励领取情况
local g_NewSeasonCard_Reward_Item = 
	{
		[1] = { Itemid = 38006790,num = 1},	--金契馈赠礼

		DGItemid = 39924803,
		DGnum = 1,
	}
local g_StartYear,g_StartMonth,g_StartDay,g_EndYear,g_EndMonth,g_EndDay	--月卡服活动起止时间
local g_IsSocialServerTime = 0  --是否是社交服，如果是社交服则需要显示悬浮tips

local g_check_btn = {}
local g_show_btn = {}
local g_check_text = {}
local g_check_img = {}
local g_CurShowIndex = 0

local g_WinImageStr = "set:CommonFrame36 image:Alternative"
local g_NotWinImageStr = "set:New_SeasonCard1 image:New_SeasonCardNo"


function New_SeasonCard_PreLoad()
	this:RegisterEvent("UI_COMMAND")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED")
	this:RegisterEvent("ADJEST_UI_POS")
	this:RegisterEvent("VIEW_RESOLUTION_CHANGED")
	
	this:RegisterEvent("OPEN_FASHION_LOTTERY")
	this:RegisterEvent("REFRESH_FASHION_LOTTERY")
	this:RegisterEvent("HIDE_ON_SCENE_TRANSED",false)	--进场景关闭界面
end

function New_SeasonCard_OnLoad()
	g_New_SeasonCard_Frame_UnifiedPosition = New_SeasonCard_Frame:GetProperty("UnifiedPosition")
	
	g_check_btn[1] = {New_SeasonCard_Icon_Animate,New_SeasonCard_Icon_Mask}	--1未领取红点,2已领取		[1]购买奖励
	
	g_show_btn[1] = New_SeasonCard_Icon
	
	g_check_img[1] = New_SeasonCard_Image1	--显示月卡剩余天数图片

	g_check_text[1] = New_SeasonCard_text1
	g_check_text[2] = New_SeasonCard_text3	--月卡剩余天数
	g_check_text[3] = New_SeasonCard_Info	--简介
	
end

function New_SeasonCard_OnEvent(event)
	if ( event == "UI_COMMAND" and tonumber(arg0) == 99890803 ) then
		g_SeasonCard_State = Get_XParam_INT(0)		
		g_SeasonCard_Duration = Get_XParam_INT(1)
		g_DailReward_State = Get_XParam_INT(2)
		g_BoughtDailReward_State = Get_XParam_INT(3)
		g_BuyReward_State = Get_XParam_INT(4)
		g_StartYear  = Get_XParam_INT(5)
		g_StartMonth =  Get_XParam_INT(6)
		g_StartDay  = Get_XParam_INT(7)
		g_EndYear = Get_XParam_INT(8)
		g_EndMonth  = Get_XParam_INT(9)
		g_EndDay  = Get_XParam_INT(10)
		g_SeasonCard_FreeSeasonCardDuration  = Get_XParam_INT(11)
		g_IsSocialServerTime = Get_XParam_INT(12)
		New_SeasonCard_Update() 
		this:Show()
		return
	elseif (event == "HIDE_ON_SCENE_TRANSED") then
		New_SeasonCard_OnClose()
	end
end

function New_SeasonCard_Update()
	New_SeasonCard_Info:SetText("#{JKYL_251211_02}")
	
	New_SeasonCard_Image1:Hide()
	-- local isOpenDG = Lua_IsNewDGOpen()
	-- local isNewMCA = Lua_IsPlayerNewMonthcard()
    local theAction = DataPool:CreateBindActionItemForShow(g_NewSeasonCard_Reward_Item[1].Itemid,
        g_NewSeasonCard_Reward_Item[1].num)
    -- if isNewMCA == 1 and isOpenDG == 1 then --是月卡服，是地宫开启时间，只是金契会换
    --     theAction = DataPool:CreateBindActionItemForShow(g_NewSeasonCard_Reward_Item.DGItemid,
    --         g_NewSeasonCard_Reward_Item.DGnum)
    -- end
	if Lua_IsPlayerFuBenJB() == 1 then
		New_SeasonCard_Image2:SetToolTip("#{JBGZ_260122_03}")
	else
		New_SeasonCard_Image2:SetToolTip("#{JKYL_251211_06}")
	end
    if theAction:GetID() ~= 0 then
        g_show_btn[1]:SetActionItem(theAction:GetID())
        g_show_btn[1]:Show()
    end
	New_SeasonCard_Image2:Hide()
	New_SeasonCard_text3:Hide()
	if g_SeasonCard_State==1 then 
		New_SeasonCard_text3:Show()
		New_SeasonCard_text3:SetText(ScriptGlobal_Format("#{JKYL_251211_10}",tostring(g_SeasonCard_Duration)))
		if g_IsSocialServerTime ~= 0 then
			New_SeasonCard_Image1:SetToolTip(ScriptGlobal_Format("#{JKYL_251211_11}",
			tostring(g_SeasonCard_Duration-g_SeasonCard_FreeSeasonCardDuration)))
		else
			New_SeasonCard_Image1:SetToolTip("")
		end
		New_SeasonCard_Image1:Show()

	elseif g_SeasonCard_State == 2 then
		New_SeasonCard_text3:Show()
		New_SeasonCard_text3:SetText(ScriptGlobal_Format("#{JKYL_251211_10}",tostring(g_SeasonCard_Duration)))
		if g_IsSocialServerTime ~= 0 then
			New_SeasonCard_Image1:SetToolTip(ScriptGlobal_Format("#{JKYL_251211_11}",
										tostring(g_SeasonCard_Duration-g_SeasonCard_FreeSeasonCardDuration)))
		else
			New_SeasonCard_Image1:SetToolTip("")
		end
		New_SeasonCard_Image1:Show()

	elseif g_SeasonCard_State == -1 then
		New_SeasonCard_ReFresh_Btn:SetText("#{JKYL_251211_09}")
		New_SeasonCard_Image1:SetToolTip("#{JKYL_251211_13}")
	else
		New_SeasonCard_Image2:Show()
		-- New_SeasonCard_text3:Show()
		-- New_SeasonCard_text3:SetText("#{JKYL_251211_12}")
		New_SeasonCard_Image1:SetToolTip("#{JKYL_251211_13}")
	end


	if g_BoughtDailReward_State==1 and g_SeasonCard_State>=1 then
		g_check_btn[1][2]:Show()
		g_check_btn[1][1]:Hide()
	else
		g_check_btn[1][1]:Hide()
		g_check_btn[1][2]:Hide()

		if g_SeasonCard_State >= 1 then
			g_check_btn[1][1]:Show()
		end
	end
	
end

function New_SeasonCard_OnClose()	--关闭月卡购买界面
	if(IsWindowShow("New_SeasonCard")) then
		CloseWindow("New_SeasonCard", true)
	end
	
	this:Hide()
end

function New_SeasonCard_GetFree()	--购买季卡
	Clear_XSCRIPT()
	Set_XSCRIPT_ScriptID(998908)
	Set_XSCRIPT_Function_Name("BuyNewMonthcard")
	Set_XSCRIPT_Parameter(0, 2)
	Set_XSCRIPT_Parameter(1, 0)
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	New_SeasonCard_Update()
end
function New_SeasonCard_Buy_Btn1_OnClick()--购买月卡
	Clear_XSCRIPT()
	Set_XSCRIPT_ScriptID(998908)
	Set_XSCRIPT_Function_Name("BuyNewMonthcard")
	Set_XSCRIPT_Parameter(0, 1)
	Set_XSCRIPT_Parameter(1, 0)
	Set_XSCRIPT_ParamCount(2)
	Send_XSCRIPT()
	New_SeasonCard_Update()
end
function New_SeasonCard_Icon_GetClick()	--领取购买每日奖励
	Clear_XSCRIPT()
	Set_XSCRIPT_ScriptID(998908)
	Set_XSCRIPT_Function_Name("GetNewMonthcardDarilyReward")
	Set_XSCRIPT_ParamCount(0)
	Send_XSCRIPT()
	New_SeasonCard_Update()
end

function New_SeasonCard_Description_Clicked()
	Clear_XSCRIPT()
		Set_XSCRIPT_Function_Name("NPCTalk")
		Set_XSCRIPT_ScriptID(892721)
		Set_XSCRIPT_Parameter(0,3)
		Set_XSCRIPT_ParamCount(1)
	Send_XSCRIPT()	
end